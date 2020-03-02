## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML and CSS mode - tools for editing HTML and CSS
 # 
 #  FILE: "htmlcssInit.tcl"
 #                                    created: 99-07-15 21.54.38 
 #                                last update: 08/04/2005 {01:04:52 PM} 
 #  Author: Johan Linde
 #  E-mail: <alpha_www_tools@go.to>
 #     www: <http://go.to/alpha_www_tools>
 #  
 # Version: 3.2 and 2.2
 # 
 # Copyright 1996-2005 by Johan Linde
 #  
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
 # 
 # ###################################################################
 ##

#===============================================================================
# This file initialises a bunch of things, much of which are used in both CSS
# and HTML modes.
#===============================================================================

proc htmlcssInit.tcl {} {}

# HTML mode version
set htmlVersion 3.2
set html::PrefsFolder [file join $PREFS HTML]

namespace eval html {}
namespace eval css  {}

#===============================================================================
# ×××× Update preferences ×××× #
#===============================================================================

# Make sure that there are no trailing colons in the folder prefs
if {[info exists HTMLmodeVars(homePages)]} {
	for {set __tmp 0} {$__tmp < [llength $HTMLmodeVars(homePages)]} {incr __tmp} {
		set __pg [lindex $HTMLmodeVars(homePages) $__tmp]
		set __pg [lreplace $__pg 0 0 [file join [file dir [lindex $__pg 0]] [file tail [lindex $__pg 0]]]]
		if {[llength $__pg] == 5} {
			set __pg [lreplace $__pg 4 4 [file join [file dir [lindex $__pg 4]] [file tail [lindex $__pg 4]]]]
		}
		set HTMLmodeVars(homePages) [lreplace $HTMLmodeVars(homePages) $__tmp $__tmp $__pg]
	}
}
if {[info exists HTMLmodeVars(FTPservers)]} {
	for {set __tmp 0} {$__tmp < [llength $HTMLmodeVars(FTPservers)]} {incr __tmp} {
		set __pg [lindex $HTMLmodeVars(FTPservers) $__tmp]
		set __pg [lreplace $__pg 0 0 [file join [file dir [lindex $__pg 0]] [file tail [lindex $__pg 0]]]]
		set HTMLmodeVars(FTPservers) [lreplace $HTMLmodeVars(FTPservers) $__tmp $__tmp $__pg]
	}
}
if {[info exists HTMLmodeVars(templateFolders)]} {
	for {set __tmp 0} {$__tmp < [llength $HTMLmodeVars(templateFolders)]} {incr __tmp} {
		set __pg [lindex $HTMLmodeVars(templateFolders) $__tmp]
		set __pg [lreplace $__pg 0 0 [file join [file dir [lindex $__pg 0]] [file tail [lindex $__pg 0]]]]
		set __pg [lreplace $__pg 1 1 [file join [file dir [lindex $__pg 1]] [file tail [lindex $__pg 1]]]]
		set HTMLmodeVars(templateFolders) [lreplace $HTMLmodeVars(templateFolders) $__tmp $__tmp $__pg]
	}
}
unset -nocomplain __tmp __pg

if {![info exists html::PrefsVersion] || ${html::PrefsVersion} < $htmlVersion} {
	catch {htmlPrefsUpdater.tcl}
}

#===============================================================================
# ×××× Menu icons ×××× #
#===============================================================================

set htmlIconTxt {"Netscape Navigator 3" "Netscape Navigator 4" "Netscape Communicator" 
"Internet Explorer" Cyberdog iCab MacLynx Mosaic Mozilla Opera Safari OmniWeb Camino}
set htmlIcons {¥135 ¥293 ¥294 ¥295 ¥281 ¥297 ¥296 ¥942 ¥306 ¥305 ¥209 ¥210 ¥211}

# Menu icons
newPref v htmlMenuIcon ¥294 HTML
newPref v htmlUtilsMenuIcon ¥281 HTML

if {$HTMLmodeVars(htmlMenuIcon) == $HTMLmodeVars(htmlUtilsMenuIcon)} {
	foreach _tmp $htmlIcons {
		if {$HTMLmodeVars(htmlMenuIcon) != $_tmp} {
			set HTMLmodeVars(htmlUtilsMenuIcon) $_tmp
			prefs::modifiedModeVar htmlUtilsMenuIcon HTML
			break
		}
	}
}

set htmlMenu $HTMLmodeVars(htmlMenuIcon)
set htmlUtilsMenu $HTMLmodeVars(htmlUtilsMenuIcon)

#===============================================================================
# ×××× Mode variables ×××× #
#===============================================================================

# Set HTML element names in lower case
newPref f useLowerCase 0 CSS

# Line width
newPref v fillColumn 75 HTML
newPref v leftFillColumn 0 HTML
# word breaking and word wrapping
newPref v wordBreak {\w+} HTML
newPref v wrapBreak {[\w_]+} HTML
newPref v wrapBreakPreface {([^\w_])} HTML
newPref var lineWrap	1 HTML

# The content of these elements is indented
newPref v indentElements {DIR DL MENU OL TABLE TR UL} HTML
# The content of these elements with optional closing tag in HTML are is indented in XHTML
newPref f indentInXHTML {} HTML

# browsers
if {![info exists browserSig] && [catch {file::getSig [icGetPref -t 1 Helper¥http]} browserSig]} {set browserSig MSIE}
# Browser signatures
newPref v browsers {MSIE MOSS MOZZ CHIM sfri OWEB OPRA iCAB} HTML

newPref v prefixString	"<!-- " HTML
newPref v suffixString	" -->" HTML

# Template folders.
newPref v templateFolders {} HTML
# Tag color
newPref v tagColor blue HTML
# Attribute color
newPref v attributeColor magenta HTML
# Simple coloring?
newPref f simpleColoring 0 HTML
# Always color immediately when typing
newPref f ColorImmediately [expr {$alpha::platform == "tk"}] HTML
# Update META DATE?
newPref f updateMetaDate 0 HTML
# Should elements be lower case?
newPref f useLowerCase	0 HTML
# Should ¥'s be inserted?
newPref	f useTabMarks	1 HTML
# Rename/remove old preferences.
prefs::renameOld HTMLmodeVars(anarchieMirrorWarn) HTMLmodeVars(interarchyMirrorWarn)

# Use the optional closing tag of these elements
newPref v optionalClosing {P TR TD TH} HTML
# Active window sets
newPref v activeTargetSets {} HTML
# Add new target windows to this set
newPref v addTargetsTo {} HTML
# A list of content types
newPref v contenttypes {text/css text/javascript multipart/form-data} HTML
# A list of link types
newPref v linktypes {stylesheet alternate start next prev contents index glossary copyright 
chapter section subsection appendix help bookmark} HTML
# When browser is launched, should it be brought to front?
newPref	f browseInForeground	1 HTML
# Save without asking when sending file to browser?
newPref f saveWithoutAsking 0 HTML
# List of commonly used character entities
newPref v commonChars {"less than" "greater than" "ampersand" "nonbreak space"} HTML
# Never ask about extensions?
newPref f hideExtensions 0 HTML
# Never ask about deprecated elements and attributes?
newPref f hideDeprecated 0 HTML
# Attributes globally not asked about at first
newPref v dontaskforAttributes {} HTML
# Attributes globally never asked about
newPref v neveraskforAttributes {} HTML
# Attributes globally always asked about
newPref v alwaysaskforAttributes {} HTML
# Beep when asking for attributes in the status bar?
newPref f promptNoisily 1 HTML
# Input from dialog windows or status bar?
newPref f useBigWindows 1 HTML
# Change attributes in dialog windows or status bar?
newPref f changeInBigWindows 1 HTML
# Create new file if missing without asking when cmd-double-clicking a link.
newPref f createWithoutAsking 0 HTML
# Cmd-double-click on non text file link opens file?
newPref f openNonTextFile 1 HTML
# Return on non text file in home page window opens file?
newPref f homeOpenNonTextFile 1 HTML
# Check anchors in links?
newPref f checkAnchors 1 HTML
# Case sensistive link checking?
newPref f caseSensitive 0 HTML
# Check links with Big Brother?
newPref f useBigBrother 0 HTML
newPref f checkInFront 1 HTML
newPref f useBBoptions 1 HTML
newPref f ignoreRemote 0 HTML
newPref f ignoreLocal 0 HTML
# FTP servers
newPref v FTPservers {} HTML
# Last modified string
newPref v lastModified "Last modified" HTML
# 'Insert include tags' only inserts tags, and not the file?
newPref f includeOnlyTags 1 HTML
# Preserve line-endings when updating includes?
newPref f preserveLineEndings 0 HTML
# Color JavaScript keywords?
newPref f JavaScriptColoring 0 HTML
# Color of JavaScript keywords
newPref v JavaScriptColor	magenta HTML
# Color of strings
newPref v stringColor green HTML
# Color of JavaScript comments
newPref v JavaCommentColor red HTML
# Color CSS keywords?
newPref f CSSColoring 0 HTML
# Color of CSS keywords
newPref v CSSColor cyan HTML
# Home pages.
newPref v homePages {} HTML
# Media types
newPref v mediatypes {aural braille embossed handheld print projection screen tty tv all} HTML
# Active color sets
newPref v activeColorSets {} HTML
# Active URL sets
newPref v activeURLSets {} HTML
# Add new URLs to this set
newPref v addURLsTo {} HTML
# Explain types prefs window.
newPref f explainTypePrefs 1 HTML
# Auto-indent when typing >
newPref f electricGreater 1 HTML
# Warn before mirroring with Interarchy
newPref f interarchyMirrorWarn 1 HTML
# Use old style "Comment Paragraph"
newPref f oldStyleCommPara 0 HTML
# Open attribute dialog after completing?
newPref f attrDialogAfterCompleting 1 HTML
# Adjust indentation when inserting a template in the beginning of a line?
newPref f adjustIndentation 1 HTML
# Last doctype used in New dialog
newPref v lastDocType "HTML 4.01 Transitional" HTML
# Last doctype used in New dialog for frames
newPref v lastFrameDocType "HTML 4.01 Frameset" HTML
# Extra space in empty element tags
newPref f extraSpace 1 HTML
# To automatically perform context relevant formatting after typing a left
# or right curly brace, turn this item on||To have the brace keys produce a
# brace without additional formatting, turn this item off
newPref flag electricBraces    1 HTML
# To automatically perform context relevant formatting after typing a
# semicolon, turn this item on||To have the semicolon key produce a
# semicolon without additional formatting, turn this item off
newPref flag electricSemicolon 1 HTML
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn    1 HTML

#===============================================================================
# ×××× Other variables ×××× #
#===============================================================================

# These elements have optional closing tags
set html::OptionalClosingTags {COLGROUP DD DT LI OPTION P THEAD TBODY TFOOT TR TH TD}
# These elements can be in document HEAD.
set html::HeadElements {BASE ISINDEX LINK META STYLE SCRIPT OBJECT}
# These elements are plug-ins.
set html::Plugins {EMBED}
# These elements do not appear in the strict DTD
set html::NotInStrict {APPLET FONT CENTER DIR MENU STRIKE S U BASEFONT ISINDEX NOFRAMES IFRAME FRAMESET FRAME}
# These elements are deprecated
set html::DeprecatedElems {APPLET FONT CENTER DIR MENU STRIKE S U BASEFONT ISINDEX}
# These elements do not appear in transitional DTD
set html::NotInTransitional {FRAME FRAMESET}
# These elements are extensions to HTML
set html::HTMLextensions {BGSOUND BLINK EMBED ILAYER KEYGEN LAYER MARQUEE MULTICOL NOBR NOEMBED NOLAYER SERVER SPACER WBR}
# These elements are only used in XHTML 1.1
set html::XHTML11Only {RB RBC RP RT RTC RUBY}
# Formatting styles
lappend html::formattingStyles NO-FORMATTING C-STYLE-FORMATTING
set html::indentLineProcs(NO-FORMATTING) {}
set html::formatBlockProcs(NO-FORMATTING) {}
set html::correctIndentProc(NO-FORMATTING) {}
set html::indentLineProcs(C-STYLE-FORMATTING) {::indentLine}
set html::formatBlockProcs(C-STYLE-FORMATTING) {::indentRegion}
set html::correctIndentProc(C-STYLE-FORMATTING) {::correctBracesIndentation}

foreach __vvv [array names HTMLmodeVars] {
	set HTMLmodeVarsInvisible($__vvv) 1
}

unset __vvv

# Comment characters
proc html::SetCommentCharacters {} {
	global HTMLmodeVars HTML::commentCharacters
	# changed for new 'isIn' functionality.
	set HTML::commentCharacters(General) ""
	if {$HTMLmodeVars(oldStyleCommPara)} {
		set HTML::commentCharacters(Paragraph) [list "<!--" "-->" "|" ]
	} else {
		set HTML::commentCharacters(Paragraph) [list "<!--" "-->" " | " ]
	}
	set HTML::commentCharacters(Box) [list "<!--" 4 "-->" 3 "|" 3]
}

html::SetCommentCharacters

#
# Internal Globals
#
# Watch out! Large comments crashes Alpha!!!
set css::CommentRegexp {/\*[^*]*\*+([^/][^*]*\*+)*/}
set html::CommentRegexp {<!--([^-]|-[^-])*-->}
set htmlCurSel	""
set htmlIsSel	0
set htmlNumBbthChecking 0
set html::HideDeprecated 0
set html::HideExtensions 0
set html::HideFrames 0
set html::xhtml 0
set html::xhtmlversion 0

proc css::DisableEnable {onoff} {
	global cssMenu
	catch {
		enableMenuItem -m $cssMenu "@Charset" $onoff
		enableMenuItem -m $cssMenu "@Import" $onoff
	}
	return
}

proc css::DisableEnablePrefs {onoff} {
	global cssMenu
	catch {
		enableMenuItem -m $cssMenu "PreferencesÉ" $onoff
	}
	return
}

proc CSS::correctIndentation {args} {
	eval ::correctBracesIndentation $args
}

#===============================================================================
# ×××× Colors for background, text, links etc. ×××× #
#===============================================================================

# Predefined colors
set css::Colors {ActiveBorder ActiveCaption AppWorkspace Background ButtonFace ButtonHighlight
ButtonShadow ButtonText CaptionText GrayText Highlight HighlightText InactiveBorder
InactiveCaption InactiveCaptionText InfoBackground InfoText Menu MenuText Scrollbar
ThreeDDarkShadow ThreeDFace ThreeDHighLight ThreeDLightShadow ThreeDShadow Window
WindowFrame WindowText}

proc html::NewColor {var val } {
	global html::ColorName
	global html::ColorNumber
	set html::ColorName($var) $val 
	set html::ColorNumber($val) $var
}
html::NewColor black	"#000000"
html::NewColor silver	"#C0C0C0"
html::NewColor gray		"#808080"
html::NewColor white	"#FFFFFF"
html::NewColor maroon	"#800000"
html::NewColor red		"#FF0000"
html::NewColor purple	"#800080"
html::NewColor fuchsia	"#FF00FF"
html::NewColor green	"#008000"
html::NewColor lime		"#00FF00"
html::NewColor olive	"#808000"
html::NewColor yellow	"#FFFF00"
html::NewColor navy		"#000080"
html::NewColor blue		"#0000FF"
html::NewColor teal		"#008080"
html::NewColor aqua		"#00FFFF"

# A list of colours
set html::basicColors [lsort [array names html::ColorName]]
rename html::NewColor ""
html::ReadActiveColorSets
html::ReadActiveCacheSets URLs
html::ReadActiveCacheSets Targets

#===============================================================================
# ×××× Cmd-Double-click ×××× #
#===============================================================================

proc HTML::DblClick {from to} {
	global mode
	
	if {[catch {html::FollowLink $from}] && $mode == "HTML"} { 
		if {![catch {search -s -f 0 -r 1 -i 1 -m 0 {[ \t\r\n](FILE|PATH|INCLPATH)=\"[^\"]+\"} $from} res] && [pos::compare [lindex $res 1] > $from]} {
			regexp -nocase {(FILE|PATH|INCLPATH)=\"[^\"]+\"} [eval getText $res] fil
			set fil [html::ResolveInclPath $fil [html::WhichInclFolder [set win [html::StrippedFrontWindowPath]]] [file dirname $win]]
			if {[file exists $fil]} {
				edit -c $fil
			} else {
				beep
				status::msg "File not found."
			}
		} elseif {[html::IsInContainer SCRIPT]} {
			JScr::DblClick $from $to
		} elseif {[html::IsInContainer STYLE]} {
			global css::IsDescriptor
			if {![catch {search -s -f 0 -r 1 -m 0 {[ \t\r\n]+[^ \t\r\n;:]+[ \t\r\n]*:} $from} res] && [pos::compare [lindex $res 1] >= $to]} {
				set css::IsDescriptor [css::IsInAtRule font-face]
				css::Dialog [string tolower [string trim [eval getText $res] " \t\r\n:"]]
			}
		} elseif {![html::RevealColor 1]} {
			html::EditTag 2
		}
	}
}
