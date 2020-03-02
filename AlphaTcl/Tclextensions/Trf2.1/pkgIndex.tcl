# return a platform designator, including both OS and machine
proc platform {} {
    global tcl_platform
    set plat [lindex $tcl_platform(os) 0]
    set mach $tcl_platform(machine)
    switch -glob -- $mach {
        sun4* { set mach sparc }
        intel -
        i*86* { set mach x86 }
        "Power Macintosh" { set mach ppc }
    }
    return "$plat-$mach"
}

set maindir $dir
set dir [file join $maindir [platform]]; source [file join $dir pkgIndex.tcl]
unset maindir