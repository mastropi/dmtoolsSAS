/* MACRO %GetDataName
Version: 1.00
Author: Daniel Mastropietro
Created: 28-May-02
Modified: 29-Jul-03

DESCRIPTION:
De un string que corresponde a la referencia de un dataset extrae
el nombre del dataset, eliminando la referencia a la library en caso de
que exista, y cualquier opción que venga entre paréntesis.

Por ejemplo, del string 'work.test(keep=x y drop=z)', la macro devuelve
'test', o sea solo el nombre del dataset.

*/
&rsubmit;
%MACRO GetDataName(str) / store des="Returns the name of a dataset from a string containing options";
%local data_name point_pos;
%let point_pos = %sysfunc(indexc(%quote(&str) , '.'));
%if &point_pos > 0 %then
	%let data_name = %substr(%quote(&str) , &point_pos+1 , %eval(%length(%quote(&str)) - &point_pos));
%else
	%let data_name = &str;
%* Elimino opciones que puedan venir con el dataset;
%let data_name = %scan(&data_name , 1 , '(');
&data_name
%MEND GetDataName;
