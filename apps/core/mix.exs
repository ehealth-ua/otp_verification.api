defmodule Core.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      app: :core,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.8.1",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test],
      docs: [source_ref: "v#\{@version\}", main: "readme", extras: ["README.md"]]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      extra_applications: [:logger, :runtime_tools],
      mod: {Core.Application, []}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:confex_config_provider, "~> 0.1.0"},
      {:confex, "~> 3.4"},
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, "~> 0.14.1"},
      {:plug_cowboy, "~> 2.0"},
      {:plug, "~> 1.7"},
      {:hackney, "~> 1.15", override: true},
      {:httpoison, "~> 1.1.0"},
      {:jvalid, "~> 0.7.0"},
      {:mouth, git: "https://github.com/Nebo15/mouth.git", branch: "master"},
      {:timex, "~> 3.5.0"},
      {:redix, "~> 0.7.1"},
      {:ehealth_logger, git: "https://github.com/edenlabllc/ehealth_logger.git"},
      {:mox, "~> 0.4", only: [:test]},
      {:ex_machina, "~> 2.2", only: [:dev, :test]},
      {:kube_rpc, "~> 0.3.0"},
      {:jason, "~> 1.1"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
