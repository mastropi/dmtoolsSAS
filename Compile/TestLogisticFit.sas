/* MACRO %TestLogisticFit
Version: 	1.07
Author: 	Daniel Mastropietro
Created: 	28-May-03
Modified: 	15-Feb-2016 (previous: 16-Nov-2015)
SAS:		v9.3

DESCRIPTION:
Analiza el ajuste de un modelo de regresión logística a partir de gráficos
que involucran las probabilidades predichas por el modelo y un conjunto de
variables regresoras analizadas.

En lo que sigue se indica con logit a la función:
			logit(p) = log(p/(1-p)),
donde log es el logaritmo natural.

Los gráficos que la macro efectúa son:
1.- Logit de las probabilidades vs. distintos valores de una dada variable
regresora categorizada. En este gráfico se incluyen:
- Logit de la probabilidad predicha por el modelo para cada grupo de la
variable regresora categorizada. Se calcula como el logit del promedio
de las probabilidades predichas dentro de cada grupo.
- Logit de la probabilidad observada para cada grupo de la variable
regresora categorizada. Se calcula como el logit de la proporción de
observaciones, dentro de cada grupo, en que la variable respuesta es igual
al evento cuya probabilidad es modelada por la regresión.
Además, puede pedirse que se muestren barras de error entorno de estas dos
cantidades, con la idea de estudiar más en detalle la variabilidad de las
probabilidades predichas dentro de cada grupo de la variable regresora,
y de ver gráficamente el error asociado a la probabilidad observada.
El ancho de las barras mide la magnitud de:
- el desvío estándar de las probabilidades predichas para las distintas
observaciones dentro de cada grupo.
- el error estándar de la probabilidad observada.

2.- Un gráfico de residuos estandarizados vs. cada variable regresora
categorizada. Los residuos estandarizados se calculan como la diferencia entre
la probabilidad observada y la probabilidad predicha para cada grupo de
la variable regresora categorizada y se estandariza por su desvío estándar.

3.- Un Normal Q-Q plot de los residuos estandarizados, donde su distribución
se compara con la normal estándar.

4.- Si es solicitado, un histograma con la distribución de los residuos
estandarizados.

USAGE:
%TestLogisticFit(
	data ,			*** Input dataset
	target= ,		*** Variable respuesta
	var= , 			*** Lista con las variables regresoras (puede incluir la variable respuesta)
	out= ,			*** Raiz del nombre de los output datasets conteniendo lo que se grafica
	outCat=	,		*** Output dataset con las variables regresoras categorizadas
	pred=p ,		*** Variable que contiene las probabilidades predichas
	event=1 ,		*** Evento modelado por la regresion logistica
	groups=10 ,		*** Número de grupos en los que efectuar la categorización
	percentiles= , 	*** Percentiles para la categorizacion
	res=res ,		*** Nombre a usar para la variable con el residuo estandarizado
	suffixRes=0 ,	*** Agregar la variable regresora como sufijo para la variable 'res'?
	plot=0,			*** Mostrar gráficos?
	histogram=0 ,	*** Hacer el histograma de los residuos?
	qqplot=1 ,		*** Hacer el normal Q-Q plot de los residuos?
	refline=3.3,	*** Valor de la línea de referencia en el gráfico de los residuos
	pointlabels=0,	*** Mostrar point labels?
	bars=0 ,		*** Mostrar barras de error en los gráficos de probabilidades?
	barwidth=1,		*** Multiplicador para las barras de error
	plotWhat=logit,	*** Graficar el logit(p) ó p en los gráficos del ajuste?
	axisX= ,		*** Axis statement a usar en el eje de las X en los gráficos
	axisLogit= ,	*** Axis statement a usar en el eje del logit en los gráficos
	axisPred= ,		*** Axis statement a usar en el eje de las probabilidades en los gráficos
	axisRes= ,		*** Axis statement a usar en el eje de los residuos en los gráficos
	log=1);			*** Mostrar mensajes en el log?

REQUIRED PARAMETERS:
- data:			Input dataset. Se supone que es un dataset generado por el output
				statement del PROC LOGISTIC.
				Puede recibir cualquier opción adicional como en cualquier opción
				data= de SAS.
				
- var:			Lista de variables, donde la primera es la variable respuesta del
				modelo de regresion a analizar y las demas son las variables regresoras
				respecto a las cuales se desea analizar el ajuste. Notar que no pueden
				incluirse interacciones entre variables.
				Las variables no tienen por qué haber sido incluidas en la regresión,
				por lo que esta macro puede usarse para analizar si es necesario incluir
				nuevas variables en la regresión.
				Ej: y x1 x2.

OPTIONAL PARAMETERS:
- target:		Variable respuesta dicotómica.
				Si el parámetro es vacío, la variable respuesta es tomada del primer elemento
				de la lista especificada en VAR.

- out:			Raiz a usar para los output datasets que contienen lo que se grafica.
				Se genera un output dataset por cada variable regresora que aparece en
				la lista de 'var'.
				Los nombres de las columnas de cada uno de estos datasets son:
				- <variable regresora considerada>: sus valores estan categorizados.

				- <variable respuesta>_Mean: promedio de la variable respuesta en cada
				grupo de la variable regresora.
				- <variable respuesta>_Std: Error estándar de <variable respuesta>_Mean.
				- <variable respuesta>_Lower: valor inferior del intervalo de ancho
				'barwidth'*<variable respuesta>_Std.
				- <variable respuesta>_Upper: valor superior del intervalo de ancho
				'barwidth'*<variable respuesta>_Std.

				- <variable con probabilidad predicha>_Mean: promedio de las
				probabilidades predichas dentro de cada grupo de la variable regresora.
				- <variable con probabilidad predicha>_Std: Desvío estándar de
				<variable respuesta>_Mean.
				- <variable con probabilidad predicha>_Lower: valor inferior del
				intervalo de ancho 'barwidth'*<variable con probabilidad predicha>_Std.
				- <variable con probabilidad predicha>_Upper: valor superior del
				intervalo de ancho 'barwidth'*<variable con probabilidad predicha>_Std.

				- logit_<variable respuesta>: logit(segunda columna).
				- logit_<variable con probabilidad predicha>: logit(tercera columna).
				- _N_: numero de observaciones en cada grupo de la variable regresora.
				- <variable con residuo estandarizado> (default=res): residuo estandarizado,
				donde el residuo es la diferencia entre la segunda y la tercera columna.

- outCat:		Output dataset con las variables regresoras listadas en 'var' categorizadas
				según el proceso requerido para hacer el análisis del logistic fit.
				Todas las variables presentes en el input dataset 'dat' también están
				presentes en este dataset de salida.
				Los nombres de las variables categorizadas coinciden con los nombres
				de las variables regresoras listadas en 'var'.
				Puede pasarse cualquier opción adicional como en cualquier opción
				data= de SAS.

- pred:			Nombre de la variable en el input dataset que tiene las probabilidades
				predichas por el modelo.
				default: p

- event:		Evento de interés. Es el valor de la variable respuesta
				cuya probabilidad fue modelada por la regresion logistica.
				Puede ser cualquier valor numérico o alfanumérico.
				default: 1

- groups:		Número de grupos en los que se efectúa la categorización de las variables
				regresoras para hacer los gráficos de ajuste.
				Cada grupo se define a partir de percentiles equidistantes, tantos como
				grupos haya. Por ej., si groups=5 los percentiles usados para categorizar
				las variables son 20 40 60 80 100.
				default: 10, es decir se utilizan los percentiles 10 20 ... 100

- percentiles:	Valores de los percentiles utilizados para categorizar las variables
				regresoras.
				Tiene preferencia sobre el parámetro groups, en el sentido de que si
				los dos son pasados, se toma el valor de 'percentiles' y no de 'groups'.
				default: 10 20 30 40 50 60 70 80 90 100

- res:			Nombre a usar para la variable que contiene el residuo estandarizado
				calculado a partir de los gráficos de ajuste para cada variable regresora.
				default: res

- suffixRes:	Indica si se agrega el nombre de la variable regresora como sufijo al
				nombre de la variable con el residuo estandarizado ('res'), tras un
				'_'. Ej: si res=res, la variable regresora es x1 y suffixRes=1, el
				nombre de la variable con el residuo es res_x1. 
				Valores posibles: 0 => No. 1 => Si.
				default: 0

- plot:			Indica si se desea ver los gráficos generados por la macro.
				Éstos gráficos pueden incluir:
				- Gráfico del ajuste para cada variable regresora categorizada.
				Según el valor del parámetro 'plotWhat', en el eje vertical de estos
				gráficos se grafica algo distinto:
					- si plotWhat=LOGIT, se grafica el logit de la probabilidad predicha
					y de la probabilidad observada para cada grupo de cada variable
					regresora categorizada.
					- si plotWhat=P, PROB o PRED, se grafica directamente las 
					probabilidades predicha y observada.
				- El gráfico de residuos estandarizados vs. cada variable regresora
				categorizada.
				- Un histograma de los residuos estandarizados para cada variable
				regresora categorizada (ver parámetro 'histogram').
 				- Un Normal Q-Q plot de los residuos estandarizados para cada
				variable regresora categorizada (ver parámetro 'qqplot').
				Valores posibles: 0 => No, 1 => Sí.
				default: 1

- histogram:	Indica si se desea ver un histograma de los residuos estandarizados
				para cada variable regresora categorizada.
				Valores posibles: 0 => No, 1 => Sí.
				default: 0

- qqplot:		Indica si se desea ver el Normal Q-Q plot de los residuos
				estandarizados para cada variable regresora categorizada.
				Se compara la distribución de los residuos con la normal estándar.
				Valores posibles: 0 => No, 1 => Sí.
				default: 1

- refline:		Valor de la línea de referencia para el gráfico de los residuos.
				En el gráfico de los residuos vs. variable regresora se ubican dos líneas
				horizontales, una a la altura &RefLine y otra a -&RefLine.
				default: 3.3

- pointlabels:	Indica si se desea usar labels en los puntos mostrando el número de
				observaciones que caen en cada categoría de las variables regresoras
				categorizadas.
				Valores posibles: 0 => No, 1 => Sí.
				default: 0

- bars:			Indica si se desea ver las barras de error entorno del logit de las
				probabilidades predichas y de las proporciones del evento de interés.
				Ver DESCRIPTION para más información sobre cómo se construyen estas barras.
				Valores posibles: 0 => No, 1 => Sí.
				default: 0

- barwidth:		Número por el cual se multiplican los desvíos y errores estándares al
				construir las barras de error en los gráficos logit vs. variable regresora.
				Este parámetro tiene efecto sólo si bars=1.
				default: 1

- plotWhat:		Establece qué cantidad se desea ver en el eje vertical del gráfico
				del ajuste por variable regresora. Las opciones son:
				- LOGIT: 			se grafica el logit de la probabilidad.
									( logit(p) = log(p/(1-p)) )
				- P, PROB, PRED:	se grafica la probabilidad.
				default: logit

- axisX:		Valor de la opción ORDER del AXIS statement de opciones de gráfico
				para definir la escala del eje de las X con la variable regresora
				en los gráficos de ajuste.
				Su valor es de la forma <min> to <max> by <step>, aunque
				la parte del 'by' es opcional.

- axisLogit:	Valor de la opción ORDER del AXIS statement de opciones de gráfico
				para definir la escala de LOGIT en el eje vertical de los gráficos
				de ajuste.
				Su valor es de la forma <min> to <max> by <step>, aunque
				la parte del 'by' es opcional.
				Sólo tiene efecto si plotWhat=LOGIT.

- axisPred:		Valor de la opción ORDER del AXIS statement de opciones de gráfico
				para definir la escala de PROBABILIDAD en el eje vertical de los gráficos
				de ajuste.
				Su valor es de la forma <min> to <max> by <step>, aunque
				la parte del 'by' es opcional.
				Sólo tiene efecto si plotWhat=P, PROB o PRED.

- axisRes:		Valor de la opción ORDER del AXIS statement de opciones de gráfico
				para definir la escala de los RESIDUOS ESTANDARIZADOS en el eje vertical
				de los gráficos de redsiduos vs. variable regresora.
				Su valor es de la forma <min> to <max> by <step>, aunque
				la parte del 'by' es opcional.

- log:			Indica si se desea ver mensajes en el log generados por la macro.
				Valores posibles: 0 => No, 1 => Sí.
				default: 1

NOTES:
1.- En relación al ancho de las barras de error en los gráficos de logit vs. variable
regresora, notar que para las probabilidades predichas, la barra es proporcional al
DESVÍO estándar, mientras que para las probabilidades observadas el ancho de la barra
es proporcional al ERROR estándar (ver punto uno en "DESCRIPTION").
La razón de esta distinción es la siguiente: no se habla de error en el caso de las
probabilidades predichas porque éstas resultan de promediar los valores de las
probabilidades predichas dentro de cada grupo de la variable regresora. El desvío
estándar de estos valores es el que se usa para construir las barras de error. No se
tiene en cuenta en estas barras, el error estándar de cada probabilidad predicha
(proveniente de los errores estándares de los parámetros de regresión del modelo).

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Categorize
- %CheckInputParameters
- %DefineSymbols
- %GetNroElements
- %GetStat
- %GetVarList
- %MakeListFromName
- %Means
- %Mplot
- %Pretty
- %Qqplot
- %ResetSASOptions
- %SetSASOptions
- %SymmetricAxis

EXAMPLES:
1.- Dado que se realizó el siguiente PROC LOGISTIC:
proc logistic data=test;
	model flag = x1;
	output out=predicted pred=pred;
run;

La siguiente invocación a la macro analiza el ajuste en términos de las variables x1, x2:

%TestLogisticFit(predicted , var=flag x1 x2 , out=fit , pred=pred , event='Acepto');

Es decir, el ajuste de la regresión logística guardado en el dataset predicted, donde
flag es la variable respuesta, y x1, x2 son las potenciales variables regresoras, es
analizado.
La probabilidad modelada por la regresión logística es la del evento flag='Acepto'.
La probabilidad predicha esta guardada en la variable 'pred' del dataset predicted.
La opción out= pide generar los datasets fit_x1 y fit_x2 que contienen los datos
usados para realizar los gráficos mostrados por la macro.
*/
&rsubmit;
%MACRO TestLogisticFit(	data ,
						target= ,
						var= , 
						out= ,
						outCat= ,

						pred=p ,
						event=1 ,

						groups=10 ,
						percentiles= ,

						res=res ,
						suffixRes=0 ,

						plot=1 ,
						histogram=0 ,
						qqplot=1 ,
						plotWhat=logit ,
						refline=3.3 ,
						pointlabels=0 , 
						bars=0 ,
						barwidth=1 ,
						axisX= ,
						axisLogit= ,
						axisPred= ,
						axisRes= ,

						log=1 ,
						help=0)
		/ store des="Tests the fit of a logistic regression using fitted and residual plots";

/* NOTA SOBRE LOS RESIDUOS DE PEARSON (21/7/03):
En el libro de Dobson sobre GLM, pag. 127 dice que los residuos de Pearson estandarizados son
los que tienen distribucion N(0,1), y no los residuos de Pearson a secas, que son los que calcula
SAS, y los que tambien se calculan en esta macro cuando se calculan los residuos agrupados.
Uno podria intentar usar los residuos estandarizados de Pearson, pero el problema es que
estan dividos por un factor que depende del elemento diagonal de la hat matrix, y este valor
no se conoce al momento de calcular los residuos agrupados, ya que el modelo fue ajustado para
las observaciones no agrupadas.
Tal vez se podria usar como valor diagonal de la hat matrix el promedio de los valores diagonales
de la hat matrix del modelo desagregado, ya que se supone que son valores parecidos. Sin embargo,
esto tiene el inconveniente (leve) de que al hacer el PROC LOGISTIC hay que pedir que en el
output dataset genere la columna con el leverage (opcion h=), lo cual debe ser hecho por el
usuario antes de llamar a la macro.
Por otro lado, a mi me parece que los residuos de Pearson a secas deberian tener distribucion
aproximadamente N(0,1) por el T.C.L. aplicado a una distribucion Binomial, con lo cual usarlos
no representaria mayores inconvenientes y seria igualmente apropiado.
*/

/*----- Macro to display usage -----*/
%MACRO ShowMacroCall;
	%put;
	%put TESTLOGISTICFIT: The macro call is as follows:;
	%put;
	%put %nrstr(%TestLogisticFit%();
	%put data , (REQUIRED) %quote(      *** Input dataset.);
	%put target= , %quote(              *** Variable respuesta.);
	%put var= , (REQUIRED) %nrquote(      *** Lista con las variables regresoras %(puede incluir la variable respuesta);
	%put %nrquote(                            en primer lugar%).);
	%put out= ,	%quote(                 *** Raiz del nombre de los output datasets conteniendo lo que se grafica.);
	%put outCat= , %quote(              *** Output dataset con las variables regresoras categorizadas.);
	%put;
	%put pred=p , %quote(               *** Variable que contiene las probabilidades predichas.);
    %put event=1 , %quote(              *** Evento modelado por la regresion logistica.);
    %put groups=10 , %quote(            *** Número de grupos en los que efectuar la categorización.);
    %put percentiles= , %quote(         *** Percentiles para la categorizacion.);
	%put;
	%put res=res , %quote(              *** Nombre a usar para la variable con el residuo estandarizado.);
	%put suffixRes=0 , %quote(          *** Agregar la variable regresora como sufijo para la variable 'res'?);
	%put;
	%put plot=0, %quote(                *** Mostrar gráficos?);
	%put histogram=0 , %quote(          *** Hacer el histograma de los residuos?);
	%put qqplot=1 , %quote(             *** Hacer el normal Q-Q plot de los residuos?);
	%put plotWhat=logit , %quote(       *** Graficar el logit(p) ó p en los gráficos del ajuste?);
	%put refline=3.3, %quote(           *** Valor de la línea de referencia en el gráfico de los residuos.);
	%put pointlabels=0, %quote(         *** Mostrar point labels?);
	%put bars=0 , %quote(               *** Mostrar barras de error en los gráficos de probabilidades?);
	%put barwidth=1, %quote(            *** Multiplicador para las barras de error.);
	%put axisX= , %quote(               *** Axis statement a usar en el eje de las X en los gráficos.);
	%put axisLogit= , %quote(           *** Axis statement a usar en el eje del logit en los gráficos.);
	%put axisPred= , %quote(            *** Axis statement a usar en el eje de las probabilidades en los);
	%put %quote(                            gráficos.);
	%put axisRes= , %quote(             *** Axis statement a usar en el eje de los residuos en los gráficos.);
	%put;
	%put log=1)%quote(                  *** Mostrar mensajes en el log?);
%MEND ShowMacroCall;
/*----- Macro to display usage -----*/

%if &help %then %do;
	%ShowMacroCall;
%end;
%* Checking required parameters and existence of input dataset;
%else %if ~%CheckInputParameters(	data=%quote(&data) , var=&var , requiredParamNames=data var= ,
									varRequired=1 , macro=TESTLOGISTICFIT) %then %do;
	%ShowMacroCall;
%end;
%else %if ~%CheckInputParameters(	data=%quote(&data) , var=&pred , varRequired=0 , macro=TESTLOGISTICFIT) %then %do;
		%** The second call is to check whether variable &pred exists in &data;
		%** Note that I do not list it in the var= parameter of the previous call to
		%** %CheckInputParameters because the parameter var= is required in the call
		%** to %TestLogisticFit. If I did that, the first call to %CheckInputParameters
		%** would return TRUE when the var= parameter of %TestLogisticFit is empty and
		%** &pred exists in &data (which is not what I want);
		%** On the other hand, note that I do not call %ExistVar to check for the
		%** existence of &pred in &data because I want an error message to be displayed
		%** if &pred is not found. %ExistVar does not display any error messages;
	%ShowMacroCall;
%end;
%else %if %quote(&target) ~= and 
	  ~%CheckInputParameters(data=&data , var=&target , varRequired=0 , macro=TESTLOGISTICFIT) %then %do;
		%** This call is to check whether the variable &target exists in &data;
		%** Same comment as above as to why I do not list &target in the first call to
		%** %CheckInputParameters;
	%ShowMacroCall;
%end;
%else %do;
/************************************* MACRO STARTS ******************************************/
/* Local variables declaration */
%local i error nro_vars pos;
%local resp _var_;
%local PredInVar;
%local data_name out_name out_options;
%local annost1 annost2 gplot orderst pointlabel step;
	%* pointlabel indica el nombre de la variable que hace de pointlabel en los graficos, y se usa
	%* solamente en la llamada a la macro %qqplot;
%local logit;	%* Igual a logit_ si plotWhat=logit. De lo contrario es vacia (si plotWhat=prob, p o pred);
%local ylabel;	%* Nombre a usar como label en el eje vertical y en el titulo de los graficos del ajuste;
%local gout;	%* Variable que indica el catalog entry donde guardar el Q-Q plot en caso de requerir
				%* tambien el histogram, para que muestre los dos en la misma ventana;
%local hsize;	%* Se usa en el PROC GREPLAY que muestra el Q-Q plot y el histograma;
%local vsize;	%* Se usa en el PROC GREPLAY que muestra el Q-Q plot y el histograma;
%local title;	%* Overall title for graphs;

%* Setting options;
%SetSASOptions;

%* Showing input parameters;
%if &log %then %do;
	%put;
	%put TESTLOGISTICFIT: Macro starts;
	%put;
	%put TESTLOGISTICFIT: Input parameters:;
	%put TESTLOGISTICFIT: - Input dataset = %quote(&data);
	%put TESTLOGISTICFIT: - target = %quote(       &target);
	%put TESTLOGISTICFIT: - var = %quote(          &var);
	%put TESTLOGISTICFIT: - out = %quote(          &out);
	%put TESTLOGISTICFIT: - outCat = %quote(       &outCat);
	%put TESTLOGISTICFIT: - pred = %quote(         &pred);
	%put TESTLOGISTICFIT: - event = %quote(        &event);
	%put TESTLOGISTICFIT: - groups = %quote(       &groups);
	%put TESTLOGISTICFIT: - res = %quote(          &res);
	%put TESTLOGISTICFIT: - suffixRes = %quote(    &suffixRes);
	%put TESTLOGISTICFIT: - percentiles = %quote(  &percentiles);
	%put TESTLOGISTICFIT: - plot = %quote(         &plot);
	%put TESTLOGISTICFIT: - histogram = %quote(    &histogram);
	%put TESTLOGISTICFIT: - qqplot = %quote(       &qqplot);
	%put TESTLOGISTICFIT: - plotWhat = %quote(     &plotWhat);
	%put TESTLOGISTICFIT: - refline = %quote(      &refline);
	%put TESTLOGISTICFIT: - pointlabels = %quote(  &pointlabels);
	%put TESTLOGISTICFIT: - bars = %quote(         &bars);
	%put TESTLOGISTICFIT: - barwidth = %quote(     &barwidth);
	%put TESTLOGISTICFIT: - axisX = %quote(        &axisX);
	%put TESTLOGISTICFIT: - axisLogit = %quote(    &axisLogit);
	%put TESTLOGISTICFIT: - axisPred = %quote(     &axisPred);
	%put TESTLOGISTICFIT: - axisRes = %quote(      &axisRes);
	%put TESTLOGISTICFIT: - log = %quote(          &log);
	%put;
%end;

%*** Parsing input parameters;
%let error = 0;
%* VAR;
%* Leyendo la lista de variables pasadas en &var (en caso de que su valor sea _NUMERIC_ haya hyphens, etc.;
%let var = %GetVarList(&data, var=&var, log=0);

%* Variable respuesta (dicotomica);
%if %quote(&target) ~= %then %do;
	%let resp = &target;
	%let nro_vars = %GetNroElements(&var);
%end;
%else %do;
	%let resp = %scan(&var, 1, ' ');
	%* Elimino la variable respuesta de la lista (podria usar %RemoveFromList, pero esto lo hice
	%* antes de crear esa macro);
	%let nro_vars = %GetNroElements(&var);
	%let pos = %sysfunc(indexc(%quote(&var), ' '));
	%* Check if there is only one variable passed which would mean that the regressor variables
	%* are missing;
	%if %eval(&pos + 1) > %length(&var) %then %do;
		%put TESTLOGISTICFIT: ERROR - Some variables are missing in parameter var=;
		%put TESTLOGISTICFIT: The format of var= is: <response-variable> <regressor-variables>;
		%let error = 1;
	%end;
	%else %do;
		%let var = %substr(&var , &pos+1);
		%let nro_vars = %GetNroElements(&var);
	%end;
%end;

%if ~&error %then %do;
	%* Continue parsing input parameters;
	%* OUT;
	%if %quote(&out) = %then
		%let out = _;
		%** Creo un nombre bien cortito para el output dataset temporal porque despues a este nombre se le
		%** agrega el nombre de la variable regresora, y si este nombre es largo, puede haber error al superar
		%** el numero de caracteres maximo de SAS que es 32;
	%let out_name = %scan(&out , 1 , '(');
	%let out_options = %GetDataOptions(&out);

	%* Categorizacion de las variables regresoras;
	%if %quote(&percentiles) = %then %do;
		%if &groups ~= %then
			%let percentiles = %MakeListFromName( , length=&groups , start=%sysevalf(100/&groups) , step=%sysevalf(100/&groups));
		%else
			%let percentiles = %MakeListFromName( , length=10 , start=10 , step=10);
	%end;
	%* Parsing options in &data;
	data _TestLogisticFit_data_;
		set &data;	%* Aqui se ejecutan todas las opciones que vengan con &data;
		keep &resp &var &pred;
		%if %sysfunc(indexw(%upcase(&var), %upcase(&pred))) %then %do;
			%let PredInVar = 1;
			%* Se crea una nueva variable igual a PRED para que el calculo de los desvios 
			%* estandares de PRED en cada grupo sean correctos. De lo contrario, como una
			%* de las variables de analisis coincide con PRED, el desvio estandar de PRED
			%* en el output dataset va a dar 0, pues se calcula sobre el dataset con las variables 
			%* categorizadas (_TestLogisticFit_cat_) que NO conserva las variables originales y
			%* por lo tanto los valores de PRED en cada grupo de la categorizacion van a ser los
			%* mismos (porque PRED es una de las variables de analisis);
			_TLF_pred_ = &pred;
			keep _TLF_pred_;
		%end;
		%else
			%let PredInVar = 0;
	run;
		%* Notar que a continuacion elimino las observaciones con &resp = . o &pred = ., porque estas
		%* observaciones no intervinieron en la regresion, ya sea porque la respuesta era missing
		%* (o sea &resp = .) o porque alguna variable regresora era missing (lo cual esta indicado por
		%* &pred = .).
		%* Por lo tanto solamente van a entrar en la categorizacion de las variables regresoras
		%* las observaciones que entraron en la regresion;
	%if &log %then
		%put TESTLOGISTICFIT: Categorizing independent variables...;
	%* DM-2016/02/15: Changed call from %Categorize to %CategorizePercentiles which holdds the
	%* original version of the %Categorize macro before its refactoring to a much simpler version
	%* that uses PROC RANK (and which therefore does not accept a given set of percentile values
	%* on which the groups should be computed);
	%CategorizePercentiles(_TestLogisticFit_data_(where=(&resp ~= . and &pred ~=.)) ,
				out=_TestLogisticFit_cat_ ,
				var=&var , value=mean , varvalue=&var, suffix= , both=0, percentiles=&percentiles , log=0);

	%* Statements for Annotate datasets;
	%let annost1 =;
	%let annost2 =;
	%* GOUT catalog for Q-Q plot and the histogram;
	%let gout =;
	%* Variable defining what to plot (if logit or p), its label and the reference lines to be used.
	%* The default is to plot logit;
	%let logit = logit_;
	%let ylabel = logit;
	%let vref = 0;

	%* Analisis del Logistic Fit;
	%do i = 1 %to &nro_vars;
		%let _var_ = %scan(&var , &i , ' ');
		%* Si se pide, agrego como sufijo de la variable con el residuo estandarizado, el nombre
		%* de la variable regresora que se esta analizando;
		%if &suffixRes %then
			%let res = &res._&_var_;
		%if &log %then
			%put TESTLOGISTICFIT: Analysis of model fit for variable %upcase(&_var_). Modeling %upcase(&resp) = &event;

		%**************************** Observed Probability (o proportion) ******************************;
		%* Creando una variable numerica para poder contar el numero de &event para cada categoria de la variable
		%* regresora &_var_;
		data _TestLogisticFit_cat_;
			set _TestLogisticFit_cat_;
			if &resp = . then _resp_num_ = .;		%*** Notar que si &resp es caracter, al comparar con ., resulta &resp missing si es efectivamente missing (es decir vacio por ser una variable caracter);
			else if &resp = &event then _resp_num_ = 1;
			else if &resp ~= &event then _resp_num_ = 0;
		run;
		%* Proporcion de &event en cada grupo de la variable regresora &_var_ (Observed Probability);
		%if &log %then
			%put TESTLOGISTICFIT: Computing observed and predicted probabilities by category...;
			%* Notar que elimino las observaciones con &pred = . porque para ellas no hay probabilidad estimada
			%* y por lo tanto no hay residuo. Las observaciones con &pred = . no intervinieron en la regresion
			%* y son aquellas con alguna variable regresora missing;
		%Means(_TestLogisticFit_cat_(where=(&pred~=.)) , var=_resp_num_ , by=&_var_ , stat=sum n , name=resp_sum n , out=_TestLogisticFit_event_sum_, log=0);

		%**************************** Average Predicted Probability ******************************;
		%* Promedio de la probabilidad predicha en cada grupo de la variable regresora &_var_ (Predicted Probability);
		%* Notar que calculo el promedio y su desvio estandar solamente a partir de las observaciones con
		%* &resp ~= missing. Esto se debe a que en el output dataset de PROC LOGISTIC, la probabilidad predicha
		%* no es missing si la respuesta es missing, con lo que no tener esto en cuenta hace que el calculo 
		%* de estas cantidades sea incorrecto, y por lo tanto el valor del residuo calculado en esta macro;
		%if ~&PredInVar %then %do;
			%Means(_TestLogisticFit_cat_(where=(&resp~=.)) , var=&pred , by=&_var_ , stat=mean stddev , name=&pred._Mean &pred._Std , out=&out_name._&_var_, log=0);
		%end;
		%else %do;
			%* Se usa _TLF_pred_ para calcular el promedio y desvio estandar de PRED, porque PRED
			%* es una variable de analisis, y si la uso el desvio estandar me va a dar 0, y no es lo que queremos;
			%Means(_TestLogisticFit_cat_(where=(&resp~=.)) , var=_TLF_pred_ , by=&_var_ , stat=mean stddev , name=&pred._Mean &pred._Std , out=&out_name._&_var_, log=0);
		%end;
			%** NOTA: Si uno promediara por cada valor de la by variable los residuos de Pearson devueltos por
			%** PROC LOGISTIC, y los comparara con los residuos de Pearson calculados en esta
			%** macro (es decir los residuos de Pearson agrupados), ve que los residuos agrupados son
			%** en general 10 veces mas grandes que el promedio de los residuos desagregados (esto al menos
			%** paso para una variable regresora en particular en un modelo particular). 
			%** Sin embargo, tiene sentido que pase en general porque tambien vi que la distribucion de dicho
			%** promedio es muy estrecha respecto a la N(0,1) (es decir los promedios estan muy apinhados
			%** entorno del 0), con lo que su distribucion no es normal (digo que lo de antes tiene sentido
			%** en base a esto porque esta distribucion es en general la que uno ve en contextos generales).
			%** Por lo tanto los residuos que deben calcularse son en verdad los residuos de  Pearson agrupados,
			%** como se hace en esta macro, y no los promedios de los residuos individuales;

		%************* Merging Observed Probability and Predicted Probability ******************;
		data &out_name._&_var_;
			format &_var_ 	n
							&resp._mean &resp._Lower &resp._Upper &resp._std
							&pred._mean &pred._Lower &pred._Upper &pred._std
							logit_&resp._Mean logit_&resp._Lower logit_&resp._Upper
							logit_&pred._Mean logit_&pred._Lower logit_&pred._Upper;
			merge &out_name._&_var_ _TestLogisticFit_event_sum_;
			by &_var_;

			%*** Observed Probability;
			&resp._Mean = resp_sum / n;							%* Proporcion de resp=&event en el dataset;
			&resp._Std = sqrt(&resp._Mean*(1 - &resp._Mean)/n);		%* Desvio estandar estimado de la proporcion de obs. con resp=&event;
			&resp._Lower = max(0,&resp._Mean - &barwidth*&resp._Std);	%* Lower end del +/- std;
			&resp._Upper = min(1,&resp._Mean + &barwidth*&resp._Std);	%* Upper end del +/- std;
			 	%* ESTOS CALCULOS DEL Lower Y DEL Upper SUPONEN QUE LA ESTIMACION DE LA PROPORCION
				%* ESTA BASADA EN UN NUMERO IMPORTANTE DE OBSERVACIONES Y QUE POR TANTO TIENE DISTRIBUCION NORMAL
				%* YA QUE SE HACE +/- UN MULTIPLO DE LA STANDARD DEVIATION DE LA PROPORCION ESTIMADA COMO
				%* prop*(1-prop)/n.
				%* EN RIGOR PARA CALCULAR EL LOWER VALUE Y EL UPPER VALUE HABRIA QUE USAR LA DISTRIBUCION
				%* BINOMIAL DE T = NUMERO DE &resp=&event;
			%* Logit of Observed Probability;
			if 0 < &resp._Mean < 1 then logit_&resp._Mean = log(&resp._Mean / (1 - &resp._Mean));
			else logit_&resp._Mean = .;
	%*		logit_&resp._std = 1 / (n*&resp._std);
				%* Aproximacion de Taylor, que surge de derivar logit(prop): SE(logit) = SE(prop) / (prop*(1-prop));

			%* Real values of the upper and lower end of the logit(prop), by transforming the upper and lower end
			%* of the estimated proportion (that is the Taylor approximation computed above is not necessary);
			if 0 < &resp._Lower < 1 then logit_&resp._Lower = log(&resp._Lower / (1 - &resp._Lower));
			else logit_&resp._Lower = .;
			if 0 < &resp._Upper < 1 then logit_&resp._Upper = log(&resp._Upper / (1 - &resp._Upper));
			else logit_&resp._Upper = .;

			%*** Predicted Probability;
				%* Usar la siguiente linea si quiero mostrar en el grafico el desvio estandar del
				%* promedio de la predicted probability;
				%* Particularmente creo que mostrar esa cantidad no aporta demasiado porque lo que
				%* querriamos ver es algo que nos indique la distribucion de las probabilidades predichas
				%* para cada valor de la variable categorizada. Con lo cual seria aun mas util un boxplot?;
			%*&pred._std = &pred._std / n;									%* Standard Error of average predicted probability;
			&pred._Lower = max(0,&pred._mean - &barwidth*&pred._std);		%* Lower end of +/- std (set to 0 if < 0);
			&pred._Upper = min(1,&pred._mean + &barwidth*&pred._std);		%* Upper end del +/- std (set to 1 if > 1);

			%* Logit of Predicted Probability;
			if 0 < &pred._Mean < 1 then logit_&pred._Mean = log(&pred._Mean / (1 - &pred._Mean));
			else logit_&pred._Mean = .;
	%*		logit_&pred._std = &pred._std / (&pred._mean*(1 - &pred._mean));
				%* Aproximacion de Taylor, que surge de derivar logit(p): SE(logit) = SE(p) / (p*(1-p));

			%* Real values of the upper and lower end of the logit(p), by transforming the upper and lower end
			%* of the estimated probability (that is the Taylor approximation computed above is not necessary);
			if 0 < &pred._Lower < 1 then logit_&pred._Lower = log(&pred._Lower / (1 - &pred._Lower));
			else logit_&pred._Lower = .;
			if 0 < &pred._Upper < 1 then logit_&pred._Upper = log(&pred._Upper / (1 - &pred._Upper));
			else logit_&pred._Upper = .;

			%* Standardized residual;
			if 0 < &pred._Mean < 1 then	&res = (&resp._mean - &pred._mean) / sqrt(&pred._mean*(1-&pred._mean)/n);
			else &res = .;

				%* Note below that the label for &pred._std and for logit_&pred._std is Standard Deviation,
				%* as opposed to Standard Error. This is because its computation is based on the variability
				%* of the predicted probability in each group.
				%* Note also that the estimated probability should have a standard error component related to
				%* the parameter estimates standard errors, but this was not considered;
			label	n 					= "Nro. of obs. with non missing values of &resp and &pred"
					&res				= "Standardized residual"
					&resp._mean		 	= "Observed Probability"
					&resp._std 			= "Standard Error of Observed Probability"
					&resp._Lower		= "Lower end of Observed Probability (-&barwidth*STD)"
					&resp._Upper		= "Upper end of Observed Probability (+&barwidth*STD)"

						/* 	Uso el label Estimated Probability y no Predicted Probability porque Estimated
							es el nombre que usa SAS para la probabilidad estimada por el modelo */
					&pred._mean 		= "Average Estimated Probability"
					&pred._std 			= "Standard Deviation of Average Estimated Probability"
					&pred._Lower		= "Lower end of Average Estimated Probability (-&barwidth*STD)"
					&pred._Upper		= "Upper end of Average Estimated Probability (+&barwidth*STD)"

					logit_&resp._Mean 	= "Logit of Observed Probability"
					/* logit_&resp._std = "Standard Error of Logit of Observed Probability" */
					logit_&resp._Lower	= "Lower end of Logit of Observed Probability"
					logit_&resp._Upper	= "Upper end of Logit of Observed Probability"

					logit_&pred._Mean 	= "Logit of Average Estimated Probability"
					/* logit_&pred._std = "Standard Deviation of Logit of Average Estimated Probability" */
					logit_&pred._Lower	= "Lower end of Logit of Average Estimated Probability"
					logit_&pred._Upper	= "Upper end of Logit of Average Estimated Probability";
			drop resp_sum;
		run;
		%if &log and &out_name ~= _ %then
			%put TESTLOGISTICFIT: Output dataset %upcase(&out_name._&_var_) created.;

		%*** Graficos;
		%if &plot %then %do;
			%if &log %then
				%put TESTLOGISTICFIT: Preparing to plot...;
			%DefineSymbols(log=0);
			%* Store input dataset name (without the options);
			%let data_name = %scan(&data, 1, '(');

			%* Observed and Predicted;
			%* Barras de error: no hay barras de error si &barwidth = 0;
			%if %upcase(&plotWhat) ~= LOGIT %then %do;
				%if %upcase(&plotWhat) = PROB or %upcase(&plotWhat) = P or %upcase(&plotWhat) = PRED %then %do;
					%let logit =;		%* Vacio significa que la variable a graficar no empieza con LOGIT_
										%* sino que es directamente la probabilidad;
					%let ylabel = Probability;
					%let vref = 0 1;
				%end;
				%else %do;
					%put TESTLOGISTICFIT: WARNING - The value of parameter PLOTWHAT= (%upcase(&plotWhat)) is not valid.;
					%put TESTLOGISTICFIT: Assuming that PLOTWHAT=LOGIT, the logit of the probabilities will be plotted.;
					%put TESTLOGISTICFIT: Valid values for parameter PLOTWHAT= are LOGIT, P, PROB and PRED (not case sensitive).;
					%let plotWhat = LOGIT;
						%** Notar que los valores de &logit, de &ylabel y de &vref ya fueron seteados a los valores
						%** default en la seccion PARSING INPUT PARAMETERS;
				%end;
			%end;
			%if &bars and &barwidth > 0 %then %do;
				%* Annotate dataset para las barras de error del grafico logit vs. &_var_;
					%* Notar que para las variables de posicion (x e y) uso _x_ e _y_ para minimizar
					%* las posibilidades de superposicion con variables con el mismo nombre (x e y) en
					%* el input dataset &out_name._&_var_.
					%* Al final del dataset, renombro _x_ por x, _y_ por y.
					%* (Ya me paso que existia la variable Y en el input dataset -que ademas hacia el
					%* papel de x- y se hizo un lio terrible).
					%* Las demas variables del annotate dataset no les pongo el underscore por dos razones:
					%* - es raro que un input dataset del usuario tenga variables con esos nombres y, mas
					%* importante, porque
					%* - esas variables son seteadas a valores en forma explicita, no como las variables 
					%* x e y que son seteadas a valores de otras variables del dataset &out_name._&_var_,
					%* con lo que puede haber problemas si alguna variable del input dataset tiene el
					%* mismo nombre que alguna de ellas.
					%*************************************************************************************;
					%* NOTA IMPORTANTE: Para que el data step funcione sin problemas es muy importante
					%* el FORMAT statement del principio, debido al RENAME que hago al final, en que
					%* renombro _x_ por x, _y_ por y. De hecho, el RENAME y el FORMAT estan relacionados
					%* en el caso de que existan en el dataset las dos variables involucradas en el RENAME
					%* (por ej. _x_ y x): como norma general, la variable que es renombrada debe aparecer
					%* antes en el dataset que la otra variable, para que no haya error de ejecucion
					%* (en este caso, _x_ debe aparecer antes que x, y _y_ antes que y). Y este orden
					%* justamente se fuerza con el FORMAT statement del principio.
					%* Nota: el mismo resultado podria lograrse sin el FORMAT statement pero con un KEEP
					%* statement (igual al y en lugar del KEEP= option del annotate dataset) justo antes
					%* del RENAME statement del final donde se renombra _x_ por x, _y_ por y;
					%*************************************************************************************;
				data _TestLogisticFit_anno_logit_(keep=xsys ysys x y function text color line position when);
					format xsys ysys _x_ _y_ function text color line position when;
					set &out_name._&_var_;
					length function $8 text $8 color $5;		
						%** length de text es 8 para contemplar posibles largos distintos de su valor;
						%** Asimismo, aparentemente el length de FUNCTION tiene que ser 8 (una vez me
						%** dio que esa variable tenia un IMPROPER LENGTH);
					retain xsys "2" ysys "2" when "B" _x_ _y_;	%* _x_ and _y_ are retained!;
					retain position "2";
					%** This is to avoid a warning that variable POSITION in the KEEP statement
					%** does not exist, which occurs when POINTLABELS=0, because the variable
					%** position is only used when pointlabels are shown in the plot;

					if &_var_ ~= . then do;
						%*** Barras de error para &logit&resp (logit de la proporcion);
							%* Notar el uso de symbol=PLUS para los extremos de las barras, porque no hay
							%* manera de que ponga un underscore o dash, incluso usando comillas como dice el help.
							%* El PLUS symbol es lo que mas se le parece al dash.
							%* Intente millones de cosas, incluso usar function=label en lugar de function=symbol
							%* con la intencion de escribir explicitamente un dash como texto.
							%* Esto andaria, pero tiene el inconveniente de que seguramente su tamanho no
							%* se adaptaria al tamanho de los symbols si el tamanho del grafico cambia;
						if &logit&resp._Mean ~= . then do;
							%** Si el valor estimado no es missing, dibujo cosas, si no no dibujo nada;
							%* Primero me ubico en el valor estimado, para evitar problemas si alguno de los
							%* extremos de las barras de error son missing;
							_x_ = &_var_; _y_ = &logit&resp._Mean;
								function = "move"; ; text = ""; color = ""; line = .; output;
								%if &pointlabels %then %do;
									function = "label"; text = trim(left(put(n , 8.))); color = "black"; line = .; position = "2"; output;
								%end;
							%* Lower end (line and symbol);
							_x_ = &_var_; _y_ = &logit&resp._Lower;
								function = "draw"; ; text = ""; color = "blue"; line = 1; output;
								function = "symbol"; text = "plus"; color = "blue"; line = .;
									when = "A"; output; when = "B";	%* resetting variable WHEN to its default;
							%* Upper end (line and symbol);
								%* Note that if lower end is missing, the line is connected from estimated value to upper end;
							_x_ = &_var_; _y_ = &logit&resp._Upper;
								function = "draw";  text = ""; color = "blue"; line = 1; output;
								function = "symbol"; text = "plus"; color = "blue"; line = .;
									when = "A"; output; when = "B";	%* resetting variable WHEN to its default;
										%** WHEN=A is set so that the symbol corresponding to the lower and
										%** upper end of the observed probability is drawn over the reference
										%** lines at 0 and 1 (in case the plotwhat=p option is passed); 
						end;				

						%*** Barras de error para &logit&pred (logit de la probabilidad predicha);
						if &logit&pred._Mean ~= . then do;
							%** Si el valor estimado no es missing, dibujo cosas, si no no dibujo nada;
							%* Primero me ubico en el valor estimado, para evitar problemas si alguno de los
							%* extremos de las barras de error son missing;
							_x_ = &_var_; _y_ = &logit&pred._Mean;
								function = "move"; ; text = ""; color = ""; line = .; output;
							%* Lower end (line and symbol);
							_x_ = &_var_; _y_ = &logit&pred._Lower;
								function = "draw"; ; text = ""; color = "red"; line = 3; output;
								function = "symbol"; text = "plus"; color = "red"; line = .; 
									when = "A"; output; when = "B";	%* resetting variable WHEN to its default;
							%* Upper end (line and symbol);
								%* Note that if lower end is missing, the line is connected from estimated value to upper end;
							_x_ = &_var_; _y_ = &logit&pred._Upper;
								function = "draw";  text = ""; color = "red"; line = 3; output;
								function = "symbol"; text = "plus"; color = "red"; line = .;
									when = "A"; output; when = "B";	%* resetting variable WHEN to its default;
										%** WHEN=A is set so that the symbol corresponding to the lower and
										%** upper end of the predicted probability is drawn over the reference
										%** lines at 0 and 1 (in case the plotwhat=p option is passed); 
						end;				
					end;
					rename 	_x_ = x
							_y_ = y;
				run;
				%* Elimino los x = . o y = . porque a veces generan cruces que no tienen que generar;
				data _TestLogisticFit_anno_logit_;
					set _TestLogisticFit_anno_logit_;
					where x ~= . and y ~= .;
				run;
				%let annost1 = annotate=_TestLogisticFit_anno_logit_;
				%* Calculo maximo y minimo para el eje vertical del grafico del ajuste;
				%if (%upcase(&plotWhat) = LOGIT and %quote(&axisLogit) =) or
					(%upcase(&plotWhat) = PROB or %upcase(&plotWhat) = P or %upcase(&plotWhat) = PRED) and %quote(&axisPred) = 	%then %do;
					%GetStat(_TestLogisticFit_anno_logit_ , var=y , stat=min , name=_y_min_ , log=0);
					%GetStat(_TestLogisticFit_anno_logit_ , var=y , stat=max , name=_y_max_ , log=0);
					%let step = %sysevalf((%pretty(&_y_max_) - %pretty(&_y_min_))/10);		%* 10 tickmarks; 
						%** Variable &step is created to have the upper extreme value be the correct one, because sas 
						%** does not always make the upper value fit in the plot (this depends on the value of the step
						%** used between tick marks, which is not known in advance (i.e. SAS is a complete DISASTER!!);
					%let orderst = order=%pretty(&_y_min_) to %pretty(&_y_max_) by &step;
						%** option used in the axis2 statement below;
						%** Macro %PRETTY is used to have pretty values for the axis extreme values;
					%symdel _y_min_ _y_max_;
					quit; 	%* Para evitar problemas con el %symdel;
				%end;
				%else %if %upcase(&plotWhat) = LOGIT %then
					%let orderst = order=&axisLogit;
				%else %if %upcase(&plotWhat) = PROB or %upcase(&plotWhat) = P or %upcase(&plotWhat) = PRED %then
					%let orderst = order=&axisPred;
				%else
					%let orderst = ;
			%end;
			%else %if &pointlabels %then %do;	%* Annotate dataset para los point labels;
				data _TestLogisticFit_anno_logit_(keep=xsys ysys x y function text position);
					format xsys ysys _x_ _y_ function text position;
					set &out_name._&_var_;
					retain xsys "2" ysys "2";
					_x_ = &_var_;
					_y_ = &logit&resp._Mean;
					function = "label";
					text = trim(left(put(n , 4.)));
					position = "2";
					rename 	_x_ = x
							_y_ = y;
				run;
				%* Elimino los x = . o y = . porque si no genera labels que no tiene que mostrar;
				data _TestLogisticFit_anno_logit_;
					set _TestLogisticFit_anno_logit_;
					where x ~= . and y ~= .;
				run;
				%let annost1 = annotate=_TestLogisticFit_anno_logit_;
			%end;

			%*** Annotate dataset para mostrar el numero de observaciones en cada
			%*** grupo de la variable categorizada _var_ en el grafico.
			%*** (porque el POINTLABEL option del SYMBOL statement no siempre anda!!!);
			%if &pointlabels %then %do;
				data _TestLogisticFit_anno_res_(keep=xsys ysys x y function text position);
					format xsys ysys _x_ _y_ function text position;
					set &out_name._&_var_;
					retain xsys "2" ysys "2";
					_x_ = &_var_;
					_y_ = &res;
					function = "label";
					text = trim(left(put(n , 4.)));	%* Eliminating trailing blanks so that the label is centered above each point;
					position = "2"; 				%* position=2 means centered one cell above;
					rename 	_x_ = x
							_y_ = y;
				run;
				%* Eliminating possible missing values in x or y;
				data _TestLogisticFit_anno_res_;
					set _TestLogisticFit_anno_res_;
					where x ~= . and y ~=.;
				run;
				%let annost2 = annotate=_TestLogisticFit_anno_res_;
			%end;

			%* Generacion de un statement para generar un grafico simetrico respecto al 0 en el eje vertical
			%* para el grafico de residuals vs. _var_ que esta dentro del gplot statement;
			%if %quote(&axisRes) = %then %do;
				%global _vaxis_;
					%* Se define la variable _vaxis_ (que es en realidad definida por %SymmetricAxis como global)
					%* en caso de que %SymmetricAxis encuentre un error (por ej. de que todos los valores de
					%* res son missing) tal que la macro variable _vaxis_ no sea definida como se espera.
					%* Si un tal error ocurriese y _vaxis_ no estuviese definida con anterioridad
					%* a la ejecucion de %SymmetricAxis, se produciria el error de que la macro variable
					%* _vaxis_ no existe y esta macro dejaria de funcionar;
				%SymmetricAxis(&out_name._&_var_ , var=&res , axis=_vaxis_ , log=0);
				%let axisRes = &_vaxis_;
				%* Borro la variable global;
				%symdel _vaxis_;
				quit;	%* Para evitar problemas con el %symdel;
			%end;

			%*** Graficos de logit vs. _var_ y de residuals vs. _var_;
			%*** GPLOT statement para hacer los graficos en una sola ventana;
			axis1;
			%if %quote(&axisX) ~= %then %do;
				axis1 order=&axisX;
			%end;
			axis2;
			%if %quote(&axisLogit) ~= %then %do;
				%let orderst = order=&axisLogit;
			%end;

			%let gplot = %str(
				symbol2 interpol=join value=star width=2;
				title "&ylabel vs. %upcase(&_var_) (categorized)";
				legend value=("Observed" "Estimated");
				axis2 label=(angle=90 "&ylabel") &orderst;
				footnote "Point label is number of obs in each group";
				proc gplot data=&out_name._&_var_ gout=tempcat &annost1;
					plot &logit&resp._Mean*&_var_=1 &logit&pred._Mean*&_var_=2
						/ overlay legend=legend haxis=axis1 vaxis=axis2 vref=&vref name="plot1";
				run;
				legend;
				title "Residuals vs. %upcase(&_var_) (categorized)";
				axis2 label=(angle=90) order=&axisRes;
				proc gplot data=&out_name._&_var_ gout=tempcat &annost2;
					plot &res*&_var_=1 / haxis=axis1 vaxis=axis2 vref=-&refline 0 &refline name="plot2";
				run;
				quit;
				axis1;
				axis2;);
			%let title = "Analysis of Logistic Fit for %upcase(&resp) against variable %upcase(&_var_)"
						 justify=center "Dataset = %upcase(&data_name) Predicted = %upcase(&pred)";
			%Mplot(&gplot , 1 , 2 , title=&title , frame=1 , description="Logistic Fit - %upcase(&_var_)" , nonotes=1);

			%* Distribution of residuals;
			%if &qqplot and &histogram %then %do;
				%let gout = _tempcat_;	%* La idea es crear el Q-Q plot y el histograma en tempcat para despues poder mostrarlos en la misma ventana con GREPLAY;
				%* Borro el contenido del catalogo _tempcat_ en caso de existir;
				%if %sysfunc(cexist(_tempcat_)) %then %do;	%*** Checks existence of catalog _tempcat_;
					proc greplay nofs igout=_tempcat_;
						delete _all_;
					run;
				%end;
				/* Use DSGI functions HSIZE/VSIZE to determine default HSIZE and VSIZE
				   and modify them for correct aspect ratio. (Taken from mplot by SAS (mplotsas.sas)) */
				data _NULL_;
					rc=ginit();
					call gask('hsize',hsize,rc);
					hsze = hsize/2;
					call symput('hsize',left(trim(hsze)));
					call gask('vsize',vsize,rc);
					vsze = vsize;
					call symput('vsize',left(trim(vsze)));
					rc=gterm();
				run;
				goptions nodisplay hsize=&hsize;
			%end;
			%if &qqplot %then %do;
				title "Normal(0,1) Q-Q plot of Residuals for %upcase(&_var_)" justify=center "(Observed Probability MINUS Estimated Probability)";
				%if &pointlabels %then %let pointlabel = n;
				%qqplot(&out_name._&_var_ , var=&res , mu=0 , sigma=1 , pointlabel=&pointlabel , gout=&gout ,
						name="qqplot" , description="Q-Q plot of Residuals - %upcase(&var)");
			%end;
			%if &histogram %then %do;
				%DefineSymbols(log=0);
				title "Distribution of Residuals for %upcase(&_var_)" justify=center "(Observed Probability MINUS Estimated Probability)";
				proc univariate data=&out_name._&_var_ noprint gout=&gout;
					var &res;
					histogram &res / normal(mu=0 sigma=1 noprint) midpoints=&axisRes
										 name="hist" description="Histogram of Residuals - %upcase(&var)";	%* name como maximo puede tener 8 letras;
				run;
			%end;
			%if &qqplot and &histogram %then %do;
				%* Title slide;
				%*** DM-2012/07/13: Replaced the use of the YMAX option with the use of &VSIZE macro variable
				%*** (computed at the data step above), since in SAS 9.3 the value of YMAX is not defined by default
				%*** (as no device is defined --which is apparent when running the above data step with the ginit()
				%*** function where a window pops up prompting the user to specify a device name);
%*				goptions nodisplay hsize=0 vsize=%sysevalf( %scan(%sysfunc(getoption(ymax)), 1 ,' ') * (100-90)/100 * 1.2 );
				goptions nodisplay hsize=0 vsize=%sysevalf( &vsize * (100-90)/100 * 1.2 );
					%** El valor usado para vsize= esta sacado de la macro %Mplot cuando genero el slide con el title.
					%** Lo que estoy diciendo es que el tamanho vertical de la slide que contiene el titulo sea el 
					%** 10%*1.2 de la altura total disponible en el graphics output area (es decir (100 - 90)/100,
					%** donde 90 es la altura de los boxes donde muestro el Q-Q plot y el histograma, definida con
					%** las opciones uly y ury del tdef del greplay de abajo).
					%** Ymax es una graphic variable que corresponde al valor maximo vertical del graphics output area;
				proc gslide gout=_tempcat_ name="title";
					title justify=center height=30 pct &title;		%* height=30 pct fue copiado de %Mplot cuando hago el gslide;
				run;
				quit;
				goptions display hsize=0 vsize=0;	%*** hsize=0 and vsize=0 resets the values of hsize and vsize;
				proc greplay nofs igout=_tempcat_ tc=sashelp.templt;
					template u1d2;					%* Template con un box arriba y dos boxes abajo;
					tdef u1d2 des="Normal Q-Q plot and Histogram of Residuals"
								1 / lly=90 lry=90
								2 / uly=90 ury=90
								3 / uly=90 ury=90;	%* Se modifica la altura de los paneles a 90 en lugar de 100;
					treplay 1:title 2:qqplot 3:hist;
					delete title qqplot hist;		%* Borro las entries correspondientes al Q-Q plot y al histograma;
					tdef u1d2 des="1 BOX UP, 2 BOXES DOWN"
								1 / lly=50 lry=50
								2 / uly=100 ury=100
								3 / uly=100 ury=100;%* Reset de las propiedades del panel;
				run;
				quit;
				%* Borro el catalogo temporario _tempcat_ creado antes para almacenar el Q-Q plot y el histograma;
				proc datasets lib=work memtype=catalog nolist;
					delete _tempcat_;
				quit;
			%end;

	/*		%if &pointlabels %then symbol1 pointlabel=none;; */
			%DefineSymbols(log=0);
			footnote;
			title;
			quit;
		%end;		%* %if &plot;

		%* Ejecutando las opciones que vengan con &out;
		%if %quote(&out_options) ~= %then %do;
			data &out_name._&_var_(&out_options);
				set &out_name._&_var_;
			run;
		%end;
		%* Borrando el output dataset si no se quiere output dataset;
		%if %upcase(&out_name) = _ %then %do;
			proc datasets nolist;
				delete &out_name._&_var_;
			quit;
		%end;
	%end;	%* %do i = 1 %to &nro_vars;

	%if %quote(&outCat) ~= %then %do;
		data &outCat;		%* Aqui se ejecutan todas las opciones que vengan con &outCat;
			set _TestLogisticFit_cat_(drop=_resp_num_);	%* La variable _resp_num_ es creada al principio del for loop;
		run;
		%if &log %then %do;
			%put TESTLOGISTICFIT: Output dataset %upcase(%scan(&outCat , 1 , '(')) with categorized variables:;
			%put TESTLOGISTICFIT: (%MakeList(%upcase(&var) , sep=%quote( , )));
			%put TESTLOGISTICFIT: created.;
		%end;
	%end;
/*
	proc datasets nolist;
		delete 	_TestLogisticFit_cat_
				_TestLogisticFit_data_
				_TestLogisticFit_event_sum_
				_TestLogisticFit_anno_logit_
				_TestLogisticFit_anno_res_;
	quit;
*/
%end;	%* %if ~&error;

%if &log %then %do;
	%put;
	%put TESTLOGISTICFIT: Macro ends;
	%put;
%end;

%ResetSASOptions;
%end;	%* Check required parameters;
%MEND TestLogisticFit;

