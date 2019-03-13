defmodule Core.ReleaseTasks do
  @moduledoc """
  Nice way to apply migrations inside a released application.

  Example:

      otp_verification_api/bin/core command Elixir.Core.ReleaseTasks migrate!
  """

  alias Ecto.Migrator

  @repo Core.Repo

  def migrate do
    # Migrate
    migrations_dir = Application.app_dir(:core, "priv/repo/migrations")

    # Run migrations
    @repo
    |> start_repo()
    |> Migrator.run(migrations_dir, :up, all: true)

    System.halt(0)
    :init.stop()
  end

  defp start_repo(repo) do
    start_applications([:logger, :postgrex, :ecto, :ecto_sql, :redis])
    Application.load(:otp_verification_api)
    # If you don't include Repo in application supervisor start it here manually
    repo.start_link()
    repo
  end

  defp start_applications(apps) do
    Enum.each(apps, fn app ->
      {_, _message} = Application.ensure_all_started(app)
    end)
  end
end
