## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode: tools for editing HTML documents
 # 
 #  FILE: "htmlMode.tcl"
 #                                    created: 95-04-26 14.49.04 
 #                                last update: 01/09/2006 {02:03:18 PM} 
 #  Author: Johan Linde
 #  E-mail: <alpha_www_tools@go.to>
 #     www: <http://go.to/alpha_www_tools>
 #  
 # Version: 3.2
 # 
 # version 0.24 (16 July 95) by Scott W. Brim <swb1@cornell.edu>
 # version 1.0 -- 3.2b1 (July 2003) by Johan Linde <alpha_www_tools@go.to>
 #
 # Copyright 1996-2006 by Johan Linde
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
# This is the main file for HTML mode
#===============================================================================

alpha::mode HTML 3.2b1 htmlMenu \
  {*.html *.htm *.shtml} {
	cssMenu htmlMenu htmlUtilsMenu
} {
	addMenu htmlMenu
	addMenu htmlUtilsMenu
	hook::register keyboard {Bind '.' <o> {html::electricGreater} HTML} "Canadian - CSA"
	hook::register removekeyboard {unBind '.' <o> {} HTML} "Canadian - CSA"
	hook::register keyboard {Bind '.' <o> {html::electricGreater} HTML} "Canadian - ISO"
	hook::register removekeyboard {unBind '.' <o> {} HTML} "Canadian - ISO"
	# Add more options to the 'New Document' prompt
	;proc newHTMLDoc {} {htmlMenu; html::NewDocument}
	;proc newHTMLDocWithContent {} {htmlMenu; html::NewwithContent}
	;proc newHTMLDocWithFrames {} {htmlMenu; html::NewDoc.withFrames}
	set {newDocTypes(New HTML Doc)} newHTMLDoc
	set {newDocTypes(New HTML Doc With Content)} newHTMLDocWithContent
	set {newDocTypes(New HTML Doc With Frames)} newHTMLDocWithFrames
	set {newDocTypesRequire(New HTML Doc With Content)} 1
} uninstall {
	if {[askyesno "This will uninstall both HTML and CSS modes. Continue?"] == "no"} {return}
	catch {file delete [file join $HOME Tcl Completions HTMLCompletions.tcl]}
	catch {file delete [file join $HOME Tcl Completions CSSCompletions.tcl]}
	catch {file delete [file join $HOME Help "CSS Help.tcl"]}
	catch {file delete [file join $HOME Help "HTML Help.tcl"]}
	catch {file delete -force [file join $HOME Help "HTML Help"]}
	set folder [procs::find htmlMenu]
	if {$folder != ""}Ê{
		set folder [file dirname $folder]
		if {[file exists $folder]} {catch {file delete -force $folder}}
	}
} maintainer {
	"Johan Linde" <alpha_www_tools@go.to> <http://go.to/alpha_www_tools>
} description {
	Supports the editing of [H]yper[T]ext [M]arkup [L]anguage files
} help {
	file "HTML Help"
}

# called by Alpha to load HTML in.  
proc htmlMenu {} {}
proc htmlUtilsMenu {} {}

namespace eval html {}
namespace eval css {}

if {${alpha::macos}} {
    # Register eventhandler for Big Brother events
    tclAE::installEventHandler Bbth Chkd html::BbthChkdHandler 
}

# Used by fillParagraph
set htmlParaCommands {html|head|title|body|h[1-6]|p|div|blockquote|center|address|pre|multicol}
append htmlParaCommands {|br|hr|wbr|basefont|ul|ol|li|dir|menu|dl|dd|dt|form|input}
append htmlParaCommands {|select|option|textarea|caption|table|tr|frameset|frame|noframes}
append htmlParaCommands {|map|area|applet|param|script|noscript|layer|ilayer|nolayer|base|link|meta|isindex}
append htmlParaCommands {|col|colgroup|marquee|object|thead|tbody|tfoot}
append htmlParaCommands {|bdo|ins|del|fieldset|legend|button|optgroup}

# Used by paragraph code
set HTML::startPara {^[ \t]*$|</?(}
append HTML::startPara $htmlParaCommands {)([ \t\r]+[^>]*>|>)}
set HTML::endPara {^[ \t]*$|</?(}
append HTML::endPara $htmlParaCommands {)([ \t\r\n]+[^>]*>|>)}

# Load other HTML mode files.
foreach __tmp {htmlcssInit htmlEntities htmlMenuDefinition html40 htmlContextualMenu cssProperties} {
	if { [catch {eval ${__tmp}.tcl}] } {
		beep
		alertnote "Loading of ${__tmp}.tcl failed"
		return
	}
}
unset -nocomplain __tmp

#
# Color support
#

proc html::Colorizing {{changing 0}} {
 	global HTMLmodeVars HTMLwords html::formattingStyles css::Property css::Descriptor
 	
 	set HTMLKeyWords {}
	if {[info exists HTMLwords]} {set HTMLKeyWords $HTMLwords}

	if {!$HTMLmodeVars(simpleColoring)} {
		# All HTML elements
		set allHTMLwords {A ABBR ACRONYM ADDRESS APPLET AREA B BASE 
		BASEFONT BDO BGSOUND BIG BLINK BLOCKQUOTE BODY BR BUTTON CAPTION 
		CENTER CITE CODE COL COLGROUP DD DEL DFN DIR DIV DL DT EM EMBED 
		FIELDSET FONT FORM FRAME FRAMESET H1 H2 H3 H4 H5 H6 HEAD HR HTML I 
		IFRAME ILAYER IMG INPUT INS ISINDEX KBD KEYGEN LABEL LAYER LEGEND 
		LI LINK MAP MARQUEE MENU META MULTICOL NOBR NOEMBED NOFRAMES 
		NOLAYER NOSCRIPT OBJECT OL OPTGROUP OPTION P PARAM PRE Q RB RBC RP RT RTC RUBY S SAMP 
		SCRIPT SELECT SERVER SMALL SPACER SPAN STRIKE STRONG STYLE SUB SUP TABLE 
		TBODY TD TEXTAREA TFOOT TH THEAD TITLE TR TT U UL VAR WBR}
	

		# All attributes
		set attributeWords {
		ABBR= ABOVE= ACCEPT-CHARSET= ACCEPT= ACCESSKEY= ACTION= ALIGN=
		ALINK= ALT= ARCHIVE= AXIS= BACKGROUND= BEHAVIOR= BELOW= BGCOLOR=
		BGPROPERTIES= BORDER= BORDERCOLOR= BORDERCOLORDARK=
		BORDERCOLORLIGHT= CELLPADDING= CELLSPACING= CHALLENGE= CHAR=
		CHAROFF= CHARSET= CHECKED CITE= CLASS= CLASSID= CLEAR= CLIP= CODE=
		CODEBASE= CODETYPE= COLOR= COLS= COLSPAN= COMPACT CONTENT= CONTROLS
		COORDS= DATA= DATETIME= DECLARE DEFER DIR= DIRECTION= DISABLED
		DYNSRC= ENCTYPE= FACE= FOR= FRAME= FRAMEBORDER= FRAMESPACING=
		GUTTER= HEADERS= HEIGHT= HIDDEN= HREF= HREFLANG= HSPACE=
		HTTP-EQUIV= ID= ISMAP LABEL= LANG= LANGUAGE= LEFT= LEFTMARGIN=
		LINK= LONGDESC= LOOP= LOWSRC= MARGINHEIGHT= MARGINWIDTH= MAXLENGTH=
		MAYSCRIPT MEDIA= METHOD= MULTIPLE NAME= NOHREF NORESIZE NOSHADE
		NOWRAP OBJECT= PAGEX= PAGEY= PALETTE= PLUGINSPAGE= PLUGINSURL=
		POINT-SIZE= PROFILE= PROMPT= RBSPAN= READONLY REL= REV= ROWS= ROWSPAN=
		RULES= SCHEME= SCOPE= SCROLLAMOUNT= SCROLLDELAY= SCROLLING=
		SELECTED SHAPE= SIZE= SPAN= SRC= STANDBY= START= STYLE= SUMMARY=
		TABINDEX= TARGET= TEXT= TITLE= TOP= TOPMARGIN= TYPE= UNITS= USEMAP=
		VALIGN= VALUE= VALUETYPE= VISIBILITY= VLINK= VSPACE= WIDTH= WRAP=
		XML:LANG= XML:SPACE= XMLNS= Z-INDEX=
		}
		
		# JavaScript keywords.
		set JavaScriptWords {break case continue default delete do export for import in 
		function if else new return switch this typeof var void while with true false 
		onAbort= onBlur= onChange= onClick= onDblClick= onError= onFocus= 
		onKeyDown= onKeyPress= onKeyUp= onLoad= onMouseDown= onMouseMove= 
		onMouseOut= onMouseOver= onMouseUp= onReset= onSelect= onSubmit= onUnload=}
		# Custom elements
		if {[html::AdditionsExists]} {
			catch {html::ReadCache "Additions coloring cache" 1}
		}
		
		foreach elem $allHTMLwords {
			if {$HTMLmodeVars(ColorImmediately)} {
				lappend allHTMLkeywords $elem
			} else {
				lappend allHTMLkeywords "<${elem}" "/${elem}"
			}
		}
		
		lappend allHTMLkeywords ?xml /> ?>

		lappend attributeWords FILE= FORM= INCLPATH= PATH= DEPTH= VERSION= ENCODING=
		
		if {$HTMLmodeVars(ColorImmediately)} {
			regsub -all = $attributeWords "" attributeWords
			regsub -all = $JavaScriptWords "" JavaScriptWords
		}
		
		# CSS keywords
		regsub -all {([a-z])( )} "[concat [array names css::Property] [array names css::Descriptor]] " {\1:\2} CSSwords
		regsub -all {(@[a-z]+):} $CSSwords {\1} CSSwords
		lappend CSSwords @font-face important active after before first first-child first-letter \
		first-line focus hover lang left link right visited
	
		if {!$changing} {
			regModeKeywords -i "<" -i ">" -I $HTMLmodeVars(tagColor) \
			  -s $HTMLmodeVars(stringColor)  -b "/*" "*/" -e "//" HTML {}
		}
		if {$HTMLmodeVars(JavaScriptColoring) || $HTMLmodeVars(CSSColoring)} {
			set col $HTMLmodeVars(JavaCommentColor)
		} else {
			set col none
		}
		regModeKeywords -a -c $col HTML
		if {$HTMLmodeVars(JavaScriptColoring)} {
			set col $HTMLmodeVars(JavaScriptColor)
		} else {
			set col none
		}
		regModeKeywords -a -k $col HTML $JavaScriptWords
		if {$HTMLmodeVars(CSSColoring)} {
			set col $HTMLmodeVars(CSSColor)
		} else {
			set col none
		}
		regModeKeywords -a -k $col HTML $CSSwords
		regModeKeywords -a -k $HTMLmodeVars(tagColor) \
		HTML [concat $HTMLKeyWords $allHTMLkeywords]
		regModeKeywords -a -k $HTMLmodeVars(attributeColor) HTML $attributeWords
		set extraWords {"<!--" "-->" "#INCLUDE" "/#INCLUDE"
		"#LASTMODIFIED" "/#LASTMODIFIED" "#DOCINDEX" "/#DOCINDEX"}
		foreach style ${html::formattingStyles} {
			lappend extraWords "#$style" "/#$style"
		}
		regModeKeywords -a -k $HTMLmodeVars(JavaCommentColor) HTML $extraWords
	} else {
		regModeKeywords -b "<" ">" -c $HTMLmodeVars(tagColor) \
		-k $HTMLmodeVars(tagColor) HTML $HTMLKeyWords
	}
}

# Change color when a color variable is changed.
proc html::ChangeColorizing {flag shownAlert} {
	global HTMLmodeVars
	set msg 0
	switch -glob $flag {
		simpleColoring -
		ColorImmediately {
			html::Colorizing
			set msg 1
		}
		JavaScriptColoring -
		attributeColor -
		CSSColoring {
			if {!$HTMLmodeVars(simpleColoring)} {
				html::Colorizing 1
			}
		}
		tagColor {
			if {$HTMLmodeVars(simpleColoring)} {
				regModeKeywords -a -c $HTMLmodeVars(tagColor) HTML
			} else {
				regModeKeywords -a -i "<" -i ">" -I $HTMLmodeVars(tagColor) HTML
				html::Colorizing 1
			}
		}
		JavaScriptColor {
			if {$HTMLmodeVars(JavaScriptColoring) && !$HTMLmodeVars(simpleColoring)} {
				html::Colorizing 1
			}
		}
		JavaCommentColor {
			if {($HTMLmodeVars(JavaScriptColoring) || $HTMLmodeVars(CSSColoring)) && !$HTMLmodeVars(simpleColoring)} {
				regModeKeywords -a -c $HTMLmodeVars(JavaCommentColor) HTML
			}
		}
		CSSColor {
			if {$HTMLmodeVars(CSSColoring) && !$HTMLmodeVars(simpleColoring)} {
				html::Colorizing 1
			}
		}	
		stringColor {
			if {!$HTMLmodeVars(simpleColoring)} {
				regModeKeywords -a -s $HTMLmodeVars(stringColor) HTML
			}
		}
	}
	refresh
	if {$msg && !$shownAlert} {
		alertnote "Coloring will not change until you switch to another window."
		set shownAlert 1
	}
	return $shownAlert
}

trace variable browserSig w html::ToggleBrowser2

# Add browsers to Browsers menu.
menu::insert Browsers items end "(-"
if {![lcontains HTMLmodeVars(browsers) $browserSig]} {
	lappend HTMLmodeVars(browsers) $browserSig
	prefs::modifiedModeVar browsers HTML
}
set html::Browsers {}
set _tmpbrws {}
foreach _brws $HTMLmodeVars(browsers) {
	if {![catch {nameFromAppl $_brws} _name]} {
		set _name [file tail $_name]
		regsub {\.app$} $_name "" _name
		lappend html::Browsers [list $_brws $_name]
		lappend _tmpbrws $_brws
		html::AddBrowserItem $_name $_brws
	} else {
		prefs::modifiedModeVar browsers HTML
	}
}
set HTMLmodeVars(browsers) $_tmpbrws
catch {unset _tmpbrws _brws _name}

html::SetDis
html::BuildWholeMenu htmlMenu
html::BuildWholeMenu htmlUtilsMenu
html::Colorizing
# Check that all home page folders exist.
set tmp_notfind ""
foreach tmp_hp $HTMLmodeVars(homePages) {
	if {![file exists [lindex $tmp_hp 0]] || ![file isdirectory [lindex $tmp_hp 0]]} {
		alertnote "Can't find the folder for the home page [lindex $tmp_hp 1][lindex $tmp_hp 2]"
		set tmp_notfind "[lindex $tmp_hp 1][lindex $tmp_hp 2]"
	}
}
if {$tmp_notfind != ""} {html::HomePages $tmp_notfind}
unset -nocomplain tmp tmp_notfind tmp_hp

# Define a couple of key bindings.
if {[file exists [file join ${html::PrefsFolder} "HTML entity keys"]]} {
	source [file join ${html::PrefsFolder} "HTML entity keys"]
} else {		
	if {![info exists htmlEntityKeys([list less than])]} {
		set htmlEntityKeys([list less than]) "<U<B<I/,"
		set htmlEntityKeysProc([list less than]) {html::InsertCharacter "less than"}
	}
	if {![info exists htmlEntityKeys([list greater than])]} {
		set htmlEntityKeys([list greater than]) "<U<B<I/."
		set htmlEntityKeysProc([list greater than]) {html::InsertCharacter "greater than"}
	}
	if {![info exists htmlEntityKeys(ampersand)]} {
		set htmlEntityKeys(ampersand) "<U<B<I/7"
		set htmlEntityKeysProc(ampersand) {html::InsertCharacter ampersand}
	}
	if {![info exists htmlEntityKeys([list nonbreak space])]} {
		set htmlEntityKeys([list nonbreak space]) "<U<B<I/ "
		set htmlEntityKeysProc([list nonbreak space]) {html::InsertCharacter "nonbreak space"}
	}
	html::SaveCache "HTML entity keys" "array set htmlEntityKeys [list [array get htmlEntityKeys]]\rarray set htmlEntityKeysProc [list [array get htmlEntityKeysProc]]"
}

bind::fromArray htmlEntityKeys htmlEntityKeysProc 0 HTML
unset -nocomplain htmlEntityKeys htmlEntityKeysProc

proc html::BindBraces {args} {
	global bind::LeftBrace bind::RightBrace
	eval Bind [keys::toBind ${bind::LeftBrace}] html::LeftBrace HTML
	eval Bind [keys::toBind ${bind::RightBrace}] html::RightBrace HTML
}
proc html::UnBindBraces {args} {
	global bind::LeftBrace bind::RightBrace
	eval unBind [keys::toBind ${bind::LeftBrace}] html::LeftBrace HTML
	eval unBind [keys::toBind ${bind::RightBrace}] html::RightBrace HTML
}
html::BindBraces
Bind '\;' html::electricSemi HTML

# Change mode hooks
proc html::ChangeModeFrom {oldMode newMode} {
	css::DisableEnable on
	html::ActivateHook
	return
}

proc html::ChangeMode {newMode} {
	css::DisableEnable off
	return
}

# Comment line
Bind 'l' <C>  html::CommentLine HTML

# Register hooks
hook::register saveHook html::UpdateLastMod HTML
# Not relevant to Alphatk, and hopefully not in the future for Alpha 8/X
hook::register saveasHook html::UpdateLastMod HTML

hook::register quitHook html::QuitHook
hook::register quitHook {temp::cleanup HTML}
hook::register quitHook {html::SaveAllCacheSets URLs}
hook::register quitHook {html::SaveAllCacheSets Targets}
hook::register closeHook html::CloseHook Home
hook::register deactivateHook html::DeactivateHook Home
hook::register activateHook html::ActivateHook HTML
hook::register openHook html::ActivateHook HTML
hook::register keyboard html::BindBraces
hook::register removekeyboard html::UnBindBraces
hook::register preOpeningHook html::PreOpening HTML
hook::register changeModeFrom html::ChangeModeFrom HTML
hook::register changeMode html::ChangeMode HTML

# Check if the file specifies its charset and if so, try to convert that
# charset name to a known encoding name.  This could perhaps be improved
# by someone who knows what valid charset values are, and how best to
# convert them to Tcl encodings.  Currently it recognises that ISO-8859-1
# and iso8859-1 are the same, for example.
proc html::PreOpening {name} {
    # Get first four lines.  Could probably do better by scanning until
    # we reach '<BODY' for example.
    set lines ""
    set fin [open [win::StripCount $name] r]
    catch {
	append lines [gets $fin] [gets $fin] [gets $fin] [gets $fin]
    }
    close $fin
    # Extract the charset
    if {![regexp -nocase -- {charset="?([a-z0-9-]+)"?} $lines -> charset]} {
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

proc HTMLmodifyFlags {} {
	html::modifyFlags
}

proc HTML::OptionTitlebar {} {
	global html::PopUptag
	return [set html::PopUptag [html::GetAttributes]]
}

proc HTML::OptionTitlebarSelect {item} {
	global html::PopUptag
	if {[lcontains html::PopUptag $item]} {
		html::InsertAttributes $item
	} else {
		error "Not an attribute."
	}
}

proc html::LeftBrace {} {
	global HTML::commentCharacters
	if {![html::IsInContainer SCRIPT] && ![html::IsInContainer STYLE] && ![html::IsInCommentContainer C-STYLE-FORMATTING]} {
		insertText "\{"
		return
	}
	set oldgen $HTML::commentCharacters(General)
	set oldpar $HTML::commentCharacters(Paragraph)
	set HTML::commentCharacters(General) "//"
	set HTML::commentCharacters(Paragraph) [list "/* " " */" " * "]
	catch {bind::LeftBrace}
	set HTML::commentCharacters(General) $oldgen
	set HTML::commentCharacters(Paragraph) $oldpar
}

proc html::RightBrace {} {
	global electricBraces HTML::commentCharacters
	set old $electricBraces
	set oldgen $HTML::commentCharacters(General)
	set oldpar $HTML::commentCharacters(Paragraph)
	if {![html::IsInContainer SCRIPT] && ![html::IsInContainer STYLE] && ![html::IsInCommentContainer C-STYLE-FORMATTING]} {
		set electricBraces 0
	} else {
		set HTML::commentCharacters(General) "//"
		set HTML::commentCharacters(Paragraph) [list "/* " " */" " * "]
	}
	catch {bind::RightBrace}
	set electricBraces $old
	set HTML::commentCharacters(General) $oldgen
	set HTML::commentCharacters(Paragraph) $oldpar
}

proc html::electricSemi {} {
	global HTML::commentCharacters
	if {![html::IsInContainer SCRIPT] && ![html::IsInContainer STYLE]} {
		insertText ";"
		return
	}
	set oldgen $HTML::commentCharacters(General)
	set oldpar $HTML::commentCharacters(Paragraph)
	set HTML::commentCharacters(General) "//"
	set HTML::commentCharacters(Paragraph) [list "/* " " */" " * "]
	catch {bind::electricSemi}
	set HTML::commentCharacters(General) $oldgen
	set HTML::commentCharacters(Paragraph) $oldpar
}

proc HTML::indentLine {args} {
	win::parseArgs w
	global html::formattingStyles html::indentLineProcs positionAfterIndentation
	foreach style ${html::formattingStyles} {
		if {[html::IsInCommentContainer -w $w $style]} {
			if {[set html::indentLineProcs($style)] != ""} {
				eval [set html::indentLineProcs($style)] [list -w $w]
			}
			return
		}
	}
	if {[html::IsInContainer -w $w STYLE] || [html::IsInContainer -w $w SCRIPT]} {
		::indentLine -w $w
		return
	}
	if {[html::IsInContainer -w $w PRE]} {
		return
	}
	
	set previndent [html::FindIndent -w $w]
	set lend [pos::math -w $w [pos::nextLineStart -w $w [getPos -w $w]] - 1]
	if {[pos::compare -w $w $lend < [getPos -w $w]]} {
		set lend [maxPos -w $w]
	}
	set thisLine [string trimleft [getText -w $w [set lstart [pos::lineStart -w $w [getPos -w $w]]] $lend ]]
	set thisIndent [html::GetIndent -w $w [getPos -w $w]]
	if {$thisIndent != $previndent} {
		set pos [getPos -w $w]
		set spos [pos::lineStart -w $w $pos]
		set pd [pos::diff -w $w $spos $pos]
		set sp ""
		regexp {^[ \t]*} [getText -w $w $spos [pos::nextLineStart -w $w $spos]] sp
		replaceText -w $w $lstart $lend "$previndent$thisLine"
		if {![info exists positionAfterIndentation] || $positionAfterIndentation} {
			set sp1 ""
			regexp {^[ \t]*} [getText -w $w $spos [pos::nextLineStart -w $w $spos]] sp1
			set newpos [pos::math -w $w $spos + $pd + [string length $sp1] - [string length $sp]]
			if {[pos::compare -w $w $newpos < $spos]} {
				goto -w $w $spos
			} else {
				goto -w $w $newpos
			}
		} else {
			goto -w $w [text::firstNonWsLinePos -w $w [getPos -w $w]]
		}
    } elseif {[info exists positionAfterIndentation] && !$positionAfterIndentation} {
		goto -w $w [text::firstNonWsLinePos -w $w [getPos -w $w]]
	}
}

proc HTML::overrideModesWith {newM script} {
	set w [win::Current]
	set oldvarmodes [win::getInfo $w varmodes]
	set oldhookmodes [win::getInfo $w hookmodes]
	win::setInfo $w varmodes [list $newM] hookmodes [list $newM]
	catch {$script} ret
	win::setInfo $w varmodes $oldvarmodes hookmodes $oldhookmodes

	return $ret
}

proc HTML::correctIndentation {args} {
	win::parseArgs w pos {next ""}
	global HTMLmodeVars html::formattingStyles html::correctIndentProc
	foreach style ${html::formattingStyles} {
		if {[html::IsInCommentContainer -w $w $style]} {
			if {[set html::correctIndentProc($style)] != ""} {
				return [eval [set html::correctIndentProc($style)] [list -w $w $pos $next]]
			}
			return [lindex [pos::toRowCol -w $w [text::firstNonWsLinePos -w $w $pos]] 1]
		}
	}
	if {[html::IsInContainer -w $w STYLE] || [html::IsInContainer -w $w SCRIPT]} {
		# Attach 'CSS' variables to the window, temporarily, so that
		# comment handling, etc, in ::correctBracesIndentation are 
		# done for CSS mode.
		return [HTML::overrideModesWith CSS \
		  [list ::correctBracesIndentation -w $w $pos $next]]
	}
	if {[html::IsInContainer -w $w PRE]} {
		return [lindex [pos::toRowCol -w $w [text::firstNonWsLinePos -w $w $pos]] 1]
	}
	set pos [pos::math -w $w [lineStart -w $w [getPos -w $w]] - 1]
	if {[pos::compare -w $w $pos < [minPos]]} {set pos [minPos]}
	set ind [text::maxSpaceForm -w $w [html::FindNextIndent -w $w $pos]]
	if {[regexp -- {^</([^<>]+)>} $next "" tag] \
	  && [lcontains HTMLmodeVars(indentElements) [string toupper $tag]]} {
		set ind [text::maxSpaceForm -w $w [html::ReduceIndent -w $w $ind]]
	}
	return [string length $ind]
}

proc html::electricGreater {} {
	global HTMLmodeVars
	replaceText [getPos] [selEnd] >
	if {!$HTMLmodeVars(electricGreater) || [html::IsInContainer STYLE] || [html::IsInContainer SCRIPT]} {return}
	if {![catch {search -s -f 0 -i 1 -m 0 -r 1 {<[^<>]+>} [pos::math [getPos] - 1]} res] && 
	[pos::compare [lindex $res 1] == [getPos]] && [is::Whitespace [getText [lineStart [lindex $res 0]] [lindex $res 0]]]} {
		  HTML::indentLine
	}
}

Bind '>' {html::electricGreater} HTML

#===============================================================================
# ×××× Mark file ×××× #
#===============================================================================

proc HTML::parseFuncs {} {
	return [html::MarkFile2 0]
}

proc HTML::MarkFile {args} {
	win::parseArgs w
	html::MarkFile2 -w $w 1
	status::msg "Marks set."
}

proc html::MarkFile2 {args} {
	win::parseArgs w markfile
	set pos [minPos -w $w]
	set exp "<\[Hh\](\[1-6\])\[^<>\]*>"
	set exp2 "</\[Hh\]\[1-6\]>"
	set parse ""
	while {![catch {search -w $w -s -f 1 -r 1 -m 0 -i 0 $exp $pos} rs] && 
	![catch {search -w $w -s -f 1 -r 1 -m 0 -i 0 $exp2 [lindex $rs 1]} res]} {
		set start [lindex $rs 0]
		set end [lindex $res 1]
		set text [getText -w $w $start $end]
		# Remove tabs and returns from text.
		regsub -all "\[\t\r\n\]+" $text " " text
		# remove all tags from text
		set headtext [html::TagStrip $text]
		# Set mark only on one line.
		if {[pos::compare -w $w $end > [pos::nextLineStart -w $w $start]]} {
			set end [pos::math -w $w [pos::nextLineStart -w $w $start] - 1]
		}
		
		regexp $exp [getText -w $w $start $end] "" indlevel

		if {$indlevel > 0 && $indlevel < 7} {
			set lab [string range "       " 2 $indlevel]
			append lab $lab $indlevel " " $headtext
			# Cut the menu item if it's longer than 30 letters, not to make it too long.
			if {[string length $lab] > 30} {
				set lab "[string range $lab 0 29]..."
			}
			if {$markfile} {
				setNamedMark -w $w $lab $start $start $end
			} else {
				lappend parse $lab [pos::lineStart -w $w $start]
			}
		}
		set pos $end
	}
	if {!$markfile} {return $parse}
}

set htmlModeIsLoaded 1

status::msg "HTML initialization complete."
