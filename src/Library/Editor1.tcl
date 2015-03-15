# -*- mode: tcl; -*-

# Define Frame for a emacs-style editor
# And Procedures to support it
# This version supports single file at a time only

# TO DO:
# 5. ctl-x s should work

######################################
# Define the Frame


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
    global theRoots theRootIdx theForrest
    global crntMsgId crntMsgTxt msgQueue msgPrevQueue visible_nodes

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
    set prnt_id "";		# id of parent tweets
    set parents {};		# stack of parents

    set chunk "";		# text chunk read from file
    set remainder "";		# incompletely read line part
    set line "";		# single line
    set lines [];		# array of split lines
    # reset forrest
    array unset theForrest
    set theRoots {}
    set theRootIdx -1
    set crntMsgId {}
    set prntMsgTxt ""

    array unset visible_nodes
    set msgQueue {}
    set msgPrevQueue {}
    set msgPrevQueue {}

    while {![eof $a_istream]} {
	# obtain next 1k symbols from the input stream
	set chunk [read $a_istream 1000]
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
    global theRootIdx msgQueue
    global step_file

    set last_element [llength $collapsed_nodes]
    incr last_element -1
    if { $last_element > -1 } {
	set collapsed_nodes [lreplace $collapsed_nodes 0 $last_element]
    }
    if {$step_file != {}} { close-step-file }
    if {$filename == {}} {return}

    # 2. Load named file
    set f [open $filename]
    read-file $f
    close $f

    # 3. Stop undo past installation
    textUndoer:reset $undoer

    set currentfile $filename

    editor-message "opened file:  $filename"
    # .editor.text insert end "\n"
    .editor.text tag add old 1.0 1.0
    .editor.text tag add new 1.0 end
    #  save-step "load-file $filename"
    next-message $really
}

proc show-sentences {path_name msg_id {show_rest 0}} {
    # display already EDU segements in widget `path_name`
    global theForrest msgid2nid node
    # obtain annotated EDUs for given message
    if {! [info exists theForrest($msg_id)]} {
	return {0 0};
    } elseif {[info exists msgid2nid($msg_id)]} {
	# puts stderr "show-sentences: msgid2nid($msg_id) == $msgid2nid($msg_id)"
	set nids $msgid2nid($msg_id);
    } elseif {$show_rest} {
	set nids {};
    } else {
	return {0 0};
    }
    # obtain text of the message to be displayed
    set msg $theForrest($msg_id);
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
	if {$node($nid,type) != "text"} {break;}

	# puts stderr "show-sentences: node(nid = $nid,offsets) = $node($nid,offsets)"
	lassign $node($nid,offsets) start end
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

proc current-selection {w} {
    if {[llength [$w tag ranges sel]] > 0} {

	#1. Text is selected.
	$w get sel.first sel.last

	#2. left char is a bracket -return the included
    } elseif {[$w get "insert -1 char"] == ")"} {
	puts stdout "Paren-match not supported"

	#3. Cursor in the center of a symbol
    } else {
	puts stdout [$w get "insert wordstart" "insert wordend"]
	$w get "insert wordstart" "insert wordend"
    }
}

######################################
# Define Key Bindings

# hack to stop the calls to this failing
# Each using app can define their own way to display messages
proc editor-message {arg} {
    .editor.msg delete 1.0 end
    .editor.msg insert end $arg
}
