## -*-Tcl-*-
 # ==========================================================================
 # Perl mode - an extension package for Alpha
 #
 # FILE: "perlMode.tcl"
 #                                          created: 08/17/1994 {09:12:06 am}
 #                                      last update: 03/21/2006 {03:23:22 PM}
 # Description:
 # 
 # This is a set of routines that allow Alpha to act as a front end for the
 # standalone MacPerl application and that allow Perl scripts to be used as
 # text filters in Alpha.  These functions are accessed through a special
 # Perl menu.
 #
 # The features of this package are explained in the file "Perl Help",
 # accessible from the Help menu.
 # 
 # See the "perlVersionHistory.tcl" file for license info, credits, etc.
 #                               
 # ==========================================================================
 ## 

# ===========================================================================
#
# ×××× Initialization of Perl mode ×××× #
# 

alpha::mode Perl 3.7b1 perlMenu {*.pl *.ph *.pm} {
    perlMenu
} {
    # Script to execute at Alpha startup
    addMenu perlMenu "¥132"
    set modeCreator(McPL) Perl
    set unixMode(perl)    Perl
    # Make sure that we have a 'Perl::PrevScript' variable.
    ensureset Perl::PrevScript {*startup*}
    # Make sure that we have a 'PerlSearchPath' variable.
    ensureset PerlSearchPath ""
} uninstall {
    catch {file delete [file join $HOME Tcl Modes "Perl Mode"]}
    catch {file delete [file join $HOME Tcl Completions PerlCompletions.tcl]}
    catch {file delete [file join $HOME Tcl Completions "Perl Tutorial.pl"]}
    catch {file delete [file join $HOME Help "Perl Commands"]}
    catch {file delete [file join $HOME Help "Perl Help"]}
} maintainer {
} description {
    Supports the editing of Perl programming files
} help {
    file "Perl Help"
}

proc perlMode.tcl {} {}
proc perlMenu     {} {}

namespace eval Perl {}

# ===========================================================================
#
# ×××× Perl mode preferences ×××× #
# 

# Removing obsolete preferences from earlier versions.

set oldVars [list \
  elecLBrace elecRBrace electricReturn electricSemi electricTab]
foreach oldVar $oldVars {prefs::removeObsolete PerlmodeVars($oldVar)}

# Renaming variables

set oldVars [list \
  perluseDebugger perlretrieveOutput perlautoSwitch perloverwriteSelection \
  perlapplyToBuffer perlpromptForArgs perlRecycleOutput perlFilterPath]
foreach oldVar $oldVars {
    regsub {^perl} $oldVar {} newVar
    if {$newVar == "RecycleOutput"}  {set newVar "recycleOutput"}
    if {$newVar == "perlFilterPath"} {set newVar "perlTextFiltersPath"} 
    prefs::renameOld $oldVar $newVar
}

unset -nocomplain oldVars
unset -nocomplain oldVar
unset -nocomplain newVar

# ===========================================================================
#
# Standard preferences recognized by various Alpha procs
#

newPref flag autoMark	               {1}     Perl
newPref var  lineWrap	               {0}     Perl
newPref var  prefixString              {# }    Perl

# I simplified this regexp to make sure that nearby word completions work
# in Alphatk -- cbu

# newPref var  wordBreak        {(([$%@*]?[_\w]+)|(\$?[][&_`'+*./|,\\";#%=\~^:?!@\$<>()-])|((\$\^)\w))} Perl

newPref var  wordBreak          {[\w%@$_*^]+} Perl

# To automatically perform context relevant formatting after typing a left
# or right curly brace, turn this item on||To have the brace keys produce a
# brace without additional formatting, turn this item off
newPref flag electricBraces    1 Perl
# To automatically perform context relevant formatting after typing a
# semicolon, turn this item on||To have the semicolon key produce a
# semicolon without additional formatting, turn this item off
newPref flag electricSemicolon 1 Perl
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn    1 Perl


# Perl mode initialisations:
set Perl::escapeChar "\\"
set Perl::quotedstringChar "\""
set Perl::lineContinuationChar "\\"

# ===========================================================================
#
# Flag preferences
#

# Turn this item on to apply the filter to the entire current text
# window||Turn this item off to use only the selected text when applying
# the filter
newPref flag applyToBuffer             {1}     Perl {Perl::postEval}
# Turn this item on to automatically switch to Perl while scripts are
# being executed||Turn this item off to keep Alpha frontmost until the
# script finishes
newPref flag autoSwitch                {1}     Perl {Perl::postEval}
# Turn this item on to always send commands from command double-clicking
# to the "Perl5 Help Url"||Turn this item off to always send commands
# from command double-clicking to the local "Perl 5 Help Docs Folder",
# opening a local file in Alpha.
newPref flag clickSearchesOnline       {0}     Perl 
# Turn this item on to include a submenu containing all of the scripts in
# the "Perl Local Lib Folder".  This might take a while to build||Turn this
# item off to remove the submenu containing all of the scripts in the "Perl
# Local Lib Folder"
newPref flag includeLocalLibMenu       {0}     Perl {Perl::updatePreferences}
# Turn this item on to include a submenu containing all of the scripts in
# the "Perl Search Paths" preference||Turn this item off to remove the
# submenu containing all of the scripts in the "Perl Search Paths"
# preference
newPref flag includePerlPathMenu       {0}     Perl {Perl::updatePreferences}
# Turn this item on to have Alpha prompt you for command-line arguments
# to be passed to the script||Turn this item off to avoid prompts from
# Alpha which will then be passed to the script
newPref flag promptForArgs             {0}     Perl {Perl::postEval}
# Turn this item on to overwrite any previous output window||Turn this
# item off to disable the automatic overwriting of any previous output
# window
newPref flag recycleOutput             {0}     Perl
# Turn this item on to automatically retrieve any output written to the
# Perl output window, displaying it in a new window under Alpha||Turn
# this item off to disable the automatic retrieval of any Perl output window
newPref flag retrieveOutput            {1}     Perl {Perl::postEval}
# Turn this item on to replace the input text in the original window with
# the output from the text filter script||Turn this item off to always
# write the output into a new window
newPref flag overwriteSelection        {0}     Perl {Perl::postEval}
# Turn this item on to automatically run scripts selected in the "Perl
# ...  Filters" menus without being prompted to continue||Turn this item
# off to always be presented with a confirmation dialog before running
# scripts in the "Perl ...  Filters" menus.
newPref flag runWithoutConfirmation    {0}     Perl
# Turn this item on to mark files structurally, recognising the special
# comments entered by 'ctrl-3'||Turn this item off to ignore special
# marks entered by 'ctrl-3', and to order marks alphabetically
newPref flag structuralMarks           {1}     Perl {Perl::MarkFile}
# Turn this item on to force the script to run under the Perl debugger.
# Control is automatically switched to Perl when the debugger is
# used||Turn this item off to avoid forcing the script to run under the
# Perl debugger
newPref flag useDebugger               {0}     Perl {Perl::postEval}

# This set is used in the 'Perl Options' menu.
set Perl::PrefsInMenu1 [list 	\
  autoSwitch			\
  promptForArgs			\
  retrieveOutput		\
  useDebugger			\
  (-)                           \
  structuralMarks               \
  clickSearchesOnline           ]
  
# This set is used in the 'Filter Options' menu.
set Perl::PrefsInMenu2 [list 	\
  applyToBuffer			\
  overwriteSelection		\
  runWithoutConfirmation        \
  (-)				\
  includeLocalLibMenu		\
  includePerlPathMenu		]

# ===========================================================================
#
# Variable preferences
#

# The location of the local Perl application.
newPref sig  perlSig                   {McPL}   Perl
# The url used for the "Perl Home Page" menu item.
newPref url  perlHomePage              {http://www.perl.com/} Perl
# If the menu flag "Prompt For Args" is checked, then the user is
# prompted for command-line arguments at the time the script is run.
# These commands are saved in this preference, and become the default
# arguments the next time the script is executed.
newPref var  perlCmdlineArgs           {}       Perl
# The location of any additional search paths used to build the "Perl
# Text Filters" menu.
newPref var  perlTextFiltersPath \
  [file join $HOME Tcl Packages "Text Filters"] Perl {Perl::buildSearchPath}
# The location of the local version of the Perl 5 Commands Help folder.
newPref var  perlHelpDocsFolder        {}       Perl
# The url for the Perl 5 documentation site.
newPref url  perl5HelpUrl      {http://language.perl.com/manual/pod/} Perl
# The location of any local Perl library, used to find 'require'd files while
# command double-clicking, and to create the "Perl Lib Scripts" submenu.
newPref var  perlLibFolder             {}       Perl {Perl::updatePreferences}
# The version of Perl used by the local application.  If this is set to
# 4, then a more limited set of keywords will be colourized, and command
# double-clicking on any keyword will open the "Perl Commands" help file.
newPref var  perlVersion               {5}      Perl {Perl::updatePreferences} [list 4 5]

proc Perl::updatePreferences {prefName} {
    
    global mode
    
    switch -- $prefName {
        "perlVersion" {
            Perl::colorizePerl $prefName
        }
        "perlVersion" {
	    Perl::postEval
        }
	"commentColor" - "stringColor" {
	    stringColorProc $prefName
	    if {($mode eq "Perl")} {
		refresh
	    } 
	}
	"commandColor" - "magicColor" - "symbolColor" {
	    Perl::colorizePerl
	    if {($mode eq "Perl")} {
	        refresh
	    } 
        }
        default {
	    Perl::buildSearchPath
	    menu::buildSome "perlMenu"
        }
    }
    return
}

# ===========================================================================
#
# A quick check to see if we can find the local Perl application.
#

proc Perl::perlFolder {} {

    global PerlmodeVars
    
    if {![catch {nameFromAppl $PerlmodeVars(perlSig)} perlPath]} {
	return [file dirname $perlPath]
    } else {
	error "Cancelled -- couldn't find the local Perl application."
    }
}

# The following works, but if the 'includeLocalLibMenu' preference is set,
# this will over-write the "File" and "Search" menus!!  Until the proc
# menu::buildHierarchy does some sort of manipulation with the menu names
# to ensure that this doesn't happen, best to leave it alone.

# # Try to find the local Perl lib folder.
# if {![string length $PerlmodeVars(perlLibFolder)]} {
#     # First find the location of the local Perl application.
#     if {![catch {Perl::perlFolder} perlPath]} {
# 	# Now look for the Lib folder.
# 	if {![catch {glob -dir $perlPath "*\[Ll\]ib*"} libPath]} {
# 	    # Found it!
# 	    set PerlmodeVars(perlLibFolder) [lindex $libPath 0]
# 	} 
#     } 
# } 

unset -nocomplain perlPath
unset -nocomplain libPath

# ===========================================================================
#
# Colorization setup
#

# The color of all text following the # symbol.
newPref color commentColor      {red}       Perl {Perl::updatePreferences}
# The color of all defined commands.
newPref color commandColor      {blue}      Perl {Perl::updatePreferences}
# The color of all text contained within double quotes.
newPref color stringColor       {green}     Perl {Perl::updatePreferences}
# In Perl mode, the colour of words started by '$'.  Perl considers such 
# words to be variables.
newPref color magicColor        {none}      Perl {Perl::updatePreferences}
# reading regular expressions.
newPref color symbolColor       {none}      Perl {Perl::updatePreferences}

# Call this now, so that all of the rest can be adds.
regModeKeywords -C Perl {}

proc Perl::colorizePerl {} {
    
    global PerlmodeVars Perl::Keywords

    # Create the list of keywords, based upon the version used in Perl mode.
    Perl::setPerl[set PerlmodeVars(perlVersion)]Keywords
    
    regModeKeywords -a                          \
      -e {#}                                	\
      -c $PerlmodeVars(commentColor)        	\
      -s $PerlmodeVars(stringColor)             \
      -k $PerlmodeVars(commandColor) Perl [set Perl::Keywords]
    
    regModeKeywords -a                          \
      -i "+" -i "-" -i "*" -i "\\"              \
      -I $PerlmodeVars(symbolColor) Perl {}

    regModeKeywords -a 				\
      -m {$}					\
      -k $PerlmodeVars(magicColor) Perl {}        
    
    return
}

# Call this now.
Perl::colorizePerl

# Set comment characters.
set Perl::commentRegexp {^[ \t]*#}
set Perl::commentCharacters(General) "#"
set Perl::commentCharacters(Paragraph) [list "## " " ##" " # "]
set Perl::commentCharacters(Box) [list "#" 1 "#" 1 "#" 3]

# ===========================================================================
# 
# Update the 'Perl::PrevScript' variable.
# 

proc Perl::setLastFilter {args} {

    global Perl::PrevScript
    
    if {[llength $args] == "1"} {set args [lindex $args 0]}
    set Perl::PrevScript $args
    Perl::postEval
}

# ===========================================================================
#
# ×××× Electrics, Indentation ×××× #
# 

Bind    up   <sz>   {Perl::searchFunc 0 0 0}  Perl
Bind  left   <sz>   {Perl::searchFunc 0 0 1}  Perl
Bind  down   <sz>   {Perl::searchFunc 1 0 0}  Perl
Bind right   <sz>   {Perl::searchFunc 1 0 1}  Perl

Bind '\('           {Perl::electricLeft "\("}                             Perl
Bind '\)'           {Perl::electricRight "\)"}                            Perl

# Necessary for Alphatk ...

if {0} {
Bind 0x13    <z>    {Perl::menuProc "perlInsertions" "Add Remove \@"}     Perl
Bind 0x14    <z>    {Perl::menuProc "perlInsertions" "Insert Divider"}    Perl
Bind 0x15    <z>    {Perl::menuProc "perlInsertions" "Add Remove \$"}     Perl
}

# ===========================================================================
# 
# Perl Carriage Return
# 
# Inserts a carriage return, and indents properly.
# 

proc Perl::carriageReturn {} {
    
    if {[isSelection]} {deleteSelection} 
    
    set pos1 [lineStart [getPos]]
    set pos2 [getPos]
    if {[regexp -- {^([\t ])*(\}|\))} [getText $pos1 $pos2]]} {
	createTMark temp $pos2
	catch {bind::IndentLine}
	gotoTMark temp ; removeTMark temp
    } 
    insertText "\r"
    catch {bind::IndentLine}
}

proc Perl::electricLeft {{char "\{"}} {
    global PerlmodeVars
    
    if {!$PerlmodeVars(electricBraces)} {
	typeText $char
	return
    }
    
    if {[literalChar]} {insertText $char ; return}
    set pat "\}\[ \t\r\n\]*(else|elsif|elseif|if)\[ \t\r\n\]*\$"
    set p [getPos]
    if {[set res [findPatJustBefore "\}" "$pat" $p word]] == ""} { 
	insertText $char
	return
    }
    # we have an if/else(if)/else
    # The behaviour here is optional, because some people may not
    switch -- $word {
	"else" {
	    deleteText [lindex $res 0] $p
	    elec::Insertion "\} $word \{\r\t¥¥\r\}\r¥¥"
	}
	"if" {
	    elec::Insertion "\(¥¥\) \{\r\t¥¥\r\}\r¥¥"
	}
	"elsif" -
	"elseif" {
	    deleteText [lindex $res 0] $p
	    elec::Insertion "\} $word \(¥¥\) \{\r\t¥¥\r\}\r¥¥"
	}
    }
}

proc Perl::electricRight {{char "\}"}} {
    global PerlmodeVars
    
    if {!$PerlmodeVars(electricBraces)} {
	typeText $char
	return
    }
    
    if {[literalChar]} {insertText $char ; return }
    set p [getPos]
    if {[regexp -- "\[^ \t\]" [getText [lineStart $p] $p]]} {
	insertText $char
	blink [matchIt $char [pos::math $p - 1]]
	return
    }
    set start [lineStart $p]
    insertText $char
    createTMark perl_er [getPos]
    backwardChar
    bind::IndentLine
    gotoTMark perl_er ; removeTMark perl_er
    bind::CarriageReturn
    blink [matchIt "\}" [pos::math $start - 1]]
}

proc Perl::electricSemi {} {
    global PerlmodeVars
    
    if {!$PerlmodeVars(electricSemicolon)} {
	typeText ";"
	return
    }

    if {[isSelection]} {deleteSelection}
    set pos  [getPos]
    set text [getText [lineStart $pos] $pos]
    
    set inFor 0
    if {[string first "for" $text] != "-1"} {
	set len [string length $text]
	for {set i 0} {$i < $len} {incr i} {
	    switch -- [string index $text $i] {
		"("	{ incr inFor }
		")"	{ incr inFor -1 }
	    }
	}
    }
    if {$inFor != 0 || [text::isInComment $pos] || [text::isInString $pos]} {
	insertText ";"
    } else {
	# This is the only change from ::electricSemi
	insertText ";" [text::indentString $pos]
	bind::CarriageReturn
    }
}

proc Perl::correctIndentation {args} {
    
    global mode indentationAmount PerlmodeVars
    
    win::parseArgs w pos {next ""}
    
    set posBeg    [pos::lineStart -w $w $pos]
    # Get information about this line, previous line ...
    set thisLine  [Perl::getCommandLine -w $w $posBeg 1 2]
    set prevLine1 [Perl::getCommandLine -w $w \
      [pos::math -w $w $posBeg - 1] 0 2]
    set prevLine2 [Perl::getCommandLine -w $w \
      [pos::math -w $w [lindex $prevLine1 0] - 1] 0 2]
    set lwhite    [lindex $prevLine1 1]
    # If we have a previous line ...
    if {[pos::compare -w $w [lindex $prevLine1 0] != $posBeg]} {
	set pL1 [string trim [lindex $prevLine1 2]]
	# Find out if there are any unbalanced {,},(,) in the last line.
	regsub -all {[^ \{\}\(\)\"\*\/\\]} $pL1 { } line
	# Remove all literals.
	regsub -all {\\\{|\\\}|\\\(|\\\)|\\\"|\\\*|\\\/} $line { } line
	regsub -all {\\} $line { } line
	# Remove everything surrounded by quotes.
	regsub -all {\"([^\"]+)\"} $line { } line
	regsub -all {\"} $line { } line
	# Remove everything surrounded by bracketed comments.
	regsub -all {/\*([^\*/]+)\*/} $line { } line
	# Now turn all braces into 2's and -2's
	regsub -all {\{|\(} $line { 1 }  line
	regsub -all {\}|\)} $line { -1 } line
	# This list should now only contain 2's and -2's.
	foreach i $line {
	    if {$i == "1" || $i == "-1"} {
		incr lwhite [expr {$i * $indentationAmount}]
	    }
	}
       # Did the last line start with a lone \) or \} ?  If so, we want to
	# keep the indent, and not make call it an unbalanced line.
	if {[regexp -- {^[\t ]*(\}|\))} $pL1]} {
	    incr lwhite $indentationAmount
	} 
    } 
    # If we have a current line ...
    if {[pos::compare -w $w [lindex $thisLine 0] == $posBeg]} {
	# Reduce the indent if the first non-whitespace character of this
	# line is ) or \}, or an "end" command.
	set tL [lindex $thisLine 2]
	if {$next == "\}" || $next == ")" || [regexp -- {^[\t ]*(\}|\))} $tL]} {
	    incr lwhite -$indentationAmount
	} 
    } 
    # Now we return the level to the calling proc.
    return [expr {$lwhite > 0 ? $lwhite : 0}]
}

# ===========================================================================
# 
# Get Command Line
# 
# Find the next/prev command line relative to a given position, and return
# the position in which it starts, its indentation, and the complete text
# of the command line.  If the search for the next/prev command fails,
# return an indentation level of 0.
# 

proc Perl::getCommandLine {args} {
    
    win::parseArgs w pos {direction 1} {ignoreComments 1}
    
    if {$ignoreComments} {
	set pat {^[\t ]*[^\t\r\n\# ]}
    } else {
	set pat {^[\t ]*[^\t\r\n ]}
    } 
    set posBeg [pos::math -w $w [pos::lineStart -w $w $pos] - 1]
    if {[pos::compare -w $w $posBeg < [minPos -w $w]]} {
	set posBeg [minPos -w $w]
    } 
    set lwhite 0
    if {![catch {search -w $w -s -f $direction -r 1 $pat $pos} match]} {
	set posBeg [lindex $match 0]
	set lwhite [lindex [pos::toRowCol -w $w \
	  [pos::math -w $w [lindex $match 1] - 1]] 1]
    }
    set posEnd [pos::math -w $w [pos::nextLineStart -w $w $posBeg] - 1]
    if {[pos::compare -w $w $posEnd > [maxPos -w $w]]} {
	set posEnd [maxPos -w $w]
    } 
    if {[pos::compare -w $w $posEnd < $posBeg]} {
	set posEnd $posBeg
    }
    return [list $posBeg $lwhite [getText -w $w $posBeg $posEnd]]
}

# ===========================================================================
# 
# End of Command
# 
# Determine if the command in a line of a given position was terminated.
# 

proc Perl::endOfCommand {line} {
    
    # First remove any valid comment, after taking care of possible # marks
    # contained in quotes, or preceded by $, or literals.
    regsub -all {(\"([^\"]+)\")|\$\#|\\\#} $line { } line
    regsub -all {\#.*$} $line { } line
    # Check to see if the last line ended with ; or \}, indicating end.
    # We also catch lines that end with \{, because the indentation of
    # these lines will be automatically increased.  And, lines that end
    # with . are probably going to have to be manually formatted.
    if {[regexp -- {(\.|;|\}|\{)([\t ]*)$} $line]} {
	return 1
    } else {
	return 0
    } 
}

proc Perl::searchFunc {direction args} {
    
    if !{[llength $args]} {set args [list 0 2]}
    if {$direction} {
	eval function::next $args
    } else {
	eval function::prev $args
    }
}

# ===========================================================================
#
# ×××× Command Double-Click ×××× #
# 
# Cmd-double-click support for Perl mode. 
# 
# Note that we would use 'editMark' quite a bit here, but as of yet we
# have no way of guaranteeing that the help files as properly marked in
# Windows.
# 
# Any proc that is called by command double click should return "1" if a
# bookmark is placed, "0" if the proc was inappropriately called.  Anything
# else returned by a called proc will be treated as a message for the user.
# 

proc Perl::DblClick {from to args} {

    global PerlmodeVars HOME Perl::Keywords 
    global Perl::SpecialVars Perl::ExprWords Perl::Lookup
    
    set noBack  [lookAt $to]
    set oneBack [lookAt [pos::math $from - 1]]
    set twoBack [lookAt [pos::math $from - 2]]
    
    set PerlVersion  $PerlmodeVars(perlVersion)
    
    # Extend selection to include special characters.
    if {$oneBack == {$}} { 
	if {[pos::compare $from == $to]} {set to [pos::math $to + 1]}
	set from [pos::math $from - 1]
	if {$noBack == {^}} {set to [pos::math $to + 1]}
    } elseif {$oneBack == {^} && $twoBack == {$}} {
	set from [pos::math $from - 2]
    } elseif {$oneBack == {%} || $oneBack == {@}} {
	set from [pos::math $from - 1]
    }
    
    # Return if there's no selected text
    if {![pos::compare $to > $from]} {return}
    selectText $from $to
    set text  [getSelect]
    set qtext [quote::Regfind $text]
    set result 0
    
    if {$noBack == "&" || $oneBack == "&"} {
	# Function call
	if {![catch {search -f 1 -r 1 -m 0 -s "sub *$qtext *\{" [minPos]} match]} {
	    placeBookmark
	    eval selectText $match
	    set result 1
	} else {
	    error "Cancelled -- sub definition not found"
	}
    } elseif {[set filename [Perl::findRequire $from $to]] != ""} {
	# If user clicked the arg of a 'require' command, open the file.
	set result [Perl::openPerlFile $filename]
    } elseif {![lcontains Perl::Keywords $text]} {
	# This is not a valid keyword.
	set result 0
    } elseif {$PerlVersion == "5" && $PerlmodeVars(clickSearchesOnline)} {
	# Try to open an on-line man page.
	set result [Perl::wwwCommandSearch $text]
    } else {
	# Try to find the command in the local Help file(s).
	set result [Perl::localCommandSearch $text]
    }
    
    if {$result == "1"} {
	# We successfully opened a new file.
	status::msg "Press 'Ctrl-.' to return to original cursor point."
    } elseif {$result == "0"} {
	# Not sure what to do with this.
	status::msg "Command-double-click on keywords, special vars, and req'd filenames"
    } else {
        status::msg $result
    }
}

proc Perl::localCommandSearch {{command ""}} {

    global PerlmodeVars
    
    if {![string length $command]} {
	set command [prompt "local Perl help for ... " [getSelect]]
    }
    return [Perl::perl[set PerlmodeVars(perlVersion)]CommandSearch $command]
}

proc Perl::wwwCommandSearch {{command ""}} {
    
    global PerlmodeVars Perl::Lookup Perl::Keywords
    
    if {![string length $command]} {
	set command [prompt "on-line Perl help for ... " [getSelect]] 
    }
    if {![info exists Perl::Lookup]} {Perl::setPerl5Keywords}
    if {[lcontains Perl::Keywords $command]} {
	# Look up keywords in the proper man page.  'folder' might be an
	# actual directory, or it might be a page containing a lot of
	# targets.
	set folder  [lindex [set Perl::Lookup($command)] 0]
	set target  [lindex [set Perl::Lookup($command)] 1]
	if {$folder == "perlvar"} {
	    # This folder no longer exists.  Everything is in the
	    # perlvar.html file, with targets.
	    regsub -all {^[$@% ]} $target {_} target
	    set urlTail "${folder}.html\#item_${target}"
	} elseif {$folder == "perlovl"} {
	    # This folder/page no longer exists.
	    set urlTail "perl.html"
	} elseif {$target == $command} {
	    # We're pretty sure that this command has its own page.
	    set urlTail "${folder}/${command}.html"
	} else {
	    # Not so sure ... but we think that it has a target in the page.
	    regsub -all { } $target {_} target
	    set urlTail "${folder}.html\#${target}"
	}
    } else {
	# Not sure what to do with this.  Just send it to the index page.
	set urlTail ""
    }
    set url [string trimright $PerlmodeVars(perl5HelpUrl) /]/${urlTail}
    urlView $url
    return "'$url' sent to browser."
}

# ===========================================================================
# 
# ×××× Mark File, Parse Funcs ×××× #
# 

proc Perl::MarkFile {args} {
    
    global mode
    
    if {[llength $args]} {
	# Called by changing the 'structuralMarks' preference.
	if {$mode == "Perl"} {
	    removeAllMarks
	} else {
	    return
	}
    }
    
    status::msg "Marking Window ..."
    
    global PerlmodeVars
    
    set structuralMarks $PerlmodeVars(structuralMarks)
    set pos [minPos]
    set l {} 
    set asEncountered {}
    
    # With this regex we scan for:
    # 
    # a package followed by a block with indented sub's, or
    # a package statement with just normal, non-indented sub's
    # 
    # {
    #     (
    #         ^
    #         (

    #         package\s+[_\w:]+\s*;\s*\{
    #         |package\s+[_\w:]+\s*;
    #         |BEGIN
    #         |END
    #         |sub\s+[_\w:]+(\s+\([$@%*;\]+\))?\s*\{
    #         |[ \t]+sub\s+[_\w:]+(\s+\([$@%*;\]+\))?\s*\{
    # 	      |=head1
    # 	      |=head2(.*)Section
    # 	      |=pod
    # 	      |__END__
    # 	      |__DATA__
    # 	      )
    #     )
    # }
    # 
    # set markExpr {(^(package\s+[_\w:]+\s*;\s*\{|BEGIN|END|sub\s+[_\w:]+(\s+\([$@%*;\]+\))?\s*\{|=head1|=pod|__END__|__DATA__)(\s+[^\s;\{])*)}
    # set markExpr {(^(package\s+[_\w:]+\s*;\s*\{*|BEGIN|END|[ \t]*sub\s+[_\w:]+(\s+\([$@%*;\\]+\))?\s*\{|=head1|=pod|__END__|__DATA__))}
    
    # cbu modified this some more to make it both Alpha and Alphatk
    # compatible.  (Alphatk can't seem to handle \w in searches ...)
    set markExpr {(^((package[_a-zA-Z0-9:;\t\{ ]+)|BEGIN|END|=head1|=pod|__END__|__DATA__|([\t ]*sub[\t ]+[_a-zA-Z0-9:'()$@%*;\t\{ ]+)))}
    if {$structuralMarks} {append markExpr {|(^[\t ]*###+ ([^#]+) ###+)}}
    set hasMarkers        0
    set inPackageSep      ""
    set allowIndentedSubs 0
    set pkgBlockEndPos [minPos]
    while {![catch {search -s -f 1 -r 1 -m 0 -i 0 $markExpr $pos} res]} {
	set start [lindex $res 0]
	set end   [lindex $res 1]
	set t     [eval getText $res]
	
	switch -regexp -- $t {
	    "^package" {
		regexp -- {^package\s+([_\w:]+)\s*;\s*(\{)*} $t all text blockBeg
		if {[info exists blockBeg] && [set blockBeg] != ""} {
		    #determine where "package block" ends
		    set pkgBlockEndPos [matchIt "\{" [pos::math $end + 1]]
		    #
		} 
		if {![info exists text]} {
		    set pos $end
		    continue
		} elseif {$structuralMarks} {
		    set text "$text ¥pkg"
		    set inPackageSep "::"
		} 		
	    }
	    "BEGIN" {
		set text "BEGIN"
	    } 			
	    "^END" {
		set text "END"
	    } 			
	    {sub\s+[_\w:]+;} {
		set pos $end
		continue
	    }
	    {^[ \t]+sub} {
		if {![info exists pkgBlockEndPos] || [pos::compare $start >= $pkgBlockEndPos]} {
		    set pos $end
		    continue
		} 
		regexp -- {^(([ \t]*)sub\s+)([\w_:]+)} $t all preNameText indent text
		if {![info exists text]} {
		    set pos $end
		    continue
		} elseif {$structuralMarks} {
		    set text "$inPackageSep$text"
		    set start [lineStart [pos::math $start + [string length $preNameText] + 1]]
		}
	    }
	    "^sub" {
		regexp -- {^(sub\s+)([\w_:']+)} $t all preNameText text
		if {![info exists text]} {
		    set pos $end
		    continue
		} elseif {$structuralMarks} {
		    set text "$inPackageSep$text"
		    set start [lineStart [pos::math $start + [string length $preNameText] + 1]]
		} 			
	    }
	    "###+" { 
		regexp -- {###+ ([^#]+) ###+} $t all text
		if {[regexp -- {^[-\t ]+$} $text]} {
		    set text "-"
		} elseif {[regexp -- {^[\t ]} $t]} {
		    set text "* $text"
		} else {
		    set text "¥ $text"
		} 	
		set hasMarkers 1
	    }
	    "=head1" -
	    "=pod" {
		set pos $end
		if {![catch {search -s -f 1 -r 1 -m 0 -i 0 "^=cut" $pos} res]} {
		    set start [lindex $res 0]
		    set end   [nextLineStart $start]
		    continue
		} else {
		    status::msg "*warning* - embeded pod with no cut encountered"
		    break
		} 
	    } 			
	    "__END__" -
	    "__DATA__" {
		break
	    } 			
	    "default" {
		unset -nocomplain text
		continue
	    } 			
	}
	set pos $end
	
	while {[lcontains marks $text]} {append text " "}
	lappend marks $text
	set arr inds
	set ${arr}($text) $start
	unset -nocomplain text
    }
    
    set already ""
    foreach arr {inds} {
	if {[info exists $arr]} {
	    if {$structuralMarks} {
		set order $marks
	    } else {
		set order [lsort -dictionary [array names $arr]]
	    }
	    foreach f $order {
		set el [set ${arr}($f)]
		set ff $f
		while {[lcontains already $ff]} {append ff " "}
		lappend already $ff
		if {$hasMarkers && ![regexp -- {^(\-|¥|\*)} $ff] } {
		    set ff "  $ff"
		} 
		setNamedMark $ff $el $el $el
	    }
	}
    }
    status::msg "'[win::CurrentTail]' has been marked."
}

proc Perl::parseFuncs {} {
    set end [maxPos]
    set pos [minPos]
    set l {}
    # set markExpr {^[\t ]*sub\s+[_\w:]+\s*\{}
    # cbu modified this some more to make it Alphatk compatible.
    set markExpr {^[\t ]*sub\s+[_a-zA-Z0-9':]+\s*\{}
    set appearanceList {}
    while {![catch {search -s -f 1 -r 1 -m 0 -i 0 $markExpr $pos} result]} {
	set start [lindex $result 0]
	set end   [lindex $result 1]
	set t     [eval getText $result]
	
	switch -regexp -- $t {
	    "sub" {
		regexp -- {^([\t ]*)sub\s+([_\w:']+)(\s+\(([$@%*;\\]+)\))?\s*\{} $t all indent subName argTypes
		set word $subName 
	    }
	}
	if {$argTypes != {}} {
	    set argLabel "$word$argTypes" 
	} else {
	    set argLabel $word
	} 
	if {[info exists cnts($word)]} {
	    # This section handles duplicate. i.e., overloaded names
	    incr cnts($word)
	    set tailOfTag($word) " (1 of $cnts($word))"
	} else {
	    #SO do: remember the following
	    set cnts($word) 1
	    # if this is the only occurence of this proc, remember where it starts
	    set indx($word) [lineStart [pos::math $start - 1]]
	}
	#associate name and tag
	set tag($word) $argLabel
	
	#advance pos to where we want to start the next search from
	set pos $end
    }
    
    set rtnRes {}
    
    if {[info exists indx]} {
	foreach hn [lsort -dictionary [array names indx]] {
	    set next [nextLineStart $indx($hn)]
	    set completeTag [set tag($hn)]
	    if {[info exists tailOfTag($hn)]} {
		append completeTag [ set tailOfTag($hn) ]
	    }
	    
	    lappend rtnRes $completeTag $next
	}
    }
    return $rtnRes 
}
# ×××× Initialize Perl Menu ×××× #

if {![alpha::tryToLoad "Initializing Perl" perlMenu.tcl {}]} {
    alertnote "Error: Not all of the mode files loaded"
}

# ===========================================================================
# 
# .