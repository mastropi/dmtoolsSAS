/* MACRO %Colors
Version: 1.00
Author: Daniel Mastropietro
Created: 25-Sep-04
Modified: 23-Nov-04

DESCRIPTION:
Returns a macro variable with a list of colors. The number of colors to put
in the list can be passed as a parameter.
The first 10 colors in the list are different, and then the colors are cycled.

USAGE:
%Colors(n=10);

REQUIRED PARAMETERS:
None

OPTIONAL PARAMETERS:
n:			Number of colors requested.
			default: 10

SEE ALSO:
- %DefineSymbols
*/
%MACRO Colors(n=10) / des="Returns a list of color names";
%local i colors colorList;
%let colorList = blue red green cyan violet yellow olive gray o salmon;
%if &n > 10 %then
	%do i = 1 %to %sysfunc(floor(%sysevalf(&n/10)));
		%let colorList = &colorList &colors;
	%end;
&colorList
%MEND Colors;
