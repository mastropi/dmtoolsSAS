/* Delete one or more data sets */
&rsubmit;
%MACRO delet(dat) / store des="Deletes datasets";
proc datasets nolist;
	delete &dat;
quit;
%MEND delet;
