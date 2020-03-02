## -*-Tcl-*- (install)
 # ###################################################################
 # 
 #  FILE: "smartPaste.tcl"
 #                                    created: 7/10/97 {2:50:59 pm} 
 #                                last update: 03/21/2006 {02:19:15 PM} 
 #  Author: Vince Darley
 #  E-mail: <vince@santafe.edu>
 #    mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #     www: <http://www.santafe.edu/~vince/>
 #  
 # Copyright (c) 1997-2006  Vince Darley, all rights reserved
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # Distributable under Tcl-style (free) license.
 # ###################################################################
 ##

# extension declaration
alpha::feature smartPaste 0.7.4 global {
    namespace eval smartPaste {}
} {
    # Turn on -- take over from core 'paste'
    hook::procRename ::paste ::smartPaste::paste
} {
    # Turn off -- revert.
    hook::procRevert ::smartPaste::paste
} maintainer {
    {Vince Darley} <vince@santafe.edu> <http://www.santafe.edu/~vince/>
} description {
    Re-indents code as you cut and paste
} help {
    This package supports the automatic indentation of the clipboard contents
    with they are Pasted into the active window.
    
    Preferences: Features
    
    By default, the level of indentation is that of the previous line.  Many
    modes have more sophisticated indentation routines, however, which take
    the context surrounding the cursor position into account.  Typically
    in programming modes, code will be indented to reflect the correct
    nesting level of braces, etc.
} uninstall this-file

proc smartPaste.tcl {} {}

## 
 # 
 # "smartPaste::paste" --
 # 
 #  If a mode has the <mode>::correctIndentation proc, then give that proc
 #  a position in the current file (where pasting will occur) together with
 #  the first non-whitespace characters to be pasted.  That proc should
 #  return a number indicating the number of characters to indent.
 # 
 # Results:
 #  Returns whatever is returned by the actual 'paste' command which is 
 #  eventually triggered.  This should be the character ranges which
 #  were pasted.
 # 
 # Side effects:
 #  text is pasted into the window.  IF THE mode::correctIndentation proc
 #  fails with an error, this proc will DO NOTHING AT ALL.  That is a bug
 #  in the mode procedure, not in this one.
 # 
 ##
proc smartPaste::paste {args} {
    win::parseArgs w
    if {$w eq "" \
      || [win::getInfo $w read-only] \
      || [catch {getScrap} scrap] \
      || ![regexp -- "^(\\s*)(\\S+)" $scrap "" white next] \
      || ![string is space [getText -w $w [lineStart -w $w [getPos -w $w]] [getPos -w $w]]] \
      || ([set ci [hook::procForWin correctIndentation $w]] eq "")} {
	# If any of the above conditions are true, there's
	# nothing 'smart' to do.
	return [hook::procOriginal ::smartPaste::paste -w $w]
    }
    # find correct indentation of line to be pasted
    # this requires <mode>::correctIndentation -w <win>
    set newIndent [hook::callProcForWin correctIndentation $w \
      [getPos -w $w] $next]
    
    # turn scrap indentation into spaces
    set oldIndent [string length [text::maxSpaceForm -w $w \
      [lindex [split $white "\r\n"] end]]]

    # If we're already positioned at the same level as what should be
    # there, then make sure we get the first line correctly indented.
    set end [selEnd -w $w]
    if {$oldIndent == $newIndent} {
	set p [lineStart -w $w [getPos -w $w]]
	if {[pos::compare -w $w $p != [getPos -w $w]]} {
	    set diff [pos::diff -w $w $p [getPos -w $w]]
	    set end [pos::math -w $w $end - $diff]
	    deleteText -w $w $p [getPos -w $w]
	}
    }
    set useScrap [text::indentBy -w $w $scrap [expr {$newIndent - $oldIndent}]]
  
    # We must mimic 'paste' so that if anything else is intercepting
    # that command, the correct things happen.
    putScrap $useScrap
    selectText -w $w [set p [lineStart -w $w [getPos -w $w]]] $end
    set ranges [hook::procOriginal ::smartPaste::paste -w $w]
    putScrap $scrap
    return $ranges
}

# ===========================================================================
# 
# .