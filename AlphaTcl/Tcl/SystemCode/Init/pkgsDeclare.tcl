# (After status bar exists)
# 
# Code for handling AlphaTcl package declarations.  Only used once the
# status bar is present.

namespace eval index {}
namespace eval mode  {}
namespace eval alpha {}

## 
 # -------------------------------------------------------------------------
 # 
 # "alpha::package" --
 # 
 #  Mimics the Tcl standard 'package' command for use with Alpha.
 #  It does however have some differences.
 #  
 #  package require ?-exact? ?-extension -mode -menu? name version
 #  package exists ?-extension -mode -menu? name version
 #  package names ?-extension -mode -menu?
 #  package uninstall name version
 #  package vcompare v1 v2
 #  package vsatisfies v1 v2
 #  package versions ?-extension -mode -menu? name
 #  package type name
 #  package info name
 #  package maintainer name version {name email web-page}
 #  package modes 
 #  
 #  Equivalent to alpha::mode alpha::menu and alpha::extension
 #  
 #  package mode ...
 #  package menu ...
 #  package extension ...
 #  
 #  For extensions only:
 #  
 #  package forget name version
 # -------------------------------------------------------------------------
 ##
proc alpha::package {cmd args} {
    global index::feature
    switch -- $cmd {
	"require" {
	    set info [alpha::_packageGetInfo "exact loose"]
	    global alpha::rebuilding
	    if {[llength $info]} {
		# When we're rebuilding package indices we don't want to
		# try to load up a package or throw an error.  We want
		# all that to happen when things are actually used.
		if {!${alpha::rebuilding} && [set version [lindex $args 1]] != ""} {
		    if {[info exists exact]} {
			if {!([lindex $info 0] eq $version)} {
			    error "requested $name exact $version, had [lindex $info 0]"
			}
		    } elseif {[info exists loose]} {
			if {[alpha::package vcompare [lindex $info 0] $version] < 0} {
			    error "requested $name $version or newer, had [lindex $info 0]"
			}
		    } elseif {![alpha::package vsatisfies [lindex $info 0] $version]} {
			error "requested $name $version, had [lindex $info 0]"
		    }
		}
		if {$alpha::rebuilding} {
		    return
		}
		if {$type eq "feature"} {
		    global global::features
		    set failed [package::do_activate $name]
		    if {$failed != 1} {
			if {[lsearch -exact ${global::features} $name] == -1} {
			    lappend global::features $name
			}
		    } else {
			package::throwActivationError
		    }
		}
		return [lindex $info 0]
	    }
	    if {!${alpha::rebuilding}} {
		error "can't find package $name"
	    }
	}
	"uninstall" {
	    set name [lindex $args 0]
	    if {[llength $args] > 2} {
		set version [lindex $args 1]
		global alpha::rebuilding 
		if {${alpha::rebuilding}} {
		    global rebuild_cmd_count index::uninstall pkg_file
		    switch -- [string trim [set script [lindex $args 2]]] {
			"this-file" {
			    set script [alpha::actionOnFileScript \
			      "file delete" $pkg_file]
			}
			"this-directory" {
			    set script [alpha::actionOnFileScript \
			      "file delete -force" [file dirname $pkg_file]]
			}
		    }
		    set index::uninstall($name) [list $version \
		      [string trim [alpha::actionOnFileScript "" $pkg_file]] $script]
		    set args [lrange $args 3 end]
		    if {[llength $args]} {
			eval [list alpha::package [lindex $args 0] $name $version] [lrange $args 1 end]
			return
		    }
		    if {[info exists rebuild_cmd_count] && [incr rebuild_cmd_count -1] == 0} {
			return -code 11
		    }
		}
	    } else {
		cache::readContents index::uninstall
		return $uninstall($name)
	    }
	}
	"forget" {
	    unset -nocomplain index::feature($name)
	}
	"exists" {
	    if {[alpha::_packageGetInfo] != ""} {return 1} else {return 0}
	}
	"type" {
	    if {[alpha::_packageGetInfo] != ""} {return $type} 
	    error "No such package"
	}
	"info" {
	    if {[llength [set info [alpha::_packageGetInfo]]]} {
		return [concat $type $info]
	    }
	    error "No such package"
	}
	"requirements" {
	    set name [lindex $args 0]
	    if {[llength $args] > 2} {
		global alpha::rebuilding 
		if {${alpha::rebuilding}} {
		    set version [lindex $args 1]
		    global rebuild_cmd_count index::$cmd
		    set data [lindex $args 2]
		    set index::${cmd}($name) [list $version $data]
		    set args [lrange $args 3 end]
		    if {[llength $args]} {
			eval [list alpha::package [lindex $args 0] $name $version] [lrange $args 1 end]
			return
		    }
		    if {[info exists rebuild_cmd_count] && [incr rebuild_cmd_count -1] == 0} {
			return -code 11
		    }
		}
	    } else {
		global index::$cmd
		if {[info exists index::${cmd}($name)]} {
		    return [set index::${cmd}($name)]
		} else {
		    return ""
		}
	    }
	}
	"preinit" -
	"maintainer" -
	"disable" -
	"description" -
	"help" {
	    set name [lindex $args 0]
	    if {[llength $args] > 2} {
		global alpha::rebuilding 
		if {${alpha::rebuilding}} {
		    set version [lindex $args 1]
		    global rebuild_cmd_count index::$cmd
		    set data [lindex $args 2]
		    set index::${cmd}($name) [list $version $data]
		    set args [lrange $args 3 end]
		    if {[llength $args]} {
			eval [list alpha::package [lindex $args 0] $name $version] [lrange $args 1 end]
			return
		    }
		    if {[info exists rebuild_cmd_count] && [incr rebuild_cmd_count -1] == 0} {
			return -code 11
		    }
		}
	    } else {
		global index::${cmd} index::loaded
		if {![info exists index::loaded($cmd)]} {
		    # Only load each cache once, otherwise we just waste
		    # a lot of time when repeatedly accessing this
		    # information (e.g. for dialogs).
		    cache::readContents index::$cmd
		    set index::loaded($cmd) 1
		}
		if {[info exists index::${cmd}($name)] \
		  && [llength [set index::${cmd}($name)]]} {
		    return [set index::${cmd}($name)]
		}
		return ""
	    }
	}
	"versions" {
	    set info [alpha::_packageGetInfo]
	    if {[llength $info]} {
		return [lindex $info 0]
	    }
	    error "No such package"
	}
	"vcompare" {
	    set c [eval alpha::_versionCompare $args]
	    if {$c > 0 || $c == -3} {
		return 1
	    } elseif {$c == 0} {
		return 0
	    } else {
		return -1
	    }
	}
	"vsatisfies" {
	    if {[lindex $args 0] eq "-loose"} {
		set c [eval alpha::_versionCompare [lrange $args 1 end]]
		return [expr {$c >= 0 || $c == -3 ? 1 : 0}]
	    } else {
		set c [eval alpha::_versionCompare $args]
		return [expr {$c >= 0 ? 1 : 0}]
	    }
	}
	"names" {
	    set names ""
	    alpha::_packageGetInfo
	    foreach type $which {
		if {[array exists index::${type}]} {
		    eval lappend names [array names index::${type}]
		} elseif {[array exists ${type}]} {
		    eval lappend names [array names ${type}]
		}
	    }
	    return $names
	}
	"mode" -
	"menu" -
	"feature" {
	    eval alpha::$cmd $args
	}
	default {
	    error "Unknown option '$cmd' to 'package'"
	}
    }
}

# Private helper for the above proc
proc alpha::_packageGetInfo {{flags ""}} {
    uplevel [list set flags $flags]
    uplevel {
	set name [lindex $args 0]
	if {[regexp -- {^-([^-].*)} $name "" which]} {
	    if {[lsearch $flags $which] != -1} {
		set $which 1
		set name [lindex $args 1]			
		set args [lrange $args 1 end]			
		return [_packageGetInfo $flags]
	    }
	    if {[lsearch {feature mode} $which] == -1} {
		error "No such flag -$which"
	    }
	    set name [lindex $args 1]
	    set args [lrange $args 1 end]
	} else {
	    set which {feature mode}
	}
	foreach type $which {
	    if {[info exists index::${type}($name)]} {
		return [set index::${type}($name)]
	    }
	    if {$type ne "feature"} {
		cache::readContents index::${type}
		if {[info exists ${type}($name)]} {
		    return [set ${type}($name)]
		}
	    }
	}
	return ""
    }	
}

proc alpha::actionOnFileScript {action file} {
    global HOME
    if {[file::pathStartsWith $file $HOME suffix]} {
	# Need to quote certain Tcl sensitive chars.  This is like
	# 'quote::Insert', but simpler (doesn't handle tabs, newlines).
	regsub -all {[][\\$"\{\}]} $suffix {\\&} suffix
	append action " \[file join \$HOME \"$suffix\"\]"
    } else {
	lappend action $file
    }
    return $action
}

## 
 # -------------------------------------------------------------------------
 # 
 # "alpha::_versionCompare" --
 # 
 #  This proc compares the two version numbers.  It returns:
 #  
 #  0 equal
 #  1 equal but beta/patch update
 #  2 equal but minor update
 #  -1 beta/patch version older
 #  -2 minor version older
 #  -3 major version newer
 #  -5 major version older
 #  
 #  i.e. >= 0 is basically ok, < 0 basically bad
 #  
 #  It works for beta, alpha, dev, fc and patch version numbers.
 #  Any sequence of letters starting b,a,d,f,p are assumed to
 #  represent the particular item.
 #  
 #  2.4 > 1.5 > 1.4.3 > 1.4.3b2 > 1.4.3b1 > 1.4.3a75 > 1.4p1 > 1.4
 # -------------------------------------------------------------------------
 ##
proc alpha::_versionCompare {v1 v2} {
    if {![regexp {[0-9]} $v1]} {
	return -code error "Bad version number \"$v1\""
    }
    if {![regexp {[0-9]} $v2]} {
	return -code error "Bad version number \"$v2\""
    }
    regsub -all -nocase {([a-z])[a-z]+} $v1 {\1} v1
    regsub -all -nocase {([a-z])[a-z]+} $v2 {\1} v2
    set v1 [split $v1 .p]
    set v2 [split $v2 .p]
    set i -1
    set ret 0
    set mult 2
    while 1 {
	incr i
	set sv1 [lindex $v1 0]
	set sv2 [lindex $v2 0]
	if {$sv1 eq "" && $sv2 eq ""} { break }
	if {$sv1 eq ""} { 
	    set v1 [concat 8 0 $v1]
	    set v2 [concat 9 $v2]
	    continue
	} elseif {$sv2 eq ""} { 
	    set v1 [concat 9 $v1]
	    set v2 [concat 8 0 $v2]
	    continue
	} elseif {[regexp -nocase {[a-z]} "$sv1$sv2"]} {
	    # beta versions
	    foreach v {sv1 sv2} {
		if {[regexp -nocase {[a-z]} [set $v]]} {
		    # f = 8, b = 7, a = 6, d = 5
		    regsub -nocase {([^a-z])f} [set $v] {\1 7 } $v
		    regsub -nocase {([^a-z])b} [set $v] {\1 6 } $v
		    regsub -nocase {([^a-z])a} [set $v] {\1 5 } $v
		    regsub -nocase {([^a-z])d} [set $v] {\1 4 } $v
		} else {
		    # release version = 8, so it is larger than any of the above
		    append $v " 8"
		}
	    }
	    set v1 [eval lreplace [list $v1] 0 0 $sv1]
	    set v2 [eval lreplace [list $v2] 0 0 $sv2]
	    set mult 1
	    continue
	}
	if {$sv1 < $sv2} { set ret -1 ; break }
	if {$sv1 > $sv2} { set ret 1 ; break }
	set v1 [lrange $v1 1 end]
	set v2 [lrange $v2 1 end]
    }
    if {$i == 0} {
	# major version, return 0, -3, -5
	return [expr {$ret * (-4*$ret + 1)}]
    } else {
	return [expr {$mult *$ret}]
    }
}

# ×××× Declare Alpha packages ×××× #

# This procedure is not yet final.  Please do not rely on its API for
# use outside of Alpha's core.  Changes may be made to streamline Alpha's
# package initialisation and declaration process.
proc alpha::declare {what name version modes {initialise ""}\
  {activate ""} {deactivate ""} {off ""} args} {
    global alpha::rebuilding unknown_pending
    if {!${alpha::rebuilding} || [info exists unknown_pending]} {return}
    global index::feature rebuild_cmd_count index::flags
    if {[string trim "$initialise$activate$deactivate$off"] eq ""} {
	# This code path is reached for alpha::library declarations,
	# and any 'auto-loading features' (which are defined as
	# features which don't have any init scripts).
	set index::feature($name) [list $version $modes -1]
    } else {
	switch -- $what {
	    "feature" {
		set init 0
	    }
	    "menu" {
		set init 1
	    }
	    "flag" {
		set init 2
		lappend index::flags $name
	    }
	    default {
		error "Bad alpha::declare type '$what'"
	    }
	}
	set index::feature($name) [list $version $modes $init $initialise \
	  $activate $deactivate $off]
    }
    if {[llength $args]} {
	eval [list alpha::package [lindex $args 0] $name $version] [lrange $args 1 end]
	return
    }
    if {[info exists rebuild_cmd_count] && [incr rebuild_cmd_count -1] == 0} {
	return -code 11
    }
}

proc alpha::feature {name version modes {initialise ""} \
  {activate ""} {deactivate ""} args} {
    uplevel 1 [list alpha::declare feature $name $version $modes \
      $initialise $activate $deactivate ""] $args
}

proc alpha::flag {name version prefsPage modes args} {
    if {[string length $prefsPage]} {
	set init "set $name 0 ; lappend flagPrefs($prefsPage) $name"
    } else {
	set init "set $name 0"
    }
    uplevel 1 [list alpha::declare flag $name $version $modes \
      $init "set $name 1" "set $name 0" ""] $args
}

proc alpha::extension {name version {script ""} args} {
    uplevel 1 [list alpha::declare feature $name $version "global-only" "" $script "" ""] $args
}

proc alpha::library {name version {script ""} args} {
    uplevel 1 [list alpha::declare library $name $version "always-on" "" "" "" "" preinit $script] $args
}

proc alpha::menu {name version modes {value ""} {initialise ""} {activate ""} {deactivate ""} args} {
    global alpha::rebuilding
    if {!${alpha::rebuilding}} {
	# This is required when autoloading some procs without activating
	# a menu
	global $name
	if {![info exists $name]} { set $name $value }
	return
    }
    if {[regexp {^¥} [string index $modes 0]]} {
	# it's in the old format
	set tmp $modes
	set modes $value
	if {$modes eq "in_menu"} { set modes "global" }
	set value $tmp
	# perhaps there's a better way of collapsing these arguments
	if {[llength $args]} {
	    set args [linsert $args 0 $activate $deactivate]
	} else {
	    if {$deactivate != ""} {
		lappend activate $deactivate
		set args $activate
	    } else {
		set args $activate
	    }
	}	
	set activate "$name"
	set deactivate ""
    }
    uplevel 1 [list alpha::declare menu $name $version $modes \
      "ensureset $name $value\n$initialise" $activate $deactivate ""] $args
}

proc alpha::mode {names version oneTimeScript {ext ""} {featureList ""} {script ""} args} {
    global alpha::rebuilding alpha::guiNotReady index::mode index::oldmode \
      pkg_file rebuild_cmd_count mode::features mode::interfaceNames
    
    if {!${alpha::rebuilding}} {
	return
    }
    # Determine the User Interface name for this mode.
    set name [lindex $names 0]
    if {([llength $names] > 1)} {
	set mode::interfaceNames($name) [lindex $names 1]
	prefs::modified mode::interfaceNames
    }
    # Store the remaining information.
    ;namespace eval ::$name {}
    if {$oneTimeScript eq "source"} {
	# We could use 'info script' instead of pkg_file, except
	# for encoding purposes we might not be using 'source' to source files.
	set oneTimeScript [alpha::actionOnFileScript source $pkg_file]
    }
    # We need to convert the 'list' $ext into a real list in which 
    # there are no newline, etc characters.
    set exts [list]
    foreach e $ext {
	lappend exts $e
    }
    if {[info exists index::mode($name)]} {
	dialog::alert "You have a duplicate definition of $name mode,\
	  possibly in the file [info script].  This is likely to lead\
	  to problems, in which this new definition partially or completely\
	  overrides the original.  You should remove one of the definitions."
    }
    set index::mode($name) [list $version $oneTimeScript $exts $featureList $script]
    if {[info exists index::oldmode($name)]} {
	# We have to take special action if the set of features for 
	# this mode differs between what we're seeing now and what
	# we've got stored.  In particular, the user may have edited
	# something!
	if {[set old_features [lindex [set index::oldmode($name)] 3]] ne $featureList} {
	    if {![info exists mode::features($name)]} {set mode::features($name) ""}
	    foreach mm $featureList {
		# Store all version number requirements
		if {[lsearch -exact $old_features $mm] == -1} {
		    # it's new
		    if {[string index $mm 0] ne "-"} {
			package::addRelevantMode $mm $name
		    }
		    if {[info exists alpha::guiNotReady]} {
			# we added a feature 
			hook::register startupHook "lunion mode::features($name) $mm"
		    } else {
			lunion mode::features($name) $mm
			prefs::modified mode::features($name)
		    }
		}
	    }
	    foreach omm $old_features {
		if {[lsearch -exact $featureList $omm] == -1} {
		    # it has been removed from the default list
		    package::removeRelevantMode $omm $name
		    set mode::features($name) [lremove [set mode::features($name)] $omm]
		    prefs::modified mode::features($name)
		}
	    }
	}
    }
    if {[llength $args]} {
	eval [list alpha::package [lindex $args 0] $name $version] [lrange $args 1 end]
	return
    }
    if {[info exists rebuild_cmd_count] && [incr rebuild_cmd_count -1] == 0} {
	return -code 11
    }		
}

## 
 # -------------------------------------------------------------------------
 # 
 # "alpha::minormode" --
 # 
 #  Declare a minormode with a given set of attributes.  A minormode can
 #  specify or adjust a window's attributes in five aspects: bindtags
 #  colortags hookmodes featuremodes varmodes
 #  
 #  alpha::minormode $name ?(+aspect|-aspect|aspect) value?+
 #  
 #  Use '+' to extend, '-' to remove and nothing to set.  For example:
 #  
 #  alpha::minormode tclshell +bindtags TclShell -hookmodes Tcl varmodes TeX
 #  
 #  IMPORTANT: Experimental (Feb 2004) and definitely NOT supported.
 #  Syntax will change!!
 #  
 #  Currently each 'value' is a _single_ value for the given aspect.  
 #  If you want to specify a list of such values, you must add them one 
 #  by one:
 #   
 #    ... featuremodes one +featuremodes two +featuremodes three
 #    
 #  will set the featuremodes to 'one two three'.  This may change in
 #  the future.  This procedure's design is not yet fixed.
 #  
 # -------------------------------------------------------------------------
 ##
proc alpha::minormode {name args} {
    set aspects {bindtags colortags hookmodes featuremodes varmodes}
    global index::minormode
    set index::minormode($name) ""
    foreach {opt val} $args {
	if {[string index $opt 0] eq "+"} {
	    set add 1
	    set opname [string range $opt 1 end]
	} elseif {[string index $opt 0] eq "-"} {
	    set add -1
	    set opname [string range $opt 1 end]
	} else {
	    set add 0
	    set opname $opt
	}
	if {[lsearch -exact $aspects $opname] == -1} {
	    return -code error "Bad option $opt, should be +/- followed by one\
	      of [join $aspects {, }]"
	}
	lappend index::minormode($name) $add $opname $val 
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alpha::internalModes" --
 # 
 # Register modes as "internal," i.e. not intended for text editing.  Any
 # "args" arguments are added to the list, and the sorted list is returned.
 # 
 # Usage:
 # 
 #     % alpha::internalModes "TeXC" "TeX Console"
 #     Browser Brws dtd InSh Inst Install MPW test {TeX Console} TeXC WWW xsl
 # 
 # Used by "statusPopMenus.tcl" and [mode::listAll] to determine which modes
 # are not intended for text editing.
 # 
 # --------------------------------------------------------------------------
 ##

proc alpha::internalModes {args} {
    
    variable internalModes
    
    set internalModes [eval [list lappend internalModes] $args]
    return [lsort -dictionary -unique $internalModes]
}