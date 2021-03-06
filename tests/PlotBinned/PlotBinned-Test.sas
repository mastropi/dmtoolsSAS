/* PlotBinned-Test.sas
Created: 		18-Jul-2018
Modified:		18-Jul-2018
Author: 		Daniel Mastropietro
Description: 	Tests run on macro %PlotBinned
Dependencies:	%RunTestHarness macro
Notes:			The test code makes use of a test harness defined in the same directory.
				Test dataset source: ScoGMas-2015 at Pronto
					data totest;
						set scomast.master_pvp01_s2(keep=
							A_ID
							A_MES
							B_TARGET_DQ90_12M
							B_FUT_MESES_HASTA_CANCELADO
							C_CR_CRITERIO_INCL_GENERAL
							E_CR_NR_OTORG
							E_CR_PAGO_TIPO
							E_CR_VINCULACION
							V_CR_PROB_MORA_REF
							V_CR_CUOTA);
						where A_MES in (1, 2, 3);
						* Create missing value on a numeric variable that is analyzed as categorical in the tests;
						if _N_ in (3, 7, 10, 50, 90) then
							E_CR_NR_OTORG = .;
						if _N_ <= 1000;
					run;
*/


/*---------------------------- Run Test Harness ---------------------------------*/
* Setup;
%let testmacro = PlotBinned;
%let testpath = E:\Daniel\SAS\Macros\tests\&testmacro;
libname test "&testpath";

* Read the Test Harness dataset;
%import(TestHarness_&testmacro, "&testpath\TestHarness-&testmacro..csv");

* Run all tests;
%RunTestHarness(
	&testmacro,
	TestHarness_&testmacro,
	library=test,
	checkoutput=out outcorr,
	resultsdir=&testpath/expected
);
/*---------------------------- Run Test Harness ---------------------------------*/



/*------------------------ Generate expected results ----------------------------*/
* Setup;
%let testmacro = PlotBinned;
%let testpath = E:\Daniel\SAS\Macros\tests\&testmacro;
libname test "&testpath";
libname expected "&testpath/expected";

* Read the Test Harness dataset;
%import(TestHarness_&testmacro, "&testpath\TestHarness-&testmacro..csv");

%RunTestHarness(
	&testmacro,
	TestHarness_&testmacro,
	library=test,
	checkoutput=out outcorr,
	saveoutput=1,
	resultsdir=&testpath/expected
);
/*------------------------ Generate expected results ----------------------------*/
