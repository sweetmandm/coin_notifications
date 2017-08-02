defmodule CoinPusherTest do
  use ExUnit.Case
  doctest CoinPusher

  test "greets the world" do
    assert CoinPusher.hello() == :world
  end
end
