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

    if {[tk windowingsystem] == "aqua"} {
	$text_w tag bind bmarker <Control-Option-ButtonRelease-2> {
	    delete-node $text_w %x %y
	}
    } else {
	$text_w tag bind bmarker <Control-Alt-ButtonRelease-3> {
	    delete-node $text_w %x %y
	}
    }

    # load/save functions
    bind all <$MODKEY-o> {::rsttool::file::open}
    bind all <$MODKEY-s> {::rsttool::file::save}
    bind all <$MODKEY-q> {::rsttool::quit}

    bindtags $text_w {all $text_w Text . UndoBindings(1)}
    bind $text_w <Any-Key> {break}
    bind $text_w <ButtonRelease-2> {break}
    bind $text_w <$MODKEY-c> {continue}

    # node creation functions
    $text_w tag bind new <ButtonRelease-1> {
	::rsttool::segmenter::segment
	break;
    }

    $text_w tag bind next <ButtonRelease-1> {
	::rsttool::segmenter::segment
	break;
    }

    # node modification operations
    $text_w tag bind bmarker <Control-ButtonPress-1> {
	set ::rsttool::segmenter::SEG_MRK_X %x
	set ::rsttool::segmenter::SEG_MRK_Y %y
	set ::rsttool::TXT_CURSOR [lindex [$text_w configure -cursor] end]
	$text_w configure -cursor question_arrow
	break
    }

    $text_w tag bind bmarker <Control-ButtonRelease-1> {
	$text_w configure -cursor $::rsttool::TXT_CURSOR
	move-node $text_w %x %y
	set ::rsttool::segmenter::SEG_MRK_X {}
	set ::rsttool::segmenter::SEG_MRK_Y {}
	break
    }
}

##################################################################
package provide rsttool::appearance::bindings 0.0.1
return
