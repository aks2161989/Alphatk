## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # AlphaTcl extension packages
 #
 # FILE: "shScriptsMode.tcl"
 #                                          created: 02/02/2000 {07:07:26 pm}
 #                                      last update: 03/21/2006 {03:26:22 PM}
 # Description: 
 # 
 # For Unix, Linux, or OS X environment shell scripts.
 #                                
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # Copyright (c) 2000-2006  Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

# ===========================================================================
#
# ×××× Initialization of sh mode ×××× #
# 

alpha::mode [list sh "Shell Scripts"] 2.0 "shScriptsMode.tcl" {
    *.csh *.tcsh *.sh
} {
    shScriptsMenu
} {
    # Script to execute at Alpha startup
    addMenu shScriptsMenu "sh" sh
    set unixMode(csh)  {sh}
    set unixMode(tcsh) {sh}
    set unixMode(sh)   {sh}
} uninstall {
    catch {file delete [file join $HOME Tcl Modes shScriptsMode.tcl]}
    catch {file delete [file join $HOME Tcl Completions shCompletions.tcl]}
    catch {file delete [file join $HOME Tcl Completions "sh Tutorial.sh"]}
    catch {file delete [file join $HOME Help "sh Scripts Help"]}
} maintainer {
    "Craig Barton Upright" <cupright@alumni.princeton.edu>
    <http://www.purl.org/net/cbu>
} description {
    Supports the editing of sh, tcsh, etc. script files
} help {
    file "sh Scripts Help"
}

proc shScriptsMode.tcl {} {}

namespace eval sh {
    
    # Comment Character variables for Comment Line/Paragraph/Box menu items.
    variable commentCharacters
    array set commentCharacters [list \
      "General"         [list "#"] \
      "Paragraph"       [list "## " " ##" " # "] \
      "Box"             [list "#" 2 "#" 2 "#" 3] \
      ]
    variable quotedstringChar "`"
    variable lineContinuationChar "\\"
    variable paragraphName   "block"
    
    # Create a list of toggleable preferences for the menu.
    variable prefsInMenu [list \
      helpFindsManPage (-) navigateBlocks \
      markHeadersOnly autoMark (-) /t<BshModeHelp ]
    
    # =======================================================================
    #
    # ×××× Keyword Dictionaries ×××× #
    #
    
    # =======================================================================
    #
    # sh commands
    #
    # Based on ls -1 /usr/bin/
    #
    set keywordLists(commands) [list \
      acctcom adb addbib admintool alias aliasadm apm appletviewer apropos \
      arch asa at atq atrm audioconvert audioplay audiorecord awk banner \
      basename batch bc bdiff bfs bg break cachefspack cachefsstat cal \
      calendar cancel captoinfo case cat catman cd checkeq checknr chgrp \
      chkey chmod chown chrtbl ckdate ckgid ckint ckitem ckkeywd ckpath \
      ckrange ckstr cksum cktime ckuid ckyorn clear cmp col colltbl comm \
      command compress continue coreadm cp cpio crontab crypt csh csplit \
      ctags cut daps date dc dd deroff devattr devfree devreserv df diff \
      diff3 diffmk dircmp dirname disable dispgid dispuid dmesg domainname \
      dos2unix dsm dsm.opt dsm.sys dsmadmc dsmc du dumpcs dumpkeys echo ed \
      edit egrep eject enable env eqn ex expand expr exstr factor false fc \
      fdetach fdformat fg fgrep file filesync find finger fmli fmt fmtmsg \
      fnattr fnbind fncreate_printer fnlist fnlookup fnrename fnsearch \
      fnunbind fold ftp gcore gencat genmsg getconf getdev getdgrp getent \
      getfacl getopt getopts gettext gettxt getvol graph grep groups hash \
      head hostid hostname i286 i386 i486 i860 i86pc iAPX286 iconv id if \
      indxbib infocmp iostat ipcrm ipcs isainfo isalist jar java java_g \
      javac javadoc javah javakey javald javap javaverify jdb jobs join jre \
      jsh k4destroy k4init k4list kbd kbdcomp keylogin keylogout kgmon kill \
      ksh ksrvtgt last lastcomm ldapadd ldapdelete ldapmodify ldapmodrdn \
      ldapsearch ldd line listdgrp listusers ln loadkeys locale localedef \
      logger login logins logname look lookbib lp lpget lpset lpstat ls \
      m68k mach mail mailcompat mailq mailstats mailx makedev man mc68000 \
      mc68010 mc68020 mc68030 mc68040 mconnect mesg mkdir mkfifo mkmsgs \
      montbl more mpstat msgfmt mt mv native2ascii nawk neqn netstat \
      newaliases newform newgrp news nfsstat nice nisaddcred niscat \
      nischgrp nischmod nischown nischttl nisdefaults niserror nisgrep \
      nisgrpadm nisln nisls nismatch nismkdir nispasswd nispath nisprefadm \
      nisrm nisrmdir nistbladm nistest nl nohup nroff oawk od on optisa \
      pack page pagesize passmgmt passwd passwd.sun paste patch pathchk pax \
      pcat pdp11 pg pgrep pkginfo pkgmk pkgparam pkgproto pkgtrans pkill \
      plimit pr prex printf priocntl ps putdev putdgrp pvs pwconv pwd rcp \
      rdate rdist read red refer remsh renice rksh rlogin rm rmail rmdir \
      rmic rmiregistry roffbib rpcgen rpcinfo rsh rstartd rup ruptime \
      rusers rwho sag sar savecore script sdiff sed select serialver \
      setfacl setpgrp settime setuname sh showrev sleep soelim solstice \
      sort sortbib sotruss sparc sparcv7 sparcv9 spell spline split srchtxt \
      strace strchg strclean strconf strerr strings stty su sum sun sun2 \
      sun3 sun3x sun4 sun4c sun4d sun4e sun4m switch sync ta tabs tail talk \
      tar tbl tcopy tee telnet test tftp tic time timex tip tnfdump \
      tnfxtract touch tplot tput tr troff true truss tty type u370 u3b \
      u3b15 u3b2 u3b5 ul ulimit umask unalias uname uncompress unexpand \
      uniq units unix2dos unpack unzip uptime uudecode uuencode vacation \
      vax vedit vgrind vi view vmstat volcheck volrmmount vsig w wait wc \
      wchrtbl whatis which who whocalls whois write xargs xgettext xstr \
      ypcat ypmatch yppasswd ypwhich zcat zipinfo \
      ]
    
    # These next are primarily associated with some of the commands above.  They
    # might be redirected in sh::wwwCommandHelp.
    
    variable shCommandsRedirect
    array set shCommandsRedirect {
	"do"          "while"
	"done"        "while"
	"elif"        "if"
	"else"        "if"
	"end"         "end"
	"END"         "end"
	"etext"       "end"
	"edata"       "end"
	"fi"          "if"
	"then"        "if"
    }
    
    append keywordLists(commands) [array names shCommandsRedirect]
    
    # =======================================================================
    #
    # Programs
    # 
    # based on ls -1 /usr/princeton/bin    
    #
    set keywordLists(programs) [list \
      _temp_.err _temp_.out a2p AcroRead acroread acroread.jw addftinfo \
      addr afmtodit agrep ampl amslatex amstex anytopnm archie asciitopgm \
      atktopbm autopasswd b2m bash bdftops bibtex bioradtopgm bison \
      bmptoppm bookline bprint brushtopbm buildhash bwish c++ c++.5.3 \
      c++.5.4 c10 c2ph cgi-bin chkmail chsh ci cjpeg cmmf cmuwmtopbm co \
      conferencing cplex cppstdin cso cthes db_archive db_checkpoint \
      db_deadlock db_dump db_load db_printlog db_recover db_stat dbms \
      dbmscopy dbmscopy.511 dbmsnox dbmsnox.511 depot \
      depot_getcollectioninfo des dig dired dislocate djpeg dnsquery dpwish \
      dvicopy dvips dvitype elm elm.d emacs emacs-19.19 emacs-19.28 \
      emacsclient enscript epsffit etags etex exng expect expect5 expectk5 \
      fax fax.990122 fax2ps fax2tiff find2perl findaffix fitstopgm \
      fitstopnm fixfmps fixmacps fixpsditps fixpspps fixtpps fixwfwps \
      fixwpps fixwwps flex flex++ font2c FontNotify.sh frn fsi_generate \
      fstopgm ftp-rfc g++ g++.5.3 g++.5.4 g3topbm gawk gcc gcc-2.6.2 gdb \
      gemtopbm genclass geqn getafm getindex gftodvi gftopk gftype gif2tiff \
      giftopnm giftoppm giftrans gindxbib glib-config glimpse glimpseindex \
      glimpseserver glookbib gmake gmake.981218 gneqn gnroff gnudiff \
      gnuplot gnuplot_x11 gouldtoppm gperf gpic grap grefer grodvi groff \
      grog grops grotty gs gsoelim gsz gtar gtbl gtk-config gtroff gzexe \
      h2ph hintservice hipstopgm host host.old hostinfo hostinfo.980904 \
      hostinfo.980917 hpcdtoppm icombine icontopbm ident ident-scan ifrom \
      ijoin ilbmtoppm ilp imgtoppm inews info inimf initex inrstex ispell \
      jgraph jpegtran jws k4passwd k4rcp k4rlogin k4rsh k4wrapper k5wrapper \
      kdestroy kermit kftp kibitz kinit klist kman knit kpasswd kpsewhich \
      krcp krlogin krsh ksu ktelnet lasergnu latex lcc less less.hlp \
      lesskey lispmtopgm lkbib lpunlock lslk lsof lsof.971211 lsof.980624 \
      lsof.save lynx lynx.991026 m2ncvt macptopbm make-ssh-known-hosts \
      make-ssh-known-hosts.old make-ssh-known-hosts1 \
      make-ssh-known-hosts1.old makeinfo maker MakeTeXPK maple maple4 \
      maple6 mapleV-4.0a math math.223 math.30 mathematica mathematica.223 \
      mathematica.30 mathremote matlab matlab.test matlab4 matlab5 mcd \
      mcopy med Medical merge metamail metamail-2.7 mf mft mgrtopbm mh \
      mh-6.8.3 mh-6.8.4 mread msgs mtvtoppm mtype munchlist mush mush-7.2.5 \
      mush-7.2.5b mush.new mweb mwebhelp.txt ncdump ncftp ncgen nessus \
      nessusd newsetup newsgroups nexpect nntplist npasswd nslookup \
      nslookup.old nslshowddb nslwhere nsquery nstest nx11start omnimark \
      pal2rgb passmass patgen pbmcatlr pbmcattb pbmclean pbmcompat pbmcrop \
      pbmcut pbmenlarge pbmfliplr pbmfliptb pbmlife pbmmake pbmmask \
      pbmpaste pbmpscale pbmreduce pbmtext pbmto10x pbmto4425 pbmtoascii \
      pbmtoatk pbmtobbnbg pbmtocmuwm pbmtoepsi pbmtoepson pbmtog3 pbmtogem \
      pbmtogo pbmtoicon pbmtolj pbmtoln03 pbmtolps pbmtomacp pbmtomgr \
      pbmtopgm pbmtopi3 pbmtopk pbmtoplot pbmtops pbmtoptx pbmtorast \
      pbmtox10bm pbmtoxbm pbmtoxwd pbmtoybm pbmtozinc pbmtrnspos pbmupc \
      pcxtopbm pcxtoppm perl perl4 perl5 pesis pfbtops pgmbentley pgmcrater \
      pgmedge pgmenhance pgmhist pgmkernel pgmnoise pgmnorm pgmoil pgmramp \
      pgmtexture pgmtofits pgmtofs pgmtolispm pgmtopbm pgmtoppm pgmtops pgp \
      pgp-2.6.2 ph pi1toppm pi3topbm pico pico.396 pico.4.03 picttopbm \
      picttoppm pilot pilot.4.03 pine pine.396 pine.4.03 ping pjtoppm \
      pktogf pktopbm pktype pltotf pmsgs Pnews pnmalias pnmarith pnmcat \
      pnmcomp pnmconvol pnmcrop pnmcut pnmdepth pnmenlarge pnmfile pnmflip \
      pnmgamma pnmhistmap pnmindex pnminvert pnmmargin pnmnlfilt pnmnoraw \
      pnmpad pnmpaste pnmrotate pnmscale pnmshear pnmsmooth pnmtile \
      pnmtoddif pnmtofits pnmtops pnmtorast pnmtosgi pnmtosir pnmtotiff \
      pnmtoxwd pooltype ppm2tiff ppm3d ppmarith ppmbrighten ppmchange \
      ppmconvol ppmcscale ppmdim ppmdist ppmdither ppmflash ppmforge \
      ppmhist ppmmake ppmmix ppmnorm ppmntsc ppmpat ppmquant ppmquantall \
      ppmqvga ppmrelief ppmrotate ppmscale ppmshear ppmshift ppmsmooth \
      ppmspread ppmtoacad ppmtobmp ppmtogif ppmtoicr ppmtoilbm ppmtomap \
      ppmtomitsu ppmtopcx ppmtopgm ppmtopi1 ppmtopict ppmtopj ppmtopjxl \
      ppmtops ppmtopuzz ppmtorast ppmtorgb3 ppmtosixel ppmtotga ppmtouil \
      ppmtoxpm ppmtoxwd ppmtoyuv ppmtoyuvsplit printers procmail \
      procmail-2.91 procmail-3.10 protoize ps2ascii ps2epsi psbb psbook \
      psidtopgm psnup psroff psselect pstopnm pstops pstruct purify python \
      python1.5 qrttoppm ras2tiff rast rasttopbm rasttopnm rasttoppm \
      rawtopgm rawtoppm RCS rcs rcs-checkin rcsdiff rcsmerge rdjpgcom \
      replsrc rftp rgb2ycbcr rgb3toppm rlog rlogin-cwd rman rn Rnmail rrn \
      rtin rz s2p sam samsave sas scheme scheme.hidden scp scp1 scp1.old \
      scp2 sftp sftp-server sftp-server2 sftp2 sgcount sggrep sgitopnm \
      sgmls sgmlsasp sgmlsb sgmlseg sgmltoken sgmltrans sgrpg sgsort \
      showaudio simple simpleq sirtopnm sldtoppm slitex slogin spctoppm \
      Splus Splus-CIV405 Splus.990617 Splus5 spottopgm spss spss-2.6 \
      sputoppm sq ssh-add ssh-add1 ssh-add1.old ssh-add2 ssh-agent \
      ssh-agent1 ssh-agent1.old ssh-agent2 ssh-askpass ssh-askpass1 \
      ssh-askpass1.old ssh-askpass2 ssh-keygen ssh-keygen1 ssh-keygen1.old \
      ssh-keygen2 ssh1 ssh1.old ssh2 sshd sshd1 sshd2 stata "stata do" stt \
      sysinfo sz taintperl tangle tclsh tcsh tex texi2dvi texindex texinfo \
      textonly tfmtodit tftopl tgatoppm Thesaurus tiff2bw tiff2ps tiffcmp \
      tiffcp tiffdither tiffdump tiffinfo tiffmedian tiffsplit tifftopbm \
      tifftopgm tifftopnm timed-read timed-run tin tknewsbiff tkpasswd \
      tkrat top top-2.5.1 top-2.6 top.SunOS5.5.1 top.SunOS5.6 top.SunOS5.7 \
      tperl4.036 tprint trn trn-artchk trn.old tryaffix unknit unprotoize \
      unsq updatedots vftovp virmf virtex vptovf weather weave wish wish4.1 \
      wrjpgcom wwwpublic X11 x11 x11copy X11R6.1 x11start x11start.new \
      xbmtopbm ximtoppm xkibitz xmaple xmaple4 xmaple6 xmlnorm xpmtoppm \
      xpstat xvminitoppm xwdtopbm xwdtopnm xwdtoppm ybmtopbm ytalk \
      yuvsplittoppm yuvtoppm zcmp zdiff zeisstopnm zforce zgrep zip zipnote \
      zipsplit zmore znew zsh zsh-2.6 zsh-2.6-beta10 zsh.new \
      ]
    
    # =======================================================================
    #
    # Flags
    # 
    # This is a simple set of flags, little more beyond the alphabet. 
    # Compiling an exhaustive list of flags for all commands is beyond my time
    # and patience, even with my obsessive tendencies.  The user has the option
    # of adding more through the Mode Preferences dialog
    #
    set keywordLists(flags) [list \
      -a -b -c -d -e -f -g -h -i -j -k -l -m -n -o -p -q -r -s -t -u -v -w \
      -x -y -z \
      ]
    
    # =======================================================================
    #
    # Directories
    # 
    # This contains common shell directories.
    #
    set keywordLists(directories) [list \
      adm audit bin crash cron dev devices dmi dsk dt etc home kernal lib \
      license local log lp mnt n nis opt platform preserve proc pub sadm \
      saf sbin scratch snmp statmon swap spool tmp u ucb usr var vol xfn yp \
      ]
    
    # =======================================================================
    #
    # Suffixes
    #
    # This list comes from both "Unix in a Nutshell" and the file mappings 
    # section of the Mac OS 9.0 Internet control panel.  It also includes 
    # some extras from more obscure programs that I use a lot, such as dbms.
    # 
    set keywordLists(suffixes) [list \
      .1st .600 .8med .8avx .a .ado .aif .aifc .aiff .al .ani .apd .arc \
      .arj .arr .art .asc .ascii .asm .au .aux .avi .bar .bas .bat .bbl \
      .bga .bib .bin .blg .bmp .boo .bst .bw .c .cc .cer .cgm .class .clp \
      .cls .clo .cmd .com .cp .cpt .crt .csh .csv .ct .cut .cvs .dat .dbf \
      .dcr .dct .dcx .def .dif .dir .diz .dl .dll .do .doc .drv .dta .dtx \
      .dv .dvi .dxf .eps .epsf .etx .evy .exe .faq .fd .fdd .fit .flc .fli \
      .fm .for .fp3 .frs .gem .gif .gl .glo .gls .grp .gz .h .hcom .hp \
      .hpgl .hpp .hqx .htm .html .i3 .ic1 .ic2 .ic3 .icn .ico .idx .ief \
      .ilbm .ilg .image .img .inc .ind .ini .ins .java .jfif .jtx .jpe .jpg \
      .ksh .lof .latex .lbm .lha .log .lot .ltx .lzh .m15 .m1a .m1v .m2 \
      .m2s .m2v .m3 .m75 .mac .mak .mcw .me .med .mf .mid .midi .mif .mime \
      .ml .mod .mol .moov .mov .mp2 .mp3 .mpa .mpe .mpeg .mpg .mpv .mps \
      .mtm .mw .mwii .neo .nfo .nsl .nst .obj .oda .okt .otf .out .ovi .p \
      .p12 .p7c .p7m .p7s .pac .pas .pbm .pc1 .pc2 .pc3 .pcs .pct .pdx .pdb \
      .pdf .pdx .pf .pgm .pgp .ph .pi1 .pi2 .pi3 .pic .pict .pit .pkg .pl \
      .plt .pm .pm3 .pm4 .pm5 .png .pntg .por .ppd .ppm .ppt .prn .ps .psd \
      .pt4 .pt5 .pxr .qcp .qdv .qif .qt .qxd .qxt .r .ra .ram .raw .readme \
      .rgb .rgba .rib .rif .rle .rm .rme .epl .rsc .rtf .rtx .s .s3m .sav \
      .sas .scc .scq .sci .scp .scr .scu .sd2 .sea .sgi .sh .sha .shar .shp \
      .SIT .sit .sithqx .six .slk .smi .snd .spc .spp .sps .Cshsun .sr \
      .ssd01 .ssdsun .stata4 .sty .sun .sup .svx .syk .sylk .tar .targa \
      .taz .tcl .tex .texi .texinfo .text .tga .tgz .tif .tiff .tny .toc \
      .tsv .ttc .ttf .tx8 .txt .ul .url .uu .uue .vff .vga .vob .voc .w51 \
      .wav .wk1 .wk3 .wmf .wp .wp4 .wp5 .wp6 .wpg .wpm .wri .wve .x10 .x11 \
      .xbm .xi .xlc .xlm .xls .xlw .xm .xpm .xwd .Z .z .zip .zoo \
      ]
}

# ===========================================================================
#
# ×××× sh mode preferences ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "sh::removeCshSettings" --
 # 
 # The previous version of this mode was named 'Csh' -- in order to make sure
 # that previous settings don't conflict these these, we quietly unset all
 # and remove them.  (We probably need a 'mode::removeAllTraces' proc)
 # 
 # --------------------------------------------------------------------------
 ##

proc sh::removeCshSettings {} {
    
    global HOME
    
    variable FirstLoad
    
    if {[info exists FirstLoad]} {
	return
    }
    
    foreach name [array names Csh] {
	prefs::removeObsolete Csh($name)
    }
    prefs::removeObsolete filepats(Csh)
    prefs::removeObsolete mode::features(Csh)
    if {[file exists [file join $HOME Tcl Mode cshMode.tcl]]} {
	set question "Your installation contains 'Csh' mode,\
	  which is now obsolete and should be uninstalled.\
	  \r\rWould you like to do that now?"
	if {[askyesno $question]} {
	    status::msg "Select 'Csh' mode from this dialog."
	    package::uninstall
	}
    }
    set FirstLoad 1
    prefs::modified FirstLoad
    return
}

# Call this now.
sh::removeCshSettings ; rename sh::removeCshSettings ""

#=============================================================================
#
# Standard preferences recognized by various Alpha procs
#

newPref flag autoMark               0          sh
newPref var  lineWrap               1          sh
newPref var  commentsContinuation 1            sh "" \
  [list "only at line start" "spaces allowed" "anywhere"] index

newPref flag electricBraces         0          sh
newPref var  fillColumn        {75}            sh
newPref var  leftFillColumn    {0}             sh
newPref var  prefixString      {# }            sh
newPref var  wordBreak         {[\w._-]+}      sh
# To automatically indent the new line produced by pressing Return, turn this
# item on.  The indentation amount is determined by the context||To have the
# Return key produce a new line without indentation, turn this item off
newPref flag indentOnReturn    1 sh

#=============================================================================
#
# Flag preferences
#

# To send double-clicked commands to the cgi man pages site rather than
# 'Unix Help Url' search results, turn this item on|| To send double-clicked
# commands to the 'Unix Help Url' search results rather than the cgi man
# pages, this item off
newPref flag helpFindsManPage    1              sh {sh::postEval}
# To only mark 'headers', sections that start with '### ' or '#### ', rather
# than all commands with respect to the 'Mark Expression' preference, turn
# this item on||To mark all commands with respect to the 'Mark Expression'
# preference, turn this item off
newPref flag markHeadersOnly     0              sh {sh::postEval}
# To navigate blocks of commands, separated by empty lines, turn this item
# on|| To navigate by indentation, where a command starts in the first
# column, turn this item off
newPref flag navigateParagraphs  0              sh {sh::postEval}

#=============================================================================
#
# Variable preferences
# 

# Enter additional shell commands to be colorized.
newPref var  addCommands       {}              sh {sh::colorizesh}
# Enter additional command flags to be colorized.
newPref var  addFlags          {}              sh {sh::colorizesh}
# Enter additional programs (such as stata, spss).
newPref var  addPrograms       {}              sh {sh::colorizesh}
# See the "sh Scripts Help" file for Mark File and Parse Funcs tips.  These
# values will are ignored unless the 'Navigate Blocks' preference is also
# set.
newPref var  markExpression    {^[ \t]*[a-zA-Z0-9]+}  sh
newPref var  parseExpression   {^[ \t]*[a-zA-Z0-9]+}  sh
# Command double-clicking on shell keywords will send them to this url
# for on-lin help.  See the "sh Scripts Help" file for details.
newPref url  unixHelpUrl      {http://unixhelp.ed.ac.uk/cgi-bin/unixhelp_search?} sh
# Command double-clicking on shell keywords can alternatively send them to
# this url for an on-line man page.  See the "sh Scripts Help" file for
# details.
newPref url  unixManPageUrl   {http://mirrors.ccs.neu.edu/cgi-bin/unixhelp/man-cgi?}    sh
# The "sh Scripts Home Page" menu item will send this url to your browser.
newPref url  shScriptsHomePage {http://unixhelp.ed.ac.uk/} sh

# ===========================================================================
# 
# Color preferences
#

newPref color commandColor      {blue}      sh {sh::colorizesh}
newPref color commentColor      {red}       sh {stringColorProc}
# Color of file directories
newPref color directoryColor    {none}      sh {sh::colorizesh}
newPref color flagColor         {blue}      sh {sh::colorizesh}
# Color of the magic character $.  Magic Characters will colorize any
# string which follows them, up to the next empty space.
newPref color magicColor        {none}      sh {sh::colorizesh}
newPref color programColor      {magenta}   sh {sh::colorizesh}
newPref color stringColor       {green}     sh {stringColorProc}
# Color of file suffixes
newPref color suffixColor       {none}      sh {sh::colorizesh}
# Color of symbols such as "/", "@", etc.
newPref color symbolColor       {magenta}   sh {sh::colorizesh}

# Call this now, so that the rest can be 'adds'.
regModeKeywords -C sh {}
regModeKeywords -a -e {#} -c $shmodeVars(commentColor) \
  -s $shmodeVars(stringColor) sh

# ===========================================================================
# 
# Categories of all sh mode preferences, used by [prefs::dialogs::modePrefs].
# When the dialogues are actually built, there will most likely be added a
# Miscellaneous pane.  This happens whenever there are prefs which are not
# categorized.  (There's no need to set a "Miscellaneous" group entry,
# because this will always be built from scratch.)
# 

# Editing
prefs::dialogs::setPaneLists "sh" "Editing" [list \
  "electricBraces" \
  "fillColumn" \
  "indentOnReturn" \
  "leftFillColumn" \
  "lineWrap" \
  "wordBreak" \
  ]

# Navigation
prefs::dialogs::setPaneLists "sh" "Navigation" [list \
  "autoMark" \
  "markExpression" \
  "markHeadersOnly" \
  "navigateParagraphs" \
  "parseExpression" \
  ]

# Comments
prefs::dialogs::setPaneLists "sh" "Comments" [list \
  "commentColor" \
  "commentsContinuation" \
  "prefixString" \
  ]

# Keywords
prefs::dialogs::setPaneLists "sh" "Keywords" [list \
  "addCommands" \
  "addFlags" \
  "addPrograms" \
  ]

# Colors
prefs::dialogs::setPaneLists "sh" "Colors" [list \
  "commandColor" \
  "directoryColor" \
  "flagColor" \
  "magicColor" \
  "programColor" \
  "stringColor" \
  "suffixColor" \
  "symbolColor" \
  ]

# Help
prefs::dialogs::setPaneLists "sh" "Shell Scripts Help" [list \
  "helpFindsManPage" \
  "shScriptsHomePage" \
  "unixHelpUrl" \
  "unixManPageUrl" \
  ]

# ===========================================================================
#
# ×××× Colorize sh ×××× #
# 

proc sh::colorizesh {{pref ""}} {
    
    global shmodeVars shcmds shUserCommands shUserPrograms shUserFlags
    
    variable keywordLists
    
    # Create the list of all keywords for completions.
    eval [list lappend shcmds] \
      $keywordLists(commands) $shmodeVars(addCommands) \
      $keywordLists(programs) $shmodeVars(addPrograms)
    if {[info exists shUserCommands]} {
	eval [list lappend shcmds] $shUserCommands
    }
    if {[info exists shUserPrograms]} {
	eval [list lappend shcmds] $shUserPrograms
    }
    set shcmds [lsort -dictionary -unique $shcmds]
    
    # Commands
    eval [list lappend shCommandColorList] \
      $keywordLists(commands) $shmodeVars(addCommands)
    if {[info exists shUserCommands]} {
	eval [list lappend shCommandColorList] $shUserCommands
    }
    regModeKeywords -a -k $shmodeVars(commandColor) \
      sh $shCommandColorList
    
    # Programs
    eval [list lappend shProgramColorList] \
      $keywordLists(programs) $shmodeVars(addPrograms)
    if {[info exists shUserPrograms]} {
	eval [list lappend shProgramColorList] $shUserCommands
    }
    regModeKeywords -a -k $shmodeVars(programColor) \
      sh $shProgramColorList
    
    # Flags
    eval [list lappend shFlagColorList] \
      $keywordLists(flags) $shmodeVars(addFlags)
    if {[info exists shUserFlags]} {
	eval [list lappend shFlagColorList] $shUserFlags
    }
    regModeKeywords -a -k $shmodeVars(flagColor) \
      sh $shFlagColorList
    
    # Directories
    regModeKeywords -a -k $shmodeVars(directoryColor) \
      sh $keywordLists(directories)
    
    # Suffixes
    regModeKeywords -a -k $shmodeVars(suffixColor) \
      sh $keywordLists(suffixes)
    
    # Symbols
    regModeKeywords -a -m {$} -k $shmodeVars(magicColor) \
      -i "+" -i "-" -i "*" -i "\\" -i "/" -i "|" \
      -I $shmodeVars(symbolColor) \
      sh {}
    
    if {($pref ne "")} {
	refresh
    }
    return
}

# Call this now.
sh::colorizesh

# ===========================================================================
#
# ×××× Key Bindings, Indentation ×××× #

Bind 0x27    <z>    {sh::menuProc "sh Scripts" "newComment"} sh
Bind 0x27   <cz>    {sh::menuProc "sh Scripts" "commentTemplate"} sh

# For those that would rather use arrow keys to navigate.  Up and down
# arrow keys will advance to next/prev command, right and left will also
# set the cursor to the top of the window.

Bind    up  <sz>    {sh::searchFunc 0 0 0} sh
Bind  left  <sz>    {sh::searchFunc 0 0 1} sh
Bind  down  <sz>    {sh::searchFunc 1 0 0} sh
Bind right  <sz>    {sh::searchFunc 1 0 1} sh

if {(${alpha::platform} eq "alpha")} {
    # This is a bug in Alpha if we need this stuff.
Bind 0x14    <z>    {sh::menuProc "sh Scripts" "insertSectionMark"} sh
Bind 0x14   <sz>    {sh::menuProc "sh Scripts" "insertSectionMark"} sh
Bind  '3'    <z>    {sh::menuProc "sh Scripts" "insertSectionMark"} sh
Bind  '#'   <sz>    {sh::menuProc "sh Scripts" "insertSectionMark"} sh
}

## 
 # --------------------------------------------------------------------------
 # 
 # "sh::carriageReturn" --
 # 
 # Inserts a carriage return, and indents properly.
 # 
 # --------------------------------------------------------------------------
 ##

proc sh::carriageReturn {} {
    
    if {[isSelection]} {
	deleteSelection
    }
    set pos1 [lineStart [getPos]]
    set pos2 [getPos]
    set t    [getText $pos1 $pos2]
    set pat  "^\[\t \]*((\}|\\)).*$)|((done|else|elif|end|END|fi)\[\r\n\t;:\]*$)"
    if {[regexp $pat $t]} {
	createTMark temp $pos2
	catch {bind::IndentLine}
	gotoTMark temp ; removeTMark temp
    }
    insertText "\r"
    catch {bind::IndentLine}
    return
}

## 
 # --------------------------------------------------------------------------
 # 
 # "sh::correctIndentation" --
 # 
 # sh::correctIndentation is necessary for Smart Paste, and returns the
 # correct level of indentation for the current line.  We grab the previous
 # non-commented line, and indent the next line respecting the commands
 # (if|else|elif|for|while) to increase the indent, and (end|else|elif|fi|od)
 # to decrease.
 # 
 # --------------------------------------------------------------------------
 ##

proc sh::correctIndentation {args} {
    
    win::parseArgs w pos {next ""}
    
    global indentationAmount
    
    variable lineContinuationChar
    
    set posBeg    [pos::lineStart -w $w $pos]
    # Get information about this line, previous line ...
    set thisLine  [sh::getCommandLine -w $w $posBeg 1 1]
    set prevLine1 [sh::getCommandLine -w $w \
      [pos::math -w $w $posBeg - 1] 0 1]
    set prevLine2 [sh::getCommandLine -w $w \
      [pos::math -w $w [lindex $prevLine1 0] - 1] 0 1]
    set lwhite    [lindex $prevLine1 1]
    # If we have a previous line ...
    if {[pos::compare -w $w [lindex $prevLine1 0] != $posBeg]} {
	set pL1 [lindex $prevLine1 2]
	# Indent if the last line did not terminate the command.
	if {([string trimright $pL1 $lineContinuationChar] ne $pL1)} {
	    incr lwhite [expr {$indentationAmount/2}]
	}
	# Check to make sure that the previous command was not itself a
	# continuation of the line before it.
	if {[pos::compare -w $w [lindex $prevLine2 0] != [lindex $prevLine1 0]]} {
	    set pL2 [string trim [lindex $prevLine2 2]]
	    if {([string trimright $pL2 $lineContinuationChar] ne $pL2)} {
		incr lwhite [expr {-$indentationAmount/2}]
	    }
	}
	# Indent if the last line was if|else|elif|for|foreach|switch|while.
	set pat {^[\t ]*(if|else|elif|for|foreach|switch|while)([\t ]*.*)?$}
	if {[regexp $pat $pL1]} {
	    incr lwhite $indentationAmount
	} elseif {[regexp {^.*<<(END|end)[\t ]*.*$} $pL1]} {
	    incr lwhite $indentationAmount
	}
	# Find out if there are any unbalanced {,},(,) in the last line.
	regsub -all {[^ \{\}\(\)\"`\#\\]} $pL1 { } line
	# Remove all literals.
	regsub -all {\\\{|\\\}|\\\(|\\\)|\\\"|\\\`|\\\#} $line { } line
	regsub -all {\\} $line { } line
	# Remove everything surrounded by quotes.
	regsub -all {\"[^\"]+\"} $line { } line
	regsub -all {\"} $line { } line
	regsub -all {\`[^\`]+\`} $line { } line
	regsub -all {\`} $line { } line
	# Remove all characters following the first valid comment.
	if {[regexp {\#} $line]} {
	    set line [string range $line 0 [string first {#} $line]]
	}
	# Now turn all braces into 1's and -1's
	regsub -all {\{|\(} $line { 1 }  line
	regsub -all {\}|\)} $line { -1 } line
	# This list should now only contain 1's and -1's.
	foreach i $line {
	    if {($i == "1") || ($i == "-1")} {
		incr lwhite [expr {$i * $indentationAmount}]
	    }
	}
	# Did the last line start with a lone \) or \} ?  If so, we want to
	# keep the indent, and not make call it an unbalanced line.
	if {[regexp {^[\t ]*(\}|\)).*} $pL1]} {
	    incr lwhite $indentationAmount
	}
    }
    # If we have a current line ...
    if {[pos::compare -w $w [lindex $thisLine 0] == $posBeg]} {
	# Reduce the indent if the first non-whitespace character of this
	# line is done|else|elif|end|endif|END|fi.
	set tL [lindex $thisLine 2]
	if {[regexp {^[\t ]*(done|else|elif|end|endif|END|fi)[\t ;:]*$} $tL]} {
	    incr lwhite -$indentationAmount
	} elseif {[regexp {^[\t ]*(\}|\))} $tL]} {
	    incr lwhite -$indentationAmount
	}
    }
    # Now we return the level to the calling proc.
    return [expr {$lwhite > 0 ? $lwhite : 0}]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "sh::getCommandLine" --
 # 
 # Find the next/prev command line relative to a given position, and return
 # the position in which it starts, its indentation, and the complete text of
 # the command line.  If the search for the next/prev command fails, return
 # an indentation level of 0.
 # 
 # --------------------------------------------------------------------------
 ##

proc sh::getCommandLine {args} {
    
    win::parseArgs w pos {direction 1} {ignoreComments 1}
    
    if {$ignoreComments} {
	set pat {^[\t ]*[^\t\r\n\# ]}
    } else {
	set pat {^[\t ]*[^\t\r\n ]}
    }
    set posBeg [pos::math -w $w [pos::lineStart -w $w $pos] - 1]
    if {[pos::compare -w $w $posBeg < [minPos -w $w]]} {
	set posBeg [minPos -w $w]
    }
    set lwhite 0
    if {![catch {search -w $w -f $direction -r 1 $pat $pos} match]} {
	set posBeg [lindex $match 0]
	set lwhite [lindex [pos::toRowCol -w $w \
	  [pos::math -w $w [lindex $match 1] - 1]] 1]
    }
    set posEnd [pos::math -w $w [pos::nextLineStart -w $w $posBeg] - 1]
    if {[pos::compare -w $w $posEnd > [maxPos -w $w]] \
      || [pos::compare -w $w $posEnd < $posBeg]} {
	set posEnd [maxPos -w $w]
    }
    return [list $posBeg $lwhite [getText -w $w $posBeg $posEnd]]
}

proc sh::searchFunc {direction args} {
    
    if {![llength $args]} {
	set args [list 0 2]
    }
    if {$direction} {
	eval nextWhat $args
    } else {
	eval prevWhat $args
    }
    return
}

# ===========================================================================
# 
# ×××× Command Double Click ×××× #
#

## 
 # --------------------------------------------------------------------------
 # 
 # "sh::DblClick" --
 # 
 # Checks to see if the highlighted word appears in the "command" list, and if
 # so, sends the selected word to "sh::wwwCommandHelp".
 # 
 # --------------------------------------------------------------------------
 ##

proc sh::DblClick {from to shift option control} {
    
    global shmodeVars
    
    variable keywordLists
    
    set allCommands  [concat $keywordLists(commands)  $shmodeVars(addCommands)]
    set allPrograms  [concat $keywordLists(programs)  $shmodeVars(addPrograms)]
    
    selectText $from $to
    set command [getSelect]
    
    # First found out if "$command" is a file in the same directory, or a 
    # complete path.  If the file exists, open it in Alpha.
    if {[win::IsFile [win::Current] filePath]} {
	set dir [file dirname $filePath]
	set f1  [file join $dir $command]
	set f2  [file join $dir [string trim $command "\""]]
	foreach f [list $command [string trim $command] $f1 $f2] {
	    if {[file exists $f]} {
		placeBookmark
		edit -c $f
		status::msg "Press 'Control-.' to return to original window."
		return
	    }
	}
    }
    # Not a file, so try something else.
    
    set pat "^[string trimleft $command "$"]\[\t ]*="
    
    if {![catch {search -s -f 1 -r 1 -i 0 -m 0 $pat [minPos]} match]} {
	# First check current file for a function, variable (etc)
	# definition, and if found ...
	placeBookmark
	goto [lineStart [lindex $match 0]]
	status::msg "Press 'Control-.' to return to original cursor position"
	return
    }
    if {[lcontains allCommands $command]} {
	sh::wwwCommandHelp $command
    } elseif {[lcontains allPrograms $command]} {
	if {[dialog::yesno "'$command' is defined as a program.\
	  Do you want to look up the host www.$command.com?"]} {
	    status::msg "Looking up the host www.$command.com"
	    url::execute http://www.${command}.com
	} else {
	    error "cancel"
	}
    } else {
	status::msg "Command-Double-Click only on shell commands and file names."
    }
    return
}

proc sh::wwwCommandHelp {{command ""}} {
    
    global shmodeVars PREFS
    
    variable shCommandsRedirect
    
    if {($command eq "")} {
	if {[catch {prompt "On-line unix command help for É" ""} command]} {
	    status::msg "Cancelled."
	    return -code return
	}
    }
    # Which site shall we use?
    if {$shmodeVars(helpFindsManPage)} {
	# Make sure that the trailing '/' is in place.
	set url [string trimright $shmodeVars(unixManPageUrl) "/"]
	# Redirect if necessary.
	if {[info exists shCommandsRedirect($command)]} {
	    set command $shCommandsRedirect($command)
	}
	append url $command
    } else {
	# Make sure that the trailing '/' is in place.
	set url [string trim $shmodeVars(unixHelpUrl)]
	append url "search_term=${command}&max_hits=50"
    }
    urlView $url
    return
}

# ===========================================================================
#
# ×××× Mark File and Parse Functions ×××× #
#

## 
 # --------------------------------------------------------------------------
 # 
 # "sh::MarkFile" --
 # 
 # The default Mark Expression will return the first 35 characters from the
 # first non-commented word.  The Statistical Modes Help file gives examples
 # of other possible expressions that could be more restrictive.
 # 
 # --------------------------------------------------------------------------
 ##

proc sh::MarkFile {args} {
    
    global shmodeVars
    
    win::parseArgs w
    
    status::msg "Marking \"[win::Tail $w]\" É"
    
    set count 0
    set pos [minPos -w $w]
    set pat {^(###[\t ]+|####[\t ]+)}
    if {!$shmodeVars(markHeadersOnly)} {
	if {$shmodeVars(navigateParagraphs)} {
	    append pat "|($shmodeVars(markExpression))"
	} else {
	    append pat "|(^\[a-zA-Z0-9\]+)"
	}
    }
    while {![catch {search -w $w -s -f 1 -r 1 -m 0 -i 1 $pat $pos} match]} {
	incr count
	set pos0 [pos::lineStart -w $w [lindex $match 0]]
	set pos1 [pos::nextLineStart -w $w $pos0]
	set pos  $pos1
	set mark [string trim [getText -w $w $pos0 $pos1]]"
	set mark "  [string trimright $mark "#"]"
	regsub {  #### } $mark {* } mark
	regsub {  ### }  $mark {¥ } mark
	if {[regexp {(^[\t #]+$)|(^[\t ]+(fi|elif|else|end|END).*)} $mark]} {
	    incr count -1
	    continue
	} elseif {[regexp {^(\*|¥)[-\t #]+\-+[\t ]*$} $mark]} {
	    # A divider.
	    incr count -1
	    set mark "-"
	}
	set mark [markTrim $mark]
	# Make sure that each mark is unique.
	while {[lcontains marks $mark]} {
	    append mark " "
	}
	lappend marks $mark
	setNamedMark -w $w $mark $pos0 $pos0 $pos0
    }
    set msg "The window \"[win::Tail $w]\" contains $count mark"
    append msg [expr {($count == 1) ? "." : "s."}]
    status::msg $msg
    return
}

# ===========================================================================
#
# sh Parse Functions
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "sh::parseFuncs" --
 # 
 # The default Parse Expression will yield only the shell command names (the
 # first non-commented word) that follow a tab.  The "Shell Scripts Help"
 # file gives examples of other possible expressions that could be more or
 # less restrictive.
 # 
 # --------------------------------------------------------------------------
 ##

proc sh::parseFuncs {} {
    
    global shmodeVars sortFuncsMenu
    
    if {$shmodeVars(navigateParagraphs)} {
	set pat $shmodeVars(parseExpression)
    } else {
	set pat {^[-a-zA-Z0-9.]+}
    }
    set pos [minPos]
    set m   [list ]
    while {![catch {search -s -f 1 -r 1 -i 0 {^(\w+)} $pos} match]} {
	if {[regexp -- {^(\w+)} [eval getText $match] "" word]} {
	    lappend m [list $word [lindex $match 0]]
	}
	set pos [lindex $match 1]
    }
    if {$sortFuncsMenu} {
	set m [lsort -dictionary $m]
    }
    return [join $m]
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× sh Menu ×××× #
# 

proc shScriptsMenu {} {}

# Tell Alpha what procedures to use to build all menus, submenus.
menu::buildProc shScriptsMenu sh::buildMenu sh::postEval

proc sh::buildMenu {} {
    
    global shScriptsMenu shmodeVars
    
    variable prefsInMenu
    
    set menuList [list \
      "shScriptsHomePage" "wwwCommandHelpÉ" \
      [list Menu -n "shModeOptions" -p sh::menuProc $prefsInMenu] "(-)" \
      "/'<E<S<BnewComment"  "/'<S<O<BcommentTemplateÉ" "/#<BinsertSectionMark" "(-)" ]
    if {$shmodeVars(navigateParagraphs)} {
	lappend menuList \
	  "/N<U<BnextBlock"     "/P<U<BprevBlock" \
	  "/S<U<BselectBlock"   "/I<B<OreformatBlock"
    } else {
	lappend menuList \
	  "/N<U<BnextCommand"     "/P<U<BprevCommand" \
	  "/S<U<BselectCommand"   "/I<B<OreformatCommand"
    }
    set submenus ""
    return [list build $menuList sh::menuProc $submenus $shScriptsMenu]
}

## 
 # --------------------------------------------------------------------------
 # 
 # "sh::postEval" --
 # 
 # Mark or dim items as necessary.
 # 
 # --------------------------------------------------------------------------
 ##

proc sh::postEval {args} {
    
    global shmodeVars
    
    variable prefsInMenu
    
    foreach itemName $prefsInMenu {
	regsub {navigateBlocks} $itemName {navigateParagraphs} prefName
	if {[info exists shmodeVars($prefName)]} {
	    markMenuItem shModeOptions $itemName $shmodeVars($prefName) Ã
	}
    }
    return
}

proc sh::rebuildMenu {{menuName "shScriptsMenu"} args} {
    menu::buildSome $menuName
    return
}

# Now we actually build the sh menu.
menu::buildSome shScriptsMenu

proc sh::registerOWH {} {
    
    global shScriptsMenu
    
    # Dim some menu items when there are no open windows.
    set menuItems {
	newComment commentTemplateÉ
	nextBlock prevBlock selectBlock reformatBlock
	nextCommand prevCommand selectCommand reformatCommand
    }
    foreach i $menuItems {
	hook::register requireOpenWindowsHook [list $shScriptsMenu $i] 1
    }
    return
}

# Call this now.
sh::registerOWH

# ===========================================================================
# 
# ×××× sh menu support ×××× #
# 

## 
 # --------------------------------------------------------------------------
 # 
 # "sh::menuProc" --
 # 
 # This is the procedure called for all main menu items.
 # 
 # --------------------------------------------------------------------------
 ##

proc sh::menuProc {menuName itemName} {
    
    global shmodeVars
    
    variable prefsInMenu
    
    switch $menuName {
	"shModeOptions" {
	    regsub {navigateBlocks} $itemName {navigateParagraphs} prefName
	    if {($itemName eq "shModeHelp")} {
		package::helpWindow "sh"
		return
	    } elseif {[getModifiers]} {
		set helpText [help::prefString $prefName "sh"]
		if {$shmodeVars($prefName)} {
		    set end "on"
		} else {
		    set end "off"
		}
		if {($end eq "on")} {
		    regsub {^.*\|\|} $helpText {} helpText
		} else {
		    regsub {\|\|.*$} $helpText {} helpText
		}
		set msg "The '$itemName' preference for sh mode is currently $end."
		dialog::alert "${helpText}."
	    } elseif {[lcontains prefsInMenu $itemName]} {
		set shmodeVars($prefName) [expr {$shmodeVars($prefName) ? 0 : 1}]
		if {([win::getMode] eq "sh")} {
		    synchroniseModeVar $prefName $shmodeVars($prefName)
		} else {
		    prefs::modified shmodeVars($prefName)
		}
		if {[regexp {Help} $prefName]} {
		    sh::rebuildMenu "shHelp"
		}
		sh::postEval
		if {$shmodeVars($prefName)} {
		    set end "on"
		} else {
		    set end "off"
		}
		set msg "The '$itemName' preference is now $end."
	    } else {
		set msg "Don't know what to do with '$itemName'."
	    }
	    if {[info exists msg]} {
		status::msg $msg
	    }
	}
	default {
	    switch -regexp $itemName {
		"shScriptsHomePage" {url::execute $shmodeVars(shScriptsHomePage)}
		"newComment"        {comment::newComment $shmodeVars(navigateParagraphs)}
		"commentTemplate"   {comment::commentTemplate}
		"insertSectionMark" {
		    set pos [getPos]
		    if {$shmodeVars(navigateParagraphs)} {
			goto [paragraph::start $pos]
		    } else {
			set results [function::inFunction $pos]
			set result  [lindex $results 0]
			set start   [lindex $results 1]
			if {$result} {
			    goto $start
			} else {
			    goto [lineStart $pos]
			}
		    }
		    elec::Insertion "### ¥¥\r¥¥"
		}
		"^prev"       {prevWhat}
		"^next"       {nextWhat}
		"^select"     {selectWhat}
		"^reformat"   {reformatWhat}
		default       {sh::$itemName}
	    }
	}
    }
    return
}

# ===========================================================================
# 
# ×××× ---- ×××× #
# 
# ×××× Version History ×××× #
# 
# modified by  rev    reason
# -------- --- ------ -----------
# 01/28/20 cbu 1.0.1  First created Csh mode, based upon other modes found 
#                       in Alpha's distribution.  Commands are based on 
#                       System V and Solaris 2.0, as found in O'Reilly's 
#                       "Unix in a Nutshell".
# 03/02/20 cbu 1.0.2  Minor modifications to comment handling.
# 03/20/00 cbu 1.0.3  Minor update of keywords dictionaries. 
# 04/01/00 cbu 1.0.4  Fixed a little bug with "comment box".
#                     Added new preferences to allow the user to optionally 
#                       use $ as a Magic Character, and to enter additional 
#                       commands and options.  
#                     Reduced the number of different user-specified colors.
#                     Added "Update Colors" proc to avoid need for a restart
# 04/08/00 cbu 1.0.5  Unset obsolete preferences from earlier versions.
#                     Added "Continue Comment" and "Electric Return Over-ride".
#                     Renamed "Update Colors" to "Update Preferences".
# 04/16/00 cbu 1.1    Renamed to cshMode.tcl
#                     Added "Mark File" and "Parse Functions" procs.
#                     Added command double-click for on-line help.
# 06/22/00 cbu 1.2    "Mark File" now recognizes headings as well as commands,
#                       and removes any leading indentation.
#                     Completions, Completions Tutorial added.
#                     "Reload Completions", referenced by "Update Preferences".
#                     Better support for user defined keywords.
#                     Removed "Continue Comment", now global in Alpha 7.4.
#                     <shift, control>-<command> double-click syntax info.
#                       (Foundations, at least.  Ongoing project.)
#                     Csh-Mode split off from Statistical Modes.
# 08/29/00 cbu 1.3    Updated for AlphaTcl 7.4.3.
#                     Removed "Electric Return Over-ride", now global in Alpha 7.4.
#                     Preliminary "C Shell" menu added, mainly with navigation.
#                     "Csh::reloadCompletions" is now obsolete.
#                     Updated completions file.
#                     Renamed to 'sh' mode.
# 10/31/01 cbu 1.3.1  Minor bug fixes.
# 01/06/03 cbu 1.4    Minor bug fixes.
#                     Removed use of [status::errorMsg] from package.
#                     Better url for help.
# 02/22/06 cbu 2.0    Keywords lists are defined in sh namespace variables.
#                     Canonical Tcl formatting.
#                     Using [prefs::dialogs::setPaneLists] for preferences.

# ===========================================================================
#
# .