# RSTTool for Annotation of Discussions

This program is a forked version of Daniel Marcu's
[modification](http://www.isi.edu/publications/licensed-sw/RSTTool/)
of the original [RSTTool](http://www.wagsoft.com/RSTTool/) by Michael
O'Donell.  This version provides a modified appearance for annotating
multilogues (i.e. dialogues with multiple participants).  The user can
view multilogues in a successive fashion (i.e. reply by reply) and can
annotate RST-relations both within and among the replies.


## Description

After starting ./RSTTool from your shell, you should see a graphical
frame consisting of three sub-windows.  The upper sub-window shows a
graphical representation of the (partial) RST tree constructed for
discussion.  In the lower part, you can see two split text windows
with text of multilogue messages.  The lower of this windows shows the
answer to the text in the upper part.  That is, if you have a dialogue
like:

*- How are you doing?*

*- Fine. Adn you?*

When scrolling the discussion, you should see the former message in
the upper windopw part, and the latter message in the lower window.


## Bindings

### All windows:

`Ctrl-O` -- open new file

`Ctrl-S` -- save file

`Ctrl-C` or `Super-C` -- copy selection

### Segment editor:

`LeftMouseClick` on unannotated text area - set a segment boundary

`Ctrl-RightMouseClick` on segment boundary - move segment boundary

`Ctrl-Alt-RightMouseClick` on segment boundary - delete segment boundary

## License

This program is based on the RSTTool version developed by Daniel Marcu
and is subject to the same [license agreement
terms](http://www.isi.edu/publications/licensed-sw/RSTTool/) as the
original program.

## Contact

If you find any issues or inconsistencies in this version of RSTTool
or in its description, please submit a bug at
https://github.com/WladimirSidorenko/RSTTool.
