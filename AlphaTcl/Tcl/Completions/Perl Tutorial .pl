
Title:                  Perl Electrics
Author:                 Vince Darley <vince@santafe.edu>
Author:                 Craig Barton Upright <cupright@alumni.princeton.edu>

    created: 05/13/2001 {11:38:40 am}
last update: 03/06/2006 {08:02:37 PM}



	  	# Table Of Contents

"# Abstract"
"# Description"
"# Typical Uses"
"# Perl Phrases"
"# Perl Scalars"
"# Expansions"
"# Collecting and sorting"
"# Invoking MacPerl from Alpha"

"# Copyright"


	======================================================================


	  	# Abstract

This document provides examples of Perl mode electric completions.


	  	# Description

This file contains examples of "electric completions".  Completions are
ways in which Alpha attempts to complete what you're typing in a mode
specific way (in this case Perl specific).

The "Config --> Special Keys ...  " menu item will display your current
completion key-binding, and will give you the option to change it if you
desire.

In this tutorial, you can use the back-quote key ( ` ) to jump to the next
completion example.  Once at the correct position, imagine that you had
just typed the preceding text.

Then hit the completion invoking key.  Alpha attempts to complete what you
typed -- eliminating a lot of keystrokes, avoiding the need for
copy/pasting, and reducing the possibility of typos.


	  	# Typical Uses

Here are some typical uses of electric completions:

	for×
	
	foreach×
	
	while×
	
	if×
	
	else×
	
	elsif×
	
	do×
	
	split×
	

	  	# Perl Phrases

These are shortcuts for common perl 'phrases'
	
	o'd×
	

	  	# Perl Scalars

When you type a perl scalar, you can add or remove the leading "$" by
pressing cntrl-4 (i.e. the key that shifts to '$').
	
	type <cntrl-4> several times:
	
	somePerlScalarVar×
	
	There is a similar binding for a perl hash (associative array):
	
	type <cntrl-2> several times:
	
	somePerlHash×
	

	# Nearby word completions

There is also some help available to save typing or mispelling variable
names that have already been used at least once.
	
First let's provide a group of identifiers:
	
	@evcode $evcode @evid *evid $evid @evmask $layout *rowParams 
	%subSection $suffix *tableParams $target 
		
Now we'll provide examples that extend the first few characters of a
indentifier into the full name:
	
	$evc×
	
	$lay×
	
	ev×
	
	
	  	# Expansions

These acronyms can be completed using the expansion key (which is not the
same as the completion key.)  The menu item "Config --> Special Keys ..."
will display your current expansion key-binding, and will give you the
option to change it if you desire.
	
	rp×
	
	tp×
	
	ss×
	

	  	# Collecting and sorting

After you have entered a lot of code, it can be useful to look at all the
identifiers you have used to check for mispelling.  Use the Perl menu
item "Collect Indentifiers" to search the current window for all
identifiers, sort them alphabetically (disregarding leading $, @, %, and
* symbols), and place them on the clipboard.  

Try it, and then paste here (Cmd-V):

	×

	  	# Invoking MacPerl from Alpha

It is now possible to use the Tcl shell to invoke MacPerl in a command line
fashion.  A new "unix shell" like command has been added to help out.  Here
is an example;
	
			Welcome to Alpha's Tcl shell.
			ÇAlpha Ä.È alias sdf [getfile]	
	
you are presented with a file dialog with which you locate the perl source
file 'sdf'.  The shell remebers this path, and allows you to make the
following call:
	
			ÇAlpha Ä.È perl sdf -h

(note that the ouput appears in the shell window).


	======================================================================

	  	# Copyright

This document has been placed in the public domain.


