# File: "mfServices.tcl"
#                        Created: 2004-09-16 07:15:20
#              Last modification: 2005-07-14 01:37:32
# Author: Bernard Desgraupes
# e-mail: <bdesgraupes@easyconnect.fr>
# www: <http://webperso.easyconnect.fr/bdesgraupes/>
# Description: this file is part of the Metafont Mode package for Alpha.
# See comments at the beginning of 'mfMode.tcl'.

namespace eval Mf {}

proc mfServices.tcl {} {}

# xserv declarations
# ==================
::xserv::addToCategory Metafont Mf GfToPk GfToDvi PlToTfm \
							TfmToPl VfToVpl VplToVf MakeTexPk

::xserv::declare Mf "Process a Metafont source file" \
 file mode {mag 1} {options ""} {base ""}

::xserv::declare GfToPk "Convert generic font to pk" file

::xserv::declare GfToDvi "Convert generic font to dvi" file

::xserv::declare PlToTfm "Convert font property list to tfm" file

::xserv::declare TfmToPl "Convert tfm file to font property list" file

::xserv::declare VfToVpl "Convert vf file to virtual font property list" vf tfm 

::xserv::declare VplToVf "Convert virtual font property list to vf file" file

::xserv::declare MakeTexPk "Execute a MakeTexPk script" file


# xserv implementations
# =====================

# CMacTex mf implementation
# -------------------------
# CMacTex signatures:
# # CMT3	mf
# # CMTd	gftodvi
# # CMTe	gftopk
# # CMTj	pltotf
# # CMTk	tftopl
# # CMTl	vftovp
# # CMTm	vptovf

::xserv::register Mf CMacTex \
  -sig CMT3 -driver {
	set cmdline "mf "
	append cmdline "\\mode=$params(mode); "
	append cmdline "mag=$params(mag); "
	append cmdline "$params(options) "
	if {$params(base) ne ""} {
		append cmdline "input $params(base);"
	}
	append cmdline "input [file::unixPathToFinder $params(file)];"
	tclAE::send $params(xservTarget) CMTX exec ---- [tclAE::build::TEXT $cmdline] \
	  dest [tclAE::build::alis [file dir $params(file)]]
}

::xserv::register GfToPk CMacTex \
 -sig CMTe -driver {
   set cmdline "gftopk [file::unixPathToFinder $params(file)]"
   app::launchBack CMTe
   tclAE::send $params(xservTarget) CMTX exec ---- [tclAE::build::TEXT $cmdline]
}

::xserv::register GfToDvi CMacTex \
 -sig CMTd -driver {
	# sendQuitEvent 'CMTd'
   set cmdline "gftodvi [file::unixPathToFinder $params(file)]"
   app::launchBack CMTd
   tclAE::send $params(xservTarget) CMTX exec ---- [tclAE::build::TEXT $cmdline]
}

::xserv::register PlToTfm CMacTex \
 -sig CMTj -driver {
   # sendQuitEvent 'CMTj'
   set file [file::unixPathToFinder $params(file)]
   set root [file::unixPathToFinder [file root $params(file)]]
   set cmdline "pltotf $file $root.tfm"
   app::launchBack CMTj
   tclAE::send $params(xservTarget) CMTX exec ---- [tclAE::build::TEXT $cmdline]
}

::xserv::register TfmToPl CMacTex \
 -sig CMTk -driver {
   # sendQuitEvent 'CMTk'
   set file [file::unixPathToFinder $params(file)]
   set root [file::unixPathToFinder [file root $params(file)]]
   set cmdline "tftopl $file $root.pl"
   app::launchBack CMTk
   tclAE::send $params(xservTarget) CMTX exec ---- [tclAE::build::TEXT $cmdline]
}

::xserv::register VfToVpl CMacTex \
 -sig CMTl -driver {
   # sendQuitEvent 'CMTl'
   set vffile [file::unixPathToFinder $params(vf)]
   set tfmfile [file::unixPathToFinder $params(tfm)]
   set root [file::unixPathToFinder [file root $params(vf)]]
   set cmdline "vftovp $vffile $tfmfile $root.vpl"
   app::launchBack CMTl
   tclAE::send $params(xservTarget) CMTX exec ---- [tclAE::build::TEXT $cmdline]
}

::xserv::register VplToVf CMacTex \
  -sig CMTm -driver {
	# sendQuitEvent 'CMTm'
	set file [file::unixPathToFinder $params(file)]
	set root [file::unixPathToFinder [file root $params(file)]]
	set cmdline "vptovf $file $root.vf $root.tfm"
	app::launchBack CMTm
	tclAE::send $params(xservTarget) CMTX exec ---- [tclAE::build::TEXT $cmdline]
}

::xserv::register MakeTexPk CMacTex \
  -sig CMT9 -driver {
	app::launchBack CMT9
	tclAE::send $params(xservTarget) aevt odoc ---- [tclAE::build::alis $params(file)]
}


# OzMetafont implementation
# -------------------------

::xserv::register Mf OzMetafont \
  -sig OzMF -driver {
	if {$params(mode) == "proof"} {
		app::launchFore OzMF
		tclAE::send $params(xservTarget) aevt odoc ---- [tclAE::build::alis $params(file)]
	} else {
		if {[catch {Mf::findResolution} res]} {
			alertnote $res
			return
		} 
		set makefile [file join [file dir $params(file)] tmp.make]
		set fileId [open $makefile w+] 
		fconfigure $fileId -translation cr
		puts $fileId [Mf::buildMakeLine $res]
		close $fileId
		Mf::runMakePkFile $makefile
	}
}

::xserv::register GfToPk OzMetafont \
 -sig OzMF -driver {
   app::launchBack OzMF
   tclAE::send $params(xservTarget) aevt odoc ---- [tclAE::build::alis $params(file)]
}

# # Note: no GfToDvi service with OzMetafont. There does not seem to be 
# # any way to execute GfToDvi via an AppleEvent sent to OzMetafont.
#     ::xserv::register GfToDvi OzMetafont -sig OzMF -driver {}

::xserv::register PlToTfm OzMetafont \
 -sig OzMF -driver {
   app::launchBack OzMF
   set file $params(file)
   tclAE::send $params(xservTarget) aevt odoc ---- [tclAE::build::alis $file]
}

::xserv::register TfmToPl OzMetafont \
 -sig OzMF -driver {
   app::launchBack OzMF
   set file $params(file)
   tclAE::send $params(xservTarget) aevt odoc ---- [tclAE::build::alis $file]
}

::xserv::register VfToVpl OzMetafont \
 -sig OzMF -driver {
   app::launchBack OzMF
   tclAE::send $params(xservTarget) aevt odoc ---- [tclAE::build::alis $params(vf)]
}

::xserv::register VplToVf OzMetafont \
 -sig OzMF -driver {
   set file $params(file)
   app::launchBack OzMF
   tclAE::send $params(xservTarget) aevt odoc ---- [tclAE::build::alis $file]
}

::xserv::register MakeTexPk OzMetafont \
  -sig OzMF -driver {
	app::launchBack OzMF
	tclAE::send $params(xservTarget) aevt odoc ---- [tclAE::build::alis $params(file)]
}



# teTex mf implementation
# -----------------------
::xserv::register Mf teTex \
  -driver {
	cd [file dir $params(file)]
	set cmdline "exec $params(xserv-mf)"
	append cmdline " \\\\ mode=$params(mode)\\;"
	append cmdline " mag=$params(mag)\\;"
	append cmdline " $params(options)"
	if {$params(mode) eq "proof" || $params(mode) eq "smoke"} {
		# Impose the nodisplays option because teTeX mf requires X11 
		append cmdline "nodisplays\\;"
	} 
	if {$params(base) ne ""} {
		append cmdline "input $params(base)"
	}
	append cmdline " input $params(file)"
	eval $cmdline
} -mode Alpha -progs {mf}

::xserv::register GfToPk teTex \
 -driver {
   set cmdline [list $params(xserv-gftopk)]
   append cmdline "$params(file)"
   return $cmdline
} -mode Exec -progs {gftopk}

::xserv::register GfToDvi teTex \
 -driver {
   set cmdline [list $params(xserv-gftodvi)]
   lappend cmdline "$params(file)"
   return $cmdline
} -mode Exec -progs {gftodvi}

::xserv::register PlToTfm teTex \
 -driver {
   set cmdline [list $params(xserv-pltotf)]
   lappend cmdline $params(file) "[file root $params(file)].tfm"
   return $cmdline
} -mode Exec -progs {pltotf}

::xserv::register TfmToPl teTex \
 -driver {
   set cmdline [list $params(xserv-tftopl)]
   lappend cmdline $params(file) "[file root $params(file)].pl"
   return $cmdline
} -mode Exec -progs {tftopl}

::xserv::register VfToVpl teTex \
 -driver {
   set cmdline [list $params(xserv-vftovp)]
   lappend cmdline $params(vf) $params(tfm) "[file root $params(vf)].vpl"
   return $cmdline
} -mode Exec -progs {vftovp}

::xserv::register VplToVf teTex \
  -driver {
	set cmdline [list $params(xserv-vptovf)]
	set root [file root $params(file)]
	lappend cmdline $params(file) "$root.vf" "$root.tfm"
	return $cmdline
} -mode Exec -progs {vptovf}

# ::xserv::register MakeTexPk teTex \
#   -driver {
# 	set cmdline [list $params(xserv-mktexpk)]
# # 	lappend cmdline $params(file)
# # 	return $cmdline
# } -mode Exec -progs {mktexpk}


