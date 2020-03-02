## -*-Tcl-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "menus.tcl"
 #                                          created: 06/17/1994 {00:26:45 PM}
 #                                      last update: 2006-06-02 23:02:12
 # Description:
 #  
 # Menu creation, support procs
 # 
 # This file is distributed under a Tcl style license.
 #  
 # ==========================================================================
 ##

proc menus.tcl {} {}

# ===========================================================================
# 
# ×××× Init Menu Building ×××× #
# 
# These are all called by "runAlphaTcl.tcl", and should never be called by
# any other AlphaTcl code.
# 

namespace eval menu {}

## 
 # -------------------------------------------------------------------------
 # 
 # "menu::buildBasic" --
 # 
 # Called by "runAlphaTcl.tcl", before the procs below.  It defines "dummy"
 # menus for "File" through "Config", which are inserted into the menubar and
 # then rebuilt later.
 # 
 # -------------------------------------------------------------------------
 ##

proc menu::buildBasic {} {
    # These are built on the fly
    Menu -n File -p menu::generalProc {}
    Menu -n Edit -p menu::generalProc {}
    Menu -n Text -p menu::generalProc {}
    Menu -n Search {}
    Menu -n Utils {}
    Menu -n Config {}
    
    insertMenu File Edit Text Search Utils Config
    
    help::buildMenu
    return
}

namespace eval alpha {}

## 
 # -------------------------------------------------------------------------
 # 
 # "alpha::buildAndInsertMenus" --
 # 
 # Define and build the main menus (by sourcing "alphaMenus.tcl"), and 
 # then build any other menus needed (at startup), and finally insert
 # them into the menubar.
 # 
 # -------------------------------------------------------------------------
 ##

proc alpha::buildAndInsertMenus {} {
    # Build main menus
    uplevel #0 {
	source [file join $HOME Tcl SystemCode alphaMenus.tcl]
	menu::buildSome "File" "Edit" "Text" "Search" "Utils" "Config"
    }
    
    # Build any other menus
    global menu::_needs_building
    eval menu::buildSome [array names menu::_needs_building]

    # Insert main menus
    global global::features index::feature
    foreach m $global::features {
	if {[lindex [set index::feature($m)] 2] == 1} {
	    global $m
	    insertMenu [set $m]
	}
    }
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Menu Building procs ×××× #
# 
# The following procedures
# 
#     menu::buildProc
#     menu::buildSome
#     menu::buildOne
#     menu::postEval
# 
# are the standard API for building menus in AlphaTcl.  Any Menu Name that is
# registered with [menu::buildProc] can be built using [menu::buildSome].
# Menus that are built in this way can be later adjusted using
# 
#     menu::insert
#     menu::uninsert
#     
#     menu::replaceWith
#     menu::removeFrom
# 
# These procedures are pairs, and "undoing" any insertion/replacement must be
# performed using the same arguments.  They call [menu::_needs_building],
# which determines if the menus are ready to be built. 
# 

## 
 # -------------------------------------------------------------------------
 # 
 # "menu::buildProc" --
 # 
 # Register a procedure to be the 'build proc' for a given menu.  This
 # procedure can do one of two things:
 #  
 # (i) Build the entire menu, including evaluating the 'menu ...'  command.
 # In this case the build proc should return anything which doesn't begin
 # 'build ...'
 #  
 # (ii) Build up part of the menu, and then allow pre-registered menu
 # insertions/replacements to take-effect.  In this case the procedure should
 # return a list of the items (listed by index):
 #  
 #   0: "build"
 #   
 #   1: list-of-items-in-the-menu
 #   
 #   2: list of other flags.  If the list doesn't contain '-p', we use the
 #   standard [menu::generalProc] procedure.  If it does contain '-p' general
 #   menu procedure to call when an item is selected.
 #   
 #   If nothing is given, or if '-1' is given, then we don't have a
 #   procedure.  If "" is given, we use the standard [menu::generalProc]
 #   procedure.  Else we use the given procedure.
 #   
 #   If "-m" is given then we don't do menu conversion.
 #   
 #   3: list of submenus which need building.
 #   
 #   4: over-ride for the name of the menu.
 #  
 # You must register the build-proc before attempting to build the menu.
 # Once registered, any call of [menu::buildSome <name>] will properly
 # (re)build your menu.
 #  
 # The 'postEval' argument is a script that will be evaluated after the menu
 # has been (re)built.
 # 
 # -------------------------------------------------------------------------
 ##

proc menu::buildProc {name proc {postEval ""}} {
    global menu::build_procs menu::posteval
    set menu::build_procs($name) $proc
    if {[string length $postEval]} {
	set menu::posteval($name) $postEval
    }
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "menu::buildSome" --
 # 
 #  Important procedure which builds all known/registered menus from a
 #  number of pieces.  It allows the inclusion of menus pieces registered
 #  with the menu::insert procedure, which allows you easily to add items
 #  (including dynamic and hierarchial) to any of Alpha's menus.
 # 
 # Results:
 #  Various menus are (re)built
 # 
 # Side effects:
 #  Items added to those menus with 'addMenuItem' will vanish.
 # 
 # --Version--Author------------------Changes-------------------------------
 #    1.0     <vince@santafe.edu> original
 #    2.0     <vince@santafe.edu> more compact, more like tk
 # -------------------------------------------------------------------------
 ##

proc menu::buildSome {args} {
    set msubs {}
    foreach token $args {
	# This menu no longer needs building
	unset -nocomplain menu::_needs_building($token)
	# Build it, and record any submenus that need building
	eval lappend msubs [menu::buildOne $token]
    }
    # build sub-menus of those built
    if {[llength $msubs]} {eval menu::buildSome $msubs}
    foreach token $args {
	hook::callAll menuBuild $token
    }
    return
}

proc menu::buildOne {args} {
    global menu::additions menu::build_procs menu::items
    set token [lindex $args 0] ; set args [lrange $args 1 end]
    set len [llength $args]
    if {$len > 0 || [info exists menu::build_procs($token)]} {
	if {$len > 0} {
	    set res $args
	} else {
	    if {[catch "[set menu::build_procs($token)]" res]} {
		error::occurred "The menu $token had a problem\
		  starting up ; $res"
		return ""
	    }
	}
	switch -- [lindex $res 0] {
	    "build" {
		set ma [lindex $res 1]
		if {[llength $res] > 2} {
		    set theotherflags [lrange [lindex $res 2] 1 end]
		    if {[lindex $res 2 0] != -1} {
			set mproc [lindex $res 2 0]
		    }
		    if {[lindex $res 3] != ""} {
			eval lappend msubs [lindex $res 3]
		    }
		    if {[lindex $res 4] != ""} { set name [lindex $res 4] }
		}
	    } "menu" - "Menu" {
		eval $res
		menu::postEval $token
		return ""
	    } default {
		menu::postEval $token
		return ""
	    }
	}
    } else {
	set ma ""
	if {[info exists menu::items($token)]} {
	    set ma [set menu::items($token)]
	    global menu::proc menu::which_subs menu::otherflags
	    if {[info exists menu::proc($token)]} {
		set mproc [set menu::proc($token)]
	    }
	    if {[info exists menu::which_subs($token)]} {
		eval lappend msubs [set menu::which_subs($token)]
	    }
	    if {[info exists menu::otherflags($token)]} {
		set theotherflags [set menu::otherflags($token)]
	    }
	}
    }

    if {![info exists name]} { set name $token }
    # add any registered items and make the menu contents
    if {[info exists menu::additions($token)]} {
	set tokens $menu::additions($token)
	set badtokens {}
	for {set i 0} {$i < [llength $tokens]} {incr i} {
	    set addition [lindex $tokens $i]
	    set ins $addition
	    set where [lindex $ins 1]
	    set type [lindex $ins 0]
	    set ins [lrange $ins 2 end]
	    switch -- $type {
		"submenu" {
		    lappend msubs [lindex $ins 0]
		    # 'ins' may be just a menu name, or also contain various
		    # additional flags (-p proc etc)
		    set ins [list [concat Menu -n $ins [list {}]]]
		}
	    }
	    switch -- [lindex $where 0] {
		"replace" {
		    set old [lindex $where 1]
		    if {[set ix [eval llindex ma $old]] != -1} {
			set ma [eval [list lreplace $ma \
			  $ix [expr {$ix -1 + [llength $old]}]] $ins]
		    } else {
			if {[lsearch -exact $badtokens $addition] == -1} {
			    # Try again, in case we have some sequence-
			    # dependence here.  
			    lappend tokens $addition
			    lappend badtokens $addition
			} else {
			    alertnote "Bad menu::replacement registered '$old'"
			}
		    }
		    
		}
		"end" {
		    eval lappend ma $ins
		}
		"after" {
		    set ipos [lindex $where 1]
		    if {![is::UnsignedInteger $ipos]} {
			if {[set pos [lsearch -exact $ma $ipos]] != -1} {
			    set ipos $pos
			} else {
			    alertnote "The string '$ipos' has not be found\
				       in menu '$name'. '$ins' will be put at\
				       the end of this menu"
			    set ipos [llength $ma]
			}
		    }
		    incr ipos
		    set ma [eval linsert [list $ma] $ipos $ins]
		}
		default {
		    if {![is::UnsignedInteger $where]} {
			if {[set pos [lsearch -exact $ma $where]] != -1} {
			    set where $pos
			} else {
			    alertnote "The string '$where' has not be found\
				       in menu '$name'. '$ins' will be put at\
				       the end of this menu"
			    set where [llength $ma]
			}
		    }
		    set ma [eval linsert [list $ma] $where $ins]
		}
	    }
	}
    }

    # build the menu
    set realname $name
    set name [list -n $name]
    if {[info exists theotherflags]} {
	set name [concat $theotherflags $name]
    }

    lappend name -h [menu::helpText [lindex $name end]]

    # Remove start or end separators (should also remove duplicate
    # separators, really).  This used to be done by a regexp, but
    # that had to be disabled because it caused problems, not
    # surprisingly, since it is silly to use a regexp on a list.
    if {[lindex $ma 0] eq "(-)"} {
	set ma [lrange $ma 1 end]
    }
    #if {[lindex $ma end] eq "(-)"} {
	#set ma [lrange $ma 0 end-1]
    #}
    
    if {[info exists mproc]} {
	if {$mproc != ""} {
	    eval Menu $name -p $mproc [list $ma]
	} else {
	    eval Menu $name [list $ma]
	}
    } else {
	eval Menu $name -p menu::generalProc [list $ma]
    }
    
    if {1} {
	#alpha::stdout "dimming $realname"
	# Experimental automatic menu-dimming code
	alpha::performDimmingForMenu $realname
    }
    
    menu::postEval $token
    if {[info exists msubs]} {
	return $msubs
    }
    return ""
}

proc menu::postEval {name} {
    global menu::posteval
    if {[info exists menu::posteval($name)]} {
	catch {uplevel \#0 [set menu::posteval($name)]}
    }
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "menu::_needs_building" --
 # 
 # This is a private procedure that should never be called by any other
 # AlphaTcl code than the insert/remove procedures below.  It determines
 # whether the Alpha GUI is ready or not -- if so, then the menu is built,
 # otherwise we cache the name of the menu so that it can be built later.
 # 
 # (Could possibly be named [menu::buildWhenReady])
 # 
 # -------------------------------------------------------------------------
 ##

proc menu::_needs_building {name} {
    global alpha::guiNotReady menu::_needs_building
    if {[info exists alpha::guiNotReady]} {
	set menu::_needs_building($name) 1
    } else {
	menu::buildSome $name
    }
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "menu::insert" --
 # 
 # Add given items to a given menu, provided they are not already there.
 # Rebuild that menu if necessary.
 # 
 # Use [menu::replaceWith] to replace a given menu item with others.
 # 
 # Arguments:
 # 
 #     name, type, where, then list of new items.
 #  
 # The "name" is the name of a Menu that should be changed.
 #  
 # "type" = 'items' 'submenu'
 #  
 # "where" can be any of 
 # 
 # (1) a non-negative integer
 # (2)'end' or the name of an existing menu item (modifiers not necessary)
 # 
 # Alternatively it may be a list composed of two elements: 'after' followed
 # by any of the preceding options.  Without 'after, the insertion of the new
 # item(s) takes place before the given position, otherwise after the given
 # position/item.
 #  
 # Multiple inserts are allowed at the same menu position (before and/or
 # after).
 #  
 # The proc [menu::uninsert] does the opposite of this one, but the list of
 # arguments must be exactly the same as those that were originally supplied
 # to [menu::insert].
 # 
 # -------------------------------------------------------------------------
 ##

proc menu::insert {name args} {
    if {[llength $args] < 3} { error "Too few args to menu::insert" }
    global menu::additions
    if {[info exists menu::additions($name)]} {
	set a [set menu::additions($name)]
	if {[lsearch -exact $a $args] != -1} { 
	    return 
	}
	# check if it's there but in a different place; we over-ride
	set dblchk [lreplace $args 1 1 "*"]
	if {[set i [lsearch -glob $a $dblchk]] == -1} {
	    unset i
	}
    }
    if {[info exists i]} {
	set menu::additions($name) [lreplace $a $i $i $args]
    } else {
	lappend menu::additions($name) $args
    }
    menu::_needs_building $name
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "menu::uninsert" --
 # 
 # Removes an insertion created by [menu::insert].  The arguments must be
 # exactly the same in order for this to work.
 #  
 # -------------------------------------------------------------------------
 ##

proc menu::uninsert {name args} {
    global menu::additions
    set a [set menu::additions($name)]
    if {[set idx [lsearch -exact $a $args]] == -1} { 
	return 
    }
    set menu::additions($name) [lreplace $a $idx $idx]
    menu::_needs_building $name
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "menu::replaceWith" --
 # 
 # Replace item(s) in a given menu with either a submenu or some items.
 # Rebuild that menu if necessary.
 # 
 # Use [menu::insert] to add a given menu item.
 # 
 # Arguments:
 # 
 #     name, current, type, then list of new items.
 #  
 # The "name" is the name of a Menu that should be changed.
 # 
 # "current" is the name of the item(s) in the default menu list.
 #  
 # "type" = 'items' 'submenu'
 #  
 # Multiple calls to [menu::replaceWith] with the same 'current' will simply
 # over-write each other (with the last one taking precedence).
 # 
 # If you wish to insert items (rather than actually replace a given item),
 # then use [menu::insert], which can be used to insert before or after any
 # known item, or at any numeric menu index, or at the menu end.
 #  
 # The proc [menu::removeFrom] does the opposite of this one, but the list of
 # arguments must be exactly the same as those that were originally supplied
 # to [menu::replaceWith].
 # 
 # -------------------------------------------------------------------------
 ##

proc menu::replaceWith {name current type args} {
    global menu::additions
    
    set replace 1
    if {[lindex $args 0] eq $current} {
	if {[llength $args] > 1} {
	    # This is actually an 'insert after' request.
	    eval [list menu::insert $name $type [list after $current]] \
	      [lrange $args 1 end]
	    return
	} else {
	    # Only need to check below if we are removing
	    # a pre-existing replacement.
	    set replace 0
	}
    }
    if {![info exists menu::additions($name)]} {
	if {$replace} {
	    lappend menu::additions($name) \
	      [concat [list $type [list replace $current]] $args]
	}
    } else {
	set add 1
	set j 0
	foreach i [set menu::additions($name)] {
	    if {[lrange $i 0 1] == [list $type [list replace $current]]} {
		if {[lindex $i 1] != $args} {
		    if {$replace} {
			set menu::additions($name) \
			  [lreplace [set menu::additions($name)] $j $j \
			  [concat [list $type [list replace $current]] $args]]
		    } else {
			set menu::additions($name) \
			  [lreplace [set menu::additions($name)] $j $j]
		    }
		    set replace 0
		    break
		} else {
		    # no change
		    return
		}
	    }
	    incr j
	}
	if {$replace} {
	    lappend menu::additions($name) \
	      [concat [list $type [list replace $current]] $args]
	}
    }
    menu::_needs_building $name
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "menu::removeFrom" --
 # 
 # Removes a replacement created by [menu::replaceWith].  The arguments must
 # be exactly the same in order for this to work.
 #  
 # -------------------------------------------------------------------------
 ##

proc menu::removeFrom {name current type args} {
     global menu::additions
     if {([lindex $args 0] eq $current) && ([llength $args] > 1)} {
	 # This was actually an 'insert after' request.
	 eval [list menu::uninsert $name $type [list "after" $current]] \
	   [lrange $args 1 end]
	 return
     }
     if {[info exists menu::additions($name)]} {
	 set rString [concat [list $type [list "replace" $current]] $args]
	 set i [lsearch -exact [set menu::additions($name)] $rString]
	 if {$i != -1} {
	     set menu::additions($name) \
	       [lreplace [set menu::additions($name)] $i $i]
	     menu::_needs_building $name
	 }
     }
     return
}

# ===========================================================================
# 
# ×××× Additional Menu support ×××× #
# 

## 
 # -------------------------------------------------------------------------
 # 
 # "menu::generalProc" --
 # 
 #  If either 'item' or 'menu::item' exists, call it.  Else try and
 #  autoload 'item', if that fails try and autoload 'menu::item'
 # -------------------------------------------------------------------------
 ##

proc menu::generalProc {menu item {lower 1}} {
    if {$lower} {set menu [string tolower $menu]}
    if {[info commands ::${menu}::${item}] != ""} {
	uplevel \#0 ::${menu}::$item
    } elseif {[info commands $item] != ""} {
	uplevel \#0 $item
    } elseif {[auto_load ::${menu}::$item]} {
	uplevel \#0 ::${menu}::$item
    } else {
	uplevel \#0 $item
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "menu::moveToEnd" --
 # 
 # Move a toplevel menu to the end of the chain
 # 
 # -------------------------------------------------------------------------
 ##

proc menu::moveToEnd {menuName} {
    global $menuName
    if {[menu::inserted [set $menuName]]} {
	removeMenu [set $menuName]
	insertMenu [set $menuName]
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "menu::replaceRebuild" --
 # 
 # Replaces the name of a menu that has already been defined, i.e. it can
 # change the icon used in the menubar.
 # 
 # -------------------------------------------------------------------------
 ##

proc menu::replaceRebuild {name title} {
    global $name alpha::guiNotReady
    set bar [menu::inserted [set $name]]
    if {$bar} {removeMenu [set $name]}
    set $name $title
    if {![info exists alpha::guiNotReady]} {
	menu::buildSome $name
	if {$bar} {insertMenu [set $name]}
    }
}

proc menu::helpText {name} {
    switch -- $name {
	Config {
	    return [list "Config menu\r\rUse this menu to view and adjust\
	      your current preferences settings."]
	}
	Text {
	    return [list "Text menu\r\rUse this menu to manipulate lines,\
	      paragraphs or larger blocks of text.|Text menu\r\rIt is disabled\
	      because no windows are currently open."]
	}
	Utils {
	    return [list "Utils menu\r\rThis menu contains miscellaneous\
	      operations such as pairwise window comparison, spell-checking,\
	      plus access to various command-line 'Shells'."]
	}
	Search {
	    return [list "Search menu\r\rUse this menu to perform sophisticated\
	      find or replace operations on the contents of single or\
	      multiple windows or files."]
	}
	Edit {
	    return [list "Edit menu\r\rUse this menu to perform the standard\
	      cut, copy, paste operations, and to carry out other minor\
	      textual manipulations."]
	}
	File {
	    return [list "File menu\r\rUse this menu to open new windows,\
	      save or print existing windows, access recently used files,\
	      and revert windows to previously saved versions."]
	}
	default {
	    set h [string trim [lindex [alpha::package description $name] 1]]
	    if {$h ne ""} {
		return [list $h]
	    } else {
		return [list "This is the $name menu"]
	    }
	}
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 #	"menu::buildHierarchy" --
 # 
 #  Given a list of folders, 'menu::buildHierarchy' returns a
 #  hierarchical menu based on the files and subfolders in each of
 #  these folders.  Pathnames are optionally stored in an array in the
 #  caller's context given by the argument 'filePaths'.  The path's
 #  index in this array is formed by concatenating the submenu name and
 #  the filename, allowing the pathname to be retrieved by the
 #  procedure 'proc' when the menu item is selected.
 # 
 #  The search may be restricted to files with specific extensions, or
 #  files matching a certain pattern.  A search depth may also be given,
 #  with three levels of subfolders assumed by default.
 # 
 #  See filesets code, perl or latex modes for examples.
 # 
 #  (originally written by Tom Pollard, with modifications by Vince Darley
 #  and Tom Scavo)
 # 
 # --Version--Author------------------Changes-------------------------------
 #    1.0    Tom Pollard	      original
 #    2.0    <vince@santafe.edu> multiple extensions, optional paths
 #    2.1    Tom Scavo	         multiple folders
 #    2.2    <vince@santafe.edu> pattern matching as well as exts
 #    2.3    <vince@santafe.edu> handles unique menu-names and does text only
 #    2.4    <jl@theophys.kth.se>  now also handles patterns like "*.{a,b}"
 #    2.5    <vince@santafe.edu> better glob, non-dup dir handling
 #    3.0    <vince@santafe.edu> fix rare bug, deal with dirs containing
 #                               a single file only.
 # -------------------------------------------------------------------------
 ##
proc menu::buildHierarchy {folders name proc {filePaths {}} {exts *} \
  {depth 3} {getMenu "menu::returnName"} {ignore ""} {top 1}} {
    global filesetmodeVars
    if { $filePaths != "" } {
	upvar 1 $filePaths fp
    }
    if {[llength $exts] > 1} {
	regsub -all {\.} $exts "" exts
	set exts "*.{[join $exts ,]}"
    } elseif {[string match ".*" $exts] && ![string match {*\**} $exts]} {
	set exts "*$exts"
    } elseif {$exts == ""} {
	# Don't allow an empty pattern, it is totally bogus
	set exts "*"
    }
    set includeHidden 0
    incr depth -1
    set overallMenu {}
    foreach folder $folders {
	if {[file exists $folder]} {
	    if {![file isdirectory $folder]} {
		set folder [file dirname $folder]
	    }
	    if {[regexp -- "[quote::Regfind [file separator]]\$" $folder]} {
		set folder [string trimright $folder [file separator]]
	    }
	    set from [expr {[string length $folder] \
	      - [string length [file tail $folder]]}]
	    # This loop acts to replace a cascade of several menus
	    # like 'net->tcltk->www' by one: 'net/tcltk/www', if the
	    # intermediate directories are empty of matches.
	    while {1} {
		set subfolders [glob -nocomplain -types d -dir $folder *]
		if {$includeHidden} {
		    set hidden [glob -nocomplain -types {d hidden} -dir $folder *]
		    set subfolders [lsort -unique [concat $subfolders $hidden]]
		}
		if {[info exists filesetmodeVars(includeNonTextFiles)] \
		  && !$filesetmodeVars(includeNonTextFiles)} {
		    set filenames [glob -types TEXT -nocomplain -dir $folder \
		      $exts]
		} else {
		    set filenames [glob -nocomplain -dir $folder -- $exts]
		}
		set filenames [lremove -- $filenames $subfolders]
		set orderedList [lsort -dictionary \
		  [concat $subfolders $filenames]]
		if {[llength $ignore]} {
		    set ignoreList \
		      [eval [list glob -nocomplain -dir $folder --] $ignore]
		    # We need '-all' because directories are probably
		    # listed twice.
		    set orderedList [lremove -- $orderedList $ignoreList]
		}
		# We can't concatenate with the 'top' because that is
		# a fixed name of a root menu (e.g. a fileset).
		if {!$top && ([llength $orderedList] == 1) \
		  && [file isdirectory [lindex $orderedList 0]]} {
		    # The only thing that matches is a directory,
		    # so we don't bother creating a submenu just for it.
		    set folder [file join $folder [lindex $orderedList 0]]
		} else {
		    break
		}
	    }
	    if {$name == 0} {
		set name [string range $folder $from end]
	    }
	    # We now have a list of all files/folders, counted once
	    # each.
	    set menu {}
	    set count 0
	    
	    if {$top} {
		# 'top' menus aren't allowed to change the name from
		# what we expect.  In particular they aren't allowed
		# to compress names with lower menus.
		set mname [eval $getMenu [list -top $top -- $name]]
	    } else {
		# Calculate the script to evaluate to get the name of
		# the menu.
		set menuNameScript [concat $getMenu [list -top $top -- $name]]
	    }
	    foreach m $orderedList {
		if {[file isfile $m]} {
		    set fname [file tail $m]
		    lappend menu "${fname}&"
		    if {$filePaths != ""} {
			set unique [file join $name $fname]
			while {[info exists fp($unique)]} {
			    append unique " "
			}
			set fp($unique) $m
		    }
		    incr count
		} elseif {$depth > 0} {
		    set subM [menu::buildHierarchy \
		      [list ${m}] 0 $proc fp $exts $depth $getMenu $ignore 0]
		    if {[llength $subM]} { 
			lappend menu $subM
			set subMenu $subM
		    }
		}
	    }
	    if {[llength $menu]} {
		eval [list lappend overallMenu] $menu
	    }
	} else {
	    beep
	    alertnote "menu::buildHierarchy:  Folder $folder does not exist!"
	}
    }
    
    if {[llength $overallMenu]} {
	if { [string length $proc] > 1 } {
	    set pproc [list -p $proc]
	} else {
	    set pproc [list]
	}	
	if { $getMenu != "menu::returnName" } {
	    if {[string length $proc] > 1} { 
		set pproc [list -p filesetMenu::subProc] 
	    }
	}
	#puts "[llength $overallMenu] , $name, [info exists subMenu]"
	if {!$top && [llength $overallMenu] == 1 && [info exists subMenu]} {
	    set origName [lindex $subMenu 3]
	    eval $getMenu [list -top $top -deregister -- $origName]
	    set name [string trimright [file join $name $origName]]
	    set mname [eval $getMenu [list -top $top -- $name]]
	    return [lreplace $subMenu 3 3 $mname]
	} else {
	    if {[info exists menuNameScript]} {
		set mname [eval $menuNameScript]
	    }
	    return [concat [list Menu -m -n] [list $mname] $pproc \
	      [list $overallMenu]]
	}
    } else {
	return [list]
    }
}

# return last argument 
proc menu::returnName {args} { 
    return [lindex $args end]
}

# ??? This doesn't appear to be used anywhere in AlphaTcl.

proc menu::reinterpretOldMenu {args} {
    set ma [lindex $args end]
    set args [lreplace $args end end]
    getOpts {-n -M -p}
    if {[info exists opts(-p)]} {
	lappend proc $opts(-p)
    } else {
	lappend proc "-1"
    }
    if {[info exists opts(-M)]} { lappend proc -M $opts(-m) }
    if {[info exists opts(-m)]} { lappend proc -m }
    menu::buildOne $opts(-n) build $ma $proc
    return
}

# ===========================================================================
# 
# ×××× Menu Icons ×××× #
# 

proc menu::itemWithIcon {name icon} {
    return "/\x1e${name}^[text::Ascii $icon 1]"
}

namespace eval icon {}

proc icon::FromID {ID} {
    return "^[text::Ascii [expr {$ID - 0x1D0}] 1]"
}

proc icon::FromSig {sig} {
    global alpha::_icons
    if {[set p [lsearch -glob ${alpha::_icons} "[quote::Find ${sig}] *"]] != -1} {
	set p [lindex ${alpha::_icons} $p]
	return [lindex $p 2]
    } else {
	return ""
    }
}

proc icon::MenuFromSig {sig} {
    global alpha::_icons
    set p [lsearch -glob ${alpha::_icons} "[quote::Find ${sig}] *"]
    if {$p != -1} {
	set char [expr {[lindex ${alpha::_icons} $p 2] -208}]
	if {$char < 1 || $char > 256} { return "" }
	return "^[text::Ascii $char 1]"
    } else {
	return ""
    }
}

# ===========================================================================
# 
# .