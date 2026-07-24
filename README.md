# Weather Forecast

Elixir solution for the Open-Meteo technical challenge. It concurrently fetches
the next six days of maximum temperatures for São Paulo, Belo Horizonte, and
Curitiba, then calculates each city's average.

The required terminal application is the primary interface. A small HTTP API is
also included so the same Elixir service can be tested with Postman and later
consumed by a browser interface. This is a plain Mix application—Phoenix is not
used.

## Requirements

- Elixir 1.15 or newer
- A compatible Erlang/OTP release

The project is currently verified with Elixir 1.19 and Erlang/OTP 28.

## Setup

```bash
mix deps.get
```

## Run the challenge

```bash
mix weather
```

Example output:

```text
São Paulo: 24.8°C
Belo Horizonte: 25.6°C
Curitiba: 20.7°C
```

The numbers depend on the current Open-Meteo forecast.

## Challenge requirements

| Requirement | Implementation |
| --- | --- |
| Three specified cities and coordinates | `WeatherForecast.Cities` |
| Today plus five days | `forecast_days=6` in `OpenMeteoClient` |
| Concurrent API calls | `Task.Supervisor.async_stream_nolink/4` |
| Average `temperature_2m_max` | `WeatherForecast.Average` |
| Clear city-by-city output | `mix weather` |
| Deterministic API mocks | `Req.Test` and client behaviours |

## Test with Postman

Start the HTTP server:

```bash
START_SERVER=true mix run --no-halt
```

Then send a `GET` request to:

```text
http://localhost:4000/api/weather
```

Successful responses use this shape:

```json
{
  "data": [
    {
      "average_max_temperature": 24.8,
      "city": "São Paulo",
      "days": 6,
      "unit": "°C"
    }
  ]
}
```

The health check is available at `GET http://localhost:4000/health`. Unknown
routes return `404`, and an Open-Meteo failure returns `502` with city-specific
details.

## Tests

```bash
mix test
mix test --cover
mix check
```

`mix check` verifies formatting, compiles with warnings treated as errors, runs
Credo in strict mode, executes the complete test suite, and enforces test
coverage.

The test suite does not call Open-Meteo. The weather provider implements a
behaviour and is replaced with deterministic test clients. Tests cover:

- concurrent execution of all three city requests;
- averaging and one-decimal rounding;
- use of only the first six temperatures;
- malformed and insufficient provider data;
- provider and HTTP error handling;
- terminal formatting and JSON endpoints.

## Design

`WeatherForecast` coordinates the work with
`Task.Supervisor.async_stream_nolink/4`, preserving the city order while running
all requests concurrently. The supervised, unlinked tasks keep a provider crash
from crashing the caller. `OpenMeteoClient` contains the external API details,
`Average` owns the calculation, and `Router` is a thin Plug/Bandit adapter over
the same core service used by the terminal command.

The HTTP server is disabled by default so it cannot interfere with the required
terminal command (for example, when port 4000 is already occupied). Setting
`START_SERVER=true` enables only the optional Postman interface.

## Live API

The API is deployed as a container-backed Vercel Function:

- [`GET /api/weather`](https://weather-forecast-elixir.vercel.app/api/weather)
- [`GET /health`](https://weather-forecast-elixir.vercel.app/health)

The repository's multi-stage production `Dockerfile` builds a self-contained
Elixir release and runs it as an unprivileged user. `vercel.json` points the
container service at that same image definition, avoiding platform-specific
application code. Pushes to `main` deploy automatically only after the GitHub
Actions formatting, compilation, lint, test, coverage, and production-image
checks pass.

To validate the production image locally:

```bash
docker build -t weather-forecast-elixir .
docker run --rm -p 4000:4000 -e PORT=4000 weather-forecast-elixir
```

Then open `http://localhost:4000/api/weather`.

Weather data is provided by [Open-Meteo](https://open-meteo.com/).
