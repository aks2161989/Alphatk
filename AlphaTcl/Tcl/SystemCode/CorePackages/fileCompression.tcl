## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "fileCompression.tcl"
 #                                          created: 10/19/2002 {11:26:29 AM}
 #                                      last update: 02/28/2006 {04:00:19 PM}
 # Description:
 # 
 # Several file compression procedures, and a new "Utils > Compress" submenu
 # which provides a friendly user interface to them.
 # 
 # Based on [file::Utils::stuffFile] and [file::Utils::stuffOpenWindows] in
 # the earlier version of "fileUtils.tcl".
 # 
 # All of the procedures found in the "File Compression API" section have
 # been designed to be called by any other code, even if this package has not
 # been formally turned by the user.  (Activation of the package will provide
 # the user-interface to the various compression options and preferences.)
 # 
 # Note: if this package was incorporated into the AlphaTcl cvs as a core
 # package (i.e. always available for other packages) then perhaps some of
 # the global definitions for the "fileCompression" package signature
 # applications defined below in [compress::initializePackage] below could be
 # removed from "alphaDefinitions.tcl".  This would require going through all
 # of AlphaTcl for their current uses, and changing the calling procedures to
 # use the API found in this file.
 # 
 # To Do:
 # 
 # • Determine if the "Destination Folder" can be specified in archive scripts.
 # • Confirm that this works in Alphatk/Windows.
 # • Look into "XServ" methods for the different Archivers.
 # • "gzip" always deletes the source file -- is there a workaround?
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # Copyright (c) 2002-2006  Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

# ◊◊◊◊ Feature Declaration ◊◊◊◊ #
alpha::feature fileCompression 0.4.1 "global-only" {
    # Initialization script.
    menu::buildProc "compress" {compress::buildCompressMenu} \
      {compress::postBuildMenu "compress"}
    menu::buildProc "fileCompression" {compress::buildPrefsMenu}
    compress::initializePackage
} {
    # Activation script.
    menu::insert   Utils submenu "(-" "compress"
    menu::insert   preferences submenu "(-)" fileCompression
    compress::registerHooks "register"
} {
    # Deactivation script.
    menu::uninsert Utils submenu "(-" "compress"
    menu::uninsert preferences submenu "(-)" fileCompression
    compress::registerHooks "deregister"
} preinit {
    # Includes items to archive the active window or its parent directory
    newPref flag "compress Menu" 0 contextualMenu
    menu::buildProc "compress " {compress::buildCompressCMenu} \
      {compress::postBuildMenu "compress "}
    # This inserts a very basic "File > File Utils > Archive File" menu comand.
    menu::insert "fileUtils" items end "archiveFile…"
} uninstall {
    this-file
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} description {
    Creates a "Utils > Compress" submenu which supports the archiving of
    windows, files, and folders from within Alpha
} help {
    This package creates a new "Utils > Compress" submenu with allows you to
    compress windows and files from within Alpha.  To turn it on, select the
    "Config > Global Setup > Features" menu item and click the checkbox that
    is named "File Compression".
    
    Preferences: Features

	  	Compressing Windows, Files, Folders
    
    The "Utils > Compress" menu contains a variety of options for creating
    the list of files that should be archived, including
    
	the active window
	the folder of the active window
	any other open window
	all open windows
	
    In all cases, only those windows that actually exist on your local drive
    can be archived.
    
    Additional options will open a dialog to specify

	any file on your local drive
	any folder on your local drive

    You can determine which archiving application options should be included
    in the menu by changing the "File Compression" package preferences --
    just select "Utils > Compress > Compression Prefs", and turn on/off the
    items named "Include Stuff Options", "Include Zip Options" etc.
    
    <<compress::packagePrefs>>
    
    Adding them to the menu does not ensure that the archiving option is
    actually available -- you should also check the value of the application
    signature for each item to determine if it exists on your local drive.
    
    If your copy of the compression program has not been registered with the
    software developer, you will need to switch to them to dismiss the
    initial dialog that is always presented when it is first launched.  (Or,
    even better, register all of your shareware!)
    
	  	Destination Folders

    The "Utils > Compress > Destination Folder" menu item will attempt to
    open your Archiver's Destination Folder in the OS. In general, this
    folder is a preference that you set as a default for the Archiver.  If
    Alpha is not able to determine the value of this preference from your
    Archiver program, you will be prompted to locate it yourself.  This
    location will be saved as a "File Compression" package preference between
    Alpha editing sessions.
    
    <<compress::openDestinationFolder>>
    
    The "Open Destination" preferences for each Archiver determines if this
    folder will be automatically opened following a compression operation.
    
    In future versions, the Destination Folder preferences might be used to
    determine the target of the Archiver.  As of this writing, you must set
    this from in the Archiver Application Preferences and simply let Alpha
    know where these folders are located.

	  	Contextual Menu Module
    
    This package also creates a new "Compress" contextual menu module that
    can be activated even if this package has not been turned on.
    
    Preferences: ContextualMenu

    This menu will offer options for archiving currently open windows.
}

proc fileCompression.tcl {} {}

# ===========================================================================
# 
# ◊◊◊◊ -------- ◊◊◊◊ #
# 

##
 # --------------------------------------------------------------------------
 #
 # "namespace eval compress" --
 # 
 # Create some variables required for this package, as well as some package
 # preferences used in the archiving procedures.
 #
 # --------------------------------------------------------------------------
 ##

namespace eval compress {
    
    global tcl_platform

    variable debugging
    if {![info exists debugging]} {
        set debugging 0
    }
    variable initialized
    if {![info exists initialized]} {
        set initialized 0
    }

    # This is used in some [getfile] dialogs.  This is saved between Alpha
    # editing sessions.
    variable lastFileChosen ""
    prefs::modified lastFileChosen

    # Create a list of Archiver options, in the order in which items will be
    # presented in the menus.
    variable archiverOptions [list]
    variable archiverDefaults
    switch -- $tcl_platform(platform) {
	"macintosh" {
	    set archiverDefaults(gzip)  0
	    set archiverDefaults(tar)   0
	    set archiverDefaults(zip)   0
	    lappend archiverOptions "zip" "tar" "gzip"
	}
	"unix" {
	    set archiverDefaults(gzip)  0
	    set archiverDefaults(tar)   1
	    set archiverDefaults(zip)   0
	    lappend archiverOptions "tar" "gzip" "zip"
	}
	"windows" {
	    set archiverDefaults(gzip)  0
	    set archiverDefaults(tar)   0
	    set archiverDefaults(zip)   1
	    lappend archiverOptions "zip" "gzip" "tar"
	}
    }
    if {(${alpha::macos} > 0)} {
	set archiverDefaults(stuff)     1
	set archiverOptions [concat [list "stuff"] $archiverOptions]
    } else {
	set archiverDefaults(stuff)     0
	lappend archiverOptions "stuff"
    }
    # No "gzip" option in MacClassic.
    if {(${alpha::macos} == 1)} {
	set idx [lsearch archiverOptions "gzip"]
	set archiverOptions [lreplace $archiverOptions $idx $idx]
	unset idx
    }
    # "gzip" currently deletes the source file -- bad option to offer at the
    # moment until this can be addressed.
    set idx [lsearch $archiverOptions "gzip"]
    set archiverOptions [lreplace $archiverOptions $idx $idx]
    unset idx
    
    # This is used in [compress::selectArchiver].
    variable lastArchiverChosen [lindex $archiverOptions 0]
    
    # These options are used in preferences and dialogs.
    variable openDestinationOptions [list \
      "Never" "Ask Each Time" "Always, If It Exists"]
    variable destinationFolderOptions [list \
      "Same As Original" "Ask Every Time" "Use Destination Folder"]
    
    # This is a list of options presented in "Utils > Compress".
    variable compressMenuOptions [list \
      "Window" \
      "Window'sFolder" \
      "OpenWindows" \
      "AWindow…" \
      "AFile…" \
      "Folder…" \
      ]
    
    # This is a list of options presented in the "Compression" CM module.
    variable compressionMenuOptions [list \
      "Window" \
      "Window'sFolder" \
      "OpenWindows" \
      ]

    # These items require at least one open window.
    variable requireOneOpenWindow [list \
      "Window" \
      "Window'sFolder" \
      ]
    # These items require at least two open windows.
    variable requireTwoOpenWindows [list \
      "OpenWindows" \
      "AWindow…" \
      ]
}

##
 # --------------------------------------------------------------------------
 #
 # "compress::initializePackage" --
 # 
 # Create some package preferences used in the archiving procedures.
 # 
 # Some of these preferences are not currently implemented, and are withheld
 # from the [compress::packagePrefs] dialog.  For simplicity, we define prefs
 # for all possible archiver options, though the "compress::archiverOptions"
 # variable is very platform specific.
 #
 # --------------------------------------------------------------------------
 ##

proc compress::initializePackage {} {
    
    variable initialized
    
    if {$initialized} {
	return
    }

    global alpha::macos
    
    variable archiverDefaults
    variable destinationFolderOptions
    variable openDestinationOptions

    # "Compression" package preferences.
    
    # These preferences determine what gets included in the menus.

    # To include "gzip" as an option in the "Utils > Compress" menu and the
    # "Compression" contextual menu module, turn this item on||To remove all
    # "gzip" options in the "Utils > Compress" menu and the "Compression"
    # contextual menu module, turn this item off.
    newPref flag [compress::archiverPref gzip]  $archiverDefaults(gzip) \
      fileCompression {compress::rebuildMenu}
    # To include "stuff" as an option in the "Utils > Compress" menu and the
    # "Compression" contextual menu module, turn this item on||To remove all
    # "stuff" options in the "Utils > Compress" menu and the "Compression"
    # contextual menu module, turn this item off.
    newPref flag [compress::archiverPref stuff] $archiverDefaults(stuff) \
      fileCompression {compress::rebuildMenu}
    # To include "tar" as an option in the "Utils > Compress" menu and the
    # "Compression" contextual menu module, turn this item on||To remove all
    # "stuff" options in the "Utils > Compress" menu and the "Compression"
    # contextual menu module, turn this item off.
    newPref flag [compress::archiverPref tar]   $archiverDefaults(tar) \
      fileCompression {compress::rebuildMenu}
    # To include "zip" as an option in the "Utils > Compress" menu and the
    # "Compression" contextual menu module, turn this item on||To remove all
    # "zip" options in the "Utils > Compress" menu and the "Compression"
    # contextual menu module, turn this item off.
    newPref flag [compress::archiverPref zip]   $archiverDefaults(zip) \
      fileCompression {compress::rebuildMenu}
    
    # As of this writing, the Destination Folder is set by the Archiver, but
    # we have no idea how to get this information, and we cannot use it to
    # specify the location of a file/folder to be archived.  For now, it is
    # only used to help the user locate it, and these preferences are not
    # exposed to the user.
    
    # To use the "Gzip Destination Folder" preference when archiving, turn
    # this item on||To use gzip's default folder when archiving, turn this
    # item off
    newPref var gzipDestination                 0       fileCompression "" \
      $destinationFolderOptions index
    # To use the "Stuff Destination Folder" preference when archiving, turn
    # this item on||To use stuff's default folder when archiving, turn this
    # item off
    newPref var stuffDestination                0       fileCompression "" \
      $destinationFolderOptions index
    # To use the "Tar Destination Folder" preference when archiving, turn
    # this item on||To use tar's default folder when archiving, turn this
    # item off
    newPref var tarDestination                  0       fileCompression "" \
      $destinationFolderOptions index
    # To use the "Zip Destination Folder" preference when archiving, turn
    # this item on||To use zip's default folder when archiving, turn this
    # item off
    newPref var zipDestination                  0       fileCompression "" \
      $destinationFolderOptions index

    # To automatically open the "Gzip Destination Folder" after archiving a
    # window / file / folder, select one of the given options.
    newPref var autoOpenGzipDestination         0       fileCompression "" \
      $openDestinationOptions index
    # To automatically open the "Stuff Destination Folder" after archiving a
    # window / file / folder, select one of the given options.
    newPref var autoOpenStuffDestination        0       fileCompression "" \
      $openDestinationOptions index
    # To automatically open the "Tar Destination Folder" after archiving a
    # window / file / folder, select one of the given options.
    newPref var autoOpenTarDestination          0       fileCompression "" \
      $openDestinationOptions index
    # To automatically open the "Zip Destination Folder" after archiving a
    # window / file / folder, select one of the given options.
    newPref var autoOpenZipDestination          0       fileCompression "" \
      $openDestinationOptions index

    # This is the "Gzip" Destination Folder that is set and/or used by your
    # archiving applications.
    newPref folder gzipDestinationFolder        ""      fileCompression
    # This is the "Stuff" Destination Folder that is set and/or used by your
    # archiving applications.
    newPref folder stuffDestinationFolder       ""      fileCompression
    # This is the "Tar" Destination Folder that is set and/or used by your
    # archiving applications.
    newPref folder tarDestinationFolder         ""      fileCompression
    # This is the "Zip" Destination Folder that is set and/or used by your
    # archiving applications.
    newPref folder zipDestinationFolder         ""      fileCompression
    
    # The signature for your "gzip" application
    newPref sig gzipSig "/usr/bin/gzip" \
      fileCompression
    # The signature of your "DropStuff" application
    newPref sig stuffSig [expr {${alpha::macos} ? "DStf" : "stuff"}] \
      fileCompression
    # The signature for your "DropTar" or "tar" application
    newPref sig tarSig [expr {${alpha::macos} ? "crsT" : "tar"}] \
      fileCompression
    # The signature of your "DropZip" or "zip" application
    newPref sig zipSig [expr {${alpha::macos} ? "DZip" : "zip"}] \
      fileCompression

   # We never need to do this twice.
    set initialized 1
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "compress::archiverPref" --
 #
 # All of the Archiver options are in lower case, corresponding to a possible
 # unix command name.  Our preferences for inclusion in the menu are
 # formatted a little bit differently -- this procedure connects the Archiver
 # to the proper package preference, and returns the current value of this
 # pref.
 #
 # --------------------------------------------------------------------------
 ##

proc compress::archiverPref {archiver {returnValue 0}} {
    
    global fileCompressionmodeVars
    
    set prefName "include[quote::Prettify $archiver]OptionsInMenu"
    
    if {!$returnValue } {
	return $prefName
    } elseif {[info exists fileCompressionmodeVars($prefName)]} {
	return $fileCompressionmodeVars($prefName)
    } else {
	return 0
    }
}

##
 # --------------------------------------------------------------------------
 #
 # "compress::packagePrefs" --
 # 
 # Open a dialog allowing the user to (un)set all Destination Folders and
 # other Archiver specific options.
 #
 # --------------------------------------------------------------------------
 ##

proc compress::packagePrefs {{archiver "all"}} {
    
    global fileCompressionmodeVars
    
    variable archiverOptions
    variable destinationFolderOptions
    variable openDestinationOptions
    
    compress::initializePackage
    
    # Set up the dialog.
    append buttonScript {package::helpWindow "fileCompression" ; } \
      {set retCode 1 ; set retVal "cancel"}
    set dialogScript [list dialog::make -title "File Compression Preferences" \
      -addbuttons [list \
      "Help" \
      "Click here to open the File Compression Help window" \
      $buttonScript]]
    if {($archiver == "all")} {
	set archivers $archiverOptions
	# Create an initial "Introduction" dialog pane.
	set intro {
	    This dialog allows you to set various "Compression" preferences for
	    all Archiver options.  All settings will be saved between editing
	    sessions, and will apply to both the "Utils > Compress" submenu as
	    well as the "Compression" contextual menu module.
	}
	regsub -all -- {\s+} $intro { } intro
	lappend dialogScript [list "Introduction" [list "text" $intro]]
    } else {
	set archivers [list $archiver]
    }
    # Add all of the individual Archiver options.  Determine variable names
    # for the dialog, and default values, then add all of the items for this
    # dialog pane, recording the associated preferences and their default
    # values.
    foreach archiver $archivers {
	set Archiver [quote::Prettify $archiver]
	set dialogPage [list "$Archiver Options"]
	# "Include In Menu" preference.
	set txt [quote::Prettify [compress::archiverPref $archiver 0]]
	set val [compress::archiverPref $archiver 1]
	lappend dialogPage [list "flag" $txt $val]
	lappend compressionPreferences \
	  [list [compress::archiverPref $archiver 0] $val]
	# This set of prefs is not currently used, since we don't seem to have
	# any control over where the archive will land.
	
# 	# "Archiver Destination" preference.
# 	set v1 $destinationFolderOptions
# 	set v2 "$Archiver Destination"
# 	set v3 $fileCompressionmodeVars(${archiver}Destination)
# 	lappend d$d [list [list menuindex $v1] $v2 $v3]
# 	lappend compressionPreferences \
# 	  [list "${archiver}Destination" $v3]
	
	# "Auto Open Destination" preference.
	set opts $openDestinationOptions
	set txt  "Open Destination"
	set val  $fileCompressionmodeVars(autoOpen${Archiver}Destination)
	lappend dialogPage [list [list "menuindex" $opts] $txt $val]
	lappend compressionPreferences \
	  [list "autoOpen${Archiver}Destination" $val]
	# "Destination Folder" preference.
	set txt "$Archiver Destination Folder:"
	set val [compress::destinationFolder $archiver]
	lappend dialogPage [list "folder" $txt $val]
	lappend compressionPreferences \
	  [list "${archiver}DestinationFolder" $val]
	# "Archiver Sig" preference.
	set txt "$Archiver Sig:"
	set val $fileCompressionmodeVars(${archiver}Sig)
	if {([string length $val] == 4)} {
	    set val "'${val}'"
	}
	lappend dialogPage [list "appspec" $txt $val]
	lappend compressionPreferences \
	  [list "${archiver}Sig" $val]
	# Add this dialog pane, and increment "d".
	lappend dialogScript $dialogPage
    }
    # Present the dialog, and change any relevant preferences.
    set result [eval $dialogScript]
    for {set i 0} {$i < [llength $result]} {incr i} {
	set prefName  [lindex $compressionPreferences $i 0]
        set prevValue [lindex $compressionPreferences $i 1]
	set newValue  [lindex $result $i]
	if {($prevValue != $newValue)} {
	    set fileCompressionmodeVars($prefName) $newValue
	    prefs::modified fileCompressionmodeVars($prefName)
	}
    }
    compress::rebuildMenu
}

# ===========================================================================
# 
# ◊◊◊◊ -------- ◊◊◊◊ #
# 
# ◊◊◊◊ Compress/Compression Menus ◊◊◊◊ #
# 
# These provide the user-interface to create an appropriate list of files as
# well as a compression technique that will eventually be used by the proc
# [compress::archiveFile] below.
# 

##
 # --------------------------------------------------------------------------
 #
 # "compress::buildCompressMenu" --
 #
 # This is for the "Utils > Compress" menu.  We only add items if the user
 # has turned on the appropriate [compress::archiverPref] package preference.
 #
 # --------------------------------------------------------------------------
 ##

proc compress::buildCompressMenu {} {
    
    global fileCompressionmodeVars
    
    variable archiverOptions
    variable compressMenuOptions
    
    set menuList [list]
    foreach archiver $archiverOptions {
	if {![compress::archiverPref $archiver 1]} {
	    continue
	} elseif {[llength $menuList]} {
	    lappend menuList "(-)"
	}
	foreach item $compressMenuOptions {
	    lappend menuList "${archiver}${item}"
	}
	set Archiver [quote::Prettify $archiver]
	if {[string length [compress::destinationFolder $archiver]]} {
	    lappend menuList "show${Archiver}Destination"
	} else {
	    lappend menuList "show${Archiver}Destination…"
	}
    }
    if {![llength $menuList]} {
        lappend menuList "(No Archiver Options Available"
    }
    lappend menuList "(-)" "compressionPrefs…" "compressionHelp"
    return [list build $menuList {compress::menuProc}]
}

##
 # --------------------------------------------------------------------------
 #
 # "compress::buildCompressionMenu" --
 #
 # Build the CM Compression menu.  Only relevant items are presented, based
 # on the existence of the active window as a file, and surrounding windows.
 # Unlike [compress::buildCompressMenu], we only include menu options for the
 # active window(s).
 #
 # --------------------------------------------------------------------------
 ##

proc compress::buildCompressCMenu {} {
    
    global fileCompressionmodeVars
    
    variable archiverOptions
    variable compressionMenuOptions
    
    set menuList [list]
    # Create the list of menu options available for each Archiver.
    set listingOptions [list]
    foreach item $compressionMenuOptions {
	switch -- $item {
	    "Window" - "Window'sFolder" {
		if {[win::IsFile [win::Current]]} {
		    lappend listingOptions $item
		}
	    }
	    "OpenWindows" {
		set local 0
		foreach w [winNames -f] {
		    if {[win::IsFile $w]} {
			incr local
		    }
		}
		if {($local >= 2)} {
		    lappend listingOptions $item
		}
	    }
	}
    }
    # Now create the menu list.
    foreach archiver $archiverOptions {
	if {![compress::archiverPref $archiver 1]} {
	    continue
	} elseif {[llength $menuList]} {
	    lappend menuList "(-)"
	}
	foreach listingOption $listingOptions {
	    lappend menuList ${archiver}${listingOption}
	}
	set Archiver [quote::Prettify $archiver]
	if {[string length [compress::destinationFolder $archiver]]} {
	    lappend menuList "show${Archiver}Destination"
	} else {
	    lappend menuList "show${Archiver}Destination…"
	}
    }
    if {![llength $menuList]} {
	set menuList [list "\(No archiver options available"]
    }
    lappend menuList "(-)" "compressionPrefs…" "compressionHelp"
    return [list build $menuList {compress::menuProc}]
}

##
 # --------------------------------------------------------------------------
 #
 # "compress::buildPrefsMenu" --
 # 
 # Create a "Config > Preferences > File Compression" menu containing items
 # for adjusting Archiver package preferences.
 #
 # --------------------------------------------------------------------------
 ##

proc compress::buildPrefsMenu {} {
    
    variable archiverOptions
    
    foreach archiver $archiverOptions {
	lappend menuList "${archiver}Preferences…"
    }
    lappend menuList "(-)" "AllPreferences…" "fileCompressionHelp"
    
    return [list build $menuList {compress::menuProc}]
}

##
 # --------------------------------------------------------------------------
 #
 # "compress::postBuildMenu" --
 # 
 # Dim "Destination Folder" items if the preference is not set to an existing
 # directory in the filesystem.
 #
 # --------------------------------------------------------------------------
 ##

proc compress::postBuildMenu {menuName} {
    
    global fileCompressionmodeVars
    
    variable archiverOptions
    
    foreach archiver $archiverOptions {
	set pref [compress::archiverPref $archiver]
	if {!$fileCompressionmodeVars($pref)} {
	    continue
	}
        set df $fileCompressionmodeVars(${archiver}DestinationFolder)
	set dim [file isdir $df]
	enableMenuItem $menuName ${archiver}DestinationFolder $dim
    }
}

##
 # --------------------------------------------------------------------------
 #
 # "compress::rebuildMenu" --
 # 
 # Called whenever the user has changed some of the [compress::archiverPref]
 # package preferences.  We always deregister all "open windows" hooks first
 # when the list of Archivers has been changed by the user.
 #
 # --------------------------------------------------------------------------
 ##

proc compress::rebuildMenu {args} {

    menu::buildSome "compress"
    # (De)Register open window hooks.
    compress::registerHooks "deregister"
    compress::registerHooks "register"
}

##
 # --------------------------------------------------------------------------
 #
 # "compress::registerHooks" --
 # 
 # Called when this package is turned on/off, or whenever the user has
 # changed some of the [compress::archiverPref] package preferences.
 # Whenever we "deregister", we make sure that all possible items have been
 # removed from the defined hook: if the user has already changed some of the
 # preferences it is a big pain (though not impossible) to remember all of
 # the hooks that were previously registered.  This is much simpler -- if the
 # hook wasn't defined, [hook::deregister] just moves on without complaining.
 #
 # --------------------------------------------------------------------------
 ##

proc compress::registerHooks {which} {
    
    variable archiverOptions
    variable requireOneOpenWindow
    variable requireTwoOpenWindows
    
    set archivers [list]
    if {($which == "deregister")} {
        set archivers $archiverOptions
    } else {
        foreach archiver $archiverOptions {
	    if {[compress::archiverPref $archiver 1]} {
	        lappend archivers $archiver
	    }
	}
    }
    foreach archiver $archivers {
	foreach item $requireOneOpenWindow {
	    set menuItem ${archiver}${item}
	    hook::${which} requireOpenWindowsHook [list "compress" $menuItem] 1
	}
    }
    foreach archiver $archivers {
	foreach item $requireTwoOpenWindows {
	    set menuItem ${archiver}${item}
	    hook::${which} requireOpenWindowsHook [list "compress" $menuItem] 2
	}
    }
}

##
 # --------------------------------------------------------------------------
 #
 # "compress::menuProc" --
 # 
 # All menus pass their items through this procedure.  We go to a bit of
 # trouble to ensure that any filelist created for archiving purposes will
 # only have valid items -- this makes it much easier to let the user know
 # why some files won't be included _before_ any of the archiving begins.
 #
 # --------------------------------------------------------------------------
 ##

proc compress::menuProc {menuName itemName} {
    
    global fileCompressionmodeVars
    
    variable archiverOptions
    
    # Some regexp patterns to determine the goal of the menu item.
    set pat1 "^([join $archiverOptions "|"])(.+)$"
    set pat2 "^show([join $archiverOptions "|"])Destination$"
    
    # Deal with the "Config > Preferences > File Compression" package
    # preferences menu first.
    if {($menuName == "fileCompression")} {
	if {($itemName == "fileCompressionHelp")} {
	    package::helpWindow "fileCompression"
	} elseif {[regexp -- $pat1 $itemName allofit archiver]} {
	    compress::packagePrefs $archiver
	} else {
	    compress::packagePrefs
	}
	return
    }
    
    # "Utils > Compress" and contextual menu utility items.
    switch -- $itemName {
        "compressionPrefs" {
            compress::packagePrefs
	    return
        }
        "compressionHelp" {
            package::helpWindow "fileCompression"
	    return
        }
    }
    if {[regexp -nocase -- $pat2 $itemName allofit Archiver]} {
	compress::openDestinationFolder [string tolower $Archiver]
	return
    }
    # Still here?  Determine the Archiver and a create a list of files.
    set pat1 "^([join $archiverOptions "|"])(.+)$"
    if {![regexp -- $pat1 $itemName allofit archiver listing]} {
	error "Unable to determine archiver/listing from $itemName"
    }
    set fileList [list]
    set emptyMsg "Could not create a list of files to archive."
    switch -- $listing {
        "AFile" {
	    set fileList [list [compress::selectPath "File"]]
        }
        "AFolder" {
            set fileList [list [compress::selectPath "Folder"]]
        }
	"AWindow" {
	    requireOpenWindow
	    set p "Choose a window:"
	    set L [nextWin]
	    set windows [list]
	    foreach w [winNames -f] {
		if {![win::IsFile $w f]} {
		    continue
		}
		set w [file tail $w]
		set windowFileConnect($w) $f
		lappend windows $w
	    }
	    if {![llength [set windows [lsort -dictionary $windows]]]} {
		set emptyMsg "There are no windows saved as files."
	    } else {
		foreach w {[list [listpick -p $p -L $L $windows]]} {
		    if {[info exists $windowFileConnect($w)]} {
			lappend fileList $windowFileConnect($w)
		    } else {
			alertnote "Couldn't connect \"${w}\" to a file!"
		    }
		}
		set emptyMsg "None of the selected open windows exist as files."
	    }
	}
	"DestinationFolder" {
	    compress::openDestinationFolder $archiver
	    return
	}
	"OpenWindows" {
	    requireOpenWindow
	    foreach w [winNames -f] {
		if {[win::IsFile $w]} {
		    lappend fileList [win::StripCount $w]
		}
	    }
	    set emptyMsg "There are no windows saved as files to archive."
	}
	"Window" {
	    requireOpenWindow
	    if {[win::IsFile [set w [win::Current]]]} {
		set fileList [list [win::StripCount $w]]
	    }
	    set emptyMsg "The active window does not exist as a file."
	}
	"Window'sFolder" {
	    requireOpenWindow
	    if {[win::IsFile [set w [win::Current]]]} {
		set fileList [list [file dirname [win::StripCount $w]]]
	    }
	    set emptyMsg "The active window does not exist as a file."
	}
	default {
	    error "Unknown option: $listing"
	}
    }
    # We should have a non-empty list by now ...
    if {![llength $fileList]} {
	alertnote $emptyMsg
	error "Cancelled -- $emptyMsg"
    }
    # Archive the given files, pass on messages.
    set result [compress::archiveFiles $fileList $archiver]
    if {($result == 1)} {
        set msg "\"[file tail [lindex $fileList 0]]\" has been archived."
    } else {
        set msg "$result files have been archived."
    }
    status::msg $msg
    # Open the Destination Folder?
    set Archiver [quote::Prettify $archiver]
    switch -- $fileCompressionmodeVars(autoOpen${Archiver}Destination) {
	"0" {
	    # Never open the Destination Folder, so do nothing.
	}
	"1" {
	    # Ask the user.
	    set q "Open the \"${archiver}\" Destination Folder?"
	    if {[dialog::yesno $q]} {
		compress::openDestinationFolder $archiver
	    }
	}
	"2" {
	    # Always open the Destination Folder.
	    if {[string length [compress::destinationFolder $archiver]]} {
		compress::openDestinationFolder $archiver
	    }
	}
	"3" {
	    # Always, and prompt to locate if necessary.
	    compress::openDestinationFolder $archiver
	}
    }
    return
}

# ===========================================================================
# 
# ◊◊◊◊ -------- ◊◊◊◊ #
# 
# ◊◊◊◊ Destination Folders ◊◊◊◊ #
# 

##
 # --------------------------------------------------------------------------
 #
 # "compress::destinationFolder" --
 # 
 # Can be called by other procedures that want to know where the user has
 # specified the location of the "Destination Folder".  If "f" is not an
 # empty string, the user's preference is set to this value.
 #
 # --------------------------------------------------------------------------
 ##

proc compress::destinationFolder {archiver {f ""}} {
    
    global fileCompressionmodeVars
    
    set prefName "${archiver}DestinationFolder"
    
    if {[string length $f]} {
	set fileCompressionmodeVars($prefName) $f
	prefs::modified fileCompressionmodeVars($prefName)
	compress::rebuildMenu
    } elseif {[info exists fileCompressionmodeVars($prefName)]} {
	return $fileCompressionmodeVars($prefName)
    } else {
        return ""
    }
}

##
 # --------------------------------------------------------------------------
 #
 # "compress::openDestinationFolder" --
 # 
 # Attempt to open the Destination Folder in the OS.
 #
 # --------------------------------------------------------------------------
 ##

proc compress::openDestinationFolder {{archiver ""} {quietly 0}} {
    
    global alpha::application
    
    if {![string length $archiver]} {
        set archiver [compress::selectArchiver]
    }
    set f [compress::destinationFolder $archiver]
    if {!$quietly && (![string length $f] || ![file isdir $f])} {
	set msg "The \"Destination Folder\" preference might be set by your\
	  archiving application, but ${alpha::application} has no idea what\
	  it is.\rWould you like to locate it now?"
	if {[dialog::yesno -width 450 $msg]} {
	    set p "Locate your \"${archiver}\" Destination Folder:"
	    set f [get_directory -p $p]
	    compress::destinationFolder $archiver $f
	}
    }
    if {![file isdir $f]} {
	set result 0
    } else {
	file::showInFinder $f
	set result 1
    }
    if {!$quietly} {
	set df "\"[quote::Prettify $archiver]\" Destination Folder"
	if {!$result} {
	    status::msg "Could not find the ${df}."
	} else {
	    status::msg "The ${df} has been opened in the OS."
	}
    }
    return $result
}

# ===========================================================================
# 
# ◊◊◊◊ -------- ◊◊◊◊ #
# 
# ◊◊◊◊ File Compression API ◊◊◊◊ #
# 
# All of the procedures in this section have been designed to be called by
# any other code in AlphaTcl.  In some cases, the scripts here might rely on
# other items defined in the system code.
# 

##
 # --------------------------------------------------------------------------
 #
 # "compress::selectPath" --
 # 
 # Prompt the user to select either an existing file or an existing folder
 # to be archived.
 #
 # --------------------------------------------------------------------------
 ##

proc compress::selectPath {{fileOrFolder ""}} {
    
    variable lastFileChosen
    
    if {![string length $fileOrFolder]} {
	set p "Would you like to archive a file or a folder?"
	if {[dialog::yesno -c -y "File" -n "Folder" $p]} {
	    set fileOrFolder "File"
	} else {
	    set fileOrFolder "Folder"
	}
    }
    switch -- $fileOrFolder {
        "File" {
	    set p "Choose a file to archive:"
	    set lastFileChosen [getfile $p $lastFileChosen]
	    set path $lastFileChosen
        }
        "Folder" {
	    set p "Choose a folder to archive:"
	    set path [get_directory -p $p]
        }
	default {
	    error "Unknown path type: $fileOrFolder"
	}
    }
    return $path
}

##
 # --------------------------------------------------------------------------
 #
 # "compress::selectArchiver" --
 # 
 # Used by [compress::archiveFiles] and [compress::archiveFile] in case the
 # calling code has not provided a compression application to use.
 # 
 # --------------------------------------------------------------------------
 ##

proc compress::selectArchiver {} {
    
    variable archiverOptions
    variable lastArchiverChosen
    
    set p "Choose a method for archiving:"
    set archiver [listpick -p $p -L $lastArchiverChosen $archiverOptions]
    set lastArchiverChosen $archiver
    return $archiver
}

##
 # --------------------------------------------------------------------------
 #
 # "compress::listArchivers" --
 # 
 # Can be used by other code to get the list of options available.
 #
 # --------------------------------------------------------------------------
 ##

proc compress::listArchivers {} {
    
    variable archiverOptions
    return $archiverOptions
}

##
 # --------------------------------------------------------------------------
 #
 # "compress::ensureArchiverSig" --
 # 
 # Used by [compress::archiveFiles] and [compress::archiveFile] to confirm
 # that the user has properly set the preferences for the given Archiver.
 #
 # --------------------------------------------------------------------------
 ##

proc compress::ensureArchiverSig {{archiver ""}} {
    
    global fileCompressionmodeVars
    
    compress::initializePackage
    
    if {![string length $archiver]} {
        set archiver [compress::selectArchiver]
    }
    if {![string length $fileCompressionmodeVars(${archiver}Sig)]} {
	set msg "The signature for \"${archiver}\" has not been set."
	alertnote $msg
	status::msg $msg
	prefs::dialogs::packagePrefs "fileCompression"
	# Did it get set yet?
	if {![string length $fileCompressionmodeVars(${archiver}Sig)]} {
	    error "Cancelling -- The signature still wasn't properly set."
	}
    }
    return $fileCompressionmodeVars(${archiver}Sig)
}

##
 # --------------------------------------------------------------------------
 #
 # "compress::archiveFiles" --
 # 
 # Given a (possibly empty) list of file-paths (any combination of file-names
 # or folders) and a (possibly empty) archiving technique, recursively call
 # [compress::archiveFile].  If either has not been specified then prompt the
 # user for the information.  When using an application like "DropStuff", if
 # it is already open then we don't want to kill it when we're done.  Also,
 # it is best to keep the application open until all archiving has been
 # completed, which is why we determine the "compressorIsOpen" variable.
 # 
 # This can be called by any other code in AlphaTcl, even if the user has not
 # formally turned on this package.  It returns the number of files that were
 # actually sent on to the archiving application.
 #
 # --------------------------------------------------------------------------
 ##

proc compress::archiveFiles {{pathList ""} {archiver ""}} {
    
    global alpha::macos
    
    watchCursor
    if {![llength $pathList]} {
	set pathList [list [compress::chooseFilePath]]
    }
    if {![string length $archiver]} {
        set archiver [compress::selectArchiver]
    }
    set result 0
    set sig [compress::ensureArchiverSig $archiver]
    # If applicable, find out if the archiver is already running.
    if {${alpha::macos} && ([string length $sig] == 4)} {
	set compressorIsOpen [app::isRunning $sig]
    } else {
        set compressorIsOpen 0
    }
    if {([llength $pathList] > 1)} {
	# Compress all but the last file.
	foreach f [lrange $pathList 0 end-1] {
	    incr result [compress::archiveFile $f $archiver 1]
	}
    }
    # Now compress the last file, closing the Archiver if necessary.
    set f [lindex $pathList end]
    incr result [compress::archiveFile $f $archiver $compressorIsOpen]
    return $result
}

##
 # --------------------------------------------------------------------------
 #
 # "compress::archiveFile" --
 # 
 # Everything in this file eventually gets passed to this procedure.
 # 
 # Given a (possibly empty) file-path (either a file-name or a folder) and a
 # (possibly empty) archiving technique, open the archiving application and
 # compress the file.  If either has not been specified then prompt the user
 # for the information.
 # 
 # When using an application like "DropStuff" in the MacOS, if it is already
 # open then we don't want to kill it when we're done.  If the calling proc
 # hasn't told us otherwise, we kill it if it wasn't open before we started.
 # 
 # We do check to make sure that the "path" actually exists before we start
 # doing anything, but any calling proc should really take care of that first.
 # 
 # This can be called by any other code in AlphaTcl, even if the user has not
 # formally turned on this package.  It returns "1" if the file-path was
 # actually passed onto the archiving application, otherwise "0".  (I'm not
 # sure if we can easily find out if anything was actually compressed.)
 # 
 # It is possible that some of this should actually be sent through some
 # "XServ" procedures, but I (cbu) have no idea how to implement any of that.
 #
 # --------------------------------------------------------------------------
 ##

proc compress::archiveFile {{path ""} {archiver ""} {keepCompressorOpen ""}} {
    
    global alpha::macos
    
    variable debugging
    variable lastFileChosen
    
    if {![string length $path]} {
	set path [compress::selectPath]
    } elseif {![file exists $path]} {
        set msg "\"[file tail $path]\" could not be found!"
	alertnote $msg
	status::msg $msg
	return 0
    }
    if {![string length $archiver]} {
	set archiver [compress::selectArchiver]
    }
    set sig [compress::ensureArchiverSig $archiver]
    # Everything should now be set-up to go ...
    watchCursor
    set result 0
    set fileTail [file tail $path]
    status::msg [set msg "Archiving ('$archiver') \"${fileTail}\" … "]
    # It is at this point that we could use some help if the "archiver"
    # signature is actually a command line, which probably means that we
    # should be using some sort of XServ procedure...
    if {${alpha::macos} && ([string length $sig] == 4)} {
	# This has been tested in Alpha8/X/tk in the MacOS.
	if {![string length $keepCompressorOpen]} {
	    set keepCompressorOpen [app::isRunning $sig]
	}
	app::launchBack $sig
	set f [tclAE::build::alis $path]
	if {![catch {tclAE::send -r '${sig}' aevt odoc ---- $f} theAEDesc]} {
	    set result 1
	    set errorMsg $theAEDesc
	}
	if {($keepCompressorOpen == 0)} {
	    tclAE::send -p '${sig}' "aevt" "quit"
	}
    } else {
	# Does this actually work in Windows?
	if {![catch {app::runScript $archiver $msg "" 1 0 [list $path]} errorMsg]} {
	    set result 1
	}
    }
    # End of archiving application interaction.
    if {$result} {
	status::msg "$msg complete"
    } elseif {!$debugging || ![info exists errorMsg]} {
        status::msg "$msg failed!"
    } else {
	dialog::alert $errorMsg
    }
    return $result
}

##
 # --------------------------------------------------------------------------
 #
 # "file::archiveFile" --
 # 
 # A very basic procedure supporting a "File > File Utils > Archive File"
 # menu command that prompts the user to identify a file or folder and an
 # archiving technique to be used.
 #
 # --------------------------------------------------------------------------
 ##


namespace eval file {}

proc file::archiveFile {} {
    compress::archiveFile
    compress::openDestinationFolder 1
}

# ===========================================================================
#
# ◊◊◊◊ ------------ ◊◊◊◊ #
# 
# ◊◊◊◊ Version History ◊◊◊◊ #
# 
# modified by  rev    reason
# -------- --- ------ -----------
# 
# 10/19/02 cbu 0.1    Original, based on the procs [file::Utils::stuffFile]
#                      and [file::Utils::stuffOpenWindows] in the earlier
#                      versions of "fileUtils.tcl".
#                     Added more file/folder compression listing options.
#                     Added support for 'DropTar' compression.
# 04/21/03 cbu 0.2    Added CM item for compression.
#                     Added support for 'Gzip' compression, although it
#                       is currently incomplete.
#                     Consolidated compression utilities into four major
#                       procs: [compressWindow], [compressWindowFolder],
#                       [compressFiles], and the basic [compressFile].
#                     We now check to see if the compressor utility was
#                       open before we started, and if so we don't kill it
#                       when we're through.
# 08/01/03 cbu 0.3    Everything is now in the "compress" namespace, made
#                       a better distinction between UI procedures (i.e.
#                       the menu and its direct support) versus the API
#                       for file compression that can be used by other code.
#                     It should be possible to call [compress::archiveFile]
#                       with a valid filename and let these procedures take
#                       care of everything else.
# 08/19/03 cbu 0.4    Each Archiver has its own destination folder and its
#                       own "Auto Open ... Destination" preference.
#                     [compress::packagePrefs] now handles prefs dialog.
#                     New "Config > Preferences > File Compression" submenu.
# 04/29/04 cbu 0.4.1  Added a "Help" button in the preferences dialog.
#                     Added an [alpha::feature] "description" argument.
# 

# ===========================================================================
# 
# .