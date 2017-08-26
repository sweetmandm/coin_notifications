defmodule CoinPusher.Contact do
  require Logger
  alias CoinPusher.Twilio

  defstruct [:phone_number]

  @spec notify(%__MODULE__{}, String.t) :: any
  def notify(contact, message) do
    Logger.debug "Notification | #{contact.phone_number}: #{message}"
    Twilio.sms(contact.phone_number, message)
  end
end
