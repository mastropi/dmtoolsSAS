/* MACRO %FindMatch
Version: 1.02
Author: Daniel Mastropietro
Created: 20-Oct-04
Modified: 3-Oct-05

DESCRIPTION:
Finds a keyword in a blank-separated list of names and returns the names containing it.
The macro function %INDEX is used to search for the keyword in each name in the list.
The search for the keyword is NOT case sensitive.

USAGE:
%FindMatch(list, key=, pos=, posNot=, not=, notPos=, log=1);

REQUIRED PARAMETERS:
- list:			Blank-separated list where a keyword is searched for.

OPTIONAL PARAMETERS:
- key:			Keyword to be searched for in 'list'.
				The search is NOT case sensitive.

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
The list of names present in 'list' containing the keyword 'key'.

NOTES:
If no parameters are passed the original list is returned.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %GetNroElements

SEE ALSO:
- %FindInList
- %InsertInList
- %RemoveFromList
- %RemoveRepeated
- %SelectName
- %SelectVar

EXAMPLES:
1.- %let match = %FindMatch(name1 name2 a_xx_b c_XX_d, key=_xx_);
Stores the list
a_xx_b c_XX_d
in macro variable 'match'.

2.- %let match = %FindMatch(name1 name2 a_xx_b c_XX_d, not=_d);
Stores the list
name1 name2 a_xx_b
in macro variable 'match'.
*/

/* PENDIENTE:
- 26/10/04: Agregar la posibilidad de pasar varios nombres en KEY y lo que se busca es
la ocurrencia de ALGUNO de ellos.
Se puede agregar tambien otro parametro que diga si es OR u AND la forma de combinar las
keys.

NOTAS:
- 18/3/05: El proceso de decision acerca de la posicion del key (segun los parametros
POS, POSNOT, NOT y NOTPOS) es igual que el que se hace en %SelectVar, con lo cual se podria
unificar el proceso en una macro y que ambas macros (%FindMatch y %SelectVar) la llamen.
*/
&rsubmit;
%MACRO FindMatch(list, key=, pos=, posNot=, not=, notPos=, log=1)
		/ store des="Returns the names in a list matching a keyword";
%local i name nro_names nvar vari;
%local searchname searchnameNot;
%local matchlist;
%* Auxiliary variables for parameters POS, POSNOT and NOTPOS. They are necessary to parse
%* these parameters when any of those are equal to END, stating that the position of the
%* the KEY or of NOT is at the END of the variable name;
%local position _position_ _positionNot_ _pos_ _posNot_ _notPos_;
%* Boolean variables that state whether the keyword KEY is found in each name and whether
%* the conditions passed in the POS, POSNOT, NOT and NOTPOS parameters are satisfied;
%local found posBool posNotBool notBool notPosBool;
%* Replacement character to use for the first character in KEY in order to search for several
%* occurrences of KEY in each variable name;
%local replacement;

%* OLD: the replacement character is the next character in the ascii sequence. But this has
%* 2 inconveniences: the next character may not exist if the character to be replaced has
%* ascii code = 255, or they may be problems with the character replaced (if it is a very
%* strange character (I have not found this problem, I am just conjecturing);
/*%let replacement = %sysfunc(byte(%eval(%sysfunc(rank(%substr(&searchname, &position, 1)))+1));*/
%let replacement = ?;
%if %quote(%upcase(&key)) = %quote(%upcase(&replacement)) %then
	%let replacement = !;

%let nro_names = %GetNroElements(%quote(&list));
%let matchlist = ;
%do i = 1 %to &nro_names;
	%let name = %scan(%quote(&list), &i, ' ');

	%* Initialize boolean variables stating whether KEY is found and if it is found 
	%* at POSNOT position, and whether NOT keyword is found and if it is found at
	%* NOTPOS position;
	%let found = 0;
	%let posBool = 0;
	%let posNotBool = 0;
	%let notBool = 0;
	%let notPosBool = 0;

	%*** Translate input parameters to character positions in name;
	%if %upcase(&pos) = END %then
		%let _pos_ = %eval(%length(%quote(&name)) - %length(%quote(&key)) + 1);
	%else
		%let _pos_ = &pos;
	%if %upcase(&posNot) = END %then
		%let _posNot_ = %eval(%length(%quote(&name)) - %length(%quote(&key)) + 1);
	%else
		%let _posNot_ = &posNot;
	%if %upcase(&notPos) = END %then
		%let _notPos_ = %eval(%length(%quote(&name)) - %length(%quote(&not)) + 1);
	%else
		%let _notPos_ = &notPos;

	%*** Search for KEY in name;
	%let position = %index(%upcase(%quote(&name)), %upcase(%quote(&key)));
	%if &position > 0 %then %do;
		%let found = 1;
		%let posBool = 1;
		%* Check if KEY is found at position POS, because if this is not the case, the
		%* match should not be considered as such;
		%if &_pos_ > 0 %then %do;
			%let searchname = &name;
			%let _position_ = &position;
			%* Search for KEY in name until the end of the name is reached (&_position_ = 0) or
			%* until it is found at or after the position pos (&_position_ < &pos);
			%do %while (&_position_ > 0 and &_position_ < &_pos_);
				%* Replace in &searchname the first character of the keyword given in KEY with
				%* the next character in the ASCII code so that I can search for other occurrences
				%* of KEY in &name;
				%let searchname = %ReplaceChar(	&searchname,
												&_position_,
												&replacement
							 				   );
				%let _position_ = %index(%upcase(%quote(&searchname)), %upcase(%quote(&key)));
			%end;
			%if &_position_ ~= &_pos_ %then
				%let posBool = 0;	%* State that KEY was not found since it was not found at
									%* the position specified in POS. Therefore the match
									%* should not be considered as such;
		%end;
		%* Search for KEY occurring at position POSNOT, because if this is the case, the
		%* match should not be considered as such;
		%if &_posNot_ > 0 %then %do;
			%let searchname = &name;
			%let _position_ = &position;
			%* Search for KEY in name until the end of the name is reached (&_position_ = 0) or
			%* until it is found at or after the position posNot (&_position_ < &posNot);
			%do %while (&_position_ > 0 and &_position_ < &_posNot_);
				%* Replace in &searchname the first character of the keyword given in KEY with
				%* the next character in the ASCII code so that I can search for other occurrences
				%* of KEY in &name;
				%let searchname = %ReplaceChar(	&searchname,
												&_position_,
												&replacement
							 				   );
				%let _position_ = %index(%upcase(%quote(&searchname)), %upcase(%quote(&key)));
			%end;
			%if &_position_ = &_posNot_ %then
				%let posNotBool = 1;
		%end;
	%end;
	%*** Search for NOT keyword in name;
	%if %quote(&not) ~= %then %do;
		%let positionNot = %index(%upcase(%quote(&name)), %upcase(%quote(&not)));
		%* Search for NOT keyword occurring at position NOTPOS, because only when this
		%* happens should the match not be considered as a match;
		%if &positionNot > 0 %then %do;
			%let notBool = 1;
			%let notPosBool = 1;
			%if &_notPos_ > 0 %then %do;
				%let searchname = &name;
				%let _positionNot_ = &positionNot;
				%* Search for NOT keyword in name until the end of the name is reached
				%* (&_positionNot_ = 0) or until it is found at or after the position notPos
				%* (&_positionNot_ < &notPos);
				%do %while (&_positionNot_ > 0 and &_positionNot_ < &_notPos_);
					%* Replace in &searchname the first character of the keyword given in NOT with
					%* the next character in the ASCII code so that I can search for other occurrences
					%* of NOT keyword in &name;
					%let searchname = %ReplaceChar(	&searchname, 
													&_positionNot_, 
													&replacement
											 	   );
					%let _positionNot_ = %index(%upcase(%quote(&searchname)), %upcase(%quote(&not)));
				%end;
				%if &_positionNot_ ~= &_notPos_ %then
					%let notPosBool = 0;	%* State that the NOT keyword was not found since it
											%* was found at a position where it is ok to be found
											%* (because it is not the position specified with NOTPOS),
											%* and still consider the match as such;	
			%end;
		%end;
	%end;

/*%put;*/
/*%put &name;*/
/*%put posBool=&posBool;*/
/*%put posNotBool=&posNotBool;*/
/*%put notBool=&notBool;*/
/*%put notPosBool=&notPosBool;*/

	%*** Add name to matchlist only if all the conditions given in parameters POS, POSNOT, 
	%*** NOT and NOTPOS are satisfied;
	%if (%length(&key) = 0 or (&found and &posBool = 1 and &posNotBool = 0)) and
		(&notBool = 0 or &notPosBool = 0) %then
		%let matchlist = &matchlist &name;
%end;
%if &log %then %do;
	%if %quote(&key) = and %quote(&not) = %then
		%put FINDMATCH: Names present in the list passed;
	%else %if %quote(&key) ~= %then
		%put FINDMATCH: Names matching the keyword %upcase(&key) in the list passed;
	%else %if %quote(&not) ~= %then
		%put FINDMATCH: Names NOT containing the keyword %upcase(&not) in the list passed;
	%if %quote(&pos) ~= or %quote(&posNot) ~= or %quote(&not) ~= or %quote(&notPos) ~= %then %do;
		%put FINDMATCH: with additional matching options:;
		%put FINDMATCH: (pos=&pos, posNot=&posNot, not=&not, notPos=&notPos);
	%end;
	%let nvar = %GetNroElements(%quote(&matchlist));
	%if &nvar = 0 %then
		%put (Empty);
	%else
		%do i = 1 %to &nvar;
			%let vari = %scan(&matchlist, &i, ' ');
			%put &i: %upcase(&vari);
		%end;
%end;
&matchlist
%MEND FindMatch;
