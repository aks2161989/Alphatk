## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  CSS mode - tools for editing CSS documents
 # 
 #  FILE: "cssBuildDialog.tcl"
 #                                    created: 00-01-02 00.22.20 
 #                                last update: 2005-02-21 17:51:02 
 #  Author: Johan Linde
 #  E-mail: <alpha_www_tools@go.to>
 #     www: <http://go.to/alpha_www_tools>
 #  
 # Version: 2.2
 # 
 # Copyright 1997-2003 by Johan Linde
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
# This file contain procs for building the dialogs for CSS 
# properties. For each type of property there is a proc
# css::BuildDialog<type>
#===============================================================================

#===============================================================================
# ×××× Dialog building ×××× #
#===============================================================================

# group
proc css::BuildDialoggroup {group v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $bt buttons $ba buttonAction $ind index
	
	global css::Group css::Property css::Descriptor css::IsDescriptor css::ExtraDialog
	foreach prop [set css::Group($group)] {
		if {${css::IsDescriptor}} {
			set p [set css::Descriptor($prop)]
		} else {
			set p [set css::Property($prop)]
		}
		eval css::BuildDialog$p $prop val box hpos wpos buttons buttonAction index		
	}
	if {[info exists css::ExtraDialog($group)]} {
		eval [set css::ExtraDialog($group)] hpos box
	}
	
	css::ShorthandBox $group hpos box
}

# @charset
proc css::BuildDialog@charset {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	lappend box -t "charset:" 10 $hpos 120 [expr {$hpos + 15}]
	lappend box -e [lindex $val $index] 120 $hpos 450 [expr {$hpos + 15}]
	incr hpos 30
}

# @import
proc css::BuildDialog@import {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $bt buttons $ba buttonAction $ind index
	lappend box -t "url:" 10 $hpos 120 [expr {$hpos + 15}]
	css::UrlBox val box hpos wpos index buttons buttonAction
	lappend box -t "media type(s):" 10 $hpos 120 [expr {$hpos + 15}]
	css::MediaList val box hpos wpos index buttons buttonAction
}

# @media
proc css::BuildDialog@media {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $bt buttons $ba buttonAction $ind index
	lappend box -t "media type(s):" 10 $hpos 120 [expr {$hpos + 15}]
	css::MediaList val box hpos wpos index buttons buttonAction
}

# @page 
proc css::BuildDialog@page {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	lappend box -t "page name:" 10 $hpos 120 [expr {$hpos + 15}] \
	  -e [lindex $val $index] 130 $hpos 250 [expr {$hpos + 15}] \
	  -t "pseudo-page:" 260 $hpos 350 [expr {$hpos + 15}] \
	  -m [concat [list [lindex $val [expr {$index + 1}]] { }] :left :right :first] \
	  360 $hpos 450 [expr {$hpos + 20}]
	incr index 2
	incr hpos 30
}

# choices
proc css::BuildDialogchoices {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	
	global css::Choices
	css::PropertyPrompt $prop $hpos wpos box
	# Special case with font-stretch descriptor
	set ch [set css::Choices($prop)]
	css::ChoiceList $ch val box hpos wpos index
	incr hpos 30
}

# color
proc css::BuildDialogcolor {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $bt buttons $ba buttonAction $ind index
	
	css::PropertyPrompt $prop $hpos wpos box
	css::ChoiceList "" val box hpos wpos index
	incr hpos 30
	css::ColorBox val box hpos wpos index buttons buttonAction
}

# url
proc css::BuildDialogurl {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $bt buttons $ba buttonAction $ind index
	
	css::PropertyPrompt $prop $hpos wpos box
	css::ChoiceList "" val box hpos wpos index
	css::UrlBox val box hpos wpos index buttons buttonAction
}

# family = like font-family and voice-family
proc css::BuildDialogfamily {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $bt buttons $ba buttonAction $ind index
	
	global css::Choices css::IsDescriptor
	css::PropertyPrompt $prop $hpos wpos box
	set ch [set css::Choices($prop)]
	# Special case with font-stretch descriptor
	if {${css::IsDescriptor} && $prop == "font-stretch"} {set ch [lrange $ch 2 end]}
	set apos $wpos
	incr wpos 70
	css::ChoiceList $ch val box hpos wpos index
	lappend box -e [lindex $val $index] 10 [expr {$hpos + 30}] 450 [expr {$hpos + 45}]
	lappend box -b Add $apos $hpos [expr {$apos + 60}] [expr {$hpos + 20}]
	lappend buttons [expr {$index + 1}]
	set buttonAction([expr {$index + 1}]) css::FamilyAddButton
	incr index 2
	set wpos 10
	incr hpos 60
}

# integer
proc css::BuildDialoginteger {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	
	css::PropertyPrompt $prop $hpos wpos box
	css::ChoiceList "" val box hpos wpos index
	css::NumberNoUnitBox $hpos wpos val index box
	incr hpos 30
}

# number
proc css::BuildDialognumber {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $bt buttons $ba buttonAction $ind index
	css::BuildDialoginteger $prop val box hpos wpos buttons buttonAction index
}

# nlpc = number, length, percentage, or choices
proc css::BuildDialognlpc {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	css::NumChoice $prop length 1 1 val box hpos wpos index
}

# lpc = length, percentage, or choices
proc css::BuildDialoglpc {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	css::NumChoice $prop length 1 0 val box hpos wpos index
}

# npc = number, percentage, or choices
proc css::BuildDialognpc {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	css::NumChoice $prop number 1 1 val box hpos wpos index
}

# lc = length or choices
proc css::BuildDialoglc {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	css::NumChoice $prop length 0 0 val box hpos wpos index
}

# ac = angle or choices
proc css::BuildDialogac {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	css::NumChoice $prop angle 0 0 val box hpos wpos index
}

# fc = frequency or choices
proc css::BuildDialogfc {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	css::NumChoice $prop frequency 0 0 val box hpos wpos index
}

# cc = color or choices
proc css::BuildDialogcc {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $bt buttons $ba buttonAction $ind index
	
	css::BuildDialogchoices $prop val box hpos wpos bt ba index
	css::ColorBox val box hpos wpos index buttons buttonAction
}

# uc = url or choices
proc css::BuildDialoguc {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $bt buttons $ba buttonAction $ind index
	
	css::BuildDialogchoices $prop val box hpos wpos bt ba index
	css::UrlBox val box hpos wpos index buttons buttonAction
}

# lp = length or percentage
proc css::BuildDialoglp {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	
	css::PropertyPrompt $prop $hpos wpos box
	css::ChoiceList "" val box hpos wpos index
	css::NumberBox $hpos wpos val index box length 1 0
	incr hpos 30
}

# tp = time or percentage
proc css::BuildDialogtp {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	
	css::PropertyPrompt $prop $hpos wpos box
	css::ChoiceList "" val box hpos wpos index
	css::NumberBox $hpos wpos val index box time 1 0
	incr hpos 30
}

# ic = integer or choices
proc css::BuildDialogic {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	
	global css::Choices
	css::PropertyPrompt $prop $hpos wpos box
	css::ChoiceList [set css::Choices($prop)] val box hpos wpos index 1 95
	css::NumberNoUnitBox $hpos wpos val index box
	incr hpos 30
	
}

# nc = number or choices
proc css::BuildDialognc {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $bt buttons $ba buttonAction $ind index
	css::BuildDialogic $prop val box hpos wpos buttons buttonAction index
}

# border
proc css::BuildDialogborder {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $bt buttons $ba buttonAction $ind index
	global css::Property css::Choices
	css::PropertyPrompt border-width $hpos wpos box
	css::ChoiceList [set css::Choices(border-top-width)] val box hpos wpos index 1 95
	css::NumberBox $hpos wpos val index box length 0 0
	incr hpos 30
	set wpos [css::PropertyPrompt border-style $hpos $wpos box]
	css::ChoiceList [set css::Choices(border-top-style)] val box hpos wpos index
	incr hpos 30
	set wpos [css::PropertyPrompt border-color $hpos $wpos box]
	css::ChoiceList [set css::Choices(border-top-color)] val box hpos wpos index
	incr hpos 30
	css::ColorBox val box hpos wpos index buttons buttonAction
	css::ShorthandBox $prop hpos box
}

# clip
proc css::BuildDialogclip {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	global css::Choices
	css::PropertyPrompt $prop $hpos wpos box
	css::ChoiceList [set css::Choices(clip)] val box hpos wpos index
	incr hpos 30
	set wpos 40
	foreach side {top right bottom left} {
		lappend box -t $side: $wpos $hpos [expr {$wpos + 60}] [expr {$hpos + 15}]
		incr wpos 60
		lappend box -c auto [lindex $val $index] $wpos $hpos [expr {$wpos + 70}] [expr {$hpos + 15}]
		incr index
		incr wpos 70
		css::NumberBox $hpos wpos val index box length 0 0
		set wpos 40
		incr hpos 30
	}
}

# quotes
proc css::BuildDialogquotes {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $bt buttons $ba buttonAction $ind index
	css::BuildDialogchoices $prop val box hpos wpos buttons buttonAction index
	lappend box -n { } -e [lindex $val $index] 130 $hpos 190 [expr {$hpos + 15}] \
	  -e [lindex $val [incr index]] 210 $hpos 270 [expr {$hpos + 15}] \
	  -b Add 290 $hpos 350 [expr {$hpos + 20}] \
	  -e [lindex $val [incr index 2]] 10 [expr {$hpos + 30}] 450 [expr {$hpos + 45}]
	lappend buttons [expr {$index - 1}]
	set buttonAction([expr {$index - 1}]) css::QuotesAddButton
	incr index
	incr hpos 50
}

# counter
proc css::BuildDialogcounter {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $bt buttons $ba buttonAction $ind index
	css::BuildDialogchoices $prop val box hpos wpos buttons buttonAction index
	lappend box -e [lindex $val $index] 10 $hpos 450 [expr {$hpos + 15}]
	incr index
	incr hpos 30
}

# size
proc css::BuildDialogsize {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	css::BuildDialogchoices $prop val box hpos wpos bt ba index
	set wpos 130
	css::NumberBox $hpos wpos val index box length 0 0
	css::NumberBox $hpos wpos val index box length 0 0
	incr hpos 30
}

# content
proc css::BuildDialogcontent {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $bt buttons $ba buttonAction $ind index
	global css::Choices
	css::BuildDialogchoices $prop val box hpos wpos bt ba index
	lappend box -e [lindex $val $index] 10 [expr {$hpos + 170}] 450 [expr {$hpos + 205}] \
	  -b Add $wpos [expr {$hpos - 30}] [expr {$wpos + 60}] [expr {$hpos - 10}]
	lappend buttons [expr {$index + 1}]
	set buttonAction([expr {$index + 1}]) css::ContentAddButton
	incr index 2
	lappend box -b Add 10 [expr {$hpos - 5}] 70 [expr {$hpos + 15}] -t URL: 80 $hpos 120 [expr {$hpos + 20}]
	lappend buttons $index
	set buttonAction($index) css::ContentURLButton
	incr index
	css::UrlBox val box hpos wpos index buttons buttonAction
	lappend box -b Add 50 [expr {$hpos + 30}] 110 [expr {$hpos + 50}] -t counter(s): 40 $hpos 120 [expr {$hpos + 20}]
	lappend buttons $index
	set buttonAction($index) css::ContentCounterButton
	incr index
	lappend box -t name: 130 $hpos 190 [expr {$hpos + 15}] -e [lindex $val $index] 200 $hpos 450 [expr {$hpos + 15}] \
	  -t string: 130 [expr {$hpos + 25}] 190 [expr {$hpos + 40}] -e [lindex $val [expr {$index + 1}]] 200 [expr {$hpos + 25}] 450 [expr {$hpos + 40}] \
	  -t style: 130 [expr {$hpos + 50}] 190 [expr {$hpos + 65}] \
	  -m [concat [list [lindex $val [expr {$index + 2}]]] {{ }} [set css::Choices(list-style-type)]] 200 [expr {$hpos + 50}] 450 [expr {$hpos + 70}]
	incr hpos 80
	incr index 3
	lappend box -t attr: 40 [expr {$hpos + 5}] 120 [expr {$hpos + 25}] -e [lindex $val $index] 130 [expr {$hpos + 5}] 250 [expr {$hpos + 20}] \
	  -b Add 260 $hpos 320 [expr {$hpos + 20}]
	lappend buttons [expr {$index + 1}]
	set buttonAction([expr {$index + 1}]) css::ContentAttrButton
	incr index 2
	incr hpos 80
}

# marks
proc css::BuildDialogmarks {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	css::PropertyPrompt $prop $hpos wpos box
	css::ChoiceList none val box hpos wpos index 1 95
	incr wpos 40
	lappend box -n { } -c crop [lindex $val $index] $wpos $hpos [expr {$wpos + 70}] [expr {$hpos + 15}]
	incr index
	incr wpos 70
	lappend box -c cross [lindex $val $index] $wpos $hpos [expr {$wpos + 70}] [expr {$hpos + 15}]
	incr index
	incr hpos 10
}

# page
proc css::BuildDialogpage {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	css::PropertyPrompt $prop $hpos wpos box
	lappend box -c auto [lindex $val $index] $wpos $hpos [expr {$wpos + 70}] [expr {$hpos + 15}]
	incr index
	lappend box -e [lindex $val $index] [expr {$wpos + 80}] $hpos 450 [expr {$hpos + 15}]
	incr index
	incr hpos 10
}

# backpos
proc css::BuildDialogbackpos {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	css::PropertyPrompt $prop $hpos wpos box
	lappend box -c inherit [lindex $val $index] $wpos $hpos [expr {$wpos + 70}] [expr {$hpos + 15}]
	incr wpos 70; incr index
	css::ChoiceList {top center bottom} val box hpos wpos index 0 95
	css::ChoiceList {left center right} val box hpos wpos index 0 95
	incr hpos 30; set wpos 170
	css::NumberBox $hpos wpos val index box length 1 0
	incr wpos -10
	css::NumberBox $hpos wpos val index box length 1 0
	incr hpos 30
}

# font 
proc css::BuildDialogfont {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $bt buttons $ba buttonAction $ind index
	global css::Choices css::FontValue
	css::BuildDialoggroup  $prop val box hpos wpos buttons buttonAction index
	css::PropertyPrompt $prop $hpos wpos box
	set ebox [list -m [concat [list ${css::FontValue}] {{ }} [set css::Choices(font)]] $wpos $hpos [expr {$wpos + 170}] [expr {$hpos + 15}]]
	regsub -- {-c {Inherit all}} $box "$ebox &" box
	incr hpos 10
}

# fontstyle
proc css::BuildDialogfontstyle {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $bt buttons $ba buttonAction $ind index
	css::BuildDialogfamily $prop val box hpos wpos buttons buttonAction index
	incr hpos -60
	lappend box -c all [lindex $val $index] 380 $hpos 460 [expr {$hpos + 15}]
	incr index
	incr hpos 60
}

# fontvariant
proc css::BuildDialogfontvariant {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $bt buttons $ba buttonAction $ind index
	css::BuildDialogfamily $prop val box hpos wpos buttons buttonAction index	
}

# fontsize
proc css::BuildDialogfontsize {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $bt buttons $ba buttonAction $ind index
	css::PropertyPrompt $prop $hpos wpos box
	lappend box -b Add $wpos $hpos [expr {$wpos + 60}] [expr {$hpos + 20}]
	lappend buttons $index
	set buttonAction($index) css::FontSizeAddButton
	incr index
	incr wpos 70
	css::NumberBox $hpos wpos val index box length 0 0
	lappend box -e [lindex $val $index] 10 [expr {$hpos + 30}] 450 [expr {$hpos + 45}]
	incr index
	lappend box -c all [lindex $val $index] 380 $hpos 460 [expr {$hpos + 15}]
	incr index
	incr hpos 60
}

# panose
proc css::BuildDialogpanose {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	css::PropertyPrompt $prop $hpos wpos box
	for {set i 0} {$i < 10} {incr i} {
		if {$i == 5} {incr hpos 30; set wpos 130}
		css::NumberNoUnitBox $hpos wpos val index box
	}
	incr hpos 30
}

# widths
proc css::BuildDialogwidths {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	css::PropertyPrompt $prop $hpos wpos box
	lappend box -e [lindex $val $index]	$wpos $hpos 450 [expr {$hpos + 35}]
	incr index
	incr hpos 50
}

# bbox
proc css::BuildDialogbbox {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	css::PropertyPrompt $prop $hpos wpos box
	css::NumberNoUnitBox $hpos wpos val index box
	css::NumberNoUnitBox $hpos wpos val index box
	css::NumberNoUnitBox $hpos wpos val index box
	css::NumberNoUnitBox $hpos wpos val index box
	incr hpos 30
}

# unirange
proc css::BuildDialogunirange {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	css::PropertyPrompt $prop $hpos wpos box
	lappend box -e [lindex $val $index] $wpos $hpos 450 [expr {$hpos + 50}]
	incr index
	set wpos 10
	incr hpos 65
}

# src
proc css::BuildDialogsrc {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $bt buttons $ba buttonAction $ind index
	css::BuildDialogurl $prop val box hpos wpos buttons buttonAction index
	lappend box -t format: 40 $hpos 120 [expr {$hpos + 15}] \
	  -e [lindex $val $index] 130 $hpos 450 [expr {$hpos + 15}] \
	  -t "font face name:" 40 [expr {$hpos + 25}] 140 [expr {$hpos + 40}] \
	  -e [lindex $val [incr index]] 150 [expr {$hpos + 25}] 450 [expr {$hpos + 40}] \
	  -b Add 40 [expr {$hpos + 50}] 100 [expr {$hpos + 70}] \
	  -e [lindex $val [incr index 2]] 130 [expr {$hpos + 50}] 450 [expr {$hpos + 130}]
	incr hpos 130
	lappend buttons [expr {$index - 1}]
	set buttonAction([expr {$index - 1}]) css::SrcButton
	incr index
}

# textalign
proc css::BuildDialogtextalign {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	global css::Choices
	css::PropertyPrompt $prop $hpos wpos box
	css::ChoiceList [set css::Choices($prop)] val box hpos wpos index 1 95
	lappend box -e [lindex $val $index] 235 $hpos 450 [expr {$hpos + 15}]
	incr index
	set wpos 10
	incr hpos 30
}

# textdecoration
proc css::BuildDialogtextdecoration {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	global css::Choices
	css::PropertyPrompt $prop $hpos wpos box
	css::ChoiceList none val box hpos wpos index 1 95
	set ch [set css::Choices($prop)]
	lappend box -c [lindex $ch 0] [lindex $val $index] $wpos $hpos [expr {$wpos + 100}] [expr {$hpos + 15}]
	incr wpos 110; incr index
	lappend box -c [lindex $ch 1] [lindex $val $index] $wpos $hpos [expr {$wpos + 100}] [expr {$hpos + 15}]
	set wpos 270; incr hpos 30; incr index
	lappend box -c [lindex $ch 2] [lindex $val $index] $wpos $hpos [expr {$wpos + 100}] [expr {$hpos + 15}]
	incr wpos 110; incr index
	lappend box -c [lindex $ch 3] [lindex $val $index] $wpos $hpos [expr {$wpos + 100}] [expr {$hpos + 15}]
	incr hpos 30; incr index
}

# textshadow
proc css::BuildDialogtextshadow {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $bt buttons $ba buttonAction $ind index
	css::PropertyPrompt $prop $hpos wpos box
	css::ChoiceList none val box hpos wpos index
	lappend box -n " "
	set wpos 40
	incr hpos 30
	foreach item {horizontal vertical blur} {
		lappend box -t $item: $wpos $hpos [expr {$wpos + 80}] [expr {$hpos + 15}]
		incr wpos 80
		css::NumberBox $hpos wpos val index box length 0 0
		set wpos 40
		incr hpos 30
	}	
	css::ColorBox val box hpos wpos index buttons buttonAction
	lappend box -b Add 40 [expr {$hpos - 40}] 105 [expr {$hpos - 20}]
	lappend buttons $index
	set buttonAction($index) css::AddTextShadow
	incr index
	lappend box -e [lindex $val $index] 10 $hpos 420 [expr {$hpos + 60}]
	incr hpos 60
}

# borderspacing
proc css::BuildDialogborderspacing {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	css::PropertyPrompt $prop $hpos wpos box
	css::ChoiceList "" val box hpos wpos index
	incr hpos 30; set wpos 130
	css::NumberBox $hpos wpos val index box length 0 0
	css::NumberBox $hpos wpos val index box length 0 0
	incr hpos 30	
}

# cursor
proc css::BuildDialogcursor {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $bt buttons $ba buttonAction $ind index
	global css::Choices
	css::PropertyPrompt $prop $hpos wpos box
	css::UrlBox val box hpos wpos index buttons buttonAction
	lappend box -e [lindex $val $index] $wpos $hpos 450 [expr {$hpos + 50}] \
	  -b Add 40 $hpos 105 [expr {$hpos + 20}]
	lappend buttons [incr index]
	set buttonAction($index) css::CursorAddButton
	incr index
	incr hpos 60
	css::ChoiceList [set css::Choices($prop)] val box hpos wpos index
	incr hpos 20
}

# playduring
proc css::BuildDialogplayduring {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $bt buttons $ba buttonAction $ind index
	css::BuildDialogchoices $prop val box hpos wpos bt ba index
	lappend box -n { }
	css::UrlBox val box hpos wpos index buttons buttonAction
	lappend box -c mix [lindex $val $index] $wpos $hpos [expr {$wpos + 95}] [expr {$hpos + 15}]
	incr index
	lappend box -c repeat [lindex $val $index] [expr {$wpos + 100}] $hpos [expr {$wpos + 195}] [expr {$hpos + 15}]
	incr index
	incr hpos 30
}

# azimuth
proc css::BuildDialogazimuth {prop v b hp wp bt ba ind} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	global css::Choices
	css::PropertyPrompt $prop $hpos wpos box
	css::ChoiceList [set css::Choices($prop)] val box hpos wpos index
	css::NumberBox $hpos wpos val index box angle 0 0
	incr hpos 30; set wpos 130
	css::ChoiceList {left-side far-left left center-left center center-right right far-right right-side} val box hpos wpos index 0
	lappend box -c behind [lindex $val $index] $wpos $hpos [expr {$wpos + 95}] [expr {$hpos + 15}]
	incr index
	incr hpos 30
}

#===============================================================================
# ×××× Dialog building help procs ×××× #
#===============================================================================

proc css::PropertyPrompt {prop hpos wp b} {
	upvar $b box $wp wpos
	set wpos 10
	set ex 0
	if {[string length $prop] > 14} {set ex 35}
	if {[string length $prop] > 20} {set ex 55}
	lappend box -t ${prop}: $wpos $hpos [expr {$wpos + 110 + $ex}] [expr {$hpos + 15}]
	incr wpos 120
	incr wpos $ex
}

proc css::NumChoice {prop type percent number v b hp wp ind} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	global css::Choices
	set wpos [css::PropertyPrompt $prop $hpos $wpos box]
	css::ChoiceList [set css::Choices($prop)] val box hpos wpos index 1 95
	css::NumberBox $hpos wpos val index box $type $percent $number
	incr hpos 30
}

proc css::NumberBox {hpos wp v ind b type percent number} {
	upvar $v val $wp wpos $b box $ind index
	
	global css::Units
	set units [set css::Units($type)]
	if {$percent} {lappend units %}
	if {$number} {set units "{ } $units"}
	lappend box -e [lindex $val $index] $wpos $hpos [expr {$wpos + 50}] [expr {$hpos + 15}]
	lappend box -m [concat [list [lindex $val [expr {$index + 1}]]] $units] \
	  [expr {$wpos + 60}] $hpos [expr {$wpos + 120}] [expr {$hpos + 20}]
	incr index 2
	incr wpos 180
}

proc css::NumberNoUnitBox {hpos wp v ind b} {
	upvar $v val $wp wpos $b box $ind index
	
	lappend box -e [lindex $val $index] $wpos $hpos [expr {$wpos + 50}] [expr {$hpos + 15}]
	incr wpos 60
	incr index
}

proc css::ChoiceList {items v b hp wp ind {inherit 1} {wd 200}} {
	upvar $v val $b box $hp hpos $wp wpos $ind index
	
	global css::IsDescriptor
	if {${css::IsDescriptor} && ![llength $items]} {return}
	if {[llength $items]} {
		set inh ""
		if {!${css::IsDescriptor} && $inherit} {set inh "inherit -"}
		lappend box -m [concat  [list [lindex $val $index]] $inh {" "} $items] \
		  $wpos $hpos [expr {$wpos + $wd}] [expr {$hpos + 20}]
	} else {
		set wd 95
		lappend box -c inherit [lindex $val $index] $wpos $hpos [expr {$wpos + 95}] [expr {$hpos + 15}]
	}
	incr wpos [expr $wd + 10]
	incr index
}

proc css::ColorBox {v b hp wp ind bt ba} {
	upvar $v val $b box $hp hpos $wp wpos $ind index $bt buttons $ba buttonAction
	global html::userColors html::basicColors css::Colors
	set htmlColors [lsort [array names html::userColors]]
 	append htmlColors " - " ${html::basicColors} " - " ${css::Colors}
	lappend box -e [lindex $val $index] 130 $hpos 200 [expr {$hpos + 15}] \
	-m [concat [list [lindex $val [expr {$index + 1}]] { }] $htmlColors] \
	210 $hpos 350 [expr {$hpos + 20}] \
	-b "New ColorÉ" 360 $hpos 460 [expr {$hpos + 20}]
	incr index 3
	lappend buttons [expr {$index - 1}]
	set buttonAction([expr {$index - 1}]) css::ColorButton
	set wpos 120
	incr hpos 40	
}

proc css::UrlBox {v b hp wp ind bt ba} {
	upvar $v val $b box $hp hpos $wp wpos $ind index $bt buttons $ba buttonAction
	global html::UserURLs
	lappend box -e [lindex $val $index] 130 $hpos 460 [expr {$hpos + 15}] \
	-m [concat [list [lindex $val [expr {$index + 1}]] { }] ${html::UserURLs}] \
	130 [expr {$hpos + 25}] 460 [expr {$hpos + 45}] \
	-b "FileÉ" 10 [expr {$hpos + 20}] 70 [expr {$hpos + 40}]
	incr index 3
	lappend buttons [expr {$index - 1}]
	set buttonAction([expr {$index - 1}]) css::FileButton
	set wpos 120
	incr hpos 50
}

proc css::MediaList {v b hp wp ind bt ba} {
	upvar $v val $b box $hp hpos $wp wpos $ind index $bt buttons $ba buttonAction
	
	global HTMLmodeVars
	lappend box -m [concat [list [lindex $val $index] { }] $HTMLmodeVars(mediatypes)] \
	  130 $hpos 260 [expr {$hpos + 20}] \
	  -e [lindex $val [expr {$index + 1}]] 130 [expr {$hpos + 30}] 460 [expr {$hpos + 45}] \
	  -b Add 270 $hpos 330 [expr {$hpos + 20}]
	lappend buttons [expr {$index + 2}]
	set buttonAction([expr {$index + 2}]) css::FamilyAddButton
	incr index 3
	incr hpos 60
}


proc css::ShorthandBox {group hp b} {
	upvar $hp hpos $b box
	global css::Shorthand css::UseShort css::InheritAll
	if {[set css::Shorthand($group)]} {
		lappend box -c "Inherit all" ${css::InheritAll} 10 $hpos 150 [expr {$hpos + 15}]
		lappend box -c "Use shorthand form if possible" ${css::UseShort} 160 $hpos 400 [expr {$hpos + 15}]
		incr hpos 20
	}
}

proc css::AllValuesBox {hp b} {
	upvar $hp hpos $b box
	global css::SetAllValues
	lappend box -r "Set all values individually" ${css::SetAllValues} 10 $hpos 300 [expr {$hpos + 15}]
	lappend box -r "Add missing values automatically if possible" [expr {!${css::SetAllValues}}] 10 [expr {$hpos + 20}] 350 [expr {$hpos + 35}]
	incr hpos 40	
}
