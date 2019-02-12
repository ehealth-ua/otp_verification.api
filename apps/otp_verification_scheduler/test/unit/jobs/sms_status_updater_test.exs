defmodule Scheduler.Jobs.SmsStatusUpdaterTest do
  @moduledoc false

  use Core.DataCase, async: false

  alias Scheduler.Jobs.SmsStatusUpdater
  import ExUnit.CaptureLog

  setup do
    :ets.insert(:sms_counter, {"count", 0})
    :ok
  end

  describe "sms logs status update test" do
    test "changeset is updated" do
      sms = insert(:sms_logs, gateway_status: "Enroute")

      {:ok, updates_sms} =
        SmsStatusUpdater.do_update_sms_status(sms, "Delivered", Timex.format!(DateTime.utc_now(), "{RFC1123}"))

      refute is_nil(updates_sms)
      assert updates_sms.gateway_status == "Delivered"
      refute is_nil(updates_sms.inserted_at)
    end

    test "changeset is not updated" do
      sms = insert(:sms_logs, gateway_status: "Enroute")

      assert is_nil(
               SmsStatusUpdater.do_update_sms_status(sms, "Enroute", Timex.format!(DateTime.utc_now(), "{RFC1123}"))
             )
    end

    test "sms status is updated to Terminated" do
      sms =
        insert(:sms_logs, gateway_status: "Enroute", inserted_at: DateTime.add(DateTime.utc_now(), -32 * 60, :second))

      {:ok, updates_sms} =
        SmsStatusUpdater.do_update_sms_status(sms, "Accepted", Timex.format!(DateTime.utc_now(), "{RFC1123}"))

      assert updates_sms.gateway_status == "Terminated"
    end

    test "sms status is not updated to Terminated" do
      sms = insert(:sms_logs, gateway_status: "Enroute")

      {:ok, updates_sms} =
        SmsStatusUpdater.do_update_sms_status(sms, "Accepted", Timex.format!(DateTime.utc_now(), "{RFC1123}"))

      refute updates_sms.gateway_status == "Terminated"
    end

    test "sms datetime is invalid" do
      sms = insert(:sms_logs, gateway_status: "Enroute")

      assert capture_log(fn -> SmsStatusUpdater.do_update_sms_status(sms, "Accepted", "test") end) =~
               "Error parsing provider datetime"
    end
  end
end
