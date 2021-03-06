#!/usr/bin/env wish

namespace eval ::rsttool::helper {
    variable HELP;
    array set HELP {};
    variable HELPMENU {Relation Interface};
}

##################################################################
proc ::rsttool::helper::create_toplevel {name} {
    variable HELP ::rsttool::RELATIONS ::rsttool::TOPLEVELS

    if {[info exists TOPLEVELS($name)] != -1} {
	destroy .$name
	destroy .$name.text
	destroy .$name.scroll
	destroy .$name.menubar
    } else {
	set TOPLEVELS($name) ""
    }

    toplevel .$name
    text .$name.text -yscrollcommand ".$name.scroll set" -height 30 -width 70
    scrollbar .$name.scroll -command ".$name.text yview"
    pack .$name.text -side left
    pack .$name.scroll -side right -fill y
    menu .$name.menubar
    if {$name == "Relations"} {
	.$name config -menu .$name.menubar
	set rel_items {mononuclear multinuclear embedded schema}
	foreach item $rel_items {
	    menu .$name.menubar.$item -tearoff 0
	    .$name.menubar add cascade -label "$item" -menu \
		.$name.menubar.$item
	}
	set types {rst multinuc embedded constit}
	foreach type $types {
	    if {$type == "rst"} { set my_label mononuclear
	    } elseif {$type == "multinuc"} { set my_label multinuclear
	    } elseif {$type == "embedded"} { set my_label embedded
	    } else { set my_label schema }
	    foreach item $RELATIONS($type) {
		.$name.menubar.$my_label add command -label "$item" \
		    -command ".$name.text delete 1.0 end; \
		.$name.text insert end \{$HELP($item)\}"
	    }
	}
    } else {
	.$name.text delete 1.0 end
	.$name.text insert end \{$HELP($name)\}
    }
}

proc ::rsttool::helper::load { } {
    variable ::rsttool::RELDIR ::rsttool::RELATIONS

    set types {rst multinuc constit embedded}
    foreach type $types {
	foreach item $RELATIONS($type) {
	    set HELP($item) {No Help Available}
	}
    }
    set HELP(interface) {No Help Available}

    set i 0
    while { $i < 2 } {
	if { $i == 0 } {
	    set help_file [open [file join $RELDIR Help.screen] r]
	} else {
	    set help_file [open [file join $RELDIR Help] r]
	}
	while {![eof $help_file]} {
	    set nextline {}
	    set entry {}
	    set last_char {}
	    while {![eof $help_file] && $last_char != "\}"} {
		gets $help_file nextline
		if {$entry != {}} {
		    append entry "\n"
		}
		append entry "$nextline"
		set nextline [string trimright $nextline]
		set last_char [string length $nextline]
		incr last_char -1
		set last_char [string index $nextline $last_char]
	    }
	    set relation [lindex $entry 0]
	    set definition [lindex $entry 1]
	    set HELP($relation) $definition
	}
	close $help_file
	incr i
    }
}

proc ::rsttool::helper::show_help {relation} {
    variable HELP
    dialog .d$relation {$relation} "$HELP($relation)" {} -1 {done}
}

proc ::rsttool::helper::init {{a_menu .menubar.mHelp}} {
    variable HELPMENU

    foreach item $HELPMENU {
	a_menu add command -label "$item" -command "create_toplevel $item"
    }
}

##################################################################
package provide rsttool::helper 0.0.1
return
