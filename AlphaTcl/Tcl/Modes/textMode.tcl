#################################################################################
# Text mode.
# 
# You should not remove this file.  Alpha may not function very well
# without it.
#================================================================================

alpha::mode Text 0.1.6 {
    # This script will be evaluated just once.

    newPref v leftFillColumn {0} Text
    newPref v suffixString {} Text
    newPref v prefixString {> } Text
    newPref v fillColumn {75} Text
    newPref var lineWrap {1} Text
    newPref v wordBreak {\w+} Text
    #newPref v wrapBreak {[\w_]+} Text
    #newPref v wrapBreakPreface {([^\w_])} Text
    
    newPref f autoMark 0 Text
    # To automatically indent the new line produced by pressing <return>, turn
    # this item on.  The indentation amount is determined by the context||To
    # have the <return> key produce a new line without indentation, turn this
    # item off
    newPref flag indentOnReturn 0 Text
    newPref v commentsContinuation 1 Text "" \
      [list "only at line start" "spaces allowed" "anywhere"] index
    ;proc Text::DblClick {args} {
	eval Tcl::DblClick $args
    }
    set Text::startPara {^[ \t]*(>|$)}
    set Text::endPara {^[ \t]*(>|$)}
    set Text::commentCharacters(General) [list ">"]
    set Text::commentCharacters(Paragraph) [list "!! " " !!" " ! "]
    set Text::commentCharacters(Box) [list "!" 1 "!" 1 "!" 3]

    ;proc Text::MarkFile {args} {
	win::parseArgs w {markDividers 1}
	status::msg "Marking \"[win::Tail $w]\" É"
	set pos [minPos -w $w]
	if {$markDividers} {
	    set pat {^((\t  \t)|([\t ]*=+[\t ]*$))}
	} else {
	    set pat {^((\t  \t))}
	}
	set count 0
	while {![catch {search -w $w -f 1 -r 1 -s $pat $pos} match]} {
	    set pos0  [lindex $match 0]
	    set pos1  [lindex $match 1]
	    set pos   [pos::nextLineStart -w $w $pos1]
	    if {$markDividers && \
	      [regexp {^[\t ]*=+$} [string trim [getText -w $w $pos0 $pos]]]} {
		set label "-"
	    } elseif {![string length [string trim [getText -w $w $pos1 $pos]]]} {
		continue
	    } else {
		regsub -all "\t" [string trimright [getText -w $w $pos1 $pos]] \
		  " " label
	    }
	    set ok 1
	    while {[lcontains labels $label]} {
		append label " "
		if {[string length $label] > 31} {
		    # Probably a problem with the file containing
		    # things like lots of lines with '===='
		    # We remove all marks and start again, this
		    # time we don't mark dividers.
		    if {[string trim $label] == "-"} {
			removeAllMarks
			return [Text::MarkFile -w $w 0]
		    }
		    set ok 0
		    break
		}
	    }
	    if {$ok} {
		lappend labels $label
		set pos2 [pos::lineStart -w $w \
		  [pos::math -w $w [pos::lineStart -w $w $pos1] - 1]]
		setNamedMark -w $w $label $pos2 $pos0 $pos0
		incr count
	    }
	}
	set msg "The window \"[win::Tail $w]\" contains $count mark"
	append msg [expr {($count == 1) ? "." : "s."}]
	status::msg $msg
	return
    }
} {default} {} {
} description {
    Provides a default text editing mode for Alpha
} help {
    If Alpha does not recognize a specific mode when it opens a file,
    the default mode is "Text" mode.  This help window is in Text mode
    -- one of the far right rectangular boxes in the status bar should
    currently read "Text".  This box is actually a pop-up menu, allowing
    you to change the mode of the current window.

    For more information regarding basic editing functions in Alpha, see
    the "Alpha Manual" or the shorter "Quick Start" help files.
}


