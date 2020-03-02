## -*-Tcl-*-  (nowrap)
## 
 # This file : userMenu.tcl
 # Created : 2000-08-06 5:53:03
 # Last modification : 2004-01-27 07:19:03
 # Author : Bernard Desgraupes
 # e-mail : <bdesgraupes@easyconnect.fr>
 # Web-page : <http://webperso.easyconnect.fr/bdesgraupes/>
 # Description :
 #      This is a menu/feature for Alpha. It allows you to store
 #      and invoke your personal procedures in a special menu.
 # 
 # (c) Copyright : Bernard Desgraupes 2000-2004
 # 
 ##
# ###############################################################################
# 08/06/2000  0.1 Created the feature.
# 10/03/2000  0.2 Added menu bindings handling.
# 14/10/2000  0.3 Added item to refresh bindings (just in case…).
# 09/04/2001  0.4 Corrected a bug in "Modify Item" when cancel picklist.
# 08/18/2001  0.5 Minor fixes. Renamed global variables.
# 27/01/2004  0.6 Complete rewriting. 
# 15/04/2004  0.7 Minor update for AlphaTcl 8.x
# ###############################################################################


alpha::menu userMenu 0.7 global "•401" {
    ensureset userMenuItems ""
    package::addPrefsDialog userMenu
} {userMenu} {
    unset -nocomplain usr_params usr_procs usr_bindings
} uninstall this-file maintainer {
    "Bernard Desgraupes" <bdesgraupes@easyconnect.fr> 
} description {
    Allows you to invoke personal AlphaTcl procedures directly from the menu
    or pressing user-defined Keyboard Shortcuts
} help {
    This is a menu/feature for Alpha.  It allows you to store personal
    procedures in a special menu and to link them easily to a menu item.
    These procedures must have been defined somewhere and loaded (in the
    prefs.tcl file for instance).
    
    How to use it: 
    Once it is installed and activated (in 'Config --> Global Setup -->
    Features...'), you have a new menu displaying a user icon with four
    items: <Add item...>, <Modify Item...>, <Remove Item...> and <Refresh
    Bindings>.

    If you choose <Add Item...>, a dialog window asks you to specify the
    name of the item you want to add to the menu and the name of the
    corresponding procedure, ie the proc which will be triggered by this
    item.  For instance, suppose you have defined a proc called
    Conv::HexNum to convert hexadecimal numbers and you want to have a menu
    item called "Convert Hex Numbers" in the User Menu: all you have to do
    is to enter ConvertHexNumbers in the first field and Conv::HexNum in
    the second field of the "Add Item" window.

    Note that there is no space in ConvertHexNumbers: this is because Alpha
    automatically inserts a space before any uppercase letter in the name
    of a menu item.
} requirements {
    alpha::package require AlphaTcl 8.0d7
}

namespace eval usr {}


# # # User menu preferences # # #

# To sort the items alphabetically in the User menu.
newPref flag sortAlphabetically 0 userMenu usr::rebuildMenu


# # # Initialisation of global variables # # #

set usr_params(topnames) {}
set usr_params(topitems) {}
set usr_params(bottomitems) [list "(-" "addItem…" "modifyItem…" \
  "<E<SremoveItem…" "<S<IresetMenu" "refreshBindings"]
set usr_params(currname) ""
set usr_params(currproc) ""
set usr_params(currbinding) ""
set usr_procs(addItem) "usr::addItem"
set usr_procs(modifyItem) usr::modifyItem
set usr_procs(removeItem) usr::removeItem
set usr_procs(resetMenu) usr::resetMenu
set usr_procs(refreshBindings) usr::refreshBindings
# Rebuild the arrays from the global variable.
if {[llength $userMenuItems]} {
    foreach f $userMenuItems {
	lappend usr_params(topitems) [lindex $f 0]
	regsub -all "<\\w" [lindex $f 0] "" thename
	regsub -all "/\\w" $thename "" thename
	lappend usr_params(topnames) $thename
	if {[regexp {(<\w|/\w)+} [lindex $f 0] thebinding]} {
	    set usr_bindings($thename) $thebinding
	} else {
	    set usr_bindings($thename) ""
	}
	set res [keys::toBind $usr_bindings($thename)]
	if {$res != ""} {
	    catch {eval [concat Bind $res $usr_procs($thename)]}
	}
	set usr_procs($thename) [lindex $f 1]
    }
} 
unset -nocomplain thename thebinding

proc userMenu {} {}


# # # Menu declarations # # #

menu::buildProc userMenu menu::buildUserMenu


# # # Building procedures # # #

proc menu::buildUserMenu {} {
    global userMenu usr_params usr_bindings userMenumodeVars
    if {$userMenumodeVars(sortAlphabetically)} {
	set toplist [lsort -dictionary $usr_params(topnames)]
    } else {
	set toplist $usr_params(topnames)
    }
    set top ""
    foreach itm $toplist {
	if {[info exists usr_bindings($itm)]} {
	    lappend top "$usr_bindings($itm)$itm"
	} else {
	    lappend top "$itm"
	}
    }
    return [list build [concat $top $usr_params(bottomitems)] \
      usr::userMenuProc {} $userMenu]
}


# # # Menu items procs # # #

proc usr::userMenuProc {menu item} {
    global usr_procs
    eval $usr_procs($item)
}


# # # Building the menu # # #

menu::buildSome userMenu 


# # # Items managing procs # # #

proc usr::userItemDialog {action} {
    global usr_params
    set usr_params(currbinding) ""
    set title "$action User Menu Item"
    set txt1 "Menu Item Name:"
    set txt2 "Menu Item Proc:"
    set txt3 "Menu Shortcut:"
    set buttonScript {
	if {![catch {procs::pick} newProc]} {
	    eval [list dialog::valSet $dial [list NAME] $newProc]
	} 
    }
    regsub -- {NAME} $buttonScript ",$txt2" buttonScript
    set button1 [list \
      "Browse Procs..." \
      "Click here to review currently defined procedures" \
      $buttonScript]
    set dialogScript [list dialog::make -title $title \
      -addbuttons $button1 \
      [list "" \
      [list var $txt1 $usr_params(currname)] \
      [list var $txt2 $usr_params(currproc)] \
      [list menubinding $txt3 $usr_params(currbinding)] \
      ]]
    if {[catch {eval $dialogScript} values]} {
	return 0
    }
    set usr_params(currname)    [lindex $values 0]
    set usr_params(currproc)    [lindex $values 1]
    set usr_params(currbinding) [lindex $values 2]
    foreach item [list name proc] {
	if {![string length $usr_params(curr${item})]} {
	    set Item [string totitle $item]
	    alertnote "The \"Menu $Item\" field cannot be empty."
	    return [usr::userItemDialog $action]
	}
    }
    return 1
}

proc usr::addItem {} {
    global usr_params usr_procs usr_bindings
    set usr_params(currname) ""
    set usr_params(currproc) ""
    set usr_params(currbinding) ""
    if {![usr::userItemDialog Add]} {
        return
    } 
    # Install new item
    regsub -all " " $usr_params(currname) "" itm
    set itm [string trimright $itm "…"]
    # Set the arrays
    set usr_procs($itm) $usr_params(currproc)
    set usr_bindings($itm) $usr_params(currbinding)
    set res [keys::toBind $usr_bindings($itm)]
    if {$res != ""} {
	catch {eval [concat Bind $res $usr_procs($itm)]}
    }
    # Update the menu lists
    lappend usr_params(topitems) "$usr_params(currbinding)$usr_params(currname)"
    lappend usr_params(topnames) "$usr_params(currname)"
    usr::rebuildMenu
    status::msg "Added item '$usr_params(currname)' to User menu"
}


proc usr::modifyItem {} {
    global usr_params usr_procs usr_bindings
    set thename [usr::pickItem modify]
    if {$thename == ""} {return} 
    regsub -all " " $thename "" olditem
    set olditem [string trimright $olditem "…"]
    set usr_params(currname) $olditem
    set usr_params(currproc) $usr_procs($olditem)
    set usr_params(currbinding) $usr_bindings($olditem)
    if {![usr::userItemDialog Modify]} {
        return
    }
    # Uninstall old item
    unset -nocomplain usr_procs($olditem) usr_bindings($olditem)
    set idx [lsearch $usr_params(topnames) $olditem]
    set usr_params(topitems) [lreplace $usr_params(topitems) $idx $idx]
    set usr_params(topnames) [lreplace $usr_params(topnames) $idx $idx]
    # Install new item
    regsub -all " " $usr_params(currname) "" newitem
    set newitem [string trimright $newitem "…"]
    # Set the arrays
    set usr_procs($newitem) $usr_params(currproc)
    set usr_bindings($newitem) $usr_params(currbinding)
    set res [keys::toBind $usr_bindings($newitem)]
    if {$res != ""} {
	catch {eval [concat Bind $res $usr_procs($newitem)]}
    }
    # Update the menu lists
    lappend usr_params(topitems) "$usr_params(currbinding)$usr_params(currname)"
    lappend usr_params(topnames) "$usr_params(currname)"
    usr::rebuildMenu
    status::msg "Modified item '$usr_params(currname)' in User menu"
}


proc usr::removeItem {} {
    global usr_params usr_procs usr_bindings
    set thename [usr::pickItem remove]
    if {$thename == ""} {return} 
    regsub -all " " $thename "" olditem
    set olditem [string trimright $olditem "…"]
    unset -nocomplain usr_procs($olditem) usr_bindings($olditem)
    set idx [lsearch $usr_params(topnames) $olditem]
    set usr_params(topitems) [lreplace $usr_params(topitems) $idx $idx]
    set usr_params(topnames) [lreplace $usr_params(topnames) $idx $idx]
    usr::rebuildMenu
    status::msg "Removed item '$olditem' from User menu"
}


proc usr::pickItem {action} {
    global usr_params 
    if {$usr_params(topnames)==""} {
	alertnote "No item to $action."
	return ""
    } 
    if {[catch {listpick -p "Item to ${action}:" \
      [lsort -dictionary $usr_params(topnames)]} itm]} {return ""}
    return $itm
}


# Rebuild the global variable from the arrays.
proc usr::updateGlobalVar {} {
    global usr_params usr_procs userMenuItems
    set userMenuItems ""
    if {[llength $usr_params(topitems)]} {
	foreach f $usr_params(topitems) {
	    regsub -all "<\\w" $f "" itm
	    regsub -all "/\\w" $itm "" itm
	    lappend userMenuItems [list $f $usr_procs($itm)]
	}
    } 
    prefs::modified userMenuItems
}


proc usr::rebuildMenu { {name ""} } {
    menu::buildSome userMenu 
    usr::updateGlobalVar
}


proc usr::resetMenu {} {
    global usr_params userMenuItems
    # Call this before resetting the lists
    usr::unloadBindings
    # Reset the lists
    set usr_params(topitems) ""
    set usr_params(topnames) ""
    set userMenuItems ""
    usr::rebuildMenu
}


# Proc to unbind the keybindings.
proc usr::unloadBindings {} {
    usr::doBindings unbind
}


# Restore the user defined keybindings associated to menu items. It happens
# that they are overridden later by other packages.
proc usr::refreshBindings {} {
    usr::doBindings Bind
    status::msg "User bindings restored"
}


# Proc to bind or unbind the current user defined bindings.
proc usr::doBindings {what} {
    global usr_params usr_procs usr_bindings
    foreach f $usr_params(topnames) {
	set res [keys::toBind $usr_bindings($f)]
	if {$res!=""} {
	    catch {eval [concat $what $res $usr_procs($f)]}
	}
    }
}