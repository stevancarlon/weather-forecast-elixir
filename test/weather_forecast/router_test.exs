defmodule WeatherForecast.RouterTest do
  use ExUnit.Case, async: false
  import Plug.Test

  alias WeatherForecast.Router

  defmodule ClientStub do
    @behaviour WeatherForecast.Client

    @impl true
    def fetch_daily_max(_city), do: {:ok, [20, 21, 22, 23, 24, 25]}
  end

  defmodule FailingClientStub do
    @behaviour WeatherForecast.Client

    @impl true
    def fetch_daily_max(_city), do: {:error, :unavailable}
  end

  setup do
    previous_client = Application.get_env(:weather_forecast, :weather_client)
    Application.put_env(:weather_forecast, :weather_client, ClientStub)

    on_exit(fn ->
      Application.put_env(:weather_forecast, :weather_client, previous_client)
    end)
  end

  test "GET /health reports that the API is available" do
    conn = Router.call(conn(:get, "/health"), Router.init([]))

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body) == %{"status" => "ok"}
  end

  test "unknown routes return JSON with a 404 status" do
    conn = Router.call(conn(:get, "/missing"), Router.init([]))

    assert conn.status == 404
    assert Jason.decode!(conn.resp_body) == %{"error" => "not_found"}
  end

  test "GET /api/weather returns all calculated city averages" do
    conn = Router.call(conn(:get, "/api/weather"), Router.init([]))
    body = Jason.decode!(conn.resp_body)

    assert conn.status == 200
    assert length(body["data"]) == 3

    assert %{
             "average_max_temperature" => 22.5,
             "city" => "São Paulo",
             "days" => 6,
             "unit" => "°C"
           } = hd(body["data"])
  end

  test "GET /api/weather translates provider errors into a bad gateway response" do
    Application.put_env(:weather_forecast, :weather_client, FailingClientStub)

    conn = Router.call(conn(:get, "/api/weather"), Router.init([]))
    body = Jason.decode!(conn.resp_body)

    assert conn.status == 502
    assert body["error"] == "weather_provider_error"
    assert length(body["details"]) == 3
    assert hd(body["details"]) == %{"city" => "São Paulo", "reason" => ":unavailable"}
  end
end
