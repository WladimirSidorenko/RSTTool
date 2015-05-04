#!/usr/bin/env wish
# -*- mode: tcl; -*-

##################################################################
namespace eval ::rsttool::treeditor::tree::node {
    namespace export bfs;
    namespace export bisearch;
    namespace export destroy-group-node;
    namespace export draw-span;
    namespace export draw-text;
    namespace export egroup-node-p;
    namespace export eparent-msgid-p;
    namespace export get-ancestor;
    namespace export get-child-pos;
    namespace export get-end-node;
    namespace export get-end;
    namespace export get-estart;
    namespace export get-eterminal;
    namespace export get-start-node;
    namespace export get-start;
    namespace export get-visible-parent;
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

    if {$msgid == {}} {set msgid $CRNT_MSGID;}

    set prfx {};
    if {$external} {set prfx "e";}

    set etype {};
    if {$type ==  "text"} {
	if {$name == {}} {set name [unique-tnode-name]};
	if {$nid == {}} {set nid [unique-tnode-id]; set VISIBLE_NODES($nid) 1};

	# save mapping from message id to node id
	if {![info exists MSGID2ROOTS($msgid)]} {set MSGID2ROOTS($msgid) {};}
	if {![info exists MSGID2TNODES($msgid)]} {set MSGID2TNODES($msgid) {}}
	# since we might add node after some group nodes were created,
	# we need to re-sort the node list
	# puts stderr "node::make: 0) insorting $nid (start = $start) in MSGID2TNODES($msgid) = $MSGID2TNODES($msgid)"
	set MSGID2TNODES($msgid) [insort $MSGID2TNODES($msgid) $start $nid];
	# puts stderr "node::make: 1) MSGID2TNODES($msgid) after insort = $MSGID2TNODES($msgid)"
	if {! $external && $start == 0 && $end >= [string length [lindex $FORREST($msgid) 0]]} {
	    set external 1;
	    set etype {text};
	}
    } elseif {$nid == {}} {
	set nid [unique-gnode-id];
	set VISIBLE_NODES($nid) 1;
	if {$name == {}} {
	    set name [make-name $start $end $external];
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
    set NODES($nid,etype) $etype;
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
	# puts stderr "make-name: a_start = $a_start: [get-start-node $a_start]"
	# puts stderr "make-name: a_end = $a_end: [get-end-node $a_end]"
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

proc ::rsttool::treeditor::tree::node::get-ancestor {a_nid} {
    variable ::rsttool::NODES;

    if {$NODES($a_nid,parent) != {}} {
	return [get-ancestor $NODES($a_nid,parent)];
    } else {
	return $a_nid;
    }
}

proc ::rsttool::treeditor::tree::node::get-estart {a_nid} {
    variable ::rsttool::FORREST;
    variable ::rsttool::NID2MSGID;

    set crnt_msgid $NID2MSGID($a_nid);
    set prnt_msgid [lindex $FORREST($crnt_msgid) 1];
    if {$prnt_msgid == {}} {return -1;}
    return [lsearch [lindex $FORREST($prnt_msgid) end] $crnt_msgid];
}

proc ::rsttool::treeditor::tree::node::get-start {a_nid {a_seen_nids {[dict create]}}} {
    variable ::rsttool::NODES;

    # if {![array exists a_seen_nids]} {unset a_seen_nids; array set a_seen_nids {};}
    # puts stderr "get-start: a_nid = $a_nid;"
    if {[group-node-p $a_nid]} {
	if {[dict  exists $a_seen_nids $NODES($a_nid,start)]} {
	    error "Infinite loop detected while searching for start position of node $a_nid";
	} else {
	    dict set a_seen_nids $NODES($a_nid,start) 1;
	}
	return [get-start $NODES($a_nid,start) $a_seen_nids];
    }
    return $NODES($a_nid,start);
}

proc ::rsttool::treeditor::tree::node::get-start-node {a_nid} {
    variable ::rsttool::NODES;

    if {[group-node-p $a_nid]} {return $NODES($a_nid,start);}
    return $a_nid;
}

proc ::rsttool::treeditor::tree::node::get-end {a_nid {a_seen_nids {[dict create]}}} {
    variable ::rsttool::NODES;

    if {[group-node-p $a_nid]} {
	# puts stderr "node::get-end: a_nid = $a_nid (end = $NODES($a_nid,end))";
	if {[dict exists $a_seen_nids $NODES($a_nid,end)]} {
	    error "Infinite loop detected while searching for end position of node $a_nid";
	} else {
	    dict set a_seen_nids $NODES($a_nid,end) 1;
	}
	return [get-end $NODES($a_nid,end) $a_seen_nids];
    } else {
	# puts stderr "node::get-end: a_nid = $a_nid (NODES($a_nid,children) == $NODES($a_nid,children))";
	if {$NODES($a_nid,children) == {}} {
	    return $NODES($a_nid,end);
	} else {
	    set echild [lindex $NODES($a_nid,children) end];
	    if {[dict exists $a_seen_nids $echild]} {
		error "Infinite loop detected while searching for end position of node $a_nid";
	    } else {
		dict set a_seen_nids $echild 1;
	    }
	    set chld_end [get-end $echild $a_seen_nids];
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
    # puts stderr "get-child-pos: a_nid == $a_nid; msgid = $msgid"
    set prnt_msgid [lindex $FORREST($msgid) 1];
    # puts stderr "get-child-pos: a_nid == $a_nid; prnt_msgid = $prnt_msgid"
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
    variable ::rsttool::FORREST;
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
	set chld_prfx "";
	if {$DISPLAYMODE == $MESSAGE} {
	    set inodes $MSGID2ROOTS($msg_id);
	} else {
	    if {! [info exists MSGID2EROOTS($msg_id)]} {set MSGID2EROOTS($msg_id) {}}
	    set inodes $MSGID2EROOTS($msg_id);
	    set chld_prfx "e";
	}
	# puts stderr "show-nodes: 0) DISPLAYMODE = $DISPLAYMODE, msg_id = $msg_id, inodes = $inodes";
	array set seen_nodes {};
	set inid {}; set imsgid {}; set iprnt_msgid {};
	while {$inodes != {}} {
	    # pop first node on the queue
	    set inid [lindex $inodes 0];
	    set inodes [lreplace $inodes 0 0];
	    puts stderr "show-nodes: 0) inid == $inid, NODES($inid,${chld_prfx}children) == $NODES($inid,${chld_prfx}children), inodes = $inodes";
	    if [info exists seen_nodes($inid)] {
		::rsttool::segmenter::message "Inifinite loop detected at node $inid";
		continue;
	    } else {
		set seen_nodes($inid) 1;
	    }
	    # pop first node on the queue
	    set imsgid $NID2MSGID($inid);
	    set iprnt_msgid [lindex $FORREST($imsgid) 1];
	    # puts stderr "show-nodes: msg_id = $msg_id, imsgid = $imsgid"
	    if {$DISPLAYMODE == $MESSAGE && $imsgid != $msg_id} {continue;}
	    if {$DISPLAYMODE == $DISCUSSION && \
		    (!$NODES($inid,external) || \
			 ($imsgid != $CRNT_MSGID && $imsgid != $PRNT_MSGID && \
			      (($PRNT_MSGID != {} && $iprnt_msgid != $PRNT_MSGID) || \
				   ($PRNT_MSGID == {} && $iprnt_msgid != $CRNT_MSGID))))} {continue;}
	    set VISIBLE_NODES($inid) 1
	    # puts stderr "show-nodes: 1) add NODES($inid,${chld_prfx}children) = $NODES($inid,${chld_prfx}children) to inodes";
	    set inodes [concat $inodes $NODES($inid,${chld_prfx}children)];
	}
	array unset seen_nodes;
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
    ::rsttool::treeditor::tree::unlink $nid 0;

    # 2. delete the graphic presentation
    erase $nid;

    # 3. remove node from visible node list and drop all its
    # structural information
    clear $nid;
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

proc ::rsttool::treeditor::tree::node::copy-children {a_trg a_src {a_external 0}} {
    variable ::rsttool::NODES;
    variable ::rsttool::NID2MSGID;

    puts stderr "copy-children: a_src = $a_src, a_trg = $a_trg, a_external == $a_external;"
    set chld_prfx ""; set chld_prnt_prfx "";
    if { $a_external } {
	set chld_prfx "e";
    }

    puts stderr "copy-children: NODES($a_src,${chld_prfx}children) = $NODES($a_src,${chld_prfx}children);"
    foreach chnid $NODES($a_src,${chld_prfx}children) {
	if { [bfs $chnid $a_trg] } {continue;}
	puts stderr "copy-children: chnid = $chnid;"
	if {$a_external && ![eparent-msgid-p $NID2MSGID($chnid)]} {
	    set chld_prnt_prfx "e";
	} else {
	    set chld_prnt_prfx "";
	}
	set NODES($chnid,${chld_prnt_prfx}parent) $a_trg;
	if { $a_external } {
	    set NODES($a_trg,echildren) [insort $NODES($a_trg,echildren) \
					     [get-child-pos $chnid] $chnid 0 get-child-pos];
	    puts stderr "copy-children: chnid = $chnid;"
	} else {
	    # append child node to the list of the parent's children
	    set NODES($a_trg,children) [insort $NODES($a_trg,children) $NODES($chnid,start) $chnid];
	}
    }
}

# Delete group node `gnid` and replace it with `replnid`
proc ::rsttool::treeditor::tree::node::destroy-group-node {gnid {replnid {}} {external 0}} {
    variable ::rsttool::NODES;
    variable ::rsttool::FORREST;
    variable ::rsttool::NID2MSGID;
    variable ::rsttool::MSGID2ENID;
    variable ::rsttool::MSGID2ROOTS;
    variable ::rsttool::MSGID2EROOTS;
    variable ::rsttool::relations::SPAN;

    namespace import ::rsttool::utils::ldelete;
    namespace import ::rsttool::treeditor::update-roots;
    namespace import ::rsttool::treeditor::tree::erase-subtree;

    puts stderr "destroy-group-node: gnid == $gnid, replnid == $replnid, external == $external;"

    if {$gnid == {}} {return;}
    set gmsg_id $NID2MSGID($gnid);
    set chld_prfx ""; set prnt_prfx ""; set repl_prnt_prfx "";
    if { $external } {
	set chld_prfx "e";
	if { ![eparent-msgid-p $gmsg_id] } {set prnt_prfx "e";}
	if { $replnid != {} && ![eparent-msgid-p $NID2MSGID($replnid)] } {
	    set repl_prnt_prfx "e";
	}
    }

    # delete `gnid` from the children of its parent and put `replnid` instead
    if { $replnid == {} } {
	if { $NODES($gnid,parent) != {} && $NODES($gnid,reltype) == $SPAN} {
	    destroy-group-node $NODES($gnid,parent) $replnid $external;
	}
	if { $NODES($gnid,eparent) != {} && $NODES($gnid,ereltype) == $SPAN} {
	    destroy-group-node $NODES($gnid,eparent) $replnid $external;
	}
    } else {
	# update parents of replacement node
	set grnd_prnt $NODES($gnid,parent);
	# set appropriate parent of the replacement node
	set NODES($replnid,parent) $grnd_prnt;
	set NODES($replnid,relname) $NODES($gnid,relname);
	set NODES($replnid,reltype) $NODES($gnid,reltype);

	set grnd_eprnt $NODES($gnid,eparent);
	# set appropriate parent of the replacement node
	set NODES($replnid,eparent) $grnd_eprnt;
	set NODES($replnid,erelname) $NODES($gnid,erelname);
	set NODES($replnid,ereltype) $NODES($gnid,ereltype);
	set NODES($replnid,external) $NODES($gnid,external);
	set NODES($replnid,etype) $NODES($gnid,etype);
	puts stderr "destroy-group-node: NODES($replnid,external) == $NODES($replnid,external);"
	puts stderr "destroy-group-node: NODES($replnid,etype) == $NODES($replnid,etype);"

	# add `replnid` to the children of grand-parent
	if { $grnd_prnt != {} } {
	    if {  $external || $NODES($grnd_prnt,etype) == $SPAN } {
		set NODES($grnd_prnt,echildren) [insort $NODES($grnd_prnt,echildren) \
						     [get-child-pos $replnid] $replnid 0 \
						     get-child-pos];
	    } else {
		# append child node to the list of the parent's children
		set NODES($grnd_prnt,children) [insort $NODES($grnd_prnt,children) \
						    $NODES($replnid,start) $replnid];
	    }
	}
	# add children of `gnid` to `replnid`
	copy-children $replnid $gnid 1;
	copy-children $replnid $gnid 0;
	# update roots
	if { [lsearch $MSGID2ROOTS($gmsg_id) $gnid] != -1 } {
	    update-roots $gmsg_id $gnid {remove} 0;
	    update-roots $gmsg_id $replnid {add} 0;
	}
	if { [lindex $MSGID2EROOTS($gmsg_id) 0] == $gnid } {
	    update-roots $gmsg_id $gnid {remove} 1;
	    update-roots $gmsg_id $replnid {add} 1;
	}
	set pmsg_id [lindex $FORREST($gmsg_id) 1];
	if { $pmsg_id != {} && [lsearch $MSGID2EROOTS($pmsg_id) $gnid] != -1 } {
	    update-roots $pmsg_id $gnid {remove} 1;
	    update-roots $pmsg_id $replnid {add} 1;
	}
    }
    # climb up the tree and update start and end nodes, if necessary
    set pnode {}; set need_update 0;
    set pnodes [list $NODES($replnid,eparent) $NODES($replnid,parent)]
    while { $pnodes != {} } {
	set need_update 0;
	# pop first node from the parent
	set pnode [lindex $pnodes 0];
	set pnodes [lrange $pnodes 1 end];
	if { $pnode == {} } {continue;}
	# replace start and end nodes
	if {[group-node-p $pnode] || [egroup-node-p $pnode]} {
	    if { $NODES($pnode,start) == $gnid } {
		set NODES($pnode,start) $replnid;
		set need_update 1;
	    }
	    if { $NODES($pnode,end) == $gnid } {
		set NODES($pnode,end) $replnid;
		set need_update 1;
	    }
	}
	if { $need_update } {
	    lappend pnodes $NODES($pnode,parent);
	    lappend pnodes $NODES($pnode,eparent);
	}
    }

    puts stderr "destroy-group-node: NODES(replnid = $replnid,external) == $NODES($replnid,external);"
    puts stderr "destroy-group-node: NODES(replnid = $replnid,etype) == $NODES($replnid,etype);"
    puts stderr "destroy-group-node: NODES(replnid = $replnid,children) == $NODES($replnid,children);"
    puts stderr "destroy-group-node: NODES(replnid = $replnid,echildren) == $NODES($replnid,echildren);"
    # erase group node
    clear $gnid;
}

##################################################
#  Collapse or Expand Nodes
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
	redisplay $clicked_node

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
    # puts stderr "group-node-p: nid = $nid, type = $NODES($nid,type)"
    if {$NODES($nid,type) == "text"} {return 0}
    return 1;
}

proc ::rsttool::treeditor::tree::node::egroup-node-p {nid} {
    variable ::rsttool::NODES;
    if {$NODES($nid,etype) == "text" || $NODES($nid,etype) == {}} {return 0;}
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

    return [expr ([string equal "$PRNT_MSGID" ""] && [string equal "$a_msgid" "$CRNT_MSGID"]) || \
		(![string equal "$PRNT_MSGID" ""] && [string equal "$a_msgid" "$PRNT_MSGID"])];
}

proc ::rsttool::treeditor::tree::node::is-prnt-p {prnt_nid chld_nid} {
    variable ::rsttool::FORREST;
    variable ::rsttool::NID2MSGID;

    return [string equal "$NID2MSGID($prnt_nid)" "[lindex $FORREST($NID2MSGID($chld_nid)) 1]"];
}

proc ::rsttool::treeditor::tree::node::get-eterminal {a_nid} {
    variable ::rsttool::NODES;
    variable ::rsttool::FORREST;
    variable ::rsttool::NID2MSGID;

    # return first non-terminal
    # puts stderr "get-eterminal: a_nid = $a_nid, egroup = [egroup-node-p $a_nid]"
    if {![egroup-node-p $a_nid]} {return $a_nid;}
    # descend into children if necessary
    set cid {};
    set imsgid $NID2MSGID($a_nid);
    foreach icid $NODES($a_nid,echildren) {
	# puts stderr "get-eterminal: icid = $icid";
	if {$NID2MSGID($icid) == $imsgid} {
	    if {$cid != {}} {error "Ambiguous external terminals found for node '$a_nid'.";}
	    set cid $icid;
	} elseif {![is-prnt-p $a_nid $icid]} {
	    return $a_nid;
	}
    }
    # puts stderr "get-eterminal: cid = $cid";
    if {$cid == {}} {error "No external terminal found for node '$a_nid'.";}
    return [get-eterminal $cid];
}

proc ::rsttool::treeditor::tree::node::bfs {a_prnt_nid a_chld_nid} {
    variable ::rsttool::NODES;

    set seen_nodes [dict create];
    set inid {};
    set inodes [list $a_prnt_nid];
    while {$inodes != {}} {
	set inid [lindex $inodes 0];
	set inodes [lreplace $inodes 0 0];
	if { $inid == $a_chld_nid } {
	    return 1;
	} elseif { [dict exists $seen_nodes $inid] } {
	    error "Infinite loop detected at node '$inid'.";
	} else {
	    dict set seen_nodes $inid 1;
	    set inodes [concat $inodes $NODES($inid,children) $NODES($inid,echildren)];
	}

    }
    return 0;
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
	# puts stderr "bisearch: llen = $llen";
	# puts stderr "bisearch: nid = [lindex $a_list $idx]";
	# puts stderr "bisearch: a_get_start = [$a_get_start [lindex $a_list $idx]]";
	set jstart [$a_get_start [lindex $a_list $idx]];

	if {$a_start == $jstart} {
	    return $idx;
	} elseif {$a_start > $jstart} {
	    set idx [expr $idx + ($llen < 1 || $llen % 2 ? 1: 0)];
	    set lstart $idx;
	}
    }
    return $idx;
}

proc ::rsttool::treeditor::tree::node::insort {a_list a_start a_nid \
						   {a_allow_dup 0} \
						   {a_get_start ::rsttool::treeditor::tree::node::get-start}} {
    set ins_idx [bisearch $a_nid $a_list $a_start $a_get_start]

    # if { $ins_idx < [llength $a_list] } {
    # 	puts stderr "node::insort: a_list = $a_list, a_nid = $a_nid, ins_idx = $ins_idx, el = [lindex $a_list $ins_idx];"
    # }
    # do not insert duplicates
    if {$a_allow_dup == 0 && $ins_idx < [llength $a_list] && \
	    [lindex $a_list $ins_idx] == $a_nid} {return $a_list;}
    return [linsert $a_list $ins_idx $a_nid];
}

proc ::rsttool::treeditor::tree::node::clear {nid} {
    variable ::rsttool::MSGID2ENID;
    variable ::rsttool::MSGID2EROOTS;
    variable ::rsttool::MSGID2ROOTS;
    variable ::rsttool::MSGID2TNODES;
    variable ::rsttool::NAME2NID;
    variable ::rsttool::NID2MSGID;
    variable ::rsttool::NODES
    variable ::rsttool::ROOTS
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
	set NODES($NODES($nid,parent),echildren) \
	    [ldelete $NODES($NODES($nid,parent),echildren) $nid]
    }
    array unset NODES $nid,parent;
    if {[info exists NODES($nid,eparent)] && $NODES($nid,eparent) != {}} {
	set NODES($NODES($nid,eparent),echildren) \
	    [ldelete $NODES($NODES($nid,eparent),echildren) $nid]
    }
    array unset NODES $nid,eparent;

    # update children
    if {[info exists NODES($nid,children)] && $NODES($nid,children) != {}} {
	foreach child_nid $NODES($nid,children) {
	    if {$NODES($child_nid,parent) == $nid} {
		array unset NODES $child_nid,parent;
	    }
	}
    }
    array unset NODES $nid,children;
    set prnt_prfx "";
    if {[info exists NODES($nid,echildren)] && $NODES($nid,echildren) != {}} {
	foreach child_nid $NODES($nid,echildren) {
	    if {$NODES($child_nid,parent) == $nid} {
		array unset NODES $child_nid,parent;
	    } elseif { $NODES($child_nid,eparent) == $nid } {
		array unset NODES $child_nid,eparent;
	    }
	}
    }
    array unset NODES $nid,echildren;

    # update roots
    set MSGID2ROOTS($msgid) [ldelete $MSGID2ROOTS($msgid) $nid];
    set MSGID2EROOTS($msgid) [ldelete $MSGID2EROOTS($msgid) $nid];

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
	set color "black";
	set text "$NODES($a_nid,name)\n$NODES($a_nid,text)";
    }
    set xpos $NODES($a_nid,xpos);
    set ypos [expr $NODES($a_nid,ypos) + 2];
    set wgt [draw-text $RSTW $text $xpos $ypos "-width $NODE_WIDTH -fill $color"];

    set NODES($a_nid,textwgt) $wgt;
    set WTN($wgt) $a_nid;

    draw-span $a_nid;
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
    # puts stderr "node::redisplay: $a_nid displayed"
    # display arc
    set prnt_prfx "";
    set msgid $NID2MSGID($a_nid);
    if {$DISPLAYMODE == $DISCUSSION && (($PRNT_MSGID != {} && $msgid != $PRNT_MSGID) || \
	    ($PRNT_MSGID == {} && $msgid != $CRNT_MSGID))} {
	set prnt_prfx "e";
    }
    # puts stderr "node::redisplay: $a_nid displaying arc, parent = $NODES($a_nid,${prnt_prfx}parent); reltype = $a_nid $NODES($a_nid,${prnt_prfx}reltype)"
    ::rsttool::treeditor::tree::arc::display $NODES($a_nid,${prnt_prfx}parent)\
	$a_nid $NODES($a_nid,${prnt_prfx}reltype);
    # puts stderr "node::redisplay: $a_nid arc displayed"
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

    # puts stderr "draw-span: a_nid = $a_nid; start = $NODES($a_nid,start), end = $NODES($a_nid,end);"
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
    # puts stderr "draw-span: min = $min; max = $max;"

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
