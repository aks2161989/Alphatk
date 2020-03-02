# (install)

alpha::mode C# 0.1.1 csharpMenu {*.cs} {
    csharpMenu
} {
    addMenu csharpMenu "C#" C#
} uninstall {
    this-file
} maintainer {
} description {
    Supports the editing of Microsoft C-Sharp files
} help {
    C# Mode provides keyword coloring, automatic indentation and keyword 
    completion.  Also the marks and funcs menus.

    Click on this "C# Example.cs" link for an example syntax file.
}

namespace eval C# {}

# required for use of C++::correctIndentation
newPref f useFasterButWorseIndentation 0 C#
newPref v indentComments "code 0" C# "" indentationTypes varitem
newPref v indentC++Comments "code 0" C# "" indentationTypes varitem

newPref	flag allowMultipleClassesPerFile 0 C#
# To automatically perform context relevant formatting after typing a left
# or right curly brace, turn this item on||To have the brace keys produce a
# brace without additional formatting, turn this item off
newPref flag electricBraces    1 C#
# To automatically perform context relevant formatting after typing a
# semicolon, turn this item on||To have the semicolon key produce a
# semicolon without additional formatting, turn this item off
newPref flag electricSemicolon 1 C#
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn    1 C#

newPref	v leftFillColumn {3} C#
newPref	v prefixString {// } C# 
newPref	v lineWrap {0} C#
#newPref v funcExpr {^[^ \t\(#\r/@].*\(.*\)$} C#
#newPref v parseExpr {\m([_:\w]+)\s*\(} C#

newPref v wordBreak {[\w_]+} C#
newPref	f autoMark	0 C#
newPref	color stringColor	green C#
newPref	color commentColor	red	 C#
newPref	color keywordColor	blue C#
newPref color funcColor yellow C#

set C#::commentCharacters(General) [list "//"]
set C#::commentCharacters(Paragraph) [list "/* " " */" " * "]
set C#::commentCharacters(Box) [list "/*" 2 "*/" 2 "*" 3]

set C#::escapeChar "\\"
set C#::quotedstringChar "\""

regModeKeywords -C {C#} {}
regModeKeywords  -a -e {//} -b {/*} {*/} -c [set C#modeVars(commentColor)] \
  -f [set C#modeVars(funcColor)] -k [set C#modeVars(keywordColor)] \
  -s [set C#modeVars(stringColor)] C# {
    abstract event new struct 
    as explicit null switch 
    base extern object this 
    bool false operator throw 
    break finally out true 
    byte fixed override try 
    case float params typeof 
    catch for private uint 
    char foreach protected ulong 
    checked goto public unchecked 
    class if readonly unsafe 
    const implicit ref ushort 
    continue in return using 
    decimal int sbyte virtual 
    default interface sealed volatile 
    delegate internal short void 
    do is sizeof while 
    double lock stackalloc   
    else long static   
    enum namespace string 
}

proc csharpMenu {} {}

## 
 # -------------------------------------------------------------------------
 # 
 # "C#::buildMenu" --
 # 
 #  Use a build proc so we can add things on the fly.
 # -------------------------------------------------------------------------
 ##
proc C#::buildMenu {} {
    global csharpMenu
    set ma {
	"nothingHereYet"
    }
    
    return [list build $ma C#::MenuProc "" $csharpMenu]
}
menu::buildProc csharpMenu C#::buildMenu

menu::buildSome csharpMenu

proc C#::MenuProc {menu item} {
    eval C#::$item
}

proc C#::electricLeft {args} {
    uplevel 1 [list C++::electricLeft] $args
}

proc C#::correctIndentation {args} {
    uplevel 1 [list C++::correctIndentation] $args
}
proc C#::indentLine {args} {
    uplevel 1 [list C++::indentLine] $args
}
proc C#::foldableRegion {args} {
    uplevel 1 [list C++::foldableRegion] $args
}

proc C#::MarkFile {args} {
    win::parseArgs win
    C#::MarkFile2 $win 1
}

proc C#::parseFuncs {args} {
    win::parseArgs win
    C#::MarkFile2 $win 0
}


# Copied from Java mode.
proc C#::MarkFile2 {win marking} {
    set classInfo ""
    
    # Look for class definitions first
    set markExpr "^\[ \t\]*(\[A-Za-z_\]\[A-Za-z0-9_\]*\[ \t\]+)*(interface|class)\[ \t\]+\[A-Za-z_\]\[A-Za-z0-9_\]*\[ \t\r\](\[A-Za-z_\]\[A-Za-z0-9_.,\]*\[ \t\]+)*\{"
    set wordExpr "(interface|class)\[ \t\]+(\[A-Za-z_\]\[A-Za-z0-9_\]*)"
    set commands {
	set markArray([concat $word $classType]) $markPos
	# Remember mark	position and name separately so	we can call
	# C#::getClassFromPos() later.
	lappend	classInfo [list $word $markPos $endPos]
    }
    C#::searchAndDestroy $win $markExpr $wordExpr $commands 0 classType
    
    # The following regular expression is overly restrictive. After the open
    # paren, I disallow semicolons. That avoids finding lines like
    # throw new FooException(arg);
    # which is good, but unfortunately also avoids finding lines like
    # public int foo(arg) // comment with semi;
    #
    # It doesn't find constructors without a "public", "private", or other phrase
    # before the method name since it requires at least one word before the
    # method name. They are special-cased below. I did that so function calls,
    # "if" statements, and the like wouldn't be found.
    set markExpr "^\[ \t\]*(\[A-Za-z_\]\[A-Za-z0-9_\]*(\[ \t\]*\\\[\\])*\[ \t\]+)+\[A-Za-z_\]\[A-Za-z0-9_\]*\[ \t\r\]*\\(\[^;\]+$"
    set wordExpr "(\[A-Za-z_\]\[A-Za-z0-9_\]*)\[ \t\]*\\("
    set commands {
	if {$className == $word} {
	    set markArray([concat $className "constructor"]) $markPos
	} else {
	    set markArray(${className}::$word) $markPos
	}
    }
    C#::searchAndDestroy $win $markExpr $wordExpr $commands 1

    set markExpr "^\[ \t\]*((public|private|protected)\[ \t\]+)+\[A-Za-z_\]\[A-Za-z0-9_\]*\[ \t\r\]*\\(\[^\r\n\]+;$"
    set wordExpr "(\[A-Za-z_\]\[A-Za-z0-9_\]*)\[ \t\]*\\("
    set commands {
	if {$className == $word} {
	    set markArray([concat $className "constructor"]) $markPos
	} else {
	    set markArray(${className}::$word) $markPos
	}
    }
    C#::searchAndDestroy $win $markExpr $wordExpr $commands 1

    # One more time; let's go back for constructors with no modifiers.
    set markExpr "^\[ \t\]*\[A-Za-z\]\[A-Za-z0-9_\]*\[ \t\r\]*\\(\[^;\]+$"
    set wordExpr "(\[A-Za-z\]\[A-Za-z0-9_\]*)\[ \t\]*\\("
    set commands {
	if {$className == $word} {
	    set markArray([concat $className "constructor"]) [lineStart -w $win [pos::math -w $win $start - 1]]
	}
    }
    C#::searchAndDestroy $win $markExpr $wordExpr $commands 1
    
    set parse {}
    if {[info exists markArray]} {
	foreach	f [lsort -dictionary [array names markArray]] {
	    set next [nextLineStart -w $win $markArray($f)]
	    
	    if {[regexp {.*(::if)$} $f] == 0} {
		if {[string length $f] > 35} { 
		    set ff "[string range $f 0 31]..." 
		} else {
		    set ff $f
		}
		if {$marking} {
		    setNamedMark -w $win "$ff" "$markArray($f)" $next $next
		} else {
		    lappend parse $ff $next
		}
	    }
	}
    }
    if {!$marking} {return $parse}
}

# Start	at top of file and find	text that matches markExpr. Clean it up	and
# use wordExpr to find the word	we want. Execute commands.
proc C#::searchAndDestroy {win markExpr wordExpr commands needClassName args} {

    upvar markArray markArray
    upvar classInfo classInfo
    
    if {!$needClassName} {
	# If the variable getEnd exists, we want to find the range that
	# this class/function encompasses.  If this flag is set, we may
	# have multiple classes, and hence cannot assume the first class
	# we find extends to the end of the file.
	global C#modeVars
	set getEnd [set "C#modeVars(allowMultipleClassesPerFile)"]
    }
    
    set pos [minPos]
    
    while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 0 -- "$markExpr" $pos} res]} {
	set start [lindex $res 0]
	set end	[pos::math -w $win [lindex $res 1] + 1]
	if {[pos::compare -w $win $end > [maxPos -w $win]]} {
	    set end [maxPos -w $win]
	}
	set thistext [getText -w $win $start $end]
	if {$needClassName} {
	    set className [C#::getClassFromPos $win $start $classInfo]
	}
	# regexp doesn't like carriage returns or tabs
	regsub -all "\[\n\r\t\]" $thistext " " thistext
	# If the open paren was	the last character on the line,
	# the selected text included the last carriage return as well.
	# Trim this off	now that it is changed into a space.
	set thistext [string trimright $thistext]
	if {[eval [list regexp -- $wordExpr $thistext ""] $args [list word]]} {
	    set markPos [lineStart -w $win $start]
	    if {[info exists getEnd]} {
		if {$getEnd} {
		    set endPos [lindex [search -w $win -s -f 1 -m 0 -i 0 -- "\{" $markPos] 1]
		    set endPos [matchIt -w $win "\{" $endPos]
		} else {
		    # little efficiency thing: the first class we find, we know
		    # extends to the end of the file, so we don't bother doing
		    # its 'matchIt' because it is very time-consuming.
		    set endPos [maxPos -w $win]
		    set getEnd 1
		}
	    }
	    eval $commands
	}
	set pos	$end
    }
}

# Given	a file position, find the class	definition in which it resides.
# There's got to be an easier way than passing two separate lists. 
# I tried fooling
# around with markArray(), but don't know Tcl well enough to use it instead.
proc C#::getClassFromPos {win pos classInfo} {
    set nClasses [llength $classInfo]
    for {set i [expr {$nClasses - 1}]} {$i >= 0} {incr i -1} {
	set range [lindex $classInfo $i]
	if {[pos::compare -w $win [lindex $range 1] <= $pos] \
	  && [pos::compare -w $win [lindex $range 2] >= $pos]} {
	    return [lindex $range 0]
	}
    }
    return ""
}
