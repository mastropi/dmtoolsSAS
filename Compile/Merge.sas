/* MACRO %Merge
Version: 1.04
Author: Daniel Mastropietro
Created: 1-Dec-00
Modified: 3-Mar-05

DESCRIPTION:
Efectúa un merge entre dos datasets por BY variables.
No es necesario ordenar previamente los datasets por las by variables.
Asimismo, por default, el orden de las observaciones en los input datasets
no se modifica. Sin embargo el output dataset queda ordenado por las BY variables.
Se pueden establecer condiciones que deben satisfacer las observaciones
para pertenecer al dataset resultante del merge (ej. if in1 and in2).

USAGE:
%Merge(
	data1 ,		*** Primer dataset a mergear
	data2 ,		*** Segundo dataset a mergear
	out= ,		*** Output dataset donde se guarda el merge
	by= ,		*** By variables por las que se hace el merge
	condition=,	*** Condición a ejecutarse en el merge
	format=,	*** Contenido del FORMAT statement a usar ANTES del MERGE statement
				***	que afecta al output dataset.
	sort=0,		*** Mantener el orden de las by variables luego del merge?
	log=1);		*** Mostrar mensajes en el log?

REQUESTED PARAMETERS:
- data1:		Primer dataset a mergear. Pueden especificarse opciones
				como las que se espefican en cualquier opción data= de SAS.

- data2:		Segundo dataset a mergear. Pueden especificarse opciones
				como las que se espefican en cualquier opción data= de SAS.

OPTIONAL PARAMETERS:
- out:			Output dataset donde se guarda el resultado del merge.
				Pueden especificarse opciones como las que se espefican en
				cualquier opción data= de SAS.
				Si no se especifica ningún output dataset, la salida se
				guarda en el primer dataset 'data1'.

- by:			By variables por las que se efectúa el merge.
				Si no se especifica nada, se hace el merge por número de
				observación.

- condition:	Condición que deben satisfacer las observaciones para
				ser parte del dataset resultante del merge. Esta condición
				se ejecuta en el data step que efectúa el merge.
				Téngase en cuenta que internamente se crean las variables
				'in1' e 'in2' que indican si cada observación proviene del
				dataset data1 o del dataset data2, respectivamente. Por lo
				tanto estas variables pueden usarse para establecer
				condiciones para que una observación pertenezca al dataset
				resultante del merge.
				Ver ejemplos abajo en la sección EXAMPLES.
				NOTA IMPORTANTE: Se supone que en ninguno de los datasets existen
				las variables IN1 e IN2. De existir, el merge funciona bien igual,
				pero dichas variables NO son incluidas en el output dataset.

- format:		Format statement a usar antes del MERGE y que afecta al output dataset
				y el orden de las variables.

- sort:			Define si se desea modificar los input datasets ordenándolos por las
				BY variables, o dejarlos sin modificar, con las observaciones en el
				orden en que estaban.
				NOTA IMPORTANTE: Si SORT=1 y hay WHERE options en los datasets a mergear,
				los filtros WHERE MODIFICAN LOS DATASETS. Para que los input datasets
				no se vean modificados, usar SORT=0.
				Valores posibles: 	0 => no modificar los input datasets
									1 => ordenar los input datasets por las BY variables
				default: 0 (no modificar los input datasets)

- log:			Indica si se desean ver los mensajes en el log.
				Valores posibles: 0 => No, 1 => Si.
				default: 1

NOTES:
1.- No es necesario ordenar los datasets para efectuar el merge. La macro
los ordena previamente según sea necesario.

2.- El orden inicial de las observaciones es mantenido en cada input dataset cuando SORT=0.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %CheckInputParameters
- %RemoveFromList
- %ResetSASOptions
- %SetSASOptions

EXAMPLES:
1.- %merge(data1 , data2 , by=A B , condition=if in2);
Hace el merge de DATA1 con DATA2 por las by variables A y B, dejando solamente
las observaciones que vienen de DATA2.
El resultado del merge se guarda en el primer dataset, DATA1.
Como el parámetro sort no fue pasado, su valor es sort=0, con lo que
los datasets DATA1 y DATA2 no son modificados por lo que el orden de las observaciones
no cambia luego de la ejecución de la macro.
El orden de las observaciones en DATA12 está dado por las BY variables.

2.- %merge(data1 , data2 , by=A B , out=data12 , condition=if in1 and in2, sort=1);
Hace el merge de DATA1 con DATA2 por las by variables A y B, dejando solamente
las observaciones que vienen tanto de DATA1 como de DATA2.
Se crea un nuevo dataset DATA12 con los resultados del merge.
Como el parámetro sort=1 los datasets DATA1 y DATA2 quedan ordenados por las BY variables.
El output dataset DATA12 también queda ordenado por las BY variables.

APPLICATIONS:
1.- Mergear datasets sin preocuparse por ordenarlos previamente por las BY variables.
2.- Mergear datasets por BY variables sin modificar el orden de las observaciones en los input
datasets.
*/
&rsubmit;
%MACRO Merge(data1, data2, out=, by=, condition=, format=, sort=0, log=1, help=0)
	/ store des="Merges two datasets";
%local by2check;		%* Used for %CheckInputParameters;
%local byst formatst mergest;
%local data1_name data2_name out_name data1_options data2_options;
%local data1_sorted data2_sorted;
%local error;
%local nobs nvar;

/*----- Macro that displays usage -----*/
%MACRO ShowMacroCall;
	%put MERGE: The macro call is as follows:;
	%put %nrstr(%Merge%();
	%put data1 , (REQUIRED) %quote(*** Primer dataset a mergear);
	%put data2 , (REQUIRED) %quote(*** Segundo dataset a mergear);
	%put out= , %quote(            *** Output dataset donde se guarda el merge);
	%put by= , %quote(             *** By variables por las que se hace el merge);
	%put format= , %quote(         *** Format statement a usar ANTES del MERGE statement);
	%put condition= , %quote(      *** Condición a ejecutarse en el merge);
	%put sort=0) %quote(           *** Mantener el orden de las by variables luego del merge?);
%MEND ShowMacroCall;

%if &help %then %do;
	%ShowMacroCall;
%end;
%else %do;
%* Checking existence of input datasets and existence of by variables in datasets;
%let error = 0;
%let data1_name = %scan(%quote(&data1) , 1 , '(');
%let data2_name = %scan(%quote(&data2) , 1 , '(');
%let data1_options = %GetDataOptions(%quote(&data1));
%let data2_options = %GetDataOptions(%quote(&data2));
%let by2check = %RemoveFromList(%quote(&by), descending, log=0);
%if ~%index(%quote(%upcase(&data1_options)), RENAME) and ~%index(%quote(%upcase(&data2_options)), RENAME) %then %do;
	%if ~%CheckInputParameters(data=&data1_name &data2_name, var=&by2check,
							   otherRequired=%quote(&data2), requiredParamNames=data1 data2, 
							   singleData=0, macro=MERGE)
	/*or ~%CheckInputParameters(data=&data2 , var=&by , requiredParamNames=data2 , macro=MERGE)*/ %then %do;
		%ShowMacroCall;
		%let error = 1;
	%end;
%end;
%else %do;
	%if ~%CheckInputParameters(data=&data1_name &data2_name,
							   otherRequired=%quote(&data2), requiredParamNames=data1 data2, 
							   singleData=0, macro=MERGE) %then %do;
		%ShowMacroCall;
		%let error = 1;
	%end;
%end;
%if ~&error %then %do;
/************************************* MACRO STARTS ******************************************/
%SetSASOptions;

%if &log %then %do;
	%put;
	%put MERGE: Macro starts;
	%put;
%end;

%let byst =;
%if %quote(&by) ~= %then %do;
	%if &sort %then %do;	
		%* The sorted datasets are the same as the input datasets;
		%let data1_sorted = &data1_name;
		%let data2_sorted = &data2_name;
	%end;
	%else %do;
		%* The sorted datasets are temporary datasets;
		%let data1_sorted = _Merge_data1_;
		%let data2_sorted = _Merge_data2_;
	%end;

	%* Sort the datasets by the BY variables;
	%* Note that below I use &data1 and &data2 (instead of &data1_name and &data2_name)
	%* because &data1 and &data2 may carry a RENAME option which renames the by variables
	%* used in the merge process (which is very common if the by variables used do not
	%* have the same name in both datasets);
	%* Note however that when SORT=1 and when there are WHERE options in &data1 or &data2,
	%* the input dataset will be overwritten with the WHERE option and we do not want
	%* that to happen, because we want to preserve the original datasets as they are;
	%let byst = by &by;
	proc sort data=&data1 out=&data1_sorted;
		&byst;
	run;
	proc sort data=&data2 out=&data2_sorted;
		&byst;
	run;

	%* Update the macro variables identifying the names of the datasets to merge with
	%* the names of the datasets created above after the sorting;
	%let data1_name = &data1_sorted;
	%let data2_name = &data2_sorted;

	%* Merge statement (no data options are included because they were already processed in the
	%* sort statement);
	%let mergest = merge &data1_name(in=in1) &data2_name(in=in2);
%end;
%else %do;
	%* Merge statement with the data options coming with DATA1 and DATA2;
	%let mergest = merge &data1_name(in=in1 &data1_options) &data2_name(in=in2 &data2_options);
%end;

%* Format statement;
%let formatst = ;
%if %quote(&format) ~= %then
	%let formatst = format &format;

%* Output dataset;
%if %quote(&out) = %then
	%let out = &data1;
%let out_name = %scan(%quote(&out), 1, '(');

%* Turn on the NOTES option in case there are problems during the MERGE statement
%* such as repeate of BY values, etc.;
%if &log %then %do;
	options &_notes_option_;
%end;
%if %quote(%upcase(&out)) = %quote(%upcase(&data1)) %then %do;
%* Remove data options from &OUT when the output dataset string is the same as the
%* input dataset string (because the data options have already been set in the SORT
%* procedure at the beginning or in the MERGE statement (when there are no BY variables));
data &out_name;
%end;
%else %do;
data &out;
%end;
	&formatst;
	&mergest;
	&byst;
	&condition;
run;
%* Show what the dataset names refer to when SORT=1;
%if %quote(&by) ~= and ~&sort and &log %then %do;
	%put MERGE: Dataset %upcase(&data1_sorted) above refers to dataset %upcase(%scan(%quote(&data1), 1, '(')).;
	%put MERGE: Dataset %upcase(&data2_sorted) above refers to dataset %upcase(%scan(%quote(&data2), 1, '(')).;
%end;
%if &log %then %do;
	options nonotes;
%end;

proc datasets nolist;
	delete 	_Merge_data1_
			_Merge_data2_;
quit;

%if &log %then %do;
	%put;
	%put MERGE: Macro ends;
	%put;
%end;

%ResetSASOptions;
%end;	%* %if ~&error;
%end;	%* %if &help;
%MEND Merge;
