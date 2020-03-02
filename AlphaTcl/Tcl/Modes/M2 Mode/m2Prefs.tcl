# to autoload this file (tabsize:8)
proc m2Prefs.tcl {} {}

namespace eval M2 {}

#===========================================================================
# ×××× M2 Preferences ×××× #
#===========================================================================


# Avoid premature early line break while typing, especially for long strings
proc M2::setLnBreakBehavior {M2MaxLineLength} {
    global fillColumn
    global wrapLow
    global wrapHigh
    global M2modeVars
    global m2_maxLnLeTol
    if {[info exists M2MaxLineLength]} then {
	# make it immediately available (without requiring a mode switch)
	set fillColumn "$M2MaxLineLength"
	set wrapLow    "[expr $M2MaxLineLength -5]"
	set wrapHigh   "[expr $M2MaxLineLength +5]"
	# Still needs to set M2modeVars(wrapLow), M2modeVars(wrapHigh), and M2modeVars(fillColumn)?
	if {[info exists M2modeVars]} then {
	    set M2modeVars(m2_maxLineLength)	"$M2MaxLineLength"
	    # make final values immediately available (without requiring a mode switch)
	    set wrapLow    "[expr $M2MaxLineLength -$M2modeVars(m2_maxLnLeTol)]"
	    set wrapHigh   "[expr $M2MaxLineLength +$M2modeVars(m2_maxLnLeTol)]"
	}	
    }		
}



# The following "unconventional" assignments to M2modeVars are made to support pre 7 Alpha usage
# AND to search for Modula-2 shells on the current computer system. Their normal functioning 
# depends on the Mac specific signature (creator) of Modula-2 shells, i.e. 'ETHM' and 'RAMS'.
# On other systems this behavior should cause no havoc, i.e. result only in a somewhat less 
# convenient functioning of the M2 mode.
if {[info exists M2ShellName]} then {
    set M2modeVars(m2_shellName) $M2ShellName
} else {
    # Try looking at the desktop data base, giving RAMSES higher priority than MacMETH shell
    # The following code, i.e. going to the parent directory by 2 file separators preceeding
    # the path is Mac specific and not portable to other platforms. Since the success of
    # these routines depends anyway on Mac specific features (Modula-2 shell signatures),
    # this is not a big issue here.
    set M2ShellName "[file join ""][file join "RMS" " RAMSES Shell"]"
    if { [catch {nameFromAppl 'RAMS'}] } then {
	# alertnote "look for RAMS failed"
	if { [catch {nameFromAppl 'ETHM'}] } then {
	    # alertnote "No Modula-2 shells found" 
	    set M2modeVars(m2_shellName) ""
	} else {
	    # alertnote "At least MacMETH found"
	    set M2modeVars(m2_shellName) "[file join [file dirname [nameFromAppl 'ETHM']] " MacMETH"]"
	    set M2ShellName $M2modeVars(m2_shellName)
	}
    } else {
	# alertnote "RAMS found" 
	set M2modeVars(m2_shellName) "[file join [file dirname [nameFromAppl 'RAMS']] " RAMSES Shell"]"
	set M2ShellName $M2modeVars(m2_shellName)
    }
}

if {[info exists M2errDOKFile]} then {
    set M2modeVars(m2_errListDOK) $M2errDOKFile
} else {
    set M2modeVars(m2_errListDOK) "[file join [file dirname $M2modeVars(m2_shellName)] "M2Tools" "ErrList.DOK"]"
    set M2errDOKFile $M2modeVars(m2_errListDOK)
}

if {![info exists M2ShellHome]} then {
    set M2ShellHome [file dirname $M2ShellName]
}

if {![info exists M2ErrFile]} then {
    set M2ErrFile [file join $M2ShellHome err.ALPHA]
}


if {[info exists M2Author]} then {
    set M2modeVars(m2_author) $M2Author
} else {
    if {[info exists M2modeVars(m2_author)]} then {
	set M2Author $M2modeVars(m2_author)
    } else {
	set M2Author "FirstName LastName"
    }
}

if {[info exists M2RightShift]} then {
    set M2modeVars(m2_indentAmount) $M2RightShift
} else {
    if {[info exists M2modeVars(m2_indentAmount)]} then {
	set M2RightShift $M2modeVars(m2_indentAmount)
    } else {
	set M2RightShift "  "
    }
}
# possible alternative: set M2modeVars(m2_indentAmount) $indentationAmount

if {[info exists M2LeftShift]} then {
    set M2modeVars(m2_leftShiftAmount) $M2LeftShift
} else {
    if {[info exists M2modeVars(m2_leftShiftAmount)]} then {
	set M2LeftShift $M2modeVars(m2_leftShiftAmount)
    } else {
	set M2LeftShift " "
    }
}
if {[info exists M2WrapRightMargin]} then {
    set M2modeVars(m2_fillRightMargin) $M2WrapRightMargin
} else {
    if {[info exists M2modeVars(m2_fillRightMargin)]} then {
	set M2WrapRightMargin $M2modeVars(m2_fillRightMargin)
    } else {
	set M2WrapRightMargin "65"
    }
}


# The only M2 variable maintained only as a simple newPref var (only new mechanism)
set M2modeVars(m2_maxLnLeTol)               {5}
set M2modeVars(m2_maxLineLength)			{120}
if {[info exists M2MaxLineLength]} then {
    M2::setLnBreakBehavior $M2MaxLineLength
} else {
    if {[info exists M2modeVars(m2_maxLineLength)]} then {
	set M2MaxLineLength $M2modeVars(m2_maxLineLength)
    } else {
	set M2MaxLineLength 120
    }
}

if {[info exists M2SaveState]} then {
    set M2modeVars(m2_savedState) $M2SaveState
} else {
    if {[info exists M2modeVars(m2_savedState)]} then {
	set M2SaveState $M2modeVars(m2_savedState)
    } else {
	set M2SaveState "mpw"
    }
}


set M2modeVars(wordBreak)		{\w+}
set M2modeVars(funcExpr)		{^[ \t]*PROCEDURE[ \t]*([^\s;(]+)}
set M2modeVars(prefixString)		{(* }
set M2modeVars(suffixString)		{ *)}
# set M2modeVars(tagFile)			"$HOME:m2TAGS"
 

# To automatically mark Modula-2 files on open, turn this item on. 
# Automatic marking takes place only if the file is not already marked||
# To avoid any changes to Modula-2 files you open, turn this item off
newPref flag autoMark	                {0} M2 

# To make M-button recognize main structural marks, turn this item on.
# Such structural marks are created by selecting some text and pressing CTRL-3.
# The M-button resembles a paper clip and can be found near the top right border of a window||
# To make M-button ignore main structural marks, turn this item off
newPref flag listMainStructuralMarks    {1} M2

# To make M-button recognize subsection structural marks, turn this item on.
# Such structural marks are created by selecting some text and pressing CTRL-4.
# Subsection structural marks are shown nested within main marks.
# The M-button resembles a paper clip and can be found near the top right border of a window||
# To make M-button ignore subsection structural marks, turn this item off
newPref flag listSectionStructuralMarks {1} M2

# To make M-button list MODULEs, including local ones, turn this item on||
# To make the M-button ignore modules, turn this item off
newPref flag listModules                {1} M2

# To make M-button list PROCEDUREs, turn this item on||
# To make the M-button ignore procedures, turn this item off
newPref flag listProcedures             {1} M2

# To format subsection structural marks with a box, turn this item on||
# To format subsection structural marks without a box, turn this item off
newPref flag boxedSectionMarks          {1} M2

# To make M-button list items in alphabetically sorted order, turn this item on||
# To make M-button list items in order of occurrence, turn this item off.
# Since the curly braces button offers already a sorted list,
# it is recommended to have this item normally turned off
newPref flag sortListedItems            {0} M2

# To have M-button ignore module and procedure declarations within comments, turn this item on|| 
# To have M-button to list module and procedure declarations within comments together with
# all other procedures, turn this item off. In general it is recommended to turn this item off,
# since its success often depends on the actual comment. For instance it fails if
# a comment contains non-matching paranthesis
newPref flag markSeesComments           {0} M2

# To trigger electric completions upon typing a blank after a reserved word, turn this item on.
# Note, to make use of this feature, reserved words need to be typed with capitals.
# E.g. 'IF<blank>' triggers 'IF THEN ELSE END(*IF*);'||
# To never trigger an electric completion by a blank, turn this item off
newPref f spaceBarExpansion         {1} M2 M2::adjustM2Prefs

# To use key 1 on the numeric keypad to trigger electric completions, turn this item on. 
# This key is particularly convenient on PowerBook keyboards (fn-J where fn = function key). 
# It works only if NLCK (NumLoCK) in the status bar is turned off (white)||
# For ordinary use of the numeric keypad key 1, turn this item off. 
# For turning this feature temporarily off or on, you can also simply toggle
# button NLCK in the status bar (grey = ordinary numeric key pad)
newPref f electricNumKeypad_1        {1} M2 M2::adjustM2Prefs

# To add double spaces after periods at the end of the sentence, turn this item on.
# This feature affects wrap text routines, e.g. CTRL-a, CTRL-SHIFT-a||
# To have merely a single space at the end of the sentence, turn this item off
newPref flag doubleSpaces           {1}  M2


if {[alpha::package exists globalM2Bindings]} {
    # To always make global bindings for <command>-0/1/2
    # available even if M2 mode has not yet been loaded, urn this item on.  
    # These bindings open work files and shell windows||
    # Tto only make these bindings global after M2 mode 
    # has first been loaded, turn this item off
    newPref flag globalM2Bindings         {0} M2  M2::adjustM2Prefs
} else {
    prefs::removeObsolete M2modeVars(globalM2Bindings)
}


# ×××× Override Global Settings ×××× #
# 
# Incompatible settings possibly specified otherwise by Alpha's defaults and 
# setupAssistant which interfere with the language "philosophy" of a structured
# language such as Modula-2
#
# now offer some of these prefs also for Alpha's "Config > Current Mode > 
# Preferences...". Unfortunately some can be controlled this way, some can't.
# Some require to be specified in alpha::mode M2 (see m2Mode.tcl):
# 
#    elecCompletions electricReturn indentUsingSpacesOnly
#
# The newPref below for indentUsingSpacesOnly was always ignored, but if
# declared in alpha::mode M2 3.8.2 { (see m2Mode.tcl) the flag shows up in
# prefs dialog (F12) twice unless commented out here.  Looks like a bug in
# Alpha 7.6 (af, 26.Feb.2003)
# 
# All indents should be made by using spaces only in Modula-2 source code
# newPref flag indentUsingSpacesOnly      {1}	M2 
# 
# Some need to be declared in m2Mode.tcl PLUS here as newPref flag.  Some
# only as newPref, some only in m2Mode.tcl.  All in all: Global flags is still
# conceptually messy :-( and it is basically impossible for me to implement the 
# M2 mode properly yet consistently for Alpha 7.6 and Alpha8/X 8.0b8 (May 2003).
# 
# Note, not all comments specified here show up in the help feature of
# the preference dialog (F12). For instance backup, horScrollBar will
# show the globally defined help texts instead.
 

set firstAlphaGlobalPrefsV "8.0"
if {[set M2::curAlphaV] >= $firstAlphaGlobalPrefsV} {
    # remove obsolete prefs
    prefs::removeObsolete M2modeVars(elecCompletions)
    # prefs::removeObsolete M2modeVars(electricSemicolon)
    prefs::removeObsolete M2modeVars(smartPaste)
    
    # To automatically indent the new line produced by pressing <return>, turn
    # this item on.  The indentation amount is determined by the context in a
    # Modula-2 syntax specific manner||To have the <return> key produce a new line
    # without indentation, turn this item off or use the M2 mode specific shortcut
    # <shift>^<control>^<return>
    newPref flag indentOnReturn           	{1}	M2
    
    # To indent what you paste in a context sensitive manner, turn this item on||To 
    # paste text exactly as it was copied into the clipboard, turn this item off. 
    # Plain vanilla pasting is usually preferable while programming in Modula-2
    newPref flag smartCutPaste              	{0}	M2 
} else {
    # Elec Completions feature is recommended to be enabled in M2 mode
    newPref flag elecCompletions           	{1}	M2
    # To indent what you paste in a context sensitive manner, turn this item on||To 
    # paste text exactly as it was copied into the clipboard, turn this item off. 
    # 'SmartPaste' is not smart enough to work properly while programing
    # in Modula-2, thus it is recommended to turn 'smartPaste' off
    newPref flag smartPaste              	{0}	M2 
    # To indent what you paste in a context sensitive manner, turn this item on||To 
    # paste text exactly as it was copied into the clipboard, turn this item off. 
    # Plain vanilla pasting is usually preferable while programming in Modula-2
    newPref flag smartCutPaste              	{0}	M2 
}

# To automatically perform context relevant formatting after typing a 
# semicolon, turn this item on||To have the semicolon key produce a mere
# semicolon without additional formatting, turn this item off. 
# 'Electric Semicolon' is not recommended in Modula-2 programming
newPref flag electricSemicolon			{0}	M2    

# To automatically wrap lines (insert EOL) during normal text 
# insertion (typing), turn this item on. Wrapping occurs as soon as 
# a line's length exceeds 'm2_maxLineLength'||To avoid automatic 
# line wrapping, turn this item off. 
# Since strings must not be broken by an EOL, line wrapping is not 
# recommended in Modula-2 programming
newPref var     lineWrap  		    	{0} 	M2

# Enabling this feature tells Alpha to insert at the begin of a line a
# comment symbol when pressing return. However, Modula-2 is a free 
# format syntax language and can't profit from this feature. Thus it
# is best to turn it off. See also menu 
# "Config -> Preferences -> Electric Completions".
newPref flag     autoContinueComment        	{0} 	M2

# To back up any Modula-2 source file when saving it, turn this item on||
# To overwrite the older file when saving the newly edited content, 
# turn this item off. It is highly recommended to turn this item off
# when programing in Modula-2. See also menu 
# "Config -> Preferences -> Electric Completions".
newPref flag     backup  		    	{0} 	M2

# EMACS navigation shortcuts should not be active in M2 mode
# newPref flag     emacs                      	{0} 	M2	

# To display a horizontal scrollbar in new windows, turn this item on||
# To have no horizontal scrollbar in new windows, turn this item off
newPref flag     horScrollBar           	{1} 	M2




# Regular expression used to delimit words
newPref variable wordBreak		{\w+} M2
# Regular expression used to parse Modula-2 procedures
newPref variable funcExpr			{^[ \t]*PROCEDURE[ \t]*([^\s;(]+)} M2 ;#-trf

####### End Override Global Settings ########




# ×××× M2 Mode's Variable Settings ×××× #

# Format of template stops (see "Config -> Preferences -> Electric Completions" for details)
newPref variable ElectricFillers    {1} M2

# Regular expression used to parse Modula-2 code while searching for procedure declarations
newPref variable parseExpr          {\b([_:\w]+)\s*\(}  M2 

# Text inserted at begin of every line in current selection
newPref variable prefixString		{ (*} M2 M2::adjustM2Prefs
# Text appended at end of every line in current selection
newPref variable suffixString		{ *)} M2 M2::adjustM2Prefs

# Color used for Modula-2 reserved words (keywords) such as IF, WHILE etc.
newPref variable keywordColor	    blue	M2 M2::colorizeM2 
# Color used for Modula-2 comments (* *)
newPref variable commentColor	    red		M2 stringColorProc 
# Color used for Modula-2 string constants (if delimited by quotes "")
newPref variable stringColor		magenta	M2 stringColorProc 
# Color used for Modula-2 standard procedures, such as ABS, INC etc.
newPref variable standardProcColor  green	M2 M2::colorizeM2 
# Color used for Modula-2 objects imported from libraries (of limited use)
newPref variable libColor		    blue	M2 M2::colorizeM2 

# First and last name of author (used in templates)
newPref variable m2_author	        {FirstName LastName} M2 M2::adjustM2Prefs
# ensure initial assignment consistent with M2Author

# Path and name of Modula-2 shell which compiles and loads your programs
newPref variable m2_shellName	    "M2modeVars(m2_shellName)" M2 M2::adjustM2Prefs
# ensure initial assignment consistent with M2ShellName

# Path and name of the file, which contains the explanations of compiler errors. This file
# is needed to display error explanations after having compiled erroneous source code.
# Normally this preference is automatically defined while configuring the launching 
# of a Modula-2 shell. See menu "M2 -> Configure Launching".
newPref variable m2_errListDOK	    {::RMS:M2Tools:ErrList.DOK} M2 M2::adjustM2Prefs

# To open Modula-2 work files which were compiled by the P1 compiler, turn this item on||
# To open Modula-2 work files which were compiled by the MacMETH/RAMSES compiler, turn this item off||
# Normally this preference is automatically defined while calling
# AlphaX via the RAMSES or MacMETH shell or while using a RASS-OSX
# utility like 'mk' or 'mk1'. M2 menu command "M2 -> Open Work Files"
# (CTRL-0) observes this preference while opening work files.
newPref flag openP1WorkFiles	{0} M2

# Directory where proc M2::openM2WorkFiles expects to find the auxiliary files
# 'err.LST' and 'ErrListP1.DOK'.  M2::openM2WorkFiles will use this directory
# also to write a third auxiliary file, 'err.ALPHA', to it.  Unless you should
# have no permission to write to the directory, which is used by default, there
# is little need to alter this preference.
newPref variable m2_P1AuxFileCacheFolder	"[file join $HOME Cache]" M2

# Amount of spaces inserted during indentations using TAB or CTRL-r (right shift)
newPref variable m2_indentAmount	{  } M2 M2::adjustM2Prefs
# ensure initial assignment consistent with M2RightShift

# Amount of spaces deleted while unindenting using CTRL-l (left shift)
newPref variable m2_leftShiftAmount	{ }  M2 M2::adjustM2Prefs
# ensure initial assignment consistent with M2LeftShift


# Right fill margin for "Wrap comment" (CTRL-a) and "Wrap text" (CTRL-SHIFT-a) commands (similar to fillColumn)
newPref variable m2_fillRightMargin	{65} M2 M2::adjustM2Prefs
# ensure initial assignment consistent with M2WrapRightMargin

# Path and name of folder which contains documentation files 
# such as the quick reference files and definition modules as
# contained in the RAMSES release
newPref variable docuFolder         {Docu} M2




if [info exists defaultFont] {
    # Default font to use in new windows
    newPref variable defaultFont        	"$defaultFont" M2
}

# Default size of font to use in new windows
newPref variable defaultFontSize        {9} M2

# Saving files with, e.g. MPW, resources
newPref variable m2_savedState		{mpw} M2 M2::adjustM2Prefs
# ensure initial assignment is consistent with M2SaveState


# Maximum length of lines beyond which automatical wrapping occurs while typing
newPref variable m2_maxLineLength	{120} M2 M2::adjustM2Prefs
# ensure initial assignment consistent with M2MaxLineLength

# Tolerance around m2_maxLineLength within which actual line breaks occurr
newPref variable m2_maxLnLeTol	    	{5} M2 M2::adjustM2Prefs

# Target platform for which code is to be edited. Every code fragment is commented
# or uncommented accordingly to the conditional compiler flags listed for the 
# given target platform.  Ex.: Any code fragment between the comments (* IF VERSION_BDM *) 
# and (* ENDIF VERSION_BDM *) is uncommented if the flag 'BDM' is listed 
# in 'm2_SunCompFlagList' and the current target platform is 'Sun'. Conversely, 
# in this example, any code fragment between the comments (* IF VERSION_MAC *) 
# and (* ENDIF VERSION_MAC *) is commented if the flag 'MAC' is not listed 
# in 'm2_SunCompFlagList'
newPref variable m2_TargetPlatform     {Mac} M2

# List of conditional compiler flags recognized if m2_TargetPlatform is 'Mac'
# (for details see 'm2_TargetPlatform')
newPref variable m2_MacCompFlagList    {DM MacMETH DM_MAC DM_MAC_OLD MW_MAC_OLD AuxLib_68KFPU} M2

# List of conditional compiler flags recognized if m2_TargetPlatform is 'IBM'
# (for details see 'm2_TargetPlatform')
newPref variable m2_IBMCompFlagList    {DM STONYBROOK DM_IBM AuxLib} M2

# List of conditional compiler flags recognized if m2_TargetPlatform is 'Sun'
# (for details see 'm2_TargetPlatform')
newPref variable m2_SunCompFlagList    {BDM EPC AuxLib} M2


# List of conditional compiler flags recognized if m2_TargetPlatform is 'P1'
# (for details see 'm2_TargetPlatform')
newPref variable m2_P1CompFlagList    {BDM P1 ISO AuxLib} M2





# newPref file     tagFile		"$HOME:modTAGS" M2

# The following are the creators and file types which should be recognized by Alpha in order
# to fully support all RAMSES (Research Aids for Modeling and Simulation of Environmental 
# Systems) files
# set modeCreators(RAMS) RAMS
# set modeCreators(ETHM) ETHM
# set modeTypes(MoTx) MoTx   # simple text, model files, but treated differently if doubleclicked
# set modeTypes(WDBN)        # simple RTF, stash files, but treated differently if doubleclicked
# set modeTypes(XLS )        # simple text, data frame files, but treated differently if doubleclicked

# set ${mode}::startPara {^(.*\{)?[ \t]*$}
# set ${mode}::endPara {^(.*\})?[ \t]*$}


# Reporting that end of this script has been reached
status::msg "m2Prefs.tcl for Programing in Modula-2 loaded"
if {[info exists M2::installDebugFlag] && [set M2::installDebugFlag]} {
    alertnote "m2Prefs.tcl for Programing in Modula-2 loaded"
}
