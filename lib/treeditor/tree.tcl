#!/usr/bin/env wish
# -*- mode: tcl; -*-

##################################################################
package require rsttool::treeditor::tree::arc
package require rsttool::treeditor::tree::node

##################################################################
namespace eval ::rsttool::treeditor::tree {
    namespace export wtn;
    namespace export ntw;
    namespace export unlink;
    namespace export clicked-node;
    namespace export clicked-widget;
    namespace export popup-choose-from-list;
}

##################################################################
proc ::rsttool::treeditor::tree::clicked-node {x y} {
    puts stderr "clicked-node: wdgt = [clicked-widget $x $y], node = [wtn [clicked-widget $x $y]];"
    return [wtn [clicked-widget $x $y]];
}

proc ::rsttool::treeditor::tree::wtn {wdgt} {
    variable ::rsttool::treeditor::WTN

    if [info exists WTN($wdgt)] {
	return $WTN($wdgt);
    }
    return {};
}

proc ::rsttool::treeditor::tree::ntw {a_nid} {
    variable ::rsttool::NODES;

    if {[info exists NODES($a_nid,textwgt)]} {
	return $NODES($a_nid,textwgt);
    }
    return {};
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

proc ::rsttool::treeditor::tree::link-nodes {clicked_nid {dragged_nid {}} {type {}} {relation {}} \
			 {ambiguity {}} {space_holder {}} } {
    variable ::rsttool::FORREST;
    variable ::rsttool::NODES;
    variable ::rsttool::NID2MSGID;
    variable ::rsttool::MSGID2ROOTS;
    variable ::rsttool::treeditor::RSTW;
    variable ::rsttool::treeditor::DRAGGED_NID;
    variable ::rsttool::treeditor::VISIBLE_NODES;
    namespace import ::rsttool::segmenter::message;

    puts stderr "link-nodes called";
    # global visible_nodes
    # global last_group_node_id DISCO_NODE
    # global newest_node rstw node currentsat
    # global msgid2nid msgs2extnid nid2msgid theForrest

    # by default, we assume that clicked node is a parent, but that
    # assumption might be changed later in this function
    set clicked_is_prnt 1;
    set ext_connection 0

    if {$dragged_nid == {}} {
	if {$DRAGGED_NID != {} && [info exists VISIBLE_NODES($DRAGGED_NID)]} {
	    set dragged_nid $DRAGGED_NID;
	} else {
	    return;
	}
    }
    # forbid connections from the node to itself
    if {$clicked_nid == $dragged_nid} {
	message "Can't connect identical nodes."
	return;
    }

    set clicked_msgid $NID2MSGID($clicked_nid)
    set clicked_prnt $NODES($clicked_nid,parent)
    if {$clicked_prnt != {} && [info exists VISIBLE_NODES($clicked_prnt)]} {
	set clicked_is_prnt 0;
    }

    # puts stderr "autolink_nodes: clicked_nid = $clicked_nid"
    # puts stderr "autolink_nodes: dragged_nid = $dragged_nid"
    # puts stderr "autolink_nodes: type = $type"

    set dragged_msgid $NID2MSGID($dragged_nid);
    set dragged_prnt $NODES($dragged_nid,parent);
    puts stderr "dragged_prnt = $dragged_prnt"
    if {$dragged_msgid != $clicked_msgid} { set ext_connection 1 }
    # forbid multiple roots for one message
    if {$dragged_prnt != {} && [info exists VISIBLE_NODES($dragged_prnt)] &&\
	    $clicked_is_prnt == 0} {
	message "Node $NODES($clicked_nid,name) already has a parent."
	return;
    }

    # prevent non-projective edges, i.e. given node can only be linked
    # to its adjacent span
    puts stderr "link-nodes: MSGID2ROOTS(clicked_msgid) = $MSGID2ROOTS($clicked_msgid)"
    namespace import ::rsttool::treeditor::tree::node::get-visible-parent;
    set clicked_idx [node::bisearch [get-visible-parent $clicked_nid] $MSGID2ROOTS($clicked_msgid)]
    set dragged_idx [node::bisearch [get-visible-parent $dragged_nid] $MSGID2ROOTS($dragged_msgid)]
    puts stderr "link-nodes: clicked_prnt = [get-visible-parent $clicked_nid]"
    puts stderr "link-nodes: dragged_prnt = [get-visible-parent $dragged_nid]"
    puts stderr "link-nodes: clicked_idx = $clicked_idx; dragged_idx = $dragged_idx"
    if {[expr abs([expr $clicked_idx - $dragged_idx])] > 1} {
	message "Can't connect non-adjacent nodes."
	return;
    }

    if {$type == {}} {
	# determine which kind of relationship may hold between two nodes
	set nucleus {nucleus}
	set nucleus_embedded {nucleus-embedded}
	set satellite {satellite}
	set satellite_embedded {satellite-embedded}
	# if parent message of the dragged node is the message
	# corresponding to the clicked node, we cannot make the clicked
	# node a satellite
	set dragged_prnt_msgid [lindex $FORREST($dragged_msgid) 1]
	set clicked_prnt_msgid [lindex $FORREST($clicked_msgid) 1]
	# for external connections, the type of dependencies is always
	# predefined
	if {$ext_connection} {
	    if {$dragged_msgid == $clicked_prnt_msgid} {
		set satellite "";
		set satellite_embedded "";
	    } else {
		set nucleus "";
		set nucleus_embedded "";
	    }
	} elseif {! $clicked_is_prnt} {
	    set nucleus "";
	    set nucleus_embedded "";
	}
	set coords [screen-coords [ntw $clicked_nid] $RSTW]
	set type [popup-choose-from-list \
		      [concat $nucleus $satellite $nucleus_embedded $satellite_embedded \
			   {multinuclear}] \
		      [expr int([lindex $coords 0])] [expr int([lindex $coords 1])] 1];
    }
    puts stderr "type = $type";
    if {$type == {}} {return}

    # choose relation according to the specified type
    set relation [choose-label $clicked_nid $type $ext_connection];

    puts stderr "relation = $relation";
    if {$relation == {}} {return;}

    set multinuc 0;
    set prnt_nid $clicked_nid;
    set prnt_msgid $clicked_msgid;
    set chld_nid $dragged_nid;
    set chld_msgid $dragged_msgid;
    switch -nocase  -- $type {
	"nucleus" {
	    set prnt_nid $dragged_nid;
	    set prnt_msgid $dragged_msgid;
	    set chld_nid $clicked_nid;
	    set chld_msgid $clicked_msgid;
	}
	"nucleus-embedded" {
	    set prnt_nid $dragged_nid;
	    set prnt_msgid $dragged_msgid;
	    set chld_nid $clicked_nid;
	    set chld_msgid $clicked_msgid;
	    set relation "$relation-embedded";
	}
	"satellite" {
	}
	"satellite-embedded" {
	    set relation "$relation-embedded";
	}
	"multinuclear" {
	    set multinuc 1;
	}
	default {
	    error "Invalid dependecy type: $type";
	    return;
	}
    }

    if {$multinuc} {
	link-multinuc $prnt_nid $chld_nid $relation $NODES($prnt_nid,parent) \
	    $ext_connection $chld_msgid $prnt_msgid;
    } else {
	link-chld-to-prnt $chld_nid $prnt_nid $relation $NODES($prnt_nid,parent) \
	    $ext_connection $chld_msgid $prnt_msgid;
    }
    ::rsttool::set-state {changed} \
	"Linked $NODES($chld_nid,name) to $NODES($prnt_nid,name) as $relation";
    # xscrollto [max $NODES($dragged_nid,xpos) $NODES($clicked_nid,xpos)]
    # yscrollto [max $NODES($dragged_nid,ypos) $NODES($clicked_nid,ypos)]
    return;
}

proc ::rsttool::treeditor::tree::link-multinuc {a_nid1 a_nid2 a_relation \
						    {a_span_nid {}} {a_ext_rel 0} \
						    {a_chld_msgid {}} {a_prnt_msgid {}}} {
    variable ::rsttool::NODES;

    if {$a_ext_rel} {return;}

    set chld1_wdgt [ntw $a_nid1];
    set chld2_wdgt [ntw $a_nid2];

    # create span node, if necessary
    if {$a_span_nid == {}} {
	set ypos [expr max($NODES($a_nid1,ypos),$NODES($a_nid2,ypos))];
	set xpos [expr min($NODES([node::get-start-node $a_nid1],xpos),\
			       $NODES([node::get-start-node $a_nid2],xpos))];
	set a_span_nid [make-span-node $a_nid1 $a_nid2 $a_relation 1 $a_ext_rel];
	set NODES($a_span_nid,ypos) $ypos;
	puts stderr "link-multinuc: xlayout-group-node $a_span_nid $xpos";
	::rsttool::treeditor::layout::xlayout-group-node $a_span_nid $xpos;
	# erase both child subtrees
	erase-subtree $a_nid1;
	erase-subtree $a_nid2;
	# then, we redraw the subtree from the span nid
	::rsttool::treeditor::layout::y-layout-subtree $a_span_nid $ypos;
    } else {
	set NODES($a_nid2,parent) $a_span_nid;
	set NODES($a_nid2,relname) $a_relation;
	set NODES($a_nid2,reltype) $HYPOTACTIC;
    }
}

proc ::rsttool::treeditor::tree::link-chld-to-prnt {a_chld_nid a_prnt_nid a_relation \
							 {a_span_nid {}} {a_ext_rel 0} \
							{a_chld_msgid {}} {a_prnt_msgid {}}} {
    variable ::rsttool::NODES;
    variable ::rsttool::NID2ENID;
    variable ::rsttool::NID2MSGID;
    variable ::rsttool::relations::SPAN;
    variable ::rsttool::relations::HYPOTACTIC;
    namespace import ::rsttool::utils::ldelete;

    if {$a_ext_rel} {return;}

    set prnt_wdgt [ntw $a_prnt_nid]
    set chld_wdgt [ntw $a_chld_nid]

    if {$a_chld_msgid == {}} {set a_chld_msgid $NID2MSGID($a_chld_nid);}
    # update parent and relation of the child node
    set NODES($a_chld_nid,parent) $a_prnt_nid;
    set NODES($a_chld_nid,relname) $a_relation;
    set NODES($a_chld_nid,reltype) $HYPOTACTIC;
    # append child node to the list of the parent's children
    set NODES($a_prnt_nid,children) [node::insort $NODES($a_prnt_nid,children) \
					 $NODES($a_chld_nid,start) $a_chld_nid];


    # create a span node for the parent, if it's needed
    if {$a_span_nid == {}} {
	set ypos $NODES($a_prnt_nid,ypos);
	set a_span_nid [make-span-node $a_prnt_nid $a_chld_nid $a_relation 0 $a_ext_rel];
	# since all subtree of the parent will shift down, we have to erase this subtree first
	erase-subtree $a_prnt_nid;
	# then, we redraw the subtree from the span nid
	::rsttool::treeditor::layout::y-layout-subtree $a_span_nid $ypos;
    } else {
	# remove child node from the list of message roots
	::rsttool::treeditor::update-roots $a_chld_msgid $a_chld_nid {remove};
	::rsttool::treeditor::layout::update-upwards $a_span_nid $a_chld_nid;
	::rsttool::treeditor::layout::y-layout-subtree $a_prnt_nid;
    }
}

proc ::rsttool::treeditor::tree::make-span-node {a_prnt_nid a_chld_nid a_reltype \
						     {a_multinuc 0} {a_ext_rel 0}} {
    variable ::rsttool::NODES;
    variable ::rsttool::NID2MSGID;
    variable ::rsttool::relations::SPAN;
    variable ::rsttool::relations::HYPOTACTIC;
    variable ::rsttool::relations::PARATACTIC;
    variable ::rsttool::treeditor::VISIBLE_NODES;
    namespace import ::rsttool::treeditor::tree::node::insort;

    set chld_start [node::get-start $a_chld_nid];
    set prnt_start [node::get-start  $a_prnt_nid];
    set chld_end [node::get-end $a_chld_nid];
    set prnt_end [node::get-end  $a_prnt_nid];

    set span_nid [node::make [expr $a_ext_rel ? {{external}} : {{internal}} ] \
		      [expr $chld_start < $prnt_start ? $a_chld_nid: $a_prnt_nid] \
		      [expr $chld_end < $prnt_end ? $a_prnt_nid: $a_chld_nid] \
		      {} $NID2MSGID($a_prnt_nid)];
    # set span node as the parent of the parent node
    lappend NODES($a_prnt_nid,parent) $span_nid;
    # add parent node to the list of span childrens
    set NODES($span_nid,children) [list $a_prnt_nid];
    # for multinuclear span, append both nodes
    if {$a_multinuc} {
	set NODES($a_prnt_nid,relname) $a_reltype;
	set NODES($a_prnt_nid,reltype) $PARATACTIC;

	set NODES($span_nid,children) [insort $NODES($span_nid,children) $chld_start $a_chld_nid];
	lappend NODES($a_chld_nid,parent) $span_nid;
	set NODES($a_chld_nid,relname) $a_reltype;
	set NODES($a_chld_nid,reltype) $PARATACTIC;
    } else {
	set NODES($a_prnt_nid,relname) {span};
	set NODES($a_prnt_nid,reltype) $SPAN;
	# position span nid at the previous position of the parent nid
	set NODES($span_nid,xpos) $NODES($a_prnt_nid,xpos);
    }
    # remember this span as external, if needed
    if {$a_ext_rel} {
	set NID2ENID($a_prnt_nid) $span_nid;
    }
    # remove parent node from the roots
    set prnt_msgid $NID2MSGID($a_prnt_nid);
    set chld_msgid $NID2MSGID($a_chld_nid);

    set VISIBLE_NODES($span_nid) 1;

    ::rsttool::treeditor::update-roots $prnt_msgid $a_prnt_nid {remove};
    ::rsttool::treeditor::update-roots $chld_msgid $a_chld_nid {remove};
    # insort new span node
    ::rsttool::treeditor::update-roots $prnt_msgid $span_nid {add};
    return $span_nid;
}

proc ::rsttool::treeditor::tree::erase-subtree {a_nid} {
    variable ::rsttool::NODES;
    variable ::rsttool::treeditor::VISIBLE_NODES;

    puts stderr "*** erase-subtree: a_nid = $a_nid"
    node::erase $a_nid;
    foreach chnid $NODES($a_nid,children) {
	if {[info exists VISIBLE_NODES($chnid)]} {
	    erase-subtree $chnid;
	}
    }
}

proc ::rsttool::treeditor::tree::unlink {sat {redraw 1}} {
    variable ::rsttool::NODES;
    variable ::rsttool::NID2MSGID;
    namespace import ::rsttool::utils::ldelete;
    namespace import ::rsttool::treeditor::destroy-group-node;
    namespace import ::rsttool::treeditor::tree::node::group-node-p;

    return;
    # 1. handle missed clicks
    if {$sat == {} || $NODES($sat,parent) == {}} {return}

    # 1. Delete connection between `sat` and its parent
    set nuc $NODES($sat,parent)
    set node($nuc,children) [ldelete $NODES($nuc,children) $sat]
    set node($sat,parent) {}
    set node($sat,relname) {}
    set spannid {}
    if {[info exists NODES($nuc,parent)] && $NODES($nuc,relname) == "span"} {
	set spannid $NODES($nuc,parent)
    }
    # puts stderr "unlink-node: sat = $sat (children: $NODES($sat,children))"
    # puts stderr "unlink-node: nuc = $nuc (children: $NODES($nuc,children))"
    # if {$spannid != {}} {puts stderr "unlink-node: spannid = $spannid  (children: $NODES($spannid,children))"}

    # 2. Redraw satellite substructure
    if {$redraw} {layout::y-layout-subtree $sat}
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
	if {$NID2MSGID($nuc) == $NID2MSGID($sat)} {
	    foreach chnid $NODES($nuc,children) {
		if {$NODES($chnid,relname) != "span"} {
		    set dgn 0
		    break
		}
	    }
	    if {[llength $NODES($nuc,children)] == 1} {
		set dgn 1
		destroy $nuc
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
	    destroy $nuc $redraw
	}
    }
    # puts stderr "unlink-node: restructure-upwards nuc = $nuc redraw = $redraw"
    ::rsttool::treeditor::layout::update-upwards $nuc $redraw
}

proc rsttool::treeditor::tree::screen-coords {item canvas} {
    namespace import ::rsttool::utils::add-points;
    namespace import ::rsttool::utils::subtract-points;

    # Returns the screen coordes of a canvas item
    set screencorrect "[winfo rootx $canvas] [winfo rooty $canvas]"
    set coords [$canvas coords $item]

    set scrollcorrection "[$canvas canvasx 0] [$canvas canvasy 0]"
    return [add-points [subtract-points $coords $scrollcorrection]\
		$screencorrect]
}

proc ::rsttool::treeditor::tree::popup-choose-from-list {Items xpos ypos {put_cancel {}} \
							     {tooltip_cmd {}}} {
    variable ::rsttool::treeditor::menu_selection;

    namespace import ::rsttool::utils::menu::add-item; # AddMenuItem
    namespace import ::rsttool::utils::menu::add-cascade; # AddMenuCascade
    namespace import ::rsttool::utils::menu::bind-tooltip; # bind-menu-tooltip
    namespace import ::rsttool::utils::menu::selection; # menu selection

    set num_items 0
    set cancel_exists 0
    set my_menu .tmpwin
    set menu_selection {}

    if {[winfo exists $my_menu]} {destroy $my_menu}
    menu $my_menu -tearoff 0
    if {$tooltip_cmd != {}} {
	bind-tooltip $my_menu $tooltip_cmd;
    }

    foreach item $Items {
	if {$num_items < 33} {
	    add-item $my_menu $item "set ::rsttool::treeditor::menu_selection $item"
	} else {
	    #set underscore ""
	    #append underscore $item
	    #set item $underscore
	    set icascade "$my_menu.[string tolower $item]";
	    menu $icascade -tearoff 0;
	    add-cascade $my_menu NEXT $icascade;
	    if {$tooltip_cmd != {}} {
		bind-tooltip $icascade "$tooltip_cmd";
	    }
	    add-item $my_menu CANCEL "set ::rsttool::treeditor::menu_selection {}"
	    set cancel_exists 1
	    bind $my_menu <Any-Leave> {set ::rsttool::treeditor::menu_selection {}};
	    set my_menu $icascade
	    add-item $my_menu $item "set ::rsttool::treeditor::menu_selection $item"
	    set num_items 0
	}
	incr num_items
    }

    if { $put_cancel && !$cancel_exists } {
	add-item $my_menu CANCEL "set ::rsttool::treeditor::menu_selection {}"
    }

    # now make the menu
    bind $my_menu <Any-Leave> {set ::rsttool::treeditor::menu_selection {}};
    .tmpwin post $xpos $ypos;
    if {[tk windowingsystem] != "aqua"} {
	tkwait variable ::rsttool::treeditor::menu_selection;
    }
    .tmpwin unpost;
    if [winfo exists .tmpwin.tooltip] {destroy .tmpwin.tooltip}

    puts stderr "popup-choose-from-list: menu_selection = $menu_selection"
    return $menu_selection
}

proc ::rsttool::treeditor::tree::choose-label {sat type {external 0}} {
    variable ::rsttool::treeditor::RSTW;
    variable ::rsttool::relations::RELATIONS;
    variable ::rsttool::relations::ERELATIONS;
    variable ::rsttool::relations::PARATACTIC;
    variable ::rsttool::relations::HYPOTACTIC;
    variable ::rsttool::relations::TYPE2REL;
    variable ::rsttool::relations::TYPE2EREL;

    set relations {};
    switch -nocase -- $type {
	"nucleus" -
	"satellite" -
	"nucleus-embedded" -
	"satellite-embedded" {
	    if {$external} {
		set relations $TYPE2EREL($HYPOTACTIC);
	    } else {
		set relations $TYPE2REL($HYPOTACTIC);
	    }
	}
	"multinuclear" {
	    if {$external} {
		set relations $TYPE2EREL($PARATACTIC);
	    } else {
		puts stderr "TYPE2REL($PARATACTIC) = $TYPE2REL($PARATACTIC)"
		set relations $TYPE2REL($PARATACTIC);
	    }
	}
	default {
	    error "Unknown dependency type: '$type'"
	    return {};
	}
    }

    set coords [screen-coords [ntw $sat] $RSTW];
    return [popup-choose-from-list $relations \
		[expr int([lindex $coords 0])]\
		[expr int([lindex $coords 1])] 1 \
		[list ::rsttool::treeditor::tree::relation-tooltip $external]];
}

proc ::rsttool::treeditor::tree::relation-tooltip {a_ext_reltype a_wdgt} {
    variable ::rsttool::helper::RELHELP;

    puts stderr "::rsttool::treeditor::tree::relation-tooltip called"
    # obtain menu entry
    set mitem [$a_wdgt entrycget active -label];
    set reltype {internal};
    if {$a_ext_reltype} {
	set reltype {external};
    }
    # show help tooltip for menu entry
    if {[info exists RELHELP($mitem,$reltype)]} {
	# construct help message
	set help "[string toupper $mitem]\n";
	foreach idesc {description type nucleus satellite nucsat effect connectives \
			   example comment} {
	    if {$RELHELP($mitem,$reltype,$idesc) != {}} {
		append help "\n[string totitle $idesc]: $RELHELP($mitem,$reltype,$idesc)\n";
	    }
	}
	::rsttool::utils::menu::tooltip $a_wdgt $help
    }
}

##################################################################
package provide rsttool::treeditor::tree 0.0.1
return