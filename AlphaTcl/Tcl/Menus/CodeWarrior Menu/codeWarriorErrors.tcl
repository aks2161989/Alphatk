# -*-Tcl-*- (nowrap)
# 
# File: codeWarriorErrors.tcl
# 							Last modification: 2004-11-05 19:13:51
# 
# Description : this file is part of the CodeWarrior Menu for Alpha.
# It contains the procedures related to error handling.

namespace eval cw {}


# -----------------------------------------------------------------
# Error handling
# -----------------------------------------------------------------
# The error reply from CodeWarrior looks like this
# [ErrM{ErrT:ErCW, ErrS:“function declaration hides inherited virtual function”, file:fss («FFFB000014371443536D617274537464506F7075704D656E752E6800000000000000000000000000000000000000000000000000000000000000000000000000000000000000»), ErrL:64}, ...]
#
#   ErrT is the error type parameter (enum : ErCE ErCW ErDf ErFn ErGn ErIn ErLE ErLW)
# 	Eg	ErCW indicates a warning
# 		ErCE indicates a compile error
# Improvements by jdunning@cs.Princeton.EDU (John Dunning)
# Completely rewritten with new TclAE syntax (Bernard Desgraupes bdesgraupes@easyconnect.fr)
	
proc cw::errors {resDesc} {	
	global tileLeft tileTop tileWidth errorHeight cw_params cw_error
	
	# First look for an 'errn' parameter
	if {[cw::checkErrorInReply $resDesc]} {return}	
	
	# Now look for a list of 'ErrM' descriptors in the direct obj parameter
	set text ""
	set errors 0
	set warnings 0
	set messages 0
	set generics 0
	set link 0
	if {[catch {tclAE::getKeyDesc $resDesc ----} theobj]} {
		return
	} 
	set count [tclAE::countItems $theobj]
	
	if {$count==0} {
		status::msg "No errors"
		return
	} 
	
	for {set i 0} {$i < $count} {incr i} {
		set subobj [tclAE::getNthDesc $theobj $i]
		
		if {[regexp "^ErrM" $subobj]} {
			set errType [tclAE::getKeyData $subobj ErrT]
			set errString [tclAE::getKeyData $subobj ErrS]
			set errLine [tclAE::getKeyData $subobj ErrL]
			set errFile [tclAE::getKeyData $subobj file TEXT]
			
			switch $errType {
				"ErCE" - "ErLE" {
					# mark actual errors with a bullet
					append text " • "
					incr errors
				}
				"ErCW" - "ErLW" {
					# mark warnings with a delta
					append text " ∆ "
					incr warnings
				}
				"ErGn" {
					# mark generic errors with a bullet
					append text " > "
					incr generics
				}
				"ErIn" {
					# mark information with a bullet
					append text " * "
					incr messages
				}
			}
			switch $errType {
				"ErCE" - "ErCW" {
					append text "\"[file tail $errFile]\"\t; Line $errLine: $errString\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t∞$errFile\r"
				}
				"ErLE" - "ErLW" - "ErGn" - "ErIn" {
					set link 1
					append text "$errString\r"
				}
			}
		} 
	}
	
	if {$errors == 0 && $warnings == 0 && $messages == 0 && $generics == 0} {
		hook::register resumeHook cw::killCompilerErrors
		return
	}
	
	new -n $cw_params(errWinTitle) -g $tileLeft $tileTop $tileWidth $errorHeight -m Brws
	if {$link} {
		insertText -w  $cw_params(errWinTitle) "(Link: $errors errors, $warnings warnings, $messages messages)\r-----\r$text"
	} else {
		insertText -w  $cw_params(errWinTitle) "($errors errors, $warnings warnings, $messages messages: use up/down arrows to browse, <cr> to jump to corresponding line)\r-----\r$text"
	}
	
	goto [minPos]
	winReadOnly
# 	browse::Down
}


proc cw::killErrors {} {
    global cw_params
    set wins [winNames]
    if {[set res [lsearch $wins $cw_params(errWinTitle)]] >= 0} {
	set name [lindex $wins $res]
	bringToFront $name
	killWindow
    }
}


proc cw::killCompilerErrors {args} {
    global cw_params
    set wins [winNames -f]
    if {[set res [lsearch $wins $cw_params(errWinTitle)]] >= 0} {
	bringToFront [lindex $wins $res]
	killWindow
    }
    # This is a one-off hook; we remove it immediately.
    hook::deregister resumeHook cw::killCompilerErrors
}


proc cw::nextError {} {
    global cw_params
    nextMatch $cw_params(errWinTitle)
}


proc cw::prevError {} {
    global cw_params
    prevMatch $cw_params(errWinTitle)
}


# Check for errors returned in the AppleEvent reply
proc cw::checkErrorInReply {resDesc {showIt 1}} {
	global cw_error
	set test [expr ![catch {tclAE::getKeyData $resDesc errn} errnum]]
	if {$test} {
		if {$errnum > 0 && $errnum < 9} {
			set msg "CW error: [set cw_error($errnum)]"
		} else {
			set msg "CW error status $errnum"
		}
		# Look for an error string
		if {[catch {tclAE::getKeyData $resDesc errs TEXT} errstring]} {
			set errstring ""
		} 
		if {$showIt} {
			alertnote $msg $errstring
		} 
		
	} else {
		set test [expr ![catch {tclAE::getKeyData $resDesc errs TEXT} errstring]]
		if {$test && $showIt} {
			alertnote $errstring
		}
	}
	return $test
}

