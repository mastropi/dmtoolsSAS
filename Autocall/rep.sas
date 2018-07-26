/* MACRO %Rep
Version: 1.00
Author: Daniel Mastopietro
Created: 24-Oct-04
Modified: 24-Oct-04

DESCRIPTION:
This macro creates a list with a given name repeated a given number of times.

USAGE:
%Rep(name, times);

RETURNED VALUES:
A list with 'name' repeated 'times' times is returned.

OTHER MACROS AND MODULES USED IN THIS MACRO:
None

EXAMPLES:
%let list = %Rep(xx, 4);
stores in macro variable 'list' the list:
xx xx xx xx
*/
%MACRO Rep(name, times)
	/ des="Returns a list with a given name repeated a specified number of times";
%local i list;

%let list = ;
%do i = 1 %to &times;
	%if %quote(&name) ~= %then
		%let list = &list &name;
	%else
		%let list = &list%quote( );
%end;

&list
%MEND Rep;
