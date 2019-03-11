defmodule Core.Verification.Verification do
  @moduledoc false
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  schema "verifications" do
    field(:check_digit, :integer)
    field(:code, :integer)
    field(:phone_number, :string)
    field(:status, :string)
    field(:code_expired_at, :utc_datetime)
    field(:active, :boolean, default: true)
    field(:attempts_count, :integer, default: 0)

    timestamps(type: :utc_datetime, updated_at: false)
  end

  # verification statuses

  @status_new "new"
  @status_verified "verified"
  @status_unverified "unverified"
  @status_completed "completed"
  @status_canceled "canceled"
  @status_expired "expired"

  def status(:new), do: @status_new
  def status(:verified), do: @status_verified
  def status(:unverified), do: @status_unverified
  def status(:completed), do: @status_completed
  def status(:canceled), do: @status_canceled
  def status(:expired), do: @status_expired

  def status_options do
    [
      @status_new,
      @status_verified,
      @status_unverified,
      @status_completed
    ]
  end
end
