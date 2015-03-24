#!/usr/bin/env wish
# -*- mode: tcl; -*-

##################################################################
namespace eval ::rsttool::treeditor::tree::arc { }

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

proc ::rsttool::treeditor::tree::arc::group-relation-p {rel} {
    if {$rel == {} } {return 0}
    set rtype [relation-type $rel]
    return [$rtype == relations::SPAN] || [$rtype == relations::MULTINUC] || \
	[$rtype == relations::CONSTIT]
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
