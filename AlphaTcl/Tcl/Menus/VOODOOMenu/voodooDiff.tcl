## -*-Tcl-*-
 # ###################################################################
 #  AlphaVOODOO - integrates Alpha with VOODOO
 # 
 #  FILE: "voodooDiff.tcl"
 #                                    created: 7/8/97 {10:02:32 pm} 
 #                                last update: 2005-08-23 12:08:35 
 #                                    version: 2.0
 #  Author: Jonathan Guyer
 #  E-mail: <jguyer@his.com>
 #     www: <http://www.his.com/jguyer/>
 #  
 #  Copyright (C) 1998-2001  Jonathan Guyer
 #  
 #  This program is free software; you can redistribute it and/or modify
 #  it under the terms of the GNU General Public License as published by
 #  the Free Software Foundation; either version 2 of the License, or
 #  (at your option) any later version.
 #  
 #  This program is distributed in the hope that it will be useful,
 #  but WITHOUT ANY WARRANTY; without even the implied warranty of
 #  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 #  GNU General Public License for more details.
 #  
 #  You should have received a copy of the GNU General Public License
 #  along with this program; if not, write to the Free Software
 #  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 #  
 # ###################################################################
 ##

namespace eval voodoo {}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::handleDiffReply" --
 # 
 #  Queued replies are passed through AEPrint and then to this routine.
 #  Return 1 if we handled it.  We must call 'currentReplyHandler thisproc'
 #  before each apple-event we send so Alpha knows we're the first in
 #  the priority queue for replies.
 # -------------------------------------------------------------------------
 ##
proc voodoo::handleDiffReply {rep} {
	# Something's goofy with the
	# form of rep as returned by AEPrint
	
	regsub {\\\{} $rep "{" rep
	regsub {\\\}} $rep "}" rep
	
	voodoo::try {
		# parse the event and display any errors
		set eventDesc [tclAE::parse::event $rep]
		
		# get the direct object
        set changed [tclAE::getKeyData $eventDesc "----" bool]
        
		tclAE::disposeDesc $eventDesc
        
		if {!$changed} {
			alertnote "“[lindex [winNames] 0]” has not changed since it was archived"
		} 
		# else 
		#	VOODOO will call voodoo::displayDiff if there are changes
        
	} -preError {
        {AppleEvent -1700 *} {
            # direct object's not a boolean, so this event isn't for us
            return 0
        }
        {AppleEvent -1719 *} {
            # direct object's missing, so this event isn't for us
            return 0
        }
        default	{
            error::rethrow
        }
    }
	
	# Event handled, either by alerting to no differences, 
	# or displaying an error message
	return 1
}

# This is for the "DoScript" interface between VOODOO and Alpha.
# To be replaced by the «event CompComp» interface below? 
# 
# No.

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::compareFiles" --
 # 
 #  Compares two files given as arguments
 # 
 # --Version--Author------------------Changes-------------------------------
 #    1.0     <j-guyer@nwu.edu> Derived from compareFiles
 #    1.1     JK (Aug2005)      A jour with Diff mode.
 #                              (Caveat: I haven't tested this.)
 # -------------------------------------------------------------------------
 ##
proc voodoo::compareFiles {{fileOne ""} {fileTwo ""}} {
    variable diffData
    if {$fileOne eq ""} {
	set fileOne [getfile "Select your first file:"]
    }
    if {$fileTwo eq ""} {
	set fileTwo [getfile "Select your second file:"]
    }
    set diffData(file1) $fileOne
    set diffData(file2) $fileTwo
    set diffData(result) [::xserv::invoke Diff \
      -oldfile $fileOne \
      -newfile $fileTwo \
      -options [array get ::DiffmodeVars] \
      ]
    return [string length $diffData(result)]
}

proc voodoo::displayDiff {} {
    variable diffData
    ::Diff::diffWindow "* VOODOO Comparison *" \
      $diffData(result) $diffData(file1) $diffData(file2) "files" 
    unset diffData
}
