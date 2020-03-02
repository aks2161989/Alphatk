## -*-Tcl-*- (nowrap)
 # ###################################################################
 #  TclAE - Parsing functions for AEGizmo strings
 # 
 #  FILE: "aeparse.tcl"
 #                                    created: 7/26/97 {6:44:05 PM} 
 #                                last update: 9/8/02 {9:35:56 PM} 
 #  Author: Jonathan Guyer
 #  E-mail: jguyer@his.com
 #    mail: Alpha Cabal
 #          POMODORO no seisan
 #     www: http://www.his.com/jguyer/
 #  
 # ========================================================================
 #               Copyright (c) 1997-2002 Jonathan Guyer
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
 #  1997-07-26 JEG 1.0 original
 # ###################################################################
 ##

## 
 # Note that 'try' is used very sparingly in this code because, although
 # syntactically pleasing, it is too slow.  As it is, there are too many
 # 'catch'es (Not anymore. Catch is gone).
 ##

## 
 # With the exception of tclAE::parse::event, the parsers in this package 
 # take the _name_ of a string variable as their argument and the 
 # string is parsed in place.  Because it will typically be used to 
 # parse the output of ≈¥ùAEBuild -r≈¥ú, tclAE::parse::event takes a string 
 # as its argument.  Since there is no forseeable reason for 
 # external code to call any parser but tclAE::parse::event, this 
 # distinction should not be a problem.
 ##

namespace eval tclAE::parse {}

if {([info tclversion] < 8.0)
||	![info exists tclAE_version] 
||  ($tclAE_version < 2.0)} {
	
# ≈÷É≈÷É≈÷É≈÷É Grammar Rules ≈÷É≈÷É≈÷É≈÷É #

# ≈÷É≈÷É≈÷É≈÷É  Public  ≈÷É≈÷É≈÷É≈÷É #

## 
 # event ::= ident '\' ident keywordlist
 # 
 # NOTE:	This is the only parsing routine in this package 
 # 			which takes a string as an argument and, thus, can
 # 			have the output of ≈¥ùAEBuild -r≈¥ú piped into it.
 ##
proc tclAE::parse::event {chars args} {
	if {[regexp {^([^\\]*)\\(.*)$} $chars blah class chars]} {
	
		# Make sure $class is formatted correctly
		tclAE::parse::ident class class
		tclAE::parse::ident chars eventID
		
		tclAE::parse::structure chars event
		
		if {[string length [string trimleft $chars]] != 0} {
			set errorMsg "Unexpected extra stuff past end"
			error $errorMsg "" [list AEParse 3 $errorMsg]
		} 
		
		global $event
		# Set these manually, as we don't want them to show up as record keys
		set ${event}(descriptorType)	"aevt"
		set ${event}(basicType)			"aevt"
		set ${event}(evcl)				$class
		set ${event}(evid)				$eventID
		
	} else {
		set errorMsg "Unexpected end of format string" 
		error $errorMsg "" [list AEParse 2 $errorMsg]
	}
	
	return $event
}

# ≈÷É≈÷É≈÷É≈÷É  Private  ≈÷É≈÷É≈÷É≈÷É #

## 
 # ident ::= identchar (identchar |	digit)*	   ≈¥äPadded/truncated
 #			 ' character* '					   to exactly 4	chars
 ##
proc tclAE::parse::ident {charsPtr resultPtr} {
	upvar $charsPtr chars
	upvar $resultPtr result
	
	set identchar {[^][(){} \r\t\n0-9'≈¥ﬂ≈¥ÿåÇåÈ:,@]}
	if {![regexp "^\\s*(${identchar}(${identchar}|\[0-9\])*)(.*)" $chars blah type blah chars]} {
		if {![regexp "^\\s*'(\[^'\]*)'(.*)" $chars blah type chars]} {
			set result "no ident"
			return 0
		}
	}
	set result [format "%-4.4s" $type]
	return 1
}

## 
 # obj ::= data				 ≈¥äSingle AEDesc; shortcut for (data)
 #		   structure		 ≈¥äUn-coerced structure
 #		   ident structure	 ≈¥äCoerced to some other	type
 ##
proc tclAE::parse::obj {charsPtr resultPtr} {
	upvar $charsPtr chars
	upvar $resultPtr result
	
	if {![catch {tclAE::parse::event $chars} result]} {
		return 1
	} elseif {[tclAE::parse::data chars result]} {
		global $result
		if {[set ${result}(descriptorType)] == "enum"} {
			if {[tclAE::parse::structure chars structure]} {
				global $structure
				
				set toType [coerce TEXT -x [set ${result}(dataRecord)] TEXT]
# 				binary scan [set ${result}(dataRecord)] a4 toType
				tclAE::disposeDesc $result
				
				if {[catch {
					set coerceDesc [tclAE::_descriptorProc $structure coerceDesc]
					set result [$coerceDesc $structure $toType]
					tclAE::disposeDesc $structure
				}]} {
					set ${structure}(descriptorType) $toType
					set result $structure
				}
			}
		} 
	} else {
		return [tclAE::parse::structure chars result]
	}
	return 1
}

## 
 # structure ::= ( data	)		   ≈¥äSingle AEDesc
 #				 [ objectlist ]	   ≈¥äAEList type
 #				 { keywordlist }   ≈¥äAERecord type
 ##
proc tclAE::parse::structure {charsPtr resultPtr} {
	upvar $charsPtr chars
	upvar $resultPtr result
	
	if {[regexp {^\s*\((.*)} $chars blah chars]} {
		if {[tclAE::parse::data chars result]} {
			if {![regexp {^\s*\)(.*)} $chars blah chars]} {
				set msg "Missing ≈¥ﬂ)≈¥ÿ after data value"
				error $msg "" [list AEParse 13 $msg]
			}
		} else {
			if {$result == "no data"} {
				if {[regexp {^\s*\)(.*)} $chars blah chars]} {
					set result [tclAE::createDesc "null"]
				} else {
					set msg "Missing ≈¥ﬂ)≈¥ÿ after data value"
					error $msg "" [list AEParse 13 $msg]
				}
			}
		}
	} elseif {![tclAE::parse::objectlist chars result]} {
		if {![tclAE::parse::reco chars result]} {
			set result "no structure"
			return 0
		}
	}
	
	return 1
}

## 
 #       list ::= [ objectlist ]
 # objectlist ::= åÇblankåÈ			  ≈¥äComma-separated list	of things
 #				  obj [	, obj ]*
 #				  
 # NOTE: proc is named 'objectlist' to avoid namespace collision
 # and because the distinction is irrelevant here. 
 # tclAE::parse::objectlist expects to find the [ ] brackets.
 ##
proc tclAE::parse::objectlist {charsPtr resultPtr} {
    upvar $charsPtr chars
    upvar $resultPtr theList
    
    if {[regexp {^\s*\[(.*)} $chars blah chars]} {
        set theList [tclAE::createList]
        global $theList
        if {![regexp {^\s*\](.*)} $chars blah chars]} {
            while 1 {
                tclAE::parse::obj chars item
                lappend ${theList}(dataRecord) $item
                regexp {^\s*(.)(.*)} $chars blah next chars
                if {$next == "\]"} {
                    break
                } elseif {$next != ","} {
                    tclAE::disposeDesc $theList
                    set msg "Expected ≈¥ﬂ,≈¥ÿ or ≈¥ﬂ\]≈¥ÿ"
                    error $msg "" [list AEParse 14 $msg]
                }		
            }
        }
        return 1
    } else {
        set theList "no list"
        return 0
    }
}

## 
 # keywordpair ::= ident : obj		  ≈¥äKeyword/value pair
 ##
proc tclAE::parse::keywordpair {charsPtr resultPtr record} {
    upvar $charsPtr chars
    upvar $resultPtr result
    
    if {[tclAE::parse::ident chars keyword]} {
        if {[regexp {^\s*:(.*)} $chars blah chars]} {
            tclAE::parse::obj chars value
            
            # too much overhead in tclAE::desc::_reco_putKeyDesc
            global $record
            if {[info exists ${record}($keyword)]} {
                catch {tclAE::disposeDesc [set ${record}($keyword)]}
            } 
            set ${record}($keyword) $value
            
            if {[lsearch -exact [set ${record}(dataRecord)] $keyword] == -1} {
                lappend ${record}(dataRecord) $keyword    
            } 
        } else {
            set msg "Missing ≈¥ﬂ:≈¥ÿ after keyword in record"
            error $msg "" [list AEParse 17 $msg]
        }
    } else {
        if {$keyword == "no ident"} {
            set msg "Missing keyword in record" 
            error $msg "" [list AEParse 16 $msg]
        }
    }
}

## 
 # record ::= { keywordlist }
 # keywordlist ::= åÇblankåÈ      ≈¥äList of said pairs
 #                              keywordpair [ , keywordpair ]*
 ##
proc tclAE::parse::reco {charsPtr resultPtr} {
    upvar $charsPtr chars
    upvar $resultPtr record
    
    if {[regexp {^\s*\{(.*)} $chars blah chars]} {
        set record [tclAE::createList 1]		
        if {![regexp {^\s*\}(.*)} $chars blah chars]} {
            while 1 {
                tclAE::parse::keywordpair chars pair $record
                regexp {^\s*(.)(.*)} $chars blah next chars
                if {$next == "\}"} {
                    break
                } elseif {$next != ","} {
                    tclAE::disposeDesc $record
                    set msg "Expected ≈¥ﬂ,≈¥ÿ or ≈¥ﬂ\}≈¥ÿ"
                    error $msg "" [list AEParse 15 $msg]
                }
            }
        }
        return 1
    } else {
        set record "no reco"
        return 0
    }
}

 # integer ::=	[ - ] digit+	≈¥äJust as in C
 # string ::=	≈¥ﬂ (character)* ≈¥ÿ
 # hexstring ::=	åÇ (hexdigit | whitespace)* åÈ	≈¥äEven no. of digits, please
 # data	::=	@		   ≈¥äGets appropriate data from fn param
 #			integer	   ≈¥ä'shor' or 'long' unless	coerced
 #			ident	   ≈¥äA 4-char type code ('type')	unless coerced
 #			string	   ≈¥äUnterminated text; 'TEXT' type unless coerced
 #			hexstring  ≈¥äRaw	hex	data; must be coerced to some type!
 ##
proc tclAE::parse::data {charsPtr resultPtr} {
	upvar $charsPtr chars
	upvar $resultPtr result
	
	if {[regexp {^\s*@(.*)} $chars blah chars]} {
        set result [tclAE::createDesc "@" "@"]
	} elseif {[regexp {^\s*(-?[0-9]+)(.*)$} $chars blah long chars]} {
		if {[expr {$long > 32768}] || [expr {$long < -32767}]} {
			set result [tclAE::createDesc "long" [coerce TEXT $long -x long]]
# 			set result [tclAE::createDesc "long" [binary format I $long]]
		} else {
			set short [coerce TEXT $long -x shor]
			set result [tclAE::createDesc "shor" [coerce TEXT $long -x shor]]
# 			set result [tclAE::createDesc "shor" [binary format S $long]]
		}
	} elseif {[regexp {^\s*≈¥ﬂ([^≈¥ÿ]*)≈¥ÿ(.*)} $chars blah TEXT chars]} {
        set result [tclAE::createDesc "TEXT" [coerce TEXT $TEXT -x TEXT]]
#         set result [tclAE::createDesc "TEXT" [binary format a* $TEXT]]
	} elseif {[regexp {^\s*åÇ([0-9a-fA-F \r\t\n]*)åÈ(.*)$} $chars blah hexd chars]} {
        set result [tclAE::createDesc "hexd" $hexd]
	} elseif {[tclAE::parse::ident chars ident]} {
		set result [tclAE::createDesc "enum" [coerce TEXT $ident -x TEXT]]
# 		set result [tclAE::createDesc "enum" [binary format a* $ident]]
	} else {
		if {$ident == "no ident"} {
			set result "no data"
			return 0
		}
    }						  
	return 1
}

}

# ≈÷É≈÷É≈÷É≈÷É Utilities ≈÷É≈÷É≈÷É≈÷É #

## 
 # -------------------------------------------------------------------------
 # 
 # "tclAE::parse::throwIfError" --
 # 
 #  Look for error keys in 'event' and, if they exist, throw them 
 # -------------------------------------------------------------------------
 ##
proc tclAE::parse::throwIfError {event} {
	global error::OSErr errorCode $event
	
	set errn 0
	set errs ""
	
    # No error if these keywords are missing
	catch {set errn [tclAE::getKeyData $event "errn" "long"]}

	catch {set errs [tclAE::getKeyData $event "errs" "TEXT"]}
	
	if {[info exists error::OSErr($errn)]} {
		if {[string length $errs] == 0} {
			set errs [lindex [set error::OSErr($errn)] 2]
		} 
		set errn [set error::OSErr($errn)] 
	} 
	
	if {(([string length $errn] != 0) && ($errn != 0))
	||	([string length $errs] != 0)} {
		error $errs "" $errn
	}
}

## 
 # -------------------------------------------------------------------------
 # 
 # "tclAE::parse::keywordValue" --
 # 
 #  This is just a wrapper from the old notation to the new one. 
 #  Don't use it in new code.
 # 
 # Results:
 #  The value of $keyword in $record
 # -------------------------------------------------------------------------
 ##
proc tclAE::parse::keywordValue {keyword record {typed 0}} {
	if {$typed} {
		return [tclAE::getKeyDesc $record $keyword]
	} else {
		return [tclAE::getKeyData $record $keyword]
	}
}

proc tclAE::parse::queued {result} {
	# Something's goofy with the
	# form of 'result' as returned by AEPrint
	
	regsub -all -- {\\\{} $result "{" result
	regsub -all -- {\\\}} $result "}" result
	
	# Get the direct object of the AppleEvent result and
	# put it into a form palatable to Alpha Tcl
	return [tclAE::parse::event $result]
}

proc tclAE::parse::queuedResult {event} {
    # Convert queued AEGizmos event into Tcl form
    set event [tclAE::parse::queued $event]
    
	# Get the direct object of the queued AppleEvent
    set result [tclAE::getKeyDesc $event ----]
    	
    tclAE::disposeDesc $event

	return $result
}


