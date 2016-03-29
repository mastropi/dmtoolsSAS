/* Puts-Test.sas
Created: 		15-Feb-2016
Author: 		Daniel Mastropietro
Description: 	Tests run on macro %Puts
Dependencies:	None
Notes:			None
Ref:			'Versions/Puts Versions.txt'
*/


/*======================================== 2016/02/04 =======================================*/
* Version 1.01;
%puts(%quote(test xx   ));
%puts(%str( | z | x | | 0), sep=%quote(|));		%* We should see 5 elements;
%puts(%str(| z | x | | 0), sep=%quote(|));		%* We should see 4 elements (as the first character is the separator);
%puts(%str(| z | x | | ), sep=%quote(|));		%* We should see 4 elements;
%puts(%str( | z | x | | ), sep=%quote(|));		%* We should see 5 elements;
%puts(%str( | z | x | |), sep=%quote(|));		%* We should see 4 elements (as the last character is the separator);
%puts(%str( | z | x || ), sep=%quote(|));		%* We should see 4 elements (as two consecutive || should be considered as one single |);
%puts(%str(test x z y), sep=%quote( ));			%* We should see 4 elements;
%puts(%str(  test x z y  ), sep=%quote( ));		%* We should see 4 elements (as the first and last characters are separators);
%puts(%str(test x z y), sep=%quote(|));			%* We should see 1 element;
%puts(%str(test x z y  ), sep=%quote( ));		%* We should see 4 element;
%puts(%str(, test, x, z, y,), sep=%quote(,));	%* We should see 4 elements (as the first and last characters are separators);
%puts(%str( , test, x, z, y,), sep=%quote(,));	%* We should see 5 elements (as the last characters are separators but there is a blank space at the beginning);

%puts(%str(| z), sep=%quote(|));
/*======================================== 2016/02/04 =======================================*/
