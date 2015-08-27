/* MACRO %Hadi
Version: 1.05
Author: Santiago Laplagne - Daniel Mastropietro
Created: 17-Dec-02
Modified: 9-Dec-03

DESCRIPTION:
Implementa el algoritmo de Hadi para detectar outliers en un conjunto de 
datos. Es un método robusto de detección y supone una distribución normal
multivariada de los datos.

USAGE:
%Hadi (
	data ,								*** Input dataset
	var=_NUMERIC_ ,						*** Analysis variables
	by= ,								*** BY variables
	out= ,								*** Output dataset with outliers removed
	outAll= , 							*** Output dataset with all observations and outliers flagged
	nameDistance=mahalanobisDistance ,	*** Name of the variable in output dataset to store the Mahalanobis distance
	nameOutlier=outlier,				*** Name of the variable in output dataset to flag outliers
	alpha=0.05 ,						*** Base significance level for outlier detection
	adjust=1 ,							*** Flag 0/1: whether the ALPHA should be adjusted by the number of obs.
	fractionGood=0.5 ,					*** Fraction of the observations to be considered as GOOD in the Hadi algorithm
	boxcox=0 ,							*** Flag 0/1: whether to transform variables with Box-Cox prior to Hadi algorithm
	lambda=-3 to 3 by 0.01 				*** Search range for the parameter of the Box-Cox transformation, lambda
	plot=0 ,							*** Flag 0/1: Show scatter plots and/or plot of Mahalanobis distance?
	scatter=1 ,							*** Flag 0/1: Generate scatter plots highlighting detected outliers?
	mahalanobis=1 ,						*** Flag 0/1: Generate plot of Mahalanobis distance by observation number?
	log=1);								*** Flag 0/1: Show messages in the log?

REQUIRED PARAMETERS:
- data:			Input dataset con los datos a utilizar. Puede recibir
				cualquier opción adicional como en cualquier opción
				data= de SAS.

OPTIONAL PARAMETERS:
- var:			Lista de las variables a utilizar en la detección de
				outliers, separadas por espacios.
				default: _NUMERIC_, es decir, todas las variables numéricas.

- by:			Lista de by variables. La detección de outliers se realiza
				para cada combinación de los valores de las by variables.
				Puede usarse este parámetro para indicar variables que
				definen	distintos segmentos.
				(No es necesario ordenar el input dataset por estas variables
				porque la macro lo hace automáticamente.)

- out:			Output dataset donde se guardan las observaciones del
				dataset	original que quedan después de eliminar los
				outliers. A las variables originalmente presentes en el
				input dataset se agregan las siguientes variables:
				- Distancia de Mahalanobis para cada observacion. El nombre
				de la variable es el especificado por el parámetro
				'nameDistance'.
				- _THRESHOLD_: Valor de corte de la distancia de Mahalanobis
				por encima del cual una observacion es considerada outlier.
				- _ALPHA_: Valor del parámetro 'alpha' pasado al invocar la macro.
				- _ALPHA_ADJ_: Valor de alpha efectivamente usado para determinar
				el valor de corte de la distancia de Mahalanobis (si no se
				especifica lo contrario, es el valor de alpha ajustado por el
				número de observaciones incluidas en la detección de outliers).
				NOTA: Si no se especifica este parámetro ni el parámetro 'outAll',
				no se genera ningun output dataset, pero sí se ven los mensajes del
				proceso de detección de outliers en el log.

- outAll:		Output dataset donde se guardan todas las observaciones del
				dataset original y se agregan 5 nuevas variables. Cuatro de ellas son
				las descriptas en el parámetro 'out' y la quinta es la variable que
				indica si la observación es o no considerada outlier.
				El nombre de esa columna viene dado por el parámetro 'nameOutlier'.
				Las observaciones consideradas outliers se indican con el valor 1,
				y con un 0 en caso contrario.
				NOTA: Si no se especifica este parámetro ni el parámetro 'out',
				no se genera ningun output dataset, pero sí se ven los mensajes del
				proceso de detección de outliers en el log.

- nameDistance:	Nombre de la columna con las distancias de Mahalanobis calculadas
				tras la última iteración del algoritmo. Esta columna se agrega a
				los output datasets indicados por los parámetros 'out' y 'outAll'.
				default: mahalanobisDistance

- nameOutlier:	Nombre de la columna con el indicador de outlier/no-outlier en
				el dataset indicado por el parámetro 'outAll'.
				Valores que toma la variable:
				0 => No outlier
				1 => Outlier
				default: outlier

- alpha:		Parámetro que determina el cuantil de la distribución 
				ChiCuadrado a usar para fijar el corte entre outlier y no
				outlier.
				Si el valor del parámetro 'adjust' es 1 (default),
				se ajusta este valor segun la transformacion
				alpha_adj = 1 - (1 - alpha)^1/n, donde n es el número de
				observaciones. De lo contrario alpha_adj = alpha.
				Dado el valor de alpha ajustado, el corte a usar
				para la distancia de Mahalanobis robusta, para decidir si una
				observación es o no outlier es el cuantil (1 - alpha_adj) de
				la distribución ChiCuadrado con p grados de libertad, donde p
				es el	número de variables listadas en el parámetro 'var'.
				Este es un ajuste para tener en cuenta el numero de tests
				que se hacen sobre el mismo conjunto de datos, y es valido si
				dichos tests son independientes (suposicion razonable si los
				datos provienen de una muestra aleatoria).
				Mientras más chico sea alpha, menos observaciones serán
				podadas.
				default: 0.05

- adjust:		Indica si se desea ajustar el nivel alpha por el nro. de
				observaciones, para disminuir las chances de detectar un
				outlier simplemente por casualidad.
				El ajuste efectuado supone independencia entre las observaciones
				lo cual es cierto si los datos provienen de una muestra
				aleatoria.
				Valores posibles: 0 => No ajustar, 1 => Ajustar.
				default: 1

- fractionGood:	Fracción de observaciones que inicialmente son consideradas
				"buenas" por el algoritmo de Hadi. Su valor debe estar entre
				0 y 1.
				default: 0.5

- boxcox:		Indica si se desea que las variables sean transformadas por
				Box-Cox previo al proceso de detección de outliers por el método
				Hadi.
				El espacio de búsqueda del lambda óptimo para efectuar la
				transformación Box-Cox es el intervalo [-3,3] a pasos de 0.01.
				Valores posibles: 0 => No, 1 => Sí.
				default: 0

- lambda:		Espacio de búsqueda para el parámetro lambda de la transformación
				Box-Cox que se efectúa previamente a la detección de outliers,
				en caso de que boxcox=1.
				Para más información ver la macro %Boxcox.
				Sólo tiene efecto si boxcox=1.
				default: -3 to 3 by 0.01

- plot:			Indica si se desea ver los gráficos generados por la macro:
				- Scatter plots de las variables analizadas, indicando en rojo
				las observaciones detectadas como outliers. 
				- Distancia de Mahalanobis para cada observación.
				Valores posibles: 0 => No, 1 => Sí.
				default: 0

- scatter:		Indica si se desea hacer los scatter plots de las variables
				analizadas, indicando en rojo las observaciones detectadas como
				outliers.
				Sólo tiene efecto si plot=1.
				Valores posibles: 0 => No, 1 => Sí.
				default: 1

- mahalanobis:	Indica si se desea ver el gráfico de las distancias de Mahalanobis
				para cada observación.
				Sólo tiene efecto si plot=1.
				Valores posibles: 0 => No, 1 => Sí.
				default: 1

- log:			Indica si se desea ver mensajes en el log generados por la macro.
				Valores posibles: 0 => No, 1 => Sí.
				default: 1
				
NOTES:
- Este algoritmo supone que los datos tiene una distribución normal multivariada.
Si esa condicion no se cumple, el algoritmo funciona de todas formas, pero los
resultados pueden no ser apropiados. En ese caso recomendamos hacer alguna
transformacion previa de los datos antes de llamar a esta función.
Por ejemplo, puede transformarse cada variable utilizando la macro %boxcox.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Any
- %Boxcox
- %Callmacro
- %DefineSymbols
- %ExistOption
- %GetDataName
- %GetDataOptions
- %GetLibraryName
- %GetNobs
- %GetNroElements
- %GetStat
- %GetVarList
- %GetVarOrder
- %CreateGroupVar
- %MakeList
- %ResetSASOptions
- %Scatter
- %SetSASOptions
- Mahalanobis (IML Module)
- Order (IML Module)

SEE ALSO:
- %Boxcox
- %Mahalanobis

EXAMPLES:
1.- %Hadi(test(where=(x1 > 0)) , var=x1-x3 , out=test_hadi , outAll=test_hadi_all ,
		  boxcox=1 , plot=1);
Detecta outliers por el método de Hadi a partir de las variables x1, x2, x3 del
dataset TEST, teniendo en cuenta las observaciones que tienen x1 > 0. La detección
está basada en las variables transformadas por Box-Cox.

DATASETS DE SALIDA:
- TEST_HADI, con las observaciones que no fueron detectadas como outliers.
- TEST_HADI_ALL, con todas las observaciones incluidas en el análisis y el agregado de
las variables con información relacionada con la detección, entre las cuales está la
variable 'outlier' que indica si una observación es outlier o no (= 1 si lo es,
= 0 en caso contrario).

GRÁFICOS:
Muestra los siguientes gráficos:
- Scatter plots de las variables x1, x2, x3.
- Distancia de Mahalanobis de cada observación, y el umbral que decide si una
observación es o no outlier.
***************************************************************************************

2.- %Hadi(test , by=group subgroup , var=xx yy zz tt ww uu ss , outAll=test_hadi ,
		  alpha=0.001 , adjust=0 , fractionGood=0.35 , plot=1 , scatter=0);
Detecta outliers por el método de Hadi a partir de las variables xx, yy, zz, tt, ww, 
uu, ss, por cada valor de las variables GROUP y SUBGROUP.
La detección está basada en las variables originales, es decir sin transformar
por Box-Cox.

OPCIONES:
- alpha=0.001:	pide utilizar el cuantil 0.001 de la distribucion ChiCuadrado para
definir una observación como outlier.
- adjust=0:		pide no ajustar el valor de alpha por el número de observaciones. En
principio esto puede ser útil si en cada uno de los grupos definidos por las by
variables no hay muchas observaciones.
- fractionGood=0.35:	pide considerar solamente el 35% de las observaciones como
"buenas" (es decir no potencialmente outliers) al iniciar el proceso de detección, en
lugar del 50% default.

DATASETS DE SALIDA:
Genera el dataset TEST_HADI con todas las observaciones incluidas en el análisis y el
agregado de las variables con información relacionada con la detección, entre las cuales
está la variable 'outlier' que indica si una observación es outlier o no (= 1 si lo es,
= 0 en caso contrario).

GRÁFICOS:
Muestra el gráfico con la distancia de Mahalanobis de cada observación, y el umbral que
decide si una observación es o no outlier, pero omite los scatter plots donde se ven qué
observaciones son outliers y cuáles no (esto porque son muchas las variables utilizadas
en la detección y tal vez los scatter plots no aporten mucho).
***************************************************************************************
*/
&rsubmit;
%MACRO Hadi(data ,
			var=_numeric_ ,
			by= ,
			out= ,
			outAll= , 

			nameDistance=mahalanobisDistance ,
			nameOutlier=outlier ,

			alpha=0.05 ,
			adjust=1 ,
			fractionGood=0.5 ,
			boxcox=0 ,
			lambda=-3 to 3 by 0.01 ,

			plot=0 ,
			scatter=1 ,
			mahalanobis=1 ,

			log=1 ,
			help=0) / store des="Robust multivariate outlier detection using the Hadi method";

/*----- Macro to display usage -----*/
%MACRO ShowMacroCall;
	%put HADI: The macro call is as follows:;
	%put %nrstr(%Hadi%();
	%put data , (REQUIRED) %quote(                 *** Input dataset);
	%put var=_NUMERIC_ , %quote(                   *** Analysis variables);
	%put by= , %quote(                             *** BY variables);
	%put out= , %quote(                            *** Output dataset with outliers removed);
	%put outAll= , %quote(                         *** Output dataset with all observations and outliers flagged);
	%put nameDistance=mahalanobisDistance , %quote(*** Name of the variable in output dataset to store the Mahalanobis distance);
	%put nameOutlier=outlier , %quote(             *** Name of the variable in output dataset to flag outliers);
	%put alpha=0.05 , %quote(                      *** Base significance level for outlier detection);
	%put adjust=1 , %quote(                        *** Flag 0/1: whether the ALPHA should be adjusted by the number of obs.);
	%put fractionGood=0.5 , %quote(                *** Fraction of the observations to be considered as GOOD in the Hadi algorithm);
	%put boxcox=0 ,	%quote(                        *** Flag 0/1: whether to transform variables with Box-Cox prior to Hadi algorithm);
	%put lambda=-3 to 3 by 0.01 %quote(            *** Search range for the parameter of the Box-Cox transformation, lambda);
	%put plot=0 , %quote(                          *** Flag 0/1: Show scatter plots and/or plot of Mahalanobis distance?);
	%put scatter=1 , %quote(                       *** Flag 0/1: Generate scatter plots highlighting detected outliers?);
	%put mahalanobis=1 ,%quote(                    *** Flag 0/1: Generate plot of Mahalanobis distance by observation number?);
	%put log=1) %quote(                            *** Flag 0/1: Show messages in the log?);
%MEND ShowMacroCall;

%local _IMLLabModelos_;
%let _IMLLabModelos_ = sasuser.IMLLabModelos;	/* Ubicacion de los modulos IML utilizados en la macro */

%local i j nobsCluster nobsAll nobsCluster nobsP nobsPCluster nobsTotal size step;
%local alpha_adj threshold;
%local 	data_name byvar_valueslist clusterInfo nro_byvars nro_codes subtitle
		var_orig var_t varOrder;

%if &help %then %do;
	%ShowMacroCall;
%end;
%else %if ~%CheckInputParameters(data=&data , var=&var , macro=HADI) %then %do;
	%ShowMacroCall;
%end;
%else %do;
/************************************* MACRO STARTS ******************************************/
%*Setting nonotes options and getting current options settings;
%SetSASOptions;

%* Showing input parameters;
%if &log %then %do;
	%put;
	%put HADI: Macro starts;
	%put;
	%put HADI: Input parameters:;
	%put HADI: - Input dataset = %quote(&data);
	%put HADI: - var = %quote(          &var);
	%put HADI: - by = %quote(           &by);
	%put HADI: - out = %quote(          &out);
	%put HADI: - outAll = %quote(       &outAll);
	%put HADI: - nameDistance = %quote( &nameDistance);
	%put HADI: - nameOutlier = %quote(  &nameOutlier);
	%put HADI: - alpha = %quote(        &alpha);
	%put HADI: - adjust = %quote(       &adjust);
	%put HADI: - fractionGood = %quote( &fractionGood);
	%put HADI: - boxcox = %quote(       &boxcox);
	%put HADI: - lambda = %quote(		  &lambda);
	%put HADI: - plot = %quote(         &plot);
	%put HADI: - scatter = %quote(      &scatter);
	%put HADI: - mahalanobis = %quote(  &mahalanobis);
	%put HADI: - log = %quote(          &log);
	%put;
%end;

%* Setting log to 1 if no dataset is created, so that the user sees some outcomes
%* from the macro execution;
%if (%quote(&out) =) and (%quote(&outAll) =) %then
	%let log = 1;

%if &log %then %do;
	%put;
	%put HADI: Macro starts;
%end;

%* Leyendo el orden en que aparecen las variables en el dataset para poder respetar ese orden en
%* el dataset de salida;
%GetVarOrder(&data , varOrder);

%* Elimino el dataset _hadi_out_ en caso de existir, para que no de error el proc append que va agregando
%* las salidas del Hadi aplicado a cada combinacion de las by variables;
proc datasets nolist;
	delete _hadi_out_;
quit;

%*** NOTA: En esta macro no es necesario hacer el format &var statement como habia que hacer
%*** en %Mahalanobis y %CutMahalanobisChi para que la distancia de Mahalanobis fuera correctamente
%*** calculada, porque el calculo de la media y de la matriz de covarianza esta hecha dentro del
%*** IML, con lo cual el orden de las variables no genera ninguna confusion.;

%* Ejecutando las opciones que vengan con el input dataset;
%* Opto por ejecutar todas las opciones ahora, obligatoriamente, porque si no se complica
%* analizar todas las posibilidades que pueden ocurrir;
%let data_name = %scan(&data , 1 , '(');	%* Nombre original del input dataset;
data _hadi_data_;
	set &data;
		%** Notar que aqui no genero la variable con el numero de observacion (_hadi_obs_)
		%** porque primero necesito eliminar las observaciones con missing value en alguna
		%** de las variables;
run;
%let data = _hadi_data_;

%*** Genero la lista de variables separadas por espacios en blanco, para poder usarlas en el %any
%*** del %if de aqui abajo;
%let var = %GetVarList(_hadi_data_ , var=&var, log=0);

%* Numero de observaciones total, incluyendo las observaciones con missing values en alguna variable;
%callmacro(getnobs , _hadi_data_ return=1 , nobsAll);
%if %quote(&by) ~= %then %do;
	%*** Creo una grouping variable para identificar cada grupo dado por las by variables;
	%*** Notar que tambien se eliminan las observaciones con missing values en cualquiera de las
	%*** variables de analisis;
	%CreateGroupVar(_hadi_data_(where=(~%any(&var,=,.))) , by=&by , name=_hadi_code_ , out=_hadi_data_ , log=0);
	%*** Creo una variable con el numero de observacion para ordenar los datasets de salida por
	%*** esta variable de manera que el orden de las observaciones en el dataset de salida sea
	%*** el mismo que el orden del dataset de entrada;
	data _hadi_data_;
		set _hadi_data_;
		_hadi_obs_ = _N_;
	run;
	%let nro_byvars = %GetNroElements(&by);
%end;
%else %do;
	data _hadi_data_;
		set &data;
		where ~%any(&var,=,.);
		_hadi_code_ = 1;	%* Agregando la variable _hadi_code_, para simular que hay un solo cluster;
		_hadi_obs_ = _N_;	%* Notar que el where statement hace que la primera observacion que satisface la condicion del where tenga _N_ = 1, como queremos;
	run;
%end;
%* Numero de observaciones para el analisis (es decir, despues de eliminar las observaciones con missing values en alguna de las variables);
%callmacro(getnobs , _hadi_data_ return=1 , nobsTotal);

%* Subtitulo para los graficos (que tambien es usado en el log, aqui abajo);
%if &boxcox %then
	%let subtitle = based on (transf.) variables;
%else
	%let subtitle = based on variables;

%if &log %then %do;
	%if %eval(&nobsTotal < &nobsAll) %then
		%put HADI: %eval(&nobsAll - &nobsTotal) observation(s) were eliminated due to missing values in some of the analysis variables.;
	%put HADI: Number of total observations used: &nobsTotal..;
	%put HADI: The outlier detection is &subtitle:;
	%put HADI: (%MakeList(%upcase(&var) , sep=%quote( , ))).;
%end;

%* Si boxcox=1, guardo los nombres de las variables originales, porque las necesito para transformar
%* por Box-Cox (dentro del loop por _hadi_code_) para cada combinacion de las by variables;
%* IMPORTANTE: Este paso debe hacerse al final de todo, es decir despues de que la variable &var es
%* usada por ultima vez, ya que aqui actualizo &var con el nombre de las variables analizadas, seguidas
%* del sufijo _bc_;
%if &boxcox %then %do;
	%let var_orig = &var;
	%let var = %MakeList(&var , suffix=_bc_);
%end;

%let i = 0;
%let size = 0;
%let nobsp = 0;		%*** Numero de observaciones que quedan en total;

%do %until (&size = &nobsTotal);
	%let i = %eval(&i + 1);
	data _hadi_clusterComplete_;
		set _hadi_data_ (where = (_hadi_code_ = &i));
		%if %quote(&by) ne %then %do;
			%do j = 1 %to &nro_byvars;
				%local byvar_name&j;
				%let byvar_name&j = %scan(&by , &j , ' ');
				%local byvar_value&j;
				call symput ("byvar_value&j" , &&&byvar_name&j);
			%end;
		%end;
	run;
	%if %quote(&by) ne %then %do;
		%* Lista de byvar values;
		%let byvar_valueslist = %upcase(&byvar_name1)=%sysfunc(trim(%sysfunc(left(&byvar_value1))));
		%do j = 2 %to &nro_byvars;
			%let byvar_valueslist = &byvar_valueslist , %upcase(&&&byvar_name&j)=%sysfunc(trim(%sysfunc(left(&&&byvar_value&j))));
		%end;
		%if &log %then %do;
			%put;
			%put HADI: Cluster &i (&byvar_valueslist);
		%end;
	%end;

	%* Numero de observaciones que intervienen en la deteccion de outliers;
	%callmacro(getnobs , _hadi_clusterComplete_ return=1 , nobsCluster);
	%let size = %eval(&size + &nobsCluster);
	%if &log %then
		%put HADI: Number of observations: &nobsCluster;

	%* Si el usuario lo pidio, se transforman las variables por Box-Cox antes de detectar outliers
	%* para mejorar la normalidad de las variables;
	%* Las variales transformadas son guardadas en variables con el sufijo _bc_, porque necesito conservar
	%* los valores de las variables originales para hacer los graficos y para generar el dataset de salida,
	%* si lo hubiera;
	%if &boxcox %then %do;
		%if &log %then %do;
			%put;
			%put HADI: Transforming variables by Box-Cox prior to outlier detection...;
		%end;
		%Boxcox(_hadi_clusterComplete_ , var=&var_orig , out=_hadi_clusterComplete_ , outLambda=_hadi_clusterLambdas_ ,
										 suffix=_bc_ , log=0 , lambda=&lambda);
		%if &log %then %do;
			data _NULL_;
				set _hadi_clusterLambdas_;
				_var_ = upcase(var);
				put "HADI: " _var_ ": lambda = " lambda_opt;
			run;
			%put;
			%put HADI: Start outlier detection...;
		%end;
	%end;

	%* Creando un dataset con solo las variables a utilizar en la deteccion de outliers,
	%* para facilitar su lectura en el PROC IML;
	%* Este data step debe ser hecho despues de hacer %Boxcox, porque deben existir en
	%* _hadi_clusterComplete_ las variables transformadas con el sufijo _bc_, y estas son creadas
	%* en %Boxcox;
	data _hadi_cluster_ (keep = &var);
		set _hadi_clusterComplete_;
	run;

	/****************** COMIENZA EL ALGORITMO DE HADI PROPIAMENTE DICHO *******************/
	proc IML;
		%* Referencia a la biblioteca con los modulos utilizados;
		reset storage = &_IMLLabModelos_;

		file log;	%*** Para que los put los mande al log;

		%*Lee solo las columnas con datos del cluster original;
		use _hadi_cluster_;
			read all into mData;
		close _hadi_cluster_;

		%*Inicializa las variables y matrices.;
		n = nrow(mData);
		p = ncol(mData);
		tol = max (10**(-(p+5)), 10**-12);
		mOnesAll = j(n, 1);
		alpha = &alpha;
		if alpha < 0 | alpha > 1 then do;
			put "HADI: WARNING - The alpha level specified is not valid. Using the default (0.05).";
			alpha = 0.05;
		end;
		cf = ( 1 + (p+1)/(n-p) + 2/(n-1-3*p) )**2;
			%* Correction Factor para que la distancia de Mahalanobis tenga distribucion Chi2
			%* Este valor es muy cercano a 1 para n grandes;

		%*** Ajuste del alpha por el numero de observaciones si es requerido;
		%if &adjust %then %do;
				%* Bonferroni adjustment;
		%*	alpha_adj = alpha/n;
				%* Adjustment assuming independence;
			alpha_adj = 1 - (1 - alpha)**(1/n);
		%end;
		%else %do;
			alpha_adj = alpha;
		%end;
		cuantil = cinv(1 - alpha_adj,p);
		cv2 = sqrt(cf * cuantil);
		mDist = 0;
		
		/*--------
		  STEP 0
		--------*/
		%*Calcula el centro tomando la mediana de todos los datos y calcula
		las distancias de Mahalanobis a ese centro con una matriz de 
		covarianza especial.;

		%if &log %then %do;
			put "HADI: step 0 - Computing Mahalanobis distances to the median.";
		%end;
		mCenter = median(mData);
		%*mCenter = quartile(mData)[3,];	%*** Tomando el tercer quartil;
		mCenterCopied = mOnesAll * (mCenter);
		mDataStandard = mData - mCenterCopied;
		mCov = (1/(n - 1)) * (mDataStandard` * mDataStandard);

		%*Ordena toda la base segun la distancia Mahalanobis.;
		mDist = Mahalanobis (mData , mCenter , mCov);
		order = Order(mDist);

		/*--------
	  	  STEP 1
		--------*/
		%* Calcula un nuevo centro usando las observaciones cercanas al 
		centro del paso 0.;

		fin = 0;
		%if %sysevalf(&fractionGood < 0) or %sysevalf(&fractionGood > 1) %then %do;
			%let fractionGood = 0.5;
		%end;
		frac = &fractionGood;		%*** Fraccion de observaciones a considerar como buenas, inicialmente;
		%*h = int(0.5*(n + p + 1));		%*** Valor que aparece en el programa original del Sr. Hadi;
		h = max( int(frac*(n + p + 1)), min(20 , int(0.5*(n + p + 1))) );
			%*** Toma aprox. el frac% de los puntos como puntos iniciales,
			%*** o bien 20 puntos, si es que el frac% es menor que 20,
			%*** o bien aprox. la mitad, si es que el nro total de obs analizadas es < 20;

		%if &log %then %do;
			put "HADI: step 1 - Computing the mean based on " (trim(left(char(h)))) " (~" (trim(left(char(frac*100)))) "%) 'good' observations.";
		%end;
		
		do until (fin = 1);
			mDataY = mData[order[1:h],];
			%*Calcula la covarianza.;
			mOnes = j(h, 1);
			mCenter = mDataY[+,]/h;

			mCenterCopied = mOnes * (mCenter);
			mDataStandard = mDataY - mCenterCopied;
			mCov = (mDataStandard` * mDataStandard) / (h - 1);
			mDist = Mahalanobis (mData, mCenter, mCov);
			order = Order(mDist);
			fin = 1;
		end;
			
		/*--------
		  STEP 2
		--------*/
		%* Agrega observaciones de a una al conjunto de observaciones que no
		seran consideradas outliers, a partir de las p observaciones con menor
		distancia de Mahalanobis del step 1.;
		%if &log %then %do;
			%put HADI: step 2 - Adding observations to the 'good' set, based on the smaller;
			%put HADI:          Mahalanobis distances.;
		%end;
		r = p;
		fin = 0;
		do while (r < h);
			r = r + 1;
			mDataY = mData[order[1:r],];
			%*Calcula la covarianza.;
			mOnes = j(r, 1);
			mCenter = mDataY[+,]/r;
			mCenterCopied = mOnes * (mCenter);
			mDataStandard = mDataY - mCenterCopied;
			mCov = (mDataStandard` * mDataStandard) / (r - 1);
			mDist = Mahalanobis (mData, mCenter, mCov);
			order = Order(mDist);
		end;
		/*--------
		  STEP 3
		--------*/
		%* Agrega observaciones de a una al conjunto de las observaciones no
		consideradas outliers hasta que la distancia de Mahalanobis sea mayor que
		la pedida a través de los parámetros.;

		%if &log %then %do;
			put "HADI: step 3 - Detecting outliers (Mahalanobis Distance Threshold = " (trim(left(char(round(cv2,0.001))))) ").";
		%end;
		fin = 0;
		
		do while (h < n & fin = 0);
			mDataY = mData[order[1:h],];
			%*Calcula la covarianza.;
			mOnes = j(h, 1);
			mCenter = mDataY[+,]/h;
			mCenterCopied = mOnes * (mCenter);
			mDataStandard = mDataY - mCenterCopied;
			mCov = (mDataStandard` * mDataStandard) / (h - 1);
			mDist = Mahalanobis (mData, mCenter, mCov);
			order = Order(mDist);
			if (mDist[order[h+1]] >= cv2) then fin = 1;
			else h = h + 1;
		end;
		%* NOTA IMPORTANTE: Las observaciones que quedan en el conjunto de observaciones
		%* consideradas no outliers pueden tener distancia de Mahalanobis mayor que el
		%* threshold. Esto se debe a que la iteracion anterior (el until del Step 3)
		%* termina cuando la observacion h + 1 (segun el orden dado por las distancias de
		%* Mahalanobis) es mayor que el threshold, pero nada dice sobre las observaciones
		%* 1 a h segun ese orden. Por un lado, estas observaciones no tienen por que
		%* ser las mismas h observaciones que en la iteracion anterior, pues las
		%* distancias de Mahalanobis fueron recalculadas con el nuevo centro y con la nueva
		%* matriz de covarianza, por lo que observaciones que antes estaban dentro de las h
		%* mejores, ahora no estan mas en ese grupo. Por otro lado, sus distancias de
		%* Mahalanobis seguramente cambiaron en la ultima iteracion (en la que el ciclo
		%* termina) debido a que nuevamente se recalcularon las distancias de Mahalanobis
		%* con el nuevo centro y nueva matriz de covarianza;
		quedan = order [1:h];
		outlier = j(n,1,1);
		outlier[quedan] = 0;
		create _hadi_outlier_ from outlier [colname = {&nameOutlier}] ;
			append from outlier;
		close _hadi_outlier_;
		create _hadi_distance_ from mDist [colname = {&nameDistance}];
			append from mDist;
		close _hadi_distance_;

		%*** Macro variables necesarias al salir del IML;
		call symput('nobspCluster' , char(nrow(quedan)));
		call symput('threshold' , char(cv2));
		call symput('alpha_adj' , char(alpha_adj));
	quit;
	%let nobsp = %eval(&nobsp + &nobspCluster);
	
	data _hadi_cluster_out_;
		format &varOrder &nameDistance _THRESHOLD_ _ALPHA_ _ALPHA_ADJ_ &nameOutlier;
		merge _hadi_clusterComplete_ _hadi_distance_ _hadi_outlier_;
		retain 	_THRESHOLD_ &threshold
				_ALPHA_ &alpha
				_ALPHA_ADJ_ &alpha_adj;
		label 	_THRESHOLD_ = "Mahalanobis threshold for the detection of outliers"
				_ALPHA_ 	= "Alpha Level"
				_ALPHA_ADJ_	= "Adjusted Alpha Level";
	run;

	%* Agregando el _hadi_out_ correspondiente al cluster actual a todo el _hadi_out_;
	proc append base=_hadi_out_ data=_hadi_cluster_out_;
	run;

	%if &log and %quote(&by) ne %then %do;
		%callmacro(getnobs , _hadi_cluster_out_ return=1 , nobsCluster);
		%put HADI: Number of observations processed: &nobsCluster;
		%put HADI: Number of outliers detected: %eval(&nobsCluster-&nobspCluster) (%sysfunc(round(%sysevalf ((&nobsCluster-&nobspCluster)/&nobsCluster*100) , 0.01))%);
	%end;

	/*
	%if (%quote(&outAll) ne) %then %do;
		proc append base=&outAll_library..&outAll_name data=_hadi_out_;
		run;
	%end;

	%if (%quote(&out) ne) %then %do;
		%if &i = 1 %then %do;
			data &out_name (drop = &nameOutlier);
				set _hadi_out_ (where = (&nameOutlier = 0));
			run;
		%end;
		%else %do;
			data &out_name (drop = &nameOutlier);
				set &out_name _hadi_out_ (where = (&nameOutlier = 0));
			run;
		%end;
		%*** Nota: No hago un PROC APPEND como para &outAll porque me genera
		%*** warnings en la salida al pedir que haga drop de &nameOutlier y 
		%*** no logro eliminar esos warnings (esta la opcion dkrocond que
		%*** se podia setear a dkrocond=nowarning, pero esto no elimina todos
		%*** los warnings);

		%* Ejecutando las opciones que vengan con &out si es que hay;
		%if %length(&out_options) > 0 %then %do;
			data &out;
				set &out;
			run;
		%end;
	%end;
	*/

%end;	%* %do %until;

%let var_bc = ;		%* Genero una lista vacia para que no de error el drop= del _hadi_out_
					%* al generar los output datasets mas abajo (en caso de que Box-Cox no se haya pedido);
%if &boxcox %then %do;
	%* Ahora genero una macro variable con la lista de variables transformadas por Box-Cox.
	%* No sigo con &var como variables transformadas, porque ahora la mayoria de los graficos
	%* estan hechos en funcion de las variables originales, por lo que cada vez que ponga &var
	%* quiero que SAS interprete a las variables originales, y la unica vez en que quiero graficar
	%* las variables transformadas (en uno de los scatter plots), le digo que use &var_bc, que tiene
	%* la lista de variables transformadas; 
	%let var_bc = &var;
	%* Vuelvo a la lista de variables originales, para hacer los graficos y generar el output dataset;
	%let var = &var_orig;
%end;

%if &log %then %do;
	%put;
	%put HADI: Total number of observations processed: &nobsTotal;
	%put HADI: Total number of outliers: %eval(&nobsTotal-&nobsp) (%sysfunc(round(%sysevalf ((&nobsTotal-&nobsp)/&nobsTotal*100) , 0.01))%);
%end;

%* Grafico de los outliers detectados: scatter plots y distancias de Mahalanobis by obs. number;
%if &plot %then %do;
	%let clusterInfo = ;
	%* Leyendo el numero de combinaciones distintas de los valores las by variables;
	proc freq data=_hadi_out_ noprint;
		tables _hadi_code_ / out=_hadi_codes_(keep=_hadi_code_);
	run;
	%callmacro(getnobs , _hadi_codes_ return=1 , nro_codes);
	%do i = 1 %to &nro_codes;
		data _hadi_toplot_;
			set _hadi_out_(where=(_hadi_code_=&i));
			%if %quote(&by) ne %then %do;
				%do j = 1 %to &nro_byvars;
					%local byvar_name&j;
					%let byvar_name&j = %scan(&by , &j , ' ');
					%local byvar_value&j;
					call symput ("byvar_value&j" , &&&byvar_name&j);
				%end;
			%end;
		run;
		%if %quote(&by) ne %then %do;
			%* Lista de byvar values;
			%let byvar_valueslist = %upcase(&byvar_name1)=%sysfunc(trim(%sysfunc(left(&byvar_value1))));
			%do j = 2 %to &nro_byvars;
				%let byvar_valueslist = &byvar_valueslist , %upcase(&&&byvar_name&j)=%sysfunc(trim(%sysfunc(left(&&&byvar_value&j))));
			%end;
		%end;
		%if %quote(&by) ne %then
			%let clusterInfo = %quote( -) Cluster &i (&byvar_valueslist);
		symbol2 value=square;
		%* Scatter plots;
		%if &scatter %then %do;
			%DefineSymbols;
			%if %GetNroElements(&var) > 1 %then %do;
				%Scatter(_hadi_toplot_ , var=&var , strata=&nameOutlier ,
				 		title="Outliers detected by HADI (%upcase(&data_name)&clusterInfo)" justify=center "&subtitle: %MakeList(%upcase(&var) , sep=%quote( , ))");
							%** La macro variable &subtitle es generada al principio, justo despues de que termina %Boxcox;
				%if &boxcox %then %do;
					%Scatter(_hadi_toplot_ , var=&var_bc , strata=&nameOutlier ,
					 		title="Outliers detected by HADI (%upcase(&data_name)&clusterInfo)" justify=center "Plot of transformed variables: %MakeList(%upcase(&var_bc) , sep=%quote( , ))");
				%end;
			%end;
			%else %do;
				axis1 label=("Observation number");
				title "Outliers detected by HADI (%upcase(&data_name)&clusterInfo)" justify=center
						"&subtitle: %MakeList(%upcase(&var) , sep=%quote( , ))";
				proc gplot data=_hadi_toplot_;
					plot &var * _hadi_obs_ = &nameOutlier / haxis=axis1;
				run;
				quit;
				title;
				axis1;
			%end;
			%DefineSymbols;
		%end;
		%* Distancias de Mahalanobis vs. obs. number;
		%if &mahalanobis %then %do;
			data _hadi_anno_(keep=xsys ysys x y function text position when);
				set _hadi_toplot_(obs=1);
				xsys="1"; ysys="2"; x=2; y=_threshold_; function="label";
					text="Mahalanobis threshold = " || trim(left(round(_threshold_,0.001)));
					position="3";	%* Left aligned;
					when="A";		%* Hacer el grafico primero y luego anotar, para que los puntos no superpongan el texto;
				call symput('threshold' , _threshold_);
			run;
			%DefineSymbols;
			axis1 label=("Observation number");
			title "Mahalanobis distances used in Hadi (%upcase(&data_name)&clusterInfo)" justify=center
					"&subtitle: %MakeList(%upcase(&var) , sep=%quote( , ))";
			%* Calculo el valor maximo de la distancia de Mahalanobis, por si el valor del threshold es
			%* mayor que el, con lo que corre el riesgo de no aparecer en el grafico si no hago algo al respecto;
			%GetStat(_hadi_toplot_ , var=&nameDistance , stat=max , name=_max_ , log=0);
			axis2 label=(angle=90);
			%* Fuerzo que se muestre la linea indicando el threshold (aun cuando su valor estaria fuera del
			%* rango de valores de la distancia de Mahalanobis;
			%if %sysevalf(&threshold > &_max_) %then %do;
				%let step = %sysevalf(&threshold/5);
				axis2 order=(0 to &threshold by &step);
			%end;
			proc gplot data=_hadi_toplot_ annotate=_hadi_anno_;
				plot &nameDistance * _hadi_obs_ = &nameOutlier / haxis=axis1 vaxis=axis2 vref=&threshold cvref=Green;
			run;
			quit;
			title;
			axis1;
			%DefineSymbols;
			%symdel _max_;		%* _max_ devuelta por %GetStat es global variable;
			quit;	%* Para que el %symdel no cause problemas;
		%end;
	%end;
%end;	%* if &plot;

%****** Output datasets ********;
%* Nota: &var_bc tiene la lista de variables transformadas (si boxcox=1) o bien es vacia.
%* Su valor es generado justo antes de %if &plot mas arriba;
%* OUT;
%if (%quote(&out) ne) %then %do;
	%* Recuperando el orden original del input dataset en caso de que haya un by statement.
	%* Ordeno por numero de observacion, para que las observaciones esten en el orden que vinieron en
	%* el input dataset;
	proc sort data=_hadi_out_;
		by _hadi_obs_;
	run;
	data &out;		%* Aqui se ejecutan las opciones que venian con &out;
		set _hadi_out_(where=(&nameOutlier=0) drop=_hadi_code_ _hadi_obs_ &var_bc);
 		drop &nameOutlier;
	run;
	%if &log %then
		%put HADI: Dataset %upcase(%scan(&out , 1 , '(')) created.;
%end;

%* OUTALL;
%if (%quote(&outAll) ne) %then %do;
	%* Recuperando el orden original del input dataset en caso de que haya un by statement.
	%* Ordeno por numero de observacion, para que las observaciones esten en el orden que vinieron en
	%* el input dataset;
	%if (%quote(&by) ne) %then %do;
		proc sort data=_hadi_out_;
			by _hadi_obs_;
		run;
	%end;
	data &outAll;		%* Aqui se ejecutan las opciones que venian con &outAll;
		set _hadi_out_(drop=_hadi_code_ _hadi_obs_ &var_bc);
	run;
	%if &log %then
		%put HADI: Dataset %upcase(%scan(&outAll , 1 , '(')) created.;
%end;

proc datasets nolist;
	delete	_hadi_anno_
			_hadi_cluster_
			_hadi_cluster_out_
			_hadi_clusterComplete_
			_hadi_clusterLambdas_
			_hadi_codes_
			_hadi_data_
			_hadi_distance_
			_hadi_out_
			_hadi_outlier_
			_hadi_toplot_;
quit;

%if &log %then %do;
	%put;
	%put HADI: Macro ends;
	%put;
%end;

%ResetSASOptions;
%end;	%* if ~%CheckInputParameters;
%MEND Hadi;

