defmodule SMSStatusUpdater.Worker do
  @moduledoc false

  use GenServer
  alias Core.SMSLogs

  @behaviour SMSStatusUpdater.Behaviours.WorkerBehaviour
  @worker Application.get_env(:sms_status_updater, :worker)

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
    SMSLogs.status_check_job()
    @worker.stop_application()
    {:stop, :normal, state}
  end

  @impl true
  def stop_application do
    System.halt(0)
  end
end
