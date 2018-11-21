defmodule Scheduler.Jobs.SmsStatusUpdater.Counter do
  @moduledoc false

  use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(state) do
    :ets.new(:sms_counter, [:public, :named_table])
    {:ok, state}
  end
end
