defmodule SMSStatusUpdater.WorkerTest do
  use Core.DataCase
  import Mox

  alias Core.SMSLog.Schema, as: SMSLog
  alias Core.SMSLogs
  alias Core.Repo
  alias SMSStatusUpdater.Worker

  setup :set_mox_global
  setup :verify_on_exit!

  describe "sms logs status update test" do
    test "works fine" do
      expect(WorkerMock, :stop_application, fn -> :ok end)
      SMSLogs.save_and_send_sms(%{"phone_number" => "+380930123456", "body" => "test"})

      Repo.update_all(
        SMSLog,
        set: [inserted_at: Timex.shift(Timex.now(), minutes: -32), gateway_status: "Enroute"]
      )

      {:ok, _pid} = GenServer.start_link(Worker, [])
      :timer.sleep(100)
      sms_logs = Repo.all(SMSLog)
      assert length(sms_logs) == 1
    end
  end
end
