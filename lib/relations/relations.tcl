#!/usr/bin/env wish

namespace eval ::rsttool::relations {
    variable DATADIR [file join [pwd] data];
    variable RELATIONS;
    array set RELATIONS {};
    variable TYPE2REL;
    array set TYPE2REL {};
    variable ERELATIONS;
    array set ERELATIONS {};
    variable TYPE2EREL;
    array set TYPE2EREL {};
}

##################################################################
# load relation description
proc ::rsttool::relations::reset {} {
    namespace import ::rsttool::utils::reset-array;

    reset-array ::rsttool::relations::ERELATIONS;
    reset-array ::rsttool::relations::RELATIONS;
    reset-array ::rsttool::relations::TYPE2REL;
    reset-array ::rsttool::relations::TYPE2EREL;
}

proc ::rsttool::relations::load {a_fname {a_dirname {}} {type "internal"}} {
    variable DATADIR;
    variable ::rsttool::helper::RELHELP;
    namespace import ::rsttool::file::xml-get-attr;

    # find relation file
    if {[set ifname [::rsttool::file::search $a_fname $a_dirname]] == {}} {
	if {[file exists [file join $DATADIR $a_fname]]} {
	    set ifname [file join $DATADIR $a_fname];
	} else {
	    error "Relation file '$a_fname' not found."
	    return -1;
	}
    };

    # read and process XML
    set xmldoc [::rsttool::file::load-xml $ifname];
    set root [$xmldoc documentElement]
    if {[string tolower [$root nodeName]] != "relations"} {
	error "Unknown relation file format: expected <relations> as root element.";
	return -2;
    }

    # obtain target array
    set relarr {};
    set type2rel {};
    switch -- $type {
	"internal" {
	    set relarr ::rsttool::relations::RELATIONS;
	    set type2rel ::rsttool::relations::TYPE2REL;
	}
	"external" {
	    set relarr ::rsttool::relations::ERELATIONS;
	    set type2rel ::rsttool::relations::TYPE2EREL;
	}
	default {
	    error "Unrecognized relation type '$type'.";
	    return -3;
	}
    }
    # populate set of relations
    set relname {}; set reltype {}; set help {}; set elname {};
    foreach ichild [$root childNodes] {
	set elname [string tolower [$ichild nodeName]];
	if {$elname == "#comment"} {continue;}
	if {$elname != "relation"} {
	    error "Incorrect format of relation file: expected <relation>.";
	    return -4;
	}
	if {[set relname [xml-get-attr $ichild {name}]] == {}} {
	    return -5;
	}
	if {[set reltype [xml-get-attr $ichild {type}]] == {}} {
	    return -6;
	}
	if {[info exists [subst $relarr]($relname)]} {
	    error "Duplicate definition of relation $relname"
	    return -7;
	} else {
	    set [subst $relarr]($relname) $reltype;
	    lappend [subst $type2rel]($reltype) $relname;

	    # set help for that relation
	    set RELHELP($relname,description) [$ichild selectNodes description]
	    set RELHELP($relname,nucleus) [$ichild selectNodes nucleus]
	    set RELHELP($relname,satellite) [$ichild selectNodes satellite]
	    set RELHELP($relname,nucsat) [$ichild selectNodes nucsat]
	    set RELHELP($relname,effect) [$ichild selectNodes effect]
	    set RELHELP($relname,connectives) [$ichild selectNodes connectives]
	    set RELHELP($relname,example) [$ichild selectNodes example]
	    set RELHELP($relname,comment) [$ichild selectNodes comment]
	}
    }
    return 0;
}

##################################################################
package provide rsttool::relations 0.0.1
return
