# RSTTool for Annotation of Discussions

This program is a forked version of [Daniel Marcu's
modification](http://www.isi.edu/publications/licensed-sw/RSTTool/) of
the original [RSTTool from Michael
O'Donell](http://www.wagsoft.com/RSTTool/).  This version provides a
modified appearance for annotating multilogues (i.e. dialogues with
multiple participants).  The user can view multilogues in a successive
fashion (i.e. reply by reply) and can annotate RST-relations both
within and among the replies.


## Description

After starting `./RSTTool &` from your shell, you should see a
graphical frame consisting of three horizontal sub-windows.  The upper
sub-window ("RST Editor") shows a graphical representation of the
(partially constructed) RS tree.  The lower part ("Segment Editor")
consists of two smaller windows that contain text of the multilogue
messages.  The lower of these windows displays the answer to the text
in the upper part.  That is, if you have a dialogue like:

*- How are you doing?*

*- Fine. And you?*

When scrolling through discussion, you should see the first message in
the upper window part, and the second message, which is answer, in the
lower window.  We also call the lower window "Segment Editor", since
in it, you can create, delete, or move the boundaries of EDUs.

### Input Format

### Output Format

## Bindings

### All windows:

`Ctrl-O` -- open new file

`Ctrl-S` -- save file

`Ctrl-C` or `Super-C` -- copy selection

### Segment Editor:

`LeftMouseClick` on unannotated text area - set new segment boundary

`Ctrl-RightMouseClick` on segment boundary - move segment boundary

`Ctrl-Alt-RightMouseClick` on segment boundary - delete segment boundary

## License

This program is based on the RSTTool version developed by Daniel Marcu
and is subject to the same [license agreement
terms](http://www.isi.edu/publications/licensed-sw/RSTTool/) as the
original program.

## Contact

If you find any issues or inconsistencies in this version of RSTTool
or in its description, please feel free to [submit a
bug](https://github.com/WladimirSidorenko/RSTTool/issues/new).
