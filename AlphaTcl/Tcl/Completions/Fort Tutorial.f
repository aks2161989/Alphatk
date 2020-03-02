
Fortran Electric Completions Tutorial

                                       version: 2.0
                                       created: 02/12/2005 {10:10:22 AM}
                                   last update: 02/15/2005 {06:13:00 PM}


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

 001  This file contains examples of "electric completions".
      Completions are ways in which Alpha attempts to complete what
      you're typing in a mode specific way (in this case Fortran, or
      "Fort" mode specific).

 002  The "Config > Special Keys" menu item will display your current
      completion key-binding, and will give you the option to change it
      if you desire.

 003  In this tutorial, you can use the back-quote key ( ` ) to jump to
      the next completion example.  Once at the correct position,
      imagine that you had just typed the preceding text.
      
 004  Then hit the completion invoking key.  Alpha attempts to complete
      what you typed -- eliminating a lot of keystrokes, avoiding the
      need for copy/pasting, and reducing the possibility of typos.
      
 005  Technical note: the presence of un-used stops can interfere with
      the completion/expansion of the next shortcut, so each jump via
      the back-quote key first clears all stops.


	  	! Keyword Completions

 101  Most Fortran keywords (including statements, functions, intrinsic
      operators, etc.)  are available as "electric completions" If you
      type a portion of the name and press your "Complete" key, the rest
      of it will be finished for you.  Press the back-quote (`) key now
      to position the cursor behind the string "write" and then press
      your special "Complete" key to test:
      
         write×
      
      After the electric template has been created, you can press your
      special "Next Stop" key to advance to the next template marker.
      
 102  Now try it with these examples
      
         format×
         if×
         abs×
      
 103  Fortran is a case-insensitive language, so you can include all of
      
         write (*,*) 
         Write (*,*) 
         WRITE (*,*) 
      
      in your source files.  The "Complete Commands Using" preference
      allows you to select your personal style -- you can view (and
      change) the current setting for this preference by selecting the
      "Config > Fort Mode Prefs > Preferences" menu item.
      
      Note that all of the following are available as electric
      completions, but all will be converted to your chosen style:
      
         write×
         Write×
         WRITE×
         
      The "Spaces After Command/Function" preferences also determine if
      the (parentheses) are inserted touching the keyword or not.
      
 104  Most Fortran keywords can be completed after typing just a portion
      of the command.  If the 'hint' is ambiguous, you will be prompted
      to select from all available options.  Complete the following:
      
         wr×
         for×
         proc×
         int×
         pr×
      
 105  If you have typed a keyword and a "(", typing a consecutive "("
      will trigger a quick () template, with an additional stop at the
      end for easy navigation:
      
         sqrt(×
         tan(×
         if (×
      
      The logic here is that typing two "((" is slightly easier than
      typing ().
      
         log×
         min×
      
      In "normal" windows, selecting "Edit > Undo" a few times will
      eventually restore the original double text if that is what you
      really wanted.  (In this window, [undo] is disabled.)
      
      You can turn off the "Electric Dbl Left Paren" preference to
      disable this feature.
         
         
	  	! If ... Then ... Else ...
      
 201  The basic "IF" statement takes place on a single line, as in
      
         IF (<logical-expression>) <statement>
         
         if×
      
      Often times you need to execute several different statements,
      using the IF ...  THEN construction, as in
      
         IF (<logical-expression>) THEN
            <statement>
            <statement>
            ...
         ENDIF
      
      You can type and complete "ifthen" to create a template for this:
      
         ifthen×
      
      And of course IFTHEN works too:
      
         IFTHEN×
      
      The "Enddo Endif Are Single Words" preference determines if the
      template includes "ENDIF" vs "END IF".

 202  If you need to include an "ELSE IF" case, just complete "elseif" :
      
         IF (x .GE. y) THEN
            WRITE(*,*) 'x is positive and x >= y'
            elseif×
         ENDIF
      
      The "Elseif Is Single Word" preference determines if "elseif" will
      complete to "ELSEIF" vs "ELSE IF".
      
      
 203  If you know in advance that you want to create an "IF ...  ELSE"
      set of conditions, you can complete "ifelse" :
      
         ifelse×
      

	  	! Electric Contractions

 301  Some statements required two keywords, as in
       
          ASSIGN <label> TO <integer name>
          
          DOUBLE PRECISION <list of variables>
          
          BLOCK DATA <arguments>
       
      You can complete these as "contractions", i.e. 
       
          a't×
          
          d'p×
          
          b'd×
          
 302  UPPER and Mixed case "hints" work as well:
       
          A'T×
          
          D'p×
          
          b'D×
       
 303  There are special cases built in for "IF/ELSE" statements :
       
          i't×
          
          i'e×
          
          IF () THEN
             e'i×
          ENDIF
       
       Tip: in Fort mode the "Expand" key will also complete all of
       these electric contractions.


	  	! DO Completions
      
 401  Fortran has several different flavors of DO statements, including
       
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
       
      If you attempt to complete "DO" you will be offered all of these
      options in a list-pick dialog:
       
         do×
       
      Your last selection will be "remembered" the next time you attempt
      to complete DO as the default option in the dialog:
       
          do×
      
      There are other methods for a template for your desired flavor
      from the outset.

	  	 	! DO ... CONTINUE
      
 411  To create a "DO ...  CONTINUE" template, you can complete the
      string "doContinue" (or "docontinue" or DOCONTINUE) :
       
         doContinue×
       
 412  The electric contraction "d'c" is even handier:
       
         d'c×
         
         D'C×
       
 413  Once you have created a DO ...  CONTINUE template, you will want
      to assign a label to it.  After typing your label behind the DO
      you can press the Complete key to add it to the CONTINUE line:
       
         DO 4655× =
            
         CONTINUE
       
      Alternatively, or if you've created a DO construct from "scratch"
      without the use of a template, you can position the cursor behind
      the final CONTINUE and then press Complete to scan the previous
      text for the DO <label> statement:
       
         DO 4875 =
            WRITE (*,*) 'x is positive and x >= y'
         CONTINUE×
       
 414  Warning: when this routine scans for the next CONTINUE it searches
      for the next "orphaned" line, i.e. the one which does not have any
      label associated with it.  No attempt is made to deal with nesting
      constuctions, so you should only use this utility when the target
      CONTINUE is visible.
        
      Similarly, completing CONTINUE will search for the closest
      previous DO label.

                        ! DO ... END DO
      
 421  This is the most basic template.  

         doEndDo×
         
         doenddo×
         
      The "Enddo Endif Are Single Words" preference determines if
      "enddo" will be inserted as "ENDDO" vs "END DO" in the template.

      The "d'e" contraction is also useful:
        
         d'e×
         
         D'e×
        

      
	  	 	! DO WHILE ... (or WHILE ... DO)

 431  To create a DO ...  WHILE template, you can complete "doWhile" or
      "doEndDo" :
        
         doWhile×
         
         dowhile×
         
      The "Enddo Endif Are Single Words" preference determines if
      "enddo" will be inserted as "ENDDO" vs "END DO" in the template.
      
         DOWHILE×
         
      The "d'w" contraction is also useful:
        
         d'w×
         
         D'W×
         
 441  To create a WHILE ... DO template, simply complete "while":
        
         while×
        
      or use "w'd":
        
         w'd×
           
	  	 	! DO ... UNTIL ...


 451  To create a DO ... UNTIL template, complete "doUntil" :
        
         doUntil×
        
      or use the contraction "d'u" :
        
         d'u×

      (Do you sense a pattern here?)
        
        
	  	! Electric Return
      
 501  Fort mode has a sophisticated indentation routine that preserves
      the contents of columns 1-6.  For example, advance to the next ×
      marker and select the "Fortran > Reformat Block" command:
      
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
 9590    Format(A ' is not a valid character -- ')
         Write(6,160)
 9600    Format('Please reenter six characters,<P>')
         Write(6,161) 
 9610    Format('of type 0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F<P>') 
         Go to 335
 9620    End if
         End do
      
      Note that the cursor is positioned at the start of the next block
      of code after reformatting, in case you want to reformat several
      blocks in your file.
     
      
 502  If the "Indent On Return" preference is turned on, pressing the
      Return key will automatically indent the next line.
      
         
         IF(QS(i:i).eq."0")  THEN×
         ENDIF
      
      It will also indent the current line before creating the new one
      when this is appropriate:
      
         IF(QS(i:i).eq."0")  THEN
            digit(i)=0.0
            ENDIF×
      
      If you just want to create a new line without invoking any fancy
      indentation routines, press Control-Return.
       
 503  The "Fortran > Shift Left/Right" menu commands will shift the text
      as desired, preserving columns 1-6.  Advance to the next ×
      marker, select the "Fortran > Select Block" menu command, and then
      practice shifting the text left and right.

 9590    Format(A ' is not a valid character -- ')×
         Write(6,160)
 9600    Format('Please reenter six characters,<P>')
         Write(6,161) 
 9610    Format('of type 0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F<P>') 
         Go to 335
         
      Note also that Alpha has dynamic "Shift Left/Right Space" commands
      in the Fortran menu.
      
 504  If you are nearing the end of a line and want to continue it to
      the next, select the "Fortran > Continue Line" command.
      
         CHARACTER(255) :: allnames , cmdln , command , comment , ×

      In some cases, you might be happily typing away and find that the
      line has been automatically continued for you.  In this case, you
      can use the "Fortran > Toggle Continuation" command to add your
      chosen continuation character into column 6:
      
         CHARACTER(255) :: allnames , cmdln , command , comment ,
         ×
      
      Selecting "Toggle Continutation" multiple times will, er, toggle
      the continuation column character.

         CHARACTER(255) :: allnames , cmdln , command , comment ,
         exename , names , root , timeline , titleline ,×
         token , zcompiletimes , zexesizes , zruntimes×
      
      You can change your "Continuation Character" preference by
      selecting "Config > Fort Mode Prefs > Preferences".
      

	  	! Word Completions

 601  Here's a paragraph in which I use the word paragraph many times.
      If I become bored of typing the word paragraph, I can just type
      
         parag×

 602  This also works with Fortran variable names, so if I have
      "MYVARIABLE" which I don't wish to retype, I can just do
      
         MYV×
         
      instead.  If there are several similar completions available, such
      as "MYVARIANCE" and "MYVALUE" then pressing the Completion key
      multiple times will cycle through all of the options.
      
         MYV×

 603  Your "Electric Expansion" key (see "Config > Special Keys") can be
      used to expand acronyms.  For example, if you name your variables
      with a mix of upper and lower case letters ("myVariable"), you can
      then expand the string
      
         mv×
      
      to insert the correct text into the window.  Again, if you have
      several words that match the acronym, such as "myVariance" and
      "myValue" you can cycle through the options.
      
         mv×

	================================================================


	  	! Copyright

c     This document has been placed in the public domain.


