/* AddLabels.sas
Created:		07-Aug-2015
Modified:		07-Aug-2015
Author:			Daniel Mastropietro
Description:	Adds the labels to a dataset containing summary information about variables in another dataset,
				one row per variable.
				By default a new column called LABEL is added to the dataset after the variable named 'var'.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %GetVarOrder
- %InsertInList
- %ResetSASOptions
- %SetSASOptions
*/

%MACRO AddLabels(data, datalabel, label=label, var=var, log=1) / store des="Adds labels to variables listed in a summary dataset";
%local fLabels;
%local order;

%SetSASOptions(varlenchk=NOWARN);

%if &log %then %do;
	%put;
	%put ADDLABELS: Macro starts;
	%put;
%end;


%* Labels in the DATALABEL dataset and create index, rename the variable name column to &VAR and create an index on it
%* in order to avoid sorting the input dataset;
proc contents data=&datalabel out=_AL_pc_(keep=name label rename=(name=&var label=&label) index=(&var)) noprint;
run;

%* Check if at least one variable has labels so that the column is not added if no variable has labels;
%let fLabels = 0;
data _NULL_;
	set _AL_pc_ end=lastobs;
	retain maxlength 0;
	maxlength = max(maxlength, lengthn(label));
	if lastobs and maxlength > 0 then
		call symput('fLabels', 1);
run;

%* Only add the LABEL column if at least one variable has labels;
%if &fLabels %then %do;
	%let order = %GetVarNames(&data);
	%let order = %InsertInList(&order, &label, after, &var);
	data &data;
		format &order;
		set &data;
		set _AL_pc_ key=&var / unique;
		if _IORC_ then _ERROR_ = 0;
	run;
	%if &log %then
		%put ADDLABELS: Labels have been added to dataset %upcase(&data) on variable %upcase(&label).;
%end;
%else %if &log %then
	%put ADDLABELS: No labels found in dataset %upcase(&datalabels).;

%if &log %then %do;
	%put;
	%put ADDLABELS: Macro ends;
	%put;
%end;

%ResetSASOptions;

%MEND AddLabels;
