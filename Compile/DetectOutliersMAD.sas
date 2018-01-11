/* MACRO %DetectOutliersMAD
Version: 1.01
Author: Daniel Mastropietro
Created: 1-Feb-05
Modified: 7-Nov-05

DESCRIPTION:
This macro detects univariate outliers using the MAD method.

USAGE:
%DetectOutliersMAD(
	data,
	var=_NUMERIC_,
	condition=,		*** Condition to be satisfied by each analysis variable in order to be considered
					*** in the outlier detection. The keyword BETWEEN can be used as in BETWEEN 0 AND 2.
	multiplier=9,
	nameOutlier=outlier,
	prefix=o_,
	out=,
	outmad=,		*** NOTE: The variables are listed in alphabetical order not in the order
					*** they were passed to the macro in parameter VAR.
	macrovar=,		*** Name of macro variable where the list of variables indicating the outliers
					*** for each analysis variable is stored.
	log=1);

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Callmacro
- %Getnobs
- %GetNroElements
- %GetVarList
- %GetVarOrder
- %MakeList
- %MakeListFromVar
- %ResetSASOptions
- %SetSASOptions

EXAMPLES:
%let var = ALL_SDO_SUM CC_ANT_MAX_HIST CC_PMI_SDO_DIV;
%DetectOutliersMAD(temp, var=&var, condition=>0, out=temp2, macrovar=list_outliers);
%DetectOutliersMAD(temp, var=&var, condition=not between -1 and 0, out=temp2, macrovar=list_outliers);
*/
&rsubmit;
%MACRO DetectOutliersMAD(	data,
					  		var=_NUMERIC_,
							condition=,
							multiplier=9,
							nameOutlier=outlier,
							prefix=o_,
							out=,
							outmad=_DOM_MAD_,
							macrovar=,
							log=1,
							help=0) / store des="Univariate outlier detection with the MAD criterion";
/*----- Macro to display usage -----*/
%MACRO ShowMacroCall;
	%put DETECTOUTLIERSMAD: The macro call is as follows:;
	%put %nrstr(%DetectOutliersMAD%();
	%put data , (REQUIRED) %quote(      *** Input dataset.);
	%put var=_NUMERIC_ , %quote(        *** Analysis variables.);
	%put condition= , %quote(           *** Condition used to filter observations for each variable.);
	%put multiplier=9 , %quote(         *** Multiplier for the MAD to flag a value as an outlier.);
	%put nameOutlier=outlier , %quote(  *** Name for the variable that flags the outliers.);
	%put prefix=o_ , %quote(            *** Prefix for the variables that flag the outliers in each variable.);
	%put out= , %quote(                 *** Output dataset.);
	%put outmad= , %quote(              *** Output dataset with the median, the MAD and the thresholds info.);
	%put macrovar= , %quote(            *** Macro variable with the list of the outlier indicator variables.);
	%put log=1) , %quote(               *** Show messages in the log?);
%MEND ShowMacroCall;

%if &help %then %do;
	%ShowMacroCall;
%end;
%else %if ~%CheckInputParameters(data=&data , var=&var , macro=DETECTOUTLIERSMAD) %then %do;
	%ShowMacroCall;
%end;
%else %do;
/************************************* MACRO STARTS ******************************************/
/* Local variables declaration */
%local _i_;
%local _vars_ _median_ _medians_ _MAD_ _MADS_ _nro_vars_ _var_order_ _var_;
%local _out_name_ _outmad_name_;
%local _nobs_ _nvar_;
%local _conditionstr_;

%SetSASOptions;

%* Showing input parameters;
%if &log %then %do;
	%put;
	%put DETECTOUTLIERSMAD: Macro starts;
	%put;
	%put DETECTOUTLIERSMAD: Input parameters:;
	%put DETECTOUTLIERSMAD: - Input dataset = %quote(&data);
	%put DETECTOUTLIERSMAD: - var = %quote(          &var);
	%put DETECTOUTLIERSMAD: - condition = %quote(    &condition);
	%put DETECTOUTLIERSMAD: - multiplier = %quote(   &multiplier);
	%put DETECTOUTLIERSMAD: - prefix = %quote(       &prefix);
	%put DETECTOUTLIERSMAD: - nameOutlier = %quote(  &nameOutlier);
	%put DETECTOUTLIERSMAD: - out = %quote(          &out);
	%put DETECTOUTLIERSMAD: - outmad = %quote(       &outmad);
	%put DETECTOUTLIERSMAD: - macrovar = %quote(     &macrovar);
	%put DETECTOUTLIERSMAD: - log = %quote(          &log);
	%put;
%end;

/*------------------------------ Parse Input Parameters -------------------------------------*/
%*** VAR=;
%let var = %GetVarList(&data, var=&var);

%*** OUT=;
%if %quote(&out) = %then
	%let out = &data;
%let _out_name_ = %scan(&out, 1, '(');
/*-------------------------------------------------------------------------------------------*/

data _DOM_data_(keep=&var);
	set &data;
run;

%* Retrieve the order in which the analysis variables appear in the dataset so that the
%* variables that flag the outliers are stored in the same order in the output dataset; 
%GetVarOrder(_DOM_data_, _var_order_);
%let var = &_var_order_;
%let _nro_vars_ = %GetNroElements(&var);

%* Compute MEDIAN and MAD for each variable;
%if %quote(&condition) ~= %then %do;
	%* Delete dataset where the append is done;
	proc datasets nolist;
		delete _DOM_MAD_ _DOM_Error_;
	quit;
	%do _i_ = 1 %to &_nro_vars_;
		%let _var_ = %scan(&var, &_i_, ' ');
		%* Parse CONDITION to check if it is of the form BETWEEN v1 AND v2, in which case
		%* the string is transformed to a regular condition that can be used in an IF clause.
		%* Note that I add an open parenthesis before the BETWEEN and a closing parenthesis
		%* after the between statement in case there is a NOT before the BETWEEN, because otherwise
		%* a condition such as NOT BETWEEN 0 AND 2, resulting in the condition NOT 0 <= x <= 2,
		%* will first execute the NOT and then the inequality operators, which is not what we want;
		%if %index(%upcase(&condition), BETWEEN) %then %do;
			%* Replace BETWEEN with an open parenthesis;
			%let _conditionstr_ = %sysfunc(tranwrd(%nrbquote(%upcase(&condition)), BETWEEN, %quote(%()));
			%* Replace the AND with a sandwich inequality operator, and add a closing parenthesis at the end;
			%let _conditionstr_ = %sysfunc(tranwrd(%nrbquote(%upcase(&_conditionstr_)), AND, <= &_var_ <=)) );
		%end;
		%else
			%let _conditionstr_ = &_var_ &condition;
		proc stdize data=_DOM_data_(where=(&_conditionstr_) keep=&_var_) 
					method=MAD 
					out=_NULL_ 
					outstat=_DOM_MAD_i_;
			%** Note the use of out=_NULL_. Otherwise, an output dataset is created with the
			%** standardized variables;
			var &_var_;
		run;
		%* Check if the output dataset _DOM_MAD_i_ has at least one observation. Sometimes,
		%* it may not contain any observation because of the where condition, and if this is
		%* the case, everything is screwed up;
		%Callmacro(getnobs, _DOM_MAD_i_ return=1, _nobs_);
		%if &_nobs_ > 0 %then %do;
			proc transpose data=_DOM_MAD_i_ out=_DOM_MAD_i_(rename=(COL1=median COL2=MAD COL3=n)) name=var;
				where upcase(_TYPE_) in ("N", "LOCATION", "SCALE");
			run;
			data _DOM_MAD_i_;
				format id var;
				length var $32;
				set _DOM_MAD_i_;
				id = &_i_;
			run;
		%end;
		%else %do;
			data _DOM_MAD_i_;
				format id var;
				length var $32;
				id = &_i_;
				var = "&_var_";
				median = .;
				MAD = .;
				n = 0;
			run;
		%end;
		data _NULL_;
			set _DOM_MAD_i_;
			call symput ('_median_', median);
			call symput ('_MAD_', MAD);
		run;
		%* Only append the information on the variable if both the median and the MAD are NOT missing;
/*		%if %sysevalf(&_median_ ~= .) and %sysevalf(&_MAD_ ~= .) %then %do;*/
		proc append base=_DOM_MAD_ data=_DOM_MAD_i_ FORCE;
		run;
/*		%end;*/
/*		%else %do;*/
/*			data _DOM_Error_i_;*/
/*				length var $32;*/
/*				var = "&_var_";*/
/*			run;*/
/*			proc append base=_DOM_Error_ data=_DOM_Error_i_ FORCE;*/
/*			run;*/
/*		%end;*/
	%end;
%end;
%else %do;
	%* All variables are analyzed together;
	proc stdize data=_DOM_data_(keep=&var)
				method=MAD
				out=_NULL_
				outstat=_DOM_MAD_;
		%** Note the use of out=_NULL_. Otherwise, an output dataset is created with the
		%** standardized variables;
		var &var;
	run;
	proc transpose data=_DOM_MAD_ out=_DOM_MAD_(rename=(COL1=median COL2=MAD)) name=var;
		where upcase(_TYPE_) in ("LOCATION", "SCALE");
	run;
	data _DOM_MAD_;
		format id;
		length id 4;
		set _DOM_MAD_;
		id = _N_;
	run;
%end;

%if %sysfunc(exist(_DOM_MAD_)) %then %do;
	%* Read the variable names, the medians and the MADs from the dataset _DOM_MAD_;
	%let _vars_= %MakeListFromVar(_DOM_MAD_, var=var, log=0);
	%let _medians_ = %MakeListFromVar(_DOM_MAD_, var=median, log=0);
	%let _MADS_ = %MakeListFromVar(_DOM_MAD_, var=MAD, log=0);
	%let _nro_vars_ = %GetNroElements(&_vars_);
	data &out;
		set &data;		%* Use &data and NOT _DOM_data_ because I want to set back all the
						%* variables in the input dataset;
		array vars{*} &_vars_;
		%* Define the length of the outlier indicator variables to 3 to save space;
		length %MakeList(&var, prefix=&prefix) 3;
		length &nameOutlier 3;
		&nameOutlier = .;	%* Set to missing initially in case none of the variables satisfy the
							%* condition specified in the CONDITION= parameter, so that there is
							%* no information about the observation being an outlier or not;
		_count_ = 0;		%* This variable counts the number of variables classified as
							%* outlier or non-outlier and is used to set the value of 
							%* &nameOutlier to 0 ONLY when ALL the variables passed in VAR are
							%* classified as non-outliers. Otherwise, if some variables are
							%* classified as non-outliers but others are not classified, then
							%* &nameOutlier is set to missing;
		%do _i_ = 1 %to &_nro_vars_;
			%let _var_ = %scan(&_vars_, &_i_, ' ');
			%let _median_ = %scan(&_medians_, &_i_, ' ');
			%let _MAD_ = %scan(&_MADS_, &_i_, ' ');
			if vars(&_i_) ~= . and &_median_ ~= . and &_MAD_ ~= . then do;
				%* Exclude the values that are excluded based on the CONDITION= parameter from
				%* the classification in outlier or not outlier;
				%if %quote(&condition) ~= %then %do;
				%* Parse CONDITION to check if it is of the form BETWEEN v1 AND v2, in which case
				%* the string is transformed to a regular condition that can be used in an IF clause.
				%* Note that I add an open parenthesis before the BETWEEN and a closing parenthesis
				%* after the between statement in case there is a NOT before the BETWEEN, because otherwise
				%* a condition such as NOT BETWEEN 0 AND 2, resulting in the condition NOT 0 <= x <= 2,
				%* will first execute the NOT and then the inequality operators, which is not what we want;
				%if %index(%upcase(&condition), BETWEEN) %then %do;
					%* Replace BETWEEN with an open parenthesis;
					%let _conditionstr_ = %sysfunc(tranwrd(%nrbquote(%upcase(&condition)), BETWEEN, %quote(%()));
					%* Replace the AND with a sandwich inequality operator, and add a closing parenthesis at the end;
					%let _conditionstr_ = %sysfunc(tranwrd(%nrbquote(%upcase(&_conditionstr_)), AND, <= vars(&_i_) <=)) );
				%end;
				%else
					%let _conditionstr_ = vars(&_i_) &condition;
				if &_conditionstr_ then do;
				%end;
					_count_ = _count_ + 1;	%* State that one more variable could be classified
											%* as outlier or non-outlier;
					%* Mark as outliers the values that are away from the MEDIAN further than
					%* &k times the MAD;
					if abs(vars(&_i_) - &_median_) > &multiplier * &_MAD_ then do;
						&nameOutlier = 1;
						&prefix&_var_ = 1;
					end;
					else do;
						if &nameOutlier ~= 1 and _count_ = &_nro_vars_ then
							&nameOutlier = 0;
						&prefix&_var_ = 0;
						%** Note that I do NOT set &nameOutlier = 0, because an outlier could have
						%** been detected on another variable, and setting &nameOutlier = 0 would
						%** reset the variable &nameOutlier to 0, when an outlier was detected on
						%** another variable;
					end;
				%if %quote(&condition) ~= %then %do;
				end;
				else
					&prefix&_var_ = .;
				%end;
			end;
			else
				&prefix&_var_ = .;
		%end;
		drop _count_;
	run;

	%if %quote(&outmad) ~= %then %do;
		%* Compute the number of outliers detected for each variable;
		%Means(&out, var=%MakeList(&_vars_, prefix=&prefix), stat=sum n nmiss, namevar=var, out=_DOM_Means_, transpose=1, log=0);
		data _DOM_Means_;
			format id;
			set _DOM_Means_(rename=(sum=count));
			id = _N_;
			%* Number of observations in the dataset in order to compute the percentage
			%* of outliers detected over ALL observations;
			nobs = n + nmiss;
			drop var;
		run;
		data &outmad;
			format id var nobs n count percent percentAll median MAD multiplier thr1 thr2;
			merge _DOM_MAD_ _DOM_Means_;
			by id;
			retain multiplier &multiplier;
			format percent percentAll percent7.1;
			percent = count / n;
			percentAll = count / nobs;
			Thr1 = median - &multiplier*MAD;
			Thr2 = median + &multiplier*MAD;
			label 	var 		= " "
					percent 	= "% of outliers over obs used"
					percentAll 	= "% of outliers over ALL obs";
		run;
		%if &log %then %do;
			%let _outmad_name_ = %scan(&outmad, 1, ' ');
			%callmacro(getnobs, &_outmad_name_ return=1, _nobs_ _nvar_);
			%put DETECTOUTLIERSMAD: Output dataset %upcase(&_outmad_name_) created containing the information of;
			%put DETECTOUTLIERSMAD: the number of outliers detected for each variable, the median, the MAD and;
			%put DETECTOUTLIERSMAD: the outlier thresholds.;
			%put DETECTOUTLIERSMAD: The dataset %upcase(&_outmad_name_) has &_nobs_ observations and &_nvar_ variables.;
			%put;
		%end;
	%end;

	%if &log %then %do;
		%callmacro(getnobs, &_out_name_ return=1, _nobs_ _nvar_);
		%put DETECTOUTLIERSMAD: Output dataset %upcase(&_out_name_) created with the information on the values;
		%put DETECTOUTLIERSMAD: that are detected as outliers for each analysis variable.;
		%put DETECTOUTLIERSMAD: The dataset %upcase(&_out_name_) has &_nobs_ observations and &_nvar_ variables.;
		%put;
	%end;

	%if %quote(&macrovar) ~= %then %do;
		%global &macrovar;
		%let &macrovar = %MakeList(&_vars_, prefix=&prefix);
		%if &log %then %do;
			%put DETECTOUTLIERSMAD: Global macro variable %upcase(&macrovar) created with the list of;
			%put DETECTOUTLIERSMAD: variables that flag the outliers for each analysis variable;
			%put;
		%end;
	%end;
%end;
%else %do;
	%if %quote(%upcase(&out)) ~= %quote(%upcase(&data)) %then %do;
		data &out;
			set &data;
		run;
	%end;
	%put DETECTOUTLIERSMAD: WARNING - No variables passed the outlier detection process;
	%put DETECTOUTLIERSMAD: The output dataset %upcase(&_out_name_) is the same as the input dataset;
%end;

proc datasets nolist;
	delete	_DOM_data_
			_DOM_Error_i_
			_DOM_Error_
			_DOM_MAD_i_
			_DOM_Means_;
	%if %quote(%upcase(&outmad)) ~= _DOM_MAD_ %then %do;
	delete _DOM_MAD_;
	%end;
quit;

%if &log %then %do;
	%put;
	%put DETECTOUTLIERSMAD: Macro ends;
	%put;
%end;

%ResetSASOptions;
%end;	%* %if ~%CheckInputParameters;
%MEND DetectOutliersMAD;
