defmodule OtpVerification.Web.VerificationsView do
  @moduledoc false
  use OtpVerification.Web, :view
  alias OtpVerification.Web.VerificationsView

  def render("show.json", %{verifications: verifications}) do
    render_one(verifications, VerificationsView, "verifications.json")
  end

  def render("verifications.json", %{verifications: verifications}) do
    %{
      id: verifications.id,
      phone_number: verifications.phone_number,
      check_digit: verifications.check_digit,
      status: verifications.status,
      code: verifications.code,
      code_expired_at: verifications.code_expired_at,
      active: verifications.active
     }
  end
  def render("phone.json", %{verified_phone: phone_number}) do
    %{
      phone_number: phone_number
     }
  end
end
