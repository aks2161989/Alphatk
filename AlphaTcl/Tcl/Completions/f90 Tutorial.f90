
Fortran90 Electric Completions Tutorial

                                            version: 2.0
                                            created: 02/12/2005 {10:10:22 AM}
                                        last update: 02/22/2005 {12:15:33 PM}


	  	! Table Of Contents

"# Description"
"# Keyword Completions"
"# If ... Then ... Else ..."
"# Electric Contractions"
"# DO Completions"
"#  DO ... CONTINUE"
"#  DO ... END DO"
"#  DO WHILE ... (or WHILE ... DO)"
"#  DO ... UNTIL ..."
"# Electric Return"
"# Word Completions"
 
"# Copyright"


	================================================================


	  	! Description

This file contains examples of "electric completions".  Completions are ways in
which Alpha attempts to complete what you're typing in a mode specific way (in
this case Fortran, or "Fort" mode specific).

The "Config > Special Keys" menu item will display your current completion
key-binding, and will give you the option to change it if you desire.

In this tutorial, you can use the back-quote key ( ` ) to jump to the next
completion example.  Once at the correct position, imagine that you had just
typed the preceding text.

Then hit the completion invoking key.  Alpha attempts to complete what you typed
-- eliminating a lot of keystrokes, avoiding the need for copy/pasting, and
reducing the possibility of typos.

Technical note: the presence of un-used stops can interfere with the
completion/expansion of the next shortcut, so each jump via the back-quote key
first clears all stops.


	  	! Keyword Completions

Most Fortran keywords (including statements, functions, intrinsic operators,
etc.)  are available as "electric completions" If you type a portion of the name
and press your "Complete" key, the rest of it will be finished for you.  Press
the back-quote (`) key now to position the cursor behind the string "write" and
then press your special "Complete" key to test:

   write×

After the electric template has been created, you can press your special "Next
Stop" key to advance to the next template marker.

Now try it with these examples

   format×
   if×
   abs×

Fortran is a case-insensitive language, so you can include all of

   write (*,*) 
   Write (*,*) 
   WRITE (*,*) 

in your source files.  The "Complete Commands Using" preference allows you to
select your personal style -- you can view (and change) the current setting for
this preference by selecting the "Config > Fort Mode Prefs > Preferences" menu
item.

Note that all of the following are available as electric completions, but all
will be converted to your chosen style:

   write×
   Write×
   WRITE×
   
The "Spaces After Command/Function" preferences also determine if the
(parentheses) are inserted touching the keyword or not.

Most Fortran keywords can be completed after typing just a portion of the
command.  If the 'hint' is ambiguous, you will be prompted to select from all
available options.  Complete the following:

   wr×
   for×
   proc×
   int×
   pr×

If you have typed a keyword and a "(", typing a consecutive "(" will trigger a
quick () template, with an additional stop at the end for easy navigation:

   sqrt(×
   tan(×
   if (×

The logic here is that typing two "((" is slightly easier than typing ().

   log×
   min×

In "normal" windows, selecting "Edit > Undo" a few times will eventually restore
the original double text if that is what you really wanted.  (In this window,
[undo] is disabled.)

You can turn off the "Electric Dbl Left Paren" preference to disable this
feature.
   
   
	  	! If ... Then ... Else ...

The basic "IF" statement takes place on a single line, as in

   IF (<logical-expression>) <statement>
   
   if×

Often times you need to execute several different statements after an IF, using
the IF ...  THEN construction, as in

   IF (<logical-expression>) THEN
      <statement>
      <statement>
      ...
   ENDIF

You can type and complete "ifthen" to create a template for this:

   ifthen×

And of course IFTHEN works too:

   IFTHEN×

The "Enddo Endif Are Single Words" preference determines if the template
includes "ENDIF" vs "END IF".

If you need to include an "ELSE IF" case, just complete "elseif" :

   IF (x .GE. y) THEN
      WRITE(*,*) 'x is positive and x >= y'
      elseif×
   ENDIF

The "Elseif Is Single Word" preference determines if "elseif" will complete to
"ELSEIF" vs "ELSE IF".


If you know in advance that you want to create an "IF ...  ELSE" set of
conditions, you can complete "ifelse" :

   ifelse×


	  	! Electric Contractions

Some statements required two keywords, as in
 
    ASSIGN <label> TO <integer name>
    
    DOUBLE PRECISION <list of variables>
    
    BLOCK DATA <arguments>
 
You can complete these as "contractions", i.e.
 
    a't×
    
    d'p×
    
    b'd×
    
UPPER and Mixed case "hints" work as well:
 
    A'T×
    
    D'p×
    
    b'D×
 
There are special cases built in for "IF/ELSE" statements :
 
    i't×
    
    i'e×
    
    IF () THEN
       e'i×
    ENDIF
 
Tip: in Fort mode the "Expand" key will also complete all of these electric
contractions.


	  	! DO Completions

Fortran has several different flavors of DO statements, including
 
   DO <label> <var>=<expr>
      <statement>
   CONTINUE
   
   DO
      <statement>
   ENDDO
   
   DO WHILE (<logical expression>) 
      <statement>
   ENDDO
   
   WHILE (<logical expression>) DO
      <statement>
   ENDDO
   
   DO
      <statement>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
   UNTIL (<logical expression)
 
If you attempt to complete "DO" you will be offered all of these options in a
list-pick dialog:
 
   do×
 
Your last selection will be "remembered" the next time you attempt to complete
DO as the default option in the dialog:
 
    do×

There are other methods for a template for your desired flavor from the outset.

	  	 	! DO ... CONTINUE

To create a "DO ...  CONTINUE" template, you can complete the string
"doContinue" (or "docontinue" or DOCONTINUE) :
 
   doContinue×
 
The electric contraction "d'c" is even handier:
 
   d'c×
   
   D'C×
 
	  	 	! DO ... END DO

This is the most basic template.  

   doEndDo×
   
   doenddo×
   
The "Enddo Endif Are Single Words" preference determines if "enddo" will be
inserted as "ENDDO" vs "END DO" in the template.

The "d'e" contraction is also useful:
  
   d'e×
   
   D'e×
  


	  	 	! DO WHILE ... (or WHILE ... DO)

To create a DO ...  WHILE template, you can complete "doWhile" or "doEndDo" :
  
   doWhile×
   
   dowhile×
   
The "Enddo Endif Are Single Words" preference determines if "enddo" will be
inserted as "ENDDO" vs "END DO" in the template.

   DOWHILE×
   
The "d'w" contraction is also useful:
  
   d'w×
   
   D'W×
   
To create a WHILE ...  DO template, simply complete "while":
  
   while×
  
or use "w'd":
  
   w'd×
     
	  	 	! DO ... UNTIL ...


To create a DO ... UNTIL template, complete "doUntil" :
  
   doUntil×
  
or use the contraction "d'u" :
  
   d'u×

(Do you sense a pattern here?)
  
  
	  	! Electric Return

Fort mode has a sophisticated indentation routine.  For example, advance to the
next × marker in this window and select the "Fortran > Reformat Block" command:

   Do i=7,12,1×
   If(QS(i:i).eq."0")  then
   digit(i)=0.0
   Else if(QS(i:i).eq."1")  then
   digit(i)=1
   Else if(QS(i:i).eq."2")  then
   digit(i)=2
   Else if(QS(i:i).eq."3")  then
   digit(i)=3
   Else if(QS(i:i).eq."") then
   Go to 162
   Else 
   Write(6,159) QS(i:i)
   Format(A ' is not a valid character -- ')
   Write(6,160)
   Format('Please reenter six characters,<P>')
   Write(6,161) 
   Format('of type 0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F<P>') 
   Go to 335
   End if
   End do

Note that the cursor is positioned at the start of the next block of code after
reformatting, in case you want to reformat several blocks in your file.

If the "Indent On Return" preference is turned on, pressing the Return key will
automatically indent the next line.
   
   IF(QS(i:i).eq."0")  THEN×
   ENDIF

It will also indent the current line before creating the new one when this is
appropriate:

   IF(QS(i:i).eq."0")  THEN
      digit(i)=0.0
      ENDIF×

If you just want to create a new line without invoking any fancy indentation
routines, press Control-Return.
 
If you are nearing the end of a line and want to continue it to the next, select
the "Fortran > Continue Line" command.

   CHARACTER(255) :: allnames , cmdln , command , comment , ×

   
	  	! Word Completions

Here's a paragraph in which I use the word paragraph many times.  If I become
bored of typing the word paragraph, I can just type

   parag×

This also works with Fortran variable names, so if I have "MYVARIABLE" which I
don't wish to retype, I can just do

   MYV×
   
instead.  If there are several similar completions available, such as
"MYVARIANCE" and "MYVALUE" then pressing the Completion key multiple times will
cycle through all of the options.

   MYV×

Your "Electric Expansion" key (see "Config > Special Keys") can be used to
expand acronyms.  For example, if you name your variables with a mix of upper
and lower case letters ("myVariable"), you can then expand the string

   mv×

to insert the correct text into the window.  Again, if you have several words
that match the acronym, such as "myVariance" and "myValue" you can cycle through
the options.

   mv×

	================================================================


	  	! Copyright

This document has been placed in the public domain.


