defmodule Core.Messenger.Secondary do
  @moduledoc false
  use Mouth.Messenger, otp_app: :core

  def init do
    Confex.fetch_env(:core, :mouth_sms2ip)
  end
end
