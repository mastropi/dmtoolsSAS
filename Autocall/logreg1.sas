/* MACRO %LogReg1
Version: 1.00
Author: Daniel Mastropietro
Created: 12-Sep-05
Modified: 12-Sep-05

DESCRIPTION:
Performs univariate Logistic Regression on a set of regressor variables.

USAGE:
%LogReg1(
	data,				*** Input dataset
	target=,			*** Target variable
	var=,				*** Regressor variables
	condition=,			*** Condition that each variable must satisfy in order to be included
						*** in the analysis.
	out=_LR1_loglike_,	*** Output dataset with minus the log-likelihood of each regression.
						*** The smaller the log-likelihood the better the model.
	log=1);				*** Show messages in the log?

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Callmacro
- %Getnobs
- %GetNroElements
- %LogisticRegression
- %ResetSASOptions
- %SetSASOptions
*/
%MACRO LogReg1(data, target=, var=, condition=, out=_LR1_loglike_, log=1)
	/ des="Performs univariate Logistic Regression on a set of variables";
%local dataopt nobs ntotal;
%local i vari;

%SetSASOptions;

%if &log %then %do;
	%put;
	%put LOGREG1: Macro starts;
	%put;
	%put LOGREG1: Univariate Logistic Regression on target variable %upcase(&target);
	%put LOGREG1: for each analysis variable with detection of influential observations;
	%put LOGREG1: with Cook criterion (Influential if Cook > 1).;
	%put;
%end;

/*----- Parse input parameters ----*/
%* Keep only variables used in the analysis;
data _LOGREG1_data_(keep=&target &var);
	set &data;
run;
/*----- Parse input parameters ----*/

proc datasets nolist;
	delete _LOGREG1_loglike_;
quit;
%let nro_vars = %GetNroElements(&var);
%do i = 1 %to &nro_vars;
	%let vari = %scan(&var, &i, ' ');
	%if &log %then
		%put LOGREG1: Variable &i - %upcase(&vari)...;
	proc datasets nolist;
		delete _LOGREG1_loglike_i;
	quit;
	%if %quote(&condition) = %then
		%let dataopt = _LOGREG1_data_(keep=&target &vari);
	%else
		%let dataopt = _LOGREG1_data_(keep=&target &vari where=(&vari &condition));
	%LogisticRegression(
		&dataopt,
		target=&target,
		var=&vari,
		selection=none,
		cook=1,
		thrcook=1.0,
		out=_LOGREG1_pred_(keep=_lr_cookd_),	/* This is used only to get the number of obs used in the regression */
		outest=_LOGREG1_loglike_i(keep=_STATUS_ _NAME_ _LNLIKE_),
		print=0,
		log=0
	);
	data _LOGREG1_temp_;
		set _LOGREG1_pred_;
		where _lr_cookd_ ~= .;
	run;
	%* Total nro. of obs available;
	%Callmacro(getnobs, _LOGREG1_pred_ return=1, ntotal);
	%* Nro. of obs used in the regression;
	%Callmacro(getnobs, _LOGREG1_temp_ return=1, nobs);
	%if %sysfunc(exist(_LOGREG1_loglike_i)) %then %do;
		data _LOGREG1_loglike_i;
			format var ntotal n;
			length var $32;
			set _LOGREG1_loglike_i;
			var = "&vari";
			ntotal = &ntotal;
			n = &nobs;
			Target = "&target";		%* Use the value passed to the macro call because the value of _NAME_
									%* coming from the macro is _LR_Y_, not the original target variable;
			LogL = -_LNLIKE_;
			ThrCook = 1.0;
			ncook = &ntotal - &nobs;
			rename 	_STATUS_ = Status;
			drop _LNLIKE_ _NAME_;
		run;
	%end;
	%else %do;
		data _LOGREG1_loglike_i;
			length var $32;
			var = "&vari";
			n = .;
			Status = "Not Converged";
			Target = "&target";
			LogL = .;
			ThrCook = .;
		run;
	%end;
	proc append base=_LOGREG1_loglike_ data=_LOGREG1_loglike_i;
	run;
%end;

%* Lables;
proc datasets nolist;
	modify _LOGREG1_loglike_;
	label 	ntotal	= "Totla nro. of obs available for the Logistic Regression"
			n 		= "Nro. of obs used in the Logistic Regression"
			Target 	= "Target variable"
			LogL 	= "-Log L"
			ThrCook = "Threshold used for the Cook's distance"
			ncook	= "Nro. of obs removed because of large Cook";
quit;

%if %quote(&out) ~= %then %do;
	data &out;
		set _LOGREG1_loglike_;
	run;
%end;

proc datasets nolist;
	delete	_LOGREG1_data_
			_LOGREG1_loglike_
			_LOGREG1_loglike_i
			_LOGREG1_pred_
			_LOGREG1_temp_;
quit;

%if &log %then %do;
	%put;
	%put LOGREG1: Macro ends;
	%put;
%end;

%ResetSASOptions;
%MEND LogReg1;
