## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "modes.tcl"
 #                                          created: 01/08/1994 {11:17:30 PM}
 #                                      last update: 02/25/2006 {10:19:31 AM}
 # Description:
 #  
 # Supports various 'mode' operations.
 # 
 # This file is distributed under a Tcl style license.
 #  
 # ==========================================================================
 ##

proc modes.tcl {} {}

namespace eval alpha {}
namespace eval mode  { 
    variable modeList
    if {![info exists modeList]} {
        set modeList [list]
    }
}

if {[array exists filepats]} {
    prefs::renameOld filepats mode::Filepats
}

# Implement (mode,minormode) by adding any minormode information.
# This block of code is not currently stable (April 2004),
# and will change.
proc alpha::_applyMinorMode {current minormode} {
    if {![info exists ::index::minormode($minormode)]} {
	alpha::log stderr "Unknown minormode '$minormode' associated with window"
	return $current
    }
    foreach {add aspect tag} $::index::minormode($minormode) {
	switch -- $add {
	    0 {
		dict set current $aspect [list $tag]
	    }
	    1 {
		if {[dict exists $current $aspect]} {
		    if {$aspect eq "colortags"} {
			dict lappend current $aspect $tag
		    } else {
			dict set current $aspect \
			  [linsert [dict get $current $aspect] 0 $tag]
		    }
		} else {
		    dict set current $aspect [list $tag]
		}
	    }
	    -1 {
		if {[dict exists $current $aspect]} {
		    set idx [lsearch -exact [dict get $current $aspect] $tag]
		    if {$idx != -1} {
			dict set current $aspect \
			  [lreplace [dict get $current $aspect] $idx $idx]
		    }
		}
	    }
	}
    }
    return $current
}

## 
 # -------------------------------------------------------------------------
 # 
 # "addMode" -- you probably won't call this proc yourself
 # 
 # -------------------------------------------------------------------------
 ##
proc addMode {names oneTime suffs _features} {
    global mode::features mode::OneTimeScript index::feature \
      mode::interfaceNames mode::modeList mode::Filepats
    
    # Determine the User Interface name for this mode.
    set m [lindex $names 0]
    if {([llength $names] > 1)} {
	set mode::interfaceNames($m) [lindex $names 1]
    }
    # Store the remaining information.
    ;namespace eval ::$m {}
    if {$oneTime ne ""} {set mode::OneTimeScript($m) $oneTime}
    ensureset mode::features($m) $_features
    foreach f $_features {
	if {[string index $f 0] ne "-"} {
	    package::addRelevantMode $f $m
	}
    }
    ensureset mode::Filepats($m) $suffs
    # Keep a list of all modes.  We cannot use the mode::filepats or
    # mode::features array entries, because when a mode is removed,
    # old preferences for those variables might still survive.
    if {[lsearch -exact $mode::modeList $m] == -1} {
	lappend mode::modeList $m
    }
}

# This procedure must never throw an error.  If it does, changeMode
# will put AlphaTcl into a problematic state.
proc loadAMode {mode} {
    global mode::OneTimeScript
    # These lines must load the mode vars into the mode var scope.
    if {[info exists mode::OneTimeScript($mode)]} {
	set Mode [mode::getName $mode 1]
	status::msg "loading mode $Mode …"
	if {[catch {uplevel \#0 $mode::OneTimeScript($mode)} err]} {
	    set maintainer \
	      [string trim [lindex [alpha::package maintainer $mode] 1]]
	    if {[string length $maintainer]} {
		alertnote "There was a BAD problem loading '$Mode' mode: $err.\
		  Please contact that mode's maintainer ($maintainer),\
		  for a fix."
	    } else {
		alertnote "There was a BAD problem loading '$Mode' mode: $err.\
		  Please contact the alphatcl-developer mailing list\
		  for a fix."
	    }
	}
	unset mode::OneTimeScript($mode)
    }
}

proc mode::getName {name {userInterfaceName "0"}} {
    
    variable interfaceNames
    
    if {!$userInterfaceName} {
	# Translate a display name to the internal representation.
	foreach modeName [array names interfaceNames] {
	    if {($interfaceNames($modeName) eq $name)} {
		set name $modeName
		break
	    }
	}
    } elseif {[info exists interfaceNames($name)]} {
	set name $interfaceNames($name)
    }
    return $name
}

proc mode::findForWindow {window} {
    set name [file tail [win::StripCount $window]]
    regsub {( copy|~\d*|.orig|.in)+$} $name "" name
    variable Filepats
    # First look for a case sensitive match:
    foreach mode [array names Filepats] {
	foreach pat $Filepats($mode) {
	    if { [string match $pat $name] } {
		return $mode
	    }
	}
    }
    # Then try to ignore case:
    foreach mode [array names Filepats] {
	foreach pat $Filepats($mode) {
	    if { [string match [string tolower $pat] [string tolower $name]] } {
		return $mode
	    }
	}
    }
    # If no match, then just:
    return "Text"    
}


# Supported method to get or set the list of file patterns for a 
# given mode.
proc mode::filePatterns {m {pat ""}} {
    variable Filepats
    if {[llength [info level 0]] == 2} {
	if {[info exists Filepats($m)]} {
	    return $Filepats($m)
	} else {
	    return {}
	}
    } else {
	set Filepats($m) $pat
	prefs::modified Filepats($m)
	return $pat
    }
}

proc addMenu {name {val ""} {modes ""} {helpText ""} {init ""} {deinit ""} {off ""}} {
    global menus index::feature index::help global::tmpfeatures
    lunion menus $name
    if {$val != ""} {
	global $name
	if {![info exists $name]} { set $name $val }
    }
    if {[info exists index::feature($name)]} {
	eval lappend modes [lindex [set index::feature($name)] 1]
    }
    set index::feature($name) \
      [list [list "for" [lindex $modes 0] "mode"] $modes 1 \
      $name "$name ; $init" $deinit $off]
    if {[string trim $helpText] ne ""} {
	set index::help($val) $helpText
    }
    lappend global::tmpfeatures $name
}

# ◊◊◊◊ Mode specific items ◊◊◊◊ #

proc mode::listAll {{userInterfaceNames "0"} {includeInternal "1"}} {
    
    variable modeList
    
    set defaultNames [list]
    if {$includeInternal} {
	set defaultNames $modeList
    } else {
	set internalModes [alpha::internalModes]
	foreach modeName $modeList {
	    if {([lsearch $internalModes $modeName] == -1)} {
	        lappend defaultNames $modeName
	    }
	} 
    }
    set modeNames [list]
    foreach modeName $defaultNames {
	lappend modeNames [mode::getName $modeName $userInterfaceNames]
    }
    return [lsort -dictionary $modeNames]
}

proc mode::listAllLoaded {{userInterfaceNames 0}} {
    
    global seenMode
    
    set modeNames [list]
    foreach modeName [array names seenMode] {
        if {($modeName eq "")} {
            continue
        } 
	lappend modeNames [mode::getName $modeName $userInterfaceNames]
    } 
    return [lsort -dictionary -unique $modeNames]
}

proc mode::exists {m} {
    global mode::features
    set m [mode::getName $m 0]
    info exists mode::features($m)
}

proc mode::removeFeatureFromAll {f} {
    global mode::features
    foreach m [array names mode::features] {
	if {[set idx [lsearch -exact [set mode::features($m)] $f]] >= 0} {
	    set mode::features($m) [lreplace [set mode::features($m)] $idx $idx]
	    prefs::modified mode::features($m)
	} elseif {[set idx [lsearch -exact [set mode::features($m)] "-$f"]] >= 0} {
	    set mode::features($m) [lreplace [set mode::features($m)] $idx $idx]
	    prefs::modified mode::features($m)
	}
    }
}

proc mode::getFeatures {m} {
    variable features
    set m [mode::getName $m 0]
    if {![info exists features($m)]} {
	return -code error "No known mode \"$m\".  If this is a newly\
	  installed mode, you probably need to rebuild your package indices."
    }
    set features($m)
}

proc mode::adjustFeatures {f {add 1}} {
    global mode::features mode
    set idx [lsearch -exact [set mode::features($mode)] $f]
    if {$add} {
	if {$idx < 0} {
	    if {[package::do_activate $f]} {
		package::throwActivationError
	    } else {
		lappend mode::features($mode) $f
		prefs::modified mode::features($mode)
	    }
	}
    } else {
	if {$idx >= 0} {
	    set mode::features($mode) [lreplace [set mode::features($mode)] $idx $idx]
	    package::deactivate $f
	    prefs::modified mode::features($mode)
	}
    }
}

proc mode::isFeatureActive {m f} {
    global mode::features
    set m [mode::getName $m 0]
    if {![info exists mode::features($m)]} {
	return 0
    }
    return [expr {[lsearch -exact [set mode::features($m)] $f] != -1}]
}

proc mode::listBindings {{m ""}} {
    if {$m == ""} { 
	global mode
	set m $mode 
    }
    set m [mode::getName $m 0]
    
    set modeBindings [list]
    foreach b [lsort -dictionary [split [bindingList $m] "\r"]] {
	set last [lindex [split [string trim $b] " "] end]
	if {$last eq $m} {
	    lappend modeBindings $b
	}
    }
    global::bindingsWindow "Current $m Mode Bindings" $modeBindings
} 

proc mode::changeDialog {} {
    set allModes [mode::listAll 1]
    if {([set M [win::getMode "" 1]] eq "")} {
        set M "Text"
    }
    set NewMode [listpick -p "Mode:" -L [list $M] [mode::listAll 1]]
    win::ChangeMode [mode::getName $NewMode 0]
    return
}

proc mode::describe {{m ""}} {
    global mode mode::features tcl_platform
    variable Filepats
    if {![string length $m]} {
	set m $mode
    } else {
	set m [mode::getName $m 0]
	loadAMode $m
    }
    set M [mode::getName $m 1]
    global fillColumn
    watchCursor
    status::msg "Creating the mode description file…"

    set name "* <$M> Mode *"
    if {![catch {bringToFront $name}]} {return}
    
    set txt "\r$M Mode Description\r\r"
    if {![catch {package::describe $m 1} res]} {
	append txt $res "\r\r"
    }
    append txt "\"# '$M' Mode Help\"\r"
    append txt "\"# Mode file patterns\"\r"
    append txt "\"# Mode menus and features\"\r"
    append txt "\"# Package-specific variables\"\r"
    append txt "\"# Mode-specific bindings\"\r\r"
    append txt "<<floatNamedMarks>>\r\r"
    append txt "\t-------------------------------------------------------------\r\r"
    if {![catch {package::helpWindow $m 1} helpFile]} {
	append txt "\t  \t'$M' Mode Help\r\r    ${helpFile}\r\r"
    }

    append txt "\t  \tMode file patterns\r\r"
    append txt "Preferences: SuffixMappings\r\r"
    if {[info exists Filepats($m)]} {
	append txt "[breakIntoLines [join $Filepats($m) ", "] $fillColumn 4]\r\r"
    } else {
	append txt "    (none)\r\r"
    }
    append txt "\t  \tMode menus and features\r\r"
    append txt "Preferences: Mode-Menus-${m}\r"
    append txt "Preferences: Mode-Features-${m}\r\r"
    if {[info exists mode::features($m)]} {
	foreach f $mode::features($m) {append txt "    package: ${f}\r"}
	append txt \r
    } else {
	append txt "    (none)\r\r"
    }
    append txt "\t  \t[mode::describeVars $m]\r\r"
    append txt "\t  \tMode-specific bindings\r\rabbreviations:  "
    if {$tcl_platform(platform) == "windows"} {
	# Could do something about 'option'?
	append txt "<c> = alt, <o> = option, "
    } else {
	append txt "<c> = command, <o> = option, "
    }
    append txt "<z> = control, <s> = shift\r\r"
    foreach b [split [bindingList] "\r"] {
	if {[lindex [split $b " "] end] eq $m} {append txt "  $b\r"}
    }
    append txt "\rTo list mode-independent bindings, select the menu items"
    append txt "\r\"Config > List Global/All Bindings\"\r"
    # Create the new window.
    new -n $name -m Text -text $txt -shell 1 -read-only 1
    # Add some hyperlinks.
    help::markColourAndHyper
    # Colour comments.
    win::searchAndHyperise {^[\t ]*#[^\r\n]+} {} 1 5
    # Colour preferences blue
    win::searchAndHyperise " : \"\[^\"\]*\"(\r|\n)" {} 1 1 +2 -1
    goto [minPos]
    refresh
    status::msg "Creating the mode description file… complete."
}

proc mode::describeVars {pkg {pkgpref ""}} {
    global index::prefshelp
    if {$pkgpref == ""} {set pkgpref $pkg}
    global ${pkgpref}modeVars
    append text "Package-specific variables\r\r"
    if {[lsearch [mode::listAll] $pkg] > -1} {
        append text "Preferences: Mode-${pkg}\r\r"
    } else {
        append text "Preferences: ${pkg}\r\r"
    }
    if {[array exists ${pkgpref}modeVars]} {
	global fillColumn prefs::type
	foreach v [lsort -dictionary [array names ${pkgpref}modeVars]] {
	    # Get the description.
	    if {[info exists index::prefshelp(${pkg},$v)]} {
		set hd [dialog::helpdescription $index::prefshelp(${pkg},$v)]
	    } elseif {[info exists index::prefshelp(${pkgpref},$v)]} {
		set hd [dialog::helpdescription $index::prefshelp(${pkgpref},$v)]
	    } elseif {[info exists index::prefshelp($v)]} {
		set hd [dialog::helpdescription $index::prefshelp($v)]
	    } else {
		set hd "(no description)"
	    }
	    # Format and add the description.
	    set description [breakIntoLines $hd $fillColumn 0]
	    regsub -all "\[\r\n\]" $description "&\# " description
	    append text "# " $description "\r"
	    # Get the value.
	    set val [set ${pkgpref}modeVars($v)]
	    if {[info exists prefs::type($v)] \
	      && [regexp {binding$} [set prefs::type($v)]]} {
		set val [dialog::specialView::binding $val]
	    }
	    # Add this to the result.
	    append text [format "%-20s: \"%s\"\r" "$v " $val]
	}
    } else {
	append text "# No preferences for '$pkg' available.\r"
    }
    
    return $text
}

##
 # --------------------------------------------------------------------------
 # 
 # "mode::menus" --
 # "mode::features" --
 # 
 # Called by the "Config > Mode Prefs " menu items to change either the mode
 # menus or features, redirect to [prefs::dialogs::modeMenusFeatures].
 # 
 # --------------------------------------------------------------------------
 ##

proc mode::menus {{m ""}} {
    prefs::dialogs::modeMenusFeatures "menus" $m
    return
}

proc mode::features {{m ""}} {
    prefs::dialogs::modeMenusFeatures "features" $m
    return
}

proc mode::menusAndFeatures {{m ""} {mfb 0}} {
    if {$m == ""} {
	global mode
	set m $mode
    }
    dialog::pickMenusAndFeatures $m $mfb
}

set mode::_namespacevars [list escapeChar quotedstringChar paragraphName\
  functionName startFunction endFunction \
  lineContinuationChar commentCharacters(General) commentCharacters(Paragraph) \
  commentCharacters(Box) startPara endPara commentBlockBreaks]

# Returns a list of two elements: 
# 
#   {(mode|global) $value}
# 
# Returns an empty list if the variable requested doesn't exist.  It
# knows about both <mode>modeVars and <mode>:: (Although we should
# probably fix on just one of these two in the future).
proc mode::getVarInfo {var varModeList} {
    variable _namespacevars

    if {[lsearch -exact $_namespacevars $var] != -1} {
	foreach aMode $varModeList {
	    if {[string length $aMode]} {
		global ${aMode}modeVars
		if {[info exists ::${aMode}::$var]} {
		    return [list "mode" [set ::${aMode}::$var]]
		}
	    }
	}
    } else {
	foreach aMode $varModeList {
	    if {[string length $aMode]} {
		global ${aMode}modeVars
		if {[info exists ${aMode}modeVars($var)]} {
		    return [list "mode" [set ${aMode}modeVars($var)]]
		}
	    }
	}
    }
    if {[globalVarIsShadowed $var]} {
	return [list "global" [globalVarSet $var]]
    } else {
	# Don't use 'global $var' because var might actually be an array
	# element descriptor like 'commentCharacters(Box)' which would
	# throw an error.
	if {[info exists ::$var]} {
	    return [list "global" [set ::$var]]
	} else {
	    return ""
	}
    }
}

# This will ensure that the mode var with the given name is set to the
# value of the (current) global variable with that name (if the right mode is the 
# currently active), and optionally set to the given new-value.
# 
# It will also ensure that prefs::modified is called on the mode var so
# that it is subsequently saved.  This can be used by any mode that
# changes (or wishes to change) the value of the given global copy of
# the mode var and therefore needs to ensure the mode var has been
# updated too (it is the mode's responsibility to do this for anything
# that is changed outside the standard prefs dialogs).
# 
# Note that if the mode is not currently active and no newValue is 
# given, then this will throw an error since it is being asked to
# perform an inconsistent action (the global variable with the given
# name does not correspond to the mode).
proc mode::setVar {m modeVarName {newValue ""}} {
    global mode $modeVarName ${m}modeVars
    if {[llength [info level 0]] == 4} {
	# Optional 'newValue' given
	if {$m eq $mode} {
	    # The global variable corresponds to this mode
	    # so set it to the newValue.
	    set $modeVarName $newValue
	}
    } else {
	# Optional argument not given.  We must be the active
	# mode for this to make sense.
        if {$m ne $mode} {
	    return -code error "Can't use mode::setVar without\
	      a value given if not the current mode."
	}
	# Get the current global value.
	set newValue [set $modeVarName]
    }
    # Now '$newValue' is valid in all code paths, so set the 
    # mode value...
    set ${m}modeVars($modeVarName) $newValue
    # ...and arrange for it to be remembered.
    prefs::modified ${m}modeVars($modeVarName)
}

# This will ensure that the mode var with the given name is set to the
# value of the (current) global var with that name, and ensure that
# prefs::modified is called on the mode var so that it is subsequently
# saved.  This can be used by any mode that changes (or wishes to 
# change) the value of the given global copy of the mode var and 
# therefore needs to ensure the mode var has been updated too (it is 
# the mode's responsibility to do this for anything that is changed 
# outside the standard prefs dialogs).
# 
# Note that one can optionally provide a value to set both global and
# mode-var to, so really one can use 'synchroniseModeVar' just like
# 'set' but to set both global and modeVar in one go, and ensure the
# change will be saved in the user's preferences.
proc synchroniseModeVar {var args} {
    global mode
    eval [list mode::setVar $mode $var] $args
}

# The 'nextLineGetter' is a script which when evaluated either
# does a 'break' (no more lines), or returns the next line of
# interest.
proc mode::getFromUnixFirstLine {line nextLineGetter} {
    # See if a unix executable name is embedded in the first line
    if {[regexp -- {^#![\t\ ]*(.+)$} $line -> mtch] } {
	#  the next regexp should catch near any name of program
	#  but not those that have spaces in their names
	if {[regexp -- {^(?:/usr/bin/env\s+)?(\S+)} $mtch -> majorMode]} { 
	    set majorMode [file tail $majorMode]
	    # remove trailing version number
	    set majorMode [string trimright $majorMode "01234567890."]
	    if {$majorMode eq "sh"} {
		# need to check if we're using a common unix trick
		while {1} {
		    set ll [eval $nextLineGetter]
		    if {[string index [string trimleft $ll] 0] ne "#"} {
			break
		    }
		}
		if {$ll == ""} {
		    if {[regexp -- {[\n\r][ \t]*[^#][^\r\n]*[\r\n]} $line ll]} {
			set ll [string trimleft $ll]
		    } else {
			set ll ""
		    }
		}
		if {[regexp -- {^exec[ \t]+(\S+)} $ll dummy ll]} {
		    set majorMode [file tail [string trimright $ll "01234567890."]]
		}
	    }		
	} else {
	    return ""
	}
    } elseif {[regexp -- {-\*- *(?:Mode:)? *([^	:;]+).*-\*-} $line "" majorMode]} {
	# We found a mode line, storing the supposed name of the mode
	# as $majorMode - below we will check if we recognise that as a mode.
    } else {
	return ""
    }
    return [string tolower $majorMode]
}

# ◊◊◊◊ Miscellaneous ◊◊◊◊ #

proc alpha::tryToLoad {msg args} {
    status::msg "${msg}…"
    set i -1
    set ok 1
    while 1 {
	set do [lindex $args [incr i]]
	set say [lindex $args [incr i]]
	if {$say == ""} {
	    set say "Loading $do"
	}
	if {$do == ""} {
	    if {$ok} {
		status::msg "${msg}…Complete."
	    } else {
		alertnote "${msg}…Failed."
	    }
	    return $ok
	}
	status::msg "${say}…"
	if {[catch $do err]} {
	    set thisErrInfo $::errorInfo
	    if {[dialog::yesno -y "View the error" -n "Continue" \
	      "$say failed!"]} {
		set y "Continue"
		set n "Save Error To Clipboard"
		if {![dialog::yesno -y $y -n $n -- $thisErrInfo]} {
		    putScrap $thisErrInfo
		} 
	    }
	}
    }
}

# ◊◊◊◊ Read in all the packages ◊◊◊◊ #

proc alpha::findAllPlugins {} {
    # Execute pre-init code for each extension whose requirements didn't fail.
    if {[cache::exists index::preinit]} {
	cache::readContents index::preinit
	foreach f [array names preinit] {
	    # Make sure that the given package/library etc is valid.
	    global alpha::packageRequirementsFailed
	    if {[info exists alpha::packageRequirementsFailed]} {
		if {([lsearch ${alpha::packageRequirementsFailed} $f] > -1)} {
		    continue
		}
	    }
	    # Still here -- so evaluate the preinit script.
	    set script [lindex [set preinit($f)] 1]
	    try::level \#0 $script -reporting log -while "pre-initialising $f" 
	}
    }
    # Now pull in regular initialisation
    findAllModes
    # This will only load the correct set of extensions,
    # taking into account whether we started with
    # 'skip prefs' or not.
    findAllExtensions
}

proc alpha::findAllModes {} {
    cache::readContents index::mode
    foreach f [array names mode] {
	eval [list addMode $f] [lrange [set mode($f)] 1 3]
	if {[string length [set script [lindex [set mode($f)] 4]]]} {
	    if {[catch {uplevel #0 $script} err]} {
		lappend problems "$f"
		lappend errors $err
	    }
	}
    }
    if {[info exists problems]} {
	if {[dialog::yesno "Problems loading modes: $problems\
	  \rDo you want to see the errors?"]} {
	    alertnote [join $errors \n]
	}
    }
}




