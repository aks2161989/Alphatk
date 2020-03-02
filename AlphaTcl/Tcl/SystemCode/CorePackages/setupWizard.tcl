## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "setupWizard.tcl"
 #                                          created: 02/29/2000 {09:40:40 AM}
 #                                      last update: 05/24/2006 {09:46:53 AM}
 # Description:
 #  
 # Creates a series of dialogs that allows the user to perform some initial
 # configuration of features, menus, basic preferences, etc.
 #  
 # Each dialog item has been constructed so that you can just evaluate its
 # procedure name in order to test it.  See the notes below preceding the
 # [setupAssistant::userSetup] procedure for more information about how each
 # dialog should be constructed.
 #  
 # Author: Vince Darley
 # E-mail: vince@santafe.edu
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501
 #    www: <http://www.santafe.edu/~vince/>
 #  
 # Include contributions from Craig Barton Upright
 #  
 # Copyright (c) 2000-2006 Vince Darley, Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

proc setupWizard.tcl {} {}

## 
 # --------------------------------------------------------------------------
 # 
 # "namespace eval setupAssistant" --
 # 
 # Set up some variables that are used throughout the procedures below.  The
 # "cancel" error string is a "real" cancel, suggesting that we should just
 # abort the rest of the setup routine.  The "width" variable helps keep all
 # of the dialogs unified in appearance.
 # 
 # We define "title" just so that developers can easily test any of the
 # procedures below by evaluating their names.  It is reset to the correct
 # values when [setupAssistant::userSetup] is called.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval setupAssistant {
    
    variable Alpha [set ::alpha::application]
    variable backError "goBackOneStep"
    variable backButton [list "Go Back" \
      "Click here to go back to the previous step." \
      "set retVal $backError ; set retCode 1"]
    variable continueHelpTag "Click here to go to the next step."
    variable postponeHelpTag "Click here to exit the Setup Assistant.\
      You can revisit it later by selecting the command\
      \"Config > Global Setup > Setup Assistant\"."
    variable step 1
    variable title "$Alpha Setup Assistant"
    variable width 500
}

## 
 # --------------------------------------------------------------------------
 # 
 # "setupAssistant" --  ?oldversions? ?newversions?
 # 
 # This is called each time the user upgrades Alpha or AlphaTcl.
 #  
 # 'oldversions' is a list containing the previous version numbers of Alpha
 # and AlphaTcl this user was using.
 #  
 # 'newversions' is a list for the current versions.
 #  
 # We can use these lists to decide which setup wizards to run.
 #  
 # Note: if the user has _never_ used Alpha before, then 'oldversions' will
 # be an empty list.  If both arguments are empty, the user has called the
 # assistant manually by using the Config menu item.
 # 
 # Dialog Buttons:
 # 
 # Each setup step (dialog) should use "Continue" as the default button, and
 # include a Cancel button that will abort the setup.  Each must also include
 # a button to perform the action which is offered, "Apply" "Download" etc.
 # Even though we might think that the proposed dialog action is perfectly
 # reasonable and useful, we require the user to explicitly decide to take
 # it.  If the button is recursive, be sure to include that information in
 # the dialog, or otherwise make it perfectly clear what happens when this
 # button is pressed.  As a reminder, each button needs (1) a name, (2) a
 # balloon help string, and (3) a script to be evaluated when the button is
 # pressed.
 # 
 # --------------------------------------------------------------------------
 # 
 # To do: ?
 #  
 # * Add some dialogs for particular uses, e.g. the three main uses of Alpha
 # are probably:
 # 
 # (1) Programming in C/C++/Java
 # (2) Writing documents in LaTeX/BibTeX
 # (3) Writing HTML
 # 
 # --------------------------------------------------------------------------
 ##

proc setupAssistant {args} {
    eval setupAssistant::userSetup $args
    return
}

proc setupAssistant::userSetup {{oldversions ""} {newversions ""}} {

    global tcl_platform
    
    variable Alpha
    variable backError
    variable step 0
    variable startup
    variable title
    variable userName ""
    
    if {[string length $oldversions] || [string length $newversions]} {
	set startup 1
    } else {
	set startup 0
    }
    set pages [list "welcome" "identity" \
      "windowsGroup" "windowsAssociateFileTypes" \
      "keyboardFont" "usualFeatures" "usualMenus" "specialKeys" \
      "helpPreferences" "filesets" "webInformation" "helpfulHints"]
    
    set ignorePages [list]
    if {[alpha::package exists "identities"]} {
	set userName [userInfo::getInfo "author"]
    } else {
	lappend ignorePages "identity"
    }
    if {($tcl_platform(platform) ne "windows")} {
	lappend ignorePages "windowsGroup" "windowsAssociateFileTypes"
    }
    if {$startup} {
        lappend ignorePages "webInformation"
    }
    set pages [lremove -- $pages $ignorePages]
    set steps [expr {[llength $pages] - 2}]
    for {set i 0} {($i < [llength $pages])} {incr i} {
	set title "$Alpha Setup Assistant"
	set page [lindex $pages $i]
	if {($page eq [lindex $pages end])} {
	    append title " - Done!"
	} elseif {($step > 0)} {
	    append title " - Step " $step " of " $steps
	}
	if {![catch {setupAssistant::$page} result]} {
	    incr step
	} elseif {($result eq $backError)} {
	    incr i -2
	    incr step -1
	    continue
	} elseif {($result eq "cancel")} {
	    break
	} else {
	    # ???
	    dialog::alert "Dialog error ($page):\r\r$result"
	}
    }
    # Make sure that we've updated any feature set/preference changes.
    prefs::saveNow
    # Only update the package file if we weren't called manually
    if {$startup} {
	# Update the "Packages" help file, then close it.
	catch {global::listPackages 1}
    }
    status::msg "Setup complete."
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "setupAssistant::welcome" --
 # 
 # Give some explanatory information about what the Setup Assistant is going
 # to offer, and give the user a chance to exit now.  We adjust the text
 # dependent upon whether this was called "manually" by the user or during
 # $Alpha's first launch.
 # 
 # --------------------------------------------------------------------------
 ##

proc setupAssistant::welcome {} {
    
    variable Alpha
    variable continueHelpTag
    variable postponeHelpTag
    variable startup
    variable title
    variable userName
    variable width
    
    set txt1 "Welcome to ${Alpha}'s Setup Assistant"
    set txt2 "Welcome back to ${Alpha}'s Setup Assistant"
    if {($userName ne "")} {
	append txt1 ", " [lindex $userName 0]
	append txt2 ", " [lindex $userName 0]
    }
    append txt1 "."
    append txt2 "."
    set txt3 "This assistant guides you through a few screens to help\
      configure ${Alpha}, such as turning on global features, menus,\
      creating filesets ... "
    set txt4 "all of which can be performed later as well when you become\
      more familiar with the program."
    set txt5 "You can cancel the Setup Assistant at any time, and revisit\
      it by selecting the \"Config > Global Setup > Setup Assistant\" menu item."

    if {$startup} {
	append intro $txt1 "\r" $txt3 $txt4 "\r" $txt5
	set cancelButton "Later"
    } else {
	append intro $txt2 "\r" $txt3
	set cancelButton "Cancel"
    }
    set dialogScript [list dialog::make -title $title -width $width \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancel $cancelButton \
      -cancelhelptag $postponeHelpTag \
      [list "" [list "text" $intro]]]
    return [eval $dialogScript]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "setupAssistant::identity" --
 # 
 # Offer the user an "Edit Identity" button to change current settings.
 # 
 # --------------------------------------------------------------------------
 ##

proc setupAssistant::identity {} {
    
    variable Alpha
    variable backButton
    variable continueHelpTag
    variable postponeHelpTag
    variable title
    variable userName
    variable width
    
    set txt1 "If you would like to provide $Alpha with some information\
      such as your e-mail address and web site, press the\
      \"Edit Identity\" button below.  This information is only used to\
      create user-specific document templates and is never shared\
      without your expressed consent.\r"
    set txt2 "You can use the \"Config > Preferences > Current Identity\"\
      menu to edit this information later, or to create new identities.\r"
    # Create an "Edit Identity" button.
    set button1 [list \
      "Edit Identity…" \
      "Click here edit your $Alpha identity." \
      [list catch {userInfo::identityDialog "edit"}]]
    set buttons [concat $button1 $backButton]
    # Now we create the dialog.
    set dialogScript [list dialog::make -title $title -width $width \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancel "Postpone" \
      -cancelhelptag $postponeHelpTag \
      -addbuttons $buttons \
      [list "$Alpha Identity" [list "text" $txt1] [list "text" $txt2]]]
    set caught [catch {eval $dialogScript} result]
    set userName [userInfo::getInfo "author"]
    if {!$caught} {
        return
    } else {
        error $result
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "setupAssistant::windowsGroup" --
 # 
 # Offer to create a new Program Manager group.
 # 
 # --------------------------------------------------------------------------
 ##

proc setupAssistant::windowsGroup {} {
    
    variable Alpha
    variable backButton
    variable continueHelpTag
    variable postponeHelpTag
    variable title
    variable width
    
    set txt "Would you like to create a Program Manager\
      group for ${Alpha}?  This way $Alpha will be\
      placed in your Start menu for easy access\r"
    # Create a "New PM Group" button.
    set button1 [list \
      "New PM Group" \
      "Click here create the new Program Manager group." \
      {set retVal {NPM} ; set retCode 0 ; {catch {windows::CreateGroup}}}]
    set buttons [concat $button1 $backButton]
    # Now we create the dialog.
    set dialogScript [list dialog::make -title $title -width $width \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancel "Postpone" \
      -cancelhelptag $postponeHelpTag \
      -addbuttons $buttons \
      [list "Program Manager Group" [list "text" $txt]]]
    return [eval $dialogScript]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "setupAssistant::installFonts" --
 # 
 # Offer a set of fonts to be downloaded and installed.  The user must click
 # on the "Download" button in order to fetch them.
 # 
 # Obsolete, and unused.  Considered unfriendly for the new user.
 # 
 # --------------------------------------------------------------------------
 ##

proc setupAssistant::installFonts {} {

    global alpha::macos tcl_platform downloadFolder ALPHA
    
    variable Alpha
    variable backButton
    variable continueHelpTag
    variable postponeHelpTag
    variable downloadFonts 0
    variable title
    variable width
    
    switch -- $tcl_platform(platform) {
	"macintosh" {
	    lappend fonts \
	      "ProFont" "ProFont-Distribution" \
	      http://www.tobiasjung.net/download.php?file=ProFont-Distribution-2.2.sit \
	      "Sheldon" "sheldonmac" \
	      http://www.tobiasjung.net/download.php?file=sheldonmac.sit
	}
	"windows" {
	    lappend fonts \
	      "ProFontWindows" PROFONT.FON \
	      http://www.tobiasjung.net/download.php?file=profontwin.zip \
	      "ProFontWindows truetype" ProFontWindows.ttf \
	      http://www.tobiasjung.net/download.php?file=MProFont.zip \
	      "Sheldon" sheldon.fon \
	      http://www.tobiasjung.net/download.php?file=sheldonwin.zip \
	      "Sheldon4" sheldon4.fon \
	      http://www.tobiasjung.net/download.php?file=sheldonwin.zip \
	}
	"unix" {
	    if {$alpha::macos == 2} {
		lappend fonts \
		  "ProFont" "ProFont-Distribution" \
		  http://www.tobiasjung.net/download.php?file=ProFont-Distribution-2.2.sit \
		  "Sheldon" "sheldonmac" \
		  http://www.tobiasjung.net/download.php?file=sheldonmac.sit
	    } else {
		lappend fonts \
		  "ProFont" "ProFontWindows*.pcf"\
		  http://www.tobiasjung.net/download.php?file=profontlinux.zip
	    }
	}
    }
    
    set txt1 "A number of good monospace fonts are available for\
      programmers.  $Alpha can download any of these so that you can\
      install them later in your OS.\r"
    set txt2 "Select the fonts you want to install,\
      then click the \"Download\" button.\r"
    set dialogPage [list "Programmer's fonts" [list "text" $txt1]]
    foreach {font namepat url} $fonts {
	lappend dialogPage [list flag $font 0]
	lappend urls $url
	lappend pats $namepat
    }
    lappend dialogPage [list "text" $txt2]
    # Create a "Download" button.
    set button1Script {
	set ::setupAssistant::downloadFonts 1 ;
	set retVal {Download} ;
	set retCode 0
    }
    set button1 [list \
      "Download" \
      "Click here download the selected fonts." \
      $button1Script]
    set buttons [concat $button1 $backButton]
    # Now we create the dialog.
    set dialogScript [list dialog::make -title $title -width $width \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancel "Postpone" \
      -cancelhelptag $postponeHelpTag \
      -addbuttons $buttons $dialogPage]
    if {[catch {eval $dialogScript} result]} {
	error $result
    } elseif {!$downloadFonts} {
	return
    }
    # Still here?  Download the selected fonts.
    foreach get $result puts $result url $urls pat $pats {
	if {$get} {
	    if {![info exists fetch] || [lsearch -exact $fetch $url] == -1} {
		lappend fetch $url
	    }
	    lappend file_pats $pat
	}
    }
    
    if {[info exists fetch]} {
        status::msg "Downloading desired fonts..."
	foreach url $fetch {
	    url::download $url
	}
        file::showInFinder $downloadFolder
	catch {switchTo $ALPHA}
	if {([llength $fetch] == 1)} {
	    set msg "The desired font was downloaded.  Please look for any\
          files matching $file_pats, and install it from there."
	} else {
	    set msg "The desired fonts were downloaded.  Please look for any\
          files matching $file_pats, and install them from there."
	}
        alertnote $msg
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "setupAssistant::windowsAssociateFileTypes" --
 # 
 # Associate file types with Alphatk.
 # 
 # --------------------------------------------------------------------------
 ##

proc setupAssistant::windowsAssociateFileTypes {} {
    
    variable Alpha
    variable associateFiles 0
    variable backButton
    variable continueHelpTag
    variable postponeHelpTag
    variable title
    variable width
    
    set txt "Would you like to associated certain file types with ${Alpha}?\
      This allows you to edit these types more easily.\r"
    # Create an "Associate File Types" button.
    set button1Script {
	set ::setupAssistant::associateFiles 1 ;
	set retVal {Associate} ;
	set retCode 0
    }
    set button1 [list \
      "Associate File Types" \
      "Click here download the selected fonts." \
      $button1Script]
    set buttons [concat $button1 $backButton]
    # Now we create the dialog.
    set menu [list menu [list none edit open]]
    set dialogScript [list dialog::make -title $title -width $width \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancel "Postpone" \
      -cancelhelptag $postponeHelpTag \
      -addbuttons $buttons \
      [list "File type associations"\
      [list "text" $txt]\
      [list $menu ".tcl" edit]\
      [list $menu ".java" open]\
      [list $menu ".txt" open]\
      [list $menu ".tex" open]\
      [list $menu ".c" open]\
      [list $menu ".cpp" open]\
      [list $menu ".html" edit]\
      [list $menu ".js" open]\
      [list $menu ".install" open]\
      [list var "Other file extensions for 'open'" ""]\
      [list var "Other file extensions for 'edit'" ""]\
      [list static "An 'open' action is when you double-click on a file"]\
      [list static "An 'edit' action can be selected when you right-click on\
      a file"]]]
    if {[catch {eval $dialogScript} result]} {
	error $result
    } elseif {!$associateFiles} {
	return
    }
    # Still here? Associate any file types as necessary.
    set edit {}
    set open {}
    set none {}
    set i    0
    foreach ext [list .tcl .java .txt .tex .c .cpp .html .js .install] {
	set action [lindex $result $i]
	lappend $action $ext
	incr i
    }
    eval lappend open [lindex $result $i]
    incr i
    eval lappend edit [lindex $result $i]
    
    # Now set the Windows file associations.
    foreach action {open edit} label {open "Edit With Alphatk"} {
	foreach ext [set $action] {
	    windows::AssociateActionWithAlphatk $ext $label
	}
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "setupAssistant::keyboardFont" --
 # 
 # --------------------------------------------------------------------------
 ##

proc setupAssistant::keyboardFont {} {
    
    global keyboard keyboards defaultFont fontSize alpha::fontList
    
    variable Alpha
    variable backButton
    variable continueHelpTag
    variable postponeHelpTag
    variable changeKeyboardFont 0
    variable title
    variable width
      
    # Dialog introduction.
     set txt1 "$Alpha maintains a \"keyboard\" setting that is independent\
       from any preference you might have set with your OS.  This setting\
       affects keyboard shortcuts that appear in drop-down menus, and helps ensure\
       that you can properly insert your desired text into open windows.\r"
     set txt2 "You can also set the default font and font-size that will\
       be used when creating new windows or opening windows that have no\
       font information saved for them.\r"
     set txt3 "You must press the \"Apply\" button to save any changes.\r"
    # Create an "Apply" button.
    set button1Script {
	set ::setupAssistant::changeKeyboardFont 1 ;
	set retVal {Apply} ;
	set retCode 0
    }
    set button1 [list \
      "Apply" \
      "Click here save any changed keyboard and font settings." \
      $button1Script]
    set buttons [concat $button1 $backButton]
    # Now we create the dialog.
    set dialogScript [list dialog::make -title $title -width $width \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancel "Postpone" \
      -cancelhelptag $postponeHelpTag \
      -addbuttons $buttons \
      [list "Keyboard & Fonts" \
      [list "text" $txt1] \
      [list [list "menu" [lsort -dictionary [array names keyboards]]] \
      "Keyboard :" $keyboard [help::prefString "keyboard"]] \
      [list "text" $txt2] \
      [list [list "menu" [lsort -dictionary ${alpha::fontList}]] \
      "Font Name :" $defaultFont [help::prefString "defaultFont"]] \
      [list [list "menu" [list "7" "8" "9" "10" "12" "14" "18" "20" "24" "30"]] \
      "Font Size :" $fontSize [help::prefString "fontSize"]] \
      [list "text" $txt3] \
      ]]
    if {[catch {eval $dialogScript} result]} {
	error $result
    } elseif {!$changeKeyboardFont} {
	return
    }
    # Still here? Turn on any features as necessary.
    set newKeyboard [lindex $result 0]
    if {($newKeyboard ne $keyboard)} {
        set keyboard $newKeyboard
	prefs::modified keyboard
	keys::keyboardChanged
	set changes 1
    }
    set newFont [lindex $result 1]
    if {($newFont ne $defaultFont)} {
	set defaultFont $newFont
	prefs::modified defaultFont
	set changes 1
    }
    set newSize [lindex $result 2]
    if {($newSize ne $fontSize)} {
	set fontSize $newSize
	prefs::modified fontSize
	set changes 1
    }
    if {[info exists changes]} {
	status::msg "The new settings have been saved."
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "setupAssistant::usualFeatures" --
 # 
 # Offer a set of default features to be turned on.  If the user selects the
 # "Apply" button then we turn on all of the items that have been checked.
 # (We don't turn off anything that isn't checked.)  If the "Continue" button
 # is selected, then we simply move on.
 # 
 # We could add this second "More Options" button
 # 
 #     set button2Script {
 #         if {![catch {prefs::dialogs::globalMenusFeatures "features"}]} {
 #             set retVal {return} ; set retCode 1
 #         } 
 #     }
 #     set button2 [list \
 #       "More Options…" \
 #       "Click here to choose from all installed features." \
 #       $button2Script]
 #     set buttons [concat $button1 $button2]
 # 
 # to offer the full-blown "Config > Global Setup > Features" dialog.
 # 
 # --------------------------------------------------------------------------
 ##

proc setupAssistant::usualFeatures {} {
    
    global global::features alpha::packageRequirementsFailed
    
    variable activatePackages 0
    variable Alpha
    variable backButton
    variable continueHelpTag
    variable postponeHelpTag
    variable title
    variable width
    
    set pkgOptions [list \
      "autoContinueComment" \
      "autoWrapComments" \
      "backup" \
      "emacs" \
      "macros" \
      "smartPaste" \
      ]
    foreach pkg $pkgOptions {
	set oldStatus($pkg) [lcontains global::features $pkg]
    }
    # Dialog introduction.
    set intro "$Alpha offers many extra features that you can turn on and\
      off to personalize your installation.\
      A few of the most common ones are listed below; \
      the initial checkbox reflects the current global activation status.\
      \r\rYou can always change your features later by selecting the\
      menu item \"Config > Global Setup > Features\".\r"
    # Create the dialog page.
    set dialogPage [list "Global Features" [list "text" $intro]]
    foreach pkg [lsort -dictionary $pkgOptions] {
	if {[lcontains alpha::packageRequirementsFailed $pkg]} {
	    continue
	} elseif {![alpha::package exists $pkg]} {
	    continue
	}
	set txt [quote::Prettify $pkg]
	if {([set description [help::itemDescription "" $pkg]] ne "")} {
	    append txt " : " $description
	}
	lappend dialogPage [list [list "smallall" "flag"] $txt $oldStatus($pkg)]
	lappend pkgNames $pkg
    }
    lappend dialogPage [list "text" \
      "You must press the \"Apply\" button to save any changes.\r"]
    # Create an "Apply" button.
    set button1Script {
	set ::setupAssistant::activatePackages 1 ;
	set retVal {Apply} ;
	set retCode 0
    }
    set button1 [list \
      "Apply" \
      "Click here turn on/off all of the features according\
      to their current checkbox status." \
      $button1Script]
    set buttons [concat $button1 $backButton]
    # Now we create the dialog.
    set dialogScript [list dialog::make -title $title -width $width \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancel "Postpone" \
      -cancelhelptag $postponeHelpTag \
      -addbuttons $buttons $dialogPage]
    if {[catch {eval $dialogScript} result]} {
	error $result
    } elseif {!$activatePackages} {
	return
    }
    # Still here? Turn on any features as necessary.
    foreach pkg $pkgNames newStatus $result {
	if {($newStatus eq $oldStatus($pkg))} {
	    continue
	} elseif {$newStatus} {
	    # Attempt to turn a package on.
	    package::makeOnOrOff $pkg "basic-on" "global"
	    lappend newPackages [quote::Prettify $pkg]
	} else {
	    # Attempt to turn a package off.
	    package::makeOnOrOff $pkg "basic-off" "global"
	}
    }
    if {[info exists newPackages]} {
	if {([llength $newPackages] == 1)} {
	    append msg {The package "} [lindex $newPackages 0] {" has }
	} else {
	    append msg {The package "} [join $newPackages ", "] {" have }
	}
	status::msg [append msg "been turned on."]
    }
    prefs::modified global::features
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "setupAssistant::usualMenus" --
 # 
 # Offer a set of default menus to be turned on.  If the user selects the
 # "Apply" button then we turn on all of the items that have been checked.
 # (We don't turn off anything that isn't checked.)  If the "Continue" button
 # is selected, then we simply move on.
 # 
 # We could add this second "More Options" button
 # 
 #     set button2Script {
 #         if {![catch {prefs::dialogs::globalMenusFeatures "menus"}]} {
 #             set retVal {return} ; set retCode 1
 #         } 
 #     }
 #     set button2 [list \
 #       "More Options…" \
 #       "Click here to choose from all installed features." \
 #       $button2Script]
 #     set buttons [concat $button1 $button2]
 # 
 # to offer the full-blown "Config > Global Setup > Menus" dialog.
 # 
 # --------------------------------------------------------------------------
 ##

proc setupAssistant::usualMenus {} {
    
    global global::features alpha::packageRequirementsFailed
    
    variable activatePackages 0
    variable Alpha
    variable backButton
    variable continueHelpTag
    variable postponeHelpTag
    variable title
    variable width
    
    set pkgOptions [list \
      "electricMenu" \
      "filtersMenu" \
      "ftpMenu" \
      "internetConfigMenu" \
      "macMenu" \
      "mailMenu" \
      "wwwMenu" \
      ]
    foreach pkg $pkgOptions {
	set oldStatus($pkg) [lcontains global::features $pkg]
    }
    # Dialog introduction.
    set intro "$Alpha also provides several extra menus that can\
      be inserted into the menubar alongside the standard File, Edit, etc.\
      menus.  A few of the most common optional menus are listed below;\
      the initial checkbox reflects the current global activation status.\
      \r\rYou can always change your menus later by selecting the\
      menu item \"Config > Global Setup > Menus\".\r"
    
    # Create the dialog page.
    set dialogPage [list "Global Menus" [list "text" $intro]]
    foreach pkg [lsort -dictionary $pkgOptions] {
	if {[lcontains alpha::packageRequirementsFailed $pkg]} {
	    continue
	} elseif {![alpha::package exists $pkg]} {
	    continue
	}
	set txt [quote::Prettify $pkg]
	if {([set description [help::itemDescription "" $pkg]] ne "")} {
	    append txt " : " $description
	}
	lappend dialogPage [list [list "smallall" "flag"] $txt $oldStatus($pkg)]
	lappend pkgNames $pkg
    }
    lappend dialogPage [list "text" \
      "You must press the \"Apply\" button to save any changes.\r"]
    # Create an "Apply" button.
    set button1Script {
	set ::setupAssistant::activatePackages 1 ;
	set retVal {Apply} ;
	set retCode 0
    }
    set button1 [list \
      "Apply" \
      "Click here turn on/off all of the menus according\
      to their current checkbox status." \
      $button1Script]
    set buttons [concat $button1 $backButton]
    # Now we create the dialog.
    set dialogScript [list dialog::make -title $title -width $width \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancel "Postpone" \
      -cancelhelptag $postponeHelpTag \
      -addbuttons $buttons $dialogPage]
    if {[catch {eval $dialogScript} result]} {
	error $result
    } elseif {!$activatePackages} {
	return
    }
    # Still here? Turn on/off any features as necessary.
    foreach pkg $pkgNames newStatus $result {
	if {($newStatus eq $oldStatus($pkg))} {
	    continue
	} elseif {$newStatus} {
	    # Attempt to turn a package on.
	    package::makeOnOrOff $pkg "basic-on" "global"
	    lappend newPackages [quote::Prettify $pkg]
	} else {
	    # Attempt to turn a package off.
	    package::makeOnOrOff $pkg "basic-off" "global"
	}
    }
    if {[info exists newPackages]} {
	if {([llength $newPackages] == 1)} {
	    append msg {The menu "} [lindex $newPackages 0] {" has }
	} else {
	    append msg {The menus "} [join $newPackages ", "] {" have }
	}
	status::msg [append msg "been turned on."]
    }
    prefs::modified global::features
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "setupAssistant::webInformation" --
 # 
 # Offer a set of potentially useful web sites.  If the user clicks on the
 # "Open Web Page" button then we first give an alert dialog with information
 # about the site, and then send the url corresponding the current item in
 # the pop-up menu to the local browser.
 # 
 # --------------------------------------------------------------------------
 ##

proc setupAssistant::webInformation {} {
    
    variable Alpha
    variable backButton
    variable continueHelpTag
    variable postponeHelpTag
    variable title
    variable webPages
    variable width
    
    # Create an array of web site {description [list message url]} items
    array set "webPages" [list \
      {AlphaTcl-users/developers mailing lists} \
      [list {You can sign up for the mailing lists at this web page} \
      {http://www.purl.org/net/alpha/mail}] \
      {AlphaTcl Home Page} \
      [list "This \"wiki\" site includes announcements and other information\
      about $Alpha and the AlphaTcl library." \
      {http://www.purl.org/net/alpha/wiki/}] \
      {Download Additional System Fonts} \
      [list {You can download additional system fonts from this web page} \
      {http://www.purl.org/net/alpha/wikipages/fonts}] \
      {Web based "Alpha-Bugzilla" bug reporting} \
      [list {You can bookmark the "Bugzilla" page for use later.} \
      {http://www.purl.org/net/alpha/bugzilla/}]]
    set webSites  [lsort -dictionary [array names webPages]]
    set defaultWS {AlphaTcl-users/developers mailing lists}
    # Dialog introduction
    set txt "$Alpha has an active and friendly mailing list for questions\
       and discussion.  Usually questions are answered within a day.  There\
       is also the collaboratively edited AlphaTcl Wiki web site, and the\
       bug-reporting web-page and database Bugzilla.\
       \rPress the \"Open Web Page\" button to visit any of these web pages\
       with your usual browser.\r"
    # Create an "Open Web Site" button.
    set dialogPageName "$Alpha Internet Resources"
    set button1Script {
	set webSite    [dialog::valGet $dial "NAME,Web Sites"]
	set messageUrl [set ::setupAssistant::webPages($webSite)]
	if {1 || [dialog::yesno -y "OK" -n "Cancel" [lindex $messageUrl 0]]} {
	    url::execute [lindex $messageUrl 1]
	    catch {switchTo $::ALPHA}
	}
    }
    regsub -all -- {NAME} $button1Script $dialogPageName button1Script
    set button1 [list \
      "Open Web Page" \
      "Click here open the current pop-up menu web page in your browser;\
      you can then bookmark it if you find it useful." \
      $button1Script]
    set buttons [concat $button1 $backButton]
    # Now we create the dialog.
    set dialogScript [list dialog::make -title $title -width $width \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancel "Postpone" \
      -cancelhelptag $postponeHelpTag \
      -addbuttons $buttons \
      [list $dialogPageName \
      [list "text" $txt] \
      [list [list "menu" $webSites] "Web Sites" $defaultWS \
      "These are some of the most useful $Alpha and AlphaTcl web sites."]]]
    if {[catch {eval $dialogScript} result]} {
	error $result
    } else {
	return
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "setupAssistant::alphaDeveloper" --
 # 
 # Offer various "Alpha Developer" items.  These will only be enabled if the
 # user clicks on the "Apply" button.
 # 
 # Obsolete, and unused.  Considered unfriendly for the new user.
 # 
 # --------------------------------------------------------------------------
 ##

proc setupAssistant::alphaDeveloper {} {
    
    global global::features
    
    variable activatePackages 0
    variable Alpha
    variable backButton
    variable continueHelpTag
    variable postponeHelpTag
    variable title
    variable width
    
    set txt1 "If you are comfortable with Tcl and wish to develop add-ons\
      to $Alpha (new modes, menus, features, etc.),\
      check the following items.\r"
    set txt2 "Click on the \"Apply\" button to enable these items.\r"
    # Create an "Apply" button.
    set button1Script {
	set ::setupAssistant::activatePackages 1 ;
	set retVal {Apply} ;
	set retCode 0
    }
    set button1 [list \
      "Apply" \
      "Click here activate the selected items." \
      $button1Script]
    set buttons [concat $button1 $backButton]
    # Now we create the dialog.
    set dialogScript [list dialog::make -title $title -width $width \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancel "Postpone" \
      -cancelhelptag $postponeHelpTag \
      -addbuttons $buttons \
      [list "AlphaTcl Developer Items" \
      [list "text" $txt1] \
      [list "flag" {Turn on the "Alpha Developer Menu"} 1] \
      [list "flag" {Create AlphaTcl Filesets for Modes, Menus, etc.} 1] \
      [list "text" $txt2]]]
    if {[catch {eval $dialogScript} result]} {
	error $result
    } elseif {!$activatePackages} {
	return
    }
    # Still here? Turn on any features as necessary.
    if {[lindex $result 0] && ![lcontains global::features "alphaDeveloperMenu"]} {
	if {[package::active "alphaDeveloperMenu"]} {
	    # This package must already be activated just by a mode.
	    lappend global::features "alphaDeveloperMenu"
	    prefs::modified global::features
	} else {
	    # This will take care of saving preferences.
	    package::makeOnOrOff "alphaDeveloperMenu" "basic-on" "global"
	}
    }
    if {[lindex $result 1]} {
	alphadev::rebuildFilesets
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "setupAssistant::filesets" --
 # 
 # Allow the user to create any number of filesets.  Some of the most basic
 # ones are described, if the user clicks on the "New Fileset" button the we
 # call the appropriate AlphaTcl procedure, and then return to the dialog.
 # 
 # --------------------------------------------------------------------------
 ##

proc setupAssistant::filesets {} {
    
    variable Alpha
    variable backButton
    variable continueHelpTag
    variable postponeHelpTag
    variable title
    variable width
    
    set txt "$Alpha uses 'filesets' to group related files.\
      \rFilesets provide an easy way to open, edit, search,\
      and manipulate all files in the set.\
      Filesets can be created by various criteria, including\
      \r• All files in a directory\
      \r• All files in a hierarchy\
      \r• All files from a multi-part LaTeX document\
      \r• All files at an ftp site (edit them as if they were local:\
      they are automatically up/downloaded!)\
      \r\rCreate as many filesets as you want using\
      the \"New Fileset\" button.\r"
    # Create a "New Fileset" button.
    set button1 [list \
      "New Fileset…" \
      "Click here to create a new fileset." \
      {catch {newFileset}}]
    set buttons [concat $button1 $backButton]
    # Now we create the dialog.
    set dialogScript [list dialog::make -title $title -width $width \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancel "Postpone" \
      -cancelhelptag $postponeHelpTag \
      -addbuttons $buttons \
      [list "$Alpha Filesets" [list "text" $txt]]]
    if {[catch {eval $dialogScript} result]} {
	error $result
    } else {
	return
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "setupAssistant::helpPreferences" --
 # 
 # Help File format preferences.
 # 
 # --------------------------------------------------------------------------
 ##

proc setupAssistant::helpPreferences {} {
    
    global help::Types help::Choices preferedHelpFormat \
      secondChoiceHelpFormat thirdChoiceHelpFormat helpFileWindowSize
    
    variable Alpha
    variable backButton
    variable continueHelpTag
    variable postponeHelpTag
    variable saveHelpPrefs 0
    variable title
    variable width
    
    set helpPopup1 [list "menu" [set help::Types]]
    set helpPopup2 [list "menu" [set help::Choices]]
    set helpPopup3 [list "menu" [prefs::options helpFileWindowSize]]
    
    foreach item [list "prefered" "secondChoice" "thirdChoice"] {
	lappend prefNames "${item}HelpFormat"
	lappend oldValues  [set ${item}HelpFormat]
    }
    lappend prefNames "helpFileWindowSize"
    lappend oldValues $helpFileWindowSize
    
    set txt1 "$Alpha contains help and documentation in a variety of formats.\
      You can specify your preferred format here.\r"
    set txt2 "(You can select \"Config > Global Setup > System Preferences\"\
      later if you want to change these settings again.)"
    # Create a "Save Preferences" button.
    set button1Script {
	set ::setupAssistant::saveHelpPrefs 1 ;
	set retVal {SavePrefs} ;
	set retCode 0
    }
    set button1 [list \
      "Apply" \
      "Click here to save the new preference settings." \
      $button1Script]
    set buttons [concat $button1 $backButton]
    # Now we create the dialog.
    set dialogScript [list dialog::make -title $title -width $width \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancel "Postpone" \
      -cancelhelptag $postponeHelpTag \
      -addbuttons $buttons \
      [list "Help and Documentation Preferences" \
      [list "text" $txt1] \
      [list $helpPopup1 "First choice"  $preferedHelpFormat \
      [help::itemDescription "preferedHelpFormat"]] \
      [list $helpPopup2 "Second choice" $secondChoiceHelpFormat \
      [help::itemDescription "secondChoiceHelpFormat"]] \
      [list $helpPopup2 "Third choice"  $thirdChoiceHelpFormat \
      [help::itemDescription "thirdChoiceHelpFormat"]] \
      [list $helpPopup3 "Help File Window Size" $helpFileWindowSize \
      [help::itemDescription "helpFileWindowSize"]] \
      [list "text" $txt2]]]
    if {[catch {eval $dialogScript} result]} {
	error $result
    } elseif {!$saveHelpPrefs} {
	return
    }
    # Still here? Save the new settings.
    foreach prefName $prefNames oldValue $oldValues newValue $result {
	if {($oldValue ne $newValue)} {
	    set $prefName $newValue
	    prefs::modified $prefName
	}
    }
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "setupAssistant::specialKeys" --
 # 
 # Either inform or remind the user about Special Keys, and in particular how
 # the Tab key does not insert a 'Real Tab'.  We automatically adjust the
 # introductory text based on these user configurations:
 # 
 # (1) The user has never changed any "Special Keys" mappings
 # (2) The user has changed them, but Tab still doesn't insert a Tab
 # (3) The user has changed them so that Tab inserts a Tab
 # 
 # Pressing the "Review Special Keys" button will open the dialog which
 # allows the user to change them, but then we return back to this one to
 # help remind the user how this can be changed again later, and where to
 # look for more information.
 # 
 # This routine is currently ignored during the Setup Assistant, it could
 # easily be added if there is some consensus to do so.
 # 
 # --------------------------------------------------------------------------
 ##

proc setupAssistant::specialKeys {} {
    
    global keys::specialBindings arrprefDefs
    
    variable Alpha
    variable backButton
    variable continueHelpTag
    variable postponeHelpTag
    variable title
    variable width
    
    set txt1 "By default, "
    set txt2 "You have previously adjusted your \"Special Keys\" mappings,\
      so you probably already know that "
    set txt3 "pressing the Tab key does not insert a 'Real Tab' into the active\
      window.  Instead, this key is mapped to perform some other function"
    set txt4 " such as indenting the current line."
    set txt5 "You can press the \"Review Special Keys\" button to change\
      the current Tab key mapping, as well as those which call other\
      special functions.  You can always change these mappings later by\
      selecting the menu item \"Config > Special Keys\".\
      \rYou might want to read the \"Help > Electrics Help\" window\
      after the Setup Assistant is done for more information about what\
      the other \"special functions\" actually do.\r"
    # Find out some information about the user's current settings, and use
    # this to determine the dialog page name and text.
    if {![info exists arrprefDefs]} {
	catch {prefs::_read "arr"}
    }
    set arrayVar {keys::specialBindings}
    if {([lsearch -regexp [array names arrprefDefs] "$arrayVar .*"] == -1)} {
	# The user has never changed Special Keys settings.
	set pageName "Default Behavior of the 'Tab' key"
	append txt $txt1 $txt3 $txt4 "\r"
    } elseif {([lindex [array get $arrayVar "Real Tab"] 1] ne "/c")} {
	# The user has not changed "Real Tab" to insert Tab.
	set pageName "Special Keys Settings"
	append txt $txt2 $txt3 ".\r"
    } else {
        # The user has bound "Real Tab" to the Tab key.
	set pageName "Special Keys Settings"
    }
    append txt $txt5
    # Create a "Review Special Keys" button.
    set button1 [list \
      "Review Special Keys…" \
      "Click here to review/change all of your current Special Keys settings." \
      {catch {global::specialKeys}}]
    set buttons [concat $button1 $backButton]
    # Now we create the dialog.
    set dialogScript [list dialog::make -title $title -width $width \
      -ok "Continue" \
      -okhelptag $continueHelpTag \
      -cancel "Postpone" \
      -cancelhelptag $postponeHelpTag \
      -addbuttons $buttons \
      [list $pageName [list "text" $txt]]]
    if {[catch {eval $dialogScript} result]} {
	error $result
    } else {
	return
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "setupAssistant::helpfulHints" --
 # 
 # Give some last minute tips, include some buttons for more information.
 # 
 # --------------------------------------------------------------------------
 ##

proc setupAssistant::helpfulHints {} {
    
    variable Alpha
    variable backButton
    variable startup
    variable title
    variable width
    
    set txt1 "If you're new to ${Alpha}, read Quick Start under the 'Help' menu. \
      Other items in this menu provide help with specific Features and Packages."
    set txt2 "The \"Config > Preferences\" menu offers more global options\
      that you might want to change"
    set txt3 "\"Config > Mode Prefs\" allows you to change preferences\
      that apply to particular types of files."
    set txt4 "Use the \"Help\" buttons in any Menus, Features, or Packages dialogs\
      to learn more about ${Alpha}."
    set button1 [list \
      "Open 'Quick Start'" \
      "Click here to open the 'Quick Start' help file." \
      "helpMenu Quick Start"]
    set button2 [list \
      "Open 'Examples Help'" \
      "Click here to open the 'Examples Help' help file." \
      "helpMenu Examples Help"]
    set button3 [list \
      "View All Preferences…" \
      "Click here to open all Preference dialogs." \
      {catch {prefs::dialogs::menuProc {preferences} {All Preferences}}}]
    if {$startup} {
	append conclusion $txt1 "\r" $txt2 ", and " $txt3 "\r" $txt4
	set buttons [concat $button1 $button2 $backButton]
    } else {
	append conclusion $txt2 ". \r" $txt4
	set buttons [concat $button3 $backButton]
    }
    dialog::make -title $title -width $width \
      -ok "Finish" \
      -okhelptag "Click here to complete the setup process." \
      -cancel "" \
      -addbuttons $buttons \
      [list "" [list "text" $conclusion]]
    return
}

# ===========================================================================
# 
# .