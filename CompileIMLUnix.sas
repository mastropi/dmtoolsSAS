/* CompileIMLUnix.sas
Author: Daniel Mastropietro
Created: 16/05/03
Modified: 12/06/06

DESCRIPTION:
Compila los modulos IML en UNIX y los graba en los catalogos especificados en la
variable &storage.
La macro variable &storage puede ser una lista de catalogos separados por espacios.
Para compilar los modulos en mas catalogos deben agregarse libname's apropiadamente
con las referencias a los directorios donde se desea ubicar los catalogos, y luego
listar dichos catalogos en la macro variable &storage.
Ej: Lo siguiente compila los modulos en catalogos llamados 'cat1' y 'cat2' en los
directorios referenciados por 'dir1' y 'dir2'.
libname dir1 "dir1";
libname dir2 "dir2";
%let storage = dir1.cat1 dir2.cat2;

NOTES:
Para que la compilacion funcione, se debe tener acceso a la macro %GetNroElements que es
llamada desde las macros que compilan cada modulo.
Para comodidad, esta macro se define en este codigo.
*/
rsubmit;
libname dir "/free/SAS/SAS_9.1/sasmacros";
%let catref = IML;
%let storage = dir.&catref;
/* Definicion de la macro %GetNroElements usada por las macros que compilan los modulos
(Si tengo el seteo para las autocall macros en Unix, entonces esta definicion no hace falta) */
%MACRO GetNroElements(list , sep=%quote( ));
%local i element nro_elements;

%let i = 0;
%do %until(&element =);
	%let i = %eval(&i + 1);
	%let element = %scan(%quote(&list) , &i , %quote(&sep ));
		%*** Notice there is a space after &sep. This is to have the correct number of elements when
		%*** there are blanks between the separators in &sep, such as in x . ..y. .z, where sep=.;
%end;
%let nro_elements = %eval(&i - 1);
&nro_elements
%MEND GetNroElements;
endrsubmit;
/* Compilacion de los modulos */
%let rsubmit = rsubmit;
%include "C:\SAS\Macros\IML\GInverseCompile.sas"; endrsubmit;
%include "C:\SAS\Macros\IML\MahalanobisCompile.sas"; endrsubmit;
%include "C:\SAS\Macros\IML\OrderCompile.sas"; endrsubmit;
rsubmit;
%GinverseCompile(&storage);
%MahalanobisCompile(&storage);
%OrderCompile(&storage);
endrsubmit;
