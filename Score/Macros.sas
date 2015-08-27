/* Macros.sas
Creado: 29/07/05
Modificado: 10/10/05
Autor: Daniel Mastropietro
Titulo: Conjunto de macros requeridas para scorear cuentas con la macro %Score.

Descripcion: Se definen las macros utilizadas por las macros %Score, %PrepareToScore y %GenerateScore
para generar el score de un modelo de regresion logistica.
*/

&rsubmit;

/************************************ %Any, version 1.08 **************************************/
%MACRO Any(vars , operator, values , pairwise=0) / store des="Create OR conditions";
%local i j condition nro_vars nro_values var;
%let nro_vars = %GetNroElements(&vars);
%let nro_values = %GetNroElements(&values);

%if ~&pairwise %then
	%do i = 1 %to &nro_vars;
		%let var = %scan(&vars , &i , ' ');
		%do j = 1 %to &nro_values;
			%let value = %scan(&values , &j , ' ');
			%if &i = 1 and &j = 1 %then
				%let condition = %str(&var&operator&value);
			%else
				%let condition = &condition | %str(&var&operator&value);	
		%end;
	%end;
%else %do;
	%if &nro_vars ~= &nro_values %then
		%put ANY: ERROR - The number of variables and the number of values must be equal when PAIRWISE=1;
	%else
		%do i = 1 %to &nro_vars;
			%let var = %scan(&vars , &i , ' ');
			%let value = %scan(&values , &i , ' ');
			%if &i = 1 %then
				%let condition = %str(&var&operator&value);
			%else
				%let condition = &condition | %str(&var&operator&value);
		%end;
%end;
(&condition)
%MEND Any;
/************************************ %Any, version 1.08 **************************************/


/************************************ %CallMacro *********************************************/
%MACRO Callmacro(macro,inparams,outparams,nin=0,sep=%quote( ),sepout=%quote( )) / store des="Call a macro and get the returned values";
%local i nin nout out params parname varname;
%local commaIndex head lengthParname tail;
/* Determining the number of input parameters passed to the macro 'macro' and the number
of output parameters returned by it. The function 'compress' eliminates all the blanks in
its argument and the function 'compbl' reduces multiple consecutive blanks into a single one.
Note that the number of input parameters is computed from the 'inparams' variable ONLY when
nin is equal to 0. Otherwise, the number of input parameters is the value of nin passed. */
%if &nin = 0 %then
	%let nin = %eval( %length(%sysfunc(compbl(%quote(&inparams)))) - %length(%sysfunc(compress(%quote(&inparams)))) + 1 ) ;
%let nout = %eval( %length(&outparams) - %length(%sysfunc(compress(&outparams))) + 1 );

/* Creating the list of parameters to pass to the macro 'macro' */
%let params = %scan( %quote(&inparams) , 1 , &sep );	%*** Initializing params with the first in parameter;
%do i = 2 %to &nin;
	%let parname = %scan( %quote(&inparams) , &i , &sep );
	%* This checks whether there is an expression of the type %quote(,) in the value of
	%* one of the parameters, so that the value of the parameter is kept as %quote(,).
	%* e.g. sep=%quote(,), or sep=%quote(a,b), etc;
	%let commaIndex = %index(%quote(&parname),%quote(,));
	%if &commaIndex %then %do;
		%let lengthParname = %length(&parname);
		%let head = %substr(%quote(&parname), 1 , &commaIndex-1);
		%if &lengthParname > &commaIndex %then
			%let tail = %substr(%quote(&parname), &commaIndex+1);
		%let parname = &head%nrstr(%quote)(,)&tail;
	%end;
	%let params = &params , &parname;
%end;

/* Calling the macro */
%let out = %&macro(&params);

/* Creating the list of output parameters returned by the macro 'macro' */
%do i = 1 %to &nout;
	%let varname = %scan( &outparams , &i , ' ' );
	%let &varname = %scan( %quote(&out) , &i , &sepout );
%end;
%MEND Callmacro;
/************************************ %CallMacro *********************************************/


/*************************** %CreateInteractions Version 1.01 ********************************/
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
							help=0) / store des="Create Interaction strings";

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
				%if %quote(&data) ~= %then %do;
					&prefix&_name1_&join&_name2_&suffix = &_var_*&_with_;
				%end;
				%if %length(&_intlist_) = 0 %then
					%let _intlist_ = &prefix&_name1_&join&_name2_&suffix;
				%else
					%let _intlist_ = &_intlist_ &sep &prefix&_name1_&join&_name2_&suffix;
				%let _prodlist_ = &_prodlist_ &_var_*&_with_;
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
/*************************** %CreateInteractions Version 1.01 ********************************/


/********************************** %EvalExp, version 1.00 ***********************************/
%MACRO EvalExp(exp) / store des="Evaluate an Expression";
%sysfunc(compbl(&exp))
%MEND EvalExp;
/********************************** %EvalExp, version 1.00 ***********************************/


/********************************* %ExistVar, Version 1.05 ***********************************/
%MACRO ExistVar(data, var, macrovar=, log=1) / store des="Returns 1 if all variables in a list exist in a data set, 0 otherwise";
/* NOTE: (27/12/04) I use two underscores in the local names because it may be common to
use a name with single underscores as the value of parameter MACROVAR= when calling this macro
from within another macro.
Except for macro variable EXIST, because there is an auxiliary macro variable called __EXIST__.
*/
%local __i__;
%local __data_name__ __dsid__ __nro_vars__ exist rc __var__;
%* Local variable used to check the existence (in turn) of each variable passed;
%local __exist__;
%local __notfound__;

%* Setting default value for returned variable (EXIST);
%* Note that the value is set to a value such that the macro returns FALSE if
%* the parameters passed are not correct.;
%let exist = 0;

%let __data_name__ = %scan(&data , 1 , '(');

%let __dsid__ = %sysfunc(open(&__data_name__));
%if ~&__dsid__ %then %do;
	%if &log %then
		%put EXISTVAR: %sysfunc(sysmsg());
%end;
%else %do;
	%let __nro_vars__ = %GetNroElements(&var);
	%if &__nro_vars__ <= 0 %then
		%put EXISTVAR: ERROR - No variables were passed.;
	%else %do;
		%let __i__ = 1;
		%let exist = 1;
		%let __notfound__ = ;
		%do %while (&__i__ <= &__nro_vars__);
			%let __var__ = %scan(&var , &__i__ , ' ');
			%if %length(&__var__) > 32 %then %do;
				%* I ask for length > 32 because the maximum allowable length of a variable name
				%* is 32 and if the varnum function is used when the name is larger than 32
				%* an error occurs (saying that the second element of the function is out of range);
				%let __exist__ = 0;
			%end;
			%else
				%let __exist__ = %sysfunc(varnum(&__dsid__ , &__var__));
				%** Returns the position of the variable in the dataset;
				%** Returns 0 if the variable does not exist;
			%if ~&__exist__ %then %do;
				%let exist = 0;		%* Setting the value of the variable that is returned by the macro;
				%let __notfound__ = &__notfound__ &__var__;
				%if &log %then
					%put EXISTVAR: Variable %upcase(&__var__) does not exist in dataset %upcase(&data).;
			%end;
			%let __i__ = %eval(&__i__ + 1);
		%end;
	%end;
	%let rc = %sysfunc(close(&__dsid__));
	
	%* Storing in a global macro variable the list of variables not found;
	%if %quote(&macrovar) ~= %then %do;
		%global &macrovar;
		%let &macrovar = &__notfound__;
	%end;
	%if &log and ~&exist %then %do;
		%put EXISTVAR: The following variables were not found in dataset %upcase(&data):;
		%put EXISTVAR: &__notfound__;
		%put;
	%end;
%end;
&exist
%MEND ExistVar;
/********************************* %ExistVar, Version 1.05 ***********************************/


/********************************* %FindInList, version 1.02 *********************************/
%MACRO FindInList(list, names, sep=%quote( ), match=ALL, sorted=0, out=, log=1) / store des="Search for names in a list";
%local i;
%local count counti counts;	%* COUNT is the number of names listed in NAMES found in the list;
							%* COUNTI is the number of times each name is found in the list;
							%* COUNTS is the vector containing the number of times EACH
							%* name is found in the list;
%local pos posi;	%* POS is the vector of name positions of each name found in the list;
					%* POSI is the name position in the list of the name being analyzed;
%local name nro_names nro_namesInlist;
%local namesFound namesFoundPos;
%local length maxlength;
%local notes_option space;

%if &log %then %do;
	%put;
	%put FINDINLIST: Macro starts;
	%put;
%end;

/*----------------------------------- Parse input parameters --------------------------------*/
%*** SEP=;
%* If SEP= is blank, redefine it as the blank space using function %quote;
%* This is necessary for the %scan function to work properly;
%if %quote(&sep) = %then
	%let sep = %quote( );
%if %quote(&sep) = %quote( ) %then
	%let fast = 1;	%* Perform fast search using INDEXW;
%else
	%let fast = 0;	%* Perform slow search using the %SCAN function that sweeps over all elements in &list;

%*** MATCH=;
%if %quote(%upcase(&match)) = ALL %then
	%let match = 0;

%*** FAST=;
%if &fast %then 	%goto FAST;
%else				%goto SLOW;
/*-------------------------------------------------------------------------------------------*/

/*------------------------------------------- FAST ------------------------------------------*/
%FAST:
%local error;
%local FirstPartOfList posi_prev;

%let error = 0;
/* The following is not necessary any more, because the macro variable FAST was removed from
the parameter list. Its value is set from the value of SEP, above.
%* Check if the separator is a blank space, o.w. abort;
%if %quote(&sep) ~= %then %do;
	%let error = 1;
	%put FINDINLIST: ERROR - In FAST search mode (FAST=1), the separator must be a blank space.;
	%put FINDINLIST: Use SLOW search mode (FAST=0) instead.;
	%put FINDINLIST: WARNING - If the number of names in the list is large, the search may take;
	%put FINDINLIST: too long.;
%end;
*/

%if ~&error %then %do;
	%let nro_names = %GetNroElements(%quote(&names));
	%let pos = ;		%* List of name positions of the names found in &list;
	%let count = 0;		%* Counter for the number of &names found in list;
	%let counts = ;		%* Vector containing the number of times each name is found in the list;
	%let namesFound = ;	%* List of names found in the list;
	%let namesFoundPos =;	%* Vector of the position of the names found in NAMES;
	%do i = 1 %to &nro_names;
		%let nro_namesInList = %GetNroElements(%quote(&list));
		%let counti = 0;
		%let posi_prev = 0;
		%let _list_ = %quote(&list);
		%let name = %scan(%quote(&names), &i, %quote( ));
		%do %until (&posi = 0 or &counti = &match);
			%let posi = %sysfunc(indexw(%quote(%upcase(&_list_)) , %quote(%upcase(&name))));
			%if &posi > 0 %then %do;
				%let counti = %eval(&counti + 1);
				%* If this is the first occurrence of NAME found in the list, increase the counter
				%* for the number of names present in NAMES found in LIST;
				%if &counti = 1 %then
					%let count = %eval(&count + 1);

				%* Store the first part of the list (coming before &name) so that the name position
				%* of &name in &list can be computed;
				%if &posi > 1 %then
					%** If it is not the first name in the list;
					%* Keep everything that is before the name to be removed from the list;
					%let FirstPartOfList = %substr(%quote(&_list_), 1, %eval(&posi-1));
				%else
					%** If it is the first name in the list;
					%let FirstPartOfList = ;

				%* Keep the list of names coming after the position where &name was found, so
				%* that the search for &name in the following loop is conducted only on the
				%* remaining part of &list;
				%if &posi < &nro_namesInList %then
					%* If it is not the last element in the list;
					%let _list_ = %substr(%quote(&_list_), %eval(&posi + %length(&name) + 1));
				%else
					%** If it is the last element in the list;
					%let _list_ = ;

				%* Get the name position of &name in the list;
				%let posi = %eval(%GetNroElements(&FirstPartOfList) + &posi_prev + 1);
				%let pos = &pos &posi;
				%let posi_prev = &posi;
			%end;
		%end;
		%* Update vector with the name of times that each name is found in the list;
		%let counts = &counts &counti;
		%* Update list of names found in the list and their position in NAMES;
		%if &counti > 0 %then %do;
			%let namesFound = &namesFound &name;
			%let namesFoundPos = &namesFoundPos &i;
		%end;
		%* If more than one occurrence was requestd and the number of names in NAMES is
		%* more than one, add a semicolon to separate the list of positions for each occurrence
		%* of the names passed in NAMES in the list;
		%* Note that I use STR not QUOTE, because with QUOTE there is an error that screws everything up;
		%* Also, a space needs to be left after the semicolon, o.w. the %scan function used below
		%* to choose the elements in the list when creating the output dataset does not
		%* work properly, because the %scan function does not recognize an element as such
		%* if there are two separators stick together;
		%if &match ~= 1 and &nro_names > 1 %then
			%let pos = %str(&pos; );
	%end;
	%goto FINAL;
%end;
%else
	%goto ABORTALL;
/*---------------------------------------- FAST ---------------------------------------------*/


/*---------------------------------------- SLOW ---------------------------------------------*/
%SLOW:
%local namej;
%local name_ch1 name_ch2 namej_ch1 namej_ch2;

%let nro_namesInList = %GetNroElements(%quote(&list), sep=%quote(&sep));
%let nro_names = %GetNroElements(%quote(&names), sep=%quote(&sep));
%let pos = ;		%* List of name positions of the names found in &list;
%let count = 0;		%* Counter for the number of &names found in list;
%let counts = ;		%* Vector containing the number of times each name is found in the list;
%let namesFound = ;	%* List of names found in the list;
%let namesFoundPos =;	%* Vector of the position of the names found in NAMES;
%do i = 1 %to &nro_names;
	%let counti = 0;
	%let name = %scan(%quote(&names), &i, %quote(&sep));
	%let name_ch1 = %substr(%quote(%upcase(&name)), 1, 1);
	%if %length(&name) > 1 %then
		%let name_ch2 = %substr(%quote(%upcase(&name)), 2, 1);
	%else
		%let name_ch2 = %quote( );	%* It is neccessary to define the value of &name_ch2 as
									%* a blank space to avoid an error in the rank function below;
	%* Search for &name in &list;
	%let j = 0;
	%do %while (&j < &nro_namesInList);
		%let j = %eval(&j + 1);
		%let namej = %scan(%quote(&list), &j, %quote(&sep));
		%let namej_ch1 = %substr(%quote(%upcase(&namej)), 1, 1);
		%if %length(&namej) > 1 %then
			%let namej_ch2 = %substr(%quote(%upcase(&namej)), 2, 1);
		%else
			%let namej_ch2 = %quote( );	%* It is neccessary to define the value of &name_ch2 as
										%* a blank space to avoid an error in the rank function below;
		%if &sorted and
			%sysfunc(rank(&namej_ch1)) > %sysfunc(rank(&name_ch1)) or
			(%sysfunc(rank(&namej_ch1)) = %sysfunc(rank(&name_ch1)) and %sysfunc(rank(&namej_ch2)) > %sysfunc(rank(&name_ch2))) %then
			%let j = &nro_namesInList;
		%else %if %upcase(&namej) = %upcase(&name) %then %do;
			%let counti = %eval(&counti + 1);
			%* If this was the first occurrence of NAME found in the list, increase the counter
			%* for the number of names present in NAMES found in LIST;
			%if &counti = 1 %then
				%let count = %eval(&count + 1);
			%* Store the name position in list of i-th name in &names (&name);
			%let posi = &j;
			%* Update the list of name positions for each different name listed in &names;
			%let pos = &pos &posi;

			%* If the number of matches requested were found, set j to &nro_namesInList so
			%* that the loop stops. Note that if MATCH=ALL, then MATCH is set to 0 at the
			%* beginning of the macro, and in this case &counti is always larger than 0
			%* therefore, the loop will continue until all the occurrences of &name are found
			%* in &list;
			%if &counti = &match %then
				%let j = &nro_namesInList;
		%end;
	%end;
	%* Update vector with the number of times that each name is found in the list;
	%let counts = &counts &counti;
	%* Update list of names found in the list and their position in NAMES;
	%if &counti > 0 %then %do;
		%let namesFound = &namesFound &name;
		%let namesFoundPos = &namesFoundPos &i;
	%end;
	%* If more than one occurrence was requestd and the number of names in NAMES is
	%* more than one, add a semicolon to separate the list of positions for each occurrence
	%* of the names passed in NAMES in the list;
	%* Note that I use STR not QUOTE, because with QUOTE there is an error that screws everything up;
	%* Also, a space needs to be left after the semicolon, o.w. the %scan function used below
	%* to choose the elements in the list when creating the output dataset does not
	%* work properly, because the %scan function does not recognize an element as such
	%* if there are two separators stick together;
	%if &match ~= 1 and &nro_names > 1 %then
		%let pos = %str(&pos; );
%end;
/*------------------------------------------- SLOW ------------------------------------------*/

%FINAL:
%if &log %then %do;
	%if &count = 0 %then
		%put FINDINLIST: No names were found in the list.;
	%else %do;
		%put FINDINLIST: &count out of &nro_names names were found in the list.;
		%put FINDINLIST: The list of names found, their index, and their positions in the list follows:;
		%let nro_namesFound = %GetNroElements(&namesFound);
		%do i = 1 %to &nro_namesFound;
			%if &i = 1 %then
				%let space = %quote( );
			%else
				%let space = ;
			%put %scan(&namesFoundPos, &i, ' '): %upcase(%scan(&namesFound, &i, ' ')) --at: &space%sysfunc(compbl(%quote(%scan(&pos, &i, ';'))));
		%end;
	%end;
%end;

%if %quote(&out) ~= %then %do;
	%* Determine the length to be used for variable POS in the output dataset;
	%if &match ~= 1 and &nro_names > 1 %then %do;
		%let maxlength = 0;
		%do i = 1 %to &nro_names;
			%let length = %length(%scan(%quote(&names), &i, ';'));
			%if &length > &maxlength %then
				%let maxlength = &length;
		%end;
	%end;

	%* Remove the notes from the log. This is necessary to avoid messages in the log when
	%* log=0;
	%let notes_option = %sysfunc(getoption(notes));
		%** Two semicolons are used in the %let above to prevent the OPTIONS command below
		%** from not being executed when an output dataset is requested by the user and
		%** accidentally the user uses a %put statement that includes a call to %FindInList
		%** as in %put %FindInList(aa bb cc, aa, out=out). Such call will show the string
		%** OPTIONS NOTES in the log instead of executing it, because it is bounded to the
		%** %put statement used before calling %FindInList;
	options nonotes;
	data &out;
		length name $32;
		%if &match ~= 1 and &nro_names > 1 %then %do;
		length pos $&maxlength;
		%end;
		%do i = 1 %to &nro_names;
			name = compbl("%scan(%quote(&names), &i, %quote(&sep))");
			%* Remove any space at the beginning;
			if substr(name,1, 1) = " " then
				name = substr(name, 2);
			%if &match ~= 1 and &nro_names > 1 %then %do;
			%* Remove any space at the beginning;
			pos = compbl("%scan(&pos, &i, ';')");
			if substr(pos, 1, 1) = " " then
				pos = substr(pos, 2);
			%end;
			%else %do;
			pos = %scan(&pos, &i, ' ');
			%end;
			output;
		%end;
	run;
	options &notes_option;
	%if &log %then %do;
		%put;
		%put FINDINLIST: Output dataset %upcase(%scan(&out, 1, '(')) created with the positions of each name in the list.;
	%end;
%end;

%* If no name was found, return 0 (just one 0, even if there are many names in the list)
%* This is done so that the returned value can be used in an %if statement;
%if &count = 0 %then
	%let pos = 0;

%ABORTALL:
%if &log %then %do;
	%put;
	%put FINDINLIST: Macro ends;
	%put;
%end;

%* Only return the name positions of the names found if no output dataset has been created.
%* Note the use of the semicolon after &pos, which closes the %if;
%if %quote(&out) = %then
&pos;
%MEND FindInList;
/********************************* %FindInList, version 1.02 *********************************/


/********************************* %FindMatch, version 1.02 **********************************/
%MACRO FindMatch(list, key=, pos=, posNot=, not=, notPos=, log=1)
		/ store des="Returns the names in a list matching a keyword";
%local i name nro_names nvar vari;
%local searchname searchnameNot;
%local matchlist;
%* Auxiliary variables for parameters POS, POSNOT and NOTPOS. They are necessary to parse
%* these parameters when any of those are equal to END, stating that the position of the
%* the KEY or of NOT is at the END of the variable name;
%local position _position_ _positionNot_ _pos_ _posNot_ _notPos_;
%* Boolean variables that state whether the keyword KEY is found in each name and whether
%* the conditions passed in the POS, POSNOT, NOT and NOTPOS parameters are satisfied;
%local found posBool posNotBool notBool notPosBool;
%* Replacement character to use for the first character in KEY in order to search for several
%* occurrences of KEY in each variable name;
%local replacement;

%* OLD: the replacement character is the next character in the ascii sequence. But this has
%* 2 inconveniences: the next character may not exist if the character to be replaced has
%* ascii code = 255, or they may be problems with the character replaced (if it is a very
%* strange character (I have not found this problem, I am just conjecturing);
/*%let replacement = %sysfunc(byte(%eval(%sysfunc(rank(%substr(&searchname, &position, 1)))+1));*/
%let replacement = ?;
%if %quote(%upcase(&key)) = %quote(%upcase(&replacement)) %then
	%let replacement = !;

%let nro_names = %GetNroElements(&list);
%let matchlist = ;
%do i = 1 %to &nro_names;
	%let name = %scan(%quote(&list), &i, ' ');

	%* Initialize boolean variables stating whether KEY is found and if it is found 
	%* at POSNOT position, and whether NOT keyword is found and if it is found at
	%* NOTPOS position;
	%let found = 0;
	%let posBool = 0;
	%let posNotBool = 0;
	%let notBool = 0;
	%let notPosBool = 0;

	%*** Translate input parameters to character positions in name;
	%if %upcase(&pos) = END %then
		%let _pos_ = %eval(%length(%quote(&name)) - %length(%quote(&key)) + 1);
	%else
		%let _pos_ = &pos;
	%if %upcase(&posNot) = END %then
		%let _posNot_ = %eval(%length(%quote(&name)) - %length(%quote(&key)) + 1);
	%else
		%let _posNot_ = &posNot;
	%if %upcase(&notPos) = END %then
		%let _notPos_ = %eval(%length(%quote(&name)) - %length(%quote(&not)) + 1);
	%else
		%let _notPos_ = &notPos;

	%*** Search for KEY in name;
	%let position = %index(%upcase(%quote(&name)), %upcase(%quote(&key)));
	%if &position > 0 %then %do;
		%let found = 1;
		%let posBool = 1;
		%* Check if KEY is found at position POS, because if this is not the case, the
		%* match should not be considered as such;
		%if &_pos_ > 0 %then %do;
			%let searchname = &name;
			%let _position_ = &position;
			%* Search for KEY in name until the end of the name is reached (&_position_ = 0) or
			%* until it is found at or after the position pos (&_position_ < &pos);
			%do %while (&_position_ > 0 and &_position_ < &_pos_);
				%* Replace in &searchname the first character of the keyword given in KEY with
				%* the next character in the ASCII code so that I can search for other occurrences
				%* of KEY in &name;
				%let searchname = %ReplaceChar(	&searchname,
												&_position_,
												&replacement
							 				   );
				%let _position_ = %index(%upcase(%quote(&searchname)), %upcase(%quote(&key)));
			%end;
			%if &_position_ ~= &_pos_ %then
				%let posBool = 0;	%* State that KEY was not found since it was not found at
									%* the position specified in POS. Therefore the match
									%* should not be considered as such;
		%end;
		%* Search for KEY occurring at position POSNOT, because if this is the case, the
		%* match should not be considered as such;
		%if &_posNot_ > 0 %then %do;
			%let searchname = &name;
			%let _position_ = &position;
			%* Search for KEY in name until the end of the name is reached (&_position_ = 0) or
			%* until it is found at or after the position posNot (&_position_ < &posNot);
			%do %while (&_position_ > 0 and &_position_ < &_posNot_);
				%* Replace in &searchname the first character of the keyword given in KEY with
				%* the next character in the ASCII code so that I can search for other occurrences
				%* of KEY in &name;
				%let searchname = %ReplaceChar(	&searchname,
												&_position_,
												&replacement
							 				   );
				%let _position_ = %index(%upcase(%quote(&searchname)), %upcase(%quote(&key)));
			%end;
			%if &_position_ = &_posNot_ %then
				%let posNotBool = 1;
		%end;
	%end;
	%*** Search for NOT keyword in name;
	%if %quote(&not) ~= %then %do;
		%let positionNot = %index(%upcase(%quote(&name)), %upcase(%quote(&not)));
		%* Search for NOT keyword occurring at position NOTPOS, because only when this
		%* happens should the match not be considered as a match;
		%if &positionNot > 0 %then %do;
			%let notBool = 1;
			%let notPosBool = 1;
			%if &_notPos_ > 0 %then %do;
				%let searchname = &name;
				%let _positionNot_ = &positionNot;
				%* Search for NOT keyword in name until the end of the name is reached
				%* (&_positionNot_ = 0) or until it is found at or after the position notPos
				%* (&_positionNot_ < &notPos);
				%do %while (&_positionNot_ > 0 and &_positionNot_ < &_notPos_);
					%* Replace in &searchname the first character of the keyword given in NOT with
					%* the next character in the ASCII code so that I can search for other occurrences
					%* of NOT keyword in &name;
					%let searchname = %ReplaceChar(	&searchname, 
													&_positionNot_, 
													&replacement
											 	   );
					%let _positionNot_ = %index(%upcase(%quote(&searchname)), %upcase(%quote(&not)));
				%end;
				%if &_positionNot_ ~= &_notPos_ %then
					%let notPosBool = 0;	%* State that the NOT keyword was not found since it
											%* was found at a position where it is ok to be found
											%* (because it is not the position specified with NOTPOS),
											%* and still consider the match as such;	
			%end;
		%end;
	%end;

	%*** Add name to matchlist only if all the conditions given in parameters POS, POSNOT, 
	%*** NOT and NOTPOS are satisfied;
	%if (%length(&key) = 0 or (&found and &posBool = 1 and &posNotBool = 0)) and
		(&notBool = 0 or &notPosBool = 0) %then
		%let matchlist = &matchlist &name;
%end;
%if &log %then %do;
	%if %quote(&key) = and %quote(&not) = %then
		%put FINDMATCH: Names present in the list passed;
	%else %if %quote(&key) ~= %then
		%put FINDMATCH: Names matching the keyword %upcase(&key) in the list passed;
	%else %if %quote(&not) ~= %then
		%put FINDMATCH: Names NOT containing the keyword %upcase(&not) in the list passed;
	%if %quote(&pos) ~= or %quote(&posNot) ~= or %quote(&not) ~= or %quote(&notPos) ~= %then %do;
		%put FINDMATCH: with additional matching options:;
		%put FINDMATCH: (pos=&pos, posNot=&posNot, not=&not, notPos=&notPos);
	%end;
	%let nvar = %GetNroElements(&matchlist);
	%if &nvar = 0 %then
		%put (Empty);
	%else
		%do i = 1 %to &nvar;
			%let vari = %scan(&matchlist, &i, ' ');
			%put &i: %upcase(&vari);
		%end;
%end;
&matchlist
%MEND FindMatch;
/********************************* %FindMatch, version 1.01 **********************************/


/******************************* %GetDataOptions, Version 1.00 *******************************/
%MACRO GetDataOptions(str) / store des="Extract the options passed in a data set specification";
%local options paren_pos;
%let paren_pos = %sysfunc(indexc(%quote(&str) , '('));
%if &paren_pos > 0 %then
	%let options = %substr(%quote(&str) , &paren_pos+1 , %eval(%length(%quote(&str)) - &paren_pos - 1));
%else
	%let options =;
&options
%MEND GetDataOptions;
/******************************* %GetDataOptions, Version 1.00 *******************************/


/******************************* %GetLibraryName, Version 1.00 *******************************/
%MACRO GetLibraryName(str) / store des="Extract the library name from a data set name";
%local library_name point_pos;
%let library_name = WORK;	%* Si no hay libname reference, devuelve WORK;
%let point_pos = %sysfunc(indexc(%quote(&str) , '.'));
%if &point_pos > 0 %then
	%let library_name = %scan(&str , 1 , '.');
&library_name
%MEND GetLibraryName;
/******************************* %GetLibraryName, Version 1.00 *******************************/


/**************************************** %GetNobs *******************************************/
%MACRO GetNobs(data,return=0,print=1,log=1) / store des="Get the number of observations and variables in a data set";

%local nobs nvar;
%let nobs = 0;	%*** These initializations are for the default in case the dataset does not exist;
%let nvar = 0;

%let data_id = %sysfunc(open(&data));
%if &data_id %then
   	%do;
       	%let nobs = %sysfunc(attrn(&data_id,NOBS));
       	%let nvar = %sysfunc(attrn(&data_id,NVARS));
       	%let rc   = %sysfunc(close(&data_id));%*** rc is just the return code of function close;
		%if (&print or &log) and ~&return %then
	 		%put &data has &nobs observation(s) and &nvar variable(s).;
   	%end;
%else
   	%put GETNOBS: %sysfunc(sysmsg());

%if &return %then
	&nobs &nvar;		%*** This statement returns the values to the outside world;

%MEND getnobs;
/**************************************** %GetNobs *******************************************/


/******************************* %GetNroElements, Version 2.02 *******************************/
%MACRO GetNroElements(list , sep=%quote( )) / store des="Get the number of names in a list";
%local i element nro_elements;

%let i = 0;
%do %until(%length(%quote(&element)) = 0);
	%let i = %eval(&i + 1);
	%let element = %scan(%quote(&list) , &i , %quote(&sep));
%end;
%let nro_elements = %eval(&i - 1);
&nro_elements
%MEND GetNroElements;
/******************************* %GetNroElements, Version 2.02 *******************************/


/********************************* %GetVarNames, Version 1.01 ********************************/
%MACRO GetVarNames(data , var=_ALL_) / store des="Get the variable names in a data set";
/*
NOTA: Lo que hace esta macro podria ser hecho con la macro %GetVarList, con la opcion
'var=_ALL_', por ej: %let varlist = %GetVarList(data, var=_ALL_);
Como yo ya habia creado esta macro %GetVarNames antes de haber modificado la macro %GetVarList
para que devolviera una macro variable (antes la habia hecho pero sin que devolviera una
macro variable, sino que creaba una macro variable dentro de la macro, sin devolverla), esta
macro %GetVarNames la dejo asi' como esta'.
*/
%local data_name dsid i nvars rc varnames vartype;

%let data_name = %scan(&data , 1 , '(');

%let dsid = %sysfunc(open(&data_name));				%*** Open dataset &data;
%if ~&dsid %then
   	%put GETVARNAMES: %sysfunc(sysmsg());
%else %do;
 	%let nvars = %sysfunc(attrn(&dsid,NVARS));
	%let varnames = ;
	%do i = 1 %to &nvars;
		%let vartype = %sysfunc(vartype(&dsid , &i));	%*** Type of variable in column &i. Either C or N;
		%if (%upcase(&vartype) = C and %quote(%upcase(&var)) = _CHAR_) or
			(%upcase(&vartype) = N and %quote(%upcase(&var)) = _NUMERIC_) or
			(%quote(%upcase(&var)) = _ALL_) %then
			%let varnames = &varnames %sysfunc(varname(&dsid , &i));
	%end;
	%let rc = %sysfunc(close(&dsid));
%end;
&varnames
%MEND GetVarNames;
/********************************* %GetVarNames, Version 1.01 ********************************/


/********************************** %MakeList, Version 1.18 **********************************/
%MACRO MakeList(namesList , prefix= , suffix= , sep=%quote( ) , nospace=0 , log=0) / store des="Create a list of names optionally adding a prefix and a suffix";
%local i list name nro_names space _var_;

%*** Getting the number of elements in &namesList;
%let i = 0;
%do %until(%length(%quote(&name)) = 0);
	%let i = %eval(&i + 1);
	%let name = %scan(&namesList , &i , ' ');
%end;
%let nro_names = %eval(&i - 1);

%*** Space or no space between separator and names;
%if &nospace %then
	%let space =;
%else %if %quote(&sep) ~= %then
	%let space = %quote( );	
	%** Only use an extra space in the separator if the separator is not already a space;

%if &nro_names > 0 %then %do;
	%do i = 1 %to &nro_names;
		%local var&i;
		%let var&i = %scan(&namesList , &i , ' ');
	%end;

	%let list = &prefix.&var1.&suffix;
	%do i = 2 %to &nro_names;
		%let _var_ = &&var&i;
		%let list = &list&space&sep&space&prefix.&_var_.&suffix;
	%end;
%end;
%else
	%let list = ;
%if &log %then %do;
	%put MAKELIST: The following list was created:;
	%put &list;
	%put;
%end;
&list
%MEND MakeList;
/********************************** %MakeList, Version 1.18 **********************************/


/******************************* %MakeListFromName, Version 1.05 *****************************/
%MACRO MakeListFromName(name , length= , start=1 , stop= , step= , prefix= , suffix= , sep=%quote( ) , log=0) / store des="Create a list of name from a name used as root";
%local i index list;

%* List is initialized as empty so that when an error occurs, the empty string is returned;
%let list = ;
%* Checking input parameters. Note that parameter name can be empty!;
%if not ((%quote(&start) ~= and %quote(&step) ~= and %quote(&length) ~=) or
		 (%quote(&start) ~= and %quote(&stop) ~= and %quote(&length) ~=) or
		 (%quote(&start) ~= and %quote(&step) ~= and %quote(&stop) ~=)) or
	 (%quote(&start) ~= and %quote(&step) ~= and %quote(&stop) ~= and %quote(&length) ~=) %then %do;
	%put MAKELISTFROMNAME: ERROR - The number of parameters passed is incorrect.;
	%put MAKELISTFROMNAME: Usage:;
	%put %nrstr(%MakeListFromName%();
	%put name ,;
	%put length= ,;
	%put start=1 ,;
	%put stop= ,;
	%put step=1 ,;
	%put prefix= ,;
	%put suffix= ,;
	%put sep=%quote( ) ,;
	%put log=0);
	%put One of the following combinations of parameter values must be passed:;
	%put START, STEP, LENGTH;
	%put START, STOP, LENGTH;
	%put START, STEP, STOP;
	%put and NOT all 4 parameters can be passed at the same time.;
%end;
%else %if %quote(&length) ~= and %sysevalf(&length <= 0) %then 
	%put MAKELISTFROMNAME: ERROR - The value of LENGTH is not positive.;
%else %if %quote(&step) ~= and %quote(&stop) ~= and
	((%sysevalf(&stop >= &start) and %sysevalf(&step <= 0)) or
	(%sysevalf(&stop < &start) and %sysevalf(&step >= 0))) %then
	%put MAKELISTFROMNAME: ERROR - The values of START=, STEP= and STOP= are inconsistent.;
%else %do;
	%let index = &start;
	%let list = &prefix.&&name.&start&suffix;
	%* Define the value of STEP since I always need it to construct the list;
	%if %quote(&step) = %then %do;
		%if &length > 1 %then
			%let step = %sysevalf((&stop - &start) / (&length - 1));
		%else
			%let step  = 0;
	%end;
	%if %quote(&stop) = %then
		%do i = 2 %to &length;
			%let index = %sysevalf(&index + &step);
			%let list = &list.&sep.&prefix.&&name.&index.&suffix;
		%end;
	%else
		%do %while ((%sysevalf(&step > 0) and %sysevalf(&index + &step <= &stop)) or
					(%sysevalf(&step < 0) and %sysevalf(&index + &step >= &stop)));
			%let index = %sysevalf(&index + &step);
			%let list = &list.&sep.&prefix.&&name.&index.&suffix;
		%end;
	%if &log %then %do;
		%put MAKELISTFROMNAME: The following list was created:;
		%put &list;
		%put;
	%end;
%end;
&list
%MEND MakeListFromName;
/******************************* %MakeListFromName, Version 1.05 *****************************/


/******************************* %MakeListFromVar, Version 1.01 ******************************/
%MACRO MakeListFromVar(data, var=, sep=%quote( ), log=1) / store des="Create a list containing the values of a column in a data set";
/*
NOTA: (23/11/04) Even though data options generally do not cause an error in the OPEN function,
no data options are accepted in the DATA parameter because one possible or common data option
would be a WHERE= option (to limit which values of the variable of interest to be read). However,
this option makes the returned value of the OPEN function be 0 (i.e. the dataset cannot be
opened).
*/
%local dsid rc;
%local i nobs;
%local fun varnum vartype;
%local cols concatenate firstobs lastobs;
%local list;

%* If SEP= is blank, redefine it as the blank space using function %quote;
%if %quote(&sep) = %then
	%let sep = %quote( );

%* Initialize the list to return (I do it here, before opening the input dataset, so that an
%* empty list is returned if an error occurs);
%let list = ;

%let dsid = %sysfunc(open(&data));
%if ~&dsid %then
	%put MAKELISTFROMVAR: ERROR - Input dataset %upcase(&data) does not exist.;
%else %do;
	%let nobs = %sysfunc(attrn(&dsid, nobs));
	%if %quote(&var) ~= %then %do;
		%let varnum = %sysfunc(varnum(&dsid, &var));
		%if &varnum = 0 %then
			%put MAKELISTFROMVAR: ERROR - Variable %upcase(&var) does not exist in dataset %upcase(&data).;
	%end;
	%else
		%let varnum = 1;
	%if &varnum > 0 %then %do;
		%let vartype = %sysfunc(vartype(&dsid, &varnum));
		%if %upcase(&vartype) = N %then
			%let fun = getvarn;
		%else
			%let fun = getvarc;

		%* Read the values of variable &var;
		%do i = 1 %to &nobs;
			%let rc = %sysfunc(fetchobs(&dsid, &i));
			%if &i = 1 %then
				%let list = %sysfunc(&fun(&dsid, &varnum));
			%else
		   		%let list = %sysfunc(compbl( %quote(&list &sep %sysfunc(&fun(&dsid, &varnum))) ));
				%** NOTE: Function COMPBL is used to avoid leaving more spaces than necessary
				%** between the names and/or between the separator and the names;
		%end;
	%end;
	%* Close dataset;
	%let rc = %sysfunc(close(&dsid));
%end;
%if &log %then %do;
	%put List of names returned:;
	%puts(%quote(&list), sep=%quote(&sep))
%end;

&list
%MEND MakeListFromVar;
/******************************* %MakeListFromVar, Version 1.01 ******************************/


/********************************** %Means, Version 1.09 *************************************/
%MACRO Means(data, 	out=, var=_numeric_, format=, where=, by=, id=, stat=, stats=, name=, names=, 
					prefix=, suffix=, weight=, noprint=1, options=, transpose=0, namevar=var, log=1) / store des="Run the MEANS procedure";
%local j k;
%local byst byvars formatst idst _name_ _newname_;
%local noprintst;
%local nro_byvars nro_cols nro_vars nro_stats out_library out_name out_options outputst;
%local _prefix_ _stat_ statst _suffix_ weightst wherest;
%local data_name varnames;
%local notes_option;
%local nobs nvars;	%*** Number of obs. and number of vars in output dataset;

%let notes_option = %sysfunc(getoption(notes));
options nonotes;

%* Remove keyword DESCENDING if it exists in parameter BY=. I store the list of
%* by variables in macro variable &byvars which is only used below in the KEEP=
%* option when reading in the input dataset;
%let byvars = %RemoveFromList(&by, descending, log=0);

%* Reading in input dataset;
data _Means_data_(keep=&byvars &id &var &weight);
	set &data;
run;

%*** Converting &var into a blank-separated list of variables;
%let nro_vars = %GetNroElements(&var);

%let formatst =;
%if %quote(&format) ~= %then
	%let formatst = format &format;

%let wherest =;
%if %quote(&where) ~= %then
	%let wherest = where &where;

%let byst =;
%if %quote(&by) ~= %then %do;
	%let byst = by &by;
	proc sort data=_Means_data_;
		&byst;
	run;
%end;

%let idst =;
%if %quote(&id) ~= %then
	%let idst = id &id;

%if %quote(&stats) ~= and %quote(&stat) = %then
	%let stat = &stats;
%if %quote(&names) ~= and %quote(&name) = %then
	%let name = &names;
%if %quote(&stat) ~= %then %do;
	%let nro_stats = %GetNroElements(&stat);
	%let statst =;
	%do j = 1 %to &nro_stats;
		%let _stat_ = %scan(&stat , &j , ' ');
		%let _name_ = ;
		%let _prefix_ = %scan(&prefix , &j , ' ');
		%let _suffix_ = %scan(&suffix , &j , ' ');
		%do k = 1 %to &nro_vars;
			%if %quote(&name) ~= %then
				%if %quote(&prefix) = and %quote(&suffix) = %then
					%let _newname_ = %scan(&name , %eval((&j-1)*&nro_vars + &k), ' ');
					%*** All names are explicitly specified;
				%else
					%let _newname_ = %scan(&name , &k , ' ');
					%*** The names are generated by the names specified in name= (as many as vars)
					%*** and the suffixes specified in suffix= (as many as stats requested);
			%else
				%if %quote(&prefix) ~= or %quote(&suffix) ~= %then %do;
					%let _newname_ = %scan(&var , &k , ' ');
					%*** Only generate the variable names for the stats if either name=, prefix or suffix=
					%*** options are specified. If none of these is specified, the names given to
					%*** the statistics variables are generated automatically with autoname;
				%end;
			%let _newname_ = &_prefix_&_newname_&_suffix_;
			%let _name_ = &_name_ &_newname_;
		%end;
		%let statst = &statst %str(&_stat_=&_name_);
	%end;
%end;
%else %do;
	%let stat = mean;
	%let nro_stats = 1;
	%let _name_ = ;
	%do k = 1 %to &nro_vars;
		%let _name_ = &_name_ %scan(&name , &k);
	%end;
	%let statst = %str(mean=&_name_);
%end;

%let weightst = ;
%if %quote(&weight) ~= %then
	%let weightst = weight &weight;

%let outputst =;
%let out_name = %scan(&out , 1 , '(');
%* Get the library name (because I use the output dataset name in a PROC DATASET statement and
%* if the output dataset name comes with a library name, there will be an error);
%let out_library = %GetLibraryName(&out_name);
%let out_options = %GetDataOptions(&out);
%if %quote(&out) ~= %then %do;
	%if &name = %then
		%let options = &options autoname;
	%let outputst = %str(output out=&out_name(&out_options drop=_TYPE_ _FREQ_) &statst / &options);
%end;
%else
	%let noprint = 0;

%let noprintst =;
%if %quote(&noprint) %then
	%let noprintst = noprint;

%* Restore notes option;
proc means data=_Means_data_ &stat &noprintst;
	&formatst;
	&wherest;
	&byst;
	&idst;
	var &var;
	&weightst;
	&outputst;
run;

%*** Transposing the output dataset so that it shows the results as they appear on the screen;
%if %quote(&out) ~= and &transpose %then %do;
	%let nro_byvars = %GetNroElements(&by);
	%let nro_cols = %eval(&nro_vars*&nro_stats);
	%let varnames = %GetVarNames(&out_name);
	%if %quote(&by) ~= %then %do;
		%let varnames = %RemoveFromList(&varnames, &by, log=0);
	%end;
	%* Read label stored in the &out dataset;
	proc contents data=&out_name out=_Means_contents_(keep=memlabel) noprint;
	run;
	data _Means_contents_;
		set _Means_contents_(obs=1);
		call symput ('label', trim(left(memlabel)));
	run;
	data _Means_out_(label="&label");
		format &by &namevar &stat;
		set &out_name;
		array _cols_ &varnames;		%*** Column names in the output dataset to be transposed;
		array _newcols_ &stat;		%*** Column names in the transposed dataset;
		do _indvar_ = 1 to &nro_vars;					%*** Cycle over the variables;
			&namevar = scan("&var", _indvar_, ' ');		%*** Get current variable name;
			do _indstat_ = 1 to &nro_stats;				%*** Cycle over the statistics requested;
				_newcols_(_indstat_) = _cols_(&nro_vars*(_indstat_ - 1) + _indvar_);
			end;
			output;
		end;
		keep &by &namevar &stat;
	run;

	%if %quote(%upcase(&out_library)) = WORK %then %do;
		proc datasets nolist;
			%if %index(&out_name, .) > 0 %then %do;
			delete %scan(&out_name, 2, '.');	%* Remove the library name (WORK) if it exists in the output dataset name;
			%end;
			%else %do; 
			delete &out_name;
			%end;
			change _Means_out_ = &out_name;
		quit;
	%end;
	%else %do;
		data &out_name(label="&label");
			set _Means_out_;
		run;
		proc datasets nolist;
			delete _Means_out_;
		quit;
	%end;
%end;

%if %quote(&out) ~= and &log %then %do;
	%callmacro(getnobs, &out_name return=1, nobs nvars);
	%put;
	%put MEANS: Dataset %upcase(&out_name) created with &nobs observations and &nvars variables.;
	%put;
%end;

proc datasets nolist;
	delete 	_Means_data_
			_Means_out_
			_Means_contents_;
quit;
options &notes_option;
%MEND Means;
/********************************** %Means, Version 1.09 *************************************/


/********************************** %Puts, Version 1.00 **************************************/
%MACRO Puts(list, sep=%quote( )) / store des="Show a list of names in the log, one name per line";
%local i nro_vars maxlength;
%let nro_vars = %GetNroElements(%quote(&list), sep=%quote(&sep));
%if &nro_vars > 0 %then %do;
	%* Maximum length of the numbers to be shown on the left hand side of the list indexing the names
	%* so that the names can be shown aligned on the same column;
	%let maxlength = %length(&nro_vars);
	%do i = 1 %to &nro_vars;
		%put &i: %rep(,%eval(&maxlength - %length(&i)))%scan(%quote(&list), &i, %quote(&sep));
	%end;
%end;
%else
	%put (Empty);
%MEND Puts;
/********************************** %Puts, Version 1.00 **************************************/


/*********************************** %Rep, Version 1.00 **************************************/
%MACRO Rep(name, times) / store des="Create a list with a name repeated a given number of times";
%local i list;

%let list = ;
%do i = 1 %to &times;
	%if %quote(&name) ~= %then
		%let list = &list &name;
	%else
		%let list = &list%quote( );
%end;

&list
%MEND Rep;
/*********************************** %Rep, Version 1.00 **************************************/


/******************************* %ReplaceChar, Version 1.00 **********************************/
%MACRO ReplaceChar(name, pos, char) / store des="Replace a character in a name at a given position";
%local newname;

%if &pos = 1 %then %do;
	%** The first character in NAME is replaced;
	%let newname = &char%substr(&name, %eval(&pos+1));
%end;
%else %if &pos = %length(&name) %then %do;
	%** The last character in NAME is replaced;
	%let newname = %substr(&name, 1, %eval(&pos-1))&char;
%end;
%else %do;
	%** A middle character in NAME is replaced;
	%let newname = %substr(&name, 1, %eval(&pos-1))&char%substr(&name, %eval(&pos+1));
%end;
&newname
%MEND ReplaceChar;
/******************************* %ReplaceChar, Version 1.00 **********************************/


/********************************* %SelectVar, Version 1.03 **********************************/
%MACRO SelectVar(data, key=, pos=, posNot=, not=, notPos=, log=1) / store des="Select variables from a data set whose names match a set of conditions";
%local data_id i nvar rc vari;
%local list matchlist;

%let data_id = %sysfunc(open(&data));
%if ~&data_id %then
	%put SELECTVAR: ERROR - Dataset %upcase(&data) does not exist.;
%else %if %quote(&key) = %then
	%put SELECTVAR: ERROR - No keyword to search for was passed as second parameter.;
%else %do;
	%let list = ;
    %let nvar = %sysfunc(attrn(&data_id, nvars));
	%do i = 1 %to &nvar;
		%let list = &list %sysfunc(varname(&data_id, &i));
	%end;
    %let rc = %sysfunc(close(&data_id));
	%let matchlist = %FindMatch(&list, key=&key, pos=&pos, posNot=&posNot, not=&not, notPos=&notPos, log=0);
%end;
%if &log %then %do;
	%put SELECTVAR: List of variables in dataset %upcase(&data);
	%put SELECTVAR: containing keyword %upcase(&key);
	%if %quote(&pos) ~= or %quote(&posNot) ~= or %quote(&not) ~= or %quote(&notPos) ~= %then %do;
		%put SELECTVAR: and additional options: (pos=&pos, posNot=&posNot, not=&not, notPos=&notPos);
	%end;
	%let nvar = %GetNroElements(&matchlist);
	%if &nvar = 0 %then
		%put (Empty);
	%else
		%do i = 1 %to &nvar;
			%let vari = %scan(&matchlist, &i, ' ');
			%put &i: %upcase(&vari);
		%end;
%end;
&matchlist
%MEND SelectVar;
/********************************* %SelectVar, Version 1.03 **********************************/


/****************************** %RemoveFromList, Version 1.05 ********************************/
%MACRO RemoveFromList(namesList, names, sep=%quote( ), allOccurrences=1, log=1)
	/ store des="Removes specified names from a list of names";
	%*** NOTE: In this macro, I use the expression %quote(%upcase(...)) when parsing
	%*** some input parameter such as &namesList. The order of these functions is important.
	%*** That is, first comes %quote and then comes %upcase.
	%*** This is because %upcase still works when there are special characters such as
	%*** comma, whereas the function where the result of the above expression is used
	%*** may not work;
%local i j k found;
%local match match_orig;
%local list name namei names_new nro_names nro_names_orig nro_namesInList;

%* If SEP= is blank, redefine it as the blank space using function %quote;
%* This is necessary for the %scan function to work properly;
%if %quote(&sep) = %then
	%let sep = %quote( );

%* Number of names present in the list of names 'namesList';
%let nro_namesInList = %GetNroElements(%quote(&namesList), sep=%quote(&sep));
%* Names and Nro. of names present in the list of names to remove (NAMES=);
%let names_orig = &names;	%* names_orig is used because &names may be updated during the 
							%* removal process in case ALLOCCURRENCES=0.
							%* The information about the original list in &names is used only
							%* for informational purposes (at the end of the macro the names
							%* listed in &names that were not found in &namesList is informed);
%let nro_names_orig = %GetNroElements(%quote(&names_orig), sep=%quote(&sep));

%* Array containing a list of 0s and 1s which indicate if each of the names listed in &names
%* was found or not found in the list (0 => Not Found, 1 => Found);
%let found = ;
%do i = 1 %to &nro_names_orig;
	%let found = &found.0;
%end;

%let nro_names = &nro_names_orig;
%** The use of nro_names and nro_names_orig is necessary because the number of names in &names
%** may change in the following loop when ALLOCCURRENCES=0. This is information is only used
%** for informational purposes at the end of the macro;
%do i = 1 %to &nro_namesInList;
	%let name = %scan(%quote(&namesList), &i, %quote(&sep));
	%*** Search for &name in &names and remove it from &list if it is found;
	%let match = %FindInList(%quote(&names), %quote(&name), sep=%quote(&sep), log=0);
	%if &match = 0 %then %do;
		%* If the name was not found in the list of names to remove, 
		%* add it to the output list (&list);
		%if %quote(&list) = %then
			%let list = &name;
		%else
			%let list = &list &sep &name;
	%end;
	%else %do;
		%* Update array &FOUND by replacing the 0 with 1 at the position indicated by &match
		%* so that we can show at the end which names listed in &names were found in the list
		%* and which were not found;
		%* When ALLOCCURRENCES=0, first I need to search for &name in the original list of
		%* &names (&names_orig) so that the proper index in the array &found is identified.
		%* This is because the list in &names may change when ALLOCCURRENCES=0, since the
		%* name already found is removed from &names;
		%if ~&allOccurrences %then %do;
			%let match_orig = %FindInList(%quote(&names_orig), %quote(&name), sep=%quote(&sep), log=0);
		%end;
		%else
			%let match_orig = &match;
		%if &match_orig > 1 and &match_orig < &nro_names_orig %then
			%let found = %substr(&found, 1, %eval(&match_orig-1))1%substr(&found, %eval(&match_orig+1));
		%else %if &match_orig = 1 and &match_orig < &nro_names_orig %then
			%let found = 1%substr(&found, %eval(&match_orig+1));		%* The name found is the first one in &names_orig;
		%else %if &match_orig > 1 and &match_orig = &nro_names_orig %then
			%let found = %substr(&found, 1, %eval(&match_orig-1))1;	%* The name found is the last one in &names_orig;
		%else
			%let found = 1;	%* There is only one name in &names_orig;

		%* In case only the first occurrence found is to be removed, remove the name found
		%* from &names so that future occurences of &name in &namesList are not removed;
		%if ~&allOccurrences %then %do;
			%let names_new = ;
			%do k = 1 %to &nro_names;
				%if &k ~= &match %then %do;
					%if %quote(&names_new) = %then
						%let names_new = %scan(%quote(&names), &k, %quote(&sep));
					%else
						%let names_new = &names_new &sep %scan(%quote(&names), &k, %quote(&sep));
				%end;
			%end;
			%* Update list of names to be removed (&names) and &nro_names;
			%let names = &names_new;
			%let nro_names = %GetNroElements(%quote(&names), sep=%quote(&sep));
		%end;
	%end;
%end;

%* Remove unnecessary blanks from the output list;
%let list = %sysfunc(compbl(%quote(&list)));

%* Give information to the user;
%if &log %then %do;
	%* List of names given in &names that were not found in the list;
	%do i = 1 %to &nro_names_orig;
		%if %substr(&found, &i, 1) = 0 %then
			%put REMOVEFROMLIST: WARNING - The name %upcase(%scan(%quote(&names_orig), &i, %quote(&sep))) was not found in the list.;
	%end;

	%* List of names kept in the list;
	%put REMOVEFROMLIST: List of names kept in the list:;
/*	%puts(%quote(&list), sep=%quote(&sep));*/	/* NO SE POR QUE ESTO GENERA ERRORES EN EL LOG!! */
	%let nro_names = %GetNroElements(%quote(&list), sep=%quote(&sep));
	%if &nro_names > 0 %then
		%do i = 1 %to &nro_names;
			%let namei = %scan(%quote(&list), &i, %quote(&sep));
			%put &i: %upcase(&namei);
		%end;
	%else
		%put (Empty);
%end;
&list
%MEND RemoveFromList;
/****************************** %RemoveFromList, Version 1.05 ********************************/
