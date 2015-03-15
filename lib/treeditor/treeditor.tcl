#!/usr/bin/env wish
# -*- mode: tcl; -*-

##################################################################
package require rsttool::treeditor::layout
package require rsttool::treeditor::tree

##################################################################
namespace eval ::rsttool::treeditor {
    variable MAXLEN 20;
    variable NODE_WIDTH 100;
    variable HALF_NODE_WIDTH [expr $NODE_WIDTH / 2];
    variable Y_TOP 30;
    variable CURRENTSAT {};
    variable CURRENTMODE link;
    variable CURRENT_XPOS 0;
    variable RSTW {};
    variable NEWEST_NODE;
    variable WAITED_NID;
    variable DISCO_NODE {};
    variable USED_NODES {};
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
    variable RSTW;

    uninstall-structurer;

    # draw toolbar for tree editor
    set rtbar [frame .rtbar]
    button .rtbar.link -text "Link" -command {
	::rsttool::treeditor::set-mode link }
    button .rtbar.autolink -text "Auto" -command {
	::rsttool::treeditor::set-mode autolink }
    button .rtbar.disconnect -text "Disconnect" -command {
	::rsttool::treeditor::set-mode disconnect }
    button .rtbar.modify -text "Modify" -command {
	::rsttool::treeditor::set-mode modify }
    button .rtbar.rename -text "Rename" -command {
	::rsttool::treeditor::set-mode rename }
    button .rtbar.reduce -text "Reduce" -command {
	::rsttool::treeditor::layout::resize-display -50 }
    button .rtbar.enlarge -text "Enlarge" -command {
	::rsttool::treeditor::layout::resize-display 50 }
    # button .rtbar.undo_by_reload -text "Undo" -command {undo_by_reload}
    # button .rtbar.undo_by_redo -text "Don't Touch" -command {undo_by_redo}
    # button .rtbar.showtext -text "Show Text" -command {showText really}

    pack .rtbar -side left
    pack .rtbar.link .rtbar.autolink .rtbar.disconnect .rtbar.modify .rtbar.rename \
	.rtbar.reduce .rtbar.enlarge -in $rtbar -side top -fill x -expand 1

    # draw tree editor
    frame .rstframe

    set RSTW [canvas  .rstframe.canvas  -bg white -relief sunken\
		  -yscrollcommand ".rstframe.yscroll set"\
		  -xscrollcommand ".rstframe.xscroll set"\
		  -height [expr [winfo screenheight .] * 0.4] \
		  -width  [expr [winfo screenwidth .] * 0.8]]

    scrollbar .rstframe.yscroll -orient vertical\
	-command ".rstframe.canvas yview"
    scrollbar .rstframe.xscroll -orient horizontal\
	-command ".rstframe.canvas xview"

    label .rstframe.msg -textvariable new_node_text
    pack .rstframe.msg -side bottom -fill x
    pack .rstframe.yscroll -side right -fill y
    pack .rstframe.xscroll -side bottom -fill x
    pack .rstframe.canvas -fill both -expand 1 -side left
    install-structurer
}

proc ::rsttool::treeditor::install-structurer {} {
    pack .rstframe -side top -fill both -expand true
}

proc ::rsttool::treeditor::uninstall-structurer {} {
    pack forget .rtbar .rstframe
}

proc ::rsttool::treeditor::toggle-button {mode dir} {
    switch -- $mode {
	link   {.rtbar.link configure -relief $dir}
	rename {.rtbar.rename configure -relief $dir}
	disconnect {.rtbar.disconnect configure -relief $dir}
	modify {.rtbar.modify configure -relief $dir}
	autolink {.rtbar.autolink configure -relief $dir}
	parenthetical {}
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
	if {[clicked-node %x %y] != 0} {
	    collapse [clicked-node %x %y]}
    }
    bind $RSTW <ButtonRelease-2> {
	if {[clicked-node %x %y] != 0} {
	    collapse [clicked-node %x %y]}
    }
    bind $RSTW <Shift-Control-ButtonRelease-1> {
	if {[clicked-node %x %y] != 0} {
	    expand [clicked-node %x %y]}
    }
    bind $RSTW <ButtonRelease-3> {
	if {[clicked-node %x %y] != 0} {
	    expand [clicked-node %x %y]}
    }
    switch -- $mode {
	autolink { $RSTW config -cursor hand2
	    bind $RSTW <ButtonPress-1> {}
	    bind $RSTW <ButtonRelease-1> {
		set clicked_node [clicked-node %x %y]
		if { [legal-node $clicked_node] != 0} {
		    autolink_nodes $clicked_node
		}
	    }
	}
	link   { $RSTW config -cursor sb_h_double_arrow
	    $RSTW bind nodes <Button-1> {}
	    bind $RSTW <ButtonPress-1> {
		if {[clicked-node %x %y] != 0} {
		    set NEWEST_NODE [clicked-node %x %y] } }
	    bind $RSTW <ButtonRelease-1> {
		if {[clicked-node %x %y] != 0} {
		    autolink_nodes [clicked-node %x %y] } }
	}
	disconnect { $RSTW config -cursor X_cursor
	    bind $RSTW <ButtonPress-1> {}
	    $RSTW bind nodes <Button-1> {}
	    bind $RSTW <ButtonRelease-1> {
		if {[clicked-node %x %y] != 0} {
		    unlink-node [clicked-node %x %y]
		    redisplay-net
		}
	    }
	}
	modify { $RSTW config -cursor X_cursor
	    bind $RSTW <ButtonPress-1> {}
	    $RSTW bind nodes <Button-1> {}
	    bind $RSTW <ButtonRelease-1> {
		if {[clicked-node %x %y] != 0} {
		    disconnect_node [clicked-node %x %y] modify}
	    }
	}
	rename { $RSTW config -cursor hand1
	    bind $RSTW <ButtonPress-1> {}
	    bind $RSTW <ButtonRelease-1> {
		if { [clicked-node %x %y] != 0} {
		    change_rel [clicked-node %x %y]
		}
	    }
	}
	parenthetical { $RSTW config -cursor X_cursor
	    bind $RSTW <ButtonPress-1> {
		if {[clicked-node %x %y] != 0} {
		    set WAITED_NID [clicked-node %x %y] } }
	    bind $RSTW <ButtonRelease-1> {}
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
