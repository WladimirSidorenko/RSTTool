#!/usr/bin/env wish

namespace eval ::rsttool::relations {
    variable DATADIR [file join [pwd] data];

    variable INTERNAL {internal};
    variable EXTERNAL {external};
    variable HYPOTACTIC {hyp};
    variable PARATACTIC {par};

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
    variable INTERNAL;
    variable EXTERNAL;
    variable HYPOTACTIC;
    variable PARATACTIC;

    variable ::rsttool::helper::RELHELP;
    namespace import ::rsttool::file::xml-get-attr;
    namespace import ::rsttool::file::xml-get-text;

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
    switch -nocase -- "$type" \
	$INTERNAL {
	    set relarr ::rsttool::relations::RELATIONS;
	    set type2rel ::rsttool::relations::TYPE2REL;
	} \
	$EXTERNAL {
	    set relarr ::rsttool::relations::ERELATIONS;
	    set type2rel ::rsttool::relations::TYPE2EREL;
	} \
	default {
	    error "Unrecognized relation type '$type'.";
	    return -3;
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
	switch -- [set reltype [xml-get-attr $ichild {type}]] \
	    $PARATACTIC - \
	    $HYPOTACTIC {;} \
	    {} {
		error "Dependency type not specified for relation '$relname'."
		return -6;
	    } \
	    default {
		error "Invalid dependency type for relation '$relname' should be\
 '$PARATACTIC' or '$HYPOTACTIC'."
		return -6;
	    }

	if {[info exists [subst $relarr]($relname)]} {
	    error "Duplicate definition of relation $relname"
	    return -7;
	} else {
	    set [subst $relarr]($relname) $reltype;
	    lappend [subst $type2rel]($reltype) $relname;

	    puts stderr "ichild name = $elname"
	    puts stderr "ichild selectNodes description = [$ichild selectNodes .//connectives]"
	    if {[$ichild selectNodes .//description] != {}} {
		puts stderr "ichild selectNodes description text = [[$ichild selectNodes ./connectives/text()] nodeValue]"
	    }

	    # set help for that relation
	    set RELHELP($relname,$type) {};
	    set RELHELP($relname,$type,comment) [xml-get-text [$ichild selectNodes .//comment/text()]];
	    set RELHELP($relname,$type,connectives) [xml-get-text [$ichild selectNodes .//connectives/text()]];
	    set RELHELP($relname,$type,description) [xml-get-text [$ichild selectNodes .//description/text()]];
	    set RELHELP($relname,$type,effect) [xml-get-text [$ichild selectNodes .//effect/text()]];
	    set RELHELP($relname,$type,example) [xml-get-text [$ichild selectNodes .//example/text()]];
	    set RELHELP($relname,$type,nucleus) [xml-get-text [$ichild selectNodes .//nucleus/text()]];
	    set RELHELP($relname,$type,nucsat) [xml-get-text [$ichild selectNodes .//nucsat/text()]];
	    set RELHELP($relname,$type,satellite) [xml-get-text [$ichild selectNodes .//satellite/text()]];
	    set RELHELP($relname,$type,type) $reltype;
	}
    }
    # sort the lists of relations
    set [subst $type2rel]($reltype) [lsort -dictionary -nocase $[subst $type2rel]($reltype)]
    return 0;
}

##################################################################
package provide rsttool::relations 0.0.1
return
