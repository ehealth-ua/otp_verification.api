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

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:myapp, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:confex_config_provider, "~> 0.1.0"},
      {:confex, "~> 3.3"},
      {:poison, "~> 3.1"},
      {:ecto, "~> 2.1"},
      {:postgrex, ">= 0.0.0"},
      {:cowboy, "~> 1.1"},
      {:hackney, "~> 1.13", override: true},
      {:httpoison, "~> 1.1.0"},
      {:jvalid, "~> 0.6.0"},
      {:mouth, git: "https://github.com/Nebo15/mouth.git", branch: "master"},
      {:ecto_logger_json, git: "https://github.com/edenlabllc/ecto_logger_json.git", branch: "query_params"},
      {:timex, "~> 3.2"},
      {:redix, "~> 0.7.1"},
      {:phoenix, "~> 1.3.3"},
      {:eview, "~> 0.12.4"},
      {:ex_doc, ">= 0.15.0", only: [:dev, :test]},
      {:excoveralls, "~> 0.8.1", only: [:dev, :test]},
      {:mox, "~> 0.4", only: [:test]},
      {:ex_machina, "~> 2.2", only: [:dev, :test]}
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
