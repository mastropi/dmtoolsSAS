/* MACRO %FreqMult
Version: 		2.02
Author: 		Daniel Mastropietro
Created: 		15-Oct-2004
Modified: 		17-May-2016 (previous: 05-Aug-2015)
SAS Version:	9.4

DESCRIPTION:
This macro computes the frequencies of a list of variables (using PROC FREQ) and stores the
results in an output dataset containing the frequencies of all the variables.
Optionally the variables can be analyzed crossed against a target variable.

The analyzed variables can be either character, numeric or of both types in the same analysis.

By default missing values are NOT treated as a valid value in the computations of the percents.

The output dataset can be either long (i.e. one row per value of the variables) or wide (i.e. one row
per variable).

USAGE:
%FreqMult(
	data,					*** Input dataset.
	target=,				*** Target variable to cross the variables VAR with.
	var=_ALL_,				*** List of variables to analyze.
	by=,					*** List of BY variables.
	formats=,				*** Formats to use for selected analysis variables and/or target variable.
	out=_FreqMult_,	    	*** Output dataset containing the frequencies.
	options=,				*** Options for the TABLES statement.
	missing=0,				*** Missing values are valid values?
	transpose=0,			*** Transpose output dataset so that there is one record per variable?
	maxlengthvalues=255,	*** Initial length to assign to the VALUES column holding the values taken by the variable
							*** in the transposed output case.
	notes=1,				*** Show SAS notes in the log?
	log=1);					*** Show messages in the log?

REQUIRED PARAMETERS:
- data:			Input dataset. Data options can be specified as in a data= SAS option.

OPTIONAL PARAMETERS:
- target:			Target variable to cross the variables VAR with.

- var:				Blank-separated list of variables to analyze.

- by:				List of BY variables, by which the frequency analysis is done.

- formats:			Formats to use for selected analysis variables listed in VAR and/or for the TARGET variable.
					This statement can be used to define groups.
					The output dataset is sorted by the formatted values of each formatted analysis variable.
					The formats should be specified as in any FORMAT statement.
					Ex:
					var1 varf.
					var2 varg.

- out:				Output dataset, containing the frequencies of each variable listed in 'var'.
					The dataset is sorted by analyzed variable, BY variables and target variable.
					Note that this is NOT the usual order used by other SAS procedures which first sort
					the output data by the BY variables, but in this case it is believed that it is of
					greater importance to compare BY groups within each analyzed variable.
					Despite of this sorting, the BY variables are always placed at the initial columns.
					Data options can be specified as in a data= SAS option.
					The dataset has the following columns:
					LONG FORMAT (TRANSPOSE=0):
					- <by-variables> if any.
					- var:				Variable name corresponding to the frequencies shown.
					- type:				Variable type ("character" or "numeric").
					- value(*):			Value taken by the variable when all variables are of the same type.
					- numvalue(*): 		Values taken by the variable, if numeric.
					- charvalue(*):		Values taken by the variable, if character.
					- formattedvalue(+):(CHAR) Formatted values taken by any formatted analysis variables.
					- <target variable> if any.
					- nvalues: 			Number of different values taken by the variable.
					- nobs:				Number of observations used in computations.
					- count: 			COUNT variable generated by PROC FREQ.
					- percent: 			PERCENT variable generated by PROC FREQ.
					(*) If all the variables are character or all the variables are numeric,
					then only the VALUE column is present. Otherwise, the columns NUMVALUE and
					CHARVALUE are present and VALUE is not.
					(+) The FORMATTEDVALUE colun is only present when at least one analysis variable
					has a format defined.

					WIDE FORMAT (TRANSPOSE=1):
					- var:					Variable name corresponding to the frequencies shown.
					- type:					Variable type ("character" or "numeric").
					- values:				List of (formatted(*)) values taken by the variable separated by columns.
					- <target variable> if any.
					(*) The values stored in the VALUES column are the formatted values if the
					analysis variable has a format defined.

					default: _FreqMult_

- options:			Options for the TABLES statement.
					Note: If statistics options (such as Chisq) are specified, they are NOT
					generated in the output dataset, because the output dataset only contains the
					frequency distribution for each variable.

- missing:			Whether the missing values should be considered as valid variable values
					for the percent calculations.
					Possible values: 0 => Missing values are NOT valid values
									 1 => Missing values are valid values
					default: 0

- transpose			Transpose output dataset so that there is one record per variable?
					default: 0

- maxlengthvalues 	Initial length to assign to the VALUES column holding the values taken by the
					variable so that no value is lost.
					This parameter can be increased in order to avoid truncation in the output values
					if the number of different values taken by a variable is too large.
					This parameter is used only when TRANSPOSE=1.
					Possible values: any positive integer value <= 32,767
					default: 255

- notes:			Indicates whether to show SAS notes in the log.
					The notes are shown only for the PROC MEANS step.
					Possible values: 0 => No, 1 => Yes.
					default: 0

- log:				Show messages in the log?
					Possible values: 0 => No, 1 => Yes
					default: 1

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Callmacro
- %FindInList
- %GetDataOptions
- %Getnobs
- %GetLibraryName
- %GetNroElements
- %GetStat
- %GetVarList
- %RemoveRepeated
- %ResetSASOptions
- %SetSASOptions

SEE ALSO:
- %Freq

EXAMPLES:
1.- %FreqMult(test, var=xnum ynum zchar, out=test_freq);
This computes the frequencies of the values taken by the variables XNUM, YNUM and ZCHAR and
stores the result in dataset TEST_FREQ.
Assuming that variables XNUM and YNUM are numeric and that variable ZCHAR is character, two
columns are created in dataset TEST_FREQ containing the values taken by the variables:
NUMVALUE, for the values taken by XNUM and YNUM, and CHARVALUE, for the values taken by ZCHAR.

2.- %FreqMult(test, var=xnum ynum zchar, out=test_freq(keep=var numvalue charvalue percent), missing=1);
Same as above, but missing values are now considered as valid variable values.
In addition only the variables VAR, NUMVALUE, CHARVALUE and COUNT are kept in the output
dataset.

3.- %FreqMult(test, by=group, var=xnum ynum zchar, formats=xnum fxnum. zchar $fzchar., transpose=1, out=test_freq);
This computes the frequencies of the values taken by the variables XNUM, YNUM and ZCHAR by each value
of the BY variable GROUP and stores the results in dataset TEST_FREQ after transposing the output get
one record per BY group and analysis variable value.
Variables XNUM and ZCHAR have a format and their formatted values are shown in the VALUES column
of the output dataset (instead of the original ones).
*/
&rsubmit;
%MACRO FreqMult(data,
				target=,
				var=_ALL_,
				by=,
				formats=,
				out=_FreqMult_,
				options=,
				missing=0,
				transpose=0,
				maxlengthvalues=255,
				notes=0,
				log=1,
				help=0) / store des="Creates a dataset with the frequencies of a set of variables";
/* PENDIENTE:
- (21/3/05) Agregar un parametro OUTSTAT= que genere un dataset con los estadisticos
solicitados en el parametro OPTIONS= (como Chisq por ej.), ya que en el OUT= dataset
se genera la distibucion de cada variable, no los estadisticos. Para generar el OUTSTAT=
dataset hay que reformular la aplicacion del PROC FREQ para cada variable, ya que es
necesario aplicarlo a cada una de las variables por separado ya que el OUTPUT statement
(que es el que debe usarse para guardar la informacion de los estadisticos solicitados)
aplica solamente a la ultima variable analizada con el TABLES statement.
*/

%* These variables are declared here because they are needed before the call to %CheckInputParameters;
%local by_orig;			%* Temporal list of by variables including any DESCENDING keyword;
%local byvarlist;		%* List of by variables without any DESCENDING keyword;
%local data_options;
%local error;

/*----- Macro to display usage -----*/
%MACRO ShowMacroCall;
	%put;
	%put FREQMULT: The macro call is as follows:;
	%put;
	%put %nrstr(%FreqMult%();
	%put data , (REQUIRED) %quote(      *** Input dataset.);
	%put target= , %quote(              *** Target dichotomous variables.);
	%put var=_ALL_ , %quote(            *** Analysis variables.);
	%put by= , %quote(                  *** List of BY variables.);
	%put formats= , %quote(             *** Formats to be used for selected analysis variables.);
	%put out=_FreqMult_ , %quote(       *** Output dataset containing the values taken by each analysis);
	%put %quote(                        *** variables, its counts and its frequencies.);
	%put %quote(transpose=0 ,           *** Transpose output dataset so that there is one record per variable?);
	%put %quote(maxlengthvalues=255 ,   *** Initial length to assign to the VALUES column holding the values taken by the variable);
	%put %quote(                        *** in the transposed output case.);
	%put options= ,	%quote(     *** Options for the TABLES statement in PROC FREQ.);
	%put missing=0 , %quote(            *** Should missing values be considered as valid values?);
	%put notes=1 , %quote(              *** Show SAS notes in the log?);
	%put log=1) %quote(                 *** Show messages in the log?);
%MEND ShowMacroCall;
/*----- Macro to display usage -----*/

%if &help %then %do;
	%ShowMacroCall;
%end;
%else %do;
%* Checking existence of input datasets and existence of variables in datasets;
%let error = 0;
%let data_options = %GetDataOptions(%quote(&data));
%if ~%index(%quote(%upcase(&data_options)), RENAME) %then %do;
	%* The check is done only if there is no RENAME option in the specification of the dataset;
	%if %quote(&by) ~= %then %do;
		%let by_orig = &by;
		%* Remove from the list of BY variables the keyword DESCENDING in case it exists,
		%* otherwise the macro %CheckInputParameters will report the non-existence of variable DESCENDING...;
		%let by = %RemoveFromList(%quote(&by), descending, log=0);
	%end;
	%if ~%CheckInputParameters(data=&data , var=&var , check=target by, macro=FREQMULT) %then %do;
		%ShowMacroCall;
		%let error = 1;
	%end;
	%* Re-establish the content of the BY parameter, in case the DESCENDING option existed, which was removed above
	%* before calling %CheckInputParameters;
	%else %do;
		%let byvarlist = &by;
		%let by = &by_orig;
	%end;
%end;
%if ~&error %then %do;
/************************************* MACRO STARTS ******************************************/
%local i;
%local nro_vars nvalues vari vartype vartypei;
%local nobs nvar;
%local maxlength;			%* Maximum length of analyzed variable names;
%local byst;
/*%local nro_byvars;		%* Descomentar si creo un indice en el PROC SORT del comienzo del codigo; */
%local missingopt;			%* Option in the tables statement of the PROC FREQ stating whether
							%* missing values should be considered in the computations;
%*** Macro variables related to variable formats;
%local format_target;		%* Possible format for the target variable;
%local hasformat;			%* List of flags indicating which variables have formats defined;
%local atleast1format;
%local formati;				%* Format name to apply to each analyzed variable;
%local pos;					%* Position of the analyzed variable &VARI in the list of formats given in &FORMAT;
%local maxlengthformattedvalues;
%local maxlengthformattedvaluesi;
%*** Macro variables related to variable types;
%local bothTypes type;
%*** Macro variables related to output dataset;
%local out_name library;	%* Name of output dataset and library where it is created.
							%* The library is necessary because the output dataset
							%* is deleted with a PROC DATASETS at the beginning and
							%* this gives an error if I do not parse the library name;
%local varorder;
%local varlenchk_opt;

%SetSASOptions(notes=&notes);

%* Show input parameters;
%if &log %then %do;
	%put;
	%put FREQMULT: Macro starts;
	%put;
	%put FREQMULT: Input parameters:;
	%put FREQMULT: - Input dataset = %quote(    &data);
	%put FREQMULT: - target = %quote(           &target);
	%put FREQMULT: - var = %quote(              &var);
    %put FREQMULT: - by = %quote(               &by);
	%put FREQMULT: - formats = %quote(          &formats);
	%put FREQMULT: - out = %quote(              &out);
	%put FREQMULT: - options = %quote(          &options);
	%put FREQMULT: - missing = %quote(          &missing);
	%put FREQMULT: - transpose = %quote(        &transpose);
	%put FREQMULT: - maxlengthvalues = %quote(  &maxlengthvalues);
	%put FREQMULT: - notes = %quote(            &notes);
	%put FREQMULT: - log = %quote(              &log);
	%put;
%end;

/*----- Parsing input parameters -----*/
%*** DATA;
%if &log %then %do;
	%put FREQMULT: Reading input dataset...;
	%put;
%end;

%*** BY=;
%let byst = ;
%if %quote(&by) ~= %then %do;
/*	%let nro_byvars = %GetNroElements(%quote(&by));		* Descomentar si creo el indice; */
	proc sort data=&data out=_FreqMult_data_(keep=&var &byvarlist &target
	/*  Creacion de indice: (14/06/06) Por ahora comento la creacion del indice porque parece que tarda mas usar indice que no usarlo.
		Al menos en el ejemplo de una sola BY variable que estuve probando.
		Por otra parte, la forma de usar el indice es NO ORDENAR POR LAS BY VARIABLES sino simplemente crear
		el indice a partir de las BY variables. Si ordeno por las BY variables, el indice no es usado en BY processing
		aun cuando al ordenar cree el indice.
											 %if &nro_byvars = 1 %then %do;
												index=(&by) %end;
											%else %do;
												index=(byvar=(&by)) %end; */	);
		by &by;
	run;
	%let byst = by &by;
%end;
%else %do;
	data _FreqMult_data_(keep=&var &target);
		set &data;
	run;
%end;

%*** VAR=;
%let var = %GetVarList(_FreqMult_data_, var=&var, log=0);
%let nro_vars = %GetNroElements(&var);

%*** OUT=;
%if %quote(&out) ~= %then %do;
	%let out_name = %scan(&out, 1, '(');
	%let library = %GetLibraryName(&out_name);
	%if %index(&out_name, .) > 0 %then
		%let out_name = %scan(&out_name, 2, '.');
%end;
%* Delete dataset used as base dataset in PROC APPEND when transpose=1 in case it exists;
proc datasets nolist;
	delete _FreqMult_out_;
quit;

%*** MISSING=;
%let missingopt = ;
%if &missing %then
	%let missingopt = missing;
/*------------------------------------*/

%* PROC CONTENTS of variables to get their lengths;
proc contents data=_FreqMult_data_ out=_FreqMult_pc_ noprint;
run;
%* Length of numeric variables;
%GetStat(_FreqMult_pc_(where=(type=1)), var=length, stat=max, name=_numlength_max_, log=0);
%* Length of character variables;
%GetStat(_FreqMult_pc_(where=(type=2)), var=length, stat=max, name=_charlength_max_, log=0);

%let maxlength = 0;
%let vartype = ;
proc freq data=_FreqMult_data_ noprint;
	%* Check if the target variable has a format and if so apply it;
	%if %quote(&target) ~= and %quote(&formats) ~= %then %do;
		%* Look for the target variable name in the list of formats;
		%let pos = %FindInList(&formats, &target, log=0);
		%if &pos > 0 %then %do;
			%* Get the format name to use for the current variable from the (POS+1)-th word in &FORMAT;
			%* Note that the format name contains the dot at the end already;
			%let format_target = %scan(&formats, %eval(&pos+1), ' ');
			format &target &format_target;
		%end;
	%end;
	%* Go over each analysis variable and request a frequency table;
	%do i = 1 %to &nro_vars;
		%let vari = %scan(&var, &i, ' ');
		%* Update maximum length of variable name;
		%let maxlength = %sysfunc(max(&maxlength, %length(&vari)));
		%* Read variable type (character or numeric);
		%let vartypei = %upcase(%GetVarType(_FreqMult_data_, &vari));
		%let vartype = &vartype &vartypei;
		%if &vartypei = C %then
			%let type = char;
		%else
			%let type = num;

		%if %quote(&formats) ~= %then %do;
			%* Look for the currently analyzed variable name in the list of formats;
			%let pos = %FindInList(&formats, &vari, log=0);
			%if &pos > 0 %then %do;
				%* Get the format name to use for the current variable from the (POS+1)-th word in &FORMAT;
				%* Note that the format name contains the dot at the end already;
				%let formati = %scan(&formats, %eval(&pos+1), ' ');
				format &vari &formati;
				%let hasformat = &hasformat 1;
			%end;
			%else
				%let hasformat = &hasformat 0;
		%end;

		&byst;

		%if %quote(&target) ~= %then %do;
		tables &vari*&target / &options &missingopt out=_FreqMult_out&i(rename=(&vari=&type.value));
		%end;
		%else %do;
		tables &vari / &options &missingopt out=_FreqMult_out&i(rename=(&vari=&type.value));
		%end;

		%if &log %then
			%put FREQMULT: Computing frequencies of variable %upcase(&vari)...;
	%end;
run;
%* Keep track whether at least one analyzed variable has a format;
%let atleast1format = %eval(%index(&hasformat, 1) > 0);
%if &atleast1format %then
	%* Create a variable that is used to shrink the value of the FORMATTEDVALUE variable in the output dataset to its minimum possible value;
	%let maxlengthformattedvalues = 0;

%* Check if variables of both types (i.e. character and numeric) where analyzed. This affects
%* the name of the variable containing the freq values and whether it is necessary (in case
%* both types are analyzed) to add a variable (named either CHARVALUE or NUMVALUE)
%* containing missing values to the dataset created for each analyzed variable, so that the
%* PROC APPEND that generates the output dataset does not give an error;
%if %GetNroElements(%RemoveRepeated(&vartype, log=0)) = 1 %then
	%let bothTypes = 0;
%else
	%let bothTypes = 1;

%* Create output dataset;
%if &log %then %do;
	%put;
	%put FREQMULT: Appending tables into %upcase(&out)...;
%end;
proc datasets library=&library nolist;
	delete &out_name;
quit;
%do i = 1 %to &nro_vars;
	%let vari = %scan(&var, &i, ' ');
	%* Number of different values found in varible &var;
	%Callmacro(getnobs, _FreqMult_out&i return=1, nvalues);
	%* Number of observations used in computations (i.e. sum of COUNT);
	proc means data=_FreqMult_out&i sum noprint;
		%if ~&missing %then %do;
		where percent ~= .;		%* Exclude the missing values from the count of nro. of obs
								%* This assumes that the variable PERCENT is kept in the output dataset
								%* (which should usually or always be the case). I do not use
								%* the value of the variable because I need to check again for
								%* the TYPE of the variable (C or N) since the name of the
								%* variable containing the values taken by the variable analyzed
								%* is &type.value;
		%end;
		var count;
		output out=_FreqMult_means_(drop=_TYPE_ _FREQ_) sum=nobs;
	run;
	data _FreqMult_out&i;
		%* Define the order of the variables and their lengths;
		format &byvarlist var type;
		length type $10;
		%if &atleast1format %then %do;
		%* Keep track of the length of the formatted values so that we can shorten its value to its minimum next;
		retain _maxlengthformattedvalues 0;
		%end;
		%if &bothTypes %then %do;
			%if %scan(&vartype, &i, ' ') = C %then
				%let type = char;
			%else
				%let type = num;
			format numvalue best12.;	%* This format is to avoid showing ** when the format is not long enough for the variables value (eg 2. instead of 8.);
			format charvalue;
			%* Define the lengths of numeric and character variables to avoid truncation;
			length numvalue &_numlength_max_;
			length charvalue $&_charlength_max_;
		%end;
		%else %do;
			%if %scan(&vartype, &i, ' ') = C %then %do;
				length value $&_charlength_max_;		%* This is to avoid the message VARIABLE VALUE HAS DIFFERENT LENGTHS ON BASE AND DATA FILE in the PROC APPEND below;
				format value $&_charlength_max_..;
			%end;
			%else %do;
				length value &_numlength_max_;			%* This is to avoid the message VARIABLE VALUE HAS DIFFERENT LENGTHS ON BASE AND DATA FILE in the PROC APPEND below;
				format value best12.;	%* This format is to avoid showing ** when the format is not long enough (eg 2. instead of 8.);
			%end;
		%end;
		%* Create the formatvalue variable if at least one format was specified;
		%if &atleast1format %then %do;
			%* Set the length of FORMATVALUE to a very large one. Then we will shrinken its length to the minimum possible;
			%* The name formatTEDvale is used (instead of e.g. formatvalue) to mimic how SAS indicates things like e.g. order=formatTED;
			length formattedvalue $255;
			format formattedvalue $255.;
		%end;
		format &target nvalues nobs;

		set _FreqMult_out&i
			(%if ~&bothTypes %then %do; rename=(&type.value=value) %end;) end=lastobs;
			%** Note that in case only one type of variable is analyzed (i.e. character or
			%** numeric), the name used for the variable containing the freq values
			%** is VALUE (not CHARVALUE or NUMVALUE as is the case when both types are present).
			%** Note also that in that case the value of &TYPE is the same for all variables (either char or num);
		if _N_ = 1 then set _FreqMult_means_;
		format percent 7.2;
		length var $&maxlength;
		var = "&vari";
		%if %scan(&vartype, &i, ' ') = C %then %do;
			type = "character";
		%end;
		%else %do;
			type = "numeric";
		%end;
		%* Compute the formatted value;
		%if &atleast1format %then %do;
			%* Check if the current variable VARI has a format specified when calling %FreqMult;
			%if %scan(&hasformat, &i, ' ') = 1 %then %do;
				%* Get the format name;
				%let pos = %FindInList(&formats, &vari, log=0);
				%let formati = %scan(&formats, %eval(&pos+1), ' ');
				%if ~&bothTypes %then %do;
					formattedvalue = put(value, &formati);
				%end;
				%else %do;
					formattedvalue = put(&type.value, &formati);
				%end;
				_maxlengthformattedvalues = max(_maxlengthformattedvalues, length(formattedvalue));
			%end;
		%end;
		%* Number of different values found for current variable;
		nvalues = &nvalues;
		label 	var = "Variable Name"
				type = "Variable Type"
				%if &bothTypes %then %do;
				numvalue = "Value taken by numeric variables"
				charvalue = "Value taken by character variables"
				%end;
				%if &atleast1format %then %do;
				formattedvalue = "Formatted value"
				%end;
				%if %quote(&target) ~= %then %do;
				nvalues = "Number of Combinations"
				%end;
				%else %do;
				nvalues = "Number of Different Values"
				%end;
				nobs = "Total Number of Valid Observations";
		%if &atleast1format %then %do;
			if lastobs then
				call symput('maxlengthformattedvaluesi', _maxlengthformattedvalues);
			drop _maxlengthformattedvalues;
		%end;
	run;
	%if &atleast1format %then
		%let maxlengthformattedvalues = %sysfunc(max(&maxlengthformattedvalues, &maxlengthformattedvaluesi));

	%*** Append the results of the current variable to the output dataset with al the analyzed variables;
	%* NOTE: The output dataset is sorted by VAR and then by the BY variables;
	proc append base=_FreqMult_out_ data=_FreqMult_out&i force;
	run;
%end;

%*** Create the output dataset and transpose the data if requested;
%if &transpose %then %do;
	%* Sort by VAR, <BY variables>, <TARGET variable>, which is needed for the transpose process;
	proc sort data=_FreqMult_out_;
		by var &by &target;
	run;
	%* Create a single column containing all the frequency values;
	data _FreqMult_out_;
		%* Note that we do not keep any COUNT or PERCENT variables because these would only make sense when there is a target variable
		%* but taking that case into account is too cumbersome and not worth it at this point;
		keep &byvarlist var type values &target;
		format &byvarlist var type values &target;
		set _FreqMult_out_(keep=&byvarlist var type &target %if &bothTypes %then %do; charvalue numvalue %end; %else %do; value %end;
															%if &atleast1format %then %do; formattedvalue %end;) end=lastobs;
		by var &by &target;
		length valuec values $&maxlengthvalues;	%* valuec stores the value of the variable as character, variable values stores all the values taken by the variable;
		retain values;				%* This variable contains all the concatenated values taken by each variable;
		retain maxlengthvalues;		%* This variable is used to measure the maximum length of the VALUES variable;

		%* Read the current variable value (depending on the value of &bothTypes this is read from different variables);
		%if &bothTypes %then %do;
		if type = "character" then do;
			%* Define the value to transpose: we should use the formattedvalue when it is not missing (meaning that the variable has a format defined);
			%if &atleast1format %then %do;
			if not missing(formattedvalue) then
				_charvalue = formattedvalue;
			else
				_charvalue = charvalue;
			%end;
			%else %do;
			_charvalue = charvalue;
			%end;
			if missing(_charvalue) then
				valuec = "<Miss>";
			else
				valuec = _charvalue;
		end;
		else
			%* Store the numeric value as character;
			%* Note that, regarding formatted values, I cannot apply the same logic as above for character values
			%* because variable FORMATTEDVALUE is character while variable NUMVALUE is numeric...;
			%* Note also that when &ATLEAST1FORMAT = 1 I additionally check for MISSING(FORMATTEDVALUE) in the
			%* first IF below that checkes for missing(NUMVALUE) because formatted values (of numeric variables at least)
			%* NEVER take missing values, as e.g. the original missing value . is converted to . as a character, and
			%* therefore is not missing. So, when checking for MISSING(formattedvalue) we are actually checking that the
			%* variable does NOT have a format and therefore we can check for missing(NUMVALUE) in order to assign <Miss> to VALUEC;
			if %if &atleast1format %then %do; missing(formattedvalue) and %end; missing(numvalue) then
				valuec = "<Miss>";
			else
				%if &atleast1format %then %do;
				if not missing(formattedvalue) then
					valuec = formattedvalue;
				else
				%end;
					valuec = trim(left(put(numvalue, best12.)));
		%end;
		%else %do;
		%* When all the variables are of the same type we follow the same logic as for numeric variables
		%* as we do not know the type of VALUE (whether character or numeric);
		if %if &atleast1format %then %do; missing(formattedvalue) and %end; missing(value) then
			valuec = "<Miss>";
		else
			%if &atleast1format %then %do;
			if not missing(formattedvalue) then
				valuec = formattedvalue;
			else
			%end;
				valuec = trim(left(put(value, best12.)));
		%end;

		%* Start a new group;
		if %MakeList(var &byvarlist &target, prefix=First., sep=or) then
			values = valuec;
		else
			values = catx(", ", values, valuec);

		%* Output the last occurrence of the current group;
		if %MakeList(var &byvarlist &target, prefix=Last., sep=or) then do;
			%* Update the macro variable containing the maximum length of the VALUES variable (in order to shorten it as much as possible at the end);
			maxlengthvalues = max(maxlengthvalues, length(values));	%* Note that the LENGTH() function computes the length of the variable value without taking into account the blanks at the end;
			output;
		end;
		if lastobs then
			%* Store the length of variable VALUES;
			call symput ('maxlengthvalues', maxlengthvalues);
	run;

	%*** Create the final output dataset ad update the length of the VALUES variable to its shortest possible length (based on the actual used space);
	%GetVarOrder(_FreqMult_out_, varorder);
	%let varlenchk_opt = %sysfunc(getoption(varlenchk));
	%* Set the option that checks variable length change to no-warning, o.w. there is a warning that data may have been truncated;
	options varlenchk=nowarn;
	data &out;
		format &varorder;
		length values $&maxlengthvalues;	%* Shorten the length of the VALUES variable as much as possible based on the data;
		set _FreqMult_out_;
	run;
	options varlenchk=&varlenchk_opt;
%end;
%else %do;
	%if &atleast1format %then %do;
		%*** Compress the length of the FORMATTEDVALUE variable to its possible minimum;
		%* Set the option that checks variable length change to no-warning, o.w. there is a warning that data may have been truncated;
		%let varlenchk_opt = %sysfunc(getoption(varlenchk));
		options varlenchk=nowarn;
		data _FreqMult_out_;
			format &byvarlist var type %if &bothTypes %then %do; charvalue numvalue %end; %else %do; value %end; formattedvalue;
			length formattedvalue $&maxlengthformattedvalues;
			format formattedvalue $&maxlengthformattedvalues..;
			set _FreqMult_out_;
		run;
		options varlenchk=&varlenchk_opt;
	%end;

	%* Sort by VAR, <BY variables>, value of variable, <TARGET variable>, and create the final output datset;
	%* Note that the value of the variable comes before the TARGET variable in the sort order because this is the way
	%* it is sorted by PROC FREQ of <var>*<target>;
	proc sort data=_FreqMult_out_ out=&out;
		by var &by %if &atleast1format %then %do; formattedvalue %end; %if &bothTypes %then %do; charvalue numvalue %end; %else %do; value %end; &target;
	run;
%end;

%if &log %then %do;
	%Callmacro(getnobs, &out return=1, nobs nvar);
	%put FREQMULT: Dataset %upcase(&out) created with &nobs observations and &nvar variables.;
%end;

%* Delete global macro variables created by %GetStat;
%symdel _numlength_max_ _charlength_max_;
quit;	%* To avoid problems with %symdel;

proc datasets nolist;
	%do i = 1 %to &nro_vars;
		delete _FreqMult_out&i;
	%end;
	delete 	_FreqMult_data_
			_FreqMult_Means_
			_FreqMult_pc_
			_FreqMult_out_;
quit;

%if &log %then %do;
	%put;
	%put FREQMULT: Macro ends;
	%put;
%end;

%ResetSASOptions;

%end;	%* %if ~&error;

%end;	%* %if &help;
%MEND FreqMult;
