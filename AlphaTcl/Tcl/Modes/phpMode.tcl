# File: "phpMode.tcl"
#                        Created: 2001-05-07 23:18:27
#              Last modification: 2006-05-04 11:29:59
# Author: Bernard Desgraupes
# e-mail: <bdesgraupes@easyconnect.fr>
# Web page: <http://webperso.easyconnect.fr/bdesgraupes/alpha.html>
# Description: basic stuff for a PHP mode (syntax coloring, comments, basic
# file marking of functions)


alpha::mode PHP 0.1.2 dummyPHP {*.php } {
} {
    # Script to execute at Alpha startup
} uninstall {
    this-file
} maintainer {
} description {
    Supports the editing of PHP programming files
} help {
    file "PHP Mode Help"
}

namespace eval PHP {}

# Preferences
# -----------
newPref v leftFillColumn {3} PHP
newPref v prefixString {# } PHP 
newPref v wordBreak {(\$)?[\w:_]+} PHP
newPref var lineWrap {0} PHP
newPref v funcExpr {^[ \t]*function[ \t]+\&?([A-Za-z][A-Za-z0-9_]*)} PHP
# newPref v parseExpr {^[ \t]*[^ \t]+[ \t]+\&?([A-Za-z][A-Za-z0-9_]*)} PHP
newPref v parseExpr {function[ \t]+\&?([a-zA-Z0-9_]+)} PHP

# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn 0 PHP
# To automatically perform context relevant formatting after typing a left
# or right curly brace, turn this item on||To have the brace keys produce a
# brace without additional formatting, turn this item off
newPref flag electricBraces    1 PHP
# To automatically perform context relevant formatting after typing a
# semicolon, turn this item on||To have the semicolon key produce a
# semicolon without additional formatting, turn this item off
newPref flag electricSemicolon 1 PHP
# Default colo(u)rs for the keywords
newPref v commentColor red PHP
newPref v keywordColor blue PHP
newPref v stringColor green PHP
newPref v phpDelimsColor magenta PHP

# Initialisation
# --------------
set PHP::commentCharacters(General) "#"
set PHP::commentCharacters(Paragraph) [list "/* " " */" " * "]
set PHP::commentCharacters(Box) [list "/*" 2 "*/" 2 "*" 3]

proc dummyPHP {} {}


# Syntax coloring
# ---------------
set PHPKeyWords	{
__FILE__ __LINE__ abs acos add addcolor addcslashes addentry addfill addshape
addslashes addstring align and array arsort ascii2ebcdic asin asort assert
atan atan2 basename bcadd bccomp bcdiv bcmod bcmul bcpow bcscale bcsqrt bcsub
bin2hex bind bindec bindtextdomain break bzclose bzcompress bzdecompress bzerrno
bzerror bzerrstr bzflush bzopen bzread bzwrite case ceil chdir checkdate
checkdnsrr chgrp chmod chop chown chr chroot class clearstatcache close
closedir closelog compact connect continue copy cos count crc32 crypt current
date dblist dbmclose dbmdelete dbmexists dbmfetch dbmfirstkey dbminsert dbmnextkey
dbmopen dbmreplace dcgettext decbin dechex decoct default define defined deg2rad
delete dgettext die dir dirname diskfreespace dl do doubleval drawcurve drawcurveto
drawline drawlineto E_ALL E_ERROR E_PARSE E_WARNING each ebcdic2ascii echo
else elseif empty end endfor endif endswitch endwhile ereg eregi escapeshellarg
escapeshellcmd eval exec exit exp explode extends extract FALSE fclose feof fflush
fgetc fgetcsv fgets fgetss file fileatime filectime filegroup fileinode filemtime
fileowner fileperms filepro filesize filetype flock floor flush fopen for foreach
fpassthru fputs fread frenchtojd fscanf fseek fsockopen fstat ftell ftruncate
function fwrite getallheaders getcwd getdate getenv getheight gethostbyaddr
gethostbyname gethostbynamel getimagesize getlastmod getmxrr getmyinode
getmypid getmyuid getprotobyname getprotobynumber getrandmax getrusage
getservbyname getservbyport getshape1 getshape2 gettext gettimeofday gettype
getwidth global gmdate gmmktime gmstrftime gregoriantojd gzclose gzcompress
gzdeflate gzencode gzeof gzfile gzgetc gzgets gzgetss gzinflate gzopen gzpassthru
gzputs gzread gzrewind gzseek gztell gzuncompress gzwrite header hebrev hebrevc
hexdec htmlentities htmlspecialchars HTTP_COOKIE_VARS HTTP_ENV_VARS HTTP_GET_VARS
HTTP_POST_FILES HTTP_POST_VARS HTTP_SERVER_VARS if imagearc imagechar imagecharup
imagecolorallocate imagecolorat imagecolorclosest imagecolordeallocate imagecolorexact
imagecolorresolve imagecolorset imagecolorsforindex imagecolorstotal imagecolortransparent
imagecopy imagecopyresized imagecreate imagecreatefromgif imagecreatefromjpeg
imagecreatefrompng imagecreatefromstring imagecreatefromwbmp imagedashedline
imagedestroy imagefill imagefilledpolygon imagefilledrectangle imagefilltoborder
imagefontheight imagefontwidth imagegammacorrect imagegif imageinterlace imagejpeg
imageline imageloadfont imagepng imagepolygon imagepsbbox imagepsencodefont imagepsextendfont
imagepsfreefont imagepsloadfont imagepsslantfont imagepstext imagerectangle imagesetpixel
imagestring imagestringup imagesx imagesy imagettfbbox imagettftext imagetypes imagewbmp
implode include include_once intval ip2long iptcparse isset jddayofweek jdmonthname
jdtofrench jdtogregorian jdtojewish jdtojulian jdtounix jewishtojd join juliantojd
key krsort ksort leak levenshtein link linkinfo list listen localeconv localtime
log log10 long2ip lstat ltrim mail max md5 metaphone mhash microtime min mkdir
mktime move movepen movepento moveto msql multcolor natcasesort natsort new
next nextframe nl2br not ocibindbyname ocicolumnisnull ocicolumnname ocicolumnsize
ocicolumntype ocicommit ocidefinebyname ocierror ociexecute ocifetch ocifetchinto
ocifetchstatement ocifreecursor ocifreedesc ocifreestatement ociinternaldebug ocilogoff
ocilogon ocinewcursor ocinewdescriptor ocinlogon ocinumcols ociparse ociplogon ociresult
ocirollback ocirowcount ociserverversion ocistatementtype octdec opendir openlog
or orbitenum orbitobject orbitstruct ord output pack passthru pclose pfsockopen PHP_OS
PHP_SELF PHP_VERSION phpcredits phpinfo phpversion pi popen pos pow prev print printf
putenv quotemeta rad2deg rand range rawurldecode rawurlencode read readdir readfile
readgzfile readline readlink realpath recode remove rename require require_once
reset return rewind rewinddir rmdir rotate rotateto round rsort rtrim save scale
scaleto serialize setAction setbackground setbounds setcolor setcookie setdepth
setdimension setfont setframes setheight sethit setindentation setleftfill setleftmargin
setline setlinespacing setlocale setmargins setname setover setrate setratio
setrightfill setrightmargin setspacing settype setup shuffle sin sizeof skewx
skewxto skewy skewyto sleep snmpget snmpset snmpwalk snmpwalkoid socket sort soundex
split spliti sprintf sqrt srand sscanf stat static strcasecmp strchr strcmp strcoll
strcspn streammp3 strerror strftime stripcslashes stripslashes stristr strlen strnatcasecmp
strnatcmp strncasecmp strncmp strpos strrchr strrev strrpos strspn strstr strtok
strtolower strtotime strtoupper strtr strval substr swfaction swfbitmap swfbutton swfdisplayitem
swffill swffont swfgradient swfmorph swfmovie swfshape swfsprite swftext swftextfield
switch symlink syslog system tan tempnam textdomain this time tmpfile touch trim
TRUE uasort ucfirst ucwords uksort umask uniqid unixtojd unlink unpack unserialize
unset urldecode urlencode usleep usort var virtual while wordwrap write xmldoc
xmldocfile xmltree xor 
}

regModeKeywords -C PHP {}
regModeKeywords -a -e {#} -b {/*} {*/} -c $PHPmodeVars(commentColor) \
  -k $PHPmodeVars(keywordColor)  -s $PHPmodeVars(stringColor) PHP $PHPKeyWords

set phpDelimsKeyWords { 
<?php ?> 
}

regModeKeywords -a -k $PHPmodeVars(phpDelimsColor) PHP $phpDelimsKeyWords
unset phpDelimsKeyWords

# Completions
# -----------

set completions(PHP) {completion::cmd completion::electric}
set PHPcmds $PHPKeyWords
unset PHPKeyWords

# Conditionals
# ------------
set PHPelectrics(if)   " (¥expr¥) \{\n\t¥cmd¥\n\t\}"
set PHPelectrics(ifelse)   "×kill0if (¥expr¥) \{\n\t¥cmd¥\n\t\} else \{\n\t¥cmd¥\n\t\}"
set PHPelectrics(ifelseif)   "×kill0if (¥expr¥) \{\n\t¥cmd¥\n\t\} elseif (¥expr¥) \{\n\t¥expr¥\n\t\} else \{\n\t¥cmd¥\n\t\}"
set PHPelectrics(elseif)   " (¥expr¥) \{\n\t¥¥\n\t\} else \{\n\t¥cmd¥\n\t\}"
set PHPelectrics(while)   " (¥¥) \{\n\t¥¥\n\t\}"
set PHPelectrics(do)   " \{\n\t¥¥\n\t\} while (¥¥);"
set PHPelectrics(for)  " (¥¥; ¥¥; ¥¥) \{\n\t¥cmd¥\n\t\}"
set PHPelectrics(foreach)   " (¥¥ as ¥¥) \{\n\t¥cmd¥\n\t\}"
set PHPelectrics(foreachkey)   "×kill0foreach (¥¥ as ¥¥ => ¥¥) \{\n\t¥cmd¥\n\t\}"
set PHPelectrics(switch)   " (¥¥) \{\n\t  case ¥¥:\n\t\t¥¥\n\t  default:\n\t\t¥¥\n\t\}"
set PHPelectrics(php)   "×kill0<?php\n\t¥¥\n?>"
set PHPelectrics(function)    " ¥name¥ (¥args¥) \{\n\t¥body¥\n\}"

# File marking
# ------------
proc PHP::MarkFile {args} {
	win::parseArgs win
	
	global PHPmodeVars
	set pos [minPos]
	
	while {![catch {search -w $win -s -f 1 -r 1 -m 0 -i 1 $PHPmodeVars(funcExpr) $pos} res]} {
		set start [lindex $res 0]
		set end [pos::math -w $win [lindex $res 1] + 1]
		set text [getText -w $win $start $end]
		
		if {[regexp -nocase -indices $PHPmodeVars(parseExpr) $text dummy pname]} {
			set	i1 [pos::math -w $win $start + [lindex $pname 0]]
			set	i2 [pos::math -w $win $start + [lindex $pname 1] + 1]
			set	word [getText -w $win $i1 $i2]
			set	tmp [list $i1 $i2]
			
			if {[info exists cnts($word)]} {
				# This section handles duplicate. i.e., overloaded names
				incr cnts($word)
				set ol_word [join [concat $word "#" $cnts($word)] ""]
				set inds($ol_word) $tmp
			} else {
				set cnts($word) 1
				set inds($word) $tmp
			}
		}
		
		set pos $end
	}
	if {[info exists inds]} {
		foreach f [lsort -dictionary [array names inds]] {
			set res $inds($f)
			setNamedMark -w $win $f [lineStart -w $win [lindex $res 0]] [lindex $res 0] [lindex $res 1]
		}
	}
}


proc PHP::correctIndentation {args} {eval C++::correctIndentation $args}


proc PHP::parseFuncs {} {
	set pos [minPos]
	set result ""
	set inclExpr {(include|require)(_once)? *\( *[\"']([^\"']+)[\"'] *\) *;}

	while {![catch {search -s -f 1 -r 1 -i 0 $inclExpr $pos} res]} {
		set txt [eval getText $res]
		if {[regexp -- $inclExpr $txt -> cmd suff path]} {
			if {[info exists thelist($cmd$suff)]} {
				lappend thelist($cmd$suff) [list "  $path" [lindex $res 0]]
			} else {
				set thelist($cmd$suff) [list [list "  $path" [lindex $res 0]]]
			}
		}
		set pos [lindex $res 1]
	}
	
	foreach type [array names thelist] {
		lappend result "¥¥ $type ¥¥" $type
			foreach pair [lsort -dictionary [set thelist($type)]] {
				lappend result [lindex $pair 0] [lindex $pair 1]
			}
	} 
	return $result
}


