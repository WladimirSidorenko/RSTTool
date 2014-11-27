# Define Frame for a emacs-style editor
# And Procedures to support it
# This version supports single file at a time only

# TO DO
#5. ctl-x s should work

######################################
# Define the Frame

if {![winfo exists .editor]} {
  scrolled-text .editor -height 30 -titlevar currentfile\
     -font -*-Courier-Medium-R-Normal--16-140-*-*-*-*-*-*\
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

proc load-file {filename {really {1}} } {
  global currentfile undoer theText collapsed_nodes
  global step_file

  set last_element [llength $collapsed_nodes]
  incr last_element -1
  if { $last_element > -1 } {
	set collapsed_nodes [lreplace $collapsed_nodes 0 $last_element]
  }
  if {$step_file != {}} { close-step-file }
  if { $filename == {} } {return}

  file mkdir $filename.rst


# 2. Load the named file
  set f [open $filename]
  .editor.text delete 1.0 end
  set theText ""
  while {![eof $f]} {
   append theText [read $f 1000]
#   .editor.text insert end [read $f 1000]
  }
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
    next-sentence really
  } else {
    next-sentence fake
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
}

proc next-sentence { {do_it {}} } {
  global theText usedText currSentence abbreviations
  set old_new_first [.editor.text index new.first]
  set flag 2
  set periods {}
  set testText $theText
  while { $flag } {
#search for the next end of sentence punctuation
    set nextCutoff [string first "\n\n"  $testText]
    set exclaimation [string first [encoding convertfrom euc-jp "\xA1\xA3"] $testText]
    set question [string first ? $testText]
    if {$nextCutoff == -1} {
	set nextCutoff [string length $testText]
	incr nextCutoff -1
    }
    if {$exclaimation != -1 && $exclaimation < $nextCutoff} {
	set nextCutoff $exclaimation
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












