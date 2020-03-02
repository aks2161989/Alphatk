## -*-Tcl-*-
 # ###################################################################
 #  Alphatk - the editor
 # 
 #  FILE: "alpha_io.tcl"
 #                                    created: 03/01/2000 {15:19:43 PM} 
 #                                last update: 2005-08-16 14:17:56 
 #  Author: Vince Darley
 #  E-mail: vince.darley@kagi.com
 #    mail: Flat 10, 98 Gloucester Terrace, London W2 6HP
 #     www: http://www.purl.org/net/alphatk
 #  
 # Copyright (c) 2000-2005  Vince Darley
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # In particular, while this is 'open source', it is NOT free, and
 # cannot be copied in full or in part except according to the terms
 # of the license agreement.
 # 
 # Right now only a handful of procedures actually read in the contents
 # of a file, or write out the contents of a text widget to file.
 # 
 # These are: edit, revert, save and saveAs.  We route all of the i/o
 # of these commands through putsTextToFile and readTextFromFile, which
 # in turn use alphaOpen.  This ensures we have common control over
 # encodings, error handling etc.
 # 
 # ###################################################################
 ##

#

## 
 # -------------------------------------------------------------------------
 # 
 # "putsTextToFile" --
 # 
 #  Returns 1 for success, or 0 for failure.
 #  
 # -------------------------------------------------------------------------
 ##
proc putsTextToFile {filename text enc eolplatform} {
    # Only have special handling if the file exists and is non-empty.
    if {[file exists $filename] && ([file size $filename] != 0)} {
	set overwriting 1
    } else {
	set overwriting 0
    }
    
    if {$overwriting} {
	if {[file isdirectory $filename]} {
	    alertnote "A directory with the same name already exists!\
	      Save aborted."
	    return 0
	}
	set safety [file join [file dirname $filename] __tmp_Alpha]
	if {[file exists $safety]} {
	    alertnote "Alphatk's temporary file for safe saving already\
	      exists in this directory.  If this problem persists, please\
	      report a bug.  I will remove the file now."
	    catch {file delete $safety}
	}
	if {![file writable $safety] && ![file writable $filename]} {
	    alertnote "Cannot write to this file (the filesystem has it\
	      marked as read-only).  The save has been cancelled."
	    return 0
	}
	if {[catch {file rename -force $filename $safety} err]} {
	    alertnote "Couldn't remove old file.  Save aborted (error: $err)."
	    return 0
	}
    }
    if {[catch {alphaOpen $filename -encoding $enc -eol $eolplatform w} fout]} {
	alertnote "Sorry, couldn't open the file for writing! Save aborted."
	if {$overwriting} {
	    catch {file rename -force [file join \
	      [file dirname $filename] __tmp_Alpha] $filename}
	}
	return 0
    }
    
    if {[fconfigure $fout -encoding] == "unicode"} {
	puts -nonewline $fout \uFEFF
    }
    
    if {[catch {puts -nonewline $fout $text} res]} {
	catch {close $fout}
	catch {file delete -force $filename}
	if {$overwriting} {
	    catch {file rename -force \
	      [file join [file dirname $filename] __tmp_Alpha] $filename}
	}
	alertnote "Couldn't save; had filesystem error: $res"
    } else {
	close $fout
	if {$overwriting} {
	    # Overwriting an existing file: we want to preserve various
	    # filesystem/platform-specific attributes
	    if {[lindex [file system $filename] 0] == "native"} {
		if {$::alpha::macos} {
		    global changeTypeAndCreatorOnSave
		    if {[info exists changeTypeAndCreatorOnSave] \
		      && $changeTypeAndCreatorOnSave} {
			catch {file attributes $filename \
			  -type TEXT -creator AlTk}
		    } else {
			catch {file attributes $filename \
			  -type [file attributes $safety -type] \
			  -creator [file attributes $safety -creator]}
		    }
		}
		if {$::tcl_platform(platform) == "unix"} {
		    catch {file attributes $filename \
		      -permissions [file attributes $safety -permissions]}
		}
	    }
	    catch {file delete -force $safety}
	} else {
	    # Creating a new file: we want to set various
	    # filesystem/platform-specific attributes to indicate that
	    # Alphatk created the file.
	    if {[lindex [file system $filename] 0] == "native"} {
		if {$::alpha::macos} {
		    catch {file attributes $filename -type TEXT -creator AlTk}
		}
	    }
	}
	status::msg "Wrote [file tail $filename],\
	  [string length $text] characters."
    }
    return 1
}

proc wordswap {data} {
    binary scan $data s* elements
    return [binary format S* $elements]
}

proc readTextFromFile {filename {encVar ""}} {
    global tcl_platform

    if {[string length $encVar]} {
	upvar 1 $encVar encoding
    }
    
    if {[info exists encoding] && [string length $encoding]} {
	set fin [alphaOpen $filename -encoding $encoding r]
    } else {
	set fin [alphaOpen $filename r]
    }
    # the alphaOpen may have adjusted the encoding
    set encoding [fconfigure $fin -encoding]

    if {$encoding == "unicode"} {
	fconfigure $fin -encoding binary
    }
    if {[catch {read $fin} text]} {
	catch {close $fin}
	error $text
    }
    close $fin

    if {$encoding == "unicode"} {
	if {[binary scan $text S bom] == 1} {
	    if {$bom == -257} {
		if {$tcl_platform(byteOrder) == "littleEndian"} {
		    set text [wordswap [string range $text 2 end]]
		} else {
		    set text [string range $text 2 end]
		}
	    } elseif {$bom == -2} {
		if {$tcl_platform(byteOrder) == "littleEndian"} {
		    set text [string range $text 2 end]
		} else {
		    set text [wordswap [string range $text 2 end]]
		}
	    } elseif {$tcl_platform(byteOrder) == "littleEndian"} {
		set text [wordswap $text]
	    }
	}
	set text [encoding convertfrom unicode $text]
    }
    
    # Do some nasty stuff on windows.
    global tcl_platform
    if {0 && ($tcl_platform(platform) eq "windows")} {
	if {![regexp -- "\[^\n\]\n\[^\n\]" $text] && [regexp -- "\n\n" $text]} {
	    regsub -all "\n\n" $text "\n" text
	}
    }
    # Return without overhead of 'return'
    set text
}

#¥ edit [-r] [-m] [-c] [-w] [-g <l> <t> <w> <h>] <name> - Open a file in new 
#  window. '-c' means don't prompt for duplicate win if file already open.
#  '-r' means open the file read-only. '-m' means omit the function titlebar 
#  menu and present only the marks titlebar menu, which is labeled with the 
#  contents of 'markLabel'. The '-g' option allows left and top coords to 
#  be specified, plus width, and height. All or none. '-w' allows you to
#  bypass the "Wrap" dialog for files with long rows.
proc editDocument {args} {
    global win::tk
    
    global defWidth defHeight defTop defLeft
    set opts(-g) [list $defLeft $defTop $defWidth $defHeight]

    getOpts {{-g 4} -tabsize -mode -encoding -tabbed -visibility}
    if {[llength $args] != 1} {
	return -code error "Bad arguments \"$args\" to 'edit'"
    }
    set fn [lindex $args end]
    if {![file exists $fn]} {
	# Check if this is an encoding issue, in which we were
	# called by the system with a natively encoding string,
	# which therefore hasn't been properly converted to utf.
	set ftry [encoding convertfrom [encoding system] $fn]
	if {[file exists $ftry]} {
	    set fn $ftry
	}
    }
    set n [file::ensureStandardPath $fn]
    if {$n == ""} {return}
    set name $n

    if {![file exists $n]} {
        return -code error "File \"$n\" doesn't exist"
    }
    if {![file readable $n]} {
        return -code error "File \"$n\" is not readable"
    }
    
    # Check if a window with the same name already exists.  Do 
    # not assume that any particular combination of the basic
    # window, <2>, <3> etc are present.  If /any/ of those are
    # around, we have a duplicate.
    if {[info exists win::tk($n)]} {
	set exists $n
    } else {
	foreach existname [array names win::tk] {
	    if {[win::StripCount $existname] eq $n} {
		# We found a duplicate.  Don't bother looking
		# for further duplicates.
		set exists $existname
		break
	    }
	}
    }
    
    if {[info exists exists]} {
	if {[info exists opts(-c)] || ([dialog::yesno -n "Open a duplicate" \
	  -y "Go to existing window" "That window is already open!"])} {
	    bringToFront $exists
	    return $exists
	}
    }
    
    append name [win::CountFor [file tail $n]]

    if {[info exists opts(-mode)]} {
	win::setInitialConfig $name mode $opts(-mode) "command"
    }
    if {[info exists opts(-tabsize)]} {
	win::setInitialConfig $name tabsize $opts(-tabsize) "command"
    }
    if {[info exists opts(-encoding)]} {
	win::setInitialConfig $name encoding $opts(-encoding) "command"
    }
    if {[info exists opts(-visibility)]} {
	win::setInitialConfig $name visibility \
	  $opts(-visibility) "command"
    }
    filePreOpeningHook $n $name
    # doesn't check window exists, or file tail name clash
    set encoding [win::getInitialConfig $name encoding]
    # Set the window title
    global showFullPathsInWindowTitles
    if {$showFullPathsInWindowTitles} {
	set title $name
    } else {
	if {[win::IsFile $n]} {
	    set title [file tail $name]
	} else {
	    set title $name
	}
    }

    if {[info exists opts(-tabbed)]} {
	set type "tabbed"
	set options [list $title $opts(-tabbed)]
    } else {
	set type "toplevel"
	set options [concat [list $title] $opts(-g)]
    }
    alpha::embedInto -text [readTextFromFile $n encoding] \
      -encoding $encoding -- $name $type $options
    
    # Now, the above embedding can actually result in a large chain
    # of events occurring, which might possibly have destroyed the
    # window!
    if {[win::Exists $name]} {
	if {[info exists opts(-r)] || ![file writable $n]} {
	    winReadOnly $name
	}
	update
    }
    return $name
}

#¥ revert - revert the file to its last saved version
proc revert {args} {
    win::parseArgs n

    global win::tk
    if {![info exists win::tk($n)]} { set n [winTailToFullName $n] }
    set filename [win::StripCount $n]
    if {[file exists $filename]} {
	set w $win::tk($n)
	set encoding [tw::encoding $w]
	if {[catch {readTextFromFile $filename encoding} text]} {
	    alertnote "Couldn't read the saved file's contents!  Error: $text"
	    return
	}
	getWinInfo -w $n wi
	set topl $wi(currline)
	setWinInfo -w $n read-only 0
	deleteText -w $n [minPos] [maxPos]
	insertText -w $n $text
	setWinInfo -w $n dirty 0
	revertHook $n
	removeAllMarks -w $n
	display -w $n [pos::fromRowCol -w $n $topl 0]
	if {![file writable $filename] || $wi(read-only)} {
	    setWinInfo -w $n read-only 1
	}
	update idletasks
	::tw::arrangeToColour $w
	status::msg "File window '$n' synchronised with version\
	  currently on disk"
    } else {
	if {$filename eq ""} {
	    error "Cancelled - no window open"
	} else {
	    error "No such file!"
	}
    }
}


#¥ save - save current window (or given window)
proc save {{w ""}} {
    if {$w == ""} {
	set w [lindex [winNames -f] 0]
    }

    getWinInfo -w $w info
    if {$info(read-only)} {
	return
    }
    set wn [win::StripCount $w]
    if {![file exists $wn]} {
	saveAs [file join [pwd] $wn]
    } else {
	coreSave $w $wn
    }
}

proc coreSave {winName path} {
    global win::tk
    saveHook $winName
    if {![putsTextToFile $path [text_wcmd $winName get 1.0 "end -1c"] \
      [tw::encoding $win::tk($winName)] [tw::platform $win::tk($winName)]]} {
	return
    }
    # adjust dirty, undo, redo data.
    ::tw::save $win::tk($winName)
    savePostHook $winName
}

proc saveAllowingCancel {{w ""}} {
    if {[catch {save $w} res]} {
	if {$res == "Cancelled"} {
	    return ""
	}
	return -code error $res
    }
    return $res
}

#¥ saveAs [def name] - save current window with new name. Optionally takes 
#  a default filename. Returns complete path of saved file, if ok hit, 
#  otherwise TCL_ERROR returned.
proc saveAs {args} {
    win::parseArgs oldw {default ""} args
    global win::tk showFullPathsInWindowTitles tcl_platform
    # get new stuff
    if {[llength $args]} {
	if {$default == "-f" && ([llength $args] == 1)} {
	    set name [lindex $args 0]
	    set force 1
	} else {
	    return -code error "bad args to saveAs"
	}
    } else {
	set default [saveAsDefaultHook $oldw $default]
	# This will prompt the user to ask if they want to overwrite an
	# existing file.
	set name [tk_getSaveFile -initialdir [file dirname $default] \
	  -initialfile [file tail $default] -filetypes [findFileTypes]]
    }
    if {$name == ""} {
	return -code error "Cancelled"
    }
    # Get correct, full path name for the file
    set tail [file tail $name]
    if {!([file::makeNameLegal $tail] eq $tail)} {
	return -code error "Illegal file name '$tail' to saveAs"
    }
    if {$tcl_platform(platform) == "windows"} {
	# Avoid confusion on windows by ensuring the long name, but catch
	# this in case we're inside a vfs that doesn't implement
	# 'longname'.
	if {[file exists $name]} {
	    catch {set name [file attributes $name -longname]}
	} else {
	    catch {
		set name [file join \
		  [file attributes [file dirname $name] -longname] \
		  [file tail $name]]
	    }
	}
    }
    set name [file nativename $name]
    set filename $name
    append name [win::CountFor [file tail $name] 1]

    # We need to create the filename so winChangedNameHook knows it
    # exists on disk.  Also we want to over-write any previous
    # large file which exists already.
    close [open $filename w]
    
    # The win::tk array entry includes any <2> duplicates etc.
    set tkw $win::tk($oldw)
    set win::tk($name) $tkw
    # Now clear this array entry, which means we finally forget about
    # the old window completely.  We do this unless the window is
    # being saved on top of itself (can happen if the user forces it,
    # or if the old file is deleted without Alphatk's knowledge).
    if {($oldw ne $name)} {
	unset win::tk($oldw)
    }
    if {$showFullPathsInWindowTitles} {
	alpha::windowChangeTitle $oldw $name $name
    } else {
	alpha::windowChangeTitle $oldw $name [file tail $name]
    }
    
    # This will update the window's mode, and may even change its contents,
    # or its encoding.  This must happen after we've got rid of all the
    # evidence of the old window (win::tk, win::tktitle).
    winChangedNameHook $name $oldw

    if {[$tkw statusConfigure image] eq "lock"} {
	tw::read_only $tkw 0
    }

    # Now we need to sort out what encoding to save the file in.  The
    # main issue is there might be different default encodings for the
    # current location and the new location.  There are two main cases:
    # 
    # (1) the window has no current encoding (i.e. it doesn't exist on
    # disk), and so we pick the default encoding for the window, or a
    # mode-specific one if that exists.
    # (2) the window has a current encoding.
    # 
    # In either case, we compare the resulting encoding with the desired
    # encoding for the saved-to location, and ask the user if there is 
    # a difference.
    set currEnc [tw::encoding $tkw]
    if {$currEnc == ""} {
	set currEnc [saveAsEncodingHook $name [info exists force]]
    }
    # Once a file has been saved, it has an encoding associated
    # with it.  This is either the encoding we forced on the file,
    # or the system encoding if none was set.
    $tkw encoding $currEnc
    
    coreSave $name $filename
}
