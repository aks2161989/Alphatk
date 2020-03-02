# -*-Tcl-*- (nowrap)
# 
# File: codeWarriorCompile.tcl
# 							Last modification : 2003-11-02 09:13:14
# 
# Description : this file is part of the CodeWarrior Menu for Alpha.
# It contains the procedures related to building.

proc codeWarriorCompile.tcl {} {}

namespace eval cw {}


proc cw::touch {} {
	cw::errors [cw::modified [win::Current]]
}


proc cw::checkSyntax {} {
	eval cw::doEvent [list Chek ---- [tclAE::build::alis [win::StripCount [win::Current]]] Errs 1]
}


proc cw::preprocess {} {
	global cw_params
	eval cw::doEvent [list PreP ---- [tclAE::build::alis [win::StripCount [win::Current]]] Errs 1]
	switchTo $cw_params(cwsig)
}


proc cw::precompile {} {
	if {[catch {putfile "Save precompiled file as"} precompFile]} {return} 
	set fid [open $precompFile w+]
	close $fid
	eval cw::doEvent [list PreC ---- [tclAE::build::alis [win::StripCount [win::Current]]] \
	  Errs 1 Targ [tclAE::build::alis $precompFile]]
}


proc cw::compile {} {
	global cw_params ALPHA cwmodeVars
	if {$cwmodeVars(saveOpenFilesBeforeBuild)} {save} 
	eval cw::doEvent [list Comp ---- [tclAE::build::alis [win::StripCount [win::Current]]] Errs 1]
}


proc cw::compileFiles {} {
	global cwmodeVars
	if {$cwmodeVars(saveOpenFilesBeforeBuild)} {saveAll} 
	set files {}
	set wins [winNames -f]
	set md [win::getMode [lindex $wins 0]]
	foreach w $wins {
		if {$md eq [win::getMode $w]} {
			lappend files $w
		}
	}
	eval cw::doEvent [list Comp ---- [tclAE::build::alises $files] Errs 1]
}


proc cw::make {} {
	eval cw::doEvent [list Make Errs 1]
}


proc cw::update {} {
	eval cw::doEvent [list UpdP Errs 1]
}


proc cw::debug {} {
	eval cw::doEvent [list RunP Errs 1 DeBg 1]
}


proc cw::run {} {
	eval cw::doEvent [list RunP Errs 1 DeBg 0]
}


proc cw::doEvent {args} {
	global cw_params ALPHA
	if {![cw::isProjectOpen]} {return} 
	cw::killErrors
	cw::switchIfNecessary
	set res [eval tclAE::send -t 500000 -r $cw_params(cwsig) $cw_params(cwclass) $args]
	cw::errors $res
	switchTo $ALPHA
}


proc cw::modified {name} { 
	global cw_params cwmodeVars
	if {!$cwmodeVars(touchWhenSaving)} {return} 
	if {![cw::checkRunning 0]} {return} 
	return [tclAE::send -t 500000 -r $cw_params(cwsig) $cw_params(cwclass) "Toch" \
	  ---- [tclAE::build::alis [win::StripCount $name]]]
}


proc cw::removeObjectCode {} {
	global cw_params
	if {![cw::isProjectOpen]} {return} 
	tclAE::send -t 500000 $cw_params(cwsig) $cw_params(cwclass) RemB
	switchTo $cw_params(cwsig)
}


# Reset the file paths for the current project. This forces the compiler
# to search for the files (in the default paths and user-specified access
# paths) the next time it needs to access the files.
proc cw::resetProjectEntryPaths {} {
	global cw_params
	if {![cw::isProjectOpen]} {return} 
	tclAE::send -t 500000 $cw_params(cwsig) $cw_params(cwclass) ReFP
}


proc cw::exportProject {} {
	global cw_params 
	if {![cw::versionGreaterThanFour]} {
		alertnote "This version of CodeWarrior is too old. No export feature."
		return
	}
	if {![cw::isProjectOpen]} {return} 	
	set expfile [file::unixPathToFinder "[cw::currentProject].xml"]
	set res [tclAE::send -t 500000 -r $cw_params(cwsig) CWIE EXPT ---- \
	  [tclAE::build::indexObject PRJD 1] kfil [tclAE::build::TEXT $expfile]]
	cw::errors $res
}


# The CWIE/DASM event expects a target file designated by index, not by name.
proc cw::disassemble {} {
	global cw_params
	watchCursor
	status::msg "Disassembling. Please wait…"
	set fname [win::StripCount [win::Current]]
	if {![cw::isInProject $fname 0]} {return} 
	set targetobj [tclAE::build::nameObject TRGT [tclAE::build::TEXT [cw::currentTarget]] \
	  [tclAE::build::indexObject PRJD 1]]
	set scrfList [cw::propertyList Path $targetobj "source files"]
	set fileidx [cw::findFileIndex $scrfList $fname]
	if {$fileidx} {
		switchTo $cw_params(cwsig)
		set res [tclAE::send -t 500000 $cw_params(cwsig) CWIE DASM \
		  ---- [tclAE::build::indexObject SRCF $fileidx $targetobj]]
		cw::errors $res
	} else {
		status::msg "Couldn't find file index"
	}
}


# CW's disassemble command opens a window in CW but does not create a file on
# disk, so we must:
# - create the file
# - send a close and save event to CW's output window
# - open the file in Alpha.  
# This proc is available by holding the option key down when opening 
# CodeWarrior "Compiling" submenu in Alpha.
proc cw::editDumpInAlpha {} {
	global cw_params
	if {![cw::versionGreaterThanFour]} {
		alertnote "Item not available. This version of CodeWarrior is too old."
		return
	}
	set fname [win::StripCount [win::Current]]
	if {![cw::isInProject $fname 0]} {return} 
	set fid [open "$fname.dump" w+]
	close $fid
	catch {tclAE::send -t 500000 -r $cw_params(cwsig) core close ---- \
	  [tclAE::build::winByName [file tail "$fname.dump"]] \
	  savo "yes " kfil [tclAE::build::alis "$fname.dump"]} res
	if {![cw::checkErrorInReply $res]} {
		edit -c "$fname.dump"
	} 
}


