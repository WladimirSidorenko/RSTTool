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


proc dialog {w title text bitmap default args} {
    global button

    # 1. Create the top-level window and divide it into top
    # and bottom parts.

    toplevel $w -class Dialog
    wm title $w $title
    wm iconname $w Dialog
    frame $w.top -relief raised -bd 1
    pack $w.top -side top -fill both
    frame $w.bot -relief raised -bd 1
    pack $w.bot -side bottom -fill both

    # 2. Fill the top part with the bitmap and message.

    message $w.top.msg -width 3i -text $text\
	-font -Adobe-Times-Medium-R-Normal-*-180-*
    pack $w.top.msg -side right -expand 1 -fill both\
	-padx 3m -pady 3m
    if {$bitmap != ""} {
	label $w.top.bitmap -bitmap $bitmap
	pack $w.top.bitmap -side left -padx 3m -pady 3m
    }

    # 3. Create a row of buttons at the bottom of the dialog.

    set i 0
    foreach but $args {
	button $w.bot.button$i -text $but -command\
	    "set button $i"
	if {$i == $default} {
	    frame $w.bot.default -relief sunken -bd 1
	    raise $w.bot.button$i
	    pack $w.bot.default -side left -expand 1\
		-padx 3m -pady 2m
	    pack $w.bot.button$i -in $w.bot.default\
		-side left -padx 2m -pady 2m\
		-ipadx 2m -ipady 1m
	} else {
	    pack $w.bot.button$i -side left -expand 1\
		-padx 3m -pady 3m -ipadx 2m -ipady 1m
	}
	incr i
    }

    # 4. Set up a binding for <Return>, if there`s a default,
    # set a grab, and claim the focus too.

    if {$default >= 0} {
	bind $w <Return> "$w.bot.button$default flash; \
                        set button $default"
    }
    set oldFocus [focus]
    tkwait visibility $w
    grab set $w
    focus $w

    # 5. Wait for the user to respond, then restore the focus
    # and return the index of the selected button.

    tkwait variable button
    destroy $w
    focus $oldFocus
    return $button
}

#############################################
# scrolled-text dialog item

proc scrolled-text {name args} {
    # Returns a scrollable text widget
    # $name.text is the actual text widger
    # $name.title is the title
    #
    # Args: (all optional)
    # -height <integer>
    # -font <font-spec>
    # -titlevar varname : variable containing the name of the frame title
    set bg [getarg -b $args]
    if {$bg == {}} {set bg white}
    set height [getarg -height $args]
    if { $height == {} } {set height 40}

    frame $name -height $height
    grid columnconfigure $name 0 -weight 1
    grid rowconfigure $name 2 -weight 1
    grid rowconfigure $name 3 -weight 1
    # add title bar
    label $name.title -textvariable [getarg -titlevar $args]
    grid $name.title -row 0  -sticky "ew"
    # add buttons for navigating around discussions
    set navibar [frame $name.navibar]
    grid $navibar -sticky "nsew" -row 1;
    set btnNext [button $name.btnNextMsg -text "Next" -command {nextMessage really}];
    set btnPrev [button $name.btnPrevMsg -text "Previous" -command {nextMessage really backward}];
    set btnNextSent [button $name.nextsent -text "Next Sentence" -command {nextSentence really}];
    grid $btnPrev $btnNext $btnNextSent -in $navibar;

    frame $name.textWindowPrnt
    text  $name.textPrnt  -bg $bg -relief sunken -yscrollcommand "$name.scrollPrnt set"
    scrollbar $name.scrollPrnt -command "$name.textPrnt yview"
    grid $name.textPrnt -in $name.textWindowPrnt -column 0 -row 0 -sticky "nsew"
    grid $name.scrollPrnt -in $name.textWindowPrnt -column 1 -row 0 -sticky "ns"
    grid columnconfigure $name.textWindowPrnt 0 -weight 1
    grid $name.textWindowPrnt -row 2 -column 0 -sticky "nsew"

    frame $name.textWindow
    text  $name.text  -bg $bg -relief sunken -yscrollcommand "$name.scroll set"
    scrollbar $name.scroll -command "$name.text yview"
    grid $name.text -in $name.textWindow -column 0 -row 0 -sticky "nsew"
    grid $name.scroll -in $name.textWindow -column 1 -row 0 -sticky "ns"
    grid columnconfigure $name.textWindow 0 -weight 1
    grid $name.textWindow -row 3 -column 0 -sticky "nsew"

    set font [getarg -font $args]
    if {$font != {}} {
	$name.textPrnt configure -font $font;
	$name.text configure -font $font;
    }

    set messagebar [getarg -messagebar $args]
    if {$messagebar == "t"} {
	frame $name.msgbar
	# the value of bg color is a hard code here
	text  $name.msg -bg gray84 -relief flat -height 1.2;
	grid columnconfigure $name.msgbar 0 -weight 1
    	grid $name.msg -in $name.msgbar -row 0 -column 0 -sticky "ew"
    	grid $name.msgbar -column 0 -row 4 -sticky "ew"
    }
}


proc getarg {key list} {
    # Returns the value in list immediately following key
    for {set i 0} {$i < [llength $list]} {incr i 2} {
	if { [lindex $list $i] == $key } {
	    return [lindex $list [expr $i + 1]]
	}
    }
    return {}
}

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


proc fileselect {{title "Select File"} {default {}} {mustExist 1} {prnt .}}  {
    global currentfile

    if {[string length $currentfile] != 0} {
	set cur_dir [file dirname $currentfile]
    } else {
	set cur_dir $::env(HOME)
    }

    if {$mustExist == 1} {
	tk_getOpenFile -initialdir $cur_dir -initialfile $default -parent $prnt -title $title
    } else {
	tk_getSaveFile -initialdir $cur_dir -initialfile $default -parent $prnt -title $title
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
