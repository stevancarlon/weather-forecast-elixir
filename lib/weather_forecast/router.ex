defmodule WeatherForecast.Router do
  @moduledoc false

  use Plug.Router

  plug(Plug.RequestId)
  plug(:match)
  plug(:dispatch)

  get "/health" do
    json(conn, 200, %{status: "ok"})
  end

  get "/api/weather" do
    case WeatherForecast.forecast() do
      {:ok, forecasts} ->
        json(conn, 200, %{data: forecasts})

      {:error, errors} ->
        json(conn, 502, %{
          error: "weather_provider_error",
          details: Enum.map(errors, &serialize_error/1)
        })
    end
  end

  match _ do
    json(conn, 404, %{error: "not_found"})
  end

  defp json(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end

  defp serialize_error(%{city: city, reason: reason}) do
    %{city: city, reason: inspect(reason)}
  end
end
