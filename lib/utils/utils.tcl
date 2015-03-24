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

proc ::rsttool::utils::menu::bind-tooltip {a_wdgt {a_cmd {::rsttool::utils::menu::show-tooltip}}} {
    puts stderr "::rsttool::utils::menu::bind-tooltip: a_wdgt = $a_wdgt, a_cmd = $a_cmd"
    bind $a_wdgt <<MenuSelect>> [list {*}[subst $a_cmd] %W];

    bind $a_wdgt <Any-Leave> {destroy %W.tooltip};
    bind $a_wdgt <Any-KeyPress> {destroy %W.tooltip};
    bind $a_wdgt <Any-Button> {destroy %W.tooltip};
}

proc ::rsttool::utils::menu::tooltip {a_wdgt {a_txt {}}} {
    puts stderr "::rsttool::utils::menu::tooltip: a_txt = $a_txt"
    if {$a_txt == {}} {return;}
    if [winfo exists $a_wdgt.tooltip] {destroy $a_wdgt.tooltip}

    set tooltip [toplevel $a_wdgt.tooltip -bd 1 -bg black]
    set scrh [winfo screenheight $a_wdgt]; # 1) flashing window fix
    set scrw [winfo screenwidth $a_wdgt]; # 2) flashing window fix
    wm geometry $tooltip +$scrh+$scrw; # 3) flashing window fix
    wm overrideredirect $tooltip 1
    pack [label $tooltip.label -bg lightyellow -fg black -text $a_txt -justify left]

    set width [winfo reqwidth $tooltip.label]
    set height [winfo reqheight $tooltip.label]
    # a.) Is the pointer in the bottom half of the screen?
    set pointer_below_midline [expr [winfo pointery .] > [expr [winfo screenheight .] / 2.0]]
    # b.) Tooltip is centred horizontally on pointer.
    set positionX [expr [winfo pointerx .] - round($width / -1.5)]
    # c.) Tooltip is displayed above or below depending on pointer Y position.
    set positionY [expr [winfo pointery .] + ($pointer_below_midline * -1) * ($height + 35) + \
		       (35 - (round($height / 2.0) % 35))]

    if  {[expr $positionX + $width] > [winfo screenwidth .]} {
	set positionX [expr [winfo screenwidth .] - $width]
    } elseif {$positionX < 0} {
	set positionX 0
    }

    wm geometry $tooltip [join  "$width x $height + $positionX + $positionY" {}]
    raise $tooltip
}

##################################################################
package provide rsttool::utils 0.0.1
return
