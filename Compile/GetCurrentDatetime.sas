/* MACRO %GetCurrentDatetime
Version: 		1.00
Author: 		Daniel Mastropietro
Created: 		29-Nov-2018
Modified: 		29-Nov-2018
SAS Version:	9.4

DESCRIPTION:
Returns the current datetime using the B8601DT15. format, i.e.as yyyymmddThhmmss.

USAGE:
%GetCurrentDatetime

EXAMPLES:
%let datetime = %GetCurrentDatetime;
*/
&rsubmit;
%MACRO GetCurrentDatetime / store des="Returns the current datetime value";
%TRIM(%SYSFUNC(DATETIME(), B8601DT15.))
%MEND GetCurrentDatetime;
