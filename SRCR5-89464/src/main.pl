:-include("base_informacao.pl").
:-include("predicados_aux.pl").

:- set_prolog_stack(global, limit(100 000 000 000)).


adjacente(X,Y,C) :- aresta(X,Y,C).
%adjacente(X,Y,C) :- aresta(Y,X,C).

%move(X,Y,Custo,Quantidade,TipoLixo) :- aresta(X,Y,Custo).
								 

getQtLixo('all',_,Q,Ponto) :- pontoRecolha(Ponto,_,_,_,_,ListaC),
							  getLixoContentor(ListaC,_,Q).
getQtLixo('seletivo',Tipo,Q,Ponto) :- pontoRecolha(Ponto,_,_,_,_,ListaC),
							  		  getLixoContentor(ListaC,Tipo,Q).
getQtLixo(_,_,0,Ponto).

getLixoContentor([],_,0).
getLixoContentor([X|Xs],Tipo,QT):- contentor(X,_,_,_,_,_,Tipo,Quantidade),
							  	   getLixoContentor(Xs,Tipo,Qt2),
						   	  	   QT is Quantidade + Qt2.
getLixoContentor(_,_,0).

%-----------------------------------------------------------------------------------------

statistics_BFS() :-
    statistics(global_stack, [G1,L1]),
    time(resolve_BFS(15885,Caminho,Dist,Q)),
    statistics(global_stack, [G2,L2]),
    Res is G2 - G1,
    write("Memory: "), 
    write(Res),write("\n"),
	write("Custo: "),write(Dist).

statistics_DFS() :-
    statistics(global_stack, [G1,L1]),
    time(resolve_DFS(15885,_,'all',C,D,Q)),
    statistics(global_stack, [G2,L2]),
    Res is G2 - G1,
    write("Memory: "), 
    write(Res),write("\n"),
	write("Custo: "),write(D).

statistics_DFSLimitada() :-
    statistics(global_stack, [G1,L1]),
    time(resolve_DFSLimitada(15885,C,Ct,5)),
    statistics(global_stack, [G2,L2]),
    Res is G2 - G1,
    write("Memory: "), 
    write(Res),write("\n"),
	write("Custo: "),write(Ct).

statistics_Gulosa() :-
    statistics(global_stack, [G1,L1]),
    time(resolve_gulosaLimitada(15885,C/Ct)),
    statistics(global_stack, [G2,L2]),
    Res is G2 - G1,
    write("Memory: "), 
    write(Res),write("\n"),
	write("Custo: "),write(Ct).

statistics_Aestrela() :-
    statistics(global_stack, [G1,L1]),
    time(resolve_aestrelaLimitada(15885,C/Ct)),
    statistics(global_stack, [G2,L2]),
    Res is G2 - G1,
    write("Memory: "), 
    write(Res),write("\n"),
	write("Custo: "),write(Ct).
%-------------------------------------------------------------------------------
% Pesquisa Não Informada - Primeiro em Profundidade (DFS) => Não Limitado


resolve_DFSCustoBasico(Nodo,[Nodo|Caminho],Custo):- primeiroprofundidadeCusto(Nodo,[Nodo],Caminho,Custo).

primeiroprofundidadeCusto(Nodo, _, [], 0):- goal(Nodo).

primeiroprofundidadeCusto(Nodo,Historico,[NodoProx|Caminho],Custo):-adjacente(Nodo,NodoProx,Custo1),
    																nao(membro(NodoProx, Historico)),
																    primeiroprofundidadeCusto(NodoProx,[NodoProx|Historico],Caminho,Custo2),
																    Custo is Custo1 + Custo2.



%-------------------------------------------------------------------------------
% Pesquisa Não Informada - Primeiro em Largura (BFS)
% resolve_BFS(15885,Caminho,D,Q).


resolve_BFS(Orig,Caminho,Dist,Q):- goal(Dest),
								   resolve_lp(Dest,[[Orig]],Caminho,Dist,15000).

resolve_lp(Dest,[[Dest|T]|_],Caminho,0,Limite):- reverse([Dest|T],Caminho).					

resolve_lp(Dest,[LA|Outros],Caminho,CustoT,Limite):- 	Limite > 0,
														LA=[Act|_],
														findall([X|LA],(Dest\==Act,adjacente(Act,X,_),\+ member(X,LA)),Novos),
														adjacente(Act,X,CustoT1),
														getQtLixo('all',_,Q1,Act), Limite1 is Limite-Q1,
														append(Outros,Novos,Todos),
														resolve_lp(Dest,Todos,Caminho,CustoT2,Limite1),
														CustoT is CustoT1 + CustoT2.




%getQuantidadesLixo([X|Xs]) :- getQtLixo('all',_,Q,Ponto).
%--------------------------------------------------------------------------------------------------------------------------------------------
% Pesquisa Não Informada - Busca Iterativa Limitada em Profundidade
% resolve_DFSLimitada(15885,C,Ct,5).

resolve_DFSLimitada(Origem,Caminho,Custo,Limite):- resolve_DFSLimitada2(Origem,[Origem],Caminho,Custo,Limite,15000).

resolve_DFSLimitada2(Origem,_,[],0,_,_):- goal(Origem).									

resolve_DFSLimitada2(Origem,Historico,[ProxNodo|Caminho],Custo,Limite,Camiao):-
								Limite > 0, 
								Camiao > 0,
								adjacente(Origem,ProxNodo,Custo1),
								nao(membro(ProxNodo,Historico)),
								Limite1 is Limite-1,
								getQtLixo('all',_,Q1,Origem),
								Camiao1 is Camiao-Q1,
								resolve_DFSLimitada2(ProxNodo,[ProxNodo|Historico],Caminho,Custo2,Limite1,Camiao1),
								Custo is Custo1 + Custo2.

%--------------------------------------------------------------------------------------------------------------------------------------------
% Pesquisa Informada - Algortimo da Pesquisa Gulosa
% resolve_gulosa(15885,C).

resolve_gulosa(Nodo,Caminho/Custo) :- estima(Nodo,Estima),
				                      agulosa([[Nodo]/0/Estima],InvCaminho/Custo/_),
				                      inverso(InvCaminho,Caminho).

agulosa(Caminhos, Caminho) :- obtem_melhor_g(Caminhos,Caminho),
                 			  Caminho = [Nodo|_]/_/_,goal(Nodo).								

agulosa(Caminhos,SolucaoCaminho) :- obtem_melhor_g(Caminhos,MelhorCaminho),
				                    seleciona(MelhorCaminho,Caminhos,OutrosCaminhos),								
				                    expande_gulosa(MelhorCaminho,ExpCaminhos),
				                    append(OutrosCaminhos,ExpCaminhos,NovoCaminhos),
				                    agulosa(NovoCaminhos,SolucaoCaminho).

obtem_melhor_g([Caminho], Caminho) :- !.

obtem_melhor_g([Caminho1/Custo1/Est1,_/Custo2/Est2|Caminhos], MelhorCaminho) :- Est1 =< Est2, !,
                                          obtem_melhor_g([Caminho1/Custo1/Est1|Caminhos], MelhorCaminho).

obtem_melhor_g([_|Caminhos], MelhorCaminho) :- obtem_melhor_g(Caminhos,MelhorCaminho).

expande_gulosa(Caminho, ExpCaminhos) :- findall(NovoCaminho,adjacente2(Caminho,NovoCaminho),ExpCaminhos).

%--------------------------------------------------------------------------------------------------------------------------------------------
% Pesquisa Informada - Algortimo da Pesquisa Gulosa LIMITADA
% resolve_gulosaLimitada(15885,C).

resolve_gulosaLimitada(Nodo,Caminho/Custo) :- resolve_gulosa(Nodo,Caminho/Custo),
											  ver_quant(Caminho,Quantidade),
											  Quantidade =< 15000.


%-----------------------------------------------------------------------------------------------------
% Pesquisa Informada - Algortimo da pesquisa A*
% resolve_aestrela(15885,C).

resolve_aestrela(Nodo,Caminho/Custo) :- estima(Nodo,Estima),
									    aestrela([[Nodo]/0/Estima], InvCaminho/Custo/_),
									    inverso(InvCaminho,Caminho).

aestrela(Caminhos,Caminho) :- obtem_melhor(Caminhos,Caminho),
    						  Caminho = [Nodo|_]/_/_,goal(Nodo).

aestrela(Caminhos,SolucaoCaminho) :- obtem_melhor(Caminhos,MelhorCaminho),
								     seleciona(MelhorCaminho,Caminhos,OutrosCaminhos),							
								     expande_aestrela(MelhorCaminho,ExpCaminhos),
								     append(OutrosCaminhos,ExpCaminhos,NovoCaminhos),
								     aestrela(NovoCaminhos,SolucaoCaminho).

obtem_melhor([Caminho], Caminho) :- !.

obtem_melhor([Caminho1/Custo1/Est1,_/Custo2/Est2|Caminhos], MelhorCaminho) :- 
											Custo1 + Est1 =< Custo2 + Est2, !,
											obtem_melhor([Caminho1/Custo1/Est1|Caminhos], MelhorCaminho).

obtem_melhor([_|Caminhos], MelhorCaminho) :- obtem_melhor(Caminhos,MelhorCaminho).

expande_aestrela(Caminho,ExpCaminhos) :- findall(NovoCaminho,adjacente2(Caminho,NovoCaminho), ExpCaminhos).


%-----------------------------------------------------------------------------------------------------
% Pesquisa Informada - Algortimo da pesquisa A* LIMITADA
% resolve_aestrelaLimitada(15885,C).

resolve_aestrelaLimitada(Nodo,Caminho/Custo) :- resolve_aestrela(Nodo,Caminho/Custo),
											  ver_quant(Caminho,Quantidade),
											  Quantidade =< 15000.


% -----------------------------------------------------------------------------------------------------------------------------------------------------
% • Gerar os circuitos de recolha tanto indiferenciada como seletiva, caso existam, que cubram um determinado território;
% caminho_Territorio(15885,_,'all',[15818,15819,15820,15821,15822,15823,15824],C).

caminho_Territorio(Nodo,TipoLixo,Residuo,ListPontosT,[Nodo|Caminho]):- 
													pp_Alg2(Nodo,[Nodo],Caminho,TipoLixo,Residuo,ListPontosT,15000).

pp_Alg2(Nodo,_,[],0,0,TipoLixo,Residuo,_,_):- goal(Nodo).

pp_Alg2(Nodo,Historico,[ProxNodo|Caminho],TipoLixo,Residuo,ListPontosT,Limite):- 
						Limite > 0,
						adjacente(Nodo,ProxNodo,Dist1),
						membro(ProxNodo,ListPontosT),							
						nao(membro(ProxNodo, Historico)),
						getQtLixo(Residuo,TipoLixo,QntLixo1,Nodo),
						Limite1 is Limite - QntLixo1,
						pp_Alg2(ProxNodo,[ProxNodo|Historico],Caminho,QntLixo2,Dist2,TipoLixo,Residuo,ListPontosT,Limite1),
						QntLixo is QntLixo1 + QntLixo2,
						Dist is Dist1 + Dist2.


%pp_Alg2(Nodo,_,[],0,0,TipoLixo,Residuo,_,_).
%pp_Alg2(Nodo,Historico,[],0,0,TipoLixo,Residuo,ListPontosT,Limite):- Limite =< 0,write("Vai ao depósito...").		


% -----------------------------------------------------------------------------------------------------------------------------------------------------
% Resolve um circuito a começar por um ponto, devolve a distância percorrida e a quantidade de lixo levantada, sendo que no máximo são só 15 000L
% • Comparar circuitos de recolha tendo em conta os indicadores de produtividade ou seja a QUANTIDADE e a DISTANCIA
% resolve_DFS(15885,_,'all',C,D,Q).

resolve_DFS(Nodo,TipoLixo,Residuo,[Nodo|Caminho],Dist,Qnt):- pp_Alg(Nodo,[Nodo],Caminho,Qnt,Dist,TipoLixo,Residuo,0).


pp_Alg(Nodo,_,[],0,0,TipoLixo,Residuo,_):- goal(Nodo).

pp_Alg(Nodo,Historico,[ProxNodo|Caminho],QntLixo,Dist,TipoLixo,Residuo,Limite):- 
						adjacente(Nodo,ProxNodo,Dist1),
						nao(membro(ProxNodo, Historico)),
						getQtLixo(Residuo,TipoLixo,QntLixo1,Nodo),
						Limite1 is Limite + QntLixo1,
						Limite1 =< 15000,
						pp_Alg(ProxNodo,[ProxNodo|Historico],Caminho,QntLixo2,Dist2,TipoLixo,Residuo,Limite1),
						QntLixo is QntLixo1 + QntLixo2,
						Dist is Dist1 + Dist2.
% Para voltar ao depósito:
%pp_Alg(Nodo,Historico,[Destino,Destino,ProxNodo|Caminho],QntLixo,Dist,TipoLixo,Residuo,Limite):- getQtLixo(Residuo,TipoLixo,QntLixo1,Nodo),
																				 %Limite1 is Limite + QntLixo1,
																				 %Limite1 >= 15000,write("Vai ao depósito..."),
																				 %estima(Nodo,Dist1),
																				 %Dist is (2 * Dist1), %ida e volta do depósito
																				 %goal(Destino),
																				 %pp_Alg(ProxNodo,[ProxNodo|Historico],Caminho,QntLixo,Dist,TipoLixo,Residuo,0).

% -------------------------------------------------------------------------------------------
% • Comparar circuitos de recolha tendo em conta os indicadores de produtividade ou seja a QUANTIDADE e a DISTANCIA
% 0- DFS
% 1- A*
% 2- Gulosa
% produtividade_circuito(15885,Dist,Quantidade,1).

produtividade_circuito(Nodo,Dist,Quantidade,0) :- resolve_DFS(Nodo,_,'all',[Nodo|Caminho],Dist,Quantidade).

produtividade_circuito(Nodo,Dist,Quantidade,1) :- resolve_aestrelaLimitada(Nodo,Caminho/Dist),
												  ver_quant(Caminho,Quantidade),!.

produtividade_circuito(Nodo,Dist,Quantidade,2) :- resolve_gulosaLimitada(Nodo,Caminho/Dist),
												  ver_quant(Caminho,Quantidade),!.

%...


ver_quant([],0).
ver_quant([X|Xs],Quantidade):- getQtLixo('all',_,QntLixo1,X),
							   ver_quant(Xs,QntLixo2),
							   Quantidade is QntLixo1 + QntLixo2.

% -----------------------------------------------------------------------------------------
% • Identificar quais os circuitos com mais pontos de recolha (por tipo de resíduo a recolher)
% maior_pontosR(15885,'all',_,Caminho,Len).
% maior_pontosR(15885,'seletivo','Lixos',Caminho,Len).
% maior_pontosR(15885,'seletivo','Papel e Cartão',Caminho,Len).
% maior_pontosR(15885,'seletivo','Vidro',Caminho,Len).

maior_pontosR(Nodo,Residuo,Tipo,L,Len) :- findall(Caminho, resolve_DFS(Nodo,Tipo,Residuo,Caminho,D,Q), Lista),
									  	  maxList(Lista,L),
										  length(L,Len).


maxList([X,Xs|T], Res) :-  length(X,Xr), length(Xs,Xsr),
						   Xr > Xsr,
						   maxList([X|T],Res).
maxList([X,Xs|T], Res) :-  length(X,Xr), length(Xs,Xsr),
						   Xr < Xsr,
						   maxList([Xs|T],Res).
maxList([X,Xs|T], Res) :-  length(X,Xr), length(Xs,Xsr),
						   Xr == Xsr,
						   maxList([Xs|T],Res).
maxList([L],L).
	

% -------------------------------------------------------------------------------------------------------
% • Escolher o circuito mais rápido (usando o critério da distância);

circuito_rapidoPI1(Origem,Caminho,Dist) :- produtividade_circuito(Nodo,Dist,Quantidade,1).
circuito_rapidoPI2(Origem,Caminho,Dist) :- produtividade_circuito(Nodo,Dist,Quantidade,2).

circuito_rapidoPNI(Origem,Caminho,Dist) :- produtividade_circuito(Nodo,Dist,Quantidade,0).

% -------------------------------------------------------------------------------------------------------
% • Escolher o circuito mais eficiente (usando um critério de eficiência à escolha);
% • Qual o circuito que recolhe mais lixo por km percorrido?
% circuito_eficientePI2(15885,Caminho,Taxa).

circuito_eficientePI1(Origem,Caminho,Taxa) :- produtividade_circuito(Nodo,Dist,Quantidade,1),
											  Taxa is Quantidade / Dist.
circuito_eficientePI2(Origem,Caminho,Taxa) :- produtividade_circuito(Nodo,Dist,Quantidade,2),
											  Taxa is Quantidade / Dist.
										
circuito_eficientePNI(Origem,Caminho,Taxa) :-  produtividade_circuito(Nodo,Dist,Quantidade,0),
											   Taxa is Quantidade / Dist.