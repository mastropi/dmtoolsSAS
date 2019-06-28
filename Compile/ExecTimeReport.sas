/* 09-Aug-2016
Reports the time elapsed since a specified datetime value.

Ex:
%let time_start = %sysfunc(DATETIME());
%ExecTimeReport(&time_start);
*/
&rsubmit;
%MACRO ExecTimeReport(datetime_start) / store des="Reports the elapsed time in a human format";
%local _diff_time_;
%let _datetime_end_ = %sysfunc(DATETIME());

%put;	%* Leave space from whatever comes above in the log;

%put *** START TIME: %quote(   %sysfunc(putn(&datetime_start, datetime20.)));
%put *** END TIME: %quote(     %sysfunc(datetime(), datetime20.));
%let _diff_time_ = %sysevalf(&_datetime_end_ - &datetime_start);
%* Need to round &_DIFF_TIME_ in order to convert the macro variable into a number;
%* Otherwise, the comparison is performed on the characters making up the macro variable value!;
%if %sysfunc(round(&_diff_time_, 1)) < 60 %then
	%put *** EXECUTION TIME:%sysfunc(putn(&_diff_time_, 4.0)) sec;
%else
	%put *** EXECUTION TIME: %sysfunc(putn(%sysevalf(&_datetime_end_ - &datetime_start), hhmm8.2)) (hh:mm);

%put;	%* Leave space after;

%MEND ExecTimeReport;


