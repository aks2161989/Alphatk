## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "search.tcl"
 #                                          created: 06/13/1995 {08:56:37 pm}
 #                                      last update: 03/21/2006 {12:57:49 PM}
 #  
 # Description: 
 # 
 # Various procedures which deal with search/reg-search/grep type stuff
 # in Alpha.
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 # 
 # Copyright (c) 1999-2006  Vince Darley
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

proc search.tcl {} {}

#================================================================================
# 'greplist' and 'grepfset' are used for batch searching from the "find" dialog.
#  Hence, you really shouldn't mess with them unless you know what you are doing.
#================================================================================
proc greplist {args} {
    global tileLeft tileTop tileWidth tileHeight errorHeight \
      browse::separator browse::jumpTo
    
    set recurse [lindex $args 0]
    set word [lindex $args 1]
    set args [lrange $args 2 end]
    
    set num [expr {[llength $args] - 2}]
    set exp [lindex $args $num]
    set arglist [lindex $args [expr {$num + 1}]]
    
    set opened 0
    set cid [scancontext create]
    
    set cmd [lrange $args 0 [expr {$num - 1}]]
    eval scanmatch $cmd {$cid $exp {
	if {!$word || [regexp -nocase -- "(^|\[^a-zA-Z0-9\])${exp}(\[^a-zA-Z0-9\]|\$)" $matchInfo(line)]} {
	    if {!$opened} {
		set opened 1
		win::SetProportions
		set w [new -n {* Batch Find *} -m Brws -g $tileLeft $tileTop $tileWidth $errorHeight -tabsize 8]
		insertText "(<cr> to go to match)\r${browse::separator}\r"
	    }
	    set l [expr {20 - [string length [file tail $f]]}]
	    regsub -all "\t" $matchInfo(line) "  " text
	    insertText -w $w "\"[file tail $f]\"[format "%$l\s" ""]; Line $matchInfo(linenum): ${text}${browse::jumpTo}$f\r"}
	}
    }
    set total [llength $arglist]
    set count 0
    foreach f $arglist {
	status::msg "Searching ([incr count] of $total files): [file tail $f]"
	if {![catch {set fid [alphaOpen $f]}]} {
	    scanfile $cid $fid
	    close $fid
	}
	incr count
    }
    scancontext delete $cid
    
    if {$opened} {
	selectText [nextLineStart [nextLineStart [minPos]]] \
	  [nextLineStart [nextLineStart [nextLineStart [minPos]]]]
	setWinInfo dirty 0
	setWinInfo read-only 1
    }
    status::msg ""
}


## 
 # -------------------------------------------------------------------------
 # 
 # "grepfset" --
 # 
 #  args: wordmatch ?-nocase? expression fileset
 #  Obviously we ignore wordmatch
 #  
 #  If the 'Grep' box was set, then the search item is _not_ quoted.
 #  
 #  Non grep searching problems:
 #  
 #  If it wasn't set, then some backslash quoting takes place. 
 #  (The chars: \.+*[]$^ are all quoted)
 #  Unfortunately, this latter case is done incorrectly, so most
 #  non-grep searches which contain a grep-sensitive character fail.
 #  The quoting should use the equivalent of the procedure 'quote::Regfind'
 #  but it doesn't quote () and perhaps other important characters.
 #  
 #  Even worse, if the string contained any '{' it never reaches this
 #  procedure (there must be an internal error due to bad quoting).
 # 
 # -------------------------------------------------------------------------
 ##
proc grepfset {args} {
    set num [expr {[llength $args] - 2}]
    # the 'find' expression
    set exp [lindex $args $num]
    # the fileset
    set fset [lindex $args [expr {$num + 1}]]
    eval greplist 0 [lrange $args 0 [expr {$num-1}]] {$exp [getFileSet $fset]}
}

proc grep {exp args} {
    global browse::jumpTo

    set files {}
    foreach arg $args {
	eval [list lappend files] [glob -types TEXT -nocomplain -- $arg]
    }
    if {![llength $files]} {return "No files matched pattern"}
    set cid [scancontext create]
    scanmatch $cid $exp {
	if {!$blah} {
	    set blah 1
	    set lines "(<cr> to go to match)\n"
	}
	set l [expr {20 - [string length [file tail $f]]}]
	regsub -all "\t" $matchInfo(line) "  " text
	append lines "\"[file tail $f]\"[format "%$l\s" ""]; Line $matchInfo(linenum): ${text}${browse::jumpTo}$f\n"
    }
    
    set blah 0
    set lines ""
    
    foreach f $files {
	if {![catch {set fid [alphaOpen $f]}]} {
	    scanfile $cid $fid
	    close $fid
	}
    }
    scancontext delete $cid
    return [string trimright $lines "\r"]
}

proc grepnames {exp args} {
    set files {}
    foreach arg $args {
	eval lappend files [glob -types TEXT -nocomplain -- $arg]
    }
    if {![llength $files]} {return "No files matched pattern"}
    set cid [scancontext create]
    scanmatch $cid $exp {
	lappend filenames $f
    }
    set filenames ""
    foreach f $files {
	if {![catch {set fid [alphaOpen $f]}]} {
	    status::msg [file tail $f]
	    scanfile $cid $fid
	    close $fid
	}
    }
    scancontext delete $cid
    return $filenames
}

proc findBatch {forward ignore regexp word pat} {
    matchingLines $pat $forward $ignore $word $regexp 
}

## 
 # -------------------------------------------------------------------------
 #	 
 #  "findPatJustBefore" --
 #	
 #  Utility proc to check whether the first occurrence of 'findpat' to
 #  the left of 'pos' is actually an occurrence of 'pat'.  It can be
 #  used to check if we're part of an '} else {' (see Tcl::electricLeft)
 #  or in TeX mode if we're in the argument of a '\label{' or '\ref{'
 #  (see smartScripts) for example.
 #	 
 #  A typical usage has the regexp 'pat' end in '$', so that it must
 #  match all the text up to 'pos'.  'matchw' can be used to store the
 #  first '()' pair match in the regexp.
 #	 
 #  New: maxlook restricts how far this proc will search.  The default
 #  is only 100 (not the entire file), after all this proc is supposed
 #  to look 'just before'!
 # -------------------------------------------------------------------------
 ##
proc findPatJustBefore { findpat pat {pos ""} {matchw ""} {maxlook 100} } {
    if { $pos == "" } {set pos [getPos] }
    if {[pos::compare $pos == [maxPos]]} { set pos [pos::math $pos - 1]}
    if { $matchw != "" } { upvar 1 $matchw word }
    set res [search -s -n -f 0 -r 1 -l [pos::math $pos - $maxlook] -- "$findpat" $pos]
    if {[llength $res]} {
	if {[regexp -- "$pat" [getText [lindex $res 0] $pos] dum word]} {
	    return [lindex $res 0]
	}
    }
    return
}
# Look for pattern in filename after integer offset afterPos and, if
# found, open the file quietly and select the pattern 
# author Jonathan Guyer
proc selectPatternInFile {filename pattern {afterOffset ""}} {
    if {$afterOffset == ""} {set afterOffset 0}
    set searchResult [file::searchFor $filename $pattern 1]
    if {[lindex $searchResult 0] < $afterOffset} {
	return 0
    }
    placeBookmark
    file::openQuietly $filename
    set firstPos [pos::math [minPos] + [lindex $searchResult 0]]
    set endPos [pos::math [minPos] + [lindex $searchResult 1]]
    selectText $firstPos $endPos
    status::msg "press <Ctrl .> to return to original cursor position"
    return 1
}

proc nextFunc {} {
    hook::callProcForWin searchFunc "" 1
}

proc prevFunc {} {
    hook::callProcForWin searchFunc "" 0
}

proc ::searchFunc {dir} {
    
    if {[catch {win::getModeVar [win::Current] funcExpr} pattern]} {
	# for modes that have no functions, just use filemarks
	findViaFileMarks $dir
	return
    }
	
    set pos [getPos]
    selectText $pos $pos
    
    if {$dir} {
	set pos [pos::math $pos + 1]
	set lastStop [maxPos]
    } else {
	set pos [pos::math $pos - 1]
	set lastStop [minPos]
    }
    if {![catch {search -s -f $dir -i 1 -r 1 -- $pattern $pos} res]} {
	eval selectText $res
    } else {
	goto $lastStop
	if {$dir} {
	    status::msg "At bottom, no more functions in this direction"
	} else {
	    status::msg "At top, no more functions in this direction"
	}
    }
}

#===========================================================================
# Juan Falgueras (7/Abril/93)
# you only need to select (or not) text and move *forward and backward*
# faster than iSearch (if you have there the |word wo|rd..).
#===========================================================================

proc quickSearch {dir} {
    if {[pos::compare [selEnd] == [getPos]]} {
	backwardChar
	hiliteWord
    }
    set myPos [expr {$dir ? [selEnd] : [pos::math [getPos] - 1]}]
    set text [getSelect]
    set searchResult [search -s -n -f $dir -m 0 -i 1 -r 0 -- $text $myPos]
    if {[llength $searchResult] == 0} {
	beep
	status::msg [concat [expr {$dir ? "->" : "<-"}] '$text' " not found"]
	return 0
    } else {
	status::msg [concat [expr {$dir ? "->" : "<-"}] '$text']
	eval selectText $searchResult
	return 1
    }
}

# ===========================================================================
# 
# .