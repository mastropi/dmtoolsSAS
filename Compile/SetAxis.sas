/* MACRO %SetAxis
Version: 1.00
Author: Daniel Mastropietro
Created: 29-Sep-04
Modified: 29-Sep-04

DESCRIPTION:
This macro returns the string to define an axis limits, as in a haxis= or vaxis=
option or in an order=() option of an axis statement.

USAGE:
%SetAxis(min, max, nrodiv);

REQUIRED PARAMETERS:
- min:				Minimum number for the axis.

- max:				Maximum number for the axis.

- nrodiv:			Number of divisions to use in the axis (= #ticks - 1).

NOTES:
- The values passed in MIN= and MAX= are 'prettysized' with the macro %Pretty, so that
"round" numbers are shown in the axis.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Pretty

SEE ALSO:
- %SymmetricAxis

EXAMPLES:
1.- 
axis1 order=(%SetAxis(0, 2.34, 10));

2.-
%GetStat(test, var=y z, stat=min);
%GetStat(test, var=y z, stat=max);
%let min = %sysfunc(min(&y_min,&z_min));
%let max = %sysfunc(max(&y_max,&z_max));
proc gplot data=test;
	plot y*x z*x / vaxis=%SetAxis(&min, &max, 10);
run;
quit;
*/
&rsubmit;
%MACRO SetAxis(min, max, nrodiv) / store des="Returns the axis statement necessary to create an axis with a specified number of ticks";
%local round_min round_max step;

%let round_min = ;
%let round_max = ;
%* Define whether the rounding of the minimum and maximum numbers should be
%* UPWARDS (i.e. towards +Inf) or DOWNWARDS (i.e. towards -Inf);
%* By default, it is assumed that the minimum number is negative and the maximum number
%* is positive. If any of these is not true, the default rounding must be changed, as follows:
%* - If the minimum number is positive, rounding of the minimum should occur DOWNWARDS.
%* - If the maximum number is negative, rounding of the maximum should occur UPWARDS.
%* If this is not done like this, it may occur that either the minimum or the maximum number
%* is left out of the plot done using the axis statement returned by this macro;
%if %sysevalf(&min > 0) %then
	%let round_min = DOWN;
%if %sysevalf(&max < 0) %then
	%let round_max = UP;
	
%let min = %Pretty(&min, round=&round_min);
%let max = %Pretty(&max, round=&round_max);
%let step = %sysevalf((&max - &min)/&nrodiv);
&min to &max by &step
%MEND SetAxis;
