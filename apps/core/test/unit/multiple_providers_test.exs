defmodule Core.MultipleProvidersTest do
  @moduledoc false
  use Core.DataCase, async: false
  import Mox
  alias Core.SMSLogs
  alias Core.SMSLog.Schema
  alias Mouth.Messenger

  test "save_and_send_sms without defined probider" do
    expect(SMSLogsMock, :deliver, fn message, config ->
      Messenger.deliver(message, config)
    end)

    assert {:ok, %Schema{provider: "mouth_twilio"}} =
             SMSLogs.save_and_send_sms(%{"phone_number" => "+380936020123", "body" => "TEST"})
  end

  test "save_and_send_sms with defined probider mouth_twilio" do
    expect(SMSLogsMock, :deliver, fn message, config ->
      Messenger.deliver(message, config)
    end)

    assert {:ok, %Schema{provider: "mouth_twilio"}} =
             SMSLogs.save_and_send_sms(%{
               "phone_number" => "+380936020123",
               "body" => "TEST",
               "provider" => "mouth_twilio"
             })
  end

  test "save_and_send_sms with defined probider mouth_sms2ip" do
    expect(SMSLogsMock, :deliver, fn _message, _config ->
      {:ok, %Schema{provider: "mouth_sms2ip"}}
    end)

    assert {:ok, %Schema{provider: "mouth_sms2ip"}} =
             SMSLogs.save_and_send_sms(%{
               "phone_number" => "+380936020123",
               "body" => "TEST",
               "provider" => "mouth_sms2ip"
             })
  end
end
