defmodule CoinPusher.Factory do
  use ExMachina
  use CoinPusher.BlockFactory
  use CoinPusher.BlockDataFactory
  use CoinPusher.TransactionDataFactory
end
