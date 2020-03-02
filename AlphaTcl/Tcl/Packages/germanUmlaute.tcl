# -*-Tcl-*-
# 
# Support of german keyboard in TeX mode
#                                                                              
alpha::feature germanUmlaute 0.2.1 {TeX Bib} {
    # Initialization script
} {
    # Activation script
    TeX::bindGermanUmlautKeys
} {
    # Deactivation script.
    TeX::bindGermanUmlautKeys "unBind"
} uninstall {
    this-file
} description {
    This feature supports the German keyboard in TeX and Bib modes
} help {
    This feature supports the German keyboard in TeX and Bib modes.  Turning
    it on
    
    Preferences: Features
    
    will create the following keyboard shortcuts for the following ascii
    keystrokes in both TeX and Bib modes:
    
	0x21            \"{u}
	Shift-0x21      \"{U}
	0x27            \"{a}
	Shift-0x27      \"{A}
	0x29            \"{o}
	Shift-0x29      \"{O}
	0x1b            \ss 
    
    This feature could also be turned on just for Bib or TeX modes:
    
    Preferences: Mode-Features-TeX
    Preferences: Mode-Features-Bib
    
    although even if turned on "globally" it will only change the bindings
    for these two modes.
}

namespace eval TeX {}
proc TeX::bindGermanUmlautKeys {{which "Bind"}} {
    foreach m [list "TeX" "Bib"] {
	$which 0x21     {TeX::GermanUmlaut u} $m
	$which 0x21 <s> {TeX::GermanUmlaut U} $m
	$which 0x27     {TeX::GermanUmlaut a} $m
	$which 0x27 <s> {TeX::GermanUmlaut A} $m
	$which 0x29     {TeX::GermanUmlaut o} $m
	$which 0x29 <s> {TeX::GermanUmlaut O} $m
	$which 0x1b     {TeX::GermanUmlaut s} $m
    }
}
proc TeX::GermanUmlaut {char} {
    switch -- $char {
	"u" {typeText "\\\"{u}"}
	"U" {typeText "\\\"{U}"}
	"a" {typeText "\\\"{a}"}										     
	"A" {typeText "\\\"{A}"}
	"o" {typeText "\\\"{o}"}
	"O" {typeText "\\\"{O}"}
	"s" {typeText "\\ss "}
    }
}

                                                                         

