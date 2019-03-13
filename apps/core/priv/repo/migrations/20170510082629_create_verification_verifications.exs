defmodule Core.Repo.Migrations.CreateOtpVerification.Verification.Verifications do
  use Ecto.Migration

  def change do
    create table(:verifications, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:phone_number, :string, null: false)
      add(:check_digit, :integer, null: false)
      add(:status, :string, null: false)
      add(:code, :integer, null: false)
      add(:code_expired_at, :utc_datetime, null: false)
      add(:active, :boolean, default: true)
      add(:gateway_id, :string)
      add(:gateway_status, :string)
      add(:attempts_count, :integer, default: 0)
      timestamps(updated_at: false, type: :utc_datetime_usec)
    end
  end
end
