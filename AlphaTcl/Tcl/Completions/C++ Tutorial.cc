
Title:                  C++ Electrics
Author:                 Craig Barton Upright <cupright@alumni.princeton.edu>
Author:                 Vince Darley <vince@santafe.edu>

    created: 05/13/2001 {01:35:07 am}
last update: 03/06/2006 {08:01:44 PM}



	  	// Table Of Contents

"# // Abstract"
"# // Description"
"# // Command Completions"
"# // Variable names"
"# // Alternate Completions"
"# // Expansions"

"# // Copyright"


	======================================================================


	  	// Abstract

This document provides examples of C++ mode electric completions.


	  	// Description

This file contains examples of "electric completions".  Completions are
ways in which Alpha attempts to complete what you're typing in a mode
specific way (in this case C++ specific).

The "Config --> Special Keys ...  " menu item will display your current
completion key-binding, and will give you the option to change it if you
desire.

In this tutorial, you can use the back-quote key ( ` ) to jump to the next
completion example.  Once at the correct position, imagine that you had
just typed the preceding text.

Then hit the completion invoking key.  Alpha attempts to complete what you
typed -- eliminating a lot of keystrokes, avoiding the need for
copy/pasting, and reducing the possibility of typos.


	  	// Command Completions

Here are some typical uses of electric completions:

	for×

	while×

	switch×


	  	// Variable names

It's important spell long variable names correctly.  

	while(myVeryLongVariableName>0) {
		my×

	  	// Alternate Completions

By pressing the invoking key multiple times, you can switch between any
number of alternative completions both above and below the insertion point. 
If you cycle through all possibilities, the entire name is highlighted so
you can delete it easily if desired.

	int myOtherLongVariable = 0;
	while(myVeryLongVariableName>0) {
		my×
	
		int myVariableBelow;


	  	// Expansions

There is another way to quickly pull a variable or function name out of the
surrounding text.  Instead of typing the first few letters of a multi-word
identifier, type each letter that starts a word in that identifier. 
Completions of this sort are invoke by pressing the 'expansion' key.  The
menu item "Config --> Special Keys ...  " will display your current
expansion key-binding, and will give you the option to change it if you
desire.


	int myOtherLongVariable = 0;
	while(myVeryLongVariableName>0) {
		mvlvn×
		molv×
		mvb×
	
		int myVariableBelow;
	
	
	======================================================================

	  	// Copyright

This document has been placed in the public domain.


