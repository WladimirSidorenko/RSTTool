#!/usr/bin/env tclsh
# -*- mode: tcl; -*-

##################################################################
# Import
global DIRNAME

##################################################################
# Main

# Run all .test files in this file's directory.
namespace eval :: source "$DIRNAME/RSTTool.tcl"

foreach t [lsort -dict [glob -directory [file dirname [file normalize [info script]]] *.test.tcl]] {
    puts -nonewline stderr "$t ..."
    if {[catch {
	namespace eval :: source $t
    }]} {
	puts stderr " FAILED"
	puts stderr $::errorInfo
    } else {
	puts stderr " SUCCESS"
    }
}
