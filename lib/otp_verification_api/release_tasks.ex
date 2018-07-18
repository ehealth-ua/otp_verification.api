defmodule OtpVerification.ReleaseTasks do
  @moduledoc """
  Nice way to apply migrations inside a released application.

  Example:

      otp_verification_api/bin/otp_verification_api command Elixir.OtpVerification.ReleaseTasks migrate!
  """
  import Mix.Ecto, warn: false

  @priv_dir "priv"
  @repo OtpVerification.Repo

  def migrate! do
    # Migrate
    migrations_dir = Application.app_dir(:otp_verification_api, "priv/repo/migrations")

    # Run migrations
    @repo
    |> start_repo()
    |> Ecto.Migrator.run(migrations_dir, :up, all: true)

    System.halt(0)
    :init.stop()
  end

  def seed! do
    seed_script = Path.join([@priv_dir, "repo", "seeds.exs"])

    # Run seed script
    start_repo(@repo)

    Code.require_file(seed_script)

    System.halt(0)
    :init.stop()
  end

  defp start_repo(repo) do
    load_app()
    {:ok, _} = repo.start_link()
    repo
  end

  defp load_app do
    start_applications([:logger, :postgrex, :ecto, :redix])
    :ok = Application.load(:otp_verification_api)
  end

  defp start_applications(apps) do
    Enum.each(apps, fn app ->
      {_, _message} = Application.ensure_all_started(app)
    end)
  end
end
