## -*-Tcl-*- (nowrap)
 # ===========================================================================
 # AlphaTcl - core Tcl engine
 #
 # FILE: "appPaths.tcl"
 #                                           created: 02/08/1997 {06:18:16 pm}
 #                                       last update: 03/13/2006 {02:52:31 PM}
 # Description:
 # 
 # Support for interaction with other applications, including specific
 # general scripts for some particular apps.
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #    www: <http://www.santafe.edu/~vince/>
 # 
 # Copyright (c) 1997-2006  Vince Darley
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ===========================================================================
 ##

alpha::library "fileServices" "1.0" {
    # Initialization script: source this file so that all services defined by
    # this package will be properly registered.  (We could define all of
    # these here in this script if we wanted to avoid sourcing this file.)
    appPaths.tcl
} maintainer {
    "Vince Darley" <vince@santafe.edu> <http://www.santafe.edu/~vince/>
} description {
    Declares various application services for viewing .pdf or .ps files, and
    compressed archives
} help {
    This library supports the package: xserv by declaring a variety of
    services that handle different types of files, such as .pdf, .ps, or
    compressed archives.  All of these helper applications can be set using
    the menu command "Config > Global Setup > Helper Applications":
    
    <<prefs::dialogs::helperApplications>>
    
    These services are automatically declared when ÇALPHAÈ is launched.
    
    See the file "appPaths.tcl" for the package: xserv declarations.
}

proc appPaths.tcl {} {}

# viewPDF

::xserv::addToCategory PDF pdfViewer

::xserv::declareBundle pdfViewer {View a PDF file} \
  viewPDF closePDF

::xserv::declare viewPDF {Display a PDF file} \
  file {line ""} {source ""}
::xserv::declare closePDF {Close a PDF file} \
  file

::xserv::register viewPDF Acrobat -sig CARO -driver {
  sendOpenEvent noReply $params(xservTarget) $params(file)
}

::xserv::register closePDF Acrobat -sig CARO -driver {
    # Unimplemented
}

::xserv::register viewPDF {Apple Preview} -sig prvw -driver {
  sendOpenEvent noReply $params(xservTarget) $params(file)
}

::xserv::register closePDF {Apple Preview} -sig prvw -driver {
    # Unimplemented
}

::xserv::register viewPDF {Finder choice} -sig MACS -driver {
  sendOpenEvent noReply $params(xservTarget) $params(file)
}

::xserv::register closePDF {Finder choice} -sig MACS -driver {
    # Unimplemented
}

::xserv::register viewPDF {PDFViewer} -driver {
  sendOpenEvent noReply $params(xservTarget) $params(file)
} -mode App

::xserv::register closePDF {PDFViewer} -driver {
    # Unimplemented
} -mode App

::xserv::register viewPDF TeXShop -sig TeXs -driver {
   sendOpenEvent noReply $params(xservTarget) $params(file)
   tclAE::send -r 'TeXs' TeXs Rpdf ---- \
     [tclAE::build::nameObject docu [tclAE::build::TEXT $params(file)]]
} -mode App

::xserv::register closePDF TeXShop -sig TeXs -driver {
    # Unimplemented
}

# Adobe Acrobat "Reader" only supports thist DDE messages:
# CloseAllDocs, DocClose, DocGoTo, DocGoToNameDest,
# DocOpen, FileOpenEx, FilePrintEx, FilePrintSilentEx,
# FilePrintToEx, and AppExit.
::xserv::register viewPDF Acrobat -driver {
    # Ensure it's running
    if {[dde services AcroView Control] eq ""} {
	# It's not running
	exec [windows::AppFor .pdf open] &
    }
    # Now close the window if it's already open (we want to refresh
    # from any changes on disk).
    catch {
	dde execute -async AcroView Control \[DocClose(\"$params(file)\")\]
    }
    # Finally open it.
    dde execute -async AcroView Control \[DocOpen(\"$params(file)\")\]
} -dde AcroView -mode Dde

::xserv::register closePDF Acrobat -driver {
    # Now close the window if it's already open (we want to refresh
    # from any changes on disk).
    catch {
	dde execute -async AcroView Control \[DocClose(\"$params(file)\")\]
    }
} -dde AcroView -mode Dde

::xserv::register viewPDF iTeXMac -sig iTMx -driver {
    lappend cmd [file join $::env(HOME) Library/TeX/bin/iTeXMac]
    lappend cmd display -file $params(file)
    if {$params(line) ne ""} {
	lappend cmd -line $params(line) -column 0
    }
    if {$params(source) ne ""} {
	lappend cmd -source $params(source)
    }
    if {[catch {eval exec $cmd}]} {
	status::msg "[file join $::env(HOME) Library/TeX/bin/iTeXMac] not found"
	exec open -a "iTeXMac" $params(file) 
    }
}

::xserv::register closePDF iTeXMac -sig iTMx -driver {
    # Unimplemented
}

::xserv::register viewPDF TeXniscope -sig MGUB -driver {
    exec open -a TeXniscope $params(file)
    if {$params(line) ne ""} {
	tclAE::send 'MGUB' TeXn Gtli STRT $params(line) \
	  STRS [tclAE::build::TEXT $params(source)] \
	  ---- [tclAE::build::indexObject docu 1]
    }
}

::xserv::register closePDF TeXniscope -sig MGUB -driver {
    # Unimplemented
}

# Scripts which are generally useful.

::xserv::declare unstuff "Unstuff .sit etc. archives" \
  file
::xserv::declare unzip "Unzip .zip, .gz etc archives" \
  file

::xserv::register unstuff "Stuffit Expander" -sig SITx -driver {
    tclAE::send -p $params(xservTarget) aevt odoc \
      ---- [tclAE::build::alis $params(file)]
}

::xserv::register unstuff "Stuffit Expander" -driver {
    return [list $params(xserv-expander) $params(file)]
} -mode Exec -progs expander

::xserv::register unstuff "Winzip" -driver {
    return [list $params(xserv-winzip) -unzip $params(file)]
} -mode Exec -progs winzip

::xserv::register unzip "Stuffit Expander" -sig SITx -driver {
    tclAE::send -p $params(xservTarget) aevt odoc \
      ---- [tclAE::build::alis $params(file)]
}

::xserv::register unzip "Stuffit Expander" -driver {
    return [list $params(xserv-expander) $params(file)]
} -mode Exec -progs expander

::xserv::register unzip "Winzip" -driver {
    return [list $params(xserv-winzip) -unzip $params(file)]
} -mode Exec -progs winzip

array set printPDFAppScripts {
    Acrobat {
	{tclAE::send -p $quotedSig aevt pdoc ---- [tclAE::build::alis $filename]}
    } Preview {
	{tclAE::send -p $quotedSig aevt pdoc ---- [tclAE::build::alis $filename]}
    }
}
array set printPDFAppSignatures {
    Acrobat CARO Preview prvw
}

lunion printPDFSigs CARO prvw

array set printPSAppScripts {
    DropPS {
	{tclAE::send $quotedSig aevt odoc ---- [tclAE::build::alis $filename]}
    } DirectTeXPro {
	{tclAE::build::resultData $quotedSig misc dosc ---- [tclAE::build::TEXT "ProjectMgr -t $dt_TeXFormat	\"[win::Current]\";  directory $dt_TeXProjectDir > CurrDirectory; download $dt_TeXProjectName.ps"]}
    } CMacTeX {
	{tclAE::send -p $quotedSig aevt pdoc ---- [tclAE::build::alis $filename]}
    }
}
array set printPSAppSignatures {
    DropPS D¥PS DirectTeXPro TeX+ CMacTeX PSP*
}

lunion printPSSigs D¥PS TeX+ PSP*

# Replaced with xserv
if {0} {
array set viewPSAppScripts {
    CMacTeX {
	{tclAE::send $quotedSig aevt odoc ---- [tclAE::build::alis $filename]}
    }
    MacGhostview {
	{sendOpenEvent noReply $quotedSig $filename}
    }
    MacGS {
	{tclAE::send $quotedSig aevt odoc ---- [tclAE::build::alis $filename]}
    }
    Tailor {
	{tclAE::send $quotedSig aevt odoc ---- [tclAE::build::alis $filename]}
    }
}
array set viewPSAppSignatures {
    CMacTeX {CMT5 CMTJ TMCJ} MacGhostview JTMC MacGS gsVR Tailor Tail
}

lunion viewPSSigs CMT5 CMTJ TMCJ JMTC gsVR Tail

array set viewPDFAppScripts {
    CMacTeX {
	{tclAE::send $quotedSig aevt odoc ---- [tclAE::build::alis $filename]}
    } MacGS {
	{tclAE::send $quotedSig aevt odoc ---- [tclAE::build::alis $filename]}
    } Acrobat {
	{tclAE::send -p $quotedSig aevt odoc ---- [tclAE::build::alis $filename]}
    } TeXShop {
	{sendOpenEvent noReply $quotedSig $filename}
    } iTeXMac {
	{sendOpenEvent noReply $quotedSig $filename}
    } TeXniscope {
	{sendOpenEvent noReply $quotedSig $filename}
    } Preview {
	{sendOpenEvent noReply $quotedSig $filename}
    }
}

lunion viewPDFSigs gsVR CARO CMTJ TeXs iTMx MGUB prvw

array set viewPDFAppSignatures {
    MacGS gsVR Acrobat CARO CMacTeX CMTJ TeXShop TeXs iTeXMac iTMx
    TeXniscope MGUB Preview prvw
}
}


array set convertPStoPDFAppSignatures {
    MacGS gsVR Distiller DSTL gs CMTA MacPs2PDF TMCA
}

lunion convertPStoPDFSigs gsVR DSTL CMTA TMCA

array set convertPStoPDFAppScripts {
    Distiller {
	{sendOpenEvent noReply $quotedSig $filename}
    }
    MacPs2PDF {
	{sendOpenEvent noReply $quotedSig $filename}
    }
    gs {
	{ set basename [file rootname $filename]
	set cmdline "gs -q -dCompatibilityLevel=1.2 \
	  -dMaxSubsetPct=100 -dNOPAUSE -dBATCH \
	  -sDEVICE=pdfwrite -sOutputFile=$basename.pdf \
	  -c save pop -f [file tail $basename].ps"
	tclAE::send -p $quotedSig CMTX exec ---- [tclAE::build::TEXT $cmdline] \
	  dest [tclAE::build::alis "[file dirname $basename]:"] }
    }
}

namespace eval app {}

# Will be improved when we eventually implement full appspec
# support as discussed on alphad.
proc app::type {sig} {
    if {[file exists $sig]} {
	return "exec"
    } else {
	return "tclae"
    }
}

proc app::ensureRunning {sig {in_front 0}} {
    # See if a process w/ any of the acceptable 
    # sigs already running.
    if {[app::isRunning [list $sig] name]} {
        if {$in_front} {switchTo '$sig'}
        return $name
    }
    if {[catch {app::getNameFromSig $sig} name]} {
        alertnote "Can't find app w/ sig '$sig'.\
          Try rebuilding your desktop or changing your helper apps."
        error "Can't find app w/ sig '$sig'"
    }
    if {![file exists $name]} {
        alertnote "Sig '$sig' is mapped to '$name', which doesn't\
          exist. Try changing your helper apps."
        error "Sig '$sig' is mapped to '$name', which doesn't exist."
    }
    # Launch the app
    if {$in_front} {
        launch -f $name
    } else {
        launch $name
    }
    global alpha::platform alpha::macos
    if {$alpha::platform eq "tk" && $alpha::macos == 2} {
        while {![app::isRunning $sig]} {
            after 1000
        }
    }
    hook::callAll launch $sig
    return $name
}

# Switch to 'sig', launching if necesary
proc app::launchFore {sig} {
    app::ensureRunning $sig 1
}

# Ensure that the app is at least running in the background.
proc app::launchBack {sig} {
    app::ensureRunning $sig 0
}

proc app::launchAnyOfThese {sigs sig \
  {prompt "Please locate the application:"}} {
    app::launchBackSigs $sigs $sig $prompt 0
}
proc app::launchElseTryThese {sigs sig \
  {prompt "Please locate the application:"}} {
    app::launchBackSigs $sigs $sig $prompt 1
}

# Check to see if any of the 'sigs' is running. If so, return its name.
# Otherwise, attempt to launch the file named by 'sig'.
proc app::launchBackSigs {sigs sig \
  {prompt "Please locate the application:"} {running_first 1} } {
    upvar \#0 $sig theSig
    
    if {$running_first || ![info exists theSig] \
      || [catch {app::getNameFromSig [set theSig] 1}]} {
	app::setRunningSig $sigs $sig
	app::getSig $prompt $sig
    }
    return [app::launchBack [set theSig]]
}

# Return all paths which might correspond to the given signature
proc app::getPathsFromSig {sig {typeArr ""}} {
    if {$typeArr != ""} {
	upvar 1 $typeArr type
    }
    
    set paths [list]

    # Check if there is a direct mapping from the signature to
    # a path.  This could be that $sig is a MacOS application
    # signature which is recognised by the system (4 char code),
    # or that it is a full path name of an executable which exists
    # in the filesystem.
    if {![catch [list nameFromAppl $sig] path]} {
	lappend paths $path
	set type($path) "ae"
    }
    
    if {[regsub {Sig$} $sig {} name]} {
	# Check to see if we can find an application on our '$env(PATH)'
	# whose name matches the given signature name reasonably closely.
	global env
	set pathlist {}
	if {[info exists env(PATH)]} {
	    set splitChar "\;"
	    set envpath $env(PATH)
	    if {[string first $splitChar $envpath] == -1} {
		set splitChar ":"
	    }
	    eval lappend pathlist [split $envpath $splitChar]
	}
	global execSearchPath
	if {[info exists execSearchPath]} {
	    eval lappend pathlist [lrange $execSearchPath 0 end]
	}
	foreach pathelt $pathlist {
	    foreach f [glob -nocomplain -dir $pathelt ${name}*] {
		if {[file executable $f]} {
		    if {[lsearch -exact $paths $f] == -1} {
			lappend paths $f
			set type($f) "exec"
		    }
		}
	    }
	}
	
    }
    return $paths
}

proc app::getNameFromSig {sig {ask 0}} {
    global tcl_platform alpha::platform
    if {$tcl_platform(platform) != "macintosh"} {
	if {[file exists $sig]} { return $sig }
    }
    return [nameFromAppl $sig]
}

proc app::getSig {prompt sig} {
    upvar \#0 $sig theSig
    if {[catch {app::getNameFromSig [set theSig] 1}]} {
	if {[info exists theSig]} {
	    set old [set theSig]
	} else {
	    set old ""
	}
	# Sets the global variable '$theSig' through the upvar
	# to 'theSig'
	set theSig [dialog::findApp $sig $prompt $old]
	prefs::modified $sig
    }
}

proc app::setRunningSig {sigs sig} {
    upvar \#0 $sig theSig
    if {[app::isRunning $sigs name s]} {
	if {![info exists theSig] || !($s eq [set theSig])} {
	    set	theSig $s
	    prefs::modified $sig
	}
	return 1
    }
    return 0
}

namespace eval aeapp {}

# Return a list of application names of applications which
# are supported for carrying out the given operation
proc aeapp::supportedFor {op} {
    global ${op}AppSignatures
    array names ${op}AppSignatures
}

# List of all supported operations.
proc aeapp::listSupportedOps {} {
    set res [list]
    foreach v [info globals *AppSignatures] {
	regsub {AppSignatures$} $v "" v
	lappend res $v
    }
    return $res
}

# Return list of signatures which correspond to a given
# application (or all applications if none is given) 
# carrying out a given operation
proc aeapp::supportedSignatures {op args} {
    global ${op}AppSignatures
    switch -- [llength $args] {
	0 {
	    set sigs ""
	    foreach app [array names ${op}AppSignatures] {
		eval lappend sigs [set ${op}AppSignatures($app)]
	    }
	    return $sigs
	}
	1 {
	    return [set ${op}AppSignatures([lindex $args 0])]
	}
	default {
	    error "Should be \"app::supportedSignatures op ?app?\""
	}
    }
}

# Return script-list for the given op/app pair, or throw error
# if no such script exists
proc aeapp::supportedScriptFor {op app} {
    global ${op}AppScripts
    set ${op}AppScripts($app)
}

# Return script-list for the given op/sig pair, or throw error
# if no such script exists
proc aeapp::supportedScriptForSig {op sig} {
    foreach app [aeapp::supportedFor $op] { 
	if {[lsearch -exact [aeapp::supportedSignatures $op $app] $sig] >= 0} {
	    return [aeapp::supportedScriptFor $op $app]
	} 
    }
    return -code error "No script for $op action on $sig"
}

## 
 # -------------------------------------------------------------------------
 # 
 # "app::execute" --
 # 
 #  No description yet available...  See app::runScript, or examples in
 #  postscriptMode.tcl
 #  
 #  Typical use would be:
 #  
 #    app::execute -sigVar viewPSSig -op viewPS -filename image.eps
 #  
 #  This will work in Alpha 7, 8, X and Alphatk.  Or even simpler:
 #  
 #    app::execute -op viewPS -filename image.eps
 #  
 #  (where the code will assume the existence of a global variable
 #  'viewPSSig' and if it isn't set to a reasonable value, will
 #  modify it appropriately).
 # -------------------------------------------------------------------------
 ##
proc app::execute {args} {
    set opts(-runAppInBackground) 0
    set opts(-showLog) 0
    set opts(-flags) ""
    set opts(-depth) ""
    set opts(-isInDir) 0
    set opts(-prompt) ""
    set opts(-filename) ""
    set opts(-dontModifySig) 0
    set opts(-flagsFirst) 0
    
    getOpts {
	-sigVar -op -prompt -filename -runAppInBackground -showLog
	-flags -depth -isInDir -sig -flagsFirst -gotErrorVar
    }

    if {[info exists opts(-gotErrorVar)]} {
	upvar 1 $opts(-gotErrorVar) err
    }
    
    set op $opts(-op)
    set depth $opts(-depth)
    set flags $opts(-flags)
    set showLog $opts(-showLog)
    set runAppInBackground $opts(-runAppInBackground)
    set isInDir $opts(-isInDir)
    set prompt $opts(-prompt)
    if {![string length $prompt]} {
	set prompt $op
    }
    
    set filename $opts(-filename)
    
    if {[info exists opts(-sig)] && [string length $opts(-sig)]} {
	if {[info exists opts(-sigVar)]} {
	    error "Can't use both '-sig' and '-sigVar'"
	}
	set sig $opts(-sig)
    } else {
	if {![info exists opts(-sigVar)]} {
	    # If sigVar is not set, assume it is a global variable which
	    # is the name of the operation with 'Sig' appended, unless
	    # we're told not to modify signatures, in which case we just
	    # use a temporary sig.
	    if {$opts(-dontModifySig)} {
		set opts(-sigVar) tempSig
		set opts(dontModifySig) 0
	    } else {
		set opts(-sigVar) $opts(-op)Sig
	    }
	}
	if {!$opts(-dontModifySig)} {
	    set sigVar $opts(-sigVar)
	    set longPrompt "Please locate a $prompt."
	    set sigs [aeapp::supportedSignatures $op]
	    
	    if {[catch [list app::launchAnyOfThese $sigs $sigVar \
	      $longPrompt] appname]} {
		global errorInfo
		error "Problem in 'app::launchAnyOfThese' :\
		  $appname\n$errorInfo"
	    }
	}
	
	set sig [uplevel \#0 [list set $sigVar]]
	if {$sigVar == "tempSig"} {
	    uplevel \#0 [list unset tempSig]
	}
    }
    
    set quotedSig "'[string trim $sig \']'"
    
    if {!$runAppInBackground} { 
	if {![file exists $sig]} {
            if {[catch {switchTo $quotedSig} err]} {
                # Probably still launching, so we wait
                # for a second
                after 1000
            }
	}
    }  
    
    if {![string length $sig]} {
	return -code error "Empty signature in app::execute"
    }
    
    if {![file exists $sig]} {
	# $sig is a MacOS signature
	if {![catch [list aeapp::supportedScriptForSig $op $sig] script]} {
	    foreach scriptline $script {
		set res [eval $scriptline]
	    }
	    return $res
	} else {
	    beep
	    alertnote "Sorry, no support for your $prompt."
	    return
	}
    } else {
	# '$sig' is a full file path of an executable which we
	# will use 'exec' on.  This is used in Alphatk and Alpha X.
	set stream 1
	# Some apps we never wish to capture stdout/stderr
	global nonInteractiveApps
	if {[info exists nonInteractiveApps]} {
	    if {[lsearch -exact $nonInteractiveApps $op] != -1} {
		set stream 0
		set runAppInBackground 2
	    }
	}
	# We have to copy executables out to a temporary directory if
	# they are in a virtual filesystem.  In the future we might
	# want to ask the user about this, since this could lead to
	# some security problems (exec a file across the internet for
	# example).
	if {[lindex [file system $sig] 0] != "native"} {
	    set newsig [temp::path exec [file tail $sig]]
	    if {![file exists $newsig]} {
		file copy $sig $newsig
	    }
	    set sig $newsig
	}
	if {$stream && $showLog} {
	    global mode
	    set win [new -n "* $op log *" -m $mode -text \
	      "File: $filename\n" -shell 1]
	    if {$filename != ""} {
		global ${op}AppScripts
		if {[info exists ${op}AppScripts(exec)]} {
		    eval [set ${op}AppScripts(exec)]
		}
		set olddir [pwd]
		if {$depth != ""} {
		    if {[is::UnsignedInteger $depth]} {
			set path [file dirname $filename]
			set filename [file tail $filename]
			while {[incr $depth -1] >= 0} {
			    # currently win/unix specific path delimiter
			    set filename "[file tail $path]/$filename"
			    set path [file dirname $path]
			}
			cd $path
		    } else {
			cd $depth
			# $filename is assumed either to be a full
			# path or already backed up to the correct level.
			if {[file::pathStartsWith $filename $depth]} {
			    set filename [string range $filename \
			      [expr {[string length $depth] +1}] end]
			}
		    }
		} else {
		    cd [file dirname $filename]
		    set filename [file tail $filename]
		}
		set filename [eval [list file join] [file split $filename]]
		if {$opts(-flagsFirst)} {
		    app::setupInput "\"$sig\" $flags \"$filename\"" $win
		} else {
		    app::setupInput "\"$sig\" \"$filename\" $flags" $win
		}
		cd $olddir
	    } else {
		if {$opts(-flagsFirst)} {
		    app::setupInput "\"$sig\" $flags \"[file tail $filename]\"" $win
		} else {
		    app::setupInput "\"$sig\" \"[file tail $filename]\" $flags" $win
		}
	    }
	    set res ""
	} else {
	    # We need the output so we actually have to run 'in the foreground'.
	    if {$runAppInBackground == 1} { set runAppInBackground 0 }

	    global tcl_platform env
	    # We can also handle cygwin applications
	    if {$tcl_platform(platform) == "windows" \
	      && ([set cyg [string first "/cygwin/" \
	      [file normalize $sig]]] != -1)} {
		set cygpath \
		  "[string range [file normalize $sig] 0 [expr {$cyg + 7}]]bin"
		set env(PATH) "$env(PATH);$cygpath"
		set env(DISPLAY) "127.0.0.1:0.0"
		set env(XEDITOR) "[app::alphaCommandLine] -cygwin +%l %f"
		set env(EDITOR)  "[app::alphaCommandLine] -cygwin +%l %f"
		set env(TEXEDIT) "[app::alphaCommandLine] -cygwin +%l %f"
	    }
	    if {$filename != ""} {
		set olddir [pwd]
		if {$isInDir} {
		    cd $filename
		    if {$runAppInBackground} {
			set err [catch {eval [list exec $sig] $flags &} res]
		    } else {
			set err [catch {eval [list exec $sig] $flags} res]
		    }
		    cd $olddir
		} else {
		    cd [file dirname $filename]
		    if {$opts(-flagsFirst)} {
			set cmd "[list exec $sig] $flags [list [file tail $filename]]"
		    } else {
			set cmd "[list exec $sig [file tail $filename]] $flags"
		    }
		    if {$runAppInBackground} {
			set err [catch {eval $cmd &} res]
		    } else {
			set err [catch {eval $cmd} res]
		    }
		    cd $olddir
		}
	    } else {
		if {$runAppInBackground} {
		    set err [catch {eval exec [list $sig] $flags &} res]
		} else {
		    set err [catch {eval exec [list $sig] $flags} res]
		}
	    }
	    if {$runAppInBackground} {
		status::msg "Application running in background."
		return
	    }
	    if {($showLog + $err) > 1} {
		global mode
		new -n "* $op log *" -m $mode -info "File: $filename\n$res"
	    }
	    if {$err} {
		beep
		# This used not to throw an error, but for testing
		# purposes we are going to allow an error to be thrown
		# here.
		return -code error -errorinfo $res "Run completed abnormally." 
	    } else {
		status::msg "Run completed successfully."
	    }
	}
	return $res
    }
}

## 
 # -------------------------------------------------------------------------
 # 
 # "app::runScript" --
 # 
 #  Use app::execute instead.  It is more flexible and more
 #  intuitive to use!
 #
 #  Generic run script handler.  Will prompt for the location of your
 #  application if necessary, run in fore/background, show a log of
 #  the result etc.  See latexComm.tcl or diffMode.tcl for examples
 #  of the necessary array entries.
 #  
 #  We extract from 'opp' (see the code for details) a prefix 'op'
 #  
 #  3 variables must be defined: ${op}Sig is a variable whose
 #  value is the signature of the application the user has selected
 #  to carry out this operation (or the path of an executable, if
 #  'exec' is possible), ${op}AppSignatures is an array of all
 #  possible name/signature pairs currently known, and ${op}AppScripts
 #  are the scripts for each of those signatures.
 #  
 #  'flags' are additional flags to pass to the application
 #  'depth' says how many levels of hierarchy Alpha should backup
 #  before calling the application for a given file.  If depth is
 #  not an integer, it can be the actual path prefix up to which
 #  Alpha should backup.  'depth' isn't relevant to all applications
 #  
 #  Modified from original evalTeXScript in latex mode.
 #  
 #  'runAppInBackground' now takes any of three values:
 #  0: run in foreground
 #  1: run in background if possible, but we want to capture the output
 #     of the process, so we may need to run in foreground.
 #  2: force to run in background (and therefore ignore the output of
 #  the process).
 #     
 #  The '1' value is useful for many calls such as diff, cvs, etc in
 #  which on MacOS we will use apple-events and can therefore run in
 #  the background, but on Unix/Windows we can't run with 'exec ... &'
 #  because we won't be able to capture the result.  Since these tools
 #  are command line tools on Unix/Windows, running in the foreground is
 #  effectively running in the background.
 # -------------------------------------------------------------------------
 ##
proc app::runScript {opp prompt filename {runAppInBackground 0} {showLog 0} {flags ""} {depth ""} {isInDir 0}} {
    if {[llength $opp] > 1} {
	set sigIn [lindex $opp 0]
	set op [lindex $opp 1]
	global $sigIn
	set sigVariable "${sigIn}(${op}Sig)"
    } else {
	set op $opp
	global ${op}Sig 
	set sigVariable "${op}Sig"
    }
    
    app::execute -sigVar $sigVariable -op $op -prompt $prompt \
      -filename $filename \
      -runAppInBackground $runAppInBackground -showLog $showLog \
      -flags $flags -depth $depth -isInDir $isInDir
}

proc app::setupInput {cmd win} {
    global tcl_platform
    if {$tcl_platform(platform) == "unix"} {
	updateExecPath
    }
    global catSig
    app::getSig "Please find your 'cat' application" catSig
    insertText -w $win $cmd "\n"
    
    # Ensure we have a native cat.
    set sig $catSig
    if {[lindex [file system $sig] 0] != "native"} {
	set newsig [temp::path exec [file tail $sig]]
	if {![file exists $newsig]} {
	    file copy $sig $newsig
	}
	set sig $newsig
    }
    set pipe [open "| \"$sig\"" r+]
    
    fconfigure $pipe -buffering none
    fileevent $pipe readable [list app::handleErrorInput $win $pipe 1]
    set output [open "|$cmd 2>@ $pipe" r]
    fileevent $output readable \
      [list app::handleStdoutInput $win $output $pipe]
}

proc app::handleErrorInput {w f {err 1}} {
    set data [gets $f]
    if {[string length $data] > 0} {
	goto -w $w [maxPos -w $w]
	insertText -w $w $data "\n"
	update idletasks
    }
}

proc app::handleStdoutInput {w output err} {
    if {[eof $output]} {
	fileevent $output readable ""
	catch {close $output}
	fileevent $err readable ""
	#catch flush $err
	catch {close $err}
	goto -w $w [maxPos -w $w]
	insertText -w $w "\nDone\n"
	goto -w $w [minPos -w $w]
	winReadOnly $w
    }
    # If this fails, the process must have finished, and the pipe closed.
    if {![catch {gets $output} data]} {
	if {[string length $data] > 0} {
	    goto -w $w [maxPos -w $w]
	    insertText -w $w $data "\n"
	    update idletasks
	}
    }
}

proc app::handleInput {w f {err 0}} {
    # Delete handler if input was exhausted.
    if {[eof $f]} {
	fileevent $f readable {}
	close $f
	return
    }

    set data [read $f]

    if {[string length $data] > 0} {
	goto -w $w [maxPos -w $w]
	insertText -w $w $data
    }
}


## 
 # -------------------------------------------------------------------------
 # 
 # "app::isRunning" --
 # 
 #  Is an app with one of the given sigs running.  Set the global $sig
 #  to the name of that thing if it is
 #  
 #  {"Finder" "MACS" 978944 182209 }
 #  
 #  Much improved by Vince to avoid scanning the processes list one at a
 #  time.
 #  
 # -------------------------------------------------------------------------
 ##
proc app::isRunning {sigs {n ""} {s ""}} {
    if {$n != ""} {upvar 1 $n name}
    if {$s != ""} {upvar 1 $s sig}
    global alpha::platform
    if {$alpha::platform == "alpha"} {
	global tcl_platform
	if {$tcl_platform(platform) == "unix"} {
	    # Alpha X on Mac OS X
	    foreach ss $sigs {
		if {[string length $ss] > 4 && [file exists $ss]} {
		    set sig $ss
		    set name $ss
		    return 1
		}
	    }
	}
	foreach ss $sigs {
            # This processes list needs cleaning up in Alpha 8/X core
            # and then documenting appropriately.  Note that on OS X,
            # X11 is recognised by the first element being 'X11' (and
            # the second one '????' !).
	    foreach p [processes] {
		if {([lindex $p 1] eq $ss) || ([lindex $p 1] eq "\"$ss\"") \
                  || ([lindex $p 0] eq $ss)} {
		    set sig $ss
		    set name [lindex $p 0]
		    return 1
		}
	    }
	}
    } else {
	foreach ss $sigs {
	    if {[string length $ss] > 4 && [file exists $ss]} {
		set sig $ss
		set name $ss
		return 1
	    }
	}
	global alpha::windowingsystem
	if {${alpha::windowingsystem} == "aqua"} {
	    # For MacOS X
	    set names {}
	    foreach app [split [exec ps -c -w -w -x] \n] {
		if {[info exists column]} {
		    set name [string range $app $column end]
		    lappend names $name
		} else {
		    set column [string first "COMMAND" $app]
		}
	    }
	    set longnames {}
	    foreach app [split [exec ps -w -w -x] \n] {
		if {[info exists column]} {
		    set name [string range $app $column end]
		    lappend longnames $name
		} else {
		    set column [string first "COMMAND" $app]
		}
	    }
	    foreach ss $sigs {
		if {[lsearch -exact $names $ss] != -1} {
		    set sig $ss
		    set name $ss
		    return 1
		}
		if {[catch {nameFromAppl $ss} app]} {continue}
		set tail [file tail $app]
		if {[file extension $tail] == ".app"} {
		    set tail [file rootname $tail]
		}
		if {[lsearch -exact $names $tail] != -1} {
		    set sig $ss
		    set name $tail
		    return 1
		}
	    }
	    foreach ss $sigs {
		if {[catch {nameFromAppl $ss} app]} {continue}
		foreach long $longnames {
		    if {[string first $app $long] != -1} {
			set sig $ss
			set name [file tail $app]
			if {[file extension $name] == ".app"} {
			    set name [file rootname $name]
			}
			return 1
		    }
		}
	    }
	}
    }
    return 0
}

## 
 # -------------------------------------------------------------------------
 # 
 # "app::registerMultiple" --
 # 
 #  Does the dirty work so a mode can use different icons for its menu
 #  according to which application a particular user has selected for
 #  that mode.  The arguments are as follows:
 #  
 #  type - a prefix such as 'java' which is used to create variables
 #  	   such as 'javaSig' 'javaMenu'
 #  creators - the list of recognised creators (1st is default)
 #  icons - the list of icon resources
 #  menurebuild - the procedure which is used to rebuild the mode menu
 #  
 #  here's an example:
 #  
 #    app::registerMultiple java [list Javc WARZ] \
 #      [list ¥140 ¥285] rebuildJavaMenu
 #      
 #  of course the rebuild procedure must use the correct icon like this:
 #  
 #    proc rebuildJavaMenu {} {
 #	    global javaMenu
 #	    menu -n $javaMenu -p javaMenuProc {
 #	    }
 #    }
 #	
 #  Note: this procedure ensures the menu is created the first time it
 #  is called, but the menu will not be inserted into the menu bar
 #  until 'insertMenu' is called (but this is usually called for you at
 #  the right times by AlphaTcl anyway).
 #	
 # --Version--Author------------------Changes-------------------------------
 #    1.0     <vince@santafe.edu> original
 # -------------------------------------------------------------------------
 ##
proc app::registerMultiple {type creators icons menurebuild} {
    global ${type}Sig multiApp
    if {![info exists ${type}Sig]} {
	set ${type}Sig [lindex $creators 0]
    }
    set multiApp($type) [list $creators $icons $menurebuild]
    app::multiChanged ${type}
    trace add variable ${type}Sig write [list app::multiChanged $type]
}

## 
 # -------------------------------------------------------------------------
 # 
 # "app::multiChanged" --
 # 
 #  Utility procedure used by the above.  No need to call it manually.
 # -------------------------------------------------------------------------
 ##
proc app::multiChanged {type args} {
    global ${type}Menu ${type}Sig multiApp
    set inserted [menu::inserted [set ${type}Menu]]
    if {$inserted} {
	# remove old menu
	removeMenu [set ${type}Menu]
    }

    # update the icon according to signature
    set info $multiApp($type)
    if {[set i [lsearch -exact [lindex $info 0] [set ${type}Sig]]] == -1} {
	set i 0
    }
    set ${type}Menu [lindex [lindex $info 1] $i]

    # rebuild the menu
    eval [lindex $multiApp($type) 2]

    if {$inserted} {
	# insert the new menu
	insertMenu [set ${type}Menu]
    }
}

proc app::alphaCommandLine {} {
    global tcl_platform HOME
    
    switch -- $tcl_platform(platform) {
	"macintosh" {
	    return -code error "No command-line on MacOS classic"
	}
	default {
	    set app [info nameof]
	    set tail [file tail $app]
	    if {[regexp -nocase -- alpha $tail]} {
		# It's an alpha or alphatk executable
		return [list $app]
	    }
	    if {[regexp -nocase -- wish $tail]} {
		# It's wish -- that means alphatk as a script
		catch {set app [file attributes $app -shortname]}
		return [list $app \
		  [file join [file dirname $HOME] alphatk.tcl]]
	    }
	}
    }
}

# ×××× Experimental line-based pipe interaction ×××× #

# Caution: API subject to change.  Code currently shared by
# spellcheck and interactive-TeX users.

proc app::closeLineBasedInteraction {pipe} {
    catch {fileevent $pipe readable ""}
    catch {close $pipe}
}

proc app::setupLineBasedInteraction {args} {
    global tcl_platform
    
    set opts(-callback) ""
    set opts(-read) "gets"
    set opts(-closeproc) ""
    getOpts {-read -callback -closeproc}
    
    if {[llength $args] != 1} {
	return -code error "Bad args.  Should be\
	  'app::setupLineBasedInteraction ?options? spawnCommand'"
    }
    set spawnCmd [lindex $args 0]
    if {$opts(-read) == "gets"} {
	set callback [list ::app::_lineBasedGetsCallback]
    } elseif {$opts(-read) == "read"} {
	set callback [list ::app::_lineBasedReadCallback]
    } else {
	return -code error "Bad -read option, should be 'line' or 'all'"
    }
    if {$tcl_platform(platform) eq "windows"} {
	unset -nocomplain opts(-usebinsh)
    }

    # Have put in an option to use /bin/sh, following Joachim's helpful
    # explanation:
    # 
    # It is because /bin/sh has better stderr and exit code handling
    # facilities than Tcl's [exec].  This is mostly important when tetexComm
    # emulates altpdflatex (Gerben Wierda's script for producing pdf via
    # latex-dvips-gs).  Now altpdflatex has the shortcoming that even if
    # latex exits nonzero, the dvips and gs will run afterwards which is waste
    # of time if the user would rather go back to the source immediately to
    # correct it.  tetexComm catches this exit code by calling tex like this:
    # 
    #     puts $texRun(pipeName) \
    #       "$command $texRun(jobName) && exit 0 || \
    #       echo TeX returned non zero exit status && exit 1"
    # 
    # and then, depending on the setting of TeX::altComm::autoViewWhenNoErrors
    # continues with dvips-ghostscript or lets the user error-browse.  (The line
    # 'TeX returned non zero exit status' is the important her, since the user
    # might also want to use the original altpdflatex, in which case the only
    # evidence for latex's nonzero exit is this message issued by altpdflatex,
    # so the uniform method of determining exit status is to parse the log for
    # this string --- agreed, this is a little backwards, but since altpdflatex
    # hides the exit codes I see no better way of cheating...)
    # 
    # Second, ghostscript sends some messages over stderr which confuse [exec].
    # With the /bin/sh construction, these messages can be redirected using
    # "2>&1 ; exit", and since all this takes place inside /bin/sh, [exec] will
    # not be bothered.

    if {[info exists opts(-usebinsh)]} {
	set pipe [open "|/bin/sh" RDWR]
    } else {
	set pipe [open "|$spawnCmd" RDWR]
    }
    fconfigure $pipe -buffering line -translation auto -blocking 0

    lappend callback $pipe $opts(-closeproc) $opts(-callback)
    fileevent $pipe readable $callback

    if [info exists opts(-usebinsh)] {
	puts $pipe "$spawnCmd ; exit \$?"
    }

    return $pipe
}

proc app::configureLineBasedInteraction {pipe callback} {
    set old [fileevent $pipe readable]
    set new [lreplace $old 3 3 $callback]
    fileevent $pipe readable $new
}

proc app::_lineBasedGetsCallback {pipe closeproc callback} {
    set status [catch {gets $pipe} result]
    eval $callback [list $pipe $status $result]
}

proc app::_lineBasedReadCallback {pipe closeproc callback} {
    set status [catch {read $pipe} result]
    set closed 0
    if {$status || [eof $pipe]} {
	set closed 1
    } elseif {![string length $result]} {
	# There was an empty line.  Check if this is because the shell
	# has died:
	set shPID [pid $pipe]
	set answer [exec ps -p $shPID]
	if {![regexp -- $shPID $answer]} {
	    # The shell has died (probably the process has simply finished)
	    set closed 1
	}
    }
    if {$closed} {
	if {[catch {close $pipe} err]} {
	    status::msg "There was an error when the child process exited: $err"
	}
	if {$closeproc != ""} {
	    eval $closeproc
	}
	return
    }
    eval $callback [list $pipe $status $result]
}

# ===========================================================================
# 
# .