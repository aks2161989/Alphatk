# (PreGui)
# 
# 
# Critical commands at this stage:
# 
#   askyesno, alert or alertnote, get_directory (only in rare circumstances)
#   quit, version, processes (Alpha only)
# 
# Critical variables at this stage:
# 
#   HOME, PREFS, alpha::application, alpha::platform, skipPrefs



# If we have already sourced this file, then this variable will exist
if {[info exists global::features]} {
    return
}

# First basic initialisation: (works with Alpha 8.0 development)
namespace eval alpha {}

if {[llength [info commands alert]] && ![llength [info procs alertnote]]} {
    if {([llength [info commands alertnote]] > 0)} {
	rename alertnote __alertnote
    }
    ;proc alertnote {args} {
	alert -t stop -c "" -o "" -- [lindex $args 0] [join [lrange $args 1 end] " "]
	return
    }
}

# 'exit' kills Alpha without allowing it to save etc.
# 'quit' handles a smooth shutdown for us.  
# 
# It's not clear we want to do this quite so early in the startup
# sequence (since if we 'quit' very early, we don't want Alpha to call
# quitHook and attempt to save prefs we haven't yet loaded).  
# ...to be resolved
if {[llength [info commands exit]]} {
    rename exit ""
    proc exit {{returnCode ""}} {quit}
}

# Read Alpha's version information
alpha::recordTimingData "Obtaining version information"
if {[catch [list source [file join $HOME Tcl SystemCode Init alphaVersionInfo.tcl]] err]} {
    alertnote "There was a bad problem while sourcing alphaVersionInfo.tcl"
    error $err
}

# PREFS points to a folder 'Alpha', we add the major version number
set PREFS "[string trimright $PREFS [file separator]]-v[lindex [split $alpha::version .] 0]"

# ===========================================================================
# 
# ×××× Support Folders ×××× #
# 
# Define the variables containing the location of the Support folders if the
# core has not already done so.  By the end of this we will have created both
# of the "local" and "user" directories if necessary and if we have the
# proper permissions to do so.  Both SUPPORT(local) and SUPPORT(user) will
# always exist as variables, but AlphaTcl code will need to always check to
# see if the directories they refer to actually exist.  This should only
# require a simple
# 
#   if {($SUPPORT(<domain>) ne "")} {...}
# 
# check; if the variable is populated, then it should exist.
# 

alpha::recordTimingData "Creating Support Folders"

# First try the core's [getStandardFolder] command if it exists.
if {![info exists SUPPORT] && [llength [info commands getStandardFolder]]} {
    foreach domain [list "local" "user"] {
	if {[catch {getStandardFolder "asup" $domain} SUPPORT($domain)]} {
            unset SUPPORT($domain)
        }
    } 
}
# If "SUPPORT(local)" still doesn't exist, use a "hard-wired" location.
if {![info exists SUPPORT(local)]} {
    set SUPPORT(local) ""
    if {($alpha::macos == 2)} {
	if {($alpha::platform eq "tk")} {
	    set SUPPORT(local) "/Library/Application Support/Alphatk"
	} else {
	    set SUPPORT(local) "/Library/Application Support/AlphaX"
	}
    } elseif {($tcl_platform(platform) eq "windows")} {
	catch {set SUPPORT(local) [file join $env(ALLUSERSPROFILE) "Application Data" Alphatk]}
    }
} 
# If "SUPPORT(user)" still doesn't exist, use a "hard-wired" location.
if {![info exists SUPPORT(user)]} {
    set SUPPORT(user) ""
    if {($alpha::macos == 2)} {
	if {$alpha::platform eq "tk"} {
	    set SUPPORT(user) [file normalize "~/Library/Application Support/Alphatk"]
	} else {
	    set SUPPORT(user) [file normalize "~/Library/Application Support/AlphaX"]
	}
    } elseif {($tcl_platform(platform) eq "windows")} {
	catch {set SUPPORT(user) [file join $env(APPDATA) Alphatk]}
    } else {
	set SUPPORT(user) [file normalize "~/.Alphatk/ApplicationSupport"]
    }
} 
# Now we attempt to create a hierarchy of folders within each SUPPORT domain.
foreach domain [list "local" "user"] {
    if {([set supportDir $SUPPORT($domain)] eq "")} {
	# We were not able to define a SUPPORT folder location.
        continue
    } elseif {![file isdir $supportDir] && [catch {file mkdir $supportDir}]} {
	# Our last attempt to create the SUPPORT folder failed.
	set SUPPORT($domain) ""
	continue
    } elseif {![file writable $supportDir]} {
	# The SUPPORT folder exists, but we don't have write privileges.
	continue
    }
    foreach tclDir [list SystemCode Modes Menus Completions Packages] {
	if {![file isdir [file join $supportDir AlphaTcl Tcl $tclDir]]} {
	    catch {file mkdir [file join $supportDir AlphaTcl Tcl $tclDir]}
	} 
    }
    foreach extraDir [list Help Examples] {
	if {![file isdir [file join $supportDir AlphaTcl $extraDir]]} {
	    catch {file mkdir [file join $supportDir AlphaTcl $extraDir]}
	} 
    }
} 
unset -nocomplain domain supportDir tclDir extraDir

# 
# End of Support Folders creation.
# 
# ===========================================================================

if {[info commands alpha::showStartupVersions] != ""} {
    # Alpha(tk) core command to show the alphatcl version info in the
    # splash screen.
    alpha::showStartupVersions
}
if {![info exists alpha::modifier_keys]} {
    set alpha::modifier_keys [list "Command" "cmd" "Option" "opt"]
}

# This flag will be cleared once our gui has been constructed. Currently
# this means both that the standard menus have been created, and that
# we are ready to create windows (e.g. 'new ...' will work).
set alpha::guiNotReady 1
set alpha::changingMode 0
if {("\u0192" ne "Ä") || ("\u2026" ne "É") } {
    if {![file exists [file join [info library] encoding]]} {
	set msg "Your 'encoding' directory inside Tcl's library\
	  '[info library]' doesn't seem to exist.  This will\
	  probably cause serious problems."
    } else {
	set msg "Unknown encoding problem.  Make sure you\
	  have installed Tcl properly, and that the AlphaTcl library\
	  (part of Alpha) \
	  has not had its encoding automatically converted when it \
	  was decompressed.  This will\
	  probably cause serious problems."
    }
    if {[askyesno "$msg   Do you want to quit?"]} {
	quit
    }
    unset msg
}

# Check if the user over-rides the preferences directory.
# This can either be in HOME or the directory where the
# executable lies (which may be the same thing).
set __prefs [list $HOME [file dirname [info nameof]]] 

foreach dir $__prefs {
    if {[file exists [file join $dir AlphaPrefs]] \
      && [file isdirectory [file join $dir AlphaPrefs]]} {
	foreach PREFS [glob -types d -dir $dir *] {
	    if {[string tolower [file join $dir alphaprefs]] eq
	    [string tolower $PREFS]} {
		break
	    }
	}
    }
}
unset dir __prefs

if {($alpha::platform eq "alpha") && ([lindex [split $alpha::version .] 0] eq "8")} {
    if {($tcl_platform(platform) eq "macintosh")} {
	# Using classic Alpha 8.
	set alpha::majorUpgradePrefsCompatible 1
    }
}

if {![file exists $PREFS]} { 
    if {[catch {file mkdir $PREFS}]} {
	alertnote "$alpha::application cannot locate or create your preferences\
	  directory '$PREFS'.  From now on it will try to use \
	  '[file join $HOME AlphaPrefs]' instead."
	set PREFS [file join $HOME AlphaPrefs]
	if {![file exists $PREFS]} { 
	    if {[catch {file mkdir $PREFS}]} {
		alertnote "Sorry, the preferences directory\r\r'$PREFS'\
		  \r\rcould not be created.  $alpha::application\
		  requires a preferences directory to run.  Please fix\
		  this problem and then try to rerun $alpha::application.\
		  Goodbye."
		quit
	    }
	}
    }
    # We have to be careful here; Alpha has hardly started up so we can't
    # yet access most of AlphaTcl.
    set major_version [lindex [split $alpha::version .] 0]
    if {[file tail $PREFS] eq "Alpha-v$major_version"} {
	# We just created a new folder for a major version of Alpha
	set prev_prefs [file join [file dirname $PREFS] "Alpha-v[expr {$major_version -1}]"]
	if {[file exists $prev_prefs]} {
	    # And it was an upgrade, since the old prefs folder exists.
	    # If the old version is compatible, copy it over
	    if {[info exists alpha::majorUpgradePrefsCompatible]} {
		if {[askyesno "You just upgraded to a new major version\
		  $alpha::version from [expr {$major_version -1}].x.\
		  Would you like to copy over your preferences? (They\
		  should be compatible.)"]} {
		    # Copy contents of prev prefs to new $PREFS
		    if {[catch {
			eval file copy [glob -dir $prev_prefs *] [list $PREFS]}]
		    } {
			alertnote "There was an error copying your\
			  preferences; this may cause problems"
		    }
		}
	    } else {
		alertnote "You just upgraded to a new major version\
		  $alpha::version from [expr {$major_version -1}].x.\
		  The preferences are largely incompatible between these\
		  two versions, so you'll have to re-enter them."
	    }
	    # Then ask if we should delete the old one
	    if {[askyesno "Do you want to delete your old preferences?"]} {
		if {[catch {file delete -force $prev_prefs}]} {
		    alertnote "There was an error deleting your old\
		      preferences; you might want to delete '$prev_prefs'\
		      manually."
		}
	    }
	}
	unset prev_prefs
    }
    unset major_version
}

# source v.  important code -- amongst other critical stuff, this
# declares the encodings of our system and our PREFS, so we must have the
# PREFS directory sorted out before we source it.
alpha::recordTimingData "Sourcing critical core code..."
if {[catch [list source [file join $HOME Tcl SystemCode Init pathManagement.tcl]] err]} {
    alertnote "There was a bad problem while sourcing pathManagement.tcl"
    error $err
}
if {[catch [list source [file join $HOME Tcl SystemCode Init coreImplementations.tcl]] err]} {
    alertnote "There was a bad problem while sourcing coreImplementations.tcl"
    error $err
}
# Get the Tcl auto-load environment setup correctly
if {[catch [list source [file join $HOME Tcl SystemCode Init tclAutoload.tcl]] err]} {
    alertnote "There was a bad problem while sourcing tclAutoload.tcl"
    error $err
}
alpha::recordTimingData "Sourcing critical core code... finished"


alpha::recordTimingData "Making auto_path ..."
if {[catch [list alpha::makeAutoPath $skipPrefs] err]} {
    alertnote "There was a bad problem while making the autopath"
    error $err
}
alpha::recordTimingData "Making auto_path ... finished"


# IMPORTANT: it is vital we get to this point in the startup sequence
# without any errors.  From this point on if we hit any errors, we
# should be able to handle them reasonably gracefully, although
# even then we might force/ask the user to quit.  However errors prior
# to this point probably can't even be dealt with in a useful way,
# basically because we only load the 'unknown' procedure just above.

alpha::ensureHomeOk
if {[catch [list source [file join $HOME Tcl SystemCode Init cache.tcl]] err]} {
    alertnote "There was a bad problem while sourcing cache.tcl"
    error $err
}
if {[catch [list source [file join $HOME Tcl SystemCode Init prefsHandling.tcl]] err]} {
    alertnote "There was a bad problem while sourcing prefsHandling.tcl"
    error $err
}
alpha::checkForPreBuiltCache

# Create the index namespace for all of our package/pref information.
namespace eval index {}
# get known packages
catch {namespace eval index {cache::readContents index::feature}}
catch {namespace eval index {cache::readContents index::requirements}}
# get list of packages of flag type
catch {namespace eval index {cache::readContents index::flags}}
# get list of preferences help of flag type
catch {namespace eval index {cache::readContents index::prefshelp}}

# Declare any early pre-gui preferences -- just those preferences which
# are necessary now, so that Alpha's core can construct the basic
# gui elements before continuing with the rest of the startup 
# sequence.

# At present, the Alpha8/X core can't handle this so early. (version 8.0b17d1)
# (See bug# 1642 : The menus in the status bar are now on the left)
if {(${alpha::platform} ne "alpha")} {
    newPref earlylinkvar locationOfStatusBar \
      [expr {$tcl_platform(platform) ne "macintosh"}] \
      global "win::statusBarLocationChanged ; #" \
      [list "Status Bar At Bottom Of Screen" "Status Bar Under Menus"] index
}

# load any early preferences (e.g. list of active packages)
# from special cache
namespace eval global {}

if {!$skipPrefs} {
    catch {prefs::loadEarlyConfiguration}
    unset -nocomplain mode::defaultfeatures
}
if {![info exists global::features]} {
    set global::features ""
    set firsttime 1
}

