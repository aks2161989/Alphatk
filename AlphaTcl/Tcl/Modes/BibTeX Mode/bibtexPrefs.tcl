## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # BibTeX mode - an extension package for Alpha
 # 
 # FILE: "bibtexPrefs.tcl"
 #                                   created: 08/17/1994 {09:12:06 am} 
 #                               last update: 02/21/2006 {05:25:49 PM}
 # Description: 
 # 
 # Procedures for manipulating Bib mode preferences, especially custom
 # entries fields.
 # 
 # See the "bibtexMode.tcl" file for license info, credits, etc.
 # ==========================================================================
 ## 

proc bibtexPrefs.tcl {} {}

# load main bib file!
bibtexMode.tcl

namespace eval Bib {}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Preference Manipulation ×××× #
# 

# ===========================================================================
# 
# "Bib::optionsProc" --
# 
# Toggle Bib mode preferences.
# 

proc Bib::optionsProc {menuName itemName} {
    
    global BibmodeVars Bib::PrefsInMenu1 alpha::platform
    
    if {$menuName == "bibModeOptions" && [getModifiers]} {
	set text [help::prefString $itemName "Bib"]
	if {[info exists BibmodeVars($itemName)]} {
	    if {$BibmodeVars($itemName)} {set end "on"} else {set end "off"}
	    if {$end == "on"} {
		regsub {^.*\|\|} $text {} text
	    } else {
		regsub {\|\|.*$} $text {} text
	    }
	    set msg "The '$itemName' preference for Bib mode is currently $end."
	} 
    } elseif {$itemName == "autoCapitalization"} {
	Bib::autoCapitalization
    } elseif {$itemName == "bibModeHelp"} {
	package::helpWindow "Bib"
    } elseif {[lcontains Bib::PrefsInMenu1 $itemName]} {
	Bib::flagFlip $itemName
	# Any message?
	if {[regexp {Menu} $itemName]} {
	    if {$itemName == "hierarchicalMenu"} {
		if {$BibmodeVars($itemName)} {
		    set msg "The BibTeX menu is now hierarchical."
		} elseif {${alpha::platform} == "alpha"} {
		    set msg "Use the command key to access dynamic BibTeX menu items."
		} else {
		    set msg "Most items are now in the main BibTeX menu."
		}
	    }
	} elseif {$BibmodeVars($itemName)} {
	    set msg "The \"$itemName\" preference is currently on."
	} else {
	    set msg "The \"$itemName\" preference is currently off."
	}
    } else {
	Bib::$itemName
    } 
    if {[info exists text]} {alertnote $text}
    if {[info exists msg]}  {status::msg $msg}
}

# ===========================================================================
#
# Update Preferences.  
# 
# This allows for changes to take effect without a restart.
# 
# Danger:  Don't include this proc in any "BibPrefs.tcl" file !!!
# 
# This will source the prefs file, and thus put Alpha in an endless loop. 
# Instead, use the "Bib::updateMyFld" proc that I've included -- see the
# notes preceding that proc below.
# 

proc Bib::updatePreferences {{pref ""}} {
    
    global PREFS BibmodeVars Bib::PrefsInMenu1 Bib::PrefsInMenu2
    
    # If there exists a "BibPrefs.tcl" file, we want to load that as 
    # well, otherwise any keywords contained therein won't be updated
    # without a manual "Load Prefs File".

    if {[file exists [file join $PREFS BibPrefs.tcl]]} {
	uplevel #0 [list source [file join $PREFS BibPrefs.tcl]]
    }
    if {$pref == "addFields"} {
	if {[llength $BibmodeVars(addFields)]} {
# 	    Bib::checkKeywords $BibmodeVars(addFields) 2 1
	}
	Bib::setBibFields
	Bib::setBibcmds 1
	menu::buildSome "fields"
    } elseif {$pref == "addTeXCommands"} {
	Bib::setBibTeXCommandsList
	Bib::setBibcmds 1
    } elseif {[regexp {.Braces} $pref]} {
	Bib::setBibEntryDelims
	Bib::setBibFieldDelims
    } elseif {$pref == "buildFilesOnStart" || [regexp {Menu} $pref]} {
	menu::buildSome "bibtexMenu"
    } elseif {$pref == "customEntry"} {
	Bib::setBibEntries
	Bib::setBibcmds 1
	menu::buildSome "entries" "defaultEntryFields"
    } elseif {[regexp {.Completions} $pref] || $pref == "symbolColor"} {
	Bib::setBibcmds 1
   } elseif {$pref == "entryColor"} {
	Bib::setBibEntries
	Bib::setBibTeXCommandsList
	refresh
    } elseif {$pref == "fieldColor"} {
	Bib::setBibFields
	refresh
    } elseif {[regexp {^upper} $pref]} {
	Bib::setBibcmds
    } elseif {[regexp {^use} $pref] || $pref == "fullPathnames"} {
	Bib::rebuildFileList 1
    } elseif {$pref == "unsetAcronymList"} {
	Bib::unsetAcronymList $BibmodeVars(unsetAcronymList) 1
	menu::buildSome "bibModeAcronyms"
    }
    set menuPrefs [concat [set Bib::PrefsInMenu1] [set Bib::PrefsInMenu2]]
    if {[lcontains menuPrefs $pref]} {
	Bib::postEval
    }
    return
}

# ===========================================================================
# 
# Edit Preference
# 
# Edit preferences, bypassing the "Mode Prefs" dialog.  Only one at a time,
# not a list of preferences.  Usually followed by Bib::updatePreferences
# and some menu rebuilding.
# 

proc Bib::editPreference {{pref ""} {promptText ""} {sort 0}} {
    
    global BibmodeVars
    
    if {$pref == ""} {
	set pref [listpick -p "Choose a preference to edit"\
	  [lsort [array names BibmodeVars]]]
    } 
    if {$promptText == ""} {
	set promptText "Edit the \"$pref\" preference:"
    } 

    set newPreference [getline "$promptText" $BibmodeVars($pref)]
    if {$newPreference == ""} {status::msg "Cancelled." ; return} 
    if {$sort} {
	set BibmodeVars($pref) [lsort $newPreference]
    } else {
	set BibmodeVars($pref) $newPreference
    } 
    prefs::modified BibmodeVars($pref)
}

# ===========================================================================
# 
# Flag Flip
# 
# Called by menu items, change the value of flag preferences.  A menu
# rebuild (of the options menu) usually takes place after this is called.
# 

proc Bib::flagFlip {{pref ""} args} {
    
    global BibmodeVars mode
    
    set BibmodeVars($pref) [expr $BibmodeVars($pref) ? 0 : 1]
    
    if {$mode == "Bib"} {
	synchroniseModeVar $pref $BibmodeVars($pref)
    } else {
	prefs::modified BibmodeVars($pref)
    }
    
    # Anything else to do?
    Bib::updatePreferences $pref
}


proc Bib::autoCapitalization {} {
    
    global BibmodeVars Bib::Fields mode
    
    set d 1
    set d$d [list dialog::make -title "Auto Field Text Capitalization"]

    # Which words should be lower case?  Retain the case?
    regsub -all "\[\r\n\t \]" [string tolower \
      $BibmodeVars(autoCapForceLower)]  " " forceLower
    set specialPatterns $BibmodeVars(autoCapSpecialPatterns)

    # Add this page of the dialog.
    incr d
    set  t1 "These strings will always be lower case:"
    set  t2 "These special regexp patterns will also be converted:"
    lappend d$d "Case Settings"
    lappend d$d [list var2 $t1 $forceLower]
    lappend d$d [list var2 $t2 $specialPatterns]
    lappend dP  [set d$d]
    lappend prefs "autoCapForceLower" "autoCapSpecialPatterns"

    # The remaining pages will set the default fields to auto-cap.
    set autoCapFields $BibmodeVars(autoCapFields)
    foreach field [set fieldNames [set Bib::Fields]] {
	set idx [lsearch $autoCapFields $field]
	lappend fieldValues [expr {$idx == "-1" ? 0 : 1}]
    }
    # Include a separate page for 12 fields at a time.
    set idx1 0
    set idx2 [expr {[set incrBy 12] - 1}]
    set num  1
    set nums [list]
    while {[llength $fieldNames] > $idx1} {
	lappend nums $num
	set fieldNames${num}  [lrange $fieldNames  $idx1 $idx2]
	set fieldValues${num} [lrange $fieldValues $idx1 $idx2]
	incr idx1 $incrBy ; incr idx2 $incrBy ; incr num
    }
    foreach num $nums {
	if {![llength [set fieldValues${num}]]} {break}
	lappend f${num} "Auto Cap Fields $num"
	lappend f${num} [list [list multiflag [set fieldNames${num}]]  \
	  "Always auto capitalize these fields when reformatting:\r  " \
	  [set fieldValues${num}]]
	lappend dP [set f${num}]
    }

    # Now present the dialog, and save the new preferences.
    set values [eval $d1 $dP]
    set count 0
    foreach pref $prefs {
	set BibmodeVars($pref) [lindex $values $count]
	if {$mode == "Bib"} {
	    synchroniseModeVar $pref $BibmodeVars($pref)
	} else {
	    prefs::modified BibmodeVars($pref)
	}
	incr count
    } 
    # Deal with auto cap fields last.
    set autoCapFields [list]
    foreach num $nums {
	set fieldValues [lindex $values $count]
	set count2 0
	foreach field [set fieldNames${num}] {
	    if {[lindex $fieldValues $count2]} {lappend autoCapFields $field}
	    incr count2
	}
	incr count
    }
    set BibmodeVars(autoCapFields) $autoCapFields
    if {$mode == "Bib"} {
	synchroniseModeVar autoCapFields $BibmodeVars(autoCapFields)
    } else {
	prefs::modified BibmodeVars(autoCapFields)
    }
    status::msg "The new settings have been saved."
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Default Entries, Fields ×××× #
#

proc Bib::entryFieldsProc {menuName itemName} {
    
    switch -- $itemName {
	"addCustomEntry" -
	"restoreDefaultFields" - 
	"restoreDefaultFields" -
	"removeCustomEntry" {
	    Bib::$itemName
	}
	"editCustomFields" {
	    if {[llength [winNames]] && [Bib::isBibFile 1] && [askyesno \
	      "Would you like to add all of the 'extra' fields from this window\
	      to the 'Add Fields' preference?"] == "yes"} {
		Bib::addWindowFields
	    } else {
		Bib::editPreference "addFields" "Edit the Add Fields' preference:" 1
	    }
	    Bib::updatePreferences addFields
	}
	default {Bib::editEntryFields $itemName}
    } 
}


# ===========================================================================
# 
# Edit Custom Entry
# 
# Change the custom<EntryName> field preferences, creating them if
# necessary, or (if the new field list is empty) optionally restore them to
# defaults by removing the preference.  User defined entries can be removed
# entirely if the new field list is empty, but can also remain.
# 
# The name should be names of the form "book", not "customBook".
# 

proc Bib::editEntryFields {{entryName ""}} {
    
    global BibmodeVars Bib::Entries Bib::RqdFlds Bib::MyFlds
    
    if {$entryName == ""} {
	set entryName [listpick -p \
	  "Select an entry to edit:" [set Bib::Entries]]
    }
    if {$entryName == "string" || $entryName == "customEntry" || \
      [info exists Bib::MyFlds($entryName]} {
	status::msg "Sorry, the entry \"$entryName\" cannot be edited from this menu."
	return
    } 
    # If by some chance the entryName is both not in the Bib::RqdFlds() array
    # and doesn't have a preference, we should try rebuilding the menu.
    if {[lsearch [set Bib::Entries] $entryName] == "-1"} {
	alertnote "Couldn't find any information for \"$entryName\".\
	  It will be removed from the menu."
	Bib::updatePreferences customEntry
	return
    }
    # Find the custom pref's name, and if it exists use its fields.
    # Otherwise, use the Bib::RqdFlds()'s fields.
    set customEntryName [Bib::entryPrefConnect $entryName]
    if {[info exists BibmodeVars($customEntryName)]} {
	set defaultList $BibmodeVars($customEntryName)
    } else {
	set defaultList [set Bib::RqdFlds($entryName)]
    }
    # Get the new list of default fields.
    set newEntryFields [getline "Modify the list of fields\
      for the entry \"$entryName\":" $defaultList]
    if {$newEntryFields == ""} {status::msg "Cancelled." ; return}
    if {$newEntryFields == $defaultList} {
	status::msg "Nothing was entered -- \"$entryName\" fields are unchanged."
    } else {
	# Update the mode preferences, creating the new pref if necessary.
	set BibmodeVars($customEntryName) $newEntryFields
	prefs::modified BibmodeVars($customEntryName)
    }
    Bib::updatePreferences customEntry
    status::msg "Current \"$entryName\" fields: $BibmodeVars($customEntryName)"
}

# ===========================================================================
# 
# Restore Default Fields.
# 
# Restore the fields of an entry to those defined in Bib::RqdFlds().  This will
# remove any custom<EntryName> preferences.  If the entry is a custom entry
# defined by the user (via the "Custom Entry" menu item), the user is
# instead given the option to remove it, although these entries are not
# included in the listpick.
# 
# The list should be names of the form "book", not "customBook".
# 

proc Bib::restoreDefaultFields {{entryNameList ""}} {
    
    global BibmodeVars Bib::CustomEntryList2
    
    if {$entryNameList == ""} {
	set title "Select entries to restore :"
	set entryNameList [listpick -l -p $title [set Bib::CustomEntryList2]]
    }
    foreach entryName $entryNameList {
	prefs::removeObsolete [Bib::entryPrefConnect $entryName]
	lappend finalList $entryName
    }
    Bib::updatePreferences customEntry
    status::msg "\"$finalList\" fields have been restored to defaults."
}

# ===========================================================================
# 
# Add User-Defined Custom Entry
# 
# Offer all fields, save them in the order chosen.
# 

proc Bib::addCustomEntry {{saveAsPref "1"}} {
    
    global BibmodeVars Bib::Fields

    set entryName ""
    while {![string length $entryName]} {
	if {[catch {prompt "Enter the name of the custom entry:" $entryName} entryName]} {
	    error "cancel"
	} elseif {[regsub -all " " $entryName "" entryName]} {
	    alertnote "No spaces allowed in entry names! -- \r\
	      The new entry name will be $entryName"
	    break
	} else {
	    break
	}
    } 
    if {!$saveAsPref} {
	if {[askyesno "Do you want to make \"$entryName\" a default menu item? \
	  It will then be available as an electric completion, too."] == "yes"} {
	    set saveAsPref 1
	}
    } 
    # Choose the first field ...
    set fieldList [listpick -L {author} -p \
      "Pick the first field:" [set Bib::Fields]]
    # ... and remove it from the list ...
    set nextFields [concat  "CompleteÉ" [set Bib::Fields]]
    set fieldSpot  [lsearch  $nextFields $fieldList]
    set nextFields [lreplace $nextFields $fieldSpot $fieldSpot]
    # ... and offer the remaining fields.
    while {[set nextField [listpick -L {CompleteÉ} -p \
      "Choose another field, or press Complete É :" $nextFields]] != "CompleteÉ"} {
	append fieldList " $nextField"
	set fieldSpot  [lsearch  $nextFields $nextField]
	set nextFields [lreplace $nextFields $fieldSpot $fieldSpot]
	dialog::alert "Current fields:  $fieldList"
    }
    # Check to make sure that the first word is not Capitalized.
    set first [string tolower [string index $entryName 0]]
    if {$first != [set First [string index $entryName 0]]} {
	set entryName [concat $first[string range $entryName 1 end]]
	dialog::alert "The new entry will be \"$entryName\""
    } 
    # Check to see if $entryName is already defined as a keyword somewhere.
    if {$saveAsPref} {
	set customEntryName [Bib::entryPrefConnect $entryName]
	set BibmodeVars($customEntryName) $fieldList
	prefs::modified BibmodeVars($customEntryName)
	Bib::updatePreferences customEntry
	status::msg "The new entry '$entryName' has been saved."
    }
    return [list $entryName $fieldList]
}

# ===========================================================================
# 
# Remove (User-Defined) Custom Entry
# 
# Return the list of all (user defined) entryName preferences, and remove
# them.  These should be names of the form "myEntry", not "customMyEntry".
# 

proc Bib::removeCustomEntry {{entryNameList ""}} {
    
    global Bib::CustomEntryList1
    
    if {$entryNameList == ""} {
	set title "Select entries to remove :"
	set entryNameList [listpick -l -p $title [set Bib::CustomEntryList1]]
    }
    foreach entryName $entryNameList {
	prefs::removeObsolete BibmodeVars([Bib::entryPrefConnect $entryName])
	lappend finalList $entryName
    }
    Bib::updatePreferences customEntry
    if {[set length [llength $finalList]] == 1} {
	status::msg "The custom entry \"$finalList\" has been removed."
    } else {
	status::msg "The custom entries \"$finalList\" have been removed."
    }
}

# ===========================================================================
# 
# Bib::addWindowFields
# 
# Add all of the "extra" fields which appear in entries in this window.
# 

proc Bib::addWindowFields {} {
    
    global Bib::DefaultFields BibmodeVars 
    
    if {![llength [winNames -f]]} {
	error "Cancelled -- no current window!"
    } 
    
    status::msg "Scanning [win::CurrentTail] for all fieldsÉ"
    
    set length1 [llength $BibmodeVars(addFields)]
    set pos [minPos]
    set pat {^[\t ]*([a-zA-Z]+)[\t ]*=}
    set newFields ""
    while {![catch {search -s -f 1 -r 1 $pat $pos} match]} {
	set pos [nextLineStart [lindex $match 1]]
	set fieldLine [getText [lindex $match 0] [lindex $match 1]]
	regexp $pat [string tolower $fieldLine] match aField
	if {![lcontains Bib::DefaultFields $aField]} {
	    append BibmodeVars(addFields) " $aField"
	} 
    }
    set BibmodeVars(addFields) [lsort -unique $BibmodeVars(addFields)]
    if {$length1 == [llength $BibmodeVars(addFields)]} {
	status::msg "No \"extra\" fields from this window were found."
	return -code return
    } else {
	prefs::modified BibmodeVars(addFields)
    }
    listpick -p "The custom fields include :" $BibmodeVars(addFields)
    status::msg ""
}

# ===========================================================================
# 
# .
