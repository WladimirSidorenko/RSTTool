# -*- mode: tcl; coding: utf-8; -*-
array unset nid2msgid
array unset msgid2nid
array unset visible_nodes
array unset msgs2extnid

array set visible_nodes {1 2 3 4 5003 5004}
array set nid2msgid {1 404536249094270976 2 404536249094270976 3 404536249094270976\
		     4 404536249094270976 5003 404536249094270976 5004 404536249094270976}
array set msgid2nid {404536249094270976 {1 2 3 4 5003 5004}}

##################################################################
set node(1,text) {@Wundersterne}
set node(1,type) {text}
set node(1,textwgt) {196}
set node(1,labelwgt) {199}
set node(1,arrowwgt) {198}
set node(1,spanwgt) {197}
set node(1,relname) {address}
set node(1,children) {}
set node(1,parent) {2}
set node(1,constituents) {}
set node(1,visible) {1}
set node(1,span) {1 1}
set node(1,offsets) {0 13}
set node(1,xpos) {80}
set node(1,ypos) {76}
set node(1,oldindex) {}
set node(1,newindex) {}
set node(1,constit) {}
set node(1,promotion) {}

set node(2,text) { ...riecht man es immer noch???}
set node(2,type) {text}
set node(2,textwgt) {193}
set node(2,labelwgt) {}
set node(2,arrowwgt) {195}
set node(2,spanwgt) {194}
set node(2,relname) {span}
set node(2,children) {1}
set node(2,parent) {5003}
set node(2,constituents) {}
set node(2,visible) {1}
set node(2,span) {2 2}
set node(2,offsets) {13 44}
set node(2,xpos) {190}
set node(2,ypos) {76}
set node(2,oldindex) {}
set node(2,newindex) {}
set node(2,constit) {}
set node(2,promotion) {}

set node(3,text) { #Wittmund}
set node(3,type) {text}
set node(3,textwgt) {202}
set node(3,labelwgt) {205}
set node(3,arrowwgt) {204}
set node(3,spanwgt) {203}
set node(3,relname) {List}
set node(3,children) {}
set node(3,parent) {5004}
set node(3,constituents) {}
set node(3,visible) {1}
set node(3,span) {3 3}
set node(3,offsets) {44 54}
set node(3,xpos) {300}
set node(3,ypos) {76}
set node(3,oldindex) {}
set node(3,newindex) {}
set node(3,constit) {}
set node(3,promotion) {}

set node(4,text) { #Kaverne}
set node(4,type) {text}
set node(4,textwgt) {206}
set node(4,labelwgt) {209}
set node(4,arrowwgt) {208}
set node(4,spanwgt) {207}
set node(4,relname) {List}
set node(4,children) {}
set node(4,parent) {5004}
set node(4,constituents) {}
set node(4,visible) {1}
set node(4,span) {4 4}
set node(4,offsets) {54 63}
set node(4,xpos) {410}
set node(4,ypos) {76}
set node(4,oldindex) {}
set node(4,newindex) {}
set node(4,constit) {}
set node(4,promotion) {}

set node(5003,text) {1-2}
set node(5003,type) {span}
set node(5003,textwgt) {191}
set node(5003,labelwgt) {}
set node(5003,arrowwgt) {}
set node(5003,spanwgt) {192}
set node(5003,relname) {}
set node(5003,children) {2}
set node(5003,parent) {}
set node(5003,constituents) {}
set node(5003,visible) {1}
set node(5003,span) {1 2}
set node(5003,offsets) {}
set node(5003,xpos) {190}
set node(5003,ypos) {30}
set node(5003,oldindex) {}
set node(5003,newindex) {}
set node(5003,constit) {}
set node(5003,promotion) {}

set node(5004,text) {3-4}
set node(5004,type) {span}
set node(5004,textwgt) {200}
set node(5004,labelwgt) {169}
set node(5004,arrowwgt) {168}
set node(5004,spanwgt) {201}
set node(5004,relname) {}
set node(5004,children) {3 4}
set node(5004,parent) {}
set node(5004,constituents) {}
set node(5004,visible) {1}
set node(5004,span) {3 4}
set node(5004,offsets) {}
set node(5004,xpos) {355}
set node(5004,ypos) {30}
set node(5004,oldindex) {}
set node(5004,newindex) {}
set node(5004,constit) {}
set node(5004,promotion) {}

##################################################################
set last_group_node_id 5004
autolink_nodes 2 5004 elaboration satellite below

if {$node(3,parent) != 5004} {
    error "Children of multi-nuclear node are relinked when connecting this node as satellite."
}
