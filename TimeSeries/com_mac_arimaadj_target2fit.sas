/* com_mac_arimaadj.sas
Version:		V3
Creado:			06/09/06
Modificado:		15/09/06
Autor:			Daniel Mastropietro
Descripcion:	Macro para ajuste de un modelo ARIMA considerando aspectos de:
				- Deteccion de stationarity
				- Deteccion de seasonality
				- Ajuste de varias propuestas de modelos ARIMA por ESACF
				- Eleccion del mejor modelo en base a validacion
				- Generacion de Forecast


PARAMETROS DE ENTRADA
Parametro		Descripcion
===================================================================================================
data,
target
y
varclass
varnum
outforecast
outforecastall
outinfo
outmape
outmapes
outoutliers
outparams
outsummary
sample=Sample
timeid=Fecha
lead
interval
pmax
qmax
period
period_min
period_max
outliers_maxnum
outliers_maxpct
outlierscondition:			Es de la forma ej. where '01dec2005'd <= Fecha <= '30aug2006'd
round
id
case
plot
error=_error_
execID
===================================================================================================


MACROS UTILIZADAS
Nombre				Descripcion												Fuente
===================================================================================================
%Callmacro			Ejecuta una macro que devuelve parametros.				Macros compiladas
%CreateExecutionID	Genera un ID de ejecucion.								com_mac_miscellanea.sas
%CreateInteractions	Calcula interacciones (productos) entre variables. 		Macros compiladas
%DateMonday			Calcula el lunes anterior o siguiente a una fecha.		com_mac_miscellanea.sas
%FreqMult			Genera un dataset con la frecuencia de variables.		Macros compiladas
%Getnobs			Devuelve el nro. de observaciones en un dataset.		Macros compiladas
%GetVarNames		Devuelve la lista de variables en un dataset.			Macros compiladas
%MakeList			Devuelve una lista de nombres generada a partir			Macros compiladas
					de ciertos criterios. 
%MakeListFromVar	Devuelve una lista de nombres generada a partir			Macros compiladas
					de un unico nombre usado como raiz.
%Means				Calcula estadisticos de variables.						Macros compiladas
%RemoveFromList		Elimina un nombre de una lista de nombres.				Macros compiladas
%SelectVar			Selecciona variables de un dataset que contienen		Macros compiladas
					un cierto KEY en el nombre.					
%TimeElapsed		Calcula el tiempo transcurrido entre dos tiempos.		com_mac_miscellanea.sas
===================================================================================================


MODIFICACIONES A LA VERSION BASE
DM = Daniel Mastropietro

Version		Fecha		Autor	Descripcion	
===================================================================================================
V1			08/09/06	DM		- Se agrego el parametro ROUND que indica si el forecast debe
								redondearse al entero mas cercano o no (default: 0).
								- Se modifico la macro %ComputeForecast agregando el parametro ROUND
								que indica si el forecast debe redondearse al entero mas cercano o no.
V2			09/09/06	DM		- Se agrego un check de que el nro. de observaciones en
								data4outliers_best sea > 0 en la seccion de ajuste del mejor modelo
								antes de generar las indicadoras de outliers, porque puede ocurrir
								que el mejor modelo no haya tenido outliers detectados y en ese
								caso truena el proceso si esta siendo ejecutado en el servidor.
								- Se agrego' un %let nobs = 0 antes de cada invocacion a la macro
								%callmacro con getnobs para evitar que el valor de nobs sea el de
								la ultima llamada a %callmacro lo que ocurriria en caso de que la
								nueva llamada a %callmacro diera error.
								- Agregue' la condicion . < probTau < 0.05 a la seccion de analisis
								de estacionariedad porque vi que a veces el p-valor del D-F test
								puede ser missing.
								- Agregue' la inicializacion de las macro variables &nout_add y
								&nout_shift en 0 antes de ajustar el mejor modelo para que estas
								variables no sean consideradas si no hubo ningun outlier detectado
								al ajustar el mejor modelo elegido.
								- Agregue' una verificacion de existencia de los siguientes datasets:
									- com_trend_params
									- com_dftest
									- com_fisher
									- com_spectrum
								ya que podria ocurrir que no se generaran si hubiera un error en el
								PROC ARIMA que los genera.
								- Agregue' el calculo del desvio estandar de las variables VARCLASS
								porque en algunas ejecuciones vi que a pesar de que la variable
								categorica no era eliminada del analisis por el analisis de frecuencias
								luego aparecia el error de que la varianza de la variable categorica
								era menor que 1E-12, y esto era incluso cuando la variable TARGET
								NO era diferenciada (y era la original).
								- (12/09/06) Agregue' el parametro execID para ser agregado a los 
								datasets temporales creados en TEMPDATA, para evitar conflicto
								entre dos procesos que se ejecutan simultaneamente y que llaman
								a esta macro. Esto hizo que tuviera que renombrar el dataset
								DATA4OUTLIERS_BEST por DATA4OUTLIERS porque de lo contrario el nombre
								con el execution ID tipo yyyymmddhhmmss superaba los 32 caracteres.
								Ahora el dataset con mayor longitud tiene justamente 32 caracteres!
V3			15/09/06	DM		- Se agrego' el parametro OUTLIERSCONDITION para que la deteccion
								de outliers solamente se efectue sobre un conjunto de fechas, por ej.
								las mas recientes a la semana a pronosticar.
								- Se paso' a usar TARGET2FIT en el analisis de la SEASONALITY y de
								la deteccion de outliers, porque habia casos en que no se detectaban
								outliers en VALID y que eran cruciales para el pronostico correcto.
		*** ADEMAS SE VOLVIO A AGREGAR LAS VARIABLES &VAR COMO PREDICTORAS EN EL PROCESO DE DETECCION
		*** DE OUTLIERS. PERO ESTO NO PUEDE PRODUCIR FPO??
===================================================================================================
*/

/* 
SUPUESTOS
- Ya esta hecha la separacion en TRAIN, VALID y TEST en el dataset. La muestra es identificada por la variable indicada
en el parametro Sample, la cual se asume que toma los siguientes valores identificatorios (en mayusculas):
	- 1-TRAIN
	- 2-VALID
	- 3-TEST
- La variable indicada en Y= es missing en VALID y TEST.
- No hay huecos de TIMEID= en los datos.

NOTAS
- Se genera la macro variable cuyo nombre se indica en ERROR= (default: _error_) donde se guarda un
indicador de si ocurrio un error en el ajuste del modelo ARIMA y en la generacion del forecast.
La macro variable vale 1 si hubo un error y 0 en caso contrario.
Dicha macro variable debe existir antes de invocar a la macro desde el mundo exterior o debe estar
definida como local si la macro es invocada desde otra macro.
*/
%MACRO ARIMAAdj(data,
				target=,
				y=,
				varclass=,
				varnum=,
				outforecast=,
				outforecastall=,
				outinfo=,
				outmape=,
				outmapes=,
				outoutliers=,
				outparams=,
				outsummary=,
				sample=Sample,		/* Nombre de la variable con las muestras TRAIN, VALID y TEST */
				timeid=Fecha,
				lead=1,				/* Lead del forecast a partir de la primera fecha de TEST */
				interval=1,
				pmax=4,
				qmax=4,
				period=,
				period_min=5,		/* Este valor default es max(pmax, qmax) + 1 */
				period_max=53,		/* 53 es el numero maximo de semanas en un anho */
				outliers_maxnum=5,
				outliers_maxpct=10,
				outlierscondition=,	/* Condicion que debe satisfacerse (sobre la FECHA por ej.) para que la observacion sea considerada en la deteccion de outliers */
				round=0,
				id=,
				case=,
				plot=0,
				error=_error_,
				execID=);

%MACRO ComputeForecast(target=, trend=0, logarithm=0, round=0);
	%if &trend %then %do;
		forecast_dtrend = forecast;
		L95_dtrend = L95;
		U95_dtrend = U95;
		forecast = trend + forecast_dtrend;
		L95 = trend + L95_dtrend;
		U95 = trend + U95_dtrend;
	%end;
	%if &logarithm %then %do;
		forecast_log = forecast;
		L95_log = L95;
		U95_log = U95;
		forecast = max(0, 10**forecast_log - 1);
		L95 = max(0, 10**L95_log - 1);
		U95 = max(0, 10**U95_log - 1);
	%end;
	%else %do;
		forecast = max(0, forecast);
		L95 = max(0, L95);
		U95 = max(0, U95);
	%end;
	%if &round %then %do;
		forecast = round(forecast);
		L95 = round(L95);
		U95 = round(U95);
	%end;

	%* Error relativo (notar que si &target = 0, lo calculo referido al Forecast);
	format error error_abs percent7.1;
	if &target > 0 then
		error = (forecast - &target) / &target;
	else if forecast > 0 then
		error = (forecast - &target) / forecast;
	else
		error = .;
	error_abs = abs(error);
%MEND ComputeForecast;


%local i;
%local nobs;
%local var;
%local var2remove;
%local lead_valid;
%local lead_test;
%local valid_startdate;
%local test_startdate;
%local plot_startdate;
%local plot_enddate;
%local mprint_option;

%local stationary;
%local trend;
%local intercept;
%local type;
%local lags;
%local probtau;
%local pvalue;
%local beta;

%local seasonal;
%local periodf;		%* Periodo que se encuentra por PROC SPECTRA;
%local accepted;

%local y2fit;
%local target2fit;
%local diff;
%local diffy;
%local noint;
%local var_diff;

%local p;
%local q;
%local nro_esacf;
%local ar_lags;
%local ma_lags;

%local nout_add;
%local nout_shift;
%local dum_add;
%local dum_shift;
%local dum_add_diff;
%local dum_shif_diff;

%local error_arima;
%local data4arima;

%local p_best;
%local q_best;

%local time_start;
%local time_end;
%local time_elapsed;

%let time_start = %sysfunc(time());

%if %quote(&execID) = %then %do;
	%CreateExecutionID(execID);
%end;

%* Borro datasets temporales;
proc datasets library=tempdata nolist;
delete 
		/* Datasets de datos */
		com_&execID._data2fit
		com_&execID._data4arima

		/* Datasets generados durante las initial settings */
		com_&execID._freq_sample
		com_&execID._freq_varclass
		com_&execID._means
		com_&execID._n_varclass
		com_&execID._var2remove
		com_&execID._timeid_sample

		/* Datasets generados por el analisis de STATIONARITY */
		com_&execID._dftest
		com_&execID._fisher
		com_&execID._stationary

		/* Datasets generados por la estimacion lineal del TREND */
		com_&execID._trend_params
		com_&execID._trend_pred

		/* Datasets generados por el analisis de SEASONALITY */
		com_&execID._seasonality
		com_&execID._spectrum
		com_&execID._spectrum_maxp

		/* Datasets generados por ESACF */
		com_&execID._esacf
		com_&execID._esacfPValues
		com_&execID._esacfOrders

		/* Datasets que se generan durante la ejecucion de los distintos modelos sugeridos por ESACF */
		com_&execID._forecast
		com_&execID._mapes
		com_&execID._mape_pqmin
		com_&execID._outliers

		/* Datasets que guardan informacion sobre el mejor modelo ARIMA elegido */
		com_&execID._data4outliers
		com_&execID._forecast1s
		com_&execID._forecast_best
		com_&execID._mape_best
		com_&execID._outliers_best
		com_&execID._params_best
		com_&execID._summary_best;
quit;

/*------------------------------------- Initial Settings ------------------------------------*/
%let mprint_option = %sysfunc(getoption(mprint));

%*** Dataset de analisis;
data tempdata.com_&execID._data2fit;
	set &data;
run;

%*** Calculo de:
- Fechas en que empiezan VALID y TEST 
- Nro. de intervalos en VALID y TEST
Esto sirve para definir las fechas de comienzo de VALID y de TEST y para corregir el valor de LEAD= pasado como parametro;
proc means data=tempdata.com_&execID._data2fit min noprint;
	class &sample;
	var &timeid;
	output out=tempdata.com_&execID._timeid_sample(drop=_TYPE_ rename=(_FREQ_=n)) min=&timeid / autoname;;
run;
data _NULL_;
	set tempdata.com_&execID._timeid_sample;
	if &sample = "2-VALID" then do;
		call symput ('lead_valid', trim(left(n)));
		call symput ('valid_startdate', trim(left(put(&timeid, date9.))));
		call symput ('plot_startdate', trim(left(put(&timeid - &interval*&period_max, date9.))));
	end;
	else if &sample = "3-TEST" then do;
		lead_test = n;
		call symput ('lead_test', trim(left(n)));
		call symput ('test_startdate', trim(left(put(&timeid, date9.))));
		call symput ('plot_enddate', trim(left(put(&timeid + &interval*min(&lead, lead_test), date9.))));
	end;
run;
%let valid_startdate = "&valid_startdate"d;
%let test_startdate = "&test_startdate"d;
%let plot_startdate = "&plot_startdate"d;
%let plot_enddate = "&plot_enddate"d;

%* Limito el valor de LEAD al numero de muestras en TEST;
%let lead = %sysfunc(min(&lead, &lead_test));

%*** VARCLASS, VARNUM;
%if %quote(&varclass) ~= %then %do;
	options nomprint;
	%FreqMult(tempdata.com_&execID._data2fit, var=&varclass, out=tempdata.com_&execID._freq_varclass, log=0);
	options &mprint_option;
	data tempdata.com_&execID._var2remove;
		set tempdata.com_&execID._freq_varclass;
		where nvalues <= 1;
	run;
	%let var2remove = %MakeListFromVar(tempdata.com_&execID._var2remove, var=var);
	%let varclass = %RemoveFromList(&varclass, &var2remove, log=0);
%end;

%* Calculo varianza de las variables continuas para ver si son menores que 1E-12;
%if %quote(&varnum) ~= or %quote(&varclass) ~= %then %do;
	options nomprint;
	%Means(tempdata.com_&execID._data2fit, var=&varnum &varclass, stat=stddev, out=tempdata.com_&execID._means, transpose=1, log=0);
	options &mprint_option;
	data tempdata.com_&execID._var2remove;
		set tempdata.com_&execID._means;
		where stddev <= 1E-6;
	run;
	%let var2remove = %MakeListFromVar(tempdata.com_&execID._var2remove, var=var);
	%let varnum = %RemoveFromList(&varnum, &var2remove, log=0);
	%let varclass = %RemoveFromList(&varclass, &var2remove, log=0);
%end;

%let var = &varclass &varnum;
/*------------------------------------- Initial Settings ------------------------------------*/


	/*---------------------------------- STATIONARITY -------------------------------*/
	%* Datasets creados en TEMPDATA: COM_STATIONARY;

	%put 1.- TEST DE NON-STATIONARITY (&case);
	/* METODOLOGIA PARA ANALISIS DE STATIONARITY:
	Requerir el test de stationarity al PROC ARIMA y seguir los siguientes pasos sobre
	los datos generados por dicho test:
	1.- Empezar por ZERO MEAN
		- Empezar por el LAGS mas grande.
		- Si el p-value es chico, concluyo que la serie es estacionaria 
				=> HAGO PROC ARIMA SOBRE LA SERIE ORIGINAL
				sin ajustar INT en el modelo. (NOINT option en ESTIMATE statement)
		- o.w. me fijo en el p-value de menor LAGS y repito el proceso (porque el p-value de un
		LAGS mayor puede ser grande porque estoy ajustando demasiados parametros).
	2.- Si el paso anterior arrojo' todos los p-valores grandes, seguir con SINGLE MEAN.
		- Empezar por el LAGS mas grande.
		- Si el p-value es chico, concluyo que la serie es estacionaria 
				=> HAGO PROC ARIMA SOBRE LA SERIE ORIGINAL
				ajustando INT en el modelo.
		- o.w. me fijo en el p-value de menor LAGS y repito el proceso (porque el p-value de un
		LAGS mayor puede ser grande porque estoy ajustando demasiados parametros).
	3.- Si el paso anterior arrojo' todos los p-valores grandes, seguir con TREND.
		- Empezar por el LAGS mas grande.
		- Si el p-value es chico, concluyo que la desviacion del TREND es estacionaria
				=> AJUSTO UN TREND Y LUEGO PROC ARIMA SOBRE LA DESVIACION DEL TREND.
		- o.w. me fijo en el p-value de menor LAGS y repito el proceso (porque el p-value de un
		LAGS mayor puede ser grande porque estoy ajustando demasiados parametros).
	3.- Si el proceso no fue interrumpido (o sea, si todos los p-values resultaron grandes quiere decir
	que tengo que diferenciar y no ajustar un trend o un zero mean).
	*/

	ods listing exclude all;
	proc arima data=tempdata.com_&execID._data2fit;
		identify var=&y(0) stationarity=(dickey=6);
	ods output StationarityTests=tempdata.com_&execID._dftest;
	run;
	quit;
	ods listing;

	%* Seteo un valor default para las macro variables relacionadas con la STATIONARITY en caso de que el proceso de
	%* stationarity falle, para que igual el proceso siga. En dicho caso el proceso supone que la serie es estacionaria;
	%let stationary = 1;
	%let trend = .;
	%let intercept = 1;
	%let type = ;
	%let lags = .;
	%let probtau = .;

	%if %sysfunc(exist(tempdata.com_&execID._dftest)) %then %do;
		%* Analisis de los datos generados por el test de stationarity;
		data tempdata.com_&execID._dftest;
			format typen;
			set tempdata.com_&execID._dftest;
			select (upcase(type));
				when ("ZERO MEAN")		typen = 1;
				when ("SINGLE MEAN")	typen = 2;
				when ("TREND")			typen = 3;
				otherwise;
			end;
		run;
		proc sort data=tempdata.com_&execID._dftest;
			by typen descending lags;
		run;
		data _NULL_;
			set tempdata.com_&execID._dftest end=lastobs;
			if . < probtau < 0.05 then do;
				select (typen);
					when (1)
						do;	%* STATIONARY WITH NO INTERCEPT;
							%* NOTAR que pongo intercept=0 para que NO se ajuste un intercept en el modelo;
							call symput ('stationary', trim(left(1)));
							call symput ('trend', trim(left(0)));
							call symput ('intercept', trim(left(0)));
							call symput ('type', trim(left(type)));
							call symput ('lags', trim(left(lags)));
							call symput ('probtau', trim(left(ProbTau)));
							stop;
						end;
					when (2)
						do;	%* STATIONARY WITH INTERCEPT;
							call symput ('stationary', trim(left(1)));
							call symput ('trend', trim(left(0)));
							call symput ('intercept', trim(left(1)));
							call symput ('type', trim(left(type)));
							call symput ('lags', trim(left(lags)));
							call symput ('probtau', trim(left(ProbTau)));
							stop;
						end;
					when (3)
						do;	%* TREND + STATIONARY RESIDUALS;
							call symput ('stationary', trim(left(0)));
							call symput ('trend', trim(left(1)));
							call symput ('intercept', trim(left(0)));
							call symput ('type', trim(left(type)));
							call symput ('lags', trim(left(lags)));
							call symput ('probtau', trim(left(ProbTau)));
							stop;
						end;
					otherwise;
				end;
			end;
			if lastobs then do;	%* DIFFERENCE SERIES (Solo llega aca si no entrO nunca en el IF . < PROBTAU < ... de arriba);
				call symput ('stationary', trim(left(0)));
				call symput ('trend', trim(left(0)));
				call symput ('intercept', trim(left(0)));
				call symput ('type', trim(left(type)));
				call symput ('lags', trim(left(lags)));
				call symput ('probtau', trim(left(ProbTau)));
			end;
		run;
	%end;
	%put %quote(        Stationary=&stationary);
	%put %quote(        Tendencia=&trend);
	%put %quote(        Intercept=&intercept);
	%put %quote(        Tendencia del ultimo test=&type);
	%put %quote(        Lags del ultimo test=&lags);
	%put %quote(        P-valor=&probtau);

	%* Information table;
	data tempdata.com_&execID._stationary;
		stat_stationary = &stationary;
		stat_trend = &trend;
		stat_intercept = &intercept;
		length stat_type $15;
		stat_type = "&type";
		stat_pvalue = &probtau;
		stat_lags = &lags;
	run;

	%* Genero dataset con los parametros de trend para indicar que no fueron estimados en el dataset INFO
	%* en caso de que no se haga una estimacion de TREND;
	data tempdata.com_&execID._trend_params;
		trend_trend = 0;
		trend_pvalue = .;
		trend_beta = .;
	run;
	/*---------------------------------- STATIONARITY -------------------------------*/

	%if &stationary %then %do;
		%put %quote(        No se estima tendencia ni se diferencia porque la serie es estacionaria.);
		%* Defino las variables que se usan en %ARIMAAdj;
		%let y2fit = &y;
%let target2fit = &target;
		%let diff = 0;
		%if not &intercept %then
			%let noint = noint;
		%else
			%let noint = ;
	%end;
	%else %if &trend %then %do;
		/*------------------------------ TREND APPROACH -----------------------------*/
		%* Datasets creados en TEMPDATA: COM_TREND_PARAMS, COM_TREND_PRED;

		%put;
		%put 1A.- ESTIMACION DE TENDENCIA;
		%let trend = 0;
		%let pvalue = .;
		%let beta = .;
		%* Regresion lineal para estimar TREND;
		proc reg data=tempdata.com_&execID._data2fit(keep=&id &sample &timeid &target &y) outest=tempdata.com_&execID._trend_params tableout noprint;
			model &y = &timeid;
			output out=tempdata.com_&execID._trend_pred(keep=&sample &timeid &target pred residual) predicted=pred residual=residual;
		run;
		quit;
		%if %sysfunc(exist(tempdata.com_&execID._trend_params)) %then %do;
			data _NULL_;
				set tempdata.com_&execID._trend_params;
				where upcase(_TYPE_) in ("PARMS" "PVALUE");
				if upcase(_TYPE_) = "PARMS" then
					call symput ('beta', trim(left(put(&timeid, 10.3))));
				else if upcase(_TYPE_) = "PVALUE" and &timeid < 0.05 then do;
					call symput ('trend', trim(left(1)));
					call symput ('pvalue', trim(left(&timeid)));
				end;
			run;
			%* Calculo el residuo para todas las muestras que no sean TRAIN;
			%* Esto es para conocer el valor verdadero de la de-trended series para todas las semanas y asi
			%* poder comparar el pronostico con el real al final del proceso;
			data tempdata.com_&execID._trend_pred;
				set tempdata.com_&execID._trend_pred;
				if &sample ~= "1-TRAIN" then do;
					residual = &target - pred;
				end;
			run;
		%end;
		%put %quote(        Tendencia Lineal=&trend);
		%put %quote(        P-valor=&pvalue);

		%if &trend %then %do;
			%put %quote(        Pendiente=&beta);
			data tempdata.com_&execID._data2fit;
				%* La variable &target._dtrend1 es el RESIDUAL de la regresion lineal, o sea es 
				%* la diferencia entre la serie original y la recta ajstada. Uso el sufijo 1 para
				%* indicar que la TREND ajustada es lineal;
				format &id &sample &timeid
					   &target &target._dtrend1 
					   &y &y._dtrend1 trend;
				merge	tempdata.com_&execID._data2fit(in=in1)
						tempdata.com_&execID._trend_pred(keep=&timeid pred residual
											    rename=(pred=trend residual=&target._dtrend1));
				by &timeid;
				if in1;
				if &y = . then
					&y._dtrend1 = .;
				else
					&y._dtrend1 = &target._dtrend1;
			run;
			%let y2fit =&y._dtrend1;
%let target2fit = &target._dtrend1;
		%end;
		%else %do;
			%let y2fit =&y;
%let target2fit = &target._dtrend1;
		%end;

		%* Information table;
		data tempdata.com_&execID._trend_params;
			trend_trend = &trend;
			trend_pvalue = &pvalue;
			trend_beta = &beta;
		run;

		%* Ajuste ARIMA (notar que aun cuando la pendiente del TREND no da significativa,
		%* igual hago un ajuste ARIMA, pero sobre la variable original (no detrended))
		%* (esto es equivalente a considerar que la serie original es estacionaria, aun
		%* cuando el test de stationarity haya dicho que la serie no es estacionaria. Lo
		%* mas probable es que la tendencia no sea lineal sino de otro tipo, y lo mejor
		%* es ajustar una serie diferenciada como se hace abajo);
		%let diff = 0;
		%let noint = noint;		%* No hay que ajustar intercept cuando se ajustan los residuos de la tendencia;
	%end;
		/*------------------------------ TREND APPROACH -----------------------------*/

	%else %do;	%* AJUSTO LA DIFFERENCED TIME SERIES; 
		/*--------------------------- DIFFERENCE APPROACH ---------------------------*/
		%* Defino las variables que se usan en %ARIMAAdj;
		%let y2fit =&y;	%* Notar que &y2fit = &y y no &y._dif porque en el PROC ARIMA se pide
							%* que se diferencie la variable a modelar;
%let target2fit = &target;
		%let diff = 1;
		%let noint = noint;		%* No hay que ajustar intercept cuando se ajusta la serie diferenciada;
								%* Confirmado por el ETS book;
		/*--------------------------- DIFFERENCE APPROACH ---------------------------*/
	%end;

	%let diffy = &diff;
	%let var_diff = %MakeList(%quote(&var), suffix=%quote(%(&diffy%)));

	/*----------------------------------- SEASONALITY ---------------------------------------*/
	%* Datasets creados en TEMPDATA: COM_FISHER, COM_SEASONALITY, COM_SPECTRUM;

	%* Deteccion de SEASONALITY;
	%put;
	%put 2.- DETECCION DE SEASONALITY (&case);
	%put %quote(        Variable usada para la deteccion: &y2fit);
	ods listing exclude all;
	proc spectra data=tempdata.com_&execID._data2fit out=tempdata.com_&execID._spectrum adjmean whitetest;
/*var &y2fit;*/
var &target2fit;
	ods output whitenoisetest=tempdata.com_&execID._fisher;
	run;
	ods listing;
	%let seasonal = 0;
	%let periodf = .;
	%let accepted = ;

	%if %sysfunc(exist(tempdata.com_&execID._fisher)) and %sysfunc(exist(tempdata.com_&execID._spectrum)) %then %do;
		data tempdata.com_&execID._fisher;
			keep M maxp sump fisher pvalue;
			set tempdata.com_&execID._fisher end=lastobs;
			retain M maxp;
			if _N_ = 1 then
				M = nvalue1;	%* Nota: de acuerdo a Wei, pag. 262, esta constante es (n-1)/2 si n es impar, y n/2-1 si n es par,
								%* donde n es el largo de la serie. El valor almacenado en el dataset WhiteNoiseTest ya viene
								%* con esta formula aplicada segun el caso, ya que si n es impar, dice M, y si n es par dice M-1
								%* en la variable Label1;
			if upcase(label1) = "MAX(P(*))" then
				maxp = nvalue1;
			else if upcase(label1) = "SUM(P(*))" then
				sump = nvalue1;
			if lastobs then do;
				%* Los siguientes estadisticos y p-valor fueron tomados del libro de Wei on Time Series, pag 262;
				if sump ~= 0 then do;
					fisher = maxp / sump;
					pvalue = M*(1 - fisher)**(M-1);
					if pvalue < 0.05 then
						call symput ('seasonal', trim(left(1)));
					output;
				end;
			end;
		run;

		%if &seasonal %then %do;
			%* Agrego numero de observacion al espectro;
			data tempdata.com_&execID._spectrum;
				format obs;
				set tempdata.com_&execID._spectrum;
				obs = _N_;
			run;
			%* Busco los dos picos mas altos del espectro para saber que periodo utilizar en el modelo;
			%* Elijo dos picos en lugar de uno para saber en que sentido redondear cuando el periodo detectado
			%* no es entero (se redondea para el lado en que ocurre el segundo pico mas alto);
			proc means data=tempdata.com_&execID._spectrum noprint;
				var P_01;
				output out=tempdata.com_&execID._spectrum_maxp(drop=_TYPE_ rename=(_FREQ_=n)) idgroup(max(P_01) out[2](P_01 period obs)=) /*maxid(P_01(period))=period*/;
			run;
			%* Defino el periodo como el round del PERIOD calculado en PROC MEANS;
			data _NULL_;
				set tempdata.com_&execID._spectrum_maxp;
				%* Me fijo para que lado cae menos abruptamente el espectro y para ese lado voy a decidir redondear
				%* el valor del periodo;
				if period_2 > period_1 and abs(obs_2 - obs_1) = 1 then
					call symput ('periodf', trim(left(ceil(period_1))));
				else if period_2 < period_1 and abs(obs_2 - obs_1) = 1 then
					call symput ('periodf', trim(left(floor(period_1))));
				else
					call symput ('periodf', trim(left(round(period_1))));
			run;
			%if %sysevalf(&periodf < &period_min) or %sysevalf(&periodf > &period_max) %then %do;;
				%let accepted = NO;
				%put %quote(        Aceptada=NO);
			%end;
			%else %do;
				%let accepted = SI;
				%if &diff = 1 %then
					%let diffy = &diff,&periodf;		%* Diferencio Y tambien en la parte SEASONAL en caso que Y ya se estE diferenciado;
														%* Esto es porque en general si hay que diferenciar en un lag, en general
														%* tambien hay que diferenciar en forma seasonal;
				%put %quote(        Aceptada=SI);
			%end;
		%end;
	%end;
	%put %quote(        Seasonal=&seasonal);
	%put %quote(        Period=&periodf);

	%* Information table;
	data tempdata.com_&execID._seasonality;
		seas_seasonal = &seasonal;
		seas_period = &periodf;
		length seas_accepted $5;
		seas_accepted = "&accepted";
	run;
	/*----------------------------------- SEASONALITY ---------------------------------------*/


	/*--------------------------------------- ESACF -----------------------------------------*/
	%* Datasets creados en TEMPDATA: COM_ARMAORDERS, COM_ESACF, COM_ESACFPVALUES, COM_ESACFORDERS;

	%*** ARIMA ESACF;
	%put;
	%put 3.- IDENTIFICACION DE ORDENES DEL MODELO ARIMA USANDO ESACF (&case);
	%* Identificacion de los valores de p y q usando ESACF (nota esta identificacion no depende
	%* de las variables predictoras que se incluyan en un CROSSCORR= option, asi que no incluyo ninguna);
	ods listing exclude all;
	proc arima data=tempdata.com_&execID._data2fit;
			identify var=&y2fit(&diffy) esacf p=(0:&pmax) q=(0:&qmax) crosscorr=(&var_diff);
	ods output 	esacf=tempdata.com_&execID._esacf
				esacfpvalues=tempdata.com_&execID._esacfPValues
				TentativeOrders=tempdata.com_&execID._esacfOrders;
	run;
	ods listing;
	/*--------------------------------------- ESACF -----------------------------------------*/


	/*---------- AJUSTES SOBRE LOS DISTINTOS P Y Q SUGERIDOS POR EL METODO ESACF ------------*/
	%* Datasets creados en TEMPDATA: COM_MAPES, COM_MAPE_PQMIN;

	%let error_arima = 0;

	%* Leo el nro. de combinaciones P y Q a probar;
	%if not %sysfunc(exist(tempdata.com_&execID._esacfOrders)) %then %do;
		%* En caso de que no haya sido generado el dataset con los valores de p y q a considerar, defino que
		%* los valores a considerar son p=0 y q=0 solamente;
		data tempdata.com_&execID._esacfOrders;
			esacf_ar = 0;
			esacf_ma = 0;
		run;
	%end;
	%let nro_esacf = 0;
	%callmacro(getnobs, tempdata.com_&execID._esacfOrders return=1, nro_esacf);
	%* Borro datasets con los MAPES y con los OUTLIERS para cada combinacion de p y q sugerida por ESACF;
	proc datasets library=tempdata nolist;
		delete 	com_&execID._mapes
				com_&execID._outliers;
	quit;
	%do i = 1 %to &nro_esacf;
		data _NULL_;
			set tempdata.com_&execID._esacfOrders(firstobs=&i obs=&i);
			call symput ('p', trim(left(esacf_ar)));
			call symput ('q', trim(left(esacf_ma)));
		run;
		%put %quote(        Ordenes AR y MA (Caso &i/&nro_esacf): p=&p, q=&q);

		/*------------------------------------- OUTLIERS ------------------------------------*/
		%* Datasets creados en TEMPDATA: COM_OUTLIERS;
		%put;
		%put 4.- DETECCION DE OUTLIERS (&case Caso &i/&nro_esacf: p=&p, q=&q);;
		%put %quote(    Se detectan outliers ADITIVOS y cambios de NIVEL.);

		%*** ARIMA OUTLIERS;
		%* NOTAR que aqui se pasa todo lo que sean periodicidades a diferenciacion de la variable a ajustar
		%* para evitar las inestabilidades numericas en la deteccion de outliers por altos ordenes de p y q;
		ods listing exclude all;
		proc arima data=tempdata.com_&execID._data2fit;
			&outlierscondition;
/*			identify var=&y2fit(&diffy %if %quote(&period) ~= %then %do; , &period %end; %if %quote(&accepted) = SI %then %do; , &periodf %end;) noprint;*/
identify var=&target2fit(&diffy %if %quote(&period) ~= %then %do; , &period %end; %if %quote(&accepted) = SI %then %do; , &periodf %end;) crosscorr=(&var_diff) noprint;
			estimate &noint p=&p q=&q input=(&var) method=ML plot printall; run;
			outlier alpha=0.01 type=(additive shift) id=&timeid sigma=robust maxnum=&outliers_maxnum maxpct=&outliers_maxpct;
		ods output OutlierDetails=tempdata.com_&execID._outliers_&p&q;
		run;
		ods listing;

		%let data4arima = tempdata.com_&execID._data2fit;
		%let nout_add = 0;
		%let nout_shift = 0;
		%if %sysfunc(exist(tempdata.com_&execID._outliers_&p&q)) %then %do;
			%** Notar que siempre se genera el dataset OUTLIERS a menos que el ESTIMATE de error;
			%** Si no se detectaron outliers el dataset OUTLIERS existe pero no tiene observaciones y
			%** por eso ahora me fijo si el nro. de obs en el dataset es > 0;
			%let nobs = 0;
			%callmacro(getnobs, tempdata.com_&execID._outliers_&p&q return=1, nobs);
			%if &nobs > 0 %then %do;
				proc sort data=tempdata.com_&execID._outliers_&p&q;
					by type time;
				run;
				data tempdata.com_&execID._outliers_&p&q;
					format outlier_case;
					set tempdata.com_&execID._outliers_&p&q;
					by type;
					format time weekdate.;		%* Corrijo el formato de la variable TIME porque a veces aparece como WEEKDATE12., lo cual esta mal;
					format Estimate Chisq 10.2;
					if first.type then
						outlier_case = 0;
					outlier_case + 1;
					if _N_ = 1 then
						put @9 "Case" @(9+5) "Obs" @(9+5+5) "Time" @(9+5+5+10) "Type" @(9+5+5+10+15) "Estimate" @(9+5+5+10+15+15) "ChiSq" @(9+5+5+10+15+15+8) "ProbChiSq";
					put @9 outlier_case @(9+5) Obs @(9+5+5) Time date9. @(9+5+5+10) Type @(9+5+5+10+15) Estimate @(9+5+5+10+15+15) ChiSq @(9+5+5+10+15+15+8) ProbChiSq;
				run;

				data tempdata.com_&execID._outliers_&p&q;
					set tempdata.com_&execID._outliers_&p&q end=lastobs;
					nout_add + (upcase(type) = "ADDITIVE");
					nout_shift + (upcase(type) = "SHIFT");
					if lastobs then do;
						call symput ('nout_add', trim(left(nout_add)));
						call symput ('nout_shift', trim(left(nout_shift)));
					end;
					drop nout_add nout_shift;
				run;

				%* Agrego las variables indicadoras de los outliers;
				proc datasets library=tempdata nolist;
					modify com_&execID._outliers_&p&q;
					index create outliers=(type outlier_case) / unique;
				quit;
				data tempdata.com_&execID._data4arima;
					set tempdata.com_&execID._data2fit;
					%if &nout_add > 0 %then %do;
						array dum_add(&nout_add);
						do outlier_case = 1 to dim(dum_add);
							type = "Additive";
							set tempdata.com_&execID._outliers_&p&q(keep=type outlier_case time) key=outliers / unique;
							dum_add(outlier_case) = &timeid = Time;
						end;
					%end;
					%if &nout_shift > 0 %then %do;
						array dum_shift(&nout_shift);
						do outlier_case = 1 to dim(dum_shift);
							type = "Shift";
							set tempdata.com_&execID._outliers_&p&q(keep=type outlier_case time) key=outliers / unique;
							dum_shift(outlier_case) = &timeid >= Time;
						end;
					%end;
					%if &nout_add > 0 or &nout_shift > 0 %then %do;
					drop type outlier_case time;
					%end;
				run;
				%let data4arima = tempdata.com_&execID._data4arima;

				%* Agrego los valores de p y q al dataset con los outliers detectados;
				data tempdata.com_&execID._outliers_&p&q;
					format p q;
					set tempdata.com_&execID._outliers_&p&q;
					length p q 3;
					p = &p;
					q = &q;
				run;

				%* Append de los OUTLIERS;
				proc append base=tempdata.com_&execID._outliers data=tempdata.com_&execID._outliers_&p&q FORCE;
				run;
			%end;
		%end;
		/*------------------------------------- OUTLIERS ------------------------------------*/


		/*-------------------------------------- ARIMA --------------------------------------*/
		%* Datasets creados en TEMPDATA: COM_FORECAST;
		%put 5.- AJUSTE DEL MODELO ARIMA (&case Caso &i/&nro_esacf: p=&p, q=&q);

		%* AR & MA lags;
		%let ar_lags = (0);
		%let ma_lags = (0);
		%if &p > 0 %then
			%let ar_lags = (%MakeListFromName( , start=1, stop=&p, step=1, sep=%quote(,)));
		%if &q > 0 %then
			%let ma_lags = (%MakeListFromName( , start=1, stop=&q, step=1, sep=%quote(,)));
		%* Impongo el periodo pedido;
		%if %quote(&period) ~= %then %do;
			%let ar_lags = &ar_lags(&period);
			%let ma_lags = &ma_lags(&period);
		%end;
		%if &seasonal and %upcase(&accepted) = SI %then %do;
			%let ar_lags = &ar_lags(&periodf);
			%let ma_lags = &ma_lags(&periodf);
		%end;

		%* Lista de indicadoras de outliers;
		%let dum_add = ; %let dum_add_diff = ;
		%let dum_shift = ; %let dum_shift_diff = ;
		%if &nout_add > 0 %then %do;
			%let dum_add = %MakeListFromName(dum_add, start=1, step=1, stop=&nout_add);
			%let dum_add_diff = %MakeList(&dum_add, suffix=%quote(%(&diffy%)));
		%end;
		%if &nout_shift > 0 %then %do;
			%let dum_shift = %MakeListFromName(dum_shift, start=1, step=1, stop=&nout_shift);
			%let dum_shift_diff = %MakeList(&dum_shift, suffix=%quote(%(&diffy%)));
		%end;

		%*** ARIMA FORECAST;
		ods listing exclude all;
		proc arima data=&data4arima;
			identify var=&y2fit(&diffy) crosscorr=(&var_diff &dum_add_diff &dum_shift_diff) noprint;
			estimate &noint p=&ar_lags q=&ma_lags input=(&var &dum_add &dum_shift) method=ML plot printall;
			forecast lead=&lead_valid id=&timeid interval=&interval out=tempdata.com_&execID._forecast; run;
		quit;
		ods listing;
		/*-------------------------------------- ARIMA --------------------------------------*/


		/*------------------------------------ FORECAST -------------------------------------*/
		%* Datasets creados en TEMPDATA: COM_MAPE_&p&q;

		%* Me fijo si se pudo generar un dataset con el forecast (notar que aunque el PROC ARIMA da error
		%* se genera de todas formas un dataset con el forecast y por esto alcanza con preguntar si el nro.
		%* de obs en el dataset es > 0. Notar tambien que si el dataset no existiese, no se genera ningun
		%* error porque en tal caso la macro getnobs (invocada por %callmacro) devuelve 0;
		%let nobs = ;
		%callmacro(getnobs, tempdata.com_&execID._forecast return=1, nobs);
		%if &nobs > 0 %then %do;
			%*** Generacion de los forecasts, cuyo calculo varia segun si se ajusto la serie original, diferenciada
			%*** o de-trended. En los dos primeros casos solo se redondea el valor de la variable FORECAST, y en
			%*** el ultimo caso se calcula el forecast sumando el trend estimado anteriormente;
			%*** Tambien se calcula el error;
			%* Agrego la variable &target._dtrend1, que tiene la diferencia entre la serie
			%* original y la tendencia lineal ajustada (el 1 justamente indica que la tendencia
			%* ajustada es lineal). Su agregado aqui es simplemente como marco de referencia
			%* para el forecast generado;
			data tempdata.com_&execID._forecast;
				merge 	tempdata.com_&execID._forecast(in=in1)
						tempdata.com_&execID._data2fit(keep=&sample &timeid &target &y
								   %if &trend %then %do; 
								   &target._dtrend1 trend
								   %end;);
				by &timeid;
				if in1;
				%ComputeForecast(target=&target, trend=&trend, logarithm=0, round=&round);
			run;

			%* Calculo del MAPE para VALID;
			proc means data=tempdata.com_&execID._forecast mean median stddev noprint;
				class &sample;
				var error error_abs;
				output out=tempdata.com_&execID._mape_&p&q(drop=_TYPE_ rename=(_FREQ_=n)) mean= median= stddev= / autoname;
			run;

			%* Agrego los valores de p y q al MAPE obtenido;
			data tempdata.com_&execID._mape_&p&q;
				format p q;
				set tempdata.com_&execID._mape_&p&q;
				length p q 3;
				p = &p;
				q = &q;
			run;
			/*------------------------------------ FORECAST -------------------------------------*/

			%* Append del MAPE;
			proc append base=tempdata.com_&execID._mapes data=tempdata.com_&execID._mape_&p&q FORCE;
			run;
		%end;

		%* Borro los datasets con el MAPE y con los OUTLIERS detectados asociados a p y q;
		proc datasets library=tempdata nolist;
			delete 	com_&execID._mape_&p&q
					com_&execID._outliers_&p&q;
		quit;
	%end;	%* LOOP sobre las distintas combinaciones de P y Q propuestas por ESACF;
	
	%* Busco la combinacion de P y Q que da el minimo error relativo sobre VALID basado en el error
	%* absoluto MEDIANO (para evitar la influencia desmedida de algun valor muy fuera de orbita);
	%if %sysfunc(exist(tempdata.com_&execID._mapes)) %then %do;
		proc means data=tempdata.com_&execID._mapes noprint;
			where &sample = "2-VALID";
			var error_abs_median;
			output out=tempdata.com_&execID._mape_pqmin(drop=_TYPE_ rename=(_FREQ_=n))
				   idgroup(min(error_abs_median) out(error_abs_median error_abs_mean &sample p q)=);
				   %** IDGROUP pide guardar los valores de P y Q para los que ocurre el minimo del MAPE;
		run;
		data tempdata.com_&execID._mape_pqmin;
			format p q mape &sample;
			set tempdata.com_&execID._mape_pqmin;
			format mape percent7.1;
			mape = error_abs_median;
			label mape = "MEDIAN Absolute Percent Error";
		run;
	%end;
	%else
		%let error_arima = 1;
	/*---------- AJUSTES SOBRE LOS DISTINTOS P Y Q SUGERIDOS POR EL METODO ESACF ------------*/


	/*--------------------------------- MEJOR MODELO --------------------------------*/
	%* Elijo el mejor ajuste para generar el 1-STEP forecast sobre VALID y TEST,
	%* esta vez usando los datos de TRAIN + VALID para estimar los parametros del modelo;

	%put 6.- AJUSTE DEL MEJOR MODELO ARIMA (&case);

	%* Verifico si hubo un error en el proceso arima seguido en ARIMAAdj que haya hecho que no se 
	%* pudiera ajustar ningun modelo, por lo que aqui no hay MEJOR modelo a ajustar!;
	%if ~&error_arima %then %do;
		data tempdata.com_&execID._mape_pqmin;
			%if %sysfunc(exist(tempdata.com_&execID._mape_pqmin)) %then %do;
			set tempdata.com_&execID._mape_pqmin;
			%end;
			%else %do;
			p = .;
			q = .;
			mape = .;
			%end;
			call symput ('p_best', trim(left(p)));
			call symput ('q_best', trim(left(q)));
		run;
		/*--------------------------------- MEJOR MODELO --------------------------------*/

		/*------------------------------ 1-STEP AHEAD FORECAST --------------------------*/
		%* Datasets creados en TEMPDATA: COM_FORECAST1S;

		%* AR & MA lags;
		%let ar_lags_best = (0);
		%let ma_lags_best = (0);
		%if &p_best > 0 %then
			%let ar_lags_best = (%MakeListFromName( , start=1, stop=&p_best, step=1, sep=%quote(,)));
		%if &q_best > 0 %then
			%let ma_lags_best = (%MakeListFromName( , start=1, stop=&q_best, step=1, sep=%quote(,)));
		%* Impongo el periodo pedido;
		%if %quote(&period) ~= %then %do;
			%let ar_lags = &ar_lags(&period);
			%let ma_lags = &ma_lags(&period);
		%end;
		%if &seasonal and %upcase(&accepted) = SI %then %do;
			%let ar_lags_best = &ar_lags_best(&periodf);
			%let ma_lags_best = &ma_lags_best(&periodf);
		%end;

		%* Agrego las variables dummy indicadoras de outliers al dataset  siempre que haya habido outliers detectados;
		%* Nota: hay dos posibilidades sobre los outliers: (i) que no exista el dataset porque hubo un error en la 
		%* estimacion y (ii) que exista el dataset pero tenga 0 observaciones. Estas dos condiciones las verifico aca;
		%let data4arima = tempdata.com_&execID._data2fit;
		%* Inicializo las macro variables que nout_add y nout_shift definen el numero de outliers detectados
		%* en el mejor modelo. Esto es para que si no se detectaron outliers, no considere las variables dum_add
		%* y dum_shift en el ARIMA;
		%let nout_add = 0;
		%let nout_shift = 0;
		%if %sysfunc(exist(tempdata.com_&execID._outliers)) %then %do;
			%let nobs = 0;
			%callmacro(getnobs, tempdata.com_&execID._outliers return=1, nobs);
			%if &nobs > 0 %then %do;
				data tempdata.com_&execID._data4outliers;
					set tempdata.com_&execID._outliers;
					where p = &p_best and q = &q_best;
				run;
				%let nobs = 0;
				%callmacro(getnobs, tempdata.com_&execID._data4outliers return=1, nobs);
				%if &nobs > 0 %then %do;
					data tempdata.com_&execID._outliers_best;
						set tempdata.com_&execID._data4outliers end=lastobs;
						nout_add + (upcase(type) = "ADDITIVE");
						nout_shift + (upcase(type) = "SHIFT");
						if lastobs then do;
							call symput ('nout_add', trim(left(nout_add)));
							call symput ('nout_shift', trim(left(nout_shift)));
						end;
						drop nout_add nout_shift;
					run;

					%* Agrego las variables indicadoras de los outliers;
					proc datasets library=tempdata nolist;
						modify com_&execID._outliers_best;
						index create outliers=(type outlier_case) / unique;
					quit;
					data tempdata.com_&execID._data4arima;
						set tempdata.com_&execID._data2fit;		%* Dataset de demanda semanal;
						%if &nout_add > 0 %then %do;
							array dum_add(&nout_add);
							do outlier_case = 1 to dim(dum_add);
								type = "Additive";
								set tempdata.com_&execID._outliers_best(keep=type outlier_case time) key=outliers / unique;
								dum_add(outlier_case) = &timeid = Time;
							end;
						%end;
						%if &nout_shift > 0 %then %do;
							array dum_shift(&nout_shift);
							do outlier_case = 1 to dim(dum_shift);
								type = "Shift";
								set tempdata.com_&execID._outliers_best(keep=type outlier_case time) key=outliers / unique;
								dum_shift(outlier_case) = &timeid >= Time;
							end;
						%end;
						%if &nout_add > 0 or &nout_shift > 0 %then %do;
						drop type outlier_case time;
						%end;
					run;
					%let data4arima = tempdata.com_&execID._data4arima;
				%end;
			%end;
		%end;

		%* Preparo los parametros para ejecutar un PROC ARIMA usando TRAIN + VALID como muestra de ajuste;
		%let dum_add = ; %let dum_add_diff = ;
		%let dum_shift = ; %let dum_shift_diff = ;
		%if &nout_add > 0 %then %do;
			%let dum_add = %MakeListFromName(dum_add, start=1, step=1, stop=&nout_add);
			%let dum_add_diff = %MakeList(&dum_add, suffix=%quote(%(&diffy%)));
		%end;
		%if &nout_shift > 0 %then %do;
			%let dum_shift = %MakeListFromName(dum_shift, start=1, step=1, stop=&nout_shift);
			%let dum_shift_diff = %MakeList(&dum_shift, suffix=%quote(%(&diffy%)));
		%end;

		%* Elimino los missing de &y para la muestra VALID para que tambien se utilice dicha muestra
		%* en la estimacion de los parametros del modelo que va a generar el 1-step forecast (aparte de
		%* la muestra TRAIN);
/* Pasar el siguiente data step a un MODIFY con index para que solo modifique las entradas correspondientes a
&sample = "2-VALID" para no tener que leer todo el dataset de nuevo. Algo asi:
proc datasets library=tempdata nolist;
modify %scan(&data4arima, 2, '.');
index create &sample;
quit;
data &data4arima; 	%* Hay que ver si conviene moodificar &data4arima o deberia modificar tempdata.com_data4arima, simplemente para no modificar el dataset original con las variables Y en missing para VALID;
&sample = "2-VALID";
modify &data4arima key=&sample / unique;
&y = &target;
%if &trend %then %do;
&y._dtrend1 = &target._dtrend1;
%end;
run;
*/
		data tempdata.com_&execID._data4arima;
			set &data4arima;
			if &sample = "2-VALID" then do;
				&y = &target;
				%if &trend %then %do;
				&y._dtrend1 = &target._dtrend1;
				%end;
				%** NOTAR que &y2fit (la variable usada en el ajuste del PROC ARIMA) puede ser &y o &y._dtrend1;
			end;
		run;

		%* Calculo el 1-step ahead forecast para TEST reajustando los parametros usando TRAIN+VALID;
		ods listing exclude all;
		proc arima data=tempdata.com_&execID._data4arima;
			identify var=&y2fit(&diffy) crosscorr=(&var_diff &dum_add_diff &dum_shift_diff);
			estimate &noint p=&ar_lags_best q=&ma_lags_best input=(&var &dum_add &dum_shift) method=ML plot printall;
			forecast lead=&lead id=&timeid interval=&interval out=tempdata.com_&execID._forecast1s;
		ods output 	ParameterEstimates=tempdata.com_&execID._params_best
					OptSummary=tempdata.com_&execID._summary_best;
		run;
		quit;
		ods listing;

		%* Me fijo si el forecast pudo ser generado (o bien si tiene observaciones);
		%* (Notar que el dataset COM_FORECAST1S no se habia generado en los
		%* PROC ARIMA anteriores, porque alli se guardaba el forecast en el dataset COM_FORECAST);
		%let nobs = ;
		%callmacro(getnobs, tempdata.com_&execID._forecast1s return=1, nobs);
		%if &nobs = 0 %then %do;
			%* Borro el dataset porque voy a intentar generarlo de nuevo;
			proc datasets library=tempdata nolist;
				delete com_&execID._forecast1s;
			quit;

			%* Rehago el pronostico basandome en la estimacion SIN VALID, ya que con VALID no convergio y antes
			%* SIN VALID habia convergido;
			data tempdata.com_&execID._data4arima;
				set tempdata.com_&execID._data4arima;
				if &sample = "2-VALID" then do;
					&y = .;
					%if &trend %then %do;
					&y._dtrend1 = .;
					%end;
					%** NOTAR que &y2fit (la variable usada en el ajuste del PROC ARIMA) puede ser &y o &y._dtrend1;
				end;
			run;

			ods listing exclude all;
			proc arima data=tempdata.com_&execID._data4arima;
				identify var=&y2fit(&diffy) crosscorr=(&var_diff &dum_add_diff &dum_shift_diff);
				estimate &noint p=&ar_lags_best q=&ma_lags_best input=(&var &dum_add &dum_shift) method=ML plot printall;
				forecast lead=%eval(&lead_valid+&lead) id=&timeid interval=&interval out=tempdata.com_&execID._forecast1s;
			ods output 	ParameterEstimates=tempdata.com_&execID._params_best
						OptSummary=tempdata.com_&execID._summary_best;
			run;
			quit;
			ods listing;

			%* Nuevamente me fijo si el forecast pudo ser generado;
			%let nobs = ;
			%callmacro(getnobs, tempdata.com_&execID._forecast1s return=1, nobs);
			%if &nobs = 0 %then %do;
				%let error_arima = 1;
				proc datasets library=tempdata nolist;
					delete com_&execID._forecast1s;
				quit;
			%end;
		%end;

		%if ~&error_arima %then %do;
			%*** Generacion de los output datasets con los forecasts:
			%*** COM_FORECAST_BEST tiene el forecast para TRAIN, VALID y TEST;
			%*** COM_FORECAST1S (Forecast 1-step) tiene el forecast para TEST;
			%*** Notar que si error_arima es 0 (o sea no hubo error en el ARIMA) quiere decir que existe
			%*** el dataset COM_FORECAST1S que se lee aqui);
			%* Agrego la variable &target._dtrend1, que tiene la diferencia entre la serie
			%* original y la tendencia lineal ajustada (el 1 de dtrend1 justamente indica que la tendencia
			%* ajustada es lineal). Su agregado aqui es simplemente como marco de referencia
			%* para el forecast generado;
			data 	tempdata.com_&execID._forecast_best
					tempdata.com_&execID._forecast1s(drop=error error_abs);
				merge 	tempdata.com_&execID._forecast1s(in=in1)
						tempdata.com_&execID._data2fit(in=in2 keep=&sample &timeid &target &y
													 %if &trend %then %do; 
													 &target._dtrend1 trend
													 %end;);
				%** NOTAR que si la opcion NOOUTALL NO se usO en el PROC ARIMA que genera el 1-step forecast arriba,
				%** en el dataset COM_FORECAST1S estan los forecasts para todas las semanas usadas en el ajuste
				%** del modelo (TRAIN y VALID) aparte de la semana de TEST;
				by &timeid;
				if in1;

				%ComputeForecast(target=&target, trend=&trend, logarithm=0, round=&round);

				if &sample = "3-TEST" then output tempdata.com_&execID._forecast1s;
				if not in2 then
					output tempdata.com_&execID._forecast1s;
					%** Si la semana no esta en los datos usados para modelar, la mando al dataset con
					%** el 1-step forecast (correspondiente al forecast de las semanas a pronosticar);
				output tempdata.com_&execID._forecast_best;
			run;

			%* MAPE con los parametros actualizados;
			proc means data=tempdata.com_&execID._forecast_best mean median stddev noprint;
				class &sample;
				var error error_abs;
				output out=tempdata.com_&execID._mape_best(drop=_TYPE_ rename=(_FREQ_=n)) mean= median= stddev= / autoname;
			run;
			%if &plot %then %do;
				%* Grafico;
				%DefineSymbols(n=2, interpol=join, value=dot);
				symbol3 interpol=join value=none color=red line=2 width=2;
				proc gplot data=tempdata.com_&execID._forecast_best;
					format &timeid date9.;
					plot &target*&timeid=1 FORECAST*&timeid=2
						 L95*&timeid=3 U95*&timeid=3 
						/ overlay href=&valid_startdate &test_startdate haxis=&plot_startdate to &plot_enddate by &interval grid legend;
				run;
				quit;
				%DefineSymbols;
			%end;
		%end;
	%end;	%* %IF &error_arima;

	%if &error_arima %then %do;
		%let p_best = .;
		%let q_best = .;
		%put;
		%put ARIMAADJ: ERROR - El pronostico que empieza en &test_startdate no pudo ser generado por errores en la estimacion.;
		%put ARIMAADJ: Se generara el pronostico como un valor constante igual al promedio de los ultimos 4 periodos.;
		%put ARIMAADJ: Nro. de combinaciones de P y Q consideradas: &nro_esacf;

		proc means data=tempdata.com_&execID._data2fit mean noprint;
			where &sample in ("1-TRAIN" "2-VALID") and &test_startdate - 4*&interval <= &timeid < &test_startdate;
				%** el -4*&interval indica que se tomen en consideracion los ultimos 4 periodos anteriores al inicio de TEST;
			var &target;
			output out=tempdata.com_&execID._forecast1s(drop=_TYPE_ rename=(_FREQ_=n)) mean=Forecast;
		run;
		%* Genero un forecast para cada lead pasado en &lead;
		data tempdata.com_&execID._forecast1s;
			set tempdata.com_&execID._data2fit(where=(&sample="3-TEST") keep=&sample &timeid &target);
			if _N_ = 1 then set tempdata.com_&execID._forecast1s;
			label n = "# periodos usados en el calculo del pronostico";
		run;
	%end;
	/*------------------------------ 1-STEP AHEAD FORECAST --------------------------*/

%if %quote(&outforecastall) ~= and %sysfunc(exist(tempdata.com_&execID._forecast_best)) %then %do;	
	data &outforecastall;
		set tempdata.com_&execID._forecast_best;
	run;
	%put;
	%put ARIMAADJ: Dataset %upcase(&outforecastall) generado con el pronostico para TRAIN, VALID y TEST.;
%end;
%if %quote(&outforecast) ~= and %sysfunc(exist(tempdata.com_&execID._forecast1s)) %then %do;	
	data &outforecast;
		set tempdata.com_&execID._forecast1s;
		drop residual;	%* Elimino la variable RESIDUAL porque esta toda en missing para TEST;
	run;
	%put;
	%put ARIMAADJ: Dataset %upcase(&outforecast) generado con el pronostico para TEST que empieza en &test_startdate..;
%end;
%if %quote(&outinfo) ~= and 
	%sysfunc(exist(tempdata.com_&execID._stationary)) and 
	%sysfunc(exist(tempdata.com_&execID._trend_params)) and 
	%sysfunc(exist(tempdata.com_&execID._seasonality)) %then %do;	
	data &outinfo;
		format  arma_p arma_q 
				stat_stationary stat_trend stat_intercept stat_type stat_pvalue stat_lags
				trend_trend trend_pvalue trend_beta
				seas_seasonal seas_period seas_accepted;
		keep 	arma_p arma_q 
				stat_stationary stat_trend stat_intercept stat_type stat_pvalue stat_lags
				trend_trend trend_pvalue trend_beta
				seas_seasonal seas_period seas_accepted;
		%* Valores de p y q best;
		length arma_p arma_q 3;
		arma_p = &p_best;
		arma_q = &q_best;
		set tempdata.com_&execID._stationary;
		set tempdata.com_&execID._trend_params;
		set tempdata.com_&execID._seasonality;
	run;
	%put;
	%put ARIMAADJ: Dataset %upcase(&outinfo) generado con la informacion del ajuste ARIMA.;
%end;

%if %quote(&outmape) ~= and %sysfunc(exist(tempdata.com_&execID._mape_best)) %then %do;	
	data &outmape;
		set tempdata.com_&execID._mape_best;
	run;
	%put;
	%put ARIMAADJ: Dataset %upcase(&outmape) generado con el MAPE (Median Absolute Percent Error) sobre VALID.;
%end;

%if %quote(&outmapes) ~= and %sysfunc(exist(tempdata.com_&execID._mapes)) %then %do;	
	data &outmapes;
		set tempdata.com_&execID._mapes;
	run;
	%put;
	%put ARIMAADJ: Dataset %upcase(&outmapes) generado con los MAPEs sobre VALID de los distintos modelos ARIMA intentados.;
%end;

%if %quote(&outoutliers) ~= and %sysfunc(exist(tempdata.com_&execID._outliers_best)) %then %do;	
	data &outoutliers;
		set tempdata.com_&execID._outliers_best;
	run;
	%put;
	%put ARIMAADJ: Dataset %upcase(&outoutliers) generado con los outliers detectados.;
%end;

%if %quote(&outparams) ~= and %sysfunc(exist(tempdata.com_&execID._params_best)) %then %do;	
	data &outparams;
		set tempdata.com_&execID._params_best;
	run;
	%put;
	%put ARIMAADJ: Dataset %upcase(&outparams) generado con los parametros estimados del modelo ARIMA.;
%end;

%if %quote(&outsummary) ~= and %sysfunc(exist(tempdata.com_&execID._summary_best)) %then %do;	
	data &outsummary;
		set tempdata.com_&execID._summary_best;
	run;
	%put;
	%put ARIMAADJ: Dataset %upcase(&outsummary) generado con el estado del ajuste ARIMA.;
%end;

%* Borro datasets temporales;
proc datasets library=tempdata nolist;
	delete 
		/* Datasets de datos */
		com_&execID._data2fit
		com_&execID._data4arima

		/* Datasets generados durante las initial settings */
		com_&execID._freq_sample
		com_&execID._freq_varclass
		com_&execID._means
		com_&execID._n_varclass
		com_&execID._var2remove
		com_&execID._timeid_sample

		/* Datasets generados por el analisis de STATIONARITY */
		com_&execID._dftest
		com_&execID._fisher
		com_&execID._stationary

		/* Datasets generados por la estimacion lineal del TREND */
		com_&execID._trend_params
		com_&execID._trend_pred

		/* Datasets generados por el analisis de SEASONALITY */
		com_&execID._seasonality
		com_&execID._spectrum
		com_&execID._spectrum_maxp

		/* Datasets generados por ESACF */
		com_&execID._esacf
		com_&execID._esacfPValues
		com_&execID._esacfOrders

		/* Datasets que se generan durante la ejecucion de los distintos modelos sugeridos por ESACF */
		com_&execID._forecast
		com_&execID._mapes
		com_&execID._mape_pqmin
		com_&execID._outliers

		/* Datasets que guardan informacion sobre el mejor modelo ARIMA elegido */
		com_&execID._data4outliers
		com_&execID._forecast1s
		com_&execID._forecast_best
		com_&execID._mape_best
		com_&execID._outliers_best
		com_&execID._params_best
		com_&execID._summary_best;
quit;

%if %quote(&error) ~= %then
	%let &error = &error_arima;

%let time_end = %sysfunc(time());
%let time_elapsed = %TimeElapsed(&time_start, &time_end, tag=Tiempo transcurrido total);
%MEND ARIMAAdj;
