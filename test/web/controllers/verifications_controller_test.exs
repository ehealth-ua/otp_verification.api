defmodule OtpVerification.Web.VerificationsControllerTest do
  use OtpVerification.Web.ConnCase

  alias OtpVerification.Verification

  @create_attrs %{check_digit: 42, code: 42, phone_number: "+380631112233", status: "created",
    type: "otp", code_expired_at: "2017-05-10T10:00:09.932834Z"}

  def fixture(:verifications) do
    {:ok, verifications} = Verification.create_verifications(@create_attrs)
    verifications
  end

  def initialize_verification do
    {:ok, verification} = Verification.initialize_verifications(%{"phone_number" => "+380631112233", "type" => "otp"})
    verification
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "initialize verification", %{conn: conn} do
    conn = post conn, "/verifications", %{type: "otp", phone_number: "+380631112233"}
    assert %{
      "id" => _,
      "check_digit" => _,
      "code" => _,
      "code_expired_at" => _,
      "phone_number" => "+380631112233",
      "status" => "created",
      "type" => "otp"} = json_response(conn, 201)["data"]
  end

  test "initialize verification bad params", %{conn: conn} do
    conn = post conn, "/verifications", %{type: "bad_type", phone_number: "+380631112233"}
    json_response(conn, 422)

    conn = Plug.Conn.put_req_header(Phoenix.ConnTest.build_conn(), "content-type", "application/json")
    conn = post conn, "/verifications", %{type: "otp", phone_number: "+38063111"}
    json_response(conn, 422)
  end

  test "complete verification", %{conn: conn} do
    verification = initialize_verification()

    conn = patch conn, "/verifications/#{verification.id}/actions/complete", %{code: verification.code}
    assert %{"status" => "completed"} = json_response(conn, 200)["data"]
  end

  test "failed verification", %{conn: conn} do
    verification = initialize_verification()

    conn = patch conn, "/verifications/#{verification.id}/actions/complete", %{code: 12345}
    assert json_response(conn, 422)
  end

  test "search", %{conn: conn} do
    fixture(:verifications)
    fixture(:verifications)

    conn = get conn, "/verifications"
    assert json_response(conn, 200)["data"]

    conn = get conn, "/verifications?phone_number=%2B380631112233"
    assert json_response(conn, 200)["data"]


    conn = get conn, "/verifications?phone_number=%2B380631112233&statuses=created,completed"
    assert json_response(conn, 200)["data"]
  end

  test "search invalid statuses", %{conn: conn} do
    conn = get conn, "/verifications?phone_number=%2B380631112233&statuses=create1d,completed"
    assert json_response(conn, 422)
  end
end
