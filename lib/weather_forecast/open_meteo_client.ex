defmodule WeatherForecast.OpenMeteoClient do
  @moduledoc "Open-Meteo implementation of `WeatherForecast.Client`."

  @behaviour WeatherForecast.Client

  @base_url "https://api.open-meteo.com/v1/forecast"

  @impl true
  def fetch_daily_max(city) do
    options = [
      headers: [
        {"user-agent",
         "weather-forecast-elixir/0.1.0 (+https://github.com/stevancarlon/weather-forecast-elixir)"}
      ],
      params: [
        latitude: city.latitude,
        longitude: city.longitude,
        daily: "temperature_2m_max",
        forecast_days: 6,
        temperature_unit: "celsius",
        timezone: "America/Sao_Paulo"
      ],
      receive_timeout: 8_000,
      retry: :transient,
      max_retries: 2
    ]

    options =
      Keyword.merge(
        options,
        Application.get_env(:weather_forecast, :weather_req_options, [])
      )

    case Req.get(@base_url, options) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        parse_response(body)

      {:ok, %Req.Response{status: status}} ->
        {:error, {:unexpected_status, status}}

      {:error, exception} ->
        {:error, {:request_failed, Exception.message(exception)}}
    end
  end

  @doc false
  def parse_response(%{"daily" => %{"temperature_2m_max" => values}})
      when is_list(values) do
    if Enum.all?(values, &is_number/1) do
      {:ok, values}
    else
      {:error, :invalid_api_response}
    end
  end

  def parse_response(_body), do: {:error, :invalid_api_response}
end
