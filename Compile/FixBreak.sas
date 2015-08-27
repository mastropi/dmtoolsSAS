/* 18/3/05
This macro fixes the problem of the macro variable _MACRO_CALL_LEVEL_ not being deleted and
the options notes set to NONOTES when a macro is interrupted.
*/
&rsubmit;
%MACRO FixBreak / store des="Restores settings after a macro execution is interrupted";
%symdel _MACRO_CALL_LEVEL_;
options notes;
%MEND FixBreak;
