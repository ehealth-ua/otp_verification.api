defmodule Scheduler.Jobs.SmsStatusUpdater do
  @moduledoc false

  use Confex, otp_app: :otp_verification_scheduler
  use Timex
  require Logger
  import Ecto.Changeset
  import Ecto.Query
  alias Core.Messenger.Primary
  alias Core.Messenger.Secondary
  alias Core.Repo
  alias Core.SMSLog.Schema, as: SMSLog

  def run do
    :ets.insert(:sms_counter, {"count", 0})
    sms_expiration = config()[:sms_statuses_expiration]
    sms_collection = find_sms_for_status_check(sms_expiration)
    Logger.info("#{length(sms_collection)} sms collected")
    collect_status_updates(sms_collection)
  end

  defp collect_status_updates(sms_collection) do
    sms_collect_timeout = config()[:sms_collect_timeout]
    Stream.run(Task.async_stream(sms_collection, __MODULE__, :update_sms_status, [], timeout: sms_collect_timeout))
    [{_, count}] = :ets.lookup(:sms_counter, "count")
    Logger.info("#{count} sms updated")
    {:ok, count}
  end

  defp find_sms_for_status_check(minutes) do
    SMSLog
    |> where([sms], sms.inserted_at > ^DateTime.add(DateTime.utc_now(), -minutes * 60, :second))
    |> where([sms], sms.gateway_status in ^[SMSLog.status(:accepted), SMSLog.status(:enroute), SMSLog.status(:unknown)])
    |> Repo.all()
  end

  def update_sms_status(%SMSLog{provider: "mouth_twilio"} = sms) do
    case Primary.status(sms.gateway_id) do
      {_, [status: status, id: _id, datetime: datetime]} ->
        do_update_sms_status(sms, status, datetime)

      _ ->
        nil
    end
  end

  def update_sms_status(%SMSLog{provider: "mouth_sms2ip"} = sms) do
    case Secondary.status(sms.gateway_id) do
      {_, [status: status, id: _id, datetime: datetime]} ->
        do_update_sms_status(sms, status, datetime)

      _ ->
        nil
    end
  end

  def do_update_sms_status(sms, status, datetime) do
    case Timex.parse(datetime, "{RFC1123}") do
      {:ok, datetime} ->
        sms_update_timeout =
          DateTime.utc_now()
          |> DateTime.add(-config()[:sms_update_timeout] * 60, :second)
          |> DateTime.to_naive()

        should_update_sms_status = NaiveDateTime.compare(sms.inserted_at, sms_update_timeout) in ~w(lt eq)a

        update_query = change(sms, gateway_status: status)

        update_query =
          if should_update_sms_status,
            do: put_change(update_query, :gateway_status, SMSLog.status(:terminated)),
            else: update_query

        if get_change(update_query, :gateway_status) do
          result =
            update_query
            |> put_change(:status_changed_at, Timezone.convert(datetime, "UTC"))
            |> Repo.update()

          :ets.update_counter(:sms_counter, "count", 1)

          result
        end

      {:error, _} ->
        Logger.error("Error parsing provider datetime: #{datetime} (sms id #{sms.id})")
    end
  end
end
