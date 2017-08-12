require IEx

defmodule CoinPusher.RawTransaction do
  def parse(data) do
    IO.inspect data
    IEx.pry
    {:ok, data}
  end
end
