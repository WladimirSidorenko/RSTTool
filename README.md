# RSTTool for Annotation of Discussions

.. image:: http://img.shields.io/github/issues/badges/shields.svg
   :alt: open issues counter
   :align: right
   :target: https://github.com/WladimirSidorenko/RSTTool/issues


This program is a forked version of [Daniel Marcu's
modification](http://www.isi.edu/publications/licensed-sw/RSTTool/) of
the original [RSTTool from Michael
O'Donell](http://www.wagsoft.com/RSTTool/).  This version provides a
modified appearance for annotation of multilogues (i.e. dialogues with
multiple participants).  The user can view multilogues in a successive
fashion (i.e. reply by reply) and can annotate RST-relations both
within and among the multilogue messages.

## Description

After starting `./RSTTool &` from your shell, you should see a
graphical window consisting of three horizontal sub-frames.  The upper
sub-frame ("RST Editor") displays a graphical representation of the
(partially constructed) RS tree.  The lower sub-frame ("Segment
Editor") consists of two smaller sub-windows.  The upper of these
windows shows a message in a given multilogue, and the lower window
displays the response to this message.

You can scroll through discussion(s) in a consecutive fashion by
clicking on the buttons "Previous Message" and "Next Message" in the
middle part of the frame.  These buttons will change the messages
displayed in the lower sub-frame representing each message-response
pair one at a time.  First, the very first message of the discussion
will be displayed in the lowest sub-window.  In this window, you can
also add and modify EDU boundaries for that message.  After clicking
on "Next message", the root message of the discussion will appear in
the upper sub-window, and the lower sub-window will display an answer
to the root meesage.

That is, if you have a dialogue like:

*- How are you doing?*

*- Fine. And you?*

To be continued...

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
