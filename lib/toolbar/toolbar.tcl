#!/usr/bin/env wish

##################################################################

##################################################################
namespace eval ::rsttool::toolbar {
    variable DIRECTION;
    array set DIRECTION {};
}

##################################################################
proc ::rsttool::toolbar::install {} {
    menu .menubar
    # attach it to the main window
    . config -menu .menubar

    # create more cascade menus
    foreach m {File View Print Help} {
	set $m [menu .menubar.m$m -tearoff 0]
	.menubar add cascade -label $m -menu .menubar.m$m
    }

    ::rsttool::file::update_menu $File
    # ::rsttool::treeditor::update_menu $View
    # ::rsttool::print::update_menu $Print
}

##################################################################
package provide rsttool::toolbar 0.0.1
return
