# -*- mode: tcl; coding: utf-8; -*-

array unset nid2msgid
array unset msgid2nid
array unset visible_nodes
array unset msgs2extnid

array set visible_nodes {1 1 2 1 3 1 5001 1}
array set nid2msgid {1 328094026052018176 2 328096228724322304 3 328096228724322304 \
			 5001 {328094026052018176 328096228724322304}}
array set msgid2nid {328094026052018176 1 328096228724322304 {2 3} \
			 {328094026052018176 328096228724322304} {5001}}
array set msgs2extnid {"328094026052018176,328096228724322304" {5001 1 span}}

set node(1,arrowwgt) 45
set node(1,children) 2
set node(1,constit) {}
set node(1,labelwgt) {}
set node(1,offsets) {0 70}
set node(1,parent) 5001
set node(1,relname) span
set node(1,span) {1 1}
set node(1,spanwgt) 44
set node(1,text) "Informationen in der Presse aus Spanien sind haltlos und nicht richtig"
set node(1,textwgt) 43
set node(1,type) text
set node(1,visible) 1
set node(1,xpos) 80
set node(1,ypos) 76

set node(2,arrowwgt) 48
set node(2,children) {}
set node(2,constit) {}
set node(2,labelwgt) 49
set node(2,offset) {0 75}
set node(2,parent) 1
set node(2,relname) r-answer
set node(2,span) {2 2}
set node(2,spanwgt) 47
set node(2,text) "@esmanagement Unangenehm wenn der Gegenwind zu heftig wird, nicht wahr...?!"
set node(2,textwgt) 46
set node(2,type) text
set node(2,xpos) 190
set node(2,ypos) 76

set node(3,arrowwgt) {}
set node(3,children) {}
set node(3,constit) {}
set node(3,labelwgt) {}
set node(2,offset) {75 93}
set node(3,parent) {}
set node(3,relname) {}
set node(3,span) {3 3}
set node(3,spanwgt) 40
set node(3,text) " #Lewandowski #bvb"
set node(3,textwgt) 39
set node(3,type) text
set node(3,xpos) 300
set node(3,ypos) 30

set node(5001,arrowwgt) {}
set node(5001,children) {1}
set node(5001,constit) {}
set node(5001,labelwgt) {}
set node(5001,parent) 5002
set node(5001,relname) span
set node(5001,span) {1 2}
set node(5001,spanwgt) 42
set node(5001,text) "1-2"
set node(5001,textwgt) 41
set node(5001,type) span
set node(5001,xpos) 80
set node(5001,ypos) 30

if {[catch {autolink_nodes 5001 3 {} "r-answer"}]} {
    error "Error when trying to link an internal node to abstract node covering two messages."
}
