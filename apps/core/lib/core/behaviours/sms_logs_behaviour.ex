defmodule Core.SMSLogsBehaviour do
  @moduledoc false

  @callback deliver(message :: map, config :: map) :: {:ok, result :: term} | {:error, reason :: term}
end
