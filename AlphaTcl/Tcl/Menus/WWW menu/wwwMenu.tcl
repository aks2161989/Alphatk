## -*-Tcl-*-
 # ==========================================================================
 # WWW Menu - an extension package for Alpha
 #
 # FILE: "wwwMenu.tcl"
 #                                          created: 04/30/1997 {11:04:46 am}
 #                                      last update: 03/21/2006 {01:53:38 PM} 
 # Description:
 # 
 # Procedures to build the WWW Menu, plus menu support.
 # 
 # Note that if the variables used in this package are 'global' lists that
 # are not specific to any window/url/filename, they are included in the
 # 'wwwMenuVars' array.
 # 
 # See the "wwwVersionHistory.tcl" file for license info, credits, etc.
 # ==========================================================================
 ##

alpha::menu wwwMenu 2.5.1 "global WWW HTML" "¥286" {
    # Initialization script.
    WWW::initializeMenu
} {
    # Activation script.
    WWW::activateMenu 1
} {
    # Deactivation script.
    WWW::activateMenu 0
} preinit {
    # 'Pre-init' script, called when Alpha is first started.  We use the
    # [array set] syntax here to ensure that any [trace]s that are applied to
    # the arrays, as in
    # 
    #     trace add variable newDocTypes {array write unset}
    # 
    # are properly taken into account.
    array set newDocTypes [list "New WWW Browser"           {WWW::renderUrl}]
    array set htmlViewer  [list "Text-only parser" 	    {WWW::renderFile}]
    array set urlViewer   [list "Internal text-only viewer" {WWW::renderUrl}]
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} uninstall {
    this-directory
} description {
    Render text-only web pages inside Alpha (like 'lynx')
} help {
    file "WWW Menu Help"
}

# Make sure that the wwwMode.tcl file has been loaded.
wwwMode.tcl

proc wwwMenu.tcl {} {}

namespace eval WWW  {
    
    variable initialized
    if {![info exists initialized]} {
        set initialized 0
    }
    variable activated
    if {![info exists activated]} {
        set activated -1
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "WWW::initializeMenu" --
 # 
 # Called when this menu is first initialized.  We try to put as little in
 # here as possible, to ensure that other code can call the "render" procs
 # even if this is not a global menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc WWW::initializeMenu {} {
    
    variable initialized
    
    if {$initialized} {
        return
    }
    wwwMode.tcl
    # Define the menu build procs.
    menu::buildProc wwwMenu      {WWW::buildMenu} {WWW::postBuildMenu}
    menu::buildProc bookmarks    {WWW::buildBookmarks}
    menu::buildProc goToPage     {WWW::buildGoToPage} {WWW::postBuildMenu}
    menu::buildProc wwwLinks     {WWW::buildLinks}
    menu::buildProc wwwWindow    {WWW::buildWindow}
    menu::buildProc wwwPathMenu  {WWW::buildWWWPath}
    # Now build the menu.
    menu::buildSome wwwMenu
    # Call anything else that is related to this package.
    hook::callAll "wwwMenuInit" *
    set initialized 1
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "WWW::activateMenu" --
 # 
 # Called when this menu is (de)activated.
 # 
 # --------------------------------------------------------------------------
 ##

proc WWW::activateMenu {which} {
    
    variable activated
    
    if {($which eq $activated)} {
        return
    } elseif {!$which} {
	WWW::OWH register
    } else {
	WWW::OWH deregister
    }
    return
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× WWW Menu ×××× #
# 

proc wwwMenu {} {}

proc WWW::buildMenu {} {
    
    global wwwMenu wwwMenuVars WWWmodeVars alpha::macos

    # Preliminaries
    set httpOk [WWW::httpAllowed]
    set optionItems [concat $wwwMenuVars(prefsInMenu) \
      "(-)" "flushCache" "setHomePageÉ" "moreOptionsÉ" "/t<BwwwMenuHelp"]

    # Create the menu list.
    if {$httpOk} {
	set menuList "<E<SviewUrlOrFileÉ"
    } else {
	set menuList "<E<SviewFileÉ"
    }
    lappend menuList "<S<IviewThisFile" "downloadUrlÉ" "goToUrlWindow" \
      [list Menu -n wwwWindow      -p WWW::menuProc -M WWW {}] \
      [list Menu -n wwwMenuOptions -p WWW::menuProc -M WWW $optionItems] "(-)" \
      "/w<Ohome" \
      [list Menu -m -n goToPage  {}] \
      [list Menu -m -n bookmarks {}]
    if {$httpOk} {
	foreach item [list 1 2 3 4] {
	    set binding $WWWmodeVars(wwwSearch${item})
	    lappend searchItems ${binding}wwwSearch${item}É
	}
        lappend menuList \
	  [list Menu -n searchEngines -p WWW::searchProc -M WWW $searchItems]
    }
    lappend menuList "history" "(-) " \
      "/bselectLink" "/b<UlinkToBrowser" "/b<U<BlinkInNewWindow" "(-)  " \
      "displayLinkLocation" "copyLinkLocation" "modifyLink" "editLinkedDocument"

    set submenus [list wwwWindow bookmarks goToPage]
    return [list build $menuList "WWW::menuProc -M WWW" $submenus $wwwMenu]
}

proc WWW::buildWindow {} {
    
    global alpha::platform

    if {(${alpha::platform} eq "alpha")} {
	set openWhere "openSourceInAlpha"
    } else {
	set openWhere "openSourceInAlphatk"
    }
    set menuList [list "reload" "/R<Orefresh" "(-)" \
      "displayLinks" "copySourceUrl" "$openWhere" "saveSourceFileAsÉ" "(-) " \
      "newWwwWindowÉ" "sendSourceToBrowser" "/S<U<OswitchToBrowser" \
      ]
    return [list build $menuList {WWW::menuProc -M WWW} {}]
}


proc WWW::buildGoToPage {} {

    global wwwMenuVars
    
    foreach item $wwwMenuVars(goToPages) {
	lappend previousWindows [lindex $item 1]
    }
    lappend previousWindows "(-)" "/\[Back" "/\]Forward" "Clear List"
    return [list build $previousWindows {WWW::navigationProc -m -M WWW} {}]
}

proc WWW::buildBookmarks {} {
    
    variable Bookmarks
    
    set bookmarks [list "Add Bookmark"]
    if {[llength [array names Bookmarks]]} {
	set bookmarks [concat $bookmarks "(-)" \
	  [lsort -dictionary [array names Bookmarks]] \
	  [list "(-) " "Edit BookmarkÉ" "Rename BookmarkÉ" "Remove BookmarkÉ"]]
    } else {
	lappend bookmarks \
	  "\(Rename BookmarkÉ" "\(Remove BookmarkÉ" "\(Edit Bookmark"
    }
    return [list build $bookmarks {WWW::navigationProc -m -M WWW} {}]
}
    
proc WWW::buildLinks {} {
    
    global alpha::CMArgs
    
    set pos [lindex ${alpha::CMArgs} 0]
    
    set title [win::Current]
    if {![catch {WWW::getCurrentLink $title 1 $pos $pos} link]} {
	set menuList [list "selectLink" "copyLinkLocation" \
	  "displayLinkLocation" "openLinkInNewWindow" "linkToBrowser" "(-)" \
	  "modifyLink" "editLinkedDocument" \
	  ]
    } else {
	set menuList [list "\(noLinkFound"]
    }
    return [list build $menuList {WWW::contextualMenuProc} {}]
}

proc WWW::buildWWWPath {} {
    
    variable UrlSource
    
    set w [win::Current]
    if {[info exists UrlSource($w)]} {
	if {([string length [set url $UrlSource($w)]] > 50)} {
	    set url "[string range $url 0 45]É"
	}
	set menuList [list $url]
    } else {
	set menuList [list "Could not identify source url"]
    }
    return [list build $menuList {WWW::titlebarSelectHook -m -c} {}]
}

proc WWW::postBuildMenu {args} {

    global WWWmodeVars wwwMenuVars wwwMenu invisibleModeVars PREFS \
      alpha::platform
    
    variable Links

    if {![package::active wwwMenu]} {
	return
    }

    set title [win::Current]
    set m [WWW::getWindowMode $title]
    # Called when the mode is potentially changing.
    set dim1 [expr {($m eq "WWW")     ? 1 : 0}]
    set dim2 [expr {($m eq "HTML")    ? 1 : 0}]
    set dim3 [expr {($dim1 + $dim2)   ? 1 : 0}]
    set dim4 0
    if {[llength [winNames]]} {
	set tmpDirs [file nativename [file join $PREFS tmp]]
	if {([string first $tmpDirs $title] != "-1") || ($m eq "WWW")} {
	    set dim4 1
	}
    }
    set dim5 [expr {[llength $wwwMenuVars(history)] > 1} ? 1 : 0]
    if {(${alpha::platform} eq "alpha")} {
	set openWhere "openSourceInAlpha"
    } else {
	set openWhere "openSourceInAlphatk"
    }
    foreach item [list $openWhere displayLinks reload refresh] {
	enableMenuItem wwwWindow $item $dim1
    }
    enableMenuItem -m bookmarks "Add Bookmark"        $dim1
    enableMenuItem $wwwMenu     "viewThisFile"        $dim2
    enableMenuItem $wwwMenu     "wwwWindow"           $dim3
    enableMenuItem wwwWindow    "sendSourceToBrowser" $dim3
    enableMenuItem wwwWindow    "copySourceUrl"       $dim3
    enableMenuItem wwwWindow    "saveSourceFileAsÉ"   $dim4
    enableMenuItem $wwwMenu     "history"             $dim5
    # Dim the 'Display Links' item if necessary.
    if {[set hasLinks [info exists Links($title)]]} {
	set hasLinks [expr {([llength $Links($title)] > 1) ? 1 : 0}]
    }
    enableMenuItem wwwWindow displayLinks $hasLinks
    # Mark the 'WWW Menu Options' menu as necessary.
    foreach itemName $wwwMenuVars(prefsInMenu) {
	if {[info exists invisibleModeVars($itemName)]} {
	    enableMenuItem wwwMenuOptions $itemName 0
	} elseif {[info exists WWWmodeVars($itemName)]} {
	    markMenuItem wwwMenuOptions $itemName $WWWmodeVars($itemName) Ã
	}
    }
    
    # Identify the current page in the 'Go To Page' menu.
    if {[set i [lsearch -glob $wwwMenuVars(goToPages) [list * [lindex $args 0]]]] != -1} {
	set wwwMenuVars(goToPagePos) $i
    }
    # Synchronize the 'Go To Page' menu, or dim as necessary.
    set pages $wwwMenuVars(goToPages)
    set pageP $wwwMenuVars(goToPagePos)
    if {[llength $pages]} {
	# We have a history of pages ...
	set forward [expr {$pageP < ([llength $pages] -1)} ? 1 : 0]
	set back    [expr {$pageP > 0} ? 1 : 0]
	enableMenuItem goToPage Forward $forward
	enableMenuItem goToPage Back    $back
	set pageC [lindex [lindex $pages $pageP] 1]
	foreach page $pages {
	    if {[set page [lindex $page 1]] ne ""} {
		if {($page eq $pageC)} {
		    markMenuItem -m goToPage $page 1 ¥
		} else {
		    markMenuItem -m goToPage $page 0 ¥
		}
	    }
	}
    }
    enableMenuItem $wwwMenu goToPage [expr {[llength $pages] ? 1 : 0}]
    # We keep this separate so that we can quickly dis/enable menu items
    # when navigating links.
    WWW::postBuildMenuLinks
    return
}

proc WWW::postBuildMenuLinks {} {

    global wwwMenu
    
    set m [WWW::getWindowMode]
    if {($m ne "WWW")} {
	set isALink 0
    } else {
	set isALink [isSelection]
    }
    if {$isALink && [catch {WWW::getCurrentLink "" 1} linkList]} {
        set isALink 0
    }
    set linkMenuItems [list modifyLink selectLink editLinkedDocument \
      linkInNewWindow linkToBrowser displayLinkLocation copyLinkLocation ]
    foreach item $linkMenuItems {
	enableMenuItem $wwwMenu $item $isALink
    }
    if {$isALink} {
        set link [lindex $linkList 2]
	enableMenuItem $wwwMenu editLinkedDocument [regexp {^file:/[/]+} $link]
    } else {
	enableMenuItem $wwwMenu editLinkedDocument 0
    }
    return
}

proc WWW::postBuildCM {args} {
    
    global contextualMenuWWWmodeVars wwwMenuVars
    
    # Synchronize the 'Go To Page' menu, or dim as necessary.
    if {[expr [set pages [llength $wwwMenuVars(goToPages)]] ? 1 : 0]} {
	set pageP $wwwMenuVars(goToPagePos)
	# We have a history of pages ...
	set forward [expr {$pageP < [expr {$pages -1}]} ? 1 : 0]
	set back    [expr {$pageP > 0} ? 1 : 0]
    } else {
        set forward [set back 0]
    }
    if {$contextualMenuWWWmodeVars(pageForwardItem)} {
	enableMenuItem [lindex $args 0] "pageForward" $forward
    }
    if {$contextualMenuWWWmodeVars(pageBackItem)} {
	enableMenuItem [lindex $args 0] "pageBack"    $back
    }
    return
}

set wwwMenuVars(owhRegistered) "-1"

proc WWW::OWH {{which "register"}} {
    
    global wwwMenu global::features wwwMenuVars
    
    # We avoid going through all of this if we've done it before.
    if {($which eq "register") && ![lcontains global::features wwwMenu]} {
	return
    } elseif {($which eq "register") && ($wwwMenuVars(owhRegistered) == "1")} {
	return
    } elseif {($which eq "deregister") && ($wwwMenuVars(owhRegistered) == "0")} {
	return
    }
    # Dim some menu items when there are no open windows.
    set menuItems [list viewThisFile \
      selectLink modifyLink editLinkedDocument linkInNewWindow linkToBrowser \
      displayLinkLocation copyLinkLocation wwwWindow]
    foreach i $menuItems {
	hook::${which} requireOpenWindowsHook [list $wwwMenu $i] 1
    }
    # Register an activate hook if we are turned on globally.
    if {[lcontains global::features wwwMenu]} {
        #hook::register          activateHook {WWW::postBuildMenu} *
    } else {
	#hook::deregister        activateHook {WWW::postBuildMenu} *
    }
    # Help ensure that we don't have to go through this again.
    if {($which eq "register")} {
	set wwwMenuVars(owhRegistered) 1
    } elseif {($which eq "deregister")} {
	set wwwMenuVars(owhRegistered) 0
    }
    return
}

proc WWW::rebuildMenu {args} {
    menu::buildSome wwwMenu
    status::msg "The WWW Menu has been rebuilt."
    return
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× WWW Menu Support ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "WWW::menuProc" --
 # 
 # The main procedure called by most menu items.  'Navigation' items are
 # routed to [WWW::navigationProc].
 # 
 # --------------------------------------------------------------------------
 ##

proc WWW::menuProc {menuName itemName args} {
    
    global browserSig alpha::macos WWWmodeVars wwwMenu wwwMenuVars
    
    variable FileSource
    variable Links
    variable LinksReverse
    variable UrlSource
    
    WWW::setWindowVars
    
    set navigationItems [list history clearHistory back forward \
      selectLink linkInNewWindow linkToBrowser]
    if {[lcontains navigationItems $itemName]} {
	WWW::navigationProc "" $itemName
	return
    }
    set title [win::Current]
    set m [WWW::getWindowMode $title]
    if {($menuName eq "wwwMenuOptions")} {
	if {($itemName eq "setHomePage")} {
	    set oldHP $WWWmodeVars(homePage)
	    status::msg "Old home page: [dialog::specialView::url $oldHP]"
	    set WWWmodeVars(homePage) [dialog::getUrl "New home page:" $oldHP]
	    prefs::modified WWWmodeVars(homePage)
	    set msg "'$WWWmodeVars(homePage)' is now your new home page."	
	} elseif {($itemName eq "flushCache")} {
	    foreach item [list BaseUrl FileSource TitleCache \
	      LinkTargetWindow LinkWindowTarget] {
		if {[info exists WWW::$item]} {
		    unset WWW::$item
		}
	    }
	    WWW::flushWindowParameters
	    WWW::quitHook
	    WWW::navigationProc "goToPage" "Clear List"
	    set msg "The WWW cache of files has been flushed."
	} elseif {($itemName eq "wwwMenuHelp")} {
	    package::helpWindow WWW
	} elseif {($itemName eq "moreOptions")} {
            prefs::dialogs::modePrefs "WWW" "WWW Menu Preferences"
	} elseif {![lcontains wwwMenuVars(prefsInMenu) $itemName]} {
	    status::msg "Sorry, don't know what to do with '$itemName'"
	    return -code return
	} else {
	    if {[getModifiers]} {
		# Open an alertnote with information about the preference.
		set text [help::prefString $itemName "WWW"]
		if {$WWWmodeVars($itemName)} {
		    regsub {^.*\|\|} $text {} text
		} else {
		    regsub {\|\|.*$} $text {} text
		}
		alertnote "${text}."
	    } else {
		set WWWmodeVars($itemName) [expr {$WWWmodeVars($itemName) ? 0 : 1}]
		if {($m eq "WWW")} {
		    synchroniseModeVar $itemName $WWWmodeVars($itemName)
		} else {
		    prefs::modified WWWmodeVars($itemName)
		}
		markMenuItem wwwMenuOptions $itemName $WWWmodeVars($itemName) Ã
		if {[lcontains wwwMenuVars(refreshPrefs) $itemName]} {
		    WWW::refreshFrontWindow
		}
	    }
	    set end [expr {$WWWmodeVars($itemName) ? "on" : "off"}]
	    set msg "The '$itemName' preference for the WWW menu is currently $end."
	}
	if {[info exists msg]} {
	    status::msg $msg
	}
	return
    }
    switch -- $itemName {
	"copySourceUrl" {
	    WWW::titlebarSelectHook
	}
	"switchToBrowser"  {app::launchFore $browserSig}
	"newWwwWindow" {
	    eval WWW::renderUrl $args
	}
	"home" {
	    WWW::renderUrl $WWWmodeVars(homePage)
	}
	"viewFile" {
	    WWW::renderFile
	}
	"viewThisFile" {
	    if {($m eq "HTML")} {
		WWW::renderFile [win::StripCount [win::Current]]
	    } else {
		status::msg "Cancelled -- file must be HTML to be viewed!"
		return -code return
	    }
	}
	"viewUrl" - "viewUrlOrFile" {
	    WWW::renderUrl
	}
	"downloadUrl" {
	    set p "Enter a url to download:"
	    if {![string length [set url [getline $p]]]} {
	        status::msg "Cancelled."
		return -code return
	    } elseif {![url::isDirectory $url]} {
		url::getAFile $url
	    } else {
		url::getADirectory $url
	    }
	}
	"modifyLink" {
	    # Make sure that we have enough info to do this.
	    if {($m ne "WWW")} {
		alertnote "Modiy Link is only useful in WWW browser mode."
		error "Cancelled"
	    } elseif {[catch {set FileSource($title)} fileSource]} {
		alertnote "Sorry, can't identify the source for '$title'."
		error "Cancelled"
	    } elseif {![file exists $fileSource]} {
		alertnote "Sorry, can't find '$fileSource'."
		error "Cancelled"
	    }
	    # Find the current link to modify.
	    set linkList [WWW::getCurrentLink]
	    set oldLink  [lindex $linkList 2]
	    status::msg "Old link: [dialog::specialView::url $oldLink]"
	    set to       [dialog::getUrl "Enter new link location" $oldLink]
	    if {($to eq "") || ($to eq $oldLink)} {
		status::msg "Nothing was changed."
		return -code return
	    }
	    # Find out if the source is already open.
	    if {![catch {getWinInfo -w $fileSource i}]} {
		if {$i(dirty)} {
		    if {![dialog::yesno "Save original file?"]} {
			error "cancel"
		    }
		    status::msg "Saving original file."
		    bringToFront $fileSource
		    save
		    bringToFront $title
		}
	    }
	    # Update the source file.
	    set reglink [quote::Regfind $oldLink]
	    set regto   [quote::Regsub $to]
	    set cid [alphaOpen $fileSource "r"]
	    if {[regsub -all -- $reglink [read $cid] $regto out]} {
		set ocid [alphaOpen $fileSource "w+"]
		puts -nonewline $ocid $out
		close $ocid
		status::msg "Updated original."
	    }
	    close $cid
	    if {[win::Exists $fileSource]} {
		bringToFront $fileSource
		status::msg "Updating window to agree with disk version."
		revert
		bringToFront $title
	    }
	    setWinInfo read-only 0
	    WWW::makeLink [win::Current] [getPos] [selEnd] $to
	    setWinInfo read-only 1
	    # Now update the link lists.
	    set i1 [lsearch $Links($title) $linkList]
	    set i2 [lsearch $LinksReverse($title) $linkList]
	    set linkList [lreplace $linkList 2 2 "WWW::link \"$to\""]
	    set linkList [lreplace $linkList 3 3 $to]
	    set Links($title)        [lreplace $Links($title)        $i1 $i1 $linkList]
	    set LinksReverse($title) [lreplace $LinksReverse($title) $i2 $i2 $linkList]
	    status::msg "WWW::link \"$to\""
	}
	"editLinkedDocument" {
	    set to [lindex [WWW::getCurrentLink "" 0] 2]
	    if {![regsub {^file:[/]+} $to {} fileSource]} {
	        status::msg "Sorry, can only edit local files."
		return -code return
	    }
	    regsub {\#.*$} [quote::Unurl $fileSource] {} fileSource
	    if {[catch {file::openQuietly $fileSource}]} {
	        status::msg "Sorry, can't find the file '$fileSource'."
		return -code return
	    }
	}
	"openSourceInAlphatk" -
	"openSourceInAlpha" {
	    if {($m ne "WWW")} {
		status::msg "This item is only useful for rendered files."
		return -code return
	    } elseif {[catch {set FileSource($title)} sourceFile]} {
		status::msg "Couldn't find the source of '$title'"
		return -code return
	    } elseif {[catch {file::openQuietly $sourceFile}]} {
		status::msg "Couldn't find '$sourceFile'"
		return -code return
	    } else {
		status::msg "Source file of '$title'"
	    }
	}
	"sendSourceToBrowser" {
	    if {($m eq "HTML")} {
		set sourceFile [win::StripCount [win::Current]]
	    } elseif {[info exists UrlSource($title)]} {
		url::execute $UrlSource($title)
		return
	    } elseif {[info exists FileSource($title)]} {
		set sourceFile $FileSource($title)
	    } else {
		status::msg "Couldn't find the source of '$title'"
		return -code return
	    }
	    # This was lifted from 'htmlSendWindow'.
	    if {${alpha::macos}} {
		if {![info exists browserSig] \
		  && [catch {file::getSig [icGetPref -t 1 Helper¥http]} browserSig]} {
		    set browserSig MOSS
		}
		if {[catch {app::launchBack $browserSig}]} {
		    app::getSig "Please locate your web browser" browserSig
		    app::launchBack $browserSig
		}
		if {($browserSig eq "MOSS")} {
		    sendOpenEvent noReply '$browserSig' $sourceFile
		} else {
		    regsub -all : $sourceFile / sourceFile
		    tclAE::send '$browserSig' \
		      WWW! OURL "----" "Òfile:///${sourceFile}Ó" FLGS 1
		}
		switchTo '$browserSig'
	    } else {
		file::openInDefault $sourceFile
		return
	    }
	}
	"refresh" {
	    WWW::refreshWindow $title
	}
	"saveSourceFileAs" {
	    # This is different from the File menu item 'Save As' because
	    # when rendering the file we might have messed up some line
	    # endings, which would be a problem for .sit files (for example)
	    if {[file isfile $title]} {
	        set sourceFile $title
	    } elseif {[catch {set FileSource($title)} sourceFile]} {
		status::msg "Couldn't find the source of '$title'"
		return -code return
	    }
	    set title [file tail $title]
	    set p "Save the source file of this '$title' window as:"
	    set newName [prompt $p $title]
	    set newDir  [get_directory -p "Save '$newName' in:"]
	    set newFile [file join $newDir $newName]
	    if {[file exists $newFile]} {
		# Should we over-write the existing target?
		set    question "'${newName}' already exists in '${newDir}'.\r"
		append question "Do you want to replace it?"
		if {([askyesno $question] eq "no")} {
		    status::msg "Cancelled." ; return
		}
	    } elseif {[catch {file copy $sourceFile $newFile}]} {
		status::msg "Failed to copy '$sourceFile' to '$newFile'"
	    } else {
		status::msg "'$newName' has been saved in '$newDir'."
	    }
	}
	"copyLinkLocation" {
	    putScrap [set to [lindex [WWW::getCurrentLink "" 0] 2]]
	    status::msg "Copied to clipboard: '[dialog::specialView::url $to]"
	}
	"displayLinkLocation" {
	    alertnote [lindex [WWW::getCurrentLink "" 0] 2]
	}
	default {eval WWW::$itemName}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "WWW::navigationProc" --
 # 
 # Handles history navigation, as well as window-movement key bindings.  Note
 # that we DO respect the "linksOpenNewWindow" preference here, which means
 # that we kill windows as necessary.
 # 
 # --------------------------------------------------------------------------
 ##

proc WWW::navigationProc {menuName itemName} {
    
    global wwwMenuVars wwwMenu
    
    variable BaseUrl
    variable Bookmarks
    variable FileSource
    variable UrlSource

    WWW::setWindowVars

    switch -- $menuName {
	"goToPage" {
	    switch -- $itemName {
		"clearList" - "Clear List" {
		    # Reset variables, clear the menu.
		    set wwwMenuVars(goToPages)   ""
		    set wwwMenuVars(goToPagePos) -1
		    menu::buildSome goToPage
		    enableMenuItem $wwwMenu goToPage 0
		    status::msg "The 'Go To Page' menu has been emptied."
		}
		"back" - "Back" {
		    set pages $wwwMenuVars(goToPages)
		    set pageP $wwwMenuVars(goToPagePos)
		    if {[win::Current] eq $wwwMenuVars(historyTitle)} {
			set pageInfo [lindex $pages $pageP]
			set filename [lindex $pageInfo 0]
			set title    [lindex $pageInfo 1]
			WWW::goToPage $filename $title
		    } elseif {$pageP > 0} {
			incr wwwMenuVars(goToPagePos) -1
			set pageInfo [lindex $pages $wwwMenuVars(goToPagePos)]
			set filename [lindex $pageInfo 0]
			set title    [lindex $pageInfo 1]
			WWW::goToPage $filename $title
		    } else {
			WWW::postBuildMenu
			beep
			status::msg "Already at first document."
		    }
		}
		"forward" - "Forward"  {
		    set pages $wwwMenuVars(goToPages)
		    set pageP $wwwMenuVars(goToPagePos)
		    if {[win::Current] eq $wwwMenuVars(historyTitle)} {
			set pageInfo [lindex $pages $pageP]
			set filename [lindex $pageInfo 0]
			set title    [lindex $pageInfo 1]
			WWW::goToPage $filename $title
		    } elseif {$pageP < [expr [llength $pages] -1]} {
			incr wwwMenuVars(goToPagePos)
			set pageInfo [lindex $pages $wwwMenuVars(goToPagePos)]
			set filename [lindex $pageInfo 0]
			set title    [lindex $pageInfo 1]
			WWW::goToPage $filename $title
		    } else {
			WWW::postBuildMenu
			beep
			status::msg "Already at most recent document."
		    }
		}
		default {
		    # Go to a history item.
		    set pages $wwwMenuVars(goToPages)
		    set pageP $wwwMenuVars(goToPagePos)
		    if {![llength $pages]} {
			status::msg "No pages are currently available."
			return -code return
		    }
		    set which 0
		    foreach i $pages {
			if {![string length $itemName]} {
			    lappend pagesL [lindex $i 1]
			} elseif {([lindex $i 1] eq $itemName) \
			  || ([lindex $i 1] eq "${itemName}É")} {
			    unset -nocomplain pages
			    break
			}
			incr which
		    }
		    if {[info exists pagesL]} {
			# None was initially specified (or found), so offer the list.
			set L [lindex [lindex $pages $pageP] 1]
			set g [listpick -p "Go to which page?" -L [list $L] $pagesL]
			WWW::navigationProc "goToPage" $g
		    } elseif {$which >= [llength $wwwMenuVars(goToPages)]} {
			alertnote "Sorry, I couldn't find that page!"
		    } else {
			set wwwMenuVars(goToPagePos) $which
			set pageInfo [lindex $wwwMenuVars(goToPages) $which]
			set filename [lindex $pageInfo 0]
			set title    [lindex $pageInfo 1]
			WWW::goToPage $filename $title
		    }
		}
	    }
	}
	"bookmarks" {
	    switch -- $itemName {
		"addBookmark" - "Add Bookmark" {
		    set w [win::Current]
		    if {[info exists UrlSource($w)]} {
			set sourceUrl $UrlSource($w)
		    } elseif {[info exists BaseUrl($w)]} {
			set sourceUrl $BaseUrl($w)
		    } else {
			# Make sure that items are properly dimmed.
			WWW::postBuildMenu 1
			status::msg "Sorry, can't find the source file for '[win::Current]'."
			return
		    }
		    set Bookmarks($w) $sourceUrl
		    prefs::modified Bookmarks($w)
		    menu::buildSome bookmarks ; WWW::postBuildMenu 1
		    status::msg "'$w' has been added to the bookmarks menu."
		}
		"editBookmark" - "Edit Bookmark" {
		    set bookmarks [lsort -dictionary [array names Bookmarks]]
		    if {![llength $bookmarks]} {
			status::msg "There are no bookmarks to rename."
			return
		    }
		    set p "Edit which bookmark?"
		    while {1} {
			set b [listpick -p $p $bookmarks]
			set p "Please type your url, or use one of the buttons below"
			set d $Bookmarks($b)
			status::msg "Old url: [dialog::specialView::url $d]"
			set newUrl [dialog::getUrl $p $d]
			set Bookmarks($b) $newUrl
			prefs::modified Bookmarks($b)
			set p "Choose another to rename, or press cancel"
			status::msg "New settings for '$b' have been saved."
		    }
		}
		"renameBookmark" - "Rename Bookmark" {
		    set bookmarks [lsort -dictionary [array names Bookmarks]]
		    if {![llength $bookmarks]} {
			status::msg "There are no bookmarks to rename."
			return
		    }
		    set p "Rename which bookmark?"
		    while {1} {
			set result  [listpick -p $p $bookmarks]
			set newName [prompt "New name for '$result':" $result]
			set Bookmarks($newName) $Bookmarks($result)
			prefs::modified Bookmarks($newName)
			prefs::modified Bookmarks($result)
			unset Bookmarks($result)
			set p "Choose another to rename, or press cancel"
			set bookmarks [lsort -dictionary [array names Bookmarks]]
			menu::buildSome bookmarks ; WWW::postBuildMenu 1
			status::msg "'$result' has been renamed to '$newName'."
		    }
		}
		"removeBookmark" - "Remove Bookmark" {
		    set bookmarks [lsort -dictionary [array names Bookmarks]]
		    if {![llength $bookmarks]} {
			status::msg "There are no bookmarks to remove."
			return
		    }
		    set p "Remove which bookmarks?"
		    if {[catch {listpick -l -p $p $bookmarks} result]} {
			status:errorMsg "Cancelled."
		    }
		    foreach bookmark $result {
			unset -nocomplain Bookmarks($bookmark)
			prefs::modified Bookmarks($bookmark)
		    }
		    menu::buildSome wwwMenu ; WWW::postBuildMenu 1
		    if {([llength $result] == "1")} {
			status::msg "$result has been removed."
		    } elseif {[llength $result] > "1"} {
			status::msg "$result have been removed."
		    }
		}
		default {
		    set w $itemName
		    if {[info exists Bookmarks(${w}É)]} {
			append w "É"
		    } elseif {![info exists Bookmarks($w)]} {
			status::msg "Sorry, can't find the source file for '$w'."
			return -code return
		    }
		    WWW::renderUrl $Bookmarks($w)
		}
	    }
	}
	default {
	    switch -- $itemName {
		"up"         {WWW::nextLink 0 ; WWW::postBuildMenuLinks}
		"down"       {WWW::nextLink 1 ; WWW::postBuildMenuLinks}
		"selectLink" {WWW::link}
		"linkInNewWindow" {
		    set title [win::Current]
		    if {$title != $wwwMenuVars(historyTitle) && [info exists FileSource($title)]} {
			set f FileSource($title)
			WWW::addHistoryItem $f
		    }
		    set to [lindex [WWW::getCurrentLink "" 0] 2]
		    WWW::visitedLink $to
		    WWW::menuProc $wwwMenu "newWwwWindow" $to
		}
		"linkToBrowser" {
		    set to [lindex [WWW::getCurrentLink "" 0] 2]
		    url::execute $to
		}
		"Home" {
		    goto [minPos]
		    WWW::postBuildMenuLinks
		}
		"End" {
		    goto [maxPos]
		    WWW::postBuildMenuLinks
		}
		"PageForward" {
		    pageForward
		    WWW::postBuildMenuLinks
		}
		"PageBack" {
		    pageBack
		    WWW::postBuildMenuLinks
		}
		"twoLinesForward" {
		    scrollDownLine
		    scrollDownLine
		}
		"twoLinesBack" {
		    scrollUpLine
		    scrollUpLine
		}
		"fiveLinesForward" {
		    scrollDownLine
		    scrollDownLine
		    scrollDownLine
		    scrollDownLine
		    scrollDownLine
		}
		"fiveLinesBack" {
		    scrollUpLine
		    scrollUpLine
		    scrollUpLine
		    scrollUpLine
		    scrollUpLine
		}
		"halfPageForward" {
		    getWinInfo winArray
		    set top   $winArray(currline)
		    set lines $winArray(linesdisp)
		    goto [pos::fromRowCol [expr $top + $lines + (${lines}/2) - 1] 0]
		    WWW::postBuildMenuLinks
		}
		"halfPageBack" {
		    getWinInfo winArray
		    set top   $winArray(currline)
		    set lines $winArray(linesdisp)
		    goto [pos::fromRowCol [expr $top - ${lines}/2] 0]
		    WWW::postBuildMenuLinks
		}
		"history" {
		    WWW::historyWindow
		}
		default {WWW::$itemName}
	    }
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "WWW::goToPage" --
 # 
 # Reopens or brings to front previously rendered windows.  Note that we DO
 # respect the "linksOpenNewWindow" preference here, which means that we kill
 # windows as necessary.
 # 
 # --------------------------------------------------------------------------
 ##

proc WWW::goToPage {filename title} {
    
    variable BaseUrl
    variable FileSource

    # We've already seen this title, so we know if it is part of a target set
    # or not.  If not, then we won't use the current window to determine if
    # the window is part of the target.
    if {[WWW::isNotPartOfTarget $title]} {
	WWW::openingAsTarget 0
    }
    WWW::openingFromLink 1
    if {[file isfile $filename]} {
        WWW::renderLocal $filename $title
    } elseif {[info exists FileSource($title)] && \
      [file exists $FileSource($title)]} {
	WWW::renderLocal $FileSource($title) $title
    } elseif {[info exists BaseUrl($title)]} {
        WWW::renderRemote $BaseUrl($title) $title
    } else {
        status::msg "Cancelled -- couldn't find the source file for '$title'."
	return -code return
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "WWW::searchProc" --
 # 
 # Create a new window with search results.  Note that we do NOT respect the
 # "linksOpenNewWindow" preference here, which means that we always create a
 # new window.
 # 
 # --------------------------------------------------------------------------
 ##

proc WWW::searchProc {menuName itemName {searchText ""} {url ""}} {
    
    global WWWmodeVars
    
    regsub {wwwSearch} $itemName {} url

    if {![string length $url]} {
	set url $WWWmodeVars(searchUrl1)
    } elseif {[regexp {^[0-9]$} $url]} {
	set url $WWWmodeVars(searchUrl${url})
    }
    if {![string length $searchText]} {
	if {[catch {getSelect} searchText]} {
	    set searchText ""
	}
	if {![string length $searchText] \
	  || !$WWWmodeVars(searchUsingSelection)} {
	    regsub {^http://}           $url     {} urlName
	    regsub {^www.}              $urlName {} urlName
	    regsub {/+.*.$}             $urlName {} urlName
	    regsub {^search\.}          $urlName {} urlName
	    regsub {\.(com|org|net)$}   $urlName {} urlNamep
	    set p "'$urlName' search forÉ "
	    set searchText [prompt $p $searchText]
	}
    }
    set searchText [quote::Url $searchText]
    regsub -all {[ ]+} $searchText {+} searchTextPlus
    set searchTextPlus %22$searchText%22
    WWW::renderUrl $url$searchTextPlus
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "WWW::massagePath" --
 # 
 # I'm not exactly sure why we need this here, but removing it in the MacOS
 # will wreak some havoc.  -- cbu
 # 
 # --------------------------------------------------------------------------
 ##

proc WWW::massagePath {pp} {
    
    upvar 1 $pp p
    if {[regexp {^file+://} $p]} {
	set p [file::fromUrl $p]
    }
    set p [file nativename $p]
    return $p
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Contextual Menu Support ×××× #
# 

proc WWW::contextualMenuProc {menuName itemName} {
    
    WWW::setWindowVars

    global wwwMenu alpha::CMArgs
    
    switch $menuName {
	"wwwLinks" {
	    set p [lindex ${alpha::CMArgs} 0]
	    set t [win::Current]
	    if {[catch {getCurrentLink $t 1 $p $p} link]} {
		status::msg "Current position is not a link."
		return
	    }
	    switch $itemName {
		"copyLinkLocation"   {
		    putScrap [set to [lindex $link 2]]
		    status::msg "Copied to clipboard: '[dialog::specialView::url $to]'"
		}
		"displayLinkLocation" {
		    alertnote [lindex $link 2]
		}
		default {
		    selectText [lindex $link 0] [lindex $link 1]
		    menuProc $wwwMenu $itemName
		}
	    }
	}
	"wwwWindow" {
	    menuProc $wwwMenu $itemName
	}
    }
    return
}

# Required for contextual menu items.

proc WWW::pageForward {args} {
    WWW::navigationProc "goToPage" "forward"
    return
}
proc WWW::pageBack {args} {
    WWW::navigationProc "goToPage" "back"
    return
}

# ===========================================================================
# 
# .