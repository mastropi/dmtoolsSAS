/* MACRO %PiecewiseTransf
Version: 1.00
Author: Daniel Mastropietro
Created: 23-Nov-04
Modified: 22-Sep-05

DESCRIPTION:
This macro makes linear piecewise transformations to a set of variables from specified cut values.

USAGE:
%PiecewiseTransf(
	data,
	var=,
	cuts=,
	prefix=I,
	join=_X_,
	fill=0,
	out=,
	log=1);

REQUIRED PARAMETERS:
- data:			Input dataset. Data options can be specified as in any data= SAS option.

- cuts:			This parameter defines the cut values to use in the piecewise transformation
				for each variable.
				It can be a list of values or a dataset containing this information.
				- In case it is a list of values, parameter VAR= needs to be passed, and it
				is assumed that the list contains the cut values to use for each and all the
				variables listed in VAR=.
				- In case it is the name of a dataset, parameter VAR= MUST be empty, and
				the dataset must contain EXACTLY the following columns:
					- Column 1 (character): containing the names of the variables to be transformed.
					- Rest of the columns (numeric): one column for each cut value to be used for 
					the transformation of each variable. The number of cuts used for each variable
					is given by the number of non-missing columns.
				  The number of cut values need NOT be the same for all the variables. For each
				  variables, cut values are read until a missing value is found.
				NOTES:
				- When making the piecewise transformation, the cut values are included into the
				left piece of the transformation.
				- The cut values need NOT be listed in ascending order.

OPTIONAL PARAMETERS:
- var:			Blank-separated list of variables to be transformed.
				If empty, the list of variables is read from the dataset passed in parameter
				'cuts'.

- prefix:		Prefix to be used for the dummy variables indicating each piece of the
				piecewise linear transformation and for the dummy variables indicating a missing
				value of the variable (if the variable has missing values).	
				The dummy variables are called <prefix><n>_<var-name>, where n is the piece
				being indicated and var-name is the name of the variable being transformed.
				In turn, the missing dummy variables are called <prefix>_<var-name>.
				Ex: if prefix=I, the variable being transformed is z, and there are 2 cut values,
				then 3 dummy variables are created: I1_z, I2_z, I3_z.
				In addition, if variable z has missing values, the following dummy variable is
				created: I_z.
				default: I

- join:			String to use for the construction of the interaction variables that are made
				up of the product between the dummy variables indicating each piece of the
				piecewise linear transformation and the variable itself.
				Ex: if prefix=I and join=_X_, the variable being transformed is z, and there are
				2 cut values, then 3 interaction variables are created: I1_X_z, I2_X_z, I3_X_z.
				default: _X_

- fill:			Value or statistic keyword to use to replace the missing values of the variables.
				If fill= is a numeric value, this value is used to replace the missing values
				of all the variables. If fill= is a statistic keyword, that statistic is
				computed for each variable and the value obtained is used to replace the
				missing values of the variable (ex: MEAN).
				default: 0

- out:			Output dataset containing the transformed variables. The names of the transformed
				variables follow the rule described under parameter PREFIX.

- log:			Show messages in the log?
				Possible values: 0 => No, 1 => Yes
				default: 1

NOTES:
1.- The following global macro variables are created:
_dummylist_:		contains the list of all the dummy variables created in the output dataset.
_interactionlist_: 	contains the list of all the interaction variables created in the output dataset.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Callmacro
- %CheckInputParameters
- %MakeListFromVar
- %ExistVar
- %Getnobs
- %GetNroElements
- %GetStat
- %GetVarList
- %IsNumber
- %ResetSASOptions
- %SetSASOptions

EXAMPLES:
1.- %PiecewiseTransf(test, cuts=cutsDataSet, out=test_transf);
This reads the information regarding the piecewise linear transformation from the dataset
CUTSDATASET, which for example would be of the following form:
var		V1		V2		V3
x1		0.3		0.7		8
x2		10		2		.
zz		0.7		.		.

NOTE: The cut values need not be sorted in ascending order for each variable.

A model including the transformed variables could then be:
proc reg data=test_transf;
	model y = &var &_dummylist_ &_interactionlist_;
run;
quit;
*/
&rsubmit;
%MACRO PiecewiseTransf(data, var=, cuts=, prefix=I, join=_X_, fill=0, out=, log=1, help=0)
		/ store des="Piecewise transformation of continuous variables with specified cuts";

/*----- Macro to display usage -----*/
%MACRO ShowMacroCall;
	%put PIECEWISETRANSF: The macro call is as follows:;
	%put %nrstr(%PiecewiseTransf%();
	%put data , (REQUIRED) %quote(*** Input dataset.);
	%put var= , %quote(           *** Variables to transform.);
	%put cuts= , %quote(          *** Cuts to be used in the transformations or dataset with that info.);
	%put prefix= , %quote(        *** Prefix to use for the dummy variables indicating each piece of the transformation.);
	%put out= , %quote(           *** Output dataset.);
	%put log=1) %quote(           *** Show messages in the log?);
%MEND ShowMacroCall;

%if &help %then %do;
	%ShowMacroCall;
%end;
%else %if ~%CheckInputParameters(data=&data , var=&var , varRequired=0,
								 otherRequired=%quote(&cuts), 
								 requiredParamNames=data cuts=, macro=PIECEWISETRANSF) %then %do;
	%ShowMacroCall;
%end;
%else %do;
/************************************* MACRO STARTS ******************************************/
/* Local variables declaration */
%local data_name freqvari nobs nro_vars out_name vari vartype;
%local i j nro_cutvalues varnames;
%local error;
%local dsid rc;
%local cutvalue;	%* Value of one single cut read from the &cuts dataset;
%local cutvaluej;	%* Value of j-th cut for a variable;
%local fillFirstChar fillStat;
%local todrop todelete;

%* Set options and get current options settings;
%SetSASOptions;

%* Show input parameters;
%if &log %then %do;
	%put;
	%put PIECEWISETRANSF: Macro starts;
	%put;
	%put PIECEWISETRANSF: Input parameters:;
	%put PIECEWISETRANSF: - Input dataset = %quote(&data);
	%put PIECEWISETRANSF: - var = %quote(          &var);
	%put PIECEWISETRANSF: - cuts = %quote(         &cuts);
	%put PIECEWISETRANSF: - prefix = %quote(       &prefix);
	%put PIECEWISETRANSF: - join = %quote(         &join);
	%put PIECEWISETRANSF: - fill = %quote(         &fill);
	%put PIECEWISETRANSF: - out = %quote(          &out);
	%put PIECEWISETRANSF: - log = %quote(          &log);
	%put;
%end;

/*------------------------------- Parsing input parameters ----------------------------------*/
%let error = 0;

%*** DATA=;
%let data_name = %scan(&data, 1, '(');

%*** VAR=;
%if %quote(&var) ~= %then %do;
	%let var = %GetVarList(&data, var=&var, log=0);
	%let nro_vars = %GetNroElements(&var);
	%*** CUTS=;
	%do i = 1 %to &nro_vars;
		%local cutvalues&i;
		%let cutvalues&i = &cuts;
	%end;
%end;
%else %if %quote(&cuts) ~= %then %do;
	%** In case parameter VAR= is empty, it is assumed that parameter cuts contains the name of a
	%** dataset with the information regarding the variables to transform and the piecewise
	%** transformation to be performed on each variable;
	%* Open dataset;
	%let dsid = %sysfunc(open(&cuts));
	%if &dsid = 0 %then %do;
		%put PIECEWISETRANSF: ERROR - Dataset %upcase(&cuts) does not exist.;
		%let error = 1;
	%end;
	%else %do;
		%* Check if the first column contains a character variable;
		%let vartype = %sysfunc(vartype(&dsid, 1));
		%if %upcase(&vartype) ~= C %then %do;
			%put PIECEWISETRANSF: ERROR - The first variable in dataset %upcase(&cuts) must contain the names of;
			%put PIECEWISETRANSF: the variables to transform.;
			%let error = 1;
		%end;
		%else %do;
			%* Read maximum number of cut values for all variables to be transformed;
			%let nro_cutvalues = %eval(%sysfunc(attrn(&dsid, nvar)) - 1);
			%if &nro_cutvalues = 0 %then %do;
				%put PIECEWISETRANSF: ERROR - No cut values are present in dataset %upcase(&cuts).;
				%let error = 1;
			%end;
			%else %do;
				%* Check if the columns after the first column contain numeric variables;
				%do j = 2 %to %eval(&nro_cutvalues+1);	%* The cut values are stored from column 2 to &nro_cutvalues+1;
					%let vartype = %sysfunc(vartype(&dsid, &j));
					%if %upcase(&vartype) ~= N %then %do;
						%put PIECEWISETRANSF: ERROR - Column &j in dataset %upcase(&cuts) is not numeric.;
						%let error = 1;
					%end;
				%end;
				%if ~&error %then %do;
					%* Read the variable names and the cut values;
					%let rc = %sysfunc(fetch(&dsid));
					%* Initialize counter of number of variables to transform;
					%let i = 0;
					%* Initialize variable list;
					%let var = ;
					%do %while(&rc = 0);
						%* Increase variable count;
						%let i = %eval(&i + 1);
						%* Update variable list;
						%let var = &var %sysfunc(getvarc(&dsid, 1));
						%* Read the cut values;
						%local cutvalues&i;
						%let cutvalues&i = ;
						%do j = 2 %to %eval(&nro_cutvalues+1);	%* The cut values are stored from column 2 to &nro_cutvalues+1;
							%let cutvalue = %sysfunc(getvarn(&dsid, &j));
							%if %sysevalf(&cutvalue ~= .) %then
							   	%let cutvalues&i = &&&cutvalues&i &cutvalue;
						%end;
						%* Read next observation;
						%let rc = %sysfunc(fetch(&dsid));
					%end;	%* while;

					%* Store number of variables to transform;
					%let nro_vars = &i;
					%* Check existence of variables to transform in input dataset;
					%if ~%ExistVar(&data, &var, macrovar=varNotFound, log=0) %then %do;
						%put PIECEWISETRANSF: ERROR - Variables %upcase(&varNotFound) were not found in input dataset %upcase(&data_name).;
						%let error = 1;
					%end;
					%symdel varNotFound;	%*** Delete global macro variable created by %ExistVar;
					quit;		%*** To avoid problems with %symdel;
				%end;
			%end;
		%end;
		%* Close dataset &cuts;
		%let rc = %sysfunc(close(&dsid));
	%end;
%end;
%else %do;
	%put PIECEWISETRANSF: ERROR - Either parameter VAR= or cuts= needs to be passed.;
	%let error = 1;
%end;

%*** FILL=;
%* Check whether FILL= is a value or a statistic keyword;
%if %IsNumber(&fill) %then
	%let fillStat = 0;	%* FILL= is a value;
%else
	%let fillStat = 1;	%* FILL= is a statistic keyword;

%*** OUT=;
%if %quote(&out) = %then
	%let out = &data;
%let out_name = %scan(&out, 1, ' ');
/*-------------------------------------------------------------------------------------------*/
%if ~&error %then %do;

%* if parameter FILL= is a statistic keyword, compute such statistic for each variable;
%if &fillStat %then %do;
	%GetStat(&data, var=&var, stat=&fill, suffix=_&fill._, macrovar=_statList_, log=0);
	%** I use the parameter SUFFIX=, to reduce the risk of overwriting global macro variables
	%** already existent in memory. Thus, I add an underscore at the end of the macro variable
	%** names, because the user usuallly does not use underscores in a macro variable name;
%end;

%* Sort the cut values in ascending order in case they came unsorted;
%do i = 1 %to &nro_vars;
	%let nro_cutvalues = %GetNroElements(&&cutvalues&i);
	%if &nro_cutvalues > 0 %then %do;	%* This %IF is done in case all cut values are missing for variable &vari;
		data _PT_cuts_;
		%do j = 1 %to &nro_cutvalues;
			cuts = %scan(&&cutvalues&i, &j, ' '); output;
		%end;
		run;
		proc sort data=_PT_cuts_;
			by cuts;
		run;
		%let cutvalues&i = %MakeListFromVar(_PT_cuts_, var=cuts, log=0);
	%end;
%end;
data &out;
	set &data end=lastobs;
	%do i = 1 %to &nro_vars;
		%* Length of dummy variables set to 3 to save space, since the only possible values are 0 or 1;
		length &prefix._&vari 3;
		%do k = 1 %to %eval(&nro_cutvalues+1);
		length &prefix&k._&vari 3;
		%end;

		%let vari = %scan(&var, &i, ' ');
		%* Number of cuts for current variable &vari;
		%let nro_cutvalues = %GetNroElements(&&cutvalues&i);
		if &vari = . then do;
			%* Variable that flags that variable &vari has at least one missing value;
			%* Replace the missing value with a non-missing value;
			%if &fillStat %then %do;
			&vari = &&&vari._&fill._;
			%end;
			%else %do;
			&vari = &fill;
			%end;
			&prefix._&vari = 1;					%* Indicator of missing value;
			%do k = 1 %to %eval(&nro_cutvalues+1);
				&prefix&k._&vari = 0;
			%end;
		end;
		else
		%do j = 1 %to &nro_cutvalues;
			%* Current cut value;
			%let cutvaluej = %scan(&&cutvalues&i, &j, ' ');
			if &vari <= &cutvaluej then do;
				&prefix._&vari = 0;			%* Indicator of non-missing value;
				%do k = 1 %to %eval(&nro_cutvalues+1);
					&prefix&k._&vari = 0;
				%end;
				&prefix&j._&vari = 1;
		end;
		else
		%end;
		do;	%* Last segment (beyond the largest cut);
			&prefix._&vari = 0;			%* Indicator of non-missing value;
			%do k = 1 %to &nro_cutvalues;
				&prefix&k._&vari = 0;
			%end;
			&prefix&j._&vari = 1;
		end;
	%end;
run;

%* Drop dummy variables whose values are all the same;
%let todrop = ;
%do i = 1 %to &nro_vars;
	%let vari = %scan(&var, &i, ' ');
	%let nro_cutvalues = %GetNroElements(&&cutvalues&i);
	%* Analysis of the indicator variable of missing values;
	%let freqvari = &prefix._&vari;
	proc freq data=&out_name noprint;
		tables &freqvari / out=_PT_freq_;
	run;
	%callmacro(getnobs, _PT_freq_ return=1, nobs);
	%* Variable that tells whether the indicator variable of missing values has to be dropped or 
	%* not because all its values are the same (this happens when the variable &vari has no
	%* missing values). 
	%* This is used when generating the list of dummy variables created in the output dataset
	%* for each variable;
	%local drop&i.0;
	%let drop&i.0 = 0;
	%if &nobs <= 1 %then %do;		
		%let todrop = &todrop &freqvari;
		%let drop&i.0 = 1;
	%end;

	%* Analysis of the dummy variables indicating each piece of the piecewise linear transformation;
	%do j = 1 %to %eval(&nro_cutvalues+1);
		%let freqvari = &prefix&j._&vari;
		proc freq data=&out_name noprint;
			tables &freqvari / out=_PT_freq_;
		run;
		%callmacro(getnobs, _PT_freq_ return=1, nobs);
		%* Variable that tells whether the current dummy variable &i&j has to be dropped or not
		%* because all its values are the same. This is used when generating the interaction
		%* variables between the dummy variables and the transformed variables;
		%local drop&i&j;
		%let drop&i&j = 0;
		%if &nobs <= 1 %then %do;
			%let todrop = &todrop &freqvari;
			%let drop&i&j = 1;
		%end;
	%end;
%end;

data &out_name;
	set &out_name(drop=&todrop);
	%* Global macro variable containing:
	%* - the list of ALL dummy variables created
	%* - the list of ALL interaction variables created;
	%global _DummyList_ _InteractionList_;
	%let _DummyList_ = ;
	%let _InteractionList_ = ;
	%do i = 1 %to &nro_vars;
		%let vari = %scan(&var, &i, ' ');
		%let nro_cutvalues = %GetNroElements(&&cutvalues&i);
		%* Global macro variables containing:
		%* - the list of dummy variables for variable &vari
		%* - the list of interaction variables for variable &vari; 
		%global &prefix._&vari &prefix&join&vari;
		%let &prefix._&vari = ;
		%let &prefix&join&vari = ;
		
		%* Add the indicator of missing values for current variable &vari to the list of
		%* dummy variables for variable &vari, if it was not dropped from the dataset above;
		%if ~&&drop&i.0 %then
			%let &prefix._&vari = &prefix._&vari;
			%** Do not get confused because the name of the macro variable is the same as its
			%** value. This is OK (an example of this assignment would be: %let I_x = I_x);
		%do j = 1 %to %eval(&nro_cutvalues+1);
			%* If the dummy variable was not dropped above (because all its values are the same),
			%* then the corresponding interaction variable is created;
			%if ~&&drop&i&j %then %do;
				%let cutvaluej = %scan(&&cutvalues&i, &j, ' ');
				%let &prefix._&vari = &&&prefix._&vari &prefix&j._&vari;
				&prefix&j&join&vari = &prefix&j._&vari * &vari;
				%let &prefix&join&vari = &&&prefix&join&vari &prefix&j&join&vari;
			%end;
		%end;
		%let _DummyList_ = &_DummyList_ &&&prefix._&vari;
		%let _InteractionList_ = &_InteractionList_ &&&prefix&join&vari;
		%if &log %then %do;
			%put;
			%put PIECEWISETRANSF: Global macro variable &prefix._&vari created with the list of;
			%put PIECEWISETRANSF: the DUMMY variables for %upcase(&vari) generated in dataset %upcase(&out_name).;
			%put PIECEWISETRANSF: Global macro variable &prefix&join&vari created with the list of;
			%put PIECEWISETRANSF: the INTERACTION variables for %upcase(&vari) generated in dataset %upcase(&out_name).;
		%end;
	%end;
	%if &log %then %do;
		%put;
		%put ************************************************************************************************;
		%put PIECEWISETRANSF: Global macro variable _DummyList_ created with the list of;
		%put PIECEWISETRANSF: ALL the DUMMY variables generated in dataset %upcase(&out_name).;
		%put PIECEWISETRANSF: Global macro variable _InteractionList_ created with the list of;
		%put PIECEWISETRANSF: ALL the INTERACTION variables generated in dataset %upcase(&out_name).;
		%put ************************************************************************************************;
	%end;
run;

%* Show the list of dummy and interaction variables created in output dataset;
%if &log %then %do;
	%put;
	%put PIECEWISETRANSF: The following DUMMY variables were created in dataset %upcase(&out_name):;
	%put PIECEWISETRANSF: &_DummyList_;
	%put PIECEWISETRANSF: The following INTERACTION variables were created in dataset %upcase(&out_name):;
	%put PIECEWISETRANSF: &_InteractionList_;
%end;

%* Delete temporary global macro variables created by %GetStat;
%if &fillStat %then %do;
	%do i = 1 %to %GetNroElements(&_statList_);
		%let todelete = %scan(&_statList_, &i);
		%syscall symdel(todelete); quit;
		%** Note that the macro variable TODELETE is not preceded by an & (this is because %symdel
		%** is called via de %syscall function;
	%end;
	%symdel _statList_; quit;
%end;

proc datasets nolist;
	delete 	_PT_cuts_
			_PT_freq_;
quit;
%end; %* %if ~&error;

%if &log %then %do;
	%put;
	%put PIECEWISETRANSF: Macro ends;
	%put;
%end;

%ResetSASOptions;
%end; %* %if ~%CheckInputParameters;
%MEND PiecewiseTransf;
