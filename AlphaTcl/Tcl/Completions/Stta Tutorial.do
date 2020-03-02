
Title:                  Stata Electrics
Author:                 Craig Barton Upright <cupright@alumni.princeton.edu>

    created: 05/14/2000 {11:39:44 pm}
last update: 03/06/2006 {08:04:10 PM}


	  	* Table Of Contents

"# Abstract"
"# Description"
"# Stata commands"
"# Stata arguments, options, etc"
"# Stata functions"
"# List Pick versus Status Bar"
"# Stata contractions"
"# Nearby word completions"
"# Acronyms"
"# Writing additional completions"

"# Copyright"


	======================================================================


	  	* Abstract

This document provides examples of Stta mode electric completions.


	  	*  Description

This file contains examples of "electric completions".  Completions are
ways in which Alpha attempts to complete what you're typing in a mode
specific way (in this case Stta specific).

The " Config --> Special Keys ...  " menu item will display your current
completion key-binding, and will give you the option to change it if you
desire.

In this tutorial, you can use the back-quote key ( ` ) to jump to the next
completion example.  Once at the correct position, imagine that you had
just typed the preceding text.

Then hit the completion invoking key.  Alpha attempts to complete what you
typed -- eliminating a lot of keystrokes, avoiding the need for
copy/pasting, and reducing the possibility of typos.


	  	*  Stata commands

Alpha will first attempt to determine if you're typing in a new command. 
After typing any non-ambiguous command abbreviation you can complete the
command -- In most cases the completion fills in more of the syntax,
inserting template stops that you can jump to using the tab key -- or
whichever key you have defined to do so.  For example:


	cap<>
	
	enc<>

		
The last template stop will position you for the next command.  Stta mode
has a "Semi Delimiter" preference which can be set via the Stata menu.  If
this preference is set, then completions will also include semicolons to
indicate the end of a command line.  This preference can be toggled on and
off by using the <control>-<shift>-; key binding.


	mlog<>
	
	gpro<>


In most cases, the completion will also insert syntax information specific
to the command in the status bar window.  This information will disappear
as soon as you begin typing again.  To review this syntax information,
"control-command double-click" on the stata command.  

Some of this information is longer than the status bar -- to insert this
information as commented text into your window for further review,
"shift-command double-click" on the Stata command.

Finally, to send the command to either www.stata.com or your local Stata
application for additional help, simply "command double-click" on the text. 
(The "Local Help" preference determines which procedure is the default --
turning this preference on will use the local application.)


	  	*  Stata arguments, options, etc

If Alpha decides that you're not typing in a new command, it will next
check to see if you're attempting to add a new argument or option to a
command:


	rla<>
	
	resc<>
	
	noh<>

There are some options which have the same names as commands, in which 
case you don't want the extra template stops and delimiter.  Preceding 
these option/command names with <'> will complete only the text:


	'gene<>
	
	'rena<>


This is also the case for "true" options, which are defined in Stta mode 
as such.  Thus you don't have to memorize the lists of keywords, and try 
to decipher the logic used by the mode's maintainer:

	'noadj<>
	
	noadj<>
	
	'iter<>
	
	iter<>


	  	*  Stata functions

Alpha also checks to see if you are completing a function:


	pct<>
	
	med<>
	
	abs<>


	  	*  List Pick versus Status Bar

The " Config --> Preferences --> Completions " menu item includes the
preference " List Pick if Multiple Completions ".  This determines Alpha's
behavior when the user is attempting to complete an ambiguous piece of
text.

If this preference is checked, then attempting to complete the following
will open a dialog box with the options available.  Otherwise, the list of
possible completions will appear in the status bar: 


	gen<>
	
	fto<>
	
	rep<>
	
	log<>


	  	*  Stata contractions

Stata uses "prefix" commands, like quietly, noisily, and capture to change
some of its behavior.  In addition, several commands have "subcommands",
like program define, matrix post, or label values.  Completing these 
prefixes (broadly defined -- not limited to Stata prefixes proper) will 
position the cursor for a further command:


	qui<>
	
	prog<>
	
	set<>



There are a number of contractions built in to help with these "prefix"
commands.  Typing the first letter of the prefix along with <'> will insert
the prefix but still complete the second command name:


* capture

    c'regre<>
        
* eq

    e'lis<>
        
* label

    l'defi<>

* matrix

    m'rown<>

* program

    p'dro<>

* reshape

    r'que<>
        
* set

    s'mor<>

* xi

    x'mlog<>
        

In addition, two commonly used "label" contractions are provided:       


	l'vl<>
	
	l'vr<>


	  	*  Nearby word completions

Alpha first tries to complete your text using the procedures explained
above.  If no suitable completion can be found, then it looks in the
document to find some written text for a completion.  For example, if you
are working with a dataset and have been making several transformations to
the variables mpiino2, rsnnn, NoWork, century, and profile, the complete
key will attempt to give you what you're looking for:


	mp<>
	
	NoW<>
	
	cent<>
	
	pro<>


Commands will always take precedence over nearby words.

Complete this example, but press the complete key multiple times after the
first completion appears:


	Com<>


Alpha will offer all of the instances in which a potential completion
appears in the document, and indicate in the status bar the location of the
found text.  After running through the entire list of possible completions,
the last one will be highlighted, allowing one to delete it if desired. 
Pressing the completion key again will delete the selection, and start the
whole process over once again.


	  	*  Acronyms

If you are in the habit of naming variables with both lower and upper case 
letters, you can use the "expansion" key to complete acronyms.  (The 
exansion key is _not_ the completion key.  You can find out how your 
special keys are defined with the  "Config --> Special Keys" menu item.)

For example, if you have the variables NoWork, momGrad, and TelNo3, 


	NW<>
	
	mG<>
	
	TN<>


	  	*  Writing additional completions

Electric completions are really pretty easy to write.  Take a look at the 
" Config --> Mode Prefs --> Edit Completions " menu item to see the current
list.  To add more, simply add a line similar to this

	set SttaCommandElectrics(blogit) "blah.blah.blah"

to a SttaPrefs.tcl file ("Config --> Mode Prefs --> Edit Prefs File").  If
you write some more, be sure to send a copy of them to the Stta mode's
current maintainer -- they'll be included in the next release.


	======================================================================

	  	*  Copyright

This document has been placed in the public domain.
