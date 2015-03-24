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
    # button .RTBAR.undo_by_reload -text "Undo" -command {undo_by_reload}
    # button .RTBAR.undo_by_redo -text "Don't Touch" -command {undo_by_redo}
    # button .RTBAR.showtext -text "Show Text" -command {showText really}

    pack $RTBAR -side top
    pack $RTBAR.link $RTBAR.disconnect $RTBAR.rename \
	$RTBAR.reduce $RTBAR.enlarge -in $RTBAR -side left -fill y -expand 1

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
    pack .rstframe -side top -fill both -expand true;
    set-mode link;
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

##################################################################
package provide rsttool::treeditor 0.0.1
return
