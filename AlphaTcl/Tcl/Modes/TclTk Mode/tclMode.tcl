## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl support packages
 # 
 # FILE: "tclMode.tcl"
 #                                          created: 04/05/1997 {09:31:10 pm}
 #                                      last update: 03/21/2006 {03:27:39 PM}
 # Description:
 # 
 # Adds support for Tk, Itcl keywords and completions, plus numerous fixes,
 # improvements, support for remote interpreters ...
 # 
 # Three procs from original: [Tcl::DblClick] [listArray] [getVarValue]
 # 
 # This file contains all of the procedures that AlphaTcl might expect to
 # find once a mode has been loaded, i.e. all those that will _not_ be
 # auto-loaded.  Additional support files contain procs that will be
 # sourced on an as-needed basis.
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta
 #         Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 # 
 # Copyright (c) 1997-2006 Vince Darley
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

alpha::mode Tcl 3.1.1 {
    tclMode.tcl
    tclMenu
} [list *.tcl *.itcl *.itk *.decls *.msg \
  *.tbc tclIndex* "\\* Trace '*' \\*" *.bench *.test] {
    tclMenu
} {
    addMenu tclMenu "¥269" "Tcl" "Tcl menu\r\rfor dealing with Tcl, Tk"
    array set unixMode {
        wish Tcl
        tclsh Tcl
        itclsh Tcl
        itkwish Tcl
        prowish Tcl
        protclsh Tcl
        tclkit Tcl
        tclkitsh Tcl
    }
    
    menu::buildProc tclMenu Tcl::buildMenu
    # Colorizing routines.
    lappend tclCmdColourings Tcl::colorTclKeywords Tcl::colorTkKeywords \
      Tcl::colorTclXKeywords Tcl::colorItclKeywords Tcl::colorPseudoTclKeywords
    lappend tclExtraColourings Tcl::colorSymbols Tcl::colorVariables
    menu::insert Utils items "wordCount" "/Y<E<OtclShell"
} maintainer {
    "Vince Darley" <vince@santafe.edu> <http://www.santafe.edu/~vince/>
} uninstall {
    this-dir
} description {
    Supports the editing and running of Tcl and Tk programming files
} help {
    file "Tcl-Tk Help"
}

::xserv::declareBundle tclShell "Tcl Shell" \
  tclInterpreterStart tclEvaluate listTclInterpreters

::xserv::declare tclInterpreterStart "Start an interpreter"
::xserv::declare tclEvaluate "Evaluate a script" interp script
::xserv::declare listTclInterpreters "List Tcl interpreters" {excluding ""}

::xserv::declareBundle tclKit "Tcl Kit Interpreter Executable" \
  tclKitEvaluate tclKitGetApplication

::xserv::declare tclKitEvaluate "Evaluate with Tcl Kit" script
::xserv::declare tclKitGetApplication "Return path to TclKit Application"

::xserv::register tclKitEvaluate "TclKit-shell" -driver {
    return $params(script)
} -mode Exec -progs {tclkit}

::xserv::register tclKitGetApplication "TclKit-shell" -driver {
    return $params(xserv-tclkit)
} -mode Alpha

::xserv::register tclInterpreterStart "Tcl Shell" \
  -sig [expr {$alpha::macos == 2 ? "WiSH" : "WIsH"}] \
  -driver {
    sendOpenEvent noReply $params(xservTarget) ""
    return $params(xservTarget)
}

::xserv::register tclEvaluate "Tcl Shell" \
  -sig [expr {$alpha::macos == 2 ? "WiSH" : "WIsH"}] \
  -driver {
    if {[catch {tclAE::build::resultData -t 30000 $params(xservTarget) \
      misc dosc ---- [tclAE::build::TEXT $params(script)]} res]} {
	if {$res eq "Process \"$params(xservTarget)\" not found"} {
	    # probably still launching
	    after 1000
	    return [tclAE::build::resultData -t 30000 $params(xservTarget) \
	      misc dosc ---- [tclAE::build::TEXT $params(script)]]
	}
	return -code error $res
    }
    return $res
}

::xserv::register listTclInterpreters "Tcl Shell" \
  -sig [expr {$alpha::macos == 2 ? "WiSH" : "WIsH"}] -driver {
    # Needs some AE cleverness to get running interps
    return ""
} -mode Alpha

::xserv::register listTclInterpreters "Tcl Shell (with 'send')" -driver {
    set res {}
    foreach i [winfo interps] {
	if {[lsearch -exact $params(excluding) $i] == -1} {
	    lappend res $i
	}
    }
    return $res
} -mode Alpha -requirements {
    if {$::alpha::platform ne "tk" || $::tcl_platform(platform) eq "windows"} {
	error "unsupported"
    }
}

::xserv::register listTclInterpreters "Tcl Shell (use dde)" -driver {
    set res {}
    foreach service [dde services TclEval ""] {
	if {[lsearch -exact $params(excluding) [lindex $service 1]] == -1} {
	    lappend res [lindex $service 1]
	}
    }
    return $res
} -mode Alpha -requirements {
    if {$::tcl_platform(platform) ne "windows"} {
	error "unsupported"
    }
}

::xserv::register tclInterpreterStart "Tcl Shell (with 'send')" -driver {
    return [tcltk::ensureNewInterp [list exec $params(xserv-tclsh) &]]
} -mode Alpha -progs tclsh -requirements {
    if {[info commands ::send] eq ""} {
	error "unsupported"
    }
}

::xserv::register tclInterpreterStart "Tcl Shell (use dde)" -driver {
    global HOME
    set wrs [file join $HOME Tools winRemoteShell.tcl]
    if {[lindex [file system $wrs] 0] != "native"} {
	set nwrs [temp::path tcltk winRemoteShell.tcl]
	# May need to overwrite if it is already there.  This
	# is probably better than using 'temp::unique' which 
	# will end up creating dozens of copies with repeated use.
	file copy -force -- $wrs $nwrs
	set wrs $nwrs
    }
    return [tcltk::ensureNewInterp [list exec $params(xserv-tclsh) $wrs &]]
} -mode Alpha -progs tclsh -requirements {
    if {$::tcl_platform(platform) ne "windows"} {
	error "unsupported"
    }
}

::xserv::register tclEvaluate "Tcl Shell (use dde)" -driver {
    set withResult [expr {[string trim $params(script)] ne "exit"}]
    if {$withResult} {
	dde execute TclEval $params(interp) [list catch $params(script) alpha_result]
	return [dde request TclEval $params(interp) alpha_result]
    } else {
	catch {dde execute -async TclEval $params(interp) $params(script)}
	return ""
    }
} -dde TclEval -mode Dde

::xserv::register tclEvaluate "Tcl Shell (with 'send')" -driver {
    send $params(interp) $params(script)
} -mode Alpha -requirements {
    if {[info commands ::send] eq ""} {
	error "unsupported"
    }
}

proc tclMode.tcl {} {}

proc tclMenu {} {
    
    # Build the menu.
    tclMenu.tcl
    menu::buildSome tclMenu
    # Register open window hooks.
    Tcl::registerOWH

    ;proc tclMenu {} {}
}

# Tcl projects

ensureset Tclprojects(AlphaTcl) [list mainFile "" shell "" fileset AlphaTcl]
ensureset "Tclprojects(Current Window)" [list mainFile "" shell "" fileset ""]

newPref var project "Current Window"    Tcl \
  [list menu::buildSome tclMenu] Tclprojects array

# This is best set via the Tcl menu.
prefs::deregister "project" "Tcl"

namespace eval Tcl {
    
    # Tcl mode initialisations:
    
    variable inTracing                  0
    variable traceProc                  ""
    variable traceInfo                  0
    
    variable escapeChar                 "\\"
    variable quotedstringChar           "\""
    variable lineContinuationChar       "\\"
    
    variable startPara                  {^(.*\{)?[ \t]*(#|$)}
    variable endPara                    {^(.*\})?[ \t]*(#|$)}
    variable commentRegexp              {^[ \t]*#}
    
    variable commentCharacters
    
    set commentCharacters(General)      "\#"
    set commentCharacters(Paragraph)    [list "## " " ##" " # "]
    set commentCharacters(Box)          [list "#" 1 "#" 1 "#" 3]
    
    variable prefsInMenu [list \
      autoMark structuralMarks structuralElectricElseBrace "(-)" \
      electricDblLeftParen electricTripleColon "(-) " \
      recogniseItcl recognisePseudoTcl recogniseTk]
    
    variable searchPats
    
    # Basic search pattern.
    set searchPats(1) \
      {(itcl(::|_))?(class|namespace[\t ]+eval|proc|method|(config)?body)}
    # Structual marks pattern.
    set searchPats(2) "($searchPats(1))|(\# ××××)"
    # Parsing function info pattern
    set searchPats(3) {(\{[^\}]+\}|\"[^\"]+\"|[^\s]+)}
    # Parse funcs pattern.
    set searchPats(4) {(itcl(::|_))?(class|body|proc|method|(config)?body)}
    
    # The value of the current interpreter command.  This will change
    # automatically as the project changes -- the current project and
    # interpreter are checked whenever a new Tcl window is activated.  We
    # cannot set it yet, since we are just loading the mode.  It will be
    # set when the first Tcl window is activated.  To ensure that nothing
    # fails if an item below is called _without_ a Tcl window having been
    # activated (as when the Tcl menu is globally activated) we make sure
    # that this is initially set to the internal interpreter.
    variable interpCmd "tcltk::internalEvaluate"
}

# ===========================================================================
#
# ×××× -------- ×××× #
# 
# ×××× Tcl mode prefs ×××× #
# 
# Set up package-specific mode variables
# 

# Removing obsolete preferences from earlier versions.
prefs::removeObsolete TclmodeVars(alphaKeyWordColor) TclmodeVars(keywordColor) \
  TclmodeVars(tclHelp) TclmodeVars(tclHelpLocation) TclmodeVars(allProcCompletions)

prefs::renameOld TclmodeVars(magicColor) TclmodeVars(variablesColor)

# Standard prefs used by various procedures in AlphaTcl.

# Turn this item on to automatically mark Tcl files when first opened if
# there are no marks currently saved||Turn this item off to never
# automatically mark Tcl files when they are first opened
newPref flag autoMark   0 Tcl {Tcl::updatePreferences}
newPref var  lineWrap   0 Tcl
# To automatically perform context relevant formatting after typing a left
# or right curly brace, turn this item on||To have the brace keys produce a
# brace without additional formatting, turn this item off
newPref flag electricBraces    1 Tcl
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn    1 Tcl
# To use the "Tcl 8.4 Commands" file for help on Tcl commands (instead of
# opening a .html version of the help file) turn this item on||To always open
# .html help files for Tcl commands, turn this item off
newPref flag useTextFileForTclCommandHelp 0 Tcl

newPref var prefixString {# } Tcl
newPref var wordBreak {(\$)?[\w:_]+} Tcl

# Flag Preferences

# To mark files structurally, recognising the special comments entered by
# 'ctrl-3', turn this item on||To mark files alphabetically, placing
# unindexed ('hidden') procs at the end of the list, turn this item off
newPref flag structuralMarks 0 Tcl {Tcl::updatePreferences}
# To insert a full set of braces with 'else/elseif' electric brace
# completions, turn this item on||To only include initial brace with
# 'else/elseif' electric braces completions, turn this item off
newPref flag structuralElectricElseBrace 0 Tcl {Tcl::updatePreferences}

# Variable Preferences

# How to handle comments continuation
newPref var commentsContinuation 2 Tcl {} \
  [list "only at line start" "spaces allowed" "anywhere"] index
# Indentation scheme for lines following one ending in a backslash
newPref var indentSlashEndLines 1 Tcl "" indent::amounts varindex
# When tracing in external interpreters, we don't necessarily
newPref var maximumNumberOfExternalCommandsToTrace 100 Tcl
# Directories in which to search for tclIndex files pointing to procedures
# for quick access to those procedures (e.g. by cmd-double-clicking).
newPref var procSearchPath "" Tcl

# Contextual menus.

# Includes utilities to obtain information about the current procedure or 
# the proc beneath the cursor, or to reload or reformat the surrounding text
newPref flag tclProcsMenu  "1"  contextualMenuTcl
# Allows you to obtain information about variables currently defined in the
# interpreter.
newPref flag tclVarsMenu   "1"  contextualMenuTcl
# Includes items to evaluate the active window, change the coloring scheme,
# and rebuild indices
newPref flag tclWindowMenu "1"  contextualMenuTcl

menu::buildProc "tclProcs"      Tcl::buildTclProcsCMenu
menu::buildProc "tclVars"       Tcl::buildTclVarsCMenu
menu::buildProc "tclWindow"     Tcl::buildTclWindowCMenu

# Tcl Help preferences

## 
 # --------------------------------------------------------------------------
 # 
 # "Tcl::findDocumentationFolder" --
 # 
 # Try to determine the location of the local help dir.
 # 
 # --------------------------------------------------------------------------
 ##

proc Tcl::findDocumentationFolder {} {
    
    global tcl_platform
    
    if {[catch {file link [info library]} libraryDir]} {
	set libraryDir [info library]
    }
    set libraryDir [file dir $libraryDir]
    switch -- $tcl_platform(platform) {
        "macintosh" {
	    set tclHelpFolder [lindex [glob -nocomplain -dir \
	      [file dir $libraryDir] "*HTML Manual"] 0]
        }
        "unix" {
	    set tclHelpFolder [file join $libraryDir "Documentation" \
	      "Reference" "Tcl"]
        }
	"windows" {
	    # I'm not sure if this will works or not. (-- cbu)
	    set tclHelpFolder [file join $libraryDir "Documentation" \
	      "Reference" "Tcl"]
	}
    }
    if {![file isdir $tclHelpFolder]} {
        set tclHelpFolder ""
    }
    return $tclHelpFolder
}

# This is the home page url for the "Tcl Help --> Tcl Home Page" menu item.
newPref url tclHomePage {http://www.tcl.tk/} Tcl
# Command-Double-Clicking on a Tcl/Tk command will provide web-based
# documentation from this local help directory.
newPref folder tcl/TkHelpLocalFolder [Tcl::findDocumentationFolder] Tcl
# Command-Double-Clicking on a Tcl/Tk command will provide web-based
# documentation from this location if the 'Tcl Help Local Folder' doesn't
# exist.
newPref url tcl/TkHelpUrlDir {http://www.tcl.tk/man/tcl8.4/} Tcl
# Command-Double-Clicking on a TclX command will provide web-based
# documentation from this location.
newPref url tclxHelpUrl {http://www.tcl.tk/man/tclx8.2/TclX.n.html} Tcl

# Tcl mode colors

# Colour [incr Tcl] commands
newPref flag recogniseItcl      {1}     Tcl     {Tcl::updatePreferences}
# Recognise and colour some common procedures 'lunion' etc.
newPref flag recognisePseudoTcl {1}     Tcl     {Tcl::updatePreferences}
# Colour TclX commands
newPref flag recogniseTclX      {0}     Tcl     {Tcl::updatePreferences}
# Colour Tk commands
newPref flag recogniseTk        {1}     Tcl     {Tcl::updatePreferences}

# Colour of all chosen commands.
newPref color commandColor      {blue}  Tcl     {Tcl::colorizeTcl}
# Color for Tcl comments
newPref color commentColor      {red}   Tcl     {stringColorProc}
# In Tcl, the colour of words started by '$'.  Tcl considers such words to be
# variables.  A dark brown might be a good choice, distinguishable, but not
# too distracting.  To try that, chose 'Config:Redefine Colors:Color_9' and
# set it to brown (the 'raw sienna' crayon is a good choice).  Then, when you
# are done, come back to this dialog.  Color_9 will now be available as a
# choice.
newPref color variablesColor    {none}  Tcl     {Tcl::colorizeTcl}
# Colour for strings
newPref color stringColor       {green} Tcl     {stringColorProc}
# Colour of symbols such as \, -, +, *, etc.  Can be useful for
# reading regular expressions.
newPref color symbolColor       {none}  Tcl     {Tcl::colorizeTcl}

# This is a "dummy" command, which must be called before [Tcl::colorizeTcl]
# so that all of the "regModeKeywords" commands in the called color procs can
# be "adds" (-a).  This is executed when the mode is first invoked, before
# the color procs are called.  This command also turns on case sensitive
# coloring of keywords.
regModeKeywords -C Tcl {}

# Now we colorize.
Tcl::colorizeTcl

proc Tcl::updatePreferences {args} {
    
    global mode
    
    foreach pref $args {
	switch -- $pref {
	    "recogniseItcl"      {Tcl::colorItclKeywords $pref}
	    "recognisePseudoTcl" {Tcl::colorPseudoTclKeywords $pref}
	    "recogniseTclX"      {
		Tcl::colorizeTcl $pref
		Tcl::Completion::buildTclXElectrics
	    }
	    "structuralMarks"    {if {$mode == "Tcl"} {markFile}}
	    default              {Tcl::colorizeTcl $pref}
	}
    }
    Tcl::postBuildOptions
}

# ===========================================================================
#
# Create categories of Tcl preferences, used by [prefs::dialogs::modePrefs].
# When the dialogues are actually built, there will most likely be added a
# Miscellaneous pane.  This happens whenever there are prefs which are not
# categorized.  (There's no need to set a "Miscellaneous" group entry,
# because this will always be built from scratch.)
# 

# Editing
prefs::dialogs::setPaneLists "Tcl" "Editing" [list \
  "autoMark" \
  "fillColumn" \
  "electricBraces" \
  "indentOnReturn" \
  "indentSlashEndLines" \
  "lineWrap" \
  "structuralElectricElseBrace" \
  "structuralMarks" \
  "wordBreak" \
  ]

# Comments
prefs::dialogs::setPaneLists "Tcl" "Comments" [list \
  "commentsContinuation" \
  "prefixString" \
  "commentColor" \
  ]

# Colors
prefs::dialogs::setPaneLists "Tcl" "Colors" [list \
  "recogniseItcl" \
  "recognisePseudoTcl" \
  "recogniseTclX" \
  "recogniseTk" \
  "recognizeObsoleteProcs" \
  "alphaColor" \
  "commandColor" \
  "stringColor" \
  "symbolColor" \
  "variablesColor" \
  ]

# Help
prefs::dialogs::setPaneLists "Tcl" "Tck/Tk Help" [list \
  "tcl/TkHelpLocalFolder" \
  "tcl/TkHelpUrlDir" \
  "tclHomePage" \
  "tclxHelpUrl" \
  "useTextFileForTclCommandHelp" \
  ]

# Tcl Procedures
prefs::dialogs::setPaneLists "Tcl" "Tcl Procedures" [list \
  "maximumNumberOfExternalCommandsToTrace" \
  "procSearchPath" \
  ]

# ===========================================================================
#
# ×××× Tcl mode bindings ×××× #
# 

# Some handy bindings for navigating procs in a file.  (cbu)
# (control-shift arrow keys, right and left also call 'insertToTop')

Bind  down <sz> {function::next 0 0}    Tcl
Bind right <sz> {function::next 0 1}    Tcl
Bind    up <sz> {function::prev 0 0}    Tcl
Bind  left <sz> {function::prev 0 1}    Tcl

# Tracing window navigation. (trf)
Bind Kpad2      {Tcl::keypad2}          Tcl
Bind Kpad5      {Tcl::keypad5}          Tcl

Bind Clear      {Tcl::keypadClear}      Tcl

##
 # -------------------------------------------------------------------------
 # 
 # "Tcl::traceWinActive"  --
 # 
 # Determines if we have a tracing window.  If so, we generally divert to
 # some procedure found in "tclTracing.tcl"
 # 
 # -------------------------------------------------------------------------
 ##

proc Tcl::traceWinActive {args} {
    win::parseArgs w
    regexp {^\* Trace} $w
}

# ===========================================================================
#
# ×××× Tcl mode electrics ×××× #
# 

proc Tcl::electricLeft {} {
    
    global TclmodeVars
    
    if {[literalChar]} {insertText "\{"; return}
    set pat "\}\[ \t\r\n\]*(else(if)?)\[ \t\r\n\]*\$"
    set p [getPos]
    if {[set res [findPatJustBefore "\}" "$pat" $p word]] == ""} {
	insertText "\{"
	return
    }
    # We have an if/else(if)/else
    
    # The behaviour here is optional, because some people may not like this
    # more structured entry.
    if {$TclmodeVars(structuralElectricElseBrace)} {
	switch -- $word {
	    "else" {
		deleteText [lindex $res 0] $p
		elec::Insertion "\} $word \{\r\t¥¥\r\}¥¥"
	    }
	    "elseif" {
		deleteText [lindex $res 0] $p
		elec::Insertion "\} $word \{¥¥\} \{\r\t¥¥\r\}¥¥"
	    }
	}
    } else {
	switch -- $word {
	    "else" {
		replaceText [lindex $res 0] $p "\} $word \{\r"
		bind::IndentLine
	    }
	    "elseif" {
		replaceText [lindex $res 0] $p "\} $word \{"
	    }
	}
    }
}

proc Tcl::electricRight {} {
    
    if {[literalChar]} {insertText "\}"; return}
    set p [getPos]
    if {[regexp "\[^ \t\]" [getText [lineStart $p] $p]]} {
	insertText "\}"
	if {[catch {blink [matchIt "\}" [pos::math $p - 1]]} err]} {
	    status::msg $err
	}
	return
    }
    set start [lineStart $p]
    insertText "\}"
    createTMark tcl_er [getPos]
    backwardChar
    bind::IndentLine
    gotoTMark tcl_er ; removeTMark tcl_er
    bind::CarriageReturn
    if {[catch {blink [matchIt "\}" [pos::math $start - 1]]} err]} {
	status::msg $err
    }
}

##
 # --------------------------------------------------------------------------
 # 
 # "Tcl::correctIndentation" --
 # 
 # Returns the correct indentation for the line containing $pos, if that line
 # were to contain ordinary characters only.  It is the responsibility of the
 # calling procedure to ensure that if we are to insert/have a line already,
 # that that information is taken into account, by passing in the argument
 # 'next'
 # --------------------------------------------------------------------------
 ##

proc Tcl::correctIndentation {args} {
    
    win::parseArgs w pos {next ""}
    
    # Preliminaries
    set pos0 [pos::lineStart -w $w $pos]
    set posM [pos::min -w $w]
    if {[pos::compare -w $w $pos0 == $posM]} {return 0}
    # If the current line is a comment, we have to check some special cases
    if {[string index $next 0] == "#"} {
	set p [pos::prevLineStart -w $w $pos0]
	set pat {^[ \t]*[^ \t\r\n]}
	set pos [pos::prevChar -w $w $pos0]
	set pp  [search -w $w -n -s -f 0 -r 1 -i 0 -m 0 -- $pat $pos]
	if {![llength $pp]} {
	    # Check for search bug at beginning of file.
	    if {[pos::compare -w $w $p != $posM]} {return 0}
	    if {[getText -w $w $posM [pos::math -w $w $posM + 2]] == "##"} {
		if {([string range $next 0 1] != "##")} {
		    return 1
		} else {
		    return 0
		}
	    }
	}
	set prev [pos::prevChar -w $w [lindex $pp 1]]
	set p [lindex $pp 0]
	if {[lookAt -w $w $prev] != "#" || ($pos0 == $posM)} {
	    # Not a comment, so indent with code
	} else {
	    set lwhite [lindex [pos::toRowCol -w $w $prev] 1]
	    # It's a comment
	    set pos1 [pos::math -w $w $prev + 2]
	    set pos2 [pos::math -w $w $prev + 2]
	    if {[getText -w $w $prev $pos1] == "##" && \
	      [lookAt -w $w $pos2] != "#" && \
	      ([string range $next 0 1] != "##")} {
		# It's a comment paragraph
		incr lwhite
	    }
	}
    }
    set next [string index $next 0]
    if {![info exists lwhite]} {
	set pat {^[ \t]*[^\# \t\r\n]}
	set pos [pos::prevChar -w $w $pos0]
	if {![catch {search -w $w -s -f 0 -r 1 -i 0 -m 0 $pat $pos} lst]} {
	    # Find the last non-comment line and get its leading whitespace
	    # What are all these cryptic variable names?!
	    set trc [pos::toRowCol -w $w [pos::prevChar -w $w [lindex $lst 1]]]
	    set lwhite [lindex $trc 1]
	    set pe1 [lookAt -w $w [pos::math -w $w $pos0 - 2]]
	    set lst [lindex $lst 0]
	    set pat {[^ \t\r\n]}
	    set pos [pos::lineEnd -w $w $lst]
	    set pp1 [search -w $w -s -f 0 -r 1 -i 0 -m 0 $pat $pos]
	    set lastC [lookAt -w $w [lindex $pp1 0]]
	    set indent [text::getIndentationAmount -w $w]
	    # Round odd half-indents upwards, and make sure we use the
	    # same offset for +ve and -ve (avoiding related rounding
	    # issues -- i.e. that int(3/2) + int (-3/2) != 0).

	    set indentSlashEndLines [win::getModeVar $w indentSlashEndLines 0]
	    set slashInd [expr {(1 + $indent * $indentSlashEndLines)/2}]
	    if {$next == "\}"} {
		incr lwhite -$indent
		set pos2 [pos::prevLineStart -w $w $pos0]
		set pe2  [lookAt -w $w [pos::math -w $w $pos2 - 2]]
		if {$pe1 == "\\"} {
		    incr lwhite $slashInd
		} elseif {$pe2 == "\\"} {
		    incr lwhite -$slashInd
		}
		if {$lastC == "\{"} {
		    incr lwhite $indent
		}
	    } else {
		if {$pe1 == "\\"} {
		    set pos1 [pos::prevLineStart -w $w $pos0]
		    if {[lookAt -w $w [pos::math -w $w $pos1 - 2]] != "\\"} {
			incr lwhite $slashInd
		    }
		} else {
		    if {$lastC == "\{"} {
			incr lwhite $indent
		    }
		    if {[lookAt -w $w [pos::math -w $w $lst - 2]] == "\\"} {
			incr lwhite -$slashInd
		    }
		}
	    }
	} else {
	    # Basically failed in all the above, so keep current indentation
	    set trc [pos::toRowCol -w $w [text::firstNonWsLinePos -w $w $pos0]]
	    set lwhite [lindex $trc 1]
	}
    }
    return [expr {$lwhite > 0 ? $lwhite : 0}]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "Tcl::foldableRegion" --
 # 
 # Return beginning and end of block to fold.  Currently limited to actual
 # procs, though it could easily be expanded to namespaces, etc.
 # 
 # -------------------------------------------------------------------------
 ##

proc Tcl::foldableRegion {args} {
    win::parseArgs w {pos ""}

    if {![string length $pos]} {
	set pos [getPos -w $w]
    }
    return [lrange [Tcl::parseFunctionInfo $pos "proc" 1] 7 end]
}

# ===========================================================================
#
# ×××× Tcl proc navigation ×××× #
# 

## 
 # -------------------------------------------------------------------------
 # 
 # "Tcl::getLimits" --
 # 
 # This is used by the "function::" procs, which are in turn called by
 # various items to get function limits for navigating, selecting, etc.
 # 
 # We allow searching for commented functions, unless that seems to throw
 # an error, in which case we try again without comments.
 # 
 # -------------------------------------------------------------------------
 ##

proc Tcl::getLimits {args} {
    
    variable searchPats

    win::parseArgs w pos direction {pat ""} {commentsOK 1}
    if {![string length $pat]} {set pat  $searchPats(1)}

    set pos0 $pos
    set pos1 [set pos2 ""]

    if {$direction} {
	# Going forward, so make sure that we don't capture the current proc.
	if {![catch {Tcl::parseFunctionInfo -w $w $pos $pat 0 $commentsOK} pp0]} {
	    set pos0 [pos::nextLineStart -w $w [lindex $pp0 1]]
	} 
    }
    # Search for the leading pattern for a proc.
    set pp1 [Tcl::findFunctionStart -w $w $pos0 $pat $direction $commentsOK]
    if {[string length [set pos0 [lindex $pp1 1]]]} {
	# Found one, so try to find the limits.
	if {![catch {Tcl::parseFunctionInfo -w $w $pos0 $pat 0 1} pp2]} {
	    set pos1 [pos::lineStart -w $w [lindex $pp2 0]]
	    set pos2 [pos::nextLineStart -w $w [lindex $pp2 1]]
	}
    }
    if {[string length $pos1] || !$commentsOK} {
	return [list $pos1 $pos2 "proc or namespace"]
    } else {
        # Try searching without using comments, limited to procs.
	return [Tcl::getLimits -w $w $pos $direction "proc" 0]
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "Tcl::searchFunc" --
 # 
 # Called by numeric keypad navigation (1) and (3).
 # 
 # "Tcl::keypad2" --
 # "Tcl::keypad5" --
 # 
 # If we're in a tracing window, we do special things (see the called procs
 # that are defined in "tclTracing.tcl"), otherwise use default routines.
 # 
 # -------------------------------------------------------------------------
 ##

proc Tcl::searchFunc {dir} {
    
    if {[Tcl::traceWinActive]} {
	Tcl::traceSearch $dir
    } elseif {$dir} {
	function::next 0 2
    } else {
	function::prev 0 2
    }
}

proc Tcl::keypad2 {} {
    
    if {[Tcl::traceWinActive]} {
	Tcl::forwardToTclReturn
    } else {
	hiliteToPin
    }
}

proc Tcl::keypad5 {} {

    if {[Tcl::traceWinActive]} {
	Tcl::backToTclCall
    } else {
	exchangePointAndPin
    }
}

##
 # --------------------------------------------------------------------------
 # 
 # "Tcl::keypadClear" --
 # 
 # (Formerly [Tcl::1XTop2XShowComment].)  Bound to 'Clear' on the numeric
 # keypad, the first call will do a normal [insertToTop].  If we are within
 # a procedure, however, and there is a block of comments preceding the
 # procedure's definition, the user is notified that a second call will
 # make those comments visible in the window.  The current position is
 # remembered, specific to the current window.
 # 
 # This second call does _not_ change the cursor position -- subsequent
 # calls will move the insertion point to the top of the window once again.
 # 
 # --------------------------------------------------------------------------
 ##

proc Tcl::keypadClear {} {
    
    set w [win::Current]
    variable keypadClearPos
    ensureset keypadClearPos($w) [minPos]
    set pos0 [set keypadClearPos($w)]
    set pos1 [getPos]
    
    # Are we currently within a procedure?
    if {[catch {Tcl::parseFunctionInfo $pos1 "proc" 0} pp1]} {
	set keypadClearPos($w) [minPos]
	insertToTop
	return
    }
    # Do we have some comments preceding this proc?
    set pos2 [lindex $pp1 0] ; set pos2a [pos::prevLineEnd $pos2]
    set pat {^[^#\r\n]*[\r\n]+[\t ]*#}
    if {![llength [set pp2 [search -n -s -f 0 -r 1 -- $pat $pos2a]]]} {
	# No comment found.
	set hasComment 0
    } else {
	# Comment found.  Is the proc which immediately follows it the same
	# one that we're dealing with?
	set pos3 [pos::lineStart [lindex $pp2 1]]
	set pos4 [lindex [function::getLimits $pos3 1] 0]
	if {![string length $pos4]} {
	    set hasComment 0
	} else {
	    set hasComment [pos::compare $pos2 == $pos4]
	}
    }
    if {!$hasComment} {
	# No comment found.
	set keypadClearPos($w) [minPos]
	insertToTop
    } elseif {[pos::compare $pos0 != $pos1]} {
	set keypadClearPos($w) $pos1
	insertToTop
	status::msg "Comments are above, press 'Clear' again to see them."
    } else {
	# We have been called once, and the insertion point has already been
	# moved to the top of the window, so the second call will display the
	# comments for this proc, and then reset.
	set keypadClearPos($w) [minPos]
	display $pos3
	set procName [Tcl::enclosingProcName $pos0]
	status::msg "These are the comments preceding '$procName'"
    }
}

# ===========================================================================
#
# ×××× Tcl file marking ×××× #
# 

## 
 # -------------------------------------------------------------------------
 # 
 # "Tcl::MarkFile" --
 # 
 # Called by the "M" button.
 # 
 # Recursively search the current window, looking for 'class' 'proc' etc
 # patterns indicating the start of some basic Tcl function.  Namespace
 # declarations (i.e. [namespace eval <ns> {...}]) are used to truncate
 # mark names.  If the "structuralMarks" preference is set, then we also
 # recognize dividers created using '××××' strings, as in the
 # divider before this comment for 'Tcl file marking'.
 # 
 # There are a few features to note:
 # 
 #   (1) Procs defined within namespaces will be recognized.
 #   (2) Namespaces defined within procs will not be recognized.
 #   (3) Procs that are not indexed (i.e. preceded by ';') or commented
 #       will be recognized, but indicated as such in the Marks menu.
 #   (4) Namespaces that are commented out or preceded by ";" will not
 #       be recognized.
 # 
 # For (3) the method for indicating 'special' items is dependent on the
 # "structuralMarks" preference.  If turned on, items will have either ";"
 # or "#" preceding the mark name.  Otherwise, these procs are placed in
 # their own separate sections.
 # 
 # Note: I experimented with a version that called [Tcl::findFunctionStart]
 # and [Tcl::parseFunctionStart], but found that file marking took over
 # twice as long -- using [pos::lineEnd] etc also slows things down quite a
 # bit.  Even so, this version takes quite a bit longer in Alpha8 to mark a
 # file than in Tcl mode version 2.x -- here's some tests for this file:
 # 
 # 2.6 :  171140 microseconds per iteration
 # 3.0 :  409618 microseconds per iteration
 # 
 # (Using procs that have ?-w window? and all of the pos:: procs pushed
 # this over 990000 microseconds per iteration.)
 # 
 # I've tried to optimize this as much as possible ...
 # 
 # -------------------------------------------------------------------------
 ##

proc Tcl::MarkFile {args} {
    win::parseArgs win
    
    global TclmodeVars
    
    variable searchPats

    # Preliminaries.
    set count1 [set count2 0]
    set class ""
    set hasMarkers 0
    set marks [list]
    status::msg "Marking Window É"
     # Regexp patterns.
    set pat1 $searchPats(1)
    set pat2 $searchPats(2)
    set pat3 $searchPats(3)
    set patA {^[\t ;\#]*}
    set patB {[\t ]+[^\t ]+[\t ]+}
    if {![set sm $TclmodeVars(structuralMarks)]} {
	set pat "${patA}(${pat1})${patB}"
    } else {
	set pat "${patA}(${pat2})${patB}"
    }
    # Recursively search for the pattern.
    set pos [minPos -w $win]
    while {[llength [set pp0 [search -w $win -n -s -m 0 -r 1 -i 0 -f 1 -- $pat $pos]]]} {
	foreach item [list prefix type name args p] {set $item ""}
	set pos0 [lineStart -w $win [lindex $pp0 0]]
	set pos1 [nextLineStart -w $win $pos0]
	if {$sm && [regexp -- {\# ××××} [set txt0 [getText -w $win $pos0 $pos1]]]} {
	    set type "divider"
	    set pos  $pos1
	} else {
	    set parsed [Tcl::funcParameters -w $win [lindex $pp0 0]]
	    foreach {prefix type name args pp1} $parsed {}
	    set pos [lindex $pp1 end]
	} 
	if {![string length $type]} {
	    continue
	} else {
	    set mark ""
	    switch -regexp -- $prefix {
		"\#"    {set prefix "\#"}
		"\;"    {set prefix "\;"}
		default {set prefix ""}
	    }
	    regsub "^itcl(::|_)" $type "" type
	    switch -glob $type {
		"body" {
		    if {$prefix != "\#"} {
			regexp $pat2 $name mark
		    }
		}
		"*class" { 
		    if {$prefix != "\#"} {
			set mark "[set class $name] 000" 
		    }
		}
		"configbody" - "proc" {
		    if {!$sm} {
		        set mark $name
		    } else {
		        set mark ${prefix}${name}
			if {$hasMarkers && [string length $prefix]} {
			    set hasMarkers 1
			}
		    }
		    if {$type == "proc"} {
			incr count1
		    }
		}
		"divider" {
		    regexp "# ×××× (.*) ××××" $txt0 all mark
		    if {[regexp -- "---*" $mark]} {
			set mark "-"
		    } elseif {[regexp "^(    )|(\t)# ×××× " $txt0]} {
			set mark " ¥$mark"
		    } else {
			set mark "¥$mark"
		    }
		    set hasMarkers 1
		}
		"method" {
		    if {$prefix == "\#"} {
			set mark ${class}::${name}
		    }
		}
		"namespace" {
		    if {[string length $prefix]} {
			continue
		    } elseif {1 && ![catch {Tcl::parseFunctionInfo -w $win $pos0} pp2]} {
			# This helps avoid marking namespaces in procs.
			set pos [nextLineStart -w $win [lindex $pp2 end]]
			continue
		    } else {
			set mark "$name 111"
			incr count2
		    }
		}
		default {set mark $name}
	    }
	}
	if {![string length $mark]} {continue}
	while {[lsearch -exact $marks $mark] != -1} {append mark " "}
	lappend marks $mark
	if {$sm} {
	    lappend asEncountered $mark
	    set arr visible
	} else {
	    switch -- $prefix {
		"\#"    {set arr commented}
		"\;"    {set arr unindexed}
		default {set arr visible}
	    }
	}
	set ${arr}($mark) [lineStart -w $win [pos::math -w $win [lineStart -w $win $pos0] - 1]]
    }
    # Reorder markers as necessary, and create them.
    set class "#"
    set marks [list]
    foreach marksArray {visible unindexed commented} {
	if {![info exists $marksArray]} {continue}
	if {$marksArray == "unindexed"} {
	    # 'Hidden' procs, those preceded by ";", will be separated
	    # from the rest by a divider.
	    set posM [minPos -w $win]
	    foreach item [list "-" "¥Unindexed procs:"] {
		setNamedMark -w $win $item $posM $posM $posM
	    }
	} elseif {$marksArray == "commented"} {
	    set posM [minPos -w $win]
	    foreach item [list "-" "¥Commented procs:"] {
		setNamedMark -w $win $item $posM $posM $posM
	    }
	}
	if {$sm} {
	    set order $asEncountered
	} else {
	    set order [lsort -dictionary [array names $marksArray]]
	}
	foreach mark $order {
	    set pos0 [set ${marksArray}($mark)]
	    set pos1 [nextLineStart -w $win $pos0]
	    if {[string first "000" $mark] != -1} {
		set mark "Class '[set class [lindex $mark 0]]'"
	    } elseif {[string first "111" $mark] != -1} {
		set mark "Namespace '[set class [lindex $mark 0]]'"
	    } else {
		regsub "^(\[\#;\]*)${class}::" $mark "\\1::" mark
	    }
	    if {$hasMarkers && ![regexp {^[\t ]*[\#;¥]} $mark]} {
		set mark " $mark"
	    }
	    if {[string trim $mark] == "-"} {set mark "-"}
	    while {[lsearch $marks $mark] > -1} {append mark " "}
	    lappend marks $mark
	    setNamedMark -w $win $mark $pos0 $pos1 $pos1
	}
    }
    # Report the number of procedures defined in this file.
    set msg "'[win::CurrentTail]' contains "
    if {$count1 == 1} {
	append msg "1 defined proc"
    } else {
	append msg "$count1 defined procs"
    }
    if {!$sm || !$count2} {
	append msg "."
    } elseif {$count2 == 1} {
	append msg ", and 1 declared namespace."
    } else {
	append msg ", and $count2 declared namespaces."
    }
    status::msg $msg
}

##
 # --------------------------------------------------------------------------
 # 
 # "Tcl::parseFuncs" --
 # 
 # Called by the "{}" button.
 # 
 # This proc is called by the "braces" pop-up.  It returns a dynamically
 # created, alphabetical, list of "pseudo-marks".  Each proc will be listed
 # with an iconographic description of its arguments.
 # 
 # Author: Tom Fetherston
 # 
 # --------------------------------------------------------------------------
 ##

proc Tcl::parseFuncs {} {
    
    variable searchPats

    # Preliminaries.
    set patA {^[\t ;]*}
    set patB {[\t ]+[^\t ]+[\t ]+}
    set pat  "${patA}($searchPats(4))${patB}"
    set pos  [minPos]
    # Recursively search for the pattern.
    while {[llength [set pp0 [search -n -s -m 0 -r 1 -i 0 -f 1 -- $pat $pos]]]} {
	set parsed [Tcl::funcParameters [lindex $pp0 0]]
	foreach {prefix type name args pp1} $parsed {}
	set pos0 [lindex $pp0 0]
	set pos  [lindex $pp1 end]
	if {![string length $type]} {continue}
	set func $name
	regsub "^itcl(::|_)" $type "" type
	if {$type == "proc"} {
	    if {[llength $args]} {
		set argLabel ""
		foreach arg $args {
		    if {[llength $arg] == 2} {
			append argLabel "À"
		    } elseif {[set arg] != "args"} {
			append argLabel "¥"
		    } else {
			append argLabel "É"
		    }
		}
		append func " {${argLabel}}"
	    }
	}
	# Remember where this function starts.
	lappend positions($func) $pos0
	# Associate name and tag.
	set tag($pos0) $func
    }
    if {![array exists positions]} {return}
    set funcs [list]
    foreach name [lsort -dictionary [array names positions]] {
	if {[set count [llength $positions($name)]] == 1} {
	    set pos1 [lindex $positions($name) 0]
	    lappend funcs $tag($pos1) $pos1
	} else {
	    for {set i 1} {$i <= $count} {incr i} {
		set pos1 [lindex $positions($name) [expr {$i - 1}]]
		lappend funcs "$tag($pos1) \($i of $count\)" $pos1
	    }
	}
    }
    return $funcs
}

proc Tcl::funcParameters {args} {
    win::parseArgs win pos
    
    global alpha::platform
    
    variable searchPats

    set pos0 [lineStart -w $win $pos]
    set pos1 [pos::math -w $win [nextLineStart -w $win $pos0] - 1]
    while {[lookAt -w $win $pos1] == "\\"} {
	set pos1 [pos::math -w $win [nextLineStart -w $win [nextLineStart -w $win $pos1] - 1]]
	if {[pos::compare -w $win $pos1 == [maxPos -w $win]]} {break}
    }
    set pos1 [nextLineStart -w $win $pos1]
    set txt1 [getText -w $win $pos0 $pos1]
    set patA {^([\t \;\#]*)[\t ]*([a-z]+)[\t ]+}
    set patB {[\t ]+([^\t ]+)}
    set pat1 "${patA}${searchPats(3)}${patB}"
    foreach item [list 1 2 3 4] {set idxs${item} [list 0 0]}
    foreach item [list prefix type name] {set $item ""}
    regexp -indices -- $pat1 $txt1 idxs0 idxs1 idxs2 idxs3 idxs4
    set parsed [regexp -inline  -- $pat1 $txt1]
    regsub -all "\s" [lindex $parsed 1] "" prefix
    set type [lindex $parsed 2]
    set name [lindex $parsed 3]
    if {[is::List $name]} {
	# Create pure-list
	set name [lrange $name 0 end]
    }
    set pos2 [pos::math -w $win $pos0 + [lindex $idxs4 0]]
    if {[lookAt -w $win $pos2] == "\{"} {
	if {![catch {matchIt -w $win "\{" [pos::math -w $win $pos2 + 1]} pos3]} {
	    set pos3 [pos::math -w $win $pos3 + 1]
	} else {
	    set pos3 $pos2
	}
    } else {
	set pp [search -w $win -n -s -f 1 -r 1 -l $pos1 -- {\s} $pos2]
	if {[llength $pp]} {
	    set pos3 [lindex $pp 1]
	} else {
	    set pos3 $pos2
	}
    }
    set args [getText -w $win $pos2 $pos3]
    if {$alpha::platform == "alpha"} {
	regsub -all "\r" $args "\n" args
    }
    set args [string map [list "\\\n" " "] $args]
    if {![is::List $args]} {
	# This is a problem we should report and fix?
	#alertnote "Bug in Tcl::funcParameters with '$args'"
    }
    if {[llength $args] == 1} {
	set args [lindex $args 0]
	if {[is::List $args]} {
	    set args [lrange $args 0 end]
	}
    }
    if {$type == "namespace"} {
	set name $args
	set args ""
    } 
    return [list $prefix $type $name $args [list $pos0 $pos1]]
}

# ===========================================================================
#
# ×××× -------- ×××× #
# 
# ×××× Info providers ×××× #
# 

proc Tcl::DblClick {from to shift option control} {
    
    variable tcltkKeywords
    
    # If <cmd> and <control> were pressed, we look to select part of a
    # combination word (less any leading dollar sign) -trf
    if {$control} {
	set pos [getPos]
	if {[lookAt $from] == "\$"} {
	    set from [pos::math $from + 1]
	}
	set pos0 $pos
	set selStartNotDetermined 1
	while {$selStartNotDetermined && ([pos::compare $pos0 > $from])} {
	    if {[set char [lookAt $pos0]] == "_"} {
		set pos0 [pos::nextChar $pos0]
		set selStartNotDetermined 0
	    } elseif {[regexp {[A-Z]} $char]} {
		set selStartNotDetermined 0
	    } else {
		set pos0 [pos::prevChar $pos0]
	    }
	}
	set pos1 $pos
	set selEndNotDetermined 1
	while {$selEndNotDetermined && ([pos::compare $pos1 <= $to])} {
	    set char [lookAt $pos1]
	    if {[regexp "\[A-Z_ \t\r\]" $char]} {
		set selEndNotDetermined 0
	    } else {
		set pos1 [pos::nextChar $pos1]
	    }
	}
	selectText $pos0 $pos1
	return
    } elseif {$shift} {
	# Attempt to put the 'args' of the proc in the status window.
	set word [getText $from $to]
	set msg "Couldn't find the arguments for '$word'"
	if {[string first "$" $word] == -1} {
	    if {[string first ":" $word] != 0} {
		if {[string length [set ns [Tcl::contextNamespace $from]]]} {
		    lappend queryWords ${ns}::${word}
		} 
	    } 
	    lappend queryWords $word
	    foreach p $queryWords {
		if {[catch {Tcl::getProcArgs $p} arguments]} {
		    continue
		} elseif {![llength $arguments]} {
		    set msg "'$p' doesn't take any arguments."
		} else {
		    set msg "'$p' arguments: $arguments"
		}
	    }
	} 
	status::msg $msg
	return
    }
    
    # Otherwise, we try to impart some extra info
    selectText $from $to
    # This might have been called from within a Trace window, in which case
    # we want to move this window to the right and push its mark.
    set pat {^\* (Tcl error|Trace|Stack|Error Info|ERROR \*)}
    if {[regexp $pat [win::CurrentTail]]} {
	lappend selectionEndPoints [getPos] [selEnd]
	if {[Tcl::findErrorInfoLocation [getPos]]} {
	    return
	}
    }
    
    # If this was called using the shortcut key, the selection may include
    # more than just the proc name, so we dust off the selection first.
    set gotName [getSelect]
    set gotName [string trimright $gotName "'"]
    if {![regexp -- "^proc\[ \t\]+(\[^ \t\]+)" $gotName -> gotName]} {
	set gotName [string trim $gotName]
    }
    set nsList [list]
    # If 'gotName' isn't in the global namespace ...
    if {![regexp "^\\$?::" $gotName]} {
	if {[string length [set ns [Tcl::contextNamespace $from]]]} {
	    # Add this one first, so that we'll check the current
	    # namespace before the global one.
	    lappend nsList "::${ns}"
	}
    }
    lappend nsList {}
    # See if any of these procNames/commands/vars/whatevers are recognized.
    if {[string index $gotName 0] == "\$"} {
	set useName [string trimleft $gotName \$:]
	foreach ns $nsList {
	    if {[Tcl::DblClickVarHelper ${ns}::$useName]} {return}
	}
    } else {
	set useName [string trimleft $gotName :]
	# Look for procs first.
	foreach ns $nsList {
	    if {![catch [list procs::findDefinition ${ns}::$useName]]} {
		# But if we're dealing with a Tcl/tk core command (possibly
		# redefined in AlphaTcl) then also continue.
		if {$ns == "" && [lsearch $tcltkKeywords $useName] > -1} {
		    catch {Tcl::DblClickHelper $useName}
		}
		return
	    }
	}
	foreach ns $nsList {
	    if {![catch [list Tcl::DblClickHelper ${ns}::$useName]]} {
		return
	    }
	}
    }
    
    # Still here?
    status::msg "No information for '$gotName' available."
}

proc Tcl::DblClickHelper {txt} {
    
    global TclmodeVars HOME auto_index \
      alphaKeyWords alphaObsProcs alphaObsCommands
    
    variable tclCommands.8.5
    variable tclKeywords
    variable tclXKeywords
    variable tkKeywords
    
    regsub {^::} $txt "" txt
    # Is it a core Tcl command?
    foreach type [list tclKeywords tkKeywords] {
	if {([lsearch [set $type] $txt] > -1)} {
	    # Is it a core Tcl 8.5 command?
	    if {([info tclversion] < 8.5) \
	      && ([lsearch ${tclCommands.8.5} $txt] > -1)} {
		# This should be defined in some SystemCode file, so we'll
		# let a later routine here deal with it.
		break
	    } 
	    set localFile [help::pathToHelp "Tcl 8.4 Commands.txt" 1]
	    if {($type eq "tclKeywords") && ($localFile ne "") \
	      && $TclmodeVars(useTextFileForTclCommandHelp)} {
		help::openGeneral $localFile $txt
		return
	    }
	    switch -- $type {
		"tclKeywords" {set dir "TclCmd"}
		"tkKeywords"  {set dir "TkCmd"}
	    }
	    variable tcltkKeywordRedirect
	    if {[info exists tcltkKeywordRedirect($txt)]} {
		set txt $tcltkKeywordRedirect($txt)
	    }
	    set localDir [file join $TclmodeVars(tcl/TkHelpLocalFolder) $dir]
	    if {[file isdir $localDir]} {
		htmlView [file join $localDir ${txt}.htm]
	    } else {
		set baseUrl [string trimright \
		  $TclmodeVars(tcl/TkHelpUrlDir) " /"]
		urlView $baseUrl/${dir}/${txt}.htm
	    }
	    return
	}
    }
    # Is it a built-in Alpha command?
    foreach type [list alphaKeyWords alphaObsProcs alphaObsCommands] {
	if {![info exists $type]} {
	    continue
	}
	if {([lsearch [set $type] $txt] > -1)} {
	    switch -- $type {
		"alphaKeyWords" {
		    help::openFile "Alpha Commands"
		    if {![editMark [win::Current] $txt 1]} {
			set pat1 "¥ $txt"
			set pat2 $txt
			foreach pat [list $pat1 $pat2] {
			    set limits [search -n -s -f 1 -r 0 -- $pat [minPos]]
			    if {[llength $limits]} {
				goto [lindex $limits 0]
				break
			    }
			}
		    }
		}
		"alphaObsProcs" {
		    # We already know that [procs::findDefinition] failed.
		    alertnote "'$txt' is an obsolete procedure.  No further\
		      information is available."
		}
		"alphaObsCommands" {
		    # Does this appear anywhere in "Alpha Commands"?
		    set AlphaCommands [file join $HOME Help "Alpha Commands"]
		    set lines [grep "^¥ ${txt}( |\$)" $AlphaCommands]
		    if {[string length $lines]} {
			help::openFile "Alpha Commands"
			goto [pos::fromRowChar [string trimright \
			  [lindex [split $lines "\n"] 1 3] :] 0]
		    } else {
			alertnote "'$txt' is an obsolete command.  No further\
			  information is available."
		    }
		}
	    }
	    return
	}
    }
    # Is it a TclX procedure?
    if {$TclmodeVars(recogniseTclX) \
      && ([lsearch $tclXKeywords $txt] > -1)} {
	alertnote here
	set localFile [help::pathToHelp "TclX Help"]
	if {$TclmodeVars(useTextFileForTclCommandHelp) \
	  && [file exists $localFile]} {
	    help::openFile $localFile
	    set pat "^\\s+$txt\\s"
	    set limits [search -n -s -f 1 -r 1 -- $pat [minPos]]
	    if {[llength $limits]} {
		goto [lindex $limits 0]
	    }
	} else {
	    urlView $TclmodeVars(tclxHelpUrl)
	}
	return
    }
    # Is it a loadable proc?  Here we use the exact namespace qualifier.
    if {![catch {procs::findDefinition $txt}]} {
	return
    }
    if {[info exists auto_index($txt)]} {
	if {![editMark $auto_index($txt) $txt]} {
	    # Some marking schemes commonly used for Tcl modes.
	    set pat1 "proc\[ \t\]+[quote::Regfind ${txt}]\[ \t\]"
	    set pat2 "proc\[ \t\]+\{[quote::Regfind ${txt}]\}\[ \t\]"
	    foreach pat [list $pat1 $pat2] {
		set limits [search -n -s -f 1 -r 1 -m 0 -- $pat [minPos]]
		if {[llength $limits]} {
		    goto [lindex $limits 0]
		    break
		}
	    }
	}
	return
    }
    # Is it some global variable?
    if {[Tcl::DblClickVarHelper $txt]} {
	return
    }
    # Is it a proc defined in the current file?  (Becoming desperate ...)
    set pat1 "proc\[ \t\]+[quote::Regfind ${txt}]\[ \t\]"
    set pat2 "proc\[ \t\]+\{[quote::Regfind ${txt}]\}\[ \t\]"
    foreach pat [list $pat1 $pat2] {
	set limits [search -n -s -f 1 -r 1 -m 0 -- $pat [minPos]]
	if {[llength $limits]} {
	    goto [lindex $limits 0]
	    return
	}
    }
    # Still here?
    error "Couldn't identify definition/help file/information for '${txt}'."
}

proc Tcl::DblClickVarHelper {txt} {
    
    variable interpCmd

    set txt [string trim [string trimleft $txt {$}]]
    # Do we recognize this as a variable, array, array element?
    if {[$interpCmd [list info exists $txt]]} {
	Tcl::showVarValue $txt
	return 1
    }
    return 0
}

##
 # --------------------------------------------------------------------------
 # 
 # "Tcl::getVarValue" --
 # 
 # Report the current value of a global variable, chosen interactively from a
 # list of all active variables.
 #
 # --------------------------------------------------------------------------
 ##

proc Tcl::getVarValue {} {
    
    if {[catch {getSelect} def]} {set def ""}
    set def [string trimleft $def "\$"]
    if {[is::List $def] && [llength $def] > 1} {
	error "Cancelled: variable names can only be a single word"
    }
    set var [Tcl::getVarFromList $def]
    if {![string length $var]} {return}
    Tcl::showVarValue $var
}

proc Tcl::getVarFromList {{def ""}} {
    variable interpCmd

    if {[string length $def]} {
	if {[$interpCmd "info exists $def"]} {return $def} 
    } 
    set ns [namespace qualifiers $def]
    if {[string length $ns] && ![$interpCmd "namespace exists $ns"]} {
	set def ""
	set ns  "::"
    }
    set def [namespace tail $def]
    
    set items [list]
    foreach var [$interpCmd "info vars ${ns}::*"] {
	lappend items [namespace tail $var]
    }
    foreach kid [$interpCmd "namespace children $ns"] {
	lappend items "[namespace tail $kid]::"
    }
    if {$ns != "::"} {
	set items [concat "::" [lsort -dictionary $items]]
    } else {
	set items [lsort -dictionary $items]
    }
    set items [lremove -all $items [list ""]]
    if {[lsearch $items $def] == -1} {set def [lindex $items 0]}
    set p "Which var in namespace '${ns}::'?"
    set var [listpick -p $p -L [list $def] $items]
    if {$var == "::"} {
	set var [Tcl::getVarFromList $ns]
    } elseif {[namespace qualifiers $var] != ""} {
	set var [Tcl::getVarFromList "${ns}::${var}"]
    } else {
	set var "${ns}::${var}"
    }
    return $var
}

##
 # --------------------------------------------------------------------------
 # 
 # "Tcl::showVarValue" --
 # 
 # If the variable is an array, or its value is too big to fit in an
 # alertnote, then its contents are listed in a new window, otherwise the
 # variable's value is displayed in an alertnote.  Note that unlike the
 # [showVarValue] proc (in the global namespace) this uses the current
 # interpreter, not the internal one.
 # 
 # --------------------------------------------------------------------------
 ##

proc Tcl::showVarValue {var} {
    
    variable interpCmd

    if {![$interpCmd "info exists $var"]} {
	alertnote "\"${var}\" doesn't exist in this context."
    } elseif {[$interpCmd "array exists $var"]} {
	new -n "* $var *" -info [Tcl::listArray $var]
	# Use 'shrinkWindow' to trim the size of the output window.
	shrinkWindow 2
    } else {
	set value [$interpCmd "set $var"]
	viewValue $var $value
    }
}

##
 # --------------------------------------------------------------------------
 # 
 # "Tcl::listArray" --
 # 
 # List the name and value of each element of the array $arrName. 
 # (Convenient to use as a shell command.)  Similar to [parray].  Uses the
 # current interpreter to determine the value.  Note that unlike the
 # [listArray] proc (in the global namespace) this uses the current
 # interpreter, not the internal one.
 # 
 # --------------------------------------------------------------------------
 ##

proc Tcl::listArray {arrName} {
    
    variable interpCmd

    if {![$interpCmd "array exists $arrName"]} {
	alertnote "\"${arrName}\" doesn't exist in this context."
	return
    }
    array set tempArray [$interpCmd "array get $arrName"]

    set maxlen 0
    foreach name [array names tempArray] {
	if {[string length $name] > $maxlen} {
	    set maxlen [string length $name]
	}
    }
    incr maxlen 4
    set results {}
    foreach name [lsort -dictionary [array names tempArray]] {
	set value $tempArray($name)
	append results [format "%-${maxlen}s%-2s\r" \"$name\" $value]
    }
    return [string trim $results]
}

# These next two probably belong in the AlphaTcl core, possibly in the
# "prefsHandling.tcl" file.

##
 # --------------------------------------------------------------------------
 # 
 # "showVarValue" --
 # 
 # If the variable is an array, or its value is too big to fit in an
 # alertnote, then its contents are listed in a new window, otherwise the
 # variable's value is displayed in an alertnote.
 # 
 # --------------------------------------------------------------------------
 ##

proc showVarValue {var} {
    
    global $var
    
    if {![info exists $var]} {
        alertnote "\"${var}\" doesn't exist as a global variable."
    } elseif {[array exists $var]} {
	new -n "* $var *" -info [listArray $var]
	# Use 'shrinkWindow' to trim the size of the output window.
	shrinkWindow 2
    } else {
	viewValue $var [set $var]
    }
}

##
 # --------------------------------------------------------------------------
 # 
 # "listArray" --
 # 
 # List the name and value of each element of the array $arrName.
 # (Convenient to use as a shell command.)  Similar to [parray].
 # 
 # --------------------------------------------------------------------------
 ##

proc listArray {arrName} {
    
    global $arrName
    
    if {![array exists $arrName]} {
	alertnote "\"${arrName}\" doesn't exist as a global array."
	return
    }
    array set tempArray [array get $arrName]

    set maxlen 0
    foreach name [array names tempArray] {
	if {[string length $name] > $maxlen} {
	    set maxlen [string length $name]
	}
    }
    incr maxlen 4
    set results {}
    foreach name [lsort -dictionary [array names tempArray]] {
	set value $tempArray($name)
	append results [format "%-${maxlen}s%-2s\r" \"$name\" $value]
    }
    return [string trim $results]
}

# ===========================================================================
# 
# .