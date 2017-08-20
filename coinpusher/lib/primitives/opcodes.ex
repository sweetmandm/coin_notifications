defmodule CoinPusher.OPCODES do
  defmacro __using__(_) do
    quote do
      import CoinPusher.OPCODES

      defmodule OP do
        defstruct [:opcode, :data, :remainder]
      end

      # push value
      @op_0 0x00
      @op_false @op_0
      @op_pushdata1 0x4c
      @op_pushdata2 0x4d
      @op_pushdata4 0x4e
      @op_1negate 0x4f
      @op_reserved 0x50
      @op_1 0x51
      @op_true @op_1
      @op_2 0x52
      @op_3 0x53
      @op_4 0x54
      @op_5 0x55
      @op_6 0x56
      @op_7 0x57
      @op_8 0x58
      @op_9 0x59
      @op_10 0x5a
      @op_11 0x5b
      @op_12 0x5c
      @op_13 0x5d
      @op_14 0x5e
      @op_15 0x5f
      @op_16 0x60

      # control
      @op_nop 0x61
      @op_ver 0x62
      @op_if 0x63
      @op_notif 0x64
      @op_verif 0x65
      @op_vernotif 0x66
      @op_else 0x67
      @op_endif 0x68
      @op_verify 0x69
      @op_return 0x6a

      # stack ops
      @op_toaltsTACK 0x6b
      @op_fromalTSTACK 0x6c
      @op_2drop 0x6d
      @op_2dup 0x6e
      @op_3dup 0x6f
      @op_2over 0x70
      @op_2rot 0x71
      @op_2swap 0x72
      @op_ifdup 0x73
      @op_depth 0x74
      @op_drop 0x75
      @op_dup 0x76
      @op_nip 0x77
      @op_over 0x78
      @op_pick 0x79
      @op_roll 0x7a
      @op_rot 0x7b
      @op_swap 0x7c
      @op_tuck 0x7d

      # splice ops
      @op_cat 0x7e
      @op_substr 0x7f
      @op_left 0x80
      @op_right 0x81
      @op_size 0x82

      # bit logic
      @op_invert 0x83
      @op_and 0x84
      @op_or 0x85
      @op_xor 0x86
      @op_equal 0x87
      @op_equalverify 0x88
      @op_reserved1 0x89
      @op_reserved2 0x8a

      # numeric
      @op_1add 0x8b
      @op_1sub 0x8c
      @op_2mul 0x8d
      @op_2div 0x8e
      @op_negate 0x8f
      @op_abs 0x90
      @op_not 0x91
      @op_0notequal 0x92

      @op_add 0x93
      @op_sub 0x94
      @op_mul 0x95
      @op_div 0x96
      @op_mod 0x97
      @op_lshift 0x98
      @op_rshift 0x99

      @op_booland 0x9a
      @op_boolor 0x9b
      @op_numequal 0x9c
      @op_numequalverify 0x9d
      @op_numnotequal 0x9e
      @op_lessthan 0x9f
      @op_greaterthan 0xa0
      @op_lessthanoreQUAL 0xa1
      @op_greaterthanOREQUAL 0xa2
      @op_min 0xa3
      @op_max 0xa4

      @op_within 0xa5

      # crypto
      @op_ripemd160 0xa6
      @op_sha1 0xa7
      @op_sha256 0xa8
      @op_hash160 0xa9
      @op_hash256 0xaa
      @op_codeseparator 0xab
      @op_checksig 0xac
      @op_checksigverify 0xad
      @op_checkmultisig 0xae
      @op_checkmultisigverify 0xaf

      # expansion
      @op_nop1 0xb0
      @op_checklocktimeverify 0xb1
      @op_nop2 @op_checklocktimeverify
      @op_checksequenceverify 0xb2
      @op_nop3 @op_checksequenceverify
      @op_nop4 0xb3
      @op_nop5 0xb4
      @op_nop6 0xb5
      @op_nop7 0xb6
      @op_nop8 0xb7
      @op_nop9 0xb8
      @op_nop10 0xb9

      # template matching params
      @op_smallinteger 0xfa
      @op_pubkeys 0xfb
      @op_pubkeyhash 0xfd
      @op_pubkey 0xfe

      @op_invalidopcode 0xff
    end
  end

  defmacro can_decode_op_n(opcode) do
    quote do
      unquote(opcode) == @op_0 or unquote(opcode) in @op_1..@op_16
    end
  end

  defmacro decode_op_n(opcode) do
    quote do
      cond do
        unquote(opcode) == @op_0 -> 0
        unquote(opcode) in @op_1..@op_16 -> unquote(opcode) - (@op_1 - 1)
      end
    end
  end
end
