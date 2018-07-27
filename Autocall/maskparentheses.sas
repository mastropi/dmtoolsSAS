/* Created: 27-Jul-2018
Macro that masks open and close parentheses in the input NAME by adding a '%' before them.
This is useful so that %NRBQUOTE(&name) does not treat any parenthesis occurring in name as an actual parenthesis.
This macro for instance is used by the %FindMatch macro.
*/
%MACRO MaskParentheses(name) / des="Masks open and close parentheses in a name";
%let name = %sysfunc(transtrn(%nrbquote(&name), %quote(%(), %quote(%%%() ));
%let name = %sysfunc(transtrn(%nrbquote(&name), %quote(%)), %quote(%%%)) ));
&name
%MEND MaskParentheses;
