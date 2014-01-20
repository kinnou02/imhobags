The basic reason for this addon is that I keep wanting it and reimplementing
parts of it.  The idea is this:

* You have a block of space.
* You want a scrolling list of items.
* Each item wants its own setup of some sort.
* You want scrolling and display to be basically handled for you.

Watch, and be amazed!

frametable = LibItemList.create(
	frame, addon, initial, count, point, setup, show, select)

Creates a table containing <count> frames (indexes 1..count),
calling setup(frametable, frame, index) on each, and also a scrollbar.
Each frame's height and width are preset by LibItemList based on the
count, the width of a native scrollbar, and the size of the frame
originally passed in.  Frames will have ownership assigned to
addon.  Scrollbar will be :SetPoint(TOPpoint, frame, TOPpoint) and
:SetHeight(frame:GetHeight()).  (point shouldbe "RIGHT" or "LEFT".)

If a click in one of the frames is not otherwise processed by
the stuff you set up, the frame is "selected".  If select was
provided, then
	select(frametable, frameindex, itemtable, itemindex)
is called.  Otherwise,
	show(frametable, frameindex, itemtable, itemindex, true)
is called.

Also sets non-numeric members of frametable:

frametable.scrollbar => scrollbar widget

frametable.offset => current offset of the scrollbar

frametable.u => whatever you passed as "initial".  Used for user data.

frametable.parent => the 'frame' argument

frametable.addon => the 'addon' argument

frametable:display(data)
	Displays data, or the last table given if data is nil.

	This involves calling
	  show(frametable, frameindex, itemtable, itemindex, selected)
	for each item currently displayed.

If you modify table, be sure to call frametable:display(), or the contents
may be out of sync, and may be redisplayed unexpectedly by scrolling activity.

Other values may be stored in frametable.  Do not mess with them.

