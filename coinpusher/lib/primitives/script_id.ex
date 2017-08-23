defmodule CoinPusher.ScriptID do
  alias CoinPusher.Hash160

  def of(input) when byte_size(input) == 20 do
    input
  end

  def of(script) do
    Hash160.of(script)
  end
end
