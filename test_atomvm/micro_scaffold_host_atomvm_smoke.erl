-module(micro_scaffold_host_atomvm_smoke).

-export([start/0, root_response_test/0, index2_response_test/0, index3_req_response_test/0]).

start() ->
    case eunit:test(?MODULE, [exact_execution]) of
        ok ->
            erlang:display({micro_scaffold_host_atomvm_smoke, ok}),
            ok;
        Error ->
            erlang:error({micro_scaffold_host_atomvm_smoke_failed, Error})
    end.

root_response_test() ->
    Expected =
        <<"HTTP/1.1 200 OK\r\n"
          "Content-Type: text/html; charset=utf-8\r\n"
          "Content-Length: 18\r\n"
          "Connection: close\r\n"
          "\r\n"
          "Hello from AtomVM\n">>,
    Response = response_for(<<"/">>),
    assert_equal(root_response, Expected, Response).

index2_response_test() ->
    Body =
        <<"<!DOCTYPE html>\n"
          "<html lang=\"ja\">\n"
          "<head>\n"
          "  <meta charset=\"UTF-8\">\n"
          "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n"
          "  <title>AtomVM HTTP Server</title>\n"
          "  <style>\n"
          "    body { font-family: sans-serif; max-width: 600px; margin: 40px auto; padding: 0 20px; }\n"
          "    h1 { color: #333; }\n"
          "    .badge { display: inline-block; background: #6c4f9e; color: white;\n"
          "             padding: 4px 10px; border-radius: 4px; font-size: 0.85em; }\n"
          "    pre { background: #f4f4f4; padding: 12px; border-radius: 4px; }\n"
          "  </style>\n"
          "</head>\n"
          "<body>\n"
          "  <h1>AtomVM HTTP Server <span class=\"badge\">Elixir</span></h1>\n"
          "  <h2>Items</h2>\n"
          "  <ul>\n"
          "    <li>Apple</li><li>Banana</li><li>Cherry</li><li>Date</li><li>Elderberry</li>\n"
          "  </ul>\n"
          "</body>\n"
          "</html>\n">>,
    Expected =
        <<"HTTP/1.1 200 OK\r\n"
          "Content-Type: text/html; charset=utf-8\r\n"
          "Content-Length: ", (integer_to_binary(byte_size(Body)))/binary, "\r\n"
          "Connection: close\r\n"
          "\r\n",
          Body/binary>>,
    Response = response_for(<<"/index2.html">>),
    assert_equal(index2_response, Expected, Response).

index3_req_response_test() ->
    Body = <<"Index3 from Req upstream\n">>,
    Server = start_upstream_server(Body),
    Expected =
        <<"HTTP/1.1 200 OK\r\n"
          "Content-Type: text/html; charset=utf-8\r\n"
          "Content-Length: ", (integer_to_binary(byte_size(Body)))/binary, "\r\n"
          "Connection: close\r\n"
          "\r\n",
          Body/binary>>,
    Response = response_for(<<"/index3.html">>),
    wait_upstream_done(Server),
    assert_equal(index3_req_response, Expected, Response).

response_for(Path) ->
    'Elixir.MicroScaffoldExample.Repo':mark_atomvm_repo(),
    Request = 'Elixir.MicroPhoenix.Request':parse(request_bytes(Path)),
    Routed = route(Request),
    'Elixir.MicroPhoenix.Response':build(Routed).

request_bytes(Path) ->
    <<"GET ", Path/binary, " HTTP/1.1\r\n"
      "Host: 192.168.1.200:5000\r\n"
      "User-Agent: host-atomvm-smoke\r\n"
      "Accept: */*\r\n"
      "\r\n">>.

route(Request) ->
    case 'Elixir.MicroPhoenix.Registry':fetch_router() of
        {ok, {Module, Function}} ->
            apply(Module, Function, [Request]);
        {ok, RouteFun} when is_function(RouteFun, 1) ->
            RouteFun(Request);
        Other ->
            erlang:error({bad_router, Other})
    end.

assert_equal(_Label, Expected, Expected) ->
    ok;
assert_equal(Label, Expected, Actual) ->
    erlang:error({assert_equal_failed, Label, {expected, Expected}, {actual, Actual}}).

start_upstream_server(Body) ->
    Parent = self(),
    Pid =
        spawn(fun() ->
            {ok, Listen} =
                gen_tcp:listen(18080, [
                    binary,
                    {active, false},
                    {packet, raw},
                    {reuseaddr, true},
                    {ip, {127, 0, 0, 1}}
                ]),
            Parent ! {self(), ready},
            {ok, Socket} = gen_tcp:accept(Listen),
            _ = gen_tcp:recv(Socket, 0),
            Response =
                <<"HTTP/1.1 200 OK\r\n"
                  "Content-Type: text/html\r\n"
                  "Content-Length: ", (integer_to_binary(byte_size(Body)))/binary, "\r\n"
                  "Connection: close\r\n"
                  "\r\n",
                  Body/binary>>,
            ok = gen_tcp:send(Socket, Response),
            ok = gen_tcp:close(Socket),
            ok = gen_tcp:close(Listen),
            Parent ! {self(), done}
        end),
    receive
        {Pid, ready} -> Pid
    after 1000 ->
        erlang:error(upstream_server_start_timeout)
    end.

wait_upstream_done(Pid) ->
    receive
        {Pid, done} -> ok
    after 1000 ->
        erlang:error(upstream_server_done_timeout)
    end.
