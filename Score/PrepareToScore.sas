/* MACRO %PrepareToScore
Creado: 14/07/05
Modificado: 30/11/05
Autor: Daniel Mastropietro
Titulo: Preparacion de los datos para la generacion del score con la macro %Score.

Descripcion: Se define la macro que prepara los datos para generar el score de un modelo de
regresion logistica.
Se siguen los siguientes pasos:
- Se reemplazan los valores missing por valores especificados.
- Se transforman las variables necesarias para aplicar el modelo.

Ref:
Template Variables.xls:		Documento que describe como definir la tabla que debe pasarse en el 
							parametro TEMPLATE, con las transformaciones de las variables.

USAGE:
%PrepareToScore(
	data=, 				*** Input dataset con las cuentas a scorear y las variables originales.
	template=, 			*** Template con las variables del modelo y sus transformaciones.
	out=_toscore_, 		*** Output dataset con las variables transformadas necesarias para el modelo.
	summary=_summary_,	*** Output dataset con las variables del modelo sumarizadas.
	id=,				*** Variables ID a conservar en el output dataset.
	pop=ALL,			*** Nombre del sub-modelo que debe aplicarse para generar el score.
	edad=,			 	*** Nombre de la variable con el horizonte de prediccion.
	time=12,			*** Horizonte de prediccion (en meses).
	errors=_err_		*** Nombre de la macro variable global generada que indica si hubo algun error.
);

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

- id:			Variables ID del input dataset a conservar en el output dataset aparte de las
(OPCIONAL)		variables transformadas.

- pop:			Nombre de la variable en el dataset <DATA> con la informacion del sub-modelo
(OPCIONAL)		que debe usarse para generar el score de cada cuenta, o bien
				nombre del sub-modelo que debe usarse para generar el score de TODAS las 
				cuentas presentes en el dataset <DATA>.
				Los valores posibles del parametro POP o de la variable <POP> deben 
				corresponderse con los valores de la variable de nombre POP presente en la 
				tabla de parametros estimados que se pasa como parametro TABLE= a la macro
				%Score.
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

PARAMETROS DE SALIDA:
- out:			Dataset con los datos a scorear, las variables originales y las variables
(OPCIONAL)		transformadas necesarias para generar el score.
				default: _TOSCORE_

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

- errors		Nombre de la macro variable global generada que indica si hubo algun error.
				Vale 1 si hubo algun error, 0 en caso contrario.
				default: _err_

MACROS REQUERIDAS:
Salvo indicacion en contrario, las macros requeridas no requieren de otras macros.
- %Any
- %EvalExp
- %FindMatch			(Usa la macro %GetNroElements y %ReplaceChar) 
- %GetNroElements
- %MakeList
- %MakeListFromName
- %MakeListFromVar
- %Means				(Usa %Callmacro, %GetDataOptions, %GetNobs, %GetLibraryName, %GetNroElements,
						 %GetVarNames, %RemoveFromList)
- %Puts 				(Usa la macro %Rep)
- %SelectVar			(Usa la macro %GetNroElements y %ReplaceChar)
*/
&rsubmit;
%MACRO PrepareToScore(	data=,
						template=,
						out=_toscore_("Score"),
						summary=_summary_(label="Distribucion de las variables del modelo"),
						id=,
						pop=,
						edad=,
						time=12,
						errors=_err_) / store des="Preparacion de datos para generar score de un modelo";
%local i;
%local var;			%* Lista de variables que aparecen en el modelo y las que son transformadas;
					%* (puede haber duplicados porque varias variables transformadas se generan
					%* a partir de una misma variable original. Ej: I1_x, I2_x, etc.);
%local var_model;	%* Lista de variables del modelo (no duplicados);
%local var_transf;	%* Variables transformadas generadas a partir de las variables listadas en &var;
%local var_transf_many;	%* Variables que se transforman por una transformacion compuesta, es decir
						%* involucrando mas de una variable en la transformacion;
%local var_means;	%* Variables cuya distribucion es calculada al final del proceso;
%local values;		%* Valores tomados por las variables categoricas;
%local var2transf;	%* Lista de variables a transformar, generada a partir de &var, eliminando
					%* las variables que no son transformadas (Transf = ST);
%local var_notfound;%* Lista de variables presentes en el dataset TEMPLATE pero no encontradas en el
					%* input dataset DATA;
%local var2transfi var_transfi;
%local nro_var2transf;

%local data_name;
%local notes_option;
%local exist_pop;	%* Verdadero si la variable &POP existe en el dataset;

%* Macro variables usadas en los PUT de los data steps con el column position de cada info desplegada;
%local pos_miss pos_misspop pos_min pos_max pos_var pos_var2transf pos_var_transf pos_transf;
%* Macro variables usadas en la lectura del LENGTH de ciertas variables;
%local dsid varnum varlen condlen rc;

%global &errors;	%* Macro variable que se usa en %Score para saber si hubo algun error en el 
					%* proceso;
%let &errors = 0;

%let notes_option = %sysfunc(getoption(notes));

/*========================= 0. Lectura de las variables del modelo ==========================*/
options nonotes;
%* Conservo las variables del modelo que estan en el input dataset;
proc contents data=&data out=_contents_ noprint;
run;
%* Agrego una variable con el un nro. de observacion en el dataset <TEMPLATE> para poder restaurar
%* el orden de las variables a transformar segun el orden en que aparecen en <TEMPLATE>. De hecho,
%* al generar el dataset _VAR_TRANSF_ con las variables a transformar, el orden originalmente
%* presente en <TEMPLATE> puede cambiar porque _VAR_TRANSF_ se construye SETeando 3 distintos
%* datasets (ver abajo en la seccion de transformacion de variables cuando se crea el dataset 
%* _VAR_TRANSF_);
data _template_;
	length _OBS_ 4;
	set &template;
	_OBS_ = _N_;
run;
proc sql;
	create table _var_ as
		select * from _template_
		where upcase(var) in (select upcase(name) from _contents_);
	create table _var_rest_ as
		select * from _template_
		where upcase(var) not in (select upcase(name) from _contents_);
quit;
%* Tabla con las variables del input dataset que aparecen en el modelo y con sus correspondientes
%* transformaciones;
%let var = %MakeListFromVar(_var_, var=var, log=0);
%* Tabla con las variables del input dataset que aparecen en el modelo (sin duplicados de VAR
%* como puede ocurrir en el dataset _VAR_). Este dataset se crea para el proceso de tratamiento
%* de missing que se hace sobre las variables originales, antes de ser transformadas;
proc sort data=_var_ out=_var_model_ nodupkey;
	by var;
run;
%** NOTA: Mas adelante guardo la lista de variables del modelo, luego de verificar las variables
%** presentes en las transformaciones compuestas (que tienen un slash (/) en la columna VAR
%** del dataset <TEMPLATE>;
%* Lista de variables no encontradas en el dataset, ya sea porque no se encontraron o porque la
%* columna VAR del dataset <TEMPLATE> lista mas de un variable porque la transformacion asociada
%* es una transformacion que involucra mas de una variable (ej. IT, RT, DF);
data _var_notfound_ _var_transf_many_;
	set _var_rest_;
	%* Guardo en _VAR_TRANSF_MANY_ los registros que tienen un / en VAR, que corresponden
	%* a transformaciones que involucran mas de una variable en el calculo;
	if index(var, "/") then output _var_transf_many_;
	else					output _var_notfound_;
run;
%* Analizo si las variables almacenadas en _VAR_NOTFOUND_ realmente son NOT FOUND porque tal vez
%* algunas de esas variables se encuentran en la columna VAR_TRANSF del dataset <TEMPLATE>, lo que
%* querria decir que deberian ser generadas por medio de una transformacion;
proc sql;
	%* Creo _VAR_NOTFOUND1_ con la lista de variables de _VAR_NOTFOUND_ realmente no encontradas,
	%* en el sentido de que no solo no se encuentran en el input dataset <DATA> sino que
	%* tampoco se encuentran en la columna VAR_TRANSF del dataset <TEMPLATE> (la lista de variables 
	%* no encontradas en el dataset <DATA> ya fue almacenada en _VAR_NOTFOUND_ arriba)
	%* (por ej. puede ser que en _var_notfound_ aparezca una variable transformada por el logaritmo,
	%* simplemente porque esa variable interviene en transformaciones posteriores, pero en este caso
	%* es de esperar que dicha variable aparezca como variable a generar en la columna VAR_TRANSF de
	%* la tabla <TEMPLATE> y que no se encuentre en el input dataset);
	create table _var_notfound1_ as
		select * from _var_notfound_
		where upcase(var) not in (select upcase(var_transf) from _template_);
	%* Creo _VAR_FOUND1_ con el complemento de _VAR_NOTFOUND1_ (es decir las variables no encontradas
	%* en el input dataset pero encontradas en la columna VAR_TRANSF de <TEMPLATE>;
	create table _var_found1_ as
		select * from _var_notfound_
		where upcase(var) in (select upcase(var_transf) from _template_);
	%* Creo _VAR_FOUND1_NOTFOUND_ con las variables que fueron encontradas en la columna VAR_TRANSF
	%* de <TEMPLATE> pero cuya correspondiente variable original no fue encontrada en el
	%* input dataset (estas son las variables que estan en el dataset _VAR_NOTFOUND1_, creado recien),
	%* con lo que no seria posible generar la variable transformada ya que la
	%* variable original no existe! El nombre de la variable original correspondiente a la variable
	%* VAR_TRANSF en cuestion es tomado de la columna VAR del dataset _VAR_FOUND1_;
	create table _var_found1_notfound_ as
		select * from _var_found1_
		where upcase(var) in (select upcase(var) from _var_notfound1_);
quit;
%* Lista de variables que intervienen en las transformaciones compuestas almacenadas en 
%* _VAR_TRANSF_MANY_ para agregar a la lista de las variables originales presentes en el modelo
%* y asi poder generar las indicadoras de missing, pues estas se usan en el
%* calculo de la variable transformada para chequear si el valor de las variables intervinientes
%* en la transformacion no es missing antes de aplicar la transformacion;
%let var_transf_many = %MakeListFromVar(_var_transf_many_, var=var, log=0);
%if %length(&var_transf_many) > 0 %then %do;
	%* Elimino las barras (/) del valor de VAR para saber cuales son las variables originales
	%* a usar en la transformacion compuesta;
	%let var_transf_many = %sysfunc(tranwrd(&var_transf_many, /, %quote( )));
	%* Elimino repetidos y guardo en _VAR_TRANSF_MANY_ORIG_ la lista de variables originales
	%* listadas en los strings con / de _VAR_TRANSF_MANY_;
	data _var_transf_many_orig_;
		length var $32;
		%do i = 1 %to %GetNroElements(&var_transf_many);
		var = "%scan(&var_transf_many, &i, ' ')";
		output;
		%end;
	run;
	%* Elimino duplicados;
	proc sort data=_var_transf_many_orig_ nodupkey;
		by var;
	run;
	%let var_transf_many_ = %MakeListFromVar(_var_transf_many_orig_, log=0);
	proc sql;
		%* Creo _VAR_MODEL2_ con la lista de variables de _VAR_TRANSF_MANY_ORIG_ encontradas en el
		%* input dataset que no fueron ya encontradas antes (que son las almacenadas en el dataset
		%* _VAR_MODEL_); 
		create table _var_model2_ as
			select var from _var_transf_many_orig_
			where 	upcase(var) in (select upcase(name) from _contents_) and
					upcase(var) not in (select upcase(var) from _var_model_);
		%* Creo _VAR_NOTFOUND2_ con las variables no encontradas en el input dataset pero tampoco
		%* encontradas en la columna VAR_TRANSF de <TEMPLATE>, lo que indicaria que son generadas
		%* por alguna transformacion;
		create table _var_notfound2_ as
			select var from _var_transf_many_orig_
			where upcase(var) not in (select upcase(name) from _contents_) and
				  upcase(var) not in (select upcase(var_transf) from _template_);
		%** NOTAR que ahora no puedo hacer lo mismo que hago arriba donde verifico si 
		%** hay variables de _VAR_TRANSF_MANY_ORIG_ que si bien no se encuentra en el input dataset
		%** son encontradas en la columna VAR_TRANSF de <TEMPLATE>, y luego verifico si estas 
		%** variables realmente pueden ser generadas por una transformacion de variables que SI
		%** estan en el input dataset, porque _VAR_TRANSF_ORIG_ NO tiene registros del dataset
		%** TEMPLATE con la informacion de las variables originales y transformadas sino que tiene
		%** solamente una columna, con las variables originales presentes en los strings con / que 
		%** definen las transformaciones compuestas. Esto es asi por la naturaleza de las
		%** transformaciones compuestas que involucran mas de una variable en la transformacion;
	quit;
	%* Agrego al dataset _VAR_MODEL_ y a la macro variable &var_model la lista de variables
	%* presentes en _VAR_MODEL2_, para que asi se puedan generar las 
	%* indicadoras de missing en el data step con el tratamiento de los missing;
	%* NOTAS:
	%* - El dataset _VAR_MODEL2_ solamente tiene una columna que es la columna con el
	%* nombre de las variables, no hay informacion sobre el tratamiento de missing y esas cosas
	%* como SI ocurre para el dataset _VAR_MODEL_. Si uno necesita hacer tratamientos
	%* a las variables usadas en las transformaciones compuestas (que son las listadas en _VAR_MODEL2_)
	%* hay que agregar al dataset <TEMPLATE> una fila que muestre dichos tratamientos;
	%* - Hay que agregar la lista de variables listadas en _VAR_MODEL2_ tanto al dataset _VAR_MODEL_
	%* como a la macro variable &var_model, para que no dE un error de SUBSCRIPT OUT OF RANGE en
	%* el data step donde se tratan los valores missing, ya que en dicho data step se define un array
	%* con las variables presentes en &var_model y luego se lee el dataset _VAR_MODEL_ accediendo a 
	%* la observacion dada por el indice de dicho array!;
	data _var_model_;
		set _var_model_ _var_model2_;
	run;
%end;
%* Genero la lista de variables originales presentes en el modelo;
%let var_model = %MakeListFromVar(_var_model_, var=var, log=0);
%* Actualizo _VAR_NOTFOUND_ juntando la informacion de _VAR_NOTFOUND1_, _VAR_FOUND1_NOTFOUND_
%* _VAR_NOTFOUND2_ y _VAR_FOUND2_NOTFOUND_;
data _var_notfound_;
	set _var_notfound1_
		_var_found1_notfound_
		%if %sysfunc(exist(_var_notfound2_)) %then %do;
		_var_notfound2_
		%end;;
run;
%* Variables a transformar en segunda ronda (o sea cuyo calculo depende de una variable transformada);
proc sql;
	%* Creo _VAR_TRANSF2_ con la lista de variables en la columna VAR de _VAR_REST_ que estan en la 
	%* columna VAR_TRANSF de <TEMPLATE>, lo cual indica que no son variables originales sino que
	%* son variables transformadas;
	create table _var_transf2_ as
		select * from _var_rest_
		where upcase(var) in (select upcase(var_transf) from _template_);
	%* Elimino las variables en _VAR_TRANSF2_ que no fueron encontradas en el input dataset
	%* y que por lo tanto estan en _VAR_NOTFOUND_;
	create table _var_transf2_ as
		select * from _var_transf2_
		where upcase(var) not in (select upcase(var) from _var_notfound_);
quit;

%let var_notfound = %MakeListFromVar(_var_notfound_, var=var, log=0);
%if %length(&var_notfound) > 0 %then %do;
	%put PREPARETOSCORE: WARNING - Las siguientes variables que aparecen en;
	%put PREPARETOSCORE: %upcase(&template) no fueron encontradas en el input dataset;
	%put PREPARETOSCORE: %upcase(&data):;
	%puts(&var_notfound)
	%put;
%end;
options &notes_option;
/*========================= 0. Lectura de las variables del modelo ==========================*/


/*=========================== 1. Tratamiento de Missing (START) =============================*/
%*** Hago el reemplazo de missing indicado en el dataset <TEMPLATE> a las variables del modelo;
%if %length(&var_model) = 0 %then %do;
	%put PREPARETOSCORE: Las variables presentes en el dataset %upcase(&data);
	%put PREPARETOSCORE: no se encontraron en la lista de variables del modelo leidas de;
	%put PREPARETOSCORE: %upcase(&template). NO HAY VARIABLES A TRANSFORMAR.;
	%put;
%end;
%else %do;
%*** Comienza el proceso de transformacion;
%* Agrego la variable de EDAD que define el horizonte de estimacion en caso de que
%* sea pasada como parametro;
%if %quote(&edad) ~= %then %do;
	%if ~%FindInList(&var_model, &edad, log=0) %then %do;
		%let var_model = &var_model &edad;
		%* Agrego el nombre de EDAD en el dataset _VAR_MODEL_ para que sea leido en el
		%* tratamiento de missing;
		data _var_model_;
			set _var_model_ end=lastobs;
			if lastobs then do;
				output;
				var = "%upcase(&edad)";
				%* Defino horizonte de observacion como el valor de reemplazo de los missing
				%* ya que si la variable no existe en la lista de variables del modelo, la misma sera
				%* inicializada en missing en el data step siguiente y el missing sera reemplazado
				%* por el valor indicado en la columna MISS;
				%if %quote(&time) ~= %then %do;
				miss = &time;
				%end;
				%else %do;
				miss = 12;
				%end;
			end;
			output;
		run;
	%end;
%end;
%put;
%put VARIABLES DEL MODELO A PREPARAR:;
%puts(&var_model);

%put;
%put;
%put PREPARETOSCORE: Lectura de los datos a scorear...;
%let exist_pop = 0;
%if %quote(&pop) = %then
	%let pop = ALL;
%else
	%let exist_pop = %ExistVar(&data, &pop, log=0);
%if ~&exist_pop and %upcase(&pop) ~= ALL %then %do;
	%put;
	%put PREPARETOSCORE: WARNING - La variable %upcase(&pop) con la informacion del sub-modelo;
	%put PREPARETOSCORE: no fue encontrada en el dataset %upcase(&data);
	%put PREPARETOSCORE: Se supondra que %upcase(&pop) es el nombre del sub-modelo a utilizar para;
	%put PREPARETOSCORE: generar el score.;
%end;

options notes;
data &out;
	%if &exist_pop %then %do;
	format &pop;
	set &data;
	pop = &pop;	%* Copio &POP a POP para poder referenciar la variable con la informacion
				%* del sub-modelo con la variable POP;
	%end;
	%else %do;
	format pop;
	set &data;
	pop = "%upcase(&pop)";
	%let pop = pop;	%* Convierto el valor de la macro variable POP del valor que representaba
					%* el sub-modelo al nombre de la variable que guarda el sub-modelo (POP)
					%* porque mas adelante voy a usar &POP para referenciar al nombre	
					%* de la variable que guarda el sub-modelo NO para referenciar el nombre
					%* del sub-modelo aplicado;
	%end;
	%let dsid = %sysfunc(open(_var_model_));
	%let varnum = %sysfunc(varnum(&dsid, misspop));
	%let varlen = %sysfunc(varlen(&dsid, &varnum));
	%let rc = %sysfunc(close(&dsid));
	%if &varlen = 1 %then %do;
		length misspop $3;
		%let varlen = 3;
	%end;
	%if %index(%quote(%upcase(&id)), _OBS_) %then %do;
	_OBS_ = _N_;		%* Esta variable ID se usa en la macro %Score;
	%end;

	%************************ Tratamiento de los valores missing *****************************;
	%put PREPARETOSCORE: Tratamiento de valores missing y truncamiento a rango MIN-MAX...;
	array vars{*} &var_model;
	%* Indicadoras de missing: las necesito para despues distinguir si tengo que transformar
	%* el valor de reemplazo del missing segun la variable TMISS;
	array IM_vars{*} %MakeList(&var_model, prefix=IM_);
	%let pos_var = %eval(1+3+1);
	%let pos_miss = %eval(&pos_var + (32+1));
	%let pos_misspop = %eval(&pos_miss + (%length(Miss Replacement)+3));
	%let pos_min = %eval(&pos_misspop + (%length(POP Replacement)+1));
	%let pos_max = %eval(&pos_min + (10+1));	%* 10 es el width del formato usado para mostrar MIN y MAX;
	if _N_ = 1 then
		put "#" @&pos_var "Variable" @&pos_miss "Miss Replacement" @&pos_misspop "POP Replacement" @%eval(&pos_min+(10-%length(Min))) "Min" @%eval(&pos_max+(10-%length(Max))) "Max";

	%* Si el parametro EDAD= no es vacio, seteo su valor al valor pasado en TIME=,
	%* para que siempre use ese valor en la variable indicada en EDAD= al generar el score;
	%if %quote(&edad) ~= %then %do;
	&edad = &time;
	%end;

	do i = 1 to dim(vars);
		%* Leo el valor de la columna miss en el dataset <TEMPLATE> correspondiente a la variable i,
		%* para saber como tratar los missing;
		set _var_model_(keep=miss misspop min max transf) point=i;
		if _N_ = 1 then do;
			vname = vname(vars(i));
			if misspop = "" then misspop = "ALL";
			put i @&pos_var vname @&pos_miss miss @&pos_misspop misspop @&pos_min min /*E10.2*/ best10. @&pos_max max /*E10.2*/ best10.;
				%** Para MIN y MAX se podria usar el formato E10.2 porque esto permite representar con 2 decimales los
				%** numeros minimo y maximo representables en doble precision -1.00E-308 a 1.00E+308.
				%** El problema con este formato es que los numeros se ven muy feos, sobre todos los
				%** numeros mas comunes que actuarian como topes (por ej. 0);
		end;

		%* Inicializo la indicadora de missing a 0;
		IM_vars(i) = 0;

		%* Trunco los valores de la variable al MIN y MAX indicados en _VAR_MODEL_;
		%* Notar que si alguno de los valores MIN o MAX o ambos son missing, el valor original
		%* de la variable no se ve modificado tras la aplicacion de la funcion correspondiente;
		%* Sin embargo, si vars(i) = . entonces el valor es reemplazado por los valores min o max;
		if vars(i) ~= . then do;
			if ~index(upcase(transf), "TR") then
				vars(i) = min( max(vars(i), min), max );
		end;

		%* Inicializo la indicadora de missing en 0 (notar que aqui genero una indicadora de
		%* missing para TODAS las variables presentes en el modelo. Sin embargo en el output
		%* dataset, solamente conservo las indicadoras de missing de las variables que realmente
		%* intervienen en el modelo como indicadoras de missing. Estas indicadoras de missing
		%* que genero aqui son necesarias para efectuar el tratamiento de missing requerido
		%* (inclusion o exclusion, segun se indica en la variable TMISS del dataset
		%* <TEMPLATE>) durante la transformacion de las variables, pero nada mas que para eso;
		else do;
			IM_vars(i) = 1;
			if index(miss, "/") then do;	%* Supongo que hay a lo sumo dos valores posibles para el
											%* valor de reemplazo de los missing (ej. 0/-1). Notar
											%* que si la variable MISS es considerada numerica
											%* no hay problema con buscar el caracter / porque
											%* automaticamente se convierte el valor de MISS a
											%* numerico;
				misspop1 = scan(upcase(misspop), 1, '/');
				misspop2 = scan(upcase(misspop), 2, '/');
				select (upcase(pop));
					when (misspop1) miss = scan(miss, 1, '/');
					when (misspop2) miss = scan(miss, 2, '/');
					otherwise		miss = 0;	%* Este lo considero el reemplazo default;
												%* Notar que si MISS esta clasificada como caracter
												%* automaticamente el numero 0 se convierte a string;
				end;
			end;
			vars(i) = miss*1;	%* Multiplico por 1 porque la variable MISS puede estar clasificada
								%* como caracter en <TEMPLATE> (por ej. si hay valores que tienen
								%* un slash (/);
		end;
	end;
	%************************ Tratamiento de los valores missing *****************************;

	drop miss misspop misspop1 misspop2 min max vname;
run;
/*============================ 1. Tratamiento de Missing (END) ==============================*/


/*====================== 2. Transformacion de las variables (START) =========================*/
%********** Macro %TRANSFORM que efectua la transformacion de las variables (START) **********;
%MACRO Transform(var, var_transf, values, varlen);
%** VARLEN es el LENGTH de la variable VAR en _VAR_TRANSF_ leido antes de llamar a esta
%** macro y usado al mostrar la informacion en el log para determinar la columna en la que
%** se muestra el nombre de la variable transformada (a VARLEN+1 de la columna en la que se
%** muestra la variable original);
%local i vari var_transfi valuesi conditioni varnames;

%local classvalues;		%* Lista de los valores de las variables categoricas (de la columna VALUES);
%local missvalues;		%* Lista de valores de reemplazo de los missing (de la columna MISS);

%*** Macro que muestra mensaje de error;
%* VAR: 		Variable que se esta procesando cuando se genera el error;
%* VARERROR: 	Nombre de la variable donde se encontro el error;
%* DATA:		Nombre del dataset donde se encontro el error en la variable VARERROR;
%MACRO Error(var=, var_transf=, varerror=, data=);
put;
put "ERROR: El valor de la variable %upcase(&varerror) para la variable &var en %upcase(&data)";
put "es invalido (" &varerror +(-1) ").";
put "Se generara un valor missing para &var_transf..";
%MEND Error;

%* Macro que define el tratamiento de los missing en la transformacion: si se incluyen o
%* se excluyen;
%* Parametros:
%* VAR: 		Nombre de la variable a transformar;
%* VAR_TRANSF: 	Nombre de la variable transformada;
%* MACRO:		Nombre de la macro a invocar que efectua la transformacion;
%MACRO Tmiss(var, var_transf, macro);
select (upcase(Tmiss));
	when ("IN") do;
		&macro;
	end;
	when ("EX") do;
		if ~IM_&var then do;	%* Se excluyen los missing de la transformacion;
			&macro;
		end;
		else if upcase(transf) ~= "IM" then
			&var_transf = &var;
		else
			&var_transf = 0;	%* En el caso de la transformacion IM, el valor para la variable
								%* transformada (indicadora de los missing) se pone en 0, porque
								%* se estan excluyendo los missing de la transformacion, con lo que
								%* todos los valores de la indicadora de missing deben ser 0;
	end;
	otherwise do;
		%Error(var=&var, var_transf=&var_transf, varerror=Tmiss, data=&template);
		&var_transf = .;
	end;
end;
%MEND Tmiss;

/*--------------------------------- TRANSFORMATION MACROS -----------------------------------*/
/* Definicion de macros con las transformaciones. Se hace referencia a los codigos de transformacion
definidos en el documento de especificaciones. Las macros son:
- %TRN:		Transformacion de Rename (RN)
- %TTR:		Transformacion de Truncamiento (TR)
- %TCT:		Transformacion Categorica (CT)
- %TI0:		Transformacion Indicadora de Ceros (I0)
- %TIM:		Transformacion Indicadora de Missing (IM)
- %TIC:		Transformacion Indicadora de valores que cumplen cierta condicion (IC)
- %TIT:		Transformacion de Interaccion entre variables o producto (IT)
- %TRT:		Transformacion Ratio (RT)
- %TDF:		Transformacion Diferencia (DF)
- %TLG:		Transformacion Logaritmica (LG)
- %TCD:		Transformacion Cuadratica (CD)
- %TCC:		Transformacion Cuadratica Centrada (CC)
- %TPL:		Transformacion a Trozos -- componente lineal (PL)
- %TPLC: 	Transformacion a Trozos -- componente lineal centrada (PLC)
- %TPCC:	Transformacion a Trozos -- componente cuadratica centrada (PCC)
*/
%* Transformacion de Rename unicamente. 
%* Esta macro es necesaria para contemplar el caso en que las variables no son transformadas
%* sino solamente renombradas. Esto puede ocurrir cuando por ejemplo se limitan los valores
%* de la variable original a un rango de valores minimo y maximo;
%* TRN: Transformacion ReName;
%MACRO TRN(var, var_transf);
&var_transf = &var;
%MEND TRN;

%* Truncamiento entre valores minimo y maximo;
%* TTR = Transformacion de TRuncamiento;
%MACRO TTR(var, var_transf);
&var_transf = min( max(&var, min), max );
%MEND TTR;

%* Categorizacion de variables continuas (generacion de dummies);
%* TCT = Transformacion CaTegorica;
%* El tratamiento de los valores missing debe ser hecho en la definicion de los 
%* valores aceptados por cada categoria;
%MACRO TCT(var, var_transf, values);
%local condition;

%* Reemplazo comas por OR;
%let condition = %sysfunc(tranwrd(%quote(&values), %quote(,), %quote( OR &var)));
%* Reemplazo guiones (-) por AND;
%let condition = &var%sysfunc(tranwrd(%quote(&condition), %quote(-), %quote( AND &var)));
if &condition then
	&var_transf = 1;
else
	&var_transf = 0;
%MEND TCT;

%* Indicadora de ceros;
%* TI0 = Transformacion Indicadora de Ceros;
%MACRO TI0(var, var_transf);
if &var = 0 then
	&var_transf = 1;
else
	&var_transf = 0;
%MEND TI0;

%* Indicadora de missing;
%* TIM = Transformacion Indicadora de Missing;
%* Nota importante: Al llamar a esta macro desde el data step abajo, primero se llama a la macro
%* TMiss y luego a esta macro, lo cual podria parecer innecesario considerando que esta macro
%* genera justamente las indicadoras de Missing y la macro TMiss establece como se tratan los
%* missing en la transformacion! Sin embargo, el llamado a la macro TMiss es util para distinguir
%* dos casos: (i) si al reemplazar el valor missing de una variable, el valor missing original
%* debe marcarse como tal en la indicadora de missing, o bien (ii) si debe hacerse de cuenta de que
%* el valor original no era missing. Lo mas comun es el primer caso, pero hay ocasiones en que
%* es util considerar el segundo caso, por ej. cuando el missing ocurre en una vairable de cantidad
%* (KNT) y dicho missing indica que la cantidad es 0, o sea que en realidad no es un missing;
%MACRO TIM(var, var_transf);
if IM_&var then
	&var_transf = 1;
else
	&var_transf = 0;
%MEND TIM;

%* Indicadora de valores que cumplen la condicion especificada;
%* TIC = Transformacion Indicadora de valores que cumplen una Condicion;
%MACRO TIC(var, var_transf, condition);
%* Notar que en principio el caso TMISS = EX no deberia ocurrir en esta transformacion, porque
%* se supone que la variable transformada segun este proceso debe tener solamente 2 valores
%* posibles y el excluir los missing de la transformacion generaria 3 valores: miss, 0 y 1;
if &var &condition then
	&var_transf = 1;
else
	&var_transf = 0;
%MEND TIC;

%* Transformacion Interaccion o producto entre 2 o mas variables;
%* TIT = Transformacion InTeraccion;
%* VAR: 	Lista de variables a interactuar (no hay limite para el nro. de variables)
%* VARINT: 	Nombre de la variable con la interaccion;
%* Notar que creo la indicadora de missing de la variable transformada por si despues la variable 
%* transformada se usa en una transformacion posterior;
%MACRO TIT(var, var_transf);
%local IM_var;
%* Reemplazo / con espacios en blanco, para obtener la lista de variables que intervienen
%* en la interaccion;
%let var = %sysfunc(tranwrd(&var, /, %quote( )));
%let IM_var = %MakeList(&var, prefix=IM_);
if %any(&IM_var, =, 1) then do;
	&var_transf = miss;
	IM_&var_transf = 1;
end;
else do;
	&var_transf = %MakeList(&var, sep=*);
	IM_&var_transf = 0;
end;
%MEND TIT;

%* Transformacion Ratio (cociente) entre 2 variables;
%* TRT = Transformacion RaTio;
%* VAR: 	Lista de las dos variables para el ratio
%* VARINT: 	Nombre de la variable con el ratio;
%* Notar que creo la indicadora de missing de la variable transformada por si despues la variable 
%* transformada se usa en una transformacion posterior;
%MACRO TRT(var, var_transf);
%local IM_var;
%* Reemplazo / con espacios en blanco, para obtener la lista de variables que intervienen en el ratio
%* y poder preguntar si son missing;
%let var = %sysfunc(tranwrd(&var, /, %quote( )));
%let IM_var = %MakeList(&var, prefix=IM_);
if %any(&IM_var, =, 1) or %scan(&var, 2, %quote( )) = 0 then do;
	&var_transf = miss;
	IM_&var_transf = 1;
end;
else do;
	&var_transf = %MakeList(&var, sep=/);
	IM_&var_transf = 0;
end;
%MEND TRT;

%* Transformacion diferencia entre 2 variables;
%* TDF = Transformacion DiFerencia;
%* Notar que creo la indicadora de missing de la variable transformada por si despues la variable 
%* transformada se usa en una transformacion posterior;
%MACRO TDF(var, var_transf);
%local IM_var;
%* Reemplazo el / con el espacio en blanco para obtener las dos variables a restar;
%let var = %sysfunc(tranwrd(&var, /, %quote( )));
%let IM_var = %MakeList(&var, prefix=IM_);
if %any(&IM_var, =, 1) then do;
	&var_transf = miss;
	IM_&var_transf = 1;
end;
else do;
	&var_transf = %MakeList(&var, sep=-);
	IM_&var_transf = 0;
end;
%MEND TDF;

%* Transformacion logaritmica;
%* TLG = Transformacion LoGaritmica;
%MACRO TLG(var, var_transf);
if &var >= 0 then
	&var_transf = log10(1 + &var);
else
	&var_transf = -log10(1 - &var);
%MEND TLG;

%* Transformacion cuadratica;
%* TCD = Transformacion Cuadratica;
%MACRO TCD(var, var_transf);
&var_transf = &var**2;
%MEND TCD;

%* Transformacion cuadratica centrada;
%* TCC = Transformacion Cuadratica Centrada;
%MACRO TCC(var, var_transf);
&var_transf = (&var - mean)**2;
%MEND TCC;

/*-------------------------------------- Piecewise ------------------------------------------*/
%* Transformacion a trozos: parte lineal para valores que cumplen con la condicion especificada;
%* TPL = Transformacion Piecewise componente Lineal;
%MACRO TPL(var, var_transf, condition, otherwise=0);
if &var &condition then
	&var_transf = &var;
else
	&var_transf = &otherwise;
%MEND TPL;

%* Transformacion a trozos: parte lineal centrada para valores que cumplen con la condicion especificada;
%* TPLC = Transformacion Piecewise componente Lineal Centrada;
%MACRO TPLC(var, var_transf, condition, otherwise=0);
if &var &condition then
	&var_transf = &var - mean;
else
	&var_transf = &otherwise;
%MEND TPLC;

%* Transformacion a trozos: parte cuadratica centrada para valores que cumplen con la condicion especificada;
%* TPCC = Transformacion Piecewise Cuadratica Centrada;
%MACRO TPCC(var, var_transf, condition, otherwise=0);
if &var &condition then
	&var_transf = (&var - mean)**2;
else
	&var_transf = &otherwise;
%MEND TPCC;
/*-------------------------------------- Piecewise ------------------------------------------*/
/*--------------------------------- TRANSFORMATION MACROS -----------------------------------*/

/*-------------------------------------- DATA STEP ------------------------------------------*/
options notes;
%* Variables del modelo a conservar en el output dataset;
%let var_model = %MakeListFromVar(_var_model_, var=var, log=0);
data &out;
	set &out;
	%let pos_var = %eval(1+3+1);
	%let pos_var_transf = %eval(&pos_var + (&varlen+1));
	%let pos_transf = %eval(&pos_var_transf + (32+1));
	%let pos_values = %eval(&pos_transf + (6+1));
	if _N_ = 1 then
		put "#" @&pos_var "Variable" @&pos_var_transf "Variable Transformada" @&pos_transf "Transf" @&pos_values "Valores";
	%* Transformacion de cada variable. Notar que uso un %DO macro y no un DO data step
	%* para poder llamar a las macros que hacen las transformaciones con el nombre de
	%* la variable. Ademas estA el inconveniente de que si uso un DO data step en muchas
	%* de las transformaciones tengo que definir ARRAYS para poder generar las variables
	%* transformadas (por ej. en la transformacion Cn), pero esto da error porque
	%* el nombre del array es siempre el mismo para cada una de las variables transformadas
	%* por Cn y eso hace que SAS salte con el error de que dicho array ya habia sido definido;
	%do i = 1 %to %GetNroElements(&var);
		%let vari = %scan(&var, &i, ' ');
		%let var_transfi = %scan(&var_transf, &i, ' ');
		%let valuesi = %scan(%quote(&values), &i, ' ');
		%let conditioni = %scan(%quote(&condition), &i, %quote(,));	%* Separado por comas porque la defincion de CONDITION puede tener espacios en el medio (como en BETWEEN 1 and 2);
		i = &i;
		set _var_transf_(keep=miss transf tmiss tpop mean min max) point=i;
		if _N_ = 1 then
			put "&i" @&pos_var "&vari" @&pos_var_transf "&var_transfi" @&pos_transf transf @&pos_values "&valuesi";

		%*** Definicion de la transformacion y su calculo;
		if index(transf, "/") then do;
			%* Esto ocurre cuando el tipo de transformacion depende del sub-modelo en el que cae
			%* el cliente (definido por el valor de la variable POP);
			%* Se supone que a lo sumo hay 2 transformaciones para una variable, por eso solamente
			%* se busca una ocurrencia de la barra separadora /;
			transf1 = scan(transf, 1, '/');		%* Transformacion 1;
			transf2 = scan(transf, 2, '/');		%* Transformacion 2;
			tmiss1 = scan(tmiss, 1, '/');		%* Tratamiento de missing 1;
			tmiss2 = scan(tmiss, 2, '/');		%* Tratamiento de missing 2;
			tpop1 = scan(upcase(tpop), 1, '/');	%* POP (sub-modelo) a la que se aplica la Transformacion 1;
			tpop2 = scan(upcase(tpop), 2, '/');	%* POP (sub-modelo) a la que se aplica la Transformacion 2;
			select (upcase(pop));
				when (tpop1) do;
					transf = transf1;
					tmiss = tmiss1;
				end;
				when (tpop2) do;
					transf = transf2;
					tmiss = tmiss2;
				end;
				otherwise do;
					transf = "ST";	%* La variable no se transforma;
					tmiss = "IN";	%* Pongo cualquier valor admisible porque igual la variable no se transforma;
				end;
			end;
		end;
		%* En lo que sigue hago una distincion de si en el nombre de la variable VAR aparece
		%* el simbolo / solamente para evitar que aparezcan mensajes en el log de que algunas
		%* variables estan uninitialized. De lo contrario, no es necesario hacerlo.
		%* Basicamente esto ocurre con las variables IM_ de otras variables
		%* que no son las originalmente presentes en el dataset (ej. IM_x_L) sino que aparecen
		%* en una transformacion tipo IT o DF que combinan mas de una variable y que
		%* claramente no son variables que estan originalmente presentes en el dataset sino
		%* que fueron generadas por medio de una transformacion (ej. logaritmica);
		%if ~%index(&vari, /) %then %do;
		%* Seleccion de transformaciones que dependen de una sola variable;
		select (upcase(transf));
			when ("RN")	do; %TRN(&vari, &var_transfi); end;
			when ("TR") do; %TMiss(&vari, &var_transfi, %nrbquote(%TTR(&vari, &var_transfi))); end;
			when ("CT") do; %TCT(&vari, &var_transfi, %quote(&valuesi)); end;	%* Aqui no importa el tratamiento de missing porque se espera que lo que hay que hacer con ellos estE informado en la macro variable &valuesi;
			when ("I0") do; %TMiss(&vari, &var_transfi, %nrbquote(%TI0(&vari, &var_transfi))); end;
			when ("IM") do; %TMiss(&vari, &var_transfi, %nrbquote(%TIM(&vari, &var_transfi))); end;
			when ("IC") do; %TMiss(&vari, &var_transfi, %nrbquote(%TIC(&vari, &var_transfi))); end;
			when ("LG") do; %TMiss(&vari, &var_transfi, %nrbquote(%TLG(&vari, &var_transfi))); end;
			when ("CD") do; %TMiss(&vari, &var_transfi, %nrbquote(%TCD(&vari, &var_transfi))); end;
			when ("CC") do; %TMiss(&vari, &var_transfi, %nrbquote(%TCC(&vari, &var_transfi))); end;
			when ("PL") do; %TMiss(&vari, &var_transfi, %nrbquote(%TPL(&vari, &var_transfi, %quote(&conditioni), otherwise=0))); end;
			when ("PLC") do; %TMiss(&vari, &var_transfi, %nrbquote(%TPLC(&vari, &var_transfi, %quote(&conditioni), otherwise=0))); end;
			when ("PCC") do; %TMiss(&vari, &var_transfi, %nrbquote(%TPCC(&vari, &var_transfi, %quote(&conditioni), otherwise=0))); end;
			otherwise; 		%* No se hace ninguna transformacion;
		end;
		%end;
		%else %do;
		%* Seleccion de transformaciones que dependen de mas de una variable;
		select (upcase(transf));
			when ("IT") do; %TIT(&vari, &var_transfi); end;
			when ("RT") do;	%TRT(&vari, &var_transfi); end;
			when ("DF") do; %TDF(&vari, &var_transfi); end;
			otherwise; 		%* No se hace ninguna transformacion;
		end;
		%end;
	%end;
	keep &pop &id &var_model &var_transf;
run;
options &notes_option;
/*-------------------------------------- DATA STEP ------------------------------------------*/
%MEND Transform;
%*********** Macro %TRANSFORM que efectua la transformacion de las variables (END) ***********;

%*** Lectura de las variables a transformar y de las variables transformadas a generar.
%*** Se toman del dataset <TEMPLATE>, de las columnas VAR y VAR_TRANSF respectivamente;
options nonotes;
%* Lista de variables a transformar;
data _var_transf_;
	set _var_ _var_transf2_ _var_transf_many_;
	where upcase(transf) ~= "ST";
run;
options &notes_option;

%*** Macro variables con la lista de variables a transformar y de las variables transformadas
%*** a generar;
%* Leo el LENGTH de la variable VAR en _VAR_TRANSF_ para saber en que columna mostrar
%* la informacion en el log;
data _NULL_;
	dsid = open("_var_transf_");
	if dsid > 0 then do;
		%* Length de VAR;
		varnum = varnum(dsid, "var");
		varlen = varlen(dsid, varnum);
		call symput ('varlen', varlen);
		%* Length de CONDITION;
		varnum = varnum(dsid, "condition");
		varlen = varlen(dsid, varnum);
		call symput ('condlen', varlen);
		rc = close(dsid);
	end;
run;
data _var_transf_;
	%* Defino el length de CONDITION a como minimo 2 para que pueda entrar el string >. que uso
	%* cuando CONDITION es vacio;
	length condition $%sysfunc(max(2,&condlen));
	set _var_transf_;
	%* Relleno con un caracter los valores missing de la variable VALUES para que los valores
	%* posibles de las variables categoricas sean correctamente leidos (si no habria un desfasaje
	%* de los valores de las distintas variables categoricas porque algunos valores serian
	%* vacios). Despues igual verifico que la transformacion a efectuar sea la categorica,
	%* antes de usar el valor de la columna VALUES;
	%* Otro tanto hago con la variable CONDITION;
	if compress(values) = "" then values = "-";
	if compress(condition) = "" then condition = ">.";	%* Uso una condicion que siempre se cumpla, si la condicion es vacia;
	%** Notar que si la columna VALUES es vacia en la tabla Excel de entrada, es definida como
	%** caracter por default;
run;
%* Ordeno el dataset _VAR_TRANSF_ por el orden originalmente presente en <TEMPLATE> para que
%* no haya problema con el orden de generacion de las variables. El orden de las variables
%* en _VAR_TRANSF_ puede ser distinto del orden original en <TEMPLATE> porque _VAR_TRANSF_ se
%* construyendo SETeando primero el dataset _VAR_, luego el dataset _VAR_TRANSF2_ y finalmente
%* el dataset _VAR_TRANSF_MANY_. Con lo cual el orden de las transformaciones se modifica;
proc sort data=_var_transf_;
	by _OBS_;	%* La variable _OBS_ fue creada en _TEMPLATE_;
run;
%* Genero macro variables con los valores de columnas que necesito referenciar con macro variables
%* en el data step que hace las transformaciones en la macro Transform;
%let var2transf = %MakeListFromVar(_var_transf_, var=var, log=0);
%let var_transf = %MakeListFromVar(_var_transf_, var=var_transf, log=0);
%let values = %MakeListFromVar(_var_transf_, var=values, log=0);
%let condition = %MakeListFromVar(_var_transf_, var=condition, sep=%quote(,), log=0);
	%**	Genero los valores de CONDITION separados por comas porque la defincion de cada una 
	%** de las CONDITION puede tener espacios en el medio (como en BETWEEN 1 and 2);
%let nro_var2transf = %GetNroElements(&var2transf);
%if &nro_var2transf = 0 %then
	%put NINGUNA VARIABLE NECESITA SER TRANSFORMADA.;
%else %do;
	%put;
	%put PREPARETOSCORE: Transformacion de variables...;
	%put VARIABLES A TRANSFORMAR:;
	data _NULL_;
		%let pos_var2transf = %eval(1+3+1);
		%let pos_var_transf = %eval(&pos_var2transf + (&varlen+1));
		%let pos_values = %eval(&pos_var_transf + (32+1));
		if _N_ = 1 then
			put "#" @&pos_var2transf "Variable" @&pos_var_transf "Variable Transformada" @&pos_values "Valores";
		%do i = 1 %to &nro_var2transf;
			%let var2transfi = %scan(&var2transf, &i, ' ');
			%let var_transfi = %scan(&var_transf, &i, ' ');
			%let valuesi = %scan(%quote(&values), &i, ' ');
			put "&i" @&pos_var2transf "&var2transfi" @&pos_var_transf "&var_transfi" @&pos_values "&valuesi";
		%end;
	run;
	%Transform(&var2transf, &var_transf, %quote(&values), &varlen);
%end;
/*===========- 2. Transformacion de las variables (END) =============*/

options nonotes;
/*----- Distribucion de las variables originales y transformadas usadas en el modelo -----*/
%if %quote(&summary) ~= %then %do;
	%let data_name = %scan(&data, 1, '(');
	%put;
	%put PREPARETOSCORE: Distribucion de las variables...;
	%* Lista de variables cuya distribucion se calcula, tras eliminar los nombres repetidos
	%* (lo cual puede ocurrir cuando una variable es transformada mas de una vez en forma
	%* anidada. Ej: x -> log(x) -> diferencia entre log(x) y otra variable), con lo que
	%* las variables x y x_L (=log(x)) apareceran tanto en la lista de variables &VAR_MODEL
	%* como en la lista de variables &VAR_TRANSF;
	%* Notar que no uso %RemoveRepeated para este fin para evitar tener que disponer de
	%* mas macros de las que ya necesito;
	data _var_means_;
		length var $32;
		%do i = 1 %to %GetNroElements(&var_model &var_transf);
		var = "%scan(&var_model &var_transf, &i, ' ')";
		output;
		%end;
	run;
	%* Elimino duplicados;
	proc sort data=_var_means_ nodupkey;
		by var;
	run;
	%let var_means = %MakeListFromVar(_var_means_, log=0);
	%*** OJO QUE LA MACRO %MEANS FALLA CUANDO EL NUMERO DE VARIABLES PASADAS EN VAR= ES MUY
	%*** GRANDE, DIGAMOS UNAS 200 O ALGO ASI;
	%Means(
		&out,
		by=&pop,
		var=&var_means,
		stat=n min max mean P1 P5 P10 P25 median P75 P90 P95 P99 stddev cv,
		out=&summary,
		transpose=1,
		log=1
	);

	%** Aca me gustaria agregar los nombres originales de las variables para despues ordenar
	%** por esos nombres, asi todas las variables y sus transformadas aparecen juntas tras ordenar,
	%** pero la cosa del merge es mas complicada de lo que parece, porque hay que mergear
	%** primero por &VAR_MODEL y luego por &VAR_TRANSF, ya que en el summary de arriba estoy
	%** calculando la distribucion de la variable original y de las transformadas, que son mas
	%** que el numero de observaciones que hay en el dataset VAR_MODEL_TRANSF;
%end;
/*---------------------------------------------------------------------------------------------*/

%end;	%* %if %length(&var) > 0;

%* Borro datasets temporarios;
proc datasets nolist;
	delete 	_contents_
			_template_
			_var_
			_var_found1_
			_var_found1_notfound_
			_var_found2_
			_var_found2_notfound_
			_var_means_
			_var_model_
			_var_model2_
			_var_notfound_
			_var_notfound1_
			_var_notfound2_
			_var_rest_
			_var_transf_
			_var_transf2_
			_var_transf_many_
			_var_transf_many_orig_
			_varlist_;
quit;

options &notes_option;
%MEND PrepareToScore;
