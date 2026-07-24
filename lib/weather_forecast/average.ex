defmodule WeatherForecast.Average do
  @moduledoc false

  @spec calculate([number()], pos_integer()) :: {:ok, float()} | {:error, atom()}
  def calculate(values, days) when is_list(values) and is_integer(days) and days > 0 do
    selected = Enum.take(values, days)

    cond do
      length(selected) < days ->
        {:error, :insufficient_forecast_data}

      not Enum.all?(selected, &is_number/1) ->
        {:error, :invalid_temperature_data}

      true ->
        {:ok, selected |> Enum.sum() |> Kernel./(days) |> Float.round(1)}
    end
  end

  def calculate(_values, _days), do: {:error, :invalid_temperature_data}
end
