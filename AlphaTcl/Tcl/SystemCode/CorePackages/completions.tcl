## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "completions.tcl"
 #                                          created: 07/27/1997 {12:43:41 am}
 #                                      last update: 03/21/2006 {01:16:19 PM}
 # 
 # Description:
 # 
 # Basic parts of the completion package to handle word and file completion,
 # but allowing very simple piggy-backing of advanced completions.
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 #      
 # Copyright (c) 1997-2006 Vince Darley.
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # Changes 18/02/2003 (J.K.): removed these optional arguments, no longer
 # used: -mustMatch, -insertHook, -postInsertHook.  New option to
 # completion::general:  -word 0 
 # 
 # ===========================================================================
 ##

proc completions.tcl {} {}

namespace eval bind {}

## 
 # -------------------------------------------------------------------------
 #       
 # "bind::Completion" --
 #      
 # If we're already completing, jump to that procedure, else go through
 # a mode-dependent list of completion procedures given by the array
 # 'completions', these return either '1' to indicate termination, or
 # '0' to say either that they failed (or that they succeeded in a
 # simple unique way and that further completion procedures may be
 # applied).
 # 
 # Procedures which succeed, but may allow further completion
 # possibilities if the user presses the completion binding again (e.g.
 # a variety of possible word completions may exist) should call
 # 'completion::action' with an appropriate '-repeatCommand' flag
 # with the follow up procedure.
 #       
 # If no mode-dependent procedure list exists (as in a basic Alpha
 # installation), then just the 'user' completions and 'word'
 # completions are attempted.
 #       
 # The list of procedures to try is copied into 'completion::chain', so
 # completion procs can modify that list if they like.
 # 
 # The 'completion' helper proc is used to translate from an entry
 # in the completion(mode) array to an actual procedure call.
 # 
 # The completion procedures which are called should not, in general,
 # modify the contents of the window.  Instead, they should call
 # 'completion::action' to carry out any actual modifications.
 # 
 # -------------------------------------------------------------------------
 ##

proc bind::Completion {} {
    if {![win::checkIfWinToEdit]} {return}
    if {![completion::tabDeleteSelection]} {return}
    
    if {[completion::noCompletionInProgress]} {
	if {[completion::user]} {return}
	global completions mode completion::chain
	if {[info exists completions($mode)]} {
	    set completion::chain $completions($mode)
	    while 1 {
		if {[set c [lindex ${completion::chain} 0]] == ""} {break}
		set completion::chain [lreplace ${completion::chain} 0 0]
		if {[completion $mode $c]} {return}
	    }
	    status::msg "No further completions exist, perhaps you\
	      should write your own."
	} else {
	    completion::word
	}
    }
}

## 
 # -------------------------------------------------------------------------
 #       
 # "completion" --
 # 
 # Call a completion, by trying in order:
 #    1) error
 #    2) 'Type' is actually a generic completion routine
 #    3) '${mode}::Completion::${Type}' is a mode-specific routine
 #    4) 'completion::${type}' is a generic routine.
 #    
 # We also check for expansion procedures of the forms:
 #    1) 'expansions::${type}'
 #    2) '${mode}::Expansion::${Type}', where Type begins with 'Ex'
 #
 # -------------------------------------------------------------------------
 ##

proc completion {mode Type args} {
    #puts [list $mode $Type $args]
    if { $Type == "error" } {error ""}
    if {[regexp {^(completion|expansions)::} $Type]} {
	return [eval $Type $args]
    } elseif {[llength [info commands ${mode}::Completion::${Type}]]} {
	return [eval ${mode}::Completion::${Type} $args]
    } elseif {[llength [info commands ${mode}::Expansion::${Type}]]} {
	return [eval ${mode}::Expansion::${Type} $args]
    } else {
	return [eval completion::[string tolower $Type] $args]
    }
}

namespace eval completion {}

# Setup this variable to say no completions are in progress.
ensureset completion::in_progress 0

## 
 # -------------------------------------------------------------------------
 #       
 # "completion::noCompletionInProgress" --
 #      
 # Call this to check if we should divert directly to a previously
 # registered completion procedure instead of starting from scratch.
 # 
 # If we should start from scratch, we just initialise a few global
 # variables and return '1'.
 # 
 # If we are continuing (and if the position hasn't changed at all), 
 # we evaluate the stored script: that returns either 1 or 0.  In the
 # latter case there are no more completions (so we select some text
 # and give a message).  In the former case we found some (and presumably
 # called completion::action to update the display appropriately).
 # 
 # If the script throws an error, we effectively ignore its existence
 # and the entire proc resets the completions and returns 1.
 #   
 # -------------------------------------------------------------------------
 ##
proc completion::noCompletionInProgress {} {
    global completion::in_progress_proc completion::in_progress_pos \
      completion::in_progress completion::original_position

    # Do the old completion if possible
    if {[set completion::in_progress]} {
	if {[pos::compare ${completion::in_progress_pos} == [getPos]]} {
	    # An existing completion is in progress.  Call the script
	    # which was registered to continue that completion.
	    
	    #puts "repeat ${completion::in_progress_proc}"
	    if {![catch {eval ${completion::in_progress_proc}} res]} {
		if {$res == 1} {
		    # We completed successfully; so tell our caller that
		    # there is a completion in progress
		    return 0
		} else {
		    # We failed.  This means we've actually run out of
		    # completions in this continuation.  We highlight
		    # the currently completed text so the user can
		    # easily delete it if they want to.
		    selectText ${completion::original_position} \
		      ${completion::in_progress_pos}
		    status::msg "All possible completions have been cycled."
		    # We don't want to start a new completion mechanism,
		    # so tell our caller to stop now.
		    return 0
		}
	    }
	}
    }
    # No completion is in progress, or an error resulted above.
    # We therefore reset everything.
    completion::reset
    return 1
}

proc completion::reset {} {
    global completion::in_progress_proc completion::in_progress_pos \
      completion::in_progress completion::original_position

    set completion::in_progress 0
    set completion::in_progress_proc error
    set completion::in_progress_pos [getPos]
    unset -nocomplain completion::original_position
    return
}

## 
 # -------------------------------------------------------------------------
 #       
 # "completion::action" --
 #      
 # Any completion procedure which is successful should call this. It is
 # best to call this rather than inserting/deleting text manually.
 # 
 # Current flags are:
 # 
 # -delete <len>:  number of chars before current cursor position to delete
 # -text <text>:   insert this text at the current position
 # -electric:      if given, then text insertions are via 'elec::Insertion' and
 #                 may therefore contain various tab stops.
 # -msg <msg>:     give this message in the status bar.
 # 
 # -repeatCommand <script>: command to be evaluated if the user asks for another
 #                 completion (provided the window/position have not been 
 #                 changed).  If this is not given, then the other flag
 #                 actions will still be taken, and it is assumed this
 #                 is a completion which cannot be 'cycled' through numerous
 #                 options in any way.
 # 
 # -------------------------------------------------------------------------
 ##
proc completion::action {args} {
    global completion::in_progress_proc completion::in_progress_pos \
      completion::in_progress completion::original_position

    #puts "success $args"
    getOpts {-delete -text -repeatCommand -msg}
    # Just in case the completion messed with the position
    goto [set completion::in_progress_pos]
    # Delete anything we were asked for
    if {[info exists opts(-delete)]} {
	if {$opts(-delete) != 0} {
	    deleteText [pos::math [getPos] - $opts(-delete)] [getPos]
	}
    }
    if {![info exists completion::original_position]} {
	set completion::original_position [getPos]
    }
    # Insert the new text
    if {[info exists opts(-electric)]} {
	elec::Insertion $opts(-text)
    } else {
	insertText $opts(-text)
    }
    # And give a message
    if {[info exists opts(-msg)]} {
	status::msg $opts(-msg)
    }
    # Now store anything required for a second go around, if that is wanted...
    if {[info exists opts(-repeatCommand)]} {
	set completion::in_progress_proc $opts(-repeatCommand)
	set completion::in_progress_pos  [getPos]
	set completion::in_progress      1
    } else {
	completion::reset
    }
    return 1
}

# This should really NOT be used.  We need to make the procs in
# this file sufficiently general so that it isn't required!
proc completion::_insert {text} {
    global completion::in_progress_pos
    insertText $text
    set completion::in_progress_pos [getPos]
}

proc completion::user {{cmd ""}} {return 0}

proc completion::word {} {
    completion::general -- [completion::lastWord] 
}

## 
 # -------------------------------------------------------------------------
 # 
 # "completion::general ?opts? lookFor" --
 # 
 #  Look for completions for the given word '$lookFor', to be inserted
 #  at the current cursor position (which is actually stored in
 #  'completion::in_progress_pos').  We look backwards first, and then
 #  forwards.
 #  
 #  Acceptable syntax:
 #  
 #  completion::general ?-excludeBefore <len>? ?-pattern <pat>? \
 #    ?-word <0/1>?  lookFor
 #  
 #  The excludeBefore 'len' is the number of characters before the
 #  current insertion point in which matches are not acceptable (the
 #  idea is we want to match anything but what the user is currently
 #  typing!).  If not given, this will be calculated as the length of
 #  'lookFor', but it could be different.
 #  
 #  If 'pat' is given, then it is used as the pattern to be matched by
 #  any completion.  If it is not given then the current
 #  (mode-specific) 'wordBreak' value is used.
 #  
 #  When matches are found, any characters beyond 'lookFor' are
 #  considered an appropriate completion, and are sent to
 #  'completion::action' with appropriate other parameters.  This will
 #  generally insert those characters into the window.
 #  
 # -------------------------------------------------------------------------
 ##
proc completion::general {args} {
    set opts(-word) 1
    set opts(-excludeBefore) ""
    getOpts {-excludeBefore -word -pattern}
    if {[llength $args] != 1} {
	return -code error "Bad arguments"
    }
    
    set lookFor [lindex $args 0]
    set len [string length $lookFor]

    if {$opts(-excludeBefore) != ""} {
	set excludeBefore $opts(-excludeBefore)
    } else {
	set excludeBefore $len
    }
    
    # Exclude the current position as a match result!
    set origPos [getPos]
    set start [pos::math $origPos - $excludeBefore - 1]

    # We want to find anything else which looks like 'lookFor' and
    # continues a 'word'
    set pat [quote::Regfind $lookFor]    
    if {[info exists opts(-pattern)]} {
	append pat $opts(-pattern)
    } else {
	global wordBreak
	append pat $wordBreak
    }
    
    # Start the general completion mechanism.
    return [completion::generalRepeat $len $origPos $pat $start \
      0 "" $opts(-word)]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "completion::generalRepeat" --
 # 
 #  Helper procedure for 'completion::general'.
 #  
 #  Returns '1' on success, 0 otherwise.  Calls completion::action on 
 #  success as well.
 # -------------------------------------------------------------------------
 ##
proc completion::generalRepeat {len origPos pat nextStart fwd prevHits word} {
    global completion::in_progress_pos
    while 1 {
	if {![catch {search -s -f $fwd -r 1 -i 0 -m $word -- $pat $nextStart} data]} {
	    set Hit [eval getText $data]
	    set beg [pos::math [lindex $data 0] + $len]
	    set end [lindex $data 1]
	    
	    if {[lsearch -exact $prevHits $Hit] == -1} {
		# This Hit is not the same as the last one
		
		# Add the hit to the list of previous hits
		lappend prevHits $Hit
		
		set extraTxt [getText $beg $end]
		set deleteLen [pos::diff $origPos [getPos]]
		# Set the message before checking to adjust the
		# forwards/backwards flag.
		if {$fwd} {
		    set fndMsg "Found below."
		} else {
		    set fndMsg "Found above."
		}
		if {$fwd} {
		    # Search Forwards
		    set nextStart $end
		    # End of found word
		} else {
		    # Search Backwards
		    set nextStart [pos::math [lindex $data 0] - $len]
		    # Before start of found word
		    if {[pos::compare $nextStart <= [minPos]]} {
			set fwd 1
			set nextStart ${completion::in_progress_pos}
		    }
		}
		# Return point (1)
		return [completion::action -repeatCommand \
		  [list completion::generalRepeat $len $origPos \
		  $pat $nextStart $fwd $prevHits $word] \
		  -msg $fndMsg -text $extraTxt -delete $deleteLen]
	    } else {
		# Move start of search after finding string again
		if {$fwd} {
		    # Searching Forwards
		    set nextStart $end
		    # End of found word
		} else {
		    # Still Searching Backwards
		    set nextStart [pos::math [lindex $data 0] - $len]
		    # Before start of found word
		    if {[pos::compare $nextStart <= [minPos]]} {
			set fwd 1
			set nextStart ${completion::in_progress_pos}
		    }
		}
	    }
	    # End if hit is the same as a previous hit
	} else {
	    # Search string not found
	    if {$fwd} {
		# Return point (2) : We were already looking forward,
		# so the word is not in the file
		return 0
	    } else {
		# Start looking forward
		set fwd 1
		set nextStart ${completion::in_progress_pos}
	    }
	}
	# There are two ways we could have returned above.  Either
	# successfully (1), or we already searched forwards and backwards
	# and failed (2).  If we reach here, we're still trying to find
	# more matches.
    }
    # This is never reached.
    return 0
}

## 
 # -------------------------------------------------------------------------
 #       
 # "completion::lastWord" --
 #      
 # Return the last word, without moving the cursor.  If a variable name is
 # given, it is returned containing the position of the start of the last
 # word.
 #       
 # Future extensions to this proc (in packages) may include further
 # optional arguments. 
 # 
 # -------------------------------------------------------------------------
 ##

proc completion::lastWord {{st ""}} {
    set pos [getPos]
    backwardWord
    if {$st != ""} {upvar 1 $st beg}
    set beg [getPos]
    goto $pos
    set test1 [pos::compare $beg < [lineStart $pos]]
    set test2 [pos::compare $beg == $pos]
    if {$test1 || $test2} {
	return -code error "Cancelled -- could not find a hint."
    } else {
	return [getText $beg $pos]
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "completion::lastTwoWords" --
 # 
 # Get last two words: returns the previous word, and sets the given var to
 # the word before that.  Note that the 'word before that' actually means
 # all text from the start of that word up to the beginning of the word
 # which is returned.  i.e. 'prev' will normally end in some sort of
 # space/punctuation.
 #       
 # Future extensions to this proc (in packages) may include further
 # optional arguments. 
 # 
 # -------------------------------------------------------------------------
 ##

proc completion::lastTwoWords {prev} {
    set pos [getPos]
    backwardWord
    set beg_rhw [getPos]
    backwardWord
    set beg_lhw [getPos]
    goto $pos
    upvar 1 $prev lhw
    set test1 [pos::compare $beg_lhw < [lineStart $pos]]
    set test2 [pos::compare $beg_lhw == $beg_rhw]
    if {$test1 || $test2} {
	set lhw { } 
    } else {
	set lhw [getText $beg_lhw $beg_rhw]
    }
    return [getText $beg_rhw $pos]
}

## 
 # -------------------------------------------------------------------------
 #       
 # "completion::tabDeleteSelection" --
 #      
 # If there is a selection, this procedure is called by completion routines
 # to ask the user if it should be deleted (or if the appropriate flag is
 # set, to delete automatically). 
 # 
 # -------------------------------------------------------------------------
 ##

proc completion::tabDeleteSelection {} {
    global askDeleteSelection elecStopMarker

    if {([regexp "^\$|^$elecStopMarker" [getSelect]] || !$askDeleteSelection)} {
	deleteText [getPos] [selEnd]
    } else {
	switch [askyesno -c "Delete selection before continuing?"] {
	    "yes" 	{deleteText [getPos] [selEnd]}
	    "no"  	{goto [selEnd]}
	    "cancel"	{error "cancel"}
	}
    }
    return 1
}

## 
 # -------------------------------------------------------------------------
 #       
 # "completion::file" --
 #      
 #  Look back, see if there's a file/dir name and try and extend it. 
 #  Useful for Shel mode.  This improves on the one that comes with Alpha
 #  by default, and is much simpler. 
 #  
 # -------------------------------------------------------------------------
 ##

proc completion::filename {{dummy ""}} {
    global tcl_platform
    
    set pos0 [getPos]
    set pos1 [pos::math $pos0 - 1]
    set pat  "\[\"\{ \t\r\n\]"
    set res  [search -s -f 0 -i 0 -m 0 -r 1 -n -- $pat $pos1]
    if {[string length $res]} {
	set from [lindex $res 1]
	if {[pos::compare $from < $pos0]} {
	    set text [getText $from $pos0]
	    
	    # NB: replace '_fixGlob' with 'glob' when Tcl's core
	    # has been fixed (Tcl 8.4.7 or 8.5a2)
	    if {$tcl_platform(platform) ne "macintosh"} {
		set text [file normalize $text]
		if {[catch {_fixGlob -path $text *} globbed]} {
		    return 0
		}
	    } else {
		if {[catch {_fixGlob -path [file normalize $text] *} globbed]} {
		    if {[catch {_fixGlob -path [file normalize :$text] *} globbed]} {
			return 0
		    } else {
		        set text [file normalize :$text]
		    }
		} else {
		    set text [file normalize $text]
		}
	    }
	    # Now handle spaces
	    regsub -all -- " " $text "\\ " text
	    set matches [list]
	    foreach match $globbed {
	       regsub -all -- " " $match "\\ " match
	       lappend matches $match
	    }
	    # Let the completion mechanism take over.  Note that
	    # [completion::Find] is given complete paths to work with,
	    # even though the hint may be relative to [pwd] or to ~/ .
	    # But the difference computed should not depend on these
	    # expansions...  But if someday [completion::Find] decides
	    # that it will rather substitute the the complete hint with
	    # the complete match, then confusion will arise, since the
	    # hint may be really ~/bi while [completion::Find] thinks
	    # the hint is /Users/myself/bi...
	    completion::Find "$text" $matches
	    return 1
	}
    }
    return 0
}

proc completion::_fixGlob {dmy path {pat *}} {
    glob -- [quote::Glob $path]$pat
}

##
 # -------------------------------------------------------------------------
 #
 # "completion::Find" --
 #
 # Insert the completion of $cmd from the list $matches: it is assumed
 # that $matches is a list all of whose entries contain $cmd as prefix.
 # (The list is not required to be sorted.)
 #
 # This proc is called from these five procs:
 #  -- completion::filename, mpw::Completion::Lc, Mf::Completion::Input
 #     (and these do not use the return value at all),
 #  -- TeX::Completion::Env and completion::matchUtil (this last one is
 #     the important calling proc).
 #
 # J.K. (19/03/2003):  This version of completion::Find is an intermediate
 # version meant to be stable and conform to the same specifications as the
 # original (v.2002) in terms of return values (0, 1, $match, or "").
 #
 # (The next version will be part of a more comprehensive completion reform,
 # and it will have cleaner return value specifications.  (Solution A:
 # always return a string, the empty string meaning 'stop'.  Solution B:
 # always return 0 or 1, and pass the string $match implicitly, either by
 # placing it in a global variable, or via a new upvar'ed optional argument.))
 #
 # -------------------------------------------------------------------------
 ##


proc completion::Find {cmd matches } {
    global listPickIfMultCmps
    set cmdlen [string length $cmd]
    set match [largestPrefix $matches]
    set rest [string range $match $cmdlen end]


    if { [llength $matches] == 0 } {
	###### CASE 0: nothing to do ######
	return 1
    } elseif { [llength $matches] == 1 } {
	###### CASE 1: unique suggestion ######
	completion::action -text $rest -msg "Text is now a maximal completion."
	return $match
    } elseif { $listPickIfMultCmps } {
	###### CASE listpick ######  (in this case: no distinction 2,3,4)
	if {[catch {set match [listpick -p "Pick a completion" $matches]}] } {
	    status::msg "Cancelled"
	    return 1
	} else {
	    set rest [string range $match $cmdlen end]
	    completion::action -text $rest
	    return $match
	}
	# In the above cases we finished authoritatively, so it is safe to
	# let somebody else (Electric) continue expanding.
	# In the below cases, it is trickier do determine what we should do...
    } elseif { [lsearch -exact $matches $cmd] > -1 } {
	###### CASE 2: $cmd exists exactly in $matches ######
	set msg "Text is now a maximal completion."
    } elseif { $cmd eq $match } {
	###### CASE 3: $cmd = the largest prefix in $matches ######
	status::msg "Can't extend --- ${matches}"
	return ""
    } elseif {($cmd ne $match)} {
	###### CASE 4: $cmd shorter than largest prefix in $matches ######
	set msg "Matching: ${matches}"
	set match ""  ;# This is equivalent to returning 1: it means stop.
    }
    completion::action -text $rest -msg $msg
    return $match
}



# EXAMPLES:
# Case 1:  $cmd == \leftli
#          $mathces == { \leftline }
# Case 2:  $cmd == \left
#          $mathces == { \left \leftappenditem \leftarrow ... }
# Case 3:  $cmd == \le
#          $mathces == { \leadsto \left \leftappenditem  ... }
#                largest prefix is \le
# Case 4:  $cmd == \lef
#          $mathces == { \left \leftappenditem \leftarrow ... }
#                largest prefix is \left

proc completion::getChoices {type choices} {
    global [lindex [split $choices "\("] 0]

    switch -- $type {
	"-command"  {return [uplevel 1 $choices]}
	"-list"     {return $choices}
	"-variable" {return [set $choices]}
	default     {error "Bad option '$type' to completion::getChoices"}
    }
}

proc completion::fromChoices {type choices prefix} {
    switch -- $type {
	"-command" {
	    set matches {}
	    foreach w [uplevel 1 $choices] {
		if {[string match "[quote::Find $prefix]*" $w]} {
		    lappend matches $w
		}
	    }
	    return $matches
	}
	"-list" {
	    set matches {}
	    foreach w $choices {
		if {[string match "[quote::Find $prefix]*" $w]} {
		    lappend matches $w
		}
	    }
	    return $matches
	}
	"-variable" {
	    return [completion::fromList $prefix $choices]
	}
	default {error "Bad option '$type' to completion::fromChoices"}
    }
}

## 
 # -------------------------------------------------------------------------
 #       
 # "completion::fromList" --
 #      
 # Given a 'cmd' prefix and the name of a list to search, that list being
 # stored in alphabetical order, this proc returns a list of all matches
 # with 'cmd', or "" if there were none.  Updated so works with arrays
 # too (Nov'96)
 #       
 # It's quite an important procedure for completions, and must handle
 # pretty large lists, so it's worth optimising.
 # 
 # I'm sure we can improve this using Tcl 8.4's flags to 'lsearch',
 # (e.g. -sorted, -start).
 # -------------------------------------------------------------------------
 ##

proc completion::fromList { cmd listName } {
    global [lindex [split $listName "\("] 0]
    lsearch -inline -all -glob [set $listName] "[quote::Find $cmd]*"
}

# We should move to this version, but that will require API changes
# to the above (and other code?)
#proc completion::fromList { cmd listContents } {
#    lsearch -inline -all -glob $listContents "${cmd}*"
#}

# ===========================================================================
# 
# .