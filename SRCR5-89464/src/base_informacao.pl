use_module(library(csv)).

:- dynamic contentor/8.
:- dynamic pontoRecolha/6.
:- dynamic aresta/3.
:- dynamic estima/2.

%garagem(15885). ou 15805
%goal(15806).

garagem(15885).
goal(15889).

load_dataset :- csv_read_file("dataset.csv", Data, [functor(row), arity(10)]),
					  convert_dataset(Data),
					  create_vertices(),
					  %create_adjacenciaInRua(),
					  create_AdjacenciaOutRuas(),
					  %get_pontosSeq().
					  garagem(G), goal(Gl),
					  arestas_LocalG(G),arestas_LocalD(Gl),
					  create_estimativa(Gl).

convert_dataset([row(Latitude,Longitude,ObjectId,Ponto_Recolha_Freguesia,Ponto_Recolha_Local,Contentor_Residuo,Contentor_Tipo,Contentor_Capacidade,Contentor_Qt,Contentor_Total_Litros)|T]) :-  
	aux_convert(T).

aux_convert([]).
aux_convert([row(Latitude,Longitude,ObjectId,Ponto_Recolha_Freguesia,Ponto_Recolha_Local,Contentor_Residuo,Contentor_Tipo,Contentor_Capacidade,Contentor_Qt,Contentor_Total_Litros)|T]) :-
	split_string(Ponto_Recolha_Local, ":", " ",[X,Xs|S]),
	createRuasAdjacentes(X,Xs,S,NomeRua,Ruas),
	split_string(NomeRua,""," ",[NRua|Ns]),
	atom_number(X, Id_Local), %converte de string para int, os outros já estão com o tipo certo
	assert(contentor(ObjectId,Latitude,Longitude,Id_Local,NRua,Ruas,Contentor_Residuo,Contentor_Total_Litros)),
	aux_convert(T).


%----------------------------------------------------------------------------------------------------
% Ver em que rua o ponto de recolha se encontra e quais as ruas adjacentes ao mesmo.
createRuasAdjacentes(X,Xs,[],NomeRua,[]):- split_string(Xs,","," ",[NomeRua|T]).
createRuasAdjacentes(X,Xs,[S|Ss],NomeRua,Ruas) :- split_string(S,"",")",[H|T]),
										 		  split_string(H,"-"," ",Ruas),
												  split_string(Xs,"(","",[NomeRua|Ns]).
createRuasAdjacentes(_,_,[_]).




%-----------------------------------------------------------------------------------------------------
% Criar pontos de recolha
% Caso o campo sentido seja igual a 1, então tem um sentido, caso seja 2, tem 2 sentidos
create_vertices():- findall((LocalId,Latitude,Longitude,Rua,RuasAdj),contentor(_,Latitude,Longitude,LocalId,Rua,RuasAdj,_,_),Locals),
				 	list_to_set(Locals,L), 
				 	create_pontoRecolha(L).


create_pontoRecolha([(Id,Latitude,Longitude,Rua,RuasAdj)|T]) :-	findall(ContentorId,contentor(ContentorId,_,_,Id,_,_,_,_),ListC),
																		assert(pontoRecolha(Id,Latitude,Longitude,Rua,RuasAdj,ListC)),
																		create_pontoRecolha(T).
create_pontoRecolha([_]).


%--------------------------------------------------------------------------------------
% Criar arestas adjacentes (de forma sequencial) entre pontos que se situam na mesma rua.
create_adjacenciaInRua() :- findall(NomeRua,pontoRecolha(_,_,_,NomeRua,_,_),RuasT),
					   		list_to_set(RuasT,T),
					   		aux_adjacenciaInRua(T).

aux_adjacenciaInRua([]).
aux_adjacenciaInRua([H|T]) :- findall(Id_Ponto,pontoRecolha(Id_Ponto,_,_,H,_,_),Pontos),
							  insere_aresta(Pontos),
							  aux_adjacenciaInRua(T).


insere_aresta([Ponto1,Ponto2|Xs]) :- distancia(Ponto1,Ponto2,Dist),
									 assert(aresta(Ponto1,Ponto2,Dist)),
									 insere_aresta([Ponto2|Xs]).
insere_aresta([_]).					   


%-------------------------------------------------------------------------------------------
% Criar arestas adjacentes entre os pontos de recolha de ruas diferentes.
create_AdjacenciaOutRuas() :- findall(Id_Ponto,pontoRecolha(Id_Ponto,_,_,_,_,_),Pontos),
							  aux_adjacenciaOutRuas(Pontos).

aux_adjacenciaOutRuas([]).
aux_adjacenciaOutRuas([H|T]) :- findall((Rua,Ruas),pontoRecolha(H,_,_,Rua,Ruas,_),RuasAdj),
								ruas_adjacentes(RuasAdj,2,H),
								aux_adjacenciaOutRuas(T).

ruas_adjacentes([(Rua,[])],_,_).
ruas_adjacentes([(Rua,[H|Hs])],S,Ponto) :- findall((Id_Ponto,Ruas),pontoRecolha(Id_Ponto,_,_,H,Ruas,_), RuasPAdj),
										   aux_ruas_adjacentes(Rua,RuasPAdj,S,Ponto),
										   ruas_adjacentes([(Rua,Hs)],1,Ponto).


aux_ruas_adjacentes(_,[],_,_).
aux_ruas_adjacentes(RuaP1,[(Ponto2,Ruas)|T],1,Ponto1) :- pertenceRua(RuaP1,Ponto2,Ruas,Ponto1).
aux_ruas_adjacentes(RuaP1,[(Ponto2,Ruas)|T],2,Ponto1) :- pertenceRua(RuaP1,Ponto1,Ruas,Ponto2). 
aux_ruas_adjacentes(RuaP1,[(Ponto2,Ruas)|T],_,Ponto1) :- aux_ruas_adjacentes(RuaP1,T,_,Ponto1). 


pertenceRua(_,P2,[],P1).
pertenceRua(RuaP1,P2,RuasP2,P1) :-  member(RuaP1,RuasP2),
									distancia(P1,P2,Dist),
									not((aresta(P1,P2,Dist))),
									assert(aresta(P1,P2,Dist)). 
 
%-----------------------------------------------------------------------------------------------------
% Fórmula de Haversine - equação usada em navegação, fornecendo distâncias entre dois pontos de uma esfera
% a partir de suas latitudes e longitudes

distancia(P1,P2,Dis):- findall((Lat1,Lon1),pontoRecolha(P1,Lat1,Lon1,_,_,_),[(Lat1,Lon1)|T1]),
					   findall((Lat2,Lon2),pontoRecolha(P2,Lat2,Lon2,_,_,_),[(Lat2,Lon2)|T2]),
					   P is 0.017453292519943295,
    				   A is (0.5 - cos((Lat2 - Lat1) * P) / 2 + cos(Lat1 * P) * cos(Lat2 * P) * (1 - cos((Lon2 - Lon1) * P)) / 2),
    				   Dis is (12742 * asin(sqrt(A))).

%-----------------------------------------------------------------------------------------------------
% Criar as arestas para a garagem ou local de depósito nos restantes pontos
arestas_LocalG(Point):- findall(Id_Ponto,pontoRecolha(Id_Ponto,_,_,_,_,_),Pontos),
					    create_arestasG(Point,Pontos).

arestas_LocalD(Point):- findall(Id_Ponto,pontoRecolha(Id_Ponto,_,_,_,_,_),Pontos),
					    create_arestasD(Point,Pontos).

create_arestasG(_,[]).
create_arestasG(G,[X|Xs]):- goal(X),
							create_arestasG(G,Xs).
create_arestasG(G,[G|Xs]):- create_arestasG(G,Xs).
create_arestasG(G,[X|Xs]):- distancia(G,X,Dist),
						    not(aresta(G,X,Dist)),
						    assert(aresta(G,X,Dist)),
						    create_arestasG(G,Xs).
create_arestasG(G,[X|Xs]):- create_arestasG(G,Xs).

create_arestasD(_,[]).
create_arestasD(G,[X|Xs]):- garagem(X),
							create_arestasD(G,Xs).	
create_arestasD(G,[G|Xs]):- create_arestasD(G,Xs).					   
create_arestasD(G,[X|Xs]):- distancia(X,G,Dist),
						    not(aresta(X,G,Dist)),
						    assert(aresta(X,G,Dist)),
						    create_arestasD(G,Xs).
create_arestasD(G,[X|Xs]):- create_arestasD(G,Xs).

%------------------------------------------------------------------------------------------------------
% Criar arestas entre um ponto de recolha que é adjacente ao seu anterior (caso exista) e ao
% posterior (caso exista) tendo em conta a sua posição no ficheiro Excel. 
get_pontosSeq():- findall(Id_Ponto,pontoRecolha(Id_Ponto,_,_,_,_,_),Pontos),
				  create_arestas_seq(Pontos).


create_arestas_seq([X,Xs|T]):- not(aresta(X,Xs,_)),
							   distancia(X,Xs,Dist),
						   	   assert(aresta(X,Xs,Dist)),
						   	   create_arestas_seq([Xs|T]).
create_arestas_seq([X,Xs|T]):- create_arestas_seq([Xs|T]).
create_arestas_seq([X]).					   	   

%------------------------------------------------------------------------------------------------------
% Consultar a base de conhecimento
showContentores() :- findall((A,B,C,D,E,F,S,G),contentor(A,B,C,D,E,F,S,G),Pontos),showList(Pontos),write("Tamanho = "),length(Pontos,N),write(N).
showPontosRecolha() :- findall((A,B,C,E,F,G),pontoRecolha(A,B,C,E,F,G),Pontos), showList(Pontos), write("Tamanho = "),length(Pontos,N),write(N).
showArestas() :- findall((X,Y,D),aresta(X,Y,D),Arestas), showList(Arestas), write("Tamanho = "),length(Arestas,N),write(N).
showEstimas() :- findall((A,B),estima(A,B),L),showList(L),write("Tamanho = "),length(L,N),write(N).
showList([H|T]) :- write(H),write("\n"),showList(T).
showList([_]).

%-------------------------------------------------------------------------------------------------------
% Cálculo da estimativa do custo de cada nodo até ao nodo final, i.e, da distância de um nodo x ao nodo final

create_estimativa(Destino):-	findall(Id_Ponto,pontoRecolha(Id_Ponto,_,_,_,_,_),Pontos),
    							insere_estimativa(Pontos,Destino).

insere_estimativa([H|T],Destino):-	distancia(H,Destino,Estimativa),
									assert(estima(H,Estimativa)),
									insere_estimativa(T,Destino).

insere_estimativa([],_).