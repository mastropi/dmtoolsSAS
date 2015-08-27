/* CrossCorr.sas
Created:		03-Aug-2012
Author:			Daniel Mastropietro
Description:	Cross-correlation analysis of several input series w.r.t. a target series.
Input:			Dataset with a target variable to be modeled with an ARIMAX model and input variables to be considered in that model.
Output:			Dataset containing the cross-correlation function between the pre-whitened input and target series.
				One single dataset is created for all input variables taken into consideration.
SAS Version:	v9.3
Modules:		SAS/ETS
Procedures:		ARIMA
Notes:			This macro was created at Centrica UK and it worked fine.
*/


%MACRO CrossCorr(
		data,
		target=y,			/* Target variable to be modeled with the ARIMAX model */
		input=x,			/* List of input variables to analyze for correlation with target variable */
		by=,
		diff=,				/* Any differences that should be applied to the input and target series: e.g. diff=(7,365) */
		p=4,				/* AR order of the ARIMA model to be fit to each input series */
		q=4,				/* MA order of the ARIMA model to be fit to each input series */
		plots=%quote(plots(only)=(series(crosscorr))),
		out=_cc_outcov_);

%local i;
%local nro_vars;
%local vari;

%let nro_vars = %sysfunc(countw(&var));

proc datasets nolist;
	delete &out;
quit;
%* Set the length of the CROSSVAR variable in the OUTCOV= dataset created by PROC ARIMA below
%* so that there is no truncation of analysis variable names;
data &out;
	format &by lag var crossvar n cov corr stderr invcorr partcorr;
	length &by var crossvar $32;
	length lag n cov corr stderr invcorr partcorr 8;
run;

%if %quote(&by) ~= %then %do;
proc sort data=&data out=_cc_data_;
	by &by;
run;
%end;
%else %do;
data _cc_data_;
	set &data;
run;
%end;

%do i = 1 %to &nro_vars;
	%let vari = %scan(&var, &i);
	proc arima data=_cc_data_ &plots;
		%if %quote(&by) ~= %then %do;
		by &by;
		%end;
		%* Apply an ARIMA(&p,&diff,&q) model to the input series currently analyzed and compute the cross-correlation between
		%* the pre-whitened target and input series using the aforementioned model;
		identify var=&vari &diff;
		estimate p=&p q=&q;
		identify var=&target &diff
					crosscorr=&vari &diff
					outcov=_cc_outcov_&i;
	run;

	proc append base=&out data=_cc_outcov_&i FORCE;
	run;

	proc datasets nolist;
		delete _cc_outcov_&i;
	quit;
%end;

%if %quote(&by) ~= %then %do;
	%* Sort first by BY variables and then by the name of the input analyzed variables;
	proc sort data=&out;
		by &by crossvar;
	run;
%end;

proc datasets nolist;
	delete _cc_data_;
quit;

%MEND CrossCorr;
