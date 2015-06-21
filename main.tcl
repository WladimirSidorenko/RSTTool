#!/usr/bin/env wish

##################################################################
# Packages
set DIR [file dirname [info script]]
lappend auto_path [file join $DIR lib]
package require rsttool

##################################################################
# Variables and Constants

##################################################################
# Methods
proc usage {{status 1}} {
    set SCRIPT [file normalize [info script]]
    set BASENAME [file tail $SCRIPT]

    puts stderr "DESCRIPTION:
Main script for launching visual interface of RSTTool.\n
USAGE:
$BASENAME \[OPTIONS\] \[input_file\]\n
OPTIONS:
-h|--help - type this screen and exit
"
    exit $status
}

##################################################################
# Main

# process arguments
set nargs 0;
foreach arg $argv {
    if { [string compare "$arg" "--help"] == 0 || [string compare "$arg" "-h"] == 0} {
	usage 0;
    } elseif { [string compare $arg "--"] == 0} {
    } elseif { [string compare -length 1 $arg "-"] == 0 && [string length $arg] != 1 } {
	return -code error "Unrecognized option: ${arg}.  Type `--help` to see usage.";
    } else {
	break;
    }
    incr nargs;
}

if { [expr $argc - $nargs] > 1 } {
    return -code error "Incorrect number of arguments: $argc.  Type `--help` to see usage.";
} else {
    rsttool::main [lrange $argv $nargs end];
}

