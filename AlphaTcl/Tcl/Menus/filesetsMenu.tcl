## -*-Tcl-*-
 # ###################################################################
 #  Vince's Additions - an extension package for Alpha
 # 
 #	FILE: "filesetsMenu.tcl"
 #					created: 20/7/96 {6:22:25 pm} 
 #				   last update: 04/03/2006 {01:29:25 PM} 
 #	Author:	Vince Darley
 #	E-mail:	<vince@santafe.edu>
 #	  mail:	317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #	   www:	<http://www.santafe.edu/~vince/>
 #	
 #  modified by  rev reason
 #  -------- --- --- -----------
 #  24/3/96  VMD 1.0 update of Pete's original to allow mode-specific filesets
 #  27/3/96  VMD 1.1 added hierarchial filesets, and checks for unique menus
 #  13/6/96  VMD 1.2 memory efficiency improvements with 'fileSets' array
 #  10/3/97  VMD 1.3 added 'procedural' fsets, including 'Open Windows'
 #  6/4/97   VMD 1.31 various fixes incorporated - thanks!
 #  11/7/97  VMD 1.4 added cache for the fileset menu, improved wc proc.
 #  15/7/97  VMD 1.41 better handling of out-of-date filesets, and dir opening
 #  15/7/97  VMD 1.42 placed cache in separate file.
 #  21/7/97  VMD 1.43 added glob patterns to ignore for directory filesets
 #  22/7/97  VMD 1.5 more sophisticated menu caching.  No more long rebuilds!
 #  10/9/97  VMD 1.6 simplified some stuff for new Alpha-Tcl
 #  7/12/97  VMD 1.6.1 makes use of winNumDirty flag
 #  12/1/98  VMD 1.6.2 removes special treatment of *recent*
 #  15/1/1999  VMD 1.7.2 a year of improvements....
 #  2000-03-13 VMD 1.7.7 Removed default filesets, fixed for no filesets.
 #  
 #  Version 2.0 separates the filesets menu from the core idea of a 
 #  'fileset', which is used elsewhere in Alpha.  The code in this
 #  file is just concerned with the filesets menu, and simply makes
 #  use of the nice core filesets code.
 # ###################################################################
 ##

alpha::menu filesetMenu 2.1.6 global "•131" {
    # We need this core code.
    alpha::package require filesets
    
    # A type can have the option of being unsorted (e.g. tex-filesets)
    newPref flag sortFilesetItems 0 "fileset"
    # Visual formatting may be of relevance to some types
    newPref flag indentFilesetItems 0 "fileset"
    # Use the variable 'filesetSortOrder' to determine the visual
    # structure of the fileset menu
    newPref flag sortFilesetsByType 0 "fileset" filesetMenu::rebuildSome
    # When a file is selected from the menu, do we try and keep
    # 'currFileSet' accurate?
    newPref flag autoAdjustFileset 1 "fileset"

    # The filesets not to show in the menu
    ensureset filesetsNotInMenu "Help"
    ensureset fsMenuDeletions [list]
    
    namespace eval filesetMenu {}
    set filesetMenu::haveSubMenus 0
    # This will autoload this file and then run this procedure
    filesetMenu::build
    # Make sure any deleted items in the main menu are removed at
    # startup.  We have to do this with a hook, because in Alpha
    # (but not Alphatk), 'deleteMenuItem' only works for menu items
    # which have already been inserted into the menu bar.
    hook::register startupHook [join $fsMenuDeletions "\n"]
} {
    # insert just before 'open remote' item
    menu::insert File items "<E<B<O/OopenRemote…" "<S<I<O/OopenViaFileset…"
    hook::register fileset-delete filesetMenu::fsetDeleted *
    hook::register fileset-update filesetMenu::fsetUpdated *
    hook::register fileset-new filesetMenu::fsetNew *
    hook::register fileset-current filesetMenu::changeCurrent *
    hook::register fileset-uncache filesetMenu::fsetUncache *
} {
    menu::uninsert File items "<E<B<O/OopenRemote…" "<S<I<O/OopenViaFileset…"
    hook::deregister fileset-delete filesetMenu::fsetDeleted *
    hook::deregister fileset-update filesetMenu::fsetUpdated *
    hook::deregister fileset-new filesetMenu::fsetNew *
    hook::deregister fileset-current filesetMenu::changeCurrent *
    hook::deregister fileset-uncache filesetMenu::fsetUncache *
} uninstall {
    this-file
} maintainer {
    "Vince Darley" vince@santafe.edu <http://www.santafe.edu/~vince/>
} description {
    Provides utilities to create, rename, etc.  groups of files known as
    "filesets" and to open their contents in Alpha for editing
} help {
    file "Filesets Help"
}

proc filesetMenu {} {}

namespace eval filesetMenu {}

## 
 # -------------------------------------------------------------------------
 # 
 # "filesetMenu::build" --
 # 
 #  This is the procedure called at each startup.  It used to be called
 #  'rebuildFilesetMenu', but that is misleading, hence the current
 #  name.  Its job is to build the menu, not worrying about whether
 #  the information it uses is current/valid/cached or whatever.
 #  It is the job of 'rebuild/update filesets' to find new information
 #  if desired.
 #  
 #  Reads the fileset menu from the cache if it exists.  This speeds up
 #  start-up by quite a bit.
 # -------------------------------------------------------------------------
 ##
proc filesetMenu::build {} { 
    status::msg "Building filesets…"
    if {[cache::exists fsMenu2.0]} {
	uplevel \#0 cache::readContents fsMenu2.0
	filesetMenu::rebuildUtils
    } else {
	filesetMenu::rebuild
    }  
}
	
## 
 # -------------------------------------------------------------------------
 #	 
 #	"filesetMenu::rebuildSome" --
 #	
 # If given '*' rebuild the entire menu, else rebuild only those types
 # given.  This is generally useful to avoid excessive rebuilding when
 # flags are adjusted
 # 
 # (but in the current implementation it just builds everything)
 # -------------------------------------------------------------------------
 ##
proc filesetMenu::rebuildSome {args} {
    rebuildAllFilesets		
}

## 
 # -------------------------------------------------------------------------
 #	 
 #	"rebuildAllFilesets" --
 #	
 # This does a complete rebuild of all information.  If we are asked
 # to use the cache, then we effectively just rebuild the menu
 # assuming all filesets (for which a cache exists) are still valid.
 # 
 # Otherwise we clear out the cache and then rebuild.
 # -------------------------------------------------------------------------
 ##
proc rebuildAllFilesets { {useCache 0} } {
    if {!$useCache} {
	foreach f [fileset::names] {
	    fileset::uncache $f
	}
    }
    
    # Just make file-sets for those we don't want in the menu
    global filesetsNotInMenu
    foreach f $filesetsNotInMenu {
	catch {fileset::make $f 0}
    }
 
    # Now rebuild the menu
    filesetMenu::rebuild
}

## 
 # -------------------------------------------------------------------------
 #	 
 #	"filesetMenu::rebuild" --
 #	
 # Build the entire filesets menu.
 # 
 # Note: this procedure cannot just be a simple loop over
 # 'UpdateAFileset', because we need to rebuild the actual
 # menu, and this may have an unknown structure.
 # 
 # Filesets which are not shown in the menu are not touched in any
 # way at all.
 # 
 # At one point I wrote: The problem is that the names of menus may
 # actually change (spaces added/deleted).  This is not a problem for
 # the fileset menu, but is a problem for any filesets which have been
 # added to other menus, since they won't know that they need to be
 # rebuilt.
 # -------------------------------------------------------------------------
 ##
proc filesetMenu::rebuild {} {
    global filesetMenu filesetmodeVars filesetsNotInMenu \
      fileSets filesetMenu::haveSubMenus fsMenuCache
    
    status::msg "Rebuilding filesets menu…"
    
    set filesetMenu::haveSubMenus 0
    set problems {}
    if {$filesetmodeVars(sortFilesetsByType)} {
	global filesetSortOrder
	set used $filesetsNotInMenu
	set sp [filesetMenu::sortedOrder $filesetSortOrder used]
	set sets [lindex $sp 0]
	set problems [lindex $sp 1]
	set problem_msg [lindex $sp 1]
    } else {
	set sets {}
	foreach f [lsort -dictionary [fileset::names]] {
	    if {![lcontains filesetsNotInMenu $f]} {
		if {[catch {fileset::make $f 1} res]} {
		    lappend problems $f
		    lappend problem_msg [list $f ($res)]
		} else {
		    lappend sets $res
		}
	    }
	}			
    }
    
    if {[llength $problems]} {
	foreach fset $problems {
	    filesetMenu::_hideOrShow $fset
	}
	status::msg "The following filesets had problems and will be\
	  hidden: [join $problem_msg {, }]"
    }

    # cache the fileset menu
    set m [list Menu -m -n $filesetMenu -p filesetMenu::menuProc \
      [concat {{<S<I<O/OOpen File…} {Menu -n Utilities {}}} "Help" \
      "\(-" $sets]]
    
    cache::create fsMenu2.0 
    cache::add fsMenu2.0 "eval" $m 
    global fsListOfSubmenus fsSubMenuInfo fsMenuDeletions
    set fsMenuDeletions [list]
    prefs::modified fsListOfSubmenus fsSubMenuInfo fileSets fsMenuCache \
      fsMenuDeletions
    eval $m
    
    filesetMenu::rebuildUtils

    status::msg ""
}

## 
 # -------------------------------------------------------------------------
 # 
 # "filesetMenu::fsetNew" --
 # 
 #  If we've added, or renamed a fileset.  In most cases we must
 #  rebuild everything (due to limitations in Alpha), but for
 #  'procedural' filesets, we can just do the utilities menu.
 # -------------------------------------------------------------------------
 ##
proc filesetMenu::fsetNew {name} {
    if {[fileset::getKindFromFset $name] == "procedural"} {
	global filesetsNotInMenu
	if {[lsearch $filesetsNotInMenu $name] == -1} {
	    lappend filesetsNotInMenu $name
	    prefs::modified filesetsNotInMenu
	}
	filesetMenu::rebuildUtils
    } else {
	filesetMenu::rebuild
	status::msg "The fileset \"$name\" has been added to the\
	  main fileset menu."
    }
}

proc filesetMenu::changeCurrent {from to} {
    # These may fail if one or other is a temporary fileset
    markMenuItem -m choose $from off
    markMenuItem -m choose $to on
}

proc filesetMenu::fsetUncache {fset} {
    global fileSets fsListOfSubmenus fsSubMenuInfo

    if {[info exists fsListOfSubmenus($fset)]} {
	# if the fileset already has a base menu, use that:
	foreach n $fsListOfSubmenus($fset) {
	    prefs::modified fsSubMenuInfo($n)
	    catch [list unset fsSubMenuInfo($n)]
	}
	prefs::modified fsListOfSubmenus($fset)
	catch [list unset fsListOfSubmenus($fset)]
    }
    if {[info exists fileSets($fset)]} {
	prefs::modified fileSets($fset)
	catch [list unset fileSets($fset)]
    }
}

proc filesetMenu::fsetUpdated {fset {m ""}} {
    if {![llength $m]} {
	return
    }

    global fileSets fsListOfSubmenus fsSubMenuInfo

    # we could rebuild the menu with this: but we don't
    cache::add fsMenu2.0 "eval" $m
    if {[info exists fsListOfSubmenus($fset)]} {
	# if the fileset already has a base menu, use that:
	foreach n $fsListOfSubmenus($fset) {
	    prefs::modified fsSubMenuInfo($n)
	}
	prefs::modified fsListOfSubmenus($fset)
    }
    if {[info exists fileSets($fset)]} {
	prefs::modified fileSets($fset)
    }
    eval $m
}

proc filesetMenu::fsetDeleted {fset} {
    global filesetsNotInMenu
    
    set removeError [catch {filesetMenu::remove $fset}]
    
    if {([set idx [lsearch -exact $filesetsNotInMenu $fset]] != -1)} {
	set filesetsNotInMenu [lreplace $filesetsNotInMenu $idx $idx]
	prefs::modified filesetsNotInMenu
	catch {
	    deleteMenuItem -m choose $fset
	    deleteMenuItem -m hideFileset $fset
	}
    } elseif {$removeError} {
	# It's on a submenu or somewhere else so we just have to do the lot!
	filesetMenu::rebuild
    } else {
	catch {
	    deleteMenuItem -m choose $fset
	    deleteMenuItem -m hideFileset $fset
	}
    }
    return
}


# ◊◊◊◊ Menu procedures ◊◊◊◊ #

## 
 # -------------------------------------------------------------------------
 #	 
 #	"filesetSortOrder" --
 #	
 #  The structure of this variable dictates how the fileset menu is
 #  structured:
 #		   
 #		   '{pattern p}' 
 #			   lists all filesets which match 'p'
 #		   '-' 
 #			   adds	a separator line
 #		   '{list of types}' 
 #			   lists all filesets of those types.
 #		   '{submenu name sub-order-list}' 
 #			   adds	a submenu with name 'name' and recursively
 #			   adds	filesets to that submenu as given by the 
 #			   sub-order.
 #			   
 #  Leading, trailing and double separators are automatically removed.
 #	 
 # -------------------------------------------------------------------------
 ##
ensureset filesetSortOrder { {pattern *Core} {pattern Packages} \
	{pattern Menus} {pattern Modes} {pattern Preferences} \
	- {tex} - {pattern *.cc} {submenu Headers {pattern *.h}} \
	- {fromDirectory think codewarrior ftp \
	fromOpenWindows fromHierarchy} * } 

proc filesetMenu::remove {fset} {
    global fsListOfSubmenus fsSubMenuInfo filesetMenu fsMenuDeletions
    # find its menu:
    if {[info exists fsListOfSubmenus($fset)]} {
	foreach m $fsListOfSubmenus($fset) {
	    # remove info about it's name
	    if {[info exists fsSubMenuInfo($m)]} {
		prefs::modified fsSubMenuInfo($m)
		unset fsSubMenuInfo($m)
	    }
	}
	set base [lindex $fsListOfSubmenus($fset) 0]
	prefs::modified fsListOfSubmenus($fset)
	unset fsListOfSubmenus($fset)
	# this will fail if it's on a submenu or if it isn't a menu at all
	deleteMenuItem -m $filesetMenu $base
	lappend fsMenuDeletions [list deleteMenuItem -m $filesetMenu $base]
	prefs::modified fsMenuDeletions
    } else {
	# I think I do nothing
    }
    
}

proc filesetMenu::removeInMenu {fset} {
    global fsListOfSubmenus fsSubMenuInfo filesetMenu fsMenuDeletions
    # find its menu:
    if {[info exists fsListOfSubmenus($fset)]} {
	set base [lindex $fsListOfSubmenus($fset) 0]
	# this will fail if it's on a submenu or if it isn't a menu at all
	markMenuItem -m hideFileset $fset on
	deleteMenuItem -m $filesetMenu $base
	lappend fsMenuDeletions [list deleteMenuItem -m $filesetMenu $base]
	prefs::modified fsMenuDeletions
    } else {
	# I think I do nothing
    }
}

## 
 # Global procedures to deal with the fact that Alpha can only have one
 # menu with each given name.  This is only a problem in dealing with
 # user-defined menus such as fileset menus, tex-package menus, ...
 ##

## 
 # -------------------------------------------------------------------------
 #	 
 #	"filesetMenu::makeSub" --
 #	
 # If desired this is the only procedure you need use --- it returns a menu
 # creation string, taking account of the unique name requirement and will
 # make sure your procedure 'proc' is called with the real menu name! 
 # -------------------------------------------------------------------------
 ##
proc filesetMenu::makeSub {fset name proc args} {
    if {[string length $proc] > 1 } {
	return [concat {Menu -m -n} \
	  [list [filesetMenu::registerName $fset -proc $proc -- $name]] \
	  -p filesetMenu::subProc $args]
    } else {
	return [concat {Menu -m -n} \
	  [list [filesetMenu::registerName $fset -- $name]] $args]
    }
}

## 
 # -------------------------------------------------------------------------
 #	 
 #	"filesetMenu::registerName" --
 #	
 # Call to ensure unique fileset submenu names.  We just add spaces as
 # appropriate and keep track of everything for you!  Filesets which have
 # multiple menus _must_ register the main menu first. 
 # -------------------------------------------------------------------------
 ##
proc filesetMenu::registerName {fset args} {
    set opts(-proc) ""
    set opts(-top) 1
    getOpts {-proc -top}
    if {[llength $args] != 1} { return -code error "Bad args" }
    set name [lindex $args 0]
    #puts "$fset $name $opts(-top)"
    global fsSubMenuInfo fsListOfSubmenus
    if {$opts(-top) && ($fset eq $name) \
      && [info exists fsListOfSubmenus($fset)]} {
	# if the fileset already has a base menu, use that,
	# but only if this is the base level of the fileset menu
	# (otherwise we have trouble if submenus contain the
	# directories with the same name as the top menu).
	foreach n $fsListOfSubmenus($fset) {
	    if {[string trimright $n] eq $fset} {
		set base $n
	    } 
	    unset fsSubMenuInfo($n)
	}
	unset fsListOfSubmenus($fset)
    }
    if {[info exists opts(-deregister)]} {
	if {[info exists fsSubMenuInfo($name)]} {
	    unset fsSubMenuInfo($name)
	}
	return
    }
    set original $name					
    if {[info exists base]} {
	set name $base
    } else {
	# I add at least one space to _all_ hierarchical submenus now.
	# This is so I won't clash with any current or future modes
	# which should never normally add spaces themselves.
	append name " "
	while {[info exists fsSubMenuInfo($name)]} {
	    append name " "
	}		
    }
    
    set fsSubMenuInfo($name) [list $fset $original $opts(-proc)]
    # build list of a fileset's menus
    lappend fsListOfSubmenus($fset) "$name"
    
    return $name
}

## 
 # -------------------------------------------------------------------------
 #	 
 #	"filesetMenu::subProc" --
 #	
 # This procedure is implicitly used to deal with ensuring unique sub-menu
 # names.  It calls the procedure you asked for, with the name of the menu
 # you think you're using. 
 # -------------------------------------------------------------------------
 ##
proc filesetMenu::subProc {menu item} {
    global fsSubMenuInfo
    set l $fsSubMenuInfo($menu)
    set realProc [lindex $l 2]
    if {$realProc eq ""} {
	# We could perhaps try to rebuild?
	error "Cancelled: fileset information out of date."
    }
    if {[info commands ::$realProc] == ""} {auto_load "::$realProc"}
    # try to call the proc with three arguments (fileset is 1st)
    if {[llength [info args $realProc]] == 2} {
	$realProc [lindex $l 1] "$item"
    } else {
	$realProc [lindex $l 0] [lindex $l 1] "$item"
    }
}

proc filesetMenu::menuProc {menu item} {
    switch -- $item {
	"Open File" {
	    file::openViaFileset
	} 
	"Help" {
	    help::openFile "Filesets Help"
	}
    }
}

proc filesetMenu::utilsProc { menu item } {
    global filesetUtils currFileSet
    if {![info exists filesetUtils($item)] \
      && [info exists filesetUtils(${item}…)]} {
	append item "…"
    }
    if {[info exists filesetUtils($item)]} {
	# it's a utility
	set utilDesc $filesetUtils($item)
	set allowedTypes [lindex $utilDesc 0]
	if {[string match $allowedTypes [fileset::type $currFileSet]]} {
	    return [eval [lindex $utilDesc 1]]
	} else {
	    beep
	    status::msg "That utility can't be applied to the current file-set."
	    return
	}
    } else {
	switch -- $item {
	    default             {$item}
	}
    }
}

proc filesetMenu::sortedOrder {order usedvar} {
    upvar 1 $usedvar used
    global filesetmodeVars filesetsNotInMenu
    set sets {}
    set problems {}
    
    foreach item $order {
	switch -- [lindex $item 0] {
	    "-" { 
		# add divider
		lappend sets "\(-" 
		continue
	    } 
	    "*" {
		# add all the rest
		set subset {}
		foreach s [fileset::names] {
		    if {![lcontains used $s]}  {
			lappend subset $s
			lappend used $s
		    }
		}
		foreach f [lsort $subset] {
		    if {[catch {fileset::make $f 1} fmenu]} {
			lappend problems $f
			lappend filesetsNotInMenu $f
		    } else {
			lappend sets $fmenu
		    }
		}
	    } 
	    "pattern" {
		# find all which match a given pattern
		set patt [lindex $item 1]
		set subset {}
		foreach s [fileset::names] {
		    if {![lcontains used $s]}  {
			if {[string match $patt $s]} {
			    lappend subset $s
			    lappend used $s
			}
		    }
		}
		foreach f [lsort $subset] {
		    if {[catch {fileset::make $f 1} fmenu]} {
			lappend problems $f
			lappend filesetsNotInMenu $f
		    } else {
			lappend sets $fmenu
		    }
		}
		
	    }
	    "submenu" {
		global filesetMenu::haveSubMenus
		set filesetMenu::haveSubMenus 1
		# add a submenu with name following and sub-order
		set name [lindex $item 1]
		set suborder [lrange $item 2 end]		  	
		# we make kind of a pretend fileset here.
		set sp [filesetMenu::sortedOrder $suborder used]
		set subsets [lindex $sp 0]
		set problems [lindex $sp 1]
		if { $subsets != "" } {
		    lappend sets [filesetMenu::makeSub $name $name \
		      fileset::openItemProc $subsets]
		}
	    }
	    "default" {		
		set subset {} 
		foreach s [fileset::names] {
		    if {[lcontains item [fileset::type $s]] \
		      && ![lcontains used $s]}  {
			lappend subset $s
			lappend used $s
		    }
		}
		foreach f [lsort $subset] {
		    if {[catch {fileset::make $f 1} fmenu]} {
			lappend problems $f
			lappend filesetsNotInMenu $f
		    } else {
			lappend sets $fmenu
		    }
		}
	    }
	}
	
    }
    # remove multiple and leading, trailing '-' in case there were gaps
    regsub -all "\\\(-\( \\\(-\)+" $sets "\(-" sets
    while { [lindex $sets 0] == "\(-" } { set sets [lrange $sets 1 end] }
    set l [expr {[llength $sets] -1}]
    if { [lindex $sets $l] == "\(-" } { set sets [lrange $sets 0 [incr l -1]] }
    
    return [list $sets $problems]
}

proc filesetMenu::rebuildUtils {} {
    global filesetUtils 
    
    set itemList [list]
    foreach fset [lsort -dictionary [fileset::names]] {
	if {[fileset::getKindFromFset $fset] == "procedural"} {continue}
	lappend itemList $fset
    }

    Menu -n "Utilities" -p filesetMenu::utilsProc [concat \
      "/'<B<OeditFilesets…" \
      "newFileset…" \
      "deleteFileset…" \
      "duplicateFileset…" \
      "printFileset…" \
      "<S<EupdateAFileset…" \
      "<S<IupdateCurrentFileset" \
      "rebuildAllFilesets" \
      [list [list Menu -n choose -c -m -p filesetMenu::choose [lsort -dictionary [fileset::names]]]] \
      [list [list Menu -n hideFileset -c -m -p filesetMenu::hideOrShow $itemList]]\
      [list [menu::makeFlagMenu filesetFlags array filesetmodeVars]] \
      "\(-" \
      [lsort [array names filesetUtils]] \
      ]

    filesetMenu::utilsMarksTicks
}

proc filesetMenu::choose {menu item} {
    changeFileSet $item
}

proc filesetMenu::hideOrShow {menu item} {
    global filesetsNotInMenu
    
    # Workaround removal of ellipsis from menu items.
    if {![fileset::exists $item]} {
	if {[fileset::exists "${item}…"]} {
	    append item "…"
	}
    }
    
    if {[catch {filesetMenu::_hideOrShow $item} ret]} {
	# error
	alertnote $ret
	return
    }
    
    if {$ret} {
	filesetMenu::rebuild
    }
    
    # Trying to unhide something may actually fail, so
    # we always check the real list.
    if {[lcontains filesetsNotInMenu $item]} {
	status::msg "The fileset \"$item\" is now hidden."
    } else {
	status::msg "The fileset \"$item\" is now in the main fileset menu."
    }
}

proc filesetMenu::_hideOrShow {fset} {
    global filesetsNotInMenu
    
    if {![fileset::exists $fset]} {
	return -code error "No such fileset \"$fset\""
    }
    set rebuild 0
    
    if {[lcontains filesetsNotInMenu $fset]} {
	if {[fileset::getKindFromFset $fset] == "procedural"} {
	    return -code error "Sorry, '$fset' is a 'procedural'\
	      fileset, and those filesets are completely dynamic\
	      and cannot appear in menus."
	}
	set idx [lsearch $filesetsNotInMenu $fset]
	set filesetsNotInMenu [lreplace $filesetsNotInMenu $idx $idx]		
	markMenuItem -m hideFileset $fset off
	# would be better if we could just insert it
	set rebuild 1
    } else {
	lappend filesetsNotInMenu $fset
	markMenuItem -m hideFileset $fset on
	if {[catch {filesetMenu::removeInMenu $fset}]} {
	    set rebuild 1
	}
    }
    prefs::modified filesetsNotInMenu
    return $rebuild
}

proc filesetMenu::ensureNoProceduralFilesets {} {
    global filesetsNotInMenu
    set notIn {}
    foreach s $filesetsNotInMenu {
	if {[fileset::exists $s]} {
	    lappend notIn $s
	}
    }
    if {[llength $notIn] != [llength $filesetsNotInMenu]} {
	set filesetsNotInMenu $notIn
	prefs::modified filesetsNotInMenu
    }
    foreach s [fileset::names] {
	if {[fileset::getKindFromFset $s] == "procedural"} {
	    if {[lsearch -exact $filesetsNotInMenu $s] == -1} {
		lappend filesetsNotInMenu $s
	    }
	}
    }
}

proc filesetMenu::utilsMarksTicks {} {
    global filesetsNotInMenu
    foreach name $filesetsNotInMenu {
	if {[fileset::getKindFromFset $name] == "procedural"} {continue}
	markMenuItem -m hideFileset $name on
    }
    global currFileSet
    markMenuItem -m choose $currFileSet on
}

filesetMenu::ensureNoProceduralFilesets
