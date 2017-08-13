# https://en.bitcoin.it/wiki/Protocol_documentation#Variable_length_integer
defmodule CoinPusher.VarInt do
  def parse(<<0xFF, value :: unsigned-integer-little-64, rest :: binary>>) do
    {:ok, value, rest}
  end

  def parse(<<0xFE, value :: unsigned-integer-little-32, rest :: binary>>) do
    {:ok, value, rest}
  end

  def parse(<<0xFD, value :: unsigned-integer-little-16, rest :: binary>>) do
    {:ok, value, rest}
  end

  def parse(<<value :: unsigned-integer-8, rest :: binary>>) do
    {:ok, value, rest}
  end

  def parse(_other), do: :error
end
