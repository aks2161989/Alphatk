## -*-Tcl-*-
 # ###################################################################
 #  TclAE - Descriptor data structure functions for AEGizmo values
 # 
 #  FILE: "aedesc.tcl"
 #                                    created: 7/28/99 {6:55:33 PM} 
 #                                last update: 1/3/01 {5:11:14 PM} 
 #                                    version: 1.0
 #  Author: Jonathan Guyer
 #  E-mail: jguyer@his.com
 #    mail: Alpha Cabal
 #          POMODORO no seisan
 #     www: http://www.his.com/jguyer/
 #  
 # ========================================================================
 #               Copyright (c) 1999-2001 Jonathan Guyer
 #                         All rights reserved
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
 #  1999-07-28 JEG 1.0 original
 # ###################################################################
 ##

namespace eval tclAE::desc {}
namespace eval tclAE::subdesc {}

proc tclAE::desc {} {}

if {([info tclversion] < 8.0)
||	![info exists tclAE_version] 
||  ($tclAE_version < 2.0)} {
	
# ≈÷É≈÷É≈÷É≈÷É TclAE objects ≈÷É≈÷É≈÷É≈÷É #

proc tclAE::desc::isDescriptor {theAEDesc} {
	global tclAE::desc::wildcard $theAEDesc
	
	return [expr {[string match ${tclAE::desc::wildcard} $theAEDesc] \
	  && [info exists $theAEDesc]}]
}

proc tclAE::subdesc::isSubDescriptor {theAESubDesc} {
	global tclAE::subdesc::wildcard $theAESubDesc
	
	return [expr {[string match ${tclAE::subdesc::wildcard} $theAESubDesc] \
	  && [info exists $theAESubDesc]}]
}

################################################################
#                                                              #
#   GET AWAY FROM HERE! THIS STUFF IS NONE OF YOUR BUSINESS!   #
#                                                              #
################################################################

ensureset tclAE::desc::_next -1
ensureset tclAE::subdesc::_next -1

## 
 # -------------------------------------------------------------------------
 # 
 # "tclAE::desc::_form" --
 # 
 # Results:
 #  AEDesc identifier for the item numbered $index.
 # -------------------------------------------------------------------------
 ##
proc tclAE::desc::_form {index} {
    # This should be the only place the descriptor syntax is hard-coded
    return "tclAEDesc.$index"
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tclAE::subdesc::_form" --
 # 
 # Results:
 #  AESubDesc identifier for the item numbered $index.
 # -------------------------------------------------------------------------
 ##
proc tclAE::subdesc::_form {index} {
    # This should be the only place the sub-descriptor syntax is hard-coded
    return "tclAESubDesc.$index"
}

proc tclAE::desc::inheritDescriptor {typeCode fromType} {
	global tclAE::desc::procs
	
	foreach method [array names tclAE::desc::procs "[quote::Find ${fromType}].*"] {
		set tclAE::desc::procs(${typeCode}[string range $method 4 end]) \
		  [set tclAE::desc::procs($method)]
	}
}

set  tclAE::desc::wildcard   [tclAE::desc::_form "*"]
set  tclAE::subdesc::wildcard   [tclAE::subdesc::_form "*"]


tclAE::desc::inheritDescriptor "****" ""

set tclAE::desc::procs(****.coerceDesc)		tclAE::desc::_****_coerceDesc
set tclAE::desc::procs(****.disposeDesc)	tclAE::desc::_****_disposeDesc
set tclAE::desc::procs(****.duplicateDesc)	tclAE::desc::_****_duplicateDesc
set tclAE::desc::procs(****.getData)		tclAE::desc::_****_getData
set tclAE::desc::procs(****.print)			tclAE::desc::_****_print

set tclAE::desc::procs(enum.getData)		tclAE::desc::_enum_getData

tclAE::desc::inheritDescriptor "list" "****"

set tclAE::desc::procs(list.coerceDesc)		tclAE::desc::_list_coerceDesc
set tclAE::desc::procs(list.countItems)		tclAE::desc::_list_countItems
set tclAE::desc::procs(list.deleteItem)		tclAE::desc::_list_deleteItem
set tclAE::desc::procs(list.disposeDesc)	tclAE::desc::_list_disposeDesc
set tclAE::desc::procs(list.duplicateDesc)	tclAE::desc::_list_duplicateDesc
set tclAE::desc::procs(list.getData)		tclAE::desc::_list_getData
set tclAE::desc::procs(list.getNthData)		tclAE::desc::_list_getNthData
set tclAE::desc::procs(list.getNthDesc)		tclAE::desc::_list_getNthDesc
set tclAE::desc::procs(list.putData)		tclAE::desc::_list_putData
set tclAE::desc::procs(list.putDesc)		tclAE::desc::_list_putDesc
set tclAE::desc::procs(list.print)			tclAE::desc::_list_print


tclAE::desc::inheritDescriptor "reco" "list"

set tclAE::desc::procs(reco.coerceDesc)		tclAE::desc::_reco_coerceDesc
set tclAE::desc::procs(reco.deleteItem)		tclAE::desc::_reco_deleteItem
set tclAE::desc::procs(reco.deleteKeyDesc)	tclAE::desc::_reco_deleteKeyDesc
set tclAE::desc::procs(reco.disposeDesc)	tclAE::desc::_reco_disposeDesc
set tclAE::desc::procs(reco.duplicateDesc)	tclAE::desc::_reco_duplicateDesc
set tclAE::desc::procs(reco.getKeyData)		tclAE::desc::_reco_getKeyData
set tclAE::desc::procs(reco.getKeyDesc)		tclAE::desc::_reco_getKeyDesc
set tclAE::desc::procs(reco.getNthData)		tclAE::desc::_reco_getNthData
set tclAE::desc::procs(reco.getNthDesc)		tclAE::desc::_reco_getNthDesc
set tclAE::desc::procs(reco.putData)		tclAE::desc::_reco_putData
set tclAE::desc::procs(reco.putDesc)		tclAE::desc::_reco_putDesc
set tclAE::desc::procs(reco.putKeyData)		tclAE::desc::_reco_putKeyData
set tclAE::desc::procs(reco.putKeyDesc)		tclAE::desc::_reco_putKeyDesc
set tclAE::desc::procs(reco.print)			tclAE::desc::_reco_print

# The AEM seems to allow these, but they don't really mean anything for a 'reco'
unset tclAE::desc::procs(reco.getData)
# unset tclAE::desc::procs(reco.putDesc)


tclAE::desc::inheritDescriptor "aevt" "reco"

set tclAE::desc::procs(aevt.duplicateDesc)	tclAE::desc::_aevt_duplicateDesc



# ≈÷É≈÷É≈÷É≈÷É  '****' method handlers  ≈÷É≈÷É≈÷É≈÷É #

proc tclAE::desc::_****_coerceDesc {theAEDesc toType} {
	global $theAEDesc
	
	set typeCode [set ${theAEDesc}(descriptorType)]
	set data [set ${theAEDesc}(dataRecord)]
	
    return [tclAE::coerceData $typeCode $data $toType]
}

proc tclAE::desc::_****_disposeDesc {theAEDesc} {
    global $theAEDesc
    unset $theAEDesc
}

proc tclAE::desc::_****_duplicateDesc {theAEDesc} {
	global $theAEDesc

	return [tclAE::createDesc [set ${theAEDesc}(descriptorType)] \
								[set ${theAEDesc}(dataRecord)]]
}

proc tclAE::desc::_****_getData {theAEDesc {desiredType ****} {typeCodePtr ""}} {
    global $theAEDesc
    
    upvar $typeCodePtr typeCode
    
	set descriptorType [set ${theAEDesc}(descriptorType)]
    set data [set ${theAEDesc}(dataRecord)]  
    	
	switch $desiredType {
      "****" {
		set typeCode $descriptorType
		switch $typeCode {
		  "TEXT" {
			set data [coerce TEXT -x $data TEXT]
		  }
		  "bool" {
			set data [expr "0x${data}"]
		  }
		  "shor" {
			set data [coerce shor -x $data TEXT]
		  }
		  "long" {
			set data [coerce long -x $data TEXT]
		  }
		  "sing" {
			set data [coerce sing -x $data TEXT]
		  }
		  "doub" {
			set data [coerce doub -x $data TEXT]
		  }
		}
	  }
      "????" {
		set typeCode $descriptorType
	  }
	  default {
		set typeCode $desiredType
		set outAEDesc [tclAE::coerceData $descriptorType $data $desiredType]
		set data [tclAE::desc::_****_getData $outAEDesc]
		tclAE::disposeDesc $outAEDesc
      }
    }
	
	return $data
}

proc tclAE::desc::_enum_getData {theAEDesc {desiredType ****} {typeCodePtr ""}} {
    set data [tclAE::desc::_****_getData $theAEDesc $desiredType $typeCodePtr]
    binary scan $data a4 enum
    
    return $enum
}

# ≈÷É≈÷É≈÷É≈÷É  'list' method handlers  ≈÷É≈÷É≈÷É≈÷É #

proc tclAE::desc::_list_coerceDesc {theAEDescList toType} {
	global $theAEDescList
	
	if {$toType == "****"} {
		return [tclAE::desc::_list_duplicateDesc $theAEDescList]
	} else {
		set items [set ${theAEDescList}(dataRecord)]
		if {[llength $items] != 1} {
			# Can only coerce a one-item list
			error::throwOSErr -1700 "Couldn't coerce descriptor to '${toType}'"
		} 
		
		return [tclAE::coerceDesc [lindex $items 0] $toType]
	}
}

proc tclAE::desc::_list_countItems {theAEDescList} {
    global $theAEDescList
    return [llength [set ${theAEDescList}(dataRecord)]]    
}    

proc tclAE::desc::_list_deleteItem {theAEDescList index} {
    global $theAEDescList
	
	set data [set ${theAEDescList}(dataRecord)]
	if {($index < 0) 
	||  ($index >= [llength $data])} {
	    # index out of range
	    error::throwOSErr -1719 "Couldn't delete item from \"${theAEDescList}\""
	} 
	# remove the item
	tclAE::disposeDesc [lindex $data $index]
	set ${theAEDescList}(dataRecord) [lreplace $data $index $index]
}

proc tclAE::desc::_list_disposeDesc {theAEDescList} {
    global $theAEDescList
    
    # Destroy the list elements
    foreach item [set ${theAEDescList}(dataRecord)] {
		tclAE::disposeDesc $item
    }
    
    # Destroy the list data
    unset $theAEDescList
}

proc tclAE::desc::_list_duplicateDesc {theAEDescList} {
	global $theAEDescList

	set newAEDescList [tclAE::createList]
	global $newAEDescList
	set ${newAEDescList}(descriptorType) [set ${newAEDescList}(descriptorType)]
	
    # Duplicate the list items
    foreach item [set ${theAEDescList}(dataRecord)] {
		lappend ${newAEDescList}(dataRecord) \
		  [tclAE::_duplicateDesc $item]
    }
    
	return $newAEDescList
}

proc tclAE::desc::_list_getData {theAEDescList {desiredType ****} {typeCodePtr ""}} {
    global $theAEDescList
	
    upvar $typeCodePtr typeCode
    set typeCode [set ${theAEDescList}(descriptorType)]
    
	foreach item [set ${theAEDescList}(dataRecord)] {
		lappend data [tclAE::getData $item $desiredType]	
	}
	
	return $data
}

proc tclAE::desc::_list_getNthData {theAEDescList index {desiredType ****} {theAEKeywordPtr ""} {typeCodePtr ""}} {
    global $theAEDescList
	
	set data [set ${theAEDescList}(dataRecord)]
	if {($index < 0) 
	||  ($index >= [llength $data])} {
	    # index out of range
	    error::throwOSErr -1719 "Couldn't get item #${index} from \"${theAEDescList}\""
	} 
    upvar $theAEKeywordPtr theAEKeyword
	upvar $typeCodePtr typeCode
	
	set theAEKeyword "****"
	
	return [tclAE::getData [lindex $data $index] $desiredType typeCode]
}

proc tclAE::desc::_list_getNthDesc {theAEDescList index {desiredType ****} {theAEKeywordPtr ""}} {
    global $theAEDescList
	
	set data [set ${theAEDescList}(dataRecord)]
	if {($index < 0) 
	||  ($index >= [llength $data])} {
	    # index out of range
	    error::throwOSErr -1719 "Couldn't get item #${index} from \"${theAEDescList}\""
	} 
    upvar $theAEKeywordPtr theAEKeyword
	
	set theAEKeyword "****"
	
	return [tclAE::coerceDesc [lindex $data $index] $desiredType]
}

proc tclAE::desc::_list_putDesc {theAEDescList index theAEDesc} {
    global $theAEDescList
    
	set items [set ${theAEDescList}(dataRecord)]
	
	set copyAEDesc [tclAE::duplicateDesc $theAEDesc]
		
    if {($index < 0) || ($index == "end")} {
        lappend ${theAEDescList}(dataRecord) $copyAEDesc
    } elseif {$index >= [llength $items]} {
	    # index out of range
	    error::throwOSErr -1719 "Couldn't put AEDesc into item #${index} of \"${theAEDescList}\""
	} else {
		# Dispose of any AEDesc that may already be in this position
		catch {tclAE::disposeDesc [lindex $items $index]}
		
		set ${theAEDescList}(dataRecord) \
		  [lreplace $items $index $index $copyAEDesc]
    }
}

# ≈÷É≈÷É≈÷É≈÷É  'reco' method handlers  ≈÷É≈÷É≈÷É≈÷É #

proc tclAE::desc::_reco_coerceDesc {theAERecord toType} {
	set newAERecord [tclAE::_duplicateDesc $theAERecord]
	
	global $newAERecord
	set ${newAERecord}(descriptorType) $toType
	
	return $newAERecord
}

proc tclAE::desc::_reco_deleteItem {theAERecord index} {
    global $theAERecord
	
	set data [set ${theAERecord}(dataRecord)]
	if {($index < 0) 
	||  ($index >= [llength $data]} {
	    # index out of range
	    error::throwOSErr -1719 "Couldn't delete item from \"${theAERecord}\""
	} 
	set keyword [lindex $data $index]
	
	# remove the item
	tclAE::disposeDesc [set ${theAERecord}($keyword)]
	unset ${theAERecord}($keyword)
	set ${theAERecord}(dataRecord) [lreplace $data $index $index]
}

proc tclAE::desc::_reco_deleteKeyDesc {theAERecord theAEKeyword} {
    global $theAERecord
    
	if {![info exists ${theAERecord}($theAEKeyword)]} {
	    # no such keyword
	    error::throwOSErr -1719	"Couldn't delete keyword '${theAEKeyword}' from \"${theAERecord}\""	
	} 
	
    # Dispose of the keyword data descriptor
    tclAE::disposeDesc [set ${theAERecord}($theAEKeyword)]
    
    # Delete keyword
    unset ${theAERecord}($theAEKeyword)    
	set ${theAERecord}(dataRecord) \
	  [lremove -all -- [set ${theAERecord}(dataRecord)] $theAEKeyword]
}

proc tclAE::desc::_reco_disposeDesc {theAERecord} {
    global $theAERecord
    
    # Destroy the record fields
    foreach keyword [set ${theAERecord}(dataRecord)] {
		tclAE::disposeDesc [set ${theAERecord}($keyword)]
    }
    
    # Destroy the record data
    unset $theAERecord
}

proc tclAE::desc::_reco_duplicateDesc {theAERecord} {
	global $theAERecord

	set newAERecord [tclAE::createList 1]
	global $newAERecord
	set ${newAERecord}(descriptorType) [set ${theAERecord}(descriptorType)]
	
    # Duplicate the record fields
    foreach keyword [set ${theAERecord}(dataRecord)] {
		set ${newAERecord}($keyword) \
		  [tclAE::_duplicateDesc [set ${theAERecord}($keyword)]]
		
		lappend ${newAERecord}(dataRecord) $keyword
    }
    
	return $newAERecord
}

proc tclAE::desc::_reco_getKeyData {theAERecord theAEKeyword {desiredType ****} {typeCodePtr ""}} {
    global $theAERecord
	
	set theAEKeyword [format "%-4.4s" $theAEKeyword]
    
	if {![info exists ${theAERecord}($theAEKeyword)]} {
		# no such keyword
		error::throwOSErr -1719 "Couldn't get keyword '${theAEKeyword}' from \"${theAERecord}\""
	}
	
    set theAEDesc [set ${theAERecord}($theAEKeyword)]

    upvar $typeCodePtr typeCode
	set data [tclAE::getData $theAEDesc $desiredType typeCode]

	return $data
}

proc tclAE::desc::_reco_getKeyDesc {theAERecord theAEKeyword {desiredType ****}} {
    global $theAERecord
	
	set theAEKeyword [format "%-4.4s" $theAEKeyword]
	
	if {![info exists ${theAERecord}($theAEKeyword)]} {
		# no such keyword
		error::throwOSErr -1719 "Couldn't get keyword '${theAEKeyword}' from \"${theAERecord}\""	
	}
    
    set theAEDesc [set ${theAERecord}($theAEKeyword)]

	return [tclAE::coerceDesc $theAEDesc $desiredType]
}

proc tclAE::desc::_reco_getNthData {theAERecord index {desiredType ****} {theAEKeywordPtr ""} {typeCodePtr ""}} {
    global $theAERecord
	
	set data [set ${theAERecord}(dataRecord)]
	if {($index < 0) 
	||  ($index >= [llength $data])} {
	    # index out of range
	    error::throwOSErr -1719 "Couldn't get item #${index} from \"${theAERecord}\""
	} 
    upvar $theAEKeywordPtr theAEKeyword
	upvar $typeCodePtr typeCode
	
	set theAEKeyword [lindex $data $index]
	
	return [tclAE::desc::_reco_getKeyData $theAERecord $theAEKeyword \
				$desiredType typeCode]
}

proc tclAE::desc::_reco_getNthDesc {theAERecord index {desiredType ****} {theAEKeywordPtr ""}} {
    global $theAERecord
	
	set data [set ${theAERecord}(dataRecord)]
	if {($index < 0) 
	||  ($index >= [llength $data])} {
	    # index out of range
	    error::throwOSErr -1719 "Couldn't get item #${index} from \"${theAERecord}\""
	} 
    upvar $theAEKeywordPtr theAEKeyword	
	set theAEKeyword [lindex $data $index]
	
	return [tclAE::desc::_reco_getKeyDesc $theAERecord $theAEKeyword $desiredType]
}

proc tclAE::desc::_reco_putDesc {theAERecord index theAEDesc} {
    global $theAERecord
    
	set keywords [set ${theAERecord}(dataRecord)]

    if {($index < 0) || ($index >= [llength $keywords])} {
	    # index out of range
	    error::throwOSErr -1719 "Couldn't put AEDesc into item #${index} of \"${theAERecord}\""
	} else {
		tclAE::desc::_reco_putKeyDesc $theAERecord [lindex $keywords $index] $theAEDesc
	}
}

proc tclAE::desc::_reco_putKeyDesc {theAERecord theAEKeyword theAEDesc} {
    global $theAERecord
    
	set theAEKeyword [format "%-4.4s" $theAEKeyword]
	
	# Dispose of any AEDesc that may already be in this position
	if {[info exists ${theAERecord}($theAEKeyword)]} {
		catch {tclAE::disposeDesc [set ${theAERecord}($theAEKeyword)]}
	} 
    
    set ${theAERecord}($theAEKeyword) [tclAE::duplicateDesc $theAEDesc]
    
	if {[lsearch -exact [set ${theAERecord}(dataRecord)] $theAEKeyword] == -1} {
		lappend ${theAERecord}(dataRecord) $theAEKeyword    
	} 
}

# ≈÷É≈÷É≈÷É≈÷É  'aevt' method handlers ≈÷É≈÷É≈÷É≈÷É #

# proc tclAE::desc::_aevt_send {level theAppleEvent $args} {
# 	global $theAppleEvent
# 	
#     set out [set ${theAppleEvent}(evcl)]
#     lappend out [set ${theAppleEvent}(evid)]
# 	
#     foreach keyword [set ${theAppleEvent}(dataRecord)] {
#         lappend out [tclAE::build::protect $keyword]
#         lappend	out [[set ${theAppleEvent}($keyword)] print]
#     }
#     return [eval tclAE::send $args $out]
# }

}

proc tclAE::desc::_aevt_duplicateDesc {theAppleEvent} {
	set newAppleEvent [tclAE::desc::_reco_duplicateDesc $theAppleEvent]

	global $theAppleEvent $newAppleEvent

	set ${newAppleEvent}(basicType)		"aevt"
	set ${newAppleEvent}(evcl)			[set ${theAppleEvent}(evcl)]
	set ${newAppleEvent}(evid)			[set ${theAppleEvent}(evid)]
    
	return $newAppleEvent
}



