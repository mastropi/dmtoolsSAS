/* MACRO %Pretty
Version: 1.02
Author: Daniel Mastropietro
Created: 11-Jul-03
Modified: 5-Jan-05

This macro rounds a number to the closest number, where closest depends on the magnitude
of the absolute value, being proportional to 1/10th of its first significant value (1/10th
is the default and can be adjusted with parameter ROUNDOFF=. For ex. if ROUNDOFF=0.001, then
the 1/10th changes to 1/1000th).
For ex., if x = 0.374, then  the closest number downwards would be 0.37 and the closest
number upwards would be 0.38. If x = 37.4, the respective closest numbers are 37 and 38.

By default, a positive number is rounded upwards and a negative number is rounded downwards.
This comes from assuming that this macro is commonly used to round the minimum and maximum
numbers of a plotting variable and that the number 0 is in between the minimum and the maximum.
For ex. a plot for which the values in the vertical axis variable run from -3.231 to 2.8374.
If the number is 0, 0 is returned.

The upwards and downwards default rounding can be changed with parameter ROUND=, which should
be equal to UP to force an upwards rounding and equal to DOWN to force a donwards rounding.
*/

/* PENDIENTE:
- 23/10/04: Arreglar el rounding de los numeros cuyo primer numero significativo es > 5, porque
actualmente no redondea al numero mas proximo que esta' a una distancia de 1/10 del primer numero
significativo sino que redondea al numero mas proximo que esta' a una distancia de 1 en el
primer numero significativo.
Por ej., el numero 0.8354 se redondeda a 0.9 en lugar de redondearse a 0.84.
- 5/1/05: Hay que modificar la forma de calcular la macro variable &exp en lo que respecta a la
resta de la cantidad log10(1.5). No me acuerdo bien de donde sale esta cantidad, pero funciona
aparentemente bien cuando roundoff=0.1, pero no del todo bien cuando el roundoff es mas chico.
Por ejemplo, si uso %Pretty(0.37361, 0.001) devuelve 0.3737 en lugar de 0.3736.
*/
%MACRO Pretty(x, round=, roundoff=0.1)
		/ des="Rounds a number according to its significance digits and its sign";
%local exp sign up;

%if %sysevalf(&x ~= 0) %then %do;		%* otherwise, if x = 0, do nothing;
	%let sign = %sysfunc(sign(&x));
	%* The macro variable &exp defines the exponent q in 10^q that determines the decimal
	%* place at which the rounding occurs.
	%* For ex.:
	%* - &exp = -2 means that the rounding will occur at the second decimal,
	%* - &exp = 2 means that the rounding will occur at the 100th position
	%* (e.g. 1253.32 will become 1300);
	%let exp = %sysfunc(round( %sysfunc(log10(%sysevalf(&sign*&x*&roundoff))) - %sysfunc(log10(1.5)) ));	
	%** The log10(1.5) is used to have the log10 of values smaller than 3.5 (for example) be rounded
	%** to the log10(3), and the values larger than 3.5 be rounded to log10(4). Otherwise the
	%** cutoff for the rounding function is the 0.5 cutoff applied to the log10, not to the original
	%** number;
	%** (5/1/05) Ver tambien nota arriba en PENDIENTE, con fecha 5/1/05;

	%if %quote(&round) = %then %do;
		%* Positive numbers are rounded upwards;
		%* (Note the use of %sysevalf to evaluate the comparison, this is because a negative
		%* sign can cause an error!!!!!!!!!!!!!!!!!!!!!!!);
		%if %sysevalf(&x > 0) %then
			%let up = 1;
		%* Negative numbers are rounded downards;
		%* (Note the use of %sysevalf to evaluate the comparison, this is because a negative
		%* sign can cause an error!!!!!!!!!!!!!!!!!!!!!!!);
		%else %if %sysevalf(&x < 0) %then
			%let up = -1;
	%end;
	%else %if %upcase(%quote(&round)) = UP %then
		%let up = 1;
	%else
		%let up = -1;

	%* Round number x;
	%let x = %sysevalf( &up*%sysfunc(ceil( %sysevalf(&up*&x*10**(-&exp)) )) * 10**&exp);
	%** The use of ceil below, instead of round, is important to attain the desired result
	%** (the reasoning is too difficult to explain...);
	%** Ex:
	%** If &x = -0.3345 and &up = 1, then:
	%** &exp = -2
	%** &up*&x*10**(-&exp) = -33.45
	%** ceil(&up*&x*10**(-&exp)) = -33
	%** x (rounded) = -0.33;
%end;

&x
%MEND Pretty;
