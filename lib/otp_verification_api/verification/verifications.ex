defmodule OtpVerification.Verification.Verifications do
  @moduledoc false
  use Ecto.Schema

  schema "verifications" do
    field :check_digit, :integer
    field :code, :integer
    field :phone_number, :string
    field :status, :string
    field :type, :string
    field :code_expired_at, :utc_datetime
    field :active, :boolean, default: true
  end
end
