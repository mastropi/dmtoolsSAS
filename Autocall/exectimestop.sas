%* MACRO %ExectTimeStop;
%* Created: 01-Sep-2015;
%* Modified: 28-Jun-2018;
%* Author: Daniel Mastropietro;
%* Stop measuring the execution time and show it in the log;
%* The maximum macro call level at which the execution time is reported is set by the macro %ExecTimeStart();
%* Ref: http://www.sascommunity.org/wiki/Tips:Program_run_time;
%* SEE ALSO:
%* - %ExecTimeStart
%* - %SetSASOptions
%* - %ResetSASOptions;
%MACRO ExecTimeStop() / des="Measures the time elapsed since %ExecTimeStart was last called";
%local _datetime_end_;
%local _diff_time_;
%* Show the execution time for the outer-most macro being executed;
%* The macro variable _Macro_Call_Level_ is handled by %SetSASOptions and %ResetSASOptions;
%if %ExistMacroVar(_Macro_Call_Level_) %then %do;
	%if &_Macro_Call_Level_ <= &_Macro_Call_Level_Report_Max_ %then %do;	%* This check should go on a separate line because if _Macro_Call_Level_ does not exist, the above IF gives an error;
		%put;		%* Leave a blank line w.r.t. the previous time report;
		%if %ExistMacroVar(_datetime_start_&_Macro_Call_Level_) %then %do;
			%let _datetime_end_ = %sysfunc(DATETIME());
			%put *** START TIME: %quote(   %sysfunc(putn(&&_datetime_start_&_Macro_Call_Level_, datetime20.)));
			%put *** END TIME: %quote(     %sysfunc(datetime(), datetime20.));
			%let _diff_time_ = %sysevalf(&_datetime_end_ - &&_datetime_start_&_Macro_Call_Level_);
			%* Need to round &_DIFF_TIME_ in order to convert the macro variable into a number;
			%* Otherwise, the comparison is performed on the characters making up the macro variable value!;
			%if %sysfunc(round(&_diff_time_, 1)) < 60 %then
				%put *** EXECUTION TIME:%sysfunc(putn(&_diff_time_, 4.0)) sec;
			%else
				%put *** EXECUTION TIME: %sysfunc(putn(%sysevalf(&_datetime_end_ - &&_datetime_start_&_Macro_Call_Level_), hhmm8.2)) (hh:mm);
			%* Delete the global macro variable created by %ExecTimeStart;
			%symdel _datetime_start_&_Macro_Call_Level_;
		%end;
		%else %do;
			%put Unable to measure execution time...;
		%end;
	%end;
	%if &_Macro_Call_Level_ = 1 %then
		%* We have reached macro call level = 1 => the outermost macro has ended execution and we need to delete the global macro variable _Macro_Call_Level_Report_Max_;
		%symdel _Macro_Call_Level_Report_Max_;
%end;
%MEND ExecTimeStop;
