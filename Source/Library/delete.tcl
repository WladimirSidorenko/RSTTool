######################################
# Ensure delete works properly in all windows

### MAKE DELETE KEY WORK PROPERLY #####
bind Text <Delete> {
    if {[%W tag nextrange sel 1.0 end] != ""} {
        %W delete sel.first sel.last
    } elseif [%W compare insert != 1.0] {
        %W delete insert-1c
        %W see insert
    }
}

bind Entry <Delete> {
    tkEntryBackspace %W
}

