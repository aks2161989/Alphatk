#! /usr/local/bin/tclsh8.0

# Regular expressions - suitable for 8.0 as well as later.
set ws "\[ \t\n\]"
set ParSepRE      "^$ws*$"
set RFC822ContRE  "^$ws"
set RFC822DataRE  "^(\[^ \t:\]+):$ws+(.*)$"
set RFC822EmptyRE "^(\[^ \t:\]+):$"
set ItemNoLeadRE  "^\[^ \t>\]"
set ItemLeadRE "^$ws*((>$ws+)*)(\\*|\[0-9\]+\\.|\[^\t\n:\]+:)$ws"
set ItemContRE "^($ws+>)+$ws*"
# RE's for (optional) use in paragraphs
set AuthorRE "(.*)$ws+<(\[^:@\]+@\[^:@\]+)>"
set ImageRE "^(\[^ \t\n\]+)$ws*(.*)$"
set EmailRE {<([^<>@]+@[^<>@]+)>}
set URLRE {(http|ftp|news|newsrc|mailto|gopher):[-A-Za-z0-9/_.#+@?=&;~]+}
set TIPURLRE {tip:([0-9]+)}
set ShortTIPRE {\[([0-9]+)\]}

# # Regular expressions - suitable for 8.1 and later only.  It is
# # easier to understand the above by looking at the below and
# # translating...  :^)
# 
# set ParSepRE      {^\s*$}
# set RFC822ContRE  {^\s}
# set RFC822DataRE  {^([^\s:]+):\s*(.*)$}
# set RFC822EmptyRE {^([^\s:]+):\s*$}
# set ItemNoLeadRE  {^[\s>]}
# set ItemLeadRE    {^\s*((>\s+)*)(\*|\d+\.|[^\t\n:]+:)\s}
# set ItemContRE    {^(\s+>)+\s*}
# # RE's for (optional) use in paragraphs
# set AuthorRE {(.*?)\s+<(.*)>}
# set ImageRE {^(\S+)\s*(.*)$}
# set EmailRE {<([^<>@]+@[^<>@]+)>}
# set URLRE {(?:http|ftp|news|newsrc|mailto|gopher):[-A-Za-z0-9/_.#+@]+}
# set TIPURLRE {tip:([0-9]+)}
# set ShortTIPRE {\[([0-9]+)\]}
# 
# # Note that ItemLeadRE would be clearer if written as:
# #     ^\s*((?:>\s+)*)(\*|\d+\.|[^\t\n:]+:)\s
# # but that would be incompatible with the 8.0 version.

proc splitIntoParagraphs {string} {
    global ParSepRE
    set paragraphs {}
    set current {}
    foreach line [split $string "\n"] {
	if {[regexp $ParSepRE $line]} {
	    # (VISUALLY) BLANK LINE = PARAGRAPH SEPARATOR
	    if {[string length $current]} {
		lappend paragraphs [string trim $current "\n"]
		set current {}
	    }
	    continue
	}
	append current "\n$line"
    }
    if {[string length $current]} {
	lappend paragraphs [string trim $current "\n"]
    }
    return $paragraphs
}

proc splitRFC822Header {paragraph} {
    global RFC822ContRE RFC822DataRE RFC822EmptyRE
    set properlines {}
    set current {}
    foreach line [split $paragraph "\n"] {
	if {[regexp $RFC822ContRE $line]} {
	    append current $line
	    continue
	}
	if {[string length $current]} {
	    if {[regexp $RFC822DataRE $current -> tag value]} {
		lappend properlines $tag $value
	    } elseif {[regexp $RFC822EmptyRE $current -> tag]} {
		lappend properlines $tag {}
	    } else {
		return -code error "header \"$current\" malformatted"
	    }
	}
	set current $line
    }
    if {[string length $current]} {
	if {[regexp $RFC822DataRE $current -> tag value]} {
	    lappend properlines $tag $value
	} elseif {[regexp $RFC822EmptyRE $current -> tag]} {
	    lappend properlines $tag {}
	} else {
	    return -code error "header \"$current\" malformatted"
	}
    }
    return $properlines
}

# takes output of splitRFC822Header
proc verifyTIPheader {headerlines} {
    array set headers {}
    array set permitted {
	TIP		{^[0-9]+$}
	Title		{.}
	Version		{^\$.*\$ *$}
	Author		{<.+@.+\..+>}
	State		{^(Draft|Active|Accepted|Deferred|Final|Rejected|Withdrawn)$}
	Type		{^(Process|Project|Informati(ve|on(al)?))$}
	Vote		{^(Pending|In progress|Done|No voting)$}
	Created		{^[0-3][0-9]-[A-Z][a-z][a-z]-2[0-9][0-9][0-9]$}
	Post-History	{.*}
	Tcl-Version	{^[0-9]+\.[0-9]+([ab.][0-9]+)?$}
	Discussions-To	{.}
	Obsoletes	{^[0-9]+$}
	Obsoleted-By	{^[0-9]+$}
	Keywords	{.}
    }
    set required {
	TIP Title Version Author State Type Vote Created Post-History
    }

    foreach {tag value} $headerlines {
	if {![info exists permitted($tag)]} {
	    return -code error "header \"${tag}: $value\" not understood"
	}
	if {![regexp $permitted($tag) $value]} {
	    return -code error "header \"${tag}: $value\" malformatted"
	}
	if {[string compare $tag Author]} {
	    if {[info exists headers($tag)]} {
		return -code error "header for \"${tag}:\" can only occur once"
	    }
	    set headers($tag) $value
	} else {
	    lappend headers($tag) $value
	}
    }
    foreach tag $required {
	if {![info exist headers($tag)]} {
	    return -code error "header for \"${tag}:\" is required"
	}
    }
    if {[string match Info* $headers(Type)]} {
	set headers(Type) Informative
    }
    if {[info exist headers(Keywords)]} {
	set kws {}
	foreach keyword [split headers(Keywords) ","] {
	    regsub -all "\[ \t\n\]+" $keyword " " keyword
	    lappend kws [string trim $keyword]
	}
	set headers(Keywords) $kws
    }
    # This check is complex...
    if {[info exist headers(Tcl-Version)] != ![string compare $headers(Type) Project]} {
	return -code error "header \"Tcl-Version:\" iff a project TIP"
    }
    # Force the created header into processable form
    regsub -all -- - $headers(Created) " " date
    set headers(Created) [clock scan $date -gmt 1]
    # Now return as association list
    return [array get headers]
}

proc shortspc {string} {
    regsub -all {[ 	
    ]+} $string " " string
    return $string
}
proc intuitParagraphKind {paragraph} {
    switch -glob -- $paragraph {
	~* {
	    set content [string range $paragraph 1 end]
	    return [list section [string trim [shortspc $content]]]
	}
	|* {
	    set lines {}
	    foreach line [split $paragraph "\n"] {
		if {![string match |* $line]} {
		    return -code error "malformatted verbatim line \"$line\""
		}
		lappend lines [string range $line 1 end]
	    }
	    return [list verbatim $lines]
	}
	#index:* {
	    set type [string trim [string range $paragraph 7 end]]
	    if {![string length $type]} {set type medium}
	    return [list index $type]
	}
	#image:* {
	    return [list image [string range $paragraph 7 end]]
	}
	---- {
	    return {separator}
	}
    }

    global ItemNoLeadRE ItemLeadRE ItemContRE

    # Hmm.  Need to figure out if we've got a list item of some kind.
    if {[regexp $ItemNoLeadRE $paragraph]} {
	return [list ordinary [shortspc $paragraph]]
    }
    if {[regexp $ItemLeadRE $paragraph head continuation ? kind]} {
        set content [string range $paragraph [string length $head] end]
        set level [llength $continuation]
        switch -glob -- $kind {
	    *: {
		set kind [string trimright $kind ":"]
		return [list description $kind $level [shortspc $content]]
	    }
	    *. {
		set kind [string trimright $kind "."]
		return [list enumeration $kind $level [shortspc $content]]
	    }
	}
	return [list bulleting $level [shortspc $content]]
    }
    if {[regexp $ItemContRE $paragraph head]} {
	set content [string range $paragraph [string length $head] end]
	return [list continuation [llength $head] [shortspc $content]]
    }
    return [list ordinary [shortspc $paragraph]]
}

proc readTIPDetailsFromFile {filename} {
    set f [open $filename r]
    set content [read $f [file size $filename]]
    close $f

    foreach {headers title abstract} [splitIntoParagraphs $content] {
	break
    }
    set heads [verifyTIPheader [splitRFC822Header $headers]]
    if {[string compare [intuitParagraphKind $title] {section Abstract}]} {
	error "Must start with abstract..."
    }
    lappend heads Abstract [lindex [intuitParagraphKind $abstract] 1]
}
array set tipdetails {}
proc getTIPDetails {filename} {
    global tipdetails
    if {![info exist tipdetails($filename)]} {
	set tipdetails($filename) [readTIPDetailsFromFile $filename]
    }
    return $tipdetails($filename)
}
proc getTIPFilenames {} {
    global DOCDIR
    cd $DOCDIR
    lsort -dictionary [glob *.tip]
}
proc foreachTIP {arrayname script} {
    upvar 1 $arrayname ary
    foreach file [getTIPFilenames] {
	array set ary [getTIPDetails $file]
	uplevel 1 $script
	unset ary
    }
}

proc convert {in out {type html}} {
    set fin [open $in r]
    set indocument [read $fin [file size $in]]
    close $fin

    set cwd [pwd]
    set outdocument [formatTIPDocument $indocument $type]

    set fout [open [file join $cwd $out] w]
    puts -nonewline $fout $outdocument
    flush $fout
    close $fout
}

proc formatTIPDocument {string {type html}} {
    global SRCDIR
    set ns tip${type}
    source $SRCDIR/$ns.tcl

    set pars  [splitIntoParagraphs $string]
    set heads [verifyTIPheader [splitRFC822Header [lindex $pars 0]]]
    set par1  [intuitParagraphKind [lindex $pars 1]]
    if {[string compare $par1 {section Abstract}]} {
	return -code error "$in must start with abstract..."
    }

    global convert
    set convert {}
    proc ${ns}::puts {args} {
	global convert
	switch [llength $args] {
	    2 {append convert [lindex $args 1]}
	    1 {append convert [lindex $args 0] "\n"}
	}
    }
    ${ns}::generateDocument $heads [lrange $pars 1 end]

    return $convert
}

if {![info exist DOCDIR]} {
    set BASETARG   _self
    set BASEURL    http://www.cs.man.ac.uk/fellowsd-bin/TIP/
    set CSSURL     http://www.cs.man.ac.uk/~fellowsd/std.css
    set FOOTERTEXT "TIP AutoGenerator - written by Donal K. Fellows"
    set SRCDIR     [file join [pwd] [file dirname [info script]]]
    set DOCDIR     [file join $env(HOME) lang tcl TIP tips]
    # just some stub values; the CGI ifc has a fuller set.
    array set contenttypes {.html "text/html" .gif "image/gif"}

    set convertRE {^([-A-Za-z0-9]+).(html|txt|tex|xml)$}
    if {[regexp $convertRE [file tail [lindex $argv 0]] out id type]} {
	if {[catch {
	    set src "[file rootname [lindex $argv 0]].tip"
	    if {![file exists $src]} {
		set src [file join $DOCDIR $id.tip]
	    }
	    puts -nonewline "converting $src to $out..."
	    flush stdout
	    convert $src [lindex $argv 0] $type
	    puts " done"
	} err]} {
	    error $err
	}
    } else {
	error "Bad path specification"
    }
    exit
}
