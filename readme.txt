Instructions to compile the SAS macros contained in directory "Compile" and the IML modules contained in directory "iml"
------------------------------------------------------------------------------------------------------------------------
Created: 12-Aug-2011
Author: Daniel Mastropietro
SAS Version: 9.x

Compilation of SAS Macros:
Execute the SAS code CompileMacros.sas

Compilation of IML modules:
Execute the SAS code CompileIML.sas

If nothing is changed in the above two codes, their execution creates a library reference in SAS called "Macros", where the following catalog entries will be seen:
IMLLabModelos	(containing the compiled IML modules)
Sasmacr		(containing the compiled SAS macros)

Note that I did not change the name of the IML catalog (to simply "IML" for example) because the name IMLLabModelos is already referenced in the macros using the compiled IML modules (e.g. %Mahalanobis).


TimeSeries folder
-----------------
Initially created in Sep-2011 to hold the time series macros used to forecast rating and demand for the TV Azteca project in 2006 while working at SAS Mexico.
The main macro is %ARIMAAdj which is defined at com_mac_arimaadj.sas.
I did a copy of this code which I called arimaadj.sas and added the TimeSeries folder to the Autocall path in C:\Daniel\SAS\code\startup\autoexec-Daniel.sas, so that it is automatically found when it is called. Note that I started doing some improvements to this macro, while the original code is kept as com_mac_arimadadj.sas.
See comments at the top of arimaadj.sas for more information on the changes.

in Aug-2012 I have added some external macros in this folder, such as SAS2012TerryWoodfield\ForecastUtilityMacros.sas, a set of macros developed by Terry Woodfield, last updated in Mar-2012. More information at SAS2012TerryWoodfield\readme.txt.

DMmacrosSAS.zip
---------------
Zip file containing the macros bundle that I submitted to Toolpool in SAS in Mar-2013. Contact in Toolpool who accepted and uploaded the submission: Loren Hodge.
The folder contains: 
- doc: folder containing a PDF file with the macros documentation and installation instructions (pdf file generated from 'help\SAS Compiled Macros - v201303.doc' or a similar version)
- source: folder containing the macros source code (which is a copy of the Compile folder and the IML folder which was placed inside 'source').
- CompileIML.sas: SAS code that compiles the IML code and generates the IMLLabModelos.sas7bcat catalog.
- CreateCompileMacrosCode.sas: SAS code that generates another SAS code to compile the macros listed in folder 'source' to the desired location.
- IMLLabModelos.sas7bcat: SAS catalog containing the compiled IML code (compiled under platform Windows 7, 64-bit, SAS 9.3_M2).
- sasmacr.sas7bcat: SAS catalog containing the compiled SAS macros (compiled under platform Windows 7, 64-bit, SAS 9.3_M2).

Ejemplos folder
---------------
Ejemplos de uso de las macros que se acumularon con el tiempo. Ej: proyecto SAS EG con analisis exploratorios con datos de Pronto, Uruguay (creado en Feb-2016).
