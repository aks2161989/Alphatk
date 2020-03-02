## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  CSS mode - tools for editing CSS documents
 # 
 #  FILE: "cssProperties.tcl"
 #                                    created: 99-06-27 16.56.02 
 #                                last update: 2005-02-21 17:51:15 
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

proc cssProperties.tcl {} {}

#===============================================================================
# ×××× Definition of CSS properties ×××× #
#
# The following arrays are defined:
# css::Property(<property>)     = type of property
# css::Choices(<property>)      = list of allowed values for properties of type 'choices' 
#                                 or similar
# css::Range(<property>)        = allowed range of values for properties taking a 
#                                 numerical value
# css::Group(<property>)        = for properties being a group of other properties, 
#                                 this defines the group
# css::Shorthand(<property>)    = flag telling if a group defines a possible shorthand notation
# css::MakeShort(<property>)    = a proc for shorthand properties to take the individual 
#                                 values and make the shorthand version
# css::ExpandProps(<property>)  = a proc for shorthand properties to take the shorthand value
#                                 and expand it to the individual values
# css::Descriptor(<descriptor>) = type of descriptor
#
# The following procs are defined for each property type.
# css::BuildDialog<proptype>   = the proc for building the property dialog
#                                (found in cssBuildDialog.tcl)
# css::ReadDialog<proptype>    = the proc for reading the property dialog
#                                (found in cssReadProperties.tcl)
# css::GetProperties<proptype> = the proc for parsing the property value in a document
#                                and get a default value for the property dialog
#                                (found in cssGetProperties.tcl)
# css::Complete<proptype>      = to complete the property value when using electric completions
#                                (found in CSSCompletions.tcl)
#===============================================================================

set css::GroupLikeProperties {group border font}

# Units

set css::Units(length) {em ex px pt cm mm in pc}
set css::Units(angle) {deg grad rad}
set css::Units(time) {ms s}
set css::Units(frequency) {Hz kHz}
set css::Units(number) {}

# Some at-rules
set css::Property(@charset) @charset
set css::Property(@import) @import
set css::Property(@media) @media
set css::Property(@page) @page

# Box model

set css::Property(margin-top) lpc
set css::Choices(margin-top) auto
set css::Range(margin-top) {-i:i}
set css::Property(margin-right) lpc
set css::Choices(margin-right) auto
set css::Range(margin-right) {-i:i}
set css::Property(margin-bottom) lpc
set css::Choices(margin-bottom) auto
set css::Range(margin-bottom) {-i:i}
set css::Property(margin-left) lpc
set css::Choices(margin-left) auto
set css::Range(margin-left) {-i:i}
set css::Property(margin) group
set css::Group(margin) {margin-top margin-right margin-bottom margin-left}
set css::Shorthand(margin) 1
set css::ExtraDialog(margin) css::AllValuesBox
set css::ReadExtraDialog(margin) css::ReadAllValuesBox
set css::AddMissingValues(margin) css::AddMissingVals
set css::MakeShort(margin) css::MakeShort4lengths
set css::ExpandProps(margin) css::ExpandPile

set css::Property(padding-top) lp
set css::Range(padding-top) {0:i}
set css::Property(padding-right) lp
set css::Range(padding-right) {0:i}
set css::Property(padding-bottom) lp
set css::Range(padding-bottom) {0:i}
set css::Property(padding-left) lp
set css::Range(padding-left) {0:i}
set css::Property(padding) group
set css::Group(padding) {padding-top padding-right padding-bottom padding-left}
set css::Shorthand(padding) 1
set css::ExtraDialog(padding) css::AllValuesBox
set css::ReadExtraDialog(padding) css::ReadAllValuesBox
set css::AddMissingValues(padding) css::AddMissingVals
set css::MakeShort(padding) css::MakeShort4lengths
set css::ExpandProps(padding) css::ExpandPile

set css::Property(border-top-width) lc
set css::Choices(border-top-width) {thin medium thick}
set css::Range(border-top-width) {0:i}
set css::Property(border-right-width) lc
set css::Choices(border-right-width) {thin medium thick}
set css::Range(border-right-width) {0:i}
set css::Property(border-bottom-width) lc
set css::Choices(border-bottom-width) {thin medium thick}
set css::Range(border-bottom-width) {0:i}
set css::Property(border-left-width) lc
set css::Choices(border-left-width) {thin medium thick}
set css::Range(border-left-width) {0:i}
set css::Property(border-width) group
set css::Group(border-width) {border-top-width border-right-width border-bottom-width border-left-width}
set css::Shorthand(border-width) 1
set css::ExtraDialog(border-width) css::AllValuesBox
set css::ReadExtraDialog(border-width) css::ReadAllValuesBox
set css::AddMissingValues(border-width) css::AddMissingVals
set css::MakeShort(border-width) css::MakeShort4lengths
set css::ExpandProps(border-width) css::ExpandPile

set css::Property(border-top-color) cc
set css::Choices(border-top-color) {transparent}
set css::Property(border-right-color) cc
set css::Choices(border-right-color) {transparent}
set css::Property(border-bottom-color) cc
set css::Choices(border-bottom-color) {transparent}
set css::Property(border-left-color) cc
set css::Choices(border-left-color) {transparent}
set css::Property(border-color) group
set css::Group(border-color) {border-top-color border-right-color border-bottom-color border-left-color}
set css::Shorthand(border-color) 1
set css::ExtraDialog(border-color) css::AllValuesBox
set css::ReadExtraDialog(border-color) css::ReadAllValuesBox
set css::AddMissingValues(border-color) css::AddMissingVals
set css::MakeShort(border-color) css::MakeShort4lengths
set css::ExpandProps(border-color) css::ExpandPile

set css::Property(border-top-style) choices
set css::Choices(border-top-style) {dotted dashed solid double groove ridge inset outset hidden none}
set css::Property(border-right-style) choices
set css::Choices(border-right-style) {dotted dashed solid double groove ridge inset outset hidden none}
set css::Property(border-bottom-style) choices
set css::Choices(border-bottom-style) {dotted dashed solid double groove ridge inset outset hidden none}
set css::Property(border-left-style) choices
set css::Choices(border-left-style) {dotted dashed solid double groove ridge inset outset hidden none}
set css::Property(border-style) group
set css::Group(border-style) {border-top-style border-right-style border-bottom-style border-left-style}
set css::Shorthand(border-style) 1
set css::ExtraDialog(border-style) css::AllValuesBox
set css::ReadExtraDialog(border-style) css::ReadAllValuesBox
set css::AddMissingValues(border-style) css::AddMissingVals
set css::MakeShort(border-style) css::MakeShort4lengths
set css::ExpandProps(border-style) css::ExpandPile

set css::Property(border-top) group
set css::Group(border-top) {border-top-width border-top-color border-top-style}
set css::Shorthand(border-top) 1
set css::MakeShort(border-top) css::MakeShortPile
set css::ExpandProps(border-top) css::ExpandPile
set css::Property(border-right) group
set css::Group(border-right) {border-right-width border-right-color border-right-style}
set css::Shorthand(border-right) 1
set css::MakeShort(border-right) css::MakeShortPile
set css::ExpandProps(border-right) css::ExpandPile
set css::Property(border-bottom) group
set css::Group(border-bottom) {border-bottom-width border-bottom-color border-bottom-style}
set css::Shorthand(border-bottom) 1
set css::MakeShort(border-bottom) css::MakeShortPile
set css::ExpandProps(border-bottom) css::ExpandPile
set css::Property(border-left) group
set css::Group(border-left) {border-left-width border-left-color border-left-style}
set css::Shorthand(border-left) 1
set css::MakeShort(border-left) css::MakeShortPile
set css::ExpandProps(border-left) css::ExpandPile

set css::Property(border) border
set css::Group(border) {border-top-width border-top-style border-top-color}
set css::Shorthand(border) 1
set css::MakeShort(border) css::MakeShortPile
set css::ExpandProps(border) css::ExpandBorder

# Visual formatting

set css::Property(display) choices
set css::Choices(display) {block inline list-item marker run-in compact table 
inline-table table-row-group table-header-group table-footer-group table-row
table-column-group table-column table-cell table-caption none}

set css::Property(position) choices
set css::Choices(position) {static relative absolute fixed}
set css::Property(top) lpc
set css::Range(top) {-i:i}
set css::Choices(top) auto
set css::Property(right) lpc
set css::Range(right) {-i:i}
set css::Choices(right) auto
set css::Property(bottom) lpc
set css::Range(bottom) {-i:i}
set css::Choices(bottom) auto
set css::Property(left) lpc
set css::Range(left) {-i:i}
set css::Choices(left) auto
set css::Property(positioning) group
set css::Group(positioning) {position top right bottom left}
set css::Shorthand(positioning) 0

set css::Property(float) choices
set css::Choices(float) {left right none}
set css::Property(clear) choices
set css::Choices(clear) {left right both none}
set css::Property(floats) group
set css::Group(floats) {float clear}
set css::Shorthand(floats) 0

set css::Property(z-index) ic
set css::Choices(z-index) auto
set css::Range(z-index) {-i:i}

set css::Property(direction) choices
set css::Choices(direction) {ltr rtl}
set css::Property(unicode-bidi) choices
set css::Choices(unicode-bidi) {embed bidi-override normal}
set css::Property(text-direction) group
set css::Group(text-direction) {direction unicode-bidi}
set css::Shorthand(text-direction) 0

set css::Property(width) lpc
set css::Choices(width) auto
set css::Range(width) {0:i}
set css::Property(min-width) lp
set css::Range(min-width) {0:i}
set css::Property(max-width) lpc
set css::Choices(max-width) none
set css::Range(max-width) {0:i}
set css::Property(height) lpc
set css::Choices(height) auto
set css::Range(height) {0:i}
set css::Property(min-height) lp
set css::Range(min-height) {0:i}
set css::Property(max-height) lpc
set css::Choices(max-height) none
set css::Range(max-height) {0:i}
set css::Property(content-size) group
set css::Group(content-size) {width min-width max-width height min-height max-height}
set css::Shorthand(content-size) 0

set css::Property(vertical-align) lpc
set css::Choices(vertical-align) {sub super top text-top middle bottom text-bottom baseline}
set css::Range(vertical-align) {-i:i}

set css::Property(overflow) choices
set css::Choices(overflow) {hidden scroll auto visible}
set css::Property(clip) clip
set css::Range(clip) {-i:i}
set css::Choices(clip) auto
set css::Property(visibility) choices
set css::Choices(visibility) {visible hidden collapse}
set css::Property(visual-effects) group
set css::Group(visual-effects) {overflow clip visibility}
set css::Shorthand(visual-effects) 0

# Generated content

set css::Property(content) content
set css::Choices(content) {open-quote close-quote no-open-quote no-close-quote}

set css::Property(quotes) quotes
set css::Choices(quotes) none

set css::Property(counter-reset) counter
set css::Choices(counter-reset) none
set css::Property(counter-increment) counter
set css::Choices(counter-increment) none
set css::Property(counters) group
set css::Group(counters) {counter-reset counter-increment}
set css::Shorthand(counters) 0

set css::Property(marker-offset) lc
set css::Choices(marker-offset) auto
set css::Range(marker-offset) {-i:i}

set css::Property(list-style-type) choices
set css::Choices(list-style-type) {disc circle square decimal decimal-leading-zero
lower-roman upper-roman lower-greek lower-alpha lower-latin upper-alpha upper-latin
hebrew armenian georgian cjk-ideographic hiragana katakana hiragana-iroha
katakana-iroha none}
set css::Property(list-style-image) uc
set css::Choices(list-style-image) auto
set css::Property(list-style-position) choices
set css::Choices(list-style-position) {inside outside}
set css::Property(list-style) group
set css::Group(list-style) {list-style-type list-style-image list-style-position}
set css::Shorthand(list-style) 1
set css::MakeShort(list-style) css::MakeShortPile
set css::ExpandProps(list-style) css::ExpandListStyle

# Paged media

set css::Property(size) size
set css::Choices(size) {portrait landscape auto}
set css::Range(size) {0:i}

set css::Property(marks) marks

set css::Property(page-break-before) choices
set css::Choices(page-break-before) {always avoid left right auto}
set css::Property(page-break-after) choices
set css::Choices(page-break-after) {always avoid left right auto}
set css::Property(page-break-inside) choices
set css::Choices(page-break-inside) {avoid auto}
set css::Property(orphans) integer
set css::Range(orphans) {0:i}
set css::Property(widows) integer
set css::Range(widows) {0:i}
set css::Property(page-breaks) group
set css::Group(page-breaks) {page-break-before page-break-after page-break-inside orphans widows}
set css::Shorthand(page-breaks) 0

set css::Property(page) page

# Color & background

set css::Property(color) color

set css::Property(background-color) cc
set css::Choices(background-color) transparent
set css::Property(background-image) uc
set css::Choices(background-image) none
set css::Property(background-repeat) choices
set css::Choices(background-repeat) {repeat-x repeat-y no-repeat repeat}
set css::Property(background-attachment) choices
set css::Choices(background-attachment) {fixed scroll}
set css::Property(background-position) backpos
set css::Range(background-position) {-i:i}
set css::Property(background) group
set css::Group(background) {background-color background-image background-repeat
background-attachment background-position}
set css::Shorthand(background) 1
set css::MakeShort(background) css::MakeShortPile
set css::ExpandProps(background) css::ExpandBackground

# Fonts

set css::Property(font-family) family
set css::Choices(font-family) {serif sans-serif cursive fantasy monospace}
set css::Property(font-style) choices
set css::Choices(font-style) {italic oblique normal}
set css::Property(font-variant) choices
set css::Choices(font-variant) {small-caps normal}
set css::Property(font-weight) choices
set css::Choices(font-weight) {bold bolder lighter 100 200 300 400 500 600 700 800 900 normal}
set css::Property(font-size) lpc
set css::Choices(font-size) {larger smaller xx-small x-small small medium large x-large xx-large}
set css::Range(font-size) {0:i}
set css::Property(line-height) nlpc
set css::Choices(line-height) normal
set css::Range(line-height) {0:i}
set css::Property(font) font
set css::Choices(font) {caption icon menu message-box small-caption status-bar}
set css::Group(font) {font-style font-variant font-weight font-size line-height font-family}
set css::Shorthand(font) 1
set css::MakeShort(font) css::MakeShortFont
set css::ExpandProps(font) css::ExpandFont

set css::Property(font-stretch) choices
set css::Choices(font-stretch) {wider narrower ultra-condensed extra-condensed condensed 
semi-condensed semi-expanded expanded extra-expanded ultra-expanded normal}
set css::Property(font-size-adjust) nc
set css::Choices(font-size-adjust) none
set css::Range(font-size-adjust) {0:i}
set css::Property(other-properties) group
set css::Group(other-properties) {font-stretch font-size-adjust}
set css::Shorthand(other-properties) 0

set css::Descriptor(font-family) family
set css::Descriptor(font-style) fontstyle
set css::Descriptor(font-variant) fontvariant
set css::Descriptor(font-weight) fontstyle
set css::Descriptor(font-stretch) fontstyle
set css::Descriptor(font-size) fontsize
set css::Descriptor(font-selection) group
set css::Group(font-selection) {font-style font-variant font-weight font-stretch font-size font-family}
set css::Shorthand(font-selection) 0

set css::Descriptor(panose-1) panose
set css::Range(panose-1) {-i:i}
set css::Descriptor(stemv) number
set css::Range(stemv) {0:i}
set css::Descriptor(stemh) number
set css::Range(stemh) {0:i}
set css::Descriptor(slope) number
set css::Range(slope) {-i:i}
set css::Descriptor(cap-height) number
set css::Range(cap-height) {0:i}
set css::Descriptor(x-height) number
set css::Range(x-height) {0:i}
set css::Descriptor(ascent) number
set css::Range(ascent) {0:i}
set css::Descriptor(descent) number
set css::Range(descent) {0:i}
set css::Descriptor(matching) group 
set css::Group(matching) {panose-1 stemv stemh slope cap-height x-height ascent descent}
set css::Shorthand(matching) 0

set css::Descriptor(widths) widths
set css::Descriptor(bbox) bbox
set css::Range(bbox) {-i:i}
set css::Descriptor(definition-src) url
set css::Descriptor(synthesis) group
set css::Group(synthesis) {widths bbox definition-src}
set css::Shorthand(synthesis) 0

set css::Descriptor(baseline) number
set css::Range(baseline) {0:i}
set css::Descriptor(centerline) number
set css::Range(centerline) {0:i}
set css::Descriptor(mathline) number
set css::Range(mathline) {0:i}
set css::Descriptor(topline) number
set css::Range(topline) {0:i}
set css::Descriptor(alignment) group
set css::Group(alignment) {baseline centerline mathline topline}
set css::Shorthand(alignment) 0

set css::Descriptor(unicode-range) unirange
set css::Descriptor(units-per-em) number
set css::Range(units-per-em) {0:i}
set css::Descriptor(src) src
set css::Descriptor(other-descriptors) group
set css::Group(other-descriptors) {unicode-range units-per-em src}
set css::Shorthand(other-descriptors) 0

# Text

set css::Property(text-indent) lp
set css::Range(text-indent) {-i:i}
set css::Property(text-align) textalign
set css::Choices(text-align) {left right center justify}
set css::Property(text-decoration) textdecoration
set css::Choices(text-decoration) {underline overline line-through blink}
set css::Property(letter-spacing) lc
set css::Choices(letter-spacing) normal
set css::Range(letter-spacing) {-i:i}
set css::Property(word-spacing) lc
set css::Choices(word-spacing) normal
set css::Range(word-spacing) {-i:i}
set css::Property(text-transform) choices
set css::Choices(text-transform) {capitalize uppercase lowercase none}
set css::Property(white-space) choices
set css::Choices(white-space) {pre nowrap normal}
set css::Property(text) group
set css::Group(text) {text-indent text-align text-decoration letter-spacing
word-spacing text-transform white-space}
set css::Shorthand(text) 0

set css::Property(text-shadow) textshadow
set css::Range(horizontal) {-i:i}
set css::Range(vertical) {-i:i}
set css::Range(blur) {0:i}

# Tables

set css::Property(caption-side) choices
set css::Choices(caption-side) {top bottom left right}
set css::Property(table-layout) choices
set css::Choices(table-layout) {fixed auto}
set css::Property(border-collapse) choices
set css::Choices(border-collapse) {separate collapse}
set css::Property(border-spacing) borderspacing
set css::Range(border-spacing) {0:i}
set css::Property(empty-cells) choices
set css::Choices(empty-cells) {hide show}
set css::Property(speak-header) choices
set css::Choices(speak-header) {always once}
set css::Property(tables) group
set css::Group(tables) {caption-side table-layout border-collapse border-spacing empty-cells
speak-header}
set css::Shorthand(tables) 0

# User interface

set css::Property(cursor) cursor
set css::Choices(cursor) {auto crosshair default pointer move e-resize ne-resize nw-resize
n-resize se-resize sw-resize s-resize w-resize text wait help}

set css::Property(outline-width) lc
set css::Choices(outline-width) {thin medium thick}
set css::Range(outline-width) {0:i}
set css::Property(outline-style)  choices
set css::Choices(outline-style) {dotted dashed solid double groove ridge inset outset hidden none}
set css::Property(outline-color) cc
set css::Choices(outline-color) invert
set css::Property(outline) group
set css::Group(outline) {outline-width outline-style outline-color}
set css::Shorthand(outline) 1
set css::MakeShort(outline) css::MakeShortPile
set css::ExpandProps(outline) css::ExpandPile

# Aural

set css::Property(volume) npc
set css::Choices(volume) {silent x-soft soft medium loud x-loud}
set css::Range(volume) {0:100}

set css::Property(pause-before) tp
set css::Range(pause-before) {0:i}
set css::Property(pause-after) tp
set css::Range(pause-after) {0:i}
set css::Property(pause) group
set css::Group(pause) {pause-before pause-after}
set css::Shorthand(pause) 1
set css::MakeShort(pause) css::MakeShortPileIfBoth
set css::ExpandProps(pause) css::ExpandPileIfBoth

set css::Property(cue-before) uc
set css::Choices(cue-before) none
set css::Property(cue-after) uc
set css::Choices(cue-after) none
set css::Property(cue) group
set css::Group(cue) {cue-before cue-after}
set css::Shorthand(cue) 1
set css::MakeShort(cue) css::MakeShortPileIfBoth
set css::ExpandProps(cue) css::ExpandCue

set css::Property(play-during) playduring
set css::Choices(play-during) {auto none}

set css::Property(azimuth) azimuth
set css::Choices(azimuth) {leftwards rightwards}
set css::Range(azimuth) {-360:360}
set css::Property(elevation) ac
set css::Choices(elevation) {below level above higher lower}
set css::Range(elevation) {-90:90}
set css::Property(spatial) group
set css::Group(spatial) {azimuth elevation}
set css::Shorthand(spatial) 0

set css::Property(speech-rate) nc
set css::Choices(speech-rate) {x-slow slow medium fast x-fast faster slower}
set css::Range(speech-rate) {0:i}
set css::Property(voice-family) family
set css::Choices(voice-family) {male female child}
set css::Property(pitch) fc
set css::Choices(pitch) {x-low low medium high x-high}
set css::Range(pitch) {0:i}
set css::Property(pitch-range) number
set css::Range(pitch-range) {0:100}
set css::Property(stress) number
set css::Range(stress) {0:100}
set css::Property(richness) number
set css::Range(richness) {0:100}
set css::Property(voice) group
set css::Group(voice) {speech-rate voice-family pitch pitch-range stress richness}
set css::Shorthand(voice) 0

set css::Property(speak) choices
set css::Choices(speak) {none spell-out normal}
set css::Property(speak-punctuation) choices
set css::Choices(speak-punctuation) {code none}
set css::Property(speak-numeral) choices
set css::Choices(speak-numeral) {digits continuous}
set css::Property(speech) group
set css::Group(speech) {speak speak-punctuation speak-numeral}
set css::Shorthand(speech) 0
