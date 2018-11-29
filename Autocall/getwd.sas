/* MACRO %Getwd
Version: 		1.00
Author: 		Daniel Mastropietro
Created: 		29-Nov-2018
Modified: 		29-Nov-2018
SAS Version:	9.4

DESCRIPTION:
Returns the working directory.

USAGE:
%getwd

EXAMPLES:
%let wd = %getwd;
*/
%MACRO Getwd / des="Returns the path to the current working directory";
%local rc;
%local wd;
%local wdir;

%* NOTE that the wdir name is the name of a MACRO VARIABLE that is assigned
%* the file reference... i.e. it is NOT the name of the fil reference.
%* This is actually CONVENIENT because we avoid the risk of overriding a
%* file reference defined by a user whose name is the same name as the one used here;
%* Ref: Documentation of FILENAME;
%let rc = %sysfunc(filename(wdir, '.'));
%if &rc ~= 0 %then %do;
	%put %sysfunc(sysmsg());
	%return;
%end;

%* Get the working directory;
%let wd = %sysfunc(pathname(&wdir));	%* Note the use of &wdir NOT wdir;

%* Close the filename connection;
%let rc = %sysfunc(filename(wdir));

&wd
%MEND Getwd;
