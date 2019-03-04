defmodule OtpVerification.MixProject do
  @moduledoc false

  use Mix.Project

  @version "2.4.0"
  def project do
    [
      version: @version,
      apps_path: "apps",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:distillery, "~> 2.0", runtime: false},
      {:excoveralls, "~> 0.8.1", only: [:dev, :test]},
      {:credo, "~> 1.0", only: [:dev, :test]},
      {:git_ops, "~> 0.6.0", only: [:dev]}
    ]
  end
end
