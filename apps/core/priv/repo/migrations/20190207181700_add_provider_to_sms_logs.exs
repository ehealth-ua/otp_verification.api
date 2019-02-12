defmodule Core.Repo.Migrations.AddProviderToSmsLogs do
  use Ecto.Migration

  def change do
    alter table(:sms_logs) do
      add(:provider, :string)
    end
  end
end
