## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # LaTeX mode - an extension package for Alpha
 #
 # FILE: "latex.tcl"
 #                                   created: 11/10/1992 {10:42:08 AM}
 #                               last update: 2006-05-05 15:01:06
 # Description:
 #
 # Note:
 #
 # LaTeX 2.09 is no longer supported.  If someone wants to make the
 # necessary changes to support it, they are welcome.
 #
 # Authors:
 #
 # (See the "LaTeX Help" file for a more complete version history.)
 #
 # version  1.1 and 1.2 (11/10/92) by Richard T. Austin <austin@eecs.umich.edu>
 # versions 2.0--3.2 and 3.2t (3/97) by Tom Scavo <trscavo@syr.edu>
 # versions 4.0 onwards (9/97) by Vince Darley <vince@santafe.edu>
 #
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta
 #         Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 #
 # Copyright (c) 1992-2006 by (in alphabetical order)
 #
 # Ivan Alves
 # Andreas Amann
 # Richard Austin
 # Pierre Basso
 # FrŽdŽric Boulanger
 # Alun Carr
 # Vince Darley
 # Juan Falgueras
 # Paul Gastin
 # Jon Guyer
 # Joachim Kock
 # Johan Linde
 # Michel Moreaux
 # Tom Pollard
 # Tom Scavo
 # Craig Barton Upright
 # 
 # All rights reserved.
 #
 # (There are doubtless other contributors to this code, please feel free
 # to let us know!)
 #
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

##
 # --------------------------------------------------------------------------
 # To Do:
 # 
 # Fix all bugs introduced in v 5.0 !!!
 # 
 # Most of the procs in "latexMacros.tcl" have been condensed into a single
 # menu proc.  More could probably be done in "latexEnvironments.tcl".
 # 
 # Along with this, we should take a look at electric completions to make
 # sure that we're not duplicating any work being done elsewhere -- there
 # seems to be some subtle differences between inserting some items via the
 # menu versus via electric completions.
 # 
 # None of the procs in the "latexFilesets.tcl" have been placed in the TeX
 # namespace -- not sure if this is a priority or not.  That file is
 # essentially the same between 4.9 and 5.0
 # 
 # All of the documentation needs an update -- many new features and changes
 # in behavior have been added with few clues to the user outside of the code
 # in the source files.
 # 
 # A lot of the dialogs would benefit from using "dialogsNew.tcl" code.
 # 
 # Many of the electric expansion preferences only work for TeX mode, but
 # that would involve some major changes in that code.
 # 
 # --------------------------------------------------------------------------
 ##

# Initialize TeX mode:
alpha::mode TeX 6.0a2 "latex.tcl" {
    *.tex *.ltx *.dtx *.sty *.cls *.clo *.ini *.ins *.aux 
    *.bbl *.blg *.bst *.def *.drv *.fd  *.fdd *.glo
    *.gls *.idx *.ilg *.ind *.lof *.log *.lot *.toc
} {
    texMenu
} {
    # Initialization script.  Called when Alpha is first started.
    addMenu texMenu "¥270" [list "TeX" "Bib"]
    set unixMode(latex) {TeX}
    # Reset the search path so it will be rebuilt the next time it's needed:
    set AllTeXSearchPaths {}

    # To add a new fileset type, all we have to do is this:
    fileset::registerNewType tex tex
    # When a tex-fileset changes, call this proc
    hook::register fileset-update {TeX::rebuildMenu filesetUpdate} "tex"
    # Add more options to the 'New Document' prompt
    set {newDocTypes(New LaTeX Doc)} TeX::newLaTeXDocument

    # Placed these here so BibTeX mode can definitely access them.
    set texParaCommands {\[|\]|begin|end|(protect\\)?label|(sub)*section\*?|subfigure|paragraph|centerline|centering|caption|chapter|item|bibitem|intertext|(protect\\)?newline|includegraphics\*?}
    namespace eval TeX {}
    set TeX::startPara {^[ \t]*$|\\\\[ \t]*$|(^|[^\\])%|\\h+line[ \t]*$|\$\$[ \t]*$|^[ \t]*(\\(}
    append TeX::startPara $texParaCommands {)(\[.*\]|\{.*\}|¥)*[ \t]*)+$}
    set TeX::endPara {^[ \t]*$|(^|[^\\])%|\$\$[ \t]*$|^[ \t]*(\\(}
    append TeX::endPara $texParaCommands {)(\[.*\]|\{.*\}|¥)*[ \t]*)+$}
} maintainer {
    "FrŽdŽric Boulanger"
} uninstall {
    this-directory
} description {
    Supports the editing of LaTeX files
} help {
    file "LaTeX Help"
}

# Autoload procedures
proc latex.tcl {} {}
proc texMenu   {} {
    status::msg "Building LaTeX menuÉ"
    latexKeys.tcl
    latexMenu.tcl
    menu::buildSome texMenu
    status::msg "Building LaTeX menuÉ complete"
    ;proc texMenu {} {}
}

# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn    1 TeX

if {(${alpha::macos} != 1)} {
    # Turn this item on to use 'kpsewhich' to find files (useful if you
    # use teTeX).  ||Turn this item off to not use 'kpsewhich' to find
    # files.
    newPref flag useKpsewhich  0 TeX
}

# ==========================================================================
#
# ×××× -------- ×××× #
# 
# ×××× Hooks ×××× #
#

# Only register hooks for our modes.
hook::register activateHook {TeX::activateHook} TeX Bib
hook::register winChangedName   {TeX::rebuildMenu "winChangedName"} TeX
hook::register saveHook     {TeX::autoAdjustFormat} TeX

proc TeX::activateHook {name} {

    global alpha::platform
    
    if {![package::active texMenu]} {return}
    
    # Now adjust the Process menu.
    TeX::autoAdjustFormat
    TeX::rebuildMenu "activateHook"
    # Some items might have been inadvertently enabled.
    TeX::postBuildTeX
}

proc TeX::autoAdjustFormat {{name ""}} {
    
    global mode TeXmodeVars
    
    if {$mode != "TeX" || !$TeXmodeVars(autoAdjustFormat)} {return}
    
    if {![string length $name]} {
        set name [win::Current]
	set rebuild 0
    } else {
        set rebuild 1
    }
    
    # We pay attention to the format, so we attempt to auto adjust.

    set baseFile      [TeX::currentBaseFile $name]
    set baseFormat    [lindex [TeX::getFormatName $baseFile] 0]
    set currentFormat $TeXmodeVars(nameOfTeXFormat)
    
    if {![string length $baseFormat] || $baseFormat == $currentFormat} {return}
    
    # There is a format name for the base file, so we attempt to auto adjust.
    if {[lsearch $TeXmodeVars(availableTeXFormats) $baseFormat] == "-1"} {
	# The format name is not in our list, so offer to add it, unless
	# the user has already said no!
	global TeX::ignoreFormats
	if {[info exists TeX::ignoreFormats] \
	  && [lsearch -exact ${TeX::ignoreFormats} $baseFormat] != -1} {
	    return
	}
	set msg "'$baseFormat' is not included in the list of available\
	  TeX Formats -- would you like to add it?"
	if {[askyesno $msg] == "yes"} {
	    lappend TeXmodeVars(availableTeXFormats) $baseFormat
	    prefs::modified TeXmodeVars(availableTeXFormats)
	    set TeXmodeVars(nameOfTeXFormat) $baseFormat
	} else {
	    # We didn't add it, so we'll set the format to a empty
	    # string -- user will be prompted if attempting to
	    # typeset the file.
	    set TeXmodeVars(nameOfTeXFormat) ""
	    lappend TeX::ignoreFormats $baseFormat
	}
    } else {
	# The format is in our list, so auto-adjust.
	set TeXmodeVars(nameOfTeXFormat) $baseFormat
    }
    if {$rebuild} {TeX::rebuildMenu "TeX Format"}
} 

# ==========================================================================
#
# ×××× -------- ×××× #
# 
# ×××× TeX Mode Preferences ×××× #
#

proc TeX::updateVersionPreferences {} {
    
    global TeX::VersionNumber TeXmodeVars TeX::MenuKeysUser alpha::macos
    
    if {![info exists TeX::VersionNumber]} {
	set TeX::VersionNumber "1"
    }

    # Note that we're not using 'alpha::package vcompare' here, so the if {}
    # tests should only check against versions which are true decimals.
    
    if {[set TeX::VersionNumber] < 4.7} {
        # These prefs are really old.
	if {[info exists TeXmodeVars(TeXInputsFolder)]} {
	    alertnote "The 'TeXInputsFolder' pref has been replaced by\
	      'TeXSearchPath', which is now a list of folders to search.\
	      Your preference will be copied to the new name and the old\
	      one will be deleted."
	    # Can't use prefs::renameOld because we are turning a single
	    # folder into a search path.
	    lappend TeXmodeVars(TeXSearchPath) $TeXmodeVars(TeXInputsFolder)
	    unset TeXmodeVars(TeXInputsFolder)
	    prefs::modified TeXmodeVars(TeXInputsFolder) TeXmodeVars(TeXSearchPath)
	}
	# Old indenting preference.
	prefs::renameOld TeXmodeVars(dontIndentBeginEnd) \
	  TeXmodeVars(dontIndentLaTeXenvironments)
	# Now set the version number so we never do this again.
	set TeX::VersionNumber 4.7
    } 
    if {[set TeX::VersionNumber] < 5.0} {
	# Create the short LaTeX menu by default, but now split the 'short'
	# pref into two different ones for "Text" and "Math"
	if {[prefs::renameOld useShortLaTeXMenu TeXmodeVars(compressTextMenus)]} {
	    set TeXmodeVars(compressMathMenus) $TeXmodeVars(compressTextMenus)
	}
	# Changing this from a global to a TeX mode preference.
	prefs::renameOld useAMSLaTeX TeXmodeVars(useAMSLaTeX)
	# Now we're going to rename that indenting pref again.
	if {[prefs::renameOld TeXmodeVars(dontIndentLaTeXenvironments) \
	  TeXmodeVars(indentLaTeXEnvironments)]} {
	    set TeXmodeVars(indentLaTeXEnvironments) \
	      [expr {1 - $TeXmodeVars(compressTextMenus)}]
	}
	# Given how many flags we have, this one seems really unnecessary
	# since it usually just gave a 'beep' before an alertnote or at the
	# end of some action where a status bar message is given.  All
	# queries for this pref have been removed.
	prefs::removeObsolete TeXmodeVars(searchNoisily)
	# Now in the menu.
	if {[info exists TeXmodeVars(TeXAddItem)]} {
	    set "TeX::MenuKeysUser(Add Item)" $TeXmodeVars(TeXAddItem)
	    prefs::modified "TeX::MenuKeysUser(Add Item)"
	} 
	prefs::removeObsolete TeXmodeVars(TeXAddItem)
	# Changing these so that additional options can be added if necessary.
	if {[set alpha::macos]} {
	    prefs::renameOld TeXmodeVars(useNewerTexturesInterface) \
	      TeXmodeVars(versionForTextures)
	    # In case these were saved previously.
	    prefs::renameOld TeX::indexStyle    TeXmodeVars(TeXindexStyle)
	    prefs::renameOld TeX::glossaryStyle TeXmodeVars(TeXglossaryStyle)
	} else {
	    prefs::removeObsolete TeXmodeVars(versionForCMacTeX)
	    prefs::removeObsolete TeXmodeVars(useNewerCMacTeXInterface)
	    prefs::removeObsolete TeXmodeVars(useNewerTexturesInterface)
	    prefs::removeObsolete TeX::indexStyle TeX::glossaryStyle
	}
	# Now we can get rid of these.
	prefs::removeObsolete TeXmodeVars(fixedFormatNames)
	prefs::removeObsolete TeXmodeVars(noFormatNameInFile)
	# Small name change.
	prefs::renameOld TeXmodeVars(latexHelp) \
	  TeXmodeVars(LaTeXHomePage)
	prefs::renameOld TeXmodeVars(electricContractions) \
	  TeXmodeVars(electricLeftContractions)
	# Make sure that we have these formats listed.
	set defaultFormats [list \
	  "LaTeX" "TeX" "Big-LaTeX" "AMS-TeX" "Plain TeX" "(-)"]
	if {[info exists TeXmodeVars(availableTeXFormats)]} {
	    set savedFormats $TeXmodeVars(availableTeXFormats)
	    set savedFormats [lremove -all $savedFormats $defaultFormats]
	} else {
	    set savedFormats [list \
	      "eTeX" "eLaTeX" "PDFTeX" "PDFLaTeX" "PDFeTeX" "PDFeLaTeX"]
	}
	set allFormats [concat $defaultFormats [lsort -dictionary $savedFormats]]
	set TeXmodeVars(availableTeXFormats) [lunique $allFormats]
	# Now set the version number so we never do this again.
	set TeX::VersionNumber 5.0
    } 
    # We always make sure that the formats include these.
    foreach formatItem [list "TeX" "LaTeX"] {
	if {![lcontains TeXmodeVars(availableTeXFormats) $formatItem]} {
	    if {![info exists TeXmodeVars(availableTeXFormats)]} {
		set TeXmodeVars(availableTeXFormats) {}
	    }
	    set TeXmodeVars(availableTeXFormats) \
	      [concat $formatItem $TeXmodeVars(availableTeXFormats)]
	} 
    }
    # Save the new version number.
    prefs::modified TeX::VersionNumber
}

# Update some old preferences.
TeX::updateVersionPreferences

# ×××× Flag Prefs ×××× #

# Note that there are some additional flag prefs in "TeXCompletions.tcl"

# Turn this item on to automatically mark windows when they're first opened
# if they don't already have marks saved||Turn this item off to never mark
# windows when they are first opened
newPref flag autoMark           "1" TeX
# Turn this item on to build the submenu of all known packages, based on
# those found in the TeX mode search paths as well as those in the folder of
# your TeX application.  Selecting these packages will insert a '\usepackage'
# line in the window||Turn this item off to never build the submenu of all
# known packages.  This will build the TeX menu faster when it is first
# inserted in the menu bar
newPref flag buildPkgsSubmenu   "0" TeX {TeX::rebuildMenu}
# Turn this item on to collect all 'Text' submenus and place them in a
# hierarchical 'Text Submenus' item||Turn this item off to include all 'Text'
# submenus in the main TeX menu
newPref flag compressTextMenus  "1" TeX {TeX::rebuildMenu}
# Turn this item on to collect all 'Math' submenus and place them in a
# hierarchical 'Math Submenus' item||Turn this item off to include all 'Math'
# submenus in the main TeX menu
newPref flag compressMathMenus  "1" TeX {TeX::rebuildMenu}
# Turn this item on to always prompt before deleting a selection when adding
# a LaTeX environment via a menu item which does not take any argument (like
# \begin{itemize} or {figure})||Turn this item off to silently delete
# highlighted text when adding a LaTeX environment that won't use it
newPref flag deleteEnvNoisily   "1" TeX
# Turn this item on to always prompt before deleting a selection when adding
# a LaTeX command via a menu item which does not take any argument (like
# \epsilon, or \ldots)||Turn this item off to silently delete highlighted
# text when adding a LaTeX command that won't use it
newPref flag deleteObjNoisily   "1" TeX
# Turn this item on to indent lines between \begin ...  \end pairs.  This not
# only works for automatic indentation but also for "Environments" menu items
# and electric completions/expansions Note that the 'document' environment is
# never indented||Turn this item off to never indent lines between \begin ... 
# \end pairs
newPref flag indentLaTeXEnvironments "1" TeX {TeX::adjustElectricLabels}
# Turn this item on to use <control-shift> arrow keys to navigate
# paragraphs||Turn this item off to navigate indented environments starting
# with '\begin' and ending with '\end'
newPref flag navigateParagraphs "1" TeX
# Turn this item on to perform a normal typeset in the background (you can
# always override with a different key-combination)||Turn this item off
# to always bring the TeX application to the front when typesetting
newPref flag runTeXInBack       "0" TeX {TeX::rebuildMenu}
# Turn this item on to give an explanatory message when typesetting the first
# time, after which this preference is turned off||Turn this item off to give
# an explanatory message the next time a file is typeset
newPref flag showFirstTimeTypesettingMessage "1" TeX
# Turn this item on to automatically turn '...'  into '\ldots' as you
# type||Turn this item off to never turn '...'  into '\ldots'
newPref flag smartDots          "1" TeX
# Turn this item on to automatically turn ' or " into ` or `` or ' or '' as
# you type, depending upon the context.  ('Delete' will first restore the
# single or double quote)||Turn this item off to never turn ' or " into ` or
# ''
newPref flag smartQuotes        "1" TeX
# Choose your smart quote style here, depending on the language you
# write your documents in.  You currently need to restart after changing
# this preference (to be fixed).
newPref var smartQuoteStyle      0 TeX TeX::smartQuotesChanged [list\
  "English (`` '' ` ')" "German (\"` \"' \\glq \\grq)" \
  "French (<< >> \\flq \\frq)" "Reverse French (>> << \\frq \\flq)"] index
# Turn this item on to take over entire numeric keypad with dummy bindings
# (Helps to avoid bad keypresses), and to rebind relevant keys to TeX mode
# specific navigation||Turn this item off to restore the numeric keypad to
# the generic navigation items used by Alpha
newPref flag takeOverNumericKeypad "1" TeX {TeX::bindLaTeXKeys}
# Turn this item on to warn if a particular template requires a certain
# package and it's not there||Turn this item off to never warn when a
# particular template requires a certain package and it's not there
newPref flag warnIfPackageNotIncluded "1" TeX
# Turn this item on to use include AMS-LaTeX specific menu items.  This will
# also change some of the default key bindings||Turn this item off to remove
# AMS-LaTeX specific menu items
newPref flag useAMSLaTeX        "0" TeX {TeX::rebuildMenu}
# Turn this item on to use use '\[', '\]' for display math 
# environments.  Turn this item off to use a full \begin..\end{displaymath}
# environment.
newPref flag useBrackets        "1" TeX
# Turn this item on to use '$...$' and '$$...$$' for mathematics rather than
# the LaTeX expressions.  This only changes the bindings in the Math Modes
# menu||Turn this item off to use '$...$' and '$$...$$' for the LaTeX
# expressions rather than mathematics
newPref flag useDollarSigns     "0" TeX {TeX::rebuildMenu}
# Turn this item on to add prefixes to label names when they are inserted,
# such as "eq" or "tab" using the "Standard TeX Label Delimiter"
# character(s)||Turn this item off to never add prefixes to label names when
# they are inserted
newPref flag useLabelPrefixes   "0" TeX {TeX::adjustElectricLabels}

# Default setting for automatic line wrapping in TeX mode
newPref var lineWrap 1 TeX

# Add some flag prefs specific to CMacTeX, Textures, etc.

if {[set alpha::macos]} {
    # Turn this item on to use Textures flash mode||Turn this item off to not
    # use Texture flash mode
    newPref flag useTexturesFlashMode "1" TeX
}

# Now we're going to hide some of these preferences from the Mode Prefs
# dialog since they're best set through the TeX menu, and we'd like to keep
# the number of options presented to the user to a minimum so that their eyes
# don't glaze over.

prefs::deregister "buildPkgsSubmenu"    "TeX"
prefs::deregister "compressMathMenus"   "TeX"
prefs::deregister "compressTextMenus"   "TeX"
prefs::deregister "useAMSLaTeX"         "TeX"
prefs::deregister "useDollarSigns"      "TeX"
prefs::deregister "showFirstTimeTypesettingMessage" "TeX"

# ×××× Variable Prefs ×××× #

# Could add '--src' here for embedding of src information in dvi files
# (e.g. for use with MikTeX).
newPref var  additionalTeXFlags "" TeX
# Extensions of auxiliary files which are removed when the "Process -->
# Remove Auxiliary Files" menu item is used.
newPref var  auxFileExtensions [list \
  .aux .bbl .blg .dvi .glo .gls .idx .ilg .ind .lof .log .lot .ps .toc \
  ] TeX
# Names of commands which insert boxed graphics.  The items in this list are
# command-double-clickable, and are presented as options for 'figure'
# templates.
newPref var  boxMacroNames {includegraphics includegraphics*} TeX {TeX::colorizeTeX}
# Commands used by your citation package.  The items in this list are
# colorized, and are command-double-clickable to find the location of the
# citation in your .bib file.
newPref var  citeCommands {cite nocite citet citeauthor citep citeyear} \
  TeX {TeX::updateCiteCommands}
newPref var  commentsContinuation 2 TeX "" \
  [list "only at line start" "spaces allowed" "anywhere"] index
# The width of a line before automatic carriage returns are issued, and the
# length used when filling paragraphs.
newPref var  fillColumn {70} TeX
# This regular expression is used for the {} 'Parse Funcs' menu on the side
# of the window, and for folding (sub)sections in Alphatk
newPref var  funcExpr {^\s*\\(part|chapter|(sub)*section)(?![A-Za-z])} TeX
# This regular expression is used by the 'Goto' navigation menu items, as
# well as Keypad navigation items to find sections.
newPref var  funcExprAlt {\\section(\[.*\]|\*)?({[^{}]*})?} TeX
# Control-Command double-clicking on a LaTeX keyword will send it to this url
# for a help reference page.  This is also the url used by the "LaTeX Help
# --> WWW LaTeX Help" menu item.
newPref url LaTeXHelp \
  {http://www.emerson.emory.edu/services/latex/latex2e/search=context?query=} TeX
# The "LaTeX Help --> LaTeX Home Page" menu item will open this url.
newPref url  LaTeXHomePage {http://www.tug.org} TeX
# How far lines should be indented after an automatic carriage return.  This
# feature is somewhat buggy -- best to leave it at 0.
newPref var  leftFillColumn {0} TeX
# File with these extensions have a different marking procedure which
# collects a list of TeX commands rather than the structural content of the
# file.
newPref var  markCommandsNotStructure \
  [list .aux .bbl .cfg .clo .cls .def .dtx .fd .sty] TeX
# The list of known mathematical environments
newPref var  mathEnvironments \
  [list "math" "displaymath" "equation" "eqnarray" "eqnarray*" "array"] TeX
# This regular expression is used in the {} 'Parse Funcs' menu on the side of
# the window.
newPref var  parseExpr {[^\{]*\{([^\}]*)\}[^\}]*} TeX
# This is the standard comment character string.
newPref var  prefixString {% } TeX
# The commands which are used to refer to labels elsewhere in the text. 
# Items in this list will be colorized, and are command-double-clickable.
newPref var  refCommands {ref eqref pageref vref vpageref} TeX {TeX::colorizeTeX}
# If possible, show TeX log inside Alpha (doesn't work with all TeX apps)
newPref var  showTeXLog 1 TeX "" \
  [list "Never" "Only after error" "Always"] index
# Pressing this key will insert a subscript _{} if the context is relevant
newPref binding smartSubscripts "/_<U" TeX "" TeX::smartSubscripts
# Pressing this key will insert a superscript _{} if the context is relevant
newPref binding smartSuperscripts "/^<U" TeX "" TeX::smartSuperscripts
# The delimiter to use by default in labels inserted into the text.  For
# instance the default is a colon, so labels are written \label{fig:...} or
# \label{eq:...}.  You may prefer a hyphen '-' or  ...
newPref var  standardTeXLabelDelimiter ":" TeX {TeX::adjustElectricLabels}
# Files with these suffixes are considered TeXable.
newPref var  texableFileExtensions \
   [list .tex .dtx .ins .ltx .drv .fdd .err .mtx .etx .texi] TeX
# Where your TeX application searches for input files.  You should add
# your 'texmf' and 'localtexmf' directories to this list.  When using
# F6 to jump to a file, TeX mode will search recursively in these
# locations.
newPref var  TeXSearchPath "" TeX {TeX::resetTeXInputs}
# This regular expression is used to determine where words start and stop.
newPref var  wordBreak {(([[:alnum:]])+|\\(\\|[a-zA-Z]+)\*?|\\[^a-zA-Z*\t\r\n \s])} TeX

# This regular expression is used to determine when words should be broken to
# be wrapped.
#newPref var  wrapBreak {(\w+|\\(\\\*?|[^A-Za-z\t\r*\s\]|[A-Za-z]+\*?))} TeX
#newPref var  wrapBreakPreface {([^\w\\]|.\\)} TeX

# Inserts a duplicate of the "LaTeX Menu > Process" menu, giving you easy 
# access to all of the various typesetting and related commands.
newPref flag "ProcessMenu" 1 contextualMenuTeX

# As far as I can tell, this pref is only used by the [TeX::isInMathMode]
# procedure which doesn't seem to be called by any other code ...  -- cbu
prefs::deregister "mathEnvironments" "TeX"

# ×××× Program Prefs ×××× #

# This preference contains the list of available TeX programs.  The selected
# program will be used by any "Typeset" menu item in the "Process" submenu.
newPref var  availableTeXPrograms [list \
  "tex" "etex" "pdftex" "pdfetex" \
  ] TeX {TeX::rebuildMenu}

#"latex" "pdflatex"

# Name of the current TeX program to use when typesetting.
newPref var  nameOfTeXProgram "tex"  TeX \
  {TeX::rebuildMenu} $TeXmodeVars(availableTeXPrograms)

# These are always auto-saved.
prefs::modified TeXmodeVars(nameOfTeXProgram)

# These are  best set using the TeX menu.
prefs::deregister "availableTeXPrograms" "TeX"
prefs::deregister "nameOfTeXProgram"     "TeX"

if {$alpha::macos} {
# (CMacTeX only) BibTeX options
newPref var  bibtexOptions "" TeX
# (CMacTeX only) dvips options
newPref var  dvipsOptions  "" TeX
}

# ×××× Format Prefs ×××× #

# Turn this item on to automatically synchronize the TeX Format variable with
# the format found in the first line in a file when it is brought to the
# front|| Turn this item off to never change the TeX Format variable without
# some explicit user action
newPref flag autoAdjustFormat  "1" TeX
# This preference contains a list of available TeX formats, which appear in
# the "Process --> TeX Formats" submenu.  Selecting any of these items will
# reset the current TeX Format, and if the format given in the first line of
# the base TeX file (something like %&LaTeX) is different from the format
# chosen you are asked if you want to include this format line.
newPref var  availableTeXFormats [list \
  "LaTeX" "TeX" "Big-LaTeX" "AMS-TeX" "Plain TeX" "(-)" \
  "eTeX" "eLaTeX" "PDFTeX" "PDFLaTeX" "PDFeTeX" "PDFeLaTeX" \
 ] TeX
# Name of the current TeX format.  Note that if the "Auto Adjust Format"
# preference is turned on then whenever a TeX file is opened or brought up
# front we attempt to synchronize this preference with the format name
# contained in the first line of the base file (i.e. %&LaTeX), and when you
# manually change the format it will be inserted in the base file.
newPref var  nameOfTeXFormat "LaTeX" TeX \
  {TeX::rebuildMenu} $TeXmodeVars(availableTeXFormats)

# These are always auto-saved.
prefs::modified TeXmodeVars(nameOfTeXFormat)
prefs::modified TeXmodeVars(availableTeXFormats)

# These are best set using the TeX menu.
prefs::deregister "autoAdjustFormat"    "TeX"
prefs::deregister "availableTeXFormats" "TeX"
prefs::deregister "nameOfTeXFormat"     "TeX"

# ×××× MacOS specific prefs ×××× #

# Add some var preferences specific to Textures, CMacTeX, etc.

if {[set alpha::macos]} {
    
    # Add MakeIndex style prefs for CMacTeX
    
    # (CMacTeX only) This is the default index style used by MakeIndex
    # preference is set.
    newPref var  TeXindexStyle  ""    TeX {TeX::rebuildMenu}
    # (CMacTeX only) This is the saved list of index styles to choose from.
    newPref var  TeXindexStyles ""    TeX {TeX::rebuildMenu}
    # (CMacTeX only) This is the default glossary style used by MakeGlossary.
    newPref var  TeXglossaryStyle ""  TeX {TeX::rebuildMenu}
    # (CMacTeX only) This is the saved list of glossary styles to choose from.
    newPref var  TeXglossaryStyles "" TeX {TeX::rebuildMenu}

    # These are best set using the TeX menu.
    prefs::deregister "TeXindexStyle"       "TeX"
    prefs::deregister "TeXindexStyles"      "TeX"
    prefs::deregister "TeXglossaryStyle"    "TeX"
    prefs::deregister "TeXglossaryStyles"   "TeX"
    
    # A little insurance to make sure we don't have any empty list items.
    set TeXmodeVars(TeXindexStyles) [lremove -all $TeXmodeVars(TeXindexStyles) [list ""]]
    set TeXmodeVars(TeXindexStyles) [lremove -all $TeXmodeVars(TeXglossaryStyle) [list ""]]

    # This will allow us to easily add additional options later if future
    # updates require more changes.
    set TeX::TexturesVersions [list "Less than 2.0" "2.0 or greater"]
    set TeX::OzTeXVersions    [list "Less than 5.0" "5.0 or greater"]

    if {0} {
	# (Textures only) Adjust this preference according to the version number
	# of the Textures application you are using.
	newPref var  versionForTextures "1" TeX {TeX::resetTexturesInterface} \
	  [set TeX::TexturesVersions] index
    }

    proc TeX::resetAvailableFormats {args} {
	
	global TeXmodeVars
	
	set availableFormats $TeXmodeVars(availableTeXFormats)
	
	# Divide the list into two if possible.
	if {[set idx [lsearch $availableFormats "(-)"]] != "-1"} {
	    set firstList [lrange $availableFormats 0 [expr {$idx - 1}]]
	    set theRest   [lrange $availableFormats [expr {$idx + 1}] end]
	} else {
	    set firstList [list]
	    set theRest   $availableFormats
	}
	set newVariants [list]
	# Adjust the list.
	if {[llength $args]} {TeX::rebuildMenu "TeX Format"}
    }
    # Call this now.
    TeX::resetAvailableFormats
}

# ==========================================================================
#
# ×××× Colorization ×××× #
#


set TeX::escapeChar "\\"

set TeX::commentCharacters(General)   "%"
set TeX::commentCharacters(Paragraph) [list "%% " " %%" " % "]
set TeX::commentCharacters(Box)       [list "%" 1 "%" 1 "%" 3]

newPref color keywordColor blue    TeX {TeX::colorizeTeX}
newPref color sectionColor magenta TeX {TeX::colorizeTeX}
newPref color commentColor red     TeX {stringColorProc}
newPref color bracesColor  green   TeX {TeX::colorizeTeX}
if {${alpha::platform} eq "tk"} {
newPref color singleDollarMathColor  green   TeX {TeX::colorizeTeX}
}

# Call this now so that the rest can be adds.
regModeKeywords -C -e {%} -c $TeXmodeVars(commentColor) {TeX} {}

# 'TeX::colorizeTeX' is executed whenever the TeX mode preferences
# 'citeCommands' 'refCommands' 'boxMacroNames' or any of the color prefs are
# changed.

proc TeX::colorizeTeX {{pref ""}} {

    global TeXmodeVars

    # Color and underline command-double-clickable LaTeX commands:

    set LaTeXClickWords [list]
    # Ensure that 'citeCommands' contains "cite" and "nocite":
    lunion TeXmodeVars(citeCommands) cite nocite
    foreach word $TeXmodeVars(citeCommands) {
        lappend LaTeXClickWords "\\$word"
    }
    # Ensure that 'refCommands' contains "ref" and "pageref":
    lunion TeXmodeVars(refCommands) ref pageref
    foreach word $TeXmodeVars(refCommands) {
        lappend LaTeXClickWords "\\$word"
    }
    # Add box macro names.
    foreach word $TeXmodeVars(boxMacroNames) {
	lappend LaTeXClickWords "\\$word"
    }
    # Add more keywords that can be command-double-clicked.
    lappend LaTeXClickWords \\documentclass \\usepackage \\input \
      \\include \\InputIfFileExists \\bibliography \\bibliographystyle \
      \\LoadClass \\RequirePackage

    regModeKeywords -a -u -k $TeXmodeVars(keywordColor) TeX $LaTeXClickWords

    # Color sectioning commands:
    
    lappend LaTeXSectionWords \\part \\chapter \\section \\subsection \
      \\subsubsection \\paragraph \\subparagraph

    regModeKeywords -a -k $TeXmodeVars(sectionColor) TeX $LaTeXSectionWords

    # Color braces and dollar signs

    if {[info exists TeXmodeVars(singleDollarMathColor)] \
      && $TeXmodeVars(singleDollarMathColor) != "none"} {
	regModeKeywords -a \
	  -i "\}" -i "\{" -I $TeXmodeVars(bracesColor) \
	  -m "\\" -k $TeXmodeVars(keywordColor) TeX {}
	regModeKeywords -a -s $TeXmodeVars(singleDollarMathColor) -q \$ \$ TeX {}
    } else {
	regModeKeywords -a \
	  -i "\}" -i "\{" -i "\$" -I $TeXmodeVars(bracesColor) \
	  -m "\\" -k $TeXmodeVars(keywordColor) TeX {}
    }

    if {[string length $pref]} {refresh}
}

# Call this now.
TeX::colorizeTeX

# ===========================================================================
# 
# ×××× Categorized Prefs ×××× #
# 
# Categorize all TeX preferences.  When the dialogues are actually built,
# there will most likely be added a Miscellaneous pane.  This happens
# whenever there are prefs which are not categorized --- all TeX mode package
# prefs are of this sort.
# 
# Note that we can add preferences to these categories that are not defined
# due to platform specifics; if they are not "registered" then they simply
# won't appear in the preferences dialog.
# 

##### Editing #####
prefs::dialogs::setPaneLists "TeX" "Editing" [list \
  "indentLaTeXEnvironments" \
  "indentationAmount" \
  "fillColumn" \
  "leftFillColumn" \
  "wordBreak" \
  "lineWrap" \
  ]
  
##### Electrics #####
prefs::dialogs::setPaneLists "TeX" "Electrics" [list \
  "deleteEnvNoisily" \
  "deleteObjNoisily" \
  "indentOnReturn" \
  "standardTeXLabelDelimiter" \
  "useBrackets" \
  "useLabelPrefixes" \
  "warnIfPackageNotIncluded" \
  "smartDots" \
  "smartQuotes" \
  "smartQuoteStyle" \
  "smartSubscripts" \
  "smartSuperscripts" \
  ]

##### Navigation #####
prefs::dialogs::setPaneLists "TeX" "Navigation" [list \
  "autoMark" \
  "funcExpr" \
  "funcExprAlt" \
  "markCommandsNotStructure" \
  "navigateParagraphs" \
  "parseExpr" \
  "takeOverNumericKeypad" \
  "citeCommands" \
  "refCommands" \
  "boxMacroNames" \
  ]

# This is just a placeholder.
prefs::dialogs::setPaneLists "TeX" "TeX Filesets" [list]

##### Comments #####
# It's perhaps a pity to have so few prefs in a single pane, but on the other
# hand the title of the pane is so clear that you'll rarely have to look into
# this pane, and hence you should not be bothered by its sparseness.
prefs::dialogs::setPaneLists "TeX" "Comments" [list \
  "commentColor" \
  "commentsContinuation" \
  "prefixString" \
  ]

##### Colors #####
# It's perhaps a pity to have so few prefs in a single pane, but on the other
# hand the title of the pane is so clear that you'll rarely have to look into
# this pane, and hence you should not be bothered by its sparseness.  (The
# true reason for this group is of course that it doesn't fit into any other
# pane it could reasonably be related to.)
prefs::dialogs::setPaneLists "TeX" "Colors" [list \
  "bracesColor" \
  "keywordColor" \
  "sectionColor" \
  "singleDollarMathColor" \
  ]

##### Typesetting #####
# Many of the typesetting prefs are implementation specific, so in practice
# this long list will fit into one pane, except possibly for CMacTeX...
# Perhaps it would be better to have a separate pane for CMacTeX --- then by
# the smart mechanism at the end of [prefs::dialogs::modePrefs], if these are
# all hidden there will be no pane.
prefs::dialogs::setPaneLists "TeX" "Typesetting" [list \
  "autoAdjustFormat" \
  "availableTeXFormats" \
  "availableTeXPrograms" \
  "nameOfTeXFormat" \
  "nameOfTeXProgram" \
  "runTeXInBack" \
  "showTeXLog" \
  "useTexturesFlashMode" \
  "TeXSearchPath" \
  "additionalTeXFlags" \
  "auxFileExtensions" \
  "texableFileExtensions" \
  "dvipsOptions" \
  "bibtexOptions" \
  "TeXglossaryStyle" \
  "TeXglossaryStyles" \
  "TeXindexStyle" \
  "TeXindexStyles" \
  ]

##### Menu prefs #####
# The following pane will actually not be built, because all these
# flags and variables are hidden ---  they are supposed to be
# accessed from the menu:
prefs::dialogs::setPaneLists "TeX" "LaTeX Menu" [list \
  "buildPkgsSubmenu" \
  "compressMathMenus" \
  "compressTextMenus" \
  "mathEnvironments" \
  "useAMSLaTeX" \
  "useDollarSigns" \
  ]

# ==========================================================================
#
# ×××× Updating Prefs Info ×××× #
#

## 
 # --------------------------------------------------------------------------
 # 
 # "TeX::resetInvisiblePrefs" --
 # 
 # Ensure that implementation specific prefs only show up when that
 # implementation is active.
 # 
 # --------------------------------------------------------------------------
 ##

proc TeX::resetInvisiblePrefs {args} {
    
    switch -- [::xserv::getCurrentImplementationNameFor tex ""] {
        "TeXtures" {
	    prefs::deregister "versionForCMacTeX"       "TeX"
            prefs::register   "versionForTextures"      "TeX"
            prefs::register   "useTexturesFlashMode"    "TeX"
            prefs::deregister "dvipsOptions"            "TeX"
        }
        "CMacTeX" {
	    prefs::register   "versionForCMacTeX"       "TeX"
            prefs::deregister "versionForTextures"      "TeX"
            prefs::deregister "useTexturesFlashMode"    "TeX"
            prefs::register   "dvipsOptions"            "TeX"
        }
        default {
	    prefs::deregister "versionForCMacTeX"       "TeX"
            prefs::deregister "versionForTextures"      "TeX"
            prefs::deregister "useTexturesFlashMode"    "TeX"
            prefs::register   "dvipsOptions"            "TeX"
        }
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "TeX::resetSigInfo" --
 # 
 # This proc is called just the first time this code is sourced in any
 # editing session, but with no arguments.  It used to be called when the
 # "texSig" changed, but not any more.
 # 
 # This procedure must rebuild the menu!
 # 
 # --------------------------------------------------------------------------
 ##

proc TeX::resetSigInfo {args} {

    global TeX::PackagesSubmenuItems TeXmodeVars AllTeXSearchPaths

    # Reset the Packages submenu so that it will be rebuilt:
    set TeX::PackagesSubmenuItems ""
    if {[info exists TeXmodeVars(versionForTextures)]} {
	# Set things up for Textures
	TeX::Textures::setInfo
    }
    TeX::resetInvisiblePrefs
    menu::buildSome texMenu
    # Reset the search path so it will be rebuilt the next time it's needed:
    set AllTeXSearchPaths {}
}

proc TeX::resetTeXInputs {args} {

    global TeX::PackagesSubmenuItems AllTeXSearchPaths

    prefs::modified TeXmodeVars(TeXSearchPath)
    # Reset the Packages submenu so that it will be rebuilt:
    set TeX::PackagesSubmenuItems ""

    status::msg "Rebuilding the Documents submenuÉ"
    TeX::rebuildMenu "Documents"
    status::msg ""

    # Reset the search path so it will be rebuilt the next time it's needed:
    set AllTeXSearchPaths {}
    
}

##
 # --------------------------------------------------------------------------
 #
 # "TeX::updateCiteCommands" --
 #
 # Called whenever the user changes the "citeCommands" preference.  We need to
 # add the list of commands to colorization routines, and make sure that they
 # are all defined with simple Electric Completions.
 # 
 # --------------------------------------------------------------------------
 ##

proc TeX::updateCiteCommands {args} {
    
    eval TeX::colorizeTeX $args
    eval TeX::adjustElectricLabels $args
    return
}

# ×××× -------- ×××× #

# Some more standard mode stuff.

# ==========================================================================
#
# ×××× Indentation ×××× #
#

# Basically adjust \begin, \end appropriately.

proc TeX::correctIndentation {args} {
    win::parseArgs w pos {next ""}

    global TeXmodeVars commentsArentSpecialWhenIndenting

    set pos0 [pos::math -w $w [lineStart -w $w $pos] - 1]
    set pat1 "^\[ \t\]*\[^ \t\n\r\]"
    set pat2 "^\[ \t\]*\[^ \t\n\r%\]"

    # Find last non-empty, non-comment line
    if {$commentsArentSpecialWhenIndenting} {
        if {[catch {search -w $w -s -f 0 -r 1 -i 0 -m 0 -- $pat1 $pos0} match]} {
            return 0
        }
    } else {
        if {[catch {search -w $w -s -f 0 -r 1 -i 0 -m 0 -- $pat2 $pos0} match]} {
            return 0
        }
    }
    set pos1   [lindex $match 0]
    set pos2   [pos::math -w $w [nextLineStart -w $w $pos1] - 1]
    set pos3   [pos::math -w $w [lindex $match 1] - 1]
    set line   [getText -w $w $pos1 $pos2]
    set lwhite [lindex [pos::toRowCol -w $w $pos3] 1]
    if {$TeXmodeVars(indentLaTeXEnvironments) && ![regexp -- {\\begin.+document} $line]} {
        incr lwhite [expr {[text::getIndentationAmount -w $w] * \
          ([regexp -- {^[ \t]*\\begin\{} $line] - [regexp -- {^\\end\{} $next])}]
    }
    # Only happens with poorly formatted files.
    if {$lwhite < 0} {return 0} else {return $lwhite}
}

# ==========================================================================
#
# ×××× Mark Menu, Parse Funcs, Folding ×××× #
#

# Bugs (features ?) :  -- a sectioning command must be on a line by itself.
# 
# Should section commands in comments be ignored?  Toggle the 'pat2'
# expression below.

proc TeX::MarkFile {args} {
    win::parseArgs win
    
    global markCommandsNotStructure TeXmodeVars mode

    set ext [string tolower [file extension $win]]
    
    set mk [win::getModeVar $win markCommandsNotStructure]
    
    if {[lsearch -exact $mk $ext] != -1} {
        return [TeX::Sty_MarkFile -w $win]
    }
    status::msg "Marking Window É"
    set pos [minPos -w $win]
    set leader {}
    # Vince's improvement (but doesn't allow embedded braces):
    # JEG improvement (add's includegraphics)
    set pat1 {\\((sub)*section|part|chapter|input|include|usepackage|includegraphics)(\[[^]]*\]|\*)?\{}
    set chapters [set sections [set subsections 0]]
    set sectioning ""
    while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 0 $pat1 $pos} match]} {
        set pos0 [lindex $match 0]
        set pos1 [lindex $match 1]               ;# Brace start
	# Brace end
        if {[catch {matchIt -w $win "\{" $pos1} pos2]} {
	    # Hmm the section name probably contains unmatched
	    # parentheses of other characters.  We cope by trying
	    # to find the first closing brace
	    if {[catch {search -w $win -s -f 1 -m 0 "\}" $pos1} pos2]} {
		set pos2 [pos::math -w $win [pos::lineEnd -w $win $pos1] -1]
	    } else {
	        set pos2 [lindex $pos2 1]
	    }
	}
	set pos  [pos::math -w $win $pos2 + 1]           ;# Used for the next round
	set cmd  [getText -w $win $pos0 $pos1]           ;# the command
        set bcnt [getText -w $win $pos1 $pos2]           ;# the contents of the braces
	
	# This will ignore comments and commands embedded in text.
# 	set pat2 "^\[\t \]*[quote::Regfind $cmd]"

	# This includes comments, but will ignore commands embedded in text. 
	# (Useful if you have defined some other command for sectioning but
	# still want to include commented \section{text} for file marking.
	set pat2 "^\[%\t \]*[quote::Regfind $cmd]"

	if {![regexp $pat2 [getText -w $win [pos::lineStart -w $win $pos1] $pos1]]} {continue}

	regsub -all "\\\\label\{\[^{}\]*\}" $bcnt "" bcnt
	regsub -all "\\\\\[a-z\]+\{(\[^{}\]+)\}" $bcnt "\\1" bcnt
        regsub -all "\[{}\]" [string trim $bcnt] "" bcnt
	
        if {![string length $bcnt]} {continue}
	
	set item ""
	set cmdName [TeX::extractCommandName $cmd]
	if {[regexp -- {((sub)*)section} $cmdName dummy prefix]} {
	    # Indent \(sub)*section or \(sub)*section*:
	    set spaces [expr 2 * [string length $prefix] / 3]
	    append item $leader [format "%$spaces\s" ""]
	    set sectioning  [format "%$spaces\s" ""]
	    if {[string length $prefix]} {
		incr subsections
	    } else {
		incr sections
	    }
	} elseif {[regexp {chapter} $cmdName]} {
	    # If \chapter or \chapter*, indent next \(sub)*section:
	    set leader {  }
	    set sectioning ""
	    incr chapters
	} elseif {[regexp {part} $cmdName]} {
	    set item "¥ $item"
	} elseif {[regexp {includegraphics} $cmdName]} then {
	    # Mark \includegraphics (JEG):
	    append item "${leader}${sectioning} È "
	} else {
	    # Mark \input, \include, and \usepackage (VD):
	    append item "È"
	}
	# Remove all superfluous whitespace (WTP):
	regsub -all "\[\ \r\n\t\]\+" $bcnt { } bcnt
	# Limit the width of the menu item and build the menu item:
	append item [markTrim $bcnt]
	# Create the mark:
	while {[lcontains marks $item]} {append item " "}
	lappend marks $item
	setNamedMark -w $win $item [pos::lineStart -w $win [pos::math -w $win $pos0 - 1]] $pos0 $pos0
    }
    if {$chapters == "1"} {
	set msg "$chapters chapter ; "
    } elseif {$chapters > 1} {
        set msg "$chapters chapters ; "
    }
    if {$sections == "1"} {
	append msg "$sections section ; "
    } else {
	append msg "$sections sections ; "
    }
    if {$subsections == "1"} {
        append msg "$subsections subsection"
    } else {
	append msg "$subsections subsections"
    }
    status::msg $msg
}

proc TeX::Sty_MarkFile {args} {
    win::parseArgs win

    set pos [minPos -w $win]
    set pat {\\((re)?newcommand(\*)?\{|(e|g|x)?def|DeclareRobustCommand(\*)?\{|providecommand(\*)?\{)\\([^[\#\\\{\}\r\n%]*)}
    set items [list]
    while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 0 $pat $pos} match]} {
        set posBeg [lindex $match 0]
        set posEnd [lindex $match 1]
        set cmd    [getText -w $win $posBeg $posEnd]
        if {[regexp -- $pat $cmd d d d d d d d item]} {
            # limit the width of the menu item, and save it.
            lappend items [list [markTrim $item] $posBeg]
        }
        set pos [pos::math -w $win $posEnd + 1]
    }
    foreach i [lsort -dictionary $items] {
        set pos      [lindex $i 1]
        setNamedMark -w $win [lindex $i 0] [pos::lineStart -w $win [pos::math -w $win $pos - 1]] $pos $pos
    }
}

proc TeX::parseFuncs {} {

    global funcExpr parseExpr

    set m   [list]
    set pos [minPos]
    while {![catch {search -s -f 1 -r 1 -i 0 -- $funcExpr $pos} match]} {
	set pos0 [lindex $match 0]
	set pos1 [pos::math [nextLineStart [lindex $match 1]] - 1]
        set line [getText $pos0 $pos1]
        if {[regexp -- $parseExpr $line -> word]} {
	    if {[regexp {\\(sub)*} $line num]} {
		set num [expr {[string length $num]/3}]
	    } else {
		set num 0
	    }
	    regsub -all "\\s+" $word { } word
	    set mark "[format %${num}s {}]$word"
	    if {[regexp {\\part} $line]} {
	        set mark "¥ $mark"
	    } elseif {[regexp {\\chapter} $line]} {
	        set mark "* $mark"
	    }
	    # Ensure unique names
	    if {[info exists already($mark)]} {
		append mark " "
	    }
            lappend m $mark $pos0
	    set already($mark) 1
        }
        set pos [lindex $match 1]
    }
    return $m
}

proc TeX::foldableRegion {pos} {

    global funcExpr
    # First check if inside a footnote
    if {[TeX::isInCommand "footnote" $pos range]} {
	return [lrange $range 1 2]
    }
    # Return beginning and end of block to fold.
    set prev [search -s -f 0 -r 1 -i 0 -n $funcExpr $pos]
    if {![llength $prev]} {return}
    set next [search -s -f 1 -r 1 -i 0 -n $funcExpr $pos]
    if {![llength $next]} {
        set next [maxPos]
    } else {
        set next [pos::math [lindex $next 0] -1]
        while {[string trim [getText [pos::lineStart $next] \
          [pos::lineEnd $next]]] == ""} {
            set next [pos::prevLineEnd $next]
            if {[pos::compare $next <= $pos]} {break}
        }
    }
    return [list [pos::lineEnd [lindex $prev 1]] $next]
}

# ==========================================================================
#
# ×××× Command-double-clicking ×××× #
#
# In TeX mode, use cmd-double-clicks to follow references and citations,
# or open input files.
#
# (originally written by Tom Pollard and Andreas Amann)
#
# Remaining bugs:
#   - search is successful even if the pattern is commented out
#     (which is a bug or a feature, depending how you look at it)

# Extended to work with filesets and with better bib code

proc TeX::DblClick {from to shift option control} {

    if {[file extension [win::Current]] == ".blg" \
      || [win::StripCount [win::Current]] == "* bibtex log *"} {
	# Use the bibtex log helper package.
        Bib::blgDoubleClick $from $to
        return
    }
    global TeXmodeVars

    # CONTROL -- send to url for LaTeX command help
    if {$control != 0} {
        selectText $from $to
        regsub {\\} [getSelect] {} cmd
	TeX::wwwCommandHelp $cmd
        return
    }

    # Extend selection to largest string delimited by commas or curly-braces
    set text [string trim [eval getText [TeX::extendArg $from $to]]]

    # Set $cmd to TeX command for which the selection is an argument, but
    # only if user clicked on a valid command argument.
    set cmd {}
    if {[set match [TeX::findCommandWithParts $from 0]] != ""} {
        set beg [lindex $match 0]
        set arg [lindex $match 2]
        set end [lindex $match 3]
        # Make sure the user clicked within a TeX argument and not
        # on the command name itself
        if {[pos::compare $from > $arg] && [pos::compare $to < $end]} {
            set cmd [TeX::extractCommandName [getText $beg $arg]]
        }
    }

    switch -- $cmd {
        "@input" -
        "input" -
        "InputIfFileExists" {TeX::openFile $text ".tex"}
        "include"           {TeX::openFile "${text}.tex"}
        "documentclass" -
        "LoadClass"         {TeX::openFile "${text}.cls"}
        "usepackage" -
        "RequirePackage"    {TeX::openFile "${text}.sty"}
        "bibliography"      {Bib::openFile "${text}.bib"}
        "bibliographystyle" {TeX::openFile "${text}.bst"}
        default {
            if {[lsearch -exact $TeXmodeVars(citeCommands) $cmd] >= 0} {
		# \cite, \nocite, etc.
                TeX::dblClickCitation $text
                return
            } elseif {[lsearch -exact $TeXmodeVars(refCommands) $cmd] >= 0} {
		# \ref, \pageref, etc.
                set labelPat {\\label\{}
                # Check for \label in current window/fileset
                if {[TeX::selectPatternInFileOrSet "$labelPat$text\}" "tex"]} {
                    return
                }
                # Only gets here if the search failed
                beep
                returnToBookmark
                status::msg {No matching \label found}
            } elseif {[lsearch -exact $TeXmodeVars(boxMacroNames) $cmd] > -1} {
		# box-making macro ($boxMacroNames)
                if {[file extension $text] == ""} {
                    foreach ext {.eps .ps .epsf} {
                        if {[set f [TeX::findTeXFile $text$ext]] != ""} {
                            break
                        }
                    }
                } else {
                    set f [TeX::findTeXFile $text]
                }
                if {$f != ""} {
                    switch -- [string tolower [file extension $f]] {
                        ".ps" -
                        ".eps" -
                        ".epsf" {
			    set p "Do you wish to view or edit \"[file tail $f]\"?"
                            switch [buttonAlert $p "View" "Edit" "Cancel"] {
                                "View"   {viewPSFile $f ; return}
                                "Edit"   {file::openQuietly $f}
				"Cancel" {error "cancel"}
                            }
                        }
                        default {file::openQuietly $f}
                    }
		    status::msg $f
		}
                # Other
            } else {
                selectText $from $to
                status::msg {Command-double-click on the required argument of an underlined LaTeX command}
            }
        }
    }
}

proc TeX::dblClickCitation {text} {

    global AllTeXSearchPaths

    # Quote regexp-active characters in case we use $text in a regexp search
    set qtext     [quote::Regfind $text]
    set bibPat    "\\bibliography\{"
    set bibTopPat {@\s*([a-zA-Z]+)\s*[\{\(]\s*}

    # Check first in the current window, either for a bib entry or a \bibitem
    if {[TeX::findBibItem $qtext [list [win::Current]]]} {
        return
    }
    # If we're in a fileset...
    if {[set theFileset [isWindowInFileset "" "tex"]] != ""} {
        # search all the files in that fileset for bib entries or \bibitems
        if {[TeX::findBibItem $qtext [fileset::tex::listFiles $theFileset "bib"]]} {
            return
        }
        if {[TeX::findBibItem $qtext [fileset::tex::listFiles $theFileset "tex"]]} {
            return
        }
        beep
        status::msg "can't find \"$text\" in the .bib file(s) or in \\thebibliography"
    } else {
        # if no fileset, and we didn't find it above, look for all the
        # included bibliographies, and search them:
        if {![catch {search -f 0 -r 0 -s -m 0 $bibPat [maxPos]} match]} {
            # Get ALL the bib file names:
            set beg [lindex $match 1]
            set end [matchIt "\{" $beg]
            set bibnames "[split [getText $beg $end] ,]"
            # Check every file:
            foreach fname $bibnames {
		if {[file exists [set ff [file::absolutePath "${fname}.bib"]]]} {
		    if {[selectPatternInFile $ff  $bibTopPat$qtext]} {
			return
		    }
		}
            }
            # Build the TeX search path:
            TeX::ensureSearchPathSet
            # Check every file in the TeX search path:
            foreach fname $bibnames {
                foreach folder $AllTeXSearchPaths {
		    if {[file exists [set ff [file join $folder ${fname}.bib]]]} {
			if {[selectPatternInFile $ff $bibTopPat$qtext]} {
			    return
			}
		    }
                }
            }
            beep
            status::msg "can't find \"$text\" in the .bib file(s)"
        } else {
            beep
            status::msg "can't find a \\bibliography"
        }
    }
    # Search through all the bibliographies using the bibIndex
    # If we find the entry,
    # prompt to insert a new database in the list of bibliographies.
    set c [TeX::currentBaseFile [win::Current]]
    if {![catch {Bib::gotoEntryFromIndex $text}]} {
        if {[askyesno "This entry is in a bibliography file which isn't referenced.  Shall I add it to this document's list of bibliographies?"] == "yes"} {
            Bib::insertNewBibliography $c [file::baseName [win::Current]]
        }
        return
    }
    # There's no matching entry.  Give a list of possibilities.
    Bib::noEntryExists $text [TeX::currentBaseFile]
}

##
 # -------------------------------------------------------------------------
 #
 # "TeX::selectPatternInFileOrSet" --
 #
 #  Useful procedure which will search for a given pattern in all files in
 #  the current fileset (or the fileset of the given window) if such a
 #  fileset exists, and otherwise it will just look at the current tex
 #  window.  The 'types' argument may be '*', 'bib' or 'tex' depending upon
 #  which types of file you wish to search in the fileset.
 #
 #  Returns 1 if successful, else 0.
 # -------------------------------------------------------------------------
 ##

proc TeX::selectPatternInFileOrSet {pat {types "*"} {win ""}} {

    if {$win == ""} {set win [win::Current]}
    if {[set fset [isWindowInFileset $win "tex"]] == ""} {
	if {[selectPatternInFile $win "$pat"]} {return 1}
    } else {
	foreach filename [fileset::tex::listFiles $fset $types] {
	    if {[selectPatternInFile $filename "$pat"]} {return 1}
	}
    }
    return 0
}

proc TeX::findBibItem {qtext fnames} {

    set theBibPat  "\\\\begin\{thebibliography"
    set bibitemPat {\\bibitem(\[[^]]*\])?\{}
    set bibTopPat  {@([a-zA-Z]+)[\{\(][  ]*}
    foreach filename $fnames {
        if ![file exists $filename] {continue}
        switch -- [file extension $filename] {
            ".tex" -
            ".ltx" {
                # Check first for a \thebibliography environment...
                set searchResult [file::searchFor $filename $theBibPat 1]
                if {[set offset [lindex $searchResult 0]] >= 0} {
                    # ...then for the \bibitem, which must be after
                    # \thebibliography declaration to make any sense
                    if {[selectPatternInFile $filename "$bibitemPat$qtext\}" \
		      [pos::math [minPos] + $offset]]} {
                        return 1
                    }
                }
            }
            ".bib" {
                if {[selectPatternInFile $filename $bibTopPat$qtext]} {
                    return 1
                }
            }
        }
    }
    return 0
}

proc TeX::wwwCommandHelp {{cmd ""}} {
    
    global TeXmodeVars
    
    if {![string length $cmd]} {
        if {[catch {prompt "Open a www page for this LaTeX command:" ""} cmd]} {
	    error "cancel"
        } 
    } 
    urlView $TeXmodeVars(LaTeXHelp)$cmd
    status::msg "\"$cmd\" sent to $TeXmodeVars(LaTeXHelp)"
}

# ==========================================================================
#
# ×××× Option Titlebar ×××× #
#

##
 # -------------------------------------------------------------------------
 #
 # "TeXOptionTitlebar"  --
 #
 #  Invoked by option-clicking on the title-bar.  List either all files
 #  in the current fileset (if we're part of one), or just all
 #  input/include files.  Select one to open it in a window.
 # -------------------------------------------------------------------------
 ##

proc TeX::OptionTitlebar {} {

    set subFileCommmands [list \
      include usepackage RequirePackage input bibliography bibliographystyle ]

    if {![win::IsFile [set win [win::Current]]]} {
        return
    } elseif {[set fset [isWindowInFileset $win "tex"]] == ""} {
        # find includes directly
        set cid [scancontext create]
        set lines {}
        # copes with various commands with '[]' optional
        scanmatch $cid "^\[ \t\]*\\\\([join $subFileCommmands |])(\\\[\[^\]\]*\\\])?\{(\[^\r\n\}\]*)\}"  {
            #eval lappend lines [split $matchInfo(submatch2) ,]
            lappend lines [list $matchInfo(submatch0) [split $matchInfo(submatch2) ,]]
        }
        set fid [alphaOpen $win "r"]
        scanfile $cid $fid
        close $fid
        scancontext delete $cid
        if {$lines != ""} {
            foreach l $lines {
                set type [lindex $l 0]
                foreach f [lindex $l 1] {
                    switch -- $type {
			"bibliography"      {lappend files "${f}.bib"}
			"bibliographystyle" {lappend files "${f}.bst"}
                        "include"           {lappend files "${f}.tex"}
                        "input"             {
                            if ![catch {TeX::findTeXFile $f ".tex"} f] {
                                set f [file tail $f]
                                lappend files $f
                            }
                        }
			"RequirePackage"    {lappend files "${f}.sty"}
                        "usepackage"        {lappend files "${f}.sty"}
                        default             {lappend files "${f}"}
                    }
                }
            }
            return $files
        } else {
            # just use files in this directory instead, so signal error
            return [::OptionTitlebar]
        }
    } else {
        set lines [list]
        global fileSetsExtra gfileSets
        lappend lines [file tail [lindex $gfileSets($fset) 0]]
        foreach f $fileSetsExtra($fset) {
            if {[lindex $f 0] == "tex"} {
                lappend lines "[string range {      } 1 [expr {2*[lindex $f 1]}]][lindex $f 2]"
            }
        }
        return $lines
    }
}

##
 # -------------------------------------------------------------------------
 #
 # "TeXOptionTitlebarSelect" --
 #
 #  Procedure called when you select an item from the option pop-up
 #  menu.  We just open the file if we can.  If there isn't a fileset,
 #  this procedure could fail.
 # -------------------------------------------------------------------------
 ##

proc TeX::OptionTitlebarSelect {fname} {

    set fname [string trim $fname]
    if {[set fset [isWindowInFileset "" "tex"]] == ""} {
        switch -- [file extension $fname] {
            ".bib"   {Bib::openFile $fname}
            default  {TeX::openFile $fname}
        }
    } else {
        file::openQuietly [texfs_awkwardGetFile $fset $fname]
    }
}

# ==========================================================================
#
# ×××× -------- ×××× #
#
# ×××× LaTeX initialisation ×××× #
#

# We need to load "latexComm.tcl" to set the TeX app signature arrays, which
# are used to build the menu.

if {[alpha::tryToLoad "Initialising LaTeX" \
  latexBackCompatibility.tcl {Loading back compatibility procsÉ}\
  latexNavigation.tcl        {Loading LaTeX NavigationÉ}\
  appPaths.tcl               {Loading some xserv definitionsÉ}\
  latexComm.tcl              {Loading LaTeX CommandsÉ}\
  latexFilesets.tcl          {Loading LaTeX FilesetsÉ}\
  ::TeX::resetInvisiblePrefs {Setting preferences}]} {
    # nothing
}

if {[alpha::tryToLoad "Initialising LaTeX menu and keys" \
  TeX::bindLaTeXKeys {Binding LaTeX keysÉ} \
  TeX::resetSigInfo  {Building TeX menuÉ}]} {
    # nothing
}

# ==========================================================================
#
# .