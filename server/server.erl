-module(server).
-export([start/2, stop/0,lerArquivo/1,escreverArquivo/2,acharOnline/2,listagemVitorias/1]).

%Precisamos adicionar mensagens q o servidor recebe do cliente com a localização para sabermos se "matou" o inimigo, se ganhou 
%Algum bonus , etc ..
acharOnline(Map,Nivel)-> [User ||{User,{_,Comp,_,true,_}} <- maps:to_list(Map), (Nivel == Comp)].

findGame(Map, User,Nivel,RM)->
    io:format("Achar jogo\n"),
    Lista = acharOnline(Map,Nivel),
    %io:format("Lista \n",[Lista]),
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
    io:format("Acceptor\n"),
    {ok, Sock} = gen_tcp:accept(LSock),
    spawn(fun() -> acceptor(LSock,RM) end),
    user(Sock, RM,RM).


user(Sock ,RM,Room) ->
    receive
        {line, Data} ->
            %io:format("Sending data ~s~n\n", [Data]),
            gen_tcp:send(Sock, Data),
            user(Sock, RM,Room);
        {tcp, _, Data} ->
            case Data of
                "users:" ++ Rest ->
                    io:format("Received user \n"),
                    RM ! {mensagem, Rest,self()};
                "keyPressed:" ++ Rest->
                    %io:format("Received keypress \n"),
                    Room ! {keyp,Rest,self()};
                "keyReleased:" ++ Rest->
                    %io:format("Received keypress \n"),
                    Room ! {keyr,Rest,self()};
                _ ->
                    io:format("Received ~s~n", [Data]),
                    Room ! {line,Data}
                end, 
            user(Sock,RM,Room);
        {nome,User} ->
            user(Sock,RM,Room,User);
        {newGame,Game} ->
            Game ! {enter,self()},
            user(Sock,RM,Game);
        {tcp_closed, _} ->
            %Colocar pra ir offline
            RM ! {logout,self()},
            io:format("User saiuuser 3\n");
        {tcp_error, _, _} ->
            %Colocar pra ir offline
            RM ! {mensagem,"logout ",self()},
            io:format("User saiu user 3\n");

         _ ->
            io:format("Erro\n")

end.
user(Sock ,RM,Room,User) ->
    receive
        {line, Data} ->
            %io:format("Sending data ~s~n\n", [Data]),
            gen_tcp:send(Sock, Data),
            user(Sock, RM,Room,User);
        {tcp, _, Data} ->
            case Data of
                "users:" ++ Rest ->
                    io:format("Received user \n"),
                    RM ! {mensagem, Rest,self()};
                "keyPressed:" ++ Rest->
                    %io:format("Received keypress \n"),
                    Room ! {keyp,Rest,self()};
                "keyReleased:" ++ Rest->
                    %io:format("Received keypress \n"),
                    Room ! {keyr,Rest,self()};
                _ ->
                    io:format("Received ~s~n", [Data]),
                    Room ! {line,Data}
                end, 
            user(Sock,RM,Room,User);
        {newGame,Game} ->
            Game ! {enter,self()},
            user(Sock,RM,Game,User);
        {tcp_closed, _} ->
            %Colocar pra ir offline
            RM ! {mensagem, "logout " ++ User,self()},
            io:format("User saiu user 4\n");
        {tcp_error, _, _} ->
            %Colocar pra ir offline
            RM ! {mensagem,"logout " ++ User ,self()},
            io:format("User saiu user 4\n");
        {nome, _} ->
            ok;
         _ ->
            io:format("Erro\n")

end.
generateObject()->
    {rand:uniform(3),rand:uniform(),rand:uniform()}.
 
gameTimer(Engine)->
    receive after 15 ->
        Engine ! timeout,
        gameTimer(Engine)
    end.

objectTimer(Engine)->
    receive after 10000 ->
        Object =generateObject(),
        Engine ! {object,Object},
        %mandar pra engine
        objectTimer(Engine)
    end.

maiorNoventa(Ang)->
    Pi = math:pi(),
    if 
        Ang > 2*Pi ->
            NewAng = Ang - 2*math:pi();
        0>Ang ->
            NewAng = Ang + 2*math:pi();
        true ->
            NewAng = Ang
    end,
    NewAng.
checkColision(NewX1,NewY1,NewAng1,NewX2,NewY2,NewAng2)->
    Normal11 = maiorNoventa(NewAng1 + math:pi()/2),
    Normal12 = maiorNoventa(NewAng1 - math:pi()/2),
    Normal21 = maiorNoventa(NewAng2 + math:pi()/2),
    Normal22 = maiorNoventa(NewAng2 - math:pi()/2),


.
atingiuObjeto (Objetos,X,Y)->
    [{Cor,XObj,YObj}||{Cor,XObj,YObj} <- Objetos, ].

    
engine(GameRoom,Users1,Users2,Objects)->
    {User1,Posx1,W1,E1,Q1,Posy1,Aceleracao1,Velocidade1, Ang1,Boost1,Nboost1,From1} = Users1,
    {User2,Posx2,W2,E2,Q2,Posy2,Aceleracao2,Velocidade2, Ang2,Boost2,Nboost2,From2} = Users2,
    
    receive 
        {keyPressed , Key  , Pid} ->

            io:format("teste keyp u1\n"),
            if 
                Pid == From1->
                    io:format("teste keyp u1\n"),
                    case Key of
                        "w\n" ->
                            engine(GameRoom,{User1,Posx1,true,E1,Q1,Posy1,Aceleracao1,Velocidade1, Ang1,Boost1,Nboost1,From1},Users2,Objects);
                        "e\n" ->
                            engine(GameRoom,{User1,Posx1,W1,true,Q1,Posy1,Aceleracao1,Velocidade1, Ang1,Boost1,Nboost1,From1},Users2,Objects);
                        "q\n" ->
                            engine(GameRoom,{User1,Posx1,W1,E1,true,Posy1,Aceleracao1,Velocidade1, Ang1,Boost1,Nboost1,From1},Users2,Objects)
                        end;
                    
                    
                
                Pid == From2 ->
                    io:format("teste keyp u2\n"),
                    case Key of
                        "w\n" ->
                            engine(GameRoom,Users1,{User2,Posx2,true,E2,Q2,Posy2,Aceleracao2,Velocidade2, Ang2,Boost2,Nboost2,From2},Objects);
                        "e\n" ->
                            engine(GameRoom,Users1,{User2,Posx2,W2,true,Q2,Posy2,Aceleracao2,Velocidade2, Ang2,Boost2,Nboost2,From2},Objects);
                        "q\n" ->
                            engine(GameRoom,Users1,{User2,Posx2,W2,E2,true,Posy2,Aceleracao2,Velocidade2, Ang2,Boost2,Nboost2,From2},Objects)
                        end
                            
                    end;
            
        {keyReleased , Key  , Pid} ->
            if
                Pid == From1->
                    io:format("teste keyr u1\n"),
                    case Key of 
                        "w\n" ->
                            engine(GameRoom,{User1,Posx1,false,E1,Q1,Posy1,Aceleracao1,Velocidade1, Ang1,Boost1,Nboost1,From1},Users2,Objects);
                        "e\n" ->
                            engine(GameRoom,{User1,Posx1,W1,false,Q1,Posy1,Aceleracao1,Velocidade1, Ang1,Boost1,Nboost1,From1},Users2,Objects);
                        "q\n" ->
                            engine(GameRoom,{User1,Posx1,W1,E1,false,Posy1,Aceleracao1,Velocidade1, Ang1,Boost1,Nboost1,From1},Users2,Objects)
                    end;   
                Pid == From2 ->
                    io:format("teste keyr u2\n"),
                    case Key of
                        "w\n" ->
                            engine(GameRoom,Users1,{User2,Posx2,false,E2,Q2,Posy2,Aceleracao2,Velocidade2, Ang2,Boost2,Nboost2,From2},Objects);
                        "e\n" ->
                            engine(GameRoom,Users1,{User2,Posx2,W2,false,Q2,Posy2,Aceleracao2,Velocidade2, Ang2,Boost2,Nboost2,From2},Objects);
                        "q\n" ->
                            engine(GameRoom,Users1,{User2,Posx2,W2,E2,false,Posy2,Aceleracao2,Velocidade2, Ang2,Boost2,Nboost2,From2},Objects)
                        end
                    end;
        {retiraBoost,From, Boost}->
            if 
                From == From1->
                    engine(GameRoom,{User1,Posx1,true,E1,Q1,Posy1,Aceleracao1,Velocidade1, Ang1,Boost1-Boost,Nboost1-1,From1},Users2,Objects);
                Pid == From2 ->
                    engine(GameRoom,Users1,{User2,Posx2,false,E2,Q2,Posy2,Aceleracao2,Velocidade2, Ang2,Boost2-Boost,Nboost2-1,From2},Objects)
            end;
        {object,Objeto}->
            NewObjects = Objects ++ [Objeto],
            {Cor,X,Y} = Objeto ,
            From1 ! {line , "game:object" ++ " "++ integer_to_list(Cor) ++ " " ++ float_to_list(X) ++ " " ++ float_to_list(Y) ++ "\n"},
            From2 ! {line , "game:object" ++ " "++ integer_to_list(Cor) ++ " " ++ float_to_list(X) ++ " " ++ float_to_list(Y) ++ "\n"},
            engine(GameRoom,Users1,Users2,NewObjects);
        timeout ->
           
            case W1 of
                true -> 
                    NewAcc1 = Aceleracao1 + 0.066;
                false ->
                    if 
                        0.09>=Aceleracao1->

                            NewAcc1 = 0;
                        Aceleracao1>0.09 ->
                            NewAcc1 = Aceleracao1 - 0.09
                end
                  
            
            end,
            case {E1,Q1} of
                {true,false} ->
                    NewAng1 = Ang1 + math:pi()/128;
                
                {false,true} ->
                    NewAng1 = Ang1 -  math:pi()/128;
                _ ->
                    NewAng1 = Ang1
            end,

            case W2 of
                true -> 
                    NewAcc2 = Aceleracao2 + 0.066;
                false ->
                    if 
                        0.09>=Aceleracao2->

                            NewAcc2 = -0.5;
                        Aceleracao2>0.09 ->
                            NewAcc2 = Aceleracao2 - 0.09
                end
                  
            end,
            case {E2,Q2} of
                {true,false} ->
                    NewAng2 = Ang2 + math:pi()/128;
                {false,true} ->
                    NewAng2 = Ang2 -  math:pi()/128;
                _ ->
                    NewAng2 = Ang2
            end,
            if 
                0>=Velocidade1->
                    NewVel1 = 0;
                true ->

                    NewVel1 = Velocidade1 + NewAcc1*0.066 - 0.066
            end,
            if 
                0>=Velocidade2->
                    NewVel2 = 0;
                true ->

                    NewVel2 = Velocidade1 + NewAcc1*0.066 - 0.066
            end,
            

            NewX1 = Posx1 + math:cos(NewAng1)*NewVel1,
            NewY1 = Posy1 + math:sin(NewAng1)*NewVel1,
            NewX2 = Posx2 + math:cos(NewAng2)*NewVel2,
            NewY2 = Posy2 + math:sin(NewAng2)*NewVel2,
            DistAux = math:pow((NewX1 -NewX2),2) + math:pow((NewY1 -NewY2),2),
            Dist = math:sqrt(DistAux),
            if 
                50>Dist->
                    case checkColision(NewX1,NewY1,NewAng1,NewX2,NewY2,NewAng2) of
                        pontoP1->
                            ;
                        pontoP2->
                    end
            end,
            
            case atingiuObjeto(NewX1,NewY1) of 
                [{Cor,X,Y}] ->
                    From1 ! {line,"game:tiraObjeto" ++ " "++float_to_list(Cor) ++ " "++ float_to_list(X) ++ " " ++ float_to_list(Y)++"\n"},
                    From2 ! {line,"game:tiraObjeto" ++ " "++float_to_list(Cor) ++ " "++ float_to_list(X) ++ " " ++ float_to_list(Y)++"\n"},
                    if 
                        Nboost >= 5 ->
                            ok;
                        true ->
                            case Cor of
                                1->
                                    NewBoost = 0,
                                    Nboost = 0;
                                2->
                                    NewNboost = Nboost + 1,
                                    NewBoost = Boost + 0.5,
                                    timer:send_after(8000  ,self(), {retiraBoost,From, Boost});
                                    
                                3->
                                    NewNboost = Nboost + 1,
                                    NewBoost = Boost + 1,
                                    timer:send_after(5000  ,self(), {retiraBoost,From, Boost}); 
                    end 
            end ,
                    
            if 
                (NewX2 > 1000 orelse 0 > NewX2 orelse NewY2 > 1000 orelse  0 >NewY2)->
                    GameRoom ! {playerOut,From2,From1};
                (NewX1 > 1000 orelse 0 > NewX1 orelse NewY1 > 1000 orelse  0 >NewY1)->
                    GameRoom ! {playerOut,From1,From2};
                true -> 
                From1 ! {line,"game:position" ++ " "++float_to_list(NewX1) ++ " "++ float_to_list(NewY1) ++ " " ++ float_to_list(NewAng1) ++ " "++ float_to_list(NewX2) ++ " " ++ float_to_list(NewY2)++ " " ++ float_to_list(NewAng2) ++"\n"},
                From2 ! {line,"game:position" ++ " "++float_to_list(NewX2) ++ " "++ float_to_list(NewY2) ++ " " ++ float_to_list(NewAng2) ++ " "++ float_to_list(NewX1) ++ " " ++ float_to_list(NewY1)++ " " ++ float_to_list(NewAng1) ++"\n"},
                engine(GameRoom,{User1,NewX1,W1,E1,Q1,NewY1,NewAcc1,NewVel1, NewAng1,Boost1,Nboost1,From1},{User2,NewX2,W2,E2,Q2,NewY2,NewAcc2,NewVel2, NewAng2,Boost2,Nboost2,From2},Objects);
            end;
        gameOver ->
            ok
        
    end.

                
gameRoom(User1,User2,RM) ->
    
    GameRoom = self(),
    {Users1,From1,_,_} = User1,
    {Users2,From2,_,_} = User2,
    receive
        {start,Tref}->
            Object =generateObject(),
            GameRoom ! {newObject,Object},
            {Posx1,W1,Q1,E1, Posy1, Aceleracao1, Velocidade1,Ang1,Boost1,Nboost1} = {250,false,false,false,250,0.0,0.0,0.0,0.0,0.0},
            {Posx2,W2,Q2,E2, Posy2, Aceleracao2, Velocidade2,Ang2,Boost2,Nboost2} = {750,false,false,false,750,0.0,0.0,math:pi(),0.0,0.0},
            Engine = spawn(fun()->engine(GameRoom,{ Users1,Posx1,W1,Q1,E1, Posy1, Aceleracao1, Velocidade1,Ang1,Boost1,Nboost1,From1}, { Users2,Posx2,W2,Q2,E2, Posy2, Aceleracao2, Velocidade2,Ang2,Boost2,Nboost2,From2},[Object]) end),
            spawn(fun() -> gameTimer(Engine) end),
            spawn(fun() -> objectTimer(Engine) end),
            gameRoom(User1,User2,Tref,RM,Engine)
    
    end.


    
gameRoom(Users1,Users2,Tref,RM,Engine) ->
    {User1,From1,Pontos1,Nivel1} = Users1,
    {User2,From2,Pontos2,Nivel2} = Users2,
   
    receive
        {keyp,Data,Pid} ->
            %io:format("Pattern recognized ~p~n",[Pid]),
            
            %io:format("user ~p~n",[User1]),
            
            if 
                Pid == From1->
                    
                    
                    Engine ! {keyPressed, Data,From1};
                    
                    
                
                Pid == From2 ->
                       
                    
                    Engine ! {keyPressed, Data,From2}
                            
                    
            end,
            gameRoom(Users1,Users2,Tref,RM,Engine);

        {keyr,Data,Pid} ->
                %io:format("Pattern recognized ~p~n",[Pid]),
                
                %io:format("user ~p~n",[User1]),
                
                if 
                    Pid == From1->
                        
                        
                        Engine ! {keyReleased, Data,From1};
                        
                        
                    
                    Pid == From2 ->
                           
                        
                        Engine ! {keyReleased, Data,From2}
                                
                        
                end,
                gameRoom(Users1,Users2,Tref,RM,Engine);
        {enter, _} ->
            io:format("gameRoom start ~n", []),
            gameRoom(Users1,Users2,Tref,RM,Engine);
        {playerOut,From1,From2}->
            RM ! {matchWinner,User1,From1,Nivel1},
            RM ! {matchLoser,User2,From2,Nivel2},
            erlang:cancel(Tref);
        {playerOut,From2,From1}->
            RM ! {matchWinner,User2,From1,Nivel1},
            RM ! {matchLoser,User1,From2,Nivel2},
            erlang:cancel(Tref);
        gameOver ->
            io:format("Acabou o jogo ~n", []),
            if 
            Pontos1 == Pontos2 ->
                overtime(Users1,Users2,RM,Engine)
            end,
            case Pontos1 > Pontos2 of
                true ->
                    RM ! {matchWinner,User1,From1,Nivel1},
                    RM ! {matchLoser,User2,From2,Nivel2};
                false ->
                    RM ! {matchWinner,User1,From1,Nivel1},
                    RM ! {matchLoser,User2,From2,Nivel2}
            end
        
    end.


overtime(Users1,Users2,RM,Engine) ->
    io:format("Entramos em tempo extra\n"),

    {User1,From1,_} = Users1,
    {User2,From2,_} = Users2,
    receive
        {playerOut,Ganhou,Perdeu} ->
                RM ! {matchWinner,Ganhou},
                RM ! {matchLoser,Perdeu};
        newObject ->
            Object =generateObject,
            timer:send_after(10000  ,self(),newObject),
            From1 ! {objeto,Object},
            From2 ! {objeto,Object};
        {ponto, User1} ->
            RM ! {matchWinner,User1},
            RM ! {matchLoser,User2};
        {ponto, User2} ->
            RM ! {matchWinner,User2},
            RM ! {matchLoser,User1}
    end.

rm(Rooms,Users) ->
    io:format("Entrei no rm\n"),

    receive
        {mensagem,Data,From}->
            NewUsers = usersManager(Users,Data,self(),From),
            NewRooms = Rooms ;
        {matchWinner,User,Nivel,From}->
            {Pass,Nivel,Vitorias,true,From} = maps:get(User,Users),
            if 
                Vitorias +1 == 2 * Nivel ->
                    NewNivel = Nivel +1;
                true ->
                    NewNivel = Nivel
            end,
            NewUsers = maps:update(User, {Pass,NewNivel,Vitorias+1,true,From}, Users),
            findGame(Users,User,Nivel,self()),
            NewUsers = Users,
            NewRooms = Rooms ,
            From ! {line, "gameOver:won"};
        {matchLoser,User,Nivel,From}->
            findGame(Users,User,Nivel,self()),
            NewUsers = Users,
            NewRooms = Rooms ,
            From ! {line, "gameOver:lost"};    
        {newMatch,User1,User2}->
            io:format("Encontrei Partida\n"),
            {Pass,Nivel1,Vitorias,true,From} = maps:get(User1,Users),
            Aux = maps:update(User1,{Pass,Nivel1,Vitorias,false,From},Users),
            {Pass1,Nivel2,Vitorias1,true,From1} = maps:get(User2,Users),
            NewUsers = maps:update(User1,{Pass1,Nivel2,Vitorias1,false,From1},Aux),
            NewRooms = Rooms ,
            Room = spawn(fun()-> gameRoom({User1,From,0,Nivel1},{User2,From1,0,Nivel2},self()) end),
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
            io:format("Create Account\n"),
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
                    io:format("login com sucesso\n"),
                    findGame(Users,User,Nivel,RM);
                {_,NewUsers} ->
                    io:format("Login não teve sucesso\n"),
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
            From ! {nome, User},
            {ok,Map#{User=> {Pass,1,0,false,From}}};
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
            From ! {nome, User},
            {ok,maps:update(User, {NewPass,Nivel,Vitorias,true,From}, Map),Nivel};       
        _ ->
            From ! {line,"Users:unsucessful\n"},
            {ok,Map}

    end.


logout(User,Map,From) -> 
    case maps:find(User,Map) of
        {ok,{Pass,Nivel,Vitorias,true,From}} ->
            From ! {line,"Users:sucessful\n"},
            {ok,maps:update(User,{Pass,Nivel,Vitorias,false,0},Map)};
        _ ->
            From ! {line,"Users:uncessful\n"},
            {ok,Map}
    end.


