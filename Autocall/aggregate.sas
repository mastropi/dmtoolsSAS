/* MACRO %Aggregate
Version:	1.00
Author:		Daniel Mastropietro
Created:	19-Mar-2018
Modified:	19-Mar-2018

DESCRIPTION:
Aggregates data on a set of BY variables computing a specified statistic
for continuous variables and the mode for categorical variables.

The computation of the mode on categorical variables is the most added value
of this macro, since it deals with both numeric and character variables
and it computes the mode which is not a straighforward quantity to compute.

Finally, all the information is put together into one dataset, preserving
the original variable names.

USAGE:
%Aggregate(
	data, 			*** Input dataset. Dataset options are allowed.
	by=,			*** Blank-separated list of BY variables.
	varnum=,		*** Blank-separated list of continuous numeric variables.
	varclass=,		*** Blank-separated list of categorical variables.
	format=,		*** Content of the format statement to use during the aggregation.
	stat=mean,		*** Statistic to compute for each continuous variable during the aggregation.
	missing=1, 		*** Whether to consider missing as a valid value for the categorical variables during the aggregation.
	out=,			*** Output dataset with the result of the aggregation.
	log=1);			*** Show messages in the log?


REQUIRED PARAMETERS:
- data:				Input dataset. Dataset options are allowed.

OPTIONAL PARAMETERS:
- by:				Blank-separated list of BY variables by which the categorization
					is carried out.
					default: (empty)

- varnum:			Blank-separated list of continuous numeric variables to aggregate.
					Either this or VARCLASS should be non-empty if some aggregation is to be done.
					default: (empty) (i.e. all numeric variables are aggregated)

- varclass:			Blank-separated list of categorical variables to aggregate.
					Either this or VARNUM should be non-empty if some aggregation is to be done.
					default: (empty)

- format:			Formats to use during the aggregation.
					They should be specified as in any FORMAT statement and they could
					affect any of the variables involved in the aggregation (e.g. the BY
					variables, the continuous variables, or the categorical variables).
					default: (empty)

- missing:			Whether to consider missing as a valid value for the categorical variables
					during the aggregation.
					Possible values: 0 => No, 1 => Yes.
					default: 1

- out:				Output dataset containing the result of the aggregation for both the
					continuous and the categorical variables.
					There is one record per BY variable combination.
					The original variable names are preserved in this aggregated dataset, since
					no information about the statistic computed on the continuous variables
					is added to the variable names.
					default: _AGGREGATE_OUT

- log:				Show messages in the log?
					Possible values: 0 => No, 1 => Yes.
					default: 1

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %ExecTimeStart
- %ExecTimeStop
- %FreqMult
- %GetVarList
- %Means
- %Puts
- %ResetSASOptions
- %SetSASOptions

APPLICATIONS:
Aggregate transaction data about clients BY client in order to get a client profile
with their average information on continuous variables and their most common value
for categorical variables. The latter is the most added value of this macro, since
it deals both numeric and character categorical variables and it computes the
mode which is not a straighforward quantity to compute.
*/


%MACRO Aggregate(data, by=, varnum=, varclass=, format=, stat=mean, missing=1, out=_aggregate_out, log=1)
	/ des="Aggregates data on a set of BY variables computing the mean for continuous variables and the mode for categorical variables";

%local byst;		%* BY statement;
%local bylist;		%* List of BY variables used in SQL statements;
%local nro_varnum;
%local nro_varclass;
%local error;

%SetSASOptions;
%ExecTimeStart;

%let error = 0;

/*----------------------- Parse input parameters ----------------------------*/
%*** BY;
%let byst = ;
%let bylist = ;
%if %quote(&by) ~= %then %do;
	%let byst = by &by;
	%let bylist = %MakeList(&by, sep=%quote(,));
%end;

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
%* Check if any variable was passed;
%if %quote(&varnum) = and %quote(&varclass) = %then %do;
	%if &log %then %do;
		%put;
		%put AGGREGATE: No variables to analyze.;
		%put AGGREGATE: Either the VARNUM= or VARCLASS= parameters need to be non-empty.;
		%put AGGREGATE: The macro stops.;
	%end;
	%let error = 1;
%end;
/*----------------------- Parse input parameters ----------------------------*/

%if ~&error %then %do;

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
	delete 	_aggregate_freq
			_aggregate_means
			_aggregate_modes
			_aggregate_mode_num
			_aggregate_mode_num_t
			_aggregate_mode_char
			_aggregate_mode_char_t
	;
quit;

%end;	%* %if ~&error;

%ExecTimeStop;
%ResetSASOptions;

%MEND Aggregate;
