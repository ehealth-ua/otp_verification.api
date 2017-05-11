defmodule OtpVerification.Verification do
  @moduledoc """
  The boundary for the Verification system.
  """

  import Ecto.{Query, Changeset}, warn: false
  alias OtpVerification.Repo

  alias OtpVerification.Verification.Verifications
  alias OtpVerification.Verification.Verifications.Search
  alias OtpVerification.Verification.VerifiedPhones
  alias EView.Changeset.Validators.PhoneNumber

  @doc """
  Returns the list of verifications.

  ## Examples

      iex> list_verifications()
      [%Verifications{}, ...]

  """
  def list_verifications do
    Repo.all(Verifications)
  end

  @doc """
  Gets a single verifications.

  Raises `Ecto.NoResultsError` if the Verifications does not exist.

  ## Examples

      iex> get_verifications!(123)
      %Verifications{}

      iex> get_verifications!(456)
      ** (Ecto.NoResultsError)

  """
  def get_verifications!(id), do: Repo.get!(Verifications, id)
  def get_verifications(id), do: Repo.get(Verifications, id)

  @doc """
  Creates a verifications.

  ## Examples

      iex> create_verifications(%{field: value})
      {:ok, %Verifications{}}

      iex> create_verifications(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_verifications(attrs \\ %{}) do
    %Verifications{}
    |> verifications_changeset(attrs)
    |> Repo.insert()
  end

  def add_verified_phone(%Verifications{} = verification) do
    %VerifiedPhones{}
    |> verified_phone_changeset(%{phone_number: verification.phone_number})
    |> Repo.insert()
  end

  def search(%Ecto.Changeset{} = changeset) do
    Verifications
    |> maybe_filter_phone(changeset)
    |> maybe_filter_statuses(changeset)
    |> Repo.all()
  end

  def maybe_filter_phone(query, changeset) do
    case get_change(changeset, :phone) do
      nil -> query
      phone -> where(query, [v], v.phone_number == ^phone)
    end
  end

  def maybe_filter_statuses(query, changeset) do
    case get_change(changeset, :statuses) do
      nil -> query
      statuses -> where(query, [v], v.status in ^String.split(statuses, ","))
    end
  end

  def initialize_verifications(attrs) do
    {otp_code, checksum} = generate_otp_code()
    code_expired_at = get_code_expiration_time()

    attrs =
      Map.merge(attrs,
        %{"check_digit" => checksum, "code" => otp_code, "status" => "created", "code_expired_at" => code_expired_at})

    %Verifications{}
    |> verifications_changeset(attrs)
    |> Repo.insert()
  end

  def verify(%Verifications{code: verification_code} = verification, code) do
    case Timex.before?(Timex.now, verification.code_expired_at) and verification_code == code do
      true -> verification_completed(verification)
      false -> verification_does_not_completed(verification)
    end
  end

  def verification_completed(%Verifications{} = verification) do
    verification
    |> update_verifications(%{status: "completed", active: false})
    |> Tuple.append(:verified)
  end

  def verification_does_not_completed(%Verifications{} = verification) do
    verification
    |> update_verifications(%{status: "unverified", active: false})
    |> Tuple.append(:not_verified)
  end

  defp generate_otp_code do
    {:ok, otp_code, _, checksum} =
      :otp_verification_api
      |> Confex.get(:code_length)
      |> get_number()
      |> Luhn.calculate()

    {otp_code, checksum}
  end

  defp get_code_expiration_time, do:
    DateTime.to_iso8601(Timex.shift(Timex.now, minutes: Confex.get(:otp_verification_api, :code_expiration_period)))

  @doc """
  Updates a verifications.

  ## Examples

      iex> update_verifications(verifications, %{field: new_value})
      {:ok, %Verifications{}}

      iex> update_verifications(verifications, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_verifications(%Verifications{} = verifications, attrs) do
    verifications
    |> verifications_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Verifications.

  ## Examples

      iex> delete_verifications(verifications)
      {:ok, %Verifications{}}

      iex> delete_verifications(verifications)
      {:error, %Ecto.Changeset{}}

  """
  def delete_verifications(%Verifications{} = verifications) do
    Repo.delete(verifications)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking verifications changes.

  ## Examples

      iex> change_verifications(verifications)
      %Ecto.Changeset{source: %Verifications{}}

  """
  def change_verifications(%Verifications{} = verifications) do
    verifications_changeset(verifications, %{})
  end

  defp verifications_changeset(%Verifications{} = verifications, attrs) do
    verifications
    |> cast(attrs, [:type, :phone_number, :check_digit, :status, :code, :code_expired_at])
    |> validate_required([:type, :phone_number, :check_digit, :status, :code, :code_expired_at])
    |> validate_inclusion(:type, ["otp"])
    |> validate_inclusion(:status, ["created", "completed", "unverified"])
    |> PhoneNumber.validate_phone_number(:phone_number)
  end

  defp verified_phone_changeset(%VerifiedPhones{} = verified_phones, attrs) do
    verified_phones
    |> cast(attrs, [:phone_number])
    |> validate_required([:phone_number])
    |> PhoneNumber.validate_phone_number(:phone_number)
  end

  def search_changeset(attrs) do
    %Search{}
    |> cast(attrs, [:phone_number, :statuses])
    |> PhoneNumber.validate_phone_number(:phone_number)
    |> verify_each_status()
  end

  def verify_each_status(changeset) do

    case get_field(changeset, :statuses) do
      nil -> changeset
      statuses ->
        Enum.reduce(String.split(statuses, ","), changeset, fn(status, acc) -> validate_status(acc, status) end)
    end

  end

  def validate_status(changeset, value) do
    if value in ["created", "completed", "unverified"],
      do: changeset,
      else: add_error(changeset, :statuses, "is invalid")
  end

  def get_number(number_length) do
    {number, ""} =
      Integer.parse 1..number_length
      |> Enum.map_join(fn(_) ->  :rand.uniform(10) - 1 end)
    number
  end
end
