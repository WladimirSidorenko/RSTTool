##################################################################
namespace eval ::rsttool::appearance {}

proc ::rsttool::appearance::set_default {{text_w .editor.text} \
					     {prnt_text_w .editor.textPrnt}} {
    # default appearance
    tk_setPalette background gray35 foreground white activebackground white activeforeground red
    # apply special default appearance settings for aqua
    if {[tk windowingsystem] == "aqua"} {
	tk_setPalette background gray85 foreground black
    }

    $text_w configure -fg black -bg white -selectbackground gray85
    $prnt_text_w configure -fg black -bg white -selectbackground gray85
    $rstw configure -bg white

    set old_clr purple;
    $text_w tag configure old -foreground $old_clr
    $text_w tag configure next -foreground black
    $text_w tag configure new -foreground DimGray
    $text_w tag lower new
    $text_w tag configure notes -foreground black
    $text_w tag configure my_sel -background yellow

    $prnt_text_w tag configure old -foreground $old_clr

}

##################################################################
package provide rsttool::appearance 0.0.1
return
