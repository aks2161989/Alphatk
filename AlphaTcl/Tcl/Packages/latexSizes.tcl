## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "latexSizes.tcl"
 #                                          created: 11/16/1997 {07:32:04 pm}
 #                                      last update: 03/21/2006 {02:17:18 PM}
 # Description:
 # 
 # Given a LaTeX command surrounding the current cursor position, allows
 # the user to cycle through a list of related commands, substituting them
 # for the current one.  The original package only performed this function
 # for 'Text Sizes' and AMS math sizes, hence the name.  Perhaps a more
 # appropriate name now would be "latexCycle.tcl" ...
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 #    
 # Includes contributions from Craig Barton Upright.
 # 
 # ========================================================================
 #              Copyright (c) 1997-2006 Vince Darley
 # ========================================================================
 # 
 # Permission to use, copy, modify, and distribute this software and its
 # documentation for any purpose and without fee is hereby granted,
 # provided that the above copyright notice appear in all copies and that
 # both that the copyright notice and warranty disclaimer appear in
 # supporting documentation.
 # 
 # Vince Darley disclaims all warranties with regard to this software,
 # including all implied warranties of merchantability and fitness.  In no
 # event shall Vince Darley be liable for any special, indirect or
 # consequential damages or any damages whatsoever resulting from loss of
 # use, data or profits, whether in an action of contract, negligence or
 # other tortuous action, arising out of or in connection with the use or
 # performance of this software.
 # 
 # ========================================================================
 ##

# feature declaration
alpha::feature latexSizes 1.0 {"TeX"} {
    # Initialization script.
    prefs::renameOld TeXmodeVars(makeSmaller) TeXmodeVars(cycleLeft) 
    prefs::renameOld TeXmodeVars(makeLarger)  TeXmodeVars(cycleRight)
    if {[set tcl_platform(platform)] == "windows"} {
	# The Cycle Left/Right bindings allow you to change the current
	# closest LaTeX command to another related item.
	newPref binding cycleLeft  "<O<B/," TeX "" "TeX::cycleList -1"
	newPref binding cycleRight "<O<B/." TeX "" "TeX::cycleList  1"
    } else {
	newPref binding cycleLeft  "<U<I/," TeX "" "TeX::cycleList -1"
	newPref binding cycleRight "<U<I/." TeX "" "TeX::cycleList  1"
    }
} {
    # Activation script.
    set TeX::DoLaTeXCycle 1
} {
    # Deactivation script.
    set TeX::DoLaTeXCycle 0
} maintainer {
    {Vince Darley} <vince@santafe.edu> <http://www.santafe.edu/~vince/>
} uninstall {
    this-file
} preinit {
    # Includes items that are related to the current LaTeX command, allowing
    # you to replace the current command
    newPref flag relatedTeXCommandsMenu 1 contextualMenuTeX
    # Includes items that are related to the current LaTeX command, allowing
    # you to replace the current command
    newPref flag relatedTeXCommandsMenu 0 contextualMenuBib
    menu::buildProc relatedTeXCommands TeX::buildRelatedCM
} description {
    Cycle through lists of related LaTeX commands using shift-opt-<>
} help {
    This is a feature for TeX and Bib modes, and when it is turned on via the
    menu item "Config > TeX/Bib Mode Prefs > Features" two new key keyboard
    shortcuts allow you to substitute related LaTeX commands for the one
    surrounding the cursor position, cycling left and right through a list
    that is presented in the status bar window.
    
    Preferences: Mode-Features-TeX
    Preferences: Mode-Features-Bib

    E.g. 

        you can turn \SMALL into \Small into \small ...

    Or 

    	you can turn the AMS-LaTeX \bigl( into \Bigl( into ... \Biggl(
	
    This also works with many grouped items in the following submenus:
   
	Sections
	Text Styles
	Math Styles
	Greek
	Theorem
	Binary Operators
	Relations
	Arrows
	Dots
	Symbols
	Functions
	Large Operators
	Math Accents
	Grouping
	Spacing
	
    Usage:
    
    Press Shift-Option-, or Shift-Option-.  and we look for the word
    surrounding or touching the current cursor position.  This word must start
    with '\', and in '\epsilon (You can adjust the keyboard shortcuts for the
    preferences 'Cycle Left/Right' in the TeX or Bib Mode preferences dialog.)

    If the current position is within {}, as in
    
	\mathbb{This is an |example}

    then the subsequent operations take place on the \word preceding the
    bracketed section.  This is true even if the cursor and the \word are not
    on the same line, as in
    
	\textrm{
	    Sometimes we do things| like this.
	}
  
    If the \word found is of any of some grouped LaTeX2e commands, the list of
    options is presented in the status bar window.  If the list is related to
    size (the original purpose of this package) then the list is presented in
    the order of magnitude, otherwise related mark-up commands are presented
    alphabetically.  Pressing the key binding again will substitute the
    next/prev item in the list for the current \word.

    Repeated keypresses continue the process.  Moving the cursor will reset
    the procedure, so the next keypress will start all over again, first
    presenting the list of options appropriate to the new position.  You can
    open the "LaTeX Example.tex" example file and activate the feature to
    experiment.
    
    Click here <<latexSizes.tcl ; showVarValue TeX::LaTeXSizes>> to see the
    list of grouped keywords that are available for cycling.  If you have any
    other groups to contribute, please contact the package's maintainer or
    send an e-mail to one of the AlphaTcl mailing lists.
    
    In Alpha8 and higher, a contextual menu item for TeX and Bib modes named
    'Related TeX Commands' is also available which operates under the same set
    of principles.
}

proc latexSizes.tcl {} {}

namespace eval TeX {}

# It really doesn't matter what these array names are.
# Can easily add more, just follow the templates below.

array set TeX::LaTeXSizes {
    
    "math"         {
	[delete] big  Big  bigg  Bigg
    }
    "mathl"        {
	[delete] bigl Bigl biggl Biggl
    }
    "mathr"        {
	[delete] bigr Bigr biggr Biggr
    }

    "greek"        {
	alpha beta gamma delta epsilon zeta eta theta iota kappa lambda mu
	nu xi omicron pi rho sigma tau upsilon phi chi psi omega
    }
    "Greek"        {
	Gamma Delta Theta Lambda Xi Pi Sigma Upsilon Phi Psi Omega
    }

    "sections"     {
	part chapter section subsection subsubsection paragraph subparagraph
    }

    "textStyle1"   {
	textbf textit textmd textrm textsc textsf textsl texttt textup
    }
    "textStyle2"   {
	em emph underline
    }
    "textShape"    {
	itshape scshape slshape upshape
    }
    "textSeries"   {
	bfseries mdseries
    }
    "textFamily"   {
	rmfamily sffamily ttfamily
    }
    "textCommands" {
	textemdash textendash textexclamdown textquestiondown
	textquotedblleft textquotedblright textquoteleft textquoteright
    }
    "misc"         {
	LaTeX LaTeXe TeX
    }


    "mathStyle1"   {
	mathbb mathbf mathcal mathfrak mathit mathrm mathsf mathtt
    }
    "mathStyle2"   {
	displaystyle scriptstyle scriptscriptstyle textstyle
    }

    "theorem"      {
	claimno corollary definition lemma proposition remark theorem
    }
    "binary1"       {
	ast bullet cap cdot circ cup div mp pm setminus sqcap sqcup star
	times uplus vee wedge
    }
    "binary2"       {
	bigtriangledown bigtriangleup diamond lhd rhd triangleleft
	triangleright unlhd unrhd
    }
    "binary3"       {
	odot ominus oplus oslash otimes
    }
    "binary4"       {
	amalg bigcirc dagger ddagger wr
    }
    "relations1"    {
	dashv geq gg in leq ll ni prec preceq sqsubset sqsubseteq sqsupset
	sqsupseteq supset subset subseteq succ succeq supseteq vdash
    }
    "relations2"    {
	approx asymp cong doteq equiv neq propto sim simeq
    }
    "relations3"    {
	bowtie frown join mid models parallel perp smile
    }
    "arrows1"       {
	Leftarrow leftarrow Leftrightarrow leftrightarrow Longleftarrow
	longleftarrow Longleftrightarrow longleftrightarrow Longrightarrow
	longrightarrow Rightarrow rightarrow
    }
    "arrows2"       {
	Downarrow downarrow Uparrow uparrow Updownarrow updownarrow
    }
    "arrows3"       {
	leadsto longmapsto mapsto
    }
    "arrows4"       {
	hookleftarrow hookrightarrow leftharpoondown leftharpoonup
	rightharpoondown rightharpoonup rightleftharpoons
    }
    "arrows5"       {
	nearrow nwarrow searrow swarrow
    }
    "dots"          {
	bullet cdot cdots ddots ldots vdots
    }
    "symbols1"      {
	aleph ell hbar Im imath jmath mho Re wp
    }
    "symbols2"      {
	angle backslash bot emptyset exists forall infty nabla neg partial
	prime surd top
    }
    "symbols3"      {
	Box clubsuit Diamond diamondsuit heartsuit spadesuit triangle
    }
    "symbols4"      {
	flat natural sharp
    }
    "functions"     {
	arccos arcsin arctan arg bmod cos cosh cot coth csc deg det dim exp
	gcd hom inf ker lg lim liminf limsup ln log max min pmod Pr sec sin
	sinh sup tan tanh
    }
    "largeOps1"     {
	coprod int oint prod sum
    }
    "largeOps2"     {
	bigcap bigcup bigodot bigoplus bigotimes bigsqcup biguplus bigvee
	bigwedge
    }
    "mathAccents"   {
	acute bar breve check ddot dot grave hat tilde vec widehat
	widetilde
    }
    "grouping"      {
	overbrace overleftarrow overline overrightarrow stackrel underbrace
	underline
    }
    "spacing1"      {
	smallskip medskip bigskip
    }
    "spacing2"      {
	hfill hspace qquad quad vfill vspace
    }
}

# Used to remember the last position.
set TeX::LastLaTeXSizesPos [minPos]

proc TeX::cycleList {inc} {
    
    global TeXmodeVars TeX::LaTeXSizes TeX::LastLaTeXSizesPos TeX::DoLaTeXCycle
    
    if {![set TeX::DoLaTeXCycle]} {return}
    
    # Some of these might be changed by the user, so we define them each time.
    if {![info exists TeXmodeVars(useAMSLaTeX)] || !$TeXmodeVars(useAMSLaTeX)} {
        set TeX::LaTeXSizes(textSize) {
	    "tiny" "scriptsize" "footnotesize" "small" "normalsize" "large"
	    "Large" "LARGE" "huge" "Huge"
	} 
    } else {
	set TeX::LaTeXSizes(textSize) {
	    "Tiny" "tiny" "SMALL" "Small" "small" "normalsize" "large"
	    "Large" "LARGE" "huge" "Huge"
	} 
    }
    # Add any TeX mode 'cite' commands.
    if {[info exists TeXmodeVars(citeCommands)]} {
	set TeX::LaTeXSizes(cite) $TeXmodeVars(citeCommands)
    }

    set len0 [string length [getSelect]]
    if {[pos::compare [getPos] != [set TeX::LastLaTeXSizesPos]]} {
	# The first time we're called, we just present the list.
        set inc 0
    } 
    set result [TeX::nearestCommand [set pos [getPos]]]
    if {![string length [set txt [lindex $result 0]]]} {
	status::msg "Could not find any LaTeX command in the surrounding text."
	return
    } 
    set posBeg [lindex $result 1]
    set posEnd [lindex $result 2]
    if {[pos::compare $posEnd < $pos]} {
        # The end of the command is to the left of the current position,
        # so we must be within some braces.
	set awayFromCommand [pos::diff $posBeg $pos]
    } 
    # Does it belong to any list?
    foreach optionType [array names TeX::LaTeXSizes] {
	if {[set idx [lsearch [set TeX::LaTeXSizes($optionType)] $txt]] != "-1"} {
	    break
	} 
    }
    if {$idx == "-1"} {
        # We cycled through all of them and didn't find any.
        status::msg "'$txt' was not found in any LaTeX Sizes list."
	return
    } 
    # Do we have a replacement?
    set newString [lindex [set TeX::LaTeXSizes($optionType)] [incr idx $inc]]
    set offset    [string length "\\$newString"]
    if {![string length $newString]} {
	# We reached the end of the line.
	status::msg "No further options beyond '$txt'"
	return
    } elseif {$newString == {[delete]}} {
        deleteText $posBeg $posEnd
	status::msg "'\\$txt' has been deleted."
	return
    } elseif {$inc != "0"} {
        replaceText $posBeg $posEnd "\\$newString"
    }
    # Go to where we were, and remember this position.
    if {[info exists awayFromCommand]} {
	set len1 [string length $txt]
	set len2 [string length "\\$newString"]
	set pos4 [pos::math $posBeg - $len1 + $len2 + $awayFromCommand]
	selectText $pos4 [pos::math $pos4 + $len0]
	set TeX::LastLaTeXSizesPos $pos4
    } elseif {[pos::compare $pos > [set posEnd [pos::math $posBeg + $offset]]]} {
        goto [set TeX::LastLaTeXSizesPos $posEnd]
    } else {
        goto [set TeX::LastLaTeXSizesPos $pos]
    }
    # Display the new position in the order.
    set options [set TeX::LaTeXSizes($optionType)]
    set options [lreplace $options $idx $idx \{[lindex $options $idx]\}]
    set options "  [join $options "  "]"
    regsub {  \{} $options " \{" options
    regsub {\}  } $options "\} " options
    if {[set optionsLen [string length $options]] < 78} {
	set msg $options
    } else {
	# Too long to fit in the status bar window.
        set segIncr 50
	set segIdx1  0
	set segIdx2 60
	set segIdx3 73
	set pre [set post ""]
	while {$segIdx2 < [expr {$optionsLen + $segIncr}]} {
	    set segment1 [string range $options $segIdx1 $segIdx2]
	    set segment2 [string range $options $segIdx1 $segIdx3]
	    if {[regexp {\{.+\}} $segment1]} {
		if {$segIdx2 < $optionsLen} {set post " É"}
		set msg "${pre}${segment2}${post}"
		break
	    } 
	    set pre "É "
	    incr segIdx1 $segIncr
	    incr segIdx2 $segIncr
	    incr segIdx3 $segIncr
	}
    }
    status::msg $msg
}

proc TeX::nearestCommand {pos} {
    
    set posBeg [set posEnd $pos]

    set txt  ""
    set pos1 [lineStart $pos]
    set pos2 [nextLineStart $pos]
    set pos3 $pos
    set txt1 [getText $pos1 $pos]
    set txt2 [getText $pos $pos2]
    set pat1 {\\[a-zA-Z]*$}

    # Find the start of this word, including the leading '\'
    if {[regexp -indices $pat1 $txt1 match]} {
	set posBeg [pos::math $pos1 + [lindex $match 0]]
	set pat2 {^[a-zA-Z]+[^a-zA-Z]}
    } else {
	set pat2 {^\\[a-zA-Z]+[^a-zA-Z]}
    }
    # Find the end of this word.
    if {[regexp -indices $pat2 $txt2 match]} {
	set posEnd [pos::math $pos + [lindex $match 1]]
    } 
    # Do we have a word?
    if {![regsub {^\\} [getText $posBeg $posEnd] "" txt]} {
	set txt ""
	# Try harder -- maybe we're in the middle of \command{some text},
	# or possibly {\command some text}.
	set pat3 "(\\\\\[a-zA-Z\]+)\[*\r\n\t \]*\[^\\\\\]?(\[\\\[\{\\\(\])"
	set pat4 "\[^\\\\\]?(\[\\\[\{\\\(\])\[*\r\n\t \]*(\\\\\[a-zA-Z\]+)"
	if {![catch {search -s -f 0 -r 1 $pat3 $pos} match]} {
	    # We're  in something like \command{some text}
	    set posBeg [lindex $match 0]
	    set txtstr [getText $posBeg $pos]
	    regexp $pat3 $txtstr allofit txt delim1
	    switch -- $delim1 {
		"\[" {set delim2 "\\\]"}
		"\{" {set delim2 "\}"}
		"\(" {set delim2 "\\\)"}
	    }
	    # ...  are we within the closing brace?
	    if {[regexp $delim2 $txtstr]} {set txt ""}
	    set posEnd [pos::math $posBeg + [string length $txt]]
	    set inside [pos::diff $posBeg $pos]
	} 
	if {$txt == "" && ![catch {search -s -f 0 -r 1 $pat4 $pos} match]} {
	    # We're  in something like {\command some text}
	    set posBeg [lindex $match 0]
	    set posEnd [lindex $match 1]
	    set txtstr [getText $posBeg $pos]
	    regexp $pat4 $txtstr allofit delim1 txt
	    switch -- $delim1 {
		"\[" {set delim2 "\\\]"}
		"\{" {set delim2 "\}"}
		"\(" {set delim2 "\\\)"}
	    }
	    # ...  are we within the closing brace?
	    if {[regexp $delim2 $txtstr]} {set txt ""}
	    set posBeg [pos::math $posEnd - [string length $txt]]
	    set inside [pos::diff $posBeg $pos]
	} 
    }
    return [list $txt $posBeg $posEnd]
}

# ×××× Contextual Menu module ×××× #

proc TeX::buildRelatedCM {args} {
 
    global alpha::CMArgs TeX::LaTeXSizes TeXmodeVars
    
    # Some of these might be changed by the user, so we define them each time.
    if {![info exists TeXmodeVars(useAMSLaTeX)] || !$TeXmodeVars(useAMSLaTeX)} {
	set TeX::LaTeXSizes(textSize) {
	    "tiny" "scriptsize" "footnotesize" "small" "normalsize" "large"
	    "Large" "LARGE" "huge" "Huge"
	} 
    } else {
	set TeX::LaTeXSizes(textSize) {
	    "Tiny" "tiny" "SMALL" "Small" "small" "normalsize" "large"
	    "Large" "LARGE" "huge" "Huge"
	} 
    }
    # Add any TeX mode 'cite' commands.
    if {[info exists TeXmodeVars(citeCommands)]} {
	set TeX::LaTeXSizes(cite) $TeXmodeVars(citeCommands)
    }


    set pos0 [lindex [set alpha::CMArgs] 0]
    set pos1 [lindex [set alpha::CMArgs] 1]
    set pos2 [lindex [set alpha::CMArgs] 2]

    set result [nearestCommand $pos0]
    
    variable RelatedCMPositions [lrange $result 1 2]

    if {[string length [set txt [lindex $result 0]]]} {
	foreach optionType [array names LaTeXSizes] {
	    if {[set idx [lsearch [set LaTeXSizes($optionType)] $txt]] != "-1"} {
		break
	    } 
	}
	if {$idx != "-1"} {
	    set menuList [lreplace $LaTeXSizes($optionType) $idx $idx \
	      "\([lindex $LaTeXSizes($optionType) $idx]"]
	} else {
	    set menuList [list "(No related commands found"]
	}
    } else {
	set menuList [list "(No nearby command found"]
    }
    return [list build $menuList {TeX::relatedCMProc -m}]
}

proc TeX::relatedCMProc {menuName itemName} {
    
    variable RelatedCMPositions
    
    set pos0 [lindex $RelatedCMPositions 0]
    set pos1 [lindex $RelatedCMPositions 1]
    replaceText $pos0 $pos1 "\\$itemName"
}

# ==========================================================================
# 
# .