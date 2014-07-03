proc Toolbar {name {direction vertical}} {
  global ToolbarDir
  set ToolbarDir($name) $direction
  frame $name
}

proc ToolbarItem {Tbar Iname Text Cmd} {
    global ToolbarDir
    button $Tbar.$Iname -text $Text -command $Cmd
    if { $ToolbarDir($Tbar) == "vertical" } {
	pack $Tbar.$Iname -side top -anchor nw -fill x
    } else {
	pack $Tbar.$Iname -side left -anchor nw -fill y
    }
}
