/* MACRO %GetDataOptions
Version: 1.00
Author: Daniel Mastropietro
Created: 17-Dec-02
Modified: 28-May-03

DESCRIPTION:
De un string correspondiente a un data= option de SAS,
devuelve la parte correspondiente a las opciones, es decir la 
parte entre paréntesis.

Por ejemplo, del string 'test(keep=x y drop=z)' la macro
devuelve el string 'keep=x y drop=z'.

*/
&rsubmit;
%MACRO GetDataOptions(str) / store des="Returns the options passed with a dataset name";
%local options paren_pos;
%let paren_pos = %sysfunc(indexc(%quote(&str) , '('));
%if &paren_pos > 0 %then
	%let options = %substr(%quote(&str) , &paren_pos+1 , %eval(%length(%quote(&str)) - &paren_pos - 1));
%else
	%let options =;
&options
%MEND GetDataOptions;
