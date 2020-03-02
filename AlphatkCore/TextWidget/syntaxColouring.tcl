## -*-Tcl-*-
 # ###################################################################
 #  Alphatk - the editor
 # 
 #  FILE: "syntaxColouring.tcl"
 #                                    created: 04/12/98 {22:45:38 PM} 
 #                                last update: 03/29/2006 {10:53:26 PM}
 #  Author: Vince Darley
 #  E-mail: vince.darley@kagi.com
 #    mail: Flat 10, 98 Gloucester Terrace, London W2 6HP
 #     www: http://www.purl.org/net/alphatk
 #  
 # Copyright (c) 1998-2005  Vince Darley
 # 
 # See the file "license.terms" for information on use and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # In particular, while this is 'open source', it is NOT free, and
 # cannot be copied in full or in part except according to the terms
 # of the license agreement.
 # 
 # ###################################################################
 ##

namespace eval tw {}


## 
 # -------------------------------------------------------------------------
 # 
 # "tw::Color" --
 # 
 #  Used to define colouring information to the enhanced text widget.
 #  Repeated calls to this command are used to build up the description
 #  of how to perform syntax colouring in the given cmode.
 #  
 #  The necessary, or possible, calls are as follows:
 #  
 #  Arrange to have a special word 'foo' coloured with $color wherever
 #  it appears in the text (unless quoted or commented out):
 #  
 #    tw::Color $cmode [list set keywords(foo) $color]
 #  
 #  Remove all previous known keywords (this is an array):
 #  
 #    tw::Color $cmode "unset keywords"
 #  
 #  Set colours for particular textual elements.  Acceptable values
 #  for '$element' are 'comment' or 'quote'.
 #  
 #    tw::Color $cmode "set specialColors($element) $color"
 #  
 #  Set the characters to be used for 'begin/end' comment pairs:
 #  
 #    tw::Color $cmode "set multiComment [list /* */]"
 #    
 #  Set a 'magic' prefix.  Any word beginning with this prefix
 #  will be coloured with the magic colour (e.g. colour all words
 #  starting with a dollar sign specially):
 #  
 #    tw::Color $cmode "set magicPrefix \$"
 #    tw::Color $cmode "set magicColor $color"
 #  
 #  Colour any other individual characters specially:
 #  
 #    tw::Color $cmode "set specialChars($char) $color"
 #    
 #  Lastly, two very important variables must be set:
 #  
 #    tw::Color $cmode [list set lineRegexp $regexp]
 #    tw::Color $cmode [list set lineVars $varList]
 #    
 #  Once all these variables have been set up, you must call
 #  'tw::SetUpColoring $cmode' which creates the necessary 
 #  procedures.  Currently the only supported user of this code
 #  is the 'regModeKeywords' procedure in alpha_colouring.
 #  
 #  Now, these two variables are created as follows:
 #  
 #  lineVars         lineRegexp
 #  --------         ----------
 #                   "^\[ \t\]*"
 #  comment          "\(?:\(" [quote::Regfind $comment] "\).*\)?"
 #  multicomment     "(?:([quote::Regfind [lindex $multicomment 0]]).*)?"
 #  quote            "((?!\\B)\"(?:\[^\\B\"\]|\\B.)*(?:\"|\\B?\\Z))?"
 #  txt2              "(.)?"
 #  
 #  The first and last of these 5 entries is obligatory.  The middle
 #  three are individually only necessary if the mode needs to colour
 #  comments, multicomments or quotes.  The 'lineVars' variable is simply
 #  an ordered list of the items on the appropriate subset of the items
 #  in the left column, and the 'lineRegexp' is a concatenation of the
 #  appropriate subset of strings in the right column.
 #  
 # ----------------------------------------------------------------------
 ##
proc tw::Color {cmode script} {
    namespace eval $cmode $script
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tw::arrangeToColourNewlyRevealed" --
 # 
 # This procedure is called whenever the window is scrolled (either
 # with the scrollbar or the '$w see' command), or if text is deleted
 # from or inserted into the current window (since this may result in
 # new lines becoming visible at either or both top/bottom of the
 # window).
 # 
 # Here 'oldtop', 'oldbottom' are the previous line numbers of
 # the first and last lines before the recent changes.  The procedure
 # itself will query '_viewable' to determine the current top and 
 # bottom.  Finally, some text may have been deleted between the
 # indices [lindex $args 0] and [lindex $args 1], if given, and
 # in that case we have to make sure to adjust the relative line
 # numbers in the calculations of what lines are newly visible.
 #  
 # -------------------------------------------------------------------------
 ##
proc tw::arrangeToColourNewlyRevealed {w oldtop oldbottom args} {
    if {![winfo ismapped $w]} {
	# Window should be fully coloured when it is mapped
	return
    }
    
    foreach {top bottom} [_viewable $w] {}
    #puts [list arrange $w $oldtop $oldbottom - $args - $top $bottom]
    if {[llength $args]} {
	set from [expr {int([lindex $args 1])}]
	set to [lindex $args 2]
	if {$to eq ""} {
	    set to [expr {int([$w index insert])}]
	} else {
	    set to [expr {int([$w index $to])}]
	}
	switch -- [lindex $args 0] {
	    "delete" {
		# diff should be negative.
		set diff [expr {$from - $to}]
		lappend range $from $from
	    }
	    "insert" {
		# Text added
		set diff [expr {$to - $from}]
		if {$to >= $top && $from <= $bottom} {
		    # Colour entire range, provided some of it is onscreen
		    lappend range $from $to
		}
	    }
	    "replace" {
		set rep_to \
		  [expr {int([$w index "[lindex $args 1] + [lindex $args 3]c"])}]
		if {$to > $top && $from < $bottom} {
		    # Colour entire range, provided some of it is onscreen
		    lappend range $from $rep_to
		}
		set diff [expr {abs($from - $rep_to) - abs($from - $to)}]
		# Fake up 'to' to look like the actual difference
		if {$diff > 0} {
		    # Did an effective delete
		    set to [expr {$from - $diff}]
		} else {
		    # Did an effective insert
		    set to [expr {$from + $diff}]
		}
	    }
	}
	if {$diff == 0} {
	    #lappend range $from $from
	} else {
	    if {$to < $oldtop} {
		incr oldtop $diff 
		incr oldbottom $diff
	    } elseif {$from > $oldbottom} {
		# do nothing
	    } elseif {$from >= $oldtop && $to <= $oldbottom} {
		incr oldbottom $diff
	    } elseif {$from < $oldtop} {
		# deleted range overlaps top of window
		incr oldbottom $diff
		set oldtop $from
	    } else {
		# deleted range overlaps bottom of window
		set oldbottom $from
	    }
	}
    }
    
    #puts [list $oldtop $oldbottom $top $bottom]
    if {$top < $oldtop} {
	# Some new text has appeared at the top
	if {$bottom < $oldtop} {
	    lappend range $top $bottom
	} else {
	    lappend range $top $oldtop
	}
    }
    if {$bottom > $oldbottom} {
	# Some new text has appeared at the bottom
	if {$top > $oldbottom} {
	    lappend range $top $bottom
	} else {
	    lappend range $oldbottom $bottom
	}
    }
    if {[info exists range]} {
	#puts "color $range"
	eval [list arrangeToColour $w] $range
    }
}

proc tw::_arrangeToColorIfVisible {w from to} {
    #puts [list $w $from $to]
    # We must strip off any leading
    regsub ":+tw:+" $w "" w
    foreach {top bottom} [_viewable $w] {}
    set from [expr {int([$w index $from])}]
    set to [expr {int([$w index $to])}]
    if {$from < $top} { set from $top }
    if {$to > $bottom} { set to $bottom }
    if {$from < $to} {
	arrangeToColour $w $from $to
    }
}

proc tw::arrangeToColour {w args} {
    #puts stderr "Perhaps colour $w $args"
    if {!$::alphatk::coloring} {return}
    variable $w
    if {![info exists ${w}(colouring)]} {
	set ${w}(colouring) $args
	after idle [list tw::colourSoon $w]
    } else {
	eval [list lappend ${w}(colouring)] $args
    }
}

# The problem with these 'tkwait's is that they can lock
# up other code that issues, say, an 'update idletasks'
# (which triggers a tw::colourSoon which locks in tkwait).
if {[tk windowingsystem] eq "aqua"} {
    proc tw::colourSoon {w} {
	if {![winfo exists $w]} { 
	    variable $w
	    if {[info exists ${w}(colouring)]} {
		unset ${w}(colouring)
	    }
	    return 
	}
	if {![winfo viewable $w]} {
	    # Ensure this is unset - we're going to colour everything
	    variable $w
	    unset -nocomplain ${w}(colouring)
	    bind [winfo toplevel $w] <Map> \
	      "[list ::tw::arrangeToColour $w {} {}] ;\
	      [list bind [winfo toplevel $w] <Map> {}]"
	    if {[catch {tkwait visibility $w}]} {
		# Window destroyed before it became visible
		return
	    }
	}
	after 1 [list tw::colourWinFraction $w]
    }
} else {
    proc tw::colourSoon {w} {
	if {![winfo exists $w]} { 
	    variable $w
	    if {[info exists ${w}(colouring)]} {
		unset ${w}(colouring)
	    }
	    return 
	}
	if {![winfo viewable $w]} {
	    # Ensure this is unset - we're going to colour everything
	    variable $w
	    unset -nocomplain ${w}(colouring)
	    bind [winfo toplevel $w] <Map> \
	      "[list ::tw::arrangeToColour $w {} {}] ;\
	      [list bind [winfo toplevel $w] <Map> {}]"
	    return
	    if {[catch {tkwait visibility $w}]} {
		# Window destroyed before it became visible
		return
	    }
	}
	after idle [list tw::colourWinFraction $w]
    }
}

if {0} {
    time {
	set ::tw::.al1.text1(colouring) [list {} {}]
	tw::colourWinFraction .al1.text1
    } 20
    # 60ms, 58ms, 114ms, 216ms for 1st four pages of Optimizer
    # 1.4s to mark the file
}

proc tw::colourWinFraction {w} {
    variable $w

    if {[info exists ${w}(colouring)]} {
	set args [set ${w}(colouring)]
	unset ${w}(colouring)
    } else {
	# Window probably destroyed.
	return
    }
    if {[catch {GetColorTags $w} cmlist]} {
	# Probably opening a window very early, or someone is sending
	# us events rather sooner than expected.
	#after idle [list after idle [concat [list tw::arrangeToColour $w] $args]]
	return
    }
    
    # Pick the first color mode which has anything defined
    foreach cm $cmlist {
	# No hierarchical namespace lookup, so modes which don't define any
	# colouring at all will throw an error unless we either divert them
	# to the generic tw::colourLine, or simply return
	if {[llength [info commands ${cm}::colourLine]]} {
	    set m $cm
	    break
	}
    }
    if {![info exists m]} {
	# None of the color modes had anything useful
	return
    }
    
    # No hierarchical namespace lookup, so modes which don't define any
    # colouring at all will throw an error unless we either divert them
    # to the generic tw::colourLine, or simply return
    if {![llength [info commands ${m}::colourLine]]} {
	return
	#set m ::tw
    }
    
    #puts [list colourWinFraction $w $m $args]

    set w_st [expr {int([$w index @0,0])}]
    set w_end [expr {int([$w index "@[winfo width $w],[winfo height $w]"])}]
    set ranges {}

    foreach {st end} $args {
	#puts stderr "Colouring $w in range $st $end"
	if {![string length $st] && ![string length $end]} {
	    set st $w_st
	    set end $w_end
	    #puts stderr "Colouring $w in range $st $end"
	} else {
	    # Checking whether some is off screen
	    if {$end < $w_st} {
		continue
	    }
	    if {$w_st > $st} {set st $w_st}
	    if {$w_end < $end} {set end $w_end}
	}
	lappend ranges [list $st $end]
    }
    #puts stderr "Colouring in ranges $ranges"
    set winname $::win::tktitle([base_window $w])
    
    foreach pair [lsort -index 0 $ranges] {
	foreach {st end} $pair {}
	if {$st == $end} {
	    set index ${st}.0
	    # Just want to colour one line.  The tricky case here
	    # is if the user is editing inside a multi-line comment
	    if {[$w compare "insert linestart" == $index]} {
		if {[::text::isInDoubleComment -w $winname insert dblStart]} {
		    if {[info exists ::tw::${m}::specialColors(comment)]} {
			$w tag add [set ::tw::${m}::specialColors(comment)] \
			  [lindex $dblStart 0] insert
		    }
		    continue
		}
	    } else {
		if {[::text::isInDoubleComment -w $winname $index dblStart]} {
		    if {[info exists ::tw::${m}::specialColors(comment)]} {
			$w tag add [set ::tw::${m}::specialColors(comment)] \
			  [lindex $dblStart 0] "$index lineend"
		    }
		    continue
		}
	    }
	    namespace eval $m [list colourLine ::tw::$w "${st}.0"]
	} else {
	    set pos_end [tw::index $w ${end}.0]
	    set pos_start ${st}.0
	    #puts stderr "Colouring $w in $m in range $st $end"
	    while {[$w compare $pos_start <= $pos_end]} {
		set pos_start [namespace eval $m \
		  [list colourLine ::tw::$w $pos_start] [lrange $cmlist 1 end]]
		if {[$w compare $pos_start == end]} {break}
	    }
	}
    }
}

proc tw::colourWholeWindow {w} {
    if {[catch {GetColorTags $w} cmlist]} { return }
    
    # Assumption of just one colour mode?
    set m [lindex $cmlist 0]
    
    set pos_start 1.0
    set pos_end [tw::index $w end]
    while {[$w compare $pos_start <= $pos_end]} {
	set pos_start [namespace eval $m \
	  [list colourLine ::tw::$w $pos_start] [lrange $cmlist 1 end]]
	if {[$w compare $pos_start == end]} {break}
    }
}

if {0} {
    proc tw::colourIndexRange {w m from to} {
	while {[$w compare $from < $to]} {
	    # Word 1 - after the current point
	    set ws1 [$w index [backward_word $w $from]]
	    set we1 [$w index [forward_word $w $from]]
	    
	    namespace eval $m [list colourWord $w $ws1 $we1]
	    set from $we1
	}
    }
}

proc tw::colourLine {w {li ""} args} {
    if {$li == ""} { 
	set li [$w index "insert linestart"] 
    }
    return "$li lineend +1c"
}

proc tw::SetUpColoring {m} {
    variable ColourBody
    variable ColourFunction
    variable ColourQuoteBody
    variable ColourMulticommentBody
    variable ColourBeginBody

    set test {}
    if {[lsearch -exact [set ::tw::${m}::lineVars] "comment"] != -1} {
	append test {
	    if {[lindex $comment 1] >= 0} {
		$w tag add $specialColors(comment) $li "$li lineend"
		break
	    }
	}
    }
    if {[info exists ::tw::${m}::multiComment]} {
	append test $ColourMulticommentBody
    }
    if {[info exists ::tw::${m}::quoteVars]} {
	foreach var [set ::tw::${m}::quoteVars] {
	    append test [format $ColourQuoteBody $var $var $var $var]
	}
    }
    if {[info exists ::tw::${m}::specialColors(function)]} {
	append test $ColourFunction
    }
    
    set cleanScript {}
    if {[info exists ::tw::${m}::specialColors(quote)]} {
	append cleanScript {
	    $w tag remove $specialColors(quote) $li $lend
	}
    }
    if {[info exists ::tw::${m}::specialColors(comment)]} {
	append cleanScript {
	    $w tag remove $specialColors(comment) $li $lend
	}
    }
    if {[info exists ::tw::${m}::specialColors(function)]} {
	append cleanScript {
	    $w tag remove $specialColors(function) $li $lend
	}
    }

    set beginScript {}
    if {[info exists ::tw::${m}::beginPat]} {
	foreach var [set ::tw::${m}::beginPat] {
	    append beginScript [format $ColourBeginBody $var]
	}
    }
    
    # These few lines allow us to call this procedure repeatedly,
    # which is useful during development when trying to optimize
    # the main body of the colourLine procedures.
    regsub -- {(\(\.\*\)\$|\(\.\)\?)$} [set ::tw::${m}::lineRegexp] \
      "" ::tw::${m}::lineRegexp
    if {[string range [lindex [set ::tw::${m}::lineVars] end] 0 2] eq "txt"} {
	set ::tw::${m}::lineVars [lreplace [set ::tw::${m}::lineVars] end end]
    }
    
    append ::tw::${m}::lineRegexp "(.)?"
    lappend ::tw::${m}::lineVars txt2
    
    if {[::set ::tw::${m}::nocase]} {
	set case "no_"
    } else {
	set case ""
    }
    
    set body [format $ColourBody $cleanScript $beginScript \
      [set ::tw::${m}::lineVars] $test $case $case]
    
    namespace eval $m [list proc colourLine [list w [list li ""] args] $body]
    return $body
}

set tw::ColourBeginBody {
    if {[regexp -indices -- {%s} $txt got]} {
	set lcur "$li + [lindex $got 0]c"
	set le "$li + [lindex $got 1]c +1c"
	$w tag add $specialColors(comment) $lcur $le
	set txt [string range $txt [expr {[lindex $got 1] +1}] end]
	if {![string length $txt]} {
	    return "$lend +1c"
	}
	set lcur $le
    }
}

# These three large variables are used to construct the body of the
# procedure used for colouring -- 'tw::<cmode>::colourLine'.  This
# construction takes place in the procedure above.  We do this to
# construct a procedure which is as optimised as possible for the mode in
# question, so colouring is as fast as possible.  We get an approximate
# 25% speed-up through this method, for most modes.
# 
# To some extent it also makes the code more readable.


# '%s' will be substituted with the name of the variable which
# contains the start/end of any quoted section found ('quote0' for
# example).  Multiple copies of this body will be used if the mode
# supports multiple quote characters.
set tw::ColourQuoteBody {
    if {[lindex $%s 1] >= 0} {
	set lcur "$li + [lindex $%s 0]c"
	set le "$li + [lindex $%s 1]c +1c"
	set openclose $specialQuotes(%s)
	if {!([$w get "$le -1c"] eq [lindex $openclose 1])} {
	    # We presumably reached the end of the line without
	    # finding a match
	    set endc [$w search -regexp -- [lindex $openclose 2] $le end]
	    if {$endc != ""} {
		# If the insertion point is in the middle of this
		# section, don't colour, otherwise we tend to just
		# colour vast pieces of code when the user types the
		# opening quote!
		if {[$w compare insert < $lcur] \
		  || [$w compare insert > $endc]} {
		    $w tag add $specialColors(quote) $lcur "$endc + 2c"
		    return "$endc lineend +1c"
		}
	    }
	}
	# All quotes are the same colour
	$w tag add $specialColors(quote) $lcur $le
    }
}

set tw::ColourFunction {
    if {[lindex $function 1] >= 0} {
	set func [expr {1 + [lindex $function 1]}]
	set lcur "$li+[lindex $function 0]c"
	$w tag add $specialColors(function) $lcur "$li+${func}c"
    }
}

# This is used if we matched the opening characters of a 'multi-comment'
# - this is a comment which can extend across multiple lines (e.g /* ...
# in C, Java modes)
set tw::ColourMulticommentBody {
    if {[lindex $multicomment 1] >= 0} {
	#puts "multicomment: $multicomment $li"
	set mc [lindex $multiComment 1]
	set lcur "$li+[lindex $multicomment 0]c"
	set endc [$w search -- $mc $lcur end]
	if {$endc != ""} {
	    # If the insertion point is in the middle of this section,
	    # don't colour, otherwise we tend to just colour vast pieces
	    # of code when the user types the opening comment
	    if {1 || [$w compare insert <= $li] \
	      || [$w compare insert > $endc]} {
		set end [$w index "$endc + [string length $mc]c"]
		$w tag add $specialColors(comment) $lcur $end
		set range [$w tag prevrange \
		  $specialColors(comment) "$lcur +1c"]
		if {[llength $range]} {
		    set index1 [lindex $range 1]
		    if {[$w compare $index1 > $end]} {
			$w tag remove $specialColors(comment) "$end" $index1
			if {[$w compare $index1 > "$end lineend"]} {
			    # We have just removed tags from a large
			    # block of text; arrange to recolour it
			    # soon.
			    tw::_arrangeToColorIfVisible $w \
			      "$endc lineend +1c" $index1
			}
		    }
		}
		return "$endc lineend +1c"
	    } else {
		$w tag add $specialColors(comment) $lcur insert
	    }
	}
    }
    if {[lindex $multicommentclose 1] >= 0} {
	#puts "multicommentclose: $multicommentclose $li"
	set mc [lindex $multiComment 0]
	set lcur "$li+[lindex $multicommentclose 1]c +1c"
	set startc [$w search -backwards -- $mc $lcur 1.0]
	if {$startc ne ""} {
	    $w tag add $specialColors(comment) $startc $lcur
	}
    }
}

set tw::ColourBody {
    variable lineRegexp
    variable specialColors
    variable multiComment
    variable specialChars
    variable specialQuotes
    variable keywords
    variable magicPrefix
    variable magicColor

    if {$li == ""} { set li [$w index "insert linestart"] }
    set txt [$w get $li [set lend [$w index "${li} lineend"]]]
    # Cleaning of extraneous tags on the line goes here
    %s
    if {[string length $txt] > 200} {
	set maxlength -180
    }
    # Special matching for the entire line goes here
    %s
    
    set wbreak [::tw::_slowReadVar $w wordbreak]
    while {[regexp -indices -- $lineRegexp $txt "" %s]} {
	#puts [list $comment $multicomment $quote0 $txt2]
	# Tests will go in here
	%s

	#puts "$txt2" ; update ; if {$::stop} { break}
	if {[set idx [lindex $txt2 0]] == -1} {break}
	set firstChar [string index $txt $idx]
	set lcur "$li + ${idx}c"
	#puts [list $firstChar [$w get $lcur $lcur+2c]]

	# This assumes quotes can be escaped, which might not be true of
	# some modes.
	if {$firstChar eq "\\" \
	  && [string index $txt [expr {$idx + 1}]] eq "\""} {
	    set li [$w index "$lcur +2c"]
	    incr idx 2
	} else {
	    if {[info exists specialChars($firstChar)]} {
		set color $specialChars($firstChar)
		$w tag add $color $lcur "$lcur +1c"
		incr idx
	    } else {
		# Use window-specific wordbreak.
		if {[regexp -indices -start $idx \
		  -- $wbreak $txt got] && ([lindex $got 0] == $idx)} {
		    set word [string range $txt $idx [lindex $got 1]]
		    # For case-insensitivity
		    set no_word [::string tolower $word]
		    if {[set len [::string length $word]]} {
			if {[info exists keywords($%sword)]} {
			    $w tag add $keywords($%sword) $lcur "$lcur +${len}c"
			} elseif {[info exists magicPrefix] \
			  && [string index $word 0] eq $magicPrefix} {
			    if {![info exists magicColor]} {
				alertnote "The colour for word prefix\
				  \"$magicPrefix\" appears not to be set.\
				  Please report this bug." 
				set magicColor color1
			    }
			    if {($len == 1) || [regexp \
			      -- $wbreak [string range $word 0 1]]} {
				$w tag add $magicColor \
				  $lcur "$lcur +${len}c"
			    } else {
				$w tag add $magicColor \
				  $lcur "$lcur + 1c"
			    }
			} else {
			    # For multiple colortags
			    foreach ct $args {
                                if {[::set ::tw::${ct}::nocase]} {
                                    if {[info exists ::tw::${ct}::keywords($no_word)]} {
                                        set color [set ::tw::${ct}::keywords($no_word)]
                                        $w tag add $color $lcur "$lcur +${len}c"
                                        break
                                    }
                                } else {
                                    if {[info exists ::tw::${ct}::keywords($word)]} {
                                        set color [set ::tw::${ct}::keywords($word)]
                                        $w tag add $color $lcur "$lcur +${len}c"
                                        break
                                    }
                                }
			    }
			}
			incr idx $len
		    }
		} else {
		    incr idx
		}
	    }
	}
	set txt [string range $txt $idx end]
	set li [$w index "$li +${idx}c"]
	#puts "now: '$txt'"
	if {[info exists maxlength]} {
	    if {[incr maxlength $idx] >= 0} {
		# Don't continue colouring very long lines!
		return "$li lineend +1c"
	    }
	}
    }
    return "$lend +1c"
}
