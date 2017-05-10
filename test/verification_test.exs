defmodule OtpVerification.VerificationTest do
  use OtpVerification.DataCase

  alias OtpVerification.Verification
  alias OtpVerification.Verification.Verifications

  @create_attrs %{check_digit: 42, code: 42, phone_number: "some phone_number", status: "some status", type: "some type"}
  @update_attrs %{check_digit: 43, code: 43, phone_number: "some updated phone_number", status: "some updated status", type: "some updated type"}
  @invalid_attrs %{check_digit: nil, code: nil, phone_number: nil, status: nil, type: nil}

  def fixture(:verifications, attrs \\ @create_attrs) do
    {:ok, verifications} = Verification.create_verifications(attrs)
    verifications
  end

  test "list_verifications/1 returns all verifications" do
    verifications = fixture(:verifications)
    assert Verification.list_verifications() == [verifications]
  end

  test "get_verifications! returns the verifications with given id" do
    verifications = fixture(:verifications)
    assert Verification.get_verifications!(verifications.id) == verifications
  end

  test "create_verifications/1 with valid data creates a verifications" do
    assert {:ok, %Verifications{} = verifications} = Verification.create_verifications(@create_attrs)
    assert verifications.check_digit == 42
    assert verifications.code == 42
    assert verifications.phone_number == "some phone_number"
    assert verifications.status == "some status"
    assert verifications.type == "some type"
  end

  test "create_verifications/1 with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = Verification.create_verifications(@invalid_attrs)
  end

  test "update_verifications/2 with valid data updates the verifications" do
    verifications = fixture(:verifications)
    assert {:ok, verifications} = Verification.update_verifications(verifications, @update_attrs)
    assert %Verifications{} = verifications
    assert verifications.check_digit == 43
    assert verifications.code == 43
    assert verifications.phone_number == "some updated phone_number"
    assert verifications.status == "some updated status"
    assert verifications.type == "some updated type"
  end

  test "update_verifications/2 with invalid data returns error changeset" do
    verifications = fixture(:verifications)
    assert {:error, %Ecto.Changeset{}} = Verification.update_verifications(verifications, @invalid_attrs)
    assert verifications == Verification.get_verifications!(verifications.id)
  end

  test "change_verifications/1 returns a verifications changeset" do
    verifications = fixture(:verifications)
    assert %Ecto.Changeset{} = Verification.change_verifications(verifications)
  end
end
