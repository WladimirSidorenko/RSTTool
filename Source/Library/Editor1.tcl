# Define Frame for a emacs-style editor
# And Procedures to support it
# This version supports single file at a time only

# TO DO
#5. ctl-x s should work

######################################
# Define the Frame

if {![winfo exists .editor]} {
    scrolled-text .editor -height 30 -titlevar currentfile \
	-font -*-Courier-Medium-R-Normal--16-140-*-*-*-*-*-* \
	-messagebar t
    global undoer
    set undoer [new textUndoer .editor.text]
}

bind all <Meta-z> {
    textUndoer:undo $undoer
}

proc pack-editor {} {
    pack .editor -pady 0.1c -padx 0.4c  -expand 1 -fill both
}

######################################
# Define global vars
set currentfile {}

######################################
# Define Procedures

# PRIMITIVES

# load-file: Procedure to put a file into the editor
# save-file: saves the current file to disk
# save-file-as: puts edit-window into newly named buffer, then saves.
# new-file: makes newly named buffer and installs it.
# revert-buffer: replaces file into window

proc wincopy {from_file to_file} {
    set from [open $from_file r]
    set to [open $to_file w]

    while {![eof $from]} {
	puts $to [read $from 1000]
    }
    close $from
    close $to
}

proc reload-current-file {} {
    global currentfile theText
    set f [open $currentfile]
    .editor.text delete 1.0 end
    set theText ""
    while {![eof $f]} {
	append theText [read $f 1000]
    }
    close $f
    .editor.text insert end "\n"
    .editor.text tag add old 1.0 1.0
    .editor.text tag add new 1.0 end
}

proc read-file {a_istream} {
    global theRoots theForrest theText

    set origlen 0; # length of complete line
    set modlen 0;  # length of modified line
    set modline ""; # auxiliary variable for storing text trimmed of tabs

    set t_id "";		# id of thew tweet
    set t_lvl 0;		# nestedness level of the tweet
    set t_text "";		# tweet's text

    set lvl_diff 0;		# difference between current and
    # previous nestedness levels
    set prev_lvl 0;		# previous nestedness level
    set prev_id "";		# previous tweet id
    set prnt_id "";		# id of parent tweet
    set parents {};		# stack of parents

    set chunk "";		# text chunk read from file
    set remainder "";		# incompletely read line part
    set line "";		# single line
    set lines [];		# array of split lines

    while {![eof $a_istream]} {
	# obtain next 1k symbols from the input stream
	set chunk [read $a_istream 1000]
	append theText $chunk
	# if there is string left from the previous run, append it to `TextPortion`
	if {$remainder != ""} {
	    set chunk "$remainder$chunk"
	    set remainder ""
	}
	# split read text chunk
	set lines [split $chunk "\n"]
	# if read text chunk did not end with a newline, pop the last element
	# from the list and store it in the variable `$remainder`
	if {[string index $chunk end] != "\n"} {
	    set remainder [lindex $lines end]
	    set lines [lreplace $lines end end]
	}
	# iterate over obtained lines
	foreach line $lines {
	    # parse line by obtaining the id of described tweet and
	    # the nestedness level of that tweet in discussion
	    set origlen [string length $line]
	    set line [string trimleft $line "\t"]
	    set modlen [string length $line]
	    if {$modlen == 0} {
		set prnt_id {};
		set prv_lvl 0;
		continue;
	    }
	    set t_lvl [expr $origlen - $modlen];
	    # get id of the tweet
	    set id_end [string wordend $line 0];
	    incr id_end -1;
	    set t_id [string range $line 0 $id_end];
	    if {[string length $t_id] == 0} {error "Tweet id could not be obtained for line '$line'."};
	    incr id_end 2;
	    set t_text [string trimleft [string range $line $id_end end]];
	    # if {[string length $t_text] == 0} {error "Empty text specified at line '$line'."};
	    # check that given tweet id was not seen previously
	    if {[info exists theForrest($t_id)]} {error "Duplicate id: '$t_id'";}
	    # store id of the tweet which starts the discussions in
	    # the list of discussion roots
	    if {$t_lvl == 0} {
		lappend theRoots $t_id;
		set parents {};
		set prnt_id {};
	    } else {
		set lvl_diff [expr $t_lvl - $prev_lvl];
		if  {[expr $lvl_diff < 0]} {
		    # successively pop last elements from the stack of
		    # parents
		    for {set i 0} {$i > $lvl_diff} {incr i -1} {
			set parents [lreplace $parents end end];
		    }
		} elseif {[expr $lvl_diff > 0]} {
		    # if nestedness level is greater than level of the
		    # previous tweet, then this tweet is the reply to the
		    # previous one
		    if {$lvl_diff > 1} {error "Incorrect line format.\
 An answer to non-existing message detected (check the number of initial indentations):\n'$line'";}
		    lappend parents $prev_id;
		};
		# the new topmost element will serve as parent
		set prnt_id [lindex $parents end];
		# append id of current message to the list of children of the parent of that message
		lset theForrest($prnt_id) end [concat [lindex $theForrest($prnt_id) end] [list $t_id]];
	    }
	    # create new entry in `theForrest` for current tweet
	    set theForrest($t_id) [list "$t_text" $prnt_id {}];
	    # remember previous nestedness level
	    set prev_lvl $t_lvl;
	    set prev_id $t_id;
	}
    }
}

proc load-file {filename {really {1}}} {
    global currentfile undoer collapsed_nodes
    global theText theRootIdx msgQueue
    global step_file

    set last_element [llength $collapsed_nodes]
    incr last_element -1
    if { $last_element > -1 } {
	set collapsed_nodes [lreplace $collapsed_nodes 0 $last_element]
    }
    if {$step_file != {}} { close-step-file }
    if {$filename == {}} {return}

    # 2. Load named file
    set theText ""
    set f [open $filename]
    read-file $f
    close $f

    # 3. Stop undo past installation
    textUndoer:reset $undoer

    set currentfile $filename
    if { $really == 1 } {open-step-file}

    editor-message "opened file:  $filename"
    # .editor.text insert end "\n"
    .editor.text tag add old 1.0 1.0
    .editor.text tag add new 1.0 end
    #  save-step "load-file $filename"
    if { $really == 1 } {
	nextMessage really
    } else {
	nextMessage fake
    }
}

proc showNodes {msg_id {show 1} } {
    # set the visibility status for all nodes belonging to the message
    # `$msg_id` to $show
    global msgid2nid node visible_nodes
    puts stderr "Changing visibility for message $msg_id to $show"

    if {[info exists msgid2nid($msg_id)]} {
	if {$show} {
	    foreach nid $msgid2nid($msg_id) {
		puts stderr "Showing node $nid"
		set visible_nodes($nid) 1
	    }
	} else {
	    foreach nid $msgid2nid($msg_id) {
		puts stderr "Hiding node $nid"
		puts stderr "visible_nodes = [array names visible_nodes]"
		if {[info exists visible_nodes($nid)]} {unset visible_nodes($nid)}
		puts stderr "visible_nodes = [array names visible_nodes]"
	    }
	}
    }
}

proc showSentences {path_name msg_id {show_rest 0}} {
    # display already EDU segements in widget `path_name`
    global theForrest msgid2nid node
    # obtain annotated EDUs for given message
    if {! [info exists theForrest($msg_id)]} {
	return {0 0};
    } elseif {[info exists msgid2nid($msg_id)]} {
	set nids $msgid2nid($msg_id);
    } elseif {$show_rest} {
	set nids {};
    } else {
	return {0 0};
    }
    # obtain text of the message to be displayed
    set msg $theForrest($msg_id);
    set txt [lindex $msg 0];
    # for each node, obtain its serial number and span
    set prev_nid -1
    set offsets {}
    set offset_shift 0
    set start 0
    set end 0
    set bmarker ""
    # we assume that node ids are topologically ordered
    foreach nid $nids {
	if {$nid > $prev_nid } {
	    set prev_nid $nid
	} else {
	    error "Error while loading message $msg_id (EDU nodes for this message are\
 not ordered topologically; prev_nid = $prev_nid, nid = $nid)"
	}
	if {$node($nid,type) != "text"} {continue;}

	set offsets $node($nid,offsets)
	if {$offsets == {}} {error "node $nid does not have valid offsets"}
	set start [lindex $offsets 0]
	set end [lindex $offsets end]

	# obtain text span between offsets
	puts stderr "start is $start"
	puts stderr "end is $end"
	puts stderr "txt is $txt"
	set itext [string range $txt $start $end]
	# insert text portion into the widget and add an EDU ending marker
	$path_name insert end $itext
	set bmarker [make-boundary-marker $nid]
	$path_name insert end $bmarker
	# update counter of artificial characters
	set offset_shift [expr $offset_shift + [string length $bmarker]]
    }
    $path_name tag add old 1.0 "[$path_name index end] -1 chars"
    # insert the rest of the text, if asked to do so
    if {$show_rest} {
    	$path_name insert end [string range $txt $end end];
    	set end end
    }
    # return position of the last annotated character and the number
    # of inserted artificial characters
    return [list $end $offset_shift]
}

proc showText { {do_it {}} } {
    global theText usedText currSentence abbreviations
    set old_new_first [.editor.text index new.first]
    set testText $theText
    #search for the next end of sentence punctuation
    set nextCutoff [string length $testText]
    incr nextCutoff -1

    set currSentence [string range $theText 0 $nextCutoff]
    incr nextCutoff
    set textCutoff [string length "$theText"]
    incr textCutoff -1
    set theText [string range $theText $nextCutoff $textCutoff]
    set usedText "$currSentence$usedText"
    .editor.text insert end "$currSentence"
    if { [.editor.text tag ranges old] == {} } {
	.editor.text tag add new 1.0 end
    } else {
	.editor.text tag add new $old_new_first end
    }
    if {"$do_it" == "really"} {save-step "showText really"}
}

proc nextMessage { {do_it {}} {direction {forward}}} {
    global theRoots theRootIdx theForrest theText usedtext
    global crntMsgId crntMsgTxt prntMsgId prntMsgTxt msgid2nid
    global msgQueue msgPrevQueue
    global offsetShift
    puts stderr "nextMessage() called"
    # remember current message id
    set prev_msg_id $crntMsgId
    # remember the old parent
    set prev_prnt_msg_id $prntMsgId;
    # check direction to which we should proceed
    if {$direction == {forward}} {
	# if we have exhausted the queue of messages for current
	# discussion, we proceed to the next discussion in the forrest
	if {[llength $msgQueue] == 0} {
	    incr theRootIdx;
	    # if no more discussions are present on the Queue, return
	    if {$theRootIdx >= [llength $theRoots]} {
		tk_messageBox -message "Reached the end of the document."
		return;
	    }
	    lappend msgQueue [lindex $theRoots $theRootIdx]
	}

	# remember current message in `msgPrevQueue`
	if {$crntMsgId != {}} {lappend msgPrevQueue $crntMsgId;}
	# assign the leftmost tweet on the Queue to crnt_msg and unshift the Queue
	set crntMsgId [lindex $msgQueue 0]
	set crnt_msg $theForrest($crntMsgId)

	set msgQueue [lreplace $msgQueue 0 0]; # pop message id from the queue
	set children [lindex $crnt_msg end]; # obtain children of current message
	set msgQueue [concat $msgQueue $children]; # append children to message queue
    } else {
	# if we have exhausted the queue of processed messages, we
	# give a message
	if {[llength $msgPrevQueue] == 0} {
	    tk_messageBox -message "Reached the beginning of the document.";
	    return;
	}

	if {$crntMsgId != {}} {
	    # remember popped message in `msgQueue`
	    set msgQueue [linsert $msgQueue[set msgQueue {}] 0 $crntMsgId];
	}
	# assign the leftmost tweet on the queue to crnt_msg and unshift the Queue
	set crntMsgId [lindex $msgPrevQueue end]
	set crnt_msg $theForrest($crntMsgId)
	set msgPrevQueue [lreplace $msgPrevQueue end end]; # pop message id from the queue
    }
    set crntMsgTxt [lindex $crnt_msg 0]; # obtain text of current message
    set prev_prnt_msg_id $prntMsgId; # remember id of previous parent
    set prntMsgId [lindex $crnt_msg 1];	# obtain id of the parent of current message

    # if parent has changed, reload it
    if {$prntMsgId != $prev_prnt_msg_id} {
	# hide all RST nodes in RST window which correspond to the
	# previous parent
	if {$crntMsgId != $prev_prnt_msg_id} {showNodes $prev_prnt_msg_id 0}
	# display all known RST nodes for the new parent
	# hide previous current node, if it is not the parent of the next message
	puts stderr "prntMsgId = $prntMsgId"
	puts stderr "prev_msg_id = $prev_msg_id"
	if {$prntMsgId != $prev_msg_id} {showNodes $prntMsgId 1}
	# obtain text of the new parent
	if {$prntMsgId == {}} {
	    set prntMsgTxt "";
	} else {
	    set prntMsgTxt [lindex $theForrest($prntMsgId) 0];
	}
	# reload the text
	.editor.textPrnt delete 0.0 end
	showSentences .editor.textPrnt $prntMsgId 1
    }
    if {$prntMsgId != $prev_msg_id} {showNodes $prev_msg_id 0;}
    # clear current message text area and place new text into it
    .editor.text delete 1.0 end
    .editor.text tag add new 1.0 end
    # show already annotated segments for current message and remember
    # position of the last annotated character
    set rvalues [showSentences .editor.text $crntMsgId]
    # show next segment if possible
    set boundary [lindex $rvalues 0]
    set offsetShift [lindex $rvalues end]
    # update what parts of the text have already been annotated and
    # which haven't
    set usedtext [string range $crntMsgTxt 0 $boundary];
    set theText [string range $crntMsgTxt $boundary end];
    # display next potential EDU chunk, if possible
    nextSentence $do_it;
    # display any nodes and sentences that already were annotated for
    # current message
    puts stderr "crntMsgId = $crntMsgId"
    puts stderr "prev_prnt_msg_id = $prev_prnt_msg_id"
    if {$crntMsgId != $prev_prnt_msg_id} {showNodes $crntMsgId 1}
    redisplay-net
}

# load next text chunk delimited by punctuation mark into the editor
proc nextSentence {{do_it {}} {trgframe .editor.text}} {
    global theText usedText currSentence abbreviations

    set flag 2
    set periods {}
    set testText $theText
    set old_new_first [$trgframe index new.first]
    while { $flag } {
	#search for the next end of sentence punctuation
	set nextCutoff [string first .  $testText]
	set exclamation [string first ! $testText]
	set question [string first ? $testText]
	if {$nextCutoff == -1} {
	    set nextCutoff [string length $testText]
	    incr nextCutoff -1
	}
	if {$exclamation != -1 && $exclamation < $nextCutoff} {
	    set nextCutoff $exclamation
	}
	if {$question != -1 && $question < $nextCutoff} {
	    set nextCutoff $question
	}
	set last [llength periods]
	incr last -1
	if {$flag == 1 && $nextCutoff == "[lindex $periods $last]"} {
	    set flag 0
	}
	set wordStart $nextCutoff
	while {$wordStart >= 0} {
	    incr wordStart -1
	    set character [string index $testText $wordStart]
	    if {"$character" == " " ||
		"$character" == "\n" ||
		"$character" == "\t"} {
		incr wordStart
		break
	    }
	}
	set test [string range $testText $wordStart $nextCutoff]
	if { [lsearch $abbreviations $test] == -1 } {
	    set flag 0
	} else {
	    set flag 1
	    incr nextCutoff
	    set testText [string range $testText $nextCutoff end]
	    lappend periods $nextCutoff
	}
    }
    foreach period $periods {
	set nextCutoff [expr $nextCutoff + $period]
    }

    set max_len [string length $theText]
    while {$nextCutoff < $max_len} {
	set quotetest [expr $nextCutoff + 1]
	set ichar [string index $theText $quotetest]
	if {[string is punct -strict $ichar] || \
		[string is space -strict $ichar]} {
	    incr nextCutoff
	} else {
	    break
	}
    }

    set currSentence [string range $theText 0 $nextCutoff]
    incr nextCutoff
    set textCutoff [string length "$theText"]
    incr textCutoff -1
    set theText [string range $theText $nextCutoff $textCutoff]
    set usedText "$currSentence$usedText"
    $trgframe insert end "$currSentence"
    if { [$trgframe tag ranges old] == {} } {
	$trgframe tag add new 1.0 end
    } else {
	$trgframe tag add new $old_new_first end
    }
    if {"$do_it" == "really"} {
	save-step "nextSentence really"
    }
}

set abbreviations {}

proc load_abbreviations { filename } {
    global abbreviations
    set abbreviations {}

    set abb_file [open $filename r]
    while { [gets $abb_file next_abb] >= 0 } {
  	lappend abbreviations $next_abb
    }
    close $abb_file
}

proc clear-current-file {} {
    global currentfile
    ##############################
    #SHORTCIRCUIT
    #  set result [tk_dialog .d1 {File Clear} "Save Open File?"\
	#		  warning 0 {Yes} {No} "Cancel"]
    #  switch -- $result {
    #         0 {save-file $currentfile}
    #         2 {return 0}
    #  }
    ################################
    #NEW
    set result [tk_dialog .d1 {File Clear} "Save Structure?"\
		    warning 0 {Yes} {No} "Cancel"]
    switch -- $result {
	0 {save-rst}
	2 {return 0}
    }
    reset-rst
    redisplay-net
}

proc save-file {{filename {}}} {
    global currentfile

    if { $filename ==  {} } {set filename $currentfile}

    # 1. Save the file
    set f [open $filename w 0600]
    puts $f  [.editor.text get 1.0 end]
    close $f

    editor-message "saved $filename"
}


proc save-file-as {{filename {}}} {
    global currentfile
    set oldfilename currentfile
    if { $filename ==  {} } {
	set filename [get-new-file-name]
	#    check for cancel
	if { $filename ==  {} } {return}
    }
    save-file $filename
    set currentfile {}
    load-file $filename

    editor-message "saved as $filename"
}


proc new-file {{filename {} }} {
    global currentfile

    # Clear the current file?
    if {[clear-current-file] == 0} {return}

    # make a new buffer
    if { $filename ==  {} } {
	set filename [get-new-file-name]
	#  check for cancel
	if { $filename ==  {} } {return}
    }

    # set the filename
    set currentfile $filename

    editor-message "created file: $filename"
}

proc revert-file {} {
    global currentfile
    load-file $currentfile
}

proc get-new-file-name {} {
    set filename [fileselect "New File" {} 0]
    if {[file exists $filename] == 1} {
	set result [tk_dialog .d {File Already Exists}\
			"File \"$filename\" already exists."\
			warning 0 {Overwrite} "Save As..." "Cancel"]
	switch -- $result {
	    0 {  }
	    1 { return [get-new-file-name] }
	    2 { return {} }
	}
    }
    return $filename
}


proc current-selection {w} {

    if {[llength [$w tag ranges sel]] > 0} {

	#1. Text is selected.
	$w get sel.first sel.last

	#2. left char is a bracket -return the included
    } elseif {[$w get "insert -1 char"] == ")"} {
	puts stdout "Paren-match not supported"

	#3. Cursor in the centre of a symbol
    } else {
	puts stdout [$w get "insert wordstart" "insert wordend"]
	$w get "insert wordstart" "insert wordend"
    }}


######################################
# Define Key Bindings

bind all <Meta-s> {
    global currentfile
    save-file $currentfile
}

bind all <Meta-o> {
    load-file  [fileselect]
}


# hack to stop the calls to this failing
# Each using app can define their own way to display messages
proc editor-message {arg} {
    .editor.msg delete 1.0 end
    .editor.msg insert end $arg}
