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
set SRCDIR "$DIRNAME/Source"
set LIBDIR "$SRCDIR/Library"

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

##################################################################
# Main
main
