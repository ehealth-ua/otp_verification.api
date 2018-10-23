use Mix.Config

# Configuration for test environment
config :ex_unit, capture_log: true

# Configure your database
config :core, Core.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox,
  username: "postgres",
  password: "postgres",
  database: "otp_verification_api_test",
  hostname: "localhost",
  ownership_timeout: 120_000_000

# We don't run a server during test. If one is required,
# you can enable the server option below.

# Print only warnings and errors during test
config :logger, level: :debug

# Run acceptance test in concurrent mode
config :core, sql_sandbox: true

config :core, :mouth, adapter: Mouth.TestAdapter
