## -*-Tcl-*-
 # ###################################################################
 #  TclAE - Functions for building AppleEvents 
 #  			(modernization of appleEvents.tcl)
 # 
 #  FILE: "aebuild.tcl"
 #                                    created: 12/13/99 {12:55:28 PM} 
 #                                last update: 9/8/02 {9:31:07 PM} 
 #                                    version: 2.0
 #  Author: Jonathan Guyer
 #  E-mail: jguyer@his.com
 #    mail: Alpha Cabal
 #          POMODORO no seisan
 #     www: http://www.his.com/jguyer/
 #  
 # ========================================================================
 #               Copyright (c) 1999-2002 Jonathan Guyer
 #                        All rights reserved
 # ========================================================================
 # Permission to use, copy, modify, and distribute this software and its
 # documentation for any purpose and without fee is hereby granted,
 # provided that the above copyright notice appear in all copies and that
 # both that the copyright notice and warranty disclaimer appear in
 # supporting documentation.
 # 
 # Jonathan Guyer disclaims all warranties with regard to this software,
 # including all implied warranties of merchantability and fitness.  In
 # no event shall Jonathan Guyer be liable for any special, indirect or
 # consequential damages or any damages whatsoever resulting from loss of
 # use, data or profits, whether in an action of contract, negligence or
 # other tortuous action, arising out of or in connection with the use or
 # performance of this software.
 # ========================================================================
 #  Description: 
 # 
 #  History
 # 
 #  modified   by  rev reason
 #  ---------- --- --- -----------
 #  1999-12-13 JEG 1.0 original
 # ###################################################################
 ##

# ≈÷É≈÷É≈÷É≈÷É Initialization ≈÷É≈÷É≈÷É≈÷É #

namespace eval tclAE::build {}

# ≈÷É≈÷É≈÷É≈÷É Event handling ≈÷É≈÷É≈÷É≈÷É #

## 
 # -------------------------------------------------------------------------
 # 
 # "tclAE::build::throw" --
 # 
 #  Shorthand routine to check for AppleEvent errors
 # -------------------------------------------------------------------------
 ##
proc tclAE::build::throw {args} {
	# Event is only parsed for error checking, so purge
	# when done (in the event of an error, it'll already
	# be gone).
	tclAE::disposeDesc [eval tclAE::build::event $args]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tclAE::build::event" --
 # 
 #  Encapsulation for new and old style event building.
 # 
 # Results:
 #  The parsed result of the event.
 # -------------------------------------------------------------------------
 ##
proc tclAE::build::event {args} {
    set event [eval tclAE::send -r $args]
    tclAE::parse::throwIfError $event
    
    return $event
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tclAE::build::resultDataAs" --
 # 
 #  Shorthand routine to get the direct object result of an AEBuild call
 # -------------------------------------------------------------------------
 ##
proc tclAE::build::resultDataAs {type args} {
    global errorMsg
    
    set result ""
    
    set event [eval tclAE::build::event $args]
    
    if {[catch {set result [tclAE::getKeyData $event ---- $type]} errorMsg]} {
        if {![string match "Missing keyword '*' in record" $errorMsg]} {
            # No direct object is OK
            error::display
        }		
    } 
    
    tclAE::disposeDesc $event
    
    return $result
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tclAE::build::resultData" --
 # 
 #  Shorthand routine to get the direct object result of an AEBuild call
 # -------------------------------------------------------------------------
 ##
proc tclAE::build::resultData {args} {
    return [eval tclAE::build::resultDataAs **** $args]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tclAE::build::resultDescAs" --
 # 
 #  Shorthand routine to get the direct object result of an AEBuild call,
 #  coercing to $type
 # -------------------------------------------------------------------------
 ##
proc tclAE::build::resultDescAs {type args} {
    global errorMsg
    
    set result ""
    
    set event [eval tclAE::build::event $args]
    
    if {[catch {set result [tclAE::getKeyDesc $event ---- $type]} errorMsg]} {
        if {![string match "Missing keyword '*' in record" $errorMsg]} {
            # No direct object is OK
            error::display
        }		
    } 
    
    tclAE::disposeDesc $event
    
    return $result
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tclAE::build::resultDesc" --
 # 
 #  Shorthand routine to get the direct object result of an AEBuild call,
 #  retaining the type code
 # -------------------------------------------------------------------------
 ##
proc tclAE::build::resultDesc {args} {
    return [eval tclAE::build::resultDescAs **** $args]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tclAE::build::resultGizmoAs" --
 # 
 #  Shorthand routine to get the direct object result of an AEBuild call,
 #  coercing to $type and printing it as an AEGizmo
 # -------------------------------------------------------------------------
 ##
proc tclAE::build::resultGizmoAs {type args} {
    global errorMsg
    
    set result ""
    
    set event [eval tclAE::build::event $args]
    
    if {[catch {set result [tclAE::getKeyGizmo $event ---- $type]} errorMsg]} {
	if {![string match "Missing keyword '*' in record" $errorMsg]} {
	    # No direct object is OK
	    error::display
	}		
    } 
    
    tclAE::disposeDesc $event
    
    return $result
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tclAE::build::resultGizmo" --
 # 
 #  Shorthand routine to get the direct object result of an AEBuild call,
 #  retaining the type code and printing it as an AEGizmo
 # -------------------------------------------------------------------------
 ##
proc tclAE::build::resultGizmo {args} {
    return [eval tclAE::build::resultGizmoAs **** $args]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tclAE::build::protect" --
 # 
 #  Alpha seems pickier about ident lengths than AEGizmos says it should be. 
 #  Protect any whitespace.
 # 
 # Results:
 #  Returns $value, possible bracketed with ' quotes
 # 
 # Side effects:
 #  None.
 # -------------------------------------------------------------------------
 ##
proc tclAE::build::protect {value} {
	set value [string trimright $value]
	if {[regexp {[][ @≈¥ù'≈¥ﬂ≈¥ÿ:,({})-]} $value blah]} {
		set quote 1
	} else {
		set quote 0
	}
	
	set value [format "%-4.4s" $value]
	
	if {$quote} {
		set value "'${value}'"		
	} 
	
	return $value
}

proc tclAE::build::objectProperty {process property object} {
	return [tclAE::build::resultData $process core getd ---- \
	  			[tclAE::build::propertyObject $property $object]]
}

# ≈÷É≈÷É≈÷É≈÷É Builders ≈÷É≈÷É≈÷É≈÷É #

proc tclAE::build::coercion {fromValue toType} {
	set toType [tclAE::build::protect $toType]

	switch -- [string index $fromValue 0] {
		"\{" { # value is record
			return "${toType}${fromValue}"
		}
		"\[" { # value is list
			set msg "Cannot coerce a list"
			error $msg "" [list AEParse 16 $msg]
		}
		default {
			return "${toType}(${fromValue})"
		}
	}
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tclAE::build::List" --
 # 
 #  Convert list 'l' to an AE list, i.e., "[l1, l2, l3, ...]".
 #  "-as type" coerces elements to 'type' before joining.  
 #  Set "-untyped" if the elements do not consist of AEDescriptors
 # -------------------------------------------------------------------------
 ##
proc tclAE::build::List {l args} {
	set opts(-as) ""
	set opts(-untyped) 0
	getOpts as
	
	if {[string length $opts(-as)] != 0} {
		set out {}
		foreach item $l {
			lappend out [tclAE::build::$opts(-as) $item]
		}
	} elseif {!$opts(-untyped)} {
		set out {}
		foreach item $l {
			lappend out [tclAE::print $item]
		}		
	} else {
		set out $l
	}
	
	set out [join $out ", "]
	return "\[$out\]"
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tclAE::build::hexd" --
 # 
 #  Convert 'value' to 'åÇvalueåÈ'.
 #  value's spaces are stripped and it is left-padded with 0 to even digits.
 # -------------------------------------------------------------------------
 ##
proc tclAE::build::hexd {value} {
	set newval $value
	if {[expr {[string length $newval] % 2}]} {
		# left pad with zero to make even number of digits
		set newval "0${newval}"
	} 
	if {![is::Hexadecimal $newval]} {
	    if {[is::Whitespace $newval]} {
		return ""
	    } else {
		set msg "Non-hex-digit in åÇ${value}åÈ" 
		error $msg "" [list AECoerce 6 $msg]
	    }
	} else {
		return "åÇ${newval}åÈ"
	}
}

proc tclAE::build::_ensureBinary {text} {
	if {[set len [string length $text]] > 0
	&&	([expr {[string length $text] % 2}] != 0
		||	![is::Hexadecimal $text])} {
		set text [coerce TEXT $text -x TEXT]
	} else {
		return $text
	}
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tclAE::build::bool" --
 # 
 #  Convert 'val' to AE 'bool(åÇvalåÈ)'.
 # -------------------------------------------------------------------------
 ##
proc tclAE::build::bool {val} {
    if {$val} {
        set val 1
    } else {
        set val 0
    }
    
    return [tclAE::build::coercion [tclAE::build::hexd $val] bool]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tclAE::build::TEXT" --
 #  
 #  Convert $txt to ≈¥ﬂTEXT≈¥ÿ.
 #  If there are curly quotes in $txt, output in raw hex, coerced to TEXT
 # -------------------------------------------------------------------------
 ##
proc tclAE::build::TEXT {txt} {
    if {$txt == ""} {
        return "[tclAE::build::coercion {} TEXT]"
    } elseif {[string first "\x00" $txt] >= 0
    ||  [string first "≈¥ﬂ" $txt]    >= 0
    ||  [string first "≈¥ÿ" $txt]    >= 0} {
        
        set hexd [binary format "a*" $txt]
        return "[tclAE::build::coercion [tclAE::build::hexd $hexd] TEXT]"
    } else {
        return "≈¥ﬂ${txt}≈¥ÿ"
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tclAE::build::alis" --
 # 
 #  Convert 'path' to an alis(åÇ...åÈ).
 # -------------------------------------------------------------------------
 ##
proc tclAE::build::alis {path} {
    set alisDesc [tclAE::coerceData TEXT $path alis]
    set gizmo [tclAE::print $alisDesc]
    tclAE::disposeDesc $alisDesc
    return $gizmo
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tclAE::build::fss" --
 # 
 #  Convert 'path' to an 'fss '(åÇ...åÈ).
 # -------------------------------------------------------------------------
 ##
proc tclAE::build::fss {path} {
    set fss [tclAE::build::resultDesc 'MACS' core getd \
      ---- "obj{want:type('cobj'), from:'null'(), \
        [tclAE::build::name $path] \
      }" \
      rtyp fss \
    ]
  set result [tclAE::print $fss]
  tclAE::disposeDesc $fss
  
  return $result
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tclAE::build::ident" --
 # 
 #  Dummy proc for rebuilding AEGizmos strings from parsed lists
 # -------------------------------------------------------------------------
 ##
proc tclAE::build::enum {enum} {
    return [tclAE::build::protect $enum]
}


proc tclAE::build::name {name} {
    return "form:'name', seld:[tclAE::build::TEXT $name]"
}

proc tclAE::build::filename {name} {
    if {${alpha::macos} == 2} {
        set name [tclAE::getHFSPath $name]
    } 
    return "obj{want:type('file'), from:'null'(), [tclAE::build::name $name] } "
}

proc tclAE::build::winByName {name} {
    return "obj{want:type('cwin'), from:'null'(), [tclAE::build::name $name]}"
}

proc tclAE::build::winByPos {absPos} {
    return "obj{want:type('cwin'), from:'null'(), [tclAE::build::absPos $absPos]}"
}

proc tclAE::build::lineRange {absPos1 absPos2} {
    set lineObj1 "obj{want:type('clin'), from:'ccnt'(), [tclAE::build::absPos $absPos1]}"
    set lineObj2 "obj{want:type('clin'), from:'ccnt'(), [tclAE::build::absPos $absPos2]}"
    return "form:'rang', seld:rang{star:$lineObj1, stop:$lineObj2}"
}

proc tclAE::build::charRange {absPos1 absPos2} {
    set charObj1 "obj{want:type('cha '), from:'ccnt'(), [tclAE::build::absPos $absPos1]}"
    set charObj2 "obj{want:type('cha '), from:'ccnt'(), [tclAE::build::absPos $absPos2]}"
    return "form:'rang', seld:rang{star:$charObj1, stop:$charObj2}"
}

proc tclAE::build::absPos {posName} {
    #
    # Use '1' or 'first' to specify first position
    # and '-1' or 'last' to specify last position.
    #
    if {$posName == "first"} { 
        set posName 1 
    } elseif {$posName == "last"} { 
        set posName -1 
    }
    if {[is::Integer $posName]} {
        return "form:indx, seld:long($posName)"
    } else {
        error "tclAE::build::absPos: bad argument"
    }
}

proc tclAE::build::nullObject {} { 
    return "'null'()" 
}

proc tclAE::build::objectType {type} { 
	return "type($type)" 
}

proc tclAE::build::nameObject {type name {from ""}} 	{
    if {$from == ""} {
        set from [tclAE::build::nullObject]
    } 
    return "obj \{ \
      form:name, \
      want:[tclAE::build::objectType $type], \
      seld:$name, \
      from:$from \
    \}" 
}

proc tclAE::build::indexObject {type ind {from ""}} {
    if {$from == ""} {
        set from [tclAE::build::nullObject]
    } 
    return "obj \{ \
      form:indx, \
      want:[tclAE::build::objectType $type], \
      seld:$ind, \
      from:$from \
    \}" 
}

proc tclAE::build::everyObject {type {from ""}} {
    return [tclAE::build::indexObject $type "abso('all ')" $from]
}

proc tclAE::build::rangeObject {type absPos1 absPos2 {from ""}} {
    if {$from == ""} {
        set from [tclAE::build::nullObject]
    } 
    set type [tclAE::build::objectType $type]
    
    set obj1 "obj{                      \
        want:$type,                     \
        from:'ccnt'(),                  \
        [tclAE::build::absPos $absPos1] \
    }"
    set obj2 "obj{                      \
        want:$type,                     \
        from:'ccnt'(),                  \
        [tclAE::build::absPos $absPos2] \
    }"
    return "obj {     \
      form:rang,      \
      want:$type,     \
      seld:rang{      \
        star:$obj1,   \
        stop:$obj2    \
      },              \
      from:$from      \
    }" 
}

proc tclAE::build::propertyObject {prop {object ""}} { 
    if {[string length $object] == 0} {
        set object [tclAE::build::nullObject]
    } 
    
    return "obj \{\
      form:prop, \
      want:[tclAE::build::objectType prop], \
      seld:[tclAE::build::objectType $prop], \
      from:$object \
    \}" 
}

proc tclAE::build::propertyListObject {props {object ""}} { 
    if {[string length $object] == 0} {
	set object [tclAE::build::nullObject]
    } 
    
    return "obj \{\
      form:prop, \
      want:[tclAE::build::objectType prop], \
      seld:[tclAE::build::List $props -as objectType], \
      from:$object \
    \}" 
}

# ≈÷É≈÷É≈÷É≈÷É Utilities ≈÷É≈÷É≈÷É≈÷É #

## 
 # -------------------------------------------------------------------------
 # 
 # "tclAE::build::startupDisk" --
 # 
 #  The name of the Startup Disk (as sometimes returned by the Finder)
 # -------------------------------------------------------------------------
 ##
proc tclAE::build::startupDisk {} {
    return [tclAE::build::objectProperty 'MACS' pnam \
      "obj \{want:type(prop), from:'null'(), \
      form:prop, seld:type(sdsk)\}" \
    ]	
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tclAE::build::OS8userName" --
 # 
 # Get the owner name of the computer
 #  
 # -------------------------------------------------------------------------
 ##
proc tclAE::build::OS8userName {} {
    # tell application "Finder" to get owner name
    return [tclAE::build::resultData 'MACS' ownn getd]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tclAE::build::OS7userName" --
 # 
 # For MacOS 7.x, we use the owner of the preferences folder.
 #  
 # This is not guaranteed to be the same as the Mac's owner, but it's 
 # likely the same and seems preferable to IC's user name, which is almost 
 # never the same.
 #
 # I picked the preference folder because it was easily 
 # specifiable through AppleEvents, because its default ownership 
 # is that of the computer, and because a user would really have to 
 # go out of their way to change it (by either explicitly changing 
 # ownership, or more likely, by clicking 
 # 'Make all currently enclosed folders like this one' 
 # in the startup disk's Sharing window after changing the disk's 
 # ownership. Anyone who does this should be taunted severely.
 # 
 # This will fail if File Sharing is off.
 # -------------------------------------------------------------------------
 ##
proc tclAE::build::OS7userName {} {
    # tell application "Finder" to get owner of preferences folder
    return [tclAE::build::objectProperty 'MACS' sown \
      [tclAE::build::propertyObject pref [tclAE::build::nullObject]] \
    ]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tclAE::build::userName" --
 # 
 #  Return the default user name. The Mac's owner name,
 #  which is in String Resource ID -16096, is inaccesible to Tcl 
 #  (at least until Tcl 8 is implemented).
 #  
 #  Try different mechanisms for determining the user name.
 #  
 # -------------------------------------------------------------------------
 ##
if {[info tclversion] < 8.0} {
    proc tclAE::build::userName {} {
        
        if {[catch {tclAE::build::OS8userName} userName]} {
            
            # Above failed, probably because the OS doesn't support
            # scriptable File Sharing.
            
            if {[catch {tclAE::build::OS7userName} userName]} {
                # Both attempts at a user name failed, so return whatever
                # Internet Config has
                
                set userName [icGetPref RealName]
            }
        }
        
        return $userName
    }
} else {
    ;proc tclAE::build::userName {} {
        return [text::fromPstring [resource read "STR " -16096]]
    }
}

# Build a Folder object from its name
proc tclAE::build::foldername {name} {
    return "obj{want:type('cfol'), from:'null'(), [tclAE::build::name $name] } "
}
