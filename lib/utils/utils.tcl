#!/usr/bin/env wish

##################################################################
namespace eval ::rsttool::utils {
    namespace export getarg;
    namespace export max;
    namespace export min;
    namespace export strip;
    namespace export reset-array;
}

##################################################################
proc ::rsttool::utils::getarg {key list} {
    # Returns the value in list immediately following key
    for {set i 0} {$i < [llength $list]} {incr i 2} {
	if { [lindex $list $i] == $key } {
	    return [lindex $list [expr $i + 1]]
	}
    }
    return {}
}

proc ::rsttool::utils::strip {a_string} {
    regsub -all "\n" $a_string " " a_string
    regsub -all "\t" $a_string " " a_string
    regsub -all "  +" $a_string " " a_string
    return [string trim $a_string];
}

proc ::rsttool::utils::reset-array {a_arr} {
    array unset $a_arr;
    array set $a_arr {};
}

proc ::rsttool::utils::max {args} {
    if {[llength $args] == 0} {
	return {};
    } else {
	set max [lindex $args 0]
    }

    foreach arg $args {
	if {$arg > $max} {set max $arg}
    }
    return $max
}

proc ::rsttool::utils::min {args} {
    if {[llength $args] == 0} {
	return {};
    } else {
	set min [lindex $args 0]
    }

    foreach arg $args {
	if {$arg < $min} {set min $arg}
    }
    return $min
}

##################################################################
package provide rsttool::utils 0.0.1
return
