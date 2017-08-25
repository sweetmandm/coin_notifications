defmodule CoinPusher.Twilio do
  @endpoint "https://api.twilio.com/2010-04-01/Accounts/"

  def sms(to, body, media \\ "") do
    payload = {:form, ["From": from(), "To": to, "Body": body, "Media": media]}
    response = :hackney.request(:post, url(), [], payload, options())
    with(
      {:ok, status, headers, body_ref} = response,
      {:ok, body} = :hackney.body(body_ref)
    ) do
      {:ok, _} = Poison.decode(body)
    end
  end

  defp options do
    [basic_auth: {sid(), token()}]
  end

  defp token do
    Application.get_env(:coinpusher, :twilio_token) |> to_charlist
  end

  defp sid do
    Application.get_env(:coinpusher, :twilio_sid) |> to_charlist
  end

  defp from do
    Application.get_env(:coinpusher, :twilio_from)
  end

  defp url do
    "#{@endpoint}#{sid()}/Messages.json"
  end
end
