-module(server).
-export([start/2, stop/0,lerArquivo/1,escreverArquivo/2,acharOnline/2,listagemVitorias/1,stringLista/2]).

%Precisamos adicionar mensagens q o servidor recebe do cliente com a localização para sabermos se "matou" o inimigo, se ganhou 
%Algum bonus , etc ..
acharOnline(Map,Nivel)-> [User ||{User,{_,Comp,_,true,_,true}} <- maps:to_list(Map), (Nivel == Comp)].

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
    lerArquivo(T,Map#{User=> {Pass,list_to_integer(Nivel),list_to_integer(Vitorias),false,0,false}}).

escreverArquivo(Map,File)->
    {ok, S} = file:open(File, [write]),
    maps:fold(
	fun(User, {Pass,Nivel,Vitorias,_,_,_}, ok) ->
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
                    io:format("Received keypress \n"),
                    Room ! {keyp,Rest,self()};
                "keyReleased:" ++ Rest->
                    io:format("Received keypress \n"),
                    Room ! {keyr,Rest,self()};
                "scoreBoard:" ++ Rest ->
                    io:format("Received scoreBoard \n"),
                    RM ! {scoreBoard,self()};
                _ ->
                    io:format("Received ~s~n", [Data]),
                    Room ! {line,Data}
                end, 
            user(Sock,RM,Room);
        {nome,User} ->
            user(Sock,RM,Room,User);
        {newGame,Game} ->
            Game ! {enter,self()},
            self() ! {line, "game:Found\n"},
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
        {changeRoom, Pid}->
            user(Sock, RM,Pid,User);
        {line, Data} ->
            %io:format("Sending data ~s~n\n", [Data]),
            gen_tcp:send(Sock, Data),
            user(Sock, RM,Room,User);
        {tcp, _, Data} ->
            case Data of
                "users:" ++ Rest ->
                    io:format("Received user \n"),
                    RM ! {mensagem, Rest,self()};
                "scoreboard:" ++ Rest ->
                    io:format("Received scoreBoard \n"),
                    RM ! {scoreBoard,self()};
                "keyPressed:" ++ Rest->
                    io:format("Received keypress \n"),
                    Room ! {keyp,Rest,self()};
                "keyReleased:" ++ Rest->
                    io:format("Received keypress \n"),
                    Room ! {keyr,Rest,self()};
                _ ->
                    io:format("Received ~s~n", [Data]),
                    Room ! {line,Data}
                end, 
            user(Sock,RM,Room,User);
        {newGame,Game} ->
            Game ! {enter,self()},
          %  self() ! {line, "game:Found"},
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
    {rand:uniform(3),rand:uniform(1000),rand:uniform(1000)}.
 
gameTimer(Engine)->
    receive
        after 15 ->
            Engine ! timeout,
            gameTimer(Engine)
    end.

objectTimer(Engine)->
    receive after 10000 ->
        Object =generateObject(),
        Engine ! {object,Object},
        objectTimer(Engine)

        %mandar pra engine
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
    %Normal11 = maiorNoventa(NewAng1 + math:pi()/2),
    %Normal12 = maiorNoventa(NewAng1 - math:pi()/2),
    %Normal21 = maiorNoventa(NewAng2 + math:pi()/2),
    %Normal22 = maiorNoventa(NewAng2 - math:pi()/2),

    

    {Directionx1,Directiony1} = {math:cos(NewAng1), math:sin(NewAng1)},
    {Directionx2,Directiony2}  = {math:cos(NewAng2), math:sin(NewAng2)},



    Dot_product1 = Directionx1 * (NewX2 - NewX1) + Directiony1 * (NewY2 - NewY1),
    Dot_product2 = Directionx2 * (NewX1 - NewX2) + Directiony2 * (NewY1 - NewY2),

    if 
  %      (Dot_product1 < 0) and (Dot_product2 < 0)->
 %       
%            error;
        Dot_product1 < 0->
            pontoP1;
        Dot_product2 < 0->
            pontoP2;
        true ->
            collision
    end.
    



atingiuObjeto ([H | T],X,Y)->
    {Cor, Xobj ,Yobj} = H ,
    DistAux = math:pow((X -Xobj),2) + math:pow((Y -Yobj),2),
    Dist = math:sqrt(DistAux),
    if 
        100>Dist->
            {Cor,Xobj,Yobj};
        true ->
            atingiuObjeto(T, X, Y)
    end;

atingiuObjeto ([],_,_)-> [].
engine(GameRoom,Users1,Users2,Objects)->
    {User1,Posx1,W1,E1,Q1,Posy1,Aceleracao1,Velocidade1, Ang1,Boost1,Nboost1,From1} = Users1,
    {User2,Posx2,W2,E2,Q2,Posy2,Aceleracao2,Velocidade2, Ang2,Boost2,Nboost2,From2} = Users2,
    
    receive 
        {overTime,Pid} ->
            io:format("OVERTIME TIME!!!!!~n"),
            {Posx11,W11,Q11,E11, Posy11, Aceleracao11, Velocidade11,Ang11,Boost11,Nboost11} = {250,false,false,false,250,0.0,0.0,0.0,0.0,0.0},
            {Posx22,W22,Q22,E22, Posy22, Aceleracao22, Velocidade22,Ang22,Boost22,Nboost22} = {750,false,false,false,750,0.0,0.0,math:pi(),0.0,0.0},
            engine(Pid,{User1,Posx11,W11,Q11,E11, Posy11, Aceleracao11, Velocidade11,Ang11,Boost11,Nboost11,From1},{User2,Posx22,W22,Q22,E22, Posy22, Aceleracao22, Velocidade22,Ang22,Boost22,Nboost22,From2},Objects);

        {keyPressed , Key  , Pid} ->

            %io:format("teste keyp u1\n"),
            if 
                Pid == From1->
                    %io:format("teste keyp u1\n"),
                    case Key of
                        "w\n" ->
                            engine(GameRoom,{User1,Posx1,true,E1,Q1,Posy1,Aceleracao1,Velocidade1, Ang1,Boost1,Nboost1,From1},Users2,Objects);
                        "e\n" ->
                            engine(GameRoom,{User1,Posx1,W1,true,Q1,Posy1,Aceleracao1,Velocidade1, Ang1,Boost1,Nboost1,From1},Users2,Objects);
                        "q\n" ->
                            engine(GameRoom,{User1,Posx1,W1,E1,true,Posy1,Aceleracao1,Velocidade1, Ang1,Boost1,Nboost1,From1},Users2,Objects)
                        end;
                    
                    
                
                Pid == From2 ->
                    %io:format("teste keyp u2\n"),
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
                    %io:format("teste keyr u1\n"),
                    case Key of 
                        "w\n" ->
                            engine(GameRoom,{User1,Posx1,false,E1,Q1,Posy1,Aceleracao1,Velocidade1, Ang1,Boost1,Nboost1,From1},Users2,Objects);
                        "e\n" ->
                            engine(GameRoom,{User1,Posx1,W1,false,Q1,Posy1,Aceleracao1,Velocidade1, Ang1,Boost1,Nboost1,From1},Users2,Objects);
                        "q\n" ->
                            engine(GameRoom,{User1,Posx1,W1,E1,false,Posy1,Aceleracao1,Velocidade1, Ang1,Boost1,Nboost1,From1},Users2,Objects)
                    end;   
                Pid == From2 ->
                    %io:format("teste keyr u2\n"),
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
                From == From2 ->
                    engine(GameRoom,Users1,{User2,Posx2,false,E2,Q2,Posy2,Aceleracao2,Velocidade2, Ang2,Boost2-Boost,Nboost2-1,From2},Objects)
            end;
        {object,Objeto}->
            NewObjects = Objects ++ [Objeto],
            {Cor,X,Y} = Objeto,
            From1 ! {line , "game:object" ++ " "++ integer_to_list(Cor) ++ " " ++ integer_to_list(X) ++ " " ++ integer_to_list(Y) ++ "\n"},
            From2 ! {line , "game:object" ++ " "++ integer_to_list(Cor) ++ " " ++ integer_to_list(X) ++ " " ++ integer_to_list(Y) ++ "\n"},
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

                            NewAcc2 = 0;
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
               
                0>Velocidade1->
                    NewVel1 = Velocidade1 + 0.66*NewAcc1;
                true ->
                    %if acc == 0 diminur vel

                    NewVel1 = Velocidade1 + NewAcc1*0.15
            end,
            if 
                
                0>Velocidade2->
                    NewVel2 = Velocidade2 +  0.66*NewAcc2;
                true ->

                    NewVel2 = Velocidade2 + NewAcc2*0.15 
            end,
            
            NewX1 = Posx1 + math:cos(NewAng1)*NewVel1,
            NewY1 = Posy1 + math:sin(NewAng1)*NewVel1,
            NewX2 = Posx2 + math:cos(NewAng2)*NewVel2,
            NewY2 = Posy2 + math:sin(NewAng2)*NewVel2,

            
            DistAux = math:pow((NewX1 -NewX2),2) + math:pow((NewY1 -NewY2),2),
            Dist = math:sqrt(DistAux),
            %{User1,Posx1,W1,E1,Q1,Posy1,Aceleracao1,Velocidade1, Ang1,Boost1,Nboost1,From1} = Users1,
            %{User2,Posx2,W2,E2,Q2,Posy2,Aceleracao2,Velocidade2, Ang2,Boost2,Nboost2,From2} = Users2,
            if 
                50>Dist->
                    case checkColision(NewX1,NewY1,NewAng1,NewX2,NewY2,NewAng2) of
                        pontoP1->
                            io:format("PONTO JOGADOR 1 ~n"),
                            {Posx11,W11,Q11,E11, Posy11, Aceleracao11, Velocidade11,Ang11,Boost11,Nboost11} = {250,false,false,false,250,0.0,0.0,0.0,0.0,0.0},
                            {Posx22,W22,Q22,E22, Posy22, Aceleracao22, Velocidade22,Ang22,Boost22,Nboost22} = {750,false,false,false,750,0.0,0.0,math:pi(),0.0,0.0},
                            GameRoom ! {ponto,From1},
                            engine(GameRoom,{User1,Posx11,W11,Q11,E11, Posy11, Aceleracao11, Velocidade11,Ang11,Boost11,Nboost11,From1},{User2,Posx22,W22,Q22,E22, Posy22, Aceleracao22, Velocidade22,Ang22,Boost22,Nboost22,From2},Objects);
                        pontoP2->
                            io:format("PONTO JOGADOR 2 ~n"),
                            {Posx11,W11,Q11,E11, Posy11, Aceleracao11, Velocidade11,Ang11,Boost11,Nboost11} = {250,false,false,false,250,0.0,0.0,0.0,0.0,0.0},
                            {Posx22,W22,Q22,E22, Posy22, Aceleracao22, Velocidade22,Ang22,Boost22,Nboost22} = {750,false,false,false,750,0.0,0.0,math:pi(),0.0,0.0},
                            GameRoom ! {ponto,From2},
                            engine(GameRoom,{User1,Posx11,W11,Q11,E11, Posy11, Aceleracao11, Velocidade11,Ang11,Boost11,Nboost11,From1},{User2,Posx22,W22,Q22,E22, Posy22, Aceleracao22, Velocidade22,Ang22,Boost22,Nboost22,From2},Objects);
                        collision->
                            engine(GameRoom,{User1,NewX1,W1,E1,Q1,NewY1,NewAcc1,-2, NewAng1,Boost1,Nboost1,From1},{User2,NewX2,W2,E2,Q2,NewY2,NewAcc2,-2, NewAng2,Boost2,Nboost2,From2},Objects)
                   end;
                true ->
                    ok
            end,

            
            case atingiuObjeto(Objects,NewX1,NewY1) of 
                [{Cor,X,Y}] ->
                    From1 ! {line,"game:tiraObjeto" ++ " "++float_to_list(Cor) ++ " "++ float_to_list(X) ++ " " ++ float_to_list(Y)++"\n"},
                    From2 ! {line,"game:tiraObjeto" ++ " "++float_to_list(Cor) ++ " "++ float_to_list(X) ++ " " ++ float_to_list(Y)++"\n"},
                    if 
                        Nboost1 >= 5 ->
                            NewNboost1= 5,
                            NewBoost1 = Boost1;
                        true ->
                            case Cor of
                                1->
                                    NewBoost1 = 0,
                                    NewNboost1 = 0;
                                2->
                                    NewNboost1 = Nboost1 + 1,
                                    NewBoost1 = Boost1 + 0.5,
                                    timer:send_after(8000  ,self(), {retiraBoost,From1, Boost1});
                                    
                                3->
                                    NewNboost1 = Nboost1 + 1,
                                    NewBoost1 = Boost1 + 1,
                                    timer:send_after(5000  ,self(), {retiraBoost,From1, Boost1})
                            end
                    end; 
                _ ->
                    NewNboost1= Nboost1,
                    NewBoost1 = Boost1
            end ,

            case atingiuObjeto(Objects,NewX2,NewY2) of 
                [{Cor2,X2,Y2}] ->
                    From1 ! {line,"game:tiraObjeto" ++ " "++float_to_list(Cor2) ++ " "++ float_to_list(X2) ++ " " ++ float_to_list(Y2)++"\n"},
                    From2 ! {line,"game:tiraObjeto" ++ " "++float_to_list(Cor2) ++ " "++ float_to_list(X2) ++ " " ++ float_to_list(Y2)++"\n"},
                    if                             

                        Nboost2 >= 5 ->
                            NewNboost2 = 5,
                            NewBoost2 = Boost2;
                            ok;
                        true ->
                            case Cor2 of
                                1->
                                    NewBoost2 = 0,
                                    NewNboost2 = 0;
                                2->
                                    NewNboost2 = Nboost2 + 1,
                                    NewBoost2 = Boost2 + 0.5,
                                    timer:send_after(8000  ,self(), {retiraBoost,From2, Boost2});
                                    
                                3->
                                    NewNboost2 = Nboost2 + 1,
                                    NewBoost2 = Boost2 + 1,
                                    timer:send_after(5000  ,self(), {retiraBoost,From2, Boost2})
                            end
                    end;
                _ ->
                    
                    NewNboost2= Nboost2,
                    NewBoost2 = Boost2
            end ,
                    
            From1 ! {line,"game:position" ++ " "++float_to_list(NewX1) ++ " "++ float_to_list(NewY1) ++ " " ++ float_to_list(NewAng1) ++ " "++ float_to_list(NewX2) ++ " " ++ float_to_list(NewY2)++ " " ++ float_to_list(NewAng2) ++"\n"},
            From2 ! {line,"game:position" ++ " "++float_to_list(NewX2) ++ " "++ float_to_list(NewY2) ++ " " ++ float_to_list(NewAng2) ++ " "++ float_to_list(NewX1) ++ " " ++ float_to_list(NewY1)++ " " ++ float_to_list(NewAng1) ++"\n"},
            if 
                (NewX2 > 1000 orelse 0 > NewX2 orelse NewY2 > 1000 orelse  0 >NewY2)->
                    GameRoom ! {playerOut,From1};
                (NewX1 > 1000 orelse 0 > NewX1 orelse NewY1 > 1000 orelse  0 >NewY1)->
                    GameRoom ! {playerOut,From2};
                true -> 
                    engine(GameRoom,{User1,NewX1,W1,E1,Q1,NewY1,NewAcc1,NewVel1, NewAng1,NewBoost1,NewNboost1,From1},{User2,NewX2,W2,E2,Q2,NewY2,NewAcc2,NewVel2, NewAng2,NewBoost2,NewNboost2,From2},Objects)
            end;
        gameOver ->
            io:format("game over!!!! Esse "),
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
            if 
                Pid == From1->
                    
                    
                    Engine ! {keyPressed, Data,From1};
                    
                    
                
                Pid == From2 ->
                       
                    
                    Engine ! {keyPressed, Data,From2}
                            
                    
            end,
            gameRoom(Users1,Users2,Tref,RM,Engine);
        {ponto,Pid} ->
            if 
                Pid == From1->           
                    gameRoom({User1,From1,Pontos1+1,Nivel1},Users2,Tref,RM,Engine);
                Pid == From2 ->
                    gameRoom(Users1,{User2,From2,Pontos2+1,Nivel2},Tref,RM,Engine)                            
            end;
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
        {playerOut,Pid1}->
            Engine ! gameOver,
            
            if 
                Pid1 == From1 ->
                    From1 ! {line, "game:gameOver venceu\n"},
                    From2 ! {line, "game:gameOver perdeu\n"},
                    RM ! {matchWinner,User2,From1,Nivel1},
                    RM ! {matchLoser,User1,From2,Nivel2};
                true ->
                    From2 ! {line, "game:gameOver venceu\n"},
                    From1 ! {line, "game:gameOver perdeu\n"},
                    RM ! {matchWinner,User1,From1,Nivel1},
                    RM ! {matchLoser,User2,From2,Nivel2}
            end;            
            
            
        overTime ->
            
            if
                Pontos1 == Pontos2 ->
                    
                    OT = spawn(fun() -> overtime(Users1,Users2,RM,Engine)end),
                    From1 ! {changeRoom,OT},
                    From2 ! {changeRoom, OT},
                    Engine ! {overTime,OT};
                true ->
                    self() ! gameOver,
                    gameRoom(Users1,Users2,Tref,RM,Engine)
            end;
            
        gameOver ->
            io:format("Acabou o jogo ~n", []),
            Engine ! gameOver,
            case Pontos1 > Pontos2 of
                true ->
                    From1 ! {line, "game:gameOver venceu\n"},
                    From2 ! {line, "game:gameOver perdeu\n"},

                    RM ! {matchWinner,User1,From1,Nivel1},
                    RM ! {matchLoser,User2,From2,Nivel2};
                false ->
                    From2 ! {line, "game:gameOver venceu\n"},
                    From1 ! {line, "game:gameOver perdeu\n"},
                    RM ! {matchWinner,User1,From1,Nivel1},
                    RM ! {matchLoser,User2,From2,Nivel2}
            end
        
    end.


overtime(Users1,Users2,RM,Engine) ->
    io:format("Entramos em tempo extra\n"),

    {User1,From1,_,Nivel1} = Users1,
    {User2,From2,_,Nivel2} = Users2,
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
            overtime(Users1,Users2,RM,Engine);
        {keyr,Data,Pid} ->
                %io:format("Pattern recognized ~p~n",[Pid]),
                
                %io:format("user ~p~n",[User1]),
                
                if 
                    Pid == From1->
                        
                        
                        Engine ! {keyReleased, Data,From1};
                        
                        
                    
                    Pid == From2 ->
                           
                        
                        Engine ! {keyReleased, Data,From2}
                                
                        
                end,
                overtime(Users1,Users2,RM,Engine);
            {playerOut,Pid1}->
                Engine ! gameOver,
                    
                if 
                    Pid1 == From1 ->
                        From1 ! {line, "game:gameOver venceu\n"},
                        From2 ! {line, "game:gameOver perdeu\n"},
                        RM ! {matchWinner,User2,From1,Nivel1},
                        RM ! {matchLoser,User1,From2,Nivel2};
                    true ->
                        From2 ! {line, "game:gameOver venceu\n"},
                        From1 ! {line, "game:gameOver perdeu\n"},
                        RM ! {matchWinner,User1,From1,Nivel1},
                        RM ! {matchLoser,User2,From2,Nivel2}
                end;
        %newObject ->
        %    Object =generateObject,
        %    timer:send_after(10000  ,self(),newObject),
        %    From1 ! {objeto,Object},
        %    From2 ! {objeto,Object};
        
        {ponto,Pid} ->
            if 
                Pid == From1->         
                    From1 ! {line, "game:gameOver venceu\n"},
                    From2 ! {line, "game:gameOver perdeu\n"},  
                    RM ! {matchWinner,User1},
                    RM ! {matchLoser,User2};
                Pid == From2 ->
                    From2 ! {line, "game:gameOver venceu\n"},
                    From1 ! {line, "game:gameOver perdeu\n"},
                    RM ! {matchWinner,User2},
                    RM ! {matchLoser,User1}
            end,
            Engine ! gameOver
    end.

rm(Rooms,Users) ->
    io:format("Entrei no rm\n"),

    receive
        {mensagem,Data,From}->
            NewUsers = usersManager(Users,Data,self(),From),
            NewRooms = Rooms ;
        {matchWinner,User,Nivel,From}->
            {Pass,Nivel,Vitorias,true,From,true} = maps:get(User,Users),
            if 
                Vitorias +1 == 2 * Nivel ->
                    NewNivel = Nivel +1;
                true ->
                    NewNivel = Nivel
            end,
            NewUsers = maps:update(User, {Pass,NewNivel,Vitorias+1,true,From,false}, Users),
            NewRooms = Rooms ;
        {matchLoser,User,Nivel,From}->
            {Pass,Nivel,Vitorias,true,From,true} = maps:get(User,Users),
            NewUsers = maps:update(User, {Pass,Nivel,Vitorias,true,From,false}, Users),
            NewRooms = Rooms ;
        {scoreBoard,From}->
            From ! {line,listagemVitorias(Users)} ,
            NewUsers = Users,
            NewRooms = Rooms ;
        {newMatch,User1,User2}->

            io:format("Encontrei Partida\n"),
            {Pass,Nivel1,Vitorias,true,From,true} = maps:get(User1,Users),
            Aux = maps:update(User1,{Pass,Nivel1,Vitorias,true,From,false},Users),
            {Pass1,Nivel2,Vitorias1,true,From1,true} = maps:get(User2,Users),
            NewUsers = maps:update(User2,{Pass1,Nivel2,Vitorias1,true,From1,false},Aux),
            NewRooms = Rooms ,
            Room = spawn(fun()-> gameRoom({User1,From,0,Nivel1},{User2,From1,0,Nivel2},self()) end),
            Tref = timer:send_after(120000 ,Room,overTime),
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
        "find_game " ++ User ->
            [NewUser] = string:tokens(User, "\n"),
            case find_game(NewUser,Users,From) of 
                {ok,NewUsers,Nivel} ->
                    io:format("irei achar jogo\n"),
                    findGame(Users,NewUser,Nivel,RM);
                _ ->
                    io:format("Jovem Gafanhoto\n"),
                    NewUsers = Users
            end;
        "create_account " ++ Rest ->
            io:format("Create Account\n"), 
            [User,Pass] = string:tokens(Rest," "),
            NewPass = re:replace(Pass, "\n" , "", [global, {return, list}]),
            {_, NewUsers} = create_account(User,NewPass,Users,From);
        "close_account " ++ Rest ->
            io:format("Close Account\n"),
            [User,Pass] = string:tokens(Rest," "),
            NewPass = re:replace(Pass, "\n" , "", [global, {return, list}]),
            {_, NewUsers} = close_account(User,NewPass,Users,From);
        "login "  ++ Rest ->
            io:format("Login\n"),
            [User,Pass] = string:tokens(Rest," "),
            case login(User,Pass,Users,From) of
                {_, NewUsers,Nivel} ->
                    io:format("login com sucesso\n");
                {_,NewUsers} ->
                    io:format("Login não teve sucesso\n"),
                    ok
            end;
        "logout " ++ User ->
            {_, NewUsers} = logout (User,Users,From)
    end,
    NewUsers.
find_game(User,Map,From)->
    case maps:find(User,Map) of
        {ok,{Pass,Nivel,Vitorias,true,From,false}} ->
            From ! {line,"Users:sucessful\n"},
            {ok,maps:update(User,{Pass,Nivel,Vitorias,true,From,true},Map),Nivel};
        _ ->
            From ! {line,"Users:unsucessful\n"}
end.

listagemVitorias(Users)->
    Lista = [{User,Vic} ||{User,{_,_,Vic,_,_,_}} <- maps:to_list(Users)],
    NewLista = lists:reverse(lists:keysort(2,Lista)),
    if 
        length(NewLista) >= 5->
            "Scoreboard:" ++ "5" ++ " " ++ stringLista(5,NewLista);
        true ->
            "Scoreboard:" ++ integer_to_list(length(NewLista)) ++  " "++ stringLista(length(NewLista),NewLista)
    end .

stringLista(N,[{User,Vic}|T])->
    if 
        N == 0->
            "\n";
        true ->
            User ++ " " ++ integer_to_list(Vic) ++ " " ++ stringLista(N-1,T)
    end.
    
    


create_account(User,Pass,Map,From) ->
     case maps:find(User,Map) of
        error ->
            %io:format("Dou print account \n"),
            From ! {line,"Users:sucessful\n"},    
            From ! {nome, User},
            {ok,Map#{User=> {Pass,1,0,false,From,false}}};
        _ ->
            From ! {line,"Users:unsucessful\n"},    
            {user_exists,Map}
   
    end.

close_account(User,Pass,Map,From) ->
    case maps:find(User,Map) of
        {ok,{Pass,_,_,_,From,_}} ->
            From ! {line,"Users:sucessful\n"},
            {ok,maps:remove(Map,User)};
         _ -> 
            From ! {line, "Users:unsucessful\n"},
            {invalid,Map}
    end.

login(User,Pass,Map,From) -> 
    [NewPass] = string:tokens(Pass, "\n"),
    case maps:find(User,Map) of
        {ok,{NewPass,Nivel,Vitorias,false,_,false}} -> 
            From ! {line,"Users:sucessful\n"},
            From ! {nome, User},
            {ok,maps:update(User, {NewPass,Nivel,Vitorias,true,From,false}, Map),Nivel};       
        _ ->
            From ! {line,"Users:unsucessful\n"},
            {ok,Map}

    end.


logout(User,Map,From) -> 
    case maps:find(User,Map) of
        {ok,{Pass,Nivel,Vitorias,true,From,_}} ->
            From ! {line,"Users:sucessful\n"},
            {ok,maps:update(User,{Pass,Nivel,Vitorias,false,0,false},Map)};
        _ ->
            From ! {line,"Users:uncessful\n"},
            {ok,Map}
    end.


