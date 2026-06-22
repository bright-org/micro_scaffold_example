defmodule MicroScaffoldExample.AtomVM do
  @moduledoc """
  AtomVM 起動エントリポイント。

  `mix.exs` の `atomvm: [start: MicroScaffoldExample.AtomVM]` から `start/0` が呼ばれる。
  AtomVM には `persistent_term` がないため、`MicroPhoenix.Registry` を使わず
  ルータ関数を直接参照する HTTP ループをここで回す。

  DB や Req を使うパスは AtomVM 向けにここで分岐する（`/index3.html` のみ）。
  `/index2.html` は通常の Router → Controller → Items → Repo.AtomVM を通す。
  """

  alias MicroPhoenix.Request

  @port 8080

  def start do
    {:ok, sock} =
      :gen_tcp.listen(@port, [:binary, {:active, false}, {:reuseaddr, true}, {:packet, :raw}])

    IO.puts("AtomVM HTTP Server listening on http://localhost:#{@port}/")
    accept_loop(sock)
  end

  defp accept_loop(listen_sock) do
    case :gen_tcp.accept(listen_sock) do
      {:ok, client} ->
        spawn(fn -> handle_client(client) end)
        accept_loop(listen_sock)

      {:error, _reason} ->
        accept_loop(listen_sock)
    end
  end

  defp handle_client(socket) do
    MicroScaffoldExample.Repo.mark_atomvm_repo()

    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        response =
          data
          |> MicroPhoenix.Request.parse()
          |> route()
          |> MicroPhoenix.Response.build()

        :gen_tcp.send(socket, response)
        :gen_tcp.close(socket)

      {:error, _} ->
        :gen_tcp.close(socket)
    end
  end

  defp route(%Request{method: :get, path: "/index3.html"}) do
    {:ok, 503, "text/plain", "index3 is not available on AtomVM"}
  end

  defp route(req) do
    MicroScaffoldExampleWeb.Router.route(req)
  end
end
