## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "backup.tcl"
 #                                          created: 10/17/2000 {12:50:44 PM}
 #                                      last update: 06/02/2006 {01:36:59 PM}
 #  
 # Author: Mostly Vince and Johan
 #  
 # All backup related material is now in this one file, so if you want to
 # modify things (to provide for saving of multiple backups, for instance),
 # there's no need to search through all of AlphaTcl.
 #  
 # Note: the 'activateBackup' procedure assumes the existence of $name's
 # "Modified" attribute is equivalent to checking whether the window
 # 'name' has been saved to disk.  This is true except perhaps for some
 # weird situations where the file exists on disk but we can't use
 # 'file mtime' to get modification information from the file.
 # 
 # Distributed under a Tcl style license.  
 # 
 # ==========================================================================
 ##

alpha::declare flag backup 0.2.0 global {
    # Make a backup every time a file is saved, in either the active file's
    # folder or a specified "Backup Folder" location\
    newPref flag backup 0
    # Folder in which to store backups.  A null value tells Alpha to use
    # the file's current directory.
    newPref var backupFolder ""
    # Extension to add to files when backing them up
    newPref var backupExtension "~"
    # If the previous backup is more recent than this number of hours,
    # then don't make a new backup.  If greater than zero, this means the 
    # backups Alpha has tend to be significantly different to the current file.
    newPref var backupAgeRequirementInHours 0.0
    # If a file is larger than this number of kilobytes, do not save
    # a backup copy.  This allows you to avoid creating backups for
    # extremely large files.  If this setting takes the value 0 it is
    # ignored.
    newPref var maximumBackupFileSize 0
    set backup 0
    lunion flagPrefs(Backups) backup
    lunion varPrefs(Backups) backupFolder backupExtension\
      backupAgeRequirementInHours maximumBackupFileSize
} {
    set backup 1
    menu::replaceWith File "revertToSaved" items "<E<SrevertToSaved" "<S<IrevertToBackupÉ"
    hook::register saveHook backupOnSave
    hook::register requireOpenWindowsHook [list File revertToBackupÉ] 1
    hook::register activateHook activateBackup
} {
    set backup 0
    menu::removeFrom File "revertToSaved" items "<E<SrevertToSaved" "<S<IrevertToBackupÉ"
    hook::deregister saveHook backupOnSave
    hook::deregister requireOpenWindowsHook [list File revertToBackupÉ] 1
    hook::deregister activateHook activateBackup
} { 
    # off
} description {
    Makes copies of old versions of saved files (appending a tilde to the name)
} help {
    Alpha can automatically make a backup copy for you of the old version of a
    file whenever you save changes.  This is done if you check 'Backup' in the
    preferences dialog "Config > Preferences > Input-Output".
    
    Preferences: Backups
    
    By default the backup file is saved in the same folder, and its name is
    formed by suffixing a tilde to the name of the saved file.  The backup
    behavior can be modified by changing the following preferences found in
    the same dialog pane:

	Backup              

    Check this if you want Alpha to make backups.

	Backup Folder       

    The folder where to save the backups.  If none specified the backups are
    saved in the same folder as the original.

	Backup Extension    

    The extension to add to name of the backup file.  Don't pick a long
    extension!  Depending on the filesystem in use, the complete file 
    name may not be allowed to exceed 31 characters.

	Backup Age Requirement In Hours     

    A new backup file is only created if the old backup file is older than
    this.
    
    If you have chosen a backup folder and want to go back to the default
    behavior of saving the backup in the document's folder, follow these
    steps:

    (1) Delete or rename the backup folder. 
    (2) Save a window.  Alpha will then ask you if you want to create the
        backup folder.  If you answer 'No' Alpha will revert to the default
        behavior.
}

proc backup.tcl {} {}

proc activateBackup {name} {
    enableMenuItem File revertToBackupÉ [expr {[backupFileExists \
      [win::StripCount $name]] && [win::infoExists $name Modified]}]
}

proc backupOnSave {name} {
    global backup backupExtension backupFolder \
      backupAgeRequirementInHours maximumBackupFileSize

    set realname $name
    if { ![file exists $name] } {
	set name [win::StripCount $name]
    }
    
    if {$backup} {
	set fileSize [file size $name]
	# Don't backup empty files:
	if { !$fileSize } {
	    return
	}
	# Don't back up too large files (according to pref):
	if {$maximumBackupFileSize != 0} {
	    if {$fileSize > (1024*$maximumBackupFileSize)} {
		status::msg "No backup, since file is larger than\
		  ${maximumBackupFileSize}kb"
		return
	    }
	}
	
	# Check the backup preferences and fix them if invalid:
	if {$backupFolder != "" && ![file exists $backupFolder]} {
	    if {![dialog::yesno "Create backup folder '$backupFolder'?"]} {
		alertnote "Backup saved in document's folder."
		set backupFolder ""
		prefs::modified backupFolder
	    } elseif {[catch {file::ensureDirExists $backupFolder}]} {
		alertnote "Couldn't create backup folder.\
		  Backup saved in document's folder."
		set backupFolder ""
		prefs::modified backupFolder
	    }
	}
	# (*) Don't allow empty extension if the backup folder is 
	# the current folder --- we don't want to overwrite originals 
	# with backups:
	if {$backupExtension == "" && $backupFolder == ""} {
	    set backupExtension ~
	    prefs::modified backupExtension
	}

	# Find out where to put the backup:
	# If no backup folder specified, use current folder:
	set dir $backupFolder
	if {![string length $dir]} {
	    set dir [file dirname $name]
	}
	set backfile [file join $dir [file tail $name]$backupExtension]
	# The user might be so perverse as to edit a file in the backup folder
	# while at the same time using a null backup extension!  (This case
	# was not caught in the above check (*))...
	if {$backupExtension == "" && [file dirname $name] eq $backupFolder} {
	    #Ê...in that case we force an extension:
	    append backfile ~
	}
	# Remark: one could wonder if those two extension checks could be 
	# performed in one go, by doing things in a smart order, but note
	# that in the (*) case there is a permanent problem and we have to
	# correct it in the prefs.  In ther second case we are dealing with
	# a temporary coincidence
	
	# Conclusion of the above:  by now we are absolutely sure that
	# $name and $backfile are two different file(names).
	
	# If there is already a backup...
	if {[file exists $backfile]} {
	    # ...which is relatively new...
	    if { [clock seconds] - [file mtime $backfile] < \
	      3600 * $backupAgeRequirementInHours } {
		# ...then don't do anything:
		return
	    }
	}
	# Perform the actual backup:
	if {[catch {file copy -force $name $backfile}]} {
	    status::msg "Failed to backup $name to $backfile"
	} else {
	    if {$::alpha::macos} {
		# May wish to use 'file attributes' instead?
		setFileInfo $backfile type TEXT
		setFileInfo $backfile creator \
		  [expr {$::alpha::platform == "alpha" ? "ALFA" : "AlTk"}]
	    }
	    status::msg "Backed up $backfile"
	}
	
    }
    activateBackup $realname
}

namespace eval file {}

proc file::revertToBackup {} {
    global backupExtension backupFolder

    set fname [win::StripCount [win::Current]]
    set dir $backupFolder
    if {$dir == ""} {
        set dir [file dirname $fname]
    }
    set bname [file join $dir "[file tail $fname]$backupExtension"]
    if {![file exists $bname]} {
        beep
	status::msg "Backup file '$bname' does not exist"
        return
    }

    # The backup was created with 'file copy' so it should have
    # the same encoding as the current window, and this is the only
    # way to know what that encoding was (i.e. the backups directory
    # will contain lots of files in many different encodings).
    set encoding [win::Encoding $fname]
    
    if {[dialog::yesno -y "Revert" -n "Preview backup" -c \
      "Revert to backup dated '[join [mtime [file mtime $bname]]]'?"]} {
        killWindow
        edit -encoding $encoding $bname
        saveAs -f $fname
    } else {
	alpha::registerEncodingFor $bname $encoding
	file::openAsTemplate $bname
	alpha::deregisterEncodingFor $bname
    }
}

proc backupFileExists {name} {
    global backupExtension backupFolder

    set dir $backupFolder
    if {$dir == ""} {
        set dir [file dirname $name]
    }
    set bname [file join $dir "[file tail $name]$backupExtension"]
    return [file exists $bname]
}
