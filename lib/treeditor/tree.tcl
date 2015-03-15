#!/usr/bin/env wish
# -*- mode: tcl; -*-

##################################################################
package require rsttool::treeditor::tree::arc
package require rsttool::treeditor::tree::node

##################################################################
namespace eval ::rsttool::treeditor::tree { }

##################################################################
proc ::rsttool::treeditor::tree::wtn {wdgt} {
    variable ::rsttool::treeditor::WTN

    if [info exists WTN($wdgt)] {
	return $WTN($wdgt);
    }
    return 0;
}

proc ::rsttool::treeditor::tree::ntw {nid} {
    global node
    return $NODES($nid,textwgt)
}

proc ::rsttool::treeditor::tree::clicked-widget {x y} {
    variable ::rsttool::treeditor::ERASED_NODES
    variable ::rsttool::treeditor::RSTW
    variable ::rsttool::treeditor::WTN

    set x1 [$RSTW canvasx $x]
    set y1 [$RSTW canvasy $y]
    set wgts [$RSTW find overlapping [expr $x1-2] [expr $y1-2] [expr $x1+2] [expr $y1+2]]

    if { [lindex $wgts 1] != {} } {
	foreach wgt $wgts {
	    if {[info exists WTN($wgt)] && [info exists ERASED_NODES($WTN($wgt))]} {
		return $wgt
	    }
	}
    } else {
	return $wgts
    }
}

proc ::rsttool::treeditor::tree::xscrollto {x} {
    variable ::rsttool::treeditor::RSTW

    set width [lindex [lindex [$RSTW config -scrollregion] 4] 2]
    $RSTW xview moveto [expr $x / $width.000]
}

proc ::rsttool::treeditor::tree::yscrollto {y} {
    variable ::rsttool::treeditor::RSTW

    set width [lindex [lindex [$RSTW config -scrollregion] 4] 3]
    $RSTW yview moveto [expr $y / $width.000]
}

##################################################################
package provide rsttool::treeditor::tree 0.0.1
return
