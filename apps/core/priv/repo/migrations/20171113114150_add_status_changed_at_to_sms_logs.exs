defmodule Core.Repo.Migrations.AddStatusChangedAtToSmsLogs do
  use Ecto.Migration

  def change do
    alter table(:sms_logs) do
      add(:status_changed_at, :utc_datetime)
    end
  end
end
