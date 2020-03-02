## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl support packages
 # 
 # FILE: "TclCompletions.tcl"
 #                                          created: 07/31/1997 {03:01:54 pm}
 #                                      last update: 03/16/2006 {03:05:34 PM}
 # Description:
 # 
 # Provides electric completion support in Tcl mode.  These routines can
 # extract information from the current Tcl interpreter to provide context
 # specific completion options based upon procedures/variables etc.  which
 # are currently recognized.  
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta
 #         Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 # 
 # Includes contributions from Craig Barton Upright
 # 
 # Copyright (c) 1997-2006  Vince Darley, Craig Barton Upright
 # All rights reserved.
 # 
 # ==========================================================================
 ##

proc TclCompletions.tcl {} {}

set completions(Tcl) {
    Preliminaries Contraction Colon ArrayElement LocalVar GlobalVar
    Proc Cmd Vvar Ensemble Electric Var Word
}
set completions(Shel) {
    Preliminaries Contraction Colon ArrayElement GlobalVar
    Proc Cmd Vvar Ensemble Electric Filename Var
}

# This line probably belongs in "tclMode.tcl".
lunion TclTemplates "createNewClass"

# ×××× Electric Colon, Left Paren ×××× #

prefs::removeObsolete ShelmodeVars(electricTripleColon)
prefs::removeObsolete ShelmodeVars(electricDblLeftParen)

##
 # -------------------------------------------------------------------------
 # 
 # "Tcl::electricTripleColon"  --
 # 
 # One rarely finds a string like ':::' in a Tcl file.  This procedure
 # allows such a string to trigger a special type of completion, one that
 # is specific to the context and the namespace of the surrounding text.
 # 
 # After typing a third consecutive ":", create and present a list of
 # possible completions based on this namespace, taking the context into
 # account to determine if this list should be composed of variables or
 # procedures.  If none are found, which might be the case if the Tcl
 # interpreter has not sourced anything pertaining to this namespace,
 # simply scan the current window for possible completions.
 # 
 # Note that this does NOT work for procs/variables in the global namespace.
 # 
 # Contibuted by Craig Barton Upright.
 # 
 # -------------------------------------------------------------------------
 ##

# To use ':' as an electric completion key, turn this item on.  Typing a
# third consecutive colon will trigger either a procedure or variable
# completion specific to the (non-global) preceding namespace|| To disable
# the use of ':' as an electric completion key, turn this item off
newPref flag electricTripleColon 0 Tcl

prefs::dialogs::setPaneLists "Tcl" "Editing" [list "electricTripleColon"]

Bind ':' Tcl::electricTripleColon Tcl

namespace eval Tcl {}

proc Tcl::electricTripleColon {} {
    
    global electricTripleColon
    
    typeText ":"
    # Should we continue?
    if {!$electricTripleColon} {
	return 0
    }
    completion::reset
    # If you wanted to invoke this after typing Tcl:: (e.g.), then remove
    # one of the ':' below.  This is, however, a little intrusive ...
    set pat1 {[^\s:"'\{$]:::}
    set txt1 [getText [pos::math [set pos0 [getPos]] - 4] $pos0]
    if {![regexp -- $pat1 $txt1]} {
	return 0
    } elseif {[Completion::Preliminaries] || ![Completion::Colon]} {
	status::msg "No further completions available."
	return 0
    } else {
	return 1
    }
}

##
 # -------------------------------------------------------------------------
 # 
 # "Tcl::electricDoubleLeftParen"  --
 # 
 # One rarely finds a string like '((' in a Tcl file.  This procedure allows
 # such a string to trigger a special type of completion, one that is
 # specific to the array name preceding the '(('.
 # 
 # After typing a second consecutive "(", create and present a list of
 # possible completions based on the preceding array name.  If none are
 # found, which might be the case if the Tcl interpreter has not sourced
 # anything pertaining to this array name, then do nothing.
 # 
 # Contibuted by Craig Barton Upright.
 # 
 # -------------------------------------------------------------------------
 ##

# To use '(' as an electric completion key, turn this item on.  Typing a
# second consecutive left parenthesis will trigger an array name completion
# if the context is appropriate, or add a closing right parenthesis if
# appropriate||To disable the use of '(' as an electric completion key, turn
# this item off
newPref flag electricDblLeftParen 0 Tcl

prefs::dialogs::setPaneLists "Tcl" "Editing" [list "electricDblLeftParen"]

Bind '(' Tcl::electricDoubleLeftParen Tcl

proc Tcl::electricDoubleLeftParen {} {

    global electricDblLeftParen
    
    typeText "\("
    # Should we continue?
    if {!$electricDblLeftParen} {
	return 0
    }
    completion::reset
    # Check to see if we should try an array name completion.
    set pat1 {([-a-zA-Z0-9:+_.]+)\(\($}
    set txt1 [getText [lineStart [set pos0 [getPos]]] $pos0]
    if {![regexp -- $pat1 $txt1]} {
	return 0
    } elseif {[Completion::Preliminaries] || [Completion::ArrayElement]} {
	return 1
    } elseif {[lookAt $pos0] != "\)"} {
	backSpace
	elec::Insertion "¥¥\)¥¥"
	return 1
    } else {
	status::msg "No further completions available."
	return 0
    }
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Completions ×××× #
# 
# Most of routines here attempt to distinguish procs from vars based upon the
# surrounding context, and in general are namespace savvy.  There might be
# some overlap amongst them, but that really isn't a problem because if any
# proc/var is 'discovered' in an earlier procedure that should start the
# others from ever being called.
# 

namespace eval Tcl::Completion {
    variable addToTclcmds      [list]
    variable interpCmd         [::Tcl::getInterp]
    variable electricCount     0
    variable lastInterpCmd     $interpCmd
    variable restoreElectrics  [list]
}

##
 # -------------------------------------------------------------------------
 # 
 # "Tcl::Completion::Preliminaries" --
 # 
 # All of the procs below will want access to some text, position variables.
 # This way we only have to perform [completion::lastWord] once.
 # 
 # When completing procs within namespaces, [Tcl::Completion::Proc] might
 # create temporary Tclelectrics array elements that we reset the next time
 # we're called.
 # 
 # Every 100th completion, we rebuild electrics.  This helps ensure that
 # any procs from files loaded after this file is first sourced will be
 # added to our lists.  The user can also rebuild electrics at any time by
 # using "Tcl Menu --> Tcl Editing --> Rebuild Tcl Electrics".
 # 
 # ------------------------------------------------------------------------
 ##

proc Tcl::Completion::Preliminaries {} {
    
    variable interpCmd
    variable lastInterpCmd
    variable TclInterpCmds
    
    # Create temporary text, position, context local variables.
    variable context [Context]
    # Clean up from previous completions (esp [Tcl::Completion::Proc]).
    variable restoreElectrics
    foreach cmd $restoreElectrics {
	unset -nocomplain ::Tclelectrics($cmd)
	Tcl::procElectrics $cmd
    }
    set restoreElectrics [list]
    # Add any new commands to the Tclcmds list.
    variable addToTclcmds
    if {[llength $addToTclcmds]} {
	set ::Tclcmds [concat $::Tclcmds $addToTclcmds]
	set ::Tclcmds [lsort -dictionary -unique $::Tclcmds]
	set TclInterpCmds($interpCmd) $::Tclcmds
	set addToTclcmds [list]
    }
    # Define the current interpreter's 'evaluate' command.  This should be
    # synchronized to the project of the current window.
    set interpCmd $::Tcl::interpCmd
    if {$interpCmd != $lastInterpCmd} {
	# Synchronize the 'Tclcmds' list to the current project.  If the
	# current interpreter never changes, this will never be called.
	if {![info exists TclInterpCmds($interpCmd)]} {
	    buildTclCmds
	} else {
	    set ::Tclcmds $TclInterpCmds($interpCmd)
	}
	set lastInterpCmd $interpCmd
    } 
    # Increment the count.
    variable electricCount
    if {[incr electricCount] >= 100} {Tcl::rebuildTclElectrics}
    return 0
}

##
 # -------------------------------------------------------------------------
 # 
 # "Tcl::Completion::Context" --
 # 
 # Determine if the surrounding context makes the text to be completed looks
 # like it should be a procedure or a variable/array.  Once a completion
 # routine has determined that it is the one that should be used, the
 # 'context' should be set to the null string to alert others that they
 # should abort quickly.  [Tcl::Completion::Cmd] doesn't do this, because we
 # want to be able to add additional completions, but we do want to avoid
 # calling that particular proc after others have done their thing.
 # 
 # [Tcl::Completion::Var] and [Tcl::Completion::Vvar] ignore the context
 # entirely (as well as 'txt1') because they are called very late in the
 # game, and need to perform their own special tests.
 # 
 # ------------------------------------------------------------------------
 ##

proc Tcl::Completion::Context {} {
    
    global Shel::endPrompt
   
    variable pos1
    variable nameSpace [Tcl::contextNamespace [getPos] 0]
    variable txt1      [completion::lastWord pos1]
    variable ElectricCommandOptions
    
    # Perform some initial tests.
    if {[string index $txt1 end] == " "} {
	return 0
    } elseif {[string index $txt1 0] == "$"}   {
	return "variable"
    }
    set pos0 [getPos]
    set txt2 [string trimright $txt1 ":"]
    if {[string length $txt2] < 3} {
	return ""
    }
    # Create some regexp patterns.
    set arrayWords [join $ElectricCommandOptions(array) "|"]
    set varWords   [join [list global set unset variable] "|"]
    set infoWords1 [join [list exists globals locals vars] "|"]
    set infoWords2 [join [list args body default commands procs] "|"]
    if {[Tcl::isShellWindow] && [info exists ::Shel::endPrompt]} {
	set sEP $::Shel::endPrompt
    } else {
	set sEP ""
    }
    set patBeg {(\$\{|(}
    set patEnd {)[\t ]+)}
    append pat1 $patBeg {array[\t ]+(} $arrayWords {)} $patEnd {$}
    append pat2 $patBeg $varWords $patEnd {([^\[]*)} {$}
    append pat3 $patBeg {info[\t ]+(} $infoWords1 {)} $patEnd {$}
    append pat4 $patBeg {info[\t ]+(} $infoWords2 {)} $patEnd {$}
    append pat5 {(eval[\t ]+)|([\[} "\\" $sEP {][\t ]*)$}
    # Try to figure out our current context.
    set txt3 [string trimleft [getText [pos::lineStart $pos0] $pos1]]
    if {[regexp $pat1 $txt3]} {
	# Must be an array.
	set context "array"
    } elseif {[regexp $pat2 $txt3] || [regexp $pat3 $txt3]} {
	# Looks like a variable name.
	set context "variable"
    } elseif {($txt3 eq "") || [regexp $pat4 $txt3] || [regexp $pat5 $txt3]} {
	# It looks like a procedure name.
	set context "procedure"
    } else {
	# Cannot tell.
	set context ""
    }
    return $context
}

# ×××× -------- ×××× #

##
 # -------------------------------------------------------------------------
 # 
 # "Tcl::Completion::Colon"  --
 # 
 # A general routine that will only work if the immediate preceding text ends
 # with "::".  Otherwise we'll pass and allow the more specific inquiries
 # take place.  Note that this does NOT work for procs/variables in the
 # global namespace.
 # 
 # Try to determine the namespace preceding the ":" of the current word,
 # create and present a list of possible completions based on this namespace,
 # taking the context into account to determine if this list should be
 # composed of variables or procedures.  If none are found, which might be
 # the case if the Tcl interpreter has not sourced anything pertaining to
 # this namespace, return "0".
 # 
 # Distinguishing between potential variables and procedures makes the
 # completion routine very useful, especially when you have a lot of both
 # defined in the namespace.  Tcl electric completions are generally
 # composed solely of procedure names.
 # 
 # Another way in which this differs from the normal electric completion is
 # the leading namespace is stripped from the options presented in the
 # listpick dialog, which makes it much easier to type a character or two
 # to navigate the list.
 # 
 # Contibuted by Craig Barton Upright.
 # 
 # -------------------------------------------------------------------------
 ##

proc Tcl::Completion::Colon {} {
    
    variable context
    variable interpCmd
    variable pos1
    variable txt1
    
    if {![string length $context] || ![regexp {::$} $txt1]} {return 0}
    set txt2 [string trimright $txt1 ":"]
    # Now we want to create a list of options for completions.
    regsub -all -- {(^\$?:*)|(:+$)} [string trim $txt2] "" ns
    if {$ns == "" || $ns == "::"} {return 0}
    set matches1 [set matches2 [list]]
    switch -- $context {
	"array" {
	    set p "Choose an array completion for '$ns'"
	    set script "info vars ${ns}::*"
	    set vars [uplevel \#0 [list $interpCmd $script]]
	    # Only add variables that are true arrays.
	    foreach var $vars {
		if {[array exists $var]} {lappend matches1 $var}
	    }
	    # Add children namespaces. arrays.
	    foreach kid [namespace children ::$ns] {
		set script "info vars ${kid}::*"
		foreach kidVar [uplevel \#0 [list $interpCmd $script]] {
		    if {[array exists $kidVar]} {
			regsub "::${ns}::" $kid "" kid
			lappend matches1 ${kid}::
			break
			# This would add all of the array names, but that
			# gets rather long -- in the current implementation,
			# choosing a children's namespace will offer options.
			# regsub "::${ns}::" $kidVar "" kidVar
			# lappend matches1 $kidVar
		    } 
		}
	    }
	}
	"procedure" {
	    set p "Choose a procedure completion for '$ns'"
	    if {![catch {procs::buildList "" ::${ns}::} procs]} {
		set matches1 $procs
	    }
	}
	"variable" {
	    set p "Choose a variable completion for '$ns'"
	    set script "info vars ${ns}::*"
	    set matches1 [uplevel \#0 [list $interpCmd $script]]
	    # Add children namespaces.
	    foreach kid [set kids [namespace children ::$ns]] {
		lappend matches1 ${kid}::
	    }
	}
    }
    foreach match $matches1 {
	regsub "^:*${ns}:*" $match "" match
	if {[string length $match]} {lappend matches2 $match}
    }
    if {![llength $matches2]} {return 0}
    if {[llength [set matches [lsort -dictionary -unique $matches2]]] == 1} {
	set completion [lindex $matches 0]
    } else {
	set completion [listpick -p $p $matches]
    }
    # Remove any leading ":"
    set pos2 [set pos0 [getPos]]
    while {[lookAt [pos::prevChar $pos0]] == ":"} {
	set pos0 [pos::prevChar $pos0]
    }
    # Complete the insertion.
    replaceText $pos0 $pos2 ::$completion
    # Now continue.  If we were completing a procedure name, there might be
    # additional completions available.  If a variable, a namespace might
    # have been chosen, and additional variables within the new namespace
    # might be available.
    if {$context == "procedure"} {
	if {![info exists ::Tclelectrics(${ns}::${completion})]} {
	    Tcl::procElectrics ${ns}::${completion}
	}
	completion::reset
	bind::Completion
    } elseif {[string index $completion end] == ":"} {
	completion::reset
	bind::Completion
    }
    return 1
}

##
 # -------------------------------------------------------------------------
 # 
 # "Tcl::Completion::ArrayElement" --
 # 
 # If the preceding text looks like an array item, attempt to complete based
 # on the available array names.  This takes both the namespace of any
 # surrounding procedure and/or the global namespace into account.  A closing
 # parenthesis is added if necessary.
 # 
 # Contibuted by Craig Barton Upright.
 # 
 # ------------------------------------------------------------------------
 ##

proc Tcl::Completion::ArrayElement {} {
    
    variable interpCmd
    variable pos1
    variable txt1
    variable nameSpace
    
    if {[string index $txt1 end] != "\("} {return 0}
    set pos0 [getPos]
    set txt2 [string trimleft $txt1  "$"]
    set txt2 [string trimright $txt2 "\("]
    # If 'txt1' isn't in the global namespace ...
    if {![regexp "^::" $txt1] && [string length $nameSpace]} {
	lappend namespaces ::${nameSpace}::
    }
    lappend namespaces "::"
    # Now find out if 'txt2' is an array in any of the namespaces.
    set matches1 [list]
    foreach ns $namespaces {
	if {[array exist ${ns}${txt2}]} {
	    set matches1 [array names ${ns}${txt2}] ; break
	}
    }
    set p "Choose a '$txt2' array name completion:"
    if {![llength [set matches [lsort -dictionary -unique $matches1]]]} {
	return 0
    } elseif {[llength $matches] == 1} {
	set completion [lindex $matches 0]
    } else {
	set completion [listpick -p $p $matches]
    }
    # Remove any leading "\("
    set pos2 $pos0
    while {[lookAt [pos::prevChar $pos0]] == "\("} {
	set pos0 [pos::prevChar $pos0]
    }
    # Complete the electric insertion.
    if {[lookAt $pos0] != "\)"} {append completion "\)"}
    replaceText $pos0 $pos2 "\($completion"
    return 1
}

##
 # -------------------------------------------------------------------------
 # 
 # "Tcl::Completion::LocalVar" --
 # 
 # Check to see if we're trying to complete a variable specific to the
 # current enclosing proc / namespace.
 # 
 # ------------------------------------------------------------------------
 ##

proc Tcl::Completion::LocalVar {} {
    
    variable context
    variable interpCmd
    variable nameSpace
    variable pos1
    variable txt1
    
    if {$context != "variable" && $context != "array"} {return 0}
    # Perform some more tests before continuing.
    set txt2 [string trimleft $txt1 "$"]
    if {[regexp {^::} $txt2]} {return 0}
    set matches1 [set matches2 [set matches3 [list]]]
    # See if we're in a procedure that has a namespace.
    regsub {^::} $nameSpace "" ns
    if {![string length $ns]} {return 0}
    set script [list info vars ::${ns}::${txt2}*]
    if {![llength [set matches1 [$interpCmd $script]]]} {return 0}
    # If the context is 'array', only offer arrays.
    if {$context == "array"} {
	foreach var $matches1 {
	    if {[array exists $var]} {lappend matches2 $var}
	}
    } else {
        set matches2 $matches1
    }
    # We have matches ...  strip of all leading "::", because the 'prematch'
    # arg in [completion::matchUtil] doesn't seem to take it into account
    # very well.
    foreach match $matches2 {
	regsub "^::${ns}::" $match "" match
	lappend matches3 $match
    }
    if {![llength $matches3]} {return 0}
    set context ""
    set matches [lsort -dictionary -unique $matches3]
    completion::matchUtil Tcl::Completion::LocalVar $txt2 $matches
}

##
 # -------------------------------------------------------------------------
 # 
 # "Tcl::Completion::GlobalVar" --
 # 
 # Only check to see if we're trying to complete a global variable, i.e. with
 # no :: except perhaps leading global namespace.
 # 
 # ------------------------------------------------------------------------
 ##

proc Tcl::Completion::GlobalVar {} {
    
    variable context
    variable interpCmd
    variable pos1
    variable txt1
    
    if {$context != "variable" && $context != "array"} {return 0}
    # Create a list of possible completions.
    regsub {^[$:]+} $txt1 "" txt2
    set matches1 [set matches2 [set matches3 [list]]]
    if {![regexp {::} $txt2]} {
	# Global var that isn't in a namespace?
	set script [list info globals ${txt2}*]
    } else {
	# Global var that is in a namespace?
	set script [list info vars ::${txt2}*]
    }
    if {![llength [set matches1 [$interpCmd $script]]]} {return 0}
    # If the context is 'array', only offer arrays.
    if {$context == "array"} {
	foreach var $matches1 {
	    if {[array exists ::$var]} {lappend matches2 $var}
	}
    } else {
	set matches2 $matches1
    }
    if {![llength $matches2]} {return 0}
    foreach match $matches2 {
	# Strip of all leading "::", because the 'prematch' arg in
	# [completion::matchUtil] doesn't seem to take it into account
	# very well.
	regsub {^::} $match "" match
	lappend matches3 $match
    }
    if {![llength $matches3]} {return 0}
    set context ""
    set matches [lsort -dictionary -unique $matches3]
    completion::matchUtil Tcl::Completion::GlobalVar $txt2 $matches
}

##
 # -------------------------------------------------------------------------
 # 
 # "Tcl::Completion::Proc" --
 # 
 # If we're trying to complete a procedure, as indicated by being the first
 # 'word' in a line or immediately following a \[, then we attempt to create
 # a list of potential completions.  For each one, we ensure that we have
 # additional electrics in place if the user chooses one of them.  (In this
 # way we can slowly build a library of "Tclelectrics" items without the user
 # needing to rebuild all of them at once.)
 # 
 # ------------------------------------------------------------------------
 ##

proc Tcl::Completion::Proc {} {
    
    variable addToTclcmds
    variable context
    variable interpCmd
    variable nameSpace
    variable pos1
    variable restoreElectrics
    variable txt1
    
    if {$context != "procedure" && $context != "cmd"} {return 0}
    regsub {^::} $txt1 "" txt2
    set matches1 [set matches2 [list]]
    # If this is in 'Tclcmds', we should defer to that.
    if {[lsearch -exact -sorted -dictionary $::Tclcmds $txt2] > -1} {return 0} 
    # Namespace checking.  First find all procs in the global namespace.
    set script [list info procs ::${txt2}*]
    foreach match [set matches [$interpCmd $script]] {
	regsub "::" $match "" txt3
	lappend matches1 $txt3
	# Make sure that each has an electric completion.
	if {![info exists ::Tclelectrics($match)]} {
	    Tcl::procElectrics $match
	}
	# Make sure that this gets added to the Tclcmds list.
	if {![lsearch -exact -sorted -dictionary $::Tclcmds $match]} {
	    lappend addToTclcmds $match
	}
    }
    # If 'txt1' does _not_ start with "::" and we're in a namespace, we're
    # going to see if there are any procedures within this namespace for a
    # possible completion.
    if {$txt1 == $txt2} {
	set pos0 [getPos]
	regsub {^::} $nameSpace "" ns
	if {[string length $ns]} {
	    set script [list info procs ::${ns}::${txt2}*]
	    foreach match [set matches [$interpCmd $script]] {
		regsub "::${ns}::" $match "" txt3
		lappend matches2 $txt3
		if {![info exists ::Tclelectrics($match)]} {
		    Tcl::procElectrics $match
		}
		if {[info exists ::Tclelectrics($match)]} {
		    set ::Tclelectrics($txt3) $::Tclelectrics($match)
		    lappend unsetElectrics $txt3
		}
		# Register it to be restored the next time that a completion
		# is called.
		lappend restoreElectrics $txt3
		# Make sure that this gets added to the Tclcmds list.
		if {![lsearch -exact -sorted -dictionary $::Tclcmds $match]} {
		    lappend addToTclcmds $match
		}
	    }
	}
    }
    if {![llength [set matches3 [concat $matches1 $matches2]]]} {return 0}
    # This ensures that [Tcl::Completion::Cmd] won't be called.
    set context ""
    set matches [lsort -dictionary -unique $matches3]
    completion::matchUtil Tcl::Completion::Proc $txt2 $matches
    return 1
}

##
 # -------------------------------------------------------------------------
 # 
 # "Tcl::Completion::Cmd" --
 # 
 # Rather than call [completion::cmd] directly in the completion routines, we
 # first check to make sure that it is appropriate to do so.  Also, procs
 # with the leading global namespace are _not_ included in 'Tclcmds', so if
 # the completion looks like a global proc then we include a 'prematch'
 # argument so that it will be recognized.
 # 
 # ------------------------------------------------------------------------
 ##

proc Tcl::Completion::Cmd {} {
    
    variable txt1
    variable context
    
    if {$context != "procedure"} {return 0}
    regexp {^(::)?} $txt1 prematch
    completion::cmd $txt1 cmds $prematch
}

##
 # -------------------------------------------------------------------------
 # 
 # "Tcl::Completion::Vvar" --
 # 
 # Try to complete a variable, provided it seems to be a variable name.
 # This means it is preceded by '$' or by 'set ' or 'arrayname(',...
 # 
 # This allows us to complete variable names which begin 'str', 'li' etc.
 # preferentially, since they would otherwise be expanded into 'string',
 # 'lindex' etc before they had a chance to be completed as variables.
 # 
 # -------------------------------------------------------------------------
 ##

proc Tcl::Completion::Vvar {} {
    
    variable ElectricCommandOptions
    variable context
    
    if {$context == "procedure"} {return 0}
    set txt1 [completion::lastWord]
    if {[string index $txt1 end] == " "} {return 0}
    if {[string index $txt1 0] == "\$"} {
	set txt2 [string range $txt1 1 end]
	set len2 [string length $txt2]
	return [completion::general -excludeBefore $len2 -- $txt2]
    }
    # Try to figure out our current context.
    set txt3 [getText [lineStart [getPos]] [getPos]]
    # Create some regexp patterns.
    set arrayWords [join $ElectricCommandOptions(array) "|"]
    set varWords   [join [list global set unset variable] "|"]
    set infoWords  [join [list exists globals locals vars] "|"]
    set patA {(\$\{|(} ; set patB {)[\t ]+)|\($}
    set pat1 "array\[\t \]+(${arrayWords})"
    set pat2 "info\[\t \]+(${infoWords})"
    set pat  "${patA}((${varWords})|(${pat1})|(${pat2}))${patB}"
    if {[regexp $pat $txt3]} {
	completion::word
    } else {
	return 0
    }
}

##
 # -------------------------------------------------------------------------
 # 
 # "Tcl::Completion::Var" --
 # 
 # A mildly adaptive call of completion::word, in which we realise we should
 # complete '$abc...'  if we can only see 'abc...'.  The standard procedure
 # considers '$' to be part of a word so that would otherwise fail.
 # 
 # ------------------------------------------------------------------------
 ##

proc Tcl::Completion::Var {} {
    
    variable context
    
    if {$context == "procedure"} {return 0}
    set txt1 [completion::lastWord]
    if {[string index $txt1 end] == " "} {return 0}
    if {[string index $txt1 0] == "\$"} {
	set txt2 [string range $txt1 1 end]
	set len2 [string length $txt2]
	completion::general -excludeBefore $len2 -- $txt2
    } else {
	completion::word
    }
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× 'Tclelectrics' etc arrays ×××× #
# 

##
 # -------------------------------------------------------------------------
 # 
 # "Tcl::Completion::buildTclCmds" --
 # 
 # Build the list of all commands recognized by the current interpreter. 
 # This allows us to maintain a separate list for each one.
 # 
 # Contibuted by Craig Barton Upright.
 # 
 # "Tcl::Completion::buildProcList" --
 # 
 # A variation of [procs::buildList] that deals with some 'interp' issues.
 # 
 # ------------------------------------------------------------------------
 ##

proc Tcl::Completion::buildTclCmds {} {

    variable electricCount 0
    variable interpCmd
    variable TclInterpCmds
    
    set ::Tclcmds [uplevel \#0 [list $interpCmd "info commands *"]]
    eval lappend ::Tclcmds [buildProcList $interpCmd]
    set ::Tclcmds [lsort -dictionary -unique $::Tclcmds]
    set TclInterpCmds($interpCmd) $::Tclcmds
}

proc Tcl::Completion::buildProcList {interpCmd {ns ::}} {

    set procList [list]
    foreach procName [$interpCmd "info procs ${ns}*"] {
	regsub {^::} $procName {} procName
	lappend procList $procName
    }
    foreach subNS [$interpCmd "namespace children $ns"] {
	eval lappend procList [buildProcList $interpCmd "${subNS}::"]
    }
    return $procList
}

proc Tcl::Completion::buildTclElectrics {} {
    
    global Tclelectrics
    
    # ×××× Tcl Keyword Completions ×××× #
    
    # Note that 'commands with options' such as [array] [file] etc. will
    # have separate electrics defined below.
    
    array set Tclelectrics {
	append          " ¥varName¥ ¥value¥ ¥?value value ...?¥"
	bgerror         " ¥message¥"
	break           ""
	case            " ¥string¥ ¥?in?¥ ¥patList¥ ¥body¥ ¥?patList body ...?¥"
	catch           " \{¥script¥\} ¥?varName?¥"
	cd              " ¥?dirName?¥"
	close           " ¥channelId¥"
	concat          " ¥arg¥ ¥arg...?¥"
	continue        ""
	else            " \{\n\t¥else body¥\n\} ¥¥"
	elseif          " \{¥test¥\} \{\n\t¥true body¥\n\} ¥¥"
	eof             " ¥channelId¥"
	error           " ¥message¥ ¥?info? ?code?¥"
	eval            " ¥arg¥ ¥?arg ...?¥"
	exec            " ¥?switches?¥ ¥arg¥ ¥?arg ...?¥"
	exit            " ¥?returnCode?¥"
	expr            " \{¥arg¥ ¥?arg arg ...?¥\}"
	flush           " ¥channelId¥"
	for             " \{¥start¥\} \{¥test¥\} \{¥increment¥\}\
	  \{\r\t¥body¥\r\}\r¥¥"
	foreach         " ¥varname¥ ¥list varname list...¥ \{\r\t¥body¥\r\} ¥¥"
	format          " ¥formatString¥ ¥?arg arg ...?¥"
	gets            " ¥channelId¥ ¥?varName?¥"
	glob            " ¥?switches?¥ ¥pattern¥ ¥?pattern ...?¥"
	global          " ¥varname¥ ¥?varname ...?¥"
	if              " \{¥test¥\} \{\r\t¥true body¥\r\} ¥¥"
	ifel            "×kill0if \{¥test¥\} \{\r\t¥true body¥\r\}\
	  else \{\n\t¥else body¥\n\} ¥¥"
	ifelse          "×kill0if \{¥test¥\} \{\r\t¥true body¥\r\}\
	  else \{\n\t¥else body¥\n\} ¥¥"
	ifelif          "×kill0if \{¥test¥\} \{\r\t¥true body¥\r\}\
	  elseif \{¥test¥\} \{\n\t¥true body¥\n\} ¥¥"
	ifelifel        "×kill0if \{¥test¥\} \{\r\t¥true body¥\r\}\
	  elseif \{¥test¥\} \{\n\t¥true body¥\n\} else \{\n\t¥else body¥\n\} ¥¥"
	incr            " ¥varName¥ ¥?increment?¥"
	join            " ¥list¥ ¥?joinString?¥"
	lappend         " ¥varName¥ ¥value¥ ¥?value value ...?¥"
	lindex          " ¥list¥ ¥element¥"
	linsert         " ¥list¥ ¥index¥ ¥element¥ ¥?element element ...?¥"
	list            " ¥?arg arg ...?¥"
	llength         " ¥list¥"
	lrange          " ¥list¥ ¥first¥ ¥last¥"
	lreplace        " ¥list¥ ¥first¥ ¥last¥ ¥?element element ...?¥"
	lsearch         " ¥?options?¥ ¥list¥ ¥pattern¥"
	lset            " ¥listVar¥ ¥index ?index...?¥ ¥value¥"
	lsort           " ¥?options?¥ ¥list¥"
	open            " ¥fileName¥ ¥?access? ?permissions?¥"
	pid             " ¥?fileId?¥"
	puts            " ¥?-nonewline?¥ ¥fileId¥ ¥string¥"
	pwd             ""
	read            " ¥?-nonewline?¥ ¥channelId¥"
	regexp          " ¥?switches?¥ ¥exp¥ ¥string¥ ¥?matchVars...?¥"
	regsub          " ¥?switches?¥ ¥exp¥ ¥string¥ ¥subSpec¥ ¥varName¥"
	rename          " ¥oldName¥ ¥newName¥"
	return          " ¥?-code code?¥ ¥?-errorinfo info?¥\
	  ¥?-errorcode code?¥ ¥?string?¥"
	scan            " ¥string¥ ¥format¥ ¥?varName varName ...?¥"
	seek            " ¥channelId¥ ¥offset¥ ¥?origin?¥"
	set             " ¥varName¥ ¥?value?¥"
	source          " ¥fileName¥"
	split           " ¥string¥ ¥?splitChars?¥"
	switch          " -¥options¥- ¥string¥ \{\n\t\"¥pattern1¥\"\
	  \{\n\t\t¥body¥\n\t\}\n\t\"¥pattern2¥\" \{\n\t\t¥body¥\n\t\}¥¥\n\}¥¥"
	tell            " ¥channelId¥"
	time            " ¥script¥ ¥?count?¥"
	unset           " ¥?-nocomplain --?¥ ¥name¥ ¥?name name ...?¥"
	uplevel         " ¥?level?¥ ¥arg¥ ¥?arg ...?¥"
	upvar           " ¥?level?¥ ¥otherVar¥ ¥myVar¥ ¥?otherVar myVar ...?¥"
	variable        " ¥name¥ ¥?value?¥"
	while           " \{¥test¥\} \{\r\t¥body¥\r\}\r¥¥"
    }

    # These three are done separately to avoid screwing up file marking or
    # the building of tclIndex files.
    set Tclelectrics(class)   " ¥name¥ \{\n\tinherit ¥parent¥\n\}"
    set Tclelectrics(proc)    " ¥name¥ \{¥args¥\} \{\n\t¥body¥\n\}"
    set Tclelectrics(body)    " \{¥string¥\} \{\n\t¥body¥\n\}"
    
    # ×××× Tcl Commands With Options ×××× #
    
    # All commands listed in the 'commandsWithOptions' list will be used by
    # [Tcl::Completion::PickOption] below, and possibly called by electric
    # contractions via indirection.
    
    # array
    lappend commandsWithOptions array
    array set Tclelectrics {
	"array anymore"         " ¥arrayName¥ ¥searchId¥"
	"array donesearch"      " ¥arrayName¥ ¥searchId¥"
	"array exists"          " ¥arrayName¥"
	"array get"             " ¥arrayName¥ ¥?pattern?¥"
	"array names"           " ¥arrayName¥ ¥?mode? ?pattern?¥"
	"array nextelement"     " ¥arrayName¥ ¥searchId¥"
	"array set"             " ¥arrayName¥ ¥list¥"
	"array size"            " ¥arrayName¥"
	"array startsearch"     " ¥arrayName¥"
	"array statistics"      " ¥arrayName¥"
	"array unset"           " ¥arrayName¥ ¥?pattern¥?"
	
    }
    # dict
    lappend commandsWithOptions dict
    array set Tclelectrics {
	"dict append"           " ¥dictionaryVariable¥ ¥key¥ ¥?string ...?¥"
	"dict create"           " ¥?key value ...?¥"
	"dict exists"           " ¥dictionaryValue¥ ¥key¥ ¥?key ...?¥"
	"dict filter"           " ¥multiple syntax options¥"
	"dict for"              " ¥{keyVar valueVar}¥ ¥dictionaryValue¥ ¥body¥"
	"dict get"              " ¥dictionaryValue¥ ¥?key ...?¥"
	"dict incr"             " ¥dictionaryVariable¥ ¥key¥ ¥?increment?¥"
	"dict info"             " ¥dictionaryValue¥"
	"dict keys"             " ¥dictionaryValue¥ ¥?globPattern?¥"
	"dict lappend"          " ¥dictionaryVariable¥ ¥key¥ ¥?value ...?¥"
	"dict merge"            " ¥?dictionaryValue ...?¥"
	"dict remove"           " ¥dictionaryValue¥ ¥?key ...?¥"
	"dict replace"          " ¥dictionaryValue¥ ¥?key value ...?¥"
	"dict set"              " ¥dictionaryVariable¥ ¥key¥ ¥?key ...?¥ ¥value¥"
	"dict size"             " ¥dictionaryValue¥"
	"dict unset"            " ¥dictionaryVariable¥ ¥key¥ ¥?key ...?¥"
	"dict update"           " ¥dictionaryVariable¥ ¥key¥ ¥varName¥ ¥?key varName ...?¥ ¥body¥"
	"dict values"           " ¥dictionaryValue¥ ¥?globPattern?¥"
	"dict with"             " ¥dictionaryVariable¥ ¥?key ...?¥ ¥body¥"
    }
    # file
    lappend commandsWithOptions file
    array set Tclelectrics {
	"file atime"            " ¥name¥ ¥?time?¥"
	"file attributes"       " ¥name¥"
	"file attributes"       " ¥name¥ ¥?option?¥"
	"file attributes"       " ¥name¥ ¥?option value option value...?¥"
	"file channels"         " ¥?pattern?¥"
	"file copy"             " ¥?-force? ?- -?¥ ¥source¥ ¥target¥"
	"file delete"           " ¥?-force? ?- -?¥ ¥pathname¥ ¥?pathname ... ?¥"
	"file dirname"          " ¥name¥"
	"file executable"       " ¥name¥"
	"file exists"           " ¥name¥"
	"file extension"        " ¥name¥"
	"file isdirectory"      " ¥name¥"
	"file isfile"           " ¥name¥"
	"file join"             " ¥name¥ ¥?name ...?¥"
	"file link"             " ¥?-linktype?¥ ¥linkName¥ ¥?target?¥"
	"file lstat"            " ¥name¥ ¥varName¥"
	"file mkdir"            " ¥dir¥ ¥?dir ...?¥"
	"file mtime"            " ¥name¥ ¥?time?¥"
	"file nativename"       " ¥name¥"
	"file normalize"        " ¥name¥"
	"file owned"            " ¥name¥"
	"file pathtype"         " ¥name¥"
	"file readable"         " ¥name¥"
	"file readlink"         " ¥name¥"
	"file rename"           " ¥?-force? ?- -?¥ ¥source¥ ¥target¥"
	"file rename"           " ¥?-force? ?- -?¥ ¥source¥ ¥?source ...?¥\
	  ¥targetDir¥"
	"file rootname"         " ¥name¥"
	"file separator"        " ?name?"
	"file size"             " ¥name¥"
	"file split"            " ¥name¥"
	"file stat"             " ¥name¥ ¥varName¥"
	"file system"           " ¥name¥"
	"file tail"             " ¥name¥"
	"file type"             " ¥name¥"
	"file volume"           ""
	"file writable"         " ¥name¥"
	
    }
    
    # history
    lappend commandsWithOptions history
    array set Tclelectrics {
	"history add"           " ¥command¥ ¥?exec?¥"
	"history change"        " ¥newValue¥ ¥?event?¥"
	"history clear"         ""
	"history event"         " ¥?event?¥"
	"history info"          " ¥?count?¥"
	"history keep"          " ¥?count?¥"
	"history nextid"        ""
	"history redo"          " ¥?event?¥"
    }
    # info
    lappend commandsWithOptions info
    array set Tclelectrics {
	"info args"                     " ¥procname¥"
	"info body"                     " ¥procname¥"
	"info cmdcount"                 " ¥¥"
	"info commands"                 " ¥?pattern?¥"
	"info complete"                 " ¥command¥"
	"info default"                  " ¥procname¥ ¥arg¥ ¥varname¥"
	"info procname"                 " ¥arg¥ ¥varname¥"
	"info exists"                   " ¥varName¥"
	"info functions"                " ¥?pattern?¥"
	"info globals"                  " ¥?pattern?¥"
	"info hostname"                 ""
	"info level"                    " ¥?number?¥"
	"info library"                  ""
	"info loaded"                   " ¥?interp?¥"
	"info locals"                   " ¥?pattern?¥"
	"info nameofexecutable"         ""
	"info patchlevel"               ""
	"info procs"                    " ¥?pattern?¥"
	"info script"                   " ¥?filename?¥ "
	"info sharedlibextension"       ""
	"info tclversion"               ""
	"info vars"                     " ¥?pattern?¥"
    }
    # interp
    lappend commandsWithOptions interp
    array set Tclelectrics {
	"interp alias"          " ¥srcPath¥¥srcCmd¥"
	"interp alias"          " ¥srcPath¥ ¥srcCmd¥ \{\}"
	"interp alias"          " ¥srcPath¥ ¥srcCmd¥ ¥targetPath¥\
	  ¥targetCmd¥ ¥?arg arg ...?¥"
	"interp aliases"        " ¥?path?¥"
	"interp create"         " ¥?-safe? ?- -? ?path?¥"
	"interp delete"         " ¥?path ...?¥"
	"interp eval"           " ¥path¥ ¥arg¥ ¥?arg ...?¥"
	"interp exists"         " ¥path¥"
	"interp expose"         " ¥path¥ ¥hiddenName¥ ¥?exposedCmdName?¥"
	"interp hide"           " ¥path¥ ¥exposedCmdName¥ ¥?hiddenCmdName?¥"
	"interp hidden"         " ¥path¥"
	"interp invokehidden"   " ¥path¥ ¥?-global?¥ ¥hiddenCmdName¥ ¥?arg ...?¥"
	"interp issafe"         " ¥?path?¥"
	"interp marktrusted"    " ¥path¥"
	"interp recursionlimit" " ¥path¥ ¥?newlimit?¥"
	"interp share"          " ¥srcPath¥ ¥channelId¥ ¥destPath¥"
	"interp slaves"         " ¥?path?¥"
	"interp target"         " ¥path¥ ¥alias¥"
	"interp transfer"       " ¥srcPath¥ ¥channelId¥ ¥destPath¥"
    }
    # namespace
    lappend commandsWithOptions namespace
    array set Tclelectrics {
	"namespace children"    " ¥?namespace? ?pattern?¥"
	"namespace code"        " ¥script¥"
	"namespace current"     ""
	"namespace delete"      " ¥?namespace namespace ...?¥"
	"namespace eval"        " ¥namespace¥ \{¥args¥\}¥¥"
	"namespace exists"      " ¥namespace¥"
	"namespace export"      " ¥?-clear? ?pattern pattern ...?¥"
	"namespace forget"      " ¥?pattern pattern ...?¥"
	"namespace import"      " ¥?-force? ?pattern pattern ...?¥"
	"namespace inscope"     " ¥namespace¥ ¥arg¥ ¥?arg ...?¥"
	"namespace origin"      " ¥command¥"
	"namespace parent"      " ¥?namespace?¥"
	"namespace qualifiers"  " ¥string¥"
	"namespace tail"        " ¥string¥"
	"namespace which"       " ¥?-command? ?-variable?¥ ¥name¥"
    }
    # package
    lappend commandsWithOptions package
    array set Tclelectrics {
	"package forget"        " ¥?package package ...?¥"
	"package ifneeded"      " ¥package¥ ¥version¥ ¥?script?¥"
	"package names"         " ¥package¥ ¥present¥ ¥?-exact?¥\
	  ¥package¥ ¥?version?¥"
	"package provide"       " ¥package¥ ¥?version?¥"
	"package require"       " ¥?-exact?¥ ¥package¥ ¥?version?¥"
	"package unknown"       " ¥?command?¥"
	"package vcompare"      " ¥version1¥ ¥version2¥"
	"package versions"      " ¥package¥"
	"package vsatisfies"    " ¥version1¥ ¥version2¥"
    }
    # string
    lappend commandsWithOptions string
    array set Tclelectrics {
	"string bytelength"     " ¥string¥"
	"string compare"        " ¥?-nocase? ?-length int?¥\
	  ¥is-bigger¥ ¥compared-with¥"
	"string equal"          " ¥?-nocase? ?-length int?¥\
	  ¥name¥ ¥string1¥ ¥string2¥"
	"string first"          " ¥search-for¥ ¥search-in¥ ¥?startIndex?¥"
	"string index"          " ¥string¥ ¥charIndex¥"
	"string is"             " ¥class¥ ¥?-strict? ?-failindex varname?¥\
	  ¥string¥"
	"string last"           " ¥search-for¥ ¥search-in¥ ¥?lastIndex?¥"
	"string length"         " ¥string¥"
	"string map"            " ¥?-nocase?¥ ¥charMap¥ ¥string¥"
	"string match"          " ¥?-nocase?¥ ¥pattern¥ ¥string¥"
	"string range"          " ¥string¥ ¥first¥ ¥last¥"
	"string repeat"         " ¥string¥ ¥count¥"
	"string replace"        " ¥string¥ ¥first¥ ¥last¥ ¥?newstring?¥"
	"string tolower"        " ¥string¥ ¥?first? ?last?¥"
	"string totitle"        " ¥string¥ ¥?first? ?last?¥"
	"string toupper"        " ¥string¥ ¥?first? ?last?¥"
	"string trim"           " ¥string¥ ¥?chars?¥"
	"string trimleft"       " ¥string¥ ¥?chars?¥"
	"string trimright"      " ¥string¥ ¥?chars?¥"
	"string wordend"        " ¥string¥ ¥index¥"
	"string wordstart"      " ¥string¥ ¥index¥"
    }
    # slave
    lappend commandsWithOptions slave
    array set Tclelectrics {
	"slave aliases"         ""
	"slave alias"           " ¥srcCmd¥"
	"slave alias"           " ¥srcCmd¥ {}"
	"slave alias"           " ¥srcCmd¥ ¥targetCmd¥ ¥?arg ...?¥"
	"slave eval"            " ¥arg¥ ¥?arg ...?¥"
	"slave expose"          " ¥hiddenName¥ ¥?exposedCmdName?¥"
	"slave hide"            " ¥exposedCmdName¥ ¥?hiddenCmdName?¥"
	"slave hidden"          ""
	"slave invokehidden"    " ¥?-global?¥ ¥hiddenName¥ ¥?arg ...?¥"
	"slave issafe"          ""
	"slave marktrusted"     ""
	"slave recursionlimit"  " ¥?newlimit?¥"
    }
    # trace
    lappend commandsWithOptions trace
    array set Tclelectrics {
	"trace add"             " ¥variable|command|execution¥\
	  ¥name¥ ¥opList¥ ¥command¥"
	"trace remove"          " ¥variable|command|execution¥\
	  ¥name¥ ¥opList¥ ¥command¥"
	"trace info"            " ¥variable|command|execution¥ ¥name¥"
    }
    
    # ×××× Tk Keyword Completions ×××× #

    array set Tclelectrics {
	bindtags        " ¥window¥ ¥?tagList?¥"
	bitmap          "×kill0image create bitmap ¥?name?¥ ¥?options?¥"
	button          " ¥pathName¥ ¥?options?¥"
	canvas          " ¥pathName¥ ¥?options?¥"
	checkbutton     " ¥pathName¥ ¥?options?¥"
	clipboard       " ¥option¥ ¥?arg arg ...?¥"
	destroy         " ¥?window window ...?¥"
	entry           " ¥pathName¥ ¥?options?¥"
	frame           " ¥pathName¥ ¥?options?¥"
	label           " ¥pathName¥ ¥?options?¥"
	labelframe      " ¥pathName¥ ¥?options?¥"
	listbox         " ¥pathName¥ ¥?options?¥"
	lower           " ¥window¥ ¥?belowThis?¥"
	menu            " ¥pathName¥ ¥?options?¥"
	menubutton      " ¥pathName¥ ¥?options?¥"
	message         " ¥pathName¥ ¥?options?¥"
	panedwindow     " ¥pathName¥ ¥?options?¥"
	photo           "×kill0image create photo ¥?name?¥ ¥?options?¥"
	radiobutton     " ¥pathName¥ ¥?options?¥"
	raise           " ¥window¥ ¥?aboveThis?¥"
	scale           " ¥pathName¥ ¥?options?¥"
	scrollbar       " ¥pathName¥ ¥?options?¥"
	send            " ¥?options?¥ ¥app¥ ¥cmd¥ ¥?arg arg ...?¥"
	spinbox         " ¥pathName¥ ¥?options?¥"
	text            " ¥pathName¥ ¥?options?¥"
	toplevel        " ¥pathName¥ ¥?options?¥"
	
	tk_chooseColor          " ¥?option value ...?¥"
	tk_chooseDirectory      " ¥?option value ...?¥"
	tk_dialog               " ¥window¥ ¥title¥ ¥text¥ ¥bitmap¥\
	  ¥default¥ ¥string¥ ¥string ...¥"
	tk_focusNext            " ¥window¥"
	tk_focusPrev            " ¥window¥"
	tk_getOpenFile          " ¥?option value ...?¥"
	tk_getSaveFile          " ¥?option value ...?¥"
	tk_menuSetFocus         " ¥pathName¥"
	tk_messageBox           " ¥?option value ...?¥"
	tk_optionMenu           " ¥w¥ ¥varName¥ ¥value¥ ¥?value value ...?¥"
	tk_popup                " ¥menu¥ ¥x¥ ¥y¥ ¥?entry?¥"
	tk_setPalette           " ¥<background>|<name value ?name value ...?>¥"
	tk_textCopy             " ¥pathName¥"
	tk_textCut              " ¥pathName¥"
	tk_textPaste            " ¥pathName¥"
    }
    
    # ×××× Tk Commands With Options ×××× #
    
    # console
    lappend commandsWithOptions console
    array set Tclelectrics {
	"console title"         "¥?string?¥" 
	"console hide"          ""
	"console show"          ""
	"console eval"          "¥script¥" 
    }
    
    # event
    lappend commandsWithOptions event
    array set Tclelectrics {
	"event add"             " ¥<<virtual>>¥ ¥sequence¥ ¥?sequence ...?¥"
	"event delete"          " <<virtual>> ¥?sequence sequence ...?¥"
	"event generate"        " ¥window event¥\
	  ¥?option value option value ...?¥"
	"event info"            " ¥?<<virtual>>?¥"
    }
    # font
    lappend commandsWithOptions font
    array set Tclelectrics {
	"font actual"           " ¥font¥ ¥?-displayof window?¥ ¥?option?¥"
	"font configure"        " ¥fontname¥ ¥?option?¥\
	  ¥?value option value ...?¥"
	"font create"           " ¥?fontname?¥ ¥?option value ...?¥"
	"font delete"           " ¥fontname¥ ¥?fontname ...?¥"
	"font families"         " ¥?-displayof window?¥"
	"font measure"          " ¥font¥ ¥?-displayof window?¥ ¥text¥"
	"font metrics"          " ¥font¥ ¥?-displayof window?¥ ¥?option?¥"
	"font names"            ""
    }
    # grab 
    lappend commandsWithOptions grab
    array set Tclelectrics {
	"grab current"          "¥?window?¥"
	"grab release"          "¥window¥"
	"grab set"              "¥?-global?¥ ¥window¥"
	"grab status"           "¥window¥"
    }
    # grid
    lappend commandsWithOptions grid 
    array set Tclelectrics {
	"grid "                 " ¥slave¥ ¥?slave ...?¥ ¥?options?¥"
	"grid bbox"             " ¥master¥ ¥?column row?¥ ¥?column2 row2?¥"
	"grid columnconfigure"  " ¥master¥ ¥index¥ ¥?-option value...?¥"
	"grid configure"        " ¥slave¥ ¥?slave ...?¥ ¥?options?¥"
	"grid forget"           " ¥slave¥ ¥?slave ...?¥"
	"grid info"             " ¥slave¥"
	"grid location"         " ¥master¥ ¥x¥ ¥y¥"
	"grid propagate"        " ¥master¥ ¥?boolean?¥"
	"grid rowconfigure"     " ¥master¥ ¥index¥ ¥?-option value...?¥"
	"grid remove"           " ¥slave¥ ¥?slave ...?¥"
	"grid size"             " ¥master¥"
	"grid slaves"           " ¥master¥ ¥?-option value?¥"
    }
    # image
    lappend commandsWithOptions image
    array set Tclelectrics {
	"image create"          " ¥type¥ ¥?name?¥ ¥?option value ...?¥"
	"image delete"          " ¥?name name ...?¥"
	"image height"          " ¥name¥"
	"image inuse"           " ¥name¥"
	"image names"           ""
	"image type"            " ¥name¥"
	"image types"           ""
	"image width"           " ¥name¥"
    }
    # option
    lappend commandsWithOptions option
    array set Tclelectrics {
	"option add"            " ¥pattern¥ ¥value¥ ¥?priority?¥"
	"option clear"          ""
	"option get"            " ¥window¥ ¥name¥ ¥class¥"
	"option readfile"       " ¥fileName¥ ¥?priority?¥"
    }
    # pack
    lappend commandsWithOptions pack
    array set Tclelectrics {
	"pack slave"            " ¥?slave ...?¥ ¥?options?¥"
	"pack configure"        " ¥slave¥ ¥?slave ...?¥ ¥?options?¥"
	"pack forget"           " ¥slave¥ ¥?slave ...?¥"
	"pack info"             " ¥slave¥"
	"pack propagate"        " ¥master¥ ¥?boolean?¥"
	"pack slaves"           " ¥master¥"
    }
    # place
    lappend commandsWithOptions place
    array set Tclelectrics {
	"place "                " ¥window¥ ¥option¥ ¥value¥ ¥?option value ...?¥"
	"place configure"       " ¥window¥ ¥?option?¥ ¥?value option value ...?¥"
	"place forget"          " ¥window¥"
	"place info"            " ¥window¥"
	"place slaves"          " ¥window¥"
    }
    # selection
    lappend commandsWithOptions selection
    array set Tclelectrics {
	"selection clear"       " ¥?-displayof window?¥ ¥?-selection selection?¥"
	"selection get"         " ¥?-displayof window?¥ ¥?-selection selection?¥\
	  ¥?-type type?¥"
	"selection handle"      " ¥?-selection selection?¥ ¥?-type type?¥\
	  ¥?-format format?¥ ¥window¥ ¥command¥"
	"selection own"         " ¥?-displayof window|?-command command?¥\
	  ¥?-selection selection?¥ ¥window (if -displayof option)¥"
    }
    # tk
    lappend commandsWithOptions tk
    array set Tclelectrics {
	"tk appname"            " ¥?newName?¥"
	"tk caret"              " ¥window¥ ¥?-x x?¥ ¥?-y y?¥ ¥?-height height?¥"
	"tk scaling"            " ¥?-displayof window?¥ ¥?number?¥"
	"tk useinputmethods"    " ¥?-displayof window?¥ ¥?boolean?¥"
	"tk windowingsystem"    ""
    }
    # tkwait
    lappend commandsWithOptions tkwait
    array set Tclelectrics {
	"tkwait variable"      " ¥name¥"
	"tkwait visibility"    " ¥name¥"
	"tkwait window"        " ¥name¥"
    }
    # winfo
    lappend commandsWithOptions winfo
    array set Tclelectrics {
	"winfo atom"                    " ¥?-displayof window?¥ ¥name¥"
	"winfo atomname"                " ¥?-displayof window?¥ ¥id¥"
	"winfo cells"                   " ¥window¥"
	"winfo children"                " ¥window¥"
	"winfo class"                   " ¥window¥"
	"winfo colormapfull"            " ¥window¥"
	"winfo containing"              " ¥?-displayof window?¥ ¥rootX¥ ¥rootY¥"
	"winfo depth"                   " ¥window¥"
	"winfo exists"                  " ¥window¥"
	"winfo fpixels"                 " ¥window number¥"
	"winfo geometry"                " ¥window¥"
	"winfo height"                  " ¥window¥"
	"winfo id"                      " ¥window¥"
	"winfo interps"                 " ¥?-displayof window?¥"
	"winfo ismapped"                " ¥window¥"
	"winfo manager"                 " ¥window¥"
	"winfo name"                    " ¥window¥"
	"winfo parent"                  " ¥window¥"
	"winfo pathname"                " ¥?-displayof window?¥ ¥id¥"
	"winfo pixels"                  " ¥window number¥"
	"winfo pointerx"                " ¥window¥"
	"winfo pointerxy"               " ¥window¥"
	"winfo pointery"                " ¥window¥"
	"winfo reqheight"               " ¥window¥"
	"winfo reqwidth"                " ¥window¥"
	"winfo rgb"                     " ¥window¥ ¥color¥"
	"winfo rootx"                   " ¥window¥"
	"winfo rooty"                   " ¥window¥"
	"winfo screen"                  " ¥window¥"
	"winfo screencells"             " ¥window¥"
	"winfo screendepth"             " ¥window¥"
	"winfo screenheight"            " ¥window¥"
	"winfo screenmmheight"          " ¥window¥"
	"winfo screenmmwidth"           " ¥window¥"
	"winfo screenvisual"            " ¥window¥"
	"winfo screenwidth"             " ¥window¥"
	"winfo server"                  " ¥window¥"
	"winfo toplevel"                " ¥window¥"
	"winfo viewable"                " ¥window¥"
	"winfo visual"                  " ¥window¥"
	"winfo visualid"                " ¥window¥"
	"winfo visualsavailable"        " ¥window¥ ¥?includeids?¥"
	"winfo vrootheight"             " ¥window¥"
	"winfo vrootwidth"              " ¥window¥"
	"winfo vrootx"                  " ¥window¥"
	"winfo vrooty"                  " ¥window¥"
	"winfo width"                   " ¥window¥"
	"winfo x"                       " ¥window¥"
	"winfo y"                       " ¥window¥"
    }
    # wm
    lappend commandsWithOptions wm
    array set Tclelectrics {
	"wm aspect"             " ¥window¥ \
	  ¥?minNumer minDenom maxNumer maxDenom?¥"
	"wm attributes"         " ¥window¥"
	"wm attributes"         " ¥window¥ ¥?option?¥"
	"wm attributes"         " ¥window¥ ¥?option value option value...?¥"
	"wm client"             " ¥window¥ ¥?name?¥"
	"wm colormapwindows"    " ¥window¥ ¥?windowList?¥"
	"wm command"            " ¥window¥ ¥?value?¥"
	"wm deiconify"          " ¥window¥"
	"wm focusmodel"         " ¥window¥ ¥?active|passive?¥"
	"wm frame"              " ¥window¥"
	"wm geometry"           " ¥window¥ ¥?newGeometry?¥"
	"wm grid"               " ¥window¥\
	  ¥?baseWidth baseHeight widthInc heightInc?¥"
	"wm group"              " ¥window¥ ¥?pathName?¥"
	"wm iconbitmap"         " ¥window¥ ¥?bitmap?¥"
	"wm iconify"            " ¥window¥"
	"wm iconmask"           " ¥window¥ ¥?bitmap?¥"
	"wm iconname"           " ¥window¥ ¥?newName?¥"
	"wm iconposition"       " ¥window¥ ¥?x y?¥"
	"wm iconwindow"         " ¥window¥ ¥?pathName?¥"
	"wm maxsize"            " ¥window¥ ¥?width height?¥"
	"wm minsize"            " ¥window¥ ¥?width height?¥"
	"wm overrideredirect"   " ¥window¥ ¥?boolean?¥"
	"wm positionfrom"       " ¥window¥ ¥?who?¥"
	"wm protocol"           " ¥window¥ ¥?name?¥ ¥?command?¥"
	"wm resizable"          " ¥window¥ ¥?width height?¥"
	"wm sizefrom"           " ¥window¥ ¥?who?¥"
	"wm stackorder"         " ¥window¥ ¥?isabove|isbelow window?¥"
	"wm state"              " ¥window¥ ¥?newstate?¥"
	"wm title"              " ¥window¥ ¥?string?¥"
	"wm transient"          " ¥window¥ ¥?master?¥"
	"wm withdraw"           " ¥window¥"
    }

    # ×××× Pick Options ×××× #
    
    # Allows the user to select required options for some Tcl commands, an
    # alternative if you can never remember the abbreviations that are made
    # available via 'contractions'.  Any "two-word" electric defined above
    # will be included below.
    
    variable ElectricCommandOptions
    variable LastElectricOption
    set electrics [array names Tclelectrics]
    foreach command $commandsWithOptions {
	# Create the options list that will be presented in the listpick.
	set commandOptions [list]
	set options [lsearch -all -glob -inline $electrics "$command *"]
	foreach item $options {lappend commandOptions [lindex $item 1]}
	set commandOptions [lsort -dictionary -unique $commandOptions]
	set ElectricCommandOptions($command) $commandOptions
	# Create the default option in the listpick.
	if {![info exists LastElectricOption($command)]} {
	    set LastElectricOption($command) [lindex $commandOptions 0]
	}
	# Create a new electric for this item.
	set Tclelectrics($command) "×\[Tcl::Completion::PickOption $command\]"
	# Create a new variable allowing e.g. "string co" to be completed to
	# "string compare".
	global Tcl${command}cmds
	set Tcl${command}cmds $ElectricCommandOptions($command)
    }
    
    # ×××× Contractions ×××× #
    
    # These make use of indirection, in conjunction with the electrics
    # defined in the "Commands With Options" sections above.  Feel free to
    # add more contractions, i.e. for Tk commands ...
    
    # "array" contractions
    array set Tclelectrics {
	a'a             "×Èarray anymore"
	a'd             "×Èarray donesearch"
	a'e             "×Èarray exists"
	a'g             "×Èarray get"
	a'n             "×Èarray names"
	a'ne            "×Èarray nextelement"
	a's             "×Èarray set"
	a'sz            "×Èarray size"
	a'ss            "×Èarray startsearch"
	a'u             "×Èarray unset"
    }
    # "dict" contractions
    array set Tclelectrics {
	d'a             "×Èdict append"
	d'c             "×Èdict create"
	d'e             "×Èdict exists"
	d'fi            "×Èdict filter"
	d'fr            "×Èdict for"
	d'g             "×Èdict get"
	d'ir"           "×Èdict incr"
	d'io"           "×Èdict info"
	d'k             "×Èdict keys"
	d'l             "×Èdict lappend"
	d'm             "×Èdict merge"
	d'rm            "×Èdict remove"
	d'rp            "×Èdict replace"
	d'st            "×Èdict set"
	d'sz            "×Èdict size"
	d'un            "×Èdict unset"
	d'up            "×Èdict update"
	d'v             "×Èdict values"
	d'w             "×Èdict with"
    }
    # "file" contractions
    array set Tclelectrics {
	f'a              "×Èfile atime"
	f'c              "×Èfile copy"
	f'dl             "×Èfile delete"
	f'd              "×Èfile dirname"
	f'exe            "×Èfile executable"
	f'exi            "×Èfile exists"
	f'ext            "×Èfile extension"
	f'id             "×Èfile isdirectory"
	f'if             "×Èfile isfile"
	f'j              "×Èfile join"
	f'l              "×Èfile lstat"
	f'md             "×Èfile mkdir"
	f'm              "×Èfile mtime"
	f'o              "×Èfile owned"
	f'p              "×Èfile pathtype"
	f'r              "×Èfile readable"
	f'rl             "×Èfile readlink"
	f'ren            "×Èfile rename"
	f'rt             "×Èfile root"
	f'rn             "×Èfile rootname"
	f'size           "×Èfile size"
	f'split          "×Èfile split"
	f'stat           "×Èfile stat"
	f'tail           "×Èfile tail"
	f'type           "×Èfile type"
	f'w              "×Èfile writable"
    }
    # "info" contractions
    array set Tclelectrics {
	i'a              "×Èinfo args"
	i'b              "×Èinfo body"
	i'cc             "×Èinfo cmdcount"
	i'cm             "×Èinfo commands"
	i'cp             "×Èinfo complete"
	i'p              "×Èinfo procname"
	i'e              "×Èinfo exists"
	i'g              "×Èinfo globals"
	i'lv             "×Èinfo level"
	i'lb             "×Èinfo library"
	i'lc             "×Èinfo locals"
	i'pl             "×Èinfo patchlevel"
	i'p              "×Èinfo procs"
	i's              "×Èinfo script"
	i't              "×Èinfo tclversion"
	i'v              "×Èinfo vars"
    }
    # "namespace" contractions
    array set Tclelectrics {
	n'c             "×Ènamespace children"
	n'e             "×Ènamespace eval"
	n'd             "×Ènamespace delete"
	n'f             "×Ènamespace forget"
	n'o             "×Ènamespace origin"
	n'p             "×Ènamespace parent"
	n'q             "×Ènamespace qualifiers"
	n't             "×Ènamespace tail"
	n'w             "×Ènamespace which"
    }
    # "string" contractions
    array set Tclelectrics {
	s'b               "×Èstring bytelength"
	s'c               "×Èstring compare"
	s'e               "×Èstring equal"
	s'f               "×Èstring first"
	s'i               "×Èstring index"
	s'i               "×Èstring is"
	s'l               "×Èstring last"
	s'len             "×Èstring length"
	s'map             "×Èstring map"
	s'm               "×Èstring match"
	s'r               "×Èstring range"
	s'rt              "×Èstring repeat"
	s'rp              "×Èstring replace"
	s't               "×Èstring trim"
	s'tl              "×Èstring trimleft"
	s'tr              "×Èstring trimright"
	s'tol             "×Èstring tolower"
	s'tt              "×Èstring totitle"
	s'tou             "×Èstring toupper"
	s'we              "×Èstring wordend"
	s'ws              "×Èstring wordstart"
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Tcl::buildTclXElectrics" --
 # 
 # If the user wants to recognize TclX commands, we create completions.
 # 
 # --------------------------------------------------------------------------
 ##

proc Tcl::Completion::buildTclXElectrics {} {
    
    global TclmodeVars Tclelectrics Tcl::tclXKeywords
    
    if {!$TclmodeVars(recogniseTclX)} {
	foreach keyword $Tcl::tclXKeywords {
	    unset -nocomplain Tclelectrics($keyword)
	}
	return
    }
    
    # ×××× TclX Keyword Completions ×××× #
    
    array set Tclelectrics {
	dirs            ""
	commandloop     " ¥?-async?¥ ¥?-interactive on|off|tty?¥ ¥?-prompt1 cmd?¥\
	  ¥?-prompt2 cmd?¥ ¥?-endcommand cmd?¥"
	echo            " ¥?str ...?¥"
	for_array_keys  " ¥var¥ ¥array_name¥ ¥code¥"
	for_recursive_glob " ¥var¥ ¥dirlist¥ ¥globlist¥ ¥code¥"
	loop            " ¥first¥ ¥limit¥ ¥?increment?¥ ¥body¥"
	popd            ""
	pushd           " ¥?dir?¥"
	recursive_glob  " ¥dirlist¥ ¥globlist¥"
	showproc        " ¥?procname ...?¥"
	try_eval        " ¥code¥ ¥catch¥ ¥?finally?¥"
	
	cmdtrace        " ¥level|on¥ ¥?noeval?¥ ¥?notruncate?¥ ¥?procs?¥ ¥?fileid?¥ ¥?command cmd?¥"
	edprocs         " ¥?proc ...?¥"
	profile         " ¥?-commands?¥ ¥?-eval?¥ ¥on|off¥"
	profrep         " ¥profDataVar¥ ¥sortKey¥ ¥?outFile?¥ ¥?userTitle?¥"
	saveprocs       " ¥fileName¥ ¥?proc...?¥"
	
	alarm           " ¥seconds¥"
	execl           " ¥?-argv0 argv0?¥ ¥prog¥ ¥?arglist?¥"
	chroot          " ¥dirname¥"
	fork            ""
	kill            " ¥?-pgroup?¥ ¥?signal?¥ ¥idlist¥"
	link            " ¥?-sym?¥ ¥srcpath¥ ¥destpath¥"
	nice            " ¥?priorityincr?¥"
	readdir         " ¥?-hidden?¥ ¥dirPath¥"
	signal          " ¥?-restart?¥ ¥action¥ ¥siglist¥ ¥?command?¥"
	sleep           " ¥seconds¥"
	system          " ¥cmdstr1¥ ¥?cmdstr2 ...?¥"
	sync            " ¥?fileId?¥"
	times           ""
	umask           " ¥?octalmask?¥"
	wait            " ¥?-nohang?¥ ¥?-untraced?¥ ¥?-pgroup?¥ ¥?pid?¥"
	
	bsearch         " ¥fileId¥ ¥key¥ ¥?retvar?¥ ¥?compare_proc?¥"
	chmod           " ¥[-fileid]¥ ¥mode¥ ¥filelist¥"
	chown           " ¥[-fileid]¥ ¥owner|{owner group}¥ ¥filelist¥"
	chgrp           " ¥[-fileid]¥ ¥group¥ ¥filelist¥"
	dup             " ¥fileId¥ ¥?targetFileId?¥"
	fcntl           " ¥fileId¥ ¥attribute¥ ¥?value?¥"
	flock           " ¥options¥ ¥fileId¥ ¥?start?¥ ¥?length?¥ ¥?origin?¥"
	for_file        " ¥var¥ ¥filename¥ ¥code¥"
	funlock         " ¥fileId¥ ¥?start?¥ ¥?length?¥ ¥?origin?¥"
	ftruncate       " ¥[-fileid]¥ ¥file¥ ¥newsize¥"
	lgets           " ¥fileId¥ ¥?varName?¥"
	pipe            " ¥?fileId_var_r fileId_var_w?¥"
	read_file       " ¥different syntaxes available¥"
	select          " ¥readfileIds¥ ¥?writefileIds?¥ ¥?exceptfileIds?¥ ¥?timeout?¥"
	write_file      " ¥fileName¥ ¥string¥ ¥?string...?¥"
	
	host_info       " ¥options¥"
	
	scanfile        " ¥?-copyfile copyFileId?¥ ¥contexthandle¥ ¥fileId¥"
	scanmatch       " ¥?-nocase?¥ ¥contexthandle¥ ¥?regexp?¥ ¥commands¥"
	
	abs             "\(¥args¥\)"
	acos            "\(¥args¥\)"
	asin            "\(¥args¥\)"
	atan2           "\(¥args¥\)"
	atan            "\(¥args¥\)"
	ceil            "\(¥args¥\)"
	cos             "\(¥args¥\)"
	cosh            "\(¥args¥\)"
	double          "\(¥args¥\)"
	exp             "\(¥args¥\)"
	floor           "\(¥args¥\)"
	fmod            "\(¥args¥\)"
	hypot           "\(¥args¥\)"
	int             "\(¥args¥\)"
	log10           "\(¥args¥\)"
	log             "\(¥args¥\)"
	pow             "\(¥args¥\)"
	round           "\(¥args¥\)"
	sin             "\(¥args¥\)"
	sinh            "\(¥args¥\)"
	sqrt            "\(¥args¥\)"
	tan             "\(¥args¥\)"
	tanh            "\(¥args¥\)"
	max             " ¥num1¥ ¥?... numN?¥"
	min             " ¥num1¥ ¥?... numN?¥"
	random          " ¥limit|seed¥ ¥?seedval?¥"
	
	intersect       " ¥lista¥ ¥listb¥"
	intersect3      " ¥lista¥ ¥listb¥"
	lassign         " ¥list¥ ¥var¥ ¥?var...?¥"
	lcontain        " ¥list¥ ¥element¥"
	lempty          " ¥list¥"
	lmatch          " ¥?mode?¥ ¥list¥ ¥pattern¥"
	lrmdups         " ¥list¥"
	lvarcat         " ¥var¥ ¥string¥ ¥?string...?¥"
	lvarpop         " ¥var¥ ¥?indexExpr?¥ ¥?string?¥"
	lvarpush        " ¥var¥ ¥string¥ ¥?indexExpr?¥"
	union           " ¥lista¥ ¥listb¥"
	
	keyldel         " ¥listvar¥ ¥key¥"
	keylget         " ¥listvar¥ ¥?key?¥ ¥?retvar|{}?¥"
	keylkeys        " ¥listvar¥ ¥?key?¥"
	keylset         " ¥listvar¥ ¥key¥ ¥value¥ ¥?key2 value2 ...?¥"
	
	ccollate        " ¥?-local?¥ ¥string1¥ ¥string2¥"
	cconcat         " ¥?string1?¥ ¥?string2?¥ ¥?...?¥"
	cequal          " ¥string¥ ¥string¥"
	cindex          " ¥string¥ ¥indexExpr¥"
	clength         " ¥string¥"
	crange          " ¥string¥ ¥firstExpr¥ ¥lastExpr¥"
	csubstr         " ¥string¥ ¥firstExpr¥ ¥lengthExpr¥"
	ctoken          " ¥strvar¥ ¥separators¥"
	ctype           " ¥?-failindex var?¥ ¥class¥ ¥string¥"
	replicate       " ¥string¥ ¥countExpr¥"
	translit        " ¥inrange¥ ¥outrange¥ ¥string¥"
	
	catopen         " ¥?-fail|-nofail?¥ ¥catname¥"
	catgets         " ¥catHandle¥ ¥setnum¥ ¥msgnum¥ ¥defaultstr¥"
	catclose        " ¥?-fail|-nofail?¥ ¥cathandle¥"
	mainloop        ""
	
	tclhelp         " ¥?addpaths?¥"
	help            " ¥?subject/helppage?¥"
	helpcd          " ¥?subject?¥"
	helppwd         ""
	apropos         " ¥pattern¥"
	
	auto_commands   " ¥?-loaders?¥"
	buildpackageindex " ¥libfilelist¥"
	convert_lib     " ¥tclIndex¥ ¥packagelib¥ ¥?ignore?¥"
	loadlibindex    " ¥libfile.tlib¥"
	auto_packages   " ¥?-location?¥"
	auto_load_file  " ¥file¥"
	searchpath      " ¥path¥ ¥file¥"
    }

    # ×××× TclX Commands With Options ×××× #
    
    # All commands listed in the 'commandsWithOptions' list will be used by
    # [Tcl::Completion::PickOption] below, and possibly called by electric
    # contractions via indirection.
    
    # infox
    lappend commandsWithOptions infox
    array set Tclelectrics {
	"infox patchlevel"      ""
	"infox have_fchown"     ""
	"infox have_fchmod"     ""
	"infox have_flock"      ""
	"infox have_fsync"      ""
	"infox have_ftruncate"  ""
	"infox have_msgcats"    ""
	"infox have_posix_signals"  ""
	"infox have_signal_restart" ""
	"infox have_truncate"   ""
	"infox have_waitpid"    ""
	"infox appname" ""
	"infox applongname"     ""
	"infox appversion"      ""
	"infox apppatchlevel"   ""
    }
    # id
    lappend commandsWithOptions id
    array set Tclelectrics {
	"id user"               " ¥?name?¥"
	"id userid"             " ¥?uid?¥"
	"id convert"            " ¥userid¥ ¥uid¥"
	"id convert"            " ¥user¥ ¥name¥"
	"id group"              " ¥?name?¥"
	"id groupid"            " ¥?gid?¥"
	"id groups"             ""
	"id groupids"           ""
	"id convert"            " ¥groupid¥ ¥gid¥"
	"id convert"            " ¥group¥ ¥name¥"
	"id effective"          " ¥user¥"
	"id effective"          " ¥userid¥"
	"id effective"          " ¥group¥"
	"id effective"          " ¥groupid¥"
	"id effective"          " ¥groupids¥"
	"id host"               ""
	"id process"            " ¥?parent|group|group set?¥"
	"id host"               ""
    }
    # fstat
    lappend commandsWithOptions fstat
    array set Tclelectrics {
	"fstat fileId"          " ¥?item?¥"
	"fstat stat"            " ¥arrayvar¥"
    }
    # scancontext
    lappend commandsWithOptions scancontext
    array set Tclelectrics {
	"scancontext create"    ""
	"scancontext delete"    " ¥contexthandle¥"
	"scancontext copyfile"  " ¥contexthandle¥ ¥?filehandle?¥"
    }
    
    # Allows the user to select required options for some TclX commands.  Any
    # "two-word" electric defined above will be included below.
    
    variable ElectricCommandOptions
    variable LastElectricOption
    set electrics [array names Tclelectrics]
    foreach command $commandsWithOptions {
	# Create the options list that will be presented in the listpick.
	set commandOptions [list]
	set options [lsearch -all -glob -inline $electrics "$command *"]
	foreach item $options {
	    lappend commandOptions [lindex $item 1]
	}
	set commandOptions [lsort -dictionary -unique $commandOptions]
	set ElectricCommandOptions($command) $commandOptions
	# Create the default option in the listpick.
	if {![info exists LastElectricOption($command)]} {
	    set LastElectricOption($command) [lindex $commandOptions 0]
	}
	# Create a new electric for this item.
	set Tclelectrics($command) "×\[Tcl::Completion::PickOption $command\]"
	# Create a new variable allowing e.g. "string co" to be completed to
	# "string compare".
	global Tcl${command}cmds
	set Tcl${command}cmds $ElectricCommandOptions($command)
    }
    return
}

##
 # -------------------------------------------------------------------------
 # 
 # "Tcl::Completion::PickOption" --
 # 
 # Allowing the user to select required options for some Tcl commands, an
 # alternative if you can never remember the abbreviations which are created
 # by [Tcl::buildTclElectrics].  Any defined "two-word" electric will be
 # directed here.  The option chosen is remembered for the next round.
 # 
 # Contibuted by Craig Barton Upright.
 # 
 # ------------------------------------------------------------------------
 ##

proc Tcl::Completion::PickOption {command} {
    
    variable ElectricCommandOptions
    variable LastElectricOption
    
    if {![info exists ElectricCommandOptions($command)]} {
	return ""
    } elseif {![llength [set options $ElectricCommandOptions($command)]]} {
	return ""
    } elseif {[llength $options] == 1} {
	set lastOption [lindex $options 0]
    } else {
	set p "Choose an option for $command :"
	set L [list $LastElectricOption($command)]
	set lastOption [listpick -p $p -L $L $options]
    }
    # This makes use of indirection.
    return "×È$command [set LastElectricOption($command) $lastOption]"
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# Tcl Command Electrics
# 
# Allows all procedures currently recognized by the Tcl interpreter to be
# used for electric completions, esp when invoked by [completion::cmd].
# 
# Contibuted by Craig Barton Upright.
# 

namespace eval Tcl {}

proc Tcl::rebuildTclElectrics {args} {
    
    global Tclcmds Tclelectrics
    
    variable electricCount 0
    
    watchCursor
    # Create the basic list of 'Tclcmd' specific to the current intrepreter.
    ensureset Tclcmds [list]
    Tcl::Completion::buildTclCmds
    # First build the basic set of Tcl command completions.
    Tcl::Completion::buildTclElectrics
    # Now build the set of TclX command completions.
    Tcl::Completion::buildTclXElectrics
    # Add more templates?
    foreach procName $Tclcmds {
	if {![info exists Tclelectrics($procName)]} {
	    Tcl::procElectrics $procName
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Tcl::procElectrics" --
 # 
 # Create a "Tclelectrics" array item for the given "procName".  Note that
 # [Tcl::getProcArgs] will auto_load the "procName" when necessary, so we
 # only call that if the procedure already exists.  The electric completion
 # is defined for both "$procName" and "::$procName".
 # 
 # --------------------------------------------------------------------------
 ##

proc Tcl::procElectrics {procName} {
    
    global Tclelectrics
    
    variable interpCmd
    
    set procName [string trimleft $procName ":"]
    set ProcName "::$procName"
    if {[llength [$interpCmd [list info procs $ProcName]]]} {
	if {[catch {Tcl::getProcArgs $ProcName} procArgs]} {
	    return
	}
	set electric " "
	foreach arg $procArgs {
	    append electric "¥" $arg "¥ "
	}
	set electric [string trimright $electric]
	array set Tclelectrics [list $procName $electric $ProcName $electric]
    }
    return
}

# Call this now.
Tcl::rebuildTclElectrics

# ===========================================================================
# 
# .