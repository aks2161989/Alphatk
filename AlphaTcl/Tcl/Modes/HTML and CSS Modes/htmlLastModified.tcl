## -*-Tcl-*- (tabsize:4)
 # ###################################################################
 #  HTML mode - tools for editing HTML documents
 # 
 #  FILE: "htmlLastModified.tcl"
 #                                    created: 99-07-20 23.04.50 
 #                                last update: 2005-02-21 17:51:53 
 #  Author: Johan Linde
 #  E-mail: <alpha_www_tools@go.to>
 #     www: <http://go.to/alpha_www_tools>
 #  
 # Version: 3.2
 # 
 # Copyright 1996-2004 by Johan Linde
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
# This file contains procs for updating the Last Modified date.
#===============================================================================

#===============================================================================
# ◊◊◊◊ Last modified ◊◊◊◊ #
#===============================================================================

proc html::LastModified {} {
	global HTMLmodeVars html::DateFormat 
	if {![win::checkIfWinToEdit]} {return}
	set box [dialog::title "Last modified tags" 210]
	lappend box -e $HTMLmodeVars(lastModified) 10 20 310 35 \
	  -t "Date format" 10 50 100 70 \
	  -r "Relaxed ISO" 1 10 75 110 95 -r "Strict ISO" 0 120 75 220 95 \
	  -r "Long" 0 10 100 70 120 -r "Abbreviated" 0 80 100 180 120 \
	  -r "Short" 0 190 100 250 120 \
	  -c "Include weekday" 0 10 125 150 145 -c "Include time" 0 155 125 290 145 \
	  -c "Time with seconds" 0 175 150 315 170 \
	  -t "Language:" 10 180 100 200 -m [concat [list { } { }] [lsort [array names html::DateFormat]]] \
	  110 180 290 200 -b OK 240 210 305 230 \
	  -b Cancel 155 210 220 230
	set values [eval [concat dialog -w 320 -h 240 $box]]
	if {[lindex $values 11]} {return}
	set lm [html::Quote [lindex $values 0]]
	set text "<!-- [html::SetCase "#LASTMODIFIED TEXT"]=\"$lm\" [html::SetCase FORM]=\""
	if {[lindex $values 1]} {append text [html::SetCase RELAXED]}
	if {[lindex $values 2]} {append text [html::SetCase ISO]}
	if {[lindex $values 3]} {append text [html::SetCase LONG]}
	if {[lindex $values 4]} {append text [html::SetCase ABBREV]}
	if {[lindex $values 5]} {append text [html::SetCase SHORT]}
	if {![lindex $values 1] && ![lindex $values 2] && ![lindex $values 5] && [lindex $values 6]} {append text [html::SetCase ",WEEKDAY"]}
	if {![lindex $values 2] && [lindex $values 7]} {append text [html::SetCase ",TIME"]}
	if {![lindex $values 2] && [lindex $values 7] && [lindex $values 8]} {append text [html::SetCase ",SECONDS"]}
	append text \"
	if {![lindex $values 1] && ![lindex $values 2] && [lindex $values 9] != " "} {append text " " [html::SetCase LANG=\"] [lindex $values 9] \"}
	append text "-->"
	set text "$text\r[html::GetLastMod $text]\r<!-- [html::SetCase /#LASTMODIFIED] -->"
	if {![catch {search -s -f 1 -r 1 -m 0 -i 1 {<!--[ \t\r\n]+#LASTMODIFIED[ \t\r\n]+[^>]+>} [minPos]} res] &&
	![catch {search -s -f 1 -r 1 -m 0 -i 1 {<!--[ \t\r\n]+/#LASTMODIFIED[ \t\r\n]+[^>]+>} [lindex $res 1]} res2] &&
	[askyesno "There are already 'last modified' tags in this document. Replace them?"] == "yes"} {
		elec::ReplaceText [lindex $res 0] [lindex $res2 1] $text
	} else {
		elec::Insertion [html::OpenCR 1] $text "\r\r"
	}
}

proc html::UpdateLastMod {args} {
	global HTMLmodeVars
	set name [lindex $args [expr {[llength $args] - 1}]]
	if {[lindex [winNames -f] 0] != $name} {bringToFront $name}
	set spos [minPos]
	set haswarned 0
	while {![catch {search -s -f 1 -r 1 -m 0 -i 1 {<!--[ \t\r\n]+#LASTMODIFIED[ \t\r\n]+[^>]+>} $spos} res]} {
		if {[catch {search -s -f 1 -r 1 -m 0 -i 1 {<!--[ \t\r\n]+/#LASTMODIFIED[ \t\r\n]+[^>]+>} [lindex $res 1]} res2]} {
			alertnote "The window '[file tail $name]' contains an opening 'last modified' tag without a matching closing tag."
			return
		}
		set str [html::GetLastMod [eval getText $res]]
		if {$str == "0"} {
			if {!$haswarned} {
				alertnote "The window '[file tail $name]' contains invalid 'last modified' tags."
				set haswarned 1
			}
		} else {
			set oldstr [getText [lindex $res 1] [lindex $res2 0]]
			regexp {^[\r\n\t ]*} $oldstr prenl
			regexp {[\r\n\t ]*$} $oldstr postnl
			replaceText [lindex $res 1] [lindex $res2 0] $prenl $str $postnl
		}
		set spos [lindex $res2 1]
	}
	if {!$HTMLmodeVars(updateMetaDate)} {return}
	set spos [minPos]
	while {![catch {search -s -f 1 -r 1 -m 0 -i 1 {<META[ \t\r\n]+[^<>]+>} $spos} res]} {
		html::ExtractAttrValues [eval getText $res] attrs attrVals errText
		set attrs [string toupper $attrs]
		if {[set i [lsearch -exact $attrs NAME=]] < 0 || [string toupper [lindex $attrVals $i]] != "DATE"} {set spos [lindex $res 1]; continue}
		set meta [eval getText $res]
		set date [mtime [now] iso]
		regexp {^[0-9]+-[0-9]+-[0-9]+} $date date
		if {[regsub -nocase "(CONTENT\[ \t\r\n\]*=\[ \t\r\n\]*)(\"\[^\"\]*\"|'\[^'\]+'|\[^ \t\n\r>\]+)" $meta "\\1\"$date\"" meta]} {
			replaceText [lindex $res 0] [lindex $res 1] $meta
		}
		set spos [lindex $res 1]
	}
}

proc html::GetLastMod {str} {
	global html::SpecialCharacter html::TimeFormat html::DateFormat
	set text ""
	set form ""
	set type ""
	set lang ""
	set systemlang ""
	if {![regexp -nocase {TEXT=\"([^\"]*)\"} $str dum text] ||
	![regexp -nocase {FORM=\"([^\"]*)\"} $str dum form] || $form == "" ||
	![regexp -nocase {[^,]*} $form type] || 
	[lsearch -exact [list LONG ABBREV SHORT ISO RELAXED] [set type [string toupper $type]]] < 0 ||
	([regexp -nocase {LANG=\"([^\"]*)\"} $str "" lang] && $lang == "")} {return 0}
	set lang [string tolower $lang]
	regsub -all {([ \.])([a-z])} $lang {\1[string toupper \2]} lang
	regsub {[a-z]} $lang {[string toupper &]} lang
	set lang [subst $lang]
	set text [html::UnQuote $text]
	set day [string match "*WEEKDAY*" [string toupper $form]]
	set tid [string match "*TIME*" [string toupper $form]]
	set sec [string match "*SECONDS*" [string toupper $form]]

	if {$type == "ISO" || $type == "RELAXED"} {
		if {$type == "ISO"} {
			set date [mtime [now] iso]
		} else {
			set date [mtime [now] relaxed]
			if {!$tid} {
				regexp {^[0-9]+-[0-9]+-[0-9]+} $date date
			} elseif {!$sec} {
				regsub {([0-9]+:[0-9]+):[0-9]+} $date "\\1" date
			}
		}
	} else {
		if {$lang != "" && [info exist html::TimeFormat($lang)]} {
			set longdate [mtime [now] long]
			set today [lindex [lindex $longdate 0] 0]
			set dayind 1
			if {$today == "Dé"} {
				# Gaelic
				set today [lrange [lindex $longdate 0] 0 1]
				set dayind 2
			}
			if {[regexp {^[0-9]+$} $today]} {
				# Brazilian and Portuguese
				set today ""
				set dayind 2
			}
			regexp {[a-zA-Z][^,]+} $today today
			set thismonth [lrange [lindex $longdate 0] $dayind end]
			regexp {[a-zA-Z][^,0-9]+} $thismonth thismonth
			set thismonth [string trim $thismonth]
			regexp {^(.*) de$} $thismonth "" thismonth
			foreach f [array names html::DateFormat] {
				if {[set weekday [lsearch -exact [lindex [set html::DateFormat($f)] 0] $today]] >= 0 &&
				[set month [lsearch -exact [lindex [set html::DateFormat($f)] 2] $thismonth]] >= 0} {
					set systemlang $f
					regexp {[0-9]+} [lindex $longdate 0] todaysdate
					set todaysdate [expr {$todaysdate}]
					regexp {[0-9]+$} [lindex $longdate 0] year
					break
				}
			}
		}
		if {$lang != "" && $systemlang != ""} {
			set timeformat [set html::TimeFormat($lang)]
			set dateformat [set html::DateFormat($lang)]
			if {$type == "SHORT"} {
				set date [lindex $dateformat 6]
				if {[string length $todaysdate] == 1 && [lindex $dateformat 7]} {
					set todaysdate "0$todaysdate"
				}
				regsub D $date $todaysdate date
				incr month
				if {[string length $month] == 1 && [lindex $dateformat 8]} {
					set month "0$month"
				}
				regsub M $date $month date
				if {![lindex $dateformat 9]} {
					set year [string range $year 2 3]
				}
				regsub Y $date $year date
			} else {
				set offset 0
				if {$type == "ABBREV"} {incr offset}
				set date [lindex $dateformat 4]
				regsub Y $date $year date
				if {[string length $todaysdate] == 1 && [lindex $dateformat 5]} {
					set todaysdate "0$todaysdate"
				}
				regsub D $date $todaysdate date
				regsub M $date [lindex [lindex $dateformat [expr {2 + $offset}]] $month] date
				if {$day && $today != ""} {
					regsub W $date [lindex [lindex $dateformat $offset] $weekday] date 
				} else {
					regsub {W[, ]+} $date "" date
				}
			}
			if {$tid} {
				set tiden [lindex $longdate 1]
				regexp {^([0-9]+)[^0-9]+([0-9]+)[^0-9]+([0-9]+)} $tiden "" hour minute seconds
				set hour [expr {$hour}]
				set isAM [regexp {[aA][mM]} $tiden]
				set is12 [regexp {[aApP][mM]} $tiden]
				if {$is12} {
					if {$isAM && $hour == 12} {set hour 0}
					if {!$isAM && $hour < 12} {incr hour 12}
				}
				set hour24 $hour
				if {![lindex $timeformat 0]} {
					if {$hour == 0} {set hour 12}
					if {$hour > 12} {incr hour -12}
				}
				if {[string length $hour] == 1 && [lindex $timeformat 4]} {
					set hour "0$hour"
				}
				append date " " $hour [lindex $timeformat 3] $minute
				if {$sec} {append date [lindex $timeformat 3] $seconds}
				if {$hour24 < 12} {
					append date [lindex $timeformat 1]
				} else {
					append date [lindex $timeformat 2]
				}
			}
		} else {
			set date [mtime [now] [string tolower $type]]
			if {!$day && $type != "SHORT" && ![regexp {^[0-9]} [lindex $date 0]]} {
				set date [lreplace $date 0 0 [lrange [lindex $date 0] 1 end]]
			}
			if {!$tid} {
				set date [lindex $date 0]
			} elseif {!$sec} {
				set tiden [lindex $date 1]
				regexp {^[0-9]+[^0-9]+[0-9]+} $tiden tidstr
				set tiden [lreplace $tiden 0 0 $tidstr]
				set date [lreplace $date 1 1 $tiden]
			}
			set date [join $date]
			# Work around Y2K bug for Swedish system
			if {$type == "SHORT" && [regexp {^[0-9]-} $date]} {
				set date "0$date"
			}
		}
	}
	if {[string length $text]} {
		append text " " $date
	} else {
		set text $date
	}
	regsub -all "&" $text "\\&amp;" text
	regsub -all "<" $text "\\&lt;" text
	regsub -all ">" $text "\\&gt;" text
	foreach c [array names html::SpecialCharacter] {
		catch {regsub -all $c $text "\\&[set html::SpecialCharacter($c)];" text}
	}

	return $text
}

# Time format
# The items in the arrays are:
# 24 hour clock (true/false)
# am string
# pm string 
# separator
# opening zero for hour (true/false)
set html::TimeFormat(Australian) {0 " AM" " PM" : 0}
set html::TimeFormat(Austrian) {1 " Uhr" " Uhr" : 0}
set html::TimeFormat(Brazilian) {1 "" "" : 1}
set html::TimeFormat(British) {0 " am" " pm" : 0}
set "html::TimeFormat(Canadian French)" {1 "" "" : 1}
set html::TimeFormat(Catalan) {1 "" "" : 1}
set html::TimeFormat(Danish) {1 "" "" : 0}
set html::TimeFormat(Dutch) {1 "" "" : 1}
set html::TimeFormat(Finnish) {1 "" "" : 1}
set html::TimeFormat(Flemish) {1 "" "" : 1}
set html::TimeFormat(French) {1 "" "" : 0}
set html::TimeFormat(German) {1 " Uhr" " Uhr" : 0}
set "html::TimeFormat(Irish English)" {1 "" "" : 1}
set "html::TimeFormat(Irish Gaelic)" {1 "" "" : 1}
set html::TimeFormat(Italian) {1 "" "" : 0}
set html::TimeFormat(Norwegian) {1 "" "" : 1}
set html::TimeFormat(Portuguese) {1 "" "" : 0}
set html::TimeFormat(Spanish) {1 "" "" : 1}
set html::TimeFormat(Swedish) {1 "" "" . 1}
set "html::TimeFormat(Swiss French)" {1 "" "" : 0}
set "html::TimeFormat(Swiss German)" {1 " Uhr" " Uhr" : 0}
set "html::TimeFormat(Swiss Italian)" {1 "" "" : 0}
set html::TimeFormat(U.S.) {0 " AM" " PM" : 0}

# Date format 
# The items in the arrays are:
# long weekdays
# short weekdays
# long months
# short months
# long date format
# opening zero for day in long format (true/false)
# short format
# opening zero for day in short format (true/false)
# opening zero for month in short format (true/false)
# show century in short format (true/false)
set html::DateFormat(Australian) {
	{Monday Tuesday Wednesday Thursday Friday Saturday Sunday}
	{Mon Tue Wed Thu Fri Sat Sun}
	{January February March April May June July August September October November December}
	{Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec}
	{W, D M Y} 0 {D/M/Y} 0 0 0
}

set html::DateFormat(Austrian) {
	{Montag Dienstag Mittwoch Donnerstag Freitag Samstag Sonntag}
	{Mon Die Mit Don Fre Sam Son}
	{Jänner Februar März April Mai Juni Juli August September Oktober November Dezember}
	{Jän Feb Mär Apr Mai Jun Jul Aug Sep Okt Nov Dez}
	{W, D. M Y} 0 {D.M.Y} 1 1 1
}

set html::DateFormat(Brazilian) {
	{"" "" "" "" "" "" ""}
	{"" "" "" "" "" "" ""}
	{janeiro fevereiro março abril maio junho julho agosto setembro outubro novembro dezembro}
	{jan fev mar abr mai jun jul ago set out nov dez}
	{D de M de Y} 1 {D.M.Y} 1 1 0
}

set html::DateFormat(British) {
	{Monday Tuesday Wednesday Thursday Friday Saturday Sunday}
	{Mon Tue Wed Thu Fri Sat Sun}
	{January February March April May June July August September October November December}
	{Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec}
	{W, M D, Y} 0 {D/M/Y} 0 0 0
}

set "html::DateFormat(Canadian French)" {
	{Lundi Mardi Mercredi Jeudi Vendredi Samedi Dimanche}
	{Lund Mard Merc Jeud Vend Same Dima}
	{janvier février mars avril mai juin juillet août septembre octobre novembre décembre}
	{janv févr mars avri mai juin juil août sept octo nove déce}
	{W D M Y} 1 {D/M/Y} 1 1 0
}

set html::DateFormat(Catalan) {
	{dilluns dimarts dimecres dijous divendres dissabte diumenge}
	{dill dima dime dij div diss dium}
	{gener febrer març abril maig juny juliol agost setembre octubre novembre desembre}
	{gen feb mar abr mai jun jul ago set oct nov dec}
	{W, D M Y} 0 {D/M/Y} 0 0 0
}

set html::DateFormat(Danish) {
	{mandag tirsdag onsdag torsdag fredag lørdag søndag}
	{man tir ons tor fre lør søn}
	{januar februar marts april maj juni juli august september oktober november december}
	{jan feb mar apr maj jun jul aug sep okt nov dec}
	{W D. M Y} 0 {D/M/Y} 1 1 0
}

set html::DateFormat(Dutch) {
	{maandag dinsdag woensdag donderdag vrijdag zaterdag zondag}
	{maa din woe don vri zat zon}
	{januari februari maart april mei juni juli augustus september oktober november december}
	{jan feb maa apr mei jun jul aug sep okt nov dec}
	{W, D M Y} 0 {D-M-Y} 1 1 1
}

set html::DateFormat(Finnish) {
	{maanantai tiistai keskiviikko torstai perjantai lauantai sunnuntai}
	{ma ti ke to pe la su}
	{tammikuu helmikuu maaliskuu huhtikuu toukokuu kesäkuu heinäkuu elokuu syyskuu lokakuu marraskuu joulukuu}
	{tammi helmi maalis huhti touko kesä heinä elo syys loka marras joulu}
	{W D. M Y} 0 {D.M.Y.} 0 0 1
}

set html::DateFormat(Flemish) {
	{maandag dinsdag woensdag donderdag vrijdag zaterdag zondag}
	{maa din woe don vri zat zon}
	{januari februari maart april mei juni juli augustus september oktober november december}
	{jan feb maa apr mei jun jul aug sep okt nov dec}
	{W, D M Y} 0 {D-M-Y} 1 1 1
}

set html::DateFormat(French) {
	{lundi mardi mercredi jeudi vendredi samedi dimanche}
	{Lun Mar Mer Jeu Ven Sam Dim}
	{janvier février mars avril mai juin juillet août septembre octobre novembre décembre}
	{jan fév mars avr mai juin juil aoû sep oct nov déc}
	{W D M Y} 0 {D/M/Y} 0 1 0
}

set html::DateFormat(German) {
	{Montag Dienstag Mittwoch Donnerstag Freitag Samstag Sonntag}
	{Mo Di Mi Do Fr Sa So}
	{Januar Februar März April Mai Juni Juli August September Oktober November Dezember}
	{Jan Feb Mär Apr Mai Jun Jul Aug Sep Okt Nov Dez}
	{W, D. M Y} 0 {D.M.Y} 1 1 1
}

set "html::DateFormat(Irish English)" {
	{Monday Tuesday Wednesday Thursday Friday Saturday Sunday}
	{Mon Tue Wed Thu Fri Sat Sun}
	{January February March April May June July August September October November December}
	{Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec}
	{W D M Y} 0 {D/M/Y} 1 1 1
}

set "html::DateFormat(Irish Gaelic)" {
	{"Dé Luain" "Dé Máirt" "Dé Céadaoin" Déardaoin "Dé hAoine" "Dé Sathairn" "Dé Domhnaigh"}
	{Luan Máir Céad Déar Aoin Sath Domh}
	{Eanáir Feabhra Márta Aibreán Bealtaine Meitheamh Iúil Lúnasa "Meán Fómhair" "D. Fómhair" Samhain Nollaig}
	{Ean Feabh Már Aib Beal Meith Iúil Lún MFómh DFómh Samh Noll}
	{W D M Y} 0 {D/M/Y} 1 1 1
}

set html::DateFormat(Italian) {
	{Lunedì Martedì Mercoledì Giovedì Venerdì Sabato Domenica}
	{Lun Mar Mer Gio Ven Sab Dom}
	{gennaio febbraio marzo aprile maggio giugno luglio agosto settembre ottobre novembre dicembre}
	{gen feb mar apr mag giu lug ago set ott nov dic}
	{W, D M Y} 0 {D-M-Y} 0 1 1
}

set html::DateFormat(Norwegian) {
	{mandag tirsdag onsdag torsdag fredag lørdag søndag}
	{man tir ons tor fre lør søn}
	{januar februar mars april mai juni juli august september oktober november desember}
	{jan feb mar apr mai jun jul aug sep okt nov des}
	{W D. M Y} 0 {D-M-Y} 1 1 0
}

set html::DateFormat(Portuguese) {
	{"" "" "" "" "" "" ""}
	{"" "" "" "" "" "" ""}
	{Janeiro Fevereiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro}
	{Jan Fev Mar Abr Mai Jun Jul Ago Set Out Nov Dez}
	{D de M de Y} 0 {D/M/Y} 1 1 0
}

set html::DateFormat(Spanish) {
	{lunes martes miércoles jueves viernes sábado domingo}
	{lun. mart. miér. juev. vier. sáb. dom.}
	{enero febrero marzo abril mayo junio julio agosto septiembre octubre noviembre diciembre}
	{ener febr marz abri mayo juni juli agos sept octu novi dici}
	{W, D M Y} 0 {D/M/Y} 0 0 0
}

set html::DateFormat(Swedish) {
	{måndag tisdag onsdag torsdag fredag lördag söndag}
	{mån tis ons tor fre lör sön}
	{januari februari mars april maj juni juli augusti september oktober november december}
	{jan feb mar apr maj jun jul aug sep okt nov dec}
	{W D M Y} 0 {Y-M-D} 1 1 0
}

set "html::DateFormat(Swiss French)" {
	{Lundi Mardi Mercredi Jeudi Vendredi Samedi Dimanche}
	{Lun Mar Mec Jeu Ven Sam Dim}
	{janvier février mars avril mai juin juillet août septembre octobre novembre décembre}
	{jan fév mars avr mai juin juil aoû sep oct nov déc}
	{W, D M Y} 0 {D.M.Y} 0 0 1
}

set "html::DateFormat(Swiss German)" {
	{Montag Dienstag Mittwoch Donnerstag Freitag Samstag Sonntag}
	{Mon Die Mit Don Fre Sam Son}
	{Januar Februar März April Mai Juni Juli August September Oktober November Dezember}
	{Jan Feb Mär Apr Mai Jun Jul Aug Sept Okt Nov Dez}
	{W, D. M Y} 0 {D.M.Y} 0 0 1
}

set "html::DateFormat(Swiss Italian)" {
	{Lunedì Martedì Mercoledì Giovedì Venerdì Sabato Domenica}
	{Lun Mar Mer Gio Ven Sab Dom}
	{gennaio febbraio marzo aprile maggio giugno luglio agosto settembre ottobre novembre dicembre}
	{gen feb mar apr mag giu lug ago set ott nov dic}
	{W, D M Y} 0 {D.M.Y} 0 0 1
}

set html::DateFormat(U.S.) {
	{Monday Tuesday Wednesday Thursday Friday Saturday Sunday}
	{Mon Tue Wed Thu Fri Sat Sun}
	{January February March April May June July August September October November December}
	{Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec}
	{W, M D, Y} 0 {M/D/Y} 0 0 0
}
