defmodule Core.VerificationsTest do
  @moduledoc false

  use Core.DataCase
  import Core.Factory
  import Mox
  alias Core.Redix
  alias Core.Verification.Verification
  alias Core.Verification.Verifications
  alias Core.Verification.VerifiedPhone
  alias Mouth.Messenger

  setup do
    Redix.command(["FLUSHALL"])
    :ok
  end

  setup :verify_on_exit!

  @create_attrs %{
    check_digit: 42,
    code: 42,
    phone_number: "+380631112233",
    status: Verification.status(:new),
    code_expired_at: "2017-05-10T10:00:09.932834Z"
  }
  @update_attrs %{
    check_digit: 43,
    code: 43,
    phone_number: "+380631112244",
    status: Verification.status(:completed),
    code_expired_at: "2017-05-11T10:00:09.932834Z"
  }
  @invalid_attrs %{
    check_digit: nil,
    code: nil,
    phone_number: nil,
    status: nil
  }

  describe "Verifications CRUD no deliver" do
    test "get_verifications returns the verifications with given id" do
      verification = insert(:verification, @create_attrs)
      assert Verifications.get_verification(verification.id) == verification
    end

    test "update_verifications/2 with valid data updates the verifications" do
      verification = insert(:verification, @create_attrs)
      assert {:ok, verification} = Verifications.update_verification(verification, @update_attrs)
      assert %Verification{} = verification
      assert verification.check_digit == 43
      assert verification.code == 43
      assert verification.phone_number == "+380631112244"
      assert verification.status == Verification.status(:completed)
    end

    test "list_verifications/1 returns all verifications" do
      verification = insert(:verification, @create_attrs)
      assert Verifications.list_verifications() == [verification]
    end

    test "get_verifications! returns the verifications with given id" do
      verification = insert(:verification, @create_attrs)
      assert Verifications.get_verification!(verification.id) == verification
    end

    test "create_verifications/1 with valid data creates a verifications" do
      assert {:ok, %Verification{} = verification} = Verifications.create_verification(@create_attrs)
      assert verification.check_digit == 42
      assert verification.code == 42
      assert verification.phone_number == "+380631112233"
      assert verification.status == Verification.status(:new)
    end

    test "update_verifications/2 with invalid data returns error changeset" do
      verification = insert(:verification, @create_attrs)
      assert {:error, %Ecto.Changeset{}} = Verifications.update_verification(verification, @invalid_attrs)
      assert verification == Verifications.get_verification!(verification.id)
    end

    test "create_verifications/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Verifications.create_verification(@invalid_attrs)
    end

    test "cancel expired verifications" do
      verification = insert(:verification, @create_attrs)
      Verifications.cancel_expired_verifications()
      verification = Repo.get(Verification, verification.id)
      refute verification.active
      assert verification.status == Verification.status(:expired)
    end

    test "create_verifications fails to create without attributes" do
      {:error, %Ecto.Changeset{}} = Verifications.create_verification(%{})
    end

    test "delete_verification" do
      verification = insert(:verification, @create_attrs)
      params = %{@create_attrs | phone_number: "+380631112234"}
      new_verification = insert(:verification, params)
      list = Verifications.list_verifications()
      assert verification in list
      assert new_verification in list

      {:ok, _} = Verifications.delete_verification(verification)
      refute verification in Verifications.list_verifications()
      assert new_verification in Verifications.list_verifications()
    end

    test "get_verifications_by return the verifications struct" do
      verification = insert(:verification, @create_attrs)
      new_verification = Verifications.get_verification_by(phone_number: verification.phone_number)
      assert new_verification == verification
    end
  end

  describe "Verifications CRUD" do
    setup do
      expect(SMSLogsMock, :deliver, fn message, config, _provider ->
        Messenger.deliver(message, config)
      end)

      :ok
    end

    test "initialize verification" do
      assert {:ok, %Verification{} = verification} =
               Verifications.initialize_verification(%{"phone_number" => "+380637654433"})

      assert verification.attempts_count == 0
    end

    test "too many requests" do
      stub(SMSLogsMock, :deliver, fn message, config, _provider ->
        Messenger.deliver(message, config)
      end)

      System.put_env("INIT_VERIFICATION_LIMIT", "5")
      assert {:ok, %Verification{}} = Verifications.initialize_verification(%{"phone_number" => "+380637654432"})
      assert {:error, :too_many_requests} = Verifications.initialize_verification(%{"phone_number" => "+380637654432"})
      assert {:ok, %Verification{}} = Verifications.initialize_verification(%{"phone_number" => "+380637654434"})
      System.put_env("INIT_VERIFICATION_LIMIT", "0")
    end

    test "initializing verification with same phone number deactivates all records with same phone number" do
      verification = insert(:verification, @create_attrs)
      assert verification.active
      {:ok, new_verification} = Verifications.initialize_verification(%{"phone_number" => "+380631112233"})
      assert new_verification.active
      verification = Verifications.get_verification(verification.id)
      refute verification.active
    end

    test "complete verification" do
      expect(SMSLogsMock, :deliver, fn message, config, _provider ->
        Messenger.deliver(message, config)
      end)

      {:ok, %Verification{} = verification} =
        Verifications.initialize_verification(%{"phone_number" => "+380637654433"})

      {:ok, verified_verification, :verified} = Verifications.verify(verification, verification.code)
      refute verified_verification.active

      {:ok, %Verification{} = verification} =
        Verifications.initialize_verification(%{"phone_number" => "+380637654432"})

      {:ok, %Verification{}, :not_verified} = Verifications.verify(verification, 123)
    end
  end

  describe "VerifiedPhone CRUD" do
    test "add_verified_phone creates db record" do
      verification = insert(:verification, @create_attrs)
      {:ok, %VerifiedPhone{} = phone} = Verifications.add_verified_phone(verification)
      %VerifiedPhone{id: id, phone_number: phone_number} = Repo.get(VerifiedPhone, phone.id)
      assert id == phone.id
      assert phone_number == phone.phone_number
    end
  end
end
