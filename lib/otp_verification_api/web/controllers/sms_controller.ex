defmodule OtpVerification.Web.SMSController do
  @moduledoc false
  use OtpVerification.Web, :controller
  alias OtpVerification.SMSLogs
  alias OtpVerification.SMSLog.Schema, as: SMSLog

  action_fallback OtpVerification.Web.FallbackController

  def send(conn, params) do
    with {:ok, %SMSLog{} = sms} <- SMSLogs.save_and_send_sms(params) do
      render(conn, "show.json", sms: sms)
    end
  end
end
