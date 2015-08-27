/* MACRO %Remap
Version: 1.00
Author: Daniel Mastropietro
Created: 21/09/05
Modified: 24/09/05

DESCRIPTION:
This macro changes to read-only or to non-read-only the access to a SASMACR catalog that is
used to store compiled macros.
When no parameters are passed, the value of the SASMSTORE option is retrieved and the libraries 
listed in that option are remapped with Read/Write access mode.
Other options are to clear or remap as read-only the libraries specified in the LIBRARY= option.

USAGE:
%Remap(library=, access=, clear=0);

REQUIRED PARAMETERS:
None

OPTIONAL PARAMETERS:
- library:		Names of the library references to be remapped.
				default: The libraries listed in the SASMSTORE option

- access:		Access mode to use when remapping the libraries.
				default: Read/Write access

- clear:		Whether to remap or just clear the library references.
				Possible values: 0 => Remap, 1 => Clear
				default: 0

NOTES:
1.- This macro CANNOT be a compiled macro because it remaps the directory with compiled macros,
and while doing so, the access to the macro would be blocked, causing an Access Violation Task.

2.- The SASHELP library is used to allow for the remapping of the specified libraries.
An empty macro %dummy is stored in that library.

EXAMPLES:
1.- %Remap;
This remaps the libraries set in the SASMSTORE option to Read/Write access.

2.- %Remap(access=readonly);
This remaps the libraries set in the SASMSTORE option to Read-only access.

3.- %Remap(library=macros, access=readonly);
This remaps the MACROS library to Read-only access.

4.- %Remap(library=macros, clear=1);
This clears the MACROS library if assigned as a SASMSTORE library.
*/
%MACRO Remap(library=, access=, clear=0) / des="Remaps a SASMSTORE library";
%local i nro_libnames;
%local accessst dir libname mstored sasmstore;
%local notes_option;

%let notes_option = %sysfunc(getoption(notes));

options nonotes;
%* Read current settings;
%if %quote(&library) = %then %do;
	%let mstored = %sysfunc(getoption(mstored));
	%let sasmstore = %sysfunc(getoption(sasmstore));
	%if %upcase(&mstored) = NOMSTORED %then
		%let sasmstore = ;
	%let libname = &sasmstore;
%end;
%else
	%let libname = &library;

%* Remove parenthesis if they exist in LIBNAME so that the different libnames can be identified
%* for remapping. The NRBQUOTE function is used to mask unbalanced parenthesis;
%let libname = %sysfunc(tranwrd(%nrbquote(&libname), %quote(%(), %quote()));
%let libname = %sysfunc(tranwrd(%nrbquote(&libname), %quote(%)), %quote()));

%* Compute the number of libnames in &LIBNAME;
%let nro_libnames = %eval( %length(&libname) - %length(%sysfunc(compress(%quote(&libname)))) + 1);
%* Store each libname in a different macro variable;
%do i = 1 %to &nro_libnames;
	%local libname&i;
	%let libname&i = %scan(&libname, &i, ' ');
%end;
%* Store the libnames in a dataset;
data _libnames_;
	length name $10;	%* The maximum nro. of characters in a libname is 8, but I use 10 just in case;
	%do i = 1 %to &nro_libnames;
		name = "%scan(%upcase(&libname), &i, ' ')";
		output;
	%end;
run;

%* Read directories mapped by all libnames in &LIBNAME;
%if %quote(&libname) ~= %then %do;
	proc sql;
		create table _dir_ as
		select distinct libname, path from dictionary.members
			where upcase(libname) in (select upcase(name) from _libnames_);
	quit;
	%* Define the macro variables where the directory is stored (DIR&i) as local;
	%do i = 1 %to &nro_libnames;
		%local dir&i;
	%end;
	data _NULL_;
		set _dir_;
		%* Remove parenthesis if they exist, because they will be added below;
		path = tranwrd(path, '(', '');
		path = tranwrd(path, ')', '');
		%* Add a single quote if the directory is not enclosed in quotes (this happens
		%* when there is only one directory listed in the path);
		if substr(left(trim(path)), 1, 1) ~= "'" then
			path = "'" || left(trim(path)) || "'";
		call symput ('dir'||left(trim(_N_)), path);
	run;
%end;
%else %do;
	%* Set &DIR1 to empty because it is referenced below when showing the message <None>;
	%local dir1;
	%let dir1 = ;
%end;

%* Show current mapping of sasmstore library;
%if %quote(&access) = %then
	%let _access_ = Read/Write;
%else
	%let _access_ = &access;
%if &clear %then
	%put SASMSTORE libraries to be cleared:;
%else
	%put SASMSTORE libraries to be remapped as ACCESS=&_access_:;
%if %quote(&dir1) = %then
	%put <None>;
%else %do;
	%do i = 1 %to &nro_libnames;
		%put &&libname&i: &&dir&i;
	%end;

	%* Use SASMSTORE=sashelp and not sasuser, because sasuser also maps the C:\SAS\Macros directory
	%* which is the directory containing the compiled macros;
	options mstored sasmstore=sashelp;
	%macro dummy / store;  %mend;

	%*** Reassign original SASMSTORE libraries with the specified ACCESS mode;
	%* Define access mode;
	%if %quote(&access) ~= %then
		%let accessst = access=&access;
	%* Remap libraries;
	options &notes_option;
	%do i = 1 %to &nro_libnames;
		%if &clear %then %do;
		libname &&libname&i;
		%end;
		%else %do;
		libname &&libname&i (&&dir&i) &accessst;
		%end;
	%end;
	%* Re-assign libraries as SASMSTORE;
	%if ~&clear %then %do;
		%if &nro_libnames = 1 %then %do;
			%put Restoring SASMSTORE to &libname...;
			options mstored sasmstore=&libname;
		%end;
		%else %do;
			%put Restoring SASMSTORE to (&libname)...;
			options mstored sasmstore=(&libname);
		%end;
	%end;
	options nonotes;
%end;

proc datasets nolist;
	delete _dir_ _libnames_;
quit;

options &notes_option;
%MEND Remap;
