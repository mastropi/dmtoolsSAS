/* MACRO %PiecewiseTransfCuts
Version: 	1.10
Author: 	Daniel Mastropietro
Created: 	03-Jan-2005
Modified: 	07-Aug-2017 (previous: 13-Jan-2005)

DESCRIPTION:
Macro that finds the best cut points for a linear piecewise transformation of ONE analysis continuous
variable that maximizes the R-Square of the multi-piece regression with respect to a CONTINUOUS target variable.

The best cut points are found among the values taken by the analysis continuous variable, as considering any
value in between two consecutive analysis variable values is the same as considering one of those values.

The analysis variable can take repeated values as these values are deduplicated before defining the cut values
to try out.

If the input dataset is appropriately prepared one can either:
- Analyze several input variables using BY processing
- Analyze a binary target variable
See the NOTES and the EXAMPLES sections for more details.

USAGE:
%PiecewiseTransfCuts(
	data, 					*** Input dataset. Data options are allowed.
	target=y,				*** Target variable (continuous)
	var=x,					*** Analysis variable (only one allowed)
	by=,					*** BY variables
	ncuts=15,				*** Number of cut values to try out to find the best cuts
	maxnpieces=3,			*** Max number of pieces in which to try piecewise regressions (<= 3)
	minpropcases=0.10,		*** Min proportion of cases that each piece must have
	out=_PTC_cuts_,			*** Output dataset containing the best cuts found for the analysis variable for each BY variable
	outall=_PTC_results_,	*** Output dataset contaniing the R-Squared and related measures for all cut values tried
	log=1);					*** Show messages in the log?

REQUIRED PARAMETERS:
- data:			Input dataset. Data options can be specified as in any DATA= option.

OPTIONAL PARAMETERS:
- target:		Continuous target variable used in the linear regressions that are performed 
				to determine the best cuts for the piecewise linear transformation.
				default: Y

- var:			Analysis variable used as predictor variable in the linear regressions
				performed to determine the best cuts for the piecewise linear transformation.
				Only ONE variable can be listed.
				NOTE: See NOTES below for directions on how to apply this analysis to more than
				one variable stored in different columns of the input dataset.
				default: X

- by:			List of by variables by which the analysis is performed.

- maxnpieces:	Maximum number of pieces to try for the multi-piece linear regression.
				Possible values are 2 and 3.
				default: 3

- minpropcases:	Minimum proportion of cases that should be present in each regression piece
				so as to guarantee R-Square values that are based on enough number of cases.
				default: 0.10

- ncuts:		Number of cut values to try out to find the best cuts.
				This number defines the step that takes from one cut value to the next and defines
				the approximate number of cut values to consider for the 2-piece linear regression.
				All the cut values are valid values of the analysis variable.
				Leave it empty to use all possible values taken by the analysis variable while satisfying
				the conditions specified by the other parameters.
				default: 15

- out:			Output dataset containing the best cuts found for each by variable combination.
				The output dataset has the following columns (in this order):
				- By variables passed in the BY= parameter.
				- _CUT_:	Best cut value ID: it can take the values 1 or 2. Number 1 indicates
							the smallest cut value found and number 2 indicates the largest
							cut value found. Number 2 is not present if the best cut values
							found may correspond to a 2-piece piecewise linear transformation.
				- _TARGET_:	Name of the target variable used in the analysis.
				- _VAR_:	Name of the regressor variable used in the analysis.
				- _VALUE_:	Value of the best cut value found that corresponds to the cut value
							ID given in column CUT. The cut value is one of the values taken
							by the regressor variable.
				- RSQ:		R-Square of the multi-piece linear regression.
							It is computed based on the sum of the RSS over all pieces and
							the Corrected Sum of Squares of the target variable (CSS(Y)) as:
								RSQ = 1 - sum(of RSS(piece)) / CSS(Y)
				- RMSE:		Root Mean Squared Error of the multi-piece linear regression.
							It is computed based on the sum of RSS over all pieces as:
								RMSE = sqrt( sum(of RSS(piece)) / sum(of n(piece)) )
							where n(piece) is the number of observations in each piece.
				- RSS: 		Sum of the Residual Sum of Squares over all pieces.
				default: _PTC_cuts_

- outall:		Output dataset containing the results for all the piecewise linear regressions
				tried out to find the best cuts.
				It has the following columns:
				- By variables passed in the BY= parameter.
				- _TARGET_:		Name of the target variable used in the analysis.
				- _VAR_:		Name of the regressor variable used in the analysis.
				- _CASE_:		ID identifying each combination of cut values analyzed to find the
								best cut values.
				- _XRANK1_:		Rank of the X value (among the values taken by X, the analysis variable)
								for the current case which corresponds to cut value CUT1.
				- _CUT1_:		First cut value for the current case.
				- _XRANK2_:		Rank of the X value (among the values taken by X, the analysis variable)
								for the current case which corresponds to cut value CUT1.
				- _CUT2_:		Second cut value for the current case.
				- N1:			Number of cases in piece 1 of the multi-piece linear regression.
				- N2:			Number of cases in piece 2 of the multi-piece linear regression.
				- N3:			Number of cases in piece 3 of the multi-piece linear regression.
				- RSQ:			R-Square of the multi-piece linear regression computed as defined
								above when describing the OUT= parameter.
				- RMSE:	 		Root Mean Squared Error of the multi-piece linear regressions computed
								as defined above when describing the OUT= parameter.
				- RSS:			Residual Sum of Squares of the multi-piece linear regressions.
				- RSS1-RSS3:	Residual Sum of Squares of pieces 1 thru 3.

				NOTE that nor the R-Square values nor the RMSE values are reported for each regression
				piece as these values are rather misleading since the total R-Square and RMSE values
				are computed on the basis of the RSS values in each piece, and NOT on the R-Square/RMSE
				values on each piece.

				default: _PTC_results_

- log:			Show messages in the log?
				Possible values are: 0 => No, 1 => Yes.
				default: 1

NOTES:
1.- APPLYING THE ANALYSIS TO MORE THAN ONE VARIABLE IN A DATASET
Create a new dataset obtained as the transposition of the columns of the input dataset containing
the analysis variables, using a code similar to the following, where:
- the analysis variables are X and Z,
- the target variable is Y,
- the column in the transposed dataset (TRANSPOSED) containing the values of X and Y is VALUE, and
- the column containing the name of the variable to which VALUE correspondes, is VAR.

data transposed;
	format var $32. value y;
	set original(keep=x z y);
	array cols x y;
	do i = 1 to dim(cols);
		value = cols(i);
		var = vname(cols(i));
		output;					*** This generates the record;
	end;
	drop x z;
run;
proc sort data=transposed out=transposed(drop=i);
	by i;
run;

Then call the macro %PiecewiseTransfCuts as follows:
%PiecewiseTransfCuts(transposed, target=y, var=value, by=var);

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %CheckInputParameters
- %CreateGroupVar
- %ExecTimeStart
- %ExecTimeStop
- %GetNroElements
- %GetStat
- %MakeList
- %MakeListFromVar
- %Means
- %Pretty
- %ResetSASOptions
- %SelectNames
- %SetSASOptions
- %ShowMacroCall

SEE ALSO:
- %PiecewiseTransf
- %VariableImpact

EXAMPLES:
1.- %PiecewiseTransfCuts(test, target=earning, var=x, out=cuts, outall=allcuts);
This creates the output datasets CUTS and ALLCUTS from the analysis of the relationship between
the continuous variable EARNING used as target variable and the continuous variable X used as
regressor variable contained in dataset TEST.
The dataset CUTS contains the best cuts found and the dataset ALLCUTS contains all the cases
analyzed for the cut values.

2.- %PiecewiseTransfCuts(test_vi, target=logit, var=value, by=var, out=cuts, outall=allcuts);
This creates the output datasets CUTS and ALLCUTS from the analysis of the relationship between
LOGIT (representing the logit(p) (= log(p/(1-p)) of a dichotomous target variable) and the
continuous variable VALUE, used as predictor variable. The analysis is done by the by variable
VAR which represents the variable to which the values stored in VALUE correspond.
The input dataset TEST_VI may well have been created using macro %VariableImpact applied to the
dataset TEST, where the target variable is the dichotomous target variable generating the variable
LOGIT in TEST_VI and the predictor variables are those given by the values of the variable VAR
in TEST_VI (e.g. the call to %VariableImpact could have been:
%VariableImpact(test, target=delinquent, var=x y z, out=test_vi), which generates
a dataset with column VAR (containing the values "x", "y" or "z" defining each analysis variable)
and column VALUE (containing the values of the categorized variables X, Y or Z)). 
The dataset CUTS contains the best cuts found for each by variable value (VAR) and the dataset
ALLCUTS contains all the cases analyzed for each by variable value.

Once the output dataset with the cuts found is generated, the following code can be used to
call the macro %PiecewiseTransf in order to transform the variables according to the cuts found.
proc transpose data=cuts out=cuts_t(drop=_NAME_) prefix=cut;
	by var;		* The variable that is to be transformed;
	id cut;		* The cut ID;
	var value;	* The variable containing the cut values;
run;
* Transform the variables using %PiecewiseTransf and create the new dataset TEST_PWT;
%PiecewiseTransf(
	test,
	cuts=cuts_t,
	prefix=I,
	join=_X_,
	fill=0,
	out=test_pwt,
	log=1);

APPLICATIONS:
This macro can be used to automatically find the best cut values to be used in a piecewise
linear transformation of a continuous variable with the aim of increasing its predictive power
of a target variable.
It can be used both for linear and logistic regression.
In linear regression, simply use the target variable of the linear regression as TARGET and the
continuous variable to be transformed as VAR.
In logistic regression, use the logit(p) (= log(p/(1-p))) --where p is the probability of the
event of interest being modelled by the logistic regression-- as TARGET and a variable obtained
from the categorization of the continuous variable used as predictor of the event of interest,
each category of which has a value of the logit.
In order to generate the data necessary to use this macro in the logistic regression framework,
the macro %VariableImpact may result useful. In fact, this macro computes the logit(p) for
each category of a categorized continuous variable. The continuous variable needs to be categorized
for this purpose, because otherwise the value of p (used in logit(p)) cannot be computed.
*/
&rsubmit;
%MACRO PiecewiseTransfCuts(data, target=y, var=x, by=, ncuts=15, maxnpieces=3, minpropcases=0.10, out=_PTC_cuts_, outall=_PTC_results_, log=1, help=0)
		/ store des="Finds the best cut points for a piecewise linear transformation to predict a continuous target";

/*----- Macro to display usage -----*/
%MACRO ShowMacroCall;
	%put PIECEWISETRANSFCUTS: The macro call is as follows:;
	%put %nrstr(%PiecewiseTransfCuts%();
	%put data , (REQUIRED) %quote( *** Input dataset.);
	%put target= , %quote(         *** Continuous Target variable.);
	%put var= , %quote(            *** Input analysis variable used as regressor (only one allowed).);
	%put by= , %quote(             *** List of BY variables.);
	%put ncuts= , %quote(          *** Number of cut values to try out to find the best cuts.);
	%put maxnpieces= , %quote(     *** Maximum number of pieces to try for the multi-piece linear regression.);
	%put minpropcases= , %quote(   *** Minimum proportion of cases that should be present in each regression piece.);
	%put out= , %quote(            *** Output dataset with the best cuts found.);
	%put outall= , %quote(         *** Output dataset with the results of all cuts tried.);
	%put log=1) %quote(            *** Show messages in the log?);
%MEND ShowMacroCall;

%if &help %then %do;
	%ShowMacroCall;
%end;
%else %if ~%CheckInputParameters(data=&data, varRequired=0,
								 otherRequired=, check=target var by,
								 requiredParamNames=data, macro=PIECEWISETRANSFCUTS) %then %do;
	%ShowMacroCall;
%end;
%else %do;
/************************************* MACRO STARTS ******************************************/
%SetSASOptions;
%ExecTimeStart;

%if &log %then %do;
	%put;
	%put PIECEWISETRANSFCUTS: Macro starts;
	%put;
%end;

%local obsvalues obssweep obs1 obs2 xvalues xsweep xn xmin xmax xfirst xlast first last step mincases;
%local cut1 cut1p cut2 cut2p;
%local b bb i j case;			%* Counters;
%local out_name outall_name;
%local byvars;
%local dkrocond_option;			%* Used to store current value of DKROCOND option;

%* Store current value of DKROCOND option that controls warnings for DROP, KEEP and RENAME statements;
%let dkrocond_option = %sysfunc(getoption(dkrocond));;

%* Show input parameters;
%if &log %then %do;
	%put;
	%put PIECEWISETRANSFCUTS: Macro starts;
	%put;
	%put PIECEWISETRANSFCUTS: Input parameters:;
	%put PIECEWISETRANSFCUTS: - Input dataset = %quote(&data);
	%put PIECEWISETRANSFCUTS: - target = %quote(       &target);
	%put PIECEWISETRANSFCUTS: - var = %quote(          &var);
	%put PIECEWISETRANSFCUTS: - by = %quote(           &by);
	%put PIECEWISETRANSFCUTS: - ncuts = %quote(        &ncuts);
	%put PIECEWISETRANSFCUTS: - maxnpieces = %quote(   &maxnpieces);
	%put PIECEWISETRANSFCUTS: - minpropcases = %quote( &minpropcases);
	%put PIECEWISETRANSFCUTS: - out = %quote(          &out);
	%put PIECEWISETRANSFCUTS: - outall = %quote(       &outall);
	%put PIECEWISETRANSFCUTS: - log = %quote(          &log);
	%put;
%end;


/*--------------------------------- Parse input parameters ----------------------------------*/
%*** DATA=;
data _PTC_data_;
	set &data;
	_GROUPID_ = 1;		%* Used if there are no by variables, to unify the code;
run;

%*** BY=;
%if %quote(&by) ~= %then %do;
	%let nro_byvars = %GetNroElements(&by);
	%CreateGroupVar(_PTC_data_(drop=_GROUPID_), by=&by, name=_GROUPID_, ngroups=nro_byvar_combos, log=0);
%end;
%else %do;
	%let nro_byvars = 1;
	%global nro_byvar_combos;	%* Nro. of different combinations of the values of the by variables;
	%let nro_byvar_combos = 1;
%end;

%*** MAXNPIECES=;
%if &maxnpieces > 3 %then
	%let maxnpieces = 3;
/*-------------------------------------------------------------------------------------------*/

%* Delete output datasets because they are used in PROC APPENDs to append the results obtained
%* for each by variable combination;
proc datasets nolist;
	delete 	_PTC_cuts_
			_PTC_results_;
quit;

%do b = 1 %to &nro_byvar_combos;
data _PTC_data_b_;
	set _PTC_data_ end=_lastobs_;
	where _GROUPID_ = &b;
	%* Observation ID;
	%if %quote(&by) ~= %then %do;
	if _lastobs_ then do;
		%do bb = 1 %to &nro_byvars;
		%local byvar&bb;
		call symput ('byvar_name'||trim(left(&bb)), "%scan(&by, &bb, ' ')");
		call symput ('byvar'||trim(left(&bb)), %scan(&by, &bb, ' '));
		%end;
	end;
	%end;
run;
%if &log and &nro_byvar_combos > 1 %then %do;
	%put;
	%put PIECEWISETRANSFCUTS: Doing the analysis for the following by variables combination:;
	%do bb = 1 %to &nro_byvars;
		%put PIECEWISETRANSFCUTS: %upcase(&&byvar_name&bb) = &&byvar&bb;
	%end;
%end;

/*---------------------------------- Single Regression --------------------------------------*/
%let case = 0;		%* Case label;
%* Do a single regression, to see if a piecewise transformation is necessary;
proc reg data=_PTC_data_b_ outest=_PTC_reg1_(rename=(_rmse_=RMSE _rsq_=RSQ)) rsquare noprint;
	reg1: model &target = &var;
	output out=_PTC_pred1_ predicted=fit residual=residual;
run;
quit;

%* Compute RMSE and RSQ;
data _PTC_rsq_all_;
	set _PTC_reg1_(keep=RMSE RSQ);
		%** Variables RMSE and RSQ are renamed to RMSE_mean and RSQ_mean because these are the
		%** variables used in the following cases when more than one regression is performed;
	%* Add information on independent and target variables;
	%if %quote(&by) ~= %then %do;
		%do bb = 1 %to &nro_byvars;
		length &&byvar_name&bb $32.;
		&&byvar_name&bb = "&&byvar&bb";
		%end;
	%end;
	length _var_ _target_ $32.;
	_var_ = "&var";
	_target_ = "&target";
	%* Identify case analyzed (defining the cut values used, which in this case is NO cuts);
	_case_ = &case;
	i = 0;
	j = 0;
	_xrank1_ = .;
	_cut1_ = .;
	%if &maxnpieces >= 3 %then %do;
	_xrank2_ = .;
	_cut2_ = .;
	%end;
	n1 = .;
	n2 = .;
	%if &maxnpieces >= 3 %then %do;
	n3 = .;
	%end;
run;

%* Compute RSS;
data _PTC_pred1_;
	set _PTC_pred1_;
	residual2 = residual*residual;
run;
%Means(_PTC_pred1_, var=residual2, stat=sum, name=RSS, out=_PTC_rss_, log=0);
data _PTC_rss_all_;
	format RSS RSS1 RSS2 %if &maxnpieces >= 3 %then %do; RSS3 %end;;
	set _PTC_rss_;
	%* Create RSS1-RSS3 because they are used in the following CASEs analyzed;
	RSS1 = RSS;
	%* RSS2-RSS3 are missing because there is only one regression here;
	RSS2 = .;
	%if &maxnpieces >= 3 %then %do; 
	RSS3 = .;
	%end;
run;

%* Create output dataset _PTC_results_b_ by putting all measures together;
data _PTC_results_b_;
	%if %quote(&by) ~= %then %do;
	format %do bb = 1 %to &nro_byvars; &&byvar_name&bb; %end;
	%end;
	format _target_ _var_ _case_ i j _cut1_ %if &maxnpieces >= 3 %then %do; _cut2_ %end;
									_xrank1_ %if &maxnpieces >= 3 %then %do; _xrank2_ %end; 
									n1 n2 %if &maxnpieces >= 3 %then %do; n3 %end; 
									RSQ RMSE RSS RSS1 RSS2 %if &maxnpieces >= 3 %then %do; RSS3 %end;;
	merge _PTC_rsq_all_ _PTC_rss_all_;
run;
/*-------------------------------------------------------------------------------------------*/


/*------------------------------------- Sweep values ----------------------------------------*/
%* Find distinct values of the analysis variable and assign a _RANK_ to each of them so that they are used
%* below to look for the best cuts;
proc sql noprint;
	create table _PTC_data_b_rank_ as
	select &var, count(*) as n_repeats
	from _PTC_data_b_
	group by &var
	order by &var;
quit;
data _PTC_data_b_rank_;
	set _PTC_data_b_rank_;
	_rank_ = _N_;
run;

%* Read all the values taken by the analysis variable into a macro variable;
%*%let xvalues = %MakeListFromVar(_PTC_data_b_, var=&var, log=0);
%let xvalues = %MakeListFromVar(_PTC_data_b_rank_, var=&var, log=0);
%* Read the observation values corresponding to the X values so that these can be identified
%* easily when merging with the input dataset in order to gather some additional information
%* corresponding to the optimum cuts found;
%let obsvalues = %MakeListFromVar(_PTC_data_b_rank_ , var=_rank_, log=0);
%let xn = %GetNroElements(&xvalues);

%* Min and Max values of x based on the minimum number of cases required in each regression piece;
%let mincases = %sysfunc(max(3, %sysfunc( floor( %sysevalf(&minpropcases*&xn) )) ));	%* 3 is the minimum possible number of cases required in each regression piece, regardless of the value of &minpropcases;
%if &log %then
	%put PIECEWISETRANSFCUTS: Each piece considered in the regressions will have at least &mincases cases.;
proc sql noprint;
	select &var into :xmin
	from _PTC_data_b_rank_
	where _rank_ = 1;

	select &var into :xmax
	from _PTC_data_b_rank_
	where _rank_ = &xn;
quit;

%* First and last value of x to use in the sweep of the cut values;
%* The values are defined so that there are enough points for the linear regression
%* in each piece defined by the cuts;
%let first = &mincases;
%let last = %sysfunc(max(0, %eval(&xn - &mincases) ));
%if &ncuts = %then
	%let step = 1;
%else %do;
	%let step = %sysfunc( max(0, %sysfunc(round( %sysevalf( (&last - &first) / &ncuts ) )) ));
	%* Check if there is only one value (the first value) to try as possible cut (because there are too few cases)
	%* => in this case try both the first and last value as cuts;
	%* (note that if we do not do this there will be an infinite loop below);
	%if &step = 0 %then
		%let step = %eval(&last - &first);
%end;

%* Values of X (xsweep) and of the X observation values (obssweep) on which the cuts are swept;
%* Note that the cuts can ONLY be values existing among the values of X, which makes sense because cutting
%* in between two values is the same as cutting on one of the actual values taken by X;
%let xsweep = ;
%let obssweep = ;
%let xfirst = ;
%let xlast = ;
%if %sysevalf(&first <= &last) %then %do;
	%let xsweep = %SelectNames(&xvalues, &first, &last);
	%let obssweep = %SelectNames(&obsvalues, &first, &last);
	%* First and last values of x for sweeping the cut values;
	%let xfirst = %scan(&xsweep, 1, ' ');
	%let xlast  = %scan(&xsweep, %GetNroElements(&xsweep), ' ');
	%* Extend &xsweep with one more value in x (which always exists because &mincases >= 3 (see above)
	%* so that border conditions when carrying the loop below are not a problem;
	%let xsweep = &xsweep %scan(&xvalues, &last + 1, ' ');
%end;

%if &log %then %do;
	%put PIECEWISETRANSFCUTS: The cut values considered for the search will be approx. &ncuts in total;
	%put PIECEWISETRANSFCUTS: spanning the X values between &xfirst and &xlast..;
	%put PIECEWISETRANSFCUTS: The minimum and maximum X values are %sysfunc(trim(%sysfunc(left(&xmin)))) and %sysfunc(trim(%sysfunc(left(&xmax)))).;
%end;
/*-------------------------------------------------------------------------------------------*/

/*------------------------------------- 2 Regressions ---------------------------------------*/
%if %GetNroElements(&xsweep) <= 1 %then %do;
	%if &log %then %do;
		%put;
		%put PIECEWISETRANSFCUTS: Not enough data to perform piecewise regressions.;
		%put PIECEWISETRANSFCUTS: Only a single regression is carried out.;
	%end;
%end;
%else %do;
	%let i = 1;
	%do %until (&cut1 = or &cut1 > &xlast or &step = 0);	%* &cut1 can be empty when the next value to try is out of range from the values in &xsweep. I also check for &step = 0 in case &first = &last and in that case the loop would never end if we do not check &step;
		%let case = %eval(&case + 1);						%* Cut case number;
		%let cut1 = %scan(&xsweep, &i, ' ');				%* Last x value to include in regression piece #1;
		%let cut1p = %scan(&xsweep, %eval(&i+1), ' ');		%* First x value to include in regression piece #2: it is the next possible value of x following &cut1;
		%let obs1 = %scan(&obssweep, &i, ' ');				%* Index of first observation included in regression piece #1;
		%if &log %then %do;
			%put PIECEWISETRANSFCUTS: Performing linear regressions in 2 pieces...;
			%if %quote(&by) ~= %then %do;
				%do bb = 1 %to &nro_byvars;
					%put PIECEWISETRANSFCUTS: %upcase(&&byvar_name&bb) = &&byvar&bb;
				%end;
			%end;
			%put PIECEWISETRANSFCUTS: Case=&case: cut = %Pretty(&cut1, roundoff=0.0001) (max ~ &xlast);
		%end;
		proc reg data=_PTC_data_b_ outest=_PTC_reg1_ rsquare noprint;
			where %sysevalf(0.999999*&xmin) <= &var <= %sysevalf(1.000001*&cut1);	%* I multiply by 1.000001 because o.w. value &cut1 is not always included in the range; 
			reg1: model &target = &var;
			output out=_PTC_pred1_ predicted=fit residual=residual;
		run;
		quit;
		proc reg data=_PTC_data_b_ outest=_PTC_reg2_ rsquare noprint;
			where %sysevalf(0.999999*&cut1p) <= &var <= %sysevalf(1.000001*&xmax);	%* I multiply by 1.000001 because o.w. value &xmax is not always included in the range;
			reg2: model &target = &var;
			output out=_PTC_pred2_ predicted=fit residual=residual;
		run;
		quit;

		%* Number of cases in each regression piece;
		data _PTC_regall_;
			set _PTC_reg1_ _PTC_reg2_;
			rename 	_edf_  = n;
		run;
		options dkrocond=nowarning;
		proc transpose data=_PTC_regall_ out=_PTC_regall_n_(drop=_NAME_ _LABEL_) prefix=n;
			var n;
		run;
		options dkrocond=&dkrocond_option;
		data _PTC_rsq_all_;
			merge _PTC_regall_n_;
			%* Add information on independent and target variables;
			%if %quote(&by) ~= %then %do;
				%do bb = 1 %to &nro_byvars;
				length &&byvar_name&bb $32.;
				&&byvar_name&bb = "&&byvar&bb";
				%end;
			%end;
			length _var_ _target_ $32.;
			_var_ = "&var";
			_target_ = "&target";
			%* Identify case analyzed (defining the cut values used);
			_case_ = &case;
			i = &i;
			j = .;
			_xrank1_ = &obs1;
			_cut1_ = &cut1;
			%if &maxnpieces >= 3 %then %do;
			_xrank2_ = .;
			_cut2_ = .;
			n3 = .;
			%end;
		run;

		%* Sum of RSS;
		%do k = 1 %to 2;
			data _PTC_pred&k._;
				set _PTC_pred&k._;
				residual2 = residual*residual;
			run;
			%Means(_PTC_pred&k._, var=residual2, stat=n sum, name=n RSS, out=_PTC_rss&k._, log=0);
		%end;
		data _PTC_rss_;
			set _PTC_rss1_ _PTC_rss2_;
		run;
		options dkrocond=nowarning;
		proc transpose data=_PTC_rss_ out=_PTC_regall_n_(drop=_NAME_ _LABEL_) prefix=n;
			var n;
		run;
		proc transpose data=_PTC_rss_ out=_PTC_regall_rss_(drop=_NAME_ _LABEL_) prefix=RSS;
			var RSS;
		run;
		options dkrocond=&dkrocond_option;
		data _PTC_rss_all_;
			format n1 n2 %if &maxnpieces >= 3 %then %do; n3 %end; RSS1 RSS2 %if &maxnpieces >= 3 %then %do; RSS3 %end;;
			merge _PTC_regall_n_ _PTC_regall_rss_;
			%if &maxnpieces >= 3 %then %do;
			n3 = .;
			RSS3 = .;
			%end;
		run;

		%* Sum of RSS, RMSE and RSQ;
		data _PTC_rsq_all_;
			%if %quote(&by) ~= %then %do;
			format %do bb = 1 %to &nro_byvars; &&byvar_name&bb; %end;
			%end;
			format _target_ _var_ _case_ i j _cut1_ %if &maxnpieces >= 3 %then %do; _cut2_ %end;
											_xrank1_ %if &maxnpieces >= 3 %then %do; _xrank2_ %end;
											n1 n2 %if &maxnpieces >= 3 %then %do; n3 %end;
											RSQ RMSE RSS RSS1 RSS2 %if &maxnpieces >= 3 %then %do; RSS3 %end;;
			merge 	_PTC_results_b_(where=(_var_ = "&var" and _case_ = 0) keep=_var_ _case_ RSQ RSS rename=(RSQ=RSQ0 RSS=RSS0))
					_PTC_rsq_all_ _PTC_rss_all_;
						%** Note that we add from _PTC_results_b_ the RSQ and RSS values for the SINGLE regression
						%** so that we can CORRECTLY compute the RSQ for the piecewise regressions,
						%** because for this we need to consider the Corrected Sum of Squares of Y ON THE SINGLE REGRESSION!
						%** Otherwise the R2 of some pieces may be very low just because they are computed based on the Y scale
						%** that is SEEN by that piece...;
			%* Corrected Sum of Squares of Target;
			CSSY = RSS0 / (1 - RSQ0);
			%* RSS, RMSE and R-Square;
			RSS = sum(of RSS1-RSS2);
			RSQ = 1 - RSS / CSSY;
			RMSE = sqrt( RSS / (n1 + n2) );
			drop RSQ0 RSS0 CSSY;
		run;

		%* Append;
		proc append base=_PTC_results_b_ data=_PTC_rsq_all_ force;
		run;

		%* Prepare for the next iteration;
		%let i = %eval(&i + &step);
		%let cut1 = %scan(&xsweep, &i, ' ');
	%end;
	/*-------------------------------------------------------------------------------------------*/

	/*------------------------------------- 3 Regressions ---------------------------------------*/
	%if &maxnpieces >= 3 %then %do;
		%if &log %then
			%put;

		%local xlast1 xlast2;			%* Maximum cut values to try for regression pieces #1 and #2;
		%if %eval(&last - &mincases) <= 0 %then
			%let xlast1 = ;				%* There are not enough points in the data;
		%else
			%let xlast1 = %scan(&xsweep, %eval(&last - &mincases), ' ');
		%let xlast2 = &xlast;

		%* Check if we fail to have enough number of points to make 3 regressions (i.e. 2 cuts);
		%if &xlast1 = or &xlast1 < &xfirst %then %do;
			%if &log %then %do;
				%put PIECEWISETRANSFCUTS: Not enough data to try 3 piecewise regressions.;
				%put PIECEWISETRANSFCUTS: The optimization process stops.;
			%end;
		%end;
		%else %do;
			%* Sweep over the cut values and do linear regressions on each piece;
			%let i = 1;
			%do %until (&cut1 = or &cut1 > &xlast1);	%* &cut1 can be empty when the next value to try is out of range from the values in &xsweep;
				%* Before iterating on the second cut, check that it does not go out of range of the values in &xsweep;
				%let j = %eval(&i + &mincases);
				%let cut2 = %scan(&xsweep, &j, ' ');
				%do %while (&cut2 ~= and &cut2 <= &xlast2);		%* &cut2 is empty when it goes out of range. I need to check for empty because empty < any value...;
					%let case = %eval(&case + 1);
					%let cut1 = %scan(&xsweep, &i, ' ');				%* Last cse to include in regression piece #1;
					%let cut1p = %scan(&xsweep, %eval(&i+1), ' ');		%* First case to include in regression piece #2;
					%let cut2 = %scan(&xsweep, &j, ' ');				%* Last case to include in regression piece #2;
					%let cut2p = %scan(&xsweep, %eval(&j+1), ' ');		%* First case to include in regression piece #3;
					%let obs1 = %scan(&obssweep, &i, ' ');				%* Index of first DISTINCT observation in regression piece #2;
					%let obs2 = %scan(&obssweep, &j, ' ');				%* Index of first DISTINCT observation in regression piece #3;
					%if &log %then %do;
						%put PIECEWISETRANSFCUTS: Performing linear regressions in 3 pieces...;
						%if %quote(&by) ~= %then %do;
							%do bb = 1 %to &nro_byvars;
								%put PIECEWISETRANSFCUTS: %upcase(&&byvar_name&bb) = &&byvar&bb;
							%end;
						%end;
						%put PIECEWISETRANSFCUTS: Case=&case: cut1 = %Pretty(&cut1, roundoff=0.0001) (max ~ &xlast1), cut2 = %Pretty(&cut2, roundoff=0.0001) (max ~ &xlast2);
					%end;
					proc reg data=_PTC_data_b_ outest=_PTC_reg1_ rsquare noprint;
						where %sysevalf(0.999999*&xmin) <= &var <= %sysevalf(1.000001*&cut1);	%* I multiply by 1.0000001 because o.w. value &cut1 is not always included in the range; 
						reg1: model &target = &var;
						output out=_PTC_pred1_ predicted=fit residual=residual;
					run;
					quit;
					proc reg data=_PTC_data_b_ outest=_PTC_reg2_ rsquare noprint;
						where %sysevalf(0.999999*&cut1p) <= &var <= %sysevalf(1.000001*&cut2);	%* I multiply by 1.000001 because o.w. value &cut2 is not always included in the range; 
						reg2: model &target = &var;
						output out=_PTC_pred2_ predicted=fit residual=residual;
					run;
					quit;
					proc reg data=_PTC_data_b_ outest=_PTC_reg3_ rsquare noprint;
						where %sysevalf(0.999999*&cut2p) <= &var <= %sysevalf(1.000001*&xmax);	%* I multiply by 1.000001 because o.w. value &xmax is not always included in the range; 
						reg3: model &target = &var;
						output out=_PTC_pred3_ predicted=fit residual=residual;
					run;
					quit;

					%* Compute number of cases in each regression piece;
					data _PTC_regall_;
						set _PTC_reg1_ _PTC_reg2_ _PTC_reg3_;
						rename 	_edf_  = n;
					run;
					options dkrocond=nowarning;
					proc transpose data=_PTC_regall_ out=_PTC_regall_n_(drop=_NAME_ _LABEL_) prefix=n;
						var n;
					run;
					options dkrocond=&dkrocond_option;
					data _PTC_rsq_all_;
						merge _PTC_regall_n_ /*_PTC_regall_rmse_ _PTC_regall_rsq_*/;
						%* Add information on independent and target variables;
						%if %quote(&by) ~= %then %do;
							%do bb = 1 %to &nro_byvars;
							length &&byvar_name&bb $32.;
							&&byvar_name&bb = "&&byvar&bb";
							%end;
						%end;
						length _var_ _target_ $32.;
						_var_ = "&var";
						_target_ = "&target";
						%* Identify case analyzed (defining the cut values used);
						_case_ = &case;
						i = &i;
						j = &j;
						_xrank1_ = &obs1;
						_cut1_ = &cut1;
						_xrank2_ = &obs2;
						_cut2_ = &cut2;
					run;

					%* Sum of RSS, RMSE and RSQ;
					%do k = 1 %to 3;
						data _PTC_pred&k._;
							set _PTC_pred&k._;
							residual2 = residual*residual;
						run;
						%Means(_PTC_pred&k._, var=residual2, stat=n sum, name=n RSS, out=_PTC_rss&k._, log=0);
					%end;
					data _PTC_rss_;
						set _PTC_rss1_ _PTC_rss2_ _PTC_rss3_;
					run;
					options dkrocond=nowarning;
					proc transpose data=_PTC_rss_ out=_PTC_regall_n_(drop=_NAME_ _LABEL_) prefix=n;
						var n;
					run;
					proc transpose data=_PTC_rss_ out=_PTC_regall_rss_(drop=_NAME_ _LABEL_) prefix=RSS;
						var RSS;
					run;
					options dkrocond=&dkrocond_option;
					data _PTC_rss_all_;
						format n1 n2 n3 RSS1-RSS3;
						merge _PTC_regall_n_ _PTC_regall_rss_;
					run;

					%* Putting all measures together;
					data _PTC_rsq_all_;
						%if %quote(&by) ~= %then %do;
						format %do bb = 1 %to &nro_byvars; &&byvar_name&bb; %end;
						%end;
						format _target_ _var_ _case_ i j _cut1_ _cut2_ _xrank1_ _xrank2_ n1 n2 n3 RSQ RMSE RSS RSS1-RSS3;
						merge 	_PTC_results_b_(where=(_var_ = "&var" and _case_ = 0) keep=_var_ _case_ RSQ RSS rename=(RSQ=RSQ0 RSS=RSS0))
								_PTC_rsq_all_ _PTC_rss_all_;
									%** Note that we add from _PTC_results_b_ the RSQ and RSS values for the SINGLE regression
									%** so that we can CORRECTLY compute the RSQ for the piecewise regressions,
									%** because for this we need to consider the Corrected Sum of Squares of Y ON THE SINGLE REGRESSION!
									%** Otherwise the R2 of some pieces may be very low just because they are computed based on the Y scale
									%** that is SEEN by that piece...;
						%* Corrected Sum of Squares of Target;
						CSSY = RSS0 / (1 - RSQ0);
						%* RSS, RMSE and R-Square;
						RSS = sum(of RSS1-RSS3);
						RSQ = 1 - RSS / CSSY;
						RMSE = sqrt( RSS / (n1 + n2 + n3) );
						drop RSQ0 RSS0 CSSY;
					run;

					%* Append;
					proc append base=_PTC_results_b_ data=_PTC_rsq_all_ force;
					run;

					%* Prepare for the next INNER iteration;
					%let j = %eval(&j + &step);
					%let cut2 = %scan(&xsweep, &j, ' ');
				%end;

				%* Prepare for the next OUTER iteration;
				%let i = %eval(&i + &step);
				%let cut1 = %scan(&xsweep, &i, ' ');
			%end;
		%end;	%* Check if there is enough number of points to perform 3 regressions;
	%end; %* &maxnpieces >= 3;
/*-------------------------------------------------------------------------------------------*/


/*---------------------------------- Choose best cuts ---------------------------------------*/
	%if &log %then %do;
		%put;
		%put PIECEWISETRANSFCUTS: Choosing the best cuts, based on maximizing the Total R-Square...;
	%end;
%end;	%* Only a single regression is performed;

%* Keep the observation with the maximum value of RSQ_mean on piecewise regressions (i.e. the single regression is NOT considered but is added below as reference);
data _PTC_cuts_b_;
	set _PTC_results_b_(where=(_case_>0)) end=lastobs;
	retain RSQ_max .;
	if RSQ > RSQ_max then do;
		RSQ_max = RSQ;
		output;
	end;
	drop RSQ_max;
run;
%* Keep the last observation of _PTC_cuts_b_ because that is the one that contains the maximum
%* value of RSQ_mean;
data _PTC_cuts_b_;
	set _PTC_cuts_b_ end=lastobs;
	if lastobs;
run;
%* Add the results for the single regression to keep as reference;
data _PTC_cuts_b_;
	set _PTC_results_b_(in=in0 where=(_case_=0))
		_PTC_cuts_b_;
	if in0 then _cut_ = 0;
run;

/* OLD (3/3/05, can delete): The above method is safer than the one below, because no comparisons
are made between the current value and the maximum value, which can give rounding errors.
In fact, the error bound for the absolute relative difference (1e-4 for instance) may not work
in all situations (and in fact it did not), in the sense that it may be too low of a bound
or too high of a bound.
%GetStat(_PTC_results_b_, var=RMSE_mean, stat=min, log=0);
%GetStat(_PTC_results_b_, var=RSQ_mean, stat=max, log=0);
%GetStat(_PTC_results_b_, var=RSS_mean, stat=min, log=0);
data _PTC_cuts_b_;
	set _PTC_results_b_;
	if &RSQ_mean_max ~= 0 then do;
		if abs((RSQ_mean - &RSQ_mean_max)/&RSQ_mean_max) < 1e-4 then output;
	end;
	else do;
		if abs(RSQ_mean - &RSQ_mean_max) < 1e-6 then output;
	end;
run;
*/

data _PTC_cuts_b_(keep=%if %quote(&by) ~= %then %do; %do bb = 1 %to &nro_byvars; &&byvar_name&bb %end; %end; _cut_ _target_ _var_ _value_ RSQ RMSE RSS);
	%if %quote(&by) ~= %then %do;
	format %do bb = 1 %to &nro_byvars; &&byvar_name&bb; %end;
	%end;
	format _cut_ _target_ _var_ _value_ RSQ RMSE RSS;
	set _PTC_cuts_b_;
	retain RSQ RMSE RSS;
	if _cut_ ~= 0 then do;	%* cut = 0 for the results for the SINGLE regression;
		_cut_ = 1;
		_value_ = _cut1_;
	end;
	output;
	%* Check whether there is only one cut value and if there is more than one, check whether
	%* the cut values are consecutive x values. If this is the case, there should be only one
	%* cut in the piecewise transformation, and thus the second cut value is not output to the
	%* dataset containing the cut values. Otherwise, output the second cut to the output dataset;
	if _xrank2_ ~= . and _xrank2_ > _xrank1_ + 1 then do;
		_cut_ = 2;
		_value_ = _cut2_;
		output;
	end;
run;

%* Append the results for the current by variable combination to the temporary output datasets;
proc append base=_PTC_cuts_ data=_PTC_cuts_b_ FORCE;
run;
proc append base=_PTC_results_ data=_PTC_results_b_ FORCE;
run;
/*-------------------------------------------------------------------------------------------*/
%end;	%* do b (BY-group processing);


/*----------------------------------- Output datasets ---------------------------------------*/
%if %quote(&out) ~= %then %do;
	%let out_name = %scan(&out, 1, '(');
	data &out;
		set _PTC_cuts_;
		label 	RSQ		= "Total R-Square"
				RMSE 	= "Total Root Mean Squared Error"
				RSS  	= "Total Residual Sum of Squares";
	run;
	%if &log %then %do;
		%put;
		%put PIECEWISETRANSFCUTS: Output dataset %upcase(&out_name) created with the optimum cuts found.;
	%end;
%end;

%if %quote(&outall) ~= %then %do;
	%let outall_name = %scan(&outall, 1, '(');
	options dkrocond=nowarning;
	data &outall;
		set _PTC_results_;
		label 	RSQ 	= "Total R-Square"
				RMSE 	= "Total Root Mean Squared Error"
				RSS  	= "Total Residual Sum of Squares"
				RSS1	= "Sum of Squares on piece 1"
				RSS2	= "Sum of Squares on piece 2"
				n1		= "Number of cases in piece 1"
				n2 		= "Number of cases in piece 2"
				%if &maxnpieces >= 3 %then %do;
				n3 		= "Number of cases in piece 3"
				RSS3	= "Sum of Squares on piece 3"
				%end;
				;
		drop i j _LABEL_;
	run;
	options dkrocond=&dkrocond_option;
	%if &log %then %do;
		%put;
		%put PIECEWISETRANSFCUTS: Output dataset %upcase(&outall_name) created with the results of the;
		%put PIECEWISETRANSFCUTS: different regressions.;
	%end;
%end;
/*-------------------------------------------------------------------------------------------*/

proc datasets nolist;
	delete 	_PTC_cuts_b_
			_PTC_data_
			_PTC_data_b_
			_PTC_data_b_rank_
			_PTC_pred1_
			_PTC_pred2_
			_PTC_pred3_
			_PTC_reg1_
			_PTC_reg2_
			_PTC_reg3_
			_PTC_regall_
			_PTC_regall_n_
			_PTC_regall_rss_
			_PTC_results_b_
			_PTC_rsq_all_
			_PTC_rss_
			_PTC_rss1_
			_PTC_rss2_
			_PTC_rss3_
			_PTC_rss_all_;
	%if %quote(%upcase(&out)) ~= _PTC_CUTS_ %then %do;
	delete 	_PTC_cuts_;
	%end;
	%if %quote(%upcase(&outall)) ~= _PTC_RESULTS_ %then %do;
	delete	_PTC_results_;
	%end;
quit;

%if &log %then %do;
	%put;
	%put PIECEWISETRANSFCUTS: Macro ends;
	%put;
%end;

%ExecTimeStop;
%ResetSASOptions;
%end; %* %if ~%CheckInputParameters;
%MEND PiecewiseTransfCuts;
