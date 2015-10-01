/* MACRO %QualifyVars
Version:		1.02
Author:			Daniel Mastropietro
Created:		03-Aug-2015
Modified:		29-Sep-2015 (previous: 28-Aug-2015)
SAS Version:	9.4

DESCRIPTION:
Qualifies a set of varibales into categorical or interval (continuous) based on the number of distinct values.
In addition it computes the following summary information:
- #zeros, %zeros
- #missing, %missing
- Number of distinct values
- List of distinct values taken for the variables with a maximum number of distinct values

USAGE:
%QualifyVars(
	data,						*** Input dataset (data options are allowed)
	var=_ALL_,					*** List of variables to qualify.
	maxncat=50,					*** Max. number of distinct values to qualify variable as categorical.
	maxnfreq=50,				*** Max. number of distinct values to list the distinct values.
	out=,						*** Output dataset (data options are allowed).
	sortby=level nvalues var,	*** Sorting criteria of the output dataset.
	log=1);						*** Show messages in log?

REQUIRED PARAMETERS:
- data:			Input dataset. Data options can be specified as in a data= SAS option..

OPTIONAL PARAMETERS:
- var:			List of variables to analyze.
				default: _ALL_

- maxncat:		Maximum number of distinct values for a variable to be classified as categorical. 
				default: 50

- maxnfreq:		Maximum number of distinct values that a variable can take in order to show
				the distinct values taken by the variable.
				When empty, it is set to the same value as MAXNCAT.
				default: empty

- out:			Output dataset containing the variable qualification.
				It contains the following columns in the order given:
				- var         Char     Variable Name
				- label       Char     Variable Label
				- nobs        Num      Total Number of Observations in input dataset
				- type        Char     Variable Type
				- level       Char     Assigned level of variable (categorical or interval)
				- values      Char     Values taken by categorical variables with less than maxnfreq distinct values.
				- nvalues     Num      Number of Different Values
				- nmiss       Num      Number of Missing Values
				- nzeros      Num      Number of Zeros
				- pvalues     Num      Percent of Distinct Values
				- pmiss       Num      Percent of Missing Values
				- pzeros      Num      Percent of Zeros

- sortby:		List of variables to sort the output dataset by.
				default: level nvalues var (so that categorical variables are listed on top and
				they are sorted by increasing number of distinct values taken)

- log:			Show messages in the log?
				Possible values: 0 => No, 1 => Yes.
				default: 1	

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %ExecTimeStart
- %ExecTimeStop
- %FreqMult
- %GetDataName
- %GetNroElements
- %GetVarAttrib
- %GetVarType
- %ResetSASOptions
- %SetSASOptions
*/
&rsubmit;
%MACRO QualifyVars(
		data,
		var=_ALL_,
		maxncat=50,
		maxnfreq=,
		out=,
		sortby=level nvalues var,
		log=1) / store des="Qualifies variables into categorical or continuous based on the number of distinct values";
%local i;
%local _var_;
%local _label_;
%local _type_;
%local maxlengthlabel;
%local nro_vars;
%local nro_var4freq;
%local var4freq;

%SetSASOptions;
%ExecTimeStart;

%if &log %then %do;
	%put;
	%put QUALIFYVARS: Macro starts;
	%put;
	%put QUALIFYVARS: Input parameters:;
	%put QUALIFYVARS: - Input dataset = %quote(    &data);
	%put QUALIFYVARS: - var = %quote(              &var);
	%put QUALIFYVARS: - maxncat = %quote(          &maxncat);
	%put QUALIFYVARS: - maxnfreq = %quote(         &maxnfreq);
	%put QUALIFYVARS: - out = %quote(              &out);
	%put QUALIFYVARS: - sortby = %quote(           &sortby);
	%put QUALIFYVARS: - log = %quote(              &log);
	%put;
%end;

/*---------------------------------- Parse input parameters ---------------------------------*/
%*** MAXNFREQ=;
%if %quote(&maxNFreq) = %then
	%let maxNFreq = &maxNCat;

%*** VAR=;
%let var = %GetVarList(&data, var=&var, log=0);
%let nro_vars = %GetNroElements(&var);

%*** OUT=;
%if %quote(&out) = %then %do;
	%let out = %GetDataName(%quote(&data))_qv;
%end;
/*---------------------------------- Parse input parameters ---------------------------------*/

%if &log %then
	%put QUALIFYVARS: Computing number of distinct values, number of missing and number of zeros of &nro_vars variables...;
proc sql;
	create table _qv_sql_ as
	select
		count(*) as nobs
	%let maxlengthlabel = 10;	%* Set the minimum maxlengthlabel to 10 which is a length larger than the strings CHARACTER and NUMERIC
								%* which are the possible values taken by the T* columns. This is to avoid truncation of 
								%* data when transposing the SQL output to create the _qv_char_ dataset;
	%do i = 1 %to &nro_vars;
		%let _var_ = %scan(&var, &i, ' ');
		%let _label_ = %GetVarAttrib(&data, &_var_, varlabel);
		%let maxlengthlabel = %sysfunc(max(&maxlengthlabel, %length(%quote(&_label_))));
		%let _type_ = %upcase(%GetVarType(&data, &_var_));
		,"&_label_" as l&i
		,%if &_type_ = C %then %do; "character" %end; %else %do; "numeric" %end; as t&i length=10
		,count(distinct(&_var_)) as n&i
		,nmiss(&_var_) as m&i
		%if &_type_ = N %then %do;
		,sum(case when &_var_ = 0 then 1 else 0 end) as z&i
		%end;
		%else %do;
		%* Assign missing to z&i for character variables
		%* (note that I need to use CASE WHEN statement because the dot is not accepted as missing value if used directly);
		,(case when 1 then . else 0 end) as z&i
		%end;
	%end;
	from &data;	
quit;

%*** Separate the different info just stored in different columns into different rows by concept;
%*** The separation needs to be done by type of variable (character and numeric) because the new columns
%*** in the transposed data can only store values of the same type;
%* Separate the character variables;
data _qv_char_;
	length concept $10 &var $&maxlengthlabel;
	set _qv_sql_(in=inL keep=l1-l&nro_vars
				rename=(
				%do i = 1 %to &nro_vars;
					%let _var_ = %scan(&var, &i, ' ');
					%quote(l&i=&_var_ )
				%end;))
		_qv_sql_(in=inT keep=t1-t&nro_vars
				rename=(
				%do i = 1 %to &nro_vars;
					%let _var_ = %scan(&var, &i, ' ');
					%quote(t&i=&_var_ )
				%end;))
	;
	if inL then concept = "label";
	else if inT then concept = "type";
run;

%* Separate the numeric variables;
data _qv_num_;
	length concept $10;
	set _qv_sql_(in=inN keep=n1-n&nro_vars
						rename=(
						%do i = 1 %to &nro_vars;
							%let _var_ = %scan(&var, &i, ' ');
							%quote(n&i=&_var_ )
						%end;))
		_qv_sql_(in=inM keep=m1-m&nro_vars
						rename=(
						%do i = 1 %to &nro_vars;
							%let _var_ = %scan(&var, &i, ' ');
							%quote(m&i=&_var_ )
						%end;))
		_qv_sql_(in=inZ keep=z1-z&nro_vars
						rename=(
						%do i = 1 %to &nro_vars;
							%let _var_ = %scan(&var, &i, ' ');
							%quote(z&i=&_var_ )
						%end;))
	;
	if inN then concept = "nvalues";
	else if inM then concept = "nmiss";
	else if inZ then concept = "nzeros";
run;

%*** Transpose the summary information;
%* Character variables;
proc transpose data=_qv_char_ out=_qv_char_ name=var;
	id concept;
	var &var;
run;
%* Numeric variables;
proc transpose data=_qv_num_ out=_qv_num_ name=var;
	id concept;
	var &var;
run;

%*** Compute frequencies of variables with less than e.g. 10 distinct values;
proc sql noprint;
	select var into :var4freq separated by ' '
	from _qv_num_
	where nvalues <= &maxNFreq;
quit;
%let nro_var4freq = %GetNroElements(&var4freq);

%* Compute frequency tables;
%if &nro_var4freq > 0 %then %do;
	%if &log %then
		%put QUALIFYVARS: Finding the values taken by &nro_var4freq variables with at most &maxNFreq levels...;
	%FreqMult(&data, var=&var4freq, out=_qv_freq_, missing=1, transpose=1, log=0);
%end;

%*** Put all summary info together;
proc sort data=_qv_char_; by var;
proc sort data=_qv_num_; by var;
data _qv_out_;
	format var label nobs type level values nvalues nmiss nzeros pvalues pmiss pzeros;
	merge 	_qv_char_
			_qv_num_
			%if &nro_var4freq > 0 %then %do; _qv_freq_(keep=var values) %end;
			;
	by var;
	if _N_ = 1 then set _qv_sql_(keep=nobs);
	%if &nro_var4freq = 0 %then %do;
	values = "";	%* When distinct values are not reported for any variables, set the character variable coming from _qv_freq_ to missing;
	%end;
	if type = "character" or nvalues <= &maxNCat then
		level = "categorical";
	else
		level = "interval";
	%* Compute percentage of missing and zeros;
	format pvalues percent7.3;			%* The percentage of pvalues are expected to be quite small for categorical variables, that is why I use more decimals;
	format pmiss pzeros percent7.1;
	pvalues = nvalues / nobs;
	pmiss = nmiss / nobs;
	pzeros = nzeros / nobs;

	label 	var = "Variable Name"
			label = "Variable Label"
			nobs = "Total Number of Observations in input dataset"
			type = "Variable Type"
			level = "Assigned level of variable (Max nvalues for categorical = &maxncat)"
			nvalues = "Number of Different Values"
			nmiss = "Number of Missing Values"
			nzeros = "Number of Zeros"
			pvalues = "Percent of Distinct Values"
			pmiss = "Percent of Missing Values"
			pzeros = "Percent of Zeros";
run;
%if %quote(&sortby) ~= %then %do;
	%* Create the output dataset by sorting _qv_out_ by the requested variables;
	proc sort data=_qv_out_ out=&out;
		by &sortby;
	run;
%end;
%else %do;
	%* Just copy _qv_out_ to the output dataset;
	data &out;
		set _qv_out_;
	run;
%end;

proc datasets nolist;
	delete 	_qv_sql_
			_qv_char_
			_qv_num_
			%if &nro_var4freq > 0 %then %do; _qv_freq_ %end;
			_qv_out_;
quit;

%if &log %then %do;
	%put;
	%put QUALIFYVARS: Macro ends;
	%put;
%end;

%ExecTimeStop;
%ResetSASOptions;

%MEND QualifyVars;
