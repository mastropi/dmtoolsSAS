/* MACRO %CreateDummyVar
y %CreateDummyMiss? (o ponerlo como un caso particular de esta macro? Mejor asi, no?)
*/
&rsubmit;
%MACRO dummy;
%CreateInteractions(var=&dummy_nomiss, with=&var_miss_fill, allInteractions=0, join=*, macrovar=dummy_nomiss_int);
%MEND dummy;
