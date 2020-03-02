## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "htmlCaches.tcl"
 #                                    created: 99-07-20 17.52.36 
 #                                last update: 12/08/2004 {05:12:37 PM} 
 #  Author: Johan Linde
 #  E-mail: <alpha_www_tools@go.to>
 #     www: <http://go.to/alpha_www_tools>
 #  
 # Version: 3.2
 # 
 # Copyright 1996-2003 by Johan Linde
 #  
 # This program is free software; you can redistribute it and/or modify
 # it under the terms of the GNU General Public License as published by
 # the Free Software Foundation; either version 2 of the License, or
 # (at your option) any later version.
 # 
 # This program is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 # GNU General Public License for more details.
 # 
 # You should have received a copy of the GNU General Public License
 # along with this program; if not, write to the Free Software
 # Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 # 
 # ###################################################################
 ##

#===============================================================================
# This file contains the procs for the URLs and Targets submenus plus procs
# for general caches.
#===============================================================================

#===============================================================================
# ×××× General caches ×××× #
#===============================================================================

proc html::SaveCache {cache text} {
	global html::PrefsFolder htmlVersion tcl_platform
	file::ensureDirExists ${html::PrefsFolder}
	set fid [open [file join ${html::PrefsFolder} $cache] w]
	if {$tcl_platform(platform) != "macintosh"} {
		fconfigure $fid -encoding macRoman
	}
	if {[info exists htmlVersion]} {puts $fid "#$htmlVersion"} else {puts $fid "#1.0"}
	puts $fid $text
	close $fid
}
  
proc html::ReadCache {cache {level #0}} {
	global html::PrefsFolder htmlVersion
	if {![file exists [file join ${html::PrefsFolder} $cache]]} {error "No cache."}
	set fid [open [file join ${html::PrefsFolder} $cache] r]
	gets $fid version
	if {![regexp {^#[0-9]+\.[0-9]+$} $version] || $version != "#$htmlVersion"} {
		close $fid
		html::DeleteCache $cache
		error "Wrong version."
	}
	close $fid
	eval {uplevel $level [list source [file join ${html::PrefsFolder} $cache]]}
}

proc html::DeleteCache {cache} {
	global html::PrefsFolder
	catch {file delete [file join ${html::PrefsFolder} $cache]}
}
  

#===============================================================================
# ×××× URL and Target Caches ×××× #
#===============================================================================

proc html::BuildAddCacheMenu {cache} {
	return [list build {"No Set"} "html::UtilsMenuItem -m -M HTML" "" "Add New $cache To"]
}

proc html::AddToCacheMark {cache} {
	global HTMLmodeVars	
	markMenuItem -m "Add New $cache To" $HTMLmodeVars(add${cache}To) on
}

proc html::URLsMenuExtra {} {
	html::URLwinMenuExtra URLs URLs URLs addURLsTo
	html::SetsMenuExtra URLs URL URLs activeURLSets
}

proc html::WindowsMenuExtra {} {
	html::URLwinMenuExtra Targets Targets Targets addTargetsTo
	html::SetsMenuExtra Targets Target Targets activeTargetSets
}

proc html::URLwinMenuExtra {folder type meny addto} {
	global HTMLmodeVars
	set sets [html::FindAllSets $folder]
	menu::insert $meny items end [list Menu -p html::UtilsMenuItem -m -M HTML -n "Add New $type To" {}]
	foreach s $sets {
		menu::insert "Add New $type To" items end $s
		
	}
	menu::buildSome "Add New $type To"
	if {![lcontains sets $HTMLmodeVars($addto)]} {
		set HTMLmodeVars($addto) "No Set"
		prefs::modifiedModeVar $addto HTML
	}
}

proc html::URLWinMenuProc {meny item} {
	switch -glob $meny {
		"Add New * To" {html::AddNewToCache $meny $item}
		default {
			switch -glob -- $item {
				"New * Set" {html::NewCacheSet $meny}
				"Delete * Set" {html::DeleteCacheSet $meny}
				"Edit * Set" {html::EditCacheSet $meny}
				"Rename * Set" {html::RenameCacheSet $meny}
				Import {html::Import}
				"Add Folder" {html::AddFolder}
				default {html::ActivateCacheSet $meny $item}
			}
		}
	}
}

proc html::FindAllSets {type} {
	global html::PrefsFolder
	set files [glob -nocomplain -dir [file join ${html::PrefsFolder} $type] *]
	set sets ""
	foreach s $files {
		lappend sets [set s [file tail $s]]
	}
	return $sets
}


proc html::SetsMenuExtra {folder type meny active} {
	global HTMLmodeVars
	set sets [html::FindAllSets $folder]
	if {[llength $sets]} {menu::insert $meny items end "(-"}
	foreach s $sets {
		menu::insert $meny items end "$s"
	}
	if {![llength $sets]} {
		enableMenuItem -m $meny "Delete $type SetÉ" off
		enableMenuItem -m $meny "Edit $type SetÉ" off
		enableMenuItem -m $meny "Rename $type SetÉ" off
		if {$meny == "URLs"} {
			enableMenuItem -m $meny ImportÉ off
			enableMenuItem -m $meny "Add FolderÉ" off
		}
	} else {
		enableMenuItem -m $meny "Delete $type SetÉ" on
		enableMenuItem -m $meny "Edit $type SetÉ" on
		enableMenuItem -m $meny "Rename $type SetÉ" on
		if {$meny == "URLs"} {
			enableMenuItem -m $meny ImportÉ on
			enableMenuItem -m $meny "Add FolderÉ" on
		}
	} 	
	# Make sure active list doesn't contain deleted sets.
	set sets [lremove $HTMLmodeVars($active) $sets]
	if {[llength $sets]} {
		set HTMLmodeVars($active) [lremove $HTMLmodeVars($active) $sets]
		prefs::modifiedModeVar $active HTML
	}
	foreach c $HTMLmodeVars($active) {
		markMenuItem -m $meny $c on
	}
}

proc html::ReadActiveCacheSets {cache} {
	global HTMLmodeVars
	upvar #0 html::User$cache thecache
	html::SaveAllCacheSets $cache
	set active active[string trimright $cache s]Sets
	set s ""
	foreach c $HTMLmodeVars($active) {
		append s " " [html::ReadACacheSet $cache $c]
	}
	set thecache [lsort -unique $s]
}

proc html::ReadACacheSet {cache set} {
	global html::PrefsFolder
	if {[catch {open [file join ${html::PrefsFolder} $cache $set]} fid]} {return}
	set c [read $fid]
	if {[regexp "\n" $c]} {set nl "\n"} else {set nl "\r"}
	set s [split [string trim $c "\r\n"] $nl]
	close $fid
	return [lremove -all -regexp $s [list "^ *$"]]
}

proc html::SaveAllCacheSets {cache} {
	global HTMLmodeVars html::Added$cache
	foreach s [array names html::Added$cache] {
		html::SaveACacheSet $cache $s
	}
}

proc html::SaveACacheSet {cache set} {
	global html::PrefsFolder html::Added$cache
	if {![info exists html::Added${cache}($set)]} {return}
	set s [html::ReadACacheSet $cache $set]
	file::ensureDirExists [file join ${html::PrefsFolder} $cache]
	append s " " [set html::Added${cache}($set)]
	set s [lsort -unique $s]
	set fid [open [file join ${html::PrefsFolder} $cache $set] "w"]
	puts $fid [join $s "\r"]
	close $fid
	unset html::Added${cache}($set)
}

# Adds a URL or window given as input to cache
proc html::AddToCache {cache newurl} {
	global HTMLmodeVars html::Added$cache html::UserURLs html::UserTargets
	if {$HTMLmodeVars(add${cache}To) == "No Set" || ($cache == "Targets" && [lsearch -exact {_self _top _parent _blank} $newurl] >= 0)} {return}
	
	set active active[string trimright $cache s]Sets
	if {[string length $newurl] && ![lcontains html::Added${cache}($HTMLmodeVars(add${cache}To)) $newurl]} { 
		lappend html::Added${cache}($HTMLmodeVars(add${cache}To)) $newurl
		if {[lcontains HTMLmodeVars($active) $HTMLmodeVars(add${cache}To)] && ![lcontains html::User${cache} $newurl]} {
			set html::User${cache} [lsort [lappend html::User${cache} $newurl]]
		}
	}
}

proc html::EditCacheSet {cache} {
	if {![llength [set sets [html::FindAllSets $cache]]]} {return}
	if {[llength $sets] == 1} {
		set cset [lindex $sets 0]
	} elseif {[catch {listpick -p "Select [string trimright $cache s] set to edit." $sets} cset] || \
	  $cset == ""} {
		return
	}
	if {$cache != "Colors"} {
		html::EditACacheSet $cache $cset
	} else {
		html::EditAColorSet $cset
	}
}

proc html::ActivateCacheSet {cache set} {
	global HTMLmodeVars
	set active active[string trimright $cache s]Sets
	if {[set i [lsearch -exact $HTMLmodeVars($active) $set]] >= 0} {
		set HTMLmodeVars($active) [lreplace $HTMLmodeVars($active) $i $i]
		markMenuItem -m $cache $set off
	} else {
		lappend HTMLmodeVars($active) $set
		markMenuItem -m $cache $set on
	}
	prefs::modifiedModeVar $active HTML
	if {$cache != "Colors"} {
		html::ReadActiveCacheSets $cache
	} else {
		html::ReadActiveColorSets
	}
	if {$i >= 0} {
		status::msg "$set deactivated."
	} else {
		status::msg "$set activated."
	}
}

proc html::GiveSetAName {type sing {ignore ""}} {
	
	set sets [string tolower [html::FindAllSets $type]]
	while {1} {
		if {[catch {string trim [prompt "$sing set name" $ignore]} cset]} {return}
		regsub -all "\[[file separator];!</(]" $cset "-" cset
		regsub "^-*" $cset "" cset
		regsub "&*$" $cset "" cset
		if {$cset == ""} {
			alertnote "You must give the $sing set a name."
		} elseif {[lcontains sets [string tolower $cset]] && $cset != $ignore} {
			alertnote "There is already a $sing set with the name '$cset'."
		} else {
			break
		}
	}
	return $cset
}

proc html::NewCacheSet {meny} {
	global html::PrefsFolder
	set cset [html::GiveSetAName $meny [string trimright $meny s]]
	if {$cset == ""} {return}
	file::ensureDirExists [file join ${html::PrefsFolder} $meny]
	close [open [file join ${html::PrefsFolder} $meny $cset] "w"]
	menu::buildSome $meny
	menu::buildSome "Add New $meny To"
	html::ActivateCacheSet $meny $cset
	status::msg "$cset added."
}

proc html::AddNewToCache {meny item} {
	global HTMLmodeVars
	set cache [lindex $meny 2]
	markMenuItem -m "Add New $cache To" $HTMLmodeVars(add${cache}To) off
	set HTMLmodeVars(add${cache}To) $item
	markMenuItem -m "Add New $cache To" $item on
	prefs::modifiedModeVar add${cache}To HTML
	status::msg "New $cache will be added to $item."
}

proc html::TrashCacheSet {cache cset {delete 1}} {
	global HTMLmodeVars html::PrefsFolder
	set active active[string trimright $cache s]Sets
	set HTMLmodeVars($active) [lremove $HTMLmodeVars($active) [list $cset]]
	prefs::modifiedModeVar $active HTML
	if {$delete} {file delete [file join ${html::PrefsFolder} $cache $cset]}
	menu::removeFrom $cache items end "<E<SEdit ${cset}É" "<S$cset"
	if {$cache != "Colors"} {menu::removeFrom "Add New $cache To" items end $cset}
	if {![llength [html::FindAllSets $cache]]} {menu::removeFrom $cache items end "(-"}
}

proc html::DeleteCacheSet {cache} {
	if {![llength [set sets [html::FindAllSets $cache]]]} {return}
	if {[llength $sets] == 1} {
		set cset [lindex $sets 0]
	} elseif {[catch {listpick -p "Select [string trimright $cache s] set to delete." $sets} cset] || \
	  $cset == ""} {
		return
	}
	if {[askyesno "Delete $cset?"] == "no"} {return}
	html::TrashCacheSet $cache $cset
	if {$cache != "Colors"} {
		html::ReadActiveCacheSets $cache
	} else {
		html::ReadActiveColorSets
	}
	status::msg "$cset deleted."
}

proc html::RenameCacheSet {cache} {
	global HTMLmodeVars html::PrefsFolder
	if {![llength [set sets [html::FindAllSets $cache]]]} {return}
	if {[llength $sets] == 1} {
		set cset [lindex $sets 0]
	} elseif {[catch {listpick -p "Select [string trimright $cache s] set to rename." $sets} cset] || \
	  $cset == ""} {
		return
	}
	set active active[string trimright $cache s]Sets
	set isactive [lcontains HTMLmodeVars($active) $cset]
	set newname [html::GiveSetAName $cache [string trimright $cache s] $cset]
	if {$newname == ""} {return}
	file rename [file join ${html::PrefsFolder} $cache $cset] [file join ${html::PrefsFolder} $cache $newname]
	html::TrashCacheSet $cache $cset 0
	if {$isactive} {html::ActivateCacheSet $cache $newname}
}

proc html::EditACacheSet {cache cset} {
	global html::OpenCacheWindows html::PrefsFolder
	html::SaveACacheSet $cache $cset
	hook::register savePostHook html::CacheSetSaveHook
	hook::register closeHook html::CacheSetCloseHook
	edit -c [file join ${html::PrefsFolder} $cache $cset]
	if {![lcontains html::OpenCacheWindows [lindex [winNames -f] 0]]} {lappend html::OpenCacheWindows [lindex [winNames -f] 0]}
}

proc html::CacheSetSaveHook {name} {
	global html::OpenCacheWindows
	if {![lcontains html::OpenCacheWindows $name]} {return}
	html::ReadActiveCacheSets [file tail [file dirname $name]]
}

proc html::CacheSetCloseHook {name} {
	global html::OpenCacheWindows
	if {![lcontains html::OpenCacheWindows $name]} {return}
	set html::OpenCacheWindows [lremove ${html::OpenCacheWindows} [list $name]]
	if {![llength ${html::OpenCacheWindows}]} {
		hook::deregister savePostHook html::CacheSetSaveHook
		hook::deregister closeHook html::CacheSetCloseHook
	}
}

# Imports all URLs in a file to the cache.
proc html::Import {} {
	global HTMLmodeVars html::AddedURLs
	if {![llength [set sets [html::FindAllSets URLs]]]} {return}
	if {[llength $sets] == 1} {
		set cset [lindex $sets 0]
	} elseif {[catch {listpick -p "Select URL set to import to." $sets} cset] || \
	  $cset == ""} {
		return
	}

	if {[catch {getfile "Import URLs from:"} fil] || ![html::IsTextFile $fil alertnote]} {return}
	set fid [open $fil r]
	set filecont " [read $fid]"
	close $fid
			
	set exp1 "\[ \\t\\n\\r\]+[html::URLregexp]"
	set exp2 {[ \t\r\n]+(url)\([ \t\r\n]*("[^"]+"|'[^']+'|[^ \t\n\r\)]+)[ \t\r\n]*\)}
	for {set i1 1} {$i1 < 3} {incr i1} {
		set fcont $filecont
		set exp [set exp$i1]
		while {[regexp -nocase -indices $exp $fcont a b url]} {
			set link [quote::Unurl [string trim [string range $fcont [lindex $url 0] [lindex $url 1]] {"'}]]
			set fcont [string range $fcont [lindex $url 1] end]
			lappend html::AddedURLs($cset) $link
		}
	}
	html::SaveACacheSet URLs $cset
	html::ReadActiveCacheSets URLs
	status::msg "URLs imported."
}

# Add all files in a folder to URL cache.
proc html::AddFolder {} {
	global HTMLmodeVars html::AddedURLs
	if {![llength [set sets [html::FindAllSets URLs]]]} {return}
	if {[llength $sets] == 1} {
		set cset [lindex $sets 0]
	} elseif {[catch {listpick -p "Select URL set to import to." $sets} cset] || \
	  $cset == ""} {
		return
	}
    if {[catch {html::GetDir "Folder to cache:"} folder]} {return}
    set path ""
    foreach hp $HTMLmodeVars(homePages) {
    	if {[string match [file join [lindex $hp 0] *] [file join $folder " "]]} {
    		set path [string range $folder [expr {[string length [lindex $hp 0]] +1}] end]
    		regsub -all [quote::Regfind [file separator]] $path {/} path
    		if {[string length $path]} {append path /}
    	}
    }
	set box "-T {Path to files}"
    append box " -w 350 -h 80 -t {Path:} 10 10 60 30 -e [list $path] 70 10 340 25 \
	  -b OK 270 50 335 70 -b Cancel 185 50 250 70"
	set val [eval dialog $box]
    if {[lindex $val 2]} {return}
    set path [string trim [lindex $val 0]]
    if {[string length $path]} {set path "[string trimright $path /]/"}

    foreach fil [glob -nocomplain -dir $folder *] {
    	set name [file tail $fil]
    	if {![file isdirectory $fil]} {
    		lappend html::AddedURLs($cset) "$path$name"
    	}
    }
	html::SaveACacheSet URLs $cset
	html::ReadActiveCacheSets URLs
	status::msg "Files added to URL set."
}

