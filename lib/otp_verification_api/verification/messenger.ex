defmodule OtpVerification.Messenger do
  @moduledoc false
  use Mouth.Messenger, otp_app: :otp_verification_api

  def init do
    Confex.fetch_env(:otp_verification_api, :mouth)
  end
end
