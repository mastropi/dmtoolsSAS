/* MACRO %Compute
Version: 1.00
Author: Daniel Mastropietro
Created: 29-Sep-04
Modified: 29-Sep-04

DESCRIPTION:
This macro simply evaluates a given function that can accept more than one argument separated
by commas. (e.g. max, min, sum, etc.)
The macro was created in order to force the evaluation of such functions, prior to input
to another macro. See section EXAMPLES below.

USAGE:
%Compute(func, arg);

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %EvalExp

SEE ALSO:
- %EvalExp

EXAMPLES:
1.-
%let max = %Compute(max, %quote(3 , 5.2 , 4.8));

This is equivalent to:
%let max = %sysfunc(max(3, 5.2, 4.8));

2.-
%let list = %nrstr(&x1 , &x2 , &x3);
%let max = %Compute(max, %quote(&list));

(The following:
%let max = %sysfunc(max(&list));
does not work, because the macro variables &x1, &x2, &x3 are not resolved to numbers.)

3.-
%let max = %Compute(max, %MakeList(fit1 fit3, prefix=&, suffix=_max, sep=%quote(,)));
*/
&rsubmit;
%MACRO Compute(func, arg) / store des="Returns the value of a function evaluation";
%sysfunc(&func(%EvalExp(&arg))))
%MEND Compute;
