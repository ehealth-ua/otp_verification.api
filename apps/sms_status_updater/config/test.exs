use Mix.Config

config :sms_status_updater, worker: WorkerMock

# Print only warnings and errors during test
config :logger, level: :warn
