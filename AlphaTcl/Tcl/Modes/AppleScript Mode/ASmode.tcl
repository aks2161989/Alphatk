# -*-Tcl-*- (nowrap)
# 
# File: ASmode.tcl
# 	        Created: 2002-03-10 11:54:39
#     Last modification: 2005-09-29 14:08:06
# Author: Bernard Desgraupes
# e-mail: <bdesgraupes@easyconnect.fr>
# Web-page: <http://webperso.easyconnect.fr/bdesgraupes/alpha.html>
# Description:
#     AppleScript mode is useful for editing, compiling, decompiling, executing,
#     processing scripts written in the AppleScript language. 
#     This is a complete rewriting of  the  previous  AppleScript  mode  by  John
#     Sarapata <sarapata_john@jpmorgan.com>.
#     Please read the doc in the AppleScript mode tutorial and the "AppleScript Help" 
#     file (it is located in the Help menu once the package is installed).
#  
# (c) Copyright: Bernard Desgraupes, 2002-2005
#     All rights reserved. This software is free software.  See  licensing  terms
#     in the AppleScript Help file.
#     
#     This file is part of the AppleScript mode package.


alpha::mode [list Scrp AppleScript] 2.3 appleScriptMenu {*.script *.scr *.scpt *.ascr} {
    appleScriptMenu
} {
    addMenu appleScriptMenu "¥331" Scrp
    set modeCreator(ToyS) Scrp  ;# AppleScript Editor
    set modeCreator(SLAB) Scrp  ;# ScriptLab
} maintainer {
    "Bernard Desgraupes" <bdesgraupes@easyconnect.fr>  <http://webperso.easyconnect.fr/bdesgraupes/alpha.html> 
} uninstall {
    this-directory
} description {
    Supports the editing of AppleScript programming files
} help {
    file "AppleScript Help"
} 

proc ASmode.tcl {} {}

# Only register these if we've actually loaded the mode or menu at least once.
set dimmitemslist [list  "compile" "execute" "run" "checkSyntax" ]
foreach item $dimmitemslist {
    hook::register requireOpenWindowsHook [list $appleScriptMenu $item] 1 
}
set dimmitemslist [list "Add Description" "Delete Description" "Line Continuation" "Colour & Mark Dictionary" ]
foreach item $dimmitemslist {
    hook::register requireOpenWindowsHook [list appleScriptUtils $item] 1 
}
unset dimmitemslist item

namespace eval Scrp {}

# Set up the mode specific preferences
newPref	v prefixString {-- } Scrp
newPref	v leftFillColumn {3} Scrp
newPref	v funcExpr {^on[ \t]+([^ \t]+)\(?} Scrp
newPref	v parseExpr {^[^ \t]+[ \t]+(\w+)} Scrp
newPref	v wordBreak {\w+} Scrp
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn 0 Scrp
# Working directory where the compiled scripts will be stored stored
if {($SUPPORT(user) ne "")} {
	newPref folder appleScriptsFolder [file join $SUPPORT(user) AppleScripts] Scrp \
	  {menu::buildScrpMenu}
} else {
	newPref folder appleScriptsFolder [file join $HOME AppleScripts] Scrp \
	  {menu::buildScrpMenu}
}
# Default colo(u)rs
newPref v commentColor red Scrp
newPref v keywordColor blue Scrp
newPref v stringColor green Scrp
# Set this flag if you want AppleScript mode to take care
# of descriptive comments stored as a TEXT resource in the
# compiled scripts.
newPref flag includeDescription 1 Scrp {menu::buildSome appleScriptFlags}
# Set this flag if you want AppleScript mode to take care
# of dynamic scripting terminology (i-e when an 'scsz' 
# resource is present) when trying to open a dictionary.
# This is useful mostly for applications with scriptable plug-ins.
newPref flag launchToGetTerminology 0 Scrp {menu::buildSome appleScriptFlags}
# Set this flag if you are compiling a context script and want it to 
# inherit bindings and properties from another context script. This parent
# script can be selected in the Scripts submenu with the Shift key down.
newPref flag inheritFromParent 0 Scrp {menu::buildSome appleScriptFlags}
# Set this flag so that your script is compiled as a context script. This 
# will make it possible to compile other scripts in this context.
newPref flag makeContext 1 Scrp {menu::buildSome appleScriptFlags}
# Set this flag if you want your script to be compiled in a specific 
# context. The context script must have been selected in the Scripts 
# submenu.
newPref flag runInContext 0 Scrp {menu::buildSome appleScriptFlags}
# Set this flag if you want your script to be compiled in augmentation to
# a specific context script. The context script can be selected 
# in the Scripts submenu with the Control key down.
newPref flag augmentContext 1 Scrp {menu::buildSome appleScriptFlags}

set scrp_params(currcontext) ""
set scrp_params(currparent) ""
# set scrp_params(scriptsubmenu) "/\x1escripts^|" 
set scrp_params(scriptsubmenu) "scripts"
set scrp_params(utils) [list  "<E<SAdd Description" "<S<IDelete Description" "Line Continuation" "(-" \
  "Open A DictionaryÉ" "Colour & Mark Dictionary" "(-" "Dump Mem Info" "Clear Memory" "(-" \
  "Apple Script Bindings" "Apple Script Tutorial" ]

proc Scrp::checkWorkingFolder {} {
    global ScrpmodeVars
    # Check for AppleScripts folder. Create it if missing.
    if {![file exists $ScrpmodeVars(appleScriptsFolder)]} {
	file mkdir $ScrpmodeVars(appleScriptsFolder)
    } 
}

Scrp::checkWorkingFolder

set Scrp::escapeChar "\\"
set Scrp::quotedstringChar "\""
set Scrp::lineContinuationChar "Â"

set Scrp::commentCharacters(General) "--"
# set Scrp::commentCharacters(Paragraph) [list "(* " " *)" " * "]
set Scrp::commentCharacters(Paragraph) [list "-- " "  --" " -- "]
set Scrp::commentCharacters(Box) [list "(*" 2 "*)" 2 "*" 3]

# Dummy proc
proc appleScriptMenu {} {}


# Menu building procs
# -------------------

proc Scrp::buildScriptsList {} {
    global ScrpmodeVars
    Scrp::checkWorkingFolder
    set scriptsList {}
    if {$alpha::macos == 1} {
	set listOsas [glob -nocomplain -type osas -dir $ScrpmodeVars(appleScriptsFolder) *]
	set listAppl [glob -nocomplain -type APPL -dir $ScrpmodeVars(appleScriptsFolder) *]
	set scriptsList [lsort -dictionary [concat $listOsas $listAppl]]
    } elseif {$alpha::macos == 2} {
	# The -types option does not work correctly on OSX
	set fullList [glob -nocomplain -dir $ScrpmodeVars(appleScriptsFolder) *]
	foreach f $fullList {
	    if {![file isdirectory $f] && ![catch {getFileInfo $f arr}]} {
		if {$arr(type) eq "osas" || $arr(type) eq "APPL"} {
		    lappend scriptsList $f
		} 
	    } 
	} 
    }    
    set ma [list "<E<SRebuild scripts list" "<S<IReveal scripts folder"]
    lappend ma "<S<BSelect a context" 
    lappend ma "<S<USelect a parent context"
    lappend ma "(-"
    foreach f $scriptsList {
	lappend ma "<E<S[file tail $f]"
	lappend ma "<S<I¥edit¥ [file tail $f]" ;#option
	lappend ma "<S<B [file tail $f]"       ;#control
	lappend ma "<S<U  [file tail $f]"      ;#shift
    } 
    return $ma
}

proc menu::buildScrpMenu {name} {
    global scrp_params
    Scrp::checkWorkingFolder 
    eval Menu -n "¥331" -p Scrp::menuProc \{ "newScript" "decompileAScriptÉ" "runAScriptÉ" \
      "(-" \{Menu -m -n "appleScriptFlags" \{\}\} "(-" \
      "compile" "execute" "run" "checkSyntax" "(-" \
      \{Menu -m -n "appleScriptUtils" -p Scrp::UtilsProc \{$scrp_params(utils)\}\} "(-"\
      \{Menu -m -n $scrp_params(scriptsubmenu) -p Scrp::scriptsFolderProc \{[Scrp::buildScriptsList]\}\}\}
    menu::buildSome appleScriptFlags
    catch {
	if {$scrp_params(currcontext) ne ""} {
	    markMenuItem $scrp_params(scriptsubmenu) \
	      "  [file tail $scrp_params(currcontext)]" 1
	}
	if {$scrp_params(currparent) ne ""} {
	    markMenuItem $scrp_params(scriptsubmenu) \
	      "    [file tail $scrp_params(currparent)]" 1 ×
	}
    }
}


# Build the menu
menu::buildProc appleScriptFlags {
    menu::buildFlagMenu appleScriptFlags array ScrpmodeVars
}
menu::buildProc appleScriptMenu {
    menu::buildScrpMenu ""
}

menu::buildSome appleScriptMenu

proc Scrp::menuProc {menu item} {
	eval Scrp::$item
}


proc Scrp::scriptsFolderProc {menu item} {
    global ScrpmodeVars scrp_params
    if {$item == "Rebuild scripts list"} {
	menu::buildScrpMenu ""
    } elseif {$item == "Reveal scripts folder"} {
	file::showInFinder $ScrpmodeVars(appleScriptsFolder)
    } elseif {$item == "Select a context"} {
	alert -t note -k "OK" -c "" -o "" "Info: selecting a script with the Control key down\
	  makes it the current context to be used when running a script with the flag\
	  \"Run in context\" set."
    } elseif {$item == "Select a parent context"} {
	alert -t note -k "OK" -c "" -o "" "Info: selecting a script with the Shift key down\
	  makes it a parent context to be used when compiling a context with the flag\
	  \"Inherit from parent\" set."
    } else {
	if {[regexp "^¥edit¥ (.*)" $item dumm item]} {
	    Scrp::decompile [file join $ScrpmodeVars(appleScriptsFolder) $item]
	    return
	} elseif {[regexp "^ (\[^ \].*)" $item dumm item]} {
	    # Selecting a context script
	    catch {
		if {$scrp_params(currcontext) ne ""} {
		    markMenuItem $scrp_params(scriptsubmenu) \
		      " [file tail $scrp_params(currcontext)]" 0
		}
	    }
	    set scrp_params(currcontext) [file join $ScrpmodeVars(appleScriptsFolder) $item]
	    markMenuItem $scrp_params(scriptsubmenu) " $item" 1
	    status::msg "Choosing $item as running context"
	    return
	} elseif {[regexp "^  (\[^ \].*)" $item dumm item]} {
	    # Selecting a parent context
	    catch {
		if {$scrp_params(currparent) ne ""} {
		    markMenuItem $scrp_params(scriptsubmenu) \
		      "  [file tail $scrp_params(currparent)]" 0
		}
	    }
	    set scrp_params(currparent) [file join $ScrpmodeVars(appleScriptsFolder) $item]
	    markMenuItem $scrp_params(scriptsubmenu) "  $item" 1 ×
	    status::msg "Choosing $item as parent context"
	    return
	} 
	# Run the selected script
	Scrp::checkWorkingFolder
	set scr [file join $ScrpmodeVars(appleScriptsFolder) $item]
	if {[file exists $scr]} {
	    Scrp::displayResult "[Scrp::doRunAScript $scr]\r"
	} else {
	    alertnote "Weird ! Couldn't find file $scr"
	}
    }
}


proc Scrp::UtilsProc {menu item} {
    regsub -all " " $item "" item
    eval Scrp::$item
}


# Menu items procs
# ----------------
proc Scrp::newScript {} {
    global ScrpmodeVars    
    if {[catch {prompt "Name of the new script" "NewScript.scr"} scrname] || $scrname == ""} {
	return
    } 
    new -n $scrname -mode Scrp
    if {$ScrpmodeVars(includeDescription)} {Scrp::AddDescription} 
}


proc Scrp::insertScriptComment {comment} {
    if {$comment==""} {return} 
    goto [minPos]
    set commentlimits [Scrp::scriptCommentRange]
    if {![lindex [lindex $commentlimits 0] 1]} {
	# There is no descriptive comment. Insert one.
	insertText "(* Description\r\t$comment\r*)\r"
	goto [minPos]
	ring::+
    } else {
	# There is already a descriptive comment. Hilite it.
	eval selectText [lindex $commentlimits 0]
	status::msg "There is already a descriptive comment."
    }
}


proc Scrp::AddDescription {} {
    Scrp::insertScriptComment "¥"
}


proc Scrp::DeleteDescription {} {
    set commentlimits [Scrp::scriptCommentRange]
    eval selectText [lindex $commentlimits 0]
    deleteSelection
}


proc Scrp::scriptCommentRange {} {
    set commentstart [minPos]
    set commenttextstart [minPos]
    set commentend [minPos]
    set commenttextend [minPos]
    set pos [minPos]
    if {![catch {search -s -f 1 -r 1 {\(\* Description[ \t\r]*} $pos} res]} {
	set commentstart [lindex $res 0]
	set commenttextstart [lindex $res 1]
	if {![catch {search -s -f 1 -r 1 {[ \t\r]*\*\)} $commenttextstart} res]} {
	    set commenttextend [lindex $res 0]
	    set commentend [lindex $res 1]
	}
    }
    return [list [list $commentstart $commentend] [list $commenttextstart $commenttextend]]
}


proc Scrp::LineContinuation {} {
    insertText "Â\r"
}



# Syntax coloring
# ---------------
set ScrpKeyWords {
    after and as back before begin begins by close considering contains copy
    count data delete div does duplicate eighth else end ends equal equals
    error every exists fifth first fourth from front get global greater if
    ignoring in is it last launch less local make me middle mod move ninth
    not of on open or pi print prop property quit reference repeat result return
    run save script second set seventh sixth size some space start starts tab
    tell tenth than then third through thru timeout times to transaction try
    until while with 
}

regModeKeywords -e {--} -b {(*} {*)} -c $ScrpmodeVars(commentColor) \
  -k $ScrpmodeVars(keywordColor)  -s $ScrpmodeVars(stringColor)  Scrp $ScrpKeyWords



# Words completion
# ----------------

set completions(Scrp) {completion::cmd completion::electric}

set Scrpcmds $ScrpKeyWords

# We don't need the keywords anymore
unset ScrpKeyWords

# Abbreviations
set Scrpelectrics(tell)		" application \"¥¥\"\n\t¥¥\nend tell"
set Scrpelectrics(on)		" ¥¥(¥¥)\n\t¥¥\nend ¥¥"
set Scrpelectrics(if)		" ¥¥ then\n\t¥¥end if"
set Scrpelectrics(try)		"\n\t¥¥\non error\n\t¥¥\n\treturn\nend try"
set Scrpelectrics(repeat)	" with ¥¥ in ¥¥\n\t¥¥\nend repeat"


# File Marking
# ------------
proc Scrp::MarkFile {args} {
    global ScrpmodeVars
    win::parseArgs w
    status::msg "Marking \"[win::Tail $w]\" É"
    set pos [minPos -w $w]
    set pat $ScrpmodeVars(funcExpr)
    while {![catch {search -w $w -s -f 1 -r 1 -m 0 -i 1 -- $pat $pos} res]} {
	set start [lindex $res 0]
	set end [lindex $res 1]
	set pos $end
	set text [getText -w $w $start $end]
	# Eliminate "on error" statements: they are not functions.
	regexp $ScrpmodeVars(funcExpr) $text dumm fnct
	set fnct [string trim $fnct " \r\n"]
	if {$fnct!="error"} {
	    set inds($fnct) $res
	} 
    }
    set count 0
    if {[info exists inds]} {
	foreach f [lsort [array names inds]] {
	    setNamedMark -w $w $f \
	      [lineStart -w $w [pos::math -w $w \
	      [lineStart -w $w [lindex $inds($f) 0]] - 1]] \
	      [lindex $inds($f) 0] [pos::math -w $w [lindex $inds($f) 1] - 1]
	    incr count
	}
    }
    set msg "The window \"[win::Tail $w]\" contains $count mark"
    append msg [expr {($count == 1) ? "." : "s."}]
    status::msg $msg
    return
}


proc Scrp::correctIndentation {args} {
    uplevel 1 ::correctBracesIndentation $args
}


# Option-clicking the title bar
# -----------------------------
proc Scrp::OptionTitlebar {} {
    global ScrpmodeVars
    Scrp::checkWorkingFolder
    set scriptsList [glob -nocomplain -type osas -dir $ScrpmodeVars(appleScriptsFolder) *]
    set appsList [glob -nocomplain -type APPL -dir $ScrpmodeVars(appleScriptsFolder) *]
    set scrlist ""
    foreach f [lsort -dictionary [concat $scriptsList $appsList]] {
	lappend scrlist "[file tail $f]"
    } 
    return $scrlist
}


proc Scrp::OptionTitlebarSelect {item} {
    global ScrpmodeVars
    Scrp::decompile [file join $ScrpmodeVars(appleScriptsFolder) $item]
}


# Key bindings
# ============
# We define AppleScript mode specific key bindings: all of them use 'ctrl-a'
# followed by a letter. For instance, to decompile and  edit  a  script,  hit
# 'ctrl-a' and then the letter 'o'.
Bind 'a' <z> prefixChar Scrp
# 'ctrl-a b'	display bindings info
Bind 'b' <A> {Scrp::AppleScriptBindings} Scrp
# 'ctrl-a n'	create a new script
Bind 'n' <A> {Scrp::newScript} Scrp
# 'ctrl-a d'	decompile and open a script
Bind 'd' <A> {Scrp::decompileAScript} Scrp
# 'ctrl-a c'	compile the current window or selection
Bind 'c' <A> {Scrp::compile} Scrp
# 'ctrl-a e'	execute (compile and run) the current window
Bind 'e' <A> {Scrp::execute} Scrp
# 'ctrl-a r'	run a script
Bind 'r' <A> {Scrp::run} Scrp
# 'ctrl-a s'	check the syntax
Bind 's' <A> {Scrp::checkSyntax} Scrp
# 'ctrl-a t'	open a terminology dictionary
Bind 't' <A> {Scrp::OpenADictionary} Scrp
# 'ctrl-a x'	free compiled scripts in memory
Bind 'f' <A> {Scrp::ClearMemory} Scrp
# 'ctrl-a m'	dump memory info
Bind 'm' <A> {Scrp::DumpMemInfo} Scrp
# 'ctrl-a l'	insert the line continuation symbol "Â"
Bind 'l' <A> {Scrp::LineContinuation} Scrp


proc Scrp::AppleScriptBindings {} {
    global tileLeft tileTop tileWidth errorHeight
    set mess [Scrp::bindingsInfoString]
    new -g $tileLeft $tileTop [expr $tileWidth*.7] [expr $errorHeight *2] -n "* AppleScript Mode Bindings *" -info $mess
    set start [minPos]
    while {![catch {search -f 1 -s -r 1 -i 1 {('|<)[a-z= -]+('|>)} $start} res]} {
	text::color [lindex $res 0] [lindex $res 1] 1
	set start [lindex $res 1]
    }
    text::color 0 [nextLineStart 0] 5
    refresh
}


proc Scrp::bindingsInfoString {} {
    set mess "KEY BINDINGS AVAILABLE IN APPLESCRIPT MODE\n\n"
    append mess "Press 'ctrl-a', release, then hit one of the following letters:\n"
    append mess "  'b'	display this <b>indings info\n"
    append mess "  'c'	<c>ompile the current window or selection\n"
    append mess "  'd'	<d>ecompile) a script\n"
    append mess "  'e'	<e>xecute (compile and run) the current window or selection\n"
    append mess "  'f'	<f>ree compiled scripts in memory\n"
    append mess "  'l'	insert the <l>ine continuation symbol \"Â\"\n"
    append mess "  'm'	dump <m>emory info\n"
    append mess "  'n'	create a <n>ew script\n"
    append mess "  'r'	<r>un a script\n"
    append mess "  's'	check the <s>yntax\n"
    append mess "  't'	open a terminology <d>ictionary\n"
    append mess "\nIn the Scripts submenu, select a script\n"
    append mess "- with no modifier key:        to run the script\n"
    append mess "- with the <Option> key down:  to decompile the script\n"
    append mess "- with the <Control> key down: to select the script as context\n"
    append mess "- with the <Shift> key down:   to select the script as parent\n"
    return $mess
}


# # # Tutorial # # #
# ------------------
proc Scrp::AppleScriptTutorial {} {
    help::openExample "AppleScript Example" 
}

