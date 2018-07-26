/* MACRO %GetDataName
Version: 	1.01
Author: 	Daniel Mastropietro
Created: 	28-May-2002
Modified: 	19-May-2016 (previous: 29-Jul-2003)

DESCRIPTION:
De un string que corresponde a la referencia de un dataset extrae
el nombre del dataset, eliminando la referencia a la library en caso de
que exista, y cualquier opción que venga entre paréntesis.

Por ejemplo, del string 'work.test(keep=x y drop=z)', la macro devuelve
'test', o sea solo el nombre del dataset.

The LIBRARY= parameter is flag indicating whether the library name should be
kept in the dataset name (1) or not (0).

HISTORY:
(2016/05/19) Added the LIBRARY= parameter.
*/
%MACRO GetDataName(str, library=0) / des="Returns the name of a dataset from a string containing a library name and options";
%local data_name point_pos;
%if ~&library %then %do;
	%let point_pos = %sysfunc(indexc(%quote(&str) , '.'));
	%if &point_pos > 0 %then
		%let data_name = %substr(%quote(&str) , &point_pos+1 , %eval(%length(%quote(&str)) - &point_pos));
	%else
		%let data_name = &str;
%end;
%else
	%let data_name = &str;
%* Elimino opciones que puedan venir con el dataset;
%let data_name = %scan(&data_name , 1 , '(');
&data_name
%MEND GetDataName;
