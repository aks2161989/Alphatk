## -*-Tcl-*- (install)
 # ###################################################################
 #	Vince's	Additions -	an extension package for Alpha
 # 
 #	FILE: "modeSearchPaths.tcl"
 #					created: 3/12/96 {6:35:25 pm}	
 #				  last update: 02/21/2006 {06:47:36 PM}	
 #	Author:	Vince Darley
 #	E-mail:	<vince@santafe.edu>
 #	  mail:	317 Paseo de Peralta
 #           Santa Fe, NM 87501, USA
 #	   www:	<http://www.santafe.edu/~vince/>
 #	
 # Copyright (c) 1997-2006  Vince Darley.
 # 
 # Distributed under a Tcl style license.  This package is not
 # actively improved any more, so if you wish to make improvements,
 # feel free to take it over.
 # 
 # ###################################################################
 ##

alpha::extension searchPaths 1.2.6 {
    menu::insert mode items end \
      "(-" "viewSearchPath" "appendSearchPathsÉ" "removeSearchPathsÉ"
    # key-binding to find and open file with selected name
    newPref binding openSelection "<O<B/H" searchPaths
    # key-binding to toggle from source to header file (or vice-versa)
    newPref binding sourceHeaderToggle "<O/f" searchPaths
    menu::insert winUtils items end \
      "[menu::bind searchPathsmodeVars(sourceHeaderToggle) -]" \
      "[menu::bind searchPathsmodeVars(openSelection) -]"
    package::addPrefsDialog searchPaths
    # make sure we've loaded the old version of this proc
    auto_load file::tryToOpen

    # ×××× Try to open the given name or selection ×××× #
    proc file::tryToOpen {{fname ""}} {
	if {$fname == ""} {set fname [getSelect]}
	if {![catch {file::_tryToOpen $fname ""}]} {
	    return
	}
	global headerSuffices sourceSuffices
	if { [file extension ${fname}] == "" } {
	    if {![catch {file::_tryToOpen $fname $headerSuffices}]} {
		return
	    }
	    if {![catch {file::_tryToOpen $fname $sourceSuffices}]} {
		return
	    }
	}
	if {[askyesno "'$fname' can not be found, do you wish to add an include path?"]} {
	    mode::appendSearchPath [get_directory]
	    mode::modifySearchPath
	    return [file::tryToOpen $fname]
	}
	error "Couldn't find anything"
    }
} uninstall {
    this-file
} maintainer {
    "Vince Darley" <vince@santafe.edu> <http://www.santafe.edu/~vince/>
} description {
    This package over-rides the default "Option Title-Bar Click" routines,
    allowing them to search more widely, and provides general procedures to
    find files from mode-specific lists of paths
} help {
    This package over-rides the default "Option Title-Bar Click" routines,
    allowing them to search more widely, and provides general procedures to
    find files from mode-specific lists of paths.  It also handles a new
    'include paths' section of the 'Config > Mode Prefs' menu.
    
    Preferences: Features

    By default the shortcut Control-Command-H is bound to "Open Selection" and
    Command-F2 is bound to "Source Header Toggle".  To change these shortcuts,
    select "Config > Preferences > Packages Preferences > Search Path Prefs".
    
    Preferences: searchPaths
	
    This code also allows AlphaTcl package developers to handle the creation
    and manipulation of a "Search Paths" menu.  You have to attach the menu to
    a given mode's menu -- See the "Java Example.java" example for an
    illustration.  The "modeSearchPaths.tcl" source file has more information.
}

proc modeSearchPaths.tcl {} {}

namespace eval global {}

proc global::searchPathPrefs {} {
    global mode searchPathsmodeVars
    if {$mode != ""} {
	set searchPathsmodeVars(${mode}ModeSearchPath) [mode::getSearchPath]
	prefs::dialogs::packagePrefs searchPaths
	if {[set searchPathsmodeVars(${mode}ModeSearchPath)] != [mode::getSearchPath]} {
	    mode::setSearchPath [set searchPathsmodeVars(${mode}ModeSearchPath)]
	}
	unset searchPathsmodeVars(${mode}ModeSearchPath)
	mode::modifySearchPath
    } else {
	prefs::dialogs::packagePrefs searchPaths
    }
}

# ×××× Include paths ×××× #

#################################################################
#																#
#  Only _ever_ access include paths through these 4 functions.  #
#																#
#################################################################

namespace eval mode {}

proc mode::getSearchPath {{m ""}} {
    if {$m == ""} {
	global mode
	if {$mode eq ""} {
	    status::msg "No mode currently active"
	    return
	} 
	set m $mode
    }
    global ${m}SearchPath
    if {[info exists ${m}SearchPath]} {
	return [set ${m}SearchPath]
    } else {
	return ""
    }
}

proc mode::setSearchPath {path} {
    global mode 
    global ${mode}SearchPath
    set ${mode}SearchPath $path
}

proc mode::removeSearchPath {path} {
    global mode 
    global ${mode}SearchPath
    if {[info exists ${mode}SearchPath]} {
	set res [lsearch -exact [set ${mode}SearchPath] $path]
	if {$res != -1} {
	    set ${mode}SearchPath [lreplace [set ${mode}SearchPath] $res $res]
	}
    }
}

proc mode::appendSearchPath {path} {
    global mode 
    global ${mode}SearchPath
    if {$mode eq ""} {
        status::msg "No mode currently active: can't append path"
	return
    } 
    if {![info exists ${mode}SearchPath] \
      || [lsearch -exact [set ${mode}SearchPath] $path] == -1} {
	lappend ${mode}SearchPath $path
    }
}

# Now we have the functions which manipulate include paths and menus

proc mode::modifySearchPath {} {
    global mode 
    if {![catch {mode::getSearchPath} include]} {
	prefs::modified ${mode}SearchPath
    }
    mode::rebuildSearchPathMenu
}

proc mode::rebuildSearchPathMenu {{name ""}} {
    global mode
    global ${mode}modeVars ${mode}SearchPathMenu
    if {[info exists ${mode}modeVars(includeMenu)] \
      && [set ${mode}modeVars(includeMenu)]} {
	if {$name == ""} {
	    if {[info exists ${mode}SearchPathMenu]} {
		set name [set ${mode}SearchPathMenu]
	    } else {
		set name headers
	    }
	} else {
	    set ${mode}SearchPathMenu $name
	}
	set paths {}
	foreach p [mode::getSearchPath] {
	    lappend paths "[dialog::specialView::file $p]&"
	}
	Menu -n $name -p mode::includeProc -m [concat {
	    "Open"
	    "Add FolderÉ"
	    "Remove FolderÉ"
	    "(-"
	} $paths]
    }
}

proc mode::checkSearchPath {} {
    set	bad 0
    if {[catch {mode::getSearchPath}]} {return [mode::appendSearchPaths]}
    set	newInc {}
    foreach p [mode::getSearchPath] {
	if {![file exists $p]} {
	    set	bad 1
	} else {
	    lappend newInc $p
	}
    }
    if {$bad} {
	mode::setSearchPath $newInc
	mode::modifySearchPath
    }
    return $newInc
}

# Now the functions the user sees

proc mode::viewSearchPath {} {
    global mode
    listpick -p "Include paths for '$mode' mode:" [mode::getSearchPath]
}

proc mode::removeSearchPaths {} {
    global mode
    set remove [listpick -p "Remove which items from '$mode' mode's search path:" -l [mode::getSearchPath]]
    foreach r $remove {
	mode::removeSearchPath $r
    }
    mode::modifySearchPath
}

proc mode::appendSearchPaths {} {
    if {[catch {mode::getSearchPath}]} {
	mode::setSearchPath {}
    }
    mode::appendSearchPath [get_directory -p \
      "Choose a search path folder:"]
    while {![catch {get_directory -p \
      "Choose another, or cancel:"} path]} {
	mode::appendSearchPath $path
	mode::viewSearchPath
    }
    mode::modifySearchPath
}

proc mode::includeProc {menu item} {
    switch -- $item {
	"Open"	{
	    set text [getText [lineStart [getPos]] [nextLineStart [getPos]]]
	    if {[regexp {["<]([^">]*)[">]} $text dummy fname]} {
		file::tryToOpen $fname
	    }
	}
	"Add Folder" { 
	    mode::appendSearchPath [get_directory]
	    mode::modifySearchPath
	}
	"Remove Folder" {
	    mode::removeSearchPath [listpick -p "Remove which folder?" [lsort [mode::getSearchPath]]]
	    mode::modifySearchPath
	}
	default {
	    set i [lsearch -glob [mode::getSearchPath] $item]
	    if {$i != -1} {
		if {[askyesno "Shall I reveal this folder in the finder?"] == "yes"} {
		    file::showInFinder [lindex [mode::getSearchPath] $i]
		}
	    } else {
		alertnote "Sorry, Alpha has a bug which can affect this menu.  I can't find that particular folder."
	    }
	}
	
    }
}

namespace eval file {}

proc file::_tryToOpen {fname suffices} {
    # first try basic open
    if {![catch {file::_tryToOpenIn [list $fname] [list [file dir [win::Current]]] $suffices}]} {
	return
    }
    # now try in mode include path
    if {![catch {file::_tryToOpenIn [list $fname] [mode::getSearchPath] $suffices}]} {
	return
    }
    # now try in common paths
    if {![catch {file::_tryToOpenIn [list $fname] [file::_MakeCommonPaths [file dirname [win::Current]]] $suffices}]} {
	return
    }
    
    error "Couldn't find anything"
}

## 
 # -------------------------------------------------------------------------
 #	 
 #  "file::_MakeCommonPaths" --
 #	
 #  Given a directory make a path of common search possibilities which
 #  could pertain to that directory.  This is done by matching possible
 #  Source/Header directory pairs, and by adding the mode-dependent
 #  'includePath' variable.
 # -------------------------------------------------------------------------
 ##
proc file::_MakeCommonPaths { thisdir } {
    # allow for some common possibilities of separating
    # source and header files
    set path [list $thisdir]
    
    foreach src { Source src source Src } {
	if { [file tail $thisdir] eq $src } {
	    foreach dir { Headers headers Header header } {
		lappend path [file join [file dirname $thisdir] $dir]
	    }
	    break
	}
    }
    
    foreach src { Headers headers Header header } {
	if { [file tail $thisdir] eq $src } {
	    foreach dir { Source src source Src } {
		lappend path [file join [file dirname $thisdir] $dir]
	    }
	    break
	}
    }
    # Try some general substitutions useful if files are stored in
    # 'XXX Sources' and 'XXX Headers' for instance.
    if {[regsub "Source" $thisdir "Header" dir]} {
	lappend path $dir
    }
    if {[regsub "Header" $thisdir "Source" dir]} {
	lappend path $dir
    }
    if {[regsub "source" $thisdir "header" dir]} {
	lappend path $dir
    }
    if {[regsub "header" $thisdir "source" dir]} {
	lappend path $dir
    }
    
    return $path
}


proc file::_tryToOpenIn { filelist path {suffices ""}} {
    set w [win::Current]
    foreach dir $path {
	foreach ff $filelist {
	    if {$suffices != ""} {
		foreach sfx $suffices {
		    if {[file exists [file join $dir $ff$sfx]] && [file join $dir $ff$sfx] != $w} {
			file::openQuietly [file join $dir $ff$sfx]
			return
		    }
		}
	    } else {
		if {[file exists [file join $dir $ff]] && [file join $dir $ff] != $w} {
		    file::openQuietly [file join $dir $ff]
		    return
		}				
	    }
	}
    }
    error "Couldn't find anything"
}

 
## 
 # ----------------------------------------------------------------------
 #	 
 #	"file::sourceHeaderToggle" --
 #	
 #  Toggles the front window back and forth between a header/source
 #  pair.  Requires that "headerSuffices" and "sourceSuffices" be
 #  defined for whatever mode it is used in.
 #	
 #  Side effects:
 #  
 #  A different window is (perhaps opened) and uppermost
 #	
 # ----------------------------------------------------------------------
 ##
proc file::sourceHeaderToggle {} {
    set ff [win::CurrentTail]
    set fbase [file::baseName $ff]
    if {[file::isSource $ff]} {
	global headerSuffices
	file::_tryToOpen ${fbase} $headerSuffices
    } elseif {[file::isHeader $ff]} {
	global sourceSuffices
	file::_tryToOpen ${fbase} $sourceSuffices
    } else {
	# don't recognise this file
	beep
	status::msg "I don't recognise the file extension. Set your 'sourceSuffices' and 'headerSuffices'"
	return
    }
}


## 
 # ----------------------------------------------------------------------
 # 
 #	"openSelection"	--
 # 
 #	 Opens the header file currently selected, or else if that
 #	 fails,	calls file::sourceHeaderToggle.  Each mode can have a variable
 #	 'includePath' defined,	in which this procedure	searches.
 # 
 # ----------------------------------------------------------------------
 ##
proc file::openSelection {} {
    file::tryToOpen
}

# three simple utility procedures

proc file::isHeader { filename {m ""}} {
    if {$m == ""} {
	global headerSuffices
	set var "headerSuffices"
    } else {
	loadAMode $m
	global ${m}modeVars
	set var "${m}modeVars(headerSuffices)"
    }
    return [lcontains $var [file extension $filename]]
} 

proc file::isSource { filename {m ""}} {
    if {$m == ""} {
	global sourceSuffices
	set var "sourceSuffices"
    } else {
	loadAMode $m
	global ${m}modeVars
	set var "${m}modeVars(sourceSuffices)"
    }
    return [lcontains $var [file extension $filename]]
}

proc file::baseName { filename } { return [file root [file tail $filename]] }


