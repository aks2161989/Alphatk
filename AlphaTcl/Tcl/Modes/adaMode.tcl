
alpha::mode Ada 1.0.4 dummyAda {*.ada *.ads *.adb *_.a *.a } {
} {
    # Script to execute at Alpha startup
} uninstall {
    this-file
} maintainer {
} description {
    Supports the editing of Ada programming files
} help {
    The programming language Ada is named after Lady Ada Lovelace, daughter of
    famed poet Lord Byron and assistant to mathematician Charles Babbage, who
    invented the Analytical Machine.  Lady Ada is often considered to be the
    world's first programmer.

    A descendent of Pascal, Ada is object-oriented, and offers interfaces to
    the languages C, FORTRAN and COBOL. For more information about Ada, see
    <http://www.adahome.com>.

    Ada Mode provides keyword coloring and procedure marking with the Marks
    Menu.  Alpha includes an "Ada Example.ada" syntax file that demonstrates
    the mode.  In Alpha's Ada mode, The keyboard shortcut F9 will switch
    between the Ada spec & body, assuming they're in the same directory and
    use either GNAT or VAX Ada naming conventions.  Other conventions can be
    supported fairly easily.
}

#===============================================================================
# From Raymond Waldrop <rwaldrop@cs.tamu.edu>
#===============================================================================

newPref v leftFillColumn {3} Ada
newPref v prefixString {-- } Ada 
newPref v wordBreak {\w+} Ada
newPref v lineWrap {0} Ada
newPref v funcExpr {^[ \t]*(procedure|function)[ \t]+([A-Za-z][A-Za-z0-9_]*)} Ada
newPref v parseExpr {^[ \t]*[^ \t]+[ \t]+([A-Za-z][A-Za-z0-9_]*)} Ada
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn 0 Ada
# To automatically perform context relevant formatting after typing a left
# or right curly brace, turn this item on||To have the brace keys produce a
# brace without additional formatting, turn this item off
newPref flag electricBraces    1 Ada
# To automatically perform context relevant formatting after typing a
# semicolon, turn this item on||To have the semicolon key produce a
# semicolon without additional formatting, turn this item off
newPref flag electricSemicolon 1 Ada

set Ada::commentCharacters(General) "-- "
set Ada::commentCharacters(Paragraph) [list "-- " "-- " "-- "]

# Don't get used!
#set adaCommentRegexp	{/\*(([^*]/)|[^*]|\r)*\*/}
#set adaPreRegexp		{^\#[\t ]*[a-z]*}
set adaKeyWords		{
    abort abs accept access all and array at begin body case constant
    declare delay delta digits do else elsif end entry exception exit
    for function generic goto others if in is limited loop mod new not
    null of or subtype out package pragma private procedure raise range
    record rem renames return reverse select separate task terminate
    then type use when while with xor = /=  := > < abstract aliased 
    protected requeue tagged until
}
regModeKeywords -C Ada {}
regModeKeywords -a -e {--} -c red -k blue  \
  -i ")" -i "(" -i ":" -i ";" -i "," -i "." \
  -I green Ada $adaKeyWords
unset adaKeyWords

proc dummyAda {} {}

#===============================================================================
# From Tom Konantz
#===============================================================================

Bind f9 Ada::otherPart Ada

proc Ada::MarkFile {args} {
    
    global AdamodeVars
    
    win::parseArgs w
    
    status::msg "Marking \"[win::Tail $w]\" É"
    set pos  [minPos -w $w]
    set pat1 $AdamodeVars(funcExpr)
    set pat2 {(procedure|function)[ \t]+([a-zA-Z0-9_]+)}
    while {![catch {search -w $w -s -f 1 -r 1 -m 0 -i 1  -- $pat1 $pos} res]} {
	set start [lindex $res 0]
	set end   [pos::math -w $w [lindex $res 1] + 1]
	set text  [getText -w $w $start $end]
	if {[regexp -nocase -indices -- $pat2 $text dummy dummy0 pname]} {
	    set	i1 [pos::math -w $w $start + [lindex $pname 0]]
	    set	i2 [pos::math -w $w $start + [lindex $pname 1] + 1]
	    set	word [getText -w $w $i1 $i2]
	    set	tmp [list $i1 $i2]
	    
	    if {[info exists cnts($word)]} {
		# This section handles duplicate. i.e., overloaded names
		incr cnts($word)
		set ol_word [join [concat $word "#" $cnts($word)] ""]
		set inds($ol_word) $tmp
	    } else {
		set cnts($word) 1
		set inds($word) $tmp
	    }
	}
	
	set pos $end
    }
    set count 0
    if {[info exists inds]} {
	foreach f [lsort -dictionary [array names inds]] {
	    set res $inds($f)
	    setNamedMark -w $w $f \
	      [lineStart -w $w [lindex $res 0]] [lindex $res 0] [lindex $res 1]
	    incr count
	}
    }
    set msg "The window \"[win::Tail $w]\" contains $count mark"
    append msg [expr {($count == 1) ? "." : "s."}]
    status::msg $msg
    return
}

# the following will switch between the Ada spec & body,
# assuming they're in the same directory
# and use either GNAT or VAX Ada naming conventions.
# other conventions can be supported fairly easily.
proc Ada::otherPart {} {
    set curname [win::Current]
    if {[regsub  "(.*)\.ads" $curname {\1.adb} tgtname]}  {
	file::openQuietly $tgtname
    } elseif  {[regsub  "(.*)\.adb" $curname {\1.ads} tgtname]}  {
	file::openQuietly $tgtname
	# Next clause must precede the one after it!
    } elseif  {[regsub  {(.*)_\.a$} $curname {\1.a} tgtname]}  {
	file::openQuietly $tgtname
    } elseif  {[regsub  {(.*)\.a$} $curname {\1_.a} tgtname]}  {
	file::openQuietly $tgtname
    } else {
	error "NoMatch"
    }
}


