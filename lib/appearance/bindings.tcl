##################################################################
namespace eval ::rsttool::appearance::bindings {
    variable MKEY {Ctrl};
    variable MODKEY {Control};
    if {[tk windowingsystem] == "aqua"} {
	set MODKEY {Command};
	set MKEY {Cmd};
    }
}

proc ::rsttool::appearance::bindings::set_default {{text_w .editor.text}} {
    variable ::rsttool::appearance::bindings::MODKEY;
    variable ::rsttool::segmenter::TXTW;
    variable ::rsttool::segmenter::PRNT_TXTW;
    variable ::rsttool::treeditor::RSTW;

    if {[tk windowingsystem] == "aqua"} {
	$TXTW tag bind bmarker <Control-Option-ButtonRelease-2> {
	    ::rsttool::segmenter::delete $::rsttool::segmenter::TXTW %x %y
	}
    } else {
	$TXTW tag bind bmarker <Control-Alt-ButtonRelease-3> {
	    ::rsttool::segmenter::delete $::rsttool::segmenter::TXTW %x %y
	}
    }

    # load/save functions
    bind all <$MODKEY-o> {::rsttool::file::open}
    bind all <$MODKEY-s> {::rsttool::file::save}
    bind all <$MODKEY-q> {::rsttool::quit}

    bindtags $TXTW {all $TXTW Text . UndoBindings(1)}
    bind $TXTW <Any-Key> {break}
    bind $TXTW <ButtonRelease-2> {break}
    bind $TXTW <$MODKEY-c> {continue}

    # scroll functions
    bind all <$MODKEY-Left> { ::rsttool::segmenter::next-message {backward}; }
    bind all <$MODKEY-Right> { ::rsttool::segmenter::next-message; }

    # node creation functions
    $TXTW tag bind new <ButtonRelease-1> {
	::rsttool::segmenter::segment
	break;
    }

    $TXTW tag bind next <ButtonRelease-1> {
	::rsttool::segmenter::segment
	break;
    }

    # node modification operations
    $TXTW tag bind bmarker <Control-ButtonPress-1> {
	set ::rsttool::segmenter::SEG_MRK_X %x
	set ::rsttool::segmenter::SEG_MRK_Y %y
	set ::rsttool::TXT_CURSOR [lindex [.editor.text configure -cursor] end]
	$::rsttool::segmenter::TXTW configure -cursor question_arrow
	break
    }

    $TXTW tag bind bmarker <Control-ButtonRelease-1> {
	$::rsttool::segmenter::TXTW configure -cursor $::rsttool::TXT_CURSOR
	::rsttool::segmenter::move $::rsttool::segmenter::TXTW %x %y
	set ::rsttool::segmenter::SEG_MRK_X {}
	set ::rsttool::segmenter::SEG_MRK_Y {}
	break;
    }
}

##################################################################
package provide rsttool::appearance::bindings 0.0.1
return
