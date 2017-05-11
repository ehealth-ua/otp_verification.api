defmodule OtpVerification.VerificationTest do
  use OtpVerification.DataCase

  alias OtpVerification.Verification
  alias OtpVerification.Verification.Verifications

  @create_attrs %{check_digit: 42, code: 42, phone_number: "+380631112233", status: "created",
    type: "otp", code_expired_at: "2017-05-10T10:00:09.932834Z"}
  @update_attrs %{check_digit: 43, code: 43, phone_number: "+380631112244", status: "completed",
    type: "otp", code_expired_at: "2017-05-11T10:00:09.932834Z"}
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
    assert verifications.phone_number == "+380631112233"
    assert verifications.status == "created"
    assert verifications.type == "otp"
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
    assert verifications.phone_number == "+380631112244"
    assert verifications.status == "completed"
    assert verifications.type == "otp"
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

  test "initialize verification" do
    assert {:ok, %Verifications{}} =
      Verification.initialize_verifications(%{"type" => "otp", "phone_number" => "+380637654433"})
  end

  test "complete verification" do
    {:ok, %Verifications{} = verification} =
      Verification.initialize_verifications(%{"type" => "otp", "phone_number" => "+380637654433"})

    {:ok, %Verifications{}, :verified} = Verification.verify(verification, verification.code)

    {:ok, %Verifications{} = verification} =
      Verification.initialize_verifications(%{"type" => "otp", "phone_number" => "+380637654432"})
    {:ok, %Verifications{}, :not_verified} = Verification.verify(verification, 123)
  end
end
