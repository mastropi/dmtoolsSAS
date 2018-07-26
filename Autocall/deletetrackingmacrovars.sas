/* MACRO %DeleteTrackingMacroVars
Version:	1.0
Author:		Daniel Mastropietro
Created:	12-Feb-2016
Modified:	12-Feb-2016

DESCRIPTION:
Deletes the global macro variables that are used by the macro system to keep track of macro execution,
such as _MACRO_CALL_LEVEL_, _datetime_start_.

REQUIRED PARAMETERS:
None.
*/
%MACRO DeleteTrackingMacroVars() / des="Deletes the global macro variables that keep track of macro execution";
%if %symexist(_MACRO_CALL_LEVEL_) %then
	%symdel _MACRO_CALL_LEVEL_;
%if %symexist(_datetime_start_) %then
	%symdel _datetime_start_;
%MEND DeleteTrackingMacroVars;
