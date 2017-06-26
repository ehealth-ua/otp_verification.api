defmodule OtpVerification.Verification.MessageManager do
  @moduledoc false
  require Logger
  use GenServer
  alias OtpVerification.Verification.Verifications

  def check_status(verification) do
    GenServer.start_link(__MODULE__, %{verification: verification})
  end

  def init(state) do
    milliseconds_to_sleep = 16 * 60 * 1000
    Process.send_after(self(), :check_sms_status, milliseconds_to_sleep)
    {:ok, state}
  end

  def handle_info(:check_sms_status, state) do
    Task.start(fn ->
      Verifications.check_gateway_status(state.verification)
    end)
    {:stop, :normal, %{}}
  end
end
