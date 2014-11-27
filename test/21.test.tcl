# -*- mode: tcl; -*-

reset-rst

set disco_node {}
set last_group_node_id 5001

array unset nid2msgid
array unset visible_nodes

array set visible_nodes {1 1 2 1 3 1 5001 1}
array set nid2msgid {1 404262465166639114 2 404262465166639114 \
			 5001 404262465166639114 3 404262465166639115}

set node(1,arrowwgt) 97
set node(1,children) {2}
set node(1,constit) {}
set node(1,labelwgt) 1
set node(1,offsets) {29 41}
set node(1,parent) 5001
set node(1,relname) span
set node(1,span) {1 1}
set node(1,spanwgt) 96
set node(1,text) " Ich mein..."
set node(1,textwgt) 95
set node(1,textwgt) {}
set node(1,type) text
set node(1,visible) 1
set node(1,xpos) 300
set node(1,ypos) 76

set node(2,arrowwgt) 104
set node(2,children) {}
set node(2,constit) {}
set node(2,labelwgt) 105
set node(2,offset) {41 51}
set node(2,parent) 1
set node(2,relname) OTHER
set node(2,span) {2 2}
set node(2,spanwgt) 33
set node(2,text) " Religion?"
set node(2,textwgt) 102
set node(2,type) text
set node(2,xpos) 410
set node(2,ypos) 122

set node(5001,arrowwgt) {}
set node(5001,children) {1}
set node(5001,constit) {}
set node(5001,labelwgt) 324
set node(5001,parent) {}
set node(5001,relname) {}
set node(5001,span) {1 2}
set node(5001,spanwgt) 40
set node(5001,text) {1-2}
set node(5001,textwgt) 93
set node(5001,type) span
set node(5001,xpos) 300
set node(5001,ypos) 30

set node(3,arrowwgt) 108
set node(3,children) {}
set node(3,constit) {}
set node(3,labelwgt) 38
set node(2,offset) {51 70}
set node(3,parent) {}
set node(3,relname) {}
set node(3,span) {3 3}
set node(3,spanwgt) 107
set node(3,text) " Welche Begründung?"
set node(3,textwgt) 106
set node(3,type) text
set node(3,xpos) 520
set node(3,ypos) 122

autolink_nodes 1 3 "multinuclear" "list"

if {$node(3,parent) != {}} {
    error "Linking satellite node to node from another message is not allowed."
}
