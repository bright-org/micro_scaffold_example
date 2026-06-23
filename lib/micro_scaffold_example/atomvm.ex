defmodule MicroScaffoldExample.AtomVM do
  @moduledoc """
  AtomVM entrypoint.

  `start/0` is invoked from `atomvm: [start: MicroScaffoldExample.AtomVM]` in `mix.exs`.
  AtomVM has no `persistent_term`, so this module runs an HTTP loop that calls the router
  function directly instead of using `MicroPhoenix.Registry`.

  DB paths branch to `Repo.AtomVM` on AtomVM.
  """

  @port 8080

  def start do
    {:ok, sock} =
      :gen_tcp.listen(@port, [:binary, {:active, false}, {:reuseaddr, true}, {:packet, :raw}])

    IO.puts("AtomVM HTTP Server listening on http://localhost:#{@port}/")
    IO.puts("Seeded #{MicroScaffoldExample.Repo.AtomVM.seed_count()} items for /index2.html")
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

  defp route(req) do
    MicroScaffoldExampleWeb.Router.route(req)
  end
end
