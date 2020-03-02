## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl support packages
 # 
 # FILE: "tclShells.tcl"
 #                                          created: 04/05/1997 {09:31:10 pm}
 #                                      last update: 2005-08-07 13:30:05
 # Description:
 # 
 # Support for Tcl/Tk shell windows.
 # 
 # The current implementation of the AlphaTcl shell window resides in the
 # "shellMode.tcl" file.  It could be moved here if that made any sense.
 # 
 # Note that [Tcl::tclShellsMenuProc] uses [namespace eval Tcl $itemName] to
 # properly redirect the items from the "Tcl > Tcl-tk Shells" submenu.  This
 # means that we could have either of
 # 
 #     remoteTclShell
 #     Tcl::remoteTclShell
 # 
 # defined, or [Tcl::remoteTclShell] could call some other procedure in a
 # different namespace if desired.
 # 
 # By default, the shell procedures are in the global namespace because they
 # were copied directly from the earlier AlphaTcl packages found in the files
 # "EnhancedTkcon.tcl" and "RemoteTclShell.tcl".  (If this changes, then
 # please remove this paragraph.)
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta
 #         Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 # 
 # Includes contributions from Craig Barton Upright.
 # 
 # Copyright (c) 1997-2005 Vince Darley
 # All rights reserved.
 # 
 # ==========================================================================
 ##

proc tclShells.tcl {} {}

# Make sure that the "tclMode.tcl" file has been sourced.
tclMode.tcl

# ×××× Alpha shell routines ×××× #

namespace eval Tcl {
    variable shellNames [list "* Tcl Shell *" "* Tcl remote shell *"]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Tcl::isShellWindow" --
 # 
 # Determine if the given window (or the active one) is some Tcl shell.
 # 
 # --------------------------------------------------------------------------
 ##

proc Tcl::isShellWindow {args} {
    win::parseArgs win
    variable shellNames
    return [expr {[lsearch -exact $shellNames $win] > -1}]
}

# # Old shell starter:
# proc tclShell {} {
#     set w "* Tcl Shell *"
#     if {[win::Exists $w]} { bringToFront $w ; return }
#     Shel::start Alpha $w \
#       "Welcome to $::alpha::application's AlphaTcl shell.\r" Tcl
#     win::setInfo $w hookmodes [linsert [win::getInfo $w hookmodes] 0 Alpha]
# }

# Alternative shell starter, taking advantage of consoleAttributes
# ----------------------------------------------------------------
# By creating the histlist in advance we can give it as extra argument to
# [console::create] with the effect that it is now a remembered attribute
# of the console.
histlist create dummyhistlist 30
console::create "* Tcl Shell *"   -shelltype Alpha \
  -mode Tcl -minormode shell -hookmodes [list Alpha Shel Tcl] \
  -startuptext "Welcome to $::alpha::application's AlphaTcl shell.\r" \
  -shellhistory $dummyhistlist
histlist destroy dummyhistlist

proc tclShell {} {
    Shel::startPreexisting "* Tcl Shell *"
}


namespace eval Alpha {}

proc Alpha::DblClick {from to args} {
    if {[file exists [set f [getText $from $to]]]} {
	file::openAny $f
    } else {
	eval [list ::Tcl::DblClick $from $to] $args
    }
}

proc Alpha::evaluate {t} {
    set msg {}
    
    set args [Shel::expandAliases $t]
    switch -regexp -- $args {
	{^\s*alias(\s+.*)?} {
	    status::msg "alias to be added"
	    if {[llength $args] != 3} {
		set msg "Error: wrong number of arguments.\rForm\
		  is: alias <abbrev> <replacement>"
	    } else {
		set abbrev [lindex $args 1]
		if {[info commands $abbrev] != "" || [procs::find $abbrev] != ""} {
		    beep
		    if {![dialog::yesno -n Cancel "'$abbrev' is\
		      already a Tcl command, do you wish to proceed?"]} {
			set msg "No alias was formed"
		    }		
		}
		if {$msg eq ""} {
		    catch {Shel::alias $abbrev [lrange $args 2 2]} msg
		}
	    } 
	    
	}
	default {
	    global auto_noexec tcl_interactive errorCode errorInfo
	    set savedErrorCode $errorCode
	    set savedErrorInfo $errorInfo
	    # To allow 'unknown' to perform command expansion
	    set tcl_interactive 1
	    set code [catch {uplevel \#0 $args} msg]
	    set tcl_interactive 0
	    if {$code == 1} {
		# strip off end of error due to 'uplevel' command
		set new [split $errorInfo \n]
		set new [lrange $new 0 [expr [llength $new] - 4]]
		if {([lindex $new 1] == "    while executing") \
		  && ([lindex $new 2] == "\"$args\"") \
		  && ([string match "invalid command name \"*\"" \
		  [lindex $new 0]])} {
		    # We need tcl_interactive style code
		    if {![info exists auto_noexec]} {
			set name [lindex $args 0]
			set new [auto_execok $name]
			if {$new != ""} {
			    set errorCode $savedErrorCode
			    set errorInfo $savedErrorInfo
			    set redir ""
			    if {[string equal [info commands console] ""]} {
				set redir ">&@stdout <@stdin"
			    }
			    return [uplevel 0 exec $redir $new [lrange $args 1 end]]
			}
		    }
		}
		set errorInfo [join $new \n]
		set msg "Error: $msg"
	    }
	}
    }
    return $msg
}

proc Alpha::Prompt {} {
    global Shel::startPrompt Shel::endPrompt
    return "${Shel::startPrompt}[file tail [string trimright [pwd] {:}]]${Shel::endPrompt} "
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Remote Tcl Shell ×××× #
# 
# This procedure allows you to use Alpha as a console for a remote Wish
# shell.  Invoking a <<remoteTclShell>> will evaluate all commands in the new
# Wish interpreter and display the results in the shell window.
# 

namespace eval remotetcltk {}

proc remoteTclShell {} {
    
    tcltk::findTclshInterp
    set w "* Tcl remote shell *"
    Shel::start remotetcltk $w \
      "Welcome to $::alpha::application's remove Tcl shell.\r" Tcl
    win::setInfo $w hookmodes [linsert [win::getInfo $w hookmodes] 0 remotetcltk]
}

# Remote Tcl Shell support procedures.

proc remotetcltk::DblClick {from to args} {
    if {[file exists [set f [getText $from $to]]]} {
	file::openAny $f
    } else {
	eval [list Tcl::DblClick $from $to] $args
    }
}

proc remotetcltk::evaluate {cmd} {
    
    global tclshInterp
    
    eval $tclshInterp [list $cmd]
}

proc remotetcltk::Prompt {} {
    
    global Shel::startPrompt Shel::endPrompt tclshInterp
    
    if {[info exists tclshInterp]} {
	set name [lindex ${tclshInterp} 1]
    } else {
	set name "no-shell"
    }
    return "${Shel::startPrompt}${name}${Shel::endPrompt} "
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Tk Console Shell ×××× #
# 
# Called by the "Tcl Menu > Tcl-tk Shells > Tkcon Shell" menu item.  this
# procedure allows you to run the 'Tkcon' package as a console.
# 
# Note that Tkcon's 'edit' command is renamed to 'tkconedit', because
# otherwise it would conflict with Alphatk.
# 

proc tkconShell {} {
    
    # Make sure that we can run this.
    watchCursor
    if {[catch {package require Tk}]} {
	alertnote "Sorry, the Tkcon shell requires Tk."
	return
    }
    
    # We need to ensure that we have some variables set properly.
    ;namespace eval ::tkcon {

	variable OPT
	variable PRIV
	
	# we want to have only the main interpreter
	set OPT(exec) ""
	# we don't want tkcon to override gets or exit
	set OPT(gets) ""
	set OPT(overrideexit) 0
	set OPT(edit) tkconedit
	# use the specified window as root
	set PRIV(root) .tkcon
	# This one doesn't work because we're embedding.
	set PRIV(protocol) "tkcon hide"
    }

    if {[info commands tkcon] != ""} {
	if {![catch {tkcon show}]} {
	    return
	}
    }
    
    if {![llength [info commands ::tkcon::Init]]} {
	status::msg "Loading Tkcon..."
	global HOME embed_args
	# Do this so tkcon doesn't override unknown.
	set embed_args 1
	rename edit alphatk_edit
	uplevel \#0 [list source [file join $HOME Tools tkcon.tcl]]
	unset embed_args
	rename ::edit ::tkconedit
	rename ::alphatk_edit ::edit
	status::msg "Tkcon loaded"
    } else {
	::tkcon::Init
    }
    tkcon show
    wm protocol .tkcon WM_DELETE_WINDOW "tkcon hide"
}

# ===========================================================================
# 
# .