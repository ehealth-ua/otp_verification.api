defmodule OtpVerification.Repo.Migrations.CreateOtpVerification.Verification.VerifiedPhones do
  use Ecto.Migration

  def change do
    create table(:verified_phones, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :phone_number, :string, null: false
      timestamps(type: :utc_datetime, inserted_at: false)
    end

  end
end
