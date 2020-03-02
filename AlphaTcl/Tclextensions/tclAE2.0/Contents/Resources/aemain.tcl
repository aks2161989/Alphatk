## -*-Tcl-*-
 # ###################################################################
 #  TclAE - AppleEvent extension for Tcl
 # 
 #  FILE: "aemain.tcl"
 #                                    created: 1/17/00 {5:53:20 PM} 
 #                                last update: 9/6/02 {10:00:19 PM} 
 #                                    version: 2.0b8
 #  Author: Jonathan Guyer
 #  E-mail: jguyer@his.com
 #    mail: Alpha Cabal
 #          POMODORO no seisan
 #     www: http://www.his.com/jguyer/
 #  
 # ========================================================================
 #               Copyright (c) 1999-2002 Jonathan Guyer
 #                      All rights reserved
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
 #  2000-01-17 JEG 1.0 original
 #  2000-08-28 JEG 2.0 synchronized with TclAE C shared library
 # ###################################################################
 ##

# ≈÷É≈÷É≈÷É≈÷É Initialization ≈÷É≈÷É≈÷É≈÷É #

alpha::extension tclAE 2.0b8 {
    namespace eval tclAE {}
    
    set haveTclAE 0
    
    alpha::package require aeom
} help {
	file "TclAE Help"
} maintainer {
    "Jon Guyer" <jguyer@his.com> <http://www.his.com/jguyer/>
} requirements {
    if {!${alpha::macos}} {
	error "Apple-events are only available on MacOS"
    }
}


proc tclAE::quitHook {} {
    # tclAE::target only exists in Alpha 8
    if {([llength [info commands "tclAE::target"]] == 0)
    &&  ([llength [info commands "::tclAE::target"]] == 0)} {
        status::msg "Caching AE Targets≈¥Ï"
        cache::delete tclAETargets
        set i 0
        foreach target [tclAE::target names] {
            set targetArray "target$i"

            # Copy target information into a local array
            tclAE::target info $target $targetArray

            set ${targetArray}(hashKey) $target
            # Cache that array
            cache::add tclAETargets variable $targetArray
            
            incr i
            unset $targetArray
        }    
    }    
}

# test will fail if TclAE.shlb is available to a Tcl8-based Alpha
if {([info tclversion] < 8.0)
||	![info exists tclAE_version] 
||  ($tclAE_version < 2.0)} {

# ≈÷É≈÷É≈÷É≈÷É TclAE calls ÌÁ la ToolBox ≈÷É≈÷É≈÷É≈÷É #

proc tclAE::build {theAEGizmo} {
	tclAE::parse::obj theAEGizmo theAEDesc
	
	return $theAEDesc
}

proc tclAE::coerceData {typeCode data toType} {
    global tclAE::coerce::handler
    
    # no need to do anything for an identity coercion
    if {($toType != $typeCode)
    &&  ($toType != "****")} {
		
		if {[catch {tclAE::getCoercionHandler $typeCode $toType} handler]} {
			if {[catch {tclAE::getCoercionHandler "****" $toType} handler]} {
				if {[catch {tclAE::getCoercionHandler $typeCode "****"} handler]} {
					# No coercion possible
					error::throwOSErr -1700
				} 		
			} 	    
		} 
		
		set resultDesc [tclAE::createDesc $toType]
		
		set data [tclAE::build::_ensureBinary $data]
		
		if {[catch {$handler $typeCode $data $toType $resultDesc}]} {
			# Coercion failed
			error::throwOSErr -1700
		} 
    } else {
		set resultDesc [tclAE::createDesc $typeCode $data]
	}
	
    return $resultDesc
}

proc tclAE::coerceDesc {theAEDesc toType} {
	global errorMsg
	
	set fromAEDesc [tclAE::_getDescFromAny $theAEDesc]
	set err [catch {
		set coerceDesc [tclAE::_descriptorProc $fromAEDesc coerceDesc]
		set toAEDesc [$coerceDesc $fromAEDesc $toType]
	} errorMsg]
	
	tclAE::disposeDesc $fromAEDesc
	
	if {$err} {
		error::rethrow
	} else {
		return $toAEDesc
	}
}

proc tclAE::countItems {theAEDescList} {
	set theAEDescList [tclAE::subdesc::_getDescIfSubDesc $theAEDescList]
    return [[tclAE::_descriptorProc $theAEDescList countItems] $theAEDescList]
}

proc tclAE::createDesc {typeCode {data ""}} {
    global tclAE::desc::_next
    
    # Get the next available AEDesc record
    set AEDesc [tclAE::desc::_form [incr tclAE::desc::_next]]
    
    # Set the descriptor type
    global $AEDesc
    set ${AEDesc}(descriptorType)	$typeCode
    set ${AEDesc}(basicType)		"****"
    set ${AEDesc}(dataRecord)		[tclAE::build::_ensureBinary $data]     

    return $AEDesc    
}

proc tclAE::createList {{isRecord 0}} {
    if {$isRecord} {
		set AEDescList [tclAE::createDesc "reco"]
		global $AEDescList
		set ${AEDescList}(basicType) "reco"
    } else {
		set AEDescList [tclAE::createDesc "list"]
		set ${AEDescList}(basicType) "list"
    }
    
    return $AEDescList
}

proc tclAE::deleteItem {theAEDescList index} {
    [[tclAE::_descriptorProc $theAEDescList deleteItem] \
      		$theAEDescList $index]
}

proc tclAE::deleteKeyDesc {theAERecord theAEKeyword} {    
    [[tclAE::_descriptorProc $theAERecord deleteKeyDesc] \
				$theAERecord $theAEKeyword]
}

proc tclAE::disposeDesc {theAEDesc} {
    return [[tclAE::_descriptorProc $theAEDesc disposeDesc] $theAEDesc]
}

proc tclAE::duplicateDesc {theAEDesc} {
    return [tclAE::_getDescFromAny $theAEDesc]
}

proc tclAE::getCoercionHandler {fromType toType} {
    global tclAE::coerce::handler

    # We ignore isSysHandler
    # All handlers are application specific (for now, anyway)
    if {[info exists tclAE::coerce::handler(${fromType}${toType})]} {
		set handlerInfo [set tclAE::coerce::handler(${fromType}${toType})]
		
		return [lindex $handlerInfo 0]
    } else {
		# Handler undefined
		error::throwOSErr -1717
    }
}

proc tclAE::getEventHandler {theAEEventClass theAEEventID} {
    global tclAE::eventHandlers

    # We ignore isSysHandler
    # All handlers are application specific (for now, anyway)
    if {[info exists tclAE::eventHandlers(${theAEEventClass}${theAEEventID})]} {
		set handlerInfo [set tclAE::eventHandlers(${theAEEventClass}${theAEEventID})]
		
		return [lindex $handlerInfo 0]
    } else {
		# Handler undefined
		error::throwOSErr -1717
    }
}

proc tclAE::getKeyData {theAERecord theAEKeyword {desiredType ****} {typeCodePtr ""}} {
    upvar $typeCodePtr typeCode
    return [[tclAE::_descriptorProc $theAERecord getKeyData] \
			  $theAERecord $theAEKeyword $desiredType typeCode]
}

proc tclAE::getKeyDesc {theAERecord theAEKeyword {desiredType ****}} {
    return [[tclAE::_descriptorProc $theAERecord getKeyDesc] \
			  $theAERecord $theAEKeyword $desiredType]
}

proc tclAE::getKeyGizmo {theAERecord theAEKeyword {desiredType ****}} {
	set theAEDesc [tclAE::getKeyDesc $theAERecord $theAEKeyword $desiredType]
	set gizmo [tclAE::print $theAEDesc]
	tclAE::disposeDesc $theAEDesc
	
	return $gizmo
}

proc tclAE::getNthData {theAEDescList index {desiredType ****} {theAEKeywordPtr ""} {typeCodePtr ""}} {
    upvar $theAEKeywordPtr theAEKeyword
    upvar $typeCodePtr typeCode
    return [[tclAE::_descriptorProc $theAEDescList getNthData] \
			  $theAEDescList $index $desiredType theAEKeyword typeCode]
}

proc tclAE::getNthDesc {theAEDescList index {desiredType ****} {theAEKeywordPtr ""}} {
    upvar $theAEKeywordPtr theAEKeyword
    return [[tclAE::_descriptorProc $theAEDescList getNthDesc] \
			  $theAEDescList $index $desiredType theAEKeyword]
}

proc tclAE::getNthGizmo {theAEDescList index {desiredType ****} {theAEKeywordPtr ""}} {
    upvar $theAEKeywordPtr theAEKeyword
	
	set theAEDesc [tclAE::getNthDesc $theAEDescList $index $desiredType theAEKeyword]
	set gizmo [tclAE::print $theAEDesc]
	tclAE::disposeDesc $theAEDesc
	
	return $gizmo
}

proc tclAE::installCoercionHandler {fromType toType theHandler {handlerRefcon 0} {fromTypeIsDesc 0} {isSysHandler 0}} {
    global tclAE::coerce::handler
    
    # We ignore isSysHandler
    # All handlers are application specific (for now, anyway)
    set tclAE::coerce::handler(${fromType}${toType}) \
	  [list $theHandler $handlerRefcon $fromTypeIsDesc]
}

proc tclAE::installEventHandler {theAEEventClass theAEEventID handler {handlerRefcon ""} {isSysHandler 0}} {
	global tclAE::eventHandlers
	
	set tclAE::eventHandlers(${theAEEventClass}${theAEEventID}) [list $handler $handlerRefcon $isSysHandler]
	
	# All events get routed through here
	eventHandler $theAEEventClass $theAEEventID tclAE::_eventHandler
}

proc tclAE::listDescriptors {} {
    global tclAE::desc::wildcard
    
    return [info globals ${tclAE::desc::wildcard}]
}

proc tclAE::print {theAEDesc} {
	global errorMsg
	
	set copyAEDesc [tclAE::_getDescFromAny $theAEDesc]
	set err [catch {
		set printDesc [tclAE::_descriptorProc $copyAEDesc print]
		set gizmo [$printDesc $copyAEDesc]
	} errorMsg]
	
	tclAE::disposeDesc $copyAEDesc
	
	if {$err} {
		error::rethrow
	} else {
		return $gizmo
	}
}

proc tclAE::putData {theAEDescList index typeCode data} {
	set putDesc [tclAE::_descriptorProc $theAEDescList putDesc]
	set theAEDesc [tclAE::createDesc $typeCode $data]
    $putDesc $theAEDescList $index $theAEDesc
	tclAE::disposeDesc $theAEDesc
}

proc tclAE::putDesc {theAEDescList index theAEDesc} {
    [tclAE::_descriptorProc $theAEDescList putDesc] \
      $theAEDescList $index $theAEDesc
}

proc tclAE::putKeyData {theAERecord theAEKeyword typeCode data} {
	set putKeyDesc [tclAE::_descriptorProc $theAERecord putKeyDesc]
	set theAEDesc [tclAE::createDesc $typeCode $data]
    $putKeyDesc $theAERecord $theAEKeyword $theAEDesc
	tclAE::disposeDesc $theAEDesc
}

proc tclAE::putKeyDesc {theAERecord theAEKeyword theAEDesc} {
    [tclAE::_descriptorProc $theAERecord putKeyDesc] \
      $theAERecord $theAEKeyword $theAEDesc
}

proc tclAE::removeCoercionHandler {fromType toType handler {isSysHandler 0}} {
    global tclAE::coerce::handler
    
    # We ignore isSysHandler
    # All handlers are application specific (for now, anyway)
    if {[info exists tclAE::coerce::handler(${fromType}${toType})]} {
		set handlerInfo [set tclAE::coerce::handler(${fromType}${toType})]
		if {$handler != [lindex $handlerInfo 0]} {
			# Something's wrong
			error::throwOSErr -1717
		} 
		unset tclAE::coerce::handler(${fromType}${toType})
    } else {
		# Handler undefined
		error::throwOSErr -1717
    }
}

proc tclAE::removeEventHandler {theAEEventClass theAEEventID handler {isSysHandler 0}} {
    global tclAE::eventHandlers
    
    # We ignore isSysHandler
    # All handlers are application specific (for now, anyway)
    if {[info exists tclAE::eventHandlers(${theAEEventClass}${theAEEventID})]} {
		set handlerInfo [set tclAE::eventHandlers(${theAEEventClass}${theAEEventID})]
		if {$handler != [lindex $handlerInfo 0]} {
			# Something's wrong
			error::throwOSErr -1717
		} 
		unset tclAE::eventHandlers(${theAEEventClass}${theAEEventID})
    } else {
		# Handler undefined
		error::throwOSErr -1717
    }
}

# ≈÷É≈÷É≈÷É≈÷É TclAE Descriptors ≈÷É≈÷É≈÷É≈÷É #

proc tclAE::getData {theAEDesc {desiredType ****} {typeCodePtr ""}} {
    upvar $typeCodePtr typeCode
    return [[tclAE::_descriptorProc $theAEDesc getData] \
			  $theAEDesc $desiredType typeCode]    
}

proc tclAE::getDescType {theAEDesc} {
    global $theAEDesc
	if {[info exists $theAEDesc]} {
		return [set ${theAEDesc}(descriptorType)]
	} else {
		error::throwOSErr -1701
	}
}

proc tclAE::replaceDescData {theAEDesc typeCode data} {
	global $theAEDesc
	
	set ${theAEDesc}(descriptorType) $typeCode
	set ${theAEDesc}(dataRecord) [tclAE::build::_ensureBinary $data]	
}

proc tclAE::setDescType {theAEDesc toType} {
	global $theAEDesc
	
	set ${theAEDesc}(descriptorType) $toType
}

# ≈÷É≈÷É≈÷É≈÷É TclAE Sub-descriptors ≈÷É≈÷É≈÷É≈÷É #

namespace eval tclAE::subdesc {}

proc tclAE::subdesc::dispose {theAESubDesc} {
	global $theAESubDesc
	
	if {[info exists $theAESubDesc]} {
		unset $theAESubDesc
	} else {
		error::throwOSErr -1701 "Couldn't dispose of \"${theAESubDesc}\""
	}
}

proc tclAE::subdesc::fromDesc {theAEDesc {toAESubDesc ""}} {
    global tclAE::subdesc::_next $theAEDesc
	
	if {![info exists $theAEDesc]} {
		error::throwOSErr -1701 "Couldn't find \"${theAEDesc}\""
	}
    
	if {$toAESubDesc == ""} {
		# Get the next available AESubDesc record
		set toAESubDesc [tclAE::subdesc::_form [incr tclAE::subdesc::_next]]		
	} 
	
	global $toAESubDesc
	
    set ${toAESubDesc}(subDescType) [set ${theAEDesc}(descriptorType)]

    if {[set ${theAEDesc}(basicType)] == "reco"} {
		set ${toAESubDesc}(basicType) "reco"
    } else {
		set ${toAESubDesc}(basicType) [set ${theAEDesc}(descriptorType)]
    }
    
    # This is not how AESubDesc's are structured, but it's what
    # makes the most sense here
    set ${toAESubDesc}(dataHandle)  $theAEDesc      

    return $toAESubDesc
}

proc tclAE::subdesc::getBasicType {theAESubDesc} {
    global $theAESubDesc
    
    return [set ${theAESubDesc}(basicType)]
}

proc tclAE::subdesc::getData {theAESubDesc {asRawBinary 0}} {
    global $theAESubDesc
	
	set theAEDesc [set ${theAESubDesc}(dataHandle)]
	global $theAEDesc
    
	if {$asRawBinary} {
		return [tclAE::getData $theAEDesc ????]
	} else {
		return [tclAE::getData $theAEDesc]
	}
}

proc tclAE::subdesc::getKey {theAESubDesc theAEKeyword {inPlace 0}} {
	global $theAESubDesc
	
	if {![tclAE::subdesc::isListOrRecord $theAESubDesc]} {
        error::throwOSErr -1703
    }
    
	set theAEDesc [set ${theAESubDesc}(dataHandle)]
	global $theAEDesc
	
	set theAEKeyword [format "%-4.4s" $theAEKeyword]
	
	if {![info exists ${theAEDesc}($theAEKeyword)]} {
		error::throwOSErr -1719 "Couldn't get sub-descriptor"
	}
	
	if {$inPlace} {
		return [tclAE::subdesc::fromDesc [set ${theAEDesc}($theAEKeyword)] $theAESubDesc]
	} else {
		return [tclAE::subdesc::fromDesc [set ${theAEDesc}($theAEKeyword)]]
	}
}

proc tclAE::subdesc::getKeyData {theAESubDesc theAEKeyword {asRawBinary 0}} {
	global $theAESubDesc
	
	if {![tclAE::subdesc::isListOrRecord $theAESubDesc]} {
        error::throwOSErr -1703 "Couldn't get sub-descriptor"
    }
    
	set theAEDesc [set ${theAESubDesc}(dataHandle)]
	global $theAEDesc
	
	if {$asRawBinary} {
		return [tclAE::getKeyData $theAEDesc $theAEKeyword ????]
	} else {
		return [tclAE::getKeyData $theAEDesc $theAEKeyword]
	}
}

proc tclAE::subdesc::getNth {theAESubDesc index {keyIfAnyPtr ""} {inPlace 0}} {
	global $theAESubDesc
	
	if {![tclAE::subdesc::isListOrRecord $theAESubDesc]} {
        error::throwOSErr -1703 "Couldn't get sub-descriptor"
    }
    
	upvar \#0 [set ${theAESubDesc}(dataHandle)] theAEDescList
	
	set data $theAEDescList(dataRecord)
	if {($index < 0) 
	||  ($index >= [llength $data])} {
		# index out of range
		error::throwOSErr -1719 "Couldn't get sub-descriptor"
	} 
	upvar $keyIfAnyPtr theAEKeyword	
	
	if {[set ${theAESubDesc}(basicType)] == "list"} {
		set theAEKeyword "****"
		set item [lindex $data $index]
	} else { # 'reco'
		set theAEKeyword [format "%-4.4s" [lindex $data $index]]
		set item $theAEDescList($theAEKeyword)
	}
	
	if {$inPlace} {
		return [tclAE::subdesc::fromDesc $item $theAESubDesc]		
	} else {
		return [tclAE::subdesc::fromDesc $item]		
	} 
}

proc tclAE::subdesc::getNthData {theAESubDesc index {keyIfAnyPtr ""} {asRawBinary 0}} {
	global $theAESubDesc
	
	if {![tclAE::subdesc::isListOrRecord $theAESubDesc]} {
        error::throwOSErr -1703 "Couldn't get sub-descriptor"
    }
    
	set theAEDesc [set ${theAESubDesc}(dataHandle)]
	global $theAEDesc
	
	upvar $keyIfAnyPtr theAEKeyword	
	
	if {$asRawBinary} {
		return [tclAE::getNthData $theAEDesc $index ???? theAEKeyword]
	} else {
		return [tclAE::getNthData $theAEDesc $index **** theAEKeyword]
	}
}

proc tclAE::subdesc::getType {theAESubDesc} {
    global $theAESubDesc
    
	if {[info exists $theAESubDesc]} {
		return [set ${theAESubDesc}(subDescType)]
	} else {
		error::throwOSErr -1701
	}
}

proc tclAE::subdesc::isListOrRecord {theAESubDesc} {
    global $theAESubDesc
	
	if {![tclAE::subdesc::isSubDescriptor $theAESubDesc]} {
		error::throwOSErr -1701 "Couldn't find \"${theAESubDesc}\""
	} 
    
    set basicType [set ${theAESubDesc}(basicType)]
    
    return [expr {($basicType == "list") 
			   || ($basicType == "reco") 
			   || ($basicType == "aevt")}]
}

proc tclAE::subdesc::listSubDescriptors {} {
    global tclAE::subdesc::wildcard
    
    return [info globals ${tclAE::subdesc::wildcard}]
}

proc tclAE::subdesc::toDesc {theAESubDesc {desiredType ****}} {
    global $theAESubDesc
	
	if {![tclAE::subdesc::isSubDescriptor $theAESubDesc]} {
		error::throwOSErr -1701 "Couldn't find \"${theAESubDesc}\""
	} 
    
    return [tclAE::coerceDesc [set ${theAESubDesc}(dataHandle)] $desiredType]
}

# The list-oriented calls that follow make sure the subdescriptor is a
# valid list or (possibly coerced) record.  If not, they'll throw
# errAEWrongDataType.

# ≈÷É≈÷É≈÷É≈÷É Private Routines ≈÷É≈÷É≈÷É≈÷É #

proc tclAE::_descriptorProc {AEDesc procType} {
    global $AEDesc tclAE::desc::procs
    
	if {![info exists $AEDesc]} {
		error::throwOSErr -1701 "Cannot '${procType}' with \"${AEDesc}\""
	}
	
    set descriptorType	[set ${AEDesc}(descriptorType)]
    set basicType	[set ${AEDesc}(basicType)]
    
    if {[info exists tclAE::desc::procs(${descriptorType}.${procType})]} {
		# Return type-specific proc
		return [set tclAE::desc::procs(${descriptorType}.${procType})]
    } elseif {[info exists tclAE::desc::procs(${basicType}.${procType})]} {
		# Return generic proc
        return [set tclAE::desc::procs(${basicType}.${procType})]
    } else {
		# No proc available
		error "Cannot '${procType}' with \"${AEDesc}\""
    }
}

proc tclAE::_duplicateDesc {theAEDesc} {
    return [[tclAE::_descriptorProc $theAEDesc duplicateDesc] $theAEDesc]
}

proc tclAE::_getDescFromAny {someAEDesc} {
	if {[tclAE::desc::isDescriptor $someAEDesc]} {
		set theAEDesc [tclAE::_duplicateDesc $someAEDesc]
	} elseif {[tclAE::subdesc::isSubDescriptor $someAEDesc]} {
		set theAEDesc [tclAE::subdesc::toDesc $someAEDesc]
	} else {
		# assume it's an AEGizmo
		set theAEDesc [tclAE::build $someAEDesc]
	}
	
	return $theAEDesc
}

proc tclAE::_eventHandler {str} {
	global tclAE::eventHandlers
	
	set theEvent [tclAE::parse::event $str]
	
	global $theEvent
	set eventClass [set ${theEvent}(evcl)]
	set eventID [set ${theEvent}(evid)]

	if {[catch {set handlerInfo [set tclAE::eventHandlers(${eventClass}${eventID})]}]} {
		tclAE::disposeDesc $theEvent
		error::throwOSErr -1717
	}
	
	# Unused by this code. Here for compatibility with Alpha 8.
	set theReply [tclAE::createList 1]
	
	set result [eval [lindex $handlerInfo 0] $theEvent $theReply]
	
	tclAE::disposeDesc $theEvent
	
	# Alpha <8 cannot send replies, so throw it away 8^(
	tclAE::disposeDesc $theReply
	
	return $result
}

proc tclAE::subdesc::_getDescIfSubDesc {theAESubDesc} {
	if {[tclAE::subdesc::isSubDescriptor $theAESubDesc]} {
		global $theAESubDesc
		return [set ${theAESubDesc}(dataHandle)]
	} else {
		return $theAESubDesc
	}
}

proc tclAE::getAttributeData {args} {return [eval tclAE::getKeyData $args]}
proc tclAE::getAttributeDesc {args} {return [eval tclAE::getKeyDesc $args]}

tclAE::desc
tclAE::coerce
tclAE::loadprint

}

# ≈÷É≈÷É≈÷É≈÷É unimplemented AEM calls ≈÷É≈÷É≈÷É≈÷É #

proc tclAE::createAppleEvent {theAEEventClass theAEEventID &target returnID transactionID &result} {beep; status::msg "tclAE::createAppleEvent not implemented"}
proc tclAE::deleteParam {&theAppleEvent theAEKeyword} {beep; status::msg "tclAE::deleteParam not implemented"}
proc tclAE::getArray {&theAEDescList arrayType arrayPtr maximumSize &itemType &itemSize itemCount} {beep; status::msg "tclAE::getArray not implemented"}
proc tclAE::getInteractionAllowed {&level} {beep; status::msg "tclAE::getInteractionAllowed not implemented"}
proc tclAE::getParamDesc {&theAppleEvent AEKeyword desiredType &result} {beep; status::msg "tclAE::getParamDesc not implemented"}
proc tclAE::getParamPtr {&theAppleEvent theAEKeyword desiredType &typeCode dataPtr maximumSize &actualSize} {beep; status::msg "tclAE::getParamPtr not implemented"}
proc tclAE::getSpecialHandler {functionClass &handler isSysHandler} {beep; status::msg "tclAE::getSpecialHandler not implemented"}
proc tclAE::getTheCurrentEvent {&theAppleEvent} {beep; status::msg "tclAE::getTheCurrentEvent not implemented"}
proc tclAE::installSpecialHandler {functionClass handler isSyshandler} {beep; status::msg "tclAE::installSpecialHandler not implemented"}
proc tclAE::interactWithUser {timeOutInTicks nmReqPtr idleProc} {beep; status::msg "tclAE::interactWithUser not implemented"}
proc tclAE::processAppleEvent {&theEventRecord} {beep; status::msg "tclAE::processAppleEvent not implemented"}
proc tclAE::putArray {&theAEDescList arrayType arrayPtr itemType itemSize itemCount} {beep; status::msg "tclAE::putArray not implemented"}
proc tclAE::putAttributeDesc {&theAppleEvent theAEKeyword &theAEDesc} {beep; status::msg "tclAE::putAttributeDesc not implemented"}
proc tclAE::putAttributePtr {&theAppleEvent theAEKeyword typeCode dataPtr dataSize} {beep; status::msg "tclAE::putAttributePtr not implemented"}
proc tclAE::putParamDesc {&theAppleEvent theAEkeyword &theAEDesc} {beep; status::msg "tclAE::putParamDesc not implemented"}
proc tclAE::putParamPtr {&theAppleEvent theAEKeyword typeCode dataPtr dataSize} {beep; status::msg "tclAE::putParamPtr not implemented"}
proc tclAE::removeSpecialHandler {functionClass handler isSysHandler} {beep; status::msg "tclAE::removeSpecialHandler not implemented"}
proc tclAE::resetTimer {&reply} {beep; status::msg "tclAE::resetTimer not implemented"}
proc tclAE::resumeTheCurrentEvent {&theAppleEvent &reply dispatcher handlerRefcon} {beep; status::msg "tclAE::resumeTheCurrentEvent not implemented"}
proc tclAE::setInteractionAllowed {level} {beep; status::msg "tclAE::setInteractionAllowed not implemented"}
proc tclAE::setTheCurrentEvent {&theAppleEvent} {beep; status::msg "tclAE::setTheCurrentEvent not implemented"}
proc tclAE::sizeOfAttribute {&theAppleEvent theAEKeyword &typeCode &dataSize} {beep; status::msg "tclAE::sizeOfAttribute not implemented"}
proc tclAE::sizeOfKeyDesc {&theAERecord theAEKeyword &typeCode &dataSize} {beep; status::msg "tclAE::sizeOfKeyDesc not implemented"}
proc tclAE::sizeOfNthItem {&theAEDescList index &typeCode &dataSize} {beep; status::msg "tclAE::sizeOfNthItem not implemented"}
proc tclAE::sizeOfParam {&theAEEvent theAEKeyword &typeCode &dataSize} {beep; status::msg "tclAE::sizeOfParam not implemented"}
proc tclAE::suspendTheCurrentEvent {&theAppleEvent} {beep; status::msg "tclAE::suspendTheCurrentEvent not implemented"}


