## -*-Tcl-*-
 # ###################################################################
 #  AlphaVOODOO - integrates Alpha with VOODOO
 # 
 #  FILE: "voodooCoercions.tcl"
 #                                    created: 6/27/97 {10:48:05 pm} 
 #                                last update: 1/3/01 {11:06:09 AM} 
 #                                    version: 2.0
 #  Author: Jonathan Guyer
 #  E-mail: <jguyer@his.com>
 #     www: <http://www.his.com/jguyer/>
 #  
 # 
 #  Copyright (C) 1997-2001  Jonathan Guyer
 #  
 #  This program is free software; you can redistribute it and/or modify
 #  it under the terms of the GNU General Public License as published by
 #  the Free Software Foundation; either version 2 of the License, or
 #  (at your option) any later version.
 #  
 #  This program is distributed in the hope that it will be useful,
 #  but WITHOUT ANY WARRANTY; without even the implied warranty of
 #  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 #  GNU General Public License for more details.
 #  
 #  You should have received a copy of the GNU General Public License
 #  along with this program; if not, write to the Free Software
 #  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 # ###################################################################
 ##

namespace eval voodoo {}

proc voodoo::coerce::enum>TEXT {typeCode data toType resultDesc} {
    binary scan $data a4 enum
    
    switch $enum {
      "eNIP" {
        set result "not in project"
      }
      "eUnl" {
        set result "unlocked"
      }
      "eLSe" {
        set result "reserved"
      }
      "eLOt" {
        set result "locked by another user"
      }
      
      "eOK " {
        set result "OK"
      }
      "eFnf" {
        set result "file not found"
      }
      "eInP" {
        set result "already in project"
      }
      
      "eNoR" {
        set result "no rights"
      }
      
      "eEqu" {
        set result "equal"
      }
      "eDif" {
        set result "different"
      }
      "eNa " {
        set result "n.a."
      }
      
      default {
        error::throwOSerr -1700
      }
      
    }
  
    tclAE::replaceDescData $resultDesc TEXT $result
}



# ××××   kLSt - locking status codes ××××

# 'eNIP'
# 'eUnl'
# 'eLSe'
# 'eLOt'

# ××××   kRCA - add result codes ××××

# 'eOK '
# 'eFnf'
# 'eInP'

# ××××   kRCL - store or fetch result codes ××××

#  (contrary to VOODOO's aete resource, these codes are not actually 
#  returned)

# 'eOK ', 'eNIP', and 'eLOt' already defined

# 'eNoR'

# ××××   kRCC - comparison result codes ××××

# 'eEqu'
# 'eDif'
# 'eNa '


