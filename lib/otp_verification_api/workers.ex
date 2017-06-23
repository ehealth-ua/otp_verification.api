defmodule OtpVerification.Worker do
  @moduledoc """
  OtpVerification background jobs module
  """
  alias OtpVerification.Verification.Verifications

  def start_link(worker_function, opts) do
    env = System.get_env("MIX_ENV")
    if env in ["test", "ci"] do
      :ignore
    else
      Task.start(__MODULE__, worker_function, [opts])
    end
  end

  def cancel_verifications(args) do
    miliseconds_to_sleep = (Keyword.get(args, :minutes) + 1) * 60 * 1000
    Process.sleep(miliseconds_to_sleep)
    Verifications.cancel_expired_verifications()
    cancel_verifications(args)
  end
end
