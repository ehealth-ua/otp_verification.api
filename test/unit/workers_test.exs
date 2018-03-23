defmodule OtpVerification.WorkersTest do
  use OtpVerification.DataCase
  import OtpVerification.Factory
  alias OtpVerification.Verification.Verifications

  test "worker test" do
    insert(:verification, %{code_expired_at: Timex.shift(Timex.now(), minutes: -2)})
    send(OtpVerification.Worker, :cancel_verifications)
    :timer.sleep(100)
    [verification | _] = Verifications.list_verifications()
    refute verification.active == true
  end
end
