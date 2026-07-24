import Config

if System.get_env("START_SERVER") in ["1", "true"] do
  config :weather_forecast, start_server: true
end

if port = System.get_env("PORT") do
  config :weather_forecast, port: String.to_integer(port)
end
