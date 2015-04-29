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
    set wdgt [$a_wdgt create line {*}$a_points -tag line -joinstyle round -smooth true -arrow first];
    return $wdgt;
}

proc ::rsttool::treeditor::tree::arc::draw-line-between {a_wdgt a_p1 {a_p2 {}}} {
    set wdgt [draw-line $a_wdgt {*}$a_p1 {*}$a_p2];
    return $wdgt;
}

proc ::rsttool::treeditor::tree::arc::draw-line {a_wdgt x1 y1 x2 y2} {
    $a_wdgt create line $x1 $y1  $x2 $y2
}

proc ::rsttool::treeditor::tree::arc::bottom-point {item} {
    variable ::rsttool::treeditor::RSTW;
    list [lindex [$RSTW coords $item] 0] [lindex [$RSTW bbox $item] 3]
}

proc ::rsttool::treeditor::tree::arc::display {a_nuc_nid a_sat_nid \
						   {a_reltype {}}} {
    variable ::rsttool::NODES;
    variable ::rsttool::NID2MSGID;
    variable ::rsttool::CRNT_MSGID;
    variable ::rsttool::PRNT_MSGID;
    variable ::rsttool::treeditor::RSTW;
    variable ::rsttool::relations::SPAN;
    variable ::rsttool::treeditor::DISCUSSION;
    variable ::rsttool::treeditor::DISPLAYMODE;
    variable ::rsttool::relations::HYPOTACTIC;
    variable ::rsttool::relations::PARATACTIC;
    variable ::rsttool::treeditor::VISIBLE_NODES;

    namespace import ::rsttool::treeditor::tree::ntw;
    namespace import ::rsttool::treeditor::tree::node::draw-text;
    namespace import ::rsttool::utils::add-points;
    namespace import ::rsttool::utils::subtract-points;
    namespace import ::rsttool::utils::mid-point;

    if {![info exists VISIBLE_NODES($a_nuc_nid)] || ![info exists VISIBLE_NODES($a_sat_nid)]} {return}

    set nuc_wdgt [ntw $a_nuc_nid];
    set sat_wdgt [ntw $a_sat_nid];
    if {$a_reltype == {}} {
	set a_reltype $NODES($a_sat_nid,reltype);
	if {$a_reltype == {}} {return}
    }

    set sat_msgid $NID2MSGID($a_sat_nid);
    set prnt_prfx "";
    if {$DISPLAYMODE == $DISCUSSION && (($PRNT_MSGID != {} && $sat_msgid != $PRNT_MSGID) || \
	    ($PRNT_MSGID == {} && $sat_msgid != $CRNT_MSGID))} {
	set prnt_prfx "e";
    }

    # set variables
    set t_opts {};
    set color "red";
    set label $NODES($a_sat_nid,${prnt_prfx}relname);
    set ypos $NODES($a_sat_nid,ypos);
    set nucbot [bottom-point $nuc_wdgt];
    set satpnt "$NODES($a_sat_nid,xpos) $NODES($a_sat_nid,ypos)";
    set labelpnt {0 0};

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
					    [lindex $labelpnt 1] [list -fill $color {*}$t_opts]];
    }
}

proc ::rsttool::treeditor::tree::arc::erase {a_nid} {
    variable ::rsttool::NODES;
    variable ::rsttool::treeditor::RSTW;

    if {[info exists NODES($a_nid,arrowwgt)] && $NODES($a_nid,arrowwgt) != {} } {
	$RSTW delete $NODES($a_nid,arrowwgt);
	array unset NODES  $a_nid,arrowwgt;
    }
    if {[info exists NODES($a_nid,labelwgt)] && $NODES($a_nid,labelwgt) != {} } {
	$RSTW delete $NODES($a_nid,labelwgt);
	array unset NODES  $a_nid,labelwgt;
    }
}

proc ::rsttool::treeditor::tree::arc::change {a_nid {relname {}} } {
    variable ::rsttool::NODES;
    variable ::rsttool::NID2MSGID;
    variable ::rsttool::relations::SPAN;
    variable ::rsttool::relations::HYPOTACTIC;
    variable ::rsttool::relations::PARATACTIC;
    variable ::rsttool::treeditor::DISCUSSION;
    variable ::rsttool::treeditor::DISPLAYMODE;
    namespace import ::rsttool::treeditor::tree::choose-label;
    namespace import ::rsttool::treeditor::layout::y-layout-subtree;
    namespace import ::rsttool::treeditor::tree::node::eparent-msgid-p;

    if {$a_nid == {}} {return;}

    # determine prefix of the parent
    set ext_connection 0;
    set prnt_prfx ""; set chld_prfx "";
    if {$DISPLAYMODE == $DISCUSSION} {
	set chld_prfx "e";
	set ext_connection 1;
	if { ![eparent-msgid-p $NID2MSGID($a_nid)]} {set prnt_prfx "e";}
    }

    # check if relation change is valid operation in given context
    set prnt $NODES($a_nid,${prnt_prfx}parent);
    if {$prnt == {}} {return;}

    switch -nocase -- $NODES($a_nid,${prnt_prfx}reltype) \
	$SPAN {
	    return;
	} \
	$HYPOTACTIC {
	    set rtype {satellite};
	} \
	$PARATACTIC {
	    set rtype {multinuclear};
	}

    set nrelation [choose-label $a_nid $rtype $ext_connection];

    if {$nrelation == {}} {return;}

    if {$NODES($a_nid,${prnt_prfx}reltype) == $PARATACTIC} {
	foreach child $NODES($prnt,${chld_prfx}children) {
	    if {$NODES($child,${prnt_prfx}reltype) == $PARATACTIC} {
		set NODES($child,${prnt_prfx}relname) $nrelation;
	    }
	}
    } else {
	set NODES($a_nid,${prnt_prfx}relname) $nrelation;
    }

    y-layout-subtree $prnt;
    ::rsttool::set-state {changed} "Changed relation for node $a_nid to '$nrelation'.";
    return;
}

##################################################################
package provide rsttool::treeditor::tree::arc 0.0.1
return
