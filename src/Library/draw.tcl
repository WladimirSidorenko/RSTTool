### GRAPHIC PRIMITIVES ###########################

proc draw-text {window txt x y {options {}}} {
    eval {$window create text} $x $y\
    	{-text $txt -anchor n -justify center}\
    	$options
}

proc draw-line {window x1 y1 x2 y2} {
    $window create line $x1 $y1  $x2 $y2
}

proc draw-line-between {window p1 {p2 {}}} {
    eval [concat "draw-line" $window $p1 $p2]
}

proc draw-arrow-between {window p1 {p2 {}}} {
    eval [concat "draw-line" $window $p1 $p2]
}

proc draw-rect {window x1 y1 x2 y2} {
    $window create rect $x1 $y1  $x2 $y2
}

proc draw-rect-between {window p1 {p2 {}}} {
    eval [concat "draw-rect" $window $p1 $p2]
}

proc draw-arc {window points} {
    set cmd "$window create line"
    set options {-tag line -joinstyle round -smooth true -arrow first}
    eval [concat $cmd $points $options]
}

proc screen-coords {item canvas} {
    # Returns the screen coordes of a canvas item
    set screencorrect "[winfo rootx $canvas] [winfo rooty $canvas]"
    set coords [$canvas coords $item]

    set scrollcorrection "[$canvas canvasx 0] [$canvas canvasy 0]"
    return [add-points [subtract-points $coords $scrollcorrection]\
		$screencorrect]
}

proc move-item {window item xdelta ydelta} {
    $window move $item $xdelta $ydelta
}
