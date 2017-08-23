defmodule CoinPusher.PubKey do
  alias CoinPusher.ScriptID

  def get_id(pub_key) do
    ScriptID.of(pub_key)
  end

  def is_valid?(pub_key) do
    byte_size(pub_key) > 0
  end
end
