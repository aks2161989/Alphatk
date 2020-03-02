## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "favoritesMenu.tcl"
 #                                          created: 02/26/2004 {10:16:48 PM}
 #                                      last update: 02/28/2006 {04:08:56 PM}
 # Description:
 # 
 # Define Alpha-specific Favorite Applications, Folders, and Files which can
 # be opened with user-defined Keyboard Shortcuts.  Throughout this file, a
 # "shortcut" refers to one that appears in the menu, while a "binding" is
 # one that possibly contains a prefix, and is not in the menu.
 # 
 # Inspired by a bugzilla RFE filed by Joachim Kock.  In some ways, this is
 # simply an enhanced version of AlphaTcl's "Switchto Menu" package.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # Copyright (c) 2004-2006  Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

# ×××× Feature Declaration ×××× #
alpha::feature favoritesMenu 1.0.1 "global-only" {
    # Initialization script.
    menu::buildProc "favorites" {favorites::buildMenu} {favorites::postBuildMenu}
    # Includes all of your current Favorite items, allowing them to open 
    # them using the methods specified by the Favorites Menu feature
    newPref flag "favoritesMenu" 0 contextualMenu
    # Place this item in the first section.
    ;namespace eval contextualMenu {
	variable menuSections
	lappend menuSections(1) "favoritesMenu"
    }
} {
    # Activation script.
    menu::insert   File submenu "<E<S/Wclose" "favorites"
    favorites::bindBindings 1
} {
    # Deactivation script.
    menu::uninsert File submenu "<E<S/Wclose" "favorites"
    favorites::bindBindings 0
} uninstall {
    this-file
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} description {
    This package allows you to open Favorite Files, Folders and Applications
    from within Alpha using custom Keyboard Shortcuts
} help {
    This package allows you to open Favorite Files, Folders and Applications
    from within Alpha using custom Keyboard Shortcuts.  After it has been
    turned on in the "Config > Global Setup > Features" dialog
    
    Preferences: Features
    
    a new "File > Favorites" submenu is created, allowing you to add new
    Favorite Items.  Favorites can be Files, Folders, or Applications.
    
	  	Table Of Contents

    "# Adding New Favorites"
    "# Keyboard Shortcuts"
    "# Opening Favorites"
    "# Power User Tip"
    "# Favorites Utility Items"
    "# Contextual Menu Module"

    <<floatNamedMarks>>


	  	Adding New Favorites
    
    Select "File > Favorites > New Favorite", which will open a series of
    dialogs that look like <<favorites::itemDialog>>.  You must first choose
    what "type" of Favorite this will be, i.e. a File, Folder or Application.
    Any open windows that exist as local files can also be selected, as well
    as your collection of files collected by the package: recentFilesMenu ,
    and your collection of folders collected by the package: recentDirsMenu .
    Once you have selected an Item Type, the next dialog allows you to name
    the Favorite, and locate it in your local disk.
    
    You must enter a name for the Favorite Item.  This could be the name of
    the File, Folder, or Application, but we don't use that by default
    because there might be some ambiguity if you have several items on your
    disk with the same name.  (See also the "# Power User Tip" below for
    additional naming strategies.)
    
    You must also select a location for the Favorite Item.  If you fail to
    do so, the dialog will keep re-appearing until you either choose a
    location or press the "Cancel" button.

    The list of Favorites has nothing to do with any MacOS Favorites, by
    the way, and changing Alpha's menu does nothing to your System Prefs.


	  	Keyboard Shortcuts
    
    Each Favorite can also be assigned a unique Keyboard Shortcut that will
    appear in the menu and which will be available in any mode, even if
    there are no open windows.  Two options are available here, either or
    both can be defined when you first create a New Favorite Item, or added
    later when by selecting "File > Favorites > Edit Favorite".
    
    "Menu Shortcuts" will appear in the "File > Favorites" menu.  
    
    "Other Keybindings" will not, and can be created with a "prefix" so
    that a binding such as
    
	Control-C Control-F

    can be used to open a Favorite Item.  You should always confirm that a
    proposed binding is not already in use before assigning it.

    
	  	Opening Favorites

    Favorites are opened by selecting them from the "Files > Favorites" menu,
    or by pressing their associated Keyboard Shortcuts.
    
    "Files" are always opened in Alpha.
    
    "Folders" open an 'Open File' dialog using the specified folder as the
    default location.  The chosen file will then be opened in Alpha.
    
    "Applications" will be launched if necessary, and then brought to the
    front.
    
    If any of your Favorites have been renamed or moved on your local disk,
    Alpha will not be able to locate it.  You must either Edit the item and
    find the new location, or Delete it.
    

	  	Power User Tip

    If the name of a Favorite Item ends in "*", as in "Readme *", then the
    default opening behavior is changed.
    
    "Files" will be sent to the Finder to be opened using whatever default
    application is deemed appropriate by the OS.
    
    "Folders" will be displayed in the OS Finder.
    
    "Applications" will be launched in the background.
    
    
	  	Favorites Utility Items
    
    After you have created a list of Favorites, you can select any of the
    various utilities to Edit/Rename/Delete any saved Favorite Item.  When
    you "Delete" them you are only affecting this submenu, and you're not
    actually deleting them from your local disk.
    
    Once you have created a Favorite Item that is a File, Folder, or
    Application, however, you cannot change that item's "type".
    
    
	  	Contextual Menu Module
    
    This package also creates a new "Favorites" Contextual Menu module that
    can be activated after if this package has been turned on.
    
    Preferences: ContextualMenu

    This CM menu will offer the same options as "File > Favorites".
}

proc favoritesMenu.tcl {} {}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 

##
 # --------------------------------------------------------------------------
 #
 # "namespace eval favorites" --
 # 
 # If we needed any internal variables defined in advance in order to
 # properly initialize this package, they would be defined here.
 #
 # --------------------------------------------------------------------------
 ##

namespace eval favorites {}
  
# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Favorites Menu ×××× #
# 
# 

##
 # --------------------------------------------------------------------------
 #
 # "favorites::buildMenu" --
 #
 # This is the build proc for the "Files > Favorites" menu.  It is also used
 # by the Contextual Menu module.
 #
 # --------------------------------------------------------------------------
 ##

proc favorites::buildMenu {} {
    
    global alpha::macos alpha::platform
    
    variable savedFavorites
    
    set files        [list]
    set folders      [list]
    set applications [list]
    set menuList     [list]

    # Categorize the saved favorites.
    foreach itemName [lsort -dictionary [array names savedFavorites]] {
	set typeList "[lindex $savedFavorites($itemName) 0]s"
	set shortcut [lindex $savedFavorites($itemName) 2]
	lappend $typeList "${shortcut}${itemName}"
    }
    # Add each item from each category to the menuList, with shortcuts.
    foreach typeList [list "files" "folders" "applications"] {
	if {![llength [set $typeList]]} {
	    continue
	} 
	set TypeList [string totitle $typeList]
	if {(${alpha::platform} eq "tk")} {
	    lappend menuList "($TypeList"
	} elseif {(${alpha::macos} == 2)} {
	    lappend menuList "([menu::itemWithIcon "!\x1f<I$TypeList" 83]"
	} else {
	    lappend menuList "([menu::itemWithIcon $TypeList 83]"
	}
	foreach menuItem [set $typeList] {
	    lappend menuList $menuItem
	}
	lappend menuList "(-)"
    }
    # Add utility items.
    lappend menuList "New FavoriteÉ" "Edit FavoriteÉ" "Rename FavoriteÉ" \
      "Delete FavoriteÉ" "(-)" "Favorites Menu Help"
    
    return [list build $menuList {favorites::menuProc -m}]
}

##
 # --------------------------------------------------------------------------
 #
 # "favorites::postBuildMenu" --
 # 
 # Dim Favorites Utility items if the user hasn't defined any yet.
 #
 # --------------------------------------------------------------------------
 ##

proc favorites::postBuildMenu {} {
    
    variable savedFavorites
    
    set dim [expr {[llength [array names savedFavorites]] > 0 ? 1 : 0}]
    foreach utility [list "Edit" "Delete" "Rename"] {
	enableMenuItem -m "favorites" "$utility FavoriteÉ" $dim
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "favorites::rebuildMenu" --
 # 
 # Called whenever the user has called any Favorites Utility items, such as
 # adding, editing, renaming, or deleting Saved Favorites.
 #
 # --------------------------------------------------------------------------
 ##

proc favorites::rebuildMenu {args} {

    menu::buildSome "favorites"
    favorites::bindBindings 1
    status::msg "The \"File > Favorites\" menu has been rebuilt."
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "favorites::menuProc" --
 # 
 # All menus pass their items through this procedure.  Saved Favorites are
 # opened using the appropriate procedure, all other Utility items are
 # redirected as necessary.
 #
 # --------------------------------------------------------------------------
 ##

proc favorites::menuProc {menuName itemName} {
    
    variable savedFavorites
    
    if {[info exists savedFavorites($itemName)]} {
	set itemType [lindex $savedFavorites($itemName) 0]
	set location [lindex $savedFavorites($itemName) 1]
	switch -- $itemType {
	    "file" {
		if {![file exists $location]} {
		    error "Cancelled -- the item \"{$itemName}\"\
		      doesn't appear to exist on your local disk."
		} elseif {([string index $itemName end] eq "*")} {
		    set cmd "file::openInDefault"
		} else {
		    set cmd "file::openQuietly"
		}
	    }
	    "folder" {
		if {![file exists $location]} {
		    error "Cancelled -- the item \"{$itemName}\"\
		      doesn't appear to exist on your local disk."
		} elseif {([string index $itemName end] eq "*")} {
		    set cmd "file::showInFinder"
		} else {
		    set cmd "file::browseFor"
		}
	    }
	    "application" {
		if {([string index $itemName end] eq "*")} {
		    set cmd "app::launchBack"
		} else {
		    set cmd "app::launchFore"
		}
	    }
	}
	$cmd $location
    } else {
	switch -- $itemName {
	    "New Favorite" {
		favorites::addNewItem
	    }
	    "Edit Favorite" {
		favorites::editItem
	    }
	    "Rename Favorite" {
		favorites::renameItem
	    }
	    "Delete Favorite" {
		favorites::removeItem
	    }
	    "Favorites Menu Help" {
		package::helpWindow "favoritesMenu"
	    }
	    default {
		error "Unknown item name: $itemName"
	    }
	}
    }
    return
}

# ===========================================================================
#
# ×××× ------------ ×××× #
# 
# ×××× Favorites Utilities ×××× #
# 

##
 # --------------------------------------------------------------------------
 #
 # "favorites::addNewItem" --
 # 
 # Calls [favorites::itemDialog], prompting the user to select an Item Type
 # and other relevant settings.  At the end we allow the user to run through
 # the routine again to add more Favorites.  All settings are saved between
 # Alpha editing sessions.
 # 
 # --------------------------------------------------------------------------
 ##

proc favorites::addNewItem {} {
    
    variable savedFavorites
    
    set result [list]
    set title    "Create New Favorite"
    set itemName ""
    set itemType ""
    set location ""
    set shortcut ""
    set binding  ""
    while {1} {
	# Call the dialog.
	set result [favorites::itemDialog \
	  $title $itemName $itemType $location $shortcut $binding]
	set itemName [lindex $result 0]
	set itemType [lindex $result 1]
	set location [lindex $result 2]
	set shortcut [lindex $result 3]
	set binding  [lindex $result 4]
	if {![info exists savedFavorites($itemName)]} {
	    break
	}
	set q "A favorite item named \"${itemName}\" already exists.\
	  Do you want to over-write its previous values?"
	if {[askyesno $q]} {
	    break
	} 
    }
    set savedFavorites($itemName) [list $itemType $location $shortcut $binding]
    prefs::modified savedFavorites($itemName)
    favorites::rebuildMenu
    if {[askyesno "Do you want to add another favorite?"]} {
        favorites::addNewItem
    } 
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "favorites::itemDialog" --
 # 
 # Prompt for an Item Type if necessary, and then use any default values in
 # the "args" list to create the dialog.  If an Item Name has been supplied,
 # the user is not allowed to change that.  We go to a little bit of trouble
 # to ensure that there is an Item Name and a proper Location set.
 # 
 # --------------------------------------------------------------------------
 ##

proc favorites::itemDialog {args} {
    
    global recent::Files recent::Directories
    
    set title    [lindex $args 0]
    set itemName [lindex $args 1]
    set itemType [lindex $args 2]
    set location [lindex $args 3]
    set shortcut [lindex $args 4]
    set binding  [lindex $args 5]
    
    if {![string length $itemType]} {
        set itemType [lindex [favorites::chooseType] 0]
    }
    # Build the dialog page.
    set dialogPage [list ""]
    if {![regexp {^Edit} $title]} {
	lappend dialogPage [list "var" "Favorite Name:" $itemName]
    } else {
        lappend dialogPage \
	  [list [list "menu" [list $itemName]] "Current Favorite:" $itemName]
    }
    switch -- $itemType {
	"choose from active windows" {
	    set windows [list]
	    foreach w [winNames -f] {
		if {[win::IsFile $w]} {
		    lappend windows $w
		} 
	    }
	    set windows [lsort -dictionary -unique $windows]
	    set itemDialogData \
	      [list [list "menu" $windows] "Active Windows:" [win::Current]]
	}
	"choose from recent files" {
	    set recentFiles [list]
	    foreach f [set recent::Files] {
		if {[file exists $f]} {
		    lappend recentFiles $f
		} 
	    }
	    set recentFiles [lsort -dictionary -unique $recentFiles]
	    set itemDialogData \
	      [list [list "menu" $recentFiles] "Recent Files:" ""]
	}
	"choose from recent folders" {
	    set recentFolders [list]
	    foreach f [set recent::Directories] {
		if {[file exists $f]} {
		    lappend recentFolders $f
		} 
	    }
	    set recentFolders [lsort -dictionary -unique $recentFolders]
	    set itemDialogData \
	      [list [list "menu" $recentFolders] "Recent Folders:" ""]
	}
	"file" {
	    set itemDialogData [list "file" "File:" $location]
	}
	"folder" {
	    set itemDialogData [list "folder" "Folder:" $location]
	}
	"application" {
	    set itemDialogData [list "appspec" "Application:" $location]
	}
    }
    lappend dialogPage $itemDialogData
    lappend dialogPage [list "menubinding" "Menu Shortcut:" $shortcut]
    lappend dialogPage [list "binding" "Other Keybinding:"  $binding]
    # Add a "Help" button.
    set button1 [list \
      "Help" \
      "Click this button to open Favorites Menu help" \
      "package::helpWindow favoritesMenu ; set retCode 1 ; set retVal {}"]
    set result [dialog::make -title $title -width 500 \
      -addbuttons $button1 $dialogPage]
    # Collect the new values, and ensure that they are valid.
    set itemName [lindex $result 0]
    set location [lindex $result 1]
    set shortcut [lindex $result 2]
    set binding  [lindex $result 3]
    switch -- $itemType {
        "choose from active windows" {
	    set location [win::StripCount $location]
            set itemType "file"
        }
        "choose from recent files" {
            set itemType "file"
        }
	"choose from recent folders" {
	    set itemType "folder"
	}
    }
    if {![string length $itemName]} {
        set msg "You must give the item a name."
    } elseif {![string length $location]} {
	set msg "You must locate the ${itemType}."
    }
    if {[info exists msg]} {
        # We need to present the dialog again.
        alertnote $msg
	return [favorites::itemDialog $title \
	  $itemName $itemType $location $shortcut $binding]
    } else {
	# We're done, so return the results.
	return [list $itemName $itemType $location $shortcut $binding]
    }
}

##
 # --------------------------------------------------------------------------
 #
 # "favorites::chooseType" --
 # 
 # Present a dialog offering Item Type options.  If appropriate, we will also
 # allow the user to select from active windows, and recent files/folders.
 # [favorites::itemDialog] will have to deal with these special cases.
 # 
 # --------------------------------------------------------------------------
 ##

proc favorites::chooseType {} {
    
    global recent::Files recent::Directories
    
    # Create a default set of options.
    set txt "You can choose to create a favorite file, folder, or application.\
      Select an option from the pop-up menu, and then you will be prompted\
      to locate the item on your local disk.\r"
    set options [list "File" "Folder" "Application"]
    # Add extras for Active Windows, Recent Files, Recent Folders?
    foreach w [winNames -f] {
	if {[win::IsFile $w]} {
	    lappend extras "Active Windows"
	    break
	} 
    }
    if {[package::active "recentFilesMenu"] \
      || [package::active "recentFilesMultiMenu"]} {
	if {[info exists recent::Files]} {
	    foreach f [set recent::Files] {
		if {[file exists $f]} {
		    lappend extras "Recent Files"
		    break
		} 
	    }
	} 
    } 
    if {[package::active "recentDirsMenu"]} {
	if {[info exists recent::Directories]} {
	    foreach f [set recent::Files] {
		if {[file exists $f]} {
		    lappend extras "Recent Folders"
		    break
		} 
	    }
	} 
    } 
    # If we have extras, adjust the dialog text and pop-up menu options.
    if {[info exists extras]} {
	append txt "You can also select a new Favorite from a list of your "
	if {([llength $extras] == 1)} {
	    set which [lindex $extras 1]
	} elseif {([llength $extras] == 2)} {
	    set which [join $extras " or "]
	} else {
	    set which [join [lrange $extras 0 end-1] ", "]
	    append which " or [lindex $extras end]"
	}
	append txt [string tolower $which] "."
	lappend options "-"
	foreach extra $extras {
	    lappend options "Choose From $extra"
	}
    } 
    # Add a "Help" button.  We need a button name, balloon help, and a
    # script to evaluate when it is selected.
    set button1 [list \
      "Help" \
      "Click this button to open Favorites Menu help" \
      "package::helpWindow favoritesMenu ; set retCode 1 ; set retVal {}"]
    return [string tolower [dialog::make -title "New Favorite Type" \
      -addbuttons $button1 [list "" \
      [list "text" $txt] \
      [list [list "menu" $options] "Item Type:"]]]]
}

##
 # --------------------------------------------------------------------------
 #
 # "favorites::editItem" --
 # 
 # Edit the settings (except for the Item Name) of a Favorites previously
 # defined by the user, save the new settings, and then rebuild the menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc favorites::editItem {} {
    
    variable savedFavorites
    
    if {![llength [set favorites [array names savedFavorites]]]} {
        error "Cancelled -- there are no favorites to edit."
    } 
    set p "Choose a favorite to edit:"
    set favorites [lsort -dictionary $favorites]
    set options $favorites
    set title "Edit A Favorite"
    while {1} {
        set itemName [listpick -p $p $options]
	if {($itemName eq "(Finish)")} {
	    break
	} 
	set result [eval [list favorites::itemDialog $title $itemName] \
	  $savedFavorites($itemName)]
	set savedFavorites($itemName) [lrange $result 1 end]
	prefs::modified savedFavorites($itemName)
	favorites::rebuildMenu
	set p "Choose another, or Finish:"
	set options [concat [list "(Finish)"] $favorites]
    }
    status::msg "All changes have been saved."
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "favorites::renameItem" --
 # 
 # Rename a previously saved Favorite Item.
 # 
 # --------------------------------------------------------------------------
 ##

proc favorites::renameItem {} {
    
    variable savedFavorites
    
    if {![llength [set favorites [array names savedFavorites]]]} {
	error "Cancelled -- there are no Favorites to edit."
    } 
    set p "Choose a Favorite to rename"
    set favorites [lsort -dictionary $favorites]
    set options $favorites
    set title "Rename A Favorite"
    while {1} {
	set itemName [listpick -p $p $options]
	set newName  ""
	if {($itemName eq "(Finish)")} {
	    break
	}
	while {1} {
	    set p "New name for \"${itemName}\":"
	    if {[catch {prompt $p $itemName} newName]} {
		status::msg "Cancelled."
		set newName ""
	        break
	    } elseif {![string length [string trim $newName]]} {
	        alertnote "The new name cannot be an empty string!"
		continue
	    } elseif {($newName eq $itemName)} {
		set newName ""
		status::msg "No changes were made."
		break
	    } elseif {([lsearch $favorites $newName] > -1)} {
		set q "The name \"${newName}\" is already used by a different\
		  Favorite -- do you want to over-write the previous values?"
		if {![askyesno $q]} {
		    continue
		} else {
		    break
		}
	    } else {
	        break
	    }
	}
	if {[string length $newName]} {
	    set savedFavorites($newName) $savedFavorites($itemName)
	    prefs::modified savedFavorites($newName)
	    prefs::modified savedFavorites($itemName)
	    unset savedFavorites($itemName)
	} 
	favorites::rebuildMenu
	set favorites [lsort -dictionary [array names savedFavorites]]
	set options [concat [list "(Finish)"] $favorites]
	set p "Choose another, or Finish:"
    }
    status::msg "All changes have been saved."
    return
}
   
##
 # --------------------------------------------------------------------------
 #
 # "favorites::removeItem" --
 # 
 # Remove a previously saved Favorite from the user's preferences.  This does
 # not remove the Favorite from the local disk.
 # 
 # --------------------------------------------------------------------------
 ##

proc favorites::removeItem {} {
    
    variable savedFavorites

    if {![llength [set favorites [array names savedFavorites]]]} {
	error "Cancelled -- there are no favorites to delete."
    } 
    set p "Delete which Favorites?"
    set favorites [lsort -dictionary $favorites]
    set itemNames [listpick -p $p -l $favorites]
    foreach itemName $itemNames {
	prefs::modified savedFavorites($itemName)
	unset savedFavorites($itemName)
    }
    favorites::rebuildMenu
    if {([llength $itemNames] == 1)} {
	status::msg "The favorite \"[lindex $itemNames 0]\" has been deleted."
    } else {
	status::msg "The selected favorites have been deleted."
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "favorites::bindBindings" --
 # 
 # The user can create non-menu-bindings that could include a prefix such as
 # Control-X, Control-T, Escape, etc.  These need to be bound "manually" by
 # calling this procedure.  If it has been called previously, we need to
 # first remove the earlier bindings in case they have been changed by the
 # user while editing a Favorite Item.
 # 
 # --------------------------------------------------------------------------
 ##

proc favorites::bindBindings {{reBind 1}} {
    
    variable previousBindings
    variable savedFavorites
    
    # [unBind] all previous bindings in case they have changed.
    foreach itemName [array names previousBindings] {
	set script  [list "favorites::menuProc {} \"${itemName}\""]
	set binding $previousBindings($itemName)
	if {![string length $binding]} {
	    continue
	} 
	eval [list unBind] [keys::toBind $binding] $script
    }
    # If we're binding anew, [Bind] and save the info on what we did.
    if {!$reBind} {
        return
    } 
    foreach itemName [array names savedFavorites] {
	set script  [list "favorites::menuProc {} \"${itemName}\""]
	set binding [lindex $savedFavorites($itemName) 3]
	if {![string length $binding]} {
	    continue
	} 
	eval [list Bind] [keys::toBind $binding] $script
	set previousBindings($itemName) $binding
    }
    return
}

# ===========================================================================
#
# ×××× ------------ ×××× #
# 
# ×××× Version History ×××× #
# 
# modified by  rev    reason
# -------- --- ------ -----------
# 
# 02/26/04 cbu 0.1    Original.  "Other Bindings" options are not offered
#                       because of bug# 1336 in AlphaTcl 8.0b7.
# 02/27/04 cbu 0.2    Added ability to define current window as a Favorite,
#                       as well as any recent files.
#                     CM module is now always in first section.
# 02/27/04 cbu 0.3    Users can also select from recent folders.
#                     To avoid confusion with duplicate window/file tails,
#                       the full paths are now included in the pop-up menus.
# 02/27/04 cbu 0.4    New "Power User" naming convention allowing "*" to
#                       trigger optional behavior for all Item Types.
# 02/29/04 cbu 1.0    Bug 1336 has been fixed in the cvs, so "Other Bindings"
#                       are re-enabled.
# 04/19/04 cbu 1.0.1  This is now in the standard AlphaTcl distribution.
#                     Easier to follow dialog script creation.

# ===========================================================================
# 
# .