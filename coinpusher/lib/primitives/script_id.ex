defmodule CoinPusher.ScriptID do
  alias CoinPusher.Hash160

  def of(input) do
    Hash160.of(input)
  end
end
