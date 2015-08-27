/* COM_MAC_MISCELLANEA.SAS
Version: 		5.0
Creado: 		20/08/06
Modificado:		10/09/06
Autor: 			Daniel Mastropietro
Descripcion:	Macros de utilidad variada

MODIFICACIONES A LA VERSION V1
DM = Daniel Mastropietro

Version		Fecha		Autor	Descripcion	
===================================================================================================
V2			01/09/06	DM		- Se agregaron las macros:
									- %GetDataName
									- %GetLibraryName
V3			08/09/06	DM		- Se agrego la macro:
									- %ComputeError
V4			10/09/06	DM		- Se agrego la macro:
									- %DateMonday
V5			11/09/06	DM		- Se agrego la macro:
									- %CreateExecutionID
===================================================================================================
*/

/*
===================================================================================================
INDICE (en orden alfabetico)
%MACRO ComputeError
	Calcula errores totale y relativos, con y sin signo entre una variable target y una prediccion.

%MACRO CreateExecutionID
	Crea el ID de una ejecucion (ya sea de pronostico de demanda, de pronostico de audiencia o de
	maximizacion de ingresos).

%MACRO DateMonday
	Devuelve la fecha correspondiente al Lunes de la semana en curso o bin del lunes de la semana
	siguiente.

%MACRO GetDataName
	De un string que representa un nombre de dataset, devuelve la parte correspondiente al nombre.

%MACRO GetLibraryName
	De un string que representa un nombre de dataset, devuelve la parte correspondiente al libref.
	Si el string representa un dataset con un solo nivel, devuelve WORK.

%MACRO TimeElapsed
	Muestra el tiempo transcurrido entre dos tiempos en formato mm minutos, ss segundos.
===================================================================================================
*/

/* Macro %ComputError
Genera las siguientes variables en el dataset como medidas del error entre TARGET y PRED:
	- error0: 		error total con signo
	- error0_abs:	error total sin signo
	- error:		error relativo con signo
	- error_abs:	error relativo sin signo
Nota: debe ejecutarse dentro de un data step.
*/
%MACRO ComputeError(target=, pred=) / des="Computes total and relative errors between a target variable and its predicted value";
	format error0 error0_abs 7.1;
	format error error_abs percent7.1;

	error0 = &pred - &target;
	if &target ~= 0 then
		error = error0 / abs(&target);
	else if &pred ~= 0 then
		error = error0 / abs(&pred);
	else
		error = 0;

	error0_abs = abs(error0);
	error_abs = abs(error);
%MEND;


/* Macro %CreateExecutionID
Genera en una macro variable el ID de ejecucion de un proceso.
*/
%MACRO CreateExecutionID(_executionID_);
%local date time;
data _NULL_;
	call symput ('date', put(date(), yymmddn8.));
	time = put(time(), time.);
	blank = index(time, ' ');
	if blank then
	   substr(time, 1, 1) = '0';
	call symput ('time', time);
run;
%let &_executionId_ = &date%sysfunc(compress(&time, ' :'));
%MEND;


/* Macro %DateMonday
Calcula la variable DATEMON como la fecha correspondiente al lunes de la semana en que se encuentra DATE
siempre que el valor de WHICH no sea NEXT. Si WHICH es NEXT calcula la variable DATEMON con la fecha correspondiente
al lunes de la semana siguiente a la semana en que se encuenttra DATE.
*/
%MACRO DateMonday(date=, dateMon=, which=);
	_weekday_ = weekday(&date);
	if _weekday_ = 1 then
		_weekday_ = 7;
	else
		_weekday_ = _weekday_ - 1;
	&dateMon = &date - (_weekday_ - 1);
	%if %upcase(&which) = NEXT %then %do; 
	&dateMon = &dateMon + 7;
	%end;
	drop _weekday_;
%MEND DateMonday;


/* Macro %GetDataName
Devuelve un string con la parte del nombre de una referencia a un dataset.
*/
%MACRO GetDataName(str) / des="Returns the name of a dataset from a string containing options";
%local data_name point_pos;
%let point_pos = %sysfunc(indexc(%quote(&str) , '.'));
%if &point_pos > 0 %then
	%let data_name = %substr(%quote(&str) , &point_pos+1 , %eval(%length(%quote(&str)) - &point_pos));
%else
	%let data_name = &str;
%* Elimino opciones que puedan venir con el dataset;
%let data_name = %scan(&data_name , 1 , '(');
&data_name
%MEND GetDataName;


/* Macro %GetLibraryName
Devuelve un string con la parte del libref de una referencia a un dataset. Si la referencia al dataset
es de un solo nivel, devuelve WORK.
*/
%MACRO GetLibraryName(str) / des="Returns the libref part of a dataset name";
%local library_name point_pos;
%let library_name = WORK;	%* Si no hay libname reference, devuelve WORK;
%let point_pos = %sysfunc(indexc(%quote(&str) , '.'));
%if &point_pos > 0 %then
	%let library_name = %scan(&str , 1 , '.');
&library_name
%MEND GetLibraryName;


/* Macro %TimeElapsed
Devuelve un string con el tiempo transcurrido entre TIME_START y TIME_END, en minutos y segundos.
*/
%MACRO TimeElapsed(time_start, time_end, tag=Tiempo transcurrido, log=1) / des="Displays in minutes and seconds the time elapsed between 2 times";
%local time_elapsed_min;
%local time_elapsed_sec;

%if %quote(&tag) ~= %then
	%let tag = &tag:;

%let time_elapsed = %sysfunc(round(%sysevalf(&time_end - &time_start), 0.1));
%if %sysevalf(&time_elapsed > 60) %then %do;
	%let time_elapsed_min = %sysfunc(floor(%sysevalf(&time_elapsed/60)));
	%let time_elapsed_sec = %sysfunc(round(%sysevalf(&time_elapsed - &time_elapsed_min*60)));
	%if &log %then
		%put &tag: &time_elapsed_min min, &time_elapsed_sec seg;
%end;
%else %do;
	%if &log %then
		%put %quote(&tag: &time_elapsed seg);
%end;
&time_elapsed
%MEND TimeElapsed;
