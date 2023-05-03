-module(server).
-export([escreverArquivo/2,
    lerArquivo/1,
    loop/1,
    create_account/2,
    close_account/ 2,
    login/2,
    logout/1,
    online/0 ]).

%start(Port) -> register(?MODULE, spawn(fun() -> loop(Port,Port) end)).
%Precisamos ler de um arquivo e guardar numa estrutura quando for iniciado , por isso
%Adicionar mais um input a o inicializador do servidor que aceita uma string q é o nome de um arquivo
%Precisamos adicionar mensagens q o servidor recebe do cliente com a localização para sabermos se "matou" o inimigo, se ganhou 
%Algum bonus , etc ..
%Criar , remover , fazer login está parcialmente feito

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
    


%start(Port,file)->
 %   {ok,Map} = lerArquivo(file),
  %  register(?MODULE,spawn(fun()->loop(Port,Map) end)).

stop(loop) -> loop ! stop.

invoke (Request) ->
    ?MODULE ! {Request,self()},
    receive {Res,?MODULE} -> Res end .
    
    
    
rpc(Request) -> 
    ?MODULE ! {Request,self()},
    receive {Res,?MODULE} -> Res end.

create_account(Usr,Pass) -> rpc({create_account,Usr,Pass}).
close_account(Usr,Pass) -> rpc({close_account,Usr,Pass}).
login(Usr,Pass) -> rpc({login,Usr,Pass}).
logout(Usr) -> rpc({logout,Usr}).
online() -> rpc({online}).

handle({create_account,User,Pass},Map) ->
    case maps:find(User,Map) of
        error ->
            {ok,Map#{User=> {Pass,false}}};
        _ ->
            {user_exists,Map}
   
    end;
handle({close_account,User,Pass},Map) ->
    case maps:find(User,Map) of
        {ok,{Pass,_}} ->
            {ok,maps:remove(Map,User)};     
         _ -> 
            {invalid,Map}
    end;
handle({login,User,Pass},Map) ->
    case maps:find(User,Map) of
        {ok,{Pass,false}} -> 
            
            {ok,maps:update(User, {Pass,true}, Map)};
        _ ->
            
            {invalid,Map}
    end;
handle({logout,User},Map) ->
    case maps:find(User,Map) of
        {ok,{P,true}} ->
            {ok,maps:update(User,{P,false},Map)};
        _ ->
            {ok,Map}
    end;
handle({online},Map) ->
    Res = [User ||{User,{_,true}} <- maps:to_list(Map)],
    {Res,Map}.


loop(Map) ->
    receive {Req, From} ->
        {Resp,NextMap} = handle(Req,Map),
        From ! {Resp,?MODULE},
        loop(NextMap)
    end.