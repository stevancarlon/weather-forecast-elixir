defmodule WeatherForecast.Cities do
  @moduledoc "The cities required by the challenge."

  @type city :: %{name: String.t(), latitude: float(), longitude: float()}

  @cities [
    %{name: "São Paulo", latitude: -23.55, longitude: -46.63},
    %{name: "Belo Horizonte", latitude: -19.92, longitude: -43.94},
    %{name: "Curitiba", latitude: -25.43, longitude: -49.27}
  ]

  @spec all() :: [city()]
  def all, do: @cities
end
