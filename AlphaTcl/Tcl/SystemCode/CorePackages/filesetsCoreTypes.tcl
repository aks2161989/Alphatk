## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "filesetsCoreTypes.tcl"
 #                                          created: 05/01/2000 {14:10:07 PM}
 #                                      last update: 03/31/2006 {11:29:10 PM}
 # Description:
 # 
 # This file contains the implementation of the basic fileset types which are
 # included in Alpha's core.  The filesets library code is in the file
 # "filesets.tcl".
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #    www: <http://www.santafe.edu/~vince/>
 #      
 # ==========================================================================
 ##

proc filesetsCoreTypes.tcl {} {}

# Make sure we've loaded the package.
alpha::package require filesets

namespace eval fileset {}

proc fileset::getDirAndPattern {} {
    global gfileSets fileSetsExtra
    set name [prompt "New fileset name:" ""]
    if {![string length $name]} {
	status::msg "Cancelled -- no text was entered."
	return
    }
    set dir [get_directory -p "New fileset dir:"]
    if {![string length $dir]} return
    
    set filePat [prompt "File pattern:" "*"]
    if {![string length $filePat]} {
	# We always need a pattern.
	set filePat "*"
	return
    }
    return [list $name $dir $filePat]
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Directory Filesets ×××× #
# 

namespace eval fileset::fromDirectory {}

proc fileset::fromDirectory::create {args} {
    global gfileSets gfileSetsType fileSetsExtra
    
    if {[llength $args] == 3} {
	foreach {name dir pat} $args {}
    } elseif {[llength $args] != 0} {
	return -code error "Bad args"
    } else {
	foreach {name dir pat} [fileset::getDirAndPattern] {}
	if {![info exists name] || ![string length $name]} return
	set filePatIgnore [prompt "List of file patterns to ignore:" ""]
	if {$filePatIgnore != ""} {
	    set fileSetsExtra($name) $filePatIgnore
	}
    }
    set gfileSets($name) [list $dir $pat]
    set gfileSetsType($name) "fromDirectory"
    
    return $name
}

proc fileset::fromDirectory::getRoot {name} {
    global gfileSets
    return [lindex $gfileSets($name) 0]
}

proc fileset::fromDirectory::setDetails {name dir pat ignore} {
    global gfileSets fileSetsExtra
    set gfileSets($name) [list $dir $pat]
    set fileSetsExtra($name) $ignore
    modifyFileset $name
}

proc fileset::fromDirectory::getDialogItems {name} {
    global gfileSets fileSetsExtra
    lappend res \
      [list [list "smallval" "folder"] "Fileset dir:" \
      [lindex $gfileSets($name) 0]\
      "Base directory for fileset"] \
      [list variable "File pattern:" [lindex $gfileSets($name) 1]\
      "Only include files which match this pattern (any 'glob' style pattern\
      may be used, such as \"*\", \"*.tcl\", \"*.{txt,text}\", etc)"]
    if {[info exists fileSetsExtra($name)]} {
	set cur $fileSetsExtra($name)
    } else {
	set cur ""
    }
    lappend res [list variable "List of file patterns to ignore:" $cur]
    set res
}

proc fileset::fromDirectory::updateContents {name {andMenu 0}} {
    if {$andMenu} {
	set menu [list]
	foreach m [getFilesInSet $name] {
	    lappend menu "[file tail $m]&"
	}
	return [filesetMenu::makeSub $name $name fileset::openItemProc \
	  [lsort -increasing $menu]]
    } else {
	return [list]
    }
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Hierarchy Filesets ×××× #
# 

namespace eval fileset::fromHierarchy {}

proc fileset::fromHierarchy::create {args} {
    global gfileSets gfileSetsType
    
    if {[llength $args] == 4} {
	foreach {name dir pat depth} $args {}
    } elseif {[llength $args] != 0} {
	return -code error "Bad args"
    } else {
	foreach {name dir pat} [fileset::getDirAndPattern] {}
	if {![string length $name]} return
	set depth [listpick -p "Depth of hierarchy?" -L 3 {1 2 3 4 5 6 7}]
	if { $depth == "" } {set depth 3}
    }
	
    set gfileSetsType($name) "fromHierarchy"
    set gfileSets($name) [list $dir $pat $depth]
    
    return $name
}

proc fileset::fromHierarchy::getRoot {name} {
    global gfileSets
    return [lindex $gfileSets($name) 0]
}

proc fileset::fromHierarchy::setDetails {name dir pat depth ignore} {
    global gfileSets fileSetsExtra
    set gfileSets($name) [list $dir $pat $depth]
    set fileSetsExtra($name) $ignore
    modifyFileset $name
}

proc fileset::fromHierarchy::getDialogItems {name} {
    global gfileSets fileSetsExtra
    set depth {1 2 3 4 5 6 7}

    set curDepth [lindex $gfileSets($name) 2]
    if {$curDepth eq ""} {
	set curDepth 3
    }
    
    lappend res \
      [list [list "smallval" "folder"] "Fileset dir:" \
      [lindex $gfileSets($name) 0] \
      "Base directory for fileset"] \
      [list variable "File pattern:" [lindex $gfileSets($name) 1] \
      "Only include files which match this pattern (any 'glob' style pattern\
      may be used, such as \"*\", \"*.tcl\", \"*.{txt,text}\", etc)"] \
      [list [list menu $depth] "Depth of hierarchy?"\
      $curDepth "Number of levels deep in the disk\
      hierarchy to include"]
    if {[info exists fileSetsExtra($name)]} {
	set cur $fileSetsExtra($name)
    } else {
	set cur ""
    }
    lappend res [list variable "List of file patterns to ignore:" $cur]
    set res
}

proc fileset::fromHierarchy::updateContents {name {andMenu 0}} {
    global fileSets gfileSets fileSetsExtra
    set dir [lindex $gfileSets($name) 0]
    set patt [lindex $gfileSets($name) 1]
    set depth [lindex $gfileSets($name) 2]
    if {[info exists fileSetsExtra($name)]} {
	set ignore $fileSetsExtra($name)
    } else {
	set ignore ""
    }
    if {[file exists $dir]} {
	# we make the menu as a string, but can bin it if we like
	set menu [menu::buildHierarchy [list $dir] $name\
	  fileset::openItemProc filesetTemp $patt $depth \
	  [list filesetMenu::registerName $name -proc fileset::openItemProc] \
	  $ignore]
    } else {
	alertnote "No such directory '$dir'"
	error "No such directory '$dir'"
    }
    
    # we need to construct the list of items
    set fileSets($name) {}
    if {[info exists filesetTemp]} {
	foreach n [array names filesetTemp] {
	    lappend fileSets($name) $filesetTemp($n)
	}
    }
    return $menu
}

proc fileset::fromHierarchy::selected {fset menu item} {
    global gfileSets
    set dir [lindex $gfileSets($fset) 0]
    set ff [getFilesInSet $fset]
    if { $fset eq $menu } {
	# it's top level
	if {[set match [lsearch $ff [file join ${dir} $item]]] >= 0} {
	    autoUpdateFileset $fset
	    file::openAny [lindex $ff $match]
	    return
	}
    }
    # the following two are slightly cumbersome, but give us the best
    # chance of finding the correct file given any ambiguity (which can
    # certainly arise if file and directory names clash excessively).
    if {[set match [lsearch $ff [file join ${dir} ${menu} $item]]] >= 0} {
	autoUpdateFileset $fset
	file::openAny [lindex $ff $match]
	return
    }
    if {[set match [lsearch $ff [file join ${dir} * ${menu} $item]]] >= 0} {
	autoUpdateFileset $fset
	file::openAny [lindex $ff $match]
	return
    }
    if {[string range $item 0 1] == " -"} {
	set item [string range $item 1 end]
	return [fileset::fromHierarchy::selected $fset $menu $item]
    }
    error "Weird! Couldn't find it."
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Recurse In Filesets ×××× #
# 

namespace eval fileset::recurseIn {}

proc fileset::recurseIn::create {args} {
    global gfileSets gfileSetsType filesetsNotInMenu
    
    if {[llength $args] == 2} {
	foreach {name dir} $args {}
    } elseif {[llength $args] != 0} {
	return -code error "Bad args"
    } else {
	set name [prompt "New fileset name:" ""]
	if {![string length $name]} {
	    status::msg "Cancelled -- no text was entered."
	    return
	}
	set dir [get_directory -p "New fileset dir:"]
	if {![string length $dir]} return
    }
    
    set gfileSets($name) [list $dir *]
    set gfileSetsType($name) "recurseIn"
    
    lappend filesetsNotInMenu $name
    return $name
}

proc fileset::recurseIn::getRoot {name} {
    global gfileSets
    return [lindex $gfileSets($name) 0]
}

proc fileset::recurseIn::setDetails {name dir} {
    global gfileSets
    set gfileSets($name) [list $dir *]
    modifyFileset $name
}

proc fileset::recurseIn::getDialogItems {name} {
    global gfileSets
    lappend res \
      [list [list "smallval" "folder"] "Fileset dir:" \
      [lindex $gfileSets($name) 0]\
      "Base directory for fileset"]
    return $res
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Open Windows Filesets ×××× #
# 
# This fileset creates an initial list based upon all open windows that exist
# as files.  Once the list has been created, the user is able to modify it.
# While this will remain a fileset of the "fromOpenWindows" type, the user
# won't be aware of this, and it will appear to just be a list of files.  In
# other words, "fromOpenWindows" only indicates how the initial list is
# formed, and nothing else.
# 

namespace eval fileset::fromOpenWindows {}

proc fileset::fromOpenWindows::create {{name ""}} {
    global gfileSets gfileSetsType
    
    if {![string length $name]} {
	set name [prompt "Create fileset containing current\
	  windows under what name?" "OpenWins"]
    }
    if {![string length $name]} {
	status::msg "Cancelled -- no text was entered."
	return
    }
    
    set names {}
    foreach f [winNames -f] {
	lappend names [win::StripCount $f]
    }
    set gfileSets($name) $names
    set gfileSetsType($name) "list"

    return $name
}

proc fileset::fromOpenWindows::setDetails {name args} {
    
    global gfileSets fileSetsExtra
    
    set gfileSets($name) [lindex $args 0]
    set fileSetsExtra($name) "created"
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "fileset::fromOpenWindows::getDialogItems" --
 # 
 # We allow the user to modify the list of files in this set by adding a
 # "filepaths" item to the edit dialog.  When this is called the first time,
 # i.e. when the fileset is being created, we create the initial list based
 # upon active windows that exist as files.  We then add a "created" item in
 # the "fileSetsExtra" array so that we know when the list has already been
 # created and saved; otherwise we would be building it from the current list
 # of active windows whenever the user edits the fileset.
 # 
 # --------------------------------------------------------------------------
 ##

proc fileset::fromOpenWindows::getDialogItems {name} {
    
    global gfileSets fileSetsExtra
    
    if {[info exists fileSetsExtra($name)] \
      && ($fileSetsExtra($name) eq "created")} {
	set fileList $gfileSets($name)
    } else {
	set fileList [list]
	foreach window [winNames -f] {
	    if {[win::IsFile $window fileName]} {
	        lappend fileList $fileName
	    }
	}
	if {![llength $fileList]} {
	    error "Cancelled -- there are no open windows that exist as files."
	}
	set gfileSets($name) $fileList
	set fileSetsExtra($name) "created"
    }
    return [list [list [list "smallval" "filepaths"] \
      "'Manual' List of File Paths" $gfileSets($name)]]
}

proc fileset::fromOpenWindows::updateContents {name {andMenu 0}} {
     if {$andMenu} {
	set menu [list]
	foreach m [getFilesInSet $name] {
	    lappend menu "[file tail $m]&"
	}
	return [filesetMenu::makeSub $name $name fileset::openItemProc \
	  [lsort -increasing $menu]]
     } else {
	return [list]
     }
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× File Path Filesets ×××× #
# 
# Allow the user to create a list of files for a fileset.  Once the list has
# been created, the user can modify it at any time.
# 

namespace eval fileset::fromFileList {}

proc fileset::fromFileList::create {{name ""}} {
    
    global gfileSets gfileSetsType
    
    while {![string length $name]} {
	set p "New \"file paths\" fileset name:"
	set name [string trim [prompt -p $name]]
	if {($name eq "")} {
	    alertnote "The name cannot be an empty string!"
	}
    }
    set filePaths [list]
    set newPath   ""
    while {1} {
        set p "Select a file path to add:"
	if {![catch {getfile $p $newPath} newPath]} {
	    break
	}
	lappend filePaths $newPath
	if {[askyesno "Would you like to add another path?"]} {
	    continue
	} else {
	    break
	}
    }
    if {![llength $filePaths]} {
        error "Cancelled -- no paths were added."
    }
    set gfileSets($name) $filePaths
    set gfileSetsType($name) "list"
    return $name
}

proc fileset::fromFileList::setDetails {name args} {
    
    global gfileSets
    
    set gfileSets($name) [lindex $args 0]
    return
}

proc fileset::fromFileList::getDialogItems {name} {
    
    global gfileSets
    
    return [list [list [list "smallval" "filepaths"] \
      "'Manual' List of File Paths" $gfileSets($name)]]
}

proc fileset::fromFileList::updateContents {name {andMenu 0}} {
    
     if {$andMenu} {
	set menuItems [list]
	foreach filePath [getFilesInSet $name] {
	    lappend menuItems "[file tail $filePath]&"
	}
	return [filesetMenu::makeSub $name $name fileset::openItemProc \
	  [lsort -increasing $menuItems]]
     } else {
	return [list]
     }
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Procedural Filesets ×××× #
# 

namespace eval fileset::procedural {}

proc fileset::procedural::create {{name ""} {p ""}} {
    global gfileSets gfileSetsType filesetsNotInMenu
    if {![string length $name]} {
	set name [prompt "Name for this filesetÉ" ""]
    }
    if {![string length $name]} {
	status::msg "Cancelled -- no text was entered."
	return
    }
    set gfileSetsType($name) "procedural"
    if {$p == ""} {
	set p procFileset[join $name ""]
	prefs::addGlobalPrefsLine "\# procedure to list files in fileset\
	  '$name' on the fly"
	prefs::addGlobalPrefsLine "proc $p \{\} \{"
	prefs::addGlobalPrefsLine "\t"
	prefs::addGlobalPrefsLine "\}"
	if {![dialog::yesno -y "Continue" -n "Edit prefs.tcl now"\
	  "A template for the procedure has been added\
	  to your \"prefs.tcl\" file. You can edit it by selecting the \
	  \"Config > Preferences > Edit Prefs File\" menu command."]} {
	    prefs::editPrefsFile
	    goto [maxPos]
	    beep
	    status::msg "Make sure you 'load' the new procedure."
	}
    }
    set gfileSets($name) $p
    lappend filesetsNotInMenu $name
    return $name
}

# Return empty menu.
proc fileset::procedural::updateContents {name {andMenu 0}} {
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Procedural Fileset Listings ×××× #
# 

namespace eval fileset {}

proc fileset::listOpenWindowsFiles {} { 
    set res {}
    foreach f [winNames -f] {
	lappend res [win::StripCount $f]
    }
    return $res
}

proc fileset::listWindowHierarchyFiles {} {
    global filesetmodeVars
    foreach f [winNames -f] {
	set fn [win::StripCount $f]
	if {[file exists $fn]} {
	    return [file::recurse [file dirname $fn] * \
	      $filesetmodeVars(includeHiddenFilesInBuiltInFilesets)]
	}
    }
    return ""
}

proc fileset::listWindowDirectoryFiles {} {
    global filesetmodeVars
    foreach f [winNames -f] {
	set fn [win::StripCount $f]
	if {[file exists $fn]} {
	    set dir [file dirname $fn]
	    set l1 [glob -nocomplain -dir $dir *]
	    if {$filesetmodeVars(includeHiddenFilesInBuiltInFilesets)} {
		set l2 [glob -nocomplain -dir $dir -types hidden *]
	    } else {
		set l2 {}
	    }
	    return [concat $l1 $l2]
	}
    }
    return ""
}

proc fileset::listRecurseDirectoryFiles {} {
    global filesetmodeVars
    return [file::recurse [get_directory -p "Search recursively\
      in which folder?"] * $filesetmodeVars(includeHiddenFilesInBuiltInFilesets)]
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Back Compatibility ×××× #
# 

proc procFilesetOpenWindows {args} {
    return [eval fileset::listOpenWindowsFiles $args]
}

proc procFilesetDirTopWin {args} {
    return [eval fileset::listWindowDirectoryFiles $args]
}

proc procFilesetHierarchyTopWin {args} {
    return [eval fileset::listWindowHierarchyFiles $args]
}

proc procFilesetRecurseIn {args} {
    return [eval fileset::listRecurseDirectoryFiles $args]
}

proc getFilesetDirectoryAndPattern {args} {
    return [eval fileset::getDirAndPattern $args]
}

# ===========================================================================
# 
# .