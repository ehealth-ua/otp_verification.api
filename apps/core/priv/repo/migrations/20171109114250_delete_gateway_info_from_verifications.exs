defmodule Core.Repo.Migrations.DeleteGatewayInfoFromVerifications do
  use Ecto.Migration

  def change do
    alter table("verifications") do
      remove(:gateway_id)
      remove(:gateway_status)
    end
  end
end
