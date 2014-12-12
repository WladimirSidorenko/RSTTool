# -*- mode: tcl; coding: utf-8; -*-

array unset nid2msgid
array unset msgid2nid
array unset visible_nodes
array unset msgs2extnid

global seg_mrk seg_mrk_y

array set visible_nodes {78 1 79 1}
array set nid2msgid {78 328565839836110848 79 328565839836110848}
array set msgid2nid {328565839836110848 {78 79}}

set theForrest(328565839836110848) {{@ZDF So'n Schmus was der #Friedrich da von sich gibt. Was für 'ne Pappnase ist der denn, #berlinheute?}}

set node(78,arrowwgt) 8665
set node(78,children) {}
set node(78,constit) {}
set node(78,labelwgt) 8487
set node(78,offsets) {0 88}
set node(78,parent) {}
set node(78,relname) {}
set node(78,span) {78 78}
set node(78,spanwgt) 44
set node(78,text) "@ZDF So'n Schmus was der #Friedrich da von sich gibt. Was für 'ne Pappnase ist der denn,"
set node(78,textwgt) 8663
set node(78,type) text
set node(78,visible) 1
set node(78,xpos) 960
set node(78,ypos) 184


set node(79,arrowwgt) 8668
set node(79,children) {}
set node(79,constit) {}
set node(79,labelwgt) 8669
set node(79,offsets) {88 101}
set node(79,parent) {}
set node(79,relname) {}
set node(79,span) {79 79}
set node(79,spanwgt) 8667
set node(79,text) " #berlinheute"
set node(79,textwgt) 8666
set node(79,type) text
set node(79,xpos) 1070
set node(79,ypos) 184

.editor.text delete 1.0 end
.editor.text tag add new 1.0 end
show-sentences .editor.text 328565839836110848 1
show-nodes 328565839836110848
redisplay-net

set seglen1 [string length $node(79,text)]
after 50 {set a 1}
vwait a

# determine x, y position of the last tag
set n_ranges [llength [.editor.text tag ranges bmarker]]
incr n_ranges -1
set tag_end [lrange [.editor.text tag ranges bmarker] $n_ranges $n_ranges]
lassign [lrange [.editor.text bbox "$tag_end -1chars"] 0 1] seg_mrk_x seg_mrk_y

# determine x, y positions for the move point
lassign [lrange [.editor.text bbox "end -1chars"] 0 1] new_x new_y

# actually move the node boundary
move-node .editor.text $new_x $new_y

# determine text length of the node after move
set seglen2 [string length $node(79,text)]

if {[expr $seglen2 - $seglen1] != 1} {
    error "Error when moving boundary past the last character back and force."
}
