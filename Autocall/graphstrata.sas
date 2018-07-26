/* MACRO %GraphStrata
******* ESTA MACRO ES OBSOLETA A PARTIR DE 15/1/03. USAR %GraphXY *******
Version: 1.00
Author: Santiago Laplagne
Created: 17-Dec-02
Modified: 06-Jan-03

DESCRIPTION:
Realiza un scatter plot de dos variables, usando distintos colores según
una columna que define estratos o grupos.

USAGE:
%GraphStrata(	data, varX, varY, varStrata, file= ,
				title="Scatter plot of 'varY' vs. 'varX' by 'varStrata'",
				height = 0.8);

REQUESTED PARAMETERS:
- data:			Input dataset con los datos a utilizar. Puede recibir
				cualquier opción adicional como en cualquier opción data=
				de SAS.
- varX:			Nombre de la variable 'x' para graficar los puntos de
				coordenadas	(x, y).
- varY:			Nombre de la variable 'y' para graficar los puntos de 
				coordenadas (x, y).
- varStrata:	Nombre de la variable que define los estratos o grupos.
				Para cada valor distinto en esta columna se usa un color
				distinto en el gráfico.
				Si los estratos están definidos por más de una variable
				puede usarse la macro %CreateGroupVar para generar una
				única variable indicadora de los estratos a partir de
				una lista de variables.

OPTIONAL PARAMETERS:
- file:			Nombre del archivo donde guardar el gráfico en formato JPG.
				Debe indicarse entre comillas la ubicación y el nombre del
				archivo a utilizar.
				En caso de pasar este parámetro, no se muestra ningún
				gráfico en pantalla.
- title:		Título del gráfico (puede ser entre comillas o no).
				default: "Scatter plot of 'varY' vs 'varX' by 'varStrata'"
- height:		Tamaño de los símbolos a utilizar en el gráfico.
				default: 0.8

NOTES:
- Esta macro puede usarse para graficar la salida 'outAll' de las macros 
%CutMahalanobisChi y %Hadi.

OTHER MACROS USED IN THIS MACRO:
- %DefineSymbols

SEE ALSO:
- %CutMahalanobisChi
- %Hadi

EXAMPLES:
- graphStrata(data, x, y, grupo, file="C:\graficos\xy.jpg", title="Por grupo");
*/
%macro GraphStrata (data, varX, varY, varStrata, file= , 
					title=, height = 0.8) / des="Use %GraphXY instead";
%local options;

%put GRAPHSTRATA: WARNING - The use of %GraphStrata is obsolete, and will be discontinued.;
%put GRAPHSTRATA: You should use %GraphXY and specify the strata variable in the strata= option.;
	%DefineSymbols (height = &height);
	%if (%quote(&file) ne) %then %let options = %STR (device=jpeg gsfname=file
		gsfmode=replace xmax=8in hsize=8in ymax=6in vsize=6in); 
	%else %let options = ;
	goptions 	&options 
				ftext=swiss
			 	fontres=presentation;
	%if (%quote(&file) ne) %then %do; FILENAME file &file; %end;
	%if (%quote(&title) =) %then %do; %let title = "Scatter plot of &varY vs &varX by &varStrata"; %end;
	title &title;
	legend1 frame cframe=ligr cborder=black position=center 
		value=(justify=center);
	
	proc gplot data=&data;
		plot &varY*&varX=&varStrata;
	run;
	quit;
	title;
	symbol1;	%*** Reseteando el formato de symbol1;
	%*** Reseteando los valores default (Todavia no encontre la manera de resetear a los
	%*** valores antes de cambiar los goptions);
	%*** Existe proc goptions, pero solamente muestra los valores de las opciones en el log;
	goptions reset=goptions;
%mend GraphStrata;
