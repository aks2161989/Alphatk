## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "addressBook.tcl"
 #                                          created: 10/22/2001 {10:28:23 AM}
 #                                      last update: 02/21/2006 {06:57:02 PM}
 #                               
 # Description:
 # 
 # Manages an address book containing e-mail, snail addresses, as well as
 # other info for user defined entries.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 #
 # --------------------------------------------------------------------------
 #  
 # Copyright (c) 2001-2006  Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

alpha::feature addressBook 1.1 "global-only" {
    # Initialization script.
    namespace eval AddressBook {}
    namespace eval addressBook {
	# This is the name of the current address book.
	variable Current
	ensureset Current "Default"
	# These are the default fields used to create entries.
	variable DefaultEntryFields [list \
	  "Full Name"  "Organization" \
	  "Address Line 1" "Address Line 2" "Address Line 3" \
	  "Phone Number" "Email" "Home Page"]
	# Make sure that the Default book has some default fields.
	variable EntryFields
	ensureset EntryFields(Default) $DefaultEntryFields
    }
    # This not only returns the current address book, it automatically makes
    # some of the common address book vars global, and creates several local
    # variable for use in the current procedure.
    proc addressBook::current {{newCurrent ""}} {
	variable Current
	variable EntryFields
	# Set a new current addressBook if desired.
	if {[string length $newCurrent]} {set Current $newCurrent} 
	# Set these local variables.
	variable current $Current
	variable book    ::AddressBook::$current
	variable books   [array names EntryFields]
	variable books   [concat "Default" [lremove $books "Default"]]
	variable entries [array names $book]
	variable fields  $EntryFields($current)
	ensureset EntryFields($current) [list ]
	# Uplevel some local variables.
	uplevel 1 {
	    variable Current
	    variable EntryFields
	    variable current 
	    variable book    
	    variable books   
	    variable books   
	    variable entries 
	    variable fields  
	}
    }
    # Register a build proc for the menu.
    menu::buildProc addressBook addressBook::buildMenu addressBook::postBuildMenu
    proc addressBook::buildMenu {} {
	current
	set currentList [linsert $books 1 "(-)"]
	if {[llength $currentList] > 2} {lappend currentList "(-)"}
	lappend currentList "New Address BookÉ" "Rename Address BookÉ" \
	  "Copy Address BookÉ" "Remove Address BookÉ"
	set cProc "addressBook::currentProc"
	set menuList [list \
	  eMailÉ insertMailingLabelÉ createMailingListÉ  (-) \
	  searchEntriesÉ searchFieldsÉ displayAllEntries \
	  [list Menu -m -n currentAddressBook -p $cProc $currentList] (-) \
	  addEntryÉ editEntryÉ renameEntryÉ removeEntryÉ  \
	  collectAllEmailsÉ updateMailElectrics (-) \
	  addEntryFieldÉ removeEntryFieldÉ arrangeEntryFieldsÉ \
	  addressBookPrefsÉ addressBookHelp]
	return [list build $menuList addressBook::menuProc]
    }
    proc addressBook::postBuildMenu {args} {
	current
	set dim1 [expr {[llength $entries]} ? 1 : 0]
	set menuItems [list \
	  eMailÉ insertMailingLabelÉ createMailingListÉ \
	  searchEntriesÉ searchFieldsÉ \
	  displayAllEntries editEntryÉ renameEntryÉ removeEntryÉ \
	  updateMailElectrics ]
	foreach item $menuItems {
	    enableMenuItem addressBook $item $dim1
	}
	set dim2 [expr {[llength $fields] > 0} ? 1 : 0]
	set dim3 [expr {[llength $fields] > 1} ? 1 : 0]
	enableMenuItem addressBook removeEntryFieldÉ   $dim2
	enableMenuItem addressBook arrangeEntryFieldsÉ $dim3
	# Mark the current book in the 'Current Address Book' menu.
	foreach book $books {
	    set mark [expr {$book == $current} ? 1 : 0]
	    markMenuItem -m currentAddressBook $book $mark Ã
	}
	set dim4 [expr {[llength $books] > 1} ? 1 : 0]
	enableMenuItem -m currentAddressBook "Remove Address BookÉ" $dim4
    }
    # Register a new entry for the 'New Documents' menu item.
    set {newDocTypes(New Address Book Entry)} addressBook::addEntry
} {
    # Activation script.
    menu::insert   Utils items 0 "(-)"
    menu::insert   Utils submenu "(-)" "addressBook"
    # To include all entry names as Mail Menu electrics, turn this item on.
    # This will only create electrics for entry names which are a single word,
    # i.e. no spaces||To never use entry names as Mail Menu electrics, turn
    # this item off
    newPref flag autoUpdateMailElectrics 0 Mail
    if {$MailmodeVars(autoUpdateMailElectrics)} {
	addressBook::updateMailElectrics "" 1
    } 
    # Register open windows hook.
    foreach item [list insertMailingLabelÉ collectAllEmailsÉ] {
	hook::register   requireOpenWindowsHook [list addressBook $item] 1
    }
} {
    # De-activation script.
    menu::uninsert Utils submenu "(-)" "addressBook"
    # Register open windows hook.
    foreach item [list insertMailingLabelÉ collectAllEmailsÉ] {
	hook::deregister requireOpenWindowsHook [list addressBook $item] 1
    }
    prefs::removeObsolete MailmodeVars(autoUpdateMailElectrics)
} uninstall {
    this-file
} description {
    This package inserts an 'Address Book' submenu in the Utils menu,
    allowing for the management of a user modified address book which
    can be used to create customized mailing lists
} help {
    This package inserts an 'Address Book' submenu in the Utils menu, allowing
    for the management of a user modified address book which can be used to
    create customized mailing lists.  Activate this package by using the
    "Config > Global Setup > Features" menu item.
    
    Preferences: Features
    
    
	  	Creating an Address Book Database
    
    Use the "Utils > Address Book > Add Entry" menu item to create new
    entries.  If any e-mail address is selected in the current window, you
    have the option to use this for the 'Email' field.

    The 'Collect All Emails' menu item will scan the current window for all
    e-mail addresses, and allow you to create a new entry for each one.  You
    can easily experiment with this by opening the "Installed Packages" help
    file and using this menu item.
    
    The entries in the database can be modified at any time using the menu
    items "Utils > Address Book > Edit/Rename/Remove Entry".
    
    The default entry fields used to create the database can be modified by
    using the "Utils > Address Book > Add/Remove Entry Field" menu item, or
    rearranged to suit your tastes.  Note that a 'Comments' field will always
    be appended to the end of the default entry fields list.  (It's probably
    easiest to compose the 'comments' field in a regular window and then paste
    it into the dialog if it is multi-line ...)
  
	  	Custom Mailing Lists, Searching

    Once a database of entries has been created, you can use it to create a
    customized mailing list (including only those fields that you specify), or
    to search the entries or specific fields for specific text or a regular
    expression.  New mailing lists and search results are always displayed in
    a new window, while the "Insert Mailing Label" menu item will place the
    selected entry in the current window.
    
    Database entries selected using the menu item "Insert Mailing Label" and
    "Create Mailing List" will be listed like this:
    
	Craig Barton Upright
	Department of Sociology
	Princeton University
	Wallace Hall, # 127
	Princeton NJ  08544
	<cupright@alumni.princeton.edu>

    while search result entries will be displayed like:
    
	Entry: cbu

	Name:               Craig Barton Upright
	Organization:       Department of Sociology
	Address Line 1:     Princeton University
	Address Line 2:     Wallace Hall, # 127
	Address Line 3:     Princeton NJ  08544
	Email:              <cupright@alumni.princeton.edu>
    
    although you also given the option to return the search results using the
    first style ("Mailing List Format") if desired.
    
    The item "Utils > Address Book > Display All Entries" will list all fields
    for all entries (using the second style) in a new window.
    
	  	Interaction with the Mail Menu

    This package provides limited support for the Mail Menu.
    
    --- All entry names can be automatically added as Mail mode electrics, so
    long as the entry name does not contain any spaces.  Set the Mail mode
    flag preference for 'Auto Update Mail Electrics' (available when the
    current window is in Mail mode ...)  to create these electrics on
    start-up, or whenever a new entry is added.
    
    --- These electrics can be updated at any time using the menu item
    "Address Book > Update Mail Electrics".
    
    --- Alpha's "Config > Preferences > Input-Output > WWW" preference for
    "Email Using" determines if the menu item "Address Book > Email ..."  and
    the mailing list hyperlinks will attempt to compose the e-mail using the
    Mail Menu or the default OS composing application.
    
    Preferences: WWW
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
}

proc addressBook.tcl {} {}

# ×××× Address Book Prefs ×××× #

# Entries can be added or edited using either a dialog or a text editing
# window.  This preference sets the default method.
newPref var editEntriesUsing "Choose each time" addressBook "" \
  addressBook::EditStyle array

# Search results can be displayed with full field headers, or simply
# Search results can be displayed with full field headers, or simply
# the field text.  This preference sets the default method.
newPref var displaySearchResults "Choose each time" addressBook "" \
  addressBook::SearchStyle array

namespace eval addressBook {

    variable EditStyle
    variable SearchStyle

    array set EditStyle {
	"Choose each time" {
	    addressBook::chooseOption addressBook::EditStyle editEntriesUsing
	}
	"Dialog window"                {return "0"}
	"Text editing window"          {return "1"}
    }

    array set SearchStyle {
	"Choose each time" {
	    addressBook::chooseOption addressBook::SearchStyle displaySearchResults
	}
	"Mailing List Format"          {return "-2"}
	"Including Text Header Info"   {return "0"}
	"Delimited by carriage return" {return "1"}
	"Delimited by tab"             {return "2"}
	"Delimited by space"           {return "3"}
    }
}

proc addressBook::findOption {prefName args} {

    switch $prefName {
	editEntriesUsing          {set prefArray "addressBook::EditStyle"}
	displaySearchResults      {set prefArray "addressBook::SearchStyle"}
    }
    eval [set ::[set prefArray]($::addressBookmodeVars($prefName))] $args
}

proc addressBook::chooseOption {prefArray prefName args} {
    
    set p "[quote::Prettify $prefName]É"
    set options [lremove [array names ::$prefArray] [list "Choose each time"]]
    set options [lsort -dictionary $options]
    if {![llength $options]} {
	status::msg "No options for $prefName available !!"
	return -code return
    } elseif {[llength $options] == "1"} {
	set val [lindex $options 0]
    } else {
	set setPref "(Set Address Book preferences to avoid this dialog É)"
	lappend options $setPref
	set val [listpick -p $p $options]
	if {$val == $setPref} {
	    # This is the only difference from 'prefs::chooseOption'
	    prefs::dialogs::packagePrefs "addressBook"
	    set val $::addressBookmodeVars($prefName)
	}
    }
    eval [set ::[set prefArray]($val)] $args
}


# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Address Book menu, support ×××× #
# 

proc addressBook::menuProc {menuName itemName} {
    
    current
    
    switch $itemName {
	"eMail" {
	    set email ""
	    set p "E-mail which entry?"
	    if {[catch {pickEntry $p} entryName]} {
		status::msg $entryName
		return -code return
	    }
	    while {![string length $email]} {
		if {[catch {getEntryField $entryName "Email"} email]} {
		    set email ""
		} elseif {[string length $email]} {
		    break
		}
		set    question "'$entryName' does not have an e-mail address. \r"
		append question "Would you like to edit that entry?"
		if {[askyesno $question] == "yes"} {
		    editEntry $entryName $current
		} else {
		    status::msg "Cancelled."
		    return -code return
		}
	    }
	    composeEmail [url::mailto $email]
	}
	"insertMailingLabel" {
	    set p "Insert which entry?"
	    if {[catch {pickEntry $p} entryName]} {
		status::msg $entryName
		return -code return
	    } 
	    set p   "Use which fields?"
	    set all "Use All Fields"
	    if {[catch {pickField $p 1 $all 0} fieldList]} {
		status::msg $fieldList
		return -code return
	    } 
	    if {[catch {createLabel $entryName $fieldList 1} entryText]} {
	        status::msg $entryText
		return -code return
	    } 
	    elec::Insertion $entryText
	}
	"createMailingList" {
	    # Which entries shall we use?
	    set p   "Display which entries?"
	    set all "Use All Entries"
	    if {[catch {pickEntry $p 1 $all} entryList]} {
		status::msg $entryList
		return -code return
	    } elseif {[lcontains entryList "Use All Entries"]} {
		set entryList ""
	    } 
	    # Which fields shall we use?
	    set p   "Use which fields?"
	    set all "Use All Fields"
	    if {[catch {pickField $p 1 $all 0} fieldList]} {
		status::msg $fieldList
		return -code return
	    } 
	    # Create the entries text.
	    set entryText ""
	    foreach entryName [lsort -dictionary $entryList] {
		if {![catch {createLabel $entryName $fieldList 1} entryInfo]} {
		    append entryText "${entryInfo}\r"
		}
	    }
	    # Create a new window with the mailing list.
	    set title "Mailing List"
	    set intro "Customized mailing list."
	    newWindow $entryText $title $intro
	}
	"searchEntries" {
	    set p "Enter alpha-numeric text or a Regular Expression to search:" 
	    if {[catch {prompt $p ""} pattern]} {
	        status::msg "Cancelled."
		return -code return
	    } elseif {![string length $pattern]} {
		status::msg "Cancelled -- nothing was entered."
		return -code return
	    }
	    searchFor $pattern
	}
	"searchFields" {
	    set p   "Search which field?"
	    set all "Search All Fields"
	    if {[catch {pickField $p 0 $all 1} field]} {
		status::msg $field
		return -code return
	    }
	    set p "Enter alpha-numeric text or a Regular Expression to search:" 
	    if {[catch {prompt $p ""} pattern]} {
		status::msg "Cancelled."
		return -code return
	    } elseif {![string length $pattern]} {
		status::msg "Cancelled -- nothing was entered."
		return -code return
	    }
	    searchFor $pattern $field
	}
	"displayAllEntries" {
	    set fieldList [concat {"Entry Name"} $fields "comments"]
	    set entryText ""
	    foreach entryName [lsort -dictionary $entries] {
		if {![catch {createLabel $entryName $fieldList "-1"} entryInfo]} {
		    append entryText "${entryInfo}\r"
		}
	    }
	    newWindow $entryText
	}
	"addEntry"  {
	    set email ""
	    if {[llength [winNames]] && [isSelection]} {
	        set email [getSelect]
		set question "Would you like to add an entry for '$email'?"
		if {![regexp {[-_a-zA-Z0-9.]+@[-_a-zA-Z0-9.]+} $email]} {
		    set email ""
		} elseif {[askyesno $question] != "yes"} {
		    set email ""
		} else {
		    set email [string trim $email]
		    set email [string trimright $email >]
		    set email [string trimleft  $email <]
		}
	    } 
	    regsub {@.+$} $email {} nickName
	    addEntry $nickName [list [list Email $email]]
	}
	"renameEntry" {
	    set p "Select an entry to rename:"
	    while {![catch {pickEntry $p} oldName]} {
		set p "New name for $oldName"
		if {[catch {prompt $p $oldName} newName]} {
		    status::msg "Cancelled."
		    return -code return
		} elseif {$oldName == $newName} {
		    status::msg "Names were the same !!"
		    continue
		}
		prefs::modified [set book]($oldName)
		array set $book [list $newName [set [set book]($oldName)]]
		unset [set book]($oldName)
		prefs::modified [set book]($newName)
		status::msg "'$oldName' has been renamed to '$newName'."
		set p "Select another entry to rename, or cancel:"
	    }
	}
	"removeEntry" {
	    set p "Remove which entries?"
	    if {[catch {pickEntry $p 1} entryList]} {
		status::msg $entryList
		return -code return
	    } 
	    foreach entry $entryList {
		prefs::modified [set book]($entry)
		unset -nocomplain [set book]($entry)
	    }
	    postBuildMenu
	    if {[llength $entryList] == "1"} {
		status::msg "$entryList has been removed."
	    } else {
		status::msg "$entryList have been removed."
	    }
	}
	"collectAllEmails" {
	    requireOpenWindow
	    set pat {[-_a-zA-Z0-9.]+@[-_a-zA-Z0-9.]+}
	    set pos [minPos]
	    while {![catch {search -s -f 1 -r 1 $pat $pos} match]} {
	        lappend results [eval getText $match]
		set pos [lindex $match 1]
	    }
	    if {![info exists results]} {
	        status::msg "No e-mails found in '[win::CurrentTail]'."
		return
	    } 
	    set results [lsort -unique $results]
	    set p "Add an entry for which e-mail?"
	    while {![catch {listpick -p $p $results} email]} {
		regsub {@.+$} $email {} nickName
		if {![catch {addEntry $nickName [list [list Email $email]]}]} {
		    set results [lremove $results [list $email]]
		    set p "Select another e-mail, or Cancel."
		}
		if {![llength $results]} {break}
	    }
	    postBuildMenu
	}
	"addEntryField" {
	    set fields [concat $EntryFields($current) "comments"]
	    set p "New Address Book Field Name:"
	    if {[catch {prompt $p ""} newField]} {
	        status::msg "Cancelled."
		return -code return
	    } elseif {![string length $newField]} {
	        status::msg "Cancelled -- nothing was entered."
		return -code return
	    } elseif {[lcontains fields $newField]} {
	        status::msg "Cancelled -- '$newField' was already a field."
		return -code return
	    }
	    lappend EntryFields($current) [string trim $newField]
	    prefs::modified EntryFields($current)
	    status::msg "'$newField' has been added as a default field."
	    set question "Would you like to re-arrange the field order?"
	    if {[askyesno $question] == "yes"} {
	        menuProc "" arrangeEntryFields
	    } 
	}
	"removeEntryField" {
	    set p "Remove which fields?"
	    set r [list "comments"]
	    if {[catch {pickField $p 1 "" 0 $r} fieldList]} {
		status::msg $fieldList
		return -code return
	    } 
	    set fields [lremove $fields $fieldList]
	    set EntryFields($current) $fields
	    prefs::modified EntryFields($current)
	    postBuildMenu
	    if {[llength $fieldList] == "1"} {
		status::msg "$fieldList has been removed as a default field."
	    } else {
		status::msg "$fieldList have been removed as default fields."
	    }
	}
	"arrangeEntryFields" {
	    if {[catch {dialog::arrangeItems $fields} newOrder]} {
		return
	    }
	    set EntryFields($current) $newOrder
	    prefs::modified EntryFields($current)
	    status::msg "The new order has been established."
	}
	"addressBookHelp"  {package::helpWindow "addressBook"}
	"addressBookPrefs" {prefs::dialogs::packagePrefs "addressBook"}
	default            {$itemName}
    }
}

proc addressBook::currentProc {menuName itemName} {
    
    variable DefaultEntryFields
    current
    
    switch $itemName {
	"New Address Book" {
	    set p "New address book name:"
	    if {[catch {prompt $p ""} newBook]} {
		status::msg "Cancelled."
		return -code return
	    } elseif {[lcontains books $newBook]} {
		status::errorMeg "Cancelled -- '$newBook' already exists."
	    }
	    set EntryFields($newBook) $DefaultEntryFields
	    current $newBook
	    menu::buildSome addressBook
	    status::msg "The new address book '$newBook' has been created."
	}
	"Rename Address Book" {
	    set p "Rename which address book?"
	    if {[catch {pickBook $p 0} oldName]} {
		status::msg $oldName
		return -code return
	    } 
	    set p "New name for '$oldName':"
	    set newName $oldName
	    while {[lcontains books $newName]} {
		if {[catch {prompt $p $oldName} newName]} {
		    status::msg "Cancelled."
		    return -code return
		} elseif {[lcontains books $newName]} {
		    set    question "The address book '$newName' already exists. "
		    append question "Are you sure that you want to "
		    append question "over-write entries with the same names?"
		    set result [askyesno -c $question]
		    if {$result == "yes"} {
			break
		    } elseif {$result == "no"} {
			set newName $oldName
		    } else {
			status::msg "Cancelled."
			return -code return
		    }
		}
	    }
	    set oldBook ::AddressBook::$oldName
	    set newBook ::AddressBook::$newName
	    set oldCurrent $current
	    current $oldName
	    foreach entryName $entries {
		set entryData [set [set oldBook]($entryName)]
		set [set newBook]($entryName) $entryData
	    }
	    set EntryFields($newName) $EntryFields($oldName)
	    unset -nocomplain $oldBook
	    if {$oldName != "Default"} {
		unset EntryFields($oldName)
	    } else {
		set EntryFields(Default) ""
	    }
	    if {$oldCurrent == $oldName} {
		current $newName
	    } else {
		current $oldCurrent
	    }
	    menu::buildSome addressBook
	    status::msg "The addressBook '$oldName' has been renamed '$newName'."
	}
	"Copy Address Book" {
	    set p "Copy which address book?"
	    if {[catch {pickBook $p 0} oldName]} {
		status::msg $oldName
		return -code return
	    } 
	    set p "Copy '$oldName' to:"
	    set newName $oldName
	    while {[lcontains books $newName]} {
		if {[catch {prompt $p $oldName} newName]} {
		    status::msg "Cancelled."
		    return -code return
		} elseif {[lcontains books $newName]} {
		    set    question "The address book '$newName' already exists. "
		    append question "Are you sure that you want to "
		    append question "over-write entries with the same names?"
		    set result [askyesno -c $question]
		    if {$result == "yes"} {
			break
		    } elseif {$result == "no"} {
			set newName $oldName
		    } else {
			status::msg "Cancelled."
			return -code return
		    }
		}
	    }
	    set oldBook ::AddressBook::$oldName
	    set newBook ::AddressBook::$newName
	    set oldCurrent $current
	    current $oldName
	    foreach entryName $entries {
		set entryData [set [set oldBook]($entryName)]
		set [set newBook]($entryName) $entryData
	    }
	    foreach field $fields {
		lunion EntryFields($newName) $field
	    }
	    current $oldCurrent
	    menu::buildSome addressBook
	    status::msg "The address book '$newName' has been updated."
	}
	"Remove Address Book" {
	    set p   "Remove which address book?"
	    set all "Remove all address books"
	    if {[catch {pickBook $p 1 $all 1} bookList]} {
		status::msg $bookList
		return -code return
	    } 
	    foreach item $bookList {
		set    question "Are you sure that you want to permanently "
		append question "remove the address book '$item' and "
		append question "all of its contents?  This cannot be undone."
		if {[askyesno $question] == "yes"} {
		    unset -nocomplain ::AddressBook::$item
		    unset -nocomplain EntryFields($item)
		    lappend removed $item
		} 
	    }
	    if {[info exists removed]} {
		if {[lcontains removed $current]} {
		    current "Default"
		} 
		menu::buildSome addressBook
		if {[llength $removed] == 1} {
		    status::msg "The address book '$removed' has been removed."
		} else {
		    status::msg "The address books '$removed' have been removed."
		}
	    } 
	}
	default {
	    if {![lcontains books $itemName]} {
		status::msg "'$itemName' is not a recognized address book."
		return -code return
	    } 
	    current $itemName
	    prefs::modified Current
	    postBuildMenu
	    status::msg "The current address book is '$itemName'."
	}
    }
}

proc addressBook::addEntry {{entryName ""} {entryValues ""}} {
    
    global MailmodeVars
    
    current

    if {[catch {prompt "New Entry name:" $entryName} entryName]} {
	status::msg "Cancelled."
	return -code return
    }
    if {[info exists [set book]($entryName)]} {
	set    question "'$entryName' already exists.\r"
	append question "Would you like to edit it?"
	if {[dialog::yesno $question]} {
	    set entryValues [set [set book]($entryName)]
	} else {
	    error "cancel"
	}
    }
    catch {dialogOrWindow {} $entryName $entryValues} result
    status::msg $result
}

proc addressBook::editEntry {{entryName ""} {addressbook ""}} {
    
    current

    if {![string length $entryName] || ![string length $addressbook]} {
	# Called from the menu, offer a list of all possible entries.
	set p "Select an entry to edit:"
	while {![catch {pickEntry $p} entryName]} {
	    if {[catch {set [set book]($entryName)} entryValues]} {
		set entryValues [list]
	    } 
	    catch {dialogOrWindow {} $entryName $entryValues} result
	    status::msg $result
	    set p "Select another entry to edit, or cancel:"
	}
    } else {
	# Most likely called from a hyperlink.
	# Make sure that we have the correct address book up front.
	if {![lcontains books $addressbook]} {
	    status::msg "Cancelled -- '$addressbook' is not a recognized address book."
	    return -code return
	} 
	set oldCurrent $current
	current $addressbook
	if {[catch {set [set book]($entryName)} entryValues]} {
	    status::msg "Could not find any '$entryName' entry."
	    return -code return
	} 
	catch {dialogOrWindow {} $entryName $entryValues} result
	current $oldCurrent
	status::msg $result
    }
}

proc addressBook::dialogOrWindow {title entryName {entryValues ""}} {
    
    current
    
    set which [findOption editEntriesUsing]
    switch $which {
	"0" {
	    # Use the dialog.
	    if {![catch {entryDialog $title $entryName $entryValues} result]} {
		array set $book [list $entryName $result]
		prefs::modified [set book]($entryName)
		postBuildMenu
		return "Changes to '$entryName' have been saved."
	    } else {
		error "Cancelled."
	    }
	}
	"1" {
	    # Use the text window.
	    entryWindow $title $entryName $entryValues
	    return "Edit the entry '$entryName' in this window."
	}
    }
}

proc addressBook::entryDialog {title entryName {entryValues ""}} {

    current

    if {![string length $title]} {set title "Edit the '$entryName' fields:"}
    # '$entryValues' is a list of field-text items.
    if {[llength $entryValues]} {array set entryField [join $entryValues]}
    set fieldList $fields ; lappend fieldList "comments"
    set d1 [list dialog::make -title $title]
    set d2 [list ""]
    # Add text fields.
    foreach fieldName $fieldList {
	ensureset entryField($fieldName) ""
	if {$fieldName == "comments"} {continue}
	lappend d2 [list var "${fieldName}:" $entryField($fieldName)]
    }
    # Add the comments field last.
    lappend d2 [list var2 "comments:" $entryField(comments)]
    set txtValues [eval $d1 [list $d2]]
    set result [list]
    for {set i 0} {$i < [llength $fieldList]} {incr i} {
        lappend result [list [lindex $fieldList $i] [lindex $txtValues $i]]
    }
    return $result
}

proc addressBook::entryWindow {title entryName {entryValues ""}} {

    current

    if {![string length $title]} {set title "Edit Address Book Entry"} 
    set fieldList $fields
    lappend fieldList "comments"
    set    intro "\rEdit the '$entryName' address book entry in this window.\r\r"
    append intro "When you are finished, click here: <<Save This Entry>>\r"
    append intro "to save the entry in the '$current' address book --\r"
    append intro "the text fields will appear in a dialog for confirmation.\r\r"
    append intro "Important:  Do NOT edit the blue \"Field:\" text !!!\r\r"
    append intro "\t______________________________________________________\r\r"
    set entryText [createLabel $entryName $fieldList "-1" $entryValues]
    new -n $title -text ${intro}${entryText} -m Text
    # Now add some color, and hyperize.
    win::searchAndHyperise "^Edit the '$entryName'"              {} 1 1 +10 -1
    win::searchAndHyperise "^\[a-zA-Z0-9\]\[a-zA-Z0-9 -\]+:   " {} 1 1
    win::searchAndHyperise "\"Field:\""                         {} 1 1
    win::searchAndHyperise "^Entry: +(\[^\r\n\]+)" \
      "addressBook::saveEntryWindow \"$entryName\" \"$current\"" 1 5 +7
    win::searchAndHyperise "<<Save This Entry>>" \
      "addressBook::saveEntryWindow \"$entryName\" \"$current\"" 1 5
    refresh
    # Try to position the cursor at the start of the first field text.
    set pos0 [minPos]
    foreach field $fields {
	set pat "^${field}: *"
	if {![catch {search -s -f 1 -r 1 $pat $pos0} match]} {
	    set pos0 [lindex $match 1]
	    break
	}
    }
    goto $pos0
    setWinInfo -w [win::Current] dirty 0
}

proc addressBook::saveEntryWindow {entryName addressbook} {

    global MailmodeVars
    
    current
    set oldCurrent $current
    current $addressbook
    
    set windowText [getText [minPos] [maxPos]]
    regsub {^.*________(\r|\n)} $windowText {} entryInfo
    set entryInfo [string trim $entryInfo]
    set entryValues [list ]
    set lastField ""
    foreach field [concat $fields "comments" ""] {
	set pat "${lastField}:(.*)${field}:"
	set lastFieldText ""
	if {[regexp $pat $entryInfo allofit lastFieldText]} {
	    set lastFieldText [string trim $lastFieldText]
	    if {$lastField == "Email" || $lastField == "Home Page"} {
	        set lastFieldText [string trimleft  $lastFieldText "<"]
		set lastFieldText [string trimright $lastFieldText ">"]
	    } 
	    lappend entryValues [list $lastField [string trim $lastFieldText]]
	}
	regsub ".*${field}:" $entryInfo "${field}:" entryInfo
	set lastField $field
    }
    # Now make sure that we get the last one.
    regsub ".*${field}:" $entryInfo "" entryInfo
    lappend entryValues [list $lastField [string trim $entryInfo]]
    # Now confirm the changes.
    set title "Please confirm the '$entryName' changes."
    if {![catch {entryDialog $title $entryName $entryValues} result]} {
	array set $book [list $entryName $result]
	prefs::modified [set book]($entryName)
	setWinInfo -w [win::Current] dirty 0
	killWindow
	current $oldCurrent
	if {$MailmodeVars(autoUpdateMailElectrics)} {
	    updateMailElectrics $entryName 1
	} 
	status::msg "Changes to '$entryName' have been saved."
    } else {
	current $oldCurrent
	status::msg "No changes have been saved."
	return -code return
    }
}
proc addressBook::searchFor {pattern {searchField ""}} {
    
    current

    set fieldList $fields
    lappend fieldList "comments"
    if {$searchField == "all fields"} {set searchField ""}
    if {[string length $searchField]} {
        set allFields [list $searchField]
    } else {
	set allFields [list "Entry Name"]
    }
    # Set up the searching arrays.  We have to compensate here (and below)
    # for the possibility that the user has added/deleted entry fields that
    # might still exist (or not exist at all) in specific entries.
    foreach entryName $entries {
	unset -nocomplain entryField
	set "Entry NameFields($entryName)" $entryName
	array set entryField [join [set [set book]($entryName)]]
	foreach field [array names entryField] {
	    ensureset entryField($field) ""
	    if {![string length $searchField]} {
		# We're not looking for a specific field.
		set ${field}Fields($entryName) $entryField($field)
		lunion allFields $field
	    } elseif {$field == $searchField} {
		set ${field}Fields($entryName) $entryField($field)
	    }
	}
    }
    # Now we search in all of the fields for the pattern.
    if {[string length $searchField] && ![info exists ${searchField}Fields]} {
	status::msg "No entries contain the field '$searchField'."
	return -code return
    } 
    foreach entryName $entries {
	foreach field $allFields {
	    if {![info exists ${field}Fields($entryName)]} {
	        continue
	    } elseif {[regexp -nocase $pattern [set ${field}Fields($entryName)]]} {
	        lappend entryList $entryName
	    } 
	}
    }
    # Find anything?
    if {![info exists entryList]} {
	status::msg "Couldn't find '$pattern' in address book fields."
	return -code return
    }
    set entryList [lsort -dictionary -unique $entryList]
    status::msg "matches found: [llength $entryList] (pattern: '$pattern')"
    # Which fields should be used?
    set resultStyle [findOption "displaySearchResults"]
    if {$resultStyle == 0 || $resultStyle == 1} {
        set includeEntryName 1
    } else {
        set includeEntryName 0
    }
    set p   "Display which fields?"
    set all "Display All Fields"
    if {[catch {pickField $p 1 $all $includeEntryName} fieldList]} {
	status::msg $fieldList
	return -code return
    }
    # Create the entries text.
    set entryText ""
    foreach entryName [lsort -dictionary $entryList] {
	if {![catch {createLabel $entryName $fieldList $resultStyle} entryInfo]} {
	    append entryText "${entryInfo}\r"
	}
    }
    # Creat the title and intro.
    set    title "Address Book Search Results"
    set    intro "Address Book Search Results --\r\r"
    append intro "[format {%-20s} {Search Term:}]${pattern}\r"
    if {[string length $searchField]} {
        append intro "[format {%-20s} {Search Field:}]$searchField\r"
    } 
    append intro "[format {%-20s} {Entries Found:}][llength $entryList]"
    # Create a new window with the search results.
    newWindow $entryText $title $intro
}

proc addressBook::createLabel {entryName {fieldList ""} {resultStyle 1} {entryValues ""}} {
 
    current

    if {$resultStyle != "-1" && ![info exists [set book]($entryName)]} {
	error "No entry exists for '$entryName'."
    }
    set textHeaders 0
    switch -- $resultStyle {
	"-2" {set delimiter "\r" ; set includeEmpty 0}
	"-1" {set textHeaders 1 ; set delimiter "\r" ; set includeEmpty 1}
	"0"  {set textHeaders 1 ; set delimiter "\r"}
	"1"  {set delimiter "\r"}
	"2"  {set delimiter "\t"}
	"3"  {set delimiter " "}
    }
    if {![llength $fieldList]} {
	set fieldList $fields
	if {$delimiter == "\r"} {
	    set fieldList [concat [list "Entry Name"] $fieldList]
	} 
	lappend fieldList "comments"
    }
    if {![llength $entryValues]} {
	if {[catch {set [set book]($entryName)} entryValues]} {set entryValues [list ]}
    } 
    array set entryField [join $entryValues]
    set entryText ""
    # Do we add the entry name?
    if {[lcontains fieldList "Entry Name"]} {
	if {$delimiter == "\r"} {
	    set entryText "Entry: ${entryName}\r\r"
	} else {
	    set entryText ${entryName}${delimiter}
	}
	set fieldList [lremove $fieldList [list "Entry Name"]]
    }
    # Should we include empty fields?
    if {![info exists includeEmpty]} {
        if {[lcontains fieldList "Entry Name"] || $delimiter != "\r"} {
            set includeEmpty 1
        } else {
	    set includeEmpty 0
        }
    } 
    # Add the fields.
    foreach field $fieldList {
	ensureset entryField($field) ""
	set fieldText [string trim $entryField($field)]
	if {[string length $fieldText]} {
	    if {$field == "Email" || $field == "Home Page"} {
		set fieldText [string trimright $fieldText <]
		set fieldText [string trimleft  $fieldText >]
		set fieldText "<${fieldText}>"
	    } elseif {$field == "comments"} {
		set fieldText "\r\r${fieldText}"
	    }
	} elseif {!$includeEmpty} {
	    continue
	}
	if {$textHeaders} {
	    append entryText [format {%-20s} "${field}:"]
	} 
	append entryText ${fieldText}\r
    } 
    return $entryText
}

proc addressBook::newWindow {entryText {title ""} {intro ""}} {
 
    current

    if {![string length $title]} {set title "'$current' Address Book Entries"} 
    if {![string length $intro]} {set intro "\"$current\" Address Book Entries"} 
    set    intro "\r${intro}\r\r"
    append intro "\t______________________________________________________\r\r"
    new -n $title -text ${intro}${entryText} -m Text
    # Now add some color, and hyperize.
    win::searchAndHyperise \
      "<(\[-_a-zA-Z0-9.\]+@\[-_a-zA-Z0-9.\]+)>" \
      {composeEmail "mailto:\1"} 1
    win::searchAndHyperise "<(\[^\r\n:\]+:\[^ >\]*)>" \
      {urlView "\1"} 1 
    win::searchAndHyperise "^\[a-zA-Z0-9\]\[a-zA-Z0-9 -\]+:   " {} 1 1
    win::searchAndHyperise "^Entry: +(\[^\r\n\]+)" \
      "addressBook::editEntry \"\\1\" \"$current\"" 1 5 +7
    refresh
    goto [minPos]
    winReadOnly
}

proc addressBook::updateMailElectrics {{entryList ""} {quietly 0}} {
    
    current
    
    # Make sure that the electrics will actually work !!
    # (There should really be a "MailCompletions.tcl" file with this.)
    ensureset ::completions(Mail) [list completion::electric completion::word]
    if {![llength $entryList]} {set entryList $entries}
    foreach entryName $entryList {
	if {[regexp " |\t" $entryName]} {continue}
	if {[catch {getEntryField $entryName "Email"} email]} {
	    set email ""
	}
	if {[string length $email]} {
	    set ::Mailelectrics($entryName) "×kill0${email}"
	} 
	set added 1
    }
    if {[info exists added] && !$quietly} {
	status::msg "The Mail Menu electrics have been updated."
    } 
}

proc addressBook::pickBook {{dialogText ""} {listOkay 0} {selectAllText ""} {defaultOkay 1}} {
    
    variable LastBook
  
    current
    
    set books [lsort -dictionary $books]
    ensureset LastBook [lindex $books 0]
    if {!$defaultOkay} {
	set books [lremove $books "Default"]
    } 
    if {![llength $books]} {
	error "There are no address books to list."
    }
    if {[string length $selectAllText]} {
	set pickList [concat [list $selectAllText] $books]
	set L $selectAllText
    } else {
	set pickList $books
	set L $LastBook
    }
    if {![string length $dialogText]} {
	if {$listOkay} {
	    set dialogText "Select address books:"
	} else {
	    set dialogText "Select an address book:"
	}
    } 
    if {$listOkay} {
	if {[catch {listpick -p $dialogText -L $L -l $pickList} result]} {
	    error "Cancelled."
	} 
    } else {
	if {[catch {listpick -p $dialogText -L $L $pickList} result]} {
	    error "Cancelled."
	} 
    }
    # Return the results.  Return all entries if user selected the option.
    if {$listOkay} {
	if {[string length $selectAllText] && [lcontains result $selectAllText]} {
	    set LastBook ""
	    return $books
	} else {
	    set LastBook [lindex $result end]
	    return $result
	} 
    } else {
	if {[string length $selectAllText] && $result == $selectAllText} {
	    # We return an empty list to indicate that all address books
	    # were chosen.  (Calling code is expecting a single item ...)
	    set LastBook ""
	    return ""
	} else {
	    set LastBook $result
	    return $result
	} 
    }
}

proc addressBook::pickEntry {{dialogText ""} {listOkay 0} {selectAllText ""}} {

    variable LastEntry
    
    current
  
    set entries [lsort -dictionary $entries]
    ensureset LastEntry [lindex $entries 0]
    if {![llength $entries]} {
	error "There are no address book entries to list."
    } elseif {[string length $selectAllText]} {
        set pickList [concat [list $selectAllText] $entries]
	set L $selectAllText
    } else {
        set pickList $entries
	set L $LastEntry
    }
    if {![string length $dialogText]} {
	if {$listOkay} {
	    set dialogText "Select address book entries:"
	} else {
	    set dialogText "Select an address book entry:"
	}
    } 
    if {$listOkay} {
	if {[catch {listpick -p $dialogText -L $L -l $pickList} result]} {
	    error "Cancelled."
	} 
    } else {
	if {[catch {listpick -p $dialogText -L $L $pickList} result]} {
	    error "Cancelled."
	} 
    }
    # Return the results.  Return all entries if user selected the option.
    if {$listOkay} {
	if {[string length $selectAllText] && [lcontains result $selectAllText]} {
	    set LastEntry ""
	    return $entries
	} else {
	    set LastEntry [lindex $result end]
	    return $result
	} 
    } else {
	if {[string length $selectAllText] && $result == $selectAllText} {
	    # We return an empty list to indicate that all entries were
	    # chosen.  (Calling code is expecting a single item ...)
	    set LastEntry ""
	    return ""
	} else {
	    set LastEntry $result
	    return $result
	} 
    }
}

proc addressBook::pickField {{dialogText ""} {listOkay 0} {selectAllText ""} {includeEntryName 1} {removeList ""}} {

    variable LastField
    
    current

    if {![string length $dialogText]} {
	if {$listOkay} {
	    set dialogText "Select some fields:"
	} else {
	    set dialogText "Select a field:"
	}
    } 
    # Add the 'comments' field at the end.
    lappend fields "comments"
    ensureset LastField [lindex $fields 0]
    # Add "Entry Name" if desired.
    if {$includeEntryName} {
	set fields [concat [list "Entry Name"] $fields]
    } 
    # Remove fields if desired.
    if {[llength $removeList]} {
        set fields [lremove $fields $removeList]
    } 
    if {![llength $fields]} {
	error "There are no address book fields to list."
    }
    # Add an option to select all fields if desired.
    if {[string length $selectAllText]} {
	set pickList [concat [list $selectAllText] $fields]
	set L $selectAllText
    } else {
        set pickList $fields
	set L $LastField
    }
    # Offer the list.
    if {$listOkay} {
	if {[catch {listpick -p $dialogText -L $L -l $pickList} result]} {
	    error "Cancelled."
	} 
    } else {
	if {[catch {listpick -p $dialogText -L $L $pickList} result]} {
	    error "Cancelled."
	} 
    }
    # Return the results.  Return all fields if user selected the option.
    if {$listOkay} {
	if {[string length $selectAllText] && [lcontains result $selectAllText]} {
	    set LastField ""
	    return $fields
	} else {
	    set LastField [lindex $result end]
	    return $result
	} 
    } else {
	if {[string length $selectAllText] && $result == $selectAllText} {
	    # We return an empty list to indicate that all fields were
	    # chosen.  (Calling code is expecting a single item ...)
	    set LastField ""
	    return ""
	} else {
	    set LastField $result
	    return $result
	} 
    }
}

proc addressBook::getEntryField {entryName field} {
    
    current

    if {![info exists [set book]($entryName)]} {
	error "There is no entry named '$entryName'."
    } 
    array set entryField [join [set [set book]($entryName)]]
    if {![info exists entryField($field)]} {
        error "There is no '$field' field for the entry '$entryName'."
    }
    set fieldText $entryField($field)
    if {$field == "Email" || $field == "Home Page"} {
	set fieldText [string trim      $fieldText]
	set fieldText [string trimright $fieldText >]
	set fieldText [string trimleft  $fieldText <]
    } 
    return $fieldText
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× version history ×××× #
# 
# To Do:
# 
# -- Better integrate Address Book with Mail menu, esp completions.
#    Probably involves a bit of updating to mailMenu.tcl, unfortunately.
# -- Import, export functions for popular mailer address books.
# 
# modified by  vers#  reason
# -------- --- ------ -----------
# 10/21/01 cbu 0.1    Created package.
# 10/23/01 cbu 0.2    Better integration with Mail Menu electrics.
#                     Better mailing list creation procs.
# 10/26/01 cbu 0.3    Multiple address books now available.
# -- 01/03 VMD 0.4.?  Various minor fixes.
# 02/11/03 cbu 1.0    Updated for Tcl 8.4 (which is now required.)
#                     Taking advantage of namespaces
#                     Several minor bug fixes -- many of which would have
#                       been causing both entry windows/dialog to be
#                       throwing several errors...
# 11/19/03 cbu 1.1    Lots of bug fixes for unnecessarily complicated
#                       [eval ... $args] stuff that completely broke this
#                       package.  It must not be used by anyone, else there
#                       should have been bug reports submitted.
# 01/26/04 cbu 1.1.1  Minor change in order of menu items.
# 

# ===========================================================================
# 
# .