defmodule OtpVerification.Repo.Migrations.AddVerificationIndex do
  @moduledoc false

  use Ecto.Migration

  def change do
    create(index(:verifications, [:phone_number, :inserted_at]))
  end
end
