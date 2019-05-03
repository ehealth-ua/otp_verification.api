defmodule Core.MultipleProvidersTest do
  @moduledoc false

  use Core.DataCase, async: false
  alias Core.SMSLog.Schema
  alias Core.SMSLogs
  alias Mouth.Messenger
  import Mox

  test "save_and_send_sms without defined probider" do
    expect(SMSLogsMock, :deliver, fn message, config, _provider ->
      Messenger.deliver(message, config)
    end)

    assert {:ok, %Schema{provider: "mouth_twilio"}} = SMSLogs.save_and_send_sms("+380936020123", "TEST", "undefined")
  end

  test "save_and_send_sms with defined probider mouth_twilio" do
    expect(SMSLogsMock, :deliver, fn message, config, _provider ->
      Messenger.deliver(message, config)
    end)

    assert {:ok, %Schema{provider: "mouth_twilio"}} =
             SMSLogs.save_and_send_sms("+380936020123", "TEST", "undefined", "mouth_twilio")
  end

  test "save_and_send_sms with defined probider mouth_sms2ip" do
    expect(SMSLogsMock, :deliver, fn _message, _config, _provider ->
      {:ok, %Schema{provider: "mouth_sms2ip"}}
    end)

    assert {:ok, %Schema{provider: "mouth_sms2ip"}} =
             SMSLogs.save_and_send_sms("+380936020123", "TEST", "undefined", "mouth_sms2ip")
  end
end
