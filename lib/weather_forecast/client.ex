defmodule WeatherForecast.Client do
  @moduledoc "Contract implemented by weather data providers."

  alias WeatherForecast.Cities

  @callback fetch_daily_max(Cities.city()) ::
              {:ok, [number()]} | {:error, term()}
end
