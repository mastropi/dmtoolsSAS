/* MACRO %Dfbetas
Version: 1.01
Author: Daniel Mastropietro
Created: 5-Aug-03
Modified: 13-Mar-05

DESCRIPTION:
Esta macro marca como influyentes aquellas observaciones que tienen
un alto DFBETA en alguno de los parámetros de un modelo de regresión
(ya sea regresión lineal o no lineal).
Recuérdese que el DFBETA se define para cada parámetro de la regresión
y para cada observación interviniente en la modelización, según la siguiente
expresión:

			      Beta_j - Beta_j(i)
	DFBETA_j(i) = ------------------
				  s(i)*sqrt((X'X)_jj)

donde,
Beta_j:	 	es el parámetro j de la regresión estimado con todas las observaciones.
Beta_j(i):	es el parámetro j de la regresión estimado cuando se elimina de la
regresión la observación i.
s(i):		es la estimación del desvío estándar del error, sin tener en cuenta
la observación i.
(X'X)_jj: 	es el elemento diagonal jj de la matrix (X'X)^-1, donde X es la matriz
de diseño del modelo de regresión.

El DFBETA_j(i) mide la variación que produce sobre la estimación del parámetro
Beta_j la eliminación de la observación i de la regresión, relativa al error estándar
de Beta_j.

Para usar esta macro, el procedimiento que efectúa la regresión debe brindar la
posibilidad de generar un dataset con los DFBETAS de la regresión.
Tanto PROC REG como PROC LOGISTIC tienen esta opción.
- En PROC REG, debe usarse la ODS table 'OutputStatistics' y la opción
INFLUENCE del MODEL statement. También es conveniente usar el statement
ODS LISTING EXCLUDE OutputStatistics antes de la creación de la tabla
OutputStatistics, para evitar ver los valores de los DFBETAS en el output.
- En PROC LOGISTIC, el dataset puede generarse de dos maneras:
	- Con la ODS table 'Influence' y la opción INFLUENCE del MODEL statement.
	- Con la opción DFBETAS= del OUTPUT statement.
Ver ejemplos abajo.

Las observaciones influyentes son marcadas por medio de una nueva variable
(cuyo nombre por default es 'influent') que vale 1 si la observacion es
influyente, y 0 en caso contrario.

Si se desea, la macro también hace gráficos de los DFBETAS para cada parámetro
de la regresión, mostrando con otro color las observaciones detectadas como
influyentes.

----------- Metodología usada para la detección de influyentes ----------------
El método seguido para detectar influyentes tiene un cierto carácter iterativo,
a saber:
1.- Se comienza detectando como influyentes aquellas observaciones que tienen
|DFBETA| > THR para algún parámetro de la regresión. THR es el umbral inicial (y máximo),
que típicamente (y por default) es = 1. (Este valor del umbral implica que la variación
producida por la eliminación una observación en un parámetro de la regresión es
mayor que el error estándar del parámetro, generando así un cambio apreciable.)
2.- Se repite el paso 1, con la diferencia de que el umbral, en lugar de ser THR,
pasa a ser THR/2. Son marcadas como influyentes TODAS las observaciones que cumplen
con las siguientes condiciones:
	- Tienen |DFBETA| > THR/2 para algún parámetro.
	- El DFBETA de dicho parámetro tiene el mismo signo (positivo o negativo)
	para todas las observaciones.
	- El número de observaciones que cumplen con estas dos condiciones
	PARA UN MISMO PARÁMETRO multiplicado por el umbral (THR/2) es mayor que THR.
	En este conteo no entran las observaciones ya marcadas como influyentes en
	la iteración anterior.
	(Esto implica que debe haber al menos 2 observaciones con |DFBETA| > THR/2
	entre las observaciones aún no marcadas como influyentes, que tengan
	el mismo signo de DFBETA y que el DFBETA corresponda al mismo parámetro
	para todas las observaciones.)
La lógica detrás de este razonamiento es la siguiente: se eliminan de la
regresión observaciones cuyo DFBETA para un mismo parámetro es mayor que el
umbral, en número tal que, en conjunto, el efecto sobre la estimación de dicho
parámetro al eliminar todas las observaciones es equivalente a tener una sola
observación con |DFBETA| > THR (el umbral inicial, típicamente 1).
3.- Se repite el proceso disminuyendo el umbral al valor THR/3, luego THR/4, etc.,
hasta alcanzar el valor indicado en el parámetro 'iter'. Por default el
parámetro 'iter' es igual a 2 (o sea se llega a considerar como minimo umbral
el valor THR/2).
------------------------------------------------------------------------------

USAGE:
%Dfbetas(
	_data_ ,				*** Input dataset containing the DFBETA values for the variables to analyze
	var= ,					*** List of variables whose DFBETAS are analyzed
	dfbetas= ,				*** Names of the variables in the input dataset containing the DFBETAS
	out= ,					*** Output dataset with all input observations where influential observations are flagged
	thr=1 , 				*** Initial (and maximum) threshold to use for the DFBETAS
	iter=2 ,				*** Maximum number of iterations for the identification of influential observations
	nameInfluent=influent ,	*** Name of variable in output dataset to store a flag of influential observations
	nameIntercept= ,		*** Name of the variable containing the Intercept parameter in the input dataset
	obs= ,					*** Name of variable in input dataset containing the observation ID to use in plot labels
	prefix=dfb_ ,			*** Prefix to add to the variables listed in VAR to build the name of the DFBETA variables
	suffix= ,				*** Suffix to add to the variables listed in VAR to build the name of the DFBETA variables
	macrovar=,				*** Macro variable where the names of the variables containing the DFBETAS are stored
	plot=0 ,				*** Generate plot of influential observations?
	print=0,				*** Show list of influential observations in the output window?
	log=1);					*** Show messages in the log?

REQUIRED PARAMETERS:
- _data_:		Input dataset en donde están guardados los DFBETAS de cada
				observación para cada una de las variables listadas en 'var'.
				Típicamente este dataset es el que se obtiene como salida
				de un procedimiento de regresión lineal o logística, al
				pedir las medidas de influencia sobre cada parámetro (DFBETA).
				En PROC REG el dataset se obtiene con la ODS table OuputStatistics
				y la opción INFLUENCE del MODEL statement.
				En PROC LOGISTIC el dataset se obtiene de dos maneras: con el
				OUTPUT statement y la opción DFBETAS=, o con la ODS table Influence
				y la opción INFLUENCE del MODEL statement.
				Este parámetro puede recibir cualquier opción adicional como en
				cualquier opción data= de SAS.

OPTIONAL PARAMETERS:
- var:			Lista de variables cuyos DFBETAS se encuentran calculados en
				'_data_'. No hace falta indicar el Intercept. Se supone que
				el parámetro correspondiente al intercept está asociado al
				nombre 'Intercept'. De no ser así, su nombre puede indicarse
				en el parámetro 'nameIntercept'.
				Si el parámetro es vacío, la macro detecta observaciones que sean
				influyentes en el Intercept solamente. 
				NOTA: La lista de variables debe coincidir con la lista de
				parámetros estimados, con lo que deben incluirse en esta lista
				los parámetros correspondientes a interacciones entre variables
				(ver ejemplos abajo).

- out:			Output dataset. Puede tener cualquier opción adicional como en
				cualquier opción data= de SAS.
				Este dataset tiene las mismas variables que el input dataset
				más las siguientes nuevas variables:
				- Una variable que indica si la observación es detectada como
				influyente.  El nombre de esta variable es el especificado por el
				parámetro 'nameInfluent'.
				- _THRESHOLD_: Valor de corte para los DFBETAS (en valor absoluto)
				por encima del cual una observacion es considerada influyente.
				- _MAX_DFBETA_: Valor correspondiente al |DFBETA| máximo, con su
				signo.
				- _NRO_LARGE_DFBETAS_: Número de DFBETAS que superaron el umbral
				dado por _THRESHOLD_.
				- _LARGEST_DFBETA_: Nombre de la variable que presenta el |DFBETA|
				más grande para cada observación.
				- _THRESHOLD0_: Valor de corte usado inicialmente para los DFBETAS.
				Corresponde al valor del parámetro 'thr'.

				Si el parámetro 'out' es vacío, estas variables son agregadas al
				input dataset.

- dfbetas:		Lista de las variables que contienen los dfbetas. Cuando se pasa este
				parámetro, se ignoran las variables pasadas en VAR, el parámetro PREFIX
				y el parámetro SUFFIX, que se usan en caso contrario para determinar el
				nombre de las variables con los DFBETAS. También se ignora el parámetro
				nameIntercept, ya que el DFBETA del Intercept se supone que también es
				pasado en el parámetro DFBETAS.

- thr:			Valor a usar inicialmente como umbral para considerar un |DFBETA|
				grande.
				default: 1, es decir se consideran grande un |DFBETA| > 1

- iter:			Número de iteraciones a realizar en la búsqueda de observaciones
				influyentes. La explicación de cómo interviene este parámetro
				en la detección de influyentes se encuentra arriba en el punto
				DESCRIPTION.
				default: 2

- nameInfluent:	Nombre a usar para la variable que marca las observaciones
				influyentes desde el punto de vista de los DFBETAS.
				Valores que toma la variable:
				0 => No influyente
				1 => Influyente
				default: influent

- nameIntercept:Nombre utilizado para indicar el parámetro correspondiente al
				Intercept.
				default: Intercept

- obs:			Nombre de la variable que corresponde al número de observación.
				Si no se pasa ningún valor, la macro genera una variable temporaria
				con el número de observación para hacer los gráficos. Esta variable
				se llama _dfbetas_obs_.

- prefix:		Prefijo que tienen los nombres de todas las variables donde se
				guardan los DFBETAS en el input dataset '_data_'.
				default: dfb_ (este es el prefijo usado por PROC REG)

- suffix:		Sufijo que tienen los nombres de todas las variables donde se
				guardan los DFBETAS en el input dataset '_data_'.

- plot:			Indica si se desea ver los gráficos generados por la macro.
				Valores posibles: 0 => No, 1 => Sí.
				default: 0

- print:		Indica si se desea ver las salidas generadas por la macro en
				el output window.
				En caso afirmativo se muestran las observaciones detectadas como
				influyentes según el criterio de los DFBETAS.
				Valores posibles: 0 => No, 1 => Sí.
				default: 0

- log:			Indica si se desea ver mensajes en el log generados por la macro.
				Valores posibles: 0 => No, 1 => Sí.
				default: 1

- macrovar:		Nombre de la macro variable donde se devuelven los nombres de 
				las variables del input dataset '_data_' con los valores de los
				DFBETAS.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Any
- %Callmacro
- %CheckInputParameters
- %Drop
- %ExistData
- %ExistVar
- %GetNroElements
- %Getnobs
- %GraphXY
- %MakeList
- %MakeListFromName
- %PrintDataDoesNotExist
- %SetSASOptions
- %SymmetricAxis
- %ResetSASOptions

SEE ALSO:
- %CreateInteractions (para armar la lista de variables a pasar en var=)

EXAMPLES:
1.- Detección de influyentes en regresión lineal:
*** Creacion de la variable de interaccion entre z1 y z2 (z1_X_z2) en el dataset TEST;
%CreateInteractions(test , z1 , z2 , join=_X_);
proc reg data=test;
	model y = z1 z2 z1_X_z2 / influence;	* Pide las medidas de influencia;
ods listing exclude OutputStatistics;	* Elimina del output las medidas de influencia;
ods output OutputStatistics=influence;	* Genera el dataset con los DFBETAS;
run;
ods listing;	* Resetea la opcion mostrar todas las salidas generadas en el output;

*** Deteccion de influyentes (a partir del dataset INFLUENCE);
%Dfbetas(influence , var=z1 z2 z1_X_z2 , macrovar=dfbetas);
** En la macro variable &dfbetas se genera la lista de DFBETAS. En este caso
** la lista es: 'dfb_z1 dfb_z2 dfb_z1_X_z2'.
******************************************************************************

2.- Detección de influyentes en regresión logística usando la opción DFBETAS=
del OUTPUT statement:
*** Creacion de la variable de interaccion entre z1 y z2 (z1_X_z2) en el dataset TEST;
%CreateInteractions(test , z1 , z2 , join=_X_);
proc logistic data=test;
	model y = z1 z2 z1_X_z2;
	output out=dfbetas dfbetas=_ALL_;	* Genera el dataset con los DFBETAS;
		** Las variables con los DFBETAS se llaman DFBETA_z1, DFBETA_z2, etc;
run;

*** Deteccion de influyentes (a partir del dataset DFBETAS);
%Dfbetas(dfbetas , var=z1 z2 z1_X_z2 , macrovar=dfbetas);
** En la macro variable &dfbetas se genera la lista de DFBETAS. En este caso
** la lista es: 'dfb_z1 dfb_z2 dfb_z1_X_z2'.
******************************************************************************

3.- Detección de influyentes en regresión logística usando ODS tables:
*** Creacion de la variable de interaccion entre z1 y z2 (z1_X_z2) en el dataset TEST;
%CreateInteractions(test , z1 , z2 , join=_X_);
proc logistic data=test;
	model y = z1 z2 z1_X_z2 / influence;	* Pide las medidas de influencia;
ods listing exclude Influence;	* Elimina del output las medidas de influencia;
ods output Influence=influence;	* Genera el dataset con los DFBETAS;
	** Las variables con los DFBETAS se llaman z1Dfbeta, z2Dfbeta, etc;
run;
ods listing;	* Resetea la opcion mostrar todas las salidas generadas en el output;

*** Deteccion de influyentes (a partir del dataset INFLUENCE);
* Notar que prefix= es vacio y suffix=Dfbeta, porque esta es la forma en que
* las variables con los DFBETAS estan nombradas en el dataset INFLUENCE;
%Dfbetas(influence , var=z1 z2 z1_X_z2 , prefix= , suffix=Dfbeta , macrovar=dfbetas);
** En la macro variable &dfbetas se genera la lista de DFBETAS. En este caso
** la lista es: 'Dfbeta_z1 Dfbeta_z2 Dfbeta_z1_X_z2'.
******************************************************************************

REFERENCES:
- SAS On-line Manual: PROC REG (Details -> Influence Diagnostics) y PROC LOGISTIC
(Details -> Regression Diagnostics).

- Hocking, "Methods and Applications of Linear Models" (1996).
*/
%MACRO Dfbetas(	_data_ ,
				var= ,
				dfbetas= ,
				out= ,

				thr=1 ,
				iter=2 , 

				nameInfluent=influent , 
				nameIntercept=Intercept , 
				obs= ,

				prefix=dfb_ , 
				suffix= , 

				plot=0 ,
				print=0 , 
				log=1 , 

				macrovar= ,

				help=0)
		/ des="Finds influential observations of a regression model with the DFBETA criterion";
/* PARA COMPLETAR:
- (22/9/03) Que la macro haga el analisis BY MODEL. Es decir el PROC REG suele generar el
archivo con las medidas de influence (del ODS OUTPUT OutputStatistics) con una variable
que se llama MODEL, donde se dice a que modelo corresponden las medidas de influencia.
Para hacer esto, hasta ahora lo que hice fue crear la macro variable _byst_. Hacer un
find de _byst_ para ver hasta donde habia llegado.
*/
/*
NOTA 1: Seria interesante que en los graficos en el eje x se mostraran los valores de la variable
cuyos DFBETAS se estan analizando. Sin embargo, esto no es posible asi como esta porque los
valores de las variables se espera que NO vengan con el dataset, sino que solamente vienen
los DFBETAS. Para hacer eso, habria que agregar alguna otra opcion que especifique el dataset
con las variables originales.

NOTA 2: Todas las macro variables locales tienen nombres con underscores porque el parametro macrovar=
recibe el nombre de una macro variable a ser definida como global. El objetivo de los underscores es
minimizar la posibilidad de que haya superposicion entre el nombre de la macro variable especificada en
macrovar y el nombre de alguna macro variable local, lo cual crearia grandes problemas.
*/

/* Macro that displays usage */
%MACRO ShowMacroCall;
	%put DFBETAS: The macro call is as follows:;
	%put %nrstr(%Dfbetas%();
	%put _data_ (REQUIRED), %quote(     *** Input dataset containing the DFBETA values for the variables to analyze);
	%put var= , %quote(                 *** List of variables whose DFBETAS are analyzed);
	%put dfbetas= , %quote(             *** Names of the variables containing the DFBETAS);
	%put out= , %quote(                 *** Output dataset with all input observations where influential observations are flagged);
	%put thr=1 , %quote(                *** Initial (and maximum) threshold to use for the DFBETAS);
	%put iter=2 , %quote(               *** Maximum number of iterations for the identification of influential observations);
	%put nameInfluent=influent , %quote(*** Name of variable in output dataset to store a flag of influential observations);
	%put nameIntercept=Intercept,%quote(*** Name of the variable containing the Intercept parameter in the input dataset);
	%put obs= , %quote(                 *** Name of variable in input dataset containing the observation ID to use in plot labels);
	%put prefix=dfb_ , %quote(          *** Prefix to add to the variables listed in VAR to build the name of the DFBETA variables);
	%put suffix= , %quote(              *** Suffix to add to the variables listed in VAR to build the name of the DFBETA variables);
	%put macrovar= , %quote(            *** Macro variable where the names of the variables containing the DFBETAS are stored);
	%put plot=0 , %quote(               *** Generate plot of influential observations?);
	%put print=0 , %quote(              *** Show list of influential observations in the output window?);
	%put log=1) %quote(                 *** Show messages in the log?);
%MEND ShowMacroCall;

%local _j_ _byst_ _data_name_ _dfbetas_prefix_ _dfbetas_suffix_ _nro_params_ _param_ _params_ _var_order_;
%local
_dfbetas_
_influent_neg_				/* Lista de variables en el dataset _large_dfbetas_ con DFBETAS negativos de parametros que son afectados por obs influyentes */
_influent_pos_				/* Lista de variables en el dataset _large_dfbetas_ con DFBETAS positivos de parametros que son afectados por obs influyentes */
_large_dfbetas_				/* Expresion que permite encontrar obs. con algun dfbeta alto en valor absoluto */
_large_dfbetas_neg_			/* Lista de los datasets temporarios con las obs. con algun dfbeta muy negativo */
_large_dfbetas_pos_			/* Lista de los datasets temporarios con las obs. con algun dfbeta muy positivo */
_max_nro_similar_values_	/* Maximo nro. de iteraciones a realizar en la busqueda de dfbetas altos */
_nobs_neg_					/* Nro. de obs. del dataset con dfbeta muy negativo en c/iteracion y para cada variable (es decir su valor se actualiza para cada variable, por lo que no da el numero total de observaciones con algun dfbeta alto en cada iteracion) */
_nobs_pos_					/* Nro. de obs. del dataset con dfbeta muy positivo en c/iteracion y para cada variable (es decir su valor se actualiza para cada variable, por lo que no da el numero total de observaciones con algun dfbeta alto en cada iteracion) */
_nobs_influent_				/* Nro. de obs. del dataset detectadas como influyentes */
__nobs_influent__			/* Nro. de obs. del dataset detectadas como influyentes en c/iteracion (iter=1, 2, etc.) */
_nro_similar_values_		/* Nro. de obs. que deben tener alto dfbeta p/que una obs. sea considerada influyente */
_thr_						/* Umbral con el que se comparan los dfbetas en cada iteracion */
_stop_;						/* Variable booleana para decidir si seguir iterando en la busqueda de influyentes */


%if &help %then %do;
	%ShowMacroCall;
%end;
%*** Checking existence of input dataset;
%* Note that the existence of &var in input dataset is not carried out because the input
%* dataset has the DFBETAS, not the regressor variables passed in &var;
%else %if ~%CheckInputParameters(data=&_data_ , requiredParamNames=_data_ , macro=DFBETAS) %then %do;
	%ShowMacroCall;
%end;
%else %do;
%* Setting options;
%SetSASOptions;
%* Showing input parameters;
%if &log %then %do;
	%put;
	%put DFBETAS: Macro starts;
	%put;
	%put DFBETAS: Input parameters:;
	%put DFBETAS: - Input dataset = &_data_;
	%put DFBETAS: - var = %quote(          &var);
	%put DFBETAS: - dfbetas = %quote(      &dfbetas);
	%put DFBETAS: - out = %quote(          &out);
	%put DFBETAS: - nameInfluent = %quote( &nameInfluent);
	%put DFBETAS: - obs = %quote(          &obs);
	%put DFBETAS: - prefix = %quote(       &prefix);
	%put DFBETAS: - suffix = %quote(       &suffix);
	%put DFBETAS: - nameIntercept = &nameIntercept;
	%put DFBETAS: - iter = %quote(         &iter);
	%put DFBETAS: - macrovar = %quote(     &macrovar);
	%put DFBETAS: - plot = %quote(         &plot);
	%put DFBETAS: - print = %quote(        &print);
	%put DFBETAS: - log = %quote(          &log);
	%put;
%end;

%*** Setting constants;
%* Numero maximo de valores altos (entre comillas) de DFBETA de similar magnitud e igual signo,
%* que se considera en el analisis de observaciones con alto DFBETA y que establecen el umbral
%* que define que un DFBETA sea alto (ver la definicion de la macro variable &_thr_ para mas
%* informacion);
%let _max_nro_similar_values_ = &iter;
%* Numero total de observaciones detectadas como influyentes;
%let _nobs_influent_ = 0;

%*** Parsing input parameters;
%* DFBETAS;
%if %quote(&dfbetas) ~= %then %do;
	%let var = ;
	%let _params_ = &dfbetas;
	%let _nro_params_ = %GetNroElements(&_params_);
	%let prefix = ;
	%let suffix = ;
	%let _dfbetas_ = &dfbetas;
%end;

%* PREFIX and SUFFIX;
%* Genero estas variables auxiliares simplemente para que se entienda mas que son &prefix y &suffix;
%let _dfbetas_prefix_ = &prefix;
%let _dfbetas_suffix_ = &suffix;

%* VAR;
%if %quote(&var) ~= %then %do;
	%let _params_ = &var;
	%let _nro_params_ = %GetNroElements(&_params_);
	%* Si habia Intercept en el modelo, agrego el correspondiente DFBETA a la lista de DFBETAS;
	%if (%ExistVar(&_data_ , &_dfbetas_prefix_&nameIntercept&_dfbetas_suffix_ , log=0)) %then %do;
		%let _nro_params_ = %eval(&_nro_params_ + 1);
		%let _params_ = &nameIntercept &var;
	%end;
	%let _dfbetas_ = %MakeList(&_params_ , prefix=&_dfbetas_prefix_ , suffix=&_dfbetas_suffix_);
%end;

%* _DATA_NAME_;
%let _data_name_ = %scan(&_data_ , 1 , '(');

%* Exist DFBETAS in &_data_?;
%if ~%ExistVar(&_data_ , &_dfbetas_) %then %do;
	%put;
	%put DFBETAS: ERROR - Not all the DFBETA variables:;
	%put DFBETAS: (%MakeList(%upcase(&_dfbetas_) , sep=%quote( , )));
	%put DFBETAS: exist in %upcase(&_data_name_).;
	%put;
%end;
%else %do; 		%* Macro is executed;
	%if &log %then %do;
		%put;
		%put DFBETAS: Variables analyzed containing the DFBETAS:;
		%put DFBETAS: (%MakeList(%upcase(&_dfbetas_) , sep=%quote( , )));
		%put DFBETAS: Number of different thresholds tried: &iter;
	%end;

	%*** Parsing input parameters;
	%* OBS: Esto es para evitar que el %ExistVar(&_data_ , &obs) de error por ser &obs vacio;
	%if %quote(&obs) = %then
		%let obs = _dfbetas_obs_;

	%* NAMEINFLUENT;
	%* Esta variable es inicialmente seteada en 0, y toma el valor 1 para las observaciones que son
	%* detectadas como influyentes;
	%* Observar que si la variable _influent_ ya existe en el dataset, aqui se sobreescribe;
	%if %quote(&nameInfluent) = %then
		%let nameInfluent = _influent_;

	%* _DATA_;
	%* Leo el orden de las variables en el input dataset para restaurarlas al final de la macro,
	%* ya que aqui separo las variables en dos datasets distintos, el de analisis y el que tiene
	%* las demas variables (esto se hace para agilizar el proceso de calculo);
	%let _var_order_ = %GetVarNames(&_data_);
	%* Ejecuto las opciones que vengan con &_data_ y ademas seteo la variable &nameInfluent = 0;
	data _dfbetas_data_
		(keep=&obs _THRESHOLD_ _MAX_DFBETA_ _NRO_LARGE_DFBETAS_ _LARGEST_DFBETA_ _THRESHOLD0_
			  &var &_dfbetas_ &nameInfluent)
		 _dfbetas_rest_
		(drop=_THRESHOLD_ _MAX_DFBETA_ _NRO_LARGE_DFBETAS_ _LARGEST_DFBETA_ _THRESHOLD0_
			  &var &_dfbetas_ &nameInfluent);
		set &_data_;			%* Aqui se ejecutan todas las opciones que vengan con &_data_;
		%if ~%ExistVar(&_data_ , &obs, log=0) %then %do;
			%if %quote(&obs) ~= _dfbetas_obs_ %then %do;
				%put DFBETA: WARNING - Variable %upcase(&obs) does not exist in %upcase(&_data_name_).;
				%put DFBETA: Creating temporary variable _DFBETAS_OBS_ to use as observation number.;
			%end;
			_dfbetas_obs_ = _N_;
			%let obs = _dfbetas_obs_;
		%end;
		&nameInfluent = 0;
		_THRESHOLD_ = .;
		_MAX_DFBETA_ = .;
		_NRO_LARGE_DFBETAS_ = .;
		length _LARGEST_DFBETA_ $ 32;		%* 32 es el largo maximo del nombre de una variable en SAS;
		_LARGEST_DFBETA_ = "";
		_THRESHOLD0_ = &thr;

		label 	_THRESHOLD_ = "Threshold for large |DFBETA|"
				_MAX_DFBETA_ = "DFBETA with maximum |DFBETA|"
				_NRO_LARGE_DFBETAS_ = "Nro. of large DFBETAS"
				_LARGEST_DFBETA_ = "Variable with largest |DFBETA|"
				_THRESHOLD0_ = "Initial (maximum) threshold for large |DFBETA|";
	run;
	%* Ordeno el dataset por &obs, lo cual es necesario para que ande bien el proceso de deteccion;
	proc sort data=_dfbetas_data_;
		by &obs;
	run;

	%*** Veo si en _dfbetas_data_ hay una variable MODEL que define los distintos modelos creados;
	%*** Esto es util por ejemplo para PROC REG en que se pueden hacer varios analisis en un mismo PROC REG;
	%*** ESTO SIN EMBARGO TODAVIA NO ESTA IMPLEMENTADO, PORQUE HAY QUE HACER LA DETECCION DE INFLUYENTES
	%*** POR CADA VALOR DE MODEL, lo cual todavia no esta hecho;
	%let _byst_ = ;
	%if (%ExistVar(_dfbetas_data_ , model , log=0)) %then
		%let _byst_ = by model;

	%************************************* COMIENZA EL ANALISIS ******************************;
	%*** Busco los dfbetas grandes (inicialmente > &thr en modulo, y luego voy bajando el umbral,
	%*** pero a la vez aumento el numero de observaciones minimo que deben tener DFBETA mayor
	%*** al umbral con el mismo signo, para ser consideradas acom influyentes. El umbral va
	%*** bajando de &thr a &thr/2, &thr/3, etc.
	%*** El proceso para cuando ya no se detectan observaciones influyentes
	%*** segun ese criterio o cuando el numero minimo de influyentes es mayor que
	%*** &_max_nro_similar_values_ (tipicamente = 3) (porque si no me parece que estariamos
	%*** eliminando demasiadas influyentes);
	%* Listas con los datasets que guardan la informacion de DFBETAS muy negativos y muy positivos;
	%let _large_dfbetas_neg_ = %MakeListFromName(_large_dfbetas , length=&_nro_params_ , start=1, step=1, suffix=_neg_);
	%let _large_dfbetas_pos_ = %MakeListFromName(_large_dfbetas , length=&_nro_params_ , start=1, step=1, suffix=_pos_);
	%let _nro_similar_values_ = 0;
	%let _stop_ = 0;
	%do %while (~&_stop_);
		%* Necesito las dos variables que siguen (_influent_neg_ e _influent_pos_) para armar la lista de
		%* variables en el dataset _large_dfbetas_ que indican si una obs tiene DFBETA muy grande para
		%* algun parametro.
		%* Dado un parametro, la variable asociada que indica si hay alguna observacion influyente
		%* en dicho parametro puede no existir en el dataset _large_dfbeta_ si ninguna observacion fue
		%* encontrada con DFBETA grande para ese parametro. Con lo cual tengo que armar una lista de las
		%* variables que si existen y que detectan valores de DFBETA grandes.
		%* Si no armo esta lista, al actualizar el dataset _large_dfbetas_ al final del loop que recorre
		%* los parametros en cada iteracion del while, va a haber error de que algunas variables no estan
		%* inicializadas (en caso de que ninguna observacion tuviese DFBETA grande para alguno de los
		%* parametros);
		%let _influent_neg_ = ;
		%let _influent_pos_ = ;

		%let _nro_similar_values_ = %eval(&_nro_similar_values_ + 1);
		%let _thr_ = %sysevalf(&thr / &_nro_similar_values_);

		%if &log %then %do;
			%put;
			%put DFBETAS: ITERATION &_nro_similar_values_: Threshold = %sysfunc(round(%sysevalf(&thr / &_nro_similar_values_) , 0.001));
			%put DFBETAS: Finding at least &_nro_similar_values_ observation(s) with |DFBETA| > %sysfunc(round(%sysevalf(&thr / &_nro_similar_values_) , 0.001)).;
		%end;

		%* Armo la expresion que compara el valor absoluto de los DFBETAS con &_thr_;
		%let _large_dfbetas_ = (%MakeList(&_dfbetas_ , prefix=%quote(abs%() , suffix=%quote(%)>&_thr_) , sep=%quote( or )));
/*		%* Debugging purposes;
		title "(0) &_data_ where &nameInfluent = 1, NRO_SIMILAR_VALUES = &_nro_similar_values_";
		proc print data=_dfbetas_data_;
			var &obs &_dfbetas_ &nameInfluent;
			where &nameInfluent;
		run;
		title;
*/
		%*** NOTA: En un momento pense que no haria falta crear el dataset _large_dfbetas_ aqui,
		%*** sino que alcanzaba con crear los datasets _neg_ y _pos_ que dicen si una observacion es
		%*** influyente en cada uno de los parametros por separado, y en forma negativa o positiva.
		%*** A partir de estos datasets, se podria crear el dataset _large_dfbetas_ seteando uno
		%*** despues de otro.
		%*** Sin embargo, esto trae dos inconvenientes:
		%*** 1.- Puede haber observaciones repetidas en los distintos datasets _neg_ y _pos_, que 
		%*** aparecerian duplicadas en el dataset _large_dfbetas_ (ya que se setean los datasets uno
		%*** detras del otro).
		%*** 2.- El dataset _large_dfbetas_ seguramente no quedaria ordenado por &obs, lo cual es 
		%*** necesario para despues mergear con _dfbetas_data_;
		data _large_dfbetas_(keep=&obs &_dfbetas_);
			set _dfbetas_data_;
			where &nameInfluent ~= 1 and &_large_dfbetas_;
				%** Considero solo las observaciones que no fueron ya marcadas como influyentes;
		run;
/*		%* Debugging purposes;
		title "(_TEMP_) NRO_SIMILAR_VALUES = &_nro_similar_values_";
		proc print data=_large_dfbetas_;
			var &obs &_dfbetas_;
		run;
		title;
*/
		data &_large_dfbetas_neg_ &_large_dfbetas_pos_;
			set _large_dfbetas_;
			%do _j_ = 1 %to &_nro_params_;
				%let _param_ = %scan(&_params_ , &_j_ , ' ');
				%*** Generacion de _LARGE_DFBETAS&_J_._NEG_ y _LARGE_DFBETAS&_J_._POS_;
				if &_dfbetas_prefix_&_param_&_dfbetas_suffix_ ~= . and &_dfbetas_prefix_&_param_&_dfbetas_suffix_ < -&_thr_ then output _large_dfbetas&_j_._neg_;
				if &_dfbetas_prefix_&_param_&_dfbetas_suffix_ > &_thr_ then output _large_dfbetas&_j_._pos_; 
			%end;
		run;

/*		%* Este %let hay que usarlo si uso los %if &_nobs_<neg/pos>_ >= &_nro_similar_values_
		%* que estan en el %do _j_ de aqui abajo;
		%let _stop_ = 1;	*/
		%do _j_ = 1 %to &_nro_params_;
			%** NEGative large DFBETAS;
			%callmacro(getnobs , _large_dfbetas&_j_._neg_ return=1 , _nobs_neg_);
				%** Observar que los valores missing de DFBETAS no estan considerados aqui ya que
				%** la condicion if que manda observaciones a los datasets _large_dfbetas&_j_ elimina
				%** los valores missing en DFBETAS;
			%if &_nobs_neg_ > 0 %then %do;
				%* Marco las observaciones de _large_dfbetas&_j_._neg_ como candidatas a influyentes o no;
				data _large_dfbetas&_j_._neg_;
					set _large_dfbetas&_j_._neg_;
					_influent&_j_._neg_ = &_nobs_neg_ >= &_nro_similar_values_;
						%** Da 1 si nro. de obs con DFBETA grande, es mayor que el numero minimo requerido;
				run;
				%let _influent_neg_ = &_influent_neg_ _influent&_j_._neg_;
	/*			%* Este %if que sigue hay que usarlo si quiero parar cuando ya no encuentra
				%* influyentes en una iteracion (es decir, no barrer todo el numero de iteraciones
				%* pedidas, sino parar cuando en alguna iteracion ya no encuentra influyentes);
				%if &_nobs_neg_ >= &_nro_similar_values_ %then
					%let _stop_ = 0;
	*/
/*				%* Debugging purposes;
				title "(%upcase(_large_dfbetas&_j_._neg_)) NRO_SIMILAR_VALUES = &_nro_similar_values_ , PARAM = &_j_";
				proc print data=_large_dfbetas&_j_._neg_;
					var &obs &_dfbetas_ _influent&_j_._neg_;
				run;
*/
			%end;

			%** POSitive large DFBETAS;
			%callmacro(getnobs , _large_dfbetas&_j_._pos_ return=1 , _nobs_pos_);
			%if &_nobs_pos_ > 0 %then %do;
				%* Marco las observaciones de _large_dfbetas&_j_._pos_ como candidatas a influyentes o no;
				data _large_dfbetas&_j_._pos_;
					set _large_dfbetas&_j_._pos_;
					_influent&_j_._pos_ = &_nobs_pos_ >= &_nro_similar_values_;
				run;
				%let _influent_pos_ = &_influent_pos_ _influent&_j_._pos_;
	/*			%* Este %if que sigue hay que usarlo si quiero parar cuando ya no encuentra
				%* influyentes en una iteracion (es decir, no barrer todo el numero de iteraciones
				%* pedidas, sino parar cuando en alguna iteracion ya no encuentra influyentes);
				%if &_nobs_pos_ >= &_nro_similar_values_ %then
					%let _stop_ = 0;
	*/
/*				title "(%upcase(_large_dfbetas&_j_._pos_)) NRO_SIMILAR_VALUES = &_nro_similar_values_ , PARAM = &_j_";
				proc print data=_large_dfbetas&_j_._pos_;
					var &obs &_dfbetas_ _influent&_j_._pos_;
				run;
				title;
*/
			%end;
		%end;	%* %do _j_ = 1 %to &_nro_params_;

		%* Elimino de _large_dfbetas_ (que originalmente tiene las observaciones con *algun*
		%* DFBETA > &_thr_ en valor absoluto) aquellas observaciones que no fueron detectadas como
		%* influyentes por no haber tantas de ellas con el mismo signo de DFBETA para la misma
		%* variable. Esta informacion esta guardada en los datasets listados en &_influent_neg_
		%* e &_influent_pos_, donde la variable que indica si la observacion es influyente esta
		%* seteada en 1 o 0 (para todas las observaciones del dataset, este numero es el mismo);
/*		%* Debugging purposes;
		options mprint notes; */
		%if &_influent_neg_ ~= or &_influent_pos_ ~= %then %do;
			data _large_dfbetas_;
				merge 	_large_dfbetas_ 
						&_large_dfbetas_neg_ &_large_dfbetas_pos_;
				by &obs;
				if %any(&_influent_neg_ &_influent_pos_, =, 1);
			run;
			%if &log %then %do;
				%callmacro(getnobs , _large_dfbetas_ return=1 , __nobs_influent__);
				%let _nobs_influent_ = %eval(&_nobs_influent_ + &__nobs_influent__);
				%put DFBETAS: Number of influent observations detected = &__nobs_influent__;
%*				%put DFBETAS: Largest |DFBETA| found = ; %*** (16/1/04) ESTO TODAVIA HAY QUE CALCULARLO (arriba cuando detecto las observaciones influyentes, tengo que calcular el maximo dfbeta)!;
			%end;
		%end;
/*		options nomprint nonotes; */

/*		%* Debugging purposes;
		data _large_dfbetas_;
			merge 	_large_dfbetas_ 
					_large_dfbetas&_j_._neg_(in=_in_neg_) _large_dfbetas&_j_._pos_(in=_in_pos_);
			by &obs;
			if ~_in_neg_ and ~_in_pos_ or _influent_neg_ or _influent_pos_ then output;
		run;
*/

		%* Marco las observaciones influyentes en el input dataset;
/*		title "_TEMP_, NRO_SIMILAR_VALUES = &_nro_similar_values_";
		proc print data=_large_dfbetas_;
			var &obs &_dfbetas_;
		run;
		title;
*/
		data _dfbetas_data_(drop=&_influent_neg_ &_influent_pos_);
			merge _dfbetas_data_ _large_dfbetas_(in=_large_dfbeta_);
			by &obs;
			array dfbetas{*} &_dfbetas_;
			if _large_dfbeta_ then do;
				&nameInfluent = 1;
				%** OJO: No poner ELSE &nameInfluent = 0 porque si asi se hiciera, cambiarían los
				%** valores de &nameInfluent que en iteraciones anteriores habian sido marcados
				%** con el valor 1 (es decir indicando que la observación es influyente);
				_THRESHOLD_ = &_thr_;

				%* Calculo el maximo valor de DFBETA sobre todos los parametros para la
				%* observacion actual;
				%* Notar que tengo que preguntar si el numero de &_dfbetas_ es = 1 porque
				%* si es solamente 1, las funciones min() y max() dan error!!!@&*#$^*(!;
				%if %GetNroElements(&_dfbetas_) = 1 %then %do;
					_dfbetas_min_ = &_dfbetas_;
					_dfbetas_max_ = &_dfbetas_;
				%end;
				%else %do;
					_dfbetas_min_ = min(of &_dfbetas_);
					_dfbetas_max_ = max(of &_dfbetas_);
				%end;
					
				if max(abs(_dfbetas_min_) , _dfbetas_max_) = _dfbetas_max_ then
					_MAX_DFBETA_ = _dfbetas_max_;
				else
					_MAX_DFBETA_ = _dfbetas_min_;
					%** Si, _MAX_DFBETA_ es negativo en caso de que en valor absoluto gane el
					%** negativo sobre el positivo, porque me interesa mostrar su signo;

				%* Cuento el numero de DFBETAS con valores mayores que _THRESHOLD_ en valor absoluto
				%* y marco el nombre del DFBETA que tiene el peor valor de DFBETA (o sea el mas grande
				%* en valor absoluto);
				_NRO_LARGE_DFBETAS_ = 0;
				do _j_ = 1 to dim(dfbetas);
					if abs(dfbetas(_j_)) > _THRESHOLD_ then
						_NRO_LARGE_DFBETAS_  = _NRO_LARGE_DFBETAS_ + 1;
					if dfbetas(_j_) = _MAX_DFBETA_ then do;
						%* Los dos %if que siguen hay que hacerlos porque el PORQUERIZO MALDITO SAS
						%* tiene mal definidas la function length!!! Si el argumento de length es vacio
						%* (entre comillas dobles), la longitud es 1 y no 0!!!! 
						%* !!!!!COMO PUEDEN HACER ALGO ASI!!!???? *Q#&$%&*(@#%$@#?!!!!!;
						%if %quote(&_dfbetas_prefix_) ~= %then %do;
							_length_prefix_ = length("&_dfbetas_prefix_");
						%end;
						%else %do;
							_length_prefix_ = 0;
						%end;
						%if %quote(&_dfbetas_suffix_) ~= %then %do;
							_length_suffix_ = length("&_dfbetas_suffix_");
						%end;
						%else %do;
							_length_suffix_ = 0;
						%end;
						_LARGEST_DFBETA_ = substr(vname(dfbetas(_j_)) , _length_prefix_ + 1 , length(vname(dfbetas(_j_))) - _length_suffix_ - _length_prefix_);
							%** Con substr() elimino el prefijo y el sufijo de los nombres de las variables
							%** que tienen los DFBETAS asi queda solo el nombre de la variable;
					end;
				end;
			end;
			drop _j_ _dfbetas_min_ _dfbetas_max_ _length_prefix_ _length_suffix_;	%* Elimino variables auxiliares;
				%** Los nombres tienen underscores para que disminuir el riesgo de sobreescribir
				%** variables presentes en el input dataset;
		run;
/*		title "(1) _dfbetas_data_ where &nameInfluent = 1, NRO_SIMILAR_VALUES = &_nro_similar_values_";
		proc print data=_dfbetas_data_;
			var &obs &_dfbetas_ &nameInfluent _threshold_;
			where &nameInfluent;
		run;
		title;
*/
		%if &_nro_similar_values_ = &_max_nro_similar_values_ %then %do;
			%let _stop_ = 1;
%*			%put STOPPED BECAUSE _nro_similar_values_ REACHED THE MAXIMUM OF &_max_nro_similar_values_.;
		%end;

	%end;	%* while;
	title;

	%*** Plotting;
	%if &plot %then %do;
		symbol1 color=blue value=dot;
		symbol2 color=red value=dot pointlabel=("#&obs");
		title "DFBETAS (%upcase(&_data_name_))";
		axis1 major=none value=none;
			%** Para evitar superposicion de los tickmarks y de los valores de &obs, que igual aparecen
			%** como labels de los puntos;
		%global _vaxis_;	%* Defino _vaxis_ como global a pesar de que %SymmetricAxis la crea para evitar
							%* problemas de que haya un error en %SymmetricAxis, y &_vaxis_ no sea creada, dando 
							%* error en esta macro;
		%do _j_ = 1 %to &_nro_params_;
			%let _param_ = %scan(&_params_ , &_j_ , ' ');
			%SymmetricAxis(_dfbetas_data_ , var=&_dfbetas_prefix_&_param_&_dfbetas_suffix_ , axis=_vaxis_ , log=0);	%* Crea la macro variable GLOBAL _vaxis_;
			proc gplot data=_dfbetas_data_;
%*				&_byst_;	%* Comente esta linea hasta que haga el proceso iterativo BY MODEL, en caso de que la variable model este en el input dataset;
					%** Ojo que &_data_ tiene que estar ordenado por la variable MODEL!;
					%** Yo no lo ordeno aqui porque llevaria tiempo si hay muchas observaciones.
					%** Ademas si &_data_ es la salida de un PROC que genera una columna MODEL, el dataset
					%** va a estar ordenado por esa variable; 
				plot &_dfbetas_prefix_&_param_&_dfbetas_suffix_*&obs=&nameInfluent / haxis=axis1 vaxis=&_vaxis_ vref=-&thr 0 &thr;
			run;
		%end;
		quit;
		title;
		%if %quote(&obs) ~= %then %do;
			symbol1 pointlabel=none;
			symbol2 pointlabel=none;
		%end;

		%* Deleting global macro variables created;
		%symdel _vaxis_;
		quit;	%* Para evitar problemas con el uso del %symdel;
	%end;

	%if &macrovar ~= %then %do;
		%global &macrovar;
		%let &macrovar = &_dfbetas_;
	%end;

	%*** Output dataset;
	%if %quote(&out) = %then
		%let out = &_data_name_;
			%** Uno de los efectos de esta asignacion de la macro variable &out es que cuando
			%** el parametro out= es vacio, la variable &nameInfluent es agregada al input dataset;
	%* Creacion del output dataset;
	%* Aqui se ejecutan las opciones que vengan con &out. Notar que si out= es vacio, &out pasa
	%* a ser el input dataset, pero solo el nombre, ya que las opciones del input dataset fueron
	%* ejecutadas al crear el dataset _dfbetas_data_;
	%* Notar tambien que se agregan de nuevo las variables que habian sido dropeadas en
	%* _dfbetas_data_ para acelerar los calculos;
	data &out;
		format &_var_order_;
		merge _dfbetas_rest_ _dfbetas_data_;
		by &obs;
		%if %quote(%upcase(&obs)) = _DFBETAS_OBS_ %then %do;
		drop _dfbetas_obs_;
		%end;
	run;
	%if &log %then %do;
		%put;
		%put DFBETAS: Total number of influent observations detected = &_nobs_influent_;
		%if %quote(&out) ~= &_data_name_ %then
			%put DFBETAS: Output dataset %upcase(%scan(&out , 1 , '(')) created.;
		%else
			%put DFBETAS: Results were output to dataset %upcase(&_data_name_).;
		%put DFBETAS: The variables generated by the macro are:;
		%put DFBETAS: - %upcase(&nameInfluent): Indicates if an observation is influent (= 0 or 1).;
		%put DFBETAS: - _THRESHOLD_: Threshold for determining if a DFBETA is large.;
		%put DFBETAS: -	_MAX_DFBETA_: Maximum DFBETA found for the observation (with sign).;
		%put DFBETAS: - _NRO_LARGE_DFBETAS_: Number of DFBETAS found to be large for each observation.;
		%put DFBETAS: - _LARGEST_DFBETA_: Name of the variable with largest DFBETA for each observation.;
		%put DFBETAS: - _THRESHOLD0_: Initial (maximum) threshold used in the iterative detecting process.;
	%end;

	%* Mostrando las observaciones influyentes en el output;
	%if &print %then %do;
		title1 "DFBETAS: Dataset %upcase(&out)";
		title2 "Observations detected as influential";
		proc print data=&out;
			where &nameInfluent;
		run;
		title1;
	%end;

	%* Borrando datasets temporarios;
	proc datasets nolist;
		delete	_dfbetas_data_	
				_dfbetas_rest_
				_large_dfbetas_
				&_large_dfbetas_neg_
				&_large_dfbetas_pos_;
	quit;

	%if &log %then %do;
		%put;
		%put DFBETAS: Macro ends;
		%put;
	%end;

	%ResetSASOptions;
%end;	%* %if ~%ExistVar;

%end;	%* %if ~%CheckInputParameters;
%MEND Dfbetas;
