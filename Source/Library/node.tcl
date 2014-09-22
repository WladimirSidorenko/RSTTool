#!/usr/bin/env wish

# Variables and methods for handling nodes.

###########
# Methods #
###########
proc make-boundary-marker {nid} {
    return "<$nid>"
}

proc get-node-number {a_path x y {start {}}} {
    # set default return values
    set nnumber -1
    # set auxiliary variables
    set choffset 1; set prev_char ""
    # obtain number of node located at coordinates (x, y) or next to `start`
    # index
    set spoint "@$x,$y"
    if {$start != {}} {
	set spoint $start
    } elseif {$x == {}} {
	return {-1 {} {}}
    }
    set nnumber [$a_path get -- "$spoint wordstart" "$spoint wordend"]
    # obtain range of bmark tag around `spoint`
    lassign [$a_path tag prevrange bmarker "$spoint wordend"] istart iend

    while {$nnumber == ">" || $nnumber == "<"} {
	switch -- $nnumber {
	    "<" {
		if {$prev_char == ">"} {break}
		set prev_char "<"
		set nnumber [$a_path get -- "$spoint +$choffset chars wordstart" \
				 "$spoint +$choffset chars wordend"]
	    }
	    ">" {
		if {$prev_char == "<"} {break}
		set prev_char ">"
		set nnumber [$a_path get -- "$spoint -$choffset chars wordstart" \
				 "$spoint -$choffset chars wordend"]
	    }
	    default {
		if {! [string is space $nnumber]} {
		    break
		}
	    }
	}
	incr choffset
    }

    if {! [string is digit $nnumber]} {
	set nnumber -1; set istart {}; set iend {}
    }
    return [list $nnumber $istart $iend]
}

proc clear-node {nid} {
    global node visible_nodes nid2msgid msgid2nid msgs2extnid

    set node($nid,text) {}
    set node($nid,type) {}
    set node($nid,textwgt) {}
    set node($nid,labelwgt) {}
    set node($nid,arrowwgt) {}
    set node($nid,spanwgt) {}
    set node($nid,relname) {}
    set node($nid,children) {}
    set node($nid,parent) {}
    set node($nid,constituents) {}
    set node($nid,visible) 1
    set node($nid,span)  {}
    set node($nid,offsets)  {}
    set node($nid,xpos) 0
    set node($nid,ypos) 0
    set node($nid,oldindex) {}
    set node($nid,newindex) {}
    set node($nid,constit) {}
    set node($nid,promotion) {}

    if [info exists visible_nodes($nid)] {unset visible_nodes($nid)}
    puts stderr "unsetting visible_nodes($nid)"
    if {[info exists nid2msgid($nid)]} {
	if {[llength $nid2msgid($nid)] > 1} {
	    if [info exists msgs2extnid([join $nid2msgid($nid) ","])] {
		unset msgs2extnid([join $nid2msgid($nid) ","])
	    }
	} else {
	    set idx [lsearch $msgid2nid($nid2msgid($nid)) $nid]
	    set msgid2nid($nid2msgid($nid)) [lreplace $msgid2nid($nid2msgid($nid)) $idx $idx]
	    unset nid2msgid($nid)
	}
    }
}

proc make-node {text type {start_pos {}} {end_pos {}}} {
    global node crntMsgId msgid2nid nid2msgid visible_nodes
    if { $type ==  "text"  } {
	set nid [unique-text-node-id]
	# save mapping from node id to message id
	set nid2msgid($nid) [list $crntMsgId]
	# save mapping from message id to node id
	if {[info exists msgid2nid($crntMsgId)]} {
	    lappend msgid2nid($crntMsgId) $nid
	} else {
	    set msgid2nid($crntMsgId) [list $nid]
	}
    } else {
	set nid [unique-group-node-id]
    }
    clear-node $nid
    set node($nid,text) $text
    set node($nid,type) $type
    set node($nid,offsets) [list $start_pos $end_pos]
    set visible_nodes($nid) 1
    # puts stderr "Created node $nid with offsets $start_pos $end_pos"

    if {$type ==  "text"} {
	set node($nid,span) "$nid $nid"
	add-text-node $nid
    } else {
	add-group-node $nid
    }
    return $nid
}

proc move-node {a_path x y X Y} {
    puts stderr "move-node: x = $x"
    puts stderr "move-node: y = $y"
    puts stderr "move-node: X = $X"
    puts stderr "move-node: Y = $Y"
}

proc delete-node {a_path x y} {
    global node crntMsgId msgid2nid last_text_node_id offsetShift
    # obtain number of node located at coordinates (x, y)
    lassign [get-node-number $a_path $x $y] inid istart iend
    puts stderr "inid = $inid; istart = $istart; iend = $iend;"
    if {$istart == -1} {
	return
    } elseif {$inid == $last_text_node_id} {
	incr last_text_node_id -1
    }
    # find next node in text
    set nxtstart [lindex [$a_path tag nextrange bmarker $iend] 0]
    # if next node exists, append text from deleted node to this next node
    if {$nxtstart != {}} {
	set nxtnid [lindex [get-node-number $a_path {} {} $nxtstart] 0]
	set node($nxtnid,text) "$node($inid,text) $node($nxtnid,text)"
    } else {
	# obtain range of previous node, if any exists
	set prevend [lindex [$a_path tag prevrange bmarker "$istart -1 char"] end]
	# remove tag `old` from the text span covered by the node which should
	# be deleted
	if {$prevend == {}} {set prevend 1.0}
	$a_path tag remove old $prevend $istart
    }
    # delete node marker
    $a_path delete $istart $iend
    # adjust offset shifts of offsets of all successive nodes
    set delta [string length [$a_path get $istart $iend]]
    set offsetShift [expr $offsetShift - $delta]
    foreach nid $msgid2nid($crntMsgId) {
	if {$nid > $inid} {
	    set old_offsets $node($nid,offsets)
	    set new_offsets {}
	    foreach off $old_offsets {
		lappend new_offsets [expr $off - $delta]
	    }
	    set node($nid,offsets) $new_offsets
	}
    }
    destroy-node $inid
    redisplay-net
}

proc create-a-node-here { do_it {my_current {}} {junk1 {}} {junk2 {}} } {
    global last_text_node_id newest_node savenum new_node_text
    global offsetShift
    global x1 x2
    # if no index was specified, set index position to the position of
    # the cursor and move it to the left, if currently pointed
    # character is a space
    if {$my_current == {}} {
	set my_current current
	while {[.editor.text compare $my_current > 1.0] && \
		   [string is space [.editor.text get $my_current]]} {
	    set my_current "$my_current -1 chars"
	}
    }
    # determine position of the last non-space character
    set my_end "end -1 chars"
    while {[.editor.text compare $my_end > 1.0]} {
	if {[string is space [.editor.text get $my_end]]} {
	    set my_end "$my_end -1 chars"
	} else {
	    set my_end "$my_end +1 chars"
	    break
	}
    }
    # put mark called `insert` before current position -- current is position
    # nearest to the mouse pointer
    .editor.text mark set insert $my_current
    # if we pointed with the mouse to an already analyzed area, then do nothing
    if {[.editor.text tag ranges new] == {} || [.editor.text compare new.first > $my_current]} {return}
    # remove tag `my_sel` from the whole text area
    .editor.text tag remove my_sel 1.0 end
    if { $do_it == "really" } {
	.editor.text tag add sel new.first "insert wordend"
	.editor.text tag add my_sel new.first "insert wordend"
    } else {
	.editor.text tag add sel new.first insert
	.editor.text tag add my_sel new.first insert
    }

    # obtain indices of the last char in selection and the end of the text
    set x [.editor.text index my_sel.last]
    set y [.editor.text index end]
    # put mark `last_sel` just before the last character in `my_sel`
    .editor.text mark set last_sel my_sel.last
    if {$x == $y} {
	.editor.text mark set last_sel "my_sel.last - 1 chars"
  	.editor.text tag remove sel last_sel sel.last
  	.editor.text tag remove my_sel last_sel my_sel.last
    }

    set the_selection [selection get]
    set new_node_text $the_selection
    regsub -all "\n" $new_node_text " " new_node_text
    regsub -all "\t" $new_node_text " " new_node_text
    regsub -all " +" $new_node_text " " new_node_text
    regsub -all "\"" $new_node_text "" new_node_text

    if { "$do_it" == "really" } {
  	incr savenum
	set start_pos [expr [.editor.text count -chars 1.0 sel.first] - $offsetShift]
	set end_pos [expr [.editor.text count -chars 1.0 sel.last] - $offsetShift]
  	set newest_node [make-node $new_node_text "text" $start_pos $end_pos]
  	redisplay-net
    }

    .editor.text mark set insert last_sel
    .editor.text tag add old my_sel.first last_sel
    .editor.text tag remove sel sel.first last_sel
    .editor.text tag remove next next.first last_sel
    .editor.text tag remove new new.first last_sel

    set boundary_marker [make-boundary-marker $last_text_node_id]
    set offsetShift [expr $offsetShift + [string length $boundary_marker]]
    .editor.text insert my_sel.last "$boundary_marker" bmarker
    # call nextSentence() if suggested EDU span was completely covered
    if {[.editor.text tag ranges next] == {} || \
	    [.editor.text compare "next.last -1 chars" <= last_sel]} {
	nextSentence $do_it
    }

    set line_no [.editor.text index old.last]
    .editor.text yview [expr int($line_no)]
    .editor.text tag add notes my_sel.last new.first
}
