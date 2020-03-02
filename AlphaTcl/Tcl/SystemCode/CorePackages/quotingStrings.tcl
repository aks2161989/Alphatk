#  AlphaTcl - core Tcl engine

namespace eval quote {}

## 
 # -------------------------------------------------------------------------
 # 
 # "quote::" --
 # 
 # Manipulate string so search and insertion procedures work as expected.
 # When strings are passed to functions such as 'regexp', 'glob', 
 # 'lsearch -glob', etc. certain characters in those strings will be
 # interpreted as special (in some sense) unless they are preceded
 # by a backslash '\' character.  Exactly which characters have this
 # effect depends on the command in question.  These procedures allow
 # you to quote exactly the right characters so the commands work
 # as expected with arbitrary strings.
 # 
 # Of course, these procedures should only be used when you want to
 # avoid the effect of the special characters -- usually you don't!
 # 
 # quote::Find
 # 
 #  Use this for 'glob' type searches, but not 'glob' itself!  The
 #  commands 'string match', 'lsearch -glob' need their arguments
 #  quoted with this procedure.
 #  
 # quote::Glob
 #  
 #  Glob treats expressions like {a,b,c} specially, in addition to
 #  *,? etc, so requires a separate procedure.
 # 	
 # quote::Regfind
 # 
 #  Use this for regexp searches.  Note that this procedure hasn't
 #  been tested much with the advanced regexps in Tcl 8.2
 #  
 # quote::Regsub
 # 
 #  Use this for the replacement expression.  A common usage might look
 #  like this:
 #   
 #   regsub -all [quote::Regfind $from] [read $cid] [quote::Regsub $to] out
 #  
 # quote::Insert
 # 
 #  Quotes any block of text captured from a window so it can be used as a 
 #  Tcl string. e.g. 'set a [quote::Insert [getSelect]] ; eval insertText $a'
 #  will work correctly.  Can be used to generate procedures on the fly,
 #  especially to add to your prefs.tcl:
 #  
 #   set a [quote::Insert [getSelect]]
 #   prefs::addGlobalPrefsLine "proc foo \{\} \{ return \"$a\" \}"
 # 
 # -------------------------------------------------------------------------
 ##
proc quote::Find  str {
    regsub -all {[][\\*?]} $str {\\&} str
    return $str
}

proc quote::Regfind str {
    regsub -all {[][\$?^|*+()\.\{\}\\]} $str {\\&} str
    return $str
}

proc quote::Regsub str {
    regsub -all {(\\|&)} $str {\\&} str
    return $str
}

proc quote::Glob str {
    regsub -all {[][*?\{\}\\]} $str {\\&} str
    return $str
}

proc quote::Insert str {
    regsub -all {[][\\$"\{\}]} $str {\\&} str
    string map [list "\r" "\\r" "\n" "\\n" "\t" "\\t"] $str
}

## 
 # -------------------------------------------------------------------------
 # 
 # "quote::Url" --
 # 
 #  If you want a piece of arbitrary text to be part of a URL, then
 #  various characters needed to be turned into their hexadecimal
 #  equivalent.  This procedure does that.
 # -------------------------------------------------------------------------
 ##
proc quote::Url {str {slash 0}} {
    set nstr ""
    set exp "\[\001- \177-ÿ%<>\"#\?=&;|\\{\\}\\`^"
    if {$slash} {append exp "/"}
    append exp "\]"
    while {[regexp -indices $exp $str c]} {
	scan [string index $str [lindex $c 0]] %c asc
	append nstr \
	  [string range $str 0 [expr {[lindex $c 0] - 1}]] \
	  [format {%%%02X} $asc]
	set str [string range $str [expr {[lindex $c 1] + 1}] end]
    }
    return "$nstr$str"
}

proc quote::UrlExceptAnchor {str} {
    set url ""
    regexp {[^#]*} $str url
    set anchor [string range $str [string length $url] end]
    return "[quote::Url $url]$anchor"
}

proc quote::Unurl {url} {
    # Could inline these
    regsub -all {\\} $url {\\\\} url
    regsub -all {%(..)} $url {\x\1\a} url
    encoding convertfrom utf-8 [join [split [subst -nocommands \
      -novariables $url] "\a"] ""]
}

loadHtmlUtilities.tcl

proc quote::Unhtml {text} {
    global html::CharacterSpecial
    set entitylist [list "&amp;" "&lt;" "&gt;" "&#8482;" "&nbsp;" "&quot;"]
    foreach char $entitylist {
	set schar [string range $char 1 [expr {[string length $char] - 2}]]
	if {[info exists html::CharacterSpecial($schar)]} {
	    set rtext [set html::CharacterSpecial($schar)]
	} elseif {$schar == "amp"} {
	    set rtext "\\&"
	} elseif {$schar == "lt"} {
	    set rtext "<"
	} elseif {$schar == "gt"} {
	    set rtext ">"
	} elseif {$schar == "quot"} {
	    set rtext "\""
	} elseif {$schar == "nbsp"} {
	    set rtext " "
	} elseif {$schar == "#8482"} {
	    set rtext "ª"
	}
	
	set subNum [regsub -all $char $text $rtext text]
    }
    return $text
}

# These procs have been modified to avoid substitutions in TeX commands 
# starting with \n, \r and \t. The fix is based on replacing single \ by
# double \\ in 'quote::Display' and replacing \(n|r|t) by their ascii
# counterpart only if there is an odd number of \.
proc quote::Display str {
    regsub -all {\\} $str {\\\\} str
    regsub -all "\r" $str "\\r" str
    regsub -all "\n" $str "\\n" str
    regsub -all "\t" $str "\\t" str
    return $str
}

proc quote::Undisplay str {
    regsub -all {(^|[^\\]|(\\\\)+)\\r} $str "\\1\r" str
    regsub -all {(^|[^\\]|(\\\\)+)\\n} $str "\\1\n" str
    regsub -all {(^|[^\\]|(\\\\)+)\\t} $str "\\1\t" str
    regsub -all {\\\\} $str {\\} str
    return $str
}

## 
 # -------------------------------------------------------------------------
 # 
 # "quote::Prettify" --
 # 
 # Since we're supposed to be a LaTeX editor, we handle names with "TeX" in
 # them a bit differently, as in
 # 
 # laTeXMenu    > LaTeX Menu
 # bibTeXApp    > BibTeX App
 # 
 # There are also some other special cases built in:
 # 
 # alphaTclItem > AlphaTcl Item
 # input-Output > Input - Output
 # item::name   > Item-name
 # item::Name   > Item-Name
 # reportABug   > Report A Bug
 # 
 # -------------------------------------------------------------------------
 # 
 # The order of the [regsub] commands matters.  Here's what they do:
 # 
 # (1)  regsub -all {^::} $str {} str
 # 
 # Strip all leading {::} from the string.
 # 
 # (2)  set a [string toupper [string index $str 0]]
 # 
 # Capitalize the first character in the string.
 # 
 # (3)  regsub -all {([^A-Z])([A-Z])} [string range $str 1 end] {\1 \2} b
 # 
 # Add a space between each "word" as indicated by an Upper Case letter
 # immediately following a lower case letter.  While this would seem to be
 # all that is required, we then take care of special cases.
 # 
 # (4)  regsub -all {((La|Bib|Oz|CMac) )?Te X} $a$b {\2TeX } a
 # 
 # We concatenate "a" (the first letter) and "b" (the rest) and make sure
 # that any "TeX" type string doesn't have unnecessary spaces.  At this point
 # our string is contained in "a".
 # 
 # (5)  regsub -all {Alpha Tcl} $a {AlphaTcl} a
 # 
 # Special case to retain the "AlphaTcl" string.
 # 
 # (6)  regsub -all {([A-Z])([A-Z][a-z])} $a {\1 \2} a
 # 
 # In command (3) we separated all "words" based on "aB" but any ALLCAP 
 # word needs to be separated from the one that follows, i.e.
 # 
 #     reportABug   -> Report A Bug
 #     viewDVISig   -> View DVI Sig
 # 
 # (7)  regsub -all {([a-z])- ([A-Z])} $a {\1 - \2} a
 # 
 # At this point "input-Output" has been transformed to "Input- Output" so we
 # surround the hyphen with whitespace.  "input-output" will be transformed
 # to "Input-output".
 # 
 # (8)  regsub -all {:: ?} $a {-} a
 # 
 # The namespaces of Tcl procedures and variables are assumed to be prefixes
 # for the rest of the name (which has already been prettified.)
 # 
 # -------------------------------------------------------------------------
 ##

proc quote::Prettify {str} {
    if {![regexp {^.+,([^,]+)$} $str b a]} {
	regsub -all {^::} $str {} str
	set a [string toupper [string index $str 0]]
	regsub -all {([^A-Z])([A-Z])} [string range $str 1 end] {\1 \2} b
	regsub -all {((La|Bib|Oz|CMac) )?Te X} $a$b {\2TeX } a
	regsub -all {Alpha Tcl} $a {AlphaTcl} a
	regsub -all {([A-Z])([A-Z][a-z])} $a {\1 \2} a
	regsub -all {([a-z])- ([A-Z])} $a {\1 - \2} a
	regsub -all {:: ?} $a {-} a
    }
    return $a
}

proc quote::Menuify str {
    set a [string toupper [string index $str 0]]
    regsub -all { *([A-Z])} [string range $str 1 end] { \1} b
    append a $b
}
## 
 # -------------------------------------------------------------------------
 # 
 # "quote::WhitespaceReg" --
 # 
 #  Quote a string so you can search for it ignoring all problems with
 #  whitespace: all sequences of space/tab/cr are treated alike.
 # -------------------------------------------------------------------------
 ##
proc quote::WhitespaceReg { str } { 
    regsub -all "\[ \t\r\n\]+" $str {[ \t\r\n]+} str
    return $str
}

## 
 # -------------------------------------------------------------------------
 # 
 # "quote::AllNonAscii" --
 # 
 #  Take all non-pure-ascii characters (anything above 0x7f) and convert
 #  them into Tcl's \uxxxx sequences. 
 # -------------------------------------------------------------------------
 ##
proc quote::AllNonAscii {data} {
    regsub -all {\[} $data {[format %c 91]} data
    regsub -all {[\u0080-\uffff]} $data {[format \\\\u%04x [scan & %c]]} data
    return [subst -nobackslashes -novariables $data]
}
