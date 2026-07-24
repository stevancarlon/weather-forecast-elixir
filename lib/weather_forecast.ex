defmodule WeatherForecast do
  @moduledoc """
  Fetches six-day forecasts concurrently and calculates each city's average
  maximum temperature.
  """

  alias WeatherForecast.{Average, Cities}

  @forecast_days 6
  @task_timeout 30_000

  @type result :: %{
          city: String.t(),
          average_max_temperature: float(),
          unit: String.t(),
          days: pos_integer()
        }

  @doc """
  Returns the average maximum temperature for every configured city.

  The HTTP client can be replaced through the `:client` option, which keeps
  tests deterministic and independent from Open-Meteo.
  """
  @spec forecast(keyword()) :: {:ok, [result()]} | {:error, [map()]}
  def forecast(opts \\ []) do
    client = Keyword.get(opts, :client, configured_client())
    timeout = Keyword.get(opts, :timeout, @task_timeout)
    cities = Cities.all()

    results =
      Task.Supervisor.async_stream_nolink(
        WeatherForecast.TaskSupervisor,
        cities,
        &forecast_city(&1, client),
        max_concurrency: length(cities),
        ordered: true,
        timeout: timeout,
        on_timeout: :kill_task
      )
      |> Enum.zip(cities)
      |> Enum.map(&normalize_task_result/1)

    errors = for {:error, error} <- results, do: error

    if errors == [] do
      {:ok, for({:ok, result} <- results, do: result)}
    else
      {:error, errors}
    end
  end

  defp forecast_city(city, client) do
    with {:ok, temperatures} <- client.fetch_daily_max(city),
         {:ok, average} <- Average.calculate(temperatures, @forecast_days) do
      {:ok,
       %{
         city: city.name,
         average_max_temperature: average,
         unit: "°C",
         days: @forecast_days
       }}
    else
      {:error, reason} -> {:error, %{city: city.name, reason: reason}}
    end
  end

  defp normalize_task_result({{:ok, {:ok, result}}, _city}), do: {:ok, result}
  defp normalize_task_result({{:ok, {:error, error}}, _city}), do: {:error, error}

  defp normalize_task_result({{:exit, reason}, city}),
    do: {:error, %{city: city.name, reason: {:task_exit, reason}}}

  defp configured_client do
    Application.get_env(:weather_forecast, :weather_client, WeatherForecast.OpenMeteoClient)
  end
end
