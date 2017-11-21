defmodule OtpVerification.SMSLogs do
  @moduledoc false
  use Timex

  require Logger

  import Ecto.Changeset
  import Ecto.Query
  import Mouth.Message

  alias OtpVerification.Repo
  alias OtpVerification.Messenger
  alias OtpVerification.SMSLog.Schema, as: SMSLog

  def save_and_send_sms(%{"phone_number" => phone_number, "body" => body} = params) do
    type = Map.get(params, "type", "undefined")
    with {_, [status: gateway_status, id: gateway_id, datetime: _]} <- send_sms(phone_number, body),
         %Ecto.Changeset{} = changeset <- create_changeset(%SMSLog{}, %{phone_number: phone_number,
                                                                       body: body,
                                                                       gateway_id: gateway_id,
                                                                       gateway_status: gateway_status,
                                                                       type: type})
    do
      Repo.insert(changeset)
    end
  end

  def create_changeset(%SMSLog{} = schema, attrs) do
    schema
    |> cast(attrs, [:phone_number, :body, :gateway_id, :gateway_status, :type])
  end

  defp send_sms(phone_number, body) do
    new_message()
    |> to(phone_number)
    |> body(body)
    |> Messenger.deliver
  end

  def status_check_job do
    sms_expiration = Confex.get(:otp_verification_api, :sms_statuses_expiration)
    sms_collection = find_sms_for_status_check(sms_expiration)
    collect_status_updates(sms_collection)
  end

  defp find_sms_for_status_check(minutes) do
    SMSLog
    |> where([sms], sms.inserted_at > ^Timex.shift(Timex.now, minutes: -minutes))
    |> where([sms], sms.gateway_status in ^["Accepted", "Enroute", "Unknown"])
    |> Repo.all
  end

  defp collect_status_updates(sms_collection) do
    Stream.run(Task.async_stream(sms_collection, __MODULE__, :update_sms_status, []))
  end

  def update_sms_status(sms) do
    case Messenger.status(sms.gateway_id) do
      {_, [status: status, id: _id, datetime: datetime]} ->
        do_update_sms_status(sms, status, datetime)
      _ -> nil
    end
  end

  defp do_update_sms_status(sms, status, datetime) do
    update_query = change(sms, [gateway_status: status])
    Logger.info(fn ->
    """
    #{inspect sms}
    status: #{status}
    Timex.shift(Timex.now(), minutes: -30): #{Timex.shift(Timex.now(), minutes: -30)}
    """
    end)
    update_query =
      cond do
        status == "Delivered" ->
          put_change(update_query, :status_changed_at, Timezone.convert(Timex.parse!(datetime, "{RFC1123}"), "UTC"))
        sms.inserted_at <= Timex.shift(Timex.now(), minutes: -30) ->
          put_change(update_query, :gateway_status, "Terminated")
        true -> update_query
      end
    Repo.update(update_query)
  end
end
