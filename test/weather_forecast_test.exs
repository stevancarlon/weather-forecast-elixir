defmodule WeatherForecastTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  defmodule SuccessfulClient do
    @behaviour WeatherForecast.Client

    @impl true
    def fetch_daily_max(city) do
      send(WeatherForecastTest, {:started, city.name, self()})

      receive do
        :continue -> {:ok, [20, 21, 22, 23, 24, 25, 100]}
      end
    end
  end

  defmodule FailingClient do
    @behaviour WeatherForecast.Client

    @impl true
    def fetch_daily_max(%{name: "Curitiba"}), do: {:error, :service_unavailable}
    def fetch_daily_max(_city), do: {:ok, List.duplicate(24, 6)}
  end

  defmodule SlowClient do
    @behaviour WeatherForecast.Client

    @impl true
    def fetch_daily_max(_city) do
      Process.sleep(:infinity)
    end
  end

  defmodule CrashingClient do
    @behaviour WeatherForecast.Client

    @impl true
    def fetch_daily_max(%{name: "Curitiba"}), do: raise("unexpected provider failure")
    def fetch_daily_max(_city), do: {:ok, List.duplicate(24, 6)}
  end

  test "fetches all cities concurrently and averages only the first six days" do
    Process.register(self(), WeatherForecastTest)

    task = Task.async(fn -> WeatherForecast.forecast(client: SuccessfulClient) end)

    workers =
      for _ <- 1..3 do
        assert_receive {:started, city, worker}, 500
        {city, worker}
      end

    assert workers |> Enum.map(&elem(&1, 0)) |> Enum.sort() ==
             ["Belo Horizonte", "Curitiba", "São Paulo"]

    Enum.each(workers, fn {_city, worker} -> send(worker, :continue) end)

    assert {:ok, forecasts} = Task.await(task)
    assert Enum.map(forecasts, & &1.city) == ["São Paulo", "Belo Horizonte", "Curitiba"]
    assert Enum.all?(forecasts, &(&1.average_max_temperature == 22.5))
  end

  test "returns identified errors when one city fails" do
    assert {:error, [%{city: "Curitiba", reason: :service_unavailable}]} =
             WeatherForecast.forecast(client: FailingClient)
  end

  test "identifies every city whose task times out" do
    assert {:error, errors} = WeatherForecast.forecast(client: SlowClient, timeout: 1)

    assert Enum.map(errors, & &1.city) == ["São Paulo", "Belo Horizonte", "Curitiba"]
    assert Enum.all?(errors, &(&1.reason == {:task_exit, :timeout}))
  end

  test "contains a client crash without crashing the caller" do
    capture_log(fn ->
      assert {:error, [%{city: "Curitiba", reason: {:task_exit, reason}}]} =
               WeatherForecast.forecast(client: CrashingClient)

      assert Exception.format_exit(reason) =~ "unexpected provider failure"
    end)
  end
end
