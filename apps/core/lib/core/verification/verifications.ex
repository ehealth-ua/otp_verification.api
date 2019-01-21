defmodule Core.Verification.Verifications do
  @moduledoc """
  The boundary for the Verification system.
  """

  import Ecto.{Query, Changeset}, warn: false
  alias Core.Luhn
  alias Core.Redix
  alias Core.Repo
  alias Core.SMSLogs
  alias Core.Verification.Verification
  alias Core.Verification.VerifiedPhone
  alias EView.Changeset.Validators.PhoneNumber
  require Logger
  use Confex, otp_app: :core

  @doc """
  Returns the list of verifications.

  ## Examples

      iex> list_verifications()
      [%Core.Verification.Verifications{}]

  """
  @spec list_verifications :: [Verification.t()] | []
  def list_verifications do
    Repo.all(Verification)
  end

  @doc """
  Gets a single verification.

  Raises `Ecto.NoResultsError` if the Verification does not exist.

  ## Examples

      iex> get_verification!(123)
      %Core.Verification.Verification{}

      iex> get_verification!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_verification(id :: String.t()) :: Verification.t() | nil | no_return
  def get_verification(id), do: Repo.get(Verification, id)
  def get_verification!(id), do: Repo.get!(Verification, id)

  def get_verified_phone(phone_number) do
    Repo.get_by(VerifiedPhone, %{phone_number: phone_number})
  end

  @doc """
  Gets a single verification.

  Raises `Ecto.NoResultsError` if the Verification does not exist.

  ## Examples

      iex> get_verification_by(123)
      %Core.Verification.Verification
  """
  @spec get_verification_by(params :: Keyword.t()) :: Verification.t() | []
  def get_verification_by(params) do
    Verification
    |> order_by(desc: :inserted_at)
    |> limit(1)
    |> Repo.get_by(params)
  end

  @doc """
  Creates a verification.

  ## Examples

      iex> create_verification(%{field: value})
      {:ok, %Core.Verification.Verification{}}

      iex> create_verification(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_verification(attrs :: %{}) :: {:ok, Verification.t()} | {:error, Ecto.Changeset.t()}
  def create_verification(attrs \\ %{}) do
    %Verification{}
    |> verification_changeset(attrs)
    |> Repo.insert()
  end

  @spec add_verified_phone(verification :: %Verification{}) :: {:ok, Verification.t()} | {:error, Ecto.Changeset.t()}
  def add_verified_phone(%Verification{} = verification) do
    verified_phone =
      VerifiedPhone
      |> where(phone_number: ^verification.phone_number)
      |> first
      |> Repo.one()

    case verified_phone do
      nil ->
        %VerifiedPhone{}
        |> verified_phone_changeset(%{phone_number: verification.phone_number})
        |> Repo.insert()

      verified_phone ->
        {:ok, verified_phone}
    end
  end

  @spec initialize_verification(attrs :: %{}) :: {:ok, Verification.t()} | {:error, Ecto.Changeset.t()}
  def initialize_verification(attrs) do
    with :ok <- validate_initialize_frequency(attrs, config()[:init_verification_limit]),
         %{} = attrs <- initialize_attrs(attrs) do
      deactivate_verifications(attrs["phone_number"])

      %Verification{}
      |> verification_changeset(attrs)
      |> Repo.insert()
    end
  end

  defp validate_initialize_frequency(attrs, limit) when is_integer(limit) and limit > 0 do
    key = "initialize:#{attrs["phone_number"]}"

    with {:ok, 1} <- Redix.setnx(key, true),
         {:ok, "OK"} <- Redix.setex(key, true, limit) do
      :ok
    else
      _ -> {:error, :too_many_requests}
    end
  end

  defp validate_initialize_frequency(_, _), do: :ok

  @spec initialize_attrs(%{}) :: %{}
  defp initialize_attrs(attrs) do
    {otp_code, checksum} = generate_otp_code()
    code_expired_at = get_code_expiration_time()

    sms_text = :core |> Confex.fetch_env!(:code_text) |> Kernel.<>(to_string(otp_code))

    try do
      {:ok, _} =
        SMSLogs.save_and_send_sms(%{
          "phone_number" => attrs["phone_number"],
          "body" => sms_text,
          "type" => "verification"
        })

      Map.merge(attrs, %{
        "check_digit" => checksum,
        "code" => otp_code,
        "status" => Verification.status(:new),
        "code_expired_at" => code_expired_at
      })
    rescue
      e in Mouth.ApiError ->
        Logger.error(fn ->
          Poison.encode!(%{
            "log_type" => "http_request",
            "action" => "POST",
            "request_id" => Logger.metadata()[:request_id],
            "body" => e.message
          })
        end)

        {:error, :service_unavailable}
    end
  end

  @spec verify(verification :: %{code: Integer.t()}, code :: Integer.t()) :: tuple()
  def verify(%Verification{code: verification_code} = verification, code) do
    with :ok <- verify_expiration_time(verification),
         is_verified <- verification_code == code do
      case is_verified do
        true -> verification_completed(verification)
        false -> verification_does_not_completed(verification, :not_verified)
      end
    end
  end

  defp verify_expiration_time(%Verification{} = verification) do
    if Timex.before?(Timex.now(), verification.code_expired_at),
      do: :ok,
      else: verification_does_not_completed(verification, :expired)
  end

  @spec verification_completed(verification :: Verification.t()) :: tuple()
  defp verification_completed(%Verification{} = verification) do
    verification
    |> update_verification(%{
      status: Verification.status(:verified),
      active: false,
      attempts_count: verification.attempts_count + 1
    })
    |> Tuple.append(:verified)
  end

  @spec verification_does_not_completed(verification :: Verification.t(), error :: atom) :: tuple()
  defp verification_does_not_completed(%Verification{} = verification, error) do
    max_attempts = Confex.fetch_env!(:core, :max_attempts)
    attempts_count = verification.attempts_count + 1

    attrs =
      if attempts_count < max_attempts,
        do: %{attempts_count: attempts_count},
        else: %{
          status: Verification.status(:unverified),
          active: false,
          attempts_count: attempts_count
        }

    verification
    |> update_verification(attrs)
    |> Tuple.append(error)
  end

  @doc """
  Updates a verification.

  ## Examples

      iex> update_verification(verification, %{field: new_value})
      {:ok, %Core.Verification.Verification{}}

      iex> update_verification(verification, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_verification(verification :: Verification.t(), %{}) ::
          {:ok, Verification.t()} | {:error, Ecto.Changeset.t()}
  def update_verification(%Verification{} = verification, attrs) do
    verification
    |> verification_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Verification.

  ## Examples

      iex> delete_verification(verification)
      {:ok, %Core.Verification.Verification{}}

      iex> delete_verification(verification)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_verification(verification :: Verification.t()) :: {:ok, Verification.t()} | {:error, Ecto.Changeset.t()}
  def delete_verification(%Verification{} = verification) do
    Repo.delete(verification)
  end

  @spec verification_changeset(verification :: Verification.t(), %{}) :: Ecto.Changeset.t()
  defp verification_changeset(%Verification{} = verification, attrs) do
    verification
    |> cast(attrs, [
      :phone_number,
      :check_digit,
      :status,
      :code,
      :code_expired_at,
      :active,
      :attempts_count
    ])
    |> validate_required([:phone_number, :check_digit, :status, :code, :code_expired_at])
    |> validate_inclusion(:status, Verification.status_options())
    |> PhoneNumber.validate_phone_number(:phone_number)
    |> unique_constraint(:phone_number, name: :verifications_phone_number_index)
  end

  @spec verification_changeset(verification :: Verification.t(), %{}) :: Ecto.Changeset.t()
  defp verified_phone_changeset(%VerifiedPhone{} = verified_phone, attrs) do
    verified_phone
    |> cast(attrs, [:phone_number])
    |> validate_required([:phone_number])
    |> unique_constraint(:phone_number)
    |> PhoneNumber.validate_phone_number(:phone_number)
  end

  @spec get_number(number_length :: pos_integer()) :: pos_integer()
  defp get_number(number_length) do
    1..(number_length - 1)
    |> Enum.map(fn _ -> :rand.uniform(9) end)
    |> Enum.join()
    |> String.to_integer()
  end

  @spec generate_otp_code :: {pos_integer(), pos_integer()}
  defp generate_otp_code do
    case Confex.fetch_env!(:core, :code_length) do
      0 ->
        {"", nil}

      code_length ->
        {:ok, otp_code, _, checksum} =
          code_length
          |> get_number()
          |> Luhn.calculate()

        {otp_code, checksum}
    end
  end

  @spec get_code_expiration_time :: String.t()
  defp get_code_expiration_time do
    DateTime.to_iso8601(Timex.shift(Timex.now(), minutes: Confex.fetch_env!(:core, :code_expiration_period)))
  end

  @spec deactivate_verifications(phone_number :: Integer.t()) :: {integer, nil | [term]} | no_return
  defp deactivate_verifications(phone_number) do
    verification_ids =
      Verification
      |> select([v], v.id)
      |> where(phone_number: ^phone_number)
      |> where(active: true)
      |> Repo.all()

    Verification
    |> where([v], v.id in ^verification_ids)
    |> Repo.update_all(set: [active: false, status: Verification.status(:canceled)])
  end

  @spec cancel_expired_verifications() :: {integer, nil | [term]} | no_return
  def cancel_expired_verifications do
    Verification
    |> where(active: true)
    |> where([v], v.code_expired_at < ^Timex.now())
    |> Repo.update_all(set: [active: false, status: Verification.status(:expired)])
  end
end
