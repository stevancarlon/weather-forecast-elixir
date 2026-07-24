defmodule WeatherForecast.CitiesTest do
  use ExUnit.Case, async: true

  alias WeatherForecast.Cities

  test "contains exactly the cities and coordinates specified by the challenge" do
    assert Cities.all() == [
             %{name: "São Paulo", latitude: -23.55, longitude: -46.63},
             %{name: "Belo Horizonte", latitude: -19.92, longitude: -43.94},
             %{name: "Curitiba", latitude: -25.43, longitude: -49.27}
           ]
  end
end
