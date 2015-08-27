/* CompileIML.sas
Author: Daniel Mastropietro
Created: 2/1/03
Modified: 12-Aug-2011 (updated directory reference for dir1 and added %include statements to make sure that the compilation macros are found)

DESCRIPTION:
Compila los modulos IML y los graba en los catalogos especificados en la &storage.
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
*/
%let imldir = C:\SAS\Macros\iml;	* Directory where the IML modules are located;
libname dir1 "C:\SAS\Macros";		* First location to store the catalog with the compiled IML modules;
%let catref = IMLLabModelos;
%let storage = dir1.&catref;
/* Modulos a compilar */
%include "&imldir\GInverseCompile.sas";
%include "&imldir\MahalanobisCompile.sas";
%include "&imldir\OrderCompile.sas";
%GinverseCompile(&storage);
%MahalanobisCompile(&storage);
%OrderCompile(&storage);
libname dir1;
