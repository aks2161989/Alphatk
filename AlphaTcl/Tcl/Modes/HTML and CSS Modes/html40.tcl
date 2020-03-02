## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "html40.tcl"
 #                                    created: 97-12-20 15.02.44 
 #                                last update: 2005-02-21 17:51:21 
 #  Author: Johan Linde
 #  E-mail: <alpha_www_tools@go.to>
 #     www: <http://go.to/alpha_www_tools>
 #  
 # Version: 3.2
 # 
 # Copyright 1996-2003 by Johan Linde
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
# This file defines all HTML elements
# 
# The following arrays are defined here or elsewhere:
# html::ElemAttrRequired(<element>) = the list of required attributes for the element
# html::ElemAttrOptional(<element>) = the list of optional attributes for the element
# html::ElemAttrUsed(<element>)     = the list of attributes always asked about
#                                     (the ones marked "Always ask about" in the Use
#                                     Attributes dialog)
# html::ElemAttrHidden(<element>)   = the list of attributes never asked about
#                                     (the ones marked "Never ask about" in the Use
#                                     Attributes dialog)
# html::ElemAttrOverride(<element>) = the list of attributes checked to "Override 
#                                     global setting" in  the Use Attributes dialog
# html::ElemExtension(<element>)    = the list of attributes which are extensions to HTML 4
# html::ElemDeprecated(<element>)   = the list of attributes which are deprecated in HTML 4
# html::ElemLayout(<element>)       = the layout of the element in the text
# html::ElemMayContain(<element>)   = the valid content of the element (used for validation)
# html::AttrType(<attribute>)        = the type of the attribut
# html::AttrType(<element>%<attribute>) = the same but for a specific element
# html::AttrChoices(<attribute>)    = list of allowed values for attributes of type 'choices' 
#                                     or similar
# html::AttrChoices(<element>%<attribute>) = the same but for a specific element
# html::AttrRange(<attribute>)      = allowed range of values for attributes taking a 
#                                     numerical value
# html::AttrRange(<element>%<attribute>) = the same but for a specific element
# 
# The following procs are defined for each attribute type:
# html::BuildDialog<type>    = the proc for building the attribute dialog
#                              (found in htmlEngine.tcl)
# html::ReadDialog<type>     = the proc for reading the attribute dialog
#                              (found in htmlEngine.tcl)
# html::GetDialog<type>      = the proc for parsing the attribute value in a document
#                              and get a default value for the attribute dialog
#                              (found in htmlEditing.tcl)
# html::StatusBar<type>      = the proc for giving the attribute a value in the status bar
#                              (found in htmlStatusBar.tcl)
#                              
# The following procs are defined for some attribute types:
# html::CheckAttribute<type> = check if the attribute value is valid
#                              (found in htmlValidate.tcl)
# html::Complete<type>       = to complete the attribute value when using electric completions
#                              (found in HTMLCompletions.tcl)
# 
# The following procs are defined for some elements:
# html::MustContainCheck<element> = check if the element has the required content
#                                   (found in htmlValidate.tcl)
# html::<element>test             = extra check that the right attributes are set in the
#                                   attribute dialog (found in htmlEngine.tcl)
#===============================================================================

proc html40.tcl {} {}

proc html::FindOptionalLayout {elem} {
	global HTMLmodeVars html::ElemLayout html::ElemLayoutClosing html::ElemLayoutNoClosing
	if {[lcontains HTMLmodeVars(optionalClosing) $elem]} {
		if {![info exists html::ElemLayout($elem)] || [regexp {open} [set html::ElemLayout($elem)]]} {
			set html::ElemLayout($elem) $html::ElemLayoutClosing($elem)
		}
	} elseif {![info exists html::ElemLayout($elem)] || ![regexp {open} [set html::ElemLayout($elem)]]} {
		set html::ElemLayout($elem) $html::ElemLayoutNoClosing($elem)
	}
}

foreach elem $html::OptionalClosingTags {
	if {![info exists html::ElemLayoutClosing($elem)] } {
		if {![info exists html::ElemLayout($elem)] || [regexp {open} [set html::ElemLayout($elem)]]} {
			switch $elem {
				COLGROUP -
				TBODY -
				TFOOT -
				THEAD -
				DT -
				LI -
				OPTION {set html::ElemLayoutClosing($elem) cr1}
				TR -
				P {set html::ElemLayoutClosing($elem) cr2}
				DD -
				TD -
				TH {set html::ElemLayoutClosing($elem) cr0}
			}
		} else {
			set html::ElemLayoutClosing($elem) $html::ElemLayout($elem)
		}
	}
	if {![info exists html::ElemLayoutNoClosing($elem)] } {
		if {![info exists html::ElemLayout($elem)] || ![regexp {open} [set html::ElemLayout($elem)]]} {
			switch $elem {
				COLGROUP -
				TBODY -
				TFOOT -
				THEAD -
				TR -
				P {set html::ElemLayoutNoClosing($elem) open11}
				DT -
				LI -
				OPTION {set html::ElemLayoutNoClosing($elem) open10}
				DD -
				TD -
				TH {set html::ElemLayoutNoClosing($elem) open00}
			}
		} else {
			set html::ElemLayoutNoClosing($elem) $html::ElemLayout($elem)
		}
	}
}
unset -nocomplain elem

#===============================================================================
# Global definition
#===============================================================================

set html::AttrType(ABBR=) other
set html::AttrType(ABOVE=) other
set html::AttrType(ACCEPT=) contenttypes
set html::AttrType(ACCEPT-CHARSET=) charsets
set html::AttrType(ACCESSKEY=) character
set html::AttrType(ACTION=) url
set html::AttrType(ALIGN=) choices
set html::AttrChoices(ALIGN=) {CENTER RIGHT LEFT JUSTIFY}
set html::AttrType(ALINK=) color
set html::AttrType(ALT=) othernotrim
set html::AttrType(ARCHIVE=) other
set html::AttrType(AXIS=) other
set html::AttrType(BACKGROUND=) url
set html::AttrType(BELOW=) other
set html::AttrType(BEHAVIOR=) choices
set html::AttrChoices(BEHAVIOR=) {SLIDE ALTERNATE SCROLL}
set html::AttrType(BGCOLOR=) color
set html::AttrType(BGPROPERTIES=) choices
set html::AttrChoices(BGPROPERTIES=) FIXED
set html::AttrType(BORDER=) integer
set html::AttrRange(BORDER=) {0:i}
set html::AttrType(BORDERCOLOR=) color
set html::AttrType(BORDERCOLORDARK=) color
set html::AttrType(BORDERCOLORLIGHT=) color
set html::AttrType(CELLSPACING=) length
set html::AttrRange(CELLSPACING=) {0:i}
set html::AttrType(CELLPADDING=) length
set html::AttrRange(CELLPADDING=) {0:i}
set html::AttrType(CHALLENGE=) other
set html::AttrType(CHAR=) character
set html::AttrType(CHAROFF=) length
set html::AttrRange(CHAROFF=) {0:i}
set html::AttrType(CHARSET=) charset
set html::AttrType(CHECKED) flag
set html::AttrType(CITE=) url
set html::AttrType(CLASS=) other
set html::AttrType(CLASSID=) url
set html::AttrType(CLEAR=) choices
set html::AttrChoices(CLEAR=) {ALL LEFT RIGHT NONE}
set html::AttrType(CLIP=) other
set html::AttrType(CODE=) other
set html::AttrType(CODEBASE=) url
set html::AttrType(CODETYPE=) contenttype
set html::AttrType(COLOR=) color
set html::AttrType(COLS=) multilengths
set html::AttrRange(COLS=) {1:i}
set html::AttrType(COLSPAN=) integer
set html::AttrRange(COLSPAN=) {1:i}
set html::AttrType(COMPACT) flag
set html::AttrType(CONTENT=) other
set html::AttrType(CONTROLS) flag
set html::AttrType(COORDS=) coords
set html::AttrRange(COORDS=) {0:i}
set html::AttrType(DATA=) url
set html::AttrType(DATETIME=) datetime
set html::AttrType(DECLARE) flag
set html::AttrType(DEFER) flag
set html::AttrType(DIR=) choices
set html::AttrChoices(DIR=) {LTR RTL}
set html::AttrType(DIRECTION=) choices
set html::AttrChoices(DIRECTION=) {RIGHT LEFT}
set html::AttrType(DISABLED) flag
set html::AttrType(DYNSRC=) url
set html::AttrType(ENCTYPE=) contenttype
set html::AttrType(FACE=) other
set html::AttrType(FOR=) id
set html::AttrType(FRAME=) choices
set html::AttrChoices(FRAME=) {BORDER VOID ABOVE BELOW HSIDES VSIDES LHS RHS BOX}
set html::AttrType(FRAMEBORDER=) choices
set html::AttrChoices(FRAMEBORDER=) {1 0}
set html::AttrType(FRAMESPACING=) integer
set html::AttrRange(FRAMESPACING=) {0:i}
set html::AttrType(GUTTER=) integer
set html::AttrRange(GUTTER=) {0:i}
set html::AttrType(HEADERS=) ids
set html::AttrType(HEIGHT=) length
set html::AttrRange(HEIGHT=) {1:i}
set html::AttrType(HIDDEN=) choices
set html::AttrChoices(HIDDEN=) {TRUE FALSE}
set html::AttrType(HREF=) url
set html::AttrType(HREFLANG=) languagecode
set html::AttrType(HSPACE=) integer
set html::AttrRange(HSPACE=) {0:i}
set html::AttrType(HTTP-EQUIV=) id
set html::AttrType(ID=) id
set html::AttrType(ISMAP) flag
set html::AttrType(LABEL=) other
set html::AttrType(LANG=) languagecode
set html::AttrType(LANGUAGE=) other
set html::AttrType(LEFT=) integer
set html::AttrRange(LEFT=) {-i:i}
set html::AttrType(LEFTMARGIN=) integer
set html::AttrRange(LEFTMARGIN=) {0:i}
set html::AttrType(LINK=) color
set html::AttrType(LONGDESC=) url
set html::AttrType(LOWSRC=) url
set html::AttrType(LOOP=) integer
set html::AttrRange(LOOP=) {-1:i}
set html::AttrType(MARGINWIDTH=) integer
set html::AttrRange(MARGINWIDTH=) {0:i}
set html::AttrType(MARGINHEIGHT=) integer
set html::AttrRange(MARGINHEIGHT=) {0:i}
set html::AttrType(MAYSCRIPT) flag
set html::AttrType(MAXLENGTH=) integer
set html::AttrRange(MAXLENGTH=) {1:i}
set html::AttrType(MEDIA=) mediadesc
set html::AttrType(METHOD=) choices
set html::AttrChoices(METHOD=) {POST GET}
set html::AttrType(MULTIPLE) flag
set html::AttrType(NAME=) other
set html::AttrType(NOHREF) flag
set html::AttrType(NORESIZE) flag
set html::AttrType(NOSHADE) flag
set html::AttrType(NOWRAP) flag
set html::AttrType(OBJECT=) other
set html::AttrType(PAGEX=) integer
set html::AttrRange(PAGEX=) {0:i}
set html::AttrType(PAGEY=) integer
set html::AttrRange(PAGEY=) {0:i}
set html::AttrType(PALETTE=) choices
set html::AttrChoices(PALETTE=) {FOREGROUND BACKGROUND}
set html::AttrType(PLUGINSURL=) url
set html::AttrType(PLUGINSPAGE=) url
set html::AttrType(POINT-SIZE=) integer
set html::AttrRange(POINT-SIZE=) {1:i}
set html::AttrType(PROFILE=) url
set html::AttrType(PROMPT=) other
set html::AttrType(RBSPAN=) integer
set html::AttrRange(RBSPAN=) {1:i}
set html::AttrType(READONLY) flag
set html::AttrType(REL=) linktypes
set html::AttrType(REV=) linktypes
set html::AttrType(ROWS=) multilengths
set html::AttrRange(ROWS=) {1:i}
set html::AttrType(ROWSPAN=) integer
set html::AttrRange(ROWSPAN=) {1:i}
set html::AttrType(RULES=) choices
set html::AttrChoices(RULES=) {GROUPS ROWS COLS ALL NONE}
set html::AttrType(SCHEME=) other
set html::AttrType(SCOPE=) choices
set html::AttrChoices(SCOPE=) {ROW COL ROWGROUP COLGROUP}
set html::AttrType(SCROLLAMOUNT=) integer
set html::AttrRange(SCROLLAMOUNT=) {1:i}
set html::AttrType(SCROLLDELAY=) integer
set html::AttrRange(SCROLLDELAY=) {1:i}
set html::AttrType(SCROLLING=) choices
set html::AttrChoices(SCROLLING=) {YES NO AUTO}
set html::AttrType(SELECTED) flag
set html::AttrType(SHAPE=) choices
set html::AttrChoices(SHAPE=) {RECT CIRCLE POLY DEFAULT}
set html::AttrType(SIZE=) integer
set html::AttrRange(SIZE=) {1:i}
set html::AttrType(SPAN=) integer
set html::AttrRange(SPAN=) {1:i}
set html::AttrType(SRC=) url
set html::AttrType(STANDBY=) other
set html::AttrType(START=) choices
set html::AttrChoices(START=) {FILEOPEN MOUSEOVER}
set html::AttrType(STYLE=) other
set html::AttrType(SUMMARY=) other
set html::AttrType(TABINDEX=) integer
set html::AttrRange(TABINDEX=) {0:32767}
set html::AttrType(TARGET=) frametarget
set html::AttrType(TEXT=) color
set html::AttrType(TITLE=) other
set html::AttrType(TOP=) integer
set html::AttrRange(TOP=) {-i:i}
set html::AttrType(TOPMARGIN=) integer
set html::AttrRange(TOPMARGIN=) {0:i}
set html::AttrType(TYPE=) choices
set html::AttrChoices(TYPE=) {DISC CIRCLE SQUARE}
set html::AttrType(UNITS=) choices
set html::AttrChoices(UNITS=) {PIXELS EN}
set html::AttrType(USEMAP=) url
set html::AttrType(VALIGN=) choices
set html::AttrChoices(VALIGN=) {BASELINE BOTTOM MIDDLE TOP}
set html::AttrType(VALUE=) other
set html::AttrType(VALUETYPE=) choices
set html::AttrChoices(VALUETYPE=) {REF OBJECT DATA}
set html::AttrType(VISIBILITY=) choices
set html::AttrChoices(VISIBILITY=) {SHOW HIDDEN INHERIT}
set html::AttrType(VLINK=) color
set html::AttrType(VSPACE=) integer
set html::AttrRange(VSPACE=) {0:i}
set html::AttrType(WIDTH=) length
set html::AttrRange(WIDTH=) {1:i}
set html::AttrType(WRAP=) choices
set html::AttrChoices(WRAP=) {VIRTUAL PHYSICAL OFF}
set html::AttrType(XML:LANG=) languagecode
set html::AttrType(XML:SPACE=) choices
set html::AttrChoices(XML:SPACE=) preserve
set html::AttrType(XMLNS=) fixed
set html::AttrFixed(XMLNS=) "http://www.w3.org/1999/xhtml"
set html::AttrType(Z-INDEX=) integer
set html::AttrRange(Z-INDEX=) {1:i}
# for eventhandlers with need both a case sensitive version + uppercase
set html::AttrType(onAbort=) eventhandler
set html::AttrType(onBlur=) eventhandler
set html::AttrType(onChange=) eventhandler
set html::AttrType(onClick=) eventhandler
set html::AttrType(onDblClick=) eventhandler
set html::AttrType(onError=) eventhandler
set html::AttrType(onFocus=) eventhandler
set html::AttrType(onKeyDown=) eventhandler
set html::AttrType(onKeyPress=) eventhandler
set html::AttrType(onKeyUp=) eventhandler
set html::AttrType(onLoad=) eventhandler
set html::AttrType(onMouseDown=) eventhandler
set html::AttrType(onMouseMove=) eventhandler
set html::AttrType(onMouseOut=) eventhandler
set html::AttrType(onMouseOver=) eventhandler
set html::AttrType(onMouseUp=) eventhandler
set html::AttrType(onReset=) eventhandler
set html::AttrType(onSelect=) eventhandler
set html::AttrType(onSubmit=) eventhandler
set html::AttrType(onUnload=) eventhandler
set html::AttrType(ONABORT=) eventhandler
set html::AttrType(ONBLUR=) eventhandler
set html::AttrType(ONCHANGE=) eventhandler
set html::AttrType(ONCLICK=) eventhandler
set html::AttrType(ONDBLCLICK=) eventhandler
set html::AttrType(ONERROR=) eventhandler
set html::AttrType(ONFOCUS=) eventhandler
set html::AttrType(ONKEYDOWN=) eventhandler
set html::AttrType(ONKEYPRESS=) eventhandler
set html::AttrType(ONKEYUP=) eventhandler
set html::AttrType(ONLOAD=) eventhandler
set html::AttrType(ONMOUSEDOWN=) eventhandler
set html::AttrType(ONMOUSEMOVE=) eventhandler
set html::AttrType(ONMOUSEOUT=) eventhandler
set html::AttrType(ONMOUSEOVER=) eventhandler
set html::AttrType(ONMOUSEUP=) eventhandler
set html::AttrType(ONRESET=) eventhandler
set html::AttrType(ONSELECT=) eventhandler
set html::AttrType(ONSUBMIT=) eventhandler
set html::AttrType(ONUNLOAD=) eventhandler

#===============================================================================
# Element definitions
#===============================================================================

# A
set html::ElemAttrOptional(A)	{HREF= HREFLANG= NAME= TARGET= CHARSET= TYPE= SHAPE= COORDS=
ACCESSKEY= TABINDEX= REL= REV= onFocus= onBlur=}
ensureset html::ElemAttrUsed(A) {HREF= NAME= TARGET=}
ensureset html::ElemLayout(A) nocr
set html::AttrType(A%TYPE=) contenttype
set html::AttrType(A%NAME=) anchor
set html::ElemNotInXHTML1.1(A) {NAME=}

# ABBR
set html::ElemAttrOptional(ABBR) {}
ensureset html::ElemLayout(ABBR) nocr

# ACRONYM
set html::ElemAttrOptional(ACRONYM) {}
ensureset html::ElemLayout(ACRONYM) nocr

# ADDRESS
set html::ElemAttrOptional(ADDRESS) {}
ensureset html::ElemLayout(ADDRESS) cr0

# APPLET
set html::ElemAttrRequired(APPLET)	{WIDTH= HEIGHT=}
set html::ElemAttrOptional(APPLET) 	{CODE= CODEBASE= ARCHIVE= OBJECT= HSPACE= VSPACE= ALIGN= NAME= ALT=
MAYSCRIPT}
ensureset html::ElemAttrUsed(APPLET)	{WIDTH= HEIGHT= CODE= CODEBASE= ALIGN= }
set html::ElemExtension(APPLET) {MAYSCRIPT}
ensureset html::ElemLayout(APPLET) cr2
set html::AttrChoices(APPLET%ALIGN=)	{TOP MIDDLE BOTTOM LEFT RIGHT}

# AREA
set html::ElemAttrRequired(AREA) {ALT=}
set html::ElemAttrOptional(AREA)	{SHAPE= COORDS= TARGET= HREF= NOHREF ACCESSKEY= TABINDEX= onFocus= onBlur=}
ensureset html::ElemAttrUsed(AREA)	{ALT= SHAPE= COORDS= TARGET= HREF= NOHREF}
ensureset html::ElemLayout(AREA) open11

# B
set html::ElemAttrOptional(B) {}
ensureset html::ElemLayout(B) nocr

# BASE
set html::ElemAttrOptional(BASE)	{ID= HREF= TARGET=}
set html::ElemNotInHTML(BASE) {ID=}
ensureset html::ElemAttrUsed(BASE) {HREF= TARGET=}
ensureset html::ElemLayout(BASE) open11

# BASEFONT
set html::ElemAttrRequired(BASEFONT)	{SIZE=}
set html::ElemAttrOptional(BASEFONT) {COLOR= FACE= ID=}
ensureset html::ElemAttrUsed(BASEFONT) {SIZE= COLOR= FACE=}
set html::AttrRange(BASEFONT%SIZE=)	{1:7}
ensureset html::ElemLayout(BASEFONT) open11

# BDO
set html::ElemAttrRequired(BDO) {DIR=}
set html::ElemAttrOptional(BDO) {LANG=}
set html::ElemNotInHTML(BDO) {onClick= onDblClick= onMouseDown= onMouseUp= onMouseOver= 
onMouseMove= onMouseOut= onKeyPress= onKeyDown= onKeyUp=}
ensureset html::ElemAttrUsed(BDO) {DIR= LANG=}
ensureset html::ElemLayout(BDO) cr0

# BIG
set html::ElemAttrOptional(BIG) {}
ensureset html::ElemLayout(BIG) nocr

# BLOCKQUOTE
set html::ElemAttrOptional(BLOCKQUOTE) {CITE=}
ensureset html::ElemLayout(BLOCKQUOTE) cr2

# BODY
set html::ElemAttrOptional(BODY)	{BACKGROUND= BGPROPERTIES= BGCOLOR= TEXT= LINK= VLINK= ALINK=
LEFTMARGIN= TOPMARGIN= onLoad= onUnload=}
ensureset html::ElemAttrUsed(BODY) {BACKGROUND= BGCOLOR= TEXT= LINK= VLINK=}
set html::ElemExtension(BODY) {BGPROPERTIES= LEFTMARGIN= TOPMARGIN=}
set html::ElemDeprecated(BODY) {BACKGROUND= BGCOLOR= TEXT= LINK= VLINK= ALINK=}
ensureset html::ElemLayout(BODY) cr2

# BR
set html::ElemAttrOptional(BR)	{CLEAR=}
ensureset html::ElemAttrUsed(BR) {CLEAR=}
set html::ElemDeprecated(BR) {CLEAR=}
ensureset html::ElemLayout(BR) open01

# BUTTON
set html::ElemAttrOptional(BUTTON) {NAME= VALUE= TYPE= DISABLED ACCESSKEY= TABINDEX= onFocus= onBlur=}
ensureset html::ElemAttrUsed(BUTTON) {NAME= VALUE= TYPE= DISABLED}
ensureset html::ElemLayout(BUTTON) cr0
set html::AttrChoices(BUTTON%TYPE=) {BUTTON RESET SUBMIT}

# CAPTION
set html::ElemAttrOptional(CAPTION)	{ALIGN=}
set html::AttrChoices(CAPTION%ALIGN=)	{BOTTOM TOP LEFT RIGHT}
ensureset html::ElemAttrUsed(CAPTION) {ALIGN=}
set html::ElemDeprecated(CAPTION) {ALIGN=}
ensureset html::ElemLayout(CAPTION) cr0

# CENTER
set html::ElemAttrOptional(CENTER) {}
ensureset html::ElemLayout(CENTER) cr2

# CITE
set html::ElemAttrOptional(CITE) {}
ensureset html::ElemLayout(CITE) nocr

# CODE
set html::ElemAttrOptional(CODE) {}
ensureset html::ElemLayout(CODE) nocr

# COL
set html::ElemAttrOptional(COL)	{SPAN= ALIGN= VALIGN= WIDTH= CHAR= CHAROFF=}
ensureset html::ElemAttrUsed(COL) {SPAN= ALIGN= VALIGN= WIDTH=}
set html::AttrType(COL%WIDTH=) multilength
set html::AttrChoices(COL%ALIGN=) {LEFT CENTER RIGHT JUSTIFY CHAR}
ensureset html::ElemLayout(COL) open11

# COLGROUP
set html::ElemAttrOptional(COLGROUP)	{SPAN= ALIGN= VALIGN= WIDTH= CHAR= CHAROFF=}
set html::AttrType(COLGROUP%WIDTH=) multilength
set html::AttrChoices(COLGROUP%ALIGN=) {LEFT CENTER RIGHT JUSTIFY CHAR}
ensureset html::ElemAttrUsed(COLGROUP) {SPAN= ALIGN= VALIGN= WIDTH=}
html::FindOptionalLayout COLGROUP

# DD
set html::ElemAttrOptional(DD)	{}
html::FindOptionalLayout DD

# DEL
set html::ElemAttrOptional(DEL) {CITE= DATETIME=}
ensureset html::ElemAttrUsed(DEL) {CITE= DATETIME=}
ensureset html::ElemLayout(DEL) cr0

# DFN
set html::ElemAttrOptional(DFN) {}
ensureset html::ElemLayout(DFN) nocr

# DIR
set html::ElemAttrOptional(DIR) {COMPACT}
ensureset html::ElemLayout(DIR) cr2

# DIV
set html::ElemAttrOptional(DIV)	{ALIGN=}
ensureset html::ElemAttrUsed(DIV) {ALIGN=}
set html::ElemDeprecated(DIV) {ALIGN=}
ensureset html::ElemLayout(DIV) cr2

# DL
set html::ElemAttrOptional(DL) {COMPACT}
set html::ElemDeprecated(DL) {COMPACT}
ensureset html::ElemLayout(DL) cr2

# DT
set html::ElemAttrOptional(DT) {}
html::FindOptionalLayout DT

# EM
set html::ElemAttrOptional(EM) {}
ensureset html::ElemLayout(EM) nocr

# FIELDSET
set html::ElemAttrOptional(FIELDSET) {}
ensureset html::ElemLayout(FIELDSET) cr2

# FONT
set html::ElemAttrOptional(FONT)	{SIZE= COLOR= FACE= POINT-SIZE=}
ensureset html::ElemAttrUsed(FONT)	{SIZE= COLOR= FACE=}
set html::ElemExtension(FONT) {POINT-SIZE=}
set html::AttrRange(FONT%SIZE=)	{1:7}
ensureset html::ElemLayout(FONT) nocr

# FORM
set html::ElemAttrRequired(FORM) {ACTION=}
set html::ElemAttrOptional(FORM)	{METHOD= ENCTYPE= TARGET= ACCEPT-CHARSET= ACCEPT= NAME= onReset= onSubmit=}
ensureset html::ElemAttrUsed(FORM) {ACTION= METHOD=}
ensureset html::ElemLayout(FORM) cr2
set html::ElemNotInXHTML1.0strict(FORM) {NAME=}
set html::ElemNotInXHTML1.1(FORM) {NAME=}

# FRAME
set html::ElemAttrOptional(FRAME)	{SRC= NAME= MARGINWIDTH= MARGINHEIGHT= SCROLLING=
NORESIZE FRAMEBORDER= LONGDESC= BORDERCOLOR=}
ensureset html::ElemAttrUsed(FRAME)	{SRC= NAME= MARGINWIDTH= MARGINHEIGHT= SCROLLING=
NORESIZE FRAMEBORDER=}
set html::ElemExtension(FRAME) {BORDERCOLOR=}
ensureset html::ElemLayout(FRAME) open11
set html::AttrType(FRAME%NAME=) targetname

# FRAMESET
set html::ElemAttrOptional(FRAMESET) {ROWS= COLS= FRAMEBORDER= BORDER= BORDERCOLOR= FRAMESPACING= onLoad= onUnload=}
ensureset html::ElemAttrUsed(FRAMESET) {ROWS= COLS=}
set html::ElemExtension(FRAMESET) {FRAMEBORDER= BORDER= BORDERCOLOR= FRAMESPACING=}
ensureset html::ElemLayout(FRAMESET) cr2

# H1
set html::ElemAttrOptional(H1)	{ALIGN=}
ensureset html::ElemAttrUsed(H1) {ALIGN=}
set html::ElemDeprecated(H1)	{ALIGN=}
ensureset html::ElemLayout(H1) cr1

# H2
set html::ElemAttrOptional(H2)	{ALIGN=}
ensureset html::ElemAttrUsed(H2)	{ALIGN=}
set html::ElemDeprecated(H2)		{ALIGN=}
ensureset html::ElemLayout(H2) cr1

# H3
set html::ElemAttrOptional(H3)	{ALIGN=}
ensureset html::ElemAttrUsed(H3)	{ALIGN=}
set html::ElemDeprecated(H3)		{ALIGN=}
ensureset html::ElemLayout(H3) cr1

# H4
set html::ElemAttrOptional(H4)	{ALIGN=}
ensureset html::ElemAttrUsed(H4)	{ALIGN=}
set html::ElemDeprecated(H4)		{ALIGN=}
ensureset html::ElemLayout(H4) cr1

# H5
set html::ElemAttrOptional(H5)	{ALIGN=}
ensureset html::ElemAttrUsed(H5)	{ALIGN=}
set html::ElemDeprecated(H5)		{ALIGN=}
ensureset html::ElemLayout(H5) cr1

# H6
set html::ElemAttrOptional(H6)	{ALIGN=}
ensureset html::ElemAttrUsed(H6)	{ALIGN=}
set html::ElemDeprecated(H6)		{ALIGN=}
ensureset html::ElemLayout(H6) cr1

# HEAD
set html::ElemAttrOptional(HEAD) {ID= PROFILE=}
set html::ElemNotInHTML(HEAD) {ID=}
ensureset html::ElemLayout(HEAD) cr2

# HR
set html::ElemAttrOptional(HR)	{ALIGN= SIZE= WIDTH= COLOR= NOSHADE}
set html::ElemExtension(HR)	{COLOR=}
set html::ElemDeprecated(HR)	{ALIGN= SIZE= WIDTH= NOSHADE}
ensureset html::ElemLayout(HR) open11
set html::AttrChoices(HR%ALIGN=) {LEFT RIGHT CENTER}

# HTML
set html::ElemAttrRequired(HTML) {XMLNS=}
set html::ElemAttrOptional(HTML) {ID=}
set html::ElemNotInHTML(HTML) {ID= XMLNS=}
ensureset html::ElemLayout(HTML) cr2

# I
set html::ElemAttrOptional(I) {}
ensureset html::ElemLayout(I) nocr

# IFRAME
set html::ElemAttrOptional(IFRAME) {SRC= NAME= WIDTH= HEIGHT= MARGINWIDTH= MARGINHEIGHT= SCROLLING=
ALIGN= FRAMEBORDER= LONGDESC=}
ensureset html::ElemAttrUsed(IFRAME) {SRC= NAME= WIDTH= HEIGHT= MARGINWIDTH= MARGINHEIGHT= SCROLLING= ALIGN=}
set html::ElemDeprecated(IFRAME)	{ALIGN=}
set html::AttrChoices(IFRAME%ALIGN=) {TOP MIDDLE BOTTOM LEFT RIGHT}
ensureset html::ElemLayout(IFRAME) nocr
set html::AttrType(IFRAME%NAME=) targetname

# IMG
set html::ElemAttrRequired(IMG)	{SRC= ALT=}
set html::ElemAttrOptional(IMG)	{LOWSRC= NAME= WIDTH= HEIGHT=  BORDER= 
ALIGN= HSPACE= VSPACE= USEMAP= ISMAP LONGDESC= DYNSRC= LOOP= START= CONTROLS onAbort= onError= onLoad=}
ensureset html::ElemAttrUsed(IMG)	{SRC= ALT= WIDTH= HEIGHT= BORDER= ALIGN= HSPACE= VSPACE=}
set html::ElemExtension(IMG) {LOWSRC= CONTROLS DYNSRC= LOOP= START= onAbort= onError= onLoad=}
set html::ElemDeprecated(IMG) {ALIGN= BORDER= HSPACE= VSPACE=}
ensureset html::ElemLayout(IMG) open00
set html::AttrChoices(IMG%ALIGN=) {TOP MIDDLE BOTTOM LEFT RIGHT}
set html::ElemNotInXHTML1.0strict(IMG) {NAME=}
set html::ElemNotInXHTML1.1(IMG) {NAME=}

# INPUT=TEXT
set "html::ElemAttrOptional(INPUT TYPE=TEXT)"	{NAME= VALUE= SIZE= MAXLENGTH= DISABLED READONLY ACCESSKEY= TABINDEX=
onFocus= onBlur= onChange= onSelect=}
ensureset "html::ElemAttrUsed(INPUT TYPE=TEXT)"	{NAME= VALUE= SIZE= MAXLENGTH=}
ensureset html::ElemLayout(INPUT) open01

# INPUT=CHECKBOX
set "html::ElemAttrRequired(INPUT TYPE=CHECKBOX)"	{VALUE=}
set "html::ElemAttrOptional(INPUT TYPE=CHECKBOX)"	{NAME= CHECKED DISABLED ACCESSKEY= TABINDEX=}
ensureset "html::ElemAttrUsed(INPUT TYPE=CHECKBOX)"	{NAME= VALUE= CHECKED}

# INPUT=BUTTON
set "html::ElemAttrOptional(INPUT TYPE=BUTTON)"	{NAME= VALUE= SIZE= DISABLED ACCESSKEY= TABINDEX=}
ensureset "html::ElemAttrUsed(INPUT TYPE=BUTTON)"	{NAME= VALUE=}

# INPUT=RADIO
set "html::ElemAttrRequired(INPUT TYPE=RADIO)"	{VALUE=}
set "html::ElemAttrOptional(INPUT TYPE=RADIO)"	{NAME= CHECKED DISABLED ACCESSKEY= TABINDEX=}
ensureset "html::ElemAttrUsed(INPUT TYPE=RADIO)"	{NAME= VALUE= CHECKED}

# INPUT=SUBMIT
set "html::ElemAttrOptional(INPUT TYPE=SUBMIT)"	{NAME= VALUE= SIZE= DISABLED ACCESSKEY= TABINDEX=}
ensureset "html::ElemAttrUsed(INPUT TYPE=SUBMIT)"	{NAME= VALUE=}

# INPUT=RESET
set "html::ElemAttrOptional(INPUT TYPE=RESET)"	{NAME= VALUE= SIZE= DISABLED ACCESSKEY= TABINDEX=}
ensureset "html::ElemAttrUsed(INPUT TYPE=RESET)"	{VALUE=}

# INPUT=PASSWORD
set "html::ElemAttrOptional(INPUT TYPE=PASSWORD)"	{NAME= VALUE= SIZE= MAXLENGTH= DISABLED READONLY ACCESSKEY= TABINDEX=
onFocus= onBlur= onChange= onSelect=}
ensureset "html::ElemAttrUsed(INPUT TYPE=PASSWORD)"	{NAME= VALUE= SIZE= MAXLENGTH=}

# INPUT=HIDDEN
set "html::ElemAttrOptional(INPUT TYPE=HIDDEN)"	{NAME= VALUE=}
ensureset "html::ElemAttrUsed(INPUT TYPE=HIDDEN)"	{NAME= VALUE=}

# INPUT=IMAGE
set "html::ElemAttrRequired(INPUT TYPE=IMAGE)"	{SRC=}
set "html::ElemAttrOptional(INPUT TYPE=IMAGE)"	{NAME= VALUE= ALIGN= ALT= USEMAP= ISMAP DISABLED ACCESSKEY= TABINDEX=}
ensureset "html::ElemAttrUsed(INPUT TYPE=IMAGE)"	{SRC= NAME= ALT=}
set "html::ElemDeprecated(INPUT TYPE=IMAGE)" {ALIGN=}
set "html::AttrChoices(INPUT TYPE=IMAGE%ALIGN=)"	{TOP MIDDLE BOTTOM LEFT RIGHT}
set "html::ElemNotInXHTML1.0(INPUT TYPE=IMAGE)" {ISMAP}
set "html::ElemNotInXHTML1.1(INPUT TYPE=IMAGE)" {ISMAP}

# INPUT=FILE
set "html::ElemAttrOptional(INPUT TYPE=FILE)"	{NAME= VALUE= SIZE= MAXLENGTH= ACCEPT= DISABLED ACCESSKEY= TABINDEX=}
ensureset "html::ElemAttrUsed(INPUT TYPE=FILE)" {NAME= SIZE= MAXLENGTH=}

# INS
set html::ElemAttrOptional(INS) {CITE= DATETIME=}
ensureset html::ElemAttrUsed(INS) {CITE= DATETIME=}
ensureset html::ElemLayout(INS) cr0

# ISINDEX
set html::ElemAttrOptional(ISINDEX)	{ACTION= PROMPT=}
set html::ElemExtension(ISINDEX) {ACTION=}
ensureset html::ElemLayout(ISINDEX) open11

# KBD
set html::ElemAttrOptional(KBD) {}
ensureset html::ElemLayout(KBD) nocr

# LABEL
set html::ElemAttrOptional(LABEL) {FOR= ACCESSKEY= onFocus= onBlur=}
ensureset html::ElemAttrUsed(LABEL) {FOR= ACCESSKEY=}
ensureset html::ElemLayout(LABEL) nocr

# LEGEND
set html::ElemAttrOptional(LEGEND) {ALIGN= ACCESSKEY=}
ensureset html::ElemAttrUsed(LEGEND) {ALIGN= ACCESSKEY=}
set html::ElemDeprecated(LEGEND) {ALIGN=}
ensureset html::ElemLayout(LEGEND) cr0
set html::AttrChoices(LEGEND%ALIGN=) {TOP BOTTOM LEFT RIGHT}

# LI
set "html::ElemAttrOptional(LI IN UL)"	{TYPE=}
ensureset "html::ElemAttrUsed(LI IN UL)" {TYPE=}
set "html::ElemDeprecated(LI IN UL)"		{TYPE=}
set "html::ElemAttrOptional(LI IN OL)"	{TYPE= VALUE=}
ensureset "html::ElemAttrUsed(LI IN OL)" {TYPE= VALUE=}
set "html::ElemDeprecated(LI IN OL)"		{TYPE= VALUE=}
set "html::AttrType(LI IN OL%VALUE=)" integer
set "html::AttrRange(LI IN OL%VALUE=)" {1:i}
set "html::AttrType(LI IN OL%TYPE=)" oltype
set "html::AttrChoices(LI IN OL%TYPE=)" {A a I i 1}
set html::ElemAttrOptional(LI) {}
html::FindOptionalLayout LI

# LINK
set html::ElemAttrOptional(LINK)	{HREF= HREFLANG= TARGET= CHARSET= REL= REV= TYPE= MEDIA=}
ensureset html::ElemAttrUsed(LINK) {HREF= REL= TYPE=}
ensureset html::ElemLayout(LINK) open11
set html::AttrType(LINK%TYPE=) contenttype

# MAP
set html::ElemAttrRequired(MAP)	{NAME=}
set html::ElemAttrOptional(MAP)	{}
ensureset html::ElemLayout(MAP) cr2
set html::AttrType(MAP%NAME=) anchor
set html::ElemNotInXHTML1.1(MAP) {NAME=}

# MENU
set html::ElemAttrOptional(MENU) {COMPACT}
ensureset html::ElemLayout(MENU) cr2

# META
set html::ElemAttrRequired(META)	{CONTENT=}
set html::ElemAttrOptional(META)	{ID= NAME= HTTP-EQUIV= SCHEME=}
set html::ElemNotInHTML(META) {ID=}
ensureset html::ElemAttrUsed(META) {CONTENT= NAME= HTTP-EQUIV=}
ensureset html::ElemLayout(META) open11
set html::AttrType(META%NAME=) id

# NOFRAMES
set html::ElemAttrOptional(NOFRAMES) {}
ensureset html::ElemLayout(NOFRAMES) cr2

# NOSCRIPT
set html::ElemAttrOptional(NOSCRIPT) {}
ensureset html::ElemLayout(NOSCRIPT) cr2

# OBJECT
set html::ElemAttrOptional(OBJECT) {CLASSID= CODEBASE= CODETYPE= ARCHIVE= DATA= NAME= TYPE= STANDBY=
ALIGN= BORDER= WIDTH= HEIGHT= HSPACE= VSPACE= USEMAP= DECLARE TABINDEX=}
ensureset html::ElemAttrUsed(OBJECT) {CLASSID= CODETYPE= ARCHIVE= DATA= NAME= TYPE= WIDTH= HEIGHT= STANDBY=}
set html::ElemDeprecated(OBJECT) {ALIGN= BORDER= HSPACE= VSPACE=}
ensureset html::ElemLayout(OBJECT) cr2
set html::AttrType(OBJECT%TYPE=) contenttype
set html::AttrChoices(OBJECT%ALIGN=) {TOP MIDDLE BOTTOM LEFT RIGHT}

# OL
set html::ElemAttrOptional(OL)	{TYPE= START= COMPACT}
ensureset html::ElemAttrUsed(OL) {TYPE= START=}
set html::ElemDeprecated(OL)	{TYPE= START= COMPACT}
ensureset html::ElemLayout(OL) cr2
set html::AttrType(OL%TYPE=) oltype
set html::AttrChoices(OL%TYPE=)	{A a I i 1}
set html::AttrType(OL%START=) integer
set html::AttrRange(OL%START=) {1:i}

# OPTGROUP
set html::ElemAttrRequired(OPTGROUP) {LABEL=}
set html::ElemAttrOptional(OPTGROUP) {DISABLED}
ensureset html::ElemAttrUsed(OPTGROUP) {LABEL= DISABLED}
ensureset html::ElemLayout(OPTGROUP) cr2

# OPTION
set html::ElemAttrOptional(OPTION)	{VALUE= LABEL= SELECTED DISABLED}
ensureset html::ElemAttrUsed(OPTION)	{VALUE= SELECTED}
html::FindOptionalLayout OPTION

# P
set html::ElemAttrOptional(P)	{ALIGN=}
ensureset html::ElemAttrUsed(P)	{ALIGN=}
set html::ElemDeprecated(P)		{ALIGN=}
html::FindOptionalLayout P

# PARAM
set html::ElemAttrRequired(PARAM)	{NAME=}
set html::ElemAttrOptional(PARAM)	{VALUE= TYPE= VALUETYPE= ID=}
ensureset html::ElemAttrUsed(PARAM) {NAME= VALUE=}
ensureset html::ElemLayout(PARAM) open11
set html::AttrType(PARAM%TYPE=) contenttype

# PRE
set html::ElemAttrOptional(PRE)	{WIDTH= XML:SPACE=}
set html::ElemDeprecated(PRE)	{WIDTH=}
set html::ElemNotInHTML(PRE) {XML:SPACE=}
ensureset html::ElemLayout(PRE) cr2
set html::AttrType(PRE%WIDTH=) integer

# Q
set html::ElemAttrOptional(Q) {CITE=}
ensureset html::ElemLayout(Q) nocr

# RB
set html::ElemAttrOptional(RB) {}
ensureset html::ElemLayout(RB) nocr

# RBC
set html::ElemAttrOptional(RBC) {}
ensureset html::ElemLayout(RBC) cr2

# RP
set html::ElemAttrOptional(RP) {}
ensureset html::ElemLayout(RP) nocr

# RT
set html::ElemAttrOptional(RT) {RBSPAN=}
ensureset html::ElemAttrUsed(RT) {RBSPAN=}
ensureset html::ElemLayout(RT) nocr

# RTC
set html::ElemAttrOptional(RTC) {}
ensureset html::ElemLayout(RTC) cr2

# RUBY
set html::ElemAttrOptional(RUBY) {}
ensureset html::ElemLayout(RUBY) cr2

# S
set html::ElemAttrOptional(S) {}
ensureset html::ElemLayout(S) nocr

# SAMP
set html::ElemAttrOptional(SAMP) {}
ensureset html::ElemLayout(SAMP) nocr

# SCRIPT
set html::ElemAttrRequired(SCRIPT) {TYPE=}
set html::ElemAttrOptional(SCRIPT)	{LANGUAGE= SRC= ARCHIVE= DEFER CHARSET= ID= XML:SPACE=}
set html::ElemNotInHTML(SCRIPT) {ID= XML:SPACE=}
ensureset html::ElemAttrUsed(SCRIPT)	{TYPE= LANGUAGE= SRC=}
set html::ElemExtension(SCRIPT) {ARCHIVE=}
set html::ElemDeprecated(SCRIPT)	{LANGUAGE=}
ensureset html::ElemLayout(SCRIPT) cr2
set html::AttrType(SCRIPT%TYPE=) contenttype

# SELECT
set html::ElemAttrOptional(SELECT)	{NAME= SIZE= TABINDEX= MULTIPLE DISABLED onFocus= onBlur= onChange=}
ensureset html::ElemAttrUsed(SELECT)	{NAME= SIZE= MULTIPLE}
ensureset html::ElemLayout(SELECT) cr2

# SMALL
set html::ElemAttrOptional(SMALL) {}
ensureset html::ElemLayout(SMALL) nocr

# SPAN
set html::ElemAttrOptional(SPAN) {}
ensureset html::ElemAttrUsed(SPAN)	{CLASS=}
ensureset html::ElemLayout(SPAN) nocr

# STRIKE
set html::ElemAttrOptional(STRIKE) {}
ensureset html::ElemLayout(STRIKE) nocr

# STRONG
set html::ElemAttrOptional(STRONG) {}
ensureset html::ElemLayout(STRONG) nocr

# STYLE
set html::ElemAttrRequired(STYLE) {TYPE=}
set html::ElemAttrOptional(STYLE) {MEDIA= TITLE= ID= XML:SPACE=}
set html::ElemNotInHTML(STYLE) {ID= XML:SPACE=}
ensureset html::ElemAttrUsed(STYLE) {TYPE=}
ensureset html::ElemLayout(STYLE) cr2
set html::AttrType(STYLE%TYPE=) contenttype

# SUB
set html::ElemAttrOptional(SUB) {}
ensureset html::ElemLayout(SUB) nocr

# SUP
set html::ElemAttrOptional(SUP) {}
ensureset html::ElemLayout(SUP) nocr

# TABLE
set html::ElemAttrOptional(TABLE)	{BORDER= CELLSPACING= CELLPADDING= COLS= WIDTH= HEIGHT=
ALIGN= FRAME= RULES= SUMMARY= BGCOLOR= BORDERCOLOR= BORDERCOLORDARK= BORDERCOLORLIGHT= BACKGROUND=}
ensureset html::ElemAttrUsed(TABLE)	{BORDER= CELLSPACING= CELLPADDING=}
set html::ElemExtension(TABLE) {COLS= HEIGHT= BORDERCOLOR= BORDERCOLORDARK= BORDERCOLORLIGHT= BACKGROUND=}
set html::ElemDeprecated(TABLE) {ALIGN= BGCOLOR=}
ensureset html::ElemLayout(TABLE) cr2
set html::AttrType(TABLE%COLS=) integer
set html::AttrChoices(TABLE%ALIGN=) {LEFT CENTER RIGHT}

# TBODY
set html::ElemAttrOptional(TBODY) {ALIGN= VALIGN= CHAR= CHAROFF=}
ensureset html::ElemAttrUsed(TBODY) {ALIGN= VALIGN=}
html::FindOptionalLayout TBODY
set html::AttrChoices(TBODY%ALIGN=) {LEFT CENTER RIGHT JUSTIFY CHAR}

# TEXTAREA
set html::ElemAttrRequired(TEXTAREA)	{ROWS= COLS=}
set html::ElemAttrOptional(TEXTAREA)	{NAME= WRAP= ACCESSKEY= TABINDEX= DISABLED READONLY onFocus= onBlur= onChange= onSelect=}
ensureset html::ElemAttrUsed(TEXTAREA) {ROWS= COLS= NAME=}
set html::ElemExtension(TEXTAREA) {WRAP=}
ensureset html::ElemLayout(TEXTAREA) cr0
set html::AttrType(TEXTAREA%ROWS=) integer
set html::AttrType(TEXTAREA%COLS=) integer

# TD
set html::ElemAttrOptional(TD)	{ALIGN= VALIGN= CHAR= CHAROFF= COLSPAN= ROWSPAN= WIDTH= HEIGHT=
NOWRAP ABBR= AXIS= HEADERS= SCOPE= BGCOLOR= BORDERCOLOR= BORDERCOLORDARK= 
BORDERCOLORLIGHT= BACKGROUND=}
ensureset html::ElemAttrUsed(TD)	{ALIGN= VALIGN= COLSPAN= ROWSPAN= WIDTH= NOWRAP}
set html::ElemExtension(TD) {BORDERCOLOR= BORDERCOLORDARK= BORDERCOLORLIGHT= BACKGROUND=}
set html::ElemDeprecated(TD) {NOWRAP BGCOLOR= WIDTH= HEIGHT=}
html::FindOptionalLayout TD
set html::AttrChoices(TD%ALIGN=) {LEFT CENTER RIGHT JUSTIFY CHAR}

# TFOOT
set html::ElemAttrOptional(TFOOT) {ALIGN= VALIGN= CHAR= CHAROFF=}
ensureset html::ElemAttrUsed(TFOOT) {ALIGN= VALIGN=}
html::FindOptionalLayout TFOOT
set html::AttrChoices(TFOOT%ALIGN=) {LEFT CENTER RIGHT JUSTIFY CHAR}

# TH
set html::ElemAttrOptional(TH)	{ALIGN= VALIGN= CHAR= CHAROFF= COLSPAN= ROWSPAN= WIDTH= HEIGHT=
NOWRAP ABBR= AXIS= HEADERS= SCOPE= BGCOLOR= BORDERCOLOR= BORDERCOLORDARK= 
BORDERCOLORLIGHT= BACKGROUND=}
ensureset html::ElemAttrUsed(TH)	{ALIGN= VALIGN= COLSPAN= ROWSPAN= WIDTH= NOWRAP}
set html::ElemExtension(TH) {BORDERCOLOR= BORDERCOLORDARK= BORDERCOLORLIGHT= BACKGROUND=}
set html::ElemDeprecated(TH) {NOWRAP BGCOLOR= WIDTH= HEIGHT=}
html::FindOptionalLayout TH
set html::AttrChoices(TH%ALIGN=) {LEFT CENTER RIGHT JUSTIFY CHAR}

# THEAD
set html::ElemAttrOptional(THEAD) {ALIGN= VALIGN= CHAR= CHAROFF=}
ensureset html::ElemAttrUsed(THEAD) {ALIGN= VALIGN=}
html::FindOptionalLayout THEAD
set html::AttrChoices(THEAD%ALIGN=) {LEFT CENTER RIGHT JUSTIFY CHAR}

# TITLE
set html::ElemAttrOptional(TITLE) {ID=}
set html::ElemNotInHTML(TITLE) {ID=}
ensureset html::ElemLayout(TITLE) cr1

# TR
set html::ElemAttrOptional(TR)	{ALIGN= VALIGN= CHAR= CHAROFF= BGCOLOR= BORDERCOLOR= BORDERCOLORDARK=
BORDERCOLORLIGHT= BACKGROUND=}
ensureset html::ElemAttrUsed(TR)	{ALIGN= VALIGN=}
set html::ElemExtension(TR) {BORDERCOLOR= BORDERCOLORDARK= BORDERCOLORLIGHT= BACKGROUND=}
set html::ElemDeprecated(TR) {BGCOLOR=}
html::FindOptionalLayout TR
set html::AttrChoices(TR%ALIGN=) {LEFT CENTER RIGHT JUSTIFY CHAR}

# TT
set html::ElemAttrOptional(TT) {}
ensureset html::ElemLayout(TT) nocr

# U
set html::ElemAttrOptional(U) {}
ensureset html::ElemLayout(U) nocr

# UL
set html::ElemAttrOptional(UL)	{TYPE= COMPACT}
ensureset html::ElemAttrUsed(UL) {TYPE=}
set html::ElemDeprecated(UL)	{TYPE= COMPACT}
ensureset html::ElemLayout(UL) cr2

# VAR
set html::ElemAttrOptional(VAR) {}
ensureset html::ElemLayout(VAR) nocr

#===============================================================================
# Extensions
#===============================================================================

# BGSOUND
set html::ElemAttrRequired(BGSOUND) {SRC=}
set html::ElemAttrOptional(BGSOUND) {LOOP=}
ensureset html::ElemAttrUsed(BGSOUND) {SRC= LOOP=}
ensureset html::ElemLayout(BGSOUND) open11

# BLINK
set html::ElemAttrOptional(BLINK) {}
ensureset html::ElemLayout(BLINK) nocr

# EMBED
set html::ElemAttrOptional(EMBED) {SRC= TYPE= WIDTH= HEIGHT= UNITS= HSPACE= VSPACE= BORDER= ALIGN=
FRAMEBORDER= NAME= HIDDEN= PALETTE= PLUGINSURL= PLUGINSPAGE=}
ensureset html::ElemAttrUsed(EMBED) {SRC= TYPE= WIDTH= HEIGHT=}
ensureset html::ElemLayout(EMBED) open00
set html::AttrType(EMBED%TYPE=) contenttype
set html::AttrType(EMBED%WIDTH=) integer
set html::AttrType(EMBED%HEIGHT=) integer
set html::AttrChoices(EMBED%ALIGN=) {TOP MIDDLE BOTTOM LEFT RIGHT}
set html::AttrChoices(EMBED%FRAMEBORDER=) {NO}

# ILAYER
set html::ElemAttrOptional(ILAYER) {LEFT= TOP= PAGEX= PAGEY= NAME= SRC= WIDTH= HEIGHT= CLIP= Z-INDEX=
ABOVE= BELOW= VISIBILITY= BGCOLOR= BACKGROUND= onLoad=}
ensureset html::ElemAttrUsed(ILAYER) {LEFT= TOP= SRC= WIDTH= HEIGHT= VISIBILITY=}
ensureset html::ElemLayout(ILAYER) cr0

# KEYGEN
set html::ElemAttrRequired(KEYGEN) {NAME=}
set html::ElemAttrOptional(KEYGEN) {CHALLENGE=}
ensureset html::ElemAttrUsed(KEYGEN) {NAME=}
ensureset html::ElemLayout(KEYGEN) open11

# LAYER
set html::ElemAttrOptional(LAYER) {LEFT= TOP= PAGEX= PAGEY= NAME= SRC= WIDTH= HEIGHT= CLIP= Z-INDEX=
ABOVE= BELOW= VISIBILITY= BGCOLOR= BACKGROUND= onLoad=}
ensureset html::ElemAttrUsed(LAYER) {LEFT= TOP= SRC= WIDTH= HEIGHT= VISIBILITY=}
ensureset html::ElemLayout(LAYER) cr2

# MARQUEE
set html::ElemAttrOptional(MARQUEE) {BEHAVIOR= DIRECTION= ALIGN= LOOP= WIDTH= HEIGHT=
HSPACE= VSPACE= BGCOLOR= SCROLLAMOUNT= SCROLLDELAY=}
ensureset html::ElemAttrUsed(MARQUEE) {BEHAVIOR= DIRECTION= LOOP=}
ensureset html::ElemLayout(MARQUEE) cr0
set html::AttrChoices(MARQUEE%ALIGN=) {TOP MIDDLE BOTTOM}

# MULTICOL
set html::ElemAttrRequired(MULTICOL)	{COLS=}
set html::ElemAttrOptional(MULTICOL)	{GUTTER= WIDTH=}
ensureset html::ElemAttrUsed(MULTICOL) {COLS= GUTTER= WIDTH=}
ensureset html::ElemLayout(MULTICOL) cr2
set html::AttrType(MULTICOL%COLS=) integer
set html::AttrRange(MULTICOL%COLS=) {2:i}

# NOBR
set html::ElemAttrOptional(NOBR) {}
ensureset html::ElemLayout(NOBR) nocr

# NOEMBED
set html::ElemAttrOptional(NOEMBED) {}
ensureset html::ElemLayout(NOEMBED) cr2

# NOLAYER
set html::ElemAttrOptional(NOLAYER) {}
ensureset html::ElemLayout(NOLAYER) cr2

# SERVER
set html::ElemAttrOptional(SERVER) {}
ensureset html::ElemLayout(SERVER) cr2

# SPACER
set html::ElemAttrRequired(SPACER)	{TYPE=}
set html::ElemAttrOptional(SPACER)	{SIZE= WIDTH= HEIGHT= ALIGN=}
ensureset html::ElemAttrUsed(SPACER) {TYPE= SIZE= WIDTH= HEIGHT= ALIGN=}
ensureset html::ElemLayout(SPACER) open00
set html::AttrChoices(SPACER%TYPE=) {HORIZONTAL VERTICAL BLOCK}
set html::AttrChoices(SPACER%ALIGN=) {TOP MIDDLE BOTTOM LEFT RIGHT}

# WBR
set html::ElemAttrOptional(WBR) 	{}
ensureset html::ElemLayout(WBR) open01

# Add attrs CLASS, ID, STYLE, TITLE.
# All except {BASE BASEFONT HEAD HTML
# META PARAM SCRIPT STYLE TITLE WBR BGSOUND KEYGEN SERVER}
foreach tmp {A ABBR ACRONYM ADDRESS APPLET AREA B BDO BIG BLINK BLOCKQUOTE BODY BR
BUTTON CAPTION CENTER CITE CODE COL COLGROUP DD DEL DFN DIR DIV DL DT EM
EMBED FIELDSET FONT FORM FRAME FRAMESET H1 H2 H3 H4 H5 H6 HR I IFRAME
ILAYER IMG {INPUT TYPE=BUTTON} {INPUT TYPE=CHECKBOX}
{INPUT TYPE=FILE} {INPUT TYPE=HIDDEN} {INPUT TYPE=IMAGE} {INPUT TYPE=PASSWORD}
{INPUT TYPE=RADIO} {INPUT TYPE=RESET} {INPUT TYPE=SUBMIT}
{INPUT TYPE=TEXT} INS ISINDEX KBD LABEL LAYER LEGEND LI {LI IN OL}
{LI IN UL} LINK MAP MARQUEE MENU MULTICOL NOBR NOEMBED NOFRAMES
NOLAYER NOSCRIPT OBJECT OL OPTGROUP OPTION P PRE RB RBC RP RT RTC RUBY Q S SAMP 
SELECT SMALL SPACER SPAN STRIKE STRONG SUB SUP TABLE TBODY TD
TEXTAREA TFOOT TH THEAD TR TT U UL VAR} {
	lappend html::ElemAttrOptional($tmp) CLASS= ID= STYLE= TITLE=
}

# Add attrs LANG, DIR.
# All except {APPLET BASE BASEFONT BDO BR FRAME FRAMESET IFRAME
# PARAM SCRIPT WBR BGSOUND KEYGEN SERVER}
foreach tmp {A ABBR ACRONYM ADDRESS AREA B BIG BLINK BLOCKQUOTE BODY BUTTON CAPTION
CENTER CITE CODE COL COLGROUP DD DEL DFN DIR DIV DL DT EM EMBED FIELDSET
FONT FORM H1 H2 H3 H4 H5 H6 HEAD HR HTML I ILAYER IMG {INPUT TYPE=BUTTON}
{INPUT TYPE=CHECKBOX} {INPUT TYPE=FILE} {INPUT TYPE=HIDDEN} 
{INPUT TYPE=IMAGE} {INPUT TYPE=PASSWORD} {INPUT TYPE=RADIO} {INPUT TYPE=RESET}
{INPUT TYPE=SUBMIT} {INPUT TYPE=TEXT} INS ISINDEX KBD LABEL LAYER LEGEND LI
{LI IN OL} {LI IN UL} LINK MAP MARQUEE MENU META MULTICOL NOBR NOEMBED NOFRAMES
NOLAYER NOSCRIPT OBJECT OL OPTGROUP OPTION P PRE RB RBC RP RT RTC RUBY Q S SAMP
SELECT SMALL SPACER SPAN STRIKE STRONG STYLE SUB SUP TABLE TBODY TD
TEXTAREA TFOOT TH THEAD TITLE TR TT U UL VAR} {
	lappend html::ElemAttrOptional($tmp) LANG= XML:LANG= DIR=
	lappend html::ElemNotInHTML($tmp) XML:LANG=
	lappend html::ElemNotInXHTML1.1($tmp) LANG=
}

# Add event handlers
# All except {APPLET BASE BASEFONT BR FONT FRAME FRAMESET HEAD HTML
# IFRAME ISINDEX META PARAM SCRIPT STYLE TITLE WBR BGSOUND KEYGEN SERVER}
foreach tmp {A ABBR ACRONYM ADDRESS AREA B BDO BIG BLINK BLOCKQUOTE BODY BUTTON CAPTION
CENTER CITE CODE COL COLGROUP DD DEL DFN DIR DIV DL DT EM EMBED FIELDSET
FORM H1 H2 H3 H4 H5 H6 HR I ILAYER IMG {INPUT TYPE=BUTTON} {INPUT TYPE=CHECKBOX}
{INPUT TYPE=FILE} {INPUT TYPE=HIDDEN} {INPUT TYPE=IMAGE} {INPUT TYPE=PASSWORD} 
{INPUT TYPE=RADIO} {INPUT TYPE=RESET} {INPUT TYPE=SUBMIT}
{INPUT TYPE=TEXT} INS KBD LABEL LAYER LEGEND LI {LI IN OL}
{LI IN UL} LINK MAP MARQUEE MENU MULTICOL NOBR NOEMBED NOFRAMES
NOLAYER NOSCRIPT OBJECT OL OPTGROUP OPTION P PRE RB RBC RP RT RTC RUBY Q S SAMP 
SELECT SMALL SPACER SPAN STRIKE STRONG SUB SUP TABLE TBODY TD
TEXTAREA TFOOT TH THEAD TR TT U UL VAR} {
	lappend html::ElemAttrOptional($tmp) onClick= onDblClick= onMouseDown= onMouseUp= onMouseOver= \
	  onMouseMove= onMouseOut= onKeyPress= onKeyDown= onKeyUp=
}

unset tmp

# Loading custom elements
if {[html::AdditionsExists] && [catch {html::ReadCache "Additions cache"}]} {
	if {[catch {html::CreateAdditionCaches;	html::ReadCache "Additions cache"}]} {
		alertnote "Loading of custom HTML elements failed."
	}
}
