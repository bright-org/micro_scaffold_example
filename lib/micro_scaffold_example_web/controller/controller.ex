defmodule MicroScaffoldExampleWeb.Controller do
  @index2_enter 0xE7101151
  @index2_items_loaded 0xE7101152
  @index2_items_rendered 0xE7101153
  @index2_template_rendered 0xE7101154
  @index3_force_gen_tcp 0xE7101160
  @index3_enter 0xE7101161
  @index3_req_start 0xE7101162
  @index3_req_ok 0xE7101163
  @index3_body_ready 0xE7101164
  @index3_template_rendered 0xE7101165
  @index3_transport_error 0xE7101166
  @index3_req_error 0xE710116E
  @index3_req_exception 0xE710116F

  @index3_url Application.compile_env(
                :micro_scaffold_example,
                :index3_url,
                "http://192.168.1.17:8000/index3.html"
              )

  @index_html_original """
  <!DOCTYPE html>
  <html lang="ja">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AtomVM HTTP Server</title>
    <style>
      body { font-family: sans-serif; max-width: 600px; margin: 40px auto; padding: 0 20px; }
      h1 { color: #333; }
      .badge { display: inline-block; background: #6c4f9e; color: white;
               padding: 4px 10px; border-radius: 4px; font-size: 0.85em; }
      pre { background: #f4f4f4; padding: 12px; border-radius: 4px; }
    </style>
  </head>
  <body>
    <h1>AtomVM HTTP Server <span class="badge">Elixir</span></h1>
    <p>AtomVM上で動くElixir製HTTPサーバーのデモページです。</p>
    <h2>REST API テスト</h2>
    <button onclick="fetchStatus()">GET /api/status</button>
    <pre id="result">ボタンを押してAPIを呼び出す...</pre>
    <script>
      async function fetchStatus() {
        const el = document.getElementById('result');
        try {
          const res = await fetch('/api/status');
          const data = await res.json();
          el.textContent = JSON.stringify(data, null, 2);
        } catch (e) {
          el.textContent = 'Error: ' + e.message;
        }
      }
    </script>
  </body>
  </html>
  """

  @index_html "Hello from AtomVM\n"

  @index2_html """
  <!DOCTYPE html>
  <html lang="ja">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AtomVM HTTP Server</title>
    <style>
      body { font-family: sans-serif; max-width: 600px; margin: 40px auto; padding: 0 20px; }
      h1 { color: #333; }
      .badge { display: inline-block; background: #6c4f9e; color: white;
               padding: 4px 10px; border-radius: 4px; font-size: 0.85em; }
      pre { background: #f4f4f4; padding: 12px; border-radius: 4px; }
    </style>
  </head>
  <body>
    <h1>AtomVM HTTP Server <span class="badge">Elixir</span></h1>
    <h2>Items</h2>
    <ul>
      <%= @items %>
    </ul>
  </body>
  </html>
  """

  def original_index_html, do: @index_html_original

  def index(conn), do: Template.render(conn, @index_html)

  def index2(conn) do
    mark(@index2_enter)
    items = MicroScaffoldExample.Items.list_items()
    mark(@index2_items_loaded)
    item_html = render_items(items, "")
    mark(@index2_items_rendered)
    response = Template.render(conn, @index2_html, %{items: item_html})
    mark(@index2_template_rendered)
    response
  end

  defp render_items([], acc), do: acc

  defp render_items([item | rest], acc) do
    render_items(rest, acc <> "<li>" <> item.name <> "</li>")
  end

  def index3(conn) do
    mark(@index3_enter)
    index3_upstream(conn)
  end

  defp index3_upstream(conn) do
    mark(@index3_force_gen_tcp)
    mark(@index3_req_start)

    case Req.get_gen_tcp(@index3_url) do
      {:ok, %Req.Response{} = resp} ->
        mark(@index3_req_ok)
        html = response_body_to_binary(resp.body)
        mark(@index3_body_ready)
        response = Template.render(conn, html)
        mark(@index3_template_rendered)
        response

      {:error, %Req.TransportError{} = error} ->
        mark(@index3_transport_error)
        upstream_error(transport_error_label(error.reason))

      {:error, _reason} ->
        mark(@index3_req_error)
        upstream_error("req error\n")
    end
  end

  defp response_body_to_binary(body) when is_binary(body), do: body
  defp response_body_to_binary(body) when is_list(body), do: :erlang.iolist_to_binary(body)
  defp response_body_to_binary(_body), do: ""

  defp transport_error_label(:timeout), do: "transport timeout\n"
  defp transport_error_label(:econnrefused), do: "transport refused\n"
  defp transport_error_label(:closed), do: "transport closed\n"
  defp transport_error_label(:gen_tcp_connect_exception), do: "transport gen_tcp connect exception\n"
  defp transport_error_label(:gen_tcp_packet_exception), do: "transport gen_tcp packet exception\n"
  defp transport_error_label(:gen_tcp_send_exception), do: "transport gen_tcp send exception\n"
  defp transport_error_label(:gen_tcp_recv_exception), do: "transport gen_tcp recv exception\n"
  defp transport_error_label(:gen_tcp_exception), do: "transport gen_tcp exception\n"
  defp transport_error_label({:ex_tcp, _reason}), do: "transport ex_tcp\n"
  defp transport_error_label(_reason), do: "transport error\n"

  defp upstream_error(message), do: {:ok, 502, "text/plain", message}

  def get(conn) when conn.path in ["/", "/index.html"] do
    index(conn)
  end

  def get(conn) when conn.path in ["/index2.html"] do
    index2(conn)
  end

  def get(conn) when conn.path in ["/index3.html"] do
    index3(conn)
  end

  def get(_conn), do: :not_found

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
