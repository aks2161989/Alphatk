if {[catch {
    # Startup of Alpha/Alphatk is split into three phases.  First
    # Alpha(tk)'s core sources Init/initialize.tcl.  Then it calls
    # the function alpha::PreGuiStartup and finally it calls
    # alpha::Startup.
    # 
    # The PreGuiStartup phase initialises the environment (PREFS folder,
    # early prefs), the auto_loading functionality, etc.  After this
    # phase returns Alpha will create the global status bar (using
    # location/theme/size information loaded from the early prefs).
    # 
    # The second phase results in the sourcing of this file, which
    # rebuilds package/tcl indices if needed and then continues with
    # loading of packages, menus, etc, and reads in all of the user's
    # ordinary preferences.  During the first phase we should avoid
    # interacting with the user, because the gui may not yet be properly
    # created.
    # 
    # Main startup phase:
    
    # Fix any broken core commands:
    if {[catch [list source [file join $HOME Tcl SystemCode coreFixes.tcl]] err]} {
	alertnote "There was a bad problem while sourcing coreFixes.tcl"
	error $err
    }

    # Rebuild the package and tcl indices, if necessary:
    source [file join $HOME Tcl SystemCode Init rebuildAlphaTcl.tcl]

    # Carry out primary startup: loading packages, etc.
    source [file join $HOME Tcl SystemCode runAlphaTcl.tcl]

} err]} {
    append alpha::errorLog "\r" $errorInfo
    set errCache $errorInfo
    if {![llength [info commands auto_load]] \
      || (![auto_load dialog::yesno] || ![auto_load dialog::alert])} {
	# This error happened either too early on in a weird way,
	# so that even the auto-loading mechanism doesn't work
	# (and has overwritten the original problem)
	# We just use the cached information.
	set errorInfo $errCache
	alertnote "That was a core startup error.  Alpha will probably\
	  not function correctly.  Press OK to view the error.  Also note\
	  that auto-loading seems not to be functioning."
	alertnote $errorInfo
    } else {
	if {[dialog::yesno -y "View the error" -n "Continue" \
	  "That was a core startup error.  Alpha will probably\
	  not function correctly."]} {
	    dialog::alert $errCache
	}
    }
}
unset -nocomplain err
if {[info exists alpha::errorLog]} {
    catch {
	new -n "* Alpha startup error log *" -info ${alpha::errorLog}
	unset alpha::errorLog
    }
}
# Sort out the menu enabled state.
alpha::performInitialMenuDimming
    
status::msg "Initialization Complete"
