#!/usr/bin/env wish
# -*- mode: tcl; -*-

##################################################################
namespace eval ::rsttool::treeditor::tree::arc {
    namespace export group-relation-p;
}

##################################################################
proc ::rsttool::treeditor::tree::arc::relation-type {rel} {
    variable ::rsttool::relations::RELATIONS

    if { $rel == relations::SPAN } {
	return span
    } elseif [info exists RELATIONS($rel,type)] {
	return $RELATIONS($rel,type)
    } else {
	return 0
    }
}

proc ::rsttool::treeditor::tree::arc::group-relation-p {a_rtype} {
    variable ::rsttool::relations::SPAN;
    variable ::rsttool::relations::PARATACTIC;

    if {$a_rtype == {}} {return 0}
    return [expr {"$a_rtype" == "$SPAN"} || {"$a_rtype" == "$PARATACTIC"}];
}

proc ::rsttool::treeditor::tree::arc::rst-relation-p {rel} {
    if {$rel == {} } {return 0}
    set rtype [relation-type $rel]
    return [$rtype == relations::RST] || [$rtype == relations::EMBEDDED]
}

proc ::rsttool::treeditor::tree::arc::constit-relation-p {rel} {
    if {$rel == {} } {return 0}
    set rtype [relation-type $rel]
    return [$rtype == relations::CONSTIT]
}

proc ::rsttool::treeditor::tree::arc::draw-arc {a_wdgt a_points} {
    puts stderr "draw-arc: $a_wdgt create line $a_points -tag line -joinstyle round -smooth true -arrow first;"
    $a_wdgt create line $a_points -tag line -joinstyle round -smooth true -arrow first;
}

proc ::rsttool::treeditor::tree::arc::draw-line-between {a_wdgt a_p1 {a_p2 {}}} {
    puts stderr "draw-line-between: a_wdgt = $a_wdgt a_p1 = $a_p1 a_p2 = $a_p2;"
    draw-line $a_wdgt {*}$a_p1 {*}$a_p2;
}

proc ::rsttool::treeditor::tree::arc::draw-line {a_wdgt x1 y1 x2 y2} {
    $a_wdgt create line $x1 $y1  $x2 $y2
}

proc ::rsttool::treeditor::tree::arc::draw-text {a_wdgt a_txt x y {options {}}} {
    $a_wdgt create text $x $y -text $a_txt -anchor n -justify center {*}$options;
}

proc ::rsttool::treeditor::tree::arc::bottom-point {item} {
    variable ::rsttool::treeditor::RSTW;
    list [lindex [$RSTW coords $item] 0] [lindex [$RSTW bbox $item] 3]
}

proc ::rsttool::treeditor::tree::arc::display {a_nuc_nid a_sat_nid \
						   {a_reltype {}}} {
    variable ::rsttool::NODES;
    variable ::rsttool::treeditor::RSTW;
    variable ::rsttool::relations::SPAN;
    variable ::rsttool::relations::HYPOTACTIC;
    variable ::rsttool::relations::PARATACTIC;
    namespace import ::rsttool::treeditor::tree::ntw;
    namespace import ::rsttool::utils::add-points;
    namespace import ::rsttool::utils::subtract-points;

    set nuc_wdgt [ntw $a_nuc_nid];
    set sat_wdgt [ntw $a_sat_nid];
    if {$a_reltype == {}} {
	set a_reltype $NODES($a_sat_nid,reltype);
	if {$a_reltype == {}} {return}
    }

    # set variables
    set color "red";
    set label $NODES($a_sat_nid,relname);
    set ypos $NODES($a_sat_nid,ypos);
    set nucbot [bottom-point [ntw $nuc_wdgt]];
    set satpnt "$NODES($a_sat_nid,xpos) $NODES($a_sat_nid,ypos)";
    set labelpnt {0 0};

    puts stderr "display-arc: reltype = $a_reltype; label = $label"
    puts stderr "display-arc: nucbot = $nucbot"
    switch -nocase -- $a_reltype \
	$SPAN {
	    set NODES($a_sat_nid,arrowwgt) [draw-line-between $RSTW $nucbot $satpnt];
	    set labelpnt [subtract-points $satpnt {0 15}];
	} \
	$HYPOTACTIC {
	    set nucpnt [add-points [$RSTW coords $nuc_wdgt] {0 -2}];
	    set midpnt [subtract-points [mid-point $nucpnt $satpnt] {0 20}]
	    set labelpnt [subtract-points $midpnt {0 6}]
	    set NODES($a_sat_nid,arrowwgt) [draw-arc $RSTW [concat $nucpnt $midpnt $satpnt]]
	} \
	$PARATACTIC {
	    set NODES($a_sat_nid,arrowwgt) [draw-line-between $RSTW $nucbot $satpnt]
	    set labelpnt [add-points $nucbot {0 15}]
	} \
	{} {
	    error "Invalid relation type '$a_reltype'."
	    return;
	}

    if {$a_reltype != $SPAN} {
	set NODES($a_sat_nid,labelwgt) [draw-text $RSTW $label [lindex $labelpnt 0] \
					    [lindex $labelpnt 1] [list -fill $color]]
    }
}

proc ::rsttool::treeditor::tree::arc::erase {a_nid} {
    variable ::rsttool::NODES;
    variable ::rsttool::treeditor::RSTW;

    if {[info exists NODES($a_nid,arrowwgt)] && $NODES($a_nid,arrowwgt) != {} } {
	$RSTW delete $NODES($a_nid,arrowwgt)
	array unset NODES  $a_nid,arrowwgt;
    }
    if {[info exists NODES($a_nid,arrowwgt)] && $NODES($a_nid,labelwgt) != {} } {
	$RSTW delete $NODES($a_nid,labelwgt)
	array unset NODES  $a_nid,labelwgt;
    }
}

proc ::rsttool::treeditor::tree::arc::change {nid {relname {}} } {
    variable ::rsttool::NODES;
    variable ::rsttool::relations::RELATIONS;
    variable ::rsttool::treeditor::CURRENTMODE;

    set cmode $CURRENTMODE
    set par $NODES($nid,parent)
    if {$par != {} && $NODES($nid,relname) != "span"} {
	if {$relname == {}} {
	    if {[member $node($nid,relname) $relations(multinuc)]} {
		set type multinuc
	    } elseif {[member $node($nid,relname) $relations(constit)]} {
		set type constit
	    } elseif {[member $node($nid,relname) $relations(embedded)]} {
		set type embedded
	    } else {
		set type rst
	    }
	    set relname [choose-label $nid $type]
	}
	if {[member $node($nid,relname) $relations(multinuc)]} {
	    foreach child $node($par,children) {
		set child_rel $node($child,relname)
		if {[member $child_rel $relations(multinuc)]} {
		    set node($child,relname) $relname
		    redisplay-node $child
		}
	    }
	} else {
	    set node($nid,relname) $relname
	}
	#    redisplay-net
	node::redisplay-node $nid
    }
    set-mode $cmode
}

##################################################################
package provide rsttool::treeditor::tree::arc 0.0.1
return
