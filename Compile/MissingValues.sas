/* MACRO %MissingValues
Version: 1.02
Author: Daniel Mastropietro
Created: 28-Dec-04
Modified: 7-Aug-06

DESCRIPTION:
This macro computes the number of missing values of a set of numeric variables and character
variables, and generates an output dataset with the number and percentage of missing values
for each analysis variable.
Optionally, it can compute the number and percentage of observations that have a given value
(such as 0). This value can be numeric or character.

USAGE:
%MissingValues(data, by=, var=_ALL_, value=, out=, log=1);

REQUIRED PARAMETERS:
- data:			Input dataset. Data options can be specified as in any data= SAS option.

OPTIONAL PARAMETERS:
- by:			Blank-separated list of variables by which the analysis is done.

- var:			List of variables for which missing values are searched.
				default: _ALL_

- value:		Value of interest. The count and percentage of observations having this value
				is computed. This can be a numeric value or a character value. The numbers are
				computed for the variables of the same type (either numeric or character). 
				default: (empty)

- out:			Output dataset containing the variables in the input dataset that have at least
				one missing value.
				Data options can be specified as in any data= SAS option.
				The output dataset contains the following 4 columns:
				- var:			Variable name with missing values.
				- type:			Variable type: C or N
				- n:			Total number of observations in the dataset
				- nmiss:		Number of missing values.
				- pcntmiss:		Percentage of missing values.
				When parameter VALUE is not blank, the following additional columns are created
				in the output dataset:
				- n<value>:	Number of obs with their value equal to VALUE.
				- pcnt<value>:	Percentage of obs with their value equal to VALUE.
				default: _mv_missing_

- log:			Show messages in the log?
				Possible values: 0 => No, 1 => Yes
				default: 1

NOTES:
It is assumed that the variables VAR, TYPE, COUNT, N and PERCENT do NOT exist in the input dataset.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %GetNroElements
- %GetVarList
- %GetVarType
- %RemoveFromList
- %ResetSASOptions
- %SetSASOptions

EXAMPLES:
1.- %MissingValues(test, var=_NUMERIC_, out=missing);
Generates dataset MISSING with the number and percentage of missing values for the numeric
variables present in the dataset TEST. The information is stored in variables NMISS and PCNTMISS.

2.- %MissingValues(test, var=x y z w, value=0, out=missing0);
Generates dataset MISSING0 with:
- number and percentage of missing values for variables X Y Z and W.
- number and percentage of zeros for variables X Y Z and W.
The information is stored, respectively, in variables NMISS, PCNTMISS, N0 and PCNT0.

3.- %MissingValues(test, var=a b c d, value="A", out=missingA);
Generates dataset MISSINGA with:
- number and percentage of missing values for variables A B C and D.
- number and percentage of values equal to "A" for variables A B C and D.
The information is stored, respectively, in variables NMISS, PCNTMISS, NA and PCNTA.

4.- %MissingValues(test, by=group subgroup, var=x y z w, value=-1, out=MissingByGroup);
Generates dataset MISSINGBYGROUP with the following information by each combination of the by
variables GROUP and SUBGROUP.
- number and percentage of missing values for variables X Y Z and W.
- number and percentage of values equal to -1 for variables X Y Z and W.
The information is stored, respectively, in variables NMISS, PCNTMISS, NM1 and PCNTM1.
*/
&rsubmit;
%MACRO MissingValues(data, by=, var=_ALL_, value=, out=, log=1) 
	/ store des="Creates a table with the number and percentage of missing values in a set of variables";
%local data_name nobs nvar nro_vars nro_charvars nro_numvars out_name vari type;
%local charvar numvar ValueType;
%local pos_decimal valuename;
%local lastby nro_byvars;

%SetSASOptions;

%if &log %then %do;
	%put;
	%put MISSINGVALUES: Macro starts;
	%put;
%end;

%let data_name = %scan(&data, 1, '(');
/*----- Parsing input parameters -----*/
%*** VAR=;
%let var = %GetVarList(&data_name, var=&var, log=0);
%let nro_vars = %GetNroElements(&var);

%*** BY=;
%if %quote(&by) ~= %then %do;
	proc sort data=&data out=_MV_data_(keep=&by &var);
		by &by;
	run;
	%let data = _MV_data_;
	%* Remove by variables from VAR list;
	%let var = %RemoveFromList(%quote(&var), %quote(&by), log=0);
	%let nro_vars = %GetNroElements(&var);

	%* Read the name of the variable listed last in the by parameter (this is to check for the first and last occurrence of
	%* the by groups);
	%let nro_byvars = %GetNroElements(%quote(&by));
	%let lastby = %scan(%quote(&by), &nro_byvars, ' ');
%end;
%else
	%let data = &data;

%*** VALUE=;
%let ValueType = ;
%if %quote(&value) ~= %then %do;
	%if (%index(&value, %str(%")) or %index(&value, %str(%'))) %then %do;
		%let ValueType = C;
		%let value = %substr(%nrbquote(&value), 2, %length(%nrbquote(&value))-2);
	%end;
	%else
		%let ValueType = N;

	%let valuename = &value;
	%** Fix the name to use for the variable n&value and nmiss&value when &value is a negative
	%** number or decimal number;
	%* Negative sign;
	%if %index(%substr(&value, 1, 1), -) %then %do;
		%let valuename = M%substr(&value, 2);
	%end;
	%* Decimal point;
	%if %index(&value, .) %then %do;
		%let pos_decimal = %index(&value, .);
		%let valuename = %substr(&value, 1, %eval(&pos_decimal-1))_%substr(&value, %eval(&pos_decimal+1));
	%end;
%end;
/*------------------------------------*/

%let numvar = ;
%let charvar = ;
%do i = 1 %to &nro_vars;
	%let vari = %scan(&var, &i, ' ');
	%let type = %GetVarType(&data_name, &vari);
	%if %upcase(&type) = N %then
		%let numvar = &numvar &vari;
	%else %if %upcase(&type) = C %then
		%let charvar = &charvar &vari;
%end;

%let nro_numvars = %GetNroElements(&numvar);
%let nro_charvars = %GetNroElements(&charvar);
data _mv_missing_(	keep=&by var type n nmiss pcntmiss
				%if %quote(&ValueType) ~= %then %do; n&valuename pcnt&valuename %end;);
	format &by var type n nmiss pcntmiss;

	%if %quote(&ValueType) ~= %then %do;
	format n&valuename pcnt&valuename;
	%end;

	set &data end=_lastobs_;

	%if %quote(&by) ~= %then %do;
	by &by;
	%end;

	format pcntmiss percent7.1;

	%if %quote(&ValueType) ~= %then %do;
	format pcnt&valuename percent7.1;
	%end;

	%* Array to store the number of observations per BY variable value;
	array count_n{*} _countN1-_countN&nro_vars;
	retain _countN1-_countN&nro_vars 0;

	%if %quote(&by) ~= %then %do;
	if first.&lastby then
		do _i_ = 1 to dim(count_n);
			count_n(_i_) = 0;
		end;
	%end;
	%* Count number of observations per BY variable value;
	do _i_ = 1 to dim(count_n);
		count_n(_i_) = count_n(_i_) + 1;
	end;

	%if &nro_numvars > 0 %then %do;
		array numvar{*} &numvar;
		array count_miss_num{*} _count_miss_num1-_count_miss_num&nro_numvars;
		retain _count_miss_num1-_count_miss_num&nro_numvars 0;
		%if &ValueType = N %then %do;	%* Only create the array count_value_num when &value is numeric;
		array count_value_num{*} _countV1-_countV&nro_numvars;
		retain _countV1-_countV&nro_numvars 0;
		%end;
		%if %quote(&by) ~= %then %do;
		if first.&lastby then
			do _i_ = 1 to dim(numvar);
				count_miss_num(_i_) = 0;
				%if &ValueType = N %then %do;
				count_value_num(_i_) = 0;
				%end;
			end;
		%end;
		do _i_ = 1 to dim(numvar);
			if numvar(_i_) = . then	count_miss_num(_i_) = count_miss_num(_i_) + 1;
			%if &ValueType = N %then %do;	%* Only compare the variable with &value when &value is numeric;
			if numvar(_i_) = &value then count_value_num(_i_) = count_value_num(_i_) + 1;
			%end;
		end;
	%end;
	%if &nro_charvars > 0 %then %do;
		array charvar{*} &charvar;
		array count_miss_char{*} _count_miss_char1-_count_miss_char&nro_charvars;
		%if &ValueType = C %then %do;		%* Only create the array count_value_char when &value is character;
		array count_value_char{*} _countV1-_countV&nro_charvars;
		retain _countV1-_countV&nro_charvars 0;
		%end;
		retain _count_miss_num1-_count_miss_num&nro_numvars 0;
		retain _count_miss_char1-_count_miss_char&nro_charvars 0;
		%if %quote(&by) ~= %then %do;
		if first.&lastby then
			do _i_ = 1 to dim(charvar);
				count_miss_char(_i_) = 0;
				%if &ValueType = C %then %do;
				count_value_char(_i_) = 0;
				%end;
			end;
		%end;
		do _i_ = 1 to dim(charvar);
			if charvar(_i_) = "" then count_miss_char(_i_) = count_miss_char(_i_) + 1;
			%if &ValueType = C %then %do;	%* Only compare the variable with &value when &value is character;
			if charvar(_i_) = "&value" then count_value_char(_i_) = count_value_char(_i_) + 1;
			%end;
		end;
	%end;

	%if %quote(&by) ~= %then %do;
	if last.&lastby then do;
	%end;
	%else %do;
	if _lastobs_ then do;
	%end;
		%if &nro_numvars > 0 %then %do;
		do _i_ = 1 to dim(numvar);
			var = vname(numvar(_i_));
			type = "N";
			nmiss = count_miss_num(_i_);
			n = count_n(_i_);
			pcntmiss = nmiss / n;
			%if %quote(&ValueType) ~= %then %do;
				%if &ValueType = N %then %do;
					n&valuename = count_value_num(_i_);
					pcnt&valuename = n&valuename / n;
				%end;
				%else %do;
					n&valuename = .;
					pcnt&valuename = .;
				%end;
			%end;
			output;
		end;
		%end;
		%if &nro_charvars > 0 %then %do;
		do _i_ = 1 to dim(charvar);
			var = vname(charvar(_i_));
			type = "C";
			nmiss = count_miss_char(_i_);
			n = count_n(_i_);
			pcntmiss = nmiss / n;
			%if %quote(&ValueType) ~= %then %do;
				%if &ValueType = C %then %do;
					n&valuename = count_value_char(_i_);
					pcnt&valuename = n&valuename / n;
				%end;
				%else %do;
					n&valuename = .;
					pcnt&valuename = .;
				%end;
			%end;
			output;
		end;
		%end;
	end;
	drop _i_;
run;

%callmacro(getnobs, _mv_missing_ return=1, nobs nvar); 
%if %quote(&out) ~= %then %do;
	%let out_name = %scan(&out, 1, '(');
	data &out;
		set _mv_missing_;
	run;
	proc datasets nolist;
		delete _mv_missing_;
	quit;

	%if &log %then
		%put MISSINGVALUES: Output dataset %upcase(&out_name) created with &nobs observations and &nvar variables.;
%end;
%else %if &log %then
	%put MISSINGVALUES: Output dataset _MV_MISSING_ created with &nobs observations and &nvar variables;

proc datasets nolist;
	delete _mv_data_;
quit;

%if &log %then %do;
	%put;
	%put MISSINGVALUES: Macro ends;
	%put;
%end;

%ResetSASOptions;
%MEND MissingValues;
