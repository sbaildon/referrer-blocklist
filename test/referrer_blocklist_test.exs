defmodule ReferrerBlocklistTest do
  use ExUnit.Case

  setup do
    filepath = System.tmp_dir!() |> Path.join("test-blocklist.txt")
    File.write!(filepath, "pre-existing.blocklist\n")

    on_exit(fn -> File.rm!(filepath) end)

    {:ok, opts: [http_client: ReferrerBlocklistTest.HTTPClient, filepath: filepath]}
  end

  test "reads blocklist from file on init, when update not completed", %{opts: opts} do
    ReferrerBlocklist.start_link(opts)

    assert ReferrerBlocklist.is_spammer?("pre-existing.blocklist")
  end

  test "init updates list once the request is completed", %{opts: opts} do
    ReferrerBlocklist.start_link(opts)
    Process.sleep(1000)

    assert ReferrerBlocklist.is_spammer?("0-0.fr")
  end

  test "uses default list from file when request fails on init", %{opts: opts} do
    ReferrerBlocklist.start_link([
      {:resource_url, "https://no-list-here.com/request/will/fail.txt"} | opts
    ])

    assert ReferrerBlocklist.is_spammer?("pre-existing.blocklist")
  end
end
