defmodule OtpVerification.Repo.Migrations.AddTypeToSmsLogs do
  use Ecto.Migration

  def change do
    alter table(:sms_logs) do
      add :type, :string, null: false, default: "undefined"
    end
  end
end
