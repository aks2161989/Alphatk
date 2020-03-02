# File : "macMenuGetInfo.tcl"
#                        Created : 2003-08-23 11:21:49
#              Last modification : 2005-06-19 20:47:39
# Author : Bernard Desgraupes
# e-mail : <bdesgraupes@easyconnect.fr>
# Web-page : <http://webperso.easyconnect.fr/bdesgraupes/>
# 
# (c) Copyright : Bernard Desgraupes, 2003-2005
#         All rights reserved.
# This software is free software. See licensing terms in the MacMenu Help file.
#
# Description : this file is part of the macMenu package for Alpha.
# It contains procedures to get info about items from the Finder
# with macMenu.
# 

# Load macMenu.tcl
macMenuTcl

namespace eval mac {}

# # # Getting info procs # # #
# ============================

proc mac::getFilesInfo {file} {
    global macfileinfo mac_params
    watchCursor
    status::msg "Seeking file info..."    
    set macfileinfo(name) [file tail $file]
    set macfileinfo(path) [file dirname $file]
    getFileInfo $file arr
    set macfileinfo(dfsz) "$arr(datalen) bytes"
    # In case we're on MacOS X and can't yet read these
    ensureset arr(resourcelen) 0
    set macfileinfo(rfsz) "$arr(resourcelen) bytes"
	set mac_params(isshared) 1
	set file [file::unixPathToFinder $file]
	set propDesc [mac::findItemProperties $file]
	set codeList [list aslk asty fcrt gppr gstp kind ownr \
	  phys pspd ptsz sgrp sown ver2 vers]
	if {$propDesc!=""} {
		mac::storeProperties $propDesc file $codeList
	} else {
		return 0
	} 
	tclAE::disposeDesc $propDesc
	status::msg ""
    return 1
}

proc mac::getFolderInfo {fold} {
    global macfolderinfo mac_params
    watchCursor
    status::msg "Seeking folder info..."
    set macfolderinfo(name) [file tail $fold]
    set macfolderinfo(path) [file dirname $fold]
	set mac_params(isshared) 1
	set fold [file::unixPathToFinder $fold]
	set propDesc [mac::findItemProperties $fold]
	set codeList [list asty fcrt gppr gstp kind ownr \
	  phys ptsz sgrp sown]
	if {$propDesc!=""} {
		mac::storeProperties $propDesc folder $codeList
	} else {
		return 0
	} 
	tclAE::disposeDesc $propDesc
	status::msg ""
    return 1
}

proc mac::getFolderSharInfo {fold} {
    global macfolderinfo mac_params
    if {!$mac_params(gotfoldsharinfo)} {
	set macfolderinfo(sown) [mac::findItemProperty sown cfol $fold]
	set macfolderinfo(sgrp) [mac::findItemProperty sgrp cfol $fold]
	set macfolderinfo(ownr) [mac::findItemProperty ownr cfol $fold]
	set macfolderinfo(gppr) [mac::findItemProperty gppr cfol $fold]
	set macfolderinfo(gstp) [mac::findItemProperty gstp cfol $fold]
	set macfolderinfo(iprv) [mac::findItemProperty iprv cfol $fold bool]
	set macfolderinfo(smou) [mac::findItemProperty smou cfol $fold bool]
	set macfolderinfo(sexp) [mac::findItemProperty sexp cfol $fold bool]
	set macfolderinfo(spro) [mac::findItemProperty spro cfol $fold bool]        
	set mac_params(gotfoldsharinfo) 1
    } 
}
    
proc mac::getVolumeInfo {vol} {
    global macvolumeinfo mac_params
    watchCursor
    status::msg "Seeking disk info..."
    set macvolumeinfo(name) [mac::trimRightSeparator vol]
	set mac_params(isshared) 1
	set vol [file::unixPathToFinder $vol]
	set propDesc [mac::findItemProperties $vol]
	set codeList [list capa dfmt frsp fshr gppr gstp igpr isrv istd \
	  kind ownr phys sgrp sown]
	if {$propDesc!=""} {
		mac::storeProperties $propDesc volume $codeList
	} else {
		return 0
	}
	tclAE::disposeDesc $propDesc
	# Finder returns wrong info for 'isej'. Ask System Events.
	set macvolumeinfo(isej) [mac::isEjectable $vol]
	status::msg ""
    return 1
}

proc mac::getVolumeSharInfo {vol} {
    global macvolumeinfo mac_params
    if {!$mac_params(gotvolsharinfo)} {
	set macvolumeinfo(sown) [mac::findItemProperty sown cdis $vol TEXT]
	set macvolumeinfo(sgrp) [mac::findItemProperty sgrp cdis $vol TEXT]
	set macvolumeinfo(ownr) [mac::findItemProperty ownr cdis $vol TEXT]
	set macvolumeinfo(gppr) [mac::findItemProperty gppr cdis $vol TEXT]
	set macvolumeinfo(gstp) [mac::findItemProperty gstp cdis $vol TEXT]
	set macvolumeinfo(iprv) [mac::findItemProperty iprv cdis $vol bool]
	set macvolumeinfo(smou) [mac::findItemProperty smou cdis $vol bool]
	set macvolumeinfo(sexp) [mac::findItemProperty sexp cdis $vol bool]
	set macvolumeinfo(spro) [mac::findItemProperty spro cdis $vol bool]        
	set mac_params(gotvolsharinfo) 1
    } 
}

proc mac::getApplInfo {appli} {
    global macapplinfo mac_params    
    watchCursor
    status::msg "Seeking application info..."
    set appli [string trimright $appli [file separator]]
    set macapplinfo(name) [file tail $appli]
    set macapplinfo(path) [file dirname $appli]
    getFileInfo $appli arr
    set macapplinfo(dfsz) "$arr(datalen) bytes"
    # In case we're on MacOS X and can't yet read these
    ensureset arr(resourcelen) 0
    set macapplinfo(rfsz) "$arr(resourcelen) bytes"
	set mac_params(isshared) 1
	set appli [file::unixPathToFinder $appli]
	set propDesc [mac::findItemProperties $appli]
	set codeList [list appt ascd aslk asmo asty Clsc fcrt hscr gppr gstp isab \
	  kind mprt ownr phys pspd ptsz sgrp sown sprt ver2 vers]
	if {$propDesc!=""} {
		mac::storeProperties $propDesc appl $codeList
	} else {
		return 0
	}
	if {[mac::isBundled $appli]} {
		# For a bundle, there is no notion of data/resource forks
		set macapplinfo(dfsz) ""
		set macapplinfo(rfsz) ""
	} 
	tclAE::disposeDesc $propDesc
	status::msg ""
    return 1
}

proc mac::getProcessInfo {process} {
    global macprocessinfo mac_params
    watchCursor
    status::msg "Seeking process info..."
    set macprocessinfo(name) $process
    set mac_params(isshared) 0
	set propDesc [mac::findItemProperties $process pcap]
	set codeList [list appt asty clsc fcrt file isab pusd revt]
	if {$propDesc!=""} {
		mac::storeProperties $propDesc process $codeList
	} else {
		return 0
	} 
	tclAE::disposeDesc $propDesc
	status::msg ""
    return 1
}

proc mac::getHardwareInfo {} {
    global machardwareinfo mac_params
    watchCursor
    status::msg "Seeking hardware info..."
    set mac_params(isshared) 0
	if $mac_params(gothdwrinfo) {return 1}
	set machardwareinfo(bclk) [mac::gestaltRead  bclk mhz  ]
	set machardwareinfo(cbon) [mac::gestaltRead  cbon vers ]
	set machardwareinfo(cpuf) [mac::gestaltRead  cpuf cpu  ]
	set machardwareinfo(cput) [mac::gestaltRead  cput cpu  ]
	set machardwareinfo(lram) [mac::gestaltRead  lram size ]
	set machardwareinfo(pclk) [mac::gestaltRead  pclk mhz  ]
	set machardwareinfo(pgsz) [mac::gestaltRead  pgsz size ]
	set machardwareinfo(sysa) [mac::gestaltRead  sysa sysa ]
	set machardwareinfo(sysv) [mac::gestaltRead  sysv vers ]
	set machardwareinfo(vm)   [mac::gestaltRead  "vm  " bool ]
	set mac_params(gothdwrinfo) 1
	status::msg ""
    return 1
}


# # # Getting properties procs # # #
# ==================================

# -------------------------------------------------------------------------
# Proc to find a specific property for a certain type of item. 
# Type can be : file, cfol, cdis, appf, prcs.
# On OSX, the argument "item" must be a Finder path, not a POSIX path.
# -------------------------------------------------------------------------
proc mac::findItemProperty {prop type item {as ""}} {
    set theAEDesc [tclAE::send -r 'MACS' core getd \
      ---- [tclAE::build::propertyObject \
      $prop [tclAE::build::nameObject \
      $type [tclAE::build::TEXT $item]]]]
    if {$as==""} {
	set objDesc [tclAE::getKeyData $theAEDesc ----]
    } else {
	set objDesc [tclAE::getKeyData $theAEDesc ---- $as]
    }
    if {$objDesc eq "'TEXT'()"} {
	return ""
    } 
    if {$as eq "bool"} {
	set res [mac::getBoolValue $objDesc]
    } 
    tclAE::disposeDesc $objDesc
    tclAE::disposeDesc $theAEDesc
    return $objDesc
}

# -------------------------------------------------------------------------
# Proc to find all the Finder properties for a certain type of item. 
# Type can be : file, cfol, cdis, appf, pcap (or prcs).
# The returned descriptor is of type reco.
# For processes, ask System Events rather than the Finder.
# Works only on OSX. 
# -------------------------------------------------------------------------
proc mac::findItemProperties {item {type "cobj"}} {
    if {$type=="pcap" || $type=="prcs"} {
        set sig sevs
	app::launchBack $sig
    } else {
	set sig MACS
    }
    set theAEDesc [tclAE::send -r '$sig' core getd ---- \
      [tclAE::build::propertyObject pALL [tclAE::build::nameObject $type [tclAE::build::TEXT $item]]]]
    if {[mac::testIfError $theAEDesc]} {
	alertnote "Couldn't get properties from Finder for '$item'"
	return ""
    } else {
	set objDesc [tclAE::getKeyDesc $theAEDesc ----]
	tclAE::disposeDesc $theAEDesc
	return $objDesc
    }
}

# -------------------------------------------------------------------------
# Convert various forms of booleans to 0/1 equivalent
# -------------------------------------------------------------------------
proc mac::getBoolValue {str} {
    switch -- $str {
	"false" - "bool(Ç00È)" {return 0}
	"true" - "bool(Ç01È)" {return 1}
	default {return $str}
    }
}

# -------------------------------------------------------------------------
# Implement the ToolBox Gestalt() function.
# -------------------------------------------------------------------------
proc mac::gestaltGet {selector} {
    global mac_params
    if {$mac_params(tclgestaltpresent)} {
	# If Tclgestalt is present use it, it is much faster
	if {[catch {set res [::gestalt $selector]}]} {
	    return ""
	} else {
	    return $res
	}
    } else {
	# Use AppleEvents. On OSX send the event to 'self'.
	if {[catch {set res [tclAE::build::resultData -s fndr gstl \
	  ---- [tclAE::build::TEXT $selector]]}]} {
	    return ""
	} else {
	    return $res
	}
    }
}

# -------------------------------------------------------------------------
# This proc formats the result of mac::gestalt according to
# the specified type.
# Type can be : size, vers, name, mhz, sysa, bool, cpu.
# -------------------------------------------------------------------------
proc mac::gestaltRead {selector type} {
    set res [mac::gestaltGet $selector]
    if {$res==""} {return ""}
    set ansr ""
    switch $type {
	"size" {
	    set ansr "$res bytes"
	}
	"vers" {
	    set ansr [format %1x $res]
	    regsub "(\\d{1,2})(\\d)(\\d)" $ansr "\\1.\\2.\\3" ansr
	    regsub "\\.0$" $ansr "" ansr
	}
	"name" {
	    set ansr [format %1x $res]
	    set name ""
	    set len [string length $ansr]
	    for {set i 0} {$i<$len} {incr i 2} {
	        append name [format %c 0x[string range $ansr $i [expr $i+ 1]]]
	    }
	    set ansr $name
	}
	"mhz" {
	    set len [string length $res]
	    set ansr "[string range $res 0 [expr $len - 7]].[string range $res [expr $len - 6] end] Mhz"
	}
	"sysa" {
	    if {$res==1} {
		set ansr "68k"
	    } else {
		set ansr "PowerPC"
	    }
	}
	"bool" {set ansr [expr {$res > 0}]}
	"cpu" {
		# See gestaltNativeCPUfamily in Gestalt.h
	    switch [format %1x $res] {
		0  {set ansr "68000"}
		1  {set ansr "68010"}
		2  {set ansr "68020"}
		3  {set ansr "68030"}
		4  {set ansr "68040"}
		101  {set ansr "601"}
		103  {set ansr "603"}
		104  {set ansr "604"}
		106  {set ansr "603e"}
		107  {set ansr "603ev"}
		108  {set ansr "750 (G3)"}
		109  {set ansr "604e"}
		10A - 10a {set ansr "604ev (Mach5)"}
		10C - 10c {set ansr "G4 (Altivec)"}
		110  {set ansr "G4 7450 (Vger, Altivec)"}
		111  {set ansr "Apollo, Altivec, G4 7455"}
		112  {set ansr "G4 7447"}
		120  {set ansr "750FX (Sahara)"}
		139  {set ansr "970"}
		69343836  {set ansr "486"}
		69353836  {set ansr "Pentium"}
		69357072  {set ansr "PentiumPro"}
		69356969  {set ansr "PentiumII"}
		default {set ansr "unknown"}
	    }
	}
	default {set ansr $res}
    }
    return $ansr
}

# -------------------------------------------------------------------------
# Get the size on disk of an item. Prop is ptsz (logical), phys (physical) 
# for a file or a folder; capa (capacity), frsp (free space) for a disk.
# Type is file, cfol or cdis.
# -------------------------------------------------------------------------
proc mac::getItemSize {prop type item} {
    return [mac::findItemProperty $prop $type $item TEXT]
}

# -------------------------------------------------------------------------
# Get the date of an item. Prop is ascd (creation) or asmo (modification).
# Type is file, cfol, cdis or appf.
# Direct object parameter's form : ldt (Ç00000000B7445E5EÈ)
# -------------------------------------------------------------------------
proc mac::getItemDate {prop type item {l ""}} {
    set theAEDesc [tclAE::send -r 'MACS' core getd \
      ---- [tclAE::build::propertyObject \
      $prop [tclAE::build::nameObject \
      $type [tclAE::build::TEXT $item]]]]
    set objDesc [tclAE::getKeyData $theAEDesc ---- ]    
    binary scan $objDesc I* long
    if {$l=="short"} {
	return [ISOTime::ISODate [lindex $long 1]]
    } else {
	return [ISOTime::ISODateAndTimeRelaxed [lindex $long 1]]
    }
}

# -------------------------------------------------------------------------
# Retrieve all the relevant properties from the descriptor.
# Type is file, folder, volume, appl or process.
# -------------------------------------------------------------------------
proc mac::storeProperties {objDesc type codeslist} {
    global mac${type}info mac_params
    foreach code $codeslist {
	if {[catch {set mac${type}info($code) [tclAE::getKeyData $objDesc $code TEXT]}]} {
	    set mac${type}info($code) ""
	}
    } 
    # Workaround the ascd/asmo bug (see comments in mac::itemDatesFromDesc)
    if {$type != "process"} {
	set mac${type}info(ascd) [mac::itemDatesFromDesc $objDesc ascd]
	set mac${type}info(asmo) [mac::itemDatesFromDesc $objDesc asmo]
    } 
}

# -------------------------------------------------------------------------
# (bug) tclAE::getKeyData fails to extract the ascd and asmo keywords.
# Use a regexp to extract them. Pattern: ascd:ldt (Ç00000000B7445E5EÈ)
# -------------------------------------------------------------------------
proc mac::itemDatesFromDesc {objDesc code {l ""}} {
    if {[regexp "$code:ldt \\(Ç(\[0-9a-fA-F\]+)È\\)" $objDesc dum res]} {
	set res [string trimleft $res 0]
	if {$l=="short"} {
	    return [ISOTime::ISODate [format %1d 0x$res]]
	} else {
	    return [ISOTime::ISODateAndTimeRelaxed [format %1d 0x$res]]
	}
    } else {
	return ""
    }
}

