## -*-Tcl-*-
 # ###################################################################
 #  TclAE - AppleEvent extension for Tcl
 # 
 #  FILE: "aeprint.tcl"
 #                                    created: 8/22/99 {4:59:36 PM} 
 #                                last update: 10/28/00 {10:37:00 PM} 
 #  Author: Jonathan Guyer
 #  E-mail: jguyer@his.com
 #    mail: Alpha Cabal
 #          POMODORO no seisan
 #     www: http://www.his.com/jguyer/
 #  
 # ========================================================================
 #               Copyright (c) 1999-2000 Jonathan Guyer
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
 #   Routines to print TclAE descriptors into AEGizmo form.
 # 
 #  History
 # 
 #  modified   by  rev reason
 #  ---------- --- --- -----------
 #  1999-08-22 JEG 1.0 original
 # ###################################################################
 ##

namespace eval tclAE::print {}

proc tclAE::loadprint {} {}

if {([info tclversion] < 8.0)
||	![info exists tclAE_version] 
||  ($tclAE_version < 2.0)} {
	
proc tclAE::desc::_****_print {theAEDesc} {
	global $theAEDesc
	
	set type [set ${theAEDesc}(descriptorType)]
	set data [set ${theAEDesc}(dataRecord)]
	
	if {[tclAE::desc::isDescriptor $data]} {
		return "${type}\([tclAE::print ${data}]\)"
	} else {
		return "${type}\([tclAE::build::hexd $data]\)"
	}
}

proc tclAE::desc::_list_print {listAEDesc} {
	global $listAEDesc
	
	set out {}
	foreach item [set ${listAEDesc}(dataRecord)] {
		lappend out [tclAE::print $item]
	}
	
	set out [join $out ", "]
	return "\[${out}\]"
}

proc tclAE::desc::_hexd_print {hexdAEDesc} {
	global $hexdAEDesc
    return [tclAE::build::hexd [set ${hexdAEDesc}(dataRecord)]]
}

proc tclAE::desc::_long_print {longAEDesc} {
	global $longAEDesc
	
	binary scan [set ${longAEDesc}(dataRecord)] I long
    return $long
}

proc tclAE::desc::_shor_print {shorAEDesc} {
	global $shorAEDesc
	
	binary scan [set ${shorAEDesc}(dataRecord)] S shor
    return $shor
}

proc tclAE::desc::_TEXT_print {TEXTAEDesc} {
	global $TEXTAEDesc
	
	set TEXT [set ${TEXTAEDesc}(dataRecord)]
	
	if {[string length $TEXT] == 0} {
		 return "[tclAE::build::coercion {} TEXT]"
	} else {
		set firstNull [string first "00" $TEXT]
		set firstOpenCurly [string first "D2" $TEXT]
		set firstCloseCurly [string first "D3" $TEXT]
		
		if {($firstNull > 0 && [expr {$firstNull % 2}] == 0)
		||	($firstOpenCurly > 0 && [expr {$firstOpenCurly % 2}] == 0)
		||	($firstCloseCurly > 0 && [expr {$firstCloseCurly % 2}] == 0)} {
			# AEGizmos string rep can't handle \x00, Å´ß, or Å´Ø.
			return [tclAE::build::coercion [tclAE::build::hexd $TEXT] TEXT]
		} else {
			binary scan $TEXT a* text
			return "Å´ß${text}Å´Ø"
		}
	}
	
}

proc tclAE::desc::_enum_print {enumAEDesc} {
	global $enumAEDesc
	
	binary scan [set ${enumAEDesc}(dataRecord)] a4 enum
    return [tclAE::build::protect $enum]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tclAE::desc::_reco_print" --
 # 
 #  Convert descriptor to an AE record, i.e., "{t1:l1, t2:l2, t3:l3, ...}".
 # -------------------------------------------------------------------------
 ##
proc tclAE::desc::_reco_print {theAERecord} {
	global $theAERecord
	
    set out {}    
	foreach keyword [set ${theAERecord}(dataRecord)] {
		set pair [tclAE::build::protect $keyword]
		append pair ":" [tclAE::print [set ${theAERecord}($keyword)]]
		lappend out $pair
	}
	
	set out [join $out ", "]
	
	set descriptorType [set ${theAERecord}(descriptorType)]
	if {($descriptorType == "reco")
	||  ($descriptorType == "aevt")} {
		return "\{${out}\}"	
	} else {
		return "[tclAE::build::protect $descriptorType]\{${out}\}"	
	}
}

proc tclAE::desc::_aevt_print {theAppleEvent} {
	global $theAppleEvent
	
    set out [set ${theAppleEvent}(evcl)]
    append out "\\" [set ${theAppleEvent}(evid)]
	append out [tclAE::desc::_reco_print $theAppleEvent]

	return $out
}

set tclAE::desc::procs(hexd.print)			tclAE::desc::_hexd_print
set tclAE::desc::procs(shor.print)			tclAE::desc::_shor_print
set tclAE::desc::procs(long.print)			tclAE::desc::_long_print
set tclAE::desc::procs(TEXT.print)			tclAE::desc::_TEXT_print
set tclAE::desc::procs(enum.print)			tclAE::desc::_enum_print
set tclAE::desc::procs(reco.print)			tclAE::desc::_reco_print
set tclAE::desc::procs(aevt.print)			tclAE::desc::_aevt_print


}

