## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "htmlFileUtils.tcl"
 #                                    created: 99-07-20 18.05.44 
 #                                last update: 02/25/2006 {03:57:26 AM} 
 #  Author: Johan Linde
 #  E-mail: <alpha_www_tools@go.to>
 #     www: <http://go.to/alpha_www_tools>
 #  
 # Version: 3.2
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

proc htmlFileUtils.tcl {} {}

#===============================================================================
# This file contains various file routines for handling HTML links.
#===============================================================================

#===============================================================================
# ×××× File routines ×××× #
#===============================================================================

# Asks for a file and returns the file name including the relative path from
# current window. For images the width and height are also returned.
proc html::GetFile {{addtocache 1} {linkFile ""} {errormsg 0}} {
	upvar pathToNewFile newFile
	# get path to this window.	
	if {![string length [set this [html::ThisFilePath $errormsg]]]} {return}
	
	# Get the file to link to.
	if {$linkFile == "" && [catch {getfile "Select file to link to."} linkFile]} {
		return 
	}
	# For html::LinkToNewFile
	set newFile $linkFile
	# Get URL for this file?
	set link [html::BASEfromPath $linkFile]
	if {[lindex $link 4] == "4"} {
		alertnote "You can't link to a file in an include folder."
		return
	}
	if {[lindex $this 4] == "4" && "[lindex $this 0][lindex $this 1]" == "[lindex $link 0][lindex $link 1]"} {
		set linkTo ":HOMEPAGE:[lindex $link 2]"
	} elseif {[lindex $this 0] == [lindex $link 0]} {
		set linkTo [html::RelativePath "[lindex $this 1][lindex $this 2]" "[lindex $link 1][lindex $link 2]"]
	} else {
		set linkTo [join [lrange $link 0 2] ""]
	}
	set widthheight ""
	if {![file isdirectory $linkFile]} {
		# Check if image file.
		set widthheight [html::GetImageSize $linkFile]
	} else {
		append linkTo /
	}
	# Add URL to cache
	if {$addtocache} {html::AddToCache URLs $linkTo}
	return [list $linkTo $widthheight]
}


# Returns the URL to the current window.
proc html::ThisFilePath {errorMsg} {
	
	set thisFile [html::StrippedFrontWindowPath]
	
	# Look for BASE element.
	if {![catch {search -s -f 1 -r 1 -i 1 -m 0 {<BASE[ \t\r\n]+[^>]*>} [minPos]} res]} {
		set comm 0
		set commPos [minPos]
		while {![catch {search -s -f 1 -r 0 -m 0 -l [lindex $res 0] {<!--} $commPos} cres]} {
			set comm 1
			if {![catch {search -s -f 1 -r 0 -m 0 -l [lindex $res 0] -- {-->} [pos::math [lindex $cres 1] + 1]} cres]} {
				set comm 0
				set commPos [lindex $cres 1]
			} else {
				break
			}
		}
		if {!$comm && [regexp -nocase {HREF[ \t\n\r]*=[ \t\n\r]*("[^"]+"|'[^']+'|[^ \t\r\n>]+)} [getText [lindex $res 0] \
		  [lindex $res 1]] dum href]} {
			set href [string trim $href "\"' \t\r\n"]
			if {[catch {html::BASEpieces $href} basestr]} {
				alertnote "Window contains invalid BASE element. Ignored."
			} else {
				return $basestr
			}
		}
	}
	
	# Check if window is saved.
	if {![file exists $thisFile]} {
		switch $errorMsg {
			0 {
				set etxt "You must save the window. If you save, you will then be prompted\
				for a file to link to."
			}
			1 {
				set etxt "You must save the window, otherwise it cannot be determined\
				where the link is pointing."
			}
			2 {
				set etxt "You must save the window, otherwise the link cannot be determined."
			}
			3 {
				set etxt "You must save the window, otherwise it cannot be determined\
				where the links are pointing."
			}
			4 {
				set etxt "You must save the window, otherwise it cannot be determined\
				where to upload it."
			}
		}
		if {[alert -t caution -k Save -c Cancel -o "" $etxt] == "Cancel"} {return}
		
		if {![catch {saveAs}]} {
			set thisFile [html::StrippedFrontWindowPath]
		} else {
			return 
		}
	}
	return [html::BASEfromPath $thisFile]
}

# Returns URL to file.
proc html::BASEfromPath {path} {
	global HTMLmodeVars
	foreach p $HTMLmodeVars(homePages) {
		if {(![set i 0] && [string match [file join [lindex $p $i] *] [file join $path " "]]) || 
		([llength $p] == 5 && [set i 4] && [string match [file join [lindex $p $i] *] [file join $path " "]])} {
			set path [string range $path [expr {[string length [lindex $p $i]] + 1}] end]
			regsub -all [quote::Regfind [file separator]] $path {/} path
			return [list [lindex $p 1] [lindex $p 2] $path [lindex $p 0] $i [lindex $p 4]]
		}
	}
	regsub -all [quote::Regfind [file separator]] $path {/} path
	return [list "file:///" "" [string trimleft $path [file separator]] "" 0]
}

# Splits a BASE URL in pieces.
# NOTE! That this proc returns a shorter list than the proc above, is used in
# HTML::DblClick to determine if the doc contains a BASE tag.
proc html::BASEpieces {href} {
	if {[regexp -indices {://} $href css]} {
		if {[set sl [string first / [string range $href [expr {[lindex $css 1] + 1}] end]]] >=0} {
			set base [string range $href 0 [expr {[lindex $css 1] + $sl + 1}]]
			set path [string range $href [expr {[lindex $css 1] + $sl + 2}] end]
			set sl [string last / $path]
			set epath [string range $path [expr {$sl + 1}] end]
			set path [string range $path 0 $sl]
		} else {
			set base [string range $href 0 [lindex $css 1]]
			set path ""
			set epath [string range $href [expr {[lindex $css 1] + 1}] end]
		}
		return [list [quote::Unurl $base] [quote::Unurl $path] [quote::Unurl $epath] ""]
	} else {
		error "Invalid BASE."
	}
}

proc html::GetImageSize {fil} {
	set widthheight ""
	set type [file::getType $fil]
	if {$type == "GIFf" || [file extension $fil] == ".gif"} {
		set widthheight [html::GIFWidthHeight $fil]
	} elseif {$type =="JPEG" || $type == "JFIF" || [file extension $fil] == ".jpg"} {
		set widthheight [html::JPEGWidthHeight $fil]
	} elseif {$type == "PNGf" || [file extension $fil] == ".png"} {
		set widthheight [html::PNGWidthHeight $fil]
	}
	return $widthheight
}


# Determines width and height of a GIF file.
proc html::GIFWidthHeight {fil} {
	global tcl_platform
	if {[catch {open $fil r} fid]} {return}
	if {$tcl_platform(platform) != "macintosh"} {
		fconfigure $fid -encoding macRoman
	}
	fconfigure $fid -translation lf
	seek $fid 6 start
	set width [expr {[html::ReadOne $fid] + 256 * [html::ReadOne $fid]}]
	set height [expr {[html::ReadOne $fid] + 256 * [html::ReadOne $fid]}]
	close $fid
	return [list $width $height]
}

# Extracts width and height of a jpeg file.
# Algorithm from the perl script 'wwwimagesize' by
# Alex Knowles, alex@ed.ac.uk
# Andrew Tong, werdna@ugcs.caltech.edu
proc html::JPEGWidthHeight {fil} {
	global tcl_platform
	if {[catch {open $fil r} fid]} {return}
	if {$tcl_platform(platform) != "macintosh"} {
		fconfigure $fid -encoding macRoman
	}
	fconfigure $fid -translation lf
	if {[text::Ascii [read $fid 1]] != 255 || [text::Ascii [read $fid 1]] != 216} {return}
	set ch ""
	while {![eof $fid]} {
		while {[text::Ascii $ch] != 255 && ![eof $fid]} {set ch [read $fid 1]}
		while {[text::Ascii $ch] == 255 && ![eof $fid]} {set ch [read $fid 1]}
		if {[set asc [text::Ascii $ch]] >= 192 && $asc <= 195} {
			seek $fid 3 current
			set height [expr {256 * [html::ReadOne $fid] + [html::ReadOne $fid]}]
			set width [expr {256 * [html::ReadOne $fid] + [html::ReadOne $fid]}]
			close $fid
			return [list $width $height]
		} else {
			set ln [expr {256 * [html::ReadOne $fid] + [html::ReadOne $fid] - 2}]
			if {$ln < 0} {break}
			seek $fid $ln current
		}
	}
	close $fid
}

proc html::PNGWidthHeight {fil} {
	global tcl_platform
	if {[catch {open $fil r} fid]} {return}
	if {$tcl_platform(platform) != "macintosh"} {
		fconfigure $fid -encoding macRoman
	}
	fconfigure $fid -translation lf
	seek $fid 16 start
	set width [expr {16777216*[html::ReadOne $fid] + 65536*[html::ReadOne $fid] + 256*[html::ReadOne $fid] + [html::ReadOne $fid]}]
	set height [expr {16777216*[html::ReadOne $fid] + 65536*[html::ReadOne $fid] + 256*[html::ReadOne $fid] + [html::ReadOne $fid]}]
	return [list $width $height]
}

# Reads one character from an image file.
proc html::ReadOne {fid} {
	return [text::Ascii [read $fid 1]]
}


# Returns toFile including relative path from fromFile.
proc html::RelativePath {fromFile toFile} {
	# Remove trailing /file from fromFile
	set fromFile [string range $fromFile 0 [expr {[string last / $fromFile] - 1}]]

	set fromdir [split $fromFile /]
	set todir [split $toFile /]
	
	# Remove the common path.
	set i 0
	while {[llength $fromdir] > $i && [llength $todir] > $i \
	&& [lindex $fromdir $i] == [lindex $todir $i]} {
		incr i
	}

	# Insert ../
	foreach f [lrange $fromdir $i end] {
		append linkTo "../"
	}
	# Add the path.
	append linkTo [join [lrange $todir $i end] /]
	
	return $linkTo
}

# Determine the path to the file "linkTo", as linked from "base path epath". 
proc html::PathToFile {base path epath hpPath linkTo} {
	global  HTMLmodeVars tcl_platform
	# Expand links in include files.
	regsub -nocase {^:HOMEPAGE:} $linkTo "$base$path" linkTo
	# Is this a mailto or news URL or anchor?
	if {[regexp {^(mailto:|news:|javascript:)} [string tolower $linkTo]]} {error $linkTo}
	
	# remove /file from epath
	set sl [string last / $epath]
	set efil [string range $epath [expr {$sl + 1}] end]
	set epath [string range $epath 0 $sl]

	# anchor points to efil
	if {[string index $linkTo 0] == "#"} {set linkTo $efil}
	
	# Remove anchor from "linkTo".
	regexp {[^#]*} $linkTo linkTo
	
	# Remove ./ from path
	if {[string range $linkTo 0 1] == "./"} {set linkTo [string range $linkTo 2 end]}
	
	# Relative URL beginning with / is relative to server URL.
	if {[string index $linkTo 0] == "/"} {
		set linkTo "$base[string range $linkTo 1 end]"
	}
	
	# Relative URL?
	if {![regexp  {://} $linkTo]} {
		set fromPath [split [string trimright "${path}$epath" /] /]
		set toPath [split $linkTo /]
		# Back down for every ../
		set i 0
		foreach tp $toPath {
			if {$tp == ".."} {
				incr i
			} else {
				break
			}
		}
		if {$i > [llength $fromPath] } {
			error ""
		} else {
			set path1 [join [lrange $fromPath 0 [expr {[llength $fromPath] - $i - 1}]] /]
			if {[string length $path1]} {append path1 /}
			append path1 [join [lrange $toPath $i end] /]
			if {[string match "$path*" $path1] && [string length $hpPath]} {
				set pathTo [string range $path1 [string length $path] end]
				regsub -all {/} $pathTo [file separator] pathTo
				set casePath $pathTo
				set pathTo [html::filejoin $hpPath $pathTo]
				if {![file isdirectory $pathTo]} {return [list $pathTo $casePath]}
			} elseif {$base == "file:///"} {
				regsub -all {/} $path1 [file separator] pathTo
				if {$tcl_platform(platform) == "unix"} {set pathTo "[file separator]$pathTo"}
				return [list $pathTo $pathTo]
			}
			set linkTo "$base$path1"
		}
	}

	foreach hp [concat $HTMLmodeVars(homePages) [list [list [file separator] file:/// "" ""]]]  {
		if {[string match "[lindex $hp 1][lindex $hp 2]*" $linkTo] ||
		[string trimright "[lindex $hp 1][lindex $hp 2]" /] == $linkTo} {
			set pathTo [string range $linkTo [string length "[lindex $hp 1][lindex $hp 2]"] end]
			regsub -all {/} $pathTo [file separator] pathTo
			set casePath $pathTo
			if {$tcl_platform(platform) == "unix"} {
				set pathTo [file join [lindex $hp 0] $pathTo]
				if {[lindex $hp 1] == "file:///"} {set casePath $pathTo}
			} else {
				set pathTo [string trimleft [html::filejoin [lindex $hp 0] $pathTo] [file separator]]
			}
			# If link to folder, add default file.
			if {[file isdirectory $pathTo]} {
				set pathTo [string trimright $pathTo [file separator]]
				append pathTo "[file separator][lindex $hp 3]"
				set casePath [string trimright $casePath [file separator]]
				append casePath "[file separator][lindex $hp 3]"
			}
			if {$tcl_platform(platform) != "unix" || [lindex $hp 1] != "file:///"} {
				set casePath [string trimleft $casePath [file separator]]
			}
			return [list $pathTo $casePath]
		}
	}
	error $linkTo
}	

proc html::FollowLink {pos {follow 1}} {
	global mode
	global HTMLmodeVars
	
	# Build regular expressions with URL attrs.
	if {$mode == "HTML"} {
		set exp [html::URLregexp]
	}

	set expcss {(url)\([ \t\r\n]*("[^"]+"|'[^']+'|[^ "'\t\n\r\)]+)[ \t\r\n]*\)}
	# Check if user clicked on a link.
	if {($mode == "HTML" && ![catch {search -s -f 0 -r 1 -i 1 -m 0 $exp $pos} res] && [pos::compare [lindex $res 1] > $pos]) ||
	(![set curl [catch {search -s -f 0 -r 1 -i 1 -m 0 $expcss $pos} res]] && [pos::compare [lindex $res 1] > $pos])} {
		if {!$follow} {return}
		# Get path to this window.
		if {![string length [set thisURL [html::ThisFilePath 1]]]} {return}
		# Get path to link.
		if {[info exists curl]} {set exp $expcss}
		regexp -nocase $exp [eval getText $res] dum1 dum2 linkTo
		set linkTo [quote::Unurl [string trim $linkTo "\"' \t\r\n"]]
		# Anchors points to file itself if no BASE. (No BASE if [llength $thisURL] > 4)
		if {[string index $linkTo 0] == "#" && [llength $thisURL] > 4} {
			set a [string range $linkTo 1 end]
			if {![catch {search -s -f 1 -r 1 -i 1 -m 0 \
			  "<(A|MAP)\[ \t\r\n\]+\[^>\]*NAME\[ \t\r\n\]*=\[ \t\r\n\]*(\"\[ \t\r\n\]*$a\[ \t\r\n\]*\"|'\[ \t\r\n\]*$a\[ \t\r\n\]*'|$a)(>|\[ \t\r\n\]+\[^<>\]*>)" [minPos]} anc]} {
				goto [lindex $anc 0]
				insertToTop
			}
			return
		}
		if {[catch {lindex [html::PathToFile [lindex $thisURL 0] [lindex $thisURL 1] [lindex $thisURL 2] [lindex $thisURL 3] $linkTo] 0} linkToPath]} {
			if {$linkToPath == ""} {
				status::msg "Link not well-defined."
			} elseif {[regexp "://" $linkToPath]} {
				urlView $linkToPath
			} else {
				status::msg "Link points to $linkToPath. Doesn't map to a file on the disk."
			}
			return
		}
		# Does the file exist? 
		if {[file exists $linkToPath] && ![file isdirectory $linkToPath]} {
			# Is it a text file?
			if {[file::getType $linkToPath] == "TEXT"} {
				edit -c $linkToPath
				if {[regexp {[^#]*#(.+)$} $linkTo dum anchor] && ![catch {search -s -f 1 -r 1 -i 1 -m 0 \
				  "<(A|MAP)\[ \t\r\n\]+\[^>\]*NAME\[ \t\r\n\]*=\[ \t\r\n\]*(\"\[ \t\r\n\]*$anchor\[ \t\r\n\]*\"|'\[ \t\r\n\]*$anchor\[ \t\r\n\]*'|$anchor)(>|\[ \t\r\n\]+\[^<>\]*>)" [minPos]} anc]} {
					goto [lindex $anc 0]
					insertToTop
				}
			} elseif {[set HTMLmodeVars(openNonTextFile)] && [file::getType $linkToPath] != "APPL"} {
				launchDoc $linkToPath
			} else {
				status::msg "[file tail $linkToPath] is not a text file."
			}
		} else {
			set isAnHtmlFile 0
			set sufficies ""
			foreach mm {HTML CSS JScr} {
			    eval lappend sufficies [mode::filePatterns $mm]
			}
			foreach suffix $sufficies {
				if {[string match $suffix $linkToPath]} {set isAnHtmlFile 1}
			}
			if {(![file exists $linkToPath] && !$isAnHtmlFile) || [file isdirectory $linkToPath] ||
			![regexp "\[^[file separator]\]+" $linkToPath disk] || ![file exists $disk[file separator]]} {
				status::msg "Cannot open [file tail $linkToPath]."
			} else {
				set htmlFile [file tail $linkToPath]
				if {![set HTMLmodeVars(createWithoutAsking)]} {
					set dval [dialog -w 350 -h 160 -t "The file '$htmlFile' does not exist.\
					  Do you want to open a new empty window with this name?\
					  It will automatically be saved in the right place,\
					  and if necessary, new folders will be created."  10 10 340 100 \
					  -c "Create missing file without asking in the future." [set HTMLmodeVars(createWithoutAsking)] 10 105 340 120 \
					  -b Yes 270 130 335 150 -b No 185 130 250 150]
					if {[lindex $dval 2]} {return}
					if {[lindex $dval 0] != [set HTMLmodeVars(createWithoutAsking)]} {
						set HTMLmodeVars(createWithoutAsking) [lindex $dval 0]
						prefs::modifiedModeVar createWithoutAsking HTML
					}
				}
				# Create a new file and open it.
				foreach p [split [file dirname $linkToPath] [file separator]] {
					append path "$p[file separator]"
					# make new folders if needed.
					if {![file exists $path]} {
						file mkdir $path
					} elseif {![file isdirectory $path]} {
						alertnote "Cannot make a new folder '[file tail [file dirname $path]]'.\
						There is already a file with the same name."
						return
					}
				}
				append path "$htmlFile"
				# create an empty file.
				set fid [open $path w]
				# I suppose it's best to close it, too.
				close $fid
				edit -c $path
			}
		}
	} else {
		error "No link."
	}
}
