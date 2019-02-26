# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :phoenix, :json_library, Jason

config :core,
  namespace: Core,
  ecto_repos: [Core.Repo],
  max_attempts: {:system, :integer, "MAX_ATTEMPTS", 3},
  code_text: {:system, :string, "OTP_CODE_TEXT", "Код авторизації дій в системі eHealth: "},
  code_length: {:system, :integer, "OTP_CODE_LENGTH", 4},
  code_expiration_period: {:system, :integer, "CODE_EXPIRATION_PERIOD_MINUTES", 15},
  api_resolvers: [sms_sender: Core.SMSLogs]

# This configuration file is loaded before any dependency and
# is restricted to this project.

config :core, Core.SMSLogs, default_adapter: {:system, :atom, "MOUTH_DEFAULT_ADAPTER", :mouth_twilio}

config :core, :mouth_twilio,
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

config :core, :mouth_sms2ip,
  adapter: {:system, :module, "SMS2IP_GATEWAY_ADAPTER", Mouth.IP2SMSAdapter},
  source_number: {:system, "SMS2IP_SOURCE_NUMBER", "test"},
  gateway_url: {:system, "SMS2IP_GATEWAY_URL", "localhost:4000"},
  gateway_status_url: {:system, "SMS2IP_GATEWAY_STATUS_URL", "localhost:4000"},
  login: {:system, "SMS2IP_GATEWAY_LOGIN", "test"},
  password: {:system, "SMS2IP_GATEWAY_PASSWORD", "password"},
  host: {:system, "SMS2IP_HOST", "https://host.ip"},
  account_sid: {:system, "SMS2IP_ACCOUNT_SID", "test"},
  auth_token: {:system, "SMS2IP_AUTH_TOKEN", "test"},
  hackney_options: [
    connect_timeout: {:system, :integer, "HACKNEY_REQUEST_TIMEOUT", 20_000},
    recv_timeout: {:system, :integer, "HACKNEY_REQUEST_TIMEOUT", 20_000},
    timeout: {:system, :integer, "HACKNEY_REQUEST_TIMEOUT", 20_000}
  ]

config :logger_json, :backend,
  formatter: EhealthLogger.Formatter,
  metadata: :all

config :logger,
  backends: [LoggerJSON],
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
