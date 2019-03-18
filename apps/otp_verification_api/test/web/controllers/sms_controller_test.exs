defmodule OtpVerification.Web.SMSControllerTest do
  use OtpVerification.Web.ConnCase
  import Mox
  alias Core.Repo
  alias Core.SMSLog.Schema, as: SMSLog

  describe "POST /sms/send" do
    setup do
      expect(SMSLogsMock, :deliver, fn message, config, _provider ->
        Mouth.Messenger.deliver(message, config)
      end)

      :ok
    end

    test "initialize verification", %{conn: conn} do
      conn = post(conn, "/sms/send", %{phone_number: "+380936020123", body: "TEST"})

      assert %{
               "id" => id,
               "phone_number" => _,
               "body" => "TEST"
             } = json_response(conn, 200)["data"]

      assert id == SMSLog |> Repo.all() |> Enum.at(0) |> Map.get(:id)
    end
  end
end
