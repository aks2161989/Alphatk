## -*-Tcl-*- (nowrap)
## 
 # This file : filtersMenu.tcl
 # Created : 2000-04-03 14:00:56
 # Last modification : 2006-01-02 09:41:15
 # Author : Bernard Desgraupes
 # e-mail : <bdesgraupes@easyconnect.fr>
 # Web-page : <http://webperso.easyconnect.fr/bdesgraupes/alpha.html>
 # Description :
 #      This is a menu/feature for Alpha. It allows you to do, in one run
 #      and very quickly, multiple and successive "find and replace"
 #      operations. These series of operations are stored in files called
 #      filters. You can easily create your own filters. There can be as
 #      many as you wish different "find and replace" instructions in a
 #      filter. The filters can be applied to a selection, a file or an
 #      entire folder.
 # 
 #      See the doc in the Filters Help (it is accessible via the Help menu
 #      once the package is installed).
 # 
 # (c) Copyright : Bernard Desgraupes 2000-2006
 # This is free software. See licensing terms in the Filters Help file.
 ##

alpha::menu filtersMenu 2.1 global "¥301" {
    # Initialization script.
    set flt_p(ext) ".flt"
    addMode [list Fltr Filter] filtersMenuTcl [list *$flt_p(ext) "\\* Temporary Filter \\*" ] {}
    alpha::internalModes "Fltr" "Filter"
    package::addPrefsDialog filtersMenu
    alpha::package require Alpha 8.0b12
} {
    filtersMenuTcl
    set names [list applyFilterToSelection applyFilterToWindow applyMultiToSelection \
      applyMultiToWindow applyTempToSelection applyTempToWindow]
    foreach i $names {
	hook::register requireOpenWindowsHook [list "¥301" $i] 1
    }
    unset i names
    hook::register requireOpenWindowsHook [list filtersUtilities checkSyntax] 1
} {
    set names [list applyFilterToSelection applyFilterToWindow applyMultiToSelection \
      applyMultiToWindow applyTempToSelection applyTempToWindow]
    foreach i $names {
	hook::deregister requireOpenWindowsHook [list "¥301" $i] 1
    }
    unset i names
    hook::deregister requireOpenWindowsHook [list filtersUtilities checkSyntax] 1
} uninstall {
    file delete -force [file join $HOME Tcl Menus "Filters Menu"]
    file delete [file join $HOME Help "Filters Help"]
} maintainer {
    "Bernard Desgraupes" <bdesgraupes@easyconnect.fr> <http://webperso.easyconnect.fr/bdesgraupes/> 
} description {
    Performs successive <Search And Replace> operations
}  help {file "Filters Help"}

proc filtersMenu.tcl {} {}

namespace eval flt {}

# # # Filters menu preferences # # #

# Max number of errors allowed when checking filter's syntax.
# Will stop checking if more.
newPref variable maxNumbErr 15 filtersMenu
# When applying filters to a selection, it is faster to use a scrap window.
# But for a short selection, you could prefer the filtering to be applied directly.
# Define here what is a "short" selection.
newPref variable maxBeforeScrap 70 filtersMenu
# Max number of nested filters called with !!includefilter or !!inputfilter.
newPref variable maxIncludeDepth 2 filtersMenu
# Sets the depth of nested subfolders to visit when applying a filter to 
# a folder. 0 means don't recurse in subfolders, -1 means unlimited depth.
newPref variable filteringDepth 0 filtersMenu
# To warn, before applying a filter to a whole file,
# that it is a non-undoable action.
newPref flag warnNotUndoable 1 filtersMenu
# To display a short description of the filters syntax in the Temporary Filter and
# in new filters.
newPref flag showFilterSyntax 1 filtersMenu

# Remove obsolete flag
prefs::removeObsolete filtersMenumodeVars(ToggleSupSearch)

# Create a folder for the filters if it does not exist already.
# It is located in Alpha Ä:Tcl:Menus:Filters Menu:
if {![file exists [file join $HOME Tcl Menus "Filters Menu" Filters]]} {
    file mkdir [file join $HOME Tcl Menus "Filters Menu" Filters]
}

# # # Preferences for the Fltr mode # # #
# Fltr mode is defined internally to allow specific features for the filter files, 
# such as coloring of comments, proper handling of the comment/uncomment procs,  
# option-click on title bar... 
# There is no reason to change the following prefs which are most standard.

prefs::removeObsolete FltrmodeVars(electricTab)

newPref v lineWrap {0} Fltr
newPref v leftFillColumn {0} Fltr
newPref v fillColumn {75} Fltr
newPref v prefixString {!! } Fltr
newPref v wordBreak {\w+} Fltr
# Default color for the comments in the filters:
newPref v commentColor red Fltr

regModeKeywords -e {!!} -c $FltrmodeVars(commentColor) Fltr {}


# # # Initialisation of some variables # # #
# # flt_p = filter parameters array
set flt_p(currentname) ""
set flt_p(currfileset) ""
set flt_p(currwinpos) ""
set flt_p(debug) 0
set flt_p(filteringDepth) $filtersMenumodeVars(filteringDepth)

# Path to the writeable Filters folder. This is the folder in which new 
# filters can be added.
if {($SUPPORT(user) ne "")} {
	set flt_p(workfolder) [file join $SUPPORT(user) Filters]
} else {
	set flt_p(workfolder) "[file join $HOME Tcl Menus "Filters Menu" Filters]"
}

# Path to the allowable locations containing a Filters folder. The order is
# important because it determines the order in which filters are searched.
# The first match wins: this means for instance that a user defined filter
# (found in ~/Library/Application Support/AlphaX) will override a filter
# installed in /Library/Application Support/AlphaX.
#   1- ~/Library/Application Support/AlphaX/Filters
#   2- /Library/Application Support/AlphaX/Filters (if it exists)
#   3- $HOME/Tcl/Menus/Filters Menu/Filters
set flt_p(searchpath) ""
foreach domain [list user local] {
	if {($SUPPORT($domain) ne "")} {
		set p [file join $SUPPORT($domain) Filters]
		lappend flt_p(searchpath) $p
		# Create the folder if necessary
		if {![file exists $p]} {
			catch {file mkdir $p}
		} 
	} 
} 
lappend flt_p(searchpath) [file join $HOME Tcl Menus "Filters Menu" Filters]

# Build the list of all the filters names
proc flt::getFiltersList {} {
	global flt_p
	set flt_p(names) ""
	foreach path $flt_p(searchpath) {
		foreach f [glob -nocomplain -tail -dir $path *$flt_p(ext)] {
			lappend flt_p(names) [file rootname $f]
		} 
	} 
	set flt_p(names) [lsort -unique -dictionary $flt_p(names)]
}

flt::getFiltersList

# Initialise the list of filters contained in the multi filter
set flt_p(multilist) ""

# Temporary Filter
# ----------------
# The file containing the temporary filter is located in
# $PREFS/tmp/filters_menu. It is written to the disk but deleted and
# recreated each time Alpha quits.
set flt_p(tempname) "* Temporary Filter *"
set flt_p(tempfile) [temp::nonunique filters_menu $flt_p(tempname)]


# Name of the window containing the results of a syntax checking
set flt_p(checkwin) "* Filters Syntax Checking *"

# Name of the window displaying the syntax for filters
set flt_p(syntaxwin) "* Filters Syntax *"

# Name of the scrap window used for fast filtering of a selection
set flt_p(scrapwin) "* Filters Scrap Window *"

# Variable to avoid the "not undoable" warning to be displayed repeatedly when using a multifilter
set flt_p(firstapplied) 0


# The regexp describing include statements
set flt_p(includeregex) "^!!(inputfilter|includefilter)\[ \t\]+\"?(\[^\"\n\r\]+)\"?\[ \t\]*"

# Explanation of the filters' syntax to be inserted, as a reminder, at the beginning of every new filter
# and in the Temporary Filter. There is a preference to prevent this message.
set flt_p(usage) "searchString    replacementString    \[option\]"

set flt_p(syntax) "!! SYNTAX : 
!!  $flt_p(usage)
!!    where the three arguments are separated by one or more tabulations.
!!    The option is a (possibly empty) string containing 0 or 1 and/or
!!    one of the letters i and m with the following signification :
!!        0 (or nothing) for an ordinary textual search (default)
!!        1 for a search with regular expressions
!!        i for a case insensitive search
!!        m to match words exactly (not a substring of a word)
!!    The options can be combined in any order : 0m, im1, i, 0m etc.
!!    Put as many of these instructions as you want in your filter. Each
!!    filtering instruction must be on a single line.
!!    A line starting with two exclamation signs is considered a comment
!!    and not a filtering instruction. If the two exclamation points are
!!    immediately followed by the word includefilter (or inputfilter) and
!!    the name of a filter (possibly enclosed in double quotes), the
!!    instructions found in this filter will be loaded and executed:
!!       !!inputfilter  \"name_of_filter\"
"

# For the Fltr mode :
set Fltr::commentCharacters(General) "!! "
set Fltr::commentCharacters(Paragraph) [list "!!!! " "!!!!" "!! "]
    
proc filtersMenuTcl {} {}


# # # Menu declarations # # #

menu::buildProc filtersMenu menu::buildfiltersMenu
menu::buildProc filtersUtilities menu::buildFiltersUtilities


# # # Building procedures # # #

proc menu::buildfiltersMenu {} {
    global filtersMenu flt_p
    set ma ""
    lappend ma "<E<SpickAFilterÉ"
    lappend ma "<S<IbuildAMultiFilterÉ"
    lappend ma "(-"
    lappend ma "<E<SapplyFilterToSelection"
    lappend ma "<S<IapplyMultiToSelection"
    lappend ma "<E<SapplyFilterToWindow"
    lappend ma "<S<IapplyMultiToWindow"
    lappend ma "<E<SapplyFilterToFilesetÉ"
    lappend ma "<S<IapplyMultiToFilesetÉ"
    lappend ma "<E<SapplyFilterToFolderÉ"
    lappend ma "<S<IapplyMultiToFolderÉ"
    lappend ma "(-"
    lappend ma "temporaryFilter"
    lappend ma "(-"
    lappend ma "applyTempToSelection"
    lappend ma "applyTempToWindow"
    lappend ma "applyTempToFilesetÉ"
    lappend ma "applyTempToFolderÉ"
    lappend ma "(-"
    lappend ma [list Menu -n filtersUtilities {}]
    lappend ma "(-"
    if {$flt_p(currentname) != ""} {
	set flt_p(currentname) [file tail $flt_p(currentname)]
	if {$alpha::macos==2} {
	    lappend ma [menu::itemWithIcon "!\x1f<IcurrentFilter" 83] 
	} else {
	    lappend ma [menu::itemWithIcon "currentFilter" 83] 
	}
	lappend ma " $flt_p(currentname)&"
    } else {
	if {$alpha::macos==2} {
	    lappend ma [menu::itemWithIcon "!\x1f<InoFilterSelected" 82] 
	} else {
	    lappend ma [menu::itemWithIcon "noFilterSelected" 82] 
	}
    }	
    
    return [list build $ma flt::MenuProc {filtersUtilities} $filtersMenu]
}


proc menu::buildFiltersUtilities {} {
    global flt_p
    set ma ""
    lappend ma "<E<SnewFilter"
    lappend ma "<S<InewMultiFilter"
    lappend ma "<E<SeditAFilterÉ"
    lappend ma "<S<IeditCurrentFilter"
    lappend ma "<S<BeditMultiFilter"
    lappend ma "<S<UshowMultiFilter"
    lappend ma "<E<SdeleteAFilterÉ"
    lappend ma "<S<IclearMultiFilter"
    lappend ma "checkSyntax"
    lappend ma "(-"
    lappend ma "filteringDepthÉ"
    lappend ma "<E<SfiltersBindings"
    lappend ma "<S<IrevealFiltersFolder" 
    lappend ma "filtersTutorial"
    lappend ma "displaySyntax"
    lappend ma "(-"
    lappend ma "filtersPreferencesÉ"
    
    return [list build $ma flt::UtilsProc {}]
}


# # # Menu items procs # # #
proc flt::MenuProc {menu item} {
	global flt_p 
	if {[regexp "apply(\\w*)To(\\w+)" $item dum type object]} {
		eval flt::apply${type}Proc $object
	} else {
		switch -- $item {
			"pickAFilter" - "buildAMultiFilter" - 
			"temporaryFilter" - "currentFilter" {eval flt::$item}
			"noFilterSelected" {flt::currentFilter}
			default {
				# If this is the current filter's name, edit it.
				if {[string trim [string tolower $item]] == \
				  [string trim [string tolower $flt_p(currentname)]]} {
					alertnote "'$flt_p(currentname)'\
					  is currently selected. You can apply it to the current window,\
					  to a selection, to a fileset or to a folder. To edit it,\
					  choose \"Edit a filter\" in the Filters Utilities submenu."
					return
				}
				# Still here?
				error "Cancelled -- unknown menu item: '$item'"
			}
		}
	}
}


proc flt::UtilsProc {menu item} {
	global flt_p
	set item [string trimright $item "."]
	switch -- $item {
		"newMultiFilter" {flt::buildAMultiFilter}
		"filtersTutorial" {help::openExample "Filters Example"}
		"revealFiltersFolder" {file::showInFinder $flt_p(workfolder)}
		"filtersPreferences" {prefs::dialogs::packagePrefs filtersMenu}
		"editAFilter" {flt::doFilterAction edit}
		"deleteAFilter" {flt::doFilterAction delete}
		default {eval flt::$item}
	}
}

	
# # # Building the menu # # #

menu::buildSome filtersMenu 


# # # Filters manipulation procs # # #

proc flt::pickAFilter {} {
	global flt_p
	flt::getFiltersList
	if {[llength $flt_p(names)] == 0} {
		alertnote "No filters were found"
		return
	} else {
		if {![catch {listpick -p "Select a filter" $flt_p(names)} filt]} {
			set flt_p(currentname) $filt
			menu::buildSome filtersMenu
		} 
	}
}


proc flt::newFilter {} {
	global flt_p filtersMenumodeVars
	if {[catch {prompt "Name of the new filter (without extension)." NewFilter} fltname]} {return} 
	set newfilter [file join $flt_p(workfolder) ${fltname}$flt_p(ext)]
	# Create the file on disk
	set fileId [alphaOpen $newfilter w+] 
	close $fileId
	# Edit it
	if {[file exists $newfilter]} {
		edit -c $newfilter
	} else {
		alertnote "Couldn't create $newfilter"
		return
	}
	# Insert a preamble
	set date [ISOTime::ISODateAndTimeRelaxed]
	set t "!! Filter: ${fltname}$flt_p(ext)\r"
	append t "!! Created: $date\r"	
	append t "!! Description: \r!! \r\r"
	insertText $t
	if {$filtersMenumodeVars(showFilterSyntax)} {
		insertText $flt_p(syntax)
	}
	# The new filter becomes the current one. Update the menu accordingly.
	lunion flt_p(names) $fltname
	set flt_p(currentname) $fltname
	menu::buildSome filtersMenu
	win::ChangeMode Fltr
}


proc flt::isFilterSelected {} {
	global flt_p
	if {$flt_p(currentname) == "" } {
		alertnote "No filter currently selected. Use the \"Pick a filter\" menu item."
		return 0
	} else {
		return 1
	}
}


proc flt::filterExists {name} {
	global flt_p
	if {[lsearch -exact $flt_p(names) $name]=="-1" && $name!=$flt_p(tempname)} {
	  return 0  
	} 
	return 1
}


# This is the search proc to find a filter's file. It returns the first one
# found on the search path.
proc flt::pathToFilter {filtername} {
	global flt_p
	set result ""
	if {$filtername eq $flt_p(tempname)} {
		return $flt_p(tempfile)
	} else {
		foreach path $flt_p(searchpath) {
			set f [file join $path $filtername$flt_p(ext)]
			if {[file exists $f]} {
				set result $f
				break
			} 
		} 
	}
	return $result
}


##########    Key bindings   ############
# The following instructions install easy to remember keybindings "ˆ la emacs".
#  For all of them you have to hit 'ctrl-f', release, then hit one of the following letters:
#   'b'  to show the <b>indings
#   'c'  to <c>heck the filter's syntax
#   'd'  to apply filter to a fol<d>er (or <d>irectory)
#   'e'  to <e>dit a filter
#   'f'  to apply filter to a <f>ileset
#   'm'  to build a <m>ultifilter
#   'n'  to create a <n>ew filter
#   'p'  to <p>ick a filter
#   's'  to apply filter to a <s>election
#   't'  to call up the <t>emporary filter
#   'w'  to apply filter to the current <w>indow

# Now if you add the control key with letters d, e, f, s, w you  get  the
# equivalent with Multifilter instead of Filter. For instance 'ctrl-f ctrl-s'
# is equivalent to "Apply Multifilter to the Selection".
# 
# There are four more key bindings to use the Temporary  Filter.  First  hit
# 'ctrl-t', release, then hit one of the letters d, f,  s,  w  to  apply  the
# temporary filter to a <d>irectory, to a <f>ileset, to a <s>election, to the
# current <w>indow respectively.

Bind 'f' <z> prefixChar 
Bind 't' <z> prefixChar 
Bind 'b' <F> {flt::filtersBindings}
Bind 'c' <F> {flt::checkSyntax}
Bind 'c' <sF> {flt::clearMultiFilter}
Bind 'd' <F> {flt::MenuProc "filtersMenu" "applyFilterToFolder"}
Bind 'd' <T> {flt::MenuProc "filtersMenu" "applyTempToFolder"}
Bind 'd' <sF> {flt::MenuProc "filtersMenu" "applyMultiToFolder"}
Bind 'e' <F> {flt::doFilterAction edit}
Bind 'e' <oF> {flt::editCurrentFilter}
Bind 'e' <sF> {flt::editMultiFilter}
Bind 'f' <F> {flt::MenuProc "filtersMenu" "applyFilterToFileset"}
Bind 'f' <T> {flt::MenuProc "filtersMenu" "applyTempToFileset"}
Bind 'f' <sF> {flt::MenuProc "filtersMenu" "applyMultiToFileset"}
Bind 'w' <F> {flt::MenuProc "filtersMenu" "applyFilterToWindow"}
Bind 'w' <T> {flt::MenuProc "filtersMenu" "applyTempToWindow"}
Bind 'w' <sF> {flt::MenuProc "filtersMenu" "applyMultiToWindow"}
Bind 'h' <F> {flt::displaySyntax}
Bind 'm' <F> {flt::buildAMultiFilter}
Bind 'n' <F> {flt::newFilter}
Bind 'p' <F> {flt::pickAFilter}
Bind 's' <F> {flt::MenuProc "filtersMenu" "applyFilterToSelection"}
Bind 's' <T> {flt::MenuProc "filtersMenu" "applyTempToSelection"}
Bind 's' <sF> {flt::MenuProc "filtersMenu" "applyMultiToSelection"}
Bind 't' <F> {flt::temporaryFilter}

# # # # # Abbreviations # # # # #
set Fltrelectrics(!!in)   "putfilter ¥¥"
set Fltrelectrics(!!inc)   "ludefilter ¥¥"


##########   Option-click on title bar   ############
# If you Option-Click on a the title bar of a filter, you get a list  of  all
# the filters stored in the  "Menus:Filters Menu:Filters:"  folder.  Selecting
# any item will open it in a window or bring its window to  front  if  it  is
# already open, and will make it the current filter as shown at the bottom of
# the Filters menu.

namespace eval Fltr {}

proc Fltr::OptionTitlebar {} {
    global flt_p 
    return $flt_p(names)
}

proc Fltr::OptionTitlebarSelect {item} {
    global flt_p
    if {[file exists [file join [file dirname [win::Current]] "$item$flt_p(ext)"]]} {
		edit -c [file join [file dirname [win::Current]] "$item$flt_p(ext)"]
    } else {
		edit -c [flt::pathToFilter $item]
    }
    set flt_p(currentname) $item
    menu::buildSome filtersMenu
    win::ChangeMode Fltr
}


##########    The "M" menu   ############

proc Fltr::MarkFile {args} {
    win::parseArgs win
    setNamedMark -w $win "go to top" \
      [minPos -w $win] [minPos -w $win] [minPos -w $win]
    setNamedMark -w $win "go to bottom" \
      [maxPos -w $win] [maxPos -w $win] [maxPos -w $win]
}


##########    The "{}" pop-up menu   ############
# The "{}" pop-up menu gives a count of the instruction lines and of
# the comments in a filter file.
proc Fltr::parseFuncs {} {
    set pos [minPos]
    set m 0
    while {[set res [search -s -f 1 -r 1 -n "^!!" $pos]] != ""} {
	incr m
	set pos [lindex $res 1]
    }
    set pos [minPos]
    set l 0
    while {[set res [search -s -f 1 -r 1 -n "^\[^\r\]+$" $pos]] != ""} {
	incr l
	set pos [lindex $res 1]
    }
    return [list "[expr $l-$m] instructions" "" "$m comments" ""]
}
