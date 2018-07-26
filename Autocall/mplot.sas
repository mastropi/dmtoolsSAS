/* MACRO %MPlot
Version: 	1.00
Author: 	Daniel Mastropietro
Created: 	14-Jan-03
Modified: 	13-Jul-2012 (previous: 19-Feb-2003)
SAS:		v9.3

DESCRIPTION:
This macro makes several plots in the same window using a specified panel
structure.

USAGE:
%MPlot(	gplot ,					** Statements defining what to plot
		nrows ,					** Nro of rows in the panel
		ncols , 				** Nro of columns in the panel
		direction=byrows ,		** Direction to use to place the plots
		matrix=0 , 				** Do plot names use matrix-like notation?
		plotName=plot ,			** Root used for the plot names
		tempcat=work.tempcat ,	** Catalog to store temporary plots
		gout=work.gseg , 		** Catalog to store the multiple plot produced
		hfactor=1 ,				** Horizontal maximiz. factor for each plot
		vfactor=1 , 			** Vertical maximiz. factor for each plot
		frame=0 , 				** Put a frame in every plot?
		title="Multiple plot" ,	** Overall title
		description=&title);	** Plot description (as shown in 'Results')

REQUESTED PARAMETERS:
- gplot:		Statements defining what to plot. This can be any SAS/GRAPH
				procedure or any other procedure that generates high resolution
				plots (e.g. the histogram statement in proc univariate).
				Each plot must have a different name, which should be made up
				of a common root and a unique identification number (which
				must be between 1 and the number of cells in the panel used
				for plotting).
				See examples below.

- nrows:		Number of row panels into which the graph window is divided.

- ncols:		Number of column panels into which the graph window is divided.

OPTIONAL PARAMETERS:
- direction:	Direction by which the plots are placed in the panel.
				Possible values are 'byrows' and 'cols'.
				This value is irrelevant if matrix=1.
				default: byrows (i.e. the panel rows are filled before filling
				the columns, following the number sequence given in the plot
				names)

- matrix:		Defines whether the plot names defined in 'gplot' use
				matrix-like notation (e.g. plot11, plot12, plot21, etc.).
				Possible values: 0 => No matrix notation, 1 => Matrix notation
				default: 0 (i.e. the plot names are of the form plot1, plot2,
				plot3, etc.)

- plotName:		Root used for the plot names as defined in parameter 'gplot'.
				default: plot

- tempcat:		Name of the catalog to store temporary plots.
				default: work.tempcat

- gout:			Name of the catalog to store the multiple plot produced by
				the macro.
				default: work.gseg (i.e. the default catalog where the high
				resolution plots are stored by SAS)

- hfactor:		Horizontal maximization factor to be used for each plot,
				with respect to the default horizontal size.
				default: 1 (i.e. no maximization)

- vfactor:		Vertical maximization factor to be used for each plot,
				with respect to the default vertical size.
				default: 1 (i.e. no maximization)

- frame:		Defines whether each plot is enclosed in a frame.
				Possible values: 0 => No frame, 1 => Frame
				default: 0 (i.e. No frame)

- novalues:		Defines whether the tick mark values should be displayed.
				default: 0 (i.e. the values are displayed)

- title:		Overall title.
				default: "Multiple plot"

- description:	Plot description as seen in the 'Results' window.
				The description must be enclosed in quotes.
				It is useful for identifying the plot among other different
				plots in the graphics window.
				default: the same value as 'title'

- nonotes:		Defines whether notes are shown regarding the plot specified
				in parameter 'gplot'.
				Possible values: 0 => Notes are shown, 1 => No notes are shown
				default: 0 (i.e. notes are shown)

NOTES:
1.- When specifying the parameter 'gplot' use the %str function to mask SAS
statements and semicolons. Ex:
%let gplot = %str(
proc gplot data=toplot gout=tempcat;
	plot y*x / name="plot1";
	plot z*x / name="plot2";
run;);
(Notice that it is not necessary to use a quit statement to end the gplot
procedure.)

2.- The names given to the plots as specified in the procedure/s defined in
the parameter 'gplot' must not exist in the catalog selected for output in
such procedure/s (which is specified by the 'gout' option in the proc statement).
If no 'gout' option is specified, the default catalog is WORK.GSEG, and thus
the above condition must hold for this catalog.

3.- In order to avoid problems with already existent plot names, use option
'gout=tempcat' in the procedure/s defined in 'gplot', where tempcat is a catalog
that should be empty or non existent. By default, %MPlot uses a catalog named
'tempcat' as the catalog for storing temporary plots (as those produced by
the procedure/s specified in 'gplot').
See examples 1 and 2 below.

OTHER MACROS AND MODULES USED IN THIS MACRO:
- %ResetSASOptions
- %SetSASOptions

SEE ALSO:
- %Scatter
- %GraphXY

EXAMPLES:
1.- Doing two plots in a 2x1 panel structure:
%let gplot = %str(
proc gplot data=toplot gout=tempcat;
	plot y*x / name="plot1";
	plot z*x / name="plot2";
run;);
%mplot(&gplot , 2 , 1);

2.- Doing a scatter plot between two variables and placing their respective
histograms in the diagonal of a 2x2 panel.
%let plots = %str(
proc univariate data=toplot gout=tempcat;
	histogram x / name="graph11";
	histogram y / name="graph22";
run;
proc gplot data=toplot gout=tempcat;
	plot y*x / name="graph12";
run;);
%mplot(&plots , 2 , 2 , plotName=graph , matrix=1);

3.- Doing two plots in a 2x2 panel structure. Since direction=bycols,
the plot named 'plot2' is placed in the (2,1) position of the panel, and
'plot3' is placed in the (1,2) position:
%let gplot = %str(
proc gplot data=toplot gout=tempcat;
	plot y*x / name="plot2";
	plot z*x / name="plot3";
run;);
%mplot(&gplot , 2 , 2 , direction=bycols);

(Notice that the plot numbers do not need to start at 1, but all of them
must be integer numbers between 1 and the number of cells in the panel
structure.)
*/
%MACRO MPlot(gplot , nrows , ncols , direction=byrows , plotName=plot , tempcat=work.tempcat , gout=work.gseg , 
			 matrix=0 , hfactor=1 , vfactor=1 , frame=0 ,  novalues=0 , title="Multiple plot" , description= ,
			 nonotes=0) / des="Multiple plots on the same graph window";
%local i j count;
%local delete tdef treplay;
%local llx ulx urx lrx lly uly ury lry right space top;
%local hstep hsize vsize vstep;

%*Setting nonotes options and getting current options settings;
%SetSASOptions;

/*************************** MACRO DEFINITIONS ****************************/
%*** Macro that generates the tdef, treplay and delete statements used when creating the panel;
%MACRO DefineGReplayStatements;
%let right = 100;		%*** Right end of the window (in cells?);
%let top = 100;			%*** Top of the window (in cells?);
%if %quote(&title) ~= %then %do;
	%*** Leaves space for the title slide;
	%let space = 0.1;		
	%let top = %sysevalf(&top - &space*&top);
%end;
%*** Initialization of coordinates;
%let vstep = %sysfunc(round(%sysevalf( &top / &nrows )));
%let hstep = %sysfunc(round(%sysevalf( &right / &ncols )));
%let llx = 0;		%let lly = %eval( &top - &vstep );
%let ulx = 0;		%let uly = &top;
%let urx = &hstep;	%let ury = &top;
%let lrx = &hstep;	%let lry = %eval( &top - &vstep );

%let tdef =;
%let treplay =;
%let delete =;
%if %quote(&title) ~= %then %do;
	%*** Defining the panel for the title slide;
	%let tdef = &tdef	0 / llx=0		lly=&top
							ulx=0		uly=100
							urx=&right	ury=100
							lrx=&right	lry=&top;
	%let treplay = &treplay 0:title;
	%let delete = &delete title;
%end;
%do i = 1 %to &nrows;
	%do j = 1 %to &ncols;
		%let tdef = &tdef &i&j /	llx=&llx       lly=&lly
									ulx=&ulx       uly=&uly
									urx=&urx       ury=&ury
									lrx=&lrx       lry=&lry 
									&frame;
		%if &matrix %then %do;	%*** If the names of the plots have matrix-like subscripts;
			%let treplay = &treplay &i&j:&plotName&i&j;
			%let delete = &delete &plotName&i&j;
		%end;

		%*** Moving right to the next column;
		%let llx = %eval( &llx + &hstep );
		%let ulx = %eval( &ulx + &hstep );
		%let urx = %eval( &urx + &hstep );
		%let lrx = %eval( &lrx + &hstep );
	%end;
	%*** Moving down to the next row;
	%let lly = %eval( &lly - &vstep );
	%let uly = %eval( &uly - &vstep );
	%let ury = %eval( &ury - &vstep );
	%let lry = %eval( &lry - &vstep );

	%*** Reset horizontal position;
	%let llx = 0;
	%let ulx = 0;
	%let urx = &hstep;
	%let lrx = &hstep;
%end;

%*** Generating the treplay and delete statements in the case the plot names do not
have matrix-like subscripts;
%if ~&matrix %then %do;
	%let count = 1;
	%if %lowcase(&direction) = byrows %then
		%do i = 1 %to &nrows;
			%do j = 1 %to &ncols;
				%let treplay = &treplay &i&j:&plotName&count;
				%let delete = &delete &plotName&count;
				%let count = %eval( &count + 1 );
			%end;
		%end;
	%else %if %lowcase(&direction) = bycols %then
		%do j = 1 %to &ncols;
			%do i = 1 %to &nrows;
				%let treplay = &treplay &i&j:&plotName&count;
				%let delete = &delete &plotName&count;
				%let count = %eval( &count + 1 );
			%end;
		%end;
	%else %do;
		%put MPLOT: ERROR - The value of 'direction' is not valid.;
		%put MPLOT: Possible values are byrows and bycols.;
	%end;
%end;
%MEND DefineGReplayStatements;
/**************************************************************************/

%if &nrows <= 0 or &ncols <= 0 %then
	%put MPLOT: ERROR - The number of rows and columns in the plot panel need to be positive.;
%else %do;
/* Reset all global statements */
%*goptions reset=all;

/* Add a frame to each plot? */
%if &frame %then
	%let frame = %str(color=black);
%else
	%let frame =;

/* Delete entries from temporal graph catalog if it is not work.gseg */
%if %upcase(&tempcat) ~= WORK.GSEG and %upcase(&tempcat) ~= GSEG %then %do;
/* THIS IS NO LONGER NECESSARY BECAUSE I FOUND THE FUNCTION CEXIST()!
	%local name temp;
	%let temp = %GetNroElements(&tempcat , sep=.);
	%if &temp > 1 %then
		%let name = %scan(&tempcat , 2 , '.');	%*** If the name of the catalog is of the form LIBREF.NAME;
	%else
		%let name = &tempcat;
	%if %Exist(sashelp.Vscatlg , memname , &name) %then %do;
*/
	%if %sysfunc(cexist(&tempcat)) %then %do;	%*** Checks existence of catalog &tempcat;
		proc greplay nofs igout=&tempcat;
			delete _all_;
		run;
	%end;
%end;
%else %do;	%*** I delete only the plot entries whose name coincides with the plot names to be plotted now;
	/* NOTE: This actually does not work because SAS does not really delete the plot entry when there
	are templates in the same graph catalog. There is no solution to this, other than placing the
	templates and the single plot entries in different catalogs (as suggested by SAS in their page
	www.sas.com/service/techsup when searching for 'delete greplay'). */
	proc greplay nofs igout=&tempcat;
		delete title;
		%if &matrix %then
			%do i = 1 %to &nrows;
				%do j = 1 %to &ncols;
					delete &plotName&i&j;
				%end;
			%end;
		%else
			%do count = 1 %to %eval(&nrows*&ncols);
				delete &plotName&count;
			%end;
	run;
	quit;
%end;
	

/* Use DSGI functions HSIZE/VSIZE to determine default HSIZE and VSIZE
   and modify them for correct aspect ratio.
   (Taken from mplot by SAS (mplotsas.sas)) */
data _NULL_;
	rc=ginit();
	call gask('hsize',hsize,rc);
	hsze = hsize/&ncols * &hfactor;
	call symput('hsize',left(trim(hsze)));
	call gask('vsize',vsize,rc);
	vsze = vsize/&nrows * &vfactor;
	call symput('vsize',left(trim(vsze)));
	rc=gterm();
run;

/* Generating the statements to be used in the creation of the template
that defines the panel to be used in the plot:
- tdef:		to create the template.
- treplay:	to place each plot, according to parameter 'direction'.
- delete:	to delete the template created with tdef.
*/
%*** tdef;
%DefineGReplayStatements;

/**************************** THE PLOTS ***************************/
/* Turn DISPLAY off,
   Specify VSIZE and HSIZE to reflect template panel dimensions */
%*** vsize and hsize for the title (ymax is the maximum vertical size of the graphics output area);
%*** DM-2012/07/13: Replaced the use of the YMAX option with the use of &VSIZE macro variable
%*** (computed at the data step above), since in SAS 9.3 the value of YMAX is not defined by default
%*** (as no device is defined --which is apparent when running the above data step with the ginit()
%*** function where a window pops up prompting the user to specify a device name);
%*goptions nodisplay vsize=%sysevalf( %scan(%sysfunc(getoption(ymax)), 1 ,' ') * &space * 1.2 );
goptions nodisplay vsize=%sysevalf( &vsize * &space * 1.2 );
%if %quote(&title) ~= %then %do;
	%*** Generating a slide with the title to be placed at the top;
	%* The height= option is to get a proper size of the letters, otherwise they may be too small;
	%* However, in the title cannot be more than 2 lines, otherwise there will be overlapping with the graphs;
	proc gslide gout=&tempcat name="title"; 
		title height=30 pct justify=center &title;
	run; quit;
		%*** Notice that gout=&tempcat, NOT &gout. This is because &tempcat is the temporary template
		%*** where the plots are done to be later placed in &gout;
	title;
%end;
%*** vsize and hsize for the plots;
goptions vsize=&vsize hsize=&hsize;
%if ~&nonotes %then %do;	%* Leave the %do, even if it is not necessary because I had problems without it;
	options notes;
%end;
&gplot;
quit;
%* Resetting option nonotes in case it was set to notes above;
options nonotes;

/* Turn DISPLAY on, reset VSIZE and HSIZE to default values (because now we will be using the whole window) */
goptions display vsize=0 hsize=0;	%*** vsize=0 and hsize=0 resets the values of vsize and hsize;

%if %quote(&description) = %then
	%let description = &title;

/* Create template and place the gplot entries into individual panels */
%* Catalog _templates_ is used to store the template used;
title &description;		%* Para que aparezca la descripcion en el Explorer window y el grafico pueda ser identificado facilmente;
proc greplay nofs igout=&tempcat gout=&gout tc=work._templates_;
tdef mplot des=&description &tdef;	%* Defines and stores the catalog in _templates_;
template mplot;				%* Uses template mplot;
treplay &treplay;			%* Shows the plots produced by &gplot in different panels of template mplot;
delete &delete;				%* Deletes the plot entries;
tdelete mplot;				%* Deletes the template;
run;
quit;
title;

%* Deleting the catalog entry (_templates_) with the template used;
proc catalog catalog=work._templates_ kill;
run;
proc datasets lib=work memtype=catalog nolist;
	delete _templates_;
quit;

%end;	%*** else;

%ResetSASOptions;
%MEND MPlot;
