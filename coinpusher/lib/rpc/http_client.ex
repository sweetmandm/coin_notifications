defmodule CoinPusher.RPC.HTTPClient do
  require Poison

  @type json :: nil | true | false | float | integer | String.t | [] | %{optional(String.t) => json}
  @type method :: String.t
  @type params :: [json] | %{optional(String.t) => json}
  @type id :: String.t | integer

  @spec call(String.t, method, params, any, atom) :: {:ok, any} | {:error, any}
  def call(url, method, params, headers \\ [], http_method \\ :post) do
    {:ok, payload} = serialized_request(method, params, 0)
    response = :hackney.request(http_method, url, headers, payload, [])
    with(
      {:ok, 200, _headers, body_ref} = response,
      {:ok, body} = :hackney.body(body_ref)
    ) do
      deserialize_response(body)
    else
      {:ok, status_code, headers, body_ref} ->
        {:error, {:request_failed, status_code, headers, :hackney.body(body_ref)}}
      {:ok, status_code, headers} ->
        {:error, {:request_failed, status_code, headers}}
      {:error, reason} ->
        {:error, reason}
    end
  end

  def serialized_request(method, params, id) do
    payload = request_payload(method, params, id)
    Poison.encode(payload)
  end

  def request_payload(method, params, id)
  when is_binary(method) and (is_list(params) or is_map(params)) and (is_number(id) or is_binary(id)) do
    %{
      "method": method,
      "params": params,
      "id": id
    }
  end

  def deserialize_response(body) do
    Poison.decode(body)
  end
end
