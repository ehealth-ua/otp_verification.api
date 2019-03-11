defmodule Core.Verification.VerifiedPhone do
  @moduledoc false
  use Ecto.Schema
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "verified_phones" do
    field(:phone_number, :string)

    timestamps(type: :utc_datetime, inserted_at: false)
  end
end
