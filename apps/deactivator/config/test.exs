use Mix.Config

config :deactivator, worker: WorkerMock

# Print only warnings and errors during test
config :logger, level: :warn
