defmodule OtpVerification.Worker do
  @moduledoc false
  require Logger
  use GenServer
  alias OtpVerification.Verification.Verifications

  def start_link(worker_function, opts) do
    GenServer.start_link(__MODULE__, call: worker_function, opts: opts)
  end

  def init(call: worker_function, opts: opts) do
    # Schedule work to be performed at some point
    schedule_work(worker_function, opts)
    {:ok, %{opts: opts}}
  end

  def handle_info(:cancel_verifications, %{opts: opts} = state) do
    Task.start(fn ->
      {canceled_records_count, _} = Verifications.cancel_expired_verifications()
      Logger.info(fn -> "Just cleaned #{canceled_records_count} expired verifications" end)
    end)

    # Reschedule once more
    schedule_work(:cancel_verifications, opts)
    {:noreply, state}
  end

  defp schedule_work(worker_function, opts) do
    miliseconds_to_sleep = Keyword.get(opts, :minutes) * 60 * 1000
    Process.send_after(self(), worker_function, miliseconds_to_sleep)
  end
end
