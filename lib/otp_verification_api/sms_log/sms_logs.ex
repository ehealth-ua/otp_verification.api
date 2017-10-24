defmodule OtpVerification.SMSLogs do
  @moduledoc false
  import Ecto.Changeset
  import Mouth.Message

  alias OtpVerification.Repo
  alias OtpVerification.Messenger
  alias OtpVerification.SMSLog.Schema, as: SMSLog

  def save_and_send_sms(%{"phone_number" => phone_number, "body" => body}) do
    with {:ok, [status: gateway_status, id: gateway_id]} <- send_sms(phone_number, body),
         %Ecto.Changeset{} = changeset <- create_changeset(%SMSLog{}, %{phone_number: phone_number,
                                                                       body: body,
                                                                       gateway_id: gateway_id,
                                                                       gateway_status: gateway_status})
    do
      Repo.insert(changeset)
    end
  end

  def create_changeset(%SMSLog{} = schema, attrs) do
    schema
    |> cast(attrs, [:phone_number, :body, :gateway_id, :gateway_status])
  end

  defp send_sms(phone_number, body) do
    new_message()
    |> to(phone_number)
    |> body(body)
    |> Messenger.deliver
  end
end
