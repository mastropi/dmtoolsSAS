/* MACRO %GetRegVarList
Created: 11-Mar-05

Macro que lee la lista de variables que quedan en una regresion y que tambien funciona
cuando hay variables categoricas.
Esta macro se puede agregar a la macro %LogisticRegression para corregir los nombres de
las variables generadas por el ODS OUTPUT ParameterEstimates del PROC LOGISTIC,
aun cuando hay variables categoricas.

SUPUESTOS:
- El dataset DATA contiene una sola observacion con la lista de los parametros estimados
para cada variable presente en el MODEL statement. En un PROC LOGISTIC, este dataset
es generado con la opcion OUTEST del PROC LOGISTIC.
- El dataset DATA fue generado con la opcion LABEL en LABEL (en lugar de NOLABEL),
aunque al mismo tiempo el label de las variables debe ser vacio (para que el LABEL que 
aparezca en el dataset DATA coincida con el nombre de la variable) porque esta macro justamente
aprovecha la informacion del LABEL para determinar los nombres de las variables categoricas.

OBSERVACIONES:
- El parametro TARGET es el nombre de la variable que se usa como target en la regresion.
- La lista de variables (en orden alfabetico) se almacena en la macro variable global
pasada como parametro en MACROVAR=, que por default es _REGVAR_.
- Se crea el dataset _REGVAR_ con la lista de variables regresoras, pero esta lista se
diferencia de la lista guardada en la macro variable homonima, porque el dataset puede
tener nombres repetidos en caso de variables categoricas con mas de 2 niveles y porque
no esta' ordenado alfabeticamente sino en el orden en que aparecen en el PROC LOGISTIC output.
Esto es asi para poder mergear luego con el dataset creado por ej. con el ODS OUTPUT
ParameterEstimates del PROC LOGISTIC que tiene la maldita desventaja de truncar a 20
el largo del nombre de las variables.
El dataset tiene dos columnas: VAR y OBS. La variable OBS sirve justamente para mergear
con la tabla de parametros estimados creada con ODS OUTPUT ParameterEstimates. Notar que
el orden de los parametros en la tabla creada por el ODS OUTPUT es el mismo que el orden
generado por esta macro en el datset _REGVAR_. Por esto se puede hacer facilmente el merge.
El nombre de este dataset se puede cambiar con el parametro OUT=.
*/
%MACRO GetRegVarList(data, out=_regvar_, macrovar=_regvar_, log=1)
	/ des="Returns the variables used in a regression from the OUTEST= dataset";
%local param out_name;

%SetSASOptions;

%if &log %then %do;
	%put;
	%put GETREGVARLIST: Macro starts;
	%put;
%end;

proc transpose data=&data out=_GRVL_temp_;
run;
%* Leo el nombre de la variable que contiene el valor de los parametros estimados para saber
%* si el parametro es missing y asi saber si la variable quedo en la regresion o no;
%let param = %scan(%GetVarNames(_GRVL_temp_), 3, ' ');
%** Nota: el _LABEL_ siempre va a estar (independientemente de la opcion LABELS)
%** porque una de las variables del dataset original es _LNLIKE_ que tiene un label;
data _GRVL_temp_;
	set _GRVL_temp_;
	where _NAME_ not in ("Intercept" "_LNLIKE_") and &param ~= .;
	%* Elimino espacios en el label de la variable porque esto me da el nombre de las
	%* variables categoricas. Al mismo tiempo, chequeo si el label tiene un asterisco
	%* que indica si el parametro corresponde a una interaccion entre variables.
	%* De ser asi, elimino los espacios entre los nombres y el asterisco para
	%* despues poder listar las variables con un %PrintNameList sin problema de que
	%* me separe la interaccion en dos variables y me considere el asterisco como una
	%* tercera variable por el hecho de que hay espacios entre los nombres y el asterisco;
	if ~index(_LABEL_, '*') then
		var_label = substr(_LABEL_, 1, index(_LABEL_, ' '));
	else
		var_label = compress(_LABEL_);		%* Elimino espacios cuando hay asterisco;
	%* Leo los nombres de las variables;
	if var_label ~= "" then
		var = var_label;	%* Nombre de las variables categoricas;
	else
		var = _NAME_;		%* Nombre de las variables continuas;
	obs = _N_;
run;
%* Guardo la lista de variables en el output dataset, antes de la desduplicacion, para poder
%* luego mergear con la lista de  variables de la regresion, y recuperar los nombres
%* originales de las variables de la regresion, antes de que el proc logistic corte
%* los nombres;
data &out;
	set _GRVL_temp_(keep=obs var);
run;
%if &log %then %do;
	%let out_name = %scan(&out, 1, ' ');
	%put GETREGVARLIST: Output dataset %upcase(&out_name) created with the list of regression variables;
	%put GETREGVARLIST: (with names repeated for categorical variables).;
%end;

%* Elimino repetidos que vienen de las variables categoricas;
proc sort data=_GRVL_temp_ out=_GRVL_temp_(keep=obs var) nodupkey;
	by var;
run;
%* Vuelvo a ordenar por el orden en que las variables habian sido listadas en la regresion
%* y genero el output dataset &data._table;
proc sort data=_GRVL_temp_;
	by obs;
run;
%* Genero la macro variable con la lista de variables presentes en la regresion;
%global &macrovar;
%let &macrovar = %MakeListFromVar(_GRVL_temp_, log=0);
%if &log %then %do;
	%put GETREGVARLIST: Global macro variable %upcase(&macrovar) created with the list of regression variables;
	%put GETREGVARLIST: (with no repeated names).;
%end;
proc datasets nolist;
	delete _GRVL_temp_;
quit;

%if &log %then %do;
	%put;
	%put GETREGVARLIST: Macro ends;
	%put;
%end;

%ResetSASOptions;
%MEND GetRegVarList;

