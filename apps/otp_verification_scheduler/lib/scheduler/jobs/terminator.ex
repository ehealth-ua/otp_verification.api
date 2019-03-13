defmodule Scheduler.Jobs.Terminator do
  @moduledoc false

  use Confex, otp_app: :otp_verification_scheduler
  import Ecto.Query
  require Logger
  alias Core.Repo
  alias Core.Verification.Verification

  def run do
    validations_expired_timeout = config()[:validations_expired_timeout]
    {deleted_records_count, _} = delete_expired_verifications(validations_expired_timeout)
    Logger.info("Just deleted #{deleted_records_count} expired verifications")
    {:ok, deleted_records_count}
  end

  defp delete_expired_verifications(expired_timeout) when is_number(expired_timeout) and expired_timeout > 0 do
    expired_moment =
      DateTime.utc_now()
      |> DateTime.add(-expired_timeout * 24 * 60 * 60, :second)
      |> DateTime.to_naive()

    Verification
    |> where([v], v.inserted_at < ^expired_moment)
    |> Repo.delete_all(timeout: :infinity)
  end

  defp delete_expired_verifications(_), do: {0, nil}
end
