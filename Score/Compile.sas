/* Compile.sas
Creado: 01/08/05
Modificado: 21/09/05
Autor: Daniel Mastropietro
Titulo: Compilacion de las macros necesarias para generar el score de una regresion logistica.

Descripcion: Se compilan con MSTORED las macros necesarias para generar el score UW2 para
nuevas cuentas.
Se efectua tanto la compilacion en local como en el servidor.
*/

/*------------------------------------ LOCAL ------------------------------------------------*/
/*----- Startup settings ------*/
%let codedir = C:\SAS\Macros\score;
%let scoredir = &codedir;
%let score = score;	* Libname donde compilar las macros;
%let access = ;		* Defino la macro variable ACCESS que define si el acceso a la liberia 
					* que se mapea en STARTUP es readonly o no. Vacio significa que no es readonly,
					* asi puedo compilar las macros. En caso de querer acceso readonly, asignar 
					* el valor ACCESS=READONLY; 
%let rsubmit = ;	* Defino la macro variable RSUBMIT que esta dentro de cada include;
/*----- Startup settings ------*/

* Guardo las opciones MSTORED y SASMSTORE actuales;
%let mstored = %sysfunc(getoption(mstored)); %put &mstored;
%let sasmstore = %sysfunc(getoption(sasmstore)); %put &sasmstore;
libname &score "&scoredir";
options mstored sasmstore=&score;
* Compilo las macros;
%include "&codedir\Macros.sas";
%include "&codedir\PrepareToScore.sas";
%include "&codedir\GenerateScore.sas";
%include "&codedir\Score.sas";
* Remove lock to UW2SCORE libname so that it can be assigned as READONLY by another SAS session
* (this was suggested by SAS Technical support on 18/8/05);
options sasmstore=sashelp;
%macro dummy / store; %mend;	* Compile dummy macro into sashelp;
libname &score;
%* Vuelvo al SASMSTORE original;
options &mstored sasmstore=&sasmstore;
/*------------------------------------ LOCAL ------------------------------------------------*/

/*---------------------------------- SERVIDOR -----------------------------------------------*/
/*----- Startup settings ------*/
%let codedir = C:\SAS\macros\score;
%let rsubmit = rsubmit;		* Defino la macro variable RSUBMIT que esta dentro de cada include;
rsubmit;
%let scoredir = /herramientas/sas/dmastro/score;
%let score = score;	* Libname donde compilar las macros;
%let access = ;		* Defino la macro variable ACCESS que define si el acceso a la liberia 
					* que se mapea en STARTUP es readonly o no. Vacio significa que no es readonly,
					* asi puedo compilar las macros. En caso de querer acceso readonly, asignar 
					* el valor ACCESS=READONLY; 
endrsubmit;
/*----- Startup settings ------*/

* Guardo las opciones MSTORED y SASMSTORE actuales;
rsubmit;
%let mstored = %sysfunc(getoption(mstored)); %put &mstored;
%let sasmstore = %sysfunc(getoption(sasmstore)); %put &sasmstore;
libname &score "&scoredir";
options mstored sasmstore=&score;
endrsubmit;
* Compilo las macros;
%include "&codedir\Macros.sas"; endrsubmit;
%include "&codedir\PrepareToScore.sas"; endrsubmit;
%include "&codedir\GenerateScore.sas"; endrsubmit;
%include "&codedir\Score.sas"; endrsubmit;
* Remove lock to UW2SCORE libname so that it can be assigned as READONLY by another SAS session
* (this was suggested by SAS Technical support on 18/8/05);
rsubmit;
options sasmstore=sashelp;
%macro dummy / store; %mend;	* Compile dummy macro into sashelp;
libname &score;
%* Vuelvo al SASMSTORE original;
options &mstored sasmstore=&sasmstore;
endrsubmit;
%* Restauro el valor de RSUBMIT a vacio;
%let rsubmit = ;
/*---------------------------------- SERVIDOR -----------------------------------------------*/
