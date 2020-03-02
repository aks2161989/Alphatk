# File : "macMenuUtils.tcl"
#                        Created : 2001-01-22 21:34:18
#              Last modification : 2005-06-18 19:25:57
# Author : Bernard Desgraupes
# e-mail : <bdesgraupes@easyconnect.fr>
# Web-page : <http://webperso.easyconnect.fr/bdesgraupes/>
# 
# (c) Copyright : Bernard Desgraupes, 2001-2005
#         All rights reserved.
# This software is free software. See licensing terms in the MacMenu Help file.
#
# Description : this file is part of the macMenu package for Alpha.
# It contains various utility procs used by macMenu.

# Load macMenu.tcl
macMenuTcl

namespace eval mac {}


# # # Building files list procs # # #
# ===================================

proc mac::buildFilesList {} {
    global mac::fileslist mac_params
    set mac::fileslist ""
    switch $mac_params(subfolds) {
	0 {mac::getFilesinHier $mac_params(srcfold) 0}
	1 {mac::getFilesinHier $mac_params(srcfold) $mac_params(nest)}
	2 {mac::getFilesinHier $mac_params(srcfold) 1 1}
    }
    status::msg "Processing files list..."
}

proc mac::getFilesinHier {dir depth {unlimited 0}} {
    global mac::fileslist mac_params
    if {![file exists $dir]} {
	alertnote "Can't find folder $dir"
	return
    } 
    status::msg "Building files list..."
    set tmplist [glob -nocomplain -dir [file join $dir] *]   
    foreach f $tmplist {
	set dp $depth
	# Here we say ![file isdirectory $f] instead of [file isfile $f] because we want
	# to include aliases in the list :
	if {![file isdirectory $f]} {
	    if {![expr [mac::testRegex $f $mac_params(casestr)] - !$mac_params(isneg)]} {
		lappend mac::fileslist $f
	    } 
	} elseif {[file isdirectory $f] && [expr $depth > 0]} {
	    if {!$unlimited} {incr dp -1} 
	    mac::getFilesinHier $f $dp $unlimited
	}
    }
}

proc mac::buildFiles&Folders {} {
    global mac::folderslist mac_params mac_contents
    if {[info exists mac_contents]} {unset mac_contents}
    set mac::folderslist ""
    switch $mac_params(subfolds) {
	0 {mac::getFoldersContents $mac_params(srcfold) 0}
	1 {mac::getFoldersContents $mac_params(srcfold) $mac_params(nest)}
	2 {mac::getFoldersContents $mac_params(srcfold) 1 1}
    }
    status::msg "Processing files list..."
}

proc mac::getFoldersContents {dir depth {unlimited 0}} {
    global mac::folderslist mac_params mac_contents
    if {![file exists $dir]} {
	alertnote "Can't find folder $dir."
	return
    } 
    status::msg "Building files list..."
    set tmplist [glob -nocomplain -dir [file join $dir] *]   
    set mac_contents($dir) ""
    foreach f $tmplist {
	set dp $depth
	# Here we say ![file isdirectory $f] instead of [file isfile $f] because we want
	# to include aliases in the list :
	if {![file isdirectory $f]} {
	    if {![expr [mac::testRegex $f $mac_params(casestr)] - !$mac_params(isneg)]} {
		lappend mac_contents($dir) [mac::relFilename $dir $f]
	    } 
	} elseif {[file isdirectory $f] && [expr $depth > 0]} {
	    if {!$unlimited} {incr dp -1} 
	    lappend mac::folderslist "[mac::relFilename $mac_params(srcfold) $f]"
	    mac::getFoldersContents $f $dp $unlimited
	}
    }
    return ${mac::folderslist}
}

proc mac::buildFoldersList {} {
    global mac::folderslist mac_params
    if {![file exists $mac_params(srcfold)]} {
	alertnote "Can't find folder $mac_params(srcfold)"
	return
    } 
    set mac::folderslist [list $mac_params(srcfold)]
    switch $mac_params(subfolds) {
	0 {return}
	1 {mac::getFoldersinHier $mac_params(srcfold) $mac_params(nest)}
	2 {mac::getFoldersinHier $mac_params(srcfold) 1 1}
    }
}

proc mac::getFoldersinHier {dir depth {unlimited 0}} {
    global mac::folderslist mac_params
    if !$depth return
    status::msg "Building subfolders list..."
    set tmplist [glob -nocomplain -types d -dir [file join $dir] *]   
    set mac::folderslist [concat ${mac::folderslist} $tmplist]
    foreach f $tmplist {
	set dp $depth
	if {!$unlimited} {incr dp -1} 
	mac::getFoldersinHier $f $dp $unlimited
    }
}

# -------------------------------------------------------------------------
# Truncate to get path relatively to the source folder.
# Modified 2001-07-16 by Frédéric Boulanger (thanks) to fix a bug when a 
# dir name contains special regexp chars.
# -------------------------------------------------------------------------
proc mac::relFilename {dir file} {
   if {[regexp "^[file join [quote::Regfind ${dir}] \(.*\)]\$" $file dum res]} {
     return $res
   } else {
     return $file
   }
}

proc mac::trimRightSeparator {varname} {
    upvar $varname thename
    set thename [string trimright $thename [file separator]]
}

proc mac::normalizeFolders {} {
    global mac_params
    mac::trimRightSeparator mac_params(srcfold)
    mac::trimRightSeparator mac_params(trgtfold) 
}

# -------------------------------------------------------------------------
# Procs to apply the additional conditions
# -------------------------------------------------------------------------
proc mac::testRegex {f {case ""}} {
    global mac_params
    if {$case==""} {
	return [regexp $mac_params(regex) [file tail $f]]
    } else {
	return [regexp $case $mac_params(regex) [file tail $f]]
    }
}

proc mac::discriminate {file} {
    global mac_params
    if !$mac_params(addconditions) {return 1}
    set file [file::unixPathToFinder $file]
    return [expr [mac::testDate ascd $file] && [mac::testDate asmo $file] && \
      [mac::testSize $file] && [mac::testType asty $file] && \
      [mac::testType fcrt $file] ]
}

proc mac::testType {type file} {
    global mac_params
    if {$mac_params($type)==""} {
        return 1
    } 
    set thetype [mac::findItemProperty $type file $file]
    return [expr ![expr $mac_params(is$type) - ![string compare $mac_params($type) $thetype]]]
}

proc mac::testDate {date file} {
    global mac_params
    if {$mac_params($date)==""} {
        return 1
    } 
    set thedate [mac::getItemDate $date file $file short]
    return [expr ![expr $mac_params(is$date) - [mac::dateCompare $thedate $mac_params($date)]]]
}

proc mac::testSize {file} {
    global mac_params
    if {$mac_params(size)==""} {
        return 1
    } 
    set thebytes [expr $mac_params(size) * 1024] 
    set thesize [format %1d 0x[mac::getItemSize ptsz file $file]]
    return [expr ![expr $mac_params(issize) - [expr $thebytes < $thesize]]]
}

# -------------------------------------------------------------------------
# Check for errors returned in the Apple Event reply
# -------------------------------------------------------------------------
proc mac::testIfError {desc} {
    global tileLeft tileTop tileWidth errorHeight
    set test [expr ![catch {tclAE::getKeyData $desc errs TEXT}]]
    if {$test} {
	catch {
	    new -g $tileLeft $tileTop [expr $tileWidth*.6] [expr $errorHeight] \
	      -n "* Error Info *" -info "Apple Event returned error message:\n\
	      [tclAE::getKeyData $desc errs TEXT]\n" 
	}
    } else {
	set test [expr ![catch {tclAE::getKeyData $desc errn TEXT}]]
	if {$test} {
	    catch {
		new -g $tileLeft $tileTop [expr $tileWidth*.6] [expr $errorHeight] \
		  -n "* Error Info *" -info "Apple Event returned error\
		  [tclAE::getKeyData $desc errn TEXT]" 
	    }
	}
    }
    tclAE::disposeDesc $desc
    return $test
}

# # # Misc utility procs # # #
# ============================

# -------------------------------------------------------------------------
# Date comparison. Dates must be in the ISOTime format "YYYY-MM-DD"
# as returned by the ISOTime.tcl procs (separator is irrelevant).
# Returns 0 if datea < dateb, 1 if datea == dateb, 2 if datea > dateb
# -------------------------------------------------------------------------
proc mac::dateCompare {datea dateb} {
    regexp {(\d\d\d\d).(\d\d).(\d\d)} $datea dum yya mma dda
    regexp {(\d\d\d\d).(\d\d).(\d\d)} $dateb dum yyb mmb ddb
    if {[expr {$yya < $yyb} || {[expr $yya == $yyb] && [expr $mma < $mmb]} \
      || {[expr $yya == $yyb] && [expr $mma == $mmb] && [expr $dda < $ddb]}]} {return 0}
    if {[expr {$yya > $yyb} || {[expr $yya == $yyb] && [expr $mma > $mmb]} \
      || {[expr $yya == $yyb] && [expr $mma == $mmb] && [expr $dda > $ddb]}]} {return 2}
    return 1
}

# -------------------------------------------------------------------------
# Output the contents of an info window
# -------------------------------------------------------------------------
proc mac::getInfoAsText {} {
    global mac_params
    new -n "* macMenu Info *" -info $mac_params(infotext)
    return 1
}
    
# -------------------------------------------------------------------------
# Update some variables when prefs are modified
# -------------------------------------------------------------------------
proc mac::shadowPrefs {name} {
    global macMenumodeVars mac_params mac::predefext HOME env
    global mac::ispredef mac::inicreatorslist mac::creatorslist
    set mac::creatorslist $mac::inicreatorslist
    if {$macMenumodeVars(additionalTypes)!=""} {
	foreach type $macMenumodeVars(additionalTypes) {
	    lappend mac::creatorslist $type
	} 
    }
    set mac::predefext $macMenumodeVars(predefExtensions)
    set mac::predefext [string trimright $mac::predefext]
    foreach e $mac::predefext {
	set mac::ispredef($e) 0
    } 
    set mac_params(chunksize) $macMenumodeVars(chunksSize)
    set mac_params(overwrite) $macMenumodeVars(overwriteIfExists)
    if {$macMenumodeVars(defaultHome)==1} {
	set mac_params(pwd) $env(HOME)
    } else {
	set mac_params(pwd) $HOME
    }
}

# -------------------------------------------------------------------------
# Rewrite the filtering expression when predefined extensions have been
# selected.
# -------------------------------------------------------------------------
proc mac::refreshFilterExpr {} {
    global mac_params mac::predefext mac::ispredef
    set extlist ""
    foreach e [array names mac::ispredef] {
	if {$mac::ispredef($e)} {
	    lappend extlist $e
	} 
    } 
    if {$mac_params(otherexts)!=""} {
	regsub -all {  +} $mac_params(otherexts) " " str
	set str [string trim $str]
	set others [split $str]
	foreach e $others {
	    lappend extlist [quote::Regfind $e]
	} 
    } 
    if {$extlist!=""} {
	set mac_params(regex) ".*\\.\([join $extlist |]\)$"
    } 
}

# -------------------------------------------------------------------------
# Break long path names in the info windows
# -------------------------------------------------------------------------
proc mac::pathLine {dir} {
    global mac_params
    if {[expr [string length $dir] < 40]} {
	set y $mac_params(y)
	eval lappend mac_params(args) [list [dialog::text "$dir" 190 y ]]
	return
    } 
    set line [file split $dir]
    set result ""
    set i 0
    while {[string length $result] < 40} {
	set result [eval file join [lrange $line 0 $i]]
	incr i
    }
    set y $mac_params(y)
    incr i -1
    eval lappend mac_params(args) [list [dialog::text "[eval file join [lrange $line 0 [expr $i-1]]]" 190 y ]]
    set next [file separator]
    append next [eval file join [lrange $line $i end]]
    if {[llength $next] != 0} {
	incr mac_params(y) 16
	mac::pathLine $next
    } 
}

# -------------------------------------------------------------------------
# Associate one of the letters m, c, s, k, l to a sorting option
# for "files list". An improper or empty 'letter' will set 
# mac_params(sortbyidx) to 0 which means no sorting.
# -------------------------------------------------------------------------
proc mac::getSortingOption {letter} {
    global mac_params
    if {[set pos [lsearch -exact [list "" "" m c s k l] [string range $letter 0 0]]]=="-1"} {
	set pos 0
    } 
    set mac_params(sortbyidx) $pos
}

# -------------------------------------------------------------------------
# Determine if an item is a bundle (packaged application).
# -------------------------------------------------------------------------
# New def for OSX
proc mac::isBundled {item} {
    set res 0
    app::launchBack sevs
    set aedesc [tclAE::send -r 'sevs' core getd ---- \
      [tclAE::build::propertyObject pALL [tclAE::build::nameObject cobj \
      [tclAE::build::TEXT $item]]]]
    set objDesc [tclAE::getKeyDesc $aedesc ----]
    if {[catch {set res [tclAE::getKeyData $objDesc pkgf]}]} {
	return 0
    } 
    return $res
}


# -------------------------------------------------------------------------
# No reply (-r)
# -------------------------------------------------------------------------
proc mac::setTypeCreator {which fname value} {
    tclAE::send 'MACS' core setd ---- \
      [tclAE::build::propertyObject $which [tclAE::build::filename $fname]] \
      data 'type'($value)
}

# -------------------------------------------------------------------------
# Some applications do not have a creator (the Calculator for instance). 
# The AE returns the value "msng" (=missing) but their PkgInfo file has "????"
# -------------------------------------------------------------------------
proc mac::getTypeCreator {which fname} {
    set res [tclAE::build::resultData 'MACS' core getd \
      ---- [tclAE::build::propertyObject $which [tclAE::build::filename $fname]]]
    if {$res eq "msng"} {
        set res "????"
    } 
    return $res
}
