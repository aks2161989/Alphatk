namespace eval tiphtml {
    variable curlev -1
    variable contexts {}
    proc enterlistcontext {level good bad1 bad2} {
	variable curlev
	variable contexts
	if {$level > $curlev} {
	    incr curlev
	    lappend contexts "</$good>"
	    puts -nonewline "<$good compact>"
	}
	switch [lindex $contexts end] "</$bad1>" - "</$bad2>" {
	    puts -nonewline [lindex $contexts end]
	    puts -nonewline "<$good compact>"
	    set contexts [lreplace $contexts end end "</$good>"]
	}
    }
    proc closecontext {{level -1}} {
	variable curlev
	variable contexts
	while {$level < $curlev} {
	    incr curlev -1
	    puts -nonewline [lindex $contexts end]
	    set contexts [lrange $contexts 0 [expr {[llength $contexts]-2}]]
	}
    }
    proc quoteLiteral {string} {
	regsub -all &  $string {\&amp;}  string
	regsub -all <  $string {\&lt;}   string
	regsub -all >  $string {\&gt;}   string
	regsub -all \" $string {\&quot;} string
	return $string
    }

    proc section {title} {
	closecontext
	puts "<h2>[quoteLiteral $title]</h2>"
    }
    proc ordinary {string} {
	continuation -1 $string
    }
    proc bulleting {level body} {
	closecontext $level
	enterlistcontext $level ul ol dl
	puts -nonewline "<li>"
	continuation $level $body
    }
    proc description {tag level body} {
	closecontext $level
	enterlistcontext $level dl ol ul
	puts -nonewline "<dt>$tag</dt><dd>"
	continuation $level $body
    }
    proc enumeration {tag level body} {
	closecontext $level
	enterlistcontext $level ol dl ul
	if {$tag != 1} {
	    puts -nonewline "<li value=$tag>"
	} else {
	    puts -nonewline "<li>"
	}
	continuation $level $body
    }
    proc continuation {level body} {
	global EmailRE URLRE TIPURLRE ShortTIPRE BASEURL
	closecontext $level
	regsub -all $EmailRE $body "<mailto:\\1>" body
	regsub -all $TIPURLRE $body "$BASEURL\\1.html" body
	set body [quoteLiteral $body]
	regsub -all $URLRE $body "<a href=\"&\">&</a>" body
	regsub -all {''(('?[^'])+)''} $body "<em>\\1</em>" body
	regsub -all $ShortTIPRE $body "<a href=\"\\1.html\">TIP #\\1</a>" body
	regsub -all {\[\[} $body \[ body
	regsub -all {\]\]} $body \] body
	variable curlev
	if {$curlev==-1 && $level==1} {
	    puts "<blockquote><p align=justify>$body</p></blockquote>"
	} else {
	    puts "<p align=justify>$body</p>"
	}
    }
    proc separator {} {
	closecontext
	puts "<hr>"
    }
    proc verbatim {lines} {
	puts "<pre>"
	foreach line $lines {
	    # HTML ignores formfeed chars, but we want to see them...
	    regsub -all {} [quoteLiteral $line] "<b><u>^L</u></b>" line
	    puts $line
	}
	puts -nonewline "</pre>"
    }

    proc tr {c1 c2 {size 1}} {
	puts -nonewline "<tr><td align=right valign=top><font size=$size>$c1"
	puts "</font></td><td><font size=$size>$c2</font></td></tr>"
    }
    proc index {kind {errorKind soft}} {
	closecontext
	# Kinds of indices?  short, medium, long, bibtex
	switch -- $kind {
	    short {
		foreachTIP d {
		    puts -nonewline "<p><a href=\"$d(TIP).html\"><font\
			    size=2>TIP #$d(TIP):"
		    switch $d(State) {
			Draft {
			    puts -nonewline " <font color=green>Draft</font>"
			}
			Rejected {
			    puts -nonewline " <font color=red>Rejected</font>"
			}
		    }
		    puts "<br>$d(Title)</font></a></p>"
		}
	    }
	    medium {
		puts "<blockquote><table width=\"85%\"><tr align=left>"
		puts "<th><font size=2>Series&nbsp;ID</font></th>"
		puts "<th><font size=2>Type</font></th>"
		puts "<th><font size=2>State</font></th>"
		puts "<th width=300><font size=2>Title</font></th></tr>"
		puts -nonewline "<tr><td colspan=4><hr></td></tr>"
		foreachTIP d {
		    puts "<tr>"
		    puts "<td valign=baseline><font\
			    size=2>TIP #$d(TIP)</font></td>"
		    puts "<td valign=baseline><font\
			    size=1>$d(Type)</font></td>"
		    puts "<td valign=baseline><font\
			    size=1>$d(State)</font></td><td>"
		    puts "<font size=2><a\
			    href=\"$d(TIP).html\">$d(Title)</a></font>"
		    puts -nonewline "</td></tr>"
		}
		puts "</table></blockquote>"
	    }
	    long {
		foreachTIP d {
		    puts "<p><table width=\"99%\"><tr><td valign=top>"

		    puts -nonewline "<a href=\"$d(TIP).html\">"
		    puts "<b><font size=4>TIP #$d(TIP): $d(Title)</font></b>"
		    puts "</a><dl><dt><tt>$d(Version)</tt></dt><dd>"
		    ordinary $d(Abstract)
		    puts "</dd></dl>"

		    puts "</td><td valign=top><table border><tr><td><table>"
		    set at "Author:"
		    global AuthorRE
		    foreach a $d(Author) {
			regexp "^$AuthorRE" $a -> name mail
			tr $at "<a href=\"mailto:$mail\">$name</a>"
			set at ""
		    }
		    tr Type: $d(Type)
		    if {[info exist d(Tcl-Version)]} {
			tr "Tcl Version:" $d(Tcl-Version)
		    }
		    tr State: $d(State)
		    tr Vote: $d(Vote)
		    tr Created: [clock format $d(Created) \
			    -format "%d %b %Y" -gmt 1]
		    tr "Posting History:" \
			    [join [split $d(Post-History) ","] "<br>"]
		    if {[info exist d(Discussions-To)]} {
			tr "Discussions To:" $d(Discussions-To)
		    }
		    if {[info exist d(Obsoletes)]} {
			tr Obsoletes: "<a href=\"$d(Obsoletes).html\"\
				>TIP #$d(Obsoletes)</a>"
		    }
		    if {[info exist d(Obsoleted-By)]} {
			tr "Obsoleted By:" "<a href=\"$d(Obsoleted-By).html\"\
				>TIP #$d(Obsoleted-By)</a>"
		    }
		    if {[info exist d(Keywords)]} {
			tr Keywords: [join $d(Keywords) ", "]
		    }
		    puts "</table></td></tr></table></td></tr></table>"
		}
	    }
	    default {
		if {[string compare $errorKind soft]} {
		    return -code error "Index style $kind not supported"
		}
		puts "<p align=justify><font color=red>Index\
			style \"$kind\" not yet supported!</font></p>"
	    }
	}
    }
    if {![llength [info command ::imwidth::getImageWidth]]} {
	source $SRCDIR/imwidth.tcl
    }
    proc image {bodytext} {
	global ImageRE DOCDIR contenttypes
	closecontext
	set caption {}
	set w 0
	regexp $ImageRE [string trim $bodytext] -> url caption
	if {[regexp {^[-_a-zA-Z0-9]+$} $url]} {
	    foreach {ext type} [array get contenttypes] {
		# Order is random, but shouldn't matter.
		if {
		    [string match image/* $type] && 
		    [file exists [set f [file join $DOCDIR $url$ext]]]
		} then {
		    set w [::imwidth::getImageWidth $f]
		    set url $url$ext
		    break
		}
	    }
	}
	set imgtag [format {img src="%s"} $url]
	if {[string length $caption]} {
	    append imgtag " alt=\"[quoteLiteral $caption]\""
	}
	if {$w > 450} {
	    set imgtag "a href=\"$url\"><$imgtag width=\"85%\"></a"
	} elseif {$w > 0} {
	    append imgtag " width=$w"
	}
	puts "<div align=center><p><$imgtag></p></div>"
    }

    proc fmtauthor {author} {
	global AuthorRE
	regexp "^$AuthorRE$" $author -> name email
	set name [string trim $name]
	if {[string length $name]} {
	    return "$name &lt;<a href=\"mailto:$email\">$email</a>&gt;"
	} else {
	    return "<a href=\"mailto:$email\">$email</a>"
	}
    }

    proc generateDocument {head body} {
	# generate HTML header
	array set h $head
	global BASETARG BASEURL CSSURL
	puts "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\"\
		\"http://www.w3.org/TR/REC-html40/loose.dtd\">"
	puts "<html><head><title>TIP #$h(TIP): $h(Title)</title>"
	puts "<meta http-equiv=\"charset\" content=\"iso-8859-1\">"
	puts "<base href=\"$BASEURL\" target=\"$BASETARG\">"
	if {[info exist h(Keywords)]} {
	    set keywords [join $h(Keywords) ", "]
	    puts "<meta name=\"Keywords\" content=\"$keywords\">"
	}
	puts "<link rel=stylesheet type=\"text/css\"\
		title=\"My standard style\" href=\"$CSSURL\">"
	puts "</head><body bgcolor=\"#d9d9d9\">"
	puts "<h1>TIP #$h(TIP): $h(Title)</h1><hr><table>"
	puts "<tr><td align=right>TIP:</td><td>$h(TIP)</td></tr>"
	puts "<tr><td align=right>Title:</td><td>$h(Title)</td></tr>"
	puts "<tr><td align=right>Version:</td><td><tt>$h(Version)</tt></td></tr>"
	switch [llength $h(Author)] {
	    0 {}
	    1 {
		set a [fmtauthor [lindex $h(Author) 0]]
		puts "<tr><td align=right>Author:</td><td>$a</td></tr>"
	    }
	    default {
		puts "<tr><td align=right valign=baseline>Authors:</td><td>"
		foreach a $h(Author) {puts "[fmtauthor $a]<br>"}
		puts "</td></tr>"
	    }
	}
	foreach tag {State Type Tcl-Version Vote} {
	    if {[info exist h($tag)] && [string length $h($tag)]} {
		puts "<tr><td align=right>${tag}:</td><td>$h($tag)</td></tr>"
	    }
	}
	set t [clock format $h(Created) -format {%A, %d %B %Y} -gmt 1]
	puts "<tr><td align=right>Created:</td><td>$t</td></tr>"
	foreach tag {Post-History} {
	    if {[string length $h($tag)]} {
		puts "<tr><td align=right>${tag}:</td><td>$h($tag)</td></tr>"
	    }
	}
	if {
	    [info exist h(Discussions-To)] &&
	    [string length $h(Discussions-To)]
	} {
	    puts -nonewline "<tr><td align=right>Discussions To:</td><td>"
	    global URLRE
	    set dt $h(Discussions-To)
	    if {[regexp $URLRE $dt]} {
		puts "<a href=\"$dt\">$dt</a></td></tr>"
	    } else {
		puts "$dt</td></tr>"
	    }
	}
	foreach tag {Obsoletes Obsoleted-By} {
	    if {[info exist h($tag)] && [string length $h($tag)]} {
		puts "<tr><td align=right>${tag}:</td><td><a\
			href=\"$h($tag)\">TIP #$h($tag)</a></td></tr>"
	    }
	}
	if {[info exist h(Keywords)]} {
	    puts "<tr><td align=right valign=baseline>Keywords:</td><td\
		    >[join $h(Keywords) {, }]</td></tr>"
	}
	puts "</table><hr>"

	# generate HTML body
	foreach par $body {
	    eval [intuitParagraphKind $par]
	}

	# generate HTML footer
	separator
	global FOOTERTEXT
	puts "<p>\[<a href=\"$h(TIP).html\">HTML</a>\]\
		\[<a href=\"$h(TIP).txt\">Plain Text</a>\]\
		\[<a href=\"$h(TIP).tip\">Source</a>\]\
		\[<a href=\"$h(TIP).tex\">LaTeX</a>\]\
		\[<a href=\"$h(TIP).xml\">XML <i>experimental!</i></a>\]\
		</p>"
	puts "<address>$FOOTERTEXT</address></body></html>"
    }
}
