defmodule Scheduler.Jobs.TerminatorTest do
  @moduledoc false

  use Core.DataCase
  import Core.Factory
  alias Core.Verification.Verifications
  alias Scheduler.Jobs.Terminator

  test "worker test when validations_expired_timeout is defined" do
    current_value = System.get_env("VALIDATIONS_EXPIRATION_PERIOD_DAYS")
    System.put_env("VALIDATIONS_EXPIRATION_PERIOD_DAYS", "2")

    verification_in =
      insert(:verification, %{
        inserted_at: DateTime.to_naive(DateTime.add(DateTime.utc_now(), -1 * 24 * 60 * 60, :second))
      })

    verification_out =
      insert(:verification, %{
        inserted_at: DateTime.to_naive(DateTime.add(DateTime.utc_now(), -3 * 24 * 60 * 60, :second))
      })

    assert {:ok, 1} == Terminator.run()

    verification_ids =
      Enum.map(Verifications.list_verifications(), fn verification ->
        verification.id
      end)

    assert verification_in.id in verification_ids
    refute verification_out.id in verification_ids

    on_exit(fn ->
      System.put_env("VALIDATIONS_EXPIRATION_PERIOD_DAYS", to_string(current_value))
    end)
  end

  test "worker test when validations_expired_timeout is not defined" do
    current_value = System.get_env("VALIDATIONS_EXPIRATION_PERIOD_DAYS")
    System.put_env("VALIDATIONS_EXPIRATION_PERIOD_DAYS", "")

    insert(:verification, %{inserted_at: DateTime.add(DateTime.utc_now(), -1 * 24 * 60 * 60, :second)})
    insert(:verification, %{inserted_at: DateTime.add(DateTime.utc_now(), -3 * 24 * 60 * 60, :second)})
    assert {:ok, 0} == Terminator.run()

    assert length(Verifications.list_verifications()) == 2

    on_exit(fn ->
      System.put_env("VALIDATIONS_EXPIRATION_PERIOD_DAYS", to_string(current_value))
    end)
  end
end
