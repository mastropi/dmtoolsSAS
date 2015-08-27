/* Modulo IML: Order
Devuelve los indices que corresponden a un vector ordenado en forma ascendente.
*/
&rsubmit;
%MACRO OrderCompile(storage);
%local nro_storage _storage_;
%let nro_storage = %GetNroElements(&storage);
proc iml;
	start Order(x);
		i = rank (x);
		orden = i;
		orden[i,]=(1:nrow(x))`;
		return(orden);
	finish Order;
	%do i = 1 %to &nro_storage;
		%let _storage_ = %scan(&storage , &i , ' ');
		reset storage = &_storage_;
		store module = Order;
	%end;
quit;
%MEND OrderCompile;
