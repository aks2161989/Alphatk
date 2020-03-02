## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 #
 # FILE: "coreFixes.tcl"
 #                                          created: 07/31/1997 {02:09:16 am}
 #                                      last update: 06/02/2006 {01:34:20 PM}
 # Description:
 # 
 # This file contains AlphaTcl procs which wrap around or replace core
 # (hard-coded) Alpha procs to fix some bugs they may have.  Sadly most core
 # Alpha bugs can't be fixed in this way.
 # 
 # Ultimately, one hopes, these bugs will be fixed and these procs can be
 # removed...  when they are fixed in the core, we can put in version checks 
 # as necessary, as in
 # 
 #     if {![alpha::package vsatisfies -loose $alpha::version 8.1]} {...}
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501
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

# If we have already sourced this file, then this proc will exist.
if {[llength [info procs coreFixes.tcl]]} {
    return "Core fixes have already been defined."
}

proc coreFixes.tcl {} {}

## 
 # --------------------------------------------------------------------------
 # 
 # "getOpts" --
 # 
 # Rudimentary option passing.  Uses upvar to get to the 'args' list of the
 # calling procedure and scans that.  Option information is stored in the
 # 'opts' array of the calling procedure.
 #  
 # Options are assumed to be flags, unless they occur in the optional
 # parameter list.  Then they are variables which take a value; the next item
 # in the args list.  If an item is a pair, then the first is the var name
 # and the second the number of arguments to give it.
 # 
 # (We've copied this here from "stringsLists.tcl" to avoid some bad
 # auto-loading problems if there are early startup errors.)
 # 
 # --------------------------------------------------------------------------
 ##

proc getOpts {{take_value ""} {set "set"}} {
    upvar 1 args a
    upvar 1 opts o
    if {($set eq "set")} {
	for {set i 0} {$i < [llength $a]} {incr i} {
	    set arg [lindex $a $i]
	    if {([string index $arg 0] ne "-")} {
		break
	    }
	    if {($arg eq "--")} {
		incr i
		break
	    }
	    set pattern "^-?[string range $arg 1 end]( .*)?$"
	    if {([set idx [lsearch -regexp $take_value $pattern]] == -1)} {
		set o($arg) 1
	    } elseif {([llength [set the_arg [lindex $take_value $idx]]] == 1)} {
		incr i
		set o($arg) [lindex $a $i]
	    } else {
		incr i
		set numargs [expr {[lindex $the_arg 1] -1}]
		set o($arg) [lrange $a $i [expr {$i + $numargs}]]
		incr i $numargs
	    }
	}
    } else {
	for {set i 0} {$i < [llength $a]} {incr i} {
	    set arg [lindex $a $i]
	    if {([string index $arg 0] ne "-")} {
		break
	    }
	    if {($arg eq "--")} {
		incr i
		break
	    }
	    if {([set idx [lsearch -regexp $take_value \
	      "^-?[string range $arg 1 end]( .*)?$"]] == -1)} {
		set o($arg) 1
	    } elseif {([llength [set the_arg [lindex $take_value $idx]]] == 1)} {
		incr i
		$set o($arg) [lindex $a $i]
	    } else {
		incr i
		set numargs [expr {[lindex $the_arg 1] -1}]
		$set o($arg) [lrange $a $i [expr {$i + $numargs}]]
		incr i $numargs
	    }
	}
    }
    set a [lrange $a $i end]
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "tclLog" --
 # 
 # We will remove this when Alpha's core stops calling it.  This procedure is
 # really private to Tcl and we should not be over-riding it.  We use
 # [alpha::log]/[alpha::stdout]/[alpha::stderr] (see "initialize.tcl").
 # 
 # --------------------------------------------------------------------------
 ##

proc tclLog {args} {
    alpha::stderr [string trim [join $args ""] "\r\n"]
    return
}

# Workaround for Alpha 8/X bug: [getScrap] throws error when there is no
# clipboard.  See e.g. bug 1781, bug 683
if {[catch {getScrap}]} {
    catch {putScrap ""}
}

# ◊◊◊◊ Renaming/removing core commands ◊◊◊◊ #

# [zapInvisibles] was renamed [zapNonPrintables] in Alpha8/X 8.0b15-D10
if {[llength [info commands zapInvisibles]]} {
    alpha::stderr "Renaming the core command \[zapInvisibles\]"
    rename zapInvisibles zapNonPrintables
}
if {[llength [info commands icURL]]} {
    alpha::stderr "Renaming the core command \[icURL\]"
    rename icURL alpha::executeURL
}
if {[llength [info commands splitWindow]]} {
    alpha::stderr "Renaming the core command \[splitWindow\]"
    rename splitWindow toggleSplitWindow
}
if {[llength [info commands select]] && ![llength [info commands selectText]]} {
    alpha::stderr "Renaming the core command \[select\]"
    rename select selectText
}

# None of these core commands exist in Alphatk.  We should ensure they are
# all removed from Alpha 8/X and then we can delete this section of code.
foreach cmd {
    coerce copyFile cp createTagFile currentPosition
    endKeyboardMacro evaluate exchangePointAndMark mkdir
    executeKeyboardMacro fileInfo fileMenu fileRemove findTag freeMem
    getMark getPathName insertFile insertPathName isearch
    keyboardMacro kt markHilite moveFile postHigh
    rectMarkHilite removeFile replaceAllOld rmdir rsearch
    setCompiler setMark startKeyboardMacro substituteVars tagFileName
    traceDump traceFunc winFuncTitle xtclcmd
    upcaseRegion downcaseRegion
} {
    if {[llength [info commands $cmd]]} {
	alpha::stderr "Removing obsolete core command \[$cmd\]"
	rename $cmd ""
    }
}
unset -nocomplain cmd

# ===========================================================================
# 
# ◊◊◊◊ -------- ◊◊◊◊ #
# 
# ◊◊◊◊ Menus, Floats ◊◊◊◊ #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "menu::inserted" --
 # 
 # Alphatk doesn't need this, but AlphaX currently still does.  AlphaX needs
 # to add the [menu::inserted] command _and_ allow [insertMenu], [removeMenu]
 # to take multiple menu name arguments.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval menu {}

if {![llength [info commands menu::inserted]]} {
    # [insertMenu]
    if {![llength [info commands __insertMenu]]} {
	rename insertMenu __insertMenu
    }
    alpha::stderr "Redefining the core command \[insertMenu\]"
    ;proc insertMenu {args} {
	global menu::toplevels
	foreach m $args {
	    __insertMenu $m
	    set menu::toplevels($m) 1
	}
	return
    }
    # [removeMenu]
    if {![llength [info commands __removeMenu]]} {
	rename removeMenu __removeMenu
    }
    alpha::stderr "Redefining the core command \[removeMenu\]"
    ;proc removeMenu {args} {
	global menu::toplevels
	foreach m $args {
	    __removeMenu $m
	    set menu::toplevels($m) 0
	}
	return
    }
    # [menu::inserted]
    alpha::stderr "Defining the command \[menu::inserted\]"
    ;proc menu::inserted {m} {
	variable toplevels
	if {[info exists toplevels($m)]} {
	    return $toplevels($m)
	} else {
	    return 0
	}
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "float" --  -m <menu> [<-h|-w|-l|-t|-M> <val>] [-n winname] [-z tag]
 # 
 # Takes a created menu (not necessarily in the menubar), and makes a
 # floating window out of it.  Returns integer tag that is used to remove the
 # window.  With no arguments, returns all currently defined menus.  -h
 # through -M change width, height, left margin, top margin, and margin
 # between buttons.  -z allows a ten-char tag to be specified for
 # 'floatShowHide'.
 # 
 # This core fix for both Alphatk and AlphaX helps ensure that menu command
 # "File > Close Float" is properly enabled by keeping track of all floated
 # menus.  It could possibly be removed if the core called an AlphaTcl hook
 # whenever floats are created/destroyed.
 # 
 # --------------------------------------------------------------------------
 ##

if {![llength [info commands __float]]} {
    alpha::stderr "Redefining the core command \[float\]"
    rename float __float
}

;proc float {args} {
    global menu::floats
    set fl [uplevel 1 [list __float] $args]
    if {![info exists menu::floats($fl)]} {
	set menu::floats($fl) 1
    }
    catch {enableMenuItem File closeFloat 1}
    return $fl
}

# This really should be handled elsewhere, after the menu has been created.
catch {enableMenuItem File closeFloat 0}

## 
 # --------------------------------------------------------------------------
 # 
 # "unfloat" --  <float num>
 # 
 # Removes specified floating window.  W/ no options lists all floating
 # windows.
 # 
 # This core fix for both Alphatk and AlphaX helps ensure that menu command
 # "File > Close Float" is properly enabled by keeping track of all floated
 # menus.  It could possibly be removed if the core called an AlphaTcl hook
 # whenever floats are created/destroyed.
 # 
 # If arguments are supplied, this version of [unfloat] returns "1" if the
 # float was successfully destroyed, otherwise "0".
 # 
 # --------------------------------------------------------------------------
 ##

if {![llength [info commands __unfloat]]} {
    alpha::stderr "Redefining the core command \[unfloat\]"
    rename unfloat __unfloat
}

;proc unfloat {{which ""}} {
    global menu::floats
    if {($which eq "")} {
	return [__unfloat]
    } elseif {[catch {__unfloat $which}]} {
	return 0
    } else {
	unset -nocomplain menu::floats($which)
	set dim [expr {[array size menu::floats] ? "1" : "0"}]
	catch {enableMenuItem File closeFloat $dim}
	return 1
    }
}

# ===========================================================================
# 
# ◊◊◊◊ -------- ◊◊◊◊ #
# 
# ◊◊◊◊ Window Display, etc. ◊◊◊◊ #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "balance" --  ?-w <win>?
 # 
 # Selects smallest set of parens, braces, or brackets that encloses the
 # current cursor position, i.e. (), {}, and [], but not <>.  If there is
 # initially a selection, [balance] operates on the position that starts the
 # selection.  Starting from the initial position it searches backward until
 # it finds one of the enclosers: (, {, or [.  It ignores any of these
 # characters which is preceded by a backslash.  When (if) it finds one then
 # it looks in the other direction for the matching character, again ignoring
 # escaped characters.  An error is thrown if any of this fails, and the
 # cursor is returned to the initial position.  Don't throw this error onto
 # the user.
 # 
 # This core fix for AlphaX ensures that the error doesn't propogate into a
 # full-blown error window for the user.
 # 
 # --------------------------------------------------------------------------
 ##

if {($alpha::platform eq "alpha")} {
    if {![llength [info commands __balance]]} {
	rename balance __balance
    }
    alpha::stderr "Redefining the core command \[balance\]"
    ;proc balance {args} {
	if {[catch {uplevel 1 [list __balance] $args} err]} {
	    if {![regexp -nocase "cancel" $err]} {
		set err "Cancelled -- could not find enclosing delimiters."
	    }
	    return -code error $err
	}
	return
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "selectText" --  ?-w <win>? <pos1> <pos2>
 # 
 # Selects the text between 'pos1' and 'pos2'.
 # 
 # This core fix for Alpha8/X will only select if current selection (if any)
 # doesn't include the exact boundaries to be selected.  Otherwise this will
 # be 'flashy' in Alpha8 -- this should be fixed, and perhaps it is no longer
 # necessary for AlphaX.
 # 
 # --------------------------------------------------------------------------
 ##

if {($alpha::platform eq "alpha")} {
    if {![llength [info commands __selectText]]} {
	rename selectText __selectText
    }
    alpha::stderr "Redefining the core command \[selectText\]"
    ;proc selectText {args} {
	win::parseArgs w pos0 {pos1 ""}
	if {($pos1 eq "")} {
	    set pos1 $pos0
	} elseif {[pos::compare -w $w $pos1 < $pos0]} {
	    set pos0a $pos1
	    set pos1a $pos0
	    set pos0  $pos0a
	    set pos1  $pos1a
	}
	if {[pos::compare -w $w $pos0 != [getPos -w $w]] \
	  || [pos::compare -w $w $pos1 != [selEnd -w $w]]} {
	    __selectText -w $w $pos0 $pos1
	}
	return
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "centerRedraw" --  ?-w <win>?
 # 
 # Redraw window with current line in the middle.
 # 
 # This core fix for AlphaX ensures that any selections already present are
 # maintained when we're done.
 # 
 # --------------------------------------------------------------------------
 ##

if {($alpha::platform eq "alpha")} {
    if {![llength [info commands __centerRedraw]]} {
	rename centerRedraw __centerRedraw
    }
    alpha::stderr "Redefining the core command \[centerRedraw\]"
    ;proc centerRedraw {args} {
	win::parseArgs w
	lappend selectionEndPoints [getPos -w $w] [selEnd -w $w]
	uplevel 1 [list __centerRedraw -w $w]
	eval [list selectText -w $w] $selectionEndPoints
	return
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "insertToTop" --  ?-w <win>?
 # 
 # Make the line that the insertion point is on the first line shown.
 # 
 # This core fix for AlphaX ensures that any selections already present are
 # maintained when we're done.
 # 
 # --------------------------------------------------------------------------
 ##

if {($alpha::platform eq "alpha")} {
    if {![llength [info commands __insertToTop]]} {
	rename insertToTop __insertToTop
    }
    alpha::stderr "Redefining the core command \[insertToTop\]"
    ;proc insertToTop {args} {
	win::parseArgs w
	set winCur [win::Current]
	lappend selectionEndPoints [getPos -w $winCur] [selEnd -w $winCur]
	uplevel 1 [list __insertToTop -w $w]
	eval [list selectText -w $winCur] $selectionEndPoints
	return
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "clear" --
 # 
 # This core fix for Alpha8/X ensures that no error is thrown if there is no
 # selection present.
 # 
 # (This seems like a good candidate for an AlphaTcl procedure; there is no
 # apparent reason to define this in the core.)
 # 
 # --------------------------------------------------------------------------
 ##

if {($alpha::platform eq "alpha")} {
    alpha::stderr "Redefining the core command \[clear\]"
    proc clear {args} {
	win::parseArgs w
	if {[isSelection -w $w]} {
	    deleteSelection -w $w
	}
	return
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "placeText" --  ?-w <win>? position text
 # 
 # This is an enhanced version of [insertText] which allows the caller to
 # specify where the text should be placed, and ensures that any previous
 # selection is restored.
 # 
 # (This seems like a good candidate for an AlphaTcl procedure; there is no
 # apparent reason to define this in the core.)
 # 
 # --------------------------------------------------------------------------
 ##

if {![llength [info commands placeText]]} {
    alpha::stderr "Defining the core command \[placeText\]"
    ;proc placeText {args} {
	win::parseArgs w pos text
	lappend selectionEndPoints [getPos -w $w] [selEnd -w $w]
	replaceText -w $w $pos $pos $text
	eval [list selectText -w $w] $selectionEndPoints
	return
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "blink" --  ?-w <win>? <pos>
 # 
 # Blink cursor at 'pos'.
 # 
 # This core fix for Alphatk/X ensures that if the position to blink is
 # offscreen, a message with context will be displayed to the user.
 # 
 # --------------------------------------------------------------------------
 ##

if {![llength [info commands __blink]]} {
    alpha::stderr "Redefining the core command \[blink\]"
    rename blink __blink
}

;proc blink {pos} {
    __blink $pos
    getWinInfo w
    if {[info exists w(currline)]} {
	set topl $w(currline)
	set endl [expr {$topl + $w(linesdisp)}]
	set row [lindex [pos::toRowChar $pos] 0]
	if {$row < $topl || $row >= $endl} {
	    status::msg "Matching '[getText [lineStart $pos] [pos::math $pos + 1]]'"
	}
    }
    return
}

# ===========================================================================
# 
# ◊◊◊◊ -------- ◊◊◊◊ #
# 
# ◊◊◊◊ File, Window Handling ◊◊◊◊ #
# 

namespace eval win {}

## 
 # --------------------------------------------------------------------------
 # 
 # "win::Current" --
 # 
 # Returns the full name of the current window, or the empty string if no
 # windows are currently open.  This is always the same as
 # 
 #     [lindex [winNames -f] 0]
 # 
 # Note that if a window is currently in the process of being opened (e.g.
 # this function is called from [alpha::openHook] or related procedures) then
 # [win::Current] will not necessarily return the new window name.  It might
 # be being opened in a hidden state, for example.
 # 
 # Alphatk/8/X core should implement this.
 # 
 # --------------------------------------------------------------------------
 ##

if {![llength [info commands win::Current]]} {
    alpha::stderr "Defining the core command \[win::Current\]"
    ;proc win::Current {} {
	return [lindex [winNames -f] 0]
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "putfile" --  <prompt> <original>
 # 
 # Display a SFPutFile() and return either the full path name of the selected
 # path (including the file name chosen by the user), or an empty string if
 # "Cancel" button was selected.  The "original" argument is displayed for
 # the user in the dialog as the default file name.  There is no control over
 # the default location for the folder; with an "original" name that doesn't
 # exist, the default folder location is always determined by the System.
 # 
 # Because Alpha7 actually wanted the tail of the file, rather than the full
 # name, we ensured that this is what is supplied.  It appears now a valid
 # path will be taken into account to set the default location, but the final
 # item in the path will be used as the default file name.  In other words,
 # it is possible to define a default path _or_ a default name, but not both.
 # This really should be fixed in the core.
 # 
 # --------------------------------------------------------------------------
 ##

if {![llength [info commands __putfile]]} {
    alpha::stderr "Redefining the core command \[putfile\]"
    rename putfile __putfile
}

proc putfile {args} {
    if {([llength $args] == 2)} {
	lset args 1 [file tail [lindex $args 1]]
    }
    return [uplevel 1 [list __putfile] $args]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "findFile" --  ?path?
 # 
 # Open a file in a new window.  An optional path parameter specifies a
 # default directory or file.
 # 
 # With this version, we open a [getfile] dialog to locate a file to edit,
 # where "path" can be a directory or a file.  If the path is empty (or if it
 # doesn't exist), the default will be directory of the last file opened by
 # the user.
 # 
 # This returns a two item list: the first is the name of the path that was
 # selected by the user, the second if the window created by Alpha including
 # any <2> window decoration.
 # 
 # We make sure that a proper "lastFindFilePath" default is defined for
 # [findFile], and that this will be remembered between editing sessions.
 # 
 # This is a "coreImplementations.tcl" candidate.
 # 
 # --------------------------------------------------------------------------
 ##

if {![info exists ::lastFindFilePath]} {
    set ::lastFindFilePath [pwd]
}
prefs::modified ::lastFindFilePath

proc findFile {{path ""}} {
    global lastFindFilePath
    
    if {![string length $path] || ![file exists $path]} {
	set path $lastFindFilePath
    }
    set filename [getfile -types {TEXT \0\0\0\0 ????} "Open which file:" $path]
    if {![file exists $filename]} {
	# This can possibly occur when trying to edit broken symlinks,
	# at least on Windows.
	alertnote "The file \"$filename\" doesn't seem to exist, so it\
	  cannot be edited"
	error "Cancelled."
    } else {
	set w [edit -c $filename]
	set lastFindFilePath [file dirname $filename]
	return [list $filename $w]
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "getfile" --  ?switches? ?prompt? ?path?
 # 
 # Open an OS dialog to obtain the name of a locally installed file.
 # 
 # Switches include:
 # 
 # -types <typeslist> :
 # 
 #     A list of MacOS file "types" that should be enabled in the dialog.
 #     Defaults to TEXT and empty type codes.
 # 
 # -openPackages <boolean> :
 # 
 #     Determines if the contents MacOSX "packages" can be inspected and
 #     selected.  Defaults to global preference value if it exists.
 # 
 # -showInvisibleFiles <boolean> :
 # 
 #     Determines if invisible files will be shown in the dialog.  Defaults
 #     to the global preference value if it exists.
 # 
 # Returns the full path of the file chosen by the user.
 # 
 # --------------------------------------------------------------------------
 # 
 # Core Fix #1: In MacClassic, when "useNavServices" is turned off, the
 # default directory shown is incorrect -- CustomGetFile() doesn't do the
 # right thing with directories.  (Bug# 397)
 # 
 # Core Fix #2: We make sure that a "lastGetfilePath" default is defined for
 # [getfile], and that this will be remembered between editing sessions.
 # This value is used if the supplied path is the null string.  (Bug# 606)
 # Apparently this is not possible for the AlphaX core to easily control, so
 # this fix is likely to remain here permanently.
 # 
 # --------------------------------------------------------------------------
 ##

if {![info exists ::lastGetfilePath]} {
    set ::lastGetfilePath [pwd]
}
prefs::modified ::lastGetfilePath

if {![llength [info commands "::__getfile"]]} {
    alpha::stderr "Redefining the core command \[getfile\]"
    rename ::getfile ::__getfile
}

;proc getfile {args} {
    
    global useNavServices lastGetfilePath
    
    set script [list "__getfile"]
    # Deal with switches and arguments.
    getOpts {-types -openPackages -showInvisibleFiles}
    if {([llength $args] > 2)} {
	error {usage: getfile ?switches? ?prompt? ?path?}
    }
    set prefOpts [list "openPackages" "showInvisibleFiles"]
    foreach opt [array names opts] {
	set prefName [string trimleft $opt "-"]
	global $prefName
	if {([lsearch $prefOpts $prefName] == -1) || [info exists $prefName]} {
	    lappend script $opt $opts($opt)
	}
    }
    # Ensure that we have prompt text.
    if {([set promptText [lindex $args 0]] eq "")} {
	set promptText "Locate a file:"
    }
    # Ensure the default path exists, using the last path if none supplied.
    # (Fix for bug# 606)
    set defaultPath [lindex $args 1]
    if {($defaultPath eq "")} {
	set defaultPath $lastGetfilePath
    }
    while {![file exists $defaultPath]} {
	set defaultPath [file dirname $defaultPath]
	if {($defaultPath eq [file dirname $defaultPath])} {
	    break
	}
    }
    # (Fix for bug# 397.)
    if {[info exists useNavServices] && !$useNavServices \
      && [file isdirectory $defaultPath]} {
	set defaultPath [file join $defaultPath " "]
    }
    # Add the final "prompt" and "defaultPath" arguments.
    lappend script "--" $promptText $defaultPath
    # Open the dialog to get the file.
    if {[catch {eval $script} result]} {
	error $result
    } else {
	return [set lastGetfilePath $result]
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "editDocument" --
 # 
 # Based on Alphatk's [editDocument] in "alpha_io.tcl", this forms the major
 # [edit] intervention to ensure that initial window settings are in place.
 # 
 # --------------------------------------------------------------------------
 ##

if {($alpha::platform eq "alpha")} {
    alpha::stderr "Defining the core command \[editDocument\]"
    ;proc editDocument {args} {
	set resize 0
	set marksMenuOnly 0
	
	set newWinAsk 1
	set readOnlyAsk 1
	set wrapAsk 1
	
	set parameters {}
	
	set i 0
	while {([set arg [lindex $args $i]] ne "")} {
	    switch -- $arg {
		"-tabsize" {
		    set tabsize [lindex $args [incr i]]
		    set args [lreplace $args [expr {$i-1}] $i]
		    incr i -1
		}
		"-c" {
		    set newWinAsk 0
		    lappend parameters NewW no
		    set args [lreplace $args $i $i]
		}
		"-g" {
		    set resize 1
		    set left [lindex $args [incr i]]
		    set top [lindex $args [incr i]]
		    set width [lindex $args [incr i]]
		    set height [lindex $args [incr i]]
		    set args [lreplace $args [expr {$i-4}] $i]
		    incr i -4
		}
		"-m" {
		    set marksMenuOnly 1
		    set args [lreplace $args $i $i]
		}
		"-r" {
		    set readOnlyAsk 0
		    lappend parameters perm no
		    set args [lreplace $args $i $i]
		}
		"-w" {
		    set wrapAsk 0
		    lappend parameters Wrap no
		    set args [lreplace $args $i $i]
		}
		"-mode" {
		    set mode [lindex $args [incr i]]
		    set args [lreplace $args [expr {$i-1}] $i]
		    incr i -1
		}
		"-encoding" {
		    set encoding [lindex $args [incr i]]
		    set args [lreplace $args [expr {$i-1}] $i]
		    incr i -1
		    # ignore this flag at present.
		}
		"-visibility" {
		    set visibility [lindex $args [incr i]]
		    set args [lreplace $args [expr {$i-1}] $i]
		    incr i -1
		}
		"--" {
		    set args [lreplace $args $i $i]
		    break
		}
		default {
		    break
		}
	    }
	}
	
	if {$newWinAsk} {
	    lappend parameters NewW ask
	}
	if {$readOnlyAsk} {
	    lappend parameters perm ask
	}
	if {$wrapAsk} {
	    lappend parameters Wrap ask
	}
	if {[info exists mode]} {
	    lappend parameters Mode [tclAE::build::TEXT $mode]
	}
	if {[info exists visibility]} {
	    lappend parameters iViz [tclAE::build::TEXT $visibility]
	}
	
	if {([set path [lindex $args $i]] eq "")} {
	    error "No file name specified for edit"
	}
	
	set path [file normalize $path]
	
	lappend parameters ---- [tclAE::build::alis $path]
	
	# Retreive the name attributed by the odoc handler from the AE's reply
	set winname [eval [list tclAE::build::resultData -s -dr aevt odoc] $parameters]
	
	if {[info exists tabsize]} {
	    setWinInfo -w $winname tabsize $tabsize
	}
	if {$resize} {
	    moveWin $winname $left $top
	    sizeWin $winname $width $height
	}
	if {$marksMenuOnly} {
	    setWinInfo -w $winname marksMenuOnly 1
	}
	return $winname
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "revert" --  ?-w <win>?
 # 
 # Revert the file to its last saved version.
 # 
 # This core fix for AlphaX will keep window vertical position the same, and
 # ensure [revertHook] is called.  Also simply returns with the standard
 # error if there is no current window.
 # 
 # --------------------------------------------------------------------------
 ##

if {($alpha::platform eq "alpha")} {
    if {![llength [info commands __revert]]} {
	rename revert __revert
    }
    alpha::stderr "Redefining the core command \[revert\]"
    ;proc revert {args} {
	if {![llength [winNames]]} {
	    error "Cancelled - no window open"
	}
	if {[llength $args] && ([lindex $args 0] eq "-w")} {
	    set win [lindex $args 1]
	} else {
	    set win [win::Current]
	}
	getWinInfo -w $win w
	set topl $w(currline)
	uplevel __revert $args
	revertHook $win
	display -w $win [pos::fromRowCol -w $win $topl 0]
	return
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "save" --  ?<win>?
 # 
 # Save current window, or given window.  If the window has never been saved,
 # then this will be re-routed, internally, to [saveAs].
 # 
 # This core fix for Alphatk/X handles the potential issues raised when a
 # window to be saved no longer exists on disk.
 # 
 # --------------------------------------------------------------------------
 ##

if {![llength [info commands __save]]} {
    alpha::stderr "Redefining the core command \[save\]"
    rename save __save
}

;proc save {{name ""}} {
    if {($name eq "")} {
	set name [win::Current]
	if {($name eq "")} {
	    error "Cancelled - no window open"
	}
    }
    set origName $name
    if {![win::IsFile $origName name]} {
	if {[win::infoExists $origName Modified]} {
	    if {![dialog::yesno "The file appears to have been moved\
	      since it was last opened or saved.  Are you sure you\
	      want to save it?"]} {
		error "Cancel: save cancelled by user, since file appears to\
		  have been moved."
	    }
	}
	# It's a new window which has never been saved
	set isNew 1
    } else {
	set modified [file mtime $name]
	if {![win::infoExists $origName Modified]} {
	    alertnote "Alpha doesn't seem to have any record of\
	      this file's modification date.  If you can reproduce\
	      its circumstances, please report a bug."
	    win::setInfo $origName Modified $modified
	} elseif {[win::getInfo $origName Modified] < $modified} {
	    # File has changed on disk
	    if {![dialog::yesno "This file has changed on disk.  Are you\
	      sure you want to save it?"]} {
		error "Cancel: save cancelled by user, since\
		  newer file existed."
	    }
	}
    }
    uplevel 1 [list __save $origName]
}

# ===========================================================================
# 
# ◊◊◊◊ -------- ◊◊◊◊ #
# 
# ◊◊◊◊ Positions ◊◊◊◊ #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "namespace eval pos" --
 # 
 # These core fixes are for AlphaX, and ensures that that commands
 # 
 #    minPos
 #    pos::compare
 #    pos::diff
 #    pos::fromRowChar
 #    pos::fromRowCol
 #    pos::math
 #    pos::toRowChar
 #    pos::toRowCol
 # 
 # are properly defined.
 # 
 # It also deals with the buggy [rowColToPos] and [posToRowCol] versions in
 # the AlphaX core: tabs are taken into account only with [posToRowCol], and
 # if the supplied 'pos' doesn't exist you will likely get an absurd result.
 # 
 # (Note to Alpha Cabal: AlphaX would most likely have better speed if these
 # (to/from)Row(Char/Col) procs were defined in the core.)
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval pos {}

if {($alpha::platform eq "alpha")} {

    # These are all used, but must not be global commands.  In Alpha8/X,
    # [rowColToPos] actually is [rowCharToPos].
    if {[llength [info commands rowColToPos]]} {
	alpha::stderr "Renaming core command \[rowColToPos\]"
	rename rowColToPos pos::__fromRowChar
    }
    # Rename this too.
    if {[llength [info commands posToRowCol]]} {
	alpha::stderr "Renaming core command \[posToRowCol\]"
	rename posToRowCol pos::__toRowCol
    }
    
    # Define these for Alpha8,X. If these applications define these commands
    # in the core, they will already be defined before this file is sourced.

    set posProcs [list "minPos" "pos::compare" "pos::math" "pos::diff" \
      "pos::fromRowChar" "pos::fromRowCol" "pos::toRowChar" "pos::toRowCol" ]
    foreach posProc $posProcs {
	if {[llength [info command $posProc]]} {
	    continue
	}
	alpha::stderr "Defining the core command \[$posProc\]"
	switch -- $posProc {
	    "minPos" {
		# • minPos - returns the first position in the current
		#     window.  This will normally be '0' in Alpha 7.x, but for
		#     compatibility with Alphatk (in which it is 1.0) should
		#     not be so assumed.
		proc minPos {args} {
		    return 0
		}
	    }
	    "pos::compare" {
		# • pos::compare <pos1> <comparison> <pos2> returns 1 or
		#     0 depending on whether the given comparison is true or
		#     not.  Valid comparisons include ==, !=, <, >, <=, >=
		#     etc.  For future compatibility, pos::compare should be
		#     used in preference to a direct, numerical comparison.
		#     
		# These don't check to see if the positions are valid,
		# unfortunately.  Don't try to use 'pos::_ensureValid' in
		# here, else you'l have an infinite loop !!
		proc pos::compare {args} {
		    _getWPos
		    expr $args
		}
	    }
	    "pos::math" {
		# • pos::math <pos> ?+/- offset?  ...  returns that
		#     position which is given by moving the given number of
		#     characters backwards or forwards in the current window. 
		#     Any number of offset arguments may be given, with or
		#     without spaces separating the arguments.  For future
		#     compatibility pos::math should be used in preference to
		#     numerical addition: positions cannot be assumed to be
		#     simple integers.
		proc pos::math {args} {
		    _getWPos
		    _ensureValid $w [expr $args]
		}
	    }
	    "pos::diff" {
		# • pos::diff <pos1> <pos2> returns the number of characters
		#     between the two positions in the current window.
		proc pos::diff {args} {
		    _getWPos
		    if {([llength $args] != 2)} {
			error {Incorrect number of args: [-w <window>] <p1> <p2>}
		    }
		    set pos0 [_ensureValid $w [lindex $args 0]]
		    set pos1 [_ensureValid $w [lindex $args 1]]
		    expr {$pos1 - $pos0}
		}
	    }
	    "pos::fromRowChar" {
		# We do some more work to ensure that the position returned
		# is actually on the same line, giving the end position if
		# 'char' exceeds the length, or if 'char' is 'end'.  The
		# only difference between the two versions is the ability
		# to call procs within namespaces.
		proc pos::fromRowChar {args} {
		    _getWPos
		    if {([llength $args] != 2)} {
			error {Incorrect number of args: [-w <window>] <row> <char>}
		    }
		    set row  [lindex $args 0]
		    set char [lindex $args 1]
		    set pos1 [__fromRowChar -w $w $row 0]
		    set pos2 [lineEnd       -w $w $pos1]
		    set line [getText       -w $w $pos1 $pos2]
		    if {($char == "0") || ![set limit [string length $line]]} {
			set pos1
		    } elseif {($char eq "end") || ($char >= $limit)} {
			set pos2
		    } else {
			expr {$pos1 + $char}
		    }
		}
	    }
	    "pos::fromRowCol" {
		# Find this position in the line by converting tabs to
		# spaces and then incrementally adding chars from column 0
		# to column 'col' until we meet or exceed the limit.  'col'
		# can actually be 'end' here to get the end position.  The
		# only difference between the two versions is the ability
		# to call procs within namespaces.
		proc pos::fromRowCol {args} {
		    _getWPos
		    if {([llength $args] != 2)} {
			error {Incorrect number of args: [-w <window>] <row> <col>}
		    }
		    set row  [lindex $args 0]
		    set col  [lindex $args 1]
		    set pos1 [__fromRowChar -w $w $row 0]
		    set pos2 [lineEnd       -w $w $pos1]
		    set line [getText       -w $w $pos1 $pos2]
		    if {($col == "0") || ![set limit [string length $line]]} {
			set pos1
		    } elseif {($col eq "end")} {
			set pos2
		    } elseif {![regexp "\t" $line]} {
			expr {$pos1 + [expr {$col > $limit ? $limit : $col}]}
		    } else {
			set idx 0
			while {1} {
			    set lineX [string range $line 0 $idx]
			    set lineX [text::maxSpaceForm -w $w $lineX]
			    incr idx
			    if {[string length $lineX] >= $col} {
				return [expr {$pos1 + $idx}]
			    } elseif {($idx >= $limit)} {
				return $pos2
			    }
			}
		    }
		}
	    }
	    "pos::toRowChar" {
		proc pos::toRowChar {args} {
		    _getWPos
		    if {([llength $args] != 1)} {
			error {Incorrect number of args: [-w <window>] <position>}
		    }
		    set pos  [_ensureValid $w $pos]
		    set row  [lindex [__toRowCol -w $w $pos] 0]
		    set line [getText -w $w [lineStart -w $w $pos] $pos]
		    set char [string length $line]
		    list $row $char
		}
	    }
	    "pos::toRowCol" {
		# Alpha8 does this correctly, but we make sure that the
		# position we return (get) is valid.
		proc pos::toRowCol {args} {
		    _getWPos
		    __toRowCol -w $w [_ensureValid $w $pos]
		}
	    }
	}
    }
    unset posProcs posProc
}

# ===========================================================================
# 
# ◊◊◊◊ -------- ◊◊◊◊ #
# 
# ◊◊◊◊ Status bar, prompts ◊◊◊◊ #
# 

namespace eval status {}

## 
 # --------------------------------------------------------------------------
 # 
 # "status::flash" --
 # 
 # Change the color of the status bar for a given period of time.
 # 
 # This core fix for AlphaX ensure that the command exists, even though it 
 # is a no-op.
 # 
 # --------------------------------------------------------------------------
 ##

if {![llength [info commands status::flash]]} {
    alpha::stderr "Defining the core command \[status::flash\]"
    ;proc status::flash {args} {
	# Not implemented.
	return
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "status::prompt" --
 # 
 # This is a more useful and generally more powerful replacement for the
 # built in [statusPrompt].  It gives the caller more control and flexibility
 # about a variety of actions (especially 'delete' keys), while trying to
 # place as little burden on the caller as possible.
 #  
 # If you wish to query modifier key presses too, the current getModifier key
 # status can be appended to the command script too.
 #  
 # There are basically two ways of calling this procedure:
 #  
 # (i) old style: 'status::prompt ?-f? promptText ?promptFunc? ?add?'
 #  
 # See the documentation of statusPrompt for this case; it is very similar.
 # The given function is called with a few arguments appended, the old
 # string, the new char, and possibly the getModifier status.
 #  
 # (ii) new style: 'status::prompt ?-f? ?-add what? ?-command script? prompt'
 #  
 # In this case, the command script is expected to keep track of the current
 # prompt, and so the command script is evaluated with only 1 or 2 arguments
 # appended: the new character pressed, and optional the getModifier status.
 #  
 # An optional -debug flag can be used to [alpha::log] the command lines
 # used, and results from calling the command script.
 #  
 # For compatibility with Alphatk, you must not call [getModifiers] yourself,
 # but should use the optional '-add' argument.  ('-add anything' is usual).
 #  
 # -------------------------------------------------------------------------
 # 
 # This is a "coreImplementations.tcl" candidate, since it isn't really 
 # fixing anything in any core.
 # 
 # -------------------------------------------------------------------------
 ##

proc status::prompt {args} {
    set opts(-add) key
    getOpts {-command -add -appendvar}
    switch -- [llength $args] {
	default {
	    return -code error "Wrong number of args:\
	      status::prompt ?-f -add what\
	      -command script -appendvar var?\
	      prompt ?oldfunc? ?add?"
	}
	1 {
	    set prompt [lindex $args 0]
	    if {[info exists opts(-command)]} {
		set func $opts(-command)
		set oldstyle 0
	    } else {
		set func ""
		set oldstyle 1
	    }
	}
	2 {
	    set oldstyle 1
	    foreach {prompt func} $args {}
	}
	3 {
	    set oldstyle 1
	    foreach {prompt func opts(-add)} $args {}
	}
    }
    if {[info exists opts(-f)]} {
	status::flash black
    }
    if {![info exists prompt]} {
	return -code error "Wrong number of args:\
	  status::prompt ?-f -add what\
	  -command script -appendvar var?\
	  prompt ?oldfunc? ?add?"
    }
    set thePrompt $prompt
    status::msg $thePrompt
    set statuscontents ""
    while {1} {
	if {!$oldstyle} {
	    set statuscontents ""
	}
	set res [coreKeyPrompt $thePrompt$statuscontents]
	set args {}
	if {$oldstyle} {
	    lappend args $statuscontents
	}
	lappend args [lindex $res 0]
	switch -- $opts(-add) {
	    "modifiers" -
	    "anything" {
		lappend args [lindex $res 1]
	    }
	}
	if {[info exists opts(-debug)]} {
	    alpha::stdout "$func $args"
	}
	if {[string length $func]} {
	    if {[set err [catch [list uplevel 1 $func $args] res]]} {
		if {[info exists opts(-debug)]} {
		    global errorInfo
		    alpha::stdout "$err $res $errorInfo"
		}
		if {($err == 2)} {
		    return $res
		} else {
		    return -code $err $res
		}
	    }
	} else {
	    set res [lindex $args 1]
	    set ascii [text::Ascii $res]
	    if {($ascii == 27)} {
		error "Cancelled with escape"
	    }
	    if {$oldstyle && ($ascii == 8)} {
		if {[string length $statuscontents] > 0} {
		    set statuscontents [string range $statuscontents 0 end-1]
		} else {
		    error "Cancelled with backspace"
		}
		set thePrompt $prompt
		status::msg "$thePrompt$statuscontents"
		continue
	    } elseif {($ascii < 32)} {
		set res ""
	    }
	}
	if {$oldstyle} {
	    if {[info exists opts(-debug)]} {
		alpha::stdout "Returned: $res"
	    }
	    if {($res eq "")} {
		return $statuscontents
	    }
	}
	if {[info exists opts(-appendvar)]} {
	    upvar 1 $opts(-appendvar) pat
	    set thePrompt "${prompt}${pat}"
	    if {$oldstyle} {
		append statuscontents $res
	    }
	} else {
	    set thePrompt $prompt
	    if {$oldstyle} {
		append statuscontents $res
		status::msg "$thePrompt$statuscontents"
	    }
	}
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "coreKeyPrompt" --
 # 
 # Alpha 8/X has [betterStatusPrompt] which is both simpler and far more
 # robust, so we use that here.  This returns a two item list consisting of
 # the key and a modifier specification.  If the Shift key was pressed, not
 # only will this be reflected in the modifiers but the key will also be
 # returned in UPPER CASE.
 # 
 # --------------------------------------------------------------------------
 ##

if {![llength [info commands coreKeyPrompt]]} {
    alpha::stderr "Defining the core command \[coreKeyPrompt\]"
    proc coreKeyPrompt {thePrompt} {
	if {![catch {betterStatusPrompt $thePrompt} result]} {
	    set key  [lindex $result 1]
	    set mods [lindex $result 2]
	    if {($mods & 34)} {
		set key [string toupper $key]
	    }
	    return [list $key $mods]
	} elseif {([lindex $result 0] == 1)} {
	    return -code error "mouse click"
	} else {
	    return -code error [lindex $result 0]
	}
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "displayEncoding" --
 # 
 # In Alpha 8/X this should set the encoding popup in the status bar to the
 # given value.  At present it is a no-op.
 # 
 # --------------------------------------------------------------------------
 ##

if {![llength [info commands displayEncoding]]} {
    alpha::stderr "Defining the core command \[displayEncoding\]"
    proc displayEncoding {args} {
	# No action.
	return
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "displayPlatform" --
 # 
 # In Alpha 8/X this should set the platform popup in the status bar to the
 # given value.  Implemented in Alpha8/X 8.0b15-D7 (April 2004).
 # 
 # --------------------------------------------------------------------------
 ##

if {![llength [info commands displayPlatform]]} {
    alpha::stderr "Defining the core command \[displayPlatform\]"
    proc displayPlatform {p} {
	global platform mode
	set platform $p
	# To force update of all status bar pop-up menu displays.
	if {($mode ne "")} {
	    displayMode [mode::getName $mode 1]
	}
	return
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "displayState" --
 # 
 # Totally experimental proc for Alphatk to give the user some feedback on
 # window-mode + states.
 # 
 # --------------------------------------------------------------------------
 ##

if {($alpha::platform eq "alpha")} {
    proc displayState {args} {
	return
    }
} else {
    proc displayState {win} {
	status::msg -state [join [win::getStates $win] ,]
	return
    }
}

# ===========================================================================
# 
# ◊◊◊◊ -------- ◊◊◊◊ #
# 
# ◊◊◊◊ Macros ◊◊◊◊ #
# 
# Some of this stuff needs to go into AlphaX, or completely exposed to Tcl
# and moved into the "macros.tcl" package (then we could share all macros
# code between Alphatk and Alpha).
# 
# [macro::endRecording]
# 
#   Stop recording keyboard macro.
# 
# [macro::startRecording] :
# 
#   Start recording keyboard macro.
# 
# [macro::recording] :
# 
#   Are we currently recording?
# 
# We intervene in [macro::startRecording] and [macro::endRecording] to set 
# the current "recording" state.
# 

namespace eval macro {
    variable recording 0
    variable Current ""
}

if {($alpha::platform eq "alpha")} {
    
    if {[llength [info commands startKeyboardMacro]]} {
	alpha::stderr "Renaming the core command \[startKeyboardMacro\]"
	rename startKeyboardMacro macro::__startRecording
    }
    if {[llength [info commands endKeyboardMacro]]} {
	alpha::stderr "Renaming the core command \[endKeyboardMacro\]"
	rename endKeyboardMacro macro::__endRecording
    }
    if {[llength [info commands keyboardMacro]]} {
	alpha::stderr "Renaming the core command \[keyboardMacro\]"
	rename keyboardMacro macro::__current
    }
    
    proc macro::recording {} {
	variable recording
	return $recording
    }
    
    proc macro::startRecording {} {
	variable recording 1
	macro::__startRecording
	return
    }
    
    proc macro::endRecording {} {
	global alpha::platform
	variable recording
	if {!$recording} {
	    status::msg "Cancelled -- Not recording!"
	} else {
	    catch {
		macro::__endRecording
		set m [macro::__current]
		# Get rid of menu trace if its there.
		regsub "macro::menuProc\[^\r\n\]+endRecording(\}|\")*" $m "" m
		# Unfortunately Alpha 7 seems to build the macro with trailing
		# \r not \n, which means the proc is just invalid.
		if {($alpha::platform eq "alpha")} {
		    regsub -all "\r" $m "\n" m
		}
		macro::current $m
	    }
	}
	set recording 0
	return
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "macro::execute" --
 # 
 # Execute the current keyboard macro.  Use [macro::current] to obtain the 
 # script that will be evaluated by this procedure.
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::execute {} {
    variable Current
    # This will create a proc called [macroName].
    eval $Current
    # Evaluate it.
    return [macroName]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "macro::current" --
 # 
 # With no arguments, returns the most recently recorded keyboard macro as a
 # procedure named "macroName", as in
 # 
 #     proc macroName {} {insertText "j"}
 # 
 # Otherwise, a single "macro" argument must either be the null string (to
 # completely reset the macro) or begin with
 # 
 #     proc macroName
 # 
 # in order for the script to be recorded; an error will be thrown otherwise.
 # (This is the format returned by AlphaX's original [keyboardMacro] command,
 # redefined above as [macro::__current].)
 # 
 # --------------------------------------------------------------------------
 ##

proc macro::current {args} {
    variable Current
    switch -- [llength $args] {
        "0" {
	    return $Current
        }
        "1" {
	    set macro [lindex $args 0]
	    if {($macro eq "") || [regexp {^\s*proc\s+macroName\s+} $macro]} {
		set Current $macro
		return $Current
	    } else {
		error "The procedure must begin with \"proc macroName ...\""
	    }
        }
        default {
            error "Usage: macro::current ?new macro script?"
        }
    }
}

# ===========================================================================
# 
# ◊◊◊◊ -------- ◊◊◊◊ #
# 
# ◊◊◊◊ Time and timing ◊◊◊◊ #
# 
# Adapted from Vince Darley's AlphaTk (alpha_commands.tcl):
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "now" --
 # 
 # Returns the current time as Macintosh seconds.  This is the number of
 # seconds that have elapsed since Midnight Jan 1, 1904.
 # 
 # --------------------------------------------------------------------------
 ##

if {![llength [info commands now]]} {
    alpha::stderr "Defining the core command \[now\]"
    proc now {} {
	return [clock seconds]
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "mtime" -- <time> [long|short|abbrev]
 # 
 # Returns a date and time string using the Macintosh International
 # Utilities.  The long/short/abbrev specification corresponds to the date.
 # These are the following formats:
 #  
 #    short     3/16/92 9:20:46 PM
 #    abbrev    Mon, Mar 16, 1992 9:20:49 PM
 #    long      Monday, March 16, 1992 9:20:43 PM
 # 
 # The returned value actually is in the form of a list.  To get text as
 # above, run the result through 'join', as in "join [mtime [now] short]".
 # 
 # --------------------------------------------------------------------------
 ##

if {![llength [info commands mtime]]} {
    alpha::stderr "Defining the core command \[mtime\]"
    proc mtime {when {how "short"} {gmt 0}} {
	switch -- $how {
	    "long" {
		set formatArgs [list "%A, %B %d %Y" "%I:%M:%S %p"]
	    }
	    "short" {
		set formatArgs [list "%m/%d/%Y" "%I:%M:%S %p"]
	    }
	    "abbrev" {
		set formatArgs [list "%a, %b %d %Y" "%I:%M:%S %p"]
	    }
	    default {
		return -code error "Illegal argument \"$how\" to mtime"
	    }
	}
	return [clock format $when -format $formatArgs -gmt $gmt]
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "ticks" --
 # 
 # Returns the current TickCount.  Ticks are 60ths of a seconds.  TickCount
 # is the number of ticks since the computer was started.  The command:
 #  
 #     puts stdout [expr "[ticks] / 60"]
 #  
 # will print the number of seconds since the computer was booted.
 # 
 # --------------------------------------------------------------------------
 ##

if {![llength [info commands ticks]]} {
    alpha::stderr "Defining the core command \[ticks\]"
    proc ticks {} {
	return [expr {([clock clicks -milliseconds]*60)/1000}]
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "cvttime" --
 # 
 # convert input time to/from mac epoch (+/- 0x7c25b080).
 # 
 # --------------------------------------------------------------------------
 ##

if {![llength [info commands cvttime]]} {
    alpha::stderr "Defining the core command \[cvttime\]"
    proc cvttime {how when} {
	switch -- $how {
	    "-mtu" {
		return [expr $when-0x7c25b080]
	    }
	    "-utm" {
		return [expr $when+0x7c25b080]
	    }
	}
    }
}

# ===========================================================================
# 
# ◊◊◊◊ -------- ◊◊◊◊ #
# 
# ◊◊◊◊ Printing ◊◊◊◊ #
# 

if {($alpha::macos == 1)} {
    # Alpha 8 (MacClassic)
    alpha::stderr "Redefining the core command \[print\]"
    rename print __print
    ;proc print {args} {
	if {[llength $args]} {
	    if {[catch [list __print [lindex $args 0]]]} {
		win::OpenQuietly [lindex $args 0]
		bringToFront [lindex $args 0]
		if {[catch {uplevel 1 __print}]} {
		    error "cancel"
		}
	    }
	} else {
	    if {[catch {uplevel 1 __print}]} {
		error "cancel"
	    }
	}
	return
    }
}

if {($tcl_platform(platform) eq "macintosh") || ($tcl_platform(platform) eq "windows")} {
    # These are used on MacClassic and on Windows.
    alpha::stderr "Defining the core command \[printLeftHeader\]"
    ;proc printLeftHeader {pg {f ""}} {
	global printHeader printHeaderTime printHeaderFullPath
	
	if {!$printHeader} {
	    return
	}
	if {($f eq "")} {
	    set f [win::Current]
	}
	if {$printHeaderFullPath} {
	    set text $f
	} else {
	    set text [file tail $f]
	}
	
	if {$printHeaderTime} {
	    append text "      [join [mtime [now] short]]"
	}
	return $text
    }
    
    alpha::stderr "Defining the core command \[printRightHeader\]"
    ;proc printRightHeader {pg {f ""}} {
	global printHeader
	if {!$printHeader} {
	    return
	}
	return "Page $pg"
    }
}

# ===========================================================================
# 
# ◊◊◊◊ -------- ◊◊◊◊ #
# 
# ◊◊◊◊ Cut Copy Paste ◊◊◊◊ #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "alpha::pasteRegion" --
 # 
 # When Alpha 8/X add to [paste] the ability to return a list of from-to
 # positions modified, the command should simultaneously be renamed to
 # [alpha::pasteRegion].
 # 
 # --------------------------------------------------------------------------
 ##

if {![llength [info commands ::alpha::pasteRegion]]} {
    alpha::stderr "Renaming the core command \[paste\]"
    rename ::paste ::alpha::_pasteRegion
    proc alpha::pasteRegion {args} {
	win::parseArgs w
	::alpha::_pasteRegion -w $w
	set to [getPos -w $w]
	set from [pos::math -w $w $to - [string length [getScrap]]]
	return [list $from $to]
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "cut" --
 # "copy" --
 # "paste" --
 # 
 # All of these used to be core commands, but are now defined here so that we
 # can assure selections are present when required.
 # 
 # These are all "coreImplementations.tcl" candidates.
 # 
 # --------------------------------------------------------------------------
 ##

proc cut {args} {
    win::parseArgs w
    if {![isSelection -w $w]} {
	error "Cancelled -- no selection to cut"
    } else {
	return [alpha::cutRegion -w $w]
    }
}

proc copy {args} {
    win::parseArgs w
    if {![isSelection -w $w]} {
	error "Cancelled -- no selection to copy"
    } else {
	return [alpha::copyRegion -w $w]
    }
}

proc paste {args} {
    win::parseArgs w
    return [alpha::pasteRegion -w $w]
}

# ===========================================================================
# 
# ◊◊◊◊ -------- ◊◊◊◊ #
# 
# ◊◊◊◊ Unicode fixes ◊◊◊◊ #
# 
# Provides better [glob] and [edit] commands which overcome deficiencies in
# the standard Tcl/AlphaX versions which have known unicode issues.
# 
# See bug# 1974 for more discussion about these issues.
# 
# <http://www.purl.org/net/alpha/bugzilla/show_bug.cgi?id=1974>
# 

namespace eval unicode {
    
    set grave       [format %c 768]
    set aigu        [format %c 769]
    set circumflex  [format %c 770]
    set tilde       [format %c 771]
    set trema       [format %c 776]
    set ring        [format %c 778]
    set cedille     [format %c 807]
    
    variable mapping [list \
      "a$grave"      à \
      "a$aigu"       á \
      "a$circumflex" â \
      "a$tilde"      ã \
      "a$trema"      ä \
      "a$ring"       å \
      "A$grave"      À \
      "A$aigu"       Á \
      "A$circumflex" Â \
      "A$tilde"      Ã \
      "A$trema"      Ä \
      "A$ring"       Å \
      \
      "c$cedille"    ç \
      "C$cedille"    Ç \
      \
      "e$grave"      è \
      "e$aigu"       é \
      "e$circumflex" ê \
      "e$trema"      ë \
      "E$grave"      È \
      "E$aigu"       É \
      "E$circumflex" Ê \
      "E$trema"      Ë \
      \
      "i$grave"      ì \
      "i$aigu"       í \
      "i$circumflex" î \
      "i$trema"      ï \
      "i$grave"      Ì \
      "i$aigu"       Í \
      "i$circumflex" Î \
      "i$trema"      Ï \
      \
      "n$tilde"      ñ \
      "N$tilde"      Ñ \
      \
      "o$grave"      ò \
      "o$aigu"       ó \
      "o$circumflex" ô \
      "o$tilde"      õ \
      "o$trema"      ö \
      "O$grave"      Ò \
      "O$aigu"       Ó \
      "O$circumflex" Ô \
      "O$tilde"      Õ \
      "O$trema"      Ö \
      \
      "u$grave"      ù \
      "u$aigu"       ú \
      "u$circumflex" û \
      "u$trema"      ü \
      "U$grave"      Ù \
      "U$aigu"       Ú \
      "U$circumflex" Û \
      "U$trema"      Ü \
      \
      "y$trema"      ÿ \
      "y$trema"      Ÿ \
      ]
    unset grave aigu circumflex tilde trema ring cedille
}

## 
 # --------------------------------------------------------------------------
 # 
 # "unicode::compose" --
 # 
 # Compose the unicode string to something Alpha can work with.
 # 
 # --------------------------------------------------------------------------
 ##

proc unicode::compose { str } {
    variable mapping
    return [string map $mapping $str]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "unicode::decompose" --
 # 
 # Decompose a string so that [glob] (e.g.) can properly deal with it.
 # 
 # --------------------------------------------------------------------------
 ##

proc unicode::decompose { str } {
    variable mapping
    foreach {item1 item2} $mapping {
	lappend newMapping $item2 $item1
    }
    return [string map $newMapping $str]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "glob" --
 # 
 # We first parse out all of the arguments to determine which ones are the
 # patterns.  Then we decompose them so that a [glob] call with a wildcard
 # won't throw an error.  Then we call the standard Tcl [glob], and
 # translate the results before returning them.
 # 
 # If Tcl ever fixes this, we can put a proper version check in place here so
 # that [glob] is only redefined when it is needed.
 # 
 # --------------------------------------------------------------------------
 ##

if {$alpha::macos} {
    if {![llength [info commands "::unicode::__glob"]]} {
	rename "::glob" "::unicode::__glob"
    }
    alpha::stderr {Redefining [glob] for unicode issues.}
    ;proc glob {args} {
	set newArgs [list]
	set valOpts [list "-directory" "-path" "-types"]
	set noVals  [list "-nocomplain" "-tails"]
	for {set i 0} {($i < [llength $args])} {incr i} {
	    set opt [lindex $args $i]
	    if {($opt eq "--")} {
		lappend newArgs $opt
		incr i
		break
	    } elseif {([lsearch -glob $noVals  "${opt}*"] > -1)} {
		lappend newArgs $opt
	    } elseif {([lsearch -glob $valOpts "${opt}*"] > -1)} {
		lappend newArgs $opt [lindex $args [incr i]]
	    } else {
		break
	    }
	}
	foreach pattern [lrange $args $i end] {
	    lappend newArgs [::unicode::decompose $pattern]
	}
	set results [uplevel \#0 [list "::unicode::__glob"] $newArgs]
	set newList [list]
	foreach path $results {
	    lappend newList [::unicode::compose $path]
	}
	return $newList
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "edit" --
 # 
 # We just need to make sure that [edit] is passed a composed name.
 # 
 # When this is fixed in the core we can add a version check.
 # 
 # --------------------------------------------------------------------------
 ##

if {($alpha::platform eq "alpha")} {
    if {![llength [info commands "::unicode::__edit"]]} {
	rename "::edit" "::unicode::__edit"
    }
    alpha::stderr {Redefining [edit] for unicode issues.}
    ;proc edit {args} {
	set oldFile [lindex $args end]
	set newFile [unicode::compose $oldFile]
	if {[file exists $oldFile] && [file exists $newFile]} {
	    set args [lreplace $args end end $newFile]
	}
	return [uplevel \#0 [list "::unicode::__edit"] $args]
    }
}

# ===========================================================================
# 
# ◊◊◊◊ -------- ◊◊◊◊ #
# 
# ◊◊◊◊ TclX Commands ◊◊◊◊ #
# 
# If TclX is loaded (if the user has installed a batteries-included Tcl
# distribution) then we will have all of its commands available, but
# otherwise, we need to define a few of them here.  AlphaTcl doesn't require
# TclX, and according to bug# 1868 attempting to load it is problematic.
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "lcontain" --  var ?indexExpr? ?string?
 # 
 # Determine if the element is a list element of list.  If the element is
 # contained in the list, 1 is returned, otherwise, 0 is returned.
 # 
 # --------------------------------------------------------------------------
 # 
 # This implementation can probably be made more efficient using 'lset'.
 # 
 # --------------------------------------------------------------------------
 ##

if {![llength [info commands lcontain]]} {
    alpha::stderr "Defining the TclX command \[lcontain\]"
    
    if {([info tclversion] < 8.5)} {
	proc lcontain {listval elt} {
	    return [expr {([lsearch -exact $listval $elt] == -1) ? 0 : 1}]
	}
    } else {
	proc lcontain {listval elt} {
	    return [expr {$elt in $listval}]
	}
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "lvarpop" --  var ?indexExpr? ?string?
 # 
 # The lvarpop command pops (deletes) the element indexed by the expression
 # indexExpr from the list contained in the variable var.  If index is
 # omitted, then 0 is assumed.  If string, is specified, then the deleted
 # element is replaced by string.  The replaced or deleted element is
 # returned.  Thus ``lvarpop argv 0'' returns the first element of argv,
 # setting argv to contain the remainder of the string.
 # 
 # If the expression indexExpr starts with the string end, then end is
 # replaced with the index of the last element in the list.  If the
 # expression starts with len, then len is replaced with the length of the
 # list.
 # 
 # --------------------------------------------------------------------------
 # 
 # This implementation can probably be made more efficient using 'lset'.
 # 
 # --------------------------------------------------------------------------
 ##

if {![llength [info commands lvarpop]]} {
    alpha::stderr "Defining the TclX command \[lvarpop\]"

    proc lvarpop { listname {index ""} {newentry ""} } {
# 	set listname [uplevel 1 [list namespace which -variable $listname]]
	upvar 1 $listname L
	if { ![string length $index] } {
	    set index 0
	} elseif { $index == "len" } {
	    set index [llength $L]
	} elseif { $index == "end" } {
	    set index [expr [llength $L] - 1]
	}
	set res [lindex $L $index]
	if { [string length $newentry] } {
	    set L [lreplace $L $index $index $newentry]
	} else {
	    set L [lreplace $L $index $index]
	}
	return $res
    }   
}



# ===========================================================================
# 
# ◊◊◊◊ -------- ◊◊◊◊ #
# 
# ◊◊◊◊ Tcl 8.5 Forward Compatibility ◊◊◊◊ #

## 
 # --------------------------------------------------------------------------
 # 
 # "dict" -- option arg ?arg ...?
 # 
 # Manipulate dictionaries.  Performs one of several operations on dictionary
 # values or variables containing dictionary values.
 # 
 # See <http://www.tcl.tk/man/tcl8.5/TclCmd/dict.htm> for more information.
 # 
 # --------------------------------------------------------------------------
 # 
 # This is a "poor man's [dict]" -- a pure tcl [dict] emulation.  Very slow,
 # but complete.  Implementation is based on lists, [array set/get] and
 # recursion.  Similar to Tcl 8.5's [dict] command, abbreviations will work.
 # 
 # Not all error checks are implemented!  e.g. 
 # 
 #     dict create odd arguments here
 # 
 # will work.  
 # 
 # --------------------------------------------------------------------------
 ##

if {![llength [info commands dict]]} {
    alpha::stderr "Defining the core command \[dict\]"

    proc dict {cmd args} {
	set validCmds [list "append" "create" "exists" "filter" "for" \
	  "get" "incr" "info" "keys" "lappend" "merge" "remove" \
	  "replace" "set" "size" "unset" "update" "values" "with"]
	if {([set idx [lsearch -glob $validCmds "${cmd}*"]] == -1)} {
	    error "bad option \"$cmd\": must be [join $validArgs {, }]"
	}
	set cmd [lindex $validCmds $idx]
	uplevel 1 [linsert $args 0 _dict_$cmd]
    }
    proc _dict_append {dvar key {args}} {
	upvar 1 $dvar dv
	if {![info exists dv]} {
	    set dv [list]
	}
	array set dvx $dv
	eval [linsert $args 0 append dvx($key) ]
	set dv [array get dvx]
    }
    proc _dict_create {args} {
	if {([llength $args] % 2)} {
	    return -code error \
	      {wrong # args: should be "dict create ?key value ...?"}
	}
	return $args
    }
    proc _dict_exists {dv key args} {
	array set dvx $dv
	set r [info exists dvx($key)]
	if {!$r} {
	    return 0
	}
	if {[llength $args]} {
	    return [eval [linsert $args 0 _dict_exists $dvx($key) ]]
	} else {
	    return 1
	}
    }
    proc _dict_filter {dv ftype args} {
	set r [list]
	foreach {globpattern} $args {break}
	foreach {varlist script} $args {break}
	
	switch $ftype {
	    key {
		foreach {key value} $dv {
		    if {[string match $globpattern $key]} {
			lappend r $key $value
		    }
		}
	    }
	    value {
		foreach {key value} $dv {
		    if {[string match $globpattern $value]} {
			lappend r $key $value
		    }
		}
	    }
	    script {
		foreach {Pkey Pval} $varlist {break}
		upvar 1 $Pkey key $Pval value
		foreach {key value} $dv {
		    if {[uplevel 1 $script]} {
			lappend r $key $value
		    }
		}
	    }
	    default {
		error "Wrong filter type"
	    }
	}
	return $r
    }
    proc _dict_for {kv dict body} {
	uplevel 1 [list foreach $kv $dict $body]
    }
    proc _dict_get {dv args} {
	if {![llength $args]} {
	    return $dv
	} else {
	    array set dvx $dv
	    set key [lindex $args 0]
	    set dv $dvx($key)
	    set args [lrange $args 1 end]
	    return [eval [linsert $args 0 _dict_get $dv]]
	}
    }
    proc _dict_incr {dvar key {incr 1}} {
	upvar 1 $dvar dv
	if {![info exists dv]} {
	    set dv [list]
	}
	array set dvx $dv
	if {![info exists dvx($key)]} {
	    set dvx($key) 0
	}
	incr dvx($key) $incr
	set dv [array get dvx]
    }
    proc _dict_info {dv} {
	return "Dictionary is represented as plain list"
    }
    proc _dict_keys {dv {pat *}} {
	array set dvx $dv
	return [array names dvx $pat]
    }
    proc _dict_lappend {dvar key args} {
	upvar 1 $dvar dv
	if {![info exists dv]} {
	    set dv [list]
	}
	array set dvx $dv
	eval [linsert $args 0 lappend dvx($key)]
	set dv [array get dvx]
    }
    proc _dict_merge {args} {
	foreach dv $args {
	    array set dvx $dv
	}
	array get dvx
    }
    proc _dict_remove {dv args} {
	foreach k $args {
	    _dict_unset dv $k
	}
	return $dv
    }
    proc _dict_replace {dv args} {
	if {([llength $args] % 2)} {
	    return -code error \
	      {wrong # args: should be "dict replace ?key value ...?"}
	}
	foreach {k v} $args {
	    _dict_set dv $k $v
	}
	return $dv
    }
    proc _dict_set {dvar key value args } {
	upvar 1 $dvar dv
	if {![info exists dv]} {
	    set dv [list]
	}
	array set dvx $dv
	if {![llength $args]} {
	    set dvx($key) $value
	} else {
	    eval [linsert $args 0 _dict_set dvx($key) $value]
	}
	set dv [array get dvx]
    }
    proc _dict_size {dv} {
	return [expr {[llength $dv]/2}]
    }
    proc _dict_unset {dvar key args} {
	upvar 1 $dvar mydvar
	if {![info exists mydvar]} {
	    set mydvar [list]
	}
	array set dv $mydvar
	if {![llength $args]} {
	    if {[info exists dv($key)]} {
		unset dv($key)
	    }
	} else {
	    eval [linsert $args 0 _dict_unset dv($key) ]
	}
	set mydvar [array get dv]
	return {}
    }
    proc _dict_update {dvar args} {
	set name [string map {: {} ( {} ) {}} $dvar]
	upvar 1 $dvar dv
	upvar 1 _my_dict_array$name local
	
	array set local $dv
	foreach {k v} [lrange $args 0 end-1] {
	    if {[info exists local($k)]} {
		if {![uplevel 1 [list info exists $v]]} {
		    uplevel 1 [list upvar 0 _my_dict_array${name}($k) $v]
		} else {
		    uplevel 1 [list set $v $local($k)]
		}
	    }
	}
	set code [catch {uplevel 1 [lindex $args end]} res]
	
	foreach {k v} [lrange $args 0 end-1] {
	    if {[uplevel 1 [list info exists $v]]} {
		set local($k) [uplevel 1 [list set $v]]
	    } else {
		unset -nocomplain local($k)
	    }
	}
	set dv [array get local]
	unset local
	
	return -code $code $res
    }
    proc _dict_values {dv {gp *}} {
	set r [list]
	foreach {k v} $dv {
	    if {[string match $gp $v]} {
		lappend r $v
	    }
	}
	return $r
    }
    proc _dict_with {dvar script} {
	set name [string map {: {} ( {} ) {}} $dvar]
	upvar 1 $dvar dv
	upvar 1 _my_dict_array$name local
	
	array set local $dv
	foreach k [array names local] {
	    if {[info exists local($k)]} {
		if {![uplevel 1 [list info exists $k]]} {
		    uplevel 1 [list upvar 0 _my_dict_array${name}($k) $k]
		} else {
		    uplevel 1 [list set $k $local($k)]
		}
	    }
	}
	set code [catch {uplevel 1 $script} res]
	
	foreach k [array names local] {
	    if {[uplevel 1 [list info exists $k]]} {
		set local($k) [uplevel 1 [list set $k]]
	    } else {
		unset -nocomplain local($k)
	    }
	}
	set dv [array get local]
	unset local
	
	return -code $code $res
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "lassign" --  list varName ?varName ...?
 # 
 # Assign list elements to variables
 # 
 # This command treats the value list as a list and assigns successive
 # elements from that list to the variables given by the varName arguments in
 # order.  If there are more variable names than list elements, the remaining
 # variables are set to the empty string.  If there are more list elements
 # than variables, a list of unassigned elements is returned.
 # 
 # See <http://www.tcl.tk/man/tcl8.5/TclCmd/lassign.htm> for more information.
 # 
 # --------------------------------------------------------------------------
 ##

if {![llength [info commands lassign]]} {
    alpha::stderr "Defining the core command \[lassign\]"
    
    proc lassign {values args} {
	set vlen [llength $values]
	set alen [llength $args]
	# Make lists equal length
	for {set i $vlen} {$i < $alen} {incr i} {
	    lappend values {}
	}
	uplevel 1 [list foreach $args $values break]
	return [lrange $values $alen end]
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "lrepeat" --  number element1 ?element2 element3 ...?
 # 
 # Build a list by repeating elements.
 # 
 # The lrepeat command creates a list of size number * number of elements by
 # repeating number times the sequence of elements element1 element2 ....
 # number must be a positive integer, elementn can be any Tcl value.  Note
 # that lrepeat 1 arg ...  is identical to list arg ..., though the arg is
 # required with lrepeat.
 # 
 # See <http://www.tcl.tk/man/tcl8.5/TclCmd/lrepeat.htm> for more information.
 # 
 # --------------------------------------------------------------------------
 ##

if {![llength [info commands lrepeat]]} {
    alpha::stderr "Defining the core command \[lrepeat\]"
    
    proc lrepeat {count value args} {
	if { ![string is integer -strict $count] } {
	    error "expected integer but got \"$count\""
	} elseif { $count < 1 } {
	    error "must have a count of at least 1"
	}
	set values [linsert $args 0 $value]
	set result {}
	for {set i 0} {$i < $count} {incr i} {
	    eval [list lappend result] $values
	}
	return $result
    }
}

# ==========================================================================
# 
# .