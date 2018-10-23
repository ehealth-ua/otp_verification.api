defmodule Deactivator.Worker do
  @moduledoc false

  use GenServer
  require Logger
  alias Core.SMSLogs
  alias Core.Verification.Verifications

  @behaviour Deactivator.Behaviours.WorkerBehaviour
  @worker Application.get_env(:deactivator, :worker)

  def start_link do
    GenServer.start_link(__MODULE__, nil)
  end

  @impl true
  def init(state) do
    Process.send_after(self(), :run, 10)
    {:ok, state}
  end

  @impl true
  def handle_info(:run, state) do
    {canceled_records_count, _} = Verifications.cancel_expired_verifications()
    Logger.info(fn -> "Just cleaned #{canceled_records_count} expired verifications" end)
    @worker.stop_application()
    {:stop, :normal, state}
  end

  @impl true
  def stop_application do
    System.halt(0)
  end
end
