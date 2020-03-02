## -*-Tcl-*-
 # ###################################################################
 #  AlphaTcl - core Tcl engine
 # 
 #  FILE: "install.tcl"
 #                                    created: 25/7/97 {1:12:02 am} 
 #                                last update: 02/25/2006 {03:44:36 AM} 
 #  Author: Vince Darley
 #  E-mail: <vince@santafe.edu>
 #    mail: 317 Paseo de Peralta
 #          Santa Fe, NM 87501, USA
 #     www: <http://www.santafe.edu/~vince/>
 #  
 # Copyright (c) 1997-2006  Vince Darley, all rights reserved
 # 
 #  This file contains a pretty complex package installation
 #  procedure, and some more rudimentary code which queries
 #  an ftp site for a list of packages and checks dates etc
 #  to see if there's something new.  The idea being you can
 #  then just select from a menu to download and subsequently
 #  install.
 #  
 # Package installation:
 # 
 #  There is a new install mode 'Inst' which adds the Install menu.
 #  Install mode is trigerred when a file's name ends in 'Install'
 #  or 'INSTALL', or when the first line of the file contains the
 #  letters 'install', provided in this last case, that the file
 #  is not in Alpha's Tcl hierarchy.  This last case is useful so
 #  that a single .tcl file can be a package and be installed by
 #  Alpha using these nice scripts, without the need for a separate
 #  install-script-file.  However once that .tcl file is installed,
 #  if you open it you certainly wouldn't want it opened in Install mode!
 #  
 # Once you've opened a file in install mode:
 # 
 #  You can select 'install this package' from the menu.  (If the file's
 #  first line contains 'auto-install' the menu item is automatically
 #  selected, provided no modifier key is pressed).  In any case, this 
 #  does the following: if there's an install file in the current directory
 #  it is sourced.  An install file is defined as a file at the same
 #  level as the current file whose name matches "*install*.tcl".
 #  If no install file is found, a default (but still rather
 #  sophisticated) installation takes place, by calling the procedure
 #  'install::packageInstallationDialog'.  Any install script in your
 #  *install*.tcl file may wish to use that procedure anyway.  For
 #  instance, the installer for Vince's Additions uses just the
 #  following lines in its installation file:
 #  
 # 	install::packageInstallationDialog "Vince's Additions" "\
 # These additions include a number of different packages, designed to \
 # make using Alpha an even more pleasant experience!  They include a \
 # more sophisticated completion and template mechanism, some bibliography \
 # conversion routines, and a general projects/documents organisation scheme." 
 # 	
 # In any case, 'install::packageInstallationDialog' does the following:
 # It scans the current directory for files which may need installing.
 # This includes any .tcl file which is not the *install*.tcl script.
 # It also includes the same in any subdirectories of the current 
 # directory.  Intelligent guesses are made as to whether files are 
 # Modes, Menus, Packages, Completions, Extensions, Help files or
 # User Packages
 # 
 # Extensions are *+\d.tcl files, these go in smarterSourceFolder
 # Modes are *Mode.tcl files, or all files in a subdir *Mode*
 # Menus are *Menu.tcl files, or all files in a subdir *Menu*
 # Completions are all files *Completions.tcl
 # Help files end in 'help' or 'tutorial' (any case)
 # User Packages are any files in a User Packages subdir.
 # Packages are anything else.
 # 
 # UserModifications are files which a package installs once, but
 # the user is expected to edit afterwards.  Hence if the package
 # is reinstalled, those files are not overwritten.
 # 
 # Clearly if the original install file was in fact a .tcl file on
 # its own (with 'install' in the first line) then we don't search
 # the directory in which it sits.  This is now implemented.
 # 
 # ----------
 # OK, we've got all the files and worked out where they should go.
 # Now we build an installation dialog, from which the user can
 # select 'Easy Install', or 'Custom Install'.  Easy install does
 # the works, custom allows the user to choose amongst all the 
 # available sub-pieces.  A sub-piece is any single item in the
 # install directory: so you can package up blocks of files as a single
 # package by putting them in a sub-dir.
 # 
 # If you hit 'OK' installation takes place, with optional backup
 # of removed files.
 # 
 # Currently package indices and tcl indices are then rebuilt.  This
 # last thing needs to be a bit more sophisticated...
 # 
 # ----------
 # Caveats:
 # 
 # 	Currently not clever enough to install, say, HTML mode in the
 # 	way it currently is: here we wish to install all HTML files in
 # 	one sub-dir of the Modes dir, but we wish to allow the user to
 # 	pick which sub-sets of files will go in that 'HTML and CSS modes'
 # 	directory.  So the user could install just HTML files and ignore
 # 	the CSS ones.  The solution I propose is to store such items in
 # 	separate subfolder of the base HTML subfolder.  Such items would
 # 	then be sub-choices of the base 'install HTML mode' choice, and
 # 	when installed, would be installed directly into the HTML mode
 # 	dir.
 # 	
 # I think I need more feedback before embarking on further 
 # modifications to this code.
 #  
 # ###################################################################
 ##
		
proc install.tcl {} {}

namespace eval install {}

proc installMenu {} {}

set installMenu "Install"
set menu::items(Install) [list \
  "installThisPackage" "(-" "rebuildPackageIndices" "rebuildTclIndices"]

menu::buildSome Install

proc install::rebuildPackageIndices {} {
    alpha::rebuildPackageIndices 
}

## 
 # -------------------------------------------------------------------------
 # 
 # "install::installThisPackage" --
 # 
 #  DO NOT CALL THIS PROCEDURE FROM YOUR *install.tcl INSTALLATION SCRIPT
 #  IT WILL CAUSE INFINITE RECURSION AND CRASH ALPHA.  THIS PROCEDURE IS
 #  DESIGNED TO SOURCE YOUR *install.tcl FILE AUTOMATICALLY IF IT EXISTS.
 #  
 #  Instead call install::packageInstallationDialog 
 #  and install::askRebuildQuit
 # -------------------------------------------------------------------------
 ##
proc install::installThisPackage {{name ""}} {
    if {$name == ""} { set name [win::StripCount [win::Current]] }
    set currD [file dirname $name]
    
    if {[file extension $name] == ".tcl"} {
	# single-file packages by definition don't have an installer.
	set installFile ""
	set installPkg $name
	# But they do have an install file.
	global install::usingThisFile
	set install::usingThisFile $name
    } else {
	set fin [open $name r]
	set line [gets $fin]
	close $fin
	if {[regexp -nocase {auto-install-script} $line]} {
	    # If there is 'auto-install-script' on the first line
	    # then we source this file (even though it doesn't have
	    # a .tcl extension, it is a tcl installation script).
	    set installFile [list $name]
	} else {
	    # Look for an appropriate installer .tcl file to use.
	    set installFile [glob -nocomplain -dir $currD *nstall*.tcl]
	    if {[llength $installFile] != 1} {
		if {[llength $installFile] > 1} {
		    alertnote "This package has two installation files.\
		      This is bad; I'll do a standard installation."
		}
		set installFile ""
		set installPkg $name
	    }
	}
    }
    
    # We assume all installers are macRoman at present.
    alpha::registerEncodingFor $currD macRoman
    
    global install::didSomething
    set install::didSomething 0
    
    if {[llength $installFile] == 1} {
	global install::usingThisFile
	set install::usingThisFile [lindex $installFile 0]
	# '$installFile' is a one-item list, so no need to wrap it
	# with 'list'.
	set res [catch {
	    if {[install::scriptLooksDangerous \
	      [file::readAll $install::usingThisFile]] \
	      && ![dialog::yesno -y Continue -n Edit \
	      "Do you wish to edit or execute\
	      '[file tail [lindex $installFile 0]]'?\r\
	      This file contains an install script, and in this\
	      case it might contain some unsafe code.\
	      Choose 'Edit' if you are unsure (you can later\
	      select 'Install' from the menu if it looks safe)."]} {
		return -code error "edit install script"
	    }
	    uplevel \#0 source $installFile
	} err]
    } else {
	set res [catch {
	    install::packageInstallationDialog $installPkg
	} err]
    }
    
    if {$res} {
	if {$err != "edit install script"} {
	    error::occurred $err
	} else {
	    # Get the window ready.
	    set openw [file::hasOpenWindows $install::usingThisFile]
	    if {[llength $openw]} {
		bringToFront [lindex $openw 0]
		defaultSize
	    } else {
		editDocument $install::usingThisFile
	    }
	    unset -nocomplain install::usingThisFile
	    unset install::didSomething
	    alpha::deregisterEncodingFor $currD
	    return -code error $err
	}
	unset -nocomplain install::usingThisFile
    }

    if {${install::didSomething} != 0 && ${install::didSomething} != 1} {
	set install::didSomething 1
    }
    
    alpha::deregisterEncodingFor $currD
    
    if {!${install::didSomething}} {
	unset install::didSomething
	return
    }
    unset install::didSomething
    
    global install::forcequit install::nochanges
    if {![info exists install::nochanges] || !${install::nochanges}}  {
	unset -nocomplain install::nochanges
	if {[info exists install::forcequit]} {
	    # Will exist unless installation was aborted
	    install::askRebuildQuit ${install::forcequit}
	}
    } else {
	unset install::nochanges
	status::msg "Installation complete (nothing was actually installed)"
    }
}

proc install::sourceUpdatedSystem {} {
    global HOME install::time
    if {![info exists install::time]} { return }
    set notSource [list AlphaBits.tcl alphaDefinitions.tcl runAlphaTcl.tcl\
      initAlphaTcl.tcl initialize.tcl library.tcl]
    foreach f [glob -nocomplain -dir [file join ${HOME} Tcl SystemCode] *.tcl] {
	if {[lsearch -exact $notSource [file tail $f]] != -1} {
	    continue
	}
	if {[file mtime $f] > ${install::time}} {
	    catch [list uplevel \#0 [list source $f]]
	}
    }
}

proc install::askRebuildQuit {{force 0}} {
    alertnote here $force
    if {$force != 2} {
	alertnote "All indices must now be rebuilt for the installation to work."
	if {![key::optionPressed] \
	  || [dialog::yesno "Shall I rebuild the indices?"]} {
	    install::sourceUpdatedSystem
	    set n [alpha::package names -feature]
	    alpha::rebuildPackageIndices
	    set new [lremove [alpha::package names -feature] $n]
	    set askUser [list]
	    foreach pkg $new {
		if {![alpha::isPackageInvisibleToUser $pkg]} {
		    # Now we also need to remove menus which are just for 
		    # particular modes
		    if {[string range \
		      [alpha::package versions $pkg] 0 3] != "for "} {
			lappend askUser $pkg
		    }
		}
	    }
	    
	    if {![key::optionPressed] \
	      || [dialog::yesno "Shall I rebuild the Tcl indices?"]} {
		rebuildTclIndices
	    }
	    auto_reset
	    if {[llength $askUser]} {
		if {[dialog::yesno "You just installed the following\
		  new packages: $new; do you want to activate them at\
		  next startup?"]} {
		    global global::features
		    eval lappend global::features $askUser
		}
	    }
	}
	# Update the "Packages" help file, then close it.
	global::listPackages 1
    }
    if {$force || [dialog::yesno "It is recommended that you quit and\
      restart Alpha.  Quit now?"]} {
	if {$force == 2} {
	    alertnote "Alpha will now quit.  Package indices will be\
	      rebuilt next time you use Alpha."
	} elseif {$force == 1} {
	    alertnote "Alpha must now quit."
	}
	if {[win::StripCount [win::CurrentTail]] == "Installation report"} {
	    setWinInfo read-only 0
	    setWinInfo dirty 1
	}
	quit
    }
}

proc install::scriptLooksDangerous {text} {
    # Avoid anything which seems to be trying to rename or delete
    # files, or otherwise execute stuff.
    if {[string first "rename " $text] != -1} {
	return 1
    }
    if {[string first "file ren" $text] != -1} {
	return 1
    }
    if {[string first "file de" $text] != -1} {
	return 1
    }
    if {[string first "rmdir" $text] != -1} {
	return 1
    }
    if {[string first "rm -r" $text] != -1} {
	return 1
    }
    return 0
}

## 
 # -------------------------------------------------------------------------
 # 
 # "install::openHook" --
 # 
 #  Used when opening an install file to check for an 'auto-install' line.
 # -------------------------------------------------------------------------
 ##
proc install::openHook {name} {
    set firstLine [getText [minPos] [nextLineStart [minPos]]]
    if {[regexp -nocase {auto-install} $firstLine]} {
	# Now we need to check we aren't actually recursively calling
	# ourselves from inside the 'editHook' below, if that hook
	# decided we do actually want to edit the file rather than 
	# install with it.
	global install::usingThisFile
	if {[info exists install::usingThisFile]} {
	    if {[file nativename $install::usingThisFile] eq $name} {
		return
	    }
	}
	install::hookHelper $name 1
    }
}

proc install::editHook {filename} {
    return [install::hookHelper $filename]
}

proc install::hookHelper {name {haveWin 0}} {
    if {$haveWin} {
	set filename [win::StripCount $name]
    } else {
	set filename $name
    }
    
    if {$haveWin} {
	moveWin $name 10000 10000
    }
    
    if {[catch {install::installThisPackage $filename} err]} {
	if {$err == "edit install script"} {
	    if {$haveWin} {
		defaultSize $name
		bringToFront $name
	    }
	    return 1
	}
	#alpha::stderr $err
    }
    
    if {$haveWin} {
	if {![catch {bringToFront $name}]} {
	    killWindow
	}
    }
    return 1
}

proc install::readAtStartup {w} {
    global alpha::readAtStartup
    lappend alpha::readAtStartup $w
    prefs::modified alpha::readAtStartup
}

## 
 # -------------------------------------------------------------------------
 # 
 # "install::packageInstallationDialog" --
 # 
 #  Optional arguments are as follows:
 #  
 #  -ignore {list of files to ignore}
 #  -remove {list of files to remove from Alpha hierarchy}	
 #  -rebuildquit '0 or 1'  
 #      (prompts the user to rebuild indices and quit; default 1)
 #  -require {Pkg version Pkg version É}
 #  	e.g. -require {Alpha 6.52 elecCompletions 7.99}
 #  -provide {Pkg version Pkg version É}
 #  -forcequit '0' or '1' or '2'.
 #  
 #  Note: -forcequit 2 is really only designed for use by Alpha Core
 #  updaters; it should not really be used by other code.
 #  
 #  and 
 #  
 #  -SystemCode -Modes -Menus
 #  -BugFixes -Completions -Packages -UserPackages
 #  -ExtensionsCode -UserModifications -Tools -Tests -Source
 #  
 #  which force the placement of the following list of files.
 #  
 #  Returns 1 if it did something, 0 if nothing (e.g. cancelled or nothing
 #  was necessary to install).  
 #  
 #  This procedure must never fail!
 # -------------------------------------------------------------------------
 ##
proc install::packageInstallationDialog {{pkgname "Package"} {description ""} args} {
    global install::usingThisFile
    if {[info exists install::usingThisFile] \
      && [file exists ${install::usingThisFile}]} {
	set currD [file dirname ${install::usingThisFile}]
    } elseif {[file exists $pkgname]} {
	set currD [file dirname $pkgname]
    } else {
	set currD [file dirname [win::Current]]
    }
    if {[file exists $pkgname] && ([file extension $pkgname] == ".tcl")} {
	# single file to install
	set items [list [file tail $pkgname]]
	set pkgname [file root [file tail $pkgname]]
	set description "I'll install this single-file package, placing\
	  it in its correct location in Alpha's code base."
    } else {
	if {[file exists $pkgname]} {
	    set pkgname "Package"
	}
	
	set toplevels [glob -nocomplain -dir $currD *.tcl]
	eval lappend toplevels [glob -nocomplain -dir $currD *.shlb]
	eval lappend toplevels [glob -types TEXT -nocomplain -dir $currD "* *"]
	set toplevels [lremove -glob $toplevels *\[Ii\]nstall*]
	set toplevels [lremove -glob $toplevels *INSTALL*]
	set subdirs [glob -nocomplain -types d -dir $currD *]
	set toplevels [lunique $toplevels]
	foreach item $toplevels {
	    # Tcl 8 doesn't have functional glob -types TEXT yet
	    if {![file isdirectory $item]} {
		lappend items [file tail $item]
	    }
	}
	if {[file exists [file join $currD Changes]]} {
	    lappend items Changes
	}
	foreach dir $subdirs {
	    lappend items [file tail ${dir}]
	}
	set subdirs [lremove -glob $subdirs "*Completions[file separator]"]
	set completions [glob -nocomplain -types d -dir $currD Completions]
	set usermods [glob -nocomplain -types d -dir $currD UserModifications]
    }
    global install::didSomething
    set install::didSomething [eval \
      [list install::_packageInstallationDialog $pkgname\
      $description $currD $items] $args]
    return ${install::didSomething}
}

proc install::canInstall {} {
    # Not yet fully implemented.
    return 1
    
    global HOME
    if {[file writable [file join $HOME Tcl]]} {
	return 1
    }
    
    set alphatclvfs \
      [expr {[lindex [file system [file join $HOME Tcl]] 0] eq "tclvfs"}]
    if {$alphatclvfs} {
	# Try to find the AlphaTcl vfs
	set dir [file join $HOME Tcl]
	for {set i 0} {$i < 3} {incr i} {
	    if {[lsearch -exact [vfs::filesystem info] $dir] != -1} {
		set alphavfs $dir
		break
	    }
	    set dir [file dirname $dir]
	}
    }
    if {[info exists alphavfs]} {
	set starpack \
	  [expr {[file system [info nameof]] eq [file system $alphavfs]}]
	if {$starpack} {
	   if {[file writable [file dirname [info nameof]]]} {
	       if {[dialog::yesno -y "Go Ahead" -n "Cancel" \
		 "You can install this update, but it will require special \
		 exit handling to update the Alphatk application in place. \
		 Do you wish to do this?"]} {
		   vfs::attributes [info nameof] -state translucent
		   hook::register quitHook \
		     [list ::install::saveModifiedAlphatkOnExit [info nameof]]
		   return 1
	       } else {
		   return 0
	       }
	    }
	}
    }
  
    alertnote \
      "Your AlphaTcl library is read-only and the installation\
      will therefore most likely fail.  You may wish to cancel."
    return 1
}

proc install::saveModifiedAlphatkOnExit {app} {
    set dir [pwd]
    cd [file dirname $app]
    set tail [file tail $app]
    set mount [vfs::filesystem info $app]
    # Do the trick of unmount, copy, remount to copy the
    # original file rather than the virtual directory.  We
    # do this using the underlying tclvfs api, so that the
    # actual metakit doesn't even notice.
    vfs::filesystem unmount $app
    file copy $tail "Patched $tail"
    vfs::filesystem mount $app $mount
    # Now we want to copy over the (modified) metakit.
    vfs::mk4::Mount "Patched $tail" "Patched $tail"
    vfs::attributes "Patched $tail" -state readwrite
    vfs::mk4::Unmount "Patched $tail"
    file::showInFinder $app
    alertnote "After Alphatk exits, please delete the\
      original '$tail' and replace it with the 'Patched $tail'"
}

## 
 # -------------------------------------------------------------------------
 # 
 # "install::_packageInstallationDialog" --
 # 
 #  Returns 1 if something was installed, 0 otherwise (including if
 #  the installation was cancelled).
 # -------------------------------------------------------------------------
 ##
proc install::_packageInstallationDialog {pkgname description currD items args} {
    global install::time install::force_overwrite HOME SUPPORT
    
    variable installHomes [list]
    
    set install::time [now]
    set install_types [list SystemCode CorePackages Examples \
      Modes Menus BugFixes SharedLibs Completions Packages Home AlphatkCore \
      ExtensionsCode UserModifications UserPackages Alphatk \
      Help QuickStart Tools Tests Source \
      remove]
    set opts(-ignore) ""
    set opts(-forcequit) 0
    set opts(-require) ""
    foreach type $install_types {
	set opts(-$type) ""
    }
    getOpts [concat $install_types \
      [list changes provide ignore require rebuildquit forcequit]]
    
    set assigned ""
    foreach type $install_types {
	if {$opts(-$type) != ""} {
	    eval lappend assigned $opts(-$type)
	    set $type $opts(-$type)
	}
    }
    # check if package requires others:
    array set req $opts(-require)
    foreach pkg [array names req] {
	eval package::reqInstalledVersion [list $pkg] $req($pkg)
    }
    unset -nocomplain req
    unset opts(-require)
    # check on -provide option
    if {[info exists opts(-provide)]} {
	array set prov $opts(-provide)
	foreach pkg [array names prov] {
	    # check currently installed version isn't newer
	    if {![catch {alpha::package versions $pkg} v]} {
		switch -- [alpha::package vcompare $v $prov($pkg)] {
		    0 {
			alertnote "Package $pkg version $v is already\
			  installed. You may wish to cancel the installation."
		    }
		    1 {
			alertnote "This installer is for $pkg version\
			  $prov($pkg) but version $v is already\
			  installed. You may wish to cancel the\
			  installation."
		    }
		}
	    }
	}
	unset -nocomplain prov
	unset opts(-provide)
    }
    
    if {![install::canInstall]} {
	return 0
    }
    
    # check if package has over-ridden default
    global install::forcequit
    set install::forcequit $opts(-forcequit)
    unset -nocomplain opts(-rebuildquit)
    unset opts(-forcequit)
    # Now assume packages/modes are sub-dirs, completions are in the
    # Completions dir, and toplevels are obvious from their name.
    # (Mode, Menu, BugFixes or default is in Packages dir)
    
    # Create a dialog:
    if {$description == ""} {
	set description "I'll do a complete installation, placing all modes,\
	  menus, completions, help files, tools, extensions and packages\
	  in their correct locations.  In addition, any core bug fixes\
	  this package contains will be patched into\
	  Alpha's core Tcl code."
    }

    set encFrom [alpha::encodingFor $currD]
    if {$encFrom == ""} { set encFrom [encoding system] }
    set encTo [alpha::encodingFor $HOME]
    if {$encTo == ""} { set encTo [encoding system] }
    if {($encFrom ne $encTo)} {
	append description "\nEncodings will be converted\
	  from $encFrom to $encTo."
    }
    
    if {[info exists opts(-changes)]} {
	if {![string length [string trim $opts(-changes)]]} {
	    unset opts(-changes)
	}
    }

    set y 80
    set names [list "Easy Install" "Custom Install"]
    lappend dial -n [lindex $names 0]
    eval lappend dial \
      [dialog::text "$description" 15 y 55]
    incr y 10
    eval lappend dial \
      [dialog::checkbox "Backup removed files" 1 20 y]
    eval lappend dial \
      [dialog::checkbox "Show installation log" 1 20 y]
    eval lappend dial \
      [dialog::checkbox "Force overwrite, even of newer files" 0 20 y]
    incr y 22
    eval lappend dial \
      [dialog::text "Click OK to continue with the installation" 15 y]
    if {${install::forcequit}} {
	eval lappend dial \
	  [dialog::text "Alpha will quit after this installation." 15 y]
    }  
    set othery [expr {$y +10}]
    lappend dial -n [lindex $names 1]
    set y 60
    eval lappend dial \
      [dialog::checkbox "Backup removed files" 1 20 y]
    eval lappend dial \
      [dialog::checkbox "Show installation log" 1 20 y]
    eval lappend dial \
      [dialog::checkbox "Force overwrite, even of newer files" 0 20 y]
    incr y 5
    # Don't install MacOS invisible folder Icon files, if they
    # have been picked up, or some new MacOS X .DS_Store files.
    lappend opts(-ignore) "Iconm" "Icon" "Icon_" ".DS_Store"
    foreach item $items {
	if {[lsearch $opts(-ignore) $item] != -1 \
	  || [lsearch $assigned $item] != -1} {
	    continue
	}
	if {[string match *+*.tcl $item]} { 
	    lappend ExtensionsCode $item 
	} elseif {[regexp "SystemCode" $item]} { 
	    lappend SystemCode $item 
	} elseif {[regexp "Alphatk" $item]} { 
	    lappend Alphatk $item 
	} elseif {[regexp "AlphatkCore" $item]} { 
	    lappend AlphatkCore $item 
	} elseif {$item == "Changes" || [string match "Writing *" $item]} { 
	    lappend Help $item 
	} elseif {[regexp "(H|h)elp(/|:)?$" $item]} {
	    lappend Help $item 
	} elseif {[regexp -nocase "quick *start$" $item]} {
	    lappend QuickStart $item 
	} elseif {[regexp ".*Examples(/|:)?$" $item]} { 
	    lappend Examples $item 
	} elseif {[regexp "Modes(/|:)?$" $item]} { 
	    lappend Modes $item 
	} elseif {[regexp "Menus(/|:)?$" $item]} { 
	    lappend Menus $item 
	} elseif {[regexp -nocase "Support( Folder)?(/|:)?$" $item]} { 
	    lappend Support $item 
	} elseif {[regexp "Source" $item]} { 
	    lappend Source $item 
	} elseif {[regexp "Tests" $item]} { 
	    lappend Tests $item 
	} elseif {[regexp "Tools" $item]} { 
	    lappend Tools $item 
	} elseif {[regexp -nocase {mode(:|/|\.tcl)?$} $item]} { 
	    lappend Modes $item 
	} elseif {[regexp -nocase {menu(:|/|\.tcl)?$} $item]} { 
	    lappend Menus $item 
	} elseif {[regexp -nocase "bugfixes" $item]} {
	    lappend BugFixes $item
	} elseif {[regexp "Completions" $item]} {
	    lappend Completions $item
	} elseif {[regexp "User ?Packages" $item]} {
	    lappend UserPackages $item
	} elseif {[regexp "UserModifications" $item]} {
	    lappend UserModifications $item
	} elseif {[regexp "CorePackages" $item]} {
	    lappend CorePackages $item
	} elseif {[regexp ".shlb\$" $item]} {
	    lappend SharedLibs $item
	} elseif {[file exists [file join $HOME $item]] \
	  || [file exists [file join $SUPPORT(local) $item]] \
	  || [file exists [file join $SUPPORT(user) $item]]} {
	    lappend Home $item
	} else {
	    lappend Packages $item
	}
    }
    set x 20
    set continue 0
    foreach items $install_types {
	if {[info exists $items]} {
	    if {$continue} {
		set continue 0
		if {$y + 10 > $othery} { set othery [expr {$y +10}] }
		set y 100
		incr x 190
		eval lappend dial [dialog::text "continuedÉ" $x y]
	    }
	    if {$items != "remove"} {
		set t "Install $items"
	    } else {
		set t "Remove obsolete files"
	    }
	    eval lappend dial [dialog::text $t $x y]
	    foreach item [set $items] {
		lappend options [list $items $item]
		regsub "\[/:\]\$" $item " Ä" item
		eval lappend dial [dialog::checkbox $item 1 [expr {$x + 20}] y]
		if {$y > 360} {
		    set continue 1
		}
	    }
	}
    }
    incr y 10
    set h [expr {$othery > $y ? $othery : $y}]
    incr h 20
    set yb [expr {$h - 28}]
    set w 450
    if {$x > 100} {
	incr w [expr {$x - 100}]
    }
    set dials [list dialog -w $w -h $h]
    set y 10
    eval lappend dials [dialog::text "$pkgname installation options" 20 y 35]
    set butts [list "OK" [expr {$w -70}] yb "Cancel" [expr {$w -150}] y]
    set butIdx 2
    if {[info exists opts(-changes)]} {
	set changeIdx $butIdx
	incr butIdx
	lappend butts "Review Changes" [expr {$w -290}] y
    }
    if {[info exists ::install::usingThisFile]} {
	set viewIdx $butIdx
	incr butIdx
	lappend butts "Edit Install Script" 20 y
    }
    eval lappend dials [eval dialog::button $butts]
    set res [eval [concat $dials [list -m [concat \
      [list [lindex $names 0]] $names] 250 10 405 30]  $dial]]
    if {[lindex $res 1]} { 
	# cancel was pressed
	status::msg "Cancelled."
	return 0
    } elseif {[info exists changeIdx] && [lindex $res $changeIdx]} {
	# 'Review Changes' was pressed.
	dialog::alert $opts(-changes)
	# Now re-create the original dialog.
	return [eval [info level 1]]
    } elseif {[info exists viewIdx] && [lindex $res $viewIdx]} {
	# 'View Install Script' was pressed.
	return -code error "edit install script"
    }
    set res [concat [list 1 0] [lrange $res $butIdx end]]
    
    set easy_install [expr {1 - [lsearch $names [lindex $res 2]]}]
    if {$easy_install} {
	set make_backup [lindex $res 3]
	set make_log [lindex $res 4]
	set install::force_overwrite [lindex $res 5]
    } else {
	set make_backup [lindex $res 6]
	set make_log [lindex $res 7]
	set install::force_overwrite [lindex $res 8]
    }
    if {$make_backup} {
	global downloadFolder
	set make_backup [file join $downloadFolder \
	  "AlphaTcl InstallationBackup"]
    } else {
	set make_backup ""
    }
    # Set i to 8 because it is first incremented below,
    # so installation goes from 9 to end, if we're not
    # doing an easy install.
    set i 8
    global install::_ignore install::log install::nochanges
    set install::_ignore $opts(-ignore)
    set install::log ""
    set install::nochanges 1
    
    # Create list of install actions
    set install_actions [list]
    foreach o $options {
	incr i
	if {!$easy_install && ![lindex $res $i]} { continue }
	set type [lindex $o 0]
	set name [lindex $o 1]
	lappend install_actions [list $type $currD $name $make_backup]
    }
    
    # Find out if we install just for this user, or for all.
    set supportFolders [list]
    foreach domain [list "local" "user"] {
	if {($SUPPORT($domain) ne "") \
	  && [file writable [file join $SUPPORT($domain) AlphaTcl]]} {
	    lappend supportFolders [file join $SUPPORT($domain) AlphaTcl]
	}
    }
    if {![llength $supportFolders]} {
        set installHomes [list $HOME]
    } elseif {([llength $supportFolders] eq "1")} {
	set installHomes $supportFolders
    } else {
	set dialogScript [list dialog::make \
	  -title "Installation Location Options" \
	  -width 350 \
	  [list "" \
	  [list "text" "The files can be installed for all possible users\
	  of this system, or only in your personal Support Folders hierarchy,\
	  or in both locations.\r"] \
	  [list "flag" "Install for all users" "0"] \
	  [list "flag" "Install in personal account" "1"] \
	  ]]
	set results [eval $dialogScript]
	if {![lindex $results 0] && ![lindex $results 1]} {
	    error "Cancelled -- no installation locations chosen."
	}
	if {[lindex $results 0]} {
	    lappend installHomes [file join $SUPPORT(local) AlphaTcl]
	}
	if {[lindex $results 1]} {
	    lappend installHomes [file join $SUPPORT(user) AlphaTcl]
	}
    }

    # Re-order install actions so 'remove' items are first
    set remove_count 0
    while {1} {
	set found_remove 0
	set icount $remove_count
	for {} {$icount < [llength $install_actions]} {incr icount} {
	    set act [lindex $install_actions $icount]
	    if {[lindex $act 0] == "remove"} {
		set install_actions [concat [list $act] \
		  [lreplace $install_actions $icount $icount]]
		incr remove_count
		set found_remove 1
		break
	    }
	}
	# If we didn't re-order the list, we're done.
	if {!$found_remove} {
	    break
	}
    }
    
    # Now carry out installation
    foreach action $install_actions {
	status::msg "Installing [lindex $action 0] '[lindex $action 2]'"
	eval [list install::files] $action
    }
    
    unset install::_ignore
    if {${install::log} == ""} {
	alertnote "No changes were made.  You must have already\
	  installed this package."
	status::msg "No changes were made.  You must have already\
	  installed this package."
	return 0
    } else {
	if {$make_log} {
	    install::showLog
	} else {
	    unset install::log
	}
	return 1
    }
    
}

proc install::showLog {{title "Installation report"}} {
    global install::log
    new -g 0 160 640 300 -n $title -text "${install::log}End of report." \
      -read-only 1 -dirty 0
    unset install::log
}


# Install 'name' from $currD into where it should go	
# If 'name' ends in a colon, it's a directory.  We can just 
# use glob to get a list!
proc install::files {type from name backup} {
    global HOME PREFS smarterSourceFolder
    
    variable installHomes
    set fromname [file join $from $name]
    set isdir [file isdirectory $fromname]
    set isfile [file isfile $fromname]

    set flist [glob -nocomplain [file join $from [string trimright $name ":/"] *]]

    if {![llength $flist] && [file exists $fromname] && $isfile} {
	lappend flist $fromname
    }
    
    switch -- $type {
	Tests -
	Source {
	    set to [file join ${HOME} Developer $type]
	    foreach f $flist {
		install::file_to $f $to $backup
	    }
	}
	Tools {
	    set to [file join ${HOME} $type]
	    foreach f $flist {
		install::file_to $f $to $backup
	    }		
	}		
	remove {
	    if {![catch {file::standardFind $name} what]} {
		if {$isdir || [regexp "(/|:)\$" $name]} {
		    foreach f [glob -nocomplain -path $what *] {
			file::removeOne $f $backup
		    }
		    install::log "Removed dir: $name"
		    file delete $what
		} else {
		    file::removeOne $what $backup
		}
	    }
	}
	SystemCode -
	Modes -
	Menus - 
	Packages {
	    foreach home $installHomes {
		set to [file join $home Tcl $type]
		if {[install::_doWeInstallDir $isdir $name $type]} {
		    install::file_to $fromname $to
		    set to [file join $to [string trimright ${name} ":/"]]
		}
		foreach f $flist {
		    install::file_to $f $to $backup
		}		
	    } 
	}
	Support {
	    foreach home $installHomes {
		if {($home eq $HOME)} {
		    alertnote "No Support files were installed."
		    install::log "No Support Folder present for support files."
		    continue
		}
		set to [file join $home $name]
		if {[regexp -- "(.*)(/|:)\$" $name "" first] && ($first ne $type)} {
		    install::file_to $name $to
		    set to [file join $to [file dirname $name]]
		}
		foreach f $flist {
		    install::file_to $f $to $backup
		}		
	    }
	}
	UserPackages {
	    set to [file join $PREFS "User Packages"]
	    if {[install::_doWeInstallDir $isdir $name $type]} {
		install::file_to $fromname $to
		set to [file join $to [string trimright ${name} ":/"]]
	    }
	    foreach f $flist {
		install::file_to $f $to $backup
	    }		
	}
	Alphatk {
	    if {${alpha::platform} == "tk"} {
		set to [file dirname $HOME]
		if {[install::_doWeInstallDir $isdir $name $type]} {
		    install::file_to $fromname $to
		    set to [file join $to [file dirname $name]]
		}
		foreach f $flist {
		    install::file_to $f $to $backup
		    if {([file tail $f] == "alphatk.tcl") \
		      && ($::alpha::macos == 2)} {
			file copy -force [file join $to alphatk.tcl] \
			  [file join $to AppMain.tcl]
		    }
		}		
	    }
	}
	AlphatkCore {
	    if {${alpha::platform} == "tk"} {
		global ALPHATK
		set to $ALPHATK
		if {[install::_doWeInstallDir $isdir $name $type]} {
		    install::file_to $fromname $to
		    set to [file join $to [file dirname $name]]
		}
		foreach f $flist {
		    install::file_to $f $to $backup
		}
	    }
	}
	CorePackages {
	    foreach home $installHomes {
		set to [file join $home Tcl SystemCode CorePackages]
		if {[install::_doWeInstallDir $isdir $name $type]} {
		    install::file_to $fromname $to
		    set to [file join $to [file dirname $name]]
		}
		foreach f $flist {
		    install::file_to $f $to $backup
		}		
	    }
	}
	QuickStart {
	    foreach home $installHomes {
		set to [file join $home QuickStart]
		foreach f $flist {
		    install::file_to $f $to $backup
		    install::readAtStartup \
		      [file join $home QuickStart [file tail $f]]
		}		
	    }
	}
	Home {
	    foreach home $installHomes {
		set to [file join $home $name]
		if {[regexp -- "(.*)(/|:)\$" $name "" first] && ($first ne $type)} {
		    install::file_to $name $to
		    set to [file join $to [file dirname $name]]
		}
		foreach f $flist {
		    install::file_to $f $to $backup
		}		
	    }
	}
	SharedLibs {
	    foreach home $installHomes {
		set to $home
		foreach f $flist {
		    install::file_to $f $to $backup
		}		
	    }
	}
	Help {
	    foreach home $installHomes {
		set to [file join $home $type]
		foreach f $flist {
		    install::file_to $f $to $backup
		}		
	    }
	}
	Examples {
	    foreach home $installHomes {
		set to [file join $home $type]
		foreach f $flist {
		    install::file_to $f $to $backup
		}		
	    }
	}		
	BugFixes {
	    foreach f $flist {
		procs::patchOriginalsFromFile $f 0
		install::log "Installed patches from $f"
	    }
	}
	Completions {
	    foreach home $installHomes {
		set to [file join $home Tcl Completions]
		foreach f $flist {
		    install::file_to $f $to $backup
		}		
	    }
	}
	UserModifications {
	    foreach home $installHomes {
		set to [file join $home Tcl UserModifications]
		global install::noreplace
		set install::noreplace 1
		foreach f $flist {
		    install::file_to $f $to $backup
		}		
		set install::noreplace 0
	    }
	}		
	ExtensionsCode {
	    if {![info exists smarterSourceFolder]} {
		set smarterSourceFolder $PREFS
		alertnote "This installation contains extension\
		  (+.tcl) files.  These require\
		  the 'Smarter Source' package, which you do not have\
		  installed.  I've put the extension\
		  files in your prefs directory, but they will not operate\
		  without that package."
	    }
	    set to "$smarterSourceFolder"
	    foreach f $flist {
		install::file_to $f $to $backup
	    }
	}	
    }
    status::msg "File installation complete"
}

proc install::_doWeInstallDir {isdir name type} {
    if {$isdir && ($name ne $type)} {
	return 1
    }
    if {[regexp -- "(.*)(/|:)\$" $name "" first] && ($first ne $type)} {
	return 1
    }
    return 0
}

proc install::log {text} {
    global install::log install::nochanges
    append install::log "${text}\r"
    if {![string match "The pre-exist*" $text]} {
	set install::nochanges 0
    }
}

proc install::file_to {file to {backup ""}} {
    global HOME
    set tail [file tail $file]
    if {$tail == "Iconm"} {return}
    if {$tail == ".DS_Store"} {return}
    if {$tail == "CVS"} {
	install::log "Ignoring cvs directory 'CVS' in installer"
	return
    }
    if {[regexp -nocase {tutorial$} [file tail $file]]} {
	install::_file_to $file [file join $HOME Tcl Completions]
    } elseif {([regexp -nocase {help$} $tail] \
      && ![regexp (/|:)Help(/|:) $file]) \
      || ($tail == "Changes")} {
	install::_file_to $file [file join $HOME Help] $backup
    } elseif {[regexp {\+[0-9]*.tcl} $tail]} {
	global smarterSourceFolder PREFS
	if {![info exists smarterSourceFolder]} { 
	    set smarterSourceFolder $PREFS 
	}
	install::_file_to $file $smarterSourceFolder $backup
    } else {
	if {[file isdirectory $file] || [regexp "(/|:)\$" $file]} {
	    
	    set file [string trimright $file [file separator]]
	    set to [file join ${to} [file tail $file]]
	    if {[file exists $to]} {
		if {![file isdirectory $to]} {
		    install::log "Removed '$to' to make room for a\
		      directory with the same name"
		    file::remove [file dirname $to] \
		      [list [file tail $to]] $backup
		    file mkdir $to
		}
	    } else {
		file::ensureDirExists $to
	    }
	    foreach f [glob -nocomplain -dir $file *] {
		install::file_to $f $to $backup
	    }
	} else {
	    install::_file_to $file $to $backup
	}
    }
}

proc install::_file_to {file to {backup ""}} {
    global install::_ignore install::force_overwrite
    foreach suffix ${install::_ignore} {
	if {[string match *[file separator]${suffix} $file] \
	  || [string match ${suffix} $file]} {
	    return
	}
    }
    status::msg "Installing [file tail $file]"
    if {[file::ensureDirExists $to]} {
	install::log "Created dir '$to'"
    }
    if {[file isdirectory $file] || [regexp "(/|:)\$" $file]} {
	
	# Remove any trailing separator, so 'file tail' does the right
	# thing even in old versions of Tcl.
	set file [string trimright $file [file separator]]
	# Install a directory
	set todir [file join ${to} [file tail $file]]
	if {[file::ensureDirExists $todir]} {
	    install::log "Created dir '$todir'"
	}
	foreach f [glob -nocomplain -dir $file *] {
	    install::_file_to $f $todir $backup
	}
    } else {
	global install::noreplace
	
	set ff $file
	if {[info exists install::noreplace] && ${install::noreplace}} {
	    foreach suffix ${install::_ignore} {
		if {[string match *${suffix} $file]} { continue }
	    }
	    set f [file tail $ff]
	    if {![file exists [file join $to $f]]} {
		if {[file exists $ff]} {
		    file::coreCopy $ff [file join $to $f]
		    install::log "Copied '[file tail $ff]' to\
		      '[file join $to $f]'"
		}
	    }
	} else {
	    foreach suffix ${install::_ignore} {
		if {[string match *${suffix} $file]} { continue }
	    }
	    set f [file tail $ff]
	    
	    if {[regexp "tclIndexx?" [file tail $f]]} {
		return
	    }
	    
	    if {${install::force_overwrite}} {
		if {[file exists "$ff" ]} {
		    file::remove $to [list $f] $backup
		    file::coreCopy $ff [file join $to $f]
		    install::log "Overwrote from '[file tail $ff]'\
		      to '[file join $to $f]'"
		}
	    } else {
		file::replaceSecondIfOlder "$ff" [file join ${to} $f] 0 $backup
	    }
	}
    }
}

proc install::fromRemoteUrl {url} {
    # download the url
    set res [url::getAFile $url]

    # get type, local file name
    set type [lindex $res 0]
    set ff [lindex $res 1]

    if {![file exists $ff] || (![file writable $ff]) || (![file size $ff])} {
	dialog::alert "It looks like that application returned control to\
	  me before the download was complete (otherwise there was an error)\
	  -- probably Netscape/IE.\r\rWhen it's done, or if there was an error\
	  hit OK."
    }
    
    # Keep decompressing until we have the root
    while {1} {
	if {[file extension $ff] == ".tcl"} {
	    # Single file package
	    set f $ff
	    break
	}
	# decompress it
	status::msg "Trying to decompress $ff"
	if {[catch {file::decompress $ff} err]} {
	    if {[error::isCancel $err]} {
		alertnote "The decompression was cancelled.\
		  I'll open the file on your desktop."
	    } else {
		alertnote "There was an error while decompressing the\
		  file ($err).  I'll open it on your desktop."
	    }
	    file::showInFinder $ff
	    return
	}

	# parse out the folder, and remainder.
	set folder [file dirname $ff]
	set rest [file tail $ff]

	set f [file::tryToFindInFolder $folder $rest \
	  "*\[i|I\]{nstall,NSTALL}" "Select the installer"]
	if {![string length $f]} { return }
	set f [file join $f]
	
	if {[info exists lastf]} {
	    if {$lastf eq $f} {
		break
	    }
	}
	
	if {[file::iscompressed $f]} {
	    set lastf $f
	    set ff $f
	} else {
	    break
	}
    }
    
    edit -c $f
    # If this wasn't auto-installed by the 'edit' command
    # (in which case the window would have been killed already)
    if {[win::Current] eq $f} {
	global mode
	if {$mode != "Inst"} {
	    alertnote "I don't know what to do with this package from here."
	} else {
	    if {[dialog::yesno "You can install this extension from\
	      the install menu.\rShall I do that for you?"]} {
		install::installThisPackage $f
	    }
	}
    }
}
