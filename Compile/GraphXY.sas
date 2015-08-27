/* MACRO %GraphXY
Version: 1.02
Author: Santiago Laplagne - Daniel Mastropietro
Created: 17-Dec-02
Modified: 5-Aug-03

DESCRIPTION:
Realiza un scatter plot de dos variables.

USAGE:
%graphXY(	data, varX, varY, file=,
			title="Scatter plot of 'varY' vs. 'varX'",
			height = 0.8 , options=);

REQUESTED PARAMETERS:
- data:			Input dataset con los datos a utilizar. Puede recibir
				cualquier opción adicional como en cualquier opción data=
				de SAS.

- varX:			Nombre de la variable 'x' para graficar los puntos de
				coordenadas	(x, y).

- varY:			Nombre de la variable 'y' para graficar los puntos de 
				coordenadas (x, y).

OPTIONAL PARAMETERS:
- strata:		Nombre de la variable que define los estratos o grupos.
				Para cada valor distinto en esta columna se usa un color
				distinto en el gráfico.
				Si los estratos están definidos por más de una variable
				puede usarse la macro %CreateGroupVar para generar una
				única variable indicadora de los estratos a partir de
				una lista de variables.

- file:			Nombre del archivo donde guardar el gráfico en formato JPG.
				Debe indicarse entre comillas la ubicación y el nombre del
				archivo a utilizar.
				En caso de pasar este parámetro, no se muestra ningún
				gráfico en pantalla.

- title:		Título del gráfico (puede ser entre comillas o no).
				Se modifica el valor del primer nivel del titulo (title1).
				default: "Scatter plot of 'varY' vs 'varX'"

- height:		Tamaño de los símbolos a utilizar en el gráfico.
				default: 0.8

- options:		Opciones para el grafico. Puede ser cualquier opcion
				valida dentro de las opciones del plot statement del
				proc gplot.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Exist
- %DefineSymbols

EXAMPLES:
- GraphXY(data , x , y , file="C:\graficos\xy.jpg" , title="Titulo" ,
		  options=vref=0);
*/
&rsubmit;
%MACRO GraphXY (data, varX, varY, strata=1 , file=, title=, height = 0.8 , options=)
		/ store des="Makes a 2D scatter plot";
%local exists_title1 goptions notes_option;
%* Variables para guardar los valores actuales de las goptions modificadas por la macro,
%* y asi poder ser reseteadas al final;
%* Uso underscores porque son variables auxiliares que no tienen mayor importancia,
%* asi no tengo conflictos con variables que pueda crear en un futuro con alguno de
%* estos nombres (sin los underscores) y que si tengan relevancia a la macro;
%* La lista de estas variables cambia si cambia el valor de la macro variable &goptions.
%* Buscar el statement %let goptions;
%local
_device_
_gsfname_
_gsfmode_
_xmax_
_ymax_
_hsize_
_vsize_;

%if %quote(&title) ~= %then 
	%let exists_title1 = 0;
%else %do;
	%* Se fija si existe un valor para title1 que no sea el default "The SAS System";
	%* Si existe uno, y el parametro title no tiene ningun valor, title1 no es cambiado;
	%let exists_title1 = %Exist(sashelp.vtitle , number , 1);	%* "1" por nivel 1;
	%if &exists_title1 %then %do;
		%let notes_option = %sysfunc(getoption(notes));
		options nonotes;
		data _NULL_;
			set sashelp.vtitle;
			where number = 1;
			if trim(left(text)) = "The SAS System" then
				call symput ('exists_title1' , 0);
		run;
		options &notes_option;
	%end;
%end;
%* %let exists_title1 = 0;	%** Eliminar esta linea si la de arriba funciona;
 
%DefineSymbols (height = &height);
%if (%quote(&file) ne) %then %do;
	%let goptions = %STR(device=jpeg gsfname=file gsfmode=replace xmax=8in ymax=6in hsize=8in vsize=6in);
	%* Guardo los settings actuales de goption para luego poder resetearlos;
	%let _device_ = %sysfunc(getoption(device));
	%let _gsfname_ = %sysfunc(getoption(gsfname));
	%let _gsfmode_ = %sysfunc(getoption(gsfmode));
	%let _xmax_ = %sysfunc(getoption(xmax));
	%let _ymax_ = %sysfunc(getoption(ymax));
	%let _hsize_ = %sysfunc(getoption(hsize));
	%let _vsize_ = %sysfunc(getoption(vsize));
%end;
%else %let goptions = ;
goptions 	&goptions /* ftext=swiss fontres=presentation */;
%if (%quote(&file) ne) %then %do; FILENAME file &file; %end;
%if (%quote(&title) =) and ~&exists_title1 %then %do; %let title = "Scatter plot of &varY vs &varX"; %end;

%* Agregando el titulo;
%if ~&exists_title1 %then %do;
	title1 &title;
%end;
legend1 frame cframe=ligr cborder=black position=center value=(justify=center);
proc gplot data=&data;
	symbol1 color=blue  value=dot interpol=none height=&height;
		%** PREGUNTA: El symbol1 statement de arriba para que esta, si mas arriba se llama a
		%* %DefineSymbols y alli se define symbol1 tal cual esta definido aqui? (DM, 5/8/03);
	plot &varY * &varX = &strata / &options;
run;
quit;
%* Reseteando el titulo principal a nada;
%if ~&exists_title1 %then %do;
	title1;
%end;
%*** Reseteando el formato de symbol1;
symbol1;
%* Reseteando los valores default de goptions en caso de que &goptions no sea vacio
%* (Todavia no encontre la manera de resetear a los valores antes de cambiar los goptions.)
%* Existe proc goptions, pero solamente muestra los valores de las opciones en el log.
%* Bueno, descubri que se puede usar la funcion getoption() junto con %sysfunc para
%* leer el valor de una opcion, pero esto hay que hacerlo para cada opcion cambiada;
%if %quote(&goptions) ~= %then
	goptions 	device=&_device_ gsfname=&_gsfname_ gsfmode=&_gsfmode_ 
				xmax=&_xmax_ ymax=&_ymax_ hsize=&_hsize_ vsize=&_vsize_;
%MEND GraphXY;
