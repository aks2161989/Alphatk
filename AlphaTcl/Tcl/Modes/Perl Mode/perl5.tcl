## -*-Tcl-*-
 # ==========================================================================
 #  Perl mode - an extension package for Alpha
 # 
 #  FILE: "perl5.tcl"
 #                                    created: 08/17/1994 {09:12:06 am} 
 #                                last update: 10/29/2001 {18:05:01 PM}
 #  Description: 
 #  
 #  Keywords to support colorization and cmd-dbl-click for Perl 5.
 #  
 #  This probably requires a minor update.
 #
 #  See the "perlVersionHistory.tcl" file for license info, credits, etc.
 #  
 # ==========================================================================
 ## 

proc perl5.tcl {} {}

namespace eval Perl {}

# ===========================================================================
#
# Keyword Setup
#
# Keywords are separated here according to their location in the Perl 5
# documentation for the convenience of the cmd-double-click mechanism.
#

proc Perl::setPerl5Keywords {} {
    
    global Perl::Keywords Perl::Perl5Keywords 
    global Perl::Lookup
    
    set Perl::Keywords ""

    # These are described in the "Compound statements" section of "perlsyn"
    set words {  
	continue else elsif for foreach if return unless until while eq ne cmp lt
	gt le ge
    }
    foreach wd $words { 
	set Perl::Lookup($wd) [list perlsyn {Compound statements}]
	lappend Perl::Keywords $wd
    }

    # These are described in the "SYNOPSIS" section of "perlsub"
    foreach wd {sub} {
	set Perl::Lookup($wd) [list perlsub {SYNOPSIS}]
	lappend Perl::Keywords $wd
    }

    # These are described in the "Packages" section of "perlmod"
    foreach wd {package} {
	set Perl::Lookup($wd) [list perlmod {Packages}]
	lappend Perl::Keywords $wd
    }

    # These are described in the "Package Constructors and Destructors" 
    # section of "perlmod" and can't be colorized.
    foreach wd {BEGIN END} { 
	set Perl::Lookup($wd) [list perlmod {Package Constructors and Destructors}] 
    }

    # These are described in the "A Class is Simply a Package" section of
    # "perlobj" and can't be colorized.
    foreach wd {@ISA $ISA} {
	set Perl::Lookup($wd) [list perlobj {A Class is Simply a Package}] 
    }

    # These are described in the "SYNOPSIS" section of "perlovl" and can't be
    # colorized.
    foreach wd {%OVERLOAD $OVERLOAD} {
	set Perl::Lookup($wd) [list perlovl {SYNOPSIS}]
    }

    # Special variables are described in "perlvar" (and are not all
    # individually marked, so we have to search for them.)
    #
    # This group can safely be colorized...
    set words {
	$_ $1 $2 $3 $4 $5 $6 $7 $8 $9 $& $` $' $+ $* $.  $/ $| $, $\\ $" $; $# $% 
	$= $- $~ $^ $: $?  $!  $@ $$ $< $> $( $) $0 $[ $]
    }
    foreach wd $words {
	set Perl::Lookup($wd) [list perlvar $wd]
	lappend Perl::Keywords $wd
    }

    #... while this group is forced lower-case by the current colorization scheme
    #
    set words {
	$ARG $MATCH $PREMATCH $POSTMATCH $LAST_PAREN_MATCH $MULTILINE_MATCHING
	$INPUT_LINE_NUMBER $NR $INPUT_RECORD_SEPARATOR $RS $OUTPUT_AUTOFLUSH
	$OUTPUT_FIELD_SEPARATOR $OFS $OUTPUT_RECORD_SEPARATOR $ORS
	$LIST_SEPARATOR $SUBSCRIPT_SEPARATOR $SUBSEP $OFMT $FORMAT_PAGE_NUMBER
	$FORMAT_LINES_PER_PAGE $FORMAT_LINES_LEFT $FORMAT_NAME $FORMAT_TOP_NAME
	$FORMAT_LINE_BREAK_CHARACTERS $FORMAT_FORMFEED $^L $ACCUMULATOR $^A
	$CHILD_ERROR $OS_ERROR $ERRNO $EVAL_ERROR $PROCESS_ID $PID $REAL_USER_ID
	$UID $EFFECTIVE_USER_ID $EUID $REAL_GROUP_ID $GID $EFFECTIVE_GROUP_ID
	$EGID $PROGRAM_NAME $PERL_VERSION $DEBUGGING $^D $SYSTEM_FD_MAX $^F
	$INPLACE_EDIT $^I $PERLDB $^P $BASETIME $^T $WARNING $^W $EXECUTABLE_NAME
	$^X $ARGV @ARGV @INC %INC $INC $ENV $SIG %ENV %SIG
    }
    foreach wd $words {
	set Perl::Lookup($wd) [list perlvar $wd]
    }

    # These are also described in "perlvar", despite being functions.
    set words {
	input_line_number input_record_separator autoflush output_field_separator
	output_record_separator format_page_number format_lines_per_page
	format_lines_left format_name format_top_name
	format_line_break_characters format_formfeed
    }
    foreach wd $words {
	set Perl::Lookup($wd) [list perlvar $wd]
	lappend Perl::Keywords $wd
    }

    # These are described in "perlfunc"
    set words {
	abs accept alarm and atan2 AUTOLOAD bind binmode bless caller chdir CHECK
	chmod chomp chop chown chr chroot close closedir connect CORE cos crypt
	dbmclose dbmopen defined delete DESTROY die do dump each endgrent
	endhostent endnetent endprotoent endpwent endservent eof eval exec exists
	exit exp fcntl fileno flock fork format formline getc getgrent getgrgid
	getgrnam gethostbyaddr gethostbyname gethostent getlogin getnetbyaddr
	getnetbyname getnetent getpeername getpgrp getppid getpriority
	getprotobyname getprotobynumber getprotoent getpwent getpwnam getpwuid
	getservbyname getservbyport getservent getsockname getsockopt glob gmtime
	goto grep hex import index INIT int ioctl join keys kill last lc lcfirst
	length link listen local localtime lock log lstat m map mkdir msgctl
	msgget msgrcv msgsnd my next no not NULL oct open opendir or ord our pack
	pipe pop pos print printf prototype push q qq qr quotemeta qw qx rand
	read readdir readline readlink readpipe recv redo ref rename require
	reset return reverse rewinddir rindex rmdir s scalar seek seekdir select
	semctl semget semop send setgrent sethostent setnetent setpgrp
	setpriority setprotoent setpwent setservent setsockopt shift shmctl
	shmget shmread shmwrite shutdown sin sleep socket socketpair sort splice
	split sprintf sqrt srand stat study substr symlink syscall sysopen
	sysread sysseek system syswrite tell telldir tie tied time times tr
	truncate uc ucfirst umask undef unlink unpack unshift untie use utime
	values vec wait waitpid wantarray warn write x xor y
    }
    foreach wd $words {
	set Perl::Lookup($wd) [list perlfunc $wd]
	lappend Perl::Keywords $wd
    }
    set Perl::Keywords [array names Perl::Lookup]
}

proc Perl::perl5CommandSearch {command} {
    
    global PerlmodeVars Perl::Lookup
    
    set PerlHelpDocs $PerlmodeVars(perlHelpDocsFolder)

    if {![info exists Perl::Lookup]} {Perl::setPerl5Keywords}
    if {[file exists $PerlHelpDocs] && [lcontains Perl::Keywords $command]} {
	# Look up keywords in the man page by their file marks.
	set filename [lindex [set Perl::Lookup($command)] 0]
	set filename [file join $PerlHelpDocs $filename]
	if {[file exists $filename]} {
	    placeBookmark
	    file::openQuietly $filename
	    set mark [lindex [set Perl::Lookup($command)] 1]
	    if {![string length $mark]} {set mark "null"}
	    if {![catch {search -f 1 -r 1 -i 0 -s "^${mark}" [minPos]} match]} {
		goto [lindex $match 0] ; insertToTop
	    }
	    return 1
	} else {
	    return 0
	}
    } elseif {[file exists [file join $PerlHelpDocs perl]]} {
	# Not sure what to do with this.  Just send it to the index page.
	placeBookmark
	file::openQuietly  [file join $PerlHelpDocs perl]
	return 1
    } else {
	# Try searching in Alpha's 'Perl Commands' file.
	return [Perl::perl4CommandSearch $command]
    }
}

# ===========================================================================
# 
# .
