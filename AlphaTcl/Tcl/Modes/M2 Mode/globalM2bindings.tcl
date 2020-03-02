# --------------------------------------------------------------------------------
# ×××× M2 Global KEY BINDINGS ×××× #
# --------------------------------------------------------------------------------
# This feature goes together with the M2 mode.  It allows end users of Alpha
# to control the behavior of the global bindings needed in the M2 mode.  The
# user may anytime activate or deactivate the global bindings of the mode
# (Ctrl^0, Ctrl^1, Ctrl^2) by activating or deactivating this
# menu command "Global Setup -> Preferences -> Features..."  under Usual
# Features (menu command "Config -> Global Setup -> Features..." section
# "Usual Features").
# 
# This feature requires that the M2 mode >= v3.8.2 is currently installed in Alpha.
#####################################################################################
# 
#   Author    Date        Modification
#   ------    ----        ------------
#   af        24.09.04    V 1.1.1 - M2 mode v4.0.2
#                         - Renaming pref globalOpenBindings to globalM2Bindings
#   af        20.02.05    M2 mode v4.1.1
#                         - Updating URLs


alpha::feature globalM2Bindings 1.1.1 "global-only" {
    #no global init script
} {
    #####activation script####
    if {[info exists M2modeVars(globalM2Bindings)]} {
	# feature was previously activated and M2 mode is in cooperative state
	if {!$M2modeVars(globalM2Bindings)} {
	    set M2modeVars(globalM2Bindings) "1"
	    prefs::modified M2modeVars(globalM2Bindings)
	}
	M2::setGlobalBindings
    } else {
	# feature is activated the very first time and M2 mode needs to be made cooperative
	set neededM2Mode 3.8.2
	if {![alpha::package exists M2] | ( [alpha::package versions M2] < ${neededM2Mode} ) } {
	    # M2 mode can't cooperate
	    set msg "Feature globalM2Bindings needs M2 mode >= v${neededM2Mode}. "
	    set msg "${msg} It appears this M2 mode is currently not installed."
	    set msg "${msg} Please reinstall it first before trying to activate this feature again."
	    alertnote "$msg"
	} else {
	    # Put M2 mode into cooperative state 
	    set M2firstInitForBindings 1
	    prefs::modified M2firstInitForBindings
	    set M2modeVars(globalM2Bindings) "1"
	    prefs::modified M2modeVars(globalM2Bindings)
	    # Use M2 mode to activate bindings 
	    M2::setGlobalBindings
	}
    }
} {
    ####deactivation script####
    if {[info exists M2modeVars(globalM2Bindings)]} {
	# feature was previously activated and M2 mode is in cooperative state
	if {$M2modeVars(globalM2Bindings)} {
	    set M2modeVars(globalM2Bindings) "0"
	    prefs::modified M2modeVars(globalM2Bindings)
	}
	M2::unsetGlobalBindings 
    } else {
	# M2 mode is not in cooperative state, force deactivation
	unBind '0'  <z> M2::openWorkFiles
	unBind '1'  <z> launchShellAndSimulate
	unBind '2'  <z> launchShell
    }
} maintainer { 
    "Andreas Fischlin" <andreas.fischlin@env.ethz.ch> <http://www.ito.ethz.ch/SysEcol> 
} uninstall {
    # deactivate
    if {[info exists M2modeVars(globalM2Bindings)] && $M2modeVars(globalM2Bindings)} {
	set M2modeVars(globalM2Bindings) "0"
    }
    if {[alpha::package exists M2]} {
	M2::unsetGlobalBindings 
    }
    # uninstall
    if {[info exists M2modeVars(globalM2Bindings)]} {
        # does not function in Alpha 7.6 (bug?)
	catch { prefs::removeObsolete M2modeVars(globalM2Bindings) }
    }
    if {[info exists M2modeVars(globalM2Bindings)]} {
        unset M2modeVars(globalM2Bindings)
    }
    if {[info exists M2firstInitForBindings]} {
	catch { prefs::removeObsolete M2firstInitForBindings }
    }
    if {[info exists M2firstInitForBindings]} {
        unset M2firstInitForBindings
    }
    set pfn [file join $HOME Tcl Modes "M2 Mode" "globalM2Bindings.tcl"]
    catch {file delete -force ${pfn}}
    if {[file exists ${pfn}]} {
	alertnote "globalM2Bindings uninstall: ${pfn} could not be removed (unexpected error)."
    } else {
	set msg "Success globalM2Bindings uninstall: globalM2Bindings.tcl removed."
	status::msg "[set msg]"
    }
} description {
Ê Ê ÊCreates global keyboard shortcuts (Control-0, Control-1, Control-2) which
Ê Ê Êopen work files in the Modula-2 (M2) mode
} help {
    This package makes the three Modula-2 (M2 mode) bindings Ctrl-0, Ctrl-1,
    and Ctrl-2 globally available.  These are basic M2 bindings and need to be
    active at all times for opening work files containing compiler errors and
    launching of Modula-2 shells --- but if you don't use Modula-2 you have no
    need for this package either...
}

proc globalM2Bindings.tcl {} {}
