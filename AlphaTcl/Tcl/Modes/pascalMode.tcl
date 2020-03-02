# (install)
alpha::mode [list Pasc Pascal] 1.0.7 dummyPascal {*.p} {
    thinkRefMenu toolboxRefMenu
} {
    set unixMode(pascal) {Pasc} 
} description {
    Supports the editing of Pascal programming files
} help {
    Pascal Mode provides keyword coloring and automatic line indention.
    Click on this "Pascal Example.p" link for an example syntax file.
}

newPref v leftFillColumn {3} Pasc
newPref v wordBreak {\w+} Pasc
newPref var lineWrap {0} Pasc
newPref v funcExpr {^(procedure|function)[^\r\n]*[;:(]} Pasc
newPref v parseExpr {^(procedure|function)[ \t]*([^\r\n]*)[ \t]*[;:(]} Pasc
newPref f autoMark	0 Pasc

# To automatically perform context relevant formatting after typing a
# semicolon, turn this item on||To have the semicolon key produce a
# semicolon without additional formatting, turn this item off
newPref flag electricSemicolon 1 Pasc
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn    1 Pasc

set pascKeyWords		{
    procedure function integer while with return var const unit type interface
    packed record begin end boolean if else repeat for downto case to of mod 
    goto file do then program or label div until set not in forward and
    implementation unit
}
regModeKeywords -C Pasc {}
regModeKeywords -a -b \{ \} -c red -k blue Pasc $pascKeyWords
unset pascKeyWords

# This kind of stuff is handled by Codewarrior menu etc.
# hook::register saveHook modified "Pasc"

#================================================================================

proc dummyPascal {} {}

set Pasc::commentCharacters(Paragraph) [list "(* " " *)" " * "]
set Pasc::quotedstringChar "'"

proc Pasc::MarkFile {args} {
    win::parseArgs win
    status::msg "Marking Window"
    set pos [minPos]
    set pat {^([ \t]*(program|procedure))+([\t ])+([a-zA-Z0-9]+[a-zA-Z0-9])+([;\t\r\n ])}
    while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 1 $pat $pos} match]} {
	set posBeg [lindex $match 0]
	regexp -nocase -- $pat [getText -w $win $posBeg [lindex $match 1]] \
	  allofit text1 text2 text3 text4
	setNamedMark -w $win $text4 $posBeg $posBeg $posBeg
	set pos [nextLineStart -w $win $posBeg]
    }
    status::msg ""
}

proc Pasc::indentLine {args} {
    win::parseArgs w
    # get details of current line
    set beg [pos::lineStart -w $w [getPos -w $w]]
    set text [getText -w $w $beg [pos::nextLineStart -w $w $beg]]
    regexp "^\[ \t\]*" $text white
    set len [string length $white]
    set epos [pos::math -w $w $beg + $len]
    
    # Find last previous non-comment line and get its leading whitespace
    set pos $beg
    while 1 {
	if {[catch {search -w $w -s -f 0 -r 1 -i 0 -m 0 "^\[ \t\]*\[^ \t\r\n\]" [pos::math -w $w $pos - 1]} lst]} {
	    # search failed at top of file
	    set line "#"
	    set lwhite 0
	    break
	}
	if {[text::isInDoubleComment -w $w [lindex $lst 0] res]} {
	    set pos [lindex $res 0]
	} else {
	    set line [getText -w $w [lindex $lst 0] [pos::math -w $w [pos::nextLineStart -w $w [lindex $lst 0]] - 1]]
	    set lwhite [lindex [pos::toRowCol -w $w [pos::math -w $w [lindex $lst 1] - 1]] 1]
	    break
	}
    }
    
    global electricColon
    set ia [text::getIndentationAmount -w $w]
    if {[regexp "begin\[ \t\]*$" $line]} {
	incr lwhite $ia
    }
    if {[regexp "end;?\[ \t\r\n\]*$" [getText -w $w $epos [pos::nextLineStart -w $w $epos]]]} {
	incr lwhite [expr -$ia]
    }
    set lwhite [text::indentOf -w $w $lwhite]
    if {$white != $lwhite} {
	replaceText -w $w $beg $epos $lwhite
    }
    goto -w $w [pos::math -w $w $beg + [string length $lwhite]]
}
