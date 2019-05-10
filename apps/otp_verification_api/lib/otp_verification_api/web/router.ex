defmodule OtpVerification.Web.Router do
  @moduledoc """
  The router provides a set of macros for generating routes
  that dispatch to specific controllers and actions.
  Those macros are named after HTTP verbs.

  More info at: https://hexdocs.pm/phoenix/Phoenix.Router.html
  """
  use OtpVerification.Web, :router

  require Logger

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:put_secure_browser_headers)
  end

  scope "/", OtpVerification.Web do
    pipe_through(:api)

    get("/verifications/:phone_number", VerificationsController, :show)
    post("/verifications", VerificationsController, :initialize)
    patch("/verifications/:phone_number/actions/complete", VerificationsController, :complete)

    post("/sms/send", SMSController, :send)
  end
end
