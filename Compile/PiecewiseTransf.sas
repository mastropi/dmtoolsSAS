/* MACRO %PiecewiseTransf
Version: 	1.01
Author: 	Daniel Mastropietro
Created: 	23-Nov-2004
Modified: 	10-Mar-2016 (previous: 22-Sep-05)

DESCRIPTION:
This macro makes linear piecewise transformations to a set of variables from specified cut values.

USAGE:
%PiecewiseTransf(
	data,			*** Input dataset. Data options are accepted.
	var=,			*** Blank-separated list of variables to transform when CUTS= is a list of cut values.
	cuts=,			*** Either a blank-separated list of cut values or a dataset with one row per variable.
	includeright=1,	*** Whether to include the right limit of each interval when defining each piece
	prefixdummy=I_,	*** Prefix to use for the indicator or dummy variables of each piece.
	prefix=pw_,		*** Prefix to use for the piecewise variables.
	suffix=_,		*** Suffix to use before the piece number added at the end of the new variable's name.
	varfix=1,		*** Whether to fix variable names to comply to 32-max character length in created variables.
	varfixremove=,	*** One or more consecutive characters to be removed from each variable before fixing their names.
	fill=mean,		*** Fill value or statistic to replace missing values of each analyzed variable.
	out=,			*** Output dataset containing the indicator and piecewise linear variables. Data options are allowed.
	log=1);			*** Whether to show messages in the log.

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
- includeright	Flag indicating whether to include the right limit of each interval when defining
				each piece.
				Possible values: 0 => No, 1 => Yes
				default: 1

- var:			Blank-separated list of variables to be transformed.
				If empty, the list of variables is read from the dataset passed in parameter
				'cuts'.

- prefixdummy:	Prefix to use for the dummy variables indicating each piece of the
				piecewise linear transformation and for the dummy variables indicating a missing
				value of the variable (if the variable has missing values).	
				The dummy variables are named <prefix>_<var-name>_<n>, where n is the piece
				being indicated and var-name is the name of the variable being transformed.
				In turn, the missing dummy variables are called <prefix>_<var-name>.
				Ex: if prefix=I, the variable being transformed is z, and there are 2 cut values,
				then 3 dummy variables are created: I_z_1, I2_z, I_z_1.
				In addition, if variable z has missing values, the following dummy variable is
				created: I_z.
				default: I_

- prefix:		Prefix to use for the piecewise variables.
				default: pw_

- suffix:		Suffix to add before the piece number added at the end of the transformed piecewise
				variables.
				Ex: if prefix=pw_ and suffix=_, the variable being transformed is z, and there are
				2 cut values, then at most the following piecewise variables are created:
				I_z_2, I_z_3, pw_z_1, pw_z_2, pw_z_3.
				Note that I_z_1 is not created, unless z has missing values (o.w. I_z_1 is always equal to 1)
				default: _

- varfix:		Whether to perform variable name fixing before attempting to create the new variable
				names to make sure that their names have at most 32 characters.
				Possible values: 0 => No, 1 => Yes
				default: 1

- varfixremove:	One or more consecutive characters to be removed from each variable before fixing their names.
				default: (empty)

- fill:			Value or statistic keyword to use to replace the missing values of the variables.
				If fill= is a numeric value, this value is used to replace the missing values
				of all the variables. If fill= is a statistic keyword, that statistic is
				computed for each variable and the value obtained is used to replace the
				missing values of the variable (ex: MEAN).
				default: mean

- out:			Output dataset containing the transformed variables. Data options are allowed.
				The names of the transformed variables follow the rule described under parameter PREFIX.

- log:			Show messages in the log?
				Possible values: 0 => No, 1 => Yes
				default: 1

NOTES:
1.- The following global macro variables are created:
_dummylist_:	contains the list of all the dummy variables created in the output dataset.
_pwlist_: 		contains the list of all the piecewise variables created in the output dataset.

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
	model y = &var &_dummylist_ &_pwlist_;
run;
quit;
*/
&rsubmit;
%MACRO PiecewiseTransf(
		data,
		var=,
		cuts=,
		includeright=1,

		prefixdummy=I_,
		prefix=pw_,
		suffix=_,
		varfix=1,
		varfixremove=,

		fill=mean,

		out=,
		log=1,
		help=0) / store des="Piecewise transformation of continuous variables with specified cuts";

/*----- Macro to display usage -----*/
%MACRO ShowMacroCall;
	%put PIECEWISETRANSF: The macro call is as follows:;
	%put %nrstr(%PiecewiseTransf%();
	%put data , (REQUIRED) %quote( *** Input dataset.);
	%put var= , %quote(            *** Variables to transform.);
	%put cuts= , (REQUIRED) %quote(*** Cuts to be used in the transformations or dataset with that info.);
	%put includeright= , %quote(   *** Whether to include the right limit of each interval when defining each piece.);
	%put prefixdummy= , %quote(    *** Prefix to use for the dummy variables indicating each piece of the transformation.);
	%put prefix= , %quote(         *** Prefix to use for the piecewise variables in each piece of the transformation.);
	%put suffix= , %quote(         *** Suffix to add before the piece number in the transformed variable names);
	%put varfix= , %quote(         *** Whether to fix variable names to comply to 32-max character length in created variables.);
	%put varfixremove= , %quote(   *** One or more consecutive characters to be removed from each variable before fixing their names.);
	%put out= , %quote(            *** Output dataset.);
	%put log=1) %quote(            *** Show messages in the log?);
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
%local cutvaluejm1; %* Value of (j-1)-th cut for a variable (used to generate CONTINUOUS piecewise variables as done by NAT Consultores);
%local operator;	%* Operator to use to compare the variable value with the cut value (either <= or <);
%local fillFirstChar fillStat;
%local todrop todelete;
%* Variables needed for variable name fixing for compliance with 32 characters max length in created variables;
%local nro_cutvalues_max;			%* This defines part of the space needed;
%local prefixspace suffixspace;		%* Spaces needed for the prefixes to add (they are two different for two different set of variables) and for the suffixes;


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
	%put PIECEWISETRANSF: - includeright = %quote( &includeright);
	%put PIECEWISETRANSF: - prefixdummy = %quote(  &prefixdummy);
	%put PIECEWISETRANSF: - prefix = %quote(       &prefix);
	%put PIECEWISETRANSF: - suffix = %quote(       &suffix);
	%put PIECEWISETRANSF: - varfix = %quote(       &varfix);
	%put PIECEWISETRANSF: - varfixremove = %quote( &varfixremove);
	%put PIECEWISETRANSF: - fill = %quote(         &fill);
	%put PIECEWISETRANSF: - out = %quote(          &out);
	%put PIECEWISETRANSF: - log = %quote(          &log);
	%put;
%end;

/*------------------------------- Parsing input parameters ----------------------------------*/
%let error = 0;

%*** DATA=;
%let data_name = %scan(&data, 1, '(');

%*** VAR= & CUTS=;
%if %quote(&var) ~= %then %do;
	%let var = %GetVarList(&data, var=&var, log=0);
	%let nro_vars = %GetNroElements(&var);
	%* Read the cut values directly from parameter CUTS=;
	%do i = 1 %to &nro_vars;
		%local cutvalues&i;
		%let cutvalues&i = &cuts;
	%end;
%end;
%else %if %quote(&cuts) ~= %then %do;
	%** In case parameter VAR= is empty, it is assumed that parameter CUTS= contains the name of a
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
	%put PIECEWISETRANSF: ERROR - Either parameter VAR= or CUTS= needs to be specified.;
	%let error = 1;
%end;

%*** INCLUDERIGHT=;
%if &includeright %then
	%let operator = <=;
%else
	%let operator = <;

%*** FILL=;
%* Check whether FILL= is a value or a statistic keyword;
%if %IsNumber(&fill) %then
	%let fillStat = 0;	%* FILL= is a value;
%else
	%let fillStat = 1;	%* FILL= is a statistic keyword;

%*** OUT=;
%if %quote(&out) = %then
	%let out = &data;
%let out_name = %scan(&out, 1, '(');
/*-------------------------------------------------------------------------------------------*/
%if ~&error %then %do;

%* Sort the cut values in ascending order in case they came unsorted and count the maximum number of cut values used among all variables;
%let nro_cutvalues_max = 0;	%* This is needed to fix the variable names below to make created variables comply with 32-characters maximum length;
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
		%* Update maximum number of cut values;
		%let nro_cutvalues_max = %sysfunc(max(&nro_cutvalues_max, &nro_cutvalues));
	%end;
%end;

%*** VARFIX=;
%* Fix the variable names so that adding the prefixes and the suffixes do not make the new variables created here
%* have more than 32 characters;
%* Note that the value of the BOOLEAN parameter VARFIX= is replaced here by a list of variable names!;
%if &varfix %then %do;
	%let prefixspace = %sysfunc (max(%length(&prefixdummy), %length(&prefix)) );
	%let suffixspace = %eval( %length(&suffix) + %length(&nro_cutvalues_max) );
	%let varfix = %FixVarNames(&var, space=%eval(&prefixspace + &suffixspace), replace=&varfixremove, replacement=);
%end;
%else
	%let varfix = &var;

%* If parameter FILL= is a statistic keyword, compute such statistic for each variable;
%if &fillStat %then %do;
	%* IMPORTANT: The name of the macro variables containing the statistic values computed by %GetStat coincide
	%* with the name of the analyzed variables, no prefix or suffix are added. This is done so that the process
	%* does not crash when the variable name has the maximum of 32 characters allowed by SAS;
	%GetStat(&data, var=&var, name=&var, stat=&fill, macrovar=_statList_, log=0);
%end;

%*** Compute INDICATOR or DUMMY variables;
data &out_name;
	set &data end=lastobs;
	%do i = 1 %to &nro_vars;
		%let vari = %scan(&var, &i, ' ');
		%let varfixi = %scan(&varfix, &i, ' ');

		%* Length of dummy variables set to 3 to save space, since the only possible values are 0 or 1;
		length &prefixdummy&varfixi 3;
		%do k = 1 %to %eval(&nro_cutvalues+1);
		length &prefixdummy&varfixi&suffix&k 3;
		%end;

		%* Number of cuts for current variable &vari;
		%let nro_cutvalues = %GetNroElements(&&cutvalues&i);
		if &vari = . then do;
			%* Variable that flags at least a missing value in variable &vari;
			%* Replace the missing value with a non-missing value;
			%if &fillStat %then %do;
			&vari = &&&vari;	%* Ex: if &vari = x, global macro variable x will exist with the required statistic for x computed above by %GetStat;
			%end;
			%else %do;
			&vari = &fill;
			%end;
			&prefixdummy&varfixi = 1;					%* Indicator of missing value;
			%do k = 1 %to %eval(&nro_cutvalues+1);
				&prefixdummy&varfixi&suffix&k = 0;
			%end;
		end;
		else
		%do j = 1 %to &nro_cutvalues;
			%* Current cut value;
			%let cutvaluej = %scan(&&cutvalues&i, &j, ' ');
			if &vari &operator &cutvaluej then do;	%* This condition is e.g. x <= 0.3, where 0.3 is the cut value;
				&prefixdummy&varfixi = 0;			%* Indicator of non-missing value;
				%* All indicators up to piece j are set to 1, the indicator for the other pieces are set to 0;
				%* NOTE that this calculation is not done as NAT writes the code and it may sound a little counter-intuitive,
				%* but here we are setting ALL the indicator variables for each piece and not the other way round used by NAT code
				%* where they iterate on the indicator variable and set their value to all pieces in one iteration;
				%do k = 1 %to &j;
					&prefixdummy&varfixi&suffix&k = 1;
				%end;
				%do k = %eval(&j+1) %to %eval(&nro_cutvalues+1);
					&prefixdummy&varfixi&suffix&k = 0;
				%end;
		end;
		else
		%end;
		do;	%* Last segment (beyond the largest cut);
			&prefixdummy&varfixi = 0;				%* Indicator of non-missing value;
			%do k = 1 %to %eval(&nro_cutvalues+1);
				&prefixdummy&varfixi&suffix&k = 1;
			%end;
		end;
	%end;
run;

%* Drop dummy variables whose values are all the same;
%let todrop = ;
%do i = 1 %to &nro_vars;
	%let vari = %scan(&var, &i, ' ');
	%let varfixi = %scan(&varfix, &i, ' ');
	%let nro_cutvalues = %GetNroElements(&&cutvalues&i);
	%* Analysis of the indicator variable of missing values;
	%let freqvari = &prefixdummy&varfixi;
	proc freq data=&out_name noprint;
		tables &freqvari / out=_PT_freq_;
	run;
	%callmacro(getnobs, _PT_freq_ return=1, nobs);
	%* Variable that tells whether the indicator variable of missing values has to be dropped or 
	%* not because all its values are the same (this happens when the variable &vari has no missing values);
	%local drop&i.0;
	%let drop&i.0 = 0;
	%if &nobs <= 1 %then %do;		
		%let todrop = &todrop &freqvari;
		%let drop&i.0 = 1;
	%end;

	%* Analysis of the dummy variables indicating each piece of the piecewise linear transformation;
	%do j = 1 %to %eval(&nro_cutvalues+1);
		%let freqvari = &prefixdummy&varfixi&suffix&j;
		proc freq data=&out_name noprint;
			tables &freqvari / out=_PT_freq_;
		run;
		%callmacro(getnobs, _PT_freq_ return=1, nobs);
		%* Variable that tells whether the current dummy variable &i&j has to be dropped or not
		%* because all its values are the same.
		%* This happens when one or more cut values fall out of the variable range.
		%* It is used to drop the variable from the output dataset as all its values are the same;
		%local drop&i&j;
		%let drop&i&j = 0;
		%if &nobs <= 1 %then %do;
			%let todrop = &todrop &freqvari;
			%let drop&i&j = 1;
		%end;
	%end;
%end;

data &out;
	drop &todrop;
	set &out_name;
	%* Global macro variable containing:
	%* - the list of ALL dummy variables created
	%* - the list of ALL piecewise variables created;
	%global _dummylist_ _pwlist_;
	%let _dummylist_ = ;
	%let _pwlist_ = ;
	%do i = 1 %to &nro_vars;
		%let vari = %scan(&var, &i, ' ');
		%let varfixi = %scan(&varfix, &i, ' ');
		%let nro_cutvalues = %GetNroElements(&&cutvalues&i);
		%* Global macro variables containing:
		%* - the list of dummy variables created for variable &vari
		%* - the list of piecewise variables created for variable &vari; 
		%* NOTE that macro variable names are ALSO restricted to 32 characters maximum length! That is why we use &varfixi here
		%* instead of the original name &vari...;
		%global &prefixdummy&varfixi &prefix&varfixi;
		%let &prefixdummy&varfixi = ;
		%let &prefix&varfixi = ;
		
		%* Add the indicator of missing values for current variable &vari to the list of
		%* dummy variables for variable &vari, if it was not dropped from the dataset above;
		%if ~&&drop&i.0 %then
			%let &prefixdummy&varfixi = &prefixdummy&varfixi;
			%** Do not get confused because the name of the macro variable is the same as its
			%** value. This is OK (an example of this assignment would be: %let I_x = I_x);

		%* Iterate on the cut values;
		%let cutvaluejm1 = 0;	%* Set the first Previous-Cut-Value to 0 as no shift should be done for the leftmost piece;
		%do j = 1 %to &nro_cutvalues;
/* 2016/03: THIS IS PART OF THE ATTEMPT MENTIONED BELOW WHEN I USE THE VARIABLE addpw&i&j... see below for more info
			retain addpw&i&j 0;		%* Dataset variable that indicates whether the piecewise variable should be added to the output dataset.
									%* This happens when the variable is not always 0;
*/

			%let cutvaluej = %scan(&&cutvalues&i, &j, ' ');

			%* Add the indicator variable to the list of indicator variables for variable I if it is not doomed to be dropped;
			%* Note that only INDICATOR variables are dropped NOT the LINEAR variables! (since the linear pieces are needed for
			%* the regression, whereas the indicator variables to be dropped (i.e. with all its value the same) only generate
			%* redundancy in the regression model;
			%* NOTE however that the linear variables may also have all their values equal and this happens when the corresponding
			%* indicator variable is 0, which in turn happens when e.g. the last cut is out of the variables range;
			%* Note that in that case we still keep the varible in the output because to drop it we should do another data step!
			%* See below for more info where I mention the ATTEMPT; 
			%if ~&&drop&i&j %then
				%let &prefixdummy&varfixi = &&&prefixdummy&varfixi &prefixdummy&varfixi&suffix&j;

			%********************************** Compute the PIECEWISE variable ********************************;
			%* Note that this is created regardless of whether the corresponding dummy variable is doomed to be dropped from the
			%* output dataset. Otherwise, when the variable has no missing values, the first piecewise variable would not be created
			%* (as all the values of the corresponding dummy variable are equal to 1);
			&prefix&varfixi&suffix&j = &prefixdummy&varfixi&suffix&j * ( (&vari - &cutvaluejm1) * (&vari &operator &cutvaluej) + (&cutvaluej - &cutvaluejm1) * (not(&vari &operator &cutvaluej)) );
			%********************************** Compute the PIECEWISE variable ********************************;

/* 2016/03: THIS WAS AN ATTEMPT TO CHECK IN THIS DATA STEP IF WE NEED TO ADD THE PIECEWISE VARIABLE.
but it is TOO COMPLICATED, because of the call symput() issue, where it is not easy to create the variable name at the LASTOBS
record making the nme of the variable build up with &I and &J... So I quit!
			%* Check if at least one value of the current piecewise variable being processed is non 0;
			%* In that case, we should add the piecewise variable to the output dataset, o.w. drop it;
			%* BUT THIS REQUIRES A FURTHER DATA STEP!!!!;
			if &prefix&varfixi&suffix&j ~= 0 then
				addpw&i&j = 1;
*/
			%* Add the piecewise variable just created to the list of piecewise variables created for the currently analyzed variable &vari;
			%let &prefix&varfixi = &&&prefix&varfixi &prefix&varfixi&suffix&j;
			%* Update the value of the previous cut;
			%let cutvaluejm1 = &cutvaluej;
		%end;

		%* Add the last piece;
		%let j = %eval(&nro_cutvalues + 1);
		%* Add the indicator variable to the list of indicator variables for variable I if it is not doomed to be dropped;
		%* Note that only INDICATOR variables are dropped NOT the PIECEWISE variables! (since the piecewise variables are needed for
		%* the regression, whereas the indicator variables to be dropped (i.e. with all its value the same) only generate
		%* redundancy in the regression model;
		%if ~&&drop&i&j %then
			%let &prefixdummy&varfixi = &&&prefixdummy&varfixi &prefixdummy&varfixi&suffix&j;

		%* Compute the last piecewise variable;
		&prefix&varfixi&suffix&j = &prefixdummy&varfixi&suffix&j * ( (&vari - &cutvaluejm1) * 1 );

		%* Add the piecewise variable just created to the list of piecewise variables created for the currently analyzed variable &vari;
		%let &prefix&varfixi = &&&prefix&varfixi &prefix&varfixi&suffix&j;

		%* Add all the indicator/piecewise variables for variable I to the list of indicator/piecewise variables;
		%let _dummylist_ = &_dummylist_ &&&prefixdummy&varfixi;
		%let _pwlist_ = &_pwlist_ &&&prefix&varfixi;
		%if &log %then %do;
			%put;
			%put PIECEWISETRANSF: Global macro variable &prefixdummy&varfixi created with the list of;
			%put PIECEWISETRANSF: the DUMMY variables for %upcase(&vari) generated in dataset %upcase(&out_name).;
			%put PIECEWISETRANSF: Global macro variable &prefix&varfixi created with the list of;
			%put PIECEWISETRANSF: the PIECEWISE variables for %upcase(&vari) generated in dataset %upcase(&out_name).;
		%end;
	%end;
	%if &log %then %do;
		%put;
		%put ************************************************************************************************;
		%put PIECEWISETRANSF: Global macro variable _dummylist_ created with the list of;
		%put PIECEWISETRANSF: ALL the DUMMY variables generated in dataset %upcase(&out_name).;
		%put PIECEWISETRANSF: Global macro variable _pwlist_ created with the list of;
		%put PIECEWISETRANSF: ALL the PIECEWISE variables generated in dataset %upcase(&out_name).;
		%put ************************************************************************************************;
	%end;
run;

%* Show the list of dummy and piecewise variables created in the output dataset;
%if &log %then %do;
	%put;
	%put PIECEWISETRANSF: The following DUMMY variables were created in dataset %upcase(&out_name):;
	%put PIECEWISETRANSF: &_dummylist_;
	%put PIECEWISETRANSF: The following PIECEWISE variables were created in dataset %upcase(&out_name):;
	%put PIECEWISETRANSF: &_pwlist_;
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
