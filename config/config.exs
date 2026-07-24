import Config

config :weather_forecast,
  port: 4000,
  start_server: false,
  weather_client: WeatherForecast.OpenMeteoClient,
  weather_req_options: []

import_config "#{config_env()}.exs"
