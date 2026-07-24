defmodule WeatherForecast.AverageTest do
  use ExUnit.Case, async: true

  alias WeatherForecast.Average

  test "rounds an average to one decimal place" do
    assert Average.calculate([28.5, 29.3, 27.1, 30.0, 26.8, 28.2], 6) == {:ok, 28.3}
  end

  test "rejects fewer values than requested" do
    assert Average.calculate([20, 21], 6) == {:error, :insufficient_forecast_data}
  end

  test "rejects non-numeric values" do
    assert Average.calculate([20, 21, nil, 23, 24, 25], 6) ==
             {:error, :invalid_temperature_data}
  end

  test "rejects invalid arguments" do
    assert Average.calculate(:not_a_list, 6) == {:error, :invalid_temperature_data}
    assert Average.calculate([20], 0) == {:error, :invalid_temperature_data}
  end
end
