/* MACRO %DetectOutliers
Version: 1.01
Author: Daniel Mastropietro
Created: 8-Mar-05
Modified: 12-Sep-05

DESCRIPTION:
This macro detects outliers with the MAD method, by iteratively increasing the multiplier
for the MAD starting at 9 in given steps (default = 3) so that the percentage of outliers
detected in each variable is not larger than a given percentage (default pcntmax = 1%).

When calling the macro %DetectOutliersMAD, the value zero and &miss are excluded with
the CONDITION parameter.

An output dataset is created with the observations detected as outliers. Default: _DO_outliers_.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Callmacro
- %DetectOutliers
- %FreqMult
- %GetNobs
- %GetNroElements
- %MakeList
- %ResetSASOptions
- %SetSASOptions

*/
/* PENDIENTE:
- 12/5/05: Agregar al output dataset OUTMAD la informacion sobre el numero de outliers y
porcentaje detectados para TODAS las variables. En este momento, solamente se listan las variables
que presentan outliers en la ULTIMA iteracion.
*/
%MACRO DetectOutliers(	data,
						var=_NUMERIC_,
						id=,
						condition=,
						multiplier=9,
						step=3,
						pcntmax=1,
						nameOutlier=outlier,
						prefix=o_,
						out=_DO_outliers_,
						outmad=_DO_MAD_,
						macrovar=,
						log=1) / des="Iterative univariate detection of outliers with the MAD criterion";
%local iter mult nobs;
%local out_name outmad_name;

%SetSASOptions;

%if &log %then %do;
	%put;
	%put DETECTOUTLIERS: Macro starts;
	%put;
%end;

data &out(keep=&id &var);
	set &data;
run;

%* Delete temporary OUTMAD dataset;
proc datasets nolist;
	delete _DO_outmad_;
quit;

%let mult = &multiplier;
%let iter = 0;
%do %until(&nobs = 0);
	%let iter = %eval(&iter + 1);
	%let nro_vars = %GetNroElements(&var);
	%put DETECTOUTLIERS: MULTIPLIER for MAD = &mult;
	%put DETECTOUTLIERS: Variables left for outlier detection:;
	%puts(&var)
	%put;
	%* Note that the number of variables in &var is diminishing at each iteration (because
	%* less number of variables are found to have outliers (as the multiplier increases).
	%* However, the information of the outliers detected for each variable in the previous
	%* iterations is preserved since the variables containing that information (the O_ variables)
	%* are not overwritten at each iteration;
	%DetectOutliersMAD(
		&out,
		var=&var,
		condition=&condition, 
		multiplier=&mult,
		prefix=&prefix,
		out=&out,
		outmad=_DO_outmad_i,
		macrovar=_outlierlist_i,
		log=0);
	%* Using the HADI method but usually it takes too long. The idea is that the Hadi method
	%* would allow to detect only the outliers that are really far away from the cloud of
	%* points, as opposed to what the MAD method does;
/*	%DetectOutliersHadi(
		&out,
		var=&var,
		nameOutlier=o, 
		out=&out, 
		macrovar=_outlierlist_i,
		boxcox=0,
		log=1);*/
	%if &iter = 1 %then %do;
		%if %quote(&macrovar) ~= %then %do;
			%global &macrovar;
			%let &macrovar = &_outlierlist_i;
		%end;
		%else %do;
			%global _outlierslist_;
			%let _outlierlist_ = &_outlierlist_i;
			%let macrovar = _outlierlist_;
		%end;
	%end;
	%FreqMult(&out, var=&_outlierlist_i, out=_DO_freq_outliers_, missing=1, log=0);
	%* Dataset with the variables for which the outlier detection continues in the next
	%* iteration, but with a larger MAD multiplier;
	data _DO_var2iterate_;
		set _DO_freq_outliers_;
		%* Keep only the variables for which some outliers are detected and for which
		%* the percentage of outliers detected is larger than the maximum allowed;
		where value = 1 and percent > &pcntmax;
		%* Create the variable name by eliminating the prefix (O_);
		varname = substr(var, %eval(%length(&prefix)+1));
	run;
	%Callmacro(getnobs, _DO_var2iterate_ return=1, nobs);
	%if &nobs > 0 %then %do;
		%let var = %MakeListFromVar(_DO_var2iterate_, var=varname, log=0);
		%let mult = %sysevalf(&mult + &step);
	%end;
	%* Keep in the OUTMADI dataset only the variables that are NOT in _DO_var2iterate_, because
	%* these are the variables for which outliers still have to be detected, since 
	%* they pass on to the next iteration;
	proc sql;
		create table _DO_outmad_i as 
			select * from _DO_outmad_i
				where not var in (select varname from _DO_var2iterate_);
	quit;

	%* Append current OUTMAD dataset to the overall OUTMAD dataset;
	proc append base=_DO_outmad_ data=_DO_outmad_i FORCE;
	run;
%end;

data &out;
	set &out;
	&nameOutlier = %MakeList(&&&macrovar, sep=OR);
	%** Note that: MISSING OR 1 is equal to 1, and MISSING OR 0 is equal to 0, so it is
	%** ok to logically concatenate the variables containing the outlier detection
	%** information, even when some of those variables may be missing because of the 
	%** CONDITION= parameter passed in the call to the macro DetectOutliers which may
	%** eliminate some records of some variables from the outlier detection process;
run;

%* Dataset with MAD computations;
data &outmad;
	format id var nobs n count percent percentAll median MAD CV;
	set _DO_outmad_;
	format CV percent7.1;
	if MAD ~= . and median not in (0 .) then
		CV = MAD / median;
	else
		CV = .;
	label CV = "Coefficient of Variation based on Median and MAD";
run;

%let out_name = %scan(&out, 1, '(');
%let outmad_name = %scan(&outmad, 1, '(');
%put DETECTOUTLIERS: Dataset %upcase(&outmad_name) created with the information on the MAD and thresholds for;
%put DETECTOUTLIERS: each analysis variable;
%put;
%put DETECTOUTLIERS: Dataset %upcase(&out_name) created with the outlier information.;
%put DETECTOUTLIERS: Variable %upcase(&nameOutlier) is the indicator of an outlier detected in;
%put DETECTOUTLIERS: any of the analysis variables.;
%put DETECTOUTLIERS: Variables starting with O_ are the indicators of the outliers detected;
%put DETECTOUTLIERS: for each analysis variable.;
%put;
%put DETECTOUTLIERS: Global macro variable %upcase(&macrovar) created with the list of variables;
%put DETECTOUTLIERS: that flag the outliers.;

proc datasets nolist;
	delete	_DO_freq_outliers_
			_DO_outmad_i
			_DO_outmad_
 			_DO_var2iterate_;
quit;

%if &log %then %do;
	%put;
	%put DETECTOUTLIERS: Macro ends;
	%put;
%end;

%ResetSASOptions;
%MEND DetectOutliers;
