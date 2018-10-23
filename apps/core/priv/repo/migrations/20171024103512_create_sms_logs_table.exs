defmodule Core.Repo.Migrations.CreateSmsLogsTable do
  use Ecto.Migration

  def change do
    create table(:sms_logs, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:phone_number, :string, null: false)
      add(:body, :string, null: false)
      add(:gateway_id, :string)
      add(:gateway_status, :string)
      timestamps(updated_at: false, type: :utc_datetime)
    end
  end
end
