if {[catch {
    # Declare package to initialize very early, _if_ the user has
    # turned them on.  Note that these are only turned on if they
    # are also in the global::features list, so it's ok to add things
    # like aeom that may not exist on some platforms.
    lappend alpha::earlyPackages Alpha smarterSource internationalMenus aeom

    # Set up list of packages which are always activated.
    set alpha::packagesAlwaysOn [list Alpha AlphaTcl isoTime\
      filesets openWindowsMenu spellcheck colorPrefs xserv calculator\
      elecCompletions elecExpansions supersearch incrementalSearch \
      internationalMenus versionControl specialCharacters recentFiles]
    if {$alpha::macos} {
	lappend alpha::packagesAlwaysOn aeom ODBEditor speech
    }
    if {$tcl_platform(platform) ne "macintosh"} {
	lappend alpha::packagesAlwaysOn alphaServer
    }
    if {[lindex [file system $HOME] 0] eq "tclvfs"} {
	# If we are running from a starpack or starkit
	lappend alpha::packagesAlwaysOn vfsFileset
    }
    lappend alpha::packagesAlwaysOn contextualMenu
    # Make sure these are in the global features list
    foreach pkg $alpha::packagesAlwaysOn {
	if {[lsearch -exact $global::features $pkg] == -1} {
	    set global::features [linsert $global::features 0 $pkg]
	}
    }
    # Now turn on any packages which are 'early' and 'active'.
    alpha::recordTimingData "Activating early + active packages ..."
    foreach pkg $alpha::earlyPackages {
	if {[lsearch -exact $global::features $pkg] != -1} {
	    alpha::recordTimingData "Activating package '${pkg}' ..."
	    alpha::package require $pkg
	    alpha::recordTimingData "Activating package '${pkg}' ... finished"
	}
    }
    unset -nocomplain pkg
    alpha::recordTimingData "Activating early + active packages ... finished"
} err]} {
    set initAlphaTclErr 1
    if {[askyesno "There was a bad error starting up; your package\
      indices seem to have been corrupted.  Would you like to rebuild them\
      and try again?\r\r(Error: $err)"]} {
	# try again.
	source [file join $HOME Tcl SystemCode Init rebuildAlphaTcl.tcl]
	source [file join $HOME Tcl SystemCode runAlphaTcl.tcl]
	return
    }
    alertnote "Please quit and restart Alpha as soon as possible.  This may\
      resolve the problem."
}
unset err

# Delete all old temporary files
temp::cleanupAll

alpha::recordTimingData "Getting definitions ..."
alpha::getDefinitions
alpha::recordTimingData "Getting definitions ... finished"

# couple of random things

if {${alpha::platform} == "alpha"} {
    # Add to chars considered part of words.  In Alphatk,
    # Tcl is unicode aware and understands all of this stuff
    # already.
    addAlphaChars {_ÄÅÇÉÑÖÜáàâäãåçéèêëíìîïñóòôöõúùûüÅØæøæß}
}

if {[info exists firsttime]} {
    unset firsttime
    lappend global::features filesetMenu
    if {!$skipPrefs} {
	# For the moment we will force the user to go
	# through this with every new release (see below)
	# setupAssistant
    }
}
if {!$skipPrefs} {
    # Read both scalar and array definitions from preferences folder.
    alpha::recordTimingData "Reading preferences ..."
    prefs::readAll
    alpha::recordTimingData "Reading preferences ... finished"
    if {[key::optionPressed]} {
    }
}
win::SetProportions
# define v. important keyboard variables
keys::keyboardChanged
alpha::recordTimingData "Building basic menus ..."
status::msg "Building basic menus…"
menu::buildBasic
alpha::recordTimingData "Building basic menus ... finished"

alpha::recordTimingData "Binding keys ..."
status::msg "Binding keys…"
alpha::basicKeyBindings
alpha::keyBindings
alpha::useElectricTemplates
alpha::recordTimingData "Binding keys ... finished"

# Read in all packages, modes and menus.
alpha::recordTimingData "Reading in packages ..."
status::msg "Reading in packages…"
alpha::findAllPlugins
alpha::recordTimingData "Reading in packages ... finished"
# call anything that's attached to my keyboard.
hook::callAll keyboard $keyboard

# If we do anything else to a menu, it must now be rebuilt, or
# if we want to edit a window, we can now do that.  This line
# must be closely followed by the startupHook call.
unset alpha::guiNotReady

# Build all menus completely.
status::msg "Building complete menus…"
alpha::recordTimingData "Building, inserting complete menus ..."
alpha::buildAndInsertMenus
alpha::recordTimingData "Building, inserting complete menus ... finished"
status::msg "Building complete menus… finished"

# Bind special keys
alpha::recordTimingData "Binding special keys ..."
bind::fromArray keys::specialBindings keys::specialProcs
alpha::recordTimingData "Binding special keys ... finished"

# Alerts and readme's for the user:
if {!$skipPrefs} {
    # read preferences file
    if {[catch {prefs::tclRead} err]} {
	append alpha::errorLog "\r" $err
	unset err
    }
}

status::msg "Startup complete"

# Call all startup hooks
alpha::recordTimingData "Calling startup hooks ..."
hook::callAll startupHook *
alpha::recordTimingData "Calling startup hooks ... finished"

if {!$skipPrefs} {
    if {![info exists readReadme] \
      || ([lindex $readReadme 0] != [alpha::package versions Alpha]) \
      || ([lindex $readReadme 1] != [alpha::package versions AlphaTcl]) \
    } {
	# This may be removed later (see above)
	if {![info exists readReadme]} {set readReadme ""}
	setupAssistant $readReadme [list [alpha::package versions Alpha] \
	  [alpha::package versions AlphaTcl]]
	prefs::add readReadme [list [alpha::package versions Alpha] \
	  [alpha::package versions AlphaTcl]]
	if {[llength [set files [glob -nocomplain -path \
	  [file join $HOME Help Readme] *]]]} {
	    # Reverse order, and remove any backups which may be around
	    set files [lreverse [lremove -regexp -all $files [list ".*~.*"]]]
	    foreach f $files {
		# Don't show Alphatk readme in Alpha.
		if {${alpha::platform} != "tk"} {
		    if {[regexp "Alphatk\$" [file tail $f]]} {
			continue
		    }
		}
		catch {helpMenu [file tail $f]}
	    }
	    unset -nocomplain f files
	} else {
	    alertnote "Alpha's \"Readme\" file should be in\
	      '[file join $HOME Help]', but isn't.  You may wish\
	      to reinstall Alpha."
	}
    }
    if {[info exists readReadme]} {
	unset readReadme
    }
    
    if {[info exists alpha::readAtStartup]} {
	foreach f ${alpha::readAtStartup} {
	    catch {edit -c -r $f}
	}
	unset alpha::readAtStartup
	prefs::modified alpha::readAtStartup
    }
}

