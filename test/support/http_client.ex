defmodule ReferrerBlocklistTest.HTTPClient do
  @behaviour ReferrerBlocklist.HTTPClient

  def get(url) do
    Req.get(url)
  end
end
