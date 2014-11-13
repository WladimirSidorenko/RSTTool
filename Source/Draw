# -*- mode: tcl; -*-
###########################################
# DRAW
# Functions used by RST-Tool for drawing arcs rst-nodes and
# relation-arcs between them


####################################################
# Draw the RST Tree
proc show-rst {} {
    global node group_nodes text_nodes rstw visible_nodes
    # go through each text and seq node and display it.
    foreach nid [concat $group_nodes $text_nodes] {
	if $node($nid,visible) {
	    display-node $nid
	}
    }
}

proc display-node {nid} {
    global node rstw node_width group_nodes wtn
    # puts stderr "display-node: $nid"

    set text $node($nid,text)
    if { $nid > 5000 } {
	set text "$text"
    } else {
	set text "($nid)\n$text"
    }
    set xpos $node($nid,xpos)
    set ypos [expr $node($nid,ypos) + 2]
    # puts stderr "display-node: xpos = $xpos"
    # puts stderr "display-node: ypos = $ypos"

    # puts stderr "display-node: step 1 (nid = $nid; text = $text)"
    if { $node($nid,constit) != {} } {
	set color "blue"
	set wgt [draw-text $rstw $node($nid,constit) $xpos $ypos\
		     "-width $node_width -fill $color"]
	set ypos [expr $ypos + 15]
    }
    # puts stderr "display-node: step 2"

    if [group-node-p $nid] {
	set color "green"
    } else {
	set color "black"
    }
    set wgt [draw-text $rstw $text $xpos $ypos\
		 "-width $node_width -fill $color"]

    # puts stderr "display-node: step 3"
    set node($nid,textwgt) $wgt
    set wtn($wgt) $nid
    display-span $nid
    display-arc $nid
}

proc display-span {nid} {
    global rstw node visible_nodes half_node_width last_text_node_id
    # puts stderr "display-span: $nid $node($nid,span)"
    # draw span line, from start of first node, to end of second
    # puts stderr "display-span: nid = $nid"

    if { $nid == 0 } { return }

    set span $node($nid,span)
    set ypos $node($nid,ypos)

    set min 999999
    set max 0

    #  # find the left+rightmost visible nodes
    #
    #  set flag 1
    #
    #  for  {set i [lindex $span 0]} {$i <= [lindex $span 1]} {incr i 1} {
    #   if { $flag && $i > $last_text_node_id } { 
    #     set i 5001 
    #     set flag 0
    #   }
    #   set par $node($i,parent)
    #   if { $node($i,visible) == 1} {
    #     if { $i < $min } {set min $i}
    #     if { $i > $max } {set max $i}
    #   } elseif { $node($i,relname) == "span" } {
    #     if { $node($par,visible) == 1 } {
    #       if { $i < $min } {set min $i}
    #       if { $i > $max } {set max $i}
    #     }
    #   } 
    #  }
    #
    #  if { $min == 999999 } { set min $nid}
    #  if { $max == 0      } { set max $nid}

    # find the positions of the left & rightmost visible nodes
    set primary_children {}
    # puts stderr "display-span: node($nid,type) == $node($nid,type)"
    # puts stderr "display-span: node($nid,children) == $node($nid,children)"
    if { $node($nid,type) == "text" } {
    } elseif { $node($nid,type) == "span" } {
	foreach child $node($nid,children) {
	    if { $node($child,relname) == "span" } {
		lappend primary_children $child
	    }
	}
    } elseif { $node($nid,type) == "multinuc" } {
	foreach child $node($nid,children) {
	    if { [group-relation-p $node($child,relname)] } {
		lappend primary_children $child
	    }
	}
    } elseif { $node($nid,type) == "constit" } {
	foreach child $node($nid,children) {
	    if { [group-relation-p $node($child,relname)] } {
		lappend primary_children $child
	    }
	}
    }
    # puts stderr "display-span: iterating over primary children ($primary_children)"
    set max_generations 15000
    while { $primary_children != {} } {
	set next_generation {}
	incr max_generations -1
	if {$max_generations == 0} {error "Maximum number of generations exceeds limit."}

	foreach child $primary_children {
	    # puts stderr "display-span: child = $child; node($child,children) = $node($child,children); next_generation = $next_generation; "
	    foreach grandchild $node($child,children) {
		lappend next_generation $grandchild
	    }
	    if [info exists visible_nodes($child)] {
		set this_xpos $node($child,xpos)
		if { $this_xpos < $min } {set min $this_xpos}
		if { $this_xpos > $max } {set max $this_xpos}
	    }
	}
	set primary_children $next_generation
    }
    # puts stderr "display-span: iteration done"

    set this_xpos $node($nid,xpos)
    if { $min == 999999 } { set min $this_xpos }
    if { $max == 0      } { set max $this_xpos }

    # draw the span-line
    set node($nid,spanwgt) [draw-line $rstw\
				[expr $min - $half_node_width] $ypos\
				[expr $max + $half_node_width] $ypos]
    #        [expr $node($min,xpos) - $half_node_width] $ypos\
	#        [expr $node($max,xpos) + $half_node_width] $ypos]
}


proc display-arc {sat} {
    global rstw node text_nodes relations visible_nodes
    set nuc $node($sat,parent)
    # puts stderr "display-arc: sat = $sat; nuc = $nuc"
    if {$nuc == {} || ! [info exists visible_nodes($nuc)]} {return}

    # erase-arc $sat
    # set some variables
    set ypos $node($sat,ypos)
    set reltype [relation-type $node($sat,relname)]
    set color "red"
    set satpnt "$node($sat,xpos) $node($sat,ypos)"
    set nucbot [bottom-point [ntw $nuc]]
    set label $node($sat,relname)

    # puts stderr "display-arc: reltype = $reltype; label = $label"
    switch -- $reltype {
	embedded { 	#draw an embedded linker (an arc from nuctop to sattop)
	    set color "blue"
	    if {$node($nuc,constit) != {}} {
		set nucpnt [add-points [$rstw coords [ntw $nuc]] {0 -17}]
	    } else {
		set nucpnt [add-points [$rstw coords [ntw $nuc]] {0 -2}]
	    }
	    set midpnt [subtract-points [mid-point $nucpnt $satpnt] "0 20"]
	    set labelpnt [subtract-points $midpnt {0 6}]
	    set node($sat,arrowwgt)\
		[draw-arc $rstw [concat $nucpnt $midpnt $satpnt]]
	}
	constit  { set node($sat,arrowwgt) \
		       [$rstw create line [lindex $nucbot 0] [lindex $nucbot 1]\
			    [lindex $satpnt 0] [lindex $nucbot 1]\
			    [lindex $satpnt 0] [lindex $satpnt 1]]
	    set labelpnt [subtract-points $satpnt {0 15}]
	}
	multinuc { set node($sat,arrowwgt)\
		       [draw-line-between $rstw $nucbot $satpnt]
	    set labelpnt [add-points $nucbot {0 15}]}
	span     { set node($sat,arrowwgt)\
		       [draw-line-between $rstw $nucbot $satpnt]
	    set labelpnt [subtract-points $satpnt {0 15}]
	    #NEW constit hack
	}
	default {  #draw an rst linker (an arc from nuctop to sattop)
	    # puts stderr "display-arc: node($nuc,constit) = $node($nuc,constit)"
	    if {$node($nuc,constit) != {}} {
		set nucpnt [add-points [$rstw coords [ntw $nuc]] {0 -17}]
	    } else {
		set nucpnt [add-points [$rstw coords [ntw $nuc]] {0 -2}]
	    }
	    set midpnt [subtract-points [mid-point $nucpnt $satpnt] {0 20}]
	    set labelpnt [subtract-points $midpnt {0 6}]
	    # temp hack
	    # puts "XXX: $nuc [expr [find-first-text-node $sat] - 1]"
	    #   if { $nuc == [expr [find-first-text-node $sat] - 2] } {
	    #       set  labelpnt [add-points $labelpnt "40 0"]
	    #   }
	    # puts stderr "display-arc: node($sat,arrowwgt) = draw-arc $rstw concat $nucpnt $midpnt $satpnt"
	    set node($sat,arrowwgt)\
		[draw-arc $rstw [concat $nucpnt $midpnt $satpnt]]
	    # puts stderr "display-arc: node($sat,arrowwgt) = $node($sat,arrowwgt)"
	}
    }

    # Draw the Label
    if { $reltype != "span" } {
	# puts stderr "label = $label; labelpnt = $labelpnt"
	set node($sat,labelwgt) [draw-text $rstw $label [lindex $labelpnt 0] \
				     [lindex $labelpnt 1] "-fill $color"]
	#TESTING
	#  } elseif { $reltype == "span" && $node($sat,constit) != {} } {
	#    set label $node($sat,constit)
	#    set node($sat,labelwgt) [draw-text $rstw $label $labelpnt "-fill $color"]
    }
    #NEW constit hack
}

proc erase-subtree {nid} {
    global node visible_nodes
    erase-node $nid
    foreach cid $node($nid,children) {
	erase-subtree $cid
    }
}

proc erase-node {nid} {
    global rstw node visible_nodes
    # puts stderr "erase-node:  erasing nid = $nid"
	$rstw delete [ntw $nid]
	$rstw delete $node($nid,spanwgt)
	set wtn([ntw $nid]) {}
	set node($nid,textwgt) {}
	set node($nid,spanwgt) {}
	erase-arc $nid
}

proc erase-arc {nid} {
    global rstw node
    debug "erase-arc: $nid"
    if { $node($nid,arrowwgt) != {} } {
	# puts stderr "erase-arc: erasing arc for nid = $nid"
	$rstw delete $node($nid,arrowwgt)
    }
    if { $node($nid,labelwgt) != {} } {
	$rstw delete $node($nid,labelwgt)
    }
}

proc redraw-subtree {nid} {
    global node visible_nodes

    erase-node $nid
    display-node $nid
    foreach cid $node($nid,children) {
	if [info exists visible_nodes($cid)] {
	    redraw-subtree $cid
	}
    }
}

proc redisplay-node {nid} {
    # wipes the old version before drawing
    global node

    # puts stderr "redisplay-node: nid = $nid; node($nid,textwgt) = $node($nid,textwgt)"
    if { $node($nid,textwgt) != {} } {
	# puts stderr "redisplay-node: calling erase-node $nid"
	erase-node $nid
	# puts stderr "redisplay-node: erase-node $nid done"
    }
    # puts stderr "redisplay-node: calling display-node $nid"
    # puts stderr "redisplay-node: display-node $nid"
    display-node $nid
    # puts stderr "redisplay-node: display-node $nid done"
}

proc redraw-child-arcs {nid} {
    # redraws the child-arcs pointing at this node
    global visible_nodes node
    debug "redraw-child-arcs: $nid"
    foreach cid $node($nid,children) {
	if [info exists visible_nodes($cid)] {
	    erase-arc $cid
	    display-arc $cid
	}
    }
}
