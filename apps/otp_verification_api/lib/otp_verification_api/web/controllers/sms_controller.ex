defmodule OtpVerification.Web.SMSController do
  @moduledoc false

  use OtpVerification.Web, :controller
  alias Core.SMSLog.Schema, as: SMSLog
  alias Core.SMSLogs

  action_fallback(OtpVerification.Web.FallbackController)

  def send(conn, params) do
    with {:ok, %SMSLog{} = sms} <-
           SMSLogs.save_and_send_sms(params["phone_number"], params["body"], params["type"], params["provider"]) do
      render(conn, "show.json", sms: sms)
    end
  end
end
