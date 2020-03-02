## -*-Tcl-*-
 # ###################################################################
 #  TclAE - AppleEvent extension for Tcl
 # 
 #  FILE: "aeom.tcl"
 #                                    created: 11/15/2000 {5:54:56 PM} 
 #                                last update: 03/21/2006 {01:09:08 PM} 
 #  Author: Jonathan Guyer
 #  E-mail: jguyer@his.com
 #    mail: Alpha Cabal
 #     www: http://www.his.com/jguyer/
 #  
 # ========================================================================
 # Copyright (c) 2000-2006 Jonathan Guyer
 # All rights reserved.
 # 
 # Redistribution and use in source and binary forms, with or without
 # modification, are permitted provided that the following conditions are met:
 # 
 #      * Redistributions of source code must retain the above copyright
 #      notice, this list of conditions and the following disclaimer.
 # 
 #      * Redistributions in binary form must reproduce the above copyright
 #      notice, this list of conditions and the following disclaimer in the
 #      documentation and/or other materials provided with the distribution.
 # 
 #      * Neither the name of Alpha Cabal nor the names of its
 #      contributors may be used to endorse or promote products derived from
 #      this software without specific prior written permission.
 # 
 # 
 # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 # AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 # IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 # ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR
 # ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 # DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 # SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 # CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 # LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 # OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 # DAMAGE.
 # ========================================================================
 #  Description: 
 #  
 #  Implementation of Alpha's AppleEvent Object Model.
 # 
 #  History
 # 
 #  modified   by  rev reason
 #  ---------- --- --- -----------
 #  2000-11-15 JEG 1.0 original
 #  2001-12-12 JEG 1.1 removed all use of AESubDescs (for OS X)
 #  2003-03-05 JEG 1.2 removed all Alpha7 code
 #  2003-10-24 JEG 1.3 added open event object selector
 # ###################################################################
 ##

alpha::extension aeom 1.3 {
    tclAE::installEventHandler aevt oapp aeom::handleOpenApp
    tclAE::installEventHandler aevt rapp aeom::handleOpenApp
    tclAE::installEventHandler aevt odoc aeom::handleOpen
    tclAE::installEventHandler aevt pdoc aeom::handlePrint
    tclAE::installEventHandler aevt quit aeom::handleQuit
    
    tclAE::installEventHandler misc dosc aeom::handleDoScript
    
    tclAE::installEventHandler core save aeom::handleSave
    
    tclAE::aete::register aeom::constructAETE
    
    # QA1070
    # OSAXen are not automatically available in OS X unless
    # you preload them with this AppleEvent (which always
    # returns a -1708 error, even when ScriptEditor does it).
    # There's no harm in sending this event in OS 9.
    catch {tclAE::send -r -s ascr gdut}
    
    # When Alpha is reopened (launched again when already running)
    # and has no documents open already, create a new untitled document.
    # This is required by the HIG but can be irritating.
    newPref flag forceDocumentOnReopen 0 global
    alpha::addToPreferencePage Window forceDocumentOnReopen
    
    aeom::accessor::registerAll
} maintainer {
    "Jon Guyer" <jguyer@his.com> <http://www.his.com/jguyer/>
} description {
    Implements Alpha's "AppleEvent Object Model"
} help {
    Implementation of Alpha's AppleEvent Object Model.  This
    package is necessary for Alpha to work properly.
} requirements {
    if {!${alpha::macos}} {
	error "Apple-events are only available on MacOS"
    }
    if {[catch {::package present tclAE}]} {
        ::package require tclAE
    } else {
        eval [::package ifneeded tclAE [::package present tclAE]]
    }
}


namespace eval aeom {}

# ×××× Required AppleEvent Handlers ×××× #

proc aeom::handleOpenApp {theAppleEvent theReplyAE} {
    global forceDocumentOnReopen
    if {$forceDocumentOnReopen && [llength [winNames]] == 0} {
	new
    }        
    if {[llength [winNames]] > 0} {
	refresh
    }
}

proc aeom::handleQuit {theAppleEvent theReplyAE} {
    quit
}
		
proc aeom::handlePrint {theAppleEvent theReplyAE} {
    set pathDesc [tclAE::getKeyDesc $theAppleEvent ----]
    set paths [aeom::_extractPaths $pathDesc]
    tclAE::disposeDesc $pathDesc
    
    foreach path $paths {
        set isOpen [llength [file::hasOpenWindows $path]]
        
        edit -c $path
        catch {::print}
        
        if {!$isOpen} {
            # Window was only opened for the print command
            killWindow
        }
    }
}

proc aeom::THINKaevtodocHook {win index theAppleEvent theReplyAE} {
    # horrible, Horrible, HORRIBLE position specifier
    # designed by THINK, but used by CodeWarrior, OzTeX, Project Builder (maybe others?)
    if {![catch {tclAE::getKeyData $theAppleEvent kpos ????} THINKPosInfo]} {
        binary scan $THINKPosInfo SSIIII THINKshowMsg THINKline \
	  THINKstart THINKend THINKerrmsgH THINKfileModDate

	if {$THINKline >= 0} {
	    set minRowCol [pos::toRowChar [minPos]]
	    incr THINKline [lindex $minRowCol 0]
	    goto [pos::fromRowCol $THINKline 0]
	    nextLineSelect
	    centerRedraw
	    
	    if {${::alpha::macos} == 2} {
		# Workaround for bug 894
		refresh
	    }
	    
	    if {$THINKshowMsg} {
		alert -t stop -c "" -o "" "@#*!% THINK error" \
		  [format "Error message handle address 0x%08X" $THINKerrmsgH]
	    } 
	} else {
	    selectText $THINKstart $THINKend
	    centerRedraw
	    
	    if {${::alpha::macos} == 2} {
		# Workaround for bug 894
		refresh
	    }
	}
    } 
}
    
hook::register aevtodocHook aeom::THINKaevtodocHook 

proc aeom::aevtodocSelectionHook {win index theAppleEvent theReplyAE} {
    if {![catch {tclAE::getKeyDesc $theAppleEvent Sele} selection]} {
	set token [tclAE::resolve $selection]
	if {[tclAE::getDescType $token] != "CHAR"} {
	    error -code -1731
	} 
	eval selectText [tclAE::getData $token]
	if {${::alpha::macos} == 2} {
	    # Workaround for bug 894
	    refresh
	}
    }
}

hook::register aevtodocHook aeom::aevtodocSelectionHook

proc aeom::handleOpen {theAppleEvent theReplyAE} {
    set pathDesc [tclAE::getKeyDesc $theAppleEvent ----]
    set paths [aeom::_extractPaths $pathDesc wasList]
    tclAE::disposeDesc $pathDesc
    
    if {[catch {tclAE::getKeyData $theAppleEvent perm} allWritable]} {
	set allWritable "ask "
    }
    if {[catch {tclAE::getKeyData $theAppleEvent Wrap} allWrapped]} {
	set allWrapped "ask "
    }
    if {[catch {tclAE::getKeyData $theAppleEvent NewW} allNewWins]} {
	set allNewWins "no  "
    }
    if {[catch {tclAE::getKeyData $theAppleEvent Mode} forceMode]} {
	set forceMode ""
    }
    if {[catch {tclAE::getKeyData $theAppleEvent iViz} visibility]} {
	set visibility ""
    }
    
    # Hooked procedures may need to extract information from parameter
    # lists that are synchronized with the file list (see, e.g., ODBEditor)
    if {$wasList} {
	set index 0
    } else {
	set index -1
    }
    
    foreach path $paths {
        set parameters {}
        set wrapit $allWrapped
        set writable $allWritable
        set newWin $allNewWins
        
        set windows [file::hasOpenWindows $path]
        
        if {[llength $windows] \
          &&	$newWin == "ask "} {
            if {[askyesno "Do you want another copy of Ô[file tail $path]Õ?"] == "yes"} {
                set newWin "yes "
            } else {
                set newWin "no  "
            }
        }
        
        if {[llength $windows] \
          &&	$newWin == "no  "} { 
	    set fullname [lindex $windows 0]
            bringToFront $fullname
            unset writable
            unset wrapit
        } else {
	    set fullname "$path[win::CountFor $path]"
	    # Some concern here about whether this initial config
	    # info will be cleaned up if we don't end up in
	    # an ordinary window (winCreatedHook does the cleanup).
	    if {$forceMode ne ""} {
		# Here we need to ensure the mode of the given file
		# is set to the given value
		win::setInitialConfig $fullname \
		  mode $forceMode "command"
	    }
	    if {$visibility ne ""} {
		# Here we need to ensure the mode of the given file
		# is set to the given value
		win::setInitialConfig $fullname \
		  visibility $visibility "command"
	    }
	    
	    openFile $path
	    
            getWinInfo -w $fullname flags
            
            if {[info exists flags(hasSpurious)] && ${flags(hasSpurious)}
            &&	$writable == "ask "} {
                set lockit [alert -t stop -k "Lock File" -c "Allow Save" -o "" \
                  "The file Ô[file tail $path]Õ had inconsistent line terminations. \
                  They have been converted to Carriage Returns." \
                  "Saving this file may damage it if it contains binary data."]
                
                if {$lockit == "Lock File"} {
                    set writable "no  "
                } else {
                    set writable "yes "
                }
            }
            
	    global neverWrapOnOpen
            if {$writable == "no  "} {
                setWinInfo -w $fullname read-only 1
                unset wrapit
	    } elseif {[info exists neverWrapOnOpen] && $neverWrapOnOpen } {
		unset wrapit
            } else {
		if {[catch {win::getInfo $fullname wrap} wrapStyle]} {
		    set wrapStyle [win::getModeVar $fullname lineWrap]
		}
		if {$wrapStyle != 1} {
		    # If the window's mode doesn't want us to wrap the
		    # file, then don't.
		    set wrapit "no  "
		}
		if {[info exists flags(needsWrap)] && $flags(needsWrap) \
		  && $wrapit eq "ask "} {
		    set doWrap [alert -t caution -c "Yes" -k "No" -o "" \
		      "Wrap Ô[file tail $path]Õ?" \
		      "This will remove the paragraph formatting from the file."]
		    
		    if {$doWrap == "Yes"} {
			set wrapit "yes "
		    } else {
			set wrapit "no  "
		    }
		}
                
                if {[info exists flags(needsWrap)] && $flags(needsWrap)
                &&	$wrapit == "yes "} {
                    set savePos [getPos -w $fullname]
                    wrapText -w $fullname \
		      [minPos -w $fullname] [maxPos -w $fullname]
                    goto -w $fullname $savePos
                    setWinInfo -w $fullname needsWrap 0
                }
            }
        }
		
	# Store the fullname in the reply desc
	if {[tclAE::getDescType $theReplyAE] ne "null"} {
	    tclAE::putKeyData $theReplyAE ---- utf8 $fullname
	} 
		
	hook::callAll aevtodocHook "" $fullname $index \
	  $theAppleEvent $theReplyAE
	if {$index >= 0} {
	    incr index
	}
	
        if {[info exists newWin]} {
            lappend parameters NewW $newWin
        }
        if {[info exists writable]} {
            lappend parameters perm $writable
        }
        if {[info exists wrapit]} {
            lappend parameters Wrap $wrapit
        }
        
        lappend sortedPaths(${parameters}) $path
        
    }
    
    # if kAEDirectCall
    # for recording purposes only
    if {[tclAE::getAttributeData $theAppleEvent esrc] == 1} { 
        foreach condition [array names sortedPaths] {
            set pathList [tclAE::createList]
            foreach path [set sortedPaths($condition)] {
                tclAE::putDesc $pathList -1 [tclAE::build::alis $path]
            }
            eval tclAE::send -s -dx aevt odoc ---- [list $pathList] $condition
        }
    } 
       
    return
}


proc aeom::handleAnswer {theAppleEvent theReplyAE} {
    if {![catch {tclAE::getKey $theAppleEvent CERR} errorList]} {
        think::parseCompileErrors $errorList
    } else {
        handleReply [tclAE::print $theAppleEvent]
    }    
}

## 
 # -------------------------------------------------------------------------
 # 
 # "aeom::handleDoScript" --
 # 
 #  The following routine handles the misc dosc event which your application
 #  should support.  How you integrate it into your app depends largely on the
 #  structure of said app.  I have installed it by adding a DoAppleEvent method
 #  to my application subclass which checks each AppleEvent to see if it is
 #  'misc' 'dosc'.  If so, this routine is called. CUSTOM */
 # -------------------------------------------------------------------------
 ##
proc aeom::handleDoScript {theAppleEvent theReplyAE} {
    set scriptDesc [tclAE::getKeyDesc $theAppleEvent ----]
    set script [tclAE::getData $scriptDesc TEXT]
    set type [tclAE::getDescType $scriptDesc]
    tclAE::disposeDesc $scriptDesc
    
    switch -- $type {
        "TEXT" {
            eval $script
        }
        "alis" {
            source $script
        }
        default {
            set errn -1770
            set errs "AEDoScriptHandler: invalid script type '${type}', \
              must be 'alis' or 'TEXT'"
            status::msg $errs
            
            tclAE::putKeyData $theReplyAE errs TEXT $errs
            tclAE::putKeyData $theReplyAE errn long $errn
            
            return $errn
        }      
    }
}

proc aeom::constructAETE {} {
    set suites {}
    set events {}
    set parameters {}
    set enumerations {}
    set enumerators {}
    
    lappend enumerators [list "yes" "yes " "take the action"]
    lappend enumerators [list "no" "no  " "do not take the action"]
    lappend enumerators [list "ask" "ask " "ask the user whether to take the action"]
    
    lappend enumerations [list savo $enumerators]
    
    lappend parameters [list "new window" NewW savo \
      "whether to open file in a new window. (default: no)" 101]
    lappend parameters [list "protecting bad line endings" perm savo \
      "whether to allow saving a file with inconsistent line endings. \
      (default: yes)" 101]
    lappend parameters [list "wrapping" Wrap savo \
      "whether to hard wrap the file. (default: no)" 101]
    lappend parameters [list "in mode" Mode TEXT \
      "language mode in which to open file. (default: determined by file \
      ending, etc.)" 101]
    lappend parameters [list "selecting" Sele insl \
      "position or range to select on opening. (default: none)" 101]

    lappend events [list "open" "open document" aevt odoc \
      {null "" 000} {alis "the file to open" 0001} $parameters]
    
    lappend suites [list "Standard Suite" "Common terms for most applications" \
      CoRe 1 1 $events {} {} $enumerations]
    
    
    set events {}
    set enumerations {}
    set enumerators {}
    
    lappend enumerators [list "Tcl instructions" TEXT "Tcl script code to execute"]
    lappend enumerators [list "alias" alis "alias of a .tcl script file to source"]
    
    lappend enumerations [list ScAl $enumerators]
    
    lappend events [list "DoScript" \
      "Execute a Tcl (Tool Command Language) script" misc dosc \
      {null "" 000} {ScAl "the Tcl script to execute" 0011}]
    
    lappend suites [list "Miscellaneous Standards Suite" \
      "Useful events that aren't in any other suite." \
      misc 1 1 $events {} {} $enumerations]
    
    return [list 1 0 0 0 $suites]
}

proc aeom::_extractPath {fileDesc} {
    set alisDesc [tclAE::coerceDesc $fileDesc alis]
    set path [tclAE::getData $alisDesc TEXT]
    tclAE::disposeDesc $alisDesc    
    
    return $path
}

proc aeom::_extractPaths {files {wasList ""}} {
    
    set paths {}
    
    upvar 1 $wasList listOfPaths
    switch -- [tclAE::getDescType $files] {
        "list" {
            set count [tclAE::countItems $files]
            
            for {set item 0} {$item < $count} {incr item} {
                set fileDesc [tclAE::getNthDesc $files $item]
                
                lappend paths [aeom::_extractPath $fileDesc]
                
                tclAE::disposeDesc $fileDesc
            }
	    
	    set listOfPaths 1
        }
        default {
            lappend paths [aeom::_extractPath $files]
	    
	    set listOfPaths 1
        }
    }
    
    return $paths
}

proc aeom::handleSave {theAppleEvent theReplyAE} {
    set fileList [tclAE::getKeyDesc $theAppleEvent ---- list]
    set num [tclAE::countItems $fileList]
    for {set i 0} {$i < $num} {incr i} {
	if {![catch {tclAE::getNthDesc $fileList $i alis} alis]} {
	    save [tclAE::getData $alis TEXT]
	} else {
	    set token [tclAE::resolve [tclAE::getNthDesc $fileList $i]]
	    if {[tclAE::getDescType $token] != "WIND"} {
	        error -code -1731
	    } 
	    save [tclAE::getData $token ????]
	}
    }
}

# ×××× Object Accessors ×××× #

namespace eval aeom::accessor {}

proc aeom::accessor::registerAll {} {
    tclAE::installObjectAccessor cwin null aeom::accessor::cwin<null
    tclAE::installObjectAccessor docu null aeom::accessor::cwin<null
    tclAE::installObjectAccessor cwor WIND aeom::accessor::cwor<WIND       
    tclAE::installObjectAccessor cwor CHAR aeom::accessor::cwor<CHAR 
    tclAE::installObjectAccessor cwor null aeom::accessor::cwor<null 
    tclAE::installObjectAccessor clin null aeom::accessor::clin<null       
    tclAE::installObjectAccessor clin WIND aeom::accessor::clin<WIND       
}

# tclAE::resolve [tclAE::build::indexObject cwor 1 [tclAE::build::winByName aeom.tcl]]

proc aeom::accessor::_getBoundaries {rangeDesc} {
    # is it really necessary to coerce this? gross
    set rangeRecord [tclAE::coerceDesc $rangeDesc reco]

    set startDesc [tclAE::getKeyDesc $rangeRecord star]
    set startItem [tclAE::resolve $startDesc]

    set stopDesc [tclAE::getKeyDesc $rangeRecord stop]
    set stopItem [tclAE::resolve $stopDesc]

    return [list $startItem $stopItem]
}

proc aeom::accessor::_rang {win keyData theToken} {
    set boundaries [aeom::accessor::_getBoundaries $keyData]
    
    set startItem [lindex $boundaries 0]
    set stopItem [lindex $boundaries 1]
    
    if {[tclAE::getDescType $startItem] ne "CHAR"
    ||	[tclAE::getDescType $stopItem] ne "CHAR"} {
	error::throwOSErr -1720
    }
    
    set startData [tclAE::getData $startItem]
    set stopData [tclAE::getData $stopItem]
    
    if {$win ne [lindex $startData 1]
    ||  $win ne [lindex $stopData 1]} {
	# range endpoints must be in same window
	error::throwOSErr -1720
    } 
    
    set start [lindex $startData 2]
    if {[pos::compare -w $win $start > [lindex $stopData 2]]} {
	set start [lindex $stopData 2]
    } 
    
    set stop [lindex $stopData 3]
    if {[pos::compare -w $win $stop < [lindex $startData 3]]} {
	set start [lindex $startData 3]
    } 
    
    tclAE::replaceDescData $theToken CHAR [list -w $win $start $stop]
}

#-------------------------------- windows --------------------------------#

proc aeom::accessor::cwin<null {desiredClass containerToken containerClass keyForm keyData theToken} {
    set wins [winNames]
    
    switch -- $keyForm {
        "name" {
            set winNum [lsearch $wins [tclAE::getData $keyData TEXT]]
            if {$winNum < 0} {
                error::throwOSErr Ð1728
            } 
        }
        "indx" {
            # absolute positions are 1-based
            set winNum [expr {[tclAE::getData $keyData long] - 1}]
            
            if {($winNum >= [llength $wins]) || ($winNum < 0)} {
                error::throwOSErr Ð1728
            }
        }
        default {
            error::throwOSErr Ð1708
        }
    }
    tclAE::replaceDescData $theToken WIND [lindex $wins $winNum]
}

#--------------------------------- words ---------------------------------#

proc aeom::accessor::_cwor {win start stop keyForm keyData theToken} {
    set wordBreak [win::getInfo $win wordbreak]
    
    switch -- $keyForm {
      "indx" {
        set index [tclAE::getData $keyData long]
        if {$index > 0} {
            # forward search from start of range
            for {} {$index > 0} {incr index -1} {
                if {[catch {search -w $win -s -f 1 -r 1 -l $stop -- "$wordBreak" $start} word]} {
                    # errAENoSuchObject
                    error::throwOSErr -1728
                }
                set start [lindex $word 1]
            }
            set start [lindex $word 0]
            set stop [lindex $word 1]
        } else {
            # backward search from end of range
            for {} {$index < 0} {incr index} {
                if {[catch {search -w $win -s -f 0 -r 1 -l $start -- "$wordBreak" [pos::math $stop - 1]} word]} {
                    # errAENoSuchObject
                    error::throwOSErr -1728
                }
                set stop [lindex $word 0]
            }
            set start [pos::math [lindex $word 0] + 1]
            set stop [lindex $word 1]
        }
	
	tclAE::replaceDescData $theToken CHAR [list -w $win $start $stop]
      }
      "rang" {
	  aeom::accessor::_rang $win $keyData $theToken
      }
      "rele" {
        
      }
      default {
          error::throwOSErr Ð1708
      }
    }
    
}

proc aeom::accessor::cwor<WIND {desiredClass containerToken containerClass keyForm keyData theToken} {
    set win [tclAE::getData $containerToken ****]
    set start [minPos -w $win]
    set stop [maxPos -w $win]
    
    aeom::accessor::_cwor $win $start $stop $keyForm $keyData $theToken
}

proc aeom::accessor::cwor<CHAR {desiredClass containerToken containerClass keyForm keyData theToken} {
    set charData [tclAE::getData $containerToken ****]
    set win [lindex $charData 0]
    set start [lindex $charData 1]
    set stop [lindex $charData 2]
    
    aeom::accessor::_cwor $win $start $stop $keyForm $keyData $theToken
}

proc aeom::accessor::cwor<null {desiredClass containerToken containerClass keyForm keyData theToken} {
    set win [win::Current]
    set start [minPos -w $win]
    set stop [maxPos -w $win]
    
    aeom::accessor::_cwor $win $start $stop $keyForm $keyData $theToken
}

#--------------------------------- lines ---------------------------------#

proc aeom::accessor::_clin {win keyForm keyData theToken} {
    switch -- $keyForm {
      "indx" {
	set index [tclAE::getData $keyData long]
	if {$index > 0} {
	    set start [pos::fromRowCol -w $win $index 0]
	    set stop [pos::nextLineStart -w $win $start]
	} else {
	    # count lines from end of range
	    set endRowCol [pos::toRowCol -w $win [maxPos -w $win]]
	    set start [pos::fromRowCol -w $win [expr [lindex $endRowCol 0] + $index] 0]
	    set stop [pos::nextLineStart -w $win $start]
	}
	tclAE::replaceDescData $theToken CHAR [list -w $win $start $stop]
      }
      "rang" {
	  aeom::accessor::_rang $win $keyData $theToken
      }
      "rele" {
	
      }
      default {
	  error::throwOSErr Ð1708
      }
    }
}

proc aeom::accessor::clin<null {desiredClass containerToken containerClass keyForm keyData theToken} {
    set win [win::Current]
    
    aeom::accessor::_clin $win $keyForm $keyData $theToken
}

proc aeom::accessor::clin<WIND {desiredClass containerToken containerClass keyForm keyData theToken} {
    set win [tclAE::getData $containerToken ****]
    
    aeom::accessor::_clin $win $keyForm $keyData $theToken
}

# ===========================================================================
# 
# .