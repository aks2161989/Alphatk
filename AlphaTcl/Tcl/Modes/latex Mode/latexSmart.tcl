## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # LaTeX mode - an extension package for Alpha
 #
 # FILE: "latexSmart.tcl"
 #                                          created: 11/10/1992 {10:42:08 AM}
 #                                      last update: 10/14/2004 {11:59:38 AM}
 # Description:
 #
 # Support for Smart Quotes/Dots.  Any package can add to the 'smart escapes'
 # list by first calling 'latexSmart.tcl' and then doing 'lappend' to the
 # "TeX::smartEscape" variable.
 #
 # See the "latex.tcl" file for license info, credits, etc.
 # ==========================================================================
 ##

proc latexSmart.tcl {} {}

namespace eval TeX {}

#--------------------------------------------------------------------------
# Smart quotes:
#--------------------------------------------------------------------------

# In sequence, english, german, french, reverse french
set TeX::smartQuoteStyles [list \
  [list `` '' ` '] [list \"` \"' {\glq } {\grq{}}] \
  [list << >> {\flq } {\frq{}}] [list >> << {\frq } {\flq{}}]]


proc TeX::smartQuotesChanged {args} {
    set style [TeX::smartQuoteStyle]
    set from [list \" \" ' ']
    for {set i 0} {$i < 4} {incr i} {
	TeX::modifySmartEscapes \
	  [list 0 "[quote::Regfind [lindex $style $i]]\$" [lindex $from $i]] 1
    }
}

proc TeX::smartQuoteStyle {} {
    global TeXmodeVars TeX::smartQuoteStyles
    lindex [set TeX::smartQuoteStyles] $TeXmodeVars(smartQuoteStyle)
}

proc TeX::smartDQuote {} {
    global TeXmodeVars
    if {!$TeXmodeVars(smartQuotes) || [literalChar]} {typeText \"; return}
    set style [TeX::smartQuoteStyle]
    if {[TeX::leftQ]} {
	typeText [lindex $style 0]
    } else {
	typeText [lindex $style 1]
    }
}

proc TeX::smartQuote {} {
    global TeXmodeVars
    if {!$TeXmodeVars(smartQuotes) || [literalChar]  } {typeText {'}; return}
    set style [TeX::smartQuoteStyle]
    if {[TeX::leftQ]} {
	typeText [lindex $style 2]
    } else {
	typeText [lindex $style 3]
    }
}

proc TeX::leftQ {} {
    if {[pos::compare [getPos] == [minPos]]} {return 1};
    return [regexp "\[\[ \t\r\n\(\{<\]" [lookAt [pos::math [getPos] - 1]]]
}

#--------------------------------------------------------------------------
# Smart dots:
#--------------------------------------------------------------------------

proc TeX::smartDots {} {
    global TeXmodeVars
    if {[isSelection]} {deleteSelection}
    if { $TeXmodeVars(smartDots) && \
      [pos::compare [getPos] > [pos::math [minPos] + 1]] } {
	if {[lookAt [pos::math [getPos] - 1]] == "."} {
	    if {[lookAt [set begPos [pos::math [getPos] - 2]]] == "."} {
		if {![text::isEscaped $begPos]} {
		    replaceText $begPos [getPos] "\\ldots"
		    return
		}
	    }
	}
    }
    insertText "."
}

#--------------------------------------------------------------------------
# Smart subscripts and superscripts:
#--------------------------------------------------------------------------

proc TeX::smartSubscripts {} {
    TeX::smartScripts {_}
}

proc TeX::smartSuperscripts {} {
    TeX::smartScripts {^}
}

proc TeX::smartScripts {char} {
    if {[isSelection]} {deleteSelection}
    if {[literalChar]} {
	insertText $char
	return
    }
    # Filenames contain literal underscores:
    set pat {\\(usepackage|input|include(only)?|documentclass|bibliography(style)?|LoadClass|RequirePackage|begin\{filecontents\})(\[[^][]*\])?\{}
    if {[findPatJustBefore "$pat" "${pat}\[.:a-zA-Z0-9/^_-\]*\$"] != ""} {
	insertText $char
	return
    }
    if {$char == {_}} {
	TeX::macroMenuProc {Formulas} subscript
    } else {
	TeX::macroMenuProc {Formulas} superscript
    }
}

#--------------------------------------------------------------------------
# Escapes and exceptions:
#--------------------------------------------------------------------------

proc TeX::modifySmartEscapes {escape add} {
    global TeX::smartEscape
    set idx [lsearch -exact [set TeX::smartEscape] $escape]
    if {$add} {
	if {$idx == -1} {
	    lappend TeX::smartEscape $escape
	}
    } else {
	if {$idx != -1} {
	    set TeX::smartEscape [lreplace [set TeX::smartEscape] $idx $idx]
	}
    }
}

proc TeX::escapeSmartStuff {} {

    global TeXmodeVars TeX::smartEscape

    if {![isSelection]} {
	set pos0 [getPos]
	set text [getText [lineStart $pos0] $pos0]
	foreach i [set TeX::smartEscape] {
	    set off  [lindex $i 0]
	    set look [lindex $i 1]
	    if {!$TeXmodeVars(smartQuotes) \
	      && [regexp "\['\"`\]" [string index $look 0]]} {
		continue
	    }
	    if {$off == 0} {
		if {[regexp -- $look $text got]} {
		    set pos1 [pos::math $pos0 - [string length $got]]
		    set old [getText $pos1 $pos0]
		    if {$old == [lindex $i 2]} {
			# The escape is the same as what is there.
			# This means we registered a bad escape,
			# but this can easily happen with multi-lingual
			# features, so we simply allow the delete.
			backSpace
			return
		    }
		    replaceText $pos1 $pos0 [lindex $i 2]
		    return
		}
	    } else {
		if {[pos::compare [set end [pos::math $pos0 + $off]] <= [maxPos]]} {
		    if {[regexp -- $look [getText [lineStart $pos0] $end] got]} {
			set pos0 $end
			set pos1 [pos::math $pos0 - [string length $got]]
			replaceText $pos1 $pos0 [lindex $i 2]
			return
		    }
		}
	    }
	}
    }
    backSpace
}

# Even with encodings on Alphatk, the above version seems to have
# some trouble.
lappend TeX::smartEscape \
  [list 0 \\\\ldots$    {...}] \
  [list 2 _\{\}\u2022\$   {_}] \
  [list 2 \\^\{\}\u2022\$ {^}] \
  [list 1 label\{\}\$  {nonumber}]

TeX::smartQuotesChanged

# ==========================================================================
#
# .