
Title:                  Lisp Electrics
Author:                 Craig Barton Upright <cupright@alumni.princeton.edu>

    created: 05/26/2000 {01:09:13 am}
last update: 03/06/2006 {08:02:23 PM}


	  	; Table Of Contents

"# Abstract"
"# Description"
"# Lisp commands"
"# List Pick versus Status Bar"
"# Nearby word completions"
"# Writing additional completions"

"# Copyright"


	======================================================================


	  	; Abstract

This document provides examples of Lisp mode electric completions.

	  	; Description 

This file contains examples of "electric completions".  Completions are
ways in which Alpha attempts to complete what you're typing in a mode
specific way (in this case Lisp specific).

The " Config --> Special Keys ...  " menu item will display your current
completion key-binding, and will give you the option to change it if you
desire.

In this tutorial, you can use the back-quote key ( ` ) to jump to the next
completion example.  Once at the correct position, imagine that you had
just typed the preceding text.

Then hit the completion invoking key.  Alpha attempts to complete what you
typed -- eliminating a lot of keystrokes, avoiding the need for
copy/pasting, and reducing the possibility of typos.


	  	; Lisp commands

Alpha will first attempt to determine if you're typing in a new command. 
After typing any non-ambiguous command abbreviation you can complete the
command -- In most cases the completion fills in more of the syntax,
inserting template stops that you can jump to using the tab key -- or
whichever key you have defined to do so.  For example:


	catch×
	
	defge×
	
	(deft×
        

If the command did not start with an open paranthesis, Alpha will insert 
one for you.


	  	; List Pick versus Status Bar

The " Config --> Preferences --> Completions " menu item includes the
preference " List Pick if Multiple Completions ".  This determines Alpha's
behavior when the user is attempting to complete an ambiguous piece of
text.

If this preference is checked, then attempting to complete the following
will open a dialog box with the options available.  Otherwise, the list of
possible completions will appear in the status bar: 


	def×
	
	pro×
	
	(con×
        

	  	; Nearby word completions

Alpha first tries to complete your text using the procedures explained
above.  If no suitable completion can be found, then it looks in the
document to find some written text for a completion.  For example, if you
have previously defined the variables S-auto-newline, S-tab-always-indent,
and S-brace-offset the complete key will attempt to give you what you're
looking for:


	S-×
        
Complete this example again, but press the complete key multiple times
after the first completion appears:


	S-×


Alpha will offer all of the instances in which a potential "S-" completion
appears in the document, and indicate in the status bar the location of the
found text.  After running through the entire list of possible completions,
the last one will be highlighted, allowing one to delete it if desired. 
Pressing the completion key again will delete the selection, and start the
whole process over once again.


	  	; Writing additional completions

Electric completions are really pretty easy to write.  Take a look at the 
" Config --> Mode Prefs --> Edit Completions " menu item to see the current
list.  If you write some more, be sure to send a copy of them to the Lisp
mode's current maintainer -- they'll be included in the next release.


	======================================================================

	  	; Copyright

This document has been placed in the public domain.


