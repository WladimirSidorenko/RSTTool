# Menu chapter
proc MenuSetup { {frame .menubar} } {
	global Menu
	frame $frame
	pack $frame -side top -fill x
	set Menu(menubar) $frame
	set Menu(uid) 0
}
proc Menu { label } {
	global Menu
	if [info exists Menu(menu,$label)] {
		error "Menu $label already defined"
	}
	# Create the menubutton and its menu
	set name $Menu(menubar).mb$Menu(uid)
	set menuName $name.menu
	incr Menu(uid)
	set mb [menubutton $name -text $label -menu $menuName]
	pack $mb -side left
	set menu [menu $menuName -tearoff 1]
    
	# Remember the widget name under a variable derived from the label.
	# This allows mxMenuBind to be passed the label instead of the widget.
	set Menu(menu,$label) $menu
	return $menu
}

proc MenuCommand { menuName label command } {
	global Menu
	if [catch {set Menu(menu,$menuName)} menu] {
		error "No such menu: $menuName"
	}
	$menu add command -label $label -command $command
}

proc MenuCheck { menuName label var { command  {} } } {
	global Menu
	if [catch {set Menu(menu,$menuName)} menu] {
		error "No such menu: $menuName"
	}
	$menu add check -label $label -command $command \
		-variable $var
}

proc MenuRadio { menuName label var {value {}} { command  {} } } {
	global Menu
	if [catch {set Menu(menu,$menuName)} menu] {
		error "No such menu: $menuName"
	}
	if {[string length $value] == 0} {
	    set value $label
	}
	$menu add radio -label $label -command $command \
		-value $value -variable $var
}

proc MenuSeparator { menuName } {
	global Menu
	if [catch {set Menu(menu,$menuName)} menu] {
		error "No such menu: $menuName"
	}
	$menu add separator
}

proc MenuCascade { menuName label } {
	global Menu
	if [catch {set Menu(menu,$menuName)} menu] {
		error "No such menu: $menuName"
	}
	if [info exists Menu(menu,$label)] {
		error "Menu $label already defined"
	}
	set sub $menu.sub$Menu(uid)
	incr Menu(uid)
	menu $sub -tearoff 0
	$menu add cascade -label $label -menu $sub
	set Menu(menu,$label) $sub
}

proc MenuBind { what sequence menuName label } {
	global Menu
	if [catch {set Menu(menu,$menuName)} menu] {
		error "No such menu: $menuName"
	}
	if [catch {$menu index $label} index] {
		error "$label not in menu $menuName"
	}
	set command [$menu entrycget $index -command]
	bind $what $sequence $command
	$menu entryconfigure $index -accelerator $sequence
}
proc MenuEntryConfigure { menuName label args } {
	global Menu
	if [catch {set Menu(menu,$menuName)} menu] {
		error "No such menu: $menuName"
	}
	eval {$menu entryconfigure $label} $args
}


