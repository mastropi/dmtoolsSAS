/* Macro %LorenzCurve
Version: 		1.00
Author: 		Daniel Mastropietro
Created:		15-May-2015
Modified:		09-Jul-2015
SAS version:	9.4

DESCRIPTION:
Generates Lorenz Curves for a non-negative numeric target variable (generally continuous) in terms of a set
of input variables and creates an output dataset that stores the area between the Lorenz curve and the perfect
equality line (diagonal) relative to the maximum possible area.
The area is always treated as positive regardless of whether the Lorenz curve lays above or below the diagonal.
The rationale behind this logic is to be able to summarize in this area strong nonlinear relationships between
the input variables and the target.

By default, missing values in the input variables are allowed, in which case they are treated as the
smallest variable value.

USAGE:
%LorenzCurve(
	data,		*** Input dataset.
	target=,	*** Target variable (assumed non-negative)
	var=,		*** List of input variables.
	missing=1,	*** Whether missing values in the input variables are allowed.
	out=, 		*** Output dataset containing the area between the Lorenz Curve and the diagonal
	plot=1,		*** Whether to plot the Lorenz curve of each analysis variable
	log=1)		*** Show messages in log?

REQUIRED PARAMETERS:
- data:			Input dataset. It can contain additional options as in any data=
				option in SAS (such as keep=, where=, etc.).

- target:		Target variable on which the Lorenz Curves are computed.

- var:			Blank separated list of input variables to analyze.

OPTIONAL PARAMETERS:
- missing:		Whether missing values in the input variables are allowed.
				In such case, they are considered as the smallest value taken by the input variable
				and are represented by the leftmost non-zero value in the Lorenz Curve.
				Possible values: 0 => No, 1 => Yes.
				default: 1

- out:			Output dataset containing the area between the Lorenz Curve and the diagonal
				(perfect equality line). The absolute value of the area is reported.
				The output dataset contains the following columns:
				- var: contains the analysis variable name
				- nobs: number of observations used in the analysis
				- area: area between the Lorenz curve and the perfect equality line (diagonal)
				relative to the maximum possible area, which is obtained when the input variable
				sorting perfectly sorts the target variable values.
				default: <data>_lorenz

- plot:			Whether to plot the Lorenz curve of each analysis variable.
				Possible values: 0 => No, 1 => Yes.
				default: 1

- log:			Show messages in log?
				Possible values: 0 => No, 1 => Yes.
				default: 1

NOTES:
1.- Non-negative values: the target variable is assumed to be non-negative.
2.- Default missing values treatement:
	- missing values in input variables are considered valid and contribute to the cumulative
	distribution at the lowest end.
	- missing values in the target variable are excluded from the analysis, meaning that the
	whole observation is excluded, also not contributing to the cumulative distribution of the
	input variable.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %CheckInputParameters
- %GetDataName
- %Getnobs
- %GetNroElements
- %GetStat
- %ResetSASOptions
- %SetSASOptions

SEE ALSO:
- %EvaluationChart (for binary targets)

APPLICATIONS:
Get a graphical and quantitative measure of the input variable strength in predicting a numeric target variable,
in general a continuous variable, similar to the Gini index for binary targets.
*/

&rsubmit;
%MACRO LorenzCurve(	data,
					target=,
					var=,
					missing=1,
					out=,
					plot=1,
					log=1,
					help=0) / store des="Plots the Lorenz Curve for a non-negative target variable and its area w.r.t. the diagonal";
%local error;

%let error = 0;

/*----- Macro to display usage -----*/
%MACRO ShowMacroCall;
	%put LORENZCURVE: The macro call is as follows:;
	%put %nrstr(%LorenzCurve%();
	%put data , (REQUIRED) %quote(      *** Input dataset.);
	%put target= , (REQUIRED) %quote(   *** Target variable %(assumed non-negative%).);
	%put var= , (REQUIRED) %quote(      *** List of input variables.);
	%put missing=1 , %quote(            *** Whether missing values in the input variables are allowed.);
	%put out= , %quote(                 *** Output dataset containing the area between the Lorenz Curve);
	%put %quote(                        *** and the diagonal %(in absolute value%) for each variable.);
	%put plot= , %quote(                *** Whether to plot the Lorenz curve of each analysis variable.);
	%put log=1) %quote(                 *** Show messages in log?);
%MEND ShowMacroCall;

%if &help %then %do;
	%ShowMacroCall;
%end;
%else %if ~%CheckInputParameters(data=&data , var=&var, varRequired=1, otherRequired=%quote(&target), requiredParamNames=data var= target=, singleData=1, macro=LORENZCURVE) %then %do;
	%ShowMacroCall;
%end;
%else %do;
/************************************* MACRO STARTS ******************************************/
%* Define local variables;
%local data_name;
%local out_lib;
%local out_name;
%local i;
%local _var_;
%local nvar;
%local nobs;			%* Number of valid observations (based on the target variable);
%local ntotal;			%* Number of observations in the input dataset;
%local nmiss;			%* Number of missing values in the input variable;
%local fMissingValue;	%* Flag indicating whether the input variable takes missing values;
%local area_pct;

%* Show input parameters;
%if &log %then %do;
	%put;
	%put LORENZCURVE: Macro starts;
	%put;
	%put LORENZCURVE: Input parameters:;
	%put LORENZCURVE: - Input dataset = %quote(&data);
	%put LORENZCURVE: - target = %quote(       &target);
	%put LORENZCURVE: - var = %quote(          &var);
	%put LORENZCURVE: - missing = %quote(      &missing);
	%put LORENZCURVE: - out = %quote(          &out);
	%put LORENZCURVE: - plot = %quote(         &plot);
	%put LORENZCURVE: - log = %quote(          &log);
	%put;
%end;

%*----------------------- Parse input parameters ----------------------;
%*** DATA;
%let data_name = %GetDataName(&data);
%*** OUT=;
%if %quote(&out) = %then %do;
	%let out = &data_name._lorenz;
	%if %length(&out) > 32 %then %do;
		%let error = 1;
		%put LORENZCURVE: ERROR - The name to be used for the output dataset is too long (%length(&out) characters);
		%put LORENZCURVE: and exceeds the maximum allowed length of 32 characters.;
		%put LORENZCURVE: Please use the OUT= parameter to assign a valid SAS name to the output dataset.;
		%put LORENZCURVE: The macro will stop executing.;
	%end;
%end;
%*----------------------- Parse input parameters ----------------------;
%if ~&error %then %do;

%SetSASOptions;

%* Create a copy of the input dataset where any included data options are applied;
data _LC_data_;
	set &data end=lastobs;
	if lastobs then
		call symput ('ntotal', trim(left(put(_N_, comma15.0))));
run;

%* Delete the output dataset in case it exists;
%let out_lib = %GetLibraryName(&out);
%let out_name = %GetDataName(&out);
proc datasets library=&out_lib nolist;
	delete &out_name;
quit;

%let nvar = %GetNroElements(&var);
%do i = 1 %to &nvar;
	%let _var_ = %scan(&var, &i, ' ');

	%* Sum the target variable for each value of the input variable so that we have unique values in the input variable;
	proc means data=_LC_data_ sum noprint;
		class &_var_ %if &missing %then %do; / missing %end;;	%* include missing values as a valid class value (this should show up as the first value of the input variable);
		var &target;
		output out=_LC_data_means_ n=ntarget sum=&target;
	run;

	%* Computation of F(x), cdf of x, and L(F), Lorenz curve;
	data _LC_data_means_ _LC_area_(keep=var nobs area_prp rename=(area_prp=area));
		format var nobs;
		format area_prp percent7.2;
		label 	var = "Input variable"
				nobs = "Number of valid cases"
				area_prp = "Area between Lorenz curve and perfect equality line";
		length var $32;
		var = "&_var_";
		if _N_ = 1 then do;
			%* Read the overall statistics (with the totals);
			set _LC_data_means_(where=(_TYPE_=0)
								keep=_TYPE_ ntarget &target
								rename=(ntarget=nobs &target=target_total));	%* Note the use of fixed new names to avoid problem with overflow of variable name length;
			%* First obsrevation should be F = 0, L = 0;
			%* This case is added so that the Lorenz curve is joined to the point (0,0);
			_TYPE_ = .;
			_FREQ_ = 0;
			&_var_ = .;
			ntarget = 0;
			&target = .;
			F = 0;	%* Cumulative distribution of input variable;
			L = 0;	%* Lorenz curve (cumulative pecent of target variable, which is like a cumulative distribution weighted by the target variable values);
			output _LC_data_means_;
		end;
		%* Read the actual statistics;
		set _LC_data_means_(where=(_TYPE_=1)) end=lastobs;
		%* Accumulate the different measures;
		retain nvalid_cum 0;	%* Cumulative number of valid observations (based on valid target values) used to compute F;
		retain target_cum 0;	%* Cumulative sum of target values used to compute L, the Lorenz curve;
		retain area 0;			%* Area between the Lorenz curve and the perfect equality line (diagonal);
		retain area_max 0;		%* Maximum possible area;
		nvalid_cum + ntarget;
		target_cum + &target;
		F = nvalid_cum / nobs;
		L = target_cum / target_total;
		%* Previous values of F and L;
		lagF = lag(F);
		lagL = lag(L);
		if _N_ = 1 then do;
			%* Check if the input variable takes a missing value (in which case it will be placed as the first observation
			%* of the output dataset generated by PROC MEANS (_LC_data_means_);
			if &_var_ = . then do;
				call symput ('fMissingValue', 1);
				call symput ('nmiss', trim(left(put(ntarget, comma15.0))));
			end;
			else do;
				call symput ('fMissingValue', 0);
				call symput ('nmiss', 0);
			end;
			%* Set lagF and lagL to 0, o.w. they are missing for the SECOND observation of the output dataset...;
			lagF = 0;
			lagL = 0;
			area_max + 0.5*F*(1 - F) ;	%* This takes into account the discrete nature of the area calculation, in the sense that the Lorenz curve cannot go instantly to 1 at F=0;
										%* It basically computes the area between a triangle of width F and height 1 and the 45 degree diagonal;
		end;
		%* Area between Lorenz curve and perfect equality line;
		area + abs(0.5*(F - lagF)*((lagL + L) - (lagF + F)));	%* Based on area of the parallelogram = (a + b)*DeltaF / 2;
		area_max + 0.5*(F - lagF)*(2 - lagF - F);				%* Increase in maximum possible area;
		area_prp = area / area_max;								%* Normalization of the area w.r.t. the maximum possible area;
		output _LC_data_means_;
		if lastobs then do;
			output _LC_area_;
			call symput ('nobs', trim(left(put(nobs, comma15.0))));
			call symput ('area_pct', trim(left(put(area_prp, percent7.2))));
		end;
	run;

	%* Append the area for this variable into the output dataset with all the areas;
	proc append base=&out data=_LC_area_ FORCE;
	run;

	%* Plot Lorenz curve;
	%if &plot %then %do;
		title1 "Lorenz curve for &target vs. &_var_";
		%if &fMissingValue %then %do;
		title2 "(# valid target cases = &nobs, # total cases = &ntotal, # miss in input var = &nmiss)";
		title3 "the leftmost non-zero point corresponds to the missing value";
		%end;
		%else %do;
		title2 "(# valid target cases = &nobs, # total cases = &ntotal)";
		%end;
		proc sgplot data=_LC_data_means_;
			series x=F y=L / markers legendlabel="Lorenz curve";
			lineparm x=0 y=0 slope=1 / lineattrs=(color="black") legendlabel="Perfect equality line";
			xaxis label="Cumulative Distribution Function of &_var_";
			yaxis label="Lorenz curve for &target";
			inset ("Lorenz curve area = " = "&area_pct") / position=topleft;
		run;
		title3;
		title2;
		title1;
	%end;
%end;

%* Label of output dataset;
proc datasets library=&out_lib nolist;
	modify &out_name (label = "Lorenz curve areas for dataset %quote(&data)");
quit;

%* Delete temporary datasets;
proc datasets nolist;
	delete 	_LC_data_
			_LC_data_means_
			_LC_area_;
quit;

%if &log %then %do;
	%put;
	%put LORENZCURVE: Macro ends;
	%put;
%end;

%ResetSASOptions;
%end;	%* if ~&error;

%end;	%* if ~%CheckInputParameters;
%MEND LorenzCurve;
