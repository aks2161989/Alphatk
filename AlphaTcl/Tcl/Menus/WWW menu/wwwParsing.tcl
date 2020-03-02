## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # WWW Menu - an extension package for Alpha
 # 
 # FILE: "wwwParsing.tcl"
 #                                          created: 04/30/1997 {11:04:46 am}
 #                                      last update: 02/07/2006 {04:49:54 PM}
 # Description:
 #  
 # Procedures to parse HTML code for use in a rendering window.  
 # 
 # This is a potential candidate for the 'html' package in the Tcllib. 
 # None of this relies on additional procedures found in the AlphaTcl
 # library, and might be useful for other Tcl packages.  This is not
 # related in any way to 'htmlparsing.tcl', and no tests have been
 # performed to see how the two different methods for parsing html code
 # produce different results.
 # 
 # Passing a string to [html::parseHtml] will create a new global array
 # named "html::ParsingCache" which contains all of the information to
 # properly render an html file in a given window.  See the notes preceding
 # [html::parseHtml] for more information.
 # 
 # Some customization of how the parsing information will be cached is
 # available by setting "html::EntitiesToText" or "::WWWmodeVars" array
 # elements -- see the notes under 'Preliminaries' for more information.
 # 
 # Parsing works well for the HTML 4.0 Transitional ('loose') specification
 # although references to style sheets are completely ignored.
 #  
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 #     
 # Includes contributions from Craig Barton Upright
 # 
 #  E-mail: <cupright@alumni.princeton.edu>
 #     www: <http://www.purl.org/net/cbu/>
 # 
 # and Dominique d'Humières
 # 
 #  E-mail: <dominiq@physique.ens.fr>
 #     
 # -------------------------------------------------------------------
 #  
 # Copyright (c) 1997-2006 Vince Darley, Craig Barton Upright, Dominique d'Humières
 # 
 # Redistribution and use in source and binary forms, with or without
 # modification, are permitted provided that the following conditions are met:
 # 
 #  • Redistributions of source code must retain the above copyright
 #    notice, this list of conditions and the following disclaimer.
 # 
 #  • Redistributions in binary form must reproduce the above copyright
 #    notice, this list of conditions and the following disclaimer in the
 #    documentation and/or other materials provided with the distribution.
 # 
 #  • Neither the name of Alpha/Alphatk nor the names of its contributors may
 #    be used to endorse or promote products derived from this software
 #    without specific prior written permission.
 # 
 # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 # AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 # IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 # ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR
 # ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 # DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 # SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 # CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 # LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 # OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 # DAMAGE.
 # 
 # ==========================================================================
 ##

package require Tcl 8.4
package provide htmlToText 4.0

proc wwwParsing.tcl {} {}

# Make sure that 'status::msg' is defined.
namespace eval status {
    if {![llength [info commands msg]]} {;proc msg {args} {}} 
}

namespace eval html {
    
    variable EntitiesToText

    # =======================================================================
    #
    # ◊◊◊◊ Html Accent Elements ◊◊◊◊ #
    # 
    # These are converted in [html::wrapTextString]
    # 
    # Note that this was written on a Macintosh, so the normal 'MacRoman'
    # issues are present with the 14 problematic characters, specifically
    # 
    #   166 178 179 185 188 189 190 208 215 221 222 240 253 254
    # 
    # so there are initially question marks, or hacky substitutes.  Feel free
    # to fix this.
    # 
    # (See <http://htmlhelp.com/reference/html40/entities/latin1.html>)
    # 
    # There are a number of other chars for which we don't have any ready
    # symbols -- try rendering them in a 'real' browser to figure them out.
    # 
    # 63       "&#63;"         <BR>    
    # 138      "&#138;"        <BR>       
    # 154      "&#154;"        <BR>       
    # 164      "&#164;"        <BR>       
    # 166      "&#166;"        <BR>       
    # 173      "&#173;"        <BR>       
    # 178      "&#178;"        <BR>       
    # 179      "&#179;"        <BR>       
    # 185      "&#185;"        <BR>       
    # 188      "&#188;"        <BR>       
    # 189      "&#189;"        <BR>       
    # 190      "&#190;"        <BR>       
    # 208      "&#208;"        <BR>       
    # 215      "&#215;"        <BR>       
    # 221      "&#221;"        <BR>       
    # 222      "&#222;"        <BR>       
    # 240      "&#240;"        <BR>       
    # 253      "&#253;"        <BR>       
    # 254      "&#254;"        <BR>       
    # 8364     "&#8364;"       <BR>          
    # ETH      "&ETH;"         <BR>   
    # THORN    "&THORN;"       <BR>     
    # Yacute   "&Yacute;"      <BR>
    # brvbar   "&brvbar;"      <BR>
    # curren   "&curren;"      <BR>
    # eth      "&eth;"         <BR>   
    # frac12   "&frac12;"      <BR>
    # frac14   "&frac14;"      <BR>
    # frac34   "&frac34;"      <BR>
    # shy      "&shy;"         <BR>   
    # sup1     "&sup1;"        <BR>      
    # sup2     "&sup2;"        <BR>      
    # sup3     "&sup3;"        <BR>      
    # thorn    "&thorn;"       <BR>     
    # times    "&times;"       <BR>     
    # yacute   "&yacute;"      <BR>
    # xA4      "&#xA4;"        <BR>       
    # xA6      "&#xA6;"        <BR>       
    # xAD      "&#xAD;"        <BR>       
    # xB2      "&#xB2;"        <BR>       
    # xB3      "&#xB3;"        <BR>       
    # xB9      "&#xB9;"        <BR>       
    # xBC      "&#xBC;"        <BR>       
    # xBD      "&#xBD;"        <BR>       
    # xBE      "&#xBE;"        <BR>       
    # xD0      "&#xD0;"        <BR>       
    # xD7      "&#xD7;"        <BR>       
    # xDD      "&#xDD;"        <BR>       
    # xDE      "&#xDE;"        <BR>       
    # xF0      "&#xF0;"        <BR>       
    # xFD      "&#xFD;"        <BR>       
    # xFE      "&#xFE;"        <BR>       
    # 

    array set EntitiesToText {
	
	"#9"            {}
	"#10"           {
}
	"#13"           {
}
	"#32"           { }
	"#33"           {!}
	"#34"           "\""
	"#35"           "\#"
	"#36"           {$}
	"#37"           {%}
	"#38"           {&}
	"#39"           {'}
	
	"#40"           "\("
	"#41"           "\)"
	"#42"           {*}
	"#43"           {+}
	"#44"           {,}
	"#45"           {-}
	"#46"           {.}
	"#47"           {/}
	"#48"           {0}
	"#49"           {1}
	
	"#50"           {2}
	"#51"           {3}
	"#52"           {4}
	"#53"           {5}
	"#54"           {6}
	"#55"           {7}
	"#56"           {8}
	"#57"           {9}
	"#58"           {:}
	"#59"           {;}
	
	"#60"           {<}
	"#61"           {=}
	"#62"           {>}
	"#63"           {?}
	"#64"           {@}
	"#65"           {A}
	"#66"           {B}
	"#67"           {C}
	"#68"           {D}
	"#69"           {E}
	
	"#70"           {F}
	"#71"           {G}
	"#72"           {H}
	"#73"           {I}
	"#74"           {J}
	"#75"           {K}
	"#76"           {L}
	"#77"           {M}
	"#78"           {N}
	"#79"           {O}
	
	"#80"           {P}
	"#81"           {Q}
	"#82"           {R}
	"#83"           {S}
	"#84"           {T}
	"#85"           {U}
	"#86"           {V}
	"#87"           {W}
	"#88"           {X}
	"#89"           {Y}
	
	"#90"           {Z}
	"#91"           "\["
	"#92"           "\\"
	"#93"           "\]"
	"#94"           {^}
	"#95"           {_}
	"#96"           {`}
	"#97"           {a}
	"#98"           {b}
	"#99"           {c}
	
	"#100"          {d}
	"#101"          {e}
	"#102"          {f}
	"#103"          {g}
	"#104"          {h}
	"#105"          {i}
	"#106"          {j}
	"#107"          {k}
	"#108"          {l}
	"#109"          {m}
	
	"#110"          {n}
	"#111"          {o}
	"#112"          {p}
	"#113"          {q}
	"#114"          {r}
	"#115"          {s}
	"#116"          {t}
	"#117"          {u}
	"#118"          {v}
	"#119"          {w}
	
	"#120"          {x}
	"#121"          {y}
	"#122"          {z}
	"#123"          "\{"
	"#124"          {|}
	"#125"          "\}"
	"#126"          {~}
	"#127"          {}
	
	"#130"          {‚}
	"#131"          {ƒ}
	"#132"          {„}
	"#133"          {…}
	"#134"          {†}
	"#135"          {‡}
	"#136"          {ˆ}
	"#137"          {‰}
	"#138"          {Sˇ}
	"#139"          {‹}
	
	"#145"          {‘} 
	"#146"          {’} 
	"#147"          {“} 
	"#148"          {”} 
	"#149"          {•} 
	
	"#150"          {–} 
	"#151"          {—} 
	"#152"          {˜} 
	"#153"          {™} 
	"#154"          {sˇ} 
	"#155"          {›} 
	"#156"          {œ} 
	"#159"          {Ÿ}
	
	"#160"          { }
	"#161"          {¡}
	"#162"          {¢}         
	"#163"          {£}     
	"#164"          {?}
	"#165"          {¥}
	"#166"          {|}
	"#167"          {§}
	"#168"          {¨}
	"#169"          {©}
	
	"#170"          {ª}
	"#171"          {«}
	"#172"          {¬}
	"#173"          {-}
	"#174"          {®}
	"#175"          {¯}
	"#176"          {°}
	"#177"          {±}
	"#178"          {2}
	"#179"          {3}
	
	"#180"          {´}
	"#181"          {µ}
	"#182"          {¶}
	"#183"          {·}
	"#184"          {¸}
	"#186"          {º}
	"#187"          {»}
	"#188"          {1/4}
	"#189"          {1/2}
	
	"#190"          {3/4}
	"#191"          {¿}
	"#192"          {À}
	"#193"          {Á}
	"#194"          {Â}
	"#195"          {Ã}
	"#196"          {Ä}
	"#197"          {Å}
	"#198"          {Æ}
	"#199"          {Ç}
	
	"#200"          {È}
	"#201"          {É}
	"#202"          {Ê}
	"#203"          {Ë}
	"#204"          {Ì}
	"#205"          {Í}
	"#206"          {Î}
	"#207"          {Ï}
	"#208"          {D}
	"#209"          {Ñ}
	
	"#210"          {Ò}
	"#211"          {Ó}
	"#212"          {Ô}
	"#213"          {Õ}
	"#214"          {Ö}
	"#215"          {x}
	"#216"          {Ø}
	"#217"          {Ù}
	"#218"          {Ú}
	"#219"          {Û}
	
	"#220"          {Ü}
	"#221"          {Y}
	"#222"          {ﬂ}
	"#223"          {ß}
	"#224"          {à}
	"#225"          {á}
	"#226"          {â}
	"#227"          {ã}
	"#228"          {ä}
	"#229"          {å}
	
	"#230"          {æ}
	"#231"          {ç}
	"#232"          {è}
	"#233"          {é}
	"#234"          {ê}
	"#235"          {ë}
	"#236"          {ì}
	"#237"          {í}
	"#238"          {î}
	"#239"          {ï}
	
	"#240"          {d}
	"#241"          {ñ}
	"#242"          {ò}
	"#243"          {ó}
	"#244"          {ô}
	"#245"          {õ}
	"#246"          {ö}
	"#247"          {÷}
	"#248"          {ø}
	"#249"          {ù}
	
	"#250"          {ú}
	"#251"          {û}
	"#252"          {ü}
	"#253"          {y}
	"#253"          {ﬂ}
	"#255"          {ÿ}
	
	"#338"          {Œ}
	"#339"          {œ}
	"#376"          {Ÿ}
	"#402"          {ƒ}
	
	"#916"          {∆}
	"#928"          {∏}
	"#931"          {∑}
	"#937"          {?}
	"#956"          {µ}
	"#960"          {π}
	
	"#8211"         {–}
	"#8212"         {—}
	"#8216"         {‘}
	"#8217"         {’}
	"#8218"         {‚}
	"#8220"         {“}
	"#8221"         {”}
	"#8222"         {„}
	"#8224"         {†}
	"#8225"         {‡}
	"#8226"         {•}
	"#8230"         {…}
	"#8240"         {‰}
	"#8249"         {‹}
	"#8250"         {›}
	"#8364"         {?}
	"#8482"         {™}
	"#8730"         {√}
	"#8734"         {∞}
	"#8747"         {∫}
	"#8776"         {≈}
	"#8800"         {≠}
	"#8804"         {≤}
	"#8805"         {≥}
	
	"AElig"         {Æ}
	"Aacute"        {Á}
	"Acirc"         {Â}
	"Agrave"        {À}
	"Aring"         {Å}
	"Atilde"        {Ã}
	"Auml"          {Ä}
	"Ccedil"        {Ç}
	"ETH"           {D}
	"Eacute"        {É}
	"Ecirc"         {Ê}
	"Egrave"        {È}
	"Euml"          {Ë}
	"Iacute"        {Í}
	"Icirc"         {Î}
	"Igrave"        {Ì}
	"Iuml"          {Ï}
	"Ntilde"        {Ñ}
	"Oacute"        {Ó}
	"Ocirc"         {Ô}
	"Ograve"        {Ò}
	"Oslash"        {Ø}
	"Otilde"        {Õ}
	"Ouml"          {Ö}
	"THORN"         {ﬂ}
	"Uacute"        {Ú}
	"Ucirc"         {Û}
	"Ugrave"        {Ù}
	"Uuml"          {Ü}
	"Yacute"        {y}
	
	"aacute"        {á}
	"acirc"         {â}
	"acute"         {´}
	"aelig"         {æ}
	"agrave"        {à}
	"aring"         {å}
	"atilde"        {ã}
	"auml"          {ä}
	"brvbar"        {|}
	"ccedil"        {ç}
	"cedil"         {¸}
	"cent"          {¢}
	"copy"          {©}
	"curren"        {?}
	"deg"           {°}
	"divide"        {÷}
	"eacute"        {é}
	"ecirc"         {ê}
	"egrave"        {è}
	"eth"           {d}
	"euml"          {ë}
	"frac12"        {1/2}
	"frac14"        {1/4}
	"frac34"        {3/4}
	"gt"            {>}
	"iacute"        {í}
	"icirc"         {î}
	"ldquo"         {”}
	"iexcl"         {¡}
	"igrave"        {ì}
	"iquest"        {¿}
	"lsquo"         {‘}
	"iuml"          {ï}
	"laquo"         {«}
	"lt"            {<}
	"macr"          {¯}
	"micro"         {µ}
	"middot"        {·}
	"nbsp"          { }
	"not"           {¬}
	"mdash"         {—}
	"ndash"         {–}
	"ntilde"        {ñ}
	"oacute"        {ó}
	"ocirc"         {ô}
	"ograve"        {ò}
	"ordf"          {ª}
	"ordm"          {º}
	"oslash"        {ø}
	"otilde"        {õ}
	"ouml"          {ö}
	"para"          {¶}
	"plusmn"        {±}
	"pound"         {£}
	"quot"          {"}
	"raquo"         {»}
	"rdquo"         {“}
	"reg"           {®}
	"rsquo"         {’}
	"sect"          {§}
	"shy"           {-}
	"sup1"          {1}
	"sup2"          {2}
	"sup3"          {3}
	"szlig"         {ß}
	"thorn"         {ﬁ}
	"times"         {x}
	"uacute"        {ú}
	"ucirc"         {û}
	"ugrave"        {ù}
	"uml"           {¨}
	"uuml"          {ü}
	"yacute"        {y}
	"yen"           {¥}
	"yuml"          {ÿ}
	
	"#xA0"          { }
	"#xA1"          {¡}
	"#xA2"          {¢}
	"#xA3"          {£}
	"#xA4"          {?}
	"#xA5"          {¥}
	"#xA6"          {|}
	"#xA7"          {§}
	"#xA8"          {¨}
	"#xA9"          {©}
	"#xAA"          {ª}
	"#xAB"          {«}
	"#xAC"          {¬}
	"#xAD"          {-}
	"#xAE"          {®}
	"#xAF"          {¯}
	
	"#xB0"          {°}
	"#xB1"          {±}
	"#xB2"          {2}
	"#xB3"          {3}
	"#xB4"          {´}
	"#xB5"          {µ}
	"#xB6"          {¶}
	"#xB7"          {·}
	"#xB8"          {¸}
	"#xB9"          {1}
	"#xBA"          {º}
	"#xBB"          {»}
	"#xBC"          {1/4}
	"#xBD"          {1/2}
	"#xBE"          {3/4}
	"#xBF"          {¿}
	
	"#xC0"          {À}
	"#xC1"          {Á}
	"#xC2"          {Â}
	"#xC3"          {Ã}
	"#xC4"          {Ä}
	"#xC5"          {Å}
	"#xC6"          {Æ}
	"#xC7"          {Ç}
	"#xC8"          {È}
	"#xC9"          {É}
	"#xCA"          {Ê}
	"#xCB"          {Ë}
	"#xCC"          {Ì}
	"#xCD"          {Í}
	"#xCE"          {Î}
	"#xCF"          {Ï}
	
	"#xD0"          {D}
	"#xD1"          {Ñ}
	"#xD2"          {Ò}
	"#xD3"          {Ó}
	"#xD4"          {Ô}
	"#xD5"          {Õ}
	"#xD6"          {Ö}
	"#xD7"          {x}
	"#xD8"          {Ø}
	"#xD9"          {Ù}
	"#xDA"          {Ú}
	"#xDB"          {Û}
	"#xDC"          {Ü}
	"#xDD"          {Y}
	"#xDE"          {ﬂ}
	"#xDF"          {ß}
	
	"#xE0"          {à}
	"#xE1"          {á}
	"#xE2"          {â}
	"#xE3"          {ã}
	"#xE4"          {ä}
	"#xE5"          {å}
	"#xE6"          {æ}
	"#xE7"          {ç}
	"#xE8"          {è}
	"#xE9"          {é}
	"#xEA"          {ê}
	"#xEB"          {ë}
	"#xEC"          {ì}
	"#xED"          {í}
	"#xEE"          {î}
	"#xEF"          {ï}
	
	"#xF0"          {d}
	"#xF1"          {ñ}
	"#xF2"          {ò}
	"#xF3"          {ó}
	"#xF4"          {ô}
	"#xF5"          {õ}
	"#xF6"          {ö}
	"#xF7"          {÷}
	"#xF8"          {ø}
	"#xF9"          {ù}
	"#xFA"          {ú}
	"#xFB"          {û}
	"#xFC"          {ü}
	"#xFD"          {y}
	"#xFE"          {ﬁ}
	"#xFF"          {ÿ}
    }
    
    # Make sure that these array elements exist.  
    # 
    # These might be previously defined, depending on the code that this
    # calling these procedures.  Code outside of AlphaTcl can define anything
    # in this section as desired before [html::parseHtml] is called.  These
    # not only affects how items are recorded in the cache, but all of 'bold'
    # 'outline' and 'shadow' will affect wrapping indentation, reducing the
    # number of characters allowed in a line that include those style
    # markers.
    foreach item [list ignoreForms ignoreImages] {
	if {![info exists ::WWWmodeVars($item)]} {
	    switch $item {
		"ignoreForms"  {set ::WWWmodeVars($item) 0}
		"ignoreImages" {set ::WWWmodeVars($item) 0}
	    }
	}
    }
    foreach item [list 1 2 3] {
	if {![info exists ::WWWmodeVars(header${item}Style)]} {
	    set ::WWWmodeVars(header${item}Style) underline
	} 
	if {![info exists ::WWWmodeVars(header${item}Color)]} {
	    set ::WWWmodeVars(header${item}Color) red
	} 
    }

    variable HtmlToStyle
    foreach item [list "B" "BIG" "CITE" "DFN" "EM" "I" "SMALL" \
      "STRONG" "U" "VAR"] {
	if {![info exists HtmlToStyle($item)]} {
	    switch $item {
		"CITE"      {set HtmlToStyle($item) italic}
		"CODE"      {set HtmlToStyle($item) normal}
		"KBD"       {set HtmlToStyle($item) normal}
		"SAMP"      {set HtmlToStyle($item) normal}
		"TT"        {set HtmlToStyle($item) normal}
		"U"         {set HtmlToStyle($item) underline}
		default     {set HtmlToStyle($item) blue}
	    }
	} 
    }
    # This number is incremented with each form encountered.
    variable ParsingFormNumber
    if {![info exists ParsingFormNumber)]} {
	set ParsingFormNumber 0
    } 
}

# ===========================================================================
# 
# ◊◊◊◊ ---- ◊◊◊◊ #
# 
# ◊◊◊◊ Preliminaries ◊◊◊◊ #
# 

## 
 # -------------------------------------------------------------------------
 # 
 # "html::resetCache"  --
 # 
 # All variables required for parsing are stored in the "html::ParsingCache"
 # array.  Any previous values are cleared when a new string is parsed.
 # 
 # -------------------------------------------------------------------------
 ##

proc html::resetCache {} {
    
    variable ParsingCache
    variable ParsingFormNumber
    
    unset -nocomplain ParsingCache

    foreach item [list BaseTarget BaseUrl Indent Text Title] {
	set ParsingCache($item) ""
    }
    foreach item [list Anchors Colors Links Marks Forms] {
	set ParsingCache($item) [list]
    }
    foreach item [list Ext Indentation Length Pre Quote InTable InTableCell] {
	set ParsingCache($item) 0
    }
    foreach item [list InForm FormFieldNumber] {
	set ParsingCache($item) 0
    }
    foreach item [list Wrap] {
	set ParsingCache($item) 1
    }
    # Styles, Colors.
    foreach num  [list 1 2 3] {
	set ParsingCache(Header${num}Color) $::WWWmodeVars(header${num}Color)
	set ParsingCache(Header${num}Style) $::WWWmodeVars(header${num}Style)
    }
    # Images, Forms.
    set ParsingCache(IgnoreImages) $::WWWmodeVars(ignoreImages)
    set ParsingCache(IgnoreForms)  $::WWWmodeVars(ignoreForms)
    set ParsingCache(FormNumber)   [set ParsingFormNumber]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "html::removeCrap" --
 #  
 # Get rid of all of the stuff that we know that we can't deal with to make
 # the parsing go a little bit faster.
 #  
 # Feel free to add to this list, or find a way to deal with them !!
 # 
 # -------------------------------------------------------------------------
 ##

proc html::removeCrap {tt} {
    
    variable ParsingCache

    upvar $tt t

    # Get rid of all scripts and comments.
    substituteForTags {<!--}     {-->}       t
    substituteForTags {<COMMENT} {/COMMENT>} t
    substituteForTags {<SCRIPT}  {/SCRIPT>}  t
    substituteForTags {<STYLE}   {/STYLE>}   t
    # Get rid of the title, in case this page wasn't very well formed and
    # didn't have a proper body.
    substituteForTags {<TITLE}   {/TITLE>}   t

    # Get rid of other stuff that we know we can't handle, but ignore.
    regsub -nocase -all -- {<IMG[ \t\r\n]+SRC[ \t\r\n]*=[ \t\r\n]*\"[^\"]*bullet.gif\"[^>]*>} $t {•} t
#   regsub -nocase -all -- "\[ \t\r\n\]+alt=\"(\[^\"\]*)\"\[^>\]*>" $t ">\\1<TD></A>" t
    regsub -nocase -all {<META[^>]*>}       $t {}  t
    regsub -nocase -all {</?DIV[^>]*>}      $t {}  t
    regsub -nocase -all {</?FONT[^>]*>}     $t {}  t
    regsub -nocase -all {</?SPAN[^>]*>}     $t {}  t
    regsub -nocase -all {</?VAR>}           $t {}  t
    # Many web pages (ab)use empty table elements to visually format text. 
    # Since we don't pay attention to them, we'll get rid of them.
    regsub -nocase -all {<TD[^>]*></TD>}    $t {}  t
    # I've seen this construction used before (esp in TIP web pages),
    # which makes list items separate paragraphs.
    regsub -nocase -all {(<LI[^>]*>)(<P[^>]*>)} $t {\2\1} t
    regsub -nocase -all {(<DD[^>]*>)(<P[^>]*>)} $t {\2\1} t
    # Addresses will simply be in italics on a separate line.
    regsub -nocase -all {<ADDRESS>}      $t {<P><I>}      t
    regsub -nocase -all {</ADDRESS>}     $t {</I><P>}     t
    
    # How does the user want to handle forms?
    if {$ParsingCache(IgnoreForms)} {
	substituteForTags {<FORM} {/FORM>}     t
	substituteForTags {<SELECT} {/SELECT>} t
    }
    # If any images that are really hyperlinks, we'll render them as such,
    # in which case the user won't even know that an image was supposed to
    # be there.  The first pattern captures images embedded in links that
    # have other text (in which case we ignore the image altogether), the
    # second captures images embedded in links with no extra text but an
    # 'alt' attribute.  (Probably should have a third case for when the
    # 'alt' attribute that isn't in quotes ...)  Images that aren't really
    # hyperlinks will be dealt with below.
    set pat1 {(<A[^>]HREF[^>]+>)\s*<IMG[^>]*>(\s*[^\s]+.*)(</A>)}
    set pat2 {(<A[^>]HREF[^>]+>)\s*<IMG[^>]*alt[\s=]+("|')([^"']+)("|')[^>]*>\s*(</A>)}
    regsub -nocase -all -- $pat1 $t {\1\2\3 } t
    regsub -nocase -all -- $pat2 $t {\1\3\5 } t
    # This may significantly reduce the length of the string, which doesn't
    # make parsing any faster but might reduce the memory required.
    if {![regexp -nocase {<PRE[^>]*>} $t]} {
	regsub -all {\s+} $t " " t
    } 
    set ParsingCache(UncrappedT) $t
}

## 
 # -------------------------------------------------------------------------
 # 
 # "html::substituteForTags" --
 #  
 # Substitute for tags that aren't properly supported, possibly by doing some
 # sneaky substition for a tag that we can actually handle, or some info for
 # the user to know what might have been there.
 #  
 # -------------------------------------------------------------------------
 ##

proc html::substituteForTags {openTag closeTag _t {substitute ""}} {
    
    upvar $_t t

    set opentag  [string tolower $openTag]
    set OPENTAG  [string toupper $openTag]
    set closetag [string tolower $closeTag]
    set CLOSETAG [string toupper $closeTag]
    foreach tag [list $opentag $OPENTAG] {
	while {[set index0 [string first $tag $t]] != -1} {
	    set tagend [string first $closetag $t]
	    set TAGEND [string first $CLOSETAG $t]
	    if {$tagend < $index0} {set tagend "-1"} 
	    if {$TAGEND < $index0} {set TAGEND "-1"} 
	    if {$tagend == "-1" && $TAGEND == "-1"} {
		#alertnote "Unbalanced '$tag' tag"
		break
	    } elseif {$tagend != "-1" && $TAGEND != "-1"} {
		set index1 [expr {$tagend > $TAGEND} ? $TAGEND : $tagend]
	    } elseif {$tagend == "-1"} {
		set index1 $TAGEND
	    } else {
		set index1 $tagend
	    }
	    set index0 [expr $index0 - 1]
	    set index1 [expr $index1 + [string length $closeTag]]
	    set t0     [string range $t 0 $index0]
	    set t1     [string range $t $index1 end]
	    set t      ${t0}${substitute}${t1}
	}
    } 
}

# ===========================================================================
# 
# ◊◊◊◊ ---- ◊◊◊◊ #
# 
# ◊◊◊◊ Parsing ◊◊◊◊ #
# 

## 
 # -------------------------------------------------------------------------
 # 
 # "html::parseHtml" --
 #  
 # Given a string of text 't', which is most likely the entire contents of an
 # .html file, parse it taking into consideration a maximum length for
 # visually filling columns and any possible 'carriageReturn' string.  The
 # result is a text string of the rendered html code.
 # 
 # During this proc, a global array named "html::ParsingCache" is created,
 # which will contain several different elements that can be used to further
 # enhance the rendered text:
 # 
 #   Anchors --
 #   
 #     A list of lists.  Each list contains the name of each anchor
 #     declared in the code, plus the string index position indicating
 #     where in the master 'Text' string this heading occurs.
 #     
 #   BaseUrl -- 
 #   
 #     The base url of this document given by <BASE HREF="...">.  If no
 #     base url is found, this element is the null string.
 #   
 #   BaseTarget -- 
 #   
 #     The target of links in this document given by <BASE TARGET="...">. 
 #     If no base target is found, this element is the null string.
 #   
 #   Colors --
 #   
 #     A list of lists.  Each list contains the starting and ending string
 #     index positions in the 'Text' string of the text to be colored, plus
 #     the color to be used for coloring.  This does not include hyperlinks.
 #     
 #   Forms --
 #   
 #     A list of lists.  Each list element contains
 #     
 #     (0) FORM-${formNumber}-FIELD-${fieldNumber}-[string toupper $formItemType]
 #     
 #         "formNumber" is incremented with each new <FORM> tag.
 #         "fieldNumber" is reset to "1" with each new <FORM> tag, and
 #           is incremented as various form input items are added.
 #         "formItemType" is the tag which prompted inclusion of the item.
 #           (The initial <FORM> will have a type named "FORMATTS" 
 #           indicating that the attributes are for the FORM tag.
 #           
 #     (1) The attributes found for "formItemType", i.e.
 #     
 #           {input name="submit" value="Search"}
 #           
 #     (2) The starting position for any text cached for this item.
 #     
 #     (3) The ending position for any text cached for this item.
 #     
 #     (4) Any extra information that might be necessary to properly
 #           execute this item.  For example, the "SELECT" tag will
 #           include all text found between the opening and closing tags.
 #           This last element is actually a list, so that items can
 #           add multiple pieces of information if necessary, all of
 #           which can be accessed via a lindex command.
 #           
 #     Various tags, such as "BUTTON" "SELECT" "TEXTAREA" will all trigger
 #     additions to the form cache, as well as "FORM" and "INPUT".
 #           
 #     If the "::WWWmodeVars(IgnoreForms)" variable is set to 1, then this
 #     list will be empty.
 #     
 #   Length --
 #   
 #     The length of the final string found in the 'Text' element.
 #     
 #   Links --
 #   
 #     A list of lists.  Each list contains the starting and ending string
 #     index positions for the hyperlink text, the link specified by HREF,
 #     and any potential target identified in the html link code.  One
 #     exception is a link created by '<ISINDEX>', in which case the link
 #     is named 'performIndexSearch'.
 #     
 #     Relative links have not been converted in any way to reflect either
 #     the location of the original file nor any potential 'BaseUrl'
 #     element; it's up to the calling code to decide what to do with this
 #     link info.
 #     
 #   Marks --
 #   
 #     A list of lists.  Each list contains heading level, the string
 #     contained in the heading, plus the string index starting and ending
 #     positions indicating where in the master 'Text' string this heading
 #     occurs.  (Ending position of the heading might be longer than simply
 #     the start plus the length to compensate for links contained within
 #     the heading -- in order to properly colorize them, a space is
 #     included around the hyperlinks.)
 #   
 #   Select -- 
 #   
 #     A list of lists.  Each list contains the attributes for the "SELECT"
 #     tag, and then any code found between the open and closing "SELECT"
 #     tags.  If forms are not ignored and the "SELECT" tag is encountered
 #     nested in a "FORM" tag, then this list is included in the "Forms"
 #     parsing cache rather than "Select".
 #   
 #   Text -- 
 #   
 #     The new string of text that contains a visual representation of all
 #     of the code in the file, nicely formatted for insertion into a
 #     window of choice.
 #     
 #   Title --
 #   
 #     The title of this document given by <TITLE>...<TITLE>.  All style
 #     elements are converted, and leading/trailing whitespace is trimmed.
 #     If no title is found, this element is the null string.
 # 
 # Each of these array elements is created, though they might be empty. 
 # Additional items found in this array are used internally during the
 # parsing routine to ensure that indentation is properly adjusted, and will
 # reflect the last values used.  This info will most likely be of no value,
 # see the procs below to find out how it is used during parsing.
 #     
 # This "html::ParsingCache" array is cleared each time this proc is called,
 # so be sure to retrieve any info needed before passing on another string to
 # be parsed.
 # 
 # Colors can be customized by setting some '::WWWmodeVars' array elements,
 # as well as "html::HtmlToStyle" array elements -- see the 'Preliminaries'
 # section below for more information.  No colors are specified here for
 # hyperlinks.
 #     
 # -------------------------------------------------------------------------
 ##

proc html::parseHtml {t {fillLength "78"} {carriageReturn "\r"}} {

    variable EntitiesToText
    variable ParsingCache
    variable ParsingFormNumber

    resetCache
    removeCrap t

    # Cache the string for carriage returns.
    set ParsingCache(CR) $carriageReturn
    # Make sure that we're dealing with the right carriage return
    set EntitiesToText(\#10) $ParsingCache(CR)
    set EntitiesToText(\#13) $ParsingCache(CR)
    # Cache the initial default fill column length.
    set ParsingCache(FillColumn) $fillLength
    # Create the string for horizontal lines.
    set ParsingCache(HR) "   [string repeat "_" [expr {$fillLength - 10}]]"

    # Find the title of the page.
    set title ""
    if {[regexp -nocase {<TITLE[^>]*>(.*)</TITLE>} $t dummy title]} {
	convertEntities title
    }
    set ParsingCache(Title) [string trim $title]
    # Find any base url, target for this page.
    set base   ""
    set target ""
    if {[regexp -nocase {<(BASE[^>]+)>} $t dummy base]} {
	getAttributes $base "baseArray" 1 HREF TARGET
	convertEntities baseArray(HREF)
	set base   $baseArray(HREF)
	set target $baseArray(TARGET)
    }
    set ParsingCache(BaseUrl)    $base
    set ParsingCache(BaseTarget) $target
    # Parse the body of the html code.
    regexp -nocase {<HTML[^>]*>(.*)</HTML>} $t dummy t
    regexp -nocase {<BODY[^>]*>(.*)</BODY>} $t dummy t
    parseBody [string trim $t]
    set ParsingFormNumber $ParsingCache(FormNumber)
    set ParsingCache(Text)
}

## 
 # -------------------------------------------------------------------------
 # 
 # "html::parseBody" "html::parseSegment" --
 #  
 # This is the real workhorse here.  Go through the string 't', and whenever
 # an html tag is found do some fancy footwork to properly register items in
 # the various caches that can be used later to properly render the page in
 # the window.  Each item in the switch should be reducing the length of the
 # original string, or making substitutions so that other tags will be
 # rendered.  Removing as many unnecessary tags before the string is passed
 # to this proc will make it all go quicker.  
 # 
 # Bad html code (i.e. missing required closing tags) will slow this down. 
 # One challenge here is dealing with all of the exceptions that lazy
 # programmers employ to omit 'required' closing tags.  For example, most
 # browsers will consider the end of a table cell to also signal the end of
 # any font or style tags, such as <B> <FONT> etc.  In fact, often the
 # closing tag for the table cell itself is missing, and presumed when
 # another cell or row starts, or the table itself is ending.  Big bother.
 # A lot of the work below is merely compensation for this type of code.
 # 
 # (One possible different approach to all of this, then, might be to simply
 # turn some style elements on when the open tag is encountered, and then
 # turn it or all style tags off at appropriate junctures.  This would
 # require a significant change to how [html::colourText] is employed below.)
 # 
 # While the original string is being parsed, the cached string can be
 # queried to determine if it ends with an empty line, etc.  'Positions' are
 # recorded according to the current length of the cached text, and can be
 # properly converted once the parsed text has been inserted into the window.
 # 
 # During the parsing, we divide the text into manageable chunks.  The idea
 # here is that if the regexp fails on a string, we add the next chunk and
 # try the regexp again -- this will happen quite a bit when the segment is
 # cutting off a tag.  Do to the magic in [html::wrapTextString], any words
 # that are cut off midstream will be joined again.
 # 
 # What is the 'ideal' size for a string to be passed through all of these
 # 'regexp' commands?  In Alpha7, it doesn't seem to matter for speed but
 # longer strings can lead to memory problems.  In Alpha8/tk, we don't seem
 # to run into any issues unless the string is longer than 5000, although 500
 # seems to maximize the speed of rendering.  Dividing the master string in
 # this manner reduces the parsing speed of the first frameset page of the
 # 'Internet Explorer Help' file from 26.2 to 6.3 seconds !!
 # 
 # We only give a new message in the message bar if the percentage of text
 # already parsed has actually changed.  This might seem like a trivial check
 # to perform, but if we just put the message in with every iteration we
 # increase rendering time in Alpha8 by up to 50%.  Seriously.  This way we
 # only increase rendering time by 0.2 seconds, regardless of the size of the
 # string being parsed, because we make a call to 'status::msg' at most 100
 # times.  The message is rather important because if parsing is taking a
 # very long time you want to know if it is still working, or frozen. 
 # Performing this check further reduces the parsing time for the 'Internet
 # Explorer Help' file to 4.1 seconds (and with other fixes down to 2.9) !!
 # 
 # -------------------------------------------------------------------------
 ##

proc html::parseBody {t} {

    variable HtmlToStyle
    variable ParsingCache

    set title $ParsingCache(Title)
    set CR    $ParsingCache(CR)
    set len1  [string length $t]
    set len2  [string length $t]
    set marks [list]
    # The initial percentage figure.
    set pct   0
    # The string length of segments that we evaluate. 
    set ideal 500
    # Divide the initial string into manageable segments.
    while {[string length $t] > $ideal} {
	lappend segments [string range $t 0 [expr {$ideal - 1}]]
	set t [string range $t $ideal end]
    }
    lappend segments $t ; set t ""
    # Create a "top" anchor.
    cacheItem Anchors "top" 0
    # Now recursively parse each segment, appending the next as necessary.
    set tagPattern "^(\[^<\]*(?:<\[<>\]\[^<\]*)*)<(\[^<>\]\[^>\]*)>(.*)\$"
    while {[llength $segments]} {
	append t [lindex $segments 0]
	set segments [lrange $segments 1 end]
	while {[regexp -- $tagPattern $t -> first html t]} {
	    set pct1 [expr (100 * ($len2 - $len1)) / $len2]
	    if {$pct != $pct1} {status::msg "Rendering -- [set pct $pct1] %"}
	    wrapTextString $first
	    regsub -all {[][\$?^|*+()\.\{\}\\]} $html {\\&} qHtml
	    switch -regexp -- [string toupper $qHtml] {
		{^A\s+} {
		    # If this is only a NAME, we might not find a closing tag.
		    set pat {A\s+NAME\s*=[^=]+\s*$}
		    if {[regexp -nocase $pat $html]} {
			getAttributes $html aArray 1 NAME
			if {[string length $aArray(NAME)]} {
			    cacheItem Anchors $aArray(NAME) $ParsingCache(Length)
			}
			continue
		    } 
		    # Find the string that will be hyperlinked.  If we can't
		    # find it, we're probably at the end of a string that was
		    # cut off and need to add some more.
		    if {[catch {findClosingTag "/A" t txt A H\[0-9\] TR TD TABLE /TR /TD /TABLE}]} {
			set t <${html}>${t}
			break
		    }
		    getAttributes $html "aArray" 0 HREF TARGET NAME
		    if {![info exists aArray(HREF)] && ![info exists aArray(NAME)]} {
			# At the moment, these are the only two attributes
			# that we actually handle.
			set t ${txt}${t}
			break
		    } 
		    # Any anchor?
		    if {[info exists aArray(NAME)]} {
			cacheItem Anchors $aArray(NAME) $ParsingCache(Length)
		    }
		    # Cache any href link.
		    if {[info exists aArray(HREF)]} {
			convertEntities aArray(HREF)
			# The only tags we pay attention to here are breaks.
			regsub -all -nocase {<BR[^>]*>} $txt "\\&#13;" txt
			regsub -all -nocase {<P[^>]*>}  $txt "\\&#13;\\&#13;" txt
			regsub -all         {<[^>]*>}   $txt ""               txt
			regsub -all "(\&nbsp\;)+" $txt " " txt
			regsub -all "\[\t \]+"    $txt " " txt
			if {![info exists aArray(TARGET)]} {set aArray(TARGET) ""}
			linkText $txt $aArray(HREF) $aArray(TARGET)
		    } elseif {[string length $txt]} {
			set t ${txt}${t}
		    }
		}
		{^APPLET} {
		    set html [lindex [join $html] 0]
		    if {[catch {findClosingTag "/APPLET" t txt}]} {
			set t <${html}>${t}
			break
		    }
		    getAttributes $html appletArray 1 CODE
		    if {[regsub {\.class} $appletArray(CODE) " " class]} {
			set class ""
		    }
		    set link "\"${class}.java\""
		    linkText "Run java ${class} applet" $link
		}
		{^AREA} {
		    # Need to look at this one closer.
		    getAttributes $html areaArray 1 HREF TARGET ALT
		    set pat {\s+TARGET\s*=\s*"[^"]*"}
		    regsub -nocase -all $pat $html {} link
		    set link [string range $link [expr 1 + [string last "=" $link]] end]
		    if {![regexp -nocase {^([^<]*)(<TD>)?</A>(.*)$} $t "" txt td t]} {
			continue
		    }
		    set pad ""
		    if {[string length $txt] == 0} {
			set txt [file rootname [string trim $link "\""]]
			set pad ${CR}${CR}
		    } elseif {$td == "<TD>"} {
			set pad $CR
		    }
		    linkText $txt "html::link $link" $link
		    cacheText $pad
		}
		{^BR\s?} {
		    ensureBreak
		    set t [string trimleft $t]
		}
		{^(B|BIG|CITE|DFN|EM|I|SMALL|STRONG|U|VAR)$} {
		    set pat1 "^\[^>\]*>\[^<\]*<\[^>\]*>"
		    set pat2 "^(\[^<\]*)</$html>(.*)\$"
		    if {![regexp -nocase $pat1 $t]} {
			set t <${html}>${t}
			break
		    } elseif {[regexp -nocase $pat2 $t "" txt t]} {
			colourText $txt $HtmlToStyle([string toupper $html])
		    }
		}
		{^BLOCKQUOTE} {
		    ensureEmptyLine
		    adjustFillColumn -3
		    adjustIndent      3
		}
		{^/BLOCKQUOTE} {
		    ensureEmptyLine
		    adjustFillColumn  3
		    adjustIndent     -3
		}
		{^BUTTON} {
		    if {[catch {findClosingTag "/BUTTON" t buttonString}]} {
			set t <${html}>${t}
			break
		    }
		    # This isn't standard html, but it's a handy
		    # way to remember the button label.
		    append html " button=\"$buttonString\""
		    cacheForm Button $html $buttonString
		    ensureSpace
		}
		{^DD} {
		    ensureBreak
		    if {![info exists ParsingCache(DDIndent)]} {
			set ParsingCache(DDIndent) 1
			adjustIndent 3
		    } 
		}
		{^/DD} {
		    ensureBreak
		    if {[info exists ParsingCache(DDIndent)]} {
			unset ParsingCache(DDIndent)
			adjustIndent -3
		    } 
		}
		{^DL} {
		    ensureEmptyLine
		}
		{^/DL} {
		    ensureEmptyLine
		    if {[info exists ParsingCache(DDIndent)]} {
			unset ParsingCache(DDIndent)
			adjustIndent -3
		    } 
		}
		{^DT} {
		    ensureBreak
		    if {[info exists ParsingCache(DDIndent)]} {
			unset ParsingCache(DDIndent)
			adjustIndent -3
		    } 
		}
		{^/DT} {
		    ensureBreak
		}
		{^EMBED\s+} {
		    set pat {src *= *"([^"]+)"}
		    if {[regexp -nocase $pat $html dummy embed]} {
			set txt "???"
			regexp {[^/:]+$} $embed txt
			linkText "Embedded '$txt'." "html::link $embed" $embed
		    }
		}
		{^FORM} {
		    # Set form counters.
		    incr ParsingCache(FormNumber)
		    set  ParsingCache(FormFieldNumber) 0
		    # Some tags should be cached differently if we're in the
		    # middle of a form.
		    set  ParsingCache(InForm) 1
		    # Cache the start of the form, and the form attributes.
		    cacheForm FormAtts $html
		    ensureEmptyLine
		}
		{^/FORM} {
		    set  ParsingCache(InForm) 0
		    ensureEmptyLine
		}
		{^HR} {
		    ensureEmptyLine
		    cacheText $ParsingCache(HR)${CR}${CR}
		}			
		{^H[1-6]+} {
		    regexp -nocase "^H(\[0-9]+)" $html dummy hNum
		    if {[catch {findClosingTag "/H${hNum}" t hString}]} {
			set t <${html}>${t}
			break
		    }
		    ensureEmptyLine
		    set hNum [expr {$hNum > 2} ? 3 : $hNum]
		    # Get the initial heading string.
		    set pos0 $ParsingCache(Length)
		    regsub -all {<[^>]*>} $hString "" hTxt
		    convertEntities hTxt
		    set hTxt [string trim $hTxt]
		    # Treat this as a normal text string, but instead of just
		    # wrapping, we color and wrap any 'plain' text.
		    while {[regexp -- $tagPattern $hString -> first html hString]} {
			colourText $first \
			  $ParsingCache(Header${hNum}Color) \
			  $ParsingCache(Header${hNum}Style)
			regsub -all {[][\$?^|*+()\.\{\}\\]} $html {\\&} qHtml
			switch -regexp [string toupper $qHtml] {
			    {^A\s+} {
				# If this is only a NAME, we might not find a closing tag.
				set pat {A\s+NAME\s*=[^=]+}
				if {[regexp -nocase $pat $html]} {
				    getAttributes $html aArray 1 NAME
				    if {[string length $aArray(NAME)]} {
					cacheItem Anchors $aArray(NAME) \
					  $ParsingCache(Length)
				    }
				    continue
				} 
				# Find the string that will be hyperlinked. 
				# If we can't find it, we'll ignore the tag.
				if {[catch {findClosingTag "/A" hString txt A H\[0-9\] TR TD TABLE /TR /TD /TABLE}]} {
				    continue
				}
				getAttributes $html "aArray" 0 HREF TARGET NAME
				if {![info exists aArray(HREF)] && ![info exists aArray(NAME)]} {
				    # These are the only two attributes that
				    # we actually handle.
				    set hString ${txt}${hString}
				    continue
				} 
				# Any anchor?
				if {[info exists aArray(NAME)]} {
				    cacheItem Anchors $aArray(NAME) $ParsingCache(Length)
				}
				# Cache any href link.
				if {[info exists aArray(HREF)]} {
				    convertEntities aArray(HREF)
				    # The only tags we pay attention to here
				    # are breaks.
				    regsub -all -nocase {<BR[^>]*>} $txt "\\&#13;" txt
				    regsub -all -nocase {<P[^>]*>}  $txt "\\&#13;\\&#13;" txt
				    regsub -all         {<[^>]*>}   $txt ""               txt
				    regsub -all "(\&nbsp\;)+" $txt " " txt
				    regsub -all "\[\t \]+"    $txt " " txt
				    if {![info exists aArray(TARGET)]} {set aArray(TARGET) ""}
				    ensureSpace
				    linkText $txt $aArray(HREF) $aArray(TARGET)
				    ensureSpace
				} elseif {[string length $txt]} {
				    set hString ${txt}${hString}
				}
			    }
			    {^BR\s?} {
				ensureBreak
				set hString [string trimleft $hString]
			    }
			    {^P} {
				ensureEmptyLine
				set ParsingCache(Wrap) 1
				set hString [string trimleft $hString]
			    }
			    {^/P} {
				ensureEmptyLine
			    }
			    {^/.*} {
			    }
			    default {
				set pat "^(\[^<\]*)</$qHtml>(.*)\$"
				if {[regexp -nocase $pat $hString dummy txt hString]} {
				    colourText $txt \
				      $ParsingCache(Header${hNum}Color) \
				      $ParsingCache(Header${hNum}Style)
				}
			    }
			}
		    }
		    # Be sure to color, wrap any remaining text string.
		    colourText $hString \
		      $ParsingCache(Header${hNum}Color) \
		      $ParsingCache(Header${hNum}Style)
		    # Record the mark
		    set pos1 $ParsingCache(Length)
		    while {[lsearch $marks $hTxt] >= 0} {append hTxt " "}
		    lappend marks $hTxt
		    cacheItem Marks $hNum $hTxt $pos0 $pos1
		    ensureEmptyLine
		}
		{^IMG} {
		    getAttributes $html imgArray 1 ALT SRC
		    if {[string length $imgArray(SRC)] && !$ParsingCache(IgnoreImages)} {
			convertEntities imgArray(SRC)
			if {[string length $imgArray(ALT)]} {
			    set txt "\[image: $imgArray(ALT)\] "
			} else {
			    set txt "\[image\] "
			}
			linkText $txt $imgArray(SRC)
		    } elseif {[string length $imgArray(ALT)]} {
			# Are we really going to ignore them?
			# Are just render the 'alt' text?
			wrapTextString "($imgArray(ALT)\) "
		    }
		}
		{^INPUT} {
		    getAttributes $html inputArray 1 TYPE NAME VALUE ALT
		    # See <http://htmlhelp.com/reference/wilbur/form/input.html>
		    # for complete INPUT specification.
		    set TYPE [string toupper $inputArray(TYPE)]
		    # (If no type, default is 'text'.)
		    switch -- $TYPE {
			"CHECKBOX" {
			    if {[regexp -nocase "CHECKED" $html]} {
				set txt {[X]}
			    } else {
				set txt {[_]}
			    }
			}
			"FILE" {
			    set txt {<Find File…>}
			}
			"HIDDEN" {
			    set txt {}
			}
			"IMAGE" {
			    # Functions similar to a submit button, but uses
			    # an image instead.
			    if {[string length $inputArray(ALT)]} {
				set txt $inputArray(ALT)
			    } elseif {[string length $inputArray(VALUE)]} {
				set txt $inputArray(VALUE)
			    } else {
				set txt {Submit}
			    }
			    # This isn't standard html, but it's a handy way
			    # to remember what the label is for the button.
			    append html " label=\"$txt\""
			    set txt "\[$txt\]"
			}
			"PASSWORD" {
			    set txt {<enter password…>}
			}
			"RADIO" {
			    if {[regexp -nocase "CHECKED" $html]} {
				set txt {(•)}
			    } else {
				set txt {(_)}
			    }
			}
			"RESET" {
			    if {[string length $inputArray(VALUE)]} {
				set txt $inputArray(VALUE)
			    } else {
				set txt {Reset}
			    }
			    append html " button=\"$txt\""
			    set txt "\[$txt\]"
			}
			"SUBMIT" {
			    if {[string length $inputArray(VALUE)]} {
				set txt $inputArray(VALUE)
			    } else {
				set txt {Submit}
			    }
			    append html " button=\"$txt\""
			    set txt "\[$txt\]"
			}
			"TEXT" - "" {
			    set txt {<enter text…>}
			}
			default {continue}
		    }
		    cacheForm $TYPE $html $txt
		    ensureSpace
		}
		{^ISINDEX} {
		    ensureEmptyLine
		    cacheText $ParsingCache(HR)${CR}${CR}
		    getAttributes $html isindexArray 0 PROMPT
		    if {![info exists isindexArray(PROMPT)]} {
			set isindexArray(PROMPT) "This is a searchable index. "
		    } 
		    cacheText $isindexArray(PROMPT)
		    set txt {[Enter keywords to search…]}
		    linkText $txt "IndexSearch"
		    cacheText "${CR}$ParsingCache(HR)${CR}${CR}"
		}
		{^LI} {
		    ensureBreak
		    set indentation $ParsingCache(Indentation)
		    set indent      $ParsingCache(Indent)
		    if {[info exists ParsingCache(OLcount$indentation)]} {
			cacheText "[string range $indent 2 end]$ParsingCache(OLcount$indentation) "
			incr ParsingCache(OLcount$indentation)
		    } else {
			cacheText "[string range $indent 2 end]• "
		    }
		}
		{^OL} {
		    adjustIndent 3
		    set indentation $ParsingCache(Indentation)
		    set ParsingCache(OLcount$indentation) 1
		    ensureEmptyLine
		}
		{^/OL} {
		    set indentation $ParsingCache(Indentation)
		    catch {unset ParsingCache(OLcount$indentation)}
		    adjustIndent -3
		    ensureEmptyLine
		}
		{^PRE} {
		    ensureEmptyLine
		    set ParsingCache(Pre)  1
		    set ParsingCache(Wrap) 0
		}
		{^/PRE} {
		    set ParsingCache(Pre)  0
		    set ParsingCache(Wrap) 1
		    ensureEmptyLine
		}
		{^P} {
		    ensureEmptyLine
		    set ParsingCache(Wrap) 1
		    set t [string trimleft $t]
		}
		{^/P} {
		    ensureEmptyLine
		}
		{^Q} {
		    switch [incr ParsingCache(Quote) 1] {
			"1"     {cacheText "“"}
			"2"     {cacheText "‘"}
			default {cacheText "'"}
		    }
		}
		{^/Q} {
		    switch $ParsingCache(Quote) {
			"1"     {cacheText "”"}
			"2"     {cacheText "’"}
			default {cacheText "'"}
		    }
		    incr ParsingCache(Quote) -1
		}
		{^SELECT} {
		    if {[catch {findClosingTag "/SELECT" t selectText}]} {
			set t <${html}>${t}
			break
		    }
		    set txt {<select option…>}
		    if {$ParsingCache(InForm)} {
			cacheForm Select $html $txt $selectText
			ensureSpace
		    } else {
			set pos0 $ParsingCache(Length)
			linkText $txt "<NoFormSelect>"
			set pos1 $ParsingCache(Length)
			cacheItem Select $html $pos0 $pos1 $selectText
			ensureSpace
		    }
		}
		{^TABLE} {
		    ensureEmptyLine
		    set ParsingCache(InTable) 1
		}
		{^/TABLE} {
		    ensureEmptyLine
		    set ParsingCache(Wrap) 1
		    set ParsingCache(InTable) 0
		    set ParsingCache(InTableCell) 0
		}
		{^T(D|H)} {
		    ensureSpace
		    if {!$ParsingCache(InTable)} {
		        # We ignore this.
			set pat "^(\[^<\]*)</$qHtml>(.*)\$"
			if {[regexp -nocase $pat $t dummy txt t]} {
			    wrapTextString $txt
			}
			break
		    }
		    set ParsingCache(InTableCell) 1
		    # We want to do here is figure out if we should wrap the
		    # text in the table cell or not.  We don't do any other
		    # formatting, i.e. trying to properly align table cells
		    # with those above or below, except to check to see if
		    # <BR> should really break or just ensure a space.
		    # 
		    # Table cells don't have to be explicity closed, so in
		    # addition to closing tags we check for opening tags to
		    # find out.  If we can't find any 'close' tag, then we add
		    # another segment and try again.  Otherwise, if the string
		    # is greater than twice the fill column length, we set
		    # 'Wrap' to 1, and continue.
		    regsub -- {\s.*} [string toupper $html] "" tag
		    if {[catch {findClosingTag "/$tag" t txt TD /TD TH /TH TR /TR /TABLE}]} {
			set t <${html}>${t}
			break
		    }
		    # Many pages use <BR> in conjunction with <IMG> to format
		    # table cells.  If a cell has an IMG and only one BR,
		    # we'll turn it into a "soft" break, simply ensuring
		    # at least one space.
		    if {[regexp -nocase "<IMG\[\r\n\t \]*" $txt]} {
			set brPat "<BR\[\r\n\t >\]*>"
			if {[regsub -all -nocase $brPat $txt " " txt2] == 1} {
			    set txt $txt2
			} 
		    }
		    set t ${txt}${t}
		    # Now we figure out the wrapping.
		    # Determine the length of this cell text.
		    regsub -all {<[^>]+>} $txt "" cellText
		    set l1 [expr {1.5 * $ParsingCache(FillColumn)}]
		    if {[regexp -nocase {\snowrap} $html]} {
			set ParsingCache(Wrap) 0
		    } elseif {[regexp -nocase {\swrap} $html]} {
			set ParsingCache(Wrap) 1
		    } elseif {[string length $cellText] > $l1} {
			set ParsingCache(Wrap) 1
		    } else {
			set ParsingCache(Wrap) 0
		    }
		}
		{^/T(D|H)} {
		    set ParsingCache(Wrap) 1
		    set ParsingCache(InTableCell) 0
		    ensureSpace
		}
		{^TEXTAREA} {
		    if {[catch {findClosingTag "/TEXTAREA" t textText}]} {
			set t <${html}>${t}
			break
		    }
		    set txt {<enter text…>}
		    cacheForm TextArea $html $txt $textText
		    ensureSpace
		}
		{^TR} {
		    # Should we give empty lines or just breaks?
		    # We don't wrap table rows.
		    ensureBreak
		}
		{^/TR} {
		    ensureBreak
		    set ParsingCache(Wrap) 1
		    set ParsingCache(InTableCell) 0
		}
		{^(UL|DIR|MENU)} {
		    ensureEmptyLine
		    adjustIndent 3
		}
		{^/(UL|DIR|MENU)} {
		    ensureEmptyLine
		    adjustIndent -3
		}
		{^/.*} {
		}
		default {
		    set pat "^(\[^<\]*)</$qHtml>(.*)\$"
		    if {[regexp -nocase $pat $t dummy txt t]} {
			wrapTextString $txt
		    }
		}
	    }
	    set len1 [expr {($ideal * [llength $segments]) + [string length $t]}]
	}
    }
    wrapTextString $t
}

## 
 # -------------------------------------------------------------------------
 # 
 # "html::findClosingTag"  --
 # 
 # Find the closest closing tag, ignoring case.  If the closing tag cannot
 # be found, we throw an error to let the calling code now that the string
 # might have been cut off between tags and that the next batch of text
 # should be added -- if the closing tag really isn't in the string (bad
 # html code !!)  then we'll end up adding the entire string and parsing
 # will potentially slow to a crawl.
 # 
 # '$args' is a list of tags that might serve as closing tags (again, this is
 # bad code but common enough), such as table rows/cells cutting off <A HREF>
 # tags -- in this case, we 'close' the tag but retain the closing tag in the
 # parsing text so that it can be dealt with.
 # 
 # -------------------------------------------------------------------------
 ##

proc html::findClosingTag {tag _t _txt args} {

    upvar $_t    t
    upvar $_txt txt

    set tagOpen  {<[\t\r\n ]*}
    set tagClose {([\t\r\n ]*>|[\t\r\n ]+[^>]+>)}
    set tagArgs  "([join [concat [list $tag] $args] |])"
    set tagPat    ${tagOpen}${tagArgs}${tagClose}
    if {![regexp -indices -nocase $tagPat $t match]} {
	error "Unbalanced '$tag' tag"
    }
    set txt [string range $t 0 [expr {[lindex $match 0] - 1}]]
    set foundTag [string toupper [eval [list string range $t] $match]]
    set foundTag [string trim [string range $foundTag 1 end-1]]
    if {($foundTag == $tag)} {
	# This was the tag we were looking for.
	set idx2 [expr {[lindex $match 1] + 1}]
    } else {
	# Found a 'bad' end, which closes the tag, but we don't want to
	# delete it from the parsing string.
        set idx2 [lindex $match 0]
    }
    set t [string range $t $idx2 end]
    return $t
}

## 
 # -------------------------------------------------------------------------
 # 
 # "html::getAttributes"  --
 # 
 # Create (and upvar) an array named 'arrayName' containing all 'args'
 # attributes for a string contained in an opening html tag.  Assumes that <>
 # have already been stripped.  If 'ensureSet' is '1' each value in 'args'
 # will have at least a null value, otherwise only those attributes both
 # listed in 'args' and existing in the string will have values placed in the
 # array -- but no other attributes will be listed.  All array name elements
 # will be in UPPER CASE.
 # 
 # The first pattern tries to find the attribute value surrounded by
 # quotes -- if that isn't found, we try without quotes, assuming that
 # the value is delimited by whitespace.
 # 
 # -------------------------------------------------------------------------
 ##

proc html::getAttributes {openTagString arrayName ensureSet args} {

    upvar $arrayName attArray
    unset -nocomplain attArray
    set args [string toupper $args]
    if {$ensureSet} {foreach arg $args {set attArray($arg) ""}}

    foreach arg $args {
	set pat1 {\s*=\s*"([^"]*)"}
	set pat2 {\s*=\s*'([^']*)'}
	set pat3 {\s*=\s*([^\s]+)\s*}
	if {[regexp -nocase ${arg}${pat1} $openTagString allofit value]} {
	    set attArray($arg) [string trim $value]
	} elseif {[regexp -nocase ${arg}${pat2} $openTagString allofit value]} {
	    set attArray($arg) [string trim $value]
	} elseif {[regexp -nocase ${arg}${pat3} $openTagString allofit value]} {
	    set attArray($arg) $value
	}
    }
}
  
# ===========================================================================
# 
# ◊◊◊◊ ---- ◊◊◊◊ #
# 
# ◊◊◊◊ Caching ◊◊◊◊ #
# 

## 
 # -------------------------------------------------------------------------
 # 
 # "html::adjustIndent"  --
 # 
 # Adjust all of the indenting variables, including the HR and the fill
 # column.
 # 
 # "html::adjustFillColumn"  --
 # 
 # Adjust the fill column variable, useful e.g. for temporarily over-riding
 # automatic text wrapping.
 # 
 # -------------------------------------------------------------------------
 ##

proc html::adjustIndent {amount} {
    
    variable ParsingCache
    
    if {[incr ParsingCache(Indentation) $amount] < 0} {
	# Should never happen with properly written html code.
	set ParsingCache(Indentation) 0
	set ParsingCache(Indent) ""
	set rightMargin [expr {$ParsingCache(FillColumn) - 10}]
	set ParsingCache(HR) "   [string repeat \"_\" $rightMargin]"
    } elseif {$amount < 0} {
	set amount [expr {abs($amount)}]
	set ParsingCache(Indent) [string range $ParsingCache(Indent) $amount end]
	set ParsingCache(HR) [string range $ParsingCache(HR) $amount end]
	append ParsingCache(HR) [string repeat "_" [expr {2 * $amount}]]
    } else {
	append ParsingCache(Indent) [string repeat " " $amount]
	set ParsingCache(HR) [string range $ParsingCache(HR) 0 \
	  [expr {[string length $ParsingCache(HR)] - ((2 * $amount) + 1)}]]
	set ParsingCache(HR) [string repeat " " $amount]$ParsingCache(HR)
    }
}

proc html::adjustFillColumn {amount} {
    
    variable ParsingCache
    
    if {[incr ParsingCache(FillColumn) $amount] < 0} {
	# Should never happen with properly written html code.
	set ParsingCache(FillColumn) 78
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "html::ensureSpace" "html::ensureBreak" "html::ensureEmptyLine"  --
 # 
 # Ensure that the end of the parsing string contains spaces, line breaks or
 # empty lines.
 # 
 # -------------------------------------------------------------------------
 ##

proc html::ensureSpace {} {

    variable ParsingCache

    if {![regexp {\s+$} $ParsingCache(Text)]} {
	cacheText " "
    } 
}

proc html::ensureBreak {} {

    variable ParsingCache

    if {![regexp {[\r\n]+$} $ParsingCache(Text)]} {
	cacheText $ParsingCache(CR)
    } 
}

proc html::ensureEmptyLine {} {

    variable ParsingCache

    ensureBreak
    if {![regexp {[\r\n]+[\t ]*[\r\n]+$} $ParsingCache(Text)]} {
	cacheText $ParsingCache(CR)
    } 
}

## 
 # -------------------------------------------------------------------------
 # 
 # "html::wrapTextString"  --
 # 
 # Given a string and some preset 'ParsingCache' parameters re indentation,
 # PRE, etc, format the string so that it will be rendered appropriately.
 # 
 # While this might be improved in efficiency, it's really [html::parseHtml]
 # that takes the most time in rendering, so that main concern here really
 # should be proper indenting and filling.
 #
 # "ext" and "html::ParsingCache(Ext)" are Vince's very clever ways of
 # adjusting the fill of a line if it contains bold, outline, or shadow
 # fonts, which take up quite a bit more room -- 'ext' indicates that the
 # current text is lengthy, while "html::ParsingCache(Ext)" remembers this
 # value in case the line isn't yet filled.
 # 
 # Punctuation handling added by Dominique.  Examples refer to the AlphaTcl
 # help file suite for "HTML Help" -- bugs could be observed in earlier
 # versions with default window sizes and 'Ignore Images' turned off.
 # 
 # "html::convertEntities"  --
 # 
 # Convert all html accents in the string to ascii characters.
 # 
 # -------------------------------------------------------------------------
 ##

proc html::wrapTextString {textString {style ""}} {
    
    variable ParsingCache
    
    set posBeg      $ParsingCache(Length)
    # Make sure that we have an adequate length for filling.
    set indentation $ParsingCache(Indentation)
    set indent      $ParsingCache(Indent)
    set CR          $ParsingCache(CR)
    if {$ParsingCache(Wrap)} {
	set wwwFC   $ParsingCache(FillColumn)
	if {($wwwFC - 20) <= $indent} {
	    # This might happen with a lot of indenting, small window
	    # parameters.
	    set wwwFC 20
	}
    } else {
	set wwwFC 2000
    }
    # Substitute all carriage returns with the specified string.
    regsub -all {
} $textString $CR textString
    # Remove any unnecessary leading extra spaces, carriage returns.
    if {!$ParsingCache(Pre)} {
	regsub {^\s+} $textString { } textString
	if {[regexp {\s+$} $ParsingCache(Text)]} {
	    regsub {^\s+} $textString {} textString
	} else {
	    regsub {^[\r\n]+} $textString {} textString
	}
    }
    # Perform some initial tests.
     if {$textString == ""} {
	# Nothing here!
	return [list $posBeg $posBeg]
    } elseif {$ParsingCache(Pre)} {
	# This is preformatted, so simply insert.
	convertEntities textString
	return [cacheText $textString]
    } else {
	regsub -all "\[\t\r\n \]+" $textString " " textString
	convertEntities textString
    }
    # Prepare the textString for wrapping.
    set ext [regexp {bold|outline|shadow} $style]
    if {[regexp "\[\r\n\]\$" $ParsingCache(Text)]} {
	set ParsingCache(Ext) 0
    }
    regsub "^.*\[\r\n\]" $ParsingCache(Text) {} thisLine
    set x [string length $thisLine]
    while {$x < $indentation} {
	cacheText " "
	incr x
    }
    set fc [expr {$wwwFC - [expr {(3 + $ParsingCache(Ext)) / 6}]}]
    if {$x > $fc} {
	# Handle punctuation character from the previous block to put them at
	# the beginning of next line rather than at the end of the previous
	# one, as in
	#                                  ... of the suffixes
	#   ".html", ".htm" or ".shtml".
	#   
	# in HTML manual (Getting Started).
	set tt ""
	set end [expr {[string length $ParsingCache(Text)] - 1}]
	set lngth_pc [expr {$end - 1}]
	set a [string index $ParsingCache(Text) $lngth_pc]
	set b [string index $ParsingCache(Text) $end]
	if {![regexp {\w} $b] && ($a == " ")} {
	    set tt $b
	    set l1 [incr lngth_pc -1]
	    set ParsingCache(Text) [string range $ParsingCache(Text) 0 $l1]
	}
	# End of punctuation character handling.
	cacheText "${CR}${indent}${tt}"
	set x 0
	set ParsingCache(Ext) 0
    }
    set fc [expr {$fc - $x + 1}]
    if {$ext} {set fc [expr {(5 + 6 * $fc) / 7}]}
    # Handle punctuation characters after previous block to put them at the
    # end of a line rather than at the beginning of next line, as in
    # 
    #                                              ... (suffix .html,
    #   .htm or .shtml).
    # 
    # in HTML manual (main page). 
    set a [string index $textString 1]
    set b [string index $textString 0]
    if {![regexp {\w} $b] && ($a == " ")} {
	set f [string last "${CR}${indent}" $ParsingCache(Text)]
	set lngth_pc [expr {[string length $ParsingCache(Text)] \
	  -[string length $indent] - 1}]	
	if {$f == $lngth_pc} {
	    set ParsingCache(Text) \
	      "[string range $ParsingCache(Text) 0 [incr f -1]]$b${CR}${indent}"
	    set textString [string range $textString 2 end]
	} 
    }
    # End of punctuation character handling.
    if {[set lword [string first " " $textString]] == -1} {
	set lword [string length $textString]
    }
    if {$fc < $lword} {
	# Handle punctuation character from the previous block to put them at
	# the beginning of next line rather than at the end of the previous
	# one, as in
	# 
	#                                  ... deprecated
	# (see below)
	# 
	# in HTML manual (Document type declaration).
	set tt ""
	set end [expr {[string length $ParsingCache(Text)] - 1}]
	set lngth_pc [expr {$end - 1}]
	set a [string index $ParsingCache(Text) $lngth_pc]
	set b [string index $ParsingCache(Text) $end]
	if {![regexp {\w} $b] && ($a == " ")} {
	    set tt $b
	    set l1 [incr lngth_pc -1]
	    set ParsingCache(Text) [string range $ParsingCache(Text) 0 $l1]
	}
	# End of punctuation character handling.
	cacheText "${CR}${indent}${tt}"
	set ParsingCache(Ext) 0
	set fc [expr {$wwwFC - $indentation - [string length $tt]}]
	if {$ext} {
	    set fc [expr {(5 + 6 * $fc) / 7}]
	    set ParsingCache(Ext) [string length $textString]
	}
    }
    # Now we cache the textString, 
    while {[string length $textString] > $fc} {
	set f [string last " " [string range $textString 0 $fc]]
	if {$f == -1} {set f $fc}
	cacheText [string trimright [string range $textString 0 $f]]
	set textString [string range $textString [incr f] end]
	set fc [expr {$ParsingCache(FillColumn) - $indentation}]
	if {$ext} {set fc [expr {(5 + 6 * $fc) / 7}]}
	if {[string length [string trim $textString]]} {
	    cacheText "${CR}${indent}"
	} 
    }
    cacheText $textString
    if {$ext} {
	set ParsingCache(Ext) \
	  [expr {$ParsingCache(Ext) + [string length $textString]}]
    }
    list $posBeg $ParsingCache(Length)
}

proc html::convertEntities {tt} {
    
    variable EntitiesToText
    variable ParsingCache
    
    upvar $tt t

    # Replace some common style elements first.
    regsub -all {&\#160;|&nbsp;}   $t { }  t
    # This is a very common coding error -- leaving off the trailing ";"
    regsub -all {&nbsp}            $t { }  t
    regsub -all {&lt;}             $t "<"  t
    regsub -all {&gt;}             $t ">"  t
    regsub -all {&quot;}           $t {"}  t
    regsub -all {&\#8226;}         $t {•}  t
    # Replace all other style elements, except for '$amp;'.  We do these at
    # the end, in case they're being used to demonstrate HTML code --
    # otherwise, the demo string will be completely converted !!
    set loop 0
    while {[regexp -- {&([^\s ;]+);} $t dummy accent]} {
	regsub {#0+} $accent {#} accent
	if {$accent == "amp" || $accent == "#38"} {
	    regsub -all $dummy $t "<<HTMLAMPCODE>>" t 
	} elseif {[info exists EntitiesToText($accent)]} {
	    regsub -all $dummy $t [set EntitiesToText($accent)] t
	} else {
	    if {[regsub -all {&} $accent {\\&} accent]} {
		echo "There is a syntax error in &${accent}\;."
		break
	    } else {
		set accent "\\&;${accent};"
		regsub -all $dummy $t $accent t
	    }
	    incr loop
	} 
	if {$loop > 100} {
	    echo "There are too many unknown characters or a problem."
	    break
	}
    }
    regsub -all {<<HTMLAMPCODE>>} $t {\&} t
    if {$loop > 0} {regsub -all {&;} $t {\&} t}
}

## 
 # -------------------------------------------------------------------------
 # 
 # "html::linkText" "html::colourText"  --
 # 
 # Given a string and some color/hyper arguments, cache both the text and the
 # color/hyper info that will be used once the text has actually been
 # inserted.  Since the window has no positions yet, we based the positions
 # for the colors/hypers on the current length of the parsing string and
 # we'll do some math position once the parsing is done and the text has been
 # inserted into the window.
 # 
 # -------------------------------------------------------------------------
 ##

proc html::linkText {txt link {target ""}} {

    if {![string length [string trim $txt]]} {return}

    set positions [wrapTextString $txt]
    set pos0 [lindex $positions 0]
    set pos1 [lindex $positions 1]
    set link [string trim [string trim $link] {\"}]
    cacheItem Links $pos0 $pos1 $link $target
}

proc html::colourText {txt args} {

    set positions [wrapTextString $txt [lindex $args 0]]
    set pos0 [lindex $positions 0]
    set pos1 [lindex $positions 1]
    foreach arg $args {cacheItem Colors $pos0 $pos1 $arg}
}

## 
 # -------------------------------------------------------------------------
 # 
 # "html::cacheFormStart" "html::cacheText" "html::cacheItem"  --
 # 
 # Store various bits of information that will be used once the entire html
 # file has been parsed.  See the comments for 'html::parseHtml' for more
 # information on what items are potentially cached during parsing.
 # 
 # -------------------------------------------------------------------------
 ##

proc html::cacheForm {formItemType typeAtts {txt ""} args} {

    variable ParsingCache

    set pos0 $ParsingCache(Length)
    set num1 $ParsingCache(FormNumber)
    set num2 $ParsingCache(FormFieldNumber)
    set link "FORM-${num1}-FIELD-${num2}-[string toupper $formItemType]"
    linkText $txt $link
    set pos1 $ParsingCache(Length)
    cacheItem Forms $link $typeAtts $pos0 $pos1 $args
    incr ParsingCache(FormFieldNumber)
}

proc html::cacheText {textString} {

    variable ParsingCache

    set length1 [string length $ParsingCache(Text)]
    set length2 [string length [append ParsingCache(Text) $textString]]
    list $length1 [set ParsingCache(Length) $length2]
}

proc html::cacheItem {item args} {

    variable  ParsingCache

    lappend ParsingCache($item) $args
}

# ===========================================================================
# 
# .
