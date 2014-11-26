# -*- mode: tcl; -*-

reset-rst

set disco_node {}
set last_group_node_id 5001
array unset visible_nodes
array set visible_nodes {1 1 2 1 5001 1}
array unset nid2msgid
array set nid2msgid {1 1 2 2 5001 1}

array set visible_nodes {1 1 2 1 3 1 5001 1}
array set nid2msgid {1 404262465166639104 2 404262465166639104 \
			 3 404262465166639104 5001 404262465166639104}

# nid	9	404262465166639104	text Ich mein...	typetext	textwgt95	labelwgt	arrowwgt97	spanwgt96	relnamespan	children5006	parent5005	constituents	visible1	span99	offsets2941	xpos300	ypos76	oldindex	newindex	constit	promotion
# nid	10	404262465166639104	text Religion?	typetext	textwgt102	labelwgt105	arrowwgt104	spanwgt103	relnameList	children	parent5006	constituents	visible1	span1010	offsets4151	xpos410	ypos122	oldindex	newindex	constit	promotion
# nid	11	404262465166639104	text Welche Begründung?	typetext	textwgt106	labelwgt109	arrowwgt108	spanwgt107	relnameList	children	parent5006	constituents	visible1	span1111	offsets5170	xpos520	ypos122	oldindex	newindex	constit	promotion
# nid	5005	404262465166639104	text9-11	typespan	textwgt93	labelwgt	arrowwgt	spanwgt94	relname	children9	parent	constituents	visible1	span911	offsets	xpos300	ypos30	oldindex	newindex	constit	promotion
# nid	5006	404262465166639104	text10-11	typemultinuc	textwgt98	labelwgt101	arrowwgt100	spanwgt99	relnameOTHER	children1011	parent9	constituents	visible1	span1011	offsets	xpos465	ypos76	oldindex	newindex	constit	promotion
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

autolink_nodes 2 3 "multinuclear" "list"

if {$node(2,parent) == 1 || [lindex $node(1,children) 2] != {}} {
    error "Linking node to an existing satellite with multinuclear relation should\
 introduce new abstract node and set this node as satellite's parent."
}
