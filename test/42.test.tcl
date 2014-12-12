# -*- mode: tcl; coding: utf-8; -*-

array unset nid2msgid
array unset msgid2nid
array unset visible_nodes
array unset msgs2extnid

array set visible_nodes {1 1 2 1 3 1 5001 1}
array set nid2msgid {1 328094026052018176 2 328096228724322304 3 328096228724322304 \
			 5001 328094026052018176}
array set msgid2nid {328094026052018176 1 328096228724322304 {2 3} \
			 328094026052018176 5001}

set node(1,arrowwgt) 55
set node(1,children) {}
set node(1,constit) {}
set node(1,labelwgt) 56
set node(1,offsets) {0 27}
set node(1,parent) 5001
set node(1,relname) List
set node(1,span) {1 1}
set node(1,spanwgt) 44
set node(1,text) "@_diesdasananas_ Oder so :D"
set node(1,textwgt) 43
set node(1,type) text
set node(1,visible) 1
set node(1,xpos) 80
set node(1,ypos) 76

set node(2,arrowwgt) 57
set node(2,children) {}
set node(2,constit) {}
set node(2,labelwgt) 58
set node(2,offset) {27 48}
set node(2,parent) 5001
set node(2,relname) List
set node(2,span) {2 2}
set node(2,spanwgt) 48
set node(2,text) " Warst du alleine da?"
set node(2,textwgt) 47
set node(2,type) text
set node(2,xpos) 190
set node(2,ypos) 76

set node(3,arrowwgt) 63
set node(3,children) {}
set node(3,constit) {}
set node(3,labelwgt) 64
set node(2,offset) {48 115}
set node(3,parent) 5001
set node(3,relname) List
set node(3,span) {3 3}
set node(3,spanwgt) 62
set node(3,text) " Ich hatte beim färben eine Freundin dabei, gegen die langeweile :D"
set node(3,textwgt) 61
set node(3,type) text
set node(3,xpos) 300
set node(3,ypos) 76

set node(5001,arrowwgt) {}
set node(5001,children) {1 2 3}
set node(5001,constit) {}
set node(5001,labelwgt) {}
set node(5001,parent) {}
set node(5001,relname) {}
set node(5001,span) {1 3}
set node(5001,spanwgt) 54
set node(5001,text) "1-3"
set node(5001,textwgt) 53
set node(5001,type) multinuc
set node(5001,xpos) 190
set node(5001,ypos) 30

unlink-node 1

if {$node(5001,children) == {}} {
    error "Error when unlinking one of multiple multi-nuclear nodes."
}
