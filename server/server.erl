-module(server).

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

start(Port,File) -> 
    register(?MODULE, spawn(fun() -> server(Port,File) end)).

    
stop() -> ?MODULE ! stop.


server(Port,File) ->
    {ok, LSock} = gen_tcp:listen(Port, [{packet, line}, {reuseaddr, true}]),
    Map = lerArquivo(file),
    RM = spawn(fun() -> rm(#{},Map) end),
    spawn(fun() -> acceptor(LSock, RM) end),
    receive stop -> escreverArquivo(Map,File) end. 


acceptor(LSock, RM) ->
    {ok, Sock} = gen_tcp:accept(LSock),
    spawn(fun() -> acceptor(LSock,RM) end),
    user(Sock, RM).


user(Sock ,RM) ->
    receive
        {line, Data} ->
            gen_tcp:send(Sock, Data),
            user(Sock, RM);
        {tcp, _, Data} ->
            RM ! {mensagem, Data},
            user(Sock,RM)
        %{tcp_closed, _} ->
         %   Room ! {leave, self()};
        %{tcp_error, _, _} ->
         %   Room ! {leave, self()}
end.

rm(Rooms,Users) ->
    receive
        {mensagem,Data}->
             case Data of
                "users:" ++ Rest ->
                    NewUsers = usersManager(Users,Rest),
                    NewRooms = Rooms ;
                _ ->
                    NewUsers = Users,
                    NewRooms = Rooms,
                    rm(Rooms,Users)
            end    
    end,
    rm(NewRooms,NewUsers).

usersManager(Users,Rest)->
    case Rest of 
        "create_account " ++ User ++ " " ++ Pass ->
            {_, NewUsers} -> create_account(User,Pass,Map);
        "close_account " ++ User ++ " " ++ Pass ->
            {_, NewUsers} -> close_account(User,Pass,Map);
        "login " ++ User ++ " " ++ Pass ->
            {_, NewUsers} -> login (User,Pass,Map);
        "logout " ++ User ->
            {_, NewUsers} -> logout (User,Pass,Map)
    end,
    NewUsers.





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
            
            {ok,maps:update(User, {Pass,Nivel,Vitorias,true}, Map)};
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

