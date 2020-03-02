## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "fortranMode.tcl"
 #                                          created: 04/05/1998 {09:30:28 pm}
 #                                      last update: 03/21/2006 {03:06:35 PM}
 # Description:
 #                                
 # Fortran mode definition and support procs
 # 
 # Features:
 # 
 #  1.  Keyword colorization (customizable)
 #  2.  Fortran-sensitive "Shift Right/Left" preserves columns 1-6
 #  3.  Auto-indentation
 #  4.  Line-breaking with Control-Option-J (a la emacs) (now Shift-Return)
 #  5.  Subroutine indexing
 #  6.  Command-Double-Click subroutine and include-file lookup
 #  7.  Customizable comment and continuation characters
 # 
 # Fortran 77 is not a free-format language, but has a very strict set of
 # rules for how the source code should be formatted.  The most important
 # rules are the column position rules:
 # 
 # Col. 1    : Blank, or a "c" or "*" for comments
 # Col. 2-5  : Statement label (optional)
 # Col. 6    : Continuation of previous line (optional)
 # Col. 7-72 : Statements
 # Col. 73-80: Sequence number (optional, rarely used today)
 # 
 # Most lines in a Fortran 77 program starts with 6 blanks and ends before
 # column 72, i.e. only the statement field is used.  Note that Fortran 90
 # allows free format.  'Fort' mode assumes a fixed-format syntax.
 # 
 # This package also defines a mode named 'f90' that supports free-format
 # editing of Fortran files.
 # 
 # --------------------------------------------------------------------------
 # 
 # Author: Tom Pollard <pollard@chem.columbia.edu>
 # 
 # Includes contributions from Craig Barton Upright.
 # 
 # Copyright (c) 1994-2006  Tom Pollard, Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

# ===========================================================================
#
# ×××× Initialization of Fort mode ×××× #
#

alpha::mode [list Fort Fortran] 2.0 {Fort::initializeMode} \
  {*.f *.inc *.fcm *.for *.hpf } {
    fortranMenu indentUsingSpacesOnly -smartPaste
} {
    # Script to execute at Alpha startup
    set unixMode(fortran) {Fort}
    addMenu fortranMenu "Fortran" [list "Fort"]
} uninstall {
    if {[askyesno "You are about to remove both 'Fort' and 'f90' modes.\
      \r\rDo you want to continue?"]} {
	foreach fileName [list \
	  [file join $::HOME Tcl Modes fortranMode.tcl] \
	  [file join $::HOME Tcl Completions FortCompletions.tcl] \
	  [file join $::HOME Tcl Completions "Fort Tutorial.f"] \
	  [file join $::HOME Tcl Completions f90Completions.tcl] \
	  [file join $::HOME Tcl Completions "f90 Tutorial.f90"] \
	  [file join $::HOME Help "Fortran Mode Help"] \
	  ] {
	    if {[file exists $fileName]} {
	        catch {file delete -force $fileName}
	    }
	}
	unset fileName
    }
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} description {
    Supports the editing of Fortran77 (fixed-format) programming files
} help {
    file "Fortran Mode Help"
}

alpha::mode [list f90 Fortran90] 2.0 {f90::initializeMode} \
  {*.f9 *.f90} {
    fortran90Menu indentUsingSpacesOnly
} {
    # Script to execute at Alpha startup
    set unixMode(fortran) {Fort}
    addMenu fortran90Menu "F90" [list "f90"]
} uninstall {
    if {[askyesno "You are about to remove both 'Fort' and 'f90' modes.\
      \r\rDo you want to continue?"]} {
	foreach fileName [list \
	  [file join $::HOME Tcl Modes fortranMode.tcl] \
	  [file join $::HOME Tcl Completions FortCompletions.tcl] \
	  [file join $::HOME Tcl Completions "Fort Tutorial.f"] \
	  [file join $::HOME Tcl Completions f90Completions.tcl] \
	  [file join $::HOME Tcl Completions "f90 Tutorial.f90"] \
	  [file join $::HOME Help "Fortran Mode Help"] \
	  ] {
	    if {[file exists $fileName]} {
		catch {file delete -force $fileName}
	    }
	}
	unset fileName
    }
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} description {
    Supports the editing of Fortran90 (free-format) programming files
} help {
    file "Fortran Mode Help"
}

proc fortranMode.tcl {} {}

## 
 # --------------------------------------------------------------------------
 # 
 # "namespace eval Fort" --
 # 
 # Define variables used throughout this package.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval Fort {
    
    variable initialized
    if {![info exists initialized]} {
        set initialized 0
    }
    variable fortModeShifting
    if {![info exists fortModeShifting]} {
        set fortModeShifting 1
    }
    
    # Used by various procedures.
    variable commentCharOptions [list "c" "C" "*" "!"]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Fort::initializeMode" --
 # 
 # ("Fort" mode)
 # 
 # After everything in this file has been sourced, call the 'Fort' procedures
 # required to colorize and create the menu.  (Placing them here helps make
 # it clearer what is being called when the mode is loaded.)
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::initializeMode {} {
    
    global FortmodeVars alpha::platform
    
    variable initialized
    variable prefLists
    
    if {$initialized} {
        return
    }
    
    # Ensure that any previously saved "commentCharacter" preference value is a
    # single character.
    if {([string length $FortmodeVars(commentCharacter)] > 1)} {
	set FortmodeVars(commentCharacter) \
	  [string index $FortmodeVars(commentCharacter) 0]
    }
    # Ensure that any previously saved "continueCharacter" preference value is a
    # single character.
    if {([string length $FortmodeVars(continueCharacter)] > 1)} {
	set FortmodeVars(continueCharacter) \
	  [string index $FortmodeVars(continueCharacter) 0]
    }

    # Call this now, so that the rest can be "adds".
    regModeKeywords -s $FortmodeVars(stringColor) Fort {}
    # Define colors.
    Fort::colorizeFortran "Fort"
    # Defin comment characters.
    Fort::setCommentCharacters
    
    # WORKAROUND for RFE# 1794.
    # 
    # This is a special compensation for Alpha8/X coloring limitations.
    # 
    if {(${alpha::platform} eq "alpha")} {
	# This is a hacky attempt to color !  comments that do not appear in
	# column 1 for Alpha8/X. Unfortunately, the colorizing will end as soon
	# as a keyword appears in the comment.  Press Control-(Option)-L to
	# refresh the window.
	newPref flag colorInlineComments {0} Fort {Fort::updatePreferences}
	lappend prefLists(Colors) "colorInlineComments"
        hook::register openHook {Fort::colorComments} Fort
	Bind 'l' <oz> {Fort::colorComments [win::Current] 0} Fort
	Bind 'l' <z>  {Fort::colorComments [win::Current] 1} Fort
    }
    # 
    # End of WORKAROUND.


    # Build the Fortran menu.
    menu::buildProc "fortranMenu" {Fort::buildMenu} {Fort::postBuildMenu}
    menu::buildSome "fortranMenu"
    
    # Make sure that we don't call this again.
    set initialized 1
    return
}

# ===========================================================================
#
# ×××× Key Bindings ×××× #
# 

# Shift left, right.

Bind    up   <sz>   {paragraph::prev 0 0}       Fort
Bind  left   <sz>   {paragraph::prev 0 1}       Fort
Bind  down   <sz>   {paragraph::next 0 0}       Fort
Bind right   <sz>   {paragraph::next 0 1}       Fort

# This is a back compatibility binding for those who are used to it.
Bind 'j'     <zo>   {Fort::continueLine}        Fort

# ===========================================================================
# 
# ×××× Preferences ×××× #
# 
# Some preferences which are also global will inherit those descriptions so
# there's no need to provide them here.
# 

prefs::removeObsolete \
  FortmodeVars(sortedIsDefault) \
  FortmodeVars(colorFuncs) \
  FortmodeVars(colorOpers) \
  FortmodeVars(funcExpr)

prefs::renameOld FortmodeVars(commentChar)      FortmodeVars(commentCharacter)
prefs::renameOld FortmodeVars(continueChar)     FortmodeVars(continueCharacter)
prefs::renameOld FortmodeVars(indentComment)    FortmodeVars(indentComments)

# --- Comment preferences.

# This comment character will be used for all "Comment" menu items.
newPref var  commentCharacter   {c}         Fort    {Fort::updatePreferences} \
  ${Fort::commentCharOptions} item
# These characters are the "Continue Character" options.  (You'll need to
# save this preference, close the dialog (with OK) and then re-open it in
# order to choose it from the above pop-up menu.)
newPref var  continueCharacters {+ $ & % @ #}   Fort {Fort::updatePreferences}
# This character will be used by the "Fortran > Continue Line" menu command.
newPref var  continueCharacter  {$}         Fort    {} \
  FortmodeVars(continueCharacters) varitem

# --- Indentation preferences.

# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn     {1}         Fort

# Comments can be automatically indented to column 3, column 7, or left alone
# (retaining any original indentation.)
newPref var  indentComments     {2}         Fort    {} \
  [list "To Column 3" "To Column 7" "Never -- Leave As Found"] index
newPref var  indentationAmount   3          Fort    {} \
  [list "1" "2" "3" "4" "5" "6" "7" "8"] item

# --- Color preferences.

# The color for all basic Fortran keywords.
newPref color commandColor      {blue}      Fort    {Fort::updatePreferences}
# The color for all keywords that start with a hash mark.
newPref color cPreprocessColor  {green}     Fort    {Fort::updatePreferences}
# The color for all comments.
newPref color commentColor      {red}       Fort    {stringColorProc}
# The color for "bit" keywords such as "bit_size" "btest" "iand" etc.
newPref color functionColor     {none}      Fort    {Fort::updatePreferences}
# The color for all "operator" keywords such as "eq" "ne" "lt" "le" etc.
newPref color operatorColor     {none}      Fort    {Fort::updatePreferences}
# The color for all strings that are contained in double quotes.
newPref color stringColor       {none}      Fort    {stringColorProc}

# --- Miscellaneous 'flag' preferences.

# To automatically mark new windows (if none have been previously saved) turn this
# item on||To never automatically mark new windows, turn this item off
newPref flag autoMark           {1}         Fort

# --- Miscellaneous 'var' (other) preferences.

newPref var  fillColumn         {72}        Fort
# This url will be opened by the "Fortran > Fortran Home Page" menu item.
newPref url  fortranHomePage {http://www.fortran.com/} Fort
newPref var  lineWrap           {1}         Fort
# When this string appears in a commented line just behind the comment
# character, it will be recognized during File Marking routines.
newPref var  markTag            {}          Fort
newPref var  wordBreak          {[\w.]+}    Fort

# ===========================================================================
# 
# Categories of all Fortran preferences, used by [prefs::dialogs::modePrefs].
# When the dialogues are actually built, there will most likely be added a
# Miscellaneous pane.  This happens whenever there are prefs which are not
# categorized.  (There's no need to set a "Miscellaneous" group entry,
# because this will always be built from scratch.)
# 

# Editing
prefs::dialogs::setPaneLists "Fort" "Editing" [list \
  "autoMark" \
  "continueCharacter" \
  "continueCharacters" \
  "fillColumn" \
  "indentationAmount" \
  "lineWrap" \
  "wordBreak" \
  ]

# Electrics
prefs::dialogs::setPaneLists "Fort" "Electrics" [list \
  "indentOnReturn" \
]

# Comments
prefs::dialogs::setPaneLists "Fort" "Comments" [list \
  "commentColor" \
  "commentCharacter" \
  "indentComments" \
  ]

# Colors
prefs::dialogs::setPaneLists "Fort" "Colors" [list \
  "colorInlineComments" \
  "cPreprocessColor" \
  "commandColor" \
  "functionColor" \
  "operatorColor" \
  "stringColor" \
  ]

# These 'preferences' can never be changed by the user.
set FortmodeVars(commentsContinuation)      "0"
set FortmodeVars(paragraphName)             "code block"
# These variables are not visible to the user.
prefs::deregister "prefixString"            "Fort"
prefs::deregister "commentsContinuation"    "Fort"
prefs::deregister "paragraphName"           "Fort"

## 
 # --------------------------------------------------------------------------
 # 
 # "Fort::updatePreferences" --  ?<args>?
 # 
 # ("Fort" mode)
 # ("f90"  mode)
 # 
 # Update colors, comment characters when preferences change.  If only one
 # argument is supplied, it is the name of the preference that has just been
 # changed, otherwise the first argument is the name of the mode and the
 # second is the name of the preference.  ("f90" mode will define [newPref]
 # tracing calls with {Fort::updatePreferences "f90?}.)
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::updatePreferences {args} {
    
    global FortmodeVars
    
    variable commentCharOptions
    
    if {([llength $args] == 1)} {
	set modeName "Fort"
	set prefName [lindex $args 0]
    } else {
	set modeName [lindex $args 0]
	set prefName [lindex $args 1]
    }
    
    switch -regexp -- $prefName {
	"Color$" {
	    Fort::colorizeFortran $modeName
	    if {([win::getMode [win::Current]] eq "Fort")} {
		Fort::colorComments [win::Current]
		refresh
	    } elseif {([win::getMode [win::Current]] eq "f90")} {
	        refresh
	    }
	}
	"^colorInlineComments" {
	    if {([win::getMode [win::Current]] eq "Fort")} {
		Fort::colorComments [win::Current]
	    }
	}
	"^commentCharacter$" {
	    Fort::setCommentCharacters
	    Fort::postBuildMenu
	    if {([win::getMode [win::Current]] eq "Fort")} {
		refresh
	    }
	}
	"^continueCharacters$" {
	    # Make sure that this is a proper list.
	    set continueCharacters [join $FortmodeVars(continueCharacters) " "]
	    set newValues [list]
	    foreach item $continueCharacters {
		switch -- [string length $item] {
		    "0" {
		        continue
		    }
		    "1" {
			if {([lsearch $commentCharOptions $item] > -1)} {
			    alertnote "The \"Continue Characters\" preference \
			      cannot contain comment characters.  The \"${item}\"\
			      option has been removed."
			} else {
			    lappend newValues $item
			}
		    }
		    default {
		        alertnote "The \"Continue Characters\" preference \
			  must be a list of single characters.  The \"${item}\"\
			  option has been removed."
		    }
		}
	    }
	    set FortmodeVars(continueCharacters) $newValues
	    prefs::modified FortmodeVars(continueCharacters)
	}
    }
    return
}

# ===========================================================================
# 
# ×××× Fortran Colorization ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Fort::colorizeFortran" --  ?<modeName "Fort">?
 # 
 # ("Fort" mode)
 # ("f90"  mode)
 # 
 # Define lists for colorizing Fortran keywords.
 # 
 # Called when Fort mode is first initialized, and whenever the user changes
 # a color preference.
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::colorizeFortran {{m "Fort"}} {
    
    global ${m}modeVars
    
    foreach [list prefName prefValue] [array get ${m}modeVars "*Color"] {
	set $prefName $prefValue
    }
    
    set FortranKeywords {
	allocatable allocate assign assignment backspace block call case
	character close common complex contains continue cycle data
	deallocate default dimension do double else elseif elsewhere end
	enddo endfile endfile endif entry equivalence exit external extrinsic
	forall format function go goto if implicit include inquire integer
	intent interface intrinsic logical module namelist none nullify open
	operator optional parameter pause pointer precision print private
	procedure program public pure read real recursive return rewind save
	select sequence stop subroutine target then to type until use where
	while write
    }
    if {($m eq "Fort")} {
        eval [list lappend FortranKeywords] $FortmodeVars(continueCharacters)
    } else {
        lappend FortranKeywords "&"
    }
    regModeKeywords -a -k $commandColor $m $FortranKeywords

    # Colorize selected C preprocessor keywords
    set CPPKeywords  {
	#if #endif #include #else #define #undef #ifdef #ifndef
    }
    regModeKeywords -a -k $cPreprocessColor $m $CPPKeywords

    # Colorize Fortran function keywords
    set BitKeywords {
	bit_size btest iand ibclr ibits ibset ieor ior ishft ishftc mvbits not
    }
    regModeKeywords -a -k $functionColor $m $BitKeywords

    # Colorize Fortran intrinsic functions
    set IntrinsicKeywords {
	abs acos aimag asin atan atan2 conjg cos cosh dble dim dprod exp
	ichar len lge lgt lle llt log log10 max min mod sign sin sinh sqrt
	tan tanh iabs dabs cabs dacos dint dnint dasin datan datan2 dcos
	ccos dcosh idim ddim dexp cexp ifix idint alog ddlog clog alog10
	dlog10 max0 amax0 max1 amax1 dmax1 min0 amin0 min1 amin1 dmin1 amod
	dmod idnint float sngl isign dsign dsin csin dsinh dsqrt csqrt dtan
	dtanh aint anint char cmplx index int nint achar adjustl adjustr
	all allocated any associated bit_size btest ceiling count cshift
	date_and_time digits dot_product eoshift epsilon exponent floor
	fraction huge iachar iand ibclr ibits ibset ieor ior ishft ishftc
	kind lbound len_trim matmul maxexponent maxloc maxval merge
	minexponent minloc minval modulo mvbits nearest not pack 
	present product radix random_number random_seed range repeat
	reshape rrspacing scale scan selected_int_kind selected_real_kind
	set_exponent shape size spacing spread sum system_clock tiny
	transfer transpose trim ubound unpack verify
    }
    regModeKeywords -a -k $functionColor $m $IntrinsicKeywords

    # Colorize Fortran operators
    set FortOperators {
	.eq. .ne. .lt. .le. .gt. .ge. .not. .and. .or. 
	.eqv. .neqv. .true. .false.
    }
    regModeKeywords -a -k $operatorColor $m $FortOperators

    return
}

# ===========================================================================
# 
# ×××× Fortran Comments ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Fort::setCommentCharacters" --
 # 
 # ("Fort" mode)
 # 
 # Define various comment related variables used by the SystemCode, as well
 # as the colors used for commenting items in Fortran windows.
 # 
 # Called when Fort mode is first initialized, and whenever the user changes
 # a comment preference.
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::setCommentCharacters {} {
    
    global FortmodeVars alpha::platform
    
    variable commentCharacters
    
    set cc $FortmodeVars(commentCharacter)
    set FortmodeVars(prefixString) "$cc "
    
    if {(${alpha::platform} eq "alpha")} {
	regModeKeywords -a -e $cc \
	  -c $FortmodeVars(commentColor) Fort {}
    } else {
	# Alphatk supports coloring all comment characters only at the
	# beginning of the line with "-begin".
	regModeKeywords -a -begin {^([cC!*].*)} -e "!" \
	  -c $FortmodeVars(commentColor) Fort {}
    }
    array set commentCharacters [list \
      "General"         $cc \
      "Paragraph"       [list "$cc " "$cc " "$cc "] \
      "Box"             [list $cc 1 $cc 1 $cc 3] \
      ]
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Fort::CommentLine" --  ?-w <win>?
 # 
 # ("Fort" mode)
 # 
 # We ensure that a previously commented line won't be commented again, and
 # we try to ensure that any previous region is re-selected again at the end.
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::CommentLine {args} {
    
    global FortmodeVars
    
    win::parseArgs w
    
    if {![win::checkIfWinToEdit $w]} {
	return
    }
    set cc $FortmodeVars(commentCharacter)
    switch -- $FortmodeVars(indentComments) {
        "0" {
            append pS $cc " "
        }
        "1" {
            append pS $cc "     "
        }
        "2" {
            append pS $cc
        }
    }
    # --- Positions involving the first line.
    set selBegPos [getPos -w $w]
    set selBegBeg [pos::lineStart -w $w $selBegPos]
    set selBegEnd [pos::lineEnd -w $w $selBegPos]
    # 'offsetBeg' -- distance from current position to the end of its line.
    if {[pos::compare -w $w $selBegPos == $selBegBeg] && [isSelection -w $w]} {
	# Special case: Selection starts at line-start, so keep it that way.
	set offsetBeg "10000"
    } else {
	set offsetBeg [pos::diff -w $w $selBegPos $selBegEnd]
    }
    # --- Positions involving the last line.
    set selEndPos [selEnd -w $w]
    set selEndBeg [pos::lineStart -w $w $selEndPos]
    set selEndEnd [pos::lineEnd -w $w $selEndPos]
    # 'offsetEnd' -- distance from selection end to the end of its line.
    if {[pos::compare -w $w $selEndPos == $selEndBeg] && [isSelection -w $w]} {
	# Special case: Selection ends at next-line-start, so back up to the
	# end of the previous line.
	set selEndEnd [pos::prevLineEnd -w $w $selEndPos]
	set offsetEnd "-1"
    } else {
	set offsetEnd [pos::diff -w $w $selEndPos $selEndEnd]
    }
    # Replace the first character in each text line.
    set newLines [list]
    foreach textLine [split [getText $selBegBeg $selEndEnd] "\r\n"] {
	if {($textLine eq "")} {
	    lappend newLines $pS
	} else {
	    set parsedLine [Fort::parseLine $textLine]
	    lappend newLines [join [lreplace $parsedLine 0 0 $cc] ""]
	}
    }
    if {[llength $newLines]} {
	set newText [join $newLines "\r"]
    } else {
	set newText $pS
    }
    replaceText -w $w $selBegBeg $selEndEnd $newText
    # Restore original position/selection relative to text.  The only
    # position that we can still count on is $selBegBeg, but we have enough
    # info to obtain line end positions and then back up using offsets.
    set newSelBeg [pos::math -w $w [pos::lineEnd -w $w $selBegBeg] - $offsetBeg]
    if {[pos::compare -w $w $newSelBeg < $selBegBeg]} {
	set newSelBeg $selBegBeg
    }
    set newSelEnd [pos::math -w $w $selBegBeg + \
      [string length $newText] - $offsetEnd]
    if {[pos::compare -w $w $newSelEnd < $selBegBeg]} {
	set newSelEnd $selBegBeg
    }
    selectText -w $w $newSelBeg $newSelEnd
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Fort::UncommentLine" --  ?-w <win>?
 # 
 # ("Fort" mode)
 # 
 # We take pains to properly indent the region after uncommenting it, and to
 # re-select it as close to the original as possible.
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::UncommentLine {args} {
    
    win::parseArgs w
    
    if {![win::checkIfWinToEdit $w]} {
	return
    }
    # --- Positions involving the first line.
    set selBegPos [getPos -w $w]
    set selBegBeg [pos::lineStart -w $w $selBegPos]
    set selBegEnd [pos::lineEnd -w $w $selBegPos]
    # 'offsetBeg' -- distance from current position to the end of its line.
    if {[pos::compare -w $w $selBegPos == $selBegBeg] && [isSelection -w $w]} {
	# Special case: Selection starts at line-start, so keep it that way.
	set offsetBeg "10000"
    } else {
	set offsetBeg [pos::diff -w $w $selBegPos $selBegEnd]
    }
    # --- Positions involving the last line.
    set selEndPos [selEnd -w $w]
    set selEndBeg [pos::lineStart -w $w $selEndPos]
    set selEndEnd [pos::lineEnd -w $w $selEndPos]
    # 'offsetEnd' -- distance from selection end to the end of its line.
    if {[pos::compare -w $w $selEndPos == $selEndBeg] && [isSelection -w $w]} {
	# Special case: Selection ends at next-line-start, so back up to the
	# end of the previous line.
	set selEndEnd [pos::prevLineEnd -w $w $selEndPos]
	set offsetEnd "-1"
    } else {
	set offsetEnd [pos::diff -w $w $selEndPos $selEndEnd]
    }
    # Replace the first character in each text line.
    set newLines [list]
    foreach textLine [split [getText $selBegBeg $selEndEnd] "\r\n"] {
	if {[regexp -- {^[cC*!]?$} $textLine]} {
	    lappend newLines ""
	} else {
	    set parsedLine [Fort::parseLine $textLine]
	    lappend newLines [join [lreplace $parsedLine 0 0 " "] ""]
	}
    }
    set newText [join $newLines "\r"]
    replaceText -w $w $selBegBeg $selEndEnd $newText
    # Restore original position/selection relative to text.  The only
    # position that we can still count on is $selBegBeg, but we have enough
    # info to obtain line end positions and then back up using offsets.
    set newSelBeg [pos::math -w $w [pos::lineEnd -w $w $selBegBeg] - $offsetBeg]
    if {[pos::compare -w $w $newSelBeg < $selBegBeg]} {
	set newSelBeg $selBegBeg
    }
    set newSelEnd [pos::math -w $w $selBegBeg + \
      [string length $newText] - $offsetEnd]
    if {[pos::compare -w $w $newSelEnd < $selBegBeg]} {
	set newSelEnd $selBegBeg
    }
    selectText -w $w $newSelBeg $newSelEnd
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Fortran::colorComments" --  <windowName> ?<center "0">?
 # 
 # ("Fort" mode)
 # 
 # WORKAROUND for RFE# 1794.
 # 
 # An experimental method for colorizing "!"  comments that do not start in
 # column 1.  (This is a hacky workaround for limitations in Alpha8/X's core
 # colorizing engine.)
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::colorComments {w {center 0}} {
    
    global alpha::platform FortmodeVars
    
    if {(${alpha::platform} ne "alpha") \
      || ([win::getMode $w] ne "Fort")} {
        return
    }
    set dirty [win::getInfo $w dirty]
    catch {removeColorEscapes -w $w}
    if {!$FortmodeVars(colorInlineComments)} {
	if {$center} {
	    centerRedraw -w $w
	} else {
	    refresh -w $w
	}
        return
    }
    status::msg [set msg "Colorizing ! comments É"]
    set pat {^[^\r\n!]*(![^\r\n]*)$}
    set pos [minPos -w $w]
    while {1} {
        set match [search -w $w -n -s -f 1 -r 1 -- $pat $pos]
	if {![llength $match]} {
	    break
	}
	set posEnd [lindex $match 1]
	regexp -indices -- $pat [eval [list getText -w $w] $match] -> indices
	set posBeg [pos::math -w $w [lindex $match 0] + [lindex $indices 0]]
	text::color -w $w $posBeg $posEnd $FortmodeVars(commentColor)
	set pos [pos::nextLineStart -w $w $posEnd]
    }
    if {!$dirty} {
        win::setInfo $w dirty 0
    }
    if {$center} {
        centerRedraw -w $w
    } else {
        refresh -w $w
    }
    status::msg "$msg finished."
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Fortran Lines ×××× #
#

## 
 # --------------------------------------------------------------------------
 # 
 # "Fort::parseLine" --  ?-w <win>? <firstArg> ?<argIsPosition "0">?
 # 
 # ("Fort" mode)
 # ("f90"  mode)
 # 
 # Parse the line given in "firstArg", alternatively the line containing the
 # position given by "firstArg".
 # 
 # Since Fortran uses a fixed-format syntax (at least < f90), it is very easy
 # to determine the 
 # 
 # (0) comment column character, 
 # (1) label, 
 # (2) continuation column character,
 # (3) indentation, and
 # (4) statement
 # 
 # that is contained in any given line.  If the comment character is invalid,
 # then we assume that the entire text line is the "statement".
 # 
 # "f90" support is provided since some procedures need to "parse" the line
 # to determine the label, leading white, and the statement. 
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::parseLine {args} {
    
    variable commentCharOptions
    
    win::parseArgs w arg {argIsPosition 0}
    
    if {$argIsPosition} {
	set textLine [getText [pos::lineStart $arg] [pos::lineEnd $arg]]
    } else {
	set textLine $arg
    }
    # Special case for free-format editing.
    if {([win::getMode $w] eq "f90")} {
	if {[regexp {^[\t ]*!(.*)$} $textLine -> theRest]} {
	    set commChar "!"
	    set textLine $theRest
	} else {
	    set commChar ""
	}
	set pat {^([\t ]*)([0-9]*)([\t ]*)(.*)$}
	regexp $pat $textLine -> white1 label white2 statement
	if {($label eq "")} {
	    append white $white1 $white2
	} else {
	    set white $white1
	}
	return [list $commChar $label "" $white $statement]
    }
    for {set i 0} {$i <= 6} {incr i} {
	if {([set char [string index $textLine $i]] eq "")} {
	    set char " "
	}
	switch -- $i {
	    "0" {
		if {([lsearch $commentCharOptions $char] > -1)} {
		    # This line is a comment.
		    set commChar $char
		    set label    ""
		    set contChar ""
		    set textLine [string range $textLine 1 end]
		    break
		} elseif {[regexp {[0-9]} $char]} {
		    # This character is part of a label.
		    set commChar ""
		    append label $char
		} elseif {($char eq "\t")} {
		    # This line is a statement.
		    set commChar " "
		    set label    "    "
		    set contChar " "
		    set textLine [string range $textLine 1 end]
		    break
		} elseif {($char eq " ")} {
		    # Empty character in column 1.
		    set commChar $char
		} else {
		    # Invalid item in the first column.
		    return [list "" "" "" "" $textLine]
		}
	    }
	    "1" - "2" - "3" - "4" {
		append label $char
	    }
	    "5" {
		set contChar $char
	    }
	    "6" {
		set textLine [string range $textLine 6 end]
	    }
	}
    }
    regexp {^(\s*)(.*)$} $textLine -> white statement
    set white [text::maxSpaceForm -w $w $white]
    return [list $commChar $label $contChar $white $statement]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Fort::continueLine" --
 # 
 # ("Fort" mode)
 # ("f90"  mode)
 # 
 # Continue the current line onto the next one.
 # 
 # If we are in a comment, simply continue the comment.
 # 
 # For "Fort" mode, insert the user's continuation character into column 5.
 # 
 # For "f90" mode, make sure that the & continuation character is at the end
 # of the line preceded by a space, then insert a Return and properly indent.
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::continueLine {} {
    
    global FortmodeVars
    
    if {![win::checkIfWinToEdit]} {
	return
    }
    if {([set m [win::getMode]] eq "Fort")} {
	set parsed [Fort::parseLine [selEnd] 1]
	switch -- [lindex $parsed 0] {
	    "" {
		# Invalid comment character.
		typeText "\r"
	    }
	    " " {
		# Not in a comment.
		typeText "\r     $FortmodeVars(continueCharacter)"
		set offset [pos::diff [getPos] [pos::lineEnd [getPos]]]
		catch {bind::IndentLine}
		goto [pos::math [pos::lineEnd [getPos]] - $offset]
	    }
	    default {
		# We're in a comment.  Replicate the padding.
		regexp -- {^[\t ]*} [join [lrange $parsed 1 end] ""] white
		typeText "\r[lindex $parsed 0]$white"
	    }
	}
    } elseif {($m eq "f90")} {
	if {[isSelection]} {
	    deleteSelection
	}
	if {[text::isInComment [getPos] prefix]} {
	    insertText "\r" $prefix
	    return
	}
	set rowBegPos [pos::lineStart [getPos]]
	set textToPos [getText $rowBegPos [getPos]]
	if {([string index [string trim $textToPos] end] ne "&")} {
	    if {([string index $textToPos end] ne " ")} {
		insertText " "
	    }
	    insertText "&"
	} 
	f90::carriageReturn
    } else {
	error "Cancelled -- this item is only useful in\
	  'Fort' and 'f90' modes."
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Fort::toggleContinuation" --
 # 
 # ("Fort" mode)
 # 
 # Toggle the character in column 6, adding the continuation character if it
 # is empty or if not then removing it.
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::toggleContinuation {} {
    
    global FortmodeVars
    
    if {![win::checkIfWinToEdit]} {
	return
    }
    set reselect  [isSelection]
    set selBegPos [getPos]
    set selEndPos [selEnd]
    set rowBegPos [pos::lineStart $selBegPos]
    set rowEndPos [pos::lineEnd $selBegPos]
    if {[pos::compare $selBegPos == $rowBegPos]} {
        set offsetBeg "10000"
    } else {
	set offsetBeg [pos::diff $selBegPos $rowEndPos]
    }
    if {[pos::compare [pos::lineStart $selEndPos] == $selEndPos]} {
        set selEndPos [pos::prevLineEnd $selEndPos]
	set offsetEnd -1
    } else {
	set offsetEnd [pos::diff $selEndPos $rowEndPos]
    }
    if {[pos::compare [pos::lineEnd $selEndPos] > $rowEndPos]} {
        error "Cancelled -- can only toggle one line at a time."
    }
    set parsed [Fort::parseLine [getText $rowBegPos $rowEndPos]]
    if {([lindex $parsed 0] eq "")} {
	# Invalid comment character.
	error "Cancelled -- invalid comment character in column 1."
    } elseif {([lindex $parsed 0] ne " ")} {
	# We're in a comment.
	error "Cancelled -- this item is not appropriate for comments."
    } elseif {([string length [string trim [lindex $parsed 1]]])} {
        error "Cancelled -- labelled lines cannot be continuations."
    }
    if {([lindex $parsed 2] eq " ")} {
        set contChar $FortmodeVars(continueCharacter)
    } else {
        set contChar " "
    }
    replaceText $rowBegPos $rowEndPos [join [lreplace $parsed 2 2 $contChar] ""]
    catch {bind::IndentLine}
    set rowEndPos [pos::lineEnd $rowBegPos]
    set newBegPos [pos::math $rowEndPos - $offsetBeg]
    if {[pos::compare $newBegPos < $rowBegPos]} {
        set newBegPos $rowBegPos
    }
    if {!$reselect} {
	goto $newBegPos
    } else {
	set newEndPos [pos::math $rowEndPos - $offsetEnd]
	selectText $newBegPos $newEndPos
    }
    return
}

##
 # --------------------------------------------------------------------------
 # 
 # "Fort::carriageReturn" --  ?-w <win>?
 # 
 # ("Fort" mode)
 # ("f90"  mode)
 # 
 # Inserts a carriage return, indents the line while retaining the correct
 # position for the next insertion.
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::carriageReturn {args} {
    
    win::parseArgs w
    
    variable commentCharOptions
    
    if {![win::checkIfWinToEdit $w]} {
	return
    }
    if {[isSelection -w $w]} {
	deleteSelection -w $w
    } 
    set posCur [getPos -w $w]
    set posEnd [pos::lineEnd -w $w $posCur]
    set text [string trim [getText -w $w $posCur $posEnd]]
    # Special case if the next non-white character is a comment.
    if {[lsearch $commentCharOptions [string index $text 0]] > -1} {
        insertText -w $w "\r"
	forwardDeleteWhitespace
	set posCur [pos::lineStart -w $w [getPos -w $w]]
	catch {bind::IndentLine}
	goto -w $w $posCur
	return
    }
    # Adjust indentation if this statement ends something special.
    set parsed [Fort::parseLine $posCur 1]
    append endPat {^(}\
      {(end\s*(if|do|type|where))} {|} \
      {(end\s+(module|program|subroutine|function))} {|} \
      {continue|until|(else(\s*(if|where))?)} \
      {)(\s|$)}
    if {[regexp -nocase -- $endPat [lindex $parsed 4]]} {
	set posCur [getPos -w $w]
	set offset [pos::diff -w $w $posCur [pos::lineEnd -w $w $posCur]]
	catch {bind::IndentLine}
	goto -w $w [pos::math -w $w [pos::lineEnd -w $w [getPos -w $w]] - $offset]
    }
    insertText -w $w "\r" "      "
    # Until indentation is better worked out, we need this.
    set posCur [getPos -w $w]
    set offset [pos::diff -w $w $posCur [pos::lineEnd -w $w $posCur]]
    catch {bind::IndentLine}
    goto -w $w [pos::math -w $w [pos::lineEnd -w $w [getPos -w $w]] - $offset]
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Fort::doShift" --  ?-w <win>? <amount>
 # 
 # ("Fort" mode)
 # 
 # Block shift left and right for Fortran mode.  For non-commented lines, we
 # always preserve columns 1-6.  For commented lines, we ensure that the
 # "indentComments" preference is respected, and that the comment character
 # has some whitespace padding following it.  The "amount" argument should be
 # a signed number, the number of visual spaces to shift right/left.  (A
 # negative "amount" will shift to the left.)
 # 
 # In all cases, any tabs in the leading "white" are converted to space
 # strings (via [Fort::parseLine]) and the original selection is restored.
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::doShift {args} {
    
    global FortmodeVars
    
    variable commentCharOptions
    variable fortModeShifting
    
    win::parseArgs w amount
    
    if {![win::checkIfWinToEdit $w]} {
	return
    } elseif {!$fortModeShifting} {
        ::shiftBy $amount
	return
    }
    regexp {^(-?)([0-9]+)} $amount -> which repeat
    set shiftString [string repeat " " $repeat]
    
    # --- Positions involving the first line.
    set selBegPos [getPos -w $w]
    set selBegBeg [pos::lineStart -w $w $selBegPos]
    set selBegEnd [pos::lineEnd -w $w $selBegPos]
    # 'offsetBeg' -- distance from current position to the end of its line.
    if {[pos::compare -w $w $selBegPos == $selBegBeg] && [isSelection -w $w]} {
	# Special case: Selection starts at line-start, so keep it that way.
	set offsetBeg "10000"
    } else {
	set offsetBeg [pos::diff -w $w $selBegPos $selBegEnd]
    }
    # --- Positions involving the last line.
    set selEndPos [selEnd -w $w]
    set selEndBeg [pos::lineStart -w $w $selEndPos]
    set selEndEnd [pos::lineEnd -w $w $selEndPos]
    # 'offsetEnd' -- distance from selection end to the end of its line.
    if {[pos::compare -w $w $selEndPos == $selEndBeg] && [isSelection -w $w]} {
	# Special case: Selection ends at next-line-start, so back up to the
	# end of the previous line.
	set selEndEnd [pos::prevLineEnd -w $w $selEndPos]
	set offsetEnd "-1"
    } elseif {[pos::compare -w $w $selEndEnd == $selBegBeg]} {
        set selEndPos [pos::nextLineStart $selEndPos]
	set selEndEnd $selBegEnd
	set offsetEnd "10000"
    } else {
	set offsetEnd [pos::diff -w $w $selEndPos $selEndEnd]
    }
    # Shift the text.
    set newLines [list]
    foreach textLine [split [getText $selBegBeg $selEndEnd] "\r\n"] {
	set parsed [Fort::parseLine $textLine]
	if {([lsearch $commentCharOptions [lindex $parsed 0]] > -1)} {
	    # This is a comment line.
	    set comment [join [lrange $parsed 1 end] ""]
	    switch -- $FortmodeVars(indentComments) {
	        "0" {
		    set padding " "
		    set padPat  "^ ?"
	        }
	        "1" {
		    set padding "     "
		    set padPat  "^ ? ? ? ? ?"
	        }
	        "2" {
		    set padding ""
		    set padPat  "^"
	        }
	    }
	    regsub -- $padPat $comment "" comment
	    if {($which eq "-")} {
		regsub -- "^$shiftString" $comment "" comment
	    } else {
		set comment "${shiftString}${comment}"
	    }
	    lappend newLines "[lindex $parsed 0]${padding}${comment}"
	} else {
	    # Normal statement line.
	    set white [lindex $parsed 3]
	    if {($which eq "-")} {
		regsub -- "^$shiftString" $white "" white
	    } else {
		append white $shiftString
	    }
	    lappend newLines [join [lreplace $parsed 3 3 $white] ""]
	}
    }
    if {![llength $newLines]} {
	set newLines [list "      "]
    }
    set newText [join $newLines "\r"]
    replaceText -w $w $selBegBeg $selEndEnd $newText
    # Restore original position/selection relative to text.  The only
    # position that we can still count on is $selBegBeg, but we have enough
    # info to obtain line end positions and then back up using offsets.
    set newSelBeg [pos::math -w $w [pos::lineEnd -w $w $selBegBeg] - $offsetBeg]
    if {[pos::compare -w $w $newSelBeg < $selBegBeg]} {
	set newSelBeg $selBegBeg
    }
    set newSelEnd [pos::math -w $w $selBegBeg + \
      [string length $newText] - $offsetEnd]
    if {[pos::compare -w $w $newSelEnd < $selBegBeg]} {
	set newSelEnd $selBegBeg
    }
    selectText -w $w $newSelBeg $newSelEnd
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Fort::specialBalance" --
 # 
 # ("Fort" mode)
 # ("f90"  mode)
 # 
 # If a "normal" [balance] works, then do nothing.  Otherwise attempt to
 # capture an enclosing "(ELSE|IF) ...  ENDIF" or "DO ...  ENDDO" block of
 # code, or PROGRAM|SUBROUTINE blocks.  This relies on proper formatting of
 # the entire block, as we use indentation to confirm the start/end.
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::specialBalance {} {
    
    set posBeg [getPos]
    set posEnd [selEnd]
    if {![catch {balance} errMsg]} {
        return
    }
    if {([win::getMode] eq "Fort")} {
        set pat1 {^[0-9 ][^\r\n]{5}}
    } else {
        set pat1 {^}
    }
    append pat1 {[\t ]*} {(} \
      {(module|program|subroutine|function)[\t ]+(\w+)} "|" \
      {(interface)} "|" \
      {(((while[\t ]+)?do)([\t ]|$))} "|" \
      {((\w+:[\t ]*do)([\t ]|$))} "|" \
      {(if[\t ]*\([^\r\n]+\)[\t ]*then)} "|" \
      {(where[\t ]*\([^\r\n]+\))} "|" \
      {(else([\t ]*(if|where)?))} \
      {)}
    set pos1 $posBeg
    while {1} {
	set match1 [search -n -s -f 0 -r 1 -i 1 -- $pat1 $pos1]
	if {![llength $match1]} {
	    selectText $posBeg $posEnd
	    error $errMsg
	} elseif {[pos::compare [lindex $match1 1] > $pos1]} {
	    set pos1 [pos::prevLineEnd $pos1]
	    continue
	}
	set white [lindex [Fort::parseLine [lindex $match1 1] 1] 3]
	if {([win::getMode] eq "Fort")} {
	    set pat2 {^[0-9 ][^\r\n]{5}}
	} else {
	    set pat2 {^}
	}
	append pat2 $white
	set line [eval getText $match1]
	switch -regexp -- [string trim [string tolower $line]] {
	    "^do" - {^while\s+do} {
		append pat2 {((until)|(continue)|(end[\t ]*do))}
	    }
	    {^\w+:\s*do(\s|$)} {
		regexp -- {^\s*(\w+):} $line -> label
		append pat2 {end[\t ]*do[\t ]+} $label
	    }
	    "if" - {else([\t ]*if)?[\t ]*$} {
		append pat2 {((else([\t ]*if)?)|(end[\t ]*if))}
	    }
	    "interface" {
		append pat2 {end[\t ]+interface([\t ]|$)}
	    }
	    "function" {
		regexp -nocase -- {function[\t ]+(\w+)} $line -> name
		append pat2 {end[\t ]+function[\t ]+} $name
	    }
	    "module" {
		regexp -nocase -- {module[\t ]+(\w+)} $line -> name
		append pat2 {end[\t ]+module[\t ]+} $name
	    }
	    "program" {
		regexp -nocase -- {program[\t ]+(\w+)} $line -> name
		append pat2 {end[\t ]+program[\t ]+} $name
	    }
	    "subroutine" {
		regexp -nocase -- {subroutine[\t ]+(\w+)} $line -> name
		append pat2 {end[\t ]+subroutine[\t ]+} $name
	    }
	    "where" - {else[\t ]*where} {
		append pat2 {(else|end)[\t ]*where}
	    }
	}
	set pos2 [pos::nextLineStart [lindex $match1 0]]
	set match2 [search -n -s -f 1 -r 1 -i 1 -- $pat2 $pos2]
	if {![llength $match2]} {
	    selectText $posBeg $posEnd
	    error $errMsg
	} elseif {[pos::compare [lindex $match2 1] < $posEnd]} {
	    set pos1 [pos::prevLineEnd [lindex $match1 0]]
	} else {
	    break
	}
    }
    set newBeg [text::firstNonWsPos [lindex $match1 0]]
    set newEnd [lindex $match2 1]
    selectText $newBeg $newEnd
    regexp {[\w\t ]+} [string trim [eval getText $match1]] what
    status::msg "Selected \"[string trim $what]\" block, lines\
      [lindex [pos::toRowCol $newBeg] 0] -\
      [lindex [pos::toRowCol $newEnd] 0]"
    return
}

# ===========================================================================
# 
# ×××× Standard Mode Support ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Fort::searchFunc" --  ?-w <win>? <direction>
 # 
 # ("Fort" mode)
 # ("f90"  mode)
 # 
 # Called by [nextFunc] and [prevFunc], generally by Keypad navigation.
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::searchFunc {args} {
    
    win::parseArgs w direction
    
    if {$direction} {
	paragraph::next 0 1
    } else {
	paragraph::prev 0 1
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Fort::MarkFile" --  ?-w <win>?
 # 
 # ("Fort" mode)
 # ("f90"  mode)
 # 
 # Mark the current window, looking for functions, entries, programs.  If the
 # user has added a "markTag" preference, we search for that in comments.
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::MarkFile {args} {
    
    global FortmodeVars f90modeVars
    
    win::parseArgs w
    
    status::msg [set msg "Marking '[win::Tail]' É"]
    
    set winMode     [win::getMode $w]
    set entry       0
    set function    0
    set module      0
    set program     0
    set subroutine  0
    if {($winMode eq "Fort")} {
        set pat1 {^[^cC*!\r\n]} 
    } else {
        set pat1 {^}
    }
    append pat1 {([\t \w*]*)} \
      {(subroutine|entry|[^\r\n]*function|module|program)} \
      {[\t ]+(\w+)}
    set pos [minPos -w $w]
    while {1} {
        set match [search -w $w -n -s -f 1 -r 1 -i 1 -- $pat1 $pos]
	if {![llength $match]} {
	    break
	}
	set text [eval [list getText -w $w] $match]
	regexp -nocase -- $pat1 $text -> valType subType name
	if {![regexp -nocase -- "end" $valType] \
	  && ![regexp -- {^\s*\!} $subType]} {
	    set mark [markTrim "$subType $name"]
	    while {[lcontains marks $mark]} {
	        append mark " "
	    }
	    lappend marks $mark
	    set row [lindex [pos::toRowCol -w $w [lindex $match 0]] 0]
	    set markItems($row) [list $mark [lindex $match 0]]
	    incr [string tolower [string trim $subType]]
	}
	set pos [pos::nextLineStart -w $w [lindex $match 0]]
    }
    set commentTag [set ${winMode}modeVars(markTag)]
    if {($commentTag ne "")} {
	if {($winMode eq "Fort")} {
	    set pat2 {^[cC*!]} 
	} else {
	    set pat2 {^[\t ]*!}
	}
	append pat2 {[\t ]*} [quote::Regfind $commentTag] \
	  {[\t ]*([^\r\n]+)$}
	set pos [minPos -w $w]
	while {1} {
	    set match [search -w $w -n -s -f 1 -r 1 -i 1 -- $pat2 $pos]
	    if {![llength $match]} {
		break
	    }
	    set text [eval [list getText -w $w] $match]
	    regexp -nocase -- $pat2 $text -> comment
	    set mark [markTrim $comment]
	    while {[lcontains marks $mark]} {
		append mark " "
	    }
	    lappend marks $mark
	    set row [lindex [pos::toRowCol -w $w [lindex $match 0]] 0]
	    set markItems($row) [list "* $mark" [lindex $match 0]]
	    set pos [pos::nextLineStart -w $w [lindex $match 0]]
	}
    }
    foreach item [lsort -integer [array names markItems]] {
	set mark [lindex $markItems($item) 0]
	set pos  [pos::lineStart -w $w [lindex $markItems($item) 1]]
	setNamedMark -w $w $mark $pos $pos $pos
    }
    append msg " finished"
    foreach item [list module program subroutine function entry] {
	if {[set $item]} {
	    append msg ", " [set $item] " "
	    if {([set $item] == 1)} {
	        append msg $item
	    } elseif {($item eq "entry")} {
	        append msg "entries"
	    } else {
	        append msg $item "s"
	    }
	}
    }
    append msg "."
    status::msg $msg
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Fort::parseFuncs" --
 # 
 # ("Fort" mode)
 # ("f90"  mode)
 # 
 # Called by the {} "Parse Funcs" pop-up menu in the active window's sidebar.
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::parseFuncs {} {
    
    global sortFuncsMenu
    
    set funcs [list]
    if {([win::getMode] eq "Fort")} {
	set pat {^[^cC*!\r\n]} 
    } else {
	set pat {^}
    }
    append pat {([\t \w*]*)} \
      {(subroutine|entry|[^\r\n]*function|module|program)} \
      {[\t ]+(\w+)}
    # Parse the file.
    set pos [minPos]
    while {1} {
	set match [search -n -s -f 1 -r 1 -i 1 -- $pat $pos]
	if {![llength $match]} {
	    break
	}
	set text [eval getText $match]
	regexp -nocase -- $pat $text -> valType subType name
	if {![regexp -nocase -- "end" $valType] \
	  && ![regexp -- {^\s*\!} $subType]} {
	    set mark [markTrim "$name (${subType})"]
	    while {[lcontains marks $mark]} {
		append mark " "
	    }
	    lappend marks $mark
	    lappend funcs [list $mark [lindex $match 0]]
	}
	set pos [pos::nextLineStart [lindex $match 0]]
    }
    if {$sortFuncsMenu} {
	set funcs [lsort -dictionary $funcs]
    }
    append what "item" [expr {([llength $funcs] == 1) ? "" : "s"}]
    status::msg "[llength $funcs] $what found in \"[win::Tail]\""
    return [join $funcs]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Fort::DblClick" --  <from> <to> <shift> <option> <control>
 # 
 # ("Fort" mode)
 # ("f90"  mode)
 # 
 # Command-Double-Clicking opens include files, jumps to subroutine
 # definitions, and follows tags.
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::DblClick {from to args} {
    
    global tagFile
    
    if {([win::getMode $w] eq "Fort")} {
	set pat1 {^[^cC*!]} 
    } else {
	set pat1 {^}
    }
    append pat1 {[ \t]*include[ \t]*['"]([^'"]+)['"]}
    
    set modified [expr [join $args "+"]]
    # First check whether an 'include' was clicked
    set line [getText [pos::lineStart $from] [pos::lineEnd $to]]
    if {[regexp -nocase -- $pat1 $line -> fileName]} {
	set path [file::absolutePath $fileName]
	if {[catch {file::openQuietly $path}]} {
	    error "Cancelled -- include file \"${fileName}\"\
	      not found in source folder"
	}
	return
    }
    selectText $from $to
    set text [getSelect]
    
    # Then check current file for subroutine definition.
    if {([win::getMode $w] eq "Fort")} {
	set pat2 {^[^cC*!]} 
    } else {
	set pat2 {^}
    }
    append pat2 {[\t \w*]*(subroutine|.*function|entry)[ \t]+}
    set pos  [minPos]
    while {1} {
	set match [search -n -s -f 1 -r 0 -m 0 -i 1 $text $pos]
	if {![llength $match]} {
	    break
	}
	set line [eval getText $match]
	if {[regexp -nocase -- $pat2$text $line]} {
	    regexp -nocase -- $pat2 $line -> subType name
	    placeBookmark
	    display [lindex $match 0]
	    # eval selectText $match
	    return
	} else {
	    set pos [pos::nextLineStart [lindex $match 1]]
	}
    }
    # Still here?  Then check tags file.
    if {[info exists tagFile]} {
	status::msg "Searching tags file..."
	set lines [grep "^$text'" $tagFile]
	if {[regexp -- {'(.*)'} $lines dummy fname]} {
	    placeBookmark 0
	    file::openQuietly $fname
	    set inds [Fort::findSub $text]
	    # set inds [search -s -f 1 -r 1 -i 1 "$pat1$text" [minPos]]
	    display [lindex $inds 0]
	    # eval selectText $inds
	    return
	}
    }
    # Still here?  Find out if the label is for a previous DO statement.
    # (This needs to be updated for "f90".)
    set parsed [Fort::parseLine $from 1]
    if {[llength [set doLine [Fort::findDoLine $from [lindex $parsed 1]]]]} {
	set msg "\'do\' statement label is defined here.  "
	if {$modified} {
	    selectText [lindex $doLine 1] [pos::nextLineStart $from]
	} else {
	    placeBookmark 0
	    goto [lindex $doLine 1]
	    append msg "Select \"Return To Bookmark\" for original location."
	}
	status::msg $msg
	return
    }
    # Still here?
    status::msg "No information available for \"${text}\""
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Indentation ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Fort::indentLine" --  ?-w <win>? ?<position "">?
 # 
 # ("Fort" mode)
 # 
 # Indentation Logic:
 # 
 # 1. Identify previous line
 # 
 #    (a) ignore comments and continuation lines
 #    (b) if current line is a CONTINUE that matches a DO, use the
 #        first corresponding DO as the previous line
 # 
 # 2. Find leading whitespace for previous line
 # 
 # 3. Increase whitespace if previous line starts a block, i.e.,
 # 
 #    (a) DO or WHILE loop
 #    (b) IF ... THEN 
 #    (c) ELSE
 # 
 # 4. Decrease whitespace if current line ends a block, i.e.,
 # 
 #    (a) ELSE || ENDIF || END IF || ENDDO || END DO
 #    (b) <linenum> CONTINUE matching a preceding DO
 #        (which is the same as 1(b), no?)
 # 
 #    or if previous line ends a DO loop on an executable statement, i.e.,
 # 
 #    (c) <linenum> (not CONTINUE) matching a preceding DO
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::indentLine {args} {
    
    global FortmodeVars
    
    variable commentCharOptions
    
    win::parseArgs w {pos ""}
    
    if {($pos eq "")} {
	set pos [getPos -w $w]
    }
    # Preliminaries
    set rowBegPos [pos::lineStart -w $w $pos]
    set rowEndPos [pos::lineEnd -w $w $pos]
    set offsetBeg [pos::diff -w $w $pos $rowEndPos]
    set thisLine  [getText -w $w $rowBegPos $rowEndPos]
    # Parse out the current line, and the set default values.  Each case
    # should (re)set them as needed.
    set parsedLine  [Fort::parseLine $thisLine]
    set commChar    [lindex $parsedLine 0]
    set label       [lindex $parsedLine 1]
    set contChar    [lindex $parsedLine 2]
    set statement   [lindex $parsedLine 4]
    set white       ""
    set adjust      0
    
    # Special cases first.
    if {([lsearch -exact $commentCharOptions $commChar] > -1)} {
	# This is a comment line.
	set label    ""
	set contChar ""
	switch -- $FortmodeVars(indentComments) {
	    "0" {
		set lwhite 1
	    }
	    "1" {
		set lwhite 5
	    }
	    "2" {
		set lwhite [string length [lindex $parsedLine 3]]
	    }
	}
    } elseif {($contChar ne " ") && ($contChar ne "")} {
	# This is a continuation line.  Use the indentation of the most
	# recent 'real' statement as the base, and then indent further.
	set parsed [Fort::parseLine [Fort::findLastLine -w $w $pos]]
	set white  [lindex $parsed 3]
	set adjust [expr {($FortmodeVars(indentationAmount) * 2)}]
    } elseif {[llength [set doLine [Fort::findDoLine -w $w $pos $label]]]} {
	# If there's a label and the label corresponds to a recent DO so use
	# the indentation for that matching DO statement.
	set white [lindex [Fort::parseLine [lindex $doLine 0]] 3]
    } else {
	# This statement must be a new line of code.
	set parsed [Fort::parseLine [Fort::findLastLine -w $w $pos]]
	set lwhite [string length [lindex $parsed 3]]
	# Increase the indent if the last statement started something special.
	set beginPat {^((if.+then)|(else(\s*if)?)|((while.+)?do))(\s|$)}
	if {[regexp -nocase -- $beginPat [lindex $parsed 4]]} {
	    incr lwhite $FortmodeVars(indentationAmount)
	}
	# Decrease the indent if this statement ends something special.
	set endPat {^((end\s*(if|do))|until|(else(\s*if)?))(\s|$)}
	if {[regexp -nocase -- $endPat $statement]} {
	    incr lwhite -$FortmodeVars(indentationAmount)
	}
    }
    
    # Now we have either an indentation amount (lwhite) or a string (white).
    if {[info exists lwhite]} {
	set white [string repeat " " $lwhite]
    } elseif {($adjust > 0)} {
	append white [string repeat " " $adjust]
    } elseif {($adjust < 0)} {
	set white [string range $white 0 end-$adjust]
    }
    set statement [string trimleft $statement]
    append replacement $commChar $label $contChar $white
    if {($replacement eq "")} {
	set replacement "      "
	set offsetBeg 0
    }
    set whiteEndPos [pos::math -w $w $rowEndPos - [string length $statement]]
    replaceText -w $w $rowBegPos $whiteEndPos $replacement
    # Now we attempt to replace the cursor where we found it.
    set newBegPos [pos::math -w $w [pos::lineEnd -w $w $rowBegPos] - $offsetBeg]
    if {[pos::compare -w $w $newBegPos < $rowBegPos]} {
	set newBegPos $rowBegPos
    } elseif {([string trim $statement] eq "")} {
        set newBegPos [pos::lineEnd -w $w $rowBegPos]
    }
    goto -w $w $newBegPos
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Fort::findLastLine" --  ?-w <win>? <position>
 # 
 # ("Fort" mode)
 # 
 # Find the first preceding non-comment, non-continuation line.
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::findLastLine {args} {
    
    win::parseArgs w pos
    
    set lastLine ""
    if {[pos::compare -w $w $pos <= [pos::lineEnd -w $w [minPos -w $w]]]} {
	return $lastLine
    }
    set pat {^[0-9 ][^\r\n]{4} [\t ]*[^\t ]+}
    set pos [pos::prevLineEnd -w $w $pos]
    set match [search -w $w -s -n -f 0 -r 1 -i 1 -- $pat $pos]
    if {[llength $match]} {
	set posBeg   [pos::lineStart -w $w [lindex $match 0]]
	set posEnd   [pos::lineEnd -w $w $posBeg]
	set lastLine [getText -w $w $posBeg $posEnd]
    }
    return $lastLine
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Fort::findDoLine" --  ?-w <win>? <position> <label>
 # 
 # ("Fort" mode)
 # 
 # Find the most recent "do" line that matches a given statement label.  If
 # it is found, return the entire line and the starting/ending line positions
 # containing it, otherwise return an empty list.  If the "label" is empty,
 # then we return immediately.
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::findDoLine {args} {
    
    win::parseArgs w pos label
    
    if {([set label [string trim $label]] eq "")} {
        return [list]
    }
    set lastDoLine ""
    # How far back should we search?
    set subPat {^[^cC*!][\t \w]*(subroutine|.*function|entry|program)[\t ]+(\w+)}
    set match  [search -w $w -n -s -f 0 -r 1 -m 0 -i 1 $subPat $pos]
    if {[llength $match]} {
	set posL [pos::lineStart -w $w [lindex $match 0]]
    } else {
	set posL [minPos -w $w]
    }
    # Search for previous 'do' line.
    append doPat {^[\t ]+do[\t ]+} $label {([^0-9]|$)}
    set pos [pos::prevLineEnd -w $w $pos]
    while {1} {
	set match [search -w $w -s -n -f 0 -r 1 -i 1 -l $posL $doPat $pos]
	if {![llength $match]} {
	    break
	}
	set posBeg [pos::lineStart -w $w [lindex $match 0]]
	set posEnd [pos::lineEnd -w $w $posBeg]
	set parsed [Fort::parseLine [getText -w $w $posBeg $posEnd]]
	if {([lindex $parsed 0] eq " ") && ([lindex $parsed 2] eq " ")} {
	    set lastDoLine [getText -w $w $posBeg $posEnd]
	    break
	}
    }
    if {($lastDoLine eq "")} {
        return [list]
    } else {
        return [list $lastDoLine $posBeg $posEnd]
    }
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Fortran Menu ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "fortranMenu" --
 # 
 # ("Fort" mode)
 # 
 # 'Dummy' proc required by AlphaTcl SystemCode.  We ensure that the mode has
 # been properly initialized -- this is only an issue if the Fortran menu has
 # been turned on globally.
 # 
 # --------------------------------------------------------------------------
 ##

proc fortranMenu {} {
    Fort::initializeMode
    ;proc fortranMenu {} {}
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Fort::buildMenu" --
 # 
 # ("Fort" mode)
 # 
 # Build the Fortran menu.
 # 
 # We use the same keyboard shortcuts defined for "Text > Shift Left/Right",
 # as determined in "internationalMenus.tcl".
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::buildMenu {} {
    
    global fortranMenu keyboard
    
    variable commentCharOptions
    
    switch -- $keyboard {
	"Brasil" -
	"Canadian - CSA" -
	"Canadian - French" -
	"Canadian - ISO" -
	"Croatian" -
	"Danish" -
	"Espa–ol - ISO" -
	"Finnish" -
	"German" -
	"Norwegian" -
	"Slovenian" -
	"Spanish" -
	"Swedish" -
	"Swiss French" -
	"Swiss German" {
	    set shiftLeftShortcut  ""
	    set shiftRightShortcut ""
	}
	"Flemish" -
	"French" -
	"French - numerical" -
	"Italian" {
	    set shiftLeftShortcut  "/("
	    set shiftRightShortcut "/)"
	}
	"Roman - JIS" {
	    set shiftLeftShortcut  "/\["
	    set shiftRightShortcut "/\]"
	}
	"Italian - Pro" {
	    set shiftLeftShortcut  "<O<B/8"
	    set shiftRightShortcut "<O<B/9"
	}
        default {
	    set shiftLeftShortcut  "<O/\["
	    set shiftRightShortcut "<O/\]"
        }
    }
    
    set menuList [list \
      [list Menu -n "fortranHelp" -p {Fort::menuProc} -m \
      [list "Fortran Home Page" "Fortran FAQ" "Fort Mode Help"]] \
      [list Menu -n "fortranComments" -p {Fort::menuProc} -m -c \
      $commentCharOptions] \
      "(-)" \
      "fortModeShifting" \
      "<E<S${shiftLeftShortcut}shiftLeft" \
      "<S<I${shiftLeftShortcut}shiftLeftSpace" \
      "<E<S${shiftRightShortcut}shiftRight" \
      "<S<I${shiftRightShortcut}shiftRightSpace" \
      "<O/BspecialBalance" \
      "(-)" \
      "<U/bcontinueLine" \
      "<U<B/btoggleContinuation" \
      "(-)" \
      "<U<B/NnextBlock" \
      "<U<B/PprevBlock" \
      "<U<B/SselectBlock" \
      "<B<O/IreformatBlock" \
      ]
    
    return [list "build" $menuList {Fort::menuProc -M "Fort"} {} $fortranMenu]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Fort::postBuildMenu" --
 # 
 # ("Fort" mode)
 # 
 # Called after the menu has been created, mark the current comment character
 # in the "Fortran > Fortran Comments" menu.  (Because "!" is included in the
 # list of options, the menu is built with the "-c" flag which prevents us
 # from including "!¥" in the original list of menu items)
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::postBuildMenu {} {
    
    global FortmodeVars fortranMenu
    
    variable commentCharOptions
    variable fortModeShifting
    
    foreach char $commentCharOptions {
	set markItem [expr {($FortmodeVars(commentCharacter) eq $char)}]
	markMenuItem -m "fortranComments" $char $markItem "¥"
    }
    markMenuItem $fortranMenu "fortModeShifting" $fortModeShifting "Ã"
    foreach item [list "Left" "LeftSpace" "Right" "RightSpace"] {
	enableMenuItem $fortranMenu "shift$item" $fortModeShifting
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Fort::menuProc" --  <menuName> <itemName>
 # 
 # ("Fort" mode)
 # ("f90"  mode)
 # 
 # Take care of all Fortran(90) Menu items.
 # 
 # --------------------------------------------------------------------------
 ##

proc Fort::menuProc {menuName itemName} {
    
    global FortmodeVars f90modeVars fortranMenu fortran90Menu
    
    variable fortModeShifting
    
    if {($menuName eq "fortranComments")} {
        set FortmodeVars(commentCharacter) $itemName
	prefs::modified FortmodeVars(commentCharacter)
	Fort::updatePreferences "commentCharacter"
	status::msg "The 'Fort' mode comment character is now '${itemName}'"
	return
    } elseif {($itemName eq "fortModeShifting")} {
	set fortModeShifting [expr {$fortModeShifting ? 0 : 1}]
	Fort::postBuildMenu
	status::msg "Shifting will\
	  [expr {$fortModeShifting ? "now" : "no longer"}] use\
	  Fort mode's special routine."
	return
    } elseif {($menuName eq $fortranMenu)} {
	# Since we don't use any fancy "requireOpenWindowHooks" or "activate"
	# hooks for this menu we have this check in case the Fortran Menu has
	# been turned on globally.
	if {([win::getMode] ne "Fort")} {
	    error "Cancelled -- \"[quote::Prettify $itemName]\"\
	      is only useful in 'Fort' mode."
	}
    } elseif {($menuName eq $fortran90Menu)} {
	# ...  in case the Fortran90 Menu has been turned on globally.
	if {([win::getMode] ne "f90")} {
	    error "Cancelled -- \"[quote::Prettify $itemName]\"\
	      is only useful in 'f90' mode."
	}
    }

    switch -- $itemName {
	"Fort Mode Help"    {package::helpWindow "Fort"}
	"Fortran FAQ"       {urlView "http://www.faqs.org/faqs/fortran-faq/"}
	"Fortran Home Page" {
	    if {([win::getMode] eq "f90")} {
		url::execute $f90modeVars(fortranHomePage)
	    } else {
		url::execute $FortmodeVars(fortranHomePage)
	    }
	}
	"f90 Mode Help"     {package::helpWindow "f90"}
	"nextBlock"         {paragraph::next}
	"prevBlock"         {paragraph::prev}
	"reformatBlock"     {paragraph::reformat}
	"selectBlock"       {paragraph::select}
	"shiftLeft"         {Fort::doShift -$FortmodeVars(indentationAmount)}
	"shiftLeftSpace"    {Fort::doShift -1}
	"shiftRight"        {Fort::doShift $FortmodeVars(indentationAmount)}
	"shiftRightSpace"   {Fort::doShift 1}
	default             {namespace eval ::Fort $itemName}
    }
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× f90 mode ×××× #
# 
# This is a separate mode for editing Fortran90 files.  Unlike the standard
# 'Fort' mode, it assumes a free-format editing syntax.  The only defined
# comment character is "!", which can appear anywhere in the line.
# 
# (See the notes in bug# 1794 regarding [regModeKeywords] limitations, which
# is the main reason we need two different modes, and why this one is named
# "f90" instead of "F90".  If that bug was resolved, it is possible that both
# modes could be defined as 'Fort' with a preference to toggle between fixed
# and free format editing, but that would still require some separate
# procedures for commenting, indentation, etc.)
# 
# We do piggy-back on procedures in the "Fort" namespace whenever possible.
# 

namespace eval f90 {
    
    variable initialized
    if {![info exists initialized]} {
        set initialized 0
    }
    variable commentCharacters
    array set commentCharacters [list \
      "General"         "!" \
      "Paragraph"       [list "! " "! " "! "] \
      "Box"             [list "!" 1 "!" 1 "!" 3] \
      ]
    
    # These procedures are shared by both modes.
    set sharedProcs [list "specialBalance" "continueLine" "carriageReturn" \
      "searchFunc" "MarkFile" "parseFuncs" "DblClick"]
    foreach procName $sharedProcs {
	;proc $procName {args} "return \[eval ::Fort::$procName \$args\]"
    }
    unset sharedProcs procName
}

## 
 # --------------------------------------------------------------------------
 # 
 # "f90::initializeMode" --
 # 
 # ("f90"  mode)
 # 
 # After everything in this file has been sourced, call the 'Fort' procedures
 # required to colorize and create the menu.  (Placing them here helps make
 # it clearer what is being called when the mode is loaded.)
 # 
 # --------------------------------------------------------------------------
 ##

proc f90::initializeMode {} {
    
    global f90modeVars
    
    variable initialized
    
    if {$initialized} {
        return
    }
    
    # Call this now, so that the rest can be "adds".
    regModeKeywords -e {!} -c $f90modeVars(commentColor) \
      -s $f90modeVars(stringColor) f90 {}
    # Define colors.
    Fort::colorizeFortran "f90"
    
    # Build the Fortran menu.
    menu::buildProc "fortran90Menu" {f90::buildMenu}
    menu::buildSome "fortran90Menu"
    
    # Make sure that we don't call this again.
    set initialized 1
    return
}

# ===========================================================================
#
# ×××× Key Bindings ×××× #
# 

# Shift left, right.

Bind    up   <sz>   {paragraph::prev 0 0}       f90
Bind  left   <sz>   {paragraph::prev 0 1}       f90
Bind  down   <sz>   {paragraph::next 0 0}       f90
Bind right   <sz>   {paragraph::next 0 1}       f90

# ===========================================================================
# 
# ×××× Preferences ×××× #
# 
# Some preferences which are also global will inherit those descriptions so
# there's no need to provide them here.
# 

# --- Comment preferences.

newPref var  prefixString       {! }    f90     {}
newPref var  commentsContinuation 1     f90     {} \
  [list "only at line start" "spaces allowed" "anywhere"] index

# --- Indentation preferences.

# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn     {1}     f90
# To always indent the contents of INTERFACE blocks, turn this item on||To
# never indent the contents of INTERFACE blocks, turn this item off
newPref flag indentInterfaceBlocks {0}   f90
# To always indent the contents of FUNCTION blocks, turn this item on||To
# never indent the contents of FUNCTION blocks, turn this item off
newPref flag indentFunctionBlocks {0}   f90
# To always indent the contents of MODULE blocks, turn this item on||To
# never indent the contents of MODULE blocks, turn this item off
newPref flag indentModuleBlocks {0}     f90
# To always indent the contents of PROGRAM blocks, turn this item on||To
# never indent the contents of PROGRAM blocks, turn this item off
newPref flag indentProgramBlocks {0}    f90
# To always indent the contents of SUBROUTINE blocks, turn this item on||To
# never indent the contents of SUBROUTINE blocks, turn this item off
newPref flag indentSubroutineBlocks {0} f90

newPref var  indentationAmount   3      f90     {} \
  [list "1" "2" "3" "4" "5" "6" "7" "8"] item

# --- Color preferences.

# The color for all basic Fortran keywords.
newPref color commandColor      {blue}  f90 {Fort::updatePreferences "f90"}
# The color for all keywords that start with a hash mark.
newPref color cPreprocessColor  {green} f90 {Fort::updatePreferences "f90"}
# The color for all comments.
newPref color commentColor      {red}   f90 {stringColorProc}
# The color for "bit" keywords such as "bit_size" "btest" "iand" etc.
newPref color functionColor     {none}  f90 {Fort::updatePreferences "f90"}
# The color for all "operator" keywords such as "eq" "ne" "lt" "le" etc.
newPref color operatorColor     {none}  f90 {Fort::updatePreferences "f90"}
# The color for all strings that are contained in double quotes.
newPref color stringColor       {none}  f90 {stringColorProc}

# --- Miscellaneous 'flag' preferences.

# To automatically mark new windows (if none have been previously saved) turn this
# item on||To never automatically mark new windows, turn this item off
newPref flag autoMark           {1}     f90

# --- Miscellaneous 'var' (other) preferences.

newPref var  fillColumn         {80}    f90
# This url will be opened by the "f90 > Fortran Home Page" menu item.
newPref url  fortranHomePage {http://www.fortran.com/} f90
newPref var  lineWrap           {0}     f90
# When this string appears in a commented line just behind the comment
# character, it will be recognized during File Marking routines.
newPref var  markTag            {}      f90
newPref var  wordBreak      {[\w.]+}    f90

# ===========================================================================
# 
# Categories of all f90 preferences, used by [prefs::dialogs::modePrefs].
# When the dialogues are actually built, there will most likely be added a
# Miscellaneous pane.  This happens whenever there are prefs which are not
# categorized.  (There's no need to set a "Miscellaneous" group entry,
# because this will always be built from scratch.)
# 

# Editing
prefs::dialogs::setPaneLists "f90" "Editing" [list \
  "autoMark" \
  "fillColumn" \
  "indentFunctionBlocks" \
  "indentInterfaceBlocks" \
  "indentModuleBlocks" \
  "indentProgramBlocks" \
  "indentSubroutineBlocks" \
  "indentationAmount" \
  "lineWrap" \
  "wordBreak" \
  ]

# Electrics
prefs::dialogs::setPaneLists "f90" "Electrics" [list \
  "indentOnReturn" \
]

# Comments
prefs::dialogs::setPaneLists "f90" "Comments" [list \
  "commentColor" \
  "commentsContinuation" \
  "prefixString"
  ]

# Colors
prefs::dialogs::setPaneLists "f90" "Colors" [list \
  "cPreprocessColor" \
  "commandColor" \
  "functionColor" \
  "operatorColor" \
  "stringColor" \
  ]

# These 'preferences' can never be changed by the user.
set f90modeVars(paragraphName)      "code block"
prefs::deregister "paragraphName"   "f90"

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Indentation ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "f90::correctIndentation" --  ?-w <win>? <position> ?<nextCharacter "">?
 # 
 # ("f90"  mode)
 # 
 # Indentation Logic:
 # 
 # 1. Identify previous line
 # 
 #    (a) ignore comments.
 #    (b) if current line is a CONTINUE or an END Do that matches a DO, use
 #        the first corresponding DO as the previous line.  In this routine,
 #        unlike [Fort::indentLine], 
 #        
 #            theta: do ...
 #        
 #        can be ended with
 #        
 #            end do theta
 # 
 # 2. Find leading whitespace for previous line
 # 
 # 3. Increase whitespace if previous line starts a block, i.e.,
 # 
 #    (a) DO or WHILE loop
 #    (b) IF ... THEN 
 #    (c) ELSE
 #    (d) FUNCTION|PROGRAM|SUBROUTINE if appropriate pref is turned on.
 # 
 # 4. Increase whitespace (x2) if previous line ended with the special & 
 #    continuation character.
 # 
 # 5. Decrease whitespace if current line ends a block, i.e.,
 # 
 #    (a) ELSE || ENDIF || END IF || ENDDO || END DO
 #    (b) END FUNCTION|PROGRAM|SUBROUTINE if appropriate pref is turned on.
 # 
 # 6. Decrease whitespace (x2) if continued previous line was itself 
 #    continued from the line that preceded it.
 # 
 # --------------------------------------------------------------------------
 ##

proc f90::correctIndentation {args} {
    
    global f90modeVars indentationAmount
    
    win::parseArgs w pos {next ""}
    
    # Preliminaries
    set rowBegPos [pos::lineStart -w $w $pos]
    set rowEndPos [pos::lineEnd -w $w $pos]
    set offsetBeg [pos::diff -w $w $pos $rowEndPos]
    set thisLine  [string trim [getText -w $w $rowBegPos $rowEndPos]]
    regexp -- {^[0-9]*} [string trim $thisLine] label1
    if {![regexp -- {^end\s*do\s+(\w+)\s*$} $thisLine -> label2]} {
	set label2 ""
    }
    
    # If there's a label and the label corresponds to a recent DO so use the
    # indentation for that matching DO statement.
    if {[llength [set doLine [f90::findDoLine -w $w $pos $label1]]]} {
	return [lindex [pos::toRowCol -w $w \
	  [text::firstNonWsPos -w $w [lindex $doLine 1]]] 1]
    } elseif {[llength [set doLine [f90::findDoLine -w $w $pos $label2]]]} {
	return [lindex [pos::toRowCol -w $w \
	  [text::firstNonWsPos -w $w [lindex $doLine 1]]] 1]
    }
    # No label with corresponding DO statement, so get more information. 
    set prevInfo1 [f90::findLastLine -w $w \
      [pos::prevLineEnd $rowBegPos]]
    set prevInfo2 [f90::findLastLine -w $w \
      [pos::prevLineEnd -w $w [lindex $prevInfo1 0]]]
    set prevLine1 [lindex $prevInfo1 2]
    set prevLine2 [lindex $prevInfo2 2]
    set lwhite    [lindex $prevInfo1 1]
    # If we have a previous line ...
    if {[pos::compare -w $w [lindex $prevInfo1 0] != $rowBegPos]} {
	# Increase indent if the preceding statement was something special.
	set beginBlocks [list {(if.+then)} {(else(\s*(if|where))?)} \
	  {((while.+)?do)} {(\w+:\s*do)} {(type\s*,)} {where\s*\([^\)]+\)}]
	foreach {prefName prefValue} [array get f90modeVars "indent*Blocks"] {
	    set beginBlockPat ""
	    if {$prefValue} {
	        regexp -- {^indent(.+)Blocks$} $prefName -> itemName
		append beginBlockPat "(" $itemName {(\s+\w+\([^\)]*\))?} ")"
		lappend beginBlocks $beginBlockPat
	    }
	}
	append beginPat {^[0-9\t ]*(} [join $beginBlocks "|"] {)(\s|$)}
	set ::testPat $beginPat
	set ::pLine $prevLine1
	if {[regexp -nocase -- $beginPat $prevLine1]} {
	    incr lwhite $indentationAmount
	} 
	# Increase indent if the last line did not terminate the command.
	if {[regexp -- {&(\s*(!.*)?)$} $prevLine1]} {
	    incr lwhite [expr {2 * $indentationAmount}]
	} 
	# Check to make sure that the previous command was not itself a
	# continuation of the line before it.
	if {[pos::compare -w $w \
	  [lindex $prevInfo1 0] != [lindex $prevInfo2 0]] \
	  && [regexp -- {&(\s*(!.*)?)$} $prevLine2]} {
	    incr lwhite [expr {-2 * $indentationAmount}]
	}
    } 
    # If we have a current line ...
    if {[regexp -- {^[0-9\t ]*[^\t ]} $thisLine]} {
	# Decrease the indent if this statement ends something special.
	set endBlocks [list "if" "do" "type" "where"]
	foreach {prefName prefValue} [array get f90modeVars "indent*Blocks"] {
	    set beginBlockPat ""
	    if {$prefValue} {
		regexp -- {^indent(.+)Blocks$} $prefName -> itemName
		lappend endBlocks $itemName
	    }
	}
	append endPat {^[0-9\t ]*} {(} \
	  {(end\s*(} [join $endBlocks "|"] {))} \
	  {|until|(else(\s*(if|where))?)} {)(\s|$)}
	if {[regexp -nocase -- $endPat $thisLine]} {
	    incr lwhite -$indentationAmount
	}
    } 
    # Now we return the level to the calling proc.
    return [expr {$lwhite > 0 ? $lwhite : 0}]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "f90::findLastLine" --  ?-w <win>? <position>
 # 
 # ("f90"  mode)
 # 
 # Find the first preceding non-comment line.
 # 
 # --------------------------------------------------------------------------
 ##

proc f90::findLastLine {args} {
    
    win::parseArgs w pos
    
    set pat {^[\t ]*[^\t\r\n !]}
    set posBeg [pos::math -w $w [pos::lineStart -w $w $pos] - 1]
    if {[pos::compare -w $w $posBeg < [minPos -w $w]]} {
	set posBeg [minPos -w $w]
    } 
    set lwhite 0
    if {![catch {search -w $w -s -f 0 -r 1 $pat $pos} match]} {
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

## 
 # --------------------------------------------------------------------------
 # 
 # "f90::findDoLine" --  ?-w <win>? <position> <label>
 # 
 # ("f90"  mode)
 # 
 # Find the most recent "do" line that matches a given statement label.  If
 # it is found, return the entire line and the starting/ending line positions
 # containing it, otherwise return an empty list.  Unlike [Fort::findDoLine]
 # we also look for labels like
 # 
 #     theta: do ...
 # 
 # that are ended with
 # 
 #     end do theta
 # 
 # If the "label" is empty, then we return immediately.
 # 
 # --------------------------------------------------------------------------
 ##

proc f90::findDoLine {args} {
    
    win::parseArgs w pos label
    
    if {([set label [string trim $label]] eq "")} {
	return [list]
    }
    set lastDoLine ""
    # How far back should we search?
    set subPat {^[^cC*!][\t \w]*(subroutine|.*function|entry|program)[\t ]+(\w+)}
    set match  [search -w $w -n -s -f 0 -r 1 -m 0 -i 1 $subPat $pos]
    if {[llength $match]} {
	set posL [pos::lineStart -w $w [lindex $match 0]]
    } else {
	set posL [minPos -w $w]
    }
    # Search for previous 'do' line.
    append doPat {(} \
      {^[\t ]*do[\t ]+} $label {([^0-9]|$)} \
      {)|(} \
      {^[\t ]*} $label {:[\t ]*do([\t ]|$)} \
      {)}
    set pos [pos::prevLineEnd -w $w $pos]
    set match [search -w $w -s -n -f 0 -r 1 -i 1 -l $posL $doPat $pos]
    if {[llength $match]} {
	set posBeg [pos::lineStart -w $w [lindex $match 0]]
	set posEnd [pos::lineEnd -w $w $posBeg]
	set lastDoLine [getText -w $w $posBeg $posEnd]
    }
    if {($lastDoLine eq "")} {
	return [list]
    } else {
	return [list $lastDoLine $posBeg $posEnd]
    }
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Fortran90 Menu ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "fortran90Menu" --
 # 
 # ("f90"  mode)
 # 
 # 'Dummy' proc required by AlphaTcl SystemCode.  We ensure that the mode has
 # been properly initialized -- this is only an issue if the Fortran90 menu
 # has been turned on globally.
 # 
 # --------------------------------------------------------------------------
 ##

proc fortran90Menu {} {
    f90::initializeMode
    ;proc fortran90Menu {} {}
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "f90::buildMenu" --
 # 
 # ("f90"  mode)
 # 
 # Build the Fortran90 menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc f90::buildMenu {} {
    
    global fortran90Menu
    
    set menuList [list \
      [list Menu -n "fortranHelp " -p {Fort::menuProc} -m \
      [list "Fortran Home Page" "Fortran FAQ" "f90 Mode Help"]] \
      "(-)" \
      "<O/BspecialBalance" \
      "<U/bcontinueLine" \
      "(-)" \
      "<U<B/NnextBlock" \
      "<U<B/PprevBlock" \
      "<U<B/SselectBlock" \
      "<B<O/IreformatBlock" \
      ]
    
    return [list "build" $menuList {Fort::menuProc -M "f90"} {} $fortran90Menu]
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Version History ×××× #
# 
# To Do:  work around grep failure for Unix-format tag files
# 
# 12/94 - fixed funcExpr, Fort::MarkFile search expressions
#       - changed comment character from 'C' to 'c' (should be case-insensitive!)
#       - added 'include' keyword
#       - added Fort::shiftRight and Fort::shiftLeft procs
# 05/95 - added Cmd-Dbl-Click handler
#       - added auto-indentation
# 08/95 - auto-indentation is finally speedy and robust
# 12/95 - more complete keyword set for F90 and HPF (from Tom Scavo)
# 12/95 - cpp keyword colorization (George Nurser <g.nurser@soc.soton.ac.uk>)
#         cmd-dbl-click supports cpp #include now
# 09/95 - fixed Fort::getPrev bug with numbered lines
#       - shiftLeft/Right revert to normal behavior on ill-formatted lines
# 10/95 - fixed Cmd-Dbl-Click handler to deal w/ new(?) tag file format and
#           improve performance (Fort::fortFindSub)
# 11/95 - added FortBreakLine
#         fixed case-sensitivity bug
# 01/96 - Fort::MarkFile no longer marks F90 "end subroutine ..." statements
#         more F90 keywords (will they never cease?)
# 01/96 - user-selectable comment and continuation characters
#         complete F90 keyword set (Thomas Bewley <bewley@rayleigh.stanford.edu>) 
#         F90 functions and comparison operators optionally colorized ( " " )
#         more complete set of C preprocessor commands colorized
#         fixed case-sensitivity problem in line-indent routines
# 01/96 - minor Fort::DblClick bug fix
# 04/97 - Coloring bug fixed.
# 08/97 - Updated for new system code.
# 02/05 - Improved [Fort::indentLine] implementation.
#         Updated for Tcl 8.0, put everything in Fort namespace.
#         Simplification of shiftLeft/Right bindings.
#         Replaced colorizing routines with [Fort::colorizeFortran].
#         Comment characters (re)set in [Fort::setCommentCharacters].
#         New [Fort::CommentLine] and [Fort::UncommentLine].
#         New [Fort::modePrefsDialog] procedure.
#         More sophisticated block shifting in [Fort::doShift].
#         New Fortran menu.
#         Shift Left/Right shortcuts adjusted for user's keyboard.
#         Simplified comment procedures, taking advantage of fixed-format.
#         New [Fort::carriageReturn] to deal with errant indent positions.
#         New [Fort::continueLine] procedure to handle menu item, binding.
#         Some preference renaming, re-organization.
#         We ensure that the "continueCharacter" pref is a single character.
#         New "continueCharacters" preference allows user to add more.
#         Minor cleanup of [Fort::MarkFile] and [Fort::DblClick].
#         New "Fortran > Fortran Help" submenu.
#         Menu items silently return when there are no open windows.
#         Menu items return when they are only appropriate in Fort mode.
#         Removed "symbolColor" preference and support -- it interfered with
#           using "*" as the comment character.
#         New "Fortran > Toggle Continuation" menu command.
#         New "wordBreak" preference includes dots.
#         Operator keywords are surrounded by dots.
#         "smartPaste" is now turned off by default.
#         Duplicate "precision" removed from keyword lists.
#         Labels can be included in column 1 (a rare occurance.)
#         Last fixes for old indentation scheme.
#         New indentation scheme is used by default.  (Older version is still
#           here mainly for reference.)
#         [Fort::carriageReturn] will indent current line when appropriate.
#         Command-Double-Click finds "DO" statement for current line label.
#         More minor [Fort::indentLine] fixes.
#         [Fort::parseLine] optionally accepts position, not just line text.
#         New "FortCompletions.tcl" file supports electric completions.
#         New [Fort::specialBalance] will select appropriate blocks of code.
#         Fort mode shifting can be toggled off and on.
#         "indentUsingSpacesOnly" is now a default Fort mode feature.
#         Duplicate "logical" removed from keyword lists.
#         New "electricDblLeftParen" preference for electric completions.
#         New [Fort::parseFuncs] procedure.
#         New [Fort::searchFunc] procedure (for keypad navigation.)
#         [Fort::MarkFile] cleanup.
#         [Fort::DblClick] cleanup.
#         Removed all "old indentation" code.  (Archived in the cvs.)
#         The "indentComments" preference is now a var, not a flag, with the
#           option to do nothing (which is the new default value.)
#         Hacky [Fort::colorComments] procedure, RFE# 1794 workaround.
#         New "Fortran Mode Help" file.
#         [Fort::selectBalance] also balances FUNCTION statements.
#         New "f90" mode handles free-format editing syntax.
# 

# ===========================================================================
# 
# .