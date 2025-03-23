defmodule ReferrerBlocklist.HTTPClient do
  @type response :: %{
          status: pos_integer(),
          body: binary()
        }

  @callback get(url :: binary()) :: {:ok, response :: response()} | {:error, term()}
end
