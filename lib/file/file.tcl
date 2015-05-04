#!/usr/bin/env wish
# -*- mode: tcl; coding: utf-8; -*-

package require tdom;
package require rsttool::appearance::bindings;

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
	    }
	    "erelscheme" {
		if {[::rsttool::relations::load [$child text]  $prj_dir "external"]} {
		    set error 1; break;
		}
	    }
	    "relscheme" {
		if {[::rsttool::relations::load [$child text] $prj_dir "internal"]} {
		    set error 1; break;
		};
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
	if {[set ret [_read_anno $xmldoc]]} {return $ret}
    }
    set CRNT_ANNO_FILE $ifname;
    return 0;
}

proc ::rsttool::file::_read_anno {a_xmldoc} {
    variable ::rsttool::NODES;
    variable ::rsttool::FORREST;
    variable ::rsttool::NID2MSGID;
    variable ::rsttool::MSGID2TNODES;

    set root [$a_xmldoc documentElement];
    if {[string tolower [$root nodeName]] != "annotation"} {
	error "Wrong format of annotation file.";
	return -1;
    }

    # read segments
    if {[set ret [read-tnode [$root selectNodes segments]]]} {return $ret}
    # set names of terminal nodes
    set imsgid {}; set ilen -1;
    foreach inid [lsort -integer -increasing [array names NID2MSGID]] {
	set imsgid $NID2MSGID($inid);
	set ilen [string length [lindex $FORREST($imsgid) 0]];
	set NODES($inid,name) [lsearch $MSGID2TNODES($imsgid) $inid];
	if {$NODES($inid,start) == 0 && $NODES($inid,end) == $ilen} {
	    set NODES($inid,external) 1;
	    set NODES($inid,etype) {text};
	}
    }

    # read spans
    if {[set ret [read-gnode [$root selectNodes spans]]]} {return $ret}
    # set names of span nodes
    namespace import ::rsttool::treeditor::tree::node::group-node-p;
    namespace import ::rsttool::treeditor::tree::node::egroup-node-p;
    namespace import ::rsttool::treeditor::tree::node::make-name;
    foreach nid [lsort -integer -increasing [array names NID2MSGID]] {
	if {[group-node-p $nid]} {
	    set NODES($nid,name) [make-name $NODES($nid,start) $NODES($nid,end) \
				      [egroup-node-p $nid]];
	}
    }
    # read relations
    if {[set ret [read-relations [$root selectNodes relations]]]} {return $ret}
    # check that each span node got children
    namespace import ::rsttool::treeditor::tree::node::egroup-node-p;
    namespace import ::rsttool::treeditor::tree::node::group-node-p;
    foreach nid [array names NID2MSGID] {
	if {([group-node-p $nid] && $NODES($nid,children) == {}) && \
		(![egroup-node-p $nid] || $NODES($nid,echildren) == {})} {
	    error "read-relations: span node $nid does not contain children.";
	}
    }
    return 0;
}

proc ::rsttool::file::write-node {a_nid a_prnt_elem a_xml_doc {a_type segment}} {
    variable ::rsttool::NODES;
    variable ::rsttool::NID2MSGID;

    set node [$a_xml_doc createElement $a_type];
    $node setAttribute {id} $a_nid;
    $node setAttribute {msgid} $NID2MSGID($a_nid);
    $node setAttribute {start} $NODES($a_nid,start);
    $node setAttribute {end} $NODES($a_nid,end);
    if {$a_type == {segment}} {$node setAttribute {name} $NODES($a_nid,name)}
    $node setAttribute {external} $NODES($a_nid,external);
    $node setAttribute {etype} $NODES($a_nid,etype);
    $a_prnt_elem appendChild $node;
}

proc ::rsttool::file::read-tnode {a_segments} {
    variable ::rsttool::NODES;
    variable ::rsttool::NAME2NID;
    variable ::rsttool::TXT_NODE_CNT;
    namespace import ::rsttool::treeditor::tree::node::insort;

    # puts stderr "read-tnode: a_segments = $a_segments"
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
	if {[set msgid [xml-get-attr $child {msgid}]] == {}} {
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
	}
	::rsttool::treeditor::tree::node::make {text} $start $end "-1" $msgid $nid;
	::rsttool::treeditor::update-roots $msgid $nid {add};

	# update counter of text nodes
	if {$nid > $TXT_NODE_CNT} {set TXT_NODE_CNT $nid;}
    }
    return 0;
}

proc ::rsttool::file::read-gnode {a_spans} {
    variable ::rsttool::NODES;
    variable ::rsttool::NID2MSGID;
    variable ::rsttool::MSGID2ROOTS;
    variable ::rsttool::GROUP_NODE_CNT;
    namespace import ::rsttool::treeditor::tree::node::insort;
    namespace import ::rsttool::treeditor::tree::node::get-start;
    namespace import ::rsttool::treeditor::tree::node::egroup-node-p;

    if {$a_spans == {}} {return 0;}
    set nid {}; set start {}; set end {};
    set external {}; set msgid1 {}; set msgid2 {};
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
	if {[set external [xml-get-attr $child {external}]] == {}} {
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
	    ::rsttool::treeditor::tree::node::make {span} $start $end {} $msgid $nid;
	    if {[catch {set etype [$child getAttribute {etype}]}]} {set etype {}}
	    set NODES($nid,external) $external;
	    set NODES($nid,etype) $etype;
	}
	set NID2MSGID($nid) $msgid;

	if {[info exists MSGID2ROOTS($msgid)]} {
	    ::rsttool::treeditor::update-roots $msgid $nid {add} $NODES($nid,external);
	    if {! $NODES($nid,external) || ![egroup-node-p $nid]} {
		::rsttool::treeditor::update-roots $msgid $nid {add} 0;
	    }
	} else {
	    error "Non-terminal node ($nid) defined for message without terminal nodes ($msgid).";
	}
	if {$nid < $GROUP_NODE_CNT} {set GROUP_NODE_CNT $nid}
    }
    return 0;
}

proc ::rsttool::file::write-relations {a_nid a_relations a_xml_doc} {
    variable ::rsttool::NODES;
    variable ::rsttool::relations::SPAN;
    variable ::rsttool::relations::HYPOTACTIC;
    variable ::rsttool::relations::PARATACTIC;
    variable ::rsttool::file::SAVED_PARNUC;
    namespace import ::rsttool::treeditor::tree::node::get-ancestor;

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
	    set reltype {reltype};
	    if {$NODES($a_nid,external)} {
		set external 1; set chld_prfx "e";
	    } else {
		set external 0; set chld_prfx "";
	    }
	    foreach cid $NODES($a_nid,${chld_prfx}children) {
		if {$NODES($cid,${chld_prfx}reltype) != $HYPOTACTIC} {continue}
		if {$ichild != {}} {
		    set xrel [$xrel cloneNode -deep];
		    [$xrel selectNodes [$ichild nodeName]] delete;
		}
		$xrel setAttribute {relname} $NODES($cid,${chld_prfx}relname);
		set ichild [$a_xml_doc createElement {satellite}];
		if {$NODES($cid,external)} {set cid [get-ancestor $cid]}
		$ichild setAttribute {idref} $cid;
		$xrel appendChild $ichild;
		$a_relations appendChild $xrel;
	    }
	    if {$ichild == {}} {
		error "Invalid data structure for node '$a_nid': span node exists without children.";
		return -1;
	    }
	} \
	$PARATACTIC {
	    set ispan $NODES($a_nid,parent);
	    # remember the span node
	    if {[info exists SAVED_PARNUC($ispan)]} {return;}
	    set SAVED_PARNUC($ispan) 1;
	    set xrel [$a_xml_doc createElement {parRelation}];
	    set irelname $NODES($a_nid,relname);
	    $xrel setAttribute {relname} $irelname;
	    set xspan [$a_xml_doc createElement {spannode}];
	    $xspan setAttribute {idref} $ispan;
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
    variable ::rsttool::relations::SPAN;
    variable ::rsttool::relations::HYPOTACTIC;
    variable ::rsttool::relations::PARATACTIC;
    namespace import ::rsttool::utils::ldelete;
    namespace import ::rsttool::treeditor::tree::node::get-start;
    namespace import ::rsttool::treeditor::tree::node::get-estart;
    namespace import ::rsttool::treeditor::tree::node::egroup-node-p;
    namespace import ::rsttool::treeditor::tree::node::get-eterminal;

    set relname ""; set chld_prfx "";
    set ispan {}; set inuc {}; set isat {};
    set ispan_id {}; set inuc_id {}; set isat_id {};
    foreach irel [$a_relations childNodes] {
	switch -nocase -- [$irel nodeName] {
	    "hyprelation" {
		if {[set relname [xml-get-attr $irel {relname}]] == {}} {
		    return -1;
		}
		if {[set ispan [$irel selectNodes ./spannode]] == {}} {
		    error "No span node specified for hypotactic relation.";
		    return -2;
		}
		set ispan_id [xml-get-attr $ispan {idref}];
		if {[set inuc [$irel selectNodes ./nucleus]] == {}} {
		    error "No nucleus specified for hypotactic relation.";
		    return -3;
		}
		set inuc_id [xml-get-attr $inuc {idref}];
		if {[set isat [$irel selectNodes ./satellite]] == {}} {
		    error "No satellite specified for hypotactic relation.";
		    return -4;
		}
		set isat_id [xml-get-attr $isat {idref}];
		if {$NODES($inuc_id,external) && $NODES($isat_id,external)} {
		    set chld_prfx "e";
		} else {
		    set chld_prfx "";
		}
		# add parent to span's children
		set NODES($ispan_id,${chld_prfx}children) \
		    [insort $NODES($ispan_id,${chld_prfx}children) \
			 [get-${chld_prfx}start $inuc_id] $inuc_id 0 \
			 ::rsttool::treeditor::tree::node::get-${chld_prfx}start];
		# puts stderr "read-relations: NODES($ispan_id,${chld_prfx}children) = $NODES($ispan_id,${chld_prfx}children)"
		# remove child and parent from the list of message roots
		set nuc_msgid $NID2MSGID($inuc_id);
		set sat_msgid $NID2MSGID($isat_id);
		if {$nuc_msgid != $sat_msgid} {
		    # if satellite is not the terminal, get its corresponding terminal
		    if {$NODES($isat_id,etype) != {text}} {set isat_id $NODES($isat_id,start);}
		    # puts stderr "read-relations: ispan_id = $ispan_id";
		    # puts stderr "read-relations: inuc_id = $inuc_id (msgid = $nuc_msgid)";
		    # puts stderr "read-relations: isat_id = $isat_id (msgid = $sat_msgid)";
		    ::rsttool::treeditor::update-roots $nuc_msgid $inuc_id {remove} 1;
		    ::rsttool::treeditor::update-roots $nuc_msgid $isat_id {remove} 1;
		} else {
		    ::rsttool::treeditor::update-roots $nuc_msgid $inuc_id {remove} 0;
		    ::rsttool::treeditor::update-roots $nuc_msgid $isat_id {remove} 0;
		}
		# link parent to span
		set NODES($inuc_id,parent) $ispan_id;
		set NODES($inuc_id,relname) {span};
		set NODES($inuc_id,reltype) $SPAN;
		set NODES($inuc_id,${chld_prfx}children) [insort $NODES($inuc_id,${chld_prfx}children) \
							      [get-${chld_prfx}start $isat_id] $isat_id 0 \
							      ::rsttool::treeditor::tree::node::get-${chld_prfx}start];
		# puts stderr "read-relations: 2) NODES($inuc_id,${chld_prfx}children) = $NODES($inuc_id,${chld_prfx}children)";
		# link child to parent
		set NODES($isat_id,${chld_prfx}parent) $inuc_id;
		set NODES($isat_id,${chld_prfx}relname) $relname;
		set NODES($isat_id,${chld_prfx}reltype) $HYPOTACTIC;
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
		write-node $nid $tnodes $xmldoc {segment};
	    } else {
		write-node $nid $gnodes $xmldoc {span};
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
    }
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
