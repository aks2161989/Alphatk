## -*-Tcl-*-
 # ###################################################################
 #  Alphatk - the editor
 # 
 #  FILE: "alpha_tk.tcl"
 #                                    created: 04/08/98 {21:52:56 PM} 
 #                                last update: 2006-03-29 09:00:42 
 #  Author: Vince Darley
 #  E-mail: vince.darley@kagi.com
 #    mail: Flat 10, 98 Gloucester Terrace, London W2 6HP
 #     www: http://www.purl.org/net/alphatk
 #  
 # Copyright (c) 1998-2005  Vince Darley
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # In particular, while this is 'open source', it is NOT free, and
 # cannot be copied in full or in part except according to the terms
 # of the license agreement.
 # 
 # ###################################################################
 ##

alpha::feature Alpha 8.5a1 {} {
    switch -- [tk windowingsystem] {
	"classic" {
	    set multiColumnMenusEveryNItems 2000
	    set useGlobalMenuBarOnly 1

	    set "flagPrefs(Platform Specific)" ""
	    set "varPrefs(Platform Specific)" ""
	}
	"aqua" {
	    set multiColumnMenusEveryNItems 2000
	    set useGlobalMenuBarOnly 1

	    set "flagPrefs(Platform Specific)" ""
	    lappend "varPrefs(Platform Specific)" "nonInteractiveApps"

	    # Alpha tries to capture stdout/stderr when it spawns off processes.  For
	    # some processes this isn't really useful, and it's best if Alpha just sets
	    # the thing running and then ignores it.  Set this variable to a list of
	    # those items in the helpers dialog which Alpha should ignore in this way
	    newPref var nonInteractiveApps [list "viewDVI" "viewPS" "viewPDF"]
	}
	"win32" - "windows" {
	    # If your platform doesn't handle scrolling menus, then your menus need
	    # to be multi-column.  Set this variable to the number of items per column.
	    set multiColumnMenusEveryNItems [expr {([winfo screenheight .] - 30)/[default::size menuitemheight]}]

	    lappend "flagPrefs(Platform Specific)" useGlobalMenuBarOnly
	    lappend "varPrefs(Platform Specific)" nonInteractiveApps showFileInExplorer
	    lappend varPrefs(Window) windowIcons

	    # Alpha tries to capture stdout/stderr when it spawns off processes.  For
	    # some processes this isn't really useful, and it's best if Alpha just sets
	    # the thing running and then ignores it.  Set this variable to a list of
	    # those items in the helpers dialog which Alpha should ignore in this way
	    newPref var nonInteractiveApps [list "viewDVI" "viewPS" "viewPDF"]
	    # To remove the menu bar from each separate text window, and use only a
	    # global menu bar, and speed up opening of new windows (Tk is particularly 
	    # slow with respect to 'cloning' menus, which it has to
	    # do if you want a separate menu bar in each editing window), click this box.||
	    # To place a menu bar in each editing window, and probably make the opening of
	    # new windows rather slow, click this box.
	    newPref flag useGlobalMenuBarOnly 1
	    # The icons that Alphatk uses for each Window can be either file-specific, or
	    # use the same icon for all windows.  This preference only affects new windows.
	    newPref variable windowIcons 0 global "" [list "Use Each File's Own Icon" "Use Alphatk Icon For All Files"] index
	    # When Alphatk opens an explorer window for a given file or folder, should
	    # that be a standard 'Folder View' or an 'Explorer Window'.
	    newPref variable showFileInExplorer 0 global "" [list "With Explorer View" "With Folder View"] index
	}
	"unix" - "x11" - 
	default {
	    # If your platform doesn't handle scrolling menus, then your menus need
	    # to be multi-column.  Set this variable to the number of items per column.
	    set multiColumnMenusEveryNItems [expr {([winfo screenheight .] - 30)/[default::size menuitemheight]}]

	    lappend "flagPrefs(Platform Specific)" "useGlobalMenuBarOnly"
	    lappend "varPrefs(Platform Specific)" "nonInteractiveApps"

	    # Alpha tries to capture stdout/stderr when it spawns off processes.  For
	    # some processes this isn't really useful, and it's best if Alpha just sets
	    # the thing running and then ignores it.  Set this variable to a list of
	    # those items in the helpers dialog which Alpha should ignore in this way
	    newPref var nonInteractiveApps [list "viewDVI" "viewPS" "viewPDF"]
	    # To remove the menu bar from each separate text window, and use only a
	    # global menu bar, and speed up opening of new windows (Tk is particularly 
	    # slow with respect to 'cloning' menus, which it has to
	    # do if you want a separate menu bar in each editing window), click this box.||
	    # To place a menu bar in each editing window, and probably make the opening of
	    # new windows rather slow, click this box.
	    newPref flag useGlobalMenuBarOnly 1
	}
    }
    
    lappend varPrefs(International) "localisation"

    # To use complete path names as the titles of windows, click
    # this box.||To use just the file name for window titles,
    # click this box.
    newPref flag showFullPathsInWindowTitles 0
    # To hide the status bar when Alphatk is not the foreground
    # application, click
    # this box.||To show the status bar at all times, click this box.
    newPref flag hideStatusBarWhenInBackground 0
    lappend flagPrefs(Window) showFullPathsInWindowTitles \
      hideStatusBarWhenInBackground

   
} {} 

