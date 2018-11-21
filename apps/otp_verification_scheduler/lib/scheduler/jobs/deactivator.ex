defmodule Scheduler.Jobs.Deactivator do
  @moduledoc false

  require Logger
  alias Core.Verification.Verifications

  def run do
    {canceled_records_count, _} = Verifications.cancel_expired_verifications()
    Logger.info(fn -> "Just cleaned #{canceled_records_count} expired verifications" end)
    {:ok, canceled_records_count}
  end
end
