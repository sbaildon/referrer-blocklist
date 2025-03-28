defmodule ReferrerBlocklist do
  use GenServer

  defp resource_url,
    do: "https://raw.githubusercontent.com/matomo-org/referrer-spam-list/master/spammers.txt"

  defp update_interval_milliseconds, do: to_timeout(week: 1)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    filepath = Keyword.get(opts, :filepath, blocklist_filepath())
    resource_url = Keyword.get(opts, :resource_url, resource_url())
    http_client = Keyword.fetch!(opts, :http_client)

    timer = Process.send_after(self(), {:update_list, resource_url}, 10)

    {:ok,
     %{timer: timer, http_client: http_client, blocklist: read_blocklist_from_file(filepath)}}
  end

  def is_spammer?(domain, pid \\ __MODULE__) do
    GenServer.call(pid, {:is_spammer, domain})
  end

  def handle_call({:is_spammer, domain}, _from, state) do
    is_spammer = MapSet.member?(state.blocklist, domain)
    {:reply, is_spammer, state}
  end

  def handle_info({:update_list, resource_url}, state) do
    %{http_client: http_client} = state
    updated_blocklist = attempt_blocklist_update(http_client, resource_url, state.blocklist)

    Process.cancel_timer(state[:timer])

    new_timer =
      Process.send_after(self(), {:update_list, resource_url}, update_interval_milliseconds())

    {:noreply, %{state | blocklist: updated_blocklist, timer: new_timer}}
  end

  defp read_blocklist_from_file(filepath) do
    File.read!(filepath)
    |> String.split("\n")
    |> MapSet.new()
  end

  defp attempt_blocklist_update(http_client, resource_url, current_blocklist) do
    case http_client.get(resource_url) do
      {:ok, %{status: 200, body: body}} ->
        String.split(body, "\n")
        |> MapSet.new()

      {:ok, _} ->
        current_blocklist

      {:error, _} ->
        current_blocklist
    end
  end

  defp blocklist_filepath() do
    Application.app_dir(:referrer_blocklist, "/priv/spammers.txt")
  end
end
