# -*-Tcl-*- (nowrap)
# 
# File: codeWarriorInspectors.tcl
# 							Last modification: 2005-03-26 19:04:46
# 
# Description: this file is part of the CodeWarrior Menu for Alpha.
# It contains the procedures related to class, file, target and project infos.

namespace eval cw {}


# -----------------------------------------------------------------
# Inspectors
# -----------------------------------------------------------------

proc cw::projectInfo {} {
	global cw_params
	watchCursor
	if {![cw::projectToFront]} {return} 
	status::msg "Building project info. Please wait..."
	set result "Current Project: $cw_params(currProjectName)\n"
	if {![catch {cw::currentProject}]} {
		append result "Access: [file dirname $cw_params(currProjectPath)][file separator]\n"
	} 
	set nbTrgt [tclAE::build::resultData $cw_params(cwsig) core cnte \
	  ---- [tclAE::build::indexObject PRJD 1] kocl type(TRGT)]
	append result "\n$nbTrgt target[expr {$nbTrgt>1 ? "s":""}]:\n"
	# Loop through all targets
	for {set j 1} {$j <= $nbTrgt} {incr j} {
		set targetobj [tclAE::build::indexObject TRGT $j \
		  [tclAE::build::indexObject PRJD 1]]
		append result "\t¥ Target: \
		  [tclAE::build::resultData $cw_params(cwsig) core getd \
		  ---- [tclAE::build::propertyObject pnam $targetobj]]\n"
		# Count subtargets
		set nbSubtrgt [tclAE::build::resultData $cw_params(cwsig) core cnte \
		  ---- $targetobj kocl type(SBTG)]
		if {$nbSubtrgt} {
			# Get subtargets if any
			append result "\t$nbSubtrgt subtargets.\n"
			set subtrgtList [tclAE::build::resultData $cw_params(cwsig) core getd \
			  ---- [tclAE::build::indexObject SBTG "abso('all ')" $targetobj]]
			append result "[join $subtrgtList "\n"]"
		} 
		# File types list
		set ftypList [cw::propertyList FTYP $targetobj "file types"]
		# Build result
		append result "\t\t[llength $ftypList] source files.\n"
		foreach typ [list LIBF RESF TXTF UNKN] \
		  name [list library resource text unknown] {
			set ${typ}Num [regsub -all $typ $ftypList "" ftypList]
			if {[set ${typ}Num]} {
				append result "\n\t\t[set ${typ}Num] $name files"
			} 
		} 
		append result "\n\n"
	}		
	new -n "Project Info" -info $result
	status::msg ""
}


proc cw::targetInfo {} {
	watchCursor
	if {![cw::projectToFront]} {return} 
	status::msg "Building current target info. Please wait..."
	set result "Current target: [cw::currentTarget]\n"
	append result "[ISOTime::ISODateAndTimeRelaxed]\n\n"
	append result "Abbreviations:\n"
	append result "LIBF: Library file\n"
	append result "RESF: Resource file\n"
	append result "TXTF: Text file\n"
	append result "UNKN: Unknown\n"
	append result "Lidx: Linking order (-1 means not in link order)\n"
	append result "\nType\tLidx\tName\n\n"
	append result [join [lsort [cw::fileTypesList]] "\n"]
	new -n "Target Info" -info "$result"
	status::msg ""
}


proc cw::fileInfo {} {
	global cw_params cw_info
	watchCursor
	set fname [win::StripCount [win::Current]]
	if {![cw::isInProject $fname 0]} {return} 
	status::msg "Building file info. Please wait..."
	set result "Current target: [cw::currentTarget]\n"
	append result "[ISOTime::ISODateAndTimeRelaxed]\n\n"
	append result "Name: [file tail $fname]\n"
	append result "Access: [file dirname $fname]:\n"
	
	set targetobj [tclAE::build::nameObject TRGT [tclAE::build::TEXT $cw_params(currTarget)] \
	  [tclAE::build::indexObject PRJD 1]]
	set scrfList [cw::propertyList Path $targetobj "source files"]
	set fileidx [cw::findFileIndex $scrfList $fname]
	
	if {$fileidx} {
		set fileobj [tclAE::build::indexObject SRCF $fileidx $targetobj]
		
		set proplist [list ID FTYP CSZE DSZE LINK LIDX MODD CMPD DBUG INIT MRGE WEAK PRER DPND]
		foreach prop $proplist {
			set value [tclAE::send -t 500000 -r $cw_params(cwsig) core getd \
			  ---- [tclAE::build::propertyObject $prop $fileobj]]
			if {![catch {tclAE::getKeyDesc $value ----} theobj]} {
				switch $prop {
					CSZE - DSZE - FTYP - ID - LIDX {
						set res $theobj
					}
					CMPD - MODD {
						set theobj [tclAE::getKeyData $value ----]    
						binary scan $theobj I* long
						set res [ISOTime::ISODateAndTimeRelaxed [lindex $long 1]]
					}
					DBUG - INIT - LINK - MRGE - WEAK {
						set res $cw_params($theobj)
					}
					DPND - PRER {
						set res ""
						set count [tclAE::countItems $theobj]
						set IDList [cw::propertyList ID $targetobj "file IDs"]
						for {set i 0} {$i < $count} {incr i} {
							set idx [lsearch $IDList [tclAE::getKeyData [tclAE::getNthDesc $theobj $i] seld]]
							append res "\n\t[lindex $scrfList $idx]"
						}
					}
				} 
			}
			append result "$cw_info($prop): $res\n"
		} 
	} else {
		append result "File not found."
	}
	new -n "[file tail $fname] Info" -info $result
	status::msg ""
} 


proc cw::linkOrder {} {
	global cw_params
	watchCursor
	if {![cw::projectToFront]} {return} 
	status::msg "Building link order. Please wait..."
	set targetobj [tclAE::build::nameObject TRGT [tclAE::build::TEXT [cw::currentTarget]] \
	  [tclAE::build::indexObject PRJD 1]]
	# Name of the current target
	set title "Target: $cw_params(currTarget)\n"
	# List of all source files
	set scrfList [cw::propertyList Path $targetobj "source files"]
	# List of all link indices
	set lidxList [cw::propertyList LIDX $targetobj "linking indices"]
	set nbSrcf [llength $scrfList]
	# Merge the two lists. Format the index to sort correctly. 
	set len [string length $nbSrcf]
	for {set i 0} { $i < $nbSrcf} {incr i} {
		set idx [lindex $lidxList $i]
		# Idx -1 means "not in the link list"
		if {$idx != "-1"} {
			set num [format %0${len}i [expr {$idx + 1}]]
			lappend result "$num\t[file tail [lindex $scrfList $i]]"
		} 
	}
	new -n "$cw_params(currTarget): Link Order" -info "$title\r[join [lsort $result] "\r"]"
	status::msg ""
}


# ÇÈ tclAE::build::propertyListObject [list Path FTYP LIDX]
# obj { form:prop,  want:type(prop),  seld:[type(Path), type(FTYP), type(LIDX)],  from:'null'()  }

proc cw::fileTypesList {} {
	global cw_params
	set targetobj [tclAE::build::nameObject TRGT [tclAE::build::TEXT [cw::currentTarget]] \
	  [tclAE::build::indexObject PRJD 1]]
	# Name of the current target
	set title "Target: $cw_params(currTarget)\n"
	# List of all source files
	set scrfList [cw::propertyList Path $targetobj "source files"]
	# List of all file types
	set ftypList [cw::propertyList FTYP $targetobj "file types"]
	# List of all linking indices
	set lidxList [cw::propertyList LIDX $targetobj "linking indices"] 
	set nbSrcf [llength $scrfList]
	# Merge the three lists
	for {set i 0} {$i < $nbSrcf} {incr i} {
		lappend result "[lindex $ftypList $i]\t[lindex $lidxList $i]\t[file tail [lindex $scrfList $i]]"
	}
	return $result
}


proc cw::resFilesList {} {
	global cw_params
	set targetobj [tclAE::build::nameObject TRGT [tclAE::build::TEXT [cw::currentTarget]] \
	  [tclAE::build::indexObject PRJD 1]]
	set result ""
	# List of all source files
	set scrfList [cw::propertyList Path $targetobj "source files"]
	# List of all file types
	set ftypList [cw::propertyList FTYP $targetobj "file types"]
	set nbSrcf [llength $scrfList]
	# Look for resource files (type RESF)
	for {set i 0} {$i < $nbSrcf} {incr i} {
		if {[lindex $ftypList $i] eq "RESF"} {
			lappend result [lindex $scrfList $i]
		}
	}
	return $result
}


proc cw::nonSimpleClasses {} {
	global cw_params
	if {![cw::checkRunning]} {return} 
	set res [tclAE::send -t 500000 -r $cw_params(cwsig) $cw_params(cwclass) NsCl]
	if {[cw::checkErrorInReply $res]} {return}	
	
	if {[catch {tclAE::getKeyDesc $resDesc ----} theobj]} {return} 
	if {![tclAE::countItems $theobj]} {
		status::msg "No simple classes"
		return
	} 
	set theobj [split $theobj]
	new -n "Non Simple Classes" -info [join $theobj "\n"]
} 


proc cw::openClassBrowser {} {
	global cw_params
	if {![cw::checkRunning]} {return} 
	if {[cw::selectClassDialog]} {
		catch {tclAE::send -t 500000 -r $cw_params(cwsig) $cw_params(cwclass) Brow \
		  ---- [tclAE::build::nameObject Clas [tclAE::build::TEXT $cw_params(currClass)]]} res
		if {[cw::checkErrorInReply $res]} {return}	
		switchTo $cw_params(cwsig)
	}
}


proc cw::getClassInfo {} {
	global cw_params
	if {![cw::isProjectOpen]} {return} 
	if {[cw::selectClassDialog]} {
		cw::classInspector $cw_params(currClass)
	} 
}


proc cw::classInspector {classname} {
	set title "Class '$classname'"
	set bsresult [cw::baseClasses $classname]
	if {[llength $bsresult]} {
		append title "\n\n[llength $bsresult] base classes :\n[join [lsort $bsresult] "\n"]"
	} 
	set dtresult [cw::dataMembers $classname]
	if {[llength $dtresult]} {
		append title "\n\n[llength $dtresult] data members :\n[join [lsort $dtresult] "\n"]"
	} 
	set fnresult [cw::memberFunctions $classname]
	if {[llength $fnresult]} {
		append title "\n\n[llength $fnresult] member functions :\n[join [lsort $fnresult] "\n"]"
	} 
	new -n "Class Info for '$classname'" -info $title
}


proc cw::baseClasses {name} {
	global cw_params
	set result ""
	set bsclNameObj [tclAE::build::indexObject BsCl "abso('all ')" \
	  [tclAE::build::nameObject Clas [tclAE::build::TEXT $name] \
	  [tclAE::build::indexObject Cata 1 ]]]
	# List of all base classes
	set bsclList [cw::propertyList Clas $bsclNameObj "base classes"]
	set num [llength $bsclList]
	if {$num} {
		# List of all base classes access properties
		set acceList [cw::propertyList Acce $bsclNameObj "access properties"]
		# List of all base classes virtual properties
		set virtList [cw::propertyList Virt $bsclNameObj "virtual properties"]
		# Clean up the bool's
		regsub -all {bool\(Ç00È\)} $virtList "  " virtList
		regsub -all {bool\(Ç01È\)} $virtList virtual virtList
		# Merge the lists
		for {set i 0} {$i < $num} {incr i} {
			lappend result "[lindex $acceList $i]\t[lindex $virtList $i]\t[lindex $bsclList $i]"
		}
	} 
	return $result
}


proc cw::dataMembers {name} {
	global cw_params
	set result ""
	set dtmbNameObj [tclAE::build::indexObject DtMb "abso('all ')" \
	  [tclAE::build::nameObject Clas [tclAE::build::TEXT $name] \
	  [tclAE::build::indexObject Cata 1 ]]]
	# List of all data members
	set dtmbList [cw::propertyList pnam $dtmbNameObj "data members"]
	set num [llength $dtmbList]
	if {$num} {
		# List of all data members access properties
		set acceList [cw::propertyList Acce $dtmbNameObj "access properties"]
		# List of all data members static properties
		set statList [cw::propertyList Stat $dtmbNameObj "static properties"]
		# Clean up the bool's
		regsub -all {bool\(Ç00È\)} $statList "  " statList
		regsub -all {bool\(Ç01È\)} $statList static statList
		# Merge the lists
		for {set i 0} {$i < $num} {incr i} {
			lappend result "[lindex $acceList $i]\t[lindex $statList $i]\t[lindex $dtmbList $i]"
		}
	}
	return $result
}


proc cw::memberFunctions {name} {
	global cw_params
	set result ""
	set mbfNameObj [tclAE::build::indexObject MbFn "abso('all ')" \
	  [tclAE::build::nameObject Clas [tclAE::build::TEXT $name] \
	  [tclAE::build::indexObject Cata 1 ]]]
	# List of all member functions
	set mbfnList [cw::propertyList pnam $mbfNameObj "member functions"]
	set num [llength $mbfnList]
	if {$num} {
		# List of all member functions access property
		set acceList [cw::propertyList Acce $mbfNameObj "access properties"]
		# List of all member functions virtual property
		set virtList [cw::propertyList Virt $mbfNameObj "virtual properties"]
		# List of all member functions static property
		set statList [cw::propertyList Stat $mbfNameObj "static properties"]
		# Clean up the bool's
		regsub -all {bool\(Ç00È\)} $virtList "  " virtList
		regsub -all {bool\(Ç01È\)} $virtList virtual virtList
		regsub -all {bool\(Ç00È\)} $statList "  " statList
		regsub -all {bool\(Ç01È\)} $statList static statList
		# Merge the lists
		for {set i 0} {$i < $num} {incr i} {
			lappend result "[lindex $acceList $i]\t[lindex $statList $i]\t[lindex $virtList $i]\t[lindex $mbfnList $i]"
		}
	}
	return $result
}