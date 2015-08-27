/* MACRO %DefineSymbols
Version: 1.01
Author: Santiago Laplagne - Daniel Mastropietro
Created: 17-Dec-02
Modified: 25-Sep-04

DESCRIPTION:
Define simbolos de la misma forma pero con distintos colores para usar en 
los gráficos por estratos o grupos.

USAGE:
%DefineSymbols (height=1, value=dot);

REQUESTED PARAMETERS:
None

OPTIONAL PARAMETERS:
- height:	Tamaño de los simbolos a utilizar en el gráfico.
			default: 1

- value: 	Forma de los símbolos. Algunos posibles valores son: plus, dot, 
			circle, triangle. Ver la opción 'value' del statement SYMBOL
			de SAS/GRAPH.
			default: dot (punto relleno)

- log:		Show messages in the log?
			Possible values: 0 => No, 1 => Yes
			default: 1	

NOTES:
- Esta macro la usa la macro %GraphStrata para graficar los estratos con
distintos colores.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %Colors

SEE ALSO:
- %GraphXY
- %Colors
*/
&rsubmit;
%MACRO DefineSymbols(height=0.7, interpol=none, value=dot, n=10, log=1)
		/ store des="Defines symbols to be used for plotting";
%local i colors;
%let colors = %Colors(n=&n);
%do i = 1 %to &n;
	symbol&i color=%scan(&colors, &i) value=&value interpol=&interpol height=&height pointlabel=none;
	%if &log %then
		%put symbol&i color=%scan(&colors, &i) value=&value interpol=&interpol height=&height pointlabel=none;
%end;
%MEND DefineSymbols;
