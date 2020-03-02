## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 #
 # FILE: "windows.tcl"
 #                                          created: 05/24/1999 {06:29:14 PM}
 #                                      last update: 03/21/2006 {12:56:53 PM}
 # Description:
 # 
 # Procedures that deal specifically with windows that have already been 
 # created by the core.
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 # 
 # Copyright (c) 1999-2006  Vince Darley
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

proc windows.tcl {} {}

#¥ closeAll - close all windows
proc closeAll {} {
    foreach w [winNames -f] {
	killWindow -w $w
    }
}

namespace eval win {}

# These variables are private to this file.
set win::_creationOrder {}

# Very important helper command for anything which takes an optional '-w
# win' argument.  Takes as arguments the name of the variable in which
# to put the window name (or win::current if none is given) followed by
# any number of arguments representing variable names to be populated
# with values given by the caller.  If not enough arguments are given
# (or too many) a nice error message will be thrown.  It is also
# possible to end the list of variable names with 'args' which will
# collect all remaining values given, or to supply default arguments as
# with standard Tcl procedure argument lists.
proc win::parseArgs {ww args} {
    upvar 1 args valuesArgs
    upvar 1 $ww w
    if {([llength $valuesArgs] > 1) && ([lindex $valuesArgs 0] eq "-w")} {
	# First argument is '-w', but we must now check if there
	# are enough extra arguments to allow for the first two
	# to be interpreted as '-w win'.  If there aren't enough,
	# we treat '-w' as a literal argument.
	set count [llength $valuesArgs]
	foreach var $args {
	    if {$var eq "args"} {
		set count 2
		break
	    } elseif {[llength $var] == 2} {
		break
	    } else {
		incr count -1
	    }
	}
	if {$count > 1} {
	    set w [lindex $valuesArgs 1]
	    set valuesArgs [lrange $valuesArgs 2 end]
	} else {
	    # Not enough arguments, probably '-w' is not a window
	    # specified, but rather an actual argument.
	    set w [win::Current]
	}
    } else {
	set w [win::Current]
    }

    set len [llength $args]
    incr len -1
    for {set i 0} {$i <= $len} {incr i} {
	set var [lindex $args $i]
	if {($i == $len) && ($var eq "args")} {
	    uplevel 1 [list set args [lrange $valuesArgs $i end]]
	    set i [llength $valuesArgs]
	    break
	} else {
	    switch -- [llength $var] {
		0 - 1 {
		    if {$i < [llength $valuesArgs]} {
			uplevel 1 [list set $var [lindex $valuesArgs $i]]
		    } else {
			return -code error "Wrong number arguments, should be:\
			  [lindex [info level -1] 0] ?-w window? $args"
		    }
		}
		2 {
		    set default [lindex $var 1]
		    set var [lindex $var 0]
		    if {$i < [llength $valuesArgs]} {
			uplevel 1 [list set $var [lindex $valuesArgs $i]]
		    } else {
			uplevel 1 [list set $var $default]
		    }
		}
		default {
		    return -code error "Bad argument list \"$var\""
		}
	    }
	}
    }
    if {$i < [llength $valuesArgs]} {
	# Too many arguments
	return -code error "Too many arguments, should be:\
	  [lindex [info level -1] 0] ?-w window? $args"
    }
}

# ×××× Basic window creation, destruction ×××× #

# AlphaTcl Window API
# 
# When windows are created, renamed, or destroyed, various of the hooks
# defined in the "Extending Alpha" document are called (winCreatedHook,
# etc).  These make use of the AlphaTcl Window API to keep track of
# window names, attributes, as follows:
# 
# 	win::created <name> - a window with this name has been created
# 	win::destroyed <name> - a window with this name has been destroyed
# 	win::nameChanged <oldname> <newname> - a window has been renamed
# 
# These three procedures may then be used by any AlphaTcl package to 
# query information about the current windows:
# 
# 	win::Exists <name>  -  does a window with this name exist?
# 	win::CreationOrder - return list of window names, ordered by creation
# 	win::StackOrder - return list of window names, ordered frontmost 
# 	                  to backmost
# 
# Any AlphaTcl variables (such as $win::attr(), $win::_creationOrder)
# should be considered private to AlphaTcl's core and only accessed
# through the above functions.

proc win::created {window} {
    variable _creationOrder
    variable attr
    
    lappend _creationOrder $window
    set attr($window) [dict create]
}

proc win::removeFromList {window} {
    variable _creationOrder
    
    if {[set ind [lsearch -exact $_creationOrder $window]] >= 0} {
	set _creationOrder [lreplace $_creationOrder $ind $ind]
    } else {
	# This is really a bug
	alertnote "Can't find the old window in creation list!\
	  Bad error in win::destroyed for \"$window\"."
    }
}

# Core attributes are freed by the core during killWindow.
# Free up AlphaTcl repository.
proc win::destroyed {window} {
    variable attr
    
    # Window being closed.  Remove all attributes.
    unset -nocomplain attr($window)
}

proc win::Exists {window} {
    variable attr
    info exists attr($window)
}

# Not for external use.  Use by AlphaTclCore only.  
# (winChangeNameHook uses it)
proc win::nameChanged {wfrom wto} {
    variable _creationOrder
    variable attr
    
    set idx [lsearch -exact $_creationOrder $wfrom]
    if {$idx >= 0} {
	lset _creationOrder $idx $wto
    } else {
	alertnote "Core bug: unknown window \"$wfrom\" when changing window name."
    }

    # Even if a window has no attributes, this array entry should exist.
    if {![info exists attr($wfrom)]} {
	alertnote "Unknown window name \"$wfrom\" when changing window name."
	return
    }
    if {$wto ne $wfrom} {
	set attr($wto) $attr($wfrom)
	unset attr($wfrom)
    }
}

proc win::CreationOrder {} {
    variable _creationOrder
    return $_creationOrder
}

# This is defined to be the same as [winNames -f] now.
proc win::StackOrder {} {
    return [winNames -f]
}

# ×××× Window attributes ×××× #

# These procs are now a critical, central part of AlphaTcl and its
# handling of windows and modes.  They still need documenting
# effectively.

set readScript {getWinInfo -w $window arr ; return $arr($field)}
set writeScript {setWinInfo -w $window $field $value ; continue}

set win::coreAttributeScript(currline) [list $readScript $writeScript]
set win::coreAttributeScript(linesdisp) [list $readScript $writeScript]
set win::coreAttributeScript(split) [list $readScript $writeScript]
set win::coreAttributeScript(state) [list $readScript $writeScript]
set win::coreAttributeScript(font) [list $readScript $writeScript]
set win::coreAttributeScript(fontsize) [list $readScript $writeScript]
set win::coreAttributeScript(platform) [list $readScript $writeScript]
set win::coreAttributeScript(read-only) [list $readScript $writeScript]
set win::coreAttributeScript(tabsize) [list $readScript $writeScript]
set win::coreAttributeScript(dirty) [list $readScript $writeScript]
set win::coreAttributeScript(shell) [list $readScript $writeScript]

# Currently experimental - ability to specify a script which will
# be used to verify arguments to win::setInitialConfig (using the
# desirable principle of throwing errors as early as possible).
set win::attributeScript(minormode) {
    if {![info exists ::index::minormode($value)]} {
	error "Unknown minormode '$value'"
    }
}

if {$alpha::platform eq "tk"} {
    # Alphatk adds the following:
    # 
    # - encoding support, which the core needs to know how to save
    # and/or edit a file.
    # - linenumbers/horscrollbar on a window by window basis
    # - wrap (needed only for Alphatk's true soft wrapping)
    # 
    set win::coreAttributeScript(encoding) [list $readScript $writeScript]
    set win::coreAttributeScript(linenumbers) [list $readScript $writeScript]
    set win::coreAttributeScript(horscrollbar) [list $readScript $writeScript]
    # Alphatk needs special handling of the 'linewrap' attribute, since it
    # is effectively stored in AlphaTcl, but certain values of it need
    # to propagate to Alphatk.
    set win::coreAttributeScript(linewrap) [list {# nothing} \
      {
	setWinInfo -w $window "wrap" [lindex {none none char word} $value]
	# Continue to AlphaTcl setting
    }]
}

# Alphatk (and soon Alpha 8/X) add the following:
# 
# - colortags (needed for colouring)
# - bindtags (needed for bindings)
# - wordbreak (needed for colouring and forward/backward word)
# 
# Notice that Alphatk's core doesn't look at the global variables
# 'mode' and 'wordBreak' since there is no requirement that a
# particular action is operating on the frontmost window, and
# therefore those variables might refer to the wrong mode!
set win::coreAttributeScript(bindtags) [list $readScript $writeScript]
set win::coreAttributeScript(colortags) [list $readScript $writeScript]
set win::coreAttributeScript(wordbreak) [list $readScript $writeScript]

unset readScript writeScript

# Currently we are nice and return a mode of "" if there are no open
# windows, rather than throwing an error.  However, one could argue that
# it is better that no win::* procs are used to query window status at
# all if there are no windows, so we might wish to reassess this choice
# in the future.
proc win::getMode {{window  ""} {userInterfaceName "0"}} {
    
    if {($window eq "") && ([set window [win::Current]] eq "")} {
	return ""
    } else {
	return [mode::getName [win::getInfo $window mode] $userInterfaceName]
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "win::getInfo" --
 # 
 #  Return core or alphatcl attribute of a window, for the given field.
 #  Will throw an error if the attribute doesn't exist.
 #  -------------------------------------------------------------------------
 ##
proc win::getInfo {window field args} {
    variable coreAttributeScript
    if {[info exists coreAttributeScript($field)]} {
	eval [lindex $coreAttributeScript($field) 0] $args
    }
    # Get from AlphaTcl repository of information
    variable attr
    eval [list dict get $attr($window) $field] $args
}

## 
 # -------------------------------------------------------------------------
 # 
 # "win::setInfo" --
 # 
 #  Sets core or alphatcl attribute(s) of a window with the given field
 #  name to the given value.  May throw an error if the value is
 #  illegal for that field.  If it does throw an error, attributes
 #  which have been successfully set up to that point will retain
 #  their new values.
 # -------------------------------------------------------------------------
 ##
proc win::setInfo {window args} {
    if {[llength $args] % 2} {
	error "Wrong # args: should be \"win::setInfo window ?field value?...\""
    }
    foreach {field value} $args {
	variable coreAttributeScript
	if {[info exists coreAttributeScript($field)]} {
	    # The line may executed 'continue' to go to the next loop
	    # iteration (if it doesn't want the value stored in the
	    # 'attr' dictionary).
	    eval [lindex $coreAttributeScript($field) 1]
	}
	# Store in AlphaTcl repository of information
	variable attr
	dict set attr($window) $field $value
    }
}

proc win::setNestedInfo {window args} {
    # Store in AlphaTcl repository of information
    variable attr
    eval [list dict set attr($window)] $args
}

## 
 # -------------------------------------------------------------------------
 # 
 # "win::freeInfo" --
 # 
 #  AlphaTcl will automatically free everything when the window closes,
 #  so only call this if you specifically want to delete certain
 #  fields.
 # -------------------------------------------------------------------------
 ##
proc win::freeInfo {window args} {
    variable attr
    foreach field $args {
	dict unset attr($window) $field
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "win::adjustInfo" --
 # 
 #  Allow caller to execute an arbitrary script which operates on the
 #  value of a given window attribute field as if it were a variable
 #  in the caller's scope, for example:
 #  
 #     win::adjustInfo [win::Current] hookmodes {lappend hookmodes foo}
 #  
 #  You can also use 'unset' to remove this attribute field, although
 #  that is not really a good idea for any core attribute.
 #  -------------------------------------------------------------------------
 ##
proc win::adjustInfo {window field script} {
    uplevel 1 [list dict update ::win::attr($window) $field $field $script]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "win::infoExists" --
 # 
 #  Returns 1 if the given attribute field exists, 0 otherwise.
 # -------------------------------------------------------------------------
 ##
proc win::infoExists {window field} {
    variable coreAttributeScript
    if {[info exists coreAttributeScript($field)]} {
	# Core attributes always exist
	return 1
    } else {
	# Does this exist in AlphaTcl repository
	variable attr
	if {[info exists attr($window)]} {
	    return [dict exists $attr($window) $field]
	} else {
	    return 0
	}
    }
}

proc win::setInitialConfig {winname option value {priority ""}} {
    variable attributeScript
    set p [lsearch -exact {global mode fileset window command} $priority]
    #puts stderr [list $winname $option $value $p]
    if {$p != -1} {
	if {[info exists attributeScript($option)]} {
	    eval $attributeScript($option)
	}
	lappend ::win::config($winname) $option $value $p
	if {$option eq "mode"} {
	    # We need to _load_ the mode now (not 'changeMode'), but simply
	    # load it all in, to get access to the <mode>modeVars. This
	    # is assumed elsewhere, e.g. win::_calculateConfig.
	    loadAMode $value
	    if {![mode::exists $value]} {
		return -code error "Unknown mode \"$value\" in \"[info level 0]\""
	    }
	}
    } else {
	return -code error "Unknown priority \"$priority\" to\
	  win::setInitialConfig"
    }
}

namespace eval win {
    variable coreModeVars
    set coreModeVars(tabsize)      tabSize
    set coreModeVars(fontsize)     fontSize
    set coreModeVars(wordbreak)    wordBreak
    set coreModeVars(linewrap)     lineWrap
    set coreModeVars(font)         defaultFont
    if {$::alpha::platform eq "tk"} {
	# These fields aren't supported in Alpha 8/X
	set coreModeVars(horscrollbar) horScrollBar
	set coreModeVars(linenumbers)  lineNumbers
    }
}

# Unsupported at present.  Use by AlphaTclCore only.
proc win::_calculateConfig {winname {option *}} {
    variable config
    variable coreModeVars
    
    set vals [dict create]
    
    if {[info exists config($winname)]} {
	# Find the highest priority pre-registered value.
	foreach {opt val priority} $config($winname) {
	    if {[info exists priors($opt)] && ($priors($opt) > $priority)} {
		continue
	    }
	    set priors($opt) $priority
	    dict set vals $opt $val
	}
    }
    if {$option ne "mode"} {
	# If we're not asking for the mode, we must update the mode
	# as best possible, and load up mode-specific attributes
	# in case they over-ride what we're looking for.
	if {![dict exists $vals mode] || [dict get $vals mode] eq ""} {
	    dict set vals mode [win::FindMode $winname]
	    # Store it so we don't do this next time.
	    win::setInitialConfig $winname mode [dict get $vals mode] "global"
	}
	set m [dict get $vals mode]
	
	# Set initial values for the 5 main attributes
	
	# This variable is a prioritised list, and might already have
	# some elements, so we add to the end, since we want any other
	# state to take precedence over the mode.
	dict lappend vals bindtags $m
	# This is a list, but the primary 'mode' must come first, since
	# it is the only one which is allowed to define comments and
	# things like that.
	if {[dict exists $vals colortags]} {
	    dict set vals colortags [linsert [dict get $vals colortags] 0 $m]
	} else {
	    dict lappend vals colortags $m
	}
	dict lappend vals hookmodes $m
	dict lappend vals varmodes $m
	dict lappend vals featuremodes $m

	# Implement (mode,minormode) by adding any minormode information.
	# This block of code is not currently stable (Dec 2004),
	# and will change.  One option is not to have minor-modes at all
	# and just have direct manipulation of the various attributes.
	if {[dict exists $vals minormode]} {
	    set vals [alpha::_applyMinorMode $vals [dict get $vals minormode]]
	    dict unset vals minormode
	}

	# We know that 'win::setInitialConfig' will have called
	# loadAMode.
	foreach lower [array names coreModeVars] {
	    set var $coreModeVars($lower)
	    # If there's no entry, or one of only global priority, then
	    # over-ride with a mode-specific value here
	    if {![info exists priors($lower)] || $priors($lower) == 0} {
		set vinfo [mode::getVarInfo $var [dict get $vals varmodes]]
		if {[lindex $vinfo 0] eq "mode" || ![info exists priors($lower)]} {
		    dict set vals $lower [lindex $vinfo 1]
		}
	    }
	}
	# We don't want to associate any encoding if there isn't
	# one (so we ignore the global variable 'defaultEncoding').
	if {![info exists priors(encoding)] || $priors(encoding) == 0} {
	    set vinfo [mode::getVarInfo defaultEncoding [dict get $vals varmodes]]
	    if {[lindex $vinfo 0] eq "mode"} {
		dict set vals encoding [lindex $vinfo 1]
	    }
	}
    }
    return $vals
}

proc win::getInitialConfig {winname option} {
    set ret [_calculateConfig $winname $option]
    if {[dict exists $ret $option]} {
	return [dict get $ret $option]
    } else {
	return ""
    }
}

proc win::getAndReleaseInitialInfo {winname} {
    variable config
    
    set ret [_calculateConfig $winname]
    unset -nocomplain config($winname)
    return $ret
}

proc win::getHookModes {winname} {
    if {[infoExists $winname hookmodes]} {
	return [getInfo $winname hookmodes]
    } else {
        return ""
    }
}

proc win::getFeatureModes {winname} {
    if {[infoExists $winname featuremodes]} {
	return [getInfo $winname featuremodes]
    } else {
	return ""
    }
}

# Return any additional tags associated with this window's behaviour
# aspects (hooks, variables, colouring, binding, features), in no
# particular order.
proc win::getStates {winname} {
    foreach aspect {hookmodes bindtags colortags varmodes featuremodes} {
	if {[infoExists $winname $aspect]} {
	    foreach s [getInfo $winname $aspect] {
		set aspects($s) 1
	    }
	}
    }
    unset -nocomplain aspects([getMode $winname])
    return [array names aspects]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "win::getModeVar" --
 # 
 #  This function gets a (possibly hooked) mode-variable associated with a
 #  given window.  It knows about both <mode>modeVars and <mode>::
 #  (Although we should probably fix on just one of these two in the
 #  future).  For example, if we want to know what 'indentationAmount' 
 #  is associated with the mode/minormode information (strictly 
 #  speaking the 'varmodes' attribute) of a window $win, we can just 
 #  ask:
 #    
 #    win::getModeVar $win indentationAmount
 #    
 #  and AlphaTcl will look through each of the varmodes associated with
 #  the window, and failing that, also a global variable of the given
 #  name, and failing that it will throw an error unless a default
 #  value is given as a third argument.
 #  
 #  If the variable doesn't exist in any varmodes and neither at the 
 #  global level, and the default argument is given, then that is
 #  returned, and otherwise an error will be thrown.
 #  
 #  We allow this to be called even if there are no windows (e.g. an 
 #  empty [win::Current]) in which just the global variables will
 #  be queried.
 #  
 #  NOTE: Just to be clear, you can't use this proc to get the 'mode'
 #  of the given window.  You must use 'win::getMode' for that.  In
 #  AlphaTcl 8.1, the $mode of a window is potentially disconnected from
 #  the set of variables associated with that window (defined by 
 #  varmodes).
 # -------------------------------------------------------------------------
 ##
proc win::getModeVar {winname var {default ""}} {
    if {$winname ne ""} {
	set varmodes [getInfo $winname varmodes]
    } else {
        set varmodes {}
    }
    set varInfo [mode::getVarInfo $var $varmodes]
    
    if {[llength $varInfo]} {
	return [lindex $varInfo 1]
    } else {
	if {[llength [info level 0]] == 4} {
	    return $default
	} else {
	    # We will, by design, throw an error if this doesn't exist.
	    return -code error "No such variable \"$var\""
	}
    }
}

# ×××× Miscellaneous window procs ×××× #

proc win::showInFinder {{winName {}}} {
    if {$winName eq ""} { set winName [win::Current] }
    if {[win::IsFile $winName fileName]} {
	file::showInFinder $fileName
    } else {
	status::msg "ERROR: FILE NOT FOUND: \"$winName\""
    }
}

# Similar to 'file::openQuietly' but will deal with
# windows which don't exist on disk.
proc win::OpenQuietly {name} {
    if {[catch {edit -c -w $name}]} {
	bringToFront $name
    }
    if {[icon -q]} {icon -o}
}

# Take a string and turn it into an acceptable window
# title.  This may involve removing illegal characters
# or shortening the string
if {${alpha::platform} == "alpha"} {
    proc win::MakeTitle {str} {
	if {[string length $str] > 31} {
	    set str "[string range $str 0 30]É"
	}
	return $str
    }
} else {
    # Alphatk is happy with much longer titles
    # (so may Alpha 8, actually, but we haven't changed that).
    proc win::MakeTitle {str} {
	if {[string length $str] > 51} {
	    set str "[string range $str 0 50]É"
	}
	return $str
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "win::IsFile" --
 # 
 # Checks if the given window name is a file, returning 1 or 0 as 
 # appropriate.
 # 
 # 'fileNameVar' is optional.  If given, and if the window is a file,
 # then it will the variable of that name in the caller's scope will be
 # set to the name of the file (i.e. minus any ' <n>' extras).  If the
 # window is not a file, fileNameVar is ignored.
 # 
 # -------------------------------------------------------------------------
 ##
proc win::IsFile {name {fileNameVar ""}} {
    if {[file isfile $name] \
      || ([regsub { <[0-9]+>$} $name {} name] && [file isfile $name])} {
	if {$fileNameVar ne ""} {
	    upvar 1 $fileNameVar local
	    set local $name
	}
	return 1
    }
    return 0
}

# This proc should perhaps replace [winDirty], in the long run:
proc win::isDirty {{win ""}} {
    if {($win eq "")} {
	set win [win::Current]
    }
    return [win::getInfo $win dirty]
}

proc win::CurrentTail {} {
    set cur [Current]
    if {[win::IsFile $cur]} {
	return [file tail $cur]
    } else {
	return $cur
    }
}
proc win::Tail {{w ""}} {
    if {$w eq ""} {set w [win::Current]}
    if {![win::IsFile $w]} {
	return $w
    } else {
	return [file tail $w]
    }
}
proc win::TopNonProcessWindow {} {
    foreach f [winNames -f] {
	if {![regexp {^\* .* \*( <[0-9]+>)?$} $f]} {
	    return $f
	}
    }
    return ""
}
proc win::TopFileWindow {} {
    foreach f [winNames -f] {
	if {[file exists [win::StripCount $f]]} {
	    return $f
	}
    }
    return ""
}

proc win::StripCount {name} {
    regsub { <\d+>$} $name {} name
    return $name
}

# Documented behaviour:
# 
# If there are no windows, return 0, else if the given (or current if
# none given) window is editable return 1, else beep and leave a
# message in the status bar saying that the window is read only.
proc win::checkIfWinToEdit {{w ""}} {
    if {![llength [winNames]]} {
	return 0
    }
    if {![string length $w]} {
        set w [win::Current]
    } 
    if {[win::getInfo $w read-only]} {
	beep
	status::msg "Read-only!"
	return 0
    } else {
	return 1
    }
}

# Find the count string required for a window with the given
# name.  We must compare both against the full names and
# against the tails.
proc win::CountFor {name {excludeCurrent 0}} {
    if {$excludeCurrent} {
	set names [lrange [winNames] 1 end]
	set fullNames [lrange [winNames -f] 1 end]
    } else {
	set names [winNames]
	set fullNames [winNames -f]
    }
    
    if {([lsearch -exact $names [file tail $name]] != -1) \
      || ([lsearch -exact $fullNames $name] != -1)} {
	set num 2
	while {([lsearch -exact $names "[file tail $name] <$num>"] != -1) \
	  || ([lsearch -exact $fullNames "$name <$num>"] != -1)} { 
	    incr num 
	}
	return " <$num>"
    }
    return ""
}

proc win::modeFromContents {name} {
    set pos [minPos -w $name]
    set line [getText -w $name $pos [pos::lineEnd -w $name $pos]]
    
    set modeList [mode::listAll]

    # Check for '(mode:<mode>)' in the first line
    if {[regexp -- {\(mode:([^\)]+)\)} $line -> m]} {
	if {[lsearch -exact $modeList $m] != -1} {
	    return $m
	}
    }

    # If not, then scan for the unix-line #!bin/sh stuff
    set nextLineGetter [format {
	if {![info exists pos]} { set pos "%s" }
	set next [pos::nextLineStart -w "%s" $pos]
	if {[pos::compare -w "%s" $next == $pos]} {
	    break
	}
	set line [getText -w "%s" $pos $next]
	set pos $next
	set line
    } $pos [quote::Insert $name] [quote::Insert $name] [quote::Insert $name]]

    set majorMode [mode::getFromUnixFirstLine $line $nextLineGetter]
    if {$majorMode eq ""} {
	return
    }
    
    global unixMode

    if {[info exists unixMode($majorMode)]} {
	return $unixMode($majorMode)
    } else {
	if {[set i [lsearch -exact [string tolower $modeList] $majorMode]] != -1} {
	    return [lindex $modeList $i]
	}
    }
    return
}

# Procedure to change the mode associated with the current
# window.
proc win::ChangeMode {newMode} {
    if {[catch {win::Current} name]} return
    winChangeMode $name $newMode
}

## 
 # -------------------------------------------------------------------------
 # 
 # "win::FindMode" --
 # 
 #  Copes with trailing '<2>', .orig, copy, '~',...
 # -------------------------------------------------------------------------
 ##
proc win::FindMode {name} {
    ::mode::findForWindow $name
}

# ¥ win::Encoding ?win?  ?encoding?  - Will be used by Alpha 8, and is
# shared with Alphatk.  If this is broken or modified, Alphatk will
# cease to work.
proc win::Encoding {args} {
    if {$::alpha::platform ne "tk"} { return "macRoman" }
    
    switch -- [llength $args] {
	0 {
	    return [win::getInfo [win::Current] encoding]
	}
	1 - 
	2 {
	    set n [lindex $args 0]
	    set oldenc [win::getInfo $n encoding]
	    if {[llength $args] > 1} {
		set enc [lindex $args 1]
		if {($oldenc ne $enc)} {
		    setWinInfo -w $n encoding $enc
		    # Only adjust global encoding and display if its
		    # the frontmost window
		    if {$n eq [win::Current]} {
			global encoding
			displayEncoding [set encoding $enc]
		    }
		    if {[win::getInfo $n dirty] || ($oldenc == "") \
		      || ![win::IsFile $n]} {
			status::msg "'$enc' encoding now associated\
			  with this window."
		    } else {
			if {[dialog::yesno "Reread from disk?"]} {
			    ::revert -w $n
			    status::msg "Synchronised with version on disk;\
			      using new $enc encoding."
			} else {
			    status::msg "'$enc' encoding now associated with\
			      this window."
			}
		    }
		}
		return $enc
	    } else {
		return $oldenc
	    }
	}
	default {
	    error "Wrong number of arguments"
	}
    }
}

# The syntax of this function differs to the other win:: function, perhaps
# it should be renamed or modified.  
proc win::cursorInWindow {args} {
    win::parseArgs w {pos ""}
    if {![string length $pos]} {set pos [getPos -w $w]}
    getWinInfo -w $w winArray
    set top   $winArray(currline)
    set lines $winArray(linesdisp)
    # This is the top line of the window.
    set pos0  [pos::fromRowCol -w $w $top 0]
    # This is the last position in the bottom visible line of the window.
    set pos1  [pos::lineEnd -w $w \
      [pos::fromRowCol -w $w [expr {$top + $lines - 1}] 0]]
    # Find out if the cursor is somewhere in the window.
    set test0 [pos::compare -w $w $pos < $pos0]
    set test1 [pos::compare -w $w $pos >= [pos::nextLineStart -w $w $pos1]]
    set isIn  [expr {$test0 || $test1} ? 0 : 1]
    return    [list $isIn $pos0 $pos1]
}

## 
 # ----------------------------------------------------------------------
 #	 
 #  "win::searchAndHyperise" --
 #	
 #  Scans through an entire file for a particular string or regexp, and
 #  attaches a hyperlink of the specified form (regsub'ed if desired)
 #  to the original string.
 #			
 #	Side effects:
 #	 Many hyperlinks will be embedded in your file
 #	
 #	Arguments:
 #	 Look for 'text', replace with 'link', doing both with a regexp
 #	 if signified (regexp = 1), using colour 'col', and offsetting
 #	 the link start and end by 'startoff' and 'endoff' respectively.
 #	 This last bit is so you can search for a large pattern, but only
 #	 embed a link in a smaller part of it.
 #	 
 #	Examples: 
 #	 see 'proc install::hyperiseUrls'
 # ----------------------------------------------------------------------
 ##
proc win::searchAndHyperise {args} {
    
    win::parseArgs w text link {regexp 0} {col 3} {startoff 0} {endoff 0}
    
    set pos [minPos -w $w]
    catch {
	while 1 {
	    set inds [search -w $w -s -f 1 -r $regexp -- $text $pos]
	    foreach {from to} $inds {break}
	    if {$startoff != 0} {
		set realfrom [pos::math -w $w $from + $startoff]
	    } else {
		set realfrom $from
	    }
	    if {$endoff != 0} {
		set realto [pos::math -w $w $to + $endoff]
	    } else {
		set realto $to
	    }
	    text::color -w $w $realfrom $realto $col
	    if {$link ne ""} {
		if {$regexp} {
		    regsub -- $text [getText -w $w $from $to] "$link" llink
		} else {
		    set llink $link
		}
		# Hack to handle some links.  (Do we really need this
		# hack, which slows down all other calls to this proc).
		set llink [string map [list << {} >> {}] $llink]

		if {[pos::diff -w $w $realfrom $realto] < 100} {
		    text::hyper -w $w $realfrom $realto $llink
		} else {
		    # Should turn this into an error in the future.
		    status::msg "Tried to mark very large hyper."
		}
	    }
	    set pos $to
	}	
    }
    # The calling procedure should 'refresh' now.
    return
}
if {0} {
    # experimental '-all' procedure, only 10% faster though.
proc win::searchAndHyperise {args} {
    
    win::parseArgs w text link {regexp 0} {col 3} {startoff 0} {endoff 0}
    
    set inds [search -w $w -s -n -all -f 1 -r $regexp -- $text [minPos]]
    foreach {from to} $inds {
	if {$startoff != 0} {
	    set realfrom [pos::math -w $w $from + $startoff]
	} else {
	    set realfrom $from
	}
	if {$endoff != 0} {
	    set realto [pos::math -w $w $to + $endoff]
	} else {
	    set realto $to
	}
	text::color -w $w $realfrom $realto $col
	if {$link ne ""} {
	    if {$regexp} {
		regsub -- $text [getText -w $w $from $to] "$link" llink
	    } else {
		set llink $link
	    }
	    # Hack to handle some links.  (Do we really need this
	    # hack, which slows down all other calls to this proc).
	    set llink [string map [list << {} >> {}] $llink]

	    if {[pos::diff -w $w $realfrom $realto] < 100} {
		text::hyper -w $w $realfrom $realto $llink
	    } else {
		# Should turn this into an error in the future.
		status::msg "Tried to mark very large hyper."
	    }
	}
    }
    # The calling procedure should 'refresh' now.
    return
}
}

proc win::multiSearchAndHyperise {args} {
    
    win::parseArgs w args
    
    while 1 {
	set text [lindex $args 0]
	set link [lindex $args 1]
	set args [lrange $args 2 end]
	if {($text eq "")} {
	    return
	}
	win::searchAndHyperise -w $w $text $link
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "win::jumpToCode" --
 # 
 #  It creates a hyperlink to a specific string in a code file, without
 #  requiring a mark to be defined there. It was handy for identifying places 
 #  in other packages that potentially collide with my key-bindings.
 #  
 #  Author: Jon Guyer.
 # -------------------------------------------------------------------------
 ##
proc win::jumpToCode {text file code} {
    set hyper {edit -c }
    append hyper $file
    append hyper { ; set pos [search -s -f 1 -r 1 "}
    append hyper $code
    append hyper {"]
    selectText [lindex $pos 0] [lindex $pos 1]}
    win::searchAndHyperise $text $hyper 0 3
}


## 
 # -------------------------------------------------------------------------
 # 
 # "win::mpsrCheck" --
 # 
 #  Called from filePreOpeningHook to get the font and size info for a
 #  window from the MPSR 1005 resource if it exists. 
 #  
 # -------------------------------------------------------------------------
 ##
proc win::mpsrCheck {winName} {
    set path [win::StripCount $winName]
    if {![catch {resource open $path} rid]} {
	if {![catch {set mpsr [resource read MPSR 1005 $rid]}]} {
	    binary scan $mpsr Sa32SS fontSize fontName tabWidth tabSize
	    set idx [string first \x00 $fontName]
	    set fontName [string range $fontName 0 [expr {$idx - 1}]]
	    set fontName [encoding convertfrom macRoman $fontName]
	    win::setInitialConfig $winName font $fontName window
	    win::setInitialConfig $winName fontsize $fontSize window
	    win::setInitialConfig $winName tabsize $tabSize window
	} 
	resource close $rid
    } 
}

# ===========================================================================
# 
# .