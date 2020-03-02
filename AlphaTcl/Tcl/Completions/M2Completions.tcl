# -*-Tcl-*- (nowrap)
#====================
# M2 mode Completions
#====================
#
# Version history
# -----------------------------------
# af    02/Mar/1998   M2 mode V 3.0.5
# af    09/Mar/1998   M2 mode V 3.0.6
# af    30/Mar/1998   M2 mode V 3.1
# af    06/Apr/1998   M2 mode V 3.1.1
# af    15/Apr/1998   M2 mode V 3.1.2
# af    07/May/1998   M2 mode V 3.1.3, adding improvements, 
#                     contributions by Juan Falgueras <juanfc@lcc.uma.es>
# af    12/May/1998   M2 mode V 3.1.4, adding killif and fixl 
# af    27/Aug/1998   M2 mode V 3.1.5, adding killif and fixl 
# af    30/Oct/1998   M2 mode V 3.1.6 
# af    08/Dec/1998   M2 mode V 3.1.7 
# af    01/Mar/1999   M2 mode V 3.2.0 
# af    22/Mar/1999   M2 mode V 3.2.1 
# af    24/Mar/1999   M2 mode V 3.2.2 
# af    08/Apr/1999   M2 mode V 3.2.3 
# af    14/Apr/1999   M2 mode V 3.2.4 
# af    22/Apr/1999   M2 mode V 3.2.5 
# af    22/May/1999   M2 mode V 3.2.6
# af    24/May/1999   M2 mode V 3.3b0
# af    27/May/1999   M2 mode V 3.3b1
# af    29/Jul/1999   M2 mode V 3.3b2
# af    02/Sep/1999   M2 mode V 3.3b3
# af    11/Nov/1999   M2 mode V 3.3b4
# af    25/Sep/2000   M2 mode V 3.5, adding template ife, ifelse for IF THEN ELSE END clause
# af    13/Apr/2001   M2 mode V 3.5.2 adding templates erec, vio
# af    15/Jun/2001   M2 mode V 3.6.0 
# af    23/Sep/2001   M2 mode V 3.7.0 
# af    14/Oct/2001   M2 mode V 3.7.2 for Alpha 7.5b3
# cbu   05/Sep/2002   M2 mode V 3.8   updated, using M2 namespace.
#                     added "M2cmds".  added M2::getName. added BEGIN.
#                     added lower and upper case completions.
# af    21/Feb/2003   M2 mode V 3.8.1 for Alpha 7.6
# af    12/Apr/2003   M2 mode V 3.8.7 for Alpha8 8.0b8
#                     - minor cleanup by Vince Darley
# af    21/Jan/2004   M2 mode V 4.0.0 for Alpha8 8.0b14 and later
# af    14/May/2004   M2 mode V 4.0.1 for Alpha8/X 8.0b15 and later
# af    14/Nov/2004   M2 mode V 4.1.0 adding procd
# af    20/Feb/2005   M2 mode V 4.1.1 updating URL information
# af    12/May/2005   M2 mode V 4.1.2 updating address information
# af    23/May/2005   M2 mode V 4.1.3 updating for latest URLs (new web server)
# 
# 
# REMARKS
# 
# See "Modula-2 Help" and "Modula-2 Tutorial.M2" for more on the use of 
# templates, expansions, and completions.
 
proc M2Completions.tcl {} {}

set completions(M2) {completion::cmd completion::electric completion::word}

# For version 3.0 of M2 mode the following completions were added.  Some of
# them were taken from Mod2Completions.tcl by Juan Falgueras in order to
# accomodate some user habits (such as disliking typing in capitals) which
# might have developed by Mod2 users who are interested in using this mode.
#  
# Note, however, the completions were not copied as is.  I fixed some
# Modula-2 syntax errors present, slightly streamlined all, and added many
# new ones.

namespace eval M2 {}

proc M2::setElectricCompletions {args} {
    
    global M2RightShift M2templateParts M2cmds M2electrics 
	global M2::curAlphaV
    
    # The templates will adjust to any reconfiguration done by the user, either
    # via "Config > Current Mode > Preferences..."  or F12
    if {![info exists M2RightShift]} {
        set _t "  "
    } else {
        set _t $M2RightShift
    }
    
    # Some author specific information to be used in templates during module
    # creation.  Please change this information to your hearts content.  Can
    # of course also be left empty entirely.  If you wanna get an idea what
    # they do, just choose the menu command.
    # 
    set M2templateParts(copyright)  "and Swiss Federal Institute of Technology Zurich ETHZ"
    # Author's address
    set institution                 "Swiss Federal Institute of Technology Zurich ETHZ"
    set affiliation                 "Systems Ecology / Department of Environmental Sciences"
    set street                      "ETH-Zentrum - CHN 35.1"
    set city                        "Zurich"
    set zipCode                     "CH-8092"
    set country                     "SWITZERLAND"

    if {("$country" == "USA") || ("$country" == "U.S.A.")} {
            set M2templateParts(address)    "$institution \r${_t}${_t}$affiliation \r${_t}${_t}$street \r${_t}${_t}$city, $zipCode \r${_t}${_t}$country \r${_t}${_t}"
    } else {
            set M2templateParts(address)    "$institution \r${_t}${_t}$affiliation \r${_t}${_t}$street \r${_t}${_t}$zipCode $city \r${_t}${_t}$country \r${_t}${_t}"
    }
    # Author's URLs
    set headerURL               "URLs:"
    set mailtoURL               "<mailto:RAMSES@env.ethz.ch>"
    set wwwURL                  "<http://www.sysecol.ethz.ch>"
    set ftpURL                  "<http://www.sysecol.ethz.ch/SimSoftware/RAMSES>"
    set M2templateParts(URLs)   "$headerURL \r${_t}${_t}${_t}${_t}$mailtoURL \r${_t}${_t}${_t}${_t}$wwwURL \r${_t}${_t}${_t}${_t}$ftpURL \r${_t}${_t}"

    # Miscellaneous (customize according to your specific needs 
    set M2electrics(killif)     "×kill0(*. should never occurr, following can be removed from final implementation .*)\rIF ¥cond¥ THEN\r${_t}DoKill(badProgState,GetMsgString, moduleName, procName,\r${_t}'¥describewhy¥' );\rEND(*IF*);\r¥¥"
    set M2electrics(fixl)       "×kill0 (*. needs fixing, only preliminary solution .*)¥¥"


    # some reserved words, statement clauses and full statements:
    # ----------------------------------------------------------

    # BEGIN
    set M2electrics(begin)      "×kill0BEGIN\r${_t}¥¥\rEND¥¥;¥¥\r¥¥"
    
    # MODULE structure
	set M2electrics(from)       "×kill0FROM ¥moduleName¥ IMPORT ¥object(s)¥;¥¥\r¥¥"
	set M2electrics(const)    	"×kill0CONST ¥¥;¥¥"
	set M2electrics(type)      	"×kill0TYPE ¥¥;¥¥"
	set M2electrics(var)       	"×kill0VAR ¥¥;¥¥"

    # TYPE
	set M2electrics(bool)      	"×kill0BOOLEAN;¥¥"
	set M2electrics(tr)         "×kill0TRUE¥¥"
	set M2electrics(1)          "×kill0TRUE¥¥"
	set M2electrics(fa)         "×kill0FALSE¥¥"
	set M2electrics(0)          "×kill0FALSE¥¥"
	set M2electrics(ch)      	"×kill0CHAR;¥¥"
	set M2electrics(int)      	"×kill0INTEGER;¥¥"
	set M2electrics(lint)      	"×kill0LONGINT;¥¥"
	set M2electrics(real)      	"×kill0REAL;¥¥"
	set M2electrics(lreal)      "×kill0LONGREAL;¥¥"
	set M2electrics(card)      	"×kill0CARDINAL;¥¥"
	set M2electrics(lcard)     	"×kill0LONGCARD;¥¥"
	set M2electrics(arr)        "×kill0ARRAY \[¥¥..¥¥\] OF ¥¥"
	set M2electrics(str)      	"×kill0ARRAY \[0..¥¥\] OF CHAR;¥¥"
	set M2electrics(rec)        "×kill0RECORD\r${_t}¥¥\rEND(*RECORD*);\r¥¥"
	set M2electrics(erec)       "×kill0END(*RECORD*);"

    # Proc parameter lists
	set M2electrics(darr)       "×kill0ARRAY OF ¥¥"
	set M2electrics(vdarr)      "×kill0VAR ¥¥: ARRAY OF ¥¥"
	set M2electrics(dstr)       "×kill0ARRAY OF CHAR;¥¥"
	set M2electrics(vdstr)      "×kill0VAR ¥¥: ARRAY OF CHAR;¥¥"
	set M2electrics(vsp)        "×kill0VAR(*speed-up*) ¥¥"
	set M2electrics(vio)        "×kill0VAR(*In/Out*) ¥¥"

    # Repetitions
	set M2electrics(for)        "×kill0FOR ¥¥:= ¥¥ TO ¥¥ DO\r${_t}¥¥\rEND(*FOR*);\r¥¥"
	set M2electrics(forby)      "×kill0FOR ¥¥:= ¥¥ TO ¥¥ BY ¥¥ DO\r${_t}¥¥\rEND(*FOR*);\r¥¥"
	set M2electrics(while)      "×kill0WHILE ¥¥ DO\r${_t}¥¥\rEND(*WHILE*);\r¥¥"
	set M2electrics(repeat)     "×kill0REPEAT\r${_t}¥¥\rUNTIL ¥¥;\r¥¥"
	set M2electrics(loop)       "×kill0LOOP\r${_t}¥¥\rEND(*LOOP*);\r¥¥"
	set M2electrics(endwhile)   "×kill0END(*WHILE*);\r¥¥"
	set M2electrics(endfor)     "×kill0END(*FOR*);\r¥¥"

    # IF
	set M2electrics(if)         "×kill0IF ¥cond¥ THEN\r${_t}¥true-clause¥\rEND(*IF*);\r¥¥"
	set M2electrics(ife)        "×kill0IF ¥cond¥ THEN\r${_t}¥true-clause¥\rELSE\r${_t}¥true-clause¥\rEND(*IF*);\r¥¥"
	set M2electrics(ifelse)     "×kill0IF ¥cond¥ THEN\r${_t}¥true-clause¥\rELSE\r${_t}¥true-clause¥\rEND(*IF*);\r¥¥"
	set M2electrics(with)       "×kill0WITH ¥¥ DO\r${_t}¥¥\rEND(*WITH*);\r¥¥"
	set M2electrics(elsif)      "×kill0ELSIF ¥¥ THEN\r${_t}¥¥"
	set M2electrics(else)       "×kill0ELSE\r${_t}¥¥"
	set M2electrics(endif)      "×kill0END(*IF*);\r¥¥"
	set M2electrics(eif)        "×kill0END(*IF*)"

    # CASE
	set M2electrics(case)       "×kill0CASE  ¥¥: ¥¥ OF\r| ¥¥:${_t}¥¥;\r| ¥¥:${_t}¥¥;\rELSE\r${_t}¥¥;\rEND(*CASE*);\r¥¥"
	set M2electrics(cases)      "×kill0CASE  ¥¥: ¥¥ OF\r| ¥¥:\r${_t}${_t}¥¥;\r| ¥¥:\r${_t}${_t}¥¥;\rELSE\r${_t}¥¥;\rEND(*CASE*);\r¥¥"
	set M2electrics(acase)      "×kill0| ¥¥:${_t}¥¥;"
	set M2electrics(acases)     "×kill0| ¥¥:\r${_t}${_t}¥¥;"

    # Comments & miscellaneous
	set M2electrics(bc)         "×kill0(*\r  ¥¥\r*)¥¥"
	set M2electrics(ec)         "×kill0 *)\r¥¥"
	set M2electrics(cc)         "×kill0(* ¥comment¥ *)¥¥"
	set M2electrics(end)        "×kill0END; ¥¥"
	set M2electrics(ret)    	"×kill0RETURN ¥¥;¥¥"


	# Procedure declarations:
	# ----------------------

	
    # For DEFINITION modules	
    
        # without formal parameters
	set M2electrics(pro)        "×kill0PROCEDURE ¥¥;¥¥"
	# with formal parameters
	set M2electrics(proa)       "×kill0PROCEDURE ¥¥(¥¥);¥¥"
	# with formal parameters and comments
	set procfirstpart           "×kill0×\[set M2tempElecVar \[M2::getName {procedure name:} {}\];return {}\]PROCEDURE \[set M2tempElecVar\] (¥argrumentsAndTypes¥);\r"
	set M2electrics(proac)      "${procfirstpart}(*\r${_t}¥¥\r*)¥¥"


    # For IMPLEMENTATION modules	
    
	# common first part
	set procfirstpart           "×kill0×\[set M2tempElecVar \[M2::getName {procedure name:} {}\];return {}\]PROCEDURE \[set M2tempElecVar\];\r"

	# simple procedure body without formal parameter list (arguments), without local vars
	set M2electrics(proc)      	"$procfirstpart\BEGIN \r${_t}¥¥\rEND \[set M2tempElecVar\];\r¥¥"
	# same as proc, but name as comment after BEGIN
	set M2electrics(procc)      "$procfirstpart\BEGIN (* \[set M2tempElecVar\] *)\r${_t}¥¥\rEND \[set M2tempElecVar\];\r¥¥"
	# procv is for a procedure without parameter list (arguments), but with
	# local vars and name as comment after BEGIN
	set M2electrics(procv)      "$procfirstpart${_t}\VAR ¥argList¥: ¥type¥\rBEGIN(* \[set M2tempElecVar\] *)\r${_t}¥¥\rEND \[set M2tempElecVar\];\r¥¥"


	# common first part
	set procfirstpart           "×kill0×\[set M2tempElecVar \[M2::getName {procedure name:} {}\];return {}\]PROCEDURE \[set M2tempElecVar\] (¥argrumentsAndTypes¥);\r"

	# proca is for a procedure with parameter list (arguments), but without
	# local vars, but with name as comment after BEGIN
	set M2electrics(proca)     	"$procfirstpart\BEGIN (* \[set M2tempElecVar\] *)\r${_t}¥¥\rEND \[set M2tempElecVar\];\r¥¥"
	# procav is for a procedure with parameter list (arguments) and with
	# local vars and name as comment after BEGIN
	set M2electrics(procav)     "$procfirstpart${_t}\VAR ¥argList¥: ¥type¥\rBEGIN (* \[set M2tempElecVar\] *)\r${_t}¥¥\rEND \[set M2tempElecVar\];\r¥¥"

	
    # I don't like the following very much, which were introduced by Juan
    # Falgueras, and think the templates offered by M2 menu offer much more
    # comfort.  E.g. they open also a window, name it correctly etc.  etc.
    set M2electrics(def)        "×kill0×\[set M2tempElecVar \[M2::getName {definition name:} {}\];return {}\]DEFINITION MODULE \[set M2tempElecVar\]¥¥;\r¥¥\r${_t}¥¥\rEND \[set M2tempElecVar\].\r"
    set M2electrics(imp)        "×kill0×\[set M2tempElecVar \[M2::getName {implementation name:} {}\];return {}\]IMPLEMENTATION MODULE \[set M2tempElecVar\]¥¥;\r¥¥\rBEGIN\r${_t}¥¥\rEND \[set M2tempElecVar\].\r"
    set M2electrics(mod)        "×kill0×\[set M2tempElecVar \[M2::getName {module name:} {}\];return {}\]MODULE \[set M2tempElecVar\];\r¥¥\rBEGIN\r${_t}¥¥\rEND \[set M2tempElecVar\].\r"

    # Do these for upper and lower case
    foreach lowerCaseElectric [array names M2electrics] {
	set M2electrics([string toupper $lowerCaseElectric]) \
	  $M2electrics($lowerCaseElectric)
    }
    
    # Set the list of commands which can be completed with partial names.
	set firstAlphaWithDictLSortV "8.0"
	if {[set M2::curAlphaV] >= $firstAlphaWithDictLSortV} {
		set M2cmds [lsort -dictionary [array names M2electrics]]
	} else {
		set M2cmds [lsort -ignore [array names M2electrics]]
	}

    status::msg "M2 Completions loaded"
    # alertnote "M2 Completions loaded"
}

# Call this now.
M2::setElectricCompletions

proc M2::getName {p defaultName} {
    if {[catch {prompt $p $defaultName} newName] || ![string length $newName]} {
	return "¥name¥"
    } else {
        return $newName
    }
}
