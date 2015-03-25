#!/usr/bin/env wish
# -*- mode: tcl; coding: utf-8; -*-

package require rsttool::appearance::bindings;
package require tdom;

##################################################################
namespace eval ::rsttool::file {
    variable HOME $::env(HOME);
    variable FTYPES {{{XML Files} {.xml}}};

    namespace export xml-get-attr;
    namespace export xml-get-text;
}

##################################################################
# add commands to menu
proc ::rsttool::file::update_menu {a_menu} {
    variable ::rsttool::appearance::bindings::MKEY

    $a_menu add command -label [format "Open %s-O" $MKEY] -command \
	{::rsttool::file::open}
    # $a_menu add command -label [format "New %s-N" $MKEY] -command \
    # 	{::rsttool::file::open}
    $a_menu add command -label [format "Save %s-S" $MKEY] -command \
    	{::rsttool::file::save}
    $a_menu add command -label [format "Quit %s-Q" $MKEY] -command \
    	{::rsttool::quit}
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
    ::rsttool::check-state "Open"

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
		# puts -nonewline stderr "NODES = ";
		# parray ::rsttool::NODES;
		# puts stderr "NAME2NID = ";
		# parray ::rsttool::NAME2NID;
		# puts stderr "NID2MSGID = ";
		# parray ::rsttool::NID2MSGID;
		# puts stderr "NID2ENID = ";
		# parray ::rsttool::NID2ENID;
		# puts stderr "MSGID2ROOTS = ";
		# parray ::rsttool::MSGID2ROOTS;
		# puts stderr "MSGID2TNODES = ";
		# parray ::rsttool::MSGID2TNODES;
		# puts stderr "MSGID2ENID = ";
		# parray ::rsttool::MSGID2ENID;
		# puts stderr "TXT_NODE_CNT = $::rsttool::TXT_NODE_CNT"
		# puts stderr "GROUP_NODE_CNT = $::rsttool::GROUP_NODE_CNT"
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
		# puts stderr "THREADS = $::rsttool::THREADS";
		# puts -nonewline stderr "FORREST = ";
		# parray ::rsttool::FORREST;
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
		# puts stderr "RELATIONS = ";
		# parray ::rsttool::relations::RELATIONS;
		# puts stderr "RELHELP = ";
		# parray ::rsttool::helper::RELHELP;
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
    ::rsttool::segmenter::message "Loaded file $CRNT_PRJ_FILE"
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
    if {[set ret [read-tnode [$root selectNodes segments]]]} {
	return $ret;}

    # read spans
    if {[set ret [read-gnode [$root selectNodes spans]]]} {
	return $ret;}

    # read relations
    if {[set ret [read-relations [$root selectNodes relations]]]} {
	return $ret;}

    return 0;
}

proc ::rsttool::file::write-tnode {a_nid a_prnt_elem a_xml_doc} {
    variable ::rsttool::NODES;
    variable ::rsttool::NID2MSGID;

    set node [$a_xml_doc createElement {segment}];
    $node setAttribute {id} $a_nid;
    $node setAttribute {name} $NODES($a_nid,name);
    $node setAttribute {msgid} $NID2MSGID($a_nid);
    $node setAttribute {start} $NODES($a_nid,start);
    $node setAttribute {end} $NODES($a_nid,end);
    $a_prnt_elem appendChild $node;
}

proc ::rsttool::file::read-tnode {a_segments} {
    variable ::rsttool::NODES;
    variable ::rsttool::NAME2NID;
    variable ::rsttool::MSGID2ROOTS;
    variable ::rsttool::MSGID2TNODES;
    variable ::rsttool::NID2MSGID;
    variable ::rsttool::TXT_NODE_CNT;
    namespace import ::rsttool::treeditor::tree::node::insort;

    puts stderr "read-tnode: a_segments = $a_segments"
    if {$a_segments == {}} {return 0;}
    set nid {}; set name {}; set msgid {}; set span {}; set start -1; set end -1;
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
	if {[set msgid [xml-get-attr $child {msgid}]] == {}} {
	    return -4;
	}
	if {[set start [xml-get-attr $child {start}]] == {}} {
	    return -5;
	}
	if {[set end [xml-get-attr $child {end}]] == {}} {
	    return -6;
	}
	# check if this node has not already been defined
	if {[info exists NODES($nid)]} {
	    error "Duplicate node id $nid."
	    return -7;
	} else {
	    if {[info exists NAME2NID($msgid,$name)]} {
		error "Duplicate node name '$name' for message $msgid."
		return -8;
	    }
	    ::rsttool::treeditor::tree::node::make {text} $start $end $name $msgid;
	}

	# update counter of text nodes
	if {$nid > $TXT_NODE_CNT} {
	    set TXT_NODE_CNT $nid
	}
    }
    return 0;
}

proc ::rsttool::file::write-gnode {a_nid a_prnt_elem a_xml_doc} {
    variable ::rsttool::NODES;
    variable ::rsttool::NID2MSGID;

    set node [$a_xml_doc createElement {span}];
    $node setAttribute {id} $a_nid;
    $node setAttribute {type} $NODES($a_nid,type);
    $node setAttribute {start} $NODES($a_nid,start);
    $node setAttribute {end} $NODES($a_nid,end);
    $node setAttribute {msgid} $NID2MSGID($a_nid);
    $a_prnt_elem appendChild $node;
}

proc ::rsttool::file::read-gnode {a_spans} {
    variable ::rsttool::NODES;
    variable ::rsttool::MSGID2ENID;
    variable ::rsttool::MSGID2ROOTS;
    variable ::rsttool::NID2MSGID;
    variable ::rsttool::GROUP_NODE_CNT;
    namespace import ::rsttool::treeditor::tree::node::insort;

    if {$a_spans == {}} {return 0;}
    set nid {}; set start {}; set end {};
    set type {}; set msgid1 {}; set msgid2 {};
    foreach child [$a_spans childNodes] {
	if {[string tolower [$child nodeName]] != "span"} {
	    error "Incorrect file format: expected <span>.";
	    return -1;
	}
	if {[set nid [xml-get-attr $child {id}]] == {}} {
	    return -2;
	}
	if {[set type [xml-get-attr $child {type}]] == {}} {
	    return -3;
	}
	if {[set start [xml-get-attr $child {start}]] == {}} {
	    return -4;
	}
	if {[set end [xml-get-attr $child {end}]] == {}} {
	    return -5;
	}
	if {[set msgid1 [xml-get-attr $child {msgid}]] == {}} {
	    return -6;
	}

	if {[info exists NODES($nid)]} {
	    error "Duplicate node id $nid."
	    return -7;
	} else {
	    set NODES($nid) {};
	    set NODES($nid,type)  $type;
	    set NODES($nid,start) $start;
	    set NODES($nid,end)   $end;
	    set NODES($nid,parent)   {};
	    set NODES($nid,relname)  {};
	    set NODES($nid,children) {};
	}

	if {$type == "external"} {
	    if {[info exists MSGID2ENID($msgid1)]} {
		error "Duplicate external node for message $msgid1."
		return -7;
	    }
	    set MSGID2ENID($msgid1) [list $nid]
	}
	set NID2MSGID($nid) [list $msgid1]

	if {[info exists MSGID2ROOTS($msgid1)]} {
	    set MSGID2ROOTS($msgid1) [insort $MSGID2ROOTS($msgid1) $idx $nid]
	} else {
	    error "Non-terminal node ($nid) defined for message without terminal nodes ($msgid1)."
	}

	if {$nid > $GROUP_NODE_CNT} {
	    set GROUP_NODE_CNT $nid;
	}
    }
    return 0;
}

proc ::rsttool::file::read-relations {a_relations} {
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
    set msg_txt [xml-get-text [$a_msg selectNodes ./text/text()]];
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
	set chname [$child nodeName];
	if {$chname == "#text" || $chname == "text"} {continue;}
	if {[set ret [_read_message $child $msg_id]]} {
	    return $ret;
	}
    }
    return 0;
}

proc ::rsttool::file::save {} {
    variable ::rsttool::NODES;
    variable ::rsttool::NID2MSGID;
    variable ::rsttool::MODIFIED;
    variable ::rsttool::CRNT_ANNO_FILE;
    namespace import ::rsttool::treeditor::tree::node::group-node-p;
    namespace import ::rsttool::treeditor::tree::node::text-node-p;

    # we don't write to the annotation file directly, but instead
    # first generate an XML file, then write it to a temporary
    # location, and if everything succeeds, move this temporary file
    # to the required location

    if {! $MODIFIED} {
	::rsttool::segmenter::message {No changes need to be saved};
	return;
    } else {
	# create XML document
	set xmldoc [dom createDocument annotation]
	set root [$xmldoc documentElement]
	set tnodes [$xmldoc createElement segments]
	set gnodes [$xmldoc createElement spans]
	# save nodes
	foreach nid [array names NID2MSGID] {
	    if {[text-node-p $nid]} {
		write-tnode $nid $tnodes $xmldoc;
	    } else {
		write-gnode $nid $gnodes $xmldoc;
	    }
	}
	$root appendChild $tnodes
	$root appendChild $gnodes

	set relations [$xmldoc createElement relations]
	$root appendChild $relations
	# create temporary file
	set tmpdir [file dirname $CRNT_ANNO_FILE]
	if {![file exists $tmpdir] || ![file isdirectory $tmpdir] || ![file writable $tmpdir]} {
	    error "Cannot write to file in directory $tmpdir";
	    return;
	}
	set tmpfname [file join $tmpdir "[file tail $CRNT_ANNO_FILE].[pid].tmp"]
	if {[catch {set tmpfile [::open $tmpfname w 0644]}]} {
	    error "Could not create temporary file $tmpfname";
	    return;
	}
	if {[catch {puts $tmpfile [$root asXML]}]} {
	    error "Could not write XML document to temporary file $tmpfname";
	    ::close $tmpfile;
	    return;
	}
	::close $tmpfile;
	file rename -force $tmpfname $CRNT_ANNO_FILE;
	::rsttool::set-state {unchanged};
    }
}

proc ::rsttool::file::revert {} {
    variable ::rsttool::MODIFIED;
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

# open file and read XML data
proc ::rsttool::file::load-xml {a_fname} {
    namespace import ::rsttool::utils::htmlentities::decode;

    set ifile [::open $a_fname r];
    set idoc [read $ifile [file size $a_fname]];
    close $ifile;
    return [dom parse [decode $idoc]];
}

# check if given XML element contains requested attribute
proc ::rsttool::file::xml-get-attr {a_elem a_attr} {
    if {[set ret [$a_elem getAttribute $a_attr]] == {}} {
	error "Element [$a_elem nodeName] does not have attribute '$a_attr'.";
    };
    return $ret;
}

# check if given XML element exists and return its text
proc ::rsttool::file::xml-get-text {a_elem} {
    namespace import ::rsttool::utils::strip;

    if {$a_elem != {}} {
	return [strip [$a_elem nodeValue]];
    }
    return {};
}

##################################################################
package provide rsttool::file 0.0.1
return
