defmodule OtpVerification.Verification.Verifications do
  @moduledoc """
  The boundary for the Verification system.
  """

  import Ecto.{Query, Changeset}, warn: false
  alias OtpVerification.Repo

  alias OtpVerification.Verification.Verification
  alias OtpVerification.Verification.Search
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

  @doc """
  Gets a single verification.

  Raises `Ecto.NoResultsError` if the Verification does not exist.

  ## Examples

      iex> get_verification_by(123)
      %OtpVerification.Verification.Verification
  """
  @spec get_verification_by(params :: Keyword.t) :: Verification.t | []
  def get_verification_by(params), do: Repo.get_by(Verification, params)

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
    %VerifiedPhone{}
    |> verified_phone_changeset(%{phone_number: verification.phone_number})
    |> Repo.insert()
  end

  @spec search(changeset :: %Ecto.Changeset{}) ::   [Verification.t] | []
  def search(%Ecto.Changeset{} = changeset) do
    Verification
    |> maybe_filter_phone(changeset)
    |> maybe_filter_statuses(changeset)
    |> Repo.all()
  end

  @spec initialize_verification(attrs :: %{}) :: {:ok, Verification.t} | {:error, Ecto.Changeset.t}
  def initialize_verification(attrs) do
    {otp_code, checksum} = generate_otp_code()
    code_expired_at = get_code_expiration_time()

    attrs =
      Map.merge(attrs,
        %{"check_digit" => checksum, "code" => otp_code, "status" => "created", "code_expired_at" => code_expired_at})

    deactivate_verifications(attrs["phone_number"])

    %Verification{}
    |> verification_changeset(attrs)
    |> Repo.insert()
  end

  @spec verify(verification :: %{code: Integer.t}, code :: Integer.t) :: tuple()
  def verify(%Verification{code: verification_code} = verification, code) do
    case Timex.before?(Timex.now, verification.code_expired_at) and verification_code == code do
      true -> verification_completed(verification)
      false -> verification_does_not_completed(verification)
    end
  end

  @spec verification_completed(verification :: Verification.t) :: tuple()
  defp verification_completed(%Verification{} = verification) do
    verification
    |> update_verification(%{status: "completed", active: false})
    |> Tuple.append(:verified)
  end

  @spec verification_does_not_completed(verification :: Verification.t) :: tuple()
  defp verification_does_not_completed(%Verification{} = verification) do
    verification
    |> update_verification(%{status: "unverified", active: false})
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
    |> cast(attrs, [:type, :phone_number, :check_digit, :status, :code, :code_expired_at])
    |> validate_required([:type, :phone_number, :check_digit, :status, :code, :code_expired_at])
    |> validate_inclusion(:type, ["otp"])
    |> validate_inclusion(:status, ["created", "completed", "unverified"])
    |> PhoneNumber.validate_phone_number(:phone_number)
  end

  @spec search_changeset(%{phone_number: Stringt.t, statuses: String.t}) :: Ecto.Changeset.t
  def search_changeset(attrs) do
    %Search{}
    |> cast(attrs, [:phone_number, :statuses])
    |> PhoneNumber.validate_phone_number(:phone_number)
    |> verify_each_status()
  end

  @spec verification_changeset(verification :: Verification.t, %{}) :: Ecto.Changeset.t
  defp verified_phone_changeset(%VerifiedPhone{} = verified_phones, attrs) do
    verified_phones
    |> cast(attrs, [:phone_number])
    |> validate_required([:phone_number])
    |> PhoneNumber.validate_phone_number(:phone_number)
  end

  @spec verify_each_status(changeset :: %Ecto.Changeset{}) :: Ecto.Changeset.t
  defp verify_each_status(changeset) do
    case get_field(changeset, :statuses) do
      nil -> changeset
      statuses ->
        Enum.reduce(String.split(statuses, ","), changeset, fn(status, acc) -> validate_status(acc, status) end)
    end
  end

  @spec validate_status(changeset :: %Ecto.Changeset{}, value :: String.t) :: Ecto.Changeset.t
  defp validate_status(changeset, value) do
    if value in ["created", "completed", "unverified"],
      do: changeset,
      else: add_error(changeset, :statuses, "is invalid")
  end

  @spec get_number(number_length :: pos_integer()) :: pos_integer()
  defp get_number(number_length) do
    1..number_length
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

  @spec maybe_filter_phone(query :: Ecto.Query.t, changeset :: %Ecto.Changeset{}) :: Ecto.Query.t
  defp maybe_filter_phone(query, changeset) do
    case get_change(changeset, :phone_number) do
      nil -> query
      phone -> where(query, [v], v.phone_number == ^phone)
    end
  end

  @spec maybe_filter_statuses(query :: Ecto.Query.t, changeset :: %Ecto.Changeset{}) :: Ecto.Query.t
  defp maybe_filter_statuses(query, changeset) do
    case get_change(changeset, :statuses) do
      nil -> query
      statuses -> where(query, [v], v.status in ^String.split(statuses, ","))
    end
  end

  @spec get_code_expiration_time :: String.t
  defp get_code_expiration_time, do:
    DateTime.to_iso8601(Timex.shift(Timex.now, minutes: Confex.get(:otp_verification_api, :code_expiration_period)))

  @spec deactivate_verifications(phone_number :: Integer.t) :: {integer, nil | [term]} | no_return
  defp deactivate_verifications(phone_number) do
    Verification
    |> where(phone_number: ^phone_number)
    |> where(active: true)
    |> Repo.update_all(set: [active: false])
  end
end
