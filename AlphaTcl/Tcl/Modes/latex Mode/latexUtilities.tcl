## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # LaTeX mode - an extension package for Alpha
 #
 # FILE: "latexUtilities.tcl"
 #                                          created: 11/10/1992 {10:42:08 AM}
 #                                      last update: 03/21/2006 {03:11:47 PM}
 # Description:
 #
 # Support for Miscellaneous items in the "LaTeX Utilities" submenu.
 #
 # See the "latex.tcl" file for license info, credits, etc.
 # ==========================================================================
 ##

# Make sure that the main TeX mode file has been loaded.
latex.tcl

proc latexUtilities.tcl {} {}

namespace eval TeX {}

# Delete all unnecessary comments from the current document:

proc TeX::deleteComments {} {

    if {[pos::compare [getPos] == [selEnd]]} {
	set start [minPos]
	set end [maxPos]
    } else {
	# We must use full lines (otherwise we would have to handle
	# beginning and end of string specially in the patterns below),
	# so extend the selection
	set start [pos::lineStart [getPos]]
	set end [pos::lineEnd [selEnd]]
	selectText $start $end
    }

    set text [getText $start $end]
    set tcount \
      [regsub -all "(^|\r|\n)\[ \t\]*%\[^\r\n\]*(\r|\n)" $text {\1} text]
    incr tcount \
      [regsub -all "\[ \t\]+%\[^\r\n\]*" $text {} text]
    incr tcount \
      [regsub -all "(\[^\\\\\](\\\\\\\\)*)%\[^\r\n\]*" $text {\1} text]
    
    replaceText $start $end $text
    
    status::msg "$tcount comments deleted."
}

# Converts all straight quotes to their TeX equivalents.

proc TeX::convertQuotes {} {

    status::msg "working…"
    watchCursor
    set msg "selection"
    if {[pos::compare [set posBeg [getPos]] == [set posEnd [selEnd]]]} {
	set msg "document"
	set posBeg [minPos]
	set posEnd [maxPos]
    }
    set text [getText $posBeg $posEnd]
    # Convert all left double quotes:
    set convert [regsub -all "\(\^\|\[\ \r\t\(\[\{\]\)\"" $text {\1``} text]
    # Convert all right double quotes:
    incr convert [regsub -all "\(\[\^\\\\\]\)\"" $text {\1''} text]
    # Convert all left single quotes:
    incr convert [regsub -all "\(\^\|\[\ \r\t\(\[\{\]\)\'" $text {\1`} text]
    if {$convert} {
	replaceText $posBeg $posEnd $text
	status::msg "$convert quotes in $msg converted"
    } else {
	status::msg "no quotes found in $msg"
    }
}

# Convert all dollar signs to their LaTeX equivalents:

proc TeX::convertDollarSigns {} {

    if {[isSelection]} {
	set msg "selection"
    } else {
	set msg "document"
    }
    set subs2 [TeX::convertDoubleDollarSigns]
    if {$subs2 == -1} {
	beep
	alertnote "unmatched double dollar signs in $msg"
    } else {
	set subs1 [TeX::convertSingleDollarSigns]
	if {$subs1 == -1} {
	    beep
	    alertnote "unmatched single dollar sign in $msg"
	} elseif {$subs1 == 0 && $subs2 == 0} {
	    status::msg "no dollar signs found in $msg"
	} else {
	    status::msg "$subs1 pairs of \$…\$ and $subs2 pairs of \$\$…\$\$ removed from $msg"
	}
    }
}

# Converts all $$...$$ pairs to \[...\] and returns the number of such
# pairs converted.  If the dollar signs are unbalanced, does nothing and
# returns -1.

proc TeX::convertDoubleDollarSigns {} {

    watchCursor
    set msg "selection"
    if {[pos::compare [set posBeg [getPos]] == [set posEnd [selEnd]]]} {
	set msg "document"
	set posBeg [minPos]
	set posEnd [maxPos]
    }
    set text [getText $posBeg $posEnd]
    set subs [regsub -all {(^|[^\\])\$\$([^$]*)\$\$} $text {\1\\[\2\\]} text]
    if {[TeX::containsDoubleDollarSigns $text]} {return -1}
    if {$subs} {
	replaceText $posBeg $posEnd $text
    }
    return [expr $subs]
}

# Returns true if the argument contains non-literal double dollar signs,
# and false otherwise.

proc TeX::containsDoubleDollarSigns {text} {
    return [regexp {(^|[^\\])\$\$} $text]
}

# Converts all $...$ pairs to \(...\), maintains the cursor position, and
# returns the number of such pairs converted.  If the dollar signs are
# unbalanced, does nothing and returns -1.

proc TeX::convertSingleDollarSigns {} {

    watchCursor
    set subs1 0; set subs2 0; set subs3 0
    set pos [getPos]; set pos2 $pos
    if {[pos::compare [set posBeg $pos] == [set posEnd [selEnd]]]} {
	set isSelection 0
	set posBeg [minPos]
	set posEnd [maxPos]
	set text1  [getText $posBeg $pos]
	set subs1  [regsub -all {(^|[^\\])\$([^$]*)\$} $text1 {\1\\(\2\\)} text1]
	# Is there a dollar sign left over?  If so, search backward for this
	# dollar sign and prepare to do a substitution on the text to the right
	# of this dollar sign.
	if {[TeX::containsSingleDollarSign $text1]} {
	    set searchString {[^\\]\$}
	    set searchResult [search -s -n -f 0 -m 0 -i 1 -r 1 $searchString [pos::math $pos -1]]
	    set pos2 [lindex $searchResult 0]
	    set text1 [string range $text1 0 [expr {[pos::diff [minPos] $pos2]+ (2 * $subs1)}]]
	    set pos [pos::math $pos + 2]
	}
	set text2 [getText $pos2 $posEnd]
	set subs2 [regsub -all {(^|[^\\])\$([^$]*)\$} $text2 {\1\\(\2\\)} text2]
	# Is there a dollar sign left over?  If so, it's unbalanced.
	if {[TeX::containsSingleDollarSign $text2]} {return -1}
	append text $text1 $text2
    } else {
	set isSelection 1
	set text [getText $posBeg $posEnd]
	set subs3 [regsub -all {(^|[^\\])\$([^$]*)\$} $text {\1\\(\2\\)} text]
	# Is there a dollar sign left over?  If so, it's unbalanced.
	if {[TeX::containsSingleDollarSign $text]} {return -1}
    }
    if {$subs1 || $subs2 || $subs3} {
	replaceText $posBeg $posEnd $text
	# If there is a selection, just put it back.  Otherwise, adjust the
	# cursor position based on the number of substitutions.
	if {$isSelection} {
	    set posEnd [getPos]
	    selectText $posBeg $posEnd
	} else {
	    goto [pos::math $pos + [expr {2 * $subs1}]]
	}
    }
    return [expr {$subs1 + $subs2 + $subs3}]
}

# Returns true if the argument contains a non-literal dollar sign, and
# false otherwise.

proc TeX::containsSingleDollarSign {text} {
    return [regexp -- {(^|[^\\])\$} $text]
}

# ==========================================================================
#
# .