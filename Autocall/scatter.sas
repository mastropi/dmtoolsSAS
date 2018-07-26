/* MACRO %Scatter
Version: 1.02
Author: Daniel Mastropietro
Created: 21-Jan-03
Modified: 28-Jul-03

DESCRIPTION:
Esta macro realiza scatter plots de a pares a partir de un conjunto
de variables, y los ubica en una misma ventana gráfica.

USAGE:
%Scatter(	data ,				*** Dataset con las variables a graficar
			var=_numeric_ ,		*** Variables a graficar
			with= ,				*** Variables contra las cual graficar 'var'
			strata= ,			*** Variable que define distintos grupos
			nolabels=0 ,		*** No labels
			novalues=0 ,		*** No tick mark values
			sizeofvalues=8 ,	*** Tamaño de los tick mark values
			format= ,			*** Formato numérico de los tick mark values
			title="Scatter plots");	*** Título del gráfico

REQUESTED PARAMETERS:
- data:			Input dataset con las variables a graficar. Puede recibir
				cualquier opción adicional como en cualquier opción
				data= de SAS.

OPTIONAL PARAMETERS:
- var:			Lista de las variables a graficar (separadas por espacios).
				Si el parámetro 'with' no se especifica, los scatter plots
				son gráficos de estas variables consigo mismas.
				Si el parámetro 'with' no es vacío, estas variables se ubican
				en las filas del scatter plots y se grafican vs. las variables
				listadas en 'with'. 
				default: _numeric_, es decir, todas las variables numéricas

- with:			Lista de variables a ubicar en las columnas del scatter plot. 
				Si este parámetro no se especifica, se grafican las variables
				en 'var' contra sí mismas.

- strata:		Nombre de la variable que define los estratos o grupos.
				Para cada valor distinto en esta columna se usa un color
				distinto en el gráfico.
				Si los estratos están definidos por más de una variable
				puede usarse la macro %CreateGroupVar para generar una
				única variable indicadora de los estratos a partir de
				una lista de variables.

- nolabels:		Define si los labels de los ejes se muestran.
				Puede ser útil eliminar los labels si hay muchos scatter
				plots realizados.
				Valores posibles: 0 => Se muestran, 1 => No se muestran.
				default: 0

- novalues:		Define si los valores de los tick marks se muestran.
				Puede ser útil eliminar los valores de los tick marks en
				caso de que los valores de las variables sean muy grandes,
				para poder ver apropiadamente los gráficos.
				Valores posibles: 0 => Se muestran, 1 => No se muestran.
				default: 0

- sizeofvalues:	Tamaño del font (en points) a usar para los valores de los
				tick marks.
				Puede ser útil achicar el tamaño del font si hay muchos scatter
				plots realizados.
				default: 8

- format:		Formato a usar para los valores de los tick marks.
				Puede resultar conveniente usar el formato exponencial Ew.d
				en caso de que los valores de las variables sean muy grandes, o
				bien para que los tamaños de los distintos scatter plots sean
				iguales (ya que en el formato exponencial los números tienen
				todos la misma longitud). (ej: E7.2) (aparentemente el valor
				minimo para w es 7.)
				default: ninguno (i.e. se mantiene el formato de las variables
				graficadas)

- title:		Título a colocar en el gráfico.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %DefineSymbols
- %GetNroElements
- %GetVarList
- %MPlot

SEE ALSO:
- %GraphXY
- %MPlot

EXAMPLES:
- %scatter(toplot , var=x y z , nolabels=1)
Genera una scatter matrix de 2x2 donde se grafica x vs. y, x vs. z, y vs. z, sin
que aparezcan los nombres de las variables graficadas.

- %scatter(toplot , var=x y z , with=x z w)
Genera una scatter matrix de 3x3 donde se grafica x vs. (x z w), y vs. (x z w),
z vs. (x z w).
*/
%MACRO Scatter(	data ,
				var=_NUMERIC_ , 
				with= ,
				strata= ,
				/* diagonal=histogram , */
				nolabels=0 ,
				novalues=0 ,
				sizeofvalues=8 ,
				format= ,
				title=)
	/ des="Makes bivariate scatter plots arranged in a panel";
%local i j k firstvar nvars nvars_with;
%local col row nro_cols nro_rows;
%local formatst label plots value;

%*Setting nonotes option and getting current options settings;
%SetSASOptions;

/* Initial settings */
%*** Define los simbolos a usar en los plots;
%DefineSymbols;
%*** Si la variable estratificadora &strata es vacia, asignarle el valor 1, que representa
%*** el numero de simbolo a usar en los graficos;
%if %quote(&strata) = %then
	%let strata = 1;
%*** Transforma &var en una lista de variables separada por espacios;
%let var = %GetVarList(&data, var=&var, log=0);

%* Row variables (i.e. to be distributed along the vertical direction of the window);
%let nvars = %GetNroElements(&var);
%do k = 1 %to &nvars;
	%local rowvar&k;
	%let rowvar&k = %scan(&var , &k , ' ');
%end;

%if &nvars <= 1 and %quote(&with) = %then
	%put SCATTER: ERROR - The number of variables in var= must be greater than 1 if with= is not specified;	
%else %do;

%if %quote(&with) = %then %do;
	%let nvars_with = &nvars;
	%do k = 1 %to &nvars_with;
		%local colvar&k;
		%let colvar&k = &&rowvar&k;
	%end;
%end;
%else %do;
	%let with = %GetVarList(&data, var=&with, log=0);
	%let nvars_with = %GetNroElements(&with);
	%do k = 1 %to &nvars_with;
		%local colvar&k;
		%let colvar&k = %scan(&with , &k , ' ');
	%end;
%end;

%let plots =;
%let k = 1;		%*** Contador para definir los axis statement;
%do i = 1 %to &nvars;
	%if %quote(&with) = %then
		%let firstvar = %eval(&i+1);
	%else
		%let firstvar = 1;
	%do j = &firstvar %to &nvars_with;
/*
		%*** Histogramas de cada variable en la diagonal;
		%if &i = &j %then %do;
			%let plots = &plots %str(
				proc univariate data=&data gout=work._tempgraphs_ noprint;
					var &&rowvar&i;
					&diagonal / name="plot&i&i";
				run;);
		%end;
		%else %do;
*/
			%*** row y col definen la ubicacion del grafico en la matriz de graficos;
			%let row = &i;
			%if %quote(&with) = %then
				%let col = %eval(&j-1);
			%else
				%let col = &j;

			%if &j = &firstvar %then %do;
				/* Me fijo si el grafico esta en la diagonal */
				%*** NOTA: Es posible que los graficos de la diagonal no sean distintos a los que
				%*** no estan en la diagonal. Sin embargo los dejo separados por si en un futuro
				%*** decido agregar algo en la diagonal, como por ej. los histogramas de las variables;
				%*******************************************************************************;
				%*** OJO que con el nombre usado para los axis (axis1&k y axis2&k) el numero de axis 
				%*** no puede ser mayor que 255. Por esto es que uso un contador aparte para los axis, 
				%*** en lugar de etiquetarlos con &i&j;
				%*******************************************************************************;
				%*** NOTAR que en los %if %then para definir los valores de las variables &label y &value
				%*** uso %do aunque no haria falta pero es una cuestion de que SAS no siempre
				%*** se comporta bien sin poner los %do;
				%*******************************************************************************;

				%*** Horizontal axis;
				%if %quote(&nolabels) %then %do; 	%let label = none; %end;
				%else %do;							%let label = ("&&colvar&j"); %end;
				%if %quote(&novalues) %then	%do;	%let value = none; %end;
				%else %do;							%let value = (height=&sizeofvalues pt); %end;
				axis1&k 
						label=&label
						value=&value;
					/*
					Nota 1: Existe una opcion del axis statement que es ORIGIN (por ejemplo origin=(10 pct , 10 pct))
					El origin= es para definir la posicion de la esquina inferior izquierda del grafico relativa
					al area de graficacion, pero no anduvo bien, pues no es respetado si el tamanho de los tick mark
					labels es muy grande. 
					Tambien se podria poner como opcion en el axis2. 
					Nota 2: En el label= option la opcion angle=90 DEBE IR ANTES del texto, de lo contrario
					SAS muestra el label de cualquier forma (sin rotarlo 90 grados).
					*/
				%*** Vertical axis;
				%if %quote(&nolabels) %then	%do;	%let label = none; %end;
				%else %do;							%let label = (angle=90 justify=center "&&rowvar&i"); %end;
				%if %quote(&novalues) %then	%do;	%let value = none; %end;
				%else %do;							%let value = (height=&sizeofvalues pt); %end;
				axis2&k 
						label=&label
						value=&value;
			%end;
			%else %do;
				%*** Horizontal axis;
				%if %quote(&nolabels) %then	%do;	%let label = none; %end;
				%else %do;							%let label = ("&&colvar&j"); %end;
				%if %quote(&novalues) %then	%do;	%let value = none; %end;
				%else %do;							%let value = (height=&sizeofvalues pt); %end;
				axis1&k
						label=&label
						value=&value;
				%*** Vertical axis;
				%if %quote(&nolabels) %then	%do;	%let label = none; %end;
				%else %do;							%let label = (angle=90 justify=center "&&rowvar&i"); %end;
				%if %quote(&novalues) %then	%do;	%let value = none;	%end;
				%else %do;							%let value = (height=&sizeofvalues pt); %end;
				axis2&k 
						label=&label
						value=&value;
			%end;
			%let formatst = ;
			%if %quote(&format) ~= %then
				%let formatst = format &&rowvar&i &&colvar&j &format;
			%let plots = &plots %str(&formatst;
					plot &&rowvar&i * &&colvar&j = &strata / name="plot&row&col" haxis=axis1&k vaxis=axis2&k;);
			%*** Incremento el contador para los axis statements;
			%let k = %eval(&k + 1);
/*		%end; */
	%end;
%end;

%let plots = %str(
proc gplot data=&data gout=work._tempgraphs_;
&plots;
run;
quit;);

%if %quote(&title) = %then %do;
	%if %quote(&with) = %then
		%let title = %str("Scatter plots (%upcase(&data))" justify=center "%upcase(&var)");
	%else
		%let title = %str("Scatter plots (%upcase(&data))" justify=center "%upcase(&var)    vs.    %upcase(&with)");
%end;

/* Plots */
%if %quote(&with) = %then %do;
	%let nro_rows = %eval(&nvars-1);
	%let nro_cols = %eval(&nvars-1);
%end;
%else %do;
	%let nro_rows = &nvars;
	%let nro_cols = &nvars_with;
%end;
%mplot(	&plots , &nro_rows , &nro_cols , tempcat=_tempgraphs_ , 
		matrix=1 , hfactor=1 , vfactor=1 , frame=1 , 
		title=&title , description="Scatter plots of %upcase(&var) (%upcase(&data))" , nonotes=1);

%* Borro el catalogo temporario usado en %Mplot para poner los graficos generados
%* por gplot y luego leidos por greplay para mostrar el scatter plot;
proc catalog catalog=work._tempgraphs_ kill;
run;
proc datasets lib=work memtype=catalog nolist;
	delete _tempgraphs_;
quit;

%end;	/* %if &nvars <= 1 and %quote(&with) = */

%ResetSASOptions;
%MEND Scatter;
