# File : "macMenuShell.tcl"
#                        Created : 2003-11-18 15:25:37
#              Last modification : 2005-06-19 14:36:16
# Author : Bernard Desgraupes
# e-mail : <bdesgraupes@easyconnect.fr>
# Web-page : <http://webperso.easyconnect.fr/bdesgraupes/>
# 
# (c) Copyright : Bernard Desgraupes, 2003-2005
#         All rights reserved.
# This software is free software. See licensing terms in the MacMenu Help file.
#
#  Description : this file is part of the macMenu package for Alpha.
# It contains procedures which can be used in Tcl scripts  directly  and  make
# all the MacMenu capacities available programmatically (instead  of  via  the
# dialogs interface).
# The same commands (without the macsh:: namespace prefix) can be used 
# directly in MacShell.


# Load macMenu.tcl
macMenuTcl

namespace eval mac {}
namespace eval macsh {}

# Dummy proc
proc macMenuInterface {} {}


# # # MacMenu interface commands # # #
# ====================================

proc macsh::files {subcmd args} {
    global mac_params mac::creatorslist mac::typeslist mac::eolslist macMenumodeVars
    set mac_params(fromshell) 1
    set opts(-c) ""
    set opts(-f) ".*"
    set opts(-i) 0
    set opts(-l) 0
    set opts(-n) 0
    set opts(-r) &
    set opts(-s) "[macsh::pwd]"
    set opts(-t) ""
    set opts(-o) $macMenumodeVars(overwriteIfExists)
    set opts(-k) ""
    set opts(-d) 0
    set opts(-b) ""
    set opts(-x) ""
    getOpts {-f -s -l -i -n -t -o -r -c -k -d -b -x -all}
    if {[file exists [file join [macsh::pwd] $opts(-s)]] \
      && [file isdirectory [file join [macsh::pwd] $opts(-s)]]} {
	set mac_params(srcfold) [file join [macsh::pwd] $opts(-s)]
    } else {
	set mac_params(srcfold) $opts(-s)
    }
    set opts(-all) [info exists opts(-all)]
    set mac_params(iscase) [expr !$opts(-i)]
    set mac_params(casestr) [expr {$mac_params(iscase) ? "":"-nocase"}]
    set mac_params(isneg) $opts(-n)
    set mac_params(overwrite) $opts(-o)
    if {$opts(-l)=="all"} {
	set mac_params(subfolds) 2
    } elseif {[expr $opts(-l) > 0]} {
	set mac_params(subfolds) 1
	set mac_params(nest) $opts(-l)
    } else {
	set mac_params(subfolds) $opts(-l)
    }
    mac::getSortingOption $opts(-b)
    set rgx $opts(-f)
    set rgx [string trimleft $rgx ^]
    set rgx [string trimright $rgx $]
    if {$rgx==""} {
	set rgx ".*"
    } 
    set mac_params(regex) "^$rgx\$"
    # If option -all is given, it overrides any -f option.
    # It is equivalent to '-f .* -n 0'.
    if {$opts(-all) == 1} {
	set mac_params(regex) ".*"
	set mac_params(neg) 0
    } 
    switch $subcmd {
	copy -
	move {
	    set mac_params(trgtfold) $opts(-t)
	    if {$subcmd=="copy"} {
		set subcmd clon
	    } 
	    if {$opts(-t)==""} {
		return "No target folder for 'files $subcmd': option -t missing."
	    } 
	    mac::moveOrCopy $subcmd
	}
	rename {
	    if {$opts(-r)==""} {
		return "Replacement expression (option -r) is empty."
	    } 
	    set mac_params(replace) $opts(-r)
	    set mac_params(caseopt) [lsearch  [list u l w f] $opts(-k)]
	    set mac_params(numbering) $opts(-d)
	    set oldexp $mac_params(truncexp)
	    set mac_params(truncexp) $opts(-x)
	    if {$mac_params(caseopt)=="-1"} {
		if {$opts(-k)!=""} {
		    return "Bad value for option -k : should be u, l, w, or f" 
		} 
		set mac_params(casing) 0
	    } else {
		set mac_params(casing) 1
	    }
	    if {$mac_params(truncexp)==""} {
		set mac_params(truncating) 0
		set mac_params(truncexp) $oldexp
	    } else {
		set mac_params(truncating) 1
	    }
	    set mac_params(addoptions) [expr $mac_params(casing) + $mac_params(numbering) + $mac_params(truncating)]
	    mac::RenameProc
	}
	duplicate -
	trash -
	lock -
	unlock -
	alias -
	list {
	    return [mac::[string totitle $subcmd]Proc]
	}
	select -
	unselect -
	untrash {	       
		return "MacMenu command '$subcmd' not available on OSX"
	}
	change {
	    set thecreator $opts(-c)
	    set thetype $opts(-t)
	    if {$thecreator=="" && $thetype==""} {
		return "No creator or type specified for 'files $subcmd': option -c or -t missing."
	    } 
	    if {$thecreator!=""} {
		set tmplist $mac::creatorslist
		set mac::creatorslist [lreplace $mac::creatorslist 0 0 $thecreator]
		set mac_params(creatoridx) 0
		mac::ChangeCreatorProc
		set mac::creatorslist tmplist
	    } 
	    if {$thetype!=""} {
		set tmplist $mac::typeslist
		set mac::typeslist [lreplace $mac::typeslist 0 0 $thetype]
		set mac_params(typeidx) 0
		mac::ChangeTypeProc $mac_params(srcfold)
		set mac::typeslist tmplist
	    } 
	}
	transcode {
		set mac_params(fromencoding) $opts(-o)
		set mac_params(toencoding) $opts(-t)
		set enclist [encoding names]
		if {[lsearch -exact $enclist $mac_params(fromencoding)]=="-1"
			|| [lsearch -exact $enclist $mac_params(toencoding)]=="-1"} {
			return "Unknown encoding"
		} 
		return [mac::ChangeEncodingProc]
		}
	transtype {
	    set mac_params(fromeol) $opts(-o)
	    set mac_params(toeol) $opts(-t)
	    if {[lsearch -exact $mac::eolslist $mac_params(fromeol)]=="-1" && $mac_params(fromeol)!="all"} {
	        return "Unknown type '$mac_params(fromeol)'. Should be mac, unix, win or all."
	    } 
	    if {[lsearch -exact $mac::eolslist $mac_params(toeol)]=="-1"} {
	        return "Unknown target type '$mac_params(toeol)'. Should be mac, unix or win."
	    } 
	    return [mac::ChangeEolsProc]
	    }
	rmalias {
	    mac::RemoveAliasProc
	}
	default {return "Unknown subcommand $subcmd"}	
    }
    return
}

proc macsh::infos {subcmd {item ""}} {
    global mac_params
    set res ""
    if {[expr {$item==""} && {$subcmd!="hardware"}]} {
	return "Missing path: should be 'info $subcmd <path>'"
    } 
    switch $subcmd {
	"file" {
	    if {[file dirname $item]==[file separator] \
	      || [file dirname $item]=="."} {
		set item [string trimleft $item [file separator]]
		set item [file join [macsh::pwd] $item]
	    } 
	    if {![file exists $item] || ![file isfile $item]} {
		return "Can't find file '$item'"
	    }
	    mac::getFilesInfo $item
	}
	"folder" {
	    mac::trimRightSeparator item
	    if {[file dirname $item]==[file separator] \
	      || [file dirname $item]=="."} {
		set item [string trimleft $item [file separator]]
		set item [file join [macsh::pwd] $item]
	    } 
	    if {![file exists $item] || ![file isdirectory $item]} {
		return "Can't find folder '$item'"
	    }
	    mac::getFolderInfo $item
	    if {$mac_params(isshared)} {
	        mac::getFolderSharInfo $item
	    } 
	}
	"disk" - "volume" {
	    set subcmd volume
	    set item [string trim $item [file separator]]
	    mac::getVolumeInfo $item
	}
	"appl" {
	    if {[file dirname $item]==[file separator] \
	      || [file dirname $item]=="."} {
		set item [string trimleft $item [file separator]]
		set item [file join [macsh::pwd] $item]
	    } 
	    if {![file exists $item] || ![file isfile $item]} {
		return "Can't find file '$item'"
	    }
	    if ![mac::getApplInfo $item] {
		return "Couldn't get info for application [file tail $item]"
	    }
	}
	"process" {
	    if {[lsearch [mac::getProcessesList] $item]==-1} {
		return "'$item' is not a running process" 
	    } 
	    mac::getProcessInfo $item
	}
	"hardware" {
	    mac::getHardwareInfo 
	}
	default {return "files: unknown subcommand $subcmd"}
    }
    global mac${subcmd}info mac_description
    foreach t [array names mac${subcmd}info] {
	lappend res "$mac_description($t): [set mac${subcmd}info($t)]\n"
    } 
    return [join [lsort -dictionary $res] ""]
}

proc macsh::empty {} {
    mac::emptyTrash
    return
}

proc macsh::eject {} {
    global mac_params
    set mac_params(fromshell) 1
    mac::eject
}

proc macsh::restart {} {mac::restart}

proc macsh::sleep {} {
    mac::sleep
    return ""
}

proc macsh::shutdown {} {mac::shutDown}


proc macsh::version {} {
    return [alpha::package versions macMenu]
}

proc macsh::bindings {} {
    return [mac::bindingsInfoString]
}

proc macsh::tutorial {} {
	    mac::macMenuTutorialInfo
	    winunequalHor
}
