import Config

config :weather_forecast,
  start_server: false,
  weather_req_options: [
    plug: {Req.Test, WeatherForecast.OpenMeteoClient},
    retry: false
  ]
