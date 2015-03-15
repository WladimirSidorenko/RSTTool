#!/usr/bin/env wish
# -*- mode: tcl; coding: utf-8; -*-

package require rsttool::appearance::bindings;
package require tdom;

##################################################################
namespace eval ::rsttool::file {
    variable HOME $::env(HOME);
    variable FTYPES {{{XML Files} {.xml}}};

    namespace export xml-get-attr;
}

##################################################################
# add commands to menu
proc ::rsttool::file::update_menu {a_menu} {
    variable ::rsttool::appearance::bindings::MKEY

    $a_menu add command -label [format "Open %s-O" $MKEY] -command \
	{::rsttool::file::open}
    # $a_menu add command -label [format "New %s-N" $MKEY] -command \
    # 	{::rsttool::file::open}
    # $a_menu add command -label [format "Save %s-S" $MKEY] -command \
    # 	{::rsttool::file::save}
    # $a_menu add command -label [format "Quit %s-Q" $MKEY] -command \
    # 	{::rsttool::quit}
    # $a_menu add command -label "Clear" -command {::rsttool::clear}
}

proc ::rsttool::file::new {} {

}

proc ::rsttool::file::open {} {
    variable HOME;
    variable FTYPES;
    variable ::rsttool::CRNT_PRJ_FILE;
    variable ::rsttool::CRNT_ANNO_FILE;
    variable ::rsttool::CRNT_BASE_FILE;
    variable ::rsttool::relations::RELATIONS;
    variable ::rsttool::relations::ERELATIONS;

    # clear current data
    ::rsttool::check_state "Open"

    # set up initial directory
    set idir $HOME;
    if {$CRNT_PRJ_FILE != {}} {
	set idir [file dirname $CRNT_PRJ_FILE];
    }

    # select anbd read file
    set fname [tk_getOpenFile -filetypes $FTYPES -initialdir $idir -parent . \
		   -title {Select File}];
    if {$fname == {}} {return;}
    ::rsttool::reset

    # process XML
    set xmldoc [load-xml $fname]
    set root [$xmldoc documentElement]
    if {[string tolower [$root nodeName]] != "rstprj"} {
	error "Unknown format of project file.";
	return;
    }

    set CRNT_PRJ_FILE $fname;
    set prj_dir [file dirname $CRNT_PRJ_FILE];

    set error 0;
    foreach child [$root childNodes] {
	switch -nocase -- [$child nodeName] {
	    "annotation" {
		if {[_open_anno [$child text] $prj_dir]} {
		    set error 1; break;
		}
		puts -nonewline stderr "NODES = ";
		parray ::rsttool::NODES;
		puts stderr "NAME2NID = ";
		parray ::rsttool::NAME2NID;
		puts stderr "NID2MSGID = ";
		parray ::rsttool::NID2MSGID;
		puts stderr "NID2ENID = ";
		parray ::rsttool::NID2ENID;
		puts stderr "MSGID2NID = ";
		parray ::rsttool::MSGID2NID;
		puts stderr "MSGID2ENID = ";
		parray ::rsttool::MSGID2ENID;
		puts stderr "TXT_NODE_CNT = $::rsttool::TXT_NODE_CNT"
		puts stderr "GROUP_NODE_CNT = $::rsttool::GROUP_NODE_CNT"
	    }
	    "abbreviations" {
		if {[abbreviations::load [$child text] $prj_dir]} {
		    set error 1; break;
		};
	    }
	    "basedata" {
		if {[_open_base [$child text] $prj_dir]} {
		    set error 1; break;
		}
		puts stderr "THREADS = $::rsttool::THREADS";
		puts -nonewline stderr "FORREST = ";
		parray ::rsttool::FORREST;
	    }
	    "erelscheme" {
		if {[::rsttool::relations::load [$child text]  $prj_dir "external"]} {
		    set error 1; break;
		}
		puts stderr "ERELATIONS = ";
		parray ::rsttool::relations::ERELATIONS;
	    }
	    "relscheme" {
		if {[::rsttool::relations::load [$child text] $prj_dir "internal"]} {
		    set error 1; break;
		};
		puts stderr "RELATIONS = ";
		parray ::rsttool::relations::RELATIONS;
	    }
	    "#comment" {
		continue;
	    }
	    default {
		error "Unknown element '[$child nodeName]'.";
		set error 1; break;
	    }
	}
    }
    if {$error} {
	::rsttool::reset;
	return;
    }

    if {$CRNT_ANNO_FILE == {}} {
	error "No annotation file specified for the project.";
	::rsttool::reset;
	return;
    }

    if {$CRNT_BASE_FILE == {}} {
	error "No source file specified for the project.";
	::rsttool::reset;
	return;
    }

    if {[array names RELATIONS] == {} && [array names ERELATIONS] == {}} {
	error "No relation scheme specified for the project.";
	::rsttool::reset;
	return;
    }

    ::rsttool::segmenter::next-message
}

proc ::rsttool::file::_open_anno {a_fname {a_dirname {}}} {
    variable ::rsttool::CRNT_ANNO_FILE;

    puts stderr "_open_anno: a_fname = $a_fname"
    set ifname [search $a_fname $a_dirname];
    # if file does not exist, create an empty one
    if {$ifname == {}} {
	set ifname [file join $a_dirname $a_fname];
	file mkdir [file dirname $ifname];
	set ifile [::open $ifname w 0644];
	# put minimal XML into the newly created file
	puts $ifile {<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE annotation SYSTEM "annotation.dtd">

<annotation>
<segments></segments>
<spans></spans>
<relations></relations>
</annotation>
	}
	close $ifile;
    } else {
	set xmldoc [load-xml $ifname];
	if {[set ret [_read_anno $xmldoc]]} {
	    return $ret;
	}
    }
    puts stderr "_open_anno: ifname = $ifname"
    set CRNT_ANNO_FILE $ifname;
    return 0;
}

proc ::rsttool::file::_read_anno {a_xmldoc} {
    set root [$a_xmldoc documentElement];
    if {[string tolower [$root nodeName]] != "annotation"} {
	error "Wrong format of annotation file.";
	return -1;
    }

    # read segments
    if {[set ret [_read_segments [$root selectNodes /segments]]]} {
	return $ret;}

    # read spans
    if {[set ret [_read_spans [$root selectNodes /spans]]]} {
	return $ret;}

    # read relations
    if {[set ret [_read_relations [$root selectNodes /relations]]]} {
	return $ret;}

    return 0;
}

proc ::rsttool::file::_read_segments {a_segments} {
    variable ::rsttool::NODES;
    variable ::rsttool::NAME2NID;
    variable ::rsttool::MSGID2NID;
    variable ::rsttool::NID2MSGID;
    variable ::rsttool::TXT_NODE_CNT;
    namespace import ::rsttool::treeditor::tree::node::get-ins-index;

    if {$a_segments == {}} {return 0;}
    set nid {}; set name {}; set msgid {}; set start -1; set end -1;
    foreach child [$a_segments childNodes] {
	if {[string tolower [$child nodeName]] != "segment"} {
	    error "Incorrect file format: expected <segment>.";
	    return -1;
	}
	if {[set nid [xml-get-attr $child {id}]] == {}} {
	    return -2;
	}
	if {[set name [xml-get-attr $child {name}]] == {}} {
	    return -3;
	}
	if {[set start [xml-get-attr $child {start}]] == {}} {
	    return -4;
	}
	if {[set end [xml-get-attr $child {end}]] == {}} {
	    return -5;
	}
	# check if this node has not already been defined
	if {[info exists NODES($nid)]} {
	    error "Duplicate node id $nid."
	    return -6;
	} else {
	    set NODES($nid) {};
	    set NODES($nid,type)  {text};
	    set NODES($nid,name)  $name;
	    set NODES($nid,start) $start;
	    set NODES($nid,end)   $end;
	    set NODES($nid,parent)   {};
	    set NODES($nid,relname)  {};
	    set NODES($nid,children) {};
	}
	if {[info exists NAME2NID($msgid,$nid)]} {
	    error "Duplicate node name '$name'."
	    return -7;
	} else {
	    set NAME2NID($msgid,$nid) $name
	}
	# update counter of text nodes
	if {$nid > $TXT_NODE_CNT} {
	    set TXT_NODE_CNT $nid
	}
	# update dictionaries
	if {[info exists MSGID2NID($nid)]} {
	    set idx [get-ins-index $MSGID2NID($msgid) $start]
	    set MSGID2NID($msgid) [linsert $MSGID2NID($msgid) $idx $nid]
	} else {
	    set MSGID2NID($msgid) [list $nid]
	}
	set NID2MSGID($nid) $msgid
    }
    return 0;
}

proc ::rsttool::file::_read_spans {a_spans} {
    variable ::rsttool::NODES;
    variable ::rsttool::MSGID2NID;
    variable ::rsttool::MSGID2ENID;
    variable ::rsttool::NID2MSGID;
    variable ::rsttool::GROUP_NODE_CNT;

    if {$a_spans == {}} {return 0;}
    set nid {}; set name {}; set type {}; set msgid1 {}; set msgid2 {};
    foreach child [$a_spans childNodes] {
	if {[string tolower [$child nodeName]] != "span"} {
	    error "Incorrect file format: expected <span>.";
	    return -1;
	}
	if {[set nid [xml-get-attr $child {id}]] == {}} {
	    return -2;
	}
	if {[set name [xml-get-attr $child {name}]] == {}} {
	    return -3;
	}
	if {[set type [xml-get-attr $child {type}]] == {}} {
	    return -4;
	}
	if {[set msgid1 [xml-get-attr $child {msgid1}]] == {}} {
	    return -5;
	}

	if {[info exists NODES($nid)]} {
	    error "Duplicate node id $nid."
	    return -8;
	} else {
	    set NODES($nid) {};
	    set NODES($nid,type)  {span};
	    set NODES($nid,name)  $name;
	    set NODES($nid,parent)   {};
	    set NODES($nid,relname)  {};
	    set NODES($nid,children) {};
	}

	if {$type == "external"} {
	    if {[set msgid2 [xml-get-attr $child {msgid2}]] == {}} {
		return -6;
	    }
	    if {[info exists MSGID2ENID($msgid1,$msgid2)]} {
		lappend MSGID2ENID($msgid1,$msgid2) $nid
	    } else {
		set MSGID2ENID($msgid1,$msgid2) [list $nid]
	    }
	    set NID2MSGID($nid) [list $msgid1  $msgid2]
	} else {
	    set NID2MSGID($nid) [list $msgid1]
	}

	if {[info exists MSGID2NID($nid)]} {
	    set idx [get-ins-index $MSGID2NID($msgid) $start]
	    set MSGID2NID($msgid) [linsert $MSGID2NID($msgid) $idx $nid]
	} else {
	    set MSGID2NID($msgid) [list $nid]
	}

	if {$nid > $GROUP_NODE_CNT} {
	    set GROUP_NODE_CNT $nid;
	}
    }
    return 0;
}

proc ::rsttool::file::_read_relations {a_relations} {
    variable ::rsttool::NODES;
    variable ::rsttool::NID2ENID;
    if {$a_relations == {}} {return 0;}

    foreach irel [$a_relations childNodes] {
	switch -nocase -- [$child nodeName] {
	    "parrelation" {
		;
	    }
	    "hyprelation" {
		;
	    }
	    default {
		error "Unrecognized element [$child nodeName]";
		return -1;
	    }
	}
    }
    return 0;
}

proc ::rsttool::file::_open_base {a_fname {a_dirname {}}} {
    variable ::rsttool::THREADS;
    variable ::rsttool::CRNT_BASE_FILE;

    set ifname [search $a_fname $a_dirname];
    if {$ifname == {}} {
	error "File '$a_fname' not found.";
	return;
    }

    # process XML
    set xmldoc [load-xml $ifname]
    set root [$xmldoc documentElement]
    if {[string tolower [$root nodeName]] != "basedata"} {
	error "Unknown format of basedata file.";
	return -1;
    }

    set root_id {};
    set thread_id {};
    foreach ithread [$root selectNodes //thread] {
	set thread_id [$ithread getAttribute id];
	set root [$ithread firstChild];
	if {$root == {}} {continue;}

	if {[string tolower [$root nodeName]] != "msg"} {
	    error "Incorrect file format: expected <msg>.";
	    return -2;
	}

	if {[set root_id [xml-get-attr $root {id}]] == {}} {
	    return -3;
	}

	lappend THREADS $root_id;
	if {[_read_message $root]} {
	    error "Error while reading messages of thread $thread_id.";
	    return -4;
	}
    }

    set CRNT_BASE_FILE $ifname;
    return 0;
}

proc ::rsttool::file::_read_message {a_msg {a_prnt_id {}}} {
    variable ::rsttool::FORREST;

    if {[string tolower [$a_msg nodeName]] != "msg"} {
	error "Incorrect file format: expected <msg> got [$a_msg nodeName].";
	return -1;
    }
    set msg_id [$a_msg getAttribute {id}];
    # check if message is unique
    if {[info exists FORREST($msg_id)]} {
	error "Duplicate message id '$msg_id'.";
	return -2;
    }
    # add this message to the FORREST as a 3-tuple of message
    # text, id of its parent, and list of its children
    set msg_txt [::rsttool::utils::strip [$a_msg text]];
    set FORREST($msg_id) [list $msg_txt $a_prnt_id {}]
    # update parent's child list
    if {$a_prnt_id != {}} {
	if {![info exists FORREST($a_prnt_id)]} {
	    error "Message with id '$a_prnt_id' not found.";
	    return -3;
	}
	lset FORREST($a_prnt_id) end [concat [lindex $FORREST($a_prnt_id) end] [list $msg_id]];
    }
    # recurse int children
    foreach child [$a_msg childNodes] {
	if {[$child nodeName] == "#text"} {continue;}
	if {[set ret [_read_message $child $msg_id]]} {
	    return $ret;
	}
    }
    return 0;
}

proc ::rsttool::file::save {} {
    variable ::rsttool::MODIFIED;

    if {! $MODIFIED} {
	::rsttool::segmenter::message {No changes need to be saved};
	return;
    }
}

proc ::rsttool::file::revert {} {
    variable ::rsttool::MODIFIED;
}

# check if given XML element contains requested attribute
proc ::rsttool::file::xml-get-attr {a_elem a_attr} {
    if {[set ret [$a_elem getAttribute $a_attr]] == {}} {
	error "Element [$a_elem nodeName] does not have attribute '$a_attr'.";
    };
    return $ret;
}

# open file and read XML data
proc ::rsttool::file::load-xml {a_fname} {
    set ifile [::open $a_fname r];
    set idoc [read $ifile [file size $a_fname]];
    close $ifile;
    return [dom parse $idoc];
}

# look for file in relative and absolute location and return first
# file found
proc ::rsttool::file::search {a_fname a_dirname} {
    set fname {};
    foreach ifname [list [file join $a_dirname $a_fname] $a_fname] {
	if {[file exists $ifname] && [file isfile $ifname]} {
	    set fname $ifname;
	    break;
	}
    }
    return [file normalize $fname];
}

##################################################################
package provide rsttool::file 0.0.1
return
