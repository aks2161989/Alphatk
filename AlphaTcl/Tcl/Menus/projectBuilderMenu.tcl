## -*-Tcl-*-
 # ###################################################################
 #  AlphaTcl - an extension package for Alpha
 # 
 #  FILE: "projectBuilder.tcl"
 #                                    created: 3/14/03 {11:14:26 PM} 
 #                                last update: 04/28/2004 {07:07:37 PM} 
 #  Author: Jonathan Guyer
 #  E-mail: jguyer@his.com
 #    mail: Alpha Cabal
 #     www: http://alphatcl.sourceforge.net
 #  
 # ========================================================================
 # Copyright (c) 2003-2004 Jonathan Guyer
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
 # See the file "license.terms" for information on usage and  redistribution 
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 #  
 #  Description: 
 # 
 #  History
 # 
 #  modified   by  rev reason
 #  ---------- --- --- -----------
 #  2003-03-14 JEG 1.0 original
 # ###################################################################
 ##

alpha::menu projectBuilderMenu 0.1 "C C++ Objc Java Pasc Fort HTML" "PB" {

} {
    tclAE::installEventHandler "KAHL" "MOD " projectBuilder::getModified
    menu::buildProc projectBuilderMenu projectBuilder::buildMenu
    menu::buildSome projectBuilderMenu
} {
    tclAE::removeEventHandler "KAHL" "MOD " projectBuilder::getModified
} uninstall {
    this-file
} maintainer {
    "Jon Guyer" <jguyer@his.com> <http://www.his.com/jguyer/>
} description {
    Uses Alpha as an external editor for Apple's Project Builder IDE
} help {
    This menu allows Alpha to act as an external editor for
    Apple's Project Builder IDE.
} requirements {
    # PB only exists on Mac OS X, but /should/ be able to talk
    # to Alpha8 in Classic
#     if {${alpha::macos} != 2} {
# 	error "Project Builder integration is only supported on Mac OS X"
#     }

    ::package require tclAE
    alpha::package require aeom 1.0a5
}

namespace eval projectBuilder {}

proc projectBuilder::buildMenu {} {
    global projectBuilderMenu

    set menuList [list \
      "(nothing yet" \
      ]
    return [list build $menuList projectBuilder::menuProc "" $projectBuilderMenu]
}

# 	HandleModified
# 	
# 	The THINK Modified event is sent when the IDE needs to know which
# 	files have been modified and when they've been modified.  Send back
# 	a list of fssMod structs in the reply event, as follows:

# 	struct {
# 		FSSpec 	fss;	//	the file spec
# 		long	when;	//	the time the file was last modified
# 		short	saved;	//	is the file being saved now (set to zero in this handler)
# 	} fssMod;
# 	
proc projectBuilder::getModified {theAppleEvent theReplyAE} {
    set modList [tclAE::createList]
    
    foreach win [winNames] path [winNames -fnocount] {
        getWinInfo -w $win winfo
	if {$winfo(dirty)} {
	    set fssDesc [tclAE::coerceData TEXT $path fss]
	    set fss [tclAE::getData $fssDesc ????]
	    
	    set fssMod [binary format a*IS \
	      [tclAE::getData $fssDesc ????] \
	      [cvttime -utm [now]] \
	      0 \
	      ]
	    
	    set modDesc [tclAE::createDesc ???? $fssMod]
	    tclAE::setDescType $modDesc TEXT
	    
	    tclAE::putDesc $modList -1 $modDesc
	} 
    } 
    
    tclAE::putKeyDesc $theReplyAE ---- $modList

    return
}


