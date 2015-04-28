#!/usr/bin/env wish
# -*- mode: tcl; coding: utf-8; -*-

##################################################################
# Description:
# Main script for building, testing, and installing this package.

##################################################################
# Variables
set SCRIPT [file normalize [info script]]
set DIRNAME [file dirname $SCRIPT]
set BASENAME [file tail $SCRIPT]
set SRCDIR [file join $DIRNAME src]
set LIBDIR [file join $SRCDIR Library]

##################################################################
# Methods
proc main {} {
    global argv
    if {![llength $argv]} {set argv help}
    foreach arg $argv {
	if {[catch {eval _$argv}]} {
	    usage
	}
    }
    exit 0
}

proc usage {{status 1}} {
    global BASENAME
    puts stderr "DESCRIPTION:
Main script for building, testing, and installing this package.\n
USAGE:
$BASENAME \[OPTIONS\] TARGETS\n
TARGETS:"
    foreach c [lsort -dict [info commands _*]] {
	set c [string range $c 1 end]
	if {[catch {H${c}} res]} {
	    puts stderr "$c args...\n"
	} else {
	    puts stderr "$c $res\n"
	}
	set prefix " "
    }
    exit $status
}

proc Hhelp {} { return "\n\tPrint this help" }
proc _help {} {
    usage 0
    return
}

proc Htest {} { return "\n\tRun tests" }
proc _test {} {
    global DIRNAME
    source "$DIRNAME/test/all.tcl"
    return
}

proc Hstarkit {} { return "?destination? ?interpreter?\n\tGenerate a starkit\n\tdestination = path of result file, default 'critcl.kit'\n\tinterpreter = (path) name of tcl shell to use for execution, default 'rsttool'" }
proc _starkit {{dst rsttool.kit} {interp tclkit}} {
    package require vfs::mk4;

    set c [open $dst w];
    fconfigure $c -translation binary -encoding binary;
    puts -nonewline $c "#!/bin/sh\n# -*- tcl -*- \\\nexec $interp \"\$0\" \$\{1+\"\$@\"\}\npackage require starkit\nstarkit::header mk4 -readonly\n\032################################################################################################################################################################";
    close $c;

    vfs::mk4::Mount $dst /KIT;
    file copy -force lib /KIT;
    file copy -force main.tcl /KIT;
    vfs::unmount /KIT;
    +x $dst;

    puts stderr "Created starkit: $dst";
    return;
}

proc Hstarpack {} { return "prefix ?destination?\n\tGenerate a fully-selfcontained executable, i.e. a starpack\n\tprefix      = path of tclkit/basekit runtime to use\n\tdestination = path of result file, default 'rsttool'" }
proc _starpack {prefix {dst rsttool}} {
    package require vfs::mk4;

    file copy -force $prefix $dst;

    vfs::mk4::Mount $dst /KIT;
    file mkdir /KIT/lib;

    foreach d [glob -directory lib *] {
	file delete -force  /KIT/lib/[file tail $d];
	file copy -force $d /KIT/lib;
    }

    file copy -force main.tcl /KIT;
    vfs::unmount /KIT;
    +x $dst;

    puts stderr "Created starpack: $dst";
    return;
}

##################################################################
# Main
main
