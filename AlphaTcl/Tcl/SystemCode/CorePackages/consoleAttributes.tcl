# -*-Tcl-*-  nowrap
# 
# File:    consoleAttributes.tcl
# Version: 2005-08-08 23:21
# Author:  Joachim Kock <kock@mat.uab.es>
# Description:
# 
# Mechanism to allow all sorts of console-like windows to remember their
# attributes (typically fontsize and geometry, but it can be any entry in
# the win::info array), to behave like windows that correspond to a file on
# disk.  This means that the first time such a console is opened, it will
# take some default attributes, or values that the programmer decided upon,
# but then, if the user changes any of these attributes to her liking,
# these new settings will be recorded when the window is closed, and be
# respected the next time the console is opened.  (There is also a reset
# command, in case you decide you would rather revert to the default
# values.)
# 
# The programmer's interface is this: instead of opening the console with
# a command like
# 
#     new -n "* My Small Brain *" -shell 1 -mode Shel -g 10 10 10 10 \
#       -font Monaco -fontsize 9
# 
# one should first declare the console with this command
# 
#     console::create "* My Small Brain *" -mode Shel -g 10 10 10 10 \
#       -font Moncao -fontsize 9
# 
# and then open it with the command
# 
#     console::open "* My Small Brain *"
# 
# Then the rest is taken care of automatically.  When the console window 
# is closed, the current attributes are written to a prefs array.  
# 
# In the console::create syntax, none of the hyphened parameters are
# necessary.  Those not specified will take default values.  (Currently
# these default values are just the global defaults, but in a future
# version, they might be mode specific defaults, if a -mode argument is
# given.)  A (pre)closeHook takes care of recording the changes to the
# attributes.  Only values that differ from the defaults are recorded.
# This means that if you leave your console with some default attribute
# and then change the global setting for this attribute, then when 
# opening the console next time, it will follow the global setting.
# 
# The attributes are stored in two arrays whose entries are a dict for each
# registered console: one array for attribute defaults (those specified at
# creation time) and one array for attribute settings (recording the actual
# settings according to distortions inflicted by the user.  In these dicts,
# the top level keys have hyphened names, like -g, -font, -minormode, etc.
# When opening a console through console::open, the user settings take
# precedence over the default settings, but can be overridden exceptionally
# by giving the parameter in the [console::open] call, or by giving the
# special -default option.
# 
# If a [create] command is issued on a console that already exists (i.e.
# has an entry in those arrays) then this entry is erased before the new
# parameters are put into it.  Note that the settings array is not touched
# in this case.  This is important since it allows the programmer to call
# [create] on a preexisting console without worrying about loosing the
# customisation contributed by the user.  In fact this situation occurs
# everytime you restart Alpha!  To clear the settings use [console::reset 
# NAME] or even [console::destroy NAME] before [console::create NAME].
# 
# A couple of other auxiliary commands, for the programmer's convenience
# (but in normal usage they should never be necessary):
# 
#     console::exists NAME
#         check whether the console NAME already exists
#     console::listAll
#         give a list of all registered consoles
#     console::getAttributeSettings NAME ?key? 
#         return the current attribute settings of NAME (as a dict,
#         or as the value of the key, if the 'key' argument is given).
#     console::getAttributeDefaults NAME ?key?
#         same, but for the defaults
#     console::setAttributeDefaults NAME key value
#         manually set a parameter
#     console::setAttributeSettings NAME key value
#         manually set a parameter


namespace eval console {}

# Preamble -- register our hook, set up our preferences, and ensure
# we have 'lvarpop' available.
hook::register preCloseHook console::recordAttributes consoleattributes

array set ::console::attributeDefaults [list]
array set ::console::attributeSettings [list]
prefs::modified ::console::attributeDefaults
prefs::modified ::console::attributeSettings

# console::create
# ---------------
# By definition a console $name exists if the dict
# console::attributeDefaults($name) exists (but it may well be empty).
# 
# When creating a new console, we assume that the status bar is at the top.
# When the window is actually opened, we correct for the case where in fact
# the status bar is at the bottom.  (In this way, if suddenly the user
# changes his preference on this issue, then his console geometry settings
# follow.)
# 
# You can define whatever parameters you want here, using -key value 
# syntax.  When the console is opened, those that makes sense for the [new]
# command are used there, and the rest are put into the win::array for
# whatever use other procs may have of them.
proc console::create { name args } {
    variable attributeDefaults
    set attributeDefaults($name) [eval _dictFromFlags $args]
}

# The only reason this special parser is needed is because we want to be
# able to give flags like -g 345 456 567 567 (apparently four values to one
# key...).
proc console::_dictFromFlags { args } {
    set D [dict create]
    while { [set key [lvarpop args]] != "" } {
	switch -glob -- $key {
	    "-g" {
		dict set D -g [list \
		  [lvarpop args] [lvarpop args] [lvarpop args] [lvarpop args]]
	    }
	    -* {
		dict set D $key [lvarpop args]
	    }
	    default {
		# This is the case where we expect a hyphened -key argument
		# but get one without a hyphen:
		error "bad arguments"
	    }
	}
    }
    return $D
}


# Remove the entry in the arrays
proc console::destroy { name } {
    if { [win::Exists $name] } {
	killWindow -w $name
    }
    unset -nocomplain ::console::attributeDefaults($name)
    unset -nocomplain ::console::attributeSettings($name)
}


# Obvious convenience procs:
proc console::exists { name } {
    return [info exists ::console::attributeDefaults($name)]
}
proc console::listAll {} {
    array names ::console::attributeDefaults
}
proc console::getAttributeDefaults { name args } {
    return [eval dict get {$::console::attributeDefaults($name)} $args]
}
proc console::getAttributeSettings { name args } {
    return [eval dict get {$::console::attributeSettings($name)} $args]
}
proc console::setAttributeDefaults { name key value } {
    dict set ::console::attributeDefaults($name) $key $value
}
proc console::setAttributeSettings { name key value } {
    dict set ::console::attributeSettings($name) $key $value
}




# console::open
# -------------
# Accepts extra arguments like -fontsize 12 which will override those
# specified in the attributeSettings.  Alternatively, accepts an extra argument
# -default* whose effect is to use the defaults instead of the settings.
# 
# Finally it also accepts one special overriding argument, -chars 80x24
# which will override the size of the window.  This is useful for windows 
# whose content is known in advance: even if the user had previously resized 
# the console to some ridiculous size, the caller can ensure that the console 
# opens at a certain size suitable for holding the content.  NOT IMPLEMENTED YET
# 
# If the console is already open, it is just brought to front, but no changes
# are applied to it.  If the console does not exist (in the big array) an
# error will occur.
# 
# Returns the name of the window created by the core, which should be the
# original supplied but we don't take any chances.
proc console::open { name args } {
    if { [win::Exists $name] } {
	bringToFront $name
	return $name
    }
    variable attributeDefaults
    variable attributeSettings
    
    set D $attributeDefaults($name)

    if { [llength $args] && [string match "\-default*" [lindex $args 0]] } {
	lvarpop args
    } elseif { [info exists attributeSettings($name)] } {
	set D [dict merge $D $attributeSettings($name)]
	# And now merge once again to get eventual -args specified at
	# invocation time --- these have highest priority.
	set D [dict merge $D [eval _dictFromFlags $args]]
    }
    
    set newCmd [list ::new -n $name -shell 1]

    # Now run through those parameters that it makes sense to give
    # directly to [new]:
    foreach key [list -mode -font -fontsize -tabsize -g] {
	if { [dict exists $D $key] } {
	    if { $key eq "-g" } {
		set thisGeom [dict get $D -g]
		set leftOffset [lindex $thisGeom 0]
		set topOffset [lindex $thisGeom 1]
		if { !$::locationOfStatusBar } {
		    # statusbar at bottom
		    incr topOffset -15
		}
		set consoleWidth [lindex $thisGeom 2]
		set consoleHeight [lindex $thisGeom 3]
		
		lappend newCmd -g $leftOffset $topOffset $consoleWidth $consoleHeight
	    } else {
		lappend newCmd $key [dict get $D $key]
	    }
	}
    }

    if { [dict exists $D -minormode] } {
	# Minor modes can only currently be applied before a window
	# is created (else you can try calling alpha::_applyMinorMode 
	# manually!).
	win::setInitialConfig $name minormode [dict get $D -minormode] window
    }

    set name [eval $newCmd]
    
    # Now copy the remaining entries in D over to the win::info array:
    foreach key [lremove [dict keys $D] \
      [list -g -mode -font -fontsize -tabsize -minormode]] {
	regsub {^-} $key "" key
	::win::setInfo $name $key [dict get $D -$key]
    }
    
    # The caller might have specified hookmodes.  However, for this 
    # to work at all, we must append the "consoleattributes" tag to the list!
    if { [catch {::win::getInfo $name hookmodes} L] } {
	set L [list]
    }
    lunion L consoleattributes
    ::win::setInfo $name hookmodes $L	

    # The refresh is needed to circumvent a display bug where fontsize is
    # not respected in the display, but only internally...
    refresh -w $name
    return $name
}



# Revert to default values.  (Note that -mode is not changed, since this
# can be delicate, and -minormode is not changed either, because this
# attribute can only be applied prior to window opening...)
proc console::reset { name } {
    if { [win::Exists $name] } {
	set D [_defaultsOrFallback $name]
	winChangeMode $name [dict get $D -mode]
	foreach key [lremove [dict keys $D] [list -g -mode -minormode]] {
	    regsub {^-} $key "" key
	    win::setInfo $name $key [dict get $D -$key]
	}
	set geom [dict get $D -g] 
	eval moveWin {$name} [lrange $geom 0 1]
	eval sizeWin {$name} [lrange $geom 2 3]
    } 
    variable attributeSettings
    unset -nocomplain attributeSettings($name)
}


# This proc is called automatically when the console window is closed.  It
# always examines geometry, mode, font, fontsize, and tabsize, and in
# addition to those, it will examine those specified in the defaults array.
# Only attributes whose value is different from the default value are
# recorded.
proc console::recordAttributes { name } {
    variable attributeSettings
    set D [_defaultsOrFallback $name]
    foreach key [dict keys $D] {
	regsub {^-} $key "" key
	if { $key eq "g" } {
	    set val [getGeometry $name]
	} elseif { [win::infoExists $name $key] } {
	    set val [win::getInfo $name $key]
	} else {
	    # We are not expected ever to come in here.  But if the
	    # parameter is not in the win::array, then the user cannot
	    # have set it, so just forget about it...
	    continue
	}
	if { [string equal -nocase $val [dict get $D -$key]] } {
	    # We don't want to record default settings.
	    # -nocase needed because font names are case insensitive
	    dict unset attributeSettings($name) -$key
	} else {
	    dict set attributeSettings($name) -$key $val
	}	
    }
}

# Construct a default dict, by starting with the global and mode settings,
# then merging in the attribute defaults (as given in the [create] statement).
proc console::_defaultsOrFallback {name} {
    # First construct a fallback dict from global and mode settings:
    set D [dict create -mode [win::getMode $name]]
    
    # Geometry:
    if {![catch {win::getModeVar $name windowGeometry} geomQuadruple] \
      && [llength $geomQuadruple]} {
	dict set D -g [lrange $geomQuadruple 1 4]
    } else {
	dict set D -g [list $::defLeft $::defTop $::defWidth $::defHeight]
    }
    # Other global/mode settings:
    catch {dict set D -font [win::getModeVar $name defaultFont]}
    catch {dict set D -fontsize [win::getModeVar $name fontSize]}
    catch {dict set D -tabsize [win::getModeVar $name tabSize]}

    # Then merge in the console defaults:
    variable attributeDefaults
    if { [info exists attributeDefaults($name)] } {
	set D [dict merge $D $attributeDefaults($name)]
    }
    # And finally, add the hookmode "consoleattributes":
    if { [catch {dict get $D -hookmodes} L] } {
	set L [list]
    }
    lunion L consoleattributes
    dict set D -hookmodes $L	

    return $D
}

