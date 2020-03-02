## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "smarterSource.tcl"
 #                                          created: 10/18/1995 {06:00:07 pm}
 #                                      last update: 02/21/2006 {02:45:35 PM} 
 # Description:
 #  
 # Changes default directory to a user specified directory. 
 # 
 # Files in PREFS are passed through unchanged.  Passes through 'tclIndex(x)'
 # and 'prefs.tcl' unchanged.
 # 
 # BASED UPON 'smartSource.tcl': Copyright 1994-2006, Robert Browning
 # (osiris@cs.utexas.edu): This code is made freely available to anyone who
 # can find a use for it.  Consider it part of my thanks to all those who
 # have contributed to the freeware and shareware base.  (Especially Pete
 # Keheler, without which this code would be pretty useless).
 # 
 # ==========================================================================
 ##

alpha::feature smarterSource 1.0 global-only {
    # Pref was renamed in Oct 2003
    if {[info exists tclExtensionsFolder]} {
	prefs::renameOld tclExtensionsFolder smarterSourceFolder
    }
    # one-off init script
    lunion varPrefs(Files) smarterSourceFolder
    # location in which smarterSource looks for extension files
    newPref earlyfolder smarterSourceFolder $PREFS "global" \
      {smarterSource::folderChanged}
    prefs::updateHome smarterSourceFolder
    if {($smarterSourceFolder ne $PREFS)} {
	if {![file exists $smarterSourceFolder]} {
	    set y "Continue"
	    set n "Open Prefs Dialog"
	    set msg "The 'Smarter Source Folder' \"$smarterSourceFolder\"\
	      you set for the Smarter Source extension doesn't appear to exist.\
	      You should set this in the 'Input-Output Preferences > Files'\
	      preferences page."
	    if {![dialog::yesno -y $y -n $n $msg]} {
		catch {prefs::dialogs::globalPrefs "Files"}
	    }
	    unset y n msg
	}
	if {$alpha::macos} {
	    # In Alpha 8/X, since encodings aren't really supported, the user
	    # will be editing all files in macRoman, which means we must
	    # force AlphaTcl to source them in macRoman too.  In Alphatk
	    # there's no need to force macRoman on the user, but some users
	    # want to share their smarter source folder between Alpha X/tk,
	    # so we force this there as well.
	    alpha::registerEncodingFor $smarterSourceFolder macRoman
	}
    }
    namespace eval smarterSource {}
    # This is the "trace proc" called when the user has changed the location 
    # of the "smarterSourceFolder" preference.
    ;proc smarterSource::folderChanged {args} {
	set q "When you change your Smarter Source folder, you should\
	  rebuild package indices.  Would you like more information?"
	if {[askyesno $q]} {
	    catch {menu::packagesProc "Packages" "rebuildPackageIndices"}
	}
	return
    }
    # Smarter Source version of [alpha::useFilesFor].  This should _never_
    # throw an error.  "args" is included only for future back compatibility
    # purposes, in case we decide to include additional arguments.
    ;proc smarterSource::useFilesFor {filename args} {
	global smarterSourceFolder HOME SUPPORT
	
	if {([file tail $filename] eq "tclIndex")} {
	    # We don't want to over-ride these files.
	    set keepLooking 0
	} elseif {[file::pathStartsWith $filename \
	  [file join $HOME Tcl] relName]} {
	    # File is in the standard AlphaTcl hierarchy.
	    set keepLooking 1
	} elseif {($SUPPORT(local) ne "") && [file isdir $SUPPORT(local)] \
	  && [file::pathStartsWith $filename \
	  [file join $SUPPORT(local) AlphaTcl Tcl] relName]} {
	    # The $SUPPORT(local) directory contains a version of this file.
	    set keepLooking 1
	} elseif {($SUPPORT(user) ne "") && [file isdir $SUPPORT(user)] \
	  && [file::pathStartsWith $filename \
	  [file join $SUPPORT(user) AlphaTcl Tcl] relName]} {
	    # The $SUPPORT(user) directory contains a version of this file.
	    set keepLooking 1
	} else {
	    set keepLooking 0
	}
	if {!$keepLooking} {
	    return [hook::procOriginal "::smarterSource::useFilesFor" $filename]
	}
	# Now we set "filename" to be the path found by the default version
	# of [alpha::useFilesFor] so that any user or sysadmin modifications
	# will still be in affect if we don't find a suitable over-ride.  We
	# could, however, comment this out if we wanted Smarter Source
	# activation to also mean that we explicitly ignore any of these
	# SUPPORT files.
	set filename [lindex \
	  [hook::procOriginal "::smarterSource::useFilesFor" $filename] 0]
	set relName [file join "Tcl" $relName]
	# Now wish to scan from $smart/file.tcl to $smart/dir/file.tcl to
	# $smart/Tcl/Modes/.../file.tcl in order.  We also look for +*.tcl
	# files.  The first time we find something, we stop.  If we haven't
	# found a synonym of the original file we must then of course use the
	# original file (and any + files found).
	set fileList [list]
	set hasSynonym 0
	set elements [file split $relName]
	for {set i 0} {$i < [llength $elements]} {incr i} {
	    set overrideFile [eval [list file join $smarterSourceFolder] \
	      [lrange $elements end-$i end]]

	    if {[file exists $overrideFile] && [file readable $overrideFile]} {
		lappend fileList $overrideFile
		set hasSynonym 1
	    }
	    set rootName [file root $overrideFile]+
	    set pattern  "*[file extension $relName]"
	    foreach extraFile [glob -nocomplain -path $rootName $pattern] {
		if {[file readable $extraFile]} {
		    lappend fileList $extraFile
		}
	    }
	    if {[llength $fileList]} {
		break
	    }
	}
	if {!$hasSynonym} {
	    set fileList [linsert $fileList 0 $filename]
	}
	return $fileList
    }
} {
    # Activation script.
    hook::procRename "::alpha::useFilesFor" "::smarterSource::useFilesFor"
    # Alerts other code as to our current status.
    set smarterSourceStatus 1
} {
    # De-activation script.
    hook::procRevert "::smarterSource::useFilesFor"
    set smarterSourceStatus 0
} uninstall {
    this-file
} description {
    This package helps you alter ÇALPHAÈ's behavior without directly
    modifying AlphaTcl source code files.  It provides a more sophisticated
    and installation-specific version of the Support Folders "Smart Source"
    functionality
} help {
    file "Smarter Source Help"

}

# ===========================================================================
# 
# .