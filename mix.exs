defmodule WeatherForecast.MixProject do
  use Mix.Project

  def project do
    [
      app: :weather_forecast,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {WeatherForecast.Application, []},
      extra_applications: [:logger]
    ]
  end

  def cli do
    [preferred_envs: [check: :test]]
  end

  defp deps do
    [
      {:bandit, "~> 1.12"},
      {:jason, "~> 1.4"},
      {:plug, "~> 1.20"},
      {:req, "~> 0.6"}
    ]
  end

  defp aliases do
    [
      check: [
        "format --check-formatted",
        "compile --warnings-as-errors",
        "test --cover"
      ]
    ]
  end
end
