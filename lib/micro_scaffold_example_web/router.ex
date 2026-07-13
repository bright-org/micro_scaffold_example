defmodule MicroScaffoldExampleWeb.Router do
  alias MicroPhoenix.Request

  @router_status 0xE7101132
  @router_get_enter 0xE7101133
  @router_controller_returned 0xE7101134
  @router_not_found 0xE7101135
  @router_method_not_allowed 0xE7101136

  def route(%Request{method: :get, path: "/api/status"}) do
    mark(@router_status)
    body = ~s({"status":"ok","vm":"AtomVM","version":"0.1.0"})
    {:ok, 200, "application/json", body}
  end

  def route(%Request{method: :get} = req) do
    mark(@router_get_enter)

    case MicroScaffoldExampleWeb.Controller.get(req) do
      {:ok, status, content_type, body} ->
        mark(@router_controller_returned)
        {:ok, status, content_type, body}

      :not_found ->
        mark(@router_not_found)
        MicroPhoenix.Static.get_error_page(404)

    end
  end

  def route(_request) do
    mark(@router_method_not_allowed)
    MicroPhoenix.Static.get_error_page(405)
  end

  defp mark(code) do
    try do
      apply(:fpga_net, :mark, [code])
    rescue
      _ -> :ok
    catch
      _, _ -> :ok
    end

    :ok
  end
end
