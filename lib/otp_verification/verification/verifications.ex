defmodule OtpVerification.Verification.Verifications do
  use Ecto.Schema

  schema "verifications" do
    field :check_digit, :integer
    field :code, :integer
    field :phone_number, :string
    field :status, :string
    field :type, :string
  end
end
