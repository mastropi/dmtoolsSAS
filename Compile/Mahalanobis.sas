/* MACRO %Mahalanobis
Version: 	1.04
Author: 	Santiago Laplagne - Daniel Mastropietro
Created: 	02-Dec-2002
Modified: 	28-Nov-2017 (previous: 12-Aug-2011, 28-Jul-2004)

DESCRIPTION:
Calcula la distancia de Mahalanobis para todos los puntos de un dataset
de un conjunto de variables especificado.
Si el conjunto de variables es pensado como un vector X (de dimension p),
la distancia de Mahalanobis se calcula como:
	M = (X - Mu)' S^(-1) (X - Mu),
donde Mu es un vector de dimension p, que da el centroide de los datos
y S una matriz de forma de tamaño p*p con información sobre la estructura
de los datos. Por default Mu se calcula como el vector de medias de los
datos y S como la matriz de covarianza.
Es posible especificar tanto el vector Mu como la matriz de covarianza S
a usar en el calculo de la distancia de Mahalanobis, que son leidas de
sendos datasets.

USAGE:
%Mahalanobis(
	data ,				*** Input dataset
	out= ,				*** Output dataset
	var=_NUMERIC_ ,		*** Variables a transformar
	id= ,				*** Nombre de la variable que identifica las obs. en los gráficos
	center= ,			*** Input dataset con el centroide, Mu
	cov= ,				*** Input dataset con la matriz de covarianza, S
	method=mean ,		*** Metodo usado para calcular el centroide, Mu
	outDistance= ,		*** Output dataset con los valores de M
	nameDistance=mahalanobisDistance , *** Nombre de la var c/los valores de M
	threshold= ,		*** Umbral a mostrar en el gráfico de las dist de Mahalanobis
	plot=0 ,			*** Mostrar graficos con las distancias de Mahalanobis?
	log=1);				*** Mostrar mensajes en el Log?

REQUESTED PARAMETERS:
- data:			Input dataset con los datos a utilizar. Puede recibir cualquier 
				opción adicional como en cualquier opción data= de SAS.

OPTIONAL PARAMETERS:
- out:			Output dataset. Este dataset coincide con el input dataset
				al que se le agrega una columna con la distancia de
				Mahalanobis, M, calculada a partir de las variables listadas
				en el parámetro 'var'. El nombre de esta columna es el
				indicado por el parámetro 'nameDistance', cuyo valor default es
				'mahalanobisDistance'.

- var:			Lista de las variables a utilizar para calcular la distancia
				de Mahalanobis, separadas por espacios.
				default: _numeric_, es decir todas las variables numéricas

- id:			Nombre de la variable usada como índice para graficar las
				distancias de Mahalanobis, en caso de que dicho gráfico sea
				requerido con el parámetro plot=1.
				Esta variable debe existir en el input dataset, pero no tiene
				por qué tener valores únicos (es decir sus valores pueden
				repetirse).
				La variable es guardada en el dataset especificado en
				outDistance junto con las distancias de Mahalanobis.

- center:		Input dataset con el vector del centroide, Mu, a utilizar en
				el cálculo de la distancia de Mahalanobis. (El nombre de
				la variable no es relevante.)

- cov:			Input dataset con la matriz de forma, S, a utilizar en
				el cálculo de la distancia de Mahalanobis. (Los nombres
				de las variables o columnas no son relevantes.)
				Si este parámetro no se pasa, la matriz S se calcula como
				la matriz de covarianza de los datos.

- method:		Método utilizado para el cálculo del centroide, Mu, en caso
				de que no se pase el parámetro 'center'.
				Por el momento el único valor posible es 'mean', que indica
				que 'Mu' se calcule como la media de los datos.
				default: mean

- outDistance:	Output dataset donde se guardan (únicamente) los valores de la
				distancia de Mahalanobis para cada punto.

- nameDistance:	Nombre de la columna con las distancias de Mahalanobis. Esta
				columna es generada tanto en el output dataset indicado en
				'outDistance', como en el output dataset especificado por el
				parámetro 'out'.
				default: mahalanobisDistance

- threshold:	Valor a mostrar con una línea horizontal en el gráfico de las
				distancias de Mahalanobis. Es útil para visualizar el umbral
				o valor de corte que se usaría para decidir si una observación
				es o no outlier.
				Si su valor no es asignado, no se muestra ninguna línea horizontal.

- plot:			Indica si se desea ver un gráfico con las distancias de
				Mahalanobis, para cada valor de la variable especificada en
				'id'. Si no se especifica ninguna variable en 'id', las
				distancias de Mahalanobis se grafican en el orden en que
				aparecen las observaciones en el input dataset.
				Valores posibles: 0 => No, 1 => Sí.
				default: 0

- log:			Indica si se desea ver mensajes en el log generados por la macro.
				Valores posibles: 0 => No, 1 => Sí.
				default: 1

NOTES:
1.- --- Distribución de la distancia de Mahalanobis ---
Para el caso en que los datos para los cuales se calcula la distancia de Mahalanobis
provienen de una distribución normal multivariada, entonces:
(a) Si tanto el centroide como la matriz de covarianza son cantidades provistas en
	forma externa (a los datos para los que se calcula la distancia de Mahalanobis),
	la distancia de Mahalanobis tiene distribución Chi2(p) (Chi-cuadrado con p grados de
	libertad).
(b) Si el centroide y/o la matriz de covarianza son calculados en forma interna
	(es decir estimados a partir de los datos para los que se calcula la distancia de
	Mahalanobis), la distancia de Mahalanobis tiene *aproximadamente* distribución
	Chi2(p) (Chi-cuadrado con p grados de libertad), y tanto más se aproxima a ella
	cuanto más grande es el número de observaciones para las que se calcula la distancia.

2.- --- Tratamiento de valores missing ---
Las observaciones que presentan valor missing en al menos una de las variables de análisis
pasadas en el parámetro var= son eliminadas del cálculo del centroide y de la matriz de
covarianza (en caso de que éstos fueran calculados a partir de los datos), pero permanecen
en el output dataset, donde la distancia de Mahalanobis aparece con valor missing.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Any
- %Cov
- %DefineSymbols
- %Drop
- %ExistOption
- %GetDataOptions
- %GetVarOrder
- %GetVarList
- %Means
- %ResetSASOptions
- %SetSASOptions
- Mahalanobis (IML Module)

SEE ALSO:
- %CutMahalanobisChi
- %BoxCox
- %Hadi

EXAMPLES:
1.- %Mahalanobis(A(where=(x>0)) , out=A_maha , var=x y ,
				 center=Mu , cov=S , nameDistance=dist , plot=1);
Calcula la distancia de Mahalanobis basada en las variables X e Y del dataset A para cada
observacion en que la variable X > 0.
El vector centroide se lee del dataset MU supuesto con 2 observaciones y una variable.
(El nombre de la variable puede ser cualquiera.)
La matriz de covarianza se lee del dataset S supuesto con 2 observaciones y 2 variables.
(Los nombres de las variables pueden ser cualesquiera.)
Las distancias de Mahalanobis calculadas se guardan en el dataset A_MAHA en la columna
llamada DIST. 
La opción PLOT=1 pide efectuar el gráfico de las distancias de Mahalanobis indizadas por
número de observación.

2.- %Mahalanobis(A , out=A_maha(keep=idvar x y mahalanobisDistance) , var=x y , id=idvar, plot=1);
Calcula la distancia de Mahalanobis basada en las variables X e Y para todas las observaciones
del dataset A.
Las distancias de Mahalanobis calculadas se guardan en el dataset A_MAHA en la columna
llamada MAHALANOBISDISTANCE. En este dataset se conservan solamente las variables IDVAR, X, Y y
MAHALANOBISDISTANCE.
La variable IDVAR (no tiene por qué tener valores únicos) se utiliza para indizar el gráfico
de las distancias de Mahalanobis solicitado por el parámetro PLOT=1.
*/
&rsubmit;
%MACRO Mahalanobis (data, out=, var=_numeric_, id= , center=, cov=, method=mean, outDistance= , 
					nameDistance=mahalanobisDistance , threshold= , plot=0 , log=1, checkError=error)
		/ store des="Computes the Mahalanobis distance of a set of continuous variables";
		%** Parameter checkError stores the value of variable _error_ that says whether an error occurred;
%local _IMLLabModelos_;
%let _IMLLabModelos_ = sasuser.IMLLabModelos;	/* Ubicacion de los modulos IML utilizados en la macro */

%* Underscores are used because parameter checkError= is the name of a macro variable that is created
%* at the end of the macro so that its value can be checked from the calling program;
%local _error_ _nobs_;
%local _id_ _idLabel_ _out_ _out_name_ _outDistance_name_ _var_ _varOrder_;

%*Setting nonotes options and getting current options settings;
%SetSASOptions;

%if &log %then %do;
	%put;
	%put MAHALANOBIS: Macro starts;
	%put;
%end;

/*----------------------------- Parsing input parameters --------------------------------*/
%* ID= option;
%* Note the distinction between &id and &_id_. The first one is the parameter passed to
%* the macro and it is not changed. The second one is the value defined and used internally.
%* This is necessary because it is needed to distinguish between the parameter and the
%* value used for ID;
%if %quote(&id) ~= %then %do;
	%let _id_ = &id;
	%let _idLabel_ = &id;
%end;
%else %do;
	%let _id_ = _OBS_;					%* Internal observation number;
	%let _idLabel_ = observation number;
%end;

%* OUT= option;
%* Note the distinction between &out and &_out_. Same comment as above for ID;
%if %quote(&out) ~= %then %do;
	%let _out_ = &out;
	%let _out_name_ = %scan(&_out_, 1, '(');
%end;
%else %do;
	%let _out_ = _Mahalanobis_out_;
	%let _out_name_ = &_out_;
%end;

%* CENTER= option will be parsed below, when checking if the computational method is valid;
/*-------------------------------------------------------------------------------------------*/

%* Leyendo el orden original de las variables en el input dataset para que quede
%* ese mismo orden al crear el output dataset;
%GetVarOrder(&data , _varOrder_);		%*** Notar que %GetVarOrder puede recibir un &data con opciones;

%* Genero la lista de variables separadas por espacios en blanco, para poder contarlas y
%* poder usarlas en %any. Esto se hace para contemplar el caso en que el valor de var=
%* sea cosas como _NUMERIC_, o como x1-x4, etc.; 
%let _var_ = %GetVarList(&data , var=&var, log=0);

/******************************* IMPORTANT NOTE **********************************************
A continuacion se copia el input dataset a un dataset interno con el fin de hacer las
siguientes operaciones:

1.- Generar un dataset en que el orden en que aparecen las variables VAR= coincida con el
orden en que son listadas por el usuario en dicho parametro. Esto es SUMAMENTE NECESARIO
pues el orden en que aparecen en el dataset es el orden en que las variables son leidas 
en el PROC IML donde se hace el calculo de la distancia de Mahalanobis(*). Este calculo
usa el centroide y la matriz de covarianza calculados por %Means y %Cov respectivamente,
antes de entrar al IML. Estas macros devuelven el centroide y la matriz de covarianza
donde las variables aparecen ordenadas segun estan listadas en el parametro VAR= pasado
por el usuario(**).
De aqui' que los ordenes de las variables en VAR= y en el input dataset leido en IML
deben coincidir para asegurarse que el calculo de la distancia de Mahalanobis sea la
correcta!

(*) Esto es porque la matriz creada en IML con el comando USE respeta el orden en que
las variables aparecen en el dataset leido, independientemente del orden en que las
variables aparecen listadas en la opcion keep=&var alli utilizada.
(**) Notar que si VAR=_NUMERIC_, el FORMAT usado para ordenar las variables tambien anda.
Y en este caso el orden va a estar bien, porque como el usuario no especifica ningun orden
particular de las variables al pasar el parametro VAR=, el orden utilizado en el calculo
del centroide y de la matriz de covarianza va a coincidir con el orden utilizado en IML
para calcular la distancia de Mahalanobis, y el calculo va a estar bien hecho.

2.- Generar una variable con el numero de observacion interno (_OBS_), utilizado para
mergear el input dataset con el dataset que contiene las distancias de Mahalanobis
calculadas, como asi tambien para usarlo como indice en el grafico de las distancias
de Mahalanobis en caso de que ninguna variable ID haya sido indicada por el usuario.

3.- Contar el numero de observaciones que no tienen missing values en ninguna de las
variables listadas en VAR=.
***********************************************************************************************/
data _Mahalanobis_data_;
	format &_var_;				%*** Notar que usar &var o &_var_ es lo mismo aqui;
	set &data end=lastobs;		%*** Aca se ejecutan todas las opciones que vengan con &data;
	retain _nobs_ 0;
	if ~%any(&_var_, =, .) then
		_nobs_ = _nobs_ + 1;	%* Only count the observation if all values in the variables
								%* listed in &_var_ are non missing;
	_OBS_ = _N_;				%* Observation number for future merges;
	if lastobs then
		call symput ('_nobs_', _nobs_);
	drop _nobs_;
run;

/* Checking number of observations and validity of some input parameters */
%let _error_ = 0;		%*** Variable que indicarA si ocurre algun error;
%if &_nobs_ = 0 %then %do;
	%let _error_ = 1;
	%put MAHALANOBIS: ERROR - There are no valid observations to process.;
	%put MAHALANOBIS: The macro MAHALANOBIS will stop executing.;
%end;
%else %if %quote(&center) = %then  %do;		%* if the center will be computed based on the data...;
	%let center = _Mahalanobis_center_;
	%if (%sysfunc(lowcase(&method)) = mean) %then %do;
		%* Calcula el vector de medias, eliminando las observaciones con algun missing value.
		%* NOTAR que es necesario eliminar explicitamente las observaciones que tengan algun
		%* missing value en alguna de las &_var_, porque la macro %Means
		%* --que llama a PROC MEANS-- solo elimina los missing values para CADA VARIABLE por
		%* separado, pero no para las variables tomadas en conjunto, que es lo que se requiere
		%* en este caso. Es decir lo que hay que hacer es eliminar TODA una observacion que
		%* tenga missing value en al menos una de las variables de analisis;
		%Means(_Mahalanobis_data_(where=(~%any(&_var_,=,.))), var=&_var_, stat=mean, out=&center, log=0);
	%end;
	%else %do;
		%let _error_ = 1;
		%put MAHALANOBIS: ERROR - The value of parameter METHOD= is not valid;
		%put MAHALANOBIS: Valid values are: mean.;
		%put MAHALANOBIS: The macro MAHALANOBIS will stop executing.;
	%end;
%end;
%if %quote(&cov) = %then %do;		%* if the covariance matrix will be computed based on the data...;
	%if %sysevalf(&_nobs_ < 2) %then %do;
		%let _error_ = 1;
		%put MAHALANOBIS: ERROR - There are not enough observations to compute the covariance matrix.;
		%put MAHALANOBIS: At least 2 observations are needed.;
		%put MAHALANOBIS: The macro MAHALANOBIS will stop executing.;
	%end;
%end;

%if ~&_error_ %then %do;
	/************************************* MACRO STARTS **************************************/
	%* Covariance matrix;
	%if %quote(&cov) = %then  %do;
		%let cov = _Mahalanobis_cov_;
		%* Calcula la matriz de covarianza de los datos
		%* (%Cov takes care of any missing values in any variable listed in &_var_ since it
		%* uses PROC CORR with the option NOMISS);
		%Cov(_Mahalanobis_data_, out=&cov, var=&_var_);
	%end;

	/*-------------------------------- Mahalanobis Distance ---------------------------------*/
	%* Usa el lenguaje IML para hacer el producto de las matrices de la distancia Mahalanobis;
	proc IML;
		%*** Definicion de modulos utilizados;
		reset storage = &_IMLLabModelos_;
	
		file log;
		%* Lee los data sets como matrices;
		use &center;
			read all into mCenter;
		close &center;
		use &cov;
			read all into mCov;
		close &cov;
		
		%* Read the observation number and the data ONLY when there is non missing data.
		%* Note that _OBS_ needs to be read together with &_var_ because there may be
		%* some missing values for some &_var_ and those observations need to be
		%* removed from the vector _OBS_ that is created below;
		use _Mahalanobis_data_(where=(~%any(&_var_,=,.)) keep=_OBS_ &_var_);
			read all into mData[colname=names];
		close _Mahalanobis_data_;

		%* Se copia en el vector _OBS_ la columna de mData con la variable para indizar
		%* las distancias de Mahalanobis mas abajo;
		_OBS_ = mData[,loc(names="_OBS_")];
		%* Se elimina la columna de observacion, porque si no interviene en el calculo de
		%* la distancia de Mahalanobis;
		mData = mData[,loc(names^="_OBS_")];

		%* Distancia de Mahalanobis;
		mMahal = Mahalanobis(mData , mCenter , mCov);
		%* Adding back the observation number;
		mMahal = _OBS_ || mMahal;
		%* Crea el dataset con las distancias de Mahalanobis y el numero de observacion
		%* interno (_OBS_) para luego mergear con el input dataset _Mahalanobis_data_;
		create _Mahalanobis_ 	from mMahal[colname={_OBS_ &nameDistance}];
			append from mMahal;
		close _Mahalanobis_;
	quit;
	/*---------------------------------------------------------------------------------------*/
	
	/*----------------------------------- Output datasets -----------------------------------*/
	%* Crea el output dataset agregando las distancias Mahalanobis a las columnas del input dataset;
	proc sort data=_Mahalanobis_data_;
		by _OBS_;
	run;
	proc sort data=_Mahalanobis_;
		by _OBS_;
	run;
	data &_out_;				%* Aqui se ejecutan las data options que vienen con OUT=;
		format &_varOrder_;		%* Restaura el orden original de las variables en el input dataset;
		merge _Mahalanobis_data_ _Mahalanobis_(keep=_OBS_ &nameDistance);
		by _OBS_;		%* Note that observations with some missing values in &_var_ are
						%* included with a missing value in variable &nameDistance;
		%* Drop the internal observation number if an output dataset was requested and no plot
		%* is requested (if a plot was requested _OBS_ may be needed for the plot);
		%if %quote(&out) ~= and ~&plot %then %do; 	drop _OBS_; %end;
		label &nameDistance = "Mahalanobis distance based on &_var_";
	run;
	%* Print the distances in the output window if no output dataset was requested;
	%if %quote(&out) = %then %do;
		title "Mahalanobis distances for %sysfunc(upcase(&_var_))";
		proc print data=&_out_name_(keep=&id &nameDistance);
		run;
		title;
	%end;
	%else %if &log %then
		%put MAHALANOBIS: Output dataset %upcase(&_out_name_) created.;
	
	%* Output dataset con las distancias de Mahalanobis;
	%if %quote(&outDistance) ~= %then %do;
		%let _outDistance_name_ = %scan(&outDistance, 1, '(');
		data &outDistance;
			format &id &nameDistance;
			set &_out_name_;
			keep &id &nameDistance;		%* Guardo la variable ID pasada como parametro;
		run;
		%if &log %then
			%put MAHALANOBIS: Output dataset %upcase(&_outDistance_name_) created.;
	%end;
	/*---------------------------------------------------------------------------------------*/
	
	/*----------------------------------------- Plots ---------------------------------------*/
	%* Grafico de las distancias de Mahalanobis;
	%if &plot %then %do;
		%DefineSymbols(height=0.7);
		title "Mahalanobis distance by &_idLabel_";
		axis1 label=("&_idLabel_");
		axis2 label=(angle=90);
		proc gplot data=&_out_name_(keep=&_id_ &nameDistance);
			plot &nameDistance*&_id_ / haxis=axis1 vaxis=axis2 %if %quote(&threshold) ~= %then %do; vref=&threshold cvref=red %end;;
		run;
		quit;
		title;
		%DefineSymbols;		%* Restaura el tamanho del simbolo;

		%* Drop variable _OBS_. This is needed only when an output dataset was requested and
		%* no ID variable is specified;
		%drop(&_out_name_, _OBS_);
	%end;
	/*---------------------------------------------------------------------------------------*/
%end;	%* %if ~&_error_;
%else %do;		%* Genero los output datasets en caso de que hayan sido solicitados
				%* con valores missing para &nameDistance;
	%* &OUT dataset;
	%if %quote(&out) ~= %then %do;
		data &_out_;
			format &_varOrder_;		%* Restaura el orden original de las variables en el input dataset;
			set _Mahalanobis_data_;
			&nameDistance = .;
			drop _OBS_;
			label &nameDistance = "Mahalanobis distance based on &_var_";
		run;
		%if &log %then 
			%put MAHALANOBIS: Output dataset %upcase(&_out_name_) created.;
	%end;
	%* &OUTDISTANCE dataset;
	%if %quote(&outDistance) ~= %then %do;
		data &outDistance;
			format &id &nameDistance;
			set _Mahalanobis_data_;
			&nameDistance = .;
			label &nameDistance = "Mahalanobis distance based on &_var_";
			keep &id &nameDistance;
		run;
		%if &log %then %do;
			%let _outDistance_name_ = %scan(&outDistance, 1, '(');
			%put MAHALANOBIS: Output dataset %upcase(&_outDistance_name_) created.;
		%end;
	%end;
%end;
	
proc datasets nolist;
	delete 	_Mahalanobis_
			_Mahalanobis_data_
			_Mahalanobis_center_
			_Mahalanobis_cov_
			_Mahalanobis_out_;
quit;

%if &log %then %do;
	%put;
	%put MAHALANOBIS: Macro ends;
	%put;
%end;

%* Storing if there were errors or not, so that this can be checked from the calling program;
%let &checkError = &_error_;
%ResetSASOptions;
%MEND Mahalanobis;

