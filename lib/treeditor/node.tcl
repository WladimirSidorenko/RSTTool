#!/usr/bin/env wish
# -*- mode: tcl; -*-

##################################################################
namespace eval ::rsttool::treeditor::tree::node {
    namespace export bisearch;
    namespace export draw-span;
    namespace export draw-text;
    namespace export eparent-msgid-p;
    namespace export get-child-pos;
    namespace export get-end-node;
    namespace export get-end;
    namespace export get-start-node;
    namespace export get-start;
    namespace export get-visible-parent;
    namespace export get-eparent;
    namespace export egroup-node-p;
    namespace export group-node-p;
    namespace export insort;
    namespace export make-name;
    namespace export redisplay;
    namespace export set-text;
    namespace export show-nodes;
    namespace export text-node-p;
}

##################################################################
proc ::rsttool::treeditor::tree::node::make {type {start {}} {end {}} \
						 {name {}} {msgid {}} {nid {}} {external 0}} {
    variable ::rsttool::NODES;
    variable ::rsttool::FORREST;
    variable ::rsttool::NAME2NID;
    variable ::rsttool::CRNT_MSGID;
    variable ::rsttool::MSGID2ROOTS;
    variable ::rsttool::MSGID2TNODES;
    variable ::rsttool::NID2MSGID;
    variable ::rsttool::treeditor::VISIBLE_NODES;

    if {$msgid == {}} {
	set msgid $CRNT_MSGID;
    }

    set prfx "";
    if {$external} {set prfx "e";}

    if {$type ==  "text"} {
	if {$name == {}} {set name [unique-tnode-name]};
	if {$nid == {}} {set nid [unique-tnode-id]; set VISIBLE_NODES($nid) 1};

	# save mapping from message id to node id
	if {![info exists MSGID2ROOTS($msgid)]} {set MSGID2ROOTS($msgid) {};}
	if {![info exists MSGID2TNODES($msgid)]} {set MSGID2TNODES($msgid) {}}
	# since we might add node after some group nodes were created,
	# we need to re-sort the node list
	# puts stderr "node::make: 0) MSGID2TNODES($msgid) = $MSGID2TNODES($msgid)"
	set MSGID2TNODES($msgid) [insort $MSGID2TNODES($msgid) $start $nid];
	# puts stderr "node::make: 1) MSGID2TNODES($msgid) = $MSGID2TNODES($msgid)"
    } else {
	if {$nid == {}} {
	    set nid [unique-gnode-id];
	    set VISIBLE_NODES($nid) 1;
	    if {$name == {}} {
		set name [make-name $start $end $external];
	    }
	}
    }
    # save mapping from node id to message id
    set NID2MSGID($nid) [list $msgid];
    set NODES($nid,children) {};
    set NODES($nid,echildren) {};
    set NODES($nid,end) $end;
    set NODES($nid,name) $name;
    set NODES($nid,parent) {};
    set NODES($nid,eparent) {};
    set NODES($nid,relname) {};
    set NODES($nid,erelname) {};
    set NODES($nid,reltype) {};
    set NODES($nid,ereltype) {};
    set NODES($nid,external) $external;
    set NODES($nid,start) $start;
    set NODES($nid,type) {};
    set NODES($nid,etype) {};
    set NODES($nid,${prfx}type) $type;
    set NAME2NID($msgid,$name) $nid;
    set-text $nid $msgid;
    return $nid;
}

proc ::rsttool::treeditor::tree::node::make-name {a_start a_end a_external} {
    variable ::rsttool::NODES;

    if {$a_external} {
	if {[is-prnt-p $a_start $a_end]} {
	    set sname -1;
	    set ename [get-child-pos $a_end];
	} elseif {[is-prnt-p $a_end $a_start]} {
	    set sname -1;
	    set ename [get-child-pos $a_start];
	} else {
	    set sname [get-child-pos $a_start];
	    set ename [get-child-pos $a_end];
	}
	incr sname; incr ename;
    } else {
	puts stderr "make-name: a_start = $a_start: [get-start-node $a_start]"
	puts stderr "make-name: a_end = $a_end: [get-end-node $a_end]"
	set sname $NODES([get-start-node $a_start],name);
	set ename $NODES([get-end-node $a_end],name);
    }
    return "$sname-$ename";
}

proc ::rsttool::treeditor::tree::node::get-visible-parent {a_nid} {
    variable ::rsttool::NODES;
    variable ::rsttool::treeditor::VISIBLE_NODES;
    namespace import ::rsttool::treeditor::tree::arc::group-relation-p;

    # puts stderr "get-visible-parent: a_nid = $a_nid; a_nid,; parent = $NODES($a_nid,parent) "
    # puts stderr "get-visible-parent: parent is visible? [info exists VISIBLE_NODES($a_nid,parent)] "
    # puts stderr "get-visible-parent: group-relation-p = [group-relation-p $NODES($a_nid,reltype)]"
    if {$NODES($a_nid,parent) != {} && [info exists VISIBLE_NODES($NODES($a_nid,parent))] && \
	    [group-relation-p $NODES($a_nid,reltype)]} {
	return [get-visible-parent $NODES($a_nid,parent)];
    }
    return $a_nid;
}

proc ::rsttool::treeditor::tree::node::get-eparent {a_nid} {
    variable ::rsttool::NODES;

    if {$NODES($a_nid,eparent) != {}} {
	return [get-eparent $NODES($a_nid,eparent)];
    } else {
	return $a_nid;
    }
}

proc ::rsttool::treeditor::tree::node::get-start {a_nid} {
    variable ::rsttool::NODES;

    # puts stderr "get-start: a_nid = $a_nid;"
    if {[group-node-p $a_nid]} {
	return [get-start $NODES($a_nid,start)];
    }
    return $NODES($a_nid,start);
}

proc ::rsttool::treeditor::tree::node::get-start-node {a_nid} {
    variable ::rsttool::NODES;

    if {[group-node-p $a_nid]} {return $NODES($a_nid,start);}
    return $a_nid;
}

proc ::rsttool::treeditor::tree::node::get-end {a_nid} {
    variable ::rsttool::NODES;

    if {[group-node-p $a_nid]} {
	puts stderr "node::get-end: a_nid = $a_nid (end = $NODES($a_nid,end))";
	return [get-end $NODES($a_nid,end)];
    } else {
	puts stderr "node::get-end: a_nid = $a_nid (NODES($a_nid,children) == $NODES($a_nid,children))";
	if {$NODES($a_nid,children) == {}} {
	    return $NODES($a_nid,end);
	} else {
	    set chld_end [get-end [lindex $NODES($a_nid,children) end]];
	    return [expr max($NODES($a_nid,end),$chld_end)];
	}
    }
}

proc ::rsttool::treeditor::tree::node::get-end-node {a_nid} {
    variable ::rsttool::NODES;

    if {[group-node-p $a_nid]} {return $NODES($a_nid,end)}
    return $a_nid;
}

proc ::rsttool::treeditor::tree::node::get-child-pos {a_nid} {
    variable ::rsttool::FORREST;
    variable ::rsttool::NID2MSGID;

    set msgid $NID2MSGID($a_nid);
    puts stderr "get-child-pos: a_nid == $a_nid; msgid = $msgid"
    set prnt_msgid [lindex $FORREST($msgid) 1];
    puts stderr "get-child-pos: a_nid == $a_nid; prnt_msgid = $prnt_msgid"
    if {$prnt_msgid == {}} {return -1}
    return [lsearch [lindex $FORREST($prnt_msgid) end] $msgid];
}

proc ::rsttool::treeditor::tree::node::set-text {a_nid {a_msgid {}}} {
    variable ::rsttool::NODES;
    variable ::rsttool::FORREST;
    variable ::rsttool::CRNT_MSGID;

    set start $NODES($a_nid,start);
    set end $NODES($a_nid,end);
    if {$NODES($a_nid,type) ==  "text"} {
	if {$a_msgid == {}} {set a_msgid $CRNT_MSGID;}
	if {$a_msgid == {}} {error "Empty message id."; return;}
	set ntext [string range [lindex $FORREST($a_msgid) 0] $start $end];
	set ntext [::rsttool::utils::strip $ntext];
	regsub -all "\"" $ntext "" ntext;
	set NODES($a_nid,text) "$ntext";
    } else {
	set NODES($a_nid,text) "";
    }
}

proc ::rsttool::treeditor::tree::node::unique-tnode-id {} {
    variable ::rsttool::TXT_NODE_CNT;
    return [incr TXT_NODE_CNT];
}

proc ::rsttool::treeditor::tree::node::unique-tnode-name {} {
    variable ::rsttool::MSG_TXT_NODE_CNT;
    return [incr MSG_TXT_NODE_CNT];
}

proc ::rsttool::treeditor::tree::node::unique-gnode-id {} {
    variable ::rsttool::GROUP_NODE_CNT;
    return [incr GROUP_NODE_CNT -1];
}

proc ::rsttool::treeditor::tree::node::unique-gnode-name {} {
    variable ::rsttool::MSG_GRP_NODE_CNT;
    return [incr MSG_GRP_NODE_CNT];
}

proc ::rsttool::treeditor::tree::node::cmp {a_nid1 a_nid2} {
    variable ::rsttool::NODES;

    if {! [info exists NODES($a_nid1,start)]} {return -1};
    if {! [info exists NODES($a_nid2,start)]} {return 1};
    return [expr [get-start $a_nid1] - [get-start $a_nid2]];
}

proc ::rsttool::treeditor::tree::node::show-nodes {msg_id {show 1}} {
    # set visibility status for all internal nodes belonging to the message
    # `$msg_id` to $show
    variable ::rsttool::NODES;
    variable ::rsttool::NID2MSGID
    variable ::rsttool::CRNT_MSGID;
    variable ::rsttool::PRNT_MSGID;
    variable ::rsttool::MSGID2ROOTS;
    variable ::rsttool::MSGID2EROOTS;
    variable ::rsttool::treeditor::MESSAGE;
    variable ::rsttool::treeditor::DISCUSSION;
    variable ::rsttool::treeditor::DISPLAYMODE;
    variable ::rsttool::treeditor::VISIBLE_NODES;

    if {! [info exists MSGID2ROOTS($msg_id)]} {return}
    # show/hide internal nodes pertaining to message `msg_id`
    if {$show} {
	if {$DISPLAYMODE == $MESSAGE} {
	    set inodes $MSGID2ROOTS($msg_id);
	} else {
	    if {! [info exists MSGID2EROOTS($msg_id)]} {set MSGID2EROOTS($msg_id) {}}
	    set inodes $MSGID2EROOTS($msg_id);
	}
	puts stderr "show-nodes: 0) DISPLAYMODE = $DISPLAYMODE, msg_id = $msg_id, inodes = $inodes";
	set inid {};
	while {$inodes != {}} {
	    # pop first node on the queue
	    set inid [lindex $inodes 0];
	    set inodes [lreplace $inodes 0 0];
	    # pop first node on the queue
	    if {$DISPLAYMODE == $MESSAGE && $NID2MSGID($inid) != $msg_id} {continue;}
	    if {$DISPLAYMODE == $DISCUSSION && !$NODES($inid,external)} {continue;}
	    set VISIBLE_NODES($inid) 1
	    set inodes [concat $inodes $NODES($inid,children)];
	}
    } else {
	namespace import ::rsttool::utils::reset-array;
	reset-array ::rsttool::treeditor::VISIBLE_NODES;
    }
    # puts stderr "show-nodes: 1) DISPLAYMODE = $DISPLAYMODE; VISIBLE_NODES = [array names VISIBLE_NODES];";
}

proc ::rsttool::treeditor::tree::node::erase {a_nid} {
    variable ::rsttool::NODES;
    variable ::rsttool::treeditor::RSTW;
    variable ::rsttool::treeditor::WTN;
    variable ::rsttool::treeditor::VISIBLE_NODES;
    namespace import ::rsttool::treeditor::tree::ntw;

    # puts stderr "erase-node:  erasing nid = $a_nid"
    set a_wdgt [ntw $a_nid];
    if {$a_wdgt != {}} {
	$RSTW delete $a_wdgt;
	array unset WTN $a_wdgt;
    }
    if {[info exists NODES($a_nid,spanwgt)]} {
	$RSTW delete $NODES($a_nid,spanwgt);
	array unset NODES $a_nid,spanwgt;
    }
    if {[info exists NODES($a_nid,textwgt)]} {
	$RSTW delete $NODES($a_nid,textwgt);
	array unset NODES $a_nid,textwgt;
    }
    ::rsttool::treeditor::tree::arc::erase $a_nid;
}

proc ::rsttool::treeditor::tree::node::destroy {nid {redraw 1}} {
    # 1. unlink node if still connected
    ::rsttool::treeditor::tree::unlink $nid 0

    # 2. delete the graphic presentation
    erase $nid

    # 3. remove node from visible node list and drop all its
    # structural information
    clear $nid
}

proc ::rsttool::treeditor::legal-node {the_node {prev_node {}} } {
    variable ::rsttool::NODES
    variable ::rsttool::NEWEST_NODE

    if {$the_node == $NEWEST_NODE} {return $the_node}

    if { $prev_node == {} } {
	set prev_node $NEWEST_NODE
	if { $NODES($NEWEST_NODE,parent) == {} } {
	    incr prev_node -1
	}
    }

    if { $prev_node != 0 } {
	if { $the_node == $prev_node } {
	    return $the_node
	} else {
	    if {$NODES($prev_node,parent) == {}} {
		return 0
	    } else {
		legal-node $the_node $NODES($prev_node,parent)
	    }
	}
    } else {
	return 0
    }
}

proc ::rsttool::treeditor::ymove-node {nid ydelta} {
    variable ::rsttool::NODES;
    variable ::rsttool::treeditor::RSTW;

    # change its pos
    move-item $RSTW [ntw $nid] 0 $ydelta

    # move its arrow down the distance
    if [info exists NODES($nid,arrowwgt)] {
	move-item $RSTW $NODES($nid,arrowwgt)   0 $ydelta
	move-item $RSTW $NODES($nid,spanwgt) 0 $ydelta
	move-item $RSTW $NODES($nid,labelwgt)   0 $ydelta
    }

    # Move its children down
    foreach child $NODES($nid,children) {
	ymove-node $child $ydelta
    }
}

# Delete node `nid` and re-link its possible child to the parent of node `nid`
proc ::rsttool::treeditor::destroy-group-node {gnid {replnid {}} {redraw 1}} {
    global node nid2msgid msgs2extnid

    if {$gnid == {}} {return}
    set prnt_msg_id $nid2msgid($gnid)
    # remove group node which connects two messages from msgs2extnid
    if {[llength $prnt_msg_id] > 1} {
	set msgkey [join $prnt_msg_id ","]
	# puts stderr "destroy-group-node: msgs2extnid($msgkey)"
	if [info exists msgs2extnid($msgkey)] {
	    # puts stderr "destroy-group-node: msgs2extnid($msgkey) exists - deleting"
	    unset msgs2extnid($msgkey)
	}
    }
    # delete `gnid` from the list of children of its parent
    set gprnt $NODES($gnid,parent)
    set node($gnid,parent) {}
    if {$gprnt != {}} {
	set node($gprnt,children) [concat [ldelete $NODES($gprnt,children) $gnid] $replnid]
    }
    # append relacement node to the list of grand parent's children;
    # re-link all children of `gnid` to `replnid` except `replnid`
    # itself
    if {$replnid != {}} {
	set node($replnid,parent) $gprnt
	set node($gnid,children) [ldelete $NODES($gnid,children) $replnid]
	set node($replnid,children) [lsort -integer [concat $NODES($replnid,children) \
							 $NODES($gnid,children)]]
	if {$NODES($replnid,relname) == "span"} {
	    set node($replnid,relname) $NODES($gnid,relname)
	}
    }
    foreach chnid $NODES($gnid,children) {
	set node($chnid,parent) $replnid
	set chld_msg_id $nid2msgid($chnid)
	# if `gnid` has children in other messages, then update
	# information stored in msgs2extnid
	if {[llength $prnt_msg_id] == 1 && $prnt_msg_id != $chld_msg_id} {
	    set msgkey "$prnt_msg_id,$chld_msg_id"
	    # puts stderr "destroy-group-node: msgkey = $msgkey"
	    if [info exists msgs2extnid($msgkey)] {
		# puts stderr "destroy-group-node: msgs2extnid($msgkey) exists"
		while {[set idx [lsearch -exact $msgs2extnid($msgkey) $gnid]] != -1} {
		    set msgs2extnid($msgkey) [lreplace $msgs2extnid($msgkey) $idx $idx $replnid]
		}
		# update children in external nodes that connect
		# multiple messages
		foreach {prntid chldid relname} $msgs2extnid($msgkey) {
		    if {$chldid == $replnid && $prntid != $gprnt} {
			set idx [lsearch -exact $NODES($prntid,children) $gnid]
			set node($prntid,children) [lreplace $NODES($prntid,children) \
							$idx $idx $replnid]
			# update span information of the parent
			restructure-upwards $prntid 0
		    }
		}
	    }
	}
    }
    # remove all children from `gnid`
    # puts stderr "destroy-group-node: erase-subtree $gnid"
    erase-subtree $gnid
    set node($gnid,children) {}
    # puts stderr "destroy-group-node: destroy-node $gnid $redraw"
    destroy-node $gnid $redraw
}

proc ::rsttool::treeditor::set-subtree-node-span {nid} {
    global node

    # this function is like reset-parent-node-span, but works downwards

    #1. Ensure span of all children is known
    foreach child $NODES($nid,children) {
	if { $NODES($child,span) == {} || [text-node-p $child]} {
	    set-subtree-node-span $child
	}
    }

    #2. Set span of present node
    set node($nid,span) [find-node-span $nid]

    #3. change the displayed text
    if { $NODES($nid,type) != "text" } {
	set node($nid,text) [make-span-label $NODES($nid,span)]
    }
}

proc ::rsttool::treeditor::make-span-label {span} {
    # returns a text-label for the span
    if { [lindex $span 0] == [lindex $span 1] } {
	return "[lindex $span 0]"
    } else {
	return "[lindex $span 0]-[lindex $span 1]"
    }
}


proc ::rsttool::treeditor::find-node-span {nid} {
    global node nid2msgid

    # Span depends on node-type
    switch -- $NODES($nid,type) {

	span { # span is min/max of nuc and all satellites
	    set min Inf
	    set max -1
	    set msgids $nid2msgid($nid)
	    foreach child $NODES($nid,children) {
		if { ($NODES($child,relname) == "span" \
			  || [constit-relation-p $NODES($child,relname)]) && \
			 [lsearch -exact $msgids $nid2msgid($child)] != -1} {
		    set min [min [lindex $NODES($child,span) 0] $min]
		    set max [max [lindex $NODES($child,span) 1] $max]
		    foreach sat $NODES($child,children) {
			set min [min [lindex $NODES($sat,span) 0] $min]
			set max [max [lindex $NODES($sat,span) 1] $max]
		    }
		}
	    }
	    # if no span node yet (not yet read in)
	    # use the existingb rel (there must be an rst rel)
	    if {$min == Inf} {
		set min [lindex $NODES($nid,children) 0]
		set max $min
	    }
	}
	text { set min $nid; set max $nid }
	default { # dealing with multinuc or constit node
	    set min 99999
	    set max  0
	    foreach child $NODES($nid,children) {
		#come back here
		#               set min [min $child $min]
		#	       if { $child <= 5000 } {
		#                 set max [max $child $max]
		#	       }
		if [group-relation-p $NODES($child,relname)] {
		    set min [min [lindex $NODES($child,span) 0] $min]
		    if { [lindex $NODES($child,span) 1] <= 5000 } {
			set max [max [lindex $NODES($child,span) 1] $max]
		    }
		}
	    }
	}
    }

    set result "$min $max"
    return "$min $max"
}


##################################################
#  Collapse or Expand Nodes

proc ::rsttool::treeditor::collapse {nid {really {}} } {
    variable RSTW
    global node collapsed_nodes

    if {![info exists node($nid,text)]} {return}

    #  if { [legal-node $nid] != 0 } {
    #    foreach child  $NODES($nid,children) {
    #      collapse $child really
    #    }
    #  } else {
    # try to collapse all children
    foreach child  $NODES($nid,children) {
	if $NODES($child,visible) {
	    set in_list [lsearch -exact $collapsed_nodes $nid]
	    if { "$in_list" == "-1" } {
		lappend collapsed_nodes $nid
	    }
	    hide-node $child
	    set really fake
	}
    }

    # Scroll to new position
    xscrollto [max [expr $NODES($nid,xpos) - 50] 0]
    #  }
}

proc ::rsttool::treeditor::expand {nid {really {}} } {
    variable RSTW
    global node collapsed_nodes

    if {![info exists node($nid,text)]} {return}

    foreach child  $NODES($nid,children) {
	expand $child really

	set junk [lsearch -exact $collapsed_nodes $nid]
	if { "$junk" != "-1" } {
	    set collapsed_nodes [lreplace $collapsed_nodes $junk $junk]
	}
	foreach child  $NODES($nid,children) {
	    show-node $child
	}

	# Scroll to new position
	# collapsed - scroll to the new node position
	xscrollto [max [expr $NODES($nid,xpos) - 50] 0]
    }
}
#END

proc ::rsttool::treeditor::hide-node {nid} {
    global node visible_nodes
    if {[info exists visible_nodes($nid)]} {
	unset visible_nodes($nid)
	foreach cid $NODES($nid,children) {
	    hide-node $cid
	}
    } else {
	return
    }
}

proc ::rsttool::treeditor::show-node {nid} {
    global node visible_nodes
    set visible_nodes($nid) 1
    foreach cid $NODES($nid,children) {
	show-node $cid
    }
}

proc ::rsttool::treeditor::describe-node {nid} {

    global node
    puts "id $nid"
    puts "text $NODES($nid,text)"
    puts "type $NODES($nid,type)"
    puts "textwgt $NODES($nid,textwgt)"
    puts "labelwgt $NODES($nid,labelwgt)"
    puts "arrowwgt $NODES($nid,arrowwgt)"
    puts "spanwgt $NODES($nid,spanwgt)"
    puts "relname $NODES($nid,relname)"
    puts "children $NODES($nid,children)"
    puts "parent $NODES($nid,parent)"
    puts "constituents $NODES($nid,constituents)"
    puts "visible $NODES($nid,visible)"
    puts "span $NODES($nid,span)"
    puts "xpos $NODES($nid,xpos)"
    puts "ypos $NODES($nid,ypos)"
    puts "oldindex $NODES($nid,oldindex)"
    puts "newindex $NODES($nid,newindex)"
    puts "promotion $NODES($nid,promotion)"
}

proc ::rsttool::treeditor::dn {nid} {describe-node $nid}

proc ::rsttool::treeditor::tree::node::disconnect_node {clicked_node method} {
    variable ::rsttool::NODES;
    variable ::rsttool::treeditor::DISCO_NODE;
    variable::rsttool::treeditor::ERASED_NODES;

    #we only allow disconnection of satellites and multinucs
    set relation $NODES($clicked_node,relname)
    set par $NODES($clicked_node,parent)
    # puts stderr "disconnect_node: clicked_node = $clicked_node"
    # puts stderr "disconnect_node: method = $method"
    # puts stderr "disconnect_node: relation = $relation"
    # puts stderr "disconnect_node: par = $par"
    if {$par == {} || $relation == "span" || $DISCO_NODE != {}} {
    } else {

	#disconnect node from parent
	set node($clicked_node,parent) {}
	set node($clicked_node,relname) {}
	redisplay-node $clicked_node

	#disconnect parent from node
	set index [lsearch $NODES($par,children) $clicked_node]
	set node($par,children) [lreplace $NODES($par,children) $index $index]
	adjust-after-change $par $par 1

	#clean up any extra spans or single multinuclear relations
	set sibling {}
	if {[relation-type $relation] == "rst"} {
	    foreach child $NODES($par,children) {
		if {[relation-type $NODES($child,relname)] == "rst" || \
			[relation-type $NODES($child,relname)] == "embedded"} {
		    lappend sibling $child
		}
	    }
	    if {$sibling == {}} {
		###########
		#extra span
		###########
		set grandpar $NODES($par,parent)
		set greatgrand $NODES($grandpar,parent)

		#put par in grandpar position
		#sibling gets grandpar's children
		foreach child $NODES($grandpar,children) {
		    if {$child != $par} {
			set node($child,parent) $par
			lappend node($par,children) $child
		    }
		}
		set node($par,parent) $greatgrand
		set node($par,relname) $NODES($grandpar,relname)
		if {$greatgrand != {}} {
		    #there is a greatgrandparent
		    #greatgrand gets par as child
		    set index [lsearch $NODES($greatgrand,children) $grandpar]
		    set node($greatgrand,children)\
			[lreplace $NODES($greatgrand,children) $index $index $par]
		}
		#eliminate grandpar
		clear $grandpar
		set node($grandpar,type) span
		lappend erased_nodes $grandpar
		adjust-after-change $par $par 1
	    }
	} elseif {[relation-type $relation] == "multinuc"} {
	    foreach child $NODES($par,children) {
		if {[relation-type $NODES($child,relname)] == "multinuc"} {
		    lappend sibling $child
		}
	    }
	    if {[lindex $sibling 1] == {}} {
		###########
		#unary multinuc
		###########
		set grandpar $NODES($par,parent)

		#put sibling into par position
		#sibling gets par's children
		foreach child $NODES($par,children) {
		    if {$child != $sibling} {
			set node($child,parent) $sibling
			lappend node($sibling,children) $child
		    }
		}
		set node($sibling,parent) $grandpar
		set node($sibling,relname) $NODES($par,relname)
		if {$grandpar != {}} {
		    #there is a grandparent
		    #grandpar gets sibling as child
		    set index [lsearch $NODES($grandpar,children) $par]
		    set node($grandpar,children)\
			[lreplace $NODES($grandpar,children) $index $index $sibling]
		}
		#eliminate par
		clear $par
		set node($par,type) span
		lappend erased_nodes $par
		adjust-after-change $sibling $sibling 1
	    }
	}

	if {$method == "disconnect"} {
	    set DISCO_NODE {}
	    set-mode nothing
	} else {
	    #method == modify
	    set DISCO_NODE $clicked_node
	    set-mode link
	}
	editor-message "disconnected $clicked_node $method"
    }
}

proc ::rsttool::treeditor::tree::node::group-node-p {nid} {
    variable ::rsttool::NODES;
    puts stderr "group-node-p: nid = $nid, type = $NODES($nid,type)"
    if {$NODES($nid,type) == "text"} {return 0}
    return 1;
}

proc ::rsttool::treeditor::tree::node::egroup-node-p {nid} {
    variable ::rsttool::NODES;
    if {$NODES($nid,etype) == "text" || $NODES($nid,etype) == {}} {return 0}
    return 1;
}

proc ::rsttool::treeditor::tree::node::text-node-p {nid} {
    variable ::rsttool::NODES;
    #come back here
    if { $nid == {} || $NODES($nid,type) == "text"} {return 1}
    return 0;
}

proc ::rsttool::treeditor::tree::node::eparent-msgid-p {a_msgid} {
    variable ::rsttool::CRNT_MSGID;
    variable ::rsttool::PRNT_MSGID;

    return [expr ([string equal "$PRNT_MSGID" ""] && [string equal "$a_msgid" "$PRNT_MSGID"]) || \
		(![string equal "$PRNT_MSGID" ""] || [string equal "$a_msgid" "$CRNT_MSGID"])];
}

proc ::rsttool::treeditor::tree::node::is-prnt-p {prnt_nid chld_nid} {
    variable ::rsttool::FORREST;
    variable ::rsttool::NID2MSGID;

    return [string equal "$NID2MSGID($prnt_nid)" "[lindex $FORREST($NID2MSGID($chld_nid)) 1]"];
}

proc ::rsttool::treeditor::tree::node::bisearch {a_nid a_list {a_start -1} \
						     {a_get_start ::rsttool::treeditor::tree::node::get-start}} {
    variable ::rsttool::NODES;

    set idx -1;
    set lstart 0;
    set jstart 0;
    set llen [llength $a_list];
    set orig_len $llen;
    if {$a_start < 0} {set a_start [$a_get_start $a_nid];}

    while {$llen > 0} {
	set llen [expr $llen / 2];
	set idx [expr $lstart + $llen];
	if {$idx >= $orig_len} {break;}
	# puts stderr "bisearch: a_list = $a_list";
	# puts stderr "bisearch: a_start = $a_start";
	# puts stderr "bisearch: a_list = $a_list";
	# puts stderr "bisearch: idx = $idx";
	# puts stderr "bisearch: nid = [lindex $a_list $idx]";
	# puts stderr "bisearch: a_get_start = [$a_get_start [lindex $a_list $idx]]";
	set jstart [$a_get_start [lindex $a_list $idx]];

	if {$a_start == $jstart} {
	    return $idx;
	} elseif {$a_start > $jstart} {
	    set idx [expr $idx + ($llen > 1? 0: 1)]
	    set lstart $idx;
	}
    }
    return $idx;
}

proc ::rsttool::treeditor::tree::node::insort {a_list a_start a_nid \
						   {a_allow_dup 0} \
						   {a_get_start ::rsttool::treeditor::tree::node::get-start}} {
    set ins_idx [bisearch $a_nid $a_list $a_start $a_get_start]

    # do not insert duplicates
    if {$a_allow_dup == 0 && $ins_idx < [llength $a_list] && \
	    [lindex $a_list $ins_idx] == $a_nid} {return $a_list;}
    return [linsert $a_list $ins_idx $a_nid];
}

proc ::rsttool::treeditor::tree::node::clear {nid} {
    variable ::rsttool::NODES
    variable ::rsttool::ROOTS
    variable ::rsttool::NID2MSGID;
    variable ::rsttool::MSGID2ROOTS;
    variable ::rsttool::MSGID2TNODES;
    variable ::rsttool::MSGID2ENID;
    variable ::rsttool::NAME2NID;
    variable ::rsttool::treeditor::VISIBLE_NODES;
    namespace import ::rsttool::utils::ldelete;

    # remove this node from MSGID's
    set msgid $NID2MSGID($nid);
    if [info exists MSGID2ROOTS($msgid)] {
	::rsttool::treeditor::update-roots $msgid $nid {remove};
	if [text-node-p $nid] {
	    set MSGID2TNODES($msgid) [ldelete $MSGID2TNODES($msgid) $nid];
	}
    }

    # clear NODES
    array unset NODES $nid;
    array unset NODES $nid,type;
    array unset NODES $nid,start;
    array unset NODES $nid,end;
    array unset NODES $nid,relname;

    if [info exists NODES($nid,name)] {
	array unset NAME2NID $NODES($nid,name);
    }
    array unset NODES $nid,name;

    # clean-up parent
    if {[info exists NODES($nid,parent)] && $NODES($nid,parent) != {}} {
	set NODES($NODES($nid,parent),children) \
	    [ldelete $NODES($NODES($nid,parent),children) $nid]
    }
    array unset NODES $nid,parent;

    if {[info exists NODES($nid,children)] && $NODES($nid,children) != {}} {
	foreach child_nid $NODES($nid,children) {
	    if {$NODES($child_nid,parent) == $nid} {
		array unset NODES $child_nid,parent;
	    }
	}
    }
    array unset NODES $nid,children;
    array unset NID2MSGID $nid;

    # remove this node from the set of visible nodes
    array unset VISIBLE_NODES $nid;
}

proc ::rsttool::treeditor::tree::node::display {a_nid} {
    variable ::rsttool::NODES;
    variable ::rsttool::FORREST;
    variable ::rsttool::NID2MSGID;
    variable ::rsttool::CRNT_MSGID;
    variable ::rsttool::PRNT_MSGID;
    variable ::rsttool::MSGID2ENID;
    variable ::rsttool::treeditor::WTN;
    variable ::rsttool::treeditor::RSTW;
    variable ::rsttool::treeditor::NODE_WIDTH;
    variable ::rsttool::treeditor::DISCUSSION;
    variable ::rsttool::treeditor::DISPLAYMODE;

    set text {};
    if {$DISPLAYMODE == $DISCUSSION} {
	set imsgid $NID2MSGID($a_nid);
	if {$NODES($a_nid,etype) == {text}} {
	    set color "black";
	    if {$imsgid == $PRNT_MSGID || \
		    ($PRNT_MSGID == {} && $imsgid == $CRNT_MSGID)} {
		set text "0";
	    } else {
		set text "[expr [get-child-pos $a_nid] + 1]";
	    }
	    set text "$text\n[lindex $FORREST($imsgid) 0]";
	} else {
	    set color "green";
	    set text "$NODES($a_nid,name)";
	}
    } elseif {[group-node-p $a_nid]} {
	set color "green";
	set text "$NODES($a_nid,name)";
    } else {
	set color "black"
	set text "$NODES($a_nid,name)\n$NODES($a_nid,text)"
    }
    set xpos $NODES($a_nid,xpos);
    set ypos [expr $NODES($a_nid,ypos) + 2];
    set wgt [draw-text $RSTW $text $xpos $ypos "-width $NODE_WIDTH -fill $color"]

    set NODES($a_nid,textwgt) $wgt
    set WTN($wgt) $a_nid

    draw-span $a_nid
    # display-arc $a_nid
}

proc ::rsttool::treeditor::tree::node::redisplay {a_nid} {
    variable ::rsttool::NODES;
    variable ::rsttool::NID2MSGID;
    variable ::rsttool::CRNT_MSGID;
    variable ::rsttool::PRNT_MSGID;
    variable ::rsttool::treeditor::DISCUSSION;
    variable ::rsttool::treeditor::DISPLAYMODE;

    # erase node
    if {[info exists NODES($a_nid,textwgt)] && $NODES($a_nid,textwgt) != {}} {
	erase $a_nid;
    }
    # display node
    display $a_nid;
    # display arc
    set prnt_prfx "";
    set msgid $NID2MSGID($a_nid);
    if {$DISPLAYMODE == $DISCUSSION && (($PRNT_MSGID != {} && $msgid != $PRNT_MSGID) || \
	    ($PRNT_MSGID == {} && $msgid != $CRNT_MSGID))} {
	set prnt_prfx "e";
    }
    ::rsttool::treeditor::tree::arc::display $NODES($a_nid,${prnt_prfx}parent)\
	$a_nid $NODES($a_nid,${prnt_prfx}reltype);
}

proc ::rsttool::treeditor::tree::node::draw-span {a_nid} {
    variable ::rsttool::NODES;
    variable ::rsttool::NID2MSGID;
    variable ::rsttool::treeditor::RSTW;
    variable ::rsttool::treeditor::MESSAGE;
    variable ::rsttool::treeditor::DISCUSSION;
    variable ::rsttool::treeditor::DISPLAYMODE;
    variable ::rsttool::treeditor::VISIBLE_NODES;
    variable ::rsttool::treeditor::HALF_NODE_WIDTH;

    if { $a_nid == {} } {return}

    set xpos $NODES($a_nid,xpos)
    set ypos $NODES($a_nid,ypos)
    set min $xpos
    set max $xpos

    puts stderr "draw-span: a_nid = $a_nid; start = $NODES($a_nid,start), end = $NODES($a_nid,end);"
    if {($DISPLAYMODE == $MESSAGE && [group-node-p $a_nid]) || \
	    ($DISPLAYMODE == $DISCUSSION && [egroup-node-p $a_nid])} {
	if {[info exists NODES($a_nid,start)]} {
	    set start_nid $NODES($a_nid,start);
	    if {[info exists NODES($start_nid,xpos)]} {
		set min $NODES($start_nid,xpos)
	    } else {
		error "Unknown index: NODES($start_nid,xpos)"
	    }
	} else {
	    error "Unknown index: NODES($a_nid,start)"
	}

	if {[info exists NODES($a_nid,end)]} {
	    set end_nid $NODES($a_nid,end);
	    if {[info exists NODES($end_nid,xpos)]} {
		set max $NODES($end_nid,xpos)
	    } else {
		error "Unknown index: NODES($end_nid,xpos)"
	    }
	} else {
	    error "Unknown index: NODES($a_nid,end)"
	}
    }
    puts stderr "draw-span: min = $min; max = $max;"

    # draw the span-line
    set NODES($a_nid,spanwgt) [draw-line $RSTW \
				   [expr $min - $HALF_NODE_WIDTH] $ypos \
				   [expr $max + $HALF_NODE_WIDTH] $ypos];
}

proc ::rsttool::treeditor::tree::node::draw-text {window txt x y {options {}}} {
    return [$window create text $x $y -text $txt -anchor n -justify center \
		{*}$options];
}

proc ::rsttool::treeditor::tree::node::draw-line {window x1 y1 x2 y2} {
    return [$window create line $x1 $y1  $x2 $y2];
}

##################################################################
package provide rsttool::treeditor::tree::node 0.0.1
return
