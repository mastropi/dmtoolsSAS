/* MACRO %CreateVarFromList
Version: 1.02
Author: Daniel Mastropietro
Created: 3-Dec-04
Modified: 17-Jan-05

DESCRIPTION:
This macro creates a dataset with one column containing the names in a list.
Optionally the dataset is transposed so that there is only one observation with all
the values passed in the list.

USAGE:
%CreateVarFromList(
	list,			*** List of names
	out=,			*** Output dataset with the list of names in one column
	sep=%quote( )	*** Separator used to separate the names in the list.
	type=char,		*** Type of variable to create in output dataset.
	sort=0, 		*** Should the list of names be sorted alphabetically?
	transpose=0		*** Transpose output dataset to have only one observation with all the names?
	title=,			*** Title to show when printing the list of names in the output window.
	log=1);			*** Show messages in the log?

NOTES:
This macro calls %PrintNameList. See the help of that macro for additional information.
*/
&rsubmit;
%MACRO CreateVarFromList(list, sep=%quote( ), out=, type=CHAR, sort=0, transpose=0, title=, log=1)
		/ store des="Creates a variable containing the names in a list";
%if &log %then
	%put CREATEVARFROMLIST: Calling %nrstr(%PrintNameList)...;
%PrintNameList(	%quote(&list), 
				sep=%quote(&sep), 
				out=&out, 
				type=&type, 
				sort=&sort, 
				transpose=&transpose, 
				title=%quote(&title), 
				log=&log);
%MEND CreateVarFromList;
