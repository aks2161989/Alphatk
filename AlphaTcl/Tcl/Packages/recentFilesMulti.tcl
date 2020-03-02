 ## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 #
 # FILE: "recentFilesMulti.tcl"
 #                                          created: 01/28/2000 {18:45:34 PM}
 #                                      last update: 05/23/2006 {01:19:18 PM}
 #
 # See 'help' section below for information.
 # 
 #     
 # This code has gone through a couple of iterations, to simplify things
 # internally, and to define a better way of specifying these groups of
 # files.  It works well, (for me!).
 #  
 # Known problem on Windoze with Alphatk.  If you edit network files (i.e.
 # remote files), and then try to startup Alphatk when there is no network,
 # it will hang for some time each time we try to rebuild this menu.  The
 # code tries to workaround this issue.
 #  
 # General buglet: if the list of recent files is manually edited somehow to
 # contain the exact same file-path more than once, it will appear more than
 # once in the menu.  You'll have to edit your "arrdefs.tcl" to remove it.
 #
 # Copyright (c) 2000-2006  Vince Darley
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # Distributable under Tcl-style (free) license.
 #  
 # ==========================================================================
 ##

alpha::feature recentFiles 1.3 "global-only" {
    # Initialization script.
    recentmulti::initializePackage
} {
    # Activation script.
    recentmulti::activatePackage 1
} { 
    # Deactivation script.
    recentmulti::activatePackage 0
} maintainer {
    "Vince Darley" <vince.darley@gmail.com> <http://www.santafe.edu/~vince/>
} uninstall {
    this-file
} description {
    Lists recently accessed files in the "File > Open Recent" menu
} help {
    This package creates the "File > Open Recent" submenu, which by default
    includes all recent files opened in ÇALPHAÈ in the order in which they
    were last opened.
    
    You can adjust the method in which these files are displayed
    
    Preferences: recentFiles
    
    such as listing files in alphabetical order, including full path names in
    the menu, and setting the number of recent files which should be added.
    
    It also allows you to define different "groups" of recent files, which
    will then be categorized into separate submenus.  You might be working on
    a number of different projects: Tcl code for ÇALPHAÈ, various programming
    projects, perhaps some web-page design, ...
     
    When you switch from working on one project to the next, you might be
    annoyed by the fact that the recent files menu is full of files from the
    previous project, _and_ the particular 5 or 10 files that you were
    working on before in this project have of course long ago vanished from
    the recent files menu.
    
    This package seeks to get around that problem, by using the concept of
    groups of recent files, defined by where they lie in your filesystem.
    So, anything in the 'ÇALPHAÈ' hierarchy is in a separate group to
    anything in your 'Programming' hierarchy which is in a different group to
    your 'html' hierarchy.  Recently used files in these different groups are
    remembered separately.
    
    The "File > Open Recent" menu will include the items in the most recently
    used group at the top of the list, and places in submenus the items in
    all other groups.  A "Miscellaneous" group contains items which don't fit
    into any other.
}

proc recentFilesMulti.tcl {} {}

namespace eval recent {}

# Earlier versions named variables in the "recentFilesMultiMenumodeVars"
# array, so we transfer them now.
foreach prefName [array names recentFilesMultiMenumodeVars] {
    prefs::renameOld recentFilesMultiMenumodeVars($prefName) \
      recentFilesmodeVars($prefName)
}
foreach prefName [array names recentFilesMenumodeVars] {
    prefs::renameOld recentFilesMenumodeVars($prefName) \
      recentFilesmodeVars($prefName)
}
unset -nocomplain prefName

# The number of files to list in the "Files > Open Recent" menu.
newPref variable numberOfRecentFiles 15 recentFiles recentmulti::makeMenu \
  [list 5 6 7 8 9 10 12 15 20 25 30 35 40 45 50]
# The ordering scheme for items in the recent files menu.
newPref variable orderRecentFilesBy 1 recentFiles recentmulti::makeMenu [list \
  "Alphabetical Order" "Date"] index
# Use this key binding to edit the most recently used file.
newPref binding editLastUsedFile "" recentFiles "" recentmulti::editLastFile

# Show each copy of files with the same name by identifying them with
# their disk location
newPref flag showDistinctDuplicates 0 recentFiles recentmulti::makeMenu

# Use sets of recent files
newPref flag useGroupsOfRecentFiles 0 recentFiles recentmulti::makeMenu

namespace eval recentmulti {

    variable initialized
    if {![info exists initialized]} {
	set initialized 0
    }
    variable activated
    if {![info exists activated]} {
	set activated -1
    }
}

proc recentmulti::initializePackage {} {

    global global::features recent::Files gfileSets gfileSetsType \
      filesetsNotInMenu fileset::notChangeable
    
    variable currentGroup
    variable initialized
    
    if {$initialized} {
        return
    }
    foreach pkgName [list "recentFilesMenu" "recentFilesMultiMenu"] {
	if {([set idx [lsearch $global::features $pkgName]] > -1)} {
	    set global::features [lreplace $global::features $idx $idx]
	}
    }
    # Declare the fileset.
    alpha::package require filesets
    set "gfileSetsType(Recent Files)" "procedural"
    set "gfileSets(Recent Files)" recentmulti::listFiles
    lunion filesetsNotInMenu "Recent Files"
    lunion fileset::notChangeable "Recent Files"
    hook::callAll fileset-new procedural "Recent Files"
    
    menu::buildProc "openRecent" {recentmulti::makeMenu}
    prefs::updateHome recent::Files list
    multilist::create recent recentmulti::whichgroup
    # A side-effect of the above line was to create this array
    prefs::modified multilist::recent
    # Add a space to avoid conflict with other menus
    set currentGroup "Miscellaneous "
    # This allows us to use any fileset we like as a recent files group.
    fileset::attachNewInformation * flag "Use As Recent Files Group" 0 \
      "To have all recently used files from this set stored separately\
      in the recent files menu, click this box||To remove this fileset\
      from the set considered for recent files, click this box" \
      recentmulti::filesetGroupInfoChanged
    
    # Contextual Menu module.
    prefs::renameOld contextualMenumodeVars(recentFilesMenu) \
      contextualMenumodeVars(openRecentMenu)
    # Includes the names of the most recently opened files.  Selecting a name
    # will open that file in ÇALPHAÈ for editing
    newPref f openRecentMenu 0 contextualMenu
    ;namespace eval ::contextualMenu {
	# This is set of items potentially appearing at the start of the CM.
	lunion menuSections(1) "openRecentMenu"
    }
    
    set initialized 1
    return
}

proc recentmulti::activatePackage {which} {
    
    variable activated
    variable groups
    
    if {($which eq $activated)} {
	return
    }
    if {$which} {
	# Register hooks
	hook::register   resumeHook {recentmulti::verifyFilesList}
	hook::register   openHook   {recentmulti::push}
	hook::register   winChangeNameHook {recentmulti::push}
	# Place a submenu just after the 'openRemote' menu item.
	menu::insert     File submenu {after "<E<B<O/OopenRemoteÉ"} openRecent
	foreach group [array names groups] {
	    if {[lindex $groups($group) 0] eq "recentmulti::standardGroup"} {
		prefs::register \
		  "group[join $group {}]SearchPath" recentFiles
	    }
	}
	# Add a preferences page.
	package::addPrefsDialog recentFiles
	# Contextual Menu module.
	prefs::register "openRecentMenu" "contextualMenu"
    } else {
	# Deregister hooks
	hook::deregister resumeHook {recentmulti::verifyFilesList}
	hook::deregister openHook   {recentmulti::push}
	hook::deregister winChangeNameHook {recentmulti::push}
	# Remove the submenu just after the "openRemote" menu item.
	menu::uninsert   File submenu {after "<E<B<O/OopenRemoteÉ"} openRecent
	# Remove the preferences page.
	package::removePrefsDialog recentFiles
	# Contextual Menu module.
	prefs::deregister "openRecentMenu" "contextualMenu"
    }
    set activated $which
    return
}

##
 # -------------------------------------------------------------------------
 #
 # "recentmulti::push" --
 #
 #  Works with files whose name contained '[' or ']' which didn't before.
 #  Doesn't add any file which fails 'file exists' to the menu.
 #  
 #  We only need the 'args' since this may be called by winChangeNameHook
 # -------------------------------------------------------------------------
 ##

proc recentmulti::push {name args} {
    global recentFilesmodeVars

    regsub { <[0-9]+>$} $name {} name
    if {![file exists $name]} { return }
    set name [file nativename $name]
    if {$recentFilesmodeVars(showDistinctDuplicates)} {
	if {[llength [set ind [multilist::find recent $name]]]} {
	    eval multilist::remove recent $ind
	    if {[recentmulti::add recent $name \
	      $recentFilesmodeVars(numberOfRecentFiles)] \
	      || $recentFilesmodeVars(orderRecentFilesBy)} {
		recentmulti::makeMenu
	    }
	    return
	}
    } else {
	if {[llength [set ind [multilist::find recent $name]]]} {
	    eval multilist::remove recent $ind
	    if {[recentmulti::add recent $name \
	      $recentFilesmodeVars(numberOfRecentFiles)] \
	      || $recentFilesmodeVars(orderRecentFilesBy)} {
		recentmulti::makeMenu
	    }
	    return
	}
	if {0} {
	    set ind 0
	    foreach f [set recentmulti::Files] {
		# perhaps we ought to test also for complications due to
		# files which end in 'É'.
		if {[file tail $f] eq [file tail $name]} {
		    set recentmulti::Files \
		      [lreplace ${recentmulti::Files} $ind $ind]
		    lappend recentmulti::Files $name
		    if {$recentFilesmodeVars(orderRecentFilesBy)} {
			recentmulti::makeMenu
		    }
		    return
		}
		incr ind
	    }
	}
    }

    recentmulti::add recent $name \
      $recentFilesmodeVars(numberOfRecentFiles)
    recentmulti::makeMenu
}

# Registered as resumeHook.  Run through the Recent Files list, and if
# an item is not an existing file, request menu rebuilding.
proc recentmulti::verifyFilesList { args } {
    # Since the user may have declared dozens of groups, we don't want to
    # check them all each time we switch back to Alpha.  We only check the
    # current group:
    foreach f [listFiles] {
	if { ![file exists $f] } {
	    makeMenu
	    return
	}
    }
}

proc recentmulti::getMenuEntries {filelist} {
    global recentFilesmodeVars
    if {$recentFilesmodeVars(showDistinctDuplicates)} {
	set menulist [file::minimalDistinctTails $filelist]
    } else {
	set menulist [list]
	foreach t $filelist {
	    if {[file::isNetworked $t] || [file exists $t]} {
		lappend menulist [file tail $t]
	    }
	    # else we just let the file disappear through lack of use
	}
    }
    if {$recentFilesmodeVars(orderRecentFilesBy)} {
	return [lreverse $menulist]
    } else {
	return [lsort -dictionary $menulist]
    }
}

proc recentmulti::makeMenu {args} {

    global recentFilesmodeVars
    
    if {$recentFilesmodeVars(useGroupsOfRecentFiles)} {
	global recentmulti::currentGroup
	set menuitems {}
	foreach group [multilist::getgroups recent] {
	    if {$group ne [set recentmulti::currentGroup]} {
		set contents [recentmulti::getMenuEntries \
		  [multilist::getgroup recent $group]]
		if {[llength $contents]} {
		    lappend menuitems [list Menu -m -c -n $group \
		      -p recentmulti::menuProc $contents]
		}
	    }
	}
	eval lappend menuitems [recentmulti::getMenuEntries \
	  [multilist::getgroup recent [set recentmulti::currentGroup]]]
    } else {
	set menuitems [recentmulti::getMenuEntries \
	  [multilist::getgroup recent "Miscellaneous "]]
    }
    if {[set enable1 [expr {[llength $menuitems] ? 1 : 0}]]} {
	lappend menuitems "(-)"
    }
    lappend menuitems "Reset List" 
    if {$recentFilesmodeVars(useGroupsOfRecentFiles)} {
        lappend menuitems "Add GroupÉ" "Remove GroupÉ"
	set enable2 [expr {[llength [recentmulti::listGroups]] ? 1 : 0}]
    } 
    lappend menuitems  "Recent Files PrefsÉ" "Recent Files Help"
    Menu -m -c -n openRecent -p recentmulti::menuProc $menuitems
    enableMenuItem -m openRecent "Reset List"   $enable1
    if {[info exists enable2]} {
	enableMenuItem -m openRecent "Remove GroupÉ" $enable2
    }
    if {[llength $args]} {
        status::msg "The 'Recent Files' menu has been rebuilt."
    } 
}

## 
 # -------------------------------------------------------------------------
 # 
 # "recentmulti::add" --
 # 
 #  Returns 1 if the current group has changed (and so the menu should
 #  probably be rebuilt).
 # -------------------------------------------------------------------------
 ##

proc recentmulti::add {tag what {max -1}} {
    global recentmulti::currentGroup
    set group [multilist::add $tag $what $max]
    if {$group ne ${recentmulti::currentGroup}} {
	set recentmulti::currentGroup $group
	return 1
    } else {
	return 0
    }
}

##
 # -------------------------------------------------------------------------
 #
 # "recentmulti::menuProc" --
 #
 #  Works with menu items which contain '[', ']' and 'É' which didn't work
 #  before.
 # -------------------------------------------------------------------------
 ##
proc recentmulti::menuProc {menu name} {

    global recentmulti::currentGroup recentFilesmodeVars

    switch -- $name {
	"Reset List" {
	    multilist::remove recent [set recentmulti::currentGroup]
	    set recentmulti::currentGroup \
	      [lindex [multilist::getgroups recent] 0]
	    #Menu -m -n recent -p recentmulti::menuProc {}
	    recentmulti::makeMenu
	}
	"Add GroupÉ" - "Add Group" {
	    if {![catch {prompt "Enter a name for the new group" ""} g]} {
		recentmulti::registerNewGroup $g \
		  [list recentmulti::standardGroup $g]
		newPref variable group[join $g ""]SearchPath "" \
		  recentFiles
		prefs::modified recentFilesmodeVars(group[join $g ""]SearchPath)
		alertnote "You can now set the search path for this group"
		prefs::dialogs::packagePrefs recentFiles
		recentmulti::makeMenu
	    }
	}
	"Remove GroupÉ" - "Remove Group" {
	    set groups [recentmulti::listGroups]
	    if {[llength $groups]} {
		set g [listpick -p "Remove which group" $groups]
		if {$g != ""} {
		    multilist::remove recent $g
		    recentmulti::deregisterGroup $g
		    recentmulti::makeMenu
		}
	    }
	    foreach g [multilist::getgroups recent] {
		if {[lsearch -exact $groups $g] == -1} {
		    # clean up orphaned groups.  They shouldn't really
		    # exist, anyway.
		    multilist::remove recent $g
		}
	    }
	}
	"Recent Files Prefs" - "Recent Files PrefsÉ" {
	    prefs::dialogs::packagePrefs "recentFiles"
	}
	"Recent Files Help" {
	    package::helpWindow "recentFiles"
	}
	default {
	    if {$menu == "openRecent"} {
		set menu [set recentmulti::currentGroup]
	    } else {
		set recentmulti::currentGroup $menu
		recentmulti::makeMenu
	    }
	    set f [file::pathEndsWith $name [multilist::getgroup recent $menu]]
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
 # "recentmulti::listFiles" --
 #
 #  Used to retrieve the list of files in the 'recent files' fileset
 # -------------------------------------------------------------------------
 ##
proc recentmulti::listFiles {} {
    global recentmulti::currentGroup
    return [multilist::getgroup recent [set recentmulti::currentGroup]]
}

proc recentmulti::editLastFile {} {
    global recentmulti::Files
    if {[set rl [llength ${recentmulti::Files}]]} {
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

# ×××× Group handling ×××× #

proc recentmulti::listGroups {} {
    global recentmulti::groups
    array names recentmulti::groups
}

## 
 # -------------------------------------------------------------------------
 # 
 # "recentmulti::registerNewGroup" --
 # 
 #  The script you register for the new group may be evaluated in
 #  two different ways:
 #  
 #  (i) eval $testscript [list $filename]
 #  
 #  should return 1 or 0 depending on if the filename is in the group 
 #  or not
 #  
 #  (ii) eval $testscript
 #  
 #  should delete all information associated with the group. The user
 #  has decided to remove the group.
 #  
 #  We suggest using an 'args' parameter and [llength $args] to 
 #  differentiate between the two.
 # -------------------------------------------------------------------------
 ##
proc recentmulti::registerNewGroup {group testScript} {
    global recentmulti::groups
    set recentmulti::groups($group) $testScript
    prefs::modified recentmulti::groups($group)
}

proc recentmulti::deregisterGroup {group} {
    global recentmulti::groups
    if {[info exists recentmulti::groups($group)]} {
	eval [set recentmulti::groups($group)]
	prefs::modified recentmulti::groups($group)
	unset recentmulti::groups($group)
    }
}

proc recentmulti::whichgroup {name} {
    global recentFilesmodeVars recentmulti::groups
    if {$recentFilesmodeVars(useGroupsOfRecentFiles)} {
	foreach group [array names recentmulti::groups] {
	    # The array entry is a script to evaluate which 
	    # will tell us if the file is in that group
	    # (if given an argument).
	    if {[eval [set recentmulti::groups($group)] [list $name]]} {
		return $group
	    }
	}
	return "Miscellaneous "
    } else {
	return "Miscellaneous "
    }
}

proc recentmulti::filesetGroupInfoChanged {fset val} {
    if {$val} {
	recentmulti::registerNewGroup $fset \
	  [list recentmulti::filesetGroup $fset]
    } else {
	recentmulti::deregisterGroup $fset
    }
}

proc recentmulti::filesetGroup {fset args} {
    global gfileSets
    if {[llength $args]} {
	set name [lindex $args 0]
	if {[fileset::exists $fset]} {
	    return [fileset::isIn $fset $name]
	} else {
	    # fileset has been deleted!
	    recentmulti::deregisterGroup $fset
	    multilist::remove recent $fset
	    return 0
	}
    } else {
	# Deregister this fileset group
	fileset::setInformation $fset useAsRecentFilesGroup 0
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "recentmulti::standardGroup" --
 # 
 #  This is the stanard group handler, which has an associated prefs
 #  variable.  We create a new group and register this handler like this:
 #  
 #  recentmulti::registerNewGroup $g [list recentmulti::standardGroup $g]
 # 
 #  When we are called with one argument, it is a file, and we must check
 #  if it is in this group.  When called with no arguments, we delete
 #  all information associated with the group.
 # -------------------------------------------------------------------------
 ##
proc recentmulti::standardGroup {group args} {
    global recentFilesmodeVars
    set pref "group[join ${group} ""]SearchPath"
    if {[llength $args]} {
	set name [lindex $args 0]
	foreach path $recentFilesmodeVars($pref) {
	    if {[file::pathStartsWith $name $path]} {
		return 1
	    }
	}
	return 0
    } else {
	prefs::modified recentFilesmodeVars($pref)
	unset recentFilesmodeVars($pref)
    }
}


# ×××× Multilist object ×××× #

namespace eval multilist {}

proc multilist::add {tag what {max -1}} {
    global multilist::$tag
    set item [multilist::which $tag $what]
    lappend multilist::${tag}($item) $what
    if {$max > 0 && ([llength [set multilist::${tag}($item)]] > $max)} {
	set multilist::${tag}($item) \
	  [lrange [set multilist::${tag}($item)] 1 end]
    }
    return $item
}

proc multilist::which {tag what} {
    global multilist::decisions
    eval [set multilist::decisions($tag)] [list $what]
}

proc multilist::getgroup {tag item} {
    global multilist::$tag
    if {[info exists multilist::${tag}($item)]} {
	return [set multilist::${tag}($item)]
    } else {
	return ""
    }
}

proc multilist::getgroups {tag} {
    global multilist::$tag
    return [array names multilist::${tag}]
}

proc multilist::remove {tag item {index ""}} {
    global multilist::$tag
    if {[string length $index]} {
	set multilist::${tag}($item) \
	  [lreplace [set multilist::${tag}($item)] $index $index]
    } else {
	if {[info exists multilist::${tag}($item)]} {
	    unset multilist::${tag}($item)
	}
    }
}

proc multilist::find {tag what {how "-exact"}} {
    global multilist::$tag
    foreach arr [array names multilist::${tag}] {
	if {[set ind [lsearch $how [set multilist::${tag}($arr)] $what]] >= 0} {
	    return [list $arr $ind]
	}
    }
    return ""
}

proc multilist::create {tag decisionProc} {
    global multilist::decisions
    # These lines are for Tcl 8's benefit. We create
    # an empty array if it doesn't yet exist.
    global multilist::$tag
    if {![array exists multilist::$tag]} {
	array set multilist::${tag} {}
    }
    # Set our decision proc.
    set multilist::decisions($tag) $decisionProc
}

# ===========================================================================
#
# ×××× ------------ ×××× #
# 
# ×××× Version History ×××× #
# 
#  modified by  rev    reason
#  -------- --- ------ -----------
#  01-28-00 VMD 0.1    Original.
#  ??-??-?? ??? ???    Various updates through the years.
#  03-20-02 cbu 1.2    Added CM module.
#                      Better handling of conflict with 'recentFilesMenu',
#                        now attempts to deactivate that package if needed.
#  02-06-06 JK         - winChangeNameHook + primitive resumeHook (see RFE 1942)
#  05/18/06 cbu 1.3    Package is now named "recentFiles" and the submenu it
#                        creates is "File > Open Recent".
#                      All preferences in "recentFilesmodeVars" array.
#                      "useGroupsOfRecentFiles" is now turned off by default.
#                      "sort
#                      

# ===========================================================================
#
# .