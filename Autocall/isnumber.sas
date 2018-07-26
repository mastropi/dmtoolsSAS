/* MACRO %IsNumber
Version: 	1.02
Author: 	Daniel Mastropietro
Created: 	23-Dec-2004
Modified: 	31-Mar-2016 (previous: 10-Mar-2005)

DESCRIPTION:
This macro states whether a string looks like a number or optionally a SET of numbers.
The macro just says whether the string "looks like" a number and doesn't really verify that it is
a number as it doesn't check for consistency of the number(s).
The only thing that the macro does is to check wheter all the characters that make up the string
are digits or any of the following symbols: ' ', '.', '+', '-', '*', '/', 'E', 'e'
(for numbers in exponential notation).

USAGE:
%IsNumber(str, multiple=0, sep=%quote( ));

REQUIRED PARAMETERS:
- str:		String to analyze.

OPTIONAL PARAMETERS:
- multiple:	Flag indicating whether multiple numbers separated by 'sep' are allowed
			in the string to be considered a valid number or set of numbers.
			Possible values: 0 => No, 1 => Yes
			default: 0

- sep:		Single character separating the plausible numbers in 'str'.
			default: %quote( ) (i.e. a blank space)

RETURNED VALUE:
The macro returns 1 if the input string looks like a number or a set of numbers and 0 otherwise.

OTHER MACROS AND MODULES USED IN THIS MACRO:
None

EXAMPLES:
1.- %let number = %IsNumber(3.235);
Stores the value 1 in macro variable 'isnumber'.

2.- %let number = %IsNumber(3.2+38..47-287.429);
Stores the value 1 in macro variable 'isnumber'.
(Even if the string is NOT actually a number!)

3.- %let number = %IsNumber(3s3874-3);
Stores the value 0 in macro variable 'isnumber'.

4.- %let number = %IsNumber(0.3 | 1e-5 |-0.8, multiple=1, sep=|)
Stores the value 1 in macro variable 'isnumber'.
*/
%MACRO IsNumber(str, multiple=0, sep=%quote( )) / des="Returns 1 if a string seems to be a number, 0 otherwise";
%local char i IsNumber length;
%local notsep;		%* condition that checks whether the analyzed character is different from &sep when &multiple = 1;

%let length = %length(&str);
%let notsep = ;
%let IsNumber = 1;
%let i = 0;
%do %while(&i < &length and &IsNumber);
	%let i = %eval(&i + 1);
	%let char = %quote(%substr(&str, &i, 1));	%* Use quote() in case the character is a blank space;

	%* Add one more condition that compares &char to &sep if multiple=1;
	%if &multiple %then
		%let notsep = and "&char" ~= "&sep";

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
		"&char" ~= " " and
		%upcase("&char") ~= "E"
		&notsep %then
		%let IsNumber = 0;
%end;
&IsNumber
%MEND IsNumber;

/* Tests:
* EMPTY string;
%put %IsNumber();					%* Returns 1;

* MULTIPLE = 0;
%put %IsNumber(-1e-5 + 0.23);		%* Returns 1;
%put %IsNumber(-1e-5 test 0.23);	%* Returns 0;

* MULTIPLE = 1;
%put %IsNumber(0.53 | 1e10, multiple=1, sep=|);						%* Returns 1;
%put %IsNumber(%quote(0.53 , 0.545), multiple=1, sep=%quote(,));	%* Returns 1;
%put %IsNumber(0.53 |t 1e10, multiple=1, sep=|);					%* Returns 0;
*/
