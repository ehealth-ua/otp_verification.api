defmodule Terminator.Behaviours.WorkerBehaviour do
  @moduledoc false

  @callback stop_application() :: no_return()
end
