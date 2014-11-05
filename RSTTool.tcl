#!/usr/bin/env wish

######################################
# Variables
set LOGIN nobody
set PLATFORM $tcl_platform(platform)
set CHANGED 0;			# flag indicating whether any
				# modifications are not saved
set x1 {}
set x2 {}
set seg_mrk_x {}
set seg_mrk_y {}
set disco_node {}
set collapsed_nodes {}
set txt_cursor xterm
set step_file {}
set currentfile {}
set size_factor 130
set actual_sec 0
set last_date {}
set begin_date {}
set cancelled 0
set editor_mode normal
set list_of_toplevels {}
set peruse_or_edit {}
set trgdir rst
set trgfname /dev/null
set save_fmt raw
set save_func "save-${save_fmt}"
set load_func "load-${save_fmt}"
set savenum 0
set crntMsgId {};	# id of the current message
set crntMsgTxt "";	# text of the current message
set prntMsgId {};	# id of the parent message
set prntMsgTxt "";	# text of the parent message
set msgQueue {};	# queue of messages not yet visited
set msgPrevQueue {};	# queue of visited messages
set theRoots {};	# id's of messages which start new discussions
set theRootIdx -1;	# index of current discussion
set erased_nodes {};	# list of erased nodes
array set visible_nodes {};    # list of nodes which are visible in RST editor
array set msgs2extnid {}; # array mapping pairs of message ids
			  # (prnt_msg_id,chld_msg_id) to the id of nodes which
			  # connect two messages
array set msgid2nid {};	  # mapping from message ids to ids of internal nodes
			  # belonging to that message
array set nid2msgid {};	  # mapping from node id to message id
array set help {};
set helpmenu {relation_defs interface}

######################################
# Methods
proc set-file-name { file_type { other_file {} } {create_dir {1}}} {
    global currentfile trgdir
    global PLATFORM LOGIN

    if {$other_file == {}} {
	set other_file $currentfile
    }

    set dirname [file join $trgdir $file_type]
    if {$create_dir && ![file exists $dirname]} {file mkdir $dirname}

    set basename [file rootname [file tail $other_file]]
    if {$PLATFORM == "unix"} {
	set uname [exec whoami]
    } else {
	set uname $LOGIN
    }
    return [file join $dirname "$basename.$uname"]
}

######################################
# Main Frame

# encoding system euc-jp
wm title . "RST-Editor"
proc Quit {} {exit}
wm protocol . WM_DELETE_WINDOW Quit
frame .segmentframe

# default appearance
tk_setPalette background gray35 foreground white activebackground white activeforeground red
# apply special default appearance settings for aqua
if {[tk windowingsystem] == "aqua"} {
    tk_setPalette background gray85 foreground black
}

######################################
# Modules
proc load-module {Path Files} {
    foreach ifile $Files {
	# puts stderr "Loading $ifile"
	source [file join $Path $ifile]
    }
}

set DIR [file dirname [info script]]
set SRC     [file join $DIR Source]
set LIBRARY [file join $SRC Library]
set RELS    [file join $DIR Relation-Sets]
set HELP    [file join $DIR Help]
set LIB_FILES {delete.tcl dialog1.tcl draw.tcl node.tcl tcl-extens.tcl tkfbox.tcl \
		   time.tcl toolbar.tcl}
set SRC_FILES {Segmenter Structurer Draw EditRelations Layout Make Print Helper}
set EDITOR_FILES {new.tcl lifo.tcl textundo.tcl Editor1.tcl}

load-module $LIBRARY $LIB_FILES
load-module $LIBRARY $EDITOR_FILES
load-module $SRC $SRC_FILES

array set relations {};
load-relations [file join $RELS Relations]
load-relations [file join $RELS ExtRelations] 1
load_abbreviations [file join $RELS abbreviations]
load_help

install-segmenter
reset-rst
set-mode link

######################################
# Appearance
catch {source $env(HOME)/.wishrc}

.editor.text configure -fg black -bg white -selectbackground gray85
.editor.textPrnt configure -fg black -bg white -selectbackground gray85
$rstw configure -bg white

set old_clr purple;
.editor.text tag configure old -foreground $old_clr
.editor.text tag configure next -foreground black
.editor.text tag configure new -foreground DimGray
.editor.text tag lower new
.editor.text tag configure notes -foreground black
.editor.text tag configure my_sel -background yellow

.editor.textPrnt tag configure old -foreground $old_clr

######################################
# Bindings

# load/save functions
bind all <Control-o> {open-file}
bind all <Control-s> {$save_func}

bind all <Control-q> {$save_func; exit}

bindtags .editor.text {all .editor.text Text . UndoBindings(1)}
bind .editor.text <Any-Key> {break}
bind .editor.text <ButtonRelease-2> {break}
bind .editor.text <Control-C> {continue}
bind .editor.text <Key-Super_L> {continue}
bind .editor.text <Key-Super_R> {continue}

# node creation functions
.editor.text tag bind new <ButtonRelease-1> {
    create-a-node-here really
}

.editor.text tag bind next <ButtonRelease-1> {
    create-a-node-here really
}

# node modification operations
.editor.text tag bind bmarker <Control-ButtonPress-1> {
    set seg_mrk_x %x
    set seg_mrk_y %y
    set txt_cursor [lindex [.editor.text configure -cursor] end]
    .editor.text configure -cursor question_arrow
    break
}

.editor.text tag bind bmarker <Control-ButtonRelease-1> {
    .editor.text configure -cursor $txt_cursor
    move-node .editor.text %x %y
    set seg_mrk_x {}
    set seg_mrk_y {}
    break
}

if {[tk windowingsystem] == "aqua"} {
    .editor.text tag bind bmarker <Control-Option-ButtonRelease-2> {
	delete-node .editor.text %x %y
    }
} else {
    .editor.text tag bind bmarker <Control-Alt-ButtonRelease-3> {
	delete-node .editor.text %x %y
    }
}
