## -*-Tcl-*-
 # ###################################################################
 #  AlphaVOODOO - integrates Alpha with VOODOO
 # 
 #  FILE: "voodooDialogs.tcl"
 #                                    created: 6/27/97 {10:48:05 pm} 
 #                                last update: 03/19/2003 {06:19:36 PM} 
 #                                    version: 2.0
 #  Author: Jonathan Guyer
 #  E-mail: <jguyer@his.com>
 #     www: <http://www.his.com/jguyer/>
 #  
 # 
 #  Copyright (C) 1998-2001  Jonathan Guyer
 #  
 #  This program is free software; you can redistribute it and/or modify
 #  it under the terms of the GNU General Public License as published by
 #  the Free Software Foundation; either version 2 of the License, or
 #  (at your option) any later version.
 #  
 #  This program is distributed in the hope that it will be useful,
 #  but WITHOUT ANY WARRANTY; without even the implied warranty of
 #  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 #  GNU General Public License for more details.
 #  
 #  You should have received a copy of the GNU General Public License
 #  along with this program; if not, write to the Free Software
 #  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 # ###################################################################
 ##

namespace eval voodoo {}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::settings" --
 # 
 #  Display a dialog to set preferences for VOODOO
 # 
 # -------------------------------------------------------------------------
 ##
proc voodoo::settings {{connect 0} {level 0} {temp ""}} {
	global voodooCurrent
	
	if {!$level} {
		# save values in case of cancel
		# only necessary at lowest nesting level
		voodoo::pushVars settings
	} else {
		upvar $temp settings
	}
	
	if {[info exists settings(password)]} {
		set password $settings(password)
	} else {
		set password ""
	}
	
	if {[set dialogWidth [expr [lindex [getMainDevice] 2] - 70]] > 700} {
		set dialogWidth 700
	}
	set dialogMiddle [expr $dialogWidth / 2]
	
	set title "VOODOO settings for project \"$voodooCurrent\":"
	
	if {$connect} {
		set OK "Connect"
	} else {
		set OK "OK"
	}
	
	set result [dialog -w $dialogWidth -h 250 \
		-t $title \
			[set l [expr $dialogMiddle - 4 * [string length $title]]] 10 \
			[expr $dialogWidth - $l] 26 \
		-t "Path:" 68 37 120 53  \
		-t "$settings(path)" 110 37 [expr $dialogWidth - 15] 53 \
		-p 110 37 [expr $dialogWidth - 15] 53 \
		-t "User name:" 28 104 103 120 \
		-t "Password:" [expr $dialogMiddle + 10] 104 \
						[expr $dialogMiddle + 81] 120 \
		\
		-b $OK [expr $dialogWidth - 75] 220 [expr $dialogWidth - 15] 240 \
		-b Cancel [expr $dialogWidth - 145] 220 [expr $dialogWidth - 85] 240 \
		-b "Variant(s)É" 10 169 100 189 \
		\
		-c "Lock and unlock local files" $settings(lockFiles) 110 60 385 76 \
		-c "Lock and unlock version groups" $settings(lockNodes) 110 80 385 96 \
		-e "$settings(user)" 110 104 [expr $dialogMiddle - 5] 120 \
		-e "$password" [expr $dialogMiddle + 85] 110 \
						[expr $dialogWidth - 15] 114 \
		-c "Always show logon dialog" $settings(showLogon) 110 127 385 143 \
		-c "Remember password" $settings(savePass) 110 147 385 163 \
		-e "$settings(selectedVariants)" 110 171 [expr $dialogWidth - 15] 187 \
		-c "Use variant filter" $settings(useFilter) 110 194 385 210 \
	]

	if {[lindex $result 1]} {
		# Cancel selected 
		return 0
	} 

	# Copy values to voodoo array
	set settings(lockFiles)	[lindex $result 3]
	set settings(lockNodes)	[lindex $result 4]
	set settings(user)		[lindex $result 5]
	set settings(showLogon)	[lindex $result 7]
	if {[set settings(savePass) [lindex $result 8]]} {
		set settings(password) [lindex $result 6]
	} elseif {[info exists settings(password)]} {
		unset settings(password)
	} 
	set settings(useFilter)		[lindex $result 10]
		
	set settings(selectedVariants)	[lindex $result 9]
	if {[lindex $result 2]} {
		# Variant(s)É selected
		if {[voodoo::selectVariants settings]} {
			set settings(useFilter) 1
		}

		# recursively call voodoo::settings to create
		# illusion of returning to settings dialog
		# from Variant(s)É dialog
		if {![voodoo::settings $connect [expr $level + 1] settings]} {
			# Cancel selected 
			return 0
		}	
	}
	
	if {!$level} {
		voodoo::popVars settings
		if {$connect} {
			voodoo::openProject [lindex $result 6]
		} 
	}
	
	return 1
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::path" --
 # 
 #  Display an SFGetBox to select a VOODOO project file
 #  
 # Results:
 # 
 #  Project path
 # -------------------------------------------------------------------------
 ##
proc voodoo::path {} {
	global voodooProject
	
	if {![catch {set project [get_directory -p "Select a VOODOO directory:"]} errMsg]} {
		# We have the user select the directory (hopefully Pete can be
		# convinced to allow file type/creator filtering in getfile), so we need
		# to glob to get the right file
	
		# get_directory appends a ":" if the selection is made from within
		# the directory, but does not if the selection is made from above
		set project [string trimright $project ":"]
		# Select the ".Proj" file within the selected directory
		set proj [lindex [glob -types Proj "$project:*"] 0]
		return $proj
	} else {
		# user cancelled, so return the existing project path
		if {[info exists voodooProject(path)]} {
			return $voodooProject(path)
		} else {
			return ""
		}
	}
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::connect" --
 # 
 #  Connect to $voodooProject(path), as $voodooProject(user) 
 #  with $voodooProject(password), interacting with the user to 
 #  obtain necessary information.
 # -------------------------------------------------------------------------
 ##
proc voodoo::connect {} {
	global voodooProject errorCode
	
	if {[voodoo::isConnected]} {
		return 1
	}
	
	if {[catch {set password $voodooProject(password)}]} {
		set password ""
		if {$voodooProject(savePass)} {
			set voodooProject(password) ""
		} 
	} 
	
	if {$voodooProject(showLogon) || !$voodooProject(savePass)} {
		set logon [dialog -w 300 -h 120 \
			-t "Connect to project\
				\"[file rootname [file tail $voodooProject(path)]]\"\
				as:" 20 10 290 26 \
			-t "User name:" 10 35 87 51 \
			-t "Password:" 15 60 87 76 \
			\
			-b "Connect" 230 90 290 110 \
			-b Cancel 150 90 210 110 \
			-e "$voodooProject(user)" 88 35 290 51 \
			-e "$password" 88 66 290 70 
		]
		if {[lindex $logon 0]} {
			# Connect
			set voodooProject(user) [lindex $logon 2]
			set password [lindex $logon 3]
			if {$voodooProject(savePass)} {
				set voodooProject(password) $password
			}
			set password [lindex [lindex $logon 3] 0]
			
			voodoo::openProject $password
	
			return 1
		} else {
			# Cancel
			return 0
		}
	} else {
		voodoo::openProject $voodooProject(password)
		return 1
	}
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::selectVariants" --
 # 
 #  Select variants from a list (hopefully) obtained from the
 #  current project
 # -------------------------------------------------------------------------
 ##
proc voodoo::selectVariants {temp} {	
	upvar $temp settings
	
	if {[voodoo::isConnected]} {
		set settings(variants) [voodoo::getVariants]
		set prompt "Select the visible variant(s):"
	} else {
		beep
		status::msg "WARNING! List is not up-to-date because\
			the project is not connected"
		set prompt "Select the visible variant(s):    (LIST OUT OF DATE!)"
		
		# We (erroneously) assume that users know what they're doing
		# and add any variants they may have typed into the variants list
		set settings(variants) [concat $settings(variants) $settings(selectedVariants)]
		set settings(variants) [lunique $settings(variants)]
	}

	# put up dialog to allow user to choose,
	# using previous selections as defaults
	if {[catch {set variants \
		[listpick -p $prompt \
			-L $settings(selectedVariants) -l $settings(variants)]} errMsg]} {
		
		return 0
	} else {
		set settings(selectedVariants) $variants 
		return 1
	}
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::removeProject" --
 # 
 #  Remove $project from list of known projects. 
 #  If $project not specified, allow user to select project(s) to remove.
 # -------------------------------------------------------------------------
 ##
proc voodoo::removeProject {{project ""}} {
	global voodooCurrent voodoo voodooProject
	
	set projects [voodoo::projects]
	if {![string length $project]} {
		if {[catch {\
			set projects [listpick -p "Remove which project(s)?" \
					-l $projects]}\
			] \
		||	![llength $projects]} {
			return
		}
	} 
	catch {
		foreach project $projects {
			if {[askyesno "Really remove project \"$project\" from list?"] == "yes"} {
				if {[info exists voodooCurrent]
				&&	$project == $voodooCurrent} {
					voodoo::disconnect
					set disconnect 1
				} else {
					set disconnect 0
				}
				
				set project [voodoo::projectFromName $project]
				global $project
				prefs::removeArray $project
				unset $project
				
				if {$disconnect} {
					trace vdelete voodooProject w voodoo::synchronize
					voodoo::defaultSettings
				} 
			}
	 	}
	}
	# resynchronize the list with the actual projects
	set voodoo(projects) [lsort [voodoo::projects]]
}

proc voodoo::chooseName {{name ""} {prompt ""}} {
	set newname [prompt "${prompt}Assign name to project:" [voodoo::legalizeName $name]]
	if {$newname == $name} {
		return $name
	} else {
		set legalname [voodoo::legalizeName $newname]
		if {$legalname != $newname} {
			if {[regexp {^\s*$} $newname]} {
				set prompt "Name must not be all white space. "
			} else {
				set prompt "\"$newname\" already taken. "
			}
			set newname [voodoo::chooseName $legalname $prompt]
		} else {
			set newname $legalname
		}
		return $newname
	}
}

proc voodoo::renameProject {{name ""}} {
	global voodoo voodooProject voodooCurrent
	
	if {$name == ""} {
		set projects [voodoo::projects]
		if {[llength $projects] > 1} {
			if {[catch {\
				set name [listpick -p "Rename which project?" \
						$projects]}\
				] \
			||	$name == ""} {
				return
			}
		} else {
			set name [lindex $projects 0]
		}
	}
		
	set newname [voodoo::chooseName $name]
	if {$newname == $name} {
		return $name
	} else {		
		set project [voodoo::projectFromName $name]
		
		global $project
		set ${project}(projectName) $newname

		if {[info exists voodooCurrent] \
			&&	$name == $voodooCurrent} {
			set voodooCurrent $newname
			set voodooProject(projectName) $newname
		}

		set voodoo(projects) [voodoo::projects]
		return $newname
	}
}

## 
 # -------------------------------------------------------------------------
 # 
 # "voodoo::displayResult" --
 # 
 #  Display a table of file names and result codes
 # -------------------------------------------------------------------------
 ##
proc voodoo::displayResult {files result {title "* Result *"}} {
	global voodooCurrent
	
	if {[set num [llength $files]] != [llength $result]} {
		error "The result codes are whack, man!"
	} elseif {$num} {
		new -n $title
		set win [lindex [winNames -f] 0]
		set title "VOODOO project \"$voodooCurrent\""
		set maxWidth 0
		foreach item $result {
			set maxWidth \
				[expr [expr [set width [string length $item]] > $maxWidth] ? \
														$width : \
														$maxWidth \
				]
		}
		
		set width [string length $title]
		set width [expr $width + ([expr 35 + $maxWidth] - $width) / 2]
		if {$width < 0} {set width 0}
		insertText [format "%${width}s\r\r" $title]
		
		# Mac filenames are a max of 32 characters. Add 3 for a little padding.
		setWinInfo -w $win tabsize 35
		for {set i 0} \
			{[expr $i < $num]} \
			{incr i} {
			insertText [format "%-35s%s\r" [file tail [lindex $files $i]] \
											[lindex $result $i]
						]
		}
		goto 0
		# if 'shrinkWindow' is loaded, call it to trim the output window.
		catch {shrinkWindow 2}
		setWinInfo -w $win dirty 0
		setWinInfo -w $win read-only 1
	}
}

proc voodoo::about {} {
	global HOME
	
	set y 10
	set yy 9
	
	set res [eval dialog -h 65 -w 330 \
		[dialog::text "AlphaVOODOO version [alpha::package versions voodooMenu]" 10 y 30] \
		[dialog::text "for VOODOO version [file::version -creator Vodo]" 10 y 30] \
		[dialog::button "OK" 250 yy] \
		[dialog::button "Help" 250 yy] \
	]
  
	if {[lindex $res 1]} {
		edit -c "$HOME:Help:VOODOO Help"
	} 
}

