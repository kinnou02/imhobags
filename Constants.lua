local Addon, private = ...

setfenv(1, private)
Const = {
	AnimationsDuration = 0.3,
	
	ItemButtonDefaultSize = 50,
	ItemButtonUnavailableAlpha = 0.5,
	
	ItemWindowCellSpacing = 2,
	ItemWindowDefaultColumns = 8, -- Starting size for new windows
	ItemWindowDefaultLayout = "default",
	ItemWindowDefaultSort = "name",
	ItemWindowJunkButtonSize = 30,
	ItemWindowMinWidth = 345, -- Prevents header buttons from overlapping and is lower bound for full columns
	ItemWindowMinHeight = 310, -- Title bar starts stretching below this content size
	ItemWindowPadding = 4,
}
