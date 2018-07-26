/* Delete one or more data sets */
%MACRO delet(dat) / des="Deletes datasets";
proc datasets nolist;
	delete &dat;
quit;
%MEND delet;
