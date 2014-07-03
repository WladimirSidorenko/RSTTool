# $Id: textundo.tcl,v 1.5 1995/06/12 09:01:41 jfontain Exp $

proc textUndoer:textUndoer {id widget {depth 2147483647}} {
    global textUndoer

    if {[string compare [winfo class $widget] Text]!=0} {
        error "textUndoer error: widget $widget is not a text widget"
    }
    set textUndoer($id,widget) $widget
    set textUndoer($id,originalBindingTags) [bindtags $widget]
    bindtags $widget [concat $textUndoer($id,originalBindingTags) UndoBindings($id)]

    bind UndoBindings($id) <Control-u> "textUndoer:undo $id"

    # self destruct automatically when text widget is gone
    bind UndoBindings($id) <Destroy> "delete textUndoer $id"

    # rename widget command
    rename $widget [set textUndoer($id,originalCommand) textUndoer:original$widget]
    # and intercept modifying instructions before calling original command
    proc $widget {args} "textUndoer:checkpoint $id \$args; eval $textUndoer($id,originalCommand) \$args"

    set textUndoer($id,commandStack) [new lifo $depth]
    set textUndoer($id,cursorStack) [new lifo $depth]
}

proc textUndoer:~textUndoer {id} {
    global textUndoer

    bindtags $textUndoer($id,widget) $textUndoer($id,originalBindingTags)
    rename $textUndoer($id,widget) ""
    rename $textUndoer($id,originalCommand) $textUndoer($id,widget)
    delete lifo $textUndoer($id,commandStack)
    delete lifo $textUndoer($id,cursorStack)
}

proc textUndoer:checkpoint {id arguments} {
    global textUndoer

    # do nothing if non modifying command
    if {[string compare [lindex $arguments 0] insert]==0} {
        textUndoer:processInsertion $id [lrange $arguments 1 end]
    }
    if {[string compare [lindex $arguments 0] delete]==0} {
        textUndoer:processDeletion $id [lrange $arguments 1 end]
    }
}

proc textUndoer:processInsertion {id arguments} {
    global textUndoer

    set number [llength $arguments]
    set length 0
    # calculate total insertion length while skipping tags in arguments
    for {set index 1} {$index<$number} {incr index 2} {
        incr length [string length [lindex $arguments $index]]
    }
    if {$length>0} {
        set index [$textUndoer($id,originalCommand) index [lindex $arguments 0]]
        lifo:push $textUndoer($id,commandStack) "delete $index $index+${length}c"
        lifo:push $textUndoer($id,cursorStack) [$textUndoer($id,originalCommand) index insert]
    }
}

proc textUndoer:processDeletion {id arguments} {
    global textUndoer

    set command $textUndoer($id,originalCommand)
    lifo:push $textUndoer($id,cursorStack) [$command index insert]
    set start [$command index [lindex $arguments 0]]
    if {[llength $arguments]>1} {
        lifo:push $textUndoer($id,commandStack) "insert $start {[$command get $start [lindex $arguments 1]]}"
    } else {
        lifo:push $textUndoer($id,commandStack) "insert $start {[$command get $start]}"
    }
}

proc textUndoer:undo {id} {
    global textUndoer

    if {[catch {set cursor [lifo:pop $textUndoer($id,cursorStack)]}]} {
        return
    }
    eval $textUndoer($id,originalCommand) [lifo:pop $textUndoer($id,commandStack)]
    # now restore cursor position
    $textUndoer($id,originalCommand) mark set insert $cursor
    # make sure insertion point can be seen
    $textUndoer($id,originalCommand) see insert
}

proc textUndoer:reset {id} {
    global textUndoer

    lifo:empty $textUndoer($id,commandStack)
    lifo:empty $textUndoer($id,cursorStack)
}
