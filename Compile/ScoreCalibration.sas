/* MACRO %ScoreCalibration
Version: 1.00
Author: Daniel Mastropietro
Created: 27-May-05
Modified: 27-May-05

NOTA: Al dia de la fecha 29/7/05 esta macro no fue probada. Entro' en desuso porque ya no se usa
como calibracion del score, sino que ahora se usa una transformacion lineal del LOGIT, que es
el estandar del mercado: a*logit + b.

DESCRIPTION:
Calibrates the score of a model for a dichotomous target, by following 3 steps:
1.- Non linear calibration to adjust the score to the observed probability.
2.- Linear calibration to transform the calibrated score to a more intelligible range of values.
3.- Linear calibration to adjust the scores among different populations, in the sense that
the same value of the score represents the same estimated probability.

USAGE:
%ScoreCalibration(
	data,				*** Input dataset containing the score.
	calib=, 			*** Dataset with the calibration information.
	type=,				*** Type of calibration performed stored in column TYPE of CALIB.
	score=,				*** Name of the variable in DATA containing the score.
	function1=, 		*** Name of the column in CALIB containing the non-linear calibration 
	function2=,			*** Name of the column in CALIB containing the linear calibration of step 2.
	params1=a b c,		*** Names of the parameters used in the non-linear and the linear calibration at step 2.
	params2=1 1 0 0 0,	*** Values of the parameters used in the linear calibration of step 3.
	out=,				*** Output dataset
	outerror=,			*** Output dataset containing the observations that gave error when calibrating.
	log=1);				*** Show messages in the log?

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %GetNroElements
- %GetVarNames
- %MakeListFromVar
- %RemoveFromList
- %ResetSASOptions
- %SetSASOptions
*/
&rsubmit;
%MACRO ScoreCalibration(data,
						calib=, 
						type=, 
						score=, 
						function1=, 
						function2=,
						params1=a b c,
						params2=1 1 0 0 0,
						out=,
						outerror=_SC_error_,
						log=1)
	/ store des="Non linear calibration of the score in a scoring model (not used any more)";
%local i;
%local data_name outerror_name;
%local nro_params1 nro_params2;
%local fcal flin;
%local p1 p2 p3 p4 p5 adjust;
%local varnames;

%SetSASOptions;

/*------------------------------ Parsing input parameters -----------------------------------*/
%*** DATA;
%let data_name = %scan(&data, 1, '(');

%*** PARAMS1=;
%* Parameter names for the non linear transformation performed at the first calibration step;
%let nro_params1 = %GetNroElements(&params1);
%do i = 1 %to &nro_params1;
	%local param&i;
	%let param&i = %scan(&params1, &i, ' ');
%end;

%*** PARAMS2=;
%* It is assumed that there are 4 parameters passed:
%* p1(=a1), p2(=a2), p3(=b1), p4(=b2), p5(=adjustment factor);
%let nro_params2 = %GetNroElements(&params2);
%let p1 = 1;
%let p2 = 1;
%let p3 = 0;
%let p4 = 0;
%let p5 = 0;	%* Adjustment parameter for linear calibration;
%do i = 1 %to %sysfunc(min(5, &nro_params2));	%* 5 is the number of parameters p1-p5;
	%let p&i = %scan(&params2, &i, ' ');
%end;
%let adjust = &p5;

%*** OUT=;
%if %quote(&out) = %then
	%let out = &data;
/*------------------------------ Parsing input parameters -----------------------------------*/

%* Calibration dataset;
data _SC_calib_;
	set &calib;
	where upcase(type) = "%upcase(&type)";
run;
%*** Calibration functions;
%* Non linear calibration;
%let fcal = %MakeListFromVar(_SC_calib_, var=&function1, log=0);
%* Linear calibration;
%let flin = %MakeListFromVar(_SC_calib_, var=&function2, log=0);
%if &log %then %do;
	%put SCORECALIBRATION: Non linear calibration performed: &fcal;
	%put SCORECALIBRATION: Linear calibration: &flin;
	%put SCORECALIBRATION: Linear Inter-calibration:;
	%put SCORECALIBRATION: ROUND(&p2/&p1*(&flin) + (&p4-&p3)/&p1 + &adjust); 
%end;

%* Add calibrated score, probability and odds to the output dataset;
%if &log %then %do;
	%put;
	%put SCORECALIBRATION: Reading variables in input dataset...;
%end;
%let varnames = %GetVarNames(&data);
%let varnames = %RemoveFromList(&varnames, score p odds logit, log=0);
%if &log %then %do;
	%put;
	%put SCORECALIBRATION: Calibrating...;
%end;
data &out &outerror;
	format &varnames score p_cal odds_cal logit_cal p odds logit;
	%if %quote(&out) ~= %quote(&data) %then %do;
	set &data;		%* The DATA options are performed here;
	%end;
	%else %do;
	set &data_name;	%* The DATA options are performed in the DATA &out statement;
	%end;
	if _N_ = 1 then set _SC_calib_(keep=type &params1);
	p = 1 / (1 + exp(-&score));
	if p not in (0, 1) then do;
		odds = p/(1 - p);
		logit = log(odds);
	end;
	else do;
		odds = .;
		logit = .;
	end;
	if logit ~= . then
		logit_cal = &fcal;
	else do;
		if p = 0 then
			logit_cal = &param2;
		else if p = 1 then
			logit_cal = &param1 + &param2;
	end;
	%* Calibrated probability;
	p_cal = 1 / (1 + exp(-logit_cal));
	odds_cal = p_cal / (1 - p_cal);
	%* Calibrated score: calibration given by the CALIB dataset + calibration given
	%* by the parameters p1-p4. If these parameters take the default values (1, 1, 0, 0)
	%* only the first calibration is performed;
	%* The ADJUST parameter is used to avoid some out-of-bounds values that should not
	%* be expected;
	score = round(&p2/&p1*(&flin) + (&p4-&p3)/&p1 + &adjust);
	if _ERROR_ then output &outerror;
	output &out;
	rename 	p = p_orig
			odds = odds_orig
			logit = logit_orig
			p_cal = p
			odds_cal = odds
			logit_cal = logit;
run;

%if &log %then %do;
	%Callmacro(getnobs, &outerror return=1, nobs);
	%if &nobs > 1 %then %do;
		%let outerror_name = %scan(&outerror, 1, '(');
		%put;
		%put SCORECALIBRATION: Output dataset %upcase(&outerror_name) created with the errors  ;
	%end;
%end;

proc datasets nolist;
	delete _SC_calib_;
quit;

%ResetSASOptions;
%MEND ScoreCalibration;