defmodule CoinPusher.Script do
  use CoinPusher.OPCODES

  def get_op(data) do
    case data do
      <<size :: unsigned-integer-8, data :: binary-size(size), rest :: binary>> when size < @op_pushdata1 ->
        {:ok, %OP{opcode: size, data: data, remainder: rest}}
      <<@op_pushdata1, size :: unsigned-integer-8, data :: binary-size(size), rest :: binary>> ->
        {:ok, %OP{opcode: @op_pushdata1, data: data, remainder: rest}}
      <<@op_pushdata2, size :: unsigned-integer-16, data :: binary-size(size), rest :: binary>> ->
        {:ok, %OP{opcode: @op_pushdata2, data: data, remainder: rest}}
      <<@op_pushdata4, size :: unsigned-integer-32, data :: binary-size(size), rest :: binary>> ->
        {:ok, %OP{opcode: @op_pushdata4, data: data, remainder: rest}}
      <<opcode :: unsigned-integer-8, rest :: binary>> ->
        {:ok, %OP{opcode: opcode, data: <<>>, remainder: rest}}
      <<>> ->
        {:notok, :empty}
      _ ->
        :error
    end
  end

  def get_all_opcodes(ops \\ [], data)

  def get_all_opcodes(ops, <<>>) do
    ops
  end

  def get_all_opcodes(ops, data) do
    {:ok, %OP{opcode: opcode, data: _, remainder: remainder}} = get_op(data)
    get_all_opcodes(ops ++ [opcode], remainder)
  end

  def is_pay_to_script_hash(pub_key) do
    byte_size(pub_key) == 23 and
    binary_part(pub_key, 0, 2) == <<@op_hash160, 0x14>> and
    binary_part(pub_key, 22, 1) == <<@op_equal>>
  end

  def is_prunable(pub_key) do
    byte_size(pub_key) >= 1 and
    binary_part(pub_key, 0, 1) == @op_return and
    is_push_only(binary_part(pub_key, 1, byte_size(pub_key) - 1))
  end

  def is_push_only(script) do
    ops = get_all_opcodes(script)
    ops |> Enum.filter(fn(op) -> op > @op_16 end) == []
  end
end
