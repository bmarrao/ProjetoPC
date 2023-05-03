-module(login_manager).
-export([start/2,
    server/1,
    create_account/2,
    close_account/ 2,
    login/2,
    logout/1,
    online/0 ]).

%start(Port) -> register(?MODULE, spawn(fun() -> server(Port,Port) end)).
%Precisamos ler de um arquivo e guardar numa estrutura quando for iniciado , por isso
%Adicionar mais um input a o inicializador do servidor que aceita uma string q é o nome de um arquivo
%Precisamos adicionar mensagens q o servidor recebe do cliente com a localização para sabermos se "matou" o inimigo, se ganhou 
%Algum bonus , etc ..
%Criar , remover , fazer login está parcialmente feito
start(Port,file)->
    {ok,Map} = lerArquivo(file),
    register(?MODULE,spawn(fun()->server(Port,Map) end)).

stop(Server) -> Server ! stop.

invoke (Request) ->
    ?MODULE ! {Request,self()},
    receive {Res,?MODULE} -> Res end .
    
    
    
    
create_account(User, Pass) -> invoke({create_account,User,Pass}).

close_account(User, Pass) ->invoke({close_account,User,Pass}).

login (User, Pass) -> invoke({login,User,Pass}).

logout (User) -> invoke({logout,User}).

online()-> invoke ({logout}).

server(Port,Map)->
    {ok, LSock} = gen_tcp:listen(Port, [binary, {packet, line}, {reuseaddr, true}])
    receive {Request, From}->
        {Res,NextState} = handle (Request,Map),
        From !{Res,?MODULE},
        server(Port,NextState)
    end .

handle({create_account,User,Pass},Map)->
    case maps:find(User,Map) of
        error ->
            {ok, Map#{user => {Pass,false}}};
        _ ->
            {user_exists,Map}
    end;

handle({close_account,User,Pass},Map)->
    case maps:find(User,Map) of
        {ok,{Pass,_}}->
            {ok,server(Port,map:remove(user,Map))};
        _ ->                
            {invalid,server(Port,Map)}
            
    end;

handle({login,User,Pass},Map)->
    case maps:find(User,Map) of
        {ok,{Pass,_}}->
            {ok,server(Port,map:update(user,{Pass,true},Map))};
        _ ->                
            {invalid,server(Port,Map)}
            
    end;


handle({logout,User},Map)->
    case maps:find(User,Map) of
        {ok,{Pass,_}}->
            {ok,server(Port,map:update(user,{Pass,false},Map))};
        _ ->                
            {invalid,server(Port,Map)}
            
    end;

handle({online},Map)->
    Pred = fun(Pass,{Pass,Status}) -> Status == 0 end,
    %res = [ || ... <- maps:to_list(Map)],
    MapFiltrado = maps:filter(Pred,Map),
    {maps:keys(MapFiltrado)}.

