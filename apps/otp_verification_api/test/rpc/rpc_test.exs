defmodule OtpVerification.RpcTest do
  @moduledoc false

  use Core.DataCase, async: true
  alias Core.Redix
  alias Mouth.Messenger
  alias OtpVerification.Rpc
  import Mox

  setup :verify_on_exit!

  setup do
    Redix.command(["FLUSHALL"])
    :ok
  end

  describe "verification_phone/1" do
    test "success get verification phone" do
      verified_phone = insert(:verified_phone)
      phone_number = verified_phone.phone_number
      assert {:ok, %{phone_number: ^phone_number}} = Rpc.verification_phone(verified_phone.phone_number)
    end

    test "phone number not found" do
      refute Rpc.verification_phone("invalid")
    end
  end

  describe "initialize/1" do
    test "success initialize" do
      expect(SMSLogsMock, :deliver, fn message, config, _provider ->
        Messenger.deliver(message, config)
      end)

      assert {:ok,
              %{
                active: true,
                code_expired_at: _,
                id: _,
                status: "new"
              }} = Rpc.initialize("+380960000000")
    end

    test "too many requests" do
      System.put_env("INIT_VERIFICATION_LIMIT", "1")

      expect(SMSLogsMock, :deliver, fn message, config, _provider ->
        Messenger.deliver(message, config)
      end)

      on_exit(fn ->
        System.delete_env("INIT_VERIFICATION_LIMIT")
      end)

      Rpc.initialize("+380960000000")
      assert {:error, :too_many_requests} = Rpc.initialize("+380960000000")
    end
  end

  describe "complete/2" do
    test "invalid phone number" do
      refute Rpc.complete("+380960000000", "invalid")
    end

    test "invalid code" do
      verification = insert(:verification)
      assert {:error, {:forbidden, "Invalid verification code"}} == Rpc.complete(verification.phone_number, "invalid")
    end

    test "code is expired" do
      verification = insert(:verification, code_expired_at: DateTime.utc_now())
      assert {:error, {:forbidden, "Verification code expired"}} == Rpc.complete(verification.phone_number, verification.code)
    end

    test "verification is not active" do
      verification = insert(:verification, active: false)
      assert {:error, {:forbidden, "Maximum attempts exceed"}} == Rpc.complete(verification.phone_number, verification.code)
    end

    test "success" do
      verification = insert(:verification)

      assert {:ok,
              %{
                active: false,
                code_expired_at: _,
                id: _,
                status: "verified"
              }} = Rpc.complete(verification.phone_number, verification.code)
    end
  end

  describe "send_sms/3" do
    test "success" do
      expect(SMSLogsMock, :deliver, fn message, config, _provider ->
        Messenger.deliver(message, config)
      end)

      assert {:ok,
              %{
                body: "foo",
                id: _,
                phone_number: "+380960000000",
                type: "undefined"
              }} = Rpc.send_sms("+380960000000", "foo", "undefined")
    end
  end
end
