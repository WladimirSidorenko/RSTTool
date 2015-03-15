#!/usr/bin/env wish

##################################################################
# Packages
set DIR [file dirname [info script]]
lappend auto_path [file join $DIR lib]

package require rsttool

##################################################################
# Main
rsttool::main $argv
