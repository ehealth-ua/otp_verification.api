use Mix.Config

# Configuration for test environment

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.

config :core, Core.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "otp_verification_api_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432,
  pool_size: 10,
  loggers: [{EhealthLogger.Ecto, :log, [:info]}]
