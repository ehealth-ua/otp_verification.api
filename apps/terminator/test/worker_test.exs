defmodule Terminator.WorkersTest do
  use Core.DataCase
  import Mox
  import Core.Factory
  alias Core.Verification.Verifications
  alias Terminator.Worker

  setup :set_mox_global
  setup :verify_on_exit!

  test "worker test when validations_expired_timeout is defined" do
    expect(WorkerMock, :stop_application, fn -> :ok end)
    current_value = Application.get_env(:terminator, :validations_expired_timeout)
    Application.put_env(:terminator, :validations_expired_timeout, 2)

    verification_in = insert(:verification, %{inserted_at: Timex.shift(Timex.now(), days: -1)})

    verification_out = insert(:verification, %{inserted_at: Timex.shift(Timex.now(), days: -3)})

    {:ok, _pid} = GenServer.start_link(Worker, [])
    :timer.sleep(100)

    verification_ids =
      Enum.map(Verifications.list_verifications(), fn verification ->
        verification.id
      end)

    assert verification_in.id in verification_ids
    refute verification_out.id in verification_ids

    on_exit(fn ->
      Application.put_env(:terminator, :validations_expired_timeout, current_value)
    end)
  end

  test "worker test when validations_expired_timeout is not defined" do
    expect(WorkerMock, :stop_application, fn -> :ok end)
    current_value = Application.get_env(:terminator, :validations_expired_timeout)
    Application.put_env(:terminator, :validations_expired_timeout, nil)

    insert(:verification, %{inserted_at: Timex.shift(Timex.now(), days: -1)})
    insert(:verification, %{inserted_at: Timex.shift(Timex.now(), days: -3)})

    {:ok, _pid} = GenServer.start_link(Worker, [])
    :timer.sleep(100)

    assert length(Verifications.list_verifications()) == 2

    on_exit(fn ->
      Application.put_env(:terminator, :validations_expired_timeout, current_value)
    end)
  end
end
