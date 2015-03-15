#!/usr/bin/env wish

##################################################################
package require tdom;

##################################################################
namespace eval ::rsttool::abbreviations {
    variable DATA_DIR [file dirname [info script]];
    variable DEFAULT_FILE [file join $DATA_DIR abbreviations.xml];
    variable ABBREVIATIONS;
    array set ABBREVIATIONS {};
}

##################################################################
proc ::rsttool::abbreviations::reset {} {
    variable ABBREVIATIONS;
    array unset ABBREVIATIONS;
}

proc ::rsttool::abbreviations::load {{a_fname ::rsttool::abbreviations::DEFAULT_FILE}} {
    set ret 0;

    set xmldoc [::rsttool::file::load-xml $a_fname]
    set root [$xmldoc]

    foreach abbrnode [$root childNodes] {
    }
}

##################################################################
package provide rsttool::abbreviations 0.0.1
return
