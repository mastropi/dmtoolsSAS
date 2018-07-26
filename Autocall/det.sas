/* MACRO %Det
Version: 1.00
Author: Santiago Laplagne
Created: 17-Dec-02
Modified: 02-Jan-03

DESCRIPTION:
Calcula el determinante de una matriz, usando la función det del proc IML.

USAGE:
%Det (data, det =, log = 0);

REQUESTED PARAMETERS:
- data:			Input dataset con los datos a utilizar. Puede recibir
				cualquier opción adicional como en cualquier opción data=
				de SAS.

OPTIONAL PARAMETERS:
- det:			Nombre de la macro variable donde se guarda el valor del 
				determinante. Si no se indica ningún nombre, el valor se 
				imprime en el Output Window.

- log:			Indica si se desea ver mensajes en el log generados por la
				macro.
				Valores posibles: 0 => No, 1 => Sí.
				default: 0

NOTES:
- Para que la macro modifique el valor de la variable indicada en det, ésta
debe haber sido definida previamente. Si la llamada está dentro de una macro 
puede definirse así:
%local determinante;
%Det (datos, det = determinante)

Si la llamada se hace fuera de una macro, puede definirse así:
%let determinate = 0;
%Det (datos, det = determinante)

Si la matriz no es cuadrada el determinante no se puede calcular y se
imprime un mensaje de error en el LOG.

SEE ALSO:
- %Cov
*/
%MACRO Det (data, det =, log = 0)
		/ des="Computes a determinant";
%local data_name _det_;

%if (&log) %then %put DET: macro starts;
%let error = 0;
%let data_name = %scan(&data , 1 , ' ');
proc IML;
	file log;
	use &data;
		read all into mData;
	close &data_name;
	if (nrow(mData)^=ncol(mData)) then do;
		put "DET: ERROR - Matrix is not square.";
		call symput("error", "1");
	end;
	else do;
		det = det (mData);
		call symput("_det_" , char(det));
		%if %quote(&det) = %then %do;
			print det;
		%end;
	end;
quit;
%if %quote(&det) ^= %then %do;
	%let &det = &_det_;
%end;
%if (&log and &error = 0) %then %put DET: The determinant is %sysfunc(left(&_det_));
%if (&log) %then %put DET: macro ends;
%MEND Det;
