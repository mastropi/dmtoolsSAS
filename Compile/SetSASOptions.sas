/* MACRO %SetSASOptions
Sets a few of current SAS options after reading their current value, so that they can be reset by
%ResetSASOptions.

Note that macro variables are defined here as global macro variables. The reason for doing this is
to avoid having to change each macro that calls %SetSASOptions whenever a new option wants to be set.

Note also the use of the global macro variable &_Macro_Call_Level_. This macro variable contains the value
of the call level at which the macro call to %SetSASOptions is performed. For example, if macro %A calls
macro %B, and both macro %A and macro %B call %SetSASOptions, then &_Macro_Call_Level_ is set to 1,
when %SetSASOptions is called from macro %A, whereas all subsequent calls to %SetSASOptions increase
the value of &_Macro_Call_Level_ by 1. The options are only set at the first call to %SetSASOptions,
otherwise the current settings would be overriden in subsequents calls to %SetSASOptions.
The value of &_Macro_Call_Level_ is decreased by %ResetSASOptions, whenever this macro is being called, first
by %B and then by %A. When %ResetSASOptions is called at the last level, macro variable _Macro_Call_Level_
is deleted.

%SetSASOptinos is used by different macros, for example for setting the value of the nonotes option, to
avoid showing SAS messages in the log.

OTHER MACROS USED IN THIS MACRO:
- %ExistMacroVar

HISTORY:
- 2015/09/02: Added VARLENCHK= parameter to set the VARLENCHK= option.
*/
&rsubmit;
%MACRO SetSASOptions(notes=0, labels=1, varlenchk=warn) / store des="Sets SAS options prior to a macro execution";
%*Setting nonotes options and getting current options settings;
%if ~%ExistMacroVar(_Macro_Call_Level_) %then %do;
	%global _Macro_Call_Level_ _notes_option_ _label_option_ _lastds_ _varlenchk_option_;
	%let _Macro_Call_Level_ = 1;

	%* SAS notes settings;
	%let _notes_option_ = %sysfunc(getoption(notes));
	%if &notes %then %do;
	options notes;
	%end;
	%else %do;
	options nonotes;
	%end;

	%* Allow labels;
	%let _label_option_ = %sysfunc(getoption(label));
	%* options label is to allow the creation of labels in datasets, regardless
	%* of the current setting of the option.
	%* Note that it is not advisable to set the options label just before the
	%* label statement is used in a dataset and then reset it to its original
	%* value, because any other data steps that involve the given dataset will
	%* not carry over the created labels if the options nolabel is set.
	%* That is why it is necessary to set the options label here, so that it
	%* is valid throughout all the execution of the macro.;
	%if &labels %then %do;
	options label;
	%end;
	%else %do;
	options nolabels;
	%end;

	%* VARLENCHECK option: NOWARN, WARN or ERROR when the length of a variable is shortened;
	%let _varlenchk_option_ = %sysfunc(getoption(varlenchk));
	options varlenchk=&varlenchk;

	%* Name of the last dataset used;
	%let _lastds_=&syslast;
%end;
%else
	%let _Macro_Call_Level_ = %eval(&_Macro_Call_Level_ + 1);
%MEND SetSASOptions;
