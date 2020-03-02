## -*-Tcl-*-
 # ###################################################################
 #  TclAE - Coersion functions for AEGizmo values
 # 
 #  FILE: "aecoerce.tcl"
 #                                    created: 11/18/98 {11:15:36 PM} 
 #                                last update: 11/2/00 {8:30:08 AM} 
 #                                    version: 2.0
 #  Author: Jonathan Guyer
 #  E-mail: jguyer@his.com
 #    mail: Alpha Cabal
 #          POMODORO no seisan
 #     www: http://www.his.com/jguyer/
 #  
 # ========================================================================
 #               Copyright (c) 1998-2000 Jonathan Guyer
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
 #  1998-11-18 JEG 1.0 original
 # ###################################################################
 ##

namespace eval tclAE::coerce {}

proc tclAE::coerce {} {}

proc tclAE::coerce::identity {typeCode data toType resultDesc} {
	tclAE::replaceDescData $resultDesc $toType $data
}

proc tclAE::coerce::true>bool {typeCode data toType resultDesc} {
	tclAE::replaceDescData $resultDesc $toType [binary format c 1]
}

proc tclAE::coerce::fals>bool {typeCode data toType resultDesc} {
	tclAE::replaceDescData $resultDesc $toType [binary format c 0]
}

proc tclAE::coerce::bool>shor {typeCode data toType resultDesc} {
	tclAE::replaceDescData $resultDesc $toType [coerce bool -x $data -x shor]
}

proc tclAE::coerce::shor>long {typeCode data toType resultDesc} {
	tclAE::replaceDescData $resultDesc $toType [coerce shor -x $data -x long]
}

proc tclAE::coerce::long>shor {typeCode data toType resultDesc} {
	tclAE::replaceDescData $resultDesc $toType [coerce long -x $data -x shor]
}

proc tclAE::coerce::long>TEXT {typeCode data toType resultDesc} {
	tclAE::replaceDescData $resultDesc $toType [coerce long -x $data -x TEXT]
}

proc tclAE::coerce::shor>TEXT {typeCode data toType resultDesc} {
	tclAE::replaceDescData $resultDesc $toType [coerce shor -x $data -x TEXT]
}

proc tclAE::coerce::TEXT>long {typeCode data toType resultDesc} {
	tclAE::replaceDescData $resultDesc $toType [coerce TEXT -x $data -x long]
}

proc tclAE::coerce::TEXT>shor {typeCode data toType resultDesc} {
	tclAE::replaceDescData $resultDesc $toType [coerce TEXT -x $data -x shor]
}


proc tclAE::coerce::alis>TEXT {typeCode data toType resultDesc} {
	tclAE::replaceDescData $resultDesc TEXT \
	  [tclAE::build::resultData 'MACS' core getd \
	  	---- "obj {form:alis, want:cobj, from:'null'(), \
			seld:[tclAE::build::coercion [tclAE::build::hexd $data] "alis"]
		}" \
		rtyp TEXT
	  ]
}

proc tclAE::coerce::TEXT>alis {typeCode data toType resultDesc} {
	tclAE::replaceDescData $resultDesc $toType [coerce TEXT -x $data -x alis]
}

proc tclAE::coerce::fss>TEXT {typeCode data toType resultDesc} {
	tclAE::replaceDescData $resultDesc $toType [specToPathName $data]
}

proc tclAE::coerce::register {from to proc} {
	tclAE::installCoercionHandler $from $to $proc
}

proc tclAE::coerce::apply {AEDesc to {typed 0}} {
	global tclAE::coerce::coercions tclAE::coerce::overrides tclAE::coerce::noCoerce
	
	set from [tclAE::desc::_getKey $AEDesc descriptorType]
	set value [tclAE::desc::_getKey $AEDesc value]
	
	if {$from == "list"} {
		set msg "Cannot coerce a list"
		error $msg "" [list AECoerce 18 $msg]
	} 
	
	# no need to do anything for an identity coercion
	if {$from != $to} {		
		set coerce [list $from $to]
		
		foreach noCoerce ${tclAE::coerce::noCoerce} {
			if {[string match $noCoerce $coerce]} {
				# return what was sent
				return [list $from $value]
			} 	
		}
		
		# coercion not blocked, so see if we know how to do it
		if {[set i [lsearch -glob ${tclAE::coerce::overrides} [list $from $to *]]] != -1} {
			set value [[lindex [lindex ${tclAE::coerce::overrides} $i] 2] $value]
		} elseif {[set i [lsearch -glob ${tclAE::coerce::coercions} [list $from $to *]]] != -1} {
			set value [[lindex [lindex ${tclAE::coerce::coercions} $i] 2] $value]
		} else {
			# -1700 is a coercion failure.
			# That's not exactly what we want; coercion didn't
			# fail, we just don't know how to do it.
			set msg "Can't coerce '$from' to '$to'"
			error $msg "" [list AECoerce 1700 $msg]
		}
	}
	if {$typed} {
        return [tclAE::desc::makeTypeValue $to $value]
	} else {
		return $value
	} 
}

# ≈÷É≈÷É≈÷É≈÷É Default Coercions ≈÷É≈÷É≈÷É≈÷É #

if {([info tclversion] < 8.0)
||	![info exists tclAE_version] 
||  ($tclAE_version < 2.0)} {
	
	tclAE::installCoercionHandler "null" "TEXT" tclAE::coerce::null>TEXT
	tclAE::installCoercionHandler "long" "TEXT" tclAE::coerce::long>TEXT
	tclAE::installCoercionHandler "shor" "TEXT" tclAE::coerce::shor>TEXT
	# used ?
	tclAE::installCoercionHandler "hexd" "alis" tclAE::coerce::alis>TEXT
	tclAE::installCoercionHandler "alis" "TEXT" tclAE::coerce::alis>TEXT
	# used ?
	tclAE::installCoercionHandler "fss " "TEXT" tclAE::coerce::fss>TEXT
	tclAE::installCoercionHandler "TEXT" "alis" tclAE::coerce::TEXT>alis
	tclAE::installCoercionHandler "TEXT" "long" tclAE::coerce::TEXT>long
	tclAE::installCoercionHandler "TEXT" "shor" tclAE::coerce::TEXT>shor
	tclAE::installCoercionHandler "shor" "long" tclAE::coerce::shor>long
	tclAE::installCoercionHandler "long" "shor" tclAE::coerce::long>shor
	tclAE::installCoercionHandler "enum" "type" tclAE::coerce::identity

	tclAE::installCoercionHandler "true" "bool" tclAE::coerce::true>bool
	tclAE::installCoercionHandler "fals" "bool" tclAE::coerce::fals>bool
	tclAE::installCoercionHandler "bool" "shor" tclAE::coerce::bool>shor
	tclAE::installCoercionHandler "bool" "TEXT" tclAE::coerce::bool>shor


}
