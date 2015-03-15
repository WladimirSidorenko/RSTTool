# -*- mode: tcl; -*-

##################################################################
package require rsttool::abbreviations
package require rsttool::utils

##################################################################
namespace eval ::rsttool::segmenter {
    variable OFFSET_SHIFT 0;
    variable SEG_MRK_X {};
    variable SEG_MRK_Y {};
}

##################################################################
proc ::rsttool::segmenter::install {} {
    if {![winfo exists .editor]} {
	scrolled-text .editor -height [expr [winfo screenheight .] * 0.4] \
	    -titlevar currentfile \
	    -font -*-Courier-Medium-R-Normal--16-140-*-*-*-*-*-* \
	    -messagebar t
    }

    pack .editor -side bottom  -pady 0.1c -padx 0.1c -anchor sw -expand 1 -fill both
    # .editor.text config -height [expr [winfo screenheight .] * 0.4]
}

proc ::rsttool::segmenter::uninstall {} {
    pack forget .editor
}

proc ::rsttool::segmenter::scrolled-text {name args} {
    namespace import ::rsttool::utils::getarg
    # Returns a scrollable text widget
    # $name.text is the actual text widger
    # $name.title is the title
    #
    # Args: (all optional)
    # -height <integer>
    # -font <font-spec>
    # -titlevar varname : variable containing the name of the frame title
    set bg [getarg -b $args]
    if {$bg == {}} {set bg white}
    set height [getarg -height $args]
    if { $height == {} } {set height 40}

    frame $name -height $height
    grid columnconfigure $name 0 -weight 1
    grid rowconfigure $name 2 -weight 1
    grid rowconfigure $name 3 -weight 1
    # add title bar
    label $name.title -textvariable [getarg -titlevar $args]
    grid $name.title -row 0  -sticky "ew"
    # add buttons for navigating around discussions
    set navibar [frame $name.navibar]
    set btnNext [button $name.btnNextMsg -text "Next Message" -command {
	::rsttool::segmenter::next-message}];
    set btnPrev [button $name.btnPrevMsg -text "Previous Message" -command {
	::rsttool::segmenter::next-message backward}];
    # set btnNextSent [button $name.nextsent -text "Next Sentence" -command {next-sentence really}];
    # grid $btnPrev $btnNext $btnNextSent -in $navibar;
    grid $navibar -sticky "ew" -row 1;
    pack $btnPrev $btnNext -in $navibar -side left -expand true -fill x;

    frame $name.textWindow
    text  $name.text  -bg $bg -relief sunken -yscrollcommand "$name.scroll set"
    scrollbar $name.scroll -command "$name.text yview"
    grid $name.text -in $name.textWindow -column 0 -row 0 -sticky "ew"
    grid $name.scroll -in $name.textWindow -column 1 -row 0 -sticky "ns"
    grid columnconfigure $name.textWindow 0 -weight 1
    grid $name.textWindow -row 3 -column 0 -sticky "ew"

    frame $name.textWindowPrnt
    text  $name.textPrnt  -bg $bg -relief sunken -yscrollcommand "$name.scrollPrnt set"
    scrollbar $name.scrollPrnt -command "$name.textPrnt yview"
    grid $name.textPrnt -in $name.textWindowPrnt -column 0 -row 0 -sticky "ew"
    grid $name.scrollPrnt -in $name.textWindowPrnt -column 1 -row 0 -sticky "ns"
    grid columnconfigure $name.textWindowPrnt 0 -weight 1
    grid $name.textWindowPrnt -row 2 -column 0 -sticky "ew"

    set font [getarg -font $args]
    if {$font != {}} {
	$name.textPrnt configure -font $font;
	$name.text configure -font $font;
    }

    set messagebar [getarg -messagebar $args]
    if {$messagebar == "t"} {
	frame $name.msgbar
	# the value of bg color is a hard code here
	text  $name.msg -bg gray84 -relief flat -height 1.2;
	grid columnconfigure $name.msgbar 0 -weight 1
    	grid $name.msg -in $name.msgbar -row 0 -column 0 -sticky "ew"
    	grid $name.msgbar -column 0 -row 4 -sticky "ew"
    }
}

proc ::rsttool::segmenter::show-sentences {path_name msg_id {show_rest 0}} {
    # display already EDU segements in widget `path_name`
    variable ::rsttool::FORREST;
    variable ::rsttool::MSGID2NID;
    variable ::rsttool::NODES;

    # obtain annotated EDUs for given message
    if {! [info exists FORREST($msg_id)]} {
	return {0 0};
    } elseif {[info exists MSGID2NID($msg_id)]} {
	# puts stderr "show-sentences: MSGID2NID($msg_id) == $MSGID2NID($msg_id)"
	set nids $MSGID2NID($msg_id);
    } elseif {$show_rest} {
	set nids {};
    } else {
	return {0 0};
    }
    # obtain text of the message to be displayed
    set msg $FORREST($msg_id);
    set txt [lindex $msg 0];
    # for each node, obtain its number and span
    set prev_nid -1
    set offsets {}
    set offset_shift 0
    set start 0
    set end 0
    set bmarker ""
    # we assume that node ids are ordered topologically
    foreach nid $nids {
	if {$nid > $prev_nid } {
	    set prev_nid $nid
	} else {
	    error "Error while loading message $msg_id (EDU nodes for this message are\
 not ordered topologically; prev_nid = $prev_nid, nid = $nid)"
	}
	if {$NODES($nid,type) != "text"} {break;}

	# puts stderr "show-sentences: node(nid = $nid,offsets) = $node($nid,offsets)"
	lassign $NODES($nid,offsets) start end
	if {$start == {}} {error "node $nid does not have valid offsets"}
	incr end -1
	# obtain text span between offsets
	set itext [string range $txt $start $end]
	# insert text portion into the widget, mark it as old text, and add an
	# EDU ending marker
	$path_name insert end $itext old
	set bmarker [make-boundary-marker $nid]
	$path_name insert end $bmarker bmarker
	# update counter of artificial characters
	incr offset_shift [string length $bmarker]
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
    return $offset_shift
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

    variable ::rsttool::NODES;
    variable ::rsttool::MSGID2ENID;
    variable ::rsttool::treeditor::VISIBLE_NODES;

    variable ::rsttool::segmenter::OFFSET_SHIFT;

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
    set OFFSET_SHIFT [show-sentences .editor.text $CRNT_MSGID 1]
    # make suggestion for the boundary of the next segment
    next-sentence
    # display any nodes and sentences that already were annotated for
    # current message
    if {$CRNT_MSGID != $prev_prnt_msg_id} {show-nodes $CRNT_MSGID 1}
    ::rsttool::treeditor::layout::redisplay-net
}

proc ::rsttool::segmenter::segment {{my_current {}}} {
    variable ::rsttool::segmenter::OFFSET_SHIFT;
    global last_text_node_id newest_node new_node_text

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

    set the_selection [selection get]
    set new_node_text [::rsttool::utils::strip $the_selection]
    regsub -all "\"" $new_node_text "" new_node_text


    set start_pos [expr [.editor.text count -chars 1.0 sel.first] - $offsetShift]
    set end_pos [expr [.editor.text count -chars 1.0 sel.last] - $offsetShift]
    namespace import ::rsttool::treeditor::tree::node::make-node;
    set newest_node [make-node $new_node_text "text" $start_pos $end_pos]
    ::rsttool::treeditor::layout::redisplay-net;

    .editor.text mark set insert last_sel
    .editor.text tag add old my_sel.first last_sel
    .editor.text tag remove sel sel.first last_sel
    if {[.editor.text tag ranges next] != {}} {
	.editor.text tag remove next next.first last_sel
    }
    .editor.text tag remove new new.first last_sel

    set boundary_marker [make-bmarker $last_text_node_id]
    set offsetShift [expr $offsetShift + [string length $boundary_marker]]
    .editor.text insert my_sel.last "$boundary_marker" bmarker
    # call next-sentence() if suggested EDU span was completely covered
    if {[.editor.text tag ranges next] == {} || \
	    [.editor.text compare "next.last -1 chars" <= last_sel]} {
	next-sentence
    }

    set line_no [.editor.text index old.last]
    .editor.text yview [expr int($line_no)]
    .editor.text tag add notes my_sel.last new.first
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
