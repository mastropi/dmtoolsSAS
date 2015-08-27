/* MACRO %ReplaceChar
Version: 1.01
Author: Daniel Mastropietro
Created: 20-Jul-05
Modified: 19-Aug-06

DESCRIPTION:
This macro replaces the character at a given position with a string.
If the replacement is a string larger than 1, the length of the name is increased.

USAGE:
%ReplaceChar(name, pos, str);

RETURNED VALUES:
The string or name with the character at the position POS replaced with the string STR.

OTHER MACROS AND MODULES USED IN THIS MACRO:
None

EXAMPLES:
1.- %let newname = %ReplaceChar(test, 2, o);
Creates the macro variable 'newname' with the value 'tost'.

2.- %let newname = %ReplaceChar(test, 2, oa);
Creates the macro variable 'newname' with the value 'toast'.

3.- %let newname = %ReplaceChar(test, 4, ts);
Creates the macro variable 'newname' with the value 'tests'.
*/
&rsubmit;
%MACRO ReplaceChar(name, pos, str) / store des="Returns a name with a character replaced with another one at a given position";
%local newname;

%let newname = &name;
%if %length(&name) > 0 and &pos > 0 and &pos <= %length(&name) %then %do;
	%if %length(&name) = 1 %then %do;
		%** This %if is to avoid an out of range error in the %SUBSTR function below (where &pos+1 and &pos-1 are used as 3rd parameters);
		%let newname = &str;
	%end;
	%else %if &pos = 1 %then %do;
		%** The first character in NAME is replaced;
		%let newname = &str%substr(%quote(&name), %eval(&pos+1));
	%end;
	%else %if &pos = %length(&name) %then %do;
		%** The last character in NAME is replaced;
		%let newname = %substr(%quote(&name), 1, %eval(&pos-1))&str;
	%end;
	%else %do;
		%** A middle character in NAME is replaced;
		%let newname = %substr(%quote(&name), 1, %eval(&pos-1))&str%substr(%quote(&name), %eval(&pos+1));
	%end;
%end;
%else %if %length(&name) > 0 %then %do;
	%** When %length(&name) > 0 it means that the value of &pos is out of range;
	%put REPLACECHAR: ERROR - The value of the second parameter (POS=&pos) is either;
	%put REPLACECHAR: negative or 0, or is larger than the length of the name where the replacement should take place:;
	%put REPLACECHAR: NAME=&name;
	%put REPLACECHAR: The value of NAME is returned.;
%end;
&newname
%MEND ReplaceChar;

