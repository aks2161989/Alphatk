if {![package vsatisfies [package provide Tcl] 8.2]} {return}
package ifneeded jpeg 0.1 [list source [file join $dir jpeg.tcl]]
