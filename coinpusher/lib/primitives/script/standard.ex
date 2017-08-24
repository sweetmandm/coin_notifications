defmodule CoinPusher.StandardTx do
  alias CoinPusher.{PubKey, ScriptID, Script}
  use CoinPusher.OPCODES

  @type tx_type :: :tx_pubkey
                 | :tx_pubkeyhash
                 | :tx_multisig
                 | :tx_null_data
                 | :tx_nonstandard
                 | :tx_scripthash

  @type witness_type :: :tx_witness_v0_keyhash
                      | :tx_witness_v0_scripthash

  @templates [
    # Standard tx, sender provides pubkey, receiver adds signature
    [:tx_pubkey, <<@op_pubkey, @op_checksig>>],
    # Bitcoin address tx, sender provides hash of pubkey, receiver provides signature and pubkey
    [:tx_pubkeyhash, <<@op_dup, @op_hash160, @op_pubkeyhash, @op_equalverify, @op_checksig>>],
    # Sender provides N pubkeys, receivers provides M signatures
    [:tx_multisig, <<@op_smallinteger, @op_pubkeys, @op_smallinteger, @op_checkmultisig>>]
  ]

  @spec extract_destinations(binary) :: {:ok, tx_type, list(binary), integer} | {:error, atom}
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
        case extract_destination(type, solutions) do
          {:ok, address} -> {:ok, type, [address], 1}
          :error -> {:ok, type, [], 1}
        end
    end
  end

  @spec extract_destination(binary) :: {:ok, binary} | :error
  def extract_destination(script_pub_key) do
    {:ok, type, solutions} = solver(script_pub_key)
    address = extract_destination(type, solutions)
    {:ok, type, address}
  end

  @spec extract_destination(atom, list) :: {:ok, binary} | :error
  defp extract_destination(type, solutions) do
    case type do
      :tx_pubkey ->
        {:ok, destinations_for(solutions) |> Enum.at(0)}
      :tx_pubkeyhash ->
        {:ok, solutions |> Enum.at(0)}
      :tx_scripthash ->
        solution = solutions |> Enum.at(0)
        {:ok, ScriptID.of(solution)}
      :tx_nonstandard ->
        :error
      _ ->
        :error
    end
  end

  @spec destinations_for(list(binary)) :: list(binary)
  defp destinations_for(solutions) do
    solutions
    |> Enum.filter(&PubKey.is_valid?/1)
    |> Enum.map(&PubKey.get_id/1)
  end

  @spec destinations_for(list(binary)) :: boolean
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

  @spec get_witness_program(binary) :: {:ok, witness_type, list(binary)}
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

  @spec solver(binary) :: {:ok, tx_type | witness_type, list(binary)}
  def solver(pub_key) do
    cond do
      Script.is_pay_to_script_hash(pub_key) ->
        <<_head :: binary-2, hash_bytes :: binary-20, _rest :: binary>> = pub_key
        {:ok, :tx_scripthash, [hash_bytes]}
      Script.is_prunable(pub_key) ->
        {:ok, :tx_null_data, []}
      is_witness_program?(pub_key) ->
        get_witness_program(pub_key)
      true ->
        check_templates(pub_key)
    end
  end

  @spec solve_template(binary, binary, list(binary)) :: {:ok, list(binary)} | :no_match
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
    {:ok, template_op} = Script.get_op(template_script)
    {:ok, script_op} = Script.get_op(script)
    cond do
      template_op.opcode == @op_pubkeys ->
        {:ok, remaining_script, pubkeys} = consume_pubkey_opcodes(script_op.remainder)
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
        :no_match
    end
  end

  @spec check_templates(list(binary), binary, list(binary) | :no_match) :: {:ok, tx_type, list(binary)}
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

  @spec consume_pubkey_opcodes(binary, list(binary)) :: {:ok, binary, list(binary)}
  def consume_pubkey_opcodes(script, solutions \\ []) do
    result = Script.get_op(script)
    case result do
      {:ok, {_, data, _} = op} when byte_size(data) in 33..65 ->
        consume_pubkey_opcodes(op.remainder, solutions ++ [data])
      _ ->
        {:ok, script, solutions}
    end
  end
end
