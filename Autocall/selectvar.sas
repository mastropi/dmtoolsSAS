/* MACRO %SelectVar
Version: 		1.06
Author: 		Daniel Mastropietro
Created: 		7-Oct-04
Modified: 		05-Aug-2015

DESCRIPTION:
This macro returns a list of variables in a dataset whose name contains a given keyword.
Not case sensitive.

USAGE:
%SelectVar(data, key=, pos=, posNot=, not=, notPos=, log=0);

REQUIRED PARAMETERS:
- data:			Dataset where the variables are searched.

OPTIONAL PARAMETERS:
- key:			Keyword to search for in the variable names.
				It should not contain any spaces.
				Not case sensitive.
				Non-name valid keywords are _ALL_, _NUMERIC_ and _CHAR_ in order to retrieve
				the list of all the variables, all the numeric variables, or all the character
				variables, respectively.

- pos:			Position in a name at which the keyword should occur in order to be
				considered a match.
				A non-numeric possible value is END, which states that the keyword should
				be found at the end of the variable name for a match to be valid.

- posNot:		Position at which the keyword 'key' should NOT be present in order for
				a name containing the key to be considered a match.
				A non-numeric possible value is END, which states that the keyword should
				NOT be found at the end of the variable name for a match to be valid.

- not:			Keyword that should NOT appear in a name to be considered a match.
				The keyword should not contain any spaces.

- notPos:		Position at which the 'not' keyword should appear so that only when this is the
				case the match with 'key' is disregarded.
				A non-numeric possible value is END, which states that the keyword NOT should
				be found at the end of the variable name for a match to be excluded.

- log:			Whether to show the list of selected variables in the log.
				Possible values are: 0 => No, 1 => Yes
				default: 1

RETURNED VALUES:
The list of names present in the dataset containing the keyword 'key'.

NOTES:
If no parameters are passed all variables in the dataset are returned.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %FindMatch
- %GetNroElements

SEE ALSO:
- %GetVarNames

EXAMPLES:
1.- %let list = %SelectVar(test, key=qq);
This returns in macro variable 'list' the list of variables in dataset TEST
containing the keyword QQ in their name.
All matches are non case sensitive.

2.- %let list = %SelectVar(test, key=qq, pos=1, not=pp);
This returns in macro variable 'list' the list of variables in dataset TEST
containing the keyword QQ at the beginning of their name, and NOT containing the
keyword PP in any part of their name.
All matches are non case sensitive.

3.- %let list = %SelectVar(test, key=qq, pos=1, not=pp, notPos=3);
Same as Ex. 2 with the difference that, among the names starting with QQ and containing PP, only
those starting with QQPP are disregarded.

4.- %let list = %SelectVar(test, key=qq, posNot=1, not=pp, notPos=3);
Same as Ex. 2 with the difference that the names starting with QQ are disregarded (e.g. QQQAABB).
In addition, those names containing the key QQ and also containing PP as the third character
are disregarded as well (e.g. AAPPBBQQ).

5.- %let list = %SelectVar(test, key=qq, pos=END);
This returns in macro variable 'list' the list of variables in dataset TEST
containing the keyword QQ appearing at the end of their name.
All matches are non case sensitive.

6.- %let list = %SelectVar(test, not=_d, notPos=END);
This returns in macro variable 'list' the list of variables in dataset TEST
NOT containing the keyword _D at the end of their name. 
*/

/* PENDIENTE:
- 26/10/04: Agregar la posibilidad de pasar varios nombres en KEY y lo que se busca es
la ocurrencia de ALGUNO de ellos.
Se puede agregar tambien otro parametro que diga si es OR u AND la forma de combinar las
keys.
*/
%MACRO SelectVar(data, key=, pos=, posNot=, not=, notPos=, log=1)
	/ des="Selects variables from a dataset whose names match certain keywords";
%local data_id i nvar rc vari vartype;
%local list matchlist;

%let data_id = %sysfunc(open(&data));
%if ~&data_id %then
	%put SELECTVAR: ERROR - Dataset %upcase(&data) does not exist.;
/*%else %if %quote(&key) = %then*/
/*	%put SELECTVAR: ERROR - No keyword to search for was passed as second parameter.;*/
%else %do;	
	%let list = ;
    %let nvar = %sysfunc(attrn(&data_id, nvars));
	%if %quote(%upcase(&key)) = _ALL_ or %quote(%upcase(&key)) = _NUMERIC_ or %quote(%upcase(&key)) = _CHAR_ %then %do;
		%do i = 1 %to &nvar;
			%let vartype = %sysfunc(vartype(&data_id, &i));
			%if %quote(%upcase(&key)) = _ALL_ or %upcase(&vartype) = %substr(%upcase(&key), 2, 1) %then
				%let list = &list %sysfunc(varname(&data_id, &i));
		%end;
	    %let rc = %sysfunc(close(&data_id));
		%let matchlist = &list;
	%end;
	%else %do;
		%do i = 1 %to &nvar;
			%let list = &list %sysfunc(varname(&data_id, &i));
		%end;
	    %let rc = %sysfunc(close(&data_id));
		%let matchlist = %FindMatch(&list, key=&key, pos=&pos, posNot=&posNot, not=&not, notPos=&notPos, log=0);
	%end;
%end;
%if &log %then %do;
	%put SELECTVAR: List of variables in dataset %upcase(&data);
	%if %quote(&key) ~= %then %do;
		%if %quote(%upcase(&key)) = _NUMERIC_ or %quote(%upcase(&key)) = _CHAR_ %then
			%put SELECTVAR: that are numeric;
		%else %do;
			%put SELECTVAR: containing keyword %upcase(&key);
			%if %quote(&pos) ~= or %quote(&posNot) ~= or %quote(&not) ~= or %quote(&notPos) ~= %then %do;
				%put SELECTVAR: and additional options: (pos=&pos, posNot=&posNot, not=&not, notPos=&notPos);
			%end;
		%end;
	%end;
	%let nvar = %GetNroElements(%quote(&matchlist));
	%if &nvar = 0 %then
		%put (Empty);
	%else %do;
		%puts(&matchlist)
	%end;
%end;
&matchlist
%MEND SelectVar;
