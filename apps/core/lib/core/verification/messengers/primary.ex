defmodule Core.Messenger.Primary do
  @moduledoc false
  use Mouth.Messenger, otp_app: :core

  def init do
    Confex.fetch_env(:core, :mouth_twilio)
  end
end
