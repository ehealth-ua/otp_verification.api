defmodule Core.SMSLogs do
  @moduledoc false

  use Confex, otp_app: :core
  require Logger
  import Ecto.Changeset
  import Mouth.Message
  alias Core.Messenger.Primary
  alias Core.Messenger.Secondary
  alias Core.Repo
  alias Core.SMSLog.Schema, as: SMSLog

  @behaviour Core.SMSLogsBehaviour
  @sms_sender_client Application.get_env(:core, :api_resolvers)[:sms_sender]

  def save_and_send_sms(%{"phone_number" => phone_number, "body" => body} = params) do
    type = params["type"] || "undefined"
    sms_provider = provider(params["provider"])

    with {_, [status: gateway_status, id: gateway_id, datetime: _]} <- send_sms(phone_number, body, sms_provider),
         %Ecto.Changeset{} = changeset <-
           create_changeset(%SMSLog{}, %{
             phone_number: phone_number,
             body: body,
             gateway_id: gateway_id,
             gateway_status: gateway_status,
             type: type,
             provider: to_string(sms_provider)
           }) do
      Repo.insert(changeset)
    end
  end

  def create_changeset(%SMSLog{} = schema, attrs) do
    cast(schema, attrs, [:phone_number, :body, :gateway_id, :gateway_status, :type, :provider])
  end

  defp provider("mouth_sms2ip"), do: :mouth_sms2ip
  defp provider("mouth_twilio"), do: :mouth_twilio
  defp provider(nil), do: config()[:default_adapter]

  defp provider(undefined) do
    Logger.error("Provider #{undefined} is not defined in config, default provider will be used")
    config()[:default_adapter]
  end

  def handle_adapter_config(%{adapter: adapter} = base_config) do
    adapter.handle_config(base_config)
  end

  defp sms_config_provider(sms_provider) do
    Confex.fetch_env!(:core, sms_provider)
    |> Map.new()
    |> handle_adapter_config()
  end

  defp send_sms(phone_number, body, provider) do
    provider_config = sms_config_provider(provider)

    new_message()
    |> to(phone_number)
    |> body(body)
    |> @sms_sender_client.deliver(provider_config, provider)
  end

  @impl true
  def deliver(message, provider_config, :mouth_twilio), do: Primary.deliver(message, provider_config)
  def deliver(message, provider_config, :mouth_sms2ip), do: Secondary.deliver(message, provider_config)
end
