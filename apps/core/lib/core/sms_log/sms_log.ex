defmodule Core.SMSLog.Schema do
  @moduledoc false
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "sms_logs" do
    field(:phone_number, :string, null: false)
    field(:body, :string, null: false)
    field(:gateway_id, :string)
    field(:gateway_status, :string)
    field(:status_changed_at, :utc_datetime)
    field(:type, :string, null: false)
    field(:provider, :string)

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  @gateway_status_accepted "Accepted"
  @gateway_status_enroute "Enroute"
  @gateway_status_unknown "Unknown"
  @gateway_status_terminated "Terminated"

  def status(:accepted), do: @gateway_status_accepted
  def status(:enroute), do: @gateway_status_enroute
  def status(:unknown), do: @gateway_status_unknown
  def status(:terminated), do: @gateway_status_terminated
end
