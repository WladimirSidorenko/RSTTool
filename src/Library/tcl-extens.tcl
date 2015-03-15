# TCL EXTENSIONS

##################################
# append-strings
# - returns the input string-list as a single string
proc append-strings {args} {
    set result ""
    foreach arg $args {
	append result $arg
    }
    return $result
}

##################################
# delete-newlines
proc delete-newlines {text} {
    eval concat [split $text \n]
}

##################################
# manipulation on lists
proc add-points {p1 p2} {
    list [expr [lindex $p1 0] + [lindex $p2 0]]\
	[expr [lindex $p1 1] + [lindex $p2 1]]
}

proc subtract-points {p1 p2} {
    list [expr [lindex $p1 0] - [lindex $p2 0]]\
	[expr [lindex $p1 1] - [lindex $p2 1]]
}

proc mid-point {p1 p2} {
    add-points $p1 [halve-point [subtract-points $p2 $p1]]
}

proc halve-point {p1} {
    list [expr [lindex $p1 0] / 2]\
	[expr [lindex $p1 1] / 2]
}
##################################
# extending menuPackage
proc MenuIndex { menuName label } {
    global Menu
    if [catch {set Menu(menu,$menuName)} menu] {
	error "No such menu: $menuName"
    }
    if [catch {$menu index $label} index] {
	error "$label not in menu: $menuName"
    }
    return $index
}

proc MenuDelete { menuName {label {}}} {
    global Menu
    # exit if the menu already doesnt exist
    if [catch {set Menu(menu,$menuName)} menu] {
	puts stdout "MenuDelete: Menu $menuName does't exist!!"
	return
    }
    # Deletes the Menu, or if a label provided, just a menuitem
    if { $label  == {} } {
	#  Delete the menu
	$menu unmap
    } else {
	#  delete the menu item
	if [catch {$menu index $label} index] {
	    puts stdout "MenuDelete: Menu item $label not in menu $menuName!!"
	    return
	}
	$menu delete index
    }
}

proc AddMenuCascade {menu label newmenu} {
    $menu add cascade -label $label -menu $newmenu
}

proc AddMenuItem {menu label cmd} {
    $menu add command -label $label -command $cmd
}

proc show-tooltip {a_wdgt a_txt} {
    if [winfo exists $a_wdgt.tooltip] {destroy $a_wdgt.tooltip}

    set tooltip [toplevel $a_wdgt.tooltip -bd 1 -bg black]
    set scrh [winfo screenheight $a_wdgt]; # 1) flashing window fix
    set scrw [winfo screenwidth $a_wdgt]; # 2) flashing window fix
    wm geometry $tooltip +$scrh+$scrw; # 3) flashing window fix
    wm overrideredirect $tooltip 1
    pack [label $tooltip.label -bg lightyellow -fg black -text $a_txt -justify left]

    set width [winfo reqwidth $tooltip.label]
    set height [winfo reqheight $tooltip.label]
    # a.) Is the pointer in the bottom half of the screen?
    set pointer_below_midline [expr [winfo pointery .] > [expr [winfo screenheight .] / 2.0]]
    # b.) Tooltip is centred horizontally on pointer.
    set positionX [expr [winfo pointerx .] - round($width / 2.0)]
    # c.) Tooltip is displayed above or below depending on pointer Y position.
    set positionY [expr [winfo pointery .] + ($pointer_below_midline * -1) * ($height + 35) + \
		       (35 - (round($height / 2.0) % 35))]

    if  {[expr $positionX + $width] > [winfo screenwidth .]} {
	set positionX [expr [winfo screenwidth .] - $width]
    } elseif {$positionX < 0} {
	set positionX 0
    }

    wm geometry $tooltip [join  "$width x $height + $positionX + $positionY" {}]
    raise $tooltip
}

proc show-menu-tooltip {a_wdgt a_y} {
    global help

    # obtain menu entry
    set mitem [$a_wdgt entrycget active -label]

    # show help tooltip for menu entry
    if {[info exists help($mitem)] && $help($mitem) != ""} {
	show-tooltip $a_wdgt $help($mitem)
    }
}

proc bind-menu-tooltip {a_wdgt} {
    bind $a_wdgt <<MenuSelect>> {
    	destroy %W.tooltip
    	show-menu-tooltip %W %y
    }

    bind $a_wdgt <Any-Leave> [list destroy %W.tooltip [list continue]]
    bind $a_wdgt <Any-KeyPress> [list destroy %W.tooltip [list continue]]
    bind $a_wdgt <Any-Button> [list destroy %W.tooltip [list continue]]
}

##################################
# ldelete (From Welch examples)
# - deletes element from a list

proc ldelete { list value } {
    set ix [lsearch -exact $list $value]
    if {$ix >= 0} {
	return [lreplace $list $ix $ix]
    } else {
	return $list
    }
}

##################################
# has-tag
proc has-tag {canv item tag} {
    # Returns non-nil if item in canvas has given tag
    lsearch [lindex [$canv itemconfigure $item -tags] 4] $tag
}

##################################
# dialog - a dialog item

# From Oestermair ch 27
# Example
# dialog .d {File Modified} {File "tcl.h" has been modified since\
    # the last time it was saved. Do you want to save it before\
    # exiting the application?} warning 0 {Save File} \
    # {Discard Changes} {Return To Editor}



#############################################
# scrolled-text dialog item




proc member {item list} {
    if { [lsearch $list $item] == -1 } {
	return 0
    } else {
	return 1
    }
}

proc max {args} {
    set max -99999
    foreach arg $args {
	if {$arg > $max} {set max $arg}
    }
    return $max
}

proc min {args} {
    set min 99999999
    foreach arg $args {
	if {$arg < $min} {set min $arg}
    }
    return $min
}


proc fileselect {{title "Select File"} {a_fname {}} {mustExist 1} {prnt .}}  {
    global currentfile

    if {$currentfile != {}} {
	set cur_dir [file dirname $currentfile]
    } else {
	set cur_dir $::env(HOME)
    }

    if {$mustExist == 1} {
	tk_getOpenFile -initialdir $cur_dir -initialfile $a_fname -parent $prnt -title $title
    } else {
	tk_getSaveFile -initialdir $cur_dir -initialfile $a_fname -parent $prnt -title $title
    }
}


global DEBUG
set DEBUG 0
proc debug {{str ""}} {
    global DEBUG
    if { $DEBUG == 1 } {
	puts $str
    }
}
