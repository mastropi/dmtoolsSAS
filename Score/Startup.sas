/* startup.sas
Creado: 21/09/05
Autor: Daniel Mastropietro
Descripcion: Startup settings para acceder a las macros compiladas para scorear modelos de regresion
logistica.

***********************************************************************************************
DEBEN DEFINIRSE LAS SIGUIENTES MACRO VARIABLES PARA QUE EL CODIGO FUNCIONE:
- scoredir:	Directorio con las macros para SCORE compiladas.
- score:	Libname con otras macros para SCORE compiladas.

Luego ejecutar el codigo con un %include.
Ver ejemplo a continuacion.
***********************************************************************************************

**************************************** EJEMPLO **********************************************
%let scoredir = "C:\Macros\Score";
%let score = score;
%include "&scoredir\startup.sas";
***********************************************************************************************
*/

/*-------------------------- Macro variables a definir --------------------------------------*/
%put scoredir=&scoredir;	* Directorio con las macros para SCORE compiladas;
%put score=&score;		* Libname con las macros para SCORE compiladas;
/*-------------------------- Macro variables a definir --------------------------------------*/

/*----------------------------- Map de las macros compiladas --------------------------------*/
* Libname con OTRAS macros compiladas ya mapeado;
%let sasmstore = %sysfunc(getoption(sasmstore));
* Mapeo MACROSAL con los libnames de TODAS las macros compiladas;
libname &score "&scoredir" access=readonly;
libname macrosal (&sasmstore &score) access=readonly;
options mstored sasmstore=macrosal;
/*----------------------------- Map de las macros compiladas --------------------------------*/
