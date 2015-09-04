/* MACRO %Categorize
Version: 	1.10
Author: 	Daniel Mastropietro
Created: 	27-Feb-2003
Modified: 	27-Aug-2015 (previous: 13-Aug-2015)

DESCRIPTION:
Categorizes a set of variables in terms of one of the following specifications:
- Number of wished categories or groups
- Specified percentile values
- Number of cases in each category or group
Note that this macro extends the capabilities of PROC RANK, as this procedure cannot
handle the second option for categorization listed above (i.e. categorization at specified
percentiles values). The other two options are handled by PROC RANK with no problems. 

USAGE:
%Categorize(
	data, 			*** Input dataset.
	var=_NUMERIC_,	*** Lista de variables numéricas a categorizar.
	out=,			*** Output dataset con las variables categorizadas.
	condition=,		*** Condición que deben cumplir los valores de CADA variable para ser
					*** incluida en la categorización.
	alltogether=1,	*** Dice si los valores excluidos por CONDITION= se juntan todos en
					*** una categoría (=1) o se genera una categoría para cada valor (=0).
	varcat=,		*** List of names to be used for the categorized variables.
	varvalue=,		*** List of names to be used for the statistic-valued categorized variables
						to be matched one-to-one with the variables listed in VAR=
	suffix=_cat,	*** Sufijo a usar para las variables categorizadas.
	value=,			*** Statistic a usar para el valor de cada categoría (mean, median,...).
	both=,			*** Categorizar tanto con valores reales y discretos
						(1, 2, ...) (=1), o solo con discretos (=0)?
	groupsize=,		*** Tamaño de cada grupo de la categorización.
	groups=10,		*** Número de grupos en los que efectuar la categorización.
	percentiles=, 	*** Percentiles a usar para la categorización.
	descending=0,	*** Should the percentile values be applied to the descending values of the variables?
	log=1);			*** Mostrar mensajes en el log?

El parámetro value puede ser cualquier estadístico válido en PROC MEANS, o bien
nada, para indicar que use números enteros sucesivos.

REQUIRED PARAMETERS:
- data:			Input dataset. Puede recibir cualquier opción adicional como
				en cualquier opción data= de SAS.

OPTIONAL PARAMETERS:
- var:			Lista de las variables numéricas a categorizar, separadas por blancos.
				default: _NUMERIC_ (es decir todas las variables numéricas)

- out:			Output dataset conformado por las variables del input dataset
				a las que se les agregan las variables categorizadas.
				El número de variables categorizadas y sus valores dependen 
				de los parámetros 'value' y 'both', como sigue:
				- si 'value' es vacío, both=0: se genera una variable categorizada para cada variable,
				con números enteros identificando cada categoría: 1 para la categoría
				correspondiente a los valores más bajos, 2 para la siguiente, y así
				siguiendo (Nota: alguno de los valores puede saltearse en caso de que
				la variable original tenga valores repetidos)
				- si 'value' NO es vacío, both=0: se genera una variable categorizada para cada
				variable, con valores identificatorios de cada categoría que son calculados
				a partir del método indicado en 'value'. Por ejemplo si value=mean, el identificador
				de cada categoría es el promedio de los valores de la variable original en la
				categoría correspondiente.
 				- si 'value' NO es vacío, both=1: se generan dos tipos de variables categorizadas,
				para cada variable: una contiene valores identificatorios de las categorías que
				son los mismos que son usados cuando 'value' es vacío, y la segunda contiene
				valores identificatorios de las categorías que son los mismos que son usados
				cuando 'value' NO es vacío.
				
				Los nombres de las variables categorizadas se arman a partir del nombre de
				la variable original más el sufijo indicado en 'suffix'. En caso de que
				both=1, los dos tipos de variables categorizadas se distinguen agregando el sufijo
				'_' seguido del valor de 'value'.
				Ej: si suffix=_c, value=mean, both=1 y var=x, se generan las variables
				categorizadas: x_c y x_c_mean.
				Notar que si el parámetro 'suffix' es vacío, las variables originales
				que son categorizadas por esta macro son reemplazadas por las variables
				categorizadas. Esto puede ser útil cuando se genera un nuevo dataset.

- condition:	Condition to be applied to each variable being categorized in order to be
				included in the categorization process.
				It should be given in form of a right-hand side expression of a WHERE condition
				expression.
				Ex: ~= 0

- alltogether:	Whether the values excluded from the categorization process because of
				the CONDITION specification should be left as is in the output dataset
				or grouped all together into a single category.
				When alltogether = 1 and statistic-valued categorized variables are
				requested with the VALUE= parameter, the representative value stored for
				the single group containing all the excluded values takes into account
				the possibly different NUMBER OF CASES where the input variable takes
				each of the excluded values. For example, if VALUE=mean, then the
				representative value stored in the statistic-valued categorized variable
				is the mean of the excluded cases, which is equivalent to computing the
				WEIGHTED average of each excluded value (i.e. weighted by the number of
				cases where the input variable takes each of the excluded values).
				default: 1

- varcat:		List of names to be used for the integer-valued categorized variables.
				This parameter is useful when any of the input variables has a long name
				making infeasible the attachment of SUFFIX to the original variable name
				because the name of the categorized variable results in a name that is longer
				than 32 characters.
				If both VARCAT and SUFFIX parameters are specified, whenever possible the
				names in the VARCAT parameter will be matched one-to-one with the names listed
				in the VAR parameter. If the number of variables specified in the VARCAT
				parameter is smaller than the number of variables given in the VAR parameter,
				then the SUFFIX value is used to construct the categorized variable names
				for the remaining variables listed in VAR not matching a name in VARCAT.

- varvalue:		List of names to be used for the statistic-valued categorized variables to
				be matched one-to-one with the names listed in the VAR parameter.
				If the number of variables specified in the VARVALUE parameter is smaller
				than the number of variables given in the VAR parameter, then the usual
				processed based on SUFFIX and VALUE (see below when describing parameter VALUE)
				will be used to construct the categorized variable names for the
				remaining variables listed in VAR not matching a name in VARVALUE.

- suffix:		Sufijo a usar para nombrar las variables categorizadas, a partir
				de las variables originales.
				Si su valor es vacío, las variables transformadas tienen el mismo
				nombre que las variables originales. Tengase en cuenta sin embargo, que en
				este caso se crea una variable temporaria en el input dataset con el
				sufijo '_', por lo que cualquier variable que coincida con el
				nombre de alguna de las variables que se estan categorizando mas
				el sufijo '_' es sobreescrita.
				In addition, SUFFIX is set to empty when the user requests only the
				statistic-valued categorized variables, via the VALUE= parameter and
				BOTH=0 option.
				default: _cat

- value:		Value to use for the statistic-based categorized variables.
				Any statistic keyword valid in PROC MEANS is accepted.
				(e.g. mean, median, q3, etc.)
				If VALUE= is empty (default), the values assigned to the categorized
				variables are consecutive integer numbers between 1 and the number of
				requested groups or categories.
				The name of the variables containing the statistic requested by this
				parameter (a.k.a. statistic-valued categorized variables) are formed by adding
				the suffix _&VALUE to either the suffix specified in parameter SUFFIX
				or to the name specified in the VARCAT= parameter for the corresponding variable.
				Ex 1: if VALUE=mean and SUFFIX=_cat, the new variables containing the mean
				of the categorized variable in each group is:  <variable-name>_CAT_MEAN
				Ex 2: if VALUE=median and VARCAT=x_grouped, the new variable containing the median
				of the categorized variable in each group is: x_grouped_median

- both:			Flag indicating whether two categorized variables should be retained
				in the output dataset for each analyzed variable:
				- an integer-valued categorized variable (IV)
				- a statistic-valued categorized variable (SV) 
				where IV uses consecutive integer values from 1 to the number of groups
				as categories for the categorized variable,
				and SV uses the value resulting from computing the statistic specified
				in parameter VALUE to each group of the IV categorized variable.
				Possible values: 0, 1, which imply the following, depending on the value of
				parameter VALUE=:
				(a) BOTH=0 and VALUE is empty 	=> Only IV is stored
				(b) BOTH=0 and VALUE not empty	=> Only SV is stored
				(c) BOTH=1 and VALUE is empty 	=> IV and SV are stored (the MEAN is used
												as statistic for the SV value)
				(d) BOTH=1 and VALUE not empty 	=> IV and SV are stored (the statistic
												specified by VALUE= is used for the SV value) 

- groupsize:	Tamaño de cada grupo de la categorización.
				Esta opción tiene prevalencia sobre groups= y percentiles=.
				Si no es posible generar todos los grupos de tamaños iguales, el último
				grupo (último de acuerdo al orden de los valores de la variable a categorizar)
				que resultaría más chico que los demás, se une al ante-último.
				*** NOTA ***: Ver seccion NOTES abajo sobre la diferencia entre usar la opción
				GROUPSIZE= y usar la opción GROUPS= o PERCENTILES=.

- groups:		Número de grupos en los que se DESEA categorizar cada variable.
				Cada grupo se define a partir de percentiles equidistantes, tantos como
				grupos haya. Por ej., si groups=5 los percentiles usados para categorizar
				las variables son 20 40 60 80 100.
				*** NOTA ***: Ver seccion NOTES abajo sobre la diferencia entre usar la opción
				GROUPSIZE= y usar la opción GROUPS= o PERCENTILES=.
				default: 10 (es decir se utilizan los percentiles 10 20 ... 100)

- percentiles:	Valores de los percentiles utilizados para categorizar las variables
				regresoras.
				Tiene preferencia sobre el parámetro groups, en el sentido de que si
				los dos son pasados, se toma el valor de 'percentiles' y no de 'groups'.
				Notas:
				- Si el ultimo valor pasado como percentil no es 100, el percentil 100 es
				agregado asi no queda ningun valor de la variable sin categorizar.
				- Ver seccion NOTES abajo sobre la diferencia entre pasar la opción
				GROUPSIZE= y pasar la opción GROUPS= o PERCENTILES=.

- descending:	Whether the percentile values should be applied to the descending values
				of the variables.
				This has an impact only when the percentile values are not equally spaced
				between 0 and 100. For example, the values 6%, 12%, ..., 96%, 100% are not
				equally spaced as the last interval has size 4%. If DESCENDING=1, the
				percentile values used to compute the categories of each variable are:
				4%, 8%, ..., 94%, 100%, that is the interval having size 4% is now the first
				interval, that is the first 4% LARGEST values of the variable will be part
				of the first category or group.
				default: 0

- log:			Indica si se desea ver mensajes en el log generados por la macro.
				Valores posibles: 0 => No, 1 => Sí.
				default: 1

NOTES:
1.- TRATAMIENTO DE VALORES REPETIDOS
En caso de que haya valores repetidos de la variable a categorizar, los resultados
obtenidos con la especificación del parámetro GROUPSIZE= y con la especificación del parámetro
GROUPS= o PERCENTILES= no va a ser necesariamente la misma.

De hecho:
- La opción GROUPSIZE= fuerza el tamaño de los grupos al tamaño especificado, con lo
que si la variable presenta muchos valores repetidos, seguramente habrá valores de la variable
original que correspondan a dos grupos distintos, por el simple hecho de que si correspondiesen
a un mismo grupo, el grupo tendría más observaciones que las especificadas en groupsize=.
Sin embargo, en estos casos, el hecho de que una observación pertenezca a un grupo y que otra
observación con el mismo valor pertenezca a otro grupo, es arbitraria...!

- Las opciones GROUPS= y PERCENTILES= en cambio especifican un número DESEADO de grupos
para la variable categorizada, pero no garantizan que exista exactamente ese número de grupos.
De hecho, todos los valores repetidos van a corresponderse con el MISMO grupo. Por ejemplo si la
variable a categorizar tiene solamente 3 valores distintos y groups=10, la variable categorizada
va a tener solamente 3 valores.
Este requerimiento hace que, en caso de que el parámetro 'value' sea vacío, algunas categorías
pueden faltar, de manera que los identificadores de las distintas categorías no sean números
enteros consecutivos. Por ejemplo, si una variable tiene 100 observaciones no missing, de las
cuales 20 tienen el valor 1.3, 35 el valor 7.2 y el resto el valor 8.4, las categorías generadas
al solicitar groups=10, son las siguientes:
var    categoría
1.3 -> 1
7.2 -> 3
8.4 -> 6

2.- TRATAMIENTO DE MISSING
Missing values are left as missing and are not counted as a separate group. This is to emulate
how PROC RANK treats missing values (they are left as missing).

3.- LIMITATIONS TO THE NAMES OF THE VARIABLES BEING CATEGORIZED
Because of the SUFFIX added to the original variable names to form the categorized variable names
the names of the variables to be categorized cannot be longer than 32 - (length-of-suffix).
In the best case, the suffix passed by the user can be set to an empty value; however in that case
a temporary variable whose name is the original variable name being categorized plus the suffix '_'
is created by the process. Therefore the absolute limitation to the names of the variables being
categorized is 31.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Callmacro
- %CheckInputParameters
- %Getnobs
- %GetVarList
- %MakeList
- %MakeListFromName
- %RemoveRepeated

EXAMPLES:
1.- %Categorize(test , out=test_cat , var=x z , both=1 , groups=100);
Crea el dataset test_cat a partir del dataset test al que se le agregan las variables
x_c, z_c, x_c_mean y z_c_mean. Las variables x_c y z_c tienen valores enteros entre 1
y 100 que indican alguna de las 100 posibles distintas categorias para las variables
x y z definidas por sus respectivos percentiles 1%, 2%, ... , 99% y 100%.
Es decir el grupo x_c = 1 corresponde a las observaciones con valor de x entre su
mínimo valor y su percentil 1%, el grupo x_c = 2 corresponde a las observaciones con
valor de x entre su percentil 1% y su percentil 2%, etc.
Al pasar el parámetro both=1, también se crean las variables x_c_mean y z_c_mean que se
obtienen de la misma manera que x_c y z_c, con la diferencia de que sus valores están
dados respectivamente por el valor medio de x y z en cada una de las categorías.

2.- %Categorize(test , var=x z , suffix=_c , groups=4);
En el dataset test agrega las variables x_c, z_c con las variables x, z categorizadas
en 4 grupos (representados respectivamente por los valores 1, 2, 3, 4), generados a
partir de los percentiles 25%, 50%, 75% y 100%. 
Es decir el grupo x_c = 1 corresponde a las observaciones con valor de x entre su mínimo
valor y su percentil 25%, el grupo x_c = 2 corresponde a las observaciones con valor de x
entre su percentil 25% y su percentil 50%, etc.

3.- %Categorize(test , var=x z , value=median , suffix=_c , both=0, percentiles=25 50 75 100);
Idem (2), pero ahora los valores representativos de cada grupo no son los números del
1 al 4, sino los valores medianos de las variables en cada grupo de categorización.
Los nombres de las variables categorizadas que contienen dicha información son:
x_c_median z_c_median

4.- %Categorize(test, var=x z, groupsize=10);
Categoriza las variables X y Z en el dataset TEST en grupos que contienen exactamente
10 observaciones cada uno, salvo tal vez la categoría correspondiente a los valores más
grandes de la variable que es categorizada, que puede tener más de 10 observaciones, en
caso de que el número total de valores no missing de la variable no sea exactamente un
múltiplo de 10.
Las variables categorizadas se almacenan en las variables X_CAT y Z_CAT

5.- %Categorize(test, var=verylongvariablename longvarname, both=0, varvalue=verylongvariablename);
Because of long variable names, the name for the statistic-valued categorized variables
is given via the VARVALUE= parameter, but just for the first analyzed variable, VERYLONGVARIABLENAME.
The statistic-valued categorized variable for the second variable (LONGVARNAME) instead is assigned
the usual name constructed by adding the statistic keyword as suffix: LONGVARNAME_mean, since
the default statistic to use is the MEAN.
*/
&rsubmit;
%MACRO Categorize(	data,
					var=_NUMERIC_,
					out=,

					condition=,
					alltogether=1,

					varcat=,
					varvalue=,
					suffix=_cat, 
					value=, 
					both=, 
					groupsize=,
					groups=10,
					percentiles=,
					descending=0,

					log=1,
					help=0) / store des="Categorizes continuous variables based on percentile values";

/*----- Macro to display usage -----*/
%MACRO ShowMacroCall;
	%put CATEGORIZE: The macro call is as follows:;
	%put %nrstr(%Categorize%();
	%put data , (REQUIRED) %quote(      *** Input dataset.);
	%put var=_NUMERIC_ , %quote(        *** List of variables to categorize.);
	%put out= , %quote(                 *** Output dataset with categorized vairables.);
	%put condition= , %quote(           *** Condition that must be satisfied by the variable values);
	%put %quote(                        *** to be included in the analysis.);
	%put alltogether=1 , %quote(        *** Whether the values excluded by parameter CONDITION= should);
	%put %quote(                            be put all together into the same category or should be put into);
	%put %quote(                            different categories, one for EACH excluded value.);
	%put varcat= , %quote(              *** List of integer-valued categorized variable names.);
	%put varvalue= , %quote(            *** List of statistic-valued categorized variable names.);
	%put suffix=_cat , %quote(          *** Suffix to use for the categorized variables.);
	%put value= , %nrquote(               *** Statistic to use to compute the value of the categories);
	%put %nrquote(                            %(ex: mean, median%));
	%put both= , %nrquote(                *** Make 1 (both=0) or 2 (both=1) categorizations for each variable?);
	%put %nrquote(                            %(2 categorizations means using both natural numbers and);
	%put %nrquote(                            the values computed by the statistic specified in value=%));
	%put groupsize= , %quote(           *** Size of each category. This is EXACT except for the largest category.);
	%put groups=10 , %quote(            *** Nro. of DESIRED groups to use in the categorization.);
	%put percentiles= , %quote(         *** Percentiles to use in the categorization.);
	%put descending=0 , %quote(         *** Should the percentile values be applied to the descending valuues of the variables?);
	%put log=1) %quote(                 *** Show messages in log?);
%MEND ShowMacroCall;

%if &help %then %do;
	%ShowMacroCall;
%end;
%else %if ~%CheckInputParameters(data=&data , var=&var , macro=CATEGORIZE) %then %do;
	%ShowMacroCall;
%end;
%else %do;
/************************************* MACRO STARTS ******************************************/
/* Local variables declaration */
%local nobs nro_percentiles pctlname pctlpre percentiles_rev;
%local out_name;		%* out_name is only used to show messages in the log;
%local dropst outst _var_ _varcat_ _name_;
%local var_order;		%* Variables in the input dataset listed in the order they appear;
%local i j nro_vars;
%local nro_groups;		%* Nro. of complete groups (used when groupsize= is not empty);
%local suffixValue;		%* Suffix for the variables categorized with the statistic given by &value;
%local dkricond;		%* Store dkricond option (Drop Keep Rename Input Condition) in order to restore it after it is changed;
%local dkricond;		%* Store dkrocond option (Drop Keep Rename Output Condition) in order to restore it after it is changed;
%local error;

%* Showing input parameters;
%if &log %then %do;
	%put;
	%put CATEGORIZE: Macro starts;
	%put;
	%put CATEGORIZE: Input parameters:;
	%put CATEGORIZE: - Input dataset = %quote(&data);
	%put CATEGORIZE: - var = %quote(          &var);
	%put CATEGORIZE: - out = %quote(          &out);
	%put CATEGORIZE: - condition = %quote(    &condition);
	%put CATEGORIZE: - alltogether = %quote(  &alltogether);
	%put CATEGORIZE: - varcat = %quote(       &varcat);
	%put CATEGORIZE: - varvalue = %quote(     &varvalue);
	%put CATEGORIZE: - suffix = %quote(       &suffix);
	%put CATEGORIZE: - value = %quote(        &value);
	%put CATEGORIZE: - both = %quote(         &both);
	%put CATEGORIZE: - groupsize = %quote(    &groupsize);
	%put CATEGORIZE: - groups = %quote(       &groups);
	%put CATEGORIZE: - percentiles = %quote(  &percentiles);
	%put CATEGORIZE: - descending = %quote(   &descending);
	%put CATEGORIZE: - log = %quote(          &log);
	%put;
%end;

%* Store the dkricond option for later reset;
%let dkricond = %sysfunc(getoption(dkricond));
%let dkrocond = %sysfunc(getoption(dkrocond));
%SetSASOptions;
/*--------------------------- Parsing input parameters --------------------------------------*/
%*** OUT=;
%if %quote(&out) = %then %do;
	%let out = %scan(&data , 1 , '(');
	%let out_name = &out;
%end;
%else
	%let out_name = %scan(&out , 1 , '(');

%*** GROUPSIZE=, GROUPS=, PERCENTILES=;
%* Note that always the PERCENTILE=100 is present in the list of percentiles, so that there is
%* no value left out when categorizing the variables;
%if &groupsize = %then %do;
	%if %quote(&percentiles) = %then
		%if &groups ~= %then
			%let percentiles = %MakeListFromName( , length=&groups , start=%sysevalf(100/&groups) , stop=100);
		%else
			%let percentiles = %MakeListFromName( , length=10 , start=10 , stop=100);
	%else
		%let percentiles = %RemoveRepeated(&percentiles 100, log=0);
%end;
%* DM-2012/06/17: Moved the calculation of &NRO_PERCENTILES from inside the block defined by %IF &GROUPSIZE = %THEN %DO to here
%* since now I need this value to reverse the percentile values in case DESCENDING=1;
%let nro_percentiles = %GetNroElements(&percentiles);
%if &descending %then %do;
	%* If the percentile values should be applied to the descending values of the variables, we should use a new
	%* set of percentile values given by (100 - percentile(i)) on the original variables in order to compute the
	%* desired percentiles. Thus if the percentiles are 6%, 12%, ..., 96%, 100% and DESCENDING=1, the new percentiles
	%* to use on the original variables are: 4%, 8%, ..., 94%, 100%;
	%let percentiles_rev = ;
	%do i = 1 %to (&nro_percentiles-1);
		%let percentiles_rev = &percentiles_rev %sysevalf(100 - %scan(&percentiles, %eval(&nro_percentiles-&i), ' '));
	%end;
	%* Replace the original values of PERCENTILES and add the 100 value (which was removed when reversing the percentile values in the loop);
	%let percentiles = &percentiles_rev 100;
%end;

%*** BOTH=, VALUE=;
%* DM-2012/06/17-START: Added new logic for parameter BOTH and VALUE;
%* The idea is that if VALUE is given but BOTH is empty, then set BOTH=1
%* (the logic is: why would a user pass VALUE= if they do not want BOTH categorized variables?
%* note that if they wanted JUST the statistic-valued categorized variable, they should explicitly specify BOTH=0);
%* Also, if BOTH=1 and VALUE is not given, then set VALUE=mean (that is MEAN is the default statistic to compute when
%* both --integer-valued and statstic-valued-- categorized variables are requested).
%* Finally, if neither BOTH nor VALUE are given, then set BOTH=0;
%if &both = and %quote(&value) = %then
	%let both = 0;
%else %if %quote(&value) ~= and &both = %then
	%let both = 1;
%* Si BOTH=1 y VALUE= es vacio, uso VALUE=mean;
%else %if &both = 1 and %quote(&value) = %then
	%let value = mean;

%*** SUFFIX=;
%* DM-2012/06/17: Eliminated the assignment of the default value _ for SUFFIX so that analyzed variables can have up to
%* 32 characters as names and still have a categorization process that works fine, by simply specifying empty values for
%* parameters SUFFIX and VALUE, or optionally specifying new names for the categorized variables in parameter VARCAT
%* --which allows keeping both the original and the categorized variables in the output dataset;
%* This also implied changing the WAY that the value of &SUFFIXVALUE was defined --i.e. the logic was changed;
%* The eliminated lines inside the following IF statement, which originally was %IF %QUOTE(&SUFFIX) = (instead of ~=), are:
%* 	%let suffix = _;			%* I use a short suffix to avoid problems with long variable names;
%* 	%let suffixValue = _&value;	%* This is only used if &value is not empty;
%* and for the ELSE part, the following lines were eliminated (as they were moved below where the value for &SUFFIXVALUE is now set:
%* 	%let suffixValue = &suffix._&value;		%* This is only used if &value is not empty;
%* DM-2015/08/27-START;
%* First set the suffix to empty when BOTH=0 and the user requested a statistic-valued categorization (which means that they
%* really want to keep the statistic-valued categorized variable (not the integer-valued categorized variable);
%if %quote(&value) ~= and ~&both %then
	%let suffix = ;
%* DM-2015/08/27-END;
%let suffixValue = ;
%if %quote(&value) ~= %then
	%let suffixValue = &suffix._&value;
%* DM-2012/06/17-END;

%*** VAR=, VARCAT=, VARVALUE=;
%* Parse any special keywords passed in VAR=;
%let var = %GetVarList(&data, var=&var, log=0);	%* Note that data options in &data are not a problem for %GetVarList;
%let nro_vars = %GetNroElements(&var);

%* DM-2012/06/17-START: Check if the new variable names do not create conflicts because of being too long...;
%let error = 0;
%do i = 1 %to &nro_vars;
	%let _var_ = %scan(&var, &i, ' ');
	%let _varcat_ = %scan(&varcat, &i, ' ');
	%let _varvalue_ = %scan(&varvalue, &i, ' ');
	%* First I check if a name is explicitly specified by the user for the categorized variables via the VARCAT= parameter
	%* or the VARVALUE= parameter.
	%* If yes, I check the length of those names.
	%* If not, I check the length of the names obtained by adding &SUFFIX and &SUFFIXVALUE to the original variable names;
	%if %length(&_varcat_) > 32 or
		(%quote(&value) ~= and %quote(&_varvalue_) ~= and %length(&_varvalue_) > 32) or 
		(%quote(&value) ~= and %quote(&_varvalue_) = and %length(&_varcat_._&value) > 32) or
		(%quote(&_varcat_) = and %quote(&_varvalue_) = and (%length(&_var_&suffix) > 32 or %length(&_var_&suffixValue) > 32)) %then %do;
		%let error = 1;
		%put CATEGORIZE: ERROR - For var = %upcase(&_var_), at least one name to be used for the categorized variables;
		%put CATEGORIZE: is longer then 32 characters and this exceeds the maximum SAS length.;
		%put CATEGORIZE: Consider using a shorter SUFFIX or the VARCAT= parameter in order to;
		%put CATEGORIZE: specify new variable names for the categorized variables.;
		%put CATEGORIZE: The macro will stop executing.;
	%end;
%end;
%* Check if a name for the new categorized variables is given for EACH of the input variables. If this is the case,
%* the value of SUFFIX is set to empty because it will not be used (recall that the default value of SUFFIX is _CAT,
%* therefore even if the user does not provide a value for SUFFIX= it will have the value _CAT by default)
%* Doing this is useful when a statistic is specified in parameter VALUE=: in such case, the names of the categorized
%* variables containing such statistic for each category will be formed by appending _&VALUE to the ORIGINAL
%* variable name, instead of appending _&VALUE to the original variable name followed by &SUFFIX which makes the
%* name too long;
%* Note that checking that the last value of &_VARCAT_ guarantees that the number of names specified in the VARCAT= parameter
%* matches (at least) the number of names given in VAR=;
%if %quote(&_varcat_) ~= %then
	%let suffix = ;
%* DM-2012/06/17-END;
%* DM-2015/08/27: Similarly to the update on SUFFIX should VARCAT= contain at least the same number of variables
listed in VAR= I now check whether _VARVALUE_ is non empty in order to set suffixValue to empty since no suffix
will be added to any of the analyzed variable to construct the name of the statistic-valued categorized variable;
%if %quote(&_varvalue_) ~= %then
	%let suffixValue = ;
/*-------------------------------------------------------------------------------------------*/

%if ~&error %then %do;
%* Store in &var_order the variable order in the input dataset, so that it can be restored
%* at the end when the output dataset is created.
%* This is necessary because of the split of the input dataset performed below into 
%* one dataset (_Categorize_data_) with the analysis variables and another dataset
%* (_Categorize_data_rest_) with the other variables.
%* Note the following:
%* - any data options in &data are executed in %GetVarOrder.
%* - this macro does not take long because it executes a PROC CONTENTS to get the variable order;
%GetVarOrder(&data, var_order);

%* Read in the dataset and split it into 2 parts: one with the variables
%* to be categorized (_Categorized_data_) and the other with the other variables
%* (_Categorize_data_rest_). 
%* A temporary observation variable is created in order to put together these 2 parts
%* at the end;
data _Categorize_data_(keep=&var _categorize_obs_) _Categorize_data_rest_(drop=&var);
	set &data end=lastobs;
	_categorize_obs_ = _N_;
run;
%* Read the number of observations to be effectively used;
%Callmacro(getnobs, _Categorize_data_ return=1, nobs);

%if &groupsize = %then %do;
	%* Calculo de los percentiles para cada variable;
	%if &log %then %do;
		%put CATEGORIZE: Nro. of approx. equal groups used to categorize each variable = &nro_percentiles;
		%put CATEGORIZE: Average size of each group = %sysfunc(round(%sysevalf(&nobs/&nro_percentiles)));
		%put;
	%end;
	%*** DM-2012/06/20-START: Changed the prefix for the percentiles so that there is no limitation for the variable name length.
	%*** Now the prefix for the percentiles for the i-th variable are constructed as _VAR&i._P1_, etc.;
%*	%let pctlpre = %MakeList(&var , prefix=_ , suffix=_);
	%let pctlpre = %MakeList(%MakeListFromName(_VAR, length=&nro_vars, start=1, step=1), suffix=_);
	%*** DM-2012/06/20-END;
	%let pctlname = %MakeListFromName(P ,length=&nro_percentiles, start=1, step=1, suffix=_);
	%if %quote(&condition) = %then %do;
		proc univariate data=_Categorize_data_ noprint;
			var &var;
			output 	out=_Categorize_percentiles_ 
					pctlpre=&pctlpre 
					pctlpts=&percentiles
					pctlname=&pctlname;
				%* The name of the percentile variables for each variable are of the form:
				%* _VAR1_P1_ _VAR1_P2_ _VAR1_P3_ _VAR1_P4_, for example if there are 4 categorization groups
				%* where VAR1 is associated with the variable to be categorized.
				%* Note that I also tried using names that explicitly mention the requested percentiles,
				%* such as _VAR1_P25_, _VAR1_P50_, etc., but this does NOT work properly when the requested
				%* percentile value is not an integer number!!;
		run;
	%end;
	%else
		%do i = 1 %to &nro_vars;
			%let _var_ = %scan(&var, &i, ' ');
			%*** DM-2012/06/20-START: Changed the prefix for the percentiles so that there is no limitation for the variable name length.
			%*** Now the prefix for the percentiles for the i-th variable are constructed as _VAR&i._P1_, etc.;
			%*** I also commented out the definition of &PCTLNAME as this has been already defined before the %IF;
%*			%let pctlpre = %MakeList(&_var_ , prefix=_ , suffix=_);
%*			%let pctlname = %MakeListFromName( , length=&nro_percentiles , start=1 , step=1 , prefix=P , suffix=_);
			%let pctlpre = _VAR&i._;		%* Note that only the i-th variable is analyzed here;
			%*** DM-2012/06/20-END;
			proc univariate data=_Categorize_data_ noprint;
				where &_var_ &condition;
				var &_var_;
				output 	out=_Categorize_percentiles_i_
						pctlpre=&pctlpre
						pctlpts=&percentiles
						pctlname=&pctlname;
			run;
			%if &i = 1 %then %do;
				data _Categorize_percentiles_;
					set _Categorize_percentiles_i_;
				run;
			%end;
			%else %do;
				data _Categorize_percentiles_;
					set _Categorize_percentiles_;
					set _Categorize_percentiles_i_;
				run;
			%end;
		%end;

	%*** DM-2012/06/20-START: Following the change in the naming of the percentile variables done at
	%*** PROC UNIVARIATE above, here I adapt the macro variable definition containing their names;
	%* Definition of the macro variables containing the list of names of the dataset columns
	%* that store the percentiles for each analysis variable;
	%do i = 1 %to &nro_vars;
%*		%let _var_ = %scan(&var , &i , ' ');
%*		%local &_var_._p;
%*		%let &_var_._p = %MakeList(&pctlname , prefix=_&_var_._);
		%local _VAR&i._p_list;
		%let _var&i._p_list = %MakeList(&pctlname , prefix=_VAR&i._);
	%end;
	%*** DM-2012/06/20-END;

	%* Categorizacion de las variables;
	data _Categorize_data_;
		%* Maintain the order of the variables in the input dataset and put the new
		%* variables towards the end;
		format &var_order;
		%* Below, the 2 sets put variables of the second dataset next to the variables of
		%* the first dataset. Any repeated variables are overridden in the first dataset
		%* by the variables in the second dataset;
		set _Categorize_data_;
		set _Categorize_data_rest_;
		if _N_ = 1 then set _Categorize_percentiles_;
		%do i = 1 %to &nro_vars;
			%let _var_ = %scan(&var , &i , ' ');
			%*** DM-2012/06/20-START: Following the change in the naming of the percentile variables done at
			%*** PROC UNIVARIATE above, here I adapt the array definition;
%*			array &_var_._p{*} &&&_var_._p;
			array _VAR&i._p{*} &&_VAR&i._p_list;	%* The number of elements of this array is &NRO_PERCENTILES (see definition of macro variables PCTLNAME and _VAR&I._P_LIST above);
			%*** DM-2012/06/20-END;
			%if %quote(&condition) ~= %then %do;
			if not (&_var_ &condition) then do;
				%* If ALLTOGETHER=1, assign all the values excluded from the categorization into
				%* the same grouped value. I use as grouped value the # of percentiles + 1;
				if &alltogether then
					_VAR&i._CAT_ = &nro_percentiles + 1;
				else
					%* It is assumed that the value of the variable &_var_ is not an integer between 1
					%* and the number of groups created by this categorization! Otherwise, one of the groups
					%* will contain the cases where the variable takes a value equal to the group ID;
					_VAR&i._CAT_ = &_var_;
			end;
			else do;
			%end;
			select;
				when (&_var_ = .)
					_VAR&i._CAT_ = .;		%* DM-2012/06/17: Renamed the categorized variable to _VAR&i._CAT_ and
											%* replaced the 0 value assigned as the group for missing values with a missing value;
				%*** DM-2012/06/25-START: Fixed the integer values representing each group of the categorized variable
				%*** so that when the DESCENDING option is ON, the categorized group associated to the higher values of
				%*** the analyzed variable is guaranteed to be 1 (in the earlier version, when DESCENDING option was ON,
				%*** the categorized group associated to the SMALLER values of the analyzed variable was guaranteed to be
				%*** &NRO_PERCENTILES, therefore leaving the categorized value of the higher values of the analyzed variable
				%*** DEPENDENT on the variable distribution, and this is not what we want...);
				%if &descending %then %do;
					%* When DESCENDING=1, the numbering of the categorized variable representing each
					%* group starts at 1 for the variable values that fall between the highest and the last to highest
					%* percentiles, INCLUDING BOTH ENDS. This --INCLUDING BOTH ENDS-- for the Group Value = 1 is done
					%* to mimic the mapping of original values to categorized when carried out on the usual case where
					%* the grouped values increase as the original variable increases (here the group having value 1 contains
					%* all values of the original variable that fall between the 0 percentile and the first percentile of
					%* the percentile value list specified by the user --that is, both extremes are included).
					%* Note however that due to the way this macro was constructed, the 100% value is ALWAYS present
					%* among the percentile value list, while the 0% value is NOT included in the percentile value list.
					%* This makes the first inequality here:
					%* 	_VAR&i._p(&nro_percentiles-1) <= &_var_ <= _VAR&i._p(&nro_percentiles)
					%* to be tantamount to:
					%* 	_VAR&i._p(&nro_percentiles-1) <= &_var_
					%* since _VAR&i._p(&nro_percentiles) is the 100% largest value of the analyzed variable;
					%* For the remaining groups (with assigned value larger than 1) the inclusion of the end values in
					%* each categorized value is reversed w.r.t. to the usual case, that is the LOWER END of the group
					%* is included and the UPPER END is NOT included.
					%* Note also that in the DESCENDING=1 case we need to separate the WHEN conditions into one more
					%* case than in the DESCENDING=0 case (usual case), making up 3 WHEN conditions insead of 2;
					when (_VAR&i._p(&nro_percentiles-1) <= &_var_ <= _VAR&i._p(&nro_percentiles))		_VAR&i._CAT_ = 1;
					%do j = 2 %to (&nro_percentiles-1);
					when (_VAR&i._p(&nro_percentiles-&j) <= &_var_ < _VAR&i._p(&nro_percentiles-&j+1))	_VAR&i._CAT_ = &j;
					%end;
					when (									&_var_ <= _VAR&i._p(1))						_VAR&i._CAT_ = &nro_percentiles;
				%end;
				%else %do;
					%* Most common or normal case: the integer value representing each group of the categorized variable
					%* goes from smaller to larger as the variable value goes from smaller to larger. Note that the
					%* grouped value 1 is assigned to the interval that contains the smallest values of the variable
					%* including both ends of the interval. For the other grouped values (larger than 1), the LOWER END
					%* of the interval is NOT included in the group and the UPPER END is included;
					when (&_var_ <= _VAR&i._p(1))						_VAR&i._CAT_ = 1;
					%do j = 2 %to &nro_percentiles;
					when (_VAR&i._p(&j-1) < &_var_ <= _VAR&i._p(&j))	_VAR&i._CAT_ = &j;
					%end;
				%end;
/*				This is commented out as part of the change block dated DM-2012/06/25.
				when (&_var_ <= _VAR&i._p(1))
					%if ~&descending %then %do;
						_VAR&i._CAT_ = 1;
					%end;
					%else %do;
						_VAR&i._CAT_ = &nro_percentiles;
					%end;
				%do j = 2 %to &nro_percentiles;
				when (_VAR&i._p(&j-1) < &_var_ <= _VAR&i._p(&j))
					%if ~&descending %then %do;
						_VAR&i._CAT_ = &j;
					%end;
					%else %do;
						_VAR&i._CAT_ = &nro_percentiles - &j + 1;
					%end;
				%end;
*/
				%*** DM-2012/06/22-END;
				%* Unidentified value;
				otherwise /*&_var_&suffix = .;*/
					_VAR&i._CAT_ = .;
			end;
			%if %quote(&condition) ~= %then %do;
			end;	%* END IF when &condition is not empty;
			%end;
			drop &&_VAR&i._p_list;
		%end;
	run;
%end;
%* Se definen las categorias de manera de que tengan tamanho groupsize=;
%else %do; %* %if groupsize = ;
	%* Nro. de grupos completos (con exactamente &groupsize observaciones) que se pueden
	%* armar. Las observaciones que quedan fuera, se juntan con el ultimo grupo;
	%let nro_groups = %sysfunc(floor(%sysevalf(&nobs/&groupsize)));
	%if &log %then %do;
		%put CATEGORIZE: Nro. of approx. equal groups used to categorize each variable = &nro_groups;
		%put CATEGORIZE: Approx. size of each group = &groupsize;
		%put;
	%end;
	%do i = 1 %to &nro_vars;
		%let _var_ = %scan(&var , &i , ' ');
		%* Sort by current variable to create the group IDs;
		proc sort data=_Categorize_data_;
			%* DM-2012/06/17: When DESCENDING=1 add the keyword DESCENDING;
			by %if &descending %then %do; DESCENDING %end; &_var_;
		run;
		data _Categorize_data_;
			set _Categorize_data_;
			/* DM-2015/08/13: BY statement was added because FIRST.&_var_ is used below. */
			by %if &descending %then %do; DESCENDING %end; &_var_;
			retain _VAR&i._CAT_;
			retain _categorize_count_ 0;
			%* If the first value is a missing value (which is the same as asking if the
			%* variable has missing values --since the dataset is sorted by &_var_), then the
			%* first categorized value is 0, which is assigned to the missing value; 
			if _N_ = 1 then do;
				if &_var_ = . then
					_VAR&i._CAT_ = .;
				else
					_VAR&i._CAT_ = 1;
			end;
			/* DM-2015/08/13: Added this ELSE IF statement to fix a bug when the analysis variable has a missing value.
			In fact, when this is the case, all the values of the categorized variable are missing! (since below
			we do _VAR&i._CAT_ + 1 and the result is missing when _VAR&i._CAT_ is missing.
			The condition checks that the first group of variable values is equal to missing (_VAR&i._CAT_ = .
			and if that group ended in the previous record (first.&_var_). */
			else if first.&_var_ and _VAR&i._CAT_ = . then
				_VAR&i._CAT_ = 1;
			/* DM-2015/08/13: Included the case when parameter CONDITION is not empty, which specifies a
			condition that should be satisfied by the input variables in order to be included in the
			categorization process. */
			%if %quote(&condition) ~= %then %do;
			if not (&_var_ &condition) then do;
				%* If ALLTOGETHER=1, assign all the values excluded from the categorization into
				%* the same grouped value. I use as grouped value 0;
				if &alltogether then
					_VAR&i._CAT_ = 0;
				else
					%* It is assumed that the value of the variable &_var_ is not an integer between 1
					%* and the number of groups created by this categorization! Otherwise, one of the groups
					%* will contain the cases where the variable takes a value equal to the group ID;
					_VAR&i._CAT_ = &_var_;
			end;
			else do;
			%end;
			if _categorize_count_ >= &groupsize and _VAR&i._CAT_ < &nro_groups then do;
				_VAR&i._CAT_ = _VAR&i._CAT_ + 1;
				_categorize_count_ = 1;		%* Notar que no se resetea a 0 (sino a 1), porque el registro
											%* actual debe ser contado como primer registro
											%* del nuevo grupo;
			end;
			else if &_var_ ~= . then		/* DM-2012/06/17: Added an IF &_VAR_ ~= . as now the missing values are categorized to missing, and they should NOT count to the categorization count. */
				_categorize_count_ = _categorize_count_ + 1;
				%** Note that this also implies that the largest values of the variable that did
				%** not fit into any group are added to the last group (increase of course its size);
			%if %quote(&condition) ~= %then %do;
			end;	%* END IF when &condition is not empty;
			%end;
			drop _categorize_count_;
		run;
	%end;
%end;

%* Asignacion de niveles en base a lo solicitado por el parametro value=. Tipicamente, el
%* valor del nivel corresponde al valor medio de la variable en cada grupo;
%if %quote(&value) ~= %then %do;
	%do i = 1 %to &nro_vars;
		%let _var_ = %scan(&var , &i , ' ');
		%let _varcat_ = %scan(&varcat , &i , ' ');
		%let _varvalue_ = %scan(&varvalue, &i, ' ');

		%* Computation of the statistic-valued categories (given by the VALUE= parameter, which is typically equal to MEAN);
		proc sort data=_Categorize_data_;
			by _VAR&i._CAT_;
		run;
		proc means data=_Categorize_data_ &value noprint;
			by _VAR&i._CAT_;
			var &_var_;
			output out=_Categorize_values_(drop=_TYPE_ _FREQ_)
				/* Define the name of the output variable based on the values of parameters VARCAT=, VARVALUE= and BOTH */
				%if %quote(&_varcat_) ~= and %quote(&_varvalue_) = and &both %then %do; 	&value=&_varcat_._&value  %end;
				%else %if %quote(&_varvalue_) ~= %then %do; 								&value=&_varvalue_ %end;
				%else %do; /* &_varcat_ = (empty) and &_varvalue_ = (empty) or ~&both */ 	&value=&_var_&suffixValue %end;
										 ;
		run;

		%* Attach the statistic-valued categorized variable to each category defined by the current integer-valued
		%* categorized variable, _VAR&i._CAT_;
		%* Note that there is no need to sort by _VAR&i._CAT_ because this sorting has been done above
		%* before the PROC MEANS statement;
		%* DM-2015/05/21-START: Now I DROP the current output variable containing the statistic in case it already exists 
		%* in the input dataset (here represented by _Categorize_data_) because if that is the case only the first
		%* occurrence of the output variable will be updated by this merge because the _Categorize_values_ dataset
		%* has only ONE observation per category whereas _Categorize_data_ has many cases per category
		%* (and only the first one is replaced!).
		%* Note that this situation may be common when the user is trying out different categorization possibilities...;
		options dkricond=nowarn;
		data _Categorize_data_;
			merge 	_Categorize_data_(drop=	%if %quote(&_varcat_) ~= and %quote(&_varvalue_) = and &both %then %do; 	&_varcat_._&value  %end;
											%else %if %quote(&_varvalue_) ~= %then %do; 								&_varvalue_ %end;
											%else %do; /* &_varcat_ = (empty) and &_varvalue_ = (empty) or ~&both */ 	&_var_&suffixValue %end;)
					_Categorize_values_;
			by _VAR&i._CAT_;
		run;
		options dkricond=&dkricond;
		%* DM-2015/05/21-END;
	%end;
%end;

%* Add back the other variables present in the input dataset into _Categorize_data_;
%* Note that _Categorize_data_rest_ need NOT be sorted because that dataset was
%* not touched and thus keeps the original order given by _categorize_obs_;
proc sort data=_Categorize_data_;
	by _categorize_obs_;
run;
%* Create output dataset or update input dataset (if OUT= is empty).
%* Here any options coming in the OUT= parameter are executed;
%if &log %then %do;
	%put CATEGORIZE: Changes performed in output dataset %upcase(&out_name):;
	%put;
%end;
options dkrocond=nowarn;
data &out;
	format &var_order;		%* Original order of variables in the input dataset;
	merge _Categorize_data_rest_ _Categorize_data_;
	by _categorize_obs_;
	%*** DM-2012/06/17-START: Updated the rename process after using internally generated variable names (_VAR&i._CAT_)
	%*** in the categorization process to name the categorized variables
	%*** (with the aim of avoiding problems with long variable names) and allowing the user to specify the names
	%*** for some or all of the new integer-valued categorized variables;
	%do i = 1 %to &nro_vars;
		%let _var_ = %scan(&var , &i , ' ');
		%let _varcat_ = %scan(&varcat , &i , ' ');
		%let _varvalue_ = %scan(&varvalue, &i, ' ');

		%*** DM-2015/05/23-START: Completely refurbished the creation and log information of the categorized variables;
		%* Process the INTEGER-VALUED categorized variable;
		%if %quote(&_varcat_) ~= %then %do;
			%* When _varcat_ is not empty for the current variable, output the integer-valued categorized variable
			%* unless a statistic-valued categorization was also requested with BOTH=0;
			%if %quote(&value) = or &both %then %do;
				%if &log %then %do;
					%if %ExistVar(_Categorize_data_rest_, &_varcat_, log=0) or %ExistVar(_Categorize_data_,  &_varcat_, log=0)  %then
						%put CATEGORIZE: Variable %upcase(&_varcat_) has been REPLACED with its integer-valued categorization.;
					%else
						%put CATEGORIZE: Variable %upcase(&_varcat_) has been created containing the integer-valued categorization for %upcase(&_var_).;
				%end;
				drop &_varcat_;
				rename _VAR&i._CAT_ = &_varcat_;
			%end;
			%else %do;
				%* Do NOT keep the integer-valued categorized variable (because a statistic-valued categorized version has
				%* also been requested with BOTH=0;
				drop _VAR&i._CAT_;
			%end;
		%end;
		%else %do;
			%* When _varcat_ is empty, only output the integer-valued categorized variable when the two following conditions are satisfied;
%*			%if &both %then %do;
			%if %quote(&value) = or %quote(&value) ~= and &both %then %do;
				%if &log %then %do;
					%if %ExistVar(_Categorize_data_rest_, &_var_&suffix, log=0) %then
						%put CATEGORIZE: Variable %upcase(&_var_&suffix) has been REPLACED with its integer-valued categorization.;
					%else
						%put CATEGORIZE: Variable %upcase(&_var_&suffix) has been created containing the integer-valued categorization for %upcase(&_var_).;
				%end;
				drop &_var_&suffix;
				rename _VAR&i._CAT_ = &_var_&suffix;
			%end;
			%else %if ~&both %then %do;
				%* Drop the integer-valued categorized variable when only the statistic-valued categorized variable has been requested;
				drop _VAR&i._CAT_;
			%end;
		%end;

		%* Process the STATISTIC-VALUED categorized variable;
		%if &log %then %do;
			%if %quote(&value) ~= %then %do;
				%if %quote(&_varvalue_) ~= %then %do;
					%if %ExistVar(_Categorize_data_rest_, &_varvalue_, log=0) or %ExistVar(_Categorize_data_, &_varvalue_, log=0) %then
						%put CATEGORIZE: Variable %upcase(&_varvalue_) has been REPLACED with its statistic-valued categorization.;
					%else
						%put CATEGORIZE: Variable %upcase(&_varvalue_) has been created containing the statistic-valued categorization for %upcase(&_var_).;
				%end;
				%else %if %quote(&_varcat_) ~= and &both %then %do;
					%** The above condition comes from the %quote(&_varcat_) ~= and %quote(&_varvalue_) = and &both condition used when creating the name of the statistic-valued categorized variable in the PROC MEANS above;
					%** The condition implies that the statistic-valued categorized variable is named &_VARCAT_._&value;
					%if %ExistVar(_Categorize_data_rest_, &_varcat_._&value, log=0) %then
						%put CATEGORIZE: Variable %upcase(&_varcat_._&value) has been REPLACED with its statistic-value categorization.;
					%else
						%put CATEGORIZE: Variable %upcase(&_varcat_._&value) has been created containing the statistic-valued categorization for %upcase(&_var_).;
				%end;
				%else %do;
					%if %ExistVar(_Categorize_data_rest_, &_var_&suffixValue, log=0) %then
						%put CATEGORIZE: Variable %upcase(&_var_&suffixValue) has been REPLACED with its statistic-valued categorization.;
					%else
						%put CATEGORIZE: Variable %upcase(&_var_&suffixValue) has been created containing the statistic-valued categorization for %upcase(&_var_).;
				%end;
			%end;

			%* Leave a line between the information of the current variable and the info for the next variable;
			%put;
		%end;
		%*** DM-2015/05/23-END;
	%end;
	%*** DM-2012/06/17-END;
	drop _categorize_obs_;
run;
%* Restore dkrocond option;
options dkrocond=&dkrocond;

proc datasets nolist;
	delete  _Categorize_data_
			_Categorize_data_rest_
			_Categorize_percentiles_
			_Categorize_percentiles_i_
			_Categorize_values_;
quit;

%end;	%* ~&error;

%if &log %then %do;
	%put;
	%put CATEGORIZE: Macro ends;
	%put;
%end;

%ResetSASOptions;

%end;	%* %if ~%CheckInputParameters;
%MEND Categorize;
