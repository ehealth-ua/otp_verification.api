defmodule Terminator.Worker do
  @moduledoc false

  use GenServer
  use Confex, otp_app: :terminator
  import Ecto.{Query, Changeset}, warn: false
  require Logger
  alias Core.Repo
  alias Core.Verification.Verification

  @behaviour Terminator.Behaviours.WorkerBehaviour
  @worker Application.get_env(:terminator, :worker)

  def start_link do
    GenServer.start_link(__MODULE__, nil)
  end

  @impl true
  def init(state) do
    Process.send_after(self(), :run, 10)
    {:ok, state}
  end

  @impl true
  def handle_info(:run, state) do
    validations_expired_timeout = Confex.fetch_env!(:terminator, :validations_expired_timeout)
    {deleted_records_count, _} = delete_expired_verifications(validations_expired_timeout)

    if deleted_records_count > 0 do
      Logger.info(fn -> "Just deleted #{deleted_records_count} expired verifications" end)
    end

    @worker.stop_application()
    {:stop, :normal, state}
  end

  @impl true
  def stop_application do
    System.halt(0)
  end

  defp delete_expired_verifications(expired_timeout) when is_number(expired_timeout) and expired_timeout > 0 do
    expired_moment = Timex.shift(Timex.now(), days: -expired_timeout)

    Verification
    |> where([v], v.inserted_at < ^expired_moment)
    |> Repo.delete_all()
  end

  defp delete_expired_verifications(_), do: {0, nil}
end
