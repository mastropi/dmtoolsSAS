%* MACRO %ExectTimeStop;
%* Created: 01-Sep-2015;
%* Author: Daniel Mastropietro;
%* Start measuring the execution time;
%* Ref: http://www.sascommunity.org/wiki/Tips:Program_run_time;
%* SEE ALSO:
%* - %ExecTimeStop
%* - %SetSASOptions
%* - %ResetSASOptions;
%MACRO ExecTimeStart / store des="Starts the clock to measure execution time of a macro";
%* Mesure the execution time for the outer-most macro being executed;
%* The macro variable _Macro_Call_Level_ is handled by %SetSASOptions and %ResetSASOptions;
%if %ExistMacroVar(_Macro_Call_Level_) %then
	%if &_Macro_Call_Level_ = 1 %then %do;
		%global _datetime_start_;
		%let _datetime_start_ = %sysfunc(DATETIME());
	%end;
%MEND ExecTimeStart;
