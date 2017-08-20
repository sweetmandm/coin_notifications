# hasher for Bitcoin's 160-bit hash (SHA-256 + RIPEMD-160).
defmodule CoinPusher.Hash160 do
  def of(input) do
    :crypto.hash(:ripemd160, :crypto.hash(:sha256, input))
  end
end
