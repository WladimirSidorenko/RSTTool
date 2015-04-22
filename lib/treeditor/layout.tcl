#!/usr/bin/env wish
# -*- mode: tcl; -*-

##################################################################
namespace eval ::rsttool::treeditor::layout {
    variable SIZE_FACTOR 0;

    namespace export update-upwards;
    namespace export y-layout-subtree;
}

##################################################################
proc ::rsttool::treeditor::layout::redisplay-net {} {
    variable ::rsttool::NODES;
    variable ::rsttool::CRNT_MSGID;
    variable ::rsttool::PRNT_MSGID;
    variable ::rsttool::MSGID2ROOTS;
    variable ::rsttool::MSGID2EROOTS;
    variable ::rsttool::treeditor::WTN;
    variable ::rsttool::treeditor::RSTW;
    variable ::rsttool::treeditor::NODE_WIDTH;
    variable ::rsttool::treeditor::MESSAGE;
    variable ::rsttool::treeditor::DISCUSSION;
    variable ::rsttool::treeditor::DISPLAYMODE;
    variable ::rsttool::treeditor::VISIBLE_NODES;
    namespace import ::rsttool::utils::max;

    # 1. Clean up from earlier structures
    $RSTW delete all;
    array unset WTN;
    array set WTN {};
    # 2. Create necessary message roots
    if {![info exists MSGID2ROOTS($CRNT_MSGID)]} {set MSGID2ROOTS($CRNT_MSGID) {}}
    # decide, which nodes to display
    if {$DISPLAYMODE == $MESSAGE} {
	set roots2display $MSGID2ROOTS($CRNT_MSGID);
    } elseif {$PRNT_MSGID == {}} {
	if {! [info exists MSGID2EROOTS($CRNT_MSGID)]} {set MSGID2EROOTS($CRNT_MSGID) {}}
	set roots2display $MSGID2EROOTS($CRNT_MSGID);
    } else {
	if {! [info exists MSGID2EROOTS($PRNT_MSGID)]} {set MSGID2EROOTS($PRNT_MSGID) {}}
	set roots2display $MSGID2EROOTS($PRNT_MSGID);
    }

    # puts stderr "*** roots2display: roots2display = $roots2display";
    # puts stderr "*** redisplay-net: VISIBLE_NODES = [array names VISIBLE_NODES]";
    # 3. layout and draw
    # puts stderr "*** redisplay-net: x-layout: roots2display == $roots2display"
    x-layout $roots2display;
    # puts stderr "*** redisplay-net: x-layout passed"
    y-layout $roots2display;
    # puts stderr "*** redisplay-net: y-layout passed"

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

proc ::rsttool::treeditor::layout::x-layout {a_nodes {xpos {}}} {
    variable ::rsttool::NODES;
    variable ::rsttool::treeditor::NODE_WIDTH;
    variable ::rsttool::treeditor::CURRENT_XPOS;
    variable ::rsttool::treeditor::VISIBLE_NODES;
    variable ::rsttool::treeditor::MESSAGE;
    variable ::rsttool::treeditor::DISCUSSION;
    variable ::rsttool::treeditor::DISPLAYMODE;
    namespace import ::rsttool::treeditor::tree::node::egroup-node-p;
    namespace import ::rsttool::treeditor::tree::node::group-node-p;

    # sort nodes according to
    set xinc [expr $NODE_WIDTH + 10];
    if {$xpos == {}} {
	set xpos [expr $NODE_WIDTH / 2 + 30];
    }
    # puts stderr "x-layout: xpos = $xpos"
    foreach nid $a_nodes {
	if {![info exists VISIBLE_NODES($nid)]} {continue}
	# puts stderr "x-layout: nid = $nid ([group-node-p $nid])";
    	if {($DISPLAYMODE == $MESSAGE && [group-node-p $nid]) || \
		($DISPLAYMODE == $DISCUSSION && [egroup-node-p $nid])} {
    	    set xpos [xlayout-group-node $nid $xpos [expr ($DISPLAYMODE == $DISCUSSION)]];
    	} else {
    	    set NODES($nid,xpos) $xpos;
    	    set xpos [expr $xpos+$xinc];
    	}
    }
    set CURRENT_XPOS $xpos;
}

proc ::rsttool::treeditor::layout::xlayout-group-node {a_nid xpos {a_external {}}} {
    variable ::rsttool::NODES;
    variable ::rsttool::NID2MSGID;
    variable ::rsttool::treeditor::NODE_WIDTH;
    variable ::rsttool::treeditor::VISIBLE_NODES;
    variable ::rsttool::treeditor::NODE_WIDTH;
    variable ::rsttool::relations::PARATACTIC;
    namespace import ::rsttool::treeditor::tree::arc::group-relation-p;
    namespace import ::rsttool::treeditor::tree::node::get-start;
    namespace import ::rsttool::treeditor::tree::node::get-child-pos;
    namespace import ::rsttool::treeditor::tree::node::eparent-msgid-p;

    # only position nodes which are not yet positioned
    if {![info exists VISIBLE_NODES($a_nid)]} {return}
    # puts stderr "xlayout-group-node: a_nid = $a_nid, xpos = $xpos;"

    # 1. Collect x coordinates of constituents
    set x_coords {};
    set prnt_prfx ""; set chld_prfx "";
    if {$a_external} {
	set chld_prfx "e";
	if {[eparent-msgid-p $NID2MSGID($a_nid)]} {
	    set istart -1;
	} else {
	    set istart [get-child-pos $a_nid];
	}
    } else {
	set istart [get-start $a_nid];
    }
    # place all left children of the node
    set start {};
    # puts stderr "xlayout-group-node: a_external == $a_external";
    # puts stderr "xlayout-group-node: NODES($a_nid,${chld_prfx}children) = $NODES($a_nid,${chld_prfx}children);"
    # puts stderr "xlayout-group-node: eparent-msgid-p = [eparent-msgid-p $NID2MSGID($a_nid)]"
    foreach dep $NODES($a_nid,${chld_prfx}children) {
	# puts stderr "xlayout-group-node: dep = $dep;"
	#  [group-relation-p $node($dep,relname)]
	if {$a_external} {
	    if {[eparent-msgid-p $NID2MSGID($dep)]} {
		set prnt_prfx "";
		set start -1;
	    } else {
		set prnt_prfx "e";
		set start [get-child-pos $dep];
	    }
	} else {
	    set start [get-start $dep]
	}
	# puts stderr "xlayout-group-node: NODES($dep,${prnt_prfx}reltype) = $NODES($dep,${prnt_prfx}reltype);"
	# puts stderr "xlayout-group-node: start = $start; istart = $istart;"
	# puts stderr "xlayout-group-node: VISIBLE_NODES = [info exists VISIBLE_NODES($dep)];"
	if {![info exists VISIBLE_NODES($dep)] || \
		($start > $istart && ![group-relation-p $NODES($dep,${prnt_prfx}reltype)])} {
	    # puts stderr "xlayout-group-node: continue;"
	    continue;
	}
	# puts stderr "***xlayout-group-node: dep = $dep, dep start = [get-start $dep], istart = $istart";
	set xpos [xlayout-group-node $dep $xpos $a_external];
	if {[group-relation-p $NODES($dep,${prnt_prfx}reltype)]} {
	    # we want to place the node over its members, not satelites
	    lappend x_coords $NODES($dep,xpos)
	}
    }
    # position the node itself
    if { $x_coords == {} } {
	# group-node, but all children invisible
	# find the first visible text node BEFORE the first tn child
	set NODES($a_nid,xpos) $xpos;
	# puts stderr "xlayout-group-node: NODES($a_nid,xpos) = $NODES($a_nid,xpos);"
	set xpos [expr $xpos + $NODE_WIDTH + 10];
    } else {
	# puts stderr "xlayout-group-node: x_coords = $x_coords";
	set x_coords [join $x_coords ", "];
	set imin [expr min($x_coords)];
	set imax [expr max($x_coords)];
	set NODES($a_nid,xpos) [expr $imin + ($imax - $imin) / 2]
	# puts stderr "xlayout-group-node: NODES($a_nid,xpos) = $NODES($a_nid,xpos);"
    }
    # place all right children of the node
    foreach dep $NODES($a_nid,${chld_prfx}children) {
	if {$a_external} {
	    set imsgid $NID2MSGID($dep);
	    if {[eparent-msgid-p $imsgid]} {
		set prnt_prfx "";
		# puts stderr "***xlayout-group-node: start = -1"
		set start -1;
	    } else {
		set prnt_prfx "e";
		# puts stderr "***xlayout-group-node: start = get-child-pos = [get-child-pos $dep]"
		set start [get-child-pos $dep];
	    }
	} else {
	    set start [get-start $dep]
	}

	# puts stderr "***xlayout-group-node: right child dep = $dep, visible = [info exists VISIBLE_NODES($dep)]";
	# puts stderr "***xlayout-group-node: group-relation = [group-relation-p $NODES($dep,${prnt_prfx}reltype)]";
	# puts stderr "***xlayout-group-node: start = $start <= istart = $istart";
	if {![info exists VISIBLE_NODES($dep)] || \
		$start <= $istart || [group-relation-p $NODES($dep,${prnt_prfx}reltype)]} {
	    # puts stderr "***xlayout-group-node: right child continue";
	    continue;
	}
	set xpos [xlayout-group-node $dep $xpos $a_external];
    }
    # puts stderr "xlayout-group-node: return xpos = $xpos";
    return $xpos;
}

proc ::rsttool::treeditor::layout::y-layout {a_nodes} {
    variable ::rsttool::treeditor::Y_TOP;

    foreach nid $a_nodes {
	# display all subtrees with no further roots and those whose roots are
	# external nodes connecting two messages
	y-layout-subtree $nid $Y_TOP;
    }
}

proc ::rsttool::treeditor::layout::y-layout-subtree {a_nid {a_ypos {}}} {
    variable ::rsttool::NODES;
    variable ::rsttool::NID2MSGID;
    variable ::rsttool::treeditor::RSTW;
    variable ::rsttool::treeditor::VISIBLE_NODES;
    variable ::rsttool::treeditor::DISCUSSION;
    variable ::rsttool::treeditor::DISPLAYMODE;
    namespace import ::rsttool::treeditor::tree::ntw;
    namespace import ::rsttool::treeditor::tree::node::redisplay;
    namespace import ::rsttool::treeditor::tree::arc::group-relation-p;
    namespace import ::rsttool::treeditor::tree::node::eparent-msgid-p;

    # puts stderr "y-layout-subtree: a_nid = $a_nid, a_ypos = $a_ypos";
    # puts stderr "y-layout-subtree: VISIBLE_NODES = [array names VISIBLE_NODES]";
    # 1. Re-layout this node
    if {$a_ypos != {}} {
	set NODES($a_nid,ypos) $a_ypos;
    } else {
	if {[info exists NODES($a_nid,ypos)]} {
	    set a_ypos $NODES($a_nid,ypos);
	} else {
	    error "ypos not specified for node '$a_nid'.";
	    return;
	}
    }
    redisplay $a_nid;
    # puts stderr "y-layout-subtree: node $a_nid redisplayed";

    # 2. Re-layout children
    set chld_prfx ""; set prnt_prfx "";
    if {$DISPLAYMODE == $DISCUSSION} {
	set chld_prfx "e";
	if {![eparent-msgid-p $NID2MSGID($a_nid)]} {set prnt_prfx "e"}
    }
    set chld_ypos [expr [lindex [$RSTW bbox [ntw $a_nid]] 3] + 30]
    foreach cid $NODES($a_nid,${chld_prfx}children) {
	puts stderr "y-layout-subtree: cid = $cid";
    	if {[info exists VISIBLE_NODES($cid)] && $cid != $a_nid} {
	    # puts stderr "y-layout-subtree: cid is visible";
	    # paratactic child nodes should keep the y position of
	    # their parent
	    if {[group-relation-p $NODES($cid,${prnt_prfx}reltype)]} {
		y-layout-subtree $cid $chld_ypos;
	    } else {
		y-layout-subtree $cid $a_ypos;
	    }
	    # puts stderr "y-layout-subtree: display arc between $a_nid and $cid with type $NODES($cid,reltype)";
    	}
    }
}

proc ::rsttool::treeditor::layout::find-first-text-node {nid} {
    variable ::rsttool::NODES;

    #come back here
    if [text-node-p $nid] {return $nid}
    # this just returns A child -- we can work back from any child
    # since all children are invis.
    set cid [lindex $NODES($nid,children) 0]
    return [find-first-text-node $cid]
}

proc ::rsttool::treeditor::layout::previous-visible-node {nid} {
    variable ::rsttool::NODES;
    variable ::rsttool::TEXT_NODES;

    set pos [lsearch $text_nodes $nid];
    for {set i [expr $pos - 1]} {$i > 0} {incr i -1} {
	if $NODES($i,visible) {return $i}
    }
    return 0;
}

proc ::rsttool::treeditor::layout::update-upwards {a_gnid a_chld_nid} {
    variable ::rsttool::NODES;
    variable ::rsttool::treeditor::RSTW
    variable ::rsttool::treeditor::VISIBLE_NODES;
    namespace import ::rsttool::treeditor::tree::node::draw-span;
    namespace import ::rsttool::treeditor::tree::node::group-node-p;

    if {[group-node-p $a_gnid]} {
	set istart $NODES($NODES($a_gnid,start),start);
	set iend $NODES($NODES($a_gnid,end),end);

	# update start and end points of the node
	if {$NODES($a_chld_nid,start) < $istart} {
	    set NODES($a_gnid,start) $a_chld_nid;
	    set NODES($a_gnid,name) "$NODES($a_chld_nid,name)-$NODES($NODES($a_gnid,end),name)";
	} elseif {$NODES($a_chld_nid,end) > $iend} {
	    set NODES($a_gnid,end) $a_chld_nid;
	    set NODES($a_gnid,name) "$NODES($NODES($a_gnid,start),name)-$NODES($a_chld_nid,name)";
	} else {
	    return;
	}
	# redraw span lines for visible nodes
	if {[info exists VISIBLE_NODES($a_gnid)]} {
	    ::rsttool::treeditor::tree::node::redisplay $a_gnid;
	}
    }
    # update parent span
    if {[info exists NODES($a_gnid,parent)] && $NODES($a_gnid,parent) != {}} {
	update-upwards $NODES($a_gnid,parent) $a_chld_nid;
    }
}

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
    # puts stderr "sort-nodes: 1) a_list = $a_list"
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
    # puts stderr "sort-nodes: 2) a_list = $a_list"
    return $a_list;
}

##################################################################
package provide rsttool::treeditor::layout 0.0.1
return
