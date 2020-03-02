## -*-Tcl-*-
 # ###################################################################
 #  AlphaTcl - core Tcl engine
 #  
 #  FILE: "markStack.tcl"
 #                                    created: 04/10/2001 {11:58:44 AM} 
 #                                last update: 02/05/2004 {05:41:34 PM} 
 #  Author: Vince Darley
 #  E-mail: vince@santafe.edu
 #          317 Paseo de Peralta, Santa Fe
 #     www: http://www.santafe.edu/~vince/
 #  
 # ###################################################################
 ##

# ================================================================================
# Simple mark stack implementation
# ================================================================================

# For mark stack.
set markName 0
set markStack [list]

# Since we know the mark stack is empty until this file is sourced,
# we need only register this hook when the file is sourced as well.
hook::register closeHook removeObsoleteMarks

proc removeObsoleteMarks {fileName} {
    global markStack
    if {[llength $markStack]} {
	set markStack [lremove -glob $markStack [list $fileName*]]
    }
}

proc placeBookmark {{msg 1}} {
    global markStack
    global markName
    
    set name mark$markName
    incr markName
    createTMark $name [getPos]
    set winName [win::Current]
    set markStack [linsert $markStack 0 [list $winName $name [getPos]]]
    if {$msg} {
	status::msg "Placed bookmark \#[llength $markStack]"
    }
}

proc returnToBookmark {{msg 1}} {
    global markStack
    if {[llength $markStack] == "0"} {
	status::msg "No bookmarks have been placed!"
	return
    }
    set mark [lindex $markStack 0]
    set markStack [lreplace $markStack 0 0]
    if {[lsearch -exact [winNames -f] [lindex $mark 0]] == -1} {
	# Window has since been closed
	win::OpenQuietly [win::StripCount [lindex $mark 0]]
	goto [lindex $mark 2]
    } else {
	# Window is still open, but [gotoTMark] only positions the cursor
	# so we need to explicitly bring it to the front.
	bringToFront [lindex $mark 0]
	if {[catch {gotoTMark [lindex $mark 1]}]} {
	    returnToBookmark
	    return
	}
    }
    if {$msg} {
	status::msg "Returned to bookmark \#[expr {[llength $markStack] + 1}]"
    }
}


