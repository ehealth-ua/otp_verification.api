use Mix.Config

config :scheduler, Scheduler.Worker,
  terminator_schedule: {:system, :string, "TERMINATOR_SCHEDULE", "*/15 * * * *"},
  deactivator_schedule: {:system, :string, "DEACTIVATOR_SCHEDULE", "* * * * *"},
  sms_status_updater_schedule: {:system, :string, "SMS_STATUS_UPDATER_SCHEDULE", "* * * * *"}

config :scheduler, Scheduler.Jobs.Terminator,
  validations_expired_timeout: {:system, :integer, "VALIDATIONS_EXPIRATION_PERIOD_DAYS", 30}

config :scheduler, Scheduler.Jobs.SmsStatusUpdater,
  sms_statuses_expiration: {:system, :integer, "SMS_STATUSES_EXPIRATION_MINUTES", 32},
  sms_update_timeout: {:system, :integer, "SMS_UPDATE_TIMEOUT_MINUTES", 30},
  sms_collect_timeout: {:system, :integer, "SMS_COLLECT_TIMEOUT", 20_000}

import_config "#{Mix.env()}.exs"
