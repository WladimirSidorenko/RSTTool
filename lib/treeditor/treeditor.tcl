#!/usr/bin/env wish
# -*- mode: tcl; -*-

##################################################################
package require rsttool::treeditor::layout
package require rsttool::treeditor::tree

##################################################################
namespace eval ::rsttool::treeditor {
    variable menu_selection {};

    variable MAXLEN 20;
    variable NODE_WIDTH 100;
    variable HALF_NODE_WIDTH [expr $NODE_WIDTH / 2];
    variable Y_TOP 30;
    variable CURRENTSAT {};
    variable CURRENTMODE link;
    variable CURRENT_XPOS 0;
    variable RTBAR {};
    variable RSTW {};
    variable DRAGGED_NID {};
    variable NEWEST_NODE;
    variable WAITED_NID;
    variable DISCO_NODE {};
    variable USED_NODES {};
    variable MESSAGE 0;
    variable DISCUSSION 1;
    variable DISPLAYMODE {};

    variable WTN;
    array set WTN {};
    variable VISIBLE_NODES;
    array set VISIBLE_NODES {};
    variable ERASED_NODES;
    array set ERASED_NODES {};
    variable COLLAPSED_NODES;
    array set COLLAPSED_NODES {};
}

##################################################################
proc ::rsttool::treeditor::update_menu {a_menu} {
    $a_menu add command -label "Redraw Structure" -command\
	{::rsttool::treeditor::layout::redisplay-net}
}

proc ::rsttool::treeditor::install {} {
    variable RTBAR;
    variable RSTW;

    uninstall-structurer;

    # draw tree editor
    frame .rstframe

    # draw toolbar for tree editor
    set RTBAR [frame .rstframe.rtbar]
    button $RTBAR.link -text "Link" -command {
	::rsttool::treeditor::set-mode link }
    # button $RTBAR.autolink -text "Auto" -command {
    # 	::rsttool::treeditor::set-mode autolink }
    button $RTBAR.disconnect -text "Disconnect" -command {
	::rsttool::treeditor::set-mode disconnect }
    # button $RTBAR.modify -text "Modify" -command {
    # 	::rsttool::treeditor::set-mode modify }
    button $RTBAR.rename -text "Rename" -command {
	::rsttool::treeditor::set-mode rename }
    button $RTBAR.reduce -text "Reduce" -command {
	::rsttool::treeditor::layout::resize-display -50 }
    button $RTBAR.enlarge -text "Enlarge" -command {
	::rsttool::treeditor::layout::resize-display 50 }
    button $RTBAR.discussion -text "Discussion" -command {
	::rsttool::treeditor::set-display-mode $::rsttool::treeditor::DISCUSSION}
    button $RTBAR.message -text "Message" -command {
	::rsttool::treeditor::set-display-mode $::rsttool::treeditor::MESSAGE}
    # button .RTBAR.undo_by_reload -text "Undo" -command {undo_by_reload}
    # button .RTBAR.undo_by_redo -text "Don't Touch" -command {undo_by_redo}
    # button .RTBAR.showtext -text "Show Text" -command {showText really}

    pack $RTBAR -side top
    pack $RTBAR.link $RTBAR.disconnect $RTBAR.rename \
	$RTBAR.reduce $RTBAR.enlarge $RTBAR.message $RTBAR.discussion \
	-in $RTBAR -side left -fill y -expand 1

    set RSTW [canvas .rstframe.canvas  -bg white -relief sunken\
		  -yscrollcommand ".rstframe.yscroll set"\
		  -xscrollcommand ".rstframe.xscroll set"\
		  -height [expr [winfo screenheight .] * 0.4] \
		  -width  [expr [winfo screenwidth .] * 0.8]]

    scrollbar .rstframe.yscroll -orient vertical -command ".rstframe.canvas yview"
    scrollbar .rstframe.xscroll -orient horizontal -command ".rstframe.canvas xview"

    pack .rstframe.yscroll -side right -fill y
    pack .rstframe.xscroll -side bottom -fill x
    pack .rstframe.canvas -fill both -expand 1 -side left

    install-structurer
}

proc ::rsttool::treeditor::install-structurer {} {
    variable ::rsttool::treeditor::MESSAGE;

    pack .rstframe -side top -fill both -expand true;

    set-mode link;
    set-display-mode $MESSAGE;
}

proc ::rsttool::treeditor::uninstall-structurer {} {
    variable RTBAR;
    variable RSTW;

    pack forget $RTBAR $RSTW;
}

proc ::rsttool::treeditor::toggle-button {mode dir} {
    variable RTBAR;
    switch -- $mode {
	link   {$RTBAR.link configure -relief $dir}
	rename {$RTBAR.rename configure -relief $dir}
	disconnect {$RTBAR.disconnect configure -relief $dir}
	message {$RTBAR.message configure -relief $dir}
	discussion {$RTBAR.discussion configure -relief $dir}
	nothing {}
    }
}

# managing modes
proc ::rsttool::treeditor::set-mode {mode} {
    variable RSTW;
    variable CURRENTMODE;
    variable NEWEST_NODE;
    variable WAITED_NID;

    toggle-button $CURRENTMODE "raised"
    set CURRENTMODE $mode
    toggle-button $CURRENTMODE "sunken"

    bind $RSTW <Control-ButtonRelease-1> {
	set iclicked [::rsttool::treeditor::tree::clicked-node %x %y];
	if {$iclicked != {}} {
	    ::rsttool::treeditor::tree::node::collapse $iclicked;}
    }
    bind $RSTW <ButtonRelease-2> {
	set iclicked [::rsttool::treeditor::tree::clicked-node %x %y];
	if {$iclicked != {}} {
	    ::rsttool::treeditor::tree::node::collapse $iclicked;}
    }
    bind $RSTW <Shift-Control-ButtonRelease-1> {
	set iclicked [::rsttool::treeditor::tree::clicked-node %x %y];
	if {$iclicked != {}} {
	    ::rsttool::treeditor::tree::node::expand $iclicked;}
    }
    bind $RSTW <ButtonRelease-3> {
	set iclicked [::rsttool::treeditor::tree::clicked-node %x %y];
	if {$iclicked != {}} {
	    ::rsttool::treeditor::tree::node::expand $iclicked;}
    }
    switch -- $mode {
	link   { $RSTW config -cursor sb_h_double_arrow
	    $RSTW bind nodes <Button-1> {}
	    bind $RSTW <ButtonPress-1> {
		set iclicked [::rsttool::treeditor::tree::clicked-node %x %y];
		if {$iclicked != {}} {
		    set ::rsttool::treeditor::DRAGGED_NID $iclicked } }
	    bind $RSTW <ButtonRelease-1> {
		set iclicked [::rsttool::treeditor::tree::clicked-node %x %y];
		if {$iclicked != {}} {
		    ::rsttool::treeditor::tree::link-nodes $iclicked } }
	}
	disconnect { $RSTW config -cursor X_cursor
	    bind $RSTW <ButtonPress-1> {}
	    $RSTW bind nodes <Button-1> {}
	    bind $RSTW <ButtonRelease-1> {
		set iclicked [::rsttool::treeditor::tree::clicked-node %x %y];
		if {$iclicked != {}} {
		    ::rsttool::treeditor::tree::unlink-nodes $iclicked;
		    ::rsttool::treeditor::layout::redisplay-net;
		}
	    }
	}
	rename { $RSTW config -cursor hand1
	    bind $RSTW <ButtonPress-1> {}
	    bind $RSTW <ButtonRelease-1> {
		set iclicked [::rsttool::treeditor::tree::clicked-node %x %y];
		if {$iclicked != {}} {
		    ::rsttool::treeditor::tree::arc::change $iclicked;
		}
	    }
	}
	nothing { $RSTW config -cursor X_cursor
	    bind $RSTW <ButtonPress-1> {}
	    bind $RSTW <ButtonRelease-1> {}
	}
    }
}

# change display mode either to discussion or single message
proc ::rsttool::treeditor::set-display-mode {a_mode} {
    variable ::rsttool::CRNT_MSGID;
    variable ::rsttool::PRNT_MSGID;
    variable ::rsttool::treeditor::MESSAGE;
    variable ::rsttool::treeditor::DISCUSSION;
    variable ::rsttool::treeditor::DISPLAYMODE;
    namespace import ::rsttool::utils::reset-array;
    namespace import ::rsttool::treeditor::tree::node::show-nodes;
    # switch mode
    if {$DISPLAYMODE == $a_mode} {return;}
    set DISPLAYMODE $a_mode;
    # reset visible nodes
    reset-array ::rsttool::treeditor::VISIBLE_NODES;

    # set new visible nodes
    switch -nocase -- $a_mode \
	$MESSAGE {
	    if {$PRNT_MSGID != {}} {
		show-nodes $PRNT_MSGID 1;
	    }
	    show-nodes $CRNT_MSGID 1;
	    toggle-button {message} {sunken};
	    toggle-button {discussion} {raised};
	} \
	$DISCUSSION {
	    if {$PRNT_MSGID == {}} {
		show-nodes $CRNT_MSGID 1;
	    } else {
		show-nodes $PRNT_MSGID 1;
	    }
	    toggle-button {message} {raised};
	    toggle-button {discussion} {sunken};
	} \
	default {
	    return;
	}
    layout::redisplay-net;
}

# update roots of all message pair involving given message
proc ::rsttool::treeditor::update-roots {a_msgid a_nid a_operation {a_external 0}} {
    variable ::rsttool::NODES;
    variable ::rsttool::FORREST;
    variable ::rsttool::THREADS;
    variable ::rsttool::THREAD_ID;
    variable ::rsttool::NID2MSGID;
    variable ::rsttool::PRNT_MSGID;
    variable ::rsttool::MSGID2ENID;
    variable ::rsttool::MSGID2ROOTS;
    variable ::rsttool::MSGID2EROOTS;
    variable ::rsttool::treeditor::MESSAGE;
    variable ::rsttool::treeditor::DISCUSSION;
    variable ::rsttool::treeditor::DISPLAYMODE;
    namespace import ::rsttool::utils::ldelete;

    # perform given operation on all messages
    set op {};
    switch -nocase -- $a_operation {
	{remove} {
	    set op ldelete;
	}
	{add} {
	    # define appropriate insertion operation
	    if {$a_external} {
		puts stderr "update-roots: msgid = $a_msgid, nid = $a_nid, add, external;";
		proc insort {a_list a_nid} {
		    variable ::rsttool::NID2MSGID;
		    namespace import ::rsttool::treeditor::tree::node::get-child-pos;
		    set start [get-child-pos $a_nid];
		    # use fully qualified `insort` here
		    set a_list [::rsttool::treeditor::tree::node::insort $a_list \
				    $start $a_nid 0 ::rsttool::treeditor::tree::node::get-child-pos];
		}
	    } else {
		proc insort {a_list a_nid} {
		    namespace import ::rsttool::treeditor::tree::node::get-start;
		    # use fully qualified `insort` here
		    return [::rsttool::treeditor::tree::node::insort  $a_list [get-start $a_nid] \
				$a_nid];
		}
	    }
	    set op insort;
	}
	default {
	    error "Unrecognized update operation: '$a_operation'."
	    return;
	}
    }

    # update external root nodes, if necessary
    if {$a_external} {
	# update set of external roots for the given message
	if {![info exists MSGID2EROOTS($a_msgid)]} {set MSGID2EROOTS($a_msgid) {}};
	if {$a_operation == {add}} {
	    if {$NID2MSGID($a_nid) == $a_msgid} {
		if {$MSGID2EROOTS($a_msgid) == {} || [lindex $MSGID2EROOTS($a_msgid) 0] != $a_nid} {
		    set MSGID2EROOTS($a_msgid) [concat $a_nid $MSGID2EROOTS($a_msgid)];
		    # puts stderr "update-roots: 0) MSGID2EROOTS($a_msgid) = $MSGID2EROOTS($a_msgid)";
		}
	    } else {
		if {$MSGID2EROOTS($a_msgid) != {} && \
			$NID2MSGID([lindex $MSGID2EROOTS($a_msgid) 0]) == $a_msgid} {
		    set MSGID2EROOTS($a_msgid) [concat [lindex $MSGID2EROOTS($a_msgid) 0] \
						    [$op [lrange $MSGID2EROOTS($a_msgid) 1 end] \
							 $a_nid]];
		    # puts stderr "update-roots: 1) MSGID2EROOTS($a_msgid) = $MSGID2EROOTS($a_msgid)";
		} else {
		    set MSGID2EROOTS($a_msgid) [$op $MSGID2EROOTS($a_msgid) $a_nid];
		    # puts stderr "update-roots: 2) MSGID2EROOTS($a_msgid) = $MSGID2EROOTS($a_msgid)";
		}
	    }
	} else {
	    set MSGID2EROOTS($a_msgid) [$op $MSGID2EROOTS($a_msgid) $a_nid];
	    # puts stderr "update-roots: 3) MSGID2EROOTS($a_msgid) = $MSGID2EROOTS($a_msgid)";
	}
    } else {
	# update roots of the message in question
	if {![info exists MSGID2ROOTS($a_msgid)]} {set MSGID2ROOTS($a_msgid) {}}
	set MSGID2ROOTS($a_msgid) [$op $MSGID2ROOTS($a_msgid) $a_nid]

	if {[llength $MSGID2ROOTS($a_msgid)] == 1} {
	    set iroot [lindex $MSGID2ROOTS($a_msgid) 0];
	    # puts stderr "update-roots: single root left = $iroot";
	    if {[info exists NODES($iroot,parent)] && $NODES($iroot,parent) != {}} {return}

	    namespace import ::rsttool::treeditor::tree::node::get-end;
	    # puts stderr "update-roots: iroot end = [get-end $iroot]";
	    # puts stderr "update-roots: message length = [string length [lindex $FORREST($a_msgid) 0]]";
	    if {[get-start $iroot] == 0 && \
		    [get-end $iroot] == [string length [lindex $FORREST($a_msgid) 0]]} {
		# puts stderr "update-roots: adding node $iroot to the list of message $a_msgid eroots";
		set NODES($iroot,external) 1;
		set NODES($iroot,etype) {text};
		set MSGID2ENID($a_msgid) $iroot;
		# update external roots of the current message
		update-roots $a_msgid $iroot {add} 1;
		# update external roots of the parent message
		if {$NODES($iroot,parent) != {}} {return}
		set prnt_msgid [lindex $FORREST($a_msgid) 1];
		if {$prnt_msgid != {}} {update-roots $prnt_msgid $iroot {add} 1}
	    }
	} elseif {[info exists MSGID2ENID($a_msgid)]} {
	    array unset MSGID2ENID $a_msgid;
	}
    }
}

##################################################################
package provide rsttool::treeditor 0.0.1
return
