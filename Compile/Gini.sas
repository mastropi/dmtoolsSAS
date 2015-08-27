/* MACRO %Gini
Version: 1.00
Author: Daniel Mastropietro
Created: 19-Apr-05
Modified: 04-Sep-05

DESCRIPTION:
Computes the Gini Index and the Signed Gini Index of variables w.r.t. to a dichotomous target
variable.
The Gini index of a variable is defined as twice the area between the
Cumulative Distribution Function of the variable for one value of the target variable and
the Cumulative Distribution Function of the variable for the other value of the target variable.
Thus:

	Gini = (Area Between Curves)*2;

The multiplication by 2 makes the Gini Index values range between 0 and 1.

The Signed Gini Index is numerically equal to the Gini Index.
A positive/negative sign indicates that the probability of the event of interest is larger/smaller
for larger values of the analysis variable.

USAGE:
%Gini(
	data,		*** Input dataset.
	target=,	*** Target dichotomous variable.
	var=,		*** Analysis variables;
	by=,		*** By variables.
	condition=,	*** Condition that must satisfy each variable to be included in the analyis.
	event=1,	*** Target event of interest.
	out=,		*** Output dataset containing the two cumulative distribution functions for each variable.
	outgini=,	*** Output dataset containing the Gini Index of each variable.
	plot=0,		*** Show the plots of the two cumulative distribution functions for each variable?
	log=1);		*** Show messages in the log?

REQUIRED PARAMETERS:
- data:			Input dataset containing the target variable and the analysis variables.
				Data options can be specified as in any data= SAS option.

- target:		Target dichotomous variable w.r.t which the Gini Index is computed.

- var:			Analysis Variables.

OPTIONAL PARAMETERS:
- by:			By variables.

- condition:	Condition that each analysis variable must satisfy in order for the value
				to be included in the computation of the Gini Index.

- event:		Event of interest. It must be one of the values taken by the target variable.
				It is used as the reference level to compute the signed Gini Index (GiniSgn),
				so that a positive value of GiniSgn indicates that the probability of the
				event of interest is LARGER when the analysis variable takes LARGER values.
				default: 1

- out:			Output dataset containing the CDFs of each analysis variable for each value of
				the target variable. This dataset can be used to reproduce the plots generated
				by the macro.

- outgini:		Output dataset containing the Gini Indexes for each variable.

- plot:			Whether to show the plots of the CDFs of each analysis variable for each value
				of the target variable, used to compute the Gini Index.
				Possible values: 0 => No, 1 => Yes
				default: 0

- log:			Show messages in the log?
				Possible values: 0 => No, 1 => Yes
				default: 1

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Callmacro
- %DefineSymbols
- %GetDataOptions
- %GetNobs
- %GetNroElements
- %MakeList
- %Means
- %Merge
- %ResetSASOptions
- %SetSASOptions

SEE ALSO:
- %EvaluationChart
- %KS

EXAMPLES:
1.- %Gini(test, target=DQ90, var=score saldo, by=SAMPLE, condition=~=0, 
		 out=gini_cdf, outgini=gini, plot=1);
Computes the Gini Indexes of variables SCORE and SALDO for each value of the dichotomous
target value DQ90, by variable SAMPLE.
Only values different from 0 are included in the computation.
The output dataset GINI_CDF contains the CDFs of the variables SCORE and SALDO for
each value of the target variable DQ90.
The output dataset GINI contains the Gini Indexes of the variables SCORE and SALDO.
A plot of the CDFs for each analysis variable is shown in the graph window.

APPLICATIONS:
This macro can be used in the following situations:
- To assess the impact of a continuous variable in a dichotomous target variable for 
exploratory data analysis, when choosing possible variables to be included in a model.
- To assess the performance of a scoring model to predict a dichotomous target variable,
by measuring the degree of separation provided by the model between the two classes of
the target variable.
*/
&rsubmit;
%MACRO Gini(data, target=, var=, by=, condition=, event=1, out=, outgini=, plot=0, log=1)
		/ store des="Computes the Gini Index";
%local i nro_vars vari;
%local data_name missing nobs nobsTotal;
%local dsid rc varnum vartype;
%local out_name outgini_name;
%local value1 value2 n1 n2 n;
%local error;
%local gini;

%SetSASOptions;

%if &log %then %do;
	%put;
	%put GINI: Macro starts;
	%put;
%end;

%let nro_vars = %GetNroElements(&var);

/*--------------------------------- Parsing input parameters --------------------------------*/
%let error = 0;
%*** DATA;
%let data_name = %scan(&data, 1, '(');
%let vartype = %GetVarType(&data_name, &target);
%if %upcase(&vartype) = C %then	
	%let missing = " ";
%else
	%let missing = .;
%if &log %then
	%put GINI: Reading input dataset...;
%if %GetDataOptions(&data) = %then %do;
	data _Gini_data_;
		set &data(keep=&by &target &var) end=lastobs;
		if lastobs then
			call symput ('nobsTotal', _N_);
	run;
%end;
%else %do;
	data _Gini_data_(keep=&by &target &var);
		set &data end=lastobs;
		if lastobs then
			call symput ('nobsTotal', _N_);
	run;
%end;
%callmacro(getnobs, _Gini_data_ return=1, nobsTotal);

%*** TARGET=;
%* Check whether the target variable is dichotomous (note that missing values
%* have already been removed from the input dataset);
%if &log %then
	%put GINI: Analyzing target variable (%upcase(&target))...;
proc freq data=_Gini_data_ noprint;
	where &target ~= &missing;
	tables &target / out=_Gini_freq_;
run;
%callmacro(getnobs, _Gini_freq_ return=1, nobs);
%if &nobs ~= 2 %then %do;
	%put GINI: ERROR - The number of values taken by the target variable is &nobs and must be 2.;
	%let error = 1;
%end;
%else %do;
	%if &log %then
		%put GINI: OK;
	%let dsid = %sysfunc(open(_Gini_freq_));
	%let varnum = %sysfunc(varnum(&dsid, &target));
	%let vartype = %sysfunc(vartype(&dsid, &varnum));
	%let rc = %sysfunc(fetch(&dsid, 1));	%* 1 is column 1;
	%* Lowest level of the target variable, where LOWEST is defined by the alfabetical order;
	%let value1 = %sysfunc(getvar&vartype(&dsid, &varnum));
		%** Note that no spaces are left by function VARTYPE, so that the statement
		%** getvar&vartype in the %let value1 statement works fine;
	%let rc = %sysfunc(fetch(&dsid, 2));	%* 2 is column 2;
	%* Highest level of the target variable, where HIGHEST is defined by the alfabetical order;
	%let value2 = %sysfunc(getvar&vartype(&dsid, &varnum));
	%let rc = %sysfunc(close(&dsid));
	%* Add quotes to the values of VALUE1 and VALUE2 when the target variable is character
	%* to avoid the error of incompatible variables;
	%if %upcase(&vartype) = C %then %do;
		%let value1 = "&value1";
		%let value2 = "&value2";
	%end;
%end;

%*** EVENT=;
%* If EVENT is emptyl, set its value to the lowest value of the target variable, which is used
%* as reference to compute the Signed Gini (GiniSgn);
%if %quote(&event) = %then %do;
	%let event = &value1;
%end;
%else %do;
	%* Check if the value of EVENT is one of the possible values of the target variable; 
	%if %sysevalf(%quote(%upcase(&event)) ~= %quote(%upcase(&value1))) and
		%sysevalf(%quote(%upcase(&event)) ~= %quote(%upcase(&value2))) %then %do;
		%put;
		%put GINI: WARNING - The parameter EVENT=%upcase(&event) is not among the possible values;
		%put GINI: of the target variable. The lowest level (%upcase(&value1)) will be used as reference;
		%put GINI: for the computation of the signed Gini.;
		%let event = &value1;
	%end;
%end;
/*-------------------------------------------------------------------------------------------*/
%if ~&error %then %do;
proc datasets nolist;
	delete	_Gini_cdf_
			_Gini_gini_;
	%if %quote(&by) ~= %then %do;
	delete	_Gini_means_;
	%end;
quit;
%do i = 1 %to &nro_vars;
	%let vari = %scan(&var, &i, ' ');
	%* Remove observations with missing values in TARGET or VAR and observations not satisfying
	%* the condition passed in parameter CONDITION=;
	data _Gini_data_i_;
		set _Gini_data_(keep=&by &target &vari);
		%if %quote(&condition) = %then %do;
		where &target ~= &missing and &vari ~= .;
		%end;
		%else %do;
		where &target ~= &missing and &vari ~= . and &vari &condition;
		%end;
		_gini_obs_ = _N_;
	run;
	%* Count nro. of obs left;
	%Callmacro(getnobs, _Gini_data_i_ return=1, nobs);
	%if &log %then %do;
		%put;
		%put GINI: Variable &i: %upcase(&vari);
		%put GINI: Nro. of obs with missing value in the target variable or analysis variable;
		%put GINI: and satisfying the specified condition in parameter CONDITION=: %eval(&nobsTotal - &nobs);
		%put GINI: Nro. of obs to be used in computations: &nobs;
	%end;
	%* Compute number of obs by BY variables;
	%if %quote(&by) ~= %then %do;
		%Means(_Gini_data_i_, by=&by, var=_gini_obs_, stat=n, name=n, out=_Gini_means_i_(keep=&by n), log=0);
		data _Gini_means_i_;
			format id var;
			set _Gini_means_i_;
			length var $32;
			id = &i;
			var = "&vari";
		run;
	%end;
	%* Compute rank of the analysis variable, because the Gini index is based on the rank;
	%* Note that when there are ties in the analysis variable the rank takes the highest value
	%* because the option TIES is set to HIGH by default. Thus the rank values are the
	%* right-continuous cumulative distribution function of the variable;
	proc sort data=_Gini_data_i_;
		by &by &target;
	run;
	proc rank data=_Gini_data_i_ out=_Gini_cdf_bytarget_i_ fraction;
		by &by &target;
		var &vari;
		ranks cdf;
	run;
	%* Overall rank of the variable values (I need this in order to compute the area under
	%* the curves, because this is the x values by which I need to multiply to compute
	%* the area of each trapezoid);
	proc rank data=_Gini_data_i_ out=_Gini_rank_i_ fraction;
		%if %quote(&by) ~= %then %do;
		by &by;
		%end;
		var &vari;
		ranks rank;
	run;
	%* Merging the variable ranks and the CDFs by target;
	%Merge(_Gini_cdf_bytarget_i_, _Gini_rank_i_, by=&by _gini_obs_, out=_Gini_cdf_i_, log=0);
	%* Dedup and sort by:
	%* - BY variables
	%* - Analysis variable
	%* - Target variable
	%* in order to compute the CDFs for each value of the target variable and to compute
	%* the areas under the curves for each target value;
/*
data _Gini_1;
	set _Gini_cdf_i_;
run;
*/
	proc sort data=_Gini_cdf_i_ out=_Gini_cdf_i_/*(drop=_gini_obs_)*/ nodupkey;
		by &by &vari &target;
	run;
	data _Gini_cdf_i_(drop=cdf cdf1_prev cdf2_prev rank1_prev rank2_prev area1 area2 n Gini GiniSgn
					  rename=(&vari=value))
		 _Gini_gini_i_(keep=&by var n Gini GiniSgn);
		format id var &by value n;
		%if %quote(&by) ~= %then %do;
		merge _Gini_cdf_i_
			  _Gini_means_i_;
		by &by;
		%end;
		%else %do;
		set _Gini_cdf_i_ end=lastobs;
		%end;
		format Gini GiniSgn rank percent7.1;
		length var $32;
		retain cdf1_prev 0; 
		retain cdf2_prev 0;
		retain rank1_prev 0;
		retain rank2_prev 0;
		retain area1 0;		%* Area under the variable CDF for the LOWEST value of the target;
		retain area2 0;		%* Area under the variable CDF for the HIGHEST value of the target;
		array reset{*} cdf1_prev cdf2_prev rank1_prev rank2_prev area1 area2;
		%if %quote(&by) ~= %then %do;
		if %MakeList(&by, prefix=first., sep=or) then
			do i = 1 to dim(reset);
				reset(i) = 0;
			end;
		%end;
		id = &i;
		var = "&vari";
		if &target = &value1 then do;
			cdf1 = cdf;
			cdf2 = max(0, cdf2_prev);	%* The MAX function is to avoid the problem caused by
										%* having the value of cdf2_prev in missing;
		end;
		else if &target = &value2 then do;
			cdf1 = max(0, cdf1_prev);	%* The MAX function is to avoid the problem caused by
										%* having the value of cdf1_prev in missing;
			cdf2 = cdf;
		end;
		%*** Update the area under the curves;
		if &target = &value1 then do;
			area1 = area1 + (cdf1 + cdf1_prev)*(rank - rank1_prev);	%* Twice the Trapezoidal area;
			rank1_prev = rank;
		end;
		else if &target = &value2 then do;
			area2 = area2 + (cdf2 + cdf2_prev)*(rank - rank2_prev);	%* Twice the Trapezoidal area;
			rank2_prev = rank;
		end;
		cdf1_prev = cdf1;
		cdf2_prev = cdf2;
/* Para verificar el calculo del area;
if &target=&value1 then
put _N_= &target= &vari= rank= rank1_prev= cdf1= cdf1_prev= area1=;
if &target=&value2 then
put _N_= &target= &vari= rank= rank2_prev= cdf2= cdf2_prev= area2=;
*/

		%if %quote(&by) ~= %then %do;
		if %MakeList(&by, prefix=last., sep=or) then do;
		%end;
		%else %do;
		if lastobs then do;
			n = &nobs;
		%end;
			%* Add the last part of the CDF that was NOT used last in the computations of the
			%* area and add the area of that part to the total are of that CDF.
			%* This is necessary because
			%* we need to extend each CDF to the 100% rank, but since the rank is computed over
			%* all values of the analysis variable, regardless of the target value, the 100%
			%* rank is reached by only one CDF, which is the CDF that was used last in computations.
			%* Therefore, here I need to add the area of the last part of the CDF that was NOT
			%* used last in computations;
			if &target = &value1 then
				area2 = area2 + (cdf2 + cdf2_prev)*(rank - rank2_prev);
			else if &target = &value2 then
				area1 = area1 + (cdf1 + cdf1_prev)*(rank - rank1_prev);
			%*** Signed Gini where the highest level of the target variable is used as reference;
			%* Note that since area1 and area2 are twice the areas, I do not need
			%* to divide by 0.5 to obtain the Gini Index. This is done in order to have the 
			%* maximum of the Gini Index equal to 1 and because the maximum possible area
			%* between the curves is 0.5;
			%if %sysevalf(%upcase(&event) = %upcase(&value2)) %then %do;
			%* VALUE2 is used as reference for the signed Gini;
			GiniSgn = area1 - area2;
			%end;
			%else %do;						%* Default computation of the signed Gini which uses
											%* the lowest level of the target variable as reference
											%* (The default means that the parameter EVENT is not passed);
			GiniSgn = area2 - area1;
			%end;
			Gini = abs(GiniSgn);
			output _Gini_gini_i_;
		end;
		output _Gini_cdf_i_;
		%if %quote(&by) ~= %then %do;
		drop i;
		%end;
	run;

	%if %quote(&out) ~= or &plot %then %do;
	%* Only create the _GINI_CDF_ dataset with the CDFs for all the variables if an output
	%* dataset or the plot of the CDFs is requested. This is to avoid
	%* wasting time creating this dataset, specially when there are a lot of variables;
	proc append base=_Gini_cdf_ data=_Gini_cdf_i_ FORCE;
	run;
	%end;
	proc append base=_Gini_gini_ data=_Gini_gini_i_ FORCE;
	run;
	%if %quote(&by) ~= %then %do;
	proc append base=_Gini_means_ data=_Gini_means_i_ FORCE;
	run;
	%end;
%end;

/*----------------------------------------- Output datasets ---------------------------------*/
%if %quote(&out) ~= %then %do;
	%let out_name = %scan(&out, 1, '(');
	data &out;
		set _Gini_cdf_(drop=id _gini_obs_);
	run;
	%if &log %then %do;
		%put;
		%put GINI: Output dataset %upcase(&out_name) created with the CDF of each variable by each level of %upcase(&target).;
	%end;
%end;

%if %quote(&outgini) ~= %then %do;
	%let outgini_name = %scan(&outgini, 1, '(');
	data &outgini;
		set _Gini_gini_;
	run;
	%if &log %then %do;
		%put;
		%put GINI: Output dataset %upcase(&outgini_name) created with the Gini Indexes for each variable.;
	%end;
%end;
%else %do;
	title2 "Gini Indexes for dataset %upcase(&data)";
	title3 "Target=%upcase(&target)";
	proc print data=_Gini_gini_;
	run;
	title3;
	title2;
%end;
/*-------------------------------------------------------------------------------------------*/

/*----------------------------------------- Plots -------------------------------------------*/
%if &plot %then %do;
	%DefineSymbols;
	symbol1 height=0.5 interpol=join;
	symbol2 height=0.5 interpol=join;
	legend1 value=("%upcase(&target)=&value1" "%upcase(&target)=&value2");
	axis2 label=("CDF");
	%do i = 1 %to &nro_vars;
		%let vari = %scan(&var, &i, ' ');
		%if %quote(&by) = %then %do;
		data _NULL_;
			set _Gini_gini_;
			n = &nobs;
			where upcase(var) = "%upcase(&vari)";
			call symput ('gini', trim(left(gini)));
			call symput ('n', trim(left(n)));
		run;
		%end;
		axis1 label=("%upcase(&vari)");
		title "CDFs of variable %upcase(&vari) for dataset %upcase(&data_name)"
			%if %quote(&by) = %then %do;
				justify=center
			  	"#Obs=&n Gini=%sysfunc(round(%sysevalf(&gini*100), 0.1))%";
			%end;;
		%* Annotate dataset to show the rank of the values;
	  	data _Gini_anno_;
			set _Gini_cdf_(where=(id=&i) keep=id value rank);
			length text $10;
			retain xsys "2";
			retain ysys "1";		%* 1 is percentage of data area;
			%* Draw a tick mark at the rank values;
			x = value; y = 100;		%* 100% means the upper horizontal axis;
			position = "5";
			function = "symbol";
			text = "|";
			output;
			%* Show the rank value;
			x = value; y = 100;		%* 100% means the upper horizontal axis;
			position = "2";
			function = "label";
			text = "("||trim(left(put(rank, percent7.1)))||")";
			output;
		run;
		%* PLOT;
		proc gplot data=_Gini_cdf_(where=(id=&i)) annotate=_Gini_anno_;
			%if %quote(&by) ~= %then %do;
			by &by;
			%end;
			plot cdf1*value=1 cdf2*value=2 / overlay legend=legend1 haxis=axis1 vaxis=axis2;
		run;
		quit;
	%end;
	title;
	legend1;
	symbol2;
	symbol1;
%end;
/*-------------------------------------------------------------------------------------------*/

proc datasets nolist;
	delete 	_Gini_anno_
			_Gini_data_
			_Gini_data_i_
			_Gini_cdf_i_
			_Gini_cdf_
			_Gini_freq_
			_Gini_means_
			_Gini_means_i_
			_Gini_gini_
			_Gini_gini_i_
			_Gini_rank_i_
			_Gini_cdf_bytarget_i_;
quit;

%end;	%* if ~&error;

%if &log %then %do;
	%put;
	%put GINI: Macro ends;
	%put;
%end;

%ResetSASOptions;
%MEND;
