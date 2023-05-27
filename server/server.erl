-module(server).
-export([start/2, stop/0,lerArquivo/1,escreverArquivo/2,acharOnline/2,  listagemVitorias/1,stringLista/2]).

acharOnline(Map,Nivel)-> [User ||{User,{_,Comp,_,true,_,true}} <- maps:to_list(Map), (Nivel == Comp)].

findGame(Map, User,Nivel,RM)->
    Lista = acharOnline(Map,Nivel),
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
        %Não apagar esse io:format escreve no arquivo
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
                    RM ! {mensagem, Rest,self()};
                "keyPressed:" ++ Rest->
                    Room ! {keyp,Rest,self()};
                "keyReleased:" ++ Rest->
                    Room ! {keyr,Rest,self()};
                "scoreBoard:" ++ _ ->
                    RM ! {scoreBoard,self()};
                _ ->
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
            RM ! {logout,self()};
        {tcp_error, _, _} ->
            RM ! {mensagem,"logout ",self()};
         _ ->
            ok
    end.
user(Sock ,RM,Room,User) ->
    receive
        {changeRoom, Pid}->
            user(Sock, RM,Pid,User);
        {line, Data} ->
            gen_tcp:send(Sock, Data),
            user(Sock, RM,Room,User);
        {tcp, _, Data} ->
            case Data of
                "users:" ++ Rest ->
                    RM ! {mensagem, Rest,self()};
                "scoreboard:" ++ _ ->
                    RM ! {scoreBoard,self()};
                "keyPressed:" ++ Rest->
                    Room ! {keyp,Rest,self()};
                "keyReleased:" ++ Rest->
                    Room ! {keyr,Rest,self()};
                _ ->
                    Room ! {line,Data}
                end, 
            user(Sock,RM,Room,User);
        {newGame,Game} ->
            Game ! {enter,self()},
            user(Sock,RM,Game,User);
        {tcp_closed, _} ->
            Room ! {disconnected,self()},
            RM ! {mensagem, "logout " ++ User,self()};
        {tcp_error, _, _} ->
            Room ! {disconnected,self()},
            RM ! {mensagem,"logout " ++ User ,self()};
        {nome, _} ->
            ok;
         _ ->
            ok
end.
generateObject()->
    {rand:uniform(3),rand:uniform(1000),rand:uniform(1000)}.
 
gameTimer(Engine)->
    receive
        gameOver ->
            ok
        after 15 ->
            Engine ! timeout,
            gameTimer(Engine)
    end.

objectTimer(Engine)->
    receive after 10000 ->
        Object =generateObject(),
        Engine ! {object,Object},
        objectTimer(Engine)

    end.

checkColision(NewX1,NewY1,NewAng1,NewX2,NewY2,NewAng2)->


    

    {Directionx1,Directiony1} = {math:cos(NewAng1), math:sin(NewAng1)},
    {Directionx2,Directiony2}  = {math:cos(NewAng2), math:sin(NewAng2)},



    Dot_product1 = Directionx1 * (NewX2 - NewX1) + Directiony1 * (NewY2 - NewY1),
    Dot_product2 = Directionx2 * (NewX1 - NewX2) + Directiony2 * (NewY1 - NewY2),

    if 
        Dot_product1 < 0->
            pontoP1;
        Dot_product2 < 0->
            pontoP2;
        true ->
            collision
    end.
    



atingiuObjeto ([H | T],Objects,X,Y,X2,Y2)->
    {Cor, Xobj ,Yobj} = H ,
    DistAux = math:pow((X -Xobj),2) + math:pow((Y -Yobj),2),
    Dist = math:sqrt(DistAux),
    DistAux2 = math:pow((X2 -Xobj),2) + math:pow((Y2 -Yobj),2),
    Dist2 = math:sqrt(DistAux2),
    
    if 
        62.5>Dist->
            NewObj = lists:delete(H, Objects),
            {Cor,Xobj,Yobj,NewObj,user1};
        62.5>Dist2->
            NewObj = lists:delete(H, Objects),
            {Cor,Xobj,Yobj,NewObj,user2};
        true ->
            atingiuObjeto(T, Objects,X, Y,X2,Y2)
    end;

atingiuObjeto ([],Objects,_,_,_,_)-> Objects.
engine(GameRoom,Users1,Users2,Objects)->
    {User1,Posx1,W1,E1,Q1,Posy1,Aceleracao1,Velocidade1, Ang1,BlueBoost1,NBlueboost1,GreenBoost1,NGreenBoost1,From1} = Users1,
    {User2,Posx2,W2,E2,Q2,Posy2,Aceleracao2,Velocidade2, Ang2,BlueBoost2,NBlueboost2,GreenBoost2,NGreenBoost2,From2} = Users2,
    
    receive 
        {overTime,Pid} ->
            {Posx11,W11,Q11,E11, Posy11, Aceleracao11, Velocidade11,Ang11,BlueBoost11,NBlueboost11,GreenBoost11,NGreenBoost11} = {250,false,false,false,250,0.0,0.0,0.0,0.0,0.0,0,0},
            {Posx22,W22,Q22,E22, Posy22, Aceleracao22, Velocidade22,Ang22,BlueBoost12,NBlueboost12,GreenBoost12,NGreenBoost12} = {750,false,false,false,750,0.0,0.0,math:pi(),0.0,0.0,0,0},
            engine(Pid,{User1,Posx11,W11,Q11,E11, Posy11, Aceleracao11, Velocidade11,Ang11,BlueBoost11,NBlueboost11,GreenBoost11,NGreenBoost11,From1},{User2,Posx22,W22,Q22,E22, Posy22, Aceleracao22, Velocidade22,Ang22,BlueBoost12,NBlueboost12,GreenBoost12,NGreenBoost12,From2},Objects);

        {keyPressed , Key  , Pid} ->

            if 
                Pid == From1->
                    case Key of
                        "w\n" ->
                            engine(GameRoom,{User1,Posx1,true,E1,Q1,Posy1,Aceleracao1,Velocidade1, Ang1,BlueBoost1,NBlueboost1,GreenBoost1,NGreenBoost1,From1},Users2,Objects);
                        "e\n" ->
                            engine(GameRoom,{User1,Posx1,W1,true,Q1,Posy1,Aceleracao1,Velocidade1, Ang1,BlueBoost1,NBlueboost1,GreenBoost1,NGreenBoost1,From1},Users2,Objects);
                        "q\n" ->
                            engine(GameRoom,{User1,Posx1,W1,E1,true,Posy1,Aceleracao1,Velocidade1, Ang1,BlueBoost1,NBlueboost1,GreenBoost1,NGreenBoost1,From1},Users2,Objects)
                        end;
                Pid == From2 ->

                    case Key of
                        "w\n" ->
                            engine(GameRoom,Users1,{User2,Posx2,true,E2,Q2,Posy2,Aceleracao2,Velocidade2, Ang2,BlueBoost2,NBlueboost2,GreenBoost2,NGreenBoost2,From2},Objects);
                        "e\n" ->
                            engine(GameRoom,Users1,{User2,Posx2,W2,true,Q2,Posy2,Aceleracao2,Velocidade2, Ang2,BlueBoost2,NBlueboost2,GreenBoost2,NGreenBoost2,From2},Objects);
                        "q\n" ->
                            engine(GameRoom,Users1,{User2,Posx2,W2,E2,true,Posy2,Aceleracao2,Velocidade2, Ang2,BlueBoost2,NBlueboost2,GreenBoost2,NGreenBoost2,From2},Objects)
                        end
                            
                    end;
            
        {keyReleased , Key  , Pid} ->
            if
                Pid == From1->
                    case Key of 
                        "w\n" ->
                            engine(GameRoom,{User1,Posx1,false,E1,Q1,Posy1,Aceleracao1,Velocidade1, Ang1,BlueBoost1,NBlueboost1,GreenBoost1,NGreenBoost1,From1},Users2,Objects);
                        "e\n" ->
                            engine(GameRoom,{User1,Posx1,W1,false,Q1,Posy1,Aceleracao1,Velocidade1, Ang1,BlueBoost1,NBlueboost1,GreenBoost1,NGreenBoost1,From1},Users2,Objects);
                        "q\n" ->
                            engine(GameRoom,{User1,Posx1,W1,E1,false,Posy1,Aceleracao1,Velocidade1, Ang1,BlueBoost1,NBlueboost1,GreenBoost1,NGreenBoost1,From1},Users2,Objects)
                    end;   
                Pid == From2 ->
                    case Key of
                        "w\n" ->
                            engine(GameRoom,Users1,{User2,Posx2,false,E2,Q2,Posy2,Aceleracao2,Velocidade2, Ang2,BlueBoost2,NBlueboost2,GreenBoost2,NGreenBoost2,From2},Objects);
                        "e\n" ->
                            engine(GameRoom,Users1,{User2,Posx2,W2,false,Q2,Posy2,Aceleracao2,Velocidade2, Ang2,BlueBoost2,NBlueboost2,GreenBoost2,NGreenBoost2,From2},Objects);
                        "q\n" ->
                            engine(GameRoom,Users1,{User2,Posx2,W2,E2,false,Posy2,Aceleracao2,Velocidade2, Ang2,BlueBoost2,NBlueboost2,GreenBoost2,NGreenBoost2,From2},Objects)
                        end
                    end;
        {retiraBoost,user1, greenboost}->
            io:format("tirei boost ~n"),       
            engine(GameRoom,{User1,Posx1,W1,E1,Q1,Posy1,Aceleracao1,Velocidade1, Ang1,BlueBoost1,NBlueboost1,GreenBoost1 - math:pow(0.7,NGreenBoost1) ,NGreenBoost1-1,From1},Users2,Objects);
        {retiraBoost,user1, bluenboost}->
            io:format("tirei boost ~n"),       
            engine(GameRoom,{User1,Posx1,W1,E1,Q1,Posy1,Aceleracao1,Velocidade1, Ang1,BlueBoost1-math:pow(0.7,NBlueboost1),NBlueboost1-1,GreenBoost1,NGreenBoost1,From1},Users2,Objects);
        {retiraBoost,user2, greenboost}->
            io:format("tirei boost ~n"),       
            engine(GameRoom,Users1,{User2,Posx2,W2,E2,Q2,Posy2,Aceleracao2,Velocidade2, Ang2,BlueBoost2,NBlueboost2,GreenBoost2- math:pow(0.7,NGreenBoost2),NGreenBoost2-1,From2},Objects);
        {retiraBoost,user2, bluenboost}->       
            io:format("tirei boost ~n"),
            engine(GameRoom,Users1,{User2,Posx2,W2,E2,Q2,Posy2,Aceleracao2,Velocidade2, Ang2,BlueBoost2-math:pow(0.7,NBlueboost2),NBlueboost2-1,GreenBoost2,NGreenBoost2,From2},Objects);
        {object,Objeto}->
            if 
                (length(Objects) == 5 )->
                    NewObjects = Objects ;
                true ->
                    
                    NewObjects = Objects ++ [Objeto],
                    {Cor,X,Y} = Objeto,
                    From1 ! {line , "game:object" ++ " "++ integer_to_list(Cor) ++ " " ++ integer_to_list(X) ++ " " ++ integer_to_list(Y) ++ "\n"},
                    From2 ! {line , "game:object" ++ " "++ integer_to_list(Cor) ++ " " ++ integer_to_list(X) ++ " " ++ integer_to_list(Y) ++ "\n"}
            end,
            engine(GameRoom,Users1,Users2,NewObjects);
        timeout ->
           
            case W1 of
                true -> 
                    if Aceleracao1 >=1 ->
                        NewAcc1 = 1;
                    true ->
                        NewAcc1 = Aceleracao1 + 0.006
                    end;
                false ->
                    if 
                        0.009>=Aceleracao1->

                            NewAcc1 = 0;
                        Aceleracao1>0.009 ->
                            NewAcc1 = Aceleracao1 - 0.009
                    end            
            end,
            case {E1,Q1} of
                {true,false} ->
                    NewAng1 = Ang1 + math:pi()/100 + GreenBoost1*math:pi()/50;
                
                {false,true} ->
                    NewAng1 = Ang1 -  math:pi()/100 - GreenBoost1*math:pi()/50;
                _ ->
                    NewAng1 = Ang1
            end,
            case W2 of
                true -> 
                    if Aceleracao2 >=1 ->
                        NewAcc2 = 1;
                    true ->
                        NewAcc2 = Aceleracao2 + 0.006
                    end;
                false ->
                    if 
                        0.009>=Aceleracao2->

                            NewAcc2 = 0;
                        Aceleracao2>0.009 ->
                            NewAcc2 = Aceleracao2 - 0.009
                    end
            end,
            case {E2,Q2} of
                {true,false} ->
                    NewAng2 = Ang2 + math:pi()/100 +GreenBoost2*math:pi()/50;
                {false,true} ->
                    NewAng2 = Ang2 -  math:pi()/100 - GreenBoost2*math:pi()/50;
                _ ->
                    NewAng2 = Ang2
            end,
            if           
                0>=Velocidade1->
                    NewVel1 = Velocidade1 +  0.066*NewAcc1*(BlueBoost1+1);
                true ->
                    if NewAcc1 == 0 ->
                        NewVel1 = Velocidade1 - 0.066*(BlueBoost1+1);
                    true ->

                        NewVel1 = Velocidade1 + (BlueBoost1+1)*NewAcc1*0.015 - 0.006*(BlueBoost1+1)
                    end
            end,
            if 
                0>=Velocidade2->
                    NewVel2 = Velocidade2 +  0.066*NewAcc2*(BlueBoost2+1);
                true ->
                    if NewAcc2 == 0 ->
                        NewVel2 = Velocidade2 - 0.066*(BlueBoost2+1);
                    true ->
                        NewVel2 = Velocidade2 + (BlueBoost2+1)*NewAcc2*0.015 - 0.006*(BlueBoost2+1)
                    end
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
                            %BlueBoost2,NBlueboost2,GreenBoost2,NGreenBoost2
                            {Posx11,W11,Q11,E11, Posy11, Aceleracao11, Velocidade11,Ang11,BlueBoost11,NBlueboost11,GreenBoost11,NGreenBoost11} = {250,false,false,false,250,0.0,0.0,0.0,0.0,0.0,0,0},
                            {Posx22,W22,Q22,E22, Posy22, Aceleracao22, Velocidade22,Ang22,BlueBoost12,NBlueboost12,GreenBoost12,NGreenBoost12} = {750,false,false,false,750,0.0,0.0,math:pi(),0.0,0.0,0,0},
                        
                            GameRoom ! {ponto,From1},
                            engine(GameRoom,{User1,Posx11,W11,Q11,E11, Posy11, Aceleracao11, Velocidade11,Ang11,BlueBoost11,NBlueboost11,GreenBoost11,NGreenBoost11,From1},{User2,Posx22,W22,Q22,E22, Posy22, Aceleracao22, Velocidade22,Ang22,BlueBoost12,NBlueboost12,GreenBoost12,NGreenBoost12,From2},Objects);

                        pontoP2->
                            {Posx11,W11,Q11,E11, Posy11, Aceleracao11, Velocidade11,Ang11,BlueBoost11,NBlueboost11,GreenBoost11,NGreenBoost11} = {250,false,false,false,250,0.0,0.0,0.0,0.0,0.0,0,0},
                            {Posx22,W22,Q22,E22, Posy22, Aceleracao22, Velocidade22,Ang22,BlueBoost12,NBlueboost12,GreenBoost12,NGreenBoost12} = {750,false,false,false,750,0.0,0.0,math:pi(),0.0,0.0,0,0},
                            
                            GameRoom ! {ponto,From2},
                            engine(GameRoom,{User1,Posx11,W11,Q11,E11, Posy11, Aceleracao11, Velocidade11,Ang11,BlueBoost11,NBlueboost11,GreenBoost11,NGreenBoost11,From1},{User2,Posx22,W22,Q22,E22, Posy22, Aceleracao22, Velocidade22,Ang22,BlueBoost12,NBlueboost12,GreenBoost12,NGreenBoost12,From2},Objects);

                        collision->
                            engine(GameRoom,{User1,NewX1,W1,E1,Q1,NewY1,0.5,-2, NewAng1,BlueBoost1,NBlueboost1,GreenBoost1,NGreenBoost1,From1},{User2,NewX2,W2,E2,Q2,NewY2,0.5,-2, NewAng2,BlueBoost2,NBlueboost2,GreenBoost2,NGreenBoost2,From2},Objects)
                   end;
                true ->
                    ok
            end,

            
            case atingiuObjeto(Objects,Objects,NewX1,NewY1,NewX2,NewY2) of 
                {Cor,X,Y,NewObj,user1} ->
                    NewObjects = NewObj,
                    NewNBlueboost2= NBlueboost2,
                    NewBlueBoost2 = BlueBoost2*NBlueboost2,
                    NewNGreenboost2= NGreenBoost2,
                    NewGreenBoost2 = GreenBoost2*NGreenBoost2,
                    From1 ! {line,"game:tiraObjeto" ++ " "++integer_to_list(Cor) ++ " "++ integer_to_list(X) ++ " " ++ integer_to_list(Y)++"\n"},
                    From2 ! {line,"game:tiraObjeto" ++ " "++integer_to_list(Cor) ++ " "++ integer_to_list(X) ++ " " ++ integer_to_list(Y)++"\n"},
                    case Cor of
                        1->
                            NewNBlueboost1= 0,
                            NewBlueBoost1 = 0,
                            NewNGreenboost1= 0,
                            NewGreenBoost1 = 0;
                            
                        2->
                            NewNBlueboost1= NBlueboost1 + 1,
                            NewBlueBoost1 = BlueBoost1 +  math:pow(0.7,NewNBlueboost1),
                            NewNGreenboost1= NGreenBoost1,
                            NewGreenBoost1 = GreenBoost1,
                            timer:send_after(5000  ,self(), {retiraBoost,user1, blueboost});
                            
                        3->
                            NewNBlueboost1= NBlueboost1,
                            NewBlueBoost1 = BlueBoost1,
                            NewNGreenboost1= NGreenBoost1 + 1,
                            NewGreenBoost1 = GreenBoost1 +  math:pow(0.7,NewNGreenboost1),
                            timer:send_after(5000  ,self(), {retiraBoost,user1, greenboost})
                    end; 
                {Cor2,X2,Y2,NewObj2,user2} ->
                    NewObjects = NewObj2,
                    NewNBlueboost1= NBlueboost1,
                    NewBlueBoost1 = BlueBoost1*NBlueboost1,
                    NewNGreenboost1= NGreenBoost1,
                    NewGreenBoost1 = GreenBoost1*NGreenBoost1,
                    From1 ! {line,"game:tiraObjeto" ++ " "++integer_to_list(Cor2) ++ " "++ integer_to_list(X2) ++ " " ++ integer_to_list(Y2)++"\n"},
                    From2 ! {line,"game:tiraObjeto" ++ " "++integer_to_list(Cor2) ++ " "++ integer_to_list(X2) ++ " " ++ integer_to_list(Y2)++"\n"},
                    case Cor2 of
                        1->
                            NewNBlueboost2= 0,
                            NewBlueBoost2 = 0,
                            NewNGreenboost2= 0,
                            NewGreenBoost2 = 0;
                            
                        2->
                            NewNBlueboost2= NBlueboost2 + 1,
                            NewBlueBoost2 = BlueBoost2 +  math:pow(0.7,NewNBlueboost2),
                            NewNGreenboost2= NGreenBoost2,
                            NewGreenBoost2 = GreenBoost2,
                            timer:send_after(5000  ,self(), {retiraBoost,user2, blueboost});
                            
                        3->
                            NewNBlueboost2= NBlueboost2,
                            NewBlueBoost2 = BlueBoost2,
                            NewNGreenboost2= NGreenBoost2 + 1,
                            NewGreenBoost2 = GreenBoost2 +  math:pow(0.7,NewNBlueboost2),
                            timer:send_after(5000  ,self(), {retiraBoost,user2, greenboost})
                    end;
                NewObj3 ->
                    NewObjects = NewObj3,
                    NewNBlueboost2= NBlueboost2,
                    NewBlueBoost2 = BlueBoost2,
                    NewNGreenboost2= NGreenBoost2,
                    NewGreenBoost2 = GreenBoost2,
                    NewNBlueboost1= NBlueboost1,
                    NewBlueBoost1 = BlueBoost1,
                    NewNGreenboost1= NGreenBoost1,
                    NewGreenBoost1 = GreenBoost1
                
            end ,

            
                    
            From1 ! {line,"game:position" ++ " "++float_to_list(NewX1) ++ " "++ float_to_list(NewY1) ++ " " ++ float_to_list(NewAng1) ++ " "++ float_to_list(NewX2) ++ " " ++ float_to_list(NewY2)++ " " ++ float_to_list(NewAng2) ++"\n"},
            From2 ! {line,"game:position" ++ " "++float_to_list(NewX2) ++ " "++ float_to_list(NewY2) ++ " " ++ float_to_list(NewAng2) ++ " "++ float_to_list(NewX1) ++ " " ++ float_to_list(NewY1)++ " " ++ float_to_list(NewAng1) ++"\n"},
            if 
                (NewX2 > 1000 orelse 0 > NewX2 orelse NewY2 > 1000 orelse  0 >NewY2)->
                    io:format("player2 out ~n"),
                    GameRoom ! {playerOut,From1};
                (NewX1 > 1000 orelse 0 > NewX1 orelse NewY1 > 1000 orelse  0 >NewY1)->
                    io:format("player1 out ~n"),
                    GameRoom ! {playerOut,From2};
                true -> 
                    engine(GameRoom,{User1,NewX1,W1,E1,Q1,NewY1,NewAcc1,NewVel1, NewAng1,NewNBlueboost1,NewBlueBoost1 ,NewNGreenboost1,NewGreenBoost1,From1},{User2,NewX2,W2,E2,Q2,NewY2,NewAcc2,NewVel2, NewAng2,NewNBlueboost2,NewBlueBoost2 ,NewNGreenboost2,NewGreenBoost2,From2},NewObjects)
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
            {Posx1,W1,Q1,E1, Posy1, Aceleracao1, Velocidade1,Ang1,BlueBoost1,NBlueboost1,GreenBoost1,NGreenBoost1} = {250,false,false,false,250,0.0,0.0,0.0,0.0,0.0,0,0},
            {Posx2,W2,Q2,E2, Posy2, Aceleracao2, Velocidade2,Ang2,BlueBoost2,NBlueboost2,GreenBoost2,NGreenBoost2} = {750,false,false,false,750,0.0,0.0,math:pi(),0.0,0.0,0,0},
            Engine = spawn(fun()->engine(GameRoom,{ Users1,Posx1,W1,Q1,E1, Posy1, Aceleracao1, Velocidade1,Ang1,BlueBoost1,NBlueboost1,GreenBoost1,NGreenBoost1,From1}, { Users2,Posx2,W2,Q2,E2, Posy2, Aceleracao2, Velocidade2,Ang2,BlueBoost2,NBlueboost2,GreenBoost2,NGreenBoost2,From2},[Object]) end),
            Timer = spawn(fun() -> gameTimer(Engine) end),
            spawn(fun() -> objectTimer(Engine) end),
            gameRoom(User1,User2,Tref,RM,Engine,Timer)
    
    end.


    
gameRoom(Users1,Users2,Tref,RM,Engine,Timer) ->
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
            gameRoom(Users1,Users2,Tref,RM,Engine,Timer);
        {ponto,Pid} ->
            io:format("Pontuaçao 1 ~p ~n", [Pontos1]),
            io:format("Pontuaçao 1 ~p ~n", [Pontos2]),
            if 
                Pid == From1->    
                    io:format("ponto player 1~n"),       
                    gameRoom({User1,From1,Pontos1+1,Nivel1},Users2,Tref,RM,Engine,Timer);
                Pid == From2 ->
                    io:format("ponto player 2~n"), 
                    gameRoom(Users1,{User2,From2,Pontos2+1,Nivel2},Tref,RM,Engine,Timer)                            
            end;
        {keyr,Data,Pid} ->
                if 
                    Pid == From1->   
                        Engine ! {keyReleased, Data,From1};
                    Pid == From2 ->
                        Engine ! {keyReleased, Data,From2}
                end,
                gameRoom(Users1,Users2,Tref,RM,Engine,Timer);
        {enter, _} ->
            gameRoom(Users1,Users2,Tref,RM,Engine,Timer);
        {playerOut,Pid1}->
            Engine ! gameOver,
            if 
                Pid1 == From1 ->
                    From1 ! {line, "game:gameOver venceu\n"},
                    From2 ! {line, "game:gameOver perdeu\n"},
                    RM ! {matchOver,User2,User1};      
                true ->
                    From2 ! {line, "game:gameOver venceu\n"},
                    From1 ! {line, "game:gameOver perdeu\n"},
                    RM ! {matchOver,User1,User2}
            end;            
        overTime ->
            if
                Pontos1 == Pontos2 ->
                    io:format("Entramos em Overtime ~n"),
                    OT = spawn(fun() -> overtime(Users1,Users2,RM,Engine)end),
                    From1 ! {changeRoom,OT},
                    From2 ! {changeRoom, OT},
                    Engine ! {overTime,OT};
                true ->
                    self() ! gameOver,
                    gameRoom(Users1,Users2,Tref,RM,Engine,Timer)
            end;
            
        gameOver ->
            io:format("Acabou o jogo ~n", []),
            Timer ! gameOver,
            Engine ! gameOver,
            case Pontos1 > Pontos2 of
                true ->
                    From2 ! {line, "game:gameOver venceu\n"},
                    From1 ! {line, "game:gameOver perdeu\n"},

                    RM ! {matchOver,User2,User1};
                false ->
                    From1 ! {line, "game:gameOver venceu\n"},
                    From2 ! {line, "game:gameOver perdeu\n"},
                    RM ! {matchOver,User1,User2}
            end;
        {disconnected,Pid} ->
            Timer ! gameOver,
            Engine ! gameOver,
            if 
                Pid == From1 ->
                    From2 ! {line, "game:gameOver venceu\n"},
                    From1 ! {line, "game:gameOver perdeu\n"},

                    RM ! {matchOver,User2,User1};
                true ->
                    From1 ! {line, "game:gameOver venceu\n"},
                    From2 ! {line, "game:gameOver perdeu\n"},

                    RM ! {matchOver,User1,User2}
            end
        

        
    end.


overtime(Users1,Users2,RM,Engine) ->
    {User1,From1,_,_} = Users1,
    {User2,From2,_,_} = Users2,
    receive
        {keyp,Data,Pid} ->
            
            if 
                Pid == From1->  
                    Engine ! {keyPressed, Data,From1};
                Pid == From2 ->   
                    Engine ! {keyPressed, Data,From2}     
            end,
            overtime(Users1,Users2,RM,Engine);
            {keyr,Data,Pid} -> 
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
                        RM ! {matchOver,User1,User2};

                    true ->
                        From2 ! {line, "game:gameOver venceu\n"},
                        From1 ! {line, "game:gameOver perdeu\n"},
                        RM ! {matchOver,User2,User1}

                end;        
        {ponto,Pid} ->
            if  
                Pid == From1->         
                    From2 ! {line, "game:gameOver venceu\n"},
                    From1 ! {line, "game:gameOver perdeu\n"},  
                    RM ! {matchOver,User2,User1};

                Pid == From2 ->
                    From1 ! {line, "game:gameOver venceu\n"},
                    From2 ! {line, "game:gameOver perdeu\n"},
                    RM ! {matchOver,User1,User2}
            end,
            Engine ! gameOver
    end.

rm(Rooms,Users) ->
    RM = self(),
    receive
        {mensagem,Data,From}->
            NewUsers = usersManager(Users,Data,self(),From),
            NewRooms = Rooms ;
        {matchOver,User1,User2}->
            {Pass,Nivel1,Vitorias,Online1,From1,Find} = maps:get(User1,Users),
            if 
                Vitorias +1 == 2 * Nivel1 ->
                    NewNivel = Nivel1 +1;
                true ->
                    NewNivel = Nivel1
            end,
            Aux = maps:update(User1, {Pass,NewNivel,Vitorias+1,Online1,From1,Find}, Users),
            {Pass2,Nivel2,Vitorias2,Online2,From2,Find2} = maps:get(User2,Users),
            NewUsers = maps:update(User2, {Pass2,Nivel2,Vitorias2,Online2,From2,Find2}, Aux),
            NewRooms = Rooms ;
        {scoreBoard,From}->
            From ! {line,listagemVitorias(Users)} ,
            NewUsers = Users,
            NewRooms = Rooms ;
        {newMatch,User1,User2}->
            {Pass,Nivel1,Vitorias,true,From,true} = maps:get(User1,Users),
            Aux = maps:update(User1,{Pass,Nivel1,Vitorias,true,From,false},Users),
            {Pass1,Nivel2,Vitorias1,true,From1,true} = maps:get(User2,Users),
            NewUsers = maps:update(User2,{Pass1,Nivel2,Vitorias1,true,From1,false},Aux),
            NewRooms = Rooms ,
            Room = spawn(fun()-> gameRoom({User1,From,0,Nivel1},{User2,From1,0,Nivel2},RM) end),
            Tref = timer:send_after(120000 ,Room,overTime),
            Room ! {start,Tref},
            From ! {newGame, Room},
            From1 ! {newGame, Room};
        stop ->
            NewUsers = Users,
            NewRooms = Rooms ,
            ?MODULE ! {data ,Users}
    end,
    rm(NewRooms,NewUsers).

usersManager(Users,String,RM,From)->

    case String of 
        "find_game " ++ User ->
            [NewUser] = string:tokens(User, "\n"),
            case find_game(NewUser,Users,From) of 
                {ok,NewUsers,Nivel} ->
                    findGame(Users,NewUser,Nivel,RM);
                _ ->
                    NewUsers = Users
            end;
        "create_account " ++ Rest ->
            [User,Pass] = string:tokens(Rest," "),
            NewPass = re:replace(Pass, "\n" , "", [global, {return, list}]),
            {_, NewUsers} = create_account(User,NewPass,Users,From);
        "close_account " ++ Rest ->
            [User,Pass] = string:tokens(Rest," "),
            NewPass = re:replace(Pass, "\n" , "", [global, {return, list}]),
            {_, NewUsers} = close_account(User,NewPass,Users,From);
        "login "  ++ Rest ->
            [User,Pass] = string:tokens(Rest," "),
            case login(User,Pass,Users,From) of
                {_, NewUsers,_} ->
                    ok;
                {_,NewUsers} ->
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


stringLista(0,[])->
    "\n";

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
            From ! {line,"Users:sucessful\n"},    
            From ! {nome, User},
            {ok,Map#{User=> {Pass,1,0,false,From,false}}};
        _ ->
            From ! {line,"Users:unsucessful\n"},    
            {user_exists,Map}
   
    end.

close_account(User,Pass,Map,From) ->
    
    case maps:find(User,Map) of
        {ok,{Pass,_,_,_,_,_}} ->
            From ! {line,"Users:sucessful\n"},
            {ok,maps:remove(User,Map)};
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


