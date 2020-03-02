# File : "macMenuShell.tcl"
#                        Created : 2001-01-22 21:35:13
#              Last modification : 2005-06-19 20:42:15
# Author : Bernard Desgraupes
# e-mail : <bdesgraupes@easyconnect.fr>
# Web-page : <http://webperso.easyconnect.fr/bdesgraupes/>
# 
# (c) Copyright : Bernard Desgraupes, 2001-2005
#         All rights reserved.
# This software is free software. See licensing terms in the MacMenu Help file.
#
#  Description : this file is part of the macMenu package for Alpha.
# It contains procedures to create a shell making the macMenu  functionalities
# available from a command line. Non interactive Unix  commands  can  be  also
# executed from this shell with AlphaX.

# Load macMenu.tcl
macMenuTcl

# Load the extra commands
catch {macMenuInterface; macMenuShellMore;}

proc macMenuShell.tcl {} {}

namespace eval mac {}
namespace eval macsh {}


# Help info for MacShell commands
# -------------------------------
# It is stored in the macsh_help array: the value is a list for each 
# subcommand of the command. Backslashes are substituted.
set macsh_help(files) [list {rename\t<-f -s -l -i -n -r -k -d -x -all>} \
  {copy\t<-f -s -l -i -n -t -o -all>} \
  {move\t<-f -s -l -i -n -t -o -all>} \
  {change\t<-f -s -l -i -n -c -t -all>} \
  {transcode\t<-f -s -l -i -n -o -t -all>} \
  {transtype\t<-f -s -l -i -n -o -t -all>} \
  {list\t<-f -s -l -i -n -b -all>} \
  {duplicate\t<-f -s -l -i -n -all>} \
  {trash\t<-f -s -l -i -n -all>} \
  {lock\t<-f -s -l -i -n -all>} \
  {unlock\t<-f -s -l -i -n -all>} \
  {alias\t<-f -s -l -i -n -all>} \
  {rmalias\t<-s -l -all>} \
  ] 

set macsh_help(infos) [list {file\t<path>} {folder\t<path>} {volume\t<path>} \
  {appl\t<path>} {process\t<processname>} hardware]

set macsh_help(help) [list "" -options {[cmdname]}]


# # # Shell definition # # #
# ==========================

proc mac::macShell {} {
    Shel::start "mac" {*Mac Shell*} \
      "WELCOME TO MAC SHELL\r\tType help to get info about commands.\r"
    # Binding MacShell completions to 'tab' key after the shellMode is loaded.
    Bind 0x30 	{mac::shellPathCompletion} Shel
    status::msg "Bound the \"tab\" key to macShell completion"
}

proc mac::evaluate {cmdline} {
    history add $cmdline
    if {$cmdline==""} return
    set cmd [lindex [split $cmdline] 0]
    if {[llength [info commands "::macsh::$cmd"]] || [auto_load "::macsh::$cmd"]} {
	catch {uplevel #0 ::macsh::$cmdline} res
	return $res
    } else {
	if {[string length [info command $cmd]]} {
	    # If the command is known to the Tcl interpreter, try to 
	    # evaluate $cmdline as a Tcl instruction
	    return [Alpha::evaluate $cmdline]
	} else {
	    # Otherwise try to interpret it as a Unix shell command
	    if {[catch {uplevel #0 exec $cmdline} res]} {
	        return "Couldn't execute command '$cmd'. Try 'man $cmd'."
	    } 
	    return $res
	}
    }
}

proc mac::Prompt {} {
    global Shel::startPrompt Shel::endPrompt
    return "${Shel::startPrompt}[file tail [string trimright [macsh::pwd] {:}]]${Shel::endPrompt} "
}


# # # MacShell commands # # #

proc macsh::help {{shellcmd ""}} {
    global macsh_help HOME
    if {$shellcmd eq ""} {
	set res "Basic commands available in Mac shell:\r"
	foreach c [lsort [info commands ::macsh::*]] {
	    regsub ::macsh:: $c "" c
	    if {[info exists macsh_help($c)]} {
		append res "[mac::displayShellCmdHelp $c]\n"
	    } else {
		append res "\t$c\n"
	    } 
	}
	append res "Type 'help <cmd>' to get info about command <cmd>.\r"
	append res "Plain Tcl commands are also interpreted in Mac shell.\r"
	return $res
    } 
    switch -- $shellcmd {
	"-options" {
	    return [join [mac::shellOptionsHelp] "\r"]
	}
	default {
	    if {[llength [info commands "::macsh::$shellcmd"]] || [auto_load ::macsh::$shellcmd]} {
	        if {[info exists macsh_help($shellcmd)]} {
	            return [mac::displayShellCmdHelp $shellcmd]
	        } else {
		    return "No help available for '$shellcmd'"
		}
	    } else {
		return "Not a Mac Shell command. Try 'man $shellcmd'"
	    }
	}
    }
}



# # # Unix-shell-like commands # # #
# ==================================

# -------------------------------------------------------------------------
# cd: change directory
# SYNTAX: 
# cd		change to Alpha's folder or to user's home dir (see the "Default Home" pref)
# cd .		change to directory of second to frontmost window (ie window just behind the shell)
# cd ..		change to parent directory. 
#     To go several levels up, type .. followed by several separators. E-g:
#     cd ..:::         etc.
#     cd ..///         etc.
#     Thus, .. is equivalent to ../
#     The following syntax is also accepted (except for [cd /] which 
#     changes to the root folder)
#     cd :::         etc.
#     cd ///         etc.
# cd blah	change to subfolder blah of current folder if blah exists
# cd abs_path	change to directory corresponding to absolute path "abs_path"
# On OSX, this command resolves the initial ~ to the users directory as usual.
# -------------------------------------------------------------------------
proc macsh::cd {{item ""}} {
    global HOME env mac_params macMenumodeVars
    # First handle the case where [cd] has no argument
    if {$item eq ""} {
	if {$macMenumodeVars(defaultHome)==1} {
	    set mac_params(pwd) $env(HOME)
	} else {
	    set mac_params(pwd) $HOME
	}
	return $mac_params(pwd)
    }
    # Resolve initial "~" on OSX.
    if {[regexp {^~} $item]} {
	regsub {~} $item $env(HOME) item
    } 
    # This is the [cd /] case on OSX
    if {$item=="/"} {
	set mac_params(pwd) $item
	return $mac_params(pwd)
    }
    if {[regexp "^(\\.\\.)?([file separator]*)$" $item dum dots seps]} {
	# This is the [cd ..///] or [cd ///] case
	set nb [string length $seps]
	if {!$nb} {set nb 1} 
	for {set i 0} {$i < $nb} {incr i} {
	    set mac_params(pwd) [file dirname $mac_params(pwd)]
	}
    } else {
	mac::trimRightSeparator item
	if {$item=="."} {
	    set topwin [win::StripCount [lindex [winNames -f] 1]]
	    if {$topwin!="" && [file exists $topwin]} {
		set mac_params(pwd) [file dirname $topwin]
	    } else {
		macsh::cd
	    }
	} else {
	    set dir [file join [macsh::pwd] $item]
	    if {[file exists $dir] && [file isdirectory $dir]} {
		set mac_params(pwd) $dir
	    } elseif {[file exists $item] && [file isdirectory $item]} {
		set mac_params(pwd) $item
	    } else {
		set volsList [mac::getAllVolsList]
		if {[lsearch -exact $volsList "$item"]!="-1"} {
		    if {$item==[file::startupDisk]} {
			set item /
		    } else {
			set item "/Volumes/$item"
		    }
		    set mac_params(pwd) $item
		} else {
		    return "No such folder '$item'"
		}
	    }
	} 
    }
    return $mac_params(pwd)
}     

# -------------------------------------------------------------------------
# pwd: print working directory
# Returns the complete path of the current MacShell folder.
# -------------------------------------------------------------------------
proc macsh::pwd {} {
    global mac_params
    set mac_params(pwd) $mac_params(pwd)
    return $mac_params(pwd)
}

# -------------------------------------------------------------------------
# ls: list
# List all files and subfolders in the current folder. On OSX, it calls 
# the Unix ls cammand for the current working directory.
# -------------------------------------------------------------------------
set macsh_help(ls) [list {[-ABCFGHLPRTWZabcdfghiklmnopqrstuwx1]}]

proc macsh::ls {args} {
    if {$args==""} {
	return [exec ls [macsh::pwd]]
    } else {
	return [exec ls [list $args] [macsh::pwd]]
    }
}

# -------------------------------------------------------------------------
# ld: list directories
# List subfolders in the current folder
# -------------------------------------------------------------------------
proc macsh::ld {} {
    global mac_params
    set reslist [glob -nocomplain -types d -dir [macsh::pwd] *]
    if {[llength $reslist]} {
	return [join $reslist "\n"] 
    } 
    return "No subfolders in [macsh::pwd]"
}

# -------------------------------------------------------------------------
# mkdir: make directory
# The mkdir command creates a new subfloder in the current folder. If no
# argument is given it will create an 'untitled' folder (same as using
# shift-cmd-N on OSX). If an argument is specified, it will be the name
# given to the new subfolder.
# -------------------------------------------------------------------------
proc macsh::mkdir {{item ""}} {
    global mac_params
    set res ""
    mac::trimRightSeparator item
    if {$item==""} {
	set dir [macsh::pwd]
	set theAE [tclAE::send -r 'MACS' core crel \
	  insh [tclAE::build::foldername $dir] \
	  kocl type(cfol)]
	set objDesc [tclAE::getKeyDesc $theAE ---- ]
	tclAE::disposeDesc $theAE
	set theAE [tclAE::send -r 'MACS' core getd ---- \
	  [tclAE::build::propertyObject pnam $objDesc]]
	set res [tclAE::getKeyData $theAE ---- TEXT]
	tclAE::disposeDesc $objDesc
	tclAE::disposeDesc $theAE
	return [file join [macsh::pwd] $res]
    } else {
	if {[file dirname $item]==[file separator] || [file dirname $item]=="."} {
	    set item [string trimleft $item [file separator]]
	    set item [file join [macsh::pwd] $item]
	} 
    }
    if {[file exists $item]} {
	return "Folder '[file tail $item]' already exists in [macsh::pwd]"
    }
    if {![catch {file mkdir $item}]} {return $item}
    return "mkdir failed"
}

# -------------------------------------------------------------------------
# edit: edit a file
# Give the name of the file : if it is in the current directory, the proc 
# will complete the path. You can use the completion mechanism to enter the
# name of the file : type the first letters, then hit the Tab key.
# If the 'edit' command is used with no argument, you are prompted to 
# select a file to edit.
# -------------------------------------------------------------------------
proc macsh::edit {{item ""}} {
    global HOME mac_params
    mac::trimRightSeparator item
    set filename [file join [macsh::pwd] $item]
    if {$item==""} {
	if {[catch {set item [getfile "Select a file"]}]} {return ""}
	::edit -c -w $item
    } elseif {[file exists $filename] && [file isfile $filename]} {
	::edit -c -w $filename
    } elseif {[file exists $item] && [file isfile $item]} {
	::edit -c -w $item
    } else {
	return "Error: Can't edit $item"
    }
    return $item
}     


# Shell help commands
# ===================

# Proc to build the 'help options' cmd in Mac Shell
proc mac::shellOptionsHelp {} {
    global macMenumodeVars
    return [list "\t-f <expr>\tfiltering regular expr (default '.*')" \
      "\t-s <folder>\tsource folder (default current folder)" \
      "\t-l <level>\tnesting level : 0, 1,... or all (default 0)" \
      "\t-i <0|1>\tignore case\? (default 0)" \
      "\t-n <0|1>\tnegate filter\? (default 0)" \
      "\t-t <folder>\ttarget folder (no default)" \
	  "\t-t <enc>\ttarget encoding in transcode (default iso8859-1)" \
	  "\t-t <kind>\ttarget eol in transtype (default mac)" \
      "\t-t <type>\tfile's type (no default)" \
      "\t-c <type>\tfile's creator (no default)" \
      "\t-o <0|1>\tforce overwrite\? (default $macMenumodeVars(overwriteIfExists), see prefs.)" \
	  "\t-o <enc>\toriginal encoding in transcode (default macRoman)" \
	  "\t-o <kind>\toriginal eol in transtype (default unix)" \
      "\t-r <expr>\tregsub expr for renaming (default &)" \
      "\t-k <0|1>\tcasing : u, l, w, f (default not-set)" \
      "\t-d <0|1>\tnumbering : 0/1 (default 0)" \
      "\t-b <m|c|s|k|l>\tsort by (no default)" \
      "\t-x <m\[.n\]>\ttruncate (default not-set)" \
      "\t-all \t\tall files (equivalent to '-f .*')"
    ]
}

proc mac::displayShellCmdHelp {cmd} {
    global macsh_help
    foreach sub $macsh_help($cmd) {
	lappend res "\t$cmd [subst -noc -nov $sub]"
    } 
    return [join $res "\r"]
}


# # # Completion mechanism # # #
# ==============================

# set macsh_keywd [list alias appl bindings change copy duplicate edit eject empty file \
#   files folder hardware help infos list lock mkdir more move options process rename \
#   restart shutdown transtype trash tutorial removeAlias unlock version volume ]
# 
# lappend completions(Tcl) {completion::cmd}
# 
# if {[info exists Shelcmds]} {
#     set Shelcmds [lsort -dictionary [concat $Shelcmds $macsh_keywd]]
# } else {
#     set Shelcmds $macsh_keywd
# }
# 
# unset -nocomplain macsh_keywd

# ----------------------------------------------------------------------------
# MacShell has a filepath completion mechanism bound to the TAB key  (like  in
# Unix shells). Type the first letters of a file's or folder's  name  and  hit
# the TAB key: the procedure will try to  complete,  looking  either  for  the
# relative or absolute path of a  file  or  folder  included  in  the  current
# folder. A complete path is supposed to start with a double quote in order to
# handle spaces in the path. If there are several possibilities, a  pick  list
# is displayed.
# ----------------------------------------------------------------------------
proc mac::shellPathCompletion {} {
    global macsh_keywd mac_params env
    set reslist ""
    set path ""
    set hasquote 0
    set inipos [getPos]
    if {![catch {search -s -f 0 {"} [pos::math $inipos - 1]} res]} {
	if {[pos::compare [lindex $res 0] < [lineStart $inipos]]} {
	    set path ""
	} else {
	    set hasquote 1
	    set pospath [lindex $res 1]
	    set path [getText $pospath $inipos]
	}
    } 
    if {$path eq ""} {
	if {![catch {search -s -f 0 -r 1 {\s} [pos::math $inipos - 1]} res]} {
	    if {[pos::compare [lindex $res 0] < [lineStart $inipos]]} {
		set path ""
	    } else {
		set pospath [lindex $res 1]
		set path [getText $pospath $inipos]
	    }
	} 
    } 
    if {$path eq ""} {return} 
    
    set dirpath [file dir $path]
    set substituted 0
    if {[file exists $dirpath] && $dirpath != [file separator] \
      && $dirpath != "." && $dirpath != "~"} {
	set fullpath $path
	set isfull 1
    } else {
	# Assume it is a relative. Resolve "~" or "."
	if {[regexp {^~} $dirpath]} {
	    regsub {^~} $path "" path
	    set dirpath $env(HOME)
	    set substituted 1
	} else {
	    if {[regexp {^\.} $path]} {
		regsub {^\.} $path "" path
		set substituted 1
	    } 
	    set dirpath [macsh::pwd]
	}
	set fullpath [file join $dirpath [string trimleft $path / ]]
	set isfull 0
    }
    set tmplist [glob -nocomplain -dir [file dir $fullpath] *]
    set reslist ""
    foreach sf $tmplist {
	if {[regexp "^[quote::Regfind $fullpath]" $sf]} {
	    if {[file isdirectory $sf]} {append sf [file separator]}
	    if {$isfull} {
		set sf [file tail $sf]
	    } else {
		set sf "[mac::relFilename $dirpath $sf]"
	    }
	    lappend reslist $sf
	} 
    } 
    switch [llength $reslist] {
	0 {
	    status::msg "No completion found"
	    return
	}
	1 {set res [lindex $reslist 0]}
	default {
	    if {[catch {listpick -p "Complete as:" [lsort -dictionary $reslist]} res]} {
		return
	    } 
	}
    }
    selectText $pospath $inipos
    deleteSelection
    if {$isfull || $substituted} {
	set res "[file join $dirpath $res]"
    } 
    if {$hasquote} {
	insertText $res
    } else {
	insertText "\"$res"
    }
    if {[lookAt [getPos]] != "\""} {
	insertText "\""
	goto [pos::math [getPos] -1]
    } elseif {[lookAt [pos::math [getPos] - 1]] == "\""} {
	goto [pos::math [getPos] -1]
    }
}

