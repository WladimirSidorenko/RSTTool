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
		set prnt_id "";
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
		set prnt_id NaN;
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
    if { $filename == {} } {return}

    # 2. Load named file
    set theText ""
    set theRootIdx -1
    set msgQueue {}
    set f [open $filename]
    .editor.text delete 1.0 end
    read-file $f
    close $f

    # 3. Stop undo past installation
    textUndoer:reset $undoer

    set currentfile $filename
    if { $really == 1 } {
	open-step-file
    }

    editor-message "opened file:  $filename"
    .editor.text insert end "\n"
    .editor.text tag add old 1.0 1.0
    .editor.text tag add new 1.0 end
    #  save-step "load-file $filename"
    if { $really == 1 } {
	nextSentence really
    } else {
	nextSentence fake
    }
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
    if {"$do_it" == "really"} {
	save-step "showText really"
    }
}

proc nextSentence { {do_it {}} } {
    global theText usedText currSentence abbreviations
    global theRoots theRootIdx theForrest
    global crntMsgId crntMsgTxt prntMsgId prntMsgTxt msgQueue

    # if we have exhausted the queue of messages for current
    # discussion, we proceed to the next discussion in the forrest
    if {[llength $msgQueue] == 0} {
	incr theRootIdx;
	# if no more discussions are present, the return
	if {$theRootIdx >= [llength $theRoots]} {
	    return;
	}
	lappend msgQueue [lindex $theRoots $theRootIdx]
    }

    # assign the leftmost tweet on the Queue to crnt_msg and unshift the Queue
    set crntMsgId [lindex $msgQueue 0]
    set crnt_msg theForrest($crntMsgId)
    set msgQueue [lreplace $msgQueue 0 0]; # pop message id from the queue

    set crntMsgTxt [lindex $crnt_msg 0]; # obtain text of current message
    set prntMsgId [lindex $crnt_msg 1];	# obtain id of the parent of current message
    set children [lindex $crnt_msg end]; # obtain children of current message
    set msgQueue [concat $msgQueue $children]; # append children to message queue

    # if parent exists, obtain its text
    if {$prntMsgId == NaN} {
	set prntMsgTxt "";
    } else {
	set prntMsgTxt [lindex theForrest($prntMsgId) 0];
    }

    set old_new_first [.editor.text index new.first]
    set flag 2
    set periods {}
    set testText $theText
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
	if { $flag == 1 && $nextCutoff == "[lindex $periods $last]"} {
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
    set quotetest [expr $nextCutoff + 1]
    if {[string index $theText $quotetest] == "\""} {
	incr nextCutoff
    }

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

    if { $filename ==  {} } {
	set filename $currentfile
    }

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
