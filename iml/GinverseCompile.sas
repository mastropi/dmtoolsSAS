%* Ginverse.sas
%* Módulo IML para calcular la inversa generalizada de una matriz cuadrada, usando la
%* descomposición en valores singulares.
%*
%* REQUESTED PARAMETERS:
%* - M:		Matriz cuadrada a invertir.
%* - tol: 	Tolerancia a usar para eliminar autovalores pequeños. Se descartan todos los
%*			autovalores a partir del autovalor para el cual la suma de los autovalores
%*			restantes (incluyéndose) es menor que 'tol'. (Ref: Hugo Scolnik, Golub.)
%*
%* RETURNED VALUES:
%* - Inversa generalizada de la matriz M.
%*;
&rsubmit;
%MACRO GinverseCompile(storage);
%local nro_storage _storage_;
%let nro_storage = %GetNroElements(&storage);
proc iml;
	start Ginverse(M, tol);
		if nrow(M) ^= ncol(M) then do;
			put "GINVERSE: Error - Matrix to invert is not square";
			stop;
		end;
		call eigen(M_eval , M_evec, M);
		p = nrow(M_eval);
		InvM = J(p,p,0);
		if M_eval[1] > 0 then
			do i = 1 to p;
				%*** Notar que conviene sumar los autovalores en este orden para sumar
				%*** los terminos mas chicos, pues 1/M_eval[i] aumenta al aumentar el indice i.
				%*** Notar tambien que el valor maximo de la matriz M_evec[,i]*t(M_evec[,i]) es 1, pues
				%*** todos los coeficientes de M_evec son <= 1 en valor absoluto ya que los autovectores
				%*** tienen norma uno (por lo tanto ninguno de sus coeficientes puede ser > 1 en valor abs.).
				%*** Esto lo digo para indicar que 1/M_eval[i] es una cota superior de los terminos
				%*** que se estan sumando para calcular InvM, es decir una cota superior del valor absoluto
				%*** de los coeficientes de la matriz 1/M_eval[i]*M_evec[,i]*t(M_evec[,i]);
				if sum(M_eval[i:p]/M_eval[1]) > p*tol then
					InvM = InvM + 1/M_eval[i]*M_evec[,i]*t(M_evec[,i]);
			end;
		return(InvM);
	finish Ginverse;
	%do i = 1 %to &nro_storage;
		%let _storage_ = %scan(&storage , &i , ' ');
		reset storage = &_storage_;
		store module = Ginverse;
	%end;
quit;
%MEND GinverseCompile;
