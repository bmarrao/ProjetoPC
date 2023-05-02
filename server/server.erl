-module(login_manager).
-export([start/0,
    loop/1,
    create_account/2,
    close_account/ 2,
    login/2,
    logout/1,
    online/0 ]).

%start(Port) -> spawn(fun() -> server(Port) end).
start()->
    register(?MODULE,spawn(fun()->loop(#{}) end)).



invoke (Request) ->
    ?MODULE ! {Request,self()},
    receive {Res,?MODULE} -> Res end .
    
    
    
    
create_account(User, Pass) -> invoke({create_account,User,Pass}).

close_account(User, Pass) ->invoke({close_account,User,Pass}).

login (User, Pass) -> invoke({login,User,Pass}).

logout (User) -> invoke({logout,User}).

online()-> invoke ({logout}).


loop(Map)->
    receive {Request, From}->
        {Res,NextState} = handle (Request,Map),
        From !{Res,?MODULE},
        loop(NextState)
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
            {ok,loop(map:remove(user,Map))};
        _ ->                
            {invalid,loop(Map)}
            
    end;

handle({login,User,Pass},Map)->
    case maps:find(User,Map) of
        {ok,{Pass,_}}->
            {ok,loop(map:update(user,{Pass,true},Map))};
        _ ->                
            {invalid,loop(Map)}
            
    end;


handle({logout,User},Map)->
    case maps:find(User,Map) of
        {ok,{Pass,_}}->
            {ok,loop(map:update(user,{Pass,false},Map))};
        _ ->                
            {invalid,loop(Map)}
            
    end;

handle({online},Map)->
    Pred = fun(Pass,{Pass,Status}) -> Status == 0 end,
    %res = [ || ... <- maps:to_list(Map)],
    MapFiltrado = maps:filter(Pred,Map),
    {maps:keys(MapFiltrado)}.

