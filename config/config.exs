# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :otp_verification_api, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:otp_verification_api, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#
# Or read environment variables in runtime (!) as:
#
#     :var_name, "${ENV_VAR_NAME}"
config :otp_verification_api,
  namespace: OtpVerification,
  ecto_repos: [OtpVerification.Repo],
  max_attempts: {:system, :integer, "MAX_ATTEMPTS", 3},
  code_text: {:system, :string, "OTP_CODE_TEXT", "Код авторизації дій в системі eHealth: "},
  code_length: {:system, :integer, "OTP_CODE_LENGTH", 4},
  code_expiration_period: {:system, :integer, "CODE_EXPIRATION_PERIOD_MINUTES", 15}

# Configure your database
config :otp_verification_api, OtpVerification.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: {:system, "DB_NAME", "otp_verification_api_dev"},
  username: {:system, "DB_USER", "postgres"},
  password: {:system, "DB_PASSWORD", "postgres"},
  hostname: {:system, "DB_HOST", "localhost"},
  port: {:system, :integer, "DB_PORT", 5432}
# This configuration file is loaded before any dependency and
# is restricted to this project.

config :otp_verification_api, :mouth,
  adapter: {:system, :module, "GATEWAY_ADAPTER", Mouth.TestAdapter},
  source_number: {:system, "SOURCE_NUMBER", "test"},
  gateway_url: {:system, "GATEWAY_URL", "localhost:4000"},
  login: {:system, "GATEWAY_LOGIN", "test"},
  password: {:system, "GATEWAY_PASSWORD", "password"}


# Configure JSON Logger back-end
  config :logger_json, :backend,
    on_init: {OtpVerification, :load_from_system_env, []},
    json_encoder: Poison,
    metadata: :all

# General application configuration
# Configures the endpoint
config :otp_verification_api, OtpVerification.Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "7X/pAxXDa89ArqDGkBZCS4eTGKGDOdx1DDDWKS/AB42isRqbn0LoZXhIQ2n/XqTK",
  render_errors: [view: EView.Views.PhoenixError, accepts: ~w(json)]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure JSON Logger back-end
config :logger_json, :backend,
  on_init: {OtpVerification, :load_from_system_env, []},
  json_encoder: Poison,
  metadata: :all

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
import_config "#{Mix.env}.exs"
