defmodule CoinPusher.ZMQClient do
  def main do
    {:ok, socket} = :chumak.socket(:sub)
    subscribe(socket)
    {:ok, _pid} = :chumak.connect(socket, :tcp, zmq_address(), zmq_port())
    loop(socket)
  end

  defp zmq_address do
    to_charlist(Application.get_env(:coinpusher, :zmq_address))
  end

  defp zmq_port do
    Application.get_env(:coinpusher, :zmq_port)
  end

  defp subscribe(socket) do
    :chumak.subscribe(socket, 'hashblock')
    :chumak.subscribe(socket, 'hashtx')
    :chumak.subscribe(socket, 'rawblock')
    :chumak.subscribe(socket, 'rawtx')
  end

  defp loop(socket) do
    IO.puts "waiting"
    {:ok, data} = :chumak.recv_multipart(socket)
    IO.inspect data
    loop(socket)
  end
end
