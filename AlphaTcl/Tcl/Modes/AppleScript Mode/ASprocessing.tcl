# -*-Tcl-*- (nowrap)
# 
# File: ASprocessing.tcl
# 	        Created: 2002-03-10 11:54:39
#     Last modification: 2005-09-29 14:12:32
# Author: Bernard Desgraupes
# e-mail: <bdesgraupes@easyconnect.fr>
# Web-page: <http://webperso.easyconnect.fr/bdesgraupes/alpha.html>
# Description:
#     This file is part of the AppleScript mode package. It contains the script
#     processing procs.
#  
# (c) Copyright: Bernard Desgraupes, 2002-2005
#     All rights reserved. This software is free software. See licensing terms
#     in the AppleScript Help file.
#     


set scrp_params(resultwin) "* AppleScript Results *"
set scrp_params(type-0) script
set scrp_params(type-1) context
set scrp_params(uid) 0

hook::register closeHook Scrp::closing Scrp
hook::register saveasHook Scrp::savingas Scrp

namespace eval Scrp {}

# Load the Tclapplescript shared library
set applescriptloaded 0

if {$alpha::macos == 1} {
    # On OS8/9, 'package require Tclapplescript' does not work if there is 
    # a pkgIndex file in {Extensions}:Tool Command Language (bug in Tcl?). 
    # This is a workaround. First find the "Extensions" folder
    set extfold [tclAE::build::resultData 'MACS' core getd rtyp TEXT ---- [tclAE::build::propertyObject extn]]
    # Now load manually the Tclapplescript shared library
    if {[catch {load  [file join $extfold "Tool Command Language" Tclapplescript.shlb]}]} {
	alertnote "I could not find Tclapplescript.shlb in the folder \
	  '[file join $extfold "Tool Command Language"]'. AppleScript mode\
	  will fail to function correctly."
    } else {
	set applescriptloaded 1
    }
    unset extfold
} elseif {$alpha::macos == 2} {
    if {[catch {package require Tclapplescript}]} {
	alertnote "Loading Tclapplescript extension failed. AppleScript mode\
	  will fail to function correctly."
    } else {
	set applescriptloaded 1
    }
} else {
    alertnote "Tclapplescript is useful only on MacOS"
}

if {$applescriptloaded} {
	status::msg "Tclapplescript extension loaded."
} 
unset applescriptloaded


proc Scrp::decompileAScript {} {
    if {[catch {Scrp::selectScript} scriptfile]} return 
    Scrp::decompile $scriptfile
}


proc Scrp::decompile {file {resID 128}} {
    global ScrpmodeVars scrp_params
    set text [Scrp::doDecompile $file]
    set scrp_params(decomp) $file
    set winname "[file root [file tail $file]].scr"
    new -n $winname -mode Scrp
    insertText $text
    set scrp_params([list nam-$winname]) $file
    if {$ScrpmodeVars(includeDescription)} {
	Scrp::insertScriptComment [Scrp::getScriptComment $file]
    } 
    set commentlimits [Scrp::scriptCommentRange]
    set scrp_params([list txt-$winname]) [getText [lindex [lindex $commentlimits 0] 1] [maxPos]]
}


proc Scrp::doDecompile {file {resID 128}} {
    global scrp_params
    if {[catch {set scrID [AppleScript load -rsrcid $resID $file]} res]} {
	Scrp::displayResult "\r$res\r"
	return
    } else {
	# In case there is a compiled script dangling, release it
	Scrp::releaseCompiled $file
	set scrp_params([list id-$file]) $scrID
	set text [encoding convertfrom macRoman [AppleScript decompile $scrID]]
	return $text
    }
}


# This proc takes care of separating the descriptive comment
# from the rest of the script.
proc Scrp::compile {} {
    global ScrpmodeVars scrp_params
    if {[catch {Scrp::makeScriptname [win::Current]} outFile]} {
        return
    } 
    set commentlimits [Scrp::scriptCommentRange]
    set text [getText [lindex [lindex $commentlimits 0] 1] [maxPos]]
    if {![Scrp::doCompile $outFile $text]} {
	status::msg "Compilation aborted"
        return
    } 
    if {$ScrpmodeVars(includeDescription)} {
	Scrp::storeScriptComment [getText [lindex [lindex $commentlimits 1] 0] \
	  [lindex [lindex $commentlimits 1] 1]] $outFile
    } 
    status::msg "Compiled $outFile"
}


# ------------------------------------------------------------------------------------
# There is a bug in the Tclapplescript library (until version 1.1.0): if the flag 
# makeContext is not set and the option -name is not used, no default script ID 
# is returned. So we have to use the option -name and build our own unique ID for 
# each script.
# ------------------------------------------------------------------------------------
proc Scrp::doCompile {outFile text} {
    global ScrpmodeVars scrp_params
    if {![Scrp::checkMustRecompile $outFile $text]} {
	if {[askyesno "This script has already been compiled. Do you want to \
	  recompile it anyway ?"] != "yes"} {
	    return 0
	} 
    }
    return [Scrp::Compilation $outFile $text]
}


proc Scrp::Compilation {outFile text {resID 128}} {
    global ScrpmodeVars scrp_params
    # If there is already a script ID attached to this script (recompiling), use it. 
    # Otherwise create a new one.
    if {[info exists scrp_params([list id-$outFile])]} {
	set scrname $scrp_params([list id-$outFile])
    } else {
	set scrname [Scrp::makeUniqueID]
    }
    
    if {$ScrpmodeVars(augmentContext)} {
	# The makeContext flag must be on.
	if {!$ScrpmodeVars(makeContext)} {
	    switch [alert -t caution -k "Set" -c "Remove" -o "Cancel"\
	      "The flag \"Augment Context\" is set in the AppleScript Flags submenu:\
	      it can be used only when compiling a context. Do you want to set the\
	      \"Make context\" flag to compile a context or remove the \"Augment Context\" flag ?"] {
		"Set" {
		    set ScrpmodeVars(makeContext) 1
		    menu::buildSome appleScriptFlags
		}
		"Remove" {
		    set ScrpmodeVars(augmentContext) 0
		    menu::buildSome appleScriptFlags
		}
		default {
		    return 0
		}
	    }
	}
    }
    
    set inheritFlag $ScrpmodeVars(inheritFromParent)
    if {$ScrpmodeVars(inheritFromParent)} {
	# Are we compiling a context ? Otherwise inheritFromParent is irrelevant.
	if {!$ScrpmodeVars(makeContext)} {
	    switch [alert -t caution -k "Set" -c "Remove" -o "Cancel"\
	      "The flag \"Inherit from parent\" is set in the AppleScript Flags submenu:\
		it can be used only when compiling a context. Do you want to set the\
	      \"Make context\" flag to compile a context or remove the \"Inherit from parent\" flag ?"] {
		"Set" {
		    set ScrpmodeVars(makeContext) 1
		    menu::buildSome appleScriptFlags
		}
		"Remove" {
		    set ScrpmodeVars(inheritFromParent) 0
		    menu::buildSome appleScriptFlags
		    set inheritFlag 0
		}
		default {
		    return 0
		}
	    }
	}
	if {$inheritFlag} {
	    # Is there a parent script selected ?
	    if {$scrp_params(currparent) == ""} {
		alert -t caution -k "OK" -c "" -o "" "No parent context currently selected.\
		  Open the Scripts submenu with the Shift key down to select one\
		  or deselect the flag \"Inherit from parent\" in the AppleScript Flags submenu."
		return 0
	    } 
	    # Parent context must be compiled and loaded. Does the current parent already 
	    # have a script ID ? If not, load it in memory.
	    set parent $scrp_params(currparent)
	    if {[info exists scrp_params([list id-$parent])]} {
		# There is already a script ID.
		set parentID $scrp_params([list id-$parent])
	    } else {
		if {[catch {set parentID [AppleScript load $parent]} res]} {
		    alertnote "Couldn't load parent context '$parent': $res"
		    return 0
		} else {
		    set scrp_params([list id-$parent]) $parentID
		}
	    }
	    # Now we must check that the parent script was compiled as a context. If not 
	    # it will have to be recompiled.
	    if {[lsearch -exact [AppleScript info contexts] $parentID]=="-1"} {
		alertnote "The parent \"[file tail $parent]\" was not compiled as a context.\
		  You must recompile it before with the \"Make context\" flag set."
		Scrp::releaseCompiled $parent
		return 0
	    }
	    # The load command does not run the script automatically. Run it manually:
	    if {[catch {AppleScript run $parentID} res]} {
		Scrp::displayResult "\r$res\r"
		return 0
	    } 
	    
	    set caught [catch {set scrID [AppleScript compile -context $ScrpmodeVars(makeContext) \
	      -name $scrname -parent $parentID -- $text]} res]
	    
	} 
    } 
    if {!$inheritFlag} {
	set caught [catch {set scrID [AppleScript compile -context $ScrpmodeVars(makeContext) \
	  -name $scrname -- $text]} res]
    } 
    if {$caught} {
	# Display the error message if an exception was caught.
	Scrp::displayResult "\r$res\r"
	return 0
    } else {
	AppleScript store -rsrcid $resID $scrID $outFile
	set scrp_params([list id-$outFile]) $scrID
    }
    set scrp_params([list txt-[win::Current]]) $text
    # Change creator to AppleScript Editor's
    tclAE::send -p 'MACS' core setd ---- [tclAE::build::propertyObject fcrt \
      [tclAE::build::nameObject file [tclAE::build::TEXT $outFile]]] data ToyS
    # Update the "Scripts Folder" submenu
    menu::buildScrpMenu ""
    return 1
}


# ------------------------------------------------------------------------------------
# If there is already a script ID corresponding to the current window and if 
# the text of the script has not changed since last compilation, return 0. 
# Otherwise return 1 which means that the script must be recompiled.
# ------------------------------------------------------------------------------------
proc Scrp::checkMustRecompile {outFile text {resID 128}} {
    global ScrpmodeVars scrp_params
    if {![info exists scrp_params([list id-$outFile])]} {
	return 1
    } 
    if {![info exists scrp_params([list txt-[win::Current]])] || \
      [string compare $scrp_params([list txt-[win::Current]]) $text]!=0} {
	return 1
    }
    return 0
}


proc Scrp::execute {} {
    if {[getPos]==[selEnd]} {
	set text [getText [minPos] [maxPos]]
    } else {
	set text [getText [getPos] [selEnd]]
    }
    catch {AppleScript execute -- $text} res
    Scrp::displayResult "\r$res\r"
}


# proc Scrp::doExecute {text} {
#     return [AppleScript execute -- $text]
# }


# ------------------------------------------------------------------------------------
# If compilation fails, return the error message in the result window. 
# If it succeeds, the compiled script is stored in memory but we delete
# it here since we're just doing a syntax check. Don't compile as a context
# otherwise the script gets executed automatically.
# ------------------------------------------------------------------------------------
proc Scrp::checkSyntax {} {
    global ScrpmodeVars scrp_params
    set oldflag $ScrpmodeVars(makeContext)
    if {[getPos]==[selEnd]} {
	set text [getText [minPos] [maxPos]]
    } else {
	set text [getText [getPos] [selEnd]]
    }
    if {[catch {AppleScript compile -name tempname -context 0 -- $text} res]} {
	Scrp::displayResult "\r$res\r"
    } else {
	alert -t note -k ":-)" -c "" -o ""  "Syntax OK !"
	AppleScript delete script tempname
    }
    set ScrpmodeVars(makeContext) $oldflag
}


# Alpha8
proc Scrp::runAScript {} {
    if {[catch {Scrp::selectScript} scrpath]} return 
    Scrp::displayResult "[Scrp::doRunAScript $scrpath]\r"
}


proc Scrp::doRunAScript {file {resID 128}} {
    set scrID [AppleScript load -rsrcid $resID $file]
    set res [AppleScript run $scrID]
    if {[catch {AppleScript delete script $scrID}]} {
        catch {AppleScript delete context $scrID}
    } 
    return $res
}


# ------------------------------------------------------------------------------------
# Run the current window. Check if it is already compiled or if it has to 
# be recompiled.
# ------------------------------------------------------------------------------------
proc Scrp::run {} {
    global ScrpmodeVars scrp_params
    set compileit 0
    if {[catch {Scrp::makeScriptname [win::Current]} outFile]} {
	return
    } 
    set commentlimits [Scrp::scriptCommentRange]
    set text [getText [lindex [lindex $commentlimits 0] 1] [maxPos]]
    if {![info exists scrp_params([list id-$outFile])]} {
	if {[askyesno "This script has not been compiled yet. Compile it now ?"] != "yes"} {
	    return
	} else {
	    set compileit 1
	}
    } else {
	if {[Scrp::checkMustRecompile $outFile $text]} {
	    switch [alert -t caution -k "OK" -c "No" -o "Cancel execution"\
	      "This script has been modified and must be recompiled. \
	      OK to recompile ?"] {
		"OK" {
		    set compileit 1
		}
		"No" {
		    set compileit 0
		}
		default {
		    return
		}
	    }
	}
    }
    if {$compileit && ![Scrp::Compilation $outFile $text]} {
	return
    }
    if {$ScrpmodeVars(runInContext)} {
	if {$scrp_params(currcontext) == ""} {
	    alert -t caution -k "OK" -c "" -o ""  "No context currently selected.\
	      Open the Scripts submenu with the Control key down to select one\
	      or deselect the flag \"Run in context\" in the AppleScript Flags submenu."
	    return
	} 
	# Does the current context already have a script ID ?
	# If not, load it in memory.
	set parent $scrp_params(currcontext)
	if {![info exists scrp_params([list id-$parent])]} {
	    if {[catch {set scrID [AppleScript load $parent]} res]} {
		error "Couldn't load context script $parent"
	    } else {
		set scrp_params([list id-$parent]) $scrID
	    }
	}
	# From the doc: << Unlike with the  "compile  -context"  command,  the  load
	# command does not run these scripts automatically. If you want to set up the
	# handlers contained in the loaded script, you must run it manually. >> So:
	AppleScript run $scrp_params([list id-$parent])
	# Now run in the context
	catch {AppleScript run -context $scrp_params([list id-$parent]) \
	  $scrp_params([list id-$outFile])} res
    } else {
	# No context
	catch {AppleScript run $scrp_params([list id-$outFile])} res
    }
    if {$res!=""} {
	Scrp::displayResult "\r$res\r"
    } 
}


proc Scrp::makeScriptname {name} {
    global ScrpmodeVars scrp_params
    if {[info exists scrp_params([list nam-$name])]} {
	return $scrp_params([list nam-$name])
    } 
    # If the current window does not exist on disk, create the compiled 
    # script in the AppleScripts folder. Otherwise it is created in the 
    # same folder as the current window.
    if {![file exists $name]} {
	Scrp::checkWorkingFolder
	set outDir $ScrpmodeVars(appleScriptsFolder)
    } else {
	set outDir [file dir $name]
    }
    # If the name has an extension and it is not "scpt", or if it has no
    # extension, use "scpt". Otherwise ask the user.
    set ext [file extension $name]
    if {$ext eq ".scpt"} {
	if {![catch {prompt "Name of the compiled script" \
	  "[file root [file tail $name]].ascr"} outFile]} {
	    if {$outFile == ""} {
		error "script name can't be empty"
	    } 
	    if {[file ext $outFile] eq ".scpt"} {
		error "can't use same extension as source script"
	    } 
	} else {
	    error "cancelled"
	}
    } else {
	set outFile "[file root [file tail $name]].scpt"
    }
    # Truncate the name if longer than 32 chars
    if {[string length $outFile]>=32} {
	set outFile [file join [file dir $outFile] \
	  "[string range $tail 0 24]É[string range $tail end-4 end]"]
    } 
    return [set scrp_params([list nam-$name]) [file join $outDir $outFile]]
}


proc Scrp::makeUniqueID {} {
    global scrp_params
    return script[incr scrp_params(uid)]
}


proc Scrp::displayResult {res {encode 1}} {
    global scrp_params
    if {$res=="\r"} {
	return
    } 
    catch {lsearch -exact [winNames] $scrp_params(resultwin)} indx
    if {[expr {$indx > -1}]} {
	bringToFront $scrp_params(resultwin)
    } else {
	new -n $scrp_params(resultwin)
    }
    goto [maxPos]
    if {$encode} {
	insertText [encoding convertfrom macRoman $res]
    } else {
	insertText $res
    }    
}


proc Scrp::releaseCompiled {outFile} {
    global scrp_params
    if {[info exists scrp_params([list id-$outFile])]} {
	switch -regexp -- $scrp_params([list id-$outFile])  {
	    "script.*" {set type script}
	    "OSAScript.*" {set type script}
	    "OSAContext.*" {set type context}
	}
	catch {
	    AppleScript delete $type $scrp_params([list id-$outFile])
	    unset scrp_params([list id-$outFile])
	}
    } 
}


proc Scrp::ClearMemory {} {
    global scrp_params
    foreach type {script context} {
	set contextsList [AppleScript info $type]
	foreach parent $contextsList {
	    # "global" context can't be deleted. Catch to ignore the error.
	    catch {AppleScript delete $type $parent}
	} 
    } 
    # Delete the id-* keys in the array scrp_params
    foreach key [array names scrp_params "\{id-*"] {
        catch {unset scrp_params($key)}
    } 
    status::msg "Scripts cleared from memory."
}


proc Scrp::DumpMemInfo {} {
    global scrp_params
    set keylist [array names scrp_params "\{id-*"]
    if {[llength $keylist]} {
	set result "*** Compiled scripts in memory:\rScript ID\tFile name\r"
	set info ""
	foreach key $keylist {
	    regexp {id-(.*)\}} $key dum scrname
	    lappend info "$scrp_params($key):\t$scrname"
	} 
	append result [join [lsort $info] "\r"]
	append result "\r*** Use \"Clear Memory\" to remove these scripts from memory."
    } else {
	set result "No compiled scripts in memory."
    }
    if {$scrp_params(currcontext)!=""} {
        append result "\rCurrent context\t$scrp_params(currcontext)"
	if {[info exists scrp_params([list id-$scrp_params(currcontext)])]} {
	    append result " (compiled)"
	} else {
	    append result " (not compiled)"
	}
	
    } 
    if {$scrp_params(currparent)!=""} {
        append result "\rCurrent parent\t$scrp_params(currparent)"
	if {[info exists scrp_params([list id-$scrp_params(currparent)])]} {
	    append result " (compiled)"
	} else {
	    append result " (not compiled)"
	}
    } 
    Scrp::displayResult "\r$result\r" 0
}


# # # Script comments handling

proc Scrp::getScriptComment {file {resID 128}} {
    if {[catch {resource open $file} fileResId]} {
	alertnote "Error: $fileResId"
	return
    } 
    if {[catch {resource read TEXT [expr $resID + 1000] $fileResId} text]} {
	set text ""
    } 
    resource close $fileResId
    return $text
}


proc Scrp::storeScriptComment {txt outFile {resID 128}} {
    if {$txt==""} {
        return
    } 
    if {[catch {resource open $outFile w+} fileResId]} {
	alertnote "Error while storing the comment: $fileResId"
	return
    } 
    resource write -id [expr $resID + 1000] -file $fileResId -force TEXT $txt
    resource close $fileResId
}


# ------------------------------------------------------------------------------------
# If the Standard Additions are available, we use NavServices to select 
# exclusively files of type 'osas' or 'APPL'. Otherwise, use the 
# traditional getFile command.
# ------------------------------------------------------------------------------------
proc Scrp::selectScript {} {
    # Dirty trick to check if Standard Additions are there
    set res [tclAE::send -r 'MACS' syso rand]
    if {[regexp errn: $res]} {
	# No Standard Additions. Go the usual way.
	if {[catch {getfile "Select a script file"} path]} {
	    error "User cancelled"
	} 
	return $path
    } else {
	# Standard Additions are there
	switchTo Finder
	set res [tclAE::send -p -r 'MACS' syso stdf rtyp TEXT \
	  prmp [tclAE::build::TEXT "Select a script file"] \
	  ftyp [tclAE::build::List [list osas APPL] -untyped]]
	switchTo 'ALFA'
	if {[regexp errn: $res]} {error "User cancelled"}
	# Result is an alis. Coerce it to text.
	return [tclAE::getKeyData $res ---- TEXT]
    }
}


# ------------------------------------------------------------------------------------
# If the source script window is closed, unset the state variables 
# associated with it and release the compiled script in memory if there
# is one.
# ------------------------------------------------------------------------------------
proc Scrp::closing {win} {
    global scrp_params
    set name [file tail $win]
    if {[info exists scrp_params([list nam-$win])]} {
	set name $scrp_params([list nam-$win])
	unset scrp_params([list nam-$win])
	Scrp::releaseCompiled $name
    } 
    if {[info exists scrp_params([list txt-$win])]} {
	unset scrp_params([list txt-$win])
    } 
}


# ------------------------------------------------------------------------------------
# When saving a window with Save As, unset the associated variables. The script 
# will have to be recompiled.
# ------------------------------------------------------------------------------------
proc Scrp::savingas {oldwin newwin} {
    global scrp_params
    if {[info exists scrp_params([list nam-$oldwin])]} {
	set oldname $scrp_params([list nam-$oldwin])
	unset scrp_params([list nam-$oldwin])
	Scrp::releaseCompiled $oldname
    } 
    if {[info exists scrp_params([list txt-$oldwin])]} {
	unset scrp_params([list txt-$oldwin])
    } 
}



