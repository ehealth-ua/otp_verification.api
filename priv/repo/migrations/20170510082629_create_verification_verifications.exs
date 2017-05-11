defmodule OtpVerification.Repo.Migrations.CreateOtpVerification.Verification.Verifications do
  use Ecto.Migration

  def change do
    create table(:verifications) do
      add :type, :string, null: false
      add :phone_number, :string, null: false
      add :check_digit, :integer, null: false
      add :status, :string, null: false
      add :code, :integer, null: false
      add :code_expired_at, :utc_datetime, null: false
      add :active, :boolean, default: true
    end

  end
end
