## -*-Tcl-*-
 # ==========================================================================
 #  Perl mode - an extension package for Alpha
 # 
 #  FILE: "perl4.tcl"
 #                                    created: 08/17/1994 {09:12:06 am} 
 #                                last update: 01/10/2006 {07:12:22 PM}
 #  Description: 
 #  
 #  Keywords to support colorization and cmd-dbl-click for Perl 4.
 #
 #  See the "perlVersionHistory.tcl" file for license info, credits, etc.
 #  
 # ==========================================================================
 ## 

proc perl4.tcl {} {}

namespace eval Perl {}

# ===========================================================================
#
# Keyword setup
#
# Keywords are separated here according to their location in "Perl Commands",
# for the convenience of the cmd-double-click mechanism.
#

proc Perl::setPerl4Keywords {} {
    
    global Perl::Keywords Perl::perl4Keywords
    global Perl::ExprWords Perl::NameWords Perl::SpecialVars
    
    set Perl::Keywords ""

    # Expression words are described in the "Compound Statements" section
    set Perl::ExprWords {  
	else elsif for foreach if return unless until while eq ne cmp lt gt le ge
    }

    # Special variables are described in their own section (and are not 
    # individually marked, so we have to search for them.)
    #
    # This group can safely be colorized...
    set Perl::NameWords {
	@_ $_ $.  $/ $, $" $\\ $\# $% $= $- $~ $^ $| $$ $?  $& $` $' $+ $* $0 $1
	$2 $3 $4 $5 $6 $7 $8 $9 $[ $] $; $!  $@ $< $> $( $) $:
    }

    #... while this group is forced lower-case by the current colorization scheme
    set Perl::SpecialVars [concat [set Perl::NameWords] {
	$^D $^F $^I $^P $^T $^W $^X 
	$ARGV @ARGV @INC %INC @INC %ENV $SIG $ENV %SIG
    }]

    # Perl operators and functions are indexed via the Marks menu
    set Perl::Keywords {
	accept alarm atan2 Bind binmode caller chdir chmod chop chown chroot
	close closedir connect continue cos crypt dbmclose dbmopen defined delete
	die do dump each eof eval exec exit exp fcntl fileno flock fork getc
	getlogin getpeername getpgrp getppid getpriority getgrnam gethostbyname
	getnetbyname getprotobyname getpwuid getgrgid getservbyname gethostbyaddr
	getnetbyaddr getprotobynumber getservbyport getpwent getgrent gethostent
	getnetent getprotoent getservent setpwent setgrent sethostent setnetent
	setprotoent setservent endpwent endgrent endhostent endnetent endprotoent
	endservent getsockname getsockopt gmtime goto grep hex index int ioctl
	join keys kill last length link listen local localtime log lstat lstat
	mkdir msgctl msgget msgsnd msgrcv next oct open opendir ord pack pipe pop
	print printf push q qq qx rand read readdir readlink recv redo rename
	require reset reverse rewinddir rindex rindex rmdir scalar seek seekdir
	select semctl semget semop send setpgrp setpriority setsockopt shift
	shmctl shmget shmread shmwrite shutdown sin sleep socket socketpair sort
	splice split sprintf sqrt srand stat study sub substr symlink syscall
	sysread system syswrite tell telldir time times tr truncate umask undef
	unlink unpack unshift utime values vec wait waitpid wantarray warn write
    }
    set Perl::perl4Keywords [concat \
      [set Perl::Keywords] [set Perl::NameWords] [set Perl::ExprWords]]
}

proc Perl::perl4CommandSearch {command} {

    global PerlmodeVars HOME Perl::Keywords Perl::SpecialVars Perl::ExprWords
    global Perl::perl4Keywords

    set PerlHelpFile [help::pathToHelp "Perl Commands"]

    # Make sure that we have some variables.
    foreach var {Keywords SpecialVars ExprWords} {
	if {![info exists Perl::$var]} {Perl::setPerl4Keywords ; break}
    }
    if {[file exists $PerlHelpFile] && [lcontains Perl::perl4Keywords $command]} {
	placeBookmark
	file::openQuietly $PerlHelpFile
	if {[lcontains Perl::ExprWords $command]} {
	    # Flow control statements don't have separate entries.
	    if {![catch {search -f 1 -r 0 -i 0 -s "Compound statements" [minPos]} match]} {
		goto [lindex $match 0] ; insertToTop
	    }
	} else {
	    if {![catch {search -f 1 -r 1 -i 0 -s "(     )${command}(\\(|  )" [minPos]} match]} {
		goto [lindex $match 0] ; insertToTop
	    }
	}
	return 1
    } else {
	return 0
    }
}

# ===========================================================================
# 
# .
