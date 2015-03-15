#!/usr/bin/env wish

# Variables and methods for handling nodes.

###########
# Methods #
###########

# return true, if prnt_nid is among ancestors of the `chld_nid`
proc is-ancestor {chld_nid prnt_nid} {
    global node

    set pnid $node($chld_nid,parent)
    if {$pnid == {}} {
	return 0;
    } elseif {$pnid == $prnt_nid} {
	return 1;
    } else {
	return [is-ancestor $pnid $prnt_nid]
    }
}

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

proc make-boundary-marker {nid} {
    return "<$nid>"
}


proc move-node {a_path x y} {
    global node seg_mrk_x seg_mrk_y

    # puts stderr "move-node: x = $x, y = $y"

    if {$seg_mrk_x == {} || $seg_mrk_y == {}} {return}
    set old_idx "@$seg_mrk_x,$seg_mrk_y wordstart"
    set new_idx "@$x,$y"

    # puts stderr "move-node: old_idx = $old_idx ('[$a_path get $old_idx]')"
    # puts stderr "move-node: new_idx = $new_idx is space ('[$a_path get $new_idx]')"
    # puts stderr "move-node: new_idx is space? [string is space [$a_path get $new_idx]])"
    # puts stderr "move-node: new_idx is end -1? [$a_path compare $new_idx == {end -1 chars}])"
    if {[string is space [$a_path get $new_idx]] &&  [$a_path compare $new_idx >= "end -1 chars"]} {
	while {[$a_path compare 1.0 < $new_idx] && \
		   [string is space [$a_path get $new_idx]]} {
	    set new_idx "$new_idx -1 chars"
	}
	set new_idx "$new_idx +1 chars"
    } else {
	set new_idx "$new_idx wordend"
    }
    # puts stderr "move-node: new_idx after space correction = $new_idx ('[$a_path get $new_idx]')"

    # obtain id of the node at initial coordinates
    lassign [get-node-number $a_path $seg_mrk_x $seg_mrk_y] inid istart iend
    # if no node id could not be obtained or the node did not move,
    # then return
    if {$istart == {} || [$a_path compare "$old_idx" == "$new_idx"] || \
	    ([$a_path compare "$new_idx" >= "$istart"] && \
		 [$a_path compare "$new_idx" < "$iend"])} {return}
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

	if [$a_path compare $new_idx > "end -1 chars"] {
	    set new_idx "end -1 chars"
	}

    	set delta_txt [$a_path get "$new_idx" "$old_idx -1 chars"]
	set delta [string length "$delta_txt"]
	# puts stderr "move-node: 1.0) istart = $istart;, delta_txt = '$delta_txt'; delta = $delta"
    	# append delta text to adjacent node, if one exists, or simply
    	# remove `old` tags otherwise
	# puts stderr "move-node: 1.1) node($inid,text) before = $node($inid,text)"
	# puts stderr "move-node: 1.1) node($inid,text) before = $node($inid,offsets)"
    	set node($inid,text) [string range $node($inid,text) 0 \
				  [expr [string length "$node($inid,text)"] - \
				       $delta - 1]]
    	set node($inid,offsets) [subtract-points $node($inid,offsets) [list 0 $delta]]
	# puts stderr "move-node: 1.2) node($inid,text) after = $node($inid,text)"
	# puts stderr "move-node: 1.2) node($inid,text) after = $node($inid,offsets)"
	# puts stderr "move-node: 1.2) node(inid = $inid,offsets) = $node($inid,offsets)"
    	if {$nxt_nid == {}} {
	    $a_path tag remove my_sel "$new_idx" "end"
	    $a_path tag remove sel "$new_idx" "end"
    	    $a_path tag remove old "$new_idx" "$istart"
    	    $a_path tag add new "$new_idx" "$istart +1 chars"
	    $a_path delete $istart $iend;		  # delete segment marker
	    $a_path insert "$new_idx" "$segmarker" bmarker; # insert segment marker at new position
	    next-sentence
    	} else {
	    if {[.editor.text tag ranges my_sel] != {} && [$a_path compare my_sel.first <= $iend]} {
		$a_path tag add my_sel "$new_idx" "$iend"
	    }
    	    set node($nxt_nid,text) "$delta_txt$node($nxt_nid,text)"
	    set node($nxt_nid,offsets) [subtract-points $node($nxt_nid,offsets) [list $delta 0]]
	    $a_path delete $istart $iend;		  # delete segment marker
	    $a_path insert "$new_idx" "$segmarker" bmarker; # insert segment marker at new position
    	}
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
	# puts stderr "move-node: 2.0) delta_txt = '$delta_txt'; delta = $delta"
	# puts stderr "move-node: 2.1) node($inid,text) before = $node($inid,text)"
	# puts stderr "move-node: 2.1) node($inid,text) before = $node($inid,offsets)"
	set node($inid,text) "$node($inid,text)$delta_txt"
	# puts stderr "move-node: 2.1) node(inid = $inid,offsets) = $node($inid,offsets)"
	set node($inid,offsets) [add-points $node($inid,offsets) [list 0 $delta]]
	# puts stderr "move-node: 2.2) node($inid,text) after = $node($inid,text)"
	# puts stderr "move-node: 2.2) node($inid,text) after = $node($inid,offsets)"
	# puts stderr "move-node: 2.2) node(inid = $inid,offsets) = $node($inid,offsets)"
	if {$nxt_nid == {}} {
	    # puts stderr "move-node: 2.1) tag ranges old [$a_path tag ranges old]"
	    # puts stderr "move-node: 2.1) tag ranges new [$a_path tag ranges new]"
	    $a_path tag add my_sel "$iend" "$new_idx"
	    $a_path tag add old "$iend" "$new_idx"
	    $a_path tag remove sel "$new_idx" "end"
	    $a_path tag remove new "$iend" "$new_idx"
	    $a_path tag remove next "$iend" "$new_idx"
	    $a_path tag remove bmarker "$iend" "end"
	} else {
	    $a_path tag remove my_sel "$iend" "$new_idx"
	    set node($nxt_nid,text) [string range $node($nxt_nid,text) $delta end]
	    # puts stderr "move-node: 2.3) node(nxt_nid = $nxt_nid,offsets) = $node($nxt_nid,offsets)"
	    set node($nxt_nid,offsets) [add-points $node($nxt_nid,offsets) [list $delta 0]]
	    # puts stderr "move-node: 2.4) node(nxt_nid = $nxt_nid,offsets) = $node($nxt_nid,offsets)"
	}
	# do not change the order of deletions and insertions below
	$a_path insert "$new_idx" "$segmarker" bmarker; # insert segment marker at new position
	$a_path delete $istart $iend; # delete segment marker
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
    if {$nxtstart == {}} {
	# obtain range of previous node, if any exists
	set prevend [lindex [$a_path tag prevrange bmarker "$istart -1 char"] end]
	# remove tag `old` from the text span covered by the node which should
	# be deleted
	if {$prevend == {}} {set prevend 1.0}
	$a_path tag remove my_sel $prevend $istart
	$a_path tag remove old $prevend $istart
	$a_path tag remove next $prevend end
	$a_path tag add new $prevend $istart
	next-sentence
    } else {
	# if next node exists, append text from deleted node to this next node
	set nxtnid [lindex [get-node-number $a_path {} {} $nxtstart] 0]
	set node($nxtnid,text) "$node($inid,text)$node($nxtnid,text)"
	set node($nxtnid,offsets) [lreplace $node($nxtnid,offsets) 0 0 \
				       [lindex $node($inid,offsets) 0]]
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
