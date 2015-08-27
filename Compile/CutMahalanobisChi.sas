/* MACRO %CutMahalanobisChi
Version: 1.06
Author: Santiago Laplagne - Daniel Mastropietro
Created: 17-Dec-02
Modified: 28-Jul-04

DESCRIPTION:
Poda un conjunto de datos multivariados, eliminando los elementos alejados 
según la distancia de Mahalanobis.

Calcula el centro del conjunto tomando el promedio de cada coordenada y la 
matriz de covarianza.
Con esos datos, llama a la macro %Mahalanobis para calcular las distancias 
al centro y elimina a todos los registros cuya distancia sea grande.
Suponiendo que los datos tienen distribucion normal, se deduce que la 
distancia Mahalanobis tiene distribucion ChiCuadrado. La macro
elimina todas las distancias mayores al cuantil pedido de la distribucion
ChiCuadrado.

USAGE:
%CutMahalanobisChi(
	data ,				 *** Input dataset
	out= ,				 *** Output dataset
	var=_numeric_ ,		 *** Variables a transformar
	by= ,				 *** By variables
	id= ,				 *** Nombre de la variable que identifica las obs. en los gráficos
	outAll= , 			 *** Output dataset con todas las observaciones
	center= ,			 *** Input dataset con el centroide para los cálculos, Mu
	cov= ,				 *** Input dataset con la matriz de covarianza para los cálculos, S
	nameOutlier=outlier, *** Nombre de la variable que define si es outlier  
	nameDistance=mahalanobisDistance *** Nombre para las distancias de Mahalanobis
	alpha=0.05,			 *** Nivel deseado para decidir si es outlier
	adjust=1,			 *** Si se desea o no ajustar alpha por el nro. de obs.
	plot=0,				 *** Mostrar gráfico de outliers detectados?
	log=1);				 *** Mostrar mensajes en el Log?

REQUESTED PARAMETERS:
- data:			Input dataset con los datos a utilizar. Puede recibir
				cualquier opción adicional como en cualquier opción
				data= de SAS.

OPTIONAL PARAMETERS:
- out:			Output dataset. En este data set se guardan las observaciones 
				del	input dataset que quedan después de la poda (eliminación
				de outliers) y se agrega una columna con las distancias de
				Mahalanobis.
				Las observaciones con valores missing en alguna de las variables
				listadas en 'var' no se incluyen en este dataset porque se
				desconoce si son o no outliers.
				Si no se indica ningún dataset, el resultado es mostrado en
				el Output Window.

- var:			Lista de las variables a utilizar en la detección de outliers,
				separadas por espacios.
				La distancia de Mahalanobis se calcula sobre estas variables.
				default: _numeric_, es decir, todas las variables numéricas

- by:			Lista de by variables. La detección de outliers se realiza
				para cada combinación de los valores de las by variables.
				Puede usarse este parámetro para indicar variables que definen
				distintos segmentos.
				(No es necesario ordenar el input dataset por estas variables
				porque la macro lo hace automáticamente.)

- id:			Nombre de la variable usada como índice en el gráfico de las
				distancias de Mahalanobis, en caso de que dicho gráfico sea
				requerido con el parámetro plot=1.

- outAll:		Output dataset donde se guardan todas las variables del dataset
				original con una nueva columna que indica si la observacion es
				o no considerada outlier. El nombre de dicha columna se
				determina con el parámetro nameOutlier.
				Si no se ingresa este parámetro, el dataset no se genera.

- center:		Input dataset con el vector del centroide, Mu, a utilizar en
				el cálculo de la distancia de Mahalanobis.

- cov:			Input dataset con la matriz de forma, S, a utilizar en
				el cálculo de la distancia de Mahalanobis.
				Si este parámetro no se pasa, la matriz S se calcula como
				la matriz de covarianza de los datos.

- nameOutlier:	Nombre de la columna con el indicador de outlier/no-outlier en
				el dataset indicado por el parámetro 'outAll'.
				Valores que toma la variable:
				0 => No outlier
				1 => Outlier
				default: outlier

- nameDistance:	Nombre de la columna con las distancias de Mahalanobis.
				Esta columna se agrega a los output datasets indicados por
				los parámetros 'out' y 'outAll'.
				default: mahalanobisDistance

- alpha:		Parámetro que determina el cuantil de la distribución 
				ChiCuadrado a usar para fijar el corte entre outlier y no
				outlier.
				Si el valor del parámetro 'adjust' es 1 (default),
				se ajusta este valor segun la transformacion
				alpha_adj = 1 - (1 - alpha)^1/n, donde n es el número de
				observaciones. De lo contrario alpha_adj = alpha.
				Dado el valor de alpha ajustado, el corte a usar
				para la distancia de mahalanobis para decidir si una observación
				es o no outlier es el cuantil (1 - alpha_adj) de la distribución
				ChiCuadrado con p grados de libertad, donde p es el	número de
				variables listadas en el parámetro 'var'.
				El ajuste que aquí se hace es un ajuste para tener en cuenta el
				número de tests que se hacen sobre el mismo conjunto de datos,
				y es válido si dichos tests son independientes (suposicion razonable
				si los datos provienen de una muestra aleatoria).
				Mientras más chico sea alpha, menos observaciones serán eliminadas.
				default: 0.05

- adjust:		Indica si se desea ajustar el nivel alpha por el nro. de
				observaciones, para disminuir las chances de detectar un
				outlier simplemente por casualidad.
				El ajuste efectuado supone independencia entre las observaciones
				lo cual es cierto si los datos provienen de una muestra
				aleatoria.
				Valores posibles: 0 => No ajustar, 1 => Ajustar.
				default: 1

- plot:			Indica si se desea ver los puntos detectados como outliers,
				en scatter plots de a pares de las variables utilizadas en la
				detección (para esto se utiliza la macro %Scatter).
				Valores posibles: 0 => No, 1 => Sí.
				default: 0

- log:			Indica si se desea que la macro imprima comentarios en el log.
				Valores posibles: 0 => No, 1 => Sí.
				default: 1

NOTES:
1.- --- Supuestos sobre la distribución de la que provienen los datos ---
Este algoritmo supone que los datos provienen de una distribución normal
multivariada. Si esta condición no se cumple, el algoritmo funciona de
todas formas, pero los resultados pueden no ser apropiados. En ese caso
se recomienda hacer alguna transformación previa de los datos antes de
llamar a esta función. Por ejemplo, puede transformarse cada variable de
interés utilizando la macro %Boxcox.

2.- --- Tratamiento de valores missing ---
Las observaciones que presentan valor missing en al menos una de las variables listadas
en el parámetro 'var', sobre las que se basa la detección de outliers, no son clasificadas
como outlier/no-outlier: tanto la distancia de Mahalanobis como la variable que contiene la
clasificación en outlier/no-outlier (cuyo nombre es el indicado en 'nameOutlier') toman
valor missing en dicho caso.
Estas observaciones no aparecen en el dataset indicado en el parámetro 'out' que es el
que contiene las observaciones que NO son detectadas como outlier. 

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Callmacro
- %DefineSymbols
- %Drop
- %ExistOption
- %Getnobs
- %GetNroElements
- %GetStat
- %GetVarList
- %GetVarOrder
- %Mahalanobis
- %CreateGroupVar
- %ResetSASOptions
- %Scatter
- %SetSASOptions

SEE ALSO:
- %Boxcox
- %Mahalanobis
- %GraphXY
- %Scatter
*/

&rsubmit; 
%MACRO CutMahalanobisChi(data,
						 out=,
						 var=_numeric_,
						 by=,
						 id=,
						 outAll=,
						 center=,
						 cov=,
						 nameOutlier=outlier,
						 nameDistance=mahalanobisDistance,
						 alpha=0.05,
						 adjust=1,
						 plot=0,
						 log=1) / store des="Outlier detection using Mahalanobis distance";
%local i alpha_adj perc threshold size;
%local nvar nobsCluster nNotOutliers nOutliers nObsTotal nUnknown temp;
%local data_name idLabel out_name varOrder;
%local error;		%* Used to check if there is an error when calling %Mahalanobis;
%local maxNPointsForScatter maxNVarForScatter nolabels novalues;	%* Variables used in the call to %Scatter;

%*Setting nonotes options and getting current options settings;
%SetSASOptions;

%* Settings constants;
%let maxNPointsForScatter = 50000;	%* Maximum number of points to allow generation of scatter plots;
%let maxNVarForScatter = 9; 		%* Maximum number of variables to allow generation of scatter plots;

%if &log %then %do;
	%put;
	%put CUTMAHALANOBISCHI: Macro starts;
	%put;
%end;

%*** Borro el dataset _CutMahalanobisChi_all_ en caso de que exista para que ande el
%*** PROC APPEND que lo crea;
proc datasets nolist;
	delete _CutMahalanobisChi_all_;
quit;

/*------------------------------- Parse input parameters ------------------------------------*/
%*** Guardo el orden de las variables en el input dataset para poder generar
%*** un dataset de salida con el mismo orden de las variables;
%GetVarOrder(&data , varOrder);

/* Copia del input dataset a un dataset interno con el fin de:
1.- Ordenar (con un FORMAT) las variables de analisis en el orden en que fueron pasadas por
el usuario.
(Si bien esto no es del todo necesario pues el reordenamiento es hecho en la macro
%Mahalanobis de todas formas para asegurarse de que el calculo de las distancias son
correctas, es hecho de todas formas por completitud. Para mayor informacion de por que
es necesario reordenar las variables, ver las notas en la macro %Mahalanobis.)

2.- Generar un numero de observacion interno con el fin de:
(a) Re-ordenar las observaciones en el output dataset como venian ordenadas en el input
	dataset en caso de que haya BY variables.
(b) Ser usado usado como ID para hacer el grafico de la distancia de Mahalanobis en caso
 	de que el usuario no pase ningun valor en el parametro ID=.
*/
data _CutMahalanobisChi_data_;
	format &id &var;	%* Reordenamiento de las variables &var en el input dataset;
	set &data;			%* Aqui se ejecutan todas las opciones que vengan con &data;
	_cmc_obs_ = _N_;
run;

%* VAR= option;
%* Genero la lista de variables separadas por espacios en blanco, para poder contarlas y
%* poder usarlas en %any. Esto se hace para contemplar el caso en que el valor de var=
%* sea cosas como _NUMERIC_, o como x1-x4, etc.
%* Notar que esto lo hago despues de leer el input dataset en un dataset interno para evitar
%* problemas de incompatibilidad entre las opciones que vienen en &data y la lista de variables
%* listadas en VAR=, lo cual podria llegar a ocurrir unicamente cuando hay opciones KEEP= o
%* DROP= en las opciones de &data; 
%let var = %GetVarList(_CutMahalanobisChi_data_, var=&var, log=0);
%* Information;
%if &log %then %do;
	%put;
	%put CUTMAHALANOBISCHI: Variables used in the the detection of outliers:;
	%put CUTMAHALANOBISCHI: %upcase(&var);
%end;

%* BY= option;
%if %quote(&by) ~= %then %do;
	%* Por las dudas borro la variable _cmc_code_ del input dataset en caso de existir, porque
	%* la creacion de una variable con el mismo nombre podria generar valores erroneos;
	%drop(_CutMahalanobisChi_data_, _GROUP_);
	%* Creo una grouping variable (_cmc_code_) para identificar cada grupo dado por las by variables
	%* Notar que los missing values de &by son considerados como un grupo distinto (lo cual es deseable);
	%CreateGroupVar(_CutMahalanobisChi_data_, by=&by , name=_GROUP_ , log=0);
	%* If there is more than one by variable listed show the by variable combination for each
	%* group in the output window (only if log=1); 
	%if &log and %GetNroElements(&by) > 1 %then %do;
		proc freq data=_CutMahalanobisChi_data_ noprint;
			tables _GROUP_ * %MakeList(&by, sep=*) / out=_CutMahalanobisChi_freq_ listing missing;
		run;
		title2 "Group Mapping";
		proc print data=_CutMahalanobisChi_freq_ noobs;
			var _GROUP_ &by;
		run;
		title2;
	%end;
%end;
%else %do;
	%* Agrego la variable _cmc_code_ = 1 para todas las observaciones, para indicar que todas
	%* pertenecen a un mismo grupo de analisis;
	data _CutMahalanobisChi_data_;
		set _CutMahalanobisChi_data_;
		_GROUP_ = 1;
	run;
%end;

%* ID= option;
%if %quote(&id) ~= %then
	%let idLabel = &id;
%else %do;
	%let id = _cmc_obs_;		%* Internal observation number;
	%let idLabel = observation number;
%end;

%* Number of variables and observations in the dataset where the Mahalanobis distances are computed;
%let nvar = %GetNroElements(&var);
%callmacro(getnobs , _CutMahalanobisChi_data_ return=1 , nObsTotal);
/*-------------------------------------------------------------------------------------------*/

%* Outlier detection by BY variable combination (i.e. by _cmc_code_);
%let i = 0;
%let size = 0;
%do %until (&size = &nObsTotal);
	%let i = %eval(&i + 1);
	data _CutMahalanobisChi_cluster_;
		set _CutMahalanobisChi_data_ end=lastobs;
		where _GROUP_ = &i;
		%if &log and %quote(&by) ~= %then %do;
			if lastobs then
				%if %GetNroElements(&by) = 1 %then %do;
					put "CUTMAHALANOBISCHI: group &i ( &by = " &by ")";
				%end;
				%else %do;
					put "CUTMAHALANOBISCHI: group &i";
				%end;
		%end;
	run;

	%callmacro(getnobs , _CutMahalanobisChi_cluster_ return=1 , nobsCluster);
	%let size = %eval(&size + &nobsCluster);

	%Mahalanobis(_CutMahalanobisChi_cluster_, out=_CutMahalanobisChi_out_, var=&var, id=&id,
				center=&center, cov=&cov, nameDistance=&nameDistance, log=0, checkError=error);

	%*** Verificacion de que el alpha este entre 0 y 1;
	%if %sysevalf(&alpha < 0 or &alpha > 1) %then %do;
		%put CUTMAHALANOBISCHI: WARNING - The alpha level specified is not valid. Using the default (0.05)...;
		%let alpha = 0.05;
	%end;

	%*** Ajuste del alpha por el numero de observaciones si es requerido;
	%if &adjust %then %do;
			%* Bonferroni adjustment;
	%*	%let alpha_adj = %sysevalf(&alpha / &nobsCluster);
	%*	%let perc = %sysevalf (1 - &alpha_adj);
			%* Adjustment assuming independence;
		%let alpha_adj = %sysevalf(1 - (1 - &alpha)**(1/&nobsCluster));
	%end;
	%else
		%let alpha_adj = &alpha;
		
	%let perc = %sysevalf(1 - &alpha_adj);	
	%let threshold = %sysfunc( sqrt( %sysfunc(cinv(&perc, %eval(&nvar)))) );

	%* Show a message that the detection process is in progress, but only if there was no error
	%* in the call to macro %Mahalanobis, because otherwise, this is not done;
	%if ~&error and &log %then
		%put CUTMAHALANOBISCHI: Detecting outliers (Mahalanobis Distance Threshold = %sysfunc(trim(%sysfunc(left(%sysfunc(round(&threshold,0.001))))))).;
	%* Create the output dataset with the outlier detection for the current cluster;
	data _CutMahalanobisChi_out_;
		set _CutMahalanobisChi_out_;
		retain threshold &threshold;
		alpha = &alpha;
		alpha_adj = &alpha_adj;
		if &nameDistance ~= . then
			if &nameDistance < &threshold then
				&nameOutlier = 0;
			else
				&nameOutlier = 1;
		else
			&nameOutlier = .;
		label 	alpha = "Alpha Level"
				alpha_adj = "Adjusted Alpha Level";
	run;
	proc append base=_CutMahalanobisChi_all_ data=_CutMahalanobisChi_out_;
	run;
%end;

%* Output datasets and printed output;
%* Recuperando el orden original del input dataset en caso de que haya un BY statement;
%if %quote(&by) ~= %then %do;
	proc sort data=_CutMahalanobisChi_all_ out=_CutMahalanobisChi_all_;
		by _cmc_obs_;
	run;
%end;

%if %quote(&outAll) ~= %then %do;
	data &outAll;
		format &varOrder;
		set _CutMahalanobisChi_all_(drop=_cmc_obs_ _GROUP_);
	run;
	%if &log %then
		%put CUTMAHALANOBISCHI: Output dataset %upcase(%scan(&outAll, 1, '(')) created.;
%end;

%if %quote(&out) ~= %then %do;
	data &out;
		format &varOrder;
    	set _CutMahalanobisChi_all_(drop=_cmc_obs_ _GROUP_ threshold);
		where &nameOutlier = 0;
		drop &nameOutlier;
	run;
	%if &log %then
		%put CUTMAHALANOBISCHI: Output dataset %upcase(%scan(&out, 1, '(')) created.;
%end;

%* Imprimiendo el dataset con todas las observaciones y con la informacion de si fueron
%* detectadas como outliers;
%if %quote(&out) = and %quote(&outAll) = %then %do;
	proc print data=_CutMahalanobisChi_all_(drop=_cmc_obs_ _GROUP_);
	run;
%end;

%* Mensaje con el numero y porcentaje de outliers detectados;
%if &log %then %do;
	proc freq data=_CutMahalanobisChi_all_ noprint;
		tables &nameOutlier / out=_CutMahalanobisChi_outliers_; 
	run;
	%* Count number of observations processed;
	%GetStat(_CutMahalanobisChi_outliers_, var=count, stat=sum, macrovar=_nObsProcessed_, log=0);
	%* Inicializacion por si todos son outliers o ninguno es outlier;
	%let nOutliers = 0;
	%let nNotOutliers = 0;
	%let nUnknown = 0;
	data _NULL_;
		set _CutMahalanobisChi_outliers_;
		if &nameOutlier = 0 then
			call symput ('nNotOutliers' , count);
		else if &nameOutlier = 1 then
			call symput ('nOutliers', count);
		else if &nameOutlier = . then
			call symput ('nUnknown', count);
	run;
	%put;
	%put CUTMAHALANOBISCHI: Variables used in the detection of outliers based on the Mahalanobis distance:;
	%put CUTMAHALANOBISCHI: %upcase(&var);
	%put CUTMAHALANOBISCHI: Total number of observations processed: &_nObsProcessed_;
	%put CUTMAHALANOBISCHI: Total number of outliers: %eval(&nOutliers) (%sysfunc(round(%sysevalf ((&nOutliers)/&_nObsProcessed_*100) , 0.01))%);
	%put CUTMAHALANOBISCHI: Total number of unclassified observations: %eval(&nUnknown) (%sysfunc(round(%sysevalf ((&nUnknown)/&_nObsProcessed_*100) , 0.01))%);
	%symdel _nObsProcessed_;	%* _nObsProcessed_ devuelta por %GetStat es global variable;
	quit;	%* Para que el %symdel no cause problemas;
%end;

%* Grafico de los outliers detectados y de las distancias de Mahalanobis by obs. number;
%* (solamente si el parametro by es vacio, porque si no se complica muchisimo);
%if &plot %then %do;
	%if %quote(&by) = %then %do;
		%DefineSymbols;
		symbol2 value=square;
		%* Scatter plots (note that the number of points to be plotted (nvar*(navr-1)/2*nobs)
		%* is limited to 10000;
		%let nolabels = 0;
		%let novalues = 0;
		%* Do not show values and labels when the number of variables to plot is too large;
		%if &nvar > 4 %then %do;
			%let nolabels = 1;
			%let novalues = 1;
		%end;
		%if &nvar > 1 and &nvar <= &maxNVarForScatter and %eval(&nvar*(&nvar-1)/2*&nObsTotal) <= &maxNPointsForScatter %then %do;
			%Scatter(_CutMahalanobisChi_all_(where=(&nameOutlier~=.)) , var=&var , strata=&nameOutlier , 
					 nolabels=&nolabels, novalues=&novalues, 
					 title="Outliers detected by CUTMAHALANOBISCHI" justify=center "based on variables: %upcase(&var)");
		%end;
		%else %if &nvar = 1 %then %do;
			axis1 label=("&idLabel");
			title "Outliers detected by CUTMAHALANOBISCHI" justify=center "based on variable: %upcase(&var)";
			proc gplot data=_CutMahalanobisChi_all_(where=(&nameOutlier~=.));
				plot &var*&id=&nameOutlier / haxis=axis1;
			run;
			quit;
			title;
			axis1;
		%end;
		%else %if &log %then %do;
			%put;
			%put CUTMAHALANOBISCHI: NOTE - Scatter plots are not shown because either the nro. of variables;
			%put CUTMAHALANOBISCHI: is more than &maxNVarForScatter or the nro. of points to be plotted is larger than &maxNPointsForScatter..;
		%end;

		%* Distancias de Mahalanobis vs. ID;
		axis1 label=("&idLabel");
		title "Mahalanobis distances by &idLabel" justify=center
			  "(Green line is Mahalanobis threshold = %sysfunc(round(&threshold,0.001)))";
		%* Calculo el valor maximo de la distancia de Mahalanobis, por si el valor del threshold es
		%* mayor que el, con lo que corre el riesgo de no aparecer en el grafico si no hago algo al respecto;
		%GetStat(_CutMahalanobisChi_all_ , var=&nameDistance , stat=max , name=_max_ , log=0);
		axis2 label=(angle=90);
		%if %sysevalf(&threshold > &_max_) %then %do;
			%let step = %sysevalf(&threshold/5);
			axis2 order=(0 to &threshold by &step) label=(angle=90);	%* The label= option needs to be set again;
		%end;
		proc gplot data=_CutMahalanobisChi_all_(where=(&nameOutlier~=.));
			plot &nameDistance*&id=&nameOutlier / haxis=axis1 vaxis=axis2 vref=&threshold cvref=Green;
		run;
		quit;
		title;
		axis1;
		%DefineSymbols;
		%symdel _max_;		%* _max_ devuelta por %GetStat es global variable;
		quit;	%* Para que el %symdel no cause problemas;
	%end;
%end;	%* %if &plot;


proc datasets nolist;
	delete	_CutMahalanobisChi_all_
			_CutMahalanobisChi_cluster_
			_CutMahalanobisChi_data_
			_CutMahalanobisChi_freq_
			_CutMahalanobisChi_out_
			_CutMahalanobisChi_outliers_;
quit;

%if &log %then %do;
	%put;
	%put CUTMAHALANOBISCHI: Macro ends;
	%put;
%end;

%ResetSASOptions;
%MEND CutMahalanobisChi;
