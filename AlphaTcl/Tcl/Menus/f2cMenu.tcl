#=======================================================================
# F2C.TCL supports MAC F2C and CODE WARRIOR
#=======================================================================
# 1.0b1	jul 95
# 1.0b2	jul 95	listpick with -L blah as default, in the hope that blah
#				is no listelement. -L {} selects always the first
#				listelement.
# 1.0b3	Dec 95	changes for CW IDE, some more comments
# 1.0b4	Mar 96	added timeout option to tclAE::send -p commands with replies
# 2.0a1 Dec 2000 Initial efforts and making compatible with newer Alpha structure
#
# Questions, comments, and bug reports to:
# 			Jon Guyer
# 			jguyer@his.com
# 
# Based on 1.0b versions by
#			Klaus Thermann
#			klaus@gaga.maschinenbau.uni-dortmund.de
# Thanks to 
#			Dirk Froehling for lots of help with the Mac OS,
#			Igor Mikolic-Torreira for making MAC F2C available.
#
# Usage
#	• To see how it works
#		Bring this file to the front, load it by cmd L, and play around
#	• For permanent usage
#		Put it into the "Tcl:UserCode" folder of Alpha
#		Edit Prefs.tcl and add the line
#		source "$HOME:Tcl:UserCode:f2c.tcl"

#		
# Menu procedures
#
# Translate F To C
#				Translates frontmost window from f to c using current
#				settings of MAC F2C, does nothing if frontmost window
#				is not *.f. If the window is dirty, it is saved before
#				translation.
#
# Open Project	Closes current project, offers file dialog to select a
#				project and tells codewarrior to open it. The name of
#				the selected project appears as (always) deactived menu
#				item. Builds the list and menu items projectFiles and
#				otherFiles (see below)
#
# Get Project	Assumes that a code warrior project is open and gets
#				its name and files. If no project exists: file dialog
#				as above
#
# Switch To Project
#				Select project from list. The list f2cProjects is saved
#				between sessions (addDef) and extended when a project is
#				opened not contained in the list.
#				Remove From List ... offers a dialog to remove files 
#				from f2cProjects.
#
# Project Files	Is a list of *.f files in the project folder which
#				have corresponding *.c files in the codewarrior project.
#				These files are edited (or simply brought to the front)
#				when selected.
#
# Other Files	Is a (possibly empty) list of *.f files in the project
#				folder having no *.c counterparts in the project.
#				Editing as above.
#
# Run			Saves all modified files and translates from f to c, 
#				followed by CODE WARRIOR run. 
#				When f2c detects an error the process is stopped and the
#				*.f file, where the error was detected, brought to front.
#
# Make			Saves all modified files and translates from f to c, 
#				followed by CODE WARRIOR make. 
#				When f2c detects an error the process is stopped and the
#				*.f file, where the error was detected, brought to front.
#
# Add File		The *.c file corresponding to the frontmost *.f file is 
#				added to the project (if the *.c and *.f are in the
#				project folder, returns otherwise)
#
# Remove File	The *.c file corresponding to the frontmost *.f file is 
#				removed from the project (if the *.c and *.f are in the
#				project folder, returns otherwise).
#
# F To C & Add Files...
#				Offers a dialog to pick files from list f2c::otherFiles. 
#				The selected files are translated from f to c and added 
#				to the cw project.
#				When f2c detects an error the process is stopped and the
#				*.f file, where the error was detected, brought to front.
#
# Remove Files...
#				Offers a dialog to pick files from list f2c::projectFiles.
#				The selected files are removed from the cw project.
#

# Use Mac F2C icon as title for the F2C menu (assumes icon resources
# have been copied into Alpha).
# To use "F2C" as menu title, replace "•134" in the next
# line with "F2C" and rebuild package indices.

alpha::menu f2cMenu	2.0 Fort "•329" {
    # One-time initialisation script 

    namespace eval f2c {}

    newPref sig f2cSig F2Ci
    newPref var f2c::project "" Fort f2c::switchToProject f2c::projects array
    set f2c::projectFiles [list]
    set f2c::otherFiles [list]
    
    menu::buildProc f2cMenu f2c::buildMenu
    # Build the project switch list
    menu::buildProc fToCProject {
	menu::buildFlagMenu fToCProject list f2c::project FortmodeVars \
	  f2c::doProject [list "Open…" "Get" "Remove From List…"]
    }
    menu::buildProc otherFToCFiles f2c::buildOtherFilesMenu
    menu::buildProc projectFToCFiles f2c::buildProjectFilesMenu
    
    # No idea what this is for.  The user should have control
    # over what menus to use when...  In particular, this simply
    # forces the current mode (whatever that happens to be) to
    # use the codewarrior menu.  Bad! Bad!
    #catch {mode::adjustFeatures codewarriorMenu}
    
    menu::buildSome f2cMenu
    
    enableMenuItem "$f2cMenu" run off
    enableMenuItem "$f2cMenu" make off
    enableMenuItem "$f2cMenu" addFile off
    enableMenuItem "$f2cMenu" removeFile off
    enableMenuItem "$f2cMenu" otherFToCFiles off
    enableMenuItem "$f2cMenu" projectFToCFiles off
    enableMenuItem "$f2cMenu" fToC&AddFiles… off
    enableMenuItem "$f2cMenu" removeFiles… off
    
} {
    # Activation script
} {
    # Deactivation script
} uninstall {
    this-file
} maintainer {
    "Jon Guyer" <jguyer@his.com> <http://www.his.com/jguyer/>
} description {
    Integrates Fortran mode with "Mac F2C" and the Codewarrior IDE
} help {
    The 'f2cMenu' integrates Alpha's Fortran mode ("Fort Help") with Igor
    Mikolic-Torreira's Mac F2C and with the Codewarrior IDE.
    
    Preferences: Mode-Menus-Fort
}

proc f2cMenu.tcl {} {}

namespace eval f2c {}
				
hook::register savePostHook f2c::savePostHook "Fort"

#-----------------------------------------------------------------------
# f2cMenu
#-----------------------------------------------------------------------
proc f2cMenu {} {} 

#-----------------------------------------------------------------------
# f2c::buildMenu
#-----------------------------------------------------------------------
proc f2c::buildMenu {} {
	global f2cMenu
	
	set ma { 
		/K<UtranslateFToC
		(-)
		{Menu -n fToCProject -p f2c::switchToProject {}}
		/R<Urun
		/M<Umake
		(-)
		<SfToC&AddFiles…
		<SaddFile
		<S<EremoveFiles…
		<SremoveFile
		{Menu -m -n otherFToCFiles -p f2c::otherFilesProc {}}
		{Menu -m -n projectFToCFiles -p f2c::projectFilesProc {}}
	}
	return [list build $ma f2c::menuProc \
	  [list fToCProject otherFToCFiles projectFToCFiles] $f2cMenu]
}

#-----------------------------------------------------------------------
# f2c::buildOtherFilesMenu
#-----------------------------------------------------------------------
proc f2c::buildOtherFilesMenu {} {
	global f2c::otherFiles
	
	return [list Menu -m -n otherFToCFiles \
	  -p f2c::otherFilesProc ${f2c::otherFiles}]
}

#-----------------------------------------------------------------------
# f2c::buildProjectFilesMenu
#-----------------------------------------------------------------------
proc f2c::buildProjectFilesMenu {} {
	global f2c::projectFiles
	
	return [list Menu -m -n projectFToCFiles \
	  -p f2c::projectFilesProc ${f2c::projectFiles}]
}

#-----------------------------------------------------------------------
# f2c::menuProc
#-----------------------------------------------------------------------
proc f2c::menuProc {menu item} {
	f2c::$item
#     switch -- $item {
#       "openProject" {
#         f2c::openOrGet open
#       }
#       "getProject" {
#         f2c::openOrGet get
#       }
#       default {
#         f2c::$item
#       }
#     }

#     {
#         f2c::edit $item
# 	}
}

#-----------------------------------------------------------------------
# f2c::doProject
#-----------------------------------------------------------------------
proc f2c::doProject {menu item} {
    switch -- $item {
      "Open" {
        f2c::openOrGet open
      }
      "Get" {
        f2c::openOrGet get
      }
	  "Remove From List" {
		f2c::removeProject $menu $item
      }
    }
}

#-----------------------------------------------------------------------
# f2c::removeProject
#-----------------------------------------------------------------------
proc f2c::removeProject {menu item} {
	global CODEWarrior CWCLASS 
	global f2c::projects f2c::project

	set name [listpick -l -L blah -p "Pick project to remove from switch list:" [array names f2c::projects]]
	if {[info exists f2c::projects]} {
		global FortmodeVars
		
		foreach item $name {
			if {$item == [set FortmodeVars(f2c::project)]} {
				f2c::clean
				set FortmodeVars(f2c::project) "" 
			} 
			unset f2c::projects($item)
		}
	}
	
	menu::buildSome f2cMenu
	
	if {[set FortmodeVars(f2c::project)] == ""} {
		global f2cMenu
		
		enableMenuItem "$f2cMenu" run off
		enableMenuItem "$f2cMenu" make off
		enableMenuItem "$f2cMenu" addFile off
		enableMenuItem "$f2cMenu" removeFile off
		enableMenuItem "$f2cMenu" otherFToCFiles off
		enableMenuItem "$f2cMenu" projectFToCFiles off
		enableMenuItem "$f2cMenu" fToC&AddFiles… off
		enableMenuItem "$f2cMenu" removeFiles… off
	} 
}

#-----------------------------------------------------------------------
# f2c::switchToProject
#-----------------------------------------------------------------------
proc f2c::switchToProject {var} {
	global CODEWarrior CWCLASS 
	global f2c::projects FortmodeVars

	set project [set FortmodeVars(f2c::project)]
	if {[info exists f2c::projects($project)]} {
		set newproject [set f2c::projects($project)]
	} else {
		alertnote "Project $project not found"
		return
	}
	f2c::clean
	cw::check
	tclAE::send $CODEWarrior aevt odoc "----" [makeAlis $newproject]
	f2c::update
}

#-----------------------------------------------------------------------
# f2c::clean
#-----------------------------------------------------------------------
proc f2c::clean {} {
	global f2cMenu FortmodeVars f2c::otherFiles f2c::projectFiles

# 	catch {menu::uninsert f2cMenu items end "([set FortmodeVars(f2c::project)]"}

	set f2c::projectFiles [list]
	set f2c::otherFiles [list]
}

#-----------------------------------------------------------------------
# f2c::update
#-----------------------------------------------------------------------
proc f2c::update {} {
	global f2c::jobs f2cMenu f2c::otherFiles FortmodeVars f2c::projects
	global CODEWarrior CWCLASS f2c::projectFiles

	# Clean the list of files to be f2c'ed
	set f2c::jobs [list]

	set project [set f2c::projects([set FortmodeVars(f2c::project)])]
	
	# Show current project in menu
# 	menu::insert f2cMenu items end "([file tail $project]"
	
	# If a *.f file in the project directory has a corresponding *.c file
	# in the CodeWarrior project append it to the list f2c::projectFiles else to the
	# list f2c::otherFiles
	set f2c::otherFiles [list]
	set f2c::projectFiles [list]
	foreach f [glob -dir [file dirname $project] *.f] {
		regsub {\.f$} $f {.c} cfile
		if {[catch {tclAE::build::throw -t 500000 $CODEWarrior $CWCLASS FInP "----" [makeAlis $cfile]}]} {
			lappend f2c::otherFiles [file tail $f]
		} else {
			lappend f2c::projectFiles [file tail $f]
		}
	}
	
	menu::buildSome f2cMenu
	
	# Update f2cMenu
 	enableMenuItem "$f2cMenu" run on
 	enableMenuItem "$f2cMenu" make on
	enableMenuItem "$f2cMenu" addFile on
	enableMenuItem "$f2cMenu" fToC&AddFiles… on
	enableMenuItem "$f2cMenu" removeFile on
	enableMenuItem "$f2cMenu" removeFiles… on
	enableMenuItem "$f2cMenu" otherFToCFiles on
	enableMenuItem "$f2cMenu" projectFToCFiles on
}
	
#-----------------------------------------------------------------------
# f2c::openOrGet: get open CodeWarrior project or
#					close project and open with standard file dialog
#-----------------------------------------------------------------------
proc f2c::openOrGet {job} {
	global CODEWarrior CWCLASS f2c::projects FortmodeVars

	# Open or get CodeWarrior project
	cw::check
	if {$job == "open"} {
		# Close current project, select new project, codewarrior open
#  		tclAE::send -t 500000 -r $CODEWarrior $CWCLASS ClsP
		set newproject [getfile "Select CodeWarrior Project"]
		set f2c::projects([file tail $newproject]) $newproject
		tclAE::send $CODEWarrior aevt odoc "----" [makeAlis $newproject]
	} else {
		# Get name of open cw project
		set projectDesc [tclAE::build::resultDesc -t 500000 $CODEWarrior $CWCLASS GetP]
		set newproject [tclAE::getData $projectDesc TEXT]
		tclAE::disposeDesc $projectDesc
		if {[string length $newproject] == 0} {
			set newproject [getfile "Select Code Warrior Project"]
			tclAE::send $CODEWarrior aevt odoc "----" [makeAlis $newproject]
		}
	}
	
	f2c::clean
	
	set name [file tail $newproject]
	set FortmodeVars(f2c::project) $name
	set f2c::projects([set name]) $newproject
	
	f2c::update
}

#-----------------------------------------------------------------------
# f2c::edit: edit or bring to front
#-----------------------------------------------------------------------
proc f2c::edit {item} {
	global f2c::projects FortmodeVars

	set projectdir [file dirname [set f2c::projects([set FortmodeVars(f2c::project)])]]
	# bring to front if file is open, otherwise edit
	if {[catch {bringToFront $item}]} {
        edit -c [file join $projectdir $item]
    }
}

proc f2c::otherFilesProc {menu item} {f2c::edit $item}
proc f2c::projectFilesProc {menu item} {f2c::edit $item}

#-----------------------------------------------------------------------
# f2c::check: check wether MAC F2C is running, launch it if not
#-----------------------------------------------------------------------
proc f2c::check {} {
	global MACF2C f2cSig
	set MACF2C [app::ensureRunning $f2cSig]
}

#-----------------------------------------------------------------------
# f2c::translateFToC: translate file in the frontmost window from f to c
#-----------------------------------------------------------------------
proc f2c::translateFToC {} { 

	global ALPHA MACF2C
	# get name of frontmost window
	set fname [lindex [winNames -f] 0]
	# return if not *.f
	if {[file extension $fname] != ".f"} {
		return
	}
	
	# save if window dirty
	getWinInfo win
	if {$win(dirty)} {
		save
	}
	# compile 
	f2c::check
	switchTo $MACF2C
	f2c::oneFile $fname
	switchTo $ALPHA
}

#-----------------------------------------------------------------------
# f2c::oneFile: translate a single file from f to c
#-----------------------------------------------------------------------
proc f2c::oneFile {fname} {
	global f2c::jobs f2cMenu MACF2C ALPHA CODEWarrior
	
	set f2cDesc [tclAE::build::resultDesc -t 500000 $MACF2C F2Ci F2C1 \
	  ---- [tclAE::build::alis $fname] \
	  ]
	if {![tclAE::getNthData $f2cDesc 0]} {
		# f2c sucessful, remove file from f2c::jobs
		set i [lsearch -exact $f2c::jobs $fname]
		if {$i >= 0} {set f2c::jobs [lreplace $f2c::jobs $i $i]}
		set Ffiles [tclAE::getNthDesc $f2cDesc 1]
		set Fcount [tclAE::countItems $Ffiles]
	    switchTo $CODEWarrior
		for {set i 0} {$i < $Fcount} {incr i} {
			set Ffile [tclAE::getNthDesc $Ffiles $i]
			set Cfiles [tclAE::getNthDesc $Ffile 3]
			tclAE::disposeDesc $Ffile
            set Ccount [tclAE::countItems $Cfiles]
            for {set j 0} {$j < $Ccount} {incr j} {
				cw::modified [tclAE::getNthData $Cfiles $j TEXT]
			} 
			tclAE::disposeDesc $Cfiles
		}
        tclAE::disposeDesc $Ffiles
		set result 0
	} else {
		switchTo $ALPHA
		# set item to fname without path
		f2c::edit [file tail $fname]
		set result 1
	}
	tclAE::disposeDesc $f2cDesc
	return $result
}

#-----------------------------------------------------------------------
# f2c::addFile: add file in the front window to project
#-----------------------------------------------------------------------
proc f2c::addFile {} { 
	global CODEWarrior CWCLASS f2c::projects FortmodeVars f2c::otherFiles

	# get name of current window
	set fname [lindex [winNames -f] 0]

	# return if not *.f 
	if {[file extension $fname] != ".f"} {
		return
	}

	set projectdir [file dirname [set f2c::projects([set FortmodeVars(f2c::project)])]]
	
	# return if not in projectdir
	set blah [file tail $fname]
	set fname [file join $projectdir $blah]
	if {[file exists $fname] != 1} return
	 
	# return if *.c file not in projectdir
	regsub {\.f$} $fname {.c} cname
	if {[file exists $cname] != 1} return

	# ok, add to project and update menu
	f2c::addOneFile $cname
}

#-----------------------------------------------------------------------
# f2c::addFiles
#-----------------------------------------------------------------------
proc f2c::fToC&AddFiles {} {
	global f2c::otherFiles f2c::projects FortmodeVars MACF2C ALPHA
	set name [listpick -l -L blah -p "Pick files to add to project:" $f2c::otherFiles]
	saveAll
	
	set projectdir [file dirname [set f2c::projects(${FortmodeVars(f2c::project)})]]
	foreach item $name {
        if {[file extension $item] == ".f"} {
            set citem [file join [file rootname $item] ".c"]
            set cname [file join $projectdir $citem]
            # compile 
            set fname [file join $projectdir $item]
            f2c::check
            switchTo $MACF2C
            if {![f2c::oneFile $fname]} {
                switchTo $ALPHA
                f2c::addOneFile $cname
            }
        }
    }    
}


#-----------------------------------------------------------------------
# f2c::addOneFile
#-----------------------------------------------------------------------
# add .c file to project and update menu
# the file is added to segment 1, without specification of Segm,
# each time a file is added, a new segment is build
proc f2c::addOneFile {cname} {
	global CODEWarrior CWCLASS

	tclAE::build::resultData $CODEWarrior $CWCLASS AddF \
	  ---- [tclAE::build::alis $cname] \
	  Segm 1
	if {![catch {
		tclAE::build::throw $CODEWarrior $CWCLASS AddF \
		  ---- [tclAE::build::alis $cname] \
		  Segm 1
	}]} {
        set fname [file join [file rootname $cname] ".f"]
		set blah [file tail $fname]
		addMenuItem -m projectFiles $blah
		deleteMenuItem -m otherFiles $blah
		lappend f2c::projectFiles $blah
		if {[set i [lsearch -exact $f2c::otherFiles "$blah"]] >= 0} {
            set f2c::otherFiles [lreplace $f2c::otherFiles $i $i]
		}
	}
}

#-----------------------------------------------------------------------
# f2c::removeOneFile
#-----------------------------------------------------------------------
proc f2c::removeOneFile {cname} {
	global f2c::projectFiles f2c::otherFiles CODEWarrior CWCLASS
	set res [tclAE::send -p -t 500000 -r  $CODEWarrior $CWCLASS RemF "----" [makeAlis $cname]]
	regexp {:\[(.*)\]} $res dummy err
	if {! $err} {
		regsub {\.c$} $cname {.f} fname
		set blah [file tail $fname]
		deleteMenuItem -m projectFiles $blah
		addMenuItem -m otherFiles $blah
		lappend f2c::otherFiles $blah
		if {[set i [lsearch -exact $f2c::projectFiles "$blah"]] >= 0} {
				set f2c::projectFiles [lreplace $f2c::projectFiles $i $i]
		}
	}
}



#-----------------------------------------------------------------------
# f2c::removeFile: remove file in the front window from project
#-----------------------------------------------------------------------
proc f2c::removeFile {} {
	global CODEWarrior CWCLASS f2c::projects FortmodeVars f2cMenu f2c::projectFiles

	# get name of current window
	set fname [lindex [winNames -f] 0]

	# return if not *.f 
	if {[file extension $fname] != ".f"} {
		return
	}
	
	# return if not in projectdir 
	set blah [file tail $fname]
	set projectdir [file dirname [set f2c::projects(${FortmodeVars(f2c::project)})]]
	set fname [file join $projectdir $blah]
	if {[file exists $fname] != 1} return
	 
	# return if *.c file not in projectdir
	regsub {\.f$} $fname {.c} cname
	if {[file exists $cname] != 1} return

	# ok, remove from project and update menu
	f2c::removeOneFile $cname
}

#-----------------------------------------------------------------------
# f2c::removeFiles
#-----------------------------------------------------------------------
proc f2c::removeFiles {} {
	global f2c::projectFiles f2c::otherFiles f2c::projects FortmodeVars
	set name [listpick -l -L blah -p "Pick files to remove from project:" $f2c::projectFiles]
	set projectdir [file dirname [set f2c::projects(${FortmodeVars(f2c::project)})]]
	foreach item $name {
		regsub {\.f$} $item {.c} citem
		set cname [file join $projectdir $citem]
		f2c::removeOneFile $cname
	}
}


#------------------------------------------------------------------------
#	f2c::run: f2c translate (if necessary), followed by CodeWarrior run 
#------------------------------------------------------------------------
proc f2c::run {} { 
	global ALPHA MACF2C f2c::jobs

	saveAll
	if {[llength ${f2c::jobs}] > 0} {
		# something to do for f2c
		f2c::check
		switchTo $MACF2C
 		foreach fname ${f2c::jobs} {
 			if {[f2c::oneFile $fname]} return
 		}
 	}
	cw::_run
}
#------------------------------------------------------------------------
#	f2c::make: f2c translate (if necessary), followed by CodeWarrior make
#------------------------------------------------------------------------
proc f2c::make {} { 
	global ALPHA MACF2C f2c::jobs

	saveAll
	if {[llength [set f2c::jobs]] > 0} {
		# something to do for f2c
		f2c::check
		switchTo $MACF2C
 		foreach fname $f2c::jobs {
 			if {[f2c::oneFile $fname]} return
 		}
 	}
	cw::Do Make
}


#-----------------------------------------------------------------------
# saveHook: modified by adding f2c support
#			each time a .f file is saved, its name is added to f2cJobs
#-----------------------------------------------------------------------

proc f2c::savePostHook name {
	global f2c::jobs
	if {[file extension $name] == ".f"}  {	
		if {![info exists f2c::jobs]
        ||	[lsearch -exact $f2c::jobs $name] < 0} {
			# not contained in f2c::jobs, append
			lappend f2c::jobs $name
		}
	}
}

#-----------------------------------------------------------------------
# f2c::checkCw: modified checkCw from codewarrior.tcl
#-----------------------------------------------------------------------
proc f2c::checkCw {} {
	global CODEWarrior CWCompilerSig cwPath

	# last parameter is default 1 = launch -f, 0 = launch
	set CODEWarrior [app::ensureRunning $CWCompilerSig 0]
}
		
