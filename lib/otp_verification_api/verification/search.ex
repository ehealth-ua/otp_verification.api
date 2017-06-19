defmodule OtpVerification.Verification.Search do
  @moduledoc false
  use Ecto.Schema

  embedded_schema do
    field :phone_number, :string
    field :statuses, :string
  end
end
