defmodule OtpVerification.Verification.Verifications do
  @moduledoc """
  The boundary for the Verification system.
  """

  import Ecto.{Query, Changeset}, warn: false
  import Mouth.Message
  alias OtpVerification.Repo
  alias OtpVerification.Messenger
  alias OtpVerification.Verification.Verification
  alias OtpVerification.Verification.VerifiedPhone
  alias EView.Changeset.Validators.PhoneNumber

  @doc """
  Returns the list of verifications.

  ## Examples

      iex> list_verifications()
      [%OtpVerification.Verification.Verifications{}]

  """
  @spec list_verifications :: [Verification.t] | []
  def list_verifications do
    Repo.all(Verification)
  end

  @doc """
  Gets a single verification.

  Raises `Ecto.NoResultsError` if the Verification does not exist.

  ## Examples

      iex> get_verification!(123)
      %OtpVerification.Verification.Verification{}

      iex> get_verification!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_verification(id :: String.t) :: Verification.t | nil | no_return
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
      %OtpVerification.Verification.Verification
  """
  @spec get_verification_by(params :: Keyword.t) :: Verification.t | []
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
      {:ok, %OtpVerification.Verification.Verification{}}

      iex> create_verification(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_verification(attrs :: %{}) :: {:ok, Verification.t} | {:error, Ecto.Changeset.t}
  def create_verification(attrs \\ %{}) do
    %Verification{}
    |> verification_changeset(attrs)
    |> Repo.insert()
  end

  @spec add_verified_phone(verification :: %Verification{}) :: {:ok, Verification.t} | {:error, Ecto.Changeset.t}
  def add_verified_phone(%Verification{} = verification) do
    verified_phone =
      VerifiedPhone
      |> where(phone_number: ^verification.phone_number)
      |> first
      |> Repo.one
    case verified_phone do
      nil ->
        %VerifiedPhone{}
        |> verified_phone_changeset(%{phone_number: verification.phone_number})
        |> Repo.insert()
      verified_phone -> {:ok, verified_phone}
    end
  end

  @spec initialize_verification(attrs :: %{}) :: {:ok, Verification.t} | {:error, Ecto.Changeset.t}
  def initialize_verification(attrs) do
    with attrs <- initialize_attrs(attrs) do

      deactivate_verifications(attrs["phone_number"])

      %Verification{}
      |> verification_changeset(attrs)
      |> Repo.insert()
    end
  end

  defp send_sms(phone_number, code) do
    sms_text = Confex.get(:otp_verification_api, :code_text)
    sms_text = sms_text <> to_string(code)
    new_message()
    |> to(phone_number)
    |> body(sms_text)
    |> Messenger.deliver
  end

  @spec initialize_verification(%{}) :: %{}
  defp initialize_attrs(attrs) do
    {otp_code, checksum} = generate_otp_code()
    code_expired_at = get_code_expiration_time()

    {:ok, [status: gateway_status, id: gateway_id]} = send_sms(attrs["phone_number"], otp_code)
    Map.merge(attrs,
      %{
        "check_digit" => checksum, "code" => otp_code,
        "status" => "new", "code_expired_at" => code_expired_at,
        "gateway_status" => gateway_status, "gateway_id" => gateway_id
        })
  end

  @spec verify(verification :: %{code: Integer.t}, code :: Integer.t) :: tuple()
  def verify(%Verification{code: verification_code} = verification, code) do
    with is_verified <- Timex.before?(Timex.now, verification.code_expired_at) and verification_code == code do
      case is_verified do
        true -> verification_completed(verification)
        false -> verification_does_not_completed(verification)
      end
    end
  end

  @spec verification_completed(verification :: Verification.t) :: tuple()
  defp verification_completed(%Verification{} = verification) do
    verification
    |> update_verification(%{status: "verified", active: false, attempts_count: verification.attempts_count + 1})
    |> Tuple.append(:verified)
  end

  @spec verification_does_not_completed(verification :: Verification.t) :: tuple()
  defp verification_does_not_completed(%Verification{} = verification) do
    max_attempts = Confex.get(:otp_verification_api, :max_attempts)
    attempts_count = verification.attempts_count + 1
    attrs = case attempts_count do
      attempts_count when attempts_count < max_attempts ->
        %{attempts_count: attempts_count}
      attempts_count when attempts_count >= max_attempts ->
        %{status: "unverified", active: false, attempts_count: attempts_count}
    end
    verification
    |> update_verification(attrs)
    |> Tuple.append(:not_verified)
  end

  @doc """
  Updates a verification.

  ## Examples

      iex> update_verification(verification, %{field: new_value})
      {:ok, %OtpVerification.Verification.Verification{}}

      iex> update_verification(verification, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_verification(verification :: Verification.t, %{}) :: {:ok, Verification.t} | {:error, Ecto.Changeset.t}
  def update_verification(%Verification{} = verification, attrs) do
    verification
    |> verification_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Verification.

  ## Examples

      iex> delete_verification(verification)
      {:ok, %OtpVerification.Verification.Verification{}}

      iex> delete_verification(verification)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_verification(verification :: Verification.t) :: {:ok, Verification.t} |{:error, Ecto.Changeset.t}
  def delete_verification(%Verification{} = verification) do
    Repo.delete(verification)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking verification changes.

  ## Examples

      iex> change_verification(verification)
      %Ecto.Changeset{}

  """
  @spec change_verification(verification :: Verification.t) :: Ecto.Changeset.t
  def change_verification(%Verification{} = verification) do
    verification_changeset(verification, %{})
  end

  @spec verification_changeset(verification :: Verification.t, %{}) :: Ecto.Changeset.t
  defp verification_changeset(%Verification{} = verification, attrs) do
    verification
    |> cast(attrs, [:phone_number, :check_digit, :status, :code,
                    :code_expired_at, :active, :gateway_id, :gateway_status, :attempts_count])
    |> validate_required([:phone_number, :check_digit, :status, :code, :code_expired_at])
    |> validate_inclusion(:status, ["new", "verified", "unverified", "completed"])
    |> PhoneNumber.validate_phone_number(:phone_number)
  end

  @spec verification_changeset(verification :: Verification.t, %{}) :: Ecto.Changeset.t
  defp verified_phone_changeset(%VerifiedPhone{} = verified_phone, attrs) do
    verified_phone
    |> cast(attrs, [:phone_number])
    |> validate_required([:phone_number])
    |> unique_constraint(:phone_number)
    |> PhoneNumber.validate_phone_number(:phone_number)
  end

  @spec get_number(number_length :: pos_integer()) :: pos_integer()
  defp get_number(number_length) do
    1..number_length - 1
    |> Enum.map(fn _ -> :rand.uniform(9) end)
    |> Enum.join
    |> String.to_integer
  end

  @spec generate_otp_code :: {pos_integer(), pos_integer()}
  defp generate_otp_code do
    {:ok, otp_code, _, checksum} =
      :otp_verification_api
      |> Confex.get(:code_length)
      |> get_number()
      |> Luhn.calculate()
    {otp_code, checksum}
  end

  @spec get_code_expiration_time :: String.t
  defp get_code_expiration_time, do:
    DateTime.to_iso8601(Timex.shift(Timex.now, minutes: Confex.get(:otp_verification_api, :code_expiration_period)))

  @spec deactivate_verifications(phone_number :: Integer.t) :: {integer, nil | [term]} | no_return
  defp deactivate_verifications(phone_number) do
    Verification
    |> where(phone_number: ^phone_number)
    |> where(active: true)
    |> Repo.update_all(set: [active: false, status: "canceled"])
  end

  @spec cancel_expired_verifications() :: {integer, nil | [term]} | no_return
  def cancel_expired_verifications do
    Verification
    |> where(active: true)
    |> where([v], v.code_expired_at < ^Timex.now)
    |> Repo.update_all(set: [active: false, status: "expired"])
  end

  @spec check_gateway_status(verification :: Verification.t) :: {:ok, Verification.t} | {:error, Ecto.Changeset.t}
  def check_gateway_status(verification) do
    {_, [status: gateway_status, id: _]} = Messenger.status(verification.gateway_id)
    update_verification(verification, %{gateway_status: gateway_status})
  end
end
