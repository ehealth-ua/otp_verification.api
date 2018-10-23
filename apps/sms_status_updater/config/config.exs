# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :sms_status_updater, worker: SMSStatusUpdater.Worker
config :sms_status_updater, SMSStatusUpdater.Application, env: Mix.env()

# Configures Elixir's Logger
config :logger, :console,
  format: "$message\n",
  metadata: [:request_id]

import_config "#{Mix.env()}.exs"
