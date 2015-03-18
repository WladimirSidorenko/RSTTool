##################################################################
namespace eval ::rsttool::appearance {}

proc ::rsttool::appearance::set_default {{text_w .editor.text} \
					     {prnt_text_w .editor.textPrnt}} {
    variable ::rsttool::treeditor::RSTW;
    variable ::rsttool::segmenter::TXTW;
    variable ::rsttool::segmenter::PRNT_TXTW;
    # default appearance
    tk_setPalette background gray69 foreground black activebackground white activeforeground red;
    # apply special default appearance settings for aqua
    if {[tk windowingsystem] == "aqua"} {
	tk_setPalette background gray85 foreground black;
    }

    $TXTW configure -fg black -bg white -selectbackground gray85;
    $PRNT_TXTW configure -fg black -bg white -selectbackground gray85;
    $RSTW configure -bg white;

    set color purple;
    $TXTW tag configure old -foreground $color;
    $TXTW tag configure next -foreground black;
    $TXTW tag configure new -foreground DimGray;
    $TXTW tag lower new
    $TXTW tag configure notes -foreground black;
    $TXTW tag configure my_sel -background yellow;

    $PRNT_TXTW tag configure old -foreground $color;
}

##################################################################
package provide rsttool::appearance 0.0.1
return
