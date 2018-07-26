/* MACRO %MakeList
Version: 1.18
Author: Daniel Mastropietro
Created: 1-Mar-01
Modified: 31-Jan-05

DESCRIPTION:
From a list of names, a new list is returned where an optional prefix and
suffix is added to each name in the list, and a word or character is used
as separator between the names.
By default, the separator is the blank space, but other words or characters
can be specified. In this case, there is still a blank space between the
names and the separator.
The macro is intended to be used in a SAS macro language context.

USAGE:
%MakeList(namesList , prefix= , suffix= , sep=%quote( ) , nospace=0 , log=0);

REQUIRED PARAMETERS:
- namesList:		Blank-separated list of names.

OPTIONAL PARAMETERS:
- prefix:			Prefix to be added to every name in the list.

- suffix:			Suffix to be added to every name in the list.

- sep:				Separator to be used between the names of the list.
					According to the value of parameter NOSPACE, a blank space
					can be left or not between the separator and the names.
					See NOTES below for comments on particular cases.
					default: %quote( ), i.e. a blank space

- nospace:			Whether to leave a space between separator and names.
					Possible values: 	0 => leave a space
									 	1 => do not leave a space
					default: 0

- log:				Show messages in the log?
					In this case the generated list is shown.
					Possible values are: 0 => Do not show messages
										 1 => Show messages
					default: 0

RETURNED VALUES:
The generated list.

NOTES:
1.- Some symbols need to be enclosed with the function %quote when passed
as parameters. This is the case for the blank space, the comma, the quotation
mark. In addition, the quotation mark is a special case, which needs to be treated
differently. Namely, the percentage sign should be used before the quotation
mark symbol, as in: %quote(%"). If '%' is not used, SAS will interpret '"' as the
beginning of a string, not as a symbol.
See examples 2 and 3 below.

2.- This macro is useful to create a set of variable names from a list of
variable names, all affected by a given prefix and/or a given suffix.
See example 1 below.

OTHER MACROS AND MODULES USED IN THIS MACRO:
None

SEE ALSO:
- %MakeListFromName
- %MakeVar

EXAMPLES:
1.- %let list = %MakeList(a b , prefix=First. , sep=OR);
generates the macro variable 'list' with the value:
'First.a OR First.b'
This can be used in a data step to test the condition that the value of
variables a or b occurs for the first time.

2.- %let total = %MakeList(x y z , prefix=Total_);
generates the macro variable 'total' with the value:
'Total_x Total_y Total_z'.

3.- %let quotedList = %Makelist(a b c , prefix=%quote(%") , suffix=%quote(%") , sep=%quote(,));
generates the macro variable quoteList with the value:
'"a" , "b" , "c"'.

4.- %let commaSeparatedList = %Makelist(a b c , sep=%quote(,) , nospace=1);
generates the macro variable commaSeparatedList with the value:
'a,b,c'.
*/
%MACRO MakeList(namesList , prefix= , suffix= , sep=%quote( ) , nospace=0 , log=0)
	/ des="Returns a list of names with specified prefix, suffix and separator";
%local i list name nro_names space _var_;

%*** Getting the number of elements in &namesList;
%let i = 0;
%do %until(%length(%quote(&name)) = 0);
	%** (31/1/05) I changed %quote(&name) = to %length(%quote(&name)) = 0 because
	%** in the previous version, when &name is a very large number (say 838289384929)
	%** SAS gives an OVERFLOW error!!!!;
	%let i = %eval(&i + 1);
	%let name = %scan(&namesList , &i , ' ');
%end;
%let nro_names = %eval(&i - 1);

%*** Space or no space between separator and names;
%if &nospace %then
	%let space =;
%else %if %quote(&sep) ~= %then
	%let space = %quote( );	
	%** Only use an extra space in the separator if the separator is not already a space;

%if &nro_names > 0 %then %do;
	%do i = 1 %to &nro_names;
		%local var&i;
		%let var&i = %scan(&namesList , &i , ' ');
	%end;

	%let list = &prefix.&var1.&suffix;
	%do i = 2 %to &nro_names;
%*1 2004/09/29: The change below was done in order to have macro variables resolved when prefix=&;
		%let _var_ = &&var&i;
		%let list = &list&space&sep&space&prefix.&_var_.&suffix;
%* 		%let list = &list&space&sep&space&prefix.&&var&i..&suffix;
%*2 2004/09/29;
	%end;
%end;
%else
	%let list = ;
%if &log %then %do;
	%put MAKELIST: The following list was created:;
	%put &list;
	%put;
%end;
&list
%MEND MakeList;
