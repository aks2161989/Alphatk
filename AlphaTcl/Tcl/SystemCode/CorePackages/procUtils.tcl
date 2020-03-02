## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 #
 # FILE: "procUtils.tcl"
 #                                          created: 08/02/1997 {06:18:16 pm}
 #                                      last update: 03/21/2006 {01:22:28 PM}
 # Description:
 # 
 # Procedures that deal with defined procedures.
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta
 #         Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 #  
 # Copyright (c) 1997-2006  Vince Darley
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

proc procUtils.tcl {} {}

namespace eval procs {}

## 
 # -------------------------------------------------------------------------
 # 
 # "procs::pick" --
 # 
 # -------------------------------------------------------------------------
 ##
proc procs::pick {{try_sel 0}} {
    set sel ""
    if {$try_sel && [llength [winNames]] \
      && [string length [set sel [getSelect]]]} {
	if {[llength [uplevel \#0 [list info commands $sel]]] \
	  && ![catch {info args $sel}]} {
	    return $sel
	} 
    } else {
	set sel ""
    }
    set ns ::
    set upOneLevel "(up one level)"
    set L $sel
    while {1} {
	set procs [lsort -dictionary [namespace children $ns]]
	if {($ns ne "::")} {
	    set procs [linsert $procs 0 $upOneLevel]
	}
	eval lappend procs \
	  [lsort -dictionary [uplevel \#0 [list namespace eval $ns [list info procs]]]]
	if {([lsearch $procs $L] == -1)} {
	    set L [lindex $procs 0]
	} 
	set p "Pick a function or child namespace in '$ns'"
	set choice [listpick -p $p -L [list $L] $procs]
	if {($choice eq $upOneLevel)} {
	    set L $ns
	    set ns [namespace parent $ns]
	    continue
	}
	if {![regexp {^::} $choice]} {
	    if {${ns} == "::"} {
		return "::${choice}"
	    } else {
		return "${ns}::${choice}"
	    }
	}
	set ns $choice
    }
}

proc procs::debug {func {line 0}} {
    set n "* Debug of $func *"
    if {[lsearch -exact [winNames -f] $n] != -1} {
	bringToFront $n
    } else {
	new -n $n -m Tcl -text \
	  "# Edit the proc in place. Use:\r# 'Reload Proc'\
	  to activate changes\r# 'Apply Changes' to put\
	  these changes into the original file\
	  \r[procs::generate $func]" \
	  -dirty 0
    }
    if {$line > 0} {
	# Add one for the comment we inserted
	incr line 3
	goto [pos::fromRowCol $line 0]
	selectText [getPos] [nextLineStart [getPos]]
    }
}

proc procs::patchOriginalsFromFile {f {alerts 1} {keepwin ""}} {
    set openWins [winNames -f]
    # get fixed procs
    uplevel \#0 [list source $f]
    # use 'c' to store comments before each proc
    set procs [procs::listInFile $f c]
    # replace all Alpha's originals
    foreach p $procs {
	if {[catch {procs::autoReplace $p 0 1 c}]} {
	    # should not happen
	    lappend failed $p
	}
    }
    set nowOpen [winNames -f]	
    foreach f [lremove -- $nowOpen $openWins] {
	if {($f ne $keepwin)} {
	    bringToFront $f
	    goto [minPos]
	    killWindow
	}
    }	
    if {$alerts} {
	set cmd "alertnote"
    } else {
        set cmd "status::msg"
    }
    if {[info exists failed]} {
	$cmd "Couldn't find: $failed, this is BAD."
    }
    $cmd "Replaced [llength $procs] procs successfully."
}

proc procs::listInFile {f {comments ""}} {
    if {$comments != ""} { upvar 1 $comments c }
    # open the window
    win::OpenQuietly $f
    # get procs in order
    set pos [minPos]
    set markExpr "^\[ \t\]*proc"
    set procs ""
    while {![catch {search -s -f 1 -r 1 -m 0 -i 0 "$markExpr" $pos} res]} {
	set start [lindex $res 0]
	set end [nextLineStart $start]
	set text [lindex [getText $start $end] 1]
	set pos $end
	lappend procs $text
	set c($text) [getText [procs::getCommentPos $start] $start]
    }
    killWindow
    return $procs
}

## 
 # -------------------------------------------------------------------------
 # 
 # "procs::getCommentPos" --
 # 
 #  'p' should be the start of a proc.  This looks for a comment which
 #  precedes that procedure.  It returns the start of such a comment,
 #  or 'p' if none was found.  Blank lines are not allowed.
 # -------------------------------------------------------------------------
 ##
proc procs::getCommentPos {p} {
    set q [pos::prevLineStart $p]
    while {[pos::compare $p > [minPos]]} {
	set pp [lindex [search -n -s -f 1 -m 0 -r 1 -l $p -- "\[ \t\]*#" $q] 0]
	if {$pp == "" || ([pos::compare $pp != $q])} {
	    break
	}
	set p $q
	set q [pos::prevLineStart $q]
    }
    return $p
}

proc procs::generate {p} {
    if {[catch {info args $p}]} {
	if {![auto_load $p]} {
	    return -code error "No such procedure $p"
	}
    }
    set a "proc $p \{"
    foreach arg [info args $p] {
	if {[info default $p $arg v]} {
	    append a "\{[list $arg $v]\} "
	} else {
	    append a "$arg "
	}
    }
    set a [string trimright $a]
    append a "\} \{"
    append a [info body $p]
    append a "\}"
    global alpha::macos
    if {$alpha::macos} {
	regsub -all "\n" $a "\r" a
    }
    return $a
}

proc procs::searchFor {p} {
    set f [procs::find $p]
    if {![string length $f]} {
	global TclmodeVars
	set pwd [pwd]
	if {[info exists TclmodeVars(procSearchPath)]} {
	    foreach dir $TclmodeVars(procSearchPath) {
		cd $dir
		set names [grepnames "^\[ \t\]*;?proc [quote::Regfind $p]\[ \t\]" *]
		if {[llength $names]} {
		    cd $pwd
		    return [lindex $names 0]
		}
	    }
	}
    }
    return $f
}

proc procs::autoReplace {p {ask 1} {addAfterLast 0} {commentArrayVar ""}} {
    set f [procs::searchFor $p]

    if {$f == ""} { set f [win::Current] }
    
    if {$commentArrayVar != ""} { upvar 1 $commentArrayVar c }
    if {[info exists c($p)]} {
	set com $c($p)
    } else {
	set com ""
    }
    
    procs::replace $f $p $ask $addAfterLast $com
    
    if {[winDirty]} {
	saveUnmodified
    }
}

proc procs::replace {f p {ask 1} {addAfterLast 0} {commenttext ""}} {
    win::OpenQuietly $f

    if {[string length $commenttext]} {
	set newp "$commenttext[procs::generate $p]"
    } else {
	set newp [procs::generate $p]
    }
    if {[catch {set a [search -s -f 1 -r 1 -m 0 \
      "^\[ \t\]*proc\[ \t\]+[quote::Regfind $p]\[ \t\]" [minPos]]}]} {
	if {!$addAfterLast} {
	    if {$ask} {
		alertnote "Failed to find proc"
	    }
	    error "Failed to find proc"
	} else {
	    # we just add it after the last one
	    insertText "\r" $newp "\r\r"
	    return
	}
    }
    goto [lindex $a 0]
    set entire [procs::findEnclosing [lindex $a 1]]
    if {[string length $commenttext]} {
	set entire [list [procs::getCommentPos [lindex $entire 0]] [lindex $entire 1]]
    }	
    eval selectText $entire
    if {$newp eq [getSelect]} { 
	status::msg "No change"
	return 
    }
    if {$ask && ![dialog::yesno "Replace this procedure?"]} {
	error "cancel"
    }
    eval replaceText $entire [list $newp]
}

# If the first brace after 'proc' ends the current line, then
# assume the argument was a single arg with no braces.
# 
# If 'detailed' is set, we return five positions, shown here by 'X's
# 
# Xproc blah X{parameters}X X{body}X
# 
# Otherwise (detailed = 0) we just return the first and last 
# of these positions.
proc procs::findEnclosing {pos {type "proc"} {detailed 0} {may_move 0}} {
    set start [lindex [search -s -m 0 -r 1 -f 0 "^\[ \t\]*;?($type) " $pos] 0]

    # Add beginning of procedure
    lappend res $start
    
    # Find the parameter block
    set p1 [lindex [search -s -f 1 "\{" $start] 0]
    set p [matchIt "\{" [pos::math $p1 + 1]]
    # If we want a detailed specification, add the beginning and end of
    # the parameter block.
    if {$detailed} {lappend res $p1 $p}
    if {[string trim [getText $p1 [nextLineStart $p1]]] == "\{"} {
	# The parameter block wasn't wrapped with {}.  This means
	# what we inserted above was the actual proc body.
	if {[pos::compare $p < $pos]} {
	    error "couldn't get proc"
	} else {
	    # This item is wrong, but it'll
	    # do for the moment.
	    if {$detailed} {
		set res [linsert $res 1 $p]
	    }
	    set p [pos::math $p + 1]
	    set res [linsert $res 1 $p]
	    return $res
	}
    }
    # find the body
    set p [lindex [search -s -f 1 "\{" $p] 0]
    if {$detailed} {lappend res $p}
    # this should not fail.  
    set p [matchIt "\{" [pos::math $p + 1]]
    set p [pos::math $p + 1]
    if {[pos::compare $p < $pos] } { error "couldn't get proc" }
    lappend res $p
    return $res
}

proc procs::findEnclosingName {pos} {
    set p [lindex [procs::findEnclosing $pos] 0]
    regsub -all "\[ \t\]+" [string trim [getText $p [nextLineStart $p]] "\{ \t\n\r"] " " t
    return [lindex [split $t] 1]
}

proc procs::buildList {{interp ""} {ns ::}} {
    set procs [list]
    foreach proc [eval $interp [list info procs ${ns}*]] {
	regsub {^::} $proc {} proc
	lappend procs $proc
    }
    foreach subNS [eval $interp [list namespace children $ns]] {
	eval lappend procs [procs::buildList $interp "${subNS}::"]
    }
    return $procs
}

# ===========================================================================
# 
# .