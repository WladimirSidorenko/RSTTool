# -*- mode: tcl; -*-

array set visible_nodes {1 1 2 1 3 1 5001 1 5002 1}
array set nid2msgid {1 1 2 1 3 1 5001 1 5002 1}

set node(1,arrowwgt) 50
set node(1,children) {}
set node(1,constit) {}
set node(1,labelwgt) 326
set node(1,offsets) {0 51}
set node(1,parent) 5001
set node(1,relname) concession
set node(1,span) {1 1}
set node(1,spanwgt) 49
set node(1,text) "Ist bei euch auch grad so geiles Sonnen-Wetter? ..."
set node(1,textwgt) 328
set node(1,textwgt) {}
set node(1,type) text
set node(1,visible) 1
set node(1,xpos) 80
set node(1,ypos) 46

set node(2,arrowwgt) 44
set node(2,children) {3}
set node(2,constit) {}
set node(2,labelwgt) 330
set node(2,offset) {51 87}
set node(2,parent) 5001
set node(2,relname) span
set node(2,span) {2 2}
set node(2,spanwgt) 33
set node(2,text) " Ach, wen versuch ich zu verarschen?"
set node(2,textwgt) 32
set node(2,type) text
set node(2,xpos) 190
set node(2,ypos) 92

set node(3,arrowwgt) 37
set node(3,children) {}
set node(3,constit) {}
set node(3,labelwgt) 38
set node(2,offset) {87 122}
set node(3,parent) 2
set node(3,relname) elaboration
set node(3,span) {3 3}
set node(3,spanwgt) 36
set node(3,text) " Jeder weiﬂ, dass 1. April ist. :-I"
set node(3,textwgt) 35
set node(3,type) text
set node(3,xpos) 300
set node(3,ypos) 92

set node(5001,arrowwgt) 47
set node(5001,children) {1 2}
set node(5001,constit) {}
set node(5001,labelwgt) 324
set node(5001,parent) 5002
set node(5001,relname) {}
set node(5001,span) {2 3}
set node(5001,spanwgt) 40
set node(5001,text) {2-3}
set node(5001,textwgt) 39
set node(5001,type) span
set node(5001,xpos) 190
set node(5001,ypos) 46

set node(5002,arrowwgt) 323
set node(5002,children) {5001}
set node(5002,constit) {}
set node(5002,labelwgt) 324
set node(5002,parent) {}
set node(5002,relname) {}
set node(5002,span) {1 3}
set node(5002,spanwgt) 46
set node(5002,text) "1-3"
set node(5002,textwgt) 45
set node(5002,type) span
set node(5002,xpos) 190
set node(5002,ypos) 0

unlink-node 1
unlink-node 2
unlink-node 3

if {$node(2,textwgt) == {}} {
    error "Text node erased when unlinking."
}
