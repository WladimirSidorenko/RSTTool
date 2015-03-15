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

proc ::rsttool::treeditor::tree::arc::change_rel {nid {relname {}} } {
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

proc ::rsttool::treeditor::choose-label {sat type {external 0}} {
    global relations extRelations rstw schemas schema_elements
    debug "choose-label: $sat $type"

    set coords [screen-coords [ntw $sat] $RSTW]
    set conv(satellite) rst
    set conv(nucleus) rst
    set conv(rst) rst
    set conv(multinuclear) multinuc
    set conv(multinuc) multinuc
    set conv(schema) constit
    set conv(constit) constit
    set conv(nucleus-embedded) embedded
    set conv(satellite-embedded) embedded
    set conv(embedded) embedded
    set type $conv($type)

    if {$external} {
	# Choose connection type from a set of external relations
	set range $extRelations
    } elseif [member $type {rst constit multinuc embedded}] {
	# Choose from the defined set
	set range $relations($type)
    } else {
	# this must be a schema type, choose from that set
	set range $schema_elements($type)
    }
    return [popup-choose-from-list $range\
		[expr int([lindex $coords 0])]\
		[expr int([lindex $coords 1])] 0 1]
}

proc ::rsttool::treeditor::popup-choose-from-list {Items xpos ypos {put_cancel {}} {show_tooltip 0}} {
    global pcfl_selection
    set pcfl_selection {}
    if {[winfo exists .tmpwin]} {destroy .tmpwin}
    menu .tmpwin -tearoff 0
    set num_items 0
    set cancel_exists 0
    set my_menu .tmpwin
    if {$show_tooltip} {
	bind-menu-tooltip $my_menu
    }

    foreach item $Items {
	if {$num_items < 33} {
	    AddMenuItem $my_menu $item "set pcfl_selection $item"
	} else {
	    #set underscore ""
	    #append underscore $item
	    #set item $underscore
	    menu $my_menu.$item -tearoff 0
	    AddMenuCascade $my_menu NEXT $my_menu.$item
	    if {$show_tooltip} {
		bind-menu-tooltip $my_menu.$item
	    }
	    AddMenuItem $my_menu CANCEL "set pcfl_selection {}"
	    set cancel_exists 1
	    set my_menu $my_menu.$item
	    AddMenuItem $my_menu $item "set pcfl_selection $item"
	    set num_items 0
	}
	incr num_items
    }

    if { $put_cancel != "NOcancel" && $cancel_exists == 0 } {
	AddMenuItem .tmpwin CANCEL "set pcfl_selection {}"
    }

    # now make the popup
    .tmpwin post $xpos $ypos
    if {[tk windowingsystem] != "aqua"} {
	tkwait variable pcfl_selection
    }
    .tmpwin unpost
    if [winfo exists .tmpwin.tooltip] {destroy .tmpwin.tooltip}

    return $pcfl_selection
}

##################################################################
package provide rsttool::treeditor::tree::arc 0.0.1
return
