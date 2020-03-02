## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 #
 # FILE: "xmlMode.tcl"
 #                                          created: 02/05/2003 {03:22:59 PM}
 #                                      last update: 2006-03-31 16:11:18
 # 
 # Description:  
 # 
 # XML mode definition and support procs.
 # 
 # Author: ?? (Automatically created by mode assistant)
 # 
 # Includes contributions from:
 # 
 # Bernard Desgraupes <bdesgraupes@easyconnect.fr>
 # Craig Barton Upright <cupright@alumni.princeton.edu>
 # Chuck Gregory <czg@mac.com>
 # 
 # Copyright (c) 2003-2006  Bernard Desgraupes, Craig Barton Upright,
 #                          Chuck Gregory
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # History:
 #
 # Automatically created by mode assistant
 # Contributions by Bernard Desgraupes
 # Contributions by Craig Barton Upright
 # Contributions by Chuck Gregory:
 #  - Added XSLT processing via an external (command line) service
 #     - "Apply XSL Transformation To File..." uses the XSERV
 #     - "Apply XSL Transformation to Buffer"  uses tDOM
 #  - (Marginally) improved tDOM-based XSLT processing
 #  - Improved electricClosingAngleBracket processing
 #  - Added "Electric Tags" preference checkbox
 #  - Improved syntax coloring (still need "regModeKeywords -f" :-)
 #  - Added mode-specific indentation amounts
 #  - ...
 # 
 # ==========================================================================
 ##

alpha::mode xml 0.5.0 source {*.plist *.xml *.manifest *.svg *.xsd *.psf} {
    xmlMenu
} {
    # Script to execute at Alpha startup.
    addMenu xmlMenu XML xml
} uninstall {
    this-file
} maintainer {
} description {
    Supports the editing of XML files
} help {
    xml Mode provides keyword coloring and completion, where keywords
    are automatically parsed from your xml files.

    Click on this "xml Example.xml" link for an example syntax file.
}

alpha::mode dtd 0.4.2 source {*.dtd} {
    xmlMenu
} {
    # Script to execute at Alpha startup.
} uninstall {
    if {[askyesno \
      "Uninstalling \"dtd\" mode will also remove \"xml\" mode.\r\r\
      Do you want to continue?"]} {
	catch {file delete [file join $HOME Tcl Modes xmlMode.tcl]}
    }
} maintainer {
} description {
    Provides support for Alpha's "xml" mode
} help {
    This package provides support for xml mode, see "xml Help".
}

alpha::mode xsl 0.4.2 source {*.xsl *.xslt} {
    xmlMenu
} {
    # Script to execute at Alpha startup.
} uninstall {
    if {[askyesno \
      "Uninstalling \"xsl\" mode will also remove \"xml\" mode.\r\r\
      Do you want to continue?"]} {
	catch {file delete [file join $HOME Tcl Modes xmlMode.tcl]}
    }
} maintainer {
} description {
    Provides support for Alpha's "xml" mode
} help {
    This package provides support for xml mode, see "xml Help".
}

proc xmlMode.tcl {} {}

# =============================== #
# ====   External Services   ==== #
# =============================== #

::xserv::declare Xslt "XSLT processor" xslfile xmlfile
::xserv::register Xslt xslt -driver {
   set command [list $params(xserv-sabcmd)]
   lappend command $params(xslfile) $params(xmlfile)
   return $command
} -progs {sabcmd}

# ====================================== #
# ====   Variables initialization   ==== #
# ====================================== #

namespace eval xml {
    # Variables initialization
    variable Params
    set Params(doctypes) [list "xml" "dtd" "xslt" ]
    set Params(editing) [list insertElement insertEntity editAttributes \
     (-) <O/BbalanceTags]
   set Params(parsing) [list "(checkWell Formedness" validateStandalone \
     validateWithDtd]
   set Params(transforming) [list "selectXsltFileÉ" "(-" \
     "applyTransformationToBuffer" "applyTransformationToFileÉ"]
   set Params(trees) [list buildTree extractSubTree dumpTree displayTree]
    
    set Params(currentxslt) ""
}
namespace eval xslt {
    variable Params
    set Params(outmethod) ""
    set Params(outencoding) "utf-8"
    set Params(outroot) ""
}
namespace eval dtd {}
namespace eval xsl {}

# This proc is called every time we turn the menu on.
# Its main effect is to ensure this code, including the
# menu definition below, has been loaded.
proc xmlMenu {} {}


# Mode preferences settings
# =========================

# xml mode
# --------
set xml::commentCharacters(General) ""
set xml::commentCharacters(Paragraph) [list "<!--" "-->" " | " ]
set xml::commentCharacters(Box) [list "<!--" 4 "-->" 3 "|" 3]

newPref var lineWrap 2 xml
newPref color keywordColor magenta xml
newPref color tagColor green xml
newPref color stringColor green xml
newPref color commentColor red xml

newPref v wordBreak {\w+} xml

newPref v prefixString	"<!-- " xml
newPref v suffixString	" -->" xml

# Invokes automatic indentation for closing tags in xml mode.
Bind '>'     {xml::electricClosingAngleBracket}			xml
Bind '>' <z> {insertText >}					xml

# xsl mode
# --------
set xsl::commentCharacters(General) ""
set xsl::commentCharacters(Paragraph) [list "<!--" "-->" " | " ]
set xsl::commentCharacters(Box) [list "<!--" 4 "-->" 3 "|" 3]

newPref var lineWrap 2 xsl
newPref color tagColor green xsl
newPref color stringColor green xsl
newPref color keywordColor blue xsl
newPref color xslFunctionColor magenta xsl

newPref v wordBreak {\w+} xsl

newPref v prefixString	"<!-- " xsl
newPref v suffixString	" -->" xsl

# At present, the "XML > Xml Editing > Balance Tags" menu item shortcut is
# only active for xml mode.
Bind '>'     {xml::electricClosingAngleBracket}			xsl
Bind '>' <z> {insertText >}					xsl
Bind 'b' <c> {xml::editingMenuProc "Xml Editing" "balanceTags"}	xsl

# dtd mode
# --------
set dtd::commentCharacters(General) ""
set dtd::commentCharacters(Paragraph) [list "<!--" "-->" " | " ]
set dtd::commentCharacters(Box) [list "<!--" 4 "-->" 3 "|" 3]

newPref var lineWrap 2 dtd
newPref color keywordColor magenta dtd
newPref color tagColor green dtd
newPref color stringColor green dtd

newPref v wordBreak {\w+} dtd

newPref v prefixString	"<!-- " dtd
newPref v suffixString	" -->" dtd

# At present, the "XML > Xml Editing > Balance Tags" menu item shortcut is
# only active for xml mode.
Bind 'b' <c> {xml::editingMenuProc "Xml Editing" "balanceTags"} dtd

# ×××× Menus ×××× #

menu::buildProc xmlMenu xml::buildXmlMenu
menu::buildProc newXmlDoc xml::buildXmlNewDoc
menu::buildProc xmlEditing xml::buildXmlEditing
menu::buildProc xmlParsing xml::buildXmlParsing
menu::buildProc xmlTransforming xml::buildXmlTransforming
menu::buildProc xmlTrees xml::buildXmlTrees


# Building menus procs
# --------------------

proc xml::buildXmlMenu {} {
    global xmlMenu
    set ma ""
    lappend ma [list Menu -n "newXmlDoc" {}]
    lappend ma "(-" "checkWellFormedness" "(-"
    lappend ma [list Menu -n "xmlEditing" {}]
    lappend ma [list Menu -n "xmlParsing" {}]
    lappend ma [list Menu -n "xmlTransforming" {}]
    lappend ma [list Menu -n "xmlTrees" {}]
    if {$alpha::platform eq "tk"} {
        lappend ma "viewXml"
    } 
    
    return [list build $ma xml::menuProc {newXmlDoc xmlEditing xmlParsing xmlTransforming xmlTrees} $xmlMenu]
}


proc xml::buildXmlNewDoc {} {
    variable Params
    return [list build $xml::Params(doctypes) xml::newDocProc ]
}


proc xml::buildXmlEditing {} {
    variable Params
    return [list build $xml::Params(editing) {xml::editingMenuProc -M "xml"} ]
}


proc xml::buildXmlParsing {} {
    variable Params
    return [list build $xml::Params(parsing) xml::parsingMenuProc ]
}

proc xml::buildXmlTransforming {} {
    variable Params
    set ma  $xml::Params(transforming)
    if {$xml::Params(currentxslt)!=""} {
	lappend ma "(-" [menu::itemWithIcon "currentXslt" 83] 
	lappend ma "  [file tail $xml::Params(currentxslt)]&"
    } else {
	lappend ma "(-" [menu::itemWithIcon "noCurrentXslt" 82] 
    }
    return [list build $ma xml::transformingMenuProc ]
}


proc xml::buildXmlTrees {} {
    variable Params
    return [list build $xml::Params(trees) xml::treesMenuProc ]
}


# Menu commands procs
# -------------------

# This procedure is called whenever we select a menu item
proc xml::menuProc {menu item} {
    switch -- $item {
	"viewXml" { 
	    global HOME
	    script::run [file join $HOME Tools stardom.tcl] \
	      [win::Current]
	}
	"checkWellFormedness" {
	    set type [getTypeOfDoc]
	    set caught 0
	    switch -- $type {
		"xml" - "xslt" - "xsl" {
		    set text [getText [minPos] [maxPos]]
		    if {[string length $text]} {
			set caught [expr ![catch {set doc [dom parse $text]} res]]
			if {$caught} {$doc delete}
		    }
		}
		"dtd" {
		    set caught [expr ![catch {dtd::checkExternalDTDfile [win::Current]} res]]
		}
		default {error "Unknown type of doc $type"}
	    }
	    if {$caught} {
		status::msg "Well formed $type document"
	    } else {
		alertnote $res
	    }
	    return $caught
	}
    }
}


proc xml::newDocProc {menu item} {
    variable Params
    if {[catch {prompt "Name of new $item doc (without extension)." ""} \
      docname] || $docname==""} {return} 
    regsub xslt $item xsl item
    # Experimental. These are hardcoded headers. This is only  temporary: 
    # we'll have to go through a dialog.
    switch -- $item {
	"xml" {
	    set contents "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\r"
	    append contents "<!DOCTYPE $docname \[\r"
	    append contents "\r\]>\r"
	    append contents "<$docname>"
	    append contents "\r</$docname>\r"
	}
	"dtd" {
	    set contents "<!-- $docname.$item -->\r"
	}
	"xsl" {
	    set contents "<?xml version=\"1.0\"?>\r"
	    append contents "<xsl:stylesheet xmlns:xsl=\"http://www.w3.org/1999/XSL/Transform\" \
	      version=\"1.0\">\r\r"
	}
    }
    new -n $docname.$item -mode $item
    insertText $contents
}


proc xml::editingMenuProc {menu item} {
    switch -- $item {
	"balanceTags" {
	    set tagName [xml::specialBalance]
	    if {($tagName ne "")} {
		status::msg "$tagName É /$tagName selected."
	    }
	}
	default {
	    alertnote "Not implemented yet"
	}
    }
    return
}

# Validate with external DTD, using the 'tnc' package, part of tDOM.
# Select error line if any.

proc xml::parsingMenuProc { menu item } {
    set fileName [win::StripCount [win::Current]]
    switch -- $item {
	"validateWithDtd" {
	    if { [catch {package require tnc} err]} {
		alertnote "XML validating with external DTD \
		  requires the 'tnc' package, part of 'tDOM'. \
		  This package is not available ($err)."
		return
	    }
	    unset err
	    set parser [expat -externalentitycommand ::dtd::ExtEntityResolver \
	      -baseurl "[file dirname $fileName]" \
	      -paramentityparsing always]
	    tnc $parser enable
	    catch {$parser parsefile $fileName} err
	    $parser free
	    if { [string length $err] } {
		if { [regexp -- {line (\d+)} $err "" lineNumber] } {
		    file::gotoLine $fileName $lineNumber
		}
		status::msg $err
	    } else {
		if { $::dtd::cachedDtdUsed } {
		    status::msg "Document validated using cached DTD."
		} else {
		    status::msg "Document valid."
		}
	    }
	}
	default {
	    alertnote "Not implemented yet"
	}
    }
}

proc xml::transformingMenuProc {menu item} {
    variable Params
    switch -- $item {
	"selectXsltFile" {
	    if {[catch {getfile "Select an XSLT file"} Params(currentxslt)]} {return} 
	    menu::buildSome xmlTransforming
	}
	"applyTransformationToBuffer" {
	    set result  [xslt::Transform [getText [minPos] [maxPos]] $Params(currentxslt)]
	    if {$result!=""} {
		new -n "[file tail [file root [win::StripCount [win::Current]]]][xslt::transformedExtension]"
		insertText $result
	    } 
	}
	"applyTransformationToFile" {
	    if {[catch {getfile "Select an XML file"} xmlfile]} {return} 
	    set fid [open $xmlfile r]
	    set txt [read $fid]
	    close $fid
	    set result [xslt::Transform $txt $Params(currentxslt)]
	    if {$result!=""} {
		new -n "[file tail [file root $xmlfile]][xslt::transformedExtension]"
		insertText $result
	    } 
	}
    }
}


proc xml::treesMenuProc {menu item} {alertnote "Not implemented yet"}


# Now build the menu
# ------------------
menu::buildSome xmlMenu 


# ===========================================================================
# 
# ×××× Editing Procedures ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "xml::specialBalance" --
 # 
 # Called by "XML > Xml Editing > Balance Tags" when the mode of the active
 # window is in the "xml" family.  If a "normal" [balance] fails, find the
 # closest set of open/close tags surrounding the cursor, and determine the
 # text found between them.  If $inside == 1, then we only select the content
 # found in the tags, otherwise the tags are included in the selection.  This
 # can be performed recursively to select nested tags.
 # 
 # Returns the name of the tag which was balanced and selected.
 # 
 # Adapted from [html::SelectContainer].
 # 
 # --------------------------------------------------------------------------
 ##

proc xml::specialBalance {args} {
    
    requireOpenWindow
    
    win::parseArgs w {inside 0}
    
    # Preliminaries -- does a normal [balance] work?
    set posBeg [getPos -w $w]
    set posEnd [selEnd -w $w]
    if {![catch {::balance -w $w} errMsg]} {
	return ""
    }
    # Manipulate the starting position if necessary.
    set start $posBeg
    if {[pos::compare -w $w $start != [minPos -w $w]] \
      && ![catch {getText -w $w $start [pos::math -w $w $start + 2]} lookingAt] \
      && ($lookingAt ne "</") \
      && ([string index $lookingAt 0] eq "<")} {
	set start [pos::math -w $w $start - 1]
    }
    # Find the enclosing container, and select it.
    set tagInfo [xml::getContainer -w $w $start $posEnd]
    if {([llength $tagInfo] != 5)} {
	selectText -w $w $posBeg $posEnd
	error $errMsg
    } elseif {$inside} {
	selectText -w $w [lindex $tagInfo 1] [lindex $tagInfo 2]
    } else {
	selectText -w $w [lindex $tagInfo 0] [lindex $tagInfo 3]
    }
    return [lindex $tagInfo 4]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "xml::getContainer" --
 # 
 # Attempt to locate the "container" surrounding the "curPos" position,
 # ensuring that the "includePos" position is in the container.
 # 
 # If successful, returns a five item list, with
 # 
 # (0) position for start of open tag
 # (1) position for end of open tag
 # (2) position for start of close tag
 # (3) position for end of close tag
 # (4) upper case name of TAG found.
 # 
 # If we fail to find an enclosing container, returns an empty list.
 # 
 # Adapted from [html::GetContainer].
 # 
 # --------------------------------------------------------------------------
 ##

proc xml::getContainer {args} {
    
    win::parseArgs w startPos includePos
    
    while {1} {
	# Find open tag.
	while {1} {
	    if {[catch {xml::findFirstOccurance -w $w {<[^<>]+>} $startPos 0} openingTags]} {
		return [list]
	    }
	    set openTagBeg [lindex $openingTags 0]
	    set openTagEnd [lindex $openingTags 1]
	    # Get the name of the opening tag.
	    set text [getText -w $w $openTagBeg $openTagEnd]
	    if {![regexp {<([^ \t\r\n>]+)} $text -> tag]} {
		return [list]
	    }
	    # Is this a closing tag?
	    if {[string index $tag 0] eq "/"} {
		set startPos [pos::math -w $w $openTagBeg - 1]
	    } else {
		break
	    }
	}
	# Find closing tag.
	set closingTags [xml::getClosing -w $w $tag $openTagEnd]
	set closeTagBeg [lindex $closingTags 0]
	set closeTagEnd [lindex $closingTags 1]
	# Are we done yet?
	if {[llength $closingTags] && [pos::compare -w $w $closeTagEnd >= $includePos]} {
	    # There is a closing tag which includes the "includePos".
	    return [list $openTagBeg $openTagEnd \
	      $closeTagBeg $closeTagEnd [string toupper $tag]]
	} elseif {[pos::compare -w $w $openTagBeg == [minPos -w $w]]} {
	    # No more text to search.
	    return [list]
	} else {
	    # Continue searching.
	    set startPos [pos::math -w $w $openTagBeg - 1]
	}
    }
    # Hmmm... shouldn't ever get here!
    return [list]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "xml::findFirstOccurance" --
 # 
 # Ignoring text in comments, find the first occurance of a given pattern.
 # The first [while] block ensures that the given position is not already in
 # a comment.  If found, the two positions for the text in the window are
 # returned, otherwise an error is thrown.
 # 
 # Adapted from [html::FindFirstOccurance].
 # 
 # --------------------------------------------------------------------------
 ##

proc xml::findFirstOccurance {args} {
    
    win::parseArgs w pattern pos {dir 1}
    
    while {![catch {search -w $w -s -f $dir -r 1 -i 1 $pattern $pos} result1] \
      && ![catch {search -w $w -s -f 0 -r 1 -i 1 -- "<!--" [lindex $result1 0]} result2] \
      && ![catch {search -w $w -s -f 1 -r 1 -i 1 -- "-->"  [lindex $result2 1]} result3] \
      && [pos::compare -w $w [lindex $result3 1] > [lindex $result1 1]]} {
	if {$dir} {
	    set pos [lindex $result3 1]
	} else {
	    set pos [pos::math -w $w [lindex $result2 0] - 1]
	}
    }
    if {[catch {search -w $w -s -f $dir -r 1 -i 1 $pattern $pos} result]} {
	error "Not found."
    } else {
	return $result
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "xml::getClosing" --
 # 
 # Determine the location for the closing of the given tag.  (We'll add the
 # surrounding angle brackets here, so don't supply them.)  If the search was
 # successful, returns a two item list with the start/end positions of the
 # closing tag.  If the search fails, returns an empty list.
 # 
 # Adapted from [html::GetClosing].
 # 
 # --------------------------------------------------------------------------
 ##

proc xml::getClosing {args} {
    
    win::parseArgs w tag pos
    
    append pat1 "</" $tag ">"
    append pat2 "<" $tag {([ \t\r\n]+|>)}
    set startPos1 $pos
    set startPos2 $pos
    while {1} {
	if {[catch {xml::findFirstOccurance -w $w $pat1 $startPos1} result1]} {
	    # Could not find the opening for the given tag.
	    return [list]
	} elseif {[catch {xml::findFirstOccurance -w $w $pat2 $startPos2} result2] \
	  || [pos::compare -w $w [lindex $result2 0] > [lindex $result1 0]]} {
	    # Found another opening tag of the same element further away than
	    # the closing tag.
	    return $result1
	} else {
	    # Search for the next closing tag.
	    set startPos1 [lindex $result1 1]
	    set startPos2 [lindex $result2 1]
	}
    }
    # Hmmm... shouldn't ever get here!
    return [list]
}

# ×××× Encodings ×××× #

hook::register preOpeningHook xml::PreOpening xml

# Check if the file specifies its encoding and if so, try to convert that
# encoding name to a known encoding name.  This could perhaps be improved
# by someone who knows what valid xml encoding values are, and how best to
# convert them to Tcl encodings.  Currently it recognises that ISO-8859-1
# and iso8859-1 are the same, for example.
proc xml::PreOpening {name} {
    # Get first four lines.  Could probably do better by scanning until
    # we reach some known starting point.
    set lines ""
    set fin [open [win::StripCount $name] r]
    catch {
	append lines [gets $fin] [gets $fin] [gets $fin] [gets $fin]
    }
    close $fin
    # Extract the charset
    if {![regexp -nocase -- {encoding="?([a-z0-9-]+)"?} $lines -> charset]} {
	return
    }
    # Find a matching encoding name, if possible
    set encnames [encoding names]
    set charset [string tolower $charset]
    set encs [string tolower $encnames]
    if {[set idx [lsearch -exact $encs $charset]] == -1} {
	regsub -all -- "-" $encs "" encs
	regsub -all -- "-" $charset "" charset
	if {[set idx [lsearch -exact $encs $charset]] == -1} {
	    return
	}
    }
    # Tell AlphaTcl to set the encoding for this window.
    set encoding [lindex $encnames $idx]
    win::setInitialConfig $name encoding $encoding "window"
}

# ×××× Completions ×××× #

set completions(xml) {Cmd completion::word}
set completions(xsl) {completion::electric completion::word}

namespace eval xml::Completion {}

proc xml::Completion::Cmd {} {
    set cmd [completion::lastWord pos]
    if {[regexp {^<([^\*]*)\*?$} $cmd -> cmd] \
      || ([lookAt [pos::math $pos -1]] eq "<")} {
	set w [win::Current]
	if {[win::infoExists $w xmlcmds]} {
	    set cmds [win::getInfo $w xmlcmds]
	    set matches [lsearch -inline -all -glob $cmds "${cmd}*"]
	    if {[llength $matches]} {
		return [completion::matchUtil Cmd $cmd $matches ""]
	    }
	}
    }
    return 0
}


# ×××× Parsing ×××× #

if {[catch {package require tdom} err]} {
    alertnote "xml mode requires the 'tdom' package for full\
      functionality. This package is not available ($err)."
    unset err
    return
}
unset err

hook::register openHook xml::openHook xml
hook::register openHook xml::openHook xsl

# Improvement to [xml::openHook] if there is an XML parsing error,
# goto the error line.  (And instead of displaying the error in a
# stupid alertnote, from where wou can't compare it with the content
# of the document, display it either in an error window, or simply in
# the status bar.)

proc xml::openHook {name} {
    # [dom parse] does not apply to a DTD
    if { [file ext $name] == ".dtd" } {
	return
    }

    # Parse the document for the node names we want
    set text [getText -w $name [minPos -w $name] [maxPos -w $name]]
    if { ![string length $text] } {
	if {[win::IsFile $name filename]} {
	    set text [file::readAll $filename]
	}
	if { ![string length $text] } {
	    return
	}
    }

    set verboseParseErrorDisplay 1

    if { [catch {set doc [dom parse $text]} err] } {
	if { [regexp -- {line (\d+)} $err "" lineNumber] } {
	    file::gotoLine $name $lineNumber
	}
	if { $verboseParseErrorDisplay && [regexp -- {[\r\n]} $err] } {
	    new -n "* XML parsing error *" -m Text -info "$err" -shrink
	} else {
	    status::msg $err
	}
	return
    }

    set nodeNames {}
    foreach n [$doc getElementsByTagName *] {
	lappend nodeNames [$n nodeName]
    }
    $doc delete

    xml::setupColouringAndCompletions $name [lsort -dictionary -unique $nodeNames]
}


# Primitive [correctIndentation] for xml files: the principle is simply
# that if there is a (single) opening tag on a line without a closing tag,
# then the next line should be indented one tab further.  If there is a
# closing tag on a line (without any opening tag) then the line should be
# indented one tab less than the previous line.  This is a very rough
# model, but it gets it right in many cases.  Surely there are fancier
# ways to do this...
proc xml::correctIndentation {args} {
    win::parseArgs w pos {next ""}
    set pos [pos::lineStart -w $w $pos]
    if {[pos::compare -w $w $pos == [minPos -w $w]]} {
	return 0
    }

    global commentsArentSpecialWhenIndenting
    # Find last previous non-comment line and get its leading whitespace
    while 1 {
	if {[pos::compare -w $w $pos == [minPos -w $w]] \
	  || [catch {search -w $w -s -f 0 -r 1 -i 0 -m 0 \
	  {^[ \t]*[^ \t\r\n]} [pos::math -w $w $pos - 1]} lst]} {
	    # search failed at top of file
	    set line "#"
	    set lwhite 0
	    break
	}
	if {!$commentsArentSpecialWhenIndenting && \
	  [text::isInDoubleComment -w $w [lindex $lst 0] res]} {
	    set pos [lindex $res 0]
	} else {
	    set line [getText -w $w [lindex $lst 0] [pos::math -w $w \
	      [pos::nextLineStart -w $w [lindex $lst 0]] - 1]]
	    set lwhite [lindex [pos::toRowCol -w $w \
	      [pos::math -w $w [lindex $lst 1] - 1]] 1]
	    break
	}
    }

    set ia [text::getIndentationAmount -w $w]
    if { [regexp -- {^\s*<[^<!?>/][^<>/]*>\s*$} $line] } {
	incr lwhite $ia
    }
    set text [getText -w $w [pos::lineStart -w $w $pos] $pos]
    append text $next
    if { [regexp -- {^\s*</[^<>/]*>\s*$} $text] } {
	incr lwhite [expr {-$ia}]
    }
    return [expr {($lwhite > 0) ? $lwhite : 0}]
}

# Primitive 'electric closing angle bracket' proc: when typing a
# closing angle bracket, and if this is an opening tag, insert a
# matching closing tag and position the cursor between them.  The
# amount of whitespace is certainly debatable -- the current choice
# just happened to be what the author needed when he put together
# this quick hack...

proc xml::electricClosingAngleBracket {} {
    set pos [getPos]
    if { [catch {set opening [matchIt > $pos]}] } {
	typeText >
	return
    }

    set tag [getText [pos::math $opening + 1] $pos]
    typeText >
    if { [regexp -- {[<>]} $tag] } {
	# ?? The $tag string shouldn't include the open/close brackets...
	return
    } elseif { [regexp {^[!?]} $tag] } {
	# Don't insert closing tags for comments, meta-tags.
	return
    } elseif { [string is space $tag] } {
	# "Empty" tags are not allowed.
	status::msg "Warning: empty tags are illegal in xml code."
	return
    }
    if { [string range $tag end end] eq "/" } {
	::indentLine
	::carriageReturn
	::indentLine
	return
    }
    regexp -- {\w+} $tag tag
    ::indentLine
    insertText \r
    set pos [getPos]
    insertText "\r</${tag}>"
    ::indentLine
    goto $pos
    ::indentLine
}


# Callback function called by the parser when trying to resolve an external
# entity.  There is support for local caching of non-local DTDs: if the
# foreign DTD is on the internet, check first if there is a local cached
# copy.  Otherwise, retrieve the file, ask the user if she wants a local
# copy for later use, and in that case, save the file in the cache folder.
#
# (Eventually there should be a submenu in the Parse submenu, listing all
# cached DTDs, and with some items also for flushing the cache or
# refreshing it.  Selecting a DTD in the menu opens the local copy for
# inspection read-only.  The code for is submenu could probably easily
# be cloned from 'userMenu'...)
#
proc dtd::ExtEntityResolver {base systemId publicId} {
    set systemId [string trim $systemId]
    if { [regexp -- {^http:} $systemId] } {
	set cacheFilename [file join $::PREFS Cache DTD [filenameFromUrl $systemId]]
	if { [file readable $cacheFilename] } {
	    set fd [open $cacheFilename]
	    variable cachedDtdUsed 1
	    return [list channel $systemId $fd]
	} else {
	    # Use http to get the DTD
	    if { [catch {package require http}] } {
		error "http not available to retrieve $systemId"
	    }
	    set thisRetrieval [::http::geturl $systemId]
	    if { [::http::status $thisRetrieval] != "ok" } {
		error "Could not retrieve $systemId"
	    }
	    set txt [::http::data $thisRetrieval]
	    ::http::cleanup $thisRetrieval


	    switch -- [askyesno "Create local copy of $systemId?"] {
		"yes" {
		    file mkdir [file join $::PREFS Cache DTD]
		    set fd [open $cacheFilename w]
		    puts $fd $txt
		    close $fd
		}
		"no" {
		    # relax
		}
	    }
	    variable cachedDtdUsed 0
	    return [list string $systemId $txt]
	}

    } else {
	# It is just a file:
	set dtdfile [file join $base $systemId]
	if { [catch {set fd [open $dtdfile]}] } {
	    error "Failed to open external entity $dtdfile"
	}
	variable cachedDtdUsed 0
	return [list channel $systemId $fd]
    }

}

# Construct a reasonable filename from a URL
# (translating slashes into hyphens):
proc dtd::filenameFromUrl { url } {
    set filename [string trim $url]
    regsub {http://} $filename "" filename
    regsub -all "/" $filename "-" filename
    return $filename
}


# This proc is a trick to check the wellformedness of a DTD file. The usual parsing
# can't be applied directly to a DTD because the syntax is different from that 
# of an XML file. The trick here is to force a parser to parse a quasi empty 
# XML file which just calls the external DTD. In that case the parser 
# reports any syntax error found in the DTD itself.
proc dtd::checkExternalDTDfile {dtd} {  
    set parser [expat -externalentitycommand dtd::ExtEntityResolver \
      -baseurl "[file dir $dtd]" -paramentityparsing always]
    
    set dummyxml "<?xml version='1.0'?>
    <!DOCTYPE dumm SYSTEM \"[file tail $dtd]\">
    <dumm/>"
    if {[catch {$parser parse $dummyxml} errmsg]} {
	$parser free
	error $errmsg
    } 
    $parser free
}


# ×××× Colouring ×××× #

# XML
# ---
set XMLKeywords {
#FIXED #IMPLIED #PCDATA #REQUIRED ANY ATTLIST CDATA DOCTYPE ELEMENT EMPTY ENTITIES 
ENTITY ID IDREF IDREFS IGNORE INCLUDE NDATA NMTOKEN NMTOKENS NOTATION PUBLIC SYSTEM
}

# XSLT
# ----
set XSLTKeywords { 
xsl:analyze-string xsl:apply-imports xsl:apply-template xsl:apply-templates
xsl:attribute xsl:attribute-set xsl:call-template xsl:character-representation xsl:choose
xsl:comment xsl:copy xsl:copy-of xsl:decimal-format xsl:default-xpath-namespace xsl:element
xsl:example-element xsl:exclude-result-prefixes xsl:extension-element-prefixes xsl:fallback
xsl:for-each xsl:for-each-group xsl:function xsl:if xsl:import xsl:import-schema xsl:include
xsl:key xsl:message xsl:namespace xsl:namespace-alias xsl:number xsl:otherwise xsl:output
xsl:param xsl:preserve-space xsl:processing-instruction xsl:result xsl:result-document
xsl:sort xsl:sort-key xsl:strip-space xsl:stylesheet xsl:template xsl:text xsl:transform
xsl:type-annotation xsl:use-attribute-sets xsl:value-of xsl:variable xsl:version
xsl:when xsl:with-param
}

set XSLTFunctions { 
current document format-number generate-id system-property 
}

# XPath
# -----
set XPathFunctions { 
boolean ceiling concat contains count false floor id lang last normalize-space not
number position round starts-with string string-length substring substring-after
substring-before sum translate true
}

set XPathKeywords { 
ancestor ancestor-or-self and attribute attribute comment descendant
descendant-or-self div element following following-sibling id if item key 
mod namespace node or preceding preceding-sibling processing-instruction 
self text typeswitch
}

# XML Schema
# ----------
set XMLSchemaElements {
all annotation any anyAttribute appInfo attribute attributeGroup choice complexContent
complexType documentation element enumeration extension field group import include
key keyref length list maxInclusive maxLength minInclusive minLength pattern redefine
restriction schema selector sequence simpleContent simpleType union unique
}

set XMLSchemaAttributes {
abstract attributeFormDefault base block blockDefault default elementFormDefault
final finalDefault fixed form itemType maxOccurs memberTypes minOccurs mixed
name namespace nillable noNamespaceSchemaLocation processContents ref schemaLocation 
substitutionGroup targetNamespace type use xpath xsi:nil xsi:schemaLocation xsi:type
}


# Formatting Objects (XSL-FO)
# ---------------------------
# Removed the following which are too long: fo:conditional-page-master-reference, 
# fo:repeatable-page-master-alternatives, fo:repeatable-page-master-reference, 
# fo:single-page-master-reference 

set XSLFOKeywords {
fo:basic-link fo:bidi-override fo:block fo:block-container fo:character fo:color-profile 
fo:declarations fo:external-graphic fo:float fo:flow fo:footnote fo:footnote-body 
fo:initial-property-set fo:inline fo:inline-container fo:instream-foreign-object 
fo:layout-master-set fo:leader fo:list-block fo:list-item fo:list-item-body 
fo:list-item-label fo:marker fo:multi-case fo:multi-properties fo:multi-property-set 
fo:multi-switch fo:multi-toggle fo:page-number fo:page-number-citation fo:page-sequence 
fo:page-sequence-master fo:region-after fo:region-before fo:region-body fo:region-end 
fo:region-start fo:retrieve-marker fo:root fo:simple-page-master fo:static-content 
fo:table fo:table-and-caption fo:table-body fo:table-caption fo:table-cell fo:table-column 
fo:table-footer fo:table-header fo:table-row fo:title fo:wrapper 
}

# # # XPath expressions use these data types:
# node-set boolean number string

# # # XML attribute value types:
# boolean-expr char expr id ncname node-set-expr number-expr pattern prefix qname
# comprising prefixqname-but-notncnamelocal token uri-reference 

# # # XML Schema's Primitive datatypes
# string boolean decimal float double duration dateTime time date 
# gYearMonth gYear gMonthDay gDay gMonth hexBinary base64Binary 
# anyURI QName NOTATION 

# Must call this at least once.
regModeKeywords -b "<!--" "-->" -c $xmlmodeVars(commentColor) \
  -C -k $xmlmodeVars(keywordColor) xml $XMLKeywords
regModeKeywords -a -i "<" -i ">" -I $xmlmodeVars(tagColor) \
  -s $xmlmodeVars(stringColor) xml {}

# xml coloring
# ------------
set xml::count 0

proc xml::setupColouringAndCompletions {name words} {
    global xmlcmds xmlmodeVars
    variable count
    incr count
    set ct [win::getInfo $name colortags]
    lappend ct xml$count
    colorTagKeywords -C -k $xmlmodeVars(tagColor) xml$count $words
    
    win::setInfo $name colortags $ct
    
    # Store this information for completions.  It would be great
    # if we could also build up a series of node-structure contents
    # for completion templates.
    win::setInfo $name xmlcmds $words
}

# xsl coloring
# ------------
regModeKeywords -k $xslmodeVars(keywordColor) \
  -s $xslmodeVars(stringColor) xsl $XSLTKeywords
regModeKeywords -a -k $xslmodeVars(xslFunctionColor) xsl $XSLTFunctions


# dtd coloring
# ------------
regModeKeywords -k $dtdmodeVars(keywordColor) \
  -s $dtdmodeVars(stringColor) dtd $XMLKeywords



# Utility procs
# =============

proc xml::getTypeOfDoc {} {
    return [string trimleft [file ext [win::StripCount [win::Current]]] "."]
}

## 
 # -------------------------------------------------------------------------
 #  Invokes an external command-line application for XSLT processing.
 # -------------------------------------------------------------------------
 ##
proc xslt::externalTransform {xmlfile xslfile} {
   global env
   variable Params
   status::msg {Starting external Xslt É}
   set Params(outmethod) "output"		;# default to ".output"
   regsub {([^:]*):/} $xmlfile {} xmlfile
   regsub {([^:]*):/} $xslfile {} xslfile
   set wd [pwd]
   cd $env(SYSTEMDRIVE)
   set result \
     [::xserv::invoke -foreground Xslt -xslfile $xslfile -xmlfile $xmlfile]
   cd $wd
   status::msg {É external Xslt done.}
   return $result
}

## 
 # -------------------------------------------------------------------------
 #  Performs internal (tDOM-based) XSLT processing.
 # -------------------------------------------------------------------------
 ##
proc xslt::Transform {xmltxt xslfile} {
    variable Params
    set Params(outmethod) ""
    set fid [open $xslfile r]
    set xsltxt [read $fid]
    close $fid
    set xslt [dom parse -keepEmpties $xsltxt]
    set xml [dom parse -keepEmpties $xmltxt]
    set xmlroot [$xml documentElement]
    $xmlroot xslt $xslt resultDoc
    set resultroot [$resultDoc documentElement]
    set result [$resultroot asXML]
    $xml delete
    $xslt delete
    $resultDoc delete
    # Let's try to be clever and see if there is an xsl:output element, 
    # in the xslt file, specifying an output method. It will be used to 
    # determine the right extension for the transformed file.
    xml::attributesFromElement $xsltxt xsl:output arr
    if {[info exists arr(method)]} {
	set Params(outmethod) $arr(method)
    } else {
	set Params(outmethod) ""
    }
    if {[info exists arr(encoding)]} {
	set Params(outencoding) $arr(encoding)
    } else {
	set Params(outencoding) "utf-8"
    }
    if {$Params(outroot) ne "html"} {
	set xsltoutput [$resultroot asXML]
    } elseif {$Params(outmethod) eq "text"} {
	set xsltoutput [$resultroot asText]
    } else {
	set xsltoutput [$resultroot asHTML]
    }
    $xml delete
    $xslt delete
    $resultDoc delete
    set result ""
    # construct XML declaration for the output document
    if {$Params(outmethod) eq "xml" \
      || ($Params(outmethod) eq "" && $Params(outroot) ne "html")} {
	append result "<?xml version=\"1.0\""
	append result " encoding=\"$Params(outencoding)\""
	append result "?>"
    }
    append result $xsltoutput
    return $result
}   

## 
 # -------------------------------------------------------------------------
 #  Constructs an appropriate file extension for an XSLT output document.
 # -------------------------------------------------------------------------
 ##
proc xslt::transformedExtension {} {
   variable Params
   if {$Params(outmethod) eq "xml" \
     || ($Params(outmethod) eq "" && $Params(outroot) ne "html")} {
      set result "_out.xml"		;# don't overwrite XML input file
   } elseif {$Params(outmethod) eq "" && $Params(outroot) eq "html"} {
      set result ".html"
   } else {
      set result ".$Params(outmethod)"
   }
   return $result
}

## 
 # -------------------------------------------------------------------------
 #  Searches 'text' for element 'elem' and returns its attributes in array 
 #  'arr'.  If there is an attribute "foo" with value "bar", the value of 
 #  'arr(foo)' will be set to "bar".  Optional 4th arg is an offset to start
 #  position for the search (0 by default).  Returns the found positions for
 #  the entire tag, or nothing if the tag was not found.
 # -------------------------------------------------------------------------
 ##
proc xml::attributesFromElement {text elem arr {start 0}} {
    upvar $arr localarr
    if {[regexp -start $start -indices -- "<$elem \[^>\]*>" $text opening]} {
	eval set txt \[string range [list $text] $opening\]
	regsub "<$elem " $txt "" txt
	regsub "/?>" $txt "" txt
	regsub -all {[ \t]+=[ \t]+} $txt "=" txt
	foreach item $txt {
	    foreach {attr val} [split $item =] {
		set localarr($attr) [string trim $val \"]
	    }
	}
	return $opening
    } else {
	error "Couldn't find element $elem"
    }
}

# ===========================================================================
# 
# .