defmodule MicroScaffoldExample.Application do
  use Application

  @impl true
  def start(_type, _args) do
    MicroPhoenix.Registry.register_router(&MicroScaffoldExampleWeb.Router.route/1)

    children = []

    Supervisor.start_link(children, strategy: :one_for_one, name: MicroScaffoldExample.Supervisor)
  end
end
