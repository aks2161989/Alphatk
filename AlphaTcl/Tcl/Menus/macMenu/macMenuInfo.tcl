# File : "macMenuInfo.tcl"
#                        Created : 2001-01-22 21:35:05
#              Last modification : 2005-06-20 18:36:19
# Author : Bernard Desgraupes
# e-mail : <bdesgraupes@easyconnect.fr>
# Web-page : <http://webperso.easyconnect.fr/bdesgraupes/>
# 
# (c) Copyright : Bernard Desgraupes, 2001-2005
#         All rights reserved.
# This software is free software. See licensing terms in the MacMenu Help file.
#
# Description : this file is part of the macMenu package for Alpha.
# It contains procedures related to the management of Finder info
# with macMenu.
# 

# Load macMenu.tcl
macMenuTcl

namespace eval mac {}


# # # Show info procs # # #
# -------------------------

proc mac::fileInfo {} {
    if {[catch {set f [getfile "Select a file"]}]} {return}
    if ![mac::getFilesInfo $f] return
    mac::showFilesInfo 
}

proc mac::folderInfo {} {
    if {[catch {set f [get_directory -p "Select a folder"]}]} {return}
    if ![mac::getFolderInfo $f] return
    mac::showFolderInfo 
}

proc mac::volumeInfo {} {
    set vollist [mac::getAllVolsList]
    if {[llength $vollist]==1} {
	set vol [lindex $vollist 0]
    } else {
	if {[catch {set vol [listpick -p "Choose a volume" $vollist]}]} {return} 
    }
    if {$vol==""} {return} 
    if ![mac::getVolumeInfo $vol] return
    mac::showVolumeInfo 
}

proc mac::applicationInfo {} {
    if {[catch {set f [getfile "Select an application"]}]} {return}
    if ![mac::getApplInfo $f] return
    mac::showApplInfo 
}

proc mac::processInfo {} {
    if {[catch {set process [listpick -p "Running processes" \
      [mac::getProcessesList]]}]} {return} 
    if {$process==""} {return} 
    if ![mac::getProcessInfo $process] return
    mac::showProcessInfo 
}

proc mac::hardwareInfo {} {
    global mac_params
    if ![mac::getHardwareInfo] {
	status::msg ""
	return
    }
    mac::showHardwareInfo 
}



# # # Building info windows # # #
# -------------------------------

proc mac::showFilesInfo {} {
    global mac_params
    mac::initInfoWindow File
    mac::infoDialogLine file name {e 30}
    mac::infoDialogLine file path t
    mac::infoDialogLine file kind t
    mac::infoDialogLine file phys t
    mac::infoDialogLine file ptsz t
    mac::infoDialogLine file dfsz t
    mac::infoDialogLine file rfsz t
    mac::infoDialogLine file ascd t
    mac::infoDialogLine file asmo t
    mac::infoDialogLine file asty {e 6} fcrt {e 6}
    mac::infoDialogLine file aslk c pspd c
    mac::infoDialogLine file vers t
    mac::infoDialogLine file ver2 t
    incr mac_params(y) 10
    mac::infoButtonPart 100
    set mac_params(infovalues) [eval dialog -w 600 -h $mac_params(y) [join $mac_params(args)]]
    mac::getFileValues
}

proc mac::showFolderInfo {} {
    global macfolderinfo mac_params
    mac::initInfoWindow Folder
    mac::infoDialogLine folder name {e 30}
    mac::infoDialogLine folder path t
    mac::infoDialogLine folder kind t
    mac::infoDialogLine folder phys t
    mac::infoDialogLine folder ptsz t
    mac::infoDialogLine folder ascd {e 15}
    mac::infoDialogLine folder asmo {e 15}
    mac::infoDialogLine folder asty {e 6}
    mac::infoDialogLine folder fcrt {e 6}
    incr mac_params(y) 10
    mac::infoButtonPart
    set mac_params(infovalues) [eval dialog -w 500 -h $mac_params(y) [join $mac_params(args)]]
    mac::getFolderValues
}

proc mac::showVolumeInfo {} {
    global macvolumeinfo mac_params
    mac::initInfoWindow Disk
    mac::infoDialogLine volume name {e 30}
    mac::infoDialogLine volume kind t
    mac::infoDialogLine volume capa t
    mac::infoDialogLine volume phys t
    mac::infoDialogLine volume frsp t
    mac::infoDialogLine volume ascd {e 15}
    mac::infoDialogLine volume asmo {e 15}
    mac::infoDialogLine volume isej y isrv y
	mac::infoDialogLine volume istd y igpr y
	mac::infoDialogLine volume dfmt t
    incr mac_params(y) 10
    mac::infoButtonPart 50
    set mac_params(infovalues) [eval dialog -w 550 -h $mac_params(y) [join $mac_params(args)]]
    mac::getVolumeValues
}

proc mac::showApplInfo {} {
    global mac_params
    mac::initInfoWindow Application
    mac::infoDialogLine appl name {e 30}
    mac::infoDialogLine appl path t
    mac::infoDialogLine appl kind t
    mac::infoDialogLine appl phys t
    mac::infoDialogLine appl ptsz t
    mac::infoDialogLine appl dfsz t rfsz t
    mac::infoDialogLine appl ascd {e 15}
    mac::infoDialogLine appl asmo {e 15}
    mac::infoDialogLine appl asty {e 6} fcrt {e 6}
    mac::infoDialogLine appl vers t
    mac::infoDialogLine appl ver2 t
    mac::infoDialogLine appl sprt t
    mac::infoDialogLine appl mprt {e 8} appt {e 8}
    mac::infoDialogLine appl aslk y pspd y
    mac::infoDialogLine appl isab y hscr y
	mac::infoDialogLine appl Clsc y
    incr mac_params(y) 10
    mac::infoButtonPart 100
    set mac_params(infovalues) [eval dialog -w 600 -h $mac_params(y) [join $mac_params(args)]]
    mac::getApplValues
}

proc mac::showProcessInfo {} {
    global mac_params
    mac::initInfoWindow Process
    mac::infoDialogLine process name {e 30}
    mac::infoDialogLine process file t
    mac::infoDialogLine process asty {e 6}
    mac::infoDialogLine process fcrt {e 6}
    mac::infoDialogLine process isab y
    mac::infoDialogLine process revt y
	mac::infoDialogLine process clsc y
    incr mac_params(y) 10
    mac::infoButtonPart
    set mac_params(infovalues) [eval dialog -w 500 -h $mac_params(y) [join $mac_params(args)]]
    mac::getOtherValues
}

proc mac::showHardwareInfo {} {
    global mac_params 
    mac::initInfoWindow Hardware
	mac::infoDialogLine hardware cpuf t
	mac::infoDialogLine hardware cput t
	mac::infoDialogLine hardware pclk t
	mac::infoDialogLine hardware bclk t
	mac::infoDialogLine hardware lram t
	mac::infoDialogLine hardware pgsz t
	mac::infoDialogLine hardware sysa t
	mac::infoDialogLine hardware sysv t
	mac::infoDialogLine hardware cbon t
	mac::infoDialogLine hardware vm   z
	incr mac_params(y) 10
    mac::infoButtonPart
    set mac_params(infovalues) [eval dialog -w 500 -h $mac_params(y) [join $mac_params(args)]]
    mac::getHardwareValues
}

proc mac::showSharingInfo {type} {
    global mac_params mac${type}info
    mac::initInfoWindow Permissions
    append mac_params(infotext) "Permissions for \"[set mac${type}info(name)]\"\n"
    mac::infoDialogLine $type sown t
    mac::infoDialogLine $type sgrp t
    mac::infoDialogLine $type ownr t
    mac::infoDialogLine $type gppr t
    mac::infoDialogLine $type gstp t
    set mac_params(args) [list "-b OK 400 $mac_params(y) 480 [expr $mac_params(y) + 20]" \
      "-b \"Get Text\" 10 $mac_params(y) 85 [expr $mac_params(y) + 20]" "[join $mac_params(args)]"
    ]
    incr mac_params(y) 30
    set mac_params(infovalues) [eval dialog -w 500 -h $mac_params(y) [join $mac_params(args)]]
    mac::getOtherValues
}

proc mac::initInfoWindow {title} {
    global mac_params
    set mac_params(infotext) ""
    set mac_params(title) $title
    set mac_params(args) ""
    set mac_params(y) 40    
    lappend mac_params(args) [list -t "* $mac_params(title) Info *" 180 5 400 25]
}


# # # Info building blocks
# ------------------------
# The info dialog is built line by line. Types are:
# 	t	text
# 	e	edit field
# 	c	checkbox
# 	y	yes/no
# 	z	on/off
proc mac::infoDialogLine {item args} {
    global mac${item}info mac_params macMenumodeVars
    global mac_description mac::yesno 
    set xcoord 10
    set count 0
    foreach {code type} $args {
	set widget [lindex $type 0]
	set wd [lindex $type 1]
	if {$wd==""} {set wd 15} 
	set rep [set mac${item}info($code)]
	# Bug 1194: an edit field can be empty
	if {$rep == "" && $widget != "e"} continue
	if {$rep=="msng"} {set rep "????"}
	set y $mac_params(y)
	incr count
	eval lappend mac_params(args) [list [dialog::text "$mac_description($code)  " $xcoord y]]
	switch $widget {
	    "t" {
		if {$code=="path" || $code=="file"} {
		    mac::pathLine "$rep "
		} else {
		    set y $mac_params(y)
		    eval lappend mac_params(args) [list [dialog::text "$rep  " [expr $xcoord + 170] y ]]
		}
	    }
	    "e" {
		set y $mac_params(y)
		eval lappend mac_params(args) [list [dialog::edit "$rep" [expr $xcoord + 170] y $wd]]
	    }
	    "c" {
		set y $mac_params(y)
		eval lappend mac_params(args) [list [dialog::checkbox "   " "[mac::getBoolValue $rep]" [expr $xcoord + 170] y]]
	    }
	    "y" {
		set y $mac_params(y)
		eval lappend mac_params(args) [list [dialog::text "$mac::yesno([mac::getBoolValue $rep]) " [expr $xcoord + 170] y ]]
	    }
	    "z" {
		set y $mac_params(y)
		set rep [mac::getBoolValue $rep]
		eval lappend mac_params(args) [list [dialog::text "$mac::yesno([incr rep 2])  " [expr $xcoord + 170] y ]]
	    }
	}
	append mac_params(infotext) "$mac_description($code): $rep\n"
	incr xcoord 300
    }
    if {$count} {
	set mac_params(y) [expr $mac_params(y) + $macMenumodeVars(lineSkip)]
    } 
}

proc mac::infoButtonPart { {offset 0} } {
    global mac_params
    set mac_params(args) [list "-b Dismiss [expr 400 + $offset] $mac_params(y) [expr 480 + $offset] [expr $mac_params(y) + 20]" \
      "-b \"Get Text\" 10 $mac_params(y) 85 [expr $mac_params(y) + 20]" "[join $mac_params(args)]"
    ]
    if {$mac_params(title)=="File"} {
      lappend mac_params(args) "-b Set 100 $mac_params(y) 175 [expr $mac_params(y) + 20]" 
    } 
    if {$mac_params(isshared)} {
      lappend mac_params(args) "-b Permissions 190 $mac_params(y) 295 [expr $mac_params(y) + 20]" 
    } 
    incr mac_params(y) 30
}



# # # Bindings Info # # #
# -----------------------
proc mac::macMenuBindingsInfo {} {
    global tileLeft tileTop tileWidth errorHeight
    new -g $tileLeft $tileTop [expr $tileWidth*.6] [expr $errorHeight *2] \
      -n "* MacMenu Bindings *" -info [mac::bindingsInfoString]
    if {![catch {search -f 1 -all -s -r 1 -i 1 {('|<)[a-z=-]+('|>)} 0} res]} {
	foreach {beg end} $res {
	    text::color $beg $end 1
	}
    }
    text::color 0 [nextLineStart 0] 5
    refresh
}

proc mac::bindingsInfoString {} {
    set mess "KEY BINDINGS AVAILABLE FOR THE MAC MENU\n\n"
    append mess "Press 'ctrl-z', release, then hit one of the following letters:\r"
	append mess "  'a'	make <a>liases\r"
	append mess "  'b'	show <b>indings info\r"
	append mess "  'c'	<c>opy files\r"
	append mess "  'd'	<d>uplicate files\r"
	append mess "  'e'	<e>mpty the trash\r"
	append mess "  'f'	delete resource <f>orks\r"
	append mess "  'j'	e<j>ect a disk\r"
	append mess "  'k'	loc<k> files\r"
	append mess "  'l'	<l>ist files\r"
	append mess "  'm'	<m>ove files\r"
	append mess "  'r'	<r>ename files\r"
	append mess "  't'	send files to the <t>rash\r"
	append mess "  'u'	<u>nlock files\r"
    append mess "You can also use:\r"
    append mess "'ctrl-cmd-y'	to open the Mac Shell\r"
    append mess "'TAB' key	for completions in Mac shell\r"
    return $mess
}


# # # Tutorial # # #
# ------------------
proc mac::macMenuTutorialInfo {} {
    help::openExample "MacMenu Example" 
}