## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # BibTeX mode - an extension package for Alpha
 # 
 # FILE: "bibtexMenu.tcl"
 #                                   created: 08/17/1994 {09:12:06 am} 
 #                               last update: 02/28/2006 {04:10:33 PM}
 # Description: 
 # 
 # Build the menu, subMenus for bibtex.
 # 
 # See the "bibtexMode.tcl" file for license info, credits, etc.
 # 
 # --------------------------------------------------------------------------
 # 
 # [Bib::listAllBibliographies] should first be called to ensure that the
 # "BibTeX Files" menu will be properly built (if desired) when this file
 # is first sourced.
 # 
 # ==========================================================================
 ## 

proc bibtexMenu.tcl {} {}

# load main bib file!
bibtexMode.tcl

namespace eval Bib {}

# ===========================================================================
#
# Register Open Windows hook
# 
# Dim some menu items when there are no open windows.
# 

proc Bib::registerOWH {{which "register"}} {
    
    global BibmodeVars global::features Bib::Entries Bib::Fields
    
    # This is only necessary if the BibTeX Menu is global.
    if {![lcontains {global::features} bibtexMenu]} {return} 
    
    set menuItems [list "entries" "fields" "sortBibFileBy" "sortBibMarks" \
      "stringConversions" "bibtexConversions"]
    
    # Dim Entries and Fields items.
    foreach i [concat [set Bib::Entries] "customEntry"] {
        hook::$which requireOpenWindowsHook [list entries $i] 1
    } 
    foreach i [concat [set Bib::Fields] "customField" "multipleFields"] {
        hook::$which requireOpenWindowsHook [list fields $i] 1
    } 
    if {$BibmodeVars(hierarchicalMenu)} {
        lappend menuItems "navigating" "formatting" 
	# Dim Searching menu items.
	foreach i {"searchEntriesÉ" "searchFieldsÉ" "quickFindCitationÉ"} {
	    hook::$which requireOpenWindowsHook [list searching $i] 1
	} 
	# Dim Cite Key Lists menu items.
	foreach i {"countEntries" "findDuplicates" "listCiteKeys"} {
	    hook::$which requireOpenWindowsHook [list citeKeyLists $i] 1
	} 
	# Dim Database menu items.
	foreach i {"addWinToDatabase" "addWinToIndex"} {
	    hook::$which requireOpenWindowsHook [list databases $i] 1
	} 
    } else {
        lappend menuItems "nextEntry" "prevEntry" "selectEntry" "selectFields" \
	  "copyCiteKey" "formatEntry" "formatRemaining" "formatAllEntries" \
	  "validateEntry" "validateRemaining" "validateAllEntries"
	if {[set alpha::platform] == "tk"} {lappend menuItems "foldEntry"}
	lappend menuItems "searchEntriesÉ" "searchFieldsÉ" \
	  "quickFindCitationÉ" "countEntries" "findDuplicates" \
	  "listCiteKeys"
	lappend menuItems "addWinToDatabase" "addWinToIndex"
    } 
    
    foreach i $menuItems {
        hook::$which requireOpenWindowsHook [list "¥282" $i] 1
    } 
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× BibTeX Menu Definition ×××× #
# 
# Some of these build procs are only used by the contextual menu.
# 

menu::buildProc bibtexMenu              Bib::buildBibMenu Bib::postEval

menu::buildProc bibModeFiles            Bib::buildBibFileMenu

menu::buildProc entries                 Bib::buildEntriesMenu
menu::buildProc fields                  Bib::buildFieldsMenu

menu::buildProc searching               Bib::buildBibSearchingMenu
menu::buildProc citeKeyLists            Bib::buildCiteKeysMenu

menu::buildProc sortBibMarks            Bib::buildSortBibMarksMenu
menu::buildProc sortBibFileBy           Bib::buildSortBibFileBy
menu::buildProc bibtexConversions       Bib::buildBibConversionsMenu

menu::buildProc defaultEntryFields      Bib::buildEntryFieldsMenu
menu::buildProc bibModeOptions          Bib::buildBibOptionsMenu Bib::postEval
menu::buildProc bibModeAcronyms         Bib::buildBibAcronymsMenu
menu::buildProc bibModeFiles            Bib::buildBibModeFilesMenu Bib::postEval

proc Bib::buildBibMenu {} {
    
    global PREFS bibtexMenu BibmodeVars menu::additions Bib::FileTails \
      Bib::Entries Bib::Fields Bib::PrefsInMenu1 Bib::PrefsInMenu2 \
      alpha::platform
    
    # Needed to know whether we should dim some menu items.
    if {[llength [set Bib::FileTails]]} {set dim ""} else {set dim "\("}
    
    set menuList {"<U<O/-bibtexApplication" "bibtexHomePage"}
    set subMenus ""
    # Add the "Bib Files Menu".
    set fileList [list \
      "rebuildFileList" "${dim}openAllBibFiles" "${dim}closeAllBibFiles"]
    if {$dim == ""} {
	lappend fileList "(-)"
	# Create the list of .bib files
	foreach bibfile [set Bib::FileTails] {lappend fileList "\ ${bibfile}&"}
    } 
    lappend menuList [list \
      Menu -n bibtexFileList -p Bib::fileListProc -M Bib $fileList]
    lappend menuList "(-)"
    # Add the Entries and Fields menus.  Note that these also have their
    # own build procs, so that these can be rebuilt on the fly.
    set entriesList [concat [set Bib::Entries] "(-)" "customEntryÉ"]
    set fieldsList  [concat [set Bib::Fields]  "(-)" "customFieldÉ" "multipleFieldsÉ"]
    lappend menuList [list \
      Menu -n entries -p Bib::entriesProc -M Bib $entriesList]
    lappend menuList [list\
      Menu -n fields -p Bib::fieldsProc -M Bib $fieldsList] "(-)"
    # Add the Navigation, Formatting, Searching menus.
    set searchList [list \
      "<U<B/EsearchEntriesÉ"           "<U<B/FsearchFieldsÉ"   \
      "${dim}<U<B/BsearchAllBibFilesÉ" "<O<B/QquickFindCitationÉ" \
      ]
    set stringsList [list \
      "stringifyEntry"   "stringifyWindow" "(-)" \
      "unstringifyEntry" "unstringifyWindow"     ]
    # Either add items or submenus.
    if {$BibmodeVars(hierarchicalMenu)} {
        set formatList [list \
	  "<U<B/LformatEntry"   "<O<U<B/LformatRemaining"   "<O<U<I<B/LformatAllEntries" "(-)" \
	  "<U<B/VvalidateEntry" "<O<U<B/VvalidateRemaining" "<O<U<I<B/VvalidateAllEntries"     ]
	set navigationList [list \
	  "<U<B/NnextEntry"   "<U<B/PprevEntry"   \
	  "<U<B/SselectEntry" "<U<B<O/SselectFields" ]
	if {[set alpha::platform] == "tk"} {
	    lappend navigationList "(-)" "<U<B/CcopyCiteKey" "/W<O<BfoldEntry"
	} else {
	    lappend navigationList "(-)" "<U<B/CcopyCiteKey" 
	}
        lappend menuList \
	  [list Menu -n navigating -p Bib::menuProc -M Bib $navigationList]
        lappend menuList \
	  [list Menu -n formatting -p Bib::menuProc -M Bib $formatList]
	lappend menuList \
	  [list Menu -n searching -p Bib::menuProc -M Bib  $searchList]
	lappend menuList \
	  [list Menu -n citeKeyLists -M Bib {}]
	lappend subMenus "citeKeyLists"
        lappend menuList "(-)"
    } else {
	set navigationList [list \
	  "<U<B/NnextEntry"       "<U<B/PprevEntry"   \
	  "<E<S<U<B/SselectEntry" "<S<O<U<B/SselectFields" "<U<B/CcopyCiteKey" ]
	if {[set alpha::platform] == "tk"} {
	    lappend navigationList "/W<O<BfoldEntry"
	}
        set formatList [list \
	  "<E<S<U<B/LformatEntry"   "<S<O<U<B/LformatRemaining"   "<S<I<O<U<B/LformatAllEntries"  \
	  "<E<S<U<B/VvalidateEntry" "<S<O<U<B/VvalidateRemaining" "<S<I<O<U<B/VvalidateAllEntries" ]
        set menuList [concat $menuList $navigationList "(-)" $formatList "(-)"]
	append  menuList " $searchList" " (-)"
	lappend menuList \
	  "<E<ScountEntries"   "<S<O${dim}countAllEntriesÉ"        \
	  "<E<SfindDuplicates" "<S<O${dim}findAllDuplicatesÉ"      \
	  "<E<SlistCiteKeys"   "<S<O${dim}listAllCiteKeys"         \
	  "(-)"
    } 
    # Add the "Sort Bib File By" and "Sort Marks By" menus.
    set sortList {
        "citeKey" "firstAuthor,Year" "lastAuthor,Year"
        "year,FirstAuthor" "year,LastAuthor"
    }
    set marksList {"alphabetically" "byPosition"}
    lappend menuList \
      [list Menu -n sortBibFileBy -p Bib::sortFileByProc -M Bib $sortList]
    lappend menuList \
      [list Menu -n sortBibMarks  -p Bib::sortMarksProc  -M Bib  $marksList]
    lappend menuList \
      [list Menu -n stringConversions -p Bib::menuProc -M Bib $stringsList]
    # Add the "Bibtex Conversions" menu
    lappend menuList [list Menu -n bibtexConversions -M Bib {}]
    # We make sure that this menu at least exists ...
    lappend subMenus "bibtexConversions"
    lappend menuList "(-)"
    # Add the "Default Entry Fields" and "Bib Mode Options" menus.
    lappend menuList [list Menu -n defaultEntryFields -M Bib {}]
    lappend menuList \
      [list Menu -n bibModeOptions -p Bib::optionsProc -M Bib [set Bib::PrefsInMenu1]]
    lappend subMenus "defaultEntryFields"
    lappend menuList [list Menu -n bibModeAcronyms -M Bib {}]
    lappend subMenus "bibModeAcronyms"
    # Add the Bib Files menu.
    set fileOptions [concat \
      "listAllBibliographiesÉ" "(-)" [set Bib::PrefsInMenu2] "(-)" \
      "viewSearchPathsÉ" "addSearchPathsÉ" "removeSearchPathsÉ" ]
    lappend menuList \
      [list Menu -n bibModeFiles -p Bib::fileOptionsProc -M Bib $fileOptions] "(-)"
    # Add the Database menu items.
    if {[file exists [file join $PREFS bibIndex]]} {
	set dim1 ""
	set re1  "re"
    } else {
	set dim1 "("
	set re1  ""
    }
    if {[file exists [file join $PREFS bibDatabase]]} {
	set dim2 ""
	set re2  "re"
    } else {
	set dim2 "("
	set re2  ""
    }
    if {$BibmodeVars(hierarchicalMenu)} {
	set dataList [list \
	  "${re1}buildIndex" "${dim1}reviewIndex" "${dim1}removeIndex" "(-)" \
	  "addWinToIndex" "addFilesToIndexÉ" "(-)" "${re2}buildDatabase" \
	  "${dim2}reviewDatabase" "${dim2}removeDatabase" "(-)" \
	  "addWinToDatabase" "addFilesToDatabaseÉ" \
	  ]
	lappend menuList [list \
	  Menu -n databases -p Bib::menuProc -M Bib $dataList]
    } else {
	lappend menuList \
	  "<E<S${re1}buildIndex"     "<S<O${dim1}reviewIndex"       \
	  "<S<B${dim1}removeIndex"                                  \
	  "<E<S${re2}buildDatabase" "<S<O${dim2}reviewDatabase"     \
	  "<S<B${dim2}removeDatabase" "(-)"                         \
	  "<E<SaddWinToIndex"    "<S<OaddFilesToIndexÉ"             \
	  "<E<SaddWinToDatabase" "<S<OaddFilesToDatabaseÉ"          
    }
    Bib::registerOWH
    return [list "build" $menuList {Bib::menuProc -M Bib} $subMenus $bibtexMenu]
}

proc Bib::buildBibFileMenu {} {

    global Bib::FileTails
    
    if {[llength [set Bib::FileTails]]} {set dim ""} else {set dim "\("}

    set fileList [list \
      "rebuildFileList" "${dim}openAllBibFiles" "${dim}closeAllBibFiles"]
    if {$dim == ""} {
	lappend fileList "(-)"
	# Create the list of .bib files
	foreach bibfile [set Bib::FileTails] {lappend fileList "\ ${bibfile}&"}
    } 

    return [list build $fileList Bib::fileListProc {}]
}

proc Bib::buildEntriesMenu {} {
    
    global Bib::Entries
    
    set entriesList [concat [set Bib::Entries] "(-)" "customEntry"]
    
    return [list build $entriesList Bib::entriesProc {}]
}

proc Bib::buildFieldsMenu {} {
    
    global Bib::Fields
    
    set fieldsList [concat [set Bib::Fields] "(-)" "customField" "multipleFields"]
    
    return [list build $fieldsList Bib::fieldsProc {}]
}

proc Bib::buildBibSearchingMenu {} {
    
    set menuList [list "searchEntriesÉ" "searchFieldsÉ" "searchAllBibFilesÉ"]

    return [list build $menuList Bib::menuProc {}]
}

proc Bib::buildCiteKeysMenu {} {
    
    global BibmodeVars Bib::CiteKeys Bib::Files
    
    set citeKeyFiles ""
    set citeKeyFiles [lsort -unique [lindex [set Bib::CiteKeys] 2]]
    if {[llength [set Bib::Files]]} {set dim1 ""} else {set dim1 "("}
    if {[llength $citeKeyFiles]}    {set dim2 ""} else {set dim2 "("}
    set citeKeyList [list \
        "countEntries" "findDuplicates" "listCiteKeys" "(-)"            \
        "${dim1}countAllEntriesÉ" "${dim1}findAllDuplicatesÉ"           \
        "${dim2}listAllCiteKeys" "(-)"                                  \
        "${dim1}createCiteKeyListÉ" "${dim2}clearCiteKeyList" "(-)"     \
        ]
    if {$dim2 == "("} {
        lappend citeKeyList "(noCiteKeysSaved"
    } else {
        foreach fileTail $citeKeyFiles {
            lappend citeKeyList "${fileTail}&"
        }
    }
    return [list build $citeKeyList Bib::citeKeysProc {}]
}

proc Bib::buildSortBibFileBy {} {
    
    set sortList {
	"citeKey" "firstAuthor,Year" "lastAuthor,Year"
	"year,FirstAuthor" "year,LastAuthor"
    }
    return [list build $sortList Bib::sortFileByProc {}]
}

proc Bib::buildSortBibMarksMenu {} {
    
    set marksList {"alphabetically" "byPosition"}
    return [list build $marksList Bib::sortMarksProc {}]
}

proc Bib::buildBibConversionsMenu {} {
    
    global menu::additions
    
    set menuList ""

    return [list build $menuList Bib::menuProc {}]
}

proc Bib::buildEntryFieldsMenu {} {
    
    global BibmodeVars  Bib::Entries alpha::platform \
      Bib::CustomEntryList Bib::CustomEntryList1 Bib::CustomEntryList2
    
    if {${alpha::platform} == "alpha"} {
            set prefix "!*"
    } else {
            set prefix "!¥"
    } 
    foreach entryName [set Bib::Entries] {
        if {[info exists Bib::MyFlds($entryName)] || $entryName == "string"} {
            # We take any Bib::MyFlds() custom entries into account (which we
            # cannot modify).
            lappend menuList "($entryName"
        } elseif {[lsearch [set Bib::CustomEntryList] $entryName] == "-1"} {
            lappend menuList "$entryName"
        } else {
            lappend menuList "${prefix}$entryName"
        } 
    }
    # Dim 'restoreDefaultFields' there are custom<EntryName> prefs.
    # We don't count user defined entries.
    if {[llength [set Bib::CustomEntryList2]]} {
	set dim1 ""
    } else {
	set dim1 "\("
    }
    # Dim 'removeCustomEntry' if there are user defined entries.
    if {[llength [set Bib::CustomEntryList1]]} {
	set dim2 ""
    } else {
	set dim2 "\("
    }
    # Finish building the menu.
    lappend menuList "(-)" "addCustomEntryÉ"\
      "${dim1}restoreDefaultFieldsÉ" "${dim2}removeCustomEntryÉ" \
       "editCustomFieldsÉ"

    return [list build $menuList Bib::entryFieldsProc {}]
}

proc Bib::buildBibOptionsMenu {} {
    
    global Bib::PrefsInMenu1
    
    return [list build [set Bib::PrefsInMenu1] Bib::optionsProc {}]
}

proc Bib::buildBibAcronymsMenu {} {
    
    global BibmodeVars Bib::AcronymsSet Bib::Acronyms

    set menuList {"viewAcronymsÉ" "addAcronymsÉ" "editAcronymsÉ"}
    set dim "("
    foreach acronym [array names Bib::Acronyms] {
        if {![info exists Bib::AcronymsSet($acronym)]} {
            # We know that this is user defined.
            set dim ""
            break
        } elseif {[set Bib::Acronyms($acronym)] != [set Bib::AcronymsSet($acronym)]} {
            # We know that this has not been redefined.
            set dim ""
            break
        } 
    } 
    lappend menuList "${dim}removeAcronymsÉ" "(-)"
    if {!$BibmodeVars(unsetAcronymList)} {
        lappend menuList "unsetAcronymList"
    } else {
        lappend menuList "resetAcronymList"
    } 
    lappend menuList "checkKeywordsÉ" "bibModeTutorial"
    
    return [list build $menuList Bib::acronymsProc {}]
}

proc Bib::buildBibModeFilesMenu {} {

    set fileOptions [concat \
      "listAllBibliographiesÉ" "(-)" [set Bib::PrefsInMenu2] "(-)" \
      "viewSearchPathsÉ" "addSearchPathsÉ" "removeSearchPathsÉ" ]
    
    return [list build $fileOptions Bib::fileOptionsProc {}]
}

# ===========================================================================
# 
# Post Evaluate -- dim or mark menu items as necessary.
# 

proc Bib::postEval {args} {
    
    global Bib::PrefsInMenu1 Bib::PrefsInMenu2 BibmodeVars
    
    foreach item [set Bib::PrefsInMenu1] {
	if {![info exists BibmodeVars($item)]} {continue}
	markMenuItem {bibModeOptions} $item $BibmodeVars($item) Ã
    }
    foreach item [set Bib::PrefsInMenu2] {
	if {![info exists BibmodeVars($item)]} {continue}
	markMenuItem {bibModeFiles} $item $BibmodeVars($item) Ã
    }
    foreach item [list view add remove] {
	enableMenuItem bibModeFiles ${item}SearchPathsÉ \
	  $BibmodeVars(useSearchPaths)
    }
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× BibTeX Menu Support ×××× #
# 

# ===========================================================================
# 
# BibTeX menu proc
# 
# This is the procedure called for all main menu items.
# 
# Note: (from "Bugs and Bug Reporting:)
# 
#       Half-fixed:
# 
# When dealing with a menu with more than perhaps 20 items, Alpha won't
# unconvert the menu-item when it is sent to the menu-proc.  So if I build
# a menu with 'Menu -n Name -p my_proc {lots of items...  thisOne}' then
# 'thisOne' appears in the menu as 'This One' (as desired), but when it is
# selected, the call is 'my_proc Name "This One"' which is incorrect.  The
# menu items near the top of the menu work fine!
# 

proc Bib::menuProc {menuName itemName} {
    
    switch -- $itemName {
	"addFilesToDatabase" - "Add Files To Database" {
	    Bib::addWinToDatabase "-1"
	}
	"addFilesToIndex" - "Add Files To Index" {
	    Bib::addWinToIndex "-1"
	}
	"addWinToDatabase" - "Add Win To Database" {
	    Bib::addWinToDatabase
	}
	"addWinToIndex" - "Add Win To Index" {
	    Bib::addWinToIndex
	}
	"buildDatabase" - "Build Database" {
	    Bib::buildDatabase 1
	}
	"buildIndex" - "Build Index" {
	    Bib::buildIndex 1
	}
	"rebuildDatabase" - "Rebuild Database" {
	    Bib::rebuildDatabase 1
	}
	"rebuildIndex" - "Rebuild Index" {
	    Bib::rebuildIndex 1
	}
	"removeDatabase" - "Remove Database" {
	    Bib::removeIndexOrDatabase "bibDatabase"
	}
	"removeIndex" - "Remove Index" {
	    Bib::removeIndexOrDatabase "bibIndex"
	}
	"reviewDatabase" - "Review Database" {
	    Bib::reviewIndexOrDatabase "bibDatabase"
	}
	"reviewIndex" - "Review Index" {
	    Bib::reviewIndexOrDatabase "bibIndex"
	}
	default {Bib::$itemName}
    }
}

# ===========================================================================
# 
# "Bib::BibModeMenuItem" --
# 
# Gives the user an alertnote if Alpha called a Bib proc for a window that
# is not in Bib mode (a known bug).
# 

proc Bib::BibModeMenuItem {{requireWindow 1}} {
    
    global mode
    
    if {$requireWindow && ![llength [winNames]]} {
        dialog::alert "This menu item requires an open window."
        return -code return
    } elseif {$mode != "Bib"} {
        dialog::alert "You might have encountered a known key-binding bug,\
          in which case you must use the menu bar.  Otherwise, you\
          selected a menu item that is only applicable to .bib files!"
        return -code return
    } 
}


# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× BibTeX Contextual Menu ×××× #
# 

# Contextual Menu modules

# Allows you to add a new entry into the active window
newPref flag "bibEntry Menu"          1 contextualMenuBib
# Allows you to add a new field into the current entry
newPref flag "bibFields Menu"         1 contextualMenuBib
# Includes all of the items in the "BibTeX > Bib Mode Acronyms" menu
newPref flag "bibModeAcronymsMenu"    0 contextualMenuBib
# Includes all of the items in the "BibTeX > Bib Mode Files" menu
newPref flag "bibModeFilesMenu"       0 contextualMenuBib
# Includes all of the items in the "BibTeX > Bib Mode Options" menu
newPref flag "bibModeOptionsMenu"     0 contextualMenuBib
# Includes items to format, validate, count (etc) entries in the active 
# window
newPref flag "bibWindowMenu"          1 contextualMenuBib
# Allows you to modify the default entry fields in BibTeX mode
newPref flag "defaultEntryFieldsMenu" 0 contextualMenuBib
# Includes all of the items in the "BibTeX > Searching" menu
newPref flag "searchingMenu"          0 contextualMenuBib
# Allows you to sort the entries in the active window
newPref flag "sortBibFileByMenu"      0 contextualMenuBib
# Allows you to sort the entry marks in the active window
newPref flag "sortBibMarksMenu"       0 contextualMenuBib

menu::buildProc "bibEntry "   Bib::buildCMEntryMenu   Bib::postEvalCM
menu::buildProc "bibFields "  Bib::buildCMFieldsMenu  Bib::postEvalCM
menu::buildProc "bibWindow"   Bib::buildCMWindowMenu  Bib::postEvalCM

# We avoid calling 'Bib::getFields' multiple times for a single run.
set Bib::LastCMFields [list]
set Bib::LastCMPos    [list]

# Sets the list of fields contained in the entry surrounding the click
# position, and returns '0' or '1' determining if we're in a selection.

proc Bib::setCMFields {} {
    
    foreach var [list LastCMPos LastCMFields] {
	variable $var
    }
    
    if {$LastCMPos != [lrange [set ::alpha::CMArgs] 0 2]} {
	set LastCMPos    [lrange [set ::alpha::CMArgs] 0 2]
	set LastCMFields [list]
	set pos [lindex [set alpha::CMArgs] 0]
	# Are we in an entry?  Do we have fields?
	if {![catch {isInEntry $pos}] && ![catch {getFields $pos} fields]} {
	    set LastCMFields $fields
	}
    }
    set pos1 [lindex [set ::alpha::CMArgs] 1]
    set pos2 [lindex [set ::alpha::CMArgs] 2]
    # Is a selection is surrounding the click position?
    return   [pos::compare $pos1 != $pos2]
}

proc Bib::buildCMEntryMenu {} {
    
    foreach var [list LastCMFields Entries] {
	variable $var
    }
    
    set selection [setCMFields]
    set citeKey   [lindex [lindex $LastCMFields 1] 1]

    if {[string length $citeKey]} {
	# We're in an entry.
	set menuList [list "${citeKey}&" "(-)" \
	  "formatEntry"    "validateEntry" \
	  "stringifyEntry" "unstringifyEntry"]
	if {[set ::alpha::platform] == "tk"} {lappend menuList "(-)" "foldEntry"}
    } else {
	set menuList [list "\(No Cite Key Found"]
	if {$selection} {
	    # We're not in an entry, but we are in a selection, so we'll
	    # offer all of the entry types as options for converting the
	    # current selection into a new entry.
	    set menuList [concat $menuList "(-)" $Entries]
	}
    }
    
    return [list build $menuList "Bib::cMProc" {}]
}

proc Bib::buildCMFieldsMenu {} {
    
    foreach var [list LastCMFields Entries Fields RqdFlds OptFlds MyFlds] {
	variable $var
    }
    
    setCMFields
    
    set citeKey   [lindex [lindex $LastCMFields 1] 1]
    set entryName [lindex [lindex $LastCMFields 1] 0]
    set allFields $Fields
    
    if {![string length $citeKey]} {set citeKey "\(No Cite Key Found"}

    if {![catch {isValidEntry $entryName} entryName]} {
	# We're in an entry.  Offer all of the relevant fields that have
	# not already been included.
	set curFields  [lindex $LastCMFields 0]
	set curfields  [string tolower $curFields]
	set addFields  [list]
	set addFields1 [list]
	set addFields2 [list]
	set addFields3 [list]
	set seenFields [list]
	set customEntryName [entryPrefConnect $entryName]
	# First create the list of required fields.
	set reqFields [list]
	if {[info exists RqdFlds($entryName)]} {
	    set rqdFields $RqdFlds($entryName)
	}
	# Now create any list of additional fields.
	if {[info exists MyFlds($entryName)] && [llength $MyFlds($entryName)]} {
	    # First see if this is a user defined entry with at least
	    # one field.
	    set optFields $MyFlds($entryName)
	} elseif {[info exists BibmodeVars($customEntryName)]} {
	    # Then check for a customEntryName preference for the entry.
	    set optFields $::BibmodeVars($customEntryName)                
	} elseif {[info exists OptFlds($entryName)]} {
	    # Or the list defined by Bib::RqdFlds().
	    set optFields $OptFlds($entryName)
	} else {
	    # Oh well...  we tried.  Offer all fields.
	    set optFields $Fields
	}
	# Now add each field which isn't there.
	foreach field $rqdFields {
	    if {[lsearch $curfields [string tolower $field]] == "-1"} {
		lappend addFields1 $field
		lappend seenFields $field
	    } 
	}
	if {![llength $addFields1]} {
	    set addFields1 [list "\(All Required Fields Present"]
	    set seenFields [concat $seenFields $rqdFields]
	} 
	foreach field $optFields {
	    if {[lsearch $curfields [string tolower $field]] == "-1"} {
		lappend addFields2 $field
		lappend seenFields $field
	    } 
	}
	if {![llength $addFields2]} {
	    set addFields2 [list "\(All Optional Fields Present"]
	    set seenFields [concat $seenFields $optFields]
	} 
	# Now add all fields, with those not seen in a submenu.
	set allFields [lremove $allFields $seenFields]
	set menuList  [concat [list "${citeKey}&" "(-)"] \
	  $addFields1 "(-)" $addFields2 "(-)" ]
	lappend menuList [list \
	  Menu -n "additionalFields" -p {Bib::cMProc} $allFields]
    } else {
	set menuList [concat [list "$citeKey" "(-)"] $allFields]
    }
    return [list build $menuList "Bib::cMProc" {}]
}

proc Bib::buildCMWindowMenu {} {
    
    set menuList [list "formatRemaining" "formatAllEntries" "(-)" \
      "validateRemaining" "validateAllEntries" "(-)" \
      "stringifyWindow" "unstringifyWindow" "(-)" \
      "countEntries" "findDuplicates" "listCiteKeys" ]
    
    return [list build $menuList Bib::cMProc {}]
}

proc Bib::postEvalCM {} {
    
    variable LastCMFields

    set citeKey [lindex [lindex $LastCMFields 1] 1]

    if {![llength $citeKey]} {return}
    
    if {"$::contextualMenuBibmodeVars(bibEntry Menu)"} {
	enableMenuItem "bibEntry " $citeKey 0
    } 
    if {"$::contextualMenuBibmodeVars(bibFields Menu)"} {
	enableMenuItem "bibFields " $citeKey 0
    } 
}

proc Bib::cMProc {menuName itemName} {
    
    variable Entries
    
    set pos0 [lindex [set ::alpha::CMArgs] 0]
    set pos1 [lindex [set ::alpha::CMArgs] 1]
    set pos2 [lindex [set ::alpha::CMArgs] 2]

    switch -- $menuName {
	"bibEntry " {
	    if {[lcontains Bib::Entries $itemName]} {
		# We know that a selection already exists, which contains
		# the click position.
		newEntry $itemName
		return
	    } else {
		goto $pos0
	    }
	    $itemName
	}
	"bibFields " - "additionalFields" {
	    if {![pos::compare $pos1 != $pos2]} {
		# Make sure that we're in the correct (click) position.
		goto $pos0
	    }
	    fieldsProc $menuName $itemName
	}
	default {
	    goto $pos0
	    $itemName
	}
    }
}

# ===========================================================================
# 
# .
