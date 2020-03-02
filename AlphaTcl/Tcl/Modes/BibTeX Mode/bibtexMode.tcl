## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # BibTeX mode - an extension package for Alpha
 # 
 # FILE: "bibtexMode.tcl"
 #                                          created: 08/17/1994 {09:12:06 am}
 #                                      last update: 03/21/2006 {02:52:42 PM}
 #                               
 # Original by Tom Pollard. 
 # Major rewrite of most of BibTeX mode by Vince Darley.  
 # 
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta
 #         Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 #
 # Major re-organization of the bibtexMode.tcl file and the handling of
 # data definition lists by Craig Barton Upright.
 # 
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # Copyright (c) 1993-2006  Tom Pollard, Vince Darley, and Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ## 

# ===========================================================================
#
# ×××× Initialization of Bib mode ×××× #
# 

alpha::mode [list Bib BibTeX] 4.4.1 bibtexMode.tcl {
    *.bib *.inspec *.hollis *.isi *.marc *.oclc *.ovid *.refer 
} { 
    bibtexMenu indentUsingSpacesOnly
    bibToHtml bibToRefer bibConvert bibDelimited
} {
    # Mode initialization script, evaluated during Alpha's startup.
    addMenu bibtexMenu "¥282" Bib
} uninstall {
    foreach f {Data Entries File Menu Mode Prefs Search Strings} {
        set F [file join $HOME Tcl Modes "BibTeX Mode" bibtex${f}.tcl]
        catch {file delete $F}
    }
    catch {file delete [file join $HOME Tcl Modes "BibTeX Mode" bibVersionHistory.tcl]}
    catch {file delete [file join $HOME Tcl Completions BibCompletions.tcl]}
    catch {file delete [file join $HOME Tcl Completions "Bib Tutorial.bib"]}
    catch {file delete [file join $HOME Help "BibTeX Help"]}
    unset f F
} description {
    Supports the editing of LaTeX bibliography (.bib) files
} help {
    file "BibTeX Help"
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
}

# To make sure that this file gets loaded before support files.
proc bibtexMode.tcl {} {}

proc bibtexMenu {} {
    
    status::msg "Building BibTeX MenuÉ"
    global BibmodeVars
    # "Bib::listAllBibliographies" should first be called to ensure that the
    # "BibTeX Files" menu will be properly built (if desired) when the menu
    # is created for the first time.
    if {$BibmodeVars(buildFilesOnStart)} {
	Bib::listAllBibliographies
	status::msg "Building BibTeX MenuÉ"
    }
    bibtexMenu.tcl
    # Now we actually build the menu.
    menu::buildSome "bibtexMenu"
    status::msg "Building BibTeX MenuÉ complete"
    ;proc bibtexMenu {} {}
}

##
 # --------------------------------------------------------------------------
 # 
 # "namespace eval Bib" --
 # 
 # Set some variable specific to this mode, some of which are used by various
 # AlphaTcl SystemCode procedures (such as the paragraph regexps and the
 # "commentCharacters" array).
 # 
 # To do: more default variables could be added here, such as
 # 
 #     ::Bib::Abbrevs
 #     ::Bib::DefaultEntries
 #     ::Bib::DefaultFields
 #     ::Bib::escapeChar
 #     ::Bib::LastCyclePos
 #     ::Bib::PrefsInMenu1
 #     ::Bib::PrefsInMenu2
 #     ::Bib::TopPat
 #     ::Bib::TopPat1
 #     ::Bib::TopPat2
 #     ::Bib::TopPat3
 # 
 #     ::Bib::RqdFlds
 #     ::Bib::StringConnect
 #     ::Bib::UseBrace
 #     ::Bib::ValidFlds
 # 
 # but this will wait until a more complete overhaul of this package using
 # [variable] instead of [global] to access these variables.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval Bib {
    
    # Bib mode's definition of a paragraph
    variable startPara {^[\t ]*.*(\}|\"),[\t ]*$}
    variable endPara   {^[\t ]*(([a-zA-Z0-9\t ]+=.*)|((\}|\")[\t ]))*$}
    
    # "Edit > Comment..." menu items
    variable commentCharacters
    array set commentCharacters [list \
      "General"           "% " \
      "Paragraph"         [list "%% " " %%" " % "] \
      "Box"               [list "%" 2 "%" 2 "%" 3] \
      ]
    
    # Variables that need to be defined for the menu to be properly built.
    set defaultMenuVariables [list "CiteKeys" "DefaultFile" "DefaultTail" \
      "FileTails" "Files" "LastFile"]
    foreach var $defaultMenuVariables {
	variable $var
	if {![info exists $var]} {
	    set $var ""
	} 
    }
    unset defaultMenuVariables var
}

# ===========================================================================
#
# ×××× Bib mode preferences ×××× #
# 

# Removing old preferences
prefs::removeObsolete BibmodeVars(shortBibMenu) BibmodeVars(databaseMenuItems)

# Renaming old preferences
prefs::renameOld BibmodeVars(breakIntoLines) \
  BibmodeVars(wrappedFields)
prefs::renameOld BibmodeVars(segregateStrings) \
  BibmodeVars(segregateStringsDuringSort)
prefs::renameOld BibmodeVars(overwriteBuffer) \
  BibmodeVars(overwriteBufferDuringSort)
prefs::renameOld BibmodeVars(descendingYears) \
  BibmodeVars(sortByDescendingYears)

# ===========================================================================
#
# Standard preferences recognized by various Alpha procs
#

# The maximum width of each line in the field value.
newPref var  fillColumn        {77}    Bib
newPref var  prefixString      {% }    Bib
newPref var  wordBreak         {[\w:.-]+}  Bib
newPref var lineWrap           {1}     Bib
newPref var  commentsContinuation 1    Bib "" \
  [list "only at line start" "spaces allowed" "anywhere"] index
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn    1 Bib
# To automatically perform context relevant formatting after typing a left
# or right curly brace, turn this item on||To have the brace keys produce a
# brace without additional formatting, turn this item off
newPref flag electricBraces    0 Bib

# ===========================================================================
#
# Flag preferences
#

# Turn this item on to line up the = signs for all fields when
# reformatting||Turn this item off to leave = signs alone when reformatting
newPref flag alignEquals       {0}     Bib {Bib::updatePreferences}
# Turn this item on to automatically mark Bib mode files when they are first
# opened, and after any sorting procedure||Turn this item off to only mark
# Bib mode files when the menu item is selected
newPref flag autoMark          {1}     Bib {Bib::updatePreferences}
# Turn this item on to break all field values into separate lines when
# formatting, respecting the 'fillColumn' preference||Turn this item off to
# keep all field values in a single line when formatting, ignoring the
# 'fillColumn' preference
newPref flag wrappedFields     {1}     Bib {Bib::updatePreferences}
# Turn this item on to automatically create the list of recognized .bib
# files when the BibTeX menu is first built||Turn this item off to only
# create the list of recognized .bib files when called by a menu item
newPref flag buildFilesOnStart {0}     Bib {Bib::updatePreferences}
# Turn this item on to sort by year in descending order (most recent to
# oldest)||Turn this item off to sort by year in ascending order (oldest to
# most recent)
newPref flag sortByDescendingYears   {1}     Bib {Bib::updatePreferences}
# Turn this item on to use curly braces to delimit entries (otherwise
# parentheses are used)||Turn this item on to use parentheses to delimit
# entries (otherwise curly braces are used)
newPref flag entryBraces       {1}     Bib {Bib::updatePreferences}
# Turn this item on to use curly braces to delimit field values (otherwise
# quotation marks are used)||Turn this item on to use quotation marks to
# delimit field values (otherwise curly braces are used)
newPref flag fieldBraces       {1}     Bib {Bib::updatePreferences}
# Turn this item on to enable all fields as electric completions||Turn this
# item off to disable electric field completions
newPref flag fieldCompletions  {1}     Bib {Bib::updatePreferences}
# Turn this item on to include the full pathnames of files in dialogs and
# the BibTeX Files menu||Turn this item on to include only the tails of
# files in dialogs and the BibTeX Files menu.
newPref flag fullPathnames     {0}     Bib {Bib::updatePreferences}
# Turn this item on to set the Navigating, Searching, Formatting, Cite Key
# Lists and Databases items in their own submenus.  Otherwise some items are
# only available as dynamic menu items by holding down the "command"
# key||Turn this item off to set the Navigating, Searching, Formatting, Cite
# Key Lists and Dababases items in the main BibTeX menu
newPref flag hierarchicalMenu  {1}     Bib {Bib::updatePreferences}
# Turn this item on to ignore the presence of "extra" fields when validating
# entries||Turn this item off to report the presence of "extra" fields when
# validating entries.
newPref flag ignoreExtraFields {0}     Bib {Bib::updatePreferences}
# Turn this item on to enable some select LaTeX commands as electric
# completions||Turn this item on disable LaTeX electric completions
newPref flag latexCompletions  {1}     Bib {Bib::updatePreferences}
# Turn this item on to include @string definitions in the marks menu||Turn
# this item off to ignore @string definitions in the marks menu
newPref flag markStrings       {0}     Bib {Bib::updatePreferences}
# Turn this item on to allow sorts to replace the original window contents.
# (Otherwise they are written to a new window.)  This also allows searches
# within "Search Results" windows to over-write their contents||Turn this
# item off to never replace the original window with the results of sorting
newPref flag overwriteBufferDuringSort   {1}     Bib {Bib::updatePreferences}
# Turn this item on to collect all @string definitions together at the top
# of the file in sorts (otherwise sort alphabetically)||Turn this item off
# to sort @string definitions alphabetically (otherwise they are collected
# at the top of the menu
newPref flag segregateStringsDuringSort  {1}     Bib {Bib::updatePreferences}
# Turn this item on to automatically turn '...'  into '\ldots' as you
# type||Turn this item off to never turn '...'  into '\ldots' as you type
newPref flag smartDots         {0}     Bib {Bib::updatePreferences}
# Turn this item on to automatically turn ' or " into ` or `` or ' or '' as
# you type, depending upon the context||Turn this item off to never turn ' or "
# into ` or '' as you type
newPref flag smartQuotes       {0}     Bib {Bib::updatePreferences}
# Turn this item on to remove optional fields if they're empty when
# reformatting||Turn this item off to never remove optional fields if
# they're empty when reformatting
newPref flag zapEmptyFields    {0}     Bib {Bib::updatePreferences}
# Turn this item on to remove the pre-defined set of Bib Acronyms||Turn this
# item off to include the pre-defined set of Bib Acronyms
newPref flag unsetAcronymList  {0}     Bib {Bib::updatePreferences}
# Turn this item on to use UPPER CASE entry names in entry templates and
# reformatting|| Turn this item off to not use UPPER CASE entry names in
# entry templates and reformatting
newPref flag upperCaseEntries  {0}     Bib {Bib::updatePreferences}
# Turn this item on to use UPPER CASE field names in entry templates and
# reformatting|| Turn this item off to not use UPPER CASE field names in
# entry templates and reformatting
newPref flag upperCaseFields   {0}     Bib {Bib::updatePreferences}
# Turn this item on to use the path of the current window to list all
# bibliographies when building databases and indices, or to "Search All Bib
# Files"||Turn this item off to not use the path of the current window when
# listing bibliographies for databases, indices, or to "Search All Bib
# Files"
newPref flag useCurrentPath    {0}     Bib {Bib::updatePreferences}
# Turn this item on to use the Bib mode's "Search Paths" to create the list
# of bibliographies||Turn this item off to not use the Bib mode's "Search
# Paths to create the list of bibliographies
newPref flag useSearchPaths    {1}     Bib {Bib::updatePreferences}
# Turn this item on to use all open windows to create the list of
# bibliographies||Turn this item off to not use all open windows to create
# the list of bibliographies
newPref flag useOpenWindows    {0}     Bib {Bib::updatePreferences}
# Turn this item on to look in the .aux file of the current TeX file window
# to list bibliographies.  Only used when TeX mode procedures need to create
# the list||Turn this item off to not look in the .aux file of the current
# TeX file window to list bibliographies.  Only used when TeX mode
# procedures need to create the list
newPref flag useTexPaths       {0}     Bib {Bib::updatePreferences}

if {(${alpha::macos} != 1)} {
    # Turn this item on to use 'kpsewhich' to find bibliographies.
    # ||Turn this item off to not use 'kpsewhich' to find bibliographies
    newPref flag useKpsewhich  {0}     Bib {Bib::updatePreferences}
}

# The preference "useSearchPaths" was previously named "useModePaths", but
# this does not seem intuitive ...  If the preference was previously set,
# we'll quietly transfer it and the delete the old pref.

prefs::renameOld BibmodeVars(useModePaths) BibmodeVars(useSearchPaths)

# ===========================================================================
#
# Variable preferences
# 

# Bib mode initialisations:
set Bib::escapeChar "\\"

# These will be included in "Fields" menu items, colorized by the Field
# Color, and used in completions.
newPref var addFields         {}      Bib {Bib::updatePreferences}
# Extra LaTeX commands recognized by Bib mode for colorizing and completions.
# Do not include the leading \ backslash.
newPref var addTeXCommands    {emph underline} Bib {Bib::updatePreferences}
# These fields will be passed through the Capitalization routine during
# reformatting.
newPref var autoCapFields     [list "address" "author" "editor" "journal" \
  "language" "publisher"] Bib
# These words will only be capitalized in Auto Cap Field texts if they
# appear at the start of a clause.
newPref var autoCapForceLower [list \
  "a" "an" "and" "by" "for" "in" "into" "of" "on" "or" "the" "to"]  Bib
# Any word starting with the first element of the regexp pair will be
# substituted for the second element during the capitalization routine.
newPref var autoCapSpecialPatterns [list \
  {^usa$ \{USA\}} {^dimaggio DiMaggio} {m(a?)cC M\\1cC} \
  {m(a?)cd M\\1cD} {m(a?)cw M\\1cW}] Bib
# Bibliography Indices and Databases can be very useful for command double
# clicking and searching, but must occasionally be rebuilt.  This
# preference allows you to cancel rebuilding.
newPref var bibAutoIndex      {1}     Bib "" [list "Never make index" \
  "Ask user when it is necessary" "Always remake when necessary"] index
if {[set tcl_platform(platform)] == "windows"} {
    # The Cycle Left/Right bindings allow you to change either the current
    # field name or entry type to another related item.
    newPref binding cycleLeft  "<O<B/," Bib "" "Bib::cycleList -1"
    newPref binding cycleRight "<O<B/." Bib "" "Bib::cycleList  1"
} else {
    newPref binding cycleLeft  "<U<I/," Bib "" "Bib::cycleList -1"
    newPref binding cycleRight "<U<I/." Bib "" "Bib::cycleList  1"
}
# The "BibTeX Home Page" menu item will send this url to your browser. 
# While the default is for Vince Darley's Macintosh port of the BibTeX
# application, this preference can be set to any url that you commonly use
# when editing .bib files.
newPref url homePage {http://www.santafe.edu/~vince/MacBibTeX.html} Bib
# Define the indentation string for field names.
newPref var indentString      {   }   Bib "Bib::setBibIndent;#"
# Define standard abbreviations (which we avoid surrounding with
# delimiters) that do not appear in @string entries.
newPref var stdAbbrevs {jan feb mar apr may jun jul aug sep oct nov dec} Bib "Bib::setBibAbbrevs;#"

# Set lists of flag preferences which can be changed in the menu.

set Bib::PrefsInMenu1 [list \
  "hierarchicalMenu"            \
  "(-)"                         \
  [menu::itemWithIcon "\(entries,Fields" 84] \
  "entryBraces"                 \
  "fieldBraces"                 \
  "upperCaseEntries"            \
  "upperCaseFields"             \
  "(-)"                         \
  [menu::itemWithIcon "\(electrics" 84] \
  "fieldCompletions"            \
  "latexCompletions"            \
  "smartDots"                   \
  "smartQuotes"                 \
  "(-)"                         \
  [menu::itemWithIcon "\(formatting" 84] \
  "autoCapitalizationÉ"         \
  "alignEquals"                 \
  "wrappedFields"               \
  "zapEmptyFields"              \
  "(-)"                         \
  [menu::itemWithIcon "\(validating" 84] \
  "ignoreExtraFields"           \
  "(-)"                         \
  [menu::itemWithIcon "\(sorting" 84] \
  "overwriteBufferDuringSort"   \
  "sortByDescendingYears"       \
  "segregateStringsDuringSort"  \
  "(-)"                         \
  [menu::itemWithIcon "\(fileMarking" 84] \
  "autoMark"                    \
  "markStrings"                 \
  "(-)"                         \
  "bibModeHelp"                 \
  ]

# This list is used in the "BibTeX Files" menu.

set Bib::PrefsInMenu2 [list \
  [menu::itemWithIcon "\(bibtexFileList" 84] \
  "fullPathnames"               \
  "buildFilesOnStart"           \
  "(-)"                         \
  [menu::itemWithIcon "\(fileListPaths" 84] \
  "useCurrentPath"              \
  "useSearchPaths"              \
  "useOpenWindows"              \
  "useTexPaths"                 \
  ]

if {[info exists BibmodeVars(useKpsewhich)]} {
    lappend Bib::PrefsInMenu2 "useKpsewhich"
} 

# These are some expansions of standard abbreviations.

array set Bib::StringConnect {
    jan "January"
    feb "February"
    mar "March"
    apr "April"
    may "May"
    jun "June"
    jul "July"
    aug "August"
    sep "September"
    oct "October"
    nov "November"
    dec "December"
}

# ===========================================================================
#
# Colorization setup
#

# The color of all text following the % symbol.
newPref color commentColor      {red}       Bib {stringColorProc}
# The color of entries following the @ symbol.
newPref color entryColor        {blue}      Bib {Bib::updatePreferences}
# The color of all defined fields
newPref color fieldColor        {blue}      Bib {Bib::updatePreferences}
# The color of all text contained within double quotes.
newPref color stringColor       {green}     Bib {stringColorProc}
# The color of special LaTeX symbols, such as $, &, etc.
newPref color symbolColor       {red}       Bib {Bib::updatePreferences}

regModeKeywords                         \
  -e {%}                                \
  -c $BibmodeVars(commentColor)         \
  -s $BibmodeVars(stringColor)          \
  Bib {}

# ===========================================================================
# 
# Categories of all BibTeX preferences, used by [prefs::dialogs::modePrefs].
# When the dialogues are actually built, there will most likely be added a
# Miscellaneous pane.  This happens whenever there are prefs which are not
# categorized.  (There's no need to set a "Miscellaneous" group entry,
# because this will always be built from scratch.)
# 

# Editing
prefs::dialogs::setPaneLists "Bib" "Editing" [list \
  "fillColumn" \
  "wordBreak" \
  "lineWrap"  \
  ]

# Electrics
prefs::dialogs::setPaneLists "Bib" "Electrics" [list \
  "cycleLeft" \
  "cycleRight" \
  "electricBraces" \
  "fieldCompletions" \
  "indentOnReturn" \
  "latexCompletions" \
  "smartDots" \
  "smartQuotes" \
  ]

# Electrics
prefs::dialogs::setPaneLists "Bib" "Navigation" [list \
  "autoMark"                    \
  "markStrings"                 \
  "overwriteBufferDuringSort"   \
  "sortByDescendingYears"       \
  "segregateStringsDuringSort"  \
  ]

# Entries and Fields
prefs::dialogs::setPaneLists "Bib" "Entries and Fields" [list \
  "addFields" \
  "entryBraces" \
  "fieldBraces" \
  "indentString" \
  "upperCaseEntries" \
  "upperCaseFields"  \
  ]

# Formatting and Validating
prefs::dialogs::setPaneLists "Bib" "Formatting, Validating" [list \
  "autoCapFields" \
  "alignEquals" \
  "autoCapForceLower" \
  "autoCapSpecialPatterns" \
  "ignoreExtraFields" \
  "stdAbbrevs" \
  "wrappedFields" \
  "zapEmptyFields"  \
  ]

# BibTeX Files and Databases
prefs::dialogs::setPaneLists "Bib" "BibTeX Files, Databases" [list \
  "bibAutoIndex" \
  "buildFilesOnStart" \
  "fullPathnames" \
  "unsetAcronymList" \
  "useCurrentPath" \
  "useKpsewhich" \
  "useOpenWindows" \
  "useSearchPaths" \
  "useTexPaths"  \
  ]

# Comments
prefs::dialogs::setPaneLists "Bib" "Comments" [list \
  "commentColor" \
  "commentsContinuation" \
  "prefixString" \
  ]

# Colors
prefs::dialogs::setPaneLists "Bib" "Colors" [list \
  "addTeXCommands" \
  "commentColor" \
  "entryColor" \
  "fieldColor" \
  "stringColor" \
  "symbolColor" \
  ]

# Deregistered preferences will not be presented in the dialog.
prefs::deregister "autoCapFields"           "Bib"
prefs::deregister "autoCapForceLower"       "Bib"
prefs::deregister "autoCapSpecialPatterns"  "Bib"
prefs::deregister "hierarchicalMenu"        "Bib"
prefs::deregister "unsetAcronymList"        "Bib"

# ===========================================================================
# 
# Entry Pref Connect
# 
# When the user defines custom fields for an entry, a new pref is created
# called custom<Entry>, as in customArticle, customInCollecton, etc.  This
# procedure simply transforms entry names.
# 
# When going backwards, from pref to entry, the null string will be
# returned if the "text" was not of the form customEntryName.  The
# "userCustomOnly" argument will return the entryName only if the
# preference is not a default entry item (1), or IS a default entry (-1).
# 

proc Bib::entryPrefConnect {text {prefToEntry 0} {userCustomOnly 0}} {
    
    global BibmodeVars Bib::RqdFlds
    
    if {!$prefToEntry} {
	# Transform <entryName> to custom<EntryName>.
	set capFirst        [string toupper [string index $text 0]]
	set customEntryName [concat custom$capFirst[string range $text 1 end]]
	return $customEntryName
    } else {
	# Transform custom<EntryName> to <entryName>
	if {![regsub {custom} $text {} entryName]} {
	    # Not of the form customEntryName.
	    return ""
	} else {
	    set lowFirst  [string tolower [string index $entryName 0]]
	    set entryName [concat $lowFirst[string range $entryName 1 end]]
	    if {$userCustomOnly == 0} {
		# Return all entry names
		# return only if "entryName" is a user defined entry.
		return $entryName
	    } elseif {$userCustomOnly == 1 && ![info exists Bib::RqdFlds($entryName)]} {
		# Return only if "entryName" is a user defined entry.
		return $entryName
	    } elseif {$userCustomOnly == 2 && [info exists Bib::RqdFlds($entryName)]} {
		# Return only if "entryName" is a NOT a user defined entry.
		return $entryName
	    } else {
		return ""
	    }
	}
    } 
}

# ===========================================================================
# 
# ×××× Preliminaries ×××× #
# 
# Set the quote characters for quoted entries / fields based on the values
# of the preferences "entryBraces" and "fieldBraces", and the "Bib::Indent"
# string.
# 

proc Bib::setBibEntryDelims {} {

    global BibmodeVars Bib::OpenEntry Bib::CloseEntry
    
    if {$BibmodeVars(entryBraces)} {
        set Bib::OpenEntry  "\{" ; set Bib::CloseEntry "\}" 
    } else {
        set Bib::OpenEntry  "(" ; set Bib::CloseEntry ")"
    }
}

proc Bib::setBibFieldDelims {} {
    
    global BibmodeVars Bib::OpenQuote Bib::CloseQuote
    
    if {$BibmodeVars(fieldBraces)} {
        set Bib::OpenQuote  "\{" ; set Bib::CloseQuote "\}" 
    } else {
        set Bib::OpenQuote  {"} ; set Bib::CloseQuote {"}
    }
}

proc Bib::setBibIndent {} {
    
    global BibmodeVars Bib::Indent
    
    set Bib::Indent $BibmodeVars(indentString)
    regsub {\\t} [set Bib::Indent] {   } Bib::Indent
}

# Call these now.

Bib::setBibEntryDelims
Bib::setBibFieldDelims
Bib::setBibIndent

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Data Definitions ×××× #
# 
# Define the data arrays that contain the names of the required, optional,
# and preferred fields for each entry type.
#
# The index names of the Bib::RqdFlds() array _define_ the valid entry
# types recognized by the program.  The Bib::OptFlds() array is used for
# validation of entries.
#

set Bib::RqdFlds(article)         {author title journal year} 
set Bib::OptFlds(article)         {volume number pages month note}

# An example of how to assign default entry fields using the Bib::MyFlds() array:
# 
# set Bib::MyFlds(article) {author title journal volume pages year note} 
# 
# (Now largely obsolete, since entry fields, as well as new entries can
# be added through the menu.  All of the Bib::MyFlds() code remains,
# however, for back compatibility...  Even so, this is NOT advertised!!!)
# 

set Bib::RqdFlds(book)            {author title publisher year} 
set Bib::OptFlds(book)            {editor volume number series address edition month note}

set Bib::RqdFlds(booklet)         {title} 
set Bib::OptFlds(booklet)         {author howpublished address month year note}

set Bib::RqdFlds(conference)      {author title booktitle year} 
set Bib::OptFlds(conference)      {editor volume number series pages organization publisher address month note}

set Bib::RqdFlds(inBook)          {author title chapter publisher year} 
set Bib::OptFlds(inBook)          {editor pages volume number series address edition month type note}

set Bib::RqdFlds(inCollection)    {author title booktitle publisher year} 
set Bib::OptFlds(inCollection)    {editor volume number series type chapter pages address edition month note}

set Bib::RqdFlds(inProceedings)   {author title booktitle year} 
set Bib::OptFlds(inProceedings)   {editor volume number series pages organization publisher address month note}

set Bib::RqdFlds(manual)          {title} 
set Bib::OptFlds(manual)          {author organization address edition year month note}

set Bib::RqdFlds(mastersThesis)   {author title school year} 
set Bib::OptFlds(mastersThesis)   {address month note type}

set Bib::RqdFlds(misc)            {} 
set Bib::OptFlds(misc)            {author title howpublished year month note}

set Bib::RqdFlds(phdThesis)       {author title school year} 
set Bib::OptFlds(phdThesis)       {address month type note}

set Bib::RqdFlds(proceedings)     {title year} 
set Bib::OptFlds(proceedings)     {editor volume number series publisher organization address month note}

set Bib::RqdFlds(string)          {} 
set Bib::OptFlds(string)          {}

set Bib::RqdFlds(techReport)      {author title institution year} 
set Bib::OptFlds(techReport)      {type number address month note}

set Bib::RqdFlds(unpublished)     {author title note} 
set Bib::OptFlds(unpublished)     {year month}

# ===========================================================================
# 
# Bib::customEntryList
# 
# Return the updated list of custom entries, those that now have defined
# preferences.  Used in Bib::setBibcmds and some menu items.  With no
# argument, return all entries with customEntryName prefs.  With an
# argument of 1, return only those that are user defined.  With an argument
# of -1, return only those that are NOT use defined.
# 

proc Bib::customEntryList {{userCustomOnly 0}} {
    
    global BibmodeVars
    
    # We'll kill this right now if there aren't any.
    if {![regexp {.custom} [array names BibmodeVars]]} {return ""} 
    # Include all of the customEntryName preferences.
    set entriesWithPrefs ""
    foreach pref [array names BibmodeVars] {
        if {[regexp {custom.} $pref]} {
            set entryName [Bib::entryPrefConnect $pref 1 $userCustomOnly]
            if {$entryName != ""} {lappend entriesWithPrefs $entryName} 
        } 
    }
    return [lsort $entriesWithPrefs]
}

# ===========================================================================
# 
# Define an array of flags indicating whether the data a given field type
# should be quoted.  The actual characters used to quote the field are
# given by 'Bib::OpenQuote' and 'Bib::CloseQuote', which are set by the
# routine 'bibFieldDelims' according to the flag $fieldBraces.
#
# Note that the index names of the Bib::UseBrace() array _define_ the
# valid field types recognized by the program.  The preference
# "addFields" will be added to the names in this array for the menu, and
# completions.
#

array set Bib::UseBrace {

    "address"       1
    "author"        1
    "booktitle"     1
    "chapter"       0
    "city"          1
    "crossref"      1
    "edition"       1
    "editor"        1
    "howPublished"  1
    "institution"   1
    "journal"       1
    "key"           1
    "language"      1
    "month"         1
    "note"          1
    "number"        0
    "organization"  1
    "pages"         1
    "publisher"     1
    "school"        1
    "series"        1
    "title"         1
    "type"          1
    "volume"        0
    "year"          0
}

# ===========================================================================
# 
# Default values for specific fields.  
# 
# If users found their way here, they could add more of their own!  This
# mainly serves to ensure that there is at least one element of the
# Bib::DefFldVal array.  Currently no way to set default values through
# the menu; it must take place here or in a BibPrefs.tcl file.
#

set Bib::DefFldVal(language) "german"

# ===========================================================================
# 
# Set Keyword Lists
# 
# Create the list(s) of all keywords for completions and colors, and the
# list of entries and fields to be used by the menus.
# 
# These are crucial procs which set the lists used by most of the menu
# items !!!  Most of these variables do not exist yet -- we make them
# global, and then define them.  This way the lists can be reset only once,
# and then called by the various procedures / menu items.
# 
# Note: In general, only "Bib::updatePreferences' should be calling these
# procs, which itself is called whenever keywords are changed through
# either the preferences or the menu items.  Also called by "Bib::flagFlip"
# when completion preferences are changed, or the proc 'Bib::updateMyFld"
# (which would only be used in a "BibPrefs.tcl" file).
# 
# The key to making all of this work, by the way, is to first set an array,
# and then define a list based on [array names ...].  Thus
# Bib::RqdFlds(myEntry) (for example) can be (re)set repeatedly, but will
# only be included once in the list of entries.  In other cases, variables
# are first be set to "" and then redefined.
# 

# ===========================================================================
# 
# Create the list of all abbrevs, which we avoid surrounding with braces. 
#

proc Bib::setBibAbbrevs {} {
    
    global BibmodeVars Bib::Abbrevs

    foreach abbrev $BibmodeVars(stdAbbrevs) {
        lappend Bib::Abbrevs [string tolower $abbrev]
    }
}

# ===========================================================================
# 
# Create the list of all entries.
#

proc Bib::setBibEntries {} {
    
    global BibmodeVars Bib::RqdFlds Bib::OptFlds Bib::MyFlds
    
    # Entries:
    global Bib::DefaultEntries
    global Bib::ValidFlds
    global Bib::EntryNameConnect
    global Bib::MyFldEntries
    global Bib::Entries

    # "Bib::DefaultEntries" will only contain the entries defined in this file. 
    # (This could be reset in a BibPrefs.tcl file -- see the note below.)
    set Bib::DefaultEntries [lsort [array names Bib::RqdFlds]]

    # Create the valid fields array.
    foreach entryName [set Bib::DefaultEntries] {
        set Bib::ValidFlds($entryName) [concat \
          [set Bib::RqdFlds($entryName)] [set Bib::OptFlds($entryName)]]
    }

    # Connect entryname to entryName.  Used in formatting and validating.
    foreach entryName [set Bib::DefaultEntries] {
        set Bib::EntryNameConnect([string tolower $entryName]) $entryName
    }

    set Bib::MyFldEntries [lsort [array names Bib::MyFlds]]

    set extraEntries ""
    foreach pref [array names BibmodeVars] {
        set entryName [Bib::entryPrefConnect $pref 1 1]
        if {$entryName != ""} {lappend extraEntries $entryName} 
    }
    set Bib::Entries [lsort [concat [set Bib::DefaultEntries] $extraEntries]]

    # Make sure that Bib::MyFlds() names are included ...  Note that these cannot
    # be edited through the "Default Entry Fields" menu.
    foreach myFldExtra [set Bib::MyFldEntries] {
        if {[lsearch [set Bib::Entries] $myFldExtra] == "-1"} {
            lappend Bib::Entries $myFldExtra
        } 
    }
    set Bib::Entries [lunique [set Bib::Entries]]
    foreach entry [set Bib::Entries] {lappend entryList "@$entry"}

    regModeKeywords -a -k $BibmodeVars(entryColor) Bib $entryList
    
    # We add "unknownEntry" et al, used by the conversion packages.  We
    # color them red to alert the user that they should be changed.
    regModeKeywords -a -k {red} Bib [list unknownEntry @unknownEntry]
    # CUSTOM ENTRIES (lists used in building menus, and some menu items) :
    
    global Bib::CustomEntryList
    global Bib::CustomEntryList1
    global Bib::CustomEntryList2

    # The list of entries with a customEntryName preference.
    set Bib::CustomEntryList   [Bib::customEntryList  ]
    # The same list, but only if these are not standard entries.
    set Bib::CustomEntryList1  [Bib::customEntryList 1]
    # The same list, but only if these ARE standard entries.
    set Bib::CustomEntryList2  [Bib::customEntryList 2]

}

# ===========================================================================
# 
# Create the list of all fields.
#

# "Bib::DefaultFields" will only contain the fields defined in this file.
set Bib::DefaultFields [lsort [array names Bib::UseBrace]]

proc Bib::setBibFields {} {
    
    global BibmodeVars Bib::DefaultFields Bib::UseBrace Bib::DefFldVal
    
    # Fields:
    global Bib::Fields
    global Bib::FieldDefs
    
    # Note that the global variable "Bib::DefaultFields" contains only the
    # default fields defined in this file, and never changes.
    set Bib::Fields [lsort [concat [set Bib::DefaultFields] $BibmodeVars(addFields)]]
    set Bib::Fields [lunique [set Bib::Fields]]

    # We add "unknownEntry" et al, used by the conversion packages.  We
    # color them red to alert the user that they should be changed.
    foreach item [list "" A B C D E F G H I J K L M N O P Q R S T U V \
      W X Y Z 1 2 3 4 5 6 7 8 9 0] {
	lappend customFieldList customField${item}
    }
    regModeKeywords -a -k {red} Bib $customFieldList
    regModeKeywords -a                                                  \
      -i "$" -i "^" -i "_" -i "~" -i "#" -i "&"                         \
      -I $BibmodeVars(symbolColor)                                      \
      -k $BibmodeVars(fieldColor) Bib [set Bib::Fields]
    
    # And now default field values (probably rarely if ever used) :
    set Bib::FieldDefs [lsort [array names Bib::DefFldVal]]
}

# ===========================================================================
# 
# Create the list of all TeX commands used for colorizing and completions.
#

proc Bib::setBibTeXCommandsList {} {
    
    global BibmodeVars 
    
    regModeKeywords -a -m {\\} -k $BibmodeVars(entryColor) Bib {}

    # LaTeX Commands: (for completions list). This is also used by
    # "checkKeywords".
    
    global Bib::TeXCommandsList Bib::TextAbbrev
    
    set BibTeXCommands {
         ldots textbf textit textmd textnormal textrm textsc textsf textsl
         texttt textup
    }
    set Bib::TextAbbrev {bf it md normal rm sc sf sl tt up}

    set Bib::TeXCommandsList [lsort [concat \
      $BibTeXCommands $BibmodeVars(addTeXCommands) [set Bib::TextAbbrev]]]
    set Bib::TeXCommandsList [lunique [set Bib::TeXCommandsList]]
    
}

# ===========================================================================
# 
# Create the list of all commands used in word completions.
#

proc Bib::setBibcmds {{refresh 0}} {
    
    global BibmodeVars Bib::Entries Bib::Fields Bib::TeXCommandsList

    # Bib Command Completions:
    global Bibcmds
    
    # Add '@' to all of the entries.
    foreach entry [set Bib::Entries] {
	if {$BibmodeVars(upperCaseEntries)} {
	    lappend entryList [string toupper $entry] @[string toupper $entry]
	} else {
	    lappend entryList [string tolower $entry] @[string tolower $entry] \
	      $entry @$entry 
	}
    }
    # Only adding fields to completions list if "fieldCompletions" is on.
    if {!$BibmodeVars(fieldCompletions)} {
        set BibFieldCmds ""
    } elseif {$BibmodeVars(upperCaseFields)} {
	set BibFieldCmds [string toupper [set Bib::Fields]]
    } else {
	set BibFieldCmds [concat [set Bib::Fields] \
	  [string tolower [set Bib::Fields]]]
    }
    # Only adding latex commands list if "latexCompletions" is on.
    if {!$BibmodeVars(latexCompletions)} {
        set BibTeXCommandCmds ""
    } else {
        set BibTeXCommandCmds [set Bib::TeXCommandsList]
    } 
    
    set Bibcmds [lsort [concat $entryList $BibFieldCmds $BibTeXCommandCmds]]
    set Bibcmds [lunique $Bibcmds]
    
    # LaTeX special symbols
    regModeKeywords -a                  \
      -i "$" -i "^" -i "_"              \
      -i "~" -i "#" -i "&"              \
      -I $BibmodeVars(symbolColor)      \
      Bib {}
    if {$refresh} {refresh}
}

# Call all of these now.

Bib::setBibAbbrevs
Bib::setBibEntries
Bib::setBibFields
Bib::setBibTeXCommandsList
Bib::setBibcmds

#============================================================================
# 
# ×××× Case Sensitivity ×××× #
# 

#============================================================================
# 
# Is Valid Entry
# 
# A way of dealing with case-sensitivity issues.
# 

proc Bib::isValidEntry {entryName} {
    
    global Bib::Entries
    
    set entries [string tolower [set Bib::Entries]]
    if {[set idx [lsearch $entries [string tolower $entryName]]] != "-1"} {
        return [lindex [set Bib::Entries] $idx]
    } else {
        error "Not a recognized entry"
    }
}

#============================================================================
# 
# Is Valid Field
# 
# A way of dealing with case-sensitivity issues.
# 

proc Bib::isValidField {fieldName} {
    
    global Bib::Fields
    
    set fields [string tolower [set Bib::Fields]]
    if {[set idx [lsearch $fields [string tolower $fieldName]]] != "-1"} {
	return [lindex [set Bib::Fields] $idx]
    } else {
	error "Not a recognized field"
    }
}

#============================================================================
# 
# Creating a pre-defined set of Bib Acronyms.  These can be removed by
# setting the "unsetAcronymList" preference.
# 

array set Bib::AcronymsSet {

    "ny"     "New York"
    "sf"     "San Francisco"
    "wdc"    "Washington D.C."

    "ajs"    "American Journal of Sociology"
    "ars"    "Annual Review of Sociology"
    "asr"    "American Sociological Review"
    "ts"     "Theory and Society"

    "cup"    "Cambridge University Press"
    "hup"    "Harvard University Press"
    "oup"    "Oxford University Press"
    "pup"    "Princeton University Press"
    "sup"    "Stanford University Press"
    "ucp"    "University of Chicago Press"
    "yup"    "Yale University Press"

    "up"     "University Press"
}

# These are not yet defined as completions -- they're simply a list that we
# can add (or remove) using the "Bib Mode Acronyms" menu.  We only add them
# if the preference "unsetAcronymList" has not been set to 1, and if the
# acronym has not already been (re)defined in "arrdefs.tcl"

if {!$BibmodeVars(unsetAcronymList)} {
    foreach acronym [array names Bib::AcronymsSet] {
        if {![info exists Bib::Acronyms($acronym)]} {
            set Bib::Acronyms($acronym) [set Bib::AcronymsSet($acronym)]
        } 
    }
    unset -nocomplain acronym
}

# ===========================================================================
# 
# Update Bib::MyFlds array
# 
# For those who want to define the Bib::MyFlds array in a "BibPrefs.tcl"
# file, or to teach Bib mode new entries for validation.
# 
# (1) Here's an example of the first possible use:
# 
#     set Bib::MyFlds(article)   "author address year"
#     set Bib::MyFlds(phdThesis) "whatever"
# 
# Bib::updateMyFld
# 
# Note that "extra" names in the Bib::MyFlds() array will also be included
# in the menu and completions, as in
# 
# set Bib::MyFlds(myEntry)   "field1 field2 etc"
# 
# The Bib::MyFlds array, however, cannot be modified through the menu.
# 
# This is not the preferred method for including additional entries, or
# modifying the fields of existing entries.  This can now all be done
# through Bibtex Menu items, and the Bib::MyFlds() array is NOT advertised !
# 
# (2) To teach Bib mode a new entry for validation purposes, a
# "BibPrefs.tcl" file should include the following:
# 
#     set   Bib::RqdFlds(myEntry) "field1 field2 etc"
#     set   Bib::OptFlds(myEntry) "field3 field4 etc"
# 
# Bib::updateMyFld
# 
# Note that this means that "myEntry" should NOT be defined using the
# "Custom Entry" menu item !!!
# 
# Unlike the Bib::MyFlds() array, this is advertised in "BibTeX Help".
# 
# One unfortunate side-effect of including this in a BibPrefs.tcl file is
# that some procs (such as Bib::set{KeywordLists}) will be repeatedly
# called by menu items using "Bib::updatePreferences", which is unavoidable
# since we have a lot a lists to deal with here that are contained in many
# places.  Fortunately, once a user has configured Bib mode to his/her
# liking, (re)setting keyword lists and (re)building menus will "only" take
# place twice when the mode is first called.  Again, this is unavoidable
# since the BibPrefs.tcl file is only sourced after all of the mode's
# initial list setting etc is done.
# 
# -- cbu
# 

proc Bib::updateMyFld {} {
    
    Bib::setBibEntries
    Bib::setBibcmds
    menu::buildSome "entries" "defaultEntryFields"
    return
}

# ===========================================================================
# 
# ×××× BibTeX Key Bindings ×××× #
# 
# abbreviations:  <o> = option, <z> = control, <s> = shift, <c> = command
# 

Bind    '2'  <z>    {togglePrefix @}        Bib

# Key bindings to enable Smart Quotes, Smart Dots

# Bind double quote:
ascii   0x22 <s>    {Bib::smartDQuote}      Bib
# Bind single quote:
ascii   0x27        {Bib::smartQuote}       Bib
# Bind period:
ascii   0x2e        {Bib::smartDots}        Bib
# Bind delete key: (use ascii to avoid dead-key problem)
ascii   0x08        {Bib::escapeSmartStuff} Bib

# Remap control-a to go to the beginning of text within a field.
Bind    'a' <z>     {Bib::beginningOfLineSmart} Bib

# Some extra navigation bindings.  (control-shift-p isn't always so handy.) 
# These bind control-shift-<arrow keys> to navigation procs as well.

Bind    up  <sz>    {Bib::prevEntry} Bib
Bind  left  <sz>    {Bib::prevEntry 0 1} Bib
Bind  down  <sz>    {Bib::nextEntry} Bib
Bind right  <sz>    {Bib::nextEntry 0 1} Bib

# Known bug: Key-bindings from other global menus might conflict with those
# defined in the Bib menu.  This will help ensure that this doesn't happen.

Bind 'n'    <sz>    {Bib::nextEntry} Bib
Bind 'p'    <sz>    {Bib::prevEntry} Bib
Bind 's'    <sz>    {Bib::selectEntry} Bib
Bind 'c'    <sz>    {Bib::copyCiteKey} Bib

Bind 'l'    <sz>    {Bib::formatEntry} Bib
Bind 'l'    <csz>   {Bib::formatRemaining} Bib
Bind 'v'    <sz>    {Bib::validateEntry} Bib
Bind 'v'    <csz>   {Bib::validateRemaining} Bib

Bind 'e'    <sz>    {Bib::searchEntries} Bib
Bind 'f'    <sz>    {Bib::searchFields} Bib
Bind 'b'    <sz>    {Bib::searchAllBibFiles} Bib
Bind 'q'    <o>     {Bib::quickFindCitation} Bib

Bind help   <s>     {package::helpWindow Bib} Bib

# Electric parentheses.
Bind '\)'           {Bib::electricRight "\)"} Bib

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Command Double Clicking ×××× #
# 

# ===========================================================================
# 
# In Bib mode, Command-double-clicks resolve abbrevs and cross-refs. 
# Unless we're in a "Formatting / Validation Results" file, in which case
# we try to jump to the original entry for the given cite-key.  Also works
# for line numbers reported in these files ...
# 

proc Bib::DblClick {from to shift option control} {
    
    global Bib::TopPat Bib::TopPat2
    global Bib::FileTails2 Bib::TailFileConnect2 
    global Bib::Entries Bib::Fields Bib::Acronyms Bib::Abbrevs

    # Remember the name of the current file
    set wCT  [win::CurrentTail]
    set wCT2 [win::StripCount $wCT]
    # Get the selection -- this might be modified later.
    set text [string trimleft [getText $from $to] "@"]
    # Get the first line.
    set firstLine [getText [minPos] [nextLineStart [minPos]]]
    # Deal with special cases first
    
    # From TeX::DblClick, "latexEngine.tcl".  Use the bibEngine proc.
    if {[file extension $wCT2] == ".blg" || $wCT2 == "* bibtex log *"} {
        Bib::blgDoubleClick $from $to
    }
    # BibTeX Statistics Window --
    if {[regexp {\\* BibTeX Statistics \\*} $wCT] || \
      [regexp {\(stats\)} $firstLine]} {
        regsub -all {"} [getText [lineStart $from] [nextLineStart $from]] {} f
        set f [string trim $f]
        if {[lsearch [winNames] $f] != "-1"} {
            bringToFront $f
        } elseif {[lsearch [set Bib::FileTails2] $f] != "-1"} {
            file::openQuietly [set Bib::TailFileConnect2($f)]
        } else {
            status::msg "Command-double-click on file names in this window."
        }
        return
    }
    # Acronym windows
    if {[regexp {\\* Bib Acronyms \\*} $wCT]} {
        regsub {"} [getText [lineStart $from] $to] {} text2
        if {$text2 == $text} {
            set title "Redefine the \"$text\" acronym:"
            set expansion [set Bib::Acronyms($text)]
            Bib::editAcronyms  $title $text $expansion
        } else {
            status::msg "Command double-click on acronyms to redefine them."
        } 
        return
    }
    # Control or Shift -- 
    if {$control || $shift} {
        set hit [Bib::entryLimits $from]
        if {[pos::compare $from < [lindex $hit 0]] || [pos::compare $from > [lindex $hit 1]]} {
            # We're not in an entry
            status::msg "This function only works within entries."
            error "\"$text\" was not within an entry."
        } 
        if {$control} {
            # Control -- perform a "Search Entries" for this text
            Bib::searchEntries "$text"
        } elseif {$shift} {
            # Shift -- perform a "Search Fields" for this text, in this field
            set field [Bib::getFldName $from [lindex $hit 0]]
            Bib::searchFields $field "$text" "-2"
        }
        return
    } 
    # Entries -- validate the entry.
    if {[lcontains Bib::Entries $text]} {Bib::validateEntry ; return} 
    # Fields -- format the entry.
    if {[lcontains Bib::Fields $text]}  {Bib::formatEntry 1 ; return} 
    # Results windows
    set resultsFile "\\* (Validation|Formatting|Conversion|Sort|Search|Cite\-Keys Results) \\*"
    set indexFile   "\\* Index For .*|Cite\-Keys List \\*"
    if {[regexp $resultsFile $wCT] || [regexp $indexFile $wCT] || \
      [regexp {\(validation|format|conversion|sort|search|cite\-keys|index|stats\)} $firstLine]} {
        Bib::DblClickFindFile $from $to
        return
    }
    # Special cases done ...  We're going to validate strings, crossrefs. 
    # Extend selection to largest string that could be an entry reference
    set limits [Bib::entryLimits $from]
    set top    [lindex $limits 0]
    set bottom [lindex $limits 1]
    set text [string trim \
      [eval getText [Bib::DblClickExtend $from $to $top $bottom]]]
    set searchPat "[set Bib::TopPat]\[\t \]*[quote::Regfind $text]\[ ,\}\)\]"
    # Get the citeKey of current entry, so we can avoid jumping to it.
    set citeKey {}
    regexp [set Bib::TopPat2] [getText $top $bottom] match type citeKey ]
    set fldName [Bib::getFldName $from $top]
    
    if {[string length $text] == 0 || $text == $citeKey || $fldName == $text || \
      ($fldName == "citeKey" && [string tolower $type] != "string")} {
        status::msg "Command-double-click on abbreviations and\
          crossref arguments in this window."
        return
    }
    # Jump to the mark for the specified citation, if a mark exists ... 
    # ...  otherwise, do an ordinary search for the cite key.
    placeBookmark    
    if {![catch {search -s -f 1 -r 1 -i 1 -m 0 $searchPat [minPos]} match]} {
        goto [lindex $match 0] ; insertToTop
    } elseif {[lsearch [set Bib::Abbrevs] $text] != "-1"} {
        status::msg "\"$text\" is defined in the \"Standard Abbreviations\" preference."
        return
    } else {
        returnToBookmark
        selectText $from $to
        if {$fldName == "crossref"} {
            status::msg "Cross-reference \"$text\" not found"
        } else {
            status::msg "Command-double-click on abbreviations and\
              crossref arguments in this window."
        }
        return
    }
    status::msg "Press <Ctl-.> to return to original position"
}

# ===========================================================================
# 
# Extend the selection around the initial selection {$from,$to}
# Extension is restricted to the range {$top,$bottom} (the current entry)
# 

proc Bib::DblClickExtend {from to top bottom} {
    if {[pos::compare $to == [minPos]]} {set to $from}
    set result [list $from $to]
    set pat    "\[,\{\]\"\'="
    if {![catch {search -f 0 -r 1 -s -m 0 -l $top $pat $from} match0]} {
        if {![catch {search -f 1 -r 1 -s -m 0 -l $bottom $pat $to} match1]} {
            set from [lindex $match0 1]
            set to   [lindex $match1 0]
            # Check for illegal chars embedded in the selection
            if {![regexp "\[\{\}\]=" [getText $from $to]]} {
                set result [list $from $to]
            }
        }
    }
    return $result
}

# ===========================================================================
# 
# Given just the location of the cite-key, attempt to locate the file that
# originated the report.
# 
# Life gets more complicated when the original file was a (now closed)
# "Search Results" window ...
#

proc Bib::DblClickFindFile {from to} {
    
    global Bib::TopPat Bib::FileTails2 Bib::TailFileConnect2
    
    # Remember the name of the current file
    set wCT   [win::CurrentTail]
    set text1 [getText $from $to]
    set searchPat "[set Bib::TopPat]\[\t \]*[quote::Regfind $text1]\[ ,\}\)\]"
    set f "-1"
    # Now we should make sure that "text" is really an entryName.
    # We have two cases to check:  Sort/Search windows, and the rest.
    # "Formatting Results" windows are so rare we don't bother.
    set text2 [getText [lineStart $from] $to]
    if {[regexp {Sort|Search} $wCT] && ![regexp [set Bib::TopPat] $text2]} {
        status::msg "Command-double-click on cite-keys in this window."
        return
    } 
    if {[regexp {Validation|Index} $wCT] && $text1 != $text2} {
        status::msg "Command-double-click on cite-keys in this window."
        return
    } 
    # Get the first line.
    set firstLine [getText [minPos] [nextLineStart [minPos]]]
    # Find the file that that generated this report.  If this is a Search
    # Results window, there might be multiple files listed.  We'll keep
    # searching for the "Search Results for ..." line that is most recent.
    if {[regexp {Validation|Formatting|Sort|Search|Index} $wCT] || \
      [regexp {\(validation|format|conversion|sort|search|index\)} $firstLine]} {
        # This is some some of report, with (hopefully) the source file listed.
        set  sourceLine {^(([a-zA-Z ]+ Results)|(Index))+( for ")}
        set pos [minPos]
        while {![catch {search -s -f 1 -r 1 -m 0 $sourceLine $pos} match]} {
            set start [lindex $match 1]
            set end   [nextLineStart $start]
            set pos   $end
            if {[pos::compare $pos < $from]} {
                regsub {"} [string trimright [getText $start $end]] {} f
            } else {
                break
            }
        }
    } elseif {[regexp {Cite\-Keys} $wCT] || \
      [regexp {\(cite\-keys\)} $firstLine]} {
        # This is a cite-keys file.
        set match [search -s -f 1 -r 1 -m 0 {  ".*"} $to]
        if {[pos::compare [lineStart [lindex $match 0]] != [lineStart $from]]} {
            status::msg "Command-double-click on line numbers and\
              cite-keys in this window."
            return
        } 
        set f [getText [lindex $match 0] [nextLineStart [lindex $match 0]]]
        regsub -all {"} $f {} f
        set f [string trim $f]
    } else {
        # We don't know what type of file this is.  (In this case it
        # shouldn't have been sent here by Bib::DblClick anyway...)
        status::msg "Sorry, this is an unknown report type."
        error "Could not determine the type of file this is originating from."
    } 
    # Now try go to the entry in the window "$f"
    if {[lsearch [winNames] $f] != "-1"} {
        placeBookmark
        bringToFront $f
        Bib::DblClickFindEntry $text1 $wCT
        return
    }
    # The window isn't currently open.  
    if {[lsearch [set Bib::FileTails2] $f] != "-1"} {
        # We got lucky.  The file wasn't open, but we know where it is.
        placeBookmark
        file::openQuietly [set Bib::TailFileConnect2($f)]
        Bib::DblClickFindEntry $text1 $wCT
        return
    }
    if {[regexp {\\* Search Results \\*} $f]} {
        # The generating file was a "Search Results" window, but that
        # window is closed.  Bother.
        regsub -all \[0\-9\] $text1 {} text2
        if {[regexp {\\* Cite\-Keys Results \\*} $wCT] && $text2 == ""} {
            # This must have been a duplicate cite-key search of a "Search
            # Results" file, but the original window is closed.  A line
            # number won't do us any good here.
            alertnote "The original \"Search Results\" window has\
              been closed, so try double-clicking on the cite-key\
              instead of the line-number."
            return
        }
        # Do a quick search of all of the citeKeys in the BibFile list.
        set results  [Bib::searchAllBibFiles $text1 "citeKey" "" 1]
        set bibfiles [lindex $results 2]
        if {[lindex $bibfiles 0] != "-1"} {
            # Found one ...
            if {[llength $bibfiles] == 1} {
                # ... and there was just one.
                placeBookmark 
                file::openQuietly [lindex $bibfiles 0]
                Bib::DblClickFindEntry $text1 $wCT
            } else {
                # ... there were several.
                set fList [listpick -l -p \
                  "Please choose at least one file to open:" $bibfiles]
                foreach f $fList {
                    file::openQuietly $f
                    Bib::DblClickFindEntry $text1 $wCT
                }
            } 
            return
        } 
    } 
    # Still couldn't find it, but we're not giving up.  Let's see if the cite
    # is in an open file.
    foreach window [winNames] {
        if {[Bib::isBibFile -w $window]} {
            placeBookmark
            bringToFront $window
            if {![Bib::DblClickFindEntry $text1 $wCT]} {
                # Didn't find it.
                returnToBookmark
            } else {
                # Found it.
                return
            }  
        } 
    }
    # Now we're giving up.
    error "Cancelled -- $weirdMessage anywhere."
}


# ===========================================================================
# 
# Double Click Find Entry
# 
# Try to find the citation within the current window.
# 

proc Bib::DblClickFindEntry {text1 {wCT ""}} {
    
    global Bib::TopPat
    
    if {$wCT == ""} {set wCT [win::CurrentTail]} 
    set searchPat "[set Bib::TopPat]\[\t \]*[quote::Regfind $text1]\[ ,\}\)\]"
    if {![catch {search -s -f 1 -r 1 -m 0 $searchPat [minPos]} match]} {
        # Now find the entry.
        goto [lineStart [lindex $match 0]] ; insertToTop
        status::msg "Press <Ctl .> to return to  $wCT"
        return 1
    } elseif {[regexp \[0\-9\] $text1]} {
        # Maybe its a line number
        goto [pos::fromRowChar $text1 0] ; insertToTop
        status::msg "Press <Ctl .> to return to  $wCT"
        return 1
    } 
    return 0
}

# ===========================================================================
# 
# ×××× Option-click title bar ×××× #
# 
# List all Bib files, and then all current windows.
#

proc Bib::OptionTitlebar {} {
    
    global Bib::FileTails
    
    set menuList {"Rebuild File List" "-"}
    foreach f [set Bib::FileTails] {lappend menuList $f} 
    lappend menuList "-"
    foreach f [winNames]  {lappend menuList $f} 
    return $menuList
    
}

proc Bib::OptionTitlebarSelect  {item}  {Bib::fileListProc "OptTitlebar" $item}

# ===========================================================================
# 
# ×××× Electric Procedures ×××× #
# 

##
 # --------------------------------------------------------------------------
 #
 # "Bib::electricLeft" --
 # 
 # This is only invoked if the Bib mode preference for "electricBraces" has
 # been turned on.  We could possibly try to create an entry template if we
 # are behind an "@entryType" string, but since it can get pretty tricky to
 # determine the exact context and the intentions/desires of the user at this
 # point it is probably best to simply properly indent the line.
 #
 # -------------------------------------------------------------------------- 
 ##

proc Bib::electricLeft {{char "\{"}} {
    
    global BibmodeVars
    
    typeText $char
    if {$BibmodeVars(electricBraces)} {
        bind::IndentLine
    } 
}

##
 # --------------------------------------------------------------------------
 #
 # "Bib::electricRight" --
 # 
 # This is only invoked if the Bib mode preference for "electricBraces" has
 # been turned on.  If we are at the end of an entry, format the entire entry.
 # If we are at the end of a field, make sure that we have "," at the end of
 # the line, and if the next line is non-empty then insert a new line via
 # [bind::CarriageReturn].  If we cannot determine that we're at the end of an
 # entry or a field, then don't try anything fancy.
 #
 # -------------------------------------------------------------------------- 
 ##

proc Bib::electricRight {{char "\}"}} {
    
    global BibmodeVars Bib::TopPat
    
    typeText $char
    if {!$BibmodeVars(electricBraces)} {
	return
    }
    bind::IndentLine
    if {[catch {matchIt $char [pos::math [getPos] -2]} pos0]} {
	return
    } elseif {$BibmodeVars(entryBraces) && $char == "\)"} {
	blink $pos0
	return
    }
    set type ""
    set txt0 [getText [pos::lineStart $pos0] $pos0]
    set txt1 $txt0
    set txt2 [getText [getPos] [pos::lineEnd]]
    set txt3 [getText [pos::nextLineStart] [pos::nextLineEnd]]
    set pat0 {^\s*@[a-zA-Z]+\s*$}
    set pat1 {^[\t ]*[^ =,]+[\t ]*=[\t ]*$}
    set pat2 {^\s*$}
    set pat3 {^\s*$}
    if {[regexp -- $pat0 $txt0]} {
	set type "entry"
    } elseif {[regexp -- $pat1 $txt1]} {
	set type "field"
    } 
    if {$type == "entry"} {
	Bib::formatEntry 0
    } elseif {$type == "field"} {
	if {[regexp -- $pat2 $txt2]} {
	    insertText ","
	    if {![regexp -- $pat3 $txt3]} {
		bind::CarriageReturn
	    } else {
		goto [pos::nextLineStart]
		bind::IndentLine
	    }
	} 
	blink $pos0
    } else {
	blink $pos0
    }
}

##
 # -------------------------------------------------------------------------
 #
 # "Bib::correctIndentation" --
 # 
 # While [Bib::formatEntry] will take care of all indentation needs in a
 # more sophisticated way, this procedure will help make a good guess as to
 # the proper indentation of the current line, especially after a Return.
 # 
 # We basically have four cases to deal with, the "indentMethod" used
 # below, all based on what the previous line looked like:
 # 
 # (1) This line is the first field following "@entryType{citeKey,"
 # (2) This line starts a new field following the end of a previous one.
 # (3) This line is the second line following the start of a new field.
 # (4) This line starts a new entry following the end of a previous one.
 # 
 # If it doesn't look like we're in any of the above situations, then we
 # assume that we are continuing a longer field, or perhaps we are in a
 # comment, and just use the indentation of the previous line.
 # 
 # -------------------------------------------------------------------------
 ##

proc Bib::correctIndentation {args} {
    
    global Bib::TopPat Bib::Indent BibmodeVars
    
    win::parseArgs w pos {next ""}
    
    # Find the most recent non-empty line.
    set txt  ""
    set pos0 $pos
    while {![string length [string trim $txt]]} {
	set pos1 [pos::prevLineStart -w $w $pos0]
	set pos2 [pos::prevLineEnd -w $w $pos0]
	set txt  [getText -w $w $pos1 $pos2]
	if {[pos::compare -w $w [set pos0 $pos1] == [minPos -w $w]]} {
	    break
	}
    }
    # Create a set of search patterns.  The order here matters.
    set pat1 ${Bib::TopPat}
    if {$BibmodeVars(fieldBraces)} {
	set pat2 {\}[\t ]*,[\t ]*$}
	set pat3 {^[\t ]*[^ =,]+[\t ]*=[\t ]*\{}
    } else {
	set pat2 {\"[\t ]*,[\t ]*$}
	set pat3 {^[\t ]*[^ =,]+[\t ]*=[\t ]*\"}
    }
    if {$BibmodeVars(entryBraces)} {
	set pat4 {^[\t ]*\}[\t ]*$}
    } else {
	set pat4 {^[\t ]*\)[\t ]*$}
    }
    # Find the method based on the regexp pattern of the previous line.
    set indentMethod 0
    for {set i 1} {[info exists pat$i]} {incr i} {
	if {[regexp -- [set pat${i}] $txt]} {
	    set indentMethod $i
	    break
	} 
    }
    switch -- $indentMethod {
	"0" {
	    return [::correctIndentation -w $w $pos $next]
	}
	"1" {
	    return [string length ${Bib::Indent}]
	}
	"2" {
	    return [string length ${Bib::Indent}]
	}
	"3" {
	    set idxs [list -1 -1]
	    regexp -indices -- $pat3 [text::maxSpaceForm $txt] idxs
	    return [expr {[lindex $idxs 1] + 1}]
	}
	"4" {
	    return 0
	}
	default {
	    return 0
	}
    }
}

# ===========================================================================
# 
# ×××× Mark File, Parse Funcs ×××× #
# 
# Mark File:    Set a named mark for each entry, using the cite-key name.
# Parse Funcs:  Only return every 10th entry.
#

# ===========================================================================
# 
# Search patterns for entries and cite-keys
# 
# What gets used where:
# 
# Bib::TopPat     match entry type
# 
# Bib::gotoEntryFromIndex
# Bib::_GotoEntry
# Bib::entryLimits
# Bib::nextEntry
# Bib::prevEntry
# Bib::searchAllBibFiles
# Bib::sortByCiteKey
# Bib::sortByAuthors
# Bib::DblClick
# Bib::DblClickFindFile
# Bib::DblClickFindEntry
# 
# Bib::TopPat1    match cite-key
# 
# Bib::listStrings
# Bib::countEntries
# Bib::sortByCiteKey
# Bib::sortByAuthors
# 
# Bib::TopPat2    match type and cite-key
# 
# Bib::buildIndex
# Bib::addWinToIndex
# Bib::getCiteKey
# Bib::getFields
# Bib::countEntries
# Bib::DblClick
# 
# Bib::TopPat3    match first field (no cite-key)
# 
# Bib::getFields
# 

# match entry type
# set Bib::TopPat {^[ ]*@[a-zA-Z]+[\{\(]([-a-zA-Z0-9_:/\.]+)}
set Bib::TopPat {^[\t ]*@([a-zA-Z]+([\t ]*))[\{\(]}

# match cite-key
set Bib::TopPat1 {^[\t ]*@[a-zA-Z]+[\t ]*[\{\(][\t ]*([^=,\t ]+)}

# match type and cite-key
set Bib::TopPat2 {^[\t ]*@([a-zA-Z]+)[\t ]*[\{\(][\t ]*([^=,\t ]+)}

# match first field (no cite-key)
set Bib::TopPat3 {^[\t ]*@([a-zA-Z]+)[\t ]*[\{\(]([\t ]*[a-zA-Z]+[\t ]*=[\t ]*)}

proc Bib::MarkFile {args} {
    
    global BibmodeVars Bib::TopPat1 Bib::TopPat2
    
    win::parseArgs w {listOnly 0}
    
    set wCT [win::Tail $w]
    if {[regexp "\\* Cite\-Keys" $wCT]} {
	# A special marking scheme for 'Cite Key Lists' windows.
	set pat {Command double-click}
	if {[catch {search -w $w -f 1 -r 0 -i 0 -m 0 -s $pat [minPos -w $w]} match]} {
	    return
	} 
	set pos [nextLineStart -w $w [nextLineStart -w $w [lindex $match 1]]]
	set pat {^([-a-zA-Z0-9_:/\.])}
	while {![catch {search -w $w -s -f 1 -r 1 -m 0 -i 0 -- $pat $pos} match]} {
	    set start [lindex $match 0]
	    set end   [nextLineStart -w $w $start]
	    set t     [getText -w $w $start $end]
	    regexp {[a-zA-Z0-9]+[-a-zA-Z0-9_:/\.]} $t citeKeyMark
	    setNamedMark -w $w $citeKeyMark $start $start $start
	    set pos $end
	}
	return
    } elseif {[regexp "\\* Validation|Formatting|BibTeX Results|List|Statistics \\*" $wCT]} {
        # These files have their own marking schemes.
        return
    }
    if {!$listOnly} {
        # We're marking the file.
        set markStrings $BibmodeVars(markStrings)
        status::msg "Marking '$wCT' É"
        set totalCount   0
        set uniqueCount  0
        set dividerCount 0
        set dividers     ""
        set marks        ""
    } else {
        # We're only creating the list of cite-keys.
        set results ""
        set markStrings 0
        status::msg "Creating the list of cite-keys for \"$wCT\" É"
    } 
    set pos [minPos -w $w]
    set pat "([set Bib::TopPat1])|(Search Results for)"
    while {![catch {search -w $w -s -f 1 -r 1 -m 0 -i 0 -- $pat $pos} res]} {
        set start [lindex $res 0]
        set pos   [nextLineStart -w $w $start]
        set text  [getText -w $w $start $pos]
        if {[regexp [set Bib::TopPat2] $text match type citeKey]} {
            # Cite-key or string found.
            if {[string tolower $type] != "string" || $markStrings} {
                if {!$listOnly} {
                    incr totalCount
                    incr uniqueCount
                    if {[lcontains marks $citeKey]} {
                        incr uniqueCount -1
                        while {[lcontains marks $citeKey]} {append citeKey " "}
                    }
                    lappend marks $citeKey
                    # Set the mark.
                    setNamedMark -w $w $citeKey $start $start $start
                } else {
                    # Record the citeKey info.
                    set lineNumber [lindex [pos::toRowChar -w $w $start] 0] 
                    lappend results [list $citeKey $lineNumber $wCT]
                } 
            }
        } elseif {[regexp -- {Search Results for} $text] && !$listOnly} {
            # Insert a divider to indicate a new Search 
            set divider "-"
            while {[lcontains dividers $divider]} {append divider " "}
            if {[llength $dividers]} {
                # But don't add a divider for the first one.
                setNamedMark -w $w $divider $start $start $start
                incr dividerCount
            } 
	    # Include the search file.
	    set fileName [getText -w $w [lindex $res 1] [nextLineStart -w $w $start]]
	    regsub -all {\"} "¥ [string trim $fileName] ¥" {} fileName
	    while {[lcontains fileNames $fileName]} {append fileName " "}
	    setNamedMark -w $w $fileName $start $start $start
	    lappend fileNames $fileName
            lappend dividers  $divider
        }
    } 
    if {$listOnly} {
	return $results
    }
    set entriesStrings "entries"
    if {$BibmodeVars(markStrings)} {set entriesStrings "entries and strings"} 
    if {$totalCount == 1} {
        # Most likely a search results window.
        status::msg "1 unique entry in $wCT"
    } else {
        status::msg "$totalCount total, $uniqueCount unique $entriesStrings in $wCT"
    } 
}

proc Bib::parseFuncs {} {
    
    global Bib::TopPat1 Bib::TopPat2 
    
    set pos [minPos]
    set count 1
    set m {}
    while {[set res [search -s -f 1 -r 1 -i 0 -n [set Bib::TopPat1] $pos]] != ""} {
        set start [lindex $res 0]
        set pos   [nextLineStart $start]
        set text  [getText $start $pos]
        if {[regexp [set Bib::TopPat2] $text match type citeKey] && [string tolower $type] != "string"} {
            # Cite-key found, and it's not a string.
            if {[string range $count [expr [string length $count] - 1] end] == 0} {
                lappend m [list $citeKey $start] 
            } 
            incr count
        }
    }
    regsub -all "\[\{\}\]" $m "" m
    return $m
}

# ===========================================================================
# 
# .