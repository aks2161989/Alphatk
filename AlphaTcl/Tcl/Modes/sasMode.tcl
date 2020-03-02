## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # Statistical Modes - an extension package for Alpha
 #
 # FILE: "sasMode.tcl"
 #                                          created: 01/15/2000 {07:15:32 pm}
 #                                      last update: 05/23/2006 {10:45:14 AM}
 # Description: 
 # 
 # For SAS syntax files.  SAS is not my statistical package of choice.
 # Anyone who has access to a newer manual should feel free to update the
 # list of keywords and send them along to me.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # Copyright (c) 2000-2006  Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

# ===========================================================================
#
# ×××× Initialization of SAS mode ×××× #
# 

alpha::mode SAS 2.3 sasMenu {
    *.sas
} {
    sasMenu
} {
    # Script to execute at Alpha startup
    addMenu sasMenu "SAS" SAS
    set unixMode(sas) {SAS}
    set modeCreator(SaS6) {SAS}
} uninstall {
    this-file
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} description {
    Supports the editing of SAS statistical batch files
} help {
    file "Statistical Modes Help"
}

hook::register quitHook SAS::quitHook

proc sasMode.tcl {} {}

namespace eval SAS {
    
    # Comment Character variables for Comment Line/Paragraph/Box menu items.
    variable commentCharacters
    array set commentCharacters [list \
      "General"         [list "*"] \
      "Paragraph"       [list "/* " " */" " * "] \
      "Box"             [list "/*" 2 "*/" 2 "*" 3] \
      ]
    # Set the list of flag preferences which can be changed in the menu.
    variable prefsInMenu [list \
      "localHelp" \
      "noHelpKey" \
      "fullIndent" \
      "(-)" \
      "autoMark" \
      "markHeadingsOnly" \
      ]
    
    # Used in [SAS::colorizeSAS].
    variable firstColorCall
    if {![info exists firstColorCall]} {
	set firstColorCall 1
    }
    
    # =======================================================================
    #
    # ×××× Keyword Dictionaries ×××× #
    #
    # Nomenclature notes:
    # 
    # SAS seems to have five levels of possible keywords.
    # 
    #   1. the top level "proc" specification:  anova, freq varcomp
    #   2. sub-level procs (or "subprocs"):  rename, value, range
    #   2. "arguments", which require no parameters:  ls, missover, in1
    #   3. "options", which require parameters:  converge, data, gamma
    #   4. "parameters", preset as opposed to user supplied: full, part  
    #
    # The default setup of this mode is to colorize all of procs and subprocs
    # blue; arguments, options, and parameters are magenta.  The user does
    # not have to specify all of these different levels -- only Argument,
    # Command, Comment, String, and Symbol colors appear in the preferences.
    # 
    # Of these four statistical packages, I am the most unfamiliar with SAS.
    # This mode is my good-hearted attempt, but is distributed with no
    # assurances that it is complete.
    # 
    
    variable keywordLists
    
    # =======================================================================
    #
    # SAS Commands
    #
    set keywordLists(commands) [list \
      aceclus anova calis cancorr candisc catmod cluster corresp discrim \
      factor fastclus format freq genmod glm glmmod inbreed kde krige2d \
      lattice lifereg lifetest loess logistic mds mixed modeclus multtest \
      nested nlin nlmixed npar1way orthoreg phreg plan pls princomp \
      prinqual probit proc reg rsreg score stepdisc surveymeans surveyreg \
      surveyselect tpspline transreg tree ttest varclus varcomp variogram \
      ]
    
    # =======================================================================
    #
    # SAS Subprocs
    #
    set keywordLists(subprocs) [list \
      arima array autoreg average axis1 axis2 by cards centroid choro class \
      col colblock colcopy collist colpct cols column columns complete \
      computab contents control data datasource density dftest do end \
      endogenous estimate exogenous filename fit footnote1 footnote2 \
      footnote3 footnote4 forecast form gmap goptions gplot id identify \
      infile input instruments keep label lagged last legend legend1 \
      legend2 length let libname macro merge model monthly options output \
      parms pattern1 pattern2 pattern3 pattern4 pattern5 pattern6 pattern7 \
      pattern8 plot print put quarterly quit range rename restrict retain \
      return row rowblock rowcopy rowlist rows run select set solve sort \
      sumby symbol symbol1 symbol2 symbol3 symbol3 symbol4 tables threshold \
      title title1 title2 title3 title4 value var weights where \
      ]
    
    # =======================================================================
    #
    # SAS Arguments
    #
    set keywordLists(arguments) [list \
      _col_ _row_ all b bcorr bcov bsscp bvreg c cback clogit clogits \
      colors corr corrb dbname device distance eof f garch gr2 h haxis hpos \
      href i in1 int intercept interval j joint l lead logit logits lrecl \
      ls lsd lspace map marginal marginals maxit maxiter mean means method \
      missover mpsprt mySAS nodesign nogls noint noiter noparm noprint \
      noprofile noresponse notrans noun obs oneway outall outby outcont \
      outest pcorr pcov pp printout proby psscp qq red redundancy regwf \
      regwq response s scjeffe seb short short shortanova sidak simple smc \
      smm snk spcorr sqpcorr sqspcorr stb stdmean survey t tcorr tcov trend \
      tsscp tukey type v vdep vpos w waller wcorr wcov wdep wsscp wteg \
      ]
    
    # =======================================================================
    #
    # SAS Options
    #
    set keywordLists(options) [list \
      absolute absorb archtest border converge crosscorr diagonal dif \
      dwprob filetype frame from identity initial intnx log manova maxiter \
      metric mulripass nlag nlags noconstant noobs noprint ourstat out \
      outfull outselect outstat overlay partial prefix rannor sing singular \
      to weight xlog \
      ]
    
    # =======================================================================
    #
    # SAS Parameters
    #
    set keywordLists(parameters) [list \
      absolute absorb and asmc average biweight centroid circle complete \
      converge density diagonal else eml epanechnikov equamax flexible \
      formatted full identity if if in initial internal join kj manova max \
      maxiter mcquitty median metric multipass needle no none normal npar \
      one orthmox ourstat out outstat p percent plus prefix procustes \
      promax proportion qtrvars quarimax random sing single singular smc \
      sorted special spline splines star test then triweight twostage \
      uniform varimax ward weight yes \
      ]
}

# ===========================================================================
#
# ×××× Setting SAS mode variables ×××× #
#

# ===========================================================================
#
# Standard preferences recognized by various Alpha procs
#

newPref var  fillColumn         {75}            SAS
newPref var  leftFillColumn     {0}             SAS
newPref var  prefixString       {* }            SAS
newPref var  wordBreak          {\w+}  SAS
newPref var  lineWrap           {0}             SAS
newPref var  commentsContinuation 1             SAS "" \
  [list "only at line start" "spaces allowed" "anywhere"] index

# To automatically perform context relevant formatting after typing a left
# or right curly brace, turn this item on||To have the brace keys produce a
# brace without additional formatting, turn this item off
newPref flag electricBraces    1 SAS
# To automatically perform context relevant formatting after typing a
# semicolon, turn this item on||To have the semicolon key produce a
# semicolon without additional formatting, turn this item off
newPref flag electricSemicolon 1 SAS
# To automatically indent the new line produced by pressing Return, turn
# this item on.  The indentation amount is determined by the context||To
# # have the Return key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn    1 SAS

# ===========================================================================
#
# Flag preferences
#

# To automatically mark files when they are opened, turn this item on||To
# disable the automatic marking of files when they are opened, turn this
# item off
newPref flag autoMark           {0}     SAS     {SAS::rebuildMenu markSasFileAs}
# To indent all continued commands (indicated by the lack of a semi-colon at
# the end of a line) by the full indentation amount rather than half, turn
# this item on|| To indent all continued commands (indicated by the lack of
# a semi-colon at the end of a line) by half of the indentation amount
# rather than the full, turn this item off
newPref flag fullIndent         {1}     SAS     {SAS::rebuildMenu markSasFileAs}
# To primarily use a www site for help rather than the local SAS
# application, turn this item on|| To primarily use the local SAS
# application for help rather than on a www site turn this item off
newPref flag localHelp          {0}     SAS     {SAS::rebuildMenu sasHelp}
# To only mark "headings" in windows (those preceded by ***), turn this item
# on||To mark both commands and headings in windows, turn this item off
newPref flag markHeadingsOnly   {0}     SAS     {SAS::postBuildMenu}
# If your keyboard does not have a "Help" key, turn this item on.  This will
# change some of the menu's key bindings|| If your keyboard has a "Help"
# key, turn this item off.  This will change some of the menu's key bindings
newPref flag noHelpKey          {0}     SAS     {SAS::rebuildMenu sasHelp}

# This isn't used yet.
prefs::deregister "localHelp" "SAS"

# ===========================================================================
#
# Variable preferences
# 

# Enter additional arguments to be colorized. 
newPref var addArguments        {}      SAS     {SAS::colorizeSAS}
# Enter additional SAS proc commands to be colorized.  
newPref var addCommands         {}      SAS     {SAS::colorizeSAS}
# Command double-clicking on a SAS keyword will send it to this url for a
# help reference page.
newPref url helpUrl             {}      SAS
# The "SAS Home Page" menu item will send this url to your browser.
newPref url sasHomePage         {http://www.sas.com/}   SAS
# Click on "Set" to find the local SAS application.
newPref sig sasSig              {SaS6}  SAS

# ===========================================================================
#
# Color preferences
#

# See the Statistical Modes Help file for an explanation of these different
# categories, and lists of keywords.
newPref color argumentColor     {magenta}   SAS     {SAS::colorizeSAS}
newPref color commandColor      {blue}      SAS     {SAS::colorizeSAS}
newPref color commentColor      {red}       SAS     {stringColorProc}
newPref color stringColor       {green}     SAS     {stringColorProc}

# The color of symbols such as "/", "@", etc.
newPref color symbolColor       {magenta}   SAS     {SAS::colorizeSAS}

# ===========================================================================
# 
# Categories of all SAS preferences, used by [prefs::dialogs::modePrefs].
# When the dialogues are actually built, there will most likely be added a
# Miscellaneous pane.  This happens whenever there are prefs which are not
# categorized.  (There's no need to set a "Miscellaneous" group entry,
# because this will always be unset.)
# 

# Editing
prefs::dialogs::setPaneLists "SAS" "Editing" [list \
  "autoMark" \
  "electricBraces" \
  "electricSemicolon" \
  "indentOnReturn" \
  "fillColumn" \
  "fullIndent" \
  "leftFillColumn" \
  "lineWrap" \
  "markHeadingsOnly" \
  "wordBreak" \
  ]

# Comments
prefs::dialogs::setPaneLists "SAS" "Comments" [list \
  "commentColor" \
  "commentsContinuation" \
  "prefixString" \
  ]

# Colors
prefs::dialogs::setPaneLists "SAS" "Colors" [list \
  "addArguments" \
  "addCommands" \
  "argumentColor" \
  "commandColor" \
  "stringColor" \
  "symbolColor" \
  ]

# Help
prefs::dialogs::setPaneLists "SAS" "SAS Help" [list \
  "helpUrl" \
  "localHelp" \
  "noHelpKey" \
  "sasHomePage" \
  "sasSig" \
  ]

## 
 # --------------------------------------------------------------------------
 # 
 # "SAS::colorizeSAS" --
 # 
 # Set all keyword lists, and colorize.
 # 
 # Could also be called in a <mode>Prefs.tcl file
 # 
 # --------------------------------------------------------------------------
 ##

proc SAS::colorizeSAS {{pref ""}} {
    
    global SASmodeVars SAScmds SASUserCommands SASUserArguments
    
    variable firstColorCall
    variable keywordLists
    
    set SAScmds [list]
    # Create the list of all keywords for completions.  SPSS keywords are not
    # case-sensitive.  To allow for different user styles, we'll include
    # lower case commands as well as ALL CAPS.  The "lowerKeywords" list 
    # will be used by the "SAS Mode Keywords > List Keywords" command.
    set keywordLists(lowerKeywords) [list]
    set keywordLists(allCommands)   [list]
    # SAS Procs and Subprocs
    foreach keyword $keywordLists(commands) {
	lappend SAScmds $keyword [string toupper $keyword]
	lappend keywordLists(lowerKeywords) [string tolower $keyword]
	lappend keywordLists(allCommands) $keyword [string toupper $keyword]
	
    }
    foreach keyword $keywordLists(subprocs) {
	lappend SAScmds $keyword [string toupper $keyword]
	lappend keywordLists(lowerKeywords) [string tolower $keyword]
	lappend keywordLists(allCommands) $keyword [string toupper $keyword]
    }
    foreach keyword $SASmodeVars(addCommands) {
	lappend SAScmds $keyword [string toupper $keyword]
	lappend keywordLists(lowerKeywords) [string tolower $keyword]
	lappend keywordLists(allCommands) $keyword [string toupper $keyword]
    }
    if {[info exists SASUserCommands]} {
	foreach keyword $SASUserCommands {
	    lappend SAScmds $keyword [string toupper $keyword]
	    lappend keywordLists(lowerKeywords) [string tolower $keyword]
	    lappend keywordLists(allCommands) $keyword [string toupper $keyword]
	}
    }
    # Arguments, Options, Parameters
    set arguments [list]
    foreach keyword $keywordLists(arguments) {
	lappend SAScmds $keyword [string toupper $keyword]
	lappend arguments $keyword [string toupper $keyword]
	lappend keywordLists(lowerKeywords) [string tolower $keyword]
    }
    foreach keyword $keywordLists(options) {
	lappend SAScmds $keyword [string toupper $keyword]
	lappend arguments $keyword [string toupper $keyword]
	lappend keywordLists(lowerKeywords) [string tolower $keyword]
    }
    foreach keyword $keywordLists(parameters) {
	lappend SAScmds $keyword [string toupper $keyword]
	lappend arguments $keyword [string toupper $keyword]
	lappend keywordLists(lowerKeywords) [string tolower $keyword]
    }
    foreach keyword $SASmodeVars(addArguments) {
	lappend SAScmds $keyword [string toupper $keyword]
	lappend arguments $keyword [string toupper $keyword]
	lappend keywordLists(lowerKeywords) [string tolower $keyword]
    }
    if {[info exists SASUserArguments]} {
	foreach keyword $SASUserArguments {
	    lappend SAScmds $keyword [string toupper $keyword]
	    lappend arguments $keyword [string toupper $keyword]
	    lappend keywordLists(lowerKeywords) [string tolower $keyword]
	}
    }
    # "SAScmds"
    set SAScmds [lsort -dictionary -unique $SAScmds]
    
    # Now we colorize keywords.  If this is the first call, we don't include 
    # the "-a" flag.
    if {$firstColorCall} {
	regModeKeywords SAS {}
	set firstColorCall 0
    }
    
    # Color comments and strings
    regModeKeywords -a -e {*} -b {/*} {*/} -c $SASmodeVars(commentColor) \
      -s $SASmodeVars(stringColor) SAS {}
    
    # Color Commands
    regModeKeywords -a -k $SASmodeVars(commandColor) SAS $SAScmds
    
    # Color Arguments, Options, Parameters
    regModeKeywords -a -k $SASmodeVars(argumentColor) SAS $arguments
    
    # Color Symbols
    regModeKeywords -a -i "+" -i "-" -i "\\" -i "|" \
      -I $SASmodeVars(symbolColor) SAS {}
    
    if {($pref ne "")} {
	refresh
    }
    return
}

# Call this now.
SAS::colorizeSAS

# ===========================================================================
#
# ×××× Key Bindings, Electrics ×××× #
# 
# abbreviations:  <o> = option, <z> = control, <s> = shift, <c> = command
# 

# Known bug: Key-bindings from other global menus might conflict with those
# defined in the SAS menu.  This will help ensure that this doesn't happen.

Bind '\)'           {SAS::electricRight "\)"} SAS

# For those that would rather use arrow keys to navigate.  Up and down
# arrow keys will advance to next/prev command, right and left will also
# set the cursor to the top of the window.

Bind    up  <sz>    {SAS::searchFunc 0 0 0} SAS
Bind  left  <sz>    {SAS::searchFunc 0 0 1} SAS
Bind  down  <sz>    {SAS::searchFunc 1 0 0} SAS
Bind right  <sz>    {SAS::searchFunc 1 0 1} SAS

## 
 # --------------------------------------------------------------------------
 # 
 # "SAS::electricSemi" --
 # 
 # Inserts a semi, carriage return, and indents properly.
 # 
 # --------------------------------------------------------------------------
 ##

proc SAS::electricSemi {} {
    
    if {[literalChar]} {
	typeText {;}
    } else {
	typeText {;}
	bind::CarriageReturn
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "SAS::carriageReturn" --
 # 
 # Inserts a carriage return, and indents properly.
 # 
 # --------------------------------------------------------------------------
 ##

proc SAS::carriageReturn {} {
    
    if {[isSelection]} {
	deleteSelection
    }
    set pos1 [lineStart [getPos]]
    set pos2 [getPos]
    if {[regexp {^([\t ])*(\}|\))} [getText $pos1 $pos2]]} {
	createTMark temp $pos2
	catch {bind::IndentLine}
	gotoTMark temp
	removeTMark temp
    }
    insertText "\r"
    catch {bind::IndentLine}
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "SAS::electricLeft" --
 # 
 # Adapted from "tclMode.tcl"
 # 
 # --------------------------------------------------------------------------
 ##

proc SAS::electricLeft {} {
    
    if {[literalChar]} {
	typeText "\{"
	return
    }
    set pat "\}\[ \t\r\n\]*(else(if)?)\[ \t\r\n\]*\$"
    set pos [getPos]
    if {([set result [findPatJustBefore "\}" $pat $pos word]] eq "")} {
	insertText "\{"
	return
    }
    # we have an if/else(if)/else
    switch -- $word {
	"else" {
	    deleteText [lindex $result 0] $pos
	    elec::Insertion "\} $word \{\r\t¥¥\r\}\r¥¥"
	}
	"elseif" {
	    deleteText [lindex $result 0] $pos
	    elec::Insertion "\} $word \{¥¥\} \{\r\t¥¥\r\}\r¥¥"
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "SAS::electricRight" --
 # 
 # Adapted from "tclMode.tcl"
 # 
 # --------------------------------------------------------------------------
 ##

proc SAS::electricRight {{char "\}"}} {
    
    if {[literalChar]} {
	typeText $char
	return
    }
    set pos [getPos]
    typeText $char
    if {![regexp {[^ \t]} [getText [lineStart $pos] $pos]]} {
	set pos [lineStart $pos]
	createTMark temp [getPos]
	catch {bind::IndentLine}
	gotoTMark temp
	removeTMark temp
	bind::CarriageReturn
    }
    if {[catch {blink [matchIt $char [pos::math $pos - 1]]}]} {
	beep
	status::msg "No matching $char !!"
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "SAS::CommentLine" --
 # "SAS::UncommentLine" --
 # 
 # An over-ride for the SystemCode [::CommentLine] procedure.
 # 
 # In the default routine, if the commentCharacters(Paragraph) are different
 # then [::CommentLine] will automatically be bracketed.  We just want to be
 # able to comment a single line without considering it to be a paragraph.
 # 
 # --------------------------------------------------------------------------
 ##

proc SAS::CommentLine {} {
    insertPrefix
    return
}

proc SAS::UncommentLine {} {
    removePrefix
    return
}

proc SAS::searchFunc {direction args} {
    
    if {![llength $args]} {
	set args [list 0 2]
    }
    if {$direction} {
	eval function::next $args
    } else {
	eval function::prev $args
    }
    return
}

# ===========================================================================
#
# ×××× Indentation ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "SAS::correctIndentation" --
 # 
 # [SAS::correctIndentation] is necessary for Smart Paste, and returns the
 # correct level of indentation for the current line.
 # 
 # We have two level of indentation in SAS, for the continuation of commands,
 # in which case we simply indent to the amount of the SAS mode variable
 # indentationAmount, and for nexted braces.
 # 
 # In [SAS::correctIndentation] we grab the previous non-commented line,
 # remove all of the characters besides braces and quotes, and then convert
 # it all to a list to be evaluated.  Braces contained within quotes, as well
 # as literal characters, should all be ignored and the remaining braces are
 # used to determine the correct level of nesting.
 # 
 # --------------------------------------------------------------------------
 ##

proc SAS::correctIndentation {args} {
    
    global SASmodeVars indentationAmount
    
    win::parseArgs w pos {next ""}
    
    if {([win::getMode $w] eq "SAS")} {
	set continueIndent [expr {$SASmodeVars(fullIndent) + 1}]
    } else {
	set continueIndent 2
    }
    
    set posBeg    [pos::lineStart -w $w $pos]
    # Get information about this line, previous line ...
    set thisLine  [SAS::getCommandLine -w $w $posBeg 1 1]
    set prevLine1 [SAS::getCommandLine -w $w \
      [pos::math -w $w $posBeg - 1] 0 1]
    set prevLine2 [SAS::getCommandLine -w $w \
      [pos::math -w $w [lindex $prevLine1 0] - 1] 0 1]
    set lwhite    [lindex $prevLine1 1]
    # If we have a previous line ...
    if {[pos::compare -w $w [lindex $prevLine1 0] != $posBeg]} {
	set pL1 [string trim [lindex $prevLine1 2]]
	# Indent if the last line did not terminate the command.
	if {![regexp {;[\t ]*$} $pL1]} {
	    incr lwhite [expr {$continueIndent * $indentationAmount/2}]
	}
	# Check to make sure that the previous command was not itself a
	# continuation of the line before it.
	if {[pos::compare -w $w [lindex $prevLine1 0] != [lindex $prevLine2 0]]} {
	    set pL2 [string trim [lindex $prevLine2 2]]
	    if {![regexp {;[\t ]*$} $pL2]} {
		incr lwhite [expr {-$continueIndent * $indentationAmount/2}]
	    }
	}
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
	# Now turn all braces into 1's and -1's
	regsub -all {\{|\(} $line { 1 }  line
	regsub -all {\}|\)} $line { -1 } line
	# This list should now only contain 1's and -1's.
	foreach i $line {
	    if {($i == "1") || ($i == "-1")} {
		incr lwhite [expr {$i * $indentationAmount}]
	    }
	}
	# Did the last line start with a lone \) or \} ?  If so, we want to
	# keep the indent, and not make call it an unbalanced line.
	if {[regexp {^[\t ]*(\}|\))} $pL1]} {
	    incr lwhite $indentationAmount
	}
    }
    # If we have a current line ...
    if {[pos::compare -w $w [lindex $thisLine 0] == $posBeg]} {
	# Reduce the indent if the first non-whitespace character of this
	# line is \) or \}.
	set tL [lindex $thisLine 2]
	if {($next eq "\}") || ($next eq "\)") \
	  || [regexp {^[\t ]*(\}|\))} $tL]} {
	    incr lwhite -$indentationAmount
	}
    }
    # Now we return the level to the calling proc.
    return [expr {$lwhite > 0 ? $lwhite : 0}]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "SAS::getCommandLine" --
 # 
 # Find the next/prev command line relative to a given position, and return
 # the position in which it starts, its indentation, and the complete text of
 # the command line.  If the search for the next/prev command fails, return
 # an indentation level of 0.
 # 
 # --------------------------------------------------------------------------
 ##

proc SAS::getCommandLine {args} {
    
    win::parseArgs w pos {direction 1} {ignoreComments 1}
    
    if {$ignoreComments} {
	set pat {^[\t ]*[^\t\r\n\*/ ]}
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
    } elseif {[pos::compare -w $w $posEnd < $posBeg]} {
	set posEnd $posBeg
    }
    return [list $posBeg $lwhite [getText -w $w $posBeg $posEnd]]
}

# ===========================================================================
# 
# ×××× Command Double Click ×××× #
#

## 
 # --------------------------------------------------------------------------
 # 
 # "SAS::DblClick" --
 # 
 # Checks to see if the highlighted word appears in any keyword list, and if
 # so, sends the selected word to the http://search.sas.com/ help site.
 # 
 # (Default preference is not the most useful site, but the best I could find.)
 #
 # Control-Command double click will insert syntax information in status bar.
 # Shift-Command double click will insert commented syntax information in
 # window.
 # 
 # (The above is not yet implemented: need to enter all of the syntax info.)
 # 
 # --------------------------------------------------------------------------
 ##

proc SAS::DblClick {from to shift option control} {
    
    global SASmodeVars SAScmds 
    
    variable syntaxMessages
    
    selectText $from $to
    set command [getSelect]
    
    if {![lcontains SAScmds $command]} {
	status::msg "'$command' is not defined as a SAS system keyword."
	return
    }
    # Defined as a keyword, determine if there's a syntax message.
    # Any modifiers pressed?
    if {$control} {
	# CONTROL -- Just put syntax message in status bar window
	if {[info exists syntaxMessages($command)]} {
	    status::msg $syntaxMessages($command)
	} else {
	    status::msg "Sorry, no syntax information available for $command"
	}
    } elseif {$shift} {
	# SHIFT --Just insert syntax message as commented text
	if {[info exists syntaxMessages($command)]} {
	    endOfLine
	    insertText "\r"
	    insertText "$syntaxMessages($command)"
	    comment::Line
	} else {
	    status::msg "Sorry, no syntax information available for $command"
	}
    } elseif {$option && !$SASmodeVars(localHelp)} {
	# Now we have four possibilities, based on "option" key and the
	# preference for "local Help Only".  (Local Help Only actually
	# switches the "normal" behavior of options versus not.)
	# 
	# OPTION, local help isn't checked -- Send command to local application
	SAS::localCommandHelp $command
    } elseif {$option && $SASmodeVars(localHelp)} {
	# OPTION, but local help is checked -- Send command for on-line help.
	SAS::wwwCommandHelp $command
    } elseif {$SASmodeVars(localHelp)} {
	# No modifiers, local help is checked -- Send command to local app.
	SAS::localCommandHelp $command
    } else {
	# No modifiers, no local help checked -- Send command for on-line
	# help.  This is the "default" behavior.
	SAS::wwwCommandHelp $command
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "SAS::wwwCommandHelp" --
 # 
 # Send command to defined url, prompting for text if necessary.
 # 
 # --------------------------------------------------------------------------
 ##

proc SAS::wwwCommandHelp {{command ""}} {
    
    global SASmodeVars
    
    if {($command eq "")} {
	if {[catch {prompt "On-line SAS help for É" ""} command]} {
	    error "cancel"
	}
    }
    status::msg "'$command' sent to $SASmodeVars(helpUrl)"
    urlView $SASmodeVars(helpUrl)$command
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "SAS::localCommandHelp" --
 # 
 # Send command to local application, prompting for text if necessary.
 # 
 # --------------------------------------------------------------------------
 ##

proc SAS::localCommandHelp {{command ""} {app "SAS"}} {
    
    # Need to work on this.
    SAS::betaMessage
    
    global SASmodeVars tcl_platform
    
    if {($command eq "")} {
	set command [prompt "local $app application help for ... " [getSelect]]
	# set command [statusPrompt "local $app application help for ..." ]
    }
    set pf $tcl_platform(platform)
    
    # We have three possible options here, based on platform.
    
    switch -- $tcl_platform(platform) {
	"macintosh" {
	    # Make sure that the Macintosh application for the signature
	    # actually exists.
	    if {[catch {nameFromAppl $SPSSmodeVars(${lowApp}Sig)}]} {
		alertnote "Looking for the $capApp application ..."
		SAS::setApplication $lowApp
	    }
	}
	"windows" - "unix" {
	    # Make sure that the Windows application for the signature
	    # exists.  We assume that this will work for unix, too.
	    if {![file exists $SPSSmodeVars(${lowApp}Sig)]} {
		alertnote "Looking for the $capApp application ..."
		SAS::setApplication $lowApp
	    }
	}
    }
    # Now we look for the actual help file.
    set helpFile "????"
    if {![file exists $helpFile]} {
	beep
	status::msg "Sorry, no help file for '$command' was found."
	error "No help file found for '$command'."
    } else {
	help::openFile $helpFile
    }
    return
}

# ===========================================================================
#
# ×××× Mark File and Parse Functions ×××× #
#

## 
 # --------------------------------------------------------------------------
 # 
 # "SAS::MarkFile" --
 # 
 # This will return the first 35 characters from the first non-commented word
 # that appears in column 0.  All other output files (those not recognized)
 # will take into account the additional left margin elements added by SAS.
 # 
 # --------------------------------------------------------------------------
 ##

proc SAS::MarkFile {args} {
    
    global SASmodeVars
    
    win::parseArgs w {type ""}
    
    status::msg "Marking \"[win::Tail $w]\" É"
    
    set pos [minPos -w $w]
    set count1 0
    set count2 0
    # Figure out what type of file this is -- source, or output.
    # The variable "type" refers to a call from the SAS menu.
    # Otherwise we try to figure out the type based on the file's suffix.
    if {($type eq "")} {
	if {([win::Tail $w] eq "* SAS Mode Example *")} {
	    # Special case for Mode Examples, but only if called from Marks
	    # menu.  (Called from SAS menu, "type" will over-ride.)
	    set type  ".sas"
	} else {
	    set type [file extension [win::Tail $w]]
	}
    }
    # Now set the mark regexp.
    if {($type eq ".sas")} {
	# Source file.
	if {!$SASmodeVars(markHeadingsOnly)} {
	    set markExpr {^(\*\*\*[ ]|\*\*\*\*[ ])?[a-zA-Z0-9]}
	} else {
	    set markExpr {^\*\*\*\**[\t ][^\r\n\t ]}
	}
    } else {
	# None of the above, so assume that it's output
	set markExpr {^([0-9]+((        )|(         )))+(\*\*\*[ ]|\*\*\*\*[ ])?[a-zA-Z0-9]}
    }
    # Mark the file
    while {![catch {search -w $w -s -f 1 -r 1 -m 0 -i 1 $markExpr $pos} match]} {
	set pos0 [lindex $match 0]
	set pos1 [pos::nextLineStart -w $w $pos0]
	set mark [string trimright [getText -w $w $pos0 $pos1]]
	# Get rid of the leading "[0-9]  " for output files
	regsub {^[0-9]*[0-9]*[0-9]*[0-9]} $mark {} mark
	# Add a little indentation so that section marks show up better
	set mark "  [string trimleft $mark " "]"
	if {[regexp -- {^\s*\*+\s*-+\s*$} $mark]} {
	    set mark "-"
	} elseif {[regsub {  \*\*\*\* } $mark {* } mark]} {
	    incr count2
	} elseif {[regsub {  \*\*\* } $mark {¥ } mark]} {
	    incr count2
	} else {
	    incr count1
	}
	# Get rid of trailing sem-colons, and truncate if necessary.
	set mark [markTrim [string trimright $mark ";" ]]
	while {[lcontains marks $mark]} {
	    append mark " "
	}
	lappend marks $mark
	# If the mark starts with "run", ignore it.
	if {![regexp {^  (run|RUN)} $mark]} {
	    setNamedMark -w $w $mark $pos0 $pos0 $pos0
	}
	set pos $pos1
    }
    # Report how many marks we created.
    if {!$SASmodeVars(markHeadingsOnly)} {
	set msg "The window \"[win::Tail $w]\" contains $count1 command"
	append msg [expr {($count1 == 1) ? "." : "s."}]
    } else {
	set msg "The window \"[win::Tail $w]\" contains $count2 heading"
	append msg [expr {($count2 == 1) ? "." : "s."}]
    }
    status::msg $msg
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "SAS::parseFuncs" --
 # 
 # This will return only the SAS command names.
 # 
 # --------------------------------------------------------------------------
 ##

proc SAS::parseFuncs {} {
    
    global sortFuncsMenu
    
    set pos [minPos]
    set m   [list]
    while {![catch {search -s -f 1 -r 1 -i 0 {^(\w+)} $pos} match]} {
	if {[regexp -- {^(\w+)} [eval getText $match] "" word]} {
	    lappend m [list $word [lindex $match 0]]
	}
	set pos [lindex $match 1]
    }
    if {$sortFuncsMenu} {
	set m [lsort -dictionary $m]
    }
    return [join $m]
}

# ===========================================================================
# 
# ×××× -------------------- ×××× #
# 
# ×××× SAS Menu ×××× #
# 

proc sasMenu {} {}

# Tell Alpha what procedures to use to build all menus, submenus.

menu::buildProc sasMenu SAS::buildMenu     SAS::postBuildMenu
menu::buildProc sasHelp SAS::buildHelpMenu

# First build the main SAS menu.

proc SAS::buildMenu {} {
    
    global sasMenu 
    
    variable prefsInMenu
    
    set optionItems $prefsInMenu
    set keywordItems [list \
      "listKeywords" "checkKeywordsÉ" "addNewCommandsÉ" "addNewArgumentsÉ"]
    set markItems [list "source" "output"]
    
    set menuList [list \
      "sasHomePage" \
      "switchToSas" \
      "/P<U<OprocessFile" \
      "/P<U<O<BprocessSelection" \
      "(-)" \
      [list Menu -n sasHelp           -M SAS {}] \
      [list Menu -n sasModeOptions -p SAS::menuProc -M SAS $optionItems] \
      [list Menu -n sasKeywords    -p SAS::menuProc -M SAS $keywordItems] \
      [list Menu -n markSasFileAs  -p SAS::menuProc -M SAS $markItems] \
      "(-)" \
      "/'<E<S<BnewComment" \
      "/'<S<O<BcommentTemplateÉ" \
      "(-)" \
      "/N<U<BnextCommand" \
      "/P<U<BprevCommand" \
      "/S<U<BselectCommand" \
      "/I<B<OreformatCommand" \
      ]
    set submenus [list sasHelp]
    return       [list build $menuList "SAS::menuProc -M SAS" $submenus $sasMenu]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "SAS::buildHelpMenu" --
 # 
 # Build the "Scheme Help" menu.  We leave out these items:
 # 
 #   "${key}<IlocalMacroHelpÉ"
 #   "${key}<OlocalMacroHelpÉ"
 # 
 # until they are properly implemented.
 # 
 # --------------------------------------------------------------------------
 ##

proc SAS::buildHelpMenu {} {
    
    global SASmodeVars
    
    # Determine which key should be used for "Help", with F8 as option.
    if {!$SASmodeVars(noHelpKey)} {
	set key "/t"
    } else {
	set key "/l"
    }
    set menuList [list "${key}<OwwwCommandHelpÉ" "setSasApplicationÉ" \
      "${key}<BsasModeHelp"]
    
    return [list build $menuList "SAS::menuProc -M SAS" {}]
}

proc SAS::rebuildMenu {{menuName "sasMenu"} {pref ""}} {
    menu::buildSome $menuName
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "SAS::postBuildMenu" --
 # 
 # Mark or dim items as necessary.
 # 
 # --------------------------------------------------------------------------
 ##

proc SAS::postBuildMenu {args} {
    
    global SASmodeVars 
    
    variable prefsInMenu
    
    foreach itemName $prefsInMenu {
	if {[info exists SASmodeVars($itemName)]} {
	    markMenuItem sasModeOptions $itemName $SASmodeVars($itemName) Ã
	}
    }
    return
}

# Now we actually build the SAS menu.
menu::buildSome sasMenu

## 
 # --------------------------------------------------------------------------
 # 
 # "SAS::registerOWH" --
 # 
 # Dim some menu items when there are no open windows.
 # 
 # --------------------------------------------------------------------------
 ##

proc SAS::registerOWH {{which "register"}} {
    
    global sasMenu
    
    set menuItems {
	processFile processSelection
	markSasFileAs newComment commentTemplateÉ
	nextCommand prevCommand selectCommand reformatCommand
    }
    foreach i $menuItems {
	hook::${which} requireOpenWindowsHook [list $sasMenu $i] 1
    }
    return
}

# Call this now.
SAS::registerOWH register
rename SAS::registerOWH ""

# ===========================================================================
# 
# ×××× SAS menu support ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "SAS::menuProc" --
 # 
 # This is the procedure called for all main menu items.
 # 
 # --------------------------------------------------------------------------
 ##

proc SAS::menuProc {menuName itemName} {
    
    global SAScmds SASmodeVars mode
    
    variable keywordLists
    variable prefsInMenu
    
    switch $menuName {
	"sasHelp" {
	    switch $itemName {
		"setSasApplication" {SAS::setApplication "SAS"}
		"sasModeHelp"       {package::helpWindow "SAS"}
		default             {SAS::$itemName}
	    }
	}
	"sasModeOptions" {
	    if {[getModifiers]} {
		set helpText [help::prefString $itemName "SAS"]
		if {$SASmodeVars($itemName)} {
		    set end "on"
		} else {
		    set end "off"
		}
		if {($end eq "on")} {
		    regsub {^.*\|\|} $helpText {} helpText
		} else {
		    regsub {\|\|.*$} $helpText {} helpText
		}
		set msg "The '$itemName' preference for SAS mode is currently $end."
		dialog::alert "${helpText}."
	    } elseif {[lcontains prefsInMenu $itemName]} {
		set SASmodeVars($itemName) [expr {$SASmodeVars($itemName) ? 0 : 1}]
		if {($mode eq "SAS")} {
		    synchroniseModeVar $itemName $SASmodeVars($itemName)
		} else {
		    prefs::modified $SASmodeVars($itemName)
		}
		if {[regexp {Help} $itemName]} {SAS::rebuildMenu "sasHelp"}
		SAS::postBuildMenu
		if {$SASmodeVars($itemName)} {
		    set end "on"
		} else {
		    set end "off"
		}
		set msg "The '$itemName' preference is now $end."
	    } else {
		error "Cancelled -- don't know what to do with '$itemName'."
	    }
	    if {[info exists msg]} {
		status::msg $msg
	    }
	}
	"sasKeywords" {
	    if {($itemName eq "listKeywords")} {
		set p "Current SAS mode keywordsÉ"
		set keywords [listpick -l -p $p $keywordLists(lowerCaseCmds)]
		foreach keyword $keywords {SAS::checkKeywords $keyword}
	    } elseif {($itemName eq "addNewCommands") || ($itemName eq "addNewArguments")} {
		set itemName [string trimleft $itemName "addNew"]
		if {($itemName eq "Commands") && [llength [winNames]] && [askyesno \
		  "Would you like to add all of the 'extra' commands from this window\
		  to the 'Add Commands' preference?"]} {
		    SAS::addWindowCommands
		} else {
		    SAS::addKeywords $itemName
		}
	    } else {
		SAS::$itemName
	    }
	    return
	}
	"markSasFileAs" {
	    removeAllMarks
	    switch $itemName {
		"source"    {SAS::MarkFile ".sas"}
		"output"    {SAS::MarkFile ".out"}
	    }
	}
	default {
	    switch $itemName {
		"sasHomePage"     {url::execute $SASmodeVars(sasHomePage)}
		"switchToSas"     {app::launchFore $SASmodeVars(sasSig)}
		"newComment"      {comment::newComment 0}
		"commentTemplate" {comment::commentTemplate}
		"nextCommand"     {function::next}
		"prevCommand"     {function::prev}
		"selectCommand"   {function::select}
		"reformatCommand" {function::reformat}
		default           {SAS::$itemName}
	    }
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "SAS::betaMessage" --
 # 
 # Give a beta message for untested features / menu items.
 # 
 # --------------------------------------------------------------------------
 ##

proc SAS::betaMessage {{item ""}} {
    
    if {($item eq "")} {
	if {[catch {info level -1} item]} {
	    set item "this item"
	}
    }
    error "Cancelled -- '$item' has not been implemented yet."
}

## 
 # --------------------------------------------------------------------------
 # 
 # "SAS::getSig" --
 # 
 # Return the SAS signature.
 # 
 # --------------------------------------------------------------------------
 ##

proc SAS::getSig {{app "SAS"}} {
    
    global SASmodeVars
    
    set lowApp [string tolower $app]
    set capApp [string toupper $app]
    if {($SASmodeVars(${lowApp}Sig) eq "")} {
	alertnote "Looking for the $capApp application ..."
	SAS::setApplication $lowApp
    }
    return $SASmodeVars(${lowApp}Sig)
}

## 
 # --------------------------------------------------------------------------
 # 
 # "SAS::setApplication" --
 # 
 # Prompt the user to locate the local SAS application.
 # 
 # --------------------------------------------------------------------------
 ##

proc SAS::setApplication {{app "SAS"}} {
    
    global mode SASmodeVars
    
    set lowApp [string tolower $app]
    set capApp [string toupper $app]
    
    set newSig ""
    set newSig [dialog::askFindApp $capApp $SASmodeVars(${lowApp}Sig)]
    
    if {($newSig ne "")} {
	mode::setVar SAS ${lowApp}Sig $newSig
	status::msg "The $capApp signature has been changed to '$newSig'."
    } else {
	error "cancel"
    }
    return
}

# ===========================================================================
# 
# ×××× Keywords ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "SAS::addWindowCommands" --
 # 
 # Add all of the "extra" commands which appear in entries in this window.
 # 
 # --------------------------------------------------------------------------
 ##

proc SAS::addWindowCommands {} {
    
    global SAScmds SASmodeVars
    
    if {![llength [winNames]]} {
	status::msg "Cancelled -- no current window!"
	return
    }
    
    status::msg "Scanning [win::CurrentTail] for all commandsÉ"
    
    set pos [minPos]
    set pat {^([a-zA-Z0-9]+[a-zA-Z0-9])+[\t ]}
    while {![catch {search -s -f 1 -r 1 $pat $pos} match]} {
	set pos [nextLineStart [lindex $match 1]]
	set commandLine [getText [lindex $match 0] [lindex $match 1]]
	regexp $pat $commandLine match aCommand
	set aCommand [string tolower $aCommand]
	if {![lcontains SAScmds $aCommand]} {
	    append SASmodeVars(addCommands) " $aCommand"
	}
    }
    set SASmodeVars(addCommands) [lsort -unique $SASmodeVars(addCommands)]
    prefs::modified SASmodeVars(addCommands)
    if {[llength $SASmodeVars(addCommands)]} {
	SAS::colorizeSAS
	listpick -p "The 'Add Commands' preference includes:" \
	  $SASmodeVars(addCommands)
	status::msg "Use the 'Mode Prefs -> Preferences' menu item to edit keyword lists."
    } else {
	status::msg "No 'extra' commands from this window were found."
    }
    return
}

proc SAS::addKeywords {{category} {keywords ""}} {
    
    global SASmodeVars
    
    if {($keywords eq "")} {
	set keywords [prompt "Enter new SAS $category:" ""]
    }
    
    # The list of keywords should all be lower case.
    set keywords [string tolower $keywords]
    # Check to see if the keyword is already defined.
    foreach keyword $keywords {
	set checkStatus [Lisp::checkKeywords $keyword 1 0]
	if {($checkStatus != "0")} {
	    alertnote "Sorry, '$keyword' is already defined\
	      in the $checkStatus list."
	    error "cancel"
	}
    }
    # Keywords are all new, so add them to the appropriate mode preference.
    append SASmodeVars(add$category) " $keywords"
    set SASmodeVars(add$category) [lsort $SASmodeVars(add$category)]
    prefs::modified SASmodeVars(add$category)
    SAS::colorizeSAS
    status::msg "'$keywords' added to $category preference."
    return
}

proc SAS::checkKeywords {{newKeywordList ""} {quietly 0} {noPrefs 0}} {
    
    global SASmodeVars SASUserCommands SASUserArguments
    
    variable keywordLists
    
    set type 0
    if {($newKeywordList eq "")} {
	set quietly 0
	set newKeywordList [prompt "Enter SAS mode keywords to be checked:" ""]
    }
    # Check to see if the new keyword(s) is already defined.
    foreach newKeyword $newKeywordList {
	if {[lcontains keywordLists(commands) $newKeyword]} {
	    set type "default commands"
	} elseif {[lcontains SASUserCommands $newKeyword]} {
	    set type "\$SASUserCommands"
	} elseif {[lcontains keywordLists(subprocs) $newKeyword]} {
	    set type "default subprocs"
	} elseif {[lcontains keywordLists(options) $newKeyword]} {
	    set type "default arguments"
	} elseif {[lcontains SASUserArguments $newKeyword]} {
	    set type "\$SASUserArguments"
	} elseif {[lcontains keywordLists(options) $newKeyword]} {
	    set type "default options"
	} elseif {[lcontains keywordLists(parameters) $newKeyword]} {
	    set type "default parameters"
	} elseif {!$noPrefs \
	  && [lcontains SASmodeVars(addCommands) $newKeyword]} {
	    set type "Add Commands Preference"
	} elseif {!$noPrefs \
	  && [lcontains SASmodeVars(addArguments) $newKeyword]} {
	    set type "Add Arguments Preference"
	}
	if {$quietly} {
	    # When this is called from other code, it should only contain
	    # one keyword to be checked, and we'll return it's type.
	    return "$type"
	} elseif {!$quietly && ($type eq 0)} {
	    alertnote "'$newKeyword' is not currently defined\
	      as a SAS mode keyword"
	} elseif {($type ne 0)} {
	    # This will work for any other value for "quietly", such as "2"
	    alertnote "'$newKeyword' is currently defined as a keyword\
	      in the '$type' list."
	}
	set type 0
    }
    return
}

# ===========================================================================
# 
# ×××× Processing ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "SAS::processFile" --
 # 
 # Send entire file to SAS for processing, adding carriage return at end
 # of file if necessary.
 # 
 # Optional "f" argument allows this to be called by other code, or to be 
 # sent via a Tcl shell window.
 # 
 # --------------------------------------------------------------------------
 ##

proc SAS::processFile {{f ""} {app "SAS"}} {
    
    if {($f ne "")} {
	file::openAny $f
    }
    set f [win::Current]
    
    set dirtyWindow [winDirty]
    set dontSave 0
    if {$dirtyWindow && [askyesno \
      "Do you want to save the file before sending it to SAS?"]} {
	save
    } else {
	set dontSave 1
    }
    if {!$dontSave && ([lookAt [pos::math [maxPos] - 1]] ne "\r")} {
	set pos [getPos]
	goto [maxPos]
	insertText "\r"
	goto $pos
	alertnote "Carriage return added to end of file."
	save
    }
    
    app::launchBack '[SAS::getSig]'
    sendOpenEvent noReply '[SAS::getSig]' $f
    switchTo '[SAS::getSig]'
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "SAS::processSelection" --
 # 
 # Procedure to implement transfer of selected lines to SAS for processing.
 # 
 # --------------------------------------------------------------------------
 ##

proc SAS::processSelection {{selection ""} {app "SAS"}} {
    
    if {($selection eq "")} {
	if {![isSelection]} {
	    status::msg "No selection -- cancelled."
	    return
	} else {
	    set selection [getSelect]
	}
    }
    set tempDir [temp::directory SAS]
    set newFile [file join $tempDir temp-SAS.sas]
    file::writeAll $newFile $selection 1
    
    app::launchBack '[SAS::getSig]'
    sendOpenEvent noReply '[SAS::getSig]' $newFile
    switchTo '[SAS::getSig]'
    return
}

proc SAS::quitHook {} {
    temp::cleanup SAS
    return
}

# ===========================================================================
# 
# ×××× --------------------- ×××× #
# 
# ×××× Version History ×××× #
# 
# modified by  vers#  reason
# -------- --- ------ -----------
# 01/28/20 cbu 1.0.1  First created sas mode, based upon other modes found 
#                       in Alpha's distribution.  Commands are based on 
#                       version 2.0.1 of SAS.
# 03/02/20 cbu 1.0.2  Minor modifications to comment handling.
# 03/20/00 cbu 1.0.3  Minor update of keywords dictionaries.
#                     Renamed mode SAS, from sas 
# 04/01/00 cbu 1.0.4  Fixed a little bug with "comment box".
#                     Added new preferences to allow the user to enter 
#                       additional commands and options.  
#                     Reduced the number of different user-specified colors.
#                     Added "Update Colors" proc to avoid need for a restart
# 04/08/00 cbu 1.0.5  Unset obsolete preferences from earlier versions.
#                     Modified "Electric Semi" added "Continue Comment" and
#                       "Electric Return Over-ride".
#                     Renamed "Update Colors" to "Update Preferences".
# 04/16/00 cbu 1.1    Renamed to sasMode.tcl
#                     Added "Mark File" and "Parse Functions" procs.
# 06/22/00 cbu 1.2    "Mark File" now recognizes headings as well as commands.
#                     "Mark File" recognizes source or output files.
#                     Completions, Completions Tutorial added.
#                     "Reload Completions", referenced by "Update Preferences".
#                     Better support for user defined keywords.
#                     Removed "Continue Comment", now global in Alpha 7.4.
#                     Added command double-click for on-line help.
#                     <shift, control>-<command> double-click syntax info.
#                       (Foundations, at least.  Ongoing project.)
# 06/22/00 cbu 1.2.1  "Mark File"ignores "run" commands.
#                     Minor keywords update.
#                     Beta-version of a SAS menu, based on the Stata menu.
#                     Added "sasSig" preference to allow user to find
#                       local application if necessary.
#                     Added SAS::sig which returns SAS signature.
# 08/28/00 cbu 1.2.2  Added some of the flag preferences to "SAS Help" menu.
#                     Added "flagFlip" to update preference bullets in menu.
#                     Added a "noHelpKey" preference, which switches the
#                       "help" key binding to F8.
#                     Added "Add New Commands / Arguments" to "SAS Help" menu.
#                     Added "Set SAS Application to "SAS Help" menu.
# 11/05/00 cbu 1.3    Added "next/prevCommand", "selectCommand", and
#                       "copyCommand" procs to menu.
#                     Added "SAS::indentLine".
#                     Added "SAS::reformatCommand" to menu.
#                     "SAS::reloadCompletions" is now obsolete.
#                     "SAS::updatePreferences" is now obsolete.
#                     "SAS::colorizeSAS" now takes care of setting all 
#                       keyword lists, including SAScmds.
#                     Cleaned up completion procs.  This file never has to be
#                       reloaded.  (Similar cleaning up for "SAS::DblClick").
# 11/16/00 cbu 2.0    New url prefs handling requires 7.4b21
#                     Added "Home Page" pref, menu item.
#                     Removed  hook::register requireOpenWindowsHook from
#                       mode declaration, put it after menu build.
# 12/19/00 cbu 2.1    The menu proc "Add Commands" now includes an option
#                       to grab all of the "extra" command from the current
#                       window, using SAS::addWindowCommands.
#                     Added "Keywords" submenu, "List Keywords" menu item.
#                     Big cleanup of ::sig, ::setApplication, processing ...
# 01/25/01 cbu 2.1.1  Bug fix for SAS::processSelection/File.
#                     Bug fix for comment characters.
# 09/26/01 cbu 2.2    Big cleanup, enabled by new 'functions.tcl' procs.
# 10/31/01 cbu 2.2.1  Minor bug fixes.
# 10/18/05 cbu 2.3    Keywords lists are defined in SAS namespace variables.
#                     Canonical Tcl formatting changes.
#                     Using [prefs::dialogs::setPaneLists] for preferences.
#                     New "markHeadingsOnly" preference.
#                     Disabled unimplemented features (finally).
#

# ===========================================================================
# 
# .