/* MACRO %Oversampling
Version: 1.00
Author: Daniel Mastropietro
Created: 18-Aug-05
Modified: 18-Aug-05

DESCRIPTION:
This macro partitions the input dataset into two samples (TRAINING and VALIDATION)
performing oversample on a target dichotomous variable with specified rates on each sample.

USAGE:
%MACRO Oversampling(
	data,				*** Input dataset.
	target=, 			*** Target variable on which the oversampling is performed.
	rates=, 			*** Sampling rates for each value of the target variable in
						*** TRAINING and VALIDATION.
	seed=12345,			*** Sample seed. 
	out=,				*** Output dataset.
	format=,			*** Variables and formats to be used in the output dataset format statement.
	namesample=SAMPLE,	*** Name for the variable that will contain the sample allocation info.
	values=TRAIN VALID,	*** Values to be used for the sample allocation in variable NAMESAMPLE.
	log=1);				*** Shows messages in the log?

REQUIRED PARAMETERS:
- data:				Input dataset where the sample partition is performed. 
					Data options can be specified as in a data= SAS option.

- target:			Name of the target variable on which the oversample is performed.

- rates 			Blank-separated list of the rare event rates desired in each sample.
					The first value is the Rare Event Rate for the TRAINING sample and
					the second value is the Rare Event Rate for the VALIDATION smaple.

OPTIONAL PARAMETERS:
- seed:				Sample seed.
					default: 12345

- out:				Output dataset with the same data as the input dataset plus an
					additional variable indicating the sample allocation of each observation.
					If no dataset is passed, the allocation variable is added at the beginning
					of the input dataset.

- format:			Contents of the FORMAT statement to use when creating the output dataset.
					Ex: FORMAT=obs pcnt percent7.1

- namesample:		Name to be used for the variable containing the sample allocation.
					The values that identify each sample are specified in parameter VALUES.
					By default, the values are TRAIN and VALID respectively for the TRAINING
					and VALIDATION samples.
					default: SAMPLE

- values:			Blank-separated values to be used for variable NAMESAMPLE= to identify each
					sample (TRAINING and VALIDATION).
					default: TRAIN VALID

- log:				Show messages in the log?
					Possible values: 0 => No, 1 => Yes
					default: 1

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Callmacro
- %Getnobs
- %ResetSASOptions
- %SetSASOptions
*/
%MACRO Oversampling(data,
					target=, 
					rates=, 
					seed=12345,

					out=,
					format=,

					namesample=SAMPLE,
					values=TRAIN VALID,

					log=1) / des="Oversampling of a target dichotomous variable";
%local NC NR N;
%local PC PR prt prv;
%local VC VR;
%local nobs;
%local SampSize SampRateRare SampRateCommon;
%local LowerEvent samprates;
%local length1 length2 length; 	%* Length of VALUES and length to be used for variable NAMESAMPLE;
%local ss_train ss_valid;		%* Sample sizes obtained for training and validation samples;

%SetSASOptions;

%if &log %then %do;
	%put;
	%put OVERSAMPLING: Macro starts;
	%put;
%end;

/*----- Parse Input Parameters -----*/
%*** RATES=;
%let prt = %sysevalf(%scan(&rates, 1, ' ')/100);
%let prv = %sysevalf(%scan(&rates, 2, ' ')/100);

%*** OUT=;
%if %quote(&out) = %then
	%let out = &data;
/*----- Parse Input Parameters -----*/

%if &log %then %do;
	%put OVERSAMPLING: Requested sampling rates for the Rare Event are:;
	%put OVERSAMPLING: TRAIN: %scan(&rates, 1, ' ')%;
	%put OVERSAMPLING: VALID: %scan(&rates, 2, ' ')%;
	%put;
%end;

%* Check if rate values are between 0 and 100;
%if not ((%sysevalf(0 < &prt) and %sysevalf(&prt < 1)) and (%sysevalf(0 < &prv) and %sysevalf(&prv < 1))) %then %do;
	%put OVERSAMPLING: The rate values passed in parameter RATES (%scan(&rates, 1, ' ')% %scan(&rates, 2, ' ')%) are not between 0 and 100.;
	%put OVERSAMPLING: The macro will stop executing.;
%end;
%else %do;
%* Read input dataset;
%if &log %then
	%put OVERSAMPLING: Reading input dataset...;
data _OS_data_(index=(_OS_obs_ / unique));
	format _OS_obs_;
	set &data;
	_OS_obs_ = _N_;
run;

%if &log %then
	%put OVERSAMPLING: Computing Event Rates...;
proc freq data=_OS_data_(keep=&target) noprint order=freq;
	tables &target / out=_freq_;
run;
%Callmacro(getnobs, _freq_ return=1, nobs);
%if &nobs ~= 2 %then %do;
	%put;
	%put OVERSAMPLING: ERROR - The number of possible values of the target variables must be 2.;
%end;
%else %do;
data _NULL_;
	set _freq_;
	if _N_ = 1 then do;
		call symput ('VC', trim(left(&target)));		%* Value of Common Event;
		call symput ('NC', trim(left(count)));			%* Count of Common Event;
		call symput ('PC', trim(left(percent/100)));	%* Proportion of Common Event;
	end;
	if _N_ = 2 then do;
		call symput ('VR', trim(left(&target)));		%* Value of Rare Event;
		call symput ('NR', trim(left(count)));			%* Count of Rare Event;
		call symput ('PR', trim(left(percent/100)));	%* Proportion of Rare Event;
	end;
run;

%* Check if the rates passed in RATES= are consistent with the Rare Event rate;
%* The RATES should be between 0 and 100, and one of them should be smaller than the
%* Rare Event rate and the other one should be larger. The latter condition guarantees that
%* the samprates for each target value are all valid sample rates (between 0 and 100);
%if not ((&prt > &PR and &prv < &PR) or (&prt < &PR and &prv > &PR)) %then %do;
	%put OVERSAMPLING: ERROR - The rate values passed in parameter RATES (%scan(&rates, 1, ' ')% %scan(&rates, 2, ' ')%) are not valid since;
	%put OVERSAMPLING: one should be larger and the other should be smaller than the Rare Event Rate.;
	%put OVERSAMPLING: (Rare Event: %upcase(&target)=&VR, Rate=%sysfunc(round(%sysevalf(&PR*100), 0.1))%);
%end;
%else %do;
	%if &log %then
		%put OVERSAMPLING: Partitioning input dataset into TRAINING and VALIDATION samples...;
	* N = Nro. of obs in pop;
	%Callmacro(getnobs, _OS_data_ return=1, N);
	* Sample Rate para Bad y para Good en el PROC SURVEYSELECT. Define el samprate a usar
	* para cada estrato, pues los estratos estan definidos por el valor de la varible target
	* (Bad o Good). O sea estos valores definen los porcentajes de Bad y de Good
	* que van a ir a parar a la muestra (por ej. si los samprates son 80% y 30% respectivamente,
	* quiere decir que el 80% de los Bad y el 30% de los Good van a ir a parar a la muestra);
	* Notar que: > BadSampRate 	=> 	> SampSize para TRAINING pero < % de Bad en VALIDATION;

	%let SampSize = %sysfunc(round(%sysevalf((1 - &prv)*&NR - &prv*&NC) / (&prt - &prv)));
	%let SampRateRare = %sysevalf((1 - &prv/&PR) / (1 - &prv/&prt) * 100);
	%let SampRateCommon = %sysevalf((&SampSize - &SampRateRare/100*&NR)/&NC * 100);
/*	%put PopSize=&N;*/
/*	%put SampSize=&SampSize;*/
/*	%put SampRateRare=&SampRateRare%;*/
/*	%put SampRateCommon =&SampRateCommon%;*/

	%* Sort by the the TARGET variable;
	proc sort data=_OS_data_(keep=_OS_obs_ &target) out=_OS_data_sorted_;
		by &target;
	run;
	%* Define the order of the samprates to use in the PROC SURVEYSELECT based on the target
	%* variable values. The samprates in the PROC SURVEYSELECT need to be in the same order as
	%* the order of the values of the target variable;
	data _NULL_;
		set _OS_data_sorted_(obs=1);
		call symput ('LowerEvent', trim(left(&target)));
	run;
	%if &LowerEvent = &VC %then
		%let samprates = &SampRateCommon &SampRateRare;	%* The lower value is the common event;
	%else %if &LowerEvent = &VR %then
		%let samprates = &SampRateRare &SampRateCommon;	%* The lower value is the rare event;
	%else
		%let samprates = ;

	%*** TRAINING SAMPLE;
	proc surveyselect 	data=_OS_data_sorted_
						out=_OS_train_
						samprate=(&samprates)
						seed=&seed
						noprint;
		strata &target;
	run;
	%*** VALIDATION SAMPLE;
	proc sort data=_OS_train_(keep=_OS_obs_ &target) out=_OS_train_(index=(_OS_obs_ / unique));
		by _OS_obs_;
	run;
	data _OS_valid_(index=(_OS_obs_ / unique));
		merge	_OS_data_(in=_in1_ keep=_OS_obs_ &target)
				_OS_train_(in=_in2_ keep=_OS_obs_);
		by _OS_obs_;
		if _in1_ and ~_in2_;
	run;

	%*** Put together the training and validation samples in the output dataset and add back
	%*** the original variables present in the input dataset;
	%* Compute the length of the values to be used for variable NAMESAMPLE;
	%let length1 = %length(%scan(&values, 1, ' '));
	%let length2 = %length(%scan(&values, 2, ' '));
	%let length = %sysfunc(max(&length1, &length2));
	data &out;
		%if %quote(&format) ~= %then %do;
		format &format;
		%end;
		length &namesample $&length;
		merge	_OS_data_(in=_in_data_)
				_OS_train_(in=_in_train_ keep=_OS_obs_)
				_OS_valid_(in=_in_valid_ keep=_OS_obs_);
		by _OS_obs_;
		if _in_data_;
		if _in_train_ then
			&namesample = "%scan(&values, 1, ' ')";
		else if _in_valid_ then
			&namesample = "%scan(&values, 2, ' ')";
		drop _OS_obs_;
	run;

	%if &log %then %do;
		%* Read sample sizes for TRAINING and VALIDATION;
		%Callmacro(getnobs, _OS_train_ return=1, ss_train);
		%Callmacro(getnobs, _OS_valid_ return=1, ss_valid);
		%put;
		%if %quote(%upcase(&out)) ~= %quote(%upcase(&data)) %then %do;
			%let out_name = %scan(&out, 1, '(');
			%put OVERSAMPLING: Output dataset %upcase(&out_name) created with the sampling partition;
			%put OVERSAMPLING: defined in variable %upcase(&namesample) (%upcase(%scan(&values, 1, ' ')) / %upcase(%scan(&values, 2, ' '))).;
		%end;
		%else %do;
			%put OVERSAMPLING: Input dataset updated with variable %upcase(&namesample) defining the sample partitions:;
			%put OVERSAMPLING: %upcase(%scan(&values, 1, ' ')) / %upcase(%scan(&values, 2, ' ')).;
		%end;
		%put OVERSAMPLING: Sampling sizes and sampling rates for the Rare Event (%upcase(&target)=&VR) are:;
		%put OVERSAMPLING: %upcase(%scan(&values, 1, ' ')): &ss_train obs, %scan(&rates, 1, ' ')%;
		%put OVERSAMPLING: %upcase(%scan(&values, 2, ' ')): &ss_valid obs, %scan(&rates, 2, ' ')%;
	%end;

%end;	%* if the rates passed in RATES= are valid w.r.t. the rare event rate;
%end;	%* if the rates passed in RATES= are between 0 and 100;
%end;	%* if &nobs ~= 2;

proc datasets nolist;
	delete 	_OS_data_
			_OS_data_sorted_
			_OS_train_
			_OS_valid_;
quit;

%if &log %then %do;
	%put;
	%put OVERSAMPLING: Macro ends;
	%put;
%end;

%ResetSASOptions;
%MEND Oversampling;
