# FILE: pkgIndex.tcl
#
# Last modified on: $Date: 2015/03/25 16:45:13 $
# Last modified by: $Author: dgp $
#
# Do not override an existing ifneeded script (from C, for example).
if {![string match "" [package ifneeded Oc 1.2.1.4]]} {return}
package ifneeded Oc 1.2.1.4 [list uplevel #0 [list source [file join $dir oc.tcl]]]
