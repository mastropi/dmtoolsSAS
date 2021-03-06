%* MACRO %ExectTimeStart;
%* Created: 01-Sep-2015;
%* Modified: 28-Jun-2019;
%* Author: Daniel Mastropietro;
%* Start measuring the execution time;
%* If the _MACRO_CALL_LEVEL_MACRO_ does not exist, it returnes the current DATETIME();
%* Ref: http://www.sascommunity.org/wiki/Tips:Program_run_time;
%* SEE ALSO:
%* - %ExecTimeStop
%* - %SetSASOptions
%* - %ResetSASOptions;
%MACRO ExecTimeStart(maxlevel=1) / des="Starts the clock to measure execution time of a macro";
%* Store the maximum macro level for which execution time should be reported;
%if ~%ExistMacroVar(_Macro_Call_Level_Report_Max_) %then %do;
	%global _Macro_Call_Level_Report_Max_;
	%let _Macro_Call_Level_Report_Max_ = &maxlevel;
%end;
%* Mesure the execution time for the outer-most macro being executed;
%* The macro variable _Macro_Call_Level_ is handled by %SetSASOptions and %ResetSASOptions;
%if %ExistMacroVar(_Macro_Call_Level_) %then %do;
	%if &_Macro_Call_Level_ <= &_Macro_Call_Level_Report_Max_ %then %do;
		%global _datetime_start_&_Macro_Call_Level_;
		%let _datetime_start_&_Macro_Call_Level_ = %sysfunc(DATETIME());
	%end;
%end;
%else
	%sysfunc(DATETIME())
%MEND ExecTimeStart;
