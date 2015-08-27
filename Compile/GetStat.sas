/* MACRO %GetStat
Version: 1.03
Author: Daniel Mastropietro
Created: 21-May-03
Modified: 6-Mar-05

DESCRIPTION:
Calcula un estadístico a partir de variables especificadas en un
dataset y devuelve su valor para cada variable en correspondientes
macro variables globales.

Opcionalmente guarda el estadistico para cada variable especificada en
un output dataset.

Esta macro es útil cuando se desea calcular el valor de un estadístico
de una variable (como la media) para ser utilizado en cálculos dentro de un
data step, ya que evita el largo proceso de calcular dicho estadístico con 
PROC MEANS, y luego mergear el dataset creado con el dataset original.
Además evita la creación de un dataset de mayor tamaño con el valor del
estadístico repetido en cada observación (que es el resultado del merge
mencionado).

NO SIRVE para usar cuando se desea calcular un estadístico por by
variables.

USAGE:
%GetStat(
	_data_ ,		*** Input dataset
	var=_NUMERIC_ ,	*** Lista de variables a utilizar en los calculos
	stat=mean ,		*** Estadistico a calcular (uno solo)
	name= ,			*** Nombres para las macro variables
	prefix= ,		*** Prefijo para los nombres de las macro variables
	suffix= ,		*** Sufijo para los nombres de las macro variables
	weight= ,		*** Variable a usar como peso en el calculo de 'stat'
	out= ,			*** Output dataset con los valores de las macro variables
	macrovar= ,		*** Macro variable global con la lista de macro variables generadas
	log=1);			*** Mostrar mensajes en el log?

REQUESTED PARAMETERS:
- _data_:		Input dataset. Puede recibir cualquier opción adicional como 
				en cualquier opción data= de SAS.

OPTIONAL PARAMETERS:
- var:			Lista de variables para las cuales se calcula el estadistico
				indicado en 'stat'.
				default: _NUMERIC_, es decir todas las variables numéricas.

- stat:			Estadístico solicitado. 
				Puede ser solamente uno y su valor puede ser cualquiera
				de las statistic keywords válidas en PROC MEANS.
				default: mean

- name:			Lista de nombres a usar para las macro variables globales
				generadas. La cantidad de nombres especificada debe ser
				la misma que el número de variables en 'var'.
				IMPORTANTE: Estos nombres no pueden coincidir con ninguno de
				los nombres utilizados para los parámetros de la macro
				(ej: var, stat, etc.), ni tener el símbolo '_' al principio
				y al final del nombre (ej: _var_, etc.).

- prefix:		Prefijo a usar para nombrar las macro variables generadas
				con el valor del estadistico solicitado.

- suffix:		Sufijo a usar para nombrar las macro variables generadas
				con el valor del estadistico solicitado.
				default: mismo nombre que el estadistico solicitado antecedido
				por un '_'. Ej. si stat=stddev, el sufijo es '_stddev'.

- weight:		Variable a usar como peso en el calculo del estadistico
				solicitado. Cumple las mismas funciones que el weight statement
				del PROC MEANS.

- out:			Output dataset donde se guardan los valores de las macro variables
				generadas con los mismos nombres que las macro variables.
				
- macrovar:		Macro variable global con la lista de las macro variables generadas
				donde se guardan los valores calculados.

- log:			Indica si se desea ver mensajes en el log generados por la macro.
				Valores posibles: 0 => No, 1 => Sí.
				default: 1

NOTES:
1.- TRATAMIENTO DE MISSING VALUES
Los missing values no se usan en los calculos de los estadisticos. Son eliminados automaticamente
por la macro PROC MEANS que es invocada para hacer los calculos.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %GetNroElements
- %GetVarList
- %Means
- %ResetSASOptions
- %SetSASOptions

SEE ALSO:
- %Means

EXAMPLES:
1.- Ejemplo de aplicación:
%GetStat(test , var=x y z , weight=peso, macrovar=list);
data test;
	set test;
	xc = x - &x_mean;
	yc = y - &y_mean;
	zc = z - &z_mean;
run;
Genera las macro variables globales x_mean, y_mean, z_mean calculadas como el promedio
ponderado por la variable peso.
Dichos promedios son luego usados en el data step para generar variables xc, yc, zc
centradas.
Tambien genera la macro variable global list con la lista 'x_mean y_mean z_mean', es
decir con la lista de macro variables generadas que contienen el estadistico requerido.

2.- %GetStat(test , var=x y z , stat=stddev , name=var1 var2 var3 , suffix=_std , out=test_stddev);
Genera las macro variables globales var1_std, var2_std, var3_std conteniendo el desvío
estándar de las variables x, y, z. Además almacena dichos valores en el output dataset 
test_stddev, en las variables var1_std, var2_std, var3_std.

3.- %GetStat(test , var=x1 x2 x3 , stat=mean , prefix=mean , out=test_mean);
Genera las macro variables globales mean_x1, mean_x2, mean_x3 con el valor de la media de las
variables x1, x2, x3. Además almacena dichos valores en el output dataset test_mean, en las
variables mean_x1, mean_x2, mean_x3.
*/
&rsubmit;
%MACRO GetStat(_data_ , var=_NUMERIC_ , stat=mean , name= ,
				prefix= , suffix= , weight= , out= , macrovar=, log=1)
		/ store des="Computes a specified statistic on a set of variables and saves the result into global macro variables";
/*
NOTE: THE MACRO VARIABLES RETURNED BY THE MACRO ARE DEFINED AS **GLOBAL**.
THIS IS DONE TO PREVENT THE USER FROM HAVING TO EXPLICITLY DEFINE EACH MACRO VARIABLE THAT IS BEING
RETURNED BEFORE CALLING THE MACRO, IN CASE MANY MACRO VARIABLES ARE GENERATED.
Now, I could avoid defining the returned macro variables as global if there is only one macro variable
being returned, but this is not done in order to keep consistency with the cases of more than one variable
returned, and thus avoid confusion.
This definition as global is not a problem as long as the macro is not called from within another macro.
If the macro were to be called from within another macro, there could be conflicts between locally defined
macro variables (locally to the macro calling %GetStat) and globally defined macro variables.
However, this problem can be avoided if enough care is taken.
Also, note that in such cases, the global macro variables generated should be deleted before
exiting the macro calling %GetStat to avoid the storage of unnecessary global macro variables.
*/
%local
_error_
_i_
_name_
_nro_names_
_nro_stats_
_nro_vars_
_vari_;
%local _out_name_;
%local _macrovar_;		%* List with the global macro variables containing the requested stat;

/*---------------------------------------  %CreateName --------------------------------------*/
%* Macro que crea el nombre de la macro variable global que contiene el estadistico solicitado
%* en STAT=. 
%* La definicion de esta macro es necesaria porque necesito hacer todo este proceso 2 veces,
%* porque el queridisimo SAS nuestro de cada dia no permite mostrar el resultado de la macro
%* variable creada en el data step, dentro del mismo data step...;
%MACRO CreateName(_i_);
%let _vari_ = %scan(&var , &_i_ , ' ');
%if %quote(&name) = %then %do;
	%let _name_ = &_vari_;
	%* Si tanto el parametro prefix como suffix son vacios, se utiliza como nombre de la macro variable
	%* el nombre de la variable analizada seguido de _&stat, donde &stat es el estadistico calculado;
	%if %quote(&prefix) = and %quote(&suffix) = %then
		%let suffix = _&stat;
%end;
%else
	%let _name_ = %scan(&name , &_i_ , ' ');
%let _name_ = &prefix&_name_&suffix;
%* Define como global la macro variable cuyo nombre es el valor de la macro variable _name_.
%* Ej: si &_name_ = x, define la macro variable x como global;
%global &_name_;
%MEND CreateName;
/*-------------------------------------------------------------------------------------------*/

%SetSASOptions;

%* Inicializacion de macro variables locales;
%let _error_ = 0;
%let _name_ = ;

%let _nro_stats_ = %GetNroElements(&stat);
%if &_nro_stats_ > 1 %then %do;
	%put GETSTAT: ERROR - The number of statistics accepted by parameter STAT= is at most 1.;
	%let _error_ = 1;
%end;

%* Parsing the content of &var;
%let var = %GetVarList(&_data_ , var=&var, log=0);

%let _nro_vars_ = %GetNroElements(&var);
%let _nro_names_ = %GetNroElements(&name);
%if &_nro_names_ > 0 and &_nro_names_ ~= &_nro_vars_ %then %do;
	%put GETSTAT: ERROR - The length of the list specified in NAME= does not match the list in VAR= .;
	%let _error_ = 1;
%end;

%if ~&_error_ %then %do;
	%if &log %then	%do;
		%put;
		%put GETSTAT: Macro starts;
		%put;
	%end;

	%*** Calculo del estadistico solicitado para cada variable;
	%Means(&_data_ , out=_GetStat_Stat_ , var=&var , stat=&stat , name=&name , prefix=&prefix , suffix=&suffix , weight=&weight, log=0);
	data _GetStat_Stat_;
		set _GetStat_Stat_;
		%do _i_ = 1 %to &_nro_vars_;
			%CreateName(&_i_);
			call symput("&_name_" , &_name_);
			%* NOTA IMPORTANTE: las comillas DOBLES son importantes en lugar de las SIMPLES,
			%* para que el simbolo & sea interpretado como referencia al valor de una macro variable, 
			%* y no como un caracter mas que forma parte del nombre de la macro variable a crear;
			%let _macrovar_ = &_macrovar_ &_name_;
		%end;
	run;

	%* Muestro el contenido de las macro variables globales generadas con el valor del estadistico solicitado.
	%* Notar que esto lo tengo que hacer luego del datastep porque si no el %put no muestra nada, ya
	%* que es ejecutado en el mismo datastep en que la macro variable fue generada;
	%* Notar que el problema no se puede resolver con la funcion resolve() y un put (en lugar de un %put)
	%* porque en tal caso el put muestra el valor de la ultima macro variable generada. 
	%* Conclusion: UNA PORQUERIA, que lo unico que logra es hacernos PERDER TIEMPO!!!!;
	%if &log %then %do;
		%do _i_ = 1 %to &_nro_vars_;
			%CreateName(&_i_);
			%* The following %IF is to avoid an error when applying the functions TRIM and LEFT
			%* to an empty string;
			%if %quote(&&&_name_) ~= %then
				%put GETSTAT: Global macro variable %upcase(&_name_) created = %sysfunc(trim(%sysfunc(left(&&&_name_))));
			%else
				%put GETSTAT: Global macro variable %upcase(&_name_) created = (empty);
		%end;
		%put;
	%end;

	%if %quote(&out) ~= %then %do;
		data &out;
			set _GetStat_Stat_;
		run;
		%if &log %then %do;
			%let _out_name_ = %scan(&out , 1 , ' ');
			%put;
			%put GETSTAT: Dataset %upcase(&_out_name_) created with the &stat of variables %upcase(&var).;
		%end;
	%end;

	%* Store the list of global macro variables created in macro variable &macrovar;
	%if %quote(&macrovar) ~= %then %do;
		%global &macrovar;
		%let &macrovar = &_macrovar_;
		%if &log %then %do;
			%put;
			%put GETSTAT: Macro variable %upcase(&macrovar) created with the list of macro variables;
			%put GETSTAT: containing the statistic requested for each variable passed in VAR:;
			%put GETSTAT: %upcase(&&&macrovar);
		%end;
	%end;

	proc datasets nolist;
		delete _GetStat_Stat_;
	quit;
%end;	%*** ~&_error_;

%if &log %then %do;
	%put;
	%put GETSTAT: Macro ends;
	%put;
%end;

%ResetSASOptions;
%MEND GetStat;
