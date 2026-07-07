defmodule MicroScaffoldExample.Application do
  use Application

  def start do
    MicroScaffoldExample.Repo.mark_atomvm_repo()
    register_router()
    MicroPhoenix.start()
  end

  @impl true
  def start(_type, _args) do
    register_router()

    children = []

    Supervisor.start_link(children, strategy: :one_for_one, name: MicroScaffoldExample.Supervisor)
  end

  defp register_router do
    MicroPhoenix.Registry.register_router(&MicroScaffoldExampleWeb.Router.route/1)
  end
end
