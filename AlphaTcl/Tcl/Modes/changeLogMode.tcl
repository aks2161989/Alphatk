#################################################################################
# change log mode.
# 
# You should not remove this file.  Alpha may not function very well
# without it.
#================================================================================

alpha::mode [list Chng "Change Log"] 0.2 source {Change*} {
} {
} description {
    Provides support for displaying Alpha "Changes" files
} help {
    Chng mode is used for Alpha's 'Changes' files, recording recent
    changes made to the application or its Tcl libraries.  The help file
    "Changes - AlphaTcl" is an example of such a file.  This mode has
    its own marking scheme, and will colorize all lines with "=" red.

    This mode is not particularly intended for text editing.
}

newPref var fillColumn 80 Chng
newPref var wordBreak {(\$)?[\w:_.]*[\w]+} Chng
newPref var prefixString "¥ " Chng

newPref v lineWrap {1} Chng
# '=' starts a comment, bullets are specially coloured,
# and strings are green.  If we have the '-begin' flag,
# then '=' only takes effect at the beginning of the line.
if {${alpha::platform} == "alpha"} {
    regModeKeywords -e "=" -i "¥" -I blue -s green Chng {}
} else {
    regModeKeywords -begin "^(\[ \t\]*=.*)" -i "¥" -I blue -s green Chng {}
}

namespace eval Chng {}

newPref f autoMark {0} Chng

# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn 0 Chng

proc Chng::MarkFile {args} {
    win::parseArgs w
    status::msg "Marking '[win::Tail $w]'É"
    set pat1 {([\w./ ]+[0-9]+)}
    set pat2 {((in)|(last)|(released)|([-0-9]+))}
    set pat  "^=\\s+${pat1}\[\t \]+${pat2}"
    set pos  [minPos -w $w]
    while {1} {
	set pp [search -w $w -n -s -f 1 -r 1 -m 0 -i 1 -- $pat $pos]
	if {![llength $pp]} {
	    break
	}
	set pos0 [lindex $pp 0]
	set pos1 [lindex $pp 1]
	regexp -nocase -- $pat [getText -w $w $pos0 $pos1] allofit mark
	set mark [string trim $mark]
	setNamedMark -w $w $mark [pos::prevLineStart -w $w $pos0] $pos0 $pos0
	set pos  [pos::nextLineStart -w $w $pos1]
    }
    status::msg "Marking '[win::Tail $w]'É complete"
}

proc Chng::correctIndentation {args} {
    win::parseArgs w pos {next ""}
    
    if {[pos::compare -w $w [set beg [lineStart -w $w $pos]] == [minPos]]} { 
	return 0 
    }
    regexp "^(\[ \t\]*)(\[^ \t\r\n\])?" \
      [getText -w $w [pos::prevLineStart -w $w $beg] $beg] -> white char
    if {![string length $char]} {return 0}
    set indent [string length [text::maxSpaceForm -w $w $white]]
    if {$char == "¥"} {
	incr indent 2
    }
    if {[string index $next 0] == "¥"} {
	incr indent -2
    }
    if {$indent < 0} { set indent 0}
    return $indent
}

proc Chng::DblClick {args} {
    eval Tcl::DblClick $args
    return
}

# This could be bound to Command-I to avoid filling long "paragraphs" that
# consist of a long list of change log comments.

Bind 'i' <cs> {Chng::fillChangeComment} Chng

## 
 # --------------------------------------------------------------------------
 # 
 # "Chng::fillChangeComment" --
 # 
 # A modified version of [paragraph::fillOne] that ensures that attempting to
 # "Text > Fill Paragraph" a window that is recognized as one long paragraph
 # won't try to fill the entire file.  It also takes some special ChangeLog
 # formatting into account:
 # 
 # * The start of a "change log comment" is a bullet, else is indicated by an
 # empty line or the first text following a "===..."  line.
 # 
 # * A first line of a change log comment starting with a bullet will start
 # in column 0, all other lines in that comment will be indented.
 # 
 # * AlphaTcl's "doubleSpaces" pref is still taken into account, although
 # that could be easily disabled if desired.
 # 
 # --------------------------------------------------------------------------
 ##

proc Chng::fillChangeComment {} {
    
    global fillColumn doubleSpaces
    
    set pos [getPos]
    # Preliminaries.
    if {([lookAt [pos::lineStart $pos]] eq "=")} {
	error "Cancelled -- cannot fill in '=' lines."
    } elseif {[pos::compare [pos::lineEnd $pos] == [pos::lineStart $pos]]} {
	# Empty line.
	error "Cancelled -- cannot fill empty lines."
    } 
    set pat1 {(^¥[\t ]+)|((\r|\r*\n)[\t ]*(\r|\r*\n))|(===\s+)}
    set pat2 {(^¥[\t ]+)|((\r|\r*\n)[\t ]*(\r|\r*\n))|(\s+===+)}
    # Find the start of this change log comment.
    set pos1 [pos::math [pos::lineEnd $pos] - 1]
    set match1 [search -n -s -f 0 -r 1 -- $pat1 $pos1]
    if {[llength $match1]} {
	set posBeg [pos::lineStart [lindex $match1 1]]
    } else {
	set posBeg [pos::lineStart $pos]
    }
    # Find the end of this change log comment.
    if {[pos::compare [pos::lineStart [selEnd]] == [selEnd]]} {
	set pos2 [pos::math [pos::prevLineEnd [selEnd]] - 1]
    } else {
	set pos2 [pos::math [pos::lineEnd [selEnd]] - 1]
    }
    set match2 [search -n -s -f 1 -r 1 -- $pat2 $pos2]
    if {[llength $match2]} {
	if {([lookAt [lindex $match2 0]] eq "¥")} {
	    set posEnd [pos::lineStart [lindex $match2 0]]
	} else {
	    set posEnd [pos::nextLineStart [lindex $match2 0]]
	}
    } else {
	set posEnd [pos::lineEnd [selEnd]]
    }
    # Confirm that our positions make sense.
    if {[pos::compare $posBeg > $pos]} {
	error "Cancelled -- couldn't identify start of change comment."
    } elseif {[pos::compare $posEnd < [selEnd]]} {
	error "Cancelled -- couldn't identify end of change comment."
    }
    # Manipulate the text to fill the change log comment.
    regsub -all -- {\s+} [getText $posBeg $posEnd] " " text
    if {$doubleSpaces} {
	regsub -all -- \
	  {(([^.][a-z]|[^a-zA-Z@]|\\@)[.?!]([])'"]|'')?) } \
	  $text {\1  } text
    }
    if {[regexp {^¥\s+} $text]} {
	# Get the first line.
	if {[info exists fillColumn]} {
	    set rightColumn $fillColumn
	} else {
	    set rightColumn 80
	}
	set textLines [split [breakIntoLines $text $rightColumn 0] "\r"]
	set firstLine [lindex $textLines 0]
	regsub -all -- {\s+} [join [lrange $textLines 1 end] " "] " " theRest
	if {$doubleSpaces} {
	    regsub -all -- \
	      {(([^.][a-z]|[^a-zA-Z@]|\\@)[.?!]([])'"]|'')?) } \
	      $theRest {\1  } theRest
	}
	set theRest [breakIntoLines $theRest $rightColumn 2]
	append newText $firstLine "\r" $theRest
    } else {
	paragraph::getLeadingIndent $posBeg leftColumn
	if {[info exists fillColumn]} {
	    set rightColumn [expr {$fillColumn - $leftColumn}]
	} else {
	    set rightColumn [expr {80 - $leftColumn}]
	}
	set newText [breakIntoLines $text $rightColumn $leftColumn]
    }
    set newText "[string trimright $newText]\r"
    # Replace text as necessary.
    if {![isSelection]} {
	set memory [paragraph::rememberWhereYouAre $posBeg $pos $posEnd]
	replaceText $posBeg $posEnd $newText
	paragraph::goBackToWhereYouWere $posBeg \
	  [pos::math $posBeg + [string length $newText]] $memory
    } else {
	replaceAndSelectText $posBeg $posEnd $newText
    }
    return
}

# ===========================================================================
# 
# .