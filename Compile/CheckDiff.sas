/* MACRO %CheckDiff
Version: 1.00
Author: Daniel Mastropietro
Created: 28-Jun-06
Modified: 09-Aug-06

DESCRIPTION:
This macro shows the observations in a dataset having different values of ONE given variable
for the same combination of BY variable values.

The output dataset stores...

how many different values of a certain variable there are for each by group.
The by groups are defined by the parameter 'byvars' and the variable (only one) whose different
values we are interested in is defined in the parameter 'var'.
The macro prints (in the log file) the number of by groups in which the variable &var
has more than one different value. 
The data set &dataout contains those groups identified by the by variables that have more
than one different value of &var.

USAGE:


REQUIRED PARAMETERS:
- data:				Input dataset. Data options can be specified as in any data= SAS option.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Callmacro
- %Getnobs
- %MakeList
- %ResetSASOptions
- %SetSASOptions


APPLICATIONS:

*/

/*
1.- 27/06/06
Actualizar la macro usando el siguiente codigo, donde hay que cambiar el &by de manera que las variables
esten separads por comas en lugar de por espacios.
proc sql noprint;
	create table diff as
		select distinct &by, &var, count(distinct A_ID_CLIENTE) as count, min(D_FECHA_AEL) as min, max(D_FECHA_AEL) as max
			from toanalyze
			group by C_NOMBRE_CLIENTE
			having calculated count > 1;
quit;

*/
&rsubmit;
%MACRO CheckDiff(data, var=, by=, out=, outall=, log=1, notes=0) 
		/ store des="Finds observations having different values of a variable for each combination of a set of by variables";
%local i;
%local bylist byvari nro_byvars;
%local nobs nvar;

%SetSASOptions(notes=&notes);

/*------------------------------ Parse input parameters -------------------------------------*/
%*** BY;
%let nro_byvars = %GetNroElements(%quote(&by));
%let bylist = %MakeList(%quote(&by), sep=%quote(,));

%*** OUT;
%if %quote(&out) = %then %do;
	%let out = _CheckDiff_out_;
%end;
/*------------------------------ Parse input parameters -------------------------------------*/


proc sql noprint;
	create table &out as
		select distinct &bylist, &var, count(distinct &var) as _count_
			from &data
			group by &bylist
			having calculated _count_ > 1;
quit;


%if %quote(&outall) ~= %then %do;
proc sql noprint;
	create table &outall as
		select out.*, data._count_
			from &out as out
			inner join &data as data
			%if &nro_byvars = 1 %then %do;
			on out.&by = data.&by
			order by out.&by;
			%end;
			%else %do;
			on
				%do i = 1 %to %eval(&nro_byvars-1);
					%let byvari = %scan(%quote(&by), &i, %quote(,));
					out.&byvari = data.&byvari and
				%end;
				%let byvari = %scan(%quote(&by), &nro_byvars, %quote(,));
				out.&byvari = data.&byvari
			order by %MakeList(%quote(&by), sep=%quote(,), prefix=out.); 
			%end;
		select distinct &bylist
			from &out as out
			%if &nro_byvars = 1 %then %do;
			where out.&by = data.&by
			order by data.&by;
			%end;
			%else %do;
			where
				%do i = 1 %to %eval(&nro_byvars-1);
					%let byvari = %scan(%quote(&by), &i, %quote(,));
					out.&byvari = data.&byvari and
				%end;
				%let byvari = %scan(%quote(&by), &nro_byvars, %quote(,));
				out.&byvari = data.&byvari
			order by %MakeList(%quote(&by), sep=%quote(,), prefix=out.); 
			%end;
quit;
%end;

%callmacro(getnobs, &out return=1, nobs nvar);
%if &log %then %do;
	%put;
	%put CHECKDIFF: Output dataset &out created with &nobs observations and &nvar variables.;
%end;



/**/
/*proc sort data=&data out=_CheckDiff_nodup_ nodupkey;*/
/*	by &by &var;*/
/*run;*/
/** Create a numeric variable with always the value of 1, in order to be able to count the*/
/** number of different values of the variable &var in case this variable is not numeric;*/
/*data _CheckDiff_nodup_;*/
/*	set _CheckDiff_nodup_;*/
/*	_count_ = 1;*/
/*run;*/
/*proc means data=_CheckDiff_nodup_ n noprint;*/
/*	by &by;*/
/*	var _count_;*/
/*	output out=_CheckDiff_count_(drop=_TYPE_ _FREQ_) n=nro_&var;*/
/*run;*/
/*proc sort data=&data out=_CheckDiff_Sorted_;*/
/*	by &by;*/
/*run;*/
/**/
/*%if %quote(&out) = %then*/
/*	%let out = _TEMP_;*/
/**/
/*data &out;*/
/*	merge _CheckDiff_Sorted_(in=in1) _CheckDiff_count_(in=in2 keep=&by nro_&var where=(nro_&var>1));*/
/*	by &by;*/
/*	if in2;*/
/*run;*/
/**/
/*%getnobs(&out);*/
/*proc datasets nolist;*/
/*	delete	_CheckDiff_nodup_*/
/*			_CheckDiff_count_*/
/*			_CheckDiff_Sorted_*/
/*			_TEMP_;*/
/*quit;*/

%ResetSASOptions;
%MEND CheckDiff;
