defmodule OtpVerification.Scheduler do
  @moduledoc false
  use Quantum.Scheduler, otp_app: :otp_verification_api
end
