/* MACRO %Map
Version: 1.00
Author: Daniel Mastropietro
Created: 17-Oct-05
Modified: 17-Oct-05

DESCRIPTION:
Adds a library with compiled macros to the current SASMSTORE library reference.

USAGE:
%Map(
	library=, 			*** Library to add to the compiled macros libname.
	dir=,				*** Directory to be mapped as <LIBRARY>. Enclosed in quotes.
	access=readonly,	*** Access mode. <Empty> or readonly.
	libname=macrosal	*** Library name used to reference all the libraries containing 
							compiled macros.
);
*/
%MACRO Map(library=, dir=, access=readonly, libname=macrosal);
%local accessst dirs sasmstore;
%local notes_option;

%let notes_option = %sysfunc(getoption(notes));

%* Parse ACCESS= option;
%let accessst = ;
%if %quote(&access) ~= %then
	%let accessst = access=&access;

%* Map new library;
libname &library &dir &accessst;

%* Read current SASMSTORE option;
%let sasmstore = %sysfunc(getoption(sasmstore));

%if %length(&sasmstore) > 0 %then %do;
	%* Remove parenthesis if they exist in SASMSTORE so that the different libnames can be identified
	%* for remapping. The NRBQUOTE function is used to mask unbalanced parenthesis;
	%let sasmstore = %sysfunc(tranwrd(%nrbquote(&sasmstore), %quote(%(), %quote()));
	%let sasmstore = %sysfunc(tranwrd(%nrbquote(&sasmstore), %quote(%)), %quote()));

	%* Read directory mapped by the SASMSTORE libname;
	options nonotes;
	proc sql;
		create table _dirs_ as
		select distinct libname, path from dictionary.members
			where upcase(libname) = "%upcase(&sasmstore)";
	quit;
	data _NULL_;
		set _dirs_;
		%* Remove parenthesis if they exist, because they will be added below;
		path = tranwrd(path, '(', '');
		path = tranwrd(path, ')', '');
		%* Add a single quote if the directory is not enclosed in quotes (this happens
		%* when there is only one directory listed in the path);
		if substr(left(trim(path)), 1, 1) ~= "'" then
			path = "'" || left(trim(path)) || "'";
		call symput ('dirs', path);
	run;

	%* Add new library to existent SASMSTORE libraries;
	options &notes_option;
	libname &libname (&dirs &dir) &accessst;
	options mstored sasmstore=&libname;

	proc datasets nolist;
		delete _dirs_;
	quit;
%end;
%else %do;
	%* Map <LIBRARY> as SASMSTORE library;
	options mstored sasmstore=&library;
%end;

options &notes_option;
%MEND;
