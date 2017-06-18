/* InformationValue-Test.sas
Created: 		17-Aug-2005
Modified: 		17-Jun-2017 (previous: 12-Aug-2006)
Author: 		Daniel Mastropietro
Description: 	Tests run on macro %InformationValue.
*/

*** Test dataset taken from "Credit Scoring for Risk Managers" de Elizabeth Mays, pag. 97.
*** The values of WOE and IV are shown as a reference of what the values should be;
data testiv;
	input group good bad WOE IV;
	length z $5;
	do i = 1 to good;
		obs = _N_;
		y = 0; 
		z = "Good";
		output;
	end;
	do i = 1 to bad;
		obs = _N_;
		y = 1; 
		z = "Bad";
		output;
	end;
	length z $5;
	drop good bad;
	datalines;
1	12125	31	1.35	0.050
2	12112	44	1.00	0.032
3	12126	30	1.38	0.052
4	12118	38	1.15	0.039
5	12107	49	0.89	0.026
6	12091	65	0.61	0.014
7	12098	59	0.71	0.018
8	12084	72	0.51	0.010
9	12101	55	0.78	0.021
10	12044	112	0.06	0.000
11	12087	69	0.55	0.012
12	12085	71	0.52	0.011
13	12062	94	0.24	0.003
14	12105	52	0.83	0.024
15	12126	30	1.38	0.052
16	12125	31	1.35	0.050
17	11975	181	-0.43	0.011
18	11959	197	-0.51	0.017
19	11524	632	-1.71	0.374
20	11691	466	-1.40	0.206
;
* The IV total value is 1.022;

proc freq data=testiv;
	tables group*y;
run;

* Format for group to test parameter FORMAT=;
proc format;
	value group 1-8 = '1-8'
				9-13 = '9-13'
				14-20 = '14-20';
run;

%InformationValue(testiv, target=y, var=group, groups=20);	* IV = 1.022, IVAdj = 1.022, IVEntropyAdj = 0.256;
* Treat the analysis variable GROUP as categorical;
%InformationValue(testiv, target=y, var=group, groups=);	* IV = 1.022, IVAdj = 0.511 (IV adjusted to 10 groups), IVEntropyAdj = 0.256;
%InformationValue(testiv, target=z, var=group, groups=20, event="Bad");	* IV = 1.022, IVAdj = 1.022, IVEntropyAdj = 0.256;
%InformationValue(testiv, target=y, var=group, formats=group group., event=0);	* Default: 10 groups: IV = 0.809, IVAdj = 4.046, IVEntropyAdj = 0.539;
%InformationValue(testiv, target=z, var=group, event="Bad", formats=group group., groups=); * No grouping: IV = 0.459, IVAdj = 1.531, IVEntropyAdj = 0.221;
%InformationValue(testiv, target=y, var=group, value=max, outformat=_informationformats_, groups=20); * IV = 1.022, IVAdj = 1.022, IVEntropyAdj = 0.256;
%InformationValue(testiv, target=z, var=group, value=max, outformat=_informationformats_, groups=20); * IV = 1.022, IVAdj = 1.022, IVEntropyAdj = 0.256;
** (17/08/05) v1.00: OK;
** (13/08/06) v1.01: OK;
** (31/07/12) v3.00: OK;	** added the SMOOTH= parameter to compute smoothed WOE values;
** (15/04/16) v3.02: OK;	** added the OUTFORMAT= parameter;
** (17/05/16) v3.03: OK; 	** renamed FORMAT= parameter with FORMATS= parameter to adapt to new version 2.02 of %FreqMult;
** (17/06/18) v4.00: OK;

* Tests on SASHELP.HEART;
%FreqMult(sashelp.heart, target=status);
%InformationValue(sashelp.heart, target=status, var=_ALL_, groups=, out=_informationvalue1_, outtable=_informationtable1_);
%InformationValue(sashelp.heart, target=status, var=_ALL_, groups=, out=_iv_, outtable=_it_);
%InformationValue(sashelp.heart, target=status, var=AgeAtStart AgeCHDdiag Smoking Smoking_Status Weight_Status Weight Sex, groups=20, out=_ivadj1_, outtable=_itadj1_);
%InformationValue(sashelp.heart, target=status, var=AgeAtDeath AgeAtStart AgeCHDdiag Height Weight Sex, groups=);

proc print data=_informationtable_;
run;
