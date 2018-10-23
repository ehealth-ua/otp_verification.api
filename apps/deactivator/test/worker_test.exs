defmodule Deactivator.WorkersTest do
  use Core.DataCase
  import Mox
  import Core.Factory
  alias Core.Verification.Verifications
  alias Deactivator.Worker

  setup :set_mox_global
  setup :verify_on_exit!

  test "worker test" do
    expect(WorkerMock, :stop_application, fn -> :ok end)
    insert(:verification, %{code_expired_at: Timex.shift(Timex.now(), minutes: -2)})
    {:ok, _pid} = GenServer.start_link(Worker, [])
    :timer.sleep(100)
    [verification | _] = Verifications.list_verifications()
    refute verification.active == true
  end
end
