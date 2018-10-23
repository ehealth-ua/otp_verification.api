defmodule Core.Repo.Migrations.AddUniqueIndexes do
  use Ecto.Migration

  def change do
    create(unique_index(:verifications, [:phone_number], where: "active = true"))
  end
end
