defmodule CoinPusher.Contact do
  require Logger
  alias CoinPusher.Twilio

  @type phone_number :: String.t

  defstruct [:phone_number]

  def notify(contact, message) do
    Logger.debug "Notification | #{contact.phone_number}: #{message}"
    Twilio.sms(contact.phone_number, message)
  end
end
