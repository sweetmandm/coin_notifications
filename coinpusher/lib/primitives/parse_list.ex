defmodule CoinPusher.ParseList do

  @type func :: (binary -> {:ok, any, binary})

  @spec parse_list(list, integer, integer, binary, func) :: {:ok, list, binary}
  def parse_list(list \\ [], index \\ 0, count, data, func)

  def parse_list(list, max, max, data, _func) do
    {:ok, list, data}
  end

  def parse_list(list, index, count, data, func) do
    {:ok, item, data} = func.(data)
    parse_list(list ++ [item], index + 1, count, data, func)
  end
end
