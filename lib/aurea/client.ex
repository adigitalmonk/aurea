defmodule Aurea.Client do
  @type method :: :get | :post | :put | :patch | :delet | :options | :head

  @callback request(
              method,
              # upstream_url,
              URI.t(),
              # proxied_headers,
              [{String.t(), String.t()}],
              # proxied_body
              binary() | nil
            ) :: {:ok, Map.t()}

  # TODO: Make the HTTP client configurable
  def request(method, upstream_url, headers, body) do
    Finch.build(method, upstream_url, headers, body)
    |> Finch.request(AureaFinch)
  end
end
