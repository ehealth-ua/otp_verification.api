defmodule Core.SMSLogs do
  @moduledoc false
  use Timex

  require Logger

  import Ecto.Changeset
  import Ecto.Query
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
    schema
    |> cast(attrs, [:phone_number, :body, :gateway_id, :gateway_status, :type])
  end

  defp send_sms(phone_number, body) do
    new_message()
    |> to(phone_number)
    |> body(body)
    |> Messenger.deliver()
  end

  def status_check_job do
    sms_expiration = Confex.fetch_env!(:core, :sms_statuses_expiration)
    sms_collection = find_sms_for_status_check(sms_expiration)
    collect_status_updates(sms_collection)
  end

  defp find_sms_for_status_check(minutes) do
    SMSLog
    |> where([sms], sms.inserted_at > ^Timex.shift(Timex.now(), minutes: -minutes))
    |> where([sms], sms.gateway_status in ^[SMSLog.status(:accepted), SMSLog.status(:enroute), SMSLog.status(:unknown)])
    |> Repo.all()
  end

  defp collect_status_updates(sms_collection) do
    sms_collect_timeout = Confex.fetch_env!(:core, :sms_collect_timeout)
    Stream.run(Task.async_stream(sms_collection, __MODULE__, :update_sms_status, [], timeout: sms_collect_timeout))
  end

  def update_sms_status(sms) do
    case Messenger.status(sms.gateway_id) do
      {_, [status: status, id: _id, datetime: datetime]} ->
        do_update_sms_status(sms, status, datetime)

      _ ->
        nil
    end
  end

  def do_update_sms_status(sms, status, datetime) do
    sms_update_timeout = Confex.fetch_env!(:core, :sms_update_timeout)

    should_update_sms_status =
      DateTime.compare(sms.inserted_at, Timex.shift(Timex.now(), minutes: -sms_update_timeout)) in [:lt, :eq]

    update_query = change(sms, gateway_status: status)

    update_query =
      if should_update_sms_status,
        do: put_change(update_query, :gateway_status, SMSLog.status(:terminated)),
        else: update_query

    if get_change(update_query, :gateway_status) do
      update_query
      |> put_change(:status_changed_at, Timezone.convert(Timex.parse!(datetime, "{RFC1123}"), "UTC"))
      |> Repo.update()
    end
  end
end
