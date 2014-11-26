# -*- mode: tcl; -*-

set disco_node {}
set last_group_node_id 5027
set relations(rst) {antithesis}
array set visible_nodes {1 1 2 1}
array set nid2msgid {1 1 2 2}

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

autolink_nodes 1 2 "multinuclear" "list"
redisplay-net
puts stderr "clicked-widget: ntw $last_group_node_id = [$rstw coords [ntw $last_group_node_id]]"

if {[clicked-widget {*}[$rstw coords [ntw $last_group_node_id]]] == {}} {
    error "Abstract nucleus node of two multi-nuclear relations is not visible for `clicked-widget`."
}
