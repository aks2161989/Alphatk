## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # BibTeX mode - an extension package for Alpha
 # 
 # FILE: "bibtexSmart.tcl"
 #                                   created: 08/17/1994 {09:12:06 am} 
 #                               last update: 02/06/2003 {01:25:48 PM}
 #                               
 # Description: 
 # 
 # Support for smart quotes, dots, etc.  Piggy-backs on "latexSmart.tcl"
 # code.
 # 
 # See the "bibtexMode.tcl" file for license info, credits, etc.
 # 
 # ==========================================================================
 ## 

proc bibtexSmart.tcl {} {}

# load main bib file!
bibtexMode.tcl

# We'd like to load some "latexSmart.tcl" code if possible, esp the
# "TeX::smartEscapes" variable.
catch {latexSmart.tcl}

namespace eval TeX {}

if {![info exists TeX::smartEscapes]} {

    lappend TeX::smartEscape \
      [list 0 {''$}             {"}] \
      [list 0 {``$}             {"}] \
      [list 0 {`$}              {'}] \
      [list 0 {\\\\ldots$}      {...}] \
      [list 2 {_\{\}\u2022\$}   {_}] \
      [list 2 {\\^\{\}\u2022\$} {^}] \
      [list 1 {label\{eq:\}$}   {nonumber}]
} 

# ===========================================================================
#
# ×××× Smart Quotes, Smart Dots ×××× #
# 
# borrowed from "latexSmart.tcl"
# 

namespace eval Bib {}

#--------------------------------------------------------------------------
# Smart quotes:
#--------------------------------------------------------------------------

proc Bib::smartDQuote {} {

    global BibmodeVars
    
    if {!$BibmodeVars(smartQuotes) || [literalChar]} {typeText {"} ; return}
    if {[leftQ]} {typeText {``}} else {typeText {''}}
}

proc Bib::smartQuote {} {
    
    global BibmodeVars
    
    if {!$BibmodeVars(smartQuotes) || [literalChar]} {typeText {'} ; return}
    if {[leftQ]} {typeText {`}} else {typeText {'}}
}

proc Bib::leftQ {} {

    if {[pos::compare [getPos] == [minPos]]} {return 1}
    return [regexp "\[\[ \t\r\n\(\{<\]" [lookAt [pos::math [getPos] - 1]]]
}

#--------------------------------------------------------------------------
# Smart dots:
#--------------------------------------------------------------------------

proc Bib::smartDots {} {
    global BibmodeVars
    if {[isSelection]} { deleteSelection }
    if { $BibmodeVars(smartDots) } {
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
# Escapes and exceptions:
#--------------------------------------------------------------------------

# We always use the "TeX::smartEscape" variable for this.

proc Bib::escapeSmartStuff {} {

    global BibmodeVars TeX::smartEscape

    if {![isSelection]} {
	set pos0 [getPos]
	set text [getText [lineStart $pos0] $pos0]
	foreach i [set TeX::smartEscape] {
	    set off  [lindex $i 0]
	    set look [lindex $i 1]
	    if {!$BibmodeVars(smartQuotes) \
	      && [regexp {['"`]} [string index $look 0]]} {
		continue
	    }
	    if {$off == 0} {
		if {[regexp -- $look $text got]} {
		    set pos1 [pos::math $pos0 - [string length $got]]
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
# ===========================================================================
# 
# .