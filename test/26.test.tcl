# -*- mode: tcl; -*-

set disco_node {}
set last_group_node_id 5000
set relations(rst) {antithesis}

array unset nid2msgid
array unset visible_nodes

array set nid2msgid {1 1 2 1 3 1}
array set visible_nodes {1 1 2 1 3 1}

set node(1,arrowwgt) 325
set node(1,children) {}
set node(1,constit) {}
set node(1,labelwgt) 326
set node(1,parent) {}
set node(1,relname) {}
set node(1,span) {1 1}
set node(1,spanwgt) 327
set node(1,text) {}
set node(1,textwgt) 328
set node(1,textwgt) {}
set node(1,type) text
set node(1,xpos) 0
set node(1,ypos) 0

set node(2,arrowwgt) 329
set node(2,children) {}
set node(2,constit) {}
set node(2,labelwgt) 330
set node(2,parent) {}
set node(2,relname) {}
set node(2,span) {2 2}
set node(2,spanwgt) 331
set node(2,text) {}
set node(2,textwgt) 332
set node(2,textwgt) {}
set node(2,type) text
set node(2,xpos) 0
set node(2,ypos) 0

set node(3,arrowwgt) 323
set node(3,children) {}
set node(3,constit) {}
set node(3,labelwgt) 324
set node(3,parent) {}
set node(3,relname) {}
set node(3,span) {3 3}
set node(3,spanwgt) 106
set node(3,text) {}
set node(3,textwgt) 105
set node(3,type) text
set node(3,xpos) 0
set node(3,ypos) 0


autolink_nodes 1 2 satellite antithesis
autolink_nodes 2 3 satellite antithesis

if {$node(2,parent) == 1 || [lindex $node(1,children) 2] != {}} {
    error "Sattellite node is not relinked after adding to it one more satellite."
}
return
