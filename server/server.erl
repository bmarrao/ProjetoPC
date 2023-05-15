-module(server).
-export([start/2, stop/0,lerArquivo/1,escreverArquivo/2,acharOnline/2]).

%Precisamos adicionar mensagens q o servidor recebe do cliente com a localização para sabermos se "matou" o inimigo, se ganhou 
%Algum bonus , etc ..
acharOnline(Map,Nivel)-> [User ||{User,{_,Nivel,_,true,_}} <- maps:to_list(Map)].

findGame(Map, User,Nivel,RM)->
    io:format("Achar jogo\n"),
    Lista = acharOnline(Map,Nivel),
    io:format("~s~nTesteOla",[Lista]),
    Tamanho = length(Lista),
    if
        (Tamanho < 1) ->
            {false};
        true ->
            [H | T] = Lista ,
            if H == User ->
                RM ! {newMatch ,lists:nth(1, T),User};
            true ->
                RM ! {newMatch ,H,User}
            end
    end.
            

            



lerArquivo(String)->
    {ok, S} = file:read_file(String),
    Usuarios = string:tokens(binary_to_list(S), "\n"),
    lerArquivo(Usuarios,#{}).

lerArquivo([],Map)-> Map;

lerArquivo([H|T],Map)->
    [User,Pass,Nivel,Vitorias]= string:tokens(H,";"),
    lerArquivo(T,Map#{User=> {Pass,list_to_integer(Nivel),list_to_integer(Vitorias),false,0}}).

escreverArquivo(Map,File)->
    {ok, S} = file:open(File, [write]),
    maps:fold(
	fun(User, {Pass,Nivel,Vitorias,_,_}, ok) ->
		io:format(S, "~s~n", [(User++";"++Pass++";"++integer_to_list(Nivel)++";"++integer_to_list(Vitorias))])
	end, ok, Map).

start(Port,File) -> 
    register(?MODULE, spawn(fun() -> server(Port,File) end)).

    
stop() -> ?MODULE ! stop.


server(Port,File) ->

    {ok, LSock} = gen_tcp:listen(Port, [{packet, line}, {reuseaddr, true}]),

    Map = lerArquivo(File),

    RM = spawn(fun() -> rm(#{},Map) end),
    spawn(fun() -> acceptor(LSock, RM) end),
    receive 
        stop ->  
            RM ! stop ,
            receive
                {data,NewMap} ->
                    io:format("~p~n", [NewMap]),
                    escreverArquivo(NewMap,File) 
            end
    end.



acceptor(LSock, RM) ->
    io:format("Acceptor"),
    {ok, Sock} = gen_tcp:accept(LSock),
    spawn(fun() -> acceptor(LSock,RM) end),
    user(Sock, RM,RM).


user(Sock ,RM,Room) ->
    receive
        {line, Data} ->
            gen_tcp:send(Sock, Data),
            user(Sock, RM,Room);
        {tcp, _, Data} ->
            case Data of
                "users:" ++ Rest ->
                    io:format("Recebi algo\n"),
                    RM ! {mensagem, Rest,self()};
                _ ->
                    Room ! {line,Data}
                end, 
            user(Sock,RM,Room);
        {newGame,Game} ->
            Game ! {enter,self()},
            user(Sock,RM,Game);
        _ ->
            io:format("User saiu\n")

        %{tcp_closed, _} ->
         %    % Colocar pra ir offline
          %  io:format("User saiu\n");
        %{tcp_error, _, _} ->
            %Colocar pra ir offline
         %   io:format("User saiu\n")

end.


 
gameRoom(User1,User2) ->
    receive
        {line, Data} ->
            io:format("received ~p ~n", [Data]),
            gameRoom(User1,User2);
        {enter, Pid} ->
            io:format("user entered ~n", []),
            gameRoom(User1,User2);
        {gameOver, Pid} ->
            io:format("user left ~n", []),
            gameRoom(User1,User2)
        
end.

rm(Rooms,Users) ->
    io:format("Entrei no rm\n"),

    receive
        {mensagem,Data,From}->
            NewUsers = usersManager(Users,Data,self(),From),
            NewRooms = Rooms ;
        {newMatch,User1,User2}->
            io:format("Encontrei Partida\n"),
            {Pass1,Nivel1,Vitorias1,true,From1} = maps:get(User1,Users),
            Aux = maps:update(User1,{Pass1,Nivel1,Vitorias1,false,From1},Users),
            {Pass,Nivel,Vitorias,true,From} = maps:get(User2,Users),
            NewUsers = maps:update(User2,{Pass,Nivel,Vitorias,false,From},Aux),
            NewRooms = Rooms ,
            Room = spawn(fun()-> gameRoom([User1,Pass1,Nivel1,Vitorias1,From1],[User2,Pass,Nivel,Vitorias,From]) end),
            From1 ! {newGame, Room},
            From ! {newGame, Room};
            %Talvez encontre erro no futuro de ter q atualizar o status pra true quando acabar a partida
        stop ->
            NewUsers = Users,
            NewRooms = Rooms ,
            ?MODULE ! {data ,Users}
    end,
    rm(NewRooms,NewUsers).

usersManager(Users,String,RM,From)->
    io:format("Entrei no usersManager\n"),

    case String of 
        "create_account " ++ Rest ->
            io:format("Create ACcount\n"),
            [User,Pass] = string:tokens(Rest," "),
            NewPass = re:replace(Pass, "\n" , "", [global, {return, list}]),
            {_, NewUsers} = create_account(User,NewPass,Users,From);
        "close_account " ++ Rest ->
            io:format("Close Account\n"),
            [User,Pass] = string:tokens(Rest," "),
            {_, NewUsers} = close_account(User,Pass,Users);
        "login "  ++ Rest ->
            io:format("Login\n"),
            [User,Pass] = string:tokens(Rest," "),
            case login(User,Pass,Users,From) of
                {_, NewUsers,Nivel} ->
                    io:format("OIIIIIIIII\n"),
                    findGame(Users,User,Nivel,RM);
                {_,NewUsers} ->
                    io:format("Algo de errado\n"),
                    ok
            end;
        "logout " ++ User ->
            {_, NewUsers} = logout (User,Users)
    end,
    NewUsers.





create_account(User,Pass,Map,From) ->
     case maps:find(User,Map) of
        error ->
            {ok,Map#{User=> {Pass,0,0,false,From}}};
        _ ->
            {user_exists,Map}
   
    end.

close_account(User,Pass,Map) ->
    case maps:find(User,Map) of
        {ok,{Pass,_,_,_,_}} ->
            {ok,maps:remove(Map,User)};     
         _ -> 
            {invalid,Map}
    end.

login(User,Pass,Map,From) -> 
    [NewPass] = string:tokens(Pass, "\n"),
    case maps:find(User,Map) of
        {ok,{NewPass,Nivel,Vitorias,false,_}} -> 
            {ok,maps:update(User, {NewPass,Nivel,Vitorias,true,From}, Map),Nivel}
        %_ ->binary_to_list(S)
         %   {invalid,Map}
    end.


logout(User,Map) -> 
    case maps:find(User,Map) of
        {ok,{Pass,Nivel,Vitorias,true,From}} ->
            {ok,maps:update(User,{Pass,Nivel,Vitorias,false,From},Map)}
        %_ ->
        %    {ok,Map}
    end.


%handle({online},Map) ->
 %   Res = [User ||{User,{_,_,_true}} <- maps:to_list(Map)],
%    {Res,Map}.

