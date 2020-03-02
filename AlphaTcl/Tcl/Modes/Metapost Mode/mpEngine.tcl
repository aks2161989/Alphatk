# File: "mpEngine.tcl"
#                        Created: 2001-02-20 22:44:20
#              Last modification: 2005-07-15 11:47:53
# Author: Bernard Desgraupes
# e-mail: <bdesgraupes@easyconnect.fr>
# www: <http://webperso.easyconnect.fr/bdesgraupes/>
# Description: this file is part of the Metapost Mode package for Alpha.
# See comments at the beginning of 'mpMode.tcl'.

namespace eval Mp {}


# Procs to process the Metapost source files
# ==========================================
# default {
# 	if {[app::type $MpmodeVars(mpAppSig)] == "exec"} {
# 		app::execute -showLog 1 -op mp -sigVar MpmodeVars(mpAppSig) \
# 		  -filename $mp_params(fullname)
# 	} else {
# 		alertnote "Unsupported $MpmodeVars(mpAppSig)"
# 	}
# }

proc Mp::runBuffer {} {
	global mp_params MpmodeVars 
	set options ""
	# Is there a Metafont mode?
	if {$mp_params(chosenMode) != "proof"} {
		if {$mp_params(chosenMode) == "userDefined"} {
			append options "\\mode=$MpmodeVars(mpModeForPrinter); "
		} else {
			append options "\\mode=$mp_params(chosenMode); "
		}
	}
	# Do we magnify?
	if {$mp_params(magstep) != 0} {
		append options "\\mag=magstep\($mp_params(magstep)\); "
	} elseif {$mp_params(mag) != 1}  {
		append options "\\mag=$mp_params(mag); "
	}
	# Invoke the Mp service
	::xserv::invoke Mp -file [win::Current] \
	  -options $options -mem $mp_params(memFile)
	# Update submenus
	set mp_params(prefix-mpx) ""
	set mp_params(prefix-log) ""
	menu::buildSome metapostUtils
}

