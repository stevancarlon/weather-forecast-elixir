defmodule WeatherForecast.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: WeatherForecast.TaskSupervisor}
    ]

    children =
      if Application.get_env(:weather_forecast, :start_server, false) do
        children ++
          [
            {Bandit,
             plug: WeatherForecast.Router,
             scheme: :http,
             port: Application.get_env(:weather_forecast, :port, 4000)}
          ]
      else
        children
      end

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: WeatherForecast.Supervisor
    )
  end
end
