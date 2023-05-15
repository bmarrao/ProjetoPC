-module(server).
-export([start/2, stop/0,lerArquivo/1,escreverArquivo/2]).

%Precisamos adicionar mensagens q o servidor recebe do cliente com a localização para sabermos se "matou" o inimigo, se ganhou 
%Algum bonus , etc ..
acharOnline(Map,Nivel)-> [User ||{User,{_,Nivel,_,true,false}} <- maps:to_list(Map)].

findGame(Map, User,Nivel,RM)->
    Lista = acharOnline(Map,Nivel),
    Tamanho = length(Lista),
    if
        (Tamanho == 1) ->
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
    lerArquivo(T,Map#{User=> {Pass,list_to_integer(Nivel),list_to_integer(Vitorias),false}}).

escreverArquivo(Map,File)->
    {ok, S} = file:open(File, [write]),
    maps:fold(
	fun(User, {Pass,Nivel,Vitorias,Status}, ok) ->
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
            io:format("Recebi algo "),
            Room = spawn(fun()-> room([]) end),
            user(Sock, RM,Room);
        {tcp, _, Data} ->
            RM ! {mensagem, Data},
            user(Sock,RM,Room);
        {entrarJogo,Game} ->
            Game ! {entrei,self()};
        _ ->
            io:format("User saiu\n")

        %{tcp_closed, _} ->
         %    % Colocar pra ir offline
          %  io:format("User saiu\n");
        %{tcp_error, _, _} ->
            %Colocar pra ir offline
         %   io:format("User saiu\n")

end.



rm(Rooms,Users) ->
    io:format("Entrei no rm"),

    receive
        {mensagem,Data}->
             case Data of
                "users:" ++ Rest ->
                    NewUsers = usersManager(Users,Rest,self()),
                    NewRooms = Rooms ;
                _ ->
                    NewUsers = Users,
                    NewRooms = Rooms        
            end   ; 
        {newMatch,User1,User2}->
            {Pass1,Nivel1,Vitorias1,false} = maps:get(User1,Users),
            Aux = maps:update(User1,{Pass1,Nivel1,Vitorias1,true},Users),
            {Pass,Nivel,Vitorias,false} = maps:get(User2,Users),
            NewUsers = maps:update(User2,{Pass,Nivel,Vitorias,true},Aux),
            NewRooms = Rooms ,
            Room = spawn(fun()-> room([]) end);
        
        stop ->
            NewUsers = Users,
            NewRooms = Rooms ,
            ?MODULE ! {data ,Users}
    end,
    rm(NewRooms,NewUsers).

usersManager(Users,String,RM)->
    io:format("Entrei no usersManager"),

    case String of 
        "create_account " ++ Rest ->
            io:format("Create ACcount"),
            [User,Pass] = string:tokens(Rest," "),
            NewPass = re:replace(Pass, "\n" , "", [global, {return, list}]),
            {_, NewUsers} = create_account(User,NewPass,Users);
        "close_account " ++ Rest ->
            [User,Pass] = string:tokens(Rest," "),
            {_, NewUsers} = close_account(User,Pass,Users);
        "login "  ++ Rest ->
            [User,Pass] = string:tokens(Rest," "),
            case login of
                {_, NewUsers,Nivel} ->
                    findGame(Users,User,Nivel,RM);
                {_,NewUsers} ->
                    ok
            end;
        "logout " ++ User ->
            {_, NewUsers} = logout (User,Users)
    end,
    NewUsers.

 
room(Pids) ->
    receive
    {enter, Pid} ->
        io:format("user entered ~n", []),
        room([Pid | Pids]);
    {line, Data} = Msg ->
        io:format("received ~p ~n", [Data]),
        [Pid ! Msg || Pid <- Pids],
        room(Pids);
    {leave, Pid} ->
        io:format("user left ~n", []),
        room(Pids -- [Pid])
end.



create_account(User,Pass,Map) ->
     case maps:find(User,Map) of
        error ->
            {ok,Map#{User=> {Pass,0,0,false}}};
        _ ->
            {user_exists,Map}
   
    end.

close_account(User,Pass,Map) ->
    case maps:find(User,Map) of
        {ok,{Pass,_,_,_}} ->
            {ok,maps:remove(Map,User)};     
         _ -> 
            {invalid,Map}
    end.

login(User,Pass,Map) -> 
    case maps:find(User,Map) of
        {ok,{Pass,Nivel,Vitorias,false}} -> 
            
            {ok,maps:update(User, {Pass,Nivel,Vitorias,true}, Map),Nivel};
        _ ->
            
            {invalid,Map}
    end.


logout(User,Map) -> 
    case maps:find(User,Map) of
        {ok,{Pass,Nivel,Vitorias,true}} ->
            {ok,maps:update(User,{Pass,Nivel,Vitorias,false},Map)};
        _ ->
            {ok,Map}
    end.


%handle({online},Map) ->
 %   Res = [User ||{User,{_,_,_true}} <- maps:to_list(Map)],
%    {Res,Map}.

