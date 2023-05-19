-module(server).
-export([start/2, stop/0,lerArquivo/1,escreverArquivo/2,acharOnline/2,listagemVitorias/1]).

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
            io:format("Dou print \n"),
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

generateObject()->
    {rand:uniform(3),rand:unifrom(),rand:uniform()}.
 
gameRoom(User1,User2,RM) ->
    receive
        {start,Tref}->
            Object =generateObject(),
            {_,From,_,_,_,_,_,_, _,_} = User1,
            {_,From1,_,_,_,_,_,_, _,_} = User2,
            From ! {objeto,Object},
            From1 ! {objeto,Object},
            gameRoom(User1,User2,Tref,RM)
    
    end.

overtime(Users1,Users2,RM) ->
    io:format("Entramos em tempo extra\n"),
    receive
        {playerOut,Ganhou,Perdeu} ->
                RM ! {matchWinner,Ganhou},
                RM ! {matchLoser,Perdeu};
        newObject ->
            Object =generateObject,
            timer:send_after(10000  ,self(),newObject),
            Users1 ! {objeto,Object},
            Users2 ! {objeto,Object}
    end.

gameRoom(Users1,Users2,Tref,RM) ->
    timer:send_after(10000  ,self(),newObject),
    {User1,From,Pontos,Posx,Posy,Nivel,Aceleracao,Velocidade, Ang,Boost} = Users1,
    {User2,From1,Pontos1,Posx1,Posy1,Nivel1,Aceleracao1,Velocidade1, Ang1,Boost1} = Users2,

     receive
        {line, Data} ->
            io:format("received ~p ~n", [Data]),
            gameRoom(Users1,Users2,Tref,RM);
        {enter, _} ->
            io:format("user entered ~n", []),
            gameRoom(Users1,Users2,Tref,RM);
        {playerOut,Ganhou,Perdeu}->
            RM ! {matchWinner,Ganhou},
            RM ! {matchLoser,Perdeu},
            erlang:cancel(Tref);
        gameOver ->
            io:format("Acabou o jogo ~n", []),
            if 
            Pontos == Pontos1 ->
                overtime(Users1,Users2,RM)
            end,
            case Pontos > Pontos1 of
                true ->
                    RM ! {matchWinner,User1},
                    RM ! {matchLoser,User2};
                false ->
                    RM ! {matchWinner,User2},
                    RM ! {matchLoser,User1}
            end;
        newObject ->
            Object =generateObject,
            timer:send_after(10000  ,self(),newObject),
            Users1 ! {objeto,Object},
            Users2 ! {objeto,Object},
            gameRoom(Users1,Users2,Tref,RM)
    end.

rm(Rooms,Users) ->
    io:format("Entrei no rm\n"),

    receive
        {mensagem,Data,From}->
            NewUsers = usersManager(Users,Data,self(),From),
            NewRooms = Rooms ;
        {matchWinner,User,Nivel}->
            {Pass,Nivel,Vitorias,true,From} = maps:get(User,Users),
            if 
                Vitorias +1 == 2 * Nivel ->
                    NewNivel = Nivel +1;
                true ->
                    NewNivel = Nivel
            end,
            NewUsers = maps:update(User, {Pass,NewNivel,Vitorias+1,true,From}, Users),
            NewRooms =Rooms ,
            findGame(Users,User,Nivel,self()),
            NewUsers = Users,
            NewRooms = Rooms ; 
        {matchLoser,User,Nivel}->
            findGame(Users,User,Nivel,self()),
            NewUsers = Users,
            NewRooms = Rooms ;
        {newMatch,User1,User2}->
            io:format("Encontrei Partida\n"),
            {Pass,Nivel,Vitorias,true,From} = maps:get(User1,Users),
            Aux = maps:update(User1,{Pass,Nivel,Vitorias,false,From},Users),
            {Pass1,Nivel1,Vitorias1,true,From1} = maps:get(User2,Users),
            NewUsers = maps:update(User1,{Pass1,Nivel1,Vitorias1,false,From1},Aux),
            NewRooms = Rooms ,
            {Pontos, Posx, Posy, Aceleracao, Velocidade,Ang,Boost} = {0,0,0,0,0,0,0},
            {Pontos1, Posx1, Posy1, Aceleracao1, Velocidade1,Ang1,Boost1} = {0,0,0,0,0,0,0},
            Room = spawn(fun()-> gameRoom([User1,From,Pontos,Posx,Posy,Nivel,Aceleracao,Velocidade, Ang,Boost],
                                        [User2,From1,Pontos1,Posx1,Posy1,Nivel1,Aceleracao1,Velocidade1, Ang1,Boost1],self()) end),
            Tref = timer:send_after(120000 ,Room,gameOver),
            Room ! {start,Tref},
            From ! {newGame, Room},
            From1 ! {newGame, Room};
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
            {_, NewUsers} = close_account(User,Pass,Users,From);
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
            {_, NewUsers} = logout (User,Users,From)
    end,
    NewUsers.


listagemVitorias(Users)->
    List = maps:to_list(Users),
    {lists:keysort(4, List)}.


create_account(User,Pass,Map,From) ->
     case maps:find(User,Map) of
        error ->
            %io:format("Dou print account \n"),
            From ! {line,"Users:sucessful\n"},    
            {ok,Map#{User=> {Pass,0,0,false,From}}};
        _ ->
            From ! {line,"Users:unsucessful\n"},    
            {user_exists,Map}
   
    end.

close_account(User,Pass,Map,From) ->
    case maps:find(User,Map) of
        {ok,{Pass,_,_,_,From}} ->
            From ! {line,"Users:sucessful\n"},
            {ok,maps:remove(Map,User)};
         _ -> 
            From ! {line, "Users:unsucessful\n"},
            {invalid,Map}
    end.

login(User,Pass,Map,From) -> 
    [NewPass] = string:tokens(Pass, "\n"),
    case maps:find(User,Map) of
        {ok,{NewPass,Nivel,Vitorias,false,_}} -> 
            From ! {line,"Users:sucessful\n"},
            {ok,maps:update(User, {NewPass,Nivel,Vitorias,true,From}, Map),Nivel};       
        _ ->
            From ! {line,"Users:unsucessful\n"},
            {ok,Map}

    end.


logout(User,Map,From) -> 
    case maps:find(User,Map) of
        {ok,{Pass,Nivel,Vitorias,true,From}} ->
            From ! {line,"Users:sucessful\n"},
            {ok,maps:update(User,{Pass,Nivel,Vitorias,false,From},Map)};
        _ ->
            From ! {line,"Users:uncessful\n"},
            {ok,Map}
    end.


