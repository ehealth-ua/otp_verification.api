defmodule Core.SMSLogsBehaviour do
  @moduledoc false

  @callback deliver(message :: map, config :: map, provider :: atom) :: {:ok, result :: term} | {:error, reason :: term}
end
