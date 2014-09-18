#!/usr/bin/env wish

# Variables and methods for handling nodes.

###########
# Methods #
###########
proc make-boundary-marker {nid} {
    return "<$nid>"
}

proc move-node {a_path x y X Y} {
    puts stderr "move-node: x = $x"
    puts stderr "move-node: y = $y"
    puts stderr "move-node: X = $X"
    puts stderr "move-node: Y = $Y"
}

proc delete-node {a_path x y} {
    global last_text_node_id
    # obtain number of node located at coordinates (x, y)
    set nid [get-node-number $a_path $x $y]
    puts stderr "nnumber = $nid"
    if {$nid == -1} {return}
    # in easy case, this node has just been created, so we can delete
    # its mark, the graphical node in rst window and decrement the
    # node counter
    if {$nid == $last_text_node_id} {
	incr last_text_node_id -1
    }
    clear-node $nid
}

proc get-node-number {a_path x y} {
    # obtain number of node located at coordinates (x, y)
    set nnumber [$a_path get -- "@$x,$y wordstart" "@$x,$y wordend"]
    set choffset 1
    set prev_char ""
    puts stderr "delete-node: entering while loop"
    while {$nnumber == ">" || $nnumber == "<"} {
	switch -- $nnumber {
	    "<" {
		if {$prev_char == ">"} {return}
		set prev_char "<"
		set nnumber [$a_path get -- "@$x,$y +$choffset chars wordstart" \
				 "@$x,$y +$choffset chars wordend"]
	    }
	    ">" {
		if {$prev_char == "<"} {return}
		set prev_char ">"
		set nnumber [$a_path get -- "@$x,$y -$choffset chars wordstart" \
				 "@$x,$y -$choffset chars wordend"]
	    }
	    default {
		if [string is digit $nnumber] {
		    break
		} else if {! [string is space $nnumber]} {
		    return
		}
	    }
	}
	incr choffset
    }
    if [string is digit $nnumber] {
	return $nnumber
    } else {
	return -1
    }
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
