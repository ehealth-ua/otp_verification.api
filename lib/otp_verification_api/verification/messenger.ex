defmodule OtpVerification.Messenger do
  @moduledoc false
  use Mouth.Messenger, otp_app: :otp_verification_api

  def init do
    config = Confex.get_map(:otp_verification_api, :mouth)
    {:ok, config}
  end
end
