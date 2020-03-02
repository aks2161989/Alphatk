## -*-Tcl-*-
 # ==========================================================================
 # Examples - a Help package for Alpha
 #
 # FILE: "Shell-Example.tcl"
 #                                          created: 10/17/2000 {02:18:43 pm}
 #                                      last update: 03/06/2006 {06:40:50 PM}
 # Description: 
 # 
 # Script for the "Shell Example" in the Examples package.
 #
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # ==========================================================================
 ##

# The "catch" is necessary due to some changes in "Shel::carriageReturn"

tclShell 

insertText {cd [file join $HOME]}
catch {Shel::carriageReturn}

insertText {ls}
catch {Shel::carriageReturn}

insertText {cd [file join $HOME Examples]}
catch {Shel::carriageReturn}

insertText {glob -dir [file join $HOME Examples] *}
catch {Shel::carriageReturn}

insertText {version}
catch {Shel::carriageReturn}

insertText {alertnote "Hello World."}
catch {Shel::carriageReturn}

