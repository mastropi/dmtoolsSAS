%* MACRO %ExectTimeStop;
%* Created: 01-Sep-2015;
%* Author: Daniel Mastropietro;
%* Stop measuring the execution time and show it in the log;
%* Ref: http://www.sascommunity.org/wiki/Tips:Program_run_time;
%* SEE ALSO:
%* - %ExecTimeStart
%* - %SetSASOptions
%* - %ResetSASOptions;
%MACRO ExecTimeStop / store des="Measures the time elapsed since %ExecTimeStart was last called";
%local _datetime_end_;
%local _diff_time_;
%* Show the execution time for the outer-most macro being executed;
%* The macro variable _Macro_Call_Level_ is handled by %SetSASOptions and %ResetSASOptions;
%if %ExistMacroVar(_Macro_Call_Level_) %then
	%if &_Macro_Call_Level_ = 1 %then %do;	%* This check should go on a separate line because if _Macro_Call_Level_ does not exist, the above IF gives an error;
		%if %ExistMacroVar(_datetime_start_) %then %do;
			%let _datetime_end_ = %sysfunc(DATETIME());
			%put *** START TIME: %quote(   %sysfunc(putn(&_datetime_start_, datetime20.)));
			%put *** END TIME: %quote(     %sysfunc(datetime(), datetime20.));
			%let _diff_time_ = %sysevalf(&_datetime_end_ - &_datetime_start_);
			%* Need to round &_DIFF_TIME_ in order to convert the macro variable into a number;
			%* Otherwise, the comparison is performed on the characters making up the macro variable value!;
			%if %sysfunc(round(&_diff_time_, 1)) < 60 %then
				%put *** EXECUTION TIME:%sysfunc(putn(&_diff_time_, 4.0)) sec;
			%else
				%put *** EXECUTION TIME: %sysfunc(putn(%sysevalf(&_datetime_end_ - &_datetime_start_), hhmm8.2)) (hh:mm);
			%* Delete the global macro variable created by %ExecTimeStart;
			%symdel _datetime_start_;
		%end;
	%end;
	%else %do;
		%put Unable to measure execution time...;
	%end;
%MEND ExecTimeStop;
