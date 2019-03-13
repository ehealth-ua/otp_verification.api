defmodule Core.Application do
  @moduledoc """
  This is an entry point of core application.
  """

  use Application
  alias Core.Redix, as: VerificationRedix

  def start(_type, _args) do
    :telemetry.attach("log-handler", [:core, :repo, :query], &Core.TelemetryHandler.handle_event/4, nil)

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

    # Define workers and child supervisors to be supervised
    children = redix_workers ++ [supervisor(Core.Repo, [])]

    opts = [strategy: :one_for_one, name: Core.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
