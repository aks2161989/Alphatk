## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "licenseTemplates.tcl"
 #                                          created: 01/02/2006 {11:02:58 AM}
 #                                      last update: 05/24/2006 {05:29:55 PM}
 # Description:
 # 
 # Creates license templates for insertion into document windows.  The user
 # can modify the default templates or add new ones.  Any other AlphaTcl code
 # can obtain a list of the current licenses or an "electric template
 # insertion using the relevant procedures below.
 # 
 # This is an [alpha::library] package which simply defines the default
 # templates and provides an API to obtain them.  The strings
 # 
 #     package: licenseTemplates
 #     "licenseTemplates Help"
 # 
 # can be included in other packages' help files to provide the user with
 # additional information about how to modify and add license templates.
 # 
 # Based on "elecTemplateExamples.tcl".
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 #  
 # Copyright (c) 2006  Vince Darley, Craig Barton Upright
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

# library declaration
alpha::library licenseTemplates "0.3" {
    license::initializePackage
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} description {
    Creates license templates for insertion into document windows
} help {
    This package creates license templates for insertion into document
    windows.  These templates can be modified to suit your particular tastes.
    You can also add new license templates.  Other AlphaTcl packages use the
    list of defined templates to insert them into windows; see help for the
    package: documentProjects and the package: electricMenu for more
    information.
    
	  	Table Of Contents

    "# Default Licenses"
    "# Modifying Templates"
    "# Adding New Templates"
    "# Restoring Templates"
    "# Template Substitutions"
    "# Advanced Substitutions"
    
    "# System Administrator Notes"
    "# Developer Notes"

    <<floatNamedMarks>>
    
    
	  	Default Licenses
    
    Several licenses are defined by default; click here
    
    <<license::showLicenses>>
    
    to list them and display the current template(s) in a new window.  You
    can modify these templates as much as you want.
    
    
	  	Modifying Templates
    
    If you're not satisfied with the content of a default template, you can
    easily modify it.  Click here
    
    <<license::modifyTemplate>>
    
    to do so.
    
    When you are satisfied with your template, simply save the file.  The
    next time that some AlphaTcl code needs to get the template it will read
    the contents of this file, ignoring any comments and leading blank lines.
    
    All of your modified license templates are stored as files in ÇALPHAÈ's
    "Support" folder.
    
    <<license::showTemplateFolder>>
    
    See the "# Template Substitutions" section below for advanced tips.
    
    
	  	Adding New Templates
    
    If you want to add a new license template without changing any of the
    current defaults, click here
    
    <<license::addTemplate>>
    
    You will be prompted for a new license name, and a new file will be
    created in your Support folder.  You might want to use an existing
    template as an example: <<license::showLicenses>>.
    
    All of your personal license templates are stored as files in ÇALPHAÈ's
    "Support" folder.
    
    <<license::showTemplateFolder>>
    
    See the "# Template Substitutions" section below for advanced tips.
    
    
	  	Restoring Templates
    
    If you want to restore a default license template, simply remove the
    modified Support file.
    
    <<license::removeTemplate>>
    
    If this was a default license defined by this package, the default
    version will then be restored.  If it was a new license template added by
    you, it will be lost forever.
    
    
	  	Template Substitutions
    
    The template that is returned to any calling procedure is in an
    "electric" format that can specify template prompts and fancy
    substitutions.  For example, anything that is surrounded by ¥bullets¥ is
    considered to be a prompt, as in
    
	¥author¥
    
    The [license::getTemplate] procedure goes even further, and attempts to
    replace some of these "hints" with information that is relevant to the
    current user.  This routine makes use of the package: identities ; you
    can use the "Config > Preferences > Current Identity" menu to set your
    name, e-mail address, etc.  and this information will be used (when it is
    available) to create a better license template.  When none is available,
    the "hint" is retained as a template prompt.
    
    Some common substitutions that you can add to your template include
    
	¥author¥
	¥organisation¥
	¥address¥
	¥email¥
	¥www¥
	¥author_initials¥
	¥year¥
    
    Or, since you are modifying the template for your personal use, you could
    simply "hard-wire" those values as desired.
    
    Some additional template substitutions which are always available include
    
	¥tail¥
	¥path¥
    
    which refer to the name and path of the active window.
    
    
	  	Advanced Substitutions
    
    You might find that you have additional common "user information" fields
    that you would like to include in your template, such as an original year
    in which a suite of files was created.  Using the package: identities ,
    you can easily add any arbitrary field and value.  Open a "prefs.tcl"
    file, and add the following
    
	userInfo::addInfo <field> <value>
    
    as in
    
	userInfo::addInfo "orig_year" "1997"
    
    Now your template can include "¥orig_year¥" and the string "1997" will be
    automatically substituted.
    
    If you are in need of additional template substitutions that are more
    contextual, such as the ¥path¥ and ¥tail¥ examples above, feel free to
    contact this package's maintainer for some tips on how to create them.
    
    
	====================================================================
    
    
	  	System Administrator Notes
    
    A sysadmin can over-ride the default license templates or add new ones to
    be made available by adding files to the "Templates/Licenses" folder in
    the $SUPPORT(local) directory.  The user will still be able to over-ride
    these system additions, but your modifications/additions will always be
    used by default.
    
    <<file::showInFinder [file join $SUPPORT(local) Templates Licenses]>>
    

	  	Developer Notes
    
    To make use of this package, you should first confirm that it exists:
    
	alpha::package exists licenseTemplates
     
    Use the proc: license::listTypes for a list of the current templates.
    
    Use the proc: license::getTemplate <type> to get the electric template.
}

proc licenseTemplates.tcl {} {}

## 
 # --------------------------------------------------------------------------
 # 
 # "namespace eval license" --
 # 
 # Define all of the default templates, and register them for use by this
 # package if the user has not already provided over-rides in a "prefs.tcl"
 # file.  Define all other variables required by this package.
 # 
 # --------------------------------------------------------------------------
 ##

namespace eval license {
    
    variable versionNumber
    if {![info exists versionNumber]} {
	set versionNumber 0
    }
    variable initialized
    if {![info exists initialized]} {
        set initialized 0
    }
    
    # "licenseFolders" contains paths to all possible template folders.  The
    # order here is important: it determines the priority we use for finding
    # modified templates.
    variable licenseFolders [list]
    foreach domain [list "user" "local"] {
	if {($::SUPPORT($domain) ne "")} {
            lappend licenseFolders \
	      [file join $::SUPPORT($domain) Templates Licenses]
        }
    }
    unset domain
    if {![llength $licenseFolders]} {
        lappend licenseFolders [file join $::PREFS Templates Licenses]
    }
    
    variable lastChosenType
    if {![info exists lastChosenType]} {
        set lastChosenType ""
    }
    
    # These are used in [license::backCompatibility].
    variable tracePlaced
    if {![info exists tracePlaced]} {
        set tracePlaced 0
    }
    variable userInformed
    if {![info exists userInformed]} {
	set userInformed 0
    }
    
    # These fields will be mapped to "user" information as appropriate.
    variable fieldMappings
    array set fieldMappings [list \
      "owner"           "author" \
      "owner_org"       "organisation" \
      ]
    
    # "defaultTemplates" is the main variable which defines the templates.
    # Any string that is contained in ¥bullets¥ will be converted to its
    # proper value in [license::getTemplate].
    variable defaultTemplates
    
    set defaultTemplates(none) ""
    # "allRightsReserved" license.
    set defaultTemplates(allRightsReserved) {
Copyright (c) ¥year¥ ¥author¥

All rights reserved.
}
    # "allRightsReservedOrg" license.
    set defaultTemplates(allRightsReservedOrg) {
Copyright (c) ¥year¥ ¥organisation¥

All rights reserved.
}
    # "bsdLicense" license.
    set defaultTemplates(bsdLicense) {
Copyright (c) ¥year¥, ¥owner¥
All rights reserved.

Redistribution and use in source and binary forms, with or
without modification, are permitted provided that the following
conditions are met:

* Redistributions of source code must retain the above
copyright notice, this list of conditions and the
following disclaimer.

* Redistributions in binary form must reproduce the above
copyright notice, this list of conditions and the following
disclaimer in the documentation and/or other materials
provided with the distribution.

* Neither the name of ¥owner_org¥ nor the names of its
contributors may be used to endorse or promote products derived
from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
    # "copyrightNotice" license.
    set defaultTemplates(copyrightNotice) {
========================================================================
Copyright (c) ¥year¥ ¥author¥
========================================================================
Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted,
provided that the above copyright notice appear in all copies and that
both that the copyright notice and warranty disclaimer appear in
supporting documentation.

¥author¥ disclaims all warranties with regard to this software,
including all implied warranties of merchantability and fitness.  In
no event shall ¥author¥ be liable for any special, indirect or
consequential damages or any damages whatsoever resulting from loss of
use, data or profits, whether in an action of contract, negligence or
other tortuous action, arising out of or in connection with the use or
performance of this software.
========================================================================
    }
    # "gnuPublicLicense" license.
    set defaultTemplates(gnuPublicLicense) {
Copyright (c) ¥year¥  ¥author¥

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
    }
    # "seeFileLicenseTerms" license.
    set defaultTemplates(seeFileLicenseTerms) {
Copyright (c) ¥year¥  ¥author¥

See the file "license.terms" for information on usage and redistribution
of this file, and for a DISCLAIMER OF ALL WARRANTIES.
}
    variable defaultTypes [lsort -dictionary [array names defaultTemplates]]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "license::initializePackage" --
 # 
 # Create the "licenseFolder" directories if necessary, and call/register 
 # any back compatibility procedures and traces.
 # 
 # --------------------------------------------------------------------------
 ##

proc license::initializePackage {} {
    
    global alpha::macos alpha::internalEncoding PREFS
    
    variable defaultTemplates
    variable initialized
    variable licenseFolders
    variable tracePlaced
    variable versionNumber
    
    set newVersionNumber "0.3"
    if {$initialized} {
	return
    }
    # Older version automatically created the template files in the user's
    # domain.  We now only do so when the templates are modified.  We'll
    # remove the file we previously added.  (Fortunately, this earlier
    # version was only in existence for a few days...)
    if {($versionNumber < "0.3")} {
	foreach licenseFolder $licenseFolders {
	    foreach type [array names defaultTemplates] {
		set filePath [file join $licenseFolder $type]
		if {[file exists $filePath]} {
		    catch {file delete -force $filePath}
		}
	    }
	}
    }
    # Make sure that our "licenseFolders" directories exist.  We might not
    # have the proper permissions to create them.  
    foreach licenseFolder $licenseFolders {
	if {![file exists $licenseFolder]} {
	    catch {file mkdir $licenseFolder}
	}
	if {![file exists $licenseFolder]} {
	    set licenseFolders [lremove $licenseFolders [list $licenseFolder]]
	}
	alpha::registerEncodingFor $licenseFolder $alpha::internalEncoding
    }
    # If the user didn't have SUPPORT available before but now does, transfer
    # all of those files to the new location.
    set prefsLicenses [file join $PREFS "Templates" "Licenses"]
    set usersLicenses [lindex $licenseFolders 0]
    if {($usersLicenses ne $prefsLicenses) && [file exists $prefsLicenses]} {
	foreach fileTail [glob -nocomplain -tails -dir $prefsLicenses "*"] {
	    set oldFile [file join $prefsLicenses $fileTail]
	    set newFile [file join $usersLicenses $fileTail]
	    if {![file exists $newFile]} {
		file copy -force $oldFile $newFile
		catch {file::toAlphaSigType $newFile}
	    }
	    file delete -force $oldFile
	}
	file delete -force $prefsLicenses
    }
    # Register our startup hook.
    hook::register "startupHook" {license::backCompatibility}
    # Now we add a trace to the "::elec::LicenseTemplates" variable so that
    # [license::backCompatibility] will be called as needed.
    if {!$tracePlaced} {
	trace add variable "::elec::LicenseTemplates" write \
	  {::license::backCompatibility}
	set tracePlaced 1
    }
    if {($versionNumber < $newVersionNumber)} {
	set versionNumber $newVersionNumber
	prefs::modified versionNumber
    }
    # Make sure that we don't do all of this again.
    set initialized 1
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "license::backCompatibility" --
 # 
 # This is a check performed after startup is complete, when the user's 
 # "prefs.tcl" file has been sourced.  Our goal here is to provide back 
 # compatibility, and to inform the user of how to update code.
 # 
 # --------------------------------------------------------------------------
 ##

proc license::backCompatibility {args} {
    
    global elec::LicenseTemplates smarterSourceFolder
    
    variable userInformed
    
    if {$userInformed} {
	return
    }
    if {[info exists elec::LicenseTemplates]} {
	set createWindow 1
	append text {
License Template Back Compatibility Information

This window has been created because some AlphaTcl code (perhaps one of your
personal modifications) is attempting to add to a global variable named

	elec::LicenseTemplates

This variable was used in earlier versions of the package: documentProjects
as well as the package: electricMenu .  Both of these packages have been
updated, and no longer use this variable.  You should adjust your personal
code accordingly.  You most likely placed it in your "prefs.tcl" file or in
a Smarter Source folder.SHOWSMARTERSOURCE

The new package: licenseTemplates makes it much easier for you to modify
existing license templates or to add new ones.  Please see the help file for
the package: licenseTemplates for more information.

Once you have used this package to add/modify the templates, you should
remove your personal code which uses the "elec::LicenseTemplates" variable so
that you will no longer be presented with this warning.
}
	if {[info exists smarterSourceFolder] \
	  && [file isdir $smarterSourceFolder]} {
	    set replacement "\r\r<<file::showInFinder \$smarterSourceFolder>>\r"
	} else {
	    set replacement ""
	}
	regsub -all -- "SHOWSMARTERSOURCE" $text $replacement text
    }
    # The user has either defined "elec::LicenseTemplates" in a personal
    # file, or has obsolete "Smarter Source" code lying about.
    if {[info exists createWindow]} {
	set q "The obsolete global variable \"elec::LicenseTemplates\"\
	  is being set by some AlphaTcl code, possibly in one of your\
	  personal modification files.  Would you like some information\
	  about how to update your code?"
	if {![askyesno $q]} {
	    unset createWindow
	}
    }
    if {[info exists createWindow]} {
	set name "* License Template Back Compatibility *"
	set w [new -n $name -text $text -tabsize 4]
	help::markColourAndHyper -w $w
	goto [minPos -w $w]
	winReadOnly
	# Set this so that the user only sees this warning once.
	set userInformed 1
    }
    return
}

# ===========================================================================
# 
# ×××× Template Files ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "license::templateFileText" --
 # 
 # Add header information to a given template text.
 # 
 # --------------------------------------------------------------------------
 ##

proc license::templateFileText {type templateText} {
    
    global alpha::application
    
    set text {# -*-Tcl-*-
# 
# This file contains your personal version of the "ÇTYPEÈ" 
# license template.  Modify it as you wish.
# 
# Note that any text surrounded with ¥bullets¥ will automatically be
# substituted with "User Information" using the [userInfo::getInfo]
# procedure.  You can retain these strings, or simply replace them with the
# appropriate text.  The list "User Information" fields include
# 
#   ÇUSERINFOFIELDSÈ
# 
# When you have finished modifying your template, just save it.  All changes
# will be recognized the next time some AlphaTcl code needs to get your 
# license template.
# 
# To restore the template to the original version, simply delete this file
# and restart ÇALPHAÈ -- it will be automatically created with the default 
# template text.
# 
# Any leading blank lines will be ignored, as well as these comments.

}
    append text [string trimleft $templateText]
    array set substitutions [list \
      "TYPE"            $type \
      "ALPHA"           $alpha::application \
      "USERINFOFIELDS"  [userInfo::listFields "all"] \
      ]
    foreach item [array names substitutions] {
	regsub -all -- "Ç${item}È" $text $substitutions($item) text
    }
    return $text
}

## 
 # --------------------------------------------------------------------------
 # 
 # "license::writeTemplateFile" --
 # 
 # Given the name of a license and some text, create the file within the
 # user's "licenseFolder".  This assumes that any header has already been
 # added.  (Sysadmins will have to add their files to the $SUPPORT(local)
 # directory "manually.")
 # 
 # --------------------------------------------------------------------------
 ##

proc license::writeTemplateFile {type text} {
    
    variable licenseFolders
    
    if {![llength $licenseFolders]} {
	dialog::errorAlert "Cancelled -- No License Template folders exist."
    }
    set templateFile [file join [lindex $licenseFolders 0] $type]
    regsub -all -- "\n" $text "\r" text
    file::writeAll $templateFile $text 1
    catch {file::toAlphaSigType $templateFile}
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "license::readTemplateFile" --
 # 
 # Given the name of a license type, attempt to read it from the file.  If
 # the file doesn't exist, throw an error.
 # 
 # --------------------------------------------------------------------------
 ##

proc license::readTemplateFile {type} {
    
    variable licenseFolders
    
    foreach licenseFolder $licenseFolders {
	set filePath [file join $licenseFolder $type]
	if {[file exists $filePath]} {
	    set fileName $filePath
	    break
	}
    }
    if {![info exists fileName]} {
	error "No template file was found."
    }
    set textLines [split [file::readAll $fileName] "\r\n"]
    for {set i 0} {($i < [llength $textLines])} {incr i} {
	if {[regexp -- {^\s*\#} [lindex $textLines $i]]} {
	    continue
	} else {
	    break
	}
    }
    set template [string trim [join [lrange $textLines $i end] "\r"]]
    if {($template ne "")} {
	append template "\r"
    }
    return $template
}

# ===========================================================================
# 
# ×××× Template Text ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "license::listTypes" --
 # 
 # List all defined license types.  The "None" license always exists, but
 # some procedures don't want to include it in the list because it cannot be
 # deleted.  The "includeNone" argument determines if it is included, and if
 # so, where.  Menu and dialog dividers can be used to separate it from the
 # other items.
 # 
 # --------------------------------------------------------------------------
 ##

proc license::listTypes {{includeNone "0"} {prettify "0"}} {
    
    variable defaultTemplates
    variable licenseFolders
    
    set licenseList [list]
    foreach licenseFolder $licenseFolders {
	set fileNames [glob -nocomplain -directory $licenseFolder -tail "*"]
	foreach fileName $fileNames {
	    lappend licenseList $fileName
	}
    }
    foreach type [array names defaultTemplates] {
	lappend licenseList $type
    }
    set licenseList [lsort -dictionary -unique $licenseList]
    set licenseList [lremove $licenseList [list "none" "None"]]
    if {($includeNone != 0)} {
	if {![llength $licenseList]} {
	    if {$prettify} {
		return [list "None"]
	    } else {
		return [list "none"]
	    }
	}
	switch -- $includeNone {
	    "-3" {
		set licenseList [linsert $licenseList 0 "none" "(-)"]
	    }
	    "-2" {
		set licenseList [linsert $licenseList 0 "none" "-"]
	    }
	    "-1" {
		set licenseList [linsert $licenseList 0 "none"]
	    }
	    "1" {
		set licenseList [linsert $licenseList end "none"]
	    }
	    "2" {
		set licenseList [linsert $licenseList end "-" "none"]
	    }
	    "3" {
		set licenseList [linsert $licenseList end "(-)" "none"]
	    }
	}
    }
    if {$prettify} {
	set newList [list]
	foreach license $licenseList {
	    lappend newList [quote::Prettify $license]
	}
	set licenseList $newList
    }
    return $licenseList
}

## 
 # --------------------------------------------------------------------------
 # 
 # "license::getTypeFromName" --
 # 
 # Given some variation of a license type's name (i.e. prettified), determine
 # if we have this defined in the "templates" array, and if so return that
 # name.  If no license type can be found, return "none".
 # 
 # This is useful if an initial list was created by [license::listTypes] with
 # the "prettify" option set.
 # 
 # --------------------------------------------------------------------------
 ##

proc license::getTypeFromName {name} {
    
    set type  $name
    set name  [string trim [string tolower $name]]
    set name1 [string trim [string tolower $name]]
    regsub -all -- {\s} $name1 {} name2
    foreach licenseType [license::listTypes 0] {
	set licensetype [string tolower $licenseType]
	if {($name1 eq $licensetype) || ($name2 eq $licensetype)} {
	    set type $licenseType
	    break
	}
    }
    return $type
}

## 
 # --------------------------------------------------------------------------
 # 
 # "license::getTemplate" --
 # 
 # If we have information about the "type" license, return it formatted as an
 # electric template.  For all templates except "none", the template will
 # have a trailing Return.  Note that case doesn't matter here; all of
 # 
 #     license::getTemplate "allRightsReserved"
 #     license::getTemplate "allrightsreserved"
 #     license::getTemplate "ALLRIGHTSRESERVED"
 # 
 # will work.
 # 
 # Back compatibility notes: earlier version of "elecTemplateExamples.tcl" 
 # contained a set of procedures in the "file" namespace such as
 # 
 #     file::allRightsReserved
 #     file::copyrightNotice
 # 
 # that would return electric templates for different license types.  These
 # are now obsolete, and nothing in the standard AlphaTcl distribution makes
 # reference to them.  It is possible, however, that the user re-defined
 # these procedures in a "prefs.tcl" or a "Smarter Source" file.  We will
 # still call these procedures if they exist or can be found.  The user
 # should, however, update any existing code and add these new or modified
 # templates as described in the "help" argument above.
 # 
 # --------------------------------------------------------------------------
 ##

proc license::getTemplate {type {substitute 1}} {
    
    variable defaultTemplates
    variable fieldMappings
    variable licenseFolders
    
    set type [license::getTypeFromName $type]
    
    if {($type eq "none")} {
	# No license.
	return ""
    }
    set template ""
    if {![catch {license::readTemplateFile $type} result]} {
	# We were able to read this from a file.
	set template $result
    } elseif {[info exists defaultTemplates($type)]} {
	# Use a default template if it is available.
	set template $defaultTemplates($type)
    } elseif {[llength [info procs [set p ::file::$type]]] || [auto_load $p]} {
	# This is a back compatibility routine; see notes above.
	warningForObsProc $p
	set template [eval $p]
    }
    if {($template eq "")} {
	return ""
	# Should we give an error warning here?
	error "No template has been defined for \"$type\""
    }
    if {$substitute} {
        # Replace ¥bulleted strings¥ with user information values. 
        foreach field [userInfo::listFields "all"] {
            set value [userInfo::getInfo $field "¥${field}¥"]
            regsub -all -- "¥${field}¥" $template $value template
        }
        # If any "extra" user information fields weren't defined, attempt to
        # replace them with reasonable substitutes.
        foreach oldField [array names fieldMappings] {
            set newField $fieldMappings($oldField)
            set value [userInfo::getInfo $newField "¥${oldField}¥"]
            regsub -all -- "¥${oldField}¥" $template $value template
        }
    }
    set template "[string trim $template]\r"
    return $template
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× User Interface ×××× #
# 

## 
 # -------------------------------------------------------------------------
 # 
 # "license::showLicenses" --
 # 
 # Called via a help window hyperlink, present the names of all of the
 # current licenses to the user.  If any are chosen (and the user doesn't
 # press Cancel), display the templates in a new window.
 # 
 # -------------------------------------------------------------------------
 ##

proc license::showLicenses {} {
    
    variable lastChosenType
    
    set p "The current defined licenses include:"
    set types [license::listTypes 0 1]
    if {([lsearch $types $lastChosenType] > -1)} {
	set L [list $lastChosenType]
    } else {
	set L [lrange $types 0 0]
    }
    if {[catch {listpick -p $p -L $L -l $types} types]} {
	return
    }
    set lastChosenType [lindex $types 0]
    set txt "\rCurrent License Templates:\r\r"
    foreach type $types {
	set section "\"$type\" license template:"
	set divider [string repeat "=" [string length $section]]
	append txt [string repeat "_" 80] "\r\r\r" $section \r $divider \
	  \r\r" [license::getTemplate [license::getTypeFromName $type] 0] "\r"
    }
    set w "* License Templates *"
    if {[win::Exists $w]} {
	bringToFront $w
	win::setInfo $w read-only 0
	replaceText -w $w [minPos -w $w] [maxPos -w $w] $txt
    } else {
	set w [new -n $w -text $txt]
    }
    goto -w $w [minPos -w $w]
    help::colourTitle -w $w red
    refresh
    catch {winReadOnly $w}
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "license::addTemplate" --
 # 
 # Allow the user to define a new template, taking care to ensure that we 
 # give it a proper name.
 # 
 # --------------------------------------------------------------------------
 ##

proc license::addTemplate {} {
    
    variable defaultTypes
    
    set p "Enter a name for the new license:"
    set name ""
    while {1} {
	set name [string trim [prompt $p $name]]
	set p "Try a different license name:"
	if {($name eq "")} {
	    alertnote "The name cannot be an empty string!"
	    continue
	} elseif {![regexp -- {^[a-zA-Z0-9 ]+$} $name]} {
	    alertnote "The name must be alpha-numeric!"
	}
	set firstChar [string index $name 0]
	set name   [string replace $name 0 0 [string tolower $firstChar]]
	regexp -all -- {\s+} $name {} name
	if {($name eq "none")} {
	    alertnote "Sorry, the \"none\" license is always empty!"
	    continue
	} elseif {([lsearch $defaultTypes $name] > -1)} {
	    set q "The \"$name\" license is always available;\
	      Would you like to modify its current template?"
	    if {![askyesno $q]} {
		continue
	    }
	} elseif {([lsearch [license::listTypes 1] $name] > -1)} {
	    alertnote "Sorry, \"$name\" is already used as the name\
	      for a license type."
	    continue
	}
	# Still here?  The name must be valid.
	break
    }
    license::modifyTemplate $name
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "license::modifyTemplate" --
 # 
 # Prompt the user for the name of a license type if none is supplied, and
 # open the "licenseFolder" file which contains the template.
 # 
 # --------------------------------------------------------------------------
 ##

proc license::modifyTemplate {{type ""}} {
    
    global alpha::application
    
    variable lastChosenType
    variable licenseFolders
    
    if {![llength $licenseFolders]} {
	dialog::errorAlert "Cancelled -- No License Template folders exist."
    }
    if {($type eq "")} {
	set p "Modify which license template?"
	set types [license::listTypes 0 1]
	if {([lsearch $types $lastChosenType] > -1)} {
	    set L [list $lastChosenType]
	} else {
	    set L [lrange $types 0 0]
	}
	set type [listpick -p $p -L $L $types]
	set lastChosenType $type
    }
    set type [license::getTypeFromName $type]
    set fileName [file join [lindex $licenseFolders 0] $type]
    if {![file exists $fileName]} {
	set template [license::getTemplate $type 0]
	if {($template eq "")} {
	    set template "Enter new template here..."
	}
	set templateText [license::templateFileText $type $template]
	license::writeTemplateFile $type $templateText
    }
    edit -c $fileName
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "license::removeTemplate" --
 # 
 # Remove a template, restoring the default version if available.
 # 
 # --------------------------------------------------------------------------
 ##

proc license::removeTemplate {{type ""}} {
    
    variable defaultTemplates
    variable lastChosenType
    variable licenseFolders
    
    set licenseFolder [lindex $licenseFolders 0]
    foreach fileTail [glob -nocomplain -directory $licenseFolder -tail "*"] {
	lappend types [quote::Prettify $fileTail]
    }
    if {![info exists types]} {
	dialog::errorAlert "Cancelled -- There are no modified\
	  file license templates to remove or restore."
    }
    if {($type eq "")} {
	set p "Remove (restore?) which license template(s)?"
	if {([lsearch $types $lastChosenType] > -1)} {
	    set L [list $lastChosenType]
	} else {
	    set L [lrange $types 0 0]
	}
	set type [listpick -p $p -L $L $types]
	set lastChosenType $type
    }
    set type [license::getTypeFromName $type]
    set fileName [file join $licenseFolder $type]
    if {![file exists $fileName]} {
	alertnote "Could not find the file\r\r$fileName\
	  \r\rNothing was removed."
    }
    if {(![info exists defaultTemplates($type)])} {
	set q "The license \"[quote::Prettify $type]\" is one of your\
	  personal additions; it will not be restored but removed.\
	  \r\rDo you want to continue?"
	if {![askyesno $q]} {
	    error "cancel"
	}
    }
    file delete -force $fileName
    foreach window [file::hasOpenWindows $fileName] {
	killWindow -w $window
    }
    set msg "The template file has been deleted"
    if {[info exists defaultTemplates($type)]} {
	append msg " and restored."
    }
    alertnote [append msg "."]
    status::msg $msg
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "license::showTemplateFolder" --
 # 
 # Display the user's "licenseFolder" in the Finder.
 # 
 # --------------------------------------------------------------------------
 ##

proc license::showTemplateFolder {} {
    
    variable licenseFolders
    
    set licenseFolder [lindex $licenseFolders 0]
    if {![file exists $licenseFolder]} {
	dialog::errorAlert "Cancelled -- No License Template folders exist."
    }
    file::showInFinder $licenseFolder
    return
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Version History ×××× #
# 
# modified by  rev    reason
# -------- --- ------ -----------
# 01/02/06 cbu 0.1    Original, based on "elecTemplateExamples.tcl"
# 01/03/06 cbu 0.2    Using "SUPPORT(user)" folder for templates.
# 01/05/06 cbu 0.3    Added "SUPPORT(local)" license folder.
#                     User's modified files always take precedence.
#                     No longer creating files during initialization.

# ===========================================================================
# 
# .