defmodule Mix.Tasks.Weather do
  @moduledoc "Fetches and prints the six-day weather averages."

  use Mix.Task

  @shortdoc "Print average maximum temperatures"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    case WeatherForecast.CLI.run() do
      :ok -> :ok
      {:error, _errors} -> Mix.raise("Could not retrieve every city's forecast")
    end
  end
end
