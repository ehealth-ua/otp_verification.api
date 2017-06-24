defmodule OtpVerification.Messanger do
  @moduledoc false
  use Mouth.Messanger, otp_app: :otp_verification_api

  def init do
    config = Confex.get_map(:otp_verification_api, :mouth)
    {:ok, config}
  end
end
