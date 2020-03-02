# (install)
############################################################################# 
# pythonMode.tcl
#  Howard Oakley, EHN & DIJ Oakley
#  howard@quercus.demon.co.uk
#
# Description:
# This auto-installing file implements a simple mode for editing 
# Python using Alpha. It has been tested with Alpha version 7.2. 
# The features of this mode include:
# syntax colouring - comments in red, strings (some) in green,
#  keywords in blue, and colons (a Python particular) in magenta 
# easy production of comment boxes etc.
# def and class marking - automatically generated marks (M popup) give 
#  the function name first, and then the class (if any), whilst class 
#  definitions give the class name twice; the {} popup takes
#  you to class definitions
# automatic indentation - given the importance of this in Python control 
#  structures, this was an essential, and is accomplished
#  using tabs in syntactic context.
# The code below is a cobbling together of code stolen from other sources. 
# Whilst the fine code of the original sources is reliable, there are 
# all sorts of nasty kludges which I have used to get it to do what 
# I needed. Tcl purists who can improve on it are invited to do so: 
# please e-mail your corrections to me so that I can maintain this. 
# My thanks and apologies to those from whom I have stolen code. 
# Version: 1.0 dated 17 Sep 1999 [or if you prefer it, 1999-09-17]. 
# 
# (Vince fixed some stuff up for Alphatk, and removed some obsolete things)
############################################################################# 

alpha::mode [list Pyth Python] 1.0.3 source {*.py} {
} {
    # Script to execute at Alpha startup
} maintainer {
} uninstall {
    this-file
} description {
    Supports the editing of Python programming files
} help {
    Python is an interpreted, interactive, object-oriented programming
    language.  It incorporates modules, exceptions, dynamic typing, very
    high level dynamic data types, and classes.  Python combines remarkable
    power with very clear syntax.  It has interfaces to many system calls
    and libraries, as well as to various window systems, and is extensible
    in C or C++.  
    
    It is also usable as an extension language for applications that need a
    programmable interface.  Finally, Python is portable: it runs on many
    brands of UNIX, on the Mac, and on PCs under MS-DOS, Windows, Windows
    NT, and OS/2.
    
                                            -- <http://www.python.org>

    Alpha's 'Pyth' Mode provides the following features: 
    
    ¥ syntax coloring - comments in red, strings (some) in green, keywords
    in blue, and colons (a Python particular) in magenta
    
    ¥ easy production of comment boxes etc.
    
    ¥ def and class marking - automatically generated file marks (M popup)
    give the function name first, and then the class (if any), whilst class
    definitions give the class name twice
    
    ¥ the {} popup (ParseFuncs) takes you to class definitions
    
    ¥ automatic indentation - given the importance of this in Python control
    structures, this is an essential, and is accomplished using tabs in
    syntactic context.
    
    See this "Python Example.py" hyperlink for an example syntax file.
}

newPref v leftFillColumn {1} Pyth
newPref v wordBreak {\w+} Pyth
newPref var lineWrap {0} Pyth
newPref v funcExpr {^[ \t]*(def|class)[ \t]+([A-Za-z0-9_]+)} Pyth 
newPref v parseExpr {^[ \t]*([A-Za-z0-9_]*)} Pyth
newPref f autoMark 0 Pyth
# To automatically perform context relevant formatting after typing a left
# or right curly brace, turn this item on||To have the brace keys produce a
# brace without additional formatting, turn this item off
newPref flag electricBraces    1 Pyth
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn    1 Pyth

# I extend the range of keywords a little, to include some type conversions 
# and other important items

set pythKeyWords {
    access and break class continue def del elif else
    except exec finally for from global if import in
    is lambda not or pass print raise return self try while 
    = < > <= >= + * - / != <> % | ^ &
    len min max ~ abs int long float complex divmod pow
    list map tuple eval string repr assert
}

regModeKeywords -C Pyth {}
regModeKeywords -a -e {#} -s green -c red -i : -I magenta \
  -k blue Pyth $pythKeyWords
unset pythKeyWords

#================================================================================ 
namespace eval Pyth {}
#================================================================================ 

# for easy production of comment boxes etc.

set Pyth::quotedstringChar "'"
newPref v prefixString {# } Pyth
set Pyth::commentCharacters(General) "\#"
set Pyth::commentCharacters(Paragraph) [list "#----" "#----" "#"] 
set Pyth::commentCharacters(Box) [list "#" 2 "#" 2 "#" 3] 

# the mark routine, which has to append the class name *if* the definition is
# part of a class definition, but reset the empty class name if it is not, 
# i.e. there is no leading whitespace before the 'def'
# - this therefore builds the M popup menu.

proc Pyth::MarkFile {args} {
    win::parseArgs w
    global PythmodeVars
    set pos [minPos -w $w]
    set classnom ""
    
    status::msg "Marking \"[win::Tail $w]\" É"
    while {![catch {search -w $w -s -f 1 -r 1 -m 0 -i 1 \
      $PythmodeVars(funcExpr) $pos} res]} {
	set start [lindex $res 0]
	set end [pos::math -w $w [lindex $res 1] + 1]
	set text [getText -w $w $start $end]
	
	if {[regexp -indices {class[ \t]+([a-zA-Z0-9_]+)} $text -> pname]} {
	    set i1 [pos::math -w $w $start + [lindex $pname 0]]
	    set i2 [pos::math -w $w $start + [lindex $pname 1] + 1]
	    # this is the start of a class definition, so save the class name       
	    set classnom  [getText -w $w $i1 $i2]
	} else {
	    if {[pos::compare -w $w $pos > [minPos -w $w]]} {
		set pp [pos::math -w $w $start - 1]
		set pq [pos::math -w $w $start + 1]
		set pr [getText -w $w $pp $pq]
		if {![regexp {[ \t]+} $pr]} {
		    # this is a standalone def, therefore reset the class
		    # name to an empty string
		    set classnom ""
		}
	    }
	}
	
	if {[regexp -indices {(def|class)[ \t]+([a-zA-Z0-9_]+)} \
	  $text dummy dummy0 pname]} {
	    set i1 [pos::math -w $w $start + [lindex $pname 0]]
	    set i2 [pos::math -w $w $start + [lindex $pname 1] + 1]
	    set word  [getText -w $w $i1 $i2]
	    set tmp [concat $i1 $i2]
	    # assemble the marker name with the def element first,
	    # followed by any class name
	    set ol_word [join [concat $word " " $classnom ""]]   
	    while {[lcontains marks $ol_word]} {
		append ol_word " "
	    }
	    lappend marks $ol_word
	    set inds($ol_word) $tmp
	}
	
	set pos $end
    }
    set count 0
    if {[info exists inds]} {
	foreach f [lsort -dictionary [array names inds]] {
	    set res $inds($f)
	    setNamedMark -w $w $f [pos::lineStart -w $w [lindex $res 0]] \
	      [lindex $res 0] [lindex $res 1]
	    incr count
	}
    }
    set msg "The window \"[win::Tail $w]\" contains $count mark"
    append msg [expr {($count == 1) ? "." : "s."}]
    status::msg $msg
    return
}

# this builds the {} menu along similar lines, but this time with just
# class definitions
proc Pyth::parseFuncs {} {
    global PythmodeVars
    set pos [minPos]
    
    while {![catch {search -s -f 1 -r 1 -m 0 -i 1 \
      $PythmodeVars(funcExpr) $pos} res]} {
	set start [lindex $res 0]
	set end [pos::math [lindex $res 1] + 1]
	set text [getText $start $end]
	
	if {[regexp -indices {class[ \t]+([a-zA-Z0-9_]+)} $text -> pname]} {
	    set i1 [pos::math $start + [lindex $pname 0]]
	    set i2 [pos::math $start + [lindex $pname 1] + 1]
	    set word  [getText $i1 $i2]
	    set tmp [concat $i1 $i2]
	    set inds($word) $tmp
	}
	set pos $end
    }
    set rtnRes {}
    
    if {[info exists inds]} {
	foreach f [lsort -dictionary [array names inds]] {
	    set next [nextLineStart $inds($f)]
	    lappend rtnRes $f $next
	}
    }
    return $rtnRes 
}

proc Pyth::indentLine {args} {
    win::parseArgs w
    # get details of current line
    set beg [pos::lineStart -w $w [getPos -w $w]]
    set text [getText -w $w $beg [pos::nextLineStart -w $w $beg]]
    regexp -- "^\[ \t\]*" $text white
    set len [string length $white]
    set epos [pos::math -w $w $beg + $len]
    
    # Find last previous non-comment line and get its leading
    # whitespace 
    set pos $beg
    while 1 {
	if {[catch {search -w $w -s -f 0 -r 1 -i 0 -m 0 \
	  "^\[ \t\]*\[^ \t\r\n\]" [pos::math -w $w $pos - 1]} lst]} {
	    # search failed at top of file
	    set line "#"
	    set lwhite 0
	    break
	}
	if {[text::isInDoubleComment -w $w [lindex $lst 0] res]} {
	    set pos [lindex $res 0]
	} else {
	    set line [getText -w $w [lindex $lst 0] \
	      [pos::math -w $w [pos::nextLineStart -w $w [lindex $lst 0]] - 1]]
	    set lwhite [lindex [pos::toRowCol -w $w [pos::math -w $w [lindex $lst 1] - 1]] 1]
	    break
	}
    }
    
    # Use [text::getIndentationAmount] instead of the window's 'tabsize' var.

#     # we need (syntactically) to increase the tabs by 1, so first do
#     # this using spaces, and then convert the spaces to a tab.  This is
#     # not elegant, but it works!
#     if {[regexp -- ":\[ \t\]*$" $line]} {
# 	getWinInfo -w $w a
# 	set ps $a(tabsize)
# 	incr lwhite $ps
#     }
#     set lwhite [text::indentOf -w $w $lwhite]
#     if {$white != $lwhite} {
# 	replaceText -w $w $beg $epos $lwhite
# 	select -w $w $beg [pos::math -w $w $beg + [string length $lwhite]]
# 	spacesToTabs -w $w
#     }
    
    set ia [text::getIndentationAmount -w $w]
    if {[regexp -- ":\[ \t\]*$" $line]} {
	incr lwhite $ia
    }
    set lwhite [text::indentOf -w $w $lwhite]
    if {$white != $lwhite} {
	replaceText -w $w $beg $epos $lwhite
    }
    goto -w $w [pos::math -w $w $beg + [string length $lwhite]]
    return
}
