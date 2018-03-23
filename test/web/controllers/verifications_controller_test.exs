defmodule OtpVerification.Web.VerificationsControllerTest do
  use OtpVerification.Web.ConnCase

  alias OtpVerification.Verification.Verification
  alias OtpVerification.Verification.Verifications
  alias OtpVerification.Verification.VerifiedPhone
  alias OtpVerification.Web.Endpoint

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
    {:ok, conn: conn}
  end

  describe "POST /verifications" do
    test "initialize verification", %{conn: conn} do
      conn = post(conn, "/verifications", %{phone_number: "+380631112233"})
      status = Verification.status(:new)

      assert %{
               "id" => _,
               "code_expired_at" => _,
               "status" => ^status
             } = json_response(conn, 201)["data"]
    end

    test "creating new verification with same number deactivates older ones", %{conn: conn} do
      res = post(conn, "/verifications", %{phone_number: "+380631112233"})
      %{"id" => id, "active" => true} = json_response(res, 201)["data"]

      res2 = post(conn, "/verifications", %{phone_number: "+380631112233"})
      %{"id" => new_id, "active" => true} = json_response(res2, 201)["data"]

      refute id == new_id
      refute Verifications.get_verification(id).active
    end

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

  describe "PATCH /verifications" do
    test "complete with invalid phone number", %{conn: conn} do
      conn = patch(conn, "/verifications/123456/actions/complete", %{code: 12345})
      assert json_response(conn, 404)
    end

    test "complete verification", %{conn: conn} do
      verification = initialize_verification()
      conn = patch(conn, "/verifications/#{verification.phone_number}/actions/complete", %{code: verification.code})
      status = Verification.status(:verified)
      assert %{"status" => ^status} = json_response(conn, 200)["data"]
      assert length(Repo.all(VerifiedPhone)) == 1
    end

    test "failed verification", %{conn: conn} do
      verification = initialize_verification()

      conn = patch(conn, "/verifications/#{verification.phone_number}/actions/complete", %{code: 12345})
      assert %{"error" => %{"message" => "Invalid verification code"}} = json_response(conn, 403)
    end

    test "code has been expired", %{conn: conn} do
      default_expiration = Confex.get(:otp_verification_api, :code_expiration_period)
      System.put_env("CODE_EXPIRATION_PERIOD_MINUTES", "0")
      verification = initialize_verification()
      conn = patch(conn, "/verifications/#{verification.phone_number}/actions/complete", %{code: verification.code})
      assert %{"error" => %{"message" => "Verification code expired"}} = json_response(conn, 403)
      System.put_env("CODE_EXPIRATION_PERIOD_MINUTES", to_string(default_expiration))
    end

    test "can't verify  after 3 attempts", %{conn: conn} do
      verification = initialize_verification()

      patch(conn, "/verifications/#{verification.phone_number}/actions/complete", %{code: 12345})
      patch(conn, "/verifications/#{verification.phone_number}/actions/complete", %{code: 12345})
      patch(conn, "/verifications/#{verification.phone_number}/actions/complete", %{code: 12345})
      conn = patch(conn, "/verifications/#{verification.phone_number}/actions/complete", %{code: verification.code})
      assert %{"error" => %{"message" => "Maximum attempts exceed"}} = json_response(conn, 403)
    end

    test "get proper verification response when creates many verifications for same number", %{conn: conn} do
      post(conn, "/verifications", %{phone_number: "+380631112233"})
      post(conn, "/verifications", %{phone_number: "+380631112233"})
      post(conn, "/verifications", %{phone_number: "+380631112233"})
      res = post(conn, "/verifications", %{phone_number: "+380631112233"})
      %{"id" => id} = json_response(res, 201)["data"]

      code = Verifications.get_verification(id).code

      res2 = patch(conn, "/verifications/+380631112233/actions/complete", %{code: code})
      assert json_response(res2, 200)
    end

    test "json schema works", %{conn: conn} do
      initialize_verification()
      res = patch(conn, "/verifications/+380631112233/actions/complete", %{code: "1234"})
      assert json_response(res, 422)
      res = patch(conn, "/verifications/+380631112233/actions/complete", %{codse: 1234})
      assert json_response(res, 422)
    end
  end

  describe "GET /verifications" do
    test "GET /verifications", %{conn: conn} do
      verification = initialize_verification()
      patch(conn, "/verifications/#{verification.phone_number}/actions/complete", %{code: verification.code})

      conn1 = get(conn, "/verifications/+380631112233")
      assert json_response(conn1, 200)

      conn2 = get(conn, "/verifications/13123123")
      assert json_response(conn2, 404)

      conn3 = get(conn, ~s(/verifications/\" or \"\"\=\"\"))
      assert json_response(conn3, 404)

      new_verification = initialize_verification("+380931232323")
      patch(conn, "/verifications/#{new_verification.phone_number}/actions/complete", %{code: new_verification.code})

      conn1 = get(conn, "/verifications/+380931232323")
      assert json_response(conn1, 200)

      patch(conn, "/verifications/#{verification.phone_number}/actions/complete", %{code: verification.code})

      conn1 = get(conn, "/verifications/+380631112233")
      assert json_response(conn1, 200)
    end
  end

  describe "testing errors callback" do
    test "service unavailable error test", %{conn: conn} do
      current_code_length = Application.get_env(:otp_verification_api, :code_length)
      current_code_text = Application.get_env(:otp_verification_api, :code_text)

      on_exit(fn ->
        Application.put_env(:otp_verification_api, :code_length, current_code_length)
        Application.put_env(:otp_verification_api, :code_text, current_code_text)
      end)

      Application.put_env(:otp_verification_api, :code_length, 0)
      Application.put_env(:otp_verification_api, :code_text, "exception")
      conn = post(conn, verifications_path(Endpoint, :initialize), %{"phone_number" => "+380931232323"})
      assert json_response(conn, 503)
    end
  end
end
