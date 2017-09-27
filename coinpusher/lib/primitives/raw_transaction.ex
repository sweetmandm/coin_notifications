defmodule CoinPusher.RawTransaction do
  alias CoinPusher.{VarInt, TxIn, TxOut, TxId}
  import CoinPusher.ParseList
  use Bitwise
  require IEx

  defstruct [:id, :version, :tx_in, :tx_out, :lock_time]

  @spec parse(binary) :: {:ok, %__MODULE__{}, binary} | {:error, any}
  def parse(data) do
    <<version :: signed-little-32, rest :: binary >> = data
    parse(version, rest, data)
  end

  defp parse(version, <<0x00, flags :: 8, data :: binary>>, original) do
    if flags == 0x00 do
      {:error, "bad flags"}
    else
      parse(version, flags, data, original)
    end
  end

  defp parse(version, data, original) do
    flags = 0x00
    parse(version, flags, data, original)
  end

  defp parse(version, flags, data, original) do
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
    unless flags == 0, do: {:error, "unknown flag"}
    <<lock_time :: unsigned-little-32, rest :: binary>> = data
    size = byte_size(original) - byte_size(rest)
    raw = binary_part(original, 0, size)
    id = raw |> TxId.from_raw
    tx = %CoinPusher.RawTransaction{
      id: id,
      version: version,
      tx_in: tx_in_list,
      tx_out: tx_out_list,
      lock_time: lock_time
    }
    {:ok, tx, rest}
  end

  defp parse_witness_flag(flags, tx_in_count, data) when band(flags, 1) == 1 do
    {:ok, witnesses, data} = parse_witness_program(tx_in_count, data)
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
    result = result ++ [%{tx_in_head | witnesses: witnesses_head}]
    add_witnesses_to_tx_in(tx_in_tail, witnesses_tail, result)
  end

  def is_coinbase?(raw_transaction) do
    first_tx_in = raw_transaction.tx_in |> Enum.at(0)
    first_tx_in |> TxIn.is_coinbase?
  end
end
