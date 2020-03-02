# -*-Tcl-*- (nowrap)
# 
# File: ASterminology.tcl
# 	        Created: 2002-03-10 11:54:39
#     Last modification: 2004-05-05 16:32:54
# Author: Bernard Desgraupes
# e-mail: <bdesgraupes@easyconnect.fr>
# Web-page: <http://webperso.easyconnect.fr/bdesgraupes/alpha.html>
# Description:
#     This file is part of the AppleScript mode package. It  contains  the  procs
#     to write the scripting dictionary of an application. It relies on 
#     the proc tclAE::aete::parse::parseAETE which is defined by the TclAE.shlb 
#     library (in aete.tcl)
#  
# (c) Copyright: Bernard Desgraupes, 2002-2004
#     All rights reserved. This software is free software.  See  licensing  terms
#     in the AppleScript Help file.

proc ASterminology.tcl {} {}

namespace eval Scrp {}
namespace eval Scrp::Term {}

# Initialization of variables
proc Scrp::Term::InitTermParams {} {
    global scrp_term
    array set scrp_term {
	nbAddParms 	0
	nbClasses 	0
	nbCompOps 	0
	nbElems 	0
	nbEnumerators	0
	nbEnums 	0
	nbEvents 	0
	nbKeyforms 	0
	nbPropr 	0
	nbSuites 	0
	dyncount	0
	staticcount	0
	isbundle	0
	hasdynamic	0
	parsinglog	""
	parsedaete	""
    }
}


proc Scrp::OpenADictionary {} {
    global scrp_term ScrpmodeVars 
    
    Scrp::Term::InitTermParams
    if {![Scrp::Term::GetResourceFile]} {return} 
    if {[catch {resource open $scrp_term(resourcepath)} fileResId]} {
	alertnote "Error: $fileResId"
	return
    } 
    if {![Scrp::Term::CheckDynamicTerminology $fileResId]} {return} 
    
    if {$scrp_term(hasdynamic) && $ScrpmodeVars(launchToGetTerminology)} {
	set scrp_term(dyncount) [Scrp::Term::GetDynamicTerminology]
    } 
    
    # If the previous failed or if the flag launchToGetTerminology is not 
    # set, look for 'aete' resources.
    if {!$scrp_term(dyncount)} {
	set scrp_term(staticcount) [Scrp::Term::GetStaticTerminology $fileResId]
    } 
    catch {resource close $fileResId}
    Scrp::Term::DisplayResults
}


proc Scrp::Term::CheckDynamicTerminology {resid} {
    global scrp_term ScrpmodeVars
    set scrp_term(hasdynamic) [Scrp::Term::HasDynamicTerminology $resid]
    # If a dynamic terminology was detected but the launchToGetTerminology 
    # flag is not on, warn the user.
    if {$scrp_term(hasdynamic) && !$ScrpmodeVars(launchToGetTerminology)} {
	# Build the message
	set msg "\"[file tail $scrp_term(filepath)]\" has dynamic terminology.\
	  Do you want to get this dynamic terminology "
	if {![app::isRunning $scrp_term(creator)]} {
	    append msg "(the application will have to be launched) "
	} 
	append msg "or just look for static terminology?"
	# Display the alert
	switch [alert -t caution -k "Dynamic" -c "Static" -o "Cancel" $msg] {
	    "Dynamic" {
		set ScrpmodeVars(launchToGetTerminology) 1
		menu::buildSome appleScriptFlags
	    }
	    "Static" {}
	    "Cancel" {
		catch {resource close $resid}
		return 0
	    }
	}
    }
    return 1
}


proc Scrp::Term::DisplayResults {} {
    global scrp_term ScrpmodeVars
    if {!$scrp_term(staticcount) && !$scrp_term(hasdynamic)} {
	Scrp::displayResult "\r*** No scripting terminology for\
	  '[file tail $scrp_term(filepath)]'.\r" 0
	return
    }
    if {$scrp_term(parsinglog) != ""} {
	Scrp::displayResult "\r*** Terminology dict for \"[file tail $scrp_term(filepath)]\"\
	  written to:\r$scrp_term(parsinglog)" 0
    } elseif {!$ScrpmodeVars(launchToGetTerminology)} {
	Scrp::displayResult "\r*** No static terminology for\
	  \"[file tail $scrp_term(filepath)]\"" 0
    }
    
    if {$scrp_term(hasdynamic) && !$ScrpmodeVars(launchToGetTerminology)} {
	Scrp::displayResult "\rWarning: \"[file tail $scrp_term(filepath)]\"\
	  can provide dynamic terminology. To get it,\rset the \"Launch To Get Terminology\"\
	  flag and invoke \"Open a dictionary\" again.\rThis will launch\
	  \"[file tail $scrp_term(filepath)]\" if it is not\
	  already running.\r" 0
    }
}


# The heuristics are as follows:
# - if it is an application file, return its path
# - if it is a bundled application, try to find a main datafork resource file
# - if there is none, try to return the path to the executable
proc Scrp::Term::GetResourceFile {} {
    global scrp_term openPackages 
    set oldval $openPackages
    set openPackages 0
    if {[catch {getfile "Get terminology from:"} f]} {
	set openPackages $oldval
	return 0
    } 
    set openPackages $oldval
    set scrp_term(filepath) [string trimright $f "/"]
    # Is this a bundled application ?
    if {[file isfile $f]} {
	set scrp_term(resourcepath) $f
    } elseif {[file isdirectory $f] && [file exists [file join $f Contents]]} {
	set scrp_term(isbundle) 1
	if {[catch {Scrp::Term::NameOfExecutable $f} xname]} {
	    return 0
	} 
	if {[file exists [file join $f Contents Resources $xname.rsrc]]} {
	    set scrp_term(resourcepath) [file join $f Contents Resources $xname.rsrc]
	} elseif {[file exists [file join $f Contents MacOS $xname]]} {
	    set scrp_term(resourcepath) [file join $f Contents MacOS $xname]
	} elseif {[file exists [file join $f Contents MacOSClassic $xname]]} {
	    set scrp_term(resourcepath) [file join $f Contents MacOSClassic $xname]
	} else {
	    error "Couldn't find resource file in bundle."
	}
    } else {
	return 0
    }
    Scrp::Term::GetCreator $f
    return 1
}


proc Scrp::Term::NameOfExecutable {bundle} {
    set plist [file join $bundle Contents info.plist]
    if {[file exists $plist]} {
	set contents [file::readAll $plist]
	if {[regexp {<key>CFBundleExecutable</key>[\r\n\t ]+<string>([^<]+)</string>} $contents -> xname]} {
	    return $xname
	} else {
	    error "Could not find CFBundleExecutable property"
	}
    } 
    # If there is no info.plist file, return the name of the bundle 
    # (trimming the extension if any)
    return [file root [file tail $bundle]]
}


proc Scrp::Term::GetCreator {name} {
    global scrp_term
    if {$scrp_term(isbundle)} {
	set name [string trimright $name "/"]
	set pkinfo [file join $name Contents PkgInfo]
	if {[file exists $pkinfo]} {
	    set contents [file::readAll $pkinfo]
		set scrp_term(creator) [string range $contents 4 7]
		return
	} elseif {[file exists $plist]} {
	    set contents [file::readAll $plist]
	    if {[regexp {<key>CFBundleSignature</key>[\r\n\t ]+<string>([^<]+)</string>} $contents -> xname]} {
		set scrp_term(creator) $xname
		return
	    } 
	}
    } else {
	if {![catch {getFileInfo $name ar}]} {
	    set scrp_term(creator) $ar(creator)
	    return
	} 
    } 
    error "Sorry, can't get file's creator for \
	  '[file tail $scrp_term(filepath)]' on this system"
}


# -------------------------------------------------------------------------
# Look for an 'scsz' resource: its first byte contains the
# kLaunchToGetTerminology flag (1 << 15). If it is set, it means that the
# application accepts the "Get AETE" Apple Event.
# -------------------------------------------------------------------------
proc Scrp::Term::HasDynamicTerminology {resid} {
    catch {resource list scsz $resid} scszList
    if {[string length [lindex $scszList 0]]!=0} {
	catch {resource read scsz [lindex $scszList 0] $resid} scszbinvar
	binary scan $scszbinvar H2 firstbyte
	return [eval expr {0x$firstbyte >> 7}]
    }
    return 0
}


proc Scrp::Term::GetDynamicTerminology {} {
    global scrp_term
    app::launchBack $scrp_term(creator)
    set res [split [tclAE::send -r '$scrp_term(creator)' ascr gdte ---- 0] ,]
    set i 1
    set ext ""
    foreach item $res {
	regexp {aete\(Ç([A-Fa-f0-9]+)È\)} $item dumm aetehexvar
	if {[llength $res]>1} {
	    set ext "_$i"
	} 
	if {[info exists aetehexvar] && $aetehexvar!=""} {
	    Scrp::Term::NameDictionary $scrp_term(filepath) $ext
	    incr i
	    set aetebinvar [binary format H* $aetehexvar]
	    set scrp_term(parsedaete) [tclAE::aete::parse::parseAETE $aetebinvar]
	    Scrp::Term::WriteDictionary
	    unset aetebinvar aetehexvar
	    append scrp_term(parsinglog) "$scrp_term(dictfilepath)\r"
	    edit -c -w $scrp_term(dictfilepath)
	} 
    }
    return [llength $res]
}


proc Scrp::Term::GetStaticTerminology {resid} {
    global scrp_term
    catch {resource list -ids aete $resid} listrez
    # Store the hexadecimal data in a variable.
    if {[llength $listrez] != 0} {
	set ext ""
	foreach rezNum $listrez {
	    if {[llength $listrez]>1} {
		set ext "_$rezNum"
	    }
	    Scrp::Term::NameDictionary $scrp_term(filepath) $ext
	    catch {resource read aete $rezNum $resid} aetebinvar
	    set scrp_term(parsedaete) [tclAE::aete::parse::parseAETE $aetebinvar]
	    Scrp::Term::WriteDictionary
	    unset aetebinvar 
	    append scrp_term(parsinglog) "$scrp_term(dictfilepath)\r"
	    edit -c -w $scrp_term(dictfilepath)
	}
    } 
    return [llength $listrez]
}


proc Scrp::Term::NameDictionary {file {ext ""}} {
    global scrp_term
    set scrp_term(dictfilepath) "$scrp_term(filepath).dict$ext"
    set tail [file tail $scrp_term(dictfilepath)]
    if {[string length $tail] > 32} {
	set scrp_term(dictfilepath) [file join [file dir $scrp_term(dictfilepath)]\
	  [shorten $tail 31 14]]
    } 
}


# Writing out scripting terminology
# ---------------------------------

proc Scrp::Term::WriteDictionary {} {
    global scrp_term 
    if {[catch {open "$scrp_term(dictfilepath)" w+} scrp_term(outfileId)]} {
	alertnote "Error: $scrp_term(outfileId)"
	return
    } 
    status::msg "Creating [file tail $scrp_term(dictfilepath)]É"
    eval Scrp::Term::WriteDictHeader [lrange $scrp_term(parsedaete) 0 3]
    set suites [lindex $scrp_term(parsedaete) 4]
    # Suites loop
    for {set i 0} {$i < $scrp_term(nbSuites)} {incr i} {
	puts $scrp_term(outfileId) "\rSUITE [expr {$i+1}]"  
	Scrp::Term::WriteDictSuite [lindex $suites $i]
    }
    flush $scrp_term(outfileId)
    close $scrp_term(outfileId)
}


proc Scrp::Term::WriteDictHeader {maj min lang code} {
    global scrp_term 
    puts $scrp_term(outfileId) "Scripting terminology for \"[file tail $scrp_term(resourcepath)]\"\r"
    puts $scrp_term(outfileId) "Version: $maj.$min"  
    puts $scrp_term(outfileId) "Language code: $lang\nScript code: $code"
    set scrp_term(nbSuites) [llength [lindex $scrp_term(parsedaete) 4]]
    puts $scrp_term(outfileId) "Number of Suites: $scrp_term(nbSuites)" 
}


# Writing each suite data. From here, we get the data for the events, classes,
# comparison operators and enumerations contained in a suite.
proc Scrp::Term::WriteDictSuite {suite} {
    global scrp_term
    puts $scrp_term(outfileId) "[lindex $suite 0] ('[lindex $suite 2]',\
      level [lindex $suite 3], version [lindex $suite 4])"
    puts $scrp_term(outfileId) "  [lindex $suite 1]"

    # Events Loop
    set scrp_term(nbEvents) [llength [lindex $suite 5]]
    if {$scrp_term(nbEvents)} {
	puts  $scrp_term(outfileId) "\r  $scrp_term(nbEvents) Terms" 
    } 
    for {set i 0} {$i < $scrp_term(nbEvents)} {incr i} {
	Scrp::Term::WriteDictEvent [lindex $suite 5 $i]
    } 
    # Classes loop
    set scrp_term(nbClasses) [llength [lindex $suite 6]]
    if {$scrp_term(nbClasses)} {
	puts $scrp_term(outfileId) "\r  $scrp_term(nbClasses) Classes" 
    } 
    for {set i 0} {$i < $scrp_term(nbClasses)} {incr i} {
	Scrp::Term::WriteDictClass [lindex $suite 6 $i]
    }
    # Comparison operators loop
    set scrp_term(nbCompOps) [llength [lindex $suite 7]]
    if {$scrp_term(nbCompOps)} {
	puts $scrp_term(outfileId) "\r  $scrp_term(nbCompOps) Comparison Operators" 
    } 
    for {set i 0} {$i < $scrp_term(nbCompOps)} {incr i} {
	Scrp::Term::WriteDictCompop [lindex $suite 7 $i]
    } 
    # Enumerations loop
    set scrp_term(nbEnums) [llength [lindex $suite 8]]
    if {$scrp_term(nbEnums)} {
	puts $scrp_term(outfileId) "\r  $scrp_term(nbEnums) Enumerations" 
    } 
    for {set i 0} {$i < $scrp_term(nbEnums)} {incr i} {
	Scrp::Term::WriteDictEnums [lindex $suite 8 $i]
    } 
}


proc Scrp::Term::WriteDictEvent {event} {
    global scrp_term
    puts $scrp_term(outfileId) "\r\t[lindex $event 0] \
      ('[lindex $event 2]'/'[lindex $event 3]') -- [lindex $event 1]"
    puts $scrp_term(outfileId) "\t\tDirect parameter type: '[lindex $event 5 0]' \
	  -- [lindex $event 5 1]"
    Scrp::Term::ParseFlags "\t\t" [lindex $event 5 2] 1 0
    puts $scrp_term(outfileId) "\t\tReply ('[lindex $event 4 0]')\
      -- [lindex $event 4 1]"
    Scrp::Term::ParseFlags "\t\t" [lindex $event 4 2] 1 0

    set scrp_term(nbAddParms) [llength [lindex $event 6]]
    if {$scrp_term(nbAddParms)} {
	puts $scrp_term(outfileId) "\t\tAdditional Parameters" 
    } 
    # Additional parameters loop	
    for {set i 0} {$i < $scrp_term(nbAddParms)} {incr i} {
	Scrp::Term::WriteDictAddparms [lindex $event 6 $i]
    }
}


proc Scrp::Term::WriteDictAddparms {addparam} {
    global scrp_term
    puts $scrp_term(outfileId) "\t\t  [lindex $addparam 0] (keyword '[lindex $addparam 1]', \
      type '[lindex $addparam 2]')"
    puts $scrp_term(outfileId) "\t\t\t-- [lindex $addparam 3]"
    Scrp::Term::ParseFlags "\t\t\t" [lindex $addparam 4] 1 0
}


proc Scrp::Term::WriteDictClass {class} {
    global scrp_term
    puts $scrp_term(outfileId) "\r\t\tClass \"[lindex $class 0]\" ('[lindex $class 1]') \
      -- [lindex $class 2]"

    set scrp_term(nbPropr) [llength [lindex $class 3]]
    if {$scrp_term(nbPropr)} {
	puts $scrp_term(outfileId) "\t\tProperties" 
    } 
    # Class properties loop	
    for {set i 0} {$i < $scrp_term(nbPropr)} {incr i} {
	Scrp::Term::WriteDictClasspropr [lindex $class 3 $i]
    }
    set scrp_term(nbElems) [llength [lindex $class 4]]
    if {$scrp_term(nbElems)} {
	puts $scrp_term(outfileId) "\t\tElements" 
    } 
    # Class elements loop	
    for {set i 0} {$i < $scrp_term(nbElems)} {incr i} {
	Scrp::Term::WriteDictElements [lindex $class 4 $i]
    }
}


proc Scrp::Term::WriteDictClasspropr {prop} {
    global scrp_term
    puts $scrp_term(outfileId) "\t\t\t[lindex $prop 0] \
      ('[lindex $prop 1]'/'[lindex $prop 2]') -- [lindex $prop 3]"
    Scrp::Term::ParseFlags "\t\t\t" [lindex $prop 4] 0 1
}


proc Scrp::Term::WriteDictElements {elem} {
    global scrp_term
    puts $scrp_term(outfileId) "\t\t\tClass element ID: '[lindex $elem 0]'"

    set scrp_term(nbKeyforms) [llength [lindex $elem 1]]
    if {$scrp_term(nbKeyforms)} {
	puts $scrp_term(outfileId) "\t\t\t$scrp_term(nbKeyforms) Key Forms: " 
    } 
    # Key forms loop	
    for {set i 0} {$i < $scrp_term(nbKeyforms)} {incr i} {
	puts $scrp_term(outfileId) "\t\t\t  '[lindex $elem 1 $i]'" 
    }
}


proc Scrp::Term::WriteDictCompop {compop} {
    global scrp_term
    puts $scrp_term(outfileId) "\t\t- \"[lindex $compop 0]\" \
          ('[lindex $compop 1]')  [lindex $compop 2]"
}


proc Scrp::Term::WriteDictEnums {enum} {
    global scrp_term
    puts $scrp_term(outfileId) "\r\t\tEnum '[lindex $enum 0]'"

    set scrp_term(nbEnumerators) [llength [lindex $enum 1]]
    if {$scrp_term(nbEnumerators)} {
	puts $scrp_term(outfileId) "\t\tEnumerators:" 
    } 
    # Key enumerators loop	
    for {set i 0} {$i < $scrp_term(nbEnumerators)} {incr i} {
	Scrp::Term::WriteDictEnumerators [lindex $enum 1 $i]
    }
}


proc Scrp::Term::WriteDictEnumerators {enumerator} {
    global scrp_term
    puts $scrp_term(outfileId) "\t\t  \"[lindex $enumerator 0]\" \
          ('[lindex $enumerator 1]') -- [lindex $enumerator 2]"
}


proc Scrp::Term::ParseFlags {indent flags arg1 arg2 } {
    global scrp_term
    set flags [split $flags ""]
    puts -nonewline $scrp_term(outfileId) $indent
    if {$arg1} {
	if {[lindex $flags 0]} {
	    puts -nonewline $scrp_term(outfileId) "It is optional. "
	} else {
	    puts -nonewline $scrp_term(outfileId) "It is required. "
	}
    }
    if {[lindex $flags 1]} {
	puts -nonewline $scrp_term(outfileId) "List "
    } else {
	puts -nonewline $scrp_term(outfileId) "Single item "
    }
    if {[lindex $flags 2]} {
	puts -nonewline $scrp_term(outfileId) "enumerated "
    } else {
	puts -nonewline $scrp_term(outfileId) "not enumerated "
    }
    if {$arg2} {
	if {[lindex $flags 3]} {
	    puts $scrp_term(outfileId) "\[r/w\]"
	} else {
	    puts $scrp_term(outfileId) "\[r/o\]"
	}
    }
    puts $scrp_term(outfileId) ""
}


proc Scrp::Colour&MarkDictionary {} {
	global inds
    help::removeAllColoursAndHypers
    removeAllMarks
    # Color events and properties
    set start [minPos]
    while {![catch {search -f 1 -s -i 0 -r 1 "^\t+\[a-zA-Z0-9 \]+  \\('" $start} res]} {
	set pos [lindex $res 0]
	set end [pos::math [lindex $res 1] - 4]
	set start [nextLineStart $end]   
	text::color $pos $end 4
	text::color $pos $end 15
	set evnt [getText [pos::math $pos + 1] $end]
	if {[regexp "^\[^\t\]" $evnt]} {
	    set inds($evnt) $start
	} 
    }
    if {[info exists inds]} {
	setNamedMark EVENTS 0 0 0
	foreach f [lsort -dictionary [array names inds]] {
	    set next [nextLineStart $inds($f)]
	    eval setNamedMark [list "  \"$f\""] $inds($f) $next $next
	}
	unset inds
    }
    # Color categories
    set start [minPos]
    while {![catch {search -f 1 -s -i 0 -r 1 \
      "^  \\d+ (Terms|Classes|Enumerations|Comparison Operators)$" $start} res]} {
	set pos [pos::math [lindex $res 0] + 2]
	set end [lindex $res 1]
	set start [nextLineStart $end]   
	text::color $pos $end 1
	text::color $pos $end 8
	text::color $pos $end 15
    }
    # Color classes
    set start [minPos]
    while {![catch {search -f 1 -s -i 0 -r 1 "^\t+Class \"\[^\"\]+\"" $start} res]} {
	set pos [lindex $res 0]
	set end [lindex $res 1]
	set start [nextLineStart $end]   
	text::color $pos $end 1
	# Mark classes
	set got [search -s -n -f 1 -r 1 "\"\[^\"\]+" $pos]
	if {[llength $got]} {
	    set pos [pos::math [lindex $got 0] + 1]
	    set inds([getText $pos [pos::math $end - 1]]) $start
	}
    }
    if {[info exists inds]} {
	setNamedMark CLASSES 0 0 0
	foreach f [lsort -dictionary [array names inds]] {
	    set next [nextLineStart $inds($f)]
	    eval setNamedMark [list "  \"$f\""] $inds($f) $next $next
	}
	unset inds
    }
    set start [minPos]
    while {![catch {search -f 1 -s -i 0 -r 1 "^\t+(Properties|Elements)$" $start} res]} {
	set pos [lindex $res 0]
	set end [lindex $res 1]
	set start [nextLineStart $end]   
	text::color $pos $end 5
    }
    # Color suites
    set start [minPos]
    while {![catch {search -f 1 -s -i 0 -r 1 "^SUITE \\d+$" $start} res]} {
	set pos [lindex $res 0]
	set end [lindex $res 1]
	set start [nextLineStart $end]   
	text::color $pos $end 0
	text::color $pos $end 8
    }
    refresh
}

