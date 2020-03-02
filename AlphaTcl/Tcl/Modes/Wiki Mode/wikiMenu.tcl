## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "wikiMenu.tcl"
 #                                          created: 01/27/2006 {11:27:36 AM}
 #                                      last update: 04/10/2006 {11:56:11 PM}
 # Description:
 # 
 # Enables the editing and posting of wiki pages from Alpha.
 # 
 # See the "wikiMode.tcl" file for author, license information.
 # 
 # ==========================================================================
 ##

alpha::menu wikiMenu 1.2b8 global "¥302" {
    # Initialization script.
    Wiki::initializeMenu
} {
    # Activation script.
    Wiki::activateMenu 1
} {
    # Deactivation script.
    Wiki::activateMenu 0
} uninstall {
    this-directory
} maintainer {
} description {
    Provides support for editing and posting remote Wiki web pages
} help {
    file "Wiki Menu Help"
}

proc wikiMenu.tcl {} {}

namespace eval Wiki {
    
    variable menuInitialized
    if {![info exists menuInitialized]} {
	set menuInitialized 0
    }
    variable menuActivated
    if {![info exist menuActivated]} {
	set menuActivated -1
    }
    # This keeps a copy of the last text we attempted to post.
    variable lastPostedText
    if {![info exists lastPostedText]} {
	set lastPostedText ""
	trace add variable "lastPostedText" "write" {Wiki::enableReview}
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::httpAvailable" --
 # 
 # Determine if the "http" package is available.  We only check once during
 # each editing session; if it didn't exist, the user will have to perform
 # some update of the Tcl library, in which case the entire System should be
 # restarted as well as Alpha.
 # 
 # If "throwError" is "0" then we simply return the availability status,
 # otherwise we throw an informative "cancel" error.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::httpAvailable {{throwError "0"}} {
    
    variable httpAvailable
    
    if {[info exists httpAvailable]} {
	set result $httpAvailable
    } elseif {[catch {package require http}]} {
	set result [set httpAvailable 0]
    } else {
	set result [set httpAvailable 1]
    }
    if {$result || !$throwError} {
        return $result
    } else {
        error "Cancelled -- the Tcl \"http\" package is not available."
    }
}

# ===========================================================================
# 
# ×××× Wiki Bindings ×××× #
# 
# We need to file bugs for any true problems here and then remove the rest.
# 

# Alpha 8 seems to need these.
if {(${alpha::platform} eq "alpha")} {
Bind ':'   <zs>  {Wiki::menuProc "Wiki Paragraph" definitionItem} Wiki
}

Bind '\''  <zs>  {Wiki::menuProc "Wiki Text"      unquote}        Wiki
Bind '\"'  <z>   {Wiki::menuProc "Wiki Text"      unquote}        Wiki

# Shortcut Preferences.

# To enable the main Wiki Menu keyboard shortcuts only in Wiki mode, turn
# this item on||To enable the main Wiki Menu keyboard shortcuts globally,
# turn this item off
newPref flag "enableShortcutsInWikiModeOnly" 1   Wiki {Wiki::rebuildMenu}

# The "Wiki Menu > Edit Wiki Page" menu shortcut.
newPref menubinding "editWikiPage"      "<U<B/E" Wiki {Wiki::rebuildMenu}
# The "Wiki Menu > Save In Browser" menu shortcut.  Unlike the other 
# shortcuts, this will not appear in the menu.
newPref binding     "saveInBrowser"     "<U<O/S" Wiki {Wiki::rebuildMenu} \
  {Wiki::saveInBrowser}
# The "Wiki Menu > Project Home Page" menu shortcut.
newPref menubinding "projectHomePage"   "<U<B/w" Wiki {Wiki::rebuildMenu}
# The "Wiki Menu > Formatting Rules" menu shortcut.
newPref menubinding "formattingRules"   "<U<B/F" Wiki {Wiki::rebuildMenu}

# The "Wiki Menu > Wiki Text > Bold" menu shortcut.
newPref menubinding "bold"              "/B<U<B" Wiki {Wiki::rebuildMenu}
# The "Wiki Menu > Wiki Text > Italics" menu shortcut.
newPref menubinding "italics"           "/I<U<B" Wiki {Wiki::rebuildMenu}
# The "Wiki Menu > Wiki Text > Unquote" menu shortcut.
newPref menubinding "unquote"           "/'<U<B" Wiki {Wiki::rebuildMenu}

set b [expr {$alpha::macos ? "<U<I" : "<U<B<O"}]


unset b

if {($alpha::platform eq "alpha")} {
    # The "Wiki Menu > Wiki Line > Horizontal Line" menu shortcut.
    newPref menubinding "horizontalLine" "/-<U<I" Wiki {Wiki::rebuildMenu}
    # The "Wiki Menu > Wiki Line > Bullet List Item" menu shortcut.
    newPref menubinding "bulletListItem" "/*<U<I" Wiki {Wiki::rebuildMenu}
    # The "Wiki Menu > Wiki Line > Numbered Item" menu shortcut.
    newPref menubinding "numberedItem"  "/1<U<I" Wiki {Wiki::rebuildMenu}
    # The "Wiki Menu > Wiki Line > Verbatim/Unverbatim" menu shortcut.
    newPref menubinding "verbatim/unverbatim" "/V<U<B" Wiki {Wiki::rebuildMenu}
} elseif {$alpha::macos} {
    # The "Wiki Menu > Wiki Line > Horizontal Line" menu shortcut.
    newPref menubinding "horizontalLine" "/-<U<I" Wiki {Wiki::rebuildMenu}
    # The "Wiki Menu > Wiki Line > Bullet List Item" menu shortcut.
    newPref menubinding "bulletListItem" "/*<U<I" Wiki {Wiki::rebuildMenu}
    # The "Wiki Menu > Wiki Line > Numbered Item" menu shortcut.
    newPref menubinding "numberedItem"  "/1<U<I" Wiki {Wiki::rebuildMenu}
    # The "Wiki Menu > Wiki Line > Verbatim" menu shortcut.
    newPref menubinding "verbatim"      "/V<U<B" Wiki {Wiki::rebuildMenu}
    # The "Wiki Menu > Wiki Line > Unverbatim" menu shortcut.
    newPref menubinding "unverbatim"   "/V<I<U<B" Wiki {Wiki::rebuildMenu}
} else {
    # The "Wiki Menu > Wiki Line > Horizontal Line" menu shortcut.
    newPref menubinding "horizontalLine" "/-<U<B<O" Wiki {Wiki::rebuildMenu}
    # The "Wiki Menu > Wiki Line > Bullet List Item" menu shortcut.
    newPref menubinding "bulletListItem" "/*<U<B<O" Wiki {Wiki::rebuildMenu}
    # The "Wiki Menu > Wiki Line > Numbered Item" menu shortcut.
    newPref menubinding "numberedItem" "/1<U<B<O" Wiki {Wiki::rebuildMenu}
    # The "Wiki Menu > Wiki Line > Verbatim" menu shortcut.
    newPref menubinding "verbatim"      "/V<U<B" Wiki {Wiki::rebuildMenu}
    # The "Wiki Menu > Wiki Line > Unverbatim" menu shortcut.
    newPref menubinding "unverbatim"  "/V<O<U<B" Wiki {Wiki::rebuildMenu}
}

# The "Wiki Menu > Wiki Paragraph > Prev Paragraph" menu shortcut.
newPref menubinding "prevParagraph"     "/P<U<B" Wiki {Wiki::rebuildMenu}
# The "Wiki Menu > Wiki Paragraph > Next Paragraph" menu shortcut.
newPref menubinding "nextParagraph"     "/N<U<B" Wiki {Wiki::rebuildMenu}
# The "Wiki Menu > Wiki Paragraph > Select Paragraph" menu shortcut.
newPref menubinding "selectParagraph"   "/S<U<B" Wiki {Wiki::rebuildMenu}
# The "Wiki Menu > Wiki Paragraph > Reformat Paragraph" menu shortcut.
newPref menubinding "reformatParagraph" "/I<O<B" Wiki {Wiki::rebuildMenu}

# ===========================================================================
# 
# Categories of all Wiki preferences, used by [prefs::dialogs::modePrefs].
# When the dialogues are actually built, there will most likely be added a
# Miscellaneous pane.  This happens whenever there are prefs which are not
# categorized.  (There's no need to set a "Miscellaneous" group entry,
# because this will always be built from scratch.)
# 

# Create the group order.
prefs::dialogs::setPaneLists "Wiki" \
  "Editing"                     [list] \
  "Colors"                      [list] \
  "Wiki Menu"                   [list] \
  "Wiki Menu > Text"            [list] \
  "Wiki Menu > Line"            [list] \
  "Wiki Menu > Paragraph"       [list]

# Wiki Menu.
prefs::dialogs::setPaneLists "Wiki" "Wiki Menu" [list \
  "enableShortcutsInWikiModeOnly" \
  "editWikiPage" \
  "saveInBrowser" \
  "projectHomePage" \
  "formattingRules" \
  ]

# Wiki Menu > Text.
prefs::dialogs::setPaneLists "Wiki" "Wiki Menu > Text" [list \
  "bold" \
  "italics" \
  "unquote" \
  ]

# Wiki Menu > Line.
prefs::dialogs::setPaneLists "Wiki" "Wiki Menu > Line" [list \
  "horizontalLine" \
  "bulletListItem" \
  "numberedItem" \
  "verbatim/unverbatim" \
  "verbatim" \
  "unverbatim" \
  ]

# Wiki Menu > Paragraph.
prefs::dialogs::setPaneLists "Wiki" "Wiki Menu > Paragraph" [list \
  "prevParagraph" \
  "nextParagraph" \
  "selectParagraph" \
  "reformatParagraph" \
  ]

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::initializeMenu" --
 # 
 # This proc is called the first time that this menu is loaded.  It should
 # _never_ be called by anything except the AlphaTcl SystemCode procedures!
 # 
 # This file will already be loaded in its entirety before this procedure is
 # formally evaluated.  This will define and build the Wiki Menu.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::initializeMenu {} {
    
    global newDocTypes global::menus WikimodeVars
    
    variable menuInitialized
    variable Projects
    variable prefProjects
    
    if {$menuInitialized} {
	return
    }
    # Make sure that our support files are sourced.
    wikiMode.tcl
    wikiMethods.tcl
    wikiProjects.tcl
    wikiFavorites.tcl
    wikiRemote.tcl
    wikiSystems.tcl
    # Define our systems.
    Wiki::defineSystems
    
    # Declare a new item for 'New Document'
    set {newDocTypes(New Wiki Project)} Wiki::newProject
    
    # Register hooks.
    hook::register activateHook {Wiki::activateHook} Wiki
    
    # If the array exists, then these should've been set at some point in the
    # past, so we don't do it again, in case the user actually wanted to
    # delete them!  This will automatically set the "default" project, which
    # will never be removed.
    if {![llength [array names Projects]]} {
	Wiki::defaultProjects
    }
    # Make sure that our projects our properly updated as necessary.
    Wiki::backCompatibilityCheck
    foreach project [Wiki::listProjects 1] {
	Wiki::verifyProject $project
    }
    # Now that we've created our projects (i.e. we know that we have some),
    # define the "wikiProject" preference.
    set prefProjects [Wiki::listProjects -2]
    prefs::renameOld WikimodeVars(wikiproject) WikimodeVars(wikiProject)
    # The current Wiki project
    newPref var wikiProject "default" "Wiki" \
      {Wiki::rebuildMenu} "Wiki::prefProjects" varitem
    prefs::deregister "wikiProject" "Wiki"
    
    # Wiki menu.
    menu::buildProc wikiMenu {Wiki::buildWikiMenu} {Wiki::postBuildMenu}
    menu::buildProc "Current Wiki" {
	menu::makeFlagMenu "Current Wiki" \
	  list wikiProject WikimodeVars {Wiki::rebuildMenu}
    }
    menu::buildProc "Wiki Favorites" {Wiki::buildFavoritesMenu} \
      {Wiki::postBuildFavorites}
    menu::buildProc "Wiki Projects" {Wiki::buildProjectsMenu} \
      {Wiki::postBuildProjects}
    menu::buildProc "Wiki Systems" {Wiki::buildSystemsMenu} \
      {Wiki::postBuildSystems}
    # Now build the menu.
    Wiki::rebuildMenu
    
    set menuInitialized 1
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::activateMenu" --
 # 
 # Called when the Wiki Menu is (de)activated.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::activateMenu {which} {
    
    global wikiMenu global::features
    
    variable menuActivated
    
    if {($which == $menuActivated)} {
	return
    } elseif {$which} {
	# We're being turned on.
	catch {loadAMode "Wiki"}
	set cmd "register"
    } else {
	# We're being turned off.
	set cmd "deregister"
    }
    if {!$which || ([lsearch -exact $global::features "wikiMenu"] > -1)} {
	set menuItems [list "Save To Web" "Save In BrowserÉ" \
	  "Wiki Paragraph" "Wiki Line" "Wiki Text"]
	foreach menuItem $menuItems {
	    hook::$cmd requireOpenWindowsHook [list $wikiMenu $menuItem] 1
	    hook::$cmd changeMode {Wiki::changeModeHook}
	}
    }
    set menuActivated $which
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::activateHook"  ---
 # 
 # Auto-adjust the current Project when a Wiki page is brought to the front.
 # This helps ensure that saving the window works properly, using the
 # variables associated with that project.
 # 
 # --------------------------------------------------------------------------
 ## 

proc Wiki::activateHook {winName} {
    
    global wikiMenu WikimodeVars
    
    variable editWindows
    variable postWindows
    
    set project [Wiki::findWindowProject $winName]
    if {($project eq "")} {
        set project "default"
    }
    if {($project ne $WikimodeVars(wikiProject))} {
	Wiki::currentProject $project
	menu::buildSome "Current Wiki"
	menu::buildSome "Wiki Favorites"
	Wiki::postBuildMenu
    }
    if {![info exists postWindows($winName)]} {
	set dim1 0
    } else {
	set dim1 $postWindows($winName)
    }
    set dim2 [expr {[info exists editWindows($winName)]}]
    enableMenuItem -m $wikiMenu "Save To Web"           $dim1
    enableMenuItem -m $wikiMenu "Save In BrowserÉ"      $dim2
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::changeModeHook" --
 # 
 # Dim/enable menu items based on switching into/out of Wiki mode.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::changeModeHook {args} {
    
    global wikiMenu
    
    set dim [expr {([lindex $args end] eq "Wiki")}]
    set menuItems [list "Save To Web" "Save In BrowserÉ" \
      "Wiki Paragraph" "Wiki Line" "Wiki Text"]
    foreach menuItem $menuItems {
	enableMenuItem -m $wikiMenu $menuItem $dim
    }
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× The Wiki Menu ×××× #
# 

proc Wiki::buildWikiMenu {} {
    
    global wikiMenu alpha::macos alpha::platform WikimodeVars
    
    Wiki::currentProject
    
    if {($project eq "") || ($project eq "default")} {
	set Project "Project"
    } else {
	set Project $project
    }
    # Wiki Text items.
    set itemNames [list "bold" "italics" "unquote"]
    foreach itemName $itemNames {
	if {[info exists WikimodeVars($itemName)]} {
	    lappend textItems $WikimodeVars($itemName)$itemName
	} else {
	    lappend textItems $itemName
	}
    }
    # Wiki Line items.
    set itemNames [list "horizontalLine" "bulletListItem" "numberedItem"]
    foreach itemName $itemNames {
	if {[info exists WikimodeVars($itemName)]} {
	    lappend lineItems $WikimodeVars($itemName)$itemName
	} else {
	    lappend lineItems $itemName
	}
    }
    if {($alpha::platform eq "alpha")} {
	lappend lineItems \
	  "<E<S$WikimodeVars(verbatim/unverbatim)verbatim" \
	  "<S<I$WikimodeVars(verbatim/unverbatim)unverbatim"
    } else {
	lappend lineItems \
	  "$WikimodeVars(verbatim)verbatim" \
	  "$WikimodeVars(unverbatim)unverbatim"
    }
    # Wiki Paragraph items.
    set itemNames [list "prevParagraph" "nextParagraph"  "selectParagraph" \
      "reformatParagraph"]
    foreach itemName $itemNames {
	if {[info exists WikimodeVars($itemName)]} {
	    lappend paragraphItems $WikimodeVars($itemName)$itemName
	} else {
	    lappend paragraphItems $itemName
	}
    }
    # Create the menu list.
    set menuProc "Wiki::menuProc"
    set menuList [list \
      "$WikimodeVars(editWikiPage)Edit Wiki PageÉ" \
      "Save To Web" \
      "Save In BrowserÉ" \
      "Review Last PostÉ" "(-)" \
      "$WikimodeVars(projectHomePage)$Project Home" \
      [list Menu -n "Wiki Favorites"    -M Wiki [list]] \
      [list Menu -n "Current Wiki"      -M Wiki [list]] \
      [list Menu -n "Wiki Projects"     -M Wiki [list]] \
      "(-)" \
      [list Menu -n "Wiki Text"         -M Wiki -p $menuProc $textItems] \
      [list Menu -n "Wiki Line"         -M Wiki -p $menuProc $lineItems] \
      [list Menu -n "Wiki Paragraph"    -M Wiki -p $menuProc $paragraphItems] \
      "$WikimodeVars(formattingRules)Formatting Rules" \
      "(-)" \
      [list Menu -n "Wiki Systems"      -M Wiki [list]] \
      "Wiki Menu PrefsÉ" "/t<BWiki Menu Help" \
      ]
    append menuProc " -m"
    if {$WikimodeVars(enableShortcutsInWikiModeOnly)} {
        append menuProc " -M Wiki"
    }
    set subMenus [list "Wiki Favorites" "Current Wiki" "Wiki Projects" \
      "Wiki Systems"]
    # Now we return the list of items for [menu::buildSome].
    return [list build $menuList $menuProc $subMenus $wikiMenu]
}

proc Wiki::postBuildMenu {args} {
    
    global wikiMenu WikimodeVars
    
    # Create variables based on current project.
    set project $WikimodeVars(wikiProject)
    if {($project eq "") || ($project eq "default")} {
	set Project "Project"
    } else {
	set Project $project
    }
    foreach field [list "projectHome" "formatting"] {
	set $field [Wiki::projectField $project $field]
    }
    # Create "dim" variables.
    set dim1 [expr {[Wiki::httpAvailable 0]}]
    set dim2 [expr {($projectHome ne "")}]
    set dim3 [expr {($formatting ne "")}]
    # Dim/enable as appropriate.
    enableMenuItem -m $wikiMenu "Edit Wiki PageÉ"          $dim1
    enableMenuItem -m $wikiMenu "$Project Home"            $dim2
    enableMenuItem -m $wikiMenu "Formatting Rules"         $dim3
    Wiki::enableReview
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::enableReview" --
 # 
 # Called by the [trace] placed on "lastPostedText", dim/enable the menu 
 # command "Wiki Menu > Review Last Post".  This is wrapped in a [catch] in 
 # case the menu isn't active.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::enableReview {args} {
    
    global wikiMenu
    
    variable lastPostedText
    
    set dim [expr {([string length $lastPostedText] > 0)}]
    catch {enableMenuItem $wikiMenu "Review Last PostÉ" $dim}
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::rebuildMenu" --
 # 
 # Rebuild the "Wiki Menu".  Because this will be called by various routines,
 # including when the user selects "Wiki Menu > Current Wiki" item to change
 # the Current Project, we go to some trouble to really ensure that items are
 # properly dimmed/enabled according to the current window context.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::rebuildMenu {args} {
    
    variable prefProjects [Wiki::listProjects -2]
    
    menu::buildSome wikiMenu
    
    if {([lindex $args 0] eq "saveInBrowser")} {
        alertnote "Note: Unlike the other Wiki shortcut preferences, the one\
	  for \"Save In Browser\" will not appear in the menu.  It will,\
	  however, be active for all Wiki page editing windows."
	return
    }
    if {[llength $args]} {
	set arg [lindex $args 0]
	Wiki::currentProject
	if {($arg eq "project") || [lcontains projects $arg]} {
	    status::msg "The current Wiki project is now '$project'"
	} else {
	    status::msg "The Wiki Menu has been rebuilt."
	}
    }
    set numWins [llength [winNames]]
    foreach i [hook::information requireOpenWindowsHook $numWins] {
	catch {eval enableMenuItem $i $numWins}
    }
    Wiki::changeModeHook [win::getMode]
    return
}

# ===========================================================================
# 
# ×××× Wiki Menu support ×××× #
# 

proc Wiki::menuProc {menuName menuItem} {
    
    global wikiMenu
    
    variable lastPostedText
    variable editWindows
    
    Wiki::currentProject
    if {($project eq "") || ($project eq "default")} {
        set Project "Project"
    } else {
        set Project $project
    }
    if {($menuName eq $wikiMenu)} {
	set menuName "Wiki Menu"
    }
    switch -- $menuName {
	"Wiki Menu" {
	    if {($menuItem eq "$Project Home")} {
		set url [Wiki::projectField $project "projectHome"]
		if {($url eq "")} {
		    # Item should have been dimmed.
		    Wiki::postBuildMenu
		    error "Cancelled -- no home page defined."
		} else {
		    Wiki::viewUrl $url
		    return
		}
	    }
	    switch -- $menuItem {
		"Edit Wiki Page" {
		    Wiki::editWikiPage
		}
		"Save To Web" {
		    # Note: a normal 'save' will always save to web if possible.
		    set name [win::Current]
		    if {![info exists editWindows($name)]} {
			alertnote "This page was not fetched from a Wiki site, \
			  and cannot be saved to the web."
			error "Cancelled -- window cannot be saved to web."
		    }
		    if {![win::getInfo [win::Current] dirty]} {
			setWinInfo dirty 1
		    }
		    menu::fileProc "" "save"
		}
		"Save In Browser" {
		    Wiki::saveInBrowser
		}
		"Review Last Post" {
		    if {![info exists lastPostedText] || ($lastPostedText eq "")} {
		        alertnote "There is no \"last post\" text to review."
			return
		    }
		    set title "* Last Post Text *"
		    set w [new -n $title -mode "Text" -text $lastPostedText]
		    winReadOnly $w
		    alertnote "This window contains the text which the Wiki Menu\
		      most recently attempted to post to the remote server."
		}
		"Formatting Rules" {
		    set url [Wiki::projectField $project "formatting"]
		    if {($url eq "")} {
			# Item should have been dimmed.
			Wiki::postBuildMenu
			error "Cancelled -- no formatting page defined."
		    } else {
			Wiki::viewUrl $url
		    }
		}
		"Wiki Menu Prefs" {
		    loadAMode "Wiki"
		    prefs::dialogs::modePrefs "Wiki" "Wiki Menu Preferences"
		}
		"Wiki Menu Help" {
		    help::openGeneral "Wiki Menu Help"
		}
		default {
		    error "Cancelled -- Unknown menu item: $menuItem"
		}
	    }
	}
	"Wiki Paragraph" {
	    switch -- $menuItem {
		"horizontalLine" -
		"bulletListItem" -
		"numberedItem"      {Wiki::blockTag $menuName $menuItem}
		"verbatim" -
		"unverbatim"        {Wiki::verbatimText $menuItem}
		"prevParagraph"     {function::prev}
		"nextParagraph"     {function::next}
		"selectParagraph"   {function::select}
		default             {Wiki::${menuItem}}
	    }
	}
	"Wiki Line" {
	    switch -- $menuItem {
		"horizontalLine" -
		"bulletListItem" -
		"numberedItem"      {Wiki::blockTag $menuName $menuItem}
		default             {Wiki::${menuItem}}
	    }
	}
	"Wiki Text" {
	    switch -- $menuItem {
		"bold" -
		"italics" -
		"unquote"           {Wiki::textTag $menuItem}
		default             {Wiki::$menuItem}
	    }
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::editWikiPage" --
 # 
 # Offer a dialog to the user to fetch a remote wiki page.  If there are any
 # defined Favorites associated with the Current Wiki Project, those are
 # offered in an initial dialog.
 # 
 # If the user chooses to enter a url, the home page of the current project
 # is the initial default url presented, though the page in the browser can
 # now be used.  All future calls will use the last entered url as the
 # default.  We take care of the url format here, which allows us to
 # determine the proper url for a rendered wiki page.
 # 
 # Returns the name of the window which was just created.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::editWikiPage {{url ""}} {
    
    variable Favorites
    variable userChangedProject 0
    
    Wiki::httpAvailable 1
    Wiki::currentProject
    
    set enterOption "Enter UrlÉ"
    if {($url eq "")} {
	if {![llength $Favorites($project)]} {
	    set url $enterOption
	} else {
	    set options [list]
	    foreach favorite $Favorites($project) {
		lappend options [lindex $favorite 0]
	    }
	    set options [lsort -dictionary $options]
	    set options [linsert $options 0 $enterOption "-"]
	    set txt1 "You can edit a wiki page from your list of favorite\
	      pages for your $project project, or enter the url directly\
	      of the page you wish to edit."
	    if {![catch {url::browserWindow}]} {
		append txt1 "  (You will have the option\
		  to choose the url of the frontmost browser window.)\r"
	    }
	    append txt1 "\r"
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
	    set dialogScript [list dialog::make -title "Edit Wiki Page" \
	      -width 450 \
	      -ok "Continue" \
	      -addbuttons $buttons \
	      [list "" \
	      [list "text" $txt1] \
	      [list [list "menu" $options] "Wiki Page Options:" \
	      [lindex $options 0]] \
	      ]]
	    if {($project ne "") && ($project ne "default")} {
		status::msg "Your current Wiki Project is \"$project\""
	    }
	    if {[catch {eval $dialogScript} results]} {
		if {$userChangedProject} {
		    return [Wiki::editWikiPage]
		} else {
		    error "Cancelled."
		}
	    }
	    if {([set url [lindex $results 0]] ne $enterOption)} {
		foreach favorite $Favorites($project) {
		    if {($url eq [lindex $favorite 0])} {
			set url [lindex $favorite 1]
			break
		    }
		}
	    }
	}
    }
    if {($url eq "")} {
	set url $enterOption
    }
    if {($url eq $enterOption)} {
	set p  "Please type your url, or use one of the buttons below"
	set defaultUrl [Wiki::urlForDialog]
	if {[catch {dialog::getUrl $p $defaultUrl} url]} {
	    error "cancel"
	} elseif {($url eq "")} {
	    error "Cancelled -- nothing was entered."
	}
    }
    set results [Wiki::editFromUrl $url]
    Wiki::urlForDialog [lindex $results 1]
    return [lindex $results 0]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::saveInBrowser" --
 # 
 # Collect the text in the active window and place it in the Clipboard so
 # that the user can paste it into the form field in the web page opened in
 # the browser.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::saveInBrowser {} {
    
    variable editWindows
    variable lastPostedText
    
    set w [win::Current]
    if {![info exists editWindows($w)]} {
        error "Cancelled -- \"[win::Tail $w]\" is not an editing window\
	  from a remote Wiki server."
    }
    set windowText [getText -w $w [minPos -w $w] [maxPos -w $w]]
    if {($windowText eq "")} {
        error "Cancelled -- $WinName doesn't contain any text!"
    }
    status::msg "Editing url: <$editWindows($w)>"
    set q "The text from the active window will be placed in the Clipboard,\
      and the original Wiki page editing url will be opened in your browser.\
      You can then paste it in the appropriate form field."
    if {![dialog::yesno -y "Continue" -n "Cancel" $q]} {
        error "Cancelled."
    }
    putScrap $windowText
    set lastPostedText $windowText
    win::setInfo $w dirty 0
    url::execute $editWindows($w)
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::urlForDialog" --
 # 
 # Manages default urls appropriate to the Current Wiki Project.  In general,
 # we assume that the last url selected by the the user will always be closer
 # to what the next choice will be than anything else we can provide, so we 
 # remember which urls were chosen for the current project.
 # 
 # If no "url" is supplied, we return the last url selected, defaulting to
 # the project's home page if this is the first time we're called.  If "url"
 # is supplied, that will be remembered for the next round.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::urlForDialog {{url ""}} {
    
    variable dialogDefaultUrls
    
    Wiki::currentProject
    
    if {![info exists dialogDefaultUrls($project)]} {
	array set tagTypes $settings
	set dialogDefaultUrls($project) $tagTypes(projectHome)
    }
    if {($url eq "")} {
	return $dialogDefaultUrls($project)
    } elseif {($project eq "default") \
      || [Wiki::validateUrlForProject $url $project 0]} {
	set dialogDefaultUrls($project) $url
	prefs::modified dialogDefaultUrls($project)
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::viewUrl" --
 # 
 # Users have the option to always use the WWW Menu for viewing urls, or to 
 # use the global "viewURL" service.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::viewUrl {url} {
    
    global WikimodeVars
    
    if {$WikimodeVars(useWWWMenuForViewing) \
      && [alpha::package exists "wwwMenu"]} {
	WWW::renderUrl $url
    } else {
	urlView $url
    }
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Editing Support ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::blockTag" --
 # 
 # Automatically insert a tag at the start of the block in which the cursor
 # currently resides.  Any previously highlighted selection is preserved. 
 # Tags can be inserted at the start of either the block or the current line.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::blockTag {menuName tagType} {
    
    Wiki::currentProject
    array set tagTypes $settings
    
    # Determine the tag to be inserted, with some special cases.
    if {[info exists tagTypes($tagType)]} {
	set tag [lindex $tagTypes($tagType) 0]
    } else {
	error "Cancelled -- unknown tag type: $tagType"
    }
    set posBeg [getPos]
    set posEnd [selEnd]
    set len1   [pos::diff $posBeg $posEnd]
    switch $menuName {
	"Wiki Paragraph" {set pos0 [Wiki::blockBeg $posBeg]}
	"Wiki Line"      {set pos0 [pos::lineStart $posBeg]}
	default          {error "Unknown menu name: $menuName"}
    }
    set len2 [pos::diff $pos0 $posBeg]
    set pos1 [text::firstNonWsLinePos $pos0]
    set len3 [expr {abs([pos::diff $pos0 $pos1])}]
    # Replace the text, inserting the mark chars in front.  Can't simply
    # use 'replaceText' to insert the tag because Alpha7/8 won't properly
    # interpret a carriage return (glyph).
    replaceText $pos0 $pos1 ""
    goto $pos0
    insertText $tag
    goto [pos::math $pos0 + $len2 - $len3 + [string length $tag]]
    # Now re-hilite any original selection.
    selectText [getPos] [pos::math [getPos] + $len1]
    if {($menuName eq "Wiki Paragraph")} {
	Wiki::reformatParagraph
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::definitionItem" --
 # 
 # Delete any highlighted text, strip any whitespace surrounding the cursor,
 # insert the closing tag, and ensure that the beginning of the block
 # contains the open tag.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::definitionItem {} {
    
    Wiki::currentProject
    array set tagTypes $settings
    
    set openTag  [lindex $tagTypes(definitionItem) 0]
    set closeTag [lindex $tagTypes(definitionItem) 1]
    # If we're not in a paragraph block, life is easy.
    if {![lindex [function::inFunction [getPos]] 0]} {
	if {[isSelection]} {
	    deleteSelection
	}
	replaceText [set pos [pos::lineStart]] [pos::lineEnd $pos] ""
	insertText ${openTag}${closeTag}
	return
    }
    # Remove all of the spaces potentially between two words, and insert
    # the closing tag.
    set pos0 [getPos] ; set pos1 [selEnd]
    while {[regexp "\[\t \]" [getText $pos1 [pos::nextChar $pos1]]]} {
	set pos1 [pos::nextChar $pos1]
    }
    while {[regexp "\[\t \]" [getText [pos::prevChar $pos0] $pos0]]} {
	set pos0 [pos::prevChar $pos0]
    }
    replaceText $pos0 $pos1 $closeTag
    # Strip any leading indentation, and insert the open tag.
    set pos0 [Wiki::blockBeg [set pos [getPos]]]
    set pos1 [text::firstNonWsLinePos $pos0]
    set len1 [pos::diff $pos0 $pos]
    set len2 [expr {abs([pos::diff $pos0 $pos1])}]
    set len3 [string length $openTag]
    replaceText $pos0 $pos1 $openTag
    goto [pos::math $pos0 + $len1 - $len2 + $len3]
    status::msg "The 'definition' should be contained on one logical line."
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::verbatimText" --
 # 
 # Indent the entire block of text using the verbatim string, or remove all
 # spaces found in the first line of the block.  Retains any original
 # selection.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::verbatimText {tagType} {
    
    # Set the tag to be inserted/removed.
    switch -- $tagType {
	"verbatim" {
	    Wiki::currentProject
	    array set tagTypes $settings
	    set openTag [lindex $tagTypes($tagType) 0]
	}
	"unverbatim" {
	    set pos0 [Wiki::blockBeg [getPos]]
	    set pos1 [text::firstNonWsLinePos $pos0]
	    set openTag [getText $pos0 $pos1]
	}
	default {error "Unknown tagtype: $tagType"}
    }
    # Preliminaries, remembering positions for later.
    set len1 [pos::diff [set pos0 [getPos]] [set pos1 [selEnd]]]
    set row0 [lindex [pos::toRowCol $pos0] 0]
    set row1 [lindex [pos::toRowCol $pos1] 0]
    set len2 [expr {($row1 - $row0) * [string length $openTag]}]
    if {![isSelection]} {
	function::select
    } else {
	selectText [Wiki::blockBeg [getPos]] [Wiki::blockEnd [selEnd]]
    }
    set memory [::paragraph::rememberWhereYouAre [set start [getPos]] $pos0 [selEnd]]
    # Change the prefix string, and (un)comment.
    global prefixString
    set oldPS $prefixString ; set prefixString $openTag
    switch $tagType {
	"verbatim"   {insertPrefix}
	"unverbatim" {removePrefix}
    }
    set prefixString $oldPS
    # Try to rehilite any previous selection.
    ::paragraph::goBackToWhereYouWere $start \
      [pos::math $start + [string length [getText $start [getPos]]]] $memory
    switch $tagType {
	"verbatim"   {selectText [getPos] [pos::math [getPos] + $len1 + $len2]}
	"unverbatim" {selectText [getPos] [pos::math [getPos] + $len1 - $len2]}
    }
    # Finish up.
    status::msg "Text is now $tagType"
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Wiki::textTag" --
 # 
 # Automatically insert a tag around the word surrounding the cursor, first
 # removing any similar tag characters surrounding the word if necessary. 
 # Retains any original selection.
 # 
 # --------------------------------------------------------------------------
 ##

proc Wiki::textTag {tagType} {
    
    Wiki::currentProject
    array set tagTypes $settings
    
    # Set the open/close tags.
    if {$tagType == "unquote"} {
	set openTag [set closeTag "'"]
    } elseif {[info exists tagTypes($tagType)]} {
	set openTag  [lindex $tagTypes($tagType) 0]
	set closeTag [lindex $tagTypes($tagType) 1]
    } else {
	error "Cancelled -- unknown tag type: $tagType"
    }
    # Preliminary position information.
    set pos  [getPos]
    set len1 [string length [getSelect]]
    eval selectText [text::surroundingWord]
    set word [getSelect]
    set len2 [pos::diff [set pos0 [getPos]] [set pos1 [selEnd]]]
    while {[regexp \\[lookAt [pos::prevChar $pos0]] $openTag]} {
	set pos0 [pos::prevChar $pos0]
    }
    while {[regexp \\[lookAt $pos1] $closeTag]} {
	set pos1 [pos::nextChar $pos1]
    }
    # Add the tag, and try to rehilite any previous selection.
    replaceText $pos0 $pos1 $word
    selectText $pos0 [pos::math $pos0 + [string length $word]]
    if {$tagType == "unquote"} {
	set openTag [set closeTag ""]
	set msg "'$word' has been unquoted."
    } elseif {[elec::Wrap ${openTag} ${closeTag}]} {
	set msg "'$word' has been set in $tagType."
    } else {
	set msg "Enter text to be set in $tagType."
    }
    set pos0 [pos::math $pos0 + $len2 + [string length $openTag]]
    set pos1 [pos::math $pos0 + $len1]
    selectText $pos0 $pos1
    status::msg $msg
    return
}

# ===========================================================================
# 
# .