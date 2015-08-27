/* MACRO %SelectNames
This macro calls %SelectName.
See SelectName.sas for more information.
*/
&rsubmit;
%MACRO SelectNames(list, first, last, sep=%quote( ))
	/ store des="Calls %SelectName";
%* Note below that the semicolon should not be used because otherwise a semicolon is added
%* to the returned value of %SelectName!!!;
%SelectName(%quote(&list), &first, &last, sep=%quote(&sep))
%MEND SelectNames;
