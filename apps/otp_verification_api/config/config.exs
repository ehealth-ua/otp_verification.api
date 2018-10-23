use Mix.Config

# Configures the endpoint
config :otp_verification_api, OtpVerification.Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "7X/pAxXDa89ArqDGkBZCS4eTGKGDOdx1DDDWKS/AB42isRqbn0LoZXhIQ2n/XqTK",
  render_errors: [view: EView.Views.PhoenixError, accepts: ~w(json)]

import_config "#{Mix.env()}.exs"
