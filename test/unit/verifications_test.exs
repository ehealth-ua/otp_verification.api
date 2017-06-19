defmodule OtpVerification.VerificationsTest do
  use OtpVerification.DataCase

  alias OtpVerification.Verification.Verification
  alias OtpVerification.Verification.Verifications
  alias OtpVerification.Verification.VerifiedPhone

  @create_attrs %{check_digit: 42, code: 42, phone_number: "+380631112233", status: "created",
    type: "otp", code_expired_at: "2017-05-10T10:00:09.932834Z"}
  @update_attrs %{check_digit: 43, code: 43, phone_number: "+380631112244", status: "completed",
    type: "otp", code_expired_at: "2017-05-11T10:00:09.932834Z"}
  @invalid_attrs %{check_digit: nil, code: nil, phone_number: nil, status: nil, type: nil}

  describe "Verifications CRUD" do
    setup do
      {:ok, verification} = Verifications.create_verification(@create_attrs)
      {:ok, verification: verification}
    end

    test "list_verifications/1 returns all verifications", %{verification: verification} do
      assert Verifications.list_verifications() == [verification]
    end

    test "get_verifications! returns the verifications with given id", %{verification: verification} do
      assert Verifications.get_verification!(verification.id) == verification
    end

    test "get_verifications returns the verifications with given id", %{verification: verification} do
      assert Verifications.get_verification(verification.id) == verification
    end

    test "get_verifications_by return the verifications struct", %{verification: verification} do
      Verifications.create_verification(@update_attrs)
      new_verification = Verifications.get_verification_by(phone_number: verification.phone_number)
      assert new_verification == verification
    end

    test "create_verifications/1 with valid data creates a verifications" do
      assert {:ok, %Verification{} = verification} = Verifications.create_verification(@create_attrs)
      assert verification.check_digit == 42
      assert verification.code == 42
      assert verification.phone_number == "+380631112233"
      assert verification.status == "created"
      assert verification.type == "otp"
    end

    test "create_verifications fails to create without attributes" do
      {:error, %Ecto.Changeset{}} = Verifications.create_verification(%{})
    end

    test "create_verifications/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Verifications.create_verification(@invalid_attrs)
    end

    test "update_verifications/2 with valid data updates the verifications", %{verification: verification} do
      assert {:ok, verification} = Verifications.update_verification(verification, @update_attrs)
      assert %Verification{} = verification
      assert verification.check_digit == 43
      assert verification.code == 43
      assert verification.phone_number == "+380631112244"
      assert verification.status == "completed"
      assert verification.type == "otp"
    end

    test "update_verifications/2 with invalid data returns error changeset", %{verification: verification} do
      assert {:error, %Ecto.Changeset{}} = Verifications.update_verification(verification, @invalid_attrs)
      assert verification == Verifications.get_verification!(verification.id)
    end

    test "change_verifications/1 returns a verifications changeset", %{verification: verification} do
      assert %Ecto.Changeset{} = Verifications.change_verification(verification)
    end

    test "initialize verification" do
      assert {:ok, %Verification{}} =
        Verifications.initialize_verification(%{"type" => "otp", "phone_number" => "+380637654433"})
    end

    test "initializing verification with same phone number deactivates all records with same phone number",
      %{verification: verification} do

      assert verification.active
      {:ok, new_verification} = Verifications.initialize_verification(%{"phone_number"=> "+380631112233",
                                                                        "type" => "otp"})
      assert new_verification.active
      verification = Verifications.get_verification(verification.id)
      refute verification.active
    end

    test "complete verification" do
      {:ok, %Verification{} = verification} =
        Verifications.initialize_verification(%{"type" => "otp", "phone_number" => "+380637654433"})

      {:ok, %Verification{}, :verified} = Verifications.verify(verification, verification.code)

      {:ok, %Verification{} = verification} =
        Verifications.initialize_verification(%{"type" => "otp", "phone_number" => "+380637654432"})
      {:ok, %Verification{}, :not_verified} = Verifications.verify(verification, 123)
    end

    test "search verification", %{verification: verification} do
      ch_set = Verifications.search_changeset(%{phone_number: verification.phone_number, status: verification.status})
      assert verification in Verifications.search(ch_set)
    end

    test "delete_verification", %{verification: verification} do
      {:ok, new_verification} = Verifications.create_verification(@create_attrs)
      list = Verifications.list_verifications()
      assert verification in list
      assert new_verification in list

      {:ok, _} = Verifications.delete_verification(verification)
      assert new_verification in Verifications.list_verifications()
    end
  end

  describe "VerifiedPhone CRUD" do
    setup do
      {:ok, verification} = Verifications.create_verification(@create_attrs)
      {:ok, verification: verification}
    end

    test "add_verified_phone creates db record", %{verification: verification} do
      {:ok, %VerifiedPhone{} = phone} = Verifications.add_verified_phone(verification)
      %VerifiedPhone{id: id, phone_number: phone_number} = Repo.get(VerifiedPhone, phone.id)
      assert id == phone.id
      assert phone_number == phone.phone_number
    end
  end

  describe "Verifications context helpers" do
  end

end
