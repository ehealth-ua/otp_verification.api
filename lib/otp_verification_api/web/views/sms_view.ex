defmodule OtpVerification.Web.SMSView do
  @moduledoc false
  use OtpVerification.Web, :view
  alias OtpVerification.Web.SMSView

  def render("show.json", %{sms: sms}) do
    render_one(sms, SMSView, "sms.json",  as: :sms)
  end

  def render("sms.json", %{sms: sms}) do
    %{
      id: sms.id,
      phone_number: sms.phone_number,
      body: sms.body
     }
  end
end
