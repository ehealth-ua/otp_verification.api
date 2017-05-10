defmodule OtpVerification.Verification do
  @moduledoc """
  The boundary for the Verification system.
  """

  import Ecto.{Query, Changeset}, warn: false
  alias OtpVerification.Repo

  alias OtpVerification.Verification.Verifications

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

  def initialize_verifications(attrs) do
#    get_number(4)
#    |> IO.inspect
  end

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
    |> cast(attrs, [:type, :phone_number, :check_digit, :status, :code])
    |> validate_required([:type, :phone_number, :check_digit, :status, :code])
  end

  def get_number( length ) do
      { number, "" } =
        Integer.parse 1..length
        |> Enum.map_join( fn(_) ->  :random.uniform(10) - 1 end )

      number
  end
end
