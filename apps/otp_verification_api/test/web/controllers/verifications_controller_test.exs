defmodule OtpVerification.Web.VerificationsControllerTest do
  use OtpVerification.Web.ConnCase
  import Mox

  alias Core.Redix
  alias Core.Verification.Verification
  alias Core.Verification.Verifications
  alias Core.Verification.VerifiedPhone
  alias Mouth.Messenger
  alias OtpVerification.Web.Endpoint

  setup :verify_on_exit!

  @create_attrs %{
    check_digit: 42,
    code: 42,
    phone_number: "+380631112233",
    status: Verification.status(:new),
    code_expired_at: "2017-05-10T10:00:09.932834Z"
  }

  def fixture(:verification) do
    {:ok, verification} = Verifications.create_verification(@create_attrs)
    verification
  end

  def initialize_verification(phone_number \\ "+380631112233") do
    {:ok, verification} = Verifications.initialize_verification(%{"phone_number" => phone_number})
    verification
  end

  setup do
    conn = put_req_header(build_conn(), "content-type", "application/json")
    Redix.command(["FLUSHALL"])
    {:ok, conn: conn}
  end

  describe "POST /verifications" do
    test "initialize verification", %{conn: conn} do
      expect(SMSLogsMock, :deliver, fn message, config ->
        Messenger.deliver(message, config)
      end)

      conn = post(conn, "/verifications", %{phone_number: "+380631112233"})
      status = Verification.status(:new)

      assert %{
               "id" => _,
               "code_expired_at" => _,
               "status" => ^status
             } = json_response(conn, 201)["data"]
    end

    test "initialize verification too many requests", %{conn: conn} do
      System.put_env("INIT_VERIFICATION_LIMIT", "5")

      expect(SMSLogsMock, :deliver, fn message, config ->
        Messenger.deliver(message, config)
      end)

      conn = post(conn, "/verifications", %{phone_number: "+380631112230"})
      status = Verification.status(:new)

      assert %{
               "id" => _,
               "code_expired_at" => _,
               "status" => ^status
             } = json_response(conn, 201)["data"]

      conn = post(conn, "/verifications", %{phone_number: "+380631112230"})
      assert json_response(conn, 429)
      System.put_env("INIT_VERIFICATION_LIMIT", "0")
    end

    test "creating new verification with same number deactivates older ones", %{conn: conn} do
      expect(SMSLogsMock, :deliver, 2, fn message, config ->
        Messenger.deliver(message, config)
      end)

      res = post(conn, "/verifications", %{phone_number: "+380631112233"})
      %{"id" => id, "active" => true} = json_response(res, 201)["data"]

      res2 = post(conn, "/verifications", %{phone_number: "+380631112233"})
      %{"id" => new_id, "active" => true} = json_response(res2, 201)["data"]

      refute id == new_id
      refute Verifications.get_verification(id).active
    end
  end

  describe "initialize verification too many requests bad params" do
    test "initialize verification bad params", %{conn: conn} do
      conn1 = post(conn, "/verifications", %{})
      assert json_response(conn1, 422)

      conn2 = post(conn, "/verifications", %{phone_number: "+38063111"})
      assert json_response(conn2, 422)

      conn3 = post(conn, "/verifications", %{phone_number: "380631112233"})
      assert json_response(conn3, 422)

      conn4 = post(conn, "/verifications", %{phone_number: 12_312_312_312})
      assert json_response(conn4, 422)
    end
  end

  describe "PATCH /verifications invalid phone number" do
    test "complete with invalid phone number", %{conn: conn} do
      conn = patch(conn, "/verifications/123456/actions/complete", %{code: 12345})
      assert json_response(conn, 404)
    end
  end

  describe "PATCH /verifications" do
    setup do
      expect(SMSLogsMock, :deliver, fn message, config ->
        Messenger.deliver(message, config)
      end)

      :ok
    end

    test "complete verification", %{conn: conn} do
      verification = initialize_verification()

      conn =
        patch(conn, "/verifications/#{verification.phone_number}/actions/complete", %{
          code: verification.code
        })

      status = Verification.status(:verified)
      assert %{"status" => ^status} = json_response(conn, 200)["data"]
      assert length(Repo.all(VerifiedPhone)) == 1
    end

    test "failed verification", %{conn: conn} do
      verification = initialize_verification()

      conn =
        patch(conn, "/verifications/#{verification.phone_number}/actions/complete", %{code: 12345})

      assert %{"error" => %{"message" => "Invalid verification code"}} = json_response(conn, 403)
    end

    test "code has been expired", %{conn: conn} do
      default_expiration = Confex.fetch_env!(:core, :code_expiration_period)
      System.put_env("CODE_EXPIRATION_PERIOD_MINUTES", "0")
      verification = initialize_verification()

      conn =
        patch(conn, "/verifications/#{verification.phone_number}/actions/complete", %{
          code: verification.code
        })

      assert %{"error" => %{"message" => "Verification code expired"}} = json_response(conn, 403)
      System.put_env("CODE_EXPIRATION_PERIOD_MINUTES", to_string(default_expiration))
    end

    test "can't verify  after 3 attempts", %{conn: conn} do
      verification = initialize_verification()

      patch(conn, "/verifications/#{verification.phone_number}/actions/complete", %{code: 12345})
      patch(conn, "/verifications/#{verification.phone_number}/actions/complete", %{code: 12345})
      patch(conn, "/verifications/#{verification.phone_number}/actions/complete", %{code: 12345})

      conn =
        patch(conn, "/verifications/#{verification.phone_number}/actions/complete", %{
          code: verification.code
        })

      assert %{"error" => %{"message" => "Maximum attempts exceed"}} = json_response(conn, 403)
    end

    test "json schema works", %{conn: conn} do
      initialize_verification()
      res = patch(conn, "/verifications/+380631112233/actions/complete", %{code: "1234"})
      assert json_response(res, 422)
      res = patch(conn, "/verifications/+380631112233/actions/complete", %{codse: 1234})
      assert json_response(res, 422)
    end
  end

  describe "PATCH /verifications for same number" do
    test "get proper verification response when creates many verifications for same number", %{
      conn: conn
    } do
      expect(SMSLogsMock, :deliver, 4, fn message, config ->
        Messenger.deliver(message, config)
      end)

      post(conn, "/verifications", %{phone_number: "+380631112233"})
      post(conn, "/verifications", %{phone_number: "+380631112233"})
      post(conn, "/verifications", %{phone_number: "+380631112233"})
      res = post(conn, "/verifications", %{phone_number: "+380631112233"})
      %{"id" => id} = json_response(res, 201)["data"]

      code = Verifications.get_verification(id).code

      res2 = patch(conn, "/verifications/+380631112233/actions/complete", %{code: code})
      assert json_response(res2, 200)
    end
  end

  describe "GET /verifications" do
    test "GET /verifications", %{conn: conn} do
      expect(SMSLogsMock, :deliver, 2, fn message, config ->
        Messenger.deliver(message, config)
      end)

      verification = initialize_verification()

      patch(conn, "/verifications/#{verification.phone_number}/actions/complete", %{
        code: verification.code
      })

      conn1 = get(conn, "/verifications/+380631112233")
      assert json_response(conn1, 200)

      conn2 = get(conn, "/verifications/13123123")
      assert json_response(conn2, 404)

      conn3 = get(conn, ~s(/verifications/\" or \"\"\=\"\"))
      assert json_response(conn3, 404)

      new_verification = initialize_verification("+380931232323")

      patch(conn, "/verifications/#{new_verification.phone_number}/actions/complete", %{
        code: new_verification.code
      })

      conn1 = get(conn, "/verifications/+380931232323")
      assert json_response(conn1, 200)

      patch(conn, "/verifications/#{verification.phone_number}/actions/complete", %{
        code: verification.code
      })

      conn1 = get(conn, "/verifications/+380631112233")
      assert json_response(conn1, 200)
    end
  end

  describe "testing errors callback" do
    setup do
      expect(SMSLogsMock, :deliver, fn message, config ->
        Messenger.deliver(message, config)
      end)

      :ok
    end

    test "service unavailable error test", %{conn: conn} do
      current_code_length = Application.get_env(:core, :code_length)
      current_code_text = Application.get_env(:core, :code_text)

      on_exit(fn ->
        Application.put_env(:core, :code_length, current_code_length)
        Application.put_env(:core, :code_text, current_code_text)
      end)

      Application.put_env(:core, :code_length, 0)
      Application.put_env(:core, :code_text, "exception")

      conn =
        post(conn, verifications_path(Endpoint, :initialize), %{"phone_number" => "+380931232323"})

      assert json_response(conn, 422)
    end
  end
end
