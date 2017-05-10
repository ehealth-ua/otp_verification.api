defmodule OtpVerification.Web.VerificationsControllerTest do
  use OtpVerification.Web.ConnCase

  alias OtpVerification.Verification.Verifications

  @create_attrs %{check_digit: 42, code: 42, phone_number: "some phone_number", status: "some status", type: "some type"}
  @invalid_attrs %{check_digit: nil, code: nil, phone_number: nil, status: nil, type: nil}

  def fixture(:verifications) do
    {:ok, verifications} = Verification.create_verifications(@create_attrs)
    verifications
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, verifications_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "creates verifications and renders verifications when data is valid", %{conn: conn} do
    conn = post conn, verifications_path(conn, :create), verifications: @create_attrs
    assert %{"id" => id} = json_response(conn, 201)["data"]

    conn = get conn, verifications_path(conn, :show, id)
    assert json_response(conn, 200)["data"] == %{
      "id" => id,
      "check_digit" => 42,
      "code" => 42,
      "phone_number" => "some phone_number",
      "status" => "some status",
      "type" => "some type"}
  end

  test "does not create verifications and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, verifications_path(conn, :create), verifications: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end
end
