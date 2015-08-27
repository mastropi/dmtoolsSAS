/* MACRO %DetectOutliersHadi
Author: Daniel Mastropietro
Created: 4-Oct-04
Modified: 4-Oct-04

DESCRIPTION:
This macro detects univariate outliers with the Hadi method.
The macro %Hadi is  called to detect outliers for each individual requested variable.
By default, a Box-Cox transformation is performed prior to the outlier detection
in order to attain a nearly normal distribution for each variable.

USAGE:
%DetectOutliersHadi(
	data,
	var=_NUMERIC_,
	alpha=0.05,
	adjust=1,
	boxcox=1,
	nameOutlier=outlier,
	out=,
	macrovar=,
	log=1);

REQUIRED PARAMETERS:
- data:				Input dataset. Data options can be specified as in a data= SAS option.

OPTIONAL PARAMETERS:
- var:				Blank-separated list of variables on which the outlier detection is
					to be performed.

- alpha:			Probability level used to define an observation as an outlier.
					Possible values: between 0 and 1
					default: 0.05

- adjust:			Whether to adjust or not the level alpha by the number of observations
					in the dataset so that the probability of detecting outliers just
					by chance is reduced.
					Possible values: 0 => Do not adjust, 1 => Adjust
					default: 1

- boxcox:			Whether to perform a Box-Cox transformation for symmetrization of
					each variable's distribution prior to the outlier detection.
					Possible options: 0 => Do not transform, 1 => Transform
					default: 1

- nameOutlier:		Name to use for the variable indicating the number of observations
					that were detected as outlier in at least one of the variables.
					It is also the name used as the radical for the variables indicating
					whether an observation is an outlier for each of the variables.
					The names of these variables have the form:
					<nameOutlier>_<analysis-variable>
					Ex: if nameOutlier=outlier and var=x z, then the names of the
					outlier indicator variables are: outlier_x, outlier_z.
					default: outlier

- out:				Output dataset. Data options can be specified as in a data= SAS option.
					The output dataset contains the same observations and variables as
					the input dataset, plus the following variables:
					- one variable for each analysis variable containing a 0/1 flag
					indicating whether an observation was detected as an outlier for
					the corresponding analysis variable. Its name has the form:
					<nameOutlier>_<analysis-variable> 
					- a variable indicating whether the corresponding observation was
					detected as an outlier for any of the analysis variable. Its name is
					the name passed in option nameOutlier=.
					- _ALPHA_: level used in the detection of outliers.
					- _ALPHA_ADJ_: _ALPHA_ adjusted by the number of observations to reduce
					the probabilities of detecting outliers just by chance.

- macrovar:			Name of the global macro variable where the list of variables
					indicating outliers in each input variable is stored.

- log:				Show messages in log?
					Possible values: 0 => No, 1 => Yes
					default: 1

NOTES:
- The name 'data' cannot be used as the name of the macro variable to return the list of
the variables containing the outlier indicator.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Drop
- %GetNroElements
- %Hadi
- %MakeList
- %Means
- %ResetSASOptions
- %SetSASOptions
- %SetVarOrder
*/
&rsubmit;
%MACRO DetectOutliersHadi(	data,
					  	var=_NUMERIC_, 
						alpha=0.05, 
						adjust=1, 
						boxcox=1, 
						nameOutlier=outlier, 
						out=, 
						macrovar=, 
						log=1) / store des="Univariate outlier detection with the Hadi method";
%local _i_;
%local _data_name_ _nro_vars_ _out_name_ _outliers_ _vari_;

%SetSASOptions;

%if &log %then %do;
	%put;
	%put DETECTOUTLIERS: Macro starts;
	%put;
%end;

%let _data_name_ = %scan(&data, 1, '(');
%if %quote(&out) = %then
	%let out = &_data_name_;
%let _out_name_ = %scan(&out, 1, '(');

%* Copying the input dataset to the output dataset and adding a variable with the
%* observation number;
data &out;
	set &data;
	_DetectOutliers_obs_ = _N_;
run;

%*** Outlier detection;
%if &log %then %do;
	%put DETECTOUTLIERS: Detecting outliers by univariate Hadi...;
	%if &boxcox %then
		%put DETECTOUTLIERS: First, performing Box-Cox symmetrization transformation.;
	%else
		%put DETECTOUTLIERS: No prior symmetrization transformation is performed.;
	%put;
%end;

%* Drop variables that will contain the outlier indicator, in case they exist;
%Drop(&out, %MakeList(&var, prefix=&nameOutlier._) &nameOutlier);
%let _nro_vars_ = %GetNroElements(&var);
%do _i_ = 1 %to &_nro_vars_;
	%let _vari_ = %scan(&var, &_i_, ' ');
	%if &log %then
		%put DETECTOUTLIERS: Analyzing variable %upcase(&_vari_) (&_i_ of &_nro_vars_) ...;
	%* Outlier detection with Hadi;
	%* Note that it is necessary to create a temporary output dataset (_DetectOutliers_vari_)
	%* and then merge with dataset &out because if the current variable &_vari_ has
	%* missing data, all the observations with at least one missing data in one of the 
	%* variables would be eliminated from the output dataset and we do not want this;
	%Hadi(&_out_name_, outAll=_DetectOutliers_vari_, var=&_vari_, alpha=&alpha, adjust=&adjust, 
					   boxcox=&boxcox, nameOutlier=&nameOutlier._&_vari_, log=0);
	data &_out_name_;
		merge &_out_name_
			  _DetectOutliers_vari_(keep=_DetectOutliers_obs_ &nameOutlier._&_vari_ _ALPHA_ _ALPHA_ADJ_);
		by _DetectOutliers_obs_;
	run;
%end;

%* List of variables indicating an outlier in each variable;
%let _outliers_ = %MakeList(&var, prefix=&nameOutlier._);

%* Add a variable that indicates if an observation is detected as an outlier in ANY
%* of the variables analyzed and drop variables created in %Hadi that are not informative
%* because they have the same names for all the varibles analyzed;
data &_out_name_;
	set &_out_name_;
	&nameOutlier = %any(&_outliers_, =, 1);
	drop _DetectOutliers_obs_;
run;
%SetVarOrder(&_out_name_, _ALPHA_ _ALPHA_ADJ_, after, &nameOutlier);

%* Show message in log indicating new dataset created and new variables added to it;
%if &log %then %do;
	%put;
	%if &_out_name_ ~= &_data_name_ %then
		%put DETECTOUTLIERS: Dataset %upcase(&_out_name_) created.;
	%put DETECTOUTLIERS: Variables:;
	%put DETECTOUTLIERS: &_outliers_;
	%put DETECTOUTLIERS: were added to dataset %upcase(&_out_name_).;
%end;

%* Computing the number of outliers detected for each variable;
%Means(&out, var=&_outliers_ &nameOutlier, stat=sum mean, out=_DetectOutliers_count_, transpose=1, namevar=var, log=0);
%* Show a summary of the number of outliers detected;
%if &log %then %do;
	%put;
	%put DETECTOUTLIERS: Nro. of outliers detected for:;
	data _DetectOutliers_count_;
		set _DetectOutliers_count_;
		var = upcase(var);
		format mean percent7.2;
		if upcase(var) ~= "%upcase(&nameOutlier)" then
			put "DETECTOUTLIERS: " var ": " sum "( " mean ")";
		else
			put "DETECTOUTLIERS: Nro. of obs. with at least one outlier detected in any of the vars: " sum "( " mean ")";
	run;
%end;

proc datasets nolist;
	delete 	_DetectOutliers_count_
			_DetectOutliers_vari_;
quit;

%* Store into a global macro variable, the list of the variables created indicating the
%* outliers detected;
%if %quote(&macrovar) ~= %then %do;
	%global &macrovar;
	%let &macrovar = &_outliers_;
%end;

%if &log %then %do;
	%put;
	%put DETECTOUTLIERS: Macro ends;
	%put;
%end;

%ResetSASOptions;
%MEND DetectOutliersHadi;
