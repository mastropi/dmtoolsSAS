/* MACRO %InformationValue
Version: 	3.02
Author: 	Daniel Mastropietro
Created: 	06-Jul-2005
Modified: 	15-Apr-2016 (previous: 15-Feb-2016)

DESCRIPTION:
This macro computes the Information Value (IV) provided by a set of input variables w.r.t.
a binary target variable.
The input variables can be either categorical or continuous. In the latter case, the
input variable is categorized into the specified number of groups.

The macro optionally creates an output dataset containing formats that allow reproducing the
categorization carried out by the macro on the continuous analysis variables.

For more details on the calculation of the Information Value see DETAILS below.

USAGE:
%InformationValue(
	data,						*** Input dataset.
	target=,					*** Dichotomous target variable.
	var=,						*** Analysis variables (character or numeric).
	event=,						*** Event of interest.
	groups=,					*** Nro. of groups to use to categorize numeric variables. Leave it empty for categorical variables.
	value=, 					*** Statistic to show for each category of numeric variables.
	format=,					*** Format to use for each analysis variable.
	smooth=1,					*** Whether to smooth the WOE calculation in order to avoid missing values.
	out=_InformationTable_,		*** Output dataset containing the WOE and IV for each bin of the categorized variables.
	outiv=_InformationValue_,	*** Output dataset containing the Information Value for each variable.
	outformat=,					*** Output dataset containing format definitions corresponding to the information value bins.
	notes=1,					*** Show SAS notes in the log?
	log=1);						*** Show messages in the log?

REQUIRED PARAMETERS:
- data:			Input dataset. Data options can be specified as in a data= SAS option.

- target:		Dichotomous target variable. It can be either character or numeric.

OPTIONAL PARAMETERS:
- var:			Blank-separated list of variables to analyze.
				The variables can be either character or numeric, or both.
				default: all variables in the dataset except for the target variable

- event:		The event of interest.
				If the target variable is character then:
				- Its value must be enclosed in quotation marks.
				- The specification of the event is case sensitive and it must respect
				the case of the values taken by the target variable.
				If the value specified does not correspond to any value taken by the target
				variable, the default is used.
				default: the largest target value

- groups:		Number of groups to use for the categorization of numeric variables listed in VAR=.
				Equal size groups are used.
				Leave it empty if no categorization is wished. For instance, for categorical variables.
				default: 10

- value:		Statistic to show for each category of numeric variables, such as the mean.
				default: empty => each category is represented by an arbitrary integer value (normally
				going from 1 to the number of groups, but this depends on how variable values are grouped)

- format:		Format to use for each analysis variable listed in VAR. This statement can be
				used to define groups.
				Just the format name needs to be specified, and only one format is allowed, which
				applies to ALL the variables listed in VAR=.

- smooth:		Flag indicating whether to smooth or not the computation of the WOE to avoid
				missing values of WOE in extreme situations when the same value of the target
				variable is observed for all cases in a category of the analyzed input variable.
				The smoothing factor is set to 0.5/
				Possible values: 0 => do not smooth, 1 => smooth
				default: 1

- out:			Output dataset containing the distribution of the target variable for each value
				of the variables listed in VAR.
				Data options can be specified as in a data= SAS option.
				The dataset has the following columns:
				- var: 			Variable name.
				- numvalue(*):	Value taken by the numeric variables.
				- charvalue(*):	Value taken by the character variables.
				- n: 			Number of observations in the dataset with non missing values of the
								analysis variable and the target variable.
				- nNonEvent: 	Number of Non-Events.
				- pcntNonEvent:	Percent of Non-Events.
				- nEvent: 		Number of Events.
				- pcntEvent: 	Percent of Events.
				- WOE: 			Weight Of Evidence of the corresponding value of the analysis variable.
				- IV:			Information Value of the analysis variable.
				(*) If all the analysis variables are character or all the analysis variables are
				numeric, there is only one column containing the values taken by the variables whose 
				name is VALUE. In this case, the columns NUMVALUE and CHARVALUE are not present in 
				the output dataset.
				default: _InformationTable_

- outiv:		Output datase containing the Information Value of each variable listed in VAR.
				Data options can be specified as in a data= SAS option.
				The dataset has the following columns:
				- var: 		Variable name.
				- n: 		Number of observations in the dataset with non missing values of the
							analysis variable and the target variable.
				- nvalues: 	Number of distinct values taken by the variable.
				- nused:	Number of distinct values of the variable that were used in the 
							computation of the Information Value. This is the same as the number
							of variable values for which the WOE is missing, which corresponds
							to values for which the information provided is infinite.
				- IV:		Information Value of the analysis variable.
				default: _InformationValue_

- ouformat:		Output dataset containing the formats that could be applied to each input variable
				in order to reproduce the categorization performed by this macro.
				IMPORTANT: This dataset is only created when VALUE=MAX, as the format definition
				is based on knowing the right-end value of each bin.

				This dataset can be used as CNTLIN dataset in the PROC FORMAT statement.
				The following variables are included in the OUTFORMAT dataset:
				- var: analyzed variable name.
				- fmtname: format name.
				- type: type of format (equal to "N" which means "numeric").
				- start: left end value of each category (length 20).
				- end: right end value of each category (length 20).
				- sexcl: flag Y/N indicating whether the start value is included/excluded in each category.
				- eexcl: flag Y/N indicating whether the end value is included/excluded in each category.
				- label: label to use for each category (length 200).

				The format name is generated automatically and has the following form:
				IV_<nnnn>R
				where:
				- <nnnn> is a 4-digit identifier of the format which corresponds to the analyzed
				numeric variable number when they are sorted alphabetically.
				- R means that the right-end value is included in each category.

				IMPORTANT: It is assumed that the number of digits including decimal point in the
				start and end values of each category is not larger than 20 when those numbers are
				expressed in BEST8. format.

				default: (empty)

- notes:		Indicates whether to show SAS notes in the log.
				The notes are shown only for the PROC MEANS step.
				Possible values: 0 => No, 1 => Yes.
				default: 0

- log:			Show messages in the log?
				Possible values: 0 => No, 1 => Yes
				default: 1

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Callmacro
- %Categorize
- %CreateFormatsFromCuts
- %ExecTimeStart
- %ExecTimeStop
- %ExistVar
- %FreqMult
- %Getnobs
- %GetVarList
- %Means
- %RemoveFromList
- %ResetSASOptions
- %SetSASOptions

DETAILS:
Information Value calculation:
Assuming that the possible values taken by the target variable are 0 and 1, and that the event
of interest is 1, the expression for the Information Value (IV) is the following:

	IV = Sum{j=1 to J} { [P(j/1) - P(j/0)] * WOE(j)}

where:
- j is the group or bin identifier of the groups of the input categorical variable or the groups
into which the input continuous variable is categorized,
- J is the number of different values taken by the categorized variable,
- P(j/b) is the proportion of cases falling into bin j when the target variable takes the value b,
- WOE(j) = ln(P(j/1)/P(j/0)) is the Weight-Of-Evidence of category j w.r.t. to target value 1.d

In order to avoid an undefined value of WOE(j), a smoothing factor is used by default in its
computation, which is equal to smooth_factor = 0.5/(#cases in the analyzed variable), making the
expression for the smoothed WOE equal to:
	Smoothed_WOE(j) = ln( (P(j/1) + smooth_factor) / (P(j/0) + smooth_factor) )

The value 0.5 corresponds to a 0.5 adjustment done originally on the COUNTS (which is then
translated to a COMMON adjustment on the probabilities by dividing by the number of analyzed cases. 

The use of the smoothing factor can be eliminated by setting parameter SMOOTH=0.

Notes:
N1) The IV is ALWAYS non-negative, since a positive/negative difference of probabilities
P(j/b) implies a positive/negative value of WOE.

N2) The WOE is computed based on the value specified in parameter EVENT as the event of interest.
If no value is specified or the value does not correspond to any possible target value, the default
event is used, i.e. the largest target value (the concept of largest is extended to character target
variables based on the alphabetical order).

For ex., if the possible target values are 0 and 1 and the EVENT parameter is empty, then the WOE
is computed as ln(P(j/1)/P(j/0)). Otherwise, if EVENT=0, the WOE is computed as ln(P(j/0)/P(j/1)).

Note that this results in a computation that is contrary to the definition of WOE usually given in the
literature, where it is computed as:
	ln(P(j/0)/P(j/1))
**regardless** of the event of interest.
The WOE definition used here favors intuition since a positive WOE in a bin implies an event penetration
that is larger than the average event penetration (event rate).

APPLICATIONS:
1.- Have a measure of the information provided by character and numeric variables in the exploratory
phase of building a model to predict a dichotomous target variable. This measure does not require that
the relationship between the variable and the target variable be linear, as is required by other measures
such as the KS or Gini.
However, the following two notes should be taken into account when computing the Information Value:
	- Continuous variables should be analyzed in categories (using the FORMAT= parameter for example).
	- The Information Value computation does not take into account the size of each categorical value.
	This means that if a category is too small with respect to the number of observations in the dataset
	and provides a lot of information about the target variable, this may not be reflected in the
	Information Value.
	However, at the same time, since the category is too small, it may not be good to have a large
	Information Value for the variable, since that category may not occur so often in the data being
	modelled.

2.- This macro could help in identifying variables whose inclusion in a logistic regression may produce
quasi-complete separation, which means that the variable is almost a perfect separator of the target
variable.
Such variables could be identified by looking at the number of distinct values of the analysis variable
that are used in the computation of the Information Value (stored in column NUSED of the OUTIV= dataset).
If this value is too small with respect to the number of distinct values taken by the analysis variable
(stored in column NVALUES of the OUTIV= dataset), it means that for many variable values the target value
is only one (as opposed to 2), giving a missing value of the WOE, which means that the information provided
by that value is infinite.
*/
&rsubmit;
%MACRO InformationValue(data,
						target=,
						var=_ALL_,
						event=,
						groups=10,
						value=,
						format=,
						smooth=1,
						out=_InformationTable_,
						outiv=_InformationValue_,
						outformat=,
						notes=0,
						log=1,
						help=0) / store des="Computes the Information Value of categorical variables w.r.t. a dichotomous variable";
/*
TODO:
- (2016/04/15) Add a flag parameter MISSING that requests to include missing values in the input variables as valid values to
be included in the Information Value analysis and calculation.
In principle this could be accomplished by generating both the categorical and statistic-valued categorical variables when calling
%Categorize (i.e. add the generation of the categorical _cat variables in that call) and set the categorical variable to 0 when
it is missing (note that the %Categorize macro keeps the missing values of the input variables as missing both in the _CAT and in the
_VALUE categorized variables.
*/

/*----- Macro to display usage -----*/
%MACRO ShowMacroCall;
	%put;
	%put INFORMATIONVALUE: The macro call is as follows:;
	%put;
	%put %nrstr(%InformationValue%();
	%put data , (REQUIRED) %quote(         *** Input dataset.);
	%put target= , %quote(                 *** Target dichotomous variable.);
	%put var=_ALL_ , %quote(               *** Analysis variables.);
    %put event= , %quote(                  *** Event of interest.);
    %put groups=20 , %quote(               *** Nro. of groups to use to categorize numeric variables.);
    %put value= , %quote(                  *** Statistic to show for the categories of numeric variables.);
	%put format= , %quote(                 *** Format to be used for selected analysis variables.);
	%put smooth=1 , %quote(                *** Whether to smooth the WOE calculation in order to avoid missing values.);
	%put out=_InformationTable_, %quote(   *** Output dataset containin the WOE and IV for each bin of the categorized variables.);
	%put outiv=_InformationValue_ , %quote(*** Output dataset containing the Information Value for each analysis variable.);
	%put outformat= , %quote(              *** Output dataset containing format definitions corresponding to the information value bins.);
	%put notes=1 , %quote(                 *** Show SAS notes in the log?);
	%put log=1) %quote(                    *** Show messages in the log?);
%MEND ShowMacroCall;
/*----- Macro to display usage -----*/

%if &help %then %do;
	%ShowMacroCall;
%end;
%else %if ~%CheckInputParameters(data=&data, var=&var, check=target, otherRequired=&target, requiredParamNames=data target=, macro=INFORMATIONVALUE) %then %do;
		%ShowMacroCall;
%end;
%else %do;
/************************************* MACRO STARTS ******************************************/
%local bothTypes;
%local error nobs nvar out_name outiv_name;
%local TargetType;
%local value0 value1;
%local varlen;
%local var_num;

%SetSASOptions(notes=&notes);
%ExecTimeStart;

%* Show input parameters;
%if &log %then %do;
	%put;
	%put INFORMATIONVALUE: Macro starts;
	%put;
	%put INFORMATIONVALUE: Input parameters:;
	%put INFORMATIONVALUE: - Input dataset = %quote(&data);
	%put INFORMATIONVALUE: - target = %quote(       &target);
	%put INFORMATIONVALUE: - var = %quote(          &var);
    %put INFORMATIONVALUE: - event = %quote(        &event);
    %put INFORMATIONVALUE: - groups = %quote(       &groups);
    %put INFORMATIONVALUE: - value = %quote(        &value);
	%put INFORMATIONVALUE: - format = %quote(       &format);
	%put INFORMATIONVALUE: - smooth = %quote(       &smooth);
	%put INFORMATIONVALUE: - out = %quote(          &out);
	%put INFORMATIONVALUE: - outiv = %quote(        &outiv);
	%put INFORMATIONVALUE: - outformat = %quote(    &outformat);
	%put INFORMATIONVALUE: - notes = %quote(        &notes);
	%put INFORMATIONVALUE: - log = %quote(          &log);
	%put;
%end;

/*--------------------------------- Parse Input Parameters ----------------------------------*/
%*** DATA;
%* Read input dataset and apply data set options;
%* This is done here because below when the macro %FreqMult is invoked, a filter is used on the
%* target variable in order to eliminate its missing occurrences, and this is done with a data option;
data _iv_data_(keep=_iv_obs_ &target &var);
	format _iv_obs_;
	set &data;
	_iv_obs_ = _N_;
run;

%let error = 0;
%*** TARGET=;
%* Check whether the target variable has only 2 possible variables and find those values;
proc freq data=_iv_data_ noprint;
	tables &target / out=_iv_target_;
run;
%* Remove the observation corresponding to missing values of TARGET and create macro variables
%* storing the possible values taken by the TARGET variable;
data _iv_target_;
	set _iv_target_ end=lastobs;
	where not missing(&target);
	if _N_ = 1 then
		call symput ('value0', trim(left(&target)));	%* This is the smallest value of the target variable;
	if _N_ = 2 then
		call symput ('value1', trim(left(&target)));	%* This is the largest value of the target variable;
	%* Store the type of the target variable in a macro variable to be used below;
	if lastobs then do;
		if vtype(&target) = "C" then
			call symput ('TargetType', "C");
		else
			call symput ('TargetType', "N");
	end;
run;
%Callmacro(getnobs, _iv_target_ return=1, nobs);
%if &nobs ~= 2 %then %do;
	%put INFORMATIONVALE: The number of values taken by the target variable (%upcase(&target)) is not 2, but &nobs..;
	%put INFORMATIONVALE: The information value cannot be computed on this data.;
	%let error = 1;
%end;

%if ~&error %then %do;

%*** EVENT=;
%if %quote(&event) = %then %do;
	%if &TargetType = C %then %do;
		%let event = "&value1";
		%let reference = 0;		%* The smallest target value is used as the reference value;
	%end;
	%else %do;
		%let event = &value1;
		%let reference = 0;		%* The smallest target value is used as the reference value;
	%end;
%end;
%else %do;
	%let reference = 0;
	%* Note that here the value of EVENT is compared with &value0 so that when the value specified
	%* in parameter EVENT is not a valid target value, the default reference value is used for the
	%* computation of the WOE (i.e. reference = 0);
	%if &TargetType = C %then %do;
		%if &event = "&value0" %then
			%let reference = 1;		%* The largest target value is used as the reference value;
		%else %do;
			%if &event ~= "&value1" %then
				%put INFORMATIONVALUE: WARNING - Event &event was not found. The default will be used instead.;
			%let event = "&value1";	%* Set the event equal to the largest target value;
		%end;
	%end;
	%else %do;
		%if &event = &value0 %then
			%let reference = 1;		%* The largest target value is used as the reference value;
		%else %do;
			%if &event ~= &value1 %then
				%put INFORMATIONVALUE: WARNING - Event &event was not found. The default will be used instead.;
			%let event = &value1;	%* Set the event equal to the largest target value;
		%end;
	%end;
%end;
%if &log %then
	%put INFORMATIONVALUE: The event of interest is: %upcase(&target)=&event;

%*** VAR=;
%* Remove the target variable from the list of analysis variables in case parameter VAR is _ALL_,
%* _NUMERIC_ or _CHAR_;
%if %quote(%upcase(&var)) = _ALL_ or %quote(%upcase(&var)) = _CHAR_ or %quote(%upcase(&var)) = _NUMERIC_ %then %do;
	%let var = %GetVarList(_iv_data_, var=&var, log=0);
	%let var = %RemoveFromList(&var, &target, log=0);
%end;

%*** SMOOTH=;
%* Define the smoothing factor adjusting the COUNTS in the calculation of the WOE in order to avoid missing values;
%if &smooth %then
	%let smooth_factor = 0.5;
%else
	%let smooth_factor = 0;
/*--------------------------------- Parse Input Parameters ----------------------------------*/

%if %quote(&groups) ~= %then %do;
	%if &log %then %do;
		%put;
		%put INFORMATIONVALUE: Categorizing numeric variables into &groups groups.;
		%if %quote(&value) ~= %then
			%put INFORMATIONVALUE: and using %upcase(&value) as representation of each group.;
	%end; 
	%* Categorize numeric variables;
	data _iv_data_num_;
		set _iv_data_(keep=_NUMERIC_ drop=&target);
	run;
	%let var_num = %GetVarList(_iv_data_num_, var=_NUMERIC_);
	%let var_num = %RemoveFromList(&var_num, _iv_obs_, log=0);
	%if %quote(&value) = %then %do;
		%* The categorized variable is made up of integer-valued categories. 
		%* Use the same variable name for the categorized variable so that the process below is easier;
%*		%Categorize(_iv_data_num_, var=&var_num, groups=&groups, suffix=, log=0);
		%* DM-2016/02/15: Refactored version of %Categorize (much simpler);
		%Categorize(_iv_data_num_, var=&var_num, groups=&groups, varcat=&var_num, log=0);
	%end;
	%else %do;
		%* The categorized variable is made up of categories equal to the statistic specified in VALUE=.
		%* Use the same variable name for the categorized variable so that the process below is easier;
		%Categorize(_iv_data_num_, var=&var_num, groups=&groups, value=&value, varvalue=&var_num, log=0);
	%end;
	data _iv_data_;
		merge 	_iv_data_(in=in1)
				_iv_data_num_;
		by _iv_obs_;
		if in1;
	run;
%end;

%* Note the use of the option SPARSE so that in the output dataset all the possible combinations of the
%* variables are output, regardless of whether there are or there are no observations. This is done
%* because we need to create the datasets _FREQ0_ and _FREQ1_ with the same number of observations.
%* If the SPARSE option were not used, the number of observations in these datasets will be different
%* whenever for a given value of an analysis variable only ONE value of the target variable occurs;
%* The WHERE= option in the _IV_DATA_ is used in order to avoid the presence of variable values in the
%* _FREQMULT_ dataset for which the only occurrence of the target variable is the missing value. If
%* the WHERE= option were not used, we could have a Division by Zero error in the data stet where the WOE
%* and the Information Value are computed because the sum of count0 and count1 could be 0.
%* Note that this option is required because the SPARSE option is also used (which is also needed);
%FreqMult(_iv_data_(where=(not missing(&target))), target=&target, var=&var, format=&format, options=outpct SPARSE, out=_iv_freqmult_, log=0);
%* Check whether all the variables in VAR are of the same type or not;
%if (%ExistVar(_iv_freqmult_, numvalue charvalue, log=0)) %then
	%let bothTypes = 1;
%else
	%let bothTypes = 0;
%* Sort the _iv_FreqMult_ dataset by the VAR variables, because the order in which they appear in it
%* is the one given by the order in which they are listed in the VAR= parameter;
%* Note that it is not necessary to sort by the column containing the values taken by the variables
%* because the dataset generated by %FreqMult is already sorted by this column;
proc sort data=_iv_freqmult_;
	by var;
run;
%* Divide the output dataset FREQMULT into two datasets, one containing the numbers and
%* percentages for target = &value0 and the other containing those for target = &value1;
data _iv_freq0_ _iv_freq1_;
	set _iv_freqmult_;
	format percent pct_row pct_col 7.1;

	%if &bothTypes %then %do;
	where not (missing(numvalue) and missing(charvalue));
	%end;
	%else %do;
	where not missing(value);
	%end;

	%if &TargetType = C %then %do;
		if &target = "&value0" then output _iv_freq0_;
		else if &target = "&value1" then output _iv_freq1_;
	%end;
	%else %do;
		if &target = &value0 then output _iv_freq0_;
		else if &target = &value1 then output _iv_freq1_;
	%end;
run;
%* Merge the numbers for target = &value0 and for target = &value1 into one dataset, one row per each
%* value of each analysis variable;
data _iv_freq03_;
	merge 	_iv_freq0_(drop=&target nvalues rename=(count=count0 percent=percent0 pct_row=pct_row0 pct_col=pct_col0))
			_iv_freq1_(drop=&target nvalues rename=(count=count1 percent=percent1 pct_row=pct_row1 pct_col=pct_col1));
	%if &bothTypes %then %do;
	by var numvalue charvalue;
	%end;
	%else %do;
	by var value;
	%end;
run;

%* Compute the total number of &value0 and &value1 by each variable;
%Means(
	_iv_freq03_, 
	by=var, 
	stat=n sum,
	var=count0 count1, 
	out=_iv_sum03_(drop=count1_n rename=(count0_n=nvalues)),
	log=0
);

%*** Compute WOE and Information Value. The reference value for these computations is the
%*** &value0 value of the target variable. This means that the WOE is computed as log(P(j/1)/P(j/0));
%let outiv_name = %scan(&outiv, 1, '(');
data _iv_freq03_(drop=nused)
	 &outiv_name(keep=var nobs nvalues nused IVTotal rename=(nobs=n IVTotal=IV));
	format var nobs nvalues nused;
	format WOE IV IVTotal 10.3;
	merge 	_iv_freq03_(in=in1)
			_iv_sum03_(in=in2);
	by var;
	if first.var then do;
		IVTotal = 0;
		nused = 0;
	end;
	format percent0 percent1 pct_row0 pct_row1 pct_col0 pct_col1 percent7.1;
	percent0 = count0 / (count0_sum + count1_sum);
	percent1 = count1 / (count0_sum + count1_sum);
	pct_row0 = count0 / (count0 + count1);
	pct_row1 = count1 / (count0 + count1);
	pct_col0 = count0 / count0_sum;
	pct_col1 = count1 / count1_sum;

	%if &reference = 0 %then %do;
	pdiff = pct_col1 - pct_col0;		%* P(j/1) - P(j/0);
	%end;
	%else %do;
	pdiff = pct_col0 - pct_col1;		%* P(j/0) - P(j/1);
	%end;

	if pct_col1 + &smooth_factor ~= 0 and pct_col0 + &smooth_factor ~= 0 then do;

		%if &reference = 0 %then %do;
		WOE = log( (pct_col1 + &smooth_factor/(count0_sum+count1_sum)) / (pct_col0 + &smooth_factor/(count0_sum+count1_sum)) );	%* P(j/1) / P(j/0) possibly adjusted by a smoothing factor;
		%end;
		%else %do;
		WOE = log( (pct_col0 + &smooth_factor/(count0_sum+count1_sum)) / (pct_col1 + &smooth_factor/(count0_sum+count1_sum)) );	%* P(j/0) / P(j/1) possibly adjusted by a smoothing factor;
		%end;

		IV = WOE*pdiff;
		IVTotal + IV;
		nused + 1;
	end;
	else do;
		WOE = .;
		IV = .;
		%** Note that for the non smoothed version of WOE, missing values of WOE are possible and they
		%** exclude the corresponding observation from contributing to the Information Value (IV).
		%** A missing value of WOE occurs for a value of the analysis variable for which the target variable
		%** is COMPLETELY determined, which means that the information provided by knowing that particular
		%** value of the variable is infinite!
		%** This means that the information provided by the analysis variable should be larger than
		%** the information provided should there be no missing values of WOE.
		%** I verified this with a numerical example (i.e. the absolute value of IV decreased when
		%** all values of WOE were not missing w.r.t. the absolute value of IV obtained when one of the WOE
		%** values was missing). I simply replaced, say TARGET = &value0 with TARGET = &value1, at one 
		%** single observation for which the analysis variable takes the value for which WOE is missing and
		%** looked at how the IV changed;
	end;
	output _iv_freq03_;
	if last.var then output &outiv_name;

	label 	nvalues = "Number of Distinct Values"
			nused 	= "Number of Distinct Values used in the IV Computation"
			WOE 	= "Weight of Evidence"	/* This name comes from the SAS help for the Credit Scoring node in Enterprise Miner */
			IV 		= "Information Value"
			IVTotal = "Information Value";
run;
%* Execute output dataset options;
data &outiv;
	set &outiv_name;
run;
%if &log %then %do;
	%callmacro(getnobs, &outiv return=1, nobs nvar);
	%put;
	%put INFORMATIONVALUE: Dataset %upcase(&outiv_name) created with &nobs observations and &nvar variables;
	%put INFORMATIONVALUE: containing the Information Value for each variable.;
%end;

/*------------------------------------ Output Table -----------------------------------------*/
%*** Dataset with distribution of target variable for each variable;
%* Read length of variable VAR containing the name of the analysis variables, so that I can set the
%* length of VAR as the maximum between the length of --Total-- and the length of VAR as coming
%* from macro %FreqMult, in order to avoid truncation of the string --Total-- when the names of the
%* variables are shorter than this string;
proc contents data=_iv_freq03_ out=_iv_contents_(keep=name length) noprint;
run;
data _NULL_;
	set _iv_contents_;
	where upcase(name) = "VAR";
	call symput ('varlen', trim(left(length)));
run;
%let varlen = %sysfunc(max(%length(--Total--), &varlen));
data &out;
	format var 	%if &bothTypes %then %do; numvalue charvalue %end;
			   	%else %do; value %end; n
				%if &reference = 0 %then %do; n0 pcnt0 n1 pcnt1; %end;
				%else %do; n1 pcnt1 n0 pcnt0; %end; %* This %IF is done so that the non-event always appears first;
	format WOE IV 10.3;
	length var $&varlen;
	set _iv_freq03_(keep=var %if &bothTypes %then %do; numvalue charvalue %end; 
							 %else %do; value %end; 
						 nobs count0 pct_row0 count1 pct_row1 WOE IV IVTotal
					rename=(count0=n0 count1=n1 
							pct_row0=pcnt0 pct_row1=pcnt1));
	by var;
	array reset(*) n0_sum n1_sum;
	if first.var then
		do i = 1 to dim(reset);
			reset(i) = .;
		end;
	format pcnt0 pcnt1 percent7.1;
	n = n0 + n1;
	n0_sum + n0;
	n1_sum + n1;
	if last.var then do;
		output;
		var = "--Total--";

		%if &bothTypes %then %do;
		numvalue = .;
		charvalue = "";
		%end;
		%else %do;
		if vtype(value) = "C" then
			value = "";
		else
			value = .;
		%end;

		n = nobs;
		n0 = n0_sum;
		n1 = n1_sum;
		pcnt0 = n0 / n;
		pcnt1 = n1 / n;
		WOE = .;
		IV = IVTotal;
	end;
	output;
	%* Variable labels;
	%if %quote(&value) = %then %do;
	label %if &bothTypes %then %do; numvalue %end; %else %do; value %end; = "dummy category";
	%end;
	%else %do;
	label %if &bothTypes %then %do; numvalue %end; %else %do; value %end; = "&value value";
	%end;
	label 	n		= "# observations"
			n0		= "# &value0"
			n1		= "# &value1"
			pcnt0 	= "% &value0"
			pcnt1	= "% &value1";
	%if &reference = 0 %then %do;
	rename 	n0 = nNonEvent
			n1 = nEvent
			pcnt0 = pcntNonEvent
			pcnt1 = pcntEvent;
	%end;
	%else %do;
	rename 	n0 = nEvent
			n1 = nNonEvent
			pcnt0 = pcntEvent
			pcnt1 = pcntNonEvent;
	%end;
	drop i nobs n0_sum n1_sum IVTotal;
run;
%if &log %then %do;
	%let out_name = %scan(&out, 1, '(');
	%callmacro(getnobs, &out_name return=1, nobs nvar);
	%put INFORMATIONVALUE: Dataset %upcase(&out_name) created with &nobs observations and &nvar variables;
	%put INFORMATIONVALUE: containing the Information Table.;
%end;
/*------------------------------------ Output Table -----------------------------------------*/


/*----------------------------------- Formats Table -----------------------------------------*/
%if %quote(&outformat) ~= %then %do;
	%local dsid rc;
	%local varnum vartype;
	%local cutvar;
	%* Only generate the OUTFORMAT dataset when the value representing each bin is the MAX value,
	%* since the formats definition is based on knowing the upper value of each bin;
	%if %upcase(&value) ~= MAX %then
		%put INFORMATIONVALUE: WARNING - No OUTFORMAT dataset is created because parameter VALUE <> MAX.;
	%else %do;
		%* Create the FORMATS dataset;
		%* This assumes that the macro was called with value=MAX so that those values can be used as right limit
		%* of each bin and thus create the formats definition;
		%if &bothTypes %then
			%let cutvar = numvalue;
		%else %do;
			%* Check if VALUE is numeric;
			%let dsid = %sysfunc(open(&out));
			%let varnum = %sysfunc(varnum(&dsid, VALUE));
			%let vartype = %sysfunc(vartype(&dsid, &varnum));
			%if %upcase(&vartype) ~= N %then %do;
				%put INFORMATIONVALUE: WARNING - No OUTFORMAT dataset is created because the analyzed variables are not numeric.;
				%let cutvar = ;
			%end;
			%else;
				%let cutvar = value;
			%let rc = %sysfunc(close(&dsid));
		%end;
		%if %quote(&cutvar) ~= %then %do;
			%let out_name = %scan(&out, 1, '(');
			%* The input dataset for %CreateFormatsFromCuts excludes the cases that correspond to character variables (&cutvar ~= .)
			%* which may exist when both numeric and character variables are analyzed. Note that in that case &cutvar=numvalue
			%* so the used condition is fine;
			%* Note also that the condition &cutvar~=. also eliminates the record with var="--Total--" that should not be considered;
			%CreateFormatsFromCuts(&out_name(where=(&cutvar~=.)), dataformat=long, cutname=&cutvar, varname=var, includeright=1, out=&outformat, log=0);

			%if &log %then %do;
				%callmacro(getnobs, &outformat return=1, nobs nvar);
				%put INFORMATIONVALUE: Dataset %upcase(&outformat) created with &nobs observations and &nvar variables;
				%put INFORMATIONVALUE: containing the format definitions associated with the information value bins.;
				%put INFORMATIONVALUE: Use PROC FORMAT CNTLIN=%upcase(&outformat) FMTLIB%str(;) RUN%str(;);
				%put INFORMATIONVALUE: to run the formats and store them in the FORMATS catalog of the WORK library.;
			%end;
		%end;
	%end;
%end;
/*----------------------------------- Formats Table -----------------------------------------*/
%end;	%* %if ~&error;

proc datasets nolist;
	delete 	_iv_contents_
			_iv_data_
			_iv_data_num_
			_iv_freq0_
			_iv_freq1_
			_iv_freq01_
			_iv_freq02_
			_iv_freq03_
			_iv_freqmult_
			_iv_sum03_
			_iv_target_;
quit;

%if &log %then %do;
	%put;
	%put INFORMATIONVALUE: Macro ends;
	%put;
%end;

%ExecTimeStop;
%ResetSASOptions;

%end;	%* %if ~%CheckInputParameters;
%MEND InformationValue;
