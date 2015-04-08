#!/usr/bin/env wish
# -*- mode: tcl; coding: utf-8; -*-

package require rsttool::appearance::bindings;
package require tdom;

##################################################################
namespace eval ::rsttool::file {
    variable HOME $::env(HOME);
    variable FTYPES {{{XML Files} {.xml}}};
    variable SAVED_PARNUC;
    array set SAVED_PARNUC {};

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
	    ::rsttool::treeditor::tree::node::make {text} $start $end $name $msgid $nid;
	    ::rsttool::treeditor::update-roots $msgid $nid {add};
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
    namespace import ::rsttool::treeditor::tree::node::get-start;

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
	if {$nid > 0} {
	    error "Invalid node id for abstract node: $nid (should be < 0)";
	    return;
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
	if {[set msgid [xml-get-attr $child {msgid}]] == {}} {
	    return -6;
	}

	if {[info exists NODES($nid)]} {
	    error "Duplicate node id $nid."
	    return -7;
	} else {
	    ::rsttool::treeditor::tree::node::make $type $start $end {} $msgid $nid;
	}

	if {$type == "external"} {
	    if {[info exists MSGID2ENID($msgid)]} {
		error "Duplicate external node for message $msgid."
		return -7;
	    }
	    set MSGID2ENID($msgid) [list $nid]
	}
	set NID2MSGID($nid) [list $msgid]

	if {[info exists MSGID2ROOTS($msgid)]} {
	    ::rsttool::treeditor::update-roots $msgid $nid {add}
	} else {
	    error "Non-terminal node ($nid) defined for message without terminal nodes ($msgid)."
	}

	if {$nid < $GROUP_NODE_CNT} {
	    set GROUP_NODE_CNT $nid;
	}
    }
    return 0;
}
proc ::rsttool::file::write-relations {a_nid a_relations a_xml_doc} {
    variable ::rsttool::NODES;
    variable ::rsttool::relations::SPAN;
    variable ::rsttool::relations::HYPOTACTIC;
    variable ::rsttool::relations::PARATACTIC;
    variable ::rsttool::file::SAVED_PARNUC;

    if {![info exists NODES($a_nid,reltype)]} {return;}

    switch -nocase -- $NODES($a_nid,reltype) \
	$SPAN {
	    set xrel [$a_xml_doc createElement {hypRelation}];
	    set ispan [$a_xml_doc createElement {spannode}];
	    $ispan setAttribute {idref} $NODES($a_nid,parent);
	    $xrel appendChild $ispan;
	    set inuc [$a_xml_doc createElement {nucleus}];
	    $inuc setAttribute {idref} $a_nid;
	    $xrel appendChild $inuc;
	    set ichild {};
	    foreach cid $NODES($a_nid,children) {
		if {$NODES($cid,reltype) != $HYPOTACTIC} {continue;}
		if {$ichild != {}} {
		    set xrel [$xrel cloneNode -deep];
		    [$xrel selectNodes [$ichild nodeName]] delete;
		}
		$xrel setAttribute {relname} $NODES($cid,relname);
		set ichild [$a_xml_doc createElement {satellite}];
		$ichild setAttribute {idref} $cid;
		$xrel appendChild $ichild;
		$a_relations appendChild $xrel;
	    }
	    if {$ichild == {}} {
		error "Invalid data structure for node '$NODES($a_nid,name)': span node exists without children.";
		return -1;
	    }
	} \
	$PARATACTIC {
	    set ispan $NODES($a_nid,parent);
	    # remember the span node
	    if {[info exists SAVED_PARNUC($ispan)]} {return;}
	    set SAVED_PARNUC($ispan) 1;
	    set xspan [$a_xml_doc createElement {spannode}];
	    $xspan setAttribute {idref} $ispan;
	    set xrel [$a_xml_doc createElement {parRelation}];
	    set irelname $NODES($a_nid,relname);
	    $xrel setAttribute {relname} $irelname;
	    $xrel appendChild $xspan;
	    # append nuclei of the span to the XML relation
	    set nuc_cnt 0;
	    foreach inuc $NODES($ispan,children) {
		if {$NODES($inuc,reltype) != $PARATACTIC} {continue;}
		if {$NODES($inuc,relname) != $irelname} {
		    error "Invalid data structure: different paratactic relations link to the same span ($ispan).";
		    return -2;
		}
		set xnuc [$a_xml_doc createElement {nucleus}];
		$xnuc setAttribute {idref} $inuc;
		$xrel appendChild $xnuc;
		incr nuc_cnt;
	    }
	    if {$nuc_cnt < 2} {
		error "Invalid data structure: multinuclear relations has less than two nuclei ($ispan).";
		return -3;
	    }
	    $a_relations appendChild $xrel;
	} \
	default {
	    return 0;
	}
    return 0;
}

proc ::rsttool::file::read-relations {a_relations} {
    variable ::rsttool::NODES;
    variable ::rsttool::NID2MSGID;
    variable ::rsttool::MSGID2ROOTS;
    variable ::rsttool::relations::SPAN;
    variable ::rsttool::relations::HYPOTACTIC;
    variable ::rsttool::relations::PARATACTIC;
    namespace import ::rsttool::utils::ldelete;
    namespace import ::rsttool::treeditor::tree::node::get-start;

    set relname "";
    set ispan {}; set inuc {}; set isat {};
    set ispan_id {}; set inuc_id {}; set isat_id {};
    foreach irel [$a_relations childNodes] {
	switch -nocase -- [$irel nodeName] {
	    "hyprelation" {
		if {[set relname [xml-get-attr $irel {relname}]] == {}} {
		    return -1;
		}
		if {[set ispan [$irel selectNodes ./spannode]] == {}} {
		    error "No span node specified for hypotactic relation."
		    return -2;
		};
		set ispan_id [xml-get-attr $ispan {idref}];
		if {[set inuc [$irel selectNodes ./nucleus]] == {}} {
		    error "No nucleus specified for hypotactic relation."
		    return -3;
		};
		set inuc_id [xml-get-attr $inuc {idref}];
		if {[set isat [$irel selectNodes ./satellite]] == {}} {
		    error "No satellite specified for hypotactic relation."
		    return -4;
		};
		set isat_id [xml-get-attr $isat {idref}];
		# add parent to span's children
		set NODES($ispan_id,children) [insort $NODES($ispan_id,children) \
						   [get-start $inuc_id] $inuc_id];
		# link parent to span
		set NODES($inuc_id,parent) $ispan_id;
		set NODES($inuc_id,relname) {span};
		set NODES($inuc_id,reltype) $SPAN;
		set NODES($inuc_id,children) [insort $NODES($inuc_id,children) \
						   [get-start $isat_id] $isat_id];
		# link child to parent
		lappend NODES($isat_id,parent) $inuc_id;
		set NODES($isat_id,relname) $relname;
		set NODES($isat_id,reltype) $HYPOTACTIC;
		# remove child and parent from the list of message roots
		set nuc_msgid $NID2MSGID($inuc_id);
		set sat_msgid $NID2MSGID($isat_id);
		if {$nuc_msgid != $sat_msgid} {
		    ::rsttool::treeditor::update-roots $nuc_msgid $inuc_id {remove} 1;
		    ::rsttool::treeditor::update-roots $nuc_msgid $isat_id {remove} 1;
		} else {
		    ::rsttool::treeditor::update-roots $nuc_msgid $inuc_id {remove} 0;
		    ::rsttool::treeditor::update-roots $nuc_msgid $isat_id {remove} 0;
		    puts stderr "read-relations: MSGID2ROOTS($nuc_msgid) = $MSGID2ROOTS($nuc_msgid)";
		}
	    }
	    "parrelation" {
		if {[set relname [xml-get-attr $irel {relname}]] == {}} {
		    return -1;
		}
		if {[set ispan [$irel selectNodes ./spannode]] == {}} {
		    error "No span node specified for paratactic relation.";
		    return -2;
		}
		set ispan_id [xml-get-attr $ispan {idref}];
		set ispan_msgid $NID2MSGID($ispan_id);
		set nuc_cnt 0;
		set inuc_id {}; set inuc_msgid {};
		# iterate over nuclei of that paratactic relation
		foreach inuc [$irel selectNodes ./nucleus] {
		    if {[set inuc_id [xml-get-attr $inuc {idref}]] == {}} {
			error "No node id specified for nucleus."
			return -3;
		    }
		    # update parent of the nucleus and add it to span's children
		    set NODES($inuc_id,parent) $ispan_id;
		    set NODES($inuc_id,relname) $relname;
		    set NODES($inuc_id,reltype) $PARATACTIC;
		    set NODES($ispan_id,children) [insort $NODES($ispan_id,children) \
						       [get-start $inuc_id] $inuc_id];
		    incr nuc_cnt;
		    set inuc_msgid $NID2MSGID($inuc_id);
		    ::rsttool::treeditor::update-roots $inuc_msgid $inuc_id {remove};
		}
		if {$nuc_cnt < 2} {
		    error "Invalid number of nuclei for paratactic relation: $nuc_cnt."
		    return -6;
		}
		# remove child and parent from the list of message roots
		set inuc_msgid $NID2MSGID($inuc_id);
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
    # recurse into children
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
    variable ::rsttool::file::SAVED_PARNUC;

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
	set xmldoc [dom createDocument annotation];
	set root [$xmldoc documentElement];
	set tnodes [$xmldoc createElement segments];
	set gnodes [$xmldoc createElement spans];
	set relations [$xmldoc createElement relations];
	# save nodes
	foreach nid [array names NID2MSGID] {
	    if {[text-node-p $nid]} {
		write-tnode $nid $tnodes $xmldoc;
	    } else {
		write-gnode $nid $gnodes $xmldoc;
	    }
	    write-relations $nid $relations $xmldoc;
	}
	# reset array of PARATACTIC nuclei
	array unset SAVED_PARNUC;
	array set SAVED_PARNUC {};
	$root appendChild $tnodes
	$root appendChild $gnodes
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
	    file delete -force -- $tmpfname;
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
