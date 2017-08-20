defmodule Base58 do
  @psz_base58 ~c(123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz)

  def encode(input) do
    int_value = :binary.decode_unsigned(input)
    result = encode(int_value, [])
    leftpad(result, '1', leading_zeros(input))
  end

  def encode_check(input) do
    sha = :crypto.hash(:sha256, :crypto.hash(:sha256, input))
    <<checksum :: binary-4, _ :: binary>> = sha
    encode(<<input :: binary, checksum :: binary>>)
  end

  defp encode(0, result), do: result

  defp encode(int, result) do
    encode(div(int, 58), [Enum.at(@psz_base58, rem(int, 58)) | result])
  end

  defp leading_zeros(input, count \\ 0)

  defp leading_zeros(<<0, rest :: binary>>, count) do
    leading_zeros(rest, count + 1)
  end

  defp leading_zeros(rest, count) when is_binary(rest) do
    count
  end

  defp leftpad(result, _, pad) when pad < 1, do: result

  defp leftpad(result, value, pad) do
    leftpad([value | result], value, pad - 1)
  end
end
