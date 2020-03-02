## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "cMode.tcl"
 #                                          created: 04/19/1996 {04:53:38 pm}
 #                                      last update: 03/21/2006 {03:02:02 PM}
 # Description:
 # 
 # Supports the editing of various C documents (C, C++, Objective C).
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 # 
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 #  modified   by  rev reason
 #  ---------- --- --- -----------
 #  2000-12-07 DWH 1.0 added help text
 #  2001-11-22 BD  1.4 added ObjC support <bdesgraupes@easyconnect.fr>
 #  
 # ==========================================================================
 ##

alpha::mode C 1.4.5 dummyC {*.c *.C *.r *.rc} {
} {
    # Script to execute at Alpha startup
} maintainer {
} uninstall {
    if {[askyesno \
      "Uninstalling \"C\" mode will also remove \"C++\" and \"Objc\" modes.\r\r\
      Do you want to continue?"]} {
	catch {file delete [file join $HOME Tcl Modes cMode.tcl]}
	catch {file delete [file join $HOME Tcl Completions CCompletions.tcl]}
	catch {file delete [file join $HOME Tcl Completions C++Completions.tcl]}
	catch {file delete [file join $HOME Tcl Completions "C Tutorial.r"]}
	catch {file delete [file join $HOME Tcl Completions "C++ Tutorial.cc"]}
    }
} description {
    Supports the editing of C programming files
} help {
    C and C++ modes function nearly identically in Alpha.  C Mode
    provides keyword coloring and procedure marking with the Marks Menu;
    supports cmd-dbl-click for opening files or (sends the word to app
    sig "DanR"); automatically handles indentation and formatting. 
    Support for Think and CodeWarrior.  

    Click on this "C++ Example.cp" link for an example syntax file.
}

alpha::mode C++ 1.4.5 dummyC++ {
    *.H *.h *.hpp *.cc *.cp *.cpp *.CPP *.pch *.pch++ *.icc *.exp *.c++
} {
} {
    # Script to execute at Alpha startup
} maintainer {
} uninstall {
    if {[askyesno \
      "Uninstalling \"C++\" mode will also remove \"C\" and \"Objc\" modes.\r\r\
      Do you want to continue?"]} {
	catch {file delete [file join $HOME Tcl Modes cMode.tcl]}
	catch {file delete [file join $HOME Tcl Completions CCompletions.tcl]}
	catch {file delete [file join $HOME Tcl Completions C++Completions.tcl]}
	catch {file delete [file join $HOME Tcl Completions "C Tutorial.r"]}
	catch {file delete [file join $HOME Tcl Completions "C++ Tutorial.cc"]}
    }
} description {
    Supports the editing of C++ programming files
} help {
    C and C++ modes function nearly identically in Alpha.  C Mode
    provides keyword coloring and procedure marking with the Marks Menu;
    supports cmd-dbl-click for opening files or (sends the word to app
    sig "DanR"); automatically handles indentation and formatting. 
    Support for Think and CodeWarrior.  

    Click on this "C++ Example.cp" link for an example syntax file.
}

alpha::mode [list Objc "Objective C"] 1.4.2 dummyObjc {*.m *.i} {
} {
    # Script to execute at Alpha startup
} maintainer {
} uninstall {
    if {[askyesno \
      "Uninstalling \"Objc\" mode will also remove \"C\" and \"C++\" modes.\r\r\
      Do you want to continue?"]} {
	catch {file delete [file join $HOME Tcl Modes cMode.tcl]}
	catch {file delete [file join $HOME Tcl Completions CCompletions.tcl]}
	catch {file delete [file join $HOME Tcl Completions "C Tutorial.r"]}
	catch {file delete [file join $HOME Tcl Completions "C++ Tutorial.cc"]}
    }
} description {
    Supports the editing of Objective-C programming files
} help {
    This mode implements specific support for Objective C. Many features
    are identical to C mode. The mode adds coloring for the ObjC specific
    keywords, special file marking for @interface, @implementation and
    @protocol declarations.

    See ObjCMarkTester.h and ObjCMarkTester.m in the Tests folder for
    examples, or "ObjectiveC Example.m" in the 'Examples' folder.
}

proc cMode.tcl {} {}

# Dummy procs
proc dummyC {} {}
proc dummyC++ {} {}
proc dummyObjc {} {}

# To automatically perform context relevant formatting after typing a left
# or right curly brace, turn this item on||To have the brace keys produce a
# brace without additional formatting, turn this item off
newPref flag electricBraces    1 C
# To automatically perform context relevant formatting after typing a
# semicolon, turn this item on||To have the semicolon key produce a
# semicolon without additional formatting, turn this item off
newPref flag electricSemicolon 1 C
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn    1 C
# To automatically perform context relevant formatting after typing a left
# or right curly brace, turn this item on||To have the brace keys produce a
# brace without additional formatting, turn this item off
newPref flag electricBraces    1 C++
# To automatically perform context relevant formatting after typing a
# semicolon, turn this item on||To have the semicolon key produce a
# semicolon without additional formatting, turn this item off
newPref flag electricSemicolon 1 C++
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn    1 C++
# To automatically perform context relevant formatting after typing a left
# or right curly brace, turn this item on||To have the brace keys produce a
# brace without additional formatting, turn this item off
newPref flag electricBraces    1 Objc
# To automatically perform context relevant formatting after typing a
# semicolon, turn this item on||To have the semicolon key produce a
# semicolon without additional formatting, turn this item off
newPref flag electricSemicolon 1 Objc
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn    1 Objc

# Preferences
# ===========

# C Preferences
# -------------
newPref v leftFillColumn {3} C
newPref v prefixString {// } C
newPref f elecElse {1} C
newPref v lineWrap {0} C
newPref v funcExpr {^[^ \t\(#\r/@].*\(.*\)$} C
newPref v parseExpr {\m(([_\w]+::~?)*[_\w]+)\s*\(} C
newPref v wordBreak {[_\w]+} C
newPref f autoMark 0 C
newPref color stringColor green C
newPref color commentColor red C
newPref color funcColor magenta C
newPref color keywordColor blue C
newPref f includeMenu {1} C
newPref v sourceSuffices { .c .C } C
newPref v headerSuffices { .h .H } C
newPref v indentComments "code 0" C "" indentationTypes varitem
# Allow C++ comments in C code, otherwise we'll actually throw
# error under some circumstances.
newPref v indentC++Comments "code 0" C "" indentationTypes varitem
newPref v indentMacros "fixed 0" C "" indentationTypes varitem
newPref f useFasterButWorseIndentation 0 C

# C++ Preferences
# ---------------
newPref v leftFillColumn {3} C++
newPref v prefixString {// } C++
newPref v wordBreak {[\w_]+} C++
newPref f elecElse {1} C++
newPref var lineWrap {0} C++
newPref v funcExpr {^([^ \t\(#[\r\n]/@].*[ \t]+)?\*?([A-Za-z0-9~_]+(<[^>]*>)?::[-A-Za-z0-9~_+= <>\|\*/]+|[A-Za-z0-9~_]+)[ \t\r\n]*\(} C++
newPref v parseExpr {\m(([_\w]+::~?)*[_\w]+)\s*\(} C++
newPref f autoMark 0 C++
newPref color stringColor green C++
newPref color commentColor red C++
newPref color keywordColor blue C++
newPref color funcColor magenta C++
newPref f includeMenu {1} C++
newPref v sourceSuffices {.cc .cp .cpp .CC .CP .CPP .icc .c} C++
newPref v headerSuffices { .h .hh .H .HH} C++
# These three are pairs:
newPref v indentComments "code 0" C++ "" indentationTypes varitem
newPref v indentC++Comments "code 0" C++ "" indentationTypes varitem
newPref v indentMacros "fixed 0" C++ "" indentationTypes varitem
newPref f useFasterButWorseIndentation 0 C++
newPref folder universalHeadersFolder "" C++

# ObjC Preferences
# ----------------
newPref v leftFillColumn {3} Objc
newPref v prefixString {// } Objc
newPref f elecElse {1} Objc
newPref var lineWrap {0} Objc
newPref v funcExpr {^-[ \t]*\([A-Za-z0-9~_]+\)[ \t\n\r]*[A-Za-z0-9]+:?} Objc
newPref v parseExpr {\m(([_\w]+::~?)*[_\w]+)\s*\(} Objc
newPref v wordBreak {[_\w]+} Objc
newPref f autoMark 0 Objc
newPref color stringColor green Objc
newPref color commentColor red Objc
newPref color funcColor magenta Objc
newPref color keywordColor blue Objc
newPref f includeMenu {1} Objc
newPref v sourceSuffices { .m .c .C } Objc
newPref v headerSuffices { .i .h .H } Objc
newPref v indentComments "code 0" Objc "" indentationTypes varitem
newPref v indentMacros "fixed 0" Objc "" indentationTypes varitem
newPref f useFasterButWorseIndentation 0 Objc


# Initialization of variables
# ===========================
# C mode initialisations:
set C::escapeChar "\\"
set C::quotedstringChar "\""
set C::lineContinuationChar "\\"

set C::commentCharacters(General) "//" ;# accepted by most compilers nowadays...
set C::commentCharacters(Paragraph) [list "/* " " */" " * "]
set C::commentCharacters(Box) [list "/*" 2 "*/" 2 "*" 3]

# C++ mode initialisations:
set C++::escapeChar "\\"
set C++::quotedstringChar "\""
set C++::lineContinuationChar "\\"

set C++::commentCharacters(General) "//" ;# no asterisk!
set C++::commentCharacters(Paragraph) [list "/* " " */" " * "]
set C++::commentCharacters(Box) [list "/*" 2 "*/" 2 "*" 3]

# ObjC mode initialisations:
set Objc::escapeChar "\\"
set Objc::quotedstringChar "\""
set Objc::lineContinuationChar "\\"

set Objc::commentCharacters(General) "//"
set Objc::commentCharacters(Paragraph) [list "/* " " */" " * "]
set Objc::commentCharacters(Box) [list "/*" 2 "*/" 2 "*" 3]


# Syntax Coloring
# ===============
# C mode
# ------
set cKeyWords {
    void break register short enum extern int for if while struct static 
    long continue switch case char unsigned double float return else 
    default goto do pascal Boolean typedef volatile union auto sizeof 
    size_t
}

if {[info exists Cwords]} {set cKeyWords [concat $cKeyWords $Cwords]}

regModeKeywords -C C {}
regModeKeywords -a -e {//} -b {/*} {*/} -c $CmodeVars(commentColor) \
  -f $CmodeVars(funcColor) -k $CmodeVars(keywordColor) \
  -s $CmodeVars(stringColor) -m {#} C $cKeyWords

# C++ mode
# --------
set {c++KeyWords} {
    new delete explicit class friend protected private public template try 
    catch throw operator const mutable virtual asm inline this and and_eq 
    bitand bitor compl not or or_eq xor xor_eq not_eq wchar_t bool true 
    false bool inline mutable static_cast dynamic_cast reinterpret_cast 
    typeid using namespace inherited
}

if {[info exists {C++words}]} {
    set {c++KeyWords} [concat ${c++KeyWords} ${C++words} $cKeyWords]
} else {
    set {c++KeyWords} [concat ${c++KeyWords} $cKeyWords]
}

regModeKeywords -C {C++} {}
regModeKeywords -a -e {//} -b {/*} {*/} -c [set C++modeVars(commentColor)] \
  -f [set C++modeVars(funcColor)] -k [set C++modeVars(keywordColor)] \
  -s [set C++modeVars(stringColor)] -m {#} {C++} ${c++KeyWords}

# ObjC mode
# ---------
set objcKeyWords {
@class @defs @encode @end @implementation @interface @private @protected @protocol @public 
@selector ARITH_SHIFT BOOL bycopy byref CACHE_BUCKET_IMP CACHE_BUCKET_NAME CACHE_BUCKET_VALID class
CLS_CLASS CLS_FLUSH_CACHE CLS_GETINFO CLS_GROW_CACHE CLS_INITIALIZED CLS_JAVA_CLASS CLS_JAVA_HYBRID
CLS_MAPPED CLS_META CLS_METHOD_ARRAY CLS_NEED_BIND CLS_POSING CLS_SETINFO defs encode end
id IMP implementation in inout interface ISSELECTOR IV marg_adjustedOffset marg_free marg_getRef
marg_getValue marg_malloc marg_prearg_size marg_setValue NAMEOF Nil nil NO objc_cache objc_category
objc_class OBJC_EXPORT OBJC_IMPORT objc_ivar_list objc_method_list objc_module OBJC_NEXT_METHOD_LIST
objc_protocol_list objc_super objc_symtab oneway out SEL selector self SELNAME SELUID super YES 
}

if {[info exists {Objcwords}]} {
    set {objcKeyWords} [concat $objcKeyWords $Objcwords $cKeyWords]
} else {
    set {objcKeyWords} [concat $objcKeyWords $cKeyWords]
}

regModeKeywords -e {//} -b {/*} {*/} -c $ObjcmodeVars(commentColor) \
  -f $ObjcmodeVars(funcColor) -k $ObjcmodeVars(keywordColor) \
  -s $ObjcmodeVars(stringColor) -m {#} Objc $objcKeyWords


unset cKeyWords
unset {c++KeyWords}
unset objcKeyWords


#================================================================================

proc C++::openUniversalHeader {} {
    global universalHeadersFolder
    if {![file exists $universalHeadersFolder]} {
	alertnote "Please set your 'Universal Headers Folder' preference first.\
	  It's set to '$universalHeadersFolder' which doesn't exist."
	return
    }
    set filename [prompt::statusLineComplete "Open which header" \
      [list file::completeFromDir $universalHeadersFolder] -nocache \
      -tryuppercase]
    
    edit -c -w -tabsize 4 [file join $universalHeadersFolder $filename]
    if {[icon -q]} {icon -o} 
}

Bind 'q' <o> C++::openUniversalHeader C++


proc C++::DblClick {from to shift option control} {	
    if {[regexp {#include.*("|<)(.*)("|>)} [getText \
      [lineStart [getPos]] [nextLineStart [getPos]]] "" "" inc]} {
	return [file::tryToOpen $inc]
    }
    
    selectText $from $to
    set text [getSelect]

    set lines {}
    global tagFile
    if {[info exists tagFile]} {
	set lines [grep "^$text'" $tagFile]
    }
    if {[regexp {'(.*)'(.*[^\t])(\t)+É} $lines "" one two]} {
	file::openQuietly $one
	set inds [search -s -f 1 -r 0 "$two" [minPos]]
	display [lindex $inds 0]
	eval selectText $inds
    } elseif {$::alpha::macos} {
	if {[catch {app::launchFore DanR} err]} {
	    status::msg $err
	} else {
	    tclAE::send -p {'DanR'} DanR {REF } "----" "³${text}²"
	}
    } else {
	# nothing to do
    }
}

# for C mode
proc C::DblClick {args} { eval C++::DblClick $args }

# for Objc mode
proc Objc::DblClick {args} { eval C++::DblClick $args }

# ×××× File marking ×××× #

## 
 # -------------------------------------------------------------------------
 #	 
 # "C++::MarkFile" --
 #	
 #	Improved version which handles templates, operators	etc.
 #	Makes use of the new mark menu in Alpha	6.5 which can handle
 #	more weird characters.  Handles most 'operator =+-*...' functions
 #  for C++
 #  
 #  Better marking of templates recently added.
 # Last modification : 2001-12-19 22:05:13
 # Author : Bernard Desgraupes <berdesg@easynet.fr>
 # -------------------------------------------------------------------------
 ##

proc C++::MarkFile {args} {
    win::parseArgs win

    global C++modeVars
    set ext [file extension $win]
    if {$ext == ".exp"} { return }
    # Do we have a header file (1) or a source file (0) :
    set isHeader [expr {[lsearch -exact [set C++modeVars(headerSuffices)] $ext]==-1 ? 0 : 1}]
    if {$isHeader} {
	# Marking various types of declarations
	foreach type [list class struct union template typedef operator] {
	    C++::otherMarks -w $win $type
	} 
    }
    C++::doFuncsMarking -w $win $isHeader
}

proc C::MarkFile {args} {
    win::parseArgs win

    global CmodeVars
    set ext [file extension $win]
    if {$ext == ".r"} {
	C::MarkRezFile -w $win
	return 
    }    
    # This is just in case a user has set C mode manually in a header file
    # (otherwise a file with extension .h is opened in C++ mode by default):
    set isHeader [expr {[lsearch -exact [set CmodeVars(headerSuffices)] $ext]==-1 ? 0 : 1}]
    if {$isHeader} {
	# Marking various types of declarations
	foreach type [list struct union typedef] {
	    C++::otherMarks -w $win $type
	} 
    }
    C::doFuncsMarking -w $win $isHeader
}

proc C++::doFuncsMarking {args} {
    win::parseArgs win isHeader

    set pos [minPos]
    set markExpr "^(\[A-Za-z0-9~_\]+\\s*\\(|(\[^ \t\(#\n\r/@:\*\]\[^=\(\r\n\]*\[ \t\]+\\*?)?"
    set subMarkExpr "(\[A-Za-z0-9~_\]+(<\[^>\]*>)?(::)?(\[A-Za-z0-9~_\]+::)*\[-A-Za-z0-9~_+ <>\|\\*/\]+|\[A-Za-z0-9~_\]+)"
    append markExpr $subMarkExpr
    append markExpr "\[ \n\t\r\]*\\()"
    append subMarkExpr "\[ \t\]*\\("
    while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 0 "$markExpr" $pos} res]} {
	set pos [lindex $res 1]
	# The regexp above also catches some typedefs and operator declarations. 
	# Let's get ridd of them here (they are handled separately).
	if {[regexp "^typedef" [getText -w $win [lindex $res 0] $pos]]} {continue} 
	if {[regexp "operator" [getText -w $win [lindex $res 0] $pos]]} {continue} 
	# If we have a source file, we don't want to mark prototypes :
	if {!$isHeader} {
	    # If there is semi-colon after the matching closing parenthese (and possibly
	    # spaces inbetween), we have a prototype. 'catch' this in case 'matchIt' fails.
	    if {![catch {set loco [pos::math -w $win [matchIt -w $win "\(" [lindex $res 1]] +1]}]} {
		while {[is::Whitespace [lookAt -w $win $loco]]} {
		    set loco [pos::math -w $win $loco +1]
		}
		if {[lookAt -w $win $loco]==";"} {
		    continue
		}
	    }
	} 
	# Looking back for the identifier
	if {[catch {search -w $win -s -f 0 -r 1 -m 0 -l [lindex $res 0] -i 0 \
	  {[ \t*][a-zA-Z]} [set pos [pos::math -w $win [lindex $res 1] -1]]} start]} {
	    set start [lindex $res 0]
	    if {[regexp "^\[A-Za-z0-9:~_\]+\[ \t\r\n\]*\\(" \
	      [getText -w $win $start [nextLineStart -w $win $start]] thistext]} {
		# nothing
	    } else {
		# Found no valid name. Skip the end of the while loop.
		continue
	    }
	} else {
	    set start [lindex $start 0]
	    set thistext [getText -w $win $start [lindex $res 1]]
	}
	# If the open paren was the last character on the line, the selected text included the last 
	# carriage return as well. Trim this off now that it is changed into a space.
	regsub -all "\[\r\n\t\]" [string trimright $thistext] " " thistext
	if {[regexp -- $subMarkExpr $thistext dummy word]} {
	    # Take care of constructors, destructors and other methods.
	    if {[string first "::" $word] != -1} {
		regsub {(<\w+>)?::} $word " " item
		set l [lindex $item 0]
		if {$l == [lindex $item 1]} {
		    # We have a constructor. If there are several, they are numbered
		    # with #1, #2 etc. In case there is only one, it is not numbered.
		    if {[info exists cnts($l)]} {
			set cnts($l) [expr $cnts($l) + 1]
			set word " Constructor '$l' #$cnts($l)"
			if {$cnts($l)==2} {
			    set word0 " Constructor '$l'"
			    set word1 " Constructor '$l' #1"
			    set inds($word1) $inds($word0)
			    unset inds($word0)
			} 
		    } else {
			set cnts($l) 1
			set word " Constructor '$l'"
		    }
		} elseif {"~$l" == [lindex $item 1]} {
		    # We have a destructor.
		    set word " Destructor '~$l'"
		} else {
		    # We have an ordinary method. Let's take care of overloaded functions.
		    set l $word
		    if {[info exists cnts($l)]} {
			set cnts($l) [expr $cnts($l) + 1]
			set word "$l #$cnts($l)"
			if {$cnts($l)==2} {
			    set word0 $l
			    set word1 "$l #1"
			    set inds($word1) $inds($word0)
			    unset inds($word0)
			} 
		    } else {
			set cnts($l) 1
			set word $l
		    }
		    
		}
	    }
	    set inds($word) [lineStart -w $win [pos::math -w $win $start - 1]]
	}
    }
    # Make the marks
    set markslist ""
    if {[info exists inds]} {
	if {$isHeader} {
	    setNamedMark -w $win "PROTOTYPES:" [minPos] [minPos] [minPos]
	} else {
	    setNamedMark -w $win "FUNCTIONS:" [minPos] [minPos] [minPos]
	}
	foreach f [lsort -dictionary [array names inds]] {
	    set next [lineStart -w $win $inds($f)]
	    set qualifier ""
	    set indent "" 
	    if {[string first "::" $f] != -1} {
		set indent "    "
		regexp "(\[A-Za-z0-9~_\]+)::" $f dum nmsp
		if {$nmsp==$qualifier} {
		} else {
		    setNamedMark -w $win "¥ Namespace $nmsp" "$inds($f)" $next $next
		    set qualifier $nmsp
		}
		regsub $nmsp $f "" item
		# If there is already a mark for $item, we add an invisible 
		# space to make it distinct. Thus synonyms won't overwrite each other.
		if {[set idx [lsearch -regexp $markslist "$item *"]]!="-1"} {
		    set item "[lindex $markslist $idx] "
		}
		set markslist [linsert $markslist 0 $item]
	    } else {
		set item $f
	    }
	    regsub "_ANSI_ARGS_" $item "" item
	    if {[string length $item] > 57} { set item "[string range $item 0 53]..." }
	    setNamedMark -w $win "$indent$item" "$inds($f)" $next $next
	}
    }
}

proc C::doFuncsMarking {args} {
    win::parseArgs win isHeader

    set pos [minPos]
    set markExpr "^(\[A-Za-z0-9~_\]+\\s*\\(|(\[^ \t\(#\n\r/@\*\]\[^=\r\n\]*\[ \t\]+\\*?)?"
    set subMarkExpr "(\[A-Za-z0-9~_\]+\[-A-Za-z0-9~_+ <>\|\\*/\]+|\[A-Za-z0-9~_\]+)"
    append markExpr $subMarkExpr
    append markExpr "\[ \n\t\r\]*\\()"
    append subMarkExpr "\[ \t\]*\\("
    while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 0 "$markExpr" $pos} res]} {
	set pos [lindex $res 1]
	# We do not want to mark typedefs :
	if {[regexp "^typedef" [getText -w $win [lindex $res 0] $pos]]} {continue} 
	# if we have a source file, we don't want to mark prototypes :
	if {!$isHeader} {
	    # If there is semi-colon after the matching closing parenthese (and possibly
	    # spaces inbetween), we have a prototype. 'catch' this in case 'matchIt' fails.
	    if {![catch {set loco [pos::math -w $win [matchIt -w $win "\(" [lindex $res 1]] +1]}]} {
		while {[is::Whitespace [lookAt -w $win $loco]]} {
		    set loco [pos::math -w $win $loco +1]
		}
		if {[lookAt -w $win $loco]==";"} {
		    continue
		}
	    }
	} 
	# Looking back for the identifier
	if {[catch {search -w $win -s -f 0 -r 1 -m 0 -l [lindex $res 0] -i 0 \
	  {[ \t*][a-zA-Z]} [set pos [pos::math -w $win [lindex $res 1] -1]]} start]} {
	    set start [lindex $res 0]
	    if {[regexp "^\[A-Za-z0-9:~_\]+\[ \t\r\n\]*\\(" \
	      [getText -w $win $start [nextLineStart -w $win $start]] thistext]} {
	    } else {
		continue
	    }
	} else {
	    set start [lindex $start 0]
	    set thistext [getText -w $win $start [lindex $res 1]]
	}
	# Trim carriage return off now that it is changed into a space.
	regsub -all "\[\r\n\t\]" [string trimright $thistext] " " thistext
	if {[regexp -- $subMarkExpr $thistext dummy word]} {
	    set inds($word) [lineStart -w $win [pos::math -w $win $start - 1]]
	}
    }
    if {[info exists inds]} {
	if {$isHeader} {
	    setNamedMark -w $win "PROTOTYPES:" [minPos] [minPos] [minPos]
	} else {
	    setNamedMark -w $win "FUNCTIONS:" [minPos] [minPos] [minPos]
	}
	foreach f [lsort -dictionary [array names inds]] {
	    set next [lineStart -w $win $inds($f)]
	    regsub "_ANSI_ARGS_" $f "" item
	    if {[string length $item] > 57} { set item "[string range $item 0 53]..." }
	    setNamedMark -w $win "  $item" "$inds($f)" $next $next
	}
    }
}

proc C++::otherMarks {args} {
    win::parseArgs win type

    set pos [minPos]
    switch $type {
	"class" {
	    set markExpr "^($type\\s*\[A-Za-z0-9~_\]+"
	    append markExpr "\\s*(\[A-Za-z0-9~_<>\]+)?\\s*"
	    append markExpr "(:(\\s+\[^\{\]+)*)?\{)"
	    set subMarkExpr "$type +(\[A-Za-z0-9~_\]+)"
	}
	"struct" - "union" {
	    set markExpr1 "typedef +$type\[ \t\]*\{\[^\}\]*\}\[ \t\]*\[A-Za-z0-9~_\]+;"
	    set markExpr2 "($type\\s*\[A-Za-z0-9~_\]+"
	    append markExpr2 "\\s*(\[A-Za-z0-9~_<>\]+)?\\s*\{)"
	    set markExpr "($markExpr1|$markExpr2)"
	    set subMarkExpr "(\[A-Za-z0-9~_\]+) *(;|\{)$"
	}
	"template" {
	    set markExpr "^($type\\s*<\[^>\]*>"
	    append markExpr "\\s*\[A-Za-z0-9~_\]+\\s+\[A-Za-z0-9~_\]+\\s*\{)"
	    set subMarkExpr "(\[A-Za-z0-9~_\]+) *\{"
	}
	"typedef" {
	    set markExpr "$type\[^;\{\]*;"
	    set subMarkExpr "(\[A-Za-z0-9~_\]+) *;$"
	}
	"define" {
	    set markExpr "\#$type\[ \t\]+(\[^ \(\n\r]*)\[^\r\n\]*$"
	    set subMarkExpr $markExpr
	}
	"operator" {
	    set markExpr "$type\[ \t\]*(\[^ \t\n\r]*)\[ \t\]*\\("
	    set subMarkExpr $markExpr
	}
    }      
    while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 0 "$markExpr" $pos} res]} {
	set pos [lindex $res 1]
	set start [lindex $res 0]
	set thistext [getText -w $win $start $pos]
	regsub -all "\[\r\n\t\]" [string trimright $thistext] " " thistext
	if {[regexp $subMarkExpr $thistext dummy word]} {
	    if {$type!="typedef" || [lsearch -exact [getNamedMarks -w $win -n] "  $word"]=="-1"} {
		set inds($word) $start
	    } 
	}
    }
    if {[info exists inds]} {
	setNamedMark -w $win "[string toupper $type]:" [minPos] [minPos] [minPos]
	foreach f [lsort -dictionary [array names inds]] {
	    set next [lineStart -w $win $inds($f)]
	    set item $f
	    if {[string length $item] > 57} { set item "[string range $item 0 53]..." }
	    setNamedMark -w $win "  ${item}" "$inds($f)" $next $next
	}
	# This is a trick to have a separator line after _each_ category (only the dash is
	# marked, not $type; thus we have different marks producing a separator line) :
	setNamedMark -w $win "-$type" [minPos] [minPos] [minPos]
    }
}

proc C::MarkRezFile {args} {
    win::parseArgs win

    # Mark 'type' statements
    set markExpr "^\[ \t\]*type\[ \t\]+'(\[a-zA-Z0-9 _\#\*\]+)'\[ \t\r\n\]+(\\\{|as)"
    set end [maxPos -w $win]
    set pos [minPos -w $win]
    while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 1 $markExpr $pos} res]} {
	set start [lindex $res 0]
	set end [lindex $res 1]
	set txt [getText -w $win $start $end]
	regexp $markExpr $txt "" rezname
	set pos [nextLineStart -w $win $start]
	set inds($rezname) [lineStart -w $win [pos::math -w $win $start - 1]]
    }
    if {[info exists inds]} {
	setNamedMark -w $win "TYPE:" [minPos] [minPos] [minPos]
	foreach f [lsort -dictionary [array names inds]] {
	    set next [nextLineStart -w $win $inds($f)]
	    setNamedMark -w $win "  $f" $inds($f) $next $next
	}
	setNamedMark -w $win "-type" [minPos] [minPos] [minPos]
	unset inds
    }
    # Mark 'resource' and 'data' statements
    set markExpr "^\[ \t\]*(resource|data)\[ \t\]+'(\[a-zA-Z0-9 _\#\*\]+)'"
    append markExpr "\[ \t\r\n\]+\\\( *(\[-a-zA-Z0-9 _\#\*\]+)"
    set end [maxPos -w $win]
    set pos [minPos -w $win]
    while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 1 $markExpr $pos} res]} {
	set start [lindex $res 0]
	set end [lindex $res 1]
	set txt [getText -w $win $start $end]
	regexp $markExpr $txt "" type rezname reznum
	set pos [nextLineStart -w $win $start]
	set inds(${rezname}$reznum) [lineStart -w $win [pos::math -w $win $start - 1]]
    }
    if {[info exists inds]} {
	setNamedMark -w $win "RESOURCE/DATA:" [minPos] [minPos] [minPos]
	foreach f [lsort -dictionary [array names inds]] {
	    set next [nextLineStart -w $win $inds($f)]
	    setNamedMark -w $win "  [string range $f 0 3] [string range $f 4 end]" $inds($f) $next $next
	}
	unset inds
    }
}

# ObjectiveC Marking
# ------------------
# In Objc source files :
# 	mark the implementations and their methods. Mark C functions.
# In Objc header files :
# 	mark the interfaces and their methods. Mark the protocols.

proc Objc::MarkFile {args} {
    win::parseArgs win
    
    global ObjcmodeVars
    set ext [file extension $win]
    # Do we have a header file (1) or a source file (0) :
    set isHeader [expr {[lsearch -exact [set ObjcmodeVars(headerSuffices)] $ext]==-1 ? 0 : 1}]
    if {$isHeader} {
	# Marking various types of declarations
	foreach type [list interface protocol] {
	    Objc::doFuncsMarking -w $win $type
	} 
	foreach type [list struct union] {
	    C++::otherMarks -w $win $type
	} 
    } else {
	Objc::doFuncsMarking -w $win implementation
	C::doFuncsMarking -w $win 0
    }
}

# class-method-declaration:
#     + [ method-type ] method-selector ;
# instance-method-declaration:
#     ­ [ method-type ] method-selector ;
proc Objc::doFuncsMarking {args} {
    win::parseArgs win type
    
    set bega [minPos -w $win]
    set markBegExpr "^@$type\\s*(\[A-Za-z0-9~_\]+)\\s*(\\(\[A-Za-z0-9~_\]+\\))?"
    set markEndExpr "^@end"
    set methodExpr "^(-|\\+)(\[ \t\]*\\(\[A-Za-z0-9~_\\* \]+\\)\\s*\[A-Za-z0-9 \]+\[: \]*)+"
    while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 0 "$markBegExpr" $bega} resa]} {
	set category ""
	set enda [lindex $resa 1]
	set bega [lindex $resa 0]
	set thistext [getText -w $win $bega $enda]
	if {[regexp $markBegExpr $thistext dummy class category]} {
	    if {$category!=""} {
		regsub -all {[()]} $category "" category
	        set class "${class}_$category"
	    } 
	    set inds($class) $bega
	}
	if {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 0 "$markEndExpr" $enda} resb]} {
	    set begb [lindex $resb 0]
	    set endb [lindex $resb 1]
	    set bega $endb
	    while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 0 -l $begb "$methodExpr" $enda} resc]} {
		set begc [lindex $resc 0]
		set enda [lindex $resc 1]
		set thistext [getText -w $win $begc $enda]
		if {[regexp $methodExpr $thistext word prefix dumm]} {
		    regsub -all ":\\(\[^\)\]+\\)\\s*\[A-Za-z0-9~_\]+ *" $word ":" word
		    regsub -- "(-|\\+)\[ \t\]*\\(\[^\)\]+\\)" $word "" word
		    set word [string trim $word]
		    eval "set inds$class\($prefix$word\) $begc"
		}
	    }
	} else {
	    alertnote "Runaway declaration: missing @end."
	    return
	}
    }
    if {[info exists inds]} {
	setNamedMark -w $win "[string toupper $type]S:" [minPos] [minPos] [minPos]
	foreach cl [lsort -dictionary [array names inds]] {
	    set next [lineStart -w $win $inds($cl)]
	    if {[regsub -all "_" $cl "  (" itm]} {
	        append itm )
	    } 
	    setNamedMark -w $win "$itm" "$inds($cl)" $next $next
	    if {[info exists inds$cl]} {
		foreach m [lsort -dictionary [array names inds$cl]] {
		    eval set next [lineStart -w $win [set inds$cl\($m\)]]
		    set item $m
		    if {[string length $item] > 57} { set item "[string range $item 0 53]..." }
		    setNamedMark -w $win "  $item" [set inds$cl\($m\)] $next $next
		}
	    }
	}
	# This is a trick to have a separator line after _each_ category (only the dash is
	# marked, not $type; thus we have different marks producing a separator line) :
	setNamedMark -w $win "-$type" [minPos] [minPos] [minPos]
    }
}


proc C::parseFuncs {} {
    set result ""
    # Marking the #define's
    set definelist [C++::parseSome define]
    # Marking the #include's
    set includelist [C++::parseSome include]
    # Building the result
    if {$definelist!=""} {
	set result $definelist
    }
    if {$includelist!=""} {
	if {$result!=""} {
	    set result [concat $result "\(- 0" $includelist]
	} else {
	    set result $includelist
	}
    }
    return $result
}

proc C++::parseFuncs {} {
    set result [C::parseFuncs]
    # Marking the methods in each class
    set methodlist [C++::parseMethods]
    # Building the result
    if {$methodlist!=""} {
	if {$result!=""} {
	    set result [concat $result "\(- 0" $methodlist]
	} else {
	    set result $methodlist
	}
    }
    return $result
}

proc C++::parseSome {what} {
    set pos [minPos]
    set title [string toupper $what]
    set thesection [list $title $title]
    set thelist ""
    set markExpr "\#$what\[ \t\]+(\[^ \(\t\n\r]*)\[^\r\n\]*$"
    while {[set res [search -s -f 1 -r 1 -i 0 -n $markExpr $pos]] != ""} {
	if {[regexp -- $markExpr [eval getText $res] "" word]} {
	    regsub -all \[<>\"\] $word "" word
	    lappend thelist [list "  $word" [lindex $res 0]]
	}
	set pos [lindex $res 1]
    } 
    if {[llength $thelist]} {
	foreach pair [lsort -dictionary [set thelist]] {
	    eval lappend thesection $pair
	}
	return $thesection
    } else {
	return ""
    }
}

proc C++::parseMethods {} {
    set thelist ""
    set pos [minPos]
    # Regexp to find class definitions
    set classExpr "^(class\[ \t\]+\[A-Za-z0-9~_\]+"
    append classExpr "\\s*(\[A-Za-z0-9~_<>\]+)?\\s*"
    append classExpr "(:\[^\{\]*)?\{)"
    set subClassExpr "class\[ \t\]+(\[A-Za-z0-9~_\]+)"
    # Regexp to find method declarations	
    set methodExpr "^\[ \t\]*(\[A-Za-z0-9~_\]+\\s*\\(|(\[^ \t\(#\n\r/@\*\]\[^=\r\n\]*\[ \t\]+\\*?)?"
    append methodExpr "(\[A-Za-z0-9~_\]+\[-A-Za-z0-9~_+ <>\|\\*/\]+|\[A-Za-z0-9~_\]+)"
    append methodExpr "\[ \n\t\r\]*\\()"
    set subMethodExpr "(\[A-Za-z0-9~\&_-\]+)\[ \t\]*\\("
    # Looking for a class definition
    while {![catch {search -s -f 1 -r 1 -m 0 -i 0 "$classExpr" $pos} res]} {
	set pos [lindex $res 1]
	set start [lindex $res 0]
	set thistext [getText $start $pos]
	regexp $subClassExpr $thistext dummy classname
	eval lappend thelist [list "CLASS '$classname'" [lindex $res 0]]
	# Find the closing brace of the class definition
	if {[catch {set closepos [matchIt "\{" [lindex $res 1]]}]} {
	    alertnote "Missing close brace"
	    return ""
	}
	# Inside this class, find the methods
	set currpos $pos
	while {![catch {search -s -f 1 -r 1 -m 0 -i 0 -l $closepos "$methodExpr" $currpos} res]} {
	    set currpos [lindex $res 1]
	    set currstart [lindex $res 0]
	    set thistext [getText $currstart $currpos]
	    regsub -all "\[\r\n\t\]" [string trimright $thistext] " " thistext
	    if {[regexp $subMethodExpr $thistext dummy method]} {
		eval lappend thelist [list "  $method" [lindex $res 0]]
	    }
	}
    }
    return $thelist
}

proc Objc::parseFuncs {} {
    set result ""
    # Marking the #define's
    set definelist [C++::parseSome define]
    # Marking the #import's
    set importlist [C++::parseSome import]
    # Building the result
    if {$definelist!=""} {
	set result $definelist
    }
    if {$importlist!=""} {
	if {$result!=""} {
	    set result [concat $result "\(- 0" $importlist]
	} else {
	    set result $importlist
	}
    }
    return $result
}


# ×××× Indentation routines ×××× #

proc C::indentLine {args} {uplevel 1 C++::indentLine $args}
proc Objc::indentLine {args} {uplevel 1 C++::indentLine $args}

 ## 
  # -------------------------------------------------------------------------
  #	 
  #	"C++indentLine" --
  #	
  #  More sophisticated version of Pete's.  Handles things like '(...)'
  #  expressions split over multiple lines, if/elseif/else both with
  #  and without curly braces, multiple line stream manipulation with
  #  '<<' or '>>', C and C++ style comments, ...  Assumes indentation
  #  is '4' but any tab-size may be used.
  #	 
  #  Current bugs: multi-line ',' separated lists are poorly indented.
  #
  #  Problems:
  #   matchIt's limit doesn't seem to work, so if there is no match and we're
  #   in a large file, we wait up to seconds sometimes.  Alpha bug.
  #		   
  #  Currently checking whether we're in a /*...*/ comment is quite
  #  time consuming.  It would be nice if Alpha supplied a hook to do
  #  this for us.
  #   
  # Results: 
  #  Indents the current line correctly ;-) for C, C++ coding
  #	 
  # --Version--Author------------------Changes-------------------------------  
  #	  1.0	  Pete Keleher			  original
  #    2.0     <vince@santafe.edu> updated as described above.
  #    2.1     <vince@santafe.edu> faster, better, uses positions not strings
  #    2.2     <vince@santafe.edu> uses 'correctIndentation' sub proc
  # -------------------------------------------------------------------------
  ##
proc C++::indentLine {args} {
    win::parseArgs w
    set beg [lineStart -w $w [getPos -w $w]]
    # Are we in a C comment /*...*/ ?
    if {![catch {C_inCComment $w $beg} comment]} {
	# If so indent specially and return.  We really need to work
	# out how to put this in 'C++::correctIndentation', so that this
	# proc (as well as 'Java::indentLine') could be removed entirely.
	set fChar [search -w $w -s -f 1 -r 1 "\[^ \t\r\n\]" $beg]
	if {[lookAt -w $w [lindex $fChar 0]] == "*"} {
	    return [eval [list C_indentCommentLine $w $beg] $comment]
	}
    }
    # No, so we can use the default procedure, which will call
    # C++::correctIndentation.
    ::indentLine -w $w
}


proc C::correctIndentation {args} {eval C++::correctIndentation $args}
proc Objc::correctIndentation {args} {eval C++::correctIndentation $args}

## 
 # -------------------------------------------------------------------------
 # 
 # "C++::correctIndentation" --
 # 
 #  Known bugs:
 #  
 #  Lines which contain a URL with :// embedded tend to be considered
 #  a ':' followed by a comment, and are indented as if they were
 #  part of a 'case://comment' statement which is wrong.
 # -------------------------------------------------------------------------
 ##
proc C++::correctIndentation {args} {
    win::parseArgs w pos {nextword ""}
    # preliminaries
    set beg [lineStart -w $w $pos]
    set nextCh [string range $nextword 0 3]
    set nextC [string index $nextCh 0]
    set nextP [string range $nextCh 0 1]
    # check for forced indentation of C, C++ comments and '#' macros
    set ind "code 0"
    switch -- $nextC {
	"\#" {
	    set ignore_trailers 1
	    set ind [win::getModeVar $w indentMacros "code 0"]
	}
	"/" {
	    set ignore_trailers 1
	    if {$nextP == "/*"} {
		set ind [win::getModeVar $w indentComments]
	    }
	    if {$nextP == "//"} {
		set ind [win::getModeVar $w indentC++Comments]
	    }
	}
    }
    if {[lindex $ind 0] == "fixed" } {
	# force indentation to given level
	return [lindex $ind 1]
    }
    
    set ia [text::getIndentationAmount -w $w]

    # (1) first we get the indent of the last line:
    # this may involve looking back a fair way
    set lst [C_prevCodeIndent $w [pos::math -w $w $beg - 1]]
    
    if {[pos::compare -w $w [set pstart [lindex $lst 0]] == [minPos]]} {
	return 0
    }
    set lwhite [lindex [pos::toRowCol -w $w [pos::math -w $w [lindex $lst 1] - 1]] 1]
    # have we just finished an if-elseif-else with no '{}'?
    set iselse [expr {$nextCh eq "else"}]
    # If the prev line (pstart) is not a no-brace-indent, the line 
    # before it might be (in which case the previous line was specially 
    # indented, and this line should _not_ be!).  So, we have three 
    # cases of importance:
    # 
    #  - the previous line is a no-brace-indent, which means this line
    #    needs to be treated specially (this line +indentamount compared
    #    to previous one, unless this line starts with an open brace)
    #    
    #  - the previous line was not a no-brace-indent, but the line
    #    before it was (this line -indentamount compared to previous 
    #    one, unless the previous one started with an open brace, in 
    #    which case this line +indentamount)
    #    
    #  - neither the previous line nor the one before are 
    #    no-brace-indents (this line indent as previous one).
    # 
    if {![C_isLineNBI $w $pstart]} {
	set inc [C_recurseNoBraceIndent $w $pstart 0 $iselse]
	incr lwhite $inc
	if {$inc != 0} {
	    if {[lookAt -w $w [pos::math -w $w [lindex $lst 1] -1]] eq "\{"} {
		incr lwhite $ia
	    }
	}
    } else {
        if {$nextC ne "\{"} {
	    incr lwhite $ia
	}
    }
    
    if {[set multi [C_isLineMulti $w $pstart]] != -1} {
	set lwhite $multi
    }
    
    # (2) now we indent this line accordingly
    
    set pbeg [pos::prevLineStart -w $w $beg]
    set backpos [pos::nextLineStart -w $w [lindex $lst 0]]
    # is there a comment at the end of the line? if so scan back to the character we want
    if {![catch {search -w $w -s -f 0 -r 1 \
      -l $pbeg "//\[^\r\n\]*\[\n\r\]" $backpos} compos]} {
	set compos [lindex $compos 0]
	if {[pos::compare -w $w $compos > $pbeg]} {
	    set backpos [pos::math -w $w $compos + 1]
	}	
    }
    set specialIndentForCaseLabel [win::getModeVar $w specialIndentForCaseLabel]
    if {[pos::compare -w $w [set backpos [pos::math -w $w $backpos - 2]] > [minPos]]} {
	set lst [search -w $w -s -f 0 -r 1 -m 0 "\[^ \t\r\n\]" $backpos]
	switch -- [lookAt -w $w [lindex $lst 0]] {
	    "\{" {
		incr lwhite $ia
	    } 
	    ":" {
		if {$specialIndentForCaseLabel \
		  && ([lookAt -w $w [pos::math -w $w [lindex $lst 0] - 1]] != ":")} {
		    # expression is better for odd indentationAmounts
		    incr lwhite [expr {$ia - $ia/2}]
		}
	    } 
	    "\)" {
		# see if we're in a if-elseif-else with no '{}' and indent
		#if {[C_isLineNBI $w $pstart]} {incr lwhite $ia}
	    }
	    "e" {
		if { [getText -w $w [pos::math -w $w [lindex $lst 0] - 3] \
		  [pos::math -w $w [lindex $lst 0] + 1]] == "else" } {
		    #if {[C_isLineNBI $w $pstart]} {incr lwhite $ia}
		}
		
	    }
	}
    }
    
    switch -- $nextC {
	"\}" {
	    incr lwhite [expr -$ia]
	}
	"<" -
	">" {			
	    # indent for '<<' and '>>' in multi-line C++ stream manipulation
	    if {$nextP == "<<" || $nextP == ">>"} {
		set strm [search -w $w -s -f 1 -r 1 "^\[^${nextC}\]+${nextP}" $pbeg]
		set lwhite [lindex [pos::toRowCol -w $w [pos::math -w $w [lindex $strm 1] - 2]] 1]
	    }
	}
    }
    # Check if we're in a multi-line '(.....)' if so align to start
    set useFasterButWorseIndentation [win::getModeVar $w useFasterButWorseIndentation 0]
    if {!$useFasterButWorseIndentation && ![catch {matchIt -w $w ")" $beg 500} paren]} {
	set lwhite [lindex [pos::toRowCol -w $w [pos::math -w $w $paren + 1]] 1]
    }

    if {$specialIndentForCaseLabel \
      && [regexp "^(case\[ \t\].*|\[a-zA-Z\]+):(\[^:\]|\$)" $nextword] && $lwhite > 3 \
      && ![info exists ignore_trailers]} {
	incr lwhite [expr -$ia/2]
    }
    # get indentation level	
    incr lwhite [lindex $ind 1]
    if {$lwhite < 0} {
	return 0
    } else {
        return $lwhite
    }
}

proc C::CommentLine {} {C++::CommentLine}

proc C++::CommentLine {} {
    set ext [file extension [win::CurrentTail]]
    if {$ext != ".h" && $ext != ".c"} {
	insertPrefix
    } else {
	::CommentLine
    }
}

proc C::UncommentLine {} {C++::UncommentLine}

proc C++::UncommentLine {} {
    set ext [file extension [win::CurrentTail]]
    if {$ext != ".h" && $ext != ".c"} {
	removePrefix
    } else {
	::UncommentLine
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "C++::electricLeft" --
 # 
 #  For those who like to place left braces after 'for', 'else' etc. on 
 #  their own line, this will ensure the left brace is correctly placed.
 # -------------------------------------------------------------------------
 ##
proc C++::electricLeft {} {
    if {[string trim [getText [lineStart [getPos]] [getPos]]] == ""} {
	if {[C_isLineNBI [win::Current] [pos::prevLineStart [getPos]]]} {
	    set p [lineStart [getPos]]
	    insertText "\{\r"
	    goto $p
	    shiftLeft
	    goto [nextLineStart $p]
	    bind::IndentLine
	    return
	}
    }
    ::electricLeft
}

proc C::electricLeft {} {C++::electricLeft}
proc Objc::electricLeft {} {C++::electricLeft}

## 
 # -------------------------------------------------------------------------
 #	 
 # "C_recurseNoBraceIndent" --
 #	
 # Scans back until we no longer have a 'no brace indent'.  A 'no brace
 # indent' is a 'for', 'if' etc which didn't use '{ ...  }'
 # -------------------------------------------------------------------------
 ##
proc C_recurseNoBraceIndent {w pos offset {iselse 0}} {
    set pos [pos::prevLineStart -w $w $pos]
    if {[C_isLineNBI $w $pos]} {
	set ia [text::getIndentationAmount -w $w]
	if {$iselse} {
	    set p [text::firstNonWsPos -w $w $pos]
	    set t [getText -w $w $p [pos::math -w $w $p + 10]]
	    if {[regexp -- "(else\[ \t\]+)?if.*" $t]} {
		return [expr {$offset -$ia}]
	    }
	}
	return [C_recurseNoBraceIndent $w $pos [incr offset [expr -$ia]] $iselse]
    }
    return $offset
    
}

set C_recNBI {^[[:blank:]]*((\}?[[:blank:]]*(if|else[[:blank:]]+if)|for)[[:blank:]]*\([^()]*\)|\}?[[:blank:]]*else)[[:blank:]]*(//[^\r\n]*)?[ \t]*}

## 
 # -------------------------------------------------------------------------
 #	 
 # "C_isLineNBI" --
 #	
 #  Tests if the given line is a 'no brace indent'.  'pos' is the beginning
 #  of the line in question, else this proc will fail.
 #  
 # -------------------------------------------------------------------------
 ##
proc C_isLineNBI {w pos} {
    global C_recNBI
    set posL [pos::nextLineStart -w $w [pos::nextLineStart -w $w $pos]]
    if {![catch {search -w $w -s -f 1 -r 1 -l $posL -- $C_recNBI $pos} ifelse]} {
	if {[pos::compare -w $w $pos == [lindex $ifelse 0]]} {
	    if {[pos::compare -w $w [lindex $ifelse 1] == [maxPos -w $w]]} {
		return 1
	    }
	    set last [lookAt -w $w [lindex $ifelse 1]]
	    if {[regexp {[\r\n]} $last]} {
		return 1
	    }
	}
    }
    return 0
}

# use 'catch' to call this proc: error = no, otherwise returns st,end pos
proc C_inCComment {w pos} {
    set cS [search -w $w -s -f 0 -r 0 -l [pos::math -w $w $pos - 1000] "/*" $pos]
    set cE [search -w $w -s -f 1 -r 0 -l [pos::math -w $w $pos + 1000] "*/" [lindex $cS 1]]
    if {[pos::compare -w $w $pos >= [lindex $cE 1]] } {
	error "No"
    } else {
	return [list [lindex $cS 0] [lindex $cE 1]]
    }
}

# look for '<<' and '(...)' multi lines.
proc C_isLineMulti {w pos} {
    # look for multi-line '(...)'
    if { ![catch {search -w $w -s -f 0 -r 1 -l $pos {\)[^\r\n]*$} [nextLineStart -w $w $pos]} paren] \
      && [pos::compare -w $w [nextLineStart -w $w $pos] == [pos::math -w $w [lindex $paren 1] + 1 ]] } {
	if {[catch {matchIt -w $w "\)" [pos::math -w $w [lindex $paren 0] - 1] 500} realStart]} {
	    return -1
	}
	if {[pos::compare -w $w [lineStart -w $w $realStart] != [lineStart -w $w [lindex $paren 0]]] } {
	    set lst [search -w $w -s -f 0 -r 1 -i 0 "^\[ \t\]*\[^ \t\r\n\]" $realStart]
	    return [lindex [pos::toRowCol -w $w [pos::math -w $w [lindex $lst 1] - 1]] 1]
	}
    }
    # look for multi-line '<<' or '>>'
    set p $pos
    while {![catch {search -w $w -s -f 1 -r 1 -l [nextLineStart -w $w $p] "^\[ \t\]*(<<|>>)" $p} strm] } {
	set p [pos::prevLineStart -w $w $p]
    }
    if { $p != $pos } {
	set lst [search -w $w -s -f 1 -r 1 -i 0 "^\[ \t\]*\[^ \t\r\n\]" $p]
	return [lindex [pos::toRowCol -w $w [pos::math -w $w [lindex $lst 1] - 1]] 1]
    }
    
    return -1
    
}

## 
 # -------------------------------------------------------------------------
 #   
 # "C_indentCommentLine" --
 #  
 #  Indents a line within a multi-line /* ... */ comment correctly.
 # -------------------------------------------------------------------------
 ##
proc C_indentCommentLine {w beg cS cE} {
    set p [getPos -w $w]
    # Turn all extraneous leading characters into spaces.
    regsub -all "\[^ \t\r\n\]" [getText -w $w [lineStart -w $w $cS] $cS] " " lwhite
    if {[text::indentUsingSpacesOnly -w $w]} {
	set lwhite [text::maxSpaceForm -w $w $lwhite]
    } else {
	set lwhite [text::minSpaceForm -w $w $lwhite]
    }
    if {[pos::compare -w $w $beg != [lineStart -w $w [lindex $cE 0]]] \
      || [text::firstNonWs -w $w [pos::math -w $w $beg - 1]] == "*" } {
	append lwhite " "
    }
    set text [getText -w $w $beg [nextLineStart -w $w $beg]]
    regexp "^\[ \t\]*" $text white
    set next [pos::math -w $w $beg + [string length $white]]
    if {$white != $lwhite} {
	replaceText -w $w $beg $next $lwhite
    }
    if {[win::getModeVar $w positionAfterIndentation] \
      && [string length [string trim $text]]} {
	# Keep relative position.
	set to [pos::math -w $w $p + [string length $lwhite] - [pos::diff -w $w $beg $next]]
	if {[pos::compare -w $w $to < $beg]} {
	    goto -w $w $beg
	} else {
	    goto -w $w $to
	}
    } else {
	goto -w $w [pos::math -w $w $beg + [string length $lwhite]]
    }
}

## 
 # -------------------------------------------------------------------------
 #   
 # "C_prevCodeIndent" --
 #  
 #  Find the indent of the previous line
 #  -  If it's the start of the file, return [minPos] [minPos] (special case)
 #  else
 #  -  if it's a C++ comment, keep looking backwards (so you can offset
 #     C++ comments if you so desire)
 #  -  if it's a C comment, get the indentation of the '/*' not some
 #     intermediate point.
 # -------------------------------------------------------------------------
 ##
proc C_prevCodeIndent {w pos} { 
    while {1} {
	if {[pos::compare -w $w $pos == [minPos]] \
	  || ([catch {search -w $w -s -m 0 -f 0 -r 1 -i 0 "^\[ \t\]*\[^ \t\r\n\]" $pos} p]) \
	  || $p == [list [minPos] [minPos]] } {
	    return [list [minPos] [pos::math -w $w [minPos] + 1]]
	} else {
	    set pp [doubleLookAt [pos::math -w $w [lindex $p 1] - 1]]
	    if { $pp == "//" } {
		set pos [pos::math -w $w [lindex $p 0] - 1]
	    } elseif { [string index $pp 0] == "#" } {
		global indentMacros
		if {[info exists indentMacros] && ($indentMacros == "code 0")} {
		    break
		}
		set pos [pos::math -w $w [lindex $p 0] - 1]
	    } elseif { $pp == "*/" } {
		set pos [lindex [search -w $w -s -f 0 -r 0 "/*" \
		  [pos::math -w $w [lindex $p 0] - 1]] 0]
	    } elseif { ![catch {set comment [C_inCComment $w [lindex $p 0]]} ] } {
		set pos [pos::math -w $w [lineStart -w $w [lindex $comment 0]] - 1]
		#return [text::indentation [lindex $comment 0]] (old style)
	    } else {
		break
	    }
	}
    }
    return $p
}


# ×××× Electric routines ×××× #

proc C::carriageReturn {} {C++::carriageReturn}
proc Objc::carriageReturn {} {C++::carriageReturn}

proc C::OptionTitlebar {} {C++::OptionTitlebar}
proc Objc::OptionTitlebar {} {C++::OptionTitlebar}


## 
 # -------------------------------------------------------------------------
 #	 
 # "C++::carriageReturn" --
 #	
 #	Called by the general routine 'carriageReturn'.	We know	no selection 
 #	exists, and we are not inside a block comment.
 # -------------------------------------------------------------------------
 ##
proc C++::carriageReturn {} {
    global specialIndentForCaseLabel
    if {$specialIndentForCaseLabel \
      && ([lookAt [pos::math [getPos] - 1]] == ":")} {
	if {[regexp {[\r\n]} [lookAt [getPos]]]} {
	    bind::IndentLine
	    endOfLine
	    insertText "\r"
	} else {
	    set pos [getPos]
	    endOfLine
	    set t [getText $pos [getPos]]
	    replaceText $pos [getPos] ""
	    bind::IndentLine
	    endOfLine
	    insertText "\r"
	    insertText $t
	}
    } else {
	insertText "\r"
    }
    catch {bind::IndentLine}
}

proc C++::OptionTitlebar {} {
	if {![win::IsFile [win::Current]]} {return ""}
	
	# else just scan through, provided the scan will function
	set cid [scancontext create]
	set lines {}
	scanmatch $cid {#.*include.*(<|")(.*)(>|")}  {
		lappend lines $matchInfo(submatch1)
	}
	set fid [alphaOpen [win::StripCount [win::Current]] "r"]
	scanfile $cid $fid
	close $fid
	scancontext delete $cid
	return [lsort -dictionary -unique $lines]
}

proc C::foldableRegion {pos} { C++::foldableRegion $pos }

proc C++::foldableRegion {pos} {
    # Return start and end coordinates of the current block
    global funcExpr
    set got [search -s -f 0 -r 1 $funcExpr $pos]
    if {[string index [string trim [eval getText $got]] end] == "\)"} {
	# Have to search forwards for an opening brace
	set start [lindex [search -s -f 1 -r 0 "\{" [lindex $got 1]] 0]
    } else {
	set start [lindex $got 1]
    }
    set end [matchIt "\{" [pos::math $start +1]]
    return [list $start $end]
}

# ===========================================================================
# 
# .