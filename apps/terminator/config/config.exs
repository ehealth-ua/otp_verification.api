# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :terminator, worker: Terminator.Worker
config :terminator, Terminator.Application, env: Mix.env()

config :terminator, Terminator.Worker,
  validations_expired_timeout: {:system, :integer, "VALIDATIONS_EXPIRATION_PERIOD_DAYS", 30}

# Configures Elixir's Logger
config :logger, :console,
  format: "$message\n",
  metadata: [:request_id]

import_config "#{Mix.env()}.exs"
