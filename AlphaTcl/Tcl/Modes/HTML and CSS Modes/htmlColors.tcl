## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "htmlColors.tcl"
 #                                    created: 00-01-15 18.41.04 
 #                                last update: 2005-02-21 17:51:27 
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


#==============================================================================
# This file contains procs for the Colors submenu plus other procs for
# handling colors.
#==============================================================================

proc html::AllColorSets {} {
	return [html::FindAllSets Colors]
}

proc html::ColorsMenuProc {item} {
	switch -glob -- $item {
		"New Color Set" {html::NewColorSet}
		"Delete Color Set" {html::DeleteCacheSet Colors}
		"Edit Color Set" {html::EditCacheSet Colors}
		"Rename Color Set" {html::RenameCacheSet Colors}
		default {html::ActivateCacheSet Colors $item}
	}
}


# Add color sets to Color menu
proc html::ColorsMenuExtra {} {
	html::SetsMenuExtra Colors Color Colors activeColorSets
}

proc html::ReadActiveColorSets {} {
	global HTMLmodeVars html::PrefsFolder
	upvar #0 html::userColors colorNumber html::userColorname colorName 
	unset -nocomplain colorNumber
	unset -nocomplain colorName
	foreach cols $HTMLmodeVars(activeColorSets) {
		catch {source [file join ${html::PrefsFolder} Colors $cols]}
	}
}

proc html::SaveColorSet {colorset number} {
	global html::PrefsFolder mode
	upvar $number colorNumber
	file::ensureDirExists [file join ${html::PrefsFolder} Colors]
	set txt ""
	foreach col [array names colorNumber] {
		set col1 [quote::Insert $col]
		append txt "if {!\[info exists \"colorNumber($col1)\"\] && !\[info exists \"colorName($colorNumber($col))\"\]}"
		append txt " {set \"colorNumber($col1)\" {$colorNumber($col)}; set \"colorName($colorNumber($col))\" {$col}}\r"
	}
	html::SaveCache [file join Colors $colorset] $txt
}

proc html::NewColorSet {{edit 1}} {
	set cset [html::GiveSetAName Colors Color]
	if {$cset == ""} {return}
	html::SaveColorSet $cset dummy
	menu::buildSome Colors 
	html::ActivateCacheSet Colors $cset
	if {$edit} {html::EditAColorSet $cset}
	return $cset
}

# Dialog to handle colors.
proc html::EditAColorSet {colorset} {
	global html::PrefsFolder
	source [file join ${html::PrefsFolder} Colors $colorset]
	
	set this ""
	while {1} {
		set colors [lsort [array names colorNumber]]
		set box "[dialog::title $colorset 370] -t {Colors:} 10 20 80 40 \
		  -t Number: 10 60 80 80 \
		  -b Done 10 110 75 130 \
		  -b New… 90 110 155 130 \
		  -b {New by number…} 260 20 395 40"
		if {[llength $colors]} {
			append box " -m [list [concat [list $this] $colors]] 90 20 230 40"
			append box " -b Change… 168 110 250 130 -b Remove 260 110 330 130 \
			  -b {Change number…} 260 50 395 70 -b View… 260 80 330 100"
			foreach c $colors {
				lappend box -n $c -t $colorNumber($c) 90 60 160 100
			}
		} else {
			append box  " -m {{ } { }} 90 20 230 40"
		}
		set values [eval [concat dialog -w 400 -h 140 $box]]
		set this [lindex $values 3]
		if {[lindex $values 0]} {
			html::SaveColorSet $colorset colorNumber
			html::ReadActiveColorSets
			return
		} elseif {[lindex $values 1]} {
			set newc [html::AddNewColor colorNumber colorName]
			if {[string length $newc]} {set this $newc}
		} elseif {[lindex $values 2]} {
			set newc [html::NameColor "" "" "" colorNumber colorName]
			if {[string length $newc]} {set this $newc}
		} elseif {[lindex $values 4]} {
			set newcolor [eval [concat colorTriple [list $this] [html::HexColor $colorNumber($this)]]]
			if {![string length $newcolor]} {continue}
			set newc [html::NameColor [html::ColorHex $newcolor] $this $colorNumber($this) colorNumber colorName]
			if {[string length $newc]} {set this $newc}		
		} elseif {[lindex $values 5]} {
			if {[askyesno "Remove $this?"] == "yes"} {
				unset colorName($colorNumber($this))
				unset colorNumber($this)
				status::msg "Color removed."
			}
		} elseif {[lindex $values 6]} {
			set newc [html::NameColor "" $this $colorNumber($this) colorNumber colorName]
			if {[string length $newc]} {set this $newc}		
		} else {
			eval [concat colorTriple [list $this] [html::HexColor $colorNumber($this)]]
		}
	}
}

# Checks if colornumber is identical to another colour.
proc html::ColorIdentical {colornumber changeColor name} {
	global html::ColorNumber
	upvar $name colorName
	if {( ![catch {set colTest [set html::ColorNumber($colornumber)]}] || \
	  ![catch {set colTest $colorName($colornumber)}] ) && \
	  $colTest != $changeColor} {
		alertnote "This color is identical with '$colTest'. Two identical \
		  colors cannot be defined."
		return 1
	}
	return 0
}

# Converts a red green blue number to hex.
proc html::ColorHex {color} {
	foreach c $color {
		set c1 [format %1X [expr {$c / 256}]]
		if {[string length $c1] == 1} {set c1 "0$c1"}
		append colornumber $c1
	}
	return "#$colornumber"
}

# Converts a hex number to red green blue.
proc html::HexColor {number} {
	foreach c [split [string range $number 1 end] ""] {
		lappend numbers [format %1d 0x$c]
	}
	set red [expr {[lindex $numbers 0] * 4096 + [lindex $numbers 1] * 256}]
	set green [expr {[lindex $numbers 2] * 4096 + [lindex $numbers 3] * 256}]
	set blue [expr {[lindex $numbers 4] * 4096 + [lindex $numbers 5] * 256}]
	return [list $red $green $blue]
}	

proc html::AddNewColor {number name} {
	upvar $number num $name nm
	set newcolor [colorTriple "New color"]	
	if {$newcolor == ""} {return }
	return [html::NameColor [html::ColorHex $newcolor] "" "" num nm]
}

proc html::AddANewColor {{def ""}} {
	global HTMLmodeVars html::PrefsFolder html::ColorNumber html::userColorname
	set newcolor [eval colorTriple {{New color}} $def]	
	if {$newcolor == ""} {return}
	set chex [html::ColorHex $newcolor]
	if {[info exists html::ColorNumber($chex)]} {return [set html::ColorNumber($chex)]}
	if {[info exists html::userColorname($chex)]} {return [set html::userColorname($chex)]}
	set values ""
	while {1} {
		set sets [lsort $HTMLmodeVars(activeColorSets)]
		if {![llength $sets]} {set sets {{ }}}
		set box {-T "Color name"}
		append box " -w 430 -h 95 -t {Color name:} 10 10 100 30 \
		  -e [list [lindex $values 0]] 110 10 175 25 \
		  -t {Add to color set:} 10 35 130 55 \
		  -m [list [concat [list [lindex $values 1]] $sets]] 140 35 280 55 \
		  -b OK 350 65 415 85 -b Cancel 265 65 330 85 -b {New color set…} 290 35 420 55 \
		  -b {Don't name color} 10 65 160 85"
		set values [eval dialog $box]
		if {[lindex $values 3]} {return}
		if {[lindex $values 4]} {
			set nset [html::NewColorSet 0]
			if {$nset != ""} {set values [lreplace $values 1 1 $nset]}
		}
		if {[lindex $values 5]} {return $chex}
		if {[lindex $values 2]} {
			if {![llength $HTMLmodeVars(activeColorSets)]} {
				alertnote "You must define a new color set to add the color to."
				set nset [html::NewColorSet 0]
				if {$nset != ""} {set values [lreplace $values 1 1 $nset]}
				continue
			}
			if {[set name [string trim [lindex $values 0]]] == ""} {
				alertnote "You must give the color a name."
				continue
			}
			catch {source [file join ${html::PrefsFolder} Colors [set cset [lindex $values 1]]]}
			if {[set name [html::NameColor $chex "" "" colorNumber colorName $name]] != ""} {
				html::SaveColorSet $cset colorNumber
				html::ReadActiveColorSets
				return $name
			}
		}
	}
}

proc html::NameColor {colornumber changeColor changeNumber number name {colorname ""}} {
	global html::basicColors css::Colors
	upvar $number Number $name Name
	set predef [concat ${html::basicColors} ${css::Colors}]
	set alluserColors [array names Number]
	set noname 1
	set picker [string length $colornumber]
	set values [list $changeColor $changeNumber]
	while {$noname} {
		if {$colorname == ""} {
			if {!$picker} {
				if {[string length $changeColor]} {
					set ttt Change
				} else {
					set ttt New
				}
				set box [dialog::title "$ttt color" 250]
				lappend box -t "Name:" 10 25 75 45 \
				  -e [lindex $values 0] 80 25 290 40 \
				  -t "Number:" 10 55 75 75 \
				  -e [lindex $values 1] 80 55 150 70 \
				  -b OK 220 100 285 120 \
				  -b Cancel 135 100 200 120
				set values [eval [concat dialog -w 300 -h 130 $box]]
				if {[lindex $values 3]} {return}
				set colorname [string trim [lindex $values 0]]
				set colornumber [string trim [lindex $values 1]]
				set coltest [html::CheckColorNumber $colornumber]
				if {$coltest == "0"} {
					alertnote "$colornumber is not a valid color number. It should be of the form #RRGGBB."
					set colorname ""
					continue
				}
				set colornumber $coltest
				if {[html::ColorIdentical $colornumber $changeColor Name]} {return}
			} else {
				if {[html::ColorIdentical $colornumber $changeColor Name]} {return}
				if {[catch {prompt "Color name" $changeColor} colorname]} { 
					# cancel
					return
				}
				set colorname [string trim $colorname]
			}
		} else {
			if {[html::ColorIdentical $colornumber $changeColor Name]} {return}
			set retiferror 1
		}
		
		if {[lcontains predef $colorname]} {
			alertnote "Predefined color. Choose another name."
			if {[info exists retiferror]} {return}
		} elseif {$colorname != ""} {
			set replace 0
			if {[lcontains alluserColors $colorname] && \
			  $colorname != $changeColor} {
				set repl [expr {[alert -t caution -k Cancel -c "" -o Replace "Replace $colorname?"] == "Replace"}]
				if {$repl} { 
					set replace 1
					# remove the color first
					unset Name($Number($colorname))
					unset Number($colorname)
				} elseif {[info exists retiferror]} {
					return
				} else {
					set colorname ""
				}
			} else {
				set replace 1
			}
			# add the new color
			if {$replace} { 
				if {[string length $changeColor]} {
					unset Name($changeNumber)
					unset Number($changeColor)
				}
				set noname 0
				set Number($colorname) $colornumber
				set Name($colornumber) $colorname
			}
		} else {
			alertnote "You must name the color."
		}
	}
	return $colorname
}
