# $Id: new.tcl,v 2.7 1995/01/09 14:41:33 jfontain Exp $

if {![info exists classNewId]} {
    # work around object creation between multiple include of this file problem
    global classNewId
    set classNewId 0
}

proc new {className args} {
    # calls the constructor for the class with optional arguments
    # and returns a unique object identifier independent of the class name

    global classNewId
    # use local variable for id for new can be called recursively
    set id [incr classNewId]
    if {[llength [info procs ${className}:$className]]>0} {
        # avoid catch to track errors
        eval ${className}:$className $id $args
    }
    return $id
}

proc delete {className id} {
    # calls the destructor for the class and delete all the object data members

    if {[llength [info procs ${className}:~$className]]>0} {
        # avoid catch to track errors
        ${className}:~$className $id
    }
    global $className
    # and delete all this object array members if any (assume that they were stored as $className($id,memberName))
    foreach name [array names $className "$id,*"] {
        unset ${className}($name)
    }
}
