## -*-Tcl-*-
 # ###################################################################
 #  Core utilities taken from HTML mode - tools for editing HTML documents
 # 
 #  FILE: "htmlUtilities.tcl"
 #                                    created: 98-02-15 18.04.08 
 #                                last update: 04/28/2004 {07:37:10 PM} 
 #  Author: Johan Linde
 #  E-mail: <alpha_www_tools@go.to>
 #     www: <http://go.to/alpha_www_tools>
 #  
 # From HTML mode Version: 3.1.2
 # 
 # Copyright 1996-2004 by Johan Linde
 #  
 # Distributed under BSD license as part of AlphaTcl.
 # 
 # ###################################################################
 ##

# auto-loading extension.
alpha::extension htmlUtilities 0.1 {
} description {
    Provides utilities for parsing html strings, used by other AlphaTcl code
} help {
    General purpose html utilities for use by any of AlphaTcl, but
    required by AlphaTcl's core.
}

proc loadHtmlUtilities.tcl {} {}

namespace eval html {}

proc html::parseTagtype {tag text} {
    set res {}
    while {1} {
	set b [string first "<$tag " $text]
	if {$b == -1} { break }
	set e [string first "</$tag>" $text]
	if {$e == -1} { break }
	set contents [string range $text $b [expr {$e -1}]]
	set text [string range $text [expr {$e + 2 + [string length $tag]}] end]
	
	regexp {([^>]+)>(.*)} $contents -> attrs contents
	
	regexp -nocase {name="([^\"]*)"} $attrs -> name
	if {![info exists name]} {
	    set name ""
	}
	
	lappend res $name [quote::Unhtml $contents]
	unset name
    }
    return $res
}

proc html::NewCharVar {var val} {
    global html::SpecialCharacter html::CharacterSpecial
    set html::SpecialCharacter($var) $val 
    set html::CharacterSpecial($val) $var
}

proc html::NewCapCharVar {var men val} {
    global html::SpecialCharacter html::CharacterSpecial html::CapCharSpecMenu
    set html::SpecialCharacter($var) $val 
    set html::CharacterSpecial($val) $var
    set html::CapCharSpecMenu($men) $val
}

html::NewCharVar "�" szlig
html::NewCharVar "�" agrave
html::NewCharVar "�" aacute
html::NewCharVar "�" acirc
html::NewCharVar "�" atilde
html::NewCharVar "�" auml
html::NewCharVar "�" aring
html::NewCharVar "�" aelig
html::NewCharVar "�" ccedil
html::NewCharVar "�" egrave
html::NewCharVar "�" eacute
html::NewCharVar "�" ecirc
html::NewCharVar "�" euml
html::NewCharVar "�" igrave
html::NewCharVar "�" iacute
html::NewCharVar "�" icirc
html::NewCharVar "�" iuml
set html::CapCharSpecMenu(eth) eth
html::NewCharVar "�" ntilde
html::NewCharVar "�" ograve
html::NewCharVar "�" oacute
html::NewCharVar "�" ocirc
html::NewCharVar "�" otilde
html::NewCharVar "�" ouml
html::NewCharVar "�" oslash
html::NewCharVar "�" ugrave
html::NewCharVar "�" uacute
html::NewCharVar "�" ucirc
html::NewCharVar "�"	uuml
set html::CapCharSpecMenu(y�) yacute
set html::CapCharSpecMenu(thorn) thorn
html::NewCharVar "�"	yuml
html::NewCharVar "�" "#339"

html::NewCapCharVar "�" "�" Agrave
html::NewCapCharVar "�" "A�" Aacute
html::NewCapCharVar "�" "A^" Acirc
html::NewCapCharVar "�" "�" Atilde
html::NewCapCharVar "�" "�" Auml
html::NewCapCharVar "�" "�" Aring
html::NewCapCharVar "�" "�" AElig
html::NewCapCharVar "�" "�" Ccedil
html::NewCapCharVar "�" "E`" Egrave
html::NewCapCharVar "�" "�" Eacute
html::NewCapCharVar "�" "E^" Ecirc
html::NewCapCharVar "�" "E�" Euml
html::NewCapCharVar "�" "I`" Igrave
html::NewCapCharVar "�" "I�" Iacute
html::NewCapCharVar "�" "I^" Icirc
html::NewCapCharVar "�" "I�" Iuml
set html::CapCharSpecMenu(ETH) ETH
html::NewCapCharVar "�" "�" Ntilde
html::NewCapCharVar "�" "O`" Ograve
html::NewCapCharVar "�" "O�" Oacute
html::NewCapCharVar "�" "O^" Ocirc
html::NewCapCharVar "�" "�" Otilde
html::NewCapCharVar "�" "�" Ouml
html::NewCapCharVar "�" "�" Oslash
html::NewCapCharVar "�" "U`" Ugrave
html::NewCapCharVar "�" "U�" Uacute
html::NewCapCharVar "�" "U^" Ucirc
html::NewCapCharVar "�" "�"	Uuml
set html::CapCharSpecMenu(Y�) Yacute
set html::CapCharSpecMenu(THORN) THORN
html::NewCapCharVar "�" "�" "#338"
html::NewCapCharVar "�" "Y�" "#376"

set "html::CapCharSpecMenu(quotation mark)"	quot
set html::CapCharSpecMenu(ampersand) amp
set "html::CapCharSpecMenu(less than)" lt
set "html::CapCharSpecMenu(greater than)" gt
set "html::CapCharSpecMenu(nonbreak space)"	nbsp
html::NewCapCharVar "�" "inverted excl. mark" "#161"
html::NewCapCharVar "�" cent "#162"
html::NewCapCharVar "�" pound "#163"
set html::CapCharSpecMenu(currency) "#164"
html::NewCapCharVar "�" yen "#165"
html::NewCapCharVar "\\|" "broken bar" "#166"
html::NewCapCharVar "�" "section sign" "#167"
html::NewCapCharVar "�" diearesis "#168"
html::NewCapCharVar "�" "copyright sign" copy
html::NewCapCharVar "�" "feminine ordinal ind." "#170"
html::NewCapCharVar "�" "left double angle" "#171"
html::NewCapCharVar "�" "not sign" "#172"
set "html::CapCharSpecMenu(soft hyphen)" "#173"
html::NewCapCharVar "�" "registered sign" reg
html::NewCapCharVar "�" macron "#175"
html::NewCapCharVar "�" degree "#176"
html::NewCapCharVar "�" "plus-minus" "#177"
set "html::CapCharSpecMenu(superscript two)" "#178"
set "html::CapCharSpecMenu(superscript three)" "#179"
html::NewCapCharVar "�" "acute accent" "#180"
html::NewCapCharVar "�" "micro sign" "#181"
html::NewCapCharVar "�" "paragraph sign" "#182"
html::NewCapCharVar "�" "middle dot" "#183"
html::NewCapCharVar "�" cedilla "#184"
set "html::CapCharSpecMenu(superscript one)" "#185"
html::NewCapCharVar "�" "masculine ordinal ind." "#186"
html::NewCapCharVar "�" "right double angle" "#187"
set "html::CapCharSpecMenu(one quarter)" "#188"
set "html::CapCharSpecMenu(one half)" "#189"
set "html::CapCharSpecMenu(three quarters)" "#190"
html::NewCapCharVar "�" "inverted question mark" "#191"
set html::CapCharSpecMenu(times) "#215"
html::NewCapCharVar "�" divide "#247"
html::NewCapCharVar "�" "en dash" "#8211"
html::NewCapCharVar "�" "em dash" "#8212"
html::NewCapCharVar "�" "left single quotation" "#8216"
html::NewCapCharVar "�" "right single quotation" "#8217"
html::NewCapCharVar "�" "single low quotation" "#8218"
html::NewCapCharVar "�" "left double quotation" "#8220"
html::NewCapCharVar "�" "right double quotation" "#8221"
html::NewCapCharVar "�" "double low quotation" "#8222"
html::NewCapCharVar "�" dagger "#8224"
html::NewCapCharVar "�" "double dagger" "#8225"
html::NewCapCharVar "�" "per mille sign" "#8240"
html::NewCapCharVar "�" "left single angle" "#8249"
html::NewCapCharVar "�" "right single angle" "#8250"
html::NewCapCharVar "�" florin "#402"
html::NewCapCharVar "�" bullet "#8226"
html::NewCapCharVar "�" ellipsis "#8230"
html::NewCapCharVar "�" "trade mark sign" "#8482"
html::NewCapCharVar "�" "square root" "#8730"
html::NewCapCharVar "�" infinity "#8734"
html::NewCapCharVar "�" integral "#8747"
html::NewCapCharVar "�" "approximately equal to" "#8776"
html::NewCapCharVar "�" "not equal to" "#8800"
html::NewCapCharVar "�" "less-than or equal" "#8804"
html::NewCapCharVar "�" "greater-than or equal" "#8805"
html::NewCapCharVar "?" euro "#8364"

rename html::NewCharVar ""
rename html::NewCapCharVar ""
