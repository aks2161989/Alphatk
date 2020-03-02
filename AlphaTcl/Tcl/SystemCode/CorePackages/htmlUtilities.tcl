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

html::NewCharVar "ß" szlig
html::NewCharVar "à" agrave
html::NewCharVar "á" aacute
html::NewCharVar "â" acirc
html::NewCharVar "ã" atilde
html::NewCharVar "ä" auml
html::NewCharVar "å" aring
html::NewCharVar "æ" aelig
html::NewCharVar "ç" ccedil
html::NewCharVar "è" egrave
html::NewCharVar "é" eacute
html::NewCharVar "ê" ecirc
html::NewCharVar "ë" euml
html::NewCharVar "ì" igrave
html::NewCharVar "í" iacute
html::NewCharVar "î" icirc
html::NewCharVar "ï" iuml
set html::CapCharSpecMenu(eth) eth
html::NewCharVar "ñ" ntilde
html::NewCharVar "ò" ograve
html::NewCharVar "ó" oacute
html::NewCharVar "ô" ocirc
html::NewCharVar "õ" otilde
html::NewCharVar "ö" ouml
html::NewCharVar "ø" oslash
html::NewCharVar "ù" ugrave
html::NewCharVar "ú" uacute
html::NewCharVar "û" ucirc
html::NewCharVar "ü"	uuml
set html::CapCharSpecMenu(y´) yacute
set html::CapCharSpecMenu(thorn) thorn
html::NewCharVar "ÿ"	yuml
html::NewCharVar "œ" "#339"

html::NewCapCharVar "À" "À" Agrave
html::NewCapCharVar "Á" "A´" Aacute
html::NewCapCharVar "Â" "A^" Acirc
html::NewCapCharVar "Ã" "Ã" Atilde
html::NewCapCharVar "Ä" "Ä" Auml
html::NewCapCharVar "Å" "Å" Aring
html::NewCapCharVar "Æ" "Æ" AElig
html::NewCapCharVar "Ç" "Ç" Ccedil
html::NewCapCharVar "È" "E`" Egrave
html::NewCapCharVar "É" "É" Eacute
html::NewCapCharVar "Ê" "E^" Ecirc
html::NewCapCharVar "Ë" "E¨" Euml
html::NewCapCharVar "Ì" "I`" Igrave
html::NewCapCharVar "Í" "I´" Iacute
html::NewCapCharVar "Î" "I^" Icirc
html::NewCapCharVar "Ï" "I¨" Iuml
set html::CapCharSpecMenu(ETH) ETH
html::NewCapCharVar "Ñ" "Ñ" Ntilde
html::NewCapCharVar "Ò" "O`" Ograve
html::NewCapCharVar "Ó" "O´" Oacute
html::NewCapCharVar "Ô" "O^" Ocirc
html::NewCapCharVar "Õ" "Õ" Otilde
html::NewCapCharVar "Ö" "Ö" Ouml
html::NewCapCharVar "Ø" "Ø" Oslash
html::NewCapCharVar "Ù" "U`" Ugrave
html::NewCapCharVar "Ú" "U´" Uacute
html::NewCapCharVar "Û" "U^" Ucirc
html::NewCapCharVar "Ü" "Ü"	Uuml
set html::CapCharSpecMenu(Y´) Yacute
set html::CapCharSpecMenu(THORN) THORN
html::NewCapCharVar "Œ" "Œ" "#338"
html::NewCapCharVar "Ÿ" "Y¨" "#376"

set "html::CapCharSpecMenu(quotation mark)"	quot
set html::CapCharSpecMenu(ampersand) amp
set "html::CapCharSpecMenu(less than)" lt
set "html::CapCharSpecMenu(greater than)" gt
set "html::CapCharSpecMenu(nonbreak space)"	nbsp
html::NewCapCharVar "¡" "inverted excl. mark" "#161"
html::NewCapCharVar "¢" cent "#162"
html::NewCapCharVar "£" pound "#163"
set html::CapCharSpecMenu(currency) "#164"
html::NewCapCharVar "¥" yen "#165"
html::NewCapCharVar "\\|" "broken bar" "#166"
html::NewCapCharVar "§" "section sign" "#167"
html::NewCapCharVar "¨" diearesis "#168"
html::NewCapCharVar "©" "copyright sign" copy
html::NewCapCharVar "ª" "feminine ordinal ind." "#170"
html::NewCapCharVar "«" "left double angle" "#171"
html::NewCapCharVar "¬" "not sign" "#172"
set "html::CapCharSpecMenu(soft hyphen)" "#173"
html::NewCapCharVar "®" "registered sign" reg
html::NewCapCharVar "¯" macron "#175"
html::NewCapCharVar "°" degree "#176"
html::NewCapCharVar "±" "plus-minus" "#177"
set "html::CapCharSpecMenu(superscript two)" "#178"
set "html::CapCharSpecMenu(superscript three)" "#179"
html::NewCapCharVar "´" "acute accent" "#180"
html::NewCapCharVar "µ" "micro sign" "#181"
html::NewCapCharVar "¶" "paragraph sign" "#182"
html::NewCapCharVar "·" "middle dot" "#183"
html::NewCapCharVar "¸" cedilla "#184"
set "html::CapCharSpecMenu(superscript one)" "#185"
html::NewCapCharVar "º" "masculine ordinal ind." "#186"
html::NewCapCharVar "»" "right double angle" "#187"
set "html::CapCharSpecMenu(one quarter)" "#188"
set "html::CapCharSpecMenu(one half)" "#189"
set "html::CapCharSpecMenu(three quarters)" "#190"
html::NewCapCharVar "¿" "inverted question mark" "#191"
set html::CapCharSpecMenu(times) "#215"
html::NewCapCharVar "÷" divide "#247"
html::NewCapCharVar "–" "en dash" "#8211"
html::NewCapCharVar "—" "em dash" "#8212"
html::NewCapCharVar "‘" "left single quotation" "#8216"
html::NewCapCharVar "’" "right single quotation" "#8217"
html::NewCapCharVar "‚" "single low quotation" "#8218"
html::NewCapCharVar "“" "left double quotation" "#8220"
html::NewCapCharVar "”" "right double quotation" "#8221"
html::NewCapCharVar "„" "double low quotation" "#8222"
html::NewCapCharVar "†" dagger "#8224"
html::NewCapCharVar "‡" "double dagger" "#8225"
html::NewCapCharVar "‰" "per mille sign" "#8240"
html::NewCapCharVar "‹" "left single angle" "#8249"
html::NewCapCharVar "›" "right single angle" "#8250"
html::NewCapCharVar "ƒ" florin "#402"
html::NewCapCharVar "•" bullet "#8226"
html::NewCapCharVar "…" ellipsis "#8230"
html::NewCapCharVar "™" "trade mark sign" "#8482"
html::NewCapCharVar "√" "square root" "#8730"
html::NewCapCharVar "∞" infinity "#8734"
html::NewCapCharVar "∫" integral "#8747"
html::NewCapCharVar "≈" "approximately equal to" "#8776"
html::NewCapCharVar "≠" "not equal to" "#8800"
html::NewCapCharVar "≤" "less-than or equal" "#8804"
html::NewCapCharVar "≥" "greater-than or equal" "#8805"
html::NewCapCharVar "?" euro "#8364"

rename html::NewCharVar ""
rename html::NewCapCharVar ""
