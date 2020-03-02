## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl support packages
 # 
 # FILE: "tclProcs.tcl"
 #                                          created: 04/05/1997 {09:31:10 pm}
 #                                      last update: 03/21/2006 {03:27:51 PM}
 # Description:
 # 
 # Adds support for finding, folding, parsing, loading, reformatting,
 # locating, etc Tcl procs, in any current window.  Also includes some
 # utilities which rely on tclIndex files or information obtained from the
 # current interpreter.
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

proc tclProcs.tcl {} {}

# ×××× -------- ×××× #

namespace eval Tcl {}

# All of the Tcl procs below take optional ?-w window?  leading arguments.

## 
 # -------------------------------------------------------------------------
 # 
 # "Tcl::enclosingProcName" --
 # "Tcl::enclosingNamespace" --
 # 
 # Find the name of the proc/namespace enclosing the current cursor position.
 # This requires that the function in question be syntactically correct, i.e.
 # no missing braces.
 # 
 # -------------------------------------------------------------------------
 ##

proc Tcl::enclosingProcName {args} {

    win::parseArgs w {pos ""} {pat "proc"}

    if {![string length $pos]} {
	set pos [getPos -w $w]
    }
    if {![catch {Tcl::parseFunctionInfo -w $w $pos $pat "name"} procName]} {
	return $procName
    } else {
	error "Couldn't find enclosing procedure."
    }
}

proc Tcl::enclosingNamespace {args} {
    
    win::parseArgs w {pos ""}
    
    if {![string length $pos]} {
	set pos [getPos -w $w]
    }
    if {![catch {Tcl::parseFunctionInfo -w $w $pos "namespace" "name"} ns]} {
	return $ns
    } else {
	error "Couldn't find enclosing namespace."
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "Tcl::contextNamespace" --
 # 
 # Find the namespace specific to the context surrounding 'pos'.  If the
 # 'requireEnclosing' argument is '0', then we search backwards for the start
 # of some proc or namespace environment, though there's no guarantee that
 # we're actually in this environment.  (This is potentially useful if the
 # user is in the middle of writing a procedure which is currently
 # syntactically incorrect due to missing closing braces, etc.  -- in this
 # situation, [Tcl::parseFunctionInfo] generally throws an error.)
 # 
 # This is used both by the contextual menu as well as completions.
 # 
 # -------------------------------------------------------------------------
 ##

proc Tcl::contextNamespace {args} {
    
    win::parseArgs w {pos ""} {requireEnclosing 1}
    
    if {![string length $pos]} {
	set pos [getPos -w $w]
    }
    set pat1 "namespace eval"
    set pat2 "proc"
    set pat3 "${pat1}|${pat2}"
    set nameSpace ""
    if {![catch {Tcl::enclosingNamespace -w $w $pos} ns]} {
	set nameSpace $ns
    } elseif {![catch {Tcl::enclosingProcName -w $w $pos} procName]} {
	set nameSpace [namespace qualifiers $procName]
    } elseif {!$requireEnclosing} {
	if {[llength [set pp [Tcl::findFunctionStart -w $w $pos $pat3]]]} {
	    set parsed [Tcl::parseFunctionStart -w $w [lindex $pp 0]]
	    set nameSpace [namespace qualifiers [lindex $parsed 2]]
	}
    }
    regsub {^::} $nameSpace "" nameSpace
    return $nameSpace
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# These next three utilities provide increasingly detailed information about
# the positions, parameters etc re a procedure at or enclosing a given
# position.
# 

## 
 # -------------------------------------------------------------------------
 # 
 # "Tcl::findFunctionStart" --
 # 
 # Find any function that starts a line with 'pattern' (allowing it to be
 # preceded by whitespace, as well as ';' and optionally '#') in the
 # specified direction.  Returns an empty list if none found, else a list
 # containing
 # 
 # (0) The start of the line containing the function
 # (1) The position following the function's name (second 'word')
 # 
 # Note that the variable 'Tcl::searchPats(1)' is a good default pattern.
 # 
 # -------------------------------------------------------------------------
 ##

proc Tcl::findFunctionStart {args} {
    
    win::parseArgs w {pos ""} {pat "proc"} {direction 0} {commentOK 0}
    
    if {![string length $pos]} {
	set pos [getPos -w $w]
    }
    if {$commentOK} {
	set patA {^[\t ;\#]*}
    } else {
	set patA {^[\t ;]*}
    }
    set patB {[\t ]+[^\t ]+[\t ]+}
    set pat1 "${patA}(${pat})${patB}"
    return [search -w $w -n -s -m 0 -r 1 -i 0 -f $direction -- $pat1 $pos]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "Tcl::parseFunctionStart" --
 # 
 # 'pos0' must be the start of a known procedure.  Returns a five item
 # list containing:
 # 
 # 'prefix' --  the string of characters less whitespace preceding the
 #              function declaration
 # 'type' --    the type of function found
 # 'name' --    the name of the function
 # 'args' --    the arguments of the function
 # 
 # and a list of positions.  If the 'function' is "namespace", then the
 # 'name' is the third 'word' and the 'args' value will be empty.
 # 
 # If the 'details' argument is '1', then the 'positions' list contains all
 # positions (0) through (7), where (0) is the start of the line containing
 # the function, others are
 # 
 #   (1)function(2) (3)name(4) (5)args(6)
 # 
 # and (7) is the start of the next line following (6).  If 'details' is '0',
 # the list of positions contains (0) and (7).  (The rationale here is
 # that doing all of that [pos::math ...]  can be somewhat labor intensive,
 # esp for recursive procs like file marking that aren't going to use the
 # intermediate positions anyway.)
 # 
 # This proc will never throw an error, although the some of the items
 # might be empty if we cannot successfully parse their values.
 # 
 # -------------------------------------------------------------------------
 ##

proc Tcl::parseFunctionStart {args} {

    variable searchPats

    win::parseArgs w pos0
    
    set pos0 [pos::lineStart -w $w $pos0]
    set pos7 [pos::lineEnd -w $w $pos0]
    while {[lookAt -w $w [pos::math -w $w $pos7 -1]] eq "\\"} {
	set pos7 [pos::nextLineEnd -w $w $pos7]
	if {[pos::compare -w $w $pos7 == [pos::max -w $w]]} {
	    break
	}
    }
    set pos7 [pos::nextLineStart -w $w $pos7]
    set txt1 [getText -w $w $pos0 $pos7]
    set patA {^([\t \;\#]*)[\t ]*([a-z]+)[\t ]+}
    set patB {[\t ]+([^\t ]+)}
    set pat1 "${patA}${searchPats(3)}${patB}"
    foreach item [list 1 2 3 4] {set idxs${item} [list 0 0]}
    foreach item [list prefix type name] {set $item ""}
    set txt1 [string map [list "\\\n" "  "] $txt1]
    regexp -indices -- $pat1 $txt1 idxs0 idxs1 idxs2 idxs3 idxs4
    set parsed [regexp -inline  -- $pat1 $txt1]
    regsub -all {\t| } [lindex $parsed 1] "" prefix
    set type [lindex $parsed 2]
    set name [lindex $parsed 3]
    if {[is::List $name]} { 
	set name [lrange $name 0 end]
    }
    set pos5 [pos::math -w $w $pos0 + [lindex $idxs4 0]]
    if {[lookAt -w $w $pos5] eq "\{"} {
	if {![catch {matchIt -w $w "\{" [pos::nextChar $pos5]} pos6]} {
	    set pos6 [pos::nextChar $pos6]
	} else {
	    set pos6 $pos5
	}
    } else {
	set pp [search -w $w -n -s -f 1 -r 1 -l $pos7 -- {[\t ]} $pos5]
	if {[llength $pp]} {
	    set pos6 [lindex $pp 0]
	} else {
	    set pos6 $pos5
	}
    }
    set args [getText -w $w $pos5 $pos6]
    set args [string map [list "\\\n" ""] $args]
    if {[llength $args] == 1} {
	set args [lindex $args 0]
	if {[is::List $args]} {
	    set args [lrange $args 0 end]
	}
    }
    if {($type eq "namespace")} {
	set name $args
	set args ""
    }
    set pos1 [pos::math -w $w $pos0 + [lindex $idxs2 0]]
    set pos2 [pos::math -w $w $pos0 + [lindex $idxs2 1] + 1]
    set pos3 [pos::math -w $w $pos0 + [lindex $idxs3 0]]
    set pos4 [pos::math -w $w $pos0 + [lindex $idxs3 1] + 1]
    for {set i 0} {($i <= 7)} {incr i} {
	lappend positions [set pos$i]
    }
    return [list $prefix $type $name $args $positions]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "Tcl::parseFunctionInfo" --
 # 
 # 'pos' is assumed to be the current position if none is specified -- an
 # optional leading ?-w window?  argument is also available.  If the
 # positions requested cannot be found (or if 'pos' is not within a defined
 # function) an error is thrown.
 # 
 # 'pat' indicates a leading search pattern to be used when searching for the
 # enclosing definition.  This could be 'namespace', 'proc|namespace', or any
 # other valid regexp.
 # 
 # The positions that we determine include (0) the start of the line in which
 # the function starts, and the following:
 # 
 # (1)proc(2) (3)name(4) (5)args(6) (7)body(8)
 # 
 # (0) and (1) might be the same position.
 # 
 # The 'details' argument determines what will be returned.  It can take on
 # the following values --
 # 
 # '0' --       Proc boundary positions: (1) and  (8)
 # '1' --       More detailed positions: (0) thru (8)
 # 'prefix' --  Possibly empty string, or ';' '#' '#;', reflecting whatever
 #              string precedes the 'proc|namespace|etc' pattern
 # 'type' --    The element of the 'proc|namespace|etc' pattern that was found
 # 'name' --    The name of the procedure (first item after 'type')
 # 'args' --    Parameters of the proc (second item after 'type')
 # 'body' --    Body of the proc (third and final item after 'type')
 # 'all' --     A list of 'prefix' 'type' 'name' 'args' 'body', and a
 #              final item containing positions normally returned for '1'
 # 
 # arguments are handled whether or not surrounded by {}, but the body
 # _must_ be surrounded by {} else we fail.
 # 
 # 'commentOK' means that we can search for commented procs/namespaces etc.
 # 
 # 'dir' determines the direction in which we initially search for the
 # start of the proc|namespace etc definition, while 'confirmWithin' means
 # that anything we found must contain the position 'pos'.  Normally, if we
 # want to find the information that is surrounding the position 'pos', the
 # 'dir' should be '0' and 'confirmWithin' should be '1'.
 # 
 # -------------------------------------------------------------------------
 ##

proc Tcl::parseFunctionInfo {args} {
    
    win::parseArgs w {pos ""} {pat ""} {details 0} {commentOK 0}
    
    if {![string length $pos]} {
	set pos [getPos -w $w]
    }
    if {![string length $pat]} {
	set pat "proc"
    }
    # Find the beginning of the procedure.
    set pp0 [Tcl::findFunctionStart -w $w $pos $pat 0 $commentOK]
    if {![string length [set pos0 [lindex $pp0 0]]]} {
	error "Couldn't find start of enclosing function's declaration"
    }
    set parsed [Tcl::parseFunctionStart -w $w [lindex $pp0 0]]
    foreach {prefix type name args p} $parsed {}
    foreach {pos0 pos1 pos2 pos3 pos4 pos5 pos6 pos7} $p {}
     # Find the body block.  If not surrounded by {}, this will fail.
    while {([lookAt -w $w $pos7] ne "\{")} {
	set pos7 [pos::prevChar -w $w $pos7]
	if {[pos::compare -w $w $pos7 <= $pos0]} {
	    error "Couldn't find start of enclosing function's body"
	}
    }
    if {[catch {matchIt -w $w "\{" [pos::nextChar -w $w $pos7]} pos8]} {
	error "Couldn't find end of enclosing function's body"
    }
    set pos8 [pos::nextChar -w $w $pos8]
    if {[pos::compare -w $w $pos8 < $pos]} {
        error "Couldn't find enclosing function."
    }
    for {set i 0} {($i <= 8)} {incr i} {
	lappend positions [set pos$i]
    }
    # Return desired information.
    switch -- $details {
	0 {return [list $pos1 $pos8]}
	1 {return $positions}
    }
    set args [lrange $args 0 end]
    set body [getText -w $w $pos7 $pos8]
    if {[info exists $details]} {
	return [set $details]
    } elseif {($details eq "all")} {
	return [list $prefix $type $name $args $body $positions]
    } else {
	error "Unknown details option: $details"
    }
}

##
 # --------------------------------------------------------------------------
 # 
 # "Tcl::getProcArgs" --
 # 
 # Returns the arguments (including possible default values) of the queried
 # 'procName' as a list.  If the proc is not recognized by the interpreter,
 # this will return an empty list.  If any argument has a default value, the
 # "arg default" list item will be surrounded with question marks.
 # 
 # Used by:
 # 
 # [Tcl::DblClick]
 # [Tcl::cmMenuProc]
 # [Tcl::procElectrics]
 # [alphadev::cmMenuProc]
 #
 # This is defined here rather than in "tclMode.tcl" so that the proc can be
 # auto_loaded even if Tcl mode is not yet been sourced, ensuring that any
 # possible [hook::procRename] in the AlphaDev Menu will still be in effect.
 # See [alphadev::getProcArgs] for more information.  (If this version of
 # [Tcl::getProcArgs] proc is reloaded any [hook::procRename] procedure
 # definition will be over-written.  It can be restored by turning the
 # AlphaDev menu off and then on again.)
 # 
 # --------------------------------------------------------------------------
 ##

proc Tcl::getProcArgs {procName} {
    return [Tcl::listProcArgs $procName]
}

##
 # --------------------------------------------------------------------------
 # 
 # "Tcl::listProcArgs" --
 # 
 # This is a separate procedure to make it easier to debug [Tcl::getProcArgs]
 # when the AlphaDev menu has redefined it.
 # 
 # We have special handling for most built-in Tcl commands.  (We could also
 # add Tk command arguments here, but that's a project reserved for someone
 # who actually codes in Tk ...)
 # 
 # --------------------------------------------------------------------------
 ##

proc Tcl::listProcArgs {procName} {

    variable interpCmd
    
    if {![info exists interpCmd]} {
	# This might occur if [Tcl::getProcArgs] is called before Tcl mode
	# has actually been loaded.
	tclMode.tcl
    }
    set procName [string trimleft $procName ":"]
    set ProcName "::$procName"
    # Special case for built-in Tcl commands.
    switch -- $ProcName {
	"::append" {
	    set procArgs [list {varName} {value} {?value value ...?}]
	}
	"::break" {
	    set procArgs [list {}]
	}
	"::case" {
	    set procArgs [list {string} {?in?} {patList} {body} {?patList body ...?}]
	}
	"::catch" {
	    set procArgs [list {script} {?varName?}]
	}
	"::cd" {
	    set procArgs [list {?dirName?}]
	}
	"::close" {
	    set procArgs [list {channelId}]
	}
	"::concat" {
	    set procArgs [list {arg} {arg...?}]
	}
	"::continue" {
	    set procArgs [list {}]
	}
	"::else" {
	    set procArgs [list {else body}]
	}
	"::elseif" {
	    set procArgs [list {test} {true body}]
	}
	"::eof" {
	    set procArgs [list {channelId}]
	}
	"::error" {
	    set procArgs [list {message} {?info? ?code?}]
	}
	"::eval" {
	    set procArgs [list {arg} {?arg ...?}]
	}
	"::exec" {
	    set procArgs [list {?switches?} {arg} {?arg ...?}]
	}
	"::exit" {
	    set procArgs [list {?returnCode?}]
	}
	"::expr" {
	    set procArgs [list {arg} {?arg arg ...?}]
	}
	"::flush" {
	    set procArgs [list {channelId}]
	}
	"::for" {
	    set procArgs [list {start} {test} {increment} {body}]
	}
	"::foreach" {
	    set procArgs [list {varname} {list} {body}]
	}
	"::format" {
	    set procArgs [list {formatString} {?arg arg ...?}]
	}
	"::gets" {
	    set procArgs [list {channelId} {?varName?}]
	}
	"::glob" {
	    set procArgs [list {?switches?} {pattern} {?pattern ...?}]
	}
	"::global" {
	    set procArgs [list {varname} {?varname ...?}]
	}
	"::if" {
	    set procArgs [list {test} {true body}]
	}
	"::incr" {
	    set procArgs [list {varName} {?increment?}]
	}
	"::join" {
	    set procArgs [list {list} {?joinString?}]
	}
	"::lappend" {
	    set procArgs [list {varName} {value} {?value value ...?}]
	}
	"::lindex" {
	    set procArgs [list {list} {element}]
	}
	"::linsert" {
	    set procArgs [list {list} {index} {element} {?element element ...?}]
	}
	"::list" {
	    set procArgs [list {?arg arg ...?}]
	}
	"::llength" {
	    set procArgs [list {list}]
	}
	"::lrange" {
	    set procArgs [list {list} {first} {last}]
	}
	"::lreplace" {
	    set procArgs [list {list} {first} {last} {?element element ...?}]
	}
	"::lsearch" {
	    set procArgs [list {?options?} {list} {pattern}]
	}
	"::lset" {
	    set procArgs [list {listVar} {index ?index...?} {value}]
	}
	"::lsort" {
	    set procArgs [list {?options?} {list}]
	}
	"::open" {
	    set procArgs [list {fileName} {?access? ?permissions?}]
	}
	"::pid" {
	    set procArgs [list {?fileId?}]
	}
	"::puts" {
	    set procArgs [list {?-nonewline?} {fileId} {string}]
	}
	"::pwd" {
	    set procArgs [list {}]
	}
	"::read" {
	    set procArgs [list {?-nonewline?} {channelId}]
	}
	"::regexp" {
	    set procArgs [list {?switches?} {exp} {string} {?matchVars...?}]
	}
	"::regsub" {
	    set procArgs [list {?switches?} {exp} {string} {subSpec} {varName}]
	}
	"::rename" {
	    set procArgs [list {oldName} {newName}]
	}
	"::return" {
	    set procArgs [list {?-code code? ?-errorinfo info? ?-errorcode  code? ?string?}]
	}
	"::scan" {
	    set procArgs [list {string} {format} {?varName varName ...?}]
	}
	"::seek" {
	    set procArgs [list {channelId} {offset} {?origin?}]
	}
	"::set" {
	    set procArgs [list {varName} {?value?}]
	}
	"::source" {
	    set procArgs [list {fileName}]
	}
	"::split" {
	    set procArgs [list {string} {?splitChars?}]
	}
	"::switch" {
	    set procArgs [list {?options? --} {string} {pattern1} {body} {?pattern body? ...}]
	}
	"::tell" {
	    set procArgs [list {channelId}]
	}
	"::time" {
	    set procArgs [list {script} {?count?}]
	}
	"::unset" {
	    set procArgs [list {?-nocomplain --?} {name} {?name name ...?}]
	}
	"::uplevel" {
	    set procArgs [list {?level?} {arg} {?arg ...?}]
	}
	"::upvar" {
	    set procArgs [list {?level?} {otherVar} {myVar} {?otherVar myVar ...?}]
	}
	"::variable" {
	    set procArgs [list {name} {?value?}]
	}
	"::while" {
	    set procArgs [list {test} {body}]
	}
	"::array" - "::file" - "::history" - "::info" - "::interp" - "::namespace" -
	"::package" - "::slave" - "::string" - "::trace" {
	    set procArgs [list {(many options availableÉ)}]
	}
    }
    if {[info exists procArgs]} {
	return $procArgs
    }
    # Special cases complete.
    set procArgs [list]
    # Make sure that we have the procedure loaded.
    if {[catch {$interpCmd "info args $ProcName"} arguments]} {
	if {[catch {$interpCmd "auto_load $ProcName"} loaded] || !$loaded} {
	    return $procArgs
	} elseif {[catch {$interpCmd "info args $ProcName"} arguments]} {
	    return $procArgs
	}
    }
    if {![llength $arguments]} {
	return $procArgs
    }
    foreach arg $arguments {
	if {[$interpCmd "info default $ProcName $arg ::_defaultArgValue"]} {
	    lappend procArgs "?$arg \"${::_defaultArgValue}\"?"
	} else {
	    lappend procArgs $arg
	}
    }
    unset -nocomplain ::_defaultArgValue
    return $procArgs
}

# ×××× -------- ×××× #

namespace eval procs {}

proc procs::quickFindDefn {} {
    set procName [prompt::statusLineComplete "proc" procs::complete]
    Tcl::DblClickHelper $procName
    return
}

proc procs::complete {pref} {
    
    if {[regexp {(.*)([^:]+)$} $pref "" start tail]} {
	set cmds [info commands ${pref}*]
	foreach child [namespace children ::$start] {
	    if {[string match "::${tail}*" $child]} {
		foreach cmd [info commands ${start}${child}::*] {
		    lappend cmds [string trimleft $cmd :]
		}
	    }
	}
	return $cmds
    } else {
	return [info commands ${pref}*]
    }
}

proc procs::reformatEnclosing {pos} {
    
    global Tcl::searchPats
    
    set pat [set Tcl::searchPats(1)]
    if {![catch {Tcl::parseFunctionInfo $pos $pat 0 1} pp]} {
	eval selectText $pp
	::indentRegion
	return 1
    } else {
	status::msg "Could not find enclosing function."
	return 0
    }
}

proc procs::loadEnclosing {args} {
    
    global Tcl::searchPats alpha::platform
    
    win::parseArgs w {pos ""}

    set pat [set Tcl::searchPats(1)]
    if {![string length $pos]} {
	set pos [getPos -w $w]
    }
    if {[catch {Tcl::parseFunctionInfo -w $w $pos $pat all} allInfo]} {
	if {[catch {Tcl::parseFunctionInfo -w $w $pos "" all} allInfo]} {
	    # Fall back on line evaluation
	    goto -w $w $pos
	    beginningLineSelect -w $w
	    endLineSelect -w $w
	    uplevel \#0 [list evaluate [getSelect -w $w]]
	    return
	}
    }
    set msg  ""
    set type [lindex $allInfo 1]
    set name [lindex $allInfo 2]
    set pos0 [lindex $allInfo end 0]
    set pos1 [lindex $allInfo end end]
    set txt  [getText -w $w $pos0 $pos1]
    if {($alpha::platform eq "alpha")} {
	regsub -all "\r" $txt "\n" txt
    }
    if {[catch {uplevel \#0 [list ::tcltk::directEvaluation $txt]} err]} {
	set pat {can't create procedure "(.*)": unknown namespace}
	if {[regexp -- $pat $err "" pr]} {
	    set msg "The procedure \[$pr\] couldn't be loaded, because\
	      it is in an unknown namespace.\r\rWould you like to create the\
	      namespace and try to load the procedure again?"
	    if {[dialog::yesno $msg]} {
		ensureNamespaceExists $pr
		return [procs::loadEnclosing -w $w $pos]
	    }
	}
	set msg "Error:  $err"
    } elseif {($type eq "proc")} {
	set msg "Loaded procedure:  \[$name\]"
    } else {
	set msg "Evaluated ${type}:  $name"
    }
    status::msg $msg
    return
}

# This should be cleaned up.

proc procs::findDefinition {{func ""}} {
    
    global TclmodeVars
    
    # Select a function.
    if {($func == "")} {
	set func [pick 1]
    }
    set fname [find $func]
    if {($fname == "")} {
	set fname [procs::findIn $func $TclmodeVars(procSearchPath)]
    }
    # If we don't have a filename, we can't do much here.
    if {($fname == "")} {
	error "Cancelled -- Can't find the source file for '$func'."
    } elseif {[catch {win::OpenQuietly $fname}]} {
	error "Cancelled -- Can't open the file '$fname'"
    }
    # First try a basic search.
    if {[regexp {^::} $func]} {
	set funcAlt [string trimleft $func ":"]
    } else {
	set funcAlt ::$func
    }
    foreach item [list $func $funcAlt] {
	set pat "proc\[\t \]+[quote::Regfind ${item}]\[ \t\]"
	set pos [search -n -s -f 1 -r 1 -i 0 -- $pat [minPos]]
	if {[llength $pos]} {
	    goto [lindex $pos 0]
	    return
	}
    }
    # We have a filename, so try to find the mark, first using truncated
    # versions of 'func' so that we can look for the actual mark name.
    # 'func' might be something like 'Bib::markFile', so first try to find
    # the '::markFile' mark.  This is used in Tcl < 8.0 only.
    if {[regexp {^[^:]+:+.*$} $func]} {
	regsub {^[^:]+} $func {} func1
	if {[string length $func1] && [editMark $fname $func1]} {
	    return
	}
    }
    # 'func' might be something like '::Bib::MarkFile', so try to
    # find the '::MarkFile' mark.
    if {[regexp {^::[^:]+::[^:]+.*$} $func]} {
	regsub {^::[^:]+} $func {} func1
	if {[string length $func1] && [editMark $fname $func1]} {
	    return
	}
    }
    # 'func' might be something like '::markFile', so try to find the
    # 'markFile' mark.  (This would pick up anything like '::electricLeft'
    # as well.)
    if {[regexp {^::[^:]+$} $func]} {
	regsub {^::} $func {} func1
	if {[string length $func1] && [editMark $fname $func1]} {
	    return
	}
    }
    # Still here ...  try removing all leading namespaces and '::'.  This
    # works for funcs like '::Bib::Completions::Entry'.
    if {[regexp {^.*::[^:]+.*$} $func]} {
	regsub {^.*::} $func {} func1
	if {[string length $func1] && [editMark $fname $func1]} {
	    return
	}
    }
    # Now try the full 'func' name, just so we can say we tried.  (If
    # everything else failed, this probably will as well.)
    if {[editMark $fname $func]} {
	return
    }
    # We tried ...
    set fname [file tail $fname]
    error "Cancelled -- Couldn't find the definition of '$func' in '$fname'"
}

proc procs::traceProc {func} {
    return [uplevel 1 [list traceTclProc $func]]
}

# ===========================================================================
# 
# .