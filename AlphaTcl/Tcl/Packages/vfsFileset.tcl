## -*-Tcl-*-
 # ###################################################################
 #  Alphatk - the ultimate editor
 # 
 #  FILE: "vfsFileset.tcl"
 #                                    created: 11/02/2000 {17:30:36 PM} 
 #                                last update: 11/03/2004 {02:31:39 PM} 
 #  Author: Vince Darley
 #  E-mail: vince@santafe.edu
 #     www: http://www.santafe.edu/~vince/
 #  
 # Copyright (c) 2000-2004  Vince Darley
 # 
 # This file is distributed under a Tcl-style free license.
 # 
 # It has two overlapping sets of functionality:
 # 
 # (i) it automatically implements a 'vfs' fileset type.
 # 
 # (ii) Under various circumstances it will automount a vfs,
 # if this package is activated:
 # 
 # (a) it intercepts file-open actions for .exe, .zip, .kit files, and
 # auto-mounts them, creating a temporary fileset in the process.
 # You can then browse that fileset with the 'open via fileset' menu
 # item.
 # 
 # (b) file-open actions for files which appear to be trying to use
 # 'tclkit' as an executable will also cause an automount.
 # 
 # ###################################################################
 ##

# extension declaration
alpha::extension vfsFileset 0.3.7 {
    if {[::package require vfs] == 1.2} {
	# Fix one bug in 1.2 which will hit us
	catch {
	    ::vfs::autoMountExtension "" ::vfs::mk4::Mount vfs::mk4
	    ::vfs::autoMountExtension .bin ::vfs::mk4::Mount vfs::mk4
	    ::vfs::autoMountExtension .kit ::vfs::mk4::Mount vfs::mk4
	    ::vfs::autoMountExtension .tar ::vfs::tar::Mount vfs::tar
	    ::vfs::autoMountExtension .zip ::vfs::zip::Mount vfs::zip
	    ::vfs::autoMountUrl ftp ::vfs::ftp::Mount vfs::ftp
	    ::vfs::autoMountUrl file ::vfs::fileUrlMount vfs
	    ::vfs::autoMountUrl tclns ::vfs::tclprocMount vfs::ns
	}
    }
    hook::register editHook fileset::vfs::autoMount .exe .zip .kit .tar
    hook::register unixModeHook fileset::vfs::scripdocMount tclkit
    hook::register unixModeHook fileset::vfs::scripdocMount tclkitsh
    if {![info exists unixMode(tclkit)]} {
	set unixMode(tclkit) Tcl
    }
    if {![info exists unixMode(tclkitsh)]} {
	set unixMode(tclkitsh) Tcl
    }
    catch {::vfs::autoMountExtension .kit ::vfs::mk4::Mount vfs::mk4}
    catch {::vfs::autoMountExtension .exe ::vfs::mk4::Mount vfs::mk4}
} requirements {
    ::package require vfs
} maintainer {
    {Vince Darley} vince@santafe.edu http://www.santafe.edu/~vince
} uninstall {
    this-file
} preinit {
    # Strictly speaking we don't quite use the same format as 'fromHierarchy'
    # filesets, but it's similar enough that it will mostly work, and save a
    # lot of coding here.
    # 
    # We'll eventually write the proper fileset type, which will avoid the
    # few glitches with current approach (e.g. a saved fileset won't work on
    # restart unless it is rebuilt because the vfs hasn't been mounted).
    fileset::registerNewType vfs "fromHierarchy"
} description {
    Mount VFS filesets and edit their contents from Alphatk
} help {
    Mount VFS filesets and edit their contents from Alphatk.  This package
    always provides a 'vfs' fileset type (you don't need to activate the
    package to use it).  This fileset type lets you specify any supported url
    and mount its contents for editing.  The set of urls supported are those
    which can be mounted by 'vfs::urlMount' in Tcl's vfs package, and any
    local files (i.e. file:// urls) which can be mounted by the 'vfs::auto'
    command.
    
    In addition, if activated, this package lets you auto-mount and edit the
    contents of virtual filesystems.  If you try to 'Open...'  a .zip or .kit
    file, for instance, Alpha will mount the contents of the file as a
    virtual filesystem, and let you edit the contents.  The types of files
    which are supported in this way are limited by those supported by the
    'vfs::auto' command of Tcl's vfs package.
}


alpha::package require filesets
namespace eval fileset::vfs {}

package require vfs

proc fileset::vfs::scripdocMount {filename} {
    if {[catch {
	::package require mk4vfs
	::vfs::mk4::Mount $filename $filename
    } err]} {
	set msg "Can't find and mount $filename as a virtual filesystem,\
	  so this file will be edited instead (error: $err)"
	alertnote $msg
	error $msg
    }
    ::fileset::vfs::autoMount $filename
}

proc fileset::vfs::autoMount {filename} {
    if {![dialog::yesno -y "Mount" -n "Treat as ordinary file" \
      "\"$filename\" looks like it can be mounted\
      as a virtual filesystem (so its contents can be accessed\
      directly).  Would you like to do this?"]} {
	return 0
    }
    # It may already be mounted.
    if {[file isdirectory $filename] \
      || ![catch [list ::vfs::auto $filename] res]} {
	if {![file isdirectory $filename]} {
	    set msg "'$filename' didn't mount correctly -- its contents\
	      can't be accessed"
	    alertnote $msg
	    error $msg
	}
	global gfileSets
	set name [file root [file tail $filename]]
	set gfileSets($name) [list $filename 3 "file://$filename"]
	registerNewFileset $name vfs
	status::msg "[file tail $filename] mounted at $name, use\
	  'Open via fileset' to edit its contents."
	# Automatically try to open it, thereby continuing the
	# user's open action.
	file::openViaFileset $name
	return 1
    } else {
	set msg "Failed to automount '$filename' as a virtual filesystem\
	  (err: $res)"
	alertnote $msg
	error $msg
    }
    
    return 0
}

proc fileset::vfs::setDetails {name vfsfile mountto depth} {
    global gfileSets
    set gfileSets($name) [list $mountto $depth $vfsfile]
    modifyFileset $name
}

proc fileset::vfs::getDialogItems {name} {
    global gfileSets
    lappend res \
      [list url "Fileset vfs:" [lindex $gfileSets($name) 2]] \
      [list variable "Mount to (blank for default):" \
      [lindex $gfileSets($name) 0]] \
      [list [list menu [list 1 2 3 4 5 6 7]] \
      "Depth of hierarchy?" [lindex $gfileSets($name) 1]]
    return $res
}

proc fileset::vfs::getRoot {name} {
    global gfileSets
    return [lindex $gfileSets($name) 0]
}

proc fileset::vfs::create {{name ""}} {
    global gfileSets gfileSetsType
    
    if {![string length $name]} {
	set name [prompt "New fileset name:" ""]
    }
    if {![string length $name]} {
	status::msg "Cancelled -- no text was entered."
	return
    }
    
    set vfsfile [dialog::getUrl "Url for new vfs fileset '$name':"]
    if {![string length $vfsfile]} return

    set mountto [getline "Mount to (leave blank for default location):" ""]
    
    set depth [listpick -p "Depth of hierarchy?" -L 3 {1 2 3 4 5 6 7}]
    if { $depth == "" } {set depth 3}

    set gfileSets($name) [list $mountto $depth $vfsfile]
    set gfileSetsType($name) "vfs"
    
    return $name
}

proc fileset::vfs::updateContents {name {andMenu 0}} {
    global fileSets gfileSets

    set vfsfile [lindex $gfileSets($name) 2]
    set to [lindex $gfileSets($name) 0]
    
    if {![regexp -- {^file://} $vfsfile]} {
	if {$to == ""} {
	    set to [temp::directory vfstmp $vfsfile]
	    set gfileSets($name) \
	      [concat [list $to] [lrange $gfileSets($name) 1 end]]
	}
	::vfs::urlMount $vfsfile $to
    } else {
	if {$to == ""} {
	    set to $vfsfile
	    set gfileSets($name) \
	      [concat [list $to] [lrange $gfileSets($name) 1 end]]
	}
	::vfs::urlMount $vfsfile
    }
    set patt *
    set depth [lindex $gfileSets($name) 1]
    # we make the menu as a string, but can bin it if we like
    set menu [menu::buildHierarchy [list $to] $name \
      fileset::openItemProc filesetTemp $patt $depth \
      [list filesetMenu::registerName $name -proc fileset::openItemProc]]
    
    # we need to construct the list of items
    set fileSets($name) {}
    if {[info exists filesetTemp]} {
	foreach n [array names filesetTemp] {
	    lappend fileSets($name) $filesetTemp($n)
	}
    }
    return $menu
}

proc fileset::vfs::selected {fset parent item} {
    fileset::fromHierarchy::selected $fset $parent $item
}

