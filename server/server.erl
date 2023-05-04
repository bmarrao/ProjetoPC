-module(server).
-export([escreverArquivo/2,
    acharOnline/2,
    lerArquivo/1,
    loop/3,
    create_account/2,
    close_account/ 2,
    login/2,
    start/2,
    server/2,
    stop/0,
    logout/1,
    online/0 ]).

%start(Port) -> register(?MODULE, spawn(fun() -> loop(Port,Port) end)).
%Precisamos ler de um arquivo e guardar numa estrutura quando for iniciado , por isso
%Adicionar mais um input a o inicializador do servidor que aceita uma string q é o nome de um arquivo
%Precisamos adicionar mensagens q o servidor recebe do cliente com a localização para sabermos se "matou" o inimigo, se ganhou 
%Algum bonus , etc ..
acharOnline(Map,Nivel)-> [User ||{User,{_,Nivel,_,true,false}} <- maps:to_list(Map)].

lerArquivo(String)->
    {ok, S} = file:read_file(String),
    Usuarios = string:tokens(binary_to_list(S), "\n"),
    lerArquivo(Usuarios,#{}).

lerArquivo([],Map)-> Map;

lerArquivo([H|T],Map)->
    [User,Pass,Nivel,Vitorias]= string:tokens(H,";"),
    lerArquivo(T,Map#{User=> {Pass,Nivel,Vitorias,false}}).

escreverArquivo(Map,File)->
    {ok, S} = file:open(File, [write]),
    maps:fold(
	fun(User, {Pass,Nivel,Vitorias,Status}, ok) ->
		io:format(S, "~s~n", [User++";"++Pass++";"++Nivel ++ ";"++Vitorias])
	end, ok, Map).
    

start(Port,File) -> spawn(fun() -> server(Port,File) end).
stop() -> ?MODULE ! stop.


server(Port,File) -> 
    {ok, LSock} = gen_tcp:listen(Port, [binary, {packet, line}]),
    Map = lerArquivo(file),
    register(?MODULE, spawn(fun() -> loop(LSock,Map,File) end )).
rpc(Request) -> 
    ?MODULE ! {Request,self()},
    receive {Res,?MODULE} -> Res end.

create_account(User,Pass) -> rpc({create_account,User,Pass}).
close_account(User,Pass) -> rpc({close_account,User,Pass}).
login(User,Pass) -> rpc({login,User,Pass}).
logout(User) -> rpc({logout,User}).
online() -> rpc({online}).

handle({create_account,User,Pass},Map) ->
    case maps:find(User,Map) of
        error ->
            {ok,Map#{User=> {Pass,0,0,false}}};
        _ ->
            {user_exists,Map}
   
    end;
handle({close_account,User,Pass},Map) ->
    case maps:find(User,Map) of
        {ok,{Pass,_,_,_}} ->
            {ok,maps:remove(Map,User)};     
         _ -> 
            {invalid,Map}
    end;
handle({login,User,Pass},Map) ->
    case maps:find(User,Map) of
        {ok,{Pass,Nivel,Vitorias,false}} -> 
            
            {ok,maps:update(User, {Pass,Nivel,Vitorias,true}, Map)};
        _ ->
            
            {invalid,Map}
    end;
handle({logout,User},Map) ->
    case maps:find(User,Map) of
        {ok,{Pass,Nivel,Vitorias,true}} ->
            {ok,maps:update(User,{Pass,Nivel,Vitorias,false},Map)};
        _ ->
            {ok,Map}
    end;
handle({online},Map) ->
    Res = [User ||{User,{_,_,_true}} <- maps:to_list(Map)],
    {Res,Map}.

loop(Lsock, Map,File) ->
    receive 
        {Req, From} ->
            {Resp,NextMap} = handle(Req,Map),
            From ! {Resp,?MODULE},
            loop(Lsock ,NextMap,File);
        stop-> 
            escreverArquivo(Map,File) end.