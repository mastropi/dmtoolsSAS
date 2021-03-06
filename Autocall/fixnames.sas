/* MACRO %FixNames
Version: 1.00
Author: Daniel Mastropietro
Created: 11-Jul-05
Modified: 4-Oct-05

DESCRIPTION:
This macro fixes the names generated by the LOGISTIC procedure using the ODS OUTPUT
statement with ParameterEsimates option.
It may be used for other procedures too but it was not tested.

USAGE:
%FixNames(
	data,			*** Dataset containing the column with the names to be fixed.
	params=,		*** Name of dataset containing the parameter estimates.
	var=variable,	*** Name of the column in dataset DATA containing the variable names
						to be fixed.
	type=PARAMS,	*** Type of table to fix: PARAMS or TYPEIII.
	out=,			*** Output dataset.
	log=1);			*** Show messages in the log?

REQUIRED PARAMETERS:
- data:			Input dataset. Data options can be specified as in a data= SAS option.

- params:		Dataset containing the model parameter estimates. This dataset must
				have only one row and be of type PARMS. It is typically generated
				by an OUTEST= option of the procedure statement of the procedure used
				to generate the model. So far this macro was teste with the LOGISTIC
				PROCEDURE.

OPTIONAL PARAMETERS:
- type:			Type of table to fix.
				Possible values:
				- PARAMS: for the dataset generated by the ParameterEstimate= option
				of the ODS OUTPUT statement in PROC LOGISTIC.
				- TYPEIII: for the dataset generated by the TypeIII= option
				of the ODS OUTPUT statement in PROC LOGISTIC.
				The difference between these 2 options is that type PARAMS may have
				more than one entry per variable (if the variable is categorical with
				more than 2 levels), whereas type TYPEIII has always one entry per
				variable.
				default: PARAMS
				
- out:			Output dataset with the variable names contained in column VAR= fixed.
				If nothing is passed, the input dataset is updated.
				NO data options can be specified.

- log:			Whether to show messages in the log.
				Possible values: 0 => No, 1 => Yes
				default: 1

NOTES:
1.- ASSUMPTIONS
It is assumed that when the model was created, the option LABEL was set to 'LABEL' and
the label of each variable is the same as the variable name. Otherwise, this macro
may not work properly.
(This is required, because the recovery of the full variable names is done via their
labels.)

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %GetRegVarList
- %ResetSASOptions
- %SetSASOptions
*/
%MACRO FixNames(data, var=variable, params=, type=PARAMS, out=, log=1)
		/ des="Restores the variable names stored in the ODS ParameterEstimates output created by a logistic regression";
%local label;

%SetSASOptions;

%if &log %then %do;
	%put;
	%put FIXNAMES: Macro starts;
	%put;
%end;

/*----- Parse input parameters -----*/
%*** OUT=;
%if %quote(&out) = %then
	%let out = &data;
/*----------------------------------*/

%GetRegVarList(&params, out=_FixNames_regvar_, log=0);
%* Read label of dataset so that it is not removed;
proc contents data=&data out=_FixNames_pc_(keep=MEMLABEL) noprint;
run;
data _NULL_;
	set _FixNames_pc_(obs=1);
	call symput ('label', memlabel);
run;
%if %upcase(&type) = PARAMS %then %do;
	data _FixNames_data_;
		set &data;
		obs = _N_ - 1;	%* _N_ - 1 because the first parameter corresponds to the Intercept;
	run;
	data &out(label="&label");
		format var;
		merge 	_FixNames_data_(in=in1)
				_FixNames_regvar_(in=in2);
		by obs;
		if var = "" then var = "Intercept";
		drop obs &var;
	run;
	%if &log %then
		%put FIXNAMES: Dataset %upcase(&out) updated with full variable names.;
%end;
%else %if %upcase(&type) = TYPEIII %then %do;
	%* Dedup of variables in _FixNames_regvar_;
	proc sort data=_FixNames_regvar_ out=_FixNames_regvar_nodup_ nodupkey;
		by var;
	run;
	%* Re-sort by OBS;
	proc sort data=_FixNames_regvar_nodup_;
		by obs;
	run;
	%* Re-assigne variable OBS in the _REGVAR_NODUP_ dataset in order to have
	%* consecutive values of OBS, and add variable OBS in the &data in
	%* order to merge with dataset _FIXNAMES_REGVAR_NODUP_, and get the variable full
	%* names;
	data _FixNames_regvar_nodup_;
		set _FixNames_regvar_nodup_;
		obs = _N_;
	run;
	data _FixNames_data_;
		set &data;
		obs = _N_;
	run;
	data &out(label="&label");
		format var;
		merge 	_FixNames_data_(in=in1)
				_FixNames_regvar_nodup_(in=in2);
		by obs;
		drop obs &var;
	run;
	%if &log %then
		%put FIXNAMES: Dataset %upcase(&out) updated with full variable names.;
%end;
%else
	%put FIXNAMES: ERROR - Parameter TYPE (= &type) is invalid. Valid values are PARAMS or TYPEIII.;

proc datasets nolist;
	delete 	_FixNames_data_
			_FixNames_regvar_
			_FixNames_regvar_nodup_
			_FixNames_pc_;
quit;

%if &log %then %do;
	%put;
	%put FIXNAMES: Macro ends;
	%put;
%end;

%ReSetSASOptions;
%MEND FixNames;
