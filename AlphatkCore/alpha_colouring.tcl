## -*-Tcl-*-
 # ###################################################################
 #  Alphatk - the editor
 # 
 #  FILE: "alpha_colouring.tcl"
 #                                    created: 04/12/98 {22:45:38 PM} 
 #                                last update: 2006-03-15 15:46:25 
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

set tw::colorList [list blue cyan green magenta red white yellow]

# Don't remove marks or selection when recolouring.
set tw::nonColorMarkRegexp {^(mark:|(back)?sel$)}

proc colorIndex {color} {
    if {[string range $color 0 5] == "color_"} {
	regsub "color_" $color "" colorIndex
    } else {
	set colorIndex [lsearch -exact $::tw::colorList $color]
	incr colorIndex
    }
    return $colorIndex
}

#¥ colorTagKeywords [options] <colortag> <keyword list> - Set keywords 
#  to color for the given tag.
#  
#  Valid options:
#  
#    -a			Keywords will be *added* to existing cmode
#    			keywords.  The new keywords can be a different
#    			color than older keywords.
#    -k <color>		Keyword color.
#    -C                 All keywords for this colortag are
#                       case-sensitive.
#    
#  No other options are allowed.  This command may be evaluated 
#  repeatedly for a given colortag, to declare multiple sets of
#  color+keywords.  However the '-C' flag applies to all keywords
#  with all colours, and need therefore only be given once -- it
#  should be given (or not, if undesired) the first time that 
#  colorTagKeywords is called for the given colortag.  So a typical
#  usage will be:
#  
#  colorTagKeywords -C foo {}
#  colorTagKeywords -a -k blue foo {list of keywords}
#  colorTagKeywords -a -k magenta foo {list of keywords}
#  ...
proc colorTagKeywords {args} {
    getOpts {-k}
    if {[llength $args] != 2} {
	return -code error "Bad argument list $args"
    }
    set colortag [lindex $args 0]
    set keywords [lindex $args 1]
    if {[info exists opts(-k)]} {
	set color $opts(-k)
    } else {
	set color blue
    }
    if {![info exists opts(-a)]} {
	tw::Color $colortag [list unset -nocomplain keywords]
    }
    if {![tw::Color $colortag [list info exists nocase]]} {
        if {[info exists opts(-C)]} {
            tw::Color $colortag [list set nocase 0]
        } else {
            tw::Color $colortag [list set nocase 1]
        }
    }
    set nocase [tw::Color $colortag [list set nocase]]
    
    set keywordColor [colorIndex $color]
    if {$keywordColor == 0} {
	foreach kw $keywords {
	    if {$nocase} { set kw [string tolower $kw] }
	    tw::Color $colortag [list unset -nocomplain keywords($kw)]
	}
    } else {
	foreach kw $keywords {
	    if {$nocase} { set kw [string tolower $kw] }
	    tw::Color $colortag [list set keywords($kw) color$keywordColor]
	}
    }
    win::_scheduleRecolouring $colortag
    return
}

#¥ regModeKeywords [options] <cmode> <keyword list> - Set keywords and comments 
#  that Alpha can recognize to color them.  Specifically, in
#  colouring-mode <cmode>, every keyword specified in the list is
#  colored non-black (blue, by default).  Comments, if specified by '-e'
#  or '-b' below, are colored red by defualt.
#  
#    -a			Keywords will be *added* to existing cmode
#    			keywords.  The new keywords can be a different
#    			color than older keywords.  This flag can also
#    			be used to modify other attributes, but it
#    			cannot be used to modify colors of existing
#    			keywords.
#    				
#    -m <c>		Specify a magic character. Every word beginning with 
#                       the magic character is a keyword.
#    -e <commentstr>	Specify a string that begins comments that last to 
#			the end of the line. 
#    -b <comment beg> <comment end>	
#                       Specify a pair of strings that bracket a 
#			comment.
#    -c <color>		Comment color.
#    -f <color>         'Function' color, which will color any word preceding '('
#    -k <color>		Keyword color.
#    -s <color>		String color. Alpha can color single-line
#			strings only, using the simple heuristic
#			of assuming the first two double quotes
#			constitute a string. 
#    -q <open-q> <close-q> Set an open/close quote pair.  The open
#                       and quote pair can be different.  This argument
#                       can be given multiple times.  If it isn't given,
#                       then the double-quote characters "" are assumed
#                       to be used for quotes (if -s is given).  To colour
#                       different characters and "" you must explicitly give
#                       both, for example: -q ' ' -q \" \" 
#    -i <char>		Specify a character to display differently.
#			Commonly used for curly braces, etc.
#    -I <color>		Color of above characters.
#	Keywords must be less than 20 characters long.
proc regModeKeywords {args} {
    getOpts {-m -e -begin {-b 2} -c -f -k -s -i -I {-q 2}} "lappend"
    set cmode [lindex $args 0]
    
    global alpha::regModeOptionMemory
    
    # spaces, starting the lineRegexp/lineVars vars
    append lineRegexp "^\[ \t\]*"
    set lineVars {}
    
    # -a option: adding additional colors
    if {![info exists opts(-a)]} {
	tw::Color $cmode [list unset -nocomplain keywords]
    } else {
	# new options override all old options which we stored, but
	# if the new options don't contain some options which were
	# previously given, we need to add them in here.
	if {[info exists alpha::regModeOptionMemory($cmode)]} {
	    foreach {o val} $alpha::regModeOptionMemory($cmode) {
		if {![info exists opts($o)]} {
		    set opts($o) $val
		}
	    }
	    unset alpha::regModeOptionMemory($cmode)
	}
    }
    if {![tw::Color $cmode [list info exists nocase]]} {
        if {[info exists opts(-C)]} {
            tw::Color $cmode [list set nocase 0]
        } else {
            tw::Color $cmode [list set nocase 1]
        }
    }
    set nocase [tw::Color $cmode [list set nocase]]
    if {[info exists opts(-begin)]} {
	# -begin option:  match regexp at beginning of line only
	set begin [lindex $opts(-begin) 0]
	if {[string length $begin]} {
	    lappend beginPat $begin
	}
	# Set the comment color.
	if {[info exists opts(-c)]} {
	    tw::Color $cmode "set specialColors(comment) color[colorIndex $opts(-c)]"
	} else {
	    tw::Color $cmode "set specialColors(comment) color5"
	}
    }
    if {[info exists opts(-e)]} {
	# -e option:  single comment character.
	set comment [lindex $opts(-e) 0]
	if {[string length $comment]} {
	    if {[string first " " $comment] != -1 && ![catch {llength $comment}]} {
		append  lineRegexp "\(?:\(" \
		  [join [quote::Regfind $comment] |] "\).*\)?"
		lappend lineVars comment
	    } else {
		append  lineRegexp "\(?:\(" [quote::Regfind $comment] "\).*\)?"
		lappend lineVars comment
	    }
	}
	# Set the comment color.
	if {[info exists opts(-c)]} {
	    tw::Color $cmode "set specialColors(comment) color[colorIndex $opts(-c)]"
	} else {
	    tw::Color $cmode "set specialColors(comment) color5"
	}
    }
    # -b option:  paired (bracketed) comments.
    if {[info exists opts(-b)]} {
	set mc [lindex $opts(-b) 0]
	tw::Color $cmode [list set multiComment $mc]
	set mC0 [lindex $mc 0]
	set mC1 [lindex $mc 1]
	# Make sure that they're both non-empty
	set emptyMulti 0
	foreach char [list $mC0 $mC1] {
	    if {![string length $char]} {set emptyMulti 1 ; break}
	}
	if {$emptyMulti} {
	    # multi comment chars were empty, so unset completely
	    unset opts(-b)
	    tw::Color $cmode "unset multiComment"
	} else {
	    append lineRegexp "(?:([quote::Regfind $mC0]).*)?"
	    lappend lineVars multicomment
	    append lineRegexp "([quote::Regfind $mC1])?"
	    lappend lineVars multicommentclose
	}
	if {[info exists opts(-c)]} {
	    tw::Color $cmode "set specialColors(comment) color[colorIndex $opts(-c)]"
	} else {
	    tw::Color $cmode "set specialColors(comment) color5"
	}
    }
    # -f option:  colorizing functions
    if {[info exists opts(-f)]} {
	tw::Color $cmode "set specialColors(function) color[colorIndex $opts(-f)]"
	append  lineRegexp "(?:(\[a-zA-Z]\\w+)\\\()?"
	lappend lineVars function
    }
    # -s option:  colorizing quoted strings.
    if {[info exists opts(-s)]} {
	tw::Color $cmode "set specialColors(quote) color[colorIndex $opts(-s)]"
	if {[info exists opts(-q)]} {
	    set pairs $opts(-q)
	} else {
	    set pairs [list [list \" \"]]
	}
	set qnum 0
	set quoteVars {}
	foreach pair $pairs {
	    if {![llength $pair]} { continue }
	    foreach {open close} $pair {
		if {![regexp -nocase -- {[a-z0-9]} $open]} {
		    set q_open "\\$open"
		} else {
		    set q_open $open
		}
		if {![regexp -nocase -- {[a-z0-9]} $close]} {
		    set q_close "\\$close"
		} else {
		    set q_close $close
		}
		# Need to store a regexp to match a multi-line quote
		tw::Color $cmode [list set specialQuotes(quote$qnum) \
		  [list $open $close "\[^\\\\\]$q_close"]]
		if {$open eq $close} {
		    append  lineRegexp \
		      "((?!\\B)${q_open}(?:\[^\\B${q_open}\]|\\B.)*(?:${q_open}|\\B?\\Z))?"
		} else {
		    append  lineRegexp \
		      "((?!\\B)${q_open}(?:\[^\\B${q_close}\]|\\B.)*(?:${q_close}|\\B?\\Z))?"
		}
		lappend quoteVars quote$qnum
		lappend lineVars quote$qnum
		incr qnum
	    }
	}
	tw::Color $cmode [list set quoteVars $quoteVars]
    }

    # -k option:  colorizing keywords.  Also used for magic characters.
    if {![info exists opts(-k)]} {set opts(-k) blue}
    set keywordColor [colorIndex $opts(-k)]
    if {$keywordColor == 0} {
	foreach kw [lindex $args 1] {
	    if {$nocase} { set kw [string tolower $kw] }
	    tw::Color $cmode [list unset -nocomplain keywords($kw)]
	}
    } else {
	foreach kw [lindex $args 1] {
	    if {$nocase} { set kw [string tolower $kw] }
	    tw::Color $cmode [list set keywords($kw) color$keywordColor]
	}
    }
    # -m option:  magic color.
    if {[info exists opts(-m)]} {
	if {$keywordColor == 0} {
	    tw::Color $cmode "unset -nocomplain magicPrefix"
	    tw::Color $cmode "unset -nocomplain magicColor"
	    # So we don't remember this option next time
	    unset opts(-m)
	} else {
	    tw::Color $cmode [list set magicPrefix [lindex $opts(-m) 0]]
	    tw::Color $cmode [list set magicColor color$keywordColor]
	}
    }
    # -i option:  special characters.  Requires an -I flag as well.
    if {[info exists opts(-i)]} {
	if {![info exists opts(-I)]} {set opts(-I) 0}
	foreach char $opts(-i) {
	    tw::Color $cmode [list set specialChars($char) color[colorIndex $opts(-I)]]
	}
    }
    if {[tw::Color $cmode [list set nocase]]} {
	tw::Color $cmode [list set lineRegexp (?i)$lineRegexp]
    } else {
	tw::Color $cmode [list set lineRegexp $lineRegexp]
    }
    tw::Color $cmode [list set lineVars $lineVars]
    if {[info exists beginPat]} {
	tw::Color $cmode [list set beginPat $beginPat]
    }
    
    if {[catch {tw::SetUpColoring $cmode} err]} {
        alertnote "Error setting up colouring-mode '$cmode': $err"
    }
    
    # remember all the old options
    set alpha::regModeOptionMemory($cmode) [array get opts]

    if {![llength [winNames -f]]} { return }
    win::_scheduleRecolouring $cmode
    return
}

proc win::_scheduleRecolouring {cmode} {
    # Now schedule a recolouring event, but only if there isn't
    # already one pending.
    set script [list ::win::recolourAllModeWindows $cmode]
    foreach af [after info] {
	if {[after info $af] eq [list $script idle]} {
	    return
	}
    }
    after idle $script
}

proc win::recolourAllModeWindows {cmode} {
    # Now, for any window which is open, with this cmode active,
    # remove all colour-related tags and recolour.
    global win::tktitle
    foreach tkw [array names win::tktitle] {
	if {[catch {tw::GetColorTags $tkw} ctags]} { continue }
	if {[lsearch -exact $ctags $cmode] != -1} {
	    foreach tag [$tkw tag names] {
		if {![regexp -- $::tw::nonColorMarkRegexp $tag]} {
		    set range [$tkw tag ranges $tag]
		    if {[llength $range]} {
			eval [list $tkw tag remove $tag] $range
		    }
		}
	    }
	    if {[wm state [winfo toplevel $tkw]] == "normal"} {
		# If it is visible
		::tw::arrangeToColour $tkw {} {}
	    }
	}
    }
}
