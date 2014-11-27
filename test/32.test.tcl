# -*- mode: tcl; coding: utf-8; -*-

array unset nid2msgid
array unset msgid2nid
array unset visible_nodes
array unset msgs2extnid

array set visible_nodes {1 1 2 1 3 1 5001 1 5002 1}
array set nid2msgid {1 404261789514616832 2 404261789514616832 3 404261977964687360 \
			 5001 404261789514616832 5002 {404261789514616832 404261977964687360}}
array set msgid2nid {404261789514616832 {1 2 5001} 404261977964687360 {3} \
			 {404261789514616832 404261977964687360} {5002}}
array set msgs2extnid {"404261789514616832,404261977964687360" {5002 5001 span 5001 3 r-justify}}

set node(1,arrowwgt) 56
set node(1,children) 2
set node(1,constit) {}
set node(1,labelwgt) {}
set node(1,offsets) {0 79}
set node(1,parent) 5001
set node(1,relname) span
set node(1,span) {1 1}
set node(1,spanwgt) 47
set node(1,text) "Was hast du eigentlich jetzt in Religion für 'ne Note bekommen, @NightmareMoon_"
set node(1,textwgt) 46
set node(1,type) text
set node(1,visible) 1
set node(1,xpos) 80
set node(1,ypos) 92

set node(2,arrowwgt) 51
set node(2,children) {}
set node(2,constit) {}
set node(2,labelwgt) 52
set node(2,offset) {79 81}
set node(2,parent) 1
set node(2,relname) attribution
set node(2,span) {2 2}
set node(2,spanwgt) 50
set node(2,text) ""
set node(2,textwgt) 49
set node(2,type) text
set node(2,xpos) 190
set node(2,ypos) 92

set node(3,arrowwgt) 64
set node(3,children) {}
set node(3,constit) {}
set node(3,labelwgt) 65
set node(2,offset) {0 75}
set node(3,parent) 5001
set node(3,relname) r-justify
set node(3,span) {3 3}
set node(3,spanwgt) 63
set node(3,text) "@AKW_Kovu Eine 6. (Also das ist jetzt kein Witz sondern mein voller Ernst.)"
set node(3,textwgt) 62
set node(3,type) text
set node(3,xpos) 300
set node(3,ypos) 46

set node(5001,arrowwgt) 61
set node(5001,children) {1 3}
set node(5001,constit) {}
set node(5001,labelwgt) {}
set node(5001,parent) 5002
set node(5001,relname) span
set node(5001,span) {1 2}
set node(5001,spanwgt) 54
set node(5001,text) "1-2"
set node(5001,textwgt) 53
set node(5001,type) span
set node(5001,xpos) 80
set node(5001,ypos) 46

set node(5002,arrowwgt) {}
set node(5002,children) {5001}
set node(5002,constit) {}
set node(5002,labelwgt) {}
set node(5002,parent) {}
set node(5002,relname) {}
set node(5002,span) {1 3}
set node(5002,spanwgt) 60
set node(5002,text) "1-3"
set node(5002,textwgt) 59
set node(5002,type) span
set node(5002,xpos) 80
set node(5002,ypos) 0

if {[catch {unlink-node 2 1; unlink-node 3 1}]} {
    error "Unlinking node from different relations causes infinite loop."
}
