#!/nfs/isd/marcu/software/tk8.1b1/unix/wish -f
 
encoding system euc-jp

wm title . "RST Interface"
wm protocol . WM_DELETE_WINDOW Quit
 
frame .segmentframe
 
######################################
# Load the modules
 
set LOGIN marcu
set PRINTER ps9b_s
set MAX_CLICK_DELAY 120
set VERSION UNIX
#set VERSION PC
if {$VERSION == "UNIX"} {
  set DIR   "/nfs/isd/marcu/RSTTool/"
#  set DIR   "/nfs/isd/liberman/tcl/RSTTool/"
} else {
  set DIR     "c:/windows/Desktop/RSTTool-Embedded/"
}
set DOT_EXISTS YES
#set DOT_EXISTS NO
if {$DOT_EXISTS == "YES"} {
  set DOT     "/nfs/etg/mediadoc/graphviz/src/cmd/dot/dot"
} else {
  set DOT    {}
}
set SRC     [file join $DIR Source]
set LIBRARY [file join $SRC Library]
set RELS    [file join $DIR Relation-Sets]
set HELP    [file join $DIR Help]

  

set LIB_FILES {dialog1.tcl tcl-extens.tcl\
               delete.tcl toolbar.tcl draw.tcl}
set SRC_FILES {Segmenter Structurer-Japanese Make Layout Draw Print EditRelations}
set EDITOR_FILES {new.tcl lifo.tcl textundo.tcl Editor1-Japanese.tcl}
 
proc load-module {Path Files} {
 
  foreach file $Files {
   puts "Loading $file"
   source [file join $Path $file]
 }
}
load-module $LIBRARY $LIB_FILES
load-module $LIBRARY $EDITOR_FILES
load-module $SRC $SRC_FILES
 
 
 
load-relations [file join $RELS Relations]
load_abbreviations [file join $RELS abbreviations]
 
proc Quit {} {exit}
 
set currentfile tmp
 
install-segmenter
reset-rst
 
.editor.text tag configure new -foreground black
.editor.text tag configure next -foreground white
.editor.text tag configure old -foreground red
.editor.text tag configure notes -foreground black
.editor.text tag configure my_sel -background yellow
 
bind .editor.text <Shift-ButtonRelease-1> { nextSentence really }
bind .editor.text <ButtonRelease-3> { nextSentence really }
bind .editor.text <Control-ButtonRelease-1> { 
	compare-click-times
	add-this-to-a-node really 
	}
bind .editor.text <ButtonRelease-2> { 
	compare-click-times
	add-this-to-a-node really 
	}
bind .editor.text <ButtonRelease-1> { 
	compare-click-times
	create-a-node-here really
	}


proc add-this-to-a-node { do_it {my_current {}} {dummy_param {}} } {
  global last_text_node_id newest_node savenum new_node_text node
  global editor_mode

  if {$editor_mode == "normal"} {
    .editor.text delete my_sel.last new.first
    .editor.text insert my_sel.last "<p>"
  }
  if {$my_current == {} } {
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
      save-rst $savenum
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

proc choose-node-for-text { } {
  global waited_nid
  tkwait variable waited_nid
  return $waited_nid
} 

set x1 {}
set x2 {}
proc create-a-node-here { do_it {my_current {}} {junk1 {}} {junk2 {}} } {
  global last_text_node_id newest_node savenum new_node_text
  global x1 x2
  if {$my_current == {} } {
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

  set x [.editor.text index my_sel.last]
  set y [.editor.text index end]
  .editor.text mark set last_sel my_sel.last
  if { $x == $y } {
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
  	set newest_node [make-node $new_node_text "text"]
  	redisplay-net
  }


  .editor.text tag add old my_sel.first last_sel
  .editor.text tag remove new my_sel.first last_sel

  .editor.text mark set insert last_sel
  .editor.text insert my_sel.last "<$last_text_node_id>"
  .editor.text tag remove sel 1.0 end
  if { "$do_it" == "really" } {
  	set myStep "create-a-node-here really [.editor.text index my_sel.last]" 
	append myStep " $last_text_node_id"
        regsub -all "\n" $the_selection {\n} the_selection
        regsub -all "\t" $the_selection {\t} the_selection
	append myStep " \{$the_selection\}"
  	save-step "$myStep" 
  	save-rst $savenum
  }
  set-mode autolink
  editor-message "saved tmp.$savenum"
  set x [.editor.text index "end - 1 chars"]
  set y [.editor.text index insert]
  if { $x == $y } {
	nextSentence $do_it
  }
  set line_no [.editor.text index old.last]
  .editor.text yview [expr int($line_no)]
  .editor.text tag add notes my_sel.last new.first
}

proc set-file-name { file_type { other_file {} } } {
  global currentfile 
  global VERSION LOGIN

  if {$other_file == {}} {
    set other_file $currentfile
  }
  set shortfilename [split $other_file /]
  set x [llength $shortfilename]
  incr x -1
  set shortfilename [lindex $shortfilename $x]

  if {$VERSION == "UNIX"} {
    set my_name [exec whoami]
    return $shortfilename.$file_type.$my_name
  } else {
#VERSION == PC
    return $shortfilename.$file_type.$LOGIN 
  }
} 

proc open-step-file {} {
  global step_file currentfile

  set mystepfile [set-file-name step]

  set step_file [open $currentfile.rst/$mystepfile w 0644]
}

proc read-step-file {} {
  global step_file currentfile

  set mystepfile [set-file-name step]

  set step_file [open $currentfile.rst/$mystepfile r]
}

proc peruse-step-file {} {
  global step_file currentfile
  global VERSION

  set mystepfile [set-file-name step]
  set mystepfile [split $mystepfile .]
  set mystepfile [lindex $mystepfile 0].[lindex $mystepfile 1]

  if {$VERSION == "UNIX"} {
    set dircontents [exec ls $currentfile.rst/]
    set dircontents [split $dircontents "\n"]
  } else {
    set dircontents [exec command.com /c dir $currentfile.rst]
  }
  set stepfile_list {}
  set index [lsearch $dircontents $mystepfile.*]
  while {$index != -1} {
    lappend stepfile_list [lindex $dircontents $index]
    set dircontents [lreplace $dircontents $index $index]
    set index [lsearch $dircontents $mystepfile.*]
  }
  if {[lindex $stepfile_list 1] != {}} {
    set mystepfile [popup-choose-from-list "$stepfile_list" 0 0 NOcancel]
  } else {
    set mystepfile [lindex $stepfile_list 0]
  }

  set step_file [open $currentfile.rst/$mystepfile r]
}

proc save-step {the_step} {
  global step_file currentfile
  puts $step_file "$the_step"
  flush $step_file
}

proc close-step-file {} {
  global step_file 
  if {"$step_file" != {} } {
    close $step_file
  }
}

set collapsed_nodes {}

proc reestablish {} {
  global savenum collapsed_nodes node step_file

  reset-rst
  if { $savenum > 0 } {
    load-rst $savenum
    foreach coll_n $collapsed_nodes {
       foreach child $node($coll_n,children) {
     	  hide-node $child
       }
    }
  }

  redisplay-net
}

proc reload-it-all {filename} {
  global step_file currentfile savenum last_text_node_id 
  global new_node_text newest_node theText usedText

  set new_node_text {}
  set theText {}
  set usedText {}
  reset-rst

  load-file $filename
  close-step-file

  set step_file [open $currentfile.step r]

  set my_list {}
  set i 0
  while {[gets $step_file my_command] >= 0} {
    lappend my_list $my_command
  }
  close-step-file
  open-step-file
  set savenum 0
  set last_text_node_id 0
  foreach my_command $my_list {
    save-step "$my_command"
    if {[regexp {^autolink_nodes} $my_command]} {
      incr savenum
    } elseif {[regexp {^create-a-node-here} $my_command]} {
      incr savenum
      incr last_text_node_id
      regsub really $my_command fake my_command
      eval $my_command
    } elseif {[regexp {^add-this-to-a-node} $my_command]} {
      incr savenum
      regsub really $my_command fake my_command
      eval $my_command
    } elseif {[regexp {^nextSentence} $my_command]} {
      regsub really $my_command fake my_command
      eval $my_command
    }
  }
  reset-rst
  if { $savenum > 0 } {
    load-rst $savenum
    set newest_node $last_text_node_id
  } else {
    reset-rst
    redisplay-net
  }
  editor-message "loaded $currentfile.$savenum"
}

set disco_node {}

set peruse_or_edit {}

proc undo_by_reload { {really {1}} } {
  global step_file currentfile savenum last_text_node_id 
  global new_node_text newest_node theText usedText collapsed_nodes
  global editor_mode disco_node erased_nodes 

  set new_node_text {}
  set theText {}
  set usedText {}
  set collapsed_nodes {}
  set editor_mode normal

  bind .editor.text <Control-ButtonRelease-1> {add-this-to-a-node really}
  bind .editor.text <ButtonRelease-2> {add-this-to-a-node really}
  bind .editor.text <ButtonRelease-1> {create-a-node-here really}

  if {$really == 1} {
    save-step #undo
    #load text
  }

  reload-current-file 

#3rd case - allows perusal of someone else's structure
  if {$really != 2} {
    close-step-file
    read-step-file
  } else {
    peruse-step-file
  }

  set my_list {}
  set i 0
  while {[gets $step_file my_command] >= 0} {
    lappend my_list $my_command
    if {[regexp {^#undo} $my_command]} {
      set j $i
      set my_list [lreplace $my_list $j $j "#UNDID"]
      while { $j > 0 } {
	incr j -1
	set my_test [lindex $my_list $j]
	if {[regexp {^#} $my_test]} {
	} else {
	  set my_list [lreplace $my_list $j $j "#$my_test"]
          if {[regexp {^collapsed_nodes} $my_test]} {
	  } else {
	    set j 0
	  }
	}
      }
    }
    incr i
  }
  if {$really != 2} {
    close-step-file
    open-step-file
  }
  set savenum 0
  set erased_nodes {}
  set last_text_node_id 0
  foreach my_command $my_list {
    if {$really != 2} {
      save-step "$my_command"
    }
    if {[regexp {^autolink_nodes} $my_command]} {
      incr savenum
      set disco_node {}
      set-mode nothing
    } elseif {[regexp {^disconnect_node} $my_command]} {
      incr savenum
      set method [lindex $my_command 2]
      if {$method == "disconnect"} {
	set disco_node {}
	set-mode nothing
      } else {
#method == modify
        set disco_node [lindex $my_command 1]
        set-mode link
      }
      lappend erased_nodes $disco_node
    } elseif {[regexp {^create-a-node-here} $my_command]} {
      incr savenum
      incr last_text_node_id
      regsub really $my_command fake my_command
      eval $my_command
    } elseif {[regexp {^add-this-to-a-node} $my_command]} {
      incr savenum
      regsub really $my_command fake my_command
      eval $my_command
    } elseif {[regexp {^nextSentence} $my_command]} {
      regsub really $my_command fake my_command
      eval $my_command
    } elseif {[regexp {^showText} $my_command]} {
      regsub really $my_command fake my_command
      eval $my_command
    } elseif {[regexp {^collapsed_nodes} $my_command]} {
      eval "set $my_command"
    }
  }

  reload_structure

  editor-message "loaded $currentfile.$savenum"
}

proc reload_structure {} {
  global savenum newest_node last_text_node_id

  reset-rst

  if { $savenum > 0 } {
    load-rst $savenum
    set newest_node $last_text_node_id
  } else {
  }

  reestablish
}

set step_file {}
set currentfile {}
set savenum 0
set size_factor 130
set theText {}
set usedText {}
set cancelled 0
set editor_mode normal

set list_of_toplevels {}

proc create_toplevel {name} {
  global relations help list_of_toplevels

  if {[lsearch $list_of_toplevels $name] != -1} {
    destroy .$name
    destroy .$name.text
    destroy .$name.scroll
    destroy .$name.menubar
  } else {
    append list_of_toplevels $name
  }

  toplevel .$name 
  text .$name.text -yscrollcommand ".$name.scroll set" -height 30 -width 70
  scrollbar .$name.scroll -command ".$name.text yview"
  pack .$name.text -side left 
  pack .$name.scroll -side right -fill y
  menu .$name.menubar 
  if {$name == "relation_defs"} {
    .$name config -menu .$name.menubar
    set rel_items {mononuclear multinuclear embedded schema}
    foreach item $rel_items {
        menu .$name.menubar.$item -tearoff 0
        .$name.menubar add cascade -label "$item" -menu \
               .$name.menubar.$item
    }
    set types {rst multinuc embedded constit}
    foreach type $types {
  	if {$type == "rst"} { set my_label mononuclear
	} elseif {$type == "embedded"} { set my_label embedded
  	} elseif {$type == "multinuc"} { set my_label multinuclear
  	} else { set my_label schema }
  	foreach item $relations($type) {
	  .$name.menubar.$my_label add command -label "$item" \
		-command ".$name.text delete 1.0 end; \
		.$name.text insert end \{$help($item)\}"
  	}
    }
  } else {
    .$name.text delete 1.0 end 
    .$name.text insert end \{$help($name)\}
  }
}

set helpmenu {relation_defs interface}
foreach item $helpmenu {
        .menubar.mHelp add command -label "$item" -command \
		"create_toplevel $item"
}

set help() {}

proc load_help {} {
  global help RELS relations

  set types {rst multinuc constit embedded}
  foreach type $types {
    foreach item $relations($type) {
      set help($item) {No Help Available}
    }
  }
  set help(interface) {No Help Available}

  set i 0
  while { $i < 2 } {
    if { $i == 0 } {
      set help_file [open [file join $RELS Help.screen] r]
    } else {
      set help_file [open [file join $RELS Help] r]
    }
    while {![eof $help_file]} {
      set nextline {}
      set entry {}
      set last_char {}
      while {![eof $help_file] && $last_char != "\}"} {
	gets $help_file nextline
	if {$entry != {}} {
	  append entry "\n"
	}
	append entry "$nextline"
	set nextline [string trimright $nextline]
	set last_char [string length $nextline]
	incr last_char -1
	set last_char [string index $nextline $last_char]
      }
      set relation [lindex $entry 0]
      set definition [lindex $entry 1]
      set help($relation) $definition
    }
    close $help_file
    incr i
  }
}

load_help

proc show_help { relation } {
  global help 

  dialog .d$relation {$relation} "$help($relation)" {} -1 {done}
}

set actual_sec 0 
set last_date {}
set begin_date {}

proc start-time { { option {} } } {
  global currentfile begin_date last_date actual_sec

 if {$currentfile != {}} {
  set realtimefile [set-file-name realtime]
  set timefile [set-file-name time]

  set actual_sec 0

  if { $option == "reset" } {
    if {[file exists $currentfile.rst/$realtimefile]} {
      set g [open $currentfile.rst/$realtimefile w 0644]
      puts $g "hours: 0 \nminutes: 0 \nseconds: 0"
      close $g
    }
    if {[file exists $currentfile.rst/$timefile]} {
      set g [open $currentfile.rst/$timefile w 0644]
      puts $g "hours: 0 \nminutes: 0 \nseconds: 0"
      close $g
    }
  }
  set last_date [clock format [clock seconds]\
	 -format "%a %b %d %H:%M:%S %Z %Y" -gmt 0]
  set begin_date $last_date
 }
}

proc compare-click-times { } {
  global currentfile actual_sec last_date
  global MAX_CLICK_DELAY
  
  set current_date [clock format [clock seconds]\
	 -format "%a %b %d %H:%M:%S %Z %Y" -gmt 0]
  set time [calc-from-date "$last_date" "$current_date" 0 0 0]
  set time [split $time :]
  set seconds [lindex $time 2]
  set minutes [lindex $time 1]
  set hours [lindex $time 0]
  set minutes [expr $hours * 60 + $minutes]
  set seconds [expr $minutes * 60 + $seconds]
  if {$seconds <= [cast-as-number $MAX_CLICK_DELAY]} {
    set actual_sec [expr $actual_sec + $seconds]
  }
  set last_date $current_date
}

proc calculate-time {hrs min sec filename} {
  global currentfile

 if {$currentfile != {}} {
  set oldhrs 0
  set oldmin 0
  set oldsec 0
  set file [set-file-name $filename]
  if {[file exists $currentfile.rst/$file]} {
    set f [open $currentfile.rst/$file r]
    gets $f oldhrs
    set oldhrs [lindex $oldhrs 1]
    gets $f oldmin
    set oldmin [lindex $oldmin 1]
    gets $f oldsec
    set oldsec [lindex $oldsec 1]
    close $f
  }
  set g [open $currentfile.rst/$file w 0644]

  set sec [expr $oldsec + $sec]
  while {$sec >= 60} {
    set sec [expr $sec - 60]
    set min [expr $min + 1]
  }
  set min [expr $oldmin + $min]
  while {$min >= 60} {
    set min [expr $min - 60]
    set hrs [expr $hrs + 1]
  }
  set hrs [expr $oldhrs + $hrs]

  puts $g "hours: $hrs \nminutes: $min \nseconds: $sec"

  close $g
 }
}

proc export-time { } {
  global actual_sec begin_date

  calculate-time 0 0 $actual_sec realtime

  set current_date [clock format [clock seconds]\
	 -format "%a %b %d %H:%M:%S %Z %Y" -gmt 0]
  set time [calc-from-date "$begin_date" "$current_date" 0 0 0]
  set time [split $time :]
  set seconds [lindex $time 2]
  set minutes [lindex $time 1]
  set hours [lindex $time 0]
  calculate-time $hours $minutes $seconds time
}

proc cast-as-number { mystring } {
  set f [split $mystring {}]
  if {[lindex $f 0] == "0"} {
    set mystring [lindex $f 1]
  }
  return $mystring
}

proc calc-from-date { line1 line2 hour minute second} {
  set endtime [lindex $line2 3]
  set endtime [split $endtime :]
  set endhour [lindex $endtime 0]
  set endhour [cast-as-number $endhour]
  set endminute [lindex $endtime 1]
  set endminute [cast-as-number $endminute]
  set endsecond [lindex $endtime 2]
  set endsecond [cast-as-number $endsecond]

  set starttime [lindex $line1 3]
  set starttime [split $starttime :]
  set starthour [lindex $starttime 0]
  set starthour [cast-as-number $starthour]
  set startminute [lindex $starttime 1]
  set startminute [cast-as-number $startminute]
  set startsecond [lindex $starttime 2]
  set startsecond [cast-as-number $startsecond]
  set second [expr $endsecond - $startsecond + $second]
  set minute [expr $endminute - $startminute + $minute]
  set hour [expr $endhour - $starthour + $hour]
  while {$second >= 60} {
    set second [expr $second - 60]
    set minute [expr $minute + 1]
  }
  if {$second < 0} {
    set second [expr $second + 60]
    set minute [expr $minute - 1]
  }
  while {$minute >= 60} {
    set minute [expr $minute - 60]
    set hour [expr $hour + 1]
  }
  if {$minute < 0} {
    set minute [expr $minute + 60]
    set hour [expr $hour - 1]
  }
  if {$hour < 0} {
    set hour [expr $hour + 24]
  }
  set answer " $hour: $minute: $second"
  return $answer
}
