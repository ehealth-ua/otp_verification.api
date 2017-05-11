defmodule OtpVerification.Verification.VerifiedPhones do
  @moduledoc false
  use Ecto.Schema

  schema "verified_phones" do
    field :phone_number, :string
    timestamps(type: :utc_datetime, inserted_at: false)
  end
end
