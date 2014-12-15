# -*- mode: tcl; coding: utf-8; -*-

array unset nid2msgid
array unset msgid2nid
array unset visible_nodes
array unset msgs2extnid

array set visible_nodes {1 1 2 1 4 1 5002 1 5003 1 5004 1}
array set nid2msgid {1 328096228724322304 2 328096228724322304 4 328096228724322304 \
			 5002 328096228724322304 5003 328096228724322304 5004 328096228724322304}
array set msgid2nid {328096228724322304 {1 2 4 5002 5003 5004}}

set node(1,text) {@nrsss ja,}
set node(1,type) {text}
set node(1,textwgt) {76}
set node(1,labelwgt) {}
set node(1,arrowwgt) {86}
set node(1,spanwgt) {77}
set node(1,relname) {span}
set node(1,children) {2}
set node(1,parent) {5002}
set node(1,constituents) {}
set node(1,visible) {1}
set node(1,span) {1 1}
set node(1,offsets) {0 10}
set node(1,xpos) {80}
set node(1,ypos) {92}
set node(1,oldindex) {}
set node(1,newindex) {}
set node(1,constit) {}
set node(1,promotion) {}

set node(2,text) { ist ja alles richtig.}
set node(2,type) {text}
set node(2,textwgt) {79}
set node(2,labelwgt) {82}
set node(2,arrowwgt) {81}
set node(2,spanwgt) {80}
set node(2,relname) {elaboration}
set node(2,children) {}
set node(2,parent) {1}
set node(2,constituents) {}
set node(2,visible) {1}
set node(2,span) {2 2}
set node(2,offsets) {10 32}
set node(2,xpos) {190}
set node(2,ypos) {92}
set node(2,oldindex) {}
set node(2,newindex) {}
set node(2,constit) {}
set node(2,promotion) {}

set node(4,text) { (Wo gibt es Sekretäre?)}
set node(4,type) {text}
set node(4,textwgt) {99}
set node(4,labelwgt) {102}
set node(4,arrowwgt) {101}
set node(4,spanwgt) {100}
set node(4,relname) {interpretation}
set node(4,children) {}
set node(4,parent) {3}
set node(4,constituents) {}
set node(4,visible) {1}
set node(4,span) {4 4}
set node(4,offsets) {107 131}
set node(4,xpos) {410}
set node(4,ypos) {92}
set node(4,oldindex) {}
set node(4,newindex) {}
set node(4,constit) {}
set node(4,promotion) {}

set node(5002,text) {1-2}
set node(5002,type) {span}
set node(5002,textwgt) {83}
set node(5002,labelwgt) {}
set node(5002,arrowwgt) {91}
set node(5002,spanwgt) {84}
set node(5002,relname) {span}
set node(5002,children) {1 5003}
set node(5002,parent) {5004}
set node(5002,constituents) {}
set node(5002,visible) {1}
set node(5002,span) {1 2}
set node(5002,offsets) {}
set node(5002,xpos) {80}
set node(5002,ypos) {46}
set node(5002,oldindex) {}
set node(5002,newindex) {}
set node(5002,constit) {}
set node(5002,promotion) {}

set node(5003,text) {3-4}
set node(5003,type) {span}
set node(5003,textwgt) {92}
set node(5003,labelwgt) {95}
set node(5003,arrowwgt) {94}
set node(5003,spanwgt) {93}
set node(5003,relname) {elaboration}
set node(5003,children) {3}
set node(5003,parent) {5002}
set node(5003,constituents) {}
set node(5003,visible) {1}
set node(5003,span) {3 4}
set node(5003,offsets) {}
set node(5003,xpos) {300}
set node(5003,ypos) {46}
set node(5003,oldindex) {}
set node(5003,newindex) {}
set node(5003,constit) {}
set node(5003,promotion) {}

set node(5004,text) {1-4}
set node(5004,type) {span}
set node(5004,textwgt) {89}
set node(5004,labelwgt) {}
set node(5004,arrowwgt) {}
set node(5004,spanwgt) {90}
set node(5004,relname) {}
set node(5004,children) {5002}
set node(5004,parent) {}
set node(5004,constituents) {}
set node(5004,visible) {1}
set node(5004,span) {1 4}
set node(5004,offsets) {}
set node(5004,xpos) {80}
set node(5004,ypos) {0}
set node(5004,oldindex) {}
set node(5004,newindex) {}
set node(5004,constit) {}
set node(5004,promotion) {}

if {[catch {unlink-node 1}]} {
    error "Error unable to unlink nested node."
}
