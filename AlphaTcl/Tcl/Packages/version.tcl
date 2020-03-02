## -*-Tcl-*- (install)
 # ###################################################################
 #  FILE: "version.tcl"
 #                                    created: 7/23/97 {12:24:48 am} 
 #                                last update: 01/29/2006 {03:13:40 PM} 
 #                                    version: 2.0
 #  Author: Jonathan Guyer
 #  E-mail: jguyer@his.com
 #    mail: Alpha Cabal
 #          POMODORO no seisan
 #     www: http://www.his.com/jguyer/
 #  
 # ========================================================================
 #               Copyright (c) 1997-2006 Jonathan Guyer
 # ========================================================================
 # This program is free software; you can redistribute it and/or modify
 # it under the terms of the GNU General Public License as published by
 # the Free Software Foundation; either version 2 of the License, or
 # (at your option) any later version.
 # 
 # This program is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 # GNU General Public License for more details.
 # 
 # You should have received a copy of the GNU General Public License
 # along with this program; if not, write to the Free Software
 # Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA. 
 # ========================================================================
 #  Description: 
 #  
 # This package obtains and formats the 'vers' resource code of the specified
 # file.  If the file has no 'vers' resource, the error -1728 from the Finder
 # will be thrown for you to catch as you see fit.  If the file's 'vers'
 # resource is wrong, e.g. Alpha 6.52 seems to think that it's version
 # 6.5.0b1, there's really nothing I can do about that 8^).  
 # 
 # 
 # To check if Alpha is modern enough for your mode, you could call
 # 
 # proc test {} {
 #     global HOME ALPHA
 #     if {[file::version "$HOME:$ALPHA"] < [file::stringToVersion "6.52"]} {
 #         error "A newer version of Alpha is required to run this package"
 #     } 
 # }
 # 
 # ...of course, since Alpha has the wrong 'vers' resource, this test would 
 # fail, but you get the idea.
 # ###################################################################
 ##

alpha::extension version 2.0.4 {
} maintainer {
    "Jon Guyer" <jguyer@his.com> <http://www.his.com/jguyer/>
} requirements {
    ::package require tclAE
} description {
    Provides utilities to obtain and format the 'vers' resource code of the
    specified file
} help {
    This auto-loading extension provides utilities to obtain and format the
    'vers' resource code of the specified file.  If the file has no 'vers'
    resource, the error -1728 from the Finder will be thrown for you to catch
    as you see fit.  If the file's 'vers' resource is wrong, e.g. Alpha 6.52
    seems to think that it's version 6.5.0b1, there's really nothing I can do
    about that 8^).
    
    See the "version.tcl" file for more information about the procs that are
    available and what they do.
}
    

tclAE::installCoercionHandler "vers" "VERS" version::vers>VERS
tclAE::installCoercionHandler "TEXT" "VERS" version::TEXT>VERS
tclAE::installCoercionHandler "utxt" "VERS" version::utxt>VERS

namespace eval file {}

## 
 # -------------------------------------------------------------------------
 # 
 # "file::version" --
 # 
 #  Obtains the 'vers' resource, if any, from $file.  Supply either a -path
 #  or -creator, but not both.  If -creator option is supplied the file
 #  creator is expected (of an application).  If -all option is supplied,
 #  returns the full list of {versionCode versionString versionText},
 #  otherwise just versionCode is returned.
 #  -------------------------------------------------------------------------
 ##
proc file::version {args} {
    set opts(-all) 0
    
    getOpts {creator path}
    
    if {[info exists opts(-creator)]} {
	if {[info exists opts(-path)]} {
	    error "file::version error: -creator and -path options are incompatible."
	} else {
	    set from "obj {want:type(file), seld:$opts(-creator), \
	      form:fcrt, from:'null'()}"
	}
    } elseif {[info exists opts(-path)]} {
	set from [tclAE::build::filename $opts(-path)]
    } else {
	error "file::version error: Either -creator or -path must be supplied."
    }
    
    if {[catch {tclAE::build::resultDesc 'MACS' core getd ---- \
	  [tclAE::build::propertyObject vers $from]} versDesc]
    &&  [info exists opts(-creator)]} {
	# Mac OS X can't handle this request by creator
	# so look it up by path

	return [file::version -path [nameFromAppl $opts(-creator)]]
    } else {
	return [tclAE::getData $versDesc VERS]
    }
}

namespace eval version {}

## 
 # -------------------------------------------------------------------------
 # 
 # "version::codeToString" --
 # 
 #  Converts the version code, as returned by file::version, into a 
 #  human-readable string, e.g., file::versionToString "6506002" 
 #  will return "6.5.0b2"
 # 
 #  $version must consist of 8 hexadecimal digits in 'vers' resource format
 # -------------------------------------------------------------------------
 ##
proc version::codeToString {version {nosubsubversion 0}} {
    binary scan $version cccc major minorMinor releaseCode nonRelease
    
    set major [expr {($major + 0x100) % 0x100}]
    set minorMinor [expr {($minorMinor + 0x100) % 0x100}]
    set nonRelease [expr {($nonRelease + 0x100) % 0x100}]
    
    set major [expr {($major / 0x10) * 10 + ($major % 0x10)}]
    set minor [expr {($minorMinor / 0x10) * 10}]
    set subversion [expr {$minorMinor % 0x10}]
    
    set vers ${major}.${minor}
	
    if {$subversion > 0} {
        # some pathological programs ;^) mush the subversion 
        # and subsubversion together
        if {!$nosubsubversion} {
            append vers "."
        }
        
        # subsubversion, or second digit of subversion
        append vers $subversion
    }
	
    switch -- $releaseCode {
	32 {append vers "d"}
	64 {append vers "a"}
	96 {append vers "b"}
    }
    
    if {$nonRelease} {
	if {$releaseCode == 0x80} {
	    append vers "f"
	}
	append vers $nonRelease
    }
    
    return $vers
}

## 
 # -------------------------------------------------------------------------
 # 
 # "version::stringToCode" --
 # 
 #  Converts a version string into a version code, suitable for ordinal 
 #  comparisons, e.g., file::stringToVersion "6.5.0b2" will return "6506002"
 # 
 #  Versions may be formatted as "6.52" or "6.5.2", but not "6.52.1" 
 #  ("6.52.0" slides by on a technicality).
 # 
 #  All fields, except the major version, are optional. 
 # -------------------------------------------------------------------------
 ##
proc version::stringToCode {vers} {
    regexp {^([0-9]+)(\.([0-9]+)(\.([0-9]))?)?(([a-zA-Z]+)([0-9]*))?} $vers \
      whole version blah subversion blah subsubversion blah releaseCode nonRelease
    
    if {$version == ""} {set version 0}
    if {$subversion == ""} {set subversion 0}
    if {$subsubversion == ""} {set subsubversion 0}
    if {$nonRelease == ""} {set nonRelease 0}
    
    # This is to put versions like '6.52' in the 'correct' form
    if {[string length $subversion] == 2
    &&  !$subsubversion} {
	set subsubversion [string index $subversion 1]
	set subversion [string index $subversion 0]
    } 
    
    if {$version > 99
    || $subversion > 9
    || $subsubversion > 9
    || [string length $releaseCode] > 1
    || $nonRelease > 255} {
	error "\"$vers\" is not properly formatted"
    } 
    
    switch -- $releaseCode {
	"d" {set releaseCode 0x20}
	"a" {set releaseCode 0x40}
	"b" {set releaseCode 0x60}
	"f" - "fc" - "" {
	    set releaseCode 0x80
	}
	default {
	    error "\"$vers\" is not properly formatted"
	}
    }
    
    set major [expr {($version / 10) * 0x10 + ($version % 10)}]
    set minor [expr {$subversion * 0x10 + $subsubversion}]
    
    return [binary format cccc $major $minor $releaseCode $nonRelease]
}

# ×××× coercion handlers ×××× #

## 
 # -------------------------------------------------------------------------
 # 
 # "version::vers>VERS" --
 # 
 #  This should work with the reply under MacOS 7.x, where the result
 #  seems to be the entire version resource in hexadecimal form, 
 #  consisting of the encoded version number 
 #  followed by the version string, first as the number and then 
 #  as the full text.
 #                                 
 #            length    length
 #   __code__????||string||________________________text____________________
 #  Ç07008000000003372E3018416C7068612056657273696F6E20372E3020A92031393937È
 #    7008000       7 . 0   A l p h a   V e r s i o n   7 . 0   ©   1 9 9 7
 # -------------------------------------------------------------------------
 ##
proc version::vers>VERS {typeCode data toType resultDesc} {
    binary scan $data H8 version
    
    set version [version::codeToString $version]
    tclAE::replaceDescData $resultDesc TEXT $version
    
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "version::TEXT>VERS" --
 # 
 #  This should work with the reply under MacOS 8.x, where Apple has done
 #  us the "favor" of only returning the version string, making ordinal
 #  comparisons a royal pain-in-the-butt!
 #
 #  We thus parse the string and hope we find something meaningful.  The
 #  first instance of Ò<number>.<number>ÉÓ is assumed to be the version (a
 #  string like "version 5" will _not_ be recognized because simple
 #  integers are just as likely to be the year).
 #
 #  Pathological version parts like "fc" (final candidate) and "p" (patch)
 #  8^) are not recognized, as they have no analog in the version resource. 
 #  -------------------------------------------------------------------------
 ##
proc version::TEXT>VERS {typeCode data toType resultDesc} {
    if {![regexp {(([0-9]+)(\.([0-9]+)(\.([0-9]))?)?(([dabf][a-zA-Z]*)([0-9]*))?)} \
      $data versionString]} {
	set versionString $data
    }
    
    tclAE::replaceDescData $resultDesc TEXT $versionString
    
    return
}

## 
 # -------------------------------------------------------------------------
 # 
 # "version::utxt>VERS" --
 # 
 #  Convert Mac OS X's Utf-16 into Utf-8 and then handle as above
 #  -------------------------------------------------------------------------
 ##
proc version::utxt>VERS {typeCode data toType resultDesc} {
    version::TEXT>VERS $typeCode [encoding convertfrom unicode $data] $toType $resultDesc
    
    return
}

