/* MACRO %PiecewiseTransfCuts
Version: 1.00
Author: Daniel Mastropietro
Created: 3-Jan-05
Modified: 13-Jan-05

DESCRIPTION:
Macro that finds the best cut points for a linear piecewise transformation of a continuous
variable that maximizes the average R-Square (over the different pieces of the transformation)
with respect to a continuous target variable.

USAGE:
%PiecewiseTransfCuts(
	data, 
	target=y,
	var=x,
	by=,
	id=,
	out=_PTC_cuts_,
	outall=_PTC_results_,
	log=1);

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

- id:			List of ID variables identifying the analysis performed that is stored in the
				output datasets. It is assumed that they can take only one combination value for
				all the observations used in the analysis.

- out:			Output dataset containing the best cuts found for each by variable combination.
				The output dataset has the following columns (in this order):
				- By variables passed in the BY= parameter.
				- CUT:		Best cut value ID: it can take the values 1 or 2. Number 1 indicates
							the smallest cut value found and number 2 indicates the largest
							cut value found. Number 2 is not present if the best cut values
							found may correspond to a 2-piece piecewise linear transformation.
				- TARGET:	Name of the target variable used in the analysis.
				- X:		Name of the regressor variable used in the analysis.
				- VALUE:	Value of the best cut value found that corresponds to the cut value
							ID given in column CUT. The cut value is one of the values taken
							by the regressor variable.
				- RSQ_mean:	Average of the R-Square's of the linear regressions in each piece.
				- RMSE_mean:Average of the Root Mean Squared Error's of the linear regressions in
							each piece.
				- RSS_mean: Average of the Residual Sum of Square's of the linear regressions in
							each piece.
				- All the other variables present in the input dataset except the variable
				passed in VAR.
				default: _PTC_cuts_

- outall:		Output dataset containing the results for all the piecewise linear regressions
				tried to find the best cuts. The output dataset has the following columns:
				- By variables passed in the BY= parameter.
				- TARGET:		Name of the target variable used in the analysis.
				- X:			Name of the regressor variable used in the analysis.
				- CASE:			ID identifying each combination of cut values analyzed to find the
								best cut values.
				- XIND1:		Index of the values taken by the regressor variable for current case,
								corresponding to cut value CUT1.
				- CUT1:			Smallest cut value used in current case.
				- XIND2:		Index of the values taken by the regressor variable for current case,
								corresponding to cut value CUT2.
				- CUT2:			Largest cut value used in current case.
				- RSQ_mean:		Average of the R-Square's of the linear regressions in each piece
								for current case.
				- RSQ1-RSQ3:	R-Square of pieces 1 thru 3 for current case.
				- RMSE_mean: 	Average of the Root Mean Squared Error's of the linear regressions in
								each piece, for current case.
				- RMSE1-RMSE3:	Root Mean Squared Error of pieces 1 thru 3 for current case.
				- RSS_mean:  	Average of the Residual Sum of Square's of the linear regressions in
								each piece, for current case.
				- RSS1-RSS3:	Residual Sum of Squares of pieces 1 thru 3 for current case.
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
- %CreateGroupVar
- %GetNroElements
- %GetStat
- %MakeList
- %MakeListFromVar
- %Means
- %Pretty
- %ResetSASOptions
- %SelectNames
- %SetSASOptions

SEE ALSO:
- %PiecewiseTransf
- %VariableImpact

EXAMPLES:
1.- %PiecewiseTransfCuts(test, target=earning, var=x, id=varname, out=cuts, outall=allcuts);
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
%MACRO PiecewiseTransfCuts(data, target=y, var=x, by=, id=, out=_PTC_cuts_, outall=_PTC_results_, log=1)
		/ store des="Finds the best cut points for a piecewise linear transformation to predict a continuous target";
/*
NOTE: (5/1/05) It seems that the best criterion to choose the optimal cuts is the average of
R-Squares for all pieces (RSQ_mean).
*/
%SetSASOptions;

%if &log %then %do;
	%put;
	%put PIECEWISETRANSFCUTS: Macro starts;
	%put;
%end;

%local obsvalues obssweep obs1 obs2 xvalues xsweep xn xmin xmax xfirst xlast first last;
%local cut1 cut1p cut2 cut2p nro_cuts1;
%local b bb i j case;			%* Counters;
%local out_name outall_name;
%local byvars;
%local dkrocond_option;			%* Used to store current value of DKROCOND option;

%* Store current value of DKROCOND option that controls warnings for DROP, KEEP and RENAME statements;
%let dkrocond_option = %sysfunc(getoption(dkrocond));;

/*------------------------------- Parsing input parameters ----------------------------------*/
%* Read input dataset;
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
	_ptc_obs_ = _N_;
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
	set _PTC_reg1_(keep=RMSE RSQ rename=(RMSE=RMSE_mean RSQ=RSQ_mean));
		%** Variables RMSE and RSQ are renamed to RMSE_mean and RSQ_mean because these are the
		%** variables used in the following cases when more than one regression is performed;
	%* Add information on independent and target variables;
	%if %quote(&by) ~= %then %do;
		%do bb = 1 %to &nro_byvars;
		length &&byvar_name&bb $32.;
		&&byvar_name&bb = "&&byvar&bb";
		%end;
	%end;
	length x target $32.;
	x = "&var";
	target = "&target";
	%* Create variables RMSE1-RMSE3 and RSQ1-RSQ3 because they are present in the following cases
	%* when more than one regression is performed;
	RMSE1 = RMSE_mean;
	RSQ1 = RSQ_mean;
	%do k = 2 %to 3;
		RMSE&k = .;
		RSQ&k = .;
	%end;
	%* Identify case analyzed (defining the cut values used, which in this case is NO cuts);
	case = &case;
	i = 0;
	j = 0;
	xind1 = .;
	cut1 = .;
	xind2 = .;
	cut2 = .;
run;

%* Compute RSS;
data _PTC_pred1_;
	set _PTC_pred1_;
	residual2 = residual*residual;
run;
%Means(_PTC_pred1_, var=residual2, id=&id, stat=sum, name=RSS, out=_PTC_rss_, log=0);
data _PTC_rss_all_;
	format RSS_mean RSS1-RSS3;
	set _PTC_rss_(rename=(RSS=RSS_mean));
	%* Create RSS1-RSS3 because they are used in the following CASEs analyzed;
	RSS1 = RSS_mean;
	%do k = 2 %to 3;
		RSS&k = .;	%* RSS2-RSS3 are missing because there is only one regression here;
	%end;
run;

%* Create output dataset _PTC_results_b_ by putting all measures together;
data _PTC_results_b_;
	%if %quote(&by) ~= %then %do;
	format %do bb = 1 %to &nro_byvars; &&byvar_name&bb; %end;
	%end;
	format &id target x case i j xind1 cut1 xind2 cut2 RSQ_mean RSQ1-RSQ3 RMSE_mean RMSE1-RMSE3;
	merge _PTC_rsq_all_ _PTC_rss_all_;
run;
/*-------------------------------------------------------------------------------------------*/

/*------------------------------------- Sweep values ----------------------------------------*/
%* Read all the values taken by the X variable into a macro variable;
%let xvalues = %MakeListFromVar(_PTC_data_b_, var=&var, log=0);
%* Read the observation values corresponding to the X values so that these can be identified
%* easily when merging with the input dataset in order to gather some additional information
%* corresponding to the optimum cuts found;
%let obsvalues = %MakeListFromVar(_PTC_data_b_, var=_ptc_obs_, log=0);
%let xn = %GetNroElements(&xvalues);
%* Min and Max values of x;
%let xmin = %scan(&xvalues, 1, ' ');
%let xmax = %scan(&xvalues, &xn, ' ');
%* First and last value of x to use in the sweep of the cut values;
%* The values are defined so that there are enough points for the linear regression
%* in each piece defined by the cuts;
%let first = 3;				%* Third smallest value;
%let last = %eval(&xn-2);	%* Third largest value;

%* Values of X and of the X observation values on which the cuts are swept;
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
%end;

%* Nro. of values on which the first cut value is swept;
%let nro_cuts1 = %GetNroElements(&xsweep);
/*-------------------------------------------------------------------------------------------*/

/*------------------------------------- 2 Regressions ---------------------------------------*/
%if &log %then %do;
	%put;
	%if &nro_cuts1 <= 1 %then %do;
		%put PIECEWISETRANSFCUTS: Not enough data to perform piecewise regressions.;
		%put PIECEWISETRANSFCUTS: Only a single regression is done.;
	%end;
%end;	
%do i = 1 %to &nro_cuts1-1;
	%** Si se incluye el mismo cut en las dos regresiones adyacentes:
	%** - usar &nro_cuts
	%** - usar &cut1 abajo en el <= del WHERE del REG2;
	%** Si NO se incluye el mismo cut en las dos regresiones adyacentes; 
	%** - usar &nro_cuts-1
	%** - usar &cut1p abajo en el <= del WHERE del REG2;

	%let case = %eval(&case + 1);
	%let cut1 = %scan(&xsweep, &i, ' ');
	%let cut1p = %scan(&xsweep, %eval(&i+1), ' ');
	%let obs1 = %scan(&obssweep, &i, ' ');
	%if &log %then %do;
		%put PIECEWISETRANSFCUTS: Performing linear regressions in 2 pieces...;
		%if %quote(&by) ~= %then %do;
			%do bb = 1 %to &nro_byvars;
				%put PIECEWISETRANSFCUTS: %upcase(&&byvar_name&bb) = &&byvar&bb;
			%end;
		%end;
		%put PIECEWISETRANSFCUTS: Case=&case: cut = %Pretty(&cut1, roundoff=0.0001);
	%end;
	proc reg data=_PTC_data_b_ outest=_PTC_reg1_ rsquare noprint;
		where %sysevalf(0.999*&xmin) <= &var <= %sysevalf(1.001*&cut1);	%* I multiply by 1.001 because o.w. value &cut1 is not always included in the range; 
		reg1: model &target = &var;
		output out=_PTC_pred1_ predicted=fit residual=residual;
	run;
	quit;
	proc reg data=_PTC_data_b_ outest=_PTC_reg2_ rsquare noprint;
		where %sysevalf(0.999*&cut1p) <= &var <= %sysevalf(1.001*&xmax);	%* I multiply by 1.001 because o.w. value &xmax is not always included in the range;
		reg2: model &target = &var;
		output out=_PTC_pred2_ predicted=fit residual=residual;
	run;
	quit;

	data _PTC_regall_;
		set _PTC_reg1_ _PTC_reg2_;
		rename 	_rmse_ = RMSE
				_rsq_  = RSQ;
	run;
	options dkrocond=nowarning;
	proc transpose data=_PTC_regall_ out=_PTC_regall_rmse_(drop=_NAME_ _LABEL_) prefix=RMSE;
		var RMSE;
	run;
	proc transpose data=_PTC_regall_ out=_PTC_regall_rsq_(drop=_NAME_ _LABEL_) prefix=RSQ;
		var RSQ;
	run;
	options dkrocond=&dkrocond_option;
	data _PTC_rsq_all_;
		merge _PTC_regall_rmse_ _PTC_regall_rsq_;
		%* Add information on independent and target variables;
		%if %quote(&by) ~= %then %do;
			%do bb = 1 %to &nro_byvars;
			length &&byvar_name&bb $32.;
			&&byvar_name&bb = "&&byvar&bb";
			%end;
		%end;
		length x target $32.;
		x = "&var";
		target = "&target";
		%* Create variables RMSE3 and RSQ3 as missing (because there is no 3rd piece);
		RMSE3 = .;
		RSQ3 = .;
		%* Compute sum of RMSE and sum of RSQ;
		RMSE_mean = sum(of rmse1-rmse2) / 2;
		RSQ_mean = sum(of rsq1-rsq2) / 2;
		%* Identify case analyzed (defining the cut values used);
		case = &case;
		i = &i;
		j = .;
		xind1 = &obs1;
		cut1 = &cut1;
		xind2 = .;
		cut2 = .;
	run;

	%* Sum of RSS;
	%do k = 1 %to 2;
		data _PTC_pred&k._;
			set _PTC_pred&k._;
			residual2 = residual*residual;
		run;
		%Means(_PTC_pred&k._, var=residual2, id=&id, stat=sum, name=RSS, out=_PTC_rss&k._, log=0);
	%end;
	data _PTC_rss_;
		set _PTC_rss1_ _PTC_rss2_;
	run;
	options dkrocond=nowarning;
	proc transpose data=_PTC_rss_ out=_PTC_rss_all_(drop=_NAME_ _LABEL_) prefix=RSS;
		%if %quote(&id) ~= %then %do;
		by &id;	%* Note the use of BY instead of ID: ID assumes that each value of the ID variable
				%* occurs only once. Here, we are assuming that the ID variable has only one value
				%* that is repeated for all observations in the input dataset;
		%end;
		var RSS;
	run;
	options dkrocond=&dkrocond_option;
	data _PTC_rss_all_;
		format RSS_mean RSS1-RSS3;
		set _PTC_rss_all_;
		RSS3 = .;
		RSS_mean = sum(of RSS1-RSS2) / 2;
	run;

	%* Putting all measures together;
	data _PTC_rsq_all_;
		%if %quote(&by) ~= %then %do;
		format %do bb = 1 %to &nro_byvars; &&byvar_name&bb; %end;
		%end;
		format &id target x case i j xind1 cut1 xind2 cut2 RSQ_mean RSQ1-RSQ3 RMSE_mean RMSE1-RMSE3;
		merge _PTC_rsq_all_ _PTC_rss_all_;
	run;

	%* Append;
	proc append base=_PTC_results_b_ data=_PTC_rsq_all_ force;
	run;
%end;
/*-------------------------------------------------------------------------------------------*/

/*------------------------------------- 3 Regressions ---------------------------------------*/
%if &log %then
	%put;
%* Sweep over the cut values and do linear regressions on each piece;
%do i = 1 %to %eval(&nro_cuts1-3);
	%** Si se incluye el mismo cut en las dos regresiones adyacentes; 
	%** - usar &nro_cuts-2
	%** - usar &cut1 abajo en el <= del WHERE del REG2
	%** - usar &cut2 abajo en el <= del WHERE del REG3;
	%** Si NO se incluye el mismo cut en las dos regresiones adyacentes; 
	%** - usar &nro_cuts-3
	%** - usar &cut1p abajo en el <= del WHERE del REG2
	%** - usar &cut2p abajo en el <= del WHERE del REG3;
 
	%do j = %eval(&i+3) %to %eval(&nro_cuts1-1);
		%** Si se incluye el mismo cut en las dos regresiones adyacentes; 
		%** - usar &i+2
		%** - nro_cuts1
		%** Si NO se incluye el mismo cut en las dos regresiones adyacentes; 
		%** - usar &i+3
		%** - nro_cuts1-1;

		%let case = %eval(&case + 1);
		%let cut1 = %scan(&xsweep, &i, ' ');
		%let cut1p = %scan(&xsweep, %eval(&i+1), ' ');
		%let cut2 = %scan(&xsweep, &j, ' ');
		%let cut2p = %scan(&xsweep, %eval(&j+1), ' ');
		%let obs1 = %scan(&obssweep, &i, ' ');
		%let obs2 = %scan(&obssweep, &j, ' ');
		%if &log %then %do;
			%put PIECEWISETRANSFCUTS: Performing linear regressions in 3 pieces...;
			%if %quote(&by) ~= %then %do;
				%do bb = 1 %to &nro_byvars;
					%put PIECEWISETRANSFCUTS: %upcase(&&byvar_name&bb) = &&byvar&bb;
				%end;
			%end;
			%put PIECEWISETRANSFCUTS: Case=&case: cut1 = %Pretty(&cut1, roundoff=0.0001), cut2 = %Pretty(&cut2, roundoff=0.0001);
		%end;
		proc reg data=_PTC_data_b_ outest=_PTC_reg1_ rsquare noprint;
			where %sysevalf(0.999*&xmin) <= &var <= %sysevalf(1.001*&cut1);	%* I multiply by 1.001 because o.w. value &cut1 is not always included in the range; 
			reg1: model &target = &var;
			output out=_PTC_pred1_ predicted=fit residual=residual;
		run;
		quit;
		proc reg data=_PTC_data_b_ outest=_PTC_reg2_ rsquare noprint;
			where %sysevalf(0.999*&cut1p) <= &var <= %sysevalf(1.001*&cut2);	%* I multiply by 1.001 because o.w. value &cut2 is not always included in the range; 
			reg2: model &target = &var;
			output out=_PTC_pred2_ predicted=fit residual=residual;
		run;
		quit;
		proc reg data=_PTC_data_b_ outest=_PTC_reg3_ rsquare noprint;
			where %sysevalf(0.999*&cut2p) <= &var <= %sysevalf(1.001*&xmax);	%* I multiply by 1.001 because o.w. value &xmax is not always included in the range; 
			reg3: model &target = &var;
			output out=_PTC_pred3_ predicted=fit residual=residual;
		run;
		quit;

		%* Compute sum of RMSE and sum of RSQ;
		data _PTC_regall_;
			set _PTC_reg1_ _PTC_reg2_ _PTC_reg3_;
			rename 	_rmse_ = RMSE
					_rsq_  = RSQ;
		run;
		options dkrocond=nowarning;
		proc transpose data=_PTC_regall_ out=_PTC_regall_rmse_(drop=_NAME_ _LABEL_) prefix=RMSE;
			var RMSE;
		run;
		proc transpose data=_PTC_regall_ out=_PTC_regall_rsq_(drop=_NAME_ _LABEL_) prefix=RSQ;
			var RSQ;
		run;
		options dkrocond=&dkrocond_option;
		data _PTC_rsq_all_;
			merge _PTC_regall_rmse_ _PTC_regall_rsq_;
			%* Add information on independent and target variables;
			%if %quote(&by) ~= %then %do;
				%do bb = 1 %to &nro_byvars;
				length &&byvar_name&bb $32.;
				&&byvar_name&bb = "&&byvar&bb";
				%end;
			%end;
			length x target $32.;
			x = "&var";
			target = "&target";
			%* Compute sum of RMSE and sum of RSQ;
			RMSE_mean = sum(of rmse1-rmse3) / 3;
			RSQ_mean = sum(of rsq1-rsq3) / 3;
			%* Identify case analyzed (defining the cut values used);
			case = &case;
			i = &i;
			j = &j;
			xind1 = &obs1;
			cut1 = &cut1;
			xind2 = &obs2;
			cut2 = &cut2;
		run;

		%* Sum of RSS;
		%do k = 1 %to 3;
			data _PTC_pred&k._;
				set _PTC_pred&k._;
				residual2 = residual*residual;
			run;
			%Means(_PTC_pred&k._, var=residual2, id=&id, stat=sum, name=RSS, out=_PTC_rss&k._, log=0);
		%end;
		data _PTC_rss_;
			set _PTC_rss1_ _PTC_rss2_ _PTC_rss3_;
		run;
		options dkrocond=nowarning;
		proc transpose data=_PTC_rss_ out=_PTC_rss_all_(drop=_NAME_ _LABEL_) prefix=RSS;
			%if %quote(&id) ~= %then %do;
			by &id;	%* Note the use of BY instead of ID: ID assumes that each value of the ID
					%* variable occurs only one. Here, we are assuming that the ID variable has
					%* only one value that is repeated for all observations in the input dataset;
			%end;
			var RSS;
		run;
		options dkrocond=&dkrocond_option;
		data _PTC_rss_all_;
			format &id RSS_mean RSS1-RSS3;
			set _PTC_rss_all_;
			RSS_mean = sum(of RSS1-RSS3) / 3;
		run;

		%* Putting all measures together;
		data _PTC_rsq_all_;
			%if %quote(&by) ~= %then %do;
			format %do bb = 1 %to &nro_byvars; &&byvar_name&bb; %end;
			%end;
			format &id target x case i j xind1 cut1 xind2 cut2 RSQ_mean RSQ1-RSQ3 RMSE_mean RMSE1-RMSE3;
			merge _PTC_rsq_all_ _PTC_rss_all_;
		run;

		%* Append;
		proc append base=_PTC_results_b_ data=_PTC_rsq_all_ force;
		run;
	%end;
%end;
/*-------------------------------------------------------------------------------------------*/

/*---------------------------------- Choose best cuts ---------------------------------------*/
%if &log %then %do;
	%put;
	%put PIECEWISETRANSFCUTS: Choosing the best cuts, based on maximizing the average R-Square...;
%end;

%* Keep the observation with the maximum value of RSQ_mean;
data _PTC_cuts_b_;
	set _PTC_results_b_ end=lastobs;
	retain RSQ_mean_max .;
	if RSQ_mean > RSQ_mean_max then do;
		RSQ_mean_max = RSQ_mean;
		output;
	end;
	drop RSQ_mean_max;
run;
%* Keep the last observation of _PTC_cuts_b_ because that is the one that contains the maximum
%* value of RSQ_mean;
data _PTC_cuts_b_;
	set _PTC_cuts_b_ end=lastobs;
	if lastobs;
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

data _PTC_cuts_b_(keep=%if %quote(&by) ~= %then %do; %do bb = 1 %to &nro_byvars; &&byvar_name&bb %end; %end; &id cut target x _ptc_obs_ value RSQ_mean RMSE_mean RSS_mean);
	%if %quote(&by) ~= %then %do;
	format %do bb = 1 %to &nro_byvars; &&byvar_name&bb; %end;
	%end;
	format &id cut target x _ptc_obs_ value RSQ_mean RMSE_mean RSS_mean;
	set _PTC_cuts_b_;
	retain RSQ_mean RMSE_mean RSS_mean;
	_ptc_obs_ = xind1;
	cut = 1;
	value = cut1;
	output;
	%* Check whether there is only one cut value and if there is more than one, check whether
	%* the cut values are consecutive x values. If this is the case, there should be only one
	%* cut in the piecewise transformation, and thus the second cut value is not output to the
	%* dataset containing the cut values;
	if j ~= . and j > i + 1 then do;
		_ptc_obs_ = xind2;
		cut = 2;
		value = cut2;
		output;
	end;
run;

%* Add the information coming from the input dataset to the dataset containing the best cuts;
data _PTC_cuts_b_;
	merge _PTC_cuts_b_(in=in1) _PTC_data_b_(in=in2 drop=&var);
	by _ptc_obs_;
	if in1 and in2;
	drop _ptc_obs_ _GROUPID_;
run;

%* Append the results for the current by variable combination to the temporary output datasets;
proc append base=_PTC_cuts_ data=_PTC_cuts_b_ FORCE;
run;
proc append base=_PTC_results_ data=_PTC_results_b_ FORCE;
run;
/*-------------------------------------------------------------------------------------------*/
%end;	%* do b;

/*----------------------------------- Output datasets ---------------------------------------*/
%if %quote(&out) ~= %then %do;
	%let out_name = %scan(&out, 1, '(');
	data &out;
		set _PTC_cuts_;
		label 	RMSE_mean = "Average Root Mean Squared Error"
				RSQ_mean  = "Average R-Square"
				RSS_mean  = "Average Residual Sum of Squares";
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
		label 	RMSE_mean = "Average Root Mean Squared Error"
				RSQ_mean  = "Average R-Square"
				RSS_mean  = "Average Residual Sum of Squares";
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
			_PTC_pred1_
			_PTC_pred2_
			_PTC_pred3_
			_PTC_reg1_
			_PTC_reg2_
			_PTC_reg3_
			_PTC_regall_
			_PTC_regall_rmse_
			_PTC_regall_rsq_
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

%ResetSASOptions;
%MEND PiecewiseTransfCuts;
