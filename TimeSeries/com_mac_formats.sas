/* com_mac_formats.sas
Version:		V1
Creado:			16/09/06
Modificado:		17/09/06
Autor:			Daniel Mastropietro
Descripcion:	Definicion de los siguientes formatos usados en el modelo de pronostico de demanda y de
				pronostico de audiencia:
				- DAYSMON:	Numero de dias en cada mes del anho (febrero siempre tiene 28 dias).
				- WKC:		Formato de fecha que indica el numero de semana del anho en que se encuentra.
				- WKMN:		Formato de fecha que indica el numero de semana dentro de cada mes en que se encuentra.

PARAMETROS DE ENTRADA
Parametro		Descripcion
===================================================================================================
FechaActual		Fecha en la que se efectua la ejecucion del proceso o modelo.
execID			Id de Ejecucion. Si es vacio, se genera uno en esta macro.
===================================================================================================

MACROS UTILIZADAS
Nombre				Descripcion												Fuente
===================================================================================================
%CreateExecutionID	Genera un ID de ejecucion.								com_mac_miscellanea.sas
===================================================================================================
*/

%MACRO FormatsWK(FechaActual=, execID=);
%local FirstFecha;
%local LastFecha;
%local year_start;
%local year_end;

%* ID de Ejecucion;
%if %quote(&execID) = %then %do;
	%CreateExecutionID(execID);
%end;

/*--------------------------------- Startup settings ----------------------------------------*/
%* Primer fecha a considerar en la definicion del formato (DEBE SER 01JAN);
%let firstfecha = '01jan2000'd;
%* Ultima fecha a considerar en el formato (igual al 31 diciembre del anho siguiente a la fecha actual);
data _NULL_;
	call symput ('lastfecha','31dec'||trim(left(year(&fechaactual)+1)));
run;
%let lastfecha = "&lastfecha"d;

%* Anhos de firstfecha y lastfecha;
%let year_start = %substr(&firstfecha, 9, 2);
%let year_end = %substr(&lastfecha, 9, 2);
/*--------------------------------- Startup settings ----------------------------------------*/


/************************************** FORMATO DAYSMON **************************************/
%* Number of days in each month (regardless of leap or non-leap years);
%* Note that the fact that a february of a leap year is considered to have 28 days only affects
%* in the creation of the WKC format in that the last week of february could be considered as the
%* first week of march (this will happen only when Monday falls on the 26th of february and the
%* year is a leap year);
%* The values in the dataset are defined using the OUTPUT statemenet instead of DATALINES, because
%* the DATALINES does not work when the code is %INCLUDED!!!;
data tempdata.com_&execID._formatdaysmon;
	format month_num label;
	keep month_num label;
	length label $2;
	array labels(12) $ ("31", "28", "31", "30", "31", "30", "31", "31", "30", "31", "30", "31");
	do month_num = 1 to 12;
		label = labels(month_num);
		output;
	end;
run;
data tempdata.com_&execID._formatdaysmon;
	keep fmtname type start end label sexcl eexcl;
	format fmtname type start end label sexcl eexcl;
	set tempdata.com_&execID._formatdaysmon;
	retain fmtname "daysmon";
	retain type "N";
	retain sexcl "N";
	retain eexcl "N";
	start = month_num;
	end = month_num;
run;
proc format library=formats cntlin=tempdata.com_&execID._formatdaysmon;
run;
proc datasets library=tempdata nolist;
	delete com_&execID._formatdaysmon;
quit;
%* Set format description;
proc catalog catalog=formats.formats;
	modify daysmon.format(description="Format: Number of days in each month (as a number) --no leap years considered");
quit;
/************************************** FORMATO DAYSMON **************************************/


/*************************************** FORMATO WKMN ****************************************/
/* Number of week within the month;
The values range from 1 to 5, and a week is considered to start on Monday. When a week falls in between
two months, it is associated with the month that holds 4 or more days of the week;
FORMAT DAYSMON IS REQUIRED!
*/
data tempdata.com_&execID._formatwkmn;
	keep fmtname type start end label sexcl eexcl;
	format fmtname type start end label sexcl eexcl;
	format start end lastfecha date9.;
	retain fmtname "wkmn";
	retain type "N";
	retain sexcl "N";
	retain eexcl "N";
	retain fecha &firstfecha;
	%* Initialize START and SEMANA;
	if _N_ = 1 then do;
		%* Initialize START;
		if weekday(&firstfecha) = 1 then
			start = &firstfecha - 6;
		else
			start = &firstfecha - (weekday(&firstfecha) - 2);
		* Initialize SEMANA;
		if 2 <= weekday(&firstfecha) <= 5 then		/* 01jan falls on Monday, Tuesday, Wednesday or Thursday */
			semana = 1;
		else
			semana = 5;
	end;
	
	%* Main cycle;
	do while (fecha <= &lastfecha);
		daysInMonth = input( put(month(fecha), daysmon.), 2.);
		day = day(fecha);
		* MONDAY => Start a new week;
		if weekday(fecha) = 2 then do;
			start = fecha;
			if daysInMonth < (day + 3) or day <= 4 then
				semana = 1;
			else
				semana = semana + 1;
		end;
		%* SUNDAY => Output;
		if weekday(fecha) = 1 then do;
			label = put(semana, 1.);
			end = fecha;
			output;
		end;
		fecha + 1;
	end;

	%* If the weekday of &lastfecha is not a Sunday, still need to output the last record;
	if weekday(&lastfecha) ~= 1 then do;
		label = put(semana, 1.);
		end = fecha + (7 - weekday(&lastfecha));	* Recall that fecha = &lastfecha + 1 at this point;
		output;
	end;
run;
proc format library=formats cntlin=tempdata.com_&execID._formatwkmn;
run;
proc datasets library=tempdata nolist;
	delete com_&execID._formatwkmn;
quit;
%* Set format description;
proc catalog catalog=formats.formats;
	modify wkmn.format(description="Format: Number of week within each month --for dates ranging from 01JAN&year_start to 31DEC&year_end");
quit;
/*************************************** FORMATO WKMN ****************************************/


/*************************************** FORMATO WKC *****************************************/
/*	Week format (C = Continuous), based on the WEEKV. format;
Continuous => A week is NOT cut into 2 pieces when new years day falls in the middle of the week;
Weeks are considered to start on a Monday;
Weeks range from 01 to 53, all being complete, except when the week is the first week or the last week of 
the period considered in the definition of the format (given by the macro variables &year_start and &year_end);
Also note that the only week that may belong to two different years is the last week of the year, either the
52nd or the 53rd week. The first week always belongs in full to the same year (as explained in the WEEKV. format
(even though not in these explicit terms))
*/
%* NOTA: Existen tambien los formatos WEEKW, WEEKV y WEEKU, pero estos incluyen el dia de la semana en el formato,
%* y esto no me interesa y no me sirve para los fines de clasificar las fechas por semana;
%* (Para saber mas sobre estos formatos ir a la seccion SAS National Language Support de SAS Products y Formats for NLS);
data tempdata.com_&execID._data4format;
	do fecha = &firstfecha to &lastfecha;
		label = substr(put(fecha, weekv.), 1, 8);
		output;
	end;
run;
proc means data=tempdata.com_&execID._data4format min max noprint;
	var fecha;
	by label;
	output out=tempdata.com_&execID._formatwkc n=n min=start max=end;
run;
data tempdata.com_&execID._formatwkc;
	keep fmtname type start end label sexcl eexcl;
	format fmtname type start end label sexcl eexcl;
	length label $10;
	set tempdata.com_&execID._formatwkc;
	format start end date9.;
	retain fmtname "wkc";
	retain type "N";
	retain sexcl "N";
	retain eexcl "N";
	label = trim(left(label)) || "-" || put(n,1.);
run;
proc format library=formats cntlin=tempdata.com_&execID._formatwkc;
run;
proc datasets library=tempdata nolist;
	delete formatwkc data4format;
quit;
%* Set format description;
proc catalog catalog=formats.formats;
	modify wkc.format(description="Format: Week within a year (based on WEEKV. format) --for dates ranging from 01JAN&year_start to 31DEC&year_end");
quit;
/*************************************** FORMATO WKC *****************************************/
%MEND FormatsWK;
