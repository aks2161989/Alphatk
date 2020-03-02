# File: "mpServices.tcl"
#                        Created: 2005-07-14 18:03:12
#              Last modification: 2005-07-15 12:04:27
# Author: Bernard Desgraupes
# e-mail: <bdesgraupes@easyconnect.fr>
# www: <http://webperso.easyconnect.fr/bdesgraupes/>
# Description: this file is part of the Metapost Mode package for Alpha.
# See comments at the beginning of 'mpMode.tcl'.

namespace eval Mp {}

proc mpServices.tcl {} {}

# xserv declarations
# ==================
# Put the Mp service in the Metafont category
::xserv::addToCategory Metafont Mp 

::xserv::declare Mp "Process a Metapost source file" \
 file {options ""} {mem ""}


# xserv implementations
# =====================

# CMacTex mp implementation
# -------------------------
# # Def with CMTX/exec event
	# ::xserv::register Mp CMacTex \
	#   -sig CMTw -driver {
	# 	set cmdline "mpost "
	# 	if {$params(mem) ne ""} {
	# 		append cmdline "&[file root $params(mem)] ; "
	# 	}
	# 	append cmdline "$params(options) "
	# 	if {$params(options) ne ""} {append cmdline "input "}
	# 	append cmdline "[file::unixPathToFinder $params(file)]"
	# 	tclAE::send $params(xservTarget) CMTX exec ---- [tclAE::build::TEXT $cmdline] \
	# 	  dest [tclAE::build::alis [file dir $params(file)]]
	# }

# # Def with aevt/odoc event
::xserv::register Mp CMacTex \
  -sig CMTw -driver {
	app::launchFore CMTw
	tclAE::send $params(xservTarget) aevt odoc ---- [tclAE::build::alis $params(file)]
}


# OzMetapost implementation
# -------------------------
# There is apparently no support in OzMetapost for options and mem files.
# The -options and -mem arguments are ignored.

::xserv::register Mp OzMetapost \
  -sig OzMP -driver {
	app::launchFore OzMP
	tclAE::send $params(xservTarget) aevt odoc ---- [tclAE::build::alis $params(file)]
}

