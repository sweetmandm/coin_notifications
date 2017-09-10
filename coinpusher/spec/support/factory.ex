defmodule CoinPusher.Factory do
  use ExMachina
  use CoinPusher.BlockchainFactory
  use CoinPusher.BlockFactory
  use CoinPusher.BlockDataFactory
  use CoinPusher.TransactionDataFactory
  use CoinPusher.TransactionFactory
end
