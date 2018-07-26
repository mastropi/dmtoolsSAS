/* MACRO %Center
Version: 1.01
Author: Daniel Mastropietro
Created: 17-Jul-03
Modified: 12-Feb-04

DESCRIPTION:
Centra variables, es decir resta la media de las variables para que la
nueva variable tenga media 0.
Opcionalmente escala las variables de manera de tener un desvio estándar
determinado.

USAGE:
%Center(
	_data_ ,		*** Input dataset
	var=_NUMERIC_ ,	*** Variables a centrar
	out= ,			*** Output dataset
	std= ,			*** Valor del desvío estándar deseado para las variables centradas
	suffix=_c , 	*** Sufijo para los nombres de las variables centradas
	macrovar= ,		*** Macro variable donde guardar la lista de las variables centradas
	log=1);			*** Mostrar mensajes en el log?

REQUIRED PARAMETERS:
- _data_:		Input dataset.

OPTIONAL PARAMETERS:
- var:			Lista separada por blancos de las variables a centrar.

- out:			Output dataset con las variables centradas.

- std:			Valor del desvío estándar deseado para las variables centradas.

- suffix:		Sufijo a usar para las variables centradas.
				default: _c

- macrovar:		Nombre de la macro variable global donde guardar la lista
				con los nombres de las variables centradas creadas.

- log:			Indica si se desea ver mensajes en el log generados por la macro.
				Valores posibles: 0 => No, 1 => Sí.
				default: 1

NOTES:
1.- El proceso de centrar variables puede hacerse con PROC STANDARD.
Sin embargo este procedimiento no permite generar nuevas variables con los
valores centrados en el input dataset. Permite ya sea sobreescribir las variables
que se transforman, o bien generar un nuevo dataset con las variables centradas.

2.- El valor del parámetro 'macrovar' no puede ser 'macrovar', ni el nombre de
ningún otro parámetro recibido por la macro. Tampoco puede empezar y terminar con
el símbolo '_'. Ejemplo de valores prohibidos: suffix , out , _var_, etc.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %DeleteMacroVar
- %GetNroElements
- %GetStat
- %GetVarList
- %MakeList

SEE ALSO:
- %Standardize

EXAMPLES:
1.- %Center(test , var=x z , macrovar=var_cent);
Centra las variables x, z creando nuevas variables x_c, z_c con los valores centrados.
Se genera la macro variable global 'var_cent' con la lista de nombres de las variables
centradas: x_c z_c.

2.- %Center(test , var=x z , std=1 , out=test_cent , suffix=_cent , macrovar=var_cent);
Crea el dataset test_cent con todas las variables que estan en test mas las variables
centradas x_cent, z_cent, que son escaladas para que tengan desvío estándar igual a 1.
Se genera tambien la macro variable 'var_cent' con la lista de nombres de las variables
centradas: x_cent z_cent.
*/
%MACRO Center(_data_ , var=_NUMERIC_ ,  out= , std= , suffix=_c , macrovar= , log=1 , help=0)
		/ des="Creates centered (zero mean) variables with specified standard deviation";
%local 	_i_ _nro_vars_;
%local 	_var_cent_ _var_cent_i_
		_var_mean_ _var_mean_i_
		_var_std_ _var_std_i_;

/*----- Macro to display usage -----*/
%MACRO ShowMacroCall;
	%put CENTER: The macro call is as follows:;
	%put %nrstr(%Center%();
	%put _data_ , (REQUIRED) %quote(    *** Input dataset.);
	%put var=_numeric_ , %quote(        *** Variables a estandarizar.);
	%put out= , %quote(                 *** Output dataset.);
	%put std= , %quote(                 *** Valor del desvío estándar deseado para las variables centradas.);
	%put suffix=_std , %quote(          *** Sufijo para los nombres de las variables estandarizadas.);
	%put macrovar= %quote(              *** Macro variable donde guardar la lista de variables estandarizadas.);
	%put log=1) , %quote(               *** Mostrar mensajes en el Log?);
%MEND ShowMacroCall;

%if &help %then %do;
	%ShowMacroCall;
%end;
%else %if ~%CheckInputParameters(data=&_data_ , var=&var , macro=CENTER) %then %do;
	%ShowMacroCall;
%end;
%else %do;
/************************************* MACRO STARTS ******************************************/
%* Showing input parameters;
%if &log %then %do;
	%put;
	%put CENTER: Macro starts;
	%put;
	%put CENTER: Input parameters:;
	%put CENTER: - Input dataset = %quote(&_data_);
	%put CENTER: - var = %quote(          &var);
	%put CENTER: - out = %quote(          &out);
	%put CENTER: - std = %quote(          &std);
	%put CENTER: - suffix = %quote(       &suffix);
	%put CENTER: - macrovar = %quote(     &macrovar);
	%put CENTER: - log = %quote(          &log);
	%put;
%end;

%* Macro variable global donde se devuelve la lista con las variables centradas generadas;
%global &macrovar;

%*** Parsing input parameters;
%* Parsing var;
%let var = %GetVarList(&_data_ , var=&var, log=0);

%* Output dataset;
%if %quote(&out) = %then
	%let out = &_data_;

%let _nro_vars_ = %GetNroElements(&var);
%* Lista de nombres de las variables centradas;
%let _var_cent_ = %MakeList(&var , suffix=&suffix);
%* Promedios de cada variable;
%GetStat(&_data_, var=&var , stat=mean , suffix=_mean , log=0);
%let _var_mean_ = %MakeList(&var , suffix=_mean);
%if &std ~= %then %do;
	%GetStat(&_data_, var=&var , stat=stddev , suffix=_std , log=0);
	%let _var_std_ = %MakeList(&var , suffix=_std);
%end;

data &out;
	set &_data_ end=_lastobs_;
	array vars{*} &var;
	array var_cent{*} &_var_cent_;
	%do _i_ = 1 %to &_nro_vars_;
		%let _var_mean_i_ = %scan(&_var_mean_ , &_i_ , ' ');
		%if &std ~= %then %do;
			%let _var_std_i_ = %scan(&_var_std_ , &_i_ , ' ');
			%if &&&_var_std_i_ ~= 0 %then
				var_cent(&_i_) = (vars(&_i_) - &&&_var_mean_i_) / &&&_var_std_i_ * &std;
			%else
				var_cent(&_i_) = 0;	%* Si la varianza de la variable es 0, quiere decir que todos los valores son iguales a la media;
		%end;
		%else
			var_cent(&_i_) = vars(&_i_) - &&&_var_mean_i_;;
	%end;
	if _lastobs_ and &log then do;
		%do _i_ = 1 %to &_nro_vars_;
			%let _var_cent_i_ = %scan(&_var_cent_ , &_i_ , ' ');
			%if &log %then %do;
				%put CENTER: Centered variable %upcase(&_var_cent_i_) created.;
				%if &std ~= %then
					%put CENTER: Standard deviation of %upcase(&_var_cent_i_) was set to &std;
			%end;
		%end;
	end;
run;

%* Deleting global macro variables generated in %GetStat;
%DeleteMacroVar(&_var_mean_);
	%** Notar que no puedo usar %symdel porque quiero borrar la macro variable
	%* referenciada por otra macro variable;

%if &macrovar ~= %then %do;
	%let &macrovar = &_var_cent_;
	%if &log %then
		%put CENTER: Macro variable %upcase(&macrovar) created with list of centered variable names.;
%end;

%end;	%* %if ~%CheckInputParameters;
%MEND Center;
