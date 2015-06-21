#!/usr/bin/env tclsh
# -*- mode: tcl; coding: utf-8; -*-

##################################################################
# Variables and Constants

##################################################################
# Import

##################################################################
# Main

# Run all .test files in this file's directory.

if {[catch {namespace eval :: {package require rsttool}}]} {
    puts stderr "Failed to load the program..."
} else {
    puts stderr {Running tests...}
    foreach t [lsort -dict [glob -nocomplain -directory [file dirname [file normalize [info script]]] *.test.tcl]] {
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
    puts stderr {Tests finished...}
}
