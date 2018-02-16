defmodule OtpVerification.SMSLogTest do
  use OtpVerification.DataCase

  alias OtpVerification.SMSLogs
  alias OtpVerification.Repo

  describe "sms logs status update test" do
    test "works fine" do
      SMSLogs.save_and_send_sms(%{"phone_number" => "+380930123456", "body" => "test"})

      Repo.update_all(
        OtpVerification.SMSLog.Schema,
        set: [inserted_at: Timex.shift(Timex.now(), minutes: -32), gateway_status: "Enroute"]
      )

      SMSLogs.status_check_job()
      sms_logs = OtpVerification.Repo.all(OtpVerification.SMSLog.Schema)
      assert length(sms_logs) == 1
    end
  end
end
