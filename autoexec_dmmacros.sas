/* autoexec_dmmacros.sas
Created: 		12-Oct-2004
Modified: 		28-Jun-2017 (previous: 12-Aug-2011: removed the mrecall option since it decreases performance; 26/09/05: changed the location of the first directory to add to the sasautos option)
Description:	Autoexec file for access to autocall macros and compiled macros in Windows.
Usage: 			Use it at the SAS execution script, as follows:
				sas -autoexec "<this-file>"
*/

options linesize=140;

/* Autocall macros */
* Allow autoexecution of macros when invoked;
options mautosource;
* Add the folder with the autocall macros to the SASAUTOS option. This is necessary even when
* the macros are compiled macros so that the %Remap macro can be found;
options sasautos = (sasautos "C:\Daniel\SAS\Macros" "C:\SAS\Macros\Autocall" "C:\SAS\Macros\TimeSeries");

/* Compiled macros */
libname macros "C:\SAS\Macros" access=readonly;
options mstored sasmstore=macros;
* Add the folder containing the IML compiled modules to the SAS System user profile folder;
libname sasuser ("!MYSASFILES" "C:\SAS\Macros");
