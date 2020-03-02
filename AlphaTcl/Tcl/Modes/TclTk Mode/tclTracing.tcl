## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl support packages
 # 
 # FILE: "tclTracing.tcl"
 #                                          created: 04/05/1997 {09:31:10 pm}
 #                                      last update: 03/21/2006 {03:28:19 PM}
 # Description:
 # 
 # Tracing of Tcl procedures.
 # Wonderful procs from Vince Darley (vince@santafe.edu).
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta
 #         Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 # 
 # Copyright (c) 1997-2006 Vince Darley
 # All rights reserved.
 # 
 # ==========================================================================
 ##

proc tclTracing.tcl {} {}

# Make sure that the "tclMode.tcl" file has been sourced.
# This sets some initial Tcl 'tracing' variable values.
tclMode.tcl

namespace eval Tcl {}

proc Tcl::traceThisProc {} {

    if {[catch {Tcl::enclosingProcName} name]} {
	status::msg "Couldn't find an enclosing procedure."
	return
    }
    set name [string trimleft $name :]
    if {![llength [set cmds [evaluate [list info commands ::$name]]]]} { 
	evaluate [list auto_load ::$name]
    }
    procs::traceProc ::$name
}

# ===========================================================================
#
# ×××× -------- ×××× #
# 
# ×××× Trace Window navigation ×××× #
# 

# This is to expand navigation in Trace windows.  The idea is to provide a
# jump to the return of the selected proc/command call (useful when you want
# to jump over sub step calls).

proc Tcl::traceSearch {dir} {
    beginningLineSelect
    endLineSelect
    set line [getSelect]
    set pat1 "(OK: |ERROR: |RETURN: |CODE\\\(\[^\)\]*\\\): )"
    if {[regexp -- "(.*) ${pat1}" $line all rtn]} {
	if {$dir} {
	    status::msg "Already at a Return"
	    return
	} else {
	    set beg [pos::math [getPos] - 1]
	    set notfound "Cannot find the Call"
	    set pat "^[quote::Regfind $rtn]"
	}
    } elseif {$dir} {
	set beg [selEnd]
	set notfound "Cannot find the Return"
	regexp -- "^(\[ \t\]*\[\\w:\]+)(.*)?" $line -> trig extra
	set extra [quote::Regfind $extra]
	set pat "^${trig}($extra)? ${pat1}"
    } else {
	status::msg "Already at a Call"
	return
    }
    if {[llength [set match [search -n -s -f $dir -i 1 -r 1 -- $pat $beg]]]} {
	eval selectText $match
    } else {
	status::msg $notfound
    }
}

proc Tcl::forwardToTclReturn {} {Tcl::traceSearch 1}
proc Tcl::backToTclCall      {} {Tcl::traceSearch 0}

# Return 1 if successful, which also implies we have placed a bookmark.
# Called by [Tcl::DblClick], but only in error/trace etc windows.
proc Tcl::findErrorInfoLocation {pos} {
    
    set text [getText [pos::lineStart $pos] [pos::lineEnd $pos]]
    if {![regexp "^(\[ \t\]*)\\\((.*)\\\)\[ \t\]*\$" $text "" pre text]} {
	return 0
    }
    set start [pos::math [pos::lineStart $pos] + [string length $pre]]
    set end [pos::math $start + [string length $text] + 2]
    selectText $start $end
    
    set words [parseWords $text]
    set line [lindex $words end]
    
    if {[lindex $words 0] == "procedure"} {
	set procName [lindex $words 1]
	placeBookmark
	if {![catch [list procs::debug $procName $line]]} {
	    return 1
	}
    } elseif {[lindex $words 1] == "arm"} {
	# a switch arm
	set procPos [lindex [search -s -f 1 -r 1 \
	  "^    \\\(procedure " [pos::nextLineStart $pos]] 1]
	if {![Tcl::findErrorInfoLocation $procPos]} {
	    return 0
	}
	# we should have opened the procedure
	set swPos [lindex [search -s -f 1 -- [lindex $words 0] [getPos]] 0]
	set row [lindex [pos::toRowChar $swPos] 0]
	incr row $line
	set start [pos::fromRowChar $row 0]
	selectText $start [pos::nextLineStart $start]
	return 1
    }
    return 0
}

# ===========================================================================
#
# ×××× -------- ×××× #
# 
# ×××× Variable Tracing ×××× #
# 
# (rudimentary code under development)

proc tclStackDump {} {
    for {set i [info level]} {$i >= 0} {incr i -1} {
	puts "Level $i: [info level $i]"
    }
}

proc traceTclVariable {{var ""}} {
    if {[regexp {([^()]*)\((.*)\)$} $var -> arr elt]} {
	global _old $arr
	set _old [set ${arr}($elt)]
	#trace add variable $var {write} [list variableTracing $var]
	trace add variable $arr {write} [list variableArrTracing $arr $elt]
    } else {
	global _old $var
	set _old [set $var]
	trace add variable $var {write} [list variableTracing $var]
    }
}

proc variableArrTracing {arr elt ar elt2 args} {
    if {$elt == $elt2} {
	eval [list variableTracing ${arr}($elt)] $args
    }
}

proc variableTracing {var args} {
    if {[regexp {([^()]*)\((.*)\)$} $var -> arr elt]} {
	global $arr
    } else {
	global $var
    }
    global _old
    tclStackDump
    if {![dialog::yesno -y "Contine" -n "Break" \
      "old ($_old) new ([set $var]), $args"]} {
	set $var $_old
	error "User-break while tracing"
    }
    set _old [set $var]
}

# ===========================================================================
#
# ×××× -------- ×××× #
# 
# ×××× Proc Tracing ×××× #
# 

proc traceTclProc {{func ""}} {

    global alpha::tracingProc alpha::traceStartLevel alpha::maxTraceDepth \
      Tcl::inTracing Tcl::tracingProc Tcl::traceInfo
    
    if {[info exists alpha::tracingProc] && ($alpha::tracingProc != "")} {
	# Remove the existing trace first, so we don't trigger more traces
	# whilst dumping the information.
	set len [evaluate [list info commands $alpha::tracingProc]]
	if {[llength $len]} {
	    set info [lindex [evaluate \
	      [list trace info execution $alpha::tracingProc]] 0]
	    if {[llength $info]} {
		evaluate [concat \
		  [list trace remove execution $alpha::tracingProc] $info]
	    }
	}
	# Now ask if the user wants the information.
	dumpTraces $alpha::tracingProc "" ask
	set Tcl::inTracing 0
	set Tcl::traceInfo 0
	Tcl::postBuildTracing
	status::msg "Tracing off."
	set alpha::tracingProc ""
	if {![string length $func]} {return}
    }
    if {![string length $func]} {set func [procs::pick 1]}
    if {![string length $func]} {return}
    # In case this is a separate interp, make sure it has this proc.
    evaluate [list namespace eval alpha {}]
    evaluate [procs::generate alpha::traceCapture]
    evaluate [list set alpha::traceStartLevel ""]
    evaluate [list set alpha::dontTraceThisTree ""]
    if {[tcltk::isInternal [tcltk::getInterpCmd]]} {
	evaluate [list trace add execution $func \
	  {enter leave enterstep leavestep} \
	  [list ::traceCapture $func]]
	set Tcl::traceInfo 0
    } else {
	global TclmodeVars
	evaluate [list set alpha::dontTrace ""]
	evaluate [list set alpha::maxTraceDepth $alpha::maxTraceDepth]
	evaluate [list trace add execution $func \
	  {enter leave enterstep leavestep} \
	  [list ::alpha::traceCapture \
	  $TclmodeVars(maximumNumberOfExternalCommandsToTrace) $func]]
	set Tcl::traceInfo 2
    }
    set alpha::tracingProc $func
    set Tcl::inTracing 1
    set Tcl::traceProc $func
    Tcl::postBuildTracing
    status::msg "Tracing '$func'É"
}

proc traceCapture {args} {

    global Tcl::traceInfo

    if {[info exists Tcl::traceInfo] && ($Tcl::traceInfo == 0)} {
	global tclMenu
	enableMenuItem tclTracing "displayTraces" 1
	set Tcl::traceInfo 1
    }
    eval [list ::alpha::traceCapture 0] $args
}

proc dumpTraces {{name ""} {data ""} {action "dump"}} {
    global alpha::tracingProc alpha::tracingData alpha::traceStartLevel \
      Tcl::traceInfo alpha::dontTraceThisTree

    watchCursor
    evaluate [list set alpha::dontTraceThisTree {}]
    evaluate [list set alpha::traceStartLevel ""]
    if {![string length $name]} {
	set name $alpha::tracingProc
    }
    if {![llength $data]} {
	status::msg "Building trace information?"
	if {[evaluate [list info exists alpha::tracingData]]} {
	    set evalCmd [tcltk::getInterpCmd]
	    if {$evalCmd == "tcltk::internalEvaluate"} {
		set data $alpha::tracingData
	    } else {
		set data [tcltk::directEvaluation [list set alpha::tracingData]]
	    }
	    evaluate [list set alpha::tracingData ""]
	}
    }
    if {![llength $data]} {
	status::msg "Trace buffer empty"
    } else {
	if {$action == "ask" && (![dialog::yesno "Dump traces?"])} {
	    return
	}
	status::msg "Displaying trace information in new window"
	new -n "* Trace '$name' *" -m Tcl \
	  -info [alpha::rawTraceToDump [K $data [set data ""]]]
    }
    if {${Tcl::traceInfo} != 2} {
	set Tcl::traceInfo 0
    }
    Tcl::postBuildTracing
}


# We need the famous 'K combinator' to handle huge traces efficiently.
proc K {x y} {set x}

namespace eval alpha {
    # Set this to zero to trace everything
    variable dontTraceCoreCommands 1
    variable dontTrace          ""
    variable dontTraceThisTree  ""
    variable maxTraceDepth
    variable platform
    variable traceStartLevel
    variable tracingData
    variable tracingProc
    
    ensureset maxTraceDepth     -1
    ensureset traceStartLevel   ""
    ensureset tracingData       ""
    ensureset tracingProc       ""

    if {$platform == "tk"} {
	lappend dontTrace text_cmd text_cmds text_wcmd text_wcmds \
	  getSplitFocus _ensureValid max getText arrangeToColourNewlyRevealed \
	  selEnd winNames search tw::see select getOpts getPos menu_tags \
	  status::msg ::msgcat::mc dialog listpick tw::mark getWinInfo \
	  dirty _menuItemToIndex enableMenuItem readTextFromFile \
	  putsTextToFile ::alpha::embedInto alpha::embedInto alphaOpen \
	  getFileInfo setWinInfo goto ::win::parseArgs insertText \
	  Bind unBind matchIt
    }
    if {1} {
	# We don't really want to trace inside our tcl-vfs code
	lappend dontTrace file glob cd pwd
	# Nor our 'dict' emulation
	lappend dontTrace dict
    }
    lappend dontTrace win::Current win::CurrentTail win::Tail lcontains \
      minPos maxPos pos::_getWPos pos::_ensureValid pos::math pos::compare \
      pos::min pos::max pos::lineStart pos::nextLineStart \
      file::pathStartsWith win::parseArgs pos::lineEnd pos::toRowCol \
      pos::toRowChar pos::fromRowCol pos::fromRowChar _ensureValid \
      pos::nextChar pos::prevChar
}

proc alpha::traceCapture {max name args} {
    
    global alpha::tracingData

    if {[catch {
	if {$max != 0 && ([info exists tracingData]) \
	  && ([llength $tracingData] > $max)} {
	    return
	}
	variable dontTrace
	variable dontTraceThisTree
	variable maxTraceDepth
	variable traceStartLevel
	variable dontTraceCoreCommands
	
	if {![string length $traceStartLevel]} {
	    set traceStartLevel [info level]
	}
	set level [expr {[info level] - $traceStartLevel}]
	# Check whether we only trace to a certain depth
	if {[info exists maxTraceDepth] \
	  && ($maxTraceDepth != -1) \
	  && ($level > $maxTraceDepth)} {
	    return
	}
	set cmd [lindex $args 0]
	set cmdname [lindex $cmd 0]
	# Check if we're inside a command we don't want to trace
	# the contents of (else the trace becomes unmanageable).
	#puts stderr "$level [info level] $args"
	if {$dontTraceCoreCommands && [llength $dontTraceThisTree]} {
	    if {[lindex $dontTraceThisTree 0] eq $cmdname} {
		if {[lindex $dontTraceThisTree 1] == $level} {
		    # If name and level are the same, then we are
		    # just leaving the command, so we can now resume
		    # tracing
		    set dontTraceThisTree ""
		} else {
		    # Same name, but different level -- the command
		    # is calling itself recursively, so we still don't
		    # want to trace.
		    return
		}
	    } else {
		# Don't trace, since we're inside.
		return
	    }
	} else {
	    # Check if we want to turn tracing off
	    if {$dontTraceCoreCommands \
	      && [lsearch -exact $dontTrace $cmdname] != -1} {
		set dontTraceThisTree [list $cmdname $level]
	    }
	}
	# Now have variables: level, cmd, args
	lappend tracingData [list $level $cmd $args]
    } err] == 1} { 
	puts stderr "bug in tracing: $err" 
    }
}

# Currently hard-code a length of 250 to trim
proc alpha::trimAndQuote {arg} {
    if {[string length $arg] > 250} {
	return "[regsub -all \n [string range $arg 0 249] {\\n}]..."
    } else {
	return [regsub -all "\n" $arg {\\n}]
    }
}

proc alpha::rawTraceToDump {data} {
    set dump {}
    set nextlevel 0
    foreach triplet $data {
	foreach {level cmd args} $triplet {
	    set when [lindex $args end]
	    switch -- $when {
		enter - enterstep {
		    set truelevel $nextlevel
		    incr nextlevel
		}
	    }
	    set newarg {}
	    foreach arg $cmd {
		lappend newarg [trimAndQuote $arg]
	    }
	    set cmd $newarg
	    if {![string is integer $level]} {
		alertnote "Bug in tracing code.  Expected integer but\
		  got '$level'"
		return -code error "Tracing code bug $triplet"
	    }
	    set indent [string repeat " " $truelevel]
	    if {([string first "\n" $cmd] == -1)} {
		set cmd "${indent}${cmd}"
	    } else {
		set lines {}
		set idx [string last "\n" $cmd]
		regexp {[ \t]*} [string range $cmd [expr {$idx+1}] end] ind
		set ind [string length \
		  [text::maxSpaceFormWithTab "        " $ind]]
		foreach line [split $cmd "\n"] {
		    set line [text::maxSpaceFormWithTab "        " $line]
		    if {[string trim \
		      [string range $line 0 [expr {$ind -1}]]] == ""} {
			set line [string range $line $ind end]
		    }
		    lappend lines $line
		}
		set cmd [join $lines "\n"]
		set cmd [text::indentBy $cmd [expr {$truelevel * 1}] 8]
	    }
	    set when [lindex $args end]
	    switch -- $when {
		leave {
		    incr nextlevel -1
		    set truelevel [expr {$nextlevel - 1}]
		    set code [lindex $args 1]
		    set res [lindex $args 2]
		    if {$code == 0} {
			append cmd " OK"
		    } elseif {$code == 1} {
			append cmd " ERROR"
		    } elseif {$code == 2} {
			append cmd " RETURN"
		    } else {
			append cmd " CODE($code)"
		    }
		    append cmd ": [trimAndQuote $res]"
		}
		leavestep {
		    incr nextlevel -1
		    set truelevel [expr {$nextlevel - 1}]
		    set trig [lindex $args 0 0]
		    set cmd "${indent}"
		    set code [lindex $args 1]
		    set res [lindex $args 2]
		    if {$code == 0} {
			append cmd "$trig OK"
		    } elseif {$code == 1} {
			append cmd "$trig ERROR"
		    } elseif {$code == 2} {
			append cmd "$trig RETURN"
		    } else {
			append cmd "$trig CODE($code)"
		    }
		    append cmd ": [trimAndQuote $res]"
		}
	    }
	    append dump $cmd "\n"
	}
    }
    return $dump
}

# ===========================================================================
# 
# .