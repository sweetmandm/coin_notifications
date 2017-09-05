defmodule CoinPusher.LinkedBlock do
  alias CoinPusher.RawBlock
  use Agent

  defstruct [:previous, :block]

  @type node_link :: pid | nil

  @spec start_link(node_link, %RawBlock{}) :: {:ok, pid}
  def start_link(previous, block) do
    Agent.start_link(fn ->
      %__MODULE__{previous: previous, block: block}
    end)
  end

  @spec block(pid) :: %RawBlock{}
  def block(agent) do
    Agent.get(agent, fn(struct) -> struct.block end)
  end

  @spec previous(pid) :: node_link
  def previous(agent) do
    Agent.get(agent, fn(struct) -> struct.previous end)
  end

  @spec set_previous(pid, node_link) :: :ok
  def set_previous(agent, previous_pid) do
    Agent.update(agent, fn(struct) -> %__MODULE__{struct | previous: previous_pid} end)
  end
end
