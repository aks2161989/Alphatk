## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl support packages
 # 
 # FILE: "alphaDeveloperMenu.tcl"
 #                                          created: 09/10/1997 {11:22:17 am}
 #                                      last update: 05/17/2006 {01:05:03 PM}
 # Description:
 # 
 # Provides useful utilities for Alpha, Alphatk and AlphaTcl developers.
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 #    
 # Includes contributions from Craig Barton Upright.
 #  
 # Copyright (c) 1997-2006  Vince Darley, Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # Based on original 'developerUtilities.tcl', which is now obsolete.
 # 
 # ==========================================================================
 ##

alpha::menu alphaDeveloperMenu 1.3 {global Chng Tcl Inst} "¥1005" {
    # Initialization script.
    alphadev::initializePackage
} {
    # Activation script.
    alphadev::activatePackage 1
} {
    # Deactivation script.
    alphadev::activatePackage 0
} uninstall {
    this-directory
} maintainer {
    "Vince Darley" <vince@santafe.edu> <http://www.santafe.edu/~vince/>
} description {
    Provides utilities for developing Tcl code for use with Alpha and Alphatk
} help {
    This package creates an "AlphaDev" menu that can be placed in the main
    menubar.  This menu includes utilities for creating and modifying the Tcl
    code used by Alpha and Alphatk.
    
    Preferences: Menus
    
    It can also be activated for specific modes, such as "Tcl" or "Chng".
    
    Preferences: Mode-Menus
    
	  	Description

    Its various menu items include utilities for:
    
    ¥ Interacting with the on-line Alpha-Bugzilla database
    ¥ Opening Help files and www links useful to Alpha8/X/tk/Tcl developers
    ¥ Viewing changes to the AlphaTcl CVS repository
    ¥ Creating/editing files in the Smarter Source Folder
    ¥ Marking  and Hyperizing Help files
    ¥ "Prettifying" text, as in "alphaDeveloperMenu" > "Alpha Developer Menu"
    ¥ Inserting AlphaTcl menu/binding codes
    ¥ Surrounding the current word/selection with ¥bullets¥
    ¥ Warning you when obsolete procedures/commands are being called
      (Select "AlphaDev > Warning For Obsolete Procs")
    ¥ Listing all currently defined procedures recognized by the interpreter
    ¥ Listing all currently defined variables recognized by the interpreter
    ¥ Listing procedures, preferences, and variables defined by all modes
    ¥ Rebuilding AlphaTcl indices and filesets
    ¥ Rebuilding menus declared with the proc: menu::buildProc
    ¥ Comparing a file with one from distribution folder
    ¥ Stuffing/uploading/updating distributions
    ¥ Testing the initial loading of all installed modes and menus
    ¥ Adding new entries to 'Changes' files, such as "Changes - AlphaTcl"
      "Changes - Alpha" and "Changes - Alphatk"
      
    Use the "AlphaDev > AlphaDev Menu Bindings" menu item to add/change the
    keyboard shortcuts associated with any of these menu items.
    
    Additional submenu information is available with these hyperlinks:
    
    "AlphaDev > Alpha Bugzilla"     package: reportABug
    "AlphaDev > Alpha Distribution" <<alphadev::dist::helpWindow>>
    "AlphaDev > Alpha Testing"      <<alphadev::testing::helpWindow>>
    "AlphaDev > AlphaDev Web Sites" <<alphadev::www::helpWindow>>
    "AlphaDev > AlphaTcl CVS"       <<alphadev::cvs::helpWindow>>
    "AlphaDev > Smarter Source"     "Smarter Source Help"
    "AlphaDev > Support Folders"    "Support Folders Help"
    
    An "Alpha Dev Utils" contextual menu module is also available for 'Tcl'
    mode, as well as an "Alpha Dev Help" module.
    
    In addition to the utilities provided by the menu items, it also includes
    support for Tcl mode, including
    
    ¥ Creation of Alpha core command electric completions
    ¥ Keyword colorizing for Alpha core commands
    ¥ Document template for packages (requires the package: documentProjects)
}

proc alphaDeveloperMenu.tcl {} {}

namespace eval contextualMenu {
    # Includes a list of Help files that provide more information about how
    # AlphaTcl works and how to modify ÇALPHAÈ's behavior
    newPref flag alphaDevHelpMenu 1 contextualMenu
    # Place this item in the first section.
    variable menuSections
    lappend menuSections(1) "alphaDevHelpMenu"
}

# ×××× Preferences, Etc. ×××× #

# To display a warning when an obsolete command/proc is called in AlphaTcl,
# turn this item on||To disable the warning when obsolete commands/procs
# are called in AlphaTcl, turn this item off
newPref flag warningForObsoleteProcedures 0 global {alphadev::postBuildMenu}

# Document Projects templates support
if {[alpha::package exists documentProjects]} {
    llunion elec::DocTemplates 1 \
      [list Tcl "Alpha package" Basic t_package * \
      [list extension feature library mode menu]]
}

hook::register activateHook {alphadev::activateHook}

# ===========================================================================
# 
# ×××× Keywords ×××× #
# 

# Create the list of obsolete Alpha commands, used in colorizing and
# completions.
# 
# Note: 'message' is not included since that is a Tk command.
# 

set alphaObsCommands {
    icURL select splitWindow zapInvisibles
}

# Create the list of obsolete Alpha procs, as defined in the file
# 'BackCompatibility.tcl'.
# 

set alphaObsProcs {
    dosc eventHandler AEBuild file::move 
    flag::options flag::isIndex flag::addType
    
    status::errorMsg modes modeALike mode::proc mode::getProc splitWindow
    
    helperApps suffixMappings trans setExternalHelpers
    
    dialog::chooseOption dialog::fileMappings dialog::preferences
    dialog::arrangeMenus dialog::globalMenusFeatures
    dialog::modeMenusFeatures dialog::packagesHelp
    dialog::pickMenusAndFeatures dialog::describeMenusAndFeatures
    dialog::_simpleDescribeMenusAndFeatures dialog::modifyModeFlags
    dialog::pkg_options dialog::edit_array dialog::editOneOfMany
    dialog::setDefaultGeometry dialog::makePreferencePages dialog::makePage
    dialog::standard_help dialog::prefs_search dialog::_sortPrefs
    dialog::_arrGet dialog::_pkgGet dialog::_standardGet dialog::_arrSet
    dialog::_pkgSet dialog::_standardSet
    
    global::allPrefs global::allPackages global::menusAndFeatures
    global::menus global::features
    
    mode::menuProc
}

# Create the list of Alpha* core commands procs, as defined in the file
# 'Alpha Commands'.

set alphaKeyWords [list \
  \
  abbreviateText abortEm addAlphaChars addHelpMenu addMenuItem alert alertnote \
  alloced alpha::copyRegion alpha::cutRegion alpha::pasteRegion ascii askyesno \
  \
  backSpace backwardChar backwardCharSelect backwardDeleteWord backwardWord \
  backwardWordSelect balance beginningBufferSelect beginningLineSelect \
  beginningOfBuffer beginningOfLine Bind bindingList blink bringToFront \
  buttonAlert  \
  \
  capitalizeRegion capitalizeWord centerRedraw clear closeFloat \
  colorTagKeywords colorTriple copy createTMark cut cvttime  \
  \
  deleteChar deleteMenuItem deleteModeBindings deleteSelection deleteText \
  deleteWord describeBinding dialog dirs display displayEncoding displayMode \
  displayPlatform displayWrap downcaseWord  \
  \
  edit enableMenuItem endBufferSelect endLineSelect endOfBuffer endOfLine \
  enterReplaceString enterSearchString enterSelection exchangePointAndPin \
  execute  \
  \
  find findAgain findAgainBackward findFile findInNextFile float floatShowHide \
  fold forwardChar forwardCharSelect forwardWord forwardWordSelect  \
  \
  getChar getColors getControlInfo getControlValue getFileInfo getGeometry \
  getMainDevice getModifiers getNamedMarks getPin getPos getScrap getSelect \
  getTMarks getText getTextDimensions getThemeMetrics getWinInfo get_directory \
  getfile getline goto gotoLine gotoMark gotoNamedMark gotoTMark  \
  \
  hiliteToPin \
  \
  icGetPref icon icOpen insertAscii insertColorEscape insertMenu insertText \
  insertToTop iterationCount  \
  \
  keyAscii keyCode killLine killWindow \
  \
  largestPrefix launch lineStart linkVar listpick lookAt ls \
  \
  macro::current macro::endRecording macro::execute macro::recording \
  macro::startRecording markMenuItem matchBrace matchIt maxPos Menu minPos \
  mousePos moveInsertionHere moveWin mtime  \
  \
  nameFromAppl new newPref nextLine nextLineSelect nextLineStart nextSentence \
  now \
  \
  oneSpace openLine otherPane \
  \
  pageBack pageForward pageSetup paste performSearch placeText popd \
  pos::compare pos::diff pos::fromRowChar pos::fromRowCol pos::lineEnd \
  pos::lineStart pos::math pos::nextLineStart pos::prevLineStart pos::toRowChar \
  pos::toRowCol prefixChar previousLine prevLineSelect prevSentence print \
  processes prompt pushd putfile putScrap \
  \
  quit \
  \
  rectangularHiliteToPin redo refresh regModeKeywords removeColorEscapes \
  removeMark removeMenu removeNamedMark removeTMark replace replace&FindAgain \
  replaceAll replaceString replaceText revert \
  \
  save saveAll saveAs saveResources scrollDownLine scrollLeftCol scrollRightCol \
  scrollUpLine search searchString selectText selEnd sendOpenEvent sendToBack \
  setControlInfo setControlValue setFileInfo setFontsTabs setNamedMark setPin \
  setRGB setWinInfo sizeWin specToPathName startEscape status::msg statusPrompt \
  switchTo \
  \
  tab ticks toggleScrollbar toggleSplitWindow \
  \
  unascii unBind undo unfloat upcaseWord \
  \
  version \
  \
  watchCursor windowVisibility winNames wins \
  \
  yank \
  \
  zapNonPrintables zoom \
  ]

# These commands are scheduled to be removed from the "alphaKeyWords" list,
# but they're listed separately for now so that the Alpha Cabal can figure
# out which (if any) of them need to be removed from the Alpha8/X core.  All
# of the 'transition' commands are now AlphaTcl procedures.  (I'm pretty sure
# that the only one remaining in the core is [ls] -- cbu)

set transitionCommands [list \
  copy cut dirs enterReplaceString enterSearchString enterSelection find \
  findAgain findAgainBackward findInNextFile getAscii ls newPref nextSentence \
  paste performSearch popd prevSentence pushd replace replace&FindAgain \
  replaceAll replaceString searchString sendOpenEvent zoom  \
  ]

# These commands are scheduled to be removed from the "alphaKeyWords" list,
# but they're listed separately for now so that the Vince can figure out
# which (if any) of them need to be removed from the Alphatk core.  None of
# the 'removed' commands are defined by Alpha8/X.

set removedCommands {
    sendToBack
}

# After the cores have been dealt with, the "alphaKeyWords" list above will
# be properly adjusted, and sorted alphabetically.  Until then, we take care
# of removing things here.  (All of this has helped to make the changes more
# obvious when comparing to earlier AlphaTcl CVS versions.)

set alphaKeyWords [lremove $alphaKeyWords $transitionCommands]
set alphaKeyWords [lremove $alphaKeyWords $removedCommands]
set alphaKeyWords [lsort -dictionary $alphaKeyWords]

eval [list lappend alphaObsCommands] $removedCommands
set alphaObsCommands [lsort -dictionary -unique $alphaObsCommands]

unset transitionCommands removedCommands

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Alpha Dev Menu, Support ×××× #
# 

namespace eval alphadev {
    
    global alpha::platform alphaDevMenuBindingsmodeVars
    
    variable initialized
    if {![info exists initialized]} {
        set initialized 0
    }
    variable activated
    if {![info exists activated]} {
	set activated -1
    }
    # List of menus rebuilt via the menu item.
    variable lastRebuiltMenus
    if {![info exists lastRebuiltMenus]} {
        set lastRebuiltMenus [list]
    } 
    # Rename old menu item binding preferences.
    prefs::renameOld "alphaDevMenuBindings(Rebuild AlphaTcl Indices)" \
      "alphaDevMenuBindings(Rebuild AlphaTcl IndicesÉ)"
    
    # Default menu items, submenus.  Each item 1-4 represents a section in
    # the AlphaDev menu that contains a particular grouping of items.
    variable menuItems
    variable submenus
    # 'Global' items, those that in general provide access to
    # the world outside of Alpha.
    lunion submenus(1) \
      "Alpha Bugzilla" \
      "Alpha Testing" \
      "AlphaDev Help Files" \
      "AlphaDev Web Sites" \
      "AlphaTcl CVS" \
      "Smarter Source" \
      "Support Folders"
    lunion menuItems(1)
    # Items related to the text in the current window.
    lunion submenus(2) \
      "Help File Marking"
    lunion menuItems(2) \
      "Prettify Text" \
      "Insert Menu CodesÉ" \
      "Insert Binding CodesÉ" \
      "Surround With Bullets"
    # Utilities that relate to the AlphaTcl library.
    lunion submenus(3)
    lunion menuItems(3) \
      "Warning For Obsolete Procs" \
      "List ProceduresÉ" \
      "List Mode ProcsÉ" \
      "List VariablesÉ" \
      "List Mode VarsÉ" \
      "List Mode PrefsÉ"
    lunion submenus(4)
    lunion menuItems(4) \
      "Rebuild AlphaTcl IndicesÉ" \
      "Rebuild AlphaTcl Filesets" \
      "Rebuild A MenuÉ"
    # Utilities for distributing Alpha.
    lunion submenus(5) \
      "Alpha Distribution"
    lunion menuItems(5) \
      "Update 'Alpha Changes'" \
      "Update 'AlphaTcl Changes'"
    if {${alpha::platform} == "tk"} {
	lunion menuItems(5) "Update 'Alphatk Changes'"
    }
    # Menu bindings.  Items in preference arrays cannot have spaces in their
    # names else dialogs fail horribly (this is apparently by design) so we
    # have to do a little song and dance here and when building the menu.
     set menuItemsWithBindings [list \
      "PrettifyText" \
      "InsertMenuCodesÉ" \
      "InsertBindingCodesÉ" \
      "SurroundWithBullets" \
      "ListProceduresÉ" \
      "ListModeProcsÉ" \
      "ListVariablesÉ" \
      "ListModeVarsÉ" \
      "ListModePrefsÉ" \
      "RebuildAlphaTclIndices" \
      "RebuildAlphaTclFilesets" \
      "RebuildAMenuÉ" \
      "Update'AlphaChanges'" \
      "Update'AlphaTclChanges'" \
      "ViewCVSChangesToWindow" \
      ]
    if {${alpha::platform} == "tk"} {
	lappend menuItemsWithBindings "Update'AlphatkChanges'"
    }
    array set defaultMenuBindings {
	surroundWithBullets     /8<U<B
    }
    foreach item $menuItemsWithBindings {
	if {[info exists defaultMenuBindings($item)]} {
	    set defaultBinding $defaultMenuBindings($item)
	} else {
	    set defaultBinding ""
	}
	newPref menubinding $item $defaultBinding alphaDevMenuBindings
    }
    newPref flag activateBindingsInTclModeOnly 1 alphaDevMenuBindings
    # Obsolete menu bindings.  These were in earlier versions.
    set obsoleteBindings [list \
      "viewCvsChangesToFile" \
      "prettifyText" \
      "insertMenuCodesÉ" \
      "insertBindingCodesÉ" \
      "surroundWithBullets" \
      "listFunctions" \
      "ListFunctions" \
      "rebuildTclIndices" \
      "rebuildAMenuÉ" \
      "update'AlphaChanges'" \
      "update'AlphaTclChanges'" ]
    foreach obsBinding $obsoleteBindings {
	prefs::removeObsolete alphaDevMenuBindingsmodeVars($obsBinding)
    }
    # Cleanup.
    unset -nocomplain defaultBinding menuItemsWithBindings item \
      obsoleteBindings obsBinding
}

proc alphadev::initializePackage {} {
    
    global tclCmdColourings
    
    variable initialized
    
    if {$initialized} {
        return
    }
    # Initialization script.
    lappend tclCmdColourings "Tcl::colorAlphaKeywords" "Tcl::colorObsCommands"
    # Colour to use for Alpha's built in commands.
    newPref color alphaColor {none} Tcl {Tcl::updatePreferences}
    # Turn this item on to colour red all obsolete Alpha procs and obsolete
    # core commands||Turn this item off to disable coloring of obsolete
    # Alpha procs and colour obsolete core commands using the Alpha color
    newPref flag recognizeObsoleteProcs 1 Tcl {Tcl::updatePreferences}
    # Has Tcl mode already colorized its keywords?
    if {[llength [info procs ::Tcl::colorizeTcl]]} {
	# Yes, so we need to re-colorize all of them.
	Tcl::colorizeTcl
	if {([win::getMode] eq "Tcl")} {
	    refresh
	}
    } 
    # Define menu building procs.
    menu::buildProc alphaDeveloperMenu {alphadev::buildMenu} \
      {alphadev::postBuildMenu}
    menu::buildProc "AlphaDev Web Sites" {alphadev::www::buildMenu} \
      {alphadev::www::postBuildMenu}
    menu::buildProc "AlphaTcl CVS" {alphadev::cvs::buildMenu}
    menu::buildProc "Alpha Distribution" {alphadev::dist::buildMenu}
    menu::buildProc "Alpha Testing" {alphadev::testing::buildMenu}
    menu::buildProc "Smarter Source" {alphadev::ss::buildMenu} \
      {alphadev::ss::postBuildMenu}
    menu::buildProc "Support Folders" {alphadev::support::buildMenu} \
      {alphadev::support::postBuildMenu}
    # Build the menu.
    menu::buildSome alphaDeveloperMenu
    # Define additional electrics for Alpha* core commands.  (Note that this
    # file will have already been sourced, so any variables defined below
    # will now be available.)
    AlphaTclCompletions.tcl
    
    set initialized 1
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::activatePackage" --
 # 
 # Called when this package is being turned on and off.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::activatePackage {which} {
    
    variable activated
    
    if {($which == $activated)} {
        return
    }
    if {$which} {
	alphadev::OWH "register"
	if {![llength [info procs ::Tcl::getProcArgs]]} {
	    auto_load ::Tcl::getProcArgs
	}
	catch {hook::procRename {::Tcl::getProcArgs} {::alphadev::getProcArgs}}
    } else {
	alphadev::OWH "deregister"
	catch {hook::procRevert {::alphadev::getProcArgs}}
    }
    set activated $which
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "alphadev::buildMenu" --
 # 
 # Create the AlphaDev menu.
 # 
 # Developer Notes:
 # 
 # All of the submenus are registered and built by other packages in
 # AlphaTcl.  For example, the 'preinit' script in "alphaTclCvs.tcl"
 # declares the menu build proc for the "AlphaTcl CVS" menu, and lets the
 # AlphaDev menu know that this menu exists by lappending the menu name to
 # the array item
 # 
 #     alphadev::extraSubmenus(1)
 # 
 # Using this method, the AlphaDev menu build proc: alphadev::buildMenu
 # never needs to know in advance what these menus might be, or to be more
 # precise it is not necessary to change this proc if any of the support
 # packages are updated, change their names, or if new packages are added to
 # AlphaTcl.  By registering the build procs in 'preinit' scripts, they are
 # sure to be available by the time the AlphaDev menu is built without
 # adding any significant overhead to Alpha's init sequences.
 # 
 # The "help.tcl" also creates AlphaDev submenus using this method -- this
 # file is always sourced during startup, which is why there is no need to
 # place the code in any package 'preinint' script.
 # 
 # -------------------------------------------------------------------------
 ##

proc alphadev::buildMenu {} {
    
    global alphaDevMenuBindingsmodeVars alphaDeveloperMenu
    
    variable submenus
    variable menuItems
    
    # Create the menu list.
    set divider   "(-)"
    set menuList  [list]
    set subMenus  [list]
    set arrayName "alphaDevMenuBindingsmodeVars"
    # Add submenus that were registered during Alpha's init sequence, and
    # menu items registered in the namespace evaluation above.
    for {set i 1} {[info exists menuItems($i)]} {incr i} {
	foreach subMenu [lsort -unique -dictionary $submenus($i)] {
	    lappend menuList [list Menu -n $subMenu {}]
	    lappend subMenus $subMenu
	}
	set menuList [concat $menuList $menuItems($i)]
	lappend menuList "${divider}[string repeat " " [expr {$i - 1}]]"
    }
    lappend menuList "AlphaDev Menu BindingsÉ"
    # Add key bindings.
    set menuList [alphadev::addMenuBindings $menuList $arrayName]
    # Set the menu proc.
    if {!$alphaDevMenuBindingsmodeVars(activateBindingsInTclModeOnly)} {
	set menuProc {alphadev::menuProc -m}
    } else {
	set menuProc {alphadev::menuProc -m -M Tcl}
    }
    # Return the list of items for the menu.
    return [list build $menuList $menuProc $subMenus $alphaDeveloperMenu]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "alphadev::addMenuBindings" --
 # 
 # Given a list of menu items and an array which potentially contains key
 # bindings, add the user defined bindings as necessary, and return the new
 # list.  Due to limitations/features in AlphaTcl, all of the items within
 # this array can _not_ contain spaces, and so we perform a little regexp
 # manipulation to determine how the bindings are stored in the array.
 # 
 # This is a prototype for in the AlphaTcl system code for menu creation.
 # It currently doesn't take any leading special characters into account,
 # i.e. those for dynamic menus (<E<S) or 'marking' characters (those whose
 # item names begin with !, as in !¥testItem).
 # 
 # -------------------------------------------------------------------------
 ##

proc alphadev::addMenuBindings {menuList arrayName} {
    
    global $arrayName
    
    for {set idx 0} {[lindex $menuList $idx] != ""} {incr idx} {
	set itemName [lindex $menuList $idx]
	regsub -all -- {\s+} $itemName "" bindingItem
	if {[info exists ${arrayName}($bindingItem)]} {
	    set binding [set ${arrayName}($bindingItem)]
	    set menuList [lreplace $menuList $idx $idx ${binding}${itemName}]
	} 
    }
    return $menuList
}

proc alphadev::postBuildMenu {args} {
    
    global alphaDeveloperMenu warningForObsoleteProcedures
    
    markMenuItem $alphaDeveloperMenu "Warning For Obsolete Procs" \
      $warningForObsoleteProcedures Ã
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "alphadev::menuProc" --  menuName itemName
 # 
 # Evaluate a script for all main menu items, redirecting as necessary, and
 # take care of any submenus that registered this as their menu proc.
 # 
 # -------------------------------------------------------------------------
 ##

proc alphadev::menuProc {menuName itemName} {
    
    variable lastChosenOption
    
    # These are all main menu items.
    switch -- $itemName {
	"Prettify Text" {
	    if {![win::checkIfWinToEdit]} {return}
	    eval selectText [text::surroundingWord]
	    if {![isSelection]} {
		status::msg "There is no text to prettify."
		return
	    } 
	    set txt1 [getSelect]
	    set txt2 ""
	    set pat  {([^-a-zA-Z0-9:.]*)([-a-zA-Z0-9:.]+)(.*)}
	    while {[regexp $pat $txt1 allofit ws word theRest]} {
		append txt2 $ws[quote::Prettify $word]
		set txt1 $theRest
	    }
	    append txt2 $txt1
	    replaceAndSelectText [getPos] [selEnd] $txt2
	}
	"Insert Menu Codes" {
	    if {![win::checkIfWinToEdit]} {return}
	    typeText [dialog::getAKey]
	}
	"Insert Binding Codes" {
	    if {![win::checkIfWinToEdit]} {return}
	    if {[isSelection]} {deleteSelection}
	    beep ; keyCode
	}
	"Surround With Bullets" {
	    if {![win::checkIfWinToEdit]} {return}
	    # If there is a selection, it get surrounded, if there is
	    # no selection, but the cursor is touching the end of a
	    # word, it gets surrounded.  Otherwise, we get a template
	    # (could not come up with a "stop beyond")
	    eval selectText [text::surroundingWord]
	    if {[isSelection]} {
		replaceText [getPos] [selEnd] "¥[getSelect]¥"
	    } else {
		insertText "¥¥"
		backwardChar
		elec::Insertion "¥replace-this¥"
	    }
	}
	"Warning For Obsolete Procs" {
	    global warningForObsoleteProcedures
	    set warningForObsoleteProcedures \
	      [expr {1 - $warningForObsoleteProcedures}]
	    prefs::modified warningForObsoleteProcedures
	    postBuildMenu
	    if {$warningForObsoleteProcedures} {
		set which "now"
	    } else {
		set which "never"
	    }
	    status::msg "You will $which be warned when\
	      obsolete procedures are called."
	} 
	"List Procedures" {
	    alphadev::listProcedures
	}
	"List Mode Procs" {
	    alphadev::listModeProcs
	}
	"List Variables" {
	    alphadev::listVariables
	}
	"List Mode Vars" {
	    alphadev::listModeVars
	}
	"List Mode Prefs" {
	    alphadev::listModePrefs
	}
	"Rebuild AlphaTcl Indices" {
	    alphadev::rebuildIndices
	}
	"Rebuild AlphaTcl Filesets" {
	    alphadev::rebuildFilesets
	}
	"Rebuild A Menu" {
	    global menu::build_procs
	    variable lastRebuiltMenus
	    set title "Choose one or more menus to rebuild :"
	    set menus [array names menu::build_procs]
	    set menus [lsort -dictionary $menus]
	    set menuL [list]
	    foreach menuName1 $menus {
		if {![regexp {\s[^\s]} $menuName1]} {
		    set menuName2 [quote::Prettify $menuName1]
		} else {
		    set menuName2 $menuName1
		}
		while {[lsearch $menuL $menuName2] > -1} {
		    append menuName2 " "
		} 
		lappend menuL $menuName2
		set menuConnect($menuName2) $menuName1
	    }
	    if {[llength $lastRebuiltMenus]} {
		set L [list [lindex $lastRebuiltMenus end]]
	    } else {
		set L [lrange $menuL 0 0]
	    }
	    set pickedMenus [listpick -p $title -L $L -l $menuL]
	    foreach menuName $pickedMenus {
		lappend lastRebuiltMenus $menuName
		menu::buildSome $menuConnect($menuName)
	    }
	    status::msg "$pickedMenus menu(s) have been rebuilt."
	}
	"Update 'Alpha Changes'" {
	    alphadev::addToChangesFile "Changes - Alpha"
	}
	"Update 'AlphaTcl Changes'" {
	    alphadev::addToChangesFile "Changes - AlphaTcl"
	}
	"Update 'Alphatk Changes'" {
	    alphadev::addToChangesFile "Changes - Alphatk"
	}
	"AlphaDev Menu Bindings" {
	    # Make sure we only have valid bindings.  (They might
	    # have changed with various updates of this package.)
	    prefs::dialogs::packagePrefs alphaDevMenuBindings
	    menu::buildSome alphaDeveloperMenu
	    status::msg "The 'Alpha Developer Menu' has been rebuilt."
	}
	default {
	    # Wish that we had [quote::Unprettify] ...
	    regsub -all -- {\s+} $itemName "" itemName
	    set firstChar [string tolower [string index $itemName 0]]
	    set itemName  "${firstChar}[string range $itemName 1 end]"
	    namespace eval ::alphadev $itemName
	}
    }
    return
}

# ===========================================================================
# 
# ×××× Contextual Menu module ×××× #
# 

# Includes items to insert menu/binding codes, massage text strings, rebuild
# menus, and rebuild AlphaTcl/Tcl indices.
newPref flag "alphaDevUtilsMenu" "0" contextualMenuTcl
# Provides information about ÇALPHAÈ core commands
newPref flag "coreCommandsMenu"  "1" contextualMenuTcl

menu::buildProc "alphaDevUtils" {alphadev::buildCMUtilsMenu}
menu::buildProc "coreCommands"  {alphadev::buildCMComandsMenu}

proc alphadev::buildCMUtilsMenu {} {
    
    global alpha::CMArgs
    
    variable lastRebuiltMenus
    
    set pos0 [lindex ${alpha::CMArgs} 0]
    lappend menuList "Prettify Text" "Surround With Bullets" \
      "Insert Menu CodesÉ" "Insert Binding CodesÉ" "(-)" \
      "Rebuild AlphaTcl Filesets" "Rebuild AlphaTcl IndicesÉ" \
    lappend menuList "(-)" "Rebuild A MenuÉ"
    foreach menuName [lsort -dictionary -unique $lastRebuiltMenus] {
	lappend menuList "Rebuild '$menuName'"
    }
    return [list build $menuList {alphadev::cmMenuProc -m}]
}

proc alphadev::buildCMComandsMenu {} {
    
    global alphaKeyWords alphaObsCommands alphaObsProcs \
      contextualMenu::cmMenuName
    
    variable cmCommand
    
    set menuList [list]
    regsub -- {^[$:\t ]+} [lindex [contextualMenu::clickWord] 0] {} cmCommand
    # Is it a built-in Alpha command?
    if {([lsearch $alphaKeyWords $cmCommand] > -1)} {
	lappend menuList "\(\"${cmCommand}\" --" \
	  "View Alpha Commands" \
	  "Display Command ArgsÉ" \
	  "Copy Args To Clipboard" 
    } elseif {([lsearch $alphaObsCommands $cmCommand] > -1)} {
	lappend menuList "\(\"${cmCommand}\" --" \
	  "Obsolete CommandÉ"
    } elseif {([lsearch $alphaObsProcs $cmCommand] > -1)} {
	lappend menuList "\(\"${cmCommand}\" --" \
	  "Obsolete ProcedureÉ"
    } else {
	set menuList [list "\(No Alpha command names found"]
	enableMenuItem ${contextualMenu::cmMenuName} "coreCommands" 0
    }
    return [list build $menuList {alphadev::cmMenuProc -m}]
}

proc alphadev::cmMenuProc {menuName itemName} {

    global contextualMenu::lastCMArgs
    
    variable cmCommand
    
    switch -- $menuName {
        "alphaDevUtils" {
	    if {[regexp {Rebuild '([^']+)'} $itemName allofit menuToRebuild]} {
		menu::buildSome $menuToRebuild
		return [status::msg "'$menuToRebuild' has been rebuilt."]
	    }
	    switch -- $itemName {
		"Prettify Text" - 
		"Surround With Bullets" -
		"Insert Menu Codes" - 
		"Insert Binding Codes" {
		    set pp ${contextualMenu::lastCMArgs}
		    selectText [lindex $pp 1] [lindex $pp 2]
		}
	    }
	    return [alphadev::menuProc alphaDevCM $itemName]
        }
        "coreCommands" {
            switch -- $itemName {
		"View Alpha Commands" {
		    Tcl::DblClickHelper $cmCommand
		}
                "Display Command Args" {
		    if {[catch {Tcl::getProcArgs $cmCommand} procArgs]} {
			set procArgs ""
			set msg "Couldn't find the arguments for '$cmCommand'"
		    } elseif {![llength $procArgs]} {
			set procArgs ""
			set msg "'$cmCommand' doesn't take any arguments."
		    } else {
			set msg "'$cmCommand' arguments: "
		    }
		    if {([lindex $procArgs 0] eq "?-w <win>?")} {
		        set procArgs [lreplace $procArgs 0 0 "?-w" "<win>?"]
		    }
		    status::msg "$msg $procArgs"
		    set y "OK"
		    set n "Place in Clipboard"
		    if {![llength $procArgs]} {
			alertnote "${msg}\r\r${procArgs}"
		    } elseif {![dialog::yesno -y $y -n $n $msg $procArgs]} {
			putScrap $procArgs
			status::msg "Copied to Clipboard: $procArgs"
		    }
                }
		"Copy Args To Clipboard" {
		    if {[catch {Tcl::getProcArgs $cmCommand} procArgs]} {
			set msg "Couldn't find the arguments for '$cmCommand'"
		    } elseif {![llength $procArgs]} {
			set msg "'$cmCommand' doesn't take any arguments."
		    } else {
			putScrap $procArgs
			set msg "Copied to Clipboard: $procArgs"
		    }
		    status::msg $msg
		}
		"Obsolete Command" {
		    set msg "\"$cmCommand\" is an obsolete command,\
		      and should never be used."
		    if {![dialog::yesno -y "OK" -n "More Info" $msg]} {
		        help::openGeneral "Alpha Commands" $cmCommand
		    }
		}
		"Obsolete Procedure" {
		    set msg "\"$cmCommand\" is an obsolete procedure,\
		      and should never be used."
		    if {![dialog::yesno -y "OK" -n "More Info" $msg]} {
			set cmd "::$cmCommand"
			if {![catch [list procs::findDefinition $cmd]]} {
			    return
			} else {
			    status::msg "Sorry, no further information\
			      is available."
			}
		    }
		}
	    }
        }
    }
    return
}

# ===========================================================================
# 
# ×××× Menu hooks ×××× #
# 

# Register Open Windows Hook.  Placed here so that its easier to modify
# without having to rebuild indices.

proc alphadev::OWH {{which "register"}} {
    
    global global::features alphaDeveloperMenu
    
    if {![lcontains global::features alphaDeveloperMenu]} {
	return
    }
    # Items requiring an open window.
    set owhItems [list "Prettify Text" "Insert Menu CodesÉ" \
      "Insert Binding CodesÉ" "Surround With Bullets"]
    
    foreach item $owhItems {
	hook::${which} requireOpenWindowsHook [list $alphaDeveloperMenu $item] 1
    }
    return
}

proc alphadev::activateHook {name} {
    return
}

# ===========================================================================
# 
# ×××× AlphaDev Menu support ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::listProcedures" --
 # 
 # List the names and arguments of all procedures in the chosen namespace(s),
 # placing the information in a new window.  The names of all namespaces that
 # don't have procedures are listed at the end.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::listProcedures {} {
    
    global alpha::macos
    
    set namespaces [alphadev::chooseNamespaces]
    watchCursor
    set header1 {
# Currently Defined Procedures for given namespaces
# 
# COMMAND-Double-Click on any procedure name to see its definition.
# 
# Namespaces include:
# 
}
    set header2 {
# These namespaces do not have any defined procedures:
}
    if {${alpha::macos}} {
	regsub -- {COMMAND} $header1 {Command} header1
    } else {
	regsub -- {COMMAND} $header1 {Alt} header1
    }
    set txt1 ""
    set txt2 ""
    foreach ns [lsort -dictionary $namespaces] {
	if {($ns eq "::")} {
	    set procedures [info procs "::*"]
	} else {
	    set procedures [info procs ${ns}::*]
	}
	if {![llength $procedures]} {
	    append txt2 $ns "\r"
	    continue
	} 
	append header1 "\# " $ns "\r"
	append txt1 "\# Namespace --  " $ns " \r\r" \
	  [format {%-40s} "\# Procedure Name"] \
	  ": Procedure Arguments" "\r\r"
	foreach p [lsort -dictionary $procedures] {
	    set args ""
	    foreach arg [info args $p] {
		if {[info default $p $arg value]} {
		    lappend args [list [list $arg $value]]
		} else {
		    lappend args [list $arg]
		}
	    }
	    append txt1 [format {%-40s} "$p "] ": " [join $args " "] "\r"
	}
	append txt1 "\r"
    }
    if {![string length $txt1]} {
	if {([llength $namespaces] == 1)} {
	    alertnote "The namespace \"[join $namespaces]\"\
	      does not have any defined procedures."
	} else {
	    alertnote "The namespaces \"[join $namespaces]\"\
	      do not have any defined procedures."
	}
	return
    } 
    append txt $header1 "\r" $txt1 "\r" 
    if {[string length $txt2]} {
	append txt $header2 "\r" $txt2 "\r"
    }
    set w [new -n {* Current Procedures *} -m Tcl -info $txt]
    foreach ns $namespaces {
	set pattern "\# Namespace --  $ns "
	set pos0 [minPos]
	if {[llength [set pp [search -w $w -n -r 0 -f 1 -- $pattern $pos0]]]} {
	    set pos1 [lindex $pp 0]
	    setNamedMark -w $w $ns $pos1 $pos1 $pos1
	} 
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::listModeProcs" --
 # 
 # List the names and arguments for a given procedure in all defined modes,
 # placing the information in a new window.  The names of all modes that
 # don't have procedures are listed at the end.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::listModeProcs {} {
    
    global alpha::macos
    
    variable modeProcOptions
    variable lastModeProc
    
    if {![info exists modeProcOptions]} {
        set modeProcOptions [list "MarkFile" "parseFuncs" "DblClick" \
	  "correctIndentation" "indentLine" "indentRegion" \
	  "CommentLine" "UncommentLine" "searchFunc" "foldableRegion" \
	  "OptionTitlebar" "OptionTitlebarSelect" "carriageReturn" \
	  "electricLeft" "electricRight" "electricSemi" "getLimits" \
	  ]
    }
    set modeProcOptions [lsort -dictionary -unique $modeProcOptions]
    if {![info exists lastModeProc]} {
        set lastModeProc [lindex $modeProcOptions 0]
    }
    set buttonScript {
	status::msg "The 'proc' name can include (or end) with \"*\" É"
	if {![catch {prompt {New Mode Proc:} ""} newProc]} {
	    lappend ::alphadev::modeProcOptions $newProc
	    set alphadev::modeProcOptions \
	      [lsort -dictionary -unique $::alphadev::modeProcOptions]
	    set retCode 1 ; set retVal $newProc
	}
	status::msg ""
    }
    set dialogScript [list dialog::make -title "Mode Procedures" \
      -addbuttons [list \
      "Add ProcÉ" \
      "Click here to add a different procedure." \
      $buttonScript] \
      [list "" \
      [list "text" "Choose the name of a procedure from the pop-up menu below.\
      After pressing the \"OK\" button each <mode>::<procName> will be sourced,\
      and a new window will display the required/optional arguments and\
      default values associated with each one.\r"] \
      [list [list "menu" $modeProcOptions] \
      "Mode Procedure:" $lastModeProc] \
      [list "text" "\rIf you press the \"Add Proc\" button you can list the\
      mode arguments/default values for any given procedure or proc* name."]]]
    
    if {![catch $dialogScript result]} {
	set modeProc [lindex $result 0]
    } elseif {($result ne "cancel")} {
	set modeProc $result
	alertnote "The proc \"${modeProc}\" will be saved for the duration\
	  of this editing session."
    } else {
	error $result
    }
    set lastModeProc $modeProc
    watchCursor
    set header1 {# -*-Tcl-*-
# 
# Mode Procedures for "MODEPROC"
# 
# COMMAND-Double-Click on any procedure name to see its definition.
# 
# "MODEPROC" is defined in these [alpha::mode] or [addMode] modes :
# 
# (There might be additional "minor-mode" procs not listed here.)
# 
}
    set header2 {
# These modes do not have any procedure defined for "MODEPROC" :
}
    if {${alpha::macos}} {
	regsub -all -- {COMMAND} $header1 {Command} header1
    } else {
	regsub -all -- {COMMAND} $header1 {Alt} header1
    }
    regsub -all -- {MODEPROC} $header1 $modeProc header1
    regsub -all -- {MODEPROC} $header2 $modeProc header2
    set len1 [expr {[string length $modeProc] + 10}]
    
    append txt1 [format "%-40s" "Procedure Name:"] \
      "Procedure Arguments:" \r \
      [format "%-40s" [string repeat "_" 15]] [string repeat "_" 20] \r\r
    
    foreach ns [mode::listAll] {
	set procName ::${ns}::${modeProc}
	if {![llength [set procedures [info procs $procName]]]} {
	    auto_load $procName
	    if {![llength [set procedures [info procs $procName]]]} {
		lappend notFound $ns
		continue
	    }
	}
	lappend found $ns
	foreach procedure $procedures {
	    set args ""
	    append txt1 [format "%-40s" "$procedure"] 
	    foreach arg [info args $procedure] {
		if {[info default $procedure $arg value]} {
		    lappend args [list [list $arg $value]]
		} else {
		    lappend args [list $arg]
		}
	    }
	    append txt1 [join $args " "] "\r"
	}
    }
    if {![info exists found]} {
	alertnote "The procedure \"${modeProc}\"\
	  is not defined for any modes."
	return
    } 
    append txt $header1 "\r" $txt1
    if {[info exists notFound]} {
	append txt $header2 "\r" [join $notFound "\r"] "\r"
    }
    set w [new -n {* Mode Procedures *} -m Tcl -info $txt]
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::listVariables" --
 # 
 # List the values of all variables in the chosen namespace(s), placing the
 # information in a new window.  The names of all arrays for the given
 # namespaces are listed at the end.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::listVariables {} {
    
    global alpha::macos
    
    set namespaces [alphadev::chooseNamespaces]
    watchCursor
    set header1 {
# Currently Defined Variables for given namespaces
# 
# This does not include array variables, but their names are listed at the end.
# 
# Namespaces include:
# 
}
    set header2 {
# These are the names of the current namespace arrays, for their values
# you can COMMAND-Double-Click on them.
}
    if {${alpha::macos}} {
	regsub -- {COMMAND} $header2 {Command} header2
    } else {
	regsub -- {COMMAND} $header2 {Alt} header2
    }
    set txt1 ""
    set arrays [list]
    foreach ns [lsort -dictionary $namespaces] {
	append header1 "\# " $ns "\r"
	if {($ns eq "::")} {
	    set variables [info vars "::*"]
	} else {
	    set variables [info vars ${ns}::*]
	}
	if {![llength $variables]} {
	    continue
	} 
	set varTxt ""
	foreach var [lsort -dictionary $variables] {
	    if {[array exists $var]} {
		lappend arrays $var
		continue
	    } elseif {![info exists $var]} {
	        continue
	    } else {
	        append varTxt [format {%-40s} "$var "] ": " [set $var] "\r"
	    }
	}
	if {[string length $varTxt]} {
	    append txt1 "\# Namespace --  " $ns " \r\r" $varTxt "\r"
	} 
    }
    if {![string length $txt1]} {
	if {([llength $namespaces] == 1)} {
	    alertnote "The namespace \"[join $namespaces]\"\
	      does not have any defined variables."
	} else {
	    alertnote "The namespaces \"[join $namespaces]\"\
	      do not have any defined variables."
	}
	return
    } 
    if {[llength $arrays]} {
	set txt2 [join [lsort -dictionary $arrays] "\r"]
    } else {
        set txt2 "(There are no arrays in the given namespaces.)"
    }
    append txt $header1 "\r" $txt1 $header2 "\r" $txt2 "\r"
    set w [new -n {* Variable Values *} -m Tcl -info $txt]
    foreach ns $namespaces {
	set pattern "\# Namespace --  $ns "
	set pos0 [minPos]
	if {[llength [set pp [search -w $w -n -r 0 -f 1 -- $pattern $pos0]]]} {
	    set pos1 [lindex $pp 0]
	    setNamedMark -w $w $ns $pos1 $pos1 $pos1
	} 
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::listModeVars" --
 # 
 # List the values of variables for each mode's namespace, placing the
 # information in a new window.  The names of all modes that have not defined
 # the variables are listed at the end.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::listModeVars {} {
    
    global alpha::macos
    
    variable modeVarOptions
    variable lastModeVar
    
    if {![info exists modeVarOptions]} {
	set modeVarOptions [list "commentCharacters" "commentRegexp" \
	  "endPara" "escapeChar" "lineContinuationChar" "quotedstringChar" \
	  "startPara" \
	  ]
    }
    set modeVarOptions [lsort -dictionary -unique $modeVarOptions]
    if {![info exists lastModeVar]} {
	set lastModeVar [lindex $modeVarOptions 0]
    }
    set buttonScript {
	status::msg "The 'var' name can include (or end) with \"*\" É"
	if {![catch {prompt {New Mode Variable:} ""} newVar]} {
	    lappend ::alphadev::modeVarOptions $newVar
	    set alphadev::modeVarOptions \
	      [lsort -dictionary -unique $::alphadev::modeVarOptions]
	    set retCode 1 ; set retVal $newVar
	}
	status::msg ""
    }
    set dialogScript [list dialog::make -title "Mode Variables" \
      -addbuttons [list \
      "Add VarÉ" \
      "Click here to add a different variable." \
      $buttonScript] \
      [list "" \
      [list "text" "Choose the name of a variable from the pop-up menu below.\
      After pressing the \"OK\" button each mode will be \"loaded\",\
      and a new window will display the current values\
      associated with each one defined as \"<mode>::<varName>\".\r"] \
      [list [list "menu" $modeVarOptions] \
      "Mode Variable:" $lastModeVar] \
      [list "text" "\rIf you press the \"Add Var\" button you can list the\
      mode arguments/default values for any given variable or var* name."]]]
    
    if {![catch $dialogScript result]} {
	set modeVar [lindex $result 0]
    } elseif {($result ne "cancel")} {
	set modeVar $result
	alertnote "The variable \"${modeVar}\" will be saved for the duration\
	  of this editing session."
    } else {
	error $result
    }
    set lastModeVar $modeVar
    watchCursor
    set header1 {# -*-Tcl-*-
# 
# Mode Variables for "MODEVAR"
# 
# "MODEVAR" is defined in these [alpha::mode] or [addMode] modes :
# 
# (There might be additional "minor-mode" variables not listed here.)
# 
}
    set header2 {
# These modes do not have any variables defined for "MODEVAR" :
}
    if {${alpha::macos}} {
	regsub -all -- {COMMAND} $header1 {Command} header1
    } else {
	regsub -all -- {COMMAND} $header1 {Alt} header1
    }
    regsub -all -- {MODEVAR} $header1 $modeVar header1
    regsub -all -- {MODEVAR} $header2 $modeVar header2
    set len1 [expr {[string length $modeVar] + 10}]
    
    append txt1 [format "%-40s" "Variable Name:"] \
      "Current Variable Value:" \r \
      [format "%-40s" [string repeat "_" 35]] [string repeat "_" 30] \r\r
    set arrays [list]
    foreach modeName [mode::listAll] {
	loadAMode $modeName
	set variables [info vars ::${modeName}::${modeVar}*]
	if {![llength $variables]} {
	    lappend notFound $modeName
	    continue
	}
	lappend found $modeName
	foreach var [lsort -dictionary $variables] {
	    if {[array exists $var]} {
		lappend arrays $var
		append txt1 $var \r\r
		foreach arrayName [lsort -dictionary [array names $var]] {
		    append txt1 [format {%-40s} "    $arrayName "] \
		      ": " [set ${var}($arrayName)] "\r"
		}
		append txt1 "\r"
	    } elseif {![info exists $var]} {
		continue
	    } else {
		append txt1 [format {%-40s} "$var "] ": " [set $var] "\r"
	    }
	}
    }
    if {![info exists found]} {
	alertnote "The variable \"${modeVar}\"\
	  is not defined for any modes."
	return
    } 
    append txt $header1 "\r" $txt1
    if {[info exists notFound]} {
	append txt $header2 "\r" [join $notFound "\r"] "\r"
    }
    set w [new -n {* Mode Variables *} -m Tcl -info $txt]
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::listModePrefs" --
 # 
 # List the values of variables for each <mode>modeVars array, placing the
 # information in a new window.  The names of all modes that have not defined
 # the variables are listed at the end.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::listModePrefs {} {
    
    global alpha::macos
    
    variable modePrefOptions
    variable lastModePref
    
    if {![info exists modePrefOptions]} {
	set modePrefOptions [list "autoMark" "fillColumn" "leftFillColumn" \
	  "commentsContinuation" "prefixString" "suffixString" \
	  "indentOnReturn" "electricBraces" "electricSemicolon" \
	  "indentationAmount" "lineWrap" "wordBreak" "funcExpr" "parseExpr" \
	  "windowGeometry" "defaultFont" "fontSize" \
	  "*Color" "*Sig" \
	  ]
    }
    set modePrefOptions [lsort -dictionary -unique $modePrefOptions]
    if {![info exists lastModePref]} {
	set lastModePref [lindex $modePrefOptions 0]
    }
    set buttonScript {
	status::msg "The 'var' name can include (or end) with \"*\" É"
	if {![catch {prompt {New Mode Preference:} ""} newVar]} {
	    lappend ::alphadev::modePrefOptions $newVar
	    set alphadev::modePrefOptions \
	      [lsort -dictionary -unique $::alphadev::modePrefOptions]
	    set retCode 1 ; set retVal $newVar
	}
	status::msg ""
    }
    set dialogScript [list dialog::make -title "Mode Preferences" \
      -addbuttons [list \
      "Add VarÉ" \
      "Click here to add a different preference." \
      $buttonScript] \
      [list "" \
      [list "text" "Choose the name of a preference from the pop-up menu below.\
      After pressing the \"OK\" button each mode will be \"loaded\",\
      and a new window will display the current values\
      associated with each one in a \"<mode>modeVars\" array.\r"] \
      [list [list "menu" $modePrefOptions] \
      "Mode Preference:" $lastModePref] \
      [list "text" "\rIf you press the \"Add Var\" button you can list the\
      mode arguments/default values for any given preference or pref* name."]]]
    
    if {![catch $dialogScript result]} {
	set modePref [lindex $result 0]
    } elseif {($result ne "cancel")} {
	set modePref $result
	alertnote "The preference \"${modePref}\" will be saved for the duration\
	  of this editing session."
    } else {
	error $result
    }
    set lastModePref $modePref
    watchCursor
    set header1 {# -*-Tcl-*-
# 
# Mode Preferences for "MODEPREF"
# 
# "MODEPREF" is defined in these [alpha::mode] or [addMode] modes :
# 
# (There might be additional "minor-mode" preferences not listed here.)
# 
}
    set header2 {
# These modes do not have any preferences defined for "MODEPREF" :
}
    if {${alpha::macos}} {
	regsub -all -- {COMMAND} $header1 {Command} header1
    } else {
	regsub -all -- {COMMAND} $header1 {Alt} header1
    }
    regsub -all -- {MODEPREF} $header1 $modePref header1
    regsub -all -- {MODEPREF} $header2 $modePref header2
    set len1 [expr {[string length $modePref] + 10}]
    
    append txt1 [format "%-40s" "Preference Name:"] \
      "Current Preference Value:" \r \
      [format "%-40s" [string repeat "_" 35]] [string repeat "_" 30] \r\r
    
    foreach modeName [mode::listAll] {
	loadAMode $modeName
	global ${modeName}modeVars
	set varNames [array get ${modeName}modeVars $modePref]
	if {![llength $varNames]} {
	    lappend notFound $modeName
	    continue
	}
	lappend found $modeName
	foreach {varName varValue} $varNames {
	    set varName "${modeName}modeVars(${varName})"
	    append txt1 [format "%-40s" $varName] $varValue "\r"
	}
    }
    if {![info exists found]} {
	alertnote "The preference \"${modePref}\"\
	  is not defined for any modes."
	return
    } 
    append txt $header1 "\r" $txt1
    if {[info exists notFound]} {
	append txt $header2 "\r" [join $notFound "\r"] "\r"
    }
    set w [new -n {* Mode Preferences *} -m Tcl -info $txt]
    return
}
 
## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::chooseNamespaces" --
 # 
 # Offer a series of list-pick dialogs allowing the user to select one or
 # more currently defined namespaces.  If "(select all)" is chosen, then we
 # return a list containing all of items in the dialog _plus_ any children of
 # those namespaces.  If the name of the current namespace (relative to the
 # dialog, not the interpreter) is selected, then we don't ignore the kids.
 # Selecting "(up one level)" will offer a new dialog.
 # 
 # This is not necessarily specific to AlphaTcl development, if there was any
 # need for it more generally we could move it into "procUtils.tcl".
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::chooseNamespaces {} {
    
    set results    [list]
    set selectAll  "(select all)"
    set upOneLevel "(up one level)"
    set ns "::"
    while {1} {
	if {![llength [set children [namespace children $ns]]]} {
	    set results [list $ns]
	    break
	}
	set p "Choose an option in \"$ns\""
	set options [list  $ns $selectAll]
	if {($ns ne "::")} {
	    lappend options $upOneLevel
	}
	set nsLength "2"
	if {$ns ne "::"} {
	    incr nsLength [string length $ns]
	}
	foreach child [lsort -dictionary $children] {
	    lappend options [string range $child $nsLength end]
	}
        set chosenChildren [listpick -p $p -l $options]
	if {([lsearch $chosenChildren $selectAll] > -1)} {
	    set results [concat [list $ns] $children]
	    break
	} elseif {([lsearch $chosenChildren $upOneLevel] > -1)} {
	    set ns [namespace parent $ns]
	    continue
	} elseif {([lindex $chosenChildren 0] eq "::")} {
	    set results [list "::"]
	    break
	}
	if {([llength $chosenChildren] == 1)} {
	    if {([lindex $chosenChildren 0] eq $ns)} {
	        return [list $ns]
	    } elseif {($ns eq "::")} {
	        append ns [lindex $chosenChildren 0]
	    } else {
		append ns "::" [lindex $chosenChildren 0]
	    }
	    continue
	}
	# Still here? Multiple children chosen, so return the results.
	foreach child $chosenChildren {
	    if {($ns eq "::")} {
		lappend results "::${child}"
	    } else {
		lappend results "${ns}::${child}"
	    }
	}
	break
    }
    if {($results ne [list "::"])} {
        foreach ns $results {
	    eval lappend results [alphadev::listNamespaceChildren $ns]
	}
    } 
    return [lsort -dictionary -unique $results]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::listNamespaceChildren" --
 # 
 # Similar to [procs::buildList], return the names of all children for the
 # given namespace.
 # 
 # This is not necessarily specific to AlphaTcl development, if there was any
 # need for it more generally we could move it into "procUtils.tcl".
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::listNamespaceChildren {{ns "::"}} {
    
    set children [namespace children $ns]
    foreach child $children {
	eval lappend children [alphadev::listNamespaceChildren "${child}::"]
    }
    return [lsort -dictionary -unique $children]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::rebuildIndices" --
 # 
 # Called by the "AlphaDev > Rebuild Indices" command.  Unlike the menu item
 # "Config > Packages > Rebuild Package Indices", we give the user the choice
 # of what indices to rebuild.  For Tcl indices, we also offer the option to
 # review any possible errors encountered when rebuilding.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::rebuildIndices {} {
    
    global alpha::application
    
    variable lastChosenOption
    
    if {[info exists lastChosenOption(rebuildIndices)]} {
	set defaults $lastChosenOption(rebuildIndices)
    } else {
	set defaults [list 1 1 0]
    }
    set txt1 "ALPHA stores all of its AlphaTcl \"Package\" information in\
      a set of Cache files to make the startup sequence more efficient.\
      When you update your AlphaTcl library, these Cache files and all\
      Tcl indices must be rebuilt.\r"
    set txt2 "After rebuilding the indices, you must immediately quit ALPHA\
      and then restart the program.\r"
    set txt3 "Some directories might cause an error to be thrown when\
      Tcl indices are rebuilt.  You can view these errors, or ignore them.\r"
    regsub -all -- {ALPHA} $txt1 ${alpha::application} txt1
    regsub -all -- {ALPHA} $txt2 ${alpha::application} txt2
    set flag0 "Rebuild AlphaTcl Indices"
    set flag1 "Rebuild Tcl Indices"
    set flag2 "Display rebuilding error alerts"
    # Present the dialog to the user.
    set results [dialog::make \
      -title "Rebuild AlphaTcl Package Indices?" \
      -width 450 \
      [list "" \
      [list "text" $txt1] \
      [list "text" $txt2] \
      [list "flag" $flag0 [lindex $defaults 0]] \
      [list "flag" $flag1 [lindex $defaults 1]] \
      [list "text" $txt3] \
      [list "flag" $flag2 [lindex $defaults 2]] \
      ]]
    set lastChosenOption(rebuildIndices) $results
    # Rebuild indices as required.
    if {[lindex $results 0]} {
	alpha::rebuildPackageIndices
    }
    if {[lindex $results 1]} {
	set errors [rebuildTclIndices]
    }
    if {[lindex $results 2] && [info exists errors]} {
	set s [expr {([llength $errors] > 1) ? "s" : ""}]
	set q "View the [llength $errors] rebuilding error${s}?"
	if {[llength $errors] && [askyesno $q]} {
	    set placeOrAppend 0
	    set title "Tcl Index Rebuilding Error"
	    for {set i 0} {($i < [llength $errors])} {incr i} {
		if {($i < ([llength $errors] - 1))} {
		    set y "Next"
		} else {
		    set y "Done"
		}
		if {!$placeOrAppend} {
		    set n "Place In Clipboard"
		} else {
		    set n "Append To Clipboard"
		}
		set dialogScript [list dialog::yesno \
		  -title "$title [expr {$i + 1}] of [llength $errors]" \
		  -width 500 \
		  -y $y -n $n -c [join [lindex $errors $i] "\r\r"]]
		if {[catch {eval $dialogScript} result]} {
		    break
		} elseif {$result} {
		    continue
		} elseif {!$placeOrAppend} {
		    putScrap $errorMsg
		    set placeOrAppend 1
		} else {
		    putScrap [getScrap] \r\r $errorMsg
		}
	    }
	} 
    }
    if {([lindex $results 0] + [lindex $results 1] == 0)} {
	status::msg "Nothing in your AlphaTcl indices changed."
    } elseif {[askyesno "Do you want to quit ${alpha::application}?"]} {
	quit
    } else {
	status::msg "You have been forewarned ..."
    }
    return
}

proc alphadev::rebuildFilesets {} {
    
    global HOME ALPHATK alpha::platform
    
    status::msg [set msg "Creating AlphaTcl filesetsÉ"]
    set filesets [list "AlphaTclCore" "Completions" "Menus" "Modes" "Packages"]
    if {${alpha::platform} == "tk"} {
        lappend filesets "AlphatkCore"
    } 
    set modifiedFilesets [list]
    # Filesets for AlphaTclCore, Menus, etc.
    foreach filesetName $filesets {
	set dir [file join $HOME Tcl $filesetName]
	set pattern "*.tcl"
	set depth 3
	# Deal with special cases that deviate from these default values.
	switch -- $filesetName {
	    "AlphaTclCore" {
	        set dir [file join $HOME Tcl SystemCode]
		set depth 2
	    }
	    "AlphatkCore" {
		set dir $ALPHATK
		set pattern ""
		set depth 2
	    }
	    "Menus" {
		set pattern "*.{tcl,flt}"
	    }
	    "Package" {
		set depth 2
	    }
	}
	if {![file isdir $dir]} {
	    alertnote "The '[file tail ${dir}]' folder is missing!"
	    continue
	} 
	fileset::fromHierarchy::create $filesetName $dir $pattern $depth
	lappend modifiedFilesets $filesetName
    }
    # Create a recursive 'AlphaTcl' fileset for searching.
    fileset::recurseIn::create AlphaTcl [file join $HOME Tcl]
    lappend modifiedFilesets "AlphaTcl"
    # This is necessary to (re)build the filesets we just created.
    rebuildAllFilesets
    # Register these to be saved.
    foreach filesetName $modifiedFilesets {
	modifyFileset $filesetName
    }
    status::msg "$msg complete."
    return
}

proc alphadev::addToChangesFile {{which "Changes - Alpha"}} {

    if {![file exists [set f [file join ${::HOME} Help $which]]]} {
	alertnote "Couldn't find the file '${which}' !!"
	return
    }
    file::openQuietly $f
    set w [win::Current]
    set pp0 [search -w $w -n -s -f 1 -r 1 -m 0 "^¥ \[\n\r\]" [minPos]]
    if {[llength $pp0]} {
	set pos [lindex $pp0 0]
    } else {
	set pos [lindex [search -w $w -n -s -f 1 -r 1 -m 0 "^¥ " [minPos]] 0]
	while {1} {
	    if {![string length $pos]} {return}
	    set pos [pos::nextLineStart -w $w $pos]
	    set txt [string trim [getText -w $w $pos [pos::lineEnd -w $w $pos]]]
	    if {[lookAt -w $w $pos] == "=" || $txt == ""} {break}
	}
    }
    goto -w $w $pos
    setWinInfo -w $w read-only 0
    if {[win::getInfo $w read-only]} {
	# Try the vcs "Make Writable" menu item.
	catch {vcs::menuProc "" "makeWritable"}
    }
    if {[win::getInfo $w read-only]} {
	alertnote "Window is still read-only"
    } else {
	insertText -w $w "¥ \r"
	backwardChar -w $w
    }
    return
}

#===============================================================================
#
# ×××× -------- ×××× #
# 
# ×××× Tcl, Inst Mode Support ×××× #
# 

##
 # --------------------------------------------------------------------------
 # 
 # "alphadev::getProcArgs" --
 # 
 # Returns the arguments (including possible default values) of the queried
 # 'procName' as a list.  If the proc is not recognized by the interpreter,
 # this will return an empty list.
 # 
 # We have special case handling for [pos::...]  and any other core commands
 # or AlphaTcl SystemCode procedures which have a syntax that won't be given
 # by [info args ...]  or [info default ...].
 #
 # We have special case handling of procs which make use of [win::parseArgs]
 # to provide ?-w win?  handling.  In these cases, the first argument in the
 # returned list will be "?-w <win>?".
 # 
 # It is safe to call this directly -- when we rename [Tcl::getProcArgs] the
 # main [Tcl::listProcArgs] is still available.
 # 
 # --------------------------------------------------------------------------
 ##

proc alphadev::getProcArgs {procName} {
    
    global alphaObsCommands alphaObsProcs Tcl::interpCmd

    set procName [string trimleft $procName ":"]
    # Special handling of obsolete procs/commands.
    if {([lsearch $alphaObsCommands $procName] > -1)} {
        return [list "(\"${procName}\" is an obsolete procedure.)"]
    } elseif {([lsearch $alphaObsCommands $procName] > -1)} {
	return [list "(\"${procName}\" is an obsolete command.)"]
    }
    set ProcName "::$procName"
    # Special handling of [pos::...] and other commands which take ?-w <win>?
    # in addition (possibly) to other arguments.
    switch -- $ProcName {
	"::pos::lineStart" -
	"::pos::prevLineStart" -
	"::pos::prevLineEnd" -
	"::pos::prevChar" -
	"::pos::prevLine"       {set procArgs [list {?pos "[getPos]"?}]}
	
	"::pos::nextLineStart" -
	"::pos::lineEnd" -
	"::pos::nextLineEnd" -
	"::pos::nextChar" -
	"::pos::nextLine"       {set procArgs [list {?pos "[selEnd]"?}]}
	
	"::pos::math"           {set procArgs [list {args}]}
	
	"::pos::compare" -
	"::pos::diff"           {set procArgs [list {pos1} {pos2}]}
	
	"::deleteText" -
	"::getText" -
	"::selectText"          {set procArgs [list {pos1} {pos2}]}
	
	"::display" -
	"::goto" -
	"::lineStart" -
	"::lookAt" -
	"::nextLineStart"       {set procArgs [list {pos}]}
	
	"::setPin"              {set procArgs [list {?pos?}]}
	
	"::gotoMark" -
	"::gotoTMark" -
	"::removeTMark"         {set procArgs [list {name}]}
	
	"::createTMark"         {set procArgs [list {name} {pos}]}
	"::getNamedMarks"       {set procArgs [list {?-n?}]}
	"::getWinInfo"          {set procArgs [list {arr}]}
	"::insertText"          {set procArgs [list {text*}]}
	"::matchIt"             {set procArgs [list {brace-char} {pos} {?limit?}]}
	"::moveInsertionHere"   {set procArgs [list {?-last?}]}
	"::removeNamedMark"     {set procArgs [list {?-n name?}]}
	"::replaceText"         {set procArgs [list {pos1} {pos2} {?text?+}]}
	"::search"              {set procArgs [list {?options ...?} {pattern} {pos}]}
	"::setNamedMark"        {set procArgs [list {?name disp pos end?}]}
	"::setWinInfo"          {set procArgs [list {field} {arg}]}
	"::toggleSplitWindow"   {set procArgs [list {?percent?}]}
	
	"::backSpace" -
	"::backwardChar" -
	"::backwardCharSelect" -
	"::backwardDeleteWord" -
	"::backwardWord" -
	"::backwardWordSelect" -
	"::balance" -
	"::beginningBufferSelect" -
	"::beginningLineSelect" -
	"::beginningOfBuffer" -
	"::beginningOfLine" -
	"::capitalizeRegion" -
	"::capitalizeWord" -
	"::clear" -
	"::copy" -
	"::cut" -
	"::deleteChar" -
	"::deleteSelection" -
	"::deleteWord" -
	"::downcaseWord" -
	"::endBufferSelect" -
	"::endLineSelect" -
	"::endOfBuffer" -
	"::endOfLine" -
	"::exchangePointAndPin" -
	"::forwardChar" -
	"::forwardCharSelect" -
	"::forwardWord" -
	"::forwardWordSelect" -
	"::getPin" -
	"::getPos" -
	"::getPos" -
	"::getSelect" -
	"::hiliteToPin" -
	"::insertToTop" -
	"::killLine" -
	"::killWindow" -
	"::lineStart" -
	"::maxPos" -
	"::maxPos" -
	"::minPos" -
	"::nextLine" -
	"::nextLineSelect" -
	"::nextLineStart" -
	"::oneSpace" -
	"::openLine" -
	"::pageBack" -
	"::pageForward" -
	"::paste" -
	"::prevLineSelect" -
	"::previousLine" -
	"::rectangularHiliteToPin" -
	"::revert" -
	"::scrollDownLine" -
	"::scrollLeftCol" -
	"::scrollRightCol" -
	"::scrollUpLine" -
	"::selEnd" -
	"::tab" -
	"::toggleSplitWindow" -
	"::upcaseWord" -
	"::yank" -
	"::zapNonPrintables" {set procArgs [list]}
    }
    if {[info exists procArgs]} {
	return [linsert $procArgs 0 {?-w <win>?}]
    }
    # More special cases for Alpha core commands.
    switch -- $ProcName {
	"::addAlphaChars" {
	    set procArgs [list {chars}]
	}
	"::addHelpMenu" {
	    set procArgs [list {item}]
	}
	"::addMenuItem" {
	    set procArgs [list {?-m?} {?-l meta-characters?} \
	      {menu-name} {item-name}]
	}
	"::alert" {
	    set procArgs [list {?-t stop|caution|note|plain?} \
	      {?-k okText?} {?-c cancelText?} {?-o otherText?} \
	      {?-h?} {?-K ok|cancel|other|help?} \
	      {?-C ok|cancel|other|help|none?} {error_string} \
	      {?explanation_string?}]
	}
	"::alertnote" {
	    set procArgs [list {message}]
	}
	"::ascii" {
	    set procArgs [list {ascii-char} {<?modifier?>} {script} {?mode?}]
	}
	"::askyesno" {
	    set procArgs [list {?-c?} {prompt}]
	}
	"::beep" {
	    set procArgs [list {?-volume num?} {?-list|sndName?}]
	}
	"::Bind" {
	    set procArgs [list {'char'} {<?modifier?>} {script} {?mode?}]
	}
	"::blink" {
	    set procArgs [list {pos}]
	}
	"::breakIntoLines" {
	    set procArgs [list {string}]
	}
	"::bringToFront" {
	    set procArgs [list {winName}]
	}
	"::buttonAlert" {
	    set procArgs [list {prompt} {button} {?button? ...}]
	}
	"::colorTriple" {
	    set procArgs [list {?prompt?} {?red green blue?}]
	}
	"::deleteMenuItem" {
	    set procArgs [list {?-m?} {menu-name} {item-name}]
	}
	"::deleteModeBindings" {
	    set procArgs [list {mode}]
	}
	"::dialog" {
	    set procArgs [list {?-w width?} {?-h height?} \
	      {?-b title l t r b?} {?-c title val l t r b?} \
	      {?-t text l t r b?} {?-e text l t r b?} \
	      {?-r text val l t r b?} {?-p l t r b?}]
	}
	"::displayMode" {
	    set procArgs [list {mode}]
	}
	"::echo" {
	    set procArgs [list {string}]
	}
	"::edit" {
	    set procArgs [list {?-r?} {?-c?} {?-w?} {?-mode val?} \
	      {?-encoding val?} {?-tabsize val?}  {?-g l t w h?} {?--?} {name}]
	}
	"::enableMenuItem" {
	    set procArgs [list {?-m?} {menuName} {item-text} {on|off}]
	}
	"::findFile" {
	    set procArgs [list {?path?}]
	}
	"::float" {
	    set procArgs [list {-m menu} {?<-h|-w|-l|-t|-M> val?} \
	      {?-n winname?} {?-z tag?}]
	}
	"::floatShowHide" {
	    set procArgs [list {on|off} {tag}]
	}
	"::getGeometry" {
	    set procArgs [list {?win?}]
	}
	"::get_directory" {
	    set procArgs [list {?-p prompt?} {?default?}]
	}
	"::getfile" {
	    set procArgs [list {?prompt?} {?path?}]
	}
	"::getline" {
	    set procArgs [list {prompt} {default}]
	}
	"::icGetPref" {
	    set procArgs [list {?<-t type?} {pref-name}]
	}
	"::icon" {
	    set procArgs [list {?-f winName?} {?-c|-o|-t|-q?} {?-g h v?}]
	}
	"::insertMenu" {
	    set procArgs [list {name}]
	}
	"::launch" {
	    set procArgs [list {-f name}]
	}
	"::listpick" {
	    set procArgs [list {?-p prompt?} {?-l?} {?-L def-list?} {list}]
	}
	"::markMenuItem" {
	    set procArgs [list {?-m?} {menuName} {item-text} {on|off} \
	      {?mark-char?}]
	}
	"::Menu" {
	    set procArgs [list {?-i <num?} {?-m?} {?-M mode?} \
	      {?-n <name|num>?} {?-p procname?} {?-s?} {list}]
	}
	"::moveWin" {
	    set procArgs [list {?window?} {left} {top}]
	}
	"::nameFromAppl" {
	    set procArgs [list {'app-sig'}]
	}
	"::new" {
	    set procArgs [list {?-g l t w h?} {?-tabsize val?} {?-mode val?} \
	      {?-dirty val?} {?-shell val?} {?-info val?} {?-n name?}]
	}
	"::prompt" {
	    set procArgs [list {prompt} {default} {?name? ?menu-item?}]
	}
	"::putScrap" {
	    set procArgs [list {string} {?string string...?}]
	}
	"::putfile" {
	    set procArgs [list {prompt} {original}]
	}
	"::regModeKeywords" {
	    set procArgs [list {?options?} {mode} {keyword-list}]
	}
	"::removeMenu" {
	    set procArgs [list {name}]
	}
	"::replaceString" {
	    set procArgs [list {?str?}]
	}
	"::saveAs" {
	    set procArgs [list {?-f?} {?def name?}]
	}
	"::searchString" {
	    set procArgs [list {?str?}]
	}
	"::sizeWin" {
	    set procArgs [list {?window?} {width} {height}]
	}
	"::status::msg" {
	    set procArgs [list {string}]
	}
	"::statusPrompt" {
	    set procArgs [list {prompt} {?func?}]
	}
	"::switchTo" {
	    set procArgs [list {appName}]
	}
	"::unBind" {
	    set procArgs [list {'char'} {<?modifier?>} {script} {?mode?}]
	}
	"::unascii" {
	    set procArgs [list {ascii-char} {<?modifier?>} {script} {?mode?}]
	}
	"::unfloat" {
	    set procArgs [list {float-num}]
	}
	"::wc" {
	    set procArgs [list {file} {?file ...?}]
	}
	"::winNames" {
	    set procArgs [list {?-f?}]
	}
    }
    if {[info exists procArgs]} {
	return $procArgs
    }
    # End of special Alpha core command cases.
    set procArgs [Tcl::listProcArgs $ProcName]
    # Special [win::parseArgs] handling.
    if {([llength $procArgs] == 1) && ([lindex $procArgs 0] eq "args")} {
	set procBody [$Tcl::interpCmd [list info body $procName]]
	set pat {\s*win::parseArgs([^\r\n]+)}
	if {[regexp -- $pat $procBody -> realArgs] && [is::List $realArgs]} {
	    set procArgs [lreplace $realArgs 0 0 {?-w <win>?}]
	}
    }
    return $procArgs
}

namespace eval Tcl {}

proc Tcl::colorAlphaKeywords {} {

    global TclmodeVars alphaKeyWords
    
    foreach word $alphaKeyWords {
	set word [string trimleft $word ":"]
	lappend keywords $word ::$word
    }
    if {$TclmodeVars(alphaColor) != "none"} {
	regModeKeywords -a -k $TclmodeVars(alphaColor) Tcl $keywords
    } else {
	regModeKeywords -a -k {black} Tcl $keywords
    }
    return
}

proc Tcl::colorObsCommands {} {

    global TclmodeVars alphaObsCommands alphaObsProcs
    
    foreach word $alphaObsCommands {
	set word [string trimleft $word ":"]
	lappend keywords1 $word ::$word
    }
    foreach word $alphaObsProcs {
	set word [string trimleft $word ":"]
	lappend keywords2 $word ::$word
    }
    if {$TclmodeVars(recognizeObsoleteProcs)} {
	regModeKeywords -a -k {red} Tcl [concat $keywords1 $keywords2]
    } else {
	regModeKeywords -a -k $TclmodeVars(alphaColor) Tcl $keywords1
	regModeKeywords -a -k {none}                   Tcl $keywords2
    }
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "Tcl::OptionTitlebar" --
 # 
 #  Add corresponding extension/non-extension files.
 # -------------------------------------------------------------------------
 ##

proc Tcl::OptionTitlebar {} {
    if {[package::active smarterSource]} {
	set n [win::CurrentTail]
	if {[set a [string first + $n]] != -1} {
	    return "[string range $n 0 [expr {$a -1}]][file extension $n]"
	} else {
	    global smarterSourceFolder
	    # Make sure this directory exists before attempting to 
	    # search it.
	    if {[file isdirectory $smarterSourceFolder]} {
		pushd $smarterSourceFolder
		set f [glob -nocomplain -path "[file root $n]+" \
		  "*[file extension $n]"]
		popd
		return $f
	    }
	}
    } else {
	return ""
    }
}

namespace eval Inst {}

proc Inst::MarkFile {args} {
    win::parseArgs win
    
    if {[file extension $win] == ".tcl"} {
	return [Tcl::MarkFile -w $win]
    }
    removeAllMarks -w $win
    
    help::removeAllColoursAndHypers -w $win
    help::markAsAlphaManual -w $win 1
    help::colourTitle -w $win 5
    help::colourMarks -w $win 5 1
    help::underlineMarks -w $win 1
    help::hyperiseExtras -w $win 1
    help::colourCodeInserts -w $win 1
    help::hyperiseUrls -w $win 1
    help::hyperiseEmails -w $win 1
    
    goto -w $win [minPos]
    refresh -w $win
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Document Projects support ×××× #
# 

proc t_package {name parentdoc subtype } {
    # Possible 'subtypes' are: extension feature library mode menu 
    
    append dummyProc [file root $name] ".tcl"
    set t "\r\# [string totitle $subtype] declaration.\r"
    append t "alpha::$subtype $name \"¥version¥\" "
    switch -- $subtype {
	"mode" {
	    append t "\"$dummyProc\" \{¥suffixMappings¥\} \{¥mode-menus/features¥\} "
	}
	"menu" {
	    append t "\"¥global or modes¥\" \"¥title/icon¥\" "
	}
	"feature" {
	    append t "\"¥global, global-only or modes¥\" "
	}
    }
    append t "\{"
    switch -- $subtype {
        "mode" - "library" {
	    append t \
	      "\r\t\# Pre-init script, sourced when Alpha is first launched." \
	      "\r\t¥startup script¥" \
        }
        "feature" - "menu" {
	    append t \
	      "\r\t\# Initialization script." \
	      "\r\t¥initialization script¥\r\} \{" \
	      "\r\t\# Activation script." \
	      "\r\t¥activate script¥\r\} \{" \
	      "\r\t\# Deactivation script." \
	      "\r\t¥deactivate script¥" \
        }
	default {
	    append t \
	      "\r\t\# Activation script." \
	      "\r\t¥activate script¥" \
        }
    }
    append t "\r" \
      "\} uninstall \{" \
      "\r\t¥script¥\r" \
      "\} maintainer \{" \
      "\r\t\{[userInfo::getInfo author {¥your name¥}]\}"
    if {([set userEmail [userInfo::getInfo email]] ne "")} {
        append t " <" $userEmail ">\r"
    }
    if {([set userWWW [userInfo::getInfo www]] ne "")} {
	append t [expr {($userEmail eq "") ? " " : "\t"}] "<" $userWWW ">"
    }
    append t "\r" \
      "\} description \{" \
      "\r\t¥brief description¥" \
      "\r\} help \{" \
      "\r\t¥file 'name' or longer help text¥" \
      "\r\}" \
      "\r\r\# \"Dummy\" procedure to help enable auto-loading." \
      "\rproc $dummyProc {} {}"
    switch $subtype {
	"mode" {
	    append t "\r\r\# ×××× $name Mode Preferences. ×××× #" \
	      "\rnewPref ¥type¥ ¥name¥ ¥default¥ " \
	      "$name ¥proc , options, sub-opts¥"
	}
    }
    append t "\r\r¥file body¥\r"
    return $t
}

# ===========================================================================
# 
# .