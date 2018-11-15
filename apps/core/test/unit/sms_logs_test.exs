defmodule Core.SMSLogTest do
  use Core.DataCase
  import ExUnit.CaptureLog
  alias Core.SMSLogs

  setup do
    :ets.new(:sms_counter, [:public, :named_table])
    :ets.insert(:sms_counter, {"count", 0})
    :ok
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

  test "sms datetime is invalid" do
    sms = insert(:sms_logs, gateway_status: "Enroute")

    assert capture_log(fn -> SMSLogs.do_update_sms_status(sms, "Accepted", "test") end) =~
             "Error parsing provider datetime"
  end
end
