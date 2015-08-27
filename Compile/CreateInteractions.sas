/* %MACRO CreateInteractions
Version: 1.01
Author: Daniel Mastropietro
Created: 15-Jul-03
Modified: 26-Jul-05

DESCRIPTION:
Crea nuevas variables como interacción o producto entre pares de variables.

A partir de una lista de variables, crea nuevas variables o strings que
corresponden a productos o interacciones consigo mismas o con otras variables.

Por ejemplo, si la lista de variables es 'x y z', puede crear variables de
interacción en un dataset correspondientes a los productos de a pares x*y x*z y*z,
o bien puede crear strings con los nombres de variables de interacción ya creadas
de la forma x_X_y x_X_z y_X_z, donde el símbolo _X_ indica interacción.

Asimismo cada elemento de la lista de variables arriba indicada puede interactuarse
con otra lista de variables como 's t' creando los productos x*s x*t y*s y*t z*s z*t.

Las alternativas manejadas por la macro son las siguientes. Se pueden crear:
1.- TODAS CON TODAS: 
	Productos de a pares entre las variables de una lista, todas con todas.
	Ej: Dada la lista: x y z, genera:
		x*x x*y x*z  y*y y*z  z*z
2.- TODAS CON LAS DEMAS:
	Productos de a pares entre las variables de una lista, cada una con las demás
	(es decir sin interactuar una variable consigo misma).
	Ej: Dada la lista: x y z, genera:
		x*y x*z y*z
3.- TODAS CONSIGO MISMA:
	Productos de las variables de una lista, cada una consigo misma.
	Ej: Dada la lista: x y z, genera:
		x*x y*y z*z
4.- TODAS CON TODAS IMPORTANDO EL ORDEN DEL PRODUCTO:
	Idem caso (1) pero generando también los productos en el orden contrario.
	Ej: Dada la lista: x y z, genera:
		x*x x*y x*z  y*x y*y y*z  z*x z*y z*z
5.- TODAS CON TODAS ENTRE DOS LISTAS DE VARIABLES:
	Productos de a pares entre las variables de dos listas distintas, todas con todas.
	Ej: Dadas las listas: 'x y z' y 's t' genera:
		x*s x*t  y*s y*t  z*s z*t
6.- VARIABLE A VARIABLE ENTRE DOS LISTAS:
	Productos de a pares entre las variables de dos listas distintas, variable a variable
	(es decir, no todas con todas sino la interacción entre las variables que están en
	la misma posición).
	Ej: Dadas las listas: 'x y z' y 's t u' genera:
		x*s y*s z*u

Ver ejemplos abajo con la numeración correspondiente para ver cómo invocar la macro
para generar las interacciones indicadas en cada caso.

USAGE:
%CreateInteractions(
	var ,				*** Lista de variables a interactuar.
	with= ,				*** Lista de variables con las que se interactuan las variables
						*** anteriores.
	data= ,				*** Input dataset.
	out= ,				*** Output dataset.
	allInteractions=1 ,	*** Efectuar todas las interacciones posibles entre las variables?
	join=_X_ ,			*** Caracteres con los que se unen los nombres de las variables.
						*** para armar el nombre de la variable de interacción.
	prefix= ,			*** Prefijo a usar en los nombres de las variables o strings de interacción.
	suffix= ,			*** Sufijo a usar en los nombres de las variables o strings de interacción.
	name1= ,			*** Lista de nombres a usar para la primera parte del nombre de las
						*** variables o strings de interacción.
	name2= ,			*** Lista de nombres a usar para la segunda parte del nombre de las
						*** variables o strings de interacción.
	sep=,				*** Separador entre las interacciones de la lista almacenada en MACROVAR=. 
	macrovar= ,			*** Nombre de la macro variable con las variables o strings de interacción
	log=1);				*** Mostrar mensajes en el log?

REQUIRED PARAMETERS:
- var:				Lista de variables a interactuar.

OPTIONAL PARAMETERS:
- with:				Lista de variables con las que se interactuan las variables de
					la lista dada en 'var'.

- data:				Input dataset que contiene las variables indicadas en
					'var' y eventualmente en 'with'.
					Puede recibir opciones adicionales como en cualquier opción
					data= de SAS.
					Si su valor es vacío, la macro no crea variables de interacción
					sino sólo strings indicando los nombres de variables de
					interacción ya creadas. 

- out:				Output dataset.
					Puede recibir opciones adicionales como en cualquier opción
					data= de SAS.
					Si su valor es vacío, las variables de interacción se crean en
					el input dataset.
					Si el input dataset es vacío, este parámetro se ignora.

- allInteractions:	Efectuar todas las interacciones posibles entre las variables?
					Valores posibles:
					0 => No (se usa para los casos 2, 3 y 6 indicados arriba).
					1 => Sí (se usa para los casos 1, 4 y 5 indicados arriba).
					default: 1

- join:				Caracteres con los que se unen los nombres de las variables.
					para armar los nombres de las variables o de los strings de
					interacción.
					Si las variables se crean en un dataset, estos caracteres deben
					ser caracteres válidos en nombres de variables de SAS.
					Por ej., si join=_X_, la variable o string correspondiente a
					la interacción entre x1 y x2 es x1_X_x2.
					default: _X_

- prefix:			Prefijo a usar en cada uno de los nombres de las variables o
					strings de interacción.

- suffix:			Sufijo a usar en cada uno de los nombres de las variables o
					strings de interacción.

- name1:			Lista de nombres a usar para la primera parte del nombre de las
					variables o strings de interacción.
					Debe tener el mismo número de elementos que la lista pasada en
					'var'.
					Ver ejemplo 1 abajo.

- name2:			Lista de nombres a usar para la segunda parte del nombre de las
					variables o strings de interacción.
					Debe tener el mismo número de elementos que la lista pasada en
					'with'.
					Ver ejemplo 1 abajo.

- sep:				Separador a usar entre las interacciones construidas en la lista
					que se almacena en la macro variable 'macrovar'.

- macrovar:			Nombre de la macro variable que contiene la lista de las
					variables o strings de interacción creados por la macro.
					Su nombre NO puede ser 'macrovar', ni tener underscores al
					comienzo y al final, ni coincidir con el nombre de ningún
					otro parámetro de la macro.
					default: _interactions_

- log:				Indica si se desean ver mensajes en el log generados por la macro.
					Valores posibles: 0 => No, 1 => Sí.
					default: 1

NOTES:
1.- Al armar los nombres de las variables de interacción tener en cuenta que el
largo máximo para el nombre de una variable en un dataset es 32 caracteres.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %CheckInputParameters
- %GetNroElements

EXAMPLES:
1.- %CreateInteractions(x y z , data=test , out=test_int , macrovar=int);
Crea el dataset TEST_INT con todas las variables de TEST más las variables de interacción
x_X_x x_X_y x_X_z  y_X_y y_X_z  z_X_z que contienen los productos entre todos los pares
de variables posibles para la lista 'x y z', es decir: x*x x*y x*z  y*y y*z  z*z,
respectivamente.

2.- %CreateInteractions(x y z);
Crea la macro variable &_interactions_ con los strings de interacción correspondientes
al (hipotético) producto de cada variable con las demás (es decir no se incluye el producto
de cada variable consigo misma):
x_X_y x_X_z y_X_z

3.- %CreateInteractions(x y z , with=x y z , data=test , 
						allInteractions=0 , join= , suffix=2 , macrovar=cuad);
En el dataset TEST se crean las variables:
x2 y2 z2,
con el cuadrado de
x y z.
(Es decir la opción allInteractions=0 pide que solamente se armen los productos
x*x y*y z*z.)
Además se crea la macro variable &cuad con la lista de variables creadas:
&cuad = x2 y2 z2.

4.- %CreateInteractions(x y z , with=x y z , join=__ , macrovar=allint);
Crea la macro variable &allint con los strings de interacción correspondientes
al (hipotético) producto de todas las variables en la lista 'x y z' con todas, importando
el orden del producto. Es decir las interacciones:
x__x x__y x__z  y__x y__y y__z  z__x z__y z__z

Notar la necesidad de incluir la misma lista ('x y z') dos veces, tanto en el primer
parámetro como en el parámetro with=. De lo contrario, estaríamos en el caso del ejemplo 2.

5.- %CreateInteractions(variable1 variable2 , with=z1 z2 , data=test ,
						join=X , name1=v1 v2 , macrovar=int);
En el dataset TEST se crean las nuevas variables:
v1Xz1 = variable1*z1
v1Xz2 = variable1*z2
v2Xz1 = variable2*z1
v2Xz2 = variable2*z2
Observar que los nombres 'variable1' y 'variable2' se cambian a 'v1' y 'v2'.

Además se crea la macro variable &int que contiene la lista de variables creadas:
&int = v1Xz1 v1Xz2 v2Xz1 v2Xz2.

6.- %CreateInteractions(x y z , with=r s t , data=test ,
						allInteractions=0 , join= , sep=+, prefix=p_ , suffix=_s, macrovar=sum);
En el dataset TEST se crean las variables de interacción:
p_xr_s p_ys_s p_zt_s,
con los productos variable a variable:
x*r y*s z*t.
(Es decir la opción allInteractions=0 pide que solamente se armen los productos
variable a variable según el orden en que aparecen.)
(Notar que los caracteres de unión son vacíos (pues join= es vacío).)
Además se crea la macro variable global SUM con el siguiente valor:
x*r + y*s + z*t

Notar que el número de variables listadas en with= debe ser el mismo que las listadas
en el primer parámetro.
*/
&rsubmit;
%MACRO CreateInteractions(	var,
							with=,
							data=,
							out=,
							allInteractions=1, 

							join=_X_, 
							prefix=,
							suffix=,
							name1=, 
							name2=,
							sep=,

							macrovar=,

							log=1,
							help=0) / store des="Creates interaction variables or interaction strings";

/*----- Macro to display usage -----*/
%MACRO ShowMacroCall;
	%put CREATEINTERACTIONS: The macro call is as follows:;
	%put;
	%put %nrstr(%CreateInteractions%();
	%put var , (REQUIRED) %quote(       *** Lista de variables a interactuar.);
	%put with= , %quote(                *** Lista de variables con las que se interactuan las variables);
	%put %quote(                            anteriores.);
	%put data= , %quote(                *** Input dataset que contiene las variables a interactuar.);
	%put out= , %quote(                 *** Output dataset.);
	%put allInteractions=1 , %quote(    *** Efectuar todas las interacciones posibles entre las variables?);
	%put join=_X_ , %quote(             *** Caracteres con los que se unen los nombres de las variables);
	%put %quote(                            para armar el nombre de la variable de interacción.);
	%put prefix= , %quote(              *** Prefijo a usar en los nombres de las variables o strings de);
	%put %quote(                            interacción.);
	%put suffix= , %quote(              *** Sufijo a usar en los nombres de las variables o strings de);
	%put %quote(                            interacción.);
	%put name1= , %quote(               *** Lista de nombres a usar para la primera parte del nombre de las);
	%put %quote(                        *** variables o strings de interacción.);
	%put name2= , %quote(               *** Lista de nombres a usar para la segunda parte del nombre de las);
	%put %quote(                        *** variables o strings de interacción.);
	%put sep= , %quote(                 *** Separador a usar entre las interacciones armadas en la lista);
	%put %quote(                            almacenada la macrovariable MACROVAR.);
	%put macrovar= , %quote(            *** Nombre de la macro variable con las variables o strings de);
	%put %quote(                            interacción.);
	%put log=1) %quote(                 *** Mostrar mensajes en el log?);
%MEND ShowMacroCall;

%local _error_ _i_ _j_ _j_start_ _k_ _nro_intvars_ _nro_vars1_ _nro_vars2_ _with_empty_;
%local _var_ _with_ _name1_ _name2_;
%* Macro variables que tienen que ver con la lista de las variables de interaccion creadas;
%local _intlist_ __intlist__;
%local _prodlist_ __prodlist__;
%local _what_;		%* Para el %put que muestra que variables o strings fueron creados;
					%* Puede valer VARIABLE o STRING;

%if &help %then %do;
	%ShowMacroCall;
%end;
%else %do;
%let _error_ = 0;
%* Checking input parameters (only if data= is not empty);
%* Note that I cannot do the if statement by building the expression
%* %if %quote(&data) ~= and ~%CheckInputParameters(...) %then %do, because %CheckInputParameters
%* will be executed regardless of whether &data is empty or not, and it will generate an error
%* message when &data is empty, even if it should not, because data= is not a required parameter;
%if %quote(&data) ~= %then %do;
	%if ~%CheckInputParameters(data=&data , var=&var , requiredParamNames=var , dataRequired=0 , varRequired=1 , macro=CREATEINTERACTIONS) or
		~%CheckInputParameters(data=&data , var=&with , dataRequired=0 , varRequired=0 , macro=CREATEINTERACTIONS) %then %do;
		%ShowMacroCall;
		%let _error_ = 1;
	%end;
%end;
%else %if ~%CheckInputParameters(var=&var , requiredParamNames=var , dataRequired=0 , varRequired=1 , macro=CREATEINTERACTIONS) %then %do;
	%ShowMacroCall;
	%let _error_ = 1;
%end;
%if ~&_error_ %then %do;
/************************************* MACRO STARTS ******************************************/
	%if &log %then %do;
		%put;
		%put CREATEINTERACTIONS: Macro starts.;
		%put;
		%put CREATEINTERACTIONS: Input parameters:;
		%put CREATEINTERACTIONS: - List of variables = %quote(&var);
		%put CREATEINTERACTIONS: - with = %quote(             &with);
		%put CREATEINTERACTIONS: - data = %quote(             &data);
		%put CREATEINTERACTIONS: - out = %quote(              &out);
		%put CREATEINTERACTIONS: - allInteractions = %quote(  &allInteractions);
		%put CREATEINTERACTIONS: - join = %quote(             &join);
		%put CREATEINTERACTIONS: - prefix = %quote(           &prefix);
		%put CREATEINTERACTIONS: - suffix = %quote(           &suffix);
		%put CREATEINTERACTIONS: - name1 = %quote(            &name1);
		%put CREATEINTERACTIONS: - name2 = %quote(            &name2);
		%put CREATEINTERACTIONS: - sep = %quote(              &sep);
		%put CREATEINTERACTIONS: - macrovar = %quote(         &macrovar);
		%put CREATEINTERACTIONS: - log = %quote(              &log);
		%put;
	%end;
	%* Inicializacion de algunas variables;
	%let _what_ = string;	%* Se usa en el %put que muestra las variables de interaccion creadas;
							%* STRING se muestra cuando no se pide la creacion de variables en un
							%* dataset sino simplemente los strings que indican las variables
							%* de interaccion;
	%let _with_empty_ = 0;
	%let _j_start_ = 1;		%* Usando en el data step donde se generan las variables de interaccion;
	%* with= empty;
	%if %quote(&with) = %then %do;
		%* Si se pasa solamente el parmetro var=, hago de cuenta que with=var, porque lo
		%* que esta pidiendo el usuario es hacer interaccion entre las variables de var.
		%* Pero seteo _with_empty_ en TRUE para que distinga dos casos:
		%* - si allInteractions=0 se hagan solo las interacciones cruzadas (es decir no se
		%* hagan interacciones con la misma variable) (ej. x*y x*z y*z).
		%* - si allInteractions=1 se hagan tambien las interacciones con la misma variable
		%* ademas de las cruzadas (ej. x*x x*y x*z y*y y*z z*z);
		%let _with_empty_ = 1;
		%let with = &var;
	%end;
	%* Checking if the number of variables in with is the same as in var when
	%* NOT all interactions are requested and with is passed (e.g. var=x y z and
	%* with=r s t and elementwise interactions are requested: x*r, y*s, z*t);
	%if ~&allInteractions and ~&_with_empty_ %then %do;
		%if %GetNroElements(%quote(&var)) ~= %GetNroElements(%quote(&with)) %then %do;
			%let _error_ = 1;
			%put;
			%put CREATEINTERACTIONS: ERROR - The number of variables in with= is not the same as in var.;
			%put CREATEINTERACTIONS: The macro will stop executing.;
			%put;
		%end;
	%end;
	%if ~&_error_ %then %do;
		%let _nro_vars1_ = %GetNroElements(%quote(&var));
		%let _nro_vars2_ = %GetNroElements(%quote(&with));
		%let _intlist_ = ;
		%let _prodlist_ = ;

		%if %quote(&data) ~= and %quote(&out) = %then
			%let out = &data;

		%if %quote(&data) ~= %then %do;
			%* Si data= no es vacio empiezo un data step;
			data &out;
				set &data end=_lastobs_;
		%end;

		%if %quote(&sep) = %then
			%let sep = %quote( );
		%do _i_ = 1 %to &_nro_vars1_;
			%let _var_ = %scan(&var , &_i_ , ' ');
			%if %quote(&name1) ~= %then
				%let _name1_ = %scan(&name1 , &_i_ , ' ');
			%else
				%let _name1_ = &_var_;

			%if &allInteractions or &_with_empty_ %then %do;
				%if &_with_empty_ %then %do;
					%if &allInteractions %then
						%let _j_start_ = &_i_;				%* Para hacer tambien interacciones tipo x*x;
					%else
						%let _j_start_ = %eval(&_i_ + 1); 	%* Para no hacer interacciones tipo x*x;
				%end;
				%do _j_ = &_j_start_ %to &_nro_vars2_;
					%let _with_ = %scan(&with , &_j_ , ' ');
					%if %quote(&name2) ~= %then
						%let _name2_ = %scan(&name2 , &_j_ , ' ');
					%else
						%let _name2_ = &_with_;
					%if %quote(&data) ~= %then %do;
						&prefix&_name1_&join&_name2_&suffix = &_var_*&_with_;
					%end;
					%if %length(&_intlist_) = 0 %then %do;
						%let _intlist_ = &prefix&_name1_&join&_name2_&suffix;
					%end;
					%else
						%let _intlist_ = &_intlist_ &sep &prefix&_name1_&join&_name2_&suffix;
					%let _prodlist_ = &_prodlist_ &_var_*&_with_;
				%end;
			%end;
			%else %do;
				%let _with_ = %scan(&with , &_i_ , ' ');
				%if %quote(&name2) ~= %then
					%let _name2_ = %scan(&name2 , &_i_ , ' ');
				%else
					%let _name2_ = &_with_;
				%* En caso de que &join sea vacio, el nombre de la nueva variable es el nombre dado 
				%* en &_name1_ con el agregado del prefijo y del sufijo;
				%* Sin embargo, esto solamente lo hace si el prefijo y el sufijo no son vacios a la
				%* vez. Si ambos fueran vacios, existiria el riesgo de que la nueva variable creada
				%* coincidiera con la dada en _name1_. Para evitar este problema, antes de hacer esto
				%* pregunto si &prefix y &suffix no son vacios a la vez cuando &join es vacio, y si
				%* &_name1_ es distinto de &_var_ y de &_with_.
				%* Si este raro caso descripto ocurre, doy a la variable de interaccion el nombre
				%* de la variable original repetida.;
/* 26/7/05: Lo siguiente fue comentado porque para mi no tiene sentido seguir la politica
de nombrar la nueva variable creada con la interaccion de la manera descripta arriba. */
/*				%if %quote(&join) = and ((%quote(&suffix) ~= and %quote(&prefix) ~=) or (&name1 ~= &_var_ and &name1 ~= &_with_)) %then %do;*/
/*					%if %quote(&data) ~= %then %do;*/
/*						&prefix&_name1_&suffix = &_var_*&_with_;*/
/*					%end;*/
/*					%if %length(&_intlist_) = 0 %then*/
/*						%let _intlist_ = &prefix&_name1_&suffix;*/
/*					%else*/
/*						%let _intlist_ = &_intlist_ &sep &prefix&_name1_&suffix;*/
/*				%end;*/
/*				%else %do;*/
					%if %quote(&data) ~= %then %do;
						&prefix&_name1_&join&_name2_&suffix = &_var_*&_with_;
					%end;
					%if %length(&_intlist_) = 0 %then
						%let _intlist_ = &prefix&_name1_&join&_name2_&suffix;
					%else
						%let _intlist_ = &_intlist_ &sep &prefix&_name1_&join&_name2_&suffix;
					%let _prodlist_ = &_prodlist_ &_var_*&_with_;
/*				%end;*/
			%end;
		%end;
		%if %quote(&data) ~= %then %do;
			%let _what_ = variable;
			%** _what_ es usado en el %put de aqui abajo donde muestro las variables creadas;
				if _lastobs_ then do;
		%end;
		%* Indico que variables de interaccion o strings indicando interaccion fueron creados;
		%if &log %then %do;
			%let _nro_intvars_= %GetNroElements(%quote(&_intlist_), sep=%quote(&sep));
			%** Note the use of %QUOTE in the argument of %GetNroElements, because &_intlist_
			%** could have characters (such as =) that would cause trouble if not masked;
			%do _k_ = 1 %to &_nro_intvars_;
				%let __intlist__ = %scan(%quote(&_intlist_) , &_k_ , %quote(&sep));
				%let __prodlist__ = %scan(&_prodlist_ , &_k_ , ' ');
				%put CREATEINTERACTIONS: Interaction &_what_ %str(%'&__intlist__%') (= &__prodlist__) created.;
					%* Note the use of %str and of % before the single quotes. Otherwise, the
					%* & sign does not function as it should;
					%* Note also that I do not print the names of the variables in capital
					%* letters because for some join strings (such as X) the names of the
					%* variables created may be confusing (as in XXY meaning interaction
					%* between variables x and y);
			%end;
		%end;
		%if %quote(&data) ~= %then %do;
			%* Termina el if_lastobs_ y el data step;
				end;
			run;
		%end;

		%* Notar que no muestro un mensaje de creacion de un dataset, porque esto lo muestra
		%* solito el SAS si options notes esta puesto. Si options notes no esta puesto es porque
		%* el usuario no queria ver mensaje en el log, asi que tambien esta bien no mostrar nada;

		%* Macro variable global con la lista de las variables de interaccion creadas;
		%* Si no se paso ningun dataset, se crea una macro variable global llamada _interactions_,
		%* para que la macro devuelva algo (es decir la lista de variables de interaccion
		%* que serian creadas si se hubiera psado el parametro data=;
		%if %quote(&data) = and %quote(&macrovar) = %then
			%let macrovar = _interactions_;
		%if %quote(&macrovar) ~= %then %do;
			%global &macrovar;
			%let &macrovar = %sysfunc(compbl(%quote(&_intlist_)));
			%if &log %then
				%put CREATEINTERACTIONS: Macro variable %upcase(&macrovar) created with the list of interaction &_what_.s.;
		%end;
	%end;	%* %if ~&_error_;

	%if &log %then %do;
		%put;
		%put CREATEINTERACTIONS: Macro ends.;
		%put;
	%end;
%end;	%* %if ~&_error_;
%end;	%* if &help;
%MEND CreateInteractions;
