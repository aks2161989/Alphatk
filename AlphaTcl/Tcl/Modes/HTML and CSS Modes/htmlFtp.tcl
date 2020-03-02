## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "htmlFtp.tcl"
 #                                    created: 00-06-22 14.01.57 
 #                                last update: 05/19/2005 {12:50:48 PM} 
 #  Author: Johan Linde
 #  E-mail: <alpha_www_tools@go.to>
 #     www: <http://go.to/alpha_www_tools>
 #  
 # Version: 3.2
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
# This file contains the procs for the FTP submenu.
#===============================================================================

#===============================================================================
# ×××× FTP ×××× #
#===============================================================================

array set html::NFpwList {
	" " %FA ! %FB \" %F8 # %F9 \$ %FE % %FF & %FC ' %FD ( %F2 ) %F3
	* %F0 + %F1 , %F6 - %F7 . %F4 / %F5 0 %EA 1 %EB 2 %E8 3 %E9
	4 %EE 5 %EF 6 %EC 7 %ED 8 %E2 9 %E3 : %E0 ; %E1 < %E6 = %E7
	> %E4 ? %E5 @ %9A A %9B B %98 C %99 D %9E E %9F F %9C G %9D
	H %92 I %93 J %90 K %91 L %96 M %97 N %94 O %95 P %8A Q %8B
	R %88 S %89 T %8E U %8F V %8C W %8D X %82 Y %83 Z %80 \[ %81
	\\ %86 \] %87 ^ %84 _ %85 ` %BA a %BB b %B8 c %B9 d %BE e %BF
	f %BC g %BD h %B2 i %B3 j %B0 k %B1 l %B6 m %B7 n %B4 o %B5
	p %AA q %AB r %A8 s %A9 t %AE u %AF v %AC w %AD x %A2 y %A3
	z %A0 \{ %A1 | %A6 \} %A7 ~ %A4 \177 %A5 € Z  \[ ‚ X ƒ Y „ ^
	… _ † \\ ‡ \] ˆ R ‰ S Š P ‹ Q Œ V  W Ž T
	 U  J ‘ K ’ H “ I ” N • O – L — M ˜ B
	™ C š %40 › A œ F  G ž D Ÿ E   z ¡ \{ ¢ x
	£ y ¤ ~ ¥ %7F ¦ | § \} ¨ r © s ª p « q ¬ v
	­ w ® t ¯ u ° j ± k ² h ³ i ´ n µ o ¶ l
	· m ¸ b ¹ c º ` » a ¼ f ? g ¾ d ¿ e À %1A
	Á %1B Â %18 Ã %19 Ä %1E Å %1F Æ %1C Ç %1D È %12 É %13 Ê %10
	Ë %11 Ì %16 Í %17 Î %14 Ï %15 Ð %0A Ñ %0B Ò %08 Ó %09 Ô %0E
	Õ %0F Ö %0C × %0D Ø %02 Ù %03 ? %01 Ü %06 Ý %07 Þ %04
	ß %05 à %3A á ; â 8 ã 9 ä > å %3F æ < ç = è 2
	é 3 ê 0 ë 1 ì 6 í 7 î 4 ï 5 ð * ñ + ò (
	ó ) ô . õ / ö , ÷ - ø \" ù # ú " " û ! ü &
	ý ' þ \$ ÿ %25
}

# Save current window and uploads it to the ftp server.
proc html::SavetoFTPServer {} {
	global html::Passwords html::CurrentUpload html::mkdir html::dirtomake html::originaldirtomake

	if {![llength [winNames]]} {return}
	set win [html::StrippedFrontWindowPath]
	if {[set this [html::ThisFilePath 4]] == ""} {return}
	set home [lindex $this 3]
	if {$home == "" && [lindex $this 0] != "file:///"} {set home [html::InWhichHomePage "[lindex $this 0][lindex $this 1]"]}
	if {$home == "" || [lindex $this 4] == "4"} {
		alertnote "Current window is not in a home page folder."
		return
	}
	
	if {[set serv [html::GetServerAndPassword $home]] == ""} {return}
	save
	set path [lindex $this 2]
	if {[lindex $serv 4] != ""} {set path [join [list [lindex $serv 4] $path] /]}
	set html::originaldirtomake [set html::dirtomake [string range $path 0 [string last / $path]]]
	set html::mkdir [list [lindex $serv 1] ${html::dirtomake} [lindex $serv 2] [set html::Passwords($home)]]
	set ftpcmd [list ftpStore $win [lindex $serv 1] $path [lindex $serv 2] [set html::Passwords($home)] html::HandleReply]
	if {[catch {eval [set html::CurrentUpload $ftpcmd]} err]} {
	    alertnote "Sorry, the upload failed: $err"
	}
}

proc html::GetServerAndPassword {home} {
	global html::Passwords HTMLmodeVars
	
	foreach f $HTMLmodeVars(FTPservers) {
		if {[lindex $f 0] == $home} {set serv $f}
	}
	if {![info exists serv]} {
		alertnote "No ftp server specified for this home page."
		return
	}
	
	if {[lindex $serv 3] != ""} {set html::Passwords($home) [lindex $serv 3]}
	if {![info exists html::Passwords($home)]} {
		if {![catch {dialog::password "Password for [lindex $serv 1]:"} pword]} {
			set html::Passwords($home) $pword
		} else {
			return
		}
	}
	return $serv
}

proc html::HandleReply {reply} {
	global html::Passwords html::mkdir html::ftpMultiple
	if {[catch {tclAE::getKeyData $reply errs} fetcherr]} {
		set fetcherr ""
	}
	if {[catch {tclAE::getKeyData $reply ----} anerr]} {
		set anerr ""
	}
	if {$fetcherr != ""} {
		# Fetch error
		if {[regexp {Error: (.*)} $fetcherr dum err2]} {set fetcherr $err2}
		if {$fetcherr == "that file or directory is unavailable or non-existent."} {
			status::msg "Creating new directory on server."
			eval html::ftpMkDir ${html::mkdir}
		} else {
			switchTo 'ALFA'
			alertnote "Ftp error: $fetcherr"
			unset html::Passwords
		}
	} elseif {$anerr != ""} {
		if {$anerr != "0"} {
			# Interarchy error.
			if {$anerr == "553" || $anerr == "550" || $anerr == "-553" || $anerr == "-550"} {
				status::msg "Creating new directory on server."
				eval html::ftpMkDir ${html::mkdir}
			} else {
				switchTo 'ALFA'
				alertnote "Ftp error: $anerr"
				unset html::Passwords
			}
		} else {
			status::msg "Document uploaded to ftp server."
		}
	} else {
		status::msg "Document uploaded to ftp server."
	}
	return 1
}

proc html::ftpMkDir {host path user password} {
	ftpMkDir $host $path $user $password html::MkDirHandler
}

proc html::MkDirHandler {reply} {
	global html::CurrentUpload html::mkdir html::dirtomake html::originaldirtomake
	if {[catch {tclAE::getKeyData $reply errs} fetcherr]} {
		set fetcherr ""
	}
	if {[catch {tclAE::getKeyData $reply ----} anerr]} {
		set anerr ""
	}
	if {$fetcherr != ""} {
		# Fetch error
		if {[regexp {Error: (.*)} $fetcherr dum err2]} {set fetcherr $err2}
		if {$fetcherr == "that file or directory is unavailable or non-existent."} {
			set html::dirtomake [string range ${html::dirtomake} 0 [string last / [string trimright ${html::dirtomake} /]]] 
			eval html::ftpMkDir [lreplace ${html::mkdir} 1 1 ${html::dirtomake}]
		} else {
			switchTo 'ALFA'
			alertnote "Ftp error: $fetcherr"
		}
	} elseif {$anerr != ""} {
		if {$anerr != "0"} {
			# Interarchy error
			if {$anerr == "553" || $anerr == "550" || $anerr == "521" || \
			  $anerr == "-553" || $anerr == "-550" || $anerr == "-521"} {
				set html::dirtomake [string range ${html::dirtomake} 0 [string last / [string trimright ${html::dirtomake} /]]] 
				eval html::ftpMkDir [lreplace ${html::mkdir} 1 1 ${html::dirtomake}]
			} else {
				switchTo 'ALFA'
				alertnote "Ftp error: $anerr"
			}
		} else {
			status::msg "Directory created on server."
			set html::dirtomake ${html::originaldirtomake}
			eval ${html::CurrentUpload}
		}
	} else {
		set html::dirtomake ${html::originaldirtomake}
		status::msg "Directory created on server."
		eval ${html::CurrentUpload}
	}
	return 1
}

proc html::ForgetPasswords {} {
	global html::Passwords
	status::msg "Passwords forgotten."
	unset html::Passwords
}

proc html::UploadHomePage {} {
	global html::fid html::baselen html::serv html::home
	global HTMLmodeVars html::Passwords html::limit
	if {![html::IsThereAHomePage] || [catch {html::WhichHomePage "upload files from"} hp]} {return}
	set html::home [lindex $hp 0]
	if {[set html::serv [html::GetServerAndPassword ${html::home}]] == ""} {return}

	ftpMirrorHierarchy ${html::home} [lindex ${html::serv} 1] \
	  [lindex ${html::serv} 2] [set html::Passwords(${html::home})] \
	  [lindex ${html::serv} 4]
}
