# -*- mode: tcl; -*-

##################################################################
package require rsttool::abbreviations
package require rsttool::utils

##################################################################
namespace eval ::rsttool::segmenter {
    variable OFFSET_SHIFT 0;
    variable TXTW {};
    variable PRNT_TXTW {};
    variable SEG_MRK_X {};
    variable SEG_MRK_Y {};
}

##################################################################
proc ::rsttool::segmenter::install {} {
    variable TXTW;
    variable PRNT_TXTW;

    set w_name .editor;
    if [winfo exists $w_name] {return;}

    set bg white;
    set font {-*-Courier-Medium-R-Normal--16-140-*-*-*-*-*-*};

    # establish text window for the message
    frame $w_name;
    grid columnconfigure $w_name 0 -weight 1
    # grid rowconfigure $w_name 1 -weight 2
    grid rowconfigure $w_name 2 -weight 1
    grid rowconfigure $w_name 3 -weight 1
    # grid rowconfigure $w_name 4 -weight 1
    # establish title bar
    label $w_name.title -textvariable ::rsttool::CRNT_PRJ_FILE;
    grid $w_name.title -row 0  -sticky "ew"
    # add buttons for navigating around discussions
    set navibar [frame $w_name.navibar]
    set btnNext [button $w_name.btnNextMsg -text "Next Message" -command {
	::rsttool::segmenter::next-message}];
    set btnPrev [button $w_name.btnPrevMsg -text "Previous Message" -command {
	::rsttool::segmenter::next-message backward}];
    pack $btnPrev $btnNext -in $navibar -side left -expand true -fill x;
    grid config $navibar -in $w_name -sticky "ew" -row 1;
    # actually draw the window for the text of the parent message
    frame $w_name.textWindowPrnt;
    set PRNT_TXTW $w_name.textPrnt
    text  $PRNT_TXTW -relief sunken -yscrollcommand "$w_name.scrollPrnt set";
    grid $PRNT_TXTW -in $w_name.textWindowPrnt -column 0 -row 0 -sticky "ew";
    scrollbar $w_name.scrollPrnt -command "$w_name.textPrnt yview";
    grid $w_name.scrollPrnt -in $w_name.textWindowPrnt -column 1 -row 0 -sticky "ns";
    grid columnconfigure $w_name.textWindowPrnt 0 -weight 2;
    grid config $w_name.textWindowPrnt -in $w_name -column 0 -row 2 -sticky "ewns";
    # actually draw the window for the text of the message
    frame $w_name.textWindow;
    set TXTW $w_name.text
    text  $TXTW -relief sunken -yscrollcommand "$w_name.scrollPrnt set"
    grid $TXTW -in $w_name.textWindow -column 0 -row 0 -sticky "ew"
    scrollbar $w_name.scroll -command "$w_name.textPrnt yview"
    grid $w_name.scroll -in $w_name.textWindow -column 1 -row 0 -sticky "ns"
    grid columnconfigure $w_name.textWindow 0 -weight 2;
    grid config $w_name.textWindow -column 0 -row 3 -sticky "ewns";
    # draw message bar
    frame $w_name.msgbar
    text  $w_name.msg -bg gray84 -relief flat -height 1.2;
    grid $w_name.msg -in $w_name.msgbar -row 0 -column 0 -sticky "ew"
    grid columnconfigure $w_name.msgbar 0 -weight 1
    grid config $w_name.msgbar -column 0 -row 4 -sticky "ew"
    pack $w_name -side bottom -pady 0.1c -padx 0.1c -anchor sw -expand 1 -fill both;
}

proc ::rsttool::segmenter::uninstall {} {
    pack forget .editor
}

proc ::rsttool::segmenter::show-sentences {path_name msg_id {show_rest 0}} {
    # display already EDU segements in widget `path_name`
    variable ::rsttool::FORREST;
    variable ::rsttool::MSGID2TNODES;
    variable ::rsttool::NODES;
    variable ::rsttool::MSG_TXT_NODE_CNT;
    variable OFFSET_SHIFT;

    # obtain annotated EDUs for given message
    if {! [info exists FORREST($msg_id)]} {
	return {0 0};
    } elseif {[info exists MSGID2TNODES($msg_id)]} {
	set nids $MSGID2TNODES($msg_id);
    } elseif {$show_rest} {
	set nids {};
    } else {
	return {0 0};
    }
    puts stderr "show-sentences: nids == $nids"
    # obtain text of the message to be displayed
    set msg $FORREST($msg_id);
    set txt [lindex $msg 0];
    # for each node, obtain its number and span
    set prev_nid -1
    set offsets {}
    set OFFSET_SHIFT 0
    set start 0
    set end 0
    set bmarker ""
    # we assume that node ids are ordered topologically
    foreach nid $nids {
	if {$nid > $prev_nid } {
	    set prev_nid $nid
	} else {
	    error "Error while loading message $msg_id\n(EDU nodes for this message are\
 not ordered topologically; prev_nid = $prev_nid, nid = $nid)"
	}
	if {! [::rsttool::treeditor::tree::node::text-node-p $nid]} {continue;}

	set start $NODES($nid,start)
	set end $NODES($nid,end)
	# puts stderr "show-sentences: node(nid = $nid,offsets) = $node($nid,offsets)"
	if {$start == {} || $end == {}} {error "node $nid does not have valid offsets"}
	incr end -1
	# obtain text span between offsets
	set itext [string range $txt $start $end]
	# insert text portion into the widget, mark it as old text, and add an
	# EDU ending marker
	$path_name insert end $itext old
	set bmarker [make-bmarker $NODES($nid,name)]
	$path_name insert end $bmarker bmarker
	# update counter of artificial characters
	incr OFFSET_SHIFT [string length $bmarker]
	incr MSG_TXT_NODE_CNT;
    }
    # put `old` tag for the case when no previos segments were
    # annotated

    # insert the rest of the text, if asked to do so
    if $end {incr end}
    if {$show_rest} {
	# insert the leftover text
	$path_name insert end [string range $txt $end end] new
	# add tag `new` to the newly inserted text
    	set end end
    }
    # return position of the last annotated character and the number
    # of inserted artificial characters
    return $OFFSET_SHIFT
}

proc ::rsttool::segmenter::next-sentence {{trgframe .editor.text}} {
    variable ::rsttool::abbreviations::ABBREVIATIONS

    set flag 2
    set periods {}
    # obtain range covered by the `next` tag
    set start [$trgframe index new.first]
    set end [$trgframe index new.last]
    # return, if tag was not found
    if {$start == {}} {return}
    # obtain text covered by the `new` tag
    set text [$trgframe get $start $end]
    while { $flag } {
	#search for the next end of sentence punctuation
	set nextCutoff [string first .  $text]
	set exclamation [string first ! $text]
	set question [string first ? $text]
	if {$nextCutoff == -1} {
	    set nextCutoff [expr [string length "$text"] -1]
	}
	if {$exclamation != -1 && $exclamation < $nextCutoff} {
	    set nextCutoff $exclamation
	}
	if {$question != -1 && $question < $nextCutoff} {
	    set nextCutoff $question
	}
	set last [expr [llength periods] -1]
	if {$flag == 1 && $nextCutoff == "[lindex $periods $last]"} {
	    set flag 0
	}
	set wordStart $nextCutoff
	while {$wordStart >= 0} {
	    incr wordStart -1
	    set character [string index $text $wordStart]
	    if [string is space -strict $character] {
		incr wordStart
		break
	    }
	}
	set test [string range $text $wordStart $nextCutoff]
	if {[info exists ABBREVIATIONS($test)]} {
	    set flag 1
	    incr nextCutoff
	    set text [string range $text $nextCutoff end]
	    lappend periods $nextCutoff
	} else {
	    set flag 0
	}
    }
    foreach period $periods {
	set nextCutoff [expr $nextCutoff + $period]
    }
    set max_len [string length $text]
    while {$nextCutoff < $max_len} {
	set quotetest [expr $nextCutoff + 1]
	set ichar [string index $text $quotetest]
	if {[string is punct -strict $ichar] || \
		[string is space -strict $ichar]} {
	    incr nextCutoff
	} else {
	    break
	}
    }
    incr nextCutoff
    # remove `next` tag from the area of presumable new segment
    # $trgframe tag remove new new.first "new.first + $nextCutoff chars"
    if {[$trgframe compare new.first < "end -1 chars"]} {
	$trgframe tag add next new.first "new.first + $nextCutoff chars"
    }
}

proc ::rsttool::segmenter::next-message {{direction {forward}}} {
    variable ::rsttool::THREADS;
    variable ::rsttool::THREAD_ID;
    variable ::rsttool::FORREST;

    variable ::rsttool::CRNT_MSGID;
    variable ::rsttool::PRNT_MSGID;
    variable ::rsttool::PRNT_MSGTXT;
    variable ::rsttool::MSG_QUEUE;
    variable ::rsttool::MSG_PREV_QUEUE;
    variable ::rsttool::MSG_TXT_NODE_CNT;
    variable ::rsttool::MSG_GRP_NODE_CNT;

    variable ::rsttool::NODES;
    variable ::rsttool::MSGID2ENID;
    variable ::rsttool::treeditor::VISIBLE_NODES;

    variable OFFSET_SHIFT;

    namespace import ::rsttool::treeditor::tree::node::show-nodes;
    # puts stderr "next-mesage called"

    # remember current message id
    set prev_msg_id $CRNT_MSGID
    # remember the old parent
    set prev_prnt_msg_id $PRNT_MSGID;
    # check direction to which we should proceed
    if {$direction == {forward}} {
	# if we have exhausted the queue of messages for current
	# discussion, we proceed to the next discussion in forrest
	if {[llength $MSG_QUEUE] == 0} {
	    incr THREAD_ID;
	    # if no more discussions are present in Queue, return
	    if {$THREAD_ID >= [llength $THREADS]} {
		incr THREAD_ID -1;
		tk_messageBox -message "Reached the end of the document."
		return;
	    }
	    lappend MSG_QUEUE [lindex $THREADS $THREAD_ID]
	}

	# remember current message in `MSG_PREV_QUEUE`
	if {$CRNT_MSGID != {}} {lappend MSG_PREV_QUEUE $CRNT_MSGID;}
	# assign the id of the leftmost tweet in the Queue to `CRNT_MSGID`
	# and unshift the Queue
	set CRNT_MSGID [lindex $MSG_QUEUE 0]
	set crnt_msg $FORREST($CRNT_MSGID)

	set MSG_QUEUE [lreplace $MSG_QUEUE 0 0]; # pop message id from the queue
	set children [lindex $crnt_msg end]; # obtain children of current message
	set MSG_QUEUE [concat $MSG_QUEUE $children]; # append children to message queue
    } else {
	# if we have exhausted the queue of processed messages, we
	# give a warning
	if {[llength $MSG_PREV_QUEUE] == 0} {
	    tk_messageBox -message "Reached the beginning of the document.";
	    return;
	}

	if {$CRNT_MSGID != {}} {
	    # remember popped message in `MSG_QUEUE`
	    set MSG_QUEUE [linsert $MSG_QUEUE[set MSG_QUEUE {}] 0 $CRNT_MSGID];
	}
	# assign the leftmost tweet on the queue to crnt_msg and unshift the Queue
	set CRNT_MSGID [lindex $MSG_PREV_QUEUE end]
	set crnt_msg $FORREST($CRNT_MSGID)
	set MSG_PREV_QUEUE [lreplace $MSG_PREV_QUEUE end end]; # pop message id from the queue
    }
    set PRNT_MSGID [lindex $crnt_msg 1];	# obtain id of the parent of current message

    ############################################
    ## Show/Hide nodes corresponding to messages

    # hide group node connecting previous message with its parent
    # puts stderr "checking external node msgs2extnid($prev_prnt_msg_id,$prev_msg_id)"
    if [info exists MSGID2ENID($prev_prnt_msg_id,$prev_msg_id)] {
	set extnid [lindex $MSGID2ENID($prev_prnt_msg_id,$prev_msg_id) 0]
	unset VISIBLE_NODES($extnid)
	# unlink children from the abstract group node
	# foreach cid $node($extnid,children) {
	#     set node($cid,parent) {}
	# }
    }
    # show group node connecting current message with its parent
    # puts stderr "checking external node msgs2extnid($PRNT_MSGID,$CRNT_MSGID)"
    if [info exists MSGID2ENID($PRNT_MSGID,$CRNT_MSGID)] {
	# puts stderr "showing nodes $msgs2extnid($PRNT_MSGID,$CRNT_MSGID)"
	set extnid [lindex $MSGID2ENID($PRNT_MSGID,$CRNT_MSGID) 0]
	# puts stderr "extnid = $extnid"
	set VISIBLE_NODES($extnid) 1
	# restore children of this abstract group node
	foreach {prntid cid relname} $MSGID2ENID($PRNT_MSGID,$CRNT_MSGID) {
	    set NODES($cid,parent) $prntid
	    set NODES($cid,relname) $relname
	}
    }
    # if parent has changed, hide the old and show the new one
    if {$PRNT_MSGID != $prev_prnt_msg_id} {
	# display all known RST nodes for the new parent hide previous current
	# node, if it is not the parent of the next message
	if {$PRNT_MSGID != $prev_msg_id} {show-nodes $PRNT_MSGID 1}
	# hide all RST nodes in RST window which correspond to the
	# previous parent
	if {$CRNT_MSGID != $prev_prnt_msg_id} {show-nodes $prev_prnt_msg_id 0}
	# obtain text of the new parent
	if {$PRNT_MSGID == {}} {
	    set PRNT_MSGTXT "";
	} else {
	    set PRNT_MSGTXT [lindex $FORREST($PRNT_MSGID) 0];
	}
	# reload the text
	.editor.textPrnt delete 0.0 end
	show-sentences .editor.textPrnt $PRNT_MSGID 1
    }
    if {$PRNT_MSGID != $prev_msg_id} {
	# puts stderr "hiding nodes for message $prev_msg_id"
	show-nodes $prev_msg_id 0
    }
    # clear current message text area and place new text into it
    .editor.text delete 1.0 end
    .editor.text tag add new 1.0 end
    # show already annotated segments for current message and make the
    # rest of the text appear in grayscale
    set MSG_TXT_NODE_CNT -1;
    set MSG_GRP_NODE_CNT -1;
    set OFFSET_SHIFT [show-sentences .editor.text $CRNT_MSGID 1]
    # make suggestion for the boundary of the next segment
    next-sentence
    # display any nodes and sentences that already were annotated for
    # current message
    if {$CRNT_MSGID != $prev_prnt_msg_id} {show-nodes $CRNT_MSGID 1}
    ::rsttool::treeditor::layout::redisplay-net
}

proc ::rsttool::segmenter::segment {{my_current {}}} {
    variable ::rsttool::NODES;
    variable ::rsttool::CRNT_MSGID;
    variable ::rsttool::segmenter::OFFSET_SHIFT;

    # if no index was specified, set the index position to the
    # position of the cursor and move it to the left, if currently
    # pointed character is a space
    if {$my_current == {}} {
	set my_current current
	while {[.editor.text compare $my_current > 1.0] && \
		   [.editor.text compare $my_current > new.first]} {
	    if {[string is space [.editor.text get "$my_current"]]} {
		set my_current "$my_current -1 chars"
	    } else {
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
    .editor.text tag add sel new.first "insert wordend"
    .editor.text tag add my_sel new.first "insert wordend"

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

    set start_pos [expr [.editor.text count -chars 1.0 sel.first] - $OFFSET_SHIFT]
    set end_pos [expr [.editor.text count -chars 1.0 sel.last] - $OFFSET_SHIFT]

    set inid [::rsttool::treeditor::tree::node::make {text} $start_pos $end_pos {} $CRNT_MSGID];
    ::rsttool::treeditor::layout::redisplay-net;

    .editor.text mark set insert last_sel
    .editor.text tag add old my_sel.first last_sel
    .editor.text tag remove sel sel.first last_sel
    if {[.editor.text tag ranges next] != {}} {
	.editor.text tag remove next next.first last_sel
    }
    .editor.text tag remove new new.first last_sel

    set boundary_marker [make-bmarker $NODES($inid,name)];
    set OFFSET_SHIFT [expr $OFFSET_SHIFT + [string length $boundary_marker]]
    .editor.text insert my_sel.last "$boundary_marker" bmarker
    # call next-sentence() if suggested EDU span was completely covered
    if {[.editor.text tag ranges next] == {} || \
	    [.editor.text compare "next.last -1 chars" <= last_sel]} {
	next-sentence
    }

    set line_no [.editor.text index old.last]
    .editor.text yview [expr int($line_no)]
    .editor.text tag add notes my_sel.last new.first

    ::rsttool::set-state {changed} "Created segment $NODES($inid,name)";
}

proc ::rsttool::segmenter::delete {a_path x y} {
    variable OFFSET_SHIFT;
    variable ::rsttool::NODES;
    variable ::rsttool::CRNT_MSGID;
    variable ::rsttool::TXT_NODE_CNT;

    # obtain number of node located at coordinates (x, y)
    lassign [get-seg-nid $a_path $x $y {} $CRNT_MSGID] inid istart iend;

    # puts stderr "delete-node: inid = $inid"
    if {$istart == {}} {
	return
    } elseif {$inid == $TXT_NODE_CNT} {
	set text_nodes [ldelete $text_nodes $inid];
	incr TXT_NODE_CNT -1;
    }
    # find next node in text
    set nxtstart [lindex [$a_path tag nextrange bmarker $iend] 0]
    if {$nxtstart == {}} {
	# obtain range of previous node, if any exists
	set prevend [lindex [$a_path tag prevrange bmarker "$istart -1 char"] end];
	# remove tag `old` from the text span covered by the node which should
	# be deleted
	if {$prevend == {}} {set prevend 1.0}
	$a_path tag remove my_sel $prevend $istart;
	$a_path tag remove old $prevend $istart;
	$a_path tag remove next $prevend end;
	$a_path tag add new $prevend $istart;
	next-sentence;
    } else {
	# if next node exists, append text from deleted node to this next node
	set nxtnid [lindex [get-seg-nid $a_path {} {} $nxtstart] 0];
	set NODES($nxtnid,text) "$NODES($inid,text)$NODES($nxtnid,text)";
	set NODES($nxtnid,start) $NODES($inid,start);
    }
    # adjust offset shifts of offsets of all successive nodes
    set delta [string length [$a_path get $istart $iend]];
    if {[string length [$a_path get $iend end]] > 0} {
	set OFFSET_SHIFT [expr $OFFSET_SHIFT - $delta];
    }
    # delete node marker
    set iname $NODES($inid,name);
    $a_path delete $istart $iend;
    ::rsttool::treeditor::tree::node::destroy $inid;
    if {$nxtstart != {}} {
	rename-segments $nxtnid $CRNT_MSGID [expr $iname - $NODES($nxtnid,name)];
	$a_path delete 0.0 end;
	show-sentences $a_path $CRNT_MSGID 1;
    }
    ::rsttool::treeditor::layout::redisplay-net;
    ::rsttool::set-state {changed} "Deleted segment $iname";
}

proc ::rsttool::segmenter::move {a_path x y} {
    variable SEG_MRK_X;
    variable SEG_MRK_Y;
    variable ::rsttool::NODES;
    variable ::rsttool::CRNT_MSGID;
    namespace import ::rsttool::treeditor::tree::node::set-text;

    parray ::rsttool::treeditor::VISIBLE_NODES;

    if {$SEG_MRK_X == {} || $SEG_MRK_Y == {}} {return}
    set old_idx "@$SEG_MRK_X,$SEG_MRK_Y wordstart"
    set new_idx "@$x,$y"

    if {[string is space [$a_path get $new_idx]] &&  [$a_path compare $new_idx <= "end -1 chars"]} {
	while {[$a_path compare 1.0 < $new_idx] && \
		   [string is space [$a_path get $new_idx]]} {
	    set new_idx "$new_idx -1 chars"
	}
	set new_idx "$new_idx +1 chars"
    } else {
	set new_idx "$new_idx wordend"
    }

    # obtain id of the node at initial coordinates
    lassign [get-seg-nid $a_path $SEG_MRK_X $SEG_MRK_Y {} $CRNT_MSGID] inid istart iend
    # if no node id could not be obtained or the node did not move,
    # then return
    if {$istart == {} || [$a_path compare "$old_idx" == "$new_idx"] || \
	    ([$a_path compare "$new_idx" >= "$istart"] && \
		 [$a_path compare "$new_idx" < "$iend"])} {return}
    set segmarker [$a_path get $istart $iend];    # obtain text of segment marker

    # obtain coordinates and id's of the next and previous nodes
    set nxt_start [lindex [$a_path tag nextrange bmarker $iend] 0]
    lassign [get-seg-nid $a_path {} {} $nxt_start $CRNT_MSGID] nxt_nid nxt_start nxt_end

    set prv_start [lindex [$a_path tag prevrange bmarker $istart] 0]
    lassign [get-seg-nid $a_path {} {} $prv_start $CRNT_MSGID] prv_nid prv_start prv_end

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

    	set delta_txt [$a_path get "$new_idx +1 chars" "$old_idx"]
	set delta [string length "$delta_txt"]
    	set NODES($inid,end) [expr $NODES($inid,end) - $delta]
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
	    set NODES($nxt_nid,start) [expr $NODES($nxt_nid,start) - $delta]
	    set-text $nxt_nid;
	    $a_path delete $istart $iend;		  # delete segment marker
	    $a_path insert "$new_idx" "$segmarker" bmarker; # insert segment marker at new position
    	}
    } else {
    	# if the node has shrunk, set the minimum possible index of
    	# the new shrunk node to the end of the first word in the
    	# original span
    	if {$nxt_nid != {} && [$a_path compare "$new_idx" >= "$nxt_start"]} {
	    set new_idx "$nxt_start -1 chars wordstart -1 chars"
    	    while {[$a_path compare 1.0 < $new_idx] && [string is space [$a_path get $new_idx]]} {
		set new_idx "$new_idx -1 chars"
	    }
	    set new_idx "$new_idx +1 chars"
	}
	set delta_txt [$a_path get "$iend" "$new_idx"]
	set delta [string length "$delta_txt"]
	# append delta text to adjacent node, if one exists, or simply
	# remove `old` tags otherwise
	set NODES($inid,end) [expr $NODES($inid,end) + $delta]
	if {$nxt_nid == {}} {
	    $a_path tag add my_sel "$iend" "$new_idx"
	    $a_path tag add old "$iend" "$new_idx"
	    $a_path tag remove sel "$new_idx" "end"
	    $a_path tag remove new "$iend" "$new_idx"
	    $a_path tag remove next "$iend" "$new_idx"
	    $a_path tag remove bmarker "$iend" "end"
	} else {
	    $a_path tag remove my_sel "$iend" "$new_idx"
	    set NODES($nxt_nid,start) [expr $NODES($nxt_nid,start) + $delta]
	    set-text $nxt_nid;
	}
	# do not change the order of deletions and insertions below
	$a_path insert "$new_idx" "$segmarker" bmarker; # insert segment marker at new position
	$a_path delete $istart $iend; # delete segment marker
    }
    set-text $inid;
    ::rsttool::treeditor::layout::redisplay-net;
    puts stderr "2) move: VISIBLE_NODES =";
    parray ::rsttool::treeditor::VISIBLE_NODES;
    ::rsttool::set-state {changed} "Moved boundary of segment $NODES($inid,name)";
}

proc ::rsttool::segmenter::rename-segments {a_nid a_msgid a_diff} {
    variable ::rsttool::NODES;
    variable ::rsttool::NAME2NID;
    variable ::rsttool::MSGID2TNODES;
    namespace import ::rsttool::treeditor::tree::node::bisearch;

    set tnodes $MSGID2TNODES($a_msgid);
    set idx [bisearch $a_nid $tnodes];
    if {$idx < 0} {return;}
    set maxidx [llength $tnodes];

    for {} {$idx < $maxidx} {incr idx} {
	set inid [lindex $tnodes $idx];
	set oname $NODES($inid,name);
	array unset NAME2NID $a_msgid,$oname;

	set nname [expr $oname + $a_diff];
	set NAME2NID($a_msgid,$nname) $inid;
	set NODES($inid,name) $nname;
    }
}

proc ::rsttool::segmenter::get-seg-nid {a_path x y {start {}} \
					    {msgid {}}} {
    variable ::rsttool::NAME2NID;
    if {$msgid == {}} {set msgid $::rsttool::CRNT_MSGID;}
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
    return [list $NAME2NID($msgid,$nnumber) $istart $iend]
}

proc ::rsttool::segmenter::make-bmarker {nid} {
    return "<$nid>"
}

proc ::rsttool::segmenter::message {{a_msg {}}} {
    .editor.msg delete 1.0 end
    .editor.msg insert end $a_msg
}

##################################################################
package provide rsttool::segmenter 0.0.1
return
