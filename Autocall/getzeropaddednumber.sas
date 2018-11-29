/* MACRO %GetZeroPaddedNumber
Version: 		1.00
Author: 		Daniel Mastropietro
Created: 		29-Nov-2018
Modified: 		29-Nov-2018
SAS Version:	9.4

DESCRIPTION:
Returns a string representing a number (NUM) in zero padded format
based on a given maximum number (MAXNUM).

USAGE:
%GetZeroPaddedNumber(num, maxnum);

EXAMPLES:
%put %GetZeroPaddedNumber(13, 1032);	* Shows 0013;

APPLICATIONS:
Given a set of numbers to generate, e.g. from 1 to a given maximum, this macro
returns each of those numbers zero padded so that their string length is the same,
e.g. 01 02 03 04 05 06 07 08 09 10
if the maximum number to generate is 10.
*/
%MACRO GetZeroPaddedNumber(num, maxnum) / des="Returns a zero padded number";
%local npads;
%let npads = %eval( %sysfunc( floor( %sysfunc(log10(&maxnum)) ) ) + 1 );
%sysfunc(putn(&num, z&npads..))
%MEND GetZeroPaddedNumber;
