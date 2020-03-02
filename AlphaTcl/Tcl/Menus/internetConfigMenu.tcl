## -*-Tcl-*-  (nowrap)
 # ==========================================================================
 # AlphaTcl support packages
 # 
 # FILE: "internetConfigMenu.tcl"
 #  
 #                                          created: 04/06/1998 {11:24:32 am}
 #                                      last update: 03/21/2006 {01:51:37 PM}
 #  
 # Original by Pete Keheler, I believe.
 #  
 # Updated by Craig Barton Upright
 #  
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 #  
 # Copyright (c) 1998-2006  Pete Keheler, Vince Darley, Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

alpha::menu internetConfigMenu 1.1 global "¥139" {
    # Initialization script.
    internetConfigMenu
} {
    # Activation script.
    hook::register   requireOpenWindowsHook [list $internetConfigMenu windowToBrowser] 1
} {
    # Deactivation script.
    hook::deregister requireOpenWindowsHook [list $internetConfigMenu windowToBrowser] 1
} preinit {
    # Contextual Menu module.  Placed here so that it can be turned on even
    # if this package isn't formally activated.
    
    # Includes items to perform internet searches, sending the current 
    # selected text to a search engine using your local browser
    newPref f "wwwSearch Menu" 0 contextualMenu
    menu::buildProc "wwwSearch " {ic::buildSearchMenu "contextual"}
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} uninstall {
    this-file 
} description {
    Provides easy access to your OS Internet applications
} help {
    file "Internet Config"
}

proc internetConfigMenu.tcl {} {}

proc internetConfigMenu {} {}

namespace eval ic {}

menu::buildProc internetConfigMenu ic::buildMenu 
menu::buildProc savedUrls          ic::buildUrlMenu 
menu::buildProc wwwSearch          ic::buildSearchMenu 

# Turn this item on to automatically surround search terms with double quotes
# before passing them on to the search engine||Turn this item off to stop the
# automatic surrounding of search terms with double quotes
newPref flag quoteSearchTerms 1 wwwSearch
# Turn this item on to bypass the search text dialog if there is a currently
# highighted selection when using the "Www Search" menu items||Turn this item
# off to use any currently highlighted selection as the default text in the
# "Www Search" menu items dialog
newPref flag useHiliteForSearch 0 wwwSearch
# This is the url for search engine number 1.  Search terms will be appended
# to the end, so it must include the special cgi pointers.
newPref url searchUrl1 {http://www.google.com/search?q=} wwwSearch
# This is the url for search engine number 2.
newPref url searchUrl2 {http://search.yahoo.com/bin/query?p==} wwwSearch
# This is the url for search engine number 3.
newPref url searchUrl3 {http://search.metacrawler.com/crawler?general=} wwwSearch
# This is the url for search engine number 4.
newPref url searchUrl4 {http://northernlight.com/nlquery.fcg?si=&cb=0&qr=} wwwSearch

prefs::renameOld "lastFinger" "ic::LastFinger"
prefs::renameOld "lastTelnet" "ic::LastTelnet"

ensureset "ic::LastFinger" [list]
ensureset "ic::LastTelnet" [list]

# ×××× Bindings ×××× #

set ic::MenuNames [list "mainMenu" "urlUtils" "savedUrls" \
  "wwwSearch" "internetConfig"]

array set menu::items {
    "mainMenu"       {fingerÉ telnetÉ urlToBrowserÉ windowToBrowser}
    "wwwSearch"      {wwwSearch1 wwwSearch2 wwwSearch3 wwwSearch4}
    "urlUtils"       {"View Saved UrlÉ" "Save New UrlÉ" "Edit Saved UrlÉ"
      "Rename Saved UrlÉ" "Delete Saved UrlÉ" "Display Saved Urls"
    }
}

array set ic::MenuKeysDefault {
    "View Saved UrlÉ" {/'<I<O}
}

proc ic::assignMenuBindings {{title "Select a menu:"} {includeFinish "0"}} {

    global ic::MenuNames ic::MenuKeysDefault ic::MenuKeysUser \
      menu::items savedUrls
    
    if {[info exists savedUrls]} {
	set menu::items(savedUrls) $savedUrls
    } else {
        set menu::items(savedUrls) [list]
    }

    set menuNames [set ic::MenuNames]
    if {$includeFinish} {set menuNames [concat [list "(Finish)"] $menuNames]}
    if {[catch {listpick -p $title $menuNames} menuName]} {
	error "cancel"
    } elseif {$menuName == "(Finish)"} {
	status::msg "The new bindings have been added to the IC menu."
	return -code return
    }
    foreach menuItem [set menu::items($menuName)] {
	regsub {^([!<].)+} $menuItem "" menuItem
	if {[regexp {(^\(-\))|/} $menuItem]} {
	    # Either a divider, or the item has its own default binding
	    # which can't be changed.
	    continue
	} elseif {[info exists ic::MenuKeysUser($menuItem)]} {
	    set menuBindings($menuItem) [set ic::MenuKeysUser($menuItem)]
	} elseif {[info exists ic::MenuKeysDefault($menuItem)]} {
	    set menuBindings($menuItem) [set ic::MenuKeysDefault($menuItem)]
	} else {
	    set menuBindings($menuItem) ""
	}
    }
    set title "'[string trim $menuName]'  key bindings É"
    catch {dialog::arrayBindings $title menuBindings 1}

    foreach menuItem [set menu::items($menuName)] {
	if {![info exists menuBindings($menuItem)]} {continue}
	set newBinding $menuBindings($menuItem)
	# Check to see if this is different from the default.
	if {[info exists ic::MenuKeysDefault($menuItem)]} {
	    set defaultBinding [set ic::MenuKeysDefault($menuItem)]
	} else {
	    set defaultBinding ""
	}
	if {$newBinding == "" && [info exists ic::MenuKeysUser($menuItem)]} {
	    prefs::modified ic::MenuKeysUser($menuItem)
	    unset ic::MenuKeysUser($menuItem)
	} elseif {$newBinding != $defaultBinding} {
	    prefs::modified ic::MenuKeysUser($menuItem)
	    set ic::MenuKeysUser($menuItem) $newBinding
	}
    }
    ic::rebuildMenu
    # Now offer the list pick again.
    set title "Select another menu, or 'Finish'"
    if {[catch {ic::assignMenuBindings $title 1}]} {
	status::msg "New bindings have been assigned, and appear in the IC menus."
    } 
}

# ×××× Internet Config Menu ×××× #

proc ic::buildMenu {{which "menubar"}} {
    
    global internetConfigMenu menu::items ic::MenuKeysDefault ic::MenuKeysUser
    
    # First determine the items available for the 'Internet Config' submenu.
    if {[catch {tclAE::build::resultData 'MACS' core getd rtyp TEXT ---- \
      "obj {form:prop, want:type(prop), seld:type(extn), from:'null'()}"} ic]} {
        set dim "\("
    } elseif {![file exists $ic]} {
        set dim "\("
    } else {
        set dim ""
    }
    set icList [list "${dim}openInternetConfig" "internetConfigHelp" \
      "assignMenuBindingsÉ" "(-)" ]
    array set menuItemPref {
	"webBrowser"   {helper¥http}
	"mailClient"   {helper¥mailto}
	"ftpClient"    {helper¥ftp}
	"gopherClient" {helper¥gopher}
	"telnetClient" {helper¥telnet}
	"newsClient"   {helper¥news}
    }
    if {![catch {icGetPref all} allPrefs]} {
	set allPrefs [string tolower $allPrefs]
	# A bug in Alpha8 with high bit chars
	regsub -all ´ $allPrefs ¥ allPrefs
    } else {
	set allPrefs [list]
    }
    set clients [list "webBrowser" "mailClient" "ftpClient" \
      "gopherClient" "telnetClient" "newsClient"]
    set menu::items(internetConfig) [list]
    foreach client $clients {
	if {[lcontains allPrefs $menuItemPref($client)]} {
	    set dim ""
	    lappend menu::items(internetConfig) $client
	} else {
	    set dim "\("
	}
	if {[info exists ic::MenuKeysDefault($client)]} {
	    set key [set ic::MenuKeysDefault($client)]
	} elseif {[info exists ic::MenuKeysUser($client)]} {
	    set key [set ic::MenuKeysUser($client)]
	} else {
	    set key ""
	}
	lappend icList ${dim}${key}${client}
    }
    # Now create the menu.
    set menuList [list \
      "Menu -n savedUrls {}" \
      "Menu -n wwwSearch {}" \
      "Menu -n internetConfig -p ic::menuProc [list $icList]" ]
    lappend menuList "(-)" 
    foreach menuItem [list "fingerÉ" "telnetÉ" "urlToBrowserÉ" "windowToBrowser"] {
	if {[info exists ic::MenuKeysDefault($menuItem)]} {
	    set key [set ic::MenuKeysDefault($menuItem)]
	} elseif {[info exists ic::MenuKeysUser($menuItem)]} {
	    set key [set ic::MenuKeysUser($menuItem)]
	} else {
	    set key ""
	}
	lappend menuList ${key}${menuItem}
    }
    set subMenus [list savedUrls wwwSearch]
    return [list build  $menuList "ic::menuProc" $subMenus $internetConfigMenu]
}

proc ic::buildUrlMenu {} {

    global urlMenu savedUrls menu::items ic::MenuKeysDefault ic::MenuKeysUser

    if {[llength [set urls [lsort -dictionary [array names savedUrls]]]]} {
	set dim ""
    } else {
        set dim "\("
    }
    foreach menuItem [set menu::items(urlUtils)] {
	if {[info exists ic::MenuKeysDefault($menuItem)]} {
	    set key [set ic::MenuKeysDefault($menuItem)]
	} elseif {[info exists ic::MenuKeysUser($menuItem)]} {
	    set key [set ic::MenuKeysUser($menuItem)]
	} else {
	    set key ""
	}
	if {$menuItem == "Save New UrlÉ"} {
	    lappend menuList ${key}${menuItem}
	} else {
	    lappend menuList ${dim}${key}${menuItem}
	}
    }
    Menu -m -n savedUrls -p ic::urlProc $menuList
    if {![string length $dim]} {
        addMenuItem -m savedUrls "(-)"
	foreach url $urls {
	    if {[info exists ic::MenuKeysDefault($url)]} {
		set key [set ic::MenuKeysDefault($url)]
	    } elseif {[info exists ic::MenuKeysUser($url)]} {
		set key [set ic::MenuKeysUser($url)]
	    } else {
		set key ""
	    }
	    addMenuItem -m -l "  " savedUrls ${key}${url}
	}
    } 
}

proc ic::buildSearchMenu {{which "menubar"}} {
    
    global wwwSearchmodeVars ic::MenuKeysDefault ic::MenuKeysUser
    
    switch -- $which {
	"menubar" {set dots "É"}
	"contextual" {
	    global alpha::CMArgs
	    set pos1 [lindex ${alpha::CMArgs} 1]
	    set pos2 [lindex ${alpha::CMArgs} 2]
	    if {[pos::diff $pos1 $pos2]} {
		set dots ""
	    } elseif {[string length [lindex [contextualMenu::clickWord] 0]]} {
		set dots ""
	    } else {
	        set dots "É"
	    }
	}
	default {error "Unknown menu: $which"}
    }
    foreach engine [list 1 2 3 4] {
	set key ""
	if {$which == "menubar"} {
	    if {[info exists ic::MenuKeysDefault(wwwSearch$engine)]} {
		set key [set ic::MenuKeysDefault(wwwSearch$engine)]
	    } elseif {[info exists ic::MenuKeysUser(wwwSearch$engine)]} {
		set key [set ic::MenuKeysUser(wwwSearch$engine)]
	    }
	} 
	if {[string length $wwwSearchmodeVars(searchUrl${engine})]} {
	    lappend menuList "${key}wwwSearch ${engine}${dots}"
	} else {
	    lappend menuList "(${key}wwwSearch ${engine}${dots}"
	}
    }
    if {$wwwSearchmodeVars(quoteSearchTerms)} {
        lappend menuList "(-)" "!¥quoteSearchTerms" "wwwSearchPrefsÉ"
    } else {
	lappend menuList "(-)"   "quoteSearchTerms" "wwwSearchPrefsÉ"
    }
    return [list build $menuList {ic::searchMenuProc}]
}

proc ic::rebuildMenu {args} {
    
    if {![llength $args]} {
        set args internetConfigMenu
    } 
    foreach arg $args {menu::buildSome $arg}
}

# Build the menu.
ic::rebuildMenu

proc ic::menuProc {menuName itemName} {
    
    switch -- $itemName {
	"webBrowser"   {set icPref {helper¥http}}
	"mailClient"   {set icPref {helper¥mailto}}
	"ftpClient"    {set icPref {helper¥ftp}}
	"gopherClient" {set icPref {helper¥gopher}}
	"telnetClient" {set icPref {helper¥telnet}}
	"newsClient"   {set icPref {helper¥news}}
    }
    if {[info exists icPref]} {
        if {![catch {icGetPref -t 1 $icPref} icApp]} {
	    launch -f $icApp
	} else {
	    alertnote "Could not get your [quote::Prettify $itemName] from Internet Config"
	    # Check if IC extension is installed.
	    if {![file exists "[tclAE::build::resultData 'MACS' core getd rtyp TEXT ---- "obj {form:prop, want:type(prop), seld:type(extn), from:'null'()}"]Internet Config Extension"]} {
		alertnote "Despite what Internet Config says, you should reboot after using IC for the first time."
		icOpen
	    }
	}
	return
    } 
    switch -- $itemName {
	"openInternetConfig" {icOpen}
	"internetConfigHelp" {package::helpWindow "internetConfigMenu"}
	"finger" {finger}
	"telnet" {telnet}
	"urlToBrowser" {
	    set p "Please type your url, or use one of the buttons below"
	    if {[catch {getSelect} url]} {set url ""}
	    if {[catch {dialog::getUrl $p $url} url]} {
		error "cancel"
	    } else {
		url::execute $url
	    }
	}
	"windowToBrowser" {
	    if {![file isfile [win::StripCount [win::Current]]]} {
	        error "Cancelled -- this window doesn't exist as a file."
	    } 
	    loadAMode HTML
	    html::SendWindow
	}
	default {ic::$itemName}
    }
}

# http://www.cs.umd.edu/~keleher/localHome.html
proc ic::urlProc {menuName itemName} {

    global savedUrls
    set urls [lsort -dictionary [array names savedUrls]]
    
    switch -- $itemName {
	"View Saved Url" {
	    if {[catch {listpick -p "View which url?" $urls} url]} {
		error "cancel"
	    } else {
		urlView $savedUrls($url)
	    }
	}
	"Save New Url" {
	    set p "Please type your url, or use one of the buttons below"
	    if {[catch {getSelect} url]} {set url ""}
	    if {[catch {dialog::getUrl $p $url} url]} {
		error "cancel"
	    } else {
	        status::msg $url
	    }
	    set name ""
	    set p    "Name for this url:"
	    while {1} {
	        if {[catch {prompt $p $name} name]} {
		    error "cancel"
	        } elseif {![string length $name]} {
	            status::msg "Nothing was entered."
	        } elseif {[info exists savedUrls($name)]} {
	            alertnote "'$name' is already used."
		    set p "Try another name"
	        } else {
	            break
	        }
	    }
	    set savedUrls($name) $url
	    prefs::modified savedUrls($name)
	    ic::rebuildMenu "urls"
	    status::msg "'$name' has been saved in the Urls menu."
	}
	"Edit Saved Url" {
	    set p1 "Edit which url?"
	    set p2 "Please type your url, or use one of the buttons below"
	    while {1} {
		if {[catch {listpick -p $p1 $urls} name]} {
		    error "cancel"
		} elseif {[catch {dialog::getUrl $p2 $savedUrls($name)} url]} {
		    error "cancel"
		} else {
		    set savedUrls($name) $url
		    prefs::modified savedUrls($name)
		    status::msg "The new setting for '$name' has been saved."
		    set p1 "Choose another to edit, or cancel"
		}
	    }
	}
	"Rename Saved Url" {
	    set p1 "Rename which url?"
	    while {1} {
		if {[catch {listpick -p $p1 $urls} name]} {
		    error "cancel"
		}
		set newName ""
		set p2 "New name for '$name'"
		while {![string length $newName]} {
		    if {[catch {prompt $p2 $name} newName]} {
			error "cancel"
		    } elseif {![string length $newName]} {
			status::msg "Nothing was entered."
		    } elseif {[lcontains urls $newName]} {
		        alertnote "That name is already being used."
			set newName ""
			set p2 "Try another name"
		    } 
		}
		set savedUrls($newName) $savedUrls($name)
		prefs::modified savedUrls($name)
		unset savedUrls($name)
		ic::rebuildMenu "savedUrls"
		status::msg "'$name' has been renamed to '$newName'."
		set p1 "Choose another to rename, or cancel"
		set urls [lsort -dictionary [array name savedUrls]]
	    }
	}
	"Delete Saved Url" {
	    if {[catch {listpick -p "Remove which urls?" -l $urls} results]} {
		error "cancel"
	    } 
	    foreach url $results {
		prefs::modified savedUrls($url)
		unset savedUrls($url)
	    }
	    ic::rebuildMenu "urls"
	    status::msg "The urls have been removed."
	}
	"Display Saved Urls" {
	    if {![llength $urls]} {
		# This item should have been dimmed.
		error "Cancelled -- there are no saved urls to display."
		ic::rebuildMenu "urls"
	    }
	    set lines {}
	    foreach name $urls {
		append lines "$name\r    <$savedUrls($name)>\r\r"
	    }
	    new -n {* Saved URLs *} -m Text -text $lines
	    goto [minPos]
	    shrinkWindow
	    help::hyperiseUrls
	    refresh
	    setWinInfo dirty 0
	}
	default {urlView $savedUrls($itemName)}
    }
}

proc ic::searchMenuProc {menuName itemName} {
    
    global wwwSearchmodeVars
    
    if {$itemName == "quoteSearchTerms"} {
        set wwwSearchmodeVars($itemName) \
	  [expr {$wwwSearchmodeVars($itemName) ? 0 : 1}]
	prefs::modified wwwSearchmodeVars($itemName)
	ic::rebuildMenu "wwwSearch"
	if {$wwwSearchmodeVars($itemName)} {
	    status::msg "The '$itemName' preference is now on."
	} else {
	    status::msg "The '$itemName' preference is now off."
	}
	return
    } elseif {$itemName == "wwwSearchPrefs"} {
	prefs::dialogs::packagePrefs "wwwSearch"
	return
    }
    # Determine what default we might have to work with.
    switch -- $menuName {
	"" - "wwwSearch"  {
	    set searchText ""
	}
	"wwwSearch " {
	    global alpha::CMArgs
	    set pos0 [lindex ${alpha::CMArgs} 0]
	    set pos1 [lindex ${alpha::CMArgs} 1]
	    set pos2 [lindex ${alpha::CMArgs} 2]
	    set pos3 [getPos]
	    set pos4 [selEnd]
	    if {[pos::diff $pos1 $pos2]} {
		set searchText [getText $pos1 $pos2]
	    } elseif {[regexp {[a-zA-Z]} [getText $pos0 [pos::nextChar $pos0]]]} {
		goto $pos0
		set searchText [eval getText [text::surroundingWord]]
		selectText $pos3 $pos4
	    } elseif {[regexp {[a-zA-Z]} [getText [pos::prevChar $pos0] $pos0]]} {
		set selection [selectLimits]
		goto $pos0
		set searchText [eval getText [text::surroundingWord]]
		selectText $pos3 $pos4
	    } else {
		set searchText ""
	    }
	}
	default {error "Unknown menu: $menuName"}
    }
    if {![string length $searchText]} {
	# Use any current selection for default text.
	if {[catch {getSelect} dT]} {set dT ""}
	if {[string length $dT] && $wwwSearchmodeVars(useHiliteForSearch)} {
	    set searchText $dT
	} elseif {[catch {prompt "WWW Search for" $dT} searchText]} {
	    error "cancel"
        } elseif {![string length $searchText]} {
	    error "cancel"
        }
    }
    if {$wwwSearchmodeVars(quoteSearchTerms)} {
	regsub -all {"} $searchText {} searchText
        set searchText "\"$searchText\""
    } 
    regsub {wwwSearch *} $itemName {} engine
    urlView $wwwSearchmodeVars(searchUrl${engine})[quote::Url ${searchText}]
}

proc finger {{whom ""}} {

    global ic::LastFinger

    set p "Who do you want to finger?"
    set d [lindex [set ic::LastFinger] end]
    if {[catch {app::launchBack {'PnLF'}}]} {
	alertnote "You must install Peter Lewis's \"Finger\" program."
	return
    }
    if {![string length $whom]} {
	if {[llength [set ic::LastFinger]] < 2} {
	    if {[catch {prompt $p $d} whom]} {
		error "cancel"
	    } elseif {![string length $whom]} {
		error "Cancelled -- nothing was entered."
	    }
	} else {
	    set prevList [concat "previous:" \
	      [lsort -dictionary [set ic::LastFinger]] \
	      [list "-" "Reset List"]]
	    if {[catch {eval [list prompt $p $d] $prevList} whom]} {
		error "cancel"
	    } elseif {![string length $whom]} {
		error "Cancelled -- nothing was entered."
	    }
	}
    } 
    if {$whom == "Reset List"} {
        set ic::LastFinger [list]
	status::msg "The list of previous fingers has been reset."
	finger
    } else {
	lappend ic::LastFinger $whom
	set ic::LastFinger [lsort -dictionary -unique [set ic::LastFinger]]
	prefs::modified lastFinger
	watchCursor
	# Probably should use tclAE proc here.
	set text [tclAE::send -p -r 'PnLF' GURL FURL ---- "Ò$whomÓ"]
	new -n "* $lastFinger *"
	if {[regexp {Ò(.*)Ó} $text dummy text]} {
	    insertText $text
	    shrinkWindow
	    goto [minPos]
	    winReadOnly
	}
    }
}

proc telnet {{where ""}} {

    global ic::LastTelnet telnetSig

    app::launchAnyOfThese [list rlfT NCSA NIFt] telnetSig "Please locate your Telnet application:"
    
    if {![string length $where]} {
	set p "Open telnet connection toÉ"
	set d [lindex [set ic::LastTelnet] end]
	if {[llength [set ic::LastTelnet]] < 2} {
	    if {[catch {prompt $p $d} where]} {
		error "cancel"
	    } elseif {![string length $where]} {
		error "Cancelled -- nothing was entered."
	    }
	} else {
	    set prevList [concat "previous:" \
	      [lsort -dictionary [set ic::LastTelnet]] \
	      [list "-" "Reset List"]]
	    if {[catch {eval [list prompt $p $d] $prevList} where]} {
		error "cancel"
	    } elseif {![string length $where]} {
		error "Cancelled -- nothing was entered."
	    }
	}
    } 
    if {$where == "Reset List"} {
	set ic::LastTelnet [list]
	status::msg "The list of previous sites has been reset."
	telnet
    } else {
	lappend ic::LastTelnet $where
	set ic::LastTelnet [lunique [set ic::LastTelnet]]
	prefs::modified ic::LastTelnet
	watchCursor
	# Probably should use tclAE proc here.
	tclAE::send -p -r '$telnetSig' GURL GURL ---- "Òtelnet://$whereÓ"
	switchTo '$telnetSig'
    }
}

# ===========================================================================
#
# ×××× ------------ ×××× #
# 
# ×××× Version History ×××× #
# 
#  modified by  rev    reason
#  -------- --- ------ -----------
#  ??/??/?? ??? 0.x    Original, various updates with improved AlphaTcl.
#  06/05/02 cbu 1.0    Updated for Alphatk.
#                      Added "Www Search" submenu.
#                      Added CM module, doesn't require menu being active.
#                      Minor work-around for Alpha8 high bit issue.
#                      Better control over telnet, finger history lists.
#  10/07/02 cbu 1.1    User can define menu bindings.
#                      Hilite can be used automatically for searching. 
# 

# ===========================================================================
# 
# .