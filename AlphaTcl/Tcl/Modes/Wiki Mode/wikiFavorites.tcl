## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "wikiFavorites.tcl"
 #                                          created: 01/27/2006 {11:14:45 AM}
 #                                      last update: 02/09/2006 {03:29:32 PM}
 # Description:
 # 
 # Provides support for "Favorite" pages for defined Wiki Projects.
 # 
 # See the "wikiMode.tcl" file for author, license information.
 # 
 # ==========================================================================
 ##

proc wikiFavorites.tcl {} {}

namespace eval Wiki {}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Favorites Menu ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::buildFavoritesMenu" --
 # 
 # Return the list of "Wiki Menu > Wiki Favorites" items required by the
 # [menu::buildSome] procedure.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::buildFavoritesMenu {} {
    
    set menuList [Wiki::listFavorites 0]
    if {[llength $menuList]} {
	set menuList [lsort -dictionary -unique $menuList]
	lappend menuList "(-)"
    }
    lappend menuList "Add New FavoriteÉ" "Edit FavoriteÉ" "Rename FavoriteÉ" \
      "Delete FavoriteÉ" "Reset FavoritesÉ" "(-)" "Favorites Help"
    
    set menuProc "Wiki::favoritesMenuProc -m -M Wiki"
    return [list "build" $menuList $menuProc]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::postBuildFavorites" --
 # 
 # Dim/enable "Wiki Menu > Wiki Favorites" menu items as necessary.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::postBuildFavorites {} {
    
    variable Favorites
    
    Wiki::currentProject
    
    set dim [expr {([llength $Favorites($project)] > 0)}]
    foreach menuItem [list "Edit ÇFÈ" "Rename ÇFÈ" "Delete ÇFÈ" "Reset ÇFÈs"] {
	regsub -all -- {ÇFÈ} $menuItem {Favorite} menuItem
	append menuItem "É"
	enableMenuItem -m "Wiki Favorites" $menuItem $dim
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::favoritesMenuProc" --
 # 
 # Handle all "Wiki Menu > Wiki Favorites" menu items.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::favoritesMenuProc {menuName menuItem} {
    
    variable Favorites
    
    Wiki::currentProject
    
    switch -- $menuItem {
	"Add New Favorite" {
	    Wiki::newFavorite
	}
	"Edit Favorite" {
	    Wiki::editFavorite
	}
	"Rename Favorite" {
	    Wiki::renameFavorite
	}
	"Delete Favorite" {
	    Wiki::deleteFavorite
	}
	"Reset Favorites" {
	    Wiki::resetFavorites
	}
	"Favorites Help" {
	    help::openGeneral "wikiMenu" "Wiki Favorites"
	}
	default {
	    set idx [Wiki::favoriteIndex $project $menuItem]
	    if {($idx != -1)} {
		Wiki::viewUrl [lindex $Favorites($project) $idx 1]
	    } else {
		error "Cancelled -- could not identify the url\
		  for \"$menuItem\"."
	    }
	}
    }
    return
}

# ===========================================================================
# 
# ×××× Favorites Utilities ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::listFavorites" --
 # 
 # List all defined favorites from the Current Wiki Project.  If "throwError"
 # is "1" then we call [Wiki::postBuildFavorites] to dim appropriate menu
 # items and an error is thrown.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::listFavorites {{throwError 1}} {
    
    variable Favorites
    
    Wiki::currentProject
    
    set favoriteList [list]
    foreach favorite $Favorites($project) {
	lappend favoriteList [lindex $favorite 0]
    }
    if {![llength $favoriteList] && $throwError} {
	Wiki::postBuildFavorites
	error "Cancelled -- there are no favorites defined\
	  for the \"$project\" project."
    }
    return [lsort -dictionary -unique $favoriteList]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::favoriteIndex" --
 # 
 # Our "Favorites" array contains entries for each project.  Each entry is a 
 # list of two-item lists, with the name and the url of a favorite.  These 
 # two-item lists are not stored alphabetically, but since most UI dialogs 
 # do sort the items it becomes a challenge to locate the original.
 # 
 # This procedure returns the index of a favorite item (pair) by searching 
 # for the name of the favorite in the project's "Favorites" array entry.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::favoriteIndex {project favorite} {
    
    variable Favorites
    
    set indexFound 0
    for {set idx 0} {($idx < [llength $Favorites($project)])} {incr idx} {
        if {([lindex $Favorites($project) $idx 0] eq $favorite)} {
            set indexFound 1
	    break
        }
    }
    if {!$indexFound} {
        return "-1"
    } else {
        return $idx
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::newFavorite" --
 # 
 # Allow the user the add new favorites for the current project, including a
 # name for the menu and its associated url.  There are three different ways
 # this information can be obtained:
 # 
 # (1) Entering the information manually.
 # (2) Using the frontmost window of the user's browser.
 # (3) Using an open WWW Menu window.
 # 
 # We have tests for (2) and (3) to see if they should be offered as options.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::newFavorite {} {
    
    variable Favorites
    variable userChangedProject 0
    
    Wiki::currentProject
    
    set title "Add New Favorite"
    set txt1 "You are about to add a new \"Favorite\" wiki page for the\
      \"$project\" project.  It will appear in the \"Wiki Favorites\" menu\
      whenever \"$project\" is the Current Wiki Project.\r"
    # Determine options.
    set options [list "Enter Values"]
    if {![set noBrowser [catch {url::browserWindow}]]} {
	lappend options "Use Browser Window"
    }
    if {![catch {WWW::listOpenWindows 1} wwwWindows] && [llength $wwwWindows]} {
        lappend options "Use WWW Menu Window"
    }
    # Determine a method for obtaining information.
    if {([llength $options] == 1)} {
	set newMethod "Enter Values"
	append txt1 "\r"
    } else {
	set txt2 "Each favorite has a name that appears in the menu, and a url\
	  that is opened when the menu item is selected. You can enter these\
	  values yourself, or obtain them from other open windows.\r"
	set txt3 "How would you like to create a new favorite?\r"
	set button1 [list \
	  "Help" \
	  "Click this button to open Wiki Favorites help" \
	  "help::openGeneral wikiMenu {Wiki Favorites} ; \
	  set retCode 1 ; set retVal {cancel}" \
	  ]
	set button2 [list \
	  "Change ProjectÉ" \
	  "Click this button to change the project" \
	  "catch {Wiki::changeCurrentProject}" \
	  ]
	if {([llength [Wiki::listProjects 1]] == 1)} {
	    set buttons $button1
	} else {
	    set buttons [concat $button1 $button2]
	}
	set dialogScript [list dialog::make -title $title \
	  -width 425 \
	  -ok "Continue" \
	  -addbuttons $buttons \
	  [list "" \
	  [list "text" $txt1] [list "text" $txt2] [list "text" $txt3] \
	  [list [list "menu" $options] "Options:"] \
	  ]]
	if {[catch {eval $dialogScript} results]} {
	    if {$userChangedProject} {
	        return [Wiki::newFavorite]
	    } else {
	        error "Cancelled."
	    }
	}
	set newMethod [lindex $results 0]
	set txt1 ""
    }
    # Obtain the information using the specified method.
    switch -- $newMethod {
        "Enter Values" {
	    set name ""
	    set url  [Wiki::urlForDialog]
	    append txt1 "After entering a valid name, press the \"Set\" button\
	      to enter the url for the wiki page."
	    if {$noBrowser} {
		append txt1 "\r"
	    } else {
		append txt1 "  You will have the option\
		  to choose the url of the frontmost browser window.\r"
	    }
	    while {1} {
		set button1 [list \
		  "Help" \
		  "Click this button to open Wiki Favorites help" \
		  "help::openGeneral wikiMenu {Wiki Favorites} ; \
		  set retCode 1 ; set retVal {cancel}" \
		  ]
		set button2 [list \
		  "Change ProjectÉ" \
		  "Click this button to change the project" \
		  "catch {Wiki::changeCurrentProject}" \
		  ]
		if {([llength [Wiki::listProjects 1]] == 1)} {
		    set buttons $button1
		} else {
		    set buttons [concat $button1 $button2]
		}
		set dialogScript [list dialog::make -title $title \
		  -width 500 \
		  -ok "Continue" \
		  -addbuttons $buttons \
		  [list "" \
		  [list "text" $txt1] \
		  [list "var"  "New Favorite Name:" $name] \
		  [list "url"  "New Favorite Wiki Page:" $url] \
		  ]]
		if {[catch {eval $dialogScript} results]} {
		    if {$userChangedProject} {
			return [Wiki::newFavorite]
		    } else {
			error "Cancelled."
		    }
		}
		set name [string trim [lindex $results 0]]
		set url  [string trim [lindex $results 1]]
		if {($name eq "")} {
		    alertnote "The name cannot be an empty string!"
		} elseif {($url eq "")} {
		    alertnote "The url cannot be an empty string!"
		} else {
		    break
		}
	    }
        }
        "Use Browser Window" {
	    status::msg [set msg "Obtaining browser's window information É "]
	    if {![catch {url::getBrowserUrlAndName} winInfo] && [llength $winInfo]} {
		status::msg [append msg "finished."]
		set q "The new Favorite you are about to add will be named\
		  \r\r[lindex $winInfo 1]\r\rand will open the url\
		  \r\r[lindex $winInfo 0]\r"
		if {![dialog::yesno -c -n "" -y "Continue" $q]} {
		    error "Cancelled."
		}
		eval Wiki::makeFavorite $winInfo
	    } else {
		dialog::alert "Sorry, but the url and name\
		  of the current browser window could not be obtained.\
		  Check that a browser window is currently opened."
		error "Cancelled."
	    }
	    status::msg ""
        }
        "Use WWW Menu Window" {
	    set p "Choose an open WWW Window:"
	    foreach w $wwwWindows {
		lappend windows [lindex $w 0]
	    }
	    set idx  [listpick -p $p -indices $windows]
	    set name [lindex $wwwWindows $idx 0]
	    set url  [lindex $wwwWindows $idx 1]
            
        }
    }
    # (Menu items don't like slashes. Remove them.)
    regsub -all -- {/} $name {-} name
    # Verify and add the new favorite.
    if {($project ne "") && ($project ne "default")} {
	Wiki::validateUrlForProject $url
    }
    lappend Favorites($project) [list $name $url]
    set Favorites($project) [lsort -unique -index 0 $Favorites($project)]
    prefs::modified Favorites($project)
    menu::buildSome "Wiki Favorites"
    alertnote "A new \"$name\" favorite page has been added to the\
      \"Wiki Favorites\" menu, associated with the \"$project\" project."
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::editFavorite" --
 # 
 # Edit the url of a defined favorite for the Current Wiki Project.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::editFavorite {} {
    
    variable Favorites
    
    Wiki::currentProject
    
    set favoriteList [Wiki::listFavorites 1]
    set p "Edit which favorite?"
    set options  [lsort -dictionary $favoriteList]
    set favorite [listpick -p $p $options]
    set itemIdx  [Wiki::favoriteIndex $project $favorite]
    set oldUrl   [lindex $Favorites($project) $itemIdx 1]
    set newUrl   [dialog::getUrl "" $oldUrl]
    if {($oldUrl eq $newUrl)} {
	status::msg "Nothing changed."
	return
    }
    lset Favorites($project) [list $itemIdx 1] $newUrl
    prefs::modified Favorites($project)
    status::msg "The new url has been saved."
    set q "Would you like to edit another favorite?"
    if {([llength $favoriteList] > 1) && [askyesno $q]} {
	Wiki::editFavorite
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::deleteFavorite" --
 # 
 # Remove a defined favorite from the Current Wiki Project.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::deleteFavorite {} {
    
    variable Favorites
    
    Wiki::currentProject
    
    set favoriteList [Wiki::listFavorites 1]
    set p "Favorite(s) to remove:"
    set options [lsort -dictionary $favoriteList]
    set removeList [listpick -p $p -l $options]
    foreach favorite $removeList {
	set idx [Wiki::favoriteIndex $project $favorite]
	set Favorites($project) [lreplace $Favorites($project) $idx $idx]
    }
    prefs::modified Favorites($project)
    menu::buildSome "Wiki Favorites"
    if {([llength $removeList] == 1)} {
	set msg "The \"[lindex $removeList 0]\" favorite has been removed."
    } else {
	set msg "The \"[join $removeList {, }]\" favorites have been removed."
    }
    status::msg $msg
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::renameFavorite" --
 # 
 # Rename a defined Favorite page from the Current Wiki Project.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::renameFavorite {} {
    
    variable Favorites
    
    Wiki::currentProject
    
    set favoriteList [Wiki::listFavorites 1]
    set p "Rename which favorite?"
    set options [lsort -dictionary $favoriteList]
    set oldName [listpick -p $p $options]
    while {1} {
	set newName [prompt "Rename \"$oldName\" to:" $oldName]
	if {([string trim $newName] eq "")} {
	    alertnote "The name cannot be an empty string!"
	    continue
	} else {
	    break
	}
    }
    if {($oldName eq $newName)} {
	status::msg "No changes."
	return
    }
    set idx [Wiki::favoriteIndex $project $oldName]
    lset Favorites($project) [list $idx 0] $newName
    prefs::modified Favorites($project)
    menu::buildSome "Wiki Favorites"
    status::msg "\"$oldName\" has been renamed to \"$newName\"."
    set q "Would you like to rename another favorite?"
    if {([llength $favoriteList] > 1) && [askyesno $q]} {
	Wiki::renameFavorite
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::resetFavorites" --
 # 
 # Delete the contents of the "Wiki Favourite Pages" menu item. This menu 
 # item is not displayed when it is empty.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::resetFavorites {} {
    
    variable Favorites
    
    Wiki::currentProject
    
    if {![llength $Favorites($project)]} {
	Wiki::postBuildFavorites
	error "Cancelled -- there are no favorites to remove."
    }
    set q "You are about to remove all \"favorite\" pages associated\
      with your $project project.  Do you want to continue?"
    if {![askyesno $q]} {
	error "Cancelled."
    }
    set Favorites($project) [list]
    prefs::modified Favorites($project)
    menu::buildSome "Wiki Favorites" $project
    return
}

# ===========================================================================
# 
# .