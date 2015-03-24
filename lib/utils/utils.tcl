#!/usr/bin/env wish

##################################################################
namespace eval ::rsttool::utils {
    namespace export add-points;
    namespace export getarg;
    namespace export ldelete;
    namespace export max;
    namespace export min;
    namespace export reset-array;
    namespace export strip;
    namespace export subtract-points;
}

namespace eval ::rsttool::utils::menu {
    namespace export add-item;
    namespace export add-cascade;
    namespace export bind-tooltip;
}

namespace eval ::rsttool::utils::htmlentities {
    namespace ensemble create -subcommands {encode decode}
    variable encode {
        \u00a0 &nbsp\; \u00a1 &iexcl\; \u00a2 &cent\; \u00a3 &pound\; \u00a4
        &curren\; \u00a5 &yen\; \u00a6 &brvbar\; \u00a7 &sect\; \u00a8 &uml\;
        \u00a9 &copy\; \u00aa &ordf\; \u00ab &laquo\; \u00ac &not\; \u00ad
        &shy\; \u00ae &reg\; \u00af &macr\; \u00b0 &deg\; \u00b1 &plusmn\;
        \u00b2 &sup2\; \u00b3 &sup3\; \u00b4 &acute\; \u00b5 &micro\; \u00b6
        &para\; \u00b7 &middot\; \u00b8 &cedil\; \u00b9 &sup1\; \u00ba &ordm\;
        \u00bb &raquo\; \u00bc &frac14\; \u00bd &frac12\; \u00be &frac34\;
        \u00bf &iquest\; \u00c0 &Agrave\; \u00c1 &Aacute\; \u00c2 &Acirc\;
        \u00c3 &Atilde\; \u00c4 &Auml\; \u00c5 &Aring\; \u00c6 &AElig\; \u00c7
        &Ccedil\; \u00c8 &Egrave\; \u00c9 &Eacute\; \u00ca &Ecirc\; \u00cb
        &Euml\; \u00cc &Igrave\; \u00cd &Iacute\; \u00ce &Icirc\; \u00cf
        &Iuml\; \u00d0 &ETH\; \u00d1 &Ntilde\; \u00d2 &Ograve\; \u00d3
        &Oacute\; \u00d4 &Ocirc\; \u00d5 &Otilde\; \u00d6 &Ouml\; \u00d7
        &times\; \u00d8 &Oslash\; \u00d9 &Ugrave\; \u00da &Uacute\; \u00db
        &Ucirc\; \u00dc &Uuml\; \u00dd &Yacute\; \u00de &THORN\; \u00df
        &szlig\; \u00e0 &agrave\; \u00e1 &aacute\; \u00e2 &acirc\; \u00e3
        &atilde\; \u00e4 &auml\; \u00e5 &aring\; \u00e6 &aelig\; \u00e7
        &ccedil\; \u00e8 &egrave\; \u00e9 &eacute\; \u00ea &ecirc\; \u00eb
        &euml\; \u00ec &igrave\; \u00ed &iacute\; \u00ee &icirc\; \u00ef
        &iuml\; \u00f0 &eth\; \u00f1 &ntilde\; \u00f2 &ograve\; \u00f3
        &oacute\; \u00f4 &ocirc\; \u00f5 &otilde\; \u00f6 &ouml\; \u00f7
        &divide\; \u00f8 &oslash\; \u00f9 &ugrave\; \u00fa &uacute\; \u00fb
        &ucirc\; \u00fc &uuml\; \u00fd &yacute\; \u00fe &thorn\; \u00ff &yuml\;
        \u0192 &fnof\; \u0391 &Alpha\; \u0392 &Beta\; \u0393 &Gamma\; \u0394
        &Delta\; \u0395 &Epsilon\; \u0396 &Zeta\; \u0397 &Eta\; \u0398 &Theta\;
        \u0399 &Iota\; \u039a &Kappa\; \u039b &Lambda\; \u039c &Mu\; \u039d
        &Nu\; \u039e &Xi\; \u039f &Omicron\; \u03a0 &Pi\; \u03a1 &Rho\; \u03a3
        &Sigma\; \u03a4 &Tau\; \u03a5 &Upsilon\; \u03a6 &Phi\; \u03a7 &Chi\;
        \u03a8 &Psi\; \u03a9 &Omega\; \u03b1 &alpha\; \u03b2 &beta\; \u03b3
        &gamma\; \u03b4 &delta\; \u03b5 &epsilon\; \u03b6 &zeta\; \u03b7 &eta\;
        \u03b8 &theta\; \u03b9 &iota\; \u03ba &kappa\; \u03bb &lambda\; \u03bc
        &mu\; \u03bd &nu\; \u03be &xi\; \u03bf &omicron\; \u03c0 &pi\; \u03c1
        &rho\; \u03c2 &sigmaf\; \u03c3 &sigma\; \u03c4 &tau\; \u03c5 &upsilon\;
        \u03c6 &phi\; \u03c7 &chi\; \u03c8 &psi\; \u03c9 &omega\; \u03d1
        &thetasym\; \u03d2 &upsih\; \u03d6 &piv\; \u2022 &bull\; \u2026
        &hellip\; \u2032 &prime\; \u2033 &Prime\; \u203e &oline\; \u2044
        &frasl\; \u2118 &weierp\; \u2111 &image\; \u211c &real\; \u2122
        &trade\; \u2135 &alefsym\; \u2190 &larr\; \u2191 &uarr\; \u2192 &rarr\;
        \u2193 &darr\; \u2194 &harr\; \u21b5 &crarr\; \u21d0 &lArr\; \u21d1
        &uArr\; \u21d2 &rArr\; \u21d3 &dArr\; \u21d4 &hArr\; \u2200 &forall\;
        \u2202 &part\; \u2203 &exist\; \u2205 &empty\; \u2207 &nabla\; \u2208
        &isin\; \u2209 &notin\; \u220b &ni\; \u220f &prod\; \u2211 &sum\;
        \u2212 &minus\; \u2217 &lowast\; \u221a &radic\; \u221d &prop\; \u221e
        &infin\; \u2220 &ang\; \u2227 &and\; \u2228 &or\; \u2229 &cap\; \u222a
        &cup\; \u222b &int\; \u2234 &there4\; \u223c &sim\; \u2245 &cong\;
        \u2248 &asymp\; \u2260 &ne\; \u2261 &equiv\; \u2264 &le\; \u2265 &ge\;
        \u2282 &sub\; \u2283 &sup\; \u2284 &nsub\; \u2286 &sube\; \u2287
        &supe\; \u2295 &oplus\; \u2297 &otimes\; \u22a5 &perp\; \u22c5 &sdot\;
        \u2308 &lceil\; \u2309 &rceil\; \u230a &lfloor\; \u230b &rfloor\;
        \u2329 &lang\; \u232a &rang\; \u25ca &loz\; \u2660 &spades\; \u2663
        &clubs\; \u2665 &hearts\; \u2666 &diams\; \u0022 &quot\; \u0026 &amp\;
        \u003c &lt\; \u003e &gt\; \u0152 &OElig\; \u0153 &oelig\; \u0160
        &Scaron\; \u0161 &scaron\; \u0178 &Yuml\; \u02c6 &circ\; \u02dc
        &tilde\; \u2002 &ensp\; \u2003 &emsp\; \u2009 &thinsp\; \u200c &zwnj\;
        \u200d &zwj\; \u200e &lrm\; \u200f &rlm\; \u2013 &ndash\; \u2014
        &mdash\; \u2018 &lsquo\; \u2019 &rsquo\; \u201a &sbquo\; \u201c
        &ldquo\; \u201d &rdquo\; \u201e &bdquo\; \u2020 &dagger\; \u2021
        &Dagger\; \u2030 &permil\; \u2039 &lsaquo\; \u203a &rsaquo\; \u20ac
        &euro\;
    }
    variable decode [lreverse $encode]
    proc encode {string} {
        variable encode
        string map $encode $string
    }
    proc decode {string} {
        variable decode
        string map $decode $string
    }

    namespace export decode;
    namespace export encode;
}

##################################################################
proc ::rsttool::utils::getarg {key list} {
    # Returns the value in list immediately following key
    for {set i 0} {$i < [llength $list]} {incr i 2} {
	if { [lindex $list $i] == $key } {
	    return [lindex $list [expr $i + 1]]
	}
    }
    return {}
}

proc ::rsttool::utils::max {args} {
    if {[llength $args] == 0} {
	return {};
    } else {
	set max [lindex $args 0]
    }

    foreach arg $args {
	if {$arg > $max} {set max $arg}
    }
    return $max
}

proc ::rsttool::utils::ldelete { list value } {
    set ix [lsearch -exact $list $value]
    if {$ix >= 0} {
	return [lreplace $list $ix $ix]
    } else {
	return $list
    }
}

proc ::rsttool::utils::min {args} {
    if {[llength $args] == 0} {
	return {};
    } else {
	set min [lindex $args 0]
    }

    foreach arg $args {
	if {$arg < $min} {set min $arg}
    }
    return $min
}

proc ::rsttool::utils::reset-array {a_arr} {
    array unset $a_arr;
    array set $a_arr {};
}

proc ::rsttool::utils::strip {a_string} {
    regsub -all "\n" $a_string " " a_string
    regsub -all "\t" $a_string " " a_string
    regsub -all "  +" $a_string " " a_string
    return [string trim $a_string];
}

proc ::rsttool::utils::add-points {p1 p2} {
    list [expr [lindex $p1 0] + [lindex $p2 0]]\
	[expr [lindex $p1 1] + [lindex $p2 1]]
}

proc ::rsttool::utils::subtract-points {p1 p2} {
    list [expr [lindex $p1 0] - [lindex $p2 0]]\
	[expr [lindex $p1 1] - [lindex $p2 1]]
}

proc ::rsttool::utils::menu::add-item {menu label cmd} {
    $menu add command -label $label -command $cmd;
}

proc ::rsttool::utils::menu::add-cascade {menu label newmenu} {
    $menu add cascade -label $label -menu $newmenu;
}

proc ::rsttool::utils::menu::bind-tooltip {a_wdgt {a_cmd {::rsttool::utils::menu::show-tooltip}}} {
    bind $a_wdgt <<MenuSelect>> [list {*}[subst $a_cmd] %W];

    bind $a_wdgt <Any-Leave> {destroy %W.tooltip};
    bind $a_wdgt <Any-KeyPress> {destroy %W.tooltip};
    bind $a_wdgt <Any-Button> {destroy %W.tooltip};
}

proc ::rsttool::utils::menu::tooltip {a_wdgt {a_txt {}}} {
    if {$a_txt == {}} {return;}
    if [winfo exists $a_wdgt.tooltip] {destroy $a_wdgt.tooltip}

    set tooltip [toplevel $a_wdgt.tooltip -bd 1 -bg black]
    set scrh [winfo screenheight $a_wdgt]; # 1) flashing window fix
    set scrw [winfo screenwidth $a_wdgt]; # 2) flashing window fix
    wm geometry $tooltip +$scrh+$scrw; # 3) flashing window fix
    wm overrideredirect $tooltip 1
    set iwidth [expr [winfo width $a_wdgt] * 3];
    pack [label $tooltip.label -wraplength $iwidth \
	      -bg lightyellow -fg black -text $a_txt -justify left]

    set width [winfo reqwidth $tooltip.label]
    set height [winfo reqheight $tooltip.label]
    # a.) Is the pointer in the bottom half of the screen?
    set pointer_below_midline [expr [winfo pointery .] > [expr [winfo screenheight .] / 2.0]]
    # b.) Tooltip is centred horizontally on pointer.
    set positionX [expr [winfo pointerx .] - round($width / -2.5)]
    # c.) Tooltip is displayed above or below depending on pointer Y position.
    set positionY [expr [winfo pointery .] + ($pointer_below_midline * -1) * ($height + 35) + \
		       (35 - (round($height / 2.0) % 35))]

    if  {[expr $positionX + $width] > [winfo screenwidth .]} {
	set positionX [expr [winfo screenwidth .] - $width]
    } elseif {$positionX < 0} {
	set positionX 0
    }

    wm geometry $tooltip [join  "$width x $height + $positionX + $positionY" {}]
    raise $tooltip
}

##################################################################
package provide rsttool::utils 0.0.1
return
