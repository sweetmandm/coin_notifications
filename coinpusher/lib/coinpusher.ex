defmodule CoinPusher.ZMQClient do
  def main do
    IO.puts "starting"
    {:ok, socket} = :chumak.socket(:sub)
    :chumak.subscribe(socket, 'hashblock')
    :chumak.subscribe(socket, 'hashtx')
    :chumak.subscribe(socket, 'rawblock')
    :chumak.subscribe(socket, 'rawtx')
    case :chumak.bind(socket, :tcp, '127.0.0.1', 5555) do
      {:ok, _bind_pid} ->
        IO.puts "connected socket"
      {:error, reason} ->
        IO.puts "connection failed"
        IO.inspect reason
      other ->
        IO.inspect other
    end
    loop(socket)
  end

  def loop(socket) do
    IO.puts "waiting"
    {:ok, data} = :chumak.recv_multipart(socket)
    IO.inspect data
    loop(socket)
  end
end
