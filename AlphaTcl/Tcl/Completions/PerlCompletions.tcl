## -*-Tcl-*-
 # ==========================================================================
 #  Perl mode - an extension package for Alpha
 # 
 #  FILE: "PerlCompletions.tcl"
 #                                    created: 08/17/1994 {09:12:06 am} 
 #                                last update: 11/29/2002 {03:11:22 PM}
 #  Description: 
 #  
 #  Support for electric completions.
 #
 #  See the "perlVersionHistory.tcl" file for license info, credits, etc.
 #  
 # ==========================================================================
 ## 

# Setting the order of precedence for completions.

set completions(Perl) {contraction completion::cmd completion::word Electric Var}

set Perlcmds {
    ARGV BEGIN accept alarm atan2 autoflush binmode bless caller chdir chmod
    chomp chown chroot close closedir connect continue crypt dbmclose dbmopen
    defined delete elsif endgrent endhostent endnetent endprotoent endpwent
    endservent exists fcntl fileno flock foreach format_formfeed
    format_line_break_characters format_lines_left format_lines_per_page
    format_name format_page_number format_top_name formline getgrent getgrgid
    getgrnam gethostbyaddr gethostbyname gethostent getlogin getnetbyaddr
    getnetbyname getnetent getpeername getpgrp getppid getpriority
    getprotobyname getprotobynumber getprotoent getpwent getpwnam getpwuid
    getservbyname getservbyport getservent getsockname getsockopt gmtime
    import index input_line_number input_record_separator ioctl lcfirst
    length listen local localtime lstat mkdir msgctl msgget msgrcv msgsnd
    opendir output_field_separator output_record_separator package print
    printf quotemeta readdir readlink rename require reset return reverse
    rewinddir rindex rmdir scalar seekdir select semctl semget semop setgrent
    sethostent setnetent setpgrp setpriority setprotoent setpwent setservent
    setsockopt shift shmctl shmget shmread shmwrite shutdown sleep socket
    socketpair splice split sprintf srand study substr symlink syscall
    sysread system syswrite telldir times truncate ucfirst umask undef unless
    unlink unpack unshift untie until utime values waitpid wantarray while
    write
}

set Perlelectrics(for)          " (¥start¥;¥test¥;¥increment¥)\{\n\t¥body¥\n\}\n¥¥"
set Perlelectrics(foreach)      "$¥scalar¥ (@¥array¥)\{\n\t¥body¥\n\}\n¥¥"
set Perlelectrics(while)        " (@¥array¥)\{\n\t¥body¥\n\}\n¥¥"
set Perlelectrics(if)           " (¥condition¥)\{\n\t¥body¥\n\} ¥¥"
set Perlelectrics(else)         " \{\n\t¥else body¥\n\} ¥¥"
set Perlelectrics(elsif)        " (¥condition¥)\{\n\t¥else body¥\n\} ¥¥"
set Perlelectrics(do)           " \{¥¥\n\t¥¥\n\} while (¥test¥);\n¥¥"

# alternative defs of above -trf
set Perlelectrics(while)        " (¥test¥) \{\r\t¥body¥\r\}\r¥¥"
set Perlelectrics(foreach)      " \$¥loopVar¥ (¥listReturner¥) \{\r\t¥body¥\r\}\r¥¥"

# ×××× functions ×××× #
set Perlelectrics(split)        "(\"¥at-these-chars¥\", ¥string-returner¥)¥¥"

# ×××× contractions ×××× #
set Perlelectrics(o'd)          "×kill0open(¥hndlName¥, \"¥fileName¥\") or die \"Can't open ¥fileName¥: $!\"\n"

##
 # -------------------------------------------------------------------------
 #
 # "Perl::Completion::Var" --
 #
 # A mildly adaptive call of completion::word, in which we realise we
 # should complete '$abc...'  if we can only see 'abc...'.  The standard
 # procedure consider '$' to be part of a word so that would otherwise
 # fail.  Also handles '%', '@' and '*'.
 # 
 # -------------------------------------------------------------------------
 ##

proc Perl::Completion::Var {} {
    set lastword [completion::lastWord]
    if [containsSpace $lastword] {return 0}
    set possPrefix [string index $lastword 0]
    if {[string first $possPrefix "\$%@*"] != -1 } {
	set got [string range $lastword 1 end]
	set looking $got
	return [completion::general -excludeBefore [string length $got] \
	  -- $looking]
    } else {
	return [completion::word]
    }
}
