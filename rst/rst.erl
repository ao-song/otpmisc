
-module(rst).

-export([run/0]).

%%--------------------------------------------------------------------
run() ->
    %% init
    ssl:start(),

    ResponderPort = erlang:integer_to_list(get_free_port()),
    Pid = start_ocsp_responder(ResponderPort),

    ServerPort1_2 = erlang:integer_to_list(get_free_port()),
    Pid1_2 = start_tls_server(tls1_2, ResponderPort, ServerPort1_2),


    {ok, Sock} =
    ssl:connect(
        {127,0,0,1}, ServerPort1_2, [
            {cacertfile, "certs/client/cacerts.pem"},
            {certfile, "certs/client/cert.pem"},
            {keyfile, "certs/client/key.pem"}
        ] ++
        [{keepalive, true},
         {versions, ['tlsv1.2']},
         {log_level, debug}], 5000),
    ok = ssl:send(Sock, ok),
    ssl:close(Sock),



    %% destroy
    os:cmd(io_lib:format("kill -9 ~p", [Pid])),
    os:cmd(io_lib:format("kill -9 ~p", [Pid1_2])),
    ssl:stop().


%%--------------------------------------------------------------------
%% Intrernal functions -----------------------------------------------
%%--------------------------------------------------------------------
start_ocsp_responder(ResponderPort) ->

    Cmd =
    "openssl ocsp -index " ++ "certs/otpCA/index.txt" ++
    " -CA " ++ "certs/b.server/cacerts.pem" ++
    " -rsigner " ++ "certs/b.server/cert.pem" ++
    " -rkey " ++ "certs/b.server/key.pem" ++
    " -port " ++ ResponderPort,
    run_cmd(Cmd).

start_tls_server(Version, ResponderPort, ServerPort) ->

    Cmd =
    "openssl s_server -cert " ++ "certs/a.server/cert.pem" ++
    " -port " ++ ServerPort ++
    " -key " ++ "certs/a.server/key.pem" ++
    " -CAfile " ++ "certs/a.server/cacerts.pem" ++
    " -status_verbose " ++
    " -status_url " ++ "http://127.0.0.1:" ++ ResponderPort ++
    " -" ++ atom_to_list(Version),
    run_cmd(Cmd).

run_cmd(Cmd) ->
    {os_pid, Pid} = erlang:port_info(
        erlang:open_port({spawn, Cmd}, []), os_pid),
    Pid.

get_free_port() ->
    {ok, Listen} = gen_tcp:listen(0, [{reuseaddr, true}]),
    {ok, Port} = inet:port(Listen),
    ok = gen_tcp:close(Listen),
    Port.