use Mix.Config

# Configuration for test environment

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :otp_verification_api, OtpVerification.Web.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :otp_verification_api, OtpVerification.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "otp_verification_api_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432,
  pool_size: 10,
  loggers: [{Ecto.LoggerJSON, :log, [:info]}]

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20
