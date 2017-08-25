# https://en.bitcoin.it/wiki/Protocol_documentation#tx
defmodule CoinPusher.RawTransaction do
  alias CoinPusher.{VarInt, TxIn, TxOut}
  use Bitwise

  defstruct [:version, :tx_in, :tx_out, :lock_time]

  def parse(data) do
    <<version :: signed-integer-little-32, rest :: binary >> = data
    tx = parse(version, rest)
    {:ok, tx}
  end

  defp parse(version = 2, <<0x00, flags :: 8, data :: binary>>) do
    if flags == 0x00, do: :error, else: parse(version, flags, data)
  end

  defp parse(version = 2, data) do
    flags = 0x00
    parse(version, flags, data)
  end

  defp parse(version = 2, flags, data) do
    {:ok, tx_in_count, data} = VarInt.parse(data)
    {:ok, tx_in_list, data} = parse_list(tx_in_count, data, &TxIn.parse/1)
    {:ok, tx_out_count, data} = VarInt.parse(data)
    {:ok, tx_out_list, data} = parse_list(tx_out_count, data, &TxOut.parse/1)
    {:ok, flags, witnesses, data} = parse_witness_flag(flags, tx_in_count, data)
    tx_in_list =
      case Enum.empty?(witnesses) do
        true -> tx_in_list
        false -> add_witnesses_to_tx_in(tx_in_list, witnesses)
      end
    unless flags == 0, do: :error
    <<lock_time :: unsigned-integer-32>> = data
    %CoinPusher.RawTransaction{
      version: version,
      tx_in: tx_in_list,
      tx_out: tx_out_list,
      lock_time: lock_time
    }
  end

  defp parse_witness_flag(flags, tx_in_count, data) when band(flags, 1) == 1 do
    {:ok, witnesses , data} = parse_witness_program(tx_in_count, data)
    {:ok, bxor(flags, 1), witnesses, data}
  end

  defp parse_witness_flag(0x00, _, data) do
    {:ok, 0x00, [], data}
  end

  defp parse_witness_program(witness_count, data) do
    parse_list(witness_count, data, fn(data) ->
      {:ok, stack_item_count, data} = VarInt.parse(data)
      parse_list(stack_item_count, data, fn(data) ->
        {:ok, size, data} = VarInt.parse(data)
        <<program :: binary-size(size), rest :: binary>> = data
        {:ok, program, rest}
      end)
    end)
  end

  defp add_witnesses_to_tx_in(tx_in_list, witnesses_list, result \\ [])

  defp add_witnesses_to_tx_in([], [], result) do
    result
  end

  defp add_witnesses_to_tx_in(tx_in_list, witnesses_list, result) do
    [tx_in_head | tx_in_tail] = tx_in_list
    [witnesses_head | witnesses_tail] = witnesses_list
    result = if Enum.empty?(result) do
      [%{tx_in_head | witnesses: witnesses_head}]
    else
      [result | %{tx_in_head | witnesses: witnesses_head}]
    end
    add_witnesses_to_tx_in(tx_in_tail, witnesses_tail, result)
  end

  defp parse_list(list \\ [], index \\ 0, count, data, func)

  defp parse_list(list, max, max, data, _func) do
    {:ok, list, data}
  end

  defp parse_list(list, index, count, data, func) do
    {:ok, item, data} = func.(data)
    parse_list(list ++ [item], index + 1, count, data, func)
  end

  def is_coinbase?(raw_transaction) do
    first_tx_in = raw_transaction.tx_in |> Enum.at(0)
    first_tx_in |> TxIn.is_coinbase?
  end
end
