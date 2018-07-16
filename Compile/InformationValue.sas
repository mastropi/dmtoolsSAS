/* MACRO %InformationValue
Version: 	4.01
Author: 	Daniel Mastropietro
Created: 	06-Jul-2005
Modified: 	10-Jan-2018 (previous: 17-Jun-2017, 17-May-2016, 15-Apr-2016)

DESCRIPTION:
This macro computes the Information Value (IV) provided by a set of input variables w.r.t.
a binary target variable.

The input variables can be either categorical or continuous. In the continuous case, the
input variable is categorized into the specified number of groups.

Note that ALL numeric variables are considered continuous if the GROUPS= parameter is not empty.
If GROUPS= is empty, they are considered categorical.
In order to analyze a set of numeric variables that include both categorical and continuous
variables, the analysis should be run separately, once on the categorical variables and
once for the continuous variables.

The macro optionally creates an output dataset containing formats that allow reproducing the
categorization carried out by the macro on the continuous analysis variables.

For more details on the calculation of the Information Value see the DETAILS section below.

USAGE:
%InformationValue(
	data,						*** Input dataset.
	target=,					*** Dichotomous target variable.
	var=_ALL_,					*** Analysis variables (character or numeric).
	event=,						*** Event of interest.
	groups=10,					*** Nro. of groups to use to categorize numeric variables. Leave it empty if ALL analyzed variables are categorical.
	condition=,					*** Condition that each analysis variable should satisfy in order to be part of the grouping.
	stat=, 						*** Statistic to use as representation of each category of numeric variables.
	format=,					*** Formats to use for each analysis variable.
	smooth=1,					*** Whether to smooth the WOE calculation in order to avoid missing values.
	out=_InformationValue_,		*** Output dataset containing the Information Value for each variable.
	outwoe=_InformationWOE_,	*** Output dataset containing the WOE and IV for each bin of the categorized variables.
	outformat=,					*** Output dataset containing format definitions corresponding to the WOE bins.
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

- condition:	Expression specifying a condition that each numeric variable should satisfy in order to
				be part of the grouping process.
				Ex:
				condition=~=0, meaning that 0 values are not grouped, but left on their own.
				condition=%quote(not in (0, 1)), meaning that 0 and 1 values are left on their own.
				default: empty => all values are considered during the grouping process

- stat:			Statistic to show for each category of numeric variables, such as the mean.
				default: empty => each category is represented by an arbitrary integer value (normally
				going from 1 to the number of groups, but this depends on how variable values are grouped)

- format:		Formats to use for selected analysis variables listed in VAR and/or for the TARGET variable.
				This statement can be used to define groups.
				The formats should be specified as in any FORMAT statement.
				Ex:
				var1 varf.
				var2 varg.

- smooth:		Flag indicating whether to smooth or not the computation of the WOE to avoid
				missing values of WOE in extreme situations when the same value of the target
				variable is observed for all cases in a category of the analyzed input variable.
				The smoothing factor is set to 0.5/
				Possible values: 0 => do not smooth, 1 => smooth
				default: 1

- out:			Output datase containing the Information Value of each variable listed in VAR.
				Data options can be specified as in a data= SAS option.
				The dataset has the following columns:
				- var: 			Variable name.
				- n: 			Number of observations in the dataset with non missing values of the
								analysis variable and the target variable.
				- nvalues: 		Number of distinct values taken by the variable.
				- nused:		Number of distinct values of the variable that were used in the 
								computation of the Information Value. This is the same as the number
								of variable values for which the WOE is missing, which corresponds
								to values for which the information provided is infinite.
				- IV:			Information Value of the analysis variable.
				- IVAdj:		Adjusted Information Value based on the number of cases in each bin
								and on the number of groups that contribute to the IV.
				- EntropyRel:	Entropy of the analyzed variable relative to the maximum possible entropy
								(which occurs when all categories of the analyzed variable have the same
								number of cases).
				default: _InformationValue_

- outwoe:		Output dataset containing the distribution of the target variable for each value
				of the variables listed in VAR.
				Data options can be specified as in a data= SAS option.
				The dataset has the following columns:
				- var: 			Variable name.
				- numvalue(*):	Value taken by the numeric variables in the corresponding bin.
				- charvalue(*):	Value taken by the character variables in the corresponding bin.
				- n: 			Number of observations in the dataset with non missing values of the
								target variable for the corresponding bin.
				- pcnt:			Proportion of observations in the dataset with non missing values of
								the target variable for the corresponding bin.
				- nNonEvent: 	Number of Non-Events in the corresponding bin.
				- pcntNonEvent:	Proportion of Non-Events in the corresponding bin.
				- nEvent: 		Number of Events in the corresponding bin.
				- pcntEvent: 	Proportion of Events in the corresponding bin.
				- WOE: 			Weight Of Evidence of the analysis variable by the corresponding bin.
				- IV:			Contribution to the Information Value of the analysis variable by the
								corresponding bin.
				- IVAdj:		Contribution to the Adjusted Information Value of the analysis variable
								by the corresponding bin.
				(*) If all the analysis variables are character or all the analysis variables are
				numeric, there is only one column containing the values taken by the variables whose 
				name is VALUE. In this case, the columns NUMVALUE and CHARVALUE are not present in 
				the output dataset.
				default: _InformationWOE_

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
- WOE(j) = ln(P(j/1)/P(j/0)) is the Weight-Of-Evidence of category j w.r.t. to target value 1

Note that the WOE can be interpreted as logit(P(1/j)) - logit(P(1)), i.e. the Delta Logit observed
in category j w.r.t. the overall population logit.
In practice the WOE is adjusted by the number of cases in the category, i.e. the weight is reduced
*towards 0* by the value log(J)/ncases(j) i.e.:
	WOE_adj(j) 	= max(0, WOE(j) - log(J)/ncases(j)) if WOE(j) >= 0
				= min(0, WOE(j) + log(J)/ncases(j)) if WOE(j) < 0
This adjustment makes it possible for categories with too few cases (for which the information
provided about the target variable is unreliable) have a WOE = 0.

The IV expression can also be interpreted as follows, in terms of the event probability:
	IV = Sum{j=1 to J} { N(j)/N { [P(1/j)/P(1) - P(0/j)/P(0)] * [logit(P(1/j)) - logit(P(1)] }

where we observe that every term in the summation is weighted by N(j)/N, i.e. the proportion
of observations in category j.

In order to avoid an undefined value of WOE(j), a smoothing factor is used by default in its
computation, which is equal to smooth_factor = 0.5/(#cases in the analyzed variable), making the
expression for the smoothed WOE equal to:
	WOE_smoothed(j) = ln( (P(j/1) + smooth_factor) / (P(j/0) + smooth_factor) )

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
	- Continuous variables should be analyzed in categories (using the GROUPS= parameter or the FORMAT= parameter).
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
that are used in the computation of the Information Value (stored in column NUSED of the OUT= dataset).
If this value is too small with respect to the number of distinct values taken by the analysis variable
(stored in column NVALUES of the OUT= dataset), it means that for many variable values the target value
is only one (as opposed to 2), giving a missing value of the WOE, which means that the information provided
by that value is infinite.
*/
&rsubmit;
%MACRO InformationValue(data,
						target=,
						var=_ALL_,
						event=,
						groups=10,
						condition=,
						stat=,
						format=,
						smooth=1,
						out=_InformationValue_,
						outwoe=_InformationWOE_,
						outformat=,
						notes=0,
						log=1,
						help=0) / store des="Computes the Information Value of categorical variables w.r.t. a dichotomous variable";

/*----- Macro to display usage -----*/
%MACRO ShowMacroCall;
	%put;
	%put INFORMATIONVALUE: The macro call is as follows:;
	%put;
	%put %nrstr(%InformationValue%();
	%put data , (REQUIRED) %quote(       *** Input dataset.);
	%put target= , %quote(               *** Target dichotomous variable.);
	%put var=_ALL_ , %quote(             *** Analysis variables.);
    %put event= , %quote(                *** Event of interest.);
    %put groups=20 , %quote(             *** Nro. of groups to use to categorize numeric variables.);
	%put condition= , %quote(            *** Condition that each analysis variable should satisfy in order to be part of the grouping.);
    %put stat= , %quote(                 *** Statistic to show for the categories of numeric variables.);
	%put format= , %quote(               *** Formats to be used for selected analysis variables or target.);
	%put smooth=1 , %quote(              *** Whether to smooth the WOE calculation in order to avoid missing values.);
	%put out=_InformationValue_ , %quote(*** Output dataset containing the Information Value for each analysis variable.);
	%put outwoe=_InformationWOE_, %quote(*** Output dataset containin the WOE and IV for each bin of the categorized variables.);
	%put outformat= , %quote(            *** Output dataset containing format definitions corresponding to the WOE bins.);
	%put notes=1 , %quote(               *** Show SAS notes in the log?);
	%put log=1) %quote(                  *** Show messages in the log?);
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
%local error nobs nvar out_name out_name;
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
    %put INFORMATIONVALUE: - condition = %quote(    &condition);
    %put INFORMATIONVALUE: - stat = %quote(         &stat);
	%put INFORMATIONVALUE: - format = %quote(       &format);
	%put INFORMATIONVALUE: - smooth = %quote(       &smooth);
	%put INFORMATIONVALUE: - out = %quote(          &out);
	%put INFORMATIONVALUE: - outwoe = %quote(       &outwoe);
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
%* Remove the target variable from the list of analysis variables in case parameter VAR is _ALL_, _NUMERIC_ or _CHAR_;
%if %quote(%upcase(&var)) = _ALL_ or %quote(%upcase(&var)) = _CHAR_ or %quote(%upcase(&var)) = _NUMERIC_ %then %do;
	%let var = %GetVarList(_iv_data_, var=&var, log=0);
	%let var = %RemoveFromList(&var, &target _iv_obs_, log=0);
%end;

%** GROUPS=;
%* Define the number of groups to use for the IV adjustement (it is equal to the specified number of groups if this
%* is given, if not it is set to 10, because the thresholds normally used to define weak, middle, or strong variables
%* are supposedly based on an IV computed on 10 groups;
%let nadj = 10;
%if &groups ~= %then
	%let nadj = &groups;

%*** SMOOTH=;
%* Define the smoothing factor adjusting the COUNTS in the calculation of the WOE in order to avoid missing values;
%if &smooth %then
	%let smooth_factor = 0.5;
%else
	%let smooth_factor = 0;

%*** OUT=, OUTTABLE=;
%let out_name = %scan(&out, 1, '(');
%let outwoe_name = %scan(&outwoe, 1, '(');
/*--------------------------------- Parse Input Parameters ----------------------------------*/

%if %quote(&groups) ~= %then %do;
	%if &log %then %do;
		%put;
		%put INFORMATIONVALUE: Categorizing numeric variables into &groups groups.;
		%if %quote(&stat) ~= %then
			%put INFORMATIONVALUE: and using %upcase(&stat) as representation of each group.;
	%end; 
	%* Categorize numeric variables;
	data _iv_data_num_;
		set _iv_data_(keep=_NUMERIC_ drop=&target);
	run;
	%let var_num = %GetVarList(_iv_data_num_, var=_NUMERIC_);
	%let var_num = %RemoveFromList(&var_num, _iv_obs_, log=0);
	%if %quote(&stat) = %then %do;
		%* The categorized variable is made up of integer-valued categories. 
		%* Use the same variable name for the categorized variable so that the process below is easier;
%*		%Categorize(_iv_data_num_, var=&var_num, groups=&groups, suffix=, log=0);
		%* DM-2016/02/15: Refactored version of %Categorize (much simpler);
		%Categorize(_iv_data_num_, var=&var_num, groups=&groups, varcat=&var_num, condition=&condition, log=&log);
	%end;
	%else %do;
		%* The categorized variable is made up of categories equal to the statistic specified in STAT=.
		%* Use the same variable name for the categorized variable so that the process below is easier;
		%Categorize(_iv_data_num_, var=&var_num, groups=&groups, condition=&condition, stat=&stat, varstat=&var_num, log=&log);
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
%* The MISSING=0 option just means that the NOBS column in the output dataset should count the number of
%* non-missing values, but still missing values are stored in the output table;
%FreqMult(_iv_data_(where=(not missing(&target))), target=&target, var=&var, format=&format, options=outpct SPARSE, missing=0, out=_iv_freqmult_, log=0);
%* Check whether all the variables in VAR are of the same type or not;
%if (%ExistVar(_iv_freqmult_, numvalue charvalue, log=0)) %then
	%let bothTypes = 1;
%else
	%let bothTypes = 0;
%* Sort the _iv_FreqMult_ dataset by the VAR variables and values to merge, because the order in which
%* they appear in it is the one given by the order in which they are listed in the VAR= parameter;
%* In addition we need to sort by the column containing the values taken by the variables
%* because, even though the dataset generated by %FreqMult sorts the values, this sorting may be
%* by their FORMATTED values which may not coincide with the sorting by the actual values...;
proc sort data=_iv_freqmult_;
	by var %if &bothTypes %then %do; numvalue charvalue %end; %else %do; value %end;;
run;
%* Divide the output dataset FREQMULT into two datasets, one containing the numbers and
%* percentages for target = &value0 and the other containing those for target = &value1;
data _iv_freq0_ _iv_freq1_;
	set _iv_freqmult_;
	format percent pct_row pct_col 7.1;
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
data _iv_freq01_;
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
	_iv_freq01_, 
	by=var, 
	stat=n sum,
	var=count0 count1, 
	out=_iv_sum01_(drop=count1_n rename=(count0_n=nvalues)),
	log=0
);

%*** Compute WOE and Information Value. The reference value for these computations is the
%*** &value0 value of the target variable. This means that the WOE is computed as log(P(j/1)/P(j/0));
data _iv_freq01_(drop=nused)
	 _iv_out_(keep=var nobs nmiss nvalues nused pct_row1_min pct_row1_max pct_row1_delta IVTotal IVTotalAdj /*IVTotalEntropyAdj EntropyTotal*/ EntropyTotalRel
			  rename=(nobs=n pct_row1_min=pcntEventMin pct_row1_max=pcntEventMax pct_row1_delta=pcntEventRange IVTotal=IV IVTotalAdj=IVAdj /*IVTotalEntropyAdj=IVEntropyAdj EntropyTotal=Entropy*/ EntropyTotalRel=EntropyRel));
	format var nobs nmiss nvalues nused pct_row1_min pct_row1_max pct_row1_delta;
	format WOE IV IVTotal IVAdj IVTotalAdj IVEntropyAdj IVTotalEntropyAdj Entropy EntropyTotal 10.3;
	format pct_row1_min pct_row1_max pct_row1_delta EntropyTotalRel percent7.1;
	merge 	_iv_freq01_(in=in1)
			_iv_sum01_(in=in2);
	by var;
	retain pct_row1_min pct_row1_max;
	if first.var then do;
		IVTotal = 0;
		EntropyTotal = 0;
		nmiss = 0;
		nused = 0;
		pct_row1_min = .;
		pct_row1_max = .;
	end;
	format percent0 percent1 pct_row0 pct_row1 pct_col0 pct_col1 percent7.1;
	percent0 = count0 / (count0_sum + count1_sum);
	percent1 = count1 / (count0_sum + count1_sum);
	pct_row0 = count0 / (count0 + count1);
	pct_row1 = count1 / (count0 + count1);
	pct_col0 = count0 / count0_sum;
	pct_col1 = count1 / count1_sum;

	%* Update the minimum and maximum percent of the event for this variable;
	pct_row1_min = min(of pct_row1_min pct_row1);
	pct_row1_max = max(of pct_row1_max pct_row1);

	%if &reference = 0 %then %do;
	pdiff = pct_col1 - pct_col0;		%* P(j/1) - P(j/0);
	%end;
	%else %do;
	pdiff = pct_col0 - pct_col1;		%* P(j/0) - P(j/1);
	%end;

	%* Count the number of missing values taken by the analyzed variable;
	if %if &bothTypes %then %do; missing(numvalue) and missing(charvalue) %end; %else %do; missing(value) %end; then
		nmiss + count0 + count1;

	%* Compute the WOE and the IV for the current category or bin;
	if pct_col1 + &smooth_factor ~= 0 and pct_col0 + &smooth_factor ~= 0 then do;

		%if &reference = 0 %then %do;
		WOE = log( (pct_col1 + &smooth_factor/(count0_sum+count1_sum)) / (pct_col0 + &smooth_factor/(count0_sum+count1_sum)) );	%* P(j/1) / P(j/0) possibly adjusted by a smoothing factor;
		%end;
		%else %do;
		WOE = log( (pct_col0 + &smooth_factor/(count0_sum+count1_sum)) / (pct_col1 + &smooth_factor/(count0_sum+count1_sum)) );	%* P(j/0) / P(j/1) possibly adjusted by a smoothing factor;
		%end;

		%* (2017/06/18) Correction by log(K)/ncases based on the paper by Quinlan "Improved use of continuous attributes in C4.5";
		if WOE > 0 then
			WOE = max(0, WOE - log(nvalues)/(count0 + count1));		%* WOE - log(K)/ncases(k) lower bounded by 0;
		else
			WOE = min(0, WOE + log(nvalues)/(count0 + count1));		%* WOE + log(K)/ncases(k) upper bounded by 0;

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
		%** the information provided when there are no missing values of WOE.
		%** I verified this with a numerical example (i.e. the absolute value of IV decreased when
		%** all values of WOE were not missing w.r.t. the absolute value of IV obtained when one of the WOE
		%** values was missing). I simply replaced, say TARGET = &value0 with TARGET = &value1, at one 
		%** single observation for which the analysis variable takes the value for which WOE is missing and
		%** looked at how the IV changed;
	end;

	%* Entropy of the analyzed variable to be used for the IV adjustment by the number of groups in the analyzed variable when adjust=1;
	count = count0 + count1;
	Entropy = -(count/(count0_sum + count1_sum)) * log(count/(count0_sum + count1_sum));
	EntropyTotal + Entropy;
	%* IV adjusted by number of groups. See definition of &nadj at the beginning;
	IVAdj = IV * log(&nadj) / log(nvalues);					%* Note: here we need to adjust by the number of categories used in the computation of IV.
															%* At this point, this information is stored in nvalues which comes from _FreqMult_.
															%* Later on nvalues will contain the number of non-missing categories and nused will
															%* contain the number of categories used in the computation of IV (this value is constructed as we speak...);
	%* Total Entropy-adjusted IV;
	IVTotalEntropyAdj = IVTotal * (1 + EntropyTotal) / (1 + log(nvalues));
	%* Total adjusted IV;
%*	IVTotalAdj = IVTotal * &nadj / nvalues;
%*	IVTotalAdj = IVTotal / (1 + EntropyTotal);				%* 1+ to avoid division by 0 when the variable takes only 1 value, and also to always divide by a number larger than 1 thus making IVAdj <= IV;
%*	IVTotalAdj = IVTotalEntropyAdj * log(&nadj) / log(nvalues);		%* NOTE that we use nvalues and NOT nused because nused does not
																	%* yet contain the number of categories used as it is being computed now;
	IVTotalAdj = IVTotal * log(&nadj) / log(nvalues);

	output _iv_freq01_;
	if last.var then do;
		if nmiss > 0 then
			nvalues = nvalues - 1;		%* Decrease nvalues by one because it counts the number of distinct non-missing categories taken by the variable;
										%* Note that nused is NOT decreased by 1 because this measures the number of categories used in the calculation
										%* of IV and missing values ARE used for the IV;
		%* Compute range of percent of event observed over all categories;
		pct_row1_delta = pct_row1_max - pct_row1_min;
		%* Compute the Entropy relative to the maximum possible entropy (which happens when all cases are distributed equally in the categories);
		EntropyTotalRel = EntropyTotal / log(nused);
		output _iv_out_;
	end;

	label 	nmiss				= "# Missing Observations"
			nvalues 			= "# Non-missing Categories"
			nused 				= "# Categories used in the IV Computation"
			pct_row1_min		= 'Min of %Event'
			pct_row1_max		= 'Max of %Event'
			pct_row_delta		= 'Range of %Event'
			WOE 				= "Weight of Evidence"	/* This name comes from the SAS help for the Credit Scoring node in Enterprise Miner */
			IV 					= "Information Value"
			IVTotal 			= "Information Value"
			IVAdj				= "Adjusted Information Value"
			IVTotalAdj			= "Adjusted Information Value"
			IVEntropyAdj 		= "Entropy-adjusted Information Value"
			IVTotalEntropyAdj 	= "Entropy-adjusted Information Value"
			Entropy 			= "Variable Entropy"
			EntropyTotal 		= "Variable Entropy"
			EntropyTotalRel		= "Variable Entropy Relative to Max. Entropy";
run;
%* Execute output dataset options;
%if %quote(&out) ~= %then %do;
	data &out;
		set _iv_out_;
	run;
	%if &log %then %do;
		%callmacro(getnobs, &out return=1, nobs nvar);
		%put;
		%put INFORMATIONVALUE: Dataset %upcase(&out_name) created with &nobs observations and &nvar variables;
		%put INFORMATIONVALUE: containing the Information Value for each variable.;
	%end;
%end;


%if %quote(&outwoe) ~= or %quote(&outformat) ~= %then %do;
	/*------------------------------- Output Table with WOE -------------------------------------*/
	%*** Dataset with distribution of target variable for each variable;
	%* Read length of variable VAR containing the name of the analysis variables, so that I can set the
	%* length of VAR as the maximum between the length of --Total-- and the length of VAR as coming
	%* from macro %FreqMult, in order to avoid truncation of the string --Total-- when the names of the
	%* variables are shorter than this string;
	proc contents data=_iv_freq01_ out=_iv_contents_(keep=name length) noprint;
	run;
	data _NULL_;
		set _iv_contents_;
		where upcase(name) = "VAR";
		call symput ('varlen', trim(left(length)));
	run;
	%let varlen = %sysfunc(max(%length(--Total--), &varlen));
	data _iv_outwoe_;
		keep var %if &bothTypes %then %do; numvalue charvalue %end; %else %do; value %end; n pcnt n0 pcnt0 n1 pcnt1 WOE IV IVAdj;
		format var 	%if &bothTypes %then %do; numvalue charvalue %end;
				   	%else %do; value %end; n pcnt
					%if &reference = 0 %then %do; n0 pcnt0 n1 pcnt1; %end;
					%else %do; n1 pcnt1 n0 pcnt0; %end; %* This %IF is done so that the non-event always appears first;
		format WOE IV IVAdj /*IVEntropyAdj Entropy*/ 10.3;
		length var $&varlen;
		merge 	_iv_freq01_(keep=var %if &bothTypes %then %do; numvalue charvalue %end; 
								 %else %do; value %end; 
							 	 nobs count0 pct_row0 count1 pct_row1 WOE IV IVTotal IVAdj IVTotalAdj /*IVEntropyAdj IVTotalEntropyAdj Entropy*/
							rename=(count0=n0 count1=n1 
									pct_row0=pcnt0 pct_row1=pcnt1))
				_iv_out_(keep=var nmiss nused /*Entropy rename=(Entropy=EntropyTotal)*/);
		by var;
		array reset(*) n0_sum n1_sum;
		if first.var then
			do i = 1 to dim(reset);
				reset(i) = .;
			end;
		format pcnt pcnt0 pcnt1 percent7.1;
		n = n0 + n1;
		pcnt = n / (nobs + nmiss);		%* Recall: nobs comes from _FreqMult_ and it counts the number of VALID observations (i.e. non-missing). This is why we need to sum nmiss to it to compute pcnt;
		n0_sum + n0;
		n1_sum + n1;
		%* Compute the IV for each group adjusted by the variable total entropy;
%*		IVEntropyAdj = IV * (1 + EntropyTotal) / (1 + log(nused));	%* 1+ to avoid division by 0 when the variable takes only 1 value, and also to always divide by a number larger than 1 thus making IVAdj <= IV;
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

			n = nobs + nmiss;
			pcnt = 1;
			n0 = n0_sum;
			n1 = n1_sum;
			pcnt0 = n0 / n;
			pcnt1 = n1 / n;
			WOE = .;
			IV = IVTotal;
			IVAdj = IVTotalAdj;
%*			IVEntropyAdj = IVTotalEntropyAdj;
%*			Entropy = EntropyTotal;
		end;
		output;
		%* Variable labels;
		%if %quote(&stat) = %then %do;
		label %if &bothTypes %then %do; numvalue %end; %else %do; value %end; = "dummy category";
		%end;
		%else %do;
		label %if &bothTypes %then %do; numvalue %end; %else %do; value %end; = "&stat value";
		%end;
		label 	n		= "# observations"
				pcnt	= "% observations"
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
%*		drop i nobs nmiss nused n0_sum n1_sum IVTotal IVTotalEntropyAdj IVTotalAdj EntropyTotal;
	run;
	%if %quote(&outwoe) ~= %then %do;
		data &outwoe;
			set _iv_outwoe_;
		run;
		%if &log %then %do;
			%callmacro(getnobs, &outwoe_name return=1, nobs nvar);
			%put INFORMATIONVALUE: Dataset %upcase(&outwoe_name) created with &nobs observations and &nvar variables;
			%put INFORMATIONVALUE: containing the Information Table with WOE values for each bin.;
		%end;
	%end;
	/*------------------------------- Output Table with WOE -------------------------------------*/


	/*----------------------------------- Formats Table -----------------------------------------*/
	%if %quote(&outformat) ~= %then %do;
		%local dsid rc;
		%local varnum vartype;
		%local cutvar;
		%* Only generate the OUTFORMAT dataset when the value representing each bin is the MAX value,
		%* since the formats definition is based on knowing the upper value of each bin;
		%if %upcase(&stat) ~= MAX %then
			%put INFORMATIONVALUE: WARNING - No OUTFORMAT dataset is created because parameter STAT <> MAX.;
		%else %do;
			%* Create the FORMATS dataset;
			%* This assumes that the macro was called with value=MAX so that those values can be used as right limit
			%* of each bin and thus create the formats definition;
			%if &bothTypes %then
				%let cutvar = numvalue;
			%else %do;
				%* Check if VALUE is numeric;
				%let dsid = %sysfunc(open(_iv_outwoe_));
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
				%* The input dataset for %CreateFormatsFromCuts excludes the cases that correspond to character variables (&cutvar ~= .)
				%* which may exist when both numeric and character variables are analyzed. Note that in that case &cutvar=numvalue
				%* so the used condition is fine;
				%* Note also that the condition &cutvar~=. also eliminates the record with var="--Total--" that should not be considered;
				%* Note: the use of the PREFIX=iv_ is to mimic the prefix used in %PiecewiseTransf by default when generating the formats dataset (pw_);
				%CreateFormatsFromCuts(_iv_outwoe_(where=(&cutvar~=.)), dataformat=long, cutname=&cutvar, varname=var, includeright=1, prefix=iv_, out=&outformat, log=0);

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
%end;
%end;	%* %if ~&error;

proc datasets nolist;
	delete 	_iv_contents_
			_iv_data_
			_iv_data_num_
			_iv_freq0_
			_iv_freq1_
			_iv_freq01_
			_iv_freq02_
			_iv_freq01_
			_iv_freqmult_
			_iv_out_
			_iv_outwoe_
			_iv_sum01_
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
