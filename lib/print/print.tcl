#!/usr/bin/env wish
# -*- mode: tcl; -*-

##################################################################
namespace eval ::rsttool::print {
    variable DOT_FILE {};
    variable P_WIDTH 1;
    variable P_HEIGHT 1;
}

##################################################################
# add commands to menu
proc ::rsttool::print::update_menu {a_menu} {
    $a_menu add cascade -label "Dot Options" -menu $a_menu.options
    menu $a_menu.options
    $a_menu.options add radio -label "text" -variable mode -value text
    $a_menu.options add radio -label "no text" -variable mode -value no_text
    $a_menu.options add separator
    $a_menu.options add radio -label "one page" -variable pages -value one
    $a_menu.options add radio -label "dot select" -variable pages -value multi
    $a_menu.options add radio -label "user select" -variable pages -value user\
	-command { ::rsttool::print::scale-size-select }
    $a_menu.options add separator
    $a_menu.options add radio -label "fill" -variable fill -value fill\
	-command { set orient portrait }
    $a_menu.options add radio -label "no fill" -variable fill -value no_fill
    $a_menu.options add separator
    $a_menu.options add radio -label "landscape" -variable orient -value landscape\
	-command { set fill no_fill }
    $a_menu.options add radio -label "portrait" -variable orient -value portrait
    $a_menu.options invoke 1
    $a_menu.options invoke 4
    $a_menu.options invoke 8
    $a_menu.options invoke 12
    $a_menu add command -label "Print Dot" -command {::rsttool::print::print_dot}
}

proc ::rsttool::print::capital { a_string } {
    return [string toupper $a_string]
}

proc ::rsttool::print::print_dot {} {
    if {[winfo exists .scalemenu]} {
	destroy .scalemenu.width
	destroy .scalemenu.height
	destroy .scalemenu
    }
    if {$currentfile != {} } {
	set my_dotfile [set-file-name dot]
	print_dot_helper
	if {$DOT_EXISTS == "YES"} {
	    exec $DOT -Tps $currentfile.rst/$my_dotfile -o\
		$currentfile.rst/$my_dotfile.ps
	    exec lpr -P$PRINTER $currentfile.rst/$my_dotfile.ps
        }
    } else {
	set my_dotfile [set-file-name dot tmp]
	print_dot_helper
	if {$DOT_EXISTS == "YES"} {
	    exec $DOT -Tps $my_dotfile -o $my_dotfile.ps
	    exec lpr -P$PRINTER $my_dotfile.ps
	    exec rm $my_dotfile.ps
        }
    }
}

proc ::rsttool::print::print_dot_helper { } {
    global node last_text_node_id currentfile dotfile used_nodes
    global last_group_node_id pages fill orient p_width p_height

    update_promotion

    if {$currentfile != {}} {
	set dotfilename $currentfile.rst/[set-file-name dot]
    } else {
	set dotfilename [set-file-name dot tmp]
    }
    set dotfile [open $dotfilename w 0644]

    set used_nodes {}

    puts $dotfile "digraph G { 
  node \[shape = box, fontname = Helvetica, fontsize = 10\]; 
  rankdir = TB; 
  page = \"8.5, 11\";" 
    if { $orient == "landscape" } {
	puts $dotfile "orientation = landscape;"
    }
    if { $pages == "one" } {
	puts $dotfile "size = \"7.5, 10\";" 
    } elseif { $pages == "user" } {
	puts $dotfile "size = \"[expr 7.5 * $p_width], [expr 10 * $p_height]\";"
    }
    if { $fill == "fill" } {
	puts $dotfile "ratio = fill;"
    }
    puts $dotfile "ranksep = .2; 
  nodesep = .2;
  concentrate = TRUE
  edge \[dir = none, fontname = Helvetica, fontsize = 10\]" 

    set root_nodes {}
    for {set i 1} {$i <= $last_text_node_id} {incr i} {
	set j $i
	while {$node($j,parent) != {} } {
	    set j $node($j,parent)
	}
	if {[lsearch $root_nodes $j] == -1} {
	    lappend root_nodes $j
	}
    }
    foreach root $root_nodes {
	puts $dotfile "$root \[shape=box\];\n"
	print_dot_recursion $root 
    }
    puts $dotfile "}"
    close $dotfile
}

proc ::rsttool::print::print_dot_recursion {nid} {
    global node dotfile used_nodes mode

    append used_nodes " $nid"

    #  print relevant information
    set nid_parent $node($nid,parent)
    append to_print "$nid \[label=\""
    if { $node($nid,constit) != {} } {
	append to_print "[capital $node($nid,constit)] \\n"
    }
    append to_print "$node($nid,promotion)"
    if { $node($nid,relname) != "span" &&
	 [relation-type $node($nid,relname)] != "multinuc"} {
	append to_print " [capital $node($nid,relname)]"
    }
    if {$mode == "text"} {
	set the_text $node($nid,text)
	while {$the_text != {}} {
	    set counter 0
	    append to_print " \\n"
	    while {$counter < 18} {
		set the_word [lindex $the_text 0]
		if {$the_word == {}} {
		    set counter 18
		} else {
		    append to_print "$the_word "
		    #delete the word from the list
		    set the_text [lreplace $the_text 0 0]
		    set wordlength [string length $the_word]
		    set counter [expr $counter + $wordlength + 1]
		}
	    }
	}
    }
    append to_print "\"\];\n"

    set child_list {}
    foreach child $node($nid,children) {
	if { [relation-type $node($child,relname)] != "rst" &&  [relation-type $node($child,relname)] != "embedded" } {
	    lappend child_list $child
	    set grandchild_list $node($child,children)
	    foreach grandchild $grandchild_list {
		if { [relation-type $node($grandchild,relname)] == "rst" || [relation-type $node($grandchild,relname)] == "embedded"} {
		    lappend child_list $grandchild
		}
	    }
	}
    }  
    set new_child_list {}
    foreach child $child_list {
	if {$child > 5000} {
	    set index $node($child,text)
	    set index [split $index -]
	    set index [lindex $index 0]
	    set backreference($index) $child
	    lappend new_child_list $index
	} else {
	    set backreference($child) $child
	    lappend new_child_list $child
	}
    }
    set new_child_list [lsort -integer $new_child_list]
    foreach child $new_child_list {
	set the_child $backreference($child)
	if { [relation-type $node($the_child,relname)] == "rst" || [relation-type $node($the_child,relname)] == "embedded"} {
	    append to_print "$the_child \[shape=box,style=dotted\];\n"
	    append to_print "edge \[style=dotted,label=\"\"\];\n"
	    append to_print "$nid -> $the_child;\n";
	} else {
	    append to_print "$the_child \[shape=box\];\n"
	    if { $node($the_child,relname) == "span" } {
		append to_print "edge \[style=bold,label=\"\"\];\n"
	    } else {
		append to_print \
		    "edge \[style=bold,label=\"[capital $node($the_child,relname)]\"\];\n"
	    }
	    append to_print "$nid -> $the_child;\n";
	}
    }
    puts $dotfile $to_print
    flush $dotfile

    foreach child $new_child_list {
	print_dot_recursion $backreference($child)
    }
}

proc save-subtree-as-ps {nid} {
  global node rstw DIR
  if { $nid !={} } {
    set print_region [find-subtree-region $nid]
    set file [fileselect "Save Postscript as" "untitled.ps" 0]
    $rstw postscript -file $file \
                   -x [lindex $print_region 0]\
                   -y [lindex $print_region 1]\
                   -width [expr [lindex $print_region 2] - [lindex $print_region 0] + 10]\
                   -height [expr [lindex $print_region 3] - [lindex $print_region 1] + 10]\
                   -pagex 0.i -pagey 11.i -pageanchor nw
  set-mode link
  }
}


proc find-subtree-region {nid} {
  global node
  puts "find-subtree-region: $nid"
  set node_region [find-node-region $nid]
  foreach cid $node($nid,children) {
   if {$node($cid,visible) == 1} {
      set node_region [unify-node-regions $node_region [find-subtree-region $cid]]
   }
  }
  return $node_region
}

proc find-node-region {nid} {
  global node half_node_width
  puts "find-node-region: $nid"
  set xmin [expr $node($nid,xpos) - $half_node_width]
  set xmax [expr $node($nid,xpos) + $half_node_width]
  set ymin $node($nid,ypos)
  set ymax [lindex [bottom-point [ntw $nid]] 1]
  return "$xmin $ymin $xmax $ymax"
}

proc unify-node-regions {reg1 reg2} {
  return "[min [lindex $reg1 0] [lindex $reg2 0]]\
          [min [lindex $reg1 1] [lindex $reg2 1]]\
          [max [lindex $reg1 2] [lindex $reg2 2]]\
          [max [lindex $reg1 3] [lindex $reg2 3]]"
}

proc ::rsttool::print::scale-size-select { } {
    variable ::rsttool::print::P_WIDTH;
    varibale ::rsttool::print::P_HEIGHT;

    if {[winfo exists .scalemenu.width]} {
	destroy .scalemenu.width
    }
    if {[winfo exists .scalemenu.height]} {
	destroy .scalemenu.height
    }
    if {[winfo exists .scalemenu]} {
	destroy .scalemenu
    }

    toplevel .scalemenu
    scale .scalemenu.width -label "Width (in pages)" \
	-from 1 -to 10 -length 10c -orient horizontal -command {
	    set P_WIDTH }
    scale .scalemenu.height -label "Height (in pages)" \
	-from 1 -to 10 -length 10c -orient horizontal -command {
	    set P_HEIGHT }
    pack .scalemenu.width .scalemenu.height -in .scalemenu
}

##################################################################
package provide rsttool::print 0.0.1
return
