defmodule Core.SMSLogs do
  @moduledoc false
  use Timex

  require Logger

  import Ecto.Changeset
  import Mouth.Message

  alias Core.Messenger
  alias Core.Repo
  alias Core.SMSLog.Schema, as: SMSLog

  def save_and_send_sms(%{"phone_number" => phone_number, "body" => body} = params) do
    type = Map.get(params, "type", "undefined")

    with {_, [status: gateway_status, id: gateway_id, datetime: _]} <- send_sms(phone_number, body),
         %Ecto.Changeset{} = changeset <-
           create_changeset(%SMSLog{}, %{
             phone_number: phone_number,
             body: body,
             gateway_id: gateway_id,
             gateway_status: gateway_status,
             type: type
           }) do
      Repo.insert(changeset)
    end
  end

  def create_changeset(%SMSLog{} = schema, attrs) do
    cast(schema, attrs, [:phone_number, :body, :gateway_id, :gateway_status, :type])
  end

  defp send_sms(phone_number, body) do
    new_message()
    |> to(phone_number)
    |> body(body)
    |> Messenger.deliver()
  end
end
