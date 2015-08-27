/* MACRO %IsNumber
Version: 1.01
Author: Daniel Mastropietro
Created: 23-Dec-04
Modified: 10-Mar-05

DESCRIPTION:
This macro states whether a string is a number or not.
The macro returns 1 if it is a number and 0 otherwise.
However the macro does not check for consistency of the number. In fact the only thing that the
macro does is stating that all the characters that make up the string are digits or the following
symbols: '.', '+', '-'.

USAGE:
%IsNumber(str);

REQUIRED PARAMETERS:
- str:		String to analyze.

OTHER MACROS AND MODULES USED IN THIS MACRO:
None

EXAMPLES:
1.- %let number = %IsNumber(3.235);
Stores the value 1 in macro variable 'isnumber'.

2.- %let number = %IsNumber(3.2+38..47-287.429);
Stores the value 1 in macro variable 'isnumber'.
(Even if the string is NOT actually a number!)

3.- %let number = %IsNumber(3s3874-3);
Sotres the value 0 in macro variable 'isnumber'.
*/
&rsubmit;
%MACRO IsNumber(str) / store des="Returns 1 if a string seems to be a number, 0 otherwise";
%local char i IsNumber length;

%let length = %length(&str);
%let IsNumber = 1;
%let i = 0;
%do %while(&i < &length and &IsNumber);
	%let i = %eval(&i + 1);
	%let char = %substr(&str, &i, 1);
	%* Note below the use of quotation marks to enclose &char. This is necessary to avoid
	%* an error when the character is a symbol like -, +, etc.;
	%if "&char" ~= "0" and
		"&char" ~= "1" and
		"&char" ~= "2" and
		"&char" ~= "3" and
		"&char" ~= "4" and
		"&char" ~= "5" and
		"&char" ~= "6" and
		"&char" ~= "7" and
		"&char" ~= "8" and
		"&char" ~= "9" and
		"&char" ~= "." and
		"&char" ~= "-" and
		"&char" ~= "+" and
		"&char" ~= "*" and
		"&char" ~= "/" and
		%upcase("&char") ~= "E" %then
		%let IsNumber = 0;
%end;
&IsNumber
%MEND IsNumber;
