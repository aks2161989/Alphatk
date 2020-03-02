## -*-Tcl-*-
 # ==========================================================================
 #  Ftp Menu -- an extension package for Alpha
 # 
 #  FILE: "ftpMenu.tcl"
 #                                          created: 04/15/2001 {04:25:14 PM}
 #                                      last update: 03/01/2006 {03:15:26 PM}
 #  
 #  Description: 
 #  
 #  Creates an Ftp Menu in Alpha allowing the user to browse remote sites,
 #  saving them as 'mount points' for later use.  Also allows for the
 #  creation of ftp filesets.
 # 
 #  Note:
 #  
 #  Since all of the ftp namespace procs in the 'ftp.tcl' file in the tcllib
 #  all begin with a cap letter, as in ftp::DisplayMsg, none of the procs
 #  here should be in any danger of re-writing them.
 #  
 # --------------------------------------------------------------------------
 # 
 # Redistribution and use in source and binary forms, with or without
 # modification, are permitted provided that the following conditions are met:
 # 
 #  ¥ Redistributions of source code must retain the above copyright
 #    notice, this list of conditions and the following disclaimer.
 # 
 #  ¥ Redistributions in binary form must reproduce the above copyright
 #    notice, this list of conditions and the following disclaimer in the
 #    documentation and/or other materials provided with the distribution.
 # 
 #  ¥ Neither the name of Alpha/Alphatk nor the names of its contributors may
 #    be used to endorse or promote products derived from this software
 #    without specific prior written permission.
 # 
 # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 # AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 # IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 # ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR
 # ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 # DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 # SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 # CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 # LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 # OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 # DAMAGE.
 # 
 # ==========================================================================
 ##

alpha::menu ftpMenu 1.1.3 global "¥141" {
    # Initialization script.
    
    ftp::buildMenu
    
    set {newDocTypes(New Ftp Connection)} file::openRemote
} {
    # Activation script.
    ftpMenu
} {
    # Deactivation script.
} uninstall {
    this-file
} description {
    Accesses files from a remote ftp server for editing
} help {
    file "FTP menu Help"
} preinit {
    fileset::registerNewType ftp "list"
}

proc ftpMenu.tcl {} {}

proc ftpMenu {} {}

# Make sure that some global vars exist.

ensureset ftpUseCache     1
ensureset lastMountPoint  ""

# This enables opening mount points from the 'File' menu.

namespace eval file {}

proc file::openRemote {} {

    if {![llength [set mounts [ftp::listMounts]]]} {
	set args [lrange [dialog::ftpLogin {Browse remote machine:} 0] 0 3]
	eval ftp::browse $args
	return
    }

    global recentMounts savedMounts
	
    set res [listpick -p "Mount point:" [lappend mounts "New connectionÉ"]]
    if {$res == "New connectionÉ"} {
	ftp::menuProc "" "browseRemote"
    } elseif {[info exists recentMounts($res)]} {
	eval ftp::browse $recentMounts($res)
    } elseif {[info exists savedMounts($res)]} {
	eval ftp::browse $savedMounts($res)
    } else {
	error "Cancelled -- couldn't browse '$res'."
    }
}

# This probably should go in www.tcl.  

namespace eval dialog {}

## 
 # -------------------------------------------------------------------------
 # 
 # "dialog::ftpLogin" --
 # 
 #  Creates a dialog allowing the user to enter remote site info.  'nm'
 #  indicates that the 'Name' text field should also appear with the default
 #  value of 'which', in case the info is going to be stored in a user
 #  chosen array name.  (We include both in case we want a 'name' field, but
 #  there is no default value to give ...)  'args' contains the remaining
 #  text field defaults, can include 'host' 'path' 'userID' 'password', any
 #  or all of which can be empty.
 #  
 # -------------------------------------------------------------------------
 ##
proc dialog::ftpLogin {{title ""} {nm 1} {which ""} args} {

    if {![string length $title]} {set title "All but 'password' are required"}
    # Set dialog size parameters.
    set left    10
    set right  100
    set top     10
    set bottom  30
    set eleft  [expr $left + 100]
    set eright 370
    set incr    30
    set height 204
    
    if {$nm} {incr height $incr}
    set l "dialog -w 400 -h $height -t [list $title] $left $top 400 $bottom"
    
    # Add text fields.

    # Name:
    if {$nm} {
	incr top $incr
	incr bottom $incr
	lappend l -t {Name:}        $left $top  $right $bottom
	lappend l -e $which        $eleft $top $eright $bottom
    }
    # Host:
    incr top $incr
    incr bottom $incr
    lappend l -t {Host:}           $left $top  $right $bottom
    lappend l -e [lindex $args 0] $eleft $top $eright $bottom
    # Path:
    incr top $incr
    incr bottom $incr
    lappend l -t {Path:}           $left $top  $right $bottom
    lappend l -e [lindex $args 1] $eleft $top $eright $bottom
    # User ID:
    incr top $incr
    incr bottom $incr
    lappend l -t {UserID:}         $left $top  $right $bottom
    lappend l -e [lindex $args 2] $eleft $top $eright $bottom
    # Password:
    incr top $incr
    incr bottom $incr
    lappend l -t {Password:}       $left $top  $right $bottom
    lappend l -e [lindex $args 3] $eleft [expr $top + 6] \
					      $eright [expr $bottom - 12]
    # Buttons
    incr top     [expr $incr + 10]
    incr bottom  [expr $incr + 10]
    eval lappend l [dialog::okcancel -380 top]
    
    # Now present the dialog, return the results if not cancelled.
    set res [eval "$l"]
    if {[lindex $res end]} {
	error "cancel"
    }
    return  [lrange $res 0 [expr {[llength $res] - 3}]]
}

# ×××× ---- ×××× #

# ×××× Ftp Menu, Support ×××× #

namespace eval ftp {}

# This isn't really necessary, but allows for the menu to be rebuilt using
# menu::buildSome.

menu::buildProc ftpMenu ftp::buildMenu

proc ftp::buildMenu {} {
    
    global savedMounts recentMounts ftpMenu ftpUseCache
    
    Menu -n $ftpMenu -p ftp::menuProc {
	<S/ibrowseRemoteÉ
	<S/i<IbrowseCurrentÉ
	/nbrowseMountsÉ
	{Menu -n ftpMenuUtils -p ftp::menuProc {
	    addMountPointÉ
	    editMountPointÉ
	    renameMountPointÉ
	    removeMountPointÉ
	    makePermanentÉ
	    createFtpFilesetÉ
	    "(-)"
	    setDefaultsÉ
	    useCache
	    flushCache
	    forgetTemp.Passwords
	}}
	ftpMenuHelp
	"(-)"
	saveAsAtÉ
	saveACopyAtÉ
	"(-)"
    }
    # Add all of the mount points.
    set addCode ""

    if {[llength [array names savedMounts]]} {
	foreach m [lsort -dictionary [array names savedMounts]] {
	    addMenuItem -m -l $addCode $ftpMenu $m
	}
    }
    if {[llength [array names recentMounts]]} {
	addMenuItem -m $ftpMenu "\(-"
	foreach m [lsort -dictionary [array names recentMounts]] {
	    addMenuItem -m -l $addCode $ftpMenu $m
	}
    }
    ftp::postEval
}

proc ftp::postEval {args} {
    
    global savedMounts recentMounts tmpFtpPasswords ftpMenu ftpUseCache
    
    # Mark or dim as necessary.  These are all pretty quick.
    
    set dim1 [expr [llength [ftp::listMounts]] ? 1 : 0]
    set dim2 [expr [llength [array names savedMounts]] ? 1 : 0]
    set dim3 [expr [llength [array names recentMounts]] ? 1 : 0]
    set dim4 [expr [llength [array names tmpFtpPasswords]] ? 1 : 0]

    foreach item {browseCurrentÉ browseMountsÉ saveAsAtÉ saveACopyAtÉ} {
	enableMenuItem $ftpMenu $item $dim1
    }
    foreach item {editMountPointÉ removeMountPointÉ renameMountPointÉ} {
	enableMenuItem ftpMenuUtils $item $dim2
    }
    foreach item {makePermanentÉ} {
	enableMenuItem ftpMenuUtils $item $dim3
    }
    enableMenuItem ftpMenuUtils "forgetTemp.Passwords" $dim4
    markMenuItem   ftpMenuUtils "useCache" $ftpUseCache
}

proc ftp::menuProc {menu item} {

    global savedMounts recentMounts fetched ftpMenu useFtpEolType 
    global lastMountPoint tmpFtpPasswords ftpDefaults

    switch -- $item {
	ftpMenuHelp  {package::helpWindow "ftpMenu"}
	browseRemote {
	    eval ftp::browse [lrange \
	      [ftp::getLogin {Browse remote ftp site:} 0] 0 3]
	}
	browseCurrent { 
	    if {[info exists fetched([win::Current])]} {
		eval ftp::browse $fetched([win::Current]) 
	    } else {
		beep; status::msg "'[win::CurrentTail]' not from remote host."
	    }
	}
	browseMounts {
	    set mounts [ftp::listMounts all 0]
	    if {[catch {listpick -p "Mount point:" $mounts} res]} {
		error "cancel"
	    } 
	    if {[info exists recentMounts($res)]} {
		eval ftp::browse $recentMounts($res)
	    } elseif {[info exists savedMounts($res)]} {
		eval ftp::browse $savedMounts($res)
	    } else {
	        error "Cancelled -- couldn't browse '$res'."
	    }
	}
	addMountPoint {
	    set addAnother 1
	    while {$addAnother} {
		set res [ftp::getLogin {All but 'password' are required:} 1 $lastMountPoint]
		set point [lindex $res 0]
		set savedMounts($point) [concat [lrange $res 1 4] "ftp"]
		prefs::modified savedMounts($point)
		ftp::buildMenu
		status::msg "The ftp mount point '$point' has been saved."
		set question "Would you like to add another mount point?"
		set addAnother [dialog::yesno $question]
	    }
	}
	editMountPoint {
	    set mounts [ftp::listMounts saved 0]
	    set p "Select a mount point to edit:" 
	    while {![catch {listpick -p $p $mounts} res]} {
		if {![string length $res]} {
		    error "cancel"
		}
		set nres [ftp::getLogin "Edit '$res' mount point" 0 $res]
		set savedMounts($res) [concat [lrange $nres 0 3] "ftp"]
		prefs::modified savedMounts($res)
		status::msg "New settings for '$res' have been saved."
		set p "Edit another, or press cancel:" 
	    }
	}
	renameMountPoint {
	    set mounts [ftp::listMounts saved 0]
	    set p1 "Select a mount point to rename" 
	    while {![catch {listpick -p $p1 $mounts} res] && [llength $res]} {
		set p2 "New name for '$res'"
		if {[catch {prompt $p2 $res} newName]} {
		    error "cancel"
		} 
		set savedMounts($newName) $savedMounts($res)
		prefs::modified savedMounts($res)
		unset savedMounts($res)
		prefs::modified savedMounts($newName)
		ftp::buildMenu
		status::msg "'$res' mount point has been renamed '$newName'."
		set mounts [ftp::listMounts saved 0]
		set p1 "Select another, or press cancel:" 
	    }
	}
	removeMountPoint {
	    set mounts [ftp::listMounts saved 0]
	    set p "Remove which mount points?"
	    if {[catch {listpick -l -p $p $mounts} res] || ![llength $res]} {
		error "cancel"
	    }
	    foreach point $res {
		prefs::modified savedMounts($point)
		catch {unset savedMounts($point)}
	    } 
	    ftp::buildMenu
	    if {[llength $res] > 1} {
		status::msg "$res ftp mount points have been removed."
	    } else {
		status::msg "$res ftp mount point has been removed."
	    }
	}
	makePermanent {
	    set mounts [ftp::listMounts recent 0]
	    set p "Make which temporary mount points permanent?"
	    if {[llength $mounts] == "1"} {
		if {[dialog::yesno "Make '[array names recentMounts]' permanent?"]} {
		    set res $mounts
		} else {
		    error "cancel"
		}
	    } elseif {[catch {listpick -l -p $p $mounts} res]} {
		error "cancel"
	    }
	    set names ""
	    foreach point $res {
		set p "Save '$point' mount point asÉ"
		if {![catch {prompt $p $point} newName]} {
		    set savedMounts($newName) $recentMounts($point)
		    unset recentMounts($point)
		    prefs::modified savedMounts($newName)
		    status::msg "The ftp mount point '$newName' has been saved."
		    lappend names $newName
		} 
	    }
	    ftp::buildMenu
	    if {![llength $names]} {
		error "cancel"
	    } elseif {[llength $names] == "1"} {
		status::msg "The ftp mount point '$names' has been saved."
	    } else {
		status::msg "The ftp mount points \"[join $names ", "]\"\
		  have been saved."
	    }
	}
	createFtpFileset {newFileset ftp}
	setDefaults { 
	    set p "Enter defaults that you wish saved:"
	    set ftpDefaults [lrange [ftp::getLogin $p 0] 0 3]
	    prefs::modified ftpDefaults
	    set lastMountPoint ""
	    status::msg "Ftp mount point defaults have been saved."
	}
	useCache {
	    global ftpUseCache
	    set ftpUseCache [expr {1 - $ftpUseCache}]
	    markMenuItem ftpMenuUtils "useCache" $ftpUseCache
	    prefs::modified ftpUseCache
	    if {$ftpUseCache} {
		status::msg "The 'Use Cache' preference is now on."
	    } else {
		status::msg "The 'Use Cache' preference is now off."
	    } 
	}
	flushCache {
	    set okToClean 1
	    foreach w [winNames -f] {
		if {[temp::isIn ftptmp $w]} {
		    set okToClean [dialog::yesno "Some open windows are stored\
		      in the cache.  If you flush the cache these windows will\
		      deleted from the disk and will not be uploaded when you\
		      save them.\rDo you want to flush the cache?"]
		    break
		}
	    }
	    if {$okToClean} {
		temp::cleanup ftptmp
		unset -nocomplain recentMounts
		ftp::buildMenu 
		status::msg "The ftp cache has been flushed."
	    } else {
	        status::msg "Cancelled."
	    }
	}
	forgetTemp.Passwords {
	    unset -nocomplain tmpFtpPasswords
	    ftp::postEval
	    status::msg "Temporary ftp passwords have been forgotten."
	}
	saveAsAt {
	    set mounts [ftp::listMounts all 0]
	    set name   [prompt "Save As:" [win::StripCount [win::CurrentTail]]]
	    if {[catch {listpick -p "At which mount point?" $mounts} point]} {
		error "cancel"
	    } 
	    if {[info exists recentMounts($point)]} {
		set specs $recentMounts($point)
	    } elseif {[info exists savedMounts($point)]} {
		set specs $savedMounts($point)
	    } else {
	        error "Cancelled -- couldn't save at '$point'."
	    }
	    set name [temp::path ftptmp [lindex $specs 0] [lindex $specs 1] $name]
	    set name [file nativename $name]
	    status::msg "Saving '$name' on [lindex $specs 0]É"
	    
	    saveAs -f "$name"
	    set name [win::Current]
	    set fetched($name) $specs
	    
	    set nm [temp::generate ftptmp listing [lindex $specs 1]]
	    catch {file delete $nm}
	    
	    if {$useFtpEolType != "auto"} {
		setWinInfo platform $useFtpEolType
	    }
	    setWinInfo dirty 1
	    save
	}
	saveACopyAt {
	    if {![file exists [win::StripCount [win::Current]]]} {
		error "Cancelled -- window must first be saved."
	    } 
	    set mounts [ftp::listMounts all 0]
	    set name   [prompt "Save A Copy As:" [win::StripCount [win::CurrentTail]]]
	    if {[catch {listpick -p "At which mount point?" $mounts} point]} {
		error "cancel"
	    } 
	    if {[info exists recentMounts($point)]} {
		set specs $recentMounts($point)
	    } elseif {[info exists savedMounts($point)]} {
		set specs $savedMounts($point)
	    } else {
		error "Cancelled -- couldn't save at '$point'."
	    }
	    set name [temp::path ftptmp [lindex $specs 0] [lindex $specs 1] $name]
	    set name [file nativename $name]
	    set fetched($name) $specs

	    if {[file exists $name]} {file delete $name}
	    file copy [win::StripCount [win::Current]] $name
	    ftp::postHook $name
	    unset fetched($name)
	}
	default {
	    if {[info exists recentMounts($item)]} {
		eval ftp::browse $recentMounts($item)
	    } elseif {[info exists savedMounts($item)]} {
		eval ftp::browse $savedMounts($item)
	    } else {
	        error "Cancelled -- can't find any information for '$item'."
	    }
	}
    }
}

proc ftp::listMounts {{which "all"} {quietly "1"}} {

    global savedMounts recentMounts
    
    if {$which == "all"} {
        set mountsToList [list savedMounts recentMounts]
    } else {
        set mountsToList [list ${which}Mounts]
    }
    set result ""
    foreach arrayName $mountsToList {
	eval lappend result [array names $arrayName]
    }
    if {!$quietly && ![llength $result]} {
        # Whatever menu item called this should have been dimmed.
	ftp::postEval
	set which [join [split $which] " or "]
	error "Cancelled -- there are no join $which mounts to list."
    } else {
        return [lsort -dictionary $result]
    }
}

proc ftp::getLogin {{title ""} {nm 1} {which ""}} {

    global ftpDefaults savedMounts lastMountPoint

    # Determine any possible text field defaults.
    if {[info exists savedMounts($which)]} {
	set defs $savedMounts($which)
    } elseif {[info exists savedMounts($lastMountPoint)]} {
	set defs $savedMounts($lastMountPoint)
    } elseif {[info exists ftpDefaults]} {
	set defs $ftpDefaults
    } else {
	set defs ""
    }
    set result [eval dialog::ftpLogin [list $title $nm $which] $defs]
    if {$nm} {set lastMountPoint [lindex $result 0]} 
    return $result
}

proc ftp::browse {host dir user password {type "ftp"} {fname {}}} {
    
    global fetched lastFtpDir recentMounts savedMounts 
    global ftpUseCache ftpBrowseVars tmpFtpPasswords
    
    if {![string length $password]} {
	if {![info exists tmpFtpPasswords("${user}@$host")]} {
	set password [dialog::password "Password for ${host}:"]
	    set tmpFtpPasswords("${user}@$host") $password
	    ftp::postEval
	} else {
	    set password $tmpFtpPasswords("${user}@$host")
	}
    }
    
    if {$dir == {-}} {
	if {![info exists lastFtpDir] || ![string length $lastFtpDir]} {
	    set lastFtpDir ""
	}
	set dir [prompt "'$host' dir:" $lastFtpDir]
    }
    set dir [string trimright $dir {/}]
    set lastFtpDir $dir
  
    status::msg "Browsing host $hostÉ"
    
    set nm [temp::generate ftptmp listing [join [list $host $user $dir] ""]]
    set ftpBrowseVars "set nm [list $nm]
      set host [list $host]
      set dir [list $dir]
      set user [list $user]
      set password [list $password]
      set fname [list $fname]
      set type [list $type]"
    
    if {!$ftpUseCache || ![file exists $nm]} {
	# 'ftpList' is defined in the file "www.tcl"
	ftpList $nm $host $dir $user $password ftp::browseListing
    } else {
	ftp::browseListing
    }    
}

proc ftp::browseListing {args} {
    
    global ftpBrowseVars fetched recentMounts savedMounts 
    global ftpUseCache ftpFetchingFile
    
    eval $ftpBrowseVars
    
    if {[catch {ftp::processListing $nm} listing]} {
	switchTo '[expr {$::alpha::platform == "alpha" ? "ALFA" : "AlTk"}]'
	alertnote "Error fetching directory '$dir'"
	return 1
    }
    set files [concat {..} $listing]
    if {$fname != ""} {
	if {[catch {listpick -L [list $fname] -p "$dir/" $files} file]} {return 1}
    } else {
	if {[catch {listpick -p "$dir/" $files} file]} {return 1}
    }
    
    if {$file == {..}} {
	if {[regexp {(.+)/[^/]+} $dir dummy sub]} {
	    catch {ftp::browse $host $sub $user $password}
	} else {
	    catch {ftp::browse $host "" $user $password}
	}
	return 1
    }
    
    if {[string match {*/} $file]} {
	if {[string length $dir]} {
	    catch {ftp::browse $host [string trimright "$dir/$file" {/}] $user $password}
	} else {
	    catch {ftp::browse $host [string trimright "$file" {/}] $user $password}
	}
	return 1
    }
    
    set entry [list $host $dir $user $password $type]
    set new 1
    foreach name [array names savedMounts] {
	if {([lindex $savedMounts($name) 0] == [lindex $entry 0]) \
	  && ([lindex $savedMounts($name) 1] == [lindex $entry 1])} {
	    set new 0
	    break;
	}
    }
    if {$new} {
	set recentMounts($dir) $entry
	ftp::buildMenu
    }
    
    set nm [temp::path ftptmp [lindex $entry 0] [lindex $entry 1] $file]
    if {!$ftpUseCache || ![file exists $nm]} {
	regsub "\[^\n\]+" $ftpBrowseVars "set nm [list $nm]" ftpBrowseVars
	if {[string length $dir]} {
	    set ftpFetchingFile "$dir/$file"
	} else {
	    set ftpFetchingFile "$file"
	}
	ftpFetch $nm $host $ftpFetchingFile $user $password ftp::receiveFile
	return 1
    }
    set nm [file nativename $nm]
    edit -c -w $nm
    # in case it's a duplicate window with <2> etc.
    set nm [win::Current]
    set fetched($nm) [list $host $dir $user $password "ftp"]
    return 1
}

proc ftp::receiveFileFromMenu {args} {
    eval ftp::receiveFile $args 1
}

proc ftp::receiveFile {args} {
    
    global fetched ftpBrowseVars ftpFetchingFile
    
    set reply [lindex $args 0]
    if {[catch {tclAE::getKeyData $reply errs} fetcherr]} {
	set fetcherr ""
    }
    if {[catch {tclAE::getKeyData $reply ----} anerr]} {
	set anerr ""
    }
    eval $ftpBrowseVars
    if {$fetcherr != ""} {
	if {[lindex $args 1] == "1"} {
	    # If we had an error message, we could give it as second argument
	    fileset::fileNotFound $fset
	} elseif {$fetcherr == "Error: unexpected server response."} {
	    # Assume it's a directory.
	    ftp::browse $host [string trimright "$ftpFetchingFile/" {/}] $user $password
	}
	return 1
    } elseif {$anerr != ""} {
	if {$anerr != "0"} {
	    if {[lindex $args 1] == "1"} {
		# If we had an error message, we could give it as second argument
		fileset::fileNotFound $fset
	    } elseif {$anerr == "550" || $anerr == "-550"} {
		# Assume it's a directory.
		ftp::browse $host [string trimright "$ftpFetchingFile/" {/}] $user $password
	    } 
	    return 1
	}
    }
    set nm [file nativename $nm]
    edit -c -w $nm
    # in case it's a duplicate window with <2> etc.
    set nm [win::Current]
    set fetched($nm) [list $host $dir $user $password "ftp"]
    return 1
}

## 
 # --------------------------------------------------------------------------
 # 
 # "ftp::processListing" --
 # 
 # Given the path of a file containing a listing of files from a remote 
 # server, read the file and parse it to return list of all files and 
 # folders (adding "/" to the end of folder names.)
 # 
 # This is a bit trickier than it might appear at first glance.  The listing 
 # will look something like this:
 # 
 #   drwxrwxr-x   7 webstar  Sysecole    238 Jun  1 16:25 AR4_04
 #   -rwxrwxr-x   1 webstar  Sysecole  13240 Sep 10 11:54 AR4_Chapter_4.html
 #   drwxrwxr-x  62 webstar  Sysecole   2108 May  9 16:35 Abstracts
 #   -rwxrwxr-x   1 webstar  Sysecole    636 Oct  5  2003 AndreasFischlin_IPCCAuthor.html
 #   drwxrwxr-x  98 webstar  Sysecole   3332 Jun 27 09:27 Articles_Reports
 #   drwxrwxr-x   8 webstar  Sysecole    272 Aug 24 12:32 CourseWare
 # 
 # or
 # 
 #   drwxr-xr-x   4 freeuser wwwfree      4096 Aug 11 21:41 archives
 #   drwxr-xr-x   6 freeuser wwwfree      4096 Aug 11 21:41 computing
 #   -rw-r--r--   1 freeuser wwwfree      5148 Aug 11 21:46 contact.html
 #   drwxr-xr-x   5 freeuser wwwfree      4096 Aug 11 21:41 courses
 #   drwxr-xr-x   2 freeuser wwwfree      4096 Jul 26 12:39 css
 #   drwxr-xr-x   2 freeuser wwwfree      4096 Aug 11 21:41 dissertation
 #   -rw-r--r--   1 freeuser wwwfree      1203 Aug 11 21:46 frames.html
 # 
 # or
 # 
 #   [Please add more examples here as needed.]
 # 
 # We'd like to assume that the last non-breaking string is the name of the
 # file/folder, but there's a chance that there are spaces in the name which
 # removes the possibility of converting the entire line to a list and then
 # grabbing the last item.  Instead, we do some regexp parsing to determine
 # the timestamp info and then use whatever follows.
 # 
 # If we knew the exact specification of a remote file listing (and if we 
 # were assured that all systems follow this protocol) we could clean up 
 # some of the ad hoc parsing that takes place here.
 # 
 # If the "path" cannot be found, or if it is empty, an error is thrown.
 # 
 # --------------------------------------------------------------------------
 ##

proc ftp::processListing {path} {
    
    if {![file exists $path]} {
	error "No directory listing found!"
    }
    set files [list]
    set lines [split [file::readAll $path] "\r\n"]
    if {[llength $lines]} {
	if {[string length [lindex $lines 0]] <= 10} {
	    set lines [lrange [lreplace $lines end end] 1 end]
	} else {
	    set lines [lreplace $lines end end]
	}
	set pat0 {^\s*[-\w]+\s+[\d]+\s+[-\w]+\s+[-\w]+\s+[\d]+}
	set pat1 { [A-Z][a-z]+ [\d, ]+ [\d,:]+ (.*)$}
	set pat2 {[-\d]+\s+[\d:APM]+\s+(<DIR>|[\d]+)\s+(.*)$}
	foreach line $lines {
	    # Attempt to remove the leading listing information.
	    if {![regsub $pat0 $line "" theRest]} {
		set theRest $line
	    }
	    if {![regexp $pat1 $theRest -> name] \
	      && ![regexp $pat2 $theRest -> dummy name]} {
		# Hmm: didn't match this line at all.  Either it is a useless
		# line, or perhaps we ought to warn the user (?)
		continue
	    }
	    if {[string match "d*" $line] || [string match "*<DIR>*" $line]} {
		if {![string match "." $name] && ![string match ".." $name]} {
		    # Directory.
		    append name "/"
		}
	    } elseif {[string match "l*" $line]} {
		# Symbolic link.
		regexp {(.*) -> (.*)} $name -> name link
		if {[string match "*/" $link]} {
		    append name "/"
		}
	    }
	    lappend files $name
	}
    } else {
	error "Empty directory listing!"
    }
    return $files
}

# ×××× ---- ×××× #

# ×××× Ftp Menu Hooks ×××× #

hook::register savePostHook       ftp::postHook
hook::register quitHook           ftp::quitHook
hook::register titlebarListHook   ftp::titlebarListHook
hook::register titlebarSelectHook ftp::titlebarSelectHook
hook::register titlebarPathHook   ftp::titlebarPathHook
  
# Open windows hook.

foreach menuItem [list browseCurrentÉ saveAsAtÉ saveACopyAtÉ] {
    hook::register requireOpenWindowsHook [list $ftpMenu $menuItem] 1
} 

unset menuItem

proc ftp::postHook {name} {

    global fetched odbedited tmpFtpPasswords

    if {[info exists fetched($name)] && ![info exists odbedited($name)]} {
	set specs $fetched($name)
	set name [win::StripCount $name]
	set password [lindex $specs 3]
	if {![string length $password]} {
	    if {![info exists tmpFtpPasswords("[lindex $specs 2]@[lindex $specs 0]")]} {
	       set password [dialog::password "Password for [lindex $specs 0]:"]
	       set tmpFtpPasswords("[lindex $specs 2]@[lindex $specs 0]") $password
	       ftp::postEval
	   } else {
	       set password $tmpFtpPasswords("[lindex $specs 2]@[lindex $specs 0]")
	   }
	}
	status::msg "Updating '[file tail $name]' on [lindex $specs 0]É"
	if {[string length [lindex $specs 1]]} {
	    ftpStore $name [lindex $specs 0] \
	      "[lindex $specs 1]/[file tail $name]" [lindex $specs 2] $password
	} else {
	    ftpStore $name [lindex $specs 0] \
	      "[file tail $name]" [lindex $specs 2] $password
	}
    }
}

proc ftp::quitHook {} {temp::cleanup ftptmp}

## 
 # -------------------------------------------------------------------------
 # 
 # "ftp::titlebarPathHook" --
 # 
 #  If $f was fetched by ftp, builds an appropriate path menu, else throws
 #  an error.
 #  
 #  Used in Alpha 8.0b5 and AlphaX 8.0a7 and above.
 # 
 # Results:
 #  
 #  Name of ftp titlebar path menu or error if not an ftp-fetched file
 # 
 # Side effects:
 # 
 #  ftp titlebar path menu is built
 # -------------------------------------------------------------------------
 ##
proc ftp::titlebarPathHook {f} {
    global fetched
    if {[info exists fetched($f)]} {
	menu::buildOne ftpPathMenu
	return "ftpPathMenu"
    } else {
	error "Not a fetched file"
    }
}

menu::buildProc ftpPathMenu buildFtpPathMenu

## 
 # -------------------------------------------------------------------------
 # 
 # "ftp::buildPathList" --
 # 
 #  Returns ftp URL for $win or top window, decomposed as list items.
 # -------------------------------------------------------------------------
 ##
proc ftp::buildPathList {{win ""}} {
    global fetched
    
    if {$win == ""} {
	set win [win::Current]
    } 

    if {[info exists fetched($win)]} {
	set specs $fetched($win)
	# add type of link to end of specs for backwards compatibility
	if {[lindex $specs 4] == ""} {
	    lappend specs "ftp"
	    set fetched($win) $specs
	}
	return [concat [list "[lindex $specs 4]://[lindex $fetched($win) 0]"] \
	  [split [lindex $fetched($win) 1] "/"] \
	  [list [file tail $win]]]
    } else {
	error "Not a fetched file"
    }
}

proc buildFtpPathMenu {} {
    return [list build [lreverse [ftp::buildPathList]] {ftp::titlebarSelectProc -m -c} {}]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "ftp::titlebarSelectProc" --
 # 
 #  ftp titlebar path menu handler.  Arguments differ form standard menu
 #  handlers:
 # 
 # Argument     Description
 # ------------ ---------------------------------------------
 #  menu        name of menu selected from
 #  pathList	list of every element in the menu from the bottom to the 
 #              item selected, inclusive.
 # 
 # Results:
 #  None.
 # 
 # Side effects: 
 # 
 #  If first item is selected, URL is copied to the Clipboard (<shift> adds
 #  username, <shift><control> adds username and password).  If other items
 #  are selected, the appropriate directory is opened in an ftp browser. 
 #  -------------------------------------------------------------------------
 ##
proc ftp::titlebarSelectProc {menu pathList} {
    global fetched
    
    set win [win::Current]

    if {![catch {ftp::buildPathList} fullPathList]} {
	if {[catch {
	    set specs $fetched($win)
	    
	    if {$pathList == $fullPathList} {
		set user ""
		if {[key::shiftPressed]} {
		    set user [lindex $specs 2]
		    if {[key::controlPressed]} {append user ":" [lindex $specs 3]} 
		    append user "@"
		}
		set    scrap <[lindex $specs 4]://${user}
		append scrap [lindex $specs 0]/
		append scrap [lindex $specs 1]/
		append scrap [lindex $pathList end]>
		putScrap $scrap
		status::msg "Copied URL of '[lindex $pathList end]' to the Clipboard."	    
	    } else {
		set dir [join [lrange $pathList 1 end] "/"]
		set msg "Browsing host [lindex $specs 0]"
		if {[string length $dir]} {append msg ", in directory $dir"}
		status::msg $msg
		eval ftp::browse [list [lindex $specs 0] $dir] [lrange $specs 2 4]
		status::msg ""
	    }
	} err]} {
	    status::msg "$err"
	}
	return 1
    } else {
	return 0
    }
}

proc ftp::titlebarListHook {f} {

    global fetched tcl_platform

    if {[info exists fetched($f)]} {
	set nm "[lindex $fetched($f) 0]/[lindex $fetched($f) 1]/[file tail $f]"
	regsub -all {//} $nm {/} nm
	if {$tcl_platform(platform) == "macintosh"} {regsub -all {/} $nm {:} nm}
	return $nm
    } else {
	error "Not a fetched file"
    }
}

proc ftp::titlebarSelectHook {win name} {

    global fetched

    if {[info exists fetched($win)]} {
	if {[catch {
	    set specs $fetched($win)
	    # add type of link to end of specs for backwards compatibility
	    if {[lindex $specs 4] == ""} {
		lappend specs "ftp"
		set fetched($win) $specs
	    }
	    if {$name == [getTitleBarPath]} {
		set user ""
		if {[key::shiftPressed]} {
		    set user [lindex $specs 2]
		    if {[key::controlPressed]} {append user ":" [lindex $specs 3]} 
		    append user "@"
		}
		set    scrap <[lindex $specs 4]://${user}
		append scrap [lindex $specs 0]/
		append scrap [lindex $specs 1]/
		append scrap [file tail $name]>
		putScrap $scrap
		status::msg "Copied URL of '[file tail $name]' to the Clipboard."	    
	    } else {
		
		set pathsplit [split $name [file separator]]
		set len [llength $pathsplit]
		switch -- $len {
		    1 {set dir ""}
		    2 {set dir [lindex $pathsplit 1]}
		    default {
			set dir [eval file join [lrange $pathsplit 1 [expr {$len -1}]]]
			global tcl_platform
			if {$tcl_platform(platform) == "macintosh"} {
			    set dir [string trimleft $dir :]
			}
		    }
		}
		if {[file separator] == ":"} {regsub -all {:} $dir {/} dir}
		set msg "Browsing host [lindex $specs 0]"
		if {[string length $dir]} {append msg ", in directory $dir"}
		status::msg $msg
		eval ftp::browse [list [lindex $specs 0] $dir] [lrange $specs 2 4]
		status::msg ""
	    }
	} err]} {
	    status::msg "$err"
	}
	return 1
    } else {
	return 0
    }
}

# ×××× ---- ×××× #

# ×××× Ftp Fileset Support ×××× #

alpha::package require filesets

# Most of these procs in the fileset::ftp namespace are called by the fileset
# menu for filesets with the fileset type 'ftp'.  Others provide support.

namespace eval fileset::ftp {}

# This allows ftp filesets to be created.

proc fileset::ftp::create {} {
    
    global gfileSets gfileSetsType fileSetsExtra
    
    set specs [ftp::getLogin]

    while {1} {
	if {[set pattern "^[prompt {File regexp pattern?} {.*}]$"] == "^$"} {
	    set pattern "^.*$"
	}
	if {[catch {regexp -- $pattern {}} err]} {
	    alertnote "That pattern, which should be a regular expression,\
	      is illegal: $err"
	} else {
	    break
	}
    }
    
    set name [lindex $specs 0]
    
    set fileSetsExtra($name) [concat [lrange $specs 1 4] [list "ftp" $pattern]]
    set gfileSetsType($name) ftp
    set gfileSets($name) ""
    
    set m [fileset::ftp::updateContents $name 1 \
      [list fileset::ftp::createCallback $name]]
    fileset::cacheMenu $name $m

    return $name
}

# These next two allow editing of ftp filesets.

proc fileset::ftp::setDetails {name args} {
    
    global fileSetsExtra
    
    set fileSetsExtra($name) $args
    prefs::modified fileSetsExtra($name)
}

proc fileset::ftp::getDialogItems {name} {
    
    global fileSetsExtra
    
    set specs $fileSetsExtra($name)
    lappend res \
      [list variable Host [lindex $specs 0]] \
      [list variable Path [lindex $specs 1]] \
      [list variable User [lindex $specs 2]] \
      [list password Password [lindex $specs 3]] \
      [list variable Type [lindex $specs 4]] \
      [list variable Regexp [lindex $specs 5]]
      
    set res
}

# The rest handle the selection of ftp fileset items.

proc fileset::ftp::selected {fset menu item} {
    
    global gfileSets fetched fileSetsExtra ftpBrowseVars 
    global ftpFetchingFile tmpFtpPasswords
    
    set ind [lsearch $gfileSets($fset) "$item"]
    if {$ind < 0} {
	set pat [string trimleft [file join * $item] [file separator]]
	set ind [lsearch $gfileSets($fset) $pat]
    }
    if {$ind < 0} {
	error "Cancelled -- couldn't find '$item' in '$fset'."
    }

    set f [lindex $gfileSets($fset) $ind]
    regsub -all {:} $f {/} f
    set specs $fileSetsExtra($fset)
    set nm [temp::path ftptmp [lindex $specs 0] [lindex $specs 1] $item]
    if {![file exists $nm]} {
	set password [lindex $specs 3]
	if {![string length $password]} {
	    if {![info exists tmpFtpPasswords("[lindex $specs 2]@[lindex $specs 0]")]} {
	       set password [dialog::password "Password for [lindex $specs 0]:"]
	       set tmpFtpPasswords("[lindex $specs 2]@[lindex $specs 0]") $password
	       ftp::postEval
	   } else {
	       set password $tmpFtpPasswords("[lindex $specs 2]@[lindex $specs 0]")
	   }
	}
	set ftpBrowseVars "set nm [list $nm]
	    set host     [list [lindex $specs 0]]
	    set dir      [list [lindex $specs 1]]
	    set user     [list [lindex $specs 2]]
	    set password [list $password]
	    set fset     [list $fset]"
	set ftpFetchingFile $f
	ftpFetch $nm [lindex $specs 0] $f [lindex $specs 2]\
	  $password ftp::receiveFileFromMenu
	return
    }
    set nm [file nativename $nm]
    edit -c -w $nm
    # in case it's a duplicate window with <2> etc.
    set nm [win::Current]
    set fetched($nm) $specs
}

proc fileset::ftp::updateContents {name {andMenu 0} {replyhandler ""}} {
    
    global fileSetsExtra filesetIsSynchronous filesetBrowseVars
    global ftpUpdateQueue ftpIsBusy tmpFtpPasswords
    
    if {[info exists ftpIsBusy] && $ftpIsBusy} {
	lappend ftpUpdateQueue [list $name $andMenu $replyhandler]
	return [fileset::fromDirectory::updateContents $name $andMenu]
    }
    
    foreach {host path username password type pattern} $fileSetsExtra($name) {
	break
    }
    if {![string length $password]} {
	if {![info exists tmpFtpPasswords("${username}@$host")]} {
	   set password [dialog::password "Password for ${host}:"]
	   set tmpFtpPasswords("${username}@$host") $password
	   ftp::postEval
       } else {
	   set password $tmpFtpPasswords("${username}@$host")
       }
    }
    set path [string trimright $path {/}]

    status::msg "Updating '$name', logging on to ${host}É"
    if {![string length $replyhandler]} {
	set replyhandler [list fileset::ftp::updateCallback $name]
    }
    set nm [temp::unique ftptmp listing.temp]
    set filesetBrowseVars($name) \
      "set nm [list $nm] ; set path [list $path] ; set pattern [list $pattern]"

    set filesetIsSynchronous($name) 0
    set ftpIsBusy 1
    ftpList $nm $host $path $username $password $replyhandler

    unset filesetIsSynchronous($name)
    return [fileset::fromDirectory::updateContents $name $andMenu]
}

# This is called when the contents of the fileset have been correctly
# updated for the first time after creation.  
# 
# If asynchronously, it should return 1

proc fileset::ftp::createCallback {name args} {
    
    global gfileSets gfileSetsType fileSetsExtra
    
    if {[catch {fileset::ftp::updateCallback $name}]} {
	global errorInfo
	set errCache $errorInfo
	if {[dialog::yesno -y "View the error" -n "Continue" \
	  "There was an error retrieving the appropriate\
	  list of files, so this fileset will be empty.  Please use the\
	  'Edit Filesets' dialog if you wish to change some of its\
	  settings."]} {
	    dialog::alert $errCache
	}
	set gfileSets($name) ""
    }
    if {[dialog::yesno "Save project fileset?"]} {
	prefs::modified gfileSetsType($name) gfileSets($name) fileSetsExtra($name)
    }
    return 1
}

# This is called whenever the contents of the fileset have been
# correctly updated.  It can be called synchronously or asynchronously.  
# 
# If asynchronously, it should return 1

proc fileset::ftp::updateCallback {name args} {
    
    global gfileSets filesetIsSynchronous ftpUpdateQueue ftpIsBusy

    set ftpIsBusy 0
    set files [fileset::ftp::processListing $name]

    set gfileSets($name) [lsort -command sortByTail $files]
    prefs::modified gfileSets($name)
    
    if {[llength $files]} {
	if {[info exists filesetIsSynchronous($name)]} {
	    set filesetIsSynchronous($name) 1
	} else {
	    # We need to update the menu
	    set m [fileset::fromDirectory::updateContents $name 1]
	    fileset::cacheMenu $name $m
	    filesetMenu::fsetUpdated $name $m
	}
    }
    if {[info exists ftpUpdateQueue] && [llength $ftpUpdateQueue]} {
	set upd [lindex $ftpUpdateQueue 0]
	set ftpUpdateQueue [lrange $ftpUpdateQueue 1 end]
	eval fileset::ftp::updateContents $upd
    }
    status::msg "Done."
    return 1
}

proc fileset::ftp::processListing {name} {

    global filesetBrowseVars tcl_platform
    eval $filesetBrowseVars($name)

    # Give the user an error message if we got this
    # far, but the listing is empty.
    if {[catch {ftp::processListing $nm} listing]} {
	catch {file delete -force $nm}
	switchTo '[expr {$::alpha::platform == "alpha" ? "ALFA" : "AlTk"}]'
	alertnote "Error fetching directory listing for fileset\
	  '${name}': $listing"
	return [list]
    }
    catch {file delete -force $nm}

    if {[catch {regexp -- $pattern {}} err]} {
	# The user supplied an invalid regexp pattern.
	alertnote "The pattern \"$pattern\" is not a valid regular expression.\
	  All remote files will be listed in the fileset."
	set pattern "^.*$"
    }
    set files {}
    foreach f $listing {
	if {![string match {*/} $f] && [regexp -- $pattern $f]} {
	    if {$path != ""} {
		lappend files "$path/$f"
	    } else {
		lappend files $f
	    }
	}
    }
    if {$tcl_platform(platform) == "macintosh"} {regsub -all {/} $files {:} files}
    file delete $nm
    return $files
}

