#!/usr/bin/env wish
# -*- mode: tcl; -*-

##################################################################
namespace eval ::rsttool::treeditor::layout {
    variable SIZE_FACTOR 0;
}

##################################################################
proc ::rsttool::treeditor::layout::redisplay-net {} {
    variable ::rsttool::NODES;
    variable ::rsttool::CRNT_MSGID;
    variable ::rsttool::PRNT_MSGID;
    variable ::rsttool::MSGID2ROOTS;
    variable ::rsttool::treeditor::WTN;
    variable ::rsttool::treeditor::RSTW;
    variable ::rsttool::treeditor::NODE_WIDTH;
    variable ::rsttool::treeditor::VISIBLE_NODES;
    namespace import ::rsttool::utils::max;

    puts stderr "redisplay-net: VISIBLE_NODES ="
    parray VISIBLE_NODES;
    # 1. Clean up from earlier structures
    $RSTW delete all;
    array unset WTN;
    array set WTN {};
    # 2. Create necessary message roots
    if {![info exists MSGID2ROOTS($PRNT_MSGID,$CRNT_MSGID)]} {
	set MSGID2ROOTS($PRNT_MSGID,$CRNT_MSGID) {};

	if [info exists MSGID2ROOTS($PRNT_MSGID)] {
	    set MSGID2ROOTS($PRNT_MSGID,$CRNT_MSGID) $MSGID2ROOTS($PRNT_MSGID);
	}
	if [info exists MSGID2ROOTS($CRNT_MSGID)] {
	    set MSGID2ROOTS($PRNT_MSGID,$CRNT_MSGID) \
		[concat $MSGID2ROOTS($PRNT_MSGID,$CRNT_MSGID) $MSGID2ROOTS($CRNT_MSGID)];
	}
    }

    # 3. layout and draw
    x-layout $MSGID2ROOTS($PRNT_MSGID,$CRNT_MSGID);
    y-layout $MSGID2ROOTS($PRNT_MSGID,$CRNT_MSGID);

    # 4. scroll to the region of the latest activity
    set ymax 0
    set xmax 0
    foreach nid [array names VISIBLE_NODES] {
    	set ymax [max $ymax $NODES($nid,ypos)]
    	set xmax [max $xmax $NODES($nid,xpos)]
    }

    $RSTW configure -scrollregion "0 1 [expr  $xmax + $NODE_WIDTH]\
          [expr $ymax + 130]"
}

proc ::rsttool::treeditor::layout::x-layout {a_nodes} {
    variable ::rsttool::NODES;
    variable ::rsttool::treeditor::NODE_WIDTH;
    variable ::rsttool::treeditor::CURRENT_XPOS;
    namespace import ::rsttool::treeditor::tree::node::group-node-p;

    # sort nodes according to
    set xinc [expr $NODE_WIDTH + 10]
    set xpos [expr $NODE_WIDTH / 2 + 30]
    foreach nid $a_nodes {
    	if [group-node-p $nid] {
    	    set xpos [xlayout-group-node $nid];
    	} else {
    	    set NODES($nid,xpos) $xpos
    	    set xpos [expr $xpos+$xinc]
    	}
    }
    set CURRENT_XPOS $xpos
}

proc ::rsttool::treeditor::layout::xlayout-group-node {a_nid a_msgid1 a_msgid2} {
    variable ::rsttool::NODES;
    variable ::rsttool::treeditor::NODE_WIDTH;
    variable ::rsttool::treeditor::VISIBLE_NODES;
    namespace import ::rsttool::utils::max;
    namespace import ::rsttool::utils::min;

    # only position nodes which are not yet positioned
    if {$NODES($nid,xpos) != {}} {return}

    # 1. Collect x coords of constituents
    set x_coords {}
    foreach dep $NODES($a_nid,children) {
	#  [group-relation-p $node($dep,relname)]
	if [info exists VISIBLE_NODES($dep)] {
	    if { !$NODES($dep,xpos) } {
		xlayout-group-node $dep
	    }
	    if [group-relation-p $NODES($dep,reltype)] {
		# we want to place the node over its members, not satelites
		lappend x_coords $NODES($dep,xpos)
	    }
	}
    }

    if { $x_coords == {} } {
	# group-node, but all children invisible
	# find the first visible text node BEFORE the first tn child
	set first_tn [find-first-text-node $nid]
	set prev_node [previous-visible-node $first_tn]
	if { $prev_node > 0 } {
	    set NODES($nid,xpos) [expr $NODES($prev_node,xpos) + $NODE_WIDTH + 10];
	} else {
	    set NODES($nid,xpos) [expr $NODE_WIDTH + 10];
	}
    } else {
	set imin [expr min($x_coords)];
	set imax [expr max($x_coords)];
	set NODES($nid,xpos) [expr $imin + ($imax - $imin) / 2]
    }
}

proc ::rsttool::treeditor::layout::y-layout {a_nodes} {
    variable ::rsttool::NODES
    variable ::rsttool::treeditor::VISIBLE_NODES
    variable ::rsttool::treeditor::Y_TOP;

    foreach nid $a_nodes {
	# display all subtrees with no further roots and those whose roots are
	# external nodes connecting two messages
	y-layout-subtree $nid $Y_TOP;
    }
}

proc ::rsttool::treeditor::layout::y-layout-subtree {a_nid {a_ypos {}}} {
    variable ::rsttool::NODES;
    variable ::rsttool::treeditor::RSTW;
    variable ::rsttool::treeditor::VISIBLE_NODES;
    namespace import ::rsttool::treeditor::tree::ntw;
    namespace import ::rsttool::treeditor::tree::arc::group-relation-p;

    puts stderr "y-layout-subtree: a_nid = $a_nid";
    # 1. Re-layout this node
    if {$a_ypos != {}} {
	set NODES($a_nid,ypos) $a_ypos;
    } else {
	set a_ypos $NODES($a_nid,ypos);
    }
    ::rsttool::treeditor::tree::node::redisplay $a_nid;

    # 2. Re-layout children
    set chld_ypos [expr [lindex [$RSTW bbox [ntw $a_nid]] 3] + 30]
    foreach cid $NODES($a_nid,children) {
    	if {[info exists VISIBLE_NODES($cid)] && $cid != $a_nid} {
	    # paratactic child nodes should keep the y position of
	    # their parent
	    if {[group-relation-p $NODES($cid,reltype)]} {
		y-layout-subtree $cid $chld_ypos;
	    } else {
		y-layout-subtree $cid $a_ypos;
	    }
	    ::rsttool::treeditor::tree::arc::display $a_nid $cid;
    	}
    }
}

# proc ::rsttool::treeditor::layout::y-layout-node {nid} {
#     variable ::rsttool::NODES;
#     variable ::rsttool::treeditor::RSTW;
#     variable ::rsttool::relations::SPAN;
#     variable ::rsttool::treeditor::Y_TOP;
#     variable ::rsttool::treeditor::VISIBLE_NODES;
#     namespace import ::rsttool::treeditor::tree::arc::group-relation-p;

#     # puts stderr "y-layout-node: nid = $nid"
#     #  Position this node under its parent
#     set nuc $NODES($nid,parent);
#     # 1. Position this node
#     if {$nuc == {} || ![info exists VISIBLE_NODES($nuc)]} {
# 	# toplevel node - position at top
# 	set NODES($nid,ypos) $Y_TOP
#     } elseif {[group-relation-p $NODES($nid,reltype)] == $SPAN} {
# 	# group node - position under parent
# 	# puts stderr "y-layout-node: set node($nid,ypos) [expr [lindex [$rstw bbox [ntw $nuc]] 3] + 30]"
# 	set NODES($nid,ypos) [expr [lindex [$RSTW bbox [ntw $nuc]] 3] + 30]
#     } else {
# 	# puts stderr "y-layout-node: set node($nid,ypos)  $node($nuc,ypos)"
# 	set NODES($nid,ypos) $node($nuc,ypos)
#     }
#     ::rsttool::treeditor::tree::node::redisplay $nid
# }

# proc ::rsttool::treeditor::layout::find-first-text-node {nid} {
#     variable ::rsttool::NODES;

#     #come back here
#     if [text-node-p $nid] {return $nid}
#     # this just returns A child -- we can work back from any
#     # child since all children are invis.
#     set cid [lindex [lsort -integer $NODES($nid,children)] 0]
#     if [text-node-p $cid] {
# 	return $cid
#     } else {
# 	return [find-first-text-node $cid]
#     }
# }

# proc ::rsttool::treeditor::layout::previous-visible-node {nid} {
#     variable ::rsttool::NODES;
#     variable ::rsttool::TEXT_NODES;

#     set pos [lsearch $text_nodes $nid]
#     for {set i [expr $pos - 1]} {$i > 0} {incr i -1} {
# 	if $NODES($i,visible) {return $i}
#     }
#     return 0
# }

proc ::rsttool::treeditor::layout::resize-display {change} {
    variable ::rsttool::NODES;
    variable ::rsttool::treeditor::RSTW;
    variable ::rsttool::treeditor::NODE_WIDTH;
    variable ::rsttool::treeditor::VISIBLE_NODES;
    variable SIZE_FACTOR;

    set ymax 0
    set xmax 0
    set SIZE_FACTOR [expr $SIZE_FACTOR + $change]
    foreach nid [array names VISIBLE_NODES] {
	set ymax [max $ymax $NODES($nid,ypos)]
	set xmax [max $xmax $NODES($nid,xpos)]
    }
    $RSTW configure -scrollregion "0 1 [expr $xmax + $NODE_WIDTH]\
	     [expr $ymax + $SIZE_FACTOR]"
}

# proc ::rsttool::treeditor::layout::adjust-after-change {nuc sat {redraw 0}} {
#     # Adjust nucleus
#     # puts stderr "link-par-to-child: restructure-upwards nuc = $nuc redraw = $redraw"
#     restructure-upwards $nuc $redraw

#     # Ajust satellite
#     if $redraw {
# 	# puts stderr "link-par-to-child: y-layout-subtree sat = $sat"
# 	y-layout-subtree $sat
#     }
# }

# proc ::rsttool::treeditor::layout::restructure-upwards {nid {redraw 0}} {
#     variable ::rsttool::NODES;
#     variable ::rsttool::treeditor::VISIBLE_NODES;

#     # puts stderr "restructure-upwards: $nid $redraw"

#     # stop when no change in span nor in pos of node
#     set adjust_needed 0

#     # 1. if the current node is a group node, its pos and span may
#     # need to be adjusted
#     if { [::rsttool::treeditor::tree::node::group-node-p $nid] } {

# 	# a) If a group node, adjust its x position
# 	if { $redraw } {
# 	    set NODES($nid,xpos) 0
# 	    xlayout-group-node $nid
# 	    set adjust_needed 1
# 	}

# 	# b) Adjust span of this node
# 	set span [tree::node::find-node-span $nid]

# 	if {$span != $NODES($nid,span)} {
# 	    # span has changed
# 	    set NODES($nid,span) $span
# 	    # change the displayed text
# 	    set NODES($nid,text) [make-span-label $span]
# 	    # mark a change has taken place
# 	    set adjust_needed 1
# 	}

# 	#  c) redraw this node if needed
# 	if { $adjust_needed && $redraw && [info exists VISIBLE_NODES($nid)]} {
# 	    # check if the node has been drawn before
# 	    tree::node::redisplay-node $nid
# 	    tree::arcs::redraw-child-arcs $nid
# 	}

#     } else {
# 	# redisplay-node $nid
# 	set adjust_needed 1
#     }

#     # 2. adjusts the span of parent nodes considering the expansion
#     # of the current node.
#     # Apply to parent also
#     set par $NODES($nid,parent)
#     if { $adjust_needed  && $par != {} && $par != $nid} {
# 	restructure-upwards $par $redraw
#     }
# }

proc ::rsttool::treeditor::layout::visible-children-p {nid} {
    variable ::rsttool::NODES;
    variable ::rsttool::treeditor::VISIBLE_NODES;

    foreach cid $NODES($nid,children) {
	if [info exists VISIBLE_NODES($nid)] {return 1}
    }
    return 0
}

proc ::rsttool::treeditor::layout::sort-nodes {a_list } {
    puts stderr "sort-nodes: 1) a_list = $a_list"
    # create custom comparison function
    proc vsort {a_nid1 a_nid2} {
	variable ::rsttool::NID2MSGID;
	variable ::rsttool::PRNT_MSGID;
	if {$NID2MSGID($a_nid1) == $NID2MSGID($a_nid2)} {
	    return [::rsttool::treeditor::tree::node::cmp $a_nid1 $a_nid2];
	} elseif {$NID2MSGID($a_nid1) == $PRNT_MSGID} {
	    return -1;
	} else {
	    return 1;
	}
    }
    set a_list [lsort -command vsort $a_list];
    puts stderr "sort-nodes: 2) a_list = $a_list"
    return $a_list;
}

##################################################################
package provide rsttool::treeditor::layout 0.0.1
return
