## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl - core Tcl engine
 # 
 # FILE: "fileManipulation.tcl"
 #                                          created: 02/24/1998 {01:57:08 pm}
 #                                      last update: 04/05/2006 {11:23:14 PM} 
 # Description:
 # 
 # These are various utility procedures which operate on windows which
 # represent files, on files directly, and on file paths.
 # 
 # Procedures which can operate on non-file windows should not be in this
 # file, and should not be in the 'file::' namespace.
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #   mail: 317 Paseo de Peralta, Santa Fe, NM 87501
 #    www: <http://www.santafe.edu/~vince/>
 #  
 # Mostly Copyright (c) 1998-2006  Vince Darley
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

proc fileManipulation.tcl {} {}

namespace eval file {}

## 
 # -------------------------------------------------------------------------
 # 
 # "file::minimalDistinctTails" --
 # 
 #  Go over all of the given files (which should be complete paths),
 #  and return an ordered list of the tails, where if any tail is
 #  duplicated, we add in the preceding directory names until we
 #  do get a unique set of items.  Order is preserved.
 #  
 #  If files do not exist, we ignore them.
 # -------------------------------------------------------------------------
 ##
proc file::minimalDistinctTails {filelist} {
    
    set menulist [list]
    set level 1
    while {1} {
	foreach t $filelist {
	    # Don't do 'file exists' for networked files.  If we're
	    # not on a network Alpha may lock for some time
	    if {![file::isNetworked $t] && ![file exists $t]} {continue}
	    set llen [llength [set tail [file split $t]]]
	    if {$llen < $level} {
		# We've exceeded the top-level.  Must be an odd problem!
		# Discard this problematic file.
		continue
	    }
	    set tail [join [lrange $tail [expr {$llen - $level}] end] [file separator]]
	    if {[info exists name($tail)]} {
		lappend remaining $name($tail)
		lappend remaining $t
		set dup($tail) 1
		set first [lsearch -exact $menulist $tail]
		set menulist [lreplace $menulist $first $first $name($tail)]
		if {$level==1} {
		    lappend menulist $t
		}
		unset name($tail)
	    } elseif {[info exists dup($tail)]} {
		lappend remaining $t
		if {$level==1} {
		    lappend menulist $t
		}
	    } else {
		set name($tail) $t
		if {$level==1} {
		    lappend menulist $tail
		} else {
		    set toolong [lsearch -exact $menulist $t]
		    set menulist [lreplace $menulist $toolong $toolong $tail]
		}
	    }
	}
	if {![info exists remaining]} {
	    break
	}
	incr level
	set filelist $remaining
	unset remaining
	unset dup
    }
    return $menulist
}

proc file::coreCopy {from to} {
    set fromEnc [alpha::encodingFor $from]
    set toEnc [alpha::encodingFor $to]
    
    file::ensureDirExists [file dirname $to]

    if {[string length $fromEnc] && [string length $toEnc]\
      && ($fromEnc != $toEnc) && [file::isText $from]} {
	# It's a text file, but might have its own special
	# encoding.  So, to avoid corrupting it, we have to
	# check (and the check depends on the mode assigned).
	# This code is a bit tricky, but used to be even worse!

	set m [file::preOpeningConfigurationCheck $from]
	if {$m eq ""} { set m [win::FindMode $from] }

	win::setInitialConfig $from mode $m "command"
	hook::callAll preOpeningHook $m $from
	array set vals [win::getAndReleaseInitialInfo $from]

	if {[info exists vals(encoding)] && ($vals(encoding) ne "")} {
	    # have specific encoding, so copy the file as is
	    file copy $from $to
	    return "text"
	} else {
	    set fin [alphaOpen $from r]
	    set fout [alphaOpen $to w]
	    fcopy $fin $fout
	    close $fin ; close $fout
	    file mtime $to [file mtime $from]
	    return "text"
	}
    } else {
	file copy $from $to
	return "binary"
    }
}

proc file::isText {fileName} {
    switch -- [string tolower [file extension $fileName]] {
	".gif" - ".pdf" - ".ps" - ".eps" - ".fon" - ".ttf" - 
	".icr" - ".ico" - ".png" - ".dll" - ".shlb" -
	".so" - ".exe" - ".zip" - ".dylib" - ".jpg" - 
	".ppm" - ".dmg" - ".sitx" - ".sit" - ".bin" - ".kit" -
	".dvi" - ".z" - ".gz" - ".class" {
	    return 0
	}
	default {
	    return 1
	}
    }
}


## 
 # --------------------------------------------------------------------------
 # 
 # "file::toUrl" --
 # 
 # Transform a file path into a url.  We take special care with any slashes
 # that appear in the original name.  The path must use the file separators
 # relevant to the OS.
 # 
 # --------------------------------------------------------------------------
 ##

proc file::toUrl {fileName} {
    global tcl_platform
    regsub -all [quote::Regfind [file separator]] \
      [quote::Url $fileName \
      [expr {($tcl_platform(platform) eq "macintosh")}]] / fileName
    return "file:///[string trimleft $fileName [file separator]]"
}

## 
 # --------------------------------------------------------------------------
 # 
 # "file::fromUrl" --
 # 
 # Transform a "file:///..."  url into a local path name.  We take special
 # care with any leading "/" that needs to be part of the file path (unix) or
 # which must be removed.
 # 
 # --------------------------------------------------------------------------
 ##

proc file::fromUrl {url} {
    
    global tcl_platform
    
    regsub "^file://(localhost)?" $url "" url
    switch -- $tcl_platform(platform) {
	"windows" {
	    regsub "^/" $url "" url
	}
	"macintosh" {
	    regsub "^/" $url "" url
	    regsub -all "/" $url ":" url
	}
    }
    return [quote::Unurl $url]
}

# Certain characters are not allowed in file names.  This procedure
# takes a prospective file name (i.e just the tail, not a full
# directory specification) and removes all illegal characters.
proc file::makeNameLegal {fileTail} {
    global tcl_platform
    switch -- $tcl_platform(platform) {
	"macintosh" {
	    regsub -all {[:]} $fileTail "" fileTail
	    return $fileTail
	}
	"windows" {
	    regsub -all {[<>*?/\\:]} $fileTail "" fileTail
	    # Trailing dots are ignored on windows.
	    regsub -all {\.+$} $fileTail "" fileTail
	    return [string trimleft $fileTail]
	}
	"unix" {
	    regsub -all {[/]} $fileTail "" fileTail
	    return $fileTail
	}
    }
}

proc file::tryToFindInFolder {folder rest pattern \
  {prompt "Select the file to use"}} {
    # Loop in case we really fail
    while {1} {
	# If we have multiple extensions, loop over them, testing for names.
	# We might have to strip off: .sit.hqx or even more.
	
	while {1} {
	    set filepre [file root $rest]
	    # look for directories
	    set dirs [glob -nocomplain -types d \
	      -path [file join $folder ${filepre}] -- *]
	    set local [lindex $dirs 0]
	    if {![info exists bestGuessFolder]} {
		set bestGuessFolder $local
	    }
	    set files [lunique [glob -types TEXT -nocomplain \
	      -dir $local -- $pattern]]
	    set realfiles [list]
	    foreach f $files {
		if {![file isdirectory $f]} {
		    lappend realfiles $f
		}
	    }
	    set files $realfiles
	    if {[llength $files] != 0} { break }

	    # look for files
	    set files [glob -types TEXT -nocomplain \
	      -path [file join ${folder} ${filepre}] -- *]
	    set realfiles [list]
	    foreach f $files {
		if {![file isdirectory $f]} {
		    lappend realfiles $f
		}
	    }
	    set files $realfiles
	    if {[llength $files] != 0} { break }
	    set newrest [file root $rest]
	    if {![string length $newrest] || ($rest eq $newrest)} {
		break
	    }
	    set rest $newrest
	}
	
	if {[llength $files] == 0} {
	    set shortLen [string length $filepre]
	    # While the length is 4 chars or more, strip 2 characters
	    # off and try again.  This should eventually work unless
	    # the package is very strangely named or packaged.
	    if {$shortLen > 4} {
		set rest [string range $filepre 0 [expr {$shortLen - 3}]]
		# try everything again.
		continue
	    }
	    alertnote "I can't find an obvious, suitable, unique file.\
	      Please try to find it in the following dialog."
	    
	    if {[info exists bestGuessFolder]} {
		set folder $bestGuessFolder
	    }
	    if {[catch [list getfile $prompt $folder] f]} {
		return ""
	    } else {
		return [file nativename $f]
	    }
	    # We used to display the folder to the user:
	    # but we never get here now.
	    file::showInFinder $local
	    return
	}
	if {[llength $files] > 1} {
	    set f [listpick -p $prompt $files]
	} else {
	    set f [lindex $files 0]
	}
	return [file nativename $f]
    }

}

# Return name(s) of any open windows corresponding to the given
# file on disk, in a list.  Returns the empty list if nothing
# is found.
proc file::hasOpenWindows {fileName} {
    set n [file::ensureStandardPath $fileName]
    # Resolve symbolic links:
    if { [file exists $n] && [file type $n] eq "link" } {
	set n [file readlink $n]
    }
    set res [list]
    foreach w [winNames -f] {
	if {[win::StripCount $w] eq $n} {
	    lappend res $w
	}
    }
    return $res
}

proc file::ensureStandardPath {fileName} {
    if {$fileName eq ""} {return ""}
    # Ensure a standard, absolute path
    return [file nativename [file normalize $fileName]]
}

# On Mac OS X takes an absolute Finder path with colons and returns 
# the corresponding unix path. On other platforms, this proc returns
# the input.
proc file::FinderPathToUnix {path} {
    if {$alpha::macos != 2 || ![regexp -- : $path]} {return $path}
    return [tclAE::getPOSIXPath $path]
}

# On Mac OS X takes an absolute unix path and returns 
# the corresponding Finder path. On other platforms, this proc returns
# the input.
proc file::unixPathToFinder {path} {
    if {$alpha::macos != 2 || ![regexp / $path]} {return $path}
    return [tclAE::getHFSPath $path]
}

proc file::cygwinPathToWindows {path} {
    regsub -- {^(/cygdrive)?/([a-zA-Z])/} $path {\2:/}
}

proc file::windowsPathToCygwin {path} {
    regsub -- {^([A-Z]):/} [file normalize $path] {/cygdrive/\1/}
}

# Returns the name of the startup disk on Mac OS
proc file::startupDisk {} {
    global file::_startupDisk
    if {[info exists file::_startupDisk]} {return $file::_startupDisk}
    set file::_startupDisk ""
    catch {
	set res [tclAE::send -r  'MACS' core getd ----  [tclAE::build::propertyObject pnam \
	  [tclAE::build::propertyObject sdsk]]]
	set sdisk [tclAE::getKeyData $res ---- TEXT]
	tclAE::disposeDesc $res
	set file::_startupDisk $sdisk
    }
    return $file::_startupDisk
}


proc file::saveResourceChanges {winName} {
    global alpha::platform
    if {$alpha::platform eq "alpha"} {
	saveResources $winName
    }
}

proc file::openAsTemplate {fileName {name ""} {readonly 1}} {
    if {$name == ""} {
	set name [file tail $fileName]
    }
    set m [win::FindMode $fileName]
    new -n $name -m $m -text [file::readAll $fileName]
    if {$readonly} {
	setWinInfo dirty 0
	setWinInfo read-only 1
    }
    goto [minPos]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "file::showInFinder" --
 # 
 # Attempt to show the "fileOrDir" in the Finder.  If none specified, the
 # current window is displayed.
 # 
 # Known limitation: on Mac OS X, if "fileOrDir" is an application, it will
 # be launched instead of shown.  (Bug# 2013)
 # 
 # --------------------------------------------------------------------------
 ##

proc file::showInFinder {{fileOrDir ""}} {
    
    global alpha::macos tcl_platform
    
    if {($fileOrDir eq "")} {
	set fileOrDir [win::Current]
    }
    if {![file exists $fileOrDir]} {
	error "Cancelled -- file not found: \"$fileOrDir\""
    }
    set fileOrDir [file normalize $fileOrDir]
    if {$alpha::macos} {
	if {[file isdirectory $fileOrDir]} {
	    switchTo Finder
	    sendOpenEvent noReply Finder $fileOrDir
	} else {
	    switchTo Finder
	    tclAE::send -p Finder misc mvis "----" [tclAE::build::alis $fileOrDir]
	}
    } elseif {($tcl_platform(platform) eq "windows")} {
	windows::Show $fileOrDir
    } else {
	alertnote "\[file::showInFinder\] not yet implemented on Unix."
    }
    return
}

proc file::tryToOpen {{fname ""}} {
    if {$fname == ""} {set fname [getSelect]}
    set f [file join [file dirname [win::Current]] $fname]
    if {[file exists $f]} {
	file::openQuietly $f
    } else {
	alertnote "Sorry, I couldn't find the file '$fname'.\
	  You could install\
	  or activate the 'Mode Search Paths' feature, which includes\
	  better include-path handling."
    }
}

proc file::ensureDirExists {dir} {
    if {![file exists $dir]} {
	set parent [file dirname $dir]
	if {$dir == "" || ($parent eq $dir)} {
	    error "Can't create the folder '$dir' because\
	      the disk doesn't exist."
	}
	file::ensureDirExists $parent
	file mkdir $dir
	return 1
    }
    return 0
}

## 
 # -------------------------------------------------------------------------
 # 
 # "file::isNetworked" --
 # 
 #  Calling 'file exists' on a networked file which may not exist is a 
 #  rather time consuming operation.  We can use this to avoid such
 #  calls in, for example, the recent files menu.
 # -------------------------------------------------------------------------
 ##
proc file::isNetworked {file} {
    global tcl_platform
    switch -- $tcl_platform(platform) {
	"macintosh" {
	    return 0
	}
	"windows" {
	    return [expr {[string range [file nativename $file] 0 1] == "\\\\"}]
	}
	"unix" {
	    return 0
	}
    }
}

if {${alpha::macos}} {
    proc file::isLocal {fname} {
	set vol [lindex [file split [file normalize $fname]] 0]
	if {[catch {
	    tclAE::build::resultData 'MACS' core getd ----\
	      [tclAE::build::propertyObject isrv\
		[tclAE::build::nameObject cdis\
		  [tclAE::build::TEXT $vol]]]
	  } res]} then {return 0}
	return $res
    }
} else {
    proc file::isLocal {file} {
	return [expr {![file::isNetworked $file]}]
    }
}

proc file::openInDefault {file} {
    set file [file::ensureStandardPath $file]
    if {[file isfile $file]} {
	if {[lindex [file system $file] 0] ne "native"} {
	    # Not a native file; copy to temp and try again
	    set newfile [temp::path exec [file tail $file]]
	    if {![file exists $newfile]} {
		file copy $file $newfile
	    }
	    set file $newfile
	}
	global tcl_platform
	switch -- $tcl_platform(platform) {
	    "macintosh" {
		sendOpenEvent -noreply Finder "${file}"
	    }
	    "windows" {
		windows::Launch $file
	    }
	    "unix" {
		if {$tcl_platform(os) == "Darwin"} {
		    sendOpenEvent -noreply Finder "${file}"
		} else {
		    alertnote "Opening such a file not yet implemented"
		}
	    }
	}
    } else {
	file::showInFinder $file
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "file::sendToBrowser" --
 # 
 # Based on the HTML mode proc [html::SendWindow], attempt to open the given
 # file in the user's designated browser.  It works best when the file has
 # the .html extension, at other times Mac OS X (or perhaps just Safari) will
 # just display the file in the Finder.
 # 
 # Any improvements would be welcome.
 # 
 # --------------------------------------------------------------------------
 ##

proc file::sendToBrowser {fileName} {
    
    global browserSig tcl_platform alpha::macos
    
    if {![file isfile $fileName]} {
	error "The file doesn't exist: \"$fileName\""
    }
    if {${alpha::macos}} {
	if {[catch {app::launchBack $browserSig}]} {
	    app::getSig "Please locate your web browser" browserSig
	    app::launchBack $browserSig
	}
	if {$browserSig == "MOSS" || $browserSig == "MOZZ" || $browserSig == "hbwr"} {
	    sendOpenEvent noReply '$browserSig' $fileName
	} else {
	    set fileName [quote::Url $fileName \
	      [expr {($tcl_platform(platform) eq "macintosh")}]]
	    regsub -all [file separator] $fileName "/" fileName
	    if {($tcl_platform(platform) eq "macintosh")} {
		set fileName "/$fileName"
	    }
	    set browserList [list "CHIM" "OWEB" "MSIE" "sfri"]
	    if {($tcl_platform(platform) eq "unix") \
	      && ([lsearch $browserList $browserSig] == -1)} {
		if {[regexp {/Volumes} $fileName]} {
		    regsub {/Volumes} $fileName "" fileName
		} else {
		    set fileName "/[quote::Url [file::startupDisk]]$fileName"
		}
	    }
	    tclAE::send '$browserSig' WWW! OURL "----" \
	      [tclAE::build::TEXT file://${fileName}] FLGS 1
	}
    } elseif {($tcl_platform(platform) eq "windows")} {
	exec $browserSig [file nativename $fileName] &
    } elseif {($tcl_platform(platform) eq "unix")} {
	set fileName [quote::Url $fileName]
	exec $browserSig -remote openURL(file://$fileName) &
    }
    switchTo '$browserSig'
    return
}

proc file::browseFor {fileName} {
    set system [lindex [file system $fileName] 0]
    if {$system == "native"} {
	return [findFile $fileName]
    } else {
	if {[file isfile $fileName]} {
	    set fileName [file dirname $fileName]
	}
	return [file::openViaListpicks $fileName]
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "file::openViaListpicks" --
 # "file::selectViaListpicks" --
 # 
 # If "fileName" is a directory, we recursively offer a list-pick dialog
 # which includes all of the files (and folders) contained within it.  Each
 # time that the dialog appears, we display the full path in the status bar
 # so that the user is reminded of where s/he is in the filesystem hierarchy.
 # All directories are indicated as such in the dialog by appending the OS
 # file separator to the end.
 # 
 # (There is a MacClassic workaround required here, since
 # 
 #     ÇAlpha 8È file join $HOME Cache
 #     cbu:Applications (Mac OS 9):Text Applications:Alpha 8.0b15:Cache
 #     ÇAlpha 8È file join $HOME Cache:
 #     Cache:
 # 
 # Big Dumb Bother.  But maybe this safeguard should be used for all OS?)
 # 
 # Once the user has chosen a valid file, it is opened in Alpha.  If at any
 # time the user cancels the dialog, a "cancel" error is thrown.
 # 
 # --------------------------------------------------------------------------
 ##


proc file::openViaListpicks {fileName} {
    return [edit -c [file::selectViaListpicks $fileName]]
}

proc file::selectViaListpicks {fileName} {

    global alpha::macos
    
    variable ovlDefaults
    variable svlDefaults
    variable svlDefaultsSaved
    
    if {[info exists ovlDefaults]} {
	foreach dir [array names ovlDefaults] {
	    prefs::renameOld file::ovlDefaults($dir) file::svlDefaults($dir)
	}
    } 
    if {![file exists $fileName]} {
	error "The file/folder \"${fileName}\" doesn't exist."
    }
    set upOneLevel ".. (up one level)"
    while {[file isdirectory $fileName]} {
	set fileName [string trimright $fileName [file separator]]
	append fileName [file separator]
	set what [list]
	set disp [list]
	if {[file dirname $fileName] ne $fileName} {
	    lappend disp $upOneLevel
	}
	foreach f [lsort -dictionary [glob -nocomplain -dir $fileName *]] {
	    set dispF [file tail $f]
	    if {[file isdir $f]} {
		append dispF [file separator]
		lappend what "folder"
	    } else {
		lappend what "file"
	    }
	    lappend disp $dispF
	}
	set dirTail [file tail $fileName]
	if {([llength $disp] <= 1)} {
	    alertnote "The \"${dirTail}\" folder is empty."
	    set fileName [file dirname $fileName]
	    continue
	}
	set what [join [lsort -dictionary -unique $what] " or "]
	set p "Choose a $what in \"${dirTail}\""
	set L ""
	if {[info exists svlDefaults($fileName)]} {
	    set L $svlDefaults($fileName)
	} 
	if {([lsearch -exact $disp $L] == -1)} {
	    if {[lindex $disp 0] ne $upOneLevel} {
	        set L [lindex $disp 0]
	    } else {
		set L [lindex $disp 1]
	    }
	}
	status::msg "Browsing:\
	  [string trimright $fileName [file separator]][file separator]"
	set choice [listpick -p $p -L [list $L] $disp]

	if {($choice eq $upOneLevel)} {
	    set fileName [file dirname $fileName]
	} else {
	    if {(${alpha::macos} == 1)} {
		set choice [string trim $choice [file separator]]
	    } 
	    set svlDefaults($fileName) $choice
	    set fileName [file join $fileName $choice]
	}
    }
    if {![info exists svlDefaultsSaved]} {
	prefs::modified svlDefaults
	set svlDefaultsSaved 1
    }
    status::msg ""
    return $fileName
}

# Will throw an error if the operation fails.
proc file::setLockState {file {locked 1}} {
    global tcl_platform
    switch -- $tcl_platform(platform) {
	"macintosh" {
	    file attributes $file -readonly $locked
	}
	"unix" {
	    if {$locked} {
		file attributes $file -permissions u-w
	    } else {
		file attributes $file -permissions u+w
	    }
	}
	"windows" {
	    file attributes $file -readonly $locked
	}
    }
}

proc file::openAny {file} {
    if {![file exists $file]} {
	alertnote "The file '$file' doesn't exist."
	return
    }
    if {[catch {
	set file [file::ensureStandardPath $file]
	getFileInfo $file a
	# If it's a file or an alias
	if {[file isfile $file] \
	  || ([file type $file] == "unknown" && (![info exists a(type)] || ($a(type) != "fdrp")))} {
	    if {![info exists a(type)] || ($a(type) == "TEXT") \
	      || ($a(type) == "")} {
		edit -c $file
	    } else {
		global tcl_platform
		switch -- $tcl_platform(platform) {
		    "macintosh" {
			sendOpenEvent -noreply Finder "${file}"
		    }
		    "windows" {
			windows::Launch $file
		    }
		    "unix" {
			if {$tcl_platform(os) == "Darwin"} {
			    sendOpenEvent -noreply Finder "${file}"
			} else {
			    alertnote "Opening such a file not yet implemented"
			}
		    }
		}
	    }
	} else {
	    file::browseFor $file
	}
    } err]} {
	if {[string match -nocase "*cancel*" $err]} {
	    return -code error $err
	} else {
	    alertnote "There was an error trying to open '$file': $err"
	}
    }
}

proc file::renameTo {} {
    if {![llength [winNames]]} {return}

    if {![win::IsFile [win::Current] origfile]} {
	alertnote "'[win::Current]' is not a file window!" ; return 
    }
    
    # If this file belongs to a fileset, we'll probably want
    # to rebuild it.
    set rebuildFileset [fileset::findForFile $origfile]
    if {$rebuildFileset eq ""} {
	set new [prompt "New name for file:" [file tail $origfile]]
    } else {
	set res [dialog::make \
	  [list "New name for file:" \
	  [list var "Name" [file tail $origfile] \
	  "Enter the file's new name here"] \
	  [list flag "Update its '$rebuildFileset' fileset too." 1 \
	  "This file belongs to the '$rebuildFileset' fileset which\
	  will probably need rebuilding."]]]
	set new [lindex $res 0]
	# If we don't want to rebuild, then reset this variable.
	if {![lindex $res 1]} {
	    set rebuildFileset ""
	}
    }
    
    set to [file join [file dirname $origfile] $new]
    
    if {[file tail $origfile] eq $new} {
	# Nothing changed
	return
    }
    
    if {[file normalize $origfile] eq [file normalize $to]} {
	# We've probably just changed to case of the name, on a 
	# case-insensitive filesystem.  This just means we
	# need to do things in two stages.
	set twoStage 1
    } else {
	if {[file exists $to]} {
	    alertnote "File '$to' already exists!"
	    return
	}
    }
    
    killWindow
    
    if {[info exists twoStage]} {
	set n 0
	while {[file exists $origfile$n]} { incr n }
	if {[catch {
	    # We workaround an apparent bug in WinTcl here.
	    set dir [pwd]
	    cd [file dirname $origfile]
	    file rename [file tail $origfile] [file tail $origfile$n]
	    file rename [file tail $origfile$n] [file tail $to]
	    cd $dir
	} err]} {
	    alertnote "Rename unsuccessful: $err"
	    edit -c $origfile
	    return
	}
    } else {
	if {[catch {file rename $origfile $to} err]} {
	    alertnote "Rename unsuccessful: $err"
	    edit -c $origfile
	    return
	}
    }
    edit -c $to
    # Rebuild the file's fileset, if desired.
    if {$rebuildFileset ne ""} {
	updateAFileset $rebuildFileset
    }
}

proc file::standardFind {f} {
    global HOME auto_path PREFS smarterSourceFolder
    set dirs $auto_path
    lappend dirs [file join $HOME Tcl Completions] $PREFS \
      [file join $HOME Help] [file join $HOME Tools]
    if {[info exists smarterSourceFolder]} { lappend dirs $smarterSourceFolder }
    foreach dir $dirs {
	if {[file exists [file join ${dir} ${f}]]} {
	    return [file join ${dir} ${f}]
	}
    }
    if {[regexp -- [quote::Regfind [file separator]] $f]} {
	foreach dir $dirs {
	    if {[file exists [file join [file dirname $dir] $f]]} {
		return [file join [file dirname $dir] $f]
	    }
	}
    }
    error "File '$f' not found"	
}

## 
 # -------------------------------------------------------------------------
 # 
 # "file::compareModifiedDates" --
 # 
 #  Return -1 if first file is older, 0 if they have equal dates,
 #  and 1 if the second file is older.
 # -------------------------------------------------------------------------
 ##
proc file::compareModifiedDates {a b} {
    # bigger = newer
    set ma [file mtime [win::StripCount $a]]
    set mb [file mtime [win::StripCount $b]]
    if {$ma < $mb} {
	return -1
    } elseif {$ma == $mb} {
	return 0
    } else {
	return 1
    }
}

proc file::compareDates {a op b} {
    # bigger = newer
    set ma [file mtime [win::StripCount $a]]
    set mb [file mtime [win::StripCount $b]]
    return [expr ($ma $op $mb)]
}

proc file::sameModifiedDate {a b} {
    return [expr {[file::compareModifiedDates $a $b] == 0}]
}

proc file::secondIsOlder {a b} {
    return [expr {[file::compareModifiedDates $a $b] == 1}]
}

proc file::replaceSecondIfOlder {a b {complain 1} {backup ""}} {
    if {![file exists $a]} { error "file::replaceSecondIfOlder -- first file '$a' does not exist!" }
    if {[file exists $b]} {
	if {[file::secondIsOlder $a $b]} {
	    file::remove [file dirname $b] [list [file tail $b]] $backup
	    file::coreCopy $a $b
	    install::log "Copied [file tail $a] to $b"
	    return 1
	} elseif {[file::secondIsOlder $b $a]} {
	    install::log "The pre-existing [file tail $a] is newer than the one which was to be installed."
	}
    } elseif {$complain} { 
	error "file::replaceSecondIfOlder -- second file '$b' does not exist!"
    } else {
	file::coreCopy $a $b
	install::log "Copied [file tail $a] to $b"
    } 
    return 0
}

proc file::removeCheckingWins {f} {
    install::log "Removed $f"
    set res 0
    foreach win [file::hasOpenWindows $f] {
	killWindow -w $win
	set res 1
    }
    file delete $f
    return $res
}

proc file::remove {to files {backup ""}} {
    foreach f $files {
	if {[file exists [file join $to $f]]} {
	    file::removeOne [file join $to $f] $backup
	}
    }
}

proc file::removeOne {f {backup ""}} {
    set ff [file tail $f]
    status::msg "Removing old '$ff'"
    if {${backup} != ""} {
	if {![file exists $backup]} { file mkdir $backup }
	set i ""
	while {[file exists [file join $backup $ff$i]]} {
	    if {$i == ""} { set i 0}
	    incr i
	}
	file copy $f [file join ${backup} $ff$i]
    }
    file::removeCheckingWins $f
}

# This function is really MacOS only,
# unless getFileInfo returns something useful.
proc file::getType {f} {
    global alpha::platform alpha::macos
    if {${alpha::macos} && ([info tclversion] > 8.4)} {
	# Tcl 8.5a0 supports this, but only on some filesystem types
	if {![catch {file attributes $f -type} result]} {
	    # Does this work for directories?
	    return $result
	}
	return ""
    } elseif {(${alpha::macos} == 2) && [file isdirectory $f]} {
	set f [file normalize $f]
	if {[string index $f 0] == "/"} {
	    regsub -all "/" [string range $f 1 end] ":" f
	}
	if {[catch {tclAE::build::resultData 'MACS' core getd ---- \
	  [tclAE::build::propertyObject asty \
	  [tclAE::build::nameObject file [tclAE::build::TEXT $f]]]} res]} {
	    return ""
	}
	return $res
    } else {
	if {[catch {getFileInfo $f arr}] || ![info exists arr(type)]} { 
	    return "" 
	}
	return $arr(type)
    }
}


# This function is really MacOS only, 
# unless getFileInfo returns something useful.
proc file::getSig {f} {
    global alpha::platform alpha::macos
    if {${alpha::macos} && ([info tclversion] > 8.4) \
      && ![file isdirectory $f]} {
	# Tcl 8.5a0 supports this, but only on some filesystem types
	if {![catch {file attributes $f -creator} result]} {
	    return $result
	}
    } 
    # If this failed, try getFileInfo (since Alpha 8.0b16, the case of bundles is handled)
    if {![catch {getFileInfo $f arr}] && [info exists arr(creator)]} { 
	return $arr(creator)
    }
    # As a last resort, on OSX, try an AE to "System Events" (works only
    # since Panther, not with Jaguar)
    if {${alpha::macos} == 2} {
	app::launchBack sevs
	if {![catch {
	    set aedesc [tclAE::send -r 'sevs' core getd ----\
	      [tclAE::build::propertyObject pALL \
	      [tclAE::build::nameObject cobj [tclAE::build::TEXT $f]]]]
	    set objDesc [tclAE::getKeyDesc $aedesc ----]
	    tclAE::getKeyData $objDesc fcrt
	} res]} {
	    return $res
	}
    }
    
    # If everything failed, return an empty string
    return "" 
}

# This function is really MacOS only
proc file::setType {f type {quietly 0}} {
    global alpha::platform alpha::macos
    if {!${alpha::macos}} {
	error "MacOS only"
    }
    if {!$quietly} {
	status::msg "Converting $f"
    } 
    if {(${alpha::platform} eq "tk")} {
	file attributes $f -type $type
    } else {
	if {[file isfile $f] && ([file::getType $f] ne $type)} {
	    setFileInfo $f type $type
	}	
    }
    return
}

# This function is really MacOS only
proc file::setSig {f sig {quietly 0}} {
    global alpha::platform alpha::macos
    if {!${alpha::macos}} {
	error "MacOS only"
    }
    if {!$quietly} {
	status::msg "Converting $f"
    } 
    if {${alpha::platform} == "tk"} {
	file attributes $f -creator $sig
    } else {
	if {[file isfile $f] && ([file::getType $f] eq "TEXT") \
	  && ([file::getSig $f] ne $sig)} {
	    setFileInfo $f creator $sig
	}	
    }
    return
}

# This function is really MacOS only
proc file::toAlphaSigType {f} {
    global alpha::platform alpha::macos
    if {!${alpha::macos}} {
	return 0
    }
    set type "TEXT"
    set sig  [expr {(${alpha::platform} eq "alpha") ? "ALFA" : "AlTk"}]
    file::setType $f $type 1
    file::setSig  $f $sig  1
    return 1
}

## 
 # -------------------------------------------------------------------------
 # 
 # "file::findAllInstances" --
 # 
 #  Returns all instances of a given pattern in a file.  This is a regexp
 #  search, and the pattern must match all the way to the end of the 
 #  file.  Here is an example usage:
 #  
 #  	set pat2 {^.*\\(usepackage|RequirePackage)\{([^\}]+)\}(.*)$}
 #  	set subpkgs [file::findAllInstances $fileName $pat2 1]
 #  
 #  Notice the pattern ends in '(.*)$', this is important.
 #  Notice that since there is one extra '()' pair in the regexp,
 #  we give '1' as the last argument.
 #  
 #  WARNING:  Calling this procedure incorrectly can easily result
 #  in an infinite loop.  This will tend to crash Alpha and is hard
 #  to debug using trace-dumps, because Alpha will tend to crash
 #  whilst tracing too!  To debug, modify the 'while' loop so that it
 #  also increments a counter, and stops after a few iterations.
 # -------------------------------------------------------------------------
 ##
proc file::findAllInstances {fileName searchString {extrabrackets 0}} {
    # Get the text of the file to be searched:
    if {[lsearch -exact [winNames -f] $fileName] >= 0} {
	set fileText [getText -w $fileName [minPos] [maxPos -w $fileName]]
    } elseif {[file exists $fileName]} {
	set fd [alphaOpen $fileName]
	set fileText [read $fd]
	close $fd
    } else {
	return ""
    }
    # Search the text for the search string:
    while {[string length $fileText]} {
	set dmy [lrange "d d d d d d" 0 $extrabrackets]
	if {[eval regexp -- [list $searchString] [list $fileText] $dmy match fileText]} {
	    lappend matches $match
	} else {
	    break
	}
    }
    if {[info exists matches]} {
	return $matches
    } else {
	return ""
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "file::findClosestMatch" --  ?-w <window>? pattern ?regexp? ?position?
 # 
 # Looks around for a particular sequence of characters (or a regexp) in the
 # specified window and returns the positions of the closest fit, either
 # fowards or backwards, or an empty list if no match was found.  Defaults to
 # the active window.
 # 
 # Note that "closest" is determined by the distance of the _start_ of the 
 # string that was found to the original position.
 # 
 # --------------------------------------------------------------------------
 ##

proc file::findClosestMatch {args} {
    
    win::parseArgs w pattern {regExp 0} {pos ""}
    
    requireOpenWindow
    if {($pos ne "")} {
	set pos [getPos -w $w]
    }
    set matchBeg [search -w $w -n -s -f 0 -r $regExp -- $pattern $pos]
    set matchEnd [search -w $w -n -s -f 1 -r $regExp -- $pattern $pos]
    set foundBeg [lindex $matchBeg 0]
    set foundEnd [lindex $matchEnd 0]
    set diffBeg  [pos::diff -w $w $foundBeg $pos]
    set diffEnd  [pos::diff -w $w $pos $foundEnd]
    
    # Return whatever we can, possibly an empty list.
    if {($foundBeg ne "") && ($foundEnd ne "")} {
	if {($diffBeg <= $diffEnd)} {
	    return $matchBeg
	} else {
	    return $matchEnd
	}
    } elseif {($foundBeg ne "")} {
	return $matchBeg
    } elseif {($foundEnd ne "")} {
        return $matchEnd
    } else {
        return [list]
    } 
}

## 
 # -------------------------------------------------------------------------
 #	 
 #  "file::preOpeningConfigurationCheck" --
 #	
 #  This is an adaptation of Tom Pollard's emacs mode setting facility.
 #  It is called from filePreOpeningHook (called by Alpha's core very
 #  early inside 'edit'), which means it takes effect before the window
 #  yet exists, so you don't get a double redraw.  Here are Tom's
 #  comments from the original:
 #	   
 #   # Emacs-style mode selection using first nonblank line of file
 #   #
 #   # Checks for interpreter line "#!/dir/subdir/command ...", or
 #   # explicit major mode election "-*-Mode: vars ...-*-".
 #   #
 #   # "command" or "Mode" is compared (case-insensitively) to Alpha mode
 #   # names and first matching mode is used for the file.
 #   #
 #   # Author:   Tom Pollard	<pollard@chem.columbia.edu>
 #   # Modified: 9/11/95
 #	
 #  Note: this proc actually opens the file for reading.  It _must_
 #  close the file before exiting.  If you modify this proc, make sure
 #  that happens!
 #  
 #  The 'name' argument is the name of the file, which must exist,
 #  the 'winname' argument is the name of the window which will/would
 #  be opened in Alpha, which is there $name with possible a string
 #  like ' <2>' appended.
 #  
 #  Results:
 #  
 #  This procedure returns the mode to be used for the given file, if
 #  it can be ascertained from the contents/type of the file.  Note
 #  that we do NOT look at the file's extension.  That is handled by
 #  ::mode::findForWindow.
 #  
 #  Side effects:
 #  
 #  The proc win::setInitialConfig may be called with additional
 #  configuration options for this window (e.g. encoding, tabsize,
 #  etc.).  Therefore if you want to call this procedure manually, you
 #  must afterwards cleanup with win::getAndReleaseInitialInfo $winname.
 #	
 # --Version--Author------------------Changes-------------------------------  
 #    1.0     <vince@santafe.edu> first modification from Tom Pollard's
 #    1.1     <vince@santafe.edu> copes with a common Tcl/Tk exec trick.
 #    1.2     <vince@santafe.edu> can map creators if desired.
 #    1.3     <vince@santafe.edu> revamped for better win/file separation
 # -------------------------------------------------------------------------
 ##
proc file::preOpeningConfigurationCheck {name {winname ""}} {
    if {![file exists "$name"]} {
	error "No such file '$name'"
    }
    if {[catch [list ::alphaOpen "$name" r] fid]} { return }
    # find first non-empty line. Return if we fail
    for { set line "" } { [string trim $line] == "" } {} {
	if { [gets $fid line] == -1} { ::close $fid ; return }
    }
    if {$winname == ""} {set winname $name}

    # Check for unicode.
    if {[regexp -- \xFE\xFF $line]||[regexp -- \xFF\xFE $line]} {
	fconfigure $fid -encoding unicode
	set encoding unicode
	# rewind -- real reading is still to come
	seek $fid 0 start
	for { set line "" } { [string trim $line] == "" } {} {
	    if {[gets $fid line] == -1} {::close $fid ; return}
	}
	win::setInitialConfig $winname encoding unicode "window"
    }
    
    set ll $line
    while {[regexp -- "\\((\[a-zA-Z\]+):(\[^\\)\]+)\\)(.*)" $ll "" var val ll]} {
	win::setInitialConfig $winname $var $val "window"
    }
    global modeCreator
    if {[info exists modeCreator([set sig [file::getSig $name]])]} {
	return $modeCreator($sig)
    }
    if {[regexp -nocase -- {^[^\n\r]*[-# \(]install($|[- \)])} $line]} {
	global HOME
	if {![file::pathStartsWith $name [file join $HOME Tcl]] \
	  && ![file::pathStartsWith $name [file norm [file join $HOME Tcl]]]} {
	    ::close $fid
	    return "Inst"
	}
    }
    # See if a unix executable name is embedded in the first line
    set nextLineGetter [format {
	if {[gets %s ll] == -1} { break }
	set ll
    } $fid]
    
    set majorMode [mode::getFromUnixFirstLine $line $nextLineGetter]
    ::close $fid
    if {$majorMode eq ""} {
	return
    }
    
    global unixMode

    if {[info exists unixMode($majorMode)]} {
	set m $unixMode($majorMode)
	hook::callAll unixModeHook $majorMode $name
	return $m
    } else {
	set m [mode::listAll]
	if {[set i [lsearch -exact [string tolower $m] $majorMode]] != -1} {
	    return [lindex $m $i]
	}
    }
    # $majorMode didn't match anything we know about.
    return
}

proc file::pathEndsWith {name filelist {optionalchar ""}} {
    # This stuff is necessary on Windows where there can be a
    # variety of possible file separators (back and forwards slashes).
    # On other platforms we should find the correct file first time
    # through the loop.
    
    lappend separators [file separator]
    if {!([file separator] eq [file nativename [file separator]])} {
	lappend separators [file nativename [file separator]]
    }
    if {!([file separator] eq [file join [file separator]])} {
	lappend separators [file join [file separator]]
    }
    foreach n [list $name [file nativename $name]] {
	foreach s $separators {
	    set flist $filelist
	    if {$optionalchar != ""} {
		set reg "[quote::Regfind $s$n]${optionalchar}?$"
	    } else {
		set reg "[quote::Regfind $s$n]$"
	    }
	    if {[file exists $n] && [set ind [lsearch -exact $flist $n]] >= 0} {
		return $n
	    }
	    while {[set ind [lsearch -regexp $flist $reg]] >= 0} {
		set f [lindex $flist $ind]
		if {[file exists $f]} {
		    return $f
		}
		set flist [lrange $flist [incr ind] end]
	    }
	}
    }
    return ""
}

# Below:
#		Expanded version of old 'DblClickAux.tcl'
# 
# Authors: Tom Pollard <pollard@chem.columbia.edu>
#	  Tom Scavo   <trscavo@syr.edu>
#	  Vince Darley <vince@santafe.edu>
# 
#  modified by  rev reason
#  -------- --- --- -----------
#  9/97     VMD 1.0 reorganised for new alpha distribution.
# ###################################################################
##

#############################################################################
# Take any valid Macintosh filespec as input, and return the
# corresponding absolute filespec.  Filenames without an explicit
# folder are resolved relative to the folder of the current document.
#
proc file::absolutePath {fileName} {
    set name [file tail $fileName]
    set subdir [file dirname $fileName]
    if {($subdir == ":") || ($subdir == ".")} {
	set subdir ""
    }
    if {[string length $subdir] > 0 && [string index $subdir 0] != ":"} {
	set dir ""
    } else {
	set dir [file dirname [lindex [winNames -f] 0]]
	# when window has no path (tcl shell for instance), use pwd
	if {($dir == ":") || ($dir == ".")} {
	    set dir [pwd]
	}
    }
    return [file join $dir $subdir $name]
}


#############################################################################
# Open the file specified by the full pathname "$fileName"
# If it's already open, just switch to it without any fuss.
# 
# Returns the name of the window which results.
proc file::openQuietly {fileName} {
    if {![file exists $fileName]} {
	return -code error "could not read \"$fileName\": no\
	  such file or directory"
    }
    set win [edit -c -w $fileName]
    if {[icon -q]} {icon -o}
    return $win
}

#############################################################################
# Searches $fileName for the given pattern $searchString.  If the 
# search is successful, returns the matched string; otherwise returns
# the empty string.  If the flag 'indices' is true and the search is
# successful, returns a list of two character offsets into the
# file giving the indices of the
# found string; otherwise returns the list '-1 -1'.
#
proc file::searchFor {fileName searchString {indices 0}} {
    # Get the text of the file to be searched:
    if {[lsearch -exact [winNames -f] $fileName] >= 0} {
	set fileText [getText -w $fileName [minPos] [maxPos -w $fileName]]
    } elseif {[file exists $fileName]} {
	set fd [::alphaOpen $fileName]
	set fileText [::read $fd]
	::close $fd
    } else {
	if { $indices } {
	    return [list -1 -1]
	} else {
	    return ""
	}
    }
    # Search the text for the search string:
    if { $indices } {
	if {[regexp -indices -- $searchString $fileText mtch]} {
	    # Fixes an apparent bug in 'regexp':
	    return [list [lindex $mtch 0] [expr {[lindex $mtch 1] + 1}]]
	} else {		
	    return [list -1 -1]
	}
    } else {
	if {[regexp -- $searchString $fileText mtch]} {
	    return $mtch
	} else {		
	    return ""
	}
    }
}


#############################################################################
#  Save $text in $fileName.  If $text is null, create an empty file.
#  Overwrite if {$overwrite} is true or the file does not exist; 
#  otherwise, prompt the user.
#
proc file::writeAll {fileName {text {}} {overwrite 0} {enc ""}} {
    if { $overwrite || ![file exists $fileName] } {
	status::msg "Saving ${fileName}É"
	if {$enc != ""} {
	    set fd [::open $fileName "w"]
	    fconfigure $fd -encoding $enc
	} else {
	    set fd [::alphaOpen $fileName "w"]
	}
	puts -nonewline $fd $text
	::close $fd
    } else {
	if {[dialog::yesno "File $fileName exists!  Overwrite?"]} {
	    file::writeAll $fileName $text 1 $enc
	} else {
	    status::msg "No file written"
	}
    }
}
    
# This proc opens a file and sets a specified selection.  If the file is a
# temporary file, the original file or window is used instead, with the
# selection appropriately adjusted.  It also accepts names of open windows
# not associated to a file on disk, or open windows specified by their tail
# name.
# 
# (This proc is a refined version of the good-old [file::gotoLine] which 
# will henceforth be a mere wrapper for this one.  The extra flexibility is
# natural to have, and in particular will be needed by the next version of 
# alphac which will be routed through here too.)
proc file::openWithSelection { fileName row0 col0 row1 col1 } {

    #### Plugin for redirecting temporary files ####
    if {![catch {temp::attributesForFile $fileName} tinfo]} {
	set fileName [lindex $tinfo 0]
	set lineOffset [lindex $tinfo 1]
	set row0 [expr {$row0 + $lineOffset}]
	set row1 [expr {$row1 + $lineOffset}]
    }
    #### End of tmp files plugin ####

    # If $fileName is an open window (not necessarily a file on disk,
    # or otherwise a file on disk but given just by its tail name), then
    # use that window:
    if { [win::Exists $fileName] || [lcontain [winNames] $fileName] } {
	set w $fileName
    } else {
	# Otherwise open the file:
	set fileName [file normalize $fileName]
	if {![file readable $fileName]} {
	    error "File \"$fileName\" is not readable"
	}
	set w [edit -c $fileName]
    }

    # Set the selection:
    set pos0 [pos::fromRowCol -w $w $row0 $col0]
    set pos1 [pos::fromRowCol -w $w $row1 $col1]
    selectText -w $w $pos0 $pos1
    
    switchTo $::ALPHA
    bringToFront $w 
    refresh -w $w
    return $w
}


# Merely a wrapper for [file::openWithSelection]
proc file::gotoLine { fname line {mesg ""} } {
    if { [catch {openWithSelection $fname $line 0 [expr {$line + 1}] 0} res] } {
	alertnote $res
	return
	# (We don't give the message when failing)
    }
    if { [string length $mesg] } {
	status::msg $mesg 
    }
    return $res
}


# Old version of [file::gotoLine]:
# #############################################################################
# #  Highlight (select) a particular line in the designated file, opening the
# #  file if necessary.  Returns the full name of the buffer containing the
# #  opened file.  If provided, a message is displayed on the status line.
# #
# proc file::gotoLine { fname line {mesg {}} } {
#     if { [file readable $fname] } {
# 	# Replace all this block with 'edit -c $fname' when bug 983 is
# 	# fixed.
# 
# 	set wins [file::hasOpenWindows $fname]
# 	if {[llength $wins]} {
# 	    bringToFront [lindex $wins 0]
# 	} else {
# 	    edit -c $fname
# 	}
#     } elseif { [lsearch -exact [winNames] $fname] >= 0 } {
# 	# It's just the tail of a path
# 	bringToFront $fname
#     } else {
# 	alertnote "File \" $fname \" not found."
# 	return
#     }
#     # Finally we have the correct window frontmost.  Now goto $line:
#     set pos [pos::fromRowCol $line 0]
#     selectText [lineStart $pos] [nextLineStart $pos]
#     if { [string length $mesg] } {
# 	status::msg $mesg 
#     }
#     refresh
#     return [win::Current]
# }



#############################################################################
# Return a list of all subfolders found within $dirName,
# down to some maximum recursion depth.  The top-level
# folder is not included in the returned list.
#
proc file::hierarchy {dirName {depth 3}} {
    set folders {}
    if {$depth > 0} {
	
	incr depth -1
	foreach m [glob -nocomplain -type d -directory $dirName -- *] {
	    eval [list lappend folders $m] [file::hierarchy $m $depth]
	}
    }
    return $folders
}

# Note that pattern is a pattern for use by 'string match' and not
# a glob-style pattern (which would also allow {a,b,c} patterns)
proc file::recurse {dir {pat "*"} {hidden 0}} {
    if {![file exists $dir]} {return [list]}
    set files [list]
    
    set flist [glob -nocomplain -dir $dir -- *]
    if {$hidden} {
	eval lappend flist [glob -nocomplain -dir $dir -types hidden -- *]
    }
    foreach f $flist {
	if {[file isdirectory $f]} {
	    eval lappend files [file::recurse $f $pat $hidden]
	} elseif {$pat eq "*"} {
	    lappend files $f
	} elseif {[string match $pat [file tail $f]]} {
	    lappend files $f
	}
    }
    return $files
}

proc file::touch {fileName {depth 3}} {
    if {[file isfile $fileName]} {
	file mtime $fileName [now]
	return
    }
    if {$depth == 0} {return}
    foreach ff [glob -nocomplain -dir $fileName *] {
	file::touch $ff [expr {$depth -1}]
    }
}

proc file::revertThese {args} {
    foreach fileName $args {
	foreach window [file::hasOpenWindows $fileName] {
	    revert -w $window
	}
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "file::completeFromDir" --
 # 
 #  Here's a good example:
 # 
 #    set fileName [prompt::statusLineComplete "Open which file" \
 #       [list file::completeFromDir [file join $HOME Help]] \
 #        -nocache -tryuppercase]
 #  
 #  Returns the list of files in '$dirName' which start with 
 #  '$filePrefix'.
 # -------------------------------------------------------------------------
 ##
proc file::completeFromDir {dirName filePrefix} {
    return [glob -nocomplain -path [file join $dirName $filePrefix] -tails *]
}

proc file::decompress {fileName} {
    switch -- [file extension $fileName] {
	".tgz" -
	".gz" {
	    xserv::invoke unzip -file $fileName
	}
	".tar" {
	    app::execute -op untar -flags "-xf" \
	      -filename $fileName -flagsFirst 1 -gotErrorVar err
	    if {!$err} {
		file delete $fileName
		return 1
	    } else {
		return 0
	    }
	}
	".zip" {
	    xserv::invoke unzip -file $fileName
	}
	".sit" - ".sitx" {
	    xserv::invoke unstuff -file $fileName
	}
	default {
	    # Perhaps should register a more general unstuffing program
	    xserv::invoke unstuff -file $fileName
	}
    }
    return 1
}

proc file::iscompressed {fileName} {
    set compressed [list .sit .bin .hqx .tar .gz .tgz .zip]
    set ext [file extension $fileName]
    if {[lsearch -exact $compressed $ext] != -1} {
	return 1
    } else {
	return 0
    }
}

proc file::convertEols {{dirNameOrNull ""}} {
    if {![string length $dirNameOrNull]} {
	set dirNameOrNull [get_directory -p "Convert files in which directory?"]
    }
    set eolType [listpick -p "Convert to which format" \
      [list "MacOS 9 (cr)" "Windows (crlf)" "Unix and MacOS X (lf)"]]
    set eol [string tolower [string range $eolType 0 2]]
    if {$eol == "uni"} { set eol "unix" }
    set dirListing [glob -dir $dirNameOrNull -type f -tails *]
    set ignore [listpick -p "Ignore any files?" -l $dirListing]
    foreach fileName $dirListing {
	if {[lsearch -exact $ignore $fileName] != -1} { continue }
	status::msg "Converting '$fileName' to $eolType"
	set conv [file join $dirNameOrNull $fileName]
	if {[file isfile $conv]} {
	    file::convertLineEndings $conv $eol
	} else {
	    status::msg "Ignoring '$fileName' since it is not a file"
	}
    }
}

# This version is for Alpha 8/Alphatk.
# The file is read and written using macRoman encoding
# to avoid that the content is mangled if it isn't utf-8 encoded.
# (Any single byte encoding could have been used when reading and writing.)
proc file::convertLineEndings {fileName eolType} {
    set contents [file::readAll $fileName macRoman]
    set fid [open $fileName w]
    fconfigure $fid -encoding macRoman
    switch -- $eolType {
	"mac" {
	    fconfigure $fid -translation cr
	}
	"unix" {
	    fconfigure $fid -translation lf
	}
	"win" {
	    fconfigure $fid -translation crlf
	}
    }
    puts -nonewline $fid $contents
    close $fid
}

proc file::hexdump {fileName} {
    # This is derived from the Tcler's WIKI, page 1599,
    # original author unknown, possibly Kevin Kenny.

    set output ""
    
    if { [ catch {
	# Open the file, and set up to process it in binary mode.
	set fid [open $fileName r]
	fconfigure $fid -translation binary -encoding binary
	
	while { ! [ eof $fid ] } {
	    # Record the seek address. Read 16 bytes from the file.
	    set addr [tell $fid]
	    set s    [read $fid 16]
	    
	    # Convert the data to hex and to characters.
	    binary scan $s H*@0a* hex ascii
	    
	    # Replace non-printing characters in the data.
	    regsub -all -- {[^[:graph:] ]} $ascii {.} ascii

	    # Split the 16 bytes into two 8-byte chunks
	    regexp -- {(.{0,16})(.{0,16})} $hex -> hex1 hex2
	    
	    # Convert the hex to pairs of hex digits
	    regsub -all -- {..} $hex1 {& } hex1
	    regsub -all -- {..} $hex2 {& } hex2
	    
	    # Put the hex and Latin-1 data to the channel
	    append output [format "%08x %-24s %-24s %-16s\n" \
	      $addr $hex1 $hex2 $ascii]
	}
    } err ] } {
	catch { ::close $fid }
	return -code error $err
    }
    # When we're done, close the file.
    catch { ::close $fid }
    return $output
}

proc file::readWinBoundsFromResource {fileName} {
    set msg ""
    if {[catch {resource open $fileName} fileResId]} {
	error $fileResId
    }
    if {[catch {resource read MPSR 1008 $fileResId} binvar]} {
	set msg $binvar
    } elseif {![binary scan $binvar S* intvar]} {
	set msg "Corrupted data in MPSR resource"
    }
    resource close $fileResId
    if {$msg!=""} {
	error $msg
    }
    return $intvar
}

proc file::writeWinBoundsInResource {fileName top left bottom right} {
    set msg ""
    if {[catch {resource open $fileName w} fileResId]} {
	error $fileResId
    }
    if {[catch {binary format SSSS $top $left $bottom $right} binvar]} {
	set msg "Invalid data: expected four integers\
	  but got '$top $left $bottom $right'."
    }
    if {[catch {resource write -force -id 1008 -file $fileResId MPSR $binvar} res]} {
	set msg $res
    }
    resource close $fileResId
    if {$msg!=""} {
	error $msg
    }
}

# ===========================================================================
# 
# .