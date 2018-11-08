defmodule OtpVerification.Web.Router do
  @moduledoc """
  The router provides a set of macros for generating routes
  that dispatch to specific controllers and actions.
  Those macros are named after HTTP verbs.

  More info at: https://hexdocs.pm/phoenix/Phoenix.Router.html
  """
  use OtpVerification.Web, :router
  use Plug.ErrorHandler

  alias Plug.LoggerJSON

  require Logger

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:put_secure_browser_headers)

    # Uncomment to enable versioning of your API
    # plug Multiverse, gates: [
    #   "2016-07-31": OtpVerification.Web.InitialGate
    # ]

    # You can allow JSONP requests by uncommenting this line:
    # plug :allow_jsonp
  end

  scope "/", OtpVerification.Web do
    pipe_through(:api)

    get("/verifications/:phone_number", VerificationsController, :show)
    post("/verifications", VerificationsController, :initialize)
    patch("/verifications/:phone_number/actions/complete", VerificationsController, :complete)

    post("/sms/send", SMSController, :send)
  end

  defp handle_errors(%Plug.Conn{status: 500} = conn, %{kind: kind, reason: reason, stack: stacktrace}) do
    LoggerJSON.log_error(kind, reason, stacktrace)
    send_resp(conn, 500, Poison.encode!(%{errors: %{detail: "Internal server error"}}))
  end

  defp handle_errors(_, _), do: nil
end
