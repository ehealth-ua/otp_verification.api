defmodule OtpVerification.Application do
  @moduledoc """
  This is an entry point of otp_verification_api application.
  """

  use Application
  alias Confex.Resolver
  alias OtpVerification.Web.Endpoint

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    configure_log_level()

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(Endpoint, [])
    ]

    opts = [strategy: :one_for_one, name: OtpVerification.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end

  # Loads configuration in `:on_init` callbacks and replaces `{:system, ..}` tuples via Confex
  @doc false
  def load_from_system_env(config) do
    Resolver.resolve(config)
  end

  # Configures Logger level via LOG_LEVEL environment variable.
  defp configure_log_level do
    case System.get_env("LOG_LEVEL") do
      nil ->
        :ok

      level when level in ["debug", "info", "warn", "error"] ->
        Logger.configure(level: String.to_atom(level))

      level ->
        raise ArgumentError,
              "LOG_LEVEL environment should have one of 'debug', 'info', 'warn', 'error' values," <>
                "got: #{inspect(level)}"
    end
  end
end
