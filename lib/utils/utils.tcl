#!/usr/bin/env wish

##################################################################
namespace eval ::rsttool::utils {
    namespace export add-points;
    namespace export getarg;
    namespace export ldelete;
    namespace export max;
    namespace export min;
    namespace export reset-array;
    namespace export strip;
    namespace export subtract-points;
}

namespace eval ::rsttool::utils::menu {
    namespace export add-item;
    namespace export add-cascade;
    namespace export bind-tooltip;
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

proc ::rsttool::utils::ldelete { list value } {
    set ix [lsearch -exact $list $value]
    if {$ix >= 0} {
	return [lreplace $list $ix $ix]
    } else {
	return $list
    }
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

proc ::rsttool::utils::reset-array {a_arr} {
    array unset $a_arr;
    array set $a_arr {};
}

proc ::rsttool::utils::strip {a_string} {
    regsub -all "\n" $a_string " " a_string
    regsub -all "\t" $a_string " " a_string
    regsub -all "  +" $a_string " " a_string
    return [string trim $a_string];
}

proc ::rsttool::utils::add-points {p1 p2} {
    list [expr [lindex $p1 0] + [lindex $p2 0]]\
	[expr [lindex $p1 1] + [lindex $p2 1]]
}

proc ::rsttool::utils::subtract-points {p1 p2} {
    list [expr [lindex $p1 0] - [lindex $p2 0]]\
	[expr [lindex $p1 1] - [lindex $p2 1]]
}

proc ::rsttool::utils::menu::add-item {menu label cmd} {
    $menu add command -label $label -command $cmd;
}

proc ::rsttool::utils::menu::add-cascade {menu label newmenu} {
    $menu add cascade -label $label -menu $newmenu;
}

proc ::rsttool::utils::menu::bind-tooltip {a_wdgt} {
    bind $a_wdgt <<MenuSelect>> {
    	destroy %W.tooltip;
    	show-menu-tooltip %W %y;
    }

    bind $a_wdgt <Any-Leave> [list destroy %W.tooltip [list continue]];
    bind $a_wdgt <Any-KeyPress> [list destroy %W.tooltip [list continue]];
    bind $a_wdgt <Any-Button> [list destroy %W.tooltip [list continue]];
}

proc ::rsttool::utils::menu::show-tooltip {a_wdgt a_y} {
    variable ::rsttool::helper::HELP;

    # obtain menu entry
    set mitem [$a_wdgt entrycget active -label]

    # show help tooltip for menu entry
    if {[info exists help($mitem)] && $help($mitem) != ""} {
	show-tooltip $a_wdgt $help($mitem)
    }
}
##################################################################
package provide rsttool::utils 0.0.1
return
