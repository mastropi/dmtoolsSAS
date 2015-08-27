/* Startup.sas 
Creado: 02/08/05
Modificado: 30/11/05
Autor: Daniel Mastropietro
Titulo: Startup settings para acceder a las macros que generan el score para una regresion logistica.

Descripcion: Se asigna por LIBNAME el directorio donde se encuentran las macros compiladas
que son necesarias para generar el score dde un modelo de regresion logistica desde Unix.
Las macros compiladas en el catalogo SASMACR.SAS7BCAT son el resultado de la compilacion de 
las macros definidas en los siguientes codigos presentes en el directorio
/sas/herramientas/dmastro/score/code:
- macros.sas
- preparetoscore.sas
- generatescore.sas
- score.sas
*/

* Leo el valor de SASMSTORE actual para poder recuperarlo luego del proceso de generacion del score;
%let sasmstore = %sysfunc(getoption(sasmstore)); %put SASMSTORE=&sasmstore;
* Map del directorio donde estan las macros compiladas para generar el score;
libname score "/herramientas/sas/dmastro/score" access=readonly;
options mstored sasmstore=score;
** Luego de concluir con el proceso de generacion del score, volver a la configuracion original
** de las macros mediante la siguiente linea:
options mstored (&sasmstore);
