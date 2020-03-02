## -*-Tcl-*- (nowrap)
 # ===========================================================================
 # AlphaTcl - core Tcl engine
 #
 # FILE: "www.tcl"
 #                                           created: 04/09/1997 {11:37:57 am}
 #                                       last update: 03/16/2006 {06:24:20 PM}
 # Description:
 # 
 # Declares all "WWW (Internet)" services for viewing urls, fetching remote
 # files, etc.  and defines SystemCode core support procedures
 # 
 # Author: Vince Darley
 # E-mail: <vince@santafe.edu>
 #    www: <http://www.santafe.edu/~vince/>
 # 
 # Copyright (c) 1997-2006  Vince Darley
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ===========================================================================
 ##

alpha::library "wwwServices" "1.0" {
    # Initialization script: source this file so that all Internet Services
    # will be properly registered.
    www.tcl
} maintainer {
    "Vince Darley" <vince@santafe.edu> <http://www.santafe.edu/~vince/>
} description {
    Declares all "WWW (Internet)" services for viewing urls, fetching remote
    files, etc.
} help {
    This library supports the package: xserv by declaring a variety of
    different "WWW/Internet" services for viewing urls, fetching remote
    files, etc.  All of these helper applications can be set using the menu
    command "Config > Global Setup > Helper Applications":
    
    <<prefs::dialogs::helperApplications "Internet">>
    
    These services are automatically declared when ÇALPHAÈ is launched.
    
    See the file "www.tcl" for the package: xserv declarations.
}

proc www.tcl {} {}

# ===========================================================================
# 
# ×××× Ftp Services ×××× #
# 

# ===========================================================================
# 
# Ftp Fetch
# 

::xserv::addToCategory "Internet" ftpFetch

::xserv::declare ftpFetch "Ftp download" \
  localName host user password path {replyHandler ""}

::xserv::register ftpFetch "AlphaTcl ftp client" \
  -mode   "Alpha" \
  -driver {
    package require ftp
    set pp [array get params] ; dict with pp {
	file::ensureDirExists [file dirname $localName]
	set s [ftp::Open $host $user $password -output ftpDisplayMsg]
	if {$s == -1} {
	    error "Failed to open ftp connection to $host"
	}
	ftp::Type $s binary
	if {![ftp::Get $s $path $localName]} {
	    ftp::Close $s
	    error "Problem fetching file"
	}
	ftp::Close $s
	if {[string length $replyHandler]} {
	    eval $replyHandler
	}
    }
}

::xserv::register ftpFetch "Fetch" \
  -sig    "FTCh" \
  -driver {
    set pp [array get params] ; dict with pp {
	file::ensureDirExists [file dirname $localName]
	if {[file exists $localName]} {
	    file delete $localName
	}
	set localName "[file dirname $localName][file separator]"
	set flag -r
	if {$replyHandler != ""} {
	    currentReplyHandler $replyHandler
	    set flag -q
	}
	tclAE::send -p $flag -t 30000 'FTCh' core clon ---- \
	  [tclAE::build::nameObject cFHD [tclAE::build::TEXT \
	  "ftp://${user}:${password}@${host}/${path}"]] \
	  insh "insl{kobj: [tclAE::build::nameObject alis \
	  [tclAE::build::TEXT [file::unixPathToFinder ${localName}]]], kpos:bgng}"
    }
}

::xserv::register ftpFetch "Interarchy" \
  -sig    "Arch" \
  -driver {
    file::ensureDirExists [file dirname $params(localName)]
    if {[file exists $params(localName)]} {
	file delete $params(localName)
    }
    set localName "[file dirname $params(localName)][file separator]"
    set flag -r
    if {$params(replyHandler) != ""} {
	currentReplyHandler $params(replyHandler)
	set flag -q
    }
    tclAE::send -p $flag -t 30000 'Arch' Arch Ftch \
      FTPh "Ò$params(host)Ó" FTPc "Ò$params(path)Ó" \
      ArGU "Ò$params(user)Ó" ArGp "Ò$params(password)Ó" \
      ---- [tclAE::build::alis $localName]
}

::xserv::register ftpFetch "NetFinder" \
  -sig    "Woof" \
  -driver {
    set pp [array get params] ; dict with pp {
	file::ensureDirExists [file dirname $localName]
	if {[file exists $localName]} {
	    file delete $localName
	}
	if {$replyHandler == "" || ![checkNetFinderVersion]} {
	    set flag -r
	    if {$replyHandler != ""} {
		currentReplyHandler $replyHandler
		set flag -q
	    }
	    close [open $localName "w"]
	    tclAE::send -p $flag -t 30000 'Woof' GURL GURL ---- \
	      "Òftp://${user}:${password}@${host}/${path}Ó" \
	      dest [tclAE::build::alis $localName]
	    return
	}
	global ALPHA
	set Woof [temp::unique ftptmp Woof]
	set fid [open $Woof "w"]
	puts $fid "auto result;"
	puts $fid "auto script;"
	puts $fid "auto script1;"
	puts $fid "auto ftpRef = NFCreateFTPInstance();"
	puts $fid "NFLoadModuleConstants();"
	puts $fid "do \{"
	puts $fid "if (result = NFConnect(ftpRef, \"$host\", 21, \"$user\", \"$password\"), result != 0) break;"
	puts $fid "if (result = NFReceiveFile(ftpRef, \"$path\", eASCIIType, \"$localName\", eText, NULL, NULL), result != 0) break;"
	puts $fid "\} while(0);"
	puts $fid "NFDisconnect(ftpRef);"
	puts $fid "NFDeleteFTPInstance(ftpRef);"
	puts $fid "script = \"tell app \\\"$ALPHA\\\"\\r ignoring application responses \\r DoScript \\\"$replyHandler aevt\\\\\\\\\\\\\\\\ansr\\\\\\\\\\\\\\\\{'----':\" + string(result) + \"\\\\\\\\\\\\\\\\}\";"
	puts $fid "script1 = \"; file delete \{$Woof\}\\\"\\r end ignoring\\r end tell\";"
	puts $fid "MICI.ExecuteScript(script + script1);"
	close $fid
	setFileInfo $Woof type ICI!
	sendOpenEvent noReply 'Woof' $Woof  
    }
}

# ===========================================================================
# 
# Ftp List
# 

::xserv::addToCategory "Internet" ftpList

::xserv::declare ftpList "Ftp list directory" \
  localName host user password path {replyHandler ""}

::xserv::register ftpList "AlphaTcl ftp client" \
  -mode   "Alpha" \
  -driver {
    set pp [array get params] ; dict with pp {
	package require ftp
	if {[catch {ftp::Open $host $user $password -output ftpDisplayMsg} s]} {
	    if {$password eq "anonymous" \
	      && [string first "response 'anonymous' is not valid" $s] != -1} {
		set password "user@host.com"
		status::msg "$s -- attempting to connect again"
		set s [ftp::Open $host $user $password -output ftpDisplayMsg]
	    } else {
		return -code error $s
	    }
	}
	if {$s == -1} {
	    error "Failed to open ftp connection to $host"
	}
	ftp::Type $s binary
	if {[string length $path]} {
	    if {![regexp {/$} $path]} {append path "/"}
	}
	set res [ftp::List $s $path]
	ftp::Close $s
	set fd [alphaOpen $localName "w"]
	puts $fd [join [concat "dummy" $res "dummy"] "\n"]
	close $fd
	if {[string length $replyHandler]} {
	    eval $replyHandler
	}
	return
    }
}

::xserv::register ftpList "Fetch" \
  -sig    "FTCh" \
  -driver {
    set pp [array get params] ; dict with pp {
	tclAE::send -p -r -t 3000 'FTCh' aevt odoc ----\
	  [tclAE::build::nameObject cFHD\
	  [tclAE::build::TEXT "ftp://${user}:${password}@${host}/${path}"]]
	tclAE::send -p -r -t 3000 'FTCh' FTCh VwFL ----\
	  [tclAE::build::nameObject cFWA [tclAE::build::TEXT $host]]
	set res [tclAE::build::resultData 'FTCh' core getd ----\
	  [tclAE::build::propertyObject pTxt\
	  [tclAE::build::indexObject cFWC long(1)]]]
	tclAE::send -p 'FTCh' core clos ----\
	  [tclAE::build::indexObject cFWC long(1)] savo "no"
	set fd [open $localName w]
	puts -nonewline $fd $res
	close $fd
	if {[string length $replyHandler]} {
	    eval $replyHandler
	}
    }
}

::xserv::register ftpList "Interarchy" \
  -sig    "Arch" \
  -driver {
    set pp [array get params] ; dict with pp {
	close [open $localName "w"]
	set flag -r
	if {$replyHandler != ""} {
	    currentReplyHandler $replyHandler
	    set flag -q
	}
	tclAE::send -p $flag -t 30000 'Arch' Arch List FTPh "Ò${host}Ó" \
	  FTPc "Ò${path}Ó" ArGU "Ò${user}Ó" ArGp "Ò${password}Ó" {----} \
	  [tclAE::build::alis $localName]
	set newname [file rootname $localName]#1[file extension $localName]
	if {[file size $localName] == 0 && [file exists $newname]} {
	    file delete $localName
	    file rename $newname $localName
	}
    }
}

::xserv::register ftpList "NetFinder" \
  -sig    "Woof" \
  -driver {
    set pp [array get params] ; dict with pp {
	if {$replyHandler == ""} {
	    alertnote "This doesn't work with NetFinder."
	    error "no reply handler"
	}
	global ALPHA
	if {![checkNetFinderVersion]} {
	    error "NetFinder 2.1.2 or later required."
	}
	close [open $localName "w"]
	set Woof [temp::unique ftptmp Woof]
	set fid [open $Woof "w"]
	puts $fid "auto file;"
	puts $fid "auto result;"
	puts $fid "auto item;"
	puts $fid "auto script;"
	puts $fid "auto script1;"
	puts $fid {auto listing = [array];}
	puts $fid "auto ftpRef = NFCreateFTPInstance();"
	puts $fid "file = fopen(\"$localName\", \"w\");"
	puts $fid "NFLoadModuleConstants();"
	puts $fid "do \{"
	puts $fid "if (result = NFConnect(ftpRef, \"$host\", 21, \"$user\", \"$password\"), result != 0) break;"
	puts $fid "if (result = NFListDirectory(ftpRef, \"$path\", 1, &listing), result != 0) break;"
	puts $fid "forall(item in listing) \{"
	puts $fid "if ((item.kind & eDirectoryItem) == eDirectoryItem) fprintf(file, \"d \");"
	puts $fid "else if ((item.kind & eLinkItem) == eLinkItem) fprintf(file, \"l \");"
	puts $fid "else fprintf(file, \"  \");"
	puts $fid "fprintf(file, \"Ab 0 0 %s\", item.name);"
	puts $fid "if ((item.kind & eLinkItem) == eLinkItem) fprintf(file, \" -> %s\", item.link);"
	puts $fid "fprintf(file, \"\\n\");"
	puts $fid "\}"
	puts $fid "\} while(0);"
	puts $fid "NFDisconnect(ftpRef);"
	puts $fid "NFDeleteFTPInstance(ftpRef);"
	puts $fid "close(file);"
	puts $fid "script = \"tell app \\\"$ALPHA\\\"\\r ignoring application responses \\r DoScript \\\"$replyHandler aevt\\\\\\\\\\\\\\\\ansr\\\\\\\\\\\\\\\\{'----':\" + string(result) + \"\\\\\\\\\\\\\\\\}\";"  
	puts $fid "script1 = \"; file delete \{$Woof\}\\\"\\r end ignoring\\r end tell\";"
	puts $fid "MICI.ExecuteScript(script + script1);"
	close $fid
	setFileInfo $Woof type ICI!
	sendOpenEvent noReply 'Woof' $Woof  
    }
}

# ===========================================================================
# 
# Ftp Mirror
# 

::xserv::addToCategory "Internet" ftpMirror

::xserv::declare ftpMirror "Mirror a local directory to a remote ftp site" \
  localDir host user password path

::xserv::register ftpMirror "Interarchy" \
  -sig    "Arch" \
  -driver {
    set pp [array get params] ; dict with pp {
	interarchyMirror $localDir $host $user $password $path
    }
}

::xserv::register ftpMirror "Iterate using 'Ftp Upload' service" \
  -mode   "Alpha" \
  -driver {
    set pp [array get params] ; dict with pp {
	iteratingMirrorToFtp $localDir $host $user $password $path
    }
}

::xserv::register ftpMirror "NetFinder" \
  -sig    "Woof" \
  -driver {
    set pp [array get params] ; dict with pp {
	ftpNetFinderMirror [list $localDir $host $user $password $path]
    }
}

# ===========================================================================
# 
# Ftp MkDir
# 

::xserv::addToCategory "Internet" ftpMkdir

::xserv::declare ftpMkdir "Ftp make directory" \
  host user password path {replyHandler ftpMkDirHandler}

::xserv::register ftpMkdir "AlphaTcl ftp client" \
  -mode   "Alpha" \
  -driver {
    set pp [array get params] ; dict with pp {
	package require ftp
	set ::ftp::VERBOSE 1
	set s [ftp::Open $host $user $password -output ftpDisplayMsg]
	if {$s == -1} {
	    error "Failed to open ftp connection to $host"
	}
	if {[string length $path]} {
	    if {![regexp {/$} $path]} {append path "/"}
	}
	# This will fail
	if {[catch [list ftp::Type $s $path] type]} {
	    ftp::Mkdir $s $path
	}
	ftp::Close $s
	
	if {[string length $replyHandler]} {
	    eval $replyHandler
	}
    }
}

::xserv::register ftpMkdir "Fetch" \
  -sig    "FTCh" \
  -driver {
    set pp [array get params] ; dict with pp {
	currentReplyHandler $replyHandler
	tclAE::send -p -q -t 30000 'FTCh' Arch MkDr \
	  FTPh "Ò${host}Ó" FTPc "Ò${path}Ó" \
	  ArGU "Ò${user}Ó" ArGp "Ò${password}Ó"
    }
}

::xserv::register ftpMkdir "Interarchy" \
  -sig    "Arch" \
  -driver {
    set pp [array get params] ; dict with pp {
	currentReplyHandler $replyHandler
	tclAE::send -p -q -t 30000 'Arch' Arch MkDr \
	  FTPh "Ò${host}Ó" FTPc "Ò${path}Ó" \
	  ArGU "Ò${user}Ó" ArGp "Ò${password}Ó"
    }
}

::xserv::register ftpMkdir "NetFinder" \
  -sig    "Woof" \
  -driver {
    set pp [array get params] ; dict with pp {
	global ALPHA

	set Woof [temp::unique ftptmp Woof]
	set fid [open $Woof "w"]
	set dirpath [string range $path 0 [expr {[string last / [string trimright $path /]] - 1}]]
	puts $fid "auto result;"
	puts $fid "auto script;"
	puts $fid "auto ftpRef = NFCreateFTPInstance();"
	puts $fid "NFLoadModuleConstants();"
	puts $fid "do \{"
	puts $fid "if (result = NFConnect(ftpRef, \"$host\", 21, \"$user\", \"$password\"), result != 0) break;"
	puts $fid "if (result = NFChangeWorkingDirectory(ftpRef, \"$dirpath\"), result != 0) break;"
	puts $fid "if (result = NFMakeDirectory(ftpRef, \"$path\"), result != 0) break;"
	puts $fid "\} while(0);"
	puts $fid "NFDisconnect(ftpRef);"
	puts $fid "NFDeleteFTPInstance(ftpRef);"
	# Does this work if replyHandler is "" ?
	puts $fid "script = \"tell app \\\"$ALPHA\\\"\\r ignoring application responses \\r DoScript \\\"$replyHandler aevt\\\\\\\\\\\\\\\\ansr\\\\\\\\\\\\\\\\{'----':\" + string(result) + \"\\\\\\\\\\\\\\\\}\\\"\\r end ignoring\\r end tell\";"
	puts $fid "MICI.ExecuteScript(script);"
	close $fid
	setFileInfo $Woof type ICI!
	sendOpenEvent noReply 'Woof' $Woof
    }
}

# ===========================================================================
# 
# Ftp Store
# 

::xserv::addToCategory "Internet" ftpStore

::xserv::declare ftpStore "Ftp upload" \
  localName host user password path {replyHandler ftpHandleReply}

::xserv::register ftpStore "AlphaTcl ftp client" \
  -mode   "Alpha" \
  -driver {
    set pp [array get params] ; dict with pp {
	package require ftp
	status::msg "Opening connection to '${host}'"
	set s [ftp::Open $host $user $password -output ftpDisplayMsg]
	if {$s == -1} {
	    error "Failed to open ftp connection to '${host}'"
	}
	status::msg "Uploading file '[file tail $localName]' to '${host}' É"
	ftp::Type $s binary
	# Note that 'Put' will overwrite existing files.
	if {[catch {ftpLibPut $s $localName $path} err]} {
	    if {$err == "Error opening connection!"} {
		error $err
	    }
	    status::msg $err
	    # Most likely cause is sub-paths not existing.
	    set pieces [file split [file dirname $path]]
	    set sub {}
	    foreach piece $pieces {
		set sub [file join $sub $piece]
		ftp::MkDir $s $sub
	    }
	    ftpLibPut $s $localName $path
	}
	ftp::Close $s
	status::msg "Uploading file '[file tail $localName]' to '${host}' É complete"
	if {$replyHandler ne ""} {
	    eval $replyHandler [list {}]
	}
    }
}

::xserv::register ftpStore "Fetch" \
  -sig    "FTCh" \
  -driver {
    set pp [array get params] ; dict with pp {
	currentReplyHandler $replyHandler
	set dirpath [string range $path 0 [string last / $path]]
	tclAE::send -p -q -t 30000 'FTCh' FTCh PutI ---- \
	  "obj{form:name, want:type(cFHD),\
	  seld:Òftp://${user}:${password}@${host}/${dirpath}Ó,\
	  from:'null'()}" Itms [tclAE::build::alis $localName]
    }
}

::xserv::register ftpStore "Interarchy" \
  -sig    "Arch" \
  -driver {
    set pp [array get params] ; dict with pp {
	currentReplyHandler $replyHandler
	tclAE::send -p -q -t 30000 'Arch' Arch Stor \
	  ---- [tclAE::build::alis $localName] FTPh "Ò${host}Ó" \
	  FTPc "Ò${path}Ó" ArGU "Ò${user}Ó" ArGp "Ò${password}Ó"
    }
}

::xserv::register ftpStore "NetFinder" \
  -sig    "Woof" \
  -driver {
    set pp [array get params] ; dict with pp {
	set dirpath [string range $path 0 [expr {[string last / $path] - 1}]]
	if {![checkNetFinderVersion]} {
	    currentReplyHandler $replyHandler
	    tclAE::send -p -q -t 30000 'Woof' PURL PURL ---- \
	      [tclAE::build::alis $localName] dest \
	      "Òftp://${user}:${password}@${host}/${dirpath}Ó"
	    return
	}
	global ALPHA
	set Woof [temp::unique ftptmp Woof]
	set fid [open $Woof "w"]
	puts $fid "auto result;"
	puts $fid "auto script;"
	puts $fid "auto script1;"
	puts $fid "auto ftpRef = NFCreateFTPInstance();"
	puts $fid "NFLoadModuleConstants();"
	puts $fid "do \{"
	puts $fid "if (result = NFConnect(ftpRef, \"$host\", 21, \"$user\", \"$password\"), result != 0) break;"
	puts $fid "if (result = NFChangeWorkingDirectory(ftpRef, \"$dirpath\"), result != 0) break;"
	puts $fid "if (result = NFSendFile(ftpRef, \"$path\", eASCIIType, \"$localName\", eText, NULL, NULL), result != 0) break;"
	puts $fid "\} while(0);"
	puts $fid "NFDisconnect(ftpRef);"
	puts $fid "NFDeleteFTPInstance(ftpRef);"
	puts $fid "script = \"tell app \\\"$ALPHA\\\"\\r ignoring application responses \\r DoScript \\\"$replyHandler aevt\\\\\\\\\\\\\\\\ansr\\\\\\\\\\\\\\\\{'----':\" + string(result) + \"\\\\\\\\\\\\\\\\}\";"
	puts $fid "script1 = \"; file delete \{$Woof\}\\\"\\r end ignoring\\r end tell\";"
	puts $fid "MICI.ExecuteScript(script + script1);"
	close $fid
	setFileInfo $Woof type ICI!
	sendOpenEvent noReply 'Woof' $Woof  
    }
}

::xserv::register ftpStore "Putty secure ftp client (psftp)" \
  -requirements {
    if {$::tcl_platform(platform) ne "windows"} {
	error "Requires Windows"
    }
} \
  -progs  {psftp} \
  -driver {
    set pp [array get params] ; dict with pp {
	set batchfile [temp::path psftp batch.txt]
	set fout [open $batchfile w]
	puts $fout [list lcd [file dirname $localName]]
	#puts $fout [list mkdir [file dirname $path]]
	puts $fout [list cd [file dirname $path]]
	puts $fout [list put [file tail $localName] [file tail $path]]
	puts $fout "quit"
	close $fout
	status::msg "Uploading file '[file tail $localName]' to '${host}' É"
	catch {exec ${xserv-psftp} ${user}@${host} -batch -pw $password \
	  -b $batchfile} res
	if {[regexp -line -- \
	  "^local:[quote::Regfind [file tail $localName]] =>" $res]} {
	    # transferred ok
	    status::msg "Uploading file '[file tail $localName]' to '${host}' É complete"
	} else {
	    error "Transfer failed: $res"
	}
	if {$replyHandler ne ""} {
	    eval $replyHandler [list {}]
	}
    }
}

# ===========================================================================
# 
# Remote Mirror
# 

::xserv::addToCategory "Internet" remoteMirror

::xserv::declare remoteMirror "Mirror a local directory to a url" \
  localDir url

::xserv::register remoteMirror "Iterate using 'Upload' service" \
  -mode   "Alpha" \
  -driver {
    iteratingMirrorToUrl $localDir $url
}

::xserv::register remoteMirror "Use ftp mirror service (only valid for ftp urls)" \
  -mode   "Alpha" \
  -driver {
    set uinfo [url::parse $params(url)]
    set type [lindex $uinfo 0]
    set rest [lindex $uinfo 1]
    if {$type ne "ftp"} {
	error "Unsupported url type $type"
    }
    url::parseFtp $rest i

    ::xserv::invoke ftpMirror -xservInteraction $params(xservInteraction)\
      -localDir $localDir -host $i(host) -path $i(path)\
      -user $i(user) -password $i(password)
}

# ===========================================================================
# 
# Upload
# 

::xserv::addToCategory "Internet" Upload

::xserv::declare Upload "Interface to upload a local file to a remote location" \
  localName url {replyHandler ftpHandleReply}

::xserv::register Upload "AlphaTcl ftp client" \
  -driver {
    set uinfo [url::parse $params(url)]
    set type [lindex $uinfo 0]
    set rest [lindex $uinfo 1]
    if {$type ne "ftp"} {
	error "Unsupported url type $type"
    }
    url::parseFtp $rest i
    set i(file) [file tail $params(localName)]
    ftpStore "$file" $i(host) "$i(path)$i(file)" $i(user) $i(pass)
}

::xserv::register Upload "Fetch" \
  -sig    "FTCh" \
  -driver {
    set uinfo [url::parse $params(url)]
    set type [lindex $uinfo 0]
    set rest [lindex $uinfo 1]
    if {$type ne "ftp"} {
	error "Unsupported url type $type"
    }
    url::parseFtp $rest i
    currentReplyHandler $params(replyHandler)
    set dirpath [string range $i(path) 0 [string last / $i(path)]]
    tclAE::send -p -q -t 30000 'FTCh' FTCh PutI ---- \
      "obj{form:name, want:type(cFHD), \
      seld:Òftp://$i(user):$i(password)@$i(host)/$i(dirpath)Ó, \
      from:'null'()}" \
      Itms [tclAE::build::alis $params(localName)]
}

::xserv::register Upload "Interarchy" \
  -sig    "Arch" \
  -driver {
    set uinfo [url::parse $params(url)]
    set type [lindex $uinfo 0]
    set rest [lindex $uinfo 1]
    if {$type ne "ftp"} {
	error "Unsupported url type $type"
    }
    url::parseFtp $rest i
    set i(file) [file tail $params(localName)]
    currentReplyHandler $params(replyHandler)
    tclAE::send -p -q -t 30000 'Arch' Arch Stor ---- \
      [tclAE::build::alis $params(localName)] FTPh "Ò$i(host)Ó" \
      FTPc "Ò$i(path)Ó" ArGU "Ò$i(user)Ó" ArGp "Ò$i(password)Ó"
}

::xserv::register Upload "Putty secure ftp client (psftp)" \
  -requirements {
    if {$::tcl_platform(platform) ne "windows"} {
	error "Requires Windows"
    }
} \
  -progs  {psftp} \
  -driver {
    set uinfo [url::parse $params(url)]
    if {[lindex $uinfo 0] ne "ftp"} {
	error "Unsupported url type [lindex $uinfo 0]"
    }
    url::parseFtp [lindex $uinfo 1] finfo
    set finfo(file) [file tail $params(localName)]
    set batchfile [temp::path psftp batch.txt]
    set fout [open $batchfile w]
    puts $fout [list lcd [file dirname $params(localName)]]
    #puts $fout [list mkdir [file dirname $path]]
    puts $fout [list cd [file dirname $finfo(path)]]
    puts $fout [list put [file tail $params(localName)] $finfo(file)]
    puts $fout "quit"
    close $fout
    status::msg "Uploading file '[file tail $params(localName)]' to '$finfo(host)' É"
    catch {exec $params(xserv-psftp) \
      $finfo(user)@$finfo(host) -batch -pw $finfo(password) \
      -b $batchfile} res
    if {[regexp -line -- \
      "^local:[quote::Regfind [file tail $params(localName)]] =>" $res]} {
	# transferred ok
	status::msg "Uploading file '[file tail $params(localName)]'\
	  to '$finfo(host)' É complete"
    } else {
	error "Transfer failed: $res"
    }
}

# ===========================================================================
# 
# ×××× HTML Services ×××× #
# 

# ===========================================================================
# 
# View HTML
# 

::xserv::addToCategory "Internet" viewHTML

::xserv::declare viewHTML "Display rendered HTML" \
  file

::xserv::register viewHTML "Open in OS default viewer" \
  -mode   "Alpha" \
  -driver {
    file::openInDefault $params(file)
}

::xserv::register viewHTML "'View a URL' service" \
  -mode   "Alpha" \
  -driver {
    ::xserv::invoke viewUrl -xservInteraction $params(xservInteraction) \
      -url [file::toUrl $params(file)]
}

::xserv::register viewHTML "Internal tkhtml widget" \
  -mode   "Alpha" \
  -requirements {
    if {($alpha::platform ne "tk")} {
	error "Requires Alphatk"
    }
} \
  -driver {
    viewInTkhtml $params(file)
}

::xserv::register viewHTML "MacOS Help Viewer" \
  -sig    "hbwr" \
  -driver {
    app::launchBack hbwr
    sendOpenEvent noReply 'hbwr' $params(file)
    switchTo 'hbwr'
}

::xserv::register viewHTML "Text-only parser" \
  -mode   "Alpha" \
  -driver {
    WWW::renderFile $params(file)
}

# ===========================================================================
# 
# ×××× URL Services ×××× #
# 

# ===========================================================================
# 
# View URL
# 

::xserv::addToCategory "Internet" viewURL

::xserv::declare viewURL "View a URL" \
  url

::xserv::register viewURL "AlphaTcl internal text only viewer" \
  -mode   "Alpha" \
  -driver {
    WWW::renderUrl $params(url)
}

::xserv::register viewURL "Camino" \
  -sig    "MOZC" \
  -driver {
    tclAE::send $params(xservTarget) GURL GURL ---- \
      [tclAE::build::TEXT $params(url)]
}

if {($alpha::macos == 0)} {
    ::xserv::register viewURL "Firefox" \
      -mode   "Exec" \
      -progs  "firefox-driver" \
      -driver {
	return [list $params(xserv-firefox) $params(url)]
    }
} else {
    ::xserv::register viewURL "Firefox" \
      -sig    "MOZB" \
      -driver {
	tclAE::send $params(xservTarget) WWW! OURL ---- \
	  [tclAE::build::TEXT $params(url)]
    }

}

if {($alpha::macos == 0)} {
    ::xserv::register viewURL "Internet Explorer" \
      -dde    "IExplore" \
      -mode   "Dde" \
      -driver {
	dde execute -async IExplore WWW_OpenURL $params(url)
    }
} else {
    ::xserv::register viewURL "Internet Explorer" \
      -sig    "MSIE" \
      -driver {
	tclAE::send $params(xservTarget) WWW! OURL ---- \
	  [tclAE::build::TEXT $params(url)]
    }
}

::xserv::register viewURL "Mozilla" \
  -sig    "MOZZ" \
  -driver {
    tclAE::send $params(xservTarget) GURL GURL ---- \
      [tclAE::build::TEXT $params(url)]
}

::xserv::register viewURL "Safari" \
  -sig    "sfri" \
  -driver {
    tclAE::send $params(xservTarget) GURL GURL ---- \
      [tclAE::build::TEXT $params(url)]
}

::xserv::register viewURL "Use OS default viewer" \
  -mode   "Alpha" \
  -driver {
    status::msg "'$params(url)' sent to browser."
    url::execute $params(url)
}

# ===========================================================================
# 
# Get URL
# 

::xserv::addToCategory "Internet" getURL

::xserv::declare getURL "Download a URL" \
  url to

::xserv::register getURL "AlphaTcl internal url downloading" \
  -mode   "Alpha" \
  -driver {
    httpCopy $params(url) $params(to)
}

::xserv::register getURL "OURL handler" \
  -sig {} \
  -driver {
    if {[file isfile $params(to)]} {
	if {[dialog::yesno "Replace [file tail $params(to)]?"]} {
	    file delete $params(to)
	} else {
	    error "Cancelled -- download aborted."
	}
    }
    close [alphaOpen $params(to) w]
    tclAE::send -p -r -t 30000 $params(xservTarget) WWW! OURL ---- \
      "Ò$params(url)Ó" INTO [tclAE::build::alis "$params(to)"]
}

# ===========================================================================
# 
# ×××× Misc. Services ×××× #
# 

# ===========================================================================
# 
# View Java Applet
# 

::xserv::addToCategory "Internet" viewJavaApplet

::xserv::declare viewJavaApplet "View a Java applet" \
  file

::xserv::register viewJavaApplet "Applet Viewer 1" \
  -sig    "WARZ" \
  -driver {
    sendOpenEvent noReply $params(xservTarget) $params(file)
}

::xserv::register viewJavaApplet "Applet Viewer 2" \
  -sig    "AppV" \
  -driver {
    sendOpenEvent noReply $params(xservTarget) $params(file)
}

::xserv::register viewJavaApplet "Internet Explorer" \
  -mode   "Dde" \
  -dde    "IExplore" \
  -driver {
    dde execute -async IExplore WWW_OpenURL [file::toUrl $params(file)]
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Handling html, url, mailto actions ×××× #
# 

proc htmlView {filename} {
    ::xserv::invoke viewHTML -file $filename
}

proc urlView {url} {
    ::xserv::invoke viewURL -url $url
}

proc composeEmail {to} {
    global composeEmailUsing eMailer
    # Note that it is up to the calling proc to ensure that 'to' is in the
    # proper format, i.e. by first using 'url::mailto'
    eval $eMailer($composeEmailUsing) [list $to]
}

proc emailDefaultComposer {url} {
    if {[string length $url] > 200} {
	# Some emailer programs can't handle long urls, so we'll put
	# the body of the message in the clipboard.
	array set mailArgs [url::unmailto $url]
	foreach field [list to cc bcc subject body] {
	    ensureset mailArgs($field) ""
	    if {$field == "to"} {
		lappend args $mailArgs(to)
	    } elseif {$field == "body"} {
		putScrap $mailArgs(body)
		set    msg "The body of the message was too long, "
		append msg "and was put in the clipboard. "
		append msg "(Just paste it in over this text.)"
		lappend args body $msg
	    } elseif {[string length $mailArgs($field)]} {
		lappend args $field $mailArgs($field)
	    }
	}
	set url [eval url::mailto $args]
    } 
    # A little insurance to ensure that 'url' starts with 'mailto:'
    regsub {^mailto:} $url {} url
    set url mailto:$url
    status::msg "'$url' sent to browser."
    url::execute $url
}


# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Basic url handling ×××× #
# 

namespace eval url {}

## 
 # --------------------------------------------------------------------------
 # 
 # "url::mailto" --
 # 
 # Generate a mailto url from the given argument pairs.  You can then pass
 # the result to 'url::execute' to take action.  Note that very long mailto
 # urls seem not to be handled properly, so you may wish to check the length
 # of the 'body' field, if given and take a different action (e.g. put the
 # body on the clip board for the user to handle manually).
 # 
 # A typical use is:
 # 
 #   url::execute [url::mailto vince@santafe.edu subject hello body goodbye]
 #  
 # --------------------------------------------------------------------------
 ##

proc url::mailto {address args} {
    set url "mailto:$address"
    set divider "?"
    foreach {arg value} $args {
	append url $divider $arg = [quote::Url $value]
	set divider "&"
    }
    return $url
}

## 
 # --------------------------------------------------------------------------
 # 
 # "url::unmailto" --
 # 
 # Obtain the fields for an email url, returning a list of argument pairs of
 # the mailto fields starting with the address and including additional
 # arguments.  This might be necessary if the url is too long for a third
 # party email application.
 # 
 # --------------------------------------------------------------------------
 ##

proc url::unmailto {url} {
    # First get the email address, leave the rest as 'args'.
    regsub {^mailto:} $url {} url
    if {![regexp {^(.+)\?(.+$)} $url allofit to args]} {
	set to $url
	set args [list]
    }
    set mailArgs [list to $to]
    # Now add the fields to the array.
    foreach arg [join [split $args &]] {
	set fieldText ""
	foreach field [list cc bcc subject body] {
	    set pat "^$field="
	    if {[regsub -nocase $pat $arg {} fieldText]} {
		lappend mailArgs $field [quote::Unurl $fieldText]
		break
	    }
	}
    }
    return $mailArgs
}

## 
 # --------------------------------------------------------------------------
 # 
 # "url::execute" --
 # 
 # This should carry out the default action of opening/clicking-on a url
 # 
 # --------------------------------------------------------------------------
 ##

proc url::execute {url} {
    ::alpha::executeURL $url
}

## 
 # --------------------------------------------------------------------------
 # 
 # "url::download" --
 # 
 # For urls which ought to be downloaded (e.g. files), this procedure will
 # try to carry that out in preference to opening.
 # 
 # --------------------------------------------------------------------------
 ##

proc url::download {url} {
    global downloadFolder
    if {![file exists $downloadFolder] \
      || ![file isdirectory $downloadFolder]} {
	global HOME
	alertnote "Your Download Folder does not exist.\
	  I'll download to Alpha's home directory."
	set downloadFolder $HOME
    }
    url::fetch $url $downloadFolder
}

proc url::getADirectory {url} {
    foreach u [url::listAllInDirectory $url] {
	status::msg "Downloading $u"
	url::download $u
    }
    status::msg "Download complete"
}

## 
 # --------------------------------------------------------------------------
 # 
 # "url::getAFile" --
 # 
 # This is the same as url::download, except if we're given a directory url.
 # In that case we find a listing of that directory and then ask the user for
 # a file in that directory.
 # 
 # --------------------------------------------------------------------------
 ##

proc url::getAFile {url} {
    while {1} {
	while {[url::isDirectory $url]} {
	    set url [url::pickFromDirectory $url]
	}
	if {[catch [list url::download $url] res]} {
	    error "Fetch error '$res'"
	}
	set type [lindex $res 0]
	set name [lindex $res 1]
	
	# Check if it really was a directory without a trailing '/'
	if {[url::downloadedDirectoryListing $type $name]} {
	    set url [url::pickFromDirectory $url [file::readAll $name]]
	    file delete $name
	} else {
	    break
	}
    }
    return $res
}

proc url::listAllInDirectory {dirurl {contents ""}} {
    if {![regexp {/$} $dirurl]} { append dirurl "/" }
    set listing [url::directoryListing $dirurl $contents]

    set res {}
    foreach u $listing {
	lappend res [lindex $u 1]
    }
    return $res
}

## 
 # --------------------------------------------------------------------------
 # 
 # "url::pickFromDirectory" --
 # 
 # Optional argument is the contents of the dirurl if it has been previously
 # downloaded (perhaps by mistake).
 # 
 # --------------------------------------------------------------------------
 ##

proc url::pickFromDirectory {dirurl {contents ""}} {
    if {![regexp {/$} $dirurl]} { append dirurl "/" }
    set listing [url::directoryListing $dirurl $contents]

    set names [list]
    foreach u $listing {
	lappend names [lindex $u 0]
    }
    set filechoice [listpick -p "Pick a file to install" $names]
    set index [lsearch -exact $names $filechoice]
    if {$index < 0} {
	return -code error "User selected a file I can't find in the list!"
    }
    set result [lindex [lindex $listing $index] 1]
    return $result
}

proc url::downloadedDirectoryListing {type name} {
    switch -- $type {
	"http" {
	    # Check if "<TITLE>Index of " is in the first 10 lines.
	    set fin [alphaOpen $name r]
	    for {set i 0} {$i < 10} {incr i} {
		if {[eof $fin]} { break }
		gets $fin line
		if {[regexp {<TITLE>Index of } $line]} {
		    close $fin
		    return 1
		}
	    }
	    close $fin
	}
    }
    return 0
}

## 
 # --------------------------------------------------------------------------
 # 
 # "url::contents" --
 # 
 # This works for anything 'url::fetch' can handle.
 # 
 # --------------------------------------------------------------------------
 ##

proc url::contents {url} {
    # Fetch the url contents into a temporary file
    temp::cleanup _urltmp
    set _tmp [temp::unique _urltmp tmp]
    url::fetch $url $_tmp
    
    # Get the contents of the url
    set fd [alphaOpen $_tmp "r"]
    if {![set err [catch {read $fd} contents]]} {
	if {[set charset [htmlGetMetaCharset $contents]] ne ""} {
	    catch {
		fconfigure $fd -encoding $charset
		seek $fd 0
		set contents [read $fd]
	    }
	}
    }
    close $fd
    
    if {$err} {
	return -code error $contents
    }
    return $contents
}

proc url::extractTag {contents tag {attr ""}} {
    set start 0
    if {[regexp -nocase -start $start -indices \
      -- "<$tag\[^>\]*>" $contents opening] && \
      [regexp -nocase -start [lindex $opening 1] -indices \
      -- "</$tag>" $contents closing]} {
	if {$attr != ""} {
	    upvar 1 $attr attrs
	    set tagLine [eval [list string range $contents] $opening]
	    set idx0 [expr {[string length $tag] + 1}]
	    set idx1 "end-1"
	    set attrs [string trim [string range $tagLine $idx0 $idx1]]
	}
	return [string range $contents \
	  [expr {[lindex $opening 1] + 1}] \
	  [expr {[lindex $closing 0] - 1}]]
    } else {
	error "Can't find tags pair <$tag>É</$tag>"
    }
}

proc url::directoryListing {url {urlContents ""}} {
    if {![url::isDirectory $url]} {
	return -code error "\"$url\" is not a directory"
    }
    set t [url::parse $url]
    set type [lindex $t 0]
    set rest [lindex $t 1]
    
    # Should return list of sublists where each sublist
    # is "name url date ...".  This is used by install::fromRemoteUrl
    # amongst other places
    switch -- $type {
	"ftp" {
	    if {![string length $urlContents]} {
		set urlContents [url::contents $url]
	    }
	    set lines [split $urlContents "\n\r"]
	    set files {}
	    foreach f [lrange [lreplace $lines end end] 1 end] {
		set nm [lindex $f end]
		if {[string length $nm]} {
		    if {[string match "d*" $f]} {
			#lappend files "$nm/"
		    } else {
			regexp {[A-Z].*$} [lreplace $f end end] time
			set date [lindex $time end]
			if {[regexp : $date] \
			  || ![regexp {^19[89][0-5]$} $date]} {
			    # reject anything pre 1996
			    lappend files [list $nm $url$nm $time]
			}
		    }
		}
	    }
	    return $files
	}
	"file" {
	    set filename [string range $rest 1 end]
	    set files [list]
	    foreach f [glob -dir $filename *] {
		lappend files [list [file tail $f] [file::toUrl $f]]
	    }
	    return $files
	}
	"http" {
	    if {![string length $urlContents]} {
		set urlContents [url::contents $url]
	    }
	    set lines [split $urlContents "\n\r"]
	    set files {}
	    set hReg \
	      "<A HREF=\"(\[^\"\]*)\">\[^<\]*</A>\[ \t\]*(\[^ \t\]+)\[ \t\]"
	    foreach f $lines {
		if {[regexp "<A (.*)<A " $f]} {
		    # lines with two links are ignored
		    continue
		}
		if {[regexp -nocase -- $hReg $f "" name date]} {
		    if {![regexp {/$} $name]} {
			if {![regexp {[89][0-5]$} $date]} {
			    # reject anything pre 1996
			    set date [split $date -]
			    set md "[lindex $date 1] [lindex $date 0] "
			    append md [expr {[lindex $date 2] < 80 ? 20 : 19}]
			    append md [lindex $date 2]
			    lappend files [list $name $url$name $md]
			}
		    }
		}
	    }
	    return $files
	}
	default {
	    return -code error "Don't know how to list '$type' url directories"
	}
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "url::isDirectory" --
 # 
 # Should we perhaps check for 'index.html' urls?  If so then the above
 # procedure should also be modified (we couldn't just get a file's url by
 # appending the name onto the 'directory').
 # 
 # --------------------------------------------------------------------------
 ##

proc url::isDirectory {url} {
    return [regexp "/\$" $url]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "url::makeAbsolute" --
 # 
 # Given a 'base' url and a potentially relative url, resolve the final
 # absolute url.  It is up to any calling code to ensure that the base url is
 # in proper format, i.e. contains a trailing '/' or 'index.html' if
 # necessary.
 # 
 # A base url that is something like 'http://www.kelehers.org/alpha/' will
 # return a url which will most certainly throw an error down the line.
 # Similarly, relative urls that would normally break if parsed by a browser
 # will most likely produce garbage output here.
 # 
 # --------------------------------------------------------------------------
 ##

proc url::makeAbsolute {baseUrl relUrl} {
    
    # If "relUrl" is an empty string, then we have nothing to reconcile.
    if {![string length $relUrl]} {
	return $baseUrl
    } 
    # Make sure that 'baseUrl' has a trailing '/' if it refers to a server.
    if {[regexp -- {^([a-zA-Z0-9]+://[^/]+$)} $baseUrl]} {
	append baseUrl "/"
    }
    set parent [string range $baseUrl 0 [string last "/" $baseUrl]]

    if {[regexp -- {^//} $relUrl]} {
	# It should inherit only the base URL's scheme.
	regsub {:.*} $baseUrl "" scheme
	return "${scheme}:${relUrl}"
    } elseif {[regexp {^[^/\#]+:} $relUrl]} {
	# This is already absolute
	return $relUrl
    } elseif {[regexp -- {^\#} $relUrl]} {
	# A simple anchor link in the same document.
	return ${baseUrl}${relUrl}
    } elseif {![regexp -- {^([./]+).*} $relUrl allofit leadingChars]} {
	# Something contained in the parent directory.
	return ${parent}${relUrl}
    } elseif {[string index $leadingChars 0] == "/"} {
	# Something contained in the server directory.
	if {[regexp {^([a-zA-Z0-9]+://[^/]+)} $parent allofit server]} {
	    return ${server}${relUrl}
	} else {
	    error "Could not identify server."
	}
    } else {
	# Up some levels in the family tree.
	set urlDirs  [split $parent "/"]
	set upTo     [regsub -all {\.\./} $relUrl {} theRest]
	set length   [expr {[llength $urlDirs] - $upTo - 2}]
	set ancestor [join [lrange $urlDirs 0 $length] "/"]/
	# Ignore any './' strings.
	regsub -all {\./} $theRest {} theRest
	return ${ancestor}${theRest}
    }
}

proc url::parse {url} {
    if {![regexp {^([^:]+)://(.*)$} $url -> type rest]} {
	error "I couldn't understand that url: '$url'"
    }
    return [list $type $rest]
}

proc url::parseFull {url} {
    if {![regexp {^([^:]+)://(.*)$} $url -> type rest]} {
	error "I couldn't understand that url: '$url'"
    }
    return [list $type $rest]
}

proc url::parseFtp {p array} {
    # format is user:pass@host/path
    regexp {(([^:]*)(:([^@]*))?@)?([^/]*)/(.*/)?([^/]*)$} $p \
      junk junk user junk pass host path file
    
    if {$user == ""} {
	set user "anonymous"
	if {[catch {set pass [icGetPref Email]}] || ![string length $pass]} {
	    set pass "anonymous"
	}
    }
    upvar 1 $array a
    array set a [list user $user pass $pass host $host path $path file $file]
}

proc url::store {url file} {
    set t [url::parse $url]
    set type [lindex $t 0]
    set rest [lindex $t 1]	
    switch -- $type {
	"ftp" {
	    url::parseFtp $rest i
	    set i(file) [file tail $file]
	    ftpStore "$file" $i(host) "$i(path)$i(file)" $i(user) $i(pass)
	}
	"file" {
	    if {[file isdirectory $file]} {
		error "Don't know how to store directories to file urls"
	    } else {
		set urlfilename [string range $rest 1 end]
		file copy $file $urlfilename
	    }
	}
	default {
	    error "Don't know how to put '$type' urls"
	}
    }
}

proc url::fetchFrom {url localdir {file ""}} {
    url::fetch ${url}${file} $localdir $file	
}


## 
 # --------------------------------------------------------------------------
 # 
 # "url::fetch" --
 # 
 # Get a precise url into a localdir/file.  The url may be a directory, in
 # which case we retrieve a listing.
 # 
 # Use url::fetchFrom to fetch a file from a given url-location.
 # 
 # --------------------------------------------------------------------------
 ##

proc url::fetch {url localdir {file ""}} {
    set t [url::parse $url]
    set type [lindex $t 0]
    set rest [lindex $t 1]
    if {$file != ""} {
	set to [file join $localdir $file]
    } else {
	set to $localdir
    }
    
    set redirect ""
    switch -- $type {
	"ftp" {
	    url::parseFtp $rest i
	    catch {file mkdir [file dirname $localdir]}
	    if {[regexp -- "/\$" "$i(path)$i(file)"]} {
		# directory
		ftpList $to $i(host) $i(path) $i(user) $i(pass)
	    } else {
		ftpFetch $to $i(host) "$i(path)$i(file)" $i(user) $i(pass)
	    }
	    set localname $to
	}
	"http" {
	    if {[file isdirectory $to]} {
		if {[regexp "/\$" $url]} {
		    set to [file join $to index.html]
		} else {
		    set tail [file tail $url]
		    regexp -- {\?file=(.*)$} $tail -> tail
		    set to [file join $to [file::makeNameLegal $tail]]
		}
	    }
	    set redirect [httpFetch $url $to]
	    set localname $to
	}
	"file" {
	    set filename [string range $rest 1 end]
	    if {[file isdirectory $filename]} {
		error "Don't know how to fetch 'file' directory urls"
	    } else {
		set localname [file join $to \
		  [file::makeNameLegal [file tail $filename]]]
		file copy $filename $localname
	    }
	}
	default {
	    error "Don't know how to fetch '$type' urls"
	}
    }
    return [list $type $localname $redirect]
}

proc url::browserWindow {} {
    return [lindex [url::getBrowserUrlAndName] 0]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "url::getBrowserUrlAndName" --
 # 
 # Returns the URL and the name corresponding to the foremost browser 
 # window. The main difficulty is to get the name of the browser window 
 # which is the value of the <title> tag. 
 # 
 # The implementation for Macintosh and Windows is very fast: depending
 # on the browser, it uses various AppleEvents or Dde to get the url and
 # title of the first window.  On OSX, the WWW!/LSTW AE works only for
 # Explorer, iCab and Opera (bug 1283).
 # 
 # For non-MacOSX Unix, the proc is unimplemented.
 # 
 # --------------------------------------------------------------------------
 ##

proc url::getBrowserUrlAndName {} {
    global browserSig browserSigs tcl_platform
    
    watchCursor
    switch -- $tcl_platform(platform) {
	"macintosh" - "unix" {
	    if {$tcl_platform(platform) == "unix" && $tcl_platform(os) != "Darwin"} {
		error "Sorry, this is unimplemented on this platform."
	    }
	    if {![app::isRunning $browserSigs name sig]} {
		error "No browser running."
	    }
	    if {$alpha::macos == 1} {
		# Get the browser windows numbers
		set winnums [tclAE::build::resultData '$sig' WWW! LSTW]
		# The winnums variable must be a list of window numbers. We are 
		# interested in the first one.
		if {$winnums!="" && [regexp "^\[0-9\]+( \[0-9\]+)*$" $winnums]} {
		    if {![catch {set winf [tclAE::build::resultData '$sig' WWW! WNFO \
		      ---- [lindex $winnums 0]]} res]} {
			return $winf
		    } else {
			alertnote $res
		    }
		} else {
		    error "No browser window currently opened."
		}
	    } elseif {$alpha::macos == 2} {
		switch -- $sig {
		    "MSIE" - "iCAB" - "OPRA" {
			# Get the browser windows numbers
			set winnums [tclAE::build::resultData '$sig' WWW! LSTW]
			# The winnums variable must be a list of window numbers. We are 
			# interested in the first one.
			if {$winnums!="" && [regexp "^\[0-9\]+( \[0-9\]+)*$" $winnums]} {
			    set theae [tclAE::send -r '$sig' WWW! WNFO ---- [lindex $winnums 0]]
			    set objDesc [tclAE::getKeyDesc $theae ----]
			    set url [tclAE::getNthData $objDesc 0 TEXT]
			    set name [tclAE::getNthData $objDesc 1 TEXT]
			} else {
			    alertnote "No browser window currently opened."
			}
		    }
		    "sfri" {
			set theae [tclAE::send -r '$sig' core getd ---- \
			  [tclAE::build::propertyObject pURL [tclAE::build::indexObject docu 1]]]
			set url [tclAE::getKeyData $theae ---- TEXT]
			set theae [tclAE::send -r '$sig' core getd ---- \
			  [tclAE::build::propertyObject pnam [tclAE::build::indexObject docu 1]]]
			set name [tclAE::getKeyData $theae ---- TEXT]
		    }
		    "MOZZ" - "CHIM" {
			set theae [tclAE::send -r '$sig' core getd ---- \
			  [tclAE::build::propertyObject curl [tclAE::build::indexObject cwin long(1)]]]
			set url [tclAE::getKeyData $theae ---- TEXT]
			set theae [tclAE::send -r '$sig' core getd ---- \
			  [tclAE::build::propertyObject pnam [tclAE::build::indexObject cwin long(1)]]]
			set name [tclAE::getKeyData $theae ---- TEXT]
			regsub "Netscape: *" $name "" name
		    }
		    "OWEB" {
			# OmniWeb accepts the WWW! LSTW AppleEvent but returns an unordered 
			# list (i-e, the first window is not necessarily the topmost). The 
			# workaround here is to get the id first.
			set id [tclAE::build::resultData '$sig' core getd ---- \
			  [tclAE::build::propertyObject "ID  " [tclAE::build::indexObject cwin long(1)]]]
			set theobj "obj {want:type('Owbc'), from:'null'(), form:'ID  ', seld:$id}"
			set theae [tclAE::send -r '$sig' core getd ---- \
			  [tclAE::build::propertyObject curl $theobj]]
			set url [tclAE::getKeyData $theae ---- TEXT]
			set theae [tclAE::send -r '$sig' core getd ---- \
			  [tclAE::build::propertyObject pnam $theobj]]
			set name [tclAE::getKeyData $theae ---- TEXT]
		    }
		}
		return [list $url $name]
	    }
	}
	"windows" {
	    if {[info exists browserSig]} {
		set root [string tolower [file rootname [file tail $browserSig]]]
	    } else {
		set root iexplore
	    }
	    set root [string trim $root ".0123456789"]
	    # If multiple iexplore instances are running, this seems
	    # to pick the first?  This should work for 'iexplore' and
	    # 'netscape' names.
	    set info [dde request $root WWW_GetWindowInfo 1]
	    set url [lindex [split $info \"] 1]
	    set name [lindex [split $info \"] 3]
	    return [list $url $name]
	}
    }
    return ""
} 


## 
 # --------------------------------------------------------------------------
 #	 
 # "GURL_AEHandler" --
 #	
 # Handle general GURL events by extracting the type 'ftp', 'http',É and
 # calling a procedure ${type}GURLHandler with a single parameter which is
 # the extracted resource.  Can be put to more general use.  You must
 # register this proc as an event handler if you want to use it.  Do this
 # with:
 #  
 #   tclAE::installEventHandler GURL GURL GURL_AEHandler
 #   
 # --------------------------------------------------------------------------
 ##

proc GURL_AEHandler {theAppleEvent theReplyAE} {
    set gizmo [tclAE::print $theAppleEvent]
    # tclAE::print seems to swallow the '\' between the class and event
    set msg "[string range $gizmo 0 3]\\[string range $gizmo 4 end]"
    
    if {![regsub {.*Ò(.*)Ó.*} $msg {\1} gurl]} {
	alertnote "Didn't understand GURL: $msg"
	return
    }
    set GURLtype [lindex [split $gurl ":"] 0]
    set GURLvalue [string range $gurl [expr {1+[string length $GURLtype]}] end]
    if {[catch {${GURLtype}GURLHandler $GURLvalue} msg]} {
	status::msg $msg
    }
    tclAE::putKeyData $theReplyAE ---- TEXT $msg
}

proc htmlGetMetaCharset {str} {
    if {![regexp -nocase -indices -- "<meta" $str first]} {
	return ""
    }
    if {![regexp -nocase -indices -- "</meta" $str last]} {
	return ""
    }
    set range [string range $str [lindex $first 1] [lindex $last 0]]
    if {[regexp -nocase -- {charset=([-\w]+)} $range -> charset]} {
	return $charset
    } else {
	return ""
    }
}

proc httpFetch {url to} {
    xserv::invoke getURL -url $url -to $to
    return $url
}

## 
 # --------------------------------------------------------------------------
 # 
 # "httpCopy" --
 # 
 # Copy a URL to a file and print meta-data.
 # 
 # --------------------------------------------------------------------------
 ##

proc httpCopy { url file {chunk 4096} } {
    if {[catch {
	uplevel \#0 {package require http}
	# We declare ourselves otherwise some sites will
	# actually reject us because they view the 'http' library
	# as being most likely a robot, I guess.
	http::config -useragent "AlphaTcl WWW browser"
    } err]} {
	return -code error "Couldn't load http package successfully\
	  (err: $err)"
    }

    # The http library automatically converts from the page's charset
    # into utf-8, but doesn't examine http-equiv tags...
    if {1} {
	set tmp [temp::unique http copy]
	set out [open $tmp w+]
	fconfigure $out -translation binary
	if {[catch {http::geturl $url -binary 1 -channel $out -progress \
	  [list httpProgress $url] -blocksize $chunk} token]} {
	    close $out
	    file delete $tmp
	    return -code error $token
	}
	seek $out 0
	set contents [read $out]
	close $out
	file delete $out
	set charset [htmlGetMetaCharset $contents]
	if {[file::isText $file]} {
	    set out [alphaOpen $file w]
	} else {
	    set out [::open $file w]
	    fconfigure $out -translation binary
	}
	if {$charset ne ""} {
	    # Catch in case we don't recognise the encoding
	    catch {
		set contents [encoding convertfrom $charset $contents]
		fconfigure $out -encoding $charset
	    }
	}
	puts -nonewline $out $contents
	close $out
	upvar #0 $token state
    } else {
	set out [alphaOpen $file w]
	if {[catch {http::geturl $url -channel $out -progress \
	  [list httpProgress $url] -blocksize $chunk} token]} {
	    close $out
	    file delete $file
	    return -code error $token
	}
	close $out
	upvar #0 $token state
    }
    set max 0
    foreach {name value} $state(meta) {
	if {[string length $name] > $max} {
	    set max [string length $name]
	}
	if {[regexp -nocase ^location$ $name]} {
	    # Handle URL redirects
	    #set value [string trim $value]
	    set value [url::makeAbsolute $url [string trim $value]]
	    status::msg "Location: $value"
	    http::cleanup $token
	    return [httpCopy $value $file $chunk]
	}
    }
    incr max
    if {0} {
	foreach {name value} $state(meta) {
	    puts [format "%-*s %s" $max $name: $value]
	}
    }
    http::cleanup $token
    return $url
}

proc httpProgress {args} {
    status::msg $args
}

# ===========================================================================
# 
# ×××× -------- ×××× #
# 
# ×××× Core ftp code ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "ftpFetch" --
 # 
 # Downloads a remote file to your disk. 
 # 
 # --------------------------------------------------------------------------
 ##

proc ftpFetch {localName host path user password {replyHandler ""}} {
    xserv::invoke ftpFetch -localName $localName -host $host \
      -path $path -user $user -password $password -replyHandler $replyHandler
}

proc ftpLibPut {s localName path} {
    global useFtpEolType tcl_platform
    set type $useFtpEolType
    if {$type == "mac"} { set type "macintosh" }
    if {$type == "ibm" || $type == "dos"} { set type "windows" }
    if {$type == "auto"} { set type $tcl_platform(platform) }
    
    if {[file::isText $localName] && ($tcl_platform(platform) != $type)} {
	set eol ""
	switch -- $type {
	    "unix" { set eol lf }
	    "windows" { set eol crlf }
	    "macintosh" { set eol cr }
	}
	set newLocal [temp::path ftpLibPut [file tail $localName]]
	set fout [open $newLocal w]
	set fin [open $localName r]
	fconfigure $fout -translation $eol
	fcopy $fin $fout
	close $fin
	close $fout
	ftp::Put $s $newLocal $path
	file delete $newLocal
    } else {
	ftp::Put $s $localName $path
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "ftpStore" --
 # 
 # Uploads a file to a remote ftp server.
 # 
 # --------------------------------------------------------------------------
 ##

proc ftpStore {localName host path user password {replyHandler ftpHandleReply}} {
    xserv::invoke ftpStore -localName $localName -host $host \
      -path $path -user $user -password $password -replyHandler $replyHandler
}

## 
 # --------------------------------------------------------------------------
 # 
 # "ftpList" --
 # 
 # Saves the file listing of a remote directory to a file.  Uses a trick for
 # Fetch when saving the file.  First the files are listed in a text window
 # in Fetch.  This window is then saved to the disk.
 # 
 # --------------------------------------------------------------------------
 ##

proc ftpList {localName host path user password {replyHandler ""}} {
    xserv::invoke ftpList -localName $localName -host $host \
      -path $path -user $user -password $password -replyHandler $replyHandler
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "checkNetFinderVersion" --
 # 
 # Checks the version of NetFinder.
 # 
 # --------------------------------------------------------------------------
 ##

ensureset ftpMultipleUploads ""

## 
 # --------------------------------------------------------------------------
 # 
 # "ftpHandleReply" --
 # 
 # Handles the reply when using ftpStore.  If the 'makedir' parameter is 1
 # (usually because we were called by 'ftpHandleReplyAndMakeDir'), then we
 # interpret 'nonexistent directory' errors and call ftpMkDir instead of
 # throwing an error.
 # 
 # --------------------------------------------------------------------------
 ##

proc ftpHandleReply {reply {makedir 0}} {
    global ftpMultipleUploads
    
    if {[catch {tclAE::getKeyData $reply errs} fetcherr]} {
	set fetcherr ""
    }
    if {[catch {tclAE::getKeyData $reply ----} anerr]} {
	set anerr ""
    }
    if {$fetcherr != ""} {
	# Fetch error
	if {[regexp {Error: (.*)} $fetcherr dum err2]} {set fetcherr $err2}
	if {$makedir && ($fetcherr == "that file or directory is unavailable or non-existent.")} {
	    status::msg "Creating new directory on server."
	    global ftp::_mkdir
	    eval ftpMkDir ${ftp::_mkdir}
	} else {
	    switchTo '[expr {$::alpha::platform == "alpha" ? "ALFA" : "AlTk"}]'
	    alertnote "Ftp error: $fetcherr"
	}
    } elseif {$anerr != ""} {
	if {$anerr != "0"} {
	    # Interarchy error.
	    if {$makedir && ($anerr == "553" || $anerr == "550" || $anerr == "-553" || $anerr == "-550")} {
		status::msg "Creating new directory on server."
		global ftp::_mkdir
		eval ftpMkDir ${ftp::_mkdir}
	    } else {
		switchTo '[expr {$::alpha::platform == "alpha" ? "ALFA" : "AlTk"}]'
		alertnote "Ftp error: $anerr"
	    }
	} else {
	    status::msg "Document uploaded to ftp server."
	    if {[llength $ftpMultipleUploads]} {ftpUploadNextFile}
	}
    } else {
	status::msg "Document uploaded to ftp server."
	if {[llength $ftpMultipleUploads]} {ftpUploadNextFile}
    }
    # Reset this flag.
    set ftpMultipleUploads {}
    return 1
}

proc ftpHandleReplyAndMakeDir {reply} {
    ftpHandleReply $reply 1
}

## 
 # --------------------------------------------------------------------------
 # 
 # "ftpDisplayMsg" --
 # 
 # Used by Tcl's 'ftp' package.
 # 
 # The way we use [ftp::Open -output ftpDisplayMsg], we want this to throw an
 # error whenever something goes wrong.
 # 
 # --------------------------------------------------------------------------
 ##

proc ftpDisplayMsg {s msg {state ""}} {
    switch -- $state {
	data	{::status::msg $msg}
	control	{::status::msg $msg}
	error	{
	    ::status::msg $msg
	    error $msg
	}
	default {::status::msg $msg}
    }	
}

proc ftpMkDir {host path user password {replyHandler ftpMkDirHandler}} {
    xserv::invoke ftpMkdir -host $host \
      -path $path -user $user -password $password -replyHandler $replyHandler
    return
}

proc ftpMkDirHandler {reply} {
    global ftpCurrentUpload ftp::_mkdir ftp::_dirtomake ftp::_originaldirtomake
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
	    set a [string range ${ftp::_dirtomake} 0 [string last / [string trimright ${ftp::_dirtomake} /]]] 
	    eval ftpMkDir [lreplace ${ftp::_mkdir} 1 1 ${ftp::_dirtomake}]
	} else {
	    switchTo '[expr {$::alpha::platform == "alpha" ? "ALFA" : "AlTk"}]'
	    alertnote "Ftp error: $fetcherr"
	}
    } elseif {$anerr != ""} {
	if {$anerr != "0"} {
	    # Interarchy error
	    if {$anerr == "553" || $anerr == "550" || $anerr == "521" || \
	      $anerr == "-553" || $anerr == "-550" || $anerr == "-521"} {
		set ftp::_dirtomake [string range ${ftp::_dirtomake} 0 [string last / [string trimright ${ftp::_dirtomake} /]]] 
		eval ftpMkDir [lreplace ${ftp::_mkdir} 1 1 ${ftp::_dirtomake}]
	    } else {
		switchTo '[expr {$::alpha::platform == "alpha" ? "ALFA" : "AlTk"}]'
		alertnote "Ftp error: $anerr"
	    }
	} else {
	    status::msg "Directory created on server."
	    set ftp::_dirtomake ${ftp::_originaldirtomake}
	    eval ${ftpCurrentUpload}
	}
    } else {
	status::msg "Directory created on server."
	set ftp::_dirtomake ${ftp::_originaldirtomake}
	eval ${ftpCurrentUpload}
    }
    return 1
}


# ×××× Remote mirroring ×××× #

proc urlMirrorHierarchy {localDir url} {
    xserv::invoke remoteMirror -localDir $localDir -url $url
}

proc ftpMirrorHierarchy {localDir host user password path} {
    xserv::invoke ftpMirror -localDir $localDir -host $host \
      -user $user -password $password -path $path
}

proc iteratingMirrorHelper {localDir} {
    
    set val [dialog -w 330 -h 100 \
      -t "Upload files modified within the last" 10 10 290 30 \
      -e "" 15 40 45 55 \
      -m {hours days hours minutes} 60 40 200 60 \
      -b OK 20 70 85 90 -b Cancel 110 70 175 90 \
      -b "Upload all files" 200 70 320 90]
    
    set age [string trim [lindex $val 0]]
    if {[lindex $val 3] || (![is::PositiveInteger $age] && ![lindex $val 4])} {
	error "Cancelled"
    }
    
    if {[lindex $val 4]} {
	set ftpUploadLimit 0
    } else {
	global tcl_precision
	if {![info exists tcl_precision]} {
	    set old_precision 6
	} else {
	    set old_precision $tcl_precision
	} 
	set tcl_precision 17
	switch -- [lindex $val 1] {
	    days {set ftpUploadLimit [expr [now].0 - $age * 86400]}
	    hours {set ftpUploadLimit [expr [now].0 - $age * 3600]}
	    minutes {set ftpUploadLimit [expr [now].0 - $age * 60]}
	}
	set tcl_precision $old_precision
	regexp {[^\.]+} ${ftpUploadLimit} ftpUploadLimit
    }
    status::msg "Building file listÉ"
    
    set filesToUpload [list]
    
    set folders [list $localDir]
    while {[llength $folders]} {
	set newFolders ""
	foreach fl $folders { 
	    foreach f [glob -nocomplain -dir $fl *] {
		if {[file isdirectory $f]} {
		    lappend newFolders $f
		} else {
		    if {$ftpUploadLimit == 0 \
		      || $ftpUploadLimit < [file mtime $f]} {
			lappend filesToUpload $f
		    }
		}
	    }
	}
	set folders $newFolders
    }
    
    if {[llength $filesToUpload] == 0} {
	error "Cancelled - No files need uploading"
    }
	
    return $filesToUpload
}

proc iteratingMirrorToUrl {localDir url} {
    foreach f [iteratingMirrorHelper $localDir] {
	xserv::invoke Upload -localName $f -url $url
    }
}

proc iteratingMirrorToFtp {localDir host user password path} {
    global ftpMultipleUploads ftpMultipleUploadInfo

    set ftpMultipleUploads [iteratingMirrorHelper $localDir]
    set ftpMultipleUploadInfo [list $localDir $host $user $password $path]
    
    ftpUploadNextFile
}

proc ftpUploadNextFile {} {
    global ftpMultipleUploadInfo ftp::_mkdir \
      ftpCurrentUpload ftp::_dirtomake ftpMultipleUploads
    
    if {[llength $ftpMultipleUploads]} {
	set f [lindex $ftpMultipleUploads 0]
	set ftpMultipleUploads [lreplace $ftpMultipleUploads 0 0]
	status::msg "Uploading '[file tail $f]'"
	set ftpBaseLen [expr {[string length [lindex $ftpMultipleUploadInfo 0]] + 1}]
	set path [string range $f ${ftpBaseLen} end]
	regsub -all [quote::Regfind [file separator]] $path {/} path
	if {[lindex ${ftpMultipleUploadInfo} 4] != ""} {set path [join [list [lindex ${ftpMultipleUploadInfo} 4] $path] /]}
	set ftp::_dirtomake [string range $path 0 [string last / $path]]
	set ftp::_mkdir [list [lindex ${ftpMultipleUploadInfo} 1] ${ftp::_dirtomake} [lindex ${ftpMultipleUploadInfo} 2] [lindex ${ftpMultipleUploadInfo} 3]]
	eval [set ftpCurrentUpload [list ftpStore $f [lindex ${ftpMultipleUploadInfo} 1] $path [lindex ${ftpMultipleUploadInfo} 2] [lindex ${ftpMultipleUploadInfo} 3] ftpHandleReplyAndMakeDir]]
    } else {
	status::msg "All documents uploaded to ftp server."
    }
}

ensureset interarchyMirrorWarn 1

proc interarchyMirror {localDir host user password path} {
    global interarchyMirrorWarn
    
    if {$interarchyMirrorWarn} {
	set val [dialog -w 400 -h 100 -t "Warning! Files on your server not\
	  found on your disk will be deleted from the server." 10 10 390 40 \
	  -c "Don't warn me about this in the future." 0 10 50 390 65 \
	  -b OK 20 75 85 95 -b Cancel 110 75 165 95]
	if {[lindex $val 0]} {
	    set interarchyMirrorWarn 0
	    prefs::modified interarchyMirrorWarn
	}
	if {[lindex $val 2]} {return}
    }
    tclAE::send -p 'Arch' Arch MPut ---- "Ò${localDir}Ó" FTPh "Ò${host}Ó" \
      FTPc "Ò${path}Ó" ArGU "Ò${user}Ó" \
      ArGp "Ò${password}Ó"
}

namespace eval ftp {
    
    variable NFpwList
    
    array set NFpwList {
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
}

# ===========================================================================
# 
# ×××× NetFinder Support ×××× #
# 

proc checkNetFinderVersion {} {
     global NetFinderVersion
     if {![info exists NetFinderVersion]} {
	alpha::package require version
	# if error, assume recent enough.
	if {[catch {file::version -creator Woof} NetFinderVersion]} {
	    set NetFinderVersion "2.1.2"
	    return 1
	}
     }
     return [expr {[alpha::package vcompare $NetFinderVersion "2.1.2"] >= 0}]
}

proc ftpNetFinderMirror {server} {
    global ftp::NFpwList ftpNFmirrorFiles
    if {![info exists ftpNFmirrorFiles([lindex $server 0])] || 
    ([set ftpNFmirrorFiles([lindex $server 0])] != ":Generic" && ![file exists [set ftpNFmirrorFiles([lindex $server 0])]])} {
	set val [dialog -w 400 -h 100 -t "No NetFinder mirror file has been selected for this home page. Either select one or let Alpha use a generic one.\
	  If you select one it may only contain one single mirror item." 10 10 390 60 \
	  -b Select 20 70 85 90 -b "Use generic" 110 70 190 90 -b Cancel 215 70 280 90]
	if {[lindex $val 2]} {return}
	if {[lindex $val 0]} {
	    ftpPickNFmirrorFile [lindex $server 0]
	} else {
	    set ftpNFmirrorFiles([lindex $server 0]) ":Generic"
	    prefs::modifiedArrayElement [lindex $server 0] ftpNFmirrorFiles
	}
    }
    if {[set ftpNFmirrorFiles([lindex $server 0])] == ":Generic"} {
	set fil [temp::unique ftptmp NFmirror]
	set passw ""
	for {set i 0} {$i < [string length [lindex $server 3]]} {incr i} {
	    append passw [set ftp::NFpwList([string index [lindex $server 3] $i])]
	}
	set path [tclAE::build::alis "[lindex $server 0]:"]
	regexp {Ç(.*)È} $path "" path
	set out "<NFML>\n\n<head>\n\t<version=1.0>\n\t<encoding=Macintosh>\n</head>\n\n<body>\n\n<item>\n\t<attributes>\n\t\t<name=\"HTML mode mirror\">"
	append out "\n\t\t<type=MIRROR_ITEM>\n\t\t<source>\n\t\t\t<alias="
	for {set i 0} {$i < [string length $path]} {incr i 64} {
	    append out "\n[string range $path $i [expr {$i + 63}]]"
	}
	append out ">\n\t\t\t<path=\"[lindex $server 0]:\">\n\t\t</source>\n\t\t<target>"
	append out "\n\t\t\t<url=ftp://[lindex $server 2]:${passw}@[lindex $server 1]/[lindex $server 4]>"
	append out "\n\t\t</target>\n\t\t<mirror_options=by_name,by_size>\n\t\t<comment=\"\">"
	append out "\n\t\t<label=0>\n\t\t<lock_status=UNLOCKED>\n\t\t<stationery_status=NORMAL>\n\t</attributes>\n</item>\n\n</body>\n</NFML>"
	set fid [open $fil w]
	puts $fid $out
	close $fid
	setFileInfo $fil type Mirr
    } else {
	set fil [set ftpNFmirrorFiles([lindex $server 0])]
	ftpCheckNFmirrorFile $fil [lindex $server 0]
    }
    sendOpenEvent -r 'Woof' $fil
    switchTo 'Woof'
    # A little delay to make sure window is opened
    set t [ticks]
    while {[expr {[ticks] - $t < 30}]} {
	update idletasks
    }
    tclAE::send -p 'Woof' NFAE SAll
    tclAE::send -p 'Woof' NFAE OPEN
}

proc ftpNetFinderMirrorFiles {dir {for ""}} {
    global ftpNFmirrorFiles
    if {![info exists ftpNFmirrorFiles($dir)]} {
	set current "None"
    } else {
	set current [dialog::specialViewAndAbbreviate file \
	  [string trimleft [set ftpNFmirrorFiles($dir)] :]]
    }
    if {$for == ""} {
	set for "files in $dir"
    }
    set val [dialog -w 400 -h 170 -t "NetFinder mirror file for\r${for}" 10 10 390 40 \
      -t "Current file: $current" 10 50 390 65 \
      -t "You can either select a NetFinder mirror file for this folder or let Alpha use a generic one.\
      If you select one it may only contain one single mirror item." 10 75 390 135 \
      -b Select 20 140 85 160 -b "Use generic" 110 140 190 160 -b Cancel 215 140 280 160]
    if {[lindex $val 2]} {return}
    if {[lindex $val 0]} {
	ftpPickNFmirrorFile $dir
    } else {
	set ftpNFmirrorFiles($dir) ":Generic"
	prefs::modifiedArrayElement $dir ftpNFmirrorFiles
    }		
}

proc ftpPickNFmirrorFile {folder} {
    global ftpNFmirrorFiles
    set fil [getfile "NetFinder mirror file"]
    ftpCheckNFmirrorFile $fil $folder
    set ftpNFmirrorFiles($folder) $fil
    prefs::modifiedArrayElement $folder ftpNFmirrorFiles
}

proc ftpCheckNFmirrorFile {fil folder} {
    if {[file::getType $fil] == "Mirr"} {
	set fcont [file::readAll $fil]
	if {[regsub -all {<item>} $fcont "" ""] != 1} {
	    error "The mirror file '[file tail $fil]' must contain one single item."
	}
	if {![regexp "<path=\"$folder:\">" $fcont]} {
	    error "The file '[file tail $fil]' is not a mirror file for the folder '[file tail $folder]'."
	}
    } else {
	error "'[file tail $fil]' is not a NetFinder mirror file."
    }
}

# ===========================================================================
# 
# .