#!/usr/bin/env wish

# Variables and methods for handling nodes.

###########
# Methods #
###########
proc add-this-to-a-node { do_it {my_current {}} {dummy_param {}} } {
    global last_text_node_id newest_node savenum new_node_text node
    global editor_mode

    if {$editor_mode == "normal"} {
	.editor.text delete my_sel.last new.first
	.editor.text insert my_sel.last "<p>"
    }
    if {$my_current == {} } {
	return
	set my_current current
    }
    .editor.text mark set insert $my_current
    if {[.editor.text compare new.first > $my_current]} {return}
    .editor.text tag remove my_sel 1.0 end

    if { $do_it == "really" } {
	.editor.text tag add sel new.first "insert wordend"
	.editor.text tag add my_sel new.first "insert wordend"
    } else {
	.editor.text tag add sel new.first insert
	.editor.text tag add my_sel new.first insert
    }


    set x [.editor.text index sel.last]
    set y [.editor.text index end]
    .editor.text mark set last_sel sel.last
    if { $x == $y } {
	.editor.text mark set last_sel "sel.last - 1 chars"
  	.editor.text tag remove sel last_sel sel.last
  	.editor.text tag remove my_sel last_sel my_sel.last
    }

    set new_node_text [selection get]
    set the_selection $new_node_text
    regsub -all "\n" $new_node_text " " new_node_text
    regsub -all "\t" $new_node_text " " new_node_text
    regsub -all " +" $new_node_text " " new_node_text
    regsub -all "\"" $new_node_text "" new_node_text
    if { "$do_it" == "really" } {
  	incr savenum
	set old_node_text $node($last_text_node_id,text)
	if { "$editor_mode" == "normal" } {
	    set node($last_text_node_id,text) "$old_node_text <p> $new_node_text"
	} else {
	    set node($last_text_node_id,text) "$old_node_text </p> $new_node_text"
	}
  	redisplay-net
    }
    .editor.text tag add old sel.first last_sel
    .editor.text tag remove new sel.first last_sel

    .editor.text mark set insert last_sel
    if { "$editor_mode" == "normal" } {
  	.editor.text insert my_sel.last "</p>"
    } elseif { "$editor_mode" == "parenthetical" } {
  	.editor.text insert my_sel.last "<$last_text_node_id>"
    }
    .editor.text tag remove sel 1.0 end
    if { "$do_it" == "really" } {
	set my_save "add-this-to-a-node really [.editor.text index my_sel.last]"
	regsub -all "\n" $the_selection {\n} the_selection
	regsub -all "\t" $the_selection {\t} the_selection
	append my_save " \{$the_selection\}"
	save-step $my_save
	# save-rst $savenum
    }
    editor-message "saved tmp.$savenum"
    set x [.editor.text index "end - 1 chars"]
    set y [.editor.text index insert]
    if { $x == $y } {
	nextSentence $do_it
    }
    if { "$editor_mode" == "normal" } {
	set editor_mode parenthetical
	bind .editor.text <Control-ButtonRelease-1> {}
	bind .editor.text <ButtonRelease-2> {}
	bind .editor.text <ButtonRelease-1> {add-this-to-a-node really}
    } elseif { "$editor_mode" == "parenthetical" } {
	set editor_mode normal
	bind .editor.text <Control-ButtonRelease-1> {add-this-to-a-node really}
	bind .editor.text <ButtonRelease-2> {add-this-to-a-node really}
	bind .editor.text <ButtonRelease-1> {create-a-node-here really}
    }
    set line_no [.editor.text index old.last]
    .editor.text yview [expr int($line_no)]
    .editor.text tag add notes my_sel.last new.first
}

proc make-boundary-marker {nid} {
    return "<$nid>"
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
    .editor.text insert my_sel.last "$boundary_marker"
    # call nextSentence() if suggested EDU span was completely covered
    if {[.editor.text tag ranges next] == {} || \
	    [.editor.text compare "next.last -1 chars" <= last_sel]} {
	nextSentence $do_it
    }

    set line_no [.editor.text index old.last]
    .editor.text yview [expr int($line_no)]
    .editor.text tag add notes my_sel.last new.first
}
