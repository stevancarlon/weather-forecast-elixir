defmodule WeatherForecast.OpenMeteoClientTest do
  use ExUnit.Case, async: true

  alias WeatherForecast.OpenMeteoClient

  @city %{name: "São Paulo", latitude: -23.55, longitude: -46.63}

  test "requests and extracts the required six-day Open-Meteo forecast" do
    Req.Test.expect(OpenMeteoClient, fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)

      assert conn.query_params == %{
               "daily" => "temperature_2m_max",
               "forecast_days" => "6",
               "latitude" => "-23.55",
               "longitude" => "-46.63",
               "temperature_unit" => "celsius",
               "timezone" => "America/Sao_Paulo"
             }

      Req.Test.json(conn, %{
        "daily" => %{"temperature_2m_max" => [20, 21, 22, 23, 24, 25]}
      })
    end)

    assert OpenMeteoClient.fetch_daily_max(@city) == {:ok, [20, 21, 22, 23, 24, 25]}
  end

  test "rejects a malformed JSON response" do
    Req.Test.expect(OpenMeteoClient, &Req.Test.json(&1, %{"daily" => %{}}))

    assert OpenMeteoClient.fetch_daily_max(@city) == {:error, :invalid_api_response}
  end

  test "rejects non-numeric temperatures from the provider" do
    Req.Test.expect(
      OpenMeteoClient,
      &Req.Test.json(&1, %{
        "daily" => %{"temperature_2m_max" => [20, nil, 22, 23, 24, 25]}
      })
    )

    assert OpenMeteoClient.fetch_daily_max(@city) == {:error, :invalid_api_response}
  end

  test "reports non-success statuses" do
    Req.Test.expect(OpenMeteoClient, &Plug.Conn.send_resp(&1, 503, "unavailable"))

    assert OpenMeteoClient.fetch_daily_max(@city) ==
             {:error, {:unexpected_status, 503}}
  end

  test "reports network failures without leaking an exception" do
    Req.Test.expect(OpenMeteoClient, &Req.Test.transport_error(&1, :econnrefused))

    assert {:error, {:request_failed, message}} = OpenMeteoClient.fetch_daily_max(@city)
    assert message =~ "connection refused"
  end
end
