-module(server).
-export([start/2, stop/0,lerArquivo/1,escreverArquivo/2]).

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
		io:format(S, "~s~n", (User++";"++Pass++";"++integer_to_list(Nivel)++";"++integer_to_list(Vitorias)))
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
    user(Sock, RM).


user(Sock ,RM) ->
    receive
        {line, Data} ->
            gen_tcp:send(Sock, Data),
            io:format("Recebi algo "),
            user(Sock, RM);
        {tcp, _, Data} ->
            RM ! {mensagem, Data},
            user(Sock,RM);
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
                    NewUsers = usersManager(Users,Rest),
                    NewRooms = Rooms ;
                _ ->
                    NewUsers = Users,
                    NewRooms = Rooms        
            end   ; 
        stop ->
            NewUsers = Users,
            NewRooms = Rooms ,
            ?MODULE ! {data ,Users}
    end,
    rm(NewRooms,NewUsers).

usersManager(Users,String)->
    io:format("Entrei no usersManager"),

    case String of 
        "create_account " ++ Rest ->
            io:format("Create ACcount"),
            [User,Pass] = string:tokens(Rest," "),
            {_, NewUsers} = create_account(User,Pass,Users);
        "close_account " ++ Rest ->
            [User,Pass] = string:tokens(Rest," "),
            {_, NewUsers} = close_account(User,Pass,Users);
        "login "  ++ Rest ->
            [User,Pass] = string:tokens(Rest," "),
            {_, NewUsers} = login (User,Pass,Users);
        "logout " ++ User ->
            {_, NewUsers} = logout (User,Users)
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

