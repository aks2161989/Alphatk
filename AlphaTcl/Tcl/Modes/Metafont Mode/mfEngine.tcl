# File: "mfEngine.tcl"
#                        Created: 2001-02-06 22:07:36
#              Last modification: 2005-07-15 10:27:49
# Author: Bernard Desgraupes
# e-mail: <bdesgraupes@easyconnect.fr>
# www: <http://webperso.easyconnect.fr/bdesgraupes/>
# Description: this file is part of the Metafont Mode package for Alpha.
# See comments at the beginning of 'mfMode.tcl'.

namespace eval Mf {}

# Force loading of mfMode.tcl
mfMenu


# Procs to process the Metafont source files
# ==========================================
# # # default {
# # # 	if {[app::type $MfmodeVars(mfSig)] == "exec"} {
# # # 		app::execute -showLog 1 -op mf -sigVar MfmodeVars(mfSig) \
# # # 		  -filename $mf_params(fullname)
# # # 	} else {
# # # 		alertnote "Unsupported $MfmodeVars(mfSig)"
# # # 	}
# # # }


proc Mf::runBuffer {} {
	global mf_params MfmodeVars
	# Do we magnify ?
	if {$mf_params(magstep) != 0} {
		set mfmag "magstep\($mf_params(magstep)\)"
	} else {
		set mfmag $mf_params(mag)
	}
	# Metafont processing mode
	if {$mf_params(chosenMode) eq "userDefined"} {
		set mfmode $MfmodeVars(mfModeForPrinter)
	} else {
		set mfmode $mf_params(chosenMode)
	}
	# Invoke the Mf service
	::xserv::invoke Mf -file [win::Current] -mode $mfmode -mag $mfmag\
	  -options [Mf::buildCommandOptions] -base $mf_params(baseFile)
	# Some bookkeeping
	set mf_params(done) 1
	if {$mf_params(chosenMode) != "proof" && $mf_params(chosenMode) != "smoke"} {
		set mf_params(tfmdone) 1
	}
	Mf::rebuildSubmenus ""
}


proc Mf::processAFolder {} {
	global mf_params
	if {[catch {get_directory -p "Select a folder."} folder]} {
		return
	} 
	Mf::processWithMakeTexPk $folder
}


proc Mf::processWithMakeTexPk {folder} {
	global mf_params 
	set filesindir [glob -nocomplain -dir [file join $folder] *.mf]
	if {[llength $filesindir] == 0} {
		alertnote "No \".mf\" files in this folder."
		return
	} 
	set maketexpkfile [file join $folder tmpall.make]
	if {[file exists $maketexpkfile]} {
		file delete $maketexpkfile
	}
	switch [buttonAlert "OK to process all \".mf\" files in '$folder'?" "Yes" "Cancel" ] {
		"yes" {
			if {[catch {Mf::findResolution} res]} {
				alertnote $res
				return
			} 
			set fileId [open $maketexpkfile a+] 
			fconfigure $fileId -translation cr
			foreach f $filesindir {
				Mf::setNames $f
				puts $fileId [Mf::buildMakeLine $res]
			}
			close $fileId
			Mf::runMakePkFile $maketexpkfile
		}
		"cancel" {
			app::launchFore "ALFA"
			return 
		}
	}
}


# Scripts and Command Lines
# =========================

proc Mf::buildCommandOptions {} {
	global mf_params  
	set opts ""
	# Add the options if the corresponding flag is set
	foreach op [list screenchars imagerules gfcorners notransforms] {
		if {[set mf_params($op)]} {append opts "$op; "}
	} 
	if {$mf_params(screenstrokes)} {
		if {$mf_params(chosenMode) ne "proof"} {
			alertnote "The \"screenstrokes\" option is for proof mode only. Ignoring it."
			Mf::toggleOption screenstrokes
			Mf::shadowMode screenstrokes
		} else {
			append opts "screenstrokes; "
		}
	}
	if {$mf_params(nodisplays)} {
		if {$mf_params(chosenMode) ne "proof"} {
			alertnote "The \"nodisplays\" option is for proof mode only. Ignoring it."
		} elseif {$mf_params(screenchars) || $mf_params(screenstrokes)} {
			alertnote "Contradictory options: you can't use \"nodisplays\" with \"screenchars\"\
			  or \"screenstrokes\". Ignoring it."
			Mf::toggleOption nodisplays
			Mf::shadowMode nodisplays
		} else {
			append opts "nodisplays; "
		}
	}
	
	return $opts
}


# --------------------------------------------------------------------------------------
# OzMetafont has no support for handling a complete command line via an Apple Event. 
# The workaround is to create a "make" file which OzMetafont will process 
# with its built-in MakeTeXPK.
# A nice side effect of this is that the "pk" files are done in the same
# time, so there is no need to invoke gftopk after processing.
# --------------------------------------------------------------------------------------
proc Mf::buildMakeLine {resolution} {
	global mf_params MfmodeVars 
	set cmdline "MakeTeXPK $mf_params(basename) "
	append cmdline "[lindex $resolution 1] [lindex $resolution 1] "
	# Do we magnify ?
	if {$mf_params(magstep) != 0} {
		append cmdline "magstep\($mf_params(magstep)\) "
	} else {
		append cmdline "$mf_params(mag) "
	}
	# Choose the mode
	if {$mf_params(chosenMode) == "localfont"} {
		append cmdline [lindex $resolution 0]
	} elseif {$mf_params(chosenMode) == "proof" || $mf_params(chosenMode) == "smoke"} {
		append cmdline $mf_params(chosenMode)
	} else {
		append cmdline $MfmodeVars(mfModeForPrinter)
	}
	# Add the options if the corresponding flag is set
	set opts [buildCommandOptions]
	if {$opts ne ""} {
		append cmdline ";$opts"
	} 
	# Input a base file if any
	if {$mf_params(baseFile) ne ""} {
		if {$opts eq ""} {append cmdline ";"}
		append cmdline "input $mf_params(baseFile)"
	}
	return $cmdline
}


# Make Pk files
# -------------

proc Mf::runMakePkFile {filename} {
	::xserv::invoke MakeTexPk -file $filename
}


