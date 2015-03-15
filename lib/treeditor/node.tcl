#!/usr/bin/env wish
# -*- mode: tcl; -*-

##################################################################
namespace eval ::rsttool::treeditor::tree::node {
    namespace export make-node;
    namespace export get-ins-index;
    namespace export show-nodes;
}

##################################################################
proc ::rsttool::treeditor::tree::node::make-node {text type {start_pos {}} {end_pos {}}} {
    variable ::rsttool::NODES;
    variable ::rsttool::CRNT_MSGID;
    variable ::rsttool::MSGID2NID;
    variable ::rsttool::NID2MSGID;
    variable ::rsttool::treeditor::VISIBLE_NODES;

    if { $type ==  "text"  } {
	set nid [unique-text-node-id]
	clear-node $nid
	# save mapping from node id to message id
	set nid2msgid($nid) [list $crntMsgId]
	# save mapping from message id to node id
	if {[info exists msgid2nid($crntMsgId)]} {
	    # since we might add node after some group nodes were
	    # created, we need to re-sort the node list
	    set msgid2nid($crntMsgId) [lsort -integer [concat $msgid2nid($crntMsgId) $nid]]
	} else {
	    set msgid2nid($crntMsgId) [list $nid]
	}
    } else {
	set nid [unique-group-node-id]
	clear-node $nid
    }
    set node($nid,text) $text
    set node($nid,type) $type
    set node($nid,offsets) [list $start_pos $end_pos]
    # puts stderr "make-node: node($nid,offsets) == $node($nid,offsets)"
    set visible_nodes($nid) 1

    if {$type ==  "text"} {
	set node($nid,span) "$nid $nid"
	add-text-node $nid
    } else {
	add-group-node $nid
    }
    return $nid
}

proc ::rsttool::treeditor::tree::node::show-nodes {msg_id {show 1}} {
    # set visibility status for all internal nodes belonging to the message
    # `$msg_id` to $show
    variable ::rsttool::MSGID2NID;
    variable ::rsttool::treeditor::VISIBLE_NODES;

    if {! [info exists MSGID2NID($msg_id)]} {return}

    # show/hide internal nodes pertaining to message `msg_id`
    if {$show} {
	foreach nid $MSGID2NID($msg_id) {
	    set VISIBLE_NODES($nid) 1
	}
    } else {
	foreach nid $MSGID2NID($msg_id) {
	    if {[info exists VISIBLE_NODES($nid)]} {unset VISIBLE_NODES($nid)}
	}
    }
}

proc ::rsttool::treeditor::tree::node::unlink-node {sat {redraw 1}} {
    global node nid2msgid group_nodes currentmode

    # 1. handle missed clicks
    if {$sat == {} || $NODES($sat,parent) == {}} {return}

    # 1. Delete connection between `sat` and its parent
    set nuc $NODES($sat,parent)
    set node($nuc,children) [ldelete $NODES($nuc,children) $sat]
    set node($sat,parent) {}
    set node($sat,relname) {}
    set spannid {}
    if {[info exists node($nuc,parent)] && $NODES($nuc,relname) == "span"} {
	set spannid $NODES($nuc,parent)
    }
    # puts stderr "unlink-node: sat = $sat (children: $NODES($sat,children))"
    # puts stderr "unlink-node: nuc = $nuc (children: $NODES($nuc,children))"
    # if {$spannid != {}} {puts stderr "unlink-node: spannid = $spannid  (children: $NODES($spannid,children))"}

    # 2. Redraw satellite substructure
    if {$redraw} {y-layout-subtree $sat}
    # 3. If parent has no more children, delete span node and shift
    # the parent up the structure
    set dgn 0
    # puts stderr "unlink-node: node($nuc,children) = $NODES($nuc,children)"
    if {$NODES($nuc,children) == {}} {
	set dgn 1
	# puts stderr "unlink-node: 1) set dgn 1"
    } elseif [group-node-p $nuc] {
	set dgn 1
	# puts stderr "unlink-node: 2) set dgn 1"
	# here, we have to differentiate between cases where `nuc` and
	# `sat` belong to same or to different messages
	if {$nid2msgid($nuc) == $nid2msgid($sat)} {
	    foreach chnid $NODES($nuc,children) {
		if {$NODES($chnid,relname) != "span"} {
		    set dgn 0
		    break
		}
	    }
	    if {[llength $NODES($nuc,children)] == 1} {
		set dgn 1
		destroy-node $nuc
		# puts stderr "unlink-node: calling destroy-node $nuc"
	    }
	}
    }

    # puts stderr "unlink-node: dgn = $dgn"
    if {$dgn} {
	if {$spannid != {} && [info exists nid2msgid($spannid)]} {
	    # puts stderr "unlink-node: destroy-group-node spannid = $spannid nuc = $nuc redraw = $redraw"
	    destroy-group-node $spannid $nuc $redraw
	} elseif [group-node-p $nuc] {
	    # puts stderr "unlink-node: destroy-node nuc = $nuc redraw = $redraw"
	    destroy-node $nuc $redraw
	}
    }
    # puts stderr "unlink-node: restructure-upwards nuc = $nuc redraw = $redraw"
    restructure-upwards $nuc $redraw
}

proc ::rsttool::treeditor::destroy-node {nid {redraw 1}} {
    # 1. unlink node if still connected
    unlink-node $nid 0

    # 2. delete the graphic presentation
    erase-node $nid

    # 3. remove node from visible node list and drop all its
    # structural information
    clear-node $nid
}

proc ::rsttool::treeditor::clicked-node {x y} {
    wtn [clicked-widget $x $y]
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
    # returns a text-lable for the span
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

proc ::rsttool::treeditor::add-text-node {nid} {
    global text_nodes

    # Report error if repeated add
    if [member $nid $text_nodes] {
	puts stderr "add-text-node: error: $nid already defined"
    }

    # add the node
    lappend text_nodes $nid
}

proc ::rsttool::treeditor::bottom-point {item} {
    variable RSTW
    list [lindex [$RSTW coords $item] 0]\
	[lindex [$RSTW bbox $item] 3]
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
		clear-node $grandpar
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
		clear-node $par
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

proc ::rsttool::treeditor::autolink_nodes {clicked_node {dragged_node {}} {type {}} {relation {}} \
			 {ambiguity {}} {space_holder {}} } {
    global newest_node rstw node currentsat
    global last_group_node_id DISCO_NODE
    global msgid2nid msgs2extnid nid2msgid theForrest
    global visible_nodes

    if {$dragged_node == {}} {
	if {[info exists newest_node] && [info exists visible_nodes($newest_node)]} {
	    set dragged_node $newest_node
	} else {
	    return
	}
    }

    if {$DISCO_NODE != {}} {
	set dragged_node $DISCO_NODE
	set DISCO_NODE {}
    }
    # puts stderr "autolink_nodes: clicked_node = $clicked_node"
    # puts stderr "autolink_nodes: dragged_node = $dragged_node"
    # puts stderr "autolink_nodes: type = $type"

    set dragged_msgid $nid2msgid($dragged_node)
    set dragged_prnt $NODES($dragged_node,parent)
    if {$dragged_prnt != {} && [info exists visible_nodes($dragged_prnt)]} {return}

    set clicked_msgid $nid2msgid($clicked_node)
    set clicked_prnt $NODES($clicked_node,parent)
    if {$clicked_prnt != {} && [info exists visible_nodes($clicked_prnt)] && \
	$dragged_msgid != $clicked_msgid} {return}

    if {[llength $clicked_msgid] > 1 || [llength $dragged_msgid] > 1} {return}

    if {$type == {} && $clicked_node == $dragged_node} {return}
    # check that clicked and dragged node are not already
    # ancestors of each other, since it would create an infinite
    # loop, if we tried to connect them again
    if {[is-ancestor $clicked_node $dragged_node] || [is-ancestor $dragged_node $clicked_node]} {
	return
    }
    # prevent non-projective edges, i.e. a given node can only be
    # linked to its adjacent span

    #set par $NODES($clicked_node,parent)
    set children $NODES($clicked_node,children)
    if {$children != {} && ! [info exists visible_nodes([lindex $children 0])]} {
	expand $clicked_node
	foreach child $children {
	    collapse $child
	}
	# reestablish
    }

    # obtain message id's of dragged and clicked nodes
    set clicked_is_prnt 0
    set ext_connection 0
    if {$dragged_msgid != $clicked_msgid} { set ext_connection 1 }

    if {$type == {} } {
	set coords [screen-coords [ntw $clicked_node] $RSTW]
	# determine which kind of relationship may hold between two nodes
	set nucleus nucleus
	set nucleus_embedded nucleus-embedded
	set satellite satellite
	set satellite_embedded satellite-embedded
	# if parent message of the dragged node is the message
	# corresponding to the clicked node, we cannot make the clicked
	# node a satellite
	set dragged_node_prnt_id [lindex $theForrest($dragged_msgid) 1]
	set clicked_node_prnt_id [lindex $theForrest($clicked_msgid) 1]
	if {$dragged_node_prnt_id == $clicked_msgid} {
	    set nucleus ""
	    set nucleus_embedded ""
	    set clicked_is_prnt 1
	} elseif {$clicked_node_prnt_id == $dragged_msgid} {
	    set satellite ""
	    set satellite_embedded ""
	} else {
	    # if both nodes belong to the same message, it can
	    # still be the case that
	}
	set type [popup-choose-from-list \
		      [concat $nucleus $satellite $nucleus_embedded $satellite_embedded \
			   {multinuclear schema}] \
		      [expr int([lindex $coords 0])] [expr int([lindex $coords 1])]]
    }
    if {$type == {}} {
	return
    }
    append this_step " $type"

    # determine if ambiguous
    if {$type == "satellite" || $type == "satellite-embedded"} {
	if { $ambiguity == {} } {
	    foreach child $NODES($clicked_node,children) {
		if { [relation-type $NODES($child,relname)] == "rst" || \
			 [relation-type $NODES($child,relname)] == "embedded"} {
		    # 1) ambiguous
		    set ambiguity "unknown"
		}
	    }
	}
    } elseif { $type == "multinuclear" } {
	if {"$NODES($clicked_node,type)" == "multinuc"} {
	    # 1) ambiguous
	    if { "$ambiguity" == {} } {
		set ambiguity "unknown"
	    }
	}
    } elseif {($type == "nucleus" || $type == "nucleus-embedded") && \
		  $NODES($clicked_node,parent) != {} && \
		  [info exists visible_nodes($NODES($clicked_node,parent))]} {
	return
    }

    # puts stderr "autolink_nodes: ambiguity = $ambiguity"
    if {$ambiguity == "unknown"} {
	set coords [screen-coords [ntw $clicked_node] $RSTW]
	set ambiguity [popup-choose-from-list {above below}\
			   [expr int([lindex $coords 0])] [expr int([lindex $coords 1])] NOcancel]
    }

    if {$type == "multinuclear" && $ambiguity == "below"} {
	# exception #1
	set i 0
	set child 0
	while { $child != {} } {
	    set child [lindex $children $i]
	    if {[relation-type $NODES($child,relname)] == "multinuc"} {
		set relation $NODES($child,relname)
		set child {}
	    }
	    incr i
	}
	if {$clicked_node == $dragged_node} {return}
	link-par-to-child $clicked_node $dragged_node $relation
    } elseif { ($type == "satellite" || $type == "satellite-embedded") && \
		   $ambiguity == "above" } {
	#exception #2
	set relation [choose-label $clicked_node $type $ext_connection]
	if {$relation == {} || $clicked_node == $dragged_node} {return}
	link-par-to-child $clicked_node $dragged_node $relation
    } elseif { $type == "schema" } {
	# exception #3
	set relation [choose-label $clicked_node $type $ext_connection]
	if {$relation == {}} {return}
	set node($clicked_node,constit) $relation
    } else {
	# standard algorithm
	if {$relation == {}} {
	    set relation [choose-label $clicked_node $type $ext_connection]
	}
	if {$relation == {}} {return}

	if {$ambiguity == {}} {
	    incr last_group_node_id
	    add-group-node $last_group_node_id
	    clear-node $last_group_node_id
	    set visible_nodes($last_group_node_id) 1
	}

	if {$ext_connection} {
	    # remember ids of messages which the new external node
	    # connects.  Additionally, if external parent already has an
	    # ancestor, link the newly create common group node to that
	    # ancestor.
	    if {$clicked_is_prnt} {
		# if dragged and clicked nodes belong to different messages,
		# remember both messages for the new group node
		set nid2msgid($last_group_node_id) [list $clicked_msgid $dragged_msgid]
		# if {[info exists node($clicked_node,parent)] && \
		    # 	    $NODES($clicked_node,parent) != {}} {
		# 	set $NODES($last_group_node_id,parent) $NODES($clicked_node,parent)
		# }
		set msgs2extnid($clicked_msgid,$dragged_msgid) [list $last_group_node_id $clicked_node span \
								    $clicked_node $dragged_node $relation]
	    } else {
		set nid2msgid($last_group_node_id) [list $dragged_msgid $clicked_msgid]
		# if {[info exists node($dragged_node,parent)] && \
		    # 	    $NODES($dragged_node,parent) != {}} {
		# 	set $NODES($last_group_node_id,parent) $NODES($dragged_node,parent)
		# }
		set msgs2extnid($dragged_msgid,$clicked_msgid) [list $last_group_node_id $dragged_node span \
								    $dragged_node $clicked_node $relation]
	    }
	} else {
	    # if dragged and clicked nodes belong to one message, remember
	    # that the new group node corresponds to that message id
	    set nid2msgid($last_group_node_id) [list $clicked_msgid]
	    # remember to which message the new internal group node belongs
	    lappend msgid2nid($clicked_msgid) $last_group_node_id
	}

	if {$type == "multinuclear"} {
	    set node($last_group_node_id,type) multinuc
	    # if clicked node is already linked to another node, link
	    # new group node to this parent
	    set grnd_prnt $NODES($clicked_node,parent)
	    if {$grnd_prnt != {} &&  [info exists visible_nodes($grnd_prnt)]} {
		link-par-to-child $grnd_prnt $last_group_node_id $NODES($clicked_node,relname);
		# unlink clicked node from its previous parent
		set node($clicked_node,parent) {}
		set node($grnd_prnt,children)  [ldelete $NODES($grnd_prnt,children) $clicked_node]
	    }
	    link-par-to-child $last_group_node_id $clicked_node $relation
	    link-par-to-child $last_group_node_id $dragged_node $relation
	    fix-children $last_group_node_id $clicked_node $dragged_node
	    redisplay-net
	} else {
	    # if {$clicked_node == $dragged_node} {return;}
	    set node($last_group_node_id,type) span
	    if {$type == "satellite" || $type == "satellite-embedded"} {
		if {$ambiguity == {}} {
		    # if assumed nucleus already is someone's satellite, we
		    set grnd_prnt $NODES($clicked_node,parent)
		    if {$NODES($clicked_node,relname) != "span" && \
			    [info exists visible_nodes($grnd_prnt)]} {
			set node($clicked_node,parent) {}
			set node($grnd_prnt,children)  [ldelete $NODES($grnd_prnt,children) $clicked_node]
			set grnd_prnt_msgid $nid2msgid($grnd_prnt)
			if {$grnd_prnt_msgid != $clicked_msgid && \
				[info exists msgs2extnid($grnd_prnt_msgid,$clicked_msgid)]} {
			    set msgs2extnid($grnd_prnt_msgid,$clicked_msgid) \
				[concat [lrange $msgs2extnid($grnd_prnt_msgid,$clicked_msgid) 0 2] \
				     [list $grnd_prnt $last_group_node_id $NODES($clicked_node,relname)]]
			}
			link-par-to-child $grnd_prnt $last_group_node_id $NODES($clicked_node,relname)
			redisplay-net
		    }
		    link-par-to-child $last_group_node_id $clicked_node span
		}
		link-par-to-child $clicked_node $dragged_node $relation
	    } elseif {$type == "nucleus" || $type == "nucleus-embedded"} {
		link-par-to-child $last_group_node_id $dragged_node span
		link-par-to-child $dragged_node $clicked_node $relation
	    }
	    # commented due to bug #35
	    # fix-children $last_group_node_id $clicked_node $dragged_node
	}
    }

    editor-message \
	"linked $dragged_node to $clicked_node as a $relation $type $ambiguity"
    xscrollto [max $NODES($dragged_node,xpos) $NODES($clicked_node,xpos)]
    yscrollto [max $NODES($dragged_node,ypos) $NODES($clicked_node,ypos)]
}

proc ::rsttool::treeditor::link-par-to-child {par child relation} {
    global node
    # puts stderr "link-par-to-child: Linking child $child to parent $par"
    if {$par == $child} {return;}
    # puts stderr "node($par,children) before: $NODES($par,children)"
    set node($par,children) [lsort -integer [list {*}$NODES($par,children) $child]]
    # puts stderr "node($par,children) after: $NODES($par,children)"

    # puts stderr "node($child,parent) before: $NODES($child,parent)"
    set node($child,parent) $par
    # puts stderr "node($child,parent) after: $NODES($child,parent)"
    set node($child,relname) $relation
    # puts stderr "link-par-to-child: adjust-after-change par = $par child = $child 1"
    adjust-after-change $par $child 1
}

proc ::rsttool::treeditor::tree::node::fix-children {new_node clicked_node dragged_node} {
    global node
    # puts stderr "fix-children: new_node = $new_node clicked_node = $clicked_node dragged_node = $dragged_node"
    foreach child $NODES($new_node,children) {
	if { $child == $clicked_node } {
	} elseif {$child == $dragged_node} {
	} elseif {$NODES($child,relname) == "span"} {
	    link-par-to-child $clicked_node $child span
	} elseif {[relation-type $NODES($child,relname)] == "multinuc"} {
	    link-par-to-child $clicked_node $child $NODES($child,relname)
	}
    }
}

proc ::rsttool::treeditor::tree::node::add-group-node {nid} {
    variable ::rsttool::NODES;
    variable ::rsttool::GROUP_NODES;

    # Report error if repeated add
    if [info exists GROUP_NODES($nid)] {error "add-group-node: error: $nid already defined"}

    # add the node
    set GROUP_NODES($nid) {};
}

proc ::rsttool::treeditor::tree::node::group-node-p {nid} {
    variable ::rsttool::NODES;
    member $NODES($nid,type) {span multinuc multinuclear constit embedded}
}

proc ::rsttool::treeditor::tree::node::text-node-p {nid} {
    variable ::rsttool::NODES;
    #come back here
    if { $nid == {} || $NODES($nid,type) == "text"} {
	return 1
    } else {
	return 0
    }
}

# TODO: test
proc ::rsttool::treeditor::tree::node::get-ins-index {a_list a_start} {
    variable ::rsttool::NODES;

    set jstart {};
    set lstart 0;
    set llen [llength $a_list];

    while {$llen > 0} {
	set llen [expr $llen / 2];
	set ins_idx [expr $lstart + $llen];
	set jstart [lindex $NODES([lindex $a_list $ins_idx],start)];
	if {$jstart > $a_start} {
	    continue;
	} else {
	    set lstart $ins_idx;
	}
    }
    return $ins_idx;
}

##################################################################
package provide rsttool::treeditor::tree::node 0.0.1
return
