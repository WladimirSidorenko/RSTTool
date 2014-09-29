#!/usr/bin/env wish

# Variables and methods for handling nodes.

###########
# Methods #
###########
proc get-node-number {a_path x y {start {}}} {
    # set default return values
    set nnumber {}
    # set auxiliary variables
    set choffset 1; set prev_char ""
    # obtain number of node located at coordinates (x, y) or next to `start`
    # index
    set spoint "@$x,$y"
    if {$start != {}} {
	set spoint $start
    } elseif {$x == {}} {
	return {{} {} {}}
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
	set nnumber {}; set istart {}; set iend {}
    }
    return [list $nnumber $istart $iend]
}

proc create-a-node-here { do_it {my_current {}} {junk1 {}} {junk2 {}} } {
    global offsetShift
    global last_text_node_id newest_node savenum new_node_text

    # if no index was specified, set index position to the position of
    # the cursor and move it to the left, if currently pointed
    # character is a space
    if {$my_current == {}} {
	set my_current current
	while {[.editor.text compare $my_current > 1.0]} {
	    if {[string is space [.editor.text get $my_current]]} {
		set my_current "$my_current -1 chars"
	    } else {
		# set my_current "$my_current wordend"
		break
	    }
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
    # puts stderr "create-a-node-here: my_current = $my_current"
    # puts stderr "create-a-node-here: my_end = $my_end"
    # put mark called `insert` before current position -- current is position
    # nearest to the mouse pointer
    .editor.text mark set insert $my_current
    # if we pointed with the mouse to an already analyzed area, then do nothing
    if {[.editor.text tag ranges new] == {} || \
	    [.editor.text compare new.first >= $my_current]} {
	return
    }
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
	# puts stderr "create-a-node-here: offsetShift == $offsetShift"
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

proc make-boundary-marker {nid} {
    return "<$nid>"
}

proc make-node {text type {start_pos {}} {end_pos {}}} {
    global node crntMsgId msgid2nid nid2msgid visible_nodes
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

proc move-node {a_path x y} {
    global node seg_mrk_x seg_mrk_y

    if {$seg_mrk_x == {} || $seg_mrk_y == {}} {return}
    set old_idx "@$seg_mrk_x,$seg_mrk_y wordstart"
    set new_idx "@$x,$y"
    if [string is space [$a_path get $new_idx]] {
	while {[$a_path compare 1.0 < $new_idx] && \
		   [string is space [$a_path get $new_idx]]} {
	    set new_idx "$new_idx -1 chars"
	}
    } else {
	set new_idx "$new_idx wordend"
    }

    # obtain id of the node at initial coordinates
    lassign [get-node-number $a_path $seg_mrk_x $seg_mrk_y] inid istart iend
    # if no node id could be obtained or the node did not move, return
    if {$istart == {} || [$a_path compare "$old_idx" == "$new_idx"] || \
	    ([$a_path compare "$new_idx" >= "$istart"] && \
		 [$a_path compare "$new_idx" <= "$iend"])} {return}
    set segmarker [$a_path get $istart $iend];    # obtain text of segment marker

    # obtain coordinates and id's of the next and previous nodes
    set nxt_start [lindex [$a_path tag nextrange bmarker $iend] 0]
    lassign [get-node-number $a_path {} {} $nxt_start] nxt_nid nxt_start nxt_end

    set prv_start [lindex [$a_path tag prevrange bmarker $istart] 0]
    lassign [get-node-number $a_path {} {} $prv_start] prv_nid prv_start prv_end

    # determine where the next location of the cursor is and find
    # adjacent node
    set delta_txt ""
    if [$a_path compare "$new_idx" < "$old_idx"] {
    	# if the node has shrinked, set the minimum possible index of
    	# the new shrinked node to the end of the first word in the
    	# original span
    	if {$prv_nid != {} && [$a_path compare "$new_idx" <= "$prv_end"]} {
    	    set new_idx "$prv_end +1 chars wordend"
    	}

    	set delta_txt [$a_path get "$new_idx" "$old_idx -1 chars"]
	set delta [string length "$delta_txt"]
    	# append delta text to adjacent node, if one exists, or simply
    	# remove `old` tags otherwise
    	set node($inid,text) [string range $node($inid,text) 0 \
				  [expr [string length "$node($inid,text)"] - \
				       $delta - 1]]
    	set node($inid,offsets) [subtract-points $node($inid,offsets) [list 0 $delta]]
    	if {$nxt_nid == {}} {
    	    $a_path tag remove old "$new_idx" "$old_idx"
    	    $a_path tag add new "$new_idx" "$old_idx"
    	} else {
    	    set node($nxt_nid,text) "$delta_txt$node($nxt_nid,text)"
	    set node($nxt_nid,offsets) [subtract-points $node($nxt_nid,offsets) [list $delta 0]]
    	}
	$a_path delete $istart $iend;		  # delete segment marker
	$a_path insert "$new_idx" "$segmarker" bmarker; # insert segment marker at new position
    } else {
    	# if node has shrinked, set the minimum possible index of the
    	# new shrinked node to the end of the first word in the
    	# original span
    	if {$nxt_nid != {} && [$a_path compare "$new_idx" >= "$nxt_start"]} {
	    set new_idx $nxt_start
    	    while {[$a_path compare 1.0 < $new_idx] && ! [string is space [$a_path get $new_idx]]} {
		set new_idx "$new_idx -1 chars"
	    }
		   set new_idx "$new_idx wordend"
	}
	set delta_txt [$a_path get "$iend" "$new_idx"]
	set delta [string length "$delta_txt"]
	# append delta text to adjacent node, if one exists, or simply
	# remove `old` tags otherwise
	set node($inid,text) "$node($inid,text)$delta_txt"
	set node($inid,offsets) [add-points $node($inid,offsets) [list 0 $delta]]
	if {$nxt_nid == {}} {
	    $a_path tag remove new "$old_idx" "$new_idx"
	    $a_path tag add old "$old_idx" "$new_idx"
	} else {
	    set node($nxt_nid,text) [string range $node($nxt_nid,text) $delta end]
	    set node($nxt_nid,offsets) [add-points $node($nxt_nid,offsets) [list $delta 0]]
	}
	$a_path insert "$new_idx" "$segmarker" bmarker; # insert segment marker at new position
	$a_path delete $istart $iend;		  # delete segment marker
    }
    redisplay-net
}

proc delete-node {a_path x y} {
    global crntMsgId msgid2nid
    global node last_text_node_id text_nodes offsetShift

    # obtain number of node located at coordinates (x, y)
    lassign [get-node-number $a_path $x $y] inid istart iend
    # puts stderr "delete-node: inid = $inid"
    if {$istart == {}} {
	return
    } elseif {$inid == $last_text_node_id} {
	set text_nodes [ldelete $text_nodes $inid]
	incr last_text_node_id -1
    }
    # find next node in text
    set nxtstart [lindex [$a_path tag nextrange bmarker $iend] 0]
    # if next node exists, append text from deleted node to this next node
    if {$nxtstart != {}} {
	set nxtnid [lindex [get-node-number $a_path {} {} $nxtstart] 0]
	set node($nxtnid,text) "$node($inid,text)$node($nxtnid,text)"
	set node($nxtnid,offsets) [lreplace $node($nxtnid,offsets) 0 0 \
				       [lindex $node($inid,offsets) 0]]
    } else {
	# obtain range of previous node, if any exists
	set prevend [lindex [$a_path tag prevrange bmarker "$istart -1 char"] end]
	# remove tag `old` from the text span covered by the node which should
	# be deleted
	if {$prevend == {}} {set prevend 1.0}
	$a_path tag remove old $prevend $istart
	$a_path tag add new $prevend $istart
    }
    # adjust offset shifts of offsets of all successive nodes
    set delta [string length [$a_path get $istart $iend]]
    if {[string length [$a_path get $iend end]] > 0} {
	set offsetShift [expr $offsetShift - $delta]
    }
    # delete node marker
    $a_path delete $istart $iend
    destroy-node $inid
    redisplay-net
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

    if {[info exists node($nid,parent)] && $node($nid,parent) != {}} {
	set node($node($nid,parent),children) \
	    [ldelete $node($node($nid,parent),children) $nid]
    }
    set node($nid,parent) {}

    if [info exists visible_nodes($nid)] {unset visible_nodes($nid)}
    if {[info exists nid2msgid($nid)]} {
	# if we delete a span node that connects two messages, we drop
	# all information about the connection between these two
	# messages
	if {[llength $nid2msgid($nid)] > 1} {
	    if [info exists msgs2extnid([join $nid2msgid($nid) ","])] {
		unset msgs2extnid([join $nid2msgid($nid) ","])
	    }
	} elseif [info exists node($nid,children)] {
	    # it also might happen that some of the children of
	    # deleted node are located in other messages, in that case
	    # we need to update the information in `msgs2extnid` too
	    set imsgid $nid2msgid($nid)
	    set msgid2nid($imsgid) [ldelete $msgid2nid($imsgid) $nid]
	    set chmsgid {}
	    foreach chnid $node($nid,children) {
		set node($chnid,parent) {}
		set chmsgid $nid2msgid($chnid)
		if {$imsgid != $chmsgid} {
		    set mkey "$imsgid,$chmsgid"
		    if [info exists msgs2extnid($mkey)] {
			foreach {mpnid mchnid rel} $msgs2extnid($mkey) {
			    if {$mchnid == $nid} {
				if {$node($mpnid,type) == "span" && \
					[llength $node($mpnid,children)] == 1} {
				    clear-node $mpnid
				}
			    }
			}
			if [info exists msgs2extnid($mkey)] {unset msgs2extnid($mkey)}
		    }
		}
	    }
	}
	unset nid2msgid($nid)
    }
    set node($nid,children) {}
}
