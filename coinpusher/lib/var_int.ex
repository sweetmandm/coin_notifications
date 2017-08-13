# https://en.bitcoin.it/wiki/Protocol_documentation#Variable_length_integer
defmodule CoinPusher.VarInt do
  def parse(data), do: parse_int(data)

  defp parse_int(<<0xFF, value :: unsigned-integer-little-64, rest :: binary>>) do
    {:ok, value, rest}
  end

  defp parse_int(<<0xFE, value :: unsigned-integer-little-32, rest :: binary>>) do
    {:ok, value, rest}
  end

  defp parse_int(<<0xFD, value :: unsigned-integer-little-16, rest :: binary>>) do
    {:ok, value, rest}
  end

  defp parse_int(<<value :: unsigned-integer-8, rest :: binary>>) do
    {:ok, value, rest}
  end

  defp parse_int(_other), do: :error
end
