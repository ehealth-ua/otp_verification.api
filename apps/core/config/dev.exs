use Mix.Config

config :core, Core.Repo,
  database: "otp_verification_api_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432,
  pool_size: 10
