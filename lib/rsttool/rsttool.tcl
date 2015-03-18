#!/usr/bin/env wish

######################################
# Packages
package require rsttool::appearance
package require rsttool::file
package require rsttool::helper
package require rsttool::print
package require rsttool::relations
package require rsttool::segmenter
package require rsttool::toolbar
package require rsttool::treeditor

######################################
# Variables
namespace eval ::rsttool {
    variable VERSION 0.0.1
    variable PLATFORM $::tcl_platform(platform)

    variable X1 {};
    variable X2 {};
    variable TXT_CURSOR xterm;

    variable TOPLEVELS;
    array set TOPLEVELS {};

    variable CRNT_PRJ_FILE {};
    variable CRNT_BASE_FILE {};
    variable CRNT_ANNO_FILE {};

    variable MODIFIED 0;
    variable TOTAL 0;
    variable ANNOTATED 0;

    variable THREADS {};
    variable THREAD_ID -1;

    variable CRNT_MSGID {};
    variable PRNT_MSGID {};
    variable PRNT_MSGTXT {};
    variable MSG_QUEUE {};
    variable MSG_PREV_QUEUE {};

    variable FORREST;
    array set FORREST {};
    variable NODES;
    array set NODES {};
    variable ROOTS;
    array set ROOTS {};
    variable TXT_NODE_CNT -1;
    variable GROUP_NODE_CNT -1;

    variable NID2MSGID;
    array set NID2MSGID {};
    variable NID2ENID;
    array set NID2ENID {};
    variable NAME2NID;
    array set NAME2NID {};
    variable MSGID2ENID;
    array set MSGID2ENID {};
    variable MSGID2NID;
    array set MSGID2NID {};
}

######################################
# Methods
######################################
# Methods
proc ::rsttool::check_state {{a_msg {Proceed}}} {
    variable MODIFIED;

    if {$MODIFIED} {
	set save [tk_dialog .check_state [format "%s" $a_msg] \
		      [format "Modified buffer exists.  %s anyway?" $a_msg] \
		      warning 0 [format "Save and %s" $a_msg] \
		      [format "%s" $a_msg] {Cancel}]
	if {$save == 0} {
	    file::save;
	    set MODIFIED 0;
	} else if {$save == 2} {
	    return 1;
	}
    }
    return 0;
}

proc ::rsttool::reset {} {
    variable CRNT_PRJ_FILE;
    variable CRNT_ANNO_FILE; variable CRNT_BASE_FILE;

    variable X1; variable X2;
    variable TOTAL; variable ANNOTATED;

    variable CRNT_MSGID; variable PRNT_MSGID; variable PRNT_MSGTXT;

    variable MSG_QUEUE; variable MSG_PREV_QUEUE;
    variable THREADS; variable THREAD_ID;

    variable GROUP_NODE_CNT; variable TXT_NODE_CNT;


    if {$CRNT_PRJ_FILE == {}} {return;}
    if {[check_state "Reset"]} {return;}

    # reset variables
    set CRNT_ANNO_FILE {};
    set CRNT_BASE_FILE {};
    set CRNT_PRJ_FILE {};
    set CRNT_MSGID {};
    set GROUP_NODE_CNT -1;
    set MSG_QUEUE {}; set MSG_PREV_QUEUE {};
    set PRNT_MSGID {};
    set PRNT_MSGTXT {};
    set THREADS {};
    set THREAD_ID -1;
    set TOTAL 0; set ANNOTATED 0;
    set TXT_NODE_CNT -1;
    set X1 {}; set X2 {};

    utils::reset-array ::rsttool::FORREST;
    utils::reset-array ::rsttool::MSGID2ENID;
    utils::reset-array ::rsttool::MSGID2NID;
    utils::reset-array ::rsttool::NAME2NID;
    utils::reset-array ::rsttool::NID2ENID;
    utils::reset-array ::rsttool::NID2MSGID;
    utils::reset-array ::rsttool::NODES;
    utils::reset-array ::rsttool::ROOTS;
    utils::reset-array ::rsttool::TEXT_NODES;
    utils::reset-array ::rsttool::treeditor::VISIBLE_NODES;

    abbreviations::reset;
    relations::reset;

    # remove text from segmenter
    .editor.text delete 0.0 end
    .editor.textPrnt delete 0.0 end
}

proc ::rsttool::quit {} {
    if {[check_state "Exit"]} {return;}
    exit 0
}

proc ::rsttool::main {{argv {}}} {
    # relations::load PCC.rel R-PCC.rel
    # abbreviations::load abbreviations
    # helper::load

    wm title . "RST-Tool"
    wm protocol . WM_DELETE_WINDOW ::rsttool::quit
    frame .segmentframe

    toolbar::install
    treeditor::install
    segmenter::install

    # helper::init
    appearance::set_default
    appearance::bindings::set_default

    catch {source $env(HOME)/.wishrc}
}

##################################################################
package provide rsttool $::rsttool::VERSION
return
