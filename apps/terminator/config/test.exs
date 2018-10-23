use Mix.Config

config :terminator, worker: WorkerMock

# Print only warnings and errors during test
config :logger, level: :warn
