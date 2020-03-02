## -*-Tcl-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "interactiveSearch.tcl"
 #                                          created: 11/08/2001 {20:01:53 PM}
 #                                      last update: 03/21/2006 {01:17:32 PM}
 # Description:
 #  
 # Implements interactive searches.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 #  
 # ==========================================================================
 ##

# This is an 'always on' package, and adds the Search menu items "Quick Find"
# "Quick Find Regexp" and "Reverse Quick Find".
alpha::extension incrementalSearch 1.2.1 {
    menu::insert Search items [list after "/R<S<O<I<BreplaceInFilesetÉ"] \
      "(- " \
      "/S<E<S<BquickFind" \
      "/S<S<B<IquickFindRegexp" \
      "/R<E<BreverseQuickFind"
    hook::register requireOpenWindowsHook [list Search quickFind] 1
    hook::register requireOpenWindowsHook [list Search quickFindRegexp] 1
    hook::register requireOpenWindowsHook [list Search reverseQuickFind] 1
} maintainer {
} description {
    Implements incremental searching in Alpha windows
} help {
    This "always-on" extension package implements incremental searching in
    the active window.  Incremental searches bypass the normal search dialog
    and search for the current text after each keystroke.  The result is often
    much faster and less intrusive.  Incremental searches are invoked by
    selecting "Search > Quick Find" and "Search > Reverse Quick Find".
    
    Start the search by selecting the menu item or by pressing its keyboard
    shortcut, then start typing the word you are searching for.  After each
    letter you've typed Alpha jumps to the nearest point in the text matching
    what you have typed so far.  The search string is also displayed in the
    status bar.

    Typing Control-S or Control-R again while an incremental search is in
    progress causes the search to proceed to the next instance of the current
    text.  Typing Control-W while incremental search is active causes all the
    characters to the end of the next word boundary to be added to the search.

    In Alphatk other pieces of text matching the current search are
    underlined, letting you easily see the upcoming matches.
    
    Pressing the "Delete" key, or clicking on the window with the mouse will
    remove the most recent keystroke from the search pattern, and back up the
    search to the most recent find, acting as an internal "Undo" command
    while searching incrementally.

    To escape or stop a search, press "Return", any of the arrow navigation
    keys, or the "Page Up/Down/etc" document navigation keys.
    
    The following keyboard shortcuts are also available during interactive
    searches:
    
    Closest occurrence before current match
     
	Command-Option G
	Control-R (mnemonic 'reverse')
       
    Closest occurrence after current match
     
	Command-G
	Control-S (mnemonic 'successor')
     
	  	Text Navigation

    "Forward Char" (aborts and leaves cursor after last match)

	Right-Arrow
	Control-F (emacs)

    "Backward Char" (aborts and leaves cursor before last match)
     
	Left-Arrow
	Control-B (emacs)
       
    "Beginning Of Line" (aborts and moves cursors to the start of the line
     containing the last match)
	
	Command-Left-Arrow
	Control-A (emacs)
       
    "Beginning Of Line" (aborts and moves cursors to the start of the line
    containing the last match)
	
	Command-Right-Arrow
	Control-E (emacs)
       
    "Center Redraw" (moves selection to center, without aborting)
     
	Control-L
      
    "Insert To Top" (moves selection to top, without aborting)
     
	Control-T
      
    Add the rest of the current word to the search string.
    
	Control-W
     
	  	Text Manipulation

    "Delete Selection" (aborts and deletes selection)
     
	Control-D (emacs)
       
    "Kill Line" (aborts and deletes from start of selection to end of line)
     
	Control-K (emacs)
       
	  	Changing the search type:
       
     Switch the case-sensitivity of the current search
     
	Control-I
     
     Toggle interpretation of \n,\r,\t in non-regexp searches
     
	Control-Backslash


     No other menu items can be invoked during incremental searches.
}

proc interactiveSearch.tcl {} {}

if {[info commands highlight] == ""} {
    proc highlight {args} {
	::win::parseArgs w pattern
	# Not implemented yet in Alpha 8/X, but is in Alphatk.  Should
	# return (almost) immediately, but schedule events to ensure all
	# strings matching 'pattern' are highlighted in the given/active
	# window.
	# 
	# If 'pattern' is the empty string, then remove all highlighting.
    }
}

proc quickFind {} {search::interactive exact}
proc reverseQuickFind {} {search::interactive exact 0}
proc quickFindRegexp {} {search::interactive regexp}

namespace eval search {}

## 
 # -------------------------------------------------------------------------
 # 
 # "search::interactive" -- general interactive searching
 # 
 # This version allows class shorthands (\d \s \w \D \S \W), 
 # word anchors (\b), and some aliases of the machine dependent 
 # control characters (\a \f \e \n \r \t). Therefore, 
 # we need two prompts, one for when we have a valid pattern, and one 
 # for when the pattern has gone invalid (most likely due to starting 
 # to enter one of the above patterns). 
 # 
 # The Return key and unknown key combinations exit the search, leaving 
 # the point at its current position. You can then use 'exchangePointAndPin'
 # (cntrl-x, cntrl-x -in emacs keyset) to jump back and forth between where
 # the search started from and where the search ended.
 # 
 # Known key combinations (e.g., arrow keys, many emacs navigation keys)
 # exit the search and perform the appropriate action. The mark is set to
 # the last successful search, so 'exchangePointAndPin' does NOT take you
 # to the start of the search.
 # 
 # The Escape key or abortEm (cntrl-g in emacs) "aborts" the search,
 # returning the cursor to the point where the search started from.
 # Use 'exchangePointAndPin' to jump to the last found match.
 # 
 # The next occurrence of the current pattern can be matched by typing 
 # either control-s (to get the next occurence forward), or control-r 
 # (to get the next occurrence backward)
 #
 # Also, after aborting or exiting, the search string is left in the Find
 # dialog, and so you can use 'findAgain' or cntrl-s or cntrl-r to continue
 # the search. Be aware that the Find dialog starts out with a default of 
 # <Grep=OFF>.
 #  
 # Original Author: Mark Nagata
 # modifications  : Tom Fetherston
 # modifications  : Vince Darley, so works with or without regexp
 # -------------------------------------------------------------------------
 ##

proc search::interactive {{type "exact"} {direction 1}} {
    set ignoreCase 1
    set interpretBackslash 0
    set patt ""
    set pos [getPos]
    lappend history [list "" [list $pos $pos] 1]
    
    set done 0
    while {!$done} {
	if {$type == "regexp"} {
	    # check pattern validatity
	    if {[catch {regexp -- $patt {} dmy} dmy]} {		
		set prompt "building->: $patt"
	    } else {
		set prompt "regIsearch: $patt"
	    }
	} else {
	    set prompt "search: $patt"
	}
	set proc [list search::interactiveKeypress $type $direction]
	set done 1
	switch -- [catch [list status::prompt -appendvar patt -command $proc -add anything $prompt] res] {
	    0 {
		# got a keystroke that triggered a normal end (e.g. <return>)
		set res "<return>"
		set tmp [getPos]
		goto $pos
		setPin
		goto $tmp
	    }
	    1 {
		# an error was generated
		if {[string match "missing close-brace" $res]} {
		    # must have typed a slash, so:
		    append patt "\\"
		    set done 0
		} elseif {[string match "invoked \"break\" outside of a loop" $res]} {
		    # do nothing
		} elseif {[string match "abort*" $res]} {
		    if {[package::active emacs]} { append res ". ctrl-x ctrl-x goes to last found" }
		    goto $pos
		} elseif {[string match "unknown*" $res]} {
		    if {[package::active emacs]} { append res ". ctrl-x ctrl-x goes to search start" }
		    set tmp [getPos]
		    goto $pos
		    setPin
		    goto $tmp
		} else {
		    # unknown error -- exit
		}
	    }
	    default {
		set done 1
	    }
	}
    }
    highlight ""
    status::msg "Search $patt: exited with $res."
}

## 
 # -------------------------------------------------------------------------
 # 
 # "search::interactiveKeypress" -- handle isearch, rsearch, regIsearch
 # 
 #  This proc handles each keypress while running a regIsearch. It has been 
 #  modified from Mark Nagata's original to provide next ocurrence 
 #  before/after current, and support for key bindings whose navigation or 
 #  text manipulation functionality makes sense with respect to a regIsearch.
 #  
 #  See the help text for this package for details of the key-bindings.
 #  
 # -------------------------------------------------------------------------
 ##
proc search::interactiveKeypress {type dir {key 0} {mod 0}} {
    set direction {}
    set t [keys::modToString $mod]

    if {[string length $key]} {
	scan $key %c decVal
    } else {
	# No key showed up.  Probably running on Alphatk
	error "no key press"
    }
    #alpha::log stdout "\r$key $t $mod $decVal"
    upvar 1 patt pat
    switch -- $t {
	"____" {
	    switch -- $decVal {
		8  {
		    set len [string length $pat]
		    if {$len > 0} {
			set pat [string range $pat 0 [expr {$len-2}]]
			set key ""
			set backtrack 1
		    } else {
			error "deletion of all characters"
		    }
		}
		1 { beginningOfBuffer;  error "navigation key"; # home; }
		4 { endOfBuffer;  error "navigation key"; # end; }
		11 { pageBack;  error "navigation key"; # page up; }
		12 { pageForward;  error "navigation key"; # page down; }
		29 { forwardChar; error "navigation key"; # right arrow; }
		28 { backwardChar; error "navigation key"; # left arrow; }
		30 { previousLine; error "navigation key"; # up arrow; }
		31 { nextLine; error "navigation key"; # down arrow; }
		27 { error "abort (esc key)"; # escape; }
		13 { error "<return> key"; }
	    }
	}
    }
    switch -- $t {
	"____" - 
	"_s__" {
	    if {0 && $curr != ""} {
		while {[string compare [string range $pat [string last $curr $pat] end] $curr] != 0} {
		    set newEnd [expr {[string length $pat] - 2}]
		    if {$newEnd < 0} {
			error "deletion of all characters"
		    } 
		    set pat [string range $pat 0 $newEnd] 
		    set backtrack 1
		}
	    } 
	    
	    set preAppend $pat
	    append pat $key
	    if {$type == "regexp"} {
		if {[catch {regexp -- $pat {} dmy} res]} {
		    status::msg "building->: $preAppend"
		    return $key
		}
	    }
	    set direction $dir
	    # This is a continuing search from the current point
	    set inplace 1
	}
	"c___" {
	    switch -- $decVal {
		101 { 
		    # cmd-e = enter search string
		    searchString $pat
		    return {}
		}
		103 { set direction 1; 	   # (cmd g); }
		28 { beginningOfLine; error "navigation key"; # cmd left arrow; }
		29 { endOfLine; error "navigation key"; # cmd right arrow; }
		default { error "unknown cmd key" }
	    }
	    
	}
	"__o_" {
	    if {[package::active emacs]} {
		switch -- $decVal {
		    2 - 186 { backwardWord; error "emacs delete word (opt-d)"; # opt-b; }
		    4 - 182 { deleteWord; error "emacs delete word (opt-d)"; # opt-d; }
		    6 - 196 { forwardWord; error "emacs forward word (opt-f)"; # opt-f; }
		}
	    } 
	}
	"___z" {
	    # If the user is using the emacs key bindings, check for ones that 
	    # make sense. All other control key combinations abort
	    if {[package::active emacs]} {
		switch -- $decVal {
		    1 { beginningOfLine; error "emacs beginning of line (cnt-a)"; # cntrl-a; }
		    2 { backwardChar; error "emacs backward char (cnt-b)"; # cntrl-b; }
		    4 { deleteSelection; error "emacs delete selection (cnt-d)"; # cntrl-d; }
		    5 { endOfLine; error "emacs end of line (cnt-e)"; # cntrl-e; }
		    6 { forwardChar; error "emacs forward char (cnt-f)"; # cntrl-f; }
		    11 - 107 { killLine; error "emacs kill line (cnt-k)"; # cntrl-k; }
		    14 { backwardChar; nextLine; error "emacs next line (cnt-n)"; }
		    15 { openLine; error "emacs open line (cnt-o)"; # cntrl-o; }
		    16 { backwardChar; previousLine; error "emacs previous line (cnt-p)"; }
		}
	    } 
	    # See if user has requested to find another match, either searchForward 
	    # (cntrl-s) or reverseSearch (cntrl-r). Set flag accordingly
	    switch -- $decVal {
		18 - 114 - 19 - 115 { 
		    # (ctrl-r, ctrl-s)
		    if {![string length $pat]} { 
			# load previous search string if current is empty
			set pat [searchString]
		    }
		    switch -- $decVal {
			18 - 114 { set direction 0; # reverse; }
			19 - 115 { set direction 1; # forward; }
			default {}
		    }
		}
		20 - 116 {
		    insertToTop; #cntl-t; 
		}
		12 - 108 { 
		    centerRedraw; return {};	# cntrl-l; 
		}
		28 {
		    # ctrl-backslash : toggle \n\r\t interpretation
		    upvar 1 interpretBackslash ib
		    set ib [expr {1-$ib}]
		    set direction $dir
		    set inplace 1
		}
		8 - 103 {
		    # cntrl-g
		    error "abort (ctrl-g)"
		}
		9 - 105 {
		    # ctrl-i : change case-sensitivity
		    upvar 1 ignoreCase ign
		    set ign [expr {1-$ign}]
		    set direction $dir
		    set inplace 1
		}
		23 - 119 {
		    # ctrl-w : add next word
		    set _p [getPos]
		    set _q [pos::math $_p + [string length [getSelect]]]
		    goto $_q
		    forwardWord
		    append pat [getText $_q [getPos]]
		    goto $_p
		    set direction $dir
		    set inplace 1
		}
		default { error "unknown cntrl key" }
	    }
	}
	"c_o_" {
	    switch -- $decVal {
		169 { 
		    # (cmd-opt 'g')
		    set direction 0 
		}
		default { error "unknown cmd-option key" }
	    }
	    
	}
	"default" {
	    error "unknown modifier key"
	}
    }
    # handle direction flag if it got set above
    if {$direction != ""} {
	if {$type == "regexp"} {
	    status::msg "regIsearch: $pat " 
	} else {
	    status::msg "search: $pat " 
	}
	upvar 1 ignoreCase ign
	if {![info exists inplace]} {
	    if {$direction} {
		set search_start [pos::math [getPos] + 1]
	    } else {
		set search_start [pos::math [getPos] - 1]
	    }
	} else {
	    set search_start [getPos]
	}
	upvar 1 history hist
	if {[info exists backtrack]} {
	    while {[llength $hist] > 1} {
		set hist [lrange $hist 0 [expr {[llength $hist]} -2]]
		if {[llength $hist]} {
		    set last [lindex $hist end]
		    if {[llength $last] == 1} {
			# search failed
			set failed 1
			continue
		    }
		    # Only if we haven't failed do we check the in-place
		    # flag (list index 2).
		    if {![info exists failed]} {
			if {![lindex $last 2]} {
			    continue
			}
		    }
		    break
		} else {
		    # error "Probably shouldn't get here"
		    # Avoid infinite loop in some odd cases.
		    break
		}
	    }
	    set last [lindex $hist end]
	    set pat [lindex $last 0]
	    eval selectText [lindex $last 1]
	    set str [eval getText [lindex $last 1]]
	    if {[string length $str] > 1} { 
		highlight $str 
	    }
	} else {
	    if {$type == "regexp"} {
		set searchResult [search -s -n -f $direction -m 0 \
		  -i $ign -r 1 -- $pat $search_start]
	    } else {
		upvar 1 interpretBackslash ib
		if {$ib} {
		    set spat $pat
		    regsub -all "\\\\n" $spat "\n" spat
		    regsub -all "\\\\r" $spat "\r" spat
		    regsub -all "\\\\t" $spat "\t" spat
		    set searchResult [search -s -n -f $direction -m 0 \
		      -i $ign -r 0 -- $spat $search_start]
		} else {
		    set searchResult [search -s -n -f $direction -m 0 \
		      -i $ign -r 0 -- $pat $search_start]
		}
	    }
	    searchString $pat
	    if {[llength $searchResult] == 0} {
		lappend hist [list "failed"]
		beep
	    } else {
		lappend hist [list $pat $searchResult [info exists inplace]]
		eval selectText $searchResult
		set str [eval getText $searchResult]
		if {[string length $str] > 1} { 
		    highlight $str 
		}
	    }
	}
	return {}
    }
}

# ===========================================================================
# 
# .