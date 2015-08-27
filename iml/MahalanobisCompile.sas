/* Modulo IML: Mahalanobis
Calcula las distancias de Mahalanobis para un conjunto de datos.
Se asume que ninguna de las matrices pasadas como parametros tienen missnig values.
Notar que devuelve la distancia de Mahalanobis, no la distancia al cuadrado.

NOTA: (19/12/02, DM) Habria que verificar el valor a usar para la variable tol dentro del modulo
Mahalanobis que define la tolerancia con que se consideran que los autovalores de la matriz de
covarianza son muy chicos.
Actualmente esta' puesta en 1e-10, pero que' hay si todos los autovalores son muy pequenhos? No habria
que usar un valor de tol que refleje el rango de variacion de los autovalores?
*/
&rsubmit;
%MACRO MahalanobisCompile(storage);
%local nro_storage _storage_;
%let nro_storage = %GetNroElements(&storage);
proc iml;
	%*** Loading stored modules;
	start Mahalanobis (mData, mCenter , mCov);
		tol = 1/&sysmaxlong;	%*** Tolerancia para despreciar autovalores al calcular la inversa generalizada;
		mOnesAll = j(nrow(mData),1);
		mInvCov = ginverse(mCov , tol);
		mCenterCopied = mOnesAll * (mCenter);
		mDataStandardAll = mData - mCenterCopied;
		mMahal1 = mDataStandardAll * mInvCov;
		mMahal2 = mMahal1 # mDataStandardAll;
		mMahal = sqrt( mMahal2[,+] );
		return(mMahal);
	finish Mahalanobis;
	%do i = 1 %to &nro_storage;
		%let _storage_ = %scan(&storage , &i , ' ');
		reset storage = &_storage_;
		store module = Mahalanobis;
	%end;
quit;
%MEND MahalanobisCompile;
