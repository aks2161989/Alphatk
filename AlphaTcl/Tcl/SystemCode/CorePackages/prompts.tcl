## -*-Tcl-*-
 # ###################################################################
 #  AlphaTcl - core Tcl engine
 # 
 #  FILE: "prompts.tcl"
 #                                    created: 27/1/98 {11:14:34 am} 
 #                                last update: 10/20/2004 {12:20:23 PM} { 2:11:10 PM} 
 #  Author: Vince Darley
 #  E-mail: <vince@santafe.edu>
 #    mail: 317 Paseo de Peralta
 #          Santa Fe, NM 87501, USA
 #     www: <http://www.santafe.edu/~vince/>
 #  
 # Copyright (c) 1998-2004  Vince Darley
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # General purpose status-line completion procedures.  Currently
 # used by Tcl, TeX and Bib modes.  
 # 
 # Also contains a set of procedures for prompting the user
 # for _small_ pieces of information, with validation of type
 # for values entered.
 # ###################################################################
 ##

# auto-loading extension.
alpha::extension prompts 0.1.4 {
} description {
    Provides general purpose status-line completion procedures for use by
    other AlphaTcl code
} help {
    This package is for AlphaTcl developers, and provides general purpose
    status-line completion procedures.  It is currently used by Tcl, TeX and
    Bib modes, so you can check out their usage for real-world examples.  It
    also contains a set of procedures for prompting the user for _small_
    pieces of information, with validation of type for values entered.
    
    See the "prompts.tcl" file for more information about what's available.
}

namespace eval prompt {}

proc prompt::general {msg def} {
    global useStatusBarForPrompts
    if {$useStatusBarForPrompts} {
	if {[catch {statusPrompt "$msg ($def): "} ans]} {
	    error "cancel"
	}
	if {![string length $ans]} {return $def}
	return $ans
    } else {
	return [prompt $msg $def]
    }
}

# ×××× Status line completion ×××× #

## 
 # -------------------------------------------------------------------------
 # 
 # "prompt::fromChoices" --
 # 
 #  Prompt the user, with completion, for one item out of a given list. 
 #  The list can either be explicit (-list items), derived from a command
 #  (-command cmdReturnsList), or in a variable (-variable listvar).
 #  
 # -------------------------------------------------------------------------
 ##
proc prompt::fromChoices {msg def type choices} {
    global useStatusBarForPrompts
    if {$useStatusBarForPrompts} {
	return [prompt::statusLineComplete $msg \
	  [list completion::fromChoices $type $choices] -default $def]
    } else {
	return [listpick -p $msg -L [list $def] \
	  [completion::getChoices $type $choices]]
    } 
}

## 
 # -------------------------------------------------------------------------
 # 
 # "prompt::statusLineComplete" --
 # 
 #  Optional flags this proc can take
 #  
 #  -nobackup             : can't use left-arrow to remove a char
 #  -nocache              : don't cache the list of completions 
 #  -nomatchiserror       : if nothing matches, we abort
 #  -initialpatt <string> : start with this string
 #  -preeval <script>     : evaluate this script first at global scope
 #  -posteval <script>    : evaluate this script afterwards at global scope
 #  -tryuppercase         : if we have no matches, check if the user was
 #                          too lazy to use the shift key!
 #  -autocomplete         : always expand the maximum amount from what
 #                          the user has typed.
 # -------------------------------------------------------------------------
 ##
proc prompt::statusLineComplete {what completeWith args} {
    global __keysSoFar __startIndex __lastMatchesDisplayed __lastMatches __tabSoFar

    set __keysSoFar {}
    set __startIndex 0
    set __lastMatchesDisplayed {}
    set __tabSoFar 0
    
    unset -nocomplain __lastMatches
    
    status::msg ""
    set patt ""
    
    getOpts [list -autocomplete -preeval -posteval -initialpatt -default]
    if {[info exists opts(-initialpatt)]} {
	set patt $opts(-initialpatt)
    }
    set pos [getPos]
    
    if {[info exists opts(-preeval)]} {
	catch {uplevel \#0 $opts(-preeval)}
    }
    if {[info exists opts(-default)]} {
	set pr "${what} ($opts(-default)): $patt"
    } else {
	set pr "${what}: $patt"
    }
    catch {status::prompt -f -appendvar patt -command prompt::_complete -add anything $pr}
    if {[info exists opts(-posteval)]} {
	catch {uplevel \#0 $opts(-posteval)}
    }
    if {[info exists __lastMatches]} {
	unset __lastMatches
    }
    # we're done
    if {[info exists __completed]} {
	return $__completed
    }
    status::msg "Cancelled: $patt"
    goto $pos
    error "Cancelled: $patt"
}

## 
 # -------------------------------------------------------------------------
 # 
 # "prompt::_complete" --
 # 
 # Summary: 
 # 
 #      Hit 'space' or 'return' or '1' to hit the first completion in
 # the list, 2-9 to select subsequent ones, 'tab' to scroll the list,
 # or any character to complete further.  Hit 'left-arrow' to delete
 # a character from the current entry.  You can also use 'delete' to
 # delete a character, except it's not shown in the display until you
 # add a character.  This is a limitation of Alpha.
 # 
 # Details:
 # 
 #  The mods to this proc are along the lines of the proc that provides 
 #  acronym-epansion in latex. Here you just type and get a list in the 
 #  statusline of all the commands known to tcl that start with whatever 
 #  you have typed so far. Whenever the set of commands share a common 
 #  prefix that goes beyond what you have typed the "letters-entered" 
 #  portion of the statusline advances to include all the common letters 
 #  (this means you have to be careful you don't re-enter them manually, as 
 #  that will likely abort entry as no command will match).
 #  
 #  Once you have started entering characters, you are presented with the 
 #  number of known cammands that start with those characters followed by 
 #  a horizontal listing of as many of those commands that will fit on the 
 #  line. These commands are separated by double spaces in order to make 
 #  commands stand out as a whole to the eye (command with "::" in them 
 #  are harder for the eyes to parse without this).
 #  
 #  At this point you either keep entering characters to narrow the matching 
 #  commands, type a tab to scroll through the horizontal list, or type a 
 #  numeral that corresponds to the position one of the visible commands in 
 #  the horizontal list (which will then be looked-up).
 #  
 #  If you just keep entering characters till you narrow the list to one 
 #  command, you might get down to a situation where the command you want 
 #  out of the matches is contained in all the other matches. When this 
 #  happens all you have to do is to type a <space> and you will look-up 
 #  that command.
 #  
 #  To make things easier, whenever a character is entered that would abort 
 #  the procedure, it is first checked to see if the upperCase version of 
 #  tht character would not keep us for aborting. For example, if you had 
 #  'pageÉ' as the entered portion, your list would be: 
 #  (pageBackward  pageForward  pageSetup), so entering 'B' or 'b' would 
 #  lookup pageBackward for you.
 #  
 #  ToDo: 
 #  ¥ provide cushioning/alerting mechanism against aborting when the user 
 #  does not notice that entered portion has been automatically extended. 
 #  Perhaps, flash the statusline and color the automatically entered 
 #  portion, and/or allow the rentering of the auto-entered portion. 
 #  Of course insertColorEscape does not work in the statusline, but 
 #  perhaps it would be possible figure out the escapes and enter them 
 #  as literals via message.
 #  ¥ perhaps alter this so you have the option of deleting characters 
 #  instead of aborting when you get no matches.
 #  ¥ perhaps provide a variant that inserts the found procName into your 
 #  current cursor position instead of doing a look-up.
 #  
 #  Note: made one change, moved the "number found:" portion of the prompt 
 #  outside the horizontal list so it is easy to visually parse the list 
 #  to determine what nember to hit to make a choice from the list.
 #  
 #  Author: mostly Tom Fetherston; Vince made the proc a little more
 #  general so it is now used by C++, Tcl and Bib modes.
 # -------------------------------------------------------------------------
 ##
proc prompt::_complete {{key 0} {mod 0}} {
    global __keysSoFar __startIndex __lastStartIndex __lastMatchesDisplayed __tabSoFar

    set t [keys::modToString $mod]

    upvar 1 opts opt
    upvar 1 patt pat
    upvar 1 completeWith compP
    upvar 1 what whatP
    if {![info exists opt(-nocache)]} {
	global __lastMatches
    }
    set curr $pat

    if {[string length $key]} {
	scan $key %c decVal
    } else {
	# No key showed up.  Probably running on Alphatk
	error "no key press"
    }

    switch -- $t {
	"____" -
	"_s__" {
	    switch -- $decVal {
		1 { beginningOfBuffer;  error "navigation key"; # home; }
		4 { endOfBuffer;  error "navigation key"; # end; }
		11 { pageBack;  error "navigation key"; # page up; }
		12 { pageForward;  error "navigation key"; # page down; }
		30 { previousLine; error "navigation key"; # up arrow; }
		31 { nextLine; error "navigation key"; # down arrow; }
		27 { error "abort (esc key)"; # escape; }
		9 {
		    if {$__tabSoFar} {
			# Double-tab = go to a list-pick
			set __lastMatches [list [listpick -p "Choose..." $__lastMatches]]
			set key ""
		    } else {
			# Tab = complete
			set complete 1
			set key ""
		    }
		}
		29 {
		    set __lastStartIndex $__startIndex 
		    if {![info exists __lastMatches]} {
			set __lastMatches [lsort [eval $compP [list $pat]]]
		    }
		    set msg "$whatP '${pat}É' ($__lastMatches)"
		    if {[string length $msg] > 80} {
			set numFound [llength $__lastMatches]
			set nextIdx [expr {$__startIndex + 1}]
			set msg "$whatP '${pat}É' $numFound found: ([lindex $__lastMatches $__startIndex] É Ètab"
			while {($nextIdx < $numFound) && ([string length "$msg  [lindex $__lastMatches $nextIdx]"] <= 80)} {
			    set matchesDisplayed [lrange $__lastMatches $__startIndex $nextIdx]
			    incr nextIdx
			    if {$nextIdx >= $numFound} {
				set more ""
			    } else {
				set more "É"
			    } 
			    if {$__startIndex == 0} {
				set start ""
			    } else {
				set start "É"
			    } 
			    set msg "$whatP '${pat}É' $numFound found: ($start $matchesDisplayed $more) Ètab"
			}
			if {$nextIdx >= [expr {$numFound}]} {
			    set __lastStartIndex $__startIndex 
			    set __startIndex 0
			} else {
			    set __lastStartIndex $__startIndex 
			    set __startIndex [expr {$nextIdx}]
			}
		    }
		    status::msg $msg
		    set __lastMatchesDisplayed $matchesDisplayed
		    return " "
		}
		28 - 8 {
		    if {![info exists opt(-nobackup)]} {
			set __keysSoFar $pat
			set oldNumFound [llength $__lastMatches]
			set numFound $oldNumFound
			if {![info exists remove]} {set remove 1}
			# make sure we remove enough chars so that we
			# actually add some more choices!
			while {$remove > 0 || ($numFound <= $oldNumFound && $__keysSoFar != "")} {
			    set __keysSoFar [string range $__keysSoFar 0 [expr {[string length $__keysSoFar] -2}]]
			    set __lastMatches [eval $compP [list $__keysSoFar]]
			    set numFound [llength $__lastMatches]
			    incr remove -1
			}
			set __lastMatches [lsort $__lastMatches]
			set pat $__keysSoFar
			set key ""
		    } else {
			error ""
		    }
		}
		10 - 13 {
		    if {![llength $__lastMatchesDisplayed] && [info exists opt(-default)]} {
			set __lastMatches [list $opt(-default)]
		    } else {
			set __lastMatches [list [lindex $__lastMatchesDisplayed 0]]
		    }
		}
		default {
		    if {[catch [list prompt::_updateLastMatches $compP $__keysSoFar$key] __lastMatches]} {
			error "Thrown in prompt::_complete $__lastMatches"
		    }
		    # If its a numerical key or the space bar, and it wasn't a valid
		    # extension of the current item
		    if {![llength $__lastMatches] && [regexp {[ 1-9]} $key]} {
			if {$key == " "} { set key 1 }
			# we hit 1-9 and are trying to select that item in 
			# the list displayed
			if {$key <= [llength $__lastMatchesDisplayed]} {
			    set __lastMatches [list [lindex $__lastMatchesDisplayed [expr {$key -1}]]]
			} else {
			    if {![llength $__lastMatchesDisplayed] && [info exists opt(-default)]} {
				set __lastMatches [list $opt(-default)]
			    } else {
				error ""
			    }
			} 				
		    }
		}
	    }
	}
    }
    
    if {![info exists __lastMatches]} {
	error "Please report a bug.  Code shouldn't get here"
    }

    set numFound [llength $__lastMatches]
    if {!$numFound} {
	# first we'll see if the user was just too lazy to shift the key
	if {[info exists opt(-tryuppercase)]} {
	    set __lastMatches [prompt::_updateLastMatches $compP $__keysSoFar[string toupper $key]]
	    set numFound [llength $__lastMatches]
	}
    } 
    append __keysSoFar $key
    set pat $__keysSoFar
    switch -- $numFound {
	0 {
	    if {![info exists opt(-nomatchiserror)]} {
		status::msg "$whatP '${pat}É' NO MATCHES!!"
		return " "
	    } else {
		error "No matches"
	    }
	}
	1 {
	    set pat [lindex $__lastMatches 0]
	    status::msg "$whatP -- '$pat'"
	    upvar 1 __completed c
	    set c $pat
	    error "done"
	}
    }
    if {[info exists complete] || [info exists opt(-autocomplete)]} {
	set pat [largestPrefix $__lastMatches]
	set __keysSoFar $pat
	set __tabSoFar 1
    } else {
	set __tabSoFar 0
    }
    
    set matchesDisplayed $__lastMatches
    set msg "$whatP '${pat}É' ($matchesDisplayed)"
    if {[string length $msg] > 80} {
	set matchesDisplayed [lindex $__lastMatches 0]
	set nextIdx 1
	set msg "$whatP '${pat}É' $numFound found: ($matchesDisplayed É) Ètab"
	while {($nextIdx < $numFound) && ([string length "$msg [lindex $__lastMatches $nextIdx]"] <= 80)} {
	    append matchesDisplayed "  " [lindex $__lastMatches $nextIdx]
	    incr nextIdx
	    set msg "$whatP '${pat}É' $numFound found: ($matchesDisplayed É) Ètab"
	}
	if {$nextIdx > [expr {$numFound}]} {
	    set __lastStartIndex $__startIndex 
	    set __startIndex 0
	} else {
	    set __lastStartIndex $__startIndex 
	    set __startIndex [expr {$nextIdx -1}]
	}
	
    } 
    set __lastMatchesDisplayed $matchesDisplayed
    status::msg $msg 
    return ""
}

## 
 # -------------------------------------------------------------------------
 # 
 # "prompt::_updateLastMatches" --
 # 
 #  Helper for the above procedure.  Needs documenting.
 # -------------------------------------------------------------------------
 ##
proc prompt::_updateLastMatches {compP str} {
    global __lastMatches
    if {![info exists __lastMatches]} {
	set res [lsort [eval $compP [list $str]]] 
    } else {
	set res [completion::fromList $str __lastMatches]
    }
    if {[info exists __lastMatches]} {
	set __lastMatches $res
    } 
    return $res
}

# ×××× Simple dialogs/prompts ×××× #

## 
 # -------------------------------------------------------------------------
 # 
 # "prompt::var" --
 # 
 #  Ask for value for a single variable.  Forces calling proc to return
 #  if value isn't ok, or procedure is cancelled.
 # -------------------------------------------------------------------------
 ##
proc prompt::var {prompt var {def ""} {testproc ""} {desired 1} {errmsg ""}} {
    global promptNoisily useStatusBarForPrompts
    if {$promptNoisily && $useStatusBarForPrompts} {beep}
    upvar 1 $var vvar
    if {$useStatusBarForPrompts} {
	if {[catch {statusPrompt "$prompt ($def): "} vvar]} {
	    return -code return
	}
	if {![string length $vvar]} {
	    set vvar $def
	}
    } else {
	if {[catch {prompt $prompt $def} vvar]} {
	    return -code return
	}
    }
    if {$testproc != ""} {
	if {[$testproc $vvar] != $desired} {
	    beep
	    status::msg $errmsg
	    return -code return
	}
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "prompt::simple" --
 # 
 #  Prompt for a few variable values, with entry-validation.  Example
 #  usage:
 #  
 #  	prompt::simple \
 #  	  [list "how many rows?" numberRows 2 N] \
 #	      [list "how many columns?" numberColumns 2 N]
 #
 #  Which either throws an error, or ensures the variables 'numberRows'
 #  'numberColumns' are set to Natural numbers, with defaults of '2'.
 # -------------------------------------------------------------------------
 ##
proc prompt::simple {args} {
    global promptNoisily useStatusBarForPrompts
    if {$useStatusBarForPrompts} {
	set i 0
	while 1 {
	    set v [lindex $args $i]
	    if {[llength $v] <= 1} {
		set args [lrange $args $i end]
		break
	    }
	    upvar 1 [lindex $v 1] _v$i
	    if {$promptNoisily} {beep}
	    set def [lindex $v 2]
	    if {[catch {statusPrompt "[lindex $v 0] ($def): "} _v$i]} {
		return -code return
	    }
	    if {![string length [set _v$i]]} {
		set _v$i $def
	    }
	    set _check$i [lrange $v 3 end]
	    if {[set _check$i] != ""} {
		if {[catch {eval entry::validate \
		  [list [set _v$i]] [set _check$i]}]} {
		    continue
		} 
	    }
	    incr i
	}
    } else {
	set i 0
	set y 40
	set dialog ""
	while 1 {
	    set v [lindex $args $i]
	    if {[llength $v] <= 1} {
		set args [lrange $args $i end]
		break
	    }
	    upvar 1 [lindex $v 1] _v$i
	    lappend dialog "-t" [lindex $v 0] 10 $y 180 [expr {$y + 18}] \
	      -e [lindex $v 2] 220 $y 240 [expr {$y + 18}]
	    incr y 30
	    set _check$i [lrange $v 3 end]
	    incr i
	}
	# now args contains just the options
	getOpts {-title}
	if {[info exists opts(-title)]} {
	    set title [list -t $opts(-title) 20 10 440 30]
	} else {
	    set title [list -t "Please enter the following:" 20 10 440 30]
	}
	while 1 {
	    set buttons [dialog::okcancel -460 y]
	    set res [eval [concat dialog -w 480 -h $y $title \
	      $buttons $dialog]]
	    if {[lindex $res 1]} { error "cancel" }
	    set OK 1
	    for {set j 0} {$j < $i} {incr j} {
		set _v$j [string trim [lindex $res [expr {2+$j}]]]
		if {[set _check$j] != ""} {
		    if {[catch {eval entry::validate \
		      [list [set _v$j]] [set _check$j]}]} {
			set OK 0
			break
		    } 
		}
	    }
	    if {$OK} { break }
	}
    }
    return
}
namespace eval entry {}

## 
 # -------------------------------------------------------------------------
 # 
 # "entry::validate" --
 # 
 #  Check if {$val} is of the given type, if the type is unrecognised, it
 #  is assumed to be a procedure we call, and check if the result of
 #  that procedure is either 1 or the first element of args if such
 #  an element was given.
 #  
 #  Therefore
 #  
 #    entry::validate $x Z
 #    entry::validate $x is::Integer
 #    entry::validate $x is::Integer 1
 #    
 #  are all equivalent.
 # -------------------------------------------------------------------------
 ##
proc entry::validate {val type args} {
    switch -- $type {
	"N" - "Z+" {
	    if {![is::PositiveInteger $val]} {
		dialog::errorAlert "invalid input '$val':  unsigned, positive integer required"
	    }
	}
	"Z" {
	    if {![is::Integer $val]} {
		dialog::errorAlert "invalid input '$val':  integer required"
	    }
	}
	"bool" {
	}
	"R" {
	    if {![is::Numeric $val]} {
		dialog::errorAlert "invalid input '$val':  real number required"
	    }
	}
	default {
	    set check [eval $type [list $val]]
	    if {$check != [expr {[llength $args] == 0 ? 1 : [lindex $args 0]}]} {
		dialog::errorAlert "invalid input '$val'"
	    }
	}
    }
}


