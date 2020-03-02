## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 #
 # FILE: "paragraphs.tcl"
 #                                          created: 10/29/1999 {14:12:52 PM}
 #                                      last update: 03/21/2006 {01:28:32 PM}
 #
 # Description:
 # 
 # Procedures for identifying, manipulating paragraphs in active windows.
 # 
 # Author: largely Vince Darley; originals probably Pete Keleher
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 # 
 # Copyright (c) 1999-2006  Vince Darley
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

proc paragraphs.tcl {} {}

namespace eval paragraph {}

## 
 # -------------------------------------------------------------------------
 # 
 # "paragraph::fill" --
 # 
 #  If there's a selection, extend the selection to complete lines and
 #  fill all paragraphs in that selection.  If there is no selection,
 #  fill the paragraph surrounding the insertion point.  The definition
 #  of a 'paragraph' may be mode dependent (see paraStart, paraFinish).
 #  If there is no selection the cursor position will be preserved; if
 #  there is a selection the cursor will be set at the start of the first
 #  paragraph.
 #  
 #  <JK> The individual paragraphs in the selection are treated one by
 #  one starting with the last one.  This backwards strategy is necessary
 #  to maintain integrity of the limits.  This proc and paragraph::fillOne
 #  were overhauled in May 2003, cf. Bugzilla 768, 945, and 952.
 #	   
 # -------------------------------------------------------------------------
 ##

proc paragraph::fill {} {
    if {![win::checkIfWinToEdit]} {return}
    if { [isSelection] } {
	# We want the selection to consist of compelte lines:
	set start [lineStart [getPos]]
	set end [selEnd]
	if { [pos::compare $end > [lineStart $end]] } {
	    set end [pos::nextLineStart $end]
	}
	# Fill the paragraphs in the selection one by one backwards:
	while { [pos::compare $end > $start] } {
	    # Set the cursor somewhere near the end (it doesn't matter so much):
	    goto [pos::math $end - 1]
	    set end [paragraph::fillOne 0 $start $end]
	    # fillOne returns the start position of the filled paragraph.
	    # This position will serve as $end for the next call, to avoid
	    # gobbling what we already filled.
	}
	goto $start
    } else {
	paragraph::fillOne 1 ; # 1 = remember cursor position
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "paragraph::fillOne" --
 # 
 #  Fills the single paragraph surrounding the insertion point.  If called
 #  with parameter '0', it doesn't bother to remember where the insertion
 #  point was, which makes multiple paragraph fills quicker when called by
 #  'fillParagraph'.  If the optional arguments minstart and maxend are
 #  specified, only text within these limits is modified, even if logically
 #  the paragraph is actually bigger.  This is used by [paragraph::fill]:
 #  if there is a selection then only that portion of text is reflowed.
 #  
 #  If the optional fillCol is specified then that is used for the 
 #  fillColumn instead of querying the current window's mode value(s).
 #  If it is -1 then we assume an infinite fill column.  This is used
 #  by paragraphToLine, for example.
 #  
 #  The proc respects mode-dependent definitions of paragraphs and comment
 #  chars.
 #  
 #  The proc returns the start position of the first paragraph filled ---
 #  this is used by the proc paragraph::fill to determine the next
 #  paragraph to fill in multiple-paragraph operations (well, in fact the
 #  previous since we are working backwards).  
 #  
 #  This version <JK, May 2003> is a complete rewrite, solving many bugs
 #  cf. Bugzilla 768, 952, and 945, as well as others mentionned in 945:
 #  This new version handles also C-style double-comments, nested comments,
 #  and ragged comments.
 #  
 #  Caveat: nested double-comments are not detected.
 #  
 #  <old remarks>
 #  Fixes: won't put a double-space after abbreviations like 'e.g.', 'i.e.'
 #  Works around the Alpha 'replaceText' bug.
 #  
 #  <JK:Dec2003> Fixed Bug 1258 and the paragraph-start cursor position bug
 #  (also mentionned there), cf.  suggestions from Craig.  (See on-location
 #  comments.)  Some simplification of handling of commented empty lines.
 #  Some tidying-up: use ($ch){$i} instead of [string repeat $ch $i] since
 #  now [search] is happy with that.  Some [nextLineStart] replaced by
 #  [pos::nextLineStart] for consistency.
 #  
 # -------------------------------------------------------------------------
 ##

## Note: if minstart and maxend are given they ought to span complete lines
## and the cursor position is then assumed to be strictly in between.
## The only caller using these optional arguments is [paragraph::fill]
## and it meets the assumption.
proc paragraph::fillOne {{remember 1} {minstart {}} {maxend {}} {fillCol ""}} {

    if {$fillCol eq ""} {
	if {[catch {win::getModeVar [win::Current] fillColumn} fillCol]} {
	    set fillCol "infinite"
	}
    }
    
    #### Part 1.  Positions.
    #### 
    #### The first part is concerned with finding the positions $pos,
    #### $start, and $end, as well as the variables $ch, $chreg,
    #### $chregRubbber which hold comment info (if we are in a comment,
    #### otherwise this variable remains undefined), and the flag
    #### $remember, and the record $memory.
    #### 
    #### Note that $start and $end are always at linestart, so the text they
    #### span contains complete lines.
    #### 
    #### Remark: parentheses can be used freely when building the search 
    #### patterns: the subpatterns are never used.
    #### 

    set pos [getPos]
    # Note: if pos is at linestart then it will later be moved back to the
    # previous line end.  NO LONGER! <JK:Dec2003> See comments in code
    # below.  If no remember, and if $pos is not in whitespace-at-paragraph-
    # start, then it will be moved to $start just prior to Part 2, in order
    # to flow according to first line of paragraph.
    set pos1 [pos::lineStart $pos]
    set pos2 [pos::lineEnd $pos]
    # pos1 and pos2 will not be changed
    
    # For double comments we also check the line start:
    if { [text::isInDoubleComment $pos1 openingPos] || \
      [text::isInDoubleComment $pos openingPos] } {
	set cpar [comment::Characters "Paragraph"]
	set lftComment [string trim [lindex $cpar 0]]
	set rtComment [string trim [lindex $cpar 1]]
	set ch [string trim [lindex $cpar 2]]
	if {$ch eq ""} {
	    set chreg {(?:)}
	} else {
	    set chreg [quote::Regfind $ch]
	}
	set chregRubber " $chreg "
	regsub -all -- {[ \t]+} $chregRubber "\[ \t\]*" chregRubber
	set lftchreg [quote::Regfind ${lftComment}]
	set rtchreg [quote::Regfind ${rtComment}]
	
	# Inside this comment block we will now look for paragraph breaks
	# We allow a mode to specify additional comment block breaks - 
	# for example Java mode probably wants to specify <p>, <br> as
	# these are commonly used in Javadoc comments.
	set extras [win::getModeVar [win::Current] commentBlockBreaks ""]
	set midpat "\[ \t\]*${chreg}*\[ \t\]*"
	if {$extras ne ""} {
	    foreach e $extras {
		lappend regs [quote::Regfind $e]
	    }
	    append midpat "([join $regs |])*\[ \t\]*"
	}
	
	set startBreakPat "(\[ \t\]*${lftchreg}|^${midpat}\$)"
	# Either the opening comment or an empty line (modulo the comment char)
	
	set endBreakPat "(\[ \t\]*${rtchreg}|^${midpat}\$)"
	# Either the closing comment or an empty line (modulo the comment char)
	
	set searchFrom $pos
	set startPos [search -s -n -f 0 -r 1 "$startBreakPat" $searchFrom]
	set start [lindex $startPos 0]
	if { [regexp -- "^\[ \t\]*(${lftchreg})*${midpat}\$" \
	  [getText $start [pos::lineEnd $start]]] } {
	    # We found blank line, not opening comment
	    set start [pos::nextLineStart $start]
	}
	set searchFrom [pos::lineStart $pos]
	# This is an ad hoc workaround; typically $pos would be in 
	# the middle of the closing comment
	set end [search -s -f 1 -r 1 "$endBreakPat" $searchFrom]
	
	# It is sure that we find the startBreakPattern, because we know there
	# is an opening comment.  Now check that we found an endBreakPattern:
	if { [llength $end] } {
	    set end [lindex $end 0]
	} else {
	    set end [search -s -n -f 1 -r 1 {^[^${chreg}]*$} $searchFrom]
	    if { [llength $end] } {
		set end [lindex $end 0]
	    } else {
		set end [maxPos] ; # this is stupid, but what else can we do?
	    }
	}
	if { [pos::compare $end < $start] } {
	    # This can occur because we are using an ad hoc value of $searchFrom
	    set end $start
	}
	
	
	# For single comment we check the end of the line:
    } elseif { [text::isInComment $pos2 ch] } {
	set ch [string trim $ch]
	set chreg [quote::Regfind $ch]
	set chregRubber " $chreg "
	regsub -all -- {[ \t]+} $chregRubber "\[ \t\]*" chregRubber

	# <JK:Dec2003> The following three lines date from May 2003.  They
	# have since been found to prevent proper flowing if the cursor is
	# at line-start, and they are now commented out.  (Probably they were
	# there originally in order to set the search position for the
	# backwards search, but in any case the regexp doesn't start with a
	# linebreak, so there is no difference whether the search begins at
	# line-start or at the preceding line-end.)  If further problems
	# arise with commented paragraph filling then a first debugging step
	# would be to put these three lines back in, and see if it helps...

#         if { [pos::compare $pos == $pos1] } { 
#              set pos [pos::math $pos -1] 
#         }
	
	# Inside this comment block we will now look for paragraph breaks

	# This old-style break pattern is only used as fallback:
	set breakPat "^\[ \t\]*(${chreg}+\[ \t\]*(${chreg})*\[ \t\]*\$|\[^${chreg} \r\n\t\]|\$)"
	
	# FANCY PLUGIN:   awareness of nested comments
	set commentChar [string trim [comment::Characters "General"]]
	if { [string length $commentChar] == 1 } {	    
	    set chReduced $ch
	    regsub -all -- {[ \t]+} $chReduced "" chReduced
	    set level [string length $chReduced]
	    if { [string equal $chReduced [string repeat $commentChar $level]] } {
		# This is the 'regular case' handled by the plugin:
		# The commentChar is a single char, and the commentString
		# in question consists of repetitions of this char, mixed
		# with whitespace.
		
		# Build the break pattern:
		set comChReg [quote::Regfind $commentChar]
		set cP "${comChReg}\[ \t\]*"
		set chregRubber "\[ \t\]*($cP){$level}"
		set breakPat "^\[ \t\]*"
		# Either a line with more comment chars:
		append breakPat "(($cP){$level}"
		append breakPat "${comChReg}"
		# Or a line with the same number of comment chars, but blank:
		append breakPat "|($cP){$level}\$"
		# Or a line with fewer comment chars:
		for { set i 0 } { $i < $level } {incr i } {
		    append breakPat "|($cP){$i}(\[^${comChReg} \t\r\n\]\[^\r\n\]*\$|\$)"
		}
		append breakPat ")"
	    }
	}
	# END OF FANCY PLUGIN
	
	# Check that the comment has a leading/trailing almost blank
	# line. Look for any line which is either blank, or starts
	# with a different character
	set searchFrom $pos
	set start [lindex [search -s -n -f 0 -r 1 $breakPat $searchFrom] 0]
	if { $start == "" } {
	    set start [minPos]
	} else {
	    set start [pos::nextLineStart $start]
	}
	if { [pos::compare $searchFrom < $start] } {
	    set searchFrom $start
	}
	set end [lindex [search -s -n -f 1 -r 1 $breakPat $searchFrom] 0]
	if { $end == "" } {
	    set end [maxPos]
	}
    } else { 
	# We are not in a comment

	# If we're on an empty line, do nothing:
	# <LABEL:emptyline>
	if { [string trim [getText $pos1 $pos2]] == "" } {
	    return $pos1 ;# linestart
	}
	set start [paragraph::start $pos] 
	if { [pos::compare $start > $pos] } {
	    set end [paragraph::finish $start]
	} else {
	    set end [paragraph::finish $pos]
	}
    }
    
    # Now we have computed $start and $end of the current paragraph.
    # Check if they are within eventual specified limits, and adjust
    # accordingly:
    if { $minstart != "" } {
	if { [pos::compare $minstart > $start] } {
	    set start $minstart
	}
    }
    if { $maxend != "" } {
	if { [pos::compare $maxend < $end] } {
	    set end $maxend
	    # This may cause $start >= $end, and hence $pos < $start...
	}
    }
    
    if { [pos::compare $pos < $start] } {
	# $pos is on a commented empty line.  (Remark: the uncommented
	# case was caught at <LABEL:emptyline> above.)  One particularly
	# important case of this is when filling multiple paragraphs:
	# then every commented empty line will be sent to [paragraph::fillOne]
	# with minstart and maxend as limits...  In any case:
	# Just return --- the only pitfall is that the return value should be
	# an earlier position, to avoid infinite loops in [paragraph::fill]):
	return [pos::lineStart $pos]
    }
    # In the May2003 version, this check was performed only in the remember
    # case (at the <LABEL:pos<start-oldcheck> below).  In fact it should be
    # performed in any case.  This also renders obsolete the 
    # '$start >= $end' check used in the May2003 version at
    # <LABEL:start>end-oldcheck>.  (In this case already $start > $pos,
    # since $pos < $maxend, by assumption.)
    
    # Cursor position perservation:
    # If "$remember==1", we attempt to preserve cursor position relative to
    # the text, even though the text is flowed.  However if the initial
    # position is in the area of whitespace-and-comment-chars at the
    # beginning of the paragraph, then it is much better to keep the cursor
    # at this exact spot (since by specification of the reflow algorithm,
    # this whitespace-and-comment-char-areas defines the indentation amount
    # for the reflow and hence is not meddled with itself).  This solves
    # a bug reported under Bug 1258.
    # 
    # Determine if we are at paragraph start:
    set pretext [getText $start $pos] ;# we know $start <= $pos.
    if { [info exists chreg] } {
	regsub -- $chreg $pretext "" pretext
    }
    set keepCursorAtPos 0
    # Now for the three cases:
    if { [string is space $pretext] } {
	set keepCursorAtPos 1
    } elseif { $remember } {
	if { [info exists chreg] } {
	    # <LABEL:pos<start-oldcheck> : code previously found here has
	    # been moved up to general case...
	    set memory [rememberWhereYouAre $start $pos $end $chreg]
	} else {
	    set memory [rememberWhereYouAre $start $pos $end]
	}
    } else {
	set pos $start
	# It is neater to indent the paragraph according to first
	# line than according to last...
    }
    # <LABEL:start>end-oldcheck> In the May2003 version there was here
    # a check for the case $start >= $end.  This is no longer needed 
    # since there is now a stronger check $pos < $start, peformed above.

    # End of Part 1.
    
    
#     # Code for debugging Part 1:
#     selectText $start $end
#     alertnote "start=$start, end=$end,  pos=$pos"
#     return
    
    #### Part 2.  Filling.
    #### 
    #### From Part 1 we have got the positions $pos, $start, $end;
    #### the comment strings $ch, $chreg, $chregRubber (if defined, 
    #### otherwise it means we are not in a comment); and the flag 
    #### $remember and the record $memory.
    #### 
    
    global doubleSpaces alpha::platform

    set text [getText $start $end]
    
    if { [info exists chreg] } { 
	set inComment 1
    } else {
	set inComment 0
    }
    if { $inComment } {
	#### We are in a comment ####
	set firstLine [getText $start [pos::nextLineStart $start]]
	if { [set boxComment [regexp -- "(${chreg}+)\[\r\n\]" \
	  $firstLine "" commentSuffix]] } {
	    # We are in a box comment --- throughout there will be special cases
	    # for box comments.
	    set boxWidth [lindex [pos::toRowCol [pos::math [pos::nextLineStart $start] -1]] 1]
	}
	regsub -all -- $chreg $firstLine [string repeat " " [string length $ch]] fr
	regexp -- "^\[ \t\]*" $fr fr
	set left [string length [text::maxSpaceForm $fr]]
	# If the comment only starts part way across a line, we need
	# to add in some extra room for what was before.
	incr left [lindex [pos::toRowCol $start] 1]
	
	if { $boxComment } {
	    set fillCol \
	      [expr {$boxWidth - $left - [string length $commentSuffix] -2}]
	} else {
	    if {$fillCol < "infinite"} {
		set fillCol [expr {$fillCol - $left}]
	    }
	}
	
	if { ![regexp -- "^${chregRubber}" $firstLine front] } {
	    # <C-start> if we didn't find a good $front on this first line;
	    # it might be because it was an opening double-comment, so perhaps we 
	    # should look at the next line before giving up:
	    set tmpPos [pos::nextLineStart $start]
	    set secondLine [getText $tmpPos [pos::nextLineStart $tmpPos]]
	    if { ![regexp -- "^${chregRubber}" $secondLine front] } {
		# That didn't work this time --- too bad 
		if {![dialog::yesno -y "Continue" -n "Stop" \
		  "Sorry, I can't yet reflow the text inside this comment."]} {
		    error "cancel"
		}
		# To avoid infinite loops
		if {[pos::compare $end <= [pos::nextLineStart $start]]} {
		    set start [pos::prevLineStart $start]
		}
		return $start
	    }
	    # It worked this time.  Now see if there is a special opening comment
	    if { [info exists lftchreg] } {
		regexp -- "^\[ \t\]*${lftchreg}+\[ \t\]*" \
		  $firstLine firstLineFront
	    } ; # </C-start>
	    # Check if the last line has a special closing comment
	    if {[info exists rtchreg] && [pos::compare $end != [pos::lineStart $end]]} {
		if {[regexp -- "^\[ \t\]*${rtchreg}+" \
		  [getText $end [pos::lineEnd $end]] lastLineEnd]} {
		    set end [pos::math $end + [string length $lastLineEnd]]
		    append text $lastLineEnd
		}
	    }
	}
	
	if { $boxComment } {
	    regsub -all -- "[quote::Regfind $commentSuffix](\r|\n|$)" \
	      $text "\\1" text
	} 
	# Remove all comment chars (of this level):
	regsub -all -- "(^|\r|\n)${chregRubber}" $text " " text
	
    } else {
	#### We are not in a comment ####
	
	# Get leading whitespace of current line and store length in 'left':
	set front [getLeadingIndent $pos left]
	if {$fillCol < "infinite"} {
	    set fillCol [expr {$fillCol - $left}]
	}
    }
    
    # Fill the text:
    regsub -all -- "\\s+" [string trim $text] " " text
    
    # Turn single spaces at end of sentences into double:
    if { $doubleSpaces } {
	regsub -all -- \
	  {(([^.][a-z]|[^a-zA-Z@]|\\@)[.?!]([])'"]|'')?) } \
	  $text {\1  } text
    }
    
    # Break the lines of the paragraph:
    set text "\r[string trimright [breakIntoLines $text $fillCol 0]]"
    
    # <C-start> special case of firstLineFront:
    if { [info exists firstLineFront] } {
	# Note that the special first-line comment tag has not been removed
	# by the above regsubs, because it has not been found.  (Had it been
	# found we wouldn't have come into the <C-start> case above...) 
	# Also note that this opening comment cannot be alone on a line,
	# because then $start would have been on the next line.
	regsub -- "^ ?\r" $text "" text
	# The inserted space is a dummy.  It will be taken away in the
	# final replacement... </C-start>
	if {![regsub -- "^\[ \t\]*${lftchreg}+\[ \t\]*" $text \
	  " [quote::Regsub $firstLineFront]" text]} {
	    set text " $text"
	}
    }
    
    regsub -all -- " ?\r" $text "\r${front}" text

    if {$inComment} {
	if {$boxComment} {
	    set newtext ""
	    foreach line [split $text "\r\n"] {
		set pad [string repeat " " \
		  [expr {$boxWidth- [string length $line] -1}]]
		lappend newtext "$line$pad$commentSuffix"
	    }
	    set text "\r[join [lrange $newtext 1 end] \r]"
	} else {
	    # No special handling for paragraph comments at present
	}
    }
    
    set text [string range $text 1 end]
    if { ![info exists lastLineEnd] } {
	append text "\r"
    }

    # Don't replace if nothing's changed:
    if { $alpha::platform != "tk" } {
	set changed [expr {$text ne [getText $start $end]}]
    } else {
	set changed  [expr {[string map [list \r \n] $text] ne [getText $start $end]}]
    }
    if { $changed } {
	# workaround an alpha bug
	if { $remember && ($alpha::platform eq "alpha") } {
	    getWinInfo a
	    if { [pos::compare [pos::fromRowCol $a(currline) 0] > $start] } { 
		goto $start 
	    }
	}
	replaceText $start $end $text
	
	# Finally, decide where to put the cursor:
	if { $keepCursorAtPos } {
	    # (This is used when the original cursor position was in
	    # the whitespace-and-comment block at paragraph start.)
	    goto $pos
	} elseif { $remember } {
	    goBackToWhereYouWere $start \
	      [pos::math $start + [string length $text]] $memory
	}
    }
    
    # in case we wish to fill a region
    return $start
}


# Some further remarks <JK, May 2003>: the two blocks of code tagged
# <C-start> treat only the special case of paragraphs double-commented like
# this:
# 
#   /* this or
#    * that */
# 
# The problem is that the prefix must be taken from the second line, but the
# first line should not have this prefix.  If someday a more general approach
# to double-comments is taken, these blocks can go away.





## 
 # -------------------------------------------------------------------------
 # 
 #	"paragraph::start" -- "paragraph::finish"
 # 
 #  "Start": It's pretty clear for non TeX modes how this works.  The
 #  only key is that we start at the beginning of the current line and
 #  look back.  We then have a quick check for whether we found that
 #  very beginning (in which case return it) or if not (in which case we
 #  have found the end of the previous paragraph) we move forward a
 #  line.
 # 
 #  "Finish": The only addition is the need for an additional check for
 #  stuff which explicitly ends lines.
 #	   
 # Results:
 #  The start/finish position of the paragraph containing the given 'pos'
 # 
 # --Version--Author------------------Changes-------------------------------
 #    1.1     <vince@santafe.edu> Cut down on '()' pairs
 #    1.2     Vince - March '96		  Better filling for TeX tables ('hline')
 #    1.3     Johan Linde - May '96   Now sensitive to HTML elements
 #    1.4     <vince@santafe.edu> Handle Tcl lists, top of file fix.
 #    1.5     <JK, May 2003> Top of file bug fix workaround, cf. Bug 590
 # -------------------------------------------------------------------------
 ##
proc paragraph::start {args} {
    win::parseArgs win pos

    set startPara [win::getModeVar $win startPara {^([ \t]*|([\\%][^\r\n]*))$}]
    
    if {[pos::compare -w $win $pos == [maxPos -w $win]]} {
	set pos [pos::math -w $win $pos - 1]
    }
    set pos [pos::lineStart -w $win $pos]
    set res [search -w $win -s -n -f 0 -r 1 -l [minPos -w $win] \
      -- "$startPara" $pos]
    if {![llength $res] || $res == "0 0" || [lindex $res 0] == "-1"} {
	# bug work-around.  Alpha fails to match '^' with start of file.
	set pp [search -w $win -s -f 1 -r 1 "\[^ \t\r\n\]" [minPos]]
	if {[llength $pp]} {
	    return [pos::lineStart -w $win [lindex $pp 0]]
	} else {
	    return [minPos]
	}
    } elseif {[pos::compare -w $win [lindex $res 0] == $pos]} {
	return $pos
    } else {
	return [pos::nextLineStart -w $win [lindex $res 0]]
    }
	
}

proc paragraph::finish {args} {
    win::parseArgs win pos

    set pos [pos::lineStart -w $win $pos]
    set end [maxPos -w $win]
    
    set mode [win::getMode $win]
    set endPara [win::getModeVar $win endPara {^([ \t]*|([\\%][^\r\n]*))$}]
    
    set res [search -w $win -s -n -f 1 -r 1 -l $end -- "$endPara" $pos]
    if {![string length $res]} {return $end}
    set cpos [pos::lineStart -w $win [lindex $res 0]]
    if {[pos::compare -w $win $cpos == $pos]} {
	return [pos::nextLineStart -w $win $cpos]
    }
    # A line which ends in '\\', '%...', '\hline', '\hhline'
    # signifies the end of the current paragraph in TeX mode
    # (the above checked for beginning of the next paragraph).
    if { $mode == "TeX" || $mode == "Bib" } {
	if {$::alpha::platform == "tk"} {
	    # Workaround a bug in Tcl's regexp engine by doing
	    # two separate searches here:
	    set pat1 {\B(\B|h+line)[ \t]*$}
	    set pat2 {[^\B]%}
	    set res21 [search -w $win -s -n -f 1 -r 1 -l $end $pat1 $pos]
	    set res22 [search -w $win -s -n -f 1 -r 1 -l $end $pat2 $pos]
	    if {![llength $res21] && ![llength $res22]} {
		return $cpos
	    } elseif {[llength $res21] && [llength $res22]} {
		set p1 [lindex $res21 0]
		set p2 [lindex $res22 0]
		if {[pos::compare -w $win $p1 < $p2]} {
		    set p $p1
		} else {
		    set p $p2
		}
	    } elseif {[llength $res21]} {
		set p [lindex $res21 0]
	    } else {
		set p [lindex $res22 0]
	    }
	    if {[pos::compare -w $win $p < $cpos] } {
		return [pos::nextLineStart -w $win $p]
	    }
	} else {
	    set pat {((\\\\|\\h+line)[ \t]*|[^\\]%[^\r\n]*)$}
	    set res2 [search -w $win -s -n -f 1 -r 1 -l $end $pat $pos]
	    if {[llength $res2]} {
		if {[pos::compare -w $win [lindex $res2 0] < $cpos] } {
		    return [pos::nextLineStart -w $win [lindex $res2 0]]
		}
	    }
	}
    }
    return $cpos
}

## 
 #	   
 # 'paragraph::rememberWhereYouAre'
 # 
 #  Given start and end positions of a paragraph and and in-between position
 #  to remember (the cursor position), the proc 'rememberWhereYouAre'
 #  returns a record which can later be passed to the proc
 #  'goBackToWhereYouWere', in order to find the spot again, even after the
 #  paragraph has been reflowed.  The optional last argument is a collection
 #  of other characters (quoted so they are regexp insensitive), which
 #  should also be ignored when trying to locate the string again.  These
 #  are typically comment chars (which will also be reflowed under
 #  fill-paragraph operations), but in principle it could be other chars as
 #  well.  The record is a two-element list:  entry-0 is the pattern,
 #  and entry-1 indicates whether the pattern was found before $pos (indicator 1)
 #  or after $pos (indicator 0).
 #	   
 # 'paragraph::goBackToWhereYouWere'
 # 
 #  Given start and end positions of a selection, and a previous record
 #  (result of a call to 'rememberWhereYouAre'), this procedure will move
 #  the insertion point to the correct place, relative to the text even if
 #  it has been reflowed.
 #  
 #  <JK:Dec2003>: revised for fixing Bug 1273; more explanations,
 #  and hopefully more readable...
 #  
 ##
 
 
####  This proc assumes   $startPara <= $pos <= $endPara   ####  
proc paragraph::rememberWhereYouAre {startPara pos endPara {commentReg ""}} {
    # First try to collect a pattern before $pos:
    set start [pos::math $pos -20]
    if { [pos::compare $start < $startPara] } {
	set start $startPara
    }
    set pat [getText $start $pos]
    set dir 1
    # Is the pattern sufficiently informative?:
    if { [string length [string trim $pat]] < 3 } {
	# Not enough.  Try instead to collect a pattern after $pos:
	set end [pos::math $pos +20]
	if { [pos::compare $end > $endPara] } {
	    set end $endPara
	}
	set pat [getText $pos $end]
	set dir 0
    }
    # We do need to quote the pattern $pat, because we are
    # eventually going to use it as search string...  We are also
    # going to make a delicate replacement, sticking in \s: all 
    # whitespace-and-comment-char blocks must be replaced with the 
    # corresponding rubber regular expression.  Since we don't want 
    # to quote \s we need to quote $pat first.  But if we first quote, 
    # then the \s replacement will be difficult due to quoted comment 
    # chars (e.g. * in C mode).  (This was Bug 1273.)  The solution 
    # is to do the two-step operation in three steps:
    # First replace comment chars by whitespace:
    if { [string length $commentReg] } {
	regsub -all -- "\[${commentReg}\]" $pat " " pat
    }
    # Then quote:
    set pat [quote::Regfind $pat]
    # Now the replacement is easy:
    regsub -all -- {\s+} $pat "\[\\s${commentReg}\]+" pat
    return [list $pat $dir]
}

proc paragraph::goBackToWhereYouWere { start end memory } {
    set pat [lindex $memory 0]
    set dir [lindex $memory 1]
    if { $pat == "" } {
	# Fallback behaviour if an empty pattern was given:
	goto $start
	return
    }
    # Look for the pattern in the text:  
    # (Note that the first wildcard must be non-greedy, to ensure 
    # that the first submatch is returned, not the last...)
    regexp -indices ".*?($pat).*" [getText $start $end] "" submatch
    if { [info exists submatch] } {
	set p [pos::math $start + $dir + [lindex $submatch $dir]]
    } else {
	# Fallback behaviour if we could not find the right spot:
	set p $end
    }
    if { [pos::compare $p >= $end] } {
	# The -1 here is another convention...?:
	goto [pos::math $end - 1]
    } else {
	goto $p
    }
}

## 
 # -------------------------------------------------------------------------
 #	 
 #	"getLeadingIndent" --
 #	
 #  Find the indentation of the line containing 'pos', and convert it to a
 #  minimal form of tabs followed by spaces.  If 'size' is given, then the
 #  variable of that name is set to the length of the indent.  Similarly
 #  'halftab' can be set to half a tab. 
 # -------------------------------------------------------------------------
 ##
proc paragraph::getLeadingIndent { pos {size ""} {halftab ""} } {
    # get the leading whitespace of the current line
    set res [search -s -n -f 1 -r 1 "^\[ \t\]*" [lineStart $pos]]
    set front [eval getText $res]

    getWinInfo a
    set sp [string repeat " " $a(tabsize)]

    # convert it to minimal form (if appropriate):
    if {![text::indentUsingSpacesOnly]} {
	regsub -all "($sp| +\t)" $front "\t" front
    }
    
    if { $size != "" } {
	upvar $size ind
	# get the length of the indent
	regsub -all "\t" $front $sp lfront
	set ind [string length $lfront]
    }
    if { $halftab != "" } {
	upvar $halftab ht
	# get the length of half a tab
	set ht [string repeat " " [expr {$a(tabsize)/2}]]
    }
    
    return $front
}
 

proc paragraph::select {args} {
    
    requireOpenWindow
    win::parseArgs w
    set pos [getPos -w $w]
    set start [paragraph::start -w $w $pos] 
    set finish [paragraph::finish -w $w $pos]
    goto -w $w $start
    selectText -w $w $start $finish
}

proc paragraph::sentence {} {
    if {![win::checkIfWinToEdit]} {return}
    set pos [getPos]
    set start [paragraph::start $pos] 
    set finish [paragraph::finish $pos]
    
    set t [string trim [getText $start $finish]]
    set period [regexp -- {\.$} $t]
    regsub -all -- "\[ \t\r\n\]+" $t " " text
    regsub -all -- {\. } $text "Æ" text
    set result ""
    foreach line [split [string trimright $text {.}] "Æ"] {
	if {[string length $line]} {
	    append result [breakIntoLines $line] ".\r"
	}
    }
    if {!$period && [regexp -- {\.\r} $result]} {
	set result [string trimright $result ".\r"]
	append result "\r"
    }
    if {$result ne [getText $start $finish]} {
	replaceText $start $finish $result
    }
    goto $pos
}

# ×××× Paragraph Navigation ×××× #
# 
# While these next procs are intended for true 'text' files, they can also
# be used for programming modes where it makes more sense to navigate blocks
# of commands (as delineated by empty lines) rather than by indentation, as
# in Fortran files.
# 
# Contributed by Craig Barton Upright.
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "paragraph::next" --
 # 
 # Advance the cursor to the start of the next paragraph.  "quietly" will
 # simply return the position of the start of the previous paragraph. 
 # "insertTo" determines where to move the current insertion point --
 #  
 # 0  don't do anything
 # 1  move the insertion point to the top of the buffer
 # 2  move the insertion point to the middle of the buffer
 #  
 # If there is a selection already highlighted, "insertTo" is ignored, and
 # the selection is extended to the either the END of the current paragraph
 # (if the selection is not there already) or to the END of the next
 # paragraph.
 # 
 # -------------------------------------------------------------------------
 ##

proc paragraph::next {args} {
    
    requireOpenWindow
    win::parseArgs w {quietly 0} {insertTo 0}
    set what [win::getModeVar $w paragraphName "paragraph"]
    
    set pat  {[\r\n]+[\r\n\t ]*[\r\n]+[^\r\n]}
    set pos0 [getPos -w $w]
    if {[pos::compare -w $w [selEnd -w $w] == [maxPos -w $w]]} {
	set pos1 [maxPos -w $w]
    } elseif {[isSelection -w $w]} {
	set pos1 [pos::math -w $w [selEnd -w $w] + 1]
    } else {
	set pos1 [getPos -w $w]
    } 
    
    if {![catch {search -w $w -s -f 1 -r 1 $pat $pos1} match]} {
	set pos2 [pos::lineStart -w $w [lindex $match 1]]
	if {[pos::compare -w $w $pos1 >= $pos2]} {
	    set pos2 [paragraph::finish -w $w [lindex $match 1]]
	}
    } else {
	set match [list [set pos2 [maxPos -w $w]] $pos2]
    }
    if {$quietly} {
	return $pos2
    } elseif {[isSelection -w $w]} {
	set pos3 [pos::nextLineStart -w $w [lindex $match 0]]
	if {[pos::compare -w $w $pos1 >= $pos3]} {
	    set pos3 [maxPos -w $w]
	} 
	selectText -w $w $pos0 $pos3
    } else {
	goto -w $w $pos2
    }
    if {($insertTo == 1)} {
	insertToTop -w $w
    } elseif {($insertTo == 2)} {
	centerRedraw -w $w
    } 
    if {[pos::compare -w $w $pos2 == [maxPos -w $w]]} {
	status::msg "No further ${what}s in the file."
    } elseif {[isSelection -w $w]} {
	status::msg "Next ${what}:\
	  [getText -w $w $pos2 [pos::nextLineStart -w $w $pos2]]"
    } else {
	status::msg [getText -w $w $pos2 [pos::nextLineStart -w $w $pos2]]
    } 
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "paragraph::prev" --
 # 
 # Back up the cursor to the start of the previous paragraph.  If the cursor
 # is currently in a paragraph, move to the start if the current one. 
 # "quietly" will simply return the position of the start of the' previous
 # paragraph.  "insertTo" determines where to move the current insertion
 # point --
 #  
 # 0  don't do anything
 # 1  move the insertion point to the top of the buffer
 # 2  move the insertion point to the middle of the buffer
 #          
 # If there is a selection already highlighted, "insertTo" is ignored, and
 # the selection is extended to the either the beginning of the current
 # paragraph (if the selection is not there already) or to the beginning of
 # the previous paragraph.
 # 
 # --------------------------------------------------------------------------
 ##

proc paragraph::prev {args} {
    
    requireOpenWindow
    win::parseArgs w {quietly 0} {insertTo 0}
    set what [win::getModeVar $w paragraphName "paragraph"]
    
    set pat {[^\r\n\t ]+[^\r\n]+[\r\n]+[\r\n\t ]*[\r\n]+[^\r\n]}
    set pos0 [selEnd {quietly 0} {insertTo 0}]
    if {[pos::compare -w $w [getPos -w $w] == [minPos -w $w]]} {
	set pos1 [minPos -w $w]
    } else {
	set pos1 [pos::math -w $w [getPos -w $w] - 1]
    } 
    if {![catch {search -w $w -s -f 0 -r 1 $pat $pos1} match]} {
	set pos2 [pos::lineStart -w $w [lindex $match 1]]
	if {[pos::compare -w $w [getPos -w $w] <= $pos2]} {
	    set pos2 [paragraph::start -w $w [lindex $match 0]]
	}
    } else {
	set pos2 [minPos -w $w]
    }
    if {$quietly} {
	return $pos2
    } elseif {[isSelection -w $w]} {
	selectText -w $w $pos2 $pos0
    } else {
	goto -w $w $pos2
    }
    if {($insertTo == 1)} {
	insertToTop -w $w
    } elseif {($insertTo == 2)} {
	centerRedraw -w $w
    } 
    if {[pos::compare -w $w $pos2 == [minPos -w $w]]} {
	status::msg "No further ${what}s in the file."
    } else {
	status::msg [getText -w $w $pos2 [pos::nextLineStart -w $w $pos2]]
    } 
}

## 
 # --------------------------------------------------------------------------
 # 
 # "paragraph::reformat" --
 # 
 # This is NOT the same as paragraph::fill.  Instead, this procedure will
 # align the indentation of every line contained in the paragraph, so
 # something like this:
 #  
 # If there's a selection, then fill 
 #           all paragraphs in that selection.
 #           If not then fill the paragraph surrounding the insertion point.
 #  The definition of a 'paragraph' may be mode dependent 
 #                                      (see paraStart, paraFinish)
 #  
 #  will end up like this:
 #  
 # If there's a selection, then fill 
 # all paragraphs in that selection.
 # If not then fill the paragraph surrounding the insertion point.
 # The definition of a 'paragraph' may be mode dependent 
 # (see paraStart, paraFinish)
 #  
 # Following reformatting, the cursor is placed at the start of the next
 # paragraph.
 # 
 # -------------------------------------------------------------------------- 
 ##

proc paragraph::reformat {args} {
    
    requireOpenWindow
    win::parseArgs w
    if {![isSelection -w $w]} {
	paragraph::select -w $w
    }
    
    status::msg "Reformatting É"
    ::indentRegion -w $w
    goto -w $w [pos::math -w $w [getPos -w $w] -1]
    goto -w $w [paragraph::prev -w $w 1 0]
    goto -w $w [paragraph::next -w $w 1 0]
    status::msg "Reformatted."
    return
}

#¥ breakIntoLines <string> ?rightCol? ?leftCol? - return 'string' with 
#  carriage returns and spaces inserted to satisfy 
#  'leftFillColumn' and 'fillColumn' variables, or the
#  two arguments which have been given.
#  
#  If no rightCol is given and the fillColumn variable doesn't exist,
#  then an infinite fillColumn is assumed.
#  
#  Implementation taken from Alphatk.
proc breakIntoLines {t {rightCol ""} {leftCol ""}} {
    if {$leftCol == ""} {
	set leftCol [win::getModeVar [win::Current] leftFillColumn 0]
    }
    if {$rightCol == ""} {
	set rightCol [win::getModeVar [win::Current] fillColumn "infinite"]
    }
    # If we don't have a right column, it is considered infinite
    if {$rightCol < "infinite"} {
	set rightCol [expr {$rightCol - $leftCol}]
    }
    if {$t == ""} { return $t }
    set t [string map [list "\n" "\r"] $t]
    #regsub -all "  +" $t " " t
    append t " "
    while 1 {
	if {$t == ""} {
	    break
	}
	set first [string first "\r" $t]
	if {$first != -1 && ($first < $rightCol)} {
	    append res [string trimleft [string range $t 0 $first]]
	    set t [string range $t [expr {$first +1}] end]
	    # Make sure we add on any blank lines.
	    if {[regexp -- {^\r+} $t blanklines]} {
		append res $blanklines
		set t [string trimleft $t]
	    }
	    continue
	}
	if {$rightCol == "infinite"} {
	    append res [string trimleft $t] "\r"
	    break
	}
	set a [string range $t 0 $rightCol]
	set where [string last " " $a]
	if {$where == -1} {
	    set where [string first " " $t]
	    if {$where == -1} {
		set a $t
		set t ""
	    } else {
		set a [string range $t 0 [expr {$where -1}]]
		set t [string trimleft \
		  [string range $t [expr {$where +1}] end] " "]
	    }
	} else {
	    set t [string trimleft \
	      [string range $t [expr {$where +1}] end] " "]
	    set a [string range $a 0 [expr {$where -1}]]
	}
	append res [string trimleft $a] "\r"
    }
    regsub -all "(^|\r)" $res "&[string repeat " " $leftCol]" res
    return [string trimright $res]
}

# ===========================================================================
# 
# .