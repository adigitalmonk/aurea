# Aurea

Aurea is a Plug that enables the "strangler fig" design pattern.

The purpose of this pattern is to slowly replace functionality in one system with a new system.

You can read more here: <https://learn.microsoft.com/en-us/azure/architecture/patterns/strangler-fig>

The plug will proxy requests to another host, allowing you to place a Phoenix app in front of
another application, slowly replacing routes in the old system with the new system.

In your Phoenix app's routes, add a `forward` route.
Likely, you'd want it to be the last route so that that other routes will "fall back" to it.

```elixir
  scope "/", MyAppWeb do
    pipe_through :browser

    get "/page", PageController, :index
  end

  scope "/" do
    forward "/", Aurea,
      upstream_base: "http://localhost:8000"
  end
```

Aurea uses the incoming request to build a new request to the given `upstream_base`.
 Aurea does not currently support streaming requests.

Scenario:
- The server is running on `http://localhost:4000`
- The upstream is set to `http://localhost:8000`
- A request is received to the unknown route `/api/user` from a client.
- Aurea picks up the forwarded request
- Aurea builds a new request:
  - The query params from the old request are added the new one
  - The "Source IP" is added to the headers as `x-source-ip`
  - The "Host" is added to the headers as `x-source-host`
  - The combined headers are added to the new request.
  - The request body is copied to the new request.
- The request is sent to `http://localhost:8000/api/user`
- The response from the upstream host is used to build the final response
  - The headers from the original request are set on the new reqeuest
  - The status code and response body are set on the response
- Client receives the final response.

## Install

```elixir
def deps do
  [
    # ...
    {:aurea, github: "adigitalmonk/aurea", branch: "master"}
    # ...
  ]
end
```
