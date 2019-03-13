defmodule Core.Repo.Migrations.CreateOtpVerification.Verification.VerifiedPhones do
  use Ecto.Migration

  def change do
    create table(:verified_phones, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:phone_number, :string, null: false)
      timestamps(type: :utc_datetime_usec, inserted_at: false)
    end

    create(unique_index(:verified_phones, :phone_number))
  end
end
