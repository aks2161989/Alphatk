## -*-Tcl-*-
 # ###################################################################
 #  AlphaTcl - core Tcl engine
 # 
 #  FILE: "package.tcl"
 #                                    created: 2/8/97 {6:15:10 pm} 
 #                                last update: 02/25/2006 {01:11:43 PM} 
 #  Author: Vince Darley
 #  E-mail: <vince@santafe.edu>
 #    mail: 317 Paseo de Peralta, Santa Fe, NM 87501
 #     www: <http://www.santafe.edu/~vince/>
 #  
 # Copyright (c) 1997-2006  Vince Darley, all rights reserved
 # 
 #  How to ensure packages are loaded in the correct order?
 #  (some may require Vince's Additions).  Here perhaps we could
 #  just use a Tcl8-like-approach: introduce a 'package' command
 #  and have stuff like 'package Name 1.0 script-to-load'.
 #  Then a package can just do 'package require Othername' to ensure
 #  it is loaded.  I like this approach.
 #  
 #  How to initialise each package at startup?  If we use the above
 #  scheme, then the startup script is purely a sequence of
 #  'package require Name' commands.  The file 'prefs.tcl' is then
 #  purely for user-meddling.  Packages do not need to store anything
 #  there.  Sounds good to me.
 #  
 #  How to uninstall things?  One approach here is a 
 #  'package uninstall Name' command.  Nice packages would provide
 #  this.
 #  
 #  We need a default behaviour too.  Some packages require no
 #  installation at all (except placing in a directory), others 
 #  require sourcing, others need to add something to a menu.  How
 #  much of this should be automated and how much is up to the
 #  package author?
 # 
 # ----
 # 
 #  The solution below is to imitate Tcl 8.  There is a 'package'
 #  mechanism.  There exists a index::feature() array which gives for
 #  each package the means to load it --- a procedure name or a
 #  'source file' command.  The package index is compiled 
 #  automatically by recursively scanning all files in the
 #  Packages directory for 'package name version do-this'
 #  commands.
 #  
 #  There's also 'package names', 'package exists name', and an
 #  important 'package require name version' which allows one
 #  package to autoload another...
 #  
 # Pros of this approach: many packages, which would otherwise
 # require an installation procedure, now can be just dropped
 # in to the packages directory and they're installed! (After
 # rebuilding the package index).  This is because 'package'
 # can declare a snippet of code, an addition to a menu etcÉ
 # ----
 # 
 # Thanks to Tom Fetherston for some improvements here.
 # ###################################################################
 ##

namespace eval package {}

if {![info exists package::loaded]} {
    set package::loaded [list]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "alpha::findAllExtensions" --
 # 
 #  package require all extensions the user has activated
 # -------------------------------------------------------------------------
 ##
proc alpha::findAllExtensions {} {
    global global::features index::feature alpha::earlyPackages
    foreach m [array names index::feature] {
	if {[lsearch -exact [set global::features] $m] != -1} {
	    # it's on
	    if {[lsearch -exact [set alpha::earlyPackages] $m] != -1} {
		# We already did this one.
		continue
	    }
	    if {[set res [package::do_activate $m]]} {
		set global::features [lremove -- $global::features [list $m]]
		package::throwActivationError
	    }
	} else {
	    if {[lindex [set index::feature($m)] 2] == 2} {
		package::initialise $m
	    }
	}
    }

    # remove any package which doesn't exist.
    foreach m [set global::features] {
	if {![info exists index::feature($m)]} {
	    set global::features [lremove -- $global::features [list $m]]
	}
    }
}

proc alpha::isPackageInvisibleToUser {pkg} {
    global alpha::packagesAlwaysOn alpha::packageRequirementsFailed \
      index::feature
    if {[lsearch -exact [set alpha::packagesAlwaysOn] $pkg] != -1} {
	return 1
    }
    if {[info exists alpha::packageRequirementsFailed]} {
	if {[lsearch -exact [set alpha::packageRequirementsFailed] $pkg] != -1} {
	    return 1
	}
    }
    # Check for "auto-loading" features.
    if {[info exists index::feature($pkg)] \
      && ([lindex [set index::feature($pkg)] 2] == "-1")} {
	return 1
    }
    return 0
}

## 
 # -------------------------------------------------------------------------
 # 
 # "package::addPrefsDialog" --
 # 
 #  Register a given package as having a standard preferences page which
 #  should be accessible from the 'Config->Packages' menu.  If the optional
 #  'mapTo' argument is given, then the actual preferences data is not
 #  stored in the array variable ${pkg}modeVars, but rather in 
 #  ${mapTo}modeVars.  This is useful if the 'pkg' name is rather long..
 # -------------------------------------------------------------------------
 ##
proc package::addPrefsDialog {pkg {mapTo ""}} {
    global package::prefs alpha::guiNotReady
    if {[string length $mapTo]} {
	# I think the existence of two variables *::prefs in this proc
	# causes problems, especially with lunion's upvar call.
	set ::alpha::prefs($pkg) $mapTo
    }
    lunion package::prefs $pkg
    if {![info exists alpha::guiNotReady]} {
	# we were called after start-up; but we currently only place
	# these packages inside a sub-dialog, so no need to build
	# anything.
	# menu::buildSome packages
    }
}

proc package::removePrefsDialog {packageName} {
     global package::prefs
     set idx [lsearch -exact ${package::prefs} $packageName]
     if {$idx != -1} {
	 set package::prefs [lreplace ${package::prefs} $idx $idx]
     }
}

##
 # --------------------------------------------------------------------------
 # 
 # "alpha::listAlphaTclPackages" --
 # 
 # List currently installed packages that match a given criteria.  Here a
 # "package" is any mode, menu or feature that has an entry in the array
 # "index::features", and includes all packages defined using some sort of
 # [alpha::package] procedure.  Modes added using [addMode], and Menus added
 # using [addMenu] will also be included in the list of results.  Preferences
 # are those packages declared with [alpha::flag] or [alpha::declare flag].
 # Following standard AlphaTcl nomenclature, any package that is not
 # categorized specifically as a "Mode" or a "Menu" or "Preference" is
 # considered to be a "Feature".
 # 
 # Listing options include:
 # 
 #   always-on              Packages turned on in "runAlphaTcl.tcl"
 #   auto-loading           Features defined using [alpha::library], or by
 #                            [alpha::extension] with an empty init script.
 #   early                  Packages turned on early in "runAlphaTcl.tcl"
 #   invalid                All Packages whose requirements failed
 #   features               Features defined using [alpha::feature]
 #   features-global        Features useful globally
 #   features-global-only   Features useful only globally
 #   features-mode          Features useful only for specific modes
 #   features-mode-<mode>   Features useful for a given mode
 #   menus                  All Menus available
 #   menus-global           Menus defined as "global"
 #   menus-mode             Menus defined for specific modes
 #   menus-mode-<mode>      Menus defined for a given mode
 #   modes                  Modes defined using [alpha::mode] or [addMode].
 #   preferences            Features defined using [alpha::flag]
 #   uninstallable          Packages that have "uninstall" scripts, but are
 #                            not defined as "always-on"
 # 
 # These lists do not make any attempt to determine any activation status,
 # but once the list has been returned calling code can pare it down using
 # whatever criteria is desired.
 # 
 # --------------------------------------------------------------------------
 ##

proc alpha::listAlphaTclPackages {{type "all"} {userInterfaceNames "0"}} {
    
    global HOME index::feature index::uninstall alpha::earlyPackages \
      alpha::packageRequirementsFailed alpha::packagesAlwaysOn
    
    set results [list]
    # Create the list of all recognized packages.
    set allPackages [array names index::feature]
    # Create the list for the given criteria.
    switch -regexp -- $type {
	"^all$" {
	    set results $allPackages
	}
	"^always-on$" {
	    set results [set alpha::packagesAlwaysOn]
	}
	"^auto-loading$" {
	    foreach p $allPackages {
		if {([lindex [set index::feature($p)] 2] == "-1")} {
		    lappend results $p
		}
	    }
	}
	"^early$" {
	    set results [set alpha::earlyPackages]
	}
	"^invalid$" {
	    set results [set alpha::packageRequirementsFailed]
	}
	"^features$" {
	    foreach p $allPackages {
		if {([lindex [set index::feature($p)] 2] == "0")} {
		    lappend results $p
		}
	    }
	}
	"^features-global$" {
	    foreach p $allPackages {
		if {([lindex [set index::feature($p)] 2] != "0")} {
		    continue
		}
		set forWhat [lindex [set index::feature($p)] 1]
		if {([lsearch $forWhat "global-only"] > -1)} {
		    lappend results $p
		} elseif {([lsearch $forWhat "global"] > -1)} {
		    lappend results $p
		}
	    }
	}
	"^features-global-only$" {
	    foreach p $allPackages {
		if {([lindex [set index::feature($p)] 2] != "0")} {
		    continue
		}
		set forWhat [lindex [set index::feature($p)] 1]
		if {([lsearch $forWhat "global-only"] > -1)} {
		    lappend results $p
		}
	    }
	}
	"^features-mode" {
	    regsub -- "^features-mode-?" $type "" m
	    foreach p $allPackages {
		if {([lindex [set index::feature($p)] 2] != "0")} {
		    continue
		}
		set forWhat [lindex [set index::feature($p)] 1]
		if {([lsearch $forWhat "global-only"] > -1)} {
		    continue
		} elseif {[string length $m] && ([lsearch $forWhat $m] == -1)} {
		    continue
		} else {
		    lappend results $p
		}
	    }
	}
	"^menus$" {
	    foreach p $allPackages {
		if {([lindex [set index::feature($p)] 2] == "1")} {
		    lappend results $p
		}
	    }
	}
	"^menus-global$" {
	    foreach p $allPackages {
		if {([lindex [set index::feature($p)] 2] != "1")} {
		    continue
		} 
		set forWhat [lindex [set index::feature($p)] 1]
		if {([lsearch $forWhat "global-only"] > -1)} {
		    lappend results $p
		} elseif {([lsearch $forWhat "global"] > -1)} {
		    lappend results $p
		}
	    }
	}
	"^menus-global-only$" {
	    foreach p $allPackages {
		if {([lindex [set index::feature($p)] 2] != "1")} {
		    continue
		} 
		set forWhat [lindex [set index::feature($p)] 1]
		if {([lsearch $forWhat "global-only"] > -1)} {
		    lappend results $p
		}
	    }
	}
	"^menus-mode" {
	    regsub -- "^menus-mode-?" $type "" m
	    foreach p $allPackages {
		if {([lindex [set index::feature($p)] 2] != "1")} {
		    continue
		} 
		set forWhat [lindex [set index::feature($p)] 1]
		if {([lsearch $forWhat "global-only"] > -1)} {
		    continue
		} elseif {($m eq "only") && ([lsearch $forWhat "global"] == -1)} {
		    lappend results $p
		} elseif {[string length $m] && ([lsearch $forWhat $m] == -1)} {
		    continue
		} else {
		    lappend results $p
		}
	    }
	}
	"^modes$" {
	    set results [mode::listAll]
	}
	"^preferences$" {
	    foreach p $allPackages {
		if {([lindex [set index::feature($p)] 2] == "2")} {
		    lappend results $p
		} 
	    }
	}
	"^uninstallable$" {
	    if {![info exists index::uninstall]} {
		cache::readContents index::uninstall
	    } 
	    foreach p [array names index::uninstall] {
		if {([lsearch ${alpha::packagesAlwaysOn} $p] == -1)} {
		    lappend results $p
		} 
	    }
	}
	default {
	    error "Unknown package listing type: $type"
	}
    }
    set packageList [list]
    if {!$userInterfaceNames} {
	set packageList $results
    } elseif {[regexp -nocase -- {^modes$} $type]} {
	foreach m $results {
	    lappend packageList [mode::getName $m 1]
	}
    } else {
	foreach p $results {
	    lappend packageList [quote::Prettify $p]
	}
    }
    return [lsort -dictionary -unique $packageList]
}

proc package::versionCheck {name vers} {
    set av [alpha::package versions $name]
    set c [alpha::_versionCompare $av $vers]
    if {$c < 0 && $c != -3} {			
	error "The installed version $av of '$name' is too old.\
	  Version $vers was requested."
    } elseif {$c == -3} {			
	error "The installed version $av of '$name' may not be\
	  backwards compatible with the requested version ($vers)."
    }			
}

proc package::reqInstalledVersion {name exact? {reqvers ""}} {
    global index::feature
    # called from installer
    set msg " I suggest you do not continue with the installation."
    if {[info exists index::feature($name)]} {
	if {[set exact?] == ""} {return}
	set av [alpha::package versions $name]
	if {[set exact?] == "-exact"} {
	    if {!([alpha::package versions $name] eq $reqvers)} {
		alertnote "The installed version $av of '$name' is incorrect.\
		  Exact version $reqvers was requested.$msg"
	    }
	} else {
	    set reqvers [set exact?]
	    if {$reqvers != ""} {		
		set c [alpha::_versionCompare $av $reqvers]			
		if {$c < 0 && $c != -3} {			
		    alertnote "The installed version $av of '$name' is\
		      too old. Version $reqvers was requested.$msg"
		} elseif {$c == -3} {			
		    alertnote "The installed version $av of '$name' may\
		      not be backwards compatible with the requested\
		      version ($reqvers).$msg"
		} 			
	    }		
	}
    } else {
	alertnote "This package requires the prior installation of '$name'.\
	  It is not currently installed.$msg"
    }
}

proc package::active {pkg {text ""}} {
    variable loaded
    set off [expr {[lsearch -exact $loaded $pkg] == -1}]
    if {[llength $text]} {
	return [lindex $text $off]
    } else {
        return [expr {!$off}]
    }
}

# Returns a single line of description for a given package, or the
# empty string.
proc package::description {pkg} {
    
    global alpha::application
    
    set lines [list]
    set desc [alpha::package description $pkg]
    # If there is no description, and this package is actually only
    # of use for another package (e.g. a menu of a particular mode),
    # then extract the description of that associated package.
    if {![llength $desc]} {
	set vers [alpha::package versions $pkg]
	if {[lindex $vers 0] eq "for"} {
	    set desc [alpha::package description [lindex $vers 1]]
	}
    }
    regsub -all -- {ÇALPHAÈ} $desc $alpha::application desc
    foreach line [split [lindex $desc 1] \r\n] {
	set trim [string trim $line]
	if {($trim ne "")} {
	    lappend lines [string trim $line]
	}
    }
    return [join $lines " "]
}

proc package::helpWindow {pkg {pointer 0}} {
    global alpha::application
    if {([lsearch [mode::listAll 1] $pkg] > -1) \
      || ([lsearch [mode::listAll] $pkg] > -1)} {
        set pkg [mode::getName $pkg 0]
	set Pkg [mode::getName $pkg 1]
    } else {
	set Pkg [quote::Prettify $pkg]
    }
    set v [alpha::package versions $pkg]
    if {[lindex $v 0] == "for"} {
	set type [lindex $v 2]
	set v [lindex $v 1]
	if {$pointer} {
	    return "The '$pkg' package is implemented by $v $type, \
	      and has no separate help."
	}
	set pkg $v
    }
    if {[llength [set res [alpha::package help $pkg]]]} {
	set help [string trim [lindex $res 1]]
	if {[regexp -- {^file[ \t\r\n]} $help]} {
	    if {![is::List $help]} {
		error "Bad help spec $help"
	    }
	    if {$pointer} {
		return "Help for this package is located in \
		  \"[lindex $help 1]\""
	    } else {
		# A badly constructed help section will throw an error
		# here if it's not a valid list.
		help::openFile [lindex $help 1]
	    }
	} else {
	    set title "* $Pkg Help *"
	    if {$pointer} {
		return $help
	    } elseif {[win::Exists $title]} {
		bringToFront $title
	    } else {
		watchCursor
		regsub -all -- {ÇALPHAÈ} $help $::alpha::application help
		set txt "\r$Pkg Help\r\r"
		# Add version, maintainer info.
		set v [alpha::package versions $pkg]
		set m [join [lindex [alpha::package maintainer $pkg] 1] \
		  "\r             "]
		if {![string length $m]} {set m "(none)"}
		append txt "Version    : ${v}\rMaintainer : ${m}\r\r"
		# Create the new 'help' window.
		new -n $title -info "${txt}\r    [string trim $help]\r\r" \
		  -mode "Help"
		help::markColourAndHyper
	    }
	}
	return
    }
    if {!$pointer} {
	alertnote "Sorry, there isn't a help file for that package. \
	  You should contact the package maintainer."
    }
    return
}

proc package::helpOrDescribe {pkg} {
    if {[set mods [expr {[getModifiers] & 0xfe}]]} {
	if {$mods & 34} {
	    package::helpWindow $pkg
	} else {
	    package::describe $pkg
	}
	return 1
    }
    return 0
}

# ×××× Specific to 'features' ×××× #

proc package::addRelevantMode {_feature mode} {
    global index::feature
    if {[info exists index::feature($_feature)]} {
	if {[lsearch -exact [set oldm [lindex [set index::feature($_feature)] 1]] $mode] != -1} {
	    return
	}
	lappend oldm $mode
	lset index::feature($_feature) 1 $oldm
    } else {
	set index::feature($_feature) [list [list "for" $mode "mode"] $mode]
    }
}

proc package::removeRelevantMode {_feature mode} {
    global index::feature
    if {[info exists index::feature($_feature)]} {
	if {[set idx [lsearch -exact [set oldm [lindex [set index::feature($_feature)] 1]] $mode]] == -1} {
	    return
	}
	set oldm [lreplace $oldm $idx $idx ""]
	lset index::feature($_feature) 1 $oldm
    }
}

proc package::makeOnOrOff {pkg state {formode ""}} {
    switch -- $state {
	"basic-on" {
	    if {![package::do_activate $pkg]} {
		if {$formode == "global"} {
		    global global::features
		    lappend global::features $pkg
		} else {
		    global mode::features
		    lappend mode::features($formode) $pkg
		    prefs::modified mode::features($formode)
		}
	    } else {
		package::throwActivationError
	    }
	}
	"basic-off" {
	    if {![package::tryToDeactivate $pkg terse]} {
		if {$formode == "global"} {
		    global global::features
		    set global::features [lremove -- $global::features [list $pkg]]
		} else {
		    global mode::features
		    set mode::features($formode) \
		      [lremove -- $mode::features($formode) [list $pkg]]
		    prefs::modified mode::features($formode)
		}
		if {[lsearch -exact $global::features $pkg] == -1} {
		    package::_off $pkg terse
		}
	    }
	}
	"mode-not-off" {
	    if {![package::do_activate $pkg]} {
		# It is on globally, and we previously turned it off for this mode
		global mode::features
		set mode::features($formode) \
		  [lremove -- [set mode::features($formode)] [list "-$pkg"]]
		prefs::modified mode::features($formode)
	    } else {
		package::throwActivationError
	    }
	}
	"mode-off" {
	    if {![package::tryToDeactivate $pkg terse]} {
		# It is on globally, and we now turn it off for this mode
		global mode::features
		lappend mode::features($formode) "-$pkg"
		prefs::modified mode::features($formode)
	    }
	}
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "package::onOrOff" --
 # 
 #  Complicated procedure to accomplish a relatively simple task!
 #  
 #  Given the old feature mode list and the new feature mode list, work
 #  out what changes have to be made to the set of on/off features to
 #  synchronise everything.
 #  
 #  This procedure is now only used by changeMode.
 #  
 #  Note that features which no longer exist are still returned by
 #  this procedure.  Hence calling procedures should possibly
 #  check whether the index::feature array entry exists.
 # -------------------------------------------------------------------------
 ##
proc package::onOrOff {oldFeatureModes newFeatureModes} {
    global global::features package::loaded
    
    #puts [list $oldFeatureModes $newFeatureModes]

    foreach f $package::loaded {
        set on($f) 1
    }
    
    foreach ll [lreverse $oldFeatureModes] {
	foreach fm $ll {
	    if {![mode::exists $fm]} { continue }
	    foreach f [mode::getFeatures $fm] {
		if {[string index $f 0] eq "-"} {
		    set f [string range $f 1 end]
		    # We'll set on($f) for anything in the global list
		    # later, so that will put anything back on that
		    # needs to be on.  Hence nothing to do here.
		} else {
		    # If the item is currently on, we'll want to
		    # turn it off (unless it's in the global
		    # list, when we'll add it back below).
		    unset -nocomplain on($f)
		}
	    }
	}
    }

    # Now we've removed all evidence of the old feature modes from the
    # 'on' list, we can add in the globally-active features
    foreach f $global::features {
	set on($f) 1
    }

    # Finally we apply the influence of the new feature modes.
    foreach ll $newFeatureModes {
	foreach fm $ll {
	    if {![mode::exists $fm]} { continue }
	    foreach f [mode::getFeatures $fm] {
		if {[string index $f 0] eq "-"} {
		    set f [string range $f 1 end]
		    # If this item is on, turn it off
		    unset -nocomplain on($f)
		} else {
		    # If this item is off, turn it on
		    set on($f) 1
		}
	    }
	}
    }

    #puts "off: [array get off]"
    #puts "on: [array get on]"
    
    set res_on [list]
    set res_off [list]
    
    foreach f $package::loaded {
	if {![info exists on($f)]} {
	    lappend res_off $f
	} else {
	    unset on($f)
	}
    }

    set res_on [array names on]
    
    #puts "off: $res_off"
    #puts "on: $res_on"

    return [list $res_off $res_on]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "package::partition" --
 # 
 #  Return either 3 lists: menus, features and then modes, if 'mode'
 #  is empty, or return 6 lists.
 #  
 #  In this second case we have 2 choices:
 #  
 #  (i) 'mode = global', we return: 
 #  usual menus, other menus, {}, usual features, other features, {}
 #  'Usual' means global, 'Other' means everything else.
 #  (ii) 'mode = some given mode', we return: 
 #  usual menus, general menus, other, usual features, general features, other
 #  'Usual' means mode-specific, 'General' means global, 'Other' means
 #  specific to other modes, or global-only
 #  
 #  Note: when we partition for a given mode, we remove all items
 #  which are currently globally on.
 # -------------------------------------------------------------------------
 ##
proc package::partition {{mode ""} {mfb 0} {ignore_flags 1}} {
    global index::feature index::flags
    set a ""
    set b ""
    set c ""
    if {$mode == ""} {
	# This is the case in which we just want everything.
	foreach n [lsort -dictionary [alpha::package names]] {
	    if {$ignore_flags && ([lsearch -exact ${index::flags} $n] != -1)} {
		continue
	    }
	    if {[info exists index::feature($n)]} {
		switch -- [lindex [set index::feature($n)] 2] {
		    "1" {
			lappend a $n
		    }
		    default {
			lappend b $n
		    }
		}
	    } else {
		lappend c $n
	    }
	}
	return [list $a $b $c]
    } else {
	# Now we either want only global items, or for the given mode
	set d ""
	set e ""
	set f ""
	set partition [array names index::feature]
	if {$mode == "global"} {
	    set mode "global*"
	    set search "-glob"
	} else {
	    set search "-exact"
	    global global::features
	    set partition [lremove -- $partition ${global::features}]
	}		
	foreach n [lsort -dictionary $partition] {
	    if {$ignore_flags && ([lsearch -exact ${index::flags} $n] != -1)} {
		continue
	    }
	    set ff [set index::feature($n)]
	    switch -- [lindex $ff 2] {
		"1" {
		    if {$mfb == 2} {continue}
		    if {[lsearch $search [lindex $ff 1] $mode] != -1} {
			lappend a $n
		    } elseif {[lsearch -exact [lindex $ff 1] "global"] != -1} {
			lappend b $n
		    } elseif {[lindex $ff 1] != "global-only"} {
			lappend c $n
		    }
		}
		"-1" {
		    # ignore auto-loading types
		}
		default {
		    if {$mfb == 1} {continue}
		    if {[lsearch $search [lindex $ff 1] $mode] != -1} {
			lappend d $n
		    } elseif {[lsearch -exact [lindex $ff 1] "global"] != -1} {
			lappend e $n
		    } elseif {[lindex $ff 1] != "global-only"} {
			lappend f $n
		    }
		}
	    }
	}
	return [list $a $b $c $d $e $f]
    }	
}

# Needs renaming and its callers updating
proc package::describe {pkg {return 0}} {
    set info [alpha::package info $pkg]
    set type [lindex $info 0]
    set v [alpha::package versions $pkg]
    if {[lindex $v 0] == "for"} {
	set msg "Package '$pkg', designed for use by [lindex $v 1]\
	  [lindex $v 2], is a"
	set basePkg [lindex $v 1]
    } else {
	set msg "Package '$pkg', version $v is a"
	set basePkg $pkg
    }
    
    switch -- $type {
	"feature" {
	    switch -- [lindex $info 3] {
		"1" {
		    append msg " menu, and is "
		    global global::menus
		    if {![package::active $pkg]} {
			append msg "not "
		    }
		    append msg "in use."
		}
		"-1" {
		    append msg "n autoloading $type."
		}
		default {
		    append msg " $type, and is \
		      [package::active $pkg {active inactive}]."
		}
	    }
	}
	"mode" {
	    append msg " $type; modes are always active."
	}
    }
    set pkg $basePkg
    cache::readContents index::maintainer
    if {[info exists maintainer($pkg)]} {
	set p [string trim [lindex [set maintainer($pkg)] 1]]
	if {$p ne ""} {
	    append msg "\rMaintainer: [lindex $p 0], [lindex $p 1]\r"
	    append msg [lindex $p 2]
	}
    }
    unset -nocomplain maintainer
    if {$return} {
	return $msg
    }
    # let package tell us where its prefs are stored.
    global alpha::prefs
    if {[info exists alpha::prefs($pkg)]} {
	set pkgpref [set alpha::prefs($pkg)]
    } else {
	set pkgpref $pkg
    }
    global ${pkgpref}modeVars
    # If there is additional information on this package, then
    # give the user three choices (help, more info, or cancel)
    if {[array exists ${pkgpref}modeVars] || [mode::exists $pkg]} {
	if {[catch {dialog::yesno -y "View Details" \
	  -n "View Help" -c $msg} res]} {
	    return
	}
	if {$res} {
	    if {[mode::exists $pkg]} {
		mode::describe $pkg
	    } else {
		append msg "\r\r" [mode::describeVars $pkg $pkgpref]
		new -n "* <$pkg> description *" -m Tcl -info $msg
	    }
	} else {
	    package::helpWindow $pkg
	}
    } else {
	# Else just let the user choose between help or continue
	if {![dialog::yesno -y "Continue" -n "View Package Help" $msg]} {
	    package::helpWindow $pkg
	}
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "package::deactivate" --
 # 
 #  Turns off all the packages given.  This procedure must never throw an
 #  error to its caller.
 # -------------------------------------------------------------------------
 ##
proc package::deactivate {args} {
    foreach pkg $args {
	package::tryToDeactivate $pkg log
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "package::activate" --
 # 
 #  Turns on all the packages given.  This procedure must never throw an
 #  error to its caller.
 # -------------------------------------------------------------------------
 ##
proc package::activate {args} {
    foreach pkg $args {
	package::tryToActivate $pkg log
    }
}

proc package::tryToDeactivate {pkg {reporting log}} {
    global index::feature alpha::guiNotReady package::loaded
    
    set idx [lsearch -exact $package::loaded $pkg]
    if {$idx == -1} { 
	# already off
	return 0 
    }
    
    if {[info exists index::feature($pkg)]} {
	set info [set index::feature($pkg)]
	if {[lindex $info 2] == 1} {
	    global $pkg
	    if {![info exists alpha::guiNotReady]} {
		set res [try::level \#0 "removeMenu \$$pkg\n[lindex $info 5]\nexpr 0" \
		  -reporting $reporting -while "deactivating $pkg"]
		set package::loaded [lreplace $package::loaded $idx $idx]
		return $res
	    }
	}
	set res [try::level \#0 "[lindex $info 5]\nexpr 0" \
	  -reporting $reporting -while "deactivating $pkg"]
	set package::loaded [lreplace $package::loaded $idx $idx]
	return $res
    } else {
	# This happens if the user completely removes a feature,
	# while some mode still wants to use it (e.g. particularly
	# with menus).
	alertnote "Something is trying to deactivate the '$pkg' feature,\
	  which no longer exists.  I will remove all references to it."
	mode::removeFeatureFromAll $pkg
	return 1
    }
}

proc package::_off {pkg {reporting log}} {
    global index::feature
    
    variable initted
    if {![info exists initted($pkg)]} { return }
    unset initted($pkg)
    
    set off [lindex [set index::feature($pkg)] 6]
    return [try::level \#0 "${off}\nexpr 0" \
      -reporting $reporting -while "turning off $pkg"]
}

proc package::do_activate {pkg} {
    global index::feature index::requirements alpha::guiNotReady \
      package::activationError package::loaded
    variable initted
    
    if {[lsearch -exact $package::loaded $pkg] != -1} {
	# already on
	return 0
    }
    
    if {[info exists index::requirements($pkg)]} {
	set info [lindex [set index::requirements($pkg)] 1]
	if {[string length $info]} {
	    set res [catch [list uplevel \#0 $info] package::activationError]
	    if {$res} {
		append package::activationError " (while requiring $pkg)"
		return $res
	    }
	}
    }
    if {[info exists index::feature($pkg)]} {
	set info [set index::feature($pkg)]
	if {![info exists initted($pkg)]} {
	    set init [lindex $info 3]
	    if {$init ne ""} {
		status::msg "Loading package '$pkg'É"
		set res [catch [list uplevel \#0 $init] package::activationError]
		if {$res} {
		    append package::activationError " (while initialising $pkg)"
		    return $res
		}
	    }
	    set initted($pkg) 1
	}
	set script [lindex $info 4]
	if {[lindex $info 2] == 1} {
	    global $pkg
	    if {![info exists alpha::guiNotReady]} {
		append script "\ninsertMenu \$$pkg"
	    }
	}
	set res [catch [list uplevel \#0 $script] package::activationError]
	if {$res} {
	    append package::activationError " (while activating $pkg)"
	} else {
	    # package is on and succeeded
	    lappend package::loaded $pkg
	}
	return $res
    } else {
	# This happens if the user completely removes a feature,
	# while some mode still wants to use it (e.g. particularly
	# with menus).
	alertnote "Something is trying to activate the '$pkg' feature,\
	  which no longer exists.  I will remove all references to it."
	mode::removeFeatureFromAll $pkg
	return 1
    }
}

proc package::throwActivationError {} {
    global package::activationError
    set thisErrInfo $::errorInfo
    if {[dialog::yesno -y "View Error Info" -n "Continue" \
      "The following problem occurred:\r [set package::activationError]\
      \rthat package will be deactivated if possible."]} {
	alpha::evaluateWhenGuiIsReady \
	  [list new -n {* Error Info *} -m Tcl -shrink -info $thisErrInfo]
    }
}

proc package::tryToActivate {pkg {reporting log}} {
    global index::feature index::requirements alpha::guiNotReady package::loaded
    variable initted
    
    if {[lsearch -exact $package::loaded $pkg] != -1} {
	# already on
	return 0
    }
    if {[info exists index::requirements($pkg)]} {
	set info [lindex [set index::requirements($pkg)] 1]
	if {[string length $info]} {
	    try::level \#0 $info -reporting $reporting -while "requiring $pkg" 
	}
    }
    if {[info exists index::feature($pkg)]} {
	set info [set index::feature($pkg)]
	if {![info exists initted($pkg)]} {
	    set init [lindex $info 3]
	    if {$init ne ""} {
		status::msg "Loading package '$pkg'É"
		try::level \#0 $init -reporting $reporting -while "initialising $pkg" 
	    }
	    set initted($pkg) 1
	}
	if {[lindex $info 2] == 1} {
	    global $pkg
	    if {![info exists alpha::guiNotReady]} {
		set res [try::level \#0 "[lindex $info 4]\ninsertMenu \$$pkg\nexpr 0" \
		  -reporting $reporting -while "activating $pkg"]
		if {$res == 0} {
		    lappend package::loaded $pkg
		}
		return $res
	    }
	}
	set res [try::level \#0 "[lindex $info 4]\nexpr 0" \
	  -reporting $reporting -while "activating $pkg"]
	if {$res == 0} {
	    lappend package::loaded $pkg
	}
	return $res
    } else {
	# This happens if the user completely removes a feature,
	# while some mode still wants to use it (e.g. particularly
	# with menus).
	alertnote "Something is trying to activate the '$pkg' feature,\
	  which no longer exists.  I will remove all references to it."
	mode::removeFeatureFromAll $pkg
	return 1
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "package::initialise" --
 # 
 #  Initialises all the packages given.  This procedure must never throw an
 #  error to its caller.
 # -------------------------------------------------------------------------
 ##
proc package::initialise {args} {
    global index::feature
    variable initted
    foreach pkg $args {
	if {[info exists index::feature($pkg)]} {
	    if {![info exists initted($pkg)]} {
		set init [lindex [set index::feature($pkg)] 3]
		if {$init ne ""} {
		    status::msg "Loading package '$pkg'É"
		    try::level \#0 $init -reporting log -while "initialising $pkg"
		}
		set initted($pkg) 1
	    }
	} else {
	    # This happens if the user completely removes a feature,
	    # while some mode still wants to use it (e.g. particularly
	    # with menus).
	    alertnote "Something is trying to activate the '$pkg' feature,\
	      which no longer exists.  I will remove all references to it."
	    mode::removeFeatureFromAll $pkg
	}
    }
}

proc package::uninstall {} {
    global index::uninstall
    cache::readContents index::uninstall
    if {![llength [set pkgs [array names index::uninstall]]]} {
	alertnote "There are no packages to uninstall."
	return
    }
    set pkgs [listpick -p "Permanently remove which packages/modes/menus?" \
      -l [lsort -dictionary $pkgs]]
    if {![llength $pkgs]} { return }
    if {![dialog::yesno "Are you absolutely sure you want to\
      uninstall [join $pkgs {, }]?\r\rThis cannot be undone."]} { 
	return 
    }
    global pkg_file
    foreach pkg $pkgs {
	set pkg_file [lindex [set index::uninstall($pkg)] 1]
	set pkg_file [uplevel \#0 [list subst $pkg_file]]
	set script [lindex [set index::uninstall($pkg)] 2]
	if {[regexp "rm -r\[^\r\n\]*" $script check]} {
	    if {![dialog::yesno "The uninstaller for $pkg contains a\
	      recursive removal command '$check'. Do you want to do this?"]} { 
		return 
	    }
	}
	if {[catch [list uplevel \#0 $script] err]} {
	    set thisErrInfo $::errorInfo
	    if {[dialog::yesno -y "View Error Info" -n "Continue" \
	      "The uninstaller for $pkg had problems!\r\r(Error: $err)"]} {
		new -n {* Error Info *} -m Tcl -shrink -info $thisErrInfo
	    }
	}
    }
    if {[askyesno "It is recommended that you quit and restart\
      ${alpha::application}.\\r\rDo you want to quit now?"]} {
	quit
    }
    if {[askyesno "If you don't quit, all indices must\
      certainly be rebuilt.\r\rWould you like to do this now?"]} {
	alpha::rebuildPackageIndices
	rebuildTclIndices
    } else {
	alertnote "This will probably cause problems."
	return
    }
    if {[askyesno "Now that you've rebuilt indices, you really should\
      quit and restart ${alpha::application}.\
      \r\rDo you want to quit now?"]} {
	quit
    } else {
        status::msg "You have been forewarned É"
    }
    unset index::uninstall
}

