# File : "macMenuEngine.tcl"
#                        Created : 2003-08-27 23:04:10
#              Last modification : 2005-06-20 21:57:13
# Author : Bernard Desgraupes
# e-mail : <bdesgraupes@easyconnect.fr>
# Web-page : <http://webperso.easyconnect.fr/bdesgraupes/>
# 
# (c) Copyright : Bernard Desgraupes, 2003-2005
#         All rights reserved.
# This software is free software. See licensing terms in the MacMenu Help file.
#
# Description : this file is part of the macMenu package for Alpha.
# It contains the procedures which execute file system actions with macMenu.
# 

# Load macMenu.tcl
macMenuTcl

namespace eval mac {}


# # # Managing files # # #
# ========================

# Select
# ------
# Not available on OSX.

	
# Duplicate
# ---------
proc mac::DuplicateProc {} {
    mac::normalizeFolders
    mac::buildFilesList
    mac::duplicateByChunks
    status::msg "Duplicate event sent OK."
}

proc mac::duplicateByChunks {} {
    global mac_params mac::fileslist
    set theCount 0
    set fileListDesc [tclAE::createList]
    foreach f ${mac::fileslist} {
	if {[mac::discriminate $f]} {
	    tclAE::putDesc $fileListDesc -1 [tclAE::build::filename $f]
	    incr theCount
	    if {$theCount >= $mac_params(chunksize)} {
	        mac::doDuplicateChunk $fileListDesc
		set theCount 0
		tclAE::disposeDesc $fileListDesc
		set fileListDesc [tclAE::createList]
	    } 
	} 
    } 
    if {$theCount > 0} {
	mac::doDuplicateChunk $fileListDesc
	tclAE::disposeDesc $fileListDesc
    } 
}

proc mac::doDuplicateChunk {listDesc} {
    status::msg "Duplicating selected files."
    catch {eval tclAE::send 'MACS' core clon ---- [list $listDesc]} 
}

# Copy and Move
# -------------
proc mac::CopyProc {} {
	mac::moveOrCopy clon
	status::msg "Copy event sent OK."
}

proc mac::MoveProc {} {
	mac::moveOrCopy move
	status::msg "Move event sent OK."
}

proc mac::moveOrCopy {event} {
	global mac_params
	mac::normalizeFolders
	if {$mac_params(trgtfold)==""} {
	alertnote "Empty target folder."
	return 0
	} 
	mac::buildFiles&Folders
	if {![file exists $mac_params(trgtfold)[file separator]]} {
	file mkdir $mac_params(trgtfold)
	} 
	mac::moveOrCopyFolders $event
	return 1
}

proc mac::moveOrCopyFolders {event} {
    global mac_params mac_contents mac::folderslist 
    # First level source folder
    if {[info exists mac_contents($mac_params(srcfold))]} {
	mac::moveOrCopyByChunks $event $mac_params(srcfold) $mac_params(trgtfold)
    } 
    # Subfolders
    foreach fold ${mac::folderslist} {
	set srcsubfold [file join $mac_params(srcfold) $fold]
	set trgtsubfold [file join $mac_params(trgtfold) $fold]
	if {[expr ![file exists $trgtsubfold] \
	  && {[set mac_contents($srcsubfold)]!=""}]} {
	    file mkdir $trgtsubfold
	} 
	if {[info exists mac_contents($srcsubfold)]} {
	    mac::moveOrCopyByChunks $event $srcsubfold $trgtsubfold
	} 
    }
}

proc mac::moveOrCopyByChunks {event srcFolder trgtFolder} {
    global mac_params mac_contents
    set theCount 0
    set fileListDesc [tclAE::createList]
    foreach f $mac_contents($srcFolder) {
	if {[mac::discriminate [file join $srcFolder $f]]} {
	    tclAE::putDesc $fileListDesc -1 [tclAE::build::filename [file join $srcFolder $f]]
	    incr theCount
	    if {$theCount >= $mac_params(chunksize)} {
		mac::doMoveOrCopyChunk $event $fileListDesc $trgtFolder
		set theCount 0
		tclAE::disposeDesc $fileListDesc
		set fileListDesc [tclAE::createList]
	    } 
	}
    } 
    if {$theCount > 0} {
	mac::doMoveOrCopyChunk $event $fileListDesc $trgtFolder
	tclAE::disposeDesc $fileListDesc
    } 
}

proc mac::doMoveOrCopyChunk {event listDesc trgtFolder} {
    global mac_params
    status::msg "Moving/Copying to $trgtFolder"
    catch {
	eval tclAE::send 'MACS' core $event ---- [list $listDesc] \
	  insh [list [tclAE::build::foldername $trgtFolder]] \
	  alrp [tclAE::build::bool $mac_params(overwrite)]
    }
}

# Rename
# ------
proc mac::RenameProc {} {
    global mac::folderslist mac::namelist mac::renamelist mac_params mac_contents 
    mac::normalizeFolders
    mac::buildFiles&Folders
    set mac_params(currnum) $mac_params(digitopt)
    set mac::namelist {}
    set mac::renamelist {}
    foreach f $mac_contents($mac_params(srcfold)) {
	set mac_params(paddvalue) [string length [llength $mac_contents($mac_params(srcfold))]]
	if {[mac::discriminate [file join $mac_params(srcfold) $f]]} {
	    regsub $mac_params(regex) $f $mac_params(replace) res
	    lappend mac::namelist $f
	    lappend mac::renamelist [mac::applyRenameOptions $res]
	}
    } 
    if {![mac::processRenamelist $mac_params(srcfold)]} return
    foreach fold ${mac::folderslist} {
	set mac_params(currnum) $mac_params(digitopt)
	set mac::namelist {}
	set mac::renamelist {}
	foreach f $mac_contents([file join $mac_params(srcfold) $fold]) {
	    set mac_params(paddvalue) [string length [llength $mac_contents([file join $mac_params(srcfold) $fold])]]
	    if {[mac::discriminate [file join $mac_params(srcfold) $fold $f]]} {
		if {$mac_params(casestr)==""} {
		    regsub $mac_params(regex) $f $mac_params(replace) res
		} else {
		    regsub $mac_params(casestr) $mac_params(regex) $f $mac_params(replace) res
		}
		lappend mac::namelist $f
		lappend mac::renamelist [mac::applyRenameOptions $res]
	    }
	} 
	if {![mac::processRenamelist [file join $mac_params(srcfold) $fold]]} return
    } 
	status::msg "Rename event sent OK"
}

# Renaming options are : trucating, numbering and casing (applied in this order)
proc mac::applyRenameOptions {name} {
    global mac_params 
    if !$mac_params(addoptions) {return $name}
    if $mac_params(truncating) {set name [mac::truncate $name]}
    if $mac_params(numbering) {set name [mac::numbering $name]}
    if $mac_params(casing) {set name [mac::casing $name]}
    return $name
}

proc mac::truncate {name} {
    global mac_params  
    set num [split $mac_params(truncexp) .]
    set str [split $name .]
    switch [llength $num] {
	1 {return [string range $name 0 [expr [lindex $num 0]-1]]}
	2 {
	    switch [llength $str] {
		1 {
		    return [string range $name 0 [expr [lindex $num 0]-1]]
		}
		default {
		    regexp {^(.*)\.(.*)$} $name dum lt rt
		    return "[string range $lt 0 \
		      [expr [lindex $num 0]-1]].[string range $rt 0 [expr [lindex $num 1]-1]]"
		}
	    } 
	}
    }
}

proc mac::numbering {name} {
    global mac_params
    if {$mac_params(paddopt)} {
	eval set affix "[format %0.$mac_params(paddvalue)d $mac_params(currnum)]"
    } else {
	set affix "$mac_params(currnum)"
	}
    if {!$mac_params(incropt) && [expr $mac_params(currnum) > 0]} {
    set affix "-$affix"
    }
    if {$mac_params(whereopt)} {
	set result "$name$affix"
    } else {
	set result "$affix$name"
    }
    incr mac_params(currnum)
    return $result
}

proc mac::casing {name} {
    global mac_params
    switch $mac_params(caseopt) {
	0 {return [string toupper $name]}
	1 {return [string tolower $name]}
	2 {
	    set str [split $name]
	    set name ""
	    foreach w $str {
		append name " [string toupper [string index $w 0 ]][string tolower [string range $w 1 end]]"
	    } 
	    return [string trim $name]
	}
	3 {return "[string toupper [string index $name 0 ]][string tolower [string range $name 1 end]]"}
    }
}

proc mac::processRenamelist {fold} {
	global mac::namelist mac::renamelist mac_params  
	if {![set len [llength ${mac::renamelist}]]} {return 1}
	set i 1
	while {[expr $i <= $len]} {
		if {[lindex ${mac::renamelist} $i]==[lindex ${mac::renamelist} [expr $i - 1]]} {
			alertnote "Naming conflict: two files renamed\r[lindex ${mac::renamelist} $i]\
			  in folder $fold."
			return 0
		} 
		incr i
	}
	for {set i 0} {$i<$len} {incr i} {
		set oldname [lindex ${mac::namelist} $i]
		if {[set newname [lindex ${mac::renamelist} $i]]==""} {
			alertnote "Empty new name for [file join $mac_params(srcfold) $fold [lindex ${mac::namelist} $i]]"
			return 0
		}
		catch {
			set desc [tclAE::send 'MACS' core setd ---- [tclAE::build::propertyObject pnam \
			  [tclAE::build::filename [file join $fold $oldname]]] \
			  data "Ò${newname}Ó"]
			# Removed -r option and disabled error checking in the AE to speed things up
			# # 	if [mac::testIfError $desc] {return 1}
		}
	}
	return 1
}


# Trash
# -----
proc mac::TrashProc {} {
    global mac::fileslist mac_params
    mac::normalizeFolders
    mac::buildFilesList
    foreach f ${mac::fileslist} {
	if {[mac::discriminate $f]} {
	    status::msg "Trashing $f"
	    catch {tclAE::send 'MACS' core delo ---- [tclAE::build::filename $f]} 
	}
    } 
	status::msg "Trash event sent OK."
}


# Alias
# -----
# We make a distinction between two situations :
# - if no target folder is specified or if it is the same as the source folder, then
#   the aliases are made in the same folders and subfolders as the original files 
# - if a target folder is specified then all the aliases are sent to this folder 
#   no matter where the original files are located in the source folder, i-e even
#   if the 'In hierarchy' flag is used.
# Note that on OSX the FNDR/sali Apple Event does not exist anymore.
proc mac::AliasProc {} {
    global mac::fileslist mac_params
    mac::normalizeFolders
    mac::buildFilesList    
    set target $mac_params(trgtfold)
    set onspot [expr {$mac_params(srcfold)==$target} || {$target==""}]
    if {[expr !$onspot && ![file exists $target]]} {
	file mkdir $target
    } 
    set param "to  "
    foreach f ${mac::fileslist} {
	if {[mac::discriminate $f]} {
	    status::msg "Making alias for [file tail $f]"
	    if {$onspot} {
		set target [file dir $f]
	    } 
	    catch {tclAE::send 'MACS' core crel \
	      kocl type(alia) \
	      insh [tclAE::build::foldername $target] \
	      $param [tclAE::build::filename $f]}  
	}
    } 
    status::msg "Make Alias event sent OK."
}

proc mac::RemoveAliasProc {} {
    global mac::folderslist mac_params
    mac::normalizeFolders
    mac::buildFoldersList
    set i 1
    foreach fol ${mac::folderslist} {
	status::msg "Removing aliases from folder [file tail $fol]"
	set nb [tclAE::build::resultData 'MACS' core cnte \
	  ---- [tclAE::build::foldername $fol] kocl type(alia)]
	if $nb {
	    set aliaslist [mac::getAliasesList $fol]
	    if {$nb==1} {set aliaslist [list $aliaslist]}
	    foreach al $aliaslist {
		catch {tclAE::send 'MACS' core delo ---- $al} 
		status::msg "Trashing $i"
		incr i
	    }
	}
    }
    status::msg "[expr {$i - 1}] aliases removed."
}  

# Lock
# ----

proc mac::LockProc {} {
    mac::setlock 1
    status::msg "Lock event sent OK."
}

proc mac::UnlockProc {} {
    mac::setlock 0
    status::msg "Unlock event sent OK."
}

proc mac::setlock {{toggle 1}} {
    global mac::fileslist
    mac::normalizeFolders
    mac::buildFilesList
    set action(1) "Locking"
    set action(0) "Unlocking"
    foreach f ${mac::fileslist} {
	if {[mac::discriminate $f]} {
	    status::msg "[set action($toggle)] $f"
	    catch {tclAE::send 'MACS' core setd ---- [tclAE::build::propertyObject aslk \
	      [tclAE::build::filename $f]] data [tclAE::build::bool $toggle]} res
	}
    } 
}


# Change creator
# --------------
proc mac::ChangeCreatorProc {} {
    global mac::fileslist mac_params mac::creatorslist
    mac::normalizeFolders
    mac::buildFilesList
    set creator [string range [lindex $mac::creatorslist $mac_params(creatoridx)] 0 3]
    foreach f ${mac::fileslist} {
	if {[mac::discriminate $f]} {
	    status::msg "Changing creator for [file tail $f]"
	    catch {mac::setTypeCreator fcrt $f $creator} 
	}
    } 
	status::msg "Change creator event sent OK"
}


# Change type
# -----------
proc mac::ChangeTypeProc {} {
    global mac::fileslist mac_params mac::typeslist
    mac::normalizeFolders
    mac::buildFilesList
    set type [string range [lindex $mac::typeslist $mac_params(typeidx)] 0 3]
    foreach f ${mac::fileslist} {
	if {[mac::discriminate $f]} {
	    status::msg "Changing type for [file tail $f]"
	    catch {mac::setTypeCreator asty $f $type}
	}
    } 
	status::msg "Change type event sent OK"
}


# Change encoding (translate to other file encoding)
# --------------------------------------------------
proc mac::ChangeEncodingProc {} {
	global mac::fileslist mac_params
	if {$mac_params(fromencoding)==$mac_params(toencoding)} {
		set mess "Source and target encodings are identical \
		  ($mac_params(fromencoding) to $mac_params(toencoding))."
		if {!$mac_params(fromshell)} {alertnote $mess}
		return $mess
	}
	mac::normalizeFolders
	mac::buildFilesList
	foreach f ${mac::fileslist} {
		if {[mac::discriminate $f]} {
			mac::doChangeEncoding $f $mac_params(fromencoding) $mac_params(toencoding) $mac_params(backuporigs)
		}
	} 
	status::msg "Transcoding done"
}

proc mac::doChangeEncoding {infile from to {backup 1}} {
	if {![file exists $infile]} {return}
	set i 0
	status::msg "Transcoding '[file tail $infile]'. Wait..."
	# Set the file names
	if {$backup} {
		set bckfile "$infile~"
		file rename -force -- $infile $bckfile
		set outfile $infile
		set infile $bckfile
	} else {
		set tmpfile [file join [file dir $infile] "[ticks][incr i]"]
		set outfile $tmpfile
	}
	# Open the channels
	set iid [open $infile]
	fconfigure $iid -encoding $from
	set oid [open $outfile w+]
	fconfigure $oid -encoding $to
	# Convert and write line by line
	while {![eof $iid]} {
		gets $iid line
		puts $oid $line
	}
	# Close the channels
	close $iid
	close $oid
	# Rename files
	if {!$backup} {
		file delete $infile
		file rename -force -- $outfile $infile
	}
}




# Change eols (aka convert line endings)
# --------------------------------------
proc mac::ChangeEolsProc {} {
    global mac::fileslist mac_params
    if {$mac_params(fromeol)==$mac_params(toeol)} {
	set mess "Source and target types are identical \
	  ($mac_params(fromeol) to $mac_params(toeol))."
	if {!$mac_params(fromshell)} {alertnote $mess}
	return $mess
    }
    mac::normalizeFolders
    mac::buildFilesList
    foreach f ${mac::fileslist} {
	if {[mac::discriminate $f]} {
	    mac::doChangeEols $f
	}
    } 
	status::msg "Changing end-of-lines done"
}

# The code of this proc is borrowed from the file::convertLineEndings proc
# written by Johan Linde in fileManipulation.tcl (7.5d19). It is simply
# adapted to the MacMenu context.
proc mac::doChangeEols {file} {
    global mac_params
    set fid [open $file r]
    fconfigure $fid -translation binary
    seek $fid 0 start
    set contents [read $fid]
    close $fid
    if {[regexp {\n\r} $contents]} {
	set thisType "win"
    } elseif {[regexp {\n} $contents]} {
	set thisType "unix"
    } else {
	set thisType "mac"
    }
    if {$thisType!=$mac_params(toeol)} {
	if {$mac_params(fromeol)=="all" || $thisType==$mac_params(fromeol)} {
	    status::msg "Changing eols for [file tail $file]"
	    file::convertLineEndings $file $mac_params(toeol)
	}
    }
}


# List
# ----
proc mac::ListProc {} {
    global mac_params mac::sortbylist
    mac::normalizeFolders
    mac::buildFilesList
    status::msg "Listing files..."
    set newlist [mac::listBuild]
    set result [mac::listFilesHeader]
    if {[llength $newlist]} {
	append result "\n[llength $newlist] files"
	if {$mac_params(sortbyidx)} {
	    append result "\nSorted by '[lindex $mac::sortbylist $mac_params(sortbyidx)]'"
	} 
	append result "\n\n[join $newlist "\n"]"
    } else {
	append result "\n\nNo files"
    }
    if {!$mac_params(fromshell)} {
	new -n "Files list" -info $result
    }
	status::msg "List files done."
    return $result
}

proc mac::listBuild {} {
    global mac::fileslist mac_params mac::sortcodelist mac::sortbylist
    mac::buildFilesList
    status::msg "Listing files..."
    set newlist {}
    foreach f ${mac::fileslist} {
	if {[mac::discriminate $f]} {
	    lappend newlist $f
	}
    } 
    if {![llength $newlist]} {return ""} 
    if {$mac_params(sortbyidx)} {
	status::msg "Sorting by '[lindex $mac::sortbylist $mac_params(sortbyidx)]'. Wait..."
	return [mac::listDoSort $newlist [lindex $mac::sortcodelist $mac_params(sortbyidx)]]
    } else {
	return $newlist
    }
}

# This proc sorts the files list according to the criterion specified by the
# 'by' argument.  The admissible values for 'by' are : asmo, ascd, ptsz, kind,
# labi (vers and comt purposely omitted here) corresponding respectively to
# "Modification date", "Creation date", "Size", "Kind", "Labels".  If the
# "Incl Crit" (Include Criterion) checkbox is checked, the value of the
# criterion will be included in the result.
proc mac::listDoSort {list by} {
	global  mac_params
	set templist ""
	# Let's build a temporary list prepending before each item the value
	# of the property
	foreach f $list {
		if {$by eq "kind" || $by eq "labi"} {
			set desc [tclAE::send -r 'MACS' core getd ---- [tclAE::build::propertyObject \
			  $by [tclAE::build::filename $f]]]
			if {![catch {tclAE::getKeyDesc $desc ---- } res]} {
				lappend templist [list $res $f]
			}
		} else {
			# Get the info with getFileInfo (AEs aren't reliable here)
			if {![catch {getFileInfo $f arr}]} {
				switch -- $by {
					asmo {set res $arr(modified)}
					ascd {set res $arr(created)}
					ptsz {set res [expr {$arr(datalen) + $arr(resourcelen)}]}
				}
				lappend templist [list $res $f]
			} 
		}
	} 
	# Sort the list. Biggest or newest comes first.
	if {$by=="ptsz" || $by=="asmo" || $by=="ascd"} {
		set templist [lsort -index 0 -integer -decr $templist]
	} else {
		set templist [lsort -index 0 $templist]
	}
	# Handle the prefix
	set resultlist ""
	if {$mac_params(criterion)} {
		if {$by eq "labi"} {return $templist} 
		foreach item $templist {
			set criterion  ""
			switch $by {
				asmo - ascd {
					set criterion [mtime [lindex $item 0]]
				}
				ptsz {
					set criterion [lindex $item 0]
				}
				kind {
					set criterion [tclAE::coerceDesc [lindex $item 0] TEXT]
				}
			}
			lappend resultlist "$criterion\t[lindex $item 1]"
		} 
	} else {
		foreach item $templist {
			lappend resultlist [lindex $item 1]
		} 
	}
	return $resultlist
}

proc mac::listFilesHeader {} {
    global mac_params mac::alternlist mac::compvaluelist mac::compdatelist
    set result "Filter: $mac_params(regex)\n"
    append result "Folder: $mac_params(srcfold)\n"
    if {$mac_params(subfolds)==1} {append result "Nesting level: $mac_params(nest)\n"} 
    if {$mac_params(subfolds)==2} {append result "All subfolders\n"} 
    if {$mac_params(iscase)} {append result "case sensitive"} else {append result "case insensitive"}
    if {$mac_params(isneg)} {append result " - negate filter"} 
    if {$mac_params(addconditions)} {
	if {$mac_params(asty)!=""} {append result "\nType [lindex $mac::alternlist $mac_params(isasty)] $mac_params(asty)"}
	if {$mac_params(fcrt)!=""} {append result "\nCreator [lindex $mac::alternlist $mac_params(isfcrt)] $mac_params(fcrt)"}
	if {$mac_params(ascd)!=""} {append result "\nCreation date [lindex $mac::compdatelist $mac_params(isascd)] $mac_params(ascd)"}
	if {$mac_params(asmo)!=""} {append result "\nModification date [lindex $mac::compdatelist $mac_params(isasmo)] $mac_params(asmo)"}
	if {$mac_params(size)!=""} {append result "\nSize [lindex $mac::compvaluelist $mac_params(issize)] $mac_params(size)"}
    } 
    return $result
}


# Delete rez Forks
# ----------------
proc mac::DeleteRezForksProc {} {
    global mac::fileslist mac_params
    if {[alert -t caution -k "Yes" -o "Don't !" -c "" "Aaaargh!" "Do you really want\
      to delete the resource forks ? This is not undoable."] != "Yes"} {
	return 0
    } 
    mac::normalizeFolders
    mac::buildFilesList
    foreach f ${mac::fileslist} {
	if {[mac::discriminate $f]} {
	    status::msg "Deleting rez fork for [file tail $f]"
	    setFileInfo $f resourcelen
	}
    } 
    status::msg "Resource forks deleted."
}

