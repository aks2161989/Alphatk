## -*-Tcl-*-
 # ###################################################################
 #  Alpha - new Tcl folder configuration
 #
 #  FILE: "recentFiles.tcl"
 #                                    created: 09/21/1997 {09:14:38 pm}
 #                                last update: 05/18/2006 {04:48:11 PM}
 #
 # Reorganisation carried out by Vince Darley with much help from Tom
 # Fetherston, Johan Linde and suggestions from the Alpha-D mailing list.
 # Alpha is shareware; please register with the author using the register
 # button in the about box.
 #
 # original author probably Pete Keleher.  Vince added a bunch of
 # code to work-around some Alpha-menu problems, and made it a
 # package.
 #
 # Version 0.2 builds the menu about a zillion times faster than
 # the original which built the menu once for every item at
 # startup!  Also removed two unnecessary procs, since that stuff
 # can be done elsewhere automatically.  Recently added lots of
 # nice new features, and placed all prefs in the packages menu.
 # ###################################################################
 ##

# alpha::feature recentFilesMenu 0.5.2 "global-only" {
#     # Initialization script.
#     alpha::package require filesets
#     namespace eval recent {}
#     ensureset recent::Files ""
#     prefs::updateHome recent::Files list
#     prefs::modified recent::Files
#     package::addPrefsDialog recentFilesMenu
#     # Contextual Menu module.
# 
#     # Includes the names of the most recently opened files.  Selecting a name
#     # will open that file in ÇALPHAÈ for editing
#     newPref f recentFilesMenu 0 contextualMenu
# } {
#     # Activation script.
#     if {[package::active recentFilesMultiMenu]} {
#         set    question "The 'Recent Files Menu' package cannot be used "
#         append question "while the 'Recent Files Multi Menu' package is active.\r\r"
#         append question "Would you like to deactivate 'Recent Files Multi' now?"
#         if {[askyesno $question] == "yes"} {
#             package::deactivate recentFilesMultiMenu
#             set global::features [lremove [set global::features] recentFilesMultiMenu]
#         } else {
#             error "The 'Recent Files Menu' package cannot be used\
#               while the 'Recent Files Multi Menu' package is active."
#         }
#     } 
#     hook::register   resumeHook recent::verifyFilesList
#     hook::register   closeHook  recent::push
#     # Declare the fileset.  Do it here in case this package is activated
#     # after 'recentFilesMultiMenu' has been turned on then off.
#     set "gfileSetsType(Recent Files)" "procedural"
#     set "gfileSets(Recent Files)" recent::listFiles
#     lunion filesetsNotInMenu "Recent Files"
#     lunion fileset::notChangeable "Recent Files"
#     hook::callAll fileset-new procedural "Recent Files"
#     # Place a submenu just before the 'close' menu item.  We define the
#     # menu build proc here in case the package has been activated after
#     # the 'recentFilesMultiMenu' has been deactivated.
#     menu::buildProc  recentFiles recent::makeMenu
#     menu::insert     File submenu "<E<S/Wclose" recentFiles
#     prefs::register "recentFilesMenu" "contextualMenu"
# } {
#     # Deactivation script.
#     hook::deregister resumeHook recent::verifyFilesList
#     hook::deregister closeHook  recent::push
#     # Remove the submenu just before the 'close' menu item.
#     menu::uninsert   File submenu "<E<S/Wclose" recentFiles
#     # Contextual Menu module.
#     prefs::deregister "recentFilesMenu" "contextualMenu"
# } uninstall {
#     this-file
# } maintainer {
# } description {
#     Lists recently accessed files under the 'File' menu
# } help {
#     This package helps you keep track of recently-used files, by placing their
#     names in a new "File > Recent Files" menu for easy access.  It also adds a
#     'Recent Files' fileset that can be used in searching.
#     
#     Preferences: Features
#     
#     You can fine-tune the behaviour of this feature by adjusting prefs in the
#     "Config > Preferences > Package Preferences > Recent Files Menu Prefs"
#     dialog pane.
#     
#     Preferences: recentDirs
# }

proc recentFiles.tcl {} {}

namespace eval recent {}

foreach oldPref {numberOfRecentFiles orderRecentFilesBy editLastUsedFile} {
    prefs::renameOld $oldPref recentFilesMenumodeVars($oldPref)
}
unset oldPref

# The number of files to list in the 'Files->Recent' menu.
newPref variable numberOfRecentFiles 15 recentFilesMenu recent::makeMenu
# The ordering scheme for items in the recent files menu.
newPref variable orderRecentFilesBy 0 recentFilesMenu recent::makeMenu [list \
  "Alphabetical Order" "Date"] index
# Use this key binding to edit the most recently used file.
newPref binding editLastUsedFile "" recentFilesMenu "" recent::editLastFile

# To show each copy of files with the same name, by identifying them with
# their disk location, click this box||To list only the most recent version
# of all files with the same name, click this box
newPref flag showDistinctDuplicates 1 recentFilesMenu recent::makeMenu

##
 # -------------------------------------------------------------------------
 #
 # "recent::push" --
 #
 #  Works with files whose name contained '[' or ']' which didn't before.
 #  Doesn't add any file which fails 'file exists' to the menu.
 #  
 #  We only need the 'args' since this may be called by saveasHook
 # -------------------------------------------------------------------------
 ##

proc recent::push {name args} {
    global recent::Files recentFilesMenumodeVars

    set name [win::StripCount $name]
    if {![file exists $name]} { return }
    set name [file nativename $name]
    if {$recentFilesMenumodeVars(showDistinctDuplicates)} {
	if {[set ind [lsearch -exact ${recent::Files} $name]] >= 0} {
	    set recent::Files [lreplace ${recent::Files} $ind $ind]
	    lappend recent::Files $name
	    if {$recentFilesMenumodeVars(orderRecentFilesBy)} {recent::makeMenu}
	    return
	}
    } else {
	if {[info exists recent::Files] \
	  && ([set ind [lsearch -exact ${recent::Files} $name]] >= 0)} {
	    set recent::Files [lreplace ${recent::Files} $ind $ind]
	    lappend recent::Files $name
	    if {$recentFilesMenumodeVars(orderRecentFilesBy)} {recent::makeMenu}
	    return
	}
	set ind 0
	foreach f $recent::Files {
	    # perhaps we ought to test also for complications due to
	    # files which end in 'É'.
	    if {[file tail $f] eq [file tail $name]} {
		set recent::Files [lreplace ${recent::Files} $ind $ind]
		lappend recent::Files $name
		if {$recentFilesMenumodeVars(orderRecentFilesBy)} {recent::makeMenu}
		return
	    }
	    incr ind
	}
    }

    lappend recent::Files $name
    if {[llength ${recent::Files}] > $recentFilesMenumodeVars(numberOfRecentFiles)} {
	set recent::Files [lrange ${recent::Files} 1 end]
    }
    recent::makeMenu
}

# Registered as resumeHook.  Run through the Files list, and if an
# item is not an existing file, remove it from the list and request
# menu rebuilding.
proc recent::verifyFilesList { args } {
    variable Files
    foreach f $Files {
	if { ![file exists $f] } {
	    set Files [lremove $Files [list $f]]
	    makeMenu
	    return
	}
    }
}


proc recent::makeMenu {args} {
    global recentFilesMenumodeVars recent::Files
    set menulist [list]

    if {$recentFilesMenumodeVars(showDistinctDuplicates)} {
	set filelist [set recent::Files]
	set level 1
	while {1} {
	    foreach t $filelist {
		if {![file exists $t]} {continue}
		set llen [llength [set tail [file split $t]]]
		if {$llen < $level} {
		    # We've exceeded the top-level.  Must be an odd problem!
		    # Discard this problematic file.
		    continue
		}
		set tail [join [lrange $tail [expr {$llen - $level}] end] [file separator]]
		if {[info exists name($tail)]} {
		    lappend remaining $name($tail)
		    lappend remaining $t
		    set dup($tail) 1
		    set first [lsearch -exact $menulist $tail]
		    set menulist [lreplace $menulist $first $first $name($tail)]
		    if {$level==1} {
			lappend menulist $t
		    }
		    unset name($tail)
		} elseif {[info exists dup($tail)]} {
		    lappend remaining $t
		    if {$level==1} {
			lappend menulist $t
		    }
		} else {
		    set name($tail) $t
		    if {$level==1} {
			lappend menulist $tail
		    } else {
			set toolong [lsearch -exact $menulist $t]
			set menulist [lreplace $menulist $toolong $toolong $tail]
		    }
		}
	    }
	    if {![info exists remaining]} {
		break
	    }
	    incr level
	    set filelist $remaining
	    unset remaining
	    unset dup
	}

    } else {
	foreach t ${recent::Files} {
	    if {[file exists $t]} {
		lappend menulist [file tail $t]
	    }
	    # else we just let the file disappear through lack of use
	}
    }
    if {$recentFilesMenumodeVars(orderRecentFilesBy)} {
	set menulist [lreverse $menulist]
    } else {
	set menulist [lsort -dictionary $menulist]
    }
    if {[set enable [expr [llength $menulist] ? 1 : 0]]} {
	lappend menulist "(-)"
    }
    lappend menulist "Reset List" "Recent Files PrefsÉ" "Recent Files Help"
    Menu -m -c -n recentFiles -p recent::menuProc $menulist
    enableMenuItem -m recentFiles "Reset List" $enable
    if {[llength $args]} {
	status::msg "The 'Recent Files' menu has been rebuilt."
    } 
}

##
 # -------------------------------------------------------------------------
 #
 # "recent::menuProc" --
 #
 #  Works with menu items which contain '[', ']' and 'É' which didn't work
 #  before.
 # -------------------------------------------------------------------------
 ##

proc recent::menuProc {menu name} {

    global recent::Files

    switch $name {
	"Reset List" {
	    set recent::Files {}
	    Menu -m -n recent -p recent::menuProc {}
	    recent::makeMenu
	}
	"Recent Files Prefs" - "Recent Files PrefsÉ" {
	    prefs::dialogs::packagePrefs "recentFilesMenu"
	}
	"Recent Files Help" {
	    package::helpWindow   "recentFilesMenu"
	}
	default {
	    set f [file::pathEndsWith $name ${recent::Files}]
	    if {$f != ""} {
		edit -c $f
		return
	    }
	    if {[file exists $name]} {
		edit -c $name
		return
	    }
	    alertnote "Couldn't find a file '$name'.  Weird!"
	    error "Cancelled"
	}
    }
}

##
 # -------------------------------------------------------------------------
 #
 # "recent::listFiles" --
 #
 #  Used to retrieve the list of files in the 'recent files' fileset
 # -------------------------------------------------------------------------
 ##

proc recent::listFiles {} {
    global recent::Files
    return ${recent::Files}
}

proc recent::editLastFile {} {
    global recent::Files
    if {[set rl [llength ${recent::Files}]]} {
	incr rl -1
	while {$rl >= 0 && [lsearch -exact [winNames -f] \
	  [set f [lindex ${recent::Files} $rl]]] >= 0 \
	  || ![file exists "$f"]} {
	    incr rl -1
	}
	if {$rl >= 0} {
	    edit -c -w [lindex ${recent::Files} $rl]
	    return
	}
    }
    status::msg "No recent file found which isn't already open"
}

