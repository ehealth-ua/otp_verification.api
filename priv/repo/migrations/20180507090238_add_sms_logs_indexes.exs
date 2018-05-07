defmodule OtpVerification.Repo.Migrations.AddSmsLogsIndexes do
  @moduledoc false

  use Ecto.Migration

  @disable_ddl_transaction true

  def change do
    create(index(:sms_logs, [:inserted_at, :gateway_status], concurrently: true))
    create(index(:sms_logs, [:gateway_id], concurrently: true))
  end
end
