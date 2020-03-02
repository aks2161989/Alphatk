# -*-Tcl-*- (nowrap)
# 
# File: codeWarriorPanels.tcl
# 							Last modification: 2003-11-01 20:49:16
# 
# Description: this file is part of the CodeWarrior Menu for Alpha.
# It contains the procedures related to preference panels.

namespace eval cw {}


# -----------------------------------------------------------------
# Preference procs
# -----------------------------------------------------------------

proc cw::extractPanelInfo {panel} {
	global cw_info cw_params
	set result ""
	set aedesc [tclAE::send -t 500000 -r $cw_params(cwsig) $cw_params(cwclass) Gref PNam [tclAE::build::TEXT $panel]]
	set theobj [tclAE::getKeyDesc $aedesc ---- ]
		switch $panel {
			"Access Paths" {
				append result [cw::extractSettings bool [list PA02 PA04] $theobj]
			}
			"Build Extras" - "Debugger Global" {
				append result [cw::extractSettings bool [list EX09 EX04 EX30 EX31] $theobj]
			}
			"C/C++ Compiler" {
				append result [cw::extractSettings text FE08 $theobj]
				append result [cw::extractSettings enum [list FE18 FE20] $theobj]
				append result [cw::extractSettings bool [list FE01 FE02 FE03 FE04 FE05 FE06 FE07 FE09 \
				  FE11 FE12 FE13 FE14 FE15 FE16 FE17 FE24 FE25 FE26 FE23 FE19 FE10] $theobj]
			}
			"C/C++ Warnings" {
				append result [cw::extractSettings bool [list WA08 WA01 WA02 WA03 WA04 WA05 \
				  WA06 WA07 WA09 WA10 WA11 WA12] $theobj]
			}
			"Custom Keywords" {
				append result [cw::extractSettings color [list GH05 GH06 GH07 GH08] $theobj]		
			}
			"File Mappings" {
				append result "\n\t$cw_info(TA02)\t\t$cw_info(TA03)\t$cw_info(TA05)\t$cw_info(TA04)\t$cw_info(TA06)\t$cw_info(TA07)\n"
				if {![catch {tclAE::getKeyDesc $theobj FMps} thesubobj]} {
					append result [cw::extractSubSettings map $thesubobj]
				} 
			}
			"Layout Editor" {
				append result [cw::extractSettings bool [list LEco LEoi] $theobj]
				append result [cw::extractSettings default [list LEgx LEgy] $theobj]
			}
			"MacOS Merge Panel" {
				# append result [cw::extractSettings enum PR01 $theobj]
				append result [cw::extractSettings text [list PR02 PR03 PR04 MG03] $theobj]
				append result [cw::extractSettings bool [list L601 MG01 MG02] $theobj]
			}
			"MetroNub Panel" {
				append result [cw::extractSettings bool [list DB01 DB12 DB03 DB04 DB05 DB10 DB11] $theobj]
			}
			"Output Flags" {
				append result [cw::extractSettings bool [list OLok RLok PDmf FFiv FFhb FFnl \
				  FFsy FFci FFsh FFin ] $theobj]
				append result [cw::extractSettings text Comt $theobj]
				append result [cw::extractSettings enum FFlb $theobj]
			}
			"PPC Disassembler" {
				append result [cw::extractSettings bool [list DS02 DS23 DS21 DS22 DS03 DS31 DS04 DS05] $theobj]
			}
			"PPC Global Optimizer" {
				# aevt\ansr{'----':{'GO01':'null'(), 'GO02':'null'()}}
				append result [cw::extractSettings enum GO01 $theobj]
				append result [cw::extractSettings text GO02 $theobj]
			}
			"PPC Linker" {
				append result [cw::extractSettings text [list L602 L603  L604] $theobj]
				append result [cw::extractSettings bool [list LN02 LN03 LN04 L601 LN10 LN11] $theobj]
				append result [cw::extractSettings enum L605 $theobj]
			}
			"PPC PEF" {
				append result [cw::extractSettings bool [list PE06 PE07 PE10] $theobj]
				append result [cw::extractSettings text PE08 $theobj]
				append result [cw::extractSettings enum [list PE01 PE05] $theobj]
				append result [cw::extractSettings default [list PE02 PE03 PE04 PE09] $theobj]
			}
			"PPC Project" {
				# A bug in CW (?): this event always returns a series of null's.
				# aevt\ansr{'----':{'PR01':'null'(), 'PR02':'null'(), 'PR03':'null'(), 'PR04':'null'(), 'PR05':'null'(),
				# 'PR06':'null'(), 'PR07':'null'(), 'PR08':'null'(), 'PR09':'null'(), 'PR11':'null'(), 'PR12':'null'(), 
				# 'PR13':'null'(), 'PR14':'null'(), 'PR15':'null'(), 'P601':'null'(), 'PR16':'null'()}}
				append result [cw::extractSettings default [list PR01 PR02 PR03 PR04 PR05 PR06 PR07 PR08 \
				  PR09 PR11 PR12 PR13 PR14 PR15 P601 PR16] $theobj]
			}
			"PPCAsm Panel" {
				append result [cw::extractSettings bool [list PPC3 PPC4 PPC5] $theobj]
				append result [cw::extractSettings enum [list PPC1 PPC2] $theobj]
				append result [cw::extractSettings text PPC6 $theobj]
			}
			"Rez Compiler" {
				append result [cw::extractSettings bool [list CR01 CR03] $theobj]
				append result [cw::extractSettings enum [list CR08 CR05] $theobj]
				append result [cw::extractSettings text [list CR02 CR06] $theobj]
				append result [cw::extractSettings default [list CR04 CR07] $theobj]
			}
			"Runtime Settings" {
				if {![catch {tclAE::getKeyDesc $theobj RS01} thesubobj]} {
					append result  "$cw_info(RS01): [tclAE::getKeyData $thesubobj pnam]\n"
				} 
				append result [cw::extractSettings text [list RS02 RS03] $theobj]
				if {![catch {tclAE::getKeyDesc $theobj RS04} thesubobj]} {
					append result  "$cw_info(RS04):\n"
					append result [cw::extractSubSettings env $thesubobj]
				} 
			}
			"Source Trees" - "Target Source Trees" - "Global Source Trees" {
				if {![catch {tclAE::getKeyDesc $theobj ST01} thesubobj]} {
					append result [cw::extractSubSettings tree $thesubobj]
				} 
			}
			"Target Settings" {
				append result [cw::extractSettings text [list TA01 TA13 TA09 TA10 TA11] $theobj]
				append result [cw::extractSettings enum TA12 $theobj]
			}
			"Build Settings" {
				append result [cw::extractSettings text [list BX02 BX03] $theobj]
				append result [cw::extractSettings bool [list BX01 BX07] $theobj]
				append result [cw::extractSettings default [list BX04 BX05 BX06] $theobj]
			}
			"Debugger Display" {
				append result [cw::extractSettings bool [list Db01 Db09 Db02 Db03 Db04 Db05 Db10] $theobj]
				append result [cw::extractSettings color [list Db06 Db07] $theobj]		
				append result [cw::extractSettings default Db08 $theobj]
			}
			"Extras" {
				append result [cw::extractSettings bool [list EX19 EX07 EX10 EX11 EX12 EX18] $theobj]
				append result [cw::extractSettings default [list EX08 EX16 EX17] $theobj]
			}
			"Font" {
				append result [cw::extractSettings text ptxf $theobj]
				append result [cw::extractSettings bool FN01 $theobj]
				append result [cw::extractSettings default [list FN02 FN03 FN04 ptps] $theobj]
			}
			"Plugin Settings" {
				append result [cw::extractSettings enum PX01 $theobj]
				append result [cw::extractSettings bool PX02 $theobj]		
			}
			"Shielded Folders" {
				append result [cw::extractSettings bool [list SF02 SF03] $theobj]
			}
			"Syntax Coloring" {
				append result [cw::extractSettings bool GH01 $theobj]
				append result [cw::extractSettings color [list GH02 GH03 GH04 GH05 GH06 GH07 GH08] $theobj]		
			}
			"VCS Setup" {
				append result [cw::extractSettings text [list VC02 VC03 VC04] $theobj]
				append result [cw::extractSettings bool [list VC01 VC11 VC05 VC06 VC07 VC08] $theobj]
			}
		}
		return $result
}

proc cw::extractSettings {kind codelist objdesc} {
	global cw_info cw_enum cw_params
	set result ""
	foreach key $codelist {
		if {![catch {tclAE::getKeyData $objdesc $key} value]} {
			switch $kind {
				"bool" {
					append result "$cw_info($key): $cw_params($value)\n"
				}
				"text" {
					append result "$cw_info($key): [tclAE::getKeyData $objdesc $key]\n"
				}
				"color" {
					binary scan $value H4H4H4 r g b
					append result "$cw_info($key) (RGB): $r - $g - $b\n"
				}
				"enum" {
					set value [tclAE::getKeyData $objdesc $key]
					if {[info exist cw_enum($value)]} {
						append result "$cw_info($key): [set cw_enum($value)]\n"
					} else {
						append result "$cw_info($key): $value\n"
					}
				}
				default {
					append result "$cw_info($key): $value\n"
				}
			}
		} 
	} 
	return $result
}


proc cw::extractSubSettings {kind subobjdesc} {
	global cw_info cw_enum cw_params
	set result ""
	switch $kind {
		"map" {
			set count [tclAE::countItems $subobjdesc]
			for {set i 0} {$i < $count} {incr i} {
				set mapdesc [tclAE::getNthDesc $subobjdesc $i]
				append result "[tclAE::getKeyData $mapdesc PR04]\t"
				append result "[tclAE::getKeyData $mapdesc TA02]\t\t"
				foreach key [list TA03 TA05 TA04 TA06] {
					append result "$cw_params([tclAE::getKeyData $mapdesc $key])\t"
				}
				append result "[tclAE::getKeyData $mapdesc TA07]\t"
				append result "\n"
			}
		}
		"tree" {
			set count [tclAE::countItems $subobjdesc]
			for {set i 0} {$i < $count} {incr i} {
				set pathdesc [tclAE::getNthDesc $subobjdesc $i]
				append result "{[tclAE::getKeyData $pathdesc pnam]}\t\t[tclAE::getKeyData $pathdesc Path]\n"
			}
		}
		"env" {
			set count [tclAE::countItems $subobjdesc]
			for {set i 0} {$i < $count} {incr i} {
				set envdesc [tclAE::getNthDesc $subobjdesc $i]
				append result "\t[tclAE::getKeyData $envdesc pnam]=[tclAE::getKeyData $envdesc Valu]\n"
			}
		}
	}
	return $result
}


proc cw::allSettings {what} {
	global cw_params
	set result "[string toupper $what] SETTINGS\n"
	append result "[ISOTime::ISODateAndTimeRelaxed]\n\n"
	foreach panel $cw_params($what) {
		status::msg "'$panel' panel..."
		set panel [string trimright $panel "&"]
		append result "\n¥ Settings from panel '$panel'\n"
		append result [cw::extractPanelInfo $panel]
	} 
	return $result
}

