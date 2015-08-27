/* MACRO %Score
Creado: 01/08/05
Modificado: 30/11/05
Autor: Daniel Mastropietro
Titulo: Generacion del score de un modelo de regresion logistica.

Descripcion: Esta macro genera el score generado por un modelo de regresion logistica para nuevas
cuentas.

Ref:
Template Variables.xls:		Documento que describe como definir la tabla que debe pasarse en el 
							parametro TEMPLATE, con las transformaciones de las variables.

USAGE:
%MACRO Score(
	data=, 				*** Input dataset con las cuentas a scorear y las variables transformadas,
						*** necesarias para aplicar el modelo.
	template=, 			*** Template con las variables del modelo y sus transformaciones.
	table=, 			*** Tabla de parametros estimados del modelo.
	rename=,			*** Tabla con el rename de las variables.
	calibration=, 		*** Dataset con la informacion de calibracion.
	out=_score_, 		*** Output dataset con el score.
	summary=_summary_,	*** Output dataset con las variables del modelo sumarizadas.
	id=,				*** Variables ID para conservar en el output dataset.
	pop=ALL,			*** Nombre del sub-modelo al que pertenecen las cuentas a scorear.
	edad=P_EDAD_12, 	*** Nombre de la variable con el horizonte de prediccion.
	time=12,			*** Horizonte de prediccion (en meses).
	keepvars=1			*** Si se desea conservar (=1) o no (=0) las variables del modelo en
						*** el output dataset.
);

********************************************************************************************
Ej:
%Score(
	data=toscore,
	template=score.template,
	table=score.table,
	rename=score.var_rename,
	calibration=score.calibration,
	out=score(label="Score de las cuentas presentes en dataset TOSCORE"),
	summary=summary(label="Distribucion de las variables del modelo para el dataset TOSCORE"),
	id=FOLIO AMBS_CONSECUTIVO DIANA,
	pop=POP1,
	edad=P_EDAD_12,
	time=12,
	keepvars=0
);
********************************************************************************************

PARAMETROS DE ENTRADA:
- data: 		Dataset con las variables originales y las necesarias para aplicar el modelo.
(REQUERIDO)		

- template: 	Dataset con las variables originales usadas en el modelo y sus transformaciones.
(REQUERIDO)		Aqui se describe las columnas que debe tener, pero para mas informacion y
				un ejemplo, ver 'Template Variables.xls'.
				Debe tener las siguientes columnas:
				- VAR:			Nombre de la variable original (luego del rename opcional efectuado 
								segun se indica en la tabla <RENAME>).
								(ej. B_AGE_ALL_MIN)
				- VAR_TRANSF: 	Nombre de la variable transformada (que interviene en el modelo)
								asociada a la variable indicada en VAR.
								(ejs. B_AGE_ALL_MIN_L, IM_B_AGE_ALL_MIN)
				- VALUES:		Valores o rangos correspondientes a cada una de las categoricas
								de variables discretas.
								Los valores y rangos se definen respetando las siguientes reglas:
								- Cada definición de valor o rango debe ir precedido por un operador
								(=, <, >, <=, >=, ~=).
								(Ej: >=1)
								- Usar coma (,)  para separar distintos valores posibles (coma = OR).
								(Ej: =2,>=4)
								- Usar guión (-) para definir rangos (guión = AND). 
								(Ej: >4-<=8)
								- NO DEJAR ESPACIOS en la definición de los valores o rangos.
				- MIN:			Valor minimo permitido para la variable indicada en VAR.
								Dejar vacio si no hay valor minimo.
				- MAX:			Valor maximo permitido para la variable indicada en VAR.
								Dejar vacio si no hay valor maximo.
				- MEAN:			Valor a usar como promedio de la variable en las transformaciones que 
								involucran centrar la variable (es decir, restar la media). Esto ocurre
								para las transformaciones CC, PLC y PCC.
				- MISS:			Valor de reemplazo de los missing.
								En caso de que haya mas de un valor de reemplazo, dependiendo del
								sub-modelo a aplicar, separar los valores por la barra '/'. A lo sumo
								puede haber 2 valores de reemplazo distintos.
								(ejs: -1, -1/0)
				- MISSPOP:		Sub-modelos a los que se aplican los tratamientos de valores missing
								indicados en MISS cuando hay mas de un tratamiento posible.
								Su valor es vacio a menos que haya mas de un tratamiento de missing
								posible para la variable. En tal caso, los nombres de los sub-modelos
								a los que se aplica cada tratamiento indicado en MISS deben separarse
								con la barra '/', sin dejar	espacios.
								(ej: POP1/POP2)
				- TRANSF:		Transformacion a efectuar a la variable original. Se usan codigos
								para indicar dichas transformaciones segun la siguiente tabla:
								- ST:	Sin Transformación
								- RN:	Rename: La variable sólo se renombra, no se transforma
								- TR:	Truncamiento a un rango de valores MIN-MAX
								- CT:	Categorización
								- I0:	Indicadora de 0
								- IM:	Indicadora de Missing
								- IC:	Indicadora de Condición especificada
								- IT:	Interacción entre 2 o más variables
								- DF:	Diferencia: Diferencia entre 2 variables
								- LG:	Logaritmo
								- CD:	Cuadrática
								- CC:	Cuadrática Centrada
								- PL:	Piecewise Lineal: Igual a la variable para el rango indicado
										en la columna CONDITION; 0 en otro caso.
								- PLC: 	Piecewise Lineal Centrada: Igual a la variable centrada para
									   	el rango indicado en la columna CONDITION; 0 en otro caso.
								- PCC: 	Piecewise Cuadrática Centrada: Igual a la variable centrada al
									   	cuadrado para el rango indicado en la columna CONDITION;
										0 en otro caso.

								Puede ocurrir que una variable sea transformada de una forma para un
								sub-modelo y de otra forma para otro sub-modelo. En este caso, se 
								separan los codigos de las transformaciones con la barra '/', sin
								dejar espacios.
								Una variable puede requerir transformarse de a lo sumo 2 formas 
								distintas, lo que quiere decir que solamente puede haber una barra
								separadora.
								(ejs: CD, LG/I0)
				- CONDITION:	Condicion que debe cumplir la variable indicada en VAR (variable
								original) para que sea transformada por las transformaciones IC, PL,
								PLC y PCC. Si la variable no cumple con esta condicion, se le asigna
								el valor 0 a la transformada.
				- TMISS:		Tratamiento a dar a los valores originalmente missing al efectuar la
								transformacion. Puede tomar los dos valores siguientes:
								- IN: 	Se incluyen en la transformacion, es decir el valor de reemplazo
										del missing es tratado como un valor mas.
								- EX 	Se excluyen de la transformacion, es decir la variable
										transformada toma el mismo valor que la variable original
										cuando el valor que esta toma es el valor de reemplazo de 
										los missing.
								IMPORTANTE: Todas las transformaciones distintas a ST, RN y CT deben
								tener un valor en esta columna. Para la transformacion CT
								(Categorizacion) se supone que TMISS = IN.
				- TPOP:			Sub-modelos en los que interviene la variable transformada.
								En caso de que la transformacion a efectuar dependa del sub-modelo en 
								el que interviene (lo cual ocurre cuando en el valor de la variable 
								TRANSF hay una barra '/'), los nombres de los sub-modelos para los que 
								debe efectuarse cada una de las transformaciones indicadas en TRANSF 
								deben separarse con la barra '/', sin dejar espacios.
								(ejs: POP1/POP2)

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

- rename:		Dataset con el rename de las variables.
(OPCIONAL)		Contiene el rename a efectuar a las variables originales llevandolas al
				nombre con el que aparecen en el modelo. Debe tener las siguientes columnas:
				- ORIGINAL:		Nombre original de la variable.
				- NEW:			Nombre nuevo de la variable, segun aparece en la columna VAR del 
								dataset <TEMPLATE>.
				default: <LIBRARY>.var_rename

- id:			Variables ID del input dataset a conservar en el output dataset, adicionalmente
(OPCIONAL)		a las variables del modelo.

- pop:			Nombre de la variable en el dataset <DATA> con la informacion del sub-modelo
(OPCIONAL)		que debe usarse para generar el score de cada cuenta, o bien
				nombre del sub-modelo que debe usarse para generar el score de TODAS las 
				cuentas presentes en el dataset <DATA>.
				Los valores posibles del parametro POP o de la variable <POP> deben 
				corresponderse con los valores de la variable de nombre <POP> presente en la 
				tabla de parametros estimados pasada como parametro TABLE=.
				Si el valor del parametro POP es vacio se supone que hay un unico sub-modelo
				a utilizar para generar el score. En tal caso se asigna como valor de POP
				el valor ALL, el cual aparece en el output dataset.

- edad			Nombre de la variable usada en el modelo para indicar el horizonte de prediccion.
(OPCIONAL)		El valor que toma al momento de generar el score es el valor especificado
				en el parametro TIME.

- time			Horizonte de prediccion (en meses). Establece el periodo asociado a la
(OPCIONAL)		probabilidad de mora estimada. Por ej., si TIME=12, la probabilidad de mora
				estimada indica la probabilidad de que la cuenta entre en mora alguna vez
				en los primeros 12 meses de vida.
				default: 12

- keepvars:		Dice si se desea conservar o no las variables del modelo en el output dataset.
(OPCIONAL)		Valores posibles: 0 => No conservar, 1 => Conservar
				default: 1

PARAMETROS DE SALIDA:
- out:			Dataset con el score y las variables usadas en el modelo.
(OPCIONAL)		Se generan las siguientes variables adicionalmente a las presentes en el
				dataset <DATA>:
				- SCORE:		Score generado para cada cuenta (si el parametro CALIBRATION= no
								es vacio).
				- P:			Probabilidad del evento 90+ dias de mora en el periodo indicado 
								en el parametro TIME de la macro, predicha por el modelo.
				- ODDS:			Odds predicho por el modelo (odds = p/(1-p)).
				- LOGIT:		Log(odds) predicho por el modelo. 
				default: _SCORE_

- summary:		Dataset con informacion sumarizada de las variables del modelo y sus
(OPCIONAL)		transformadas.
				Este dataset tiene las siguientes columnas:
				- N:		Nro. de observaciones usadas en el calculo de los estadisticos
				- MIN:		Valor minimo
				- MAX:		Valor maximo
				- MEAN:		Valor medio
				- P1:		Percentil 1
				- P5:		Percentil 5
				- P10:		Percentil 10
				- P25:		Percentil 25
				- MEDIAN: 	Valor mediano
				- P75:		Percentil 75
				- P90:		Percentil 90
				- P95:		Percentil 95
				- P99:		Percentil 99
				- STDDEV:	Desvio estandar
				- CV:		Coeficiente de Variacion (= Desvio estandar / Media * 100)
				default: _SUMMARY_

SUPUESTOS:
No hay.

MACROS REQUERIDAS:
Macros principales:
- %PrepareToScore
- %GenerateScore

Macros auxiliares (salvo indicacion en contrario, las macros auxiliares indicadas no requieren de
otras macros):
- %Callmacro
- %CreateInteractions
- %EvalExp
- %ExistVar
- %FindMatch			(Usa la macro %GetNroElements y %ReplaceChar) 
- %GetLibraryName
- %GetNobs
- %GetNroElements
- %MakeList
- %MakeListFromName
- %MakeListFromVar
- %Means				(Usa %Callmacro, %GetDataOptions, %GetNobs, %GetLibraryName, 
						%GetNroElements, %GetVarNames, %RemoveFromList)
- %Puts 				(Usa la macro %Rep)
- %RemoveFromList		(Usa %FindInList y %GetNroElements)
- %SelectVar			(Usa la macro %GetNroElements y %ReplaceChar)
*/
&rsubmit;
%MACRO Score(	data=,
				template=,
				table=,
				calibration=,
				rename=,
				out=,
				summary=,
				id=,
				pop=,
				edad=,
				time=12,
				keepvars=1) / store des="Score de un modelo de regresion logistica";
%local i;
%local _data_ data_name out_name summary_name;
%local notes_option;
%local library;
%local original new renamei renamestr nro_renames;
%local error;	%* Indica si hubo un error en el ultimo paso en el que se genera el output 
				%* para decidir si borrar o no el dataset intermedio _SCORE_;

%let notes_option = %sysfunc(getoption(notes));
options nonotes;

/*-------------------------------- Parse input parameters -----------------------------------*/
%*** DATA=;
%* Defino el nombre del input dataset a procesar;
%let _data_ = &data;

%*** OUT=;
%if %quote(&out) = %then %do;
	%let data_name = %scan(&data, 1, '(');
	%let out = _score_(label="Score de las cuentas presentes en %upcase(&data_name)");
%end;

%*** SUMMARY=;
/* Esto lo elimino para que el usuario tenga la opcion de no pasar ningun dataset en SUMMARY=
para que no genere ningun summary dataset.
%if %quote(&summary) = %then %do;
	%let data_name = %scan(&data, 1, '(');
	%let summary = _summary_(label="Distribucion de las variables del modelo para las cuentas presentes %upcase(&data_name)");
%end;
*/

%*** POP=;
%if %quote(&pop) = %then
	%let pop = ALL; 
/*-------------------------------- Parse input parameters -----------------------------------*/


/*--------------------------------- Rename de Variables -------------------------------------*/
%* Rename de las variables a como aparecen en el modelo;
%put;
%put -------------------------- RENAME DE LAS VARIABLES (START) ------------------------------;
%* Leo la library con la ubicacion del dataset con los renames a partir del dataset pasado
%* en TEMPLATE;
%let library = %GetLibraryName(&template);
proc contents data=&data out=_score_varnames_(keep=name) noprint;
run;

%if %quote(&rename) = %then
	%let rename = &library..var_rename;

%if ~%sysfunc(exist(&rename)) %then %do;
	%put;
	%put SCORE: El dataset %upcase(&rename) no fue encontrado.;
	%put SCORE: Ninguna variable del modelo sera renombrada.;
%end;
%else %do;
	%* Busco las variables del input dataset que estan para ser renombradas. Las variables
	%* a renombrar son aquellas que aparecen en la columna ORIGINAL del dataset <RENAME>
	%* pero que ademas su nombre nuevo segun el rename NO aparezca en la columna NEW del
	%* dataset <RENAME>, porque esto significaria que la variable ya aparece con el nuevo nombre
	%* en el dataset a scorear;
	proc sql;
		create table _score_rename_ as
			select * from &rename
				where original in (select name from _score_varnames_) and 
					  not (new in (select name from _score_varnames_));
	quit;
	%let original = %MakeListFromVar(_score_rename_, var=original, log=0);
	%let new = %MakeListFromVar(_score_rename_, var=new, log=0);
	%if %length(&original) > 0 %then %do;
		%CreateInteractions(&original, with=&new, join==, allinteractions=0, macrovar=_renamestr_, log=0);
		%let renamestr = &_renamestr_;
		%* Borro la variable global creada en %CreateInteractions;
		%symdel _renamestr_; quit;

		%* Renombro las variables solicitadas;
		%put SCORE: Renames... (usando la tabla %upcase(&rename));
		data _NULL_;
			set _score_rename_;
			if _N_ = 1 then
				put "Original" @40 "Nueva";
			put original @40 new;
		run;
		data _score_data_;
			set &data;
			rename &renamestr;
		run;
		%* Cambio el nombre del input dataset a procesar que ahora va a ser _score_data_;
		%let _data_ = _score_data_;
	%end;
	%else
		%let renamestr = ;
%end;
%put -------------------------- RENAME DE LAS VARIABLES (END) --------------------------------;
%put;

/*------------------------------- Preparacion de Variables ----------------------------------*/
%put;
%put ---------------------- PREPARACION DE LAS VARIABLES (START) -----------------------------;
%* Macro variable global generada en PrepareToScore que dice si hubo algun error;
%global _err_;
%let _err_ = 1;
%PrepareToScore(
	data=&_data_,
	template=&template, 
	out=&out,
	summary=&summary,
	id=_OBS_ &id,		/* _OBS_ se genera en la macro %PrepareToScore y la quiero conservar */
	pop=&pop,
	edad=&edad,
	time=&time,
	errors=_err_		/* Macro variable global generada en %PrepareToScore */
);
%put ---------------------- PREPARACION DE LAS VARIABLES (END) -------------------------------;
%put;

%if &_err_ %then %do;	/* Si hubo error en la ejecucion de la macro %PrepareToScore */
%put SCORE: ERROR - Se produjo un error en la preparacion de los datos. El score no sera generado;
%end;
%else %do;
%let error = 0;		%* Macro variable que dice si hubo error al generar el dataset de salida;
	/*-------------------------------------- SCORE ------------------------------------------*/
%put;
%put ----------------------------------- SCORE! (START) --------------------------------------;
	%* Defino el nombre de la variable que guarda el nombre de la poblacion o sub-modelo
	%* segun es generada en la macro %PrepareToScore;
	%if ~%ExistVar(_score_, &pop, log=0) %then
		%let pop = pop;
	%GenerateScore(
		data=&out, 
		table=&table, 
		calibration=&calibration,
		out=_score_,
		pop=&pop,
		id=_OBS_ &id
	);

	/*--------------------------------- Output datasets -------------------------------------*/
	options &notes_option;
	%let out_name = %scan(&out, 1, '(');
	data &out;
		format &pop version &id;
		%if %quote(&calibration) ~= %then %do;
		format score;
		%end;
		format p odds logit;
		%if %quote(%upcase(&out_name)) ~= _SCORE_ %then %do;
		merge 	&out
				_score_(keep=_OBS_ &id version %if %quote(&calibration) ~= %then %do; score %end; p odds logit);
		by _OBS_;
		%end;
		%else %do;
		set _score_;
		%end;

		drop _OBS_;
		%if ~&keepvars %then %do;
		keep &pop version &id %if %quote(&calibration) ~= %then %do; score %end; p odds logit;
		%end;
	run;
	%if &syserr %then %do;
		%let error = 1;
		%put SCORE: WARNING - Ocurrio un error en la generacion del dataset de salida %upcase(&out_name).;
		%put SCORE: Ver resultados intermedios en el dataset _SCORE_.;
	%end;
	options nonotes;
%put ----------------------------------- SCORE! (END) ----------------------------------------;
%put;
%end;

proc datasets nolist;
	delete _score_rename_;
	delete _score_varnames_;
	%if %quote(%upcase(&_data_)) = _SCORE_DATA_ %then %do;
	delete _score_data_;
	%end;
	%let out_name = %scan(&out, 1, '(');
	%if %quote(%upcase(&out_name)) ~= _SCORE_ and ~&error %then %do;
	delete _score_;
	%end;
	%let summary_name = %scan(&summary, 1, '(');
	%if %quote(%upcase(&summary_name)) ~= _SUMMARY_ %then %do;
	delete _summary_;
	%end;
quit;
options &notes_option;
%MEND Score;
