/* MACRO %GenerateScore
Creado: 14/07/05
Modificado: 11/10/05
Autor: Daniel Mastropietro
Titulo: Generacion del score de un modelo de regresion logistica

DESCRIPCION: 
Macro para calcular la probabilidad predicha y el score de un modelo de regresion logistica.

PRECEDENCIAS:
%PrepareToScoreUW2:	Prepara los datos y las variables para generar el score segun el modelo.

USAGE:
%MACRO GenerateScore(
	data=,			*** Input dataset con las cuentas a scorear y las variables transformadas,
					*** necesarias para aplicar el modelo.
	table=,			*** Tabla de parametros estimados para los distintos sub-modelos.
	calibration=, 	*** Dataset con la informacion de calibracion.
	out=_score_, 	*** Output dataset con el score.
	pop=pop,		*** Variable en el dataset <DATA> y en el dataset <TABLE> que tiene la 
					*** informacion del sub-modelo a aplicar para generar el score de cuenta.
	id=				*** Variables ID para conservar en el output dataset.
);

PARAMETROS DE ENTRADA:
- data: 		Dataset con las variables originales y las necesarias para aplicar el modelo.
(REQUERIDO)		Debe tener la variable indicada en el parametro POP= con el identificador del 
				sub-modelo a aplicar para generar el score de cada cuenta.

- table:		Dataset con la tabla de parametros estimados para cada variable transformada
(REQUERIDO)		presente en el modelo y para cada sub-modelo posible.
				Debe tener las siguientes columnas:
				- VAR:			Variable transformada usada en el modelo.
				- ESTIMATE:		Parametro estimado correspondiente a la variable indicada en VAR.

				Adicionalmente, puede tener las siguientes columnas:
				- <POP>:		Nombre del sub-modelo en el que interviene la variable indicada en
								VAR con el parametro estimado indicado en ESTIMATE.
								Su valor puede contener solamente los caracteres permitidos en un
								dataset de SAS, ya que esta macro genera datasets temporarios
								que usan el valor de <POP> en el nombre del dataset.
				- VERSION:		Version del sub-modelo indicado en <POP>.
								Esta variable aparece en el output dataset.
								Si esta variable esta ausente, en su lugar se usa la fecha de
								ejecucion segun es devuelta por la macro variable de sistema SYSDATE
								(que tiene formato ddMONyy).

- calibration: 	Dataset con la informacion de la funcion de la calibracion utilizada para
(OPCIONAL)		generar el SCORE a partir del LOGIT.
				Si no se pasa ningun valor la variable con el SCORE no se genera.
				Debe tener las siguientes columnas:
				- FUNCTION:		Expresion (texto) de la funcion que transforma el LOGIT en SCORE.
								Tipicamente la funcion tiene la forma:
								A*(logit - C) + B, donde:
								A = Pendiente
								B = Intercept
								C = Shift
				- A:			Parametro A de la transformacion indicada en FUNCTION.
				- B:			Parametro B de la transformacion indicada en FUNCTION.
				- C:			Parametro C de la transformacion indicada en FUNCTION.
				- SCORE_MIN:	Minimo valor de score permitido al generar el score (ej. 1).
				- SCORE_MAX:	Maximo valor de score permitido al generar el score (ej. 999).

- id:			Variables ID del input dataset a conservar en el output dataset, adicionalmente
(OPCIONAL)		a las variables generadas por la macro (SCORE, P, ODDS, LOGIT).

PARAMETROS DE SALIDA:
- out:			Dataset con el score y las variables usadas en el modelo.
(OPCIONAL)		Se generan las siguientes variables adicionalmente a las presentes en el
				dataset <DATA>:
				- SCORE:		Score generado para cada cuenta (si el parametro CALIBRATION= no es
								vacio).
				- P:			Probabilidad del evento 90+ dias de mora, predicha por el modelo.
				- ODDS:			Odds predicho por el modelo (odds = p/(1-p)).
				- LOGIT:		Log(odds) predicho por el modelo. 
				default: _SCORE_

SUPUESTOS:
No hay.

MACROS REQUERIDAS:
Salvo indicacion en contrario, las macros requeridas no requieren de otras macros.
- %Callmacro
- %ExistVar
- %GetNobs
- %GetNroElements
- %MakeList
- %MakeListFromVar
- %Means				(Usa %Callmacro, %GetDataOptions %GetNobs, %GetLibraryName, %GetNroElements,
						 %GetVarNames, %RemoveFromList)
- %Puts 				(Usa la macro %Rep)
- %RemoveFromList		(Usa %FindInList y %GetNroElements)
*/
&rsubmit;
%MACRO GenerateScore(	data=,
						table=,
						calibration=,
						out=_score_,
						pop=pop,
						id=)
	/  store des="Generacion del score de un modelo de regresion logistica";
%local i nro_pops popvalues popi var;
%local version;								%* Indica si la variable VERSION esta presente en el dataset <TABLE>;
%local data_name table_name calibration;	%* Nombres de datasets utilizados;
%local fun a b c;							%* Parametros de la calibracion del score;
%local notes_option;

%let data_name = %scan(&data, 1, '(');
%let table_name = %scan(&table, 1, '(');
%put;
%put GENERATESCORE: Dataset con las cuentas a scorear: %upcase(&data_name);
%put GENERATESCORE: Tabla de parametros estimados: %upcase(&table_name);
%if %quote(&calibration) ~= %then %do;
	%let fun = %MakeListFromVar(&calibration, var=function, log=0);
	%let a = %MakeListFromVar(&calibration, var=a, log=0);
	%let b = %MakeListFromVar(&calibration, var=b, log=0);
	%let c = %MakeListFromVar(&calibration, var=c, log=0);
	%let fun = %sysfunc(tranwrd(&fun, a, &a));
	%let fun = %sysfunc(tranwrd(&fun, b, &b));
	%let fun = %sysfunc(tranwrd(&fun, c, &c));
	%put GENERATESCORE: Dataset con la info de calibracion del score: %upcase(&calibration);
	%put GENERATESCORE: Funcion de calibracion: &fun;
%end;

%* Elimino las NOTES;
%let notes_option = %sysfunc(getoption(notes));
options nonotes;

/*================================= 1. Tablas de Parametros =================================*/
%* Hago lo siguiente:
%* - Genero las tablas de parametros para cada sub-modelo (POP) a partir del dataset <TABLE>
%* - Leo las variables de cada sub-modelo.
%* - Verifico que las variables esten presentes en el dataset a scorear e indico en el log
%* las variables que no son encontradas. La ejecucion sigue, por lo que se va a generar un
%* score missing para todas las cuentas que califican en el sub-modelo con error;
%MACRO CreateTables(table, popvalues);
%local i nro_pops nobs popi;

%let nro_pops = %GetNroElements(&popvalues);
%* Separo la tabla de parametros en tantas tablas como POPs haya;
data %MakeList(&popvalues, prefix=_table_);
	set &table;
	select (upcase(&pop));
		%do i = 1 %to &nro_pops;
		when ("%upcase(%scan(&popvalues, &i, ' '))") output _table_%scan(&popvalues, &i, ' ');
		%end;
		otherwise;
	end;
	%* Fecha de la ejecucion en caso de que la variable VERSION no exista en la tabla;
	%if ~%ExistVar(&table, version, log=0) %then %do;
	%let version = 0;
	retain version "&sysdate";
	%end;
	%else %do;
	%let version = 1;
	%end;
	keep &pop version var estimate;
run;

%do i = 1 %to &nro_pops;
	%let popi = %scan(&popvalues, &i, ' ');
	%* Macro variable que dice si la tabla con los parametros estimados para POP&i fue
	%* encontrada, para que esta macro variable pueda ser referenciada cuando creo
	%* arrays en el data step que genera el dataset <OUT>;
	%let table_found&i = 0;
	%Callmacro(getnobs, _table_&popi return=1, nobs);
	%if &nobs = 0 %then
		%put GENERATESCORE: WARNING - No se encontro ninguna tabla de parametros para el sub-modelo %upcase(&popi).;
	%else %do;
		%let table_found&i = 1;
		%* Lectura de las variables del modelo (segun la tabla);
		%let var_reg_&popi = %MakeListFromVar(_table_&popi, var=var, log=0);
		%* Verifico si las variables del modelo estan en el dataset a scorear;
		%put GENERATESCORE: Verificando variables del modelo %upcase(&popi) en el dataset %upcase(&data)...;
		%if %ExistVar(&data, %RemoveFromList(&&var_reg_&popi, Intercept, log=0), macrovar=_notfound_, log=0) %then
			%put GENERATESCORE: ...OK;
		%else %do;
			%put GENERATESCORE: WARNING - Las siguientes variables no fueron encontradas en el dataset %upcase(&data):;
			%puts(&_notfound_);
		%end;
	%end;
%end;
%MEND CreateTables;

%* Leo las POPs que estan en el dataset a scorear. Cada una de estas pops debe tener
%* una tabla con los parametros estimados del modelo que es creada en %CreateTables 
%* y que se llama _TABLE_<POP>;
%put;
%put GENERATESCORE: Lectura de los sub-modelos a los que pertenecen las cuentas a scorear...;
proc sort data=&data_name(keep=&pop) out=_score_nodup_ nodupkey;
	by &pop;
run;
%let popvalues = %MakeListFromVar(_score_nodup_, var=&pop, log=0);
%let nro_pops = %GetNroElements(&popvalues);
%* Defino como LOCAL la macro variable que contiene las variables de cada POP, cuyo valor
%* es asignado en la macro %CreateTables. Hago lo mismo con la macro variable table_found&i;
%do i = 1 %to &nro_pops;
	%let popi = %scan(&popvalues, &i, ' ');
	%local var_reg_&popi;
	%local table_found&i;
%end;

%put GENERATESCORE: Las cuentas a scorear se clasifican dentro de los siguientes sub-modelos:;
%puts(&popvalues);

%* Genero las tablas de parametros correspondientes a cada POP;
%put;
%put GENERATESCORE: Lectura de la tabla con los parametros estimados...;
data _table_;
	%if %quote(%upcase(&popvalues)) = ALL %then %do;
	length &pop $5;
	%end;
	set &table;
	%if %quote(%upcase(&popvalues)) = ALL %then %do;
	&pop = "ALL";
	%end;
run;
%CreateTables(_table_, &popvalues);
/*================================= 1. Tablas de Parametros =================================*/


/*======================================= 2. SCORE ==========================================*/
%* Funcion que transforma el LOGIT en SCORE;
%put;
%put GENERATESCORE: Generacion del score...;
%put FUNCION DE GENERACION DEL SCORE: &fun;
options notes;
data &out;
	format &pop version &id;
	%if %quote(&calibration) ~= %then %do;
	format score;
	%end;
	format p odds logit;
	set &data;

	%****************** Dataset con la calibracion del score ***************;
	%if %quote(&calibration) ~= %then %do;
	if _N_ = 1 then set &calibration(keep=function a b c score_min score_max);
	%end;
	%****************** Dataset con la calibracion del score ***************;

	%****************** Variables de cada sub-modelo indicado en <POP> *************;
	%* Notar que el orden de las variables regresoras es el mismo que el orden en que aparecen
	%* en las tablas con los parametros estimados (_TABLE_&popi) porque de ahi se leyeron
	%* las macro variables var_reg_&popi usadas aqui para definir el ARRAY vars_reg&i que
	%* contiene la lista de variables regresoras;
	%do i = 1 %to &nro_pops;
		%if &&table_found&i %then %do;
			%let popi = %scan(&popvalues, &i, ' ');
			array vars_reg&i{*} &&var_reg_&popi;
		%end;
	%end;
	%****************** Variables de cada sub-modelo indicado en <POP> *************;

	%* Variables para cada POP que dicen si ya se encontro una observacion de la POP correspondiente; 
	array pops_found{*} pop_found1-pop_found&nro_pops;
	retain pop_found1-pop_found&nro_pops 0;

	%****************** Calculo del logit ***************;
	select (upcase(&pop));
		%do i = 1 %to &nro_pops;
		%let popi = %scan(%upcase(&popvalues), &i, ' ');
		when ("&popi") do;
			%* Solamente hago los calculos si la tabla con los parametros estimados fue encontrada;
			%if &&table_found&i %then %do;
			i = &i;
			logit = 0;
			set _table_&popi(keep=version) point=i;
			if ~pops_found(&i) then do;	%* Solo imprimo la ecuacion la primera vez que encuentra un cliente de cada POP;
				put;
				put "Sub-modelo: " &pop;
				put "Version: " version;
				put "Formula: Logit =";
			end;
			do j = 1 to dim(vars_reg&i);
				set _table_&popi(keep=var estimate) point=j;
				select (upcase(var));
					when ("INTERCEPT") do;
						logit = logit + estimate;
						%* Imprimo la formula solamente la primera vez que la POP es encontrada;
						if ~pops_found(&i) then
							put @(2+32+5) Estimate;
					end;
					otherwise do;
						var_name = vname(vars_reg&i(j));
						logit = logit + vars_reg&i(j)*estimate;
						%* Imprimo la formula solamente la primera vez que la POP es encontrada;
						if ~pops_found(&i) then
							put "+ " var_name @(2+32+2) "*" @(2+32+5) Estimate @(2+32+5+15) j;
					end;
				end;
			end;
			%* Digo que la POP encontrada ya fue encontrada para que la formula de generacion
			%* del LOGIT no se imprima otra vez;
			pops_found(&i) = 1;
			%end;
		end;
		%end;
		otherwise
			put "ERROR: El grupo " &pop "no se encontro";
	end;
	%****************** Calculo del logit ***************;

	%****************** Generacion del score ***************;
	%* Probabilidad de Bad Rate;
	%* Primero calculo la P para rangos de LOGIT que no den under u overflow;
	%* Tomo el rango (-20, 20), porque ya para esos valores dan probabilidades muy cerca
	%* de 0 o 1;
	if logit ~= . then do;
		if -20 < logit < 20 then
			p = 1 / (1 + exp(-logit));
		else if logit < 0 then
			p = 0;
		else
			p = 1;
	end;
	%* ODDS;
	if p ~= 1 then
		odds = p / (1 - p);
	else
		odds = .;
	%* SCORE;
	%if %quote(&calibration) ~= %then %do;
	score = round(&fun);		%* La funcion es: score = round(&a*(logit - &logit_max) + &score_min);
	if odds = 0 then
		score = score_max;		%* Mejor cliente, pues odds=0 ocurre cuando p=0;
	else if odds = . and p ~= . then
		score = score_min;		%* Peor cliente, pues odds=. ocurre cuando p=1 (es el odds = infinito);
	if score ~= . then do;
		score = max(score_min, score);
		if score_max ~= . then
			score = min(score, score_max);
	end;
	%end;
	drop var var_name estimate intercept pop_found1-pop_found&nro_pops;

	%* Labels;
	label 	&pop 	= "Poblacion"
			%if &version %then %do;
			version = "Version del modelo"
			%end;
			%else %do;
			version = "Fecha de ejecucion"
			%end;
			p 		= "Probabilidad predicha"
			odds 	= "Odds predicho"
			logit 	= "Log(odds) predicho"
			%if %quote(&calibration) ~= %then %do;
			score_min = "Score minimo posible"
			score_max = "Score maximo posible"
			%end;
			;
	keep &pop version &id p odds logit;
	%if %quote(&calibration) ~= %then %do;
	keep score;
	%end;
%*	drop function a b c score_min score_max;
run;
/*======================================= 2. SCORE ==========================================*/
options nonotes;

proc datasets nolist;
	%do i = 1 %to &nro_pops;
		%let popi = %scan(&popvalues, &i, ' ');
		delete _table_&popi;
	%end;
	delete 	_score_nodup_
			_table_;
quit;

%* Restauro las NOTES options;
options &notes_option;
%MEND GenerateScore;
