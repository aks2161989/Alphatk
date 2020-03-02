## -*-Tcl-*-
 # ###################################################################
 #  Error - Complements 'error' and 'catch'
 # 
 #  FILE: "error.tcl"
 #                                    created: 2/24/98 {10:14:10 PM} 
 #                                last update: 12/29/2004 {09:22:49 AM} 
 #                                    version: 1.2
 #  Author: Jonathan Guyer
 #  E-mail: <jguyer@his.com>
 #     www: <http://www.his.com/~jguyer/>
 #  
 # Copyright (c) 1998-2004  Jonathan Guyer
 # 
 # Distributed under a Tcl-style BSD license.
 #  
 # ###################################################################
 ##

## 
 # Just like it says
 ##
newPref flag beepOnError 0

## 
 # Causes 'try' scripts to abort if they are executing this many levels deep 
 # in the execution stack (see 'info level'). A negative value allows 
 # unlimited nesting. 
 ##
newPref variable maximumLevel 25 global

# We set the "displayErrorsIn" variable to the lowest setting for stable
# releases, and the highest for all others (i.e. betas) based on the version
# number of the AlphaTcl library.
if {![regexp -- {[a-zA-Z]} [set alpha::tclversion]]} {
    set defaultErrorDisplay "status bar"
} else {
    set defaultErrorDisplay "new window"
}
# Errors can be reported in the status bar, a dialog, or a new window
newPref variable displayErrorsIn $defaultErrorDisplay global \
  {setErrorVariables} [list "status bar" "dialog" "new window"]
unset defaultErrorDisplay

# --------------------------------------------------------------------
# 
# CODE TAGGED FOR REMOVAL
# 
# After the final release of AlphaTcl 8.0 these lines can be removed.
# 

# If the user had changed these previously (when they were formal
# preferences), we'll make sure that the values are no longer saved.
foreach oldPref [list "::errorReporting" "::errorDisplay"] {
    if {[info exists $oldPref]} {
	hook::register "quitHook" "prefs::remove $oldPref"
    } 
}
unset oldPref

##
 # --------------------------------------------------------------------------
 # 
 # "setErrorVariables" --
 # 
 # We use the variables "errorReporting" and "errorDisplay" below when
 # determining how error messages will be displayed to the user.  These used
 # to be separate preferences, but now the "displayErrorsIn" variable is the
 # only one presented to be changed.  We could adjust all of the code below
 # to simply query this one preference, but for now we use the legacy code
 # and just adjust these variables accordingly.
 # 
 # --------------------------------------------------------------------------
 ##

proc setErrorVariables {args} {
    
    global displayErrorsIn errorReporting errorDisplay
    
    switch -- $displayErrorsIn {
	"status bar" {
	    set errorReporting taciturn
	    set errorDisplay "alertnote always"
	}
	"dialog" {
	    set errorReporting verbose
	    set errorDisplay "alertnote always"
	}
	"new window" {
	    set errorReporting pedantic
	    set errorDisplay "window always"
	}
    }
}

# Call this now.
setErrorVariables

lunion flagPrefs(Errors) beepOnError
lunion varPrefs(Errors) displayErrorsIn maximumLevel
	
set Tclelectrics(try) " \{\n\t¥script¥\n\} -onError \{\n\t¥error code¥ \{\n\t\t¥error script¥\n\t\}\n\} ¥¥"

ensureset errorMsg ""
ensureset errorWhile "" 
ensureset errorCode ""
ensureset errorScript ""
ensureset errorDisplayedAlready 0

namespace eval try {}

## 
 # -------------------------------------------------------------------------
 # 
 # "try" --
 # 
 # The try command executes its script argument in the stack frame that 
 # called it.  In the event of an error, try matches the global 
 # errorCode against each of any pattern arguments, specified by the 
 # -onError parameter, in order.  As soon as it finds a pattern that 
 # matches errorCode it evaluates the following body argument by 
 # passing it recursively to the Tcl interpreter and returns the 
 # result of that evaluation.  The last pattern argument is always a 
 # default to display the error (you may explicitly define a default 
 # argument if this behavior is not desired). Optionally, the errorMsg 
 # can be used for comparison, instead of errorCode.
 # 
 # The syntax is largely that of switch, although the options follow 
 # script for both syntactic and performance reasons.  The default 
 # comparision mode for try is -glob, instead of -exact.  Unlike 
 # switch, try does not support separate pattern/command arguments; 
 # all must be provided as a list argument to the -onError optional 
 # parameter.  The following options are currently supported:
 # 
 # -onError {pattern body ?pattern body ...?}: errorCode is compared to 
 # 	each pattern in order.  When a match is found, body is 
 # 	executed in the stack frame that called try.  If this option 
 # 	is missing, all errors will be displayed by the default 
 # 	routine.
 #     
 # -exact: Use exact matching when comparing errorCode to a pattern.
 # 
 # -glob: When matching errorCode to the patterns, use glob-style 
 #   matching (i.e. the same as implemented by the string match 
 # 	command). This is the default.
 # 	
 # -regexp: When matching errorCode to the patterns, use regular
 #     expression matching (i.e. the same as implemented by the regexp 
 #     command).
 # 	
 # -display: Override the user's setting for errorDisplay.
 # 	Options are 'alertnote always', 
 # 	and 'window always'.
 # 
 # -reporting: Override the user's setting for errorReporting.
 # 	Options are taciturn, terse, verbose, pedantic, and log.
 # 			
 # -while: Short phrase to describe action taking place in event of an 
 # 	error.
 # 
 # -code: Match errorCode against the -onError patterns. This is the 
 #     default.
 # 	
 # -message: Match the errorMsg against the -onError patterns.
 # 
 # The -onError scripts execute in the frame that calls try, so 
 # all variables local to that frame are available, as are the global 
 # variables errorCode, errorInfo, and errorMsg (without having 
 # to declare them global).
 # 
 # If a body is specified as Ò-Ó it means that the  body  for
 # the  next  pattern  should also be used as the body for this
 # pattern (if the next pattern also has a body of  Ò-Ó  then
 # the body after that is used, and so on).  This feature makes
 # it possible to share a single body among several patterns.
 # 
 # Below are some examples of try commands:
 # 
 #   try {
 # 		 error "" "" aaab
 # 	 } -onError {
 #       ^a.*b$ -
 #       b {format 1}
 #       a* {format 2}
 #       default {format 3}
 #   } -regexp
 # will return 1, and
 # 
 #   try {
 # 		 error "" "" xyz
 # 	 } -onError {
 #       a
 #         -
 #       b
 #         {format 1}
 #       a*
 #         {format 2}
 #       default
 #         {format 3}
 #   }
 # will return 3.
 # 
 # NOTE: The old -depth option has been eliminated to allow delayed argument
 # processing, resulting in an 80% speed increase for error-free scripts. 
 # Instead of 
 # 
 # 	try {script} -depth n
 # 
 # now use
 # 
 # 	try::level n {script}
 # 
 # to achieve the same result.
 # 
 # NOTE:
 # A 'try' block adds about 0.6 ticks to the execution of an error-free
 # script on my 7100/66 so, judiciously applied, there's not much of a penalty 
 # in using it. 
 # -------------------------------------------------------------------------
 ##
proc try {script args} {
    global maximumLevel
    
    # Make sure we're not nested too deeply in the execution stack.
    if {$maximumLevel >= 0 && [info level] > $maximumLevel} {
	global errorMsg errorInfo errorCode
	
	# set everything up for a 'pedantic' report
	set errorMsg "Maximum level of ${maximumLevel} exceeded"
	set errorInfo "$errorMsg\n    while executing\ntry\{$script\}"
	set errorCode [list TRY LEVEL $errorMsg]
	
	eval try::handleError $script $args
	
	# rethrow the error to abort execution
	return -code error -errorcode $errorCode $errorMsg 
    } 
    
    if {[catch {uplevel 1 $script} result]} {
	global errorMsg errorInfo
	
	# Strip the last five lines off the error stack (they're
	# from the "uplevel" command).
	#
	set new [split $errorInfo \n]
	set new [lrange $new 0 [expr {[llength $new] - 6}]]
	lappend new "    invoked from within" "try \{$script\}"
	set errorInfo [join $new \n]
	
	set errorMsg $result
	set result [eval try::handleError [list $script] $args]
    }
    
    return $result
}

## 
 # -------------------------------------------------------------------------
 # 
 # "try::level" --
 # 
 #  Try to execute a script at a specified level in the execution stack.
 #  Arguments are those of 'try'.
 # -------------------------------------------------------------------------
 ##
proc try::level {level args} {
    uplevel $level ::try $args
}


## 
 # -------------------------------------------------------------------------
 # 
 # "try::handleError" --
 # 
 #  Parse args and deal with 'errorCode' accordingly.
 #  This routine is only used internally by 'try'.
 #
 # --Version--Author------------------Changes-------------------------------
 #    1.0     <jguyer@his.com> original
 #    1.0.2   <jguyer@his.com> fixed default script
 # -------------------------------------------------------------------------
 ##

proc try::handleError {script args} {
    
    global errorCode errorMsg
    global maximumLevel errorReporting errorDisplay 
    global errorWhile errorScript
    global errorDisplayedAlready
    
    set errorDisplayedAlready 0
    set errorScript $script
    
    set opts(-onError) {}
    set opts(-regexp) 0
    set opts(-exact) 0
    set opts(-glob) 1
    set opts(-message) 0
    set opts(-code) 1
    set opts(-reporting) $errorReporting
    set opts(-display) $errorDisplay
    
    getOpts {onError reporting display while}
    
    # temporarily override user settings
    set savedReporting $errorReporting
    set errorReporting $opts(-reporting)
    
    set savedDisplay $errorDisplay
    set errorDisplay $opts(-display)
    
    if {[info exists opts(-while)]} {
	global errorMsg
	set errorWhile $opts(-while)
	append errorMsg " while $opts(-while)"
    } else {
	set errorWhile ""
    }
    
    if {$opts(-exact)} {
	set compareStyle {-exact}
	# no default script
    } elseif {$opts(-regexp)} {
	set compareStyle {-regexp}
	set default [lsearch $opts(-onError) default]
	if {($default % 2) != 0} {
	    # no default script yet, so add one
	    set opts(-onError) [concat $opts(-onError) default error::display]
	}		
    } else {
	set compareStyle {-glob}
	set default [lsearch $opts(-onError) default]
	if {($default % 2) != 0} {
	    # no default script yet, so add one
	    set opts(-onError) [concat $opts(-onError) default error::display]
	}		
    }
    
    if {$opts(-message)} {
	set compareWith $errorMsg
    } else {
	set compareWith $errorCode
    }
    
    set errorSwitch "uplevel 2 \{global errorMsg errorInfo errorCode;"
    append errorSwitch "switch $compareStyle -- \{$compareWith\} \{$opts(-onError)\}\}"
    
    set result [eval $errorSwitch]
    
    set errorReporting $savedReporting
    set errorDisplay $savedDisplay
    
    return $result
}

namespace eval error {}

# ×××× display styles ×××× #

# Tcl equivalent of what happens in Alpha 8 in C.  Used by Alphatk,
# and can be used as a 'bgerror' procedure.  (In fact, it could
# be a good idea to simply call this procedure 'bgerror')
proc error::occurred {msg} {
    if {[string match -nocase "*cancel*" $msg]} {
	# Patterns which appear to be some sort of 'cancel' operation
	# simply lead to a message in the status bar.  All other 
	# errors throw an error.
	if {($msg eq "cancel")} {
	    set msg "Cancelled."
	}
	status::msg $msg
    } else {
	global errorMsg errorDisplayedAlready
	set errorMsg $msg
	set errorDisplayedAlready 0
	error::display
    }
}

proc error::isCancel {msg} {
    string match -nocase "*cancel*" $msg
}

## 
 # -------------------------------------------------------------------------
 # 
 # "error::display" --
 # 
 #  Display the error residing in 'errorMsg', 'errorCode', and 'errorInfo' 
 #  in the format specified by user settings.
 # 
 # --Version--Author------------------Changes-------------------------------
 #    1.0     <jguyer@his.com> original
 # -------------------------------------------------------------------------
 ##
proc error::display {} {
    global errorMsg
    global errorReporting errorDisplay beepOnError
    global errorDisplayedAlready
    
    # This flag is set at the end of this proc and cleared
    # at the beginning of a 'try'. This avoids certain situations,
    # like recursion errors, that would produce multiple alerts
    # otherwise.
    if {$errorDisplayedAlready} {
	return
    } 
    
    if {$beepOnError} {
	beep
    } 
    
    # Display the error according to user-specified preferences.
    error::${errorReporting}Display $errorMsg $errorDisplay
    
    # Make sure a duplicate error message isn't
    # inflicted on the user.
    set errorDisplayedAlready 1
}

## 
 # -------------------------------------------------------------------------
 # 
 # "error::taciturnDisplay" --
 # 
 #  Display $errorMsg in the message bar.
 # -------------------------------------------------------------------------
 ##
proc error::taciturnDisplay {errorMsg {display ""}} {
    # display is ignored
	
    status::msg $errorMsg
}

## 
 # -------------------------------------------------------------------------
 # 
 # "error::terseDisplay" --
 # 
 #  Just display $errorMsg.
 # -------------------------------------------------------------------------
 ##
proc error::terseDisplay {errorMsg {display "alertnote always"}} {	
    switch -- $display {
	"alertnote always" {
	    alertnote $errorMsg
	}
	"alertnote preferred" {
	    # Obsolete code path.  Remove in the future
	    alertnote $errorMsg
	}
	"window always" {
	    error::window [error::nudgeMessage $errorMsg]
	}
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "error::verboseDisplay" --
 # 
 #  Display $errorMsg and $errorCode
 # -------------------------------------------------------------------------
 ##
proc error::verboseDisplay {errorMsg {display "alertnote always"}} {
    global errorCode
    
    # Quote the error messageÉ
    set msg "\"$errorMsg\""
    # Éand check if it identifies itself as an error. 
    # If not, prepend a label to identify it as such.
    if {![regexp -nocase {\merror(s)?\M} $msg]} {
	set msg "Error Message: $msg"
    } else {
	set msg "Message: $msg"
    }		
    
    switch {$errorCode} {
	"" -
	"NONE" -
	"0" {
	}
	default {
	    append msg "\rError Code: $errorCode"
	}
    } 
    error::terseDisplay $msg $display
}

## 
 # -------------------------------------------------------------------------
 # 
 # "error::pedanticDisplay" --
 # 
 #  Display $errorMsg in an error::window with as much context as possible,
 #  obtained from errorCode and errorInfo.
 # -------------------------------------------------------------------------
 ##
proc error::pedanticDisplay {errorMsg {display ""}} {
    # both errorMsg and display are ignored
    
    global errorInfo errorCode
    
    set msg $errorInfo
    
    # The execution stack is all mucked up with quotes and such.
	# Make it look like more normal Tcl.
    regsub -all -nocase "(while executing\[ \t\r\n\]*)\"" $msg {\1} msg
    regsub -all -nocase "\"(\n\[ \t\]*invoked from within)" $msg {\1} msg
    regsub -all -nocase "(invoked from within\[ \t\r\n\]*)\"" $msg {\1} msg	
    regsub -all -nocase "\"(\n\[ \t\]*\\\(procedure)" $msg {\1} msg
    regsub -all -nocase "\"(\n\[ \t\]*\\\(\"(eval|foreach|for|while)\")" $msg {\1} msg
    regsub {"$} $msg {} msg
    
    # Comment out the separator lines to make them more readable
    # with syntax coloring
    regsub -all -nocase "while executing" $msg {# \0} msg
    regsub -all -nocase "invoked from within" $msg {# \0} msg
    
    # Quote the first line of the error info, as it's the error message,
    # and if it doesn't explicitly say it's an error, label it as such.
    set msg [split $msg \n]
    set err "\"[lindex $msg 0]\""
    if {![regexp -nocase {\merror(s)?\M} $err]} {
	set err "Error Message: $err"
    } else {
	set err "Message: $err"		
    }
    set msg [lreplace $msg 0 0 $err "Error Code: $errorCode"]
    set msg [join $msg \n]
    
    error::window $msg
}

## 
 # -------------------------------------------------------------------------
 # 
 # "error::logDisplay" --
 # 
 #  Display error in the tcl shell if available or 
 #  in the startup log if initializing
 # -------------------------------------------------------------------------
 ##
proc error::logDisplay {errorMsg {display ""}} {
    # both errorMsg and display are ignored
    
    global errorInfo errorWhile errorScript
    
    if {$errorWhile != ""} {
	set msg "Error while $errorWhile. "
    } else {
	set msg "An error occurred. "
    }
    append msg "Error dump is in tcl shell if open."
    
    #     error::terseDisplay $msg "alertnote always"
    
    global alpha::guiNotReady
    if {![info exists alpha::guiNotReady]} {
	alpha::log stderr "======================="
	alpha::log stderr "try $errorWhile $errorScript error"
	alpha::log stderr $errorInfo
	alpha::log stderr "\r"
    } else {
	namespace eval alpha {}
	global alpha::errorLog
	append alpha::errorLog "=======================\r"
	append alpha::errorLog "try $errorWhile $errorScript error\r"
	append alpha::errorLog $errorInfo
	append alpha::errorLog "\r"
    }
}

# ×××× display utilities ×××× #

## 
 # -------------------------------------------------------------------------
 # 
 # "error::nudgeMessage" --
 # 
 #  Bump $errorMsg down and to the right for better display in a window.
 # -------------------------------------------------------------------------
 ##
proc error::nudgeMessage {errorMsg} {
    set lines [split $errorMsg "\r"]
    set errorMsg {"" ""}
    foreach line $lines {
	lappend errorMsg "\t$line"
    }
    join $errorMsg "\r"
}

## 
 # -------------------------------------------------------------------------
 # 
 # "error::window" --
 # 
 #  Display an error window, named by the current errorCode.
 #  The window is clean and read-only and is displayed in Tcl
 #  mode; the syntax coloring is particularly useful for 'pedantic' reports.
 # -------------------------------------------------------------------------
 ##
proc error::window {errorMsg} {
    global errorCode
    
    new -n "* ERROR * $errorCode *" -m Tcl -info "$errorMsg" -shrink
}

# ×××× general utilities ×××× #

## 
 # -------------------------------------------------------------------------
 # 
 # "error::rethrow" --
 # 
 #  Call with $errorMsg in the event you 'catch' an error you don't want.
 #  All this saves is having to declare 'global errorMsg errorInfo errorCode' 
 #  all over your code
 # 
 # Results:
 #  An error is thrown
 # 
 # --Version--Author------------------Changes-------------------------------
 #    1.0     <jguyer@his.com> original
 #    1.1     <jguyer@his.com> throws errorInfo too
 # -------------------------------------------------------------------------
 ##
proc error::rethrow {} {
    global errorMsg errorInfo errorCode 
    
    # ??? Can we clean up errorInfo to be more informative?
    
    error $errorMsg $errorInfo $errorCode
}

proc error::pushVars {} {
    uplevel {
	global errorCode errorInfo errorMsg
	global errorWhile errorScript
	
	# save globals in case this is a try within a try (some of the
	# reporting mechanisms result in try calls).
	
	set saveCode	$errorCode
	set saveInfo	$errorInfo
	set saveMsg		$errorMsg
	set saveWhile	$errorWhile
	set saveScript	$errorScript	
    }
}

proc error::popVars {} {
    uplevel {
	global errorCode errorInfo errorMsg
	global errorWhile errorScript
	
	# restore globals
	
	set errorCode	$saveCode
	set errorInfo	$saveInfo
	set errorMsg	$saveMsg	
	set errorWhile	$saveWhile
	set errorScript	$saveScript
    }
}
