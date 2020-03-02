## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "recentDirs.tcl"
 #                                          created: 06/10/2001 {10:19:51 pm}
 #                                      last update: 02/28/2006 {04:34:05 PM}
 #                               
 # Description:
 # 
 # Creates a "Files > Recent Dirs" submenu which includes the collection of
 # all recently used volumes and directories.  Selecting any menu item will
 # open a standard OS Find File dialog, using the chosen directory as the
 # default.
 # 
 # Optionally inserts 'Save In' and 'Save A Copy In' menus as well.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 #
 # Many thanks to Darryl Smith and Bernard Desgraupes for several suggestions
 # and a lot of beta testing.
 # 
 # Copyright (c) 2001-2006  Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

# ×××× Feature Declaration ×××× #
alpha::feature recentDirsMenu 1.3.8 "global-only" {
    # Initialization script.
    # Register build procs for each menu.
    menu::buildProc recentDirs         {recent::buildDirsMenu}
    menu::buildProc saveACopyIn        {recent::buildDirsMenu}
    menu::buildProc saveIn             {recent::buildDirsMenu}
    menu::buildProc showDirInFinder    {recent::buildDirsMenu}
} {
    # Activation script.
    hook::register openHook            {recent::pushDir}
    hook::register winChangedNameHook  {recent::pushDir}
    hook::register resumeHook          {recent::verifyDirsList}
    # Insert the menus, and add the dirs of any open windows.
    recent::insertDirsMenus "all" "insert"
    foreach f [winNames -f] {
	recent::pushDir $f
    }
    unset -nocomplain f
    # Add the pref dialog panes.
    package::addPrefsDialog "recentDirsMenu"
    package::addPrefsDialog "recentDirsBindings"
} {
    # De-activation script.
    hook::deregister openHook           {recent::pushDir}
    hook::deregister winChangedNameHook {recent::pushDir}
    hook::deregister resumeHook         {recent::verifyDirsList}
    # Remove the menus.
    recent::insertDirsMenus "all" "uninsert"
    # Remove the pref dialog panes.
    package::removePrefsDialog "recentDirsMenu"
    package::removePrefsDialog "recentDirsBindings"
} uninstall {
    this-file
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} description {
    This package inserts a 'Recent Dirs' submenu in the File menu,
    which keeps track of all recently used directories
} help {
    This feature is similar to the package: recentFilesMenu, but keeps track
    of the parent directories (and optionally volume names) of all recently
    used files rather than the actual filenames.  You can turn this package
    on by selecting the "Config > Global Setup > Features" menu item and
    clicking on the checkbox next to "Recent Dirs".
    
    Preferences: Features

    
	  	Table Of Contents

    "# Recent Dirs menu"
    "# Save (A Copy) In menus"
    "# Directory Lists Preferences"
    "# Recent Dirs Utilities"
    "# Performance Issues"

    <<floatNamedMarks>>


	  	Recent Dirs menu
    
    This package creates and inserts a new "File > Recent Dirs" submenu
    which contains the names of all 'remembered' directories, added whenever
    a file is opened in Alpha.  Selecting any directory or volume name will
    open a standard OS "Find File" dialog using the selected item as the
    default location.  This package also defines several different contextual
    menu modules similar to the menus described below.
    
    To set the max number of items listed in the menu (15 is the default)
    select "Recent Dirs > Recent Dirs Prefs".
    
    Preferences: recentDirsMenu
    
    This dialog contains additional preferences which determine how the
    'Recent Dirs' menu is built -- read the "# Directory Lists Preferences"
    section below for more information.

    Tip: In Alpha (not Alphatk) holding down any modifier key while selecting
    a menu item will open it in the OS Finder instead of opening a Find File
    dialog.  To reverse this behavior, turn on the Recent Dirs preference
    named 'Open Item In Finder' in the preferences dialog.
    
    You also have the option to insert a new submenu to open any recent
    directory in the OS Finder, "File > File Utiles > Show Dir In Finder" by
    turning on the "Show Dir In Finder Menu" preference.
    

	  	Save (A Copy) In menus
    
    This package can also insert two new 'Save' submenus into the File menu,
    named 'Save In' and 'Save A Copy In'.  These menus will contain the exact
    same list of directories/volumes as the 'Recent Dirs' menu.  These are
    added if the 'Save (A Copy) In Menu' preferences are set in the
    preferences dialog.
    
    Selecting any menu item will either save a copy or save the current
    window IN the selected directory, bypassing the 'Save' dialog.  You will
    be prompted for the name of the file to be saved.  If the target file
    already exists, you will be asked if you want to replace it -- clicking
    on 'No' will cancel the operation.
    
    Tip: In Alpha (not Alphatk), holding down any modifier key while
    selecting a menu item in these 'Save' menus will automatically use the
    name of the current window, bypassing the prompt.  If the target file
    already exists, you will still be asked if you want to replace it.
    
    To reverse this behavior, so that you are prompted for a new filename
    ONLY if a modifier is pressed, set the 'saveUsingWindowName' preference
    in the preferences dialog.
    

	  	Directory Lists Preferences
    
    This package has a number of different preferences which can change how
    the list of recent directories will be built.  Changing any of these
    preferences will affect ALL of the submenus added by this package.
    

    This is a 'flag' preference, which can be turned on or off:
    
	Order Items Alphabetically
    
    Order all items alphabetically.  Otherwise, items are listed in the order
    in which they were last accessed, the most recent listed first.
    
    
    The remaining preferences can take on several different values:

	Number Of Recent Dirs
    
    The number of directories/volumes 'remembered' when building the list.
    This will include items that might be ignored by the next three prefs.
    
	Display In Menu ...
   
    Items can be displayed with their full path name, only their tails, or
    with 'distinct' file tails.  With the second option, duplicate items are
    ignored, and only the most recent directory with the given name is used
    in the menu.  With the third option, duplicate directories are listed
    with their parent directories to indicate an unambiguous location.

	Missing Items Should Be ...
    
    When building the menu, the existence of directory/volume can be checked,
    and if found to be missing can be ignored, included, or dimmed in the
    menu.
    
    Note: In the Windows OS, directories which might exist over a network are
    never checked to see if they actually exist, since this might cause a big
    hangup -- they are always included in the menu.  In the MacOS, networked
    items ARE checked for existence.
    
	Networked Items Should Be ...

    Since networked items (in the Windows OS) are never checked to see if
    they exist, and selecting a missing networked item might cause trouble,
    it might be useful to mark them in the menu so that you know which ones
    they are.  Networked items can also be simply ignored, or included in the
    menu.  This preference currently has no effect in the MacOS.

	Volumes Should Be ...

    Technically, any file in the top level of a volume (such as your hard
    drive or an ejectable disk) is not actually contained in a directory.
    Volume names can be ignored, included, or placed in their own section in
    the menu.


	  	Recent Dirs Utilities
    
    The main "File > Recent Dirs" menu contains several items which can also
    help maintain the list of directories.  Again, changing the list for one
    menu changes the lists for the others as well.
    
	Reset List
    
    Flushes the list of all remembered directories and volumes.
    
	Add Directory ...
    
    Opens a dialog allowing you to select directories which will be added to
    the menu.  Note that volumes can NOT be selected, only directories within
    them.  After choosing a directory, the same dialog will re-appear
    allowing you to select another -- click on 'Cancel' when you are finished
    adding directories.
    
	Remove Menu Item ...
    
    Opens a list-pick dialog containing all of the current directories or
    volumes listed in the menu.  Selecting one or more of them will remove
    them from the menu(s).
    
	Rebuild Menu(s)
    
    This item should rarely be needed, because whenever a file is opened its
    parent directory/volume is always added to the list, and any missing
    items are dealt with according to the preferences described above.  If
    any of the menus seem out of date, however, use this item to rebuild
    them.
    
	Recent Dirs Prefs ...
    
    Opens a dialog containing all of the preferences associated with this
    package.  Click on the 'Help' button in the dialog to obtain a short
    description of each preference listed.
    
	Recent Dirs Bindings ...

    You can set keyboard shortcuts to open/save/display any item in the cache
    of recent directories.  Click here <<recent::dirsPackageOptions
    Bindings>> to set these now.  These shortcuts normally require this
    package to be activated -- otherwise the list of directories is not
    maintained.

	Recent Dirs Help

    Opens this window.


	  	Performance Issues

    If you have a slower processor, activating this package might slow down
    this intitial startup of Alpha.  If this is the case, you probably want
    to set the 'Use Cache At Startup' preference, which will the menu list
    saved from when you last used Alpha, but won't check to see if the
    existence of any items has changed since your last editing session.
    
    If opening a window seems to take too long, you might also consider
    setting the following preferences to these values to make the Recent Dirs
    menus rebuild a little bit faster, listed in the order in which they'll
    have the greatest effect:

    Order Items Alphabetically --       Yes (turn this item on)
    Display In Menu --                  Any value except 'Distinct File Tails'
    Missing Items Should Be --          Included
    Networked Items Should Be --        Included
    Volumes Should Be --                Included
    
    Note that since all of the "File > Save (A Copy) In" etc menus use the
    same list of menu items, turning any of them on or off probably will not
    have any noticable effect on startup or opening windows.
}

proc recentDirs.tcl {} {}

# ×××× Recent Dirs Prefs ×××× #

prefs::renameOld \
  recentDirsMenumodeVars(orderItemsAlphabetically) \
  recentDirsMenumodeVars(orderDirsAlphabetically)

# By default, the 'Recent Dirs' menu items open an OS 'Find File' dialog,
# but if any modifier key is held then the directory is opened in the OS
# Finder.  Turn this item on to reverse these behaviors||Turn this item off
# to restore the default behavior of modifier keys in the 'Recent Dirs'
# menu item
newPref flag openItemInFinder           0 recentDirsMenu
# To listed recent directories alphabetically, turn this item on||To list
# directories in the order that they were most recently accessed, turn this
# item off
newPref flag orderDirsAlphabetically    1 recentDirsMenu recent::buildDirsMenu
# To insert a 'Save A Copy In' submenu in the File menu, turn this item on.
# Selecting any menu item will save a copy of the current window into the
# chosen directory or volume||To remove the 'Save A Copy In' menu, turn
# this item off
newPref flag saveACopyInMenu            0 recentDirsMenu recent::insertDirsMenus
# To insert a 'Save In' submenu in the File menu, turn this item on.
# Selecting any menu item will save the current window into the chosen
# directory or volume||To remove the 'Save In' menu, turn this item off
newPref flag saveInMenu                 0 recentDirsMenu recent::insertDirsMenus
# By default, the 'Save In' and 'Save A Copy In' menu items prompt the user
# for a new filename which will be saved in the given directory or volume,
# but if any modifier key is held then the name of the current window is
# used.  Turn this item on to reverse these behaviors||Turn this item off
# to restore the default behavior of modifier keys in the 'Save (A Copy) In'
# menus
newPref flag saveUsingWindowName        0 recentDirsMenu

# As of this writing, 'getModifiers' doesn't work in Alphatk, so we offer a
# different menu instead for opening a directory in the Finder.

# To insert a 'Show Dir In Finder' submenu in the 'File Utils' menu, turn
# this item on.  Selecting any menu item will save a copy of the current
# window into the chosen directory or volume||To remove the 'Show Dir In
# Finder' menu, turn this item off
newPref flag showDirInFinderMenu        0 recentDirsMenu recent::insertDirsMenus
# To use a cache of the Recent Dirs items when restarting Alpha (which is
# quicker but might not accurately reflect missing dirs) turn this item
# on||To always check the list of Recent Dirs items to see if they exist
# when restarting Alpha (which might take a little longer) turn this item
# off
newPref flag useCacheOnStartup          0 recentDirsMenu
# Recent items can be listed with their full path names, or only their file
# tails.  If 'Distinct File Tails' is selected, multiple items with the same
# tail will be identified with parent directories, displaying an unambiguous
# disk location.  The first two options rebuild the menu very quickly, the
# last takes the most time.
newPref var displayInMenu               2 recentDirsMenu recent::buildDirsMenu \
  [list "Full Path Names" "File Tails Only" "Distinct File Tails"] index
# Networked item (on the Windows OS) are never checked to see if they exist
# because if you are no longer on the network this can cause a big hangup.
# Networked items can be ignored, included, or marked as such in the menu.
newPref var networkedItemsShouldBe      2 recentDirsMenu recent::buildDirsMenu \
  [list "Ignored" "Included In Menu" "Marked In Menu"] index
# If a directory or volume cannot be found while rebuilding the menu, the
# item can be ignored or dimmed in the menu.  Note that networked items are
# never checked for existence.
newPref var missingItemsShouldBe        2 recentDirsMenu recent::buildDirsMenu \
  [list "Ignored" "Included In Menu" "Dimmed In Menu"] index
# The number of recent directories to remember when building the menu.
newPref var numberOfRecentDirs          15 recentDirsMenu recent::buildDirsMenu
# Technically, any file in the top level of a volume is not actually
# contained in a directory.  Volume names can be ignored, included, or
# placed in their own section in the menu.
newPref var volumesShouldBe             2 recentDirsMenu recent::buildDirsMenu \
  [list "Ignored" "Included In Menu" "Separated In Menu"] index

# Recent Dirs Bindings
# 
# We create a 'separate' package here with bindings.  These aren't included
# in the menu, so that the user can create them with prefixes if desired.
# 

# Use this binding to open a dialog to select a directory to open.
newPref binding openRecentDir "" recentDirsBindings "" \
  {recent::dirsMenuShortcut "open"}
# Use this binding to open a dialog to select a directory to save a copy of
# the current window into.
newPref binding saveACopyIn   "" recentDirsBindings "" \
  {recent::dirsMenuShortcut "save a copy in"}
# Use this binding to open a dialog to select a directory to save the current
# window into.
newPref binding saveIn        "" recentDirsBindings "" \
  {recent::dirsMenuShortcut "save in"}
# Use this binding to open a dialog to select a directory to open in the
# Finder.
newPref binding showRecentDir "" recentDirsBindings "" \
  {recent::dirsMenuShortcut "show in Finder"}

# Contextual Menu modules.

# Includes the directory names of the most recently opened files.  Selecting
# a directory name will trigger an "Open File" dialog using that directory as
# the default location.
newPref f recentDirsMenu       0 contextualMenu
# Includes the directory names of the most recently opened files.  Selecting
# a directory name will save a copy of the active window in that location
newPref f saveACopyInMenu      0 contextualMenu
# Includes the directory names of the most recently opened files.  Selecting
# a directory name will save the active window in that location
newPref f saveInMenu           0 contextualMenu
# Includes the directory names of the most recently opened files.  Selecting
# a directory name will open that location in the Finder
newPref f showDirInFinderMenu  0 contextualMenu

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Recent Dirs Menu ×××× #
# 

namespace eval recent {
    
    global recentDirsMenumodeVars

    # Make sure that we some variables in place.
    foreach item [list Directories DirsMenuCache DirsMarkList DirsDimList] {
	variable $item
	if {![info exists $item]} {
	    set $item [list]
	}
	prefs::modified $item
    }
    variable LastDirChosen ""
    # Remove the menu cache if desired -- forces a call to [recent::listDirs]
    # during the building of the menu when Alpha is started up and activating
    # this package.
    if {!$recentDirsMenumodeVars(useCacheOnStartup)} {
	unset -nocomplain DirsMenuCache
	unset -nocomplain DirsMarkList
	unset -nocomplain DirsDimList
    }
}

##
 # --------------------------------------------------------------------------
 #
 # "recent::insertDirsMenus" --
 #
 # Called by the (de)activate arguments in the package declaration, also by
 # the package prefs dialog when adding/removing optional menus.  Also
 # (de)registers Open Windows hooks for the optional menus.
 # 
 # --------------------------------------------------------------------------
 ##

proc recent::insertDirsMenus {pref {which ""}} {
    
    global recentDirsMenumodeVars
    
    if {($pref eq "all")} {
	set menus "recentDirs"
	foreach menuOption {saveIn saveACopyIn showDirInFinder} {
	    if {$recentDirsMenumodeVars(${menuOption}Menu)} {
		lappend menus $menuOption
	    }
	}
    } elseif {[regsub {Menu$} $pref {} menus]} {
	set which $recentDirsMenumodeVars($pref)
    } else {
	error "No valid menu could be defined."
    }
    foreach what $menus {
	switch $which {
	    "0"                 {set which uninsert}
	    "1"                 {set which insert}
	}
	# These last two will screw up some of the dynamic menu items, but
	# I'm not sure yet how to avoid this.  Maybe this is a feature
	# rather than a bug ...
	switch $what {
	    "recentDirs"        {set where "<E<S/Wclose"}
	    "saveIn"            {set where "<E<S/Ssave"}
	    "saveACopyIn"       {set where "<E<S/Ssave"}
	    "showDirInFinder"   {set where "showInFinder"}
	}
	switch $what {
	    "showDirInFinder"   {set who "fileUtils"}
	    default             {set who "File"}
	}
	menu::$which $who submenu $where $what
	# Register open window hooks.
	if {[regexp {^save.*In} $what]} {
	    if {($which eq "insert")} {
		hook::register requireOpenWindowsHook [list $who $what] 1
	    } else {
		hook::deregister requireOpenWindowsHook [list $who $what] 1
	    }
	}
	# Generate a message.
	if {($what ne "recentDirs")} {
	    if {($which eq "insert")} {
		set msg "The '$what' menu has been inserted."
	    } else {
		set msg "The '$what' menu has been removed."
	    }
	}
    }
    if {($pref ne "all") && [info exists msg]} {
	status::msg $msg
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "recent::pushDir" --
 #
 # Works with files whose name contained '[' or ']'.
 # Doesn't add to the menu the dir of any file which fails 'file exists'.
 # 
 # Called by either a hook or a menu item.  'args' is used in case this is
 # called by the 'winChangedName' hook.  <JK date="feb2006>The old hook,
 # 'winChangeNameHook' gave the old win name as first argument, and for this
 # reason [recent::pushDir] had to take instead [lindex $args 0] as fileName.
 # The new hook 'winChangedName' has the new name as first argument and the
 # old as second.  Hence we can directly use the fileName argument without
 # the need of looking in the $args arguments.</JK>
 # 
 # --------------------------------------------------------------------------
 ##

proc recent::pushDir {fileName args} {
    
    global recentDirsMenumodeVars
    variable Directories
    
    # Adding items to the menu.
    
    set fileName [file nativename [win::StripCount $fileName]]
    set dirName  [file dirname $fileName]
    set rebuild  1
    # More tests could be included here.
    if {![file exists $fileName] && ([lindex $args 1] ne "over-ride")} {
	# This isn't an actual file, and isn't being added by a menu item.
	return
    } elseif {[file::pathStartsWith $dirName [temp::directory ""]]} {
	# Don't include temporary directories (such as ftp ...)
	return
    } elseif {($fileName eq [file separator]) || ![llength $dirName]} {
	# Work-around for new 'file' command implementation in 7.5d1-d7.
	# There's probably a better way of handling this.
	set dirName ${fileName}[file separator]
    } elseif {![string match *[file separator]* $dirName]} {
	# More work-around for new 'file' command implementation.
	append dirName [file separator]
    }
    # Make sure that the directory exists before we add it.  Once it's
    # in the list, it stays there unless the user removes it.
    if {![file isdirectory $dirName]} {
	return
    }
    # Have we seen this one before?
    if {([set i [lsearch -exact $Directories $dirName]] != -1)} {
	# This dir/volume has already been included, so we just put it
	# at the end of the list.
	set Directories [lreplace $Directories $i $i]
	set rebuild 0
    }
    lappend Directories $dirName
    if {[regexp {^[0-9]+$} $recentDirsMenumodeVars(numberOfRecentDirs)]} {
	set limit $recentDirsMenumodeVars(numberOfRecentDirs)
    } else {
	set limit 100
    }
    if {([llength $Directories] > $limit)} {
	set Directories [lrange $Directories 1 end]
    }
    if {$rebuild || !$recentDirsMenumodeVars(orderDirsAlphabetically)} {
	recent::buildDirsMenu 0
    }
    return
}


##
 # --------------------------------------------------------------------------
 #
 # "recent::verifyDirsList" --
 #
 # Registered as resumeHook.  Run through the Directories list, and if an
 # item is not a valid directory or is not properly dimmed, request menu
 # rebuilding.  The idea of this proc, although it repeats some
 # functionality from [recent::buildDirsMenu], is that we should only
 # rebuild the menu if there is some reason for doing so.  After all, this
 # hooks triggers every time we switch back and forth (which can happen
 # really a lot, for example in TeX mode).
 # 
 # <JK date="feb2006">I confess I don't know if some special treatment of
 # networked volumes is due here.</JK>
 # --------------------------------------------------------------------------
 ##

proc recent::verifyDirsList { args } {
    global recentDirsMenumodeVars
    if { $recentDirsMenumodeVars(missingItemsShouldBe) == 1 } {
	# According to the prefs, we should not clean up the list at all.
	return
    }
    variable Directories
    variable DirsDimList
    foreach dir $Directories {
	if { ![file isdirectory $dir] } {
	    if { $recentDirsMenumodeVars(missingItemsShouldBe) == 0 } {
		set Directories [lremove $Directories [list $dir]]
		buildDirsMenu rebuild
		return
	    } elseif { $recentDirsMenumodeVars(missingItemsShouldBe) == 2 &&
	      ([info exists DirsDimList] && ![lcontain $DirsDimList [file tail $dir]]) } {
		# An item needs dimming:
		buildDirsMenu rebuild
		return
	    }
	}
    }
}


##
 # --------------------------------------------------------------------------
 #
 # "recent::buildDirsMenu" --
 #
 # Building the menu.
 # 
 # Called by [recent::pushDir], a menu item, or when some prefs change.
 # [recent::listDirs] will determine the order of the items -- if anything
 # needs to be dimmed or marked, we do that here after creating the menus.
 # 
 # The variable 'recent::DirsMenuCache' is really only used when the package
 # is first activated, to make sure that we don't have to rebuild the same
 # menuList up to four times in a row.
 # 
 # --------------------------------------------------------------------------
 ##

proc recent::buildDirsMenu {{pref ""}} {
    
    global recentDirsMenumodeVars
    
    variable Directories
    variable DirsDimList
    variable DirsMarkList
    variable DirsMenuCache
    
    if {[string length $pref]} {
	# Don't use the menu caches.
	unset -nocomplain DirsMenuCache
	unset -nocomplain DirsMarkList
	unset -nocomplain DirsDimList
	if {($pref eq "numberOfRecentDirs")} {
	    # Called from the prefs dialog.
	    set limit $recentDirsMenumodeVars(numberOfRecentDirs)
	    if {![regexp {^[0-9]+$} $limit]} {
		alertnote "The 'Number of Recent Dirs' preference should be a number."
		recent::dirsMenuProc "" "Recent Dirs Prefs"
		return
	    } else {
		set limit [expr $limit - 1]
		set Directories [lrange $Directories 0 $limit]
	    }
	} elseif {($pref eq "rebuild")} {
	    # This is a "hard" rebuild, which will also remove all duplicates.
	    set Directories [lunique $Directories]
	}
    }

    set menuNames "recentDirs"
    foreach menuOption {saveACopyIn saveIn showDirInFinder} {
	if {$recentDirsMenumodeVars(${menuOption}Menu)} {
	    lappend menuNames $menuOption
	}
    }
    if {[info exists DirsMenuCache]} {
	# This makes building the menus quicker when the package is first
	# activated.  Otherwise, the cache is usually unset above.
	set menuList1 $DirsMenuCache
    } else {
	set menuList1 [recent::listDirs]
    }
    
    # Add the Recent Dirs Utils items.
    set menuList2 [list                                                        \
      "(-)" "Reset List" "Remove Menu ItemÉ" "Add DirectoryÉ" "Rebuild Menu"   \
      "(-)" "Recent Dirs PrefsÉ" "Recent Dirs BindingsÉ" "Recent Dirs Help"                            ]
    if {([llength $menuNames] != 1)} {
	set menuList2 [lreplace $menuList2 4 4 "Rebuild Menus"]
    }
    # Create the menus.
    set menuProc "recent::dirsMenuProc"
    Menu -c -m -n recentDirs      -p $menuProc "$menuList1 $menuList2"
    Menu -c -m -n saveACopyIn     -p $menuProc $menuList1
    Menu -c -m -n saveIn          -p $menuProc $menuList1
    Menu -c -m -n showDirInFinder -p $menuProc $menuList1
    # Do we have anything in the list?
    if {([lindex $menuList1 0] eq "No Saved Dirs")} {
	# No.
	foreach menuName $menuNames {
	    enableMenuItem -m $menuName "No Saved Dirs" off
	}
	foreach item {"Reset List" "Remove Menu ItemÉ"} {
	    enableMenuItem -m recentDirs $item off
	}
    } else {
	# Yes, so dim or mark as necessary.
	if {($recentDirsMenumodeVars(networkedItemsShouldBe) == 2)} {
	    foreach menuName $menuNames {
		if {![info exists DirsMarkList]} {
		    break
		}
		foreach item $DirsMarkList {
		    markMenuItem -m $menuName $item on ~
		}
	    }
	}
	if {($recentDirsMenumodeVars(missingItemsShouldBe) == 2)} {
	    foreach menuName $menuNames {
		if {![info exists DirsDimList]} {
		    break
		}
		foreach item $DirsDimList {
		    enableMenuItem -m $menuName $item off
		}
	    }
	}
    }
    if {[string length $pref] && ($pref != "0")} {
	if {([llength $menuNames] == 1)} {
	    status::msg "The 'Recent Dirs' menu has been rebuilt."
	} else {
	    status::msg "The Recent Dir menus have been rebuilt."
	}
    }
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "recent::listDirs" --
 #
 # Create a nice list for the menu, only adding parent directories of
 # remembered items if necessary to avoid ambiguity.  Possiblly Goes through
 # two more passes of the list to re-order or remove items as necessary,
 # determined by a few different package preferences.
 # 
 # --------------------------------------------------------------------------
 ##

proc recent::listDirs {} {
    
    global recentDirsMenumodeVars
    
    variable Directories
    variable DirsDimList
    variable DirsMarkList
    variable DirsMenuCache

    set DirsMarkList ""
    set DirsDimList  ""
    set menuList ""
    set dirList   $Directories
    
    set displayAs $recentDirsMenumodeVars(displayInMenu)
    set volumes   $recentDirsMenumodeVars(volumesShouldBe)
    set networked $recentDirsMenumodeVars(networkedItemsShouldBe)
    set missing   $recentDirsMenumodeVars(missingItemsShouldBe)

    if {($displayAs != 2)} {
	# Don't show distinct duplicate file tails in the menu.
	foreach d $dirList {
	    # Dealing with volumes.
	    if {[string match *[file separator] $d]} {
		# This Item is a volume.
		if {($volumes != 0)} {
		    # Include it and move on.
		    lappend menuList $d
		}
		continue
	    }
	    # Dealing with networked or missing items.
	    if {[file::isNetworked $d]} {
		# Remove networked items from the menu list.
		if {($networked == 0)} {
		    continue
		}
	    } elseif {![file exists $d]} {
		# Remove missing items from the menu list .
		if {($missing == 0)} {
		    continue
		}
	    }
	    if {($displayAs == 0)} {
		# Include full path names in the menu.
		lappend menuList $d
	    } else {
		# Include file tails in the menu.
		lappend menuList [file tail $d]
	    }
	}
    } else {
	# Display distinct duplicates in the menu.  We would use
	# 'file::minimalDistinctTails', but that automatically removes
	# files that don't exist.
	set level 1
	while {1} {
	    foreach d $dirList {
		# Dealing with volumes.
		if {[string match *[file separator] $d]} {
		    # This Item is a volume.
		    if {($volumes == 0)} {
			# Volumes should not be included.
			continue
		    }
		}
		# Dealing with networked or missing items.
		if {[file::isNetworked $d]} {
		    # Remove networked items from the menu list.
		    if {($networked == 0)} {
			continue
		    }
		} elseif {![file exists $d]} {
		    # Remove missing items from the menu list .
		    if {!$missing} {
			continue
		    }
		}
		set llen [llength [set tail [file split $d]]]
		if {($d eq [file separator])} {
		    # Odd case, happens with volumes.
		    set i [lsearch -exact $Directories $d]
		    set Directories [lreplace $Directories $i $i]
		} elseif {[regexp "[quote::Regfind [file separator]]$" $d]} {
		    # This item is a volume.
		    lappend menuList $d
		    continue
		} elseif {($llen < $level)} {
		    # We've exceeded the top-level.  Must be an odd problem!
		    # Discard this problematic file.
		    continue
		}
		set tail [join [lrange $tail [expr {$llen - $level}] end] [file separator]]
		if {[info exists name($tail)]} {
		    lappend remaining $name($tail)
		    lappend remaining $d
		    set dup($tail) 1
		    set first [lsearch -exact $menuList $tail]
		    set menuList [lreplace $menuList $first $first $name($tail)]
		    if {($level == 1)} {
			lappend menuList $d
		    }
		    unset name($tail)
		} elseif {[info exists dup($tail)]} {
		    lappend remaining $d
		    if {($level == 1)} {
			lappend menuList $d
		    }
		} else {
		    set name($tail) $d
		    if {($level == 1)} {
			lappend menuList $tail
		    } else {
			set toolong [lsearch -exact $menuList $d]
			set menuList [lreplace $menuList $toolong $toolong $tail]
		    }
		}
	    }
	    if {![info exists remaining]} {
		break
	    }
	    incr level
	    set dirList $remaining
	    unset remaining
	    unset dup
	}
    }
    # Make sure that we have a unique list
    set menuList [lunique $menuList]
    # Odd little bug with top-level folders.  Not sure where it happens above.
    set pat [quote::Regfind [file separator][file separator]]
    regsub -all $pat $menuList [file separator] menuList
    # List either alphabetically, or in order of last appearance.
    if {$recentDirsMenumodeVars(orderDirsAlphabetically)} {
	set menuList [lsort -dictionary $menuList]
    } else {
	set menuList [lreverse $menuList]
    }
    # Do we have anything in the menu list?
    if {![llength $menuList]} {
	# No.
	set DirsMarkList ""
	set DirsDimList  ""
	return [set DirsMenuCache [list "No Saved Dirs"]]
    }
    # Yes, perform some tests to see if any items should be marked or dimmed.
    set test2 $recentDirsMenumodeVars(networkedItemsShouldBe)
    set test3 $recentDirsMenumodeVars(missingItemsShouldBe)
    if {($volumes == 2)} {
	# We have to first separate volumes if necessary, in order to properly
	# determine where marked or dimmed items will be located.
	set volsList  ""
	set dirsList  ""
	foreach item $menuList {
	    foreach d $Directories {
		# Link it to the menu item ...
		set pat1 [quote::Find [file separator]]
		set pat2 [quote::Find [file normalize [file separator]]]
		set match1 [string match "*${pat1}${item}" $d]
		set match2 [string match "*${pat2}${item}" $d]
		if {($item eq $d) || $match1 || $match2} {
		    # ...  if it matches the end of the directory we know it
		    # is unique (because of all of the work done above). If
		    # it doesn't match, we just continue.
		    set isVolume [string match *$pat1 $d]
		    if {($volumes == 2) && $isVolume} {
			# Separate volumes into their own section.
			lappend volsList $item
		    } else {
			lappend dirsList $item
		    }
		    continue
		}
	    }
	}
	# Now create the revised list of menu items.
	if {[llength $volsList]} {
	    set menuList "$volsList (- $dirsList"
	} else {
	    set menuList $dirsList
	}
    }
    set menuList [lunique $menuList]
    if {($networked == 2) || ($missing == 2)} {
	# Determine where marked or dimmed items will be located.
	set DirsMarkList ""
	set DirsDimList  ""
	foreach item $menuList {
	    foreach d $Directories {
		# Link it to the menu item ...
		set match1 [string match "*[file separator]$item" $d]
		set match2 [string match "*[file nativename [file separator]]$item" $d]
		if {($item eq $d) || $match1 || $match2} {
		    # ...  if it matches the end of the directory we know it
		    # is unique (because of all of the work done above). If
		    # it doesn't match, we just continue.
		    if {[file::isNetworked $d]} {
			if {($networked == 2)} {
			    # Mark networked items.
			    lappend DirsMarkList $item
			}
		    } elseif {![file exists $d]} {
			if {($missing == 2)} {
			    # Dim missing items.
			    lappend DirsDimList  $item
			}
		    }
		    continue
		}
	    }
	}
    }
    return [set DirsMenuCache $menuList]
}

##
 # --------------------------------------------------------------------------
 #
 # "recent::dirsMenuProc" --
 #
 # Works with menu items which contain '[', ']' and 'É'.
 # 
 # --------------------------------------------------------------------------
 ##

proc recent::dirsMenuProc {menuName itemName args} {
    
    global recentDirsMenumodeVars
    
    variable Directories
    variable DirsMenuCache
    variable ItemDirConnect
    
    if {[getModifiers]} {
	set modified 1
    } else {
	set modified 0
    }
    set rD $Directories

    switch $itemName {
	"Reset List" {
	    if {$modified} {
		alertnote "Use this menu item to reset the list of remembered directories."
	    } else {
		set Directories ""
		recent::buildDirsMenu 1
	    }
	}
	"Add DirectoryÉ" -
	"Add Directory" {
	    if {$modified} {
		alertnote "Use this menu item to add to the list of remembered directories."
	    } elseif {[llength $args]} {
		foreach path $args {
		    recent::pushDir "" [file join $path dummy] "over-ride"
		}
	    } else {
		set newDir [get_directory]
		recent::pushDir "" [file join $newDir dummy] "over-ride"
		status::msg "'[file tail $newDir]' has been added to the 'Recent Dirs' menu."
		set    question "Would you like to add more directories?\r"
		append question "If so, the dialog will reappear until you press 'Cancel'."
		if {![askyesno $question]} {
		    return
		}
		set p "Select another, or cancel:"
		while {![catch {get_directory -p $p} newDir]} {
		    recent::pushDir "" [file join $newDir dummy] "over-ride"
		    status::msg "'[file tail $newDir]' has been added to the 'Recent Dirs' menu."
		}
	    }
	}
	"Remove Menu ItemÉ" -
	"Remove Menu Item" {
	    if {$modified && ![llength $args]} {
		alertnote "Use this menu item to remove items from the list of remembered directories."
		return
	    } elseif {![llength $args]} {
		set p "Select items to remove from the menu:"
		if {![info exists DirsMenuCache]} {
		    recent::listDirs
		}
		set pickList [lremove -all $DirsMenuCache [list "(-"]]
		if {[catch {listpick -p $p -l $pickList} args]} {
		    status::msg "Cancelled."
		    return
		}
	    }
	    foreach d $args {
		foreach dir $rD {
		    if {[string match *$d $dir]} {
			lappend removeList $dir
			break
		    }
		}
	    }
	    if {[info exists removeList]} {
		set Directories [lremove $rD $removeList]
	    } else {
		# Should never get here ...
		status::msg "Sorry, couldn't remove '$args'."
		return
	    }
	    recent::buildDirsMenu 1
	}
	"Rebuild Menu" -
	"Rebuild Menus" {
	    if {$modified} {
		alertnote "Use this menu item to rebuild the Recent Dir menu(s)."
	    } else {
		recent::buildDirsMenu rebuild
	    }
	}
	"Recent Dirs Help" {
	    if {$modified} {
		alertnote "Use this menu item to open the 'Recent Dirs Help' window."
	    } else {
		package::helpWindow   "recentDirsMenu"
	    }
	}
	"Recent Dirs PrefsÉ" -
	"Recent Dirs Prefs" {
	    if {$modified} {
		alertnote "Use this menu item to set the 'Recent Dirs Menu' preferences."
	    } else {
		prefs::dialogs::packagePrefs "recentDirsMenu"
	    }
	}
	"Recent Dirs BindingsÉ" -
	"Recent Dirs Bindings" {
	    if {$modified} {
		alertnote "Use this menu item to set the 'Recent Dirs Bindings' preferences."
	    } else {
		prefs::dialogs::packagePrefs "recentDirsBindings"
	    }
	}
	default {
	    if {[info exists ItemDirConnect($itemName)]} {
		set d $ItemDirConnect($itemName)
	    } else {
		set d [file::pathEndsWith $itemName $rD]
	    }
	    if {($d ne "") && [file exists $d]} {
		set dir $d
	    } elseif {[file exists $itemName]} {
		set dir $itemName
	    }
	    if {![info exists dir]} {
		set    question "Couldn't find '$itemName'.\r"
		append question "Would you like to remove it from the menu?"
		if {[askyesno $question]} {
		    recent::dirsMenuProc "" "Remove Menu Item" $itemName
		} elseif {($recentDirsMenumodeVars(missingItemsShouldBe) == 2)} {
		    recent::buildDirsMenu 1
		}
		return
	    }
	    switch $menuName {
		"saveIn" -
		"saveACopyIn"   {
		    if {![llength [winNames]]} {
			status::msg "This item requires an open window."
			return
		    }
		    if {$recentDirsMenumodeVars(saveUsingWindowName)} {
			set modified [expr -$modified + 1]
		    }
		    if {$modified} {
			# Save using the (stripped) current window name.
			file::$menuName $dir [win::StripCount [win::CurrentTail]]
		    } else {
			# Prompt the user for the window name.
			file::$menuName $dir ""
		    }
		}
		"showDirInFinder" -
		"recentDirs" {
		    if {($menuName eq "showDirInFinder")} {
			set modified 1
		    } elseif {$recentDirsMenumodeVars(openItemInFinder)} {
			set modified [expr -$modified + 1]
		    }
		    if {$modified} {
			# Try to show the directory in the Finder.
			file::showInFinder $dir
		    } else {
			# Open a 'Find File' dialog using this directory as
			# the default.
			findFile $dir
		    }
		}
	    }
	}
    }
    return
}

proc recent::dirsMenuShortcut {itemName {directory ""}} {
    
    global recentDirsMenumodeVars
    
    variable Directories
    variable DirsMenuCache
    variable ItemDirConnect
    variable LastDirChosen

    # Some actions require an open window.
    switch -- $itemName {
	"save in" - "save a copy in" {requireOpenWindow}
    }
    # Do we have a default directory to use?
    if {![string length $directory]} {
	if {![info exists DirsMenuCache]} {
	    recent::listDirs
	}
	if {([lindex [set dirs $DirsMenuCache] 0] eq "No Saved Dirs")} {
	    status::msg "No recent directories to choose from."
	    return
	}
	if {[lcontains dirs $LastDirChosen]} {
	    set L [list $LastDirChosen]
	} else {
	    set L [list [lindex $dirs 0]]
	}
	set p "Choose a directory to ${itemName}:"
	set LastDirChosen [set directory [listpick -p $p -L $L $dirs]]
	if {![file exists $directory]} {
	    if {[info exists ItemDirConnect($directory)]} {
		set directory2 $ItemDirConnect($directory)
	    } else {
		set directory2 [file::pathEndsWith $directory $Directories]
	    }
	    if {![file exists $directory2]} {
		set    question "Couldn't find '$directory'.\r"
		append question "Would you like to remove it from the menu?"
		if {[askyesno $question]} {
		    recent::dirsMenuProc "" "Remove Menu Item" $directory
		    return
		} elseif {($recentDirsMenumodeVars(missingItemsShouldBe) == 2)} {
		    recent::buildDirsMenu 1
		}
	    }
	    set directory $directory2
	}
    }
    # Does this directory exist?
    if {![file exists $directory]} {
	switch -- $itemName {
	    "open" - "show in Finder" {
		while {![file exists $directory]} {
		    set parent [file dirname $directory]
		    if {($parent eq $directory)} {
			set directory ""
			break
		    } else {
			set directory $parent
		    }
		}
	    }
	    default {
		alertnote "The directory '$directory' doesn't exist!"
		status::msg "Cancelled."
		return
	    }
	}
    }
    # Should we use the current window's name?
    if {$recentDirsMenumodeVars(saveUsingWindowName)} {
	set window [win::StripCount [win::CurrentTail]]
    } else {
        set window ""
    }
    # Execute the desired procedure.
    switch -- $itemName {
	"open"            {findFile $directory}
	"save in"         {file::saveIn $directory $window}
	"save a copy in"  {file::saveACopyIn $directory $window}
	"show in Finder"  {file::showInFinder $directory}
	default           {error "Unknown option: $itemName"}
    }
    return
}

# This ensures that prefs have been defined.
proc recent::dirsPackageOptions {which} {

    prefs::dialogs::packagePrefs recentDirs${which}
    return
}

# ===========================================================================
# 
# ××××  -------- ×××× #
# 
# These probably should go in 'fileManipulation.tcl'
# 

namespace eval file {}

##
 # --------------------------------------------------------------------------
 #
 # "file::saveIn" --
 #
 # Save the current window in a specified directory, bypassing the 'Save'
 # dialog, optionally prompting for a new fileName.
 #
 # --------------------------------------------------------------------------
 ##

proc file::saveIn {dirPath {fileName ""}} {

    requireOpenWindow

    status::msg "Saving in '${dirPath}' ..."

    set currentWindow [win::StripCount [win::Current]]
    set currentTail   [win::StripCount [win::CurrentTail]]

    if {![string match *[file separator] $dirPath]} {
	set dirName [file tail $dirPath]
    } else {
	set dirName $dirPath
    }
    if {![file exists $dirPath]} {
	# Make sure that the target directory/volume exists.
	status::msg "Sorry, '${dirPath}' could not be found."
	return
    } elseif {![string length $fileName]} {
	# Prompt the user for a new fileName.
	set p "Save in '${dirName}' as"
	if {[catch {prompt $p $currentTail} fileName]} {
	    status::msg "Cancelled."
	    return
	}
    }
    # Save the current window in the desired location.
    set newFile [file join $dirPath $fileName]
    if {([file nativename $newFile] eq $currentWindow)} {
	status::msg "Cancelled -- target file is the same as the original !!"
	return
    } elseif {[file exists $newFile]} {
	# Find out when the target file was last modified.
	set nfLastMod [file mtime $newFile]
	# Find out when the source file was last modified
	set cwLastMod [file mtime $currentWindow]
	# Which is newer?
	if {[expr {$nfLastMod < $cwLastMod}]} {
	    set which "An older file named"
	} elseif {[expr {$nfLastMod > $cwLastMod}]} {
	    set which "A newer file named"
	} else {
	    set which "A file named"
	}
	# Should we over-write the existing target?
	set   question "$which '${fileName}' already exists in '${dirName}'.\r\r"
	append question "Do you want to replace it?"
	if {![askyesno $question]} {
	    status::msg "Cancelled."
	    return
	}
    }
    saveAs -f $newFile
    save
    return
}

##
 # --------------------------------------------------------------------------
 #
 # "file::saveACopyIn" --
 #
 # Save a copy of the current window in a specified directory, bypassing
 # the 'Save' dialog, optionally prompting for a new fileName.
 #
 # --------------------------------------------------------------------------
 ##

proc file::saveACopyIn {dirPath {fileName ""}} {

    requireOpenWindow

    status::msg "Saving a copy in '${dirPath}' ..."

    set currentWindow [win::StripCount [win::Current]]
    set currentTail   [win::StripCount [win::CurrentTail]]

    if {![string match *[file separator] $dirPath]} {
	set dirName [file tail $dirPath]
    } else {
	set dirName $dirPath
    }
    if {![file exists $dirPath]} {
	# Make sure that the target directory/volume exists.
	status::msg "Sorry, '${dirPath}' could not be found."
	return
    } elseif {![win::IsFile $currentWindow]} {
	# Make sure that the current window is actually a file.
	status::msg "'$currentWindow' must first be saved."
	return
    } elseif {![string length $fileName]} {
	# Prompt the user for a new fileName.
	set p "Save a copy in '${dirName}' as"
	if {[catch {prompt $p $currentTail} fileName]} {
	    status::msg "Cancelled."
	    return
	}
    }
    # Save a copy of the current window in the desired location.
    set newFile [file join $dirPath $fileName]
    if {([file nativename $newFile] eq $currentWindow)} {
	status::msg "Cancelled -- target file is the same as the original !!"
	return
    } elseif {[file exists $newFile]} {
	# Find out when the target file was last modified.
	set nfLastMod [file mtime $newFile]
	# Find out when the source file was last modified
	set cwLastMod [file mtime $currentWindow]
	# Which is newer?
	if {[expr {$nfLastMod < $cwLastMod}]} {
	    set which "An older file named"
	} elseif {[expr {$nfLastMod > $cwLastMod}]} {
	    set which "A newer file named"
	} else {
	    set which "A file named"
	}
	# Should we over-write the existing target?
	set    question "$which '${fileName}' already exists in '${dirName}'.\r\r"
	append question "Do you want to replace it?"
	if {[askyesno $question]} {
	    # In order to use 'file copy', the target can NOT first exist.
	    catch {file delete $newFile}
	} else {
	    status::msg "Cancelled."
	    return
	}
    }
    if {[catch {file copy $currentWindow $newFile}]} {
	status::msg "Failed to copy '$currentTail' to '${dirName}'"
	return
    } elseif {![catch {getFileInfo $currentWindow fileArray}]} {
        if {[info exists fileArray(creator)]} {
            catch {setFileInfo $newFile creator $fileArray(creator)}
        } 
	if {[info exists fileArray(type)]} {
	    catch {setFileInfo $newFile type $fileArray(type)}
	} 
    }
    status::msg "'${newFile}' saved."
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
# 06/10/01 cbu 0.1    Original, based on 'recentFiles.tcl'.
# 06/12/01 cbu 0.2    Less restrictive inclusion of 'dir' names, can include
#                       volumes as well.
#                     If an item isn't found, the user is given the option
#                       to remove it from the menu.
#                     Items are added to the menu when a window is opened, not
#                       when closed.  (Using [openHook], not [closeHook].)
# 06/13/01 cbu 0.3    Bug fix for removing non-existent menu items.
#                     Added pref to reverse modifier key behavior.
#                     'Remove Menu Item' now lists items as in menu.
#                     Better menu addition of volume names ??  Involves a few
#                       work-arounds to compensate for new 'file' command
#                       which was implemented in 7.4d1-d7, hopefully ensures
#                       compatibility back to 7.3.
# 06/15/01 cbu 1.0    Bug fix for menu declaration, [menu::insert].
#                     More user control over how missing items and volumes are
#                       listed (or ignored) in the menu.
#                     New 'Save A Copy In' and 'Save In' menus.
#                     Moved some code into new procs.
#                     Requires AlphaTcl 7.4.x for newer [menu::insert] command.
# 06/18/01 cbu 1.0.1  Bug fix for [file::saveIn].
#                     Bug fix when dimming missing items.
#                     Networked items are never checked for existence. (Can
#                       cause a hangup in the Windows OS).
#                     When adding directories, user is given the choice to
#                       add more items, with some explanation.
# 06/20/01 cbu 1.1    Bug fix for [recent::pushDir] when 'fileName' doesn't
#                       exist (as when called from 'Add Directory' menu item.)
#                     Using [enableMenuItem] instead of embedding '(' in
#                       menuLists so that it is compatible with [Menu -c ...]
#                       argument.  (Alphatk/8 issue).
#                     New pref for optionally marking networked items.
#                     New 'Show Dir In Finder' menu option.
#                     New option to display full path names in menu.
#                     Faster start-up, saving menulist in a cache.  (Cache
#                       is generally unset whenever [recent::buildDirsMenu]
#                       is called otherwise.)
#                     [file::saveIn] and [file::saveACopyIn] now check to
#                       make sure that target file is not same as original.
#                     Menu Cache can be used on start-up if desired.
# 06/27/01 cbu 1.1.1  Improved 'help' arg -- formatting, typos and such.
# 06/28/01 cbu 1.1.2  Minor bug for ignoring missing items in [recent::listDirs]
#                     Improved ballon help for Alphatk.
# 09/25/01 cbu 1.1.3  Temporary dirs (in PREFS:tmp) are now finally ignored.
#                     Bug fix when adding dirs that are already there.
#                       (Should have used 'end' instead of '$limit' in string
#                       command)
#                     Fix (??) to compensate for Alphatk [enableMenuItem] fixes,
#                       so we no longer need to find the index of the item
#                       names when creating the list to dim/mark.
# 03/20/02 cbu 1.2    Added CM modules.
#                     [close [open $newFile w]] no longer necessary in
#                       [file::saveIn] due to core fixes for [saveAs].
#                     [file::saveIn] and [file::saveACopyIn] now check to see
#                       if the target file is newer or older, and reports the
#                       info in the alertnote before over-writing.
# 01/29/03 cbu 1.3    Various updates due to AlphaTcl changes.
#                     New 'openRecentDir' binding and procedure.
#                     Now requires Tcl 8.4
#                     All procs take advantage of 'recent' namespace.
# 08/19/03 cbu 1.3.1  Minor bug fix for <2> windows in [recent::pushDir].
# 08/25/03 cbu 1.3.2  Minor Tcl formatting changes.
# 09/01/03 cbu 1.3.3  Reimplemented use of [global].
# 09/08/03 cbu 1.3.4  Calling procs with full namespaces.
# 12/01/03 cbu 1.3.5  Better insertion of "Save (A Copy) In" submenus, required
#                       for new Alpha8/X core dynamic menu changes to ensure
#                       that "File > Rename" can be accessed.
# 12/30/03 cbu 1.3.6  Removed use of [recent::uplevelVars], using [variable].
#                     Use [file::pathStartsWith $dirName [temp::directory ""]]
#                       to determine if the directory is in a "temp" folder.
#                     Removed [package require Tcl 8.4] in init script since
#                       this file is only distributed via CVS for Alpha8/X/tk.
#                     Using [package::removePrefsDialog] when de-activated.
#                     Minor 'help' argument and other formatting changes.
# 03/24/04 cbu 1.3.7  Ensure that type/creator are transferred when saving to
#                       a directory ([file::saveACopyIn]).
# 01/19/05 cbu 1.3.8  No need to call [alpha::menuAdjustForOpenWins].
# 2006-02-07JK 1.3.9  resumeHook to check for orphaned dirs.
# 

# ===========================================================================
#
# .