## -*-Tcl-*-  (nowrap)
 # ==========================================================================
 # Mail Menu - an extension package for Alpha
 #
 # FILE: "mailParsing.tcl"
 # 
 #                                          created: 01/03/2005 {09:50:32 AM}
 #                                      last update: 04/06/2005 {11:02:03 AM}
 # Description:
 # 
 # Parsing of E-mail "From" message text.  This will handle "multipart" mime
 # messages, and take special encodings into account.
 # 
 # (There is currently no support for specific character sets, however.)
 # 
 # See the "Changes - Mail Menu" file for license information.
 # 
 # ==========================================================================
 ##

proc mailParsing.tcl {} {}

# ===========================================================================
# 
# ◊◊◊◊ Parsing Mail Text ◊◊◊◊ #
# 

namespace eval Mail {
    
    # This is used to keep track of parsed www colors/links.
    variable htmlCache
    if {![info exists htmlCache]} {
        set htmlCache [list]
    } 
    variable parsingFillColumn
    if {![info exists parsingFillColumn]} {
        set parsingFillColumn 80
    } 
    # The array for translating "quoted-printable" strings.  Note that these
    # 
    # 8A  S  
    # 8E  Z  
    # 88  ^  
    # 9A  s  
    # 9E  z  
    # 98  ~  
    # F0  d  
    # 
    # are just approximations.  They don't exist in MacRoman.
    # 
    # Do _not_ include "=3D" -> "=" here, we do that "manually" at the end.
    # 
    variable quotedPrintableEncoding
    array set quotedPrintableEncoding {
	
	"=09"           "\t"
	
	"=20"           { }
	"=21"           {!}
	"=22"           {"}
	"=23"           {#}
	"=24"           {$}
	"=25"           {%}
	"=26"           {\&}
	"=27"           {'}
	"=28"           {(}
	"=29"           {)}
	
	"=2A"           {*}
	"=2B"           {+}
	"=2C"           {,}
	"=2D"           {-}
	"=2E"           {.}
	"=2F"           {/}
	
	"=31"           {1}
	"=32"           {2}
	"=33"           {3}
	"=34"           {4}
	"=35"           {5}
	"=36"           {6}
	"=37"           {7}
	"=38"           {8}
	"=39"           {9}
	
	"=3A"           {:}
	"=3B"           {;}
	"=3C"           {<}
	"=3E"           {>}
	"=3F"           {?}
	
	"=40"           {@}
	"=41"           {A}
	"=42"           {B}
	"=43"           {C}
	"=44"           {D}
	"=45"           {E}
	"=46"           {F}
	"=47"           {G}
	"=48"           {H}
	"=49"           {I}
	
	"=4A"           {J}
	"=4B"           {K}
	"=4C"           {L}
	"=4D"           {M}
	"=4E"           {N}
	"=4F"           {O}
	
	"=50"           {P}
	"=51"           {Q}
	"=52"           {R}
	"=53"           {S}
	"=54"           {T}
	"=55"           {U}
	"=56"           {V}
	"=57"           {W}
	"=58"           {X}
	"=59"           {Y}
	
	"=5A"           {Z}
	"=5B"           {[}
	"=5C"           "\\"
	"=5D"           {]}
	"=5E"           {^}
	"=5F"           {_}
	
	"=60"           {`}
	"=61"           {a}
	"=62"           {b}
	"=63"           {c}
	"=64"           {d}
	"=65"           {e}
	"=66"           {f}
	"=67"           {g}
	"=68"           {h}
	"=69"           {i}
	
	"=6A"           {j}
	"=6B"           {k}
	"=6C"           {l}
	"=6D"           {m}
	"=6E"           {n}
	"=6F"           {o}
	
	"=70"           {p}
	"=71"           {q}
	"=72"           {r}
	"=73"           {s}
	"=74"           {t}
	"=75"           {u}
	"=76"           {v}
	"=77"           {w}
	"=78"           {x}
	"=79"           {y}
	
	"=7A"           {z}
	"=7B"           {\{}
	"=7C"           {|}
	"=7D"           {\}}
	"=7E"           {~}
	
	"=80"           {?}
	"=82"           {‚}
	"=83"           {ƒ}
	"=84"           {„}
	"=85"           {…}
	"=86"           {†}
	"=87"           {‡}
	"=88"           {^}
	"=89"           {‰}
	
	"=8A"           {S}
	"=8B"           {‹}
	"=8C"           {Œ}
	"=8E"           {Z}
	
	"=91"           {‘}
	"=92"           {’}
	"=92"           {’}
	"=93"           {“}
	"=94"           {”}
	"=95"           {•}
	"=96"           {–}
	"=97"           {—}
	"=98"           {~}
	"=99"           {™}
	
	"=9A"           {s}
	"=9B"           {›}
	"=9C"           {œ}
	"=9E"           {z}
	"=9F"           {Ÿ}
	
	"=A0"           { }
	"=A2"           {¢}
	"=A8"           {®}
	"=A9"           {©}
	
	"=AB"           {«}
	"=AD"           {-}
	
	"=B0"           {°}
	"=B1"           {±}
	"=B2"           {2}
	"=B3"           {3}
	"=B4"           {´}
	"=B5"           {µ}
	"=B6"           {¶}
	"=B7"           {·}
	"=B8"           {¸}
	"=B9"           {1}
	
	"=BA"           {º}
	"=BB"           {»}
	"=BC"           {1/4}
	"=BD"           {1/2}
	"=BE"           {3/4}
	"=BF"           {¿}
	
	"=C0"           {À}
	"=C1"           {Á}
	"=C2"           {Â}
	"=C3"           {Ã}
	"=C4"           {Ä}
	"=C5"           {Å}
	"=C6"           {Æ}
	"=C7"           {Ç}
	"=C8"           {È}
	"=C9"           {É}
	
	"=CA"           {Ê}
	"=CB"           {Ë}
	"=CC"           {Ì}
	"=CD"           {Í}
	"=CE"           {Î}
	"=CF"           {Ï}
	
	"=D0"           {D}
	"=D1"           {Ñ}
	"=D2"           {Ò}
	"=D3"           {Ó}
	"=D4"           {Ô}
	"=D5"           {Õ}
	"=D6"           {Ö}
	"=D7"           {x}
	"=D8"           {Ø}
	"=D9"           {Ù}
	
	"=DA"           {Ú}
	"=DB"           {Û}
	"=DC"           {Ü}
	"=DD"           {Y}
	"=DE"           {ﬂ}
	"=DF"           {ß}
	
	"=E0"           {à}
	"=E1"           {á}
	"=E2"           {â}
	"=E3"           {ã}
	"=E4"           {ä}
	"=E5"           {å}
	"=E6"           {æ}
	"=E7"           {ç}
	"=E8"           {è}
	"=E9"           {é}
	
	"=EA"           {ê}
	"=EB"           {ë}
	"=EC"           {ì}
	"=ED"           {í}
	"=EE"           {î}
	"=EF"           {ï}
	
	"=F0"           {d}
	"=F1"           {ñ}
	"=F2"           {ò}
	"=F3"           {ó}
	"=F4"           {ô}
	"=F5"           {õ}
	"=F6"           {ö}
	"=F7"           {÷}
	"=F8"           {ø}
	"=F9"           {ù}
	
	"=FA"           {ú}
	"=FB"           {û}
	"=FC"           {ü}
	"=FD"           {y}
	"=FE"           {ﬁ}
	"=FF"           {ÿ}
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "Mail::setFillColumn"  --
 # 
 # Determine the fill column length.
 # 
 # Since we know that the window has either already been created (and so the
 # geometry is already set) or will be created with a pre-determined width,
 # we want to break lines to fit the window.  The formula used to determine
 # the fill column variable for Alpha8/X probably could be fine tuned, but
 # works reasonably well for now.
 #  
 # -------------------------------------------------------------------------
 ##

proc Mail::setFillColumn {} {
    
    global MailmodeVars alpha::platform defWidth
    
    variable parsingFillColumn
    
    if {[win::Exists [set w [Mail::findViewerWindow]]]} {
        set width [lindex [getGeometry $w] 2] ; # l t w h
    } elseif {([llength $MailmodeVars(mailViewWindowGeometry)] == 5)} {
        set width [lindex $MailmodeVars(mailViewWindowGeometry) 3]
    } else {
        set width $defWidth
    }
    set fontname $MailmodeVars(mailViewWindowFont)
    set fontsize $MailmodeVars(mailViewFontSize)
    set X [string repeat "abcdeABCDE" 10]
    switch -- ${alpha::platform} {
	"alpha" {
	    # Yes, this is crude.
	    set fontMeas [expr {(($fontsize + 5) / 2.0)}]
	}
	"dummy" {
	    # We'd like to use this for "alpha", but [getTextDimensions]
	    # either fails or returns bogus specs.  See bug# 1783, 1788.
	    set fontDims [getTextDimensions -font $fontname -size $fontsize $X]
	    set fontMeas [expr {[lindex $fontDims 2] / 90.0}]
	}
	"tk" {
	    set fontDims [font measure [list $fontname $fontsize] $X]
	    set fontMeas [expr {[screenToDistance $fontDims] / 90.0}]
	}
    }
    set fillCol [expr {int($width / $fontMeas)}]
    set fillCol [expr {$fillCol < 70 ? 70 : $fillCol}]
    set parsingFillColumn $fillCol
    return [set parsingFillColumn $fillCol]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::parseContent" --
 # 
 # Parse the contents of our new viewing window, and return them as a text
 # string to the calling procedure.  We pass the contents and other relevant
 # arguments to [Mail::parseString] to begin the (possibly recursive) parsing
 # routines.  The results are stored in the "parsedText" variable, but also
 # explicitly returned in case the calling procedure wants it right away.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::parseContent {content args} {
    
    global MailmodeVars
    
    variable htmlCache
    variable htmlMarker
    variable newMessagePartText
    variable parsedText
    variable renderHtml
    variable reserveText
    
    # Reset variables.
    set parsedText  ""
    set reserveText ""
    set htmlCache   [list]
    set htmlMarker  "-1"
    if {$MailmodeVars(renderHtmlFormattedText) \
      && [alpha::package exists "wwwMenu"]} {
	set renderHtml 1
    } else {
	set renderHtml 0
    }
    Mail::setFillColumn
    # Make sure that we have some default values.
    array set emailFields [list \
      "content-type"                    "text/plain" \
      "content-transfer-encoding"       "" \
      ]
    # Find our true values.
    array set emailFields $args
    # Call a support procedure.
    set parsedText [Mail::parseString $content \
      "content-type"                $emailFields(content-type) \
      "content-transfer-encoding"   $emailFields(content-transfer-encoding)]
    if {![string length [string trim $parsedText]]} {
        set parsedText $reserveText
    } 
    append newMessagePat {^\s*(} [quote::Regsub $newMessagePartText] {)\s*}
    regsub -- $newMessagePat $parsedText {} parsedText
    return $parsedText
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::parseString" --
 # 
 # Based on the "content-type" field, call a helper procedure to parse the
 # supplied "content".
 # 
 # Called by [Mail::parseContent] but also my any other helper procedure that
 # has encountered a string that has to be parsed separately.  
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::parseString {content args} {
    
    set text ""
    # Make sure that we have some default values.
    array set emailFields [list \
      "content-type"                    "text/plain" \
      "content-transfer-encoding"       "" \
      ]
    # Find our true values.
    array set emailFields $args
    set cType $emailFields(content-type)
    set cTEnc $emailFields(content-transfer-encoding)
    # Call a support procedure.
    switch -regexp -- [string tolower [string trimleft $cType]] {
	"^application/" {set cmd "Mail::parseAttach"}
	"^audio/"       {set cmd "Mail::parseAttach"}
	"^image/"       {set cmd "Mail::parseAttach"}
	"^message/"     {set cmd "Mail::parseMessage"}
	"^multipart/"   {set cmd "Mail::parseMulti"}
	"^text/"        {set cmd "Mail::parseText"}
	"^video/"       {set cmd "Mail::parseAttach"}
	default         {set cmd "Mail::parseText"}
    }
    if {[catch {$cmd [string trim $content] $cType $cTEnc} text]} {
	# This is mainly for debugging.
	dialog::alert -- "Error Warning:\r\r$::errorInfo"
	set text $content
    } 
    # Return our results.
    if {[string length [string trim $text]]} {
	set text "[string trimright $text]\r\r"
    } else {
	set text ""
    }
    return $text
}
## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::parseText" --
 # 
 # We need to deal with "Content-Transfer-Encoding: Quoted-Printable" text.
 # We use the WWW package if possible to render any html formatted text.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::parseText {content cType cTEnc} {
    
    global MailmodeVars html::ParsingCache
    
    variable htmlCache
    variable htmlMarker
    variable quotedPrintableEncoding
    variable parsingFillColumn
    variable renderHtml
    
    set text ""
    # Quoted-Printable Content-Transfer-Encoding
    if {[regexp -nocase -- "quoted-printable" $cTEnc]} {
	regsub -all -- {=(\r|\r?\n|$)}  $content {}     content
	regsub -all -- {=20(\r|\r?\n)}  $content "\r"   content
	foreach encodingItem [array names quotedPrintableEncoding] {
	    set printItem $quotedPrintableEncoding($encodingItem)
	    regsub -all -nocase -- $encodingItem $content $printItem content
	}
	regsub -all -nocase -- {=3D} $content {=} content
    } 
    # Parse our text.
    if {[regexp -nocase -- {text/(html|enriched)} $cType] && $renderHtml} {
	# Html text -- parse it using WWW Menu procedures.  We place a
	# special marker at the end of our "(This message ...)" line so that
	# the colorizing routine has knows what to think of as the "start"
	# position relative to the colors/links in the parsing cache.
	loadAMode "WWW"
	if {[catch {html::parseHtml $content $parsingFillColumn} htmlText]} {
	    set htmlText $content
	}
	regexp -all -- {^(\s*)(.*)$} $htmlText -> leadWhite htmlText
	append text "(This message was delivered in html format)" \
	  [string repeat "\t" 24] "∞∞∞" [incr htmlMarker] "∞∞∞\r" \
	  [string repeat " " [string length $leadWhite]] "\r" $htmlText
	foreach cacheItem [list "Colors" "Links"] {
	    if {![info exists html::ParsingCache($cacheItem)]} {
	        set html::ParsingCache($cacheItem) [list]
	    } 
	    set $cacheItem [set html::ParsingCache($cacheItem)]
	}
	lappend htmlCache [list $Colors $Links]
    } else {
	# Plain text -- just perform wrapping of long lines.
	foreach line [split $content "\r\n"] {
	    if {([string length $line] < $parsingFillColumn)} {
		append text $line "\r"
	    } else {
		# Break into lines, each with the same prefix string.
		set pat {^([>\|\t ]*)(.*)$}
		regexp -- $pat $line -> prefixString theRest
		set prefixLength [string length $prefixString]
		set rightCol [expr {$parsingFillColumn - $prefixLength}]
		set newLines [breakIntoLines $theRest $rightCol]
		foreach newLine [split $newLines "\r\n"] {
		    append text $prefixString $newLine "\r"
		}
	    }
	}
    }
    return [string trimright $text]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::parseMessage" --
 # 
 # We have two sets of headers here, and we only pay attention to the second
 # ones that contain the message.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::parseMessage {content cType cTEnc} {
    
    variable parsingFillColumn
    
    set content-type ""
    set content-transfer-encoding ""
    set fieldPattern {^([-\w]+):[\t ]*(.*)}
    set emailFields  [list "from" "to" "cc" "reply-to" "date" "subject"]
    set hasEmail     [list "from" "to" "cc" "reply-to"]
    set headerInfo   [list]
    set newContent   [list]
    set msgLines [split [string trimleft $content] "\r\n"]
    for {set i 0} {($i < [llength $msgLines])} {incr i} {
	set msgLine [lindex $msgLines $i]
	if {[regexp -nocase -- $fieldPattern $msgLine -> which what]} {
	    set which [string tolower $which]
	    set $which $what
	    while {1} {
		set nextMsgLine [lindex $msgLines [expr {$i + 1}]]
		if {[regexp {^[\t ]+\S} $nextMsgLine]} {
		    append $which $nextMsgLine
		    incr i
		} else {
		    break
		}
	    } 
	    if {([lsearch $emailFields $which] > -1)} {
		set newLine [format {%-10s} "[string totitle $which]:"]
		if {([lsearch $hasEmail $which] > -1)} {
		    set fieldValue [Mail::parseEmailField [set $which]]
		} else {
		    set fieldValue [Mail::parseHeaderField [set $which]]
		    set fieldValue [string trim [breakIntoLines \
		      $fieldValue $parsingFillColumn 10]]
		}
		append newLine $fieldValue
		append text $newLine "\r"
		lappend headerInfo $newLine
	    } 
	} elseif {![string length $msgLine]} {
	    set newContent [lrange $msgLines [incr i] end]
	    break
	}
    }
    set text "(In-line message)\r\r"
    if {[llength $headerInfo]} {
        append text [join $headerInfo "\r"] "\r\r"
    } 
    set content [concat $content [list ""] $newContent]
    set content [string trim [join $newContent "\r"]]
    foreach varName [info vars content-*] {
	lappend args $varName [set $varName]
    }
    append text [eval [list Mail::parseString $content] $args]
    return [string trimright $text]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::parseMulti" --
 # 
 # Parse out a multi-part message.  The "cType" argument should include a
 # boundary string which will delimit each section.  We then pass that
 # section string to [Mail::parseText] to be dealt with as necessary.  Note
 # that multipart sections can be nested, i.e. include multipart sections
 # themselves.  This procedure will be able to handle this.
 # 
 # There is a special case built in for the "digest" subtype, in which each
 # part is actually a separate e-mail (complete with header fields) that has
 # to be parsed.  We only pay attention to "content-..."  fields and include
 # all others in parsed text, separating them from the body of each message.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::parseMulti {content cType cTEnc} {
    
    variable newMessagePartText
    variable parsingFillColumn
    variable renderHtml
    variable reserveText
    
    set multiPat {multipart/([-\w]+).*;\s*boundary=\"?([^\"]+)\"?}
    if {![regexp -nocase -- $multiPat $cType -> subtype boundary]} {
	return $content
    }
    set text ""
    set emailFields  [list "from" "to" "cc" "reply-to" "date" "subject"]
    # We have multiple sections.  Scan the entire string to separate them
    # into their own "section$number" variables.  The pattern with "--" at
    # the end indicates the end of the section, but we handle this in the
    # same way, i.e. assume that a new section is starting.
    set number    "0"
    set boundPat1 "--${boundary}"
    set boundPat2 "--${boundary}--"
    set section0  [list ""]
    foreach line [split $content "\r\n"] {
	if {($line eq $boundPat1) || ($line eq $boundPat2)} {
	    incr number
	} else {
	    lappend section$number $line
	}
    }
    # Now we scan each section to figure out how to parse it.
    set fieldPattern {^([-\w]+):[\t ]*(.*)}
    for {set i1 0} {($i1 <= $number)} {incr i1} {
	if {![info exists section$i1]} {
	    continue
	} 
	set sectionContent [list]
	set content-type ""
	set content-transfer-encoding ""
	for {set i2 0} {($i2 < [llength [set section$i1]])} {incr i2} {
	    set msgLine [lindex [set section$i1] $i2]
	    if {($subtype eq "digest") \
	      && ![string length $msgLine] \
	      && ($i2 == 0)} {
		continue
	    } 
	    if {[regexp -nocase -- $fieldPattern $msgLine -> which what]} {
		set which [string tolower $which]
		set $which $what
		while {1} {
		    set nextMsgLine [lindex [set section$i1] [expr {$i2 + 1}]]
		    if {[regexp {^[\t ]+\S} $nextMsgLine]} {
			append $which $nextMsgLine
			incr i2
		    } else {
			break
		    }
		} 
		if {![regexp -nocase -- "^content-" $msgLine] \
		  && ([lsearch $emailFields $which] > -1)} {
		    set newLine        [format {%-10s} "[string totitle $which]:"]
		    append newLine     [string trimleft \
		      [breakIntoLines [set $which] $parsingFillColumn 10]]
		    lappend sectionContent $newLine
		} 
	    } elseif {![string length $msgLine]} {
		if {($subtype eq "digest") && [llength $sectionContent]} {
		    lappend sectionContent ""
		} 
		if {[regexp {^message} ${content-type}]} {
		    set sectionContent [lrange [set section$i1] [incr i2] end]
		} else {
		    set sectionContent [concat $sectionContent \
		      [lrange [set section$i1] [incr i2] end]]
		}
		set sectionContent [join $sectionContent "\r"]
		break
	    }
	}
	# If the "content-type" was "multipart/alternative" then we pay
	# attention to the current "renderHtml" value.
	foreach varName [info vars content-*] {
	    lappend args $varName [set $varName]
	}
	regsub -all -- {^[\r\n]+} $sectionContent {} sectionContent
	set sectionText [eval [list Mail::parseString $sectionContent] $args]
	if {[regexp -- {multipart/alternative} $cType]} {
	    if {$renderHtml && [regexp {^text/plain} ${content-type}]} {
		append reserveText $sectionText
	        continue
	    } elseif {!$renderHtml && [regexp {^text/html} ${content-type}]} {
		append reserveText $sectionText
	        continue
	    } 
	} 
	if {[string length [string trim $sectionText]]} {
	    if {![string match "${newMessagePartText}*" \
	      [string trimleft $sectionText]]} {
		append text "\r\r" $newMessagePartText "\r\r"
	    } 
	    append text [string trimright $sectionText]
	} 
    }
    return [string trimright $text]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::parseAttach" --
 # 
 # We might be able to handle attachments someday, but for now we simply
 # inform the user that the file was attached.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::parseAttach {content cType cTEnc} {
    
    set extraPat {([\w/]+).+name=\"?([^\"]+)\"?}
    if {![regexp -nocase -- $extraPat $cType -> attachmentType fileName]} {
	return $cType
    } else {
	set attachmentType [string tolower $attachmentType]
	return "Attached $attachmentType file: \"${fileName}\""
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::parseEmailField" --
 # 
 # Given a string for a header field that contains an e-mail address, attempt
 # to parse out the "real names" from the addresses to include in a canonical
 # way.  For example,
 # 
 #   «Alpha» Mail::parseEmailField "Walker Art Center Events <mailing.list@walkerart.org>"
 #   "Walker Art Center Events" <mailing.list@walkerart.org>
 # 
 #   «Alpha» Mail::parseEmailField "=?ISO-8859-1?Q?Dominique_d'Humi=E8res?= <dhum...@wanadoo.fr>"
 #   "Dominique_d'Humières" <dhum...@wanadoo.fr>
 # 
 #   «Alpha» Mail::parseEmailField "dominiq@lps.ens.fr (Dominique Dhumieres)"
 #   "Dominique Dhumieres" <dominiq@lps.ens.fr>
 # 
 # Each e-mail address is listed in the return value on a separate line, all
 # but the first indented by 10 spaces.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::parseEmailField {fieldValue} {
    
    variable emailPattern
    
    set newValueList [list]
    set addresses    [list]
    set newRealName  ""
    set newAddress   ""
    # Create a list of addresses.
    set fieldValueList [split $fieldValue "\r\n\t "]
    for {set i 0} {($i < [llength $fieldValueList])} {incr i} {
	set item [string trim [lindex $fieldValueList $i]]
        if {[regexp $emailPattern $item]} {
	    regexp {^\s*<?([^>,]+)[>,\s]*$} $item -> newAddress
        } else {
	    append newRealName [string trim $item]
	    while {1} {
		set nextItem [lindex $fieldValueList [incr i]]
		if {[regexp $emailPattern $nextItem]} {
		    incr i -1
		    break
		} elseif {[string length $nextItem]} {
		    append newRealName " " $nextItem
		} 
		if {($i >= [llength $fieldValueList])} {
		    break
		}
	    }
        }
	if {([string index $item end] eq ",")
	  && [string length $newAddress]} {
	    lappend addresses [list $newRealName $newAddress]
	    set newRealName ""
	    set newAddress  ""
	} 
    }
    # Add our last item found.
    lappend addresses [list $newRealName $newAddress]
    # Massage our entries.
    foreach address $addresses {
	# Massage our entry name.
	set entryName [string trim [lindex $address 0]]
	set entryName [string trim $entryName "\""]
	set entryName [string trimleft  $entryName "\("]
	set entryName [string trimright $entryName "\)"]
	set entryName [Mail::parseHeaderField $entryName]
	if {[string length $entryName]} {
	    set entryName "\"[string trim $entryName]\""
	} 
	# Massage our entry address.
	set emailAddress [string trim [lindex $address 1]]
	set emailAddress [string trimleft  $emailAddress "<"]
	set emailAddress [string trimright $emailAddress ">"]
	if {[string length $emailAddress]} {
	    set emailAddress "<${emailAddress}>"
	}
	# Add this value to our list.
	lappend newValueList [string trim "$entryName $emailAddress"]
    }
    set pad [string repeat " " 10]
    return [string trim [join $newValueList ",\r${pad}"]]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::parseHeaderField" --
 # 
 # Parse the given header field value, converting quoted-printable characters
 # as necessary.
 # 
 # For example:
 # 
 #   «Alpha» Mail::parseHeaderField "=?ISO-8859-1?Q?Dominique_d'Humi=E8res?="
 #   Dominique_d'Humières
 # 
 # Results are returned in one long line.  It is up to the calling code to
 # wrap/break them as necessary.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::parseHeaderField {fieldValue} {
    
    set quotedPat {^\s*=\?\S+?q\?([^\?]+)\?=\s*(.*)}
    set newValue  ""
    regsub -all -- {\s+} [string trim $fieldValue] { } fieldValue
    while {[regexp -nocase -- $quotedPat $fieldValue -> unquotedValue fieldValue]} {
	append newValue [Mail::parseText $unquotedValue "" "quoted-printable"]
	set fieldValue [string trim $fieldValue]
    }
    append newValue $fieldValue
    regsub -all -- {\s+} $newValue { } newValue
    return [string trim $newValue]
}

# ===========================================================================
# 
# ◊◊◊◊ -------- ◊◊◊◊ #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Mail::colorizeWindow" --
 # 
 # Our "Mail View" windows are created in our "mailview" minor-mode, which
 # doesn't have any colortags.  This gives us greater control over what we
 # color (and what we don't) without running into long-standing Alpha8/X core
 # issues where [text::color] and [regModeKeywords] don't play well together.
 # (The main issue here is the conflict with the [regModeKeywords] "-c" flag
 # for coloring comments that confuses ending color breaks.)
 # 
 # In this routine we color:
 # 
 # * The ">=====<" divider line
 # * All e-mail header fields
 # * The special "Msg" line containing the "Reply" and "Trash" hyperlinks
 # * Quoted material in the body of the email
 # * urls and "mailto" hyperlinks, not only surrounded by <angle-brackets>
 # * Any color/hyper cached by [html::parseHtml] in [Mail::parseText]
 # 
 # We take special care to only hyperlink a text region once -- in Alpha8/x
 # adding multiple "colorEscapes" for a single position tends to destroy
 # hyperlinks and only color them.
 # 
 # --------------------------------------------------------------------------
 ##

proc Mail::colorizeWindow {args} {
    
    global MailmodeVars
    
    variable htmlCache
    
    win::parseArgs w {msgLineOnly 0}
    
    # Special case for AlphaTcl e-mails.
    set sentTo [Mail::getFieldValue "to"]
    set sentCc [Mail::getFieldValue "cc"]
    if {[regexp -nocase -- {alphatcl|alpha-bugzilla} "$sentTo $sentCc"]} {
	set alphaTclMail 1
    } else {
        set alphaTclMail 0
    }
    # Find our divider string.
    set pat  {^>====+[^\r]+====+<$}
    set pos  [minPos -w $w]
    set dividerLine [search -w $w -s -n -f 1 -r 1 -- $pat $pos]
    if {![llength $dividerLine]} {
        return
    } 
    # Color the {Msg "95" (98) of mailbox "Inbox" Reply Trash} line
    set posL [lindex $dividerLine 0]
    set pat  {([0-9]+).*mailbox "(.+)".*(Reply).*(Reply To All).*(Trash)}
    set pos  [minPos -w $w]
    set msgLine [search -w $w -s -n -f 1 -r 1 -l $posL -- $pat $pos]
    if {[llength $msgLine]} {
        set pos0 [pos::lineStart -w $w     [lindex $msgLine 0]]
	set pos1 [pos::nextLineStart -w $w [lindex $msgLine 1]]
	set text [getText -w $w $pos0 $pos1]
	regexp -indices $pat $text -> number folder reply replyToAll trash
	set pos  $pos0
	# Mail index number.
	set pos0 [pos::math -w $w $pos + [lindex $number 0]]
	set pos1 [pos::math -w $w $pos + [lindex $number 1] + 1]
	text::color -w $w $pos0 $pos1 bold
	# Mail folder name.
	set pos0 [pos::math -w $w $pos + [lindex $folder 0]]
	set pos1 [pos::math -w $w $pos + [lindex $folder 1] + 1]
	text::color -w $w $pos0 $pos1 bold
	# "Reply" hyperlink
	set pos0 [pos::math -w $w $pos + [lindex $reply 0]]
	set pos1 [pos::math -w $w $pos + [lindex $reply 1] + 1]
	text::color -w $w $pos0 $pos1 "4"
	text::hyper -w $w $pos0 $pos1 "Mail::replyToEmail 0"
	# "Reply To All" hyperlink
	set pos0 [pos::math -w $w $pos + [lindex $replyToAll 0]]
	set pos1 [pos::math -w $w $pos + [lindex $replyToAll 1] + 1]
	text::color -w $w $pos0 $pos1 "4"
	text::hyper -w $w $pos0 $pos1 "Mail::replyToEmail 1"
	# "Trash" hyperlink
	set pos0 [pos::math -w $w $pos + [lindex $trash 0]]
	set pos1 [pos::math -w $w $pos + [lindex $trash 1] + 1]
	text::color -w $w $pos0 $pos1 "4"
	text::hyper -w $w $pos0 $pos1 "Mail::trashMessage"
    } 
    # If we can only color the Msg line, then stop now.
    if {$msgLineOnly} {
        refresh
	return
    } 
    # Color our e-mail header fields.
    set posL [lindex $dividerLine 0]
    set pat  {^[-\w]+:}
    set pos  [minPos -w $w]
    while {1} {
	set headerField [search -w $w -n -f 1 -r 1 -l $posL -- $pat $pos]
	if {![llength $headerField]} {
	    break
	} 
	eval [list text::color -w $w] $headerField 1
	set pos [pos::nextLineStart -w $w [lindex $headerField 1]]
    }
    # Color our divider line.
    eval [list text::color -w $w] $dividerLine 5
    # Colorize quoted (comment) lines in the body of the e-mail.  We also
    # colorize lines that start with the canonical ">" character, but also
    # check for other common characters.
    if {$MailmodeVars(quotedTextShouldBe)} {
	set quoteCharacters [list ">" "\\|"]
	if {$alphaTclMail} {
	    lappend quoteCharacters " *\#"
	}
	set pat "^([join [lunique $quoteCharacters] {|}])"
	set pos [pos::nextLineStart [lindex $dividerLine 0]]
	while {1} {
	    set quotedLine [search -w $w -s -n -f 1 -r 1 -- $pat $pos]
	    if {![llength $quotedLine]} {
		break
	    } 
	    set pos0 [lindex $quotedLine 0]
	    set pos1 [pos::lineEnd -w $w $pos0]
	    if {[regexp {1|3} $MailmodeVars(quotedTextShouldBe)]} {
		text::color -w $w $pos0 $pos1 $MailmodeVars(quoteColor)
	    } 
	    if {[regexp {2|3} $MailmodeVars(quotedTextShouldBe)]} {
		text::color -w $w $pos0 $pos1 italic
	    } 
	    set pos [pos::nextLineStart $pos0]
	    if {[pos::compare -w $w $pos == [maxPos -w $w]]} {
		break
	    } 
	}
    } 
    # Color, hyperlink other text.
    set textToHyper [list]
    set textToColor [list]
    # Special case for AlphaTcl e-mails.
    if {$alphaTclMail} {
	help::hyperiseExtras 1
	set pattern {\[([-\w:]+)\]}
	win::searchAndHyperise $pattern {Tcl::DblClickHelper \1} 1 4 +1 -1 
    } 
    # Hyperlink urls.
    set pattern {(^|[^a-zA-Z])((https?|news|mailto|ftp):[^\]\s:\"<>]+)([^[:alnum:]]|$)}
    set matches [search -w $w -all -n -s -f 1 -r 1 -- $pattern [minPos]]
    for {set i 0} {($i < [llength $matches])} {incr i} {
	set pos0 [lindex $matches $i]
	set pos1 [lindex $matches [incr i]]
	regexp -- $pattern [getText -w $w $pos0 $pos1] -> pre url dummy post
	set pos0 [pos::math -w $w $pos0 + [string length $pre]]
	set pos1 [pos::math -w $w $pos1 - [string length $post]]
	if {([string index $url end] eq ".")} {
	    set pos1 [pos::math -w $w $pos1 - 1]
	    set url  [string range $url 0 end-1]
	} 
	lappend textToHyper [list $pos0 $pos1 "urlView $url"]
    }
    set pattern {(^|[<\s\"])(www\.[^\s:\"<>]+)([^[:alnum:]]|$)}
    set matches [search -w $w -all -n -s -f 1 -r 1 -- $pattern [minPos]]
    for {set i 0} {($i < [llength $matches])} {incr i} {
	set pos0 [lindex $matches $i]
	set pos1 [lindex $matches [incr i]]
	regexp -- $pattern [getText -w $w $pos0 $pos1] -> pre www post
	set pos0 [pos::math -w $w $pos0 + [string length $pre]]
	set pos1 [pos::math -w $w $pos1 - [string length $post]]
	if {([string index $www end] eq ".")} {
	    set pos1 [pos::math -w $w $pos1 - 1]
	    set url  [string range $www 0 end-1]
	} 
	lappend textToHyper [list $pos0 $pos1 "urlView http://$www"]
    }
    # Hyperlink "mailto" links,
    set pattern {(^|[<\s\"])([-+\w.]+@[-+\w.]+[\w])([^[:alnum:]]|$)}
    set matches [search -w $w -all -n -s -f 1 -r 1 -- $pattern [minPos]]
    for {set i 0} {($i < [llength $matches])} {incr i} {
	set pos0 [lindex $matches $i]
	set pos1 [lindex $matches [incr i]]
	regexp -- $pattern [getText -w $w $pos0 $pos1] -> pre email post
	set pos0 [pos::math -w $w $pos0 + [string length $pre]]
	set pos1 [pos::math -w $w $pos1 - [string length $post]]
	if {([string index $email end] eq ".")} {
	    set pos1  [pos::math -w $w $pos1 - 1]
	    set email [string range $email 0 end-1]
	} 
	lappend textToHyper [list $pos0 $pos1 "Mail::newEmailWindow $email"]
    }
    # Attempt to render html colors/hypers.
    set pos [minPos]
    for {set i 0} {($i < [llength $htmlCache])} {incr i} {
	set htmlMarkerPat "[string repeat \t 24]∞∞∞${i}∞∞∞"
	set match [search -w $w -n -s -f 1 -- $htmlMarkerPat $pos]
	if {![llength $match]} {
	    break
	} 
	set pos [pos::nextLineStart -w $w [lindex $match 1]]
	set pos [pos::nextChar -w $w $pos]
	# Colors which aren't hyperlinks
	foreach item [lindex $htmlCache $i 0] {
	    set pos0   [pos::math -w $w $pos + [lindex $item 0]]
	    set pos1   [pos::math -w $w $pos + [lindex $item 1]]
	    # We attempt to avoid colorizing across empty space if
	    # possible.
	    set txt    [string trimleft  [getText -w $w $pos0 $pos1]]
	    set pos0   [pos::math -w $w $pos1 - [string length $txt]]
	    set txt    [string trimright [getText -w $w $pos0 $pos1]]
	    set pos1   [pos::math -w $w $pos0 + [string length $txt]]
	    lappend textToColor [list $pos0 $pos1 [lindex $item 2]]
	}
	# Links
	foreach item [lindex $htmlCache $i 1] {
	    set pos0   [pos::math -w $w $pos + [lindex $item 0]]
	    set pos1   [pos::math -w $w $pos + [lindex $item 1]]
	    set link   [lindex $item 2]
	    set target [lindex $item 3]
	    if {($link eq "IndexSearch") || [regexp {^(FORM)} $link]} {
		continue
	    } elseif {([string index $link 0] eq "\#")} {
		# We can't handle links to anchors in the same window (yet).
		continue
	    } elseif {[catch {url::makeAbsolute $link $target} url]} {
		continue
	    }
	    # We attempt to avoid hyperlinking across empty space if
	    # possible.
	    set txt    [string trimleft  [getText -w $w $pos0 $pos1]]
	    set pos0   [pos::math -w $w $pos1 - [string length $txt]]
	    set txt    [string trimright [getText -w $w $pos0 $pos1]]
	    set pos1   [pos::math -w $w $pos0 + [string length $txt]]
	    lappend textToHyper [list $pos0 $pos1 [list urlView $url]]
	}
    }
    # Add our cached colors and hyperlinks.
    set posBegs [list]
    set posEnds [list]
    foreach item $textToHyper {
	set pos0  [lindex $item 0]
	set pos1  [lindex $item 1]
	set diff0 [pos::diff -w $w $pos0 [minPos -w $w]]
	set diff1 [pos::diff -w $w $pos1 [minPos -w $w]]
	if {([lsearch -exact $posBegs $diff0] > -1) \
	  || ([lsearch -exact $posEnds $diff1] > -1)} {
	    continue
	} 
	text::color -w $w $pos0 $pos1 3
	text::hyper -w $w $pos0 $pos1 [lindex $item 2]
	lappend posBegs $diff0
	lappend posEnds $diff1
    }
    foreach item $textToColor {
	set pos0  [lindex $item 0]
	set pos1  [lindex $item 1]
	set diff0 [pos::diff -w $w $pos0 [minPos -w $w]]
	set diff1 [pos::diff -w $w $pos1 [minPos -w $w]]
	if {([lsearch -exact $posBegs $diff0] > -1) \
	  || ([lsearch -exact $posEnds $diff1] > -1)} {
	    continue
	} 
	text::color -w $w $pos0 $pos1 [lindex $item 2]
    }
    # Reset our cache information.
    set htmlCache [list]
    # An explicit [refresh] is now required.
    refresh -w $w
    return
}

# ===========================================================================
# 
# .