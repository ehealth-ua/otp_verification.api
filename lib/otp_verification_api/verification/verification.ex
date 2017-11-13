defmodule OtpVerification.Verification.Verification do
  @moduledoc false
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  schema "verifications" do
    field :check_digit, :integer
    field :code, :integer
    field :phone_number, :string
    field :status, :string
    field :code_expired_at, :utc_datetime
    field :active, :boolean, default: true
    field :attempts_count, :integer, default: 0
    timestamps(type: :utc_datetime, updated_at: false)
  end
end
