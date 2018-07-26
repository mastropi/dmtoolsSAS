/* MACRO %Boxcox
Version: 1.09
Author: Daniel Mastropietro
Created: 12-Dec-02
Modified: 11-Feb-04

DESCRIPTION:
Efectúa la transformación de Box-Cox univariada a un conjunto de datos.
La transformación de Box-Cox tiene tres parámetros y es de la forma:
 
T(x) = x0 { 1 + [((x + s)/x0)^lambda - 1] / lambda }, 	si lambda ~= 0
T(x) = x0 [ 1 + log((x + s)/x0) ],						si lambda  = 0.

Donde x es la variable a transformar, x0 es el matching point (es decir
el punto cuyo valor no es alterado por la transformación), s es el shift
que debe hacerse a la variable original x para que todos sus valores
sean positivos, y lambda es el parámetro de la transformación que maximiza
la log-likelihood de la variable transformada con el requisito de que la
variable transformada tenga distribución normal.
Por default el matching point es la mediana de los datos a transformar. 
La función log() indica logaritmo natural.

USAGE:
%Boxcox(
	data ,					*** Input dataset (required)
	var=_numeric_ ,			*** Variables a transformar
	out= ,					*** Output dataset
	suffix=_bc ,			*** Sufijo a usar para las variables transformadas
	lambda=-3 to 3 by 0.01,	*** Search space del lambda optimo
	exclude= ,				*** Lista de valores a excluir del analisis
	outLambda= ,			*** Dataset con el lambda optimo para c/variable
	outLoglik= ,			*** Dataset c/log-lik p/lambdas del search space
	confidence=0.95 ,		*** Nivel de confianza p/el intervalo de lambda
	matchingPoint=median ,	*** Metodo o valor para la eleccion del x0
	mu=mean,				*** Estimacion de la media a usar en el Q-Q plot
	sigma=std,				*** Estimacion del desvio a usar en el Q-Q plot
	real=0 , 				*** Utilizar el valor real del lambda optimo?
	plot=0 ,				*** Mostrar graficos?
	loglik=1 ,				*** Mostrar grafico de la log-likelihood?
	qqplot=1 , 				*** Hacer Q-Q plot?
	histogram=0 , 			*** Hacer histograma?
	log=1 ,					*** Mostrar mensajes en el Log?
	macrovar=);				*** Macro variable donde se guarda la lista de
							*** variables transformadas;

REQUIRED PARAMETERS:
- data:			Input dataset con los datos a utilizar. Puede recibir
				cualquier opción adicional como en cualquier opción
				data= de SAS.

OPTIONAL PARAMETERS:
- var:			Lista de las variables a transformar por Box-Cox, separadas
				por espacios.
				default: _numeric_, es decir todas las variables numéricas

- out:			Output dataset. Este dataset tiene las mismas columnas que el
				input dataset al que se le agregan columnas con las
				variables transformadas por Box-Cox. Los nombres de estas
				columnas coinciden con los nombres de las variables
				originales con el sufijo indicado por el parámetro
				'suffix' (default = _bc).
				(Ej: si 'x' es la variables original y suffix=T, la
				variable transformada se llama 'xT'.)
				Si el parametro es vacio, las variables transformadas son
				almacenadas en ningun lado.
				Para crear las variables transformadas en el input dataset,
				especificar el nombre del input dataset en este parámetro. 

- suffix:		Sufijo a utilizar para nombrar las variables transformadas
				(sin encerrar entre comillas). Si su valor es vacío, las
				variables transformadas tienen el mismo nombre que las
				variables originales.
				default: _bc

- lambda:		Espacio de búsqueda para el parámetro lambda de la
				transformación Box-Cox. El parámetro lambda que se utiliza
				en la transformación de Box-Cox resulta de maximizar la
				log-likelihood de la variable transformada en el rango de
				variación definido por 'lambda'.
				formato: lambda=lambda_min TO lambda_max BY step
				default: -3 to 3 by 0.01

- exclude:		Lista de valores separados por espacios a excluir del analisis
				que busca el valor de lambda a utilizar en la transformacion de
				Box-Cox.
				Los valores excluidos no son utilizados en el cálculo del lambda
				que maximiza la log-likelihood, y son dejados en la variable
				transformada con el mismo valor que en la variable original.

- outLambda:	Output dataset donde se guardan los valores de lambda que
				efectúan la transformación de Box-Cox para cada variable, así
				como sus intervalos de confianza.
				Tiene las siguientes columnas (en este orden):
				- var:			Nombre de la variable transformada.
				- lambda_real:	Valor de lambda que maximiza la log-likelihood.
				- lambda_opt:	Valor de lambda usado en la transf. Box-Cox.
				- lambda_lower:	Límite inf. del intervalo de confianza p/lambda.
				- lambda_upper:	Límite sup. del intervalo de confianza p/lambda.
				- confidence:	Nivel de confianza p/los intervalos de confianza.
				- matchingValue:Valor del matching point usado en la transforamción.
				- shift:		Shift con que se corre la variable antes de transformar.
				- loglik:		Valor maximo de la log-likelihood corresp. a lambda_real.
				- matchingPoint:Forma de calcular el matching point (mean, median, ...)
				NOTA: toda opción adicional del tipo de las usadas en opciones
				data= de SAS son ignoradas.

- outLoglik:	Output dataset donde se guardan los valores de lambda del search
				space (según viene especificado por el parámetro 'lambda') y los
				valores de la log-likelihood correspondientes. El dataset tiene
				tantas columnas como variables listadas en el parámetro 'var'
				más una:
				- lambda:		Valores del search space del lambda óptimo.
				- L_<varj>:		Valores de la log-likelihood para cada lambda
								para cada variable 'varj'.
				Ej: si var=x y, el dataset tiene 3 columnas: lambda, L_x, L_y.
				NOTA: toda opción adicional del tipo de las usadas en opciones
				data= de SAS son ignoradas.

- confidence:	Nivel a usar para el intervalo de confianza para lambda.
				default: 0.95

- matchingPoint:Indica qué valor se utiliza para el matching point, x0, que es
				el punto cuyo valor no es alterado por la transformación de
				Box-Cox. Puede indicarse de dos formas distintas:
				a) Con el nombre de la función a utilizar para calcular x0 a
				partir de las variables originales.
				b) Con el valor numérico que se desea utilizar para x0. 
				En el caso de dar el nombre de la función, éste puede ser
				alguno de los siguientes: median, min, max ó mean.
				(Notar que si se elige como	matching point a la media, la media
				de los valores transformados no tiene por qué coincidir con la
				media de los valores originales.)
				default: median

- mu:			Estimación de la media a utilizar en los Q-Q plot
				o Probability plots que evalúan la normalidad de las variables.
				A parte de valores numéricos, keywords permitidas son: mean, median.
				La opción 'median' provee una estimación más robusta de la media.
				default: mean (i.e. la media)

- sigma:		Estimación del desvío estándar (sigma) a utilizar en los Q-Q plot
				o Probability plots que evalúan la normalidad de las variables.
				A parte de valores numéricos, keywords permitidas son: std, hspr
				(hspr = half spread = qrange/1.349,	donde qrange significa
				interquartile range = Tercer cuartil - Primer cuartil).
				La opción 'hspr' provee una estimación más robusta de sigma.
				default: std (i.e. desvío estándar de los datos)

- real:			Indica si en la transformación de Box-Cox se desea utilizar el
				valor real encontrado para el lambda que maximiza la
				log-likelihood.
				Si no se desea utilizar el valor real, las variables son
				transformadas con lambda = 0 si el intervalo de confianza para
				lambda incluye el 0, o con lambda = 1 si el intervalo de
				confianza incluye el 1. En cualquier otro caso, se utiliza el
				valor real de lambda encontrado.
				Valores posibles: 	0 => No usar el valor real
									1 => Sí, usar el valor real.
				default: 0

- plot:			Indica si se desea ver los gráficos generados por la macro.
				Se generan los siguientes gráficos para cada variable transformada:
				- log-likelihood en función de los distintos valores de lambda
				- Q-Q plots de la variable antes y después de transformar
				- Histogramas de la variable antes y después de transformar
				Si el parámetro pide mostrar gráficos, por default se muestran
				el gráfico de la log-likelihood y los Q-Q plots.
				La selección de los gráficos se hace con los parámetros 'loglik',
				'qqplot' y 'histogram'.
				Valores posibles: 0 => No, 1 => Sí.
				default: 0

- loglik:		Indica si se desea ver el gráfico de la log-likelihood en función
				de los distintos valores de lambda, para cada variable.
				Valores posibles: 0 => No, 1 => Sí.
				default: 1

- qqplot:		Indica si se desea ver los Q-Q plots de cada variable antes y
				después de la transformación.
				Valores posibles: 0 => No, 1 => Sí.
				default: 1

- histogram:	Indica si se desea ver los histogramas de cada variable antes y
				después de la transformación.
				Valores posibles: 0 => No, 1 => Sí.
				default: 0

- log:			Indica si se desea ver mensajes en el log generados por la macro.
				Valores posibles: 0 => No, 1 => Sí.
				default: 1

- macrovar:		Nombre de la macro variable donde se guarda la lista de variables
				transformadas.
				Este parámetro es útil cuando el número de variables a transformar
				es alto y luego se desea hacer referencia a todas las variables
				transformadas.

NOTES:
- En el caso de tener variables con valores positivos, es conveniente usar como
matching point el mínimo de los datos (es decir matchingPoint=min). De esta
manera, el valor mínimo de las variables transformadas seguirá siendo positivo.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %CheckInputParameters
- %GetDataName
- %GetVarOrder
- %MakeList
- %Qqplot
- %ResetSASOptions
- %SetSASOptions

EXAMPLES:
1.- %Boxcox(test(where=(x>0 and y>0)) , out=test_bc , var=x y ,
			lambda=-1 to 1 by 0.1 , outLambda=lambda_opt , 
			outLoglik=loglik , matchingPoint=min , plot=1);
Busca el lambda optimo para las variables x e y (a partir de los valores
positivos de las mismas) en el intervalo [-1,1] variando lambda a intervalos
de 0.1.
Crea el dataset TEST_BC con todas las variables del input dataset más las
variables transformadas, x_bc, y_bc. 
Crea el dataset LAMBDA_OPT con los valores óptimos de lambda encontrados y
los intervalos de confianza para el verdadero valor de lambda correspondiente
a cada variable.
Crea el dataset LOGLIK con los valores de la log-likelihood para cada uno de
los valores de lambda del espacio de búsqueda.
Utiliza como matching point (es decir el valor que no es afectado por la
transformación), el valor mínimo de 'x > 0' y de 'y > 0'.
De esta manera, las variables transformadas seguiran siendo positivas.

2.- %Boxcox(test , out=test_bc(keep=x_bc y_bc) , var=x y , matchingPoint=1);
Utiliza el valor 1 como matching point para efectuar la transformacion de
Box-Cox. Es decir, el valor 1 no es afectado por la transformacion.
Crea el dataset TEST_BC que contiene solamente las variables transformadas,
x_bc, y_bc.

3.- %Boxcox(test , out=test , var=x y , suffix=T , macrovar=listT);
Crea las variables transformadas xT, yT en el dataset de entrada, TEST.
Crea la macro variable listT donde se guarda la lista de las variables
transformadas (Es decir &listT = xT yT).

4.- %Boxcox(test , var=x y , plot=1 , histogram=1);
No crea ningun dataset de salida. Simplemente calcula los valores del
parámetro lambda que maximiza la log-likelihood para cada variable
especificada y hace todos los gráficos posibles (log-likelihood, Q-Q plots
de las variables originales y transformadas e histogramas de las variables
originales y transformadas).

5.- %Boxcox(test , var=x y , exclude=0 0.5, macrovar=var_bc);
Excluye los valores 0 y 0.5 del análisis para el cálculo del lambda de la
transformación tanto para x como para y.
Además genera la macro variable var_bc con la lista de variables transformadas.
En este caso &var_bc = x_bc y_bc.

APPLICATIONS:
1.- Transformación de variables previo a un proceso de detección de outliers que
supone distribución normal multivariada de las mismas.
Notar sin embargo, que %Boxcox efectúa la transformación individualmente a cada variable,
sin tener en cuenta su distribución conjunta. (Aunque esto podría implementarse en un futuro.)

2.- Generar una variable que tiene una distribución más simétrica que la variable original.

3.- Separar valores muy apiñados de una variable para poder verlos mejor en un gráfico (por
ej. en un scatter plot entre la variable respuesta de una regresión y una variable regresora).
*/
%MACRO Boxcox(data ,
			  var=_NUMERIC_ ,
			  out= ,
			  suffix=_bc ,
			  lambda=-3 to 3 by 0.01 ,
			  exclude= ,
			  outLambda= ,
			  outLoglik= ,

			  confidence=0.95 ,
			  matchingPoint=median ,
			  mu=mean ,
			  sigma=std ,
			  real=0 ,

			  plot=0 ,
			  loglik=1 ,
			  qqplot=1 ,
			  histogram=0 ,
			  log=1 ,

			  macrovar= ,

			  help=0) / des="Performs Box-Cox transformation of variables";

/*----- Macro to display usage -----*/
%MACRO ShowMacroCall;
	%put BOXCOX: The macro call is as follows:;
	%put %nrstr(%Boxcox%();
	%put data , (REQUIRED) %quote(      *** Input dataset.);
	%put var=_NUMERIC_ , %quote(        *** Variables a transformar.);
	%put out= , %quote(                 *** Output dataset.);
	%put suffix=_bc , %quote(           *** Sufijo a usar para las variables transformadas.);
	%put lambda=-3 to 3 by 0.01, %quote(*** Search space del lambda optimo.);
	%put exclude= , %quote(             *** Lista de valores a excluir del analisis.);
	%put outLambda= , %quote(           *** Dataset con el lambda optimo para c/variable.);
	%put outLoglik= , %quote(           *** Dataset c/log-lik p/lambdas del search space.);
	%put confidence=0.95 , %quote(      *** Nivel de confianza p/el intervalo de lambda.);
	%put matchingPoint=median , %quote( *** Metodo o valor para la eleccion del x0.);
	%put real=0 , %quote(               *** Utilizar el valor real del lambda optimo?);
	%put plot=0 , %quote(               *** Mostrar graficos?);
	%put loglik=1 , %quote(             *** Mostrar grafico de la log-likelihood?);
	%put qqplot=1 , %quote(             *** Hacer Q-Q plot?);
	%put histogram=0 , %quote(          *** Hacer histograma?);
	%put log=1 , %quote(                *** Mostrar mensajes en el log?);
	%put macrovar=) %quote(             *** Macro variable donde se guarda la lista de variables);
	%put %quote(                            transformadas.);
%MEND ShowMacroCall;

%if &help %then %do;
	%ShowMacroCall;
%end;
%else %if ~%CheckInputParameters(data=&data , var=&var , macro=BOXCOX) %then %do;
	%ShowMacroCall;
%end;
%else %do;
/************************************* MACRO STARTS ******************************************/
/* Local variables declaration */
%local i j;				%* Index variables;
%local alpha_sw;		%* Level for Shapiro-Wilk test;
%local data_name;		%* Name of input dataset;
%local _exclude_;		%* Takes in turn the value of each element passed in parameter exclude=;
%local lambda_opt;		%* Value of optimum lambda (value of lambda used in transformation);
%local lambda_real;		%* Value of lambda that maximizes the log-likelihood;
%local L_cols;			%* Column names with the log-likelihood for each variable;
%local nobs;			%* Number of observations in the dataset;
%local notes_option;	%* Local variable used to store the value of the NOTES option, used
						%* when parsing input parameter exclude=;
%local nro_exclude;		%* Number of elements passed in parameter exclude=;
%local nvar;			%* Number of variables to be transformed;
%local order;			%* Order of the variables in the input dataset;
%local out2000;			%* Dataset used for Shapiro-Wilk test of normality since this test
						%* works for a maximum of 2000 observations;
%local out_name;		%* Name of output dataset;
%local out_options;		%* Options for output dataset;
%local out_param;		%* Name of output dataset as passed in the out= parameter;
%local pvalues;			%* Variable names containing the p-values for the Shapiro-Wilk test
						%* for each variable;
%local roundoff;		%* Value used in the round function to define the nro. of decimal
						%* places of lambdas and p-values to show in the log;
%local validMatchingPoints;	%* List with valid names for parameter matchingPoint= in case it
							%* is not a number;
%local var_t;			%* Names of transformed variables;
%local _var_;			%* Temporary variable to store the name of current analyzed variable;
%local varOrder;		%* List of variables in the order they appear in the input dataset;
%local varOrder_t;		%* List of transformed variables in the order they appear in the
						%* input dataset;
%local y;				%* Variable used in the Y axis of the plots;

%*Setting options and getting current options settings;
%SetSASOptions;

%* Showing input parameters;
%if &log %then %do;
	%put;
	%put BOXCOX: Macro starts;
	%put;
	%put BOXCOX: Input parameters:;
	%put BOXCOX: - Input dataset = %quote(&data);
	%put BOXCOX: - var = %quote(          &var);
	%put BOXCOX: - out = %quote(          &out);
	%put BOXCOX: - suffix = %quote(       &suffix);
	%put BOXCOX: - lambda = %quote(		  &lambda);
	%put BOXCOX: - exclude = %quote(      &exclude);
	%put BOXCOX: - outLambda = %quote(	  &outlambda);
	%put BOXCOX: - outLoglik = %quote(	  &outloglik);
	%put BOXCOX: - confidence = %quote(	  &confidence);
	%put BOXCOX: - matchingPoint = %quote(&matchingPoint);
	%put BOXCOX: - real = %quote(         &real);
	%put BOXCOX: - plot = %quote(         &plot);
	%put BOXCOX: - loglik = %quote(		  &loglik);
	%put BOXCOX: - qqplot = %quote(		  &qqplot);
	%put BOXCOX: - histogram = %quote(	  &histogram);
	%put BOXCOX: - log = %quote(          &log);
	%put BOXCOX: - macrovar = %quote(     &macrovar);
	%put;
%end;

/*----- Variable settings -----*/
%* Round off that defines the number of decimal places of lambda to show in the log;
%let roundoff = 0.0001;
%* Level to display a warning that a transformed variable may not be normally distributed;
%let alpha_sw = 0.0001;
%* Nombres admisibles para la funcion utilizada para calcular el matching point x0.
%* (deben ser escritos en minusculas porque luego comparo con lowcase(&matchingPoint);
%let validMatchingPoints = median min max mean;

/*----- Parsing input parameters -----*/
%*** Guardando el orden de las variables en el input dataset para poder generar
%*** un dataset de salida con el mismo orden de las variables;
%GetVarOrder(&data , order);		%* Notar que las opciones que vengan en &data se ejecutan en %GetVarOrder;
%*** Genero una lista con las variables transformadas en el orden en que aparecen en el dataset
%*** para que el dataset de salida tenga las variables transformadas en dicho orden, y no haya
%*** confusion;
%let data_name = %scan(&data , 1 , '(');
%GetVarOrder(&data_name(keep=&var) , varOrder);
%let varOrder_t = %MakeList(&varOrder , suffix=&suffix);

%*** Leo todo el dataset en un dataset temporario, para poder usar el format statement
%*** que me respete el orden de las variables listadas en &var, y de esta manera
%*** las transformaciones Box-Cox se analicen en ese orden;
%*** Ademas creo una variable con el numero de observacion para despues poder mergear
%*** sin riesgos al armar el output dataset (hacia el final). Notar que el numero de observacion
%*** no es agregado al dataset original, sino a un dataset temporario;
data _Boxcox_data_(sortedby=_boxcox_obs_);
		%* Le digo a sas que el dataset esta sorted by _obs_ para que despues, cuando mergeo con el
		%* output dataset by _obs_, no pierda tiempo en el sort previo si es que el sorted by _obs_ se mantuvo;
		%* NOTA: En realidad, en estos momentos (29/7/03), no se hace ningun sorting antes del merge
		%* porque en el codigo en ninguna parte se cambia el orden de las observaciones. Igual este
		%* sortedby lo dejo por si en un futuro sea necesario hacer un sorting antes de mergear);
	format &var;	%*** Para que el orden en que se analizan las variables sea el orden en que aparecen en var=;
	set &data;		%*** Aca se ejecutan todas las opciones que vengan con &data;
	_boxcox_obs_ = _N_;	%*** Observation variable;
run;
%* De ahora en mas el dataset de trabajo es el dataset temporario _Boxcox_data_;
%let data = _Boxcox_data_;

%*** Eliminando posibles data options que hayan venido con los parametros &outLoglik y &outLambda;
%*** Todas las opciones que vengan con ellos se ignoran;
%if %quote(&outLambda) ~= %then
	%let outLambda = %scan(&outLambda , 1 , '(');
%if %quote(&outLoglik) ~= %then
	%let outLoglik = %scan(&outLoglik , 1 , '(');

%*** Parameter exclude=. Checking if only one value is passed and if this value is numeric.
%*** Otherwise there will be an error when trying to exclude the value(s) given in &exclude
%*** in the PROC IML below, from matrix X with the data;
%if %quote(&exclude) ~= %then %do;
	%let nro_exclude = %GetNroElements(&exclude);
	%* Eliminating the notes from the log because if &exclude is not a number, there
	%* will be a note in the log stating that a mathematical operation could not be
	%* performed, when the INPUT function is invoked;
	%* NOTE that notes_option is a LOCAL variable, not to be confused with the global
	%* macro variable _notes_option_;
	%let notes_option = %sysfunc(getoption(notes));	
	option nonotes;
	data _NULL_;
		%do i = 1 %to &nro_exclude;
			%let _exclude_ = %scan(&exclude , &i , ' ');
			exclude = input("&_exclude_" , 32.);
				%** 32 is the maximum number of digits in &exclude that is allowed (and it
				%** is the maximum number allowed for the second parameter of the INPUT
				%** function. Any character beyond the 32nd digit is ignored by INPUT
				%** and will be kept in &exclude, probably producing an error later on
				%** in PROC IML when trying to eliminate the rows whose values are not
				%** equal to &exclude. But there does not seem to be a solution for this;
			if exclude = . then do;
				%** A comparison with missing value (.) allows to detect a non-numeric
				%** value in &exclude. In fact when &exclude has a non-numeric value
				%** the output of the INPUT function above yields missing. Apparently,
				%** there is no other way to do this, because if I do not use the function
				%** INPUT and assign the current value in the list directly to variable
				%** exclude, if this value is not a number, there will be a note stating
				%** that the variable whose name is the value taken from the list in &exclude
				%** is uninitialized, and no further processing of the data step is performed.
				%** For example, if &exclude = pepe, executing exclude = &exclude will produce
				%** the note: Variable PEPE is uninitialized, and the data step will stop;
				put "BOXCOX: ERROR - At least one value passed in EXCLUDE= is not numeric.";
				put "BOXCOX: The parameter will be ignored.";
				put "value=&exclude";
				call symput ('exclude', '');	%* Sets the value of &exclude to empty;
			end;
		%end;
	run;
	%* Resetting NOTES option;
	option &notes_option;
%end;
/* END Parsing input parameters */

%* Some notes to the log;
%if &log %then %do;
	%put BOXCOX: Search space for the optimum lambda: &lambda;
	%if %quote(&exclude) ~= %then %do;
		%if &nro_exclude > 1 %then
			%put BOXCOX: Observations whose value is either &exclude are excluded.;
		%else
			%put BOXCOX: Observations with value = &exclude are excluded.;
	%end;
%end;

%* Busqueda del lambda optimo para cada variable;
proc iml;
	file log;
	use _Boxcox_data_(keep=&var _boxcox_obs_);
		read all into X[colname=namesX];
	close _Boxcox_data_;
	%* Elimino el numero de observacion de la matriz X y creo el vector obs con los numeros
	%* de observacion;
	obs = X[,loc(namesX='_boxcox_obs_')];
	X = X[,loc(namesX^='_boxcox_obs_')];

	%*** Initial settings;
	%* Number of total observations in X;
	nobs = nrow(X);
	call symput('nobs' , char(nobs));
	%* Number of variables in X;
	nvar = ncol(X);
	call symput('nvar' , char(nvar));
	%* Creating macro variable with list of variables to transform;
	%do j = 1 %to &nvar;
		%local var&j;
		%* This is done in case parameter var= is _numeric_ or of the type x1-xN;
		call symput("var&j" , namesX[&j]);
	%end;
	%let var = ;
	%do j = 1 %to &nvar;
		%let var = &var &&var&j;
	%end;

	%*** Variables that are used when the values of x are shifted so that they are all positive;
	pcnt = 0.01;		%* Fraction of minimum value of x that defines the shift in case not all
						%* values are positive;
	shift = J(nvar,1,0);

	%*** Search space for lambda;
	%let lambda = %upcase(&lambda);
	lambda_min = %sysfunc(compbl(%scan(&lambda , 1 , 'TO')));
	lambda_max = %sysfunc(compbl(%scan(%scan(&lambda , 1 , 'BY'),2,'TO')));
	lambda_step = %sysfunc(compbl(%scan(&lambda , 2 , 'BY')));
	npoints = floor( (lambda_max - lambda_min) / lambda_step + 1 );
%*	npoints = %scan(&lambda , 3 , ' ');
%*	if npoints > 1 then
%*		lambda_step = (lambda_max - lambda_min) / (npoints - 1);
%*	else
%*		lambda_step = 0;

	%* Initializations of matrices used in the search for the maximum;
	lambda = J(npoints , 1 , 0);
	L = J(npoints,nvar,0);			%*** Matriz con log-likelihood para cada variable;
	Xt = X;							%*** Matriz con las variables transformadas (esto es necesario
									%*** porque mas adelante referencio solo algunas filas de Xt,
									%*** para almacenar su valor (ver final del loop do j = 1 to nvar);
	ind_max = J(1,nvar);			%*** Inicializo en 1 los indices donde ocurre el maximo de log-likelihood;
									%*** Esto corresponde a decir que el maximo inicialmente esta en el
									%*** extremo izquierdo del espacio de busqueda;
	L_max = J(1,nvar)*0;			%*** Inicializo en 0 el valor maximo de la log-likelihood para cada variable;

	lambda_opt = J(nvar,1,0);		%* Vector con los valores de lambda a utilizar en la transformacion;
	lambda_real = lambda_opt;		%* Vector con los valores de lambda que maximizan la log-likelihood para cada variable;
	lambda_lower = J(nvar,1,0);		%* Vector con el lower bound para el intervalo de confianza de lambda;
	lambda_upper = J(nvar,1,0);		%* Vector con el upper bound para el intervalo de confianza de lambda;
	x0 = J(nvar,1);					%* Vector con los matched points (puntos de apareamiento), donde la transformacion es igual a la identidad;
									%* El default es igual 1;
	confidence = J(nvar,1,&confidence);	%*** Nivel de confianza para cada variable inicializado en el valor nominal pasado en la macro;
										%*** El nivel de confianza puede cambiar dependiendo del intervalo de busqueda del maximo de la log-likelihood;

	/*----- Searching lambda_real that maximizes the log-likelihood -----*/;
	do j = 1 to nvar;
		%if &log %then %do;
			put;
			put "BOXCOX: VARIABLE: " (upcase(namesX[j]));
			put "BOXCOX: Searching for lambda_opt that maximizes the log-likelihood...";
		%end;

		%* Values to exclude from the analysis;
		%if %quote(&exclude) ~= %then %do;
			%* Notes:
			%* - LOC returns a row vector
			%* - The %str function is used within the call to %any to mask the comma in X[,j];
			indExclude = loc(%any(%str(X[,j]), =, &exclude));
			indMissing = loc(X[,j]=.);
			indToExclude = loc(%any(%str(X[,j]), =, &exclude) | X[,j]=.);
				%** Note that the search is carried out again instead of simply
				%** putting the indices in indMissing after indExclude because if
				%** any of those is empty, there will be an error STUPID SAAAAASSSSSS!!*(#&$*(@;
				%** This also guarantees that indToExclude is reinitialized for each new variable,
				%** and that is empty if no indices are found;
			%if &log %then %do;
				put "BOXCOX: Observations with values to be excluded: " (trim(left(char(ncol(indExclude)))));
				if ncol(indMissing) > 0 then
					put "BOXCOX: Missing values: " (trim(left(char(ncol(indMissing)))));
			%end;
		%end;
		%else %do;
			indToExclude = loc(X[,j]=.);
			%if &log %then %do;
				if ncol(indToExclude) > 0 then
					put "BOXCOX: Missing values: " (trim(left(char(ncol(indToExclude)))));
			%end;
		%end;
		%* Exclude the indices in indToExclude from the analysis. Note that the length
		%* of indToExclude is first checked for > 0 because otherwise SAS gives the
		%* error that the matrix has not been set to a value when trying to use it;
		if ncol(indToExclude) > 0 then
			ind = remove(1:nobs, indToExclude);		%* nobs is created above, in initial settings;
		else
			ind = 1:nobs;		%* Setting ind to the value used when no observations are excluded;
		%if &log %then %do;
			put "BOXCOX: Observations used: " (trim(left(char(ncol(ind)))));
		%end;

		if ncol(ind) = 0 then
			put "BOXCOX: No observations left for analysis. VARIABLE SKIPPED.";
		else do;
			%* Vector with observations to use of variable j;
			XX = X[ind, j];
			%* Number of observations used;
			n = nrow(XX);

			%*** Shifting the values of x so that they are all positive;
			xmin = min(XX);
			if xmin <= 0 then do;
				if xmin < 0 then
					shift[j] = -(1 + pcnt)*xmin;
				else
					shift[j] = pcnt*min(XX[loc(XX>0)]);
				XX = XX + shift[j];
			end;

			%** Initialization;	
			logXX_sum = log(XX)[+];			%*** Sum of log(x);
			XXt = XX;						%*** Vector of transformed values;
			%** Loop that searches for the lambda that maximizes the log-likelihood;
			do i = 1 to npoints;
				lambda[i] = lambda_min + (i-1)*lambda_step;
				%*** Transformation of the variable;
				if lambda[i] = 0 then
					XXt = log(XX);			%*** Natural log;
				else
					XXt = ( XX##lambda[i] - 1 ) / lambda[i];		%*** ##: Elementwise exponentiation;
				%*** Media y varianza del vector transformado;
				mu = XXt[+] / n;
				sigma2 = ( (XXt - J(n,1)*mu)##2 )[+] / n;		%*** MLE of variance;

				%*** Log-likelihood a menos de una constante (la constante se pone abajo);
				L[i,j] = -0.5*n*log(sigma2) + (lambda[i] - 1)*logXX_sum;
				if L[i,j] > L[ind_max[j],j] then
					ind_max[j] = i;
			end;

			%* Adding the constant that gives the value of the log-likelihood;
			L[,j] = L[,j] - 1.418938533*n;		%*** The coeefficient of n is equal to -0.5*(log(2pi)+1);
			%* Max of log-likelihood for variable j;
			L_max[j] = L[ind_max[j], j];
			%* Lambda where max L occurs;
			lambda_opt[j] = lambda[ind_max[j]];		%* Lambda to use in the Box-Cox transformation;
			lambda_real[j] = lambda_opt[j];			%* Real value of lambda where the maximum occurs;

			/*----- Confidence interval for lambda -----*/
			%if &log %then %do;
				put "BOXCOX: lambda_opt = " (trim(left(char(round(lambda_opt[j],&roundoff)))));
			%end;
			%if %sysfunc(indexw(&validMatchingPoints , %sysfunc( lowcase(%quote(&matchingPoint)) ))) %then %do;
				%if %sysfunc(lowcase(%quote(&matchingPoint))) = mean %then %do;
					x0[j] = sum(XX) / n;
				%end;
				%else %do;
					x0[j] = &matchingPoint(XX);		%* e.g.: if &matchingPoint = median, this results in mean(XX);
				%end;
			%end;
			%else %do;
				x0[j] = &matchingPoint;		%*** At this point, &matchingPoint ust be a number;
			%end;
			if ind_max[j] = 1 | ind_max[j] = npoints then do;
				confidence[j] = .;		%*** Setting the confidence level to missing, because no CI is reported;
				lambda_lower[j] = .;	%*** Setting the confidence interval;
				lambda_upper[j] = .;	%*** Setting the confidence interval;
				put "BOXCOX: WARNING - The maximum of the log-likelihood for variable " (upcase(namesX[j]));
				put "BOXCOX: is reached at the edge of the search space for lambda";
				put "BOXCOX: This may not be the maximum for that variable.";
				put "BOXCOX: You should change the search space for lambda.";
				put "BOXCOX: No confidence interval for lambda will be reported.";
				put;
			end;

			else do;
				%*** Intervalo de Confianza para lambda_opt de nivel aprox. igual a &ci.
				%*** Esta basado en que -2(log-likelihood - max(log-likelihood)) ~ Chi^2 with 1 d.f.;
				%*** Para mas info ver "Profile-Likelihood-Based Confidence Intervals" en SAS Online manuals;
				L_lowerBound = L_max[j] - 0.5*cinv(&confidence , 1);
				%*** Busco los dos valores de lambda para los cuales L = L_lowerBound.
				%*** Estos valores pueden no existir si nivel de confianza pedido &ci es muy grande, porque
				%*** se iria fuera del rango lambda;
				i1 = ind_max[j] - 1;		%*** Indice que indica el lower bound del intervalo de confianza para lambda_opt;
				i2 = ind_max[j] + 1;		%*** Indice que indica el upper bound del intervalo de confianza para lambda_opt;
				found = 0; found1 = 0; found2 = 0;

				%if &log %then %do;
					put "BOXCOX: Finding the %sysfunc(round(%sysevalf(&confidence*100),0.1))% likelihood-based confidence interval for " (trim(left(upcase(namesX[j])))) ":";
					/*put "index_max = " (trim(left(char(ind_max[j])))) ", lambda_opt = " (lambda_opt[j]) ", L_max = " (L_max[j]) ", L_lowerBound = " L_lowerBound;*/
				%end;
				do while (^found & i1 >= 1 & i2 <= npoints);
					/*
					%if &log %then %do;
						put "index = " (trim(left(char(i1)))) ", " (lambda[i1]) ";   " (trim(left(char(i2)))) ", " (lambda[i2]) ";   L_left = " (L[i1,j]) ", L_right = " (L[i2,j]);
					%end;
					*/
					if L[i1,j] < L_lowerBound then do;
						lambda_lower[j] = lambda[i1];
						found1 = 1;
					end;
					if L[i2,j] < L_lowerBound then do;
						lambda_upper[j] = lambda[i2];
						found2 = 1;
					end;
					if found1 & found2 then
						found = 1;
					i1 = i1 - 1;
					i2 = i2 + 1;
				end;
				%*** En caso de que la busqueda del intervalo de confianza se haya salido
				%*** del search space, calculo el nivel del intervalo de confianza para
				%*** L = L_border;
				if ^found then do;
					if i1 = 1 then do;		%*** Si se topo con el borde a la izquierda del search space;
						%*** Pregunto si el valor de L en el extremo derecho es mayor que en el extremo izquierdo;
						%*** Elijo como L_border al valor mas alto;
						if L[npoints,j] > L[1,j] then
							L_border = L[npoints,j];
						else
							L_border = L[1,j];
					end;
					else do;				%*** Si se topo con el borde a la derecha del search space;
						%*** Pregunto si el valor de L en el extremo izquierdo es mayor que en el extremo derecho;
						%*** Elijo como L_border al valor mas alto;
						if L[1,j] > L[npoints,j] then
							L_border = L[1,j];
						else
							L_border = L[npoints,j];
					end;
					confidence[j] = probchi(2*(L_max[j] - L_border) , 1);	%*** Nuevo nivel de confianza para lambda;
					%*** Busco el intervalo de confianza para lambda con nivel de confianza = confidence[j];
					if L_border > L[1,j] then do;				%*** Busco L_border hacia la izquierda;
						lambda_upper[j] = lambda[npoints];		%*** lambda_upper esta en el borde derecho del search space;
						i1 = ind_max[j] - 1;
						found1 = 0;
						do while (^found1);		%*** No pregunto por i1 >= 1 por como elegi L_border arriba;
							if L[i1,j] < L_border then do;	%*** Pregunto por <= en lugar de < para contemplar el raro caso en que L[1,j] = L[npoints,j] y no me de error de indice;
								lambda_lower[j] = lambda[i1];
								found1 = 1;
							end;
							i1 = i1 - 1;
						end;
						side = "to the right";	%*** Sentido en el cual debe ensancharse el search space de lambda para que el intervalo de confianza caiga adentro del search space;
					end;
					else if L_border > L[npoints,j] then do;	%*** Busco L_border hacia la derecha;
						lambda_lower[j] = lambda[1];			%*** lambda_lower esta en el borde izquierdo del search space;
						i2 = ind_max[j] + 1;
						found2 = 0;
						do while (^found2);		%*** No pregunto por i2 <= npoints por como elegi L_border arriba;
							if L[i2,j] < L_border then do;
								lambda_upper[j] = lambda[i2];
								found2 = 1;
							end;
							i2 = i2 + 1;
						end;
						side = "to the left";	%*** Sentido en el cual debe ensancharse el search space de lambda para que el intervalo de confianza caiga adentro del search space;
					end;
					else do;	%*** L[1,j] = L[npoints,j];
						lambda_lower[j] = lambda[1];
						lambda_upper[j] = lambda[npoints];
						side = "in both sides";	%*** Sentidos en que debe ensancharse el search space de lambda para que el intervalo de confianza caiga adentro del search space;
					end;
				end;
				%if &log %then %do;
					put "BOXCOX: %sysfunc(round(%sysevalf(&confidence*100),0.1))% confidence interval for lambda: (" (trim(left(char(round(lambda_lower[j],&roundoff))))) " , " (trim(left(char(round(lambda_upper[j],&roundoff))))) ")";
				%end;
				if ^found then do;
					put "BOXCOX: WARNING - The level of the reported confidence interval for variable " (upcase(namesX[j]));
					put "BOXCOX: is smaller than %sysfunc(round(%sysevalf(&confidence*100),0.1))%, namely: " (trim(left(char(round(confidence[j]*100,0.1))))) "%.";
					put "BOXCOX: This is because the search space for lambda is too small.";
					put "BOXCOX: You should increase the search space " side ".";
				end;
			end;

			/*----- Transformation of variable -----*/
			%* Variable j is transformed using the Box-Cox transformation with lambda = lambda_opt,
			%* and the matching point x0 at x0[j];
			%* Note: When &real is FALSE, the following is done as far as the lambda used in the transformation:
			%* - If the confidence interval for lambda_opt includes 0, the natural log transformation is used.
			%* - if the confidence interval for lambda_opt includes 1, the variable is not transformed.;
			%* 
			%* Note that the message stating that the variable is transformed is used in each if-then-else
			%* entry just because I want to show what is the real lambda used in the transformation when
			%* one of the above cases occurs and &real is FALSE; 
			%if ~&real %then %do;
				if lambda_lower[j] < 0 & lambda_upper[j] > 0 then do;
					lambda_opt[j] = 0;
					%* Logarithm transformation matched at x0[j];
					XXt = x0[j] * ( 1 + log(XX / x0[j]) );
					%if &log %then %do;
						put "BOXCOX: Transforming variable " (trim(left((upcase(namesX[j]))))) "... (lambda = " (trim(left(char(round(lambda_opt[j],&roundoff))))) ")";
						put "BOXCOX: NOTE - The Box-Cox transformation for variable " (trim(left(upcase(namesX[j])))) " was set to log(),";
						put "BOXCOX: because the " (trim(left(char(round(confidence[j]*100,0.1))))) "% confidence interval for lambda includes 0.";
					%end;
				end;
				else if lambda_lower[j] < 1 & lambda_upper[j] > 1 then do;
					%* The variable is not tansformed (note that a shift possibly introduced above is removed,
					%* so that the transformed variable and the original variable are the same;
					XXt = XX - shift[j];
					%if &log %then %do;
						put "BOXCOX: NOTE - Variable " (trim(left(upcase(namesX[j])))) " was not transformed by Box-Cox,";
						put "BOXCOX: because the " (trim(left(char(round(confidence[j]*100,0.1))))) "% confidence interval for lambda includes 1.";
					%end;
				end;
				else do;
					%* Box-Cox transformation with the lambda_opt found;
					XXt = x0[j] * (1 + ( (XX / x0[j])##lambda_opt[j] - 1 ) / lambda_opt[j]);
					put "BOXCOX: Transforming variable " (trim(left((upcase(namesX[j]))))) "... (lambda = " (trim(left(char(round(lambda_opt[j],&roundoff))))) ")";
				end;
			%end;
			%else %do;
				%if &log %then %do;
					put "BOXCOX: Transforming variable " (trim(left((upcase(namesX[j]))))) "... (lambda = " (trim(left(char(round(lambda_opt[j],&roundoff))))) ")";
				%end;
			%end;

			%if &log %then %do;
				put;
			%end;

			%*** Updating the j-th column of matrix with transformed variables (Xt), with transformed
			%*** values stored in vector XXt;
			%* Checking if there were observations excluded from the analysis;
			if ncol(indToExclude) = 0 then
				Xt[,j] = XXt;
			else do;
				%* Transformation of observations included in the analysis;
				Xt[ind, j] = XXt;
				%* Observations not included in the analysis are left unchanged;
				Xt[indToExclude, j] = X[indToExclude, j];
			end;
		end;
	end;

	%*** Grabando la log-likelihood para cada variable;
	%if %quote(&outLoglik) = %then %do;
		%let outLoglik = _Boxcox_loglik_;
	%end;
	%let L_cols = %MakeList(&var , prefix=L_ , sep=%quote( ));
	lambda_L = J(npoints , nvar+1 , 0);
	lambda_L[,1] = lambda;
	lambda_L[,2:ncol(lambda_L)] = L;
	create &outLoglik from lambda_L[colname={lambda &L_cols}];
		append from lambda_L;
	close &outLoglik;

	%*** Grabando los datos originales y transformados;
	%*** Notar que necesito el dataset &out, ya sea que fue solicitado o no, porque luego realizo el test de
	%*** normalidad de Shapiro-Wilk basado en las variables transformadas;
	%let var_t = %MakeList(&var , suffix=&suffix , sep=%quote( ));
	%let out_param = &out;
		%* Para contemplar el caso en que el output dataset coincida con el input dataset,
		%* se graba el nombre original del output dataset en la variable &out_param, para que
		%* pueda ser usada mas adelante al mergear el output dataset temporario con el input
		%* dataset y asi armar el output dataset completo;
	%if %quote(&out_param) = or %upcase(%GetDataName(&out_param)) = %upcase(%GetDataName(&data_name)) %then %do;
			%* Notar que &data_name tiene el nombre del dataset originalmente pasado en el parametro &data,
			%* no tiene el nombre del dataset temporario creado al principio (_Boxcox_data_);
			%* Creo un dataset auxiliar tanto si el parametro out= es vacio como si es igual al input
			%* dataset, porque si es igual al input dataset, se perderian las demas variables del input
			%* dataset, ya que el output dataset inicialmente es creado solamente con las variables
			%* transformadas. Mas adelante (fuera del PROC IML), estas variables transformadas son
			%* mergeadas con todas las demas variables que venian en el input dataset;
			%* El uso de la macro %GetDataName para comparar los nombres, se debe a que se elimina
			%* cualquier referencia a una libreria en dichos nombres (del tipo WORK.OUT, etc.).
			%* Observar que no me preocupo por verificar si las librerias son distintas, con lo
			%* cual los nombres estarian referenciando a distintos datasets, pero esto no molesta.
			%* En todo caso hace algo que no haria falta hacer (crear el dataset temporario _Boxcox_out_)
			%* cuando los nombres son iguales pero las librerias distintas, pero no es algo que haga danho;
		%let out = _Boxcox_out_;
	%end;
	%let out_name = %scan(&out , 1 , '(');
	%let out_options = %GetDataOptions(&out);
	Xt = Xt || obs;		%*** Agregando el numero de observacion auxiliar, generado para mergear luego con el input dataset;
	create &out_name from Xt[colname={&var_t _boxcox_obs_}];
		append from Xt;
	close &out_name;

	%*** Grabando los valores de lambda utilizados en la transformacion de Box-Cox, y sus intervalos de confianza;
	%* Nombre de las variables analizadas (notar que se elimina _boxcox_obs_ que fue agregada
	%* al principio para tener el numero de observacion);
	var = namesX[loc(namesX^='_boxcox_obs_')]`;
	%*** El dataset outlambda lo creo obligatoriamente porque necesito los valores de lambda_opt y L_max
	%*** para ubicar en el grafico de la log-likelihood. Ademas necesito los valores de lambda_opt y
	%*** lambda_real para que sean mostrados en los titulos de los graficos. Claramente solamente necesito
	%*** esto si plot=1, pero como el dataset &outLambda es chiquito lo creo de todas formas aunque el
	%*** usuario no requiera ningun grafico;
	%if %quote(&outLambda) = %then %do;
		%let outLambda = _Boxcox_outlambda_;
	%end;
	create &outLambda var {var lambda_opt lambda_real lambda_lower lambda_upper confidence x0 shift L_max};
		append;
	close &outLambda;

	%*** Extremos de lambda para los graficos de la log-likelihood;
	call symput("lambda_min" , char(lambda_min));
	call symput("lambda_max" , char(lambda_max));
quit;

%*** Reordeno las variables transformadas de manera que aparezcan en el mismo orden
%*** en que aparecen las variables sin transformar;
data &out_name;
	format &varOrder_t;
	set &out_name;
run;

%*** Test de Shapiro-Wilk de normalidad de los datos transformados;
%let pvalues = %MakeList(&var_t , prefix=pvalue_ , sep=%quote( ));
%let out2000 = &out_name;
	%** Nombre del dataset con a lo sumo 2000 observaciones para poder hacer el test de
	%** Shapiro-Wilk;
	%** Asigno un valor a out2000 a pesar de que lo asigno mas abajo, porque la asignacion
	%** de abajo ocurre dentro del %if y no siempre se verifica la condicion del %if
	%** (&nobs > 2000);
%if &nobs > 2000 %then %do;		%*** Tomo una muestra si hay mas de 2000 observaciones;
	%if &log %then %do;
		%put BOXCOX: NOTE - Because the dataset has more than 2000 observations, a random sample of;
		%put BOXCOX: 2000 observations is taken in order to perform the Shapiro-Wilk tests of normality;
		%put BOXCOX: for all the variables.;
		%put;
	%end;
	proc surveyselect data=&out_name sampsize=2000 out=_Boxcox_out_sample_ noprint;
	run;
	%let out2000 = _Boxcox_out_sample_;
%end;
proc univariate data=&out2000 normal noprint;
	var &var_t;
	output out=_Boxcox_sw_ probn=&pvalues;
run;
data _NULL_;
	set _Boxcox_sw_;
	array pvalues{*} &pvalues;
	array vars{*} &var_t;
	do j = 1 to &nvar;
		_name_ = upcase(vname(vars(j)));
		%* NOTE: At one point I used the following statement to read the variable name
		%* _var_ = upcase(scan("&var_t", j , ' ')).
		%* However this gave an error when the number of variables in &var_t was too
		%* large (the error was just shown in the log, but still everything worked correctly);
		if &log then do;
			put "BOXCOX: Shapiro-Wilk test of normality for transformed variable " _name_ ":";
			put "BOXCOX: p-value = " pvalues(j);
		end;
		if pvalues(j) < &alpha_sw then do;
			put "BOXCOX: WARNING - The p-value for the test of normality for transformed variable " _name_;
			put "BOXCOX: is " pvalues(j) ", less than &alpha_sw..";
			put "BOXCOX: The distribution of the transformed variable may not be normal.";
		end;
		if &log then put;
	end;
run;

%if %quote(&outLambda) ~= %then %do;
	data &outLambda;
		%* El orden en que aparecen las variables en el dataset es:
		%* var lambda_opt lambda_real lambda_lower lambda_upper confidence matchingValue shift matchingPoint;
		set &outLambda(rename=(x0=matchingValue L_max=loglik));
		retain matchingPoint "&matchingPoint";
		%* El rename es para que los nombres queden en minusculas y no en mayusculas como vienen del IML;
		rename 	var				= var
				lambda_opt		= lambda_opt
				lambda_real 	= lambda_real
				lambda_lower 	= lambda_lower
				lambda_upper 	= lambda_upper
				confidence		= confidence
				shift			= shift;
		label 	var				= "Variable transformed"
				lambda_opt		= "Value of lambda used in the Box-Cox transformation"
				lambda_real 	= "Value of lambda that maximizes the log-likelihood"
				lambda_lower 	= "Lower bound of the %sysfunc(round(%sysevalf(&confidence*100),0.1))% confidence interval for lambda"
				lambda_upper 	= "Upper bound of the %sysfunc(round(%sysevalf(&confidence*100),0.1))% confidence interval for lambda"
				confidence		= "Level of the confidence interval for lambda"
				matchingValue	= "Matching value for the Box-Cox transformation"
				matchingPoint	= "Matching point for the Box-Cox transformation"
				shift			= "Shift performed on the variable prior to transformation"
				loglik			= "Maximum value of the log-likelihood, attained at lambda_opt";
	run;
	quit;
%end;

%*** Grafico;
%if &plot %then %do;
	%do i = 1 %to &nvar;
		%*** Lectura de los valores de lambda_opt y lambda_real para mostrar en los gráficos;
		%let y = %scan(&var , &i , ' ');
		data _NULL_;
			set &outLambda(where=(var="&y") keep=var lambda_opt lambda_real);
			if _N_ = 1;			%* Me quedo solo con la primera observacion del subset dado por el where=;
			call symput ('lambda_opt' , lambda_opt);	%* Grabo el valor de lambda_opt para indicarlo en el grafico de la log-likelihood;
			call symput ('lambda_real' , lambda_real);	%* Grabo el valor de lambda_real para indicarlo en el Q-Q plot de la variable transformada;
		run;

		%*** Log-likelihood function;
		%if &loglik %then %do;
			%let y = %scan(&var , &i , ' ');
			%* Annotate dataset para marcar el valor maximo de la log-likelihood;
			%* Ver archivo annotate.sas para ver como se define y se usa el annotate dataset;
			data _Boxcox_annotate_(keep=x y function xsys ysys text color line angle position size);
				set &outLambda;
				length function $8 text $100;
				where var = "&y";
				retain size 2;
					%*** Lineas verticales indicando lambda = 0 y lambda = 1 como referencia;
					%* En x = 0;
					x = 0; y = 0; xsys = "2"; ysys = "1"; function = "move"; output;
					x = 0; y = 100; xsys = "2"; ysys = "1"; function = "draw"; color = "black"; line = 1; size = 1; output;
					%* En x = 1;
					x = 1; y = 0; xsys = "2"; ysys = "1"; function = "move"; output;
					x = 1; y = 100; xsys = "2"; ysys = "1"; function = "draw"; color = "black"; line = 1; size = 1; output;
					%*** Puntos y linea vertical roja que pasa por lambda_real;
					x = lambda_real; y = 0; xsys = "2"; ysys = "1"; function = "move"; output;
					x = lambda_real; y = 0; xsys = "2"; ysys = "1"; function = "symbol"; text = "star"; color = "red"; size = 2; output;
					x = lambda_real; y = loglik; xsys = "2"; ysys = "2"; function = "draw"; color = "red"; size = 1; output;
					x = lambda_real; y = loglik; function = "symbol"; text = "star"; color = "red"; size = 2; output;
					x = lambda_real; y = 100; xsys = "2"; ysys = "1"; function = "draw"; color = "red"; size = 1; output;
					%*** Comentario indicando la posicion del lambda estimado;
					x = lambda_real; y = 5; xsys = "2"; ysys = "1"; function = "label"; 
						text = "Estimated lambda";
						position = "+"; color = "black"; size = 1; output;
					%*** Lineas verticales rojas punteadas para el intervalo de confianza,
					%*** siempre que ese intervalo se haya informado;
					if confidence ~= . then do; 
						%* Lower value;
						x = lambda_lower; y = 0; xsys = "2"; ysys = "1"; function = "move"; output;
						x = lambda_lower; y = 100; xsys = "2"; ysys = "1"; function = "draw"; color = "red"; line = 2; size = 1; output;
						%* Upper value;
						x = lambda_upper; y = 0; xsys = "2"; ysys = "1"; function = "move"; output;
						x = lambda_upper; y = 100; xsys = "2"; ysys = "1"; function = "draw"; color = "red"; line = 2; size = 1; output;
						%*** Comentario indicando que lo de arriba es el intervalo de confianza;
						x = lambda_real; y = 50; xsys = "2"; ysys = "1"; function = "label"; 
							text = trim(left(round(confidence*100,0.1))) || "%";
							position = "+"; angle = 0; color = "black"; size = 1; output;
						x = lambda_real; y = 45; xsys = "2"; ysys = "1"; function = "label"; 
							text = "Confidence Interval"; position = "+"; angle = 0; color = "black"; size = 1; output;
						x = lambda_real; y = 40; xsys = "2"; ysys = "1"; function = "label"; 
							text = "for lambda"; position = "+"; angle = 0; color = "black"; size = 1; output;
						%* Comentario indicando que el intervalo mostrado no entra en el grafico, en caso de que
						%* sea asi si el intervalo de busqueda de lambda es muy chico;
						if confidence < &confidence then do;
							x = 50; y = 98; xsys = "5"; ysys = "5"; function = "label"; 
								text = "WARNING: The level of the reported confidence interval is smaller than the %sysfunc(round(%sysevalf(&confidence*100),0.1))% nominal value";
								position = "+"; color = "black"; size = 1; output;
						end;
					end;
					else do;
						x = 50; y = 98; xsys = "5"; ysys = "5"; function = "label"; 
							text = "WARNING: The maximum of the log-likelihood is reached at the edge of the search space for lambda";
							position = "+"; color = "black"; size = 1; output;
					end;
			run;
			title "Log-likelihood (%upcase(&data_name))" justify=center "%sysfunc(upcase(&y)) (Optimum Lambda = %sysfunc(trim(%sysfunc(left(&lambda_real)))))";
			proc gplot data=&outLoglik annotate=_Boxcox_annotate_;
				symbol1 color=blue interpol=join value=none;
				axis1 order=(&lambda_min to &lambda_max by 0.1);
				axis2 label=("L(lambda)");
				plot L_&y*lambda=1 / haxis=axis1 vaxis=axis2 grid;
			run;
			quit;
			symbol1;		%*** restore previous definition;
			title;
		%end;

		%*** Q-Q plots;
		%if &qqplot %then %do;
			%*** Q-Q plot of original variable;
			%let y = %scan(&var , &i , ' ');
			symbol1 color=black interpol=none value=dot;
			title "Normal Q-Q plot for original variable (%upcase(&data_name))" justify=center "%sysfunc(upcase(&y))";
			%qqplot(_Boxcox_data_ , var=&y , mu=&mu , sigma=&sigma);
			symbol1;		%*** restore previous definition;

			%*** Q-Q plot of transformed variable;
			%let y = %scan(&var_t , &i , ' ');
			symbol1 color=black interpol=none value=dot;
			title "Normal Q-Q plot for transformed variable (%upcase(&data_name))" justify=center "%sysfunc(upcase(&y)) (Lambda used = %sysfunc(trim(%sysfunc(left(&lambda_opt)))))";
			%qqplot(&out_name , var=&y , mu=&mu , sigma=&sigma);
				%** Notar que uso el dataset &out_name y no _Boxcox_data_, porque el nombre de las variables
				%** transformadas y originales puede ser el mismo, y la unica diferencia para identificarlas
				%** seria en que dataset se encuentran almacenadas;
			symbol1;		%*** restore previous definition;
			title;
		%end;
		%if &histogram %then %do;
			%*** Histogram of original variable;
			%let y = %scan(&var , &i , ' ');
			title "Histogram of original variable (%upcase(&data_name))" justify=center "%sysfunc(upcase(&y))";
			proc univariate data=_Boxcox_data_ noprint;
				histogram &y / cbarline=blue grid;
			run;

			%*** Histogram of transformed variable;
			%let y = %scan(&var_t , &i , ' ');
			title "Histogram of transformed variable (%upcase(&data_name))" justify=center "%sysfunc(upcase(&y)) (Lambda used = %sysfunc(trim(%sysfunc(left(&lambda_opt)))))";
			proc univariate data=&out_name noprint;
				histogram &y / normal(mu=est sigma=est noprint color=red) cbarline=blue grid;
			run;
				%** Notar que uso el dataset &out_name y no _Boxcox_data_, porque el nombre de las variables
				%** transformadas y originales puede ser el mismo, y la unica diferencia para identificarlas
				%** seria en que dataset se encuentran almacenadas;
		%end;
	%end;
%end;

%*** Creo el output dataset;
%*** NOTA IMPORTANTE: El output dataset debe ser creado al final de todo (es decir, despues de hacer los
%*** graficos por ejemplo), para contemplar el caso en que el output dataset coincide con el input dataset,
%*** y el nombre de las variables originales y transformadas coinciden.
%*** Si este fuera el caso y el output dataset se creara antes de hacer los graficos, no podrian hacerse
%*** los graficos con las variables antes y despues de la transformacion, porque dichas variables
%*** coincidirian ya al ser sus nombres los mismos, y al ser el output dataset igual al input dataset,
%*** las variables originales ya habrian sido sobre escritas;
%if %quote(&out) ~= _Boxcox_out_ or %upcase(%GetDataName(&out_param)) = %upcase(%GetDataName(&data_name)) %then %do;
		%** Notar que &out_param es el parametro out= pasado originalmente al llamar a la macro,
		%** sin sufrir ninguna modificacion;
		%** Asimismo &data_name tiene el nombre del dataset pasado originalmente en el parametro data,
		%** no tiene el valor del dataset temporario _Boxcox_data_;
	%*** Se genera el dataset de salida, a partir del dataset de entrada al que se le agregan
	%*** las variables transformadas, manteniendo el orden en que estaban las variables en el
	%*** dataset de entrada;
	%* NOTA: En el merge que sigue, no hace falta previamente ordenar por _obs_ porque ya estan ordenados
	%* por _obs_ (en ningun momento en el codigo se cambio dicho orden. Si bien esto sea cierto, por las
	%* dudas hago un merge by _obs_ y no por SAS observation number para evitar problemas, en caso de que en
	%* el futuro el codigo cambie y los datasets ya no esten ordenados por _obs_. Tampoco hago un sort de
	%* los datasets aqui, porque seria una perdida de tiempo tener que ordenarlos (pues ya estan ordenados,
	%* pero SAS no se da cuenta de ello y los ordenaria de nuevo);
	data &out_param;	%*** Aqui se ejecutan todas las opciones que hayan venido con el parametro out=;
		format &order;	%*** &order contiene las variables en el orden en que aparecen en el input dataset &data;
		merge _Boxcox_data_ &out_name;
			%** Notar lo siguiente: 
			%** Primero se pone _Boxcox_data_ y luego &out_name en el merge statement.
			%** Esto es para que tengan preferencia las variables de &out_name (por eso esta puesto en el
			%** segundo lugar). El objetivo es que si las variables transformadas ya existen en _Boxcox_data_,
			%** que tenga preferencia las creadas ahora en &out_name, ya que si el usuario pidio grabar
			%** las variables transformadas en variables ya existentes es porque queria sobreescribir las
			%** que estan en _Boxcox_data_;
		by _boxcox_obs_;
		%*** Para poner el nombre de las variables transformadas en minusculas (si no, del IML vienen en mayusculas);
		%do i = 1 %to &nvar;
			%let _var_ = %scan(&var_t , &i , ' ');
			rename &_var_ = &_var_;
		%end;
		drop _boxcox_obs_;			%* Elimino la variable auxiliar con el numero de observacion;
	run;
	%if &log %then %do;
		%put;
		%put BOXCOX: Output dataset %upcase(%scan(&out_param , 1 , '(')) created.;
		%put BOXCOX: Transformed variables;
		%put BOXCOX: (%MakeList(%upcase(&var_t) , sep=%quote( , )));
		%put BOXCOX: have been output to %upcase(%scan(&out_param , 1 , '(')).;
		%put;
	%end;
%end;

%*** If requested, create global macro variable with list of transformed variable names;
%if %quote(&macrovar) ~= %then %do;
	%global &macrovar;
	%let &macrovar = &var_t;
	%if &log %then %do;
		%put;
		%put BOXCOX: Global macro variable %upcase(&macrovar) with list of transformed variables, created.;
	%end;
%end;

%*** Borrando datasets temporarios;
%* Asumo que no existe ningun dataset con estos nombres creado por el usuario (porque los nombres tienen underscores);
proc datasets nolist;
	delete  _Boxcox_annotate_
			_Boxcox_data_
			_Boxcox_loglik_
			_Boxcox_out_
			_Boxcox_outlambda_
			_Boxcox_out_sample_
			_Boxcox_pc_
			_Boxcox_sw_;
quit;
%if &log %then %do;
	%put;
	%put BOXCOX: Macro ends;
	%put;
%end;

%ResetSASOptions;
%end;	%* if ~%CheckInputParameters;
%MEND Boxcox;

