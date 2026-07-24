defmodule WeatherForecast.CLI do
  @moduledoc false

  def run(opts \\ []) do
    case WeatherForecast.forecast(opts) do
      {:ok, forecasts} ->
        Enum.each(forecasts, fn forecast ->
          IO.puts("#{forecast.city}: #{forecast.average_max_temperature}°C")
        end)

        :ok

      {:error, errors} ->
        IO.puts(:stderr, "Unable to fetch all forecasts: #{inspect(errors)}")
        {:error, errors}
    end
  end
end
