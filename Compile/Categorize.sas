/* MACRO %Categorize
Version:	1.02
Author:		Daniel Mastropietro
Created:	12-Feb-2016
Modified:	09-Jan-2018 (previous: 18-Jun-2017, 12-Feb-2016)

DESCRIPTION:
Categorizes a set of numeric variables based on ranks (i.e. equal size binning) and optionally
creates a new set of variables containing a specified statistic (like the mean) for each bin.

Missing values in the analyzed variables are categorized as missing values.

USAGE:
%Categorize(
	data, 			*** Input dataset. Dataset options are allowed
	var=_NUMERIC_,	*** Blank-separated list of variables to categorize
	by=,			*** Blank-separated list of BY variables
	format=,		*** Content of the format statement to use in PROC RANK
	id=,			*** Blank-separated list of ID variables to keep in the output dataset
	condition=,		*** Condition that each analysis variable should satisfy in order for the
					*** case to be included in the categorization process
	varcat=,		*** Blank-separated list of names to be used for the rank variables.
					*** This list should be matched one to one with the variables in VAR.
	varvalue=,		*** Blank-separated list of names to be used for the statistic-valued categorized variables
					*** This list should be matched one to one with the variables in VAR.
	stat=,			*** Statistic to use as representation of each category for the statistic-valued categorized variables
	groupsize=,		*** Number of cases wished for each group in the categorized variables
	groups=10,		*** Number of groups to use in the categorization
	descending=0,	*** Compute ranks on the decreasing values of the analyzed variables?
	out=,			*** Output dataset with the categorized variables
	addvars=1,		*** Add categorized variables to the variables present in the input dataset?
	log=1);			*** Show messages in the log?


REQUIRED PARAMETERS:
- data:				Input dataset. Dataset options are allowed.

OPTIONAL PARAMETERS:
- var:				Blank-separated list of numeric variables to categorize.
					default=_NUMERIC_

- by:				Blank-separated list of BY variables by which the categorization
					is carried out.
					default: (Empty)

- format:			Format to use for the BY variables.
					default: (Empty)

- id:				ID variable to keep in the output dataset when ADDVARS=0.
					default: (Empty)

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Callmacro
- %CheckInputParameters
- %CreateInteractions
- %ExecTimeStart
- %ExecTimeStop
- %FixVarNames
- %Getnobs
- %GetVarOrder
- %MakeListFromName
- %Means
- %ResetSASOptions
- %SetSASOptions
*/
&rsubmit;
%MACRO Categorize(	data,
					var=_NUMERIC_,
					by=,
					format=,
					id=,		/* NEW */

					condition=,
/*					alltogether=1,*/

					varcat=,
					varvalue=,
/*					suffix=_cat, */
					stat=mean,
					value=,
/*					both=, */
					groupsize=,
					groups=10,
/*					percentiles=,*/
					descending=0,

					out=,
					addvars=1,

					log=1,
					help=0) / store des="Categorizes continuous variables based on percentile values";

/*----- Macro to display usage -----*/
%MACRO ShowMacroCall;
	%put CATEGORIZE: The macro call is as follows:;
	%put %nrstr(%Categorize%();
	%put data , (REQUIRED) %quote(      *** Input dataset. Dataset options are allowed.);
	%put var=_NUMERIC_ , %quote(        *** Blank-separated list of variables to categorize.);
	%put by= , %quote(                  *** Blank-separated list of BY variables.);
	%put format= , %quote(              *** Content of the format statement to use in PROC RANK.);
	%put id= , %quote(                  *** Blank-separated list of ID variables to keep in the output dataset.);
	%put condition= , %quote(           *** Condition that each analysis variable should satisfy in order for the);
	%put %quote(                        *** case to be included in the categorization process.);
	%put varcat= , %quote(              *** Blank-separated list of names to be used for the rank variables.);
	%put %quote(                        *** This list should be matched one to one with the ariables in VAR.);
	%put varvalue= , %quote(            *** Blank-separated list of names to be used for the statistic-valued categorized variables.);
	%put %quote(                        *** This list should be matched one to one with the ariables in VAR.);
	%put stat= , %quote(                *** Statistic to use as representative of each category for the statistic-valued categorized variables.);
	%put groupsize= , %quote(           *** Number of cases wished for each group in the categorized variables.);
	%put groups=10 , %quote(            *** Number of groups to use in the categorization.);
	%put descending=0 , %quote(         *** Compute ranks on the decreasing values of the analyzed variables?);
	%put out= , %quote(                 *** Output dataset with the categorized variables.);
	%put addvars=1 , %quote(            *** Add categorized variables to the variables present in the input dataset?);
	%put log=1) %quote(                 *** Show messages in log?);
%MEND ShowMacroCall;

%if &help %then %do;
	%ShowMacroCall;
%end;
%else %if ~%CheckInputParameters(data=&data, var=&var, check=by, macro=CATEGORIZE) %then %do;
	%ShowMacroCall;
%end;
%else %do;
/************************************* MACRO STARTS ******************************************/
%* Global variables used by %CreateInteractions;
%global _renamecat;
%global _renameval;

%* Local variables;
%local data_name;
%local out_name;
%local dkricond;
%local error;
%local i;
%local nobs;
%local nvar;
%local byst;
%local formatst;
%local renamest;
%local rankvar;
%local rankvari;
%local vari;
%local valvar;		%* Names used internally to store the statistic-valued grouped variables;
%local nro_vars;
%local var_order;

%*** Treat parameters VALUE= and STAT= because I do not want to show VALUE in the log (the user should use STAT, not VALUE, although they represent the same thing);
%* Out of the two parameters, STAT has preference;
%* Note that if both are empty, the %Means macro below will assume that the user wants to use the MEAN as statistic
%* as representation of each category;
%if %quote(&stat) = %then
	%let stat = &value;

%* Show input parameters;
%if &log %then %do;
	%put;
	%put CATEGORIZE: Macro starts;
	%put;
	%put CATEGORIZE: Input parameters:;
	%put CATEGORIZE: - Input dataset = %quote(&data);
	%put CATEGORIZE: - var = %quote(          &var);
	%put CATEGORIZE: - by = %quote(           &by);
	%put CATEGORIZE: - format = %quote(       &format);
	%put CATEGORIZE: - id = %quote(           &id);
	%put CATEGORIZE: - condition = %quote(    &condition);
	%put CATEGORIZE: - varcat = %quote(       &varcat);
	%put CATEGORIZE: - varvalue = %quote(     &varvalue);
	%put CATEGORIZE: - stat = %quote(         &stat);
	%put CATEGORIZE: - groupsize = %quote(    &groupsize);
	%put CATEGORIZE: - groups = %quote(       &groups);
	%put CATEGORIZE: - descending = %quote(   &descending);
	%put CATEGORIZE: - out = %quote(          &out);
	%put CATEGORIZE: - addvars = %quote(      &addvars);
	%put CATEGORIZE: - log = %quote(          &log);
	%put;
%end;

%let error = 0;
/*------------------------- Parse input parameters -------------------------*/
%*** Parmeters that should be ok before proceeding;
%*** DATA=;
%let data_name = %GetDataName(&data);

%*** VAR=;
%let var = %GetVarList(&data, var=&var);
%let nro_vars = %GetNroElements(&var);
%let rankvar = %MakeListFromName(_rank, start=1, stop=&nro_vars, step=1);

%*** VARCAT= and VARVALUE=;
%if %quote(&varcat) ~= and %GetNroElements(&varcat) ~= &nro_vars %then %do;
	%let error = 1;
	%put CATEGORIZE: ERROR - The number of variables listed in VARCAT= must be the same;
	%put CATEGORIZE: (if non-empty) as the number of variables in VAR= (&nro_vars);
%end;
%if %quote(&varvalue) ~= and %GetNroElements(&varvalue) ~= &nro_vars %then %do;
	%let error = 1;
	%put CATEGORIZE: ERROR - The number of variables listed in VARVALUE= must be the same;
	%put CATEGORIZE: (if non-empty) as the number of variables in VAR= (&nro_vars);
%end;

%if ~&error %then %do;

%SetSASOptions;
%ExecTimeStart;

%if &log %then %do;
	%put;
	%put CATEGORIZE: Macro starts;
	%put;
%end;

/*-------------------------------- Parse input parameters -----------------------------------*/
%*** BY=;
%let byst = ;
%if %quote(&by) ~= %then
	%let byst = by &by;

%*** FORMAT=;
%let formatst = ;
%if %quote(&format) ~= %then
	%let formatst = format &format;

%*** DESCENDING=;
%if &descending %then
	%let descending = descending;
%else
	%let descending = ;

%*** OUT=;
%if %quote(&out) = %then %do;
	%* If no output dataset is given, set it to the input dataset and set ADDVARS=1 so that newly created variables are added to the input dataset;
	%let out = &data_name;
	%let addvars = 1;
%end;
/*-------------------------------- Parse input parameters -----------------------------------*/


%*** When all the variables in the input dataset are requested
%*** split the dataset into analysis variables and the rest of the variables;
%if &addvars %then %do;
	%* Store the variable order to be used at the end to restore the variable order;
	%GetVarOrder(&data, var_order);
	data _cat_dat_(keep=_obs_ &id &by &var) _cat_dat_rest_(drop=&id &by &var);
		format _obs_;
		set &data;
		_obs_ = _N_;
	run;
%end;
%else %do;
	data _cat_dat_(keep=_obs_ &id &by &var);
		format _obs_;
		set &data;
		_obs_ = _N_;
	run;
%end;

%*** GROUPSIZE (this must come AFTER the creation of the analysis dataset in case the number of cases
%*** changes w.r.t. the input dataset specified in DATA);
%Callmacro(getnobs, _cat_dat_ return=1, nobs);
%if %quote(&groupsize) ~= %then %do;
	%let groups = %sysfunc(floor(%sysevalf(&nobs/&groupsize)));
	%if &log %then %do;
		%put CATEGORIZE: Nro. of approx. equal groups used to categorize each variable = &groups;
		%put CATEGORIZE: Approx. size of each group = &groupsize;
		%put;
	%end;
%end;
/*------------------------- Parse input parameters -------------------------*/

%*** Sort by the BY variables;
%if %quote(&by) ~= %then %do;
	proc sort data=_cat_dat_;
		&byst;
	run;
%end;

%*** Compute the groups for all variables together when there is no condition to be applied on each variable separately;
%if %quote(&condition) = %then %do;
	%* Note that the output dataset of PROC RANK is the same as the input dataset, since it is used below for
	%* the continued analysis;
	proc rank 	data=_cat_dat_
				out=_cat_dat_
				groups=&groups
				&descending;
		&formatst;
		&byst;
		var &var;
		ranks &rankvar;
	run;
%end;

%do i = 1 %to &nro_vars;
	%let vari = %scan(&var, &i, ' ');
	%let rankvari = %scan(&rankvar, &i, ' ');
	%if &log %then %do;
		%put CATEGORIZE: Categorizing variable %upcase(&vari) (&i of &nro_vars)...;
	%end;

	%* Compute the groups separately for each variable when there is a condition to apply
	%* separately to each of them;
	%if %quote(&condition) ~= %then %do;
		%* Note that the output dataset of PROC RANK is a new dataset _cat_dat_rank_ as this
		%* dataset may have less records than the original dataset _cat_dat_ because of the
		%* condition applied to the analyzed variable; 
		proc rank 	data=_cat_dat_(keep=_obs_ &by &vari)
					out=_cat_dat_rank_(keep=_obs_ &by &vari &rankvari)
					groups=&groups
					&descending;
			where &vari &condition;	%* CONDITION for the record to be included in the groups calculation;
			&formatst;
			&byst;
			var &vari;
			ranks &rankvari;
		run;

		%* Merge back with _cat_dat_ so that we have the rank variable in the original dataset
		%* which will allow us to merge back with it after we compute the statistic-valued
		%* grouped variable below;
		%* Since we do a LEFT join the original dataset will have the rank variable missing
		%* for cases excluded from the ranking procedure above;
		proc sql;
			create unique index _obs_ on _cat_dat_rank_;
		quit;
		data _cat_dat_;
			set _cat_dat_;
			set _cat_dat_rank_(keep=_obs_ &rankvari) key=_obs_ / unique;
			if _IORC_ > 1 then do;
				%* IMPORTANT: This check needs to be done because excluded values by the condition and missing values in the original
				%* analyzed numeric variable do not have any match in the aggregated dataset generated by PROC RANK above;
				%* However, the value read from variable &rankvari in the aggregated dataset may NOT always be missing...
				%* (as it should) WHY??? I think it is because it retains the value from the previous record... WHY???;
				_ERROR_ = 0;
				%* Distinguish the missing values from the excluded values so that they are not put into the same group;
				if missing(&vari) then
					&rankvari = .;
				else
					&rankvari = -1;
					%** We can safely use -1 for the rank variable because the rank values are never negative;
					%** HOWEVER, this has the drawback that ALL EXCLUDED VALUES ARE MAPPED TO THE SAME GROUP!;
			end;
		run;
	%end;

	%* Compute statistics for each group in the currently analyzed variable;
	%Means(	_cat_dat_(keep=&by &rankvari &vari),
			by=&by,
			class=&rankvari,
			types=&rankvari,
			format=&format,
			var=&vari,
			stat=&stat,
			name=_value&i,		/* Name for the variable containing the value corresponding to the statistic specified in parameter STAT= */
			out=_cat_dat_means_,
			log=0);

	%* Create an index on the BY and rank variables so that we can merge fast below;
	proc sql;
		%if %quote(&by) = %then %do;
		%* Simple index;
		create unique index &rankvari on _cat_dat_means_;
		%end;
		%else %do;
		%* Composite index;
		create unique index idxrank on _cat_dat_means_(%MakeList(&by &rankvari, sep=%quote(,)));
		%end;
	quit;

	%* Merge with original data;
	data _cat_dat_;
		set _cat_dat_;
		%* Need to do a separate situation whether there are BY variables or not because
		%* of problems with the name of the indices!!;
		%if %quote(&by) = %then %do;
		%* Simple index;
		set _cat_dat_means_(keep=&rankvari _value&i) key=&rankvari / unique;
		%end;
		%else %do;
		%* Composite index;
		set _cat_dat_means_(keep=&by &rankvari _value&i) key=idxrank / unique;
		%end;
		if _IORC_ > 0 then do;
			%* IMPORTANT: This check needs to be done because missing values in the original analyzed numeric variable
			%* do not have any match in the aggregated dataset generated by %Means above, BUT the value read
			%* from variable _value&i in the aggregated dataset may NOT always be missing (as it should)... WHY???;
			%* I think it is because it retains the value from the previous record... WHY???;
			_ERROR_ = 0;
			_value&i = .;
		end;
	run;
%end;
%* Names of the statistic-valued categorized variables;
%* This is needed below either for their rename into the user-specified names or to drop them because they were not requested in the output;
%let valvar = %MakeListFromName(_value, start=1, stop=&nro_vars, step=1);

%*** Rename variables as indicated by the VARCAT= and VARVALUE= parameters;
%* Keep just the statistic-valued variable if both VARCAT= and VARVALUE= are empty by adding
%* the statistic name to the variable names.
%* Otherwise, keep the variables as specified by VARCAT and VARVALUE;
%if %quote(&varcat) = and %quote(&varvalue) = %then %do;
	%* Fix variable names so that the suffix (_&stat) fits in;
	%let var = %FixVarNames(&var, space=%length(_&stat));
	%let varvalue = %MakeList(&var, suffix=_&stat);
%end;
%else %if %quote(&varcat) ~= %then %do;
	%CreateInteractions(&rankvar, with=&varcat, join=%quote(=), allinteractions=0, macrovar=_renamecat, log=0);
%end;

%* Create the RENAME statement to use as part of the data options when creating the output dataset;
%* Note that either &varcat or &varvalue are set, so RENAMEST is always non-empty;
%* Note also that &varvalue is set above if both VARCAT and VARVALUE are empty;
%if %quote(&varvalue) ~= %then %do;
	%CreateInteractions(&valvar, with=&varvalue, join=%quote(=), allinteractions=0, macrovar=_renameval, log=0);
%end;
%let renamest = rename=(&_renamecat &_renameval);

%*** Create output dataset;
%* Sort the dataset by the original order;
proc sort data=_cat_dat_;
	by _obs_;
run;

%* Since below I am dropping variables that may not exist, I set the drop, keep, rename warning option to NOWARN;
%let dkricond = %sysfunc(getoption(dkricond));
options dkricond=nowarn;
data &out;
	%if &addvars %then %do;
		%* Merge back with the input dataset if the output variables have been requested to be added to the input dataset;
		%* Note that _cat_dat_rest_ is already sorted by _OBS_ from the beginning;
		format &var_order;
		merge 	_cat_dat_rest_(drop=&varcat &varvalue) 
				_cat_dat_(drop=&varcat &varvalue &renamest);
		by _obs_;
	%end;
	%else %do;
		%* Otherwise, keep just the analyzed variables and new created variables in the output dataset;
		set _cat_dat_(drop=&varcat &varvalue &renamest);
	%end;
	%if %quote(&varcat) ~= %then %do;
		%* Increase the RANK variables by 1 because they range from 0 to (groups-1) and I do not like it;
		array _ranks(*) &varcat;
		do _i = 1 to dim(_ranks);
			_ranks(_i) = _ranks(_i) + 1;
		end;
		drop _i;
	%end;
	%else %do;
		%* Drop the rank variables created in the process because they should not be kept;
		drop &rankvar;
	%end;
	%if %quote(&varvalue) ~= %then %do;
		%if %quote(&condition) ~= %then %do;
			%* If the statistic-valued variables are kept in the output and 
			%* there was a condition applied during the analysis of each variable,
			%* set the statistic-valued variable to the same value as the original variable
			%* for any values not included in the analysis (since at this point the assigned value 
			%* is missing).
			%* Note that for those cases, the categorical-valued variable
			%* will still be missing and this is perfectly fine, since they do not have a rank group!;
			array _vars(*) &var;
			array _varvalues(*) &varvalue;
			do _i = 1 to dim(_vars);
				%* Check if each variable does NOT satisfy the condition (which means the case
				%* was not included in the calculation of the groups);  
				if not (_vars(_i) &condition) then
					_varvalues(_i) = _vars(_i);
			end;
			drop _i;
		%end;
	%end;
	%else %do;
		%* Drop the temporary statistic-valued categorized variables;
		drop &valvar;
	%end;
	%if &addvars or (~&addvars and %quote(&id) ~=) %then %do;
		%* Only drop the _OBS_ variable if the variables created by this process are added to the
		%* input dataset or, when not added, the user did not give any variable to use as ID.
		%* In those cases, keeping _OBS_ gives the user a reference of each record in the output
		%* dataset which is sorted in the same order the input dataset was sorted;
		drop _obs_;
	%end;
run;
options dkricond=&dkricond;

%if &log %then %do;
	%let out_name = %scan(&out, 1, '(');
	%callmacro(getnobs, &out_name return=1, nobs nvar);
	%if %upcase(&out_name) = %upcase(&data_name) %then %do;
		%put;
		%put CATEGORIZE: Dataset %upcase(&data_name) updated with the newly created set of categorized variables.;
		%put CATEGORIZE: The dataset has now &nobs observations and &nvar variables.;
	%end;
	%else %do;
		%put;
		%put CATEGORIZE: Dataset %upcase(&out_name) created with &nobs observations and &nvar variables;
		%put CATEGORIZE: containing the categorized variables added to the input dataset.;
	%end;
%end;

%*** Clean up;
%* Delete temporary datasets;
proc datasets nolist;
	delete 	_cat_dat_
			_cat_dat_means_
			_cat_dat_rank_
			_cat_dat_rest_;
quit;

%* Delete global variables created by %CreateInteractions;
%symdel _renamecat _renameval;

%if &log %then %do;
	%put;
	%put CATEGORIZE: Macro ends;
	%put;
%end;

%ExecTimeStop;
%ResetSASOptions;

%end;	%* %if ~&error;

%end;	%* %if ~%CheckInputParameters;
%MEND Categorize;
