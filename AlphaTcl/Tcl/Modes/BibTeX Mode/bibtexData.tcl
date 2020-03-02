## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # BibTeX mode - an extension package for Alpha
 # 
 # FILE: "bibtexData.tcl"
 #                                          created: 08/17/1994 {09:12:06 am}
 #                                      last update: 03/21/2006 {02:51:45 PM}
 # Description: 
 # 
 # Procedures to build the bibtex files list, and to create/rebuild etc
 # the bib databases and indices.   Some of these procedures are also
 # called by command double click procs in TeX mode.
 # 
 # See the "bibtexMode.tcl" file for license info, credits, etc.
 # ==========================================================================
 ## 

proc bibtexData.tcl {} {}

# load main bib file!
bibtexMode.tcl

namespace eval Bib {}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Indices and Databases ×××× #
# 

# ===========================================================================
# 
# Bib::buildIndex
# 
# Build the bibIndex file which allows for very fast lookup of bib entries.
# If called from the menu, we don't check the "bibAutoIndex" preference.
# 

proc Bib::buildIndex {{quietly 0}} {
    
    global BibmodeVars PREFS Bib::TopPat2
    
    if {!$quietly && $BibmodeVars(bibAutoIndex) == 0} {
        alertnote "The \"Bib Auto Index\" preference is set to\
          \"Never Make Index\", so this procedure will end."
        error "The \"bibAutoIndex\" preference is set to\
          \"Never Make Index\"."
    } elseif {!$quietly && $BibmodeVars(bibAutoIndex) == 1} {
        if {[askyesno "The bibIndex needs to be rebuilt --\
          is that okay?"] != "yes"} {
            status::msg "Cancelled."
            error "User declined to allow the index to be rebuilt."
        }
    } 
    set files [lsort [Bib::listAllBibliographies]]
    set filesLength [llength $files]
    if {$filesLength == 0} {
        error "Cancelled -- there are no bibliography files to index."
    } 
    status::msg "Rebuilding Index É"
    set   bIndOut [open [file join ${PREFS} bibIndex] w]
    puts $bIndOut "# -*-Tcl-*- (nowrap) \r"
    puts $bIndOut "# Bibliography index file for quick reference lookup"
    puts $bIndOut "# Created on [mtime [now]]\r"
    set cid [scancontext create]
    # this will actually mark strings as well
    scanmatch $cid [set Bib::TopPat2] {
        if {![regexp -nocase (preamble|string|comment) $matchInfo(submatch0)]} {
            lappend found $matchInfo(submatch1)
        }
    }
    watchCursor
    foreach f $files {
        set found {}
        puts $bIndOut "set \"bibIndex($f)\" \{"
        status::msg "Indexing ([incr filesLength -1] left) [file tail $f] É"
        if {![catch {set fid [open $f]}]} {
            scanfile $cid $fid
            close $fid
        }
        # we sort so we can search it efficiently for all entries with
        # a given prefix.
        puts $bIndOut " [lsort $found] "
        puts $bIndOut "\}"
    }
    close $bIndOut
    scancontext delete $cid
    status::msg "Rebuilding the BibTeX menu É"
    menu::buildSome "bibtexMenu"
    status::msg "bibIndex creation complete."
    return
}

proc Bib::rebuildIndex {{quietly 0}} {
    
    set review [Bib::closePrefsFile "bibIndex"]
    Bib::buildIndex $quietly
    if {$review} {
	Bib::reviewIndexOrDatabase bibIndex
    }
    return
}

# ===========================================================================
# 
# Bib::addWinToIndex
# 
# Add the current window (or the user's selection of files) to the bibIndex
# file, creating it if necessary.  (A variation of Bib::buildIndex -- if
# that proc is modified, be sure to check this one, too.)
# 

proc Bib::addWinToIndex {{files ""}} {
    
    global PREFS Bib::TopPat2
    set currentWindows [winNames -f]
    if {$files == "" && [llength $currentWindows]} {
        # Assume that this is for the current window, so long as it is
        # a valid .bib file.  Otherwise, ask ...
        if {![Bib::isBibFile]} {
            set answer [askyesno -c "The current window doesn't seem\
              to be a valid .bib file.  Are you sure that you want\
              to add it to the Bib Index?"]
            if {$answer == "yes"} {
                set files [list [win::Current]]
            } elseif {$answer == "cancel"} {
		error "cancel"
            } elseif {$answer == "no"} {
                # Offer all of the current .bib windows.
                foreach w [winNames -f] {
                    if {[Bib::isBibFile -w $w]} {
                        lappend windowsList [file tail $w]
                        set windowsListConnect([file tail $w]) $w
                    } 
                }
                if {[info exists windowsList]} {
                    set fileList [listpick -l -p \
                      "Select some .bib windows to add to the index :"\
                      $windowsList]
                } else {
                    error "Cancelled -- there are no open .bib windows\
		      to add to the index."
                } 
                foreach f $fileList {
                    lappend files $windowsListConnect($f)
                } 
            } 
        } else {
            set files [list [win::Current]]
        } 
    }
    if {$files == "" || $files == "-1"} {
        # The files have not yet been set, or the user wants to choose.
        set prompt "Select some .bib files to add to the index :"
        if {[set files [Bib::listAllBibliographies "" 2 $prompt]] == ""} {
            return
        }
    }
    if {[file exists [file join $PREFS bibIndex]]} {
        set review [Bib::closePrefsFile "bibIndex"]
        set bIndOut [open [file join ${PREFS} bibIndex] a]
        puts $bIndOut "\r# Updated on [mtime [now]]\r"
    } else {
        set bIndOut [open [file join ${PREFS} bibIndex] w]
        puts $bIndOut "# -*-Tcl-*- (nowrap) \r"
        puts $bIndOut "# Bibliography database file for quick reference lookup"
        puts $bIndOut "# Created on [mtime [now]]\r"
    } 
    set cid [scancontext create]
    # this will actually mark strings as well
    scanmatch $cid [set Bib::TopPat2] {
        if {![regexp -nocase (preamble|string|comment) $matchInfo(submatch0)]} {
            lappend found $matchInfo(submatch1)
        }
    }
    set filesLength [llength $files]
    foreach f $files {
        set found {}
        lappend fileTails [file tail $f]
        puts $bIndOut "set \"bibIndex($f)\" \{"
        status::msg "Indexing ([incr filesLength -1] left) [file tail $f] É"
        if {![catch {set fid [open $f]}]} {
            scanfile $cid $fid
            close $fid
        } else {
            status::msg "Could not index $f"
        } 
        # we sort so we can search it efficiently for all entries with
        # a given prefix.
        puts $bIndOut " [lsort $found] "
        puts $bIndOut "\}"
    }
    close $bIndOut
    scancontext delete $cid
    status::msg "Rebuilding the BibTeX menu É"
    menu::buildSome "bibtexMenu"
    if {$review} {
	Bib::reviewIndexOrDatabase bibIndex
    } 
    status::msg "\"[join $fileTails]\" added to the Bib Index."
    return
}

# ===========================================================================
# 
# Bib::buildDatabase
# 
# Build the bibDatabase which allows speedy completion of citations and
# contains titles, so that you can pick the correct completion easily.
# If called from the menu, we don't check the "bibAutoIndex" preference.
# 

proc Bib::buildDatabase {{quietly 0}} {
    
    global BibmodeVars PREFS
    
    if {!$quietly && $BibmodeVars(bibAutoIndex) == 0} {
        alertnote "The \"Bib Auto Index\" preference is set to\
          \"Never Make Index\", so this procedure will end."
	error "Cancelled"
    } elseif {!$quietly && $BibmodeVars(bibAutoIndex) == 1} {
        if {[askyesno "The bibDatabase needs to be rebuilt --\
          is that okay?"] != "yes"} {
	    error "cancel"
        }
    } 
    # Get the list of current open windows -- we won't close them when
    # we're done.
    set currentPaths [winNames -f]
    set files [lsort -dictionary [Bib::listAllBibliographies]]
    set filesLength [llength $files]
    if {$filesLength == 0} {
        error "Cancelled -- there are no bibliography files to include\
	  in the database."
    } 
    status::msg "Rebuilding Database É"
    set   bDatOut [open [file join ${PREFS} bibDatabase] w]
    puts $bDatOut "# -*-Tcl-*- (nowrap) \r"
    puts $bDatOut "# Bibliography database file for quick reference lookup"
    puts $bDatOut "# Created on [mtime [now]]\r"
    # if it fails, but we succeed later, we will have the opportunity
    # to rebuild the bibIndex
    watchCursor
    foreach f $files {
        catch {file::openQuietly $f}
        status::msg "Creating database ([incr filesLength -1] left) [file tail $f] É"
        puts $bDatOut "# citekeys, titles in \"[win::CurrentTail]\", as of [mtime [now]]\r"
        puts $bDatOut [Bib::makeDatabaseOf $f]
        if {[lsearch $currentPaths $f] == "-1"} {
            # Only close if it wasn't previously open!
            killWindow
        } 
    }
    close $bDatOut
    status::msg "Rebuilding the BibTeX menu É"
    menu::buildSome "bibtexMenu"
    status::msg "bibDatabase creation complete."
    return
}

proc Bib::rebuildDatabase {{quietly 0}} {
    
    set review [Bib::closePrefsFile "bibDatabase"]
    Bib::buildDatabase $quietly
    if {$review} {
	Bib::reviewIndexOrDatabase bibDatabase
    }
    return
}

proc Bib::makeDatabaseOf {fullPath {quietly 1}} {
    set p [minPos]
    set result ""
    #                   ___type____   __brace_   _______key_______   _delim
    set pat {^[\t ]*@\s*([a-zA-Z]+)\s*([\{\(])\s*([^\s\{\}\(\),]+)\s*(,|\})}
    while { ![catch {search -s -f 1 -r 1 -- $pat $p} epos] } {
	set p [lindex $epos 0]
	set np [lindex $epos 1]
	set entry [getText $p $np]
	regexp -- $pat $entry "" type brace key
	if { [regexp -nocase (preamble|string|comment) $type] || \
	  [catch {matchIt $brace $np} end] } {
	    set p $np
	    continue
	}
	set p $end
	if { ![catch {search -s -f 1 -r 1 -i 1 -l $end -- {title\s*=\s*} $np} epos] } {
	    set epos [lindex $epos 1]
	    if { [regexp {[\(\{]} [lookAt $epos] brace] \
	      && ![catch {matchIt $brace [pos::math $epos + 1]} end] } {
		set title [getText [pos::math $epos + 1] $end]
	    } else {
		set title [getText $epos [nextLineStart $epos]]
	    }
	    regsub -all {\s+} [string trim $title] { } title
	    if {$quietly} {
		append result "$key \{$title\}\r"
	    } else {
		# This is probably for the "Index of this Window" menu item,
		# so we'll try to clean it up some.
		append result "[format {%-20s} $key] \{$title\}\r"
	    }
	}
    }
    return $result
}



# ===========================================================================
# 
# Bib::addWinToDatabase
# 
# Add the current window (or the user's selection of files) to the
# bibDatabase file, creating it if necessary.
# 

proc Bib::addWinToDatabase {{files ""}} {

    global PREFS
    set currentWindows [winNames -f]
    if {$files == "" && [llength $currentWindows]} {
        # Assume that this is for the current window, so long as it is
        # a valid .bib file.  Otherwise, ask ...
        if {![Bib::isBibFile]} {
            set answer [askyesno -c "The current window doesn't seem\
              to be a valid .bib file.  Are you sure that you want\
              to add it to the Bib Database?"]
            if {$answer == "yes"} {
                set files [list [win::Current]]
            } elseif {$answer == "cancel"} {
		error "cancel"
            } elseif {$answer == "no"} {
                # Offer all of the current .bib windows.
                foreach w [winNames -f] {
                    if {[Bib::isBibFile -w $w]} {
                        lappend windowsList [file tail $w]
                        set windowsListConnect([file tail $w]) $w
                    } 
                }
                if {[info exists windowsList]} {
                    set fileList [listpick -l -p \
                      "Select some .bib windows to add to the database :"\
                      $windowsList]
                } else {
                    error "Cancelled -- There are no open .bib windows\
		      to add to the database."
                } 
                foreach f $fileList {
                    lappend files $windowsListConnect($f)
                } 
            } 
        } else {
            set files [list [win::Current]]
        } 
    }
    if {$files == "" || $files == "-1"} {
        # The files have not yet been set, or the user wants to choose.
        set prompt "Select some .bib files to add to the database :"
        if {[set files [Bib::listAllBibliographies "" 2 $prompt]] == ""} {
            return
        }
    }
    if {[file exists [file join $PREFS bibDatabase]]} {
        set review [Bib::closePrefsFile "bibDatabase"]
        set bDatOut [open [file join ${PREFS} bibDatabase] a]
    } else {
        set bDatOut [open [file join ${PREFS} bibDatabase] w]
        puts $bDatOut "# -*-Tcl-*- (nowrap) \r"
        puts $bDatOut "# Bibliography database file for quick reference lookup"
        puts $bDatOut "# Created on [mtime [now]]\r"
    }
    set filesLength [llength $files]
    foreach f $files {
        status::msg "Creating database ([incr filesLength -1] left) [file tail $f] É"
        catch {file::openQuietly $f}
        lappend fileTails [win::CurrentTail]
        puts $bDatOut "# citekeys, titles in \"[win::CurrentTail]\", as of [mtime [now]]\r"
        puts $bDatOut [Bib::makeDatabaseOf $f]
        if {[lsearch -exact $currentWindows [win::Current]] < 0} {
            killWindow
        } 
    } 
    close $bDatOut
    status::msg "Rebuilding the BibTeX menu É"
    menu::buildSome "bibtexMenu"
    if {$review} {
	Bib::reviewIndexOrDatabase bibDatabase
    } 
    status::msg "\"[join $fileTails]\" added to the Bib Database."
    return
}

proc Bib::reviewIndexOrDatabase {which} {
    
    global PREFS
    
    regsub "bib" $which "" type
    if {[file exists [file join $PREFS $which]]} {
        edit -r -c [file join $PREFS $which]
    } elseif {[askyesno "No Bib $type exists. \
      Do you want to create one?"] == "yes"} {
        Bib::rebuild${type} 1
    } 
}

proc Bib::removeIndexOrDatabase {which} {
    
    global PREFS

    regsub "bib" $which "" type
    if {[file exists [file join $PREFS $which]]} {
        file delete [file join $PREFS $which]
	status::msg "Rebuilding the BibTeX menu É"
	menu::buildSome "bibtexMenu"
        status::msg "The Bib $type has been deleted."
    } else {
        status::msg "No Bib $type currently exists."
    }
    return
}

proc Bib::closePrefsFile {fileName} {
    
    global PREFS
    set result 0
    foreach w [winNames -f] {
        if {[win::StripCount $w] == [file join $PREFS $fileName]} {
            bringToFront $w
            killWindow
            set result 1
        }
    }
    return $result
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Bibliography Lists ×××× #
#

# ===========================================================================
# 
# Bib::listAllBibliographies
# 
# Return all bibliographies on the search path.  Optionally only return
# those which are in a given .aux file.  Similar to Bib::pickBibliography,
# but I don't want to mess with that code.
# 
# If "quietly" == 0, then this was probably called from the menu.  Allow
# the user to actually see the bibliographies that would be used in the
# creation of a database / index, and to open one if desired.  
# 
# If "quietly" == 1, just return the list of all possible .bib files.
# 
# If "quietly" == 2, we offer the list for the user to select some files,
# and then return that list to the calling proc (as in the procedures
# Bib::addWinToIndex/Database).
# 

proc Bib::listAllBibliographies {{auxfile ""} {quietly 1} {prompt ""}} {
    
    # With the pref vars we have eliminated all the TeX Paths scanning. 
    # Furthermore, we can add the bibliography in the same directory as the
    # original LaTeX doc, and any bibliography in the modeSearchPath.
    
    global BibmodeVars Bib::DefaultFile
    global Bib::Files Bib::FileTails Bib::FileTails2 
    global Bib::TailFileConnect BibFileTailConnect Bib::TailFileConnect2
    
    set   biblist {}
    if {$BibmodeVars(useTexPaths)} {
        set biblist [concat $biblist [Bib::listTexPathBibs $auxfile]]
    }
    if {$BibmodeVars(useOpenWindows)} {
        set biblist [concat $biblist [Bib::listOpenBibFiles]]
    } 
    if {$BibmodeVars(useSearchPaths)} {
        # Use both the mode paths set by Bib and TeX mode
        set biblist [concat $biblist [Bib::listModePathBibs Bib]]
        set biblist [concat $biblist [Bib::listModePathBibs TeX]]
    }
    if {$BibmodeVars(useCurrentPath)} {
        set biblist [concat $biblist [Bib::listCurrentPathBibs]]
    }
    if {[info exists BibmodeVars(useKpsewhich)] && $BibmodeVars(useKpsewhich)} {
	set biblist [concat $biblist [Bib::listKpsewhichBibs]]
    }
    set Bib::Files [lunique $biblist]
    # Several procs use file tails in dialogs, and we need to be able to
    # connect them back to the full pathnames.  If the preference for
    # "fullPathnames" is set, the "tail" name will be the full path. 
    # Command double-clicking needs Bib::FileTails2 for search results
    # windows, though, if the file isn't already open.
    set Bib::FileTails  ""
    set Bib::FileTails2 ""
    foreach f   $biblist {
        if {!$BibmodeVars(fullPathnames)} {
            set fT [file tail $f]
        } else {
            set fT $f
        } 
        set Bib::TailFileConnect($fT) $f
        set BibFileTailConnect($f)  $fT
        lappend Bib::FileTails   $fT
        lappend Bib::FileTails2  [file tail $f]
        set Bib::TailFileConnect2([file tail $f]) $f
    }
    set Bib::FileTails  [lsort -unique [set Bib::FileTails]]
    set Bib::FileTails2 [lsort -unique [set Bib::FileTails2]]
    if {$quietly == 1} {
        # This is the default case.  Just return the list of full pathnames.
        return [set Bib::Files]
    } 
    if {![llength [set Bib::FileTails]]} {
        error "Cancelled -- There are no bibliographies available to list."
    } 
    # Offer the list in a listpick dialog, and open a file if desired.
    set wC  [win::Current]
    set wCT [win::CurrentTail]
    # Now offer the list of bibliographies, with the option to create a
    # new one.  If possible, the default bib file will be highlighted.
    set biblist2 [set Bib::FileTails]
    if {[lsearch $biblist2 [set Bib::DefaultFile]] != "-1"} {
        set bDF [set Bib::DefaultFile] 
    } else {
        set bDF [lindex $biblist2 0]
    } 
    if {$prompt == ""} {
        set prompt "Select some bibliography files to open :"
        lappend biblist2 {New fileÉ}
    } 
    set bibfiles [listpick -l -L [list $bDF] -p $prompt $biblist2]
    foreach f $bibfiles {
        if {$f != "New fileÉ"} {
            lappend bibFullPaths [set Bib::TailFileConnect($f)]
        } else {
            lappend bibFullPaths $f
        } 
    } 
    if {$bibfiles == ""} {
        error "No bibliography file selected."
    } elseif {$quietly == 2} {
        # This is the second case -- return the list of files selected.
        return $bibFullPaths
    } elseif {[llength $bibfiles] == 1 && $wC == [lindex $bibfiles 0]} {
        status::msg "The current open window was chosen ..."
    } else {
        # This is the third case, when quietly == 0 -- open all of the
        # files selected by the user.
        foreach f $bibFullPaths {
            if {$f == "New fileÉ"} {
                if {[catch {file::newDocument}]} {
                    putfile "Save new bibliography as É" ".bib"
                } 
            } else {
                file::openQuietly $f
            } 
        }
    }
    # Return the list of bib files that was selected.
    return $bibFullPaths
} 

proc Bib::listTexPathBibs {{auxfile ""}} {

    TeX::ensureSearchPathSet
    
    global AllTeXSearchPaths
    
    set  biblist {}
    if {$auxfile == "" || [catch {set fid [open "$auxfile" r]}]} {
        foreach d $AllTeXSearchPaths {
            eval lappend biblist [glob -nocomplain -dir ${d} *.bib]
        }
    } else {
        set  bibs {}
        # get list of bibs from .aux file
        set  cid  [scancontext create]
        scanmatch $cid {bibdata\{([^\}]*)\}} {
            eval lappend bibs [split $matchInfo(submatch0) ","]
        }
        scanfile $cid $fid
        close $fid
        scancontext  delete $cid
        # find the full paths
        foreach b $bibs {
            foreach d $AllTeXSearchPaths {
                if {[file exists [file join ${d} ${b}.bib]]} {
                    lappend biblist [file join ${d} ${b}.bib]
                    break
                }
            }      
        }
    }
    return $biblist
}

proc Bib::listOpenBibFiles {} {
    
    set biblist {}
    if {![llength [winNames -f]]} {
        return ""
    } 
    foreach d [winNames -f] {
        if {[string trimright $d {.bib}] != $d} {lappend biblist $d} 
    }
    return $biblist
}

proc Bib::listModePathBibs {{m ""}} {
    
    global mode
    
    if {$m == ""} {
        set m $mode
    }
    # First see if mode::getSearchPath allows one to specify the mode ...
    if {[catch {set paths [mode::getSearchPath $m]}]} {
        # Can only use the current mode's path.  Shouldn't happen because
        # we already redefined the proc ...
        set paths [mode::getSearchPath]
    }
    set biblist {}
    foreach d $paths {eval lappend biblist [glob -nocomplain -dir ${d} *.bib]}
    return $biblist
}

proc Bib::listCurrentPathBibs {} {

    global mode
    
    set biblist {}
    if {$mode == "TeX" || $mode   == "Bib"} {
        # We should add the current window's path to the search path,
        # but only if the file actually exists.
        if {[file exists [win::Current]]} {
            eval lappend biblist \
              [glob -nocomplain -dir [file dirname [win::Current]] *.bib]
        } 
    }
    return $biblist
}

# Finds all files with extension .bib in the bib-path as used by "kpsewhich".
proc Bib::listKpsewhichBibs {} {
    global tcl_platform
    
    set biblist [list]
    if {![catch {exec kpsewhich --show-path bib} dirlist]} {
	# OS path lists on Windows have ';' as separator, but on 
	# Unix have ':'
	if {$tcl_platform(platform) eq "windows"} {
	    set sep ";"
	} else {
	    set sep ":"
	}
	foreach path [split $dirlist $sep] {
	    regsub -- "^!!" $path "" path
	    regsub -- "/+$" $path "" path
	    set bibs [glob -nocomplain -dir $path *.bib]
	    eval lappend biblist $bibs
	}
    }
    return $biblist
}

proc Bib::reportFileCount {} {

    global Bib::Files
    
    set count [llength [set Bib::Files]]
    if {!$count} {
        status::msg "There were no files to list."
    } elseif {$count == 1} {
        status::msg "The Bib Files list contains just one file."
    } else {
        status::msg "The Bib Files list has been rebuilt with $count files."
    } 
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× TeX Mode support ×××× #
#

# ===========================================================================
# 
# Bib::openFile
# 
# Given a filename, and the directory of the base '.aux' file, try and find
# the file.  If we don't succeed, pass the request onto the TeX code.
# 

proc Bib::openFile {filename {dir ""}} {
    if {![catch {file::openQuietly [file join ${dir} ${filename}]}]} {
        return
    }
    # look where base file was
    if {![catch {file::openQuietly [file join ${dir} ${filename}]}]} {
        return
    }
    # look in bibtex inputs folder
    global bibtexSig
    if {![catch {file::openQuietly [file join \
      [file dirname [nameFromAppl $bibtexSig]] "BibTeX inputs" ${filename}]}]} {
        return
    } 
    # look in all usual tex places
    TeX::openFile "$filename"
    return
}

# ===========================================================================
# 
# Bib::noEntryExists
# 
# No entry exists in the known .bib files.  Either add an entry, possibly
# in a new bibliography file, or add a .bib file to those currently
# searched.
# 

proc Bib::noEntryExists {item {basefile ""}} {
    
    global PREFS
    
    set basefile [Bib::getBasefile $basefile]
    set choice [dialog::optionMenu \
      "No entry '$item' exists.  What do you want to do?" \
      [list                                     \
      "New entry"                               \
      "New entry in new bibliography file"      \
      "Add .bib file to \\bibliography\{É\}"    \
      "Change original citation"                \
      "Search all bibliographies"               \
      "Open a bibliography file"                \
      "Rebuild the index and database"          \
      ]]
    switch -- $choice {
        "New entry" {
            Bib::_newEntry $item
        }
        "New entry in new bibliography file" {
            Bib::_newEntry $item 1
        }
        "Add .bib file to \\bibliography\{É\}" {
            Bib::insertNewBibliography $basefile    
        }
        "Change original citation" {
            Bib::changeOriginalCitation $item $basefile
        }
        "Search all bibliographies" {
            Bib::searchAllBibFiles $item "citeKey"
        }
        "Open a bibliography file" {
            Bib::listAllBibliographies "" 0
        }
        "Rebuild the index and database" {
            placeBookmark
            Bib::rebuildDatabase 1
            Bib::rebuildIndex    1
            returnToBookmark
        }
        "Cancel" {
            # nothing
        }
    }            
}

proc Bib::_newEntry {item {newFile 0}} {
    
    global Bib::TailFileConnect
    
    set wCT [win::CurrentTail]
    if {$newFile} {
        placeBookmark
        set bibfile [putfile "Save new bibliography asÉ" ".bib"]
        if {$bibfile == ""} {
            error "No bibliography file selected."
        } else {
            new -n $bibfile
        }       
    } else {
        # Need to pick a .bib file.
        set bibfile [Bib::pickBibliography 1 \
          "Select a bibliography file to which to add an entry"]
        if {[catch {TeX::openFile $bibfile}]} {
            # see if "filename" is a full pathname
            set f [concat [file separator]$bibfile]
            if {[file exists [set Bib::TailFileConnect($f)]]} {
                # And it should, since we just created the .bib list ...
                file::openQuietly [set Bib::TailFileConnect($f)]
                alertnote "Warning -- \"$bibfile\" is not \
                  in the current TeX path ..."
            } else {
                alertnote "Weird -- couldn't find \"$bibfile\""
                error "Couldn't find $bibfile."
            } 
        } 
    }
    # Now insert a new entry.
    global Bib::Entries
    Bib::newEntry [listpick -p "Which type of entry?" [set Bib::Entries]]
    insertText $item
    ring::+
    status::msg "Press <Ctrl-.> to return to $wCT"
}

proc Bib::insertNewBibliography {{basefile ""} {bibfile ""}} {

    set basefile [Bib::getBasefile $basefile]
    file::openQuietly ${basefile}
    
    # find bibliography, position cursor and add
    placeBookmark
    endOfBuffer
    if {[catch {set pos [search -s -f 0 -r 0 -m 0 "\\bibliography\{" [getPos]]}]} {
        # add the environment
        set pos [search -s -f 0 "\\end\{document\}" [getPos]]
        goto [pos::math [minPos] + [lindex $pos 0]]
        set preinsert  "\\bibliography\{"
        set postinsert "\}\r\r"
    } else {
        set preinsert  ""
        set postinsert ","
        goto [pos::math [minPos] + [lindex $pos 1]]
    }
    if {$bibfile == ""} {
        set bibfile [Bib::pickBibliography 0 \
          "Select a bibliography file to add"]
    }
    insertText "${preinsert}[lindex [split $bibfile "."] 0]${postinsert}"
    status::msg "Press <Ctrl .> to return to original cursor position"
}

proc Bib::changeOriginalCitation {citation {basefile ""}} {
    
    if {$basefile == ""} {set basefile [TeX::currentBaseFile]}
    # find .aux and open base .tex/.ltx
    if {[set proj [isWindowInFileset $basefile "tex"]] != ""} {
        set files [texListFilesInFileSet $proj]
    } else {
        set files $basefile
    }
    status:msg "SearchingÉ"
    set got "[eval grep [list $citation] $files]\r"
    status:msg "SearchingÉ complete."
    if {[string first "; Line " $got] == [string last "; Line " $got]} {
        # just one match
        if {![regexp {°([^\r\n]*)[\r\n]} $got dmy filename]} {
            alertnote "I couldn't find the original.  You probably have a\
              multi-part document which you haven't made into a TeX fileset.\
              Unless it's a fileset, I can't find the other files."
            return
        }
        file::openQuietly $filename
	set offsets [file::searchFor $filename $citation 1]
        selectText [pos::math [minPos] + [lindex $offsets 0]] \
	  [pos::math [minPos] + [lindex $offsets 1]]
        status::msg "This is the original citation.\
          Change it, then re-run LaTeX and BibTeX."
    } else {
        grepsToWindow "* List of citations *" $got
    }
}

proc Bib::getBasefile {{basefile ""}} {

    if {$basefile == ""} {
        return [TeX::currentBaseFile]
    }
    # find .aux and open base .tex/.ltx
    set base [file root $basefile]
    if {[file exists ${base}.tex]} {
        return ${base}.tex
    } elseif {[file exists ${base}.ltx]} {
        return ${base}.ltx
    } else {
        alertnote "Base file with name '${base}.tex/ltx' not found." 
        error ""
    }                           
}

# ===========================================================================
# 
# Bib::pickBibliography
# 
# Put up a list-dialog so the user can select a bibliography file for some
# action (taken by the caller).  Can also create a new file if desired.
# 

proc Bib::pickBibliography {{allowNew 1} {prompt "Pick a bibliography file"}} {
    
    global Bib::LastFile
    
    set biblist [Bib::listAllBibliographies]
    # Set a default in the listpick dialog It's useful because you will
    # often want to add a bunch of new items in a row to the same
    # bibliography.  At the end this will be set to the file chosen.  
    set bDF [set Bib::LastFile]
    if {$allowNew} {
        lappend biblist {New fileÉ}
    }
    set bibfile [listpick -p $prompt -L [list $bDF] $biblist]
    if {$bibfile == ""} {
        error "No bibliography file selected."
    } elseif {$bibfile == "New fileÉ" } {
        set bibfile [putfile "Save new bibliography asÉ" ".bib"]
        if {$bibfile == ""} {
            error "No bibliography file selected."
        } else {
            set fout [open $bibfile w]
            close $fout
        }       
    }
    return [file tail [set Bib::LastFile $bibfile]]
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× ????? ×××× #
# 

proc Bib::pcite {} {
    set words [prompt "Citation keys" ""]
    if {![llength $words]} {error "No keys"}
    
    set pattern {@}
    foreach w $words {
        append pattern "(\[^@\]+$w)"
    }
    
    foreach entry [Bib::findEntries $pattern] {
        set res [Bib::getFields [lindex $entry 0]]
        set title [lindex [lindex $res 1] [lsearch [lindex $res 0] "title"]]
        set citekey [lindex [lindex $res 1] [lsearch [lindex $res 0] "citekey"]]
        set matches($title) $citekey
        set where($title) [lindex $entry 0]
    }
    if {![info exists matches]} {alertnote "No citations"; return}
    set title [listpick -p "Citation?" [lsort [array names matches]]]
    putScrap $matches($title)
    alertnote $matches($title)
    goto $where($title)
}

# ===========================================================================
# 
# .