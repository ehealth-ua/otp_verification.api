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
#     config :core, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:core, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#
# Or read environment variables in runtime (!) as:
#
#     :var_name, "${ENV_VAR_NAME}"
config :core,
  namespace: Core,
  ecto_repos: [Core.Repo],
  max_attempts: {:system, :integer, "MAX_ATTEMPTS", 3},
  code_text: {:system, :string, "OTP_CODE_TEXT", "Код авторизації дій в системі eHealth: "},
  code_length: {:system, :integer, "OTP_CODE_LENGTH", 4},
  code_expiration_period: {:system, :integer, "CODE_EXPIRATION_PERIOD_MINUTES", 15},
  sms_statuses_expiration: {:system, :integer, "SMS_STATUSES_EXPIRATION_MINUTES", 32},
  sms_update_timeout: {:system, :integer, "SMS_UPDATE_TIMEOUT_MINUTES", 30},
  sms_collect_timeout: {:system, :integer, "SMS_COLLECT_TIMEOUT", 20_000}

# This configuration file is loaded before any dependency and
# is restricted to this project.

config :core, :mouth,
  adapter: {:system, :module, "GATEWAY_ADAPTER", Mouth.TestAdapter},
  source_number: {:system, "SOURCE_NUMBER", "test"},
  gateway_url: {:system, "GATEWAY_URL", "localhost:4000"},
  gateway_status_url: {:system, "GATEWAY_STATUS_URL", "localhost:4000"},
  login: {:system, "GATEWAY_LOGIN", "test"},
  password: {:system, "GATEWAY_PASSWORD", "password"},
  host: {:system, "TWILIO_HOST", "https://api.twilio.com"},
  account_sid: {:system, "TWILIO_ACCOUNT_SID", "test"},
  auth_token: {:system, "TWILIO_AUTH_TOKEN", "test"},
  hackney_options: [
    connect_timeout: {:system, :integer, "HACKNEY_REQUEST_TIMEOUT", 20_000},
    recv_timeout: {:system, :integer, "HACKNEY_REQUEST_TIMEOUT", 20_000},
    timeout: {:system, :integer, "HACKNEY_REQUEST_TIMEOUT", 20_000}
  ]

# General application configuration
# Configures Elixir's Logger
config :logger, :console,
  format: "$message\n",
  handle_otp_reports: true,
  level: :info

config :core, Core.Redix,
  host: {:system, "REDIS_HOST", "0.0.0.0"},
  port: {:system, :integer, "REDIS_PORT", 6379},
  password: {:system, "REDIS_PASSWORD", nil},
  database: {:system, "REDIS_DATABASE", nil},
  pool_size: {:system, :integer, "REDIS_POOL_SIZE", 5}

config :core, Core.Verification.Verifications,
  init_verification_limit: {:system, :integer, "INIT_VERIFICATION_LIMIT", 0}

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
import_config "#{Mix.env()}.exs"
