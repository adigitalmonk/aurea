defmodule Aurea do
  import Plug.Conn
  require Logger

  defp extract_query_params(%{query_params: qp}) do
    URI.encode_query(qp)
  end

  def extract_request(conn, upstream_base, query_params) do
    inbound_body = conn.assigns[:raw_body]

    upstream =
      upstream_base
      |> URI.merge(conn.request_path)
      |> to_string()
      |> then(fn url ->
        if query_params,
          do: url <> "?" <> query_params,
          else: url
      end)

    source_ip =
      conn.remote_ip
      |> Tuple.to_list()
      |> Enum.join(".")

    proxied_headers = [
      {"x-source-ip", source_ip},
      {"x-source-host", conn.host}
      | conn.req_headers
    ]

    {conn.method, inbound_body, upstream, proxied_headers}
  end

  def proxy_request(client, {method, body, upstream_url, proxied_headers}) do
    client.request(method, upstream_url, proxied_headers, body)
    |> case do
      {:ok, _response} = payload ->
        payload

      {:error, error} = err ->
        Logger.error(error)
        err
    end
  end

  defp put_outbound_headers(conn, %{headers: headers}) do
    Enum.reduce(headers, conn, fn {header, value}, acc ->
      Plug.Conn.put_resp_header(acc, header, value)
    end)
  end

  def init(opts) do
    %{
      http_client: Keyword.get(opts, :aurea_client, Aurea.Client),
      upstream_base: Keyword.get(opts, :upstream_base)
    }
  end

  def call(conn, %{upstream_base: upstream_base, http_client: client}) do
    with query_params <- extract_query_params(conn),
         request_data <- extract_request(conn, upstream_base, query_params),
         {:ok, response} <- proxy_request(client, request_data) do
      conn
      |> put_outbound_headers(response)
      |> send_resp(response.status, response.body)
    else
      {:error, error} ->
        Logger.error(error)
        send_resp(conn, 500, "Could not forward request")
    end
  end
end
