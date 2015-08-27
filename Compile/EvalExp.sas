/* MACRO %EvalExp
Version: 1.00
Author: Daniel Mastropietro
Created: 29-Sep-04
Modified: 29-Sep-04

DESCRIPTION:
This macro evaluates (or resolves) an expression by calling the function COMPBL at the
macro level (via %sysfunc). That is, it simply does the following:

%sysfunc(compbl(&exp));

where &exp is the expression to evaluate.

This macro was created because there is no macro function to force the evaluation of an
expression at the macro level when the expression is not an mathematical operation.
(For the evaluation of such expressions there exist %eval and %sysevalf.)

USAGE:
%EvalExp(exp);

OTHER MACROS AND MODULES USED IN THIS MACRO:
None

SEE ALSO:
- %Compute

EXAMPLES:
1.- 
%let list = %nrstr(&x1, &x2);
%let mean = %sysfunc(mean(%EvalExp(&list)));

(Using
%let mean = %sysfunc(mean(&list));
DOES NOT WORK(!!!) because the expression contained in &list is not resolved
prior to the execution of MEAN, and the function MEAN requires numeric arguments.)

APPLICATIONS:
It is useful to evaluate an expression or the result of a macro call prior to the evaluation
of another function.
Ex:
%let max = %sysfunc(max(%EvalExp(%MakeList(x1 x2 x3, prefix=&, sep=%quote(,)))));

This computes the maximum among the macro variables &x1, &x2 and &x3.
If %EvalExp is not used, the execution of function MAX gives the following error:
"ERROR: The function MAX referenced by the %SYSFUNC or %QSYSFUNC macro function has too few
       arguments."
and this is because the result of the call to %MakeList is not resolved prior to the
call to function MAX.
*/
&rsubmit;
%MACRO EvalExp(exp) / store des="Evaluates an expression and removes multiple blanks";
%sysfunc(compbl(&exp))
%MEND EvalExp;

