/*


OTHER MACROS AND MODULES USED IN THIS MACRO:
- %ExecTimeStart
- %ExecTimeStop
- %FreqMult
- %GetVarList
- %Means
- %Puts
- %ResetSASOptions
- %SetSASOptions
*/


%MACRO Aggregate(data, by=, varnum=, varclass=, format=, stat=mean, missing=1, out=, log=1)
	/ store des="Aggregates data on a set of BY variables computing the mean for continuous variables and the mode for categorical variables";

%local byst;		%* BY statement;
%local bylist;		%* List of BY variables used in SQL statements;
%local nro_varnum;
%local nro_varclass;

%SetSASOptions;
%ExecTimeStart;

/* ----------------------- Parse input parameters ----------------------------*/
%*** VARNUM, VARCLASS;
%let nro_varnum = 0;
%let nro_varclass = 0;
%if %quote(&varnum) ~= %then %do;
	%let varnum = %GetVarList(&data, var=&varnum);
	%let nro_varnum = %sysfunc(countw(&varnum));
%end;
%if %quote(&varclass) ~= %then %do;
	%let varclass = %GetVarList(&data, var=&varclass);
	%let nro_varclass = %sysfunc(countw(&varclass));
%end;
%* CHeck if any variable was passed;
%if %quote(&varnum) = and %quote(&varclass) = %then %do;
	%if &log %then %do;
		%put;
		%put AGGREGATE: No variables to analyze.;
		%put AGGREGATE: Either the VARNUM= or VARCLASS= parameters need to be non-empty.;
		%put AGGREGATE: The macro stops.;
	%end;
	%abort cancel;
%end;

%*** BY;
%let byst = ;
%let bylist = ;
%if %quote(&by) ~= %then %do;
	%let byst = by &by;
	%let bylist = %MakeList(&by, sep=%quote(,));
%end;
/* ----------------------- Parse input parameters ----------------------------*/


%*** Aggregation of continuous variables;
%if %quote(&varnum) ~= %then %do;
	%if &log %then %do;
		%put;
		%put AGGREGATE: Computing the %upcase(&stat) value for the following CONTINUOUS variables:;
		%puts(&varnum);
	%end;
	%Means(
		&data,
		by=&by,
		format=&format,
		var=&varnum,
		stat=&stat,
		name=&varnum,
		droptypefreq=0,
		out=_aggregate_means(drop=_TYPE_),
		log=0
	);
%end;
%else %do;
	%* Compute the number of records per BY variable to store in the output dataset;
	proc sql;
		create table _aggregate_means as
		select
			%if %quote(&bylist) ~= %then %do;
			&bylist,
			%end;
			count(*) as _FREQ_
		from &data
		%if %quote(&bylist) ~= %then %do;
		group by &bylist
		%end;
		;
	quit;
%end;

%*** Aggregation of categorical variables;
%if %quote(&varclass) ~= %then %do;
	%if &log %then %do;
		%put;
		%put AGGREGATE: Computing the MODE for the following CATEGORICAL variables:;
		%puts(&varclass);
	%end;
	%FreqMult(
		&data,
		by=&by,
		format=&format,
		var=&varclass,
		missing=&missing,
		out=_aggregate_freq,
		log=0
	);
	proc sort data=_aggregate_freq;
		by &by var;
	run;

	%*** Find the modes for character and numeric variables separately (as the values taken by the variables are of different types);
	proc means data=_aggregate_freq noprint;
		where type = "character";
		by &by var;
		var percent;
		output out=_aggregate_mode_char maxid(percent(charvalue))=mode max=percent;
	run;
	proc means data=_aggregate_freq noprint;
		where type = "numeric";
		by &by var;
		var percent;
		output out=_aggregate_mode_num maxid(percent(numvalue))=mode max=percent;
	run;

	%*** Transpose the modes dataset;
	proc transpose data=_aggregate_mode_char out=_aggregate_mode_char_t(drop=_NAME_ _LABEL_);
		&byst;
		id var;
		var mode;
	run;
	proc transpose data=_aggregate_mode_num out=_aggregate_mode_num_t(drop=_NAME_ _LABEL_);
		&byst;
		id var;
		var mode;
	run;

	%*** Put the modes in one dataset;
	data _aggregate_modes;
		set _aggregate_mode_char_t;
		set _aggregate_mode_num_t;
	run;
%end;

%*** Put together the aggregations of continuous and categorical variables;
data &out;
	format &by;
	%* NOTE: The _AGGREGATE_MEANS dataset is always created even if there are no continuous variables to analyze;
	%* The reason is that it always contains at least the _FREQ_ variable counting the number of cases by BY variable;
	format _FREQ_;
	set _aggregate_means;
	%if %quote(&varclass) ~= %then %do;
	set _aggregate_modes;
	%end;
run;
%if &syserr = 0 and &log %then %do;
	%put;
	%put AGGREGATE: Dataset %upcase(&out) was created with the %upcase(&stat) of &nro_varnum continuous variables;
	%put AGGREGATE: and the MODE of &nro_varclass categorical variables;
	%if %quote(&by) ~= %then
		%put AGGREGATE: by BY variables %upcase(&by).;
%end;

proc datasets nolist;
	delete _aggregate_:;
quit;

%ExecTimeStop;
%ResetSASOptions;

%MEND Aggregate;

/*
data totest;
	infile datalines delimiter="," dsd missover;
	length id $10;
	input id $ fecha turno $ x y grp;
	length y 3;
	informat fecha date9.;
	format fecha date9.;
	datalines;
A,01jan2017,N,3.2,1,5
A,02jan2017,N,3.5,1,.
A,03jan2017,M,8,0,4
B,20May2017,M,.,0,.
B,21May2017,N,9,0,4
B,27may2017,T,3.1,0,3
B,27may2017,N,0.0,1,4
C,27may2017,T,1.2,1,3
C,04Jun2017,T,4.5,0,3
C,05Jun2017,T,8.1,0,2
;


* NO grouping (no BY variables);
%Aggregate(totest, varnum=x y, varclass=turno grp, stat=mean, missing=1, out=totest_agg01);
* One single BY variable with STAT = max;
%Aggregate(totest, by=id, varnum=x y, varclass=turno grp, stat=max, missing=1, out=totest_agg02);
* Group by ID, DATE;
%Aggregate(totest, by=id fecha, varnum=x y, varclass=turno grp, stat=mean, missing=1, out=totest_agg03);
* Group by ID, WEEK;
%Aggregate(totest, by=id fecha, format=fecha weekv6., varnum=x y, varclass=turno grp, stat=mean, missing=1, out=totest_agg04);
* Group by ID, MONTH, with stat=median;
%Aggregate(totest, by=id fecha, format=fecha monyy7., varnum=x y, varclass=turno grp, stat=median, missing=1, out=totest_agg05);
* Only VARNUM variables;
%Aggregate(totest, by=id fecha, format=fecha monyy7., varnum=x y, stat=median, missing=1, out=totest_agg06);
* Only VARCLASS variables;
%Aggregate(totest, by=id fecha, format=fecha monyy7., varclass=turno grp, missing=1, out=totest_agg07);
* Only VARNUM variables, NO BY variables;
%Aggregate(totest, format=fecha monyy7., varnum=x y, stat=median, missing=1, out=totest_agg08);
* Only VARCLASS variables, NO BY variables;
%Aggregate(totest, format=fecha monyy7., varclass=turno grp, missing=1, out=totest_agg09);
%* No analysis variables --> a messages should be written in the log stating that no analysis can be done;
%Aggregate(totest);
*/

/*
libname data "E:\Daniel\SAS\Macros\tests\Aggregate\data";
proc copy in=work out=data;
	select totest;
run;

libname expect "E:\Daniel\SAS\Macros\tests\Aggregate\expected";
proc copy in=work out=expect;
	select totest_agg:;
run;
*/
