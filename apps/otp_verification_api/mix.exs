defmodule OtpVerificationAPI.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      app: :otp_verification_api,
      version: "0.1.0",
      elixir: "~> 1.6",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [mod: {OtpVerification.Application, []}, extra_applications: [:logger, :runtime_tools]]
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
      {:confex, "~> 3.3"},
      {:poison, "~> 3.1"},
      {:httpoison, "~> 1.1.0"},
      {:hackney, "~> 1.13", override: true},
      {:cowboy, "~> 1.1"},
      {:phoenix, "~> 1.3.3"},
      {:eview, "~> 0.12.4"},
      {:phoenix_ecto, "~> 3.2"},
      {:plug_logger_json, "~> 0.5"},
      {:ecto_logger_json, git: "https://github.com/edenlabllc/ecto_logger_json.git", branch: "query_params"},
      {:excoveralls, "~> 0.8.1", only: [:dev, :test]},
      {:ex_machina, "~> 2.2", only: [:dev, :test]},
      {:core, in_umbrella: true}
    ]
  end

  defp aliases do
    [
      "ecto.setup": fn _ -> Mix.shell().cmd("cd ../core && mix ecto.setup") end
    ]
  end
end
