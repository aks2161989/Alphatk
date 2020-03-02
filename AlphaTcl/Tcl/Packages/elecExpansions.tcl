## -*-Tcl-*-
 # ==========================================================================
 # Vince's Additions - an extension package for Alpha
 # 
 # FILE: "elecExpansions.tcl"
 #                                          created: 12/30/1996 {12:30:40 pm}
 #                                      last update: 03/21/2006 {02:09:52 PM}
 # 
 # Description:
 # 
 # Support for electric expansion of acronyms.
 # 
 # Author: Mark Nagata
 # E-mail: <nagata@kurims.kyoto-u.ac.jp>
 #   
 # Author: Tim van der Leeuw
 # E-mail: <tnleeuw@cs.vu.nl>
 # 
 # Author: Thomas R. Fetherston
 # E-mail: <ranch1@earthlink.net>
 #   mail: 94 Lipp Ave, Pittsburgh, PA 15229-2001
 #   
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 #      
 # Copyright (c) 1997-2006 Thomas R. Fetherston, Vince Darley.
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # This package is not actively improved any more, so if you wish to make
 # improvements, feel free to take it over.
 # 
 # ==========================================================================
 #
 # to do list
 # ----------
 # change __Gcw_prevHint to a list of previous hits so we only get new hits
 # 
 # (status:: Done ??) 
 # 
 # monitor the character(s) to the right of the cursor point so the
 # automatic, "oneSapce" can be suppressed, e.g. if a comma, close
 # "bracket", or return immediately follows, let the inserted text abut
 # it without a space
 # 
 # (status:: Done ??)
 # 
 # cause a hint that ends in an '[' to search for a hit that is a
 # parameterized routine.  (what is a routine depends on the mode), and
 # invoke a "replacement that includes a template for the proper number
 # of arguments
 # 
 # let numerals play a role in finding a "Hit"
 # 
 # let an invocation include a file or list to be searched instead of
 # the current window.
 # 
 # ==========================================================================
 # 
 # Technical notes
 # ---------------
 # All the global variables needed to store state information between calls
 # (start with __Gcw_)
 # 
 # The following binding is just a suggestion.  It is the one that I like
 # best, I have this in my pref.tcl file
 # 
 # ascii 0x20 <c> bind::Expansion
 # i.e. command-<space>
 # 
 # ==========================================================================
 ##

alpha::feature elecExpansions 9.1.3 "global-only" {
    lunion flagPrefs(Completions) listPickIfMultExpds
    # This is similar to the flag for completions.
    newPref flag listPickIfMultExpds 0
    # Create the "Electric Expansions" menu
    menu::buildProc electricExpansions menu::buildExpansionsMenu
    proc menu::buildExpansionsMenu {} {
	set menuList [list \
	  "viewGlobalExpansionsÉ"	\
	  "addGlobalExpansionsÉ"	\
	  "editGlobalExpansionsÉ"	\
	  "removeGlobalExpansionsÉ"	\
	  "(-"				\
	  "expansionsHelp" 		\
	]
	return [list build $menuList expansion::menuProc {} electricExpansions]
    }
} { 
    # Insert the menu into "Config --> Packages".
    menu::insert preferences submenu "(-)" electricExpansions
} {
    # De-activation script
    menu::uninsert preferences submenu "(-)" electricExpansions
} maintainer {
    "Tom Fetherston" "<ranch1@earthlink.net>"
} uninstall {
    this-file
} description {
    This package provides a different kind of word completion than Electric
    Completions.  To expand word-combinations, type the word's 'acronym' and
    invoke an expansion instead by using the 'expansion' key
} help {
    This package provides a different kind of word completion than the
    package: elecCompletions.  When you find yourself typing a lot of
    variable and function names over and over, and these names are
    word-combinations where the name is formed by either capitalizing each
    word or separating them with an underscore, just type the initial
    letter of each word and invoke an acronym expansion instead by using
    the 'expansion' key.  The "Config --> Special Keys" menu item allows
    you to set/change this key; you can access this dialog now by clicking
    here: <<global::specialKeys>>
    
    The idea of this package is to allow you to type a string consisting of
    the initial letters of the words that have been joined to make up a
    variable, function, or procedure name.  This is often shorter and more
    natural than typing a few letters and using electric completions.  As I
    developed this routine I found that a regexp for more than three
    letters caused search to choke so only those letters of a "hint" are
    significant.  A three letter pattern is used for the search.
    
    After a possible hit is located, it is turned into an acronym and
    checked against the "hint".  The string you are going to use expansion
    on can be entered in uppercase, lowercase, or any combination.  The
    words in the target you are trying to hit have to start with a capital
    (except the first word), or, be separated by an underscore or a colon.
    
    The hint can be embedded between non-alphabetic characters and certain
    punctuation marks:
    
	[ ( { , ; : ' " ] ) }  
    
    The expanded hint remains so embedded, and the cursor appears
    beyond the trailing punctuation.  Any whitespace between the hint and
    the cursor is also preserved.
    
    e.g. if 'sin($gl)' was expanded (in the file "elecExpansions.tcl"), 
    we would get 
    
	sin($__Gcw_len)
    
    Similarly, 'mouse($gph', would expand to
    
	mouse($__Gcw_prevHint,
    
    done twice, we would get
    
	mouse($__Gcw_prevHit,

    Take the "Text Tutorial" for a demonstration.
    
    See the "Electrics Help" file for more information about electrics.
}

proc elecExpansions.tcl {} {}

## 
 # -------------------------------------------------------------------------
 #       
 # "bind::Expansion" --
 #      
 # If we're already completing, jump to that procedure, else go through a
 # mode-dependent list of expansion procedures given by the array
 # 'expanders', these return either '1' to indicate termination, or '0' to
 # say either that they failed or that they succeeded and that further
 # expansion procedures may be applied.
 # 
 # -------------------------------------------------------------------------
 ##

namespace eval bind {}

proc bind::Expansion {} {

    if {![win::checkIfWinToEdit]} {return}
    if {![completion::tabDeleteSelection]} {return}
    
    if {[completion::noCompletionInProgress]} {
	if {[expansion::user]} {return}
	global expanders mode
	if {![catch {set expandersList $expanders($mode)}]} {
	    foreach e $expandersList {
		if {[completion $mode $e]} {return}
	    }
	}
	#if none of the expanders succeeded, (or, don't exist) try
	expansion::acronym
    }
}

namespace eval expansion {}

# ===========================================================================
# 
# ×××× Electric Expansions menu ×××× #
# 
# Allows users to define their own global expansions without having to
# modify any prefs.tcl files.
# 
# Contributed by Craig Barton Upright.
# 

# Just so we have one!
set userExpansions(date) {×kill0×[lindex [mtime [now]] 0]}

proc expansion::menuProc {menu item} {
    if {$item == "expansionsHelp"} {
	package::helpWindow "elecExpansions"
    } else {
	expansion::$item
    } 
}

proc expansion::viewGlobalExpansions {} {
    
    global mode userExpansions
    
    set windows [winNames]
    foreach w $windows {
	# Close any open "* Expansions *" windows.
	if {[win::StripCount $w] == "* Expansions *"} {
	    bringToFront $w
	    killWindow
	}
    }
    new -n "* Expansions *" -text [listArray userExpansions] -m $mode
    # if 'shrinkWindow' is loaded, call it to trim the output window.
    catch {
	goto [maxPos] ; insertText "\r"
	selectAll     ; sortLines 
    }
    goto [minPos]
    insertText "Use the \"Edit Expansions\" \rmenu item to re-define them.\r\r"
    catch {shrinkWindow 2}
    winReadOnly
    status::msg "" 
    
}

proc expansion::addGlobalExpansions {{title ""} {hint ""} {expansion "×kill0"}} {
    
    set finish [expansion::addExpansionsDialog "" $hint $expansion]
    # Offer the dialog again to add more.
    set title "Create another Expansion, or press Finish:"
    while {$finish != "1"} {
	set finish [expansion::addExpansionsDialog $title "" $expansion]
    }
    expansion::viewGlobalExpansions
}

proc expansion::addExpansionsDialog {{title ""} {hint ""} {expansion "×kill0"}} {
    
    global userExpansions
    
    if {$title == ""} {
	set title "Create a new Expansion, or redefine an existing one:"
    } 
    set y 10
    set aCD [list -T $title]
    set yb 20
    set Expansion "Expansion (×kill0 deletes hint) :" 
    eval lappend aCD [dialog::button   "Finish"                    300 yb   ]
    eval lappend aCD [dialog::button   "More"                      300 yb   ]
    eval lappend aCD [dialog::button   "Cancel"                    300 yb   ]
    if {$hint == ""} {
	eval lappend aCD [dialog::textedit "Hint :" $hint           10  y 25]
    } else {
	eval lappend aCD [dialog::text     "Hint :"                 10  y   ]
	eval lappend aCD [dialog::menu 10 y $hint $hint 200                 ]
    } 
    eval lappend aCD [dialog::textedit $Expansion $expansion        10  y 25]
    incr y 20
    set result [eval dialog -w 380 -h $y $aCD]
    if {[lindex $result 2]} {
	# User pressed "Cancel'
	error "cancel"
    }
    set finish     [lindex $result 0]
    set hint       [string trim [lindex $result 3]]
    set expansion [lindex $result 4]
    if {$hint != "" && $expansion != ""} {
	set userExpansions($hint) $expansion
	prefs::addArrayElement userExpansions $hint $expansion
	status::msg "\"$hint -- $expansion\" has been added."
	return $finish
    } elseif {$finish == "1"} {
	return $finish
    } else {
	error "Cancelled -- one of the dialog fields was empty."
    } 
}

proc expansion::editGlobalExpansions {} {
    
    global userExpansions
    
    set hint [listpick -p "Select a hint to edit:" \
      [lsort -dictionary [array names userExpansions]]]
    set expansion $userExpansions($hint)
    set title "Edit the \"$hint\" correction:"
    set finish [expansion::addExpansionsDialog $title $hint $expansion]
    # Offer the dialog again to add more.
    while {$finish != "1"} {
	set hint [listpick -p \
	  "Select another hint to edit, or Cancel:" \
	  [array names userExpansions]]
	set expansion $userExpansions($hint)
	set title "Edit the \"$hint\" expansion"
	set finish [expansion::addExpansionsDialog $title $hint $expansion]
    }
    expansion::viewGlobalExpansions 
}

proc expansion::removeGlobalExpansions {{removeList ""}} {
    
    global userExpansions
    
    if {$removeList == ""} {
	# First list the user defined expansions.  We remove "date"
	set userHints [array names userExpansions]
	set dateSpot [lsearch $userHints date]
	if {$dateSpot != "-1"} {
	    set userHints [lreplace $userHints $dateSpot $dateSpot]
	} 
	if {[llength $userHints] == "0"} {
	    status::msg "Cancelled -- there are no user defined expansions to remove."
	    return
	} 
	set removeList [listpick -l -p "Select some Hints to remove:" \
	  [lunique $userHints]]
    } 
    foreach hint $removeList {
	# Then remove it from arrdefs.tcl
	catch {prefs::removeArrayElement userExpansions $hint}
	catch {unset userExpansions($hint)}
    }
    expansion::viewGlobalExpansions
}

# ×××× ---------------- ×××× #

# ×××× Expanding ×××× #

# ===========================================================================
# 
# These declare, in order, the names of the expander procedures for each
# mode.  The actual procedure must be named
# 
# '${mode}::Expansion::${listItem}', 
# 
# unless the item is 'expansions::*' in which case that actual procedure is
# called.
# 

# These should actually go in the <mode>Completions.tcl files.

set expanders(TeX) {ExCmd}
set expanders(Tcl) {}
set expanders(C)   {}

# Set up some global variables.

ensureset __Gcw_prevHint        {}
ensureset __Gcw_prevsrcListName {}
ensureset __Gcw_prevHintPos     ""
ensureset __Gcw_nextStart       ""
ensureset __Gcw_above_BELOW     ""
ensureset __Gcw_endPrevRpl      ""
ensureset __Gcw_pos_expanding   ""
ensureset __Gcw_expanding       0
ensureset __Gcw_already_expanding error

proc expansion::user {{cmd ""}} {
    global userExpansions
    if {![string length $cmd]} {
	set cmd [completion::lastWord]
    }
    if {[containsSpace $cmd] || ![info exists userExpansions($cmd)]}  {
	return 0
    } else {
	elec::findCmd $cmd userExpansions
	return 1
    }
}

proc expansion::acronym {} {
    
    global __Gcw_len       __Gcw_prevHintPos __Gcw_prevHint   __Gcw_endPrevRpl
    global __Gcw_prevHits  __Gcw_patt        __Gcw_nextStart  __Gcw_above_BELOW
    global __Gcw_expanding 
    
    set To         [getPos]
    set lastChar   [lookAt [pos::math $To - 1]]
    set hintCapper [lookAt $To]
    
    backwardWord
    set From [getPos] ; goto $To
    
    # Adjust From to prune any non alphabetic prefix
    set hint [getText $From $To]
    
    # The following variables may not come into existence in the regexp
    # below, so set up defaults.
    set tail ""
    set punc ""
    regexp {([a-zA-Z0-9_]+)([](\{[,;:'"\}) ]*)[\t ]*$} $hint tail hint punc
    set From [pos::math $To - [string length $tail]]

    # This is a 1st try, so make sure the hint is legal.
    if {![string length $__Gcw_prevHintPos]} {
	if {[regexp {[0-9_]} $hint] > 0} {
	    selectText $From $To
	    set msg "'$hint' is an illegal hint:\
	      numerals and underscores are not allowed."
	} elseif {[pos::compare $From == $To]} {
	    set msg "Cancelled -- was not able to find any hint."
	} 
	if {[info exists msg]} {
	    beep ; status::msg $msg
	    set __Gcw_prevHintPos ""
	    set __Gcw_expanding 0
	    return
	} 
    }
    
    # Adjust To, leaving trailing spaces or tabs
    set To [pos::math $From + [string length $hint] + [string length $punc]]

    if {![string length $__Gcw_prevHintPos] \
      || [pos::compare $From != $__Gcw_prevHintPos]} {
	# Trying to expand a new hint
	set __Gcw_prevHint $hint
	set __Gcw_prevHits {}
	set __Gcw_len  [string length $hint]
	set __Gcw_patt [elec::searchPat $hint]
	set __Gcw_above_BELOW 0
	
	set start [pos::math $From - 1] 
	set beg {}; set end {}
	set foundAbove 0
	set foundBelow 0

	elec::_searchAboveForHit start beg end Hit foundAbove
	
	if {$foundAbove} {
	    lappend __Gcw_prevHits $Hit
	    # Put in the Hit, 
	    set replacement ${Hit}${punc}
	    set msg "Found above."
	    set __Gcw_prevHintPos $From
	    set __Gcw_endPrevRpl [getPos]
	    elec::_adjustGlobals __Gcw_endPrevRpl __Gcw_above_BELOW __Gcw_nextStart
	} else {
	    # Reset some variables to search 'below'.
	    set start $To
	    set beg {} ; set end {}
	    set __Gcw_above_BELOW 1
	    elec::_searchBelowForHit start beg end Hit foundBelow
	}
	if {$foundBelow} {
	    lappend __Gcw_prevHits $Hit
	    # Put in the Hit, 
	    set replacement ${Hit}${punc}
	    set msg "Found below."
	    set __Gcw_prevHintPos $From
	    set __Gcw_endPrevRpl [getPos]
	    elec::_adjustGlobals __Gcw_endPrevRpl __Gcw_above_BELOW __Gcw_nextStart
	}
	if {![info exists replacement]} {
	    # No Hit for this hint exists
	    selectText $From $To
	    status::msg "No possible expansions were found."
	    set __Gcw_prevHintPos ""
	    set __Gcw_expanding 0
	    return
	} 
    } 
    while {![info exists replacement]} {
	# No replacement yet, so we are re-trying the previous hint.
	set start $__Gcw_nextStart  
	set beg {} ; set end {}
	set foundByContinuedSearch 0
	elec::_continueSearchForHit start beg end Hit foundByContinuedSearch
	
	# Pre-set 'where', in case there is a valid Hit for this iteration
	if {$__Gcw_above_BELOW} {set where "below"} else {set where "above"}

	if {$foundByContinuedSearch} {                      
	    # If this Hit is not the same as the last one
	    if {![lcontains __Gcw_prevHits $Hit]} {
		# Add the hit to the list of previous hits
		lappend __Gcw_prevHits $Hit
		# Put in the Hit, 
		set replacement ${Hit}${punc}
		set msg "Found ${where}."
		set __Gcw_endPrevRpl [getPos]
	    }
	    elec::_adjustGlobals __Gcw_endPrevRpl __Gcw_above_BELOW __Gcw_nextStart
	} else {
	    # Another Hit was not found
	    if {!$__Gcw_above_BELOW} {
		# We haven't tried BELOW
		set __Gcw_above_BELOW 1
		set __Gcw_nextStart $__Gcw_endPrevRpl
	    } else {
		# No more Hits can exist, because we have exhausted the search.
		set replacement ${__Gcw_prevHint}${punc}
		set msg "Original hint -- all possible expansions have been cycled."
		set __Gcw_prevHintPos ""
		set __Gcw_expanding   0
	    }
	}
    }
    if {[info exists replacement]} {
	replaceText $From $To $replacement
	goto [pos::math $From + [string length $replacement]]
	status::msg $msg
    }
}

namespace eval elec {}

## 
 # -------------------------------------------------------------------------
 #       
 # "elec::alreadyExpanding" --
 #      
 # If a expansion routine has been called once, and would like to be called
 # again (to cycle through a number of possibilities), then it should
 # register itself with this procedure.
 #  
 # -------------------------------------------------------------------------
 ##

proc elec::alreadyExpanding {procedure} {

    global __Gcw_already_expanding __Gcw_pos_expanding

    # Store the given expansion
    set __Gcw_already_expanding $procedure
    set __Gcw_pos_expanding     [getPos]
}

# Note: in all the following scripts that start with uplevelÉ, the
# agrguments are "fake", and serve only to show what variables are used by
# these macro-like subroutines.  Their primary purpose is to make the above
# code more readable.  Each is started with an underscore to indicate that
# they are internal to another routine, and should not be called by
# themselves.

#    ------------------  -in--  -out--------(bool)-
proc elec::_searchAboveForHit {start  beg end Hit success} {
    
    uplevel {
	if {[pos::compare $start == [minPos]]} {
	    set moreToSearch 0
	} else {
	    set moreToSearch 1
	}
	while {$moreToSearch} {
	    set pat $__Gcw_patt
	    set foundAbove [expr {![catch {search -s -f 0 -r 1 -i 0 -m 1 -- $pat $start} BegEnd]}]
	    if {!$foundAbove} {unset BegEnd ; break}
	    set beg [lindex $BegEnd 0]
	    set end [lindex $BegEnd 1]
	    unset BegEnd
	    set Hit [getText $beg $end]
	    
	    set fullMatch [elec::acronymsAreEqual $hint $Hit]
	    if {$fullMatch} {
		break
	    } else {
		set foundAbove 0
	    }
	    if {[pos::compare $beg <= [minPos]]} {
		set moreToSearch 0
	    } else {
		set start [pos::math $beg - 1]
	    }
	}
    }
}

# -- ------------------------  -in-- -out--------(bool)-
proc elec::_searchBelowForHit {start beg end Hit success} {
    
    uplevel {
	set moreToSearch 1
	while {$moreToSearch} {
	    set pat $__Gcw_patt
	    set foundBelow [expr {![catch {search -s -f 1 -r 1 -i 0 -m 1 -- $pat $start} BegEnd]}]
	    if {!$foundBelow} {unset BegEnd ; break}
	    set beg [lindex $BegEnd 0]
	    set end [lindex $BegEnd 1]
	    set Hit [getText $beg $end]
	    unset BegEnd
	    
	    set fullMatch [elec::acronymsAreEqual $hint $Hit]
	    if {$fullMatch} {
		break
	    } else {
		set foundBelow 0
	    }
	    if {[pos::compare $end >= [maxPos]]} {
		set moreToSearch 0
	    } else {
		set start [expr $end]
	    }
	}
    }
}

# -- ---------------------------  -in--  -out--------(bool)-
proc elec::_continueSearchForHit {start  beg end Hit success} {
    
    uplevel {
	set moreToSearch 1
	while {$moreToSearch} {
	    set foundByContinuedSearch [expr {![catch {search -s -f $__Gcw_above_BELOW -r 1 -i 0 -m 1 -- \
	      $__Gcw_patt $__Gcw_nextStart} BegEnd]}]
	    if {!$foundByContinuedSearch} {unset BegEnd ; break}
	    set beg [lindex $BegEnd 0]
	    set end [lindex $BegEnd 1]
	    set Hit [getText $beg $end]
	    unset BegEnd
	    
	    set fullMatch [elec::acronymsAreEqual $__Gcw_prevHint $Hit]
	    if {$fullMatch} {
		break
	    } else {
		set foundBelow 0
	    }
	    if {[pos::compare $end >= [maxPos]]} {
		set moreToSearch 0
	    } else {
		elec::_adjustGlobals __Gcw_endPrevRpl  __Gcw_above_BELOW   __Gcw_nextStart
	    }
	}
    }
}

# -- --------------------  -in------------- -mod-------------  -out-----------
proc elec::_adjustGlobals {__Gcw_endPrevRpl __Gcw_above_BELOW  __Gcw_nextStart} {
    
    uplevel {
	if {$__Gcw_above_BELOW} {
	    set __Gcw_nextStart $end
	} else {
	    set __Gcw_nextStart [pos::math $beg - 1]
	    if {![string length $__Gcw_nextStart]} {
		set __Gcw_above_BELOW 1
		set __Gcw_nextStart $__Gcw_endPrevRpl
	    }
	}
    }
}

# -- ----------------(bool)  -in- ---------------
proc elec::acronymsAreEqual {hint wordCombination} {
    
    set splitOnUndrS [split $wordCombination {_}]
    set shoe {}
    foreach part $splitOnUndrS {
	if {$part == {}} continue
	set part [split $part {}]
	set part [lreplace $part 0 0 [string toupper [lindex $part 0]]]
	set part [join $part {}]
	append shoe $part
    }
    regsub -all \[a-z0-9\] $shoe {} shoe
    return [expr {![string compare [string toupper $hint] $shoe]}]
}

## 
 # -------------------------------------------------------------------------
 #       
 # "elec::acronymListExpansions" --
 #      
 # Given a an acronym of the sub-words in a 'multi-word command' (the
 # 'hint') and the name of a list to search, that list consisting of
 # acronyms-command pairs on separate lines that have been placed in
 # alphabetical order and starting/ending with a return, this proc returns
 # a list of all pairs that have the hint as their first element or'0' if
 # there were none.
 #   
 # Based on Vince Darley's modeListCompletions.
 # 
 # -------------------------------------------------------------------------
 ##

proc elec::acronymListExpansions {hint dictName} {
    
    global $dictName
    
    set reg {(\n}
    append reg $hint { +[^\n]+)+}
    if {[regexp $reg [set $dictName] pairs]} {
	set odd 1
	foreach m $pairs {
	    if {$odd % 2 != 0} {incr odd ; continue}
	    incr odd
	    append matches $m " "
	}
	return $matches
    } else {
	return 0
    }
}

proc elec::expandThis {cmd matches {isdbllist 0} {forcequery 0}} {

    global possMatches returnedMatch listPickIfMultExpds
    
    set possMatches $matches
    set mquery [set match [lindex $matches 0]]
    if {$isdbllist} { set match [lindex [lindex $match 0] 0]}
    if { [set cmdnum [llength $matches]] == 1 || $match == $cmd } {
	# It's unique or already a command, so insert it 
	backwardDeleteWord
	elec::commandPrefix
	insertText $match
	return $match
    } else {
	set item [lindex $matches [incr cmdnum -1]]
	if {$isdbllist} { set item [lindex [lindex $item 0] 0] }
	
	set num 1
	set correspondingNum 1
	set numberedChoices "\{"
	set currChoiceSet ""
	set setIdx 0
	set multiSets 0
	set pickNumOfStartIn(0) $correspondingNum
	foreach m $matches {
	    append numberedList "\{$num $m\} "
	    #make up a list of choiceSets, where eadh choice set has < 79
	    # characters
	    if {[string length "$currChoiceSet$correspondingNum $m "] < 77} {
		append numberedChoices "$correspondingNum $m "
		append currChoiceSet   "$correspondingNum $m "
		set setAndNum($num) [list $setIdx $correspondingNum]
	    } else {
		incr setIdx
		set correspondingNum 1
		append numberedChoices "mÉ\} \{$correspondingNum $m "
		set currChoiceSet      "$correspondingNum $m "
		set setAndNum($num) [list $setIdx $correspondingNum]
		set pickNumOfStartIn($setIdx) $num
		set multiSets 1
	    }
	    incr correspondingNum
	    incr num
	}
	if {$multiSets} {
	    append numberedChoices "bÉ\}"
	} else {
	    append numberedChoices "\}"
	}
	if {$listPickIfMultExpds} {
	    beep
	    if {[catch { set choice [listpick -p "Pick an expansion" $numberedList]}]} {
		status::msg "Cancelled"
		return 1
	    } else {
		backwardDeleteWord
		elec::commandPrefix
		set choice [lindex $choice 1]
		insertText $choice
		return $choice
	    }
	} else {
	    set pickNum 1
	    set promptNum $pickNum
	    set currChoiceSet_idx 0
	    set c "\t"
	    backwardDeleteWord
	    elec::commandPrefix
	    insertText [lindex $matches 0]
	    
	    while {[set c] == "\t"} {
		set currChoiceSet_idx [lindex $setAndNum($pickNum) 0]
		set currChoiceSet     [lindex $numberedChoices $currChoiceSet_idx]
		# Look up what number in the currChoiceSet corresponds to
		# the pickNum
		set currNum [lindex $setAndNum($pickNum) 1]
		regsub "$currNum " $currChoiceSet "=>" choices

		set returnedMatch ""
		
		status::msg $choices
		set c [getChar]
		set c [string tolower $c ]
		scan $c "%c" decRep
		if {$decRep == 27} {
		    set c "esc"
		} 
		switch -- $c {
		    "\t" {
			incr pickNum
			if {$pickNum > [llength $matches]} {
			    set pickNum 1
			} 
			backwardDeleteWord
			elec::commandPrefix
			insertText [lindex $matches [expr {$pickNum -1}]]
			# Set things up so we cylce to the next choice
			continue                                        
		    }
		    " " -
		    "\\" -
		    "\r" -
		    "\n" {
			# these keys indicate that we are satisfied with
			# the current choice, just insert the key pressed

			# alertnote "you pressed a return, \\, or space"
			# alertnote "pickNum = $pickNum"
			return [list [lindex $matches [expr {$pickNum -1}]] $c]
		    }
		    "m" {
			# When there are more choices than can be diplayed
			# on the statusline pressing 'm', will get the next
			# set of choices
			if {[string match "*mÉ" $currChoiceSet]} {
			    set pickNum $pickNumOfStartIn([expr {$currChoiceSet_idx +1}])
			}
			if {[string match "*bÉ" $currChoiceSet]} {
			    set pickNum 1
			} 
			backwardDeleteWord
			elec::commandPrefix
			insertText [lindex $matches [expr {$pickNum -1}]]
			# Set things up so we cylce to the next choice
			set c "\t"
			continue
		    }
		    "b" {
			# When there are more choices than can be diplayed
			# on the statusline pressing 'b', will get the
			# first set of choices
			set pickNum 1
			set c "\t"
			backwardDeleteWord
			elec::commandPrefix
			insertText [lindex $matches [expr {$pickNum -1}]]
			#set things up so we cylce to the next choice
			continue
		    }
		    "esc" {
			# When you want to bypass this and get to
			# acronymExpansion
			backwardDeleteWord
			insertText $cmd
			return 0
		    }
		    "default" {
			# See if c is, or can be converted to, a number in
			# the range 1-9
			set strPos [string first $c "asdfghjkl123456789"]
			if {$strPos == -1} {
			    beep
			    return
			}
			set numberChoosen [expr {$strPos % 9}]
			if {$numberChoosen > [llength $possMatches]} {
			    beep
			    return
			} 
			# alertnote "you choose number $numberChoosen"   
			set returnedMatch [lindex $possMatches [expr {$pickNumOfStartIn($currChoiceSet_idx) + $numberChoosen -1}]]
		    }
		}
		# catch {statusPrompt -f $choices statusLineChooser}
		if {$returnedMatch != ""} {
		    backwardDeleteWord
		    elec::commandPrefix
		    insertText $returnedMatch
		    return $returnedMatch                               
		} 
	    }
	}
	return ""
    }
}

proc elec::commandPrefix {} {
    
    global mode
    
    switch -- $mode {
	"TeX" {
	    set pos [getPos]
	    set bol [getText [lineStart $pos] $pos]
	    switch -glob $bol {
		"*\\begin\{" -
		"*\\end\{" - 
		"*\\" {
		    return
		}
		"default" {
		    insertText "\\"
		}
	    }
	}
    }
}
                                        
proc elec::searchPat {wordStarters} {
    
    set identifierLeader {(_|__)?}
    set wordTail {[a-z0-9]*}
    set identifierTail {[a-zA-Z0-9_]*}
    
    set idx_Last [expr {[string length $wordStarters]-1}]
    if {$idx_Last>2} {set idx_Last 2}
    
    set searchPat  $identifierLeader
    set    firstPost [string index $wordStarters 0]
    append searchPat [format "(%s|%s)" [string toupper $firstPost] $firstPost]
    append searchPat $wordTail
    
    for {set i 1} {$i < $idx_Last} {incr i} {
	set    fencePost [string index $wordStarters $i]
	append searchPat [format {(%1$s|_%1$s|_%2$s)} [string toupper $fencePost] $fencePost]
	append searchPat $wordTail
    }
    set    fencePost [string index $wordStarters $i]
    append searchPat [format {(%1$s|_%1$s|_%2$s)} [string toupper $fencePost] $fencePost]
    append searchPat $identifierTail
    return $searchPat
}

## 
 # ==========================================================================
 #      
 # ×××× HISTORY ×××× #
 #                   
 #  Based on wordCompetion.tcl
 #   
 #  Originally composed by Mark Nagata for Alpha 5.76, 4/22/94.
 #  Modified by Tim van der Leeuw (tnleeuw@cs.vu.nl), 9/14/94.
 #  Modified by Tom Fetherston
 # 
 #  modified who rev   reason
 #  -------- --- ----- ------
 #  07/05/96 trf 1.0   Original
 #  07/11/96 trf 1.1   Allow expansion of hint prefixed with non-alphabetic
 #                       character(s).
 #                     Ensure Hit used is followed with only one space.
 #  07/12/96 trf 1.2   Allow hint to be suffixed with certain puncuation marks
 #                       and still be expanded. 
 #                     Added hint check.
 #  07/14/96 trf 1.3   Work around for regexp to include a close bracket
 #  07/14/96 trf 1.4   Changed previous hit to a list of previous hits so hits
 #                       would be offered only once.
 #  12/30/96 trf 1.5   Modified so that this could be integrated with
 #                       Vince Darley's Completion package.
 #  05/14/97 VD  1.6   Changed proc names to reflect new naming scheme.
 #  05/22/97 trf 1.7   Removed uses of 'oneSpace', this messed up stop locations. 
 #  02/12/97 trf 9.0b3 Made changes to fix TeX expansions, bumped to 9.0b3.
 #  04/12/97 VMD 9.0.1 various fixes, better tcl8 compatibility
 #  10/19/00 cbu 9.0.4 Added 'Electric Completions' menu for global completions.
 #  04/08/01 cbu 9.0.5 Improved 'Electric Completions' menu dialogs.
 #  06/07/01 cbu 9.1   Changes to Mode Tutorials, different behavior for end
 #                       of completions cycle added to 'completions.tcl'.
 #                     Cleanup of expansion::acronym.
 #                     Spaces no longer automatically inserted after expansion.
 #                     Package is now a global-only feature, to allow for a
 #                       de-activation script.
 #  07/11/01 cbu 9.1.1 Removed dependency on -1.0 as a position.
 #  11/27/04 cbu 9.1.3 Resetting expansion position variables no longer uses
 #                       [minPos] as the indicator, but the null string.
 #  
 # ==========================================================================
 ##

# ===========================================================================
# 
# .