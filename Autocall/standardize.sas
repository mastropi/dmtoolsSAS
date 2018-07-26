/* MACRO %Standardize
Version: 1.00
Author: Daniel Mastropietro
Created: 17-Jul-03
Modified: 12-Feb-04

DESCRIPTION:
Estandariza variables a media 0 y desvío 1.

USAGE:
%Standardize(
	_data_ ,		*** Input dataset
	var=_NUMERIC_ ,	*** Variables a estandarizar
	out= ,			*** Output dataset
	suffix=_std , 	*** Sufijo para los nombres de las variables estandarizadas
	macrovar= ,		*** Macro variable donde guardar las lista de variables estandarizadas
	log=1);			*** Mostrar mensajes en el log?

REQUIRED PARAMETERS:
- _data_:		Input dataset.

OPTIONAL PARAMETERS:
- var:			Lista separada por blancos de las variables a estandarizar.

- out:			Output dataset con las variables estandarizadas.

- std:			Valor del desvío estándar deseado para las variables estandarizadas.

- suffix:		Sufijo a usar para las variables estandarizadas.
				default: _std

- macrovar:		Nombre de la macro variable global donde guardar la lista
				con los nombres de las variables estandarizadas creadas.

- log:			Indica si se desea ver mensajes en el log generados por la macro.
				Valores posibles: 0 => No, 1 => Sí.
				default: 1

NOTES:
1.- Esta macro no hace otra cosa que llamar a la macro %Center con los
parámetros que recibe, agregando el parámetro std=1.

2.- El proceso de estandarizar variables puede hacerse con PROC STANDARD.
Sin embargo este procedimiento no permite generar nuevas variables con los
valores estandarizados en el input dataset. Permite ya sea sobreescribir las
variables que se transforman, o bien generar un nuevo dataset con las variables
estandarizadas.

3.- El valor del parámetro 'macrovar' no puede ser 'macrovar', ni el nombre de
ningún otro parámetro recibido por la macro. Tampoco puede empezar y terminar con
el símbolo '_'. Ejemplo de valores prohibidos: suffix , out , _var_, etc.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Center

SEE ALSO:
- %Center

EXAMPLES:
1.- %Standardize(test , var=x z , macrovar=var_std);
Estandariza las variables x, z creando nuevas variables x_std, z_std con los
valores estandarizados.
Se genera la macro variable global 'var_std' con la lista de nombres de las
variables estandarizadas: x_std z_std.

2.- %Standardize(test , var=x z , out=test_s , suffix=_s , macrovar=var_s);
Crea el dataset test_s con todas las variables que estan en test mas las
variables estandarizadas x_s, z_s. 
Se genera tambien la macro variable 'var_s' con la lista de los nombres de
las variables estandarizadas: x_s z_s.
*/
%MACRO Standardize(_data_ , var=_NUMERIC_ , out= , suffix=_std , macrovar= , log=1 , help=0)
				/ des="Creates standardized variables to zero mean and unit standard deviation";

/*----- Macro to display usage -----*/
%MACRO ShowMacroCall;
	%put STANDARDIZE: The macro call is as follows:;
	%put %nrstr(%Standardize%();
	%put _data_ , (REQUIRED) %quote(    *** Input dataset.);
	%put var=_numeric_ , %quote(        *** Variables a estandarizar.);
	%put out= , %quote(                 *** Output dataset.);
	%put suffix=_std , %quote(          *** Sufijo para los nombres de las variables estandarizadas.);
	%put macrovar= %quote(              *** Macro variable donde guardar la lista de variables estandarizadas.);
	%put log=1) %quote(                 *** Mostrar mensajes en el Log?);
%MEND ShowMacroCall;

%if &help %then %do;
	%ShowMacroCall;
%end;
%else %if ~%CheckInputParameters(data=&_data_ , var=&var , macro=STANDARDIZE) %then %do;
	%ShowMacroCall;
%end;
%else %do;
	%* Showing input parameters;
	%if &log %then %do;
		%put;
		%put STANDARDIZE: Macro starts;
		%put;
		%put STANDARDIZE: Input parameters:;
		%put STANDARDIZE: - Input dataset = %quote(&_data_);
		%put STANDARDIZE: - var = %quote(          &var);
		%put STANDARDIZE: - out = %quote(          &out);
		%put STANDARDIZE: - suffix = %quote(       &suffix);
		%put STANDARDIZE: - macrovar = %quote(     &macrovar);
		%put STANDARDIZE: - log = %quote(          &log);
		%put Calling macro %nrstr(%Center)...;
		%put;
	%end;
	%Center(&_data_, var=&var, out=&out, std=1, suffix=&suffix, macrovar=&macrovar, log=&log);
%end;
%MEND Standardize;
