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

  test "changeset is updated" do
    sms = insert(:sms_logs, gateway_status: "Enroute")
    {:ok, updates_sms} = SMSLogs.do_update_sms_status(sms, "Delivered", Timex.format!(Timex.now(), "{RFC1123}"))
    refute is_nil(updates_sms)
    assert updates_sms.gateway_status == "Delivered"
    refute is_nil(updates_sms.inserted_at)
  end

  test "changeset is not updated" do
    sms = insert(:sms_logs, gateway_status: "Enroute")
    assert is_nil(SMSLogs.do_update_sms_status(sms, "Enroute", Timex.format!(Timex.now(), "{RFC1123}")))
  end

  test "sms status is updated to Terminated" do
    sms = insert(:sms_logs, gateway_status: "Enroute", inserted_at: Timex.shift(Timex.now(), minutes: -32))
    {:ok, updates_sms} = SMSLogs.do_update_sms_status(sms, "Accepted", Timex.format!(Timex.now(), "{RFC1123}"))
    assert updates_sms.gateway_status == "Terminated"
  end

  test "sms status is not updated to Terminated" do
    sms = insert(:sms_logs, gateway_status: "Enroute")
    {:ok, updates_sms} = SMSLogs.do_update_sms_status(sms, "Accepted", Timex.format!(Timex.now(), "{RFC1123}"))
    refute updates_sms.gateway_status == "Terminated"
  end
end
