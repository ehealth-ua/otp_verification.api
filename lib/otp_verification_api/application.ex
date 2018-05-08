defmodule OtpVerification do
  @moduledoc """
  This is an entry point of otp_verification_api application.
  """

  use Application
  alias OtpVerification.Web.Endpoint
  alias Confex.Resolver
  alias OtpVerification.Redix, as: VerificationRedix

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    redix_config = VerificationRedix.config()

    redix_workers =
      for i <- 0..(redix_config[:pool_size] - 1) do
        worker(
          Redix,
          [
            [
              host: redix_config[:host],
              port: redix_config[:port],
              password: redix_config[:password],
              database: redix_config[:database]
            ],
            [name: :"redix_#{i}"]
          ],
          id: {Redix, i}
        )
      end

    configure_log_level()

    # Define workers and child supervisors to be supervised
    children =
      redix_workers ++
        [
          # Start the Ecto repository
          supervisor(OtpVerification.Repo, []),
          # Start the endpoint when the application starts
          supervisor(OtpVerification.Web.Endpoint, []),
          # Starts a worker by calling: OtpVerification.Worker.start_link(arg1, arg2, arg3)
          worker(OtpVerification.Scheduler, []),
          worker(OtpVerification.Worker, [:cancel_verifications, [minutes: 1]])
        ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
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
