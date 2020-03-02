
Title:                  SPSS Electrics
Author:                 Craig Barton Upright <cupright@alumni.princeton.edu>

    created: 05/26/2000 {12:55:02 am}
last update: 03/06/2006 {08:03:32 PM}


	  	* Table Of Contents

"# Abstract"
"# Description"
"# SPSS keywords"
"# SPSS commands versus arguments"
"# SPSS function completions"
"# List Pick versus Status Bar"
"# Nearby word completions"
"# Acronyms"
"# Writing additional completions"

"# Copyright"


	======================================================================


	  	* Abstract

This document provides examples of SPSS mode electric completions.


	  	* Description

This file contains examples of "electric completions".  Completions are
ways in which Alpha attempts to complete what you're typing in a mode
specific way (in this case SPSS specific).

The " Config --> Special Keys ...  " menu item will display your current
completion key-binding, and will give you the option to change it if you
desire.

In this tutorial, you can use the back-quote key ( ` ) to jump to the next
completion example.  Once at the correct position, imagine that you had
just typed the preceding text.

Then hit the completion invoking key.  Alpha attempts to complete what you
typed -- eliminating a lot of keystrokes, avoiding the need for
copy/pasting, and reducing the possibility of typos.


	  	* SPSS keywords

Alpha will first attempt to determine if you're typing in a new keyword. 
After typing any non-ambiguous keyword abbreviation you can complete the
command -- In some cases the completion fills in more of the syntax,
inserting template stops that you can jump to using the tab key -- or
whichever key you have defined to do so.  For example:


	repl<>
	
	imp<>
	
	form<>
	
	exe<>


The last template stop will position you for the next command.

Because SPSS commands are case-insensitive, Alpha will recognize if your 
intended completion is upper or lower case:


	AGG<>
	
	agg<>


	  	* SPSS commands versus arguments

One of the challenges of writing completions for SPSS is that the program
rarely distinguishes between commands and arguments, and often uses the
same name for both.  To overcome this, and distinguish between command
completions and arguments completions, first type a <'> before any word
that you want completed without extra template stops:


	'reco<>
	
	reco<>
	
	'SAVE<>
	
	SAVE<>
	
	'conto<>
	
	compu<>  


Arguments that are preceded with </> don't need the <'> :


	/ren<>
	
	/OUTF<>


	  	* SPSS function completions

A small number of functions have been defined, such as abs, cos, sqrt, etc. 
These will be completed with paratheses and template stops:


	abs<>
	
	cos<>
	
	art<>
	
	SQ<>
	
	LN<>


	  	* List Pick versus Status Bar

The " Config --> Preferences --> Completions " menu item includes the
preference " List Pick if Multiple Completions ".  This determines Alpha's
behavior when the user is attempting to complete an ambiguous piece of
text.

If this preference is checked, then attempting to complete the following
will open a dialog box with the options available.  Otherwise, the list of
possible completions will appear in the status bar: 


	com<>
	
	rep<>
	
	LOG<>
	
	/pre<>
	
	'PRO<>


	  	* Nearby word completions

Alpha first tries to complete your text using the procedures explained
above.  If no suitable completion can be found, then it looks in the
document to find some written text for a completion.  For example, if you
are working with a dataset and have been making several transformations to
the variables dpiino2, rsnnn, nojob, century, and profile, the complete
key will attempt to give you what you're looking for:


	dp<>
	
	noj<>
	
	cent<>
	
	pro<>


Commands will always take precedence over nearby words.

Complete this example, but press the complete key multiple times after the
first completion appears:


	Com<>


Alpha will offer all of the instances in which a potential "Com" completion
appears in the document, and indicate in the status bar the location of the
found text.  After running through the entire list of possible completions,
the last one will be highlighted, allowing one to delete it if desired. 
Pressing the completion key again will delete the selection, and start the
whole process over once again.


	  	* Acronyms

If you are in the habit of naming variables with both lower and upper case 
letters, you can use the "expansion" key to complete acronyms.  (The 
exansion key is _not_ the completion key.  You can find out how your 
special keys are defined with the  "Config --> Special Keys" menu item.)

For example, if you have the variables NoWork, momGrad, and TelNo3, 


	NW<>
	
	mG<>
	
	TN<>


	  	* Writing additional completions

Electric completions are really pretty easy to write.  Take a look at the 
" Config --> Mode Prefs --> Edit Completions " menu item to see the current
list.  To add more, simply add a line similar to this

	set SPSSCommandElectrics(aggregate) "blah.blah.blah"

to a SPSSPrefs.tcl file ("Config --> Mode Prefs --> Edit Prefs File").  If
you write some more, be sure to send a copy of them to the SPSS mode's
current maintainer -- they'll be included in the next release.


	======================================================================

	  	* Copyright

This document has been placed in the public domain.
