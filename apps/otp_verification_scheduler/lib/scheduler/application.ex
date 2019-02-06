defmodule Scheduler.Application do
  @moduledoc false

  use Application
  alias Scheduler.Jobs.SmsStatusUpdater.Counter
  alias Scheduler.Worker

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {Counter, []},
      {Worker, []}
    ]

    opts = [strategy: :one_for_one, name: Scheduler.Supervisor]
    result = Supervisor.start_link(children, opts)
    Worker.create_jobs()
    result
  end
end
