%--------------------------------------------------------
% AUXILIARES

membro(X, [X|_]).
membro(X, [_|Xs]):- membro(X, Xs).

nao( Questao ) :- Questao, !, fail.
nao( Questao ).

%--------------------------------------------------------
inverso(Xs, Ys):-
	inverso(Xs, [], Ys).

inverso([], Xs, Xs).
inverso([X|Xs],Ys, Zs):-
	inverso(Xs, [X|Ys], Zs).

seleciona(E, [E|Xs], Xs).
seleciona(E, [X|Xs], [X|Ys]) :- seleciona(E, Xs, Ys).

adjacente2([Nodo|Caminho]/Custo/_,[ProxNodo,Nodo|Caminho]/NovoCusto/Est) :- adjacente(Nodo,ProxNodo,PassoCusto),
										                                    nao(membro(ProxNodo,Caminho)),
										                                    NovoCusto is Custo + PassoCusto,
										                                    estima(ProxNodo,Est).

%----------------------------------------------

list_butlast([X|Xs], Ys) :-                 % use auxiliary predicate ...
   list_butlast_prev(Xs, Ys, X).            % ... which lags behind by one item

list_butlast_prev([], [], _).
list_butlast_prev([X1|Xs], [X0|Ys], X0) :-  
   list_butlast_prev(Xs, Ys, X1).           % lag behind by one