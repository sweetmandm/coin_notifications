defmodule CoinPusher.ScriptParser do
  alias CoinPusher.{OP, PubKey, ScriptID}
  use CoinPusher.OP

  @templates [
    # Standard tx, sender provides pubkey, receiver adds signature
    [:tx_pubkey, <<@op_pubkey, @op_checksig>>],
    # Bitcoin address tx, sender provides hash of pubkey, receiver provides signature and pubkey
    [tx_pubkeyhash: <<@op_dup, @op_hash160, @op_pubkeyhash, @op_equalverify, @op_checksig>>],
    # Sender provides N pubkeys, receivers provides M signatures
    [tx_multisig: <<@op_smallinteger, @op_pubkeys, @op_smallinteger, @op_checkmultisig>>]
  ]

  def extract_destinations(script_pub_key) do
    {:ok, type, solutions} = solver(script_pub_key)
    case type do
      :tx_null_data ->
        {:error, type}
      :tx_multisig ->
        [nRequired | solutions] = solutions
        destinations = destinations_for(solutions)
        {:ok, type, destinations, nRequired}
      _ ->
        address = extract_destination(type, solutions)
        {:ok, type, [address], 1}
    end
  end

  def extract_destination(script_pub_key) do
    {:ok, type, solutions} = solver(script_pub_key)
    address = extract_destination(type, solutions)
    {:ok, type, address}
  end

  defp extract_destination(type, solutions) do
    case type do
      :tx_pubkey ->
        destinations_for(solutions) |> Enum.at(0)
      :tx_pubkeyhash ->
        solution = solutions |> Enum.at(0)
        solution = <<solution :: unsigned-integer-160>>
        solution
      :tx_scripthash ->
        solution = solutions |> Enum.at(0)
        solution = <<solution :: unsigned-integer-160>>
        address = ScriptID.of(solution)
        address
      _ ->
        nil
    end
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

  defp destinations_for(solutions) do
    solutions
    |> Enum.filter(&PubKey.is_valid?/1)
    |> Enum.map(&PubKey.get_id/1)
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

  def is_witness_program?(pub_key) do
    opcode = binary_part(pub_key, 0, 1)
    cond do
      byte_size(pub_key) < 4 or byte_size(pub_key) > 42 ->
        false
      !can_decode_op_n(opcode) ->
        false
      byte_size(pub_key) == binary_part(pub_key, 1, 1) + 2 ->
        true
      true ->
        false
    end
  end

  def get_witness_program(pub_key) do
    opcode = binary_part(pub_key, 0, 1)
    version = decode_op_n(opcode)
    program = binary_part(pub_key, 2, byte_size(pub_key) - 2)
    program_size = byte_size(program)
    case {version, program_size} do
      {0, 20} ->
        {:ok, :tx_witness_v0_keyhash, [program]}
      {0, 32} ->
        {:ok, :tx_witness_v0_scripthash, [program]}
      _ ->
        :error
    end
  end

  def can_decode_op_n(opcode) do
    opcode == @op_0 or opcode in @op_1..@op_16
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
        <<_head :: binary-2, hash_bytes :: binary-20, _rest :: binary>> = pub_key
        {:ok, :tx_scripthash, [hash_bytes]}
      is_prunable(pub_key) ->
        {:ok, :tx_null_data, []}
      is_witness_program?(pub_key) ->
        get_witness_program(pub_key)
      true ->
        check_templates(pub_key)
    end
  end

  def solve_template(template_script, script, solutions \\ [])

  def solve_template(<<>>, <<>>, solutions) do
    # Successfully matched a template script.
    {:ok, solutions}
  end

  def solve_template(template_script, script, _) when <<>> in [template_script, script] do
    # One of the scripts is empty but the other is not - no match.
    :no_match
  end

  def solve_template(template_script, script, solutions) do
    {:ok, template_op} = get_op(template_script)
    {:ok, script_op} = get_op(script)
    script = script_op.data
    cond do
      template_op.opcode == @op_pubkeys ->
        {:ok, remaining_script, pubkeys} = consume_pubkey_opcodes(script)
        solve_template(template_op.remainder, remaining_script, solutions ++ pubkeys)
      template_op.opcode == @op_pubkey ->
        solution = if byte_size(script_op.data) in 33..65, do: [script_op.data], else: []
        solve_template(template_op.remainder, script_op.remainder, solutions ++ solution)
      template_op.opcode == @op_pubkeyhash ->
        hash = if byte_size(script_op.data) == 20, do: [script_op.data], else: []
        solve_template(template_op.remainder, script_op.remainder, solutions ++ hash)
      template_op.opcode == @op_smallinteger ->
        n = if can_decode_op_n(script_op.opcode), do: [decode_op_n(script_op.opcode)], else: []
        solve_template(template_op.remainder, script_op.remainder, solutions ++ n)
      template_op.opcode == script_op.opcode and template_op.data == script_op.data ->
        solve_template(template_op.remainder, script_op.remainder, solutions)
      true ->
        {:error, :tx_nonstandard}
    end
  end

  def check_templates(templates \\ @templates, script, solutions \\ :no_match)

  def check_templates([], _script, :no_match), do: {:ok, :tx_nonstandard, []}

  def check_templates(templates, script, :no_match) do
    [head | tail] = templates
    template_type = head |> Enum.at(0)
    template_script = head |> Enum.at(1)
    result = solve_template(template_script, script)
    case result do
      {:ok, solutions} ->
        {:ok, template_type, solutions}
      :no_match ->
        check_templates(tail, script, :no_match)
    end
  end

  def consume_pubkey_opcodes(script, solutions \\ []) do
    result = get_op(script)
    case result do
      {:ok, {_, data, _} = op} when byte_size(data) in 33..65 ->
        consume_pubkey_opcodes(op.remainder, solutions ++ [data])
      _ ->
        {:ok, script, solutions}
    end
  end
end
