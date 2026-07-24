defmodule Mix.Tasks.WeatherTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  defmodule ClientStub do
    @behaviour WeatherForecast.Client

    @impl true
    def fetch_daily_max(_city), do: {:ok, List.duplicate(26.0, 6)}
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

  test "mix weather runs the challenge's terminal interface" do
    Mix.Task.reenable("weather")

    output = capture_io(fn -> Mix.Task.run("weather") end)

    assert output ==
             """
             São Paulo: 26.0°C
             Belo Horizonte: 26.0°C
             Curitiba: 26.0°C
             """
  end

  test "mix weather exits unsuccessfully when forecasts cannot be obtained" do
    Application.put_env(:weather_forecast, :weather_client, FailingClientStub)
    Mix.Task.reenable("weather")

    output =
      capture_io(:stderr, fn ->
        assert_raise Mix.Error, fn -> Mix.Task.run("weather") end
      end)

    assert output =~ "Unable to fetch all forecasts"
  end
end
