defmodule OtpVerification.Web.VerificationsView do
  use OtpVerification.Web, :view
  alias OtpVerification.Web.VerificationsView

  def render("index.json", %{verifications: verifications}) do
    render_many(verifications, VerificationsView, "verifications.json")
  end

  def render("show.json", %{verifications: verifications}) do
    render_one(verifications, VerificationsView, "verifications.json")
  end

  def render("verifications.json", %{verifications: verifications}) do
    %{id: verifications.id,
      type: verifications.type,
      phone_number: verifications.phone_number,
      check_digit: verifications.check_digit,
      status: verifications.status,
      code: verifications.code}
  end
end
