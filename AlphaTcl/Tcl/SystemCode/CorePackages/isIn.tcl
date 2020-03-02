## -*-Tcl-*-
 # ###################################################################
 #  AlphaTcl 
 # 
 #  FILE: "isIn.tcl"
 #                                    created: 2001-05-05
 #                                last update: 02/16/2005 {04:58:05 PM} 
 # File : "isIn.tcl"
 # Author : Bernard Desgraupes and Joachim Kock
 # e-mail : <berdesg@easynet.fr>  <kock@math.unice.fr>
 # www : <http://perso.easynet.fr/~berdesg/alpha.html>
 #
 #  Description: 
 # 
 # Procedures for handling comments - in particular to determine
 # whether a given position is in a comment or not.  The answer to this
 # question takes into account that logical line starts may not
 # coincide with physical line starts, that the meaning of a comment
 # char may be suspended, either by an escape char (like in Tcl: \#) or
 # when being part of a quoted string (e.g. "#").
 #
 # The mode specific aspects of these questions are controlled by one
 # preference flag
 #
 #   commentsContinuation
 #
 # and three series of mode specific global variables
 #
 #   set (mode)::escapeChar "\\"
 #   set (mode)::quotedstringChar "\""
 #   set (mode)::lineContinuationChar "\\"
 #
 # These variables must be defined by each mode individually.  If the
 # variable is not defined, the corresponding check is simply not
 # performed, so modes where the concept of escapeChar,
 # quotedstringChar, or lineContinuationChar has no meaning can (and
 # should) just leave that variable undefined. 
 #
 # The flag commentsContinuation controls whether every comment char
 # is detected (value 2), or if it is only detected at line start modulo
 # whitespace (value 1), or only at proper line start (value 0).  For
 # most modes, the global setting =2 is adequate according to syntax,
 # but the user may prefer to override this, according to typing habits.
 # For Text and Mail modes the flag should be set =1.  Fortran syntax
 # requires the flag to be =0.
 # Mode writers should declare this flag like in this example :
 #   newPref v commentsContinuation 0 TeX "" \
 #    [list "only at line start" "spaces allowed" "anywhere"] index
 #
 # ###################################################################
 ##

# The variable {mode}::escapeChar is used only in the proc
# text::isEscaped, which in turn is called by text::isInQuotedString,
# text::trueStartOfLine, text::InSingleComment, and
# text::InDoubleComment.  This variable holds the character that
# suspends the meaning of special characters...  In many modes it is \
# (single backslash), eg.  C, C++, TeX, Tcl...  In modes where there is
# no such thing, the variable should be left undefined.
proc text::isEscaped {args} {
  win::parseArgs w {position ""}
  
  set escapeChar [win::getModeVar $w escapeChar ""]
  if {$escapeChar == ""} {
    return 0
  }
  if {$position==""} {
    set position [getPos -w $w]
  }
  
  # An actual 'search' for repeated $escapeChar may be faster?
  set position [pos::math -w $w $position - 1]
  set count 0
  while {[lookAt -w $w $position] eq $escapeChar} {
      incr count
      set position [pos::math -w $w $position - 1]
      if {[pos::compare -w $w $position == [minPos]]} {
	  break
      }
  }
  return [expr {$count % 2}]
}


# The variable {mode}::quotedstringChar is used only in
# text::isInQuotedString, which in turn is called from
# text::InSingleComment and text::InDoubleComment.  It holds the
# character, in the middle of a pair of which certain special
# characters are given their literal meaning...  In many programming
# modes this is " (double quote).  In modes where there is no such
# thing, the variable should be left undefined.
proc text::isInQuotedString {args} {
  win::parseArgs w {position ""}
  
  set quotedstringChar [win::getModeVar $w quotedstringChar ""]
  if {$quotedstringChar == ""} {
    return 0
  }
  if {$position==""} {
    set position [getPos -w $w]
  }
  set start [text::trueStartOfLine -w $w $position]
  set qcount 0
  while  {![catch {search -w $w -f 1 -r 1 -s -l $position \
   -- "[quote::Regfind $quotedstringChar]" $start} res]} {
    #if not escaped
    if {![text::isEscaped -w $w [lindex $res 0]]} { 
      incr qcount;         #then count it
    }
    set start [lindex $res 1]
  }
  #if odd number of true quotes then we're in:
  return [expr {$qcount % 2}]
}

# The variable (mode)::lineContinuationChar is used only by
# text::trueStartOfLine, which in turn is called from
# text::isInQuotedString and text::isInSingleComment.  In modes where no
# such thing exists, leave the variable undefined.
# 
# Proc to find the true beginning of a line i-e the beginning of the
# logical line and not only of the physical line : this means that it
# has to take into account continued line endings with a _single_
# backslash.
proc text::trueStartOfLine {args} {
    win::parseArgs w {position ""}
    
  if {$position==""} {
    set position [getPos -w $w]
  }
  set begpos [pos::lineStart -w $w $position]
  set lineContinuationChar [win::getModeVar $w lineContinuationChar ""]
  if {$lineContinuationChar == ""} {
    return $begpos
  }
  while {[lookAt -w $w [pos::math -w $w $begpos - 2]] eq $lineContinuationChar} {
    if {![text::isEscaped -w $w [pos::math -w $w $begpos - 2]]} {
      set begpos [pos::prevLineStart -w $w $begpos]
    } else {break}
  }
  return $begpos
}


# Proc to determine whether we are in a single line comment.  Answer: 0
# or 1.  In affirmative case, the variable commentPos will acquire the
# position of the active comment tag (list of two integers, e.g. 13 14)
proc text::isInSingleComment {args} {
    win::parseArgs w pos {commentPos ""}
    
    global commentsContinuation
    if {$commentPos != ""} {
	upvar 1 $commentPos foundPos
    }
    set startpos [text::trueStartOfLine -w $w $pos]
    
    set commentCharList [comment::Characters "General" [win::getInfo $w varmodes]]

    foreach commentCh $commentCharList {
	set commentCh [string trim $commentCh]
	while  {![catch {search -w $w -f 1 -r 1 -s -l $pos \
	  -- "[quote::Regfind $commentCh]" $startpos} foundPos]} {
	    if {[text::isEscaped -w $w [lindex $foundPos 0]] || \
	      [text::isInQuotedString -w $w [lindex $foundPos 0]] || \
	      [text::isInDoubleComment -w $w [lindex $foundPos 0]]} {
		#escaped, quoted, or in double comment, so keep searching:
		set startpos [lindex $foundPos 1]
		continue  ;#looking for the same commentCh
	    } elseif {$commentsContinuation == 1} { 
		# 1 = "spaces allowed"
		#(actually we should perform line-continuation substitution)
		set txt [getText -w $w $startpos [lindex $foundPos 0]]
		if {![is::Whitespace $txt]} {
		    #found preceding nonwhite, so there can't possibly
		    #be any comments (of this type) on this line:
		    break  ;#and proceed to the next commentCh in the list
		}
	    } elseif {$commentsContinuation == 0} { 
		# 0 = "only at line start"
		#(comments can ONLY start in column 1)
		if {![pos::compare -w $w $startpos == [lindex $foundPos 0] ]} {
		    #we are not at line start, so this comment is not valid:
		    break  ;#and proceed to the next commentCh in the list
		}
	    }
	    return 1  ;#this is a true comment
	}
    }
    return 0  ;#found none
}


# Proc to determine whether we are in a double comment, i.e. a comment
# defined by an opening and a closing tag.  In fact the proc does not
# bother whether a closing tag exists after the cursor position,
# because anyway the user might not have typed it yet...
# 
# Result: 0 or 1.  In affirmative case, the variable openingPos will
# acquire the position of the active opening comment tag (list of two
# positions, e.g. 13 15 in Alpha or 13.2 13.4 in Alphatk)
proc text::isInDoubleComment {args} {
    win::parseArgs w pos {openingPos ""}
    
    if {$openingPos != ""} {
	upvar 1 $openingPos foundPos
    }
    
    set cpar [comment::Characters "Paragraph" [win::getInfo $w varmodes]]
    if {[llength $cpar]} {
	set lftComment [string trim [lindex $cpar 0]]
	set rtComment [string trim [lindex $cpar 1]]
	if {($lftComment ne $rtComment)} {
	    #otherwise we don't care...
	    set lftpos [pos::math -w $w $pos - 1]
	    #adjust this if you use very long comments
	    set searchSize 5000
	    set searchlim [pos::math -w $w $lftpos - $searchSize]
	    while {![catch {search -w $w -f 0 -r 1 -s -l $searchlim \
	      -- "[quote::Regfind $lftComment]" $lftpos} foundPos]} {
		if {[text::isEscaped -w $w [lindex $foundPos 0]] \
		  || [text::isInQuotedString -w $w [lindex $foundPos 0]]} {
		    #escaped or quoted; keep searching:
		    set lftpos [pos::math -w $w [lindex $foundPos 0] - 1]
		    continue  ;#to look backwards for an opening
		} else {
		    #found a true lftComment.  Now looking for a rtComment
		    set rtpos [lindex $foundPos 1]
		    if {![catch {search -w $w -f 1 -r 1 -s -l $pos \
		      -- "[quote::Regfind $rtComment]" $rtpos} res]} {
			#found a closing rtComment, so there is no reason to
			#search further back for an opening:
			break  ;# = return 0
		    }
		}
		return 1  ;#found lftComment without subsequent rtComment
	    }
	}
    }
    return 0  ;#found none
}


# Proc to determine whether the given position is in a comment.
# Answer: 0 or 1. In affirmative case, the variable st will acquire the
# suggested way of prefixing the following line, as used by the proc
# bind::CarriageReturn
proc text::isInComment {args} {
    win::parseArgs w pos {st ""}
    
    if {[pos::compare -w $w $pos == [minPos]]} {
	return 0
    }
    if {$st != ""} {
	upvar 1 $st start
    }
    
    # First case : double comments
    if {[text::isInDoubleComment -w $w $pos]} {
	set cpar [comment::Characters "Paragraph" [win::getInfo $w varmodes]]
	if {![llength $cpar]} {
	    # We don't have paragraph style comment characters.
	    return 0
	}
	set txt [getText -w $w [pos::lineStart -w $w $pos] $pos]
	# Only go through this trouble if we need to calculate 'st'
	if {$st != ""} {
	    set openCom [string trim [lindex $cpar 0]]
	    set midCom [string trim [lindex $cpar 2]]
	    # determine the indent/comment prefix of next line:
	    if {[regexp -- "^(.*)[quote::Regfind $openCom](\[ \t\]*)" \
	      $txt "" start c]} {
		# the line has an opening comment, so next line gets a
		# middle comment:
		regsub -all "\[^ \t\]" $start " " start
		append start [string trimright [lindex $cpar 2]] $c
	    } else {
		# no opening comment in this line, so just copy the leading
		# whitespace, possibly with an occurrence of the
		# middle-continuation-comment char:
		regexp -- "^\[ \t\]*[quote::Regfind $midCom]?\[ \t\]*" \
		  $txt start
	    }
	}
	return 1
    }
    # Second case : single comments
    if {[text::isInSingleComment -w $w $pos commentPos]} {
	# Only go through this trouble if we need to calculate 'st'
	if {$st != ""} {
	    #set preString, commentString and postString:
	    set previousText [getText -w $w \
	      [pos::lineStart -w $w [lindex $commentPos 0]] \
	      [lindex $commentPos 0]]
	    regsub -all "\[^ \t\]" $previousText " " preString
	    set commentString [getText -w $w [lindex $commentPos 0] \
	      [lindex $commentPos 1]]
	    set followingText [getText -w $w [lindex $commentPos 1] $pos]
	    if {![regexp -- "([quote::Regfind $commentString]|\[ \t\])*" \
	      $followingText postString]} {
		set postString ""
	    }
	    set start $preString$commentString$postString
	}
	return 1
    }
    return 0
}

################################################################################


proc isAtLineEnd {args} {
    win::parseArgs w pos
    return [regexp {[\r\n]} [lookAt -w $w $pos]]
}

######################################################################
# NOTE THAT the following two procs
#   text::isInString
#   literalChar
# are primitive equivalents of
#   text::isInQuotedString
#   text::isEscaped
# and they could probably be replaced or overwritten:
#
# proc text::isInString {pos} {
#   text::isInQuotedString $pos
# }
#
# proc literalChar {} {
#   text::isEscaped
# }
#
# CHECK OUT THIS CAREFULLY BEFORE CHANGING ANYTHING!
#
######################################################################

proc text::isInString {args} {
    win::parseArgs w pos
    return [text::isInQuotedString -w $w $pos]
}

proc literalChar {args} {
    win::parseArgs w
    return [text::isEscaped -w $w]
}
