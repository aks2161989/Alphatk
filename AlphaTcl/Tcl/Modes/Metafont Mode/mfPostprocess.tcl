# File: "mfPostprocess.tcl"
#                        Created: 2001-02-06 22:07:36
#              Last modification: 2005-07-14 11:14:13
# Author: Bernard Desgraupes
# e-mail: <bdesgraupes@easyconnect.fr>
# www: <http://webperso.easyconnect.fr/bdesgraupes/>
# Description: this file is part of the Metafont Mode package for Alpha.
# See comments at the beginning of 'mfMode.tcl'.

proc mfPostprocess.tcl {} {}

namespace eval Mf {}


# Procs to run the related programs
# =================================

proc Mf::invokeService {serv file {type ""}} {
	if {[Mf::checkExists $file $type]} {
		::xserv::invoke $serv -file $file
	}
}


proc Mf::postProcessing {serv} {
	global mf_params 
	if {$serv eq "VfToVpl"} {
		if {[catch {getfile "Select a vf file for $serv"} vffile]} {return} 
		if {[xserv::getCurrentImplementationNameFor Mf ""] ne "OzMetafont"} {
			# In the case of OzMetafont, only the vf file is necessary: the
			# tfm file is supposed to be at the right place in the TeX tree.
			if {[catch {getfile "Select a tfm file for $serv"} tfmfile]} {return} 
		} else {
			set tfmfile ""
		}
		Mf::setNames $vffile
		Mf::doVftoVplProc $vffile $tfmfile
	} else {
		if {[catch {getfile "Select a file to apply $serv"} file]} {return}
		Mf::setNames $file
		Mf::invokeService $serv $file
	}
}


proc Mf::doVftoVplProc {vffile tfmfile} {
	::xserv::invoke VfToVpl -vf $vffile -tfm $tfmfile
}


# Editable output files
# ---------------------
proc Mf::editLogFile {}  {
	global mf_params 
	set logfile [file join $mf_params(dirname) $mf_params(basename).log]
	if {![Mf::checkExists $logfile log]} {
		return
	} else {
		edit -c -r $res
	}
}


proc Mf::editPlFile {} {
	global mf_params 
	set plfile [file join $mf_params(dirname) $mf_params(basename).pl]
	if {[file exists $plfile]} {
		edit -c -mode Mf -r $plfile
	} else {
		alertnote "Can't find $mf_params(basename).pl in $mf_params(dirname)."
	}
	set mf_params(prefix-pl) ""
	Mf::rebuildSubmenus ""
}


