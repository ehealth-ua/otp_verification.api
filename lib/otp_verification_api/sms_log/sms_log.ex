defmodule OtpVerification.SMSLog.Schema do
  @moduledoc false
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  schema "sms_logs" do
    field(:phone_number, :string, null: false)
    field(:body, :string, null: false)
    field(:gateway_id, :string)
    field(:gateway_status, :string)
    field(:status_changed_at, :utc_datetime)
    field(:type, :string, null: false)
    timestamps(type: :utc_datetime, updated_at: false)
  end
end
