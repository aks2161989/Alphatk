namespace eval ::imwidth {
    namespace export getImageWidth

    variable imageWidthCache
    array set imageWidthCache {}
    proc getImageWidth {imagefile} {
	variable imageWidthCache
	if {![info exist imageWidthCache($imagefile)]} {
	    set imageWidthCache($imagefile) 0
	    if {[catch {
		set imageWidthCache($imagefile) [getImageWidthCore $imagefile]
	    } msg]} {
		puts "DEBUG: imwidth $imagefile -> $msg"
		puts ErrorCode=$::errorCode
		puts ErrorInfo=$::errorInfo
	    }
	}
	return $imageWidthCache($imagefile)
    }
    proc getImageWidthCore {imagefile} {
	global contenttypes
	set ext [file extension $imagefile]
	if {![regexp {image/([-a-z]+)} $contenttypes($ext) -> type]} {
	    return 0
	}
	switch $type {
	    gif {
		return [gifsize $imagefile]
	    }
	    jpeg {
		return [get_jpg_width $imagefile]
	    }
	    png {
		return [pngsize $imagefile]
	    }
	    x-portable-pixmap {
		return [PPMwidth $imagefile]
	    }
	}
	return 0
    }

    proc PPMwidth {filename} {
	set f [open $imagefile r]
	gets $f;# Read magic number
	while {[gets $f s]+1&&[string length $s]&&[string match #* $s]} {}
	close $f
	scan $s %d width
	return $width
    }

    # From the Wiki!
    proc gifsize {name} {
	set f [open $name r]
	fconfigure $f -translation binary
	# read GIF signature -- check that this is
	# either GIF87a or GIF89a
	set sig [read $f 6]
	switch $sig {
	    "GIF87a" -
	    "GIF89a" {
		# do nothing
	    }
	    default {
		error "$f is not a GIF file"
	    }
	}

	# Read "logical screen size", this is USUALLY the image size
	# too.  Interpreting the rest of the GIF specification is left
	# as an exercise
	binary scan [read $f 2] s wid

	return $wid
    }

    # From the Wiki!
    proc get_jpg_width {filename} {
	# open the file
	set img [open $filename r+]
	# set to binary mode - VERY important
	fconfigure $img -translation binary

	# read in first two bytes
	binary scan [read $img 2] "H4" byte1
	# check to see if this is a JPEG, all JPEGs start with "ffd8", make
	# that SHOULD start with
	if {$byte1!="ffd8"} {
	    close $img
	    error "$filename is not a valid JPEG file!"
	}

	# cool, it's a JPG so let's loop through the whole file until we
	# find the next marker.
	while { ![eof $img]} {
	    while {$byte1!="ff"} {
		binary scan [read $img 1] "H2" byte1
	    }

	    # we found the next marker, now read in the marker type byte,
	    # throw out any extra "ff"'s
	    while {$byte1=="ff"} {
		binary scan [read $img 1] "H2" byte1
	    }

	    # if this the the "SOF" marker then get the data
	    if { ($byte1>="c0") && ($byte1<="c3") } {
		# it is the right frame. read in a chunk of data
		# containing the dimensions.
		binary scan [read $img 7] "x3SS" height width
		# return the dimensions in a list
		close $img
		return $width
	    } else {
		# this is not the the "SOF" marker, read in the offset of the
		# next marker
		binary scan [read $img 2] "S" offset
		# the offset includes its own two bytes so we need to subtract
		# them
		set offset [expr $offset -2]
		# move ahead to the next marker
		seek $img $offset current
	    }

	}
	# we didn't find an "SOF" marker...
	close $img
	return 0
    }

    # From the Wiki!
    proc pngsize {filename} {
	if {[file size $filename] < 33} {
	    error "File $filename not large enough to contain PNG header"
	}
	set f [open $filename r]
	fconfigure $f -encoding binary -translation binary

	# Read PNG file signature
	binary scan [read $f 8] H* sig
	if {[string compare $sig 89504e470d0a1a0a]} {
	    close $f
	    error "$filename is not a PNG file"
	}

	# Read IHDR chunk signature - the length (0x0000000d) never
	# changes, and the 49484452 should also always be there as it
	# is the string "IHDR"!
	binary scan [read $f 8] c8 sig
	if {[string compare $sig 0000000d49484452]} {
	    close $f
	    error "$filename is missing a leading IHDR chunk"
	}

	# Read off the size of the image
	binary scan [read $f 8] II width height
	# Ignore the rest of the data, including the chunk CRC, since I have
	# no convenient algorithm to verify it!

	#binary scan [read $f 5] ccccc depth type compression filter interlace
	#binary scan [read $f 4] I chunkCRC

	close $f
	return $width
    }
}
