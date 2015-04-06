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
    namespace import ::rsttool::treeditor::tree::node::show-nodes;

    if {$DISPLAYMODE == $a_mode} {return;}
    switch -nocase -- $a_mode \
	$MESSAGE {
	    show-nodes $PRNT_MSGID 1 {internal};
	    show-nodes $CRNT_MSGID 1 {internal};
	    show-nodes $PRNT_MSGID 1 {external};

	    toggle-button {message} {sunken};
	    toggle-button {discussion} {raised};
	} \
	$DISCUSSION {
	    show-nodes $PRNT_MSGID 0 {internal};
	    show-nodes $CRNT_MSGID 0 {internal};
	    if {$PRNT_MSGID == {}} {
		show-nodes $CRNT_MSGID 1 {external};
	    } else {
		show-nodes $PRNT_MSGID 1 {external};
	    }
	    toggle-button {message} {raised};
	    toggle-button {discussion} {sunken};
	} \
	default {
	    return;
	}

    set DISPLAYMODE $a_mode;
    layout::redisplay-net;
}

# update roots of all message pair involving given message
proc ::rsttool::treeditor::update-roots {a_msgid a_nid a_operation} {
    variable ::rsttool::NODES;
    variable ::rsttool::THREADS;
    variable ::rsttool::THREAD_ID;
    variable ::rsttool::PRNT_MSGID;
    variable ::rsttool::MSGID2ENID;
    variable ::rsttool::MSGID2ROOTS;
    variable ::rsttool::MSGID2EROOTS;
    variable ::rsttool::treeditor::MESSAGE;
    variable ::rsttool::treeditor::DISPLAYMODE;
    namespace import ::rsttool::utils::ldelete;

    # perform given operation on all messages
    set op {};
    switch -nocase --  $a_operation {
	{remove} {
	    set op ldelete;
	}
	{add} {
	    proc insort {a_list a_nid} {
		namespace import ::rsttool::treeditor::tree::node::get-start;
		return [::rsttool::treeditor::tree::node::insort  $a_list \
			    [get-start $a_nid] $a_nid];
	    }
	    set op insort;
	}
	default {
	    error "Unrecognized update operation: '$a_operation'."
	    return;
	}
    }
    # update roots of the message in question
    if {![info exists MSGID2ROOTS($a_msgid)]} {
	set MSGID2ROOTS($a_msgid) {};
    }
    set MSGID2ROOTS($a_msgid) [$op $MSGID2ROOTS($a_msgid) $a_nid]

    # update external nodes, if necessary
    if {$DISPLAYMODE == $MESSAGE} {
	if {[llength $MSGID2ROOTS($a_msgid)] == 1} {
	    set iroot [lindex $MSGID2ROOTS($a_msgid) 0];
	    variable ::rsttool::FORREST;
	    variable ::rsttool::MSGID2EROOTS;
	    namespace import ::rsttool::treeditor::tree::node::get-end;
	    namespace import ::rsttool::treeditor::tree::node::get-child-pos;

	    if {[get-end $iroot] == [string length [lindex $FORREST($a_msgid) 0]]} {
		if {![info exists MSGID2ENID($a_msgid)]} {set MSGID2ENID($a_msgid) {}}
		set MSGID2ENID($a_msgid) [concat $iroot $MSGID2ENID($a_msgid)];

		set prnt_msgid [lindex $FORREST($a_msgid) 1];
		if {$prnt_msgid != {}} {
		    if {![info exists MSGID2EROOTS($prnt_msgid)]} {set MSGID2EROOTS($prnt_msgid) {}}
		    set MSGID2EROOTS($prnt_msgid) [concat [lrange $MSGID2EROOTS($prnt_msgid) 0 0] \
			[::rsttool::treeditor::tree::node::insort \
			     [lrange $MSGID2EROOTS($prnt_msgid) 1 end] \
			     [get-child-pos $a_msgid] $iroot 0 \
			     ::rsttool::treeditor::tree::node::get-child-pos]];
		}
	    }
	} elseif {[info exists MSGID2ENID($a_msgid)]} {
	    array unset MSGID2ENID $a_msgid;
	}
    }
}

##################################################################
package provide rsttool::treeditor 0.0.1
return
