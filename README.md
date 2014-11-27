# RSTTool for Annotation of Discussions

This program is a forked version of [Daniel Marcu's
modification](http://www.isi.edu/publications/licensed-sw/RSTTool/) of
the original [RSTTool from Michael
O'Donell](http://www.wagsoft.com/RSTTool/).  This version provides a
modified appearance for annotation of multilogues (i.e. dialogues with
multiple participants).  The user can view multilogues in a successive
fashion (i.e. reply by reply) and can annotate RST-relations both
within and among the multilogue messages.

---

## Description

After starting `./RSTTool &` from your shell, you should see a
graphical window consisting of three horizontal sub-frames.  The upper
sub-frame (called <tt>RST Editor</tt>) displays a graphical
representation of the (partially constructed) RST tree.  The middle
sub-frame (<tt>Refererence Text Viewer</tt>) shows the message which
is being answered in the discussion.  The lowest part of the program
windows (<tt>Answer Text Editor</tt>) displays the answer to the
reference message and also allows you to annotate boundaries of
elementary discourse units in that answer.

After loading an input file with discussions (cf. Section [Input
Format][]), you should see the first message of the first discussion
in <tt>Answer Text Editor</tt>.  There you can annotate the boundaries
of its discourse segments.  Since this message is typically not an
answer to any other message in your file, <tt>Refererence Text
Viewer</tt> will remain empty by that time.

Once you have annotated the segments of the message in <tt>Answer Text
Editor</tt> (cf. Section [Answer Text Editor][] for description), you
can construct an RST tree of these segments using <tt>RST Editor</tt>.
In order to link two nodes, you simply need to click one of them, and
then make a second click on the node which you are going to connect
to.  After that, a context menu will be offered asking you whether the
first node should be linked as a nucleus or a satellite, or, probably,
as a part of a multinucleus relation.  Once you have chosen the
linkage type, you can choose a particular relation for that link in
another menu.

To proceed to the next message, you simply need to click the button
<tt>Next Message</tt> in the middle part of the window.  If your
currently annotated message has any answers, then its text will move
to the <tt>Refererence Text Viewer</tt> part and the answer will be
displayed in <tt>Answer Text Editor</tt> instead.

After you are finished with your annotation, you can save your data
either by using the menu <tt>File/Save</tt> or by using the hot key
<tt>Ctrl-S</tt> (<tt>Cmd-S</tt> on Mac).

---

### Input Format

This tool accepts discussion files in tab-separated format where each
message is represented as a sequence of fields delimited by tabulation
characters.  In each message, there shoul be at least one and at most
two non-empty fields.  The first of these fields represents the id of
that message (the id should be unique across the file).  The second
field contains the text of the message (no tabs are allowed within the
text).  The number of tabulation characters at the beginning of the
string represents the ``nestedness'' level of the message in a given
discussion.  It means, that message which starts a discussion there
should have zero tabs at the beginning whereas an immediate answer to
it should have one tab and should immediately follow this first
message.  An answer to the answer should begin with two tabs and so
on.  You can see an example of the input file
[here](examples/input.txt).

---

### Output Format

Currently, this tool saves all annotations in a tab-separated format
too.  The output file contains all information (including meta-data)
about each created EDU segment and the RST relations established
between the segments.  Lines containing description of the segments
begin with the word ``nid`` followed by the id of the EDU node, and
the id of its message.  Further fields have the format
``attribute_name\034attribute_value``, where ``\034`` is a special
character (with octal code 34) that rarely occurs in normal text and
serves here as a delimiter.  The attribute value pairs are delimited
from each other by tab characters.  The particular set of attributes
and their values mostly depends on the type of the node.  Further
works are planned to provide an appropriate exporter for this format
to other formats like (RST Treebank Lisp Format or RS3).

---

## Bindings

Particular bindings apply for particular parts of the program window.
Below you can see a summary of binding for each of the sub-frames.

### All windows

`Ctrl-O` or `Cmd-O` on Mac -- open new file

`Ctrl-S` or `Cmd-S` on Mac -- save file

`Ctrl-C` or `Cmd-C` on Mac -- copy selection

### Answer Text Editor

`LeftMouseClick` on unannotated text area - set new segment boundary

`Ctrl-RightMouseClick` on segment boundary - move segment boundary

`Ctrl-Alt-RightMouseClick` on segment boundary - delete segment boundary

---

## License

This program is based on the RSTTool version developed by Daniel Marcu
and is subject to the same [license agreement
terms](http://www.isi.edu/publications/licensed-sw/RSTTool/) as the
original program.

---

## Contact

If you find any issues or inconsistencies in this version of RSTTool
or in its description, please feel free to [submit a
bug](https://github.com/WladimirSidorenko/RSTTool/issues/new).
