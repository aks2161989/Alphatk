
Title:                  sh Electrics
Author:                 Craig Barton Upright <cupright@alumni.princeton.edu>

    created: 05/26/2000 {06:23:20 pm}
last update: 03/06/2006 {08:00:24 PM}

 
	  	# Table Of Contents

"# Abstract"
"# Description"
"# C shell commands"
"# List Pick versus Status Bar"
"# C shell contractions"
"# Nearby word completions"
"# Acronym Expansions"
"# Writing additional completions"
"# Copyright"


	======================================================================


	  	# Abstract

This document provides examples of sh mode electric completions.


	  	# Description 

This file contains examples of "electric completions".  Completions are
ways in which Alpha attempts to complete what you're typing in a mode
specific way (in this case sh specific).

The " Config --> Special Keys ...  " menu item will display your current
completion key-binding, and will give you the option to change it if you
desire.

In this tutorial, you can use the back-quote key ( ` ) to jump to the next
completion example.  Once at the correct position, imagine that you had
just typed the preceding text.

Then hit the completion invoking key.  Alpha attempts to complete what you
typed -- eliminating a lot of keystrokes, avoiding the need for
copy/pasting, and reducing the possibility of typos.


	  	# C shell commands

Alpha will first attempt to determine if you're typing in a new command. 
After typing any non-ambiguous command abbreviation you can complete the
command -- In most cases the completion fills in more of the syntax,
inserting template stops that you can jump to using the tab key -- or
whichever key you have defined to do so.  For example:


        ln×
        
        rmd×
        
        comp×
        
        chmod×
        

The last template stop will position you for the next command. 


	  	# List Pick versus Status Bar

The " Config --> Preferences --> Completions " menu item includes the
preference " List Pick if Multiple Completions ".  This determines Alpha's
behavior when the user is attempting to complete an ambiguous piece of
text.

If this preference is checked, then attempting to complete the following
will open a dialog box with the options available.  Otherwise, the list of
possible completions will appear in the status bar: 


        gen×
        
        lo×
        
        mk×
        

	  	# C shell contractions

Command contractions can also be created for sh mode.  The current 
version contains merely this one example:


        s'd×

        
Additional contractions can be easily added to the shCompletions.tcl file.


	  	# Nearby word completions

Alpha first tries to complete your text using the procedures explained
above.  If no suitable completion can be found, then it looks in the
document to find some written text for a completion.  For example, if you
are working with a dataset and have been making several transformations to
the variables mmiino2, rsnnn, nowork, century, and profile, the complete
key will attempt to give you what you're looking for:


        mm×
        
        now×
        
        cent×
        
        pro×


Commands will always take precedence over nearby words.

Complete this example, but press the complete key multiple times after the
first completion appears:


        Com×


Alpha will offer all of the instances in which a potential "Com" completion
appears in the document, and indicate in the status bar the location of the
found text.  After running through the entire list of possible completions,
the last one will be highlighted, allowing one to delete it if desired.
Pressing the completion key again will delete the selection, and start the
whole process over once again.


	  	# Acronym Expansions

If you are in the habit of naming variables with both lower and upper case 
letters, you can use the "expansion" key to complete acronyms.  (The 
exansion key is _not_ the completion key.  You can find out how your 
special keys are defined with the  "Config --> Special Keys" menu item.)

For example, if you have the variables NoWork, momGrad, and TelNo3, 


        NW×
        
        mG×
        
        TN×
        
        
	  	# Writing additional completions

Electric completions are really pretty easy to write.  Take a look at the 
" Config --> Mode Prefs --> Edit Completions " menu item to see the current
list.  If you write some more, be sure to send a copy of them to the sh
mode's current maintainer -- they'll be included in the next release.


	  	# Copyright

This document has been placed in the public domain.
