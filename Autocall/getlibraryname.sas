/* MACRO %GetLibraryName
Version: 1.00
Author: Daniel Mastropietro
Created: 28-May-02
Modified: 28-May-03

DESCRIPTION:
De un string que corresponde a la referencia de un dataset extrae
el nombre del library name. Si no tiene ninguna referencia a libname,
devuelve WORK.


*/
%MACRO GetLibraryName(str) / des="Returns the libref part of a dataset name";
%local library_name point_pos;
%let library_name = WORK;	%* Si no hay libname reference, devuelve WORK;
%let point_pos = %sysfunc(indexc(%quote(&str) , '.'));
%if &point_pos > 0 %then
	%let library_name = %scan(&str , 1 , '.');
&library_name
%MEND GetLibraryName;
