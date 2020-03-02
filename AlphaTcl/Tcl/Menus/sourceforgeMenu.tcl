## -*-Tcl-*-
 # ###################################################################
 #  AlphaTcl - extension to interact with sourceforge
 # 
 #  FILE: "sourceforgeMenu.tcl"
 #                                    created: 09/29/2001 {10:58:06 AM} 
 #                                last update: 11/19/2004 {09:37:12 AM} 
 #  Author: Vince Darley
 #  E-mail: vince@santafe.edu
 #          317 Paseo de Peralta, Santa Fe
 #     www: http://www.santafe.edu/~vince/
 #  
 # ###################################################################
 ##

# menu declaration
alpha::menu sourceforgeMenu 0.3.5 global SF {
    
} {
    sourceforgeMenu
} {
    
} maintainer {
    {Vince Darley} vince@santafe.edu http://www.santafe.edu/~vince/
} uninstall {
    this-file
} description {
    Interacts with the on-line "SourceForge" open source repository
} help {
    This global menu provides functionality to aid interactions with the open
    source repository 'sourceforge' (<http://sourceforge.net/>).  It allows
    you to specify any number of different sourceforge projects, and creates
    several different menu items to access mailing lists, forums, new, bugs,
    cvs repositories, etc.
    
    Preferences: Menus
}

proc sourceforgeMenu {} {}

namespace eval sf {}

hook::register requireOpenWindowsHook [list $sourceforgeMenu viewCvsChangesToFile] 1

set sf::cvsCgiRoot "http://cvs.sourceforge.net/cgi-bin/viewcvs.cgi/"
set sf::cvsRoot "http://cvs.sourceforge.net/"
set sf::httpRoot "http://sourceforge.net/"

# # Register new project: http://sourceforge.net/register/

proc sf::buildMenu {args} {
    global sourceforgeMenu sfmodeVars sfprojects
    set items [list "goToSourceForge" \
      "softwareMap" "siteStatusPage" "docsPage"]
    lappend items [list Menu -n "my sf.net" -p "sf::MenuProc" \
      [list loginAtSourceForge myPersonalPage accountOptions "Diary & Notes&" \
      myProjects monitoring mailings donations]]
    lappend items "(-)" "editProjectsÉ"
    if {[array size sfprojects] > 0} {
	lappend items \
	  [menu::makeFlagMenu sourceForgeProject list sourceForgeProject sfmodeVars]
    }
    lappend items [list Menu -n "projectAreas" -p "sf::MenuProc" \
      [list "ªGo to $sfmodeVars(sourceForgeProject) Project&" "(-" admin browseCvs \
      bugs cvsAccess docManager featureRequests fileReleases forums homePage mailingLists \
      memberList news patches screenshots statistics submitNews supportRequests tasks \
	  tracker "(-" downloadArea getNightlyTarball]]
    lappend items "(-" "viewCvsChangesToFile" "viewBugNumberÉ" \
      "viewPatchNumberÉ" 
    
    if {[array size sfprojects] > 0} {
	lappend items "(-" [menu::itemWithIcon "currentProject" 83]
	lappend items "ª$sfmodeVars(sourceForgeProject)&"
    } else {
	lappend items "(-" [menu::itemWithIcon "noProjectDeclared" 82] 
    }
    
    Menu -n $sourceforgeMenu -p sf::MenuProc $items
}

# If the array exists, then these should've been set at some point
# in the past, so we don't do it again, in case the user actually
# wanted to delete them!
if {![array exists sfprojects]} {
    ensureset sfprojects(Tcl) "sfProjectName tcl sfGroupId 10894"
    ensureset sfprojects(AlphaTcl) "sfProjectName alphatcl sfGroupId 16416"
    # save them.
    prefs::modified sfprojects(Tcl) sfprojects(AlphaTcl)
}

# The current project
newPref var sourceForgeProject Tcl sf sf::buildMenu sfprojects array

sf::buildMenu

proc sf::MenuProc {menu item} {
    global sfprojects sfmodeVars sf::httpRoot

    switch -- $menu {
	"SF" {
	    if {[info exists sfprojects($item)]} {
		sf::goToProject $item
	    } elseif {[string match -nocase $item $sfmodeVars(sourceForgeProject)]} {
		sf::goToProject
	    } else {
		switch -- $item {
		    "goToSourceForge" {url::execute "[set sf::httpRoot]"}
		    "softwareMap" {url::execute "[set sf::httpRoot]softwaremap"}
		    "siteStatusPage" {url::execute "[set sf::httpRoot]docman/display_doc.php?docid=2352&group_id=1"}
		    "docsPage" {url::execute "[set sf::httpRoot]docman/?group_id=1"}
		    "currentProject" {sf::goToProject }
		    "noProjectDeclared" {
			alert -t note -k "OK" -c "" -o "" "No project declared !" "Use the 'Edit ProjectÉ'\
			  menu item to create a new project. You will have to specify its SourceForge\
			  identification number."
		    }
		    default {menu::generalProc sf $item}
		}
	    }
	}
	"projectAreas" {
	    if {[regexp -nocase -- "^go ?to" $item]} {
		sf::goToProject
	    } else {
		sf::gotoArea $item $sfmodeVars(sourceForgeProject)
	    }
	}
	"my sf.net" {
	    sf::gotoArea $item ""
	}
    }
}


proc sf::editProjects {} {
    global sfprojects sfmodeVars
    set res [dialog::editGroup -array sfprojects -delete ask \
      -new sf::newProjectDetails \
      -title "Edit sourceforge project information" \
      -current $sfmodeVars(sourceForgeProject) \
      [list "sfProjectName" variable "Sourceforge project name"\
      "This is the name by which sourceforge refers to the project"] \
      [list "sfGroupId" variable "Sourceforge group id"\
      "This is the number (usually 5 digit) which sourceforge uses\
      to access further information on this project, usually using\
      http lookups with '?group_id=xxxxx'"] \
      [list "sfLocalDir" folder "Head of local copy of project"\
      "Location of checked-out version of the project"]]
    # This works whether projects have been modified or deleted.
    foreach proj $res {
	prefs::modified sfprojects($proj)
    }
    if {[llength $res]} {
	# Should now rebuild the menu in case we've added or
	# removed a project.
	sf::buildMenu
    }
}

proc sf::newProjectDetails {} {
    set name [prompt "Descriptive name of new project" ""]
    if {[string length $name]} {
	return [list $name [list sfProjectName "" sfGroupId ""]]
    } else {
	return
    }
}

proc sf::project {{proj ""}} {
    if {![string length $proj]} { 
	global sfmodeVars
	return $sfmodeVars(sourceForgeProject)
    }
    return $proj
}

proc sf::projectInfo {{proj ""}} {
    global sfmodeVars sfprojects
    if {![string length $proj]} { 
	set proj $sfmodeVars(sourceForgeProject)
    }
    return $sfprojects($proj)
}

proc sf::ChooseProjectFor {{filename ""}} {
    if {$filename == ""} {
	set filename [win::Current]
    }
    if {$filename == ""} { 
	status::msg "No window open!"
	return 
    }
    global sfprojects
    foreach proj [array names sfprojects] {
	set projectInfo [sf::projectInfo $proj]
	set dir [lindex $projectInfo 5]
	if {$dir == "" || ![file exists $dir]} {
	    continue
	}
	if {[file::pathStartsWith $filename $dir]} {
	    return $proj
	}
    }
    return ""
}

proc sf::goToProject {{proj ""}} {
    global sf::httpRoot
    set projectInfo [sf::projectInfo $proj]
     url::execute "[set sf::httpRoot]projects/[lindex $projectInfo 1]"
}

proc sf::gotoArea {area proj} {
    global sf::cvsCgiRoot sf::cvsRoot sf::httpRoot
    
    set groupid [lindex [sf::projectInfo $proj] 3]
    set name [lindex [sf::projectInfo $proj] 1]
    
    switch -- $area {
	admin {set http "[set sf::httpRoot]project/admin/?group_id=${groupid}"}
	browseCvs {set http "[set sf::cvsCgiRoot]${name}/"}
	cvsAccess {set http "[set sf::httpRoot]cvs/?group_id=${groupid}"}
	downloadArea {set http "http://prdownloads.sourceforge.net/${name}/"}
	getNightlyTarball {set http "[set sf::cvsRoot]cvstarballs/${name}-cvsroot.tar.bz2"}
	docManager {set http "[set sf::httpRoot]docman/?group_id=${groupid}"}
	forums {set http "[set sf::httpRoot]forum/?group_id=${groupid}"}
	homePage {set http "http://${name}.sourceforge.net"}
	mailingLists {set http "[set sf::httpRoot]mail/?group_id=${groupid}"}
	memberList {set http "[set sf::httpRoot]project/memberlist.php?group_id=${groupid}"}
	news {set http "[set sf::httpRoot]news/?group_id=${groupid}"}
	fileReleases {set http "[set sf::httpRoot]project/showfiles.php?group_id=${groupid}"}
	screenshots {set http "[set sf::httpRoot]project/screenshots.php?group_id=${groupid}"}
	statistics {set http "[set sf::httpRoot]project/stats/?group_id=${groupid}"}
	submitNews {set http "[set sf::httpRoot]news/submit.php?group_id=${groupid}"}
	tasks {set http "[set sf::httpRoot]pm/?group_id=${groupid}"}
	tracker - bugs - featureRequests - patches - supportRequests {
	    set http "[set sf::httpRoot]tracker/?group_id=${groupid}"
	}
	loginAtSourceForge {set http "[set sf::httpRoot]account/login.php"}
	myPersonalPage {set http "[set sf::httpRoot]my/"}
	diary&Notes {set http "[set sf::httpRoot]my/diary.php"}
	accountOptions {set http "[set sf::httpRoot]account"}
	myProjects - monitoring - mailings - donations {
	    set http "[set sf::httpRoot]my/[string tolower $area].php"
	}
	default {
	    error "Bad area \"$area\""
	}
    }
    url::execute $http
}

proc sf::viewCvsChangesToFile {} {
    set filename [win::StripCount [win::Current]]
    if {$filename == ""} { 
	status::msg "No window open!"
	return 
    }
    set proj [sf::ChooseProjectFor $filename]
    if {![string length $proj]} { 
	global sfmodeVars
	set msg "File not part of any known project."
	set projectInfo [sf::projectInfo]
	set dir [lindex $projectInfo 5]
	if {$dir == "" || ![file exists $dir]} {
	    append msg "Current project $sfmodeVars(sourceForgeProject) has no attached folder."
	}
	status::msg $msg
	return
    }
    set projectInfo [sf::projectInfo $proj]
    set local [lindex $projectInfo 5]
    set dir [file dirname $filename]
    # It is more robust to look for the cvs repository, because that will cope
    # with the situation where the file we're looking at is part of a module inside
    # the repository, and not the whole checkout.
    if {[file exists [file join $dir CVS Repository]]} {
	set repository [string trim [file::readAll [file join $dir CVS Repository]]]
	regsub "^/cvsroot/[lindex $projectInfo 1]/" $repository "" repository
	set repository [file join $repository [file tail $filename]]
    } else {
	if {![file::pathStartsWith $filename $local repository]} {
	    status::msg "File not part of $proj"
	    return
	}
    }
    regsub "^file:///" [file::toUrl $repository] "" rest
    
    global sf::cvsCgiRoot
    set url "[set sf::cvsCgiRoot][lindex $projectInfo 1]/$rest"
    status::msg "Going to $url"
    url::execute $url
}

proc sf::viewBugNumber {{proj ""} {bug ""}} {
    global sf::httpRoot
    if {$bug == ""} {
	set bug [prompt "View [sf::project $proj] project's bug#" ""]
    }
    if {$bug == ""} {
	return
    }
    set group [lindex [sf::projectInfo $proj] 3]
    set http "[set sf::httpRoot]tracker/index.php"
    append http "?func=detail&aid=${bug}&group_id=${group}&atid=1${group}"
    url::execute $http
}

proc sf::viewPatchNumber {{proj ""} {patch ""}} {
    global sf::httpRoot
    if {$patch == ""} {
	set patch [prompt "View [sf::project $proj] project's patch#" ""]
    }
    if {$patch == ""} {
	return
    }
    set group [lindex [sf::projectInfo $proj] 3]
    set http "[set sf::httpRoot]tracker/index.php"
    append http "?func=detail&aid=${patch}&group_id=${group}&atid=3${group}"
    url::execute $http
}

