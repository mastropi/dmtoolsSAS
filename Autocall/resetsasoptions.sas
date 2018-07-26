/* %MACRO ResetSASOptions
Resets a few SAS options with the value read in %SetSASOptions.

It is assumed that all macro variables referenced here exist as global macro variables, and are defined
in %SetSASOptions.
See more comments about the macro variables being used in %SetSASOptions.
This macro is used by different macros, for example for resetting the value of the nonotes option.

OTHER MACROS USED IN THIS MACRO:
- %ExistMacroVar

HISTORY:
- 2015/09/02: Added a reset of the VARLENCHK= option set by %SetSASOptions.
*/
%MACRO ResetSASOptions / des="Resets SAS options after a macro execution";
%if %ExistMacroVar(_Macro_Call_Level_) %then %do;
	%let _Macro_Call_Level_ = %eval(&_Macro_Call_Level_ - 1);
	%if &_Macro_Call_Level_ = 0 %then %do;
		options &_notes_option_ &_label_option_ varlenchk=&_varlenchk_option_ _last_=&_lastds_;
		%symdel _Macro_Call_Level_ _notes_option_ _lastds_ _label_option_ _varlenchk_option_;
		quit;		%* This is to avoid problems with %symdel. Sometimes, the statements that come right after
					%* %symdel are not executed!! (I already reported this problem to SAS);
	%end;
%end;
%MEND ResetSASOptions;
