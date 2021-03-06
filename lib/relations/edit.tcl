# -*- mode: tcl; -*-
# Relations

#############################
# function to pack the Editor



if {[winfo exists .menus]} {
    destroy .menus .relations .schematbar .relinfo
}

proc install-releditor {} {
    global schemas
    wm title . "RST Interface"
    pack .menus .relations  -side top -anchor nw -fill x
}

proc uninstall-releditor {} {
    pack forget .menus .relations
}

proc install-schemas {} {
    global schemas schematype

    # destroy any old version
    if {[winfo exists .menus.schematype.choice]} {
	destroy .menus.schematype.choice
    }

    # make the Schema choice menu
    eval [concat "tk_optionMenu .menus.schematype.choice schematype"\
	      $schemas]
    for {set i [expr [llength $schemas] - 1]} {$i >= 0} {incr i -1} {
	.menus.schematype.choice.menu entryconfigure $i\
	    -command "set schematype [lindex $schemas $i];install-schema"
    }
    pack .menus.schematype.label .menus.schematype.choice -side left


    pack  .menus.schematype  -after .menus.reltype -side left
    pack .schematbar -after .menus -side right
    install-schema [lindex $schemas 0]
}



proc install-schema {{schema {}}} {
    global schemas schema_elements schematype

    if { $schema == {} } {set schema $schematype}

    puts "install-schema: $schema"
    # Delete all entries
    .relations.table delete 0 end

    # Add the new
    foreach constit $schema_elements($schema) {
	.relations.table insert end $constit
    }
}

frame .menus
frame .menus.reltype
label .menus.reltype.label -text "View: "
tk_optionMenu .menus.reltype.choice reltype "RST Relations" "Schemas"
.menus.reltype.choice.menu entryconfigure 0 -command {
    set reltype "RST Relations"
    pack forget .menus.schematype
    pack forget .schematbar
}
.menus.reltype.choice.menu entryconfigure 1 -command {
    set reltype "Schemas"
    install-schemas
}
pack .menus.reltype.label .menus.reltype.choice -side left



button .menus.done -text "Done" -command {
    uninstall-releditor
    install-structurer
}
pack .menus.reltype   .menus.done -side left

frame .menus.schematype
label .menus.schematype.label -text "Schema: "

frame .schematbar
button .schematbar.add -text "Add Schema"\
    -command {add-schema}
button .schematbar.del -text "Delete Schema"\
    -command {delete-schema}
pack .schematbar.add .schematbar.del -side left



frame .relations
label .relations.label -text "Relations/Constituents"
listbox .relations.table -width 20 -height 20 -bg white
pack .relations.label .relations.table  -side top


frame .relinfo
