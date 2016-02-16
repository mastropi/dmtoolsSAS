/* MACRO %MakeListFromName
Version: 1.05
Author: Daniel Mastropietro
Created: 1-Mar-01
Modified: 6-Jul-05

DESCRIPTION:
This macro generates a list of (unquoted) numbered names from a single (unquoted) name
used as root.
For example, it can generate the list 'x1 x2 x3' from name 'x'.

USAGE:
%MakeListFromName(
	name , 
	length= , 
	start=1 , 
	step= , 
	stop= , 
	prefix= , 
	suffix= , 
	sep=%quote( ) ,
	log=0);

REQUIRED PARAMETERS:
- name:			Name (unquoted) to be used as the root for all generated names.
				(Leave blank if a list of numbers is desired. See example 3).

NOTE: Not all of the following parameters are required. Exactly three of them should have a value,
and parameter START must always be present.
- length:		Number of names to be generated in the list.
				If no value is passed, it is computed as
				floor('start' - 'stop') + 1.

- start:		Starting label value. It can be any real number.
				default: 1

- stop:			Stopping label value. It can be any real number.

- step:			Step to use for the numbers labeling the elements in the list.
				It can be any real number.
				(e.g. if step=2, name=x, length=3 the list will be x1 x3 x5)

OPTIONAL PARAMETERS:
- prefix:		Prefix to be added to every name in the list.

- suffix:		Suffix to be added to every name in the list.

- sep:			Separator to be used between the names of the list.
				default: %quote( ), i.e. a blank space

- log:			Show messages in the log?
				In this case the generated list is shown.
				Possible values are: 0 => Do not show messages
									 1 => Show messages
				default: 0

RETURNED VALUES:
- The list generated is returned in a macro variable. Therefore the output of
this macro can be assigned to a macro variable in a %let statement, or shown
in the log with a %put statement.

NOTES:
1.- Three out of the 4 parameters START, STEP, STOP and LENGHT must be passed,
and START must ALWAYS be passed (default = 1).

2.- Some symbols need to be enclosed with the function %quote when passed
as parameters. This is the case for the blank space, the comma, the quotation
mark. In addition, the quotation mark is a special case, which needs to be treated
differently. Namely, the percentage sign should be used before the quotation
mark symbol, as in: %quote(%"). If '%' is not used, SAS will interpret '"' as the
beginning of a string, not as a symbol.
See examples below.

OTHER MACROS AND MODULES USED IN THIS MACRO:
None

SEE ALSO:
- %MakeList
- %MakeVar

EXAMPLES:
1.- %let list1 = %MakeListFromName(x , length=5 , start=0 , step=10);
assigns the following list to macro variable 'list1':
'x0 x10 x20 x30 x40'.

2.- %put list2 = %MakeListFromName(x , start=1 , step=1 , length=5 , prefix=%quote(%") , suffix=%quote(%") , sep=%quote(,));
shows the following list in the log:
'"x1","x2","x3","x4","x5"'.

3.- %put list2 = %MakeListFromName(x , start=-1 , step=-2 , stop=-6, sep=%quote( or ));
shows the following list in the log:
'x-1 or x-3 or x-5'.

4.- %put ListOfNumbers = %MakeListFromName( , length=3 , start=0 , step=10);
shows the following list in the log:
'0 10 20'.
(Note that the first parameter is empty.)

APPLICATIONS:
This macro is useful to generate a list of variable names with the same root
but different numbers identifying each of them, as in 'x1 x2 x3 x4 x5 x6 x7'.
*/
&rsubmit;
%MACRO MakeListFromName(name , length= , start=1 , stop= , step= , prefix= , suffix= , sep=%quote( ) , log=0)
		/ store des="Returns a list of numbered names with a specified root";
%local i index list;

%* List is initialized as empty so that when an error occurs, the empty string is returned;
%let list = ;
%* Checking input parameters. Note that parameter name can be empty!;
%if not ((%quote(&start) ~= and %quote(&step) ~= and %quote(&length) ~=) or
		 (%quote(&start) ~= and %quote(&stop) ~= and %quote(&length) ~=) or
		 (%quote(&start) ~= and %quote(&step) ~= and %quote(&stop) ~=)) or
	 (%quote(&start) ~= and %quote(&step) ~= and %quote(&stop) ~= and %quote(&length) ~=) %then %do;
	%put MAKELISTFROMNAME: ERROR - The number of parameters passed is incorrect.;
	%put MAKELISTFROMNAME: Usage:;
	%put %nrstr(%MakeListFromName%();
	%put name ,;
	%put length= ,;
	%put start=1 ,;
	%put stop= ,;
	%put step=1 ,;
	%put prefix= ,;
	%put suffix= ,;
	%put sep=%quote( ) ,;
	%put log=0);
	%put One of the following combinations of parameter values must be passed:;
	%put START, STEP, LENGTH;
	%put START, STOP, LENGTH;
	%put START, STEP, STOP;
	%put and NOT all 4 parameters can be passed at the same time.;
%end;
%else %if %quote(&length) ~= and %sysevalf(&length <= 0) %then 
	%put MAKELISTFROMNAME: ERROR - The value of LENGTH is not positive.;
%else %if %quote(&step) ~= and %quote(&stop) ~= and
	((%sysevalf(&stop >= &start) and %sysevalf(&step <= 0)) or
	(%sysevalf(&stop < &start) and %sysevalf(&step >= 0))) %then
	%put MAKELISTFROMNAME: ERROR - The values of START=, STEP= and STOP= are inconsistent.;
%else %do;
	%let index = &start;
	%let list = &prefix.&&name.&start&suffix;
	%* Define the value of STEP since I always need it to construct the list;
	%if %quote(&step) = %then %do;
		%if &length > 1 %then
			%let step = %sysevalf((&stop - &start) / (&length - 1));
		%else
			%let step  = 0;
	%end;
	%if %quote(&stop) = %then
		%do i = 2 %to &length;
			%let index = %sysevalf(&index + &step);
			%let list = &list.&sep.&prefix.&&name.&index.&suffix;
		%end;
	%else
		%do %while ((%sysevalf(&step > 0) and %sysevalf(&index + &step <= &stop)) or
					(%sysevalf(&step < 0) and %sysevalf(&index + &step >= &stop)));
			%let index = %sysevalf(&index + &step);
			%let list = &list.&sep.&prefix.&&name.&index.&suffix;
		%end;
	%if &log %then %do;
		%put MAKELISTFROMNAME: The following list was created:;
		%put &list;
		%put;
	%end;
%end;
&list
%MEND MakeListFromName;
