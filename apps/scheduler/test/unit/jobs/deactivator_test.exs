defmodule Scheduler.Jobs.DeactivatorTest do
  @moduledoc false

  use Core.DataCase
  import Core.Factory
  alias Core.Verification.Verifications
  alias Scheduler.Jobs.Deactivator

  test "worker test" do
    insert(:verification, %{code_expired_at: Timex.shift(Timex.now(), minutes: -2)})
    assert {:ok, 1} == Deactivator.run()
    [verification | _] = Verifications.list_verifications()
    refute verification.active == true
  end
end
