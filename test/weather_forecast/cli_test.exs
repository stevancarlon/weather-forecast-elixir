defmodule WeatherForecast.CLITest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias WeatherForecast.CLI

  defmodule ClientStub do
    @behaviour WeatherForecast.Client

    @impl true
    def fetch_daily_max(_city), do: {:ok, List.duplicate(27.5, 6)}
  end

  defmodule FailingClientStub do
    @behaviour WeatherForecast.Client

    @impl true
    def fetch_daily_max(_city), do: {:error, :unavailable}
  end

  test "prints one clearly formatted line per city" do
    output =
      capture_io(fn ->
        assert CLI.run(client: ClientStub) == :ok
      end)

    assert output ==
             """
             São Paulo: 27.5°C
             Belo Horizonte: 27.5°C
             Curitiba: 27.5°C
             """
  end

  test "writes failures to standard error" do
    output =
      capture_io(:stderr, fn ->
        assert {:error, errors} = CLI.run(client: FailingClientStub)
        assert length(errors) == 3
      end)

    assert output =~ "Unable to fetch all forecasts"
  end
end
