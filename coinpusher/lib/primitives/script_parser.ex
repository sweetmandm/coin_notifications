defmodule CoinPusher.ScriptParser do
  alias CoinPusher.OP
  use CoinPusher.OP

  @templates %{
    # Standard tx, sender provides pubkey, receiver adds signature
    tx_pubkey: [@op_pubkey, @op_checksig],
    # Bitcoin address tx, sender provides hash of pubkey, receiver provides signature and pubkey
    tx_pubkeyhash: [@op_dup, @op_hash160, @op_pubkeyhash, @op_equalverify, @op_checksig],
    # Sender provides N pubkeys, receivers provides M signatures
    tx_multisig: [@op_smallinteger, @op_pubkeys, @op_smallinteger, @op_checkmultisig]
  }

  defmacro is_pay_to_script_hash(pub_key) do
    quote do
      byte_size(unquote(pub_key)) == 23 and
      binary_part(unquote(pub_key), 0, 2) == <<@op_hash160, 0x14>> and
      binary_part(unquote(pub_key), 22, 1) == <<@op_equal>>
    end
  end

  def is_prunable(pub_key) do
    byte_size(pub_key) >= 1 and
    binary_part(pub_key, 0, 1) == @op_return and
    is_push_only(binary_part(pub_key, 1, byte_size(pub_key) - 1))
  end

  def is_push_only(script) do
    ops = get_all_ops(script)
    {left, right} = Enum.split_while
  end

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
    end
  end

  def get_all_ops(ops \\ [], data)

  def get_all_ops(ops, data) do
    ops ++ [get_op(data)]
  end

  def get_all_ops(ops, <<>>) do
    ops
  end

  def is_witness_program(pub_key) do
    opcode = binary_part(pub_key, 0, 1)
    cond do
      byte_size(pub_key) < 4 or byte_size(pub_key) > 42 ->
        false
      opcode != @op_0 and (opcode < @op_1 || opcode > @op_16) ->
        false
      byte_size(pub_key) == binary_part(pub_key, 1, 1) + 2
        version = decode_op_n(opcode)
        program = binary_part(pub_key, 2, byte_size(pub_key) - 2)
        {:ok, version, program}
      true ->
        false
    end
  end

  def decode_op_n(opcode) do
    cond do
      opcode == @op_0 -> 0
      opcode in @op_1..@op_16 -> opcode - (@op_1 - 1)
    end
  end

  def solver(pub_key) do
    cond do
      is_pay_to_script_hash(pub_key) ->
        <<_head :: binary-size(2), hash_bytes :: binary-size(20), rest :: binary>> = pub_key
        {:ok, :tx_scripthash, [hash_bytes]}
      is_prunable(pub_key) ->
        {:ok, :tx_null_data, []}
      {:ok, version, program} = is_witness_program(pub_key) ->
        program_size = byte_size(program)
        case {version, program_size} do
          {0, 20} ->
            {:ok, :tx_witness_v0_keyhash, [program]}
          {0, 32} ->
            {:ok, :tx_witness_v0_scripthash, [program]}
        end
    end
  end

  def extract_destinations(script_pub_key) do
    {:ok, type, solutions} = solver(script_pub_key)
    case type do
      :tx_null_data -> {:error, type}
      :tx_multisig -> {:ok, type, solutions, 1}
      other -> {:ok, type, solutions, 1}
    end
  end

  def addresses_for(:tx_null_data, pub_key) do
    :error
  end

  def addresses_for(type = :tx_multisig, pub_key) do
    addresses = []
    {:ok, type, addresses}
  end

  def addresses_for(type, pub_key) do
    address = extract_destination(pub_key)
    {:ok, type, [address]}
  end

  def extract_destination(script_pub_key) do
    {:ok, type, solutions} = solver(script_pub_key)
  end

  def handle(:tx_pubkey, solutions) do
    pub_key = solutions |> Enum.at(0)
    pub_key |> PubKey.get_id
  end
end

defmodule PubKey do
  def get_id(pub_key) do
    "abc"
  end
end
