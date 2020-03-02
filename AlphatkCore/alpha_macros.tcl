## -*-Tcl-*-
 # ###################################################################
 #  Alphatk - the editor
 # 
 #  FILE: "alpha_macros.tcl"
 #                                    created: 04/12/1998 {23:17:46 PM}
 #                                last update: 01/21/2005 {10:57:26 AM}
 #  Description:
 #  
 #  Core support for recording Keyboard Macros.
 #  
 #  The proc [alpha::executeAndRecord] is called by Binding and Menu scripts
 #  in other Alphatk core files, see its annotation below.  The only other
 #  item that gets recorded is an unbound keystroke that inserts a single
 #  character into the window, via [::tw::keypressed] -- we redefine this
 #  procedure as necessary when Macro Recording starts and ends, or when
 #  recording is aborted for any reason.
 #  
 #  Author: Vince Darley
 #  E-mail: vince.darley@kagi.com
 #    mail: Flat 10, 98 Gloucester Terrace, London W2 6HP
 #     www: http://www.purl.org/net/alphatk
 #  
 # Includes contributions from Craig Barton Upright
 #  
 # Copyright (c) 1998-2005  Vince Darley and Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # In particular, while this is 'open source', it is NOT free, and
 # cannot be copied in full or in part except according to the terms
 # of the license agreement.
 # 
 # ###################################################################
 ##

proc alpha_macros.tcl {} {}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Core Macro Commands ×××× #
# 
# These "Core Macro Commands" can be called directly by any AlphaTcl Binding,
# using the sequence
#  
#   [macro::startRecording]
#   [macro::endRecording]
#   [macro::execute]
#  
# as is the case with the "Emacs" package.  For this reason we need to make
# sure that we're offering appropriate status bar messages.
#  
# Other code (such as the "Macros" package) might call these from within other
# procedures, modifying some of the UI such as messages, error handling, etc.
# 
# Other "core" Macro Recording commands, such as
# 
#   [macro::current]
#   [macro::execute]
#   
# are currently defined in AlphaTcl's "coreFixes.tcl" file, although they
# should perhaps be placed in "coreImplementations.tcl".
#  

namespace eval macro {
    
    variable Current ""
    variable currentScript [list]
    variable recording 0
    # Remember our original "textInsert" procedure script.
    variable textInsertProc "::tw::keypressed"
    variable textInsertArgs [info args $textInsertProc]
    variable textInsertBody [info body $textInsertProc]
    # Define a script which will record the keystroke.
    variable textInsertMacroBody {
	macro::suspendRecording
	set result [eval $::macro::textInsertBody]
	macro::resumeRecording
	if {$char ne ""} {
	    macro::recordCommand "typeText \"[quote::Insert $char]\""
	}
	return $result
    } 
} 

##
 # --------------------------------------------------------------------------
 #
 # "macro::startRecording" --
 # 
 # Start recording a Keyboard Macro.
 # 
 # If we were not recording in the first place, then we simply inform the user
 # (without throwing an error).
 # 
 # Otherwise, we have the following responsibilities:
 # 
 # (1) Redefine our "Text Insert" procedure to our new version.
 # (2) Set the Macro Recording Status to "1". 
 # (3) Inform the user that Macro Recording has started.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::startRecording {} {
    
    variable currentScript [list]
    
    if {([macro::recording] != 0)} {
	# We were already recording.
	macro::recording 0
	macro::redefineTextInsertProc
	macro::current ""
	error "Cancelled -- Recording was already in progress\
	  but has now been aborted."
    } else {
	macro::recording 1
	macro::redefineTextInsertProc
	status::msg "Defining Keyboard MacroÉ"
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "macro::endKeyboardMacro" --
 # 
 # Stop recording a Keyboard Macro.
 # 
 # If we were not recording in the first place, then we simply inform the user
 # (without throwing an error).
 # 
 # Otherwise, we have the following responsibilities:
 # 
 # (1) Redefine our "Text Insert" procedure to the original version.
 # (2) Reset the Macro Recording Status.
 # (3) Reformat the Macro Script as necessary.
 # (4) Save the Macro Script for use by other Alphatk core commands and 
 #     Alphatcl procedures.
 # (5) Inform the user that Macro Recording has ended.
 # 
 # The current Macro Recording Status is most likely "2" when this is called,
 # because recording should have been suspended before this procedure is
 # executed.  It is therefore an unreliable test to determine if there was an
 # error thrown during the Macro Recording sequence -- we're counting on
 # [alpha::executeAndRecord] to capture this, and to appropriately adjust the
 # Macro Recording Status.
 #
 # --------------------------------------------------------------------------
 ##

proc macro::endRecording {} {
    
    variable currentScript
    variable textInsertProc
    variable textInsertArgs
    variable textInsertBody
    
    if {([macro::recording] == 0)} {
	# We were not recording, but we should make sure that our text
	# insertion proc is properly redefined.
	macro::redefineTextInsertProc
	error "Cancelled -- Not Recording!"
    }
    # Collect the Current Script and reformat as necessary.
    set macroScript [cleanupScript $currentScript]
    macro::current "proc macroName \{\} \{\n${macroScript}\n\}"
    # This has to come last (or at least after we have added a new
    # script to [macro::current]) to properly dim/enable the Macro
    # Recording items.
    macro::recording 0
    macro::redefineTextInsertProc
    status::msg "Keyboard Macro Complete"
    return
}

proc macro::cleanupScript {currentScript} {
    set pat {^ *typeText +}
    set lastCommand ""
    set macroCommands [list]
    foreach command $currentScript {
	# Clean up 'typeText' commands by combining them into a
	# string.
	if {[regexp -- $pat $command] && [regexp -- $pat $lastCommand]} {
	    set newInsert [lindex $command 1]
	    set oldInsert [lindex $lastCommand 1]
	    set macroCommands [lreplace $macroCommands end end]
	    set newIns [quote::Insert ${oldInsert}${newInsert}]
	    set command "typeText \"${newIns}\""
	}
	lappend macroCommands \n${command}
	set lastCommand $command
    } 
    set macroScript [list]
    foreach line $macroCommands {
	if {![string length [set line [string trim $line]]]} {
	    continue
	} 
	lappend macroScript "    $line"
    }
    set macroScript [string trim [join $macroScript "\n"]]
    return $macroScript
}

##
 # --------------------------------------------------------------------------
 #
 # "macro::redefineTextInsertProc" --
 # 
 # Redefine [::tw::keypressed] to either start or stop recording individual
 # (unbound) keystrokes.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::redefineTextInsertProc {} {
    
    variable recording
    variable textInsertProc
    variable textInsertArgs
    variable textInsertBody
    variable textInsertMacroBody
    
    if {($recording == 0)} {
	eval [list proc $textInsertProc $textInsertArgs $textInsertBody]
    } else {
	eval [list proc $textInsertProc $textInsertArgs $textInsertMacroBody]
    }
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Macro Recording ×××× #
# 
# The procedure [alpha::executeAndRecord] below will be called by each
# 
# (1) Binding script defined using [Bind]
# (2) Menu script defined using [Menu]
# 
# as well as
# 
# (3) [::tw::keypressed], but only when Macro Recording has been turned on.
# 
# If recording has been turned off, then [alpha::executeAndRecord] should not
# be calling anything in this section besides [macro::recording].
# 
# Otherwise, the recording will first be suspended, the command will be
# executed, recording will be resumed, and (if appropriate) the command will
# be properly recorded in the internal Current Macro Script variable.
# 
# The internal macro "$recording" variable should only be accessed via
# [macro::recording] by any procedure outside of this section.  Note that the
# AlphaTcl package "Macros" will place a trace on this variable, so it should
# only be changed when absolutely necessary.
# 

##
 # --------------------------------------------------------------------------
 #
 # "macro::recording" --
 #
 # If no "newValue" is supplied, return the current Macro Recording Status,
 # otherwise change the status to the new value.
 # 
 # If recording is being set to some new value, then we automatically define
 # the "Text Insert" procedure appropriately.
 # 
 # This procedure could possibly be defined in AlphaTcl, in either of the
 # core files "coreFixes.tcl" or "coreImplementations.tcl".
 #
 # --------------------------------------------------------------------------
 ##

proc macro::recording {{newValue ""}} {
    
    variable recording
    
    if {[string length $newValue]} {
	set recording $newValue
    }
    return $recording
}

##
 # --------------------------------------------------------------------------
 #
 # "macro::suspendRecording" --
 # "macro::resumeRecording" --
 #
 # This is how we avoid recording 'nested' commands, i.e. when the current
 # script being executed calls makes another call to [macro::recordCommand].
 # Because [alpha::executeAndRecord] is only called by top-level events,
 # this safeguard should be unnecessary, but it is very easy to implement
 # with low overhead.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::suspendRecording {} {
 
    variable recording
    if {($recording > 0)} {
	incr recording 1
    } 
    return
}

proc macro::resumeRecording {} {

    variable recording
    if {($recording > 1)} {
	incr recording -1
    } 
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "macro::recordCommand" --
 #
 # If we are recording a macro (and it has not been suspended), add the item
 # to our Current Script list.  The calling proc _must_ supply a command in
 # order for it to be recorded -- [info level 1] might throw an error!  (The
 # default empty string for the "command" argument is present only to avoid
 # throwing unnecessary errors.)
 #
 # --------------------------------------------------------------------------
 ##

proc macro::recordCommand {{command ""}} {
    
    variable recording

    if {($recording != 1) || ![string length $command]} {
	return
    } 
    variable currentScript
    lappend currentScript $command
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Recording Top-Level Events ×××× #
# 
# This section could possibly be moved into some other AlphatkCore file if
# it needs to be more obvious how Menu and Binding scripts are executed,
# perhaps in "alpha_menus.tcl" where it is actually used.
# 

namespace eval alpha {
    variable recordingCommand ""
}

##
 # --------------------------------------------------------------------------
 #
 # "alpha::executeAndRecord" --
 #
 # This procedure will be called only by top-level events, including
 # 
 # (1) Binding script defined using [Bind]
 # (2) Menu script defined using [Menu]
 # 
 # but should (i.e. by deliberate design) only be called once during the
 # execution of some operation.
 # 
 # If we are not currently recording a macro, we simply execute the script and
 # return the results.  Otherwise, we 
 # 
 # (1) Suspend the recording
 # (2) Execute the command
 # (3) Resume recording
 # (4) Record the script
 # 
 # Steps (1) and (3) are safeguards just in case the "deliberate design"
 # failed to take something into account..l
 # 
 # If the execution of the command throws an error, Macro Recording will be
 # aborted.  (The default empty string for the "command" argument is present
 # only to avoid throwing unnecessary errors.)
 # 
 # If the command is going to at some point call [macro::startRecording],
 # then our "macro::recording" variable should have initially been "0",
 # which means that it won't get recorded.
 # 
 # If the command is going to at some point call [macro::endRecording], then
 # that procedure will set our "macro::recording" variable to "0" before it
 # is done, letting [macro::recordingCommand] know that the command
 # shouldn't be recorded.
 #
 # --------------------------------------------------------------------------
 ##

proc alpha::executeAndRecord {{command ""}} {
    
    variable recordingCommand $command
    
    if {![string length $command]} {
        return
    } elseif {([macro::recording] == 0)} {
        return [uplevel 1 [list eval ${::alpha::recordingCommand}]]
    } 
    # We are recording a macro, so suspend the recording, execute the script,
    # resume recording, and then record the command.
    variable recordingCommand $command
    macro::suspendRecording
    if {[catch {uplevel 1 [list eval ${::alpha::recordingCommand}]} result]} {
	macro::recording 0
	macro::redefineTextInsertProc
	error $result
    } else {
	macro::resumeRecording
	macro::recordCommand $command
    }
    return $result
}

# ===========================================================================
# 
# .