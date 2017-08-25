defmodule CoinPusher.Contact do
  require Logger

  @type phone_number :: String.t

  defstruct [:phone_number]

  def notify(contact, message) do
    Logger.debug "Notification | #{contact.phone_number}: #{message}"
  end
end
