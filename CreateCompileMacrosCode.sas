/* CreateCompileMacrosCode.sas
Created: 		18-Aug-2005
Modified: 		12-Aug-2015 (added ACCESSOPT macro variable that defines whether we want to assign the macro store as readonly or not)
Author: 		Daniel Mastropietro
Description: 	Create the code to compile the SAS macros that are available in a given directory into a
				compiled catalog that is used as a SASMSTORE catalog to run the macros.
				The compilation code is called CompileMacros.sas and is stored in the directory defined
				below by the macro variable &compiledir.
Notes:			It is assumed that the platform is Windows (since the separator used for directories is '\').
				The code can be adapted to Unix platforms by changing the directory separator to '/', both
				in the macro variables definition and in a few other parts of the code where the separator is used.

****************** IMPORTANT NOTE ABOUT THE UPDATE OF COMPILED MACROS ************************
In order to update the compiled macros catalog, it is necessary to map the catalog as
NOT read-only. However this cannot be done unless the following trick is performed, namely:
before mapping the catalog as not read-only submit the following statements:

options sasmstore=sasuser;
%macro dummy / store; %mend;

Now set the macro catalog (whose name is always sasmacr.sas7bcat) as not read-only by doing:

libname macros "&compiledir";
options sasmstore=macros;

Now submit the code that compiles the macros to be stored in the compiled macros catalog.

Finally unlock the SASMACR catalog just created and re-assign it as read-only by doing:
options sasmstore=sasuser;
%macro dummy / store;  %mend;

The above logic is followed by the code below that generates the CompileMacros.sas code
that is then run to compile or re-compile the SAS macros.

NOTE that this procedure is fine as long as the update of the compiled macros is done on a
local machine, but NOT when it is done on a server accessed by several users.
(In fact, it is not possible to remove the read-only property of the catalog because the catalog
may be in used by other users!)
In such scenario, it seems that just deleting the sasmacr.sas7bcat catalog and then
regenerating it by running the compilation code is enough to re-compile the macros catalog
(even if the catalog is mapped as read-only by a user). At least this worked for me on a Unix server.
****************** IMPORTANT NOTE ABOUT THE UPDATE OF COMPILED MACROS ************************
*/


/************************************ Set Macro Variables ************************************/
*** NOTE: All directories MUST EXIST prior to execution;
%let macrosdir = E:\SAS\Macros;						* Directory where SAS macros are usually stored in the system;
%let compiledir = &macrosdir\DMmacros;				* Directory to store the compiled macros; 
%let sourcedir = &macrosdir\DMmacros\source;		* Directory where the macro codes are located;
%let codefile = CompileMacros.sas;					* Name of the SAS code file that is created and run
													* to generate the SASMACR catalog containing the compiled macros;
%let librefmacros = macros;							* Name to use for the library reference to the location of the compiled macros;
%let maxfilenamelen = 60;							* Maximum number of characters of source code filenames
													* (this is needed to appropriately generate the compile code);
%let accessopt = ;									* Use access=readonly if we want the macro store to be readonly. Otherwise leave empty;  
%let run = 1;										* Flag 0/1: Run the compilation code?;
/************************************ Set Macro Variables ************************************/


/************************** Create SAS code for macro compilation ****************************/
* Directory listing of *.sas files;
filename macros PIPE "dir ""&sourcedir\*.sas"" /b";		* /b lists only the file names;

* COMPILEMACROS.SAS;
data _NULL_;
	file "&compiledir\&codefile";		* Output file which will contain the code to compile the macros;
	infile macros end=lastobs;			* Input file to read the filenames of the macros to compile;
	input filename :$&maxfilenamelen..;	* Variable to store the filename of each macro;
	if _N_ = 1 then do;
		put "* Code to compile macros into SASMSTORE catalog located in &compiledir;";
		put "* Created: &sysdate;";
		put;
		put "*--------------------------------------- Startup settings ----------------------------------;";
		put "* Location of macros source code;";
		put "%nrstr(%let) sourcepath = &sourcedir;";
		put "* Location of compiled macros (i.e. where the SASMACR catalog will be stored);";
		put "%nrstr(%let) outpath = &compiledir;";
		put "*--------------------------------------- Startup settings ----------------------------------;";
		put;
		put "* Unlock sasmacr catalog %upcase(&librefmacros) in case it exists;";
		put "options mstored sasmstore=sasuser;";
		put "%nrstr(%macro) dummy / store; %nrstr(%mend);";
		put "libname &librefmacros '&compiledir';";
		put "options mstored sasmstore=&librefmacros;";
		put "* Define macro variables used in each macro code;";
		put "%nrstr(%let rsubmit = ;)";
		put "* Compile macros;";
	end;
	* Remove *.sas files that are not codes or are backup codes;
	if ~index(upcase(filename), ".SAS7") and ~index(upcase(filename), ".BAK") and ~index(upcase(filename), "COPY OF") then do;
		count + 1;
		put "%include '&sourcedir\" filename +(-1) "';" @%length(include &sourcedir)+3+&maxfilenamelen.+2+1 "* " count +(-1) ";";
	end;
	if lastobs then do;
		put "* Unlock sasmacr catalog;";
		put "options sasmstore=sasuser;";
		put "%nrstr(%macro) dummy / store; %nrstr(%mend);";
		* Assign the MACROS library as readonly;
		put "libname &librefmacros '&compiledir' &accessopt;";
		put "options sasmstore=&librefmacros;";
	end;
run;
/*********************** Create codes for local and server compilations **********************/


/******************************* Compile macros on local *************************************/
* Compile macros;
%macro runit;
%if &run %then %do;
	%include "&compiledir\&codefile";
%end;
%mend runit;
%runit;
/******************************* Compile macros on local *************************************/
