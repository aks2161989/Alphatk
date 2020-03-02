## -*-Tcl-*- (install)
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "latexMathbb.tcl"
 #                                          created: 01/26/1998 {03:12:38 pm}
 #                                      last update: 03/21/2006 {02:16:59 PM}
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 # 
 # Copyright (c) 1998-2006  Vince Darley
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # Distributable under Tcl-style (free) license.
 # 
 # ==========================================================================
 ##

# extension declaration
alpha::feature latexMathbb 1.3.2 {TeX Bib} {
    # Initialization script.
    namespace eval TeX {}
    set TeX::UseMathbb 0
    newPref var blackboardBoldSymbols "QZRN" TeX {TeX::Mathbb::adjustBindings}
} {
    # Activation script.
    TeX::Mathbb::turnOnOff 1
} {
    # Deactivation script.
    TeX::Mathbb::turnOnOff 0
} maintainer {
    {Vince Darley} <vince@santafe.edu> <http://www.santafe.edu/~vince/>
} requirements {
    alpha::package require -loose TeX 5.0
} uninstall {
    this-file
} description {
    Turns 'ZZ' into $\mathbb{Z}$ (e.g) on the fly
} help {
    This is a feature for TeX and Bib modes.  Once this feature has been 
    turned on, typing 
    
	ZZ

    will automatically be substituted with 

	\mathbb{Z}

    on the fly, and the same for any other symbols in your TeX mode preference
    "Blackboard Bold Symbols".  Note that this preference is 'attached' to TeX
    mode, and can only be changed when the current window is in TeX mode,
    although the preference does apply to both TeX and Bib.
    
    If this package is turned on globally via "Config > Global Setup > Features", 
    it applies to both modes, else you must activate it separately for each 
    mode by selecting the menu item "Config > Mode Prefs > Features" .
	
	Preferences: Features
	
	Preferences: Mode-Features-TeX
	Preferences: Mode-Features-Bib
}

proc latexMathbb.tcl {} {}

namespace eval TeX::Mathbb {}

proc TeX::Mathbb::turnOnOff {isOn} {
    global TeX::UseMathbb
    set TeX::UseMathbb $isOn
    TeX::Mathbb::setBindings $isOn
}

proc TeX::Mathbb::adjustBindings {args} {
    global TeX::UseMathbb
    if {![set TeX::UseMathbb]} { return }
    TeX::Mathbb::setBindings 1
}

proc TeX::Mathbb::setBindings {on} {
    global TeXmodeVars
    
    foreach symbol [split $TeXmodeVars(blackboardBoldSymbols) {}] {
	foreach m [list TeX Bib] {
	    if {$on} {
		Bind '[string tolower $symbol]' <s> \
		  "TeX::Mathbb::convert $symbol" $m
	    } else {
		unBind '[string tolower $symbol]' <s> \
		  "TeX::Mathbb::convert $symbol" $m
	    }
	}
    }
    TeX::Mathbb::addSmartEscape $on
}

proc TeX::Mathbb::addSmartEscape {on} {
    global TeX::smartEscape TeXmodeVars
    if {![info exists TeX::smartEscape]} {latexSmart.tcl}
    
    foreach symbol [split $TeXmodeVars(blackboardBoldSymbols) ""] {
	set mathbb "\\\\mathbb\\\{${symbol}\\\}$"
	lappend mathbbEscapes [list 0 $mathbb ${symbol}${symbol}]
    }
    foreach escape $mathbbEscapes {
	TeX::modifySmartEscapes $escape $on
    }
}

proc TeX::Mathbb::convert {symb} {

    global TeX::UseMathbb

    if {![set TeX::UseMathbb] || [lookAt [pos::math [getPos] - 1]] != $symb} { 
	typeText $symb ; return
    }
    selectText [pos::math [getPos] - 1] [getPos]
    TeX::doUppercaseMathStyle mathbb "math blackboard bold"
}

# ===========================================================================
# 
# .