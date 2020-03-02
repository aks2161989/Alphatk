# (install)

alpha::mode Java 1.23 javaMenu {*.java *.j} {
    javaMenu
} {
    # Script to execute at Alpha startup
    addMenu javaMenu "¥140" Java
} uninstall {
    catch {file delete [file join $HOME Tcl Modes javaMode.tcl]}
    catch {file delete [file join $HOME Tcl Completions JavaCompletions.tcl]}
} maintainer {
} description {
    Supports the editing of Java programming files
} help {
    Java Mode provides keyword coloring and class/method marking with the 
    Marks Menu; it gives you automatic indentation and keyword completion.
	
    Java Mode supplies a menu for easy switching between your favorite Java
    compiler and Alpha (Shift-Command-S), will send a file to be compiled
    (Shift-Command-K).  The Java Menu can be used to open a HTML file
    corresponding to a java file in the Applet Viewer.  If there is a file
    "some_applet.html" in the same folder as "some_applet.java" it is sent.
    Otherwise the user is asked to select a HTML file.  This file is
    remembered throughout this session with Alpha.

    Click on this "Java Example.java" link for an example syntax file.
}

proc javaMode.tcl {} {}

array set javacompilerAppSignatures {
    Suncompiler javc
}
array set javacompilerAppScripts {
    Suncompiler {
	{sendOpenEvent -n $quotedSig $filename}
    }
}

# required for use of C++::correctIndentation
newPref f useFasterButWorseIndentation 0 Java
newPref v indentComments "code 0" Java "" indentationTypes varitem
newPref v indentC++Comments "code 0" Java "" indentationTypes varitem
# To automatically perform context relevant formatting after typing a left
# or right curly brace, turn this item on||To have the brace keys produce a
# brace without additional formatting, turn this item off
newPref flag electricBraces    1 Java
# To automatically perform context relevant formatting after typing a
# semicolon, turn this item on||To have the semicolon key produce a
# semicolon without additional formatting, turn this item off
newPref flag electricSemicolon 1 Java
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn    1 Java

newPref	flag allowMultipleClassesPerFile 0 Java
#newPref f elecColon {1} Java

# Look up words you control-command-double-click on here.
newPref url javaLangHelpLocation \
  "http://java.sun.com/j2se/1.4/docs/api/java/lang/" Java

newPref	v leftFillColumn {3} Java
newPref	v prefixString {// } Java 
newPref	v lineWrap {0} Java
#newPref	v funcExpr {^[^ \t\(#\r/@].*\(.*\)$} Java
#    newPref v parseExpr {\m([_:\w]+)\s*\(} Java

newPref v wordBreak {[\w_]+} Java
newPref	f autoMark	0 Java
# To synchronise Alpha's value for your java class path with the current
# value in your system environment each time Alpha starts up, click this 
# box||To let Alpha maintain its own value for your classpath independent
# of the systemwide value, click this box.
newPref	f classPathSynchroniseWithEnv	1 Java
# Your Java class path.
newPref searchpath classSearchPath "" Java "" [list *.jar *.zip]
newPref	color stringColor	green Java
newPref	color commentColor	red	 Java
newPref	color keywordColor	blue Java
newPref color funcColor yellow Java
newPref f includeMenu 1 Java
newPref variable showJavacompilerLog 1 Java "" \
  [list "Never" "Only after error" "Always"] index

set Java::commentCharacters(General) [list "//"]
set Java::commentCharacters(Paragraph) [list "/* " " */" " * "]
set Java::commentCharacters(Box) [list "/*" 2 "*/" 2 "*" 3]
set Java::commentBlockBreaks [list <p> <br> <pre> </pre> <ul> </ul>]

set Java::escapeChar "\\"
set Java::quotedstringChar "\""

ensureset Java_projectStore(placeClassesHere) ""
ensureset Java_projectStore(compileFromThisFolder) ""
ensureset JavaProjects(Usual) [array get Java_projectStore]
ensureset JavaProject Usual

regModeKeywords -C {Java} {}
regModeKeywords  -a -e {//} -b {/*} {*/} -c $JavamodeVars(commentColor) \
		 -f $JavamodeVars(funcColor) -k $JavamodeVars(keywordColor) \
		 -s $JavamodeVars(stringColor) Java {
    abstract boolean break byte byvalue case catch char class const 
    continue default do double else extends false final finally float for 
    goto if implements import instanceof int interface long native new 
    null package private protected public return short static super switch 
    synchronized this throw throws transient true try void while future 
    generic inner outer operator rest var volatile
}
regModeKeywords -a -k color_9 Java { Object String }

proc javaMenu {} {}

if {$JavamodeVars(classPathSynchroniseWithEnv)} {
    if {[info exists env(CLASSPATH)]} {
	set JavamodeVars(classSearchPath) [split $env(CLASSPATH) ";"]
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "menu::buildjavaMenu" --
 # 
 #  Use a build proc so we can add things on the fly.
 # -------------------------------------------------------------------------
 ##
proc Java::buildMenu {} {
    global javaMenu
    set ma {
	"switchToCompiler"
	"(-"
	"/K<U<OcompileFile"
	"(-"
	"/V<U<OviewApplet"
	"//<BnewJavadocComment"
	"editProjects"
	"insertFileAsBytes"
    }
    
    return [list build $ma Java::MenuProc "" $javaMenu]
}
menu::buildProc javaMenu Java::buildMenu

# If this package exists, add the headers menu
if {[alpha::package exists searchPaths]} {
    menu::buildProc javaSearchPath {mode::rebuildSearchPathMenu javaSearchPath}
    menu::insert javaMenu submenu end javaSearchPath
}

menu::buildSome javaMenu

proc Java::MenuProc {menu item} {
    eval Java::$item
}

proc Java::electricLeft {args} {
    uplevel 1 [list C++::electricLeft] $args
}

proc Java::correctIndentation {args} {
    uplevel 1 [list C++::correctIndentation] $args
}
proc Java::indentLine {args} {
    uplevel 1 [list C++::indentLine] $args
}
proc Java::foldableRegion {args} {
    uplevel 1 [list C++::foldableRegion] $args
}

proc Java::newJavadocComment {} {
    if {[isSelection]} {
	regsub -all "(\r|\n)( *//)?" [getSelect] "\r * " body
	deleteSelection
    } else {
	set body "¥comment body¥"
    }
    elec::Insertion "/**\r * $body\r */\r¥¥"
}

proc Java::editProjects {} {
    prefs::dialogs::editOneOfManyVars "Edit or create a new Java project" \
      JavaProject JavaProjects Java_projectStore project
}

# Launches Java Compiler
proc Java::switchToCompiler {} {
    global javacompilerSig
    app::launchAnyOfThese javc javacompilerSig "Please locate the Java compiler:"
    switchTo '$javacompilerSig'
}

# Sends the window to the compiler.
proc Java::compileFile {} {
    global showJavacompilerLog classSearchPath JavaProjects
    set path [win::StripCount [win::Current]]

    if {[winDirty]} {
	switch -- [askyesno -c "Save '[file tail $path]'?"] {
	    "yes" {
		save
		# Get path again, in case it was Untitled before.
		set path [win::StripCount [win::Current]]
	    }
	    "no" {
		if {![file exists $path]} {
		    alertnote "Can't send window to compiler."
		    return
		}
	    }
	    "cancel" {return}
	}
    }
    # Experimental code which will allow you to compile into a hierarchy
    # using javac's ability to find related class files in multiple packages
    # automatically.  This is needed for any project which contains files
    # in more than one directory.

    # Of course we only want to do this if the current file is in the 
    # compilation path given.  Else we'll assume it's a standalone file.
    set compileFrom ""
    set placeClasses ""

    # We check automatically whether a given file is in a project
    # by examining whether the path matches.
    foreach proj [array names JavaProjects] {
	array set tmp $JavaProjects($proj)
	if {$tmp(compileFromThisFolder) != "" \
	  && [file::pathStartsWith $path $tmp(compileFromThisFolder)]} {
	    set compileFrom $tmp(compileFromThisFolder)
	    set placeClasses $tmp(placeClassesHere)
	    break
	}
    }
    
    set classpathArg [string trim [join $classSearchPath {;}]]
    if {[string length $classpathArg]} {
	set classpathArg "-classpath $classpathArg"
    }
    
    if {$placeClasses != ""} {
	app::runScript javacompiler "Java compiler" \
	  $path 0 $showJavacompilerLog \
	  "-d $placeClasses $classpathArg" \
	  $compileFrom
    } else {
	app::runScript javacompiler "Java compiler" \
	  $path 0 $showJavacompilerLog $classpathArg \
	  $compileFrom
    }
}

# Opens a HTML file corresponding to a java file in the Applet Viewer.
# If there is a file some_applet.html in the same folder as some_applet.java
# it is sent. Otherwise the user is asked to select a HTML file.
# This file is remembered throughout this session with Alpha.
proc Java::viewApplet {} {
    global javaAppletFile
    set name [win::StripCount [win::Current]]
    set dir [file dirname $name]
    set root [file rootname [file tail $name]]
    set path [file join $dir $root.html]
    if {[info exists javaAppletFile($name)] && [file exists $javaAppletFile($name)]} {
	set path $javaAppletFile($name)
    } elseif {![file exists $path]} {
	set path [getfile "Please locate HTML file for applet."]
	set javaAppletFile($name) $path
    }
    xserv::invoke viewJavaApplet -file $path
}

proc Java::MarkFile {args} {
    win::parseArgs win
    Java::markFileHelper -w $win 1
}

proc Java::parseFuncs {args} {
    win::parseArgs win
    Java::markFileHelper -w $win 0
}


# My version of	Java::MarkFile. First revision, April 1996.
# Jim Menard, jimm@io.com
# Improved by Vince: both start and end position of embedded classes are
# stored, so if we order methods/sub-classes randomly, we still mark 
# things properly.
proc Java::markFileHelper {args} {
    win::parseArgs win marking

    set classInfo ""
    
    # Look for class definitions first
    set markExpr "^\[ \t\]*(\[A-Za-z_\]\[A-Za-z0-9_\]*\[ \t\]+)*(interface|class)\[ \t\]+\[A-Za-z_\]\[A-Za-z0-9_\]*\[ \t\r\](\[A-Za-z_\]\[A-Za-z0-9_.,\]*\[ \t\]+)*\{"
    set wordExpr "(interface|class)\[ \t\]+(\[A-Za-z_\]\[A-Za-z0-9_\]*)"
    set commands {
	set markArray([concat $word $classType]) $markPos
	# Remember mark	position and name separately so	we can call
	# Java::getClassFromPos() later.
	lappend	classInfo [list $word $markPos $endPos]
    }
    Java::searchAndDestroy $win $markExpr $wordExpr $commands 0 classType
    
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
    Java::searchAndDestroy $win $markExpr $wordExpr $commands 1

    set markExpr "^\[ \t\]*((public|private|protected)\[ \t\]+)+\[A-Za-z_\]\[A-Za-z0-9_\]*\[ \t\r\]*\\(\[^\r\n\]+;$"
    set wordExpr "(\[A-Za-z_\]\[A-Za-z0-9_\]*)\[ \t\]*\\("
    set commands {
	if {$className == $word} {
	    set markArray([concat $className "constructor"]) $markPos
	} else {
	    set markArray(${className}::$word) $markPos
	}
    }
    Java::searchAndDestroy $win $markExpr $wordExpr $commands 1

    # One more time; let's go back for constructors with no modifiers.
    set markExpr "^\[ \t\]*\[A-Za-z\]\[A-Za-z0-9_\]*\[ \t\r\]*\\(\[^;\]+$"
    set wordExpr "(\[A-Za-z\]\[A-Za-z0-9_\]*)\[ \t\]*\\("
    set commands {
	if {$className == $word} {
	    set markArray([concat $className "constructor"]) \
	      [lineStart -w $win [pos::math -w $win $start - 1]]
	}
    }
    Java::searchAndDestroy $win $markExpr $wordExpr $commands 1
    
    set parse {}
    if {[info exists markArray]} {
	foreach	f [lsort -dictionary [array names markArray]] {
	    set next [lineStart -w $win $markArray($f)]
	    
	    if {[regexp {.*(::if)$} $f] == 0} {
		if {[string length $f] > 45} { 
		    set ff "[string range $f 0 44]..." 
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
proc Java::searchAndDestroy {win markExpr wordExpr commands needClassName args} {
    
    upvar markArray markArray
    upvar classInfo classInfo
    
    if {!$needClassName} {
	global JavamodeVars
	# If the variable getEnd exists, we want to find the range that
	# this class/function encompasses.  If this flag is set, we may
	# have multiple classes, and hence cannot assume the first class
	# we find extends to the end of the file.
	set getEnd $JavamodeVars(allowMultipleClassesPerFile)
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
	    set className [Java::getClassFromPos $win $start $classInfo]
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
		    set endPos [lindex [search -w $win -s -f 1 -m 0 -i 0 \
		      -- "\{" $markPos] 1]
		    if {[catch {matchIt -w $win "\{" $endPos} match]} {
			# There wasn't a matching brace
			status::msg $match
		    } else {
			set endPos $match
		    }
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
proc Java::getClassFromPos {win pos classInfo} {
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

# Useful to embed images etc into Java source code
proc Java::insertFileAsBytes {{filename ""}} {
    if {![string length $filename]} {
	set filename [getfile]
    }
    set fin [open $filename r]
    fconfigure $fin -translation binary -encoding binary
    set contents [read $fin]
    close $fin
    set res [list]
    foreach f [split $contents ""] {
	scan $f %c foo
	lappend res "(byte)0x[format %02x $foo]"
    }
    set res [breakIntoLines [join $res ", "]]
    elec::Insertion "static byte ¥arrayname¥[] = \{\r$res\r\};\r"
}

proc Java::DblClick {from to shift option control} {
    set text [getSelect]
    if {$control} {
	global JavamodeVars
	urlView "$JavamodeVars(javaLangHelpLocation)${text}.html"
    }
}

#proc Java::findLastType {{pos ""}} {
#    set var [completion::lastWord]
#    puts [Java::findType $var [getPos]]
#    #puts [completion::lastTwoWords prev]
#    #puts $prev
#}
#Bind '1' <z> Java::findLastType Java 

# Look backwards from 'pos' for the definition of the variable
# $varName.
proc Java::findType {varName pos} {
    set pat "\[a-zA-Z0-9_\]+(\\\[\[0-9\]*\\\])?\[ \t\]+[quote::Regfind $varName]"
    set res [search -s -n -f 0 -r 1 -- $pat $pos]
    if {![llength $res]} { return }
    set first [lindex [split [eval getText $res] " \t"] 0]
    set typePos [pos::math [lindex $res 0] + [string length $first]]
    set p [getPos]
    goto $typePos
    set res [completion::lastWord]
    goto $p
    return $res
}


